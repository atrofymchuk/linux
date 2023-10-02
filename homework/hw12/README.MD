## Домашнее задание: PAM
Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников
дать конкретному пользователю права работать с докером и возможность рестартить докер сервис
## Решение:
Запретим пользователю test_otus, пока без привязки к группе. \
Чтобы у пользователя не было возможности войти в систему не только через SSH, но и локально для этого необходимо откорректировать два файла:\
```vi /etc/pam.d/sshd``` и ```vi /etc/pam.d/login```
```
[vagrant@hw12 ~]$ cat /etc/pam.d/sshd
#%PAM-1.0
auth       required     pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_access.so 
account    required     pam_time.so
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
```
```
[vagrant@hw12 ~]$ cat /etc/pam.d/login
#%PAM-1.0
auth [user_unknown=ignore success=ok ignore=ignore default=bad] pam_securetty.so
auth       substack     system-auth
account    required     pam_time.so
account    required     pam_access.so
auth       include      postlogin
account    required     pam_nologin.so
account    include      system-auth
password   include      system-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    optional     pam_console.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      system-auth
session    include      postlogin
-session   optional     pam_ck_connector.so
```
Заходим в файл ```/etc/security/time.conf``` и добавляем в конце файла строку, запретив вход по выходным ```*;*;test_otus;Wk``` Добавляем пользователя командой ```useradd test_otus``` и задаем ему пароль, ```passwd test_otus``` Заходим сегодня, в понедельник, когда у нас работает правило.
```
[vagrant@hw12 ~]$ ssh test_otus@localhost
test_otus@localhost's password:
[test_user@hw12 ~]$
```

## Создадим ограничения на группу admin
Создаем группу ```groupadd admin```
Добавим нашего пользователя ```test_otus``` в ранее созданную группу ```usermod -aG admin test_otus```
Установим модуль ```pam_script```
```
[root@hw12 vagrant]# cat /etc/pam.d/sshd
#%PAM-1.0
auth       required     pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_access.so
auth       required     pam_script.so # Добавил эту строку
account    required     pam_time.so
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
```
Правим файл ```/etc/pam_script``` 

```
#!/bin/bash
if [[ `grep $PAM_USER /etc/group | grep 'admin'` ]]
then
exit 0
fi
if [[ `date +%u` > 5 ]]
then
exit 1
fi
```

И указываю права на исполнение ```chmod +x /etc/pam_script```
В этом файле мы проверяем состоит ли пользователь в группе admin и если да то пускаем его (значит его можно пускать всегда). Если он не состоит в этой группе то срабатывает проверка на то, какой сейчас день недели, если он больше 5, т.е. выходные то не пускаем. Задача выполнена.
