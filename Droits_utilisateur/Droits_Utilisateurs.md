Aperçu des droits d'accès des groupes et utilisateurs sur les fichiers, dossiers et commandes disponibles.

---

### **📂 Permissions par Fichier/Dossier**  

#### **📂 Répertoire `/etc/gts`**  

- 📜 `gts_main.bash` → **Tous** (`755`) ✅ *Lecture/Exécution pour tous*  

- 📜 `gts_utilisateurs.bash` → **RH** (`750`) 🔒 *Accès limité au groupe RH*  
  - 🚫 **IT et autres utilisateurs** → **Ne peuvent pas lire ni exécuter ce fichier**  

- 📜 `gts_cron.bash` → **Tous** (`755`) ✅ *Lecture/Exécution pour tous*  

- 📜 `gts_surveillance.bash` → **IT** (`750`) 🔒 *Accès limité au groupe IT*  
  - 🚫 **RH et autres utilisateurs** → **Ne peuvent pas lire ni exécuter ce fichier**  
 
- 📜 `gts_journalisation.bash` → **IT** (`750`) 🔒 *Accès limité au groupe IT*  
  - 🚫 **RH et autres utilisateurs** → **Ne peuvent pas lire ni exécuter ce fichier**  

#### **📂 Répertoire `/etc/new_agents`**  

- 📜 `new_agents.txt` → **IT** (`2750`) 🔒 *Lecture/Écriture pour IT, pas d'accès aux autres*  
  - 🚫 **RH et autres utilisateurs** → **Ne peuvent pas voir ou modifier ce fichier**  

#### **📂 Répertoire `/etc/cron_script`**  

- 📜 `cron_space_disk.bash` → **Tous** (`755`) ✅ *Exécutable par tous*  

---

### **📜 Droits et Restrictions Sudo (`/etc/sudoers`)**  

- ✅ **Groupe IT** : Peut exécuter **toutes les commandes** avec `sudo`.  
- ✅ **Groupe RH** : Peut exécuter `setquota` sans mot de passe.  

- 🚫 **RH** **ne peut pas** :  
  - Modifier la configuration sudo (`/etc/sudoers`).  
  - Obtenir des droits root sur des commandes autres que `setquota`.  
  - Ajouter/supprimer des utilisateurs **hors du groupe RH**.  

---

<font color="#ffffff">o</font>
<font color="#ffffff">o</font>
### **📜 Droits et Restrictions Doas (`/etc/doas.conf`)**

**RH peut :**  

✅ Gérer utilisateurs/groupes (`adduser`, `userdel`, etc.).  
✅ Modifier `/etc/doas.conf` et `/etc/new_agents/new_agents.txt`.  
✅ Configurer les quotas (`setquota`).  

🚫 **RH ne peut pas :**  
  - **Supprimer le groupe** `sudo` ou `IT` (`groupdel sudo`, `groupdel IT`).
  - **Supprimer des utilisateurs IT** (`gpasswd -d IT`).  
  - **Modifier les permissions des fichiers sensibles** (`chmod 440 /etc/sudoers.d/root`).  

✅ **IT peut :**  
  - Lire les quotas (`repquota`).  
  
🚫 **IT ne peut pas :**  
  - Modifier les permissions de `RH` sur `doas.conf`.  
  - Gérer les utilisateurs/groupes.  

---

### **📂 Dossiers de sauvegarde `/mnt/data_disk/DEP/`**  

- 📂 **RH** (`770`) 🔒 *Accès total pour RH, aucun accès aux autres*.  
  - 🚫 **IT et autres utilisateurs** → **Ne peuvent pas lire/écrire dans ce dossier**.  

- 📂 **IT** (`770`) 🔒 *Accès total pour IT, aucun accès aux autres*.  
  - 🚫 **RH et autres utilisateurs** → **Ne peuvent pas lire/écrire dans ce dossier**.  

---

### **🔹 Récapitulatif des Groupes**  

| **Groupe** | **Peut faire ✅**                                                        | **Ne peut pas faire 🚫**                                                                |
| ---------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **RH**     | Gérer utilisateurs/groupes RH, modifier `doas.conf`, configurer quotas. | Supprimer `sudo`/`IT`, modifier `/etc/sudoers`, voir/modifier fichiers IT.              |
| **IT**     | Voir quotas, gérer `new_agents`, accéder aux scripts IT.                | Modifier permissions de RH, gérer utilisateurs/groupes, accéder aux fichiers RH.        |
| **Tous**   | Exécuter certains scripts publics (`755`).                              | Modifier fichiers système critiques (`/etc/sudoers`, `/etc/gts/gts_utilisateurs.bash`). |

---
