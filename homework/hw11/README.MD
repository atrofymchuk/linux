## Домашнее задание: Первые шаги с Ansible

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt;
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными;
- после установки nginx должен быть в режиме enabled в systemd;
- должен быть использован notify для старта nginx после установки;
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible.

## Решение:
Используем команду ```ansible-galaxy init roles/nginx```, она создает структура директорий и файлов для роли nginx
```
├── roles
│   └── nginx
│       ├── defaults
│       │   └── main.yml
│       ├── files
│       ├── handlers
│       │   └── main.yml
│       ├── meta
│       │   └── main.yml
│       ├── README.md
│       ├── tasks
│       │   ├── main.yml
│       │   └── redhat.yml
│       ├── templates
│       │   ├── index.html.j2
│       │   └── nginx.conf.j2
│       ├── tests
│       │   ├── inventory
│       │   └── test.yml
│       └── vars
│           └── main.yml
```
Inventory:
```
├── staging
│   └── hosts
```
Playbook:
```
├── playbook
│   └── web.yml
```
В vagrantfile предусмотрено запуска плейбука ansible командой ```ansible-playbook playbook/web.yml```

Для запуска и проверки нужно:
- склонировать репозиторий: ```git clone https://github.com/andreit2/linux-homework.git```
- перейти в директорию с домашним заданием: ```cd linux-homework/hw11/```
- для запуска выполнить команду ```vagrant up```
- после провижинга проверить командой ```curl http://192.168.100.100:8080```


