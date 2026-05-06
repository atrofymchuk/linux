/etc/systemd/system/rf-be-dev.service

```
[Unit]
Description=This is backend server
After=network.target
[Service]
\#Environment=PORT=5000
Type=simple
WorkingDirectory=/var/www/refugee/develop/backend
ExecStart=/usr/bin/node /var/www/refugee/develop/backend/dist/src/main.js
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=node-rf-be-dev
User=gitlab-runner
Group=gitlab-runner

[Install]
WantedBy=multi-user.target
```