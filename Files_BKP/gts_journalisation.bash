#! /bin/bash

#check si rsylog installe
verifrsyslog(){
  if dpkg -s rsyslog &> /dev/null; then
    echo "rsyslog est déjà installé."
  else
    echo "rsyslog n'est pas installé. Installation en cours..."
    sudo apt-get update && sudo apt-get install -y rsyslog
    if mycmd; then
      echo "rsyslog installé avec succès."
    else
      echo "Erreur lors de l'installation de rsyslog."
      exit 1
    fi
  fi
}

configJournal() {
  sudo touch /var/log/syslog-central.log
  LOG_FILE="/var/log/syslog-central.log"
  # Vérifier si le fichier existe déjà
  if [ ! -f "$LOG_FILE" ]; then
    echo "Le fichier $LOG_FILE n'existe pas, il va être créé."
  fi
  # Ajouter ou modifier ligne de config dans /etc/rsyslog.conf
  if ! grep -q "*.* $LOG_FILE" /etc/rsyslog.conf; then
    echo "*.* $LOG_FILE" | sudo tee -a /etc/rsyslog.conf
    if mycmd; then
      echo "Journalisation centralisée configurée."
    else
      echo "Erreur lors de la configuration de la journalisation centralisée."
      exit 1
    fi
  else
    echo "Journalisation déjà configurée."
  fi
  restart_rsyslog
}

# Mise en place de la rotation des journaux
configRotation(){
echo "Config de la rotation des journaux pour $LOG_FILE"
ROTATE_CONFIG="/etc/logrotate.d/syslog-central"
sudo tee $ROTATE_CONFIG > /dev/null <<EOL
$LOG_FILE {
    size 10M
    rotate 5
    compress
    missingok
    notifempty
}
EOL
if mycmd; then
    echo "Rotation des journaux configurée."
  else
    echo "Erreur lors de la configuration de la rotation des journaux."
    exit 1
  fi
}


restart_rsyslog() {
    sudo systemctl restart rsyslog
    if mycmd; then
        echo "restart success."
    else 
        echo "restart failed"
        exit 1
    fi     
}

configure_advanced_logging() {
  sudo tee /etc/rsyslog.d/apache.conf > /dev/null <<EOL
    if ($program == "apache2") then /var/log/apache2/error.log
EOL
    sudo tee /etc/rsyslog.d/ssh.conf > /dev/null <<EOL
    if ($program == "sshd") then /var/log/auth.log
EOL
    sudo tee /etc/rsyslog.d/mysql.conf > /dev/null <<EOL
    if ($program == "mysqld") then /var/log/mysql/error.log
EOL
  if mycmd; then
    echo "Journalisation avancée configurée."
  else
    echo "Erreur lors de la configuration de la journalisation avancée."
    exit 1
  fi
}

verify_log_configuration() {
  echo "Vérification de la configuration des journaux..."
  if [ ! -f /var/log/syslog-central.log ]; then
    echo "/var/log/syslog-central.log n'existe pas."
    return 1
  fi
  if [ ! -s /var/log/syslog-central.log ]; then
    echo "/var/log/syslog-central.log est vide."
    return 1
  fi
  # Vérifie si le fichier appartient à syslog
  if ls -l /var/log/syslog-central.log | awk '{print $3":"$4}' | grep -q "syslog:syslog"; then
  echo "Le fichier appartient à syslog:syslog"
    else
  echo "Le fichier n'appartient pas à syslog:syslog"
fi
  # Vérifie si le fichier contient des messages de log récents
  if ! grep -q "Ceci est un message de test" /var/log/syslog-central.log; then
    echo "/var/log/syslog-central.log ne contient pas de messages de test récents."
    return 1
  fi
  echo "/var/log/syslog-central.log fonctionne correctement."
  return 0
}

while true; do
    echo "\n--- Menu Interactif ---"
    echo "1. Vérification et installation de rsyslog"
    echo "2. Configuration de la journalisation centralisée"
    echo "3. Mise en place de la rotation des journaux"
    echo "4. Activation de la journalisation avancée pour les services critiques"
    echo "5. Redémarrage du service rsyslog"
    echo "6. Vérification de la configuration des journaux"
    echo "7. Quitter"
    read -p "Choisissez une option (1-7) : " CHOICE

    case $CHOICE in
        1)
            verifrsyslog;;
        2)
            configJournal;;
        3)
            configRotation;;
        4)
            configure_advanced_logging;;
        5)
            restart_rsyslog;;
        6)
            verify_log_configuration;;
        7)
            echo "bye!"
            exit 0;;
        *)
            echo "Option invalide, veuillez réessayer.";;
    esac
done

