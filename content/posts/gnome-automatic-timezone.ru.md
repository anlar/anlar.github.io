---
title: 'Настройка автоматической смены часового пояса в GNOME 46 (Ubuntu 24.04)'
date: 2025-01-18T20:13:00+01:00
draft: false
tags:
  - linux
  - gnome
  - ubuntu
---

В GNOME есть функция автоматического определения часового пояса системы, что удобно при перемещениях между странами.
К сожалению, в данный момент она сломана и требует некоторых дополнительных действий от пользователя,
чтобы заставить её работать.

<!--more-->

## Общий принцип работы

GNOME использует D-Bus сервис `geoclue` для получения текущего местоположения системы.
`geoclue`, в свою очередь, использует внешний сервис для получения координат по IP и данным Wi-Fi сети.

## Включение смены часовых поясов

Для начала необходимо включить функцию в настройках GNOME:

1. В разделе настроек **Date & Time** - **Automatic Time Zone**;
2. В разделе **Privacy & Security / Location** - **Automatic Device Location**.

## Настройка провайдера геолокации

По умолчанию `geoip` использует Mozilla Location Service для получения координат.
Проблема в том, что в 2024 году [этот сервис закрылся](https://discourse.mozilla.org/t/retiring-the-mozilla-location-service/128693).

В логах сервиса можно увидеть ошибку при запросе координат:

```
$ journalctl -u geoclue.service
Jan 08 21:12:25 user systemd[1]: Starting geoclue.service - Location Lookup Service...
Jan 08 21:12:25 user systemd[1]: Started geoclue.service - Location Lookup Service.
Jan 08 21:12:33 user geoclue[2278]: Failed to query location: No WiFi networks found
Jan 08 21:12:38 user geoclue[2278]: Failed to query location: Query location SOUP error: Not Found
Jan 08 21:17:41 user geoclue[2278]: Failed to query location: Query location SOUP error: Not Found
Jan 08 21:17:43 user geoclue[2278]: Failed to query location: Query location SOUP error: Not Found
...
```

`geoclue` позволяет самостоятельно настроить URL провайдера геолокации. После закрытия сервиса от Mozilla
остались (и появились) другие альтернативы:

1. [beaconDB](https://beacondb.net/) - бесплатный сервис (обсуждение на [Hacker News](https://news.ycombinator.com/item?id=40895672));
2. [Google Geolocation API](https://developers.google.com/maps/documentation/geolocation/overview) - требует ключа и оплачивается по количеству запросов.

Для замены будем использовать **beaconDB**. Нужно добавить в файл конфигурации `/etc/geoclue/geoclue.conf` URL нового сервиса:

```
url=https://beacondb.net/v1/geolocate
```

После чего перезапустить демон `geoclue`:

```
# systemctl restart geoclue.service
```

На этом всё. Если что-то не заработает, то необходимо проверить логи `geoclue` на наличие ошибок.

