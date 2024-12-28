#!/bin/bash

# Définir l'utilisateur et le répertoire
USER=$(whoami)
LOG_DIR="/home/$USER/logs"

# Créer le répertoire de logs s'il n'existe pas
mkdir -p "$LOG_DIR"

# Exécuter la commande du et afficher l'espace utilisé
du -sh /home/"$USER" | awk '{print $1 " utilisé sur un maximum de 10 Go"}' >> "$LOG_DIR/cron_space_disk.log" 2>&1