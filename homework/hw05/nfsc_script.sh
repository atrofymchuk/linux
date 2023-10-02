#!/bin/bash
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo mkdir /mnt/share_storage
sudo mount -t nfs -o rw,nosuid,noexec,soft,intr,proto=udp,vers=3 192.168.50.10:/mnt/share_storage /mnt/share_storage
echo "192.168.50.10:/mnt/share_storage /mnt/share_storage nfs noauto,x-systemd.automount,proto=udp,vers=3 0 0" >> /etc/fstab

