---
title: 'Установка и настройка сервера Jitsi Meet в Docker'
date: '2026-02-17T12:31:02+01:00'
draft: false
tags:
  - linux
  - jitsi
  - docker
---

[Jitsi Meet](https://jitsi.org/) -- это open source платформа для
видео-звонков. Её легко развернуть на сервере (есть официальная Docker Compose
конфигурация); работает в браузере, на
[десктопе](https://flathub.org/en-GB/apps/org.jitsi.jitsi-meet), на
[Android](https://f-droid.org/en/packages/org.jitsi.meet/) и на
[iPhone](https://apps.apple.com/us/app/jitsi-meet/id1165103905); относительно
нетребовательна к ресурсам.

<!--more-->

## Требования

1. Доменное имя.

   В примере используется `example.com`.

2. Сервер с Linux.

   В моих тестах для небольших конференций (до 5 человек с включённым видео)
   было достаточно 1x3.3 ГГц CPU и 2 ГБ RAM (минимальная конфигурация у моего
   хостинга). Подробней о требованиях: [Self-Hosting Deployment
   Requirements](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-requirements/)

## Установка и настройка

Для примера установки используется сервер с CentOS Stream 10. Для других
дистрибутивов ход установки аналогичен (с поправкой на другие пакетные
менеджеры).

### Установка Docker

Сначала необходимо установить Docker (официальное руководство по установке:
[Install Docker Engine on
CentOS](https://docs.docker.com/engine/install/centos/)).

Добавляем репозиторий Docker CE и устанавливаем Docker:

```
# dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

```
# dnf install docker-ce
```

Запускаем демон Docker:

```
# systemctl enable --now docker
```

### Установка Jitsi Meet

Далее нужно установить и запустить сервер Jitsi Meet (официальное руководство
по установке: [Jitsi Self-Hosting
Guide](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker/)).

Установка будет в директорию `/opt`: `/opt/jitsi-docker-jitsi-meet-$ID` для
файлов Docker Compose и `/opt/jitsi-config` для рабочих файлов и настроек
компонентов Jitsi Meet. Место установки можно поменять на любое другое.

Скачиваем дистрибутив с Docker Compose файлами:

```
# cd /opt
# wget $(wget -q -O - https://api.github.com/repos/jitsi/docker-jitsi-meet/releases/latest | grep zip | cut -d\" -f4) -O jitsi-docker.zip
```

Извлекаем из него необходимые файлы:

```
unzip jitsi-docker.zip *docker-compose.yml *gen-passwords.sh
```

Переходим в рабочую директорию:

```
cd jitsi-docker-jitsi-meet-*
```

Создаём в ней `.env` файл с настройками (доменное имя и email для Let's Encrypt
необходимо заменить на свои):

```sh
# General

CONFIG=/opt/jitsi-config
HTTP_PORT=80
HTTPS_PORT=443
TZ=UTC
PUBLIC_URL=https://meet.example.com

# Let's Encrypt configuration

ENABLE_LETSENCRYPT=1
LETSENCRYPT_DOMAIN=meet.example.com
LETSENCRYPT_EMAIL=meet@example.com
LETSENCRYPT_ACME_SERVER="letsencrypt"

# Authentication configuration

ENABLE_AUTH=1
ENABLE_GUESTS=1
AUTH_TYPE=internal

# Security

JICOFO_AUTH_PASSWORD=test
JVB_AUTH_PASSWORD=test
JIGASI_XMPP_PASSWORD=test
JIGASI_TRANSCRIBER_PASSWORD=test
JIBRI_RECORDER_PASSWORD=test
JIBRI_XMPP_PASSWORD=test

# Docker Compose options

RESTART_POLICY=unless-stopped

# Other options

ENABLE_WELCOME_PAGE=0
```

Далее необходимо обновить файл `.env` случайными паролями для взаимодействия
компонентов Jitsi Meet между собой с помощью скрипта:

```
# ./gen-passwords.sh
```

Создаём директории для компонентов Jitsi Meet:

```
# mkdir -p /opt/jitsi-config/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
```

И запускаем сервер:

```
# docker compose up -d
```

Первый запуск может занять некоторое время (минуту-две), так как будут
создаваться сертификаты Let's Encrypt (статус можно увидеть в логах).

Логи сервера можно проверить командой:

```
# docker compose logs web
```

### Создание пользователей

Пользователи хранятся на сервере Prosody. Подробней о работе с пользователями:
[Jitsi Meet
authentification](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker/#internal-authentication).

Для создания пользователя необходимо зайти в контейнер `prosody`:

```
# docker compose exec prosody /bin/bash
```

И создать пользователя:

```
# prosodyctl --config /config/prosody.cfg.lua register TheDesiredUsername meet.jitsi TheDesiredPassword
```

## Использование

Для создания встречи нужно открыть `https://meet.example.com` и будет создана
комната со случайным названием. Первый вошедший пользователь становится
модератором.

Приведённая конфигурация требует аутентификации от модератора при создании
комнаты (`ENABLE_AUTH=1`) и разрешает анонимный вход гостям, если во встрече
есть модератор (`ENABLE_GUESTS=1`). Эти настройки можно изменить -- разрешить
анонимный вход и создание комнат для всех, или наоборот, запретить вход
анонимным гостям.

## Дополнительные настройки

При развёртывании Jitsi Meet через Docker Compose можно задавать различные
опции через `.env` файл (полный список доступен в `docker-compose.yml`).

Некоторые полезные опции:

* `DEFAULT_LANGUAGE=ru` - язык интерфейса по умолчанию.
* `TOOLBAR_BUTTONS=camera,chat` - набор доступных кнопок в интерфейсе (полный
  список в файле
  [config.js#L861](https://github.com/jitsi/jitsi-meet/blob/master/config.js#L861)).
