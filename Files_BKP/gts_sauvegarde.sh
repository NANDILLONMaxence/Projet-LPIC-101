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

# Dossier de base pour les sauvegardes
BASE_DIR="/mnt/data_disk/DEP"

# === Vérification département et groupe ===
verif_dep_groupe() {
  read -p "Entrez le nom du département à initialiser : " DEPARTEMENT
  DEP_DIR="$BASE_DIR/$DEPARTEMENT"

  # === Vérifier si le groupe existe ===
  if ! getent group "$DEPARTEMENT" > /dev/null; then
    error_message "Le groupe $DEPARTEMENT n'existe pas. Veuillez demander à un administrateur de le créer."
    return
  fi

  # === Vérifier si le dossier existe ===
  if [ ! -d "$DEP_DIR" ]; then
    mkdir -p "$DEP_DIR"
    info_message "Dossier créé : $DEP_DIR"
  else
    show_message "Le dossier $DEP_DIR existe."
  fi
}

# === Sauvegarde manuelle ===
sauvegarde_manuelle() {
  show_message "Sauvegarde manuelle :"
  read -p "Entrez le nom du département ou du groupe : " DEPARTEMENT
  DEP_DIR="$BASE_DIR/$DEPARTEMENT"

  if [ -d "$DEP_DIR" ]; then
    read -p "Entrez le chemin du fichier ou dossier à sauvegarder : " SOURCE
    if [ -e "$SOURCE" ]; then
      cp -r "$SOURCE" "$DEP_DIR"
      info_message "Sauvegarde réussie dans $DEP_DIR"
    else
      error_message "Le fichier ou dossier spécifié n'existe pas."
    fi
  else
    error_message "Le département $DEPARTEMENT n'existe pas. Veuillez l'initialiser d'abord."
  fi
}

# === Planification d'une tâche cron pour la sauvegarde automatique ===
planifier_sauvegarde() {
  show_message "Planification d'une tâche cron :"
  read -p "Entrez le nom du département : " DEPARTEMENT
  DEP_DIR="$BASE_DIR/$DEPARTEMENT"

  if [ -d "$DEP_DIR" ]; then
    read -p "Entrez le chemin du fichier ou dossier à sauvegarder automatiquement : " SOURCE
    if [ -e "$SOURCE" ]; then
      info_message "Exemple de définition de job :"
      info_message ".---------------- minute (0 - 59)"
      info_message "|  .------------- heure (0 - 23)"
      info_message "|  |  .---------- jour du mois (1 - 31)"
      info_message "|  |  |  .------- mois (1 - 12) OU jan,feb,mar,apr ..."
      info_message "|  |  |  |  .---- jour de la semaine (0 - 6) (Dimanche=0 ou 7) OU sun,mon,tue,wed,thu,fri,sat"
      info_message "|  |  |  |  |"
      info_message "*  *  *  *  *"
      read -p "Entrez la fréquence de la sauvegarde (ex : '0 2 * * *' pour tous les jours à 2h) : " FREQUENCE
      CRON_CMD="$FREQUENCE cp -r $SOURCE $DEP_DIR"
      (crontab -l; echo "$CRON_CMD") | crontab -
      info_message "Tâche cron ajoutée avec succès : $CRON_CMD"
    else
      error_message "Le fichier ou dossier spécifié n'existe pas."
    fi
  else
    error_message "Le département $DEPARTEMENT n'existe pas. Veuillez l'initialiser d'abord."
  fi
}

# === Menu principal ===
while true; do
    show_message "=== Menu de configuration sauvegarde ==="
    echo "1. Initialiser ou créer un département"
    echo "2. Sauvegarde manuelle"
    echo "3. Planifier une sauvegarde automatique"
    echo "4. Quitter"
    read -p "Sélectionnez une option : " CHOIX

    case $CHOIX in
      1) verif_dep_groupe ;;
      2) sauvegarde_manuelle ;;
      3) planifier_sauvegarde ;;
      4) show_message "Sortie." ; exit 0 ;;
      *) error_message "Option invalide, veuillez réessayer." ;;
    esac
done
