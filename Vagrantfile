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

    # === Add data disk (50GB) ===
    unless File.exist?("./data_disk.vdi")
      vb.customize ["createhd", "--filename", "./data_disk.vdi", "--variant", "Fixed", "--size", 3 * 1024]
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
      apt-get update -y

      apt-get install -y linux-image-amd64 linux-headers-amd64 dkms build-essential doas quota htop openssh-server parted curl sudo vim tree e2fsprogs sshfs apache2 dos2unix rsyslog



      # === Add folders ===
      mkdir -p /etc/gts
      mkdir -p /etc/new_agents
      mkdir -p /etc/cron_script

      # === Add files/folders ===
      touch /etc/new_agents/new_agents.txt
      cp -r /vagrant/Files_BKP /home/vagrant/Files_BKP

      # === Move files and set permissions ===
      cp /home/vagrant/Files_BKP/cron_space_disk.sh /etc/cron_script
      chmod 755 /etc/cron_script/*
      cp /home/vagrant/Files_BKP/gts* /etc/gts

      # === Add group and set permissions ===
      chmod 755 /etc/gts

      groupadd RH
      chgrp RH /etc/gts/gts_utilisateurs.sh
      chmod 750 /etc/gts/gts_utilisateurs.sh

      # All users
      chmod 755 /etc/gts/gts_cron.sh

      # Group IT
      groupadd IT
      chgrp -R IT /etc/new_agents
      chmod 2750 /etc/new_agents

      chgrp IT /etc/gts/gts_surveillance.sh
      chmod 750 /etc/gts/gts_surveillance.sh

      chgrp IT /etc/gts/gts_journalisation.sh
      chmod 750 /etc/gts/gts_journalisation.sh

      # Add permissions on file sudoer
      echo '# === Autorisations suplémentaires ===
      %IT ALL=(ALL:ALL) ALL
      agent_RH-1  ALL=(ALL) NOPASSWD: /usr/sbin/setquota' | tee -a /etc/sudoers

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
      
      echo '# === Autoriser agent_RH-1 à gérer les utilisateurs et les groupes ===
      permit nopass agent_RH-1 cmd adduser
      permit nopass agent_RH-1 cmd userdel
      permit nopass agent_RH-1 cmd groupadd
      permit nopass agent_RH-1 cmd groupdel
      permit nopass agent_RH-1 cmd groupmod
      permit nopass agent_RH-1 cmd usermod
      permit nopass agent_RH-1 cmd chpasswd

      # === Autoriser agent_RH-1 à gérer les groupes ===
      permit nopass agent_RH-1 cmd gpasswd args -a
      permit nopass agent_RH-1 cmd gpasswd args -d
      permit nopass agent_RH-1 cmd gpasswd args -m

      # === Autoriser agent_RH-1 à insérer du texte ===
      permit nopass agent_RH-1 cmd tee args -a /etc/doas.conf
      permit nopass agent_RH-1 cmd tee args -a /etc/new_agents/new_agents.txt

      # === Autoriser agent_RH-1 à configurer des quotas ===
      # Voir dans visudo
      #permit nopass agent_RH-1 cmd setquota

      # === Restrictions pour agent_RH-1 ===
      deny agent_RH-1 cmd gpasswd args -d sudo
      deny agent_RH-1 cmd gpasswd args -d IT
      deny agent_RH-1 cmd groupdel args sudo
      deny agent_RH-1 cmd groupdel args IT
      deny agent_RH-1 cmd chmod args 440 /etc/sudoers.d/root
      deny agent_RH-1 cmd chmod args 440 /etc/sudoers.d/vagrant

      # === Autoriser root à exécuter des commandes sans mot de passe ===
      permit nopass root' > /etc/doas.conf
      
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
      chmod 770 /mnt/data_disk/DE/IT

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
    - agent_RH_1 - Mot de passe : plume_souple-1
    - vagrant - Mot de passe : vagrant
 
   Connexions SSH :
   - vagrant ssh debian12
   - ssh agent-RH-1@192.168.60.150
   - ssh adminesgi@192.168.60.150
   - vagrant ssh
   - ssh [user]@127.0.0.1 -p 2222
  MESSAGE
end
