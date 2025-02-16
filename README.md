# Projet LPIC101 - Administration Linux Avancée

## Contexte

Ce projet s'inscrit dans le cadre de la certification **LPIC101** et vise à mettre en pratique les compétences en administration Linux à travers la création de plusieurs script bash utilisant les commandes vue en cours et à l'aide de nos connaissance.

L'objectif est de permettre aux agents RH, aux employés et à l'équipe IT de gérer facilement des tâches d'administration système essentielles au sein d'une petite entreprise.

## Fonctionnalités

Ce projet propose plusieurs scripts Bash permettant d'automatiser des tâches comme :

- **Gestion des utilisateurs et des groupes** : Création, suppression et gestion des utilisateurs et groupes.
- **Automatisation avec cron** : Planification et gestion des tâches automatisées.
- **Surveillance du système** : Monitoring de l'espace disque, des processus et de la mémoire.
- **Sauvegarde de fichiers** : Sauvegarde manuelle et planifiée des données critiques.
- **Configuration de la journalisation** : Gestion centralisée des logs avec rsyslog.

## Installation

Le projet repose sur **Vagrant** et **VirtualBox** pour la création d'une machine virtuelle Debian prête à l'emploi.

### 1. Installer VirtualBox et Vagrant

#### Sous Debian/Ubuntu :

```bash
sudo apt update && sudo apt install virtualbox vagrant -y
```

#### Sous Windows :

- [Télécharger VirtualBox v7](https://www.virtualbox.org/wiki/Downloads) et l'installer.
- [Télécharger Vagrant](https://www.vagrantup.com/downloads) et l'installer.

### 2. Installer les plugins Vagrant pour VirtualBox

```bash
vagrant plugin install vagrant-vbguest
```

## Démarrage du projet

### 1. Cloner le dépôt

```bash
git clone <URL_DU_DEPOT>
cd <NOM_DU_DEPOT>
```

### 2. Démarrer la machine virtuelle

```bash
vagrant up
```

> **Remarque :** Il se peut que pendant la config il vous demande de redémarrer manuellement la vm et de refaire un vagrant up.

### 3. Accéder à la machine virtuelle

```bash
vagrant ssh
```

## Utilisation des scripts

Une fois connecté à la VM, vous pouvez exécuter les scripts disponibles dans le projet :

```bash
gts_utilisateurs.sh   # Gestion des utilisateurs et groupes
gts_cron.sh           # Gestion des tâches cron
gts_surveillance.sh   # Monitoring système
gts_sauvegarde.sh     # Sauvegarde des fichiers
gts_journalisation.sh # Configuration des logs
```

Faite appel à la commande `gts_main` dans votre terminal.

---
