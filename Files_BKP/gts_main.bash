#!/bin/bash

#  permet de changer le répertoire de travail vers le répertoire du script
if ! cd "$(dirname "$0")"; then
    error_message "Erreur : Impossible de changer le répertoire vers $(dirname "$0")" >&2
    exit 1
fi

# === Définition des couleurs ===
color_B="\033[1;34m"  # Bleu clair
color_W="\033[1;37m"  # Blanc clair
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

# Chemins des scripts
SCRIPT_UTILISATEURS="./gts_utilisateurs.bash"
SCRIPT_SURVEILLANCE="./gts_surveillance.bash"
SCRIPT_CRON="./gts_cron.bash"
SCRIPT_SAUVEGARDE="./gts_sauvegarde.bash"
SCRIPT_JOURNALISATION="./gts_journalisation.bash"

# Journalisation des erreurs
LOG_FILE="/var/log/gts_menu.log"

# Vérifier si l'utilisateur peut exécuter un script
check_permission() {
    local script=$1
    if [ -x "$script" ]; then
        return 0  # Autorisé
    else
        error_message "Accès refusé : Vous n'avez pas la permission d'exécuter $script"
        error_message "Cette tentative a été journalisée."
        echo "$(date) - $(whoami) a tenté d'exécuter $script sans permission." | sudo tee -a "$LOG_FILE" > /dev/null
        return 1  # Refusé
    fi
}

# === Menu principal ===
while true; do
    clear
    show_message "=== Menu Principal GTS ==="
    show_option "1. Gestion des utilisateurs"
    show_option "2. Surveillance du système"
    show_option "3. Gestion des taches avec cron"  
    show_option "4. Gestion des sauvegardes" 
    show_option "5. Gestion de la journalisation"
    show_option "6. Quitter"
    echo
    read -r -p "Sélectionnez une option : " CHOIX

    case $CHOIX in
        1) check_permission "$SCRIPT_UTILISATEURS" && bash "$SCRIPT_UTILISATEURS" ;;
        2) check_permission "$SCRIPT_SURVEILLANCE" && bash "$SCRIPT_SURVEILLANCE" ;;
        3) check_permission "$SCRIPT_CRON" && bash "$SCRIPT_CRON" ;;
        4) check_permission "$SCRIPT_SAUVEGARDE" && bash "$SCRIPT_SAUVEGARDE" ;;
        5) check_permission "$SCRIPT_JOURNALISATION" && bash "$SCRIPT_JOURNALISATION" ;;
        6) info_message "Sortie du menu." ; exit 0 ;;
        *) error_message "Option invalide, veuillez réessayer." ;;
    esac

    read -r -p "Appuyez sur Entrée pour continuer..."
done
