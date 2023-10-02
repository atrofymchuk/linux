## Домашнее задание: Systemd

Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):
- Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в `/etc/sysconfig`
- Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
- Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.
## Решение:
Для проверки домашнего задания нужно положить в одну директорию Vagranfile и скрипт script.sh
поднять стенд командой `vagrant up`
для проверки подключиться к стенду командой `vagrant ssh`
првоерка 1 части командой на стенде  `tail -f /var/log/messages` вывод буде содержать:
>Jul 20 15:11:04 hw8 systemd: Starting My watchlog service...\
>Jul 20 15:11:05 hw8 root: Tue Jul 20 15:11:05 EEST 2021: I found word, Master!\
>Jul 20 15:11:05 hw8 systemd: Started My watchlog service.
проверка 2 часть  командой `systemctl status spawn-fcgi` вывод должен содержать:
>[vagrant@hw8 ~]$ systemctl status spawn-fcgi
>● spawn-fcgi.service - Spawn-fcgi startup service by Otus
>   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
>   Active: active (running) since Tue 2021-07-20 14:51:38 UTC; 4min 14s ago
> Main PID: 3488 (php-cgi)
>   CGroup: /system.slice/spawn-fcgi.service
>           ├─3488 /usr/bin/php-cgi
>           ├─3499 /usr/bin/php-cgi
>           ├─3500 /usr/bin/php-cgi
 
проверка 3 часть командой `ss -tnulp | grep httpd`
Практика проекта:
1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в `/etc/sysconfig`
Для начала создаём файл с конфигурацией для сервиса в директории `/etc/sysconfig` - из неё сервис будет брать необходимую переменную.
>[andreit@stand ~#] cat /etc/sysconfig/watchlog\
>#Configuration file for my watchdog service\
>#Place it to /etc/sysconfig\
>#File and word in that file that we will be monit\
>WORD="ALERT"\
>LOG=/var/log/watchlog.log

Затем создаем `/var/log/watchlog.log` и пишем туда строки на своё усмотрение,плюс ключевое слово ALERT\
Создадим скрипт:

>[andreit@stand ~#] cat /opt/watchlog.sh\
>#!/bin/bash\
>WORD=$1\
>LOG=$2\
>DATE=`date`\
>if grep $WORD $LOG &> /dev/null\
>then\
>  logger "$DATE: I found word, Master!"\
>else\
>  exit 0\
>fi

Команда logger отправляет лог в системный журнал.\
Создадим юнит для сервиса `/etc/systemd/system/watchlog.service`: 
```
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchdog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

Создадим юнит для таймера `/etc/systemd/system/watchlog.timer`:
```
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
```

Для проверки работы сервиса необходимо запустить сервисы:
```
sudo systemctl start watchlog.service
sudo systemctl start watchlog.timer
```
Проверяем:
```
[root@stand ~]# tail -f /var/log/messages
```
Смотрим в лог-файле, как результат в сообщениях будет запись что в логе найдено проверочное слово ALERT

>Jul 20 15:11:04 stand systemd: Starting My watchlog service...\
>Jul 20 15:11:05 stand root: Tue Jul 20 15:11:05 EEST 2021: I found word, Master!\
>Jul 20 15:11:05 stand systemd: Started My watchlog service.

2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).

>[root@stand ~]# yum install epel-release -y && yum install spawn-fcgi php php-cli

Необходимо раскомментировать строки с переменными в `/etc/sysconfig/spawn-fcgi`
```
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```
А сам юнит файл будет примерно следующего вида /etc/systemd/system/spawn-fcgi.service
```
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
```

Убеждаемся что все успешно работает:
>[root@stand ~#] systemctl start spawn-fcgi
>[root@stand ~#] systemctl status spawn-fcgi
>Jul 20 16:08:10 stand systemd[1]: Started Spawn-fcgi startup service by Otus.

3. Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами.

Для запуска нескольких экземпляров сервиса будем использовать шаблон в конфигурации файла окружения:
```
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I <------добавим параметр %I сюда
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
```
В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом:
```
# /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
# /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```
Соответственно в директории с конфигами httpd должны лежать два конфига, в нашем случае это будут first.conf и second.conf\
Для удачного запуска, в конфигурационных файлах должны быть указаны уникальные для каждого экземпляра опции Listen и PidFile.\
Конфиги можно скопировать и поправить только второй, в нем должны быть следующие опции:
```
PidFile /var/run/httpd-second.pid
Listen 8080
```
Этого достаточно для успешного запуска.\
Запустим:
```
[root@stand ~#] systemctl start httpd@first
[root@stand ~#] systemctl start httpd@second
```
Проверить можно несколькими способами, например посмотреть какие порты слушаются:
>[root@stand ~#] ss -tnulp | grep httpd

