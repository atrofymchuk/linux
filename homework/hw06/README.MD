## Домашнее задание: Размещаем свой RPM в своем репозитории
- создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
- создать свой репо и разместить там свой RPM реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо
## Решение:
Домашнее задание реализовано на стенде из двух виртуальных машин repo и client.
- cкрипт [repo.sh](repo.sh) поднимает сервер для локального репозитория, скачивает исходники nginx, применяет к нему патч для модуля nginx_upstream_check_module и собирает пакет, локальный репозиторий доступен по адресу http://192.168.50.10.
- cкрипт [client.sh](client.sh) готовит клиента для установки пакета nginx из локального репозитория http://192.168.50.10.
- файл [nginx.spec](nginx.spec) - подготовленный файл спецификациb для сборки кастомного nginx. Файл отличается от оригинального только строкой "--add-module=/root/nginx_upstream_check_module" (добавляет в сборку пропатченный модуль upstream_check).
- файл [repos.conf](repos.conf) - файл конфигурации для nginx для работы в качестве репозитория (включён автоиндекс на папку /var/www/html/repos)

