##  Домашнее задание: Работа с загрузчиком
- Попасть в систему без пароля несколькими способами.
- Установить систему с LVM, после чего переименовать VG.
- Добавить модуль в initrd.
## Решение:
### 1. Попасть в систему без пароля несколькими способами.
### Способ 1. `init=/bin/sh`

В конце строки начинающейся с linux16 добавляем init=/bin/sh [screenshot 7.1](/hw07/screenshots/7.1.png)
и нажимаем сtrl-x для загрузки в систему.
Мы попали в систему [screenshot 7.2](/hw07/screenshots/7.2.png).  Рутовая файлова система при этом смонтирована в режиме Read-Only [screenshot 7.3](/hw07/screenshots/7.3.png)
Нужно воспользоваться командой: `mount -o remount,rw /`  чтобы рутовая файловая система была перепримонтирована и работала в режиме записи и чтения [screenshot 7.4](/hw07/screenshots/7.4.png). 
Проверяем что перемонирование выполнено записав данные в любой файл и удалив файл: `touch file` `rm file` [screenshot 7.5](/hw07/screenshots/7.5.png) или прочитав вывод команды `mount | grep root`
### Способ 2. `rd.break`
В конце строки начинающейся с linux16 добавляем `rd.break` [screenshot 7.6](/hw07/screenshots/7.6.png) и нажимаем сtrl-x для загрузки в систему.
Попадаем в emergency mode [screenshot 7.7](/hw07/screenshots/7.7.png) .
Наша корневая файловая система смонтирована (опять же в режиме Read-Only, но мы не в ней.
Далее будет пример как попасть в нее и поменять пароль администратора [screenshot 7.8](/hw07/screenshots/7.8.png):
```
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
```
После чего можно перезагружаться и заходить в систему с новым паролем. Полезно когда утерян пароль администратора.
### Способ 3. `rw init=/sysroot/bin/sh`
В строке начинающейся с linux16 заменяем `ro` на `rw init=/sysroot/bin/sh` [screenshot 7.9](/hw07/screenshots/7.9.png) и нажимаем `сtrl-x` для загрузки в систему и мы сразу оказываемся в файловой системе, которая доступна на чтение и запись.
### 2. Установить систему с LVM, после чего переименовать VG.
Посмотрим текущее состояние системы:
>[root@lvm ~]# vgs\
> VG     #PV #LV #SN Attr   VSize  VFree\
> centos   1   2   0 wz--n- <9.00g    0

Нас интересует вторая строка с именем Volume Group. Приступим к переименованию:

>[root@lvm ~]# vgrename centos OtusRoot\
>Volume group "centos" successfully renamed to "OtusRoot"

Далее правим /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg Везде заменяем старое название `centos`  на новое `OtusRoot`.
Пересоздаем initrd image, чтобы он знал новое название Volume Group
```
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
````
>*** Creating image file ***\
>*** Creating image file done ***\
>*** Creating initramfs image file '/boot/initramfs-5.8.5-1.el7.elrepo.x86_64.img' done ***

После чего можем перезагружаться и если все сделано правильно успешно грузимся с
новым именем Volume Group и проверяем:
>[root@lvm ~]# vgs\
>  VG       #PV #LV #SN Attr   VSize  VFree\
>  OtusRoot   1   2   0 wz--n- <9.00g    0

## Добавить модуль в initrd
Скрипты модулей хранятся в каталоге /usr/lib/dracut/modules.d/. Для того чтобы
добавить свой модуль создаем там папку с именем 01test:
```
mkdir /usr/lib/dracut/modules.d/01test
```
В нее поместим два скрипта:
1. [module-setup.sh](/hw07/module-setup.sh) - который устанавливает модуль и вызывает скрипт test.sh
2. [test.sh](/hw07/test.sh) - собственно сам вызываемый скрипт, в нём у нас рисуется пингвинчик
Пересобираем образ initrd

>[root@lvm 01test]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
>.....
>** Creating image file ***\
>*** Creating image file done ***\
>*** Creating initramfs image file '/boot/initramfs-5.8.5-1.el7.elrepo.x86_64.img' done ***

или такой командой
```
dracut -f -v
```
Можно проверить/посмотреть какие модули загружены в образ:
```
lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
test
```
После чего можно пойти двумя путями для проверки:\
Перезагрузиться и руками выключить опции rghb и quiet и увидеть вывод.\
Либо отредактировать grub.cfg убрав эти опции.\
В итоге при загрузке вы увидите пингвина в выводе терминала [screenshot 7.10](/hw07/screenshots/7.10.png).

