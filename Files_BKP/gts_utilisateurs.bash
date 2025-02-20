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

# === Fonction pour créer un utilisateur ===
create_user() {
    read -r -p "Entrez le nom d'utilisateur : " username
    if id "$username" &>/dev/null; then
        error_message "L'utilisateur $username existe déjà."
    else
        password=$(openssl rand -base64 12)
        doas adduser --disabled-password --allow-bad-names "$username"
        echo "$username:$password" | doas chpasswd
        info_message "Utilisateur $username créé avec succès."
        echo -e "$(date)\t$username\t$password" | doas tee -a /etc/new_agents/new_agents.txt > /dev/null
    fi
}

# === Fonction pour supprimer un utilisateur ===
delete_user() {
    read -r -p "Entrez le nom d'utilisateur à supprimer : " username
    if id "$username" &>/dev/null; then
        if doas userdel -r "$username" &>/dev/null; then
            info_message "Utilisateur $username supprimé avec succès."
        else
            error_message "Une erreur s'est produite lors de la suppression de l'utilisateur $username."
        fi
    else
        error_message "L'utilisateur $username n'existe pas."
    fi
}

# === Fonction pour créer un groupe ===
create_group() {
    read -r -p "Entrez le nom du groupe : " groupname
    if getent group "$groupname" &>/dev/null; then
        error_message "Le groupe $groupname existe déjà."
    else
        doas groupadd "$groupname"
        info_message "Groupe $groupname créé avec succès."
    fi
}

# === Fonction pour ajouter un utilisateur à un groupe ===
assign_user_to_group() {
    read -r -p "Entrez le nom d'utilisateur : " username
    read -r -p "Entrez le nom du groupe : " groupname
    if id "$username" &>/dev/null && getent group "$groupname" &>/dev/null; then
        doas usermod -aG "$groupname" "$username"
        info_message "Utilisateur $username ajouté au groupe $groupname."
    else
        error_message "Utilisateur ou groupe non trouvé."
    fi
}

# === Fonction pour configurer un quota disque ===
set_user_quota() {
    while true; do
        read -r -p "Entrez le nom d'utilisateur : " username
        if id "$username" &>/dev/null; then
            show_message "Utilisateur trouvé : $username"

            while true; do
                show_message "Quelle quantité d'espace disque souhaitez-vous attribuer ? (1Go ou 2Go)"
                read -r -p "Entrez 1 ou 2 : " space_choice

                if [ "$space_choice" == "1" ]; then
                    quota_size="1048576" # 1 Go en blocs de 1 Ko
                    info_message "Vous avez choisi 1 Go pour $username."
                    break
                elif [ "$space_choice" == "2" ]; then
                    quota_size="2097152" # 2 Go en blocs de 1 Ko
                    info_message "Vous avez choisi 2 Go pour $username."
                    break
                else
                    error_message "Choix invalide. Veuillez entrer 1 ou 2."
                fi
            done

            # Appliquer le quota sur le répertoire de l'utilisateur
            home_dir="/mnt/data_disk"
            if [ -d "$home_dir" ]; then
                info_message "Application du quota de $quota_size sur l'utilisateur : $username"

                # Configuration du quota (assurez-vous que le système prend en charge les quotas (repquota -a))
                if sudo setquota -u "$username" 0 "$quota_size" 0 0 "$home_dir"; then
                    info_message "Quota appliqué avec succès pour $username."
                else    
                    error_message "Échec de l'application du quota."
                fi
            else
                error_message "Le répertoire de l'utilisateur n'existe pas ou n'est pas accessible : $home_dir"
            fi
            break
        else
            error_message "Utilisateur $username introuvable. Veuillez réessayer."
        fi
    done
}

# === Fonction pour configurer l'autorisation d'utiliser systmctl ===
set_user_systemctl() {
    read -r -p "Entrez le nom d'utilisateur : " username
    if id "$username" &>/dev/null; then
        echo " # === Autorise $username à gerer le service apache ===
        permit nopass $username cmd systemctl args restart apache2
        permit nopass $username cmd systemctl args start apache2
        permit nopass $username cmd systemctl args status apache2
        permit nopass $username cmd systemctl args stop apache2" | doas tee -a /etc/doas.conf
        info_message "Accès systemctl configuré pour $username."
    else
        error_message "L'utilisateur $username n'existe pas."
    fi
}

# === Menu principal ===
while true; do
    show_message "=== Menu Gestion des Utilisateurs ==="
    show_option "1. Créer un utilisateur"
    show_option "2. Supprimer un utilisateur"
    show_option "3. Créer un groupe"
    show_option "4. Affecter un utilisateur à un groupe"
    show_option "5. Définir un quota disque pour un utilisateur"
    show_option "6. Configurer la gestion du service Apache"
    show_option "7. Quitter"
    read -r -p "Choisissez une option : " choix

    case $choix in
        1) create_user ;;
        2) delete_user ;;
        3) create_group ;;
        4) assign_user_to_group ;;
        5) set_user_quota ;;
        6) set_user_systemctl ;;
        7) info_message "Sortie." ; exit 0 ;;
        *) error_message "Option invalide, veuillez réessayer." ;;
    esac
    echo
done
