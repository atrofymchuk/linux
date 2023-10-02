#!/bin/bash
sudo yum install rpcbind nfs-utils -y
sudo systemctl enable nfs-server --now
sudo systemctl enable rpcbind
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=nfs3
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload
sudo mkdir -p /mnt/share_storage/upload
sudo chmod -R 777 /mnt/share_storage/upload
sudo chown -R nfsnobody:nfsnobody /mnt/share_storage
sudo echo "/mnt/share_storage 192.168.50.11(rw,root_squash,no_all_squash)" > /etc/exports
sudo exportfs -r

