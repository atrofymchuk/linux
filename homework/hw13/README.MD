## Домашнее задание: Практика с SELinux
# 1. Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux. 

# 2. Обеспечить работоспособность приложения при включенном selinux.
- развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;
- выяснить причину неработоспособности механизма обновления зоны (см. README);
- предложить решение (или решения) для данной проблемы;
- выбрать одно из решений для реализации, предварительно обосновав выбор;
- реализовать выбранное решение и продемонстрировать его работоспособность. 

## Решение:
Подготовим виртуалку и установим необходимые пакеты: ```nginx, net-tools, setools-console, policycoreutils-python```

```
[vagrant@hw13 ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2021-10-19 16:41:12 UTC; 2min 47s ago
  Process: 13308 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 13306 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 13305 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 13310 (nginx)
```
Проверяем на каком порту запущен nginx
```
[vagrant@hw13 ~]$ sudo netstat -tulpn | grep nginx
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      13310/nginx: master
tcp6       0      0 :::80                   :::*                    LISTEN      13310/nginx: master
```
1.1 С помощью setsebool
правим конфиг nginx, сменив порт на нестандартный
```
server {
        listen       7777;
        #listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;
```

Сервис nginx не стартует, смотрим логи
```
type=AVC msg=audit(1634714891.519:484): avc:  denied  { name_bind } for  pid=2051 comm="nginx" src=7777 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1634714891.519:484): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55a14d21c738 a2=10 a3=7ffed84a1d30 items=0 ppid=1 pid=2051 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
```
Вариант решения проблемы команда:
```setsebool -P nis_enabled 1```
Стартуем nginx
```
[vagrant@hw13 ~]$ sudo systemctl start nginx
[vagrant@hw13 ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-20 09:46:42 UTC; 3s ago
  Process: 2305 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2303 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 2302 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2307 (nginx)
   CGroup: /system.slice/nginx.service
           ├─2307 nginx: master process /usr/sbin/nginx
           └─2308 nginx: worker process
```
Проверяем на каком порту:
```
[vagrant@hw13 ~]$ sudo netstat -tulpn | grep nginx
tcp        0      0 0.0.0.0:7777            0.0.0.0:*               LISTEN      2307/nginx: master
```

С вывода видно что nginx работает на нестандартном 7777 порту.

1.2 добавление нестандартного порта в имеющийся тип

Вернем ```setsebool -P nis_enabled 1 обратно в 0 ```:
```
[vagrant@hw13 ~]$ sudo setsebool -P nis_enabled 0
```
Мы опять все поломали
```
[vagrant@hw13 ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Wed 2021-10-20 10:28:00 UTC; 14s ago
  Process: 2305 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2699 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 2698 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2307 (code=exited, status=0/SUCCESS)

Oct 20 10:28:00 hw13 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Oct 20 10:28:00 hw13 nginx[2699]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Oct 20 10:28:00 hw13 systemd[1]: nginx.service: control process exited, code=exited status=1
Oct 20 10:28:00 hw13 nginx[2699]: nginx: [emerg] bind() to 0.0.0.0:7777 failed (13: Permission denied)
Oct 20 10:28:00 hw13 nginx[2699]: nginx: configuration file /etc/nginx/nginx.conf test failed
Oct 20 10:28:00 hw13 systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Oct 20 10:28:00 hw13 systemd[1]: Unit nginx.service entered failed state.
Oct 20 10:28:00 hw13 systemd[1]: nginx.service failed.
```
Выясним на каком порту можно держать nginx

```
[vagrant@hw13 ~]$ sudo semanage port -l | grep http_port
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```

Порта 7777 нету в данном списке, значит надо добавить:

```
[vagrant@hw13 ~]$ sudo semanage port -a -t http_port_t -p tcp 7777
```
Запускаем, проверяем, работает.

```
[vagrant@hw13 ~]$ sudo systemctl start nginx
[vagrant@hw13 ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-20 10:33:25 UTC; 6s ago
  Process: 2729 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2727 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 2726 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2731 (nginx)
   CGroup: /system.slice/nginx.service
           ├─2731 nginx: master process /usr/sbin/nginx
           └─2733 nginx: worker process

Oct 20 10:33:25 hw13 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Oct 20 10:33:25 hw13 nginx[2727]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Oct 20 10:33:25 hw13 nginx[2727]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Oct 20 10:33:25 hw13 systemd[1]: Started The nginx HTTP and reverse proxy server.
```

1.3 формирование и установка модуля SELinux

Вернем шаг 1.2 в исходное состояние:
```
[vagrant@hw13 ~]$ sudo semanage port -d -t http_port_t -p tcp 7777
```
Посмотрим, какой модуль надо доустановить.

```
[vagrant@hw13 ~]$ ls -Z /usr/sbin/nginx
-rwxr-xr-x. root root system_u:object_r:httpd_exec_t:s0 /usr/sbin/nginx
```
```
[root@hw13 vagrant]# audit2allow -M httpd_add --debug < /var/log/audit/audit.log
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i httpd_add.pp
```
Выполняем команду согласно рекомендации и проверяем:
```
[root@hw13 vagrant]# semodule -i httpd_add.pp
[root@hw13 vagrant]# systemctl start nginx
[root@hw13 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-20 10:33:25 UTC; 28min ago
  Process: 2729 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2727 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 2726 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2731 (nginx)
   CGroup: /system.slice/nginx.service
           ├─2731 nginx: master process /usr/sbin/nginx
           └─2733 nginx: worker process

Oct 20 10:33:25 hw13 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Oct 20 10:33:25 hw13 nginx[2727]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Oct 20 10:33:25 hw13 nginx[2727]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Oct 20 10:33:25 hw13 systemd[1]: Started The nginx HTTP and reverse proxy server.
```
из вывода видно что nginx работает, проверяем на каком порту:

```
[root@hw13 vagrant]# netstat -tulpn | grep nginx
tcp        0      0 0.0.0.0:7777            0.0.0.0:*               LISTEN      2731/nginx: master
```
2. Обеспечить работоспособность приложения при включенном selinux.
Развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
Выяснить причину неработоспособности механизма обновления зоны (см. README);
Предложить решение (или решения) для данной проблемы;
Выбрать одно из решений для реализации, предварительно обосновав выбор;
Реализовать выбранное решение и продемонстрировать его работоспособность.

Запустим стенд.
```
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key
> test
incorrect section name: test
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
```
Со стороны клиента нечего делать.
Смотрим на сервере, передаем логи утилите audit2why
```
[root@ns01 vagrant]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1634729103.177:1891): avc:  denied  { create } for  pid=5082 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```
Доступ заблокирован, в соответствии с отсутствием правила Type Enforcement. Также посмотрим вывод утилиты sealert:

```
[root@ns01 vagrant]# sealert -a /var/log/audit/audit.log
100% done
found 1 alerts in /var/log/audit/audit.log
--------------------------------------------------------------------------------

SELinux is preventing /usr/sbin/named from create access on the file named.ddns.lab.view1.jnl.

*****  Plugin catchall_labels (83.8 confidence) suggests   *******************

If you want to allow named to have create access on the named.ddns.lab.view1.jnl file
Then you need to change the label on named.ddns.lab.view1.jnl
Do
# semanage fcontext -a -t FILE_TYPE 'named.ddns.lab.view1.jnl'
where FILE_TYPE is one of the following: dnssec_trigger_var_run_t, ipa_var_lib_t, krb5_host_rcache_t, krb5_keytab_t, named_cache_t, named_log_t, named_tmp_t, named_var_run_t, named_zone_t.
Then execute:
restorecon -v 'named.ddns.lab.view1.jnl'


*****  Plugin catchall (17.1 confidence) suggests   **************************

If you believe that named should be allowed create access on the named.ddns.lab.view1.jnl file by default.
Then you should report this as a bug.
You can generate a local policy module to allow this access.
Do
allow this access for now by executing:
# ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000
# semodule -i my-iscworker0000.pp


Additional Information:
Source Context                system_u:system_r:named_t:s0
Target Context                system_u:object_r:etc_t:s0
Target Objects                named.ddns.lab.view1.jnl [ file ]
Source                        isc-worker0000
Source Path                   /usr/sbin/named
Port                          <Unknown>
Host                          <Unknown>
Source RPM Packages           bind-9.11.4-26.P2.el7_9.7.x86_64
Target RPM Packages
Policy RPM                    selinux-policy-3.13.1-266.el7.noarch
Selinux Enabled               True
Policy Type                   targeted
Enforcing Mode                Enforcing
Host Name                     ns01
Platform                      Linux ns01 3.10.0-1127.el7.x86_64 #1 SMP Tue Mar
                              31 23:36:51 UTC 2020 x86_64 x86_64
Alert Count                   1
First Seen                    2021-10-20 11:25:03 UTC
Last Seen                     2021-10-20 11:25:03 UTC
Local ID                      2ec0c6a8-986a-4f90-80a7-160ca8924f74

Raw Audit Messages
type=AVC msg=audit(1634729103.177:1891): avc:  denied  { create } for  pid=5082 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0


type=SYSCALL msg=audit(1634729103.177:1891): arch=x86_64 syscall=open success=no exit=EACCES a0=7f2f64763050 a1=241 a2=1b6 a3=24 items=0 ppid=1 pid=5082 auid=4294967295 uid=25 gid=25 euid=25 suid=25 fsuid=25 egid=25 sgid=25 fsgid=25 tty=(none) ses=4294967295 comm=isc-worker0000 exe=/usr/sbin/named subj=system_u:system_r:named_t:s0 key=(null)

Hash: isc-worker0000,named_t,etc_t,file,create
```
SElinux запрещает доступ /usr/sbin/named на создание файла named.ddns.lab.view1.jnl. и предлагает два решения проблемы. Воспользуемся вторым способом.
Из файла /etc/named.conf получим распололжение файла зоны ddns.lab
```
[root@ns01 vagrant]# cat /etc/named.conf
options {
    // network
        listen-on port 53 { 192.168.50.10; };
        // listen-on-v6 port 53 { ::1; };

    // data
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";

    // server
        recursion yes;
        allow-query     { any; };
    allow-transfer { any; };

    // dnssec
        dnssec-enable yes;
        dnssec-validation yes;

    // others
        bindkeys-file "/etc/named.iscdlv.key";
        managed-keys-directory "/var/named/dynamic";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// RNDC Control for client
key "rndc-key" {
    algorithm hmac-md5;
    secret "GrtiE9kz16GK+OKKU/qJvQ==";
};

controls {
        inet 192.168.50.10 allow { 192.168.50.15; } keys { "rndc-key"; };
};

acl "view1" {
    192.168.50.15/32; // client
};

// ZONE TRANSFER WITH TSIG
include "/etc/named.zonetransfer.key";

view "view1" {
    match-clients { "view1"; };

    // root zone
    zone "." IN {
        type hint;
        file "named.ca";
    };

    // zones like localhost
    include "/etc/named.rfc1912.zones";
    // root DNSKEY
    include "/etc/named.root.key";

    // labs dns zone
    zone "dns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab.view1";
    };

    // labs ddns zone
    zone "ddns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        allow-update { key "zonetransfer.key"; };
        file "/etc/named/dynamic/named.ddns.lab.view1";
    };

    // labs newdns zone
    zone "newdns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.newdns.lab";
    };

    // labs zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.50.168.192.rev";
    };
};

view "default" {
    match-clients { any; };

    // root zone
    zone "." IN {
        type hint;
        file "named.ca";
    };

    // zones like localhost
    include "/etc/named.rfc1912.zones";
    // root DNSKEY
    include "/etc/named.root.key";

    // labs dns zone
    zone "dns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab";
    };

    // labs ddns zone
    zone "ddns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        allow-update { key "zonetransfer.key"; };
        file "/etc/named/dynamic/named.ddns.lab";
    };

    // labs newdns zone
    zone "newdns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.newdns.lab";
    };

    // labs zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.50.168.192.rev";
    };
};
```

Как видно файл расположен "/etc/named/dynamic/named.ddns.lab.view1" Расcмотрим его в контектсте безопасности.

```
[root@ns01 vagrant]# ll -Z /etc/named/dynamic/named.ddns.lab.view1
-rw-rw----. named named system_u:object_r:etc_t:s0       /etc/named/dynamic/named.ddns.lab.view1
```
Тип etc_t, необходимо поменять на named_cache_t согласно документации RedHat
```
[root@ns01 vagrant]# semanage fcontext -a -t named_cache_t '/etc/named/dynamic(/.*)?'
[root@ns01 vagrant]# restorecon -R -v /etc/named/dynamic/
restorecon reset /etc/named/dynamic context unconfined_u:object_r:etc_t:s0->unconfined_u:object_r:named_cache_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:etc_t:s0->system_u:object_r:named_cache_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:etc_t:s0->system_u:object_r:named_cache_t:s0
```
Переключаемся на клиента и проверям, снова сменив зону
```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
>
> quit
```
