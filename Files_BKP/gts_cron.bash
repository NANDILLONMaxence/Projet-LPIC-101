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

# === Menu principal ===
while true; do
    show_message "=== Gestion des taches automatiques ==="
	show_option "1. Lister les taches cron"
    show_option "2. Ajouter une tache cron"
    show_option "3. Supprimer une tâche cron"
    show_option "4. Quitter"
	echo
    read -r -p "Choisissez une option : " choix
	echo

    case $choix in

		1)
            show_message "=== Liste des taches ==="
			crontab -l
			echo
            continue ;;
        2)
            # Sous-menu pour planifier une tâche
            show_message "=== Planification de tache ==="
            show_option "Commandes disponibles :"
            show_option "1. Mettre en place le check space sur votre compte"
            show_option "2. Supprimer un fichier (ex. : nettoyer des anciens fichiers)"
			show_option "3. Personnaliser la Planification de tache"
			show_option "4. Retour au menu principal."
			echo
            read -r -p "Choisissez une commande à planifier : " commande
			echo

			case $commande in
				1)
					cmd="/etc/cron_script/cron_space_disk.sh" # Emplacement du script
					schedule="0 9 * * *" # Exécution automatique à 9h tous les jours
					echo ;;
				2)
					read -r -p "Entrez le chemin de votre fichier : " chemin
					cmd="rm $chemin" ;;
				3)
					read -r -p "Entrez votre commande personnalisée : " cmd ;;
				4)
					show_message "Retour au menu principal." ; continue ;;
	
				*)
					error_message "Commande invalide, exit" ; exit 1 ;;
			esac

			# Si l'utilisateur a choisi une commande autre que les options 3 ou 4, demander la fréquence
			if [ "$commande" -ne 1 ] && [ "$commande" -ne 4 ]; then
				# Propose des horaires courants
				echo
				show_message "=== Fréquences disponibles ==="
				show_option "1. Tous les jours à minuit"
				show_option "2. Tous les jours à 7h du matin"
				show_option "3. Tous les jours à midi"
				show_option "4. Tous les vendredis à 19h"
				show_option "5. Une fois par mois (1er du mois à minuit)"
				show_option "6. Une fois tous les deux mois (1er du mois impair à minuit)"
				show_option "7. Toutes les heures"
				show_option "8. Personnaliser la fréquence"
				show_option "9. Retour au menu principal."
				echo
				read -r -p "Choisissez une fréquence : " frequence
				echo

				case $frequence in
					1)
						schedule="0 0 * * *" ;;
					2)
						schedule="0 7 * * *" ;;
					3)
						schedule="0 12 * * *" ;;
					4)
						schedule="0 19 * * 5" ;;
					5)
						schedule="0 0 1 * *" ;;
					6)
						schedule="0 0 1 */2 *" ;;
					7)
						schedule="0 * * * *" ;;
					8)
						info_message "Exemple de définition de job :"
						info_message ".---------------- minute (0 - 59)"
						info_message "|  .------------- heure (0 - 23)"
						info_message "|  |  .---------- jour du mois (1 - 31)"
						info_message "|  |  |  .------- mois (1 - 12) OU jan,feb,mar,apr ..."
						info_message "|  |  |  |  .---- jour de la semaine (0 - 6) (Dimanche=0 ou 7) OU sun,mon,tue,wed,thu,fri,sat"
						info_message "|  |  |  |  |"
						info_message "*  *  *  *  *"
						read -r -p "Votre fréquence : " schedule ;;
					9)
						show_message "Retour au menu principal." ; continue ;;
					*)
						error_message "Fréquence invalide, exit." ; exit 1 ;;
				esac
			fi

            # Ajout de la tâche au cron
			echo
            (crontab -l ; echo "$schedule $cmd") | crontab -
            info_message "Tâche ajoutée : '$cmd' sera exécutée selon l'horaire : $schedule" ;;
        3)
            # Sauvegarder les tâches cron dans un fichier temporaire
			crontab_temp="/tmp/crontab_temp.txt"
			if ! crontab -l > "$crontab_temp"; then
				error_message "Erreur : impossible de lire la liste des tâches cron."
				exit 1
			fi

			# Afficher les tâches avec numérotation
			cat -n "$crontab_temp"
			
			# Demander à l'utilisateur le numéro de la tâche à supprimer
			read -r -p "Entrez le numéro de la tâche à supprimer : " ligne

			# Supprimer la tâche spécifiée
			if ! sed -i "${ligne}d" "$crontab_temp"; then
				error_message "Erreur : impossible de supprimer la ligne ${ligne}."
				exit 1
			fi

			# Charger les modifications dans crontab
			if ! crontab "$crontab_temp"; then
				error_message "Erreur : impossible de mettre à jour crontab."
				exit 1
			fi

			# Supprimer le fichier temporaire
			rm -f "$crontab_temp"
			echo
			info_message "Tâche supprimée avec succès." ; echo ;;
        4)
            info_message "Sortie." ; echo ; exit 0 ;;
        *)
            error_message "Option invalide, veuillez réessayer." ; echo ;;
    esac
done

