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

# === Fonction pour créer un utilisateur ===
create_user() {
    read -p "Entrez le nom d'utilisateur : " username
    if id "$username" &>/dev/null; then
        error_message "L'utilisateur $username existe déjà."
    else
        password=$(openssl rand -base64 12)
        doas adduser "$username"
        echo "$username:$password" | doas chpasswd
        info_message "Utilisateur $username créé avec succès."
        echo -e "$(date)\t$username\t$password" >>/etc/new_agents/new_agents.txt
    fi
}

# === Fonction pour supprimer un utilisateur ===
delete_user() {
    read -p "Entrez le nom d'utilisateur à supprimer : " username
    if id "$username" &>/dev/null; then
        doas userdel -r "$username"
        info_message "Utilisateur $username supprimé avec succès."
    else
        error_message "L'utilisateur $username n'existe pas."
    fi
}

# === Fonction pour créer un groupe ===
create_group() {
    read -p "Entrez le nom du groupe : " groupname
    if getent group "$groupname" &>/dev/null; then
        error_message "Le groupe $groupname existe déjà."
    else
        doas groupadd "$groupname"
        info_message "Groupe $groupname créé avec succès."
    fi
}

# === Fonction pour ajouter un utilisateur à un groupe ===
assign_user_to_group() {
    read -p "Entrez le nom d'utilisateur : " username
    read -p "Entrez le nom du groupe : " groupname
    if id "$username" &>/dev/null && getent group "$groupname" &>/dev/null; then
        doas usermod -aG "$groupname" "$username"
        info_message "Utilisateur $username ajouté au groupe $groupname."
    else
        error_message "Utilisateur ou groupe non trouvé."
    fi
}

# === Fonction pour configurer un quota disque ===
set_user_quota() {
    read -p "Entrez le nom d'utilisateur : " username
    if id "$username" &>/dev/null; then
        doas setquota -u "$username" 2097152 2097152 0 0 /home
        info_message "Quota de 2 Go défini pour l'utilisateur $username."
    else
        error_message "L'utilisateur $username n'existe pas."
    fi
}

# === Fonction pour configurer l'autorisation d'utiliser systmctl ===
set_user_systemctl() {
    read -p "Entrez le nom d'utilisateur : " username
    if id "$username" &>/dev/null; then
        echo " # === Autorise $username à gerer le service apache ===
        permit nopass $username cmd systemctl args restart apache2
        permit nopass $username cmd systemctl args start apache2
        permit nopass $username cmd systemctl args stop apache2" | doas tee -a /etc/doas.conf
        info_message "Accès systemctl configuré pour $username."
    else
        error_message "L'utilisateur $username n'existe pas."
    fi
}

# === Menu principal ===
while true; do
    show_message "\n=== Menu Gestion des Utilisateurs ==="
    echo "1. Créer un utilisateur"
    echo "2. Supprimer un utilisateur"
    echo "3. Créer un groupe"
    echo "4. Affecter un utilisateur à un groupe"
    echo "5. Définir un quota disque pour un utilisateur"
    echo "6. Configurer la gestion du service Apache"
    echo "7. Quitter"
    read -p "Choisissez une option : " choix

    case $choix in
    1) create_user ;;
    2) delete_user ;;
    3) create_group ;;
    4) assign_user_to_group ;;
    5) set_user_quota ;;
    6) set_user_systemctl ;;
    7)
        info_message "Sortie." ; break ;;
    *) error_message "Option invalide. Veuillez réessayer." ;;
    esac
    echo
done
