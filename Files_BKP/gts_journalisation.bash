#! /bin/bash


# === Définir des couleurs pour les messages ===
color_B="\033[1;34m"  # Bleu clair
color_W="\033[1;37m]" # Blanc clair
color_R="\033[1;31m"  # Rouge clair
color_G="\033[1;32m"  # Vert clair
reset_color="\033[0m" # Réinitialisation des couleurs

# === Fonctions pour afficher des messages colorés ===
show_message() {
    echo -e "${color_B}$1${reset_color}"
}

show_option() {
    echo -e "${color_W}$1${reset_color}"
}

error_message() {
    echo -e "${color_R}$1${reset_color}"
}

info_message() {
    echo -e "${color_G}$1${reset_color}"
}




#check si rsylog installe
verifrsyslog(){
  if dpkg -s rsyslog &> /dev/null; then
    echo "rsyslog est déjà installé."
  else
    echo "rsyslog n'est pas installé. Installation en cours..."
    if sudo apt-get update && sudo apt-get install -y rsyslog ; then
      echo "rsyslog installé avec succès."
    else
      error_message "Erreur lors de l'installation de rsyslog."
      exit 1
    fi
  fi
}

configJournal() {
  PATH_LOG_FILE="/var/log/syslog-central.log"
  # Vérifier si le fichier de log existe, sinon le créer et donner les bonnes permissions
  if [ ! -f "$PATH_LOG_FILE" ]; then
    echo "Création du fichier de log : $PATH_LOG_FILE"
    sudo touch "$PATH_LOG_FILE"
    sudo chown syslog:adm "$PATH_LOG_FILE"  # Assure que syslog peut écrire
    sudo chmod 640 "$PATH_LOG_FILE"
    echo "fichier crée" 
  fi

  # Vérifier si la ligne existe dans /etc/rsyslog.conf, sinon l'ajouter
  if ! grep -q "^\*\.\* ${PATH_LOG_FILE}$" /etc/rsyslog.conf; then
    echo "Ajout de la configuration dans /etc/rsyslog.conf..."
    echo "*.*    $PATH_LOG_FILE" | sudo tee -a /etc/rsyslog.conf > /dev/null

    # Redémarrer rsyslog après modification
    restart_rsyslog
    echo "Journalisation centralisée configurée et rsyslog redémarré."
  else
    echo "Journalisation déjà configurée."
  fi
}

# Mise en place de la rotation des journaux
configRotation(){
    echo "Config de la rotation des journaux pour $PATH_LOG_FILE"
    PATH_ROTATE_CONFIG="/etc/logrotate.d/syslog-central"
    if sudo tee "$PATH_ROTATE_CONFIG" > /dev/null <<EOL
$PATH_LOG_FILE {
    size 10M
    rotate 5
    compress
    missingok
    notifempty
}
EOL
    then
        echo "Rotation des journaux configurée."
    else
        error_message "Erreur lors de la configuration de la rotation des journaux."
        exit 1
    fi
}

restart_rsyslog() {
    if sudo systemctl restart rsyslog; then
        echo "restart success."
    else 
        error_message "restart failed"
        exit 1
    fi     
}

configure_advanced_logging() {
    if sudo tee /etc/rsyslog.d/apache.conf > /dev/null <<EOL
if \$programname == 'apache2' then /var/log/apache2/error.log
EOL && sudo tee /etc/rsyslog.d/ssh.conf > /dev/null <<EOL
if \$programname == 'sshd' then /var/log/auth.log
EOL && sudo tee /etc/rsyslog.d/mysql.conf > /dev/null <<EOL
if \$programname == 'mysqld' then /var/log/mysql/error.log
EOL
    then
        echo "Journalisation avancée configurée."
    else
        error_message "Erreur lors de la configuration de la journalisation avancée."
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
    echo "--- Menu Interactif ---"
    show_option "1. Vérification et installation de rsyslog"
    show_option "2. Configuration de la journalisation centralisée"
    show_option "3. Mise en place de la rotation des journaux"
    show_option "4. Activation de la journalisation avancée pour les services critiques"
    show_option "5. Redémarrage du service rsyslog"
    show_option "6. Vérification de la configuration des journaux"
    show_option "7. Quitter"
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
            error_message "Option invalide, veuillez réessayer.";;
    esac
done

