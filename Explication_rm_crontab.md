Ce script permet de modifier les tâches planifiées dans le fichier `crontab` de l'utilisateur en suivant une série d'étapes bien définies. Voici comment il fonctionne :

---

### 1. **Sauvegarde des tâches cron dans un fichier temporaire** :
   - La commande `crontab -l` liste toutes les tâches cron de l'utilisateur.
   - Le résultat est redirigé dans un fichier temporaire (ici, `crontab_temp.txt`).
     ```bash
     crontab -l > crontab_temp.txt
     ```
   - **Pourquoi ?** Cela permet de manipuler la liste des tâches comme un fichier texte ordinaire.

---

### 2. **Affichage des tâches avec numérotation** :
   - La commande `cat -n` affiche le contenu de `crontab_temp.txt` en numérotant chaque ligne.
     ```bash
     cat -n crontab_temp.txt
     ```
   - **Pourquoi ?** La numérotation aide l'utilisateur à repérer facilement la tâche qu'il souhaite supprimer.

---

### 3. **Lecture de l'entrée utilisateur** :
   - La commande `read` capture le numéro de ligne que l'utilisateur veut supprimer.
     ```bash
     read -p "Entrez le numéro de la tâche à supprimer : " ligne
     ```
   - **Pourquoi ?** Cela permet au script de cibler une tâche spécifique basée sur le choix de l'utilisateur.

---

### 4. **Suppression de la tâche sélectionnée** :
   - La commande `sed -i "${ligne}d"` supprime la ligne correspondant au numéro choisi.
     ```bash
     sed -i "${ligne}d" crontab_temp.txt
     ```
   - **Pourquoi ?** Le script modifie le fichier temporaire pour retirer uniquement la tâche sélectionnée.

---

### 5. **Mise à jour de crontab avec le fichier modifié** :
   - La commande `crontab crontab_temp.txt` recharge le fichier temporaire dans le système cron.
     ```bash
     crontab crontab_temp.txt
     ```
   - **Pourquoi ?** Cela remplace la liste des tâches cron de l'utilisateur par le contenu mis à jour du fichier temporaire.

---

### 6. **Nettoyage du fichier temporaire** :
   - Le fichier temporaire est supprimé pour éviter l'encombrement.
     ```bash
     rm crontab_temp.txt
     ```
   - **Pourquoi ?** Une fois la mise à jour effectuée, le fichier n'est plus nécessaire.

---

### Pourquoi ces changements affectent-ils réellement `crontab` ?
Le système `cron` utilise des fichiers dédiés pour stocker les tâches planifiées, généralement localisés dans `/var/spool/cron/crontabs/<nom_utilisateur>`. La commande `crontab` fournit une interface pour manipuler ces fichiers de manière sécurisée. Voici comment cela fonctionne :

1. **Lecture des tâches existantes** :
   - `crontab -l` extrait le contenu du fichier cron pour l'utilisateur courant.

2. **Modification hors ligne** :
   - Les modifications sont effectuées sur une copie temporaire du fichier, évitant toute corruption du fichier original.

3. **Mise à jour du fichier cron** :
   - `crontab <fichier>` remplace le fichier cron de l'utilisateur par le contenu du fichier fourni.

---
