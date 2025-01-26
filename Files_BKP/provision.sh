#!/bin/bash

# === Update/Upgrade and install services ===
apt-get update -y && apt-get upgrade -y
apt-get install -y linux-image-amd64 linux-headers-amd64 dkms build-essential doas quota htop openssh-server parted curl sudo vim tree e2fsprogs sshfs apache2 dos2unix rsyslog

# === Add folders ===
mkdir -p /etc/gts /etc/new_agents /etc/cron_script

# === Add files/folders ===
touch /etc/new_agents/new_agents.txt
cp -r /scripts /home/vagrant/Files_BKP

# === Convert syntax to UNIX ===
dos2unix /home/vagrant/Files_BKP/*.sh

# === Move files and set permissions ===
cp /home/vagrant/Files_BKP/cron_space_disk.sh /etc/cron_script
chmod 755 /etc/cron_script/*
cp /home/vagrant/Files_BKP/gts* /etc/gts
chmod 755 /etc/gts

# === Add group and set permissions ===
groupadd RH
chgrp RH /etc/gts/gts_utilisateurs.sh
chmod 750 /etc/gts/gts_utilisateurs.sh
chmod 755 /etc/gts/gts_cron.sh

groupadd IT
chgrp -R IT /etc/new_agents
chmod 2750 /etc/new_agents

chgrp IT /etc/gts/gts_surveillance.sh
chmod 750 /etc/gts/gts_surveillance.sh
chgrp IT /etc/gts/gts_journalisation.sh
chmod 750 /etc/gts/gts_journalisation.sh

# === Add permissions on file sudoer ===
echo '%IT ALL=(ALL:ALL) ALL\nagent_RH-1  ALL=(ALL) NOPASSWD: /usr/sbin/setquota' >> /etc/sudoers

# === Add users ===
adduser --gecos "" --disabled-password adminesgi
echo "adminesgi:@zerty2QWERTY" | chpasswd
usermod -aG IT adminesgi

adduser --gecos "" --disabled-password --allow-bad-names agent_RH-1
echo "agent_RH-1:plume_souple-1" | chpasswd
usermod -aG RH agent_RH-1

# === Configure additional rights for agent_RH-1 ===
if [ ! -f /etc/doas.conf ]; then
  touch /etc/doas.conf
fi
chmod 640 /etc/doas.conf
cat <<EOF > /etc/doas.conf
# === Autoriser agent_RH-1 à gérer les utilisateurs et les groupes ===
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

# === Restrictions pour agent_RH-1 ===
deny agent_RH-1 cmd gpasswd args -d sudo
deny agent_RH-1 cmd gpasswd args -d IT
deny agent_RH-1 cmd groupdel args sudo
deny agent_RH-1 cmd groupdel args IT
deny agent_RH-1 cmd chmod args 440 /etc/sudoers.d/root
deny agent_RH-1 cmd chmod args 440 /etc/sudoers.d/vagrant
EOF

# === Enable password authentication for SSH ===
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# === Configure second disk for /mnt/data_disk + automatic mount ===
if [ $(lsblk | grep -c sdb) -eq 1 ]; then
  mkfs.ext4 /dev/sdb
  mkdir -p /mnt/data_disk
  echo '/dev/sdb /mnt/data_disk ext4 defaults,usrquota 0 0' >> /etc/fstab
  mount -a
  quotacheck -cum /mnt/data_disk
  quotaon /mnt/data_disk
  mv /home /mnt/data_disk/home
  ln -s /mnt/data_disk/home /home
fi

# === Backup folders for departments ===
mkdir -p /mnt/data_disk/DEP/{RH,IT}
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
