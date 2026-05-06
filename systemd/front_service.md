/etc/systemd/system/rf-fe-dev.service

```
[Unit]
Description=This service runs front for production
After=syslog.target.network.target
[Service]
Type=simple
User=gitlab-runner
WorkingDirectory=/var/www/refugee/develop/frontend/
ExecStart=npm start -- --port 3030
Restart=on-failure

[Install]
WantedBy=multi-user.target
```