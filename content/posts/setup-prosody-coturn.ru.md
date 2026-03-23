---
title: 'Setup XMPP-server Prosody with Coturn'
date: '2026-02-24T14:54:54+01:00'
draft: true
tags:
  - linux
  - xmpp
---

Info

<!--more-->

## Требования

1. Доменное имя.

   В примере используется `chat.example.com`.

2. Сервер с Linux.

   Для работы prosody+coturn достаточно 1 ядра и 128 MB RAM.

## Установка и настройка

Для примера установки используется сервер с CentOS Stream 10. Для других
дистрибутивов ход установки аналогичен (с поправкой на другие пакетные
менеджеры).

### Prosody

dnf install prosody

/etc/prosody/prosody.cfg.lua

```lua
modules_enabled = {
  -- Generally required
  "disco"; -- Service discovery
  "roster"; -- Allow users to have a roster. Recommended ;)
  "saslauth"; -- Authentication for clients and servers. Recommended if you want to log in.
  "tls"; -- Add support for secure TLS on c2s/s2s connections

  -- Not essential, but recommended
  "carbons"; -- Keep multiple online clients in sync
  "limits"; -- Enable bandwidth limiting for XMPP connections
  "pep"; -- Allow users to store public and private data in their account
  "smacks"; -- Stream management and resumption (XEP-0198)

  -- Nice to have
  "account_activity"; -- Record time when an account was last used
  "cloud_notify"; -- Push notifications for mobile devices
  "csi_simple"; -- Simple but effective traffic optimizations for mobile devices
  "ping"; -- Replies to XMPP pings with pongs
  "time"; -- Let others know the time here on this server
  "uptime"; -- Report how long server has been running
  "version"; -- Replies to server version requests
  "mam"; -- Store recent messages to allow multi-device synchronization

  "turn_external"; -- Provide external STUN/TURN service for e.g. audio/video calls

  -- Admin interfaces
  "admin_shell"; -- Allow secure administration via 'prosodyctl shell'
}

modules_disabled = {
  "s2s";
}

-- Rate limits
-- Enable rate limits for incoming client and server connections. These help
-- protect from excessive resource consumption and denial-of-service attacks.

limits = {
        c2s = {
                rate = "10kb/s";
        };
        s2sin = {
                rate = "30kb/s";
        };
}

authentication = "internal_hashed"

turn_external_host = "chat.example.com"
turn_external_secret = "SECRET"

log = {
  info = "/var/log/prosody/prosody.log"; -- Change 'info' to 'debug' for verbose logging
  error = "/var/log/prosody/prosody.err"; -- Log errors also to file
  error = "*syslog"; -- Log errors also to syslog
}

-- Location of directory to find certificates in (relative to main config file):
certificates = "/etc/pki/prosody/"

-- POSIX configuration
-- For more info see https://prosody.im/doc/configure#posix-only_options
pidfile = "/run/prosody/prosody.pid";

VirtualHost "chat.example.com"

Component "upload.chat.example.com" "http_file_share"
    modules_enabled = { "http_file_share" }
    http_file_share_expires_after = "30 days"

Component "conference.chat.example.com" "muc"
    modules_enabled = { "muc_mam" }
```

systemctl enable --now prosody

/var/log/prosody/prosody.log

systemctl status prosody

### Prosody: shared groups

```lua
modules_enabled = {
    -- Other modules
    "groups"; -- Enable mod_groups
} 

groups_file = "/etc/prosody/sharedgroups.txt"
 ```

/etc/prosody/sharedgroups.txt:

```
[Support Team]
support@example.com
john.doe@example.com
```

### Coturn

dnf install coturn

/etc/coturn/turnserver.conf

realm=chat.example.com
use-auth-secret
static-auth-secret=SECRET

systemctl enable --now coturn

systemctl status coturn
/var/log/coturn/turnserver.log

### DNS

chat A
conference.chat
upload.chat

### Firewall

```sh
# dnf install firewalld
# systemctl enable --now firewalld
```

```sh
# firewall-cmd --permanent --add-service=xmpp-client # 5222/tcp
# firewall-cmd --permanent --add-service=stun        # 3478/tcp 3478/udp
# firewall-cmd --permanent --add-port=5281/tcp
```

### Certs

dnf install certbot

certbot certonly --standalone -d chat.example.com -d upload.chat.example.com -d conference.chat.example.com

prosodyctl --root cert import /etc/letsencrypt/

/etc/letsencrypt/renewal-hooks/deploy/prosody.sh

```sh
#!/bin/sh
/usr/bin/prosodyctl --root cert import /etc/letsencrypt/live
```

chmod +x /etc/letsencrypt/renewal-hooks/deploy/prosody.sh

systemctl enable --now certbot-renew.timer

## Manage

prosodyctl adduser someone@chat.example.com
