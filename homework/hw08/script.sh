!# /bin/bash
#Для начала создаём файл watchlog с конфигурацией для сервиса в директории /etc/sysconfig/
touch /etc/sysconfig/watchlog
#Добавляем необходимую переменную
echo 'WORD=ALERT
LOG=/var/log/watchlog.log' >/etc/sysconfig/watchlog
#Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение,плюс ключевое слово ALERT
touch /var/log/watchlog.log
echo '123
test
ALERT
456' > /var/log/watchlog.log
#Создадим скрипт /opt/watchlog.sh
touch /opt/watchlog.sh
echo '#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi' > /opt/watchlog.sh
#Дадим права на выполнение созданому скрипту /opt/watchlog.sh
chmod -R 0700 /opt/watchlog.sh
#Создадим юнит для сервиса /etc/systemd/system/watchlog.service
touch /etc/systemd/system/watchlog.service
echo '[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG' > /etc/systemd/system/watchlog.service
#Создадим юнит для таймера /etc/systemd/system/watchlog.timer:
touch /etc/systemd/system/watchlog.timer
echo 'Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/watchlog.timer
#запускаем watchlog.timer и watchlog.service
systemctl daemon-reload
systemctl start watchlog.timer
systemctl start watchlog.service
# Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл
yum install epel-release -y && yum install install spawn-fcgi php php-cli -y
#Необходимо раскомментировать строки с переменными в /etc/sysconfig/spawn-fcgi
echo 'SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"' > /etc/sysconfig/spawn-fcgi
#Создаем юнит файл следующего вида /etc/systemd/system/spawn-fcgi.service
touch /etc/systemd/system/spawn-fcgi.service
echo '[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/spawn-fcgi.service
#Запускаем spawn-fcgi
systemctl daemon-reload
systemctl start spawn-fcgi
# Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами
#Для запуска нескольких экземпляров сервиса будем использовать шаблон в конфигурации файла окружения:
cp /usr/lib/systemd/system/httpd.service /etc/systemd/system
mv /etc/systemd/system/httpd.service /etc/systemd/system/httpd@.service
echo '[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/httpd@.service
#В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом:
touch /etc/sysconfig/httpd-first
echo 'OPTIONS=-f conf/first.conf' > /etc/sysconfig/httpd-first
touch /etc/sysconfig/httpd-second
echo 'OPTIONS=-f conf/second.conf' > /etc/sysconfig/httpd-second
#В директории с конфигами httpd должны лежать два конфига, в нашем случае это будут first.conf и second.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
#Правим конфиги
echo 'PidFile /var/run/httpd-first.pid
ServerName localhost' >> /etc/httpd/conf/first.conf
echo 'PidFile /var/run/httpd-second.pid
ServerName localhost' >> /etc/httpd/conf/second.conf
sed -i '/Listen 80/c Listen 8080' /etc/httpd/conf/first.conf
sed -i '/Listen 80/c Listen 8081' /etc/httpd/conf/second.conf
setenforce 0
systemctl daemon-reload
systemctl start httpd@first.service
systemctl start httpd@second.service
