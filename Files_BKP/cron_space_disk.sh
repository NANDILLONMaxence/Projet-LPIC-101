#!/bin/bash

# === Fonction pour surveiller l'utilisation de l'espace disque ===
check_user_disk_space() {
    user_dir="$1"
    log_dir="$2"

    # Créer le répertoire de logs s'il n'existe pas
    mkdir -p "$log_dir"

    # Calculer l'espace utilisé et consigner dans le fichier de log
    du -sh "$user_dir" | awk '{print $1 " utilisé sur un maximum de 10 Go"}' >> "$log_dir/cron_space_disk.log" 2>&1

    # Afficher un message de confirmation
    echo "L'utilisation de l'espace disque a été enregistrée dans $log_dir/cron_space_disk.log."
}

# === Variables ===
USER=$(whoami)
USER_HOME="/home/$USER"
LOG_DIR="/home/$USER/logs"

# === Appeler la fonction ===
check_user_disk_space "$USER_HOME" "$LOG_DIR"