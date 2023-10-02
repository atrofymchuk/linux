## Домашнее задание: Практические навыки работы с ZFS
- Отрабатываем навыки работы с созданием томов export/import и установкой параметров.
- Определить алгоритм с наилучшим сжатием.
- Определить настройки pool’a Найти сообщение от преподавателей
##  Решение:
Создаем пул zfs_pool:
```
$zpool create zfs_pool mirror sdb sdc
```
Создаем разные файловые системы:
```
$sudo zfs create zfs_pool/test_gzip
$sudo zfs set compression=on zfs_pool/test_gzip
$sudo zfs set compress=gzip zfs_pool/test_gzip
$sudo zfs create zfs_pool/test_gzip-1
$sudo zfs set compression=on zfs_pool/test_gzip-1
$sudo zfs set compress=gzip-1 zfs_pool/test_gzip-1
$sudo zfs create zfs_pool/test_gzip-9
$sudo zfs set compression=on zfs_pool/test_gzip-9
$sudo zfs set compress=gzip-9 zfs_pool/test_gzip-9
$sudo zfs create zfs_pool/test_lz4
$sudo zfs set compression=on zfs_pool/test_lz4
$sudo zfs set compress=lz4 zfs_pool/test_lz4
$sudo zfs create zfs_pool/test_lzjb
$sudo zfs set compression=on zfs_pool/test_lzjb
$sudo zfs set compress=lzjb zfs_pool/test_lzjb
$sudo zfs create zfs_pool/test_zle
$sudo zfs set compression=on zfs_pool/test_zle
$sudo zfs set compress=zle zfs_pool/test_zle
```
скачаваем файл “Война и мир” и располагаем на файловых системах
```
$curl -o "War_and_Peace.txt" -J -L https://www.gutenberg.org/cache/epub/2600/pg2600.txt
$sudo cp War_and_Peace.txt /zfs_pool/test_gzip
$sudo cp War_and_Peace.txt /zfs_pool/test_gzip-1
$sudo cp War_and_Peace.txt /zfs_pool/test_gzip-9
$sudo cp War_and_Peace.txt /zfs_pool/test_lz4
$sudo cp War_and_Peace.txt /zfs_pool/test_lzjb
$sudo cp War_and_Peace.txt /zfs_pool/test_zle
```
Сравниваем выводы команд:
```
$zfs get compression,compressratio
NAME                  PROPERTY       VALUE     SOURCE
zfs_pool              compression    off       default
zfs_pool              compressratio  1.08x     -
zfs_pool/test_gzip    compression    gzip      local
zfs_pool/test_gzip    compressratio  1.08x     -
zfs_pool/test_gzip-1  compression    gzip-1    local
zfs_pool/test_gzip-1  compressratio  1.08x     -
zfs_pool/test_gzip-9  compression    gzip-9    local
zfs_pool/test_gzip-9  compressratio  1.08x     -
zfs_pool/test_lz4     compression    lz4       local
zfs_pool/test_lz4     compressratio  1.08x     -
zfs_pool/test_lzjb    compression    lzjb      local
zfs_pool/test_lzjb    compressratio  1.07x     -
zfs_pool/test_zle     compression    zle       local
zfs_pool/test_zle     compressratio  1.08x     -
```
```
$cd /zfs_pool
$du -s *
1182	test_gzip
1182	test_gzip-1
1182	test_gzip-9
1182	test_lz4
1182	test_lzjb
1182	test_zle
```
Вывод показывает значение 1182 Кб одного и того же файла но на разных файловых системах с разным сжатием.
#### Вывод: Для текстового файла рассмотренные алгоритмы сжатия gzip, gzip-1, gzip-9, lz4, lzjb, zle имеют одинаковую степень сжатия,единственно по параметру compressratio проигрывает файловая система с сжатием lzjb и наименьши значением 1.07x

### 2.Определить настройки pool’a
Собираем пул из скачанного архива
```
$sudo zpool import -d ${PWD}/zpoolexport otus
$zpool list
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus   480M  2,19M   478M        -         -     0%     0%  1.00x    ONLINE  -
$zfs list
NAME             USED  AVAIL     REFER  MOUNTPOINT
otus            2,04M   350M       24K  /otus
otus/hometask2  1,88M   350M     1,88M  /otus/hometask2

```
Определяем настройки размера pool'a, обьем хранилища составляет 480 мегабайт. Этот парметр не меняется.
```
$zpool get size otus
NAME  PROPERTY  VALUE  SOURCE
otus  size      480M   -

```
Определяем тип pool
```
$zfs get type
NAME            PROPERTY  VALUE       SOURCE
otus            type      filesystem  -
otus/hometask2  type      filesystem  -

```
Определяем значение recordsize
```
$zfs get recordsize
NAME            PROPERTY    VALUE    SOURCE
otus            recordsize  128K     local
otus/hometask2  recordsize  128K     inherited from otus
```
Для смены параметра используем команду:
```
$sudo zfs set recordsize=64K otus
$sudo zfs get recordsize
NAME            PROPERTY    VALUE    SOURCE
otus            recordsize  64K      local
otus/hometask2  recordsize  64K      inherited from otus
```
Определяем какое сжатие используется
```
$sudo zfs get compression
NAME            PROPERTY     VALUE     SOURCE
otus            compression  zle       local
otus/hometask2  compression  zle       inherited from otus
```
Определяем какая контрольная сумма используется
```
$zfs get checksum
NAME            PROPERTY  VALUE      SOURCE
otus            checksum  sha256     local
otus/hometask2  checksum  sha256     inherited from otus
```
### 3.Найти сообщение от преподавателей
Восстановливаем с файла файловую систему командой:
```
sudo zfs receive otus/storage@task2 < otus_task2.file 
```
Поиск файла secret_message
```
find /otus -name secret_message
/otus/storage/task1/file_mess/secret_message
```
Результат secret_message 
```
cat /otus/storage/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```
