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
      vb.customize ["createhd", "--filename", "./data_disk.vdi", "--variant", "Fixed", "--size", 51200]
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

      apt-get install -y linux-image-amd64 linux-headers-amd64 dkms build-essential htop openssh-server parted curl sudo vim tree e2fsprogs sshfs

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
      chgrp RH /etc/gts/gts_cron.sh
      chmod 750 /etc/gts/gts_cron.sh

      groupadd IT
      chgrp -R IT /etc/new_agents
      chmod 2750 /etc/new_agents
      chmod 740 /etc/new_agents/new_agents.txt
      chgrp IT /etc/gts/gts_surveillance.sh
      chmod 750 /etc/gts/gts_surveillance.sh
      usermod -aG IT vagrant

      echo '%IT ALL=(ALL:ALL) ALL' | sudo tee -a /etc/sudoers

      # === Add users ===
      adduser --gecos "" --disabled-password adminesgi
      echo "adminesgi:@zerty2QWERTY" | chpasswd
      usermod -aG IT adminesgi

      adduser --gecos "" --disabled-password --allow-bad-names agent_RH_1
      echo "agent_RH_1:plume_souple-1" | chpasswd
      usermod -aG RH agent_RH_1

      # === Enable password authentication for SSH ===
      sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

      # === Configure second disk for /mnt/data_disk + montage automatique ===
      if [ $(lsblk | grep -c sdb) -eq 1 ]; then
        mkfs.ext4 /dev/sdb
        mkdir -p /mnt/data_disk
        echo '/dev/sdb /mnt/data_disk ext4 defaults 0 0' >> /etc/fstab
        mount -a
      fi

      # === Configure GRUB ===
      sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/' /etc/default/grub
      sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="quiet splash"/' /etc/default/grub
      update-grub

      # === Set default systemd target to multi-user ===
      systemctl set-default multi-user.target

      systemctl restart ssh
      systemctl enable ssh
      #/lib/systemd/systemd-sysv-install enable ssh

      # Recharger
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
   - ssh agent-RH-1@192.168.60.200
   - ssh adminesgi@192.168.60.200
   - ssh [user]@127.0.0.1 -p 2222
  MESSAGE
end
