#!/bin/bash
cp /vagrant/local.repo /etc/yum.repos.d/local.repo
yum -y install nginx
systemctl start nginx
systemctl status nginx
exit 0
