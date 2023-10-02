#!/bin/bash
yum -y install git gcc glibc-static yum-utils rpmdevtools zlib-devel openssl-devel pcre-devel createrepo
cd /root
git clone https://github.com/yaoweibin/nginx_upstream_check_module.git
rpm -Uvh http://nginx.org/packages/centos/7/SRPMS/nginx-1.20.1-1.el7.ngx.src.rpm
rm -rf nginx-1.20.1-1.el7.ngx.src.rpm
rpmdev-setuptree
cd /root/rpmbuild/SOURCES
tar xf nginx-1.20.1.tar.gz && rm -rf nginx-1.20.1.tar.gz
cd nginx-1.20.1
patch -p1 < /root/nginx_upstream_check_module/check_1.16.1+.patch
cd ..
tar czf nginx-1.20.1.tar.gz nginx-1.20.1 && rm -rf nginx-1.20.1
cd /root/rpmbuild/SPECS
cp /vagrant/nginx.spec .
rpmbuild -bb nginx.spec
rpm -ivh /root/rpmbuild/RPMS/x86_64/nginx-1.20.1-1.el7.ngx.x86_64.rpm
systemctl enable nginx
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
mkdir -p /var/www/html/repos
rm /etc/nginx/conf.d/default.conf
cp /vagrant/repo.conf /etc/nginx/conf.d/.
cp /root/rpmbuild/RPMS/x86_64/nginx-1.20.1-1.el7.ngx.x86_64.rpm /var/www/html/repos/.
createrepo --update /var/www/html/repos/
systemctl start nginx
exit 0

