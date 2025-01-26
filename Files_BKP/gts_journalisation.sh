#!/bin/bash

# === Définir des couleurs pour les messages ===
color_B="\033[1;34m"  # Bleu clair
color_R="\033[1;31m"  # Rouge clair
color_G="\033[1;32m"  # Vert clair
reset_color="\033[0m" # Réinitialisation des couleurs

# === Fonctions pour afficher des messages colorés ===
show_message() {
    echo -e "${color_B}$1${reset_color}"
}

error_message() {
    echo -e "${color_R}$1${reset_color}"
}

info_message() {
    echo -e "${color_G}$1${reset_color}"
}

# === Fonction pour vérifier et installer rsyslog ===
check_install_rsyslog() {
    show_message "Vérification de rsyslog..."
    if ! dpkg -l | grep -qw rsyslog; then
        show_message "rsyslog n'est pas installé. Installation en cours..."
        sudo apt update
        sudo apt install -y rsyslog
        info_message "rsyslog installé avec succès."
    else
        show_message "rsyslog est déjà installé."
    fi
}

# === Fonction pour configurer la journalisation centralisée ===
configure_central_logging() {
    show_message "Vérification de la configuration de la journalisation centralisée..."

    # Vérifie si la configuration est déjà présente dans le fichier rsyslog.conf
    if grep -q "^*.* /var/log/syslog-central.log" /etc/rsyslog.conf; then
        error_message "La journalisation centralisée est déjà configurée."
    else
        show_message "Configuration de la journalisation centralisée..."
        echo "*.* /var/log/syslog-central.log" | sudo tee -a /etc/rsyslog.conf
        info_message "Journalisation centralisée configurée dans /var/log/syslog-central.log."
        sudo systemctl restart rsyslog
        show_message "Service rsyslog redémarré pour appliquer les changements."
    fi
}

# === Fonction pour mettre en place la rotation des journaux ===
setup_log_rotation() {
    show_message "Vérification de la configuration de la rotation des journaux..."

    # Vérifie si le fichier de configuration existe et contient déjà les paramètres nécessaires
    if [ -f /etc/logrotate.d/rsyslog ] && grep -q "/var/log/syslog-central.log" /etc/logrotate.d/rsyslog; then
        error_message "La rotation des journaux est déjà configurée."
    else
        show_message "Mise en place de la rotation des journaux..."
        cat <<EOF | sudo tee /etc/logrotate.d/rsyslog
/var/log/syslog-central.log {
    rotate 7
    daily
    compress
    missingok
    notifempty
    create 0640 root adm
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
        info_message "Rotation des journaux configurée dans /etc/logrotate.d/rsyslog."
    fi
}

# === Fonction pour activer la journalisation avancée pour les services critiques ===
enable_advanced_logging() {
    show_message "Vérification et activation de la journalisation avancée..."

    for service in apache2 sshd mysql; do
        # Vérifie si la configuration existe déjà dans rsyslog.conf
        if grep -q "if \\$programname == \"$service\" then /var/log/$service.log" /etc/rsyslog.conf; then
            info_message "La journalisation avancée est déjà configurée pour $service."
        else
            show_message "Configuration de la journalisation avancée pour $service..."
            echo "if \$programname == \"$service\" then /var/log/$service.log" | sudo tee -a /etc/rsyslog.conf
            
            # Vérifier si le fichier de log existe.
            if [ ! -f /var/log/$service.log ]; then
				show_message Création des fichiers de logs.
                sudo touch /var/log/$service.log
			else
				error_message Attention ! fichier de log déjà créer.
            fi

            # Applique les permissions correctes
            sudo chmod 640 /var/log/$service.log
            sudo chown syslog:adm /var/log/$service.log
        fi
    done

    # Redémarre rsyslog pour appliquer les modifications
    sudo systemctl restart rsyslog
    info_message "Journalisation avancée activée pour Apache, SSH et MySQL."
}

# === Fonction pour vérifier la configuration ===
verify_configuration() {
    show_message "Vérification de la configuration des journaux..."
    logger "Test de journalisation pour vérifier la configuration."
    sleep 2
    if grep -q "Test de journalisation" /var/log/syslog-central.log; then
        info_message "La configuration est opérationnelle."
    else
        error_message "Problème détecté dans la configuration."
    fi
}

# === Menu principal ===
while true; do
    show_message " === Menu de configuration de la journalisation système ==="
    echo "1) Vérification et installation de rsyslog"
    echo "2) Configuration de la journalisation centralisée"
    echo "3) Mise en place de la rotation des journaux"
    echo "4) Activation de la journalisation avancée pour les services critiques"
    echo "5) Redémarrage du service rsyslog"
    echo "6) Vérification de la configuration des journaux"
    echo "7) Quitter"
    read -p "Choisissez une option : " option

    case $choix in
        1) check_install_rsyslog ;;
        2) configure_central_logging ;;
        3) setup_log_rotation ;;
        4) enable_advanced_logging ;;
        5) restart_rsyslog ;;
        6) verify_logging ;;
        7) echo "Sortie." ; exit 0 ;;
        *) echo "Option invalide. Veuillez réessayer." ;;
    esac
done

