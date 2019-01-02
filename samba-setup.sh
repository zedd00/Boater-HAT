#!/bin/bash
# This script is to configure a samba server on a fresh install of Ubuntu Server
# sharepath is the full path that you would like your share to be at. eg /mnt/share
sharepath=""
# The name of the new share
sharename=""
# sharedevice is your array. It can be found with sudo fdisk -l
sharedevice=""
###### End of variables, there shouldn't be a need to edit anything else #############
sudo apt update
# Install Samba, make it available to your user
sudo apt install samba -y
pnid="$(id -nu)"
sudo smbpasswd -a $pnid
sudo bash -c ' echo "'$pnid':\"'$pnid'\"" > smbusers'

# Create the folder for the drive to be mounted into, enable access, format it.
sudo mkdir $sharepath
sudo chmod 0755 $sharepath
sudo mkfs.ext4 $sharedevice
# Make a backup of fstab, add the drive so it's available across reboots, mount it now.
sudo cp /etc/fstab /etc/fstab_old
sudo bash -c ' echo "'$sharedevice'  '$sharepath'  auto   defaults   0  0" >> /etc/fstab'
sudo bash -c ' echo "" >> /etc/fstab'
sudo mount -a
# Backup samba.conf, add the share to it, restart the service.
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
sudo sed -i "/\[global\]/a\[$sharename\]\ncomment = $sharename\npath = $sharepath\nread only = no\nbrowsable = yes\ncreate mask = 0644\ndirectory mask = 0755" smb.conf
sudo service smbd restart
