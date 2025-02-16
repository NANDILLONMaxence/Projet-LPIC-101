# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-12"

  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.memory = "2048"
    vb.cpus = 2

    # === Add data disk 10GB) ===
    unless File.exist?("./data_disk.vdi")
      vb.customize ["createhd", "--filename", "./data_disk.vdi", "--variant", "Fixed", "--size", 10 * 1024]
    end
    vb.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", 1, "--device", 0, "--type", "hdd", "--medium", "./data_disk.vdi"]
  end

  # === Machine debian12 ===
  config.vm.define "debian12" do |debian12|
    debian12.vm.hostname = "Debian12"
    debian12.vm.network "private_network", ip: "192.168.60.150"

    # === Config vm ===
    debian12.vm.provision "shell", inline: <<-SHELL
      # === Update/Upgrade and install services ===
      apt-get update -y && apt-get upgrade -y

      # === Install packages ===
      ## === Install MySQL 8.0 ===
      wget https://dev.mysql.com/get/mysql-apt-config_0.8.32-1_all.deb
      debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-server select mysql-8.0"
      debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-product select Ok"
      debconf-set-selections <<< "mysql-apt-config mysql-apt-config/tools-component select Enabled"
      DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.32-1_all.deb
      apt-get install -f -y
      apt-get update -y
      ROOT_PASSWORD="root"
      debconf-set-selections <<< "mysql-server mysql-server/root_password password $ROOT_PASSWORD"
      debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $ROOT_PASSWORD"
      DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
      
      ## === Tools ===
      PACKAGES="linux-image-amd64 linux-headers-amd64 dkms build-essential \
      doas quota htop openssh-server parted curl sudo vim tree e2fsprogs \
      sshfs apache2 dos2unix rsyslog"

      apt-get install -y $PACKAGES
      apt-get update -y

      # === Add folders ===
      mkdir -p /etc/gts
      mkdir -p /etc/new_agents
      mkdir -p /etc/cron_script

      # === Add files/folders ===
      touch /etc/new_agents/new_agents.txt
      cp -r /vagrant/Files_BKP /home/vagrant/Files_BKP

      # === Convert syntaxe on UNIX ===
      dos2unix /home/vagrant/Files_BKP/*.bash

      # === Move files and set permissions ===
      cp /home/vagrant/Files_BKP/cron_space_disk.bash /etc/cron_script
      chmod 755 /etc/cron_script/*
      cp /home/vagrant/Files_BKP/gts* /etc/gts

      # === Add group and set permissions ===
      chmod 755 /etc/gts

      # Menu GTS principal
      chomd 755 /etc/gts/gts_main.bash

      # Group RH
      groupadd RH
      chgrp RH /etc/gts/gts_utilisateurs.bash
      chmod 750 /etc/gts/gts_utilisateurs.bash

      # All users
      chmod 755 /etc/gts/gts_cron.bash

      # Group IT
      groupadd IT
      chgrp -R IT /etc/new_agents
      chmod 2750 /etc/new_agents

      chgrp IT /etc/gts/gts_surveillance.bash
      chmod 750 /etc/gts/gts_surveillance.bash

      chgrp IT /etc/gts/gts_journalisation.bash
      chmod 750 /etc/gts/gts_journalisation.bash

      # Add permissions on file sudoer
      echo '# === Autorisations suplémentaires ===
      %IT  ALL=(ALL:ALL) ALL
      %RH  ALL=(ALL) NOPASSWD: /usr/sbin/setquota' | tee -a /etc/sudoers

      # Création d'un lien symbolique pour rendre gts_main.bash accessible depuis n'importe quel répertoire
      sudo ln -s /etc/gts/gts_main.bash /usr/local/bin/gts_main
      
      # add perm sudo permission journa
      # === Add users ===
      adduser --gecos "" --disabled-password adminesgi
      echo "adminesgi:@zerty2QWERTY" | chpasswd
      usermod -aG IT adminesgi

      adduser --gecos "" --disabled-password --allow-bad-names agent_RH-1
      echo "agent_RH-1:plume_souple-1" | chpasswd
      usermod -aG RH agent_RH-1 

      # === Configuration des droits suplémentaires pour l'agent RH 1
      # Créer le fichier doas.conf s'il n'existe pas
      if [ ! -f /etc/doas.conf ]; then
        touch /etc/doas.conf
      fi
      chmod 640 /etc/doas.conf
      
      echo '# === Autoriser Groupe RH à gérer les utilisateurs et les groupes ===
      permit nopass :RH cmd adduser
      permit nopass :RH cmd userdel
      permit nopass :RH cmd groupadd
      permit nopass :RH cmd groupdel
      permit nopass :RH cmd groupmod
      permit nopass :RH cmd usermod
      permit nopass :RH cmd chpasswd

      # === Autoriser Groupe RH à gérer les groupes ===
      permit nopass :RH cmd gpasswd args -a
      permit nopass :RH cmd gpasswd args -d
      permit nopass :RH cmd gpasswd args -m

      # === Autoriser Groupe RH à insérer du texte ===
      permit nopass :RH cmd tee args -a /etc/doas.conf
      permit nopass :RH cmd tee args -a /etc/new_agents/new_agents.txt

      # === Autoriser Groupe RH à configurer des quotas ===
      # Voir dans visudo
      #permit nopass :RH cmd setquota

      # === Restrictions pour Groupe RH ===
      deny :RH cmd gpasswd args -d sudo
      deny :RH cmd gpasswd args -d IT
      deny :RH cmd groupdel args sudo
      deny :RH cmd groupdel args IT
      deny :RH cmd chmod args 440 /etc/sudoers.d/root
      deny :RH cmd chmod args 440 /etc/sudoers.d/vagrant

      # === Autoriser Groupe IT à afficher les quotas === 
      permit nopass :IT cmd repquota

      # === Autoriser root à exécuter des commandes sans mot de passe ===
      #permit nopass root' > /etc/doas.conf
      
      # === Enable password authentication for SSH ===
      sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

      # === Configure second disk for /mnt/data_disk + montage automatique ===
      if [ $(lsblk | grep -c sdb) -eq 1 ]; then
        mkfs.ext4 /dev/sdb
        mkdir -p /mnt/data_disk
        echo '/dev/sdb /mnt/data_disk ext4 defaults,usrquota 0 0' >> /etc/fstab
        mount -a

        # === Initialiser les fichiers de quotas ===
        quotacheck -cum /mnt/data_disk
        quotaon /mnt/data_disk

         # === Déplacer le répertoire /home sur le nouveau disque ===
        mv /home /mnt/data_disk/home
        ln -s /mnt/data_disk/home /home
        echo "Répertoire /home déplacé vers /mnt/data_disk/home."
        systemctl start sshd
        echo "Quotas activés pour /mnt/data_disk."
      fi

      # === Dossiers de sauvegarde par départements ===
      mkdir -p  /mnt/data_disk/DEP/RH
      chgrp RH /mnt/data_disk/DEP/RH
      chmod 770 /mnt/data_disk/DEP/RH
      mkdir -p /mnt/data_disk/DEP/IT
      chgrp IT /mnt/data_disk/DEP/IT
      chmod 770 /mnt/data_disk/DEP/IT

      # === Configure GRUB ===
      sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/' /etc/default/grub
      sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="quiet splash"/' /etc/default/grub
      update-grub

      # === Set default systemd target to multi-user ===
      systemctl set-default multi-user.target

      systemctl restart ssh
      systemctl enable ssh
      #/lib/systemd/systemd-sysv-install enable ssh

      # === Relance de la VM ===
      reboot
      SHELL
  end

  config.vm.post_up_message = <<-MESSAGE
    Machine Debian12 prête !

    Utilisateurs :
    - adminesgi - Mot de passe : @zerty2QWERTY
    - agent_RH-1 - Mot de passe : plume_souple-1
    - vagrant - Mot de passe : vagrant
 
   Connexions SSH :
   - vagrant ssh debian12
   - ssh agent-RH-1@192.168.60.150
   - ssh adminesgi@192.168.60.150
   - vagrant ssh
   - ssh [user]@127.0.0.1 -p 2222
  MESSAGE
end
