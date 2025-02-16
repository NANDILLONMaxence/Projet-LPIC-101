#!/bin/bash

# === Définir des couleurs pour les messages ===
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

# Fonction pour surveiller l'espace disque
check_disk_space() {
    show_message "=== Surveillance de l'espace disque ==="
    df -h | column -t
    echo
}

# Fonction pour afficher les processus en temps réel
launch_htop() {
    if command -v htop > /dev/null; then
        show_message "=== Lancement de htop ==="
        htop
    else
        error_message "htop n'est pas installé. Veuillez l'installer en utilisant votre gestionnaire de paquets (par exemple, apt, yum, ou pacman)."
    fi
}

# Fonction pour lister les processus actifs
list_processes() {
    show_message "=== Suivi des processus actifs ==="
    info_message "Resumer processus par utilisation CPU :"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 11
    echo
    info_message "Resumer processus par utilisation MEM :"
    ps -eo pid,comm,%mem --sort=-%mem | head -n 11
    echo
}


# Fonction pour surveiller l'utilisation de la mémoire
check_memory_usage() {
    show_message "=== Surveillance de l'utilisation de la mémoire ==="
    free -h
    echo
}

# Fontion pour Afficher l'utilisation de l'espace disque par utilisateur
check_space_user_disk() {
    show_message "=== Surveillance de l'utilisation de l'espace disque par utilisateur ==="
    doas repquota -a
    echo
}

# === Menu principal ===
while true; do
    show_message "=== Menu de surveillance du serveur ==="
    show_option "1. Surveiller l'espace disque"
    show_option "2. Lister les processus actifs (en temps réel)"
	show_option "3. TOP 10 des processus par utilisation CPU/MEM"
    show_option "4. Surveiller l'utilisation de la mémoire"
    show_option "5. Surveiller l'utilisation de l'espace disque par utilisateur"
    show_option "6. Quitter"
    echo
    read -r -p "Choisissez une option : " choix
    echo

    case $choix in
        1) check_disk_space ;;
        2) launch_htop ;;
        3) list_processes ;;
		4) check_memory_usage ;;
        5) check_space_user_disk ;;			
        6) info_message "Sortie." ; exit 0 ;;
        *) error_message "Option invalide, veuillez réessayer." ;;
    esac
    echo
done
