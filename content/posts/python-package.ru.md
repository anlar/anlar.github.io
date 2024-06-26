---
title: "Создание и публикация пакета в PyPI"
date: 2023-09-13T00:00:00+04:00
draft: false
tags:
  - python
  - packaging
aliases: ['/ru/2023-09-13-python-package/']
---

В экосистеме Python существует много систем для сборки и публикации пакетов. Здесь описывается самый простой и, насколько это возможно, "официальный и современный"  на данный момент способ. Для примера используется консольное приложение на Python, которое можно будет как запускать из командной строки, так и использовать как библиотеку в других приложениях.

<!--more-->

Примером пакета, собранного этим способом, является `todoist-to-todotxt`:

* [Репозиторий проекта](https://github.com/anlar/todoist-to-todotxt)
* [Страница в PyPI](https://pypi.org/project/todoist-to-todotxt/)

## Подготовка

Сборка будет проходить в Ubuntu. Для работы понадобится Python 3, pip (пакетный менеджер) и virtualenv (для изолированной сборки пакета):

    # apt install python3-pip python3-venv

Также нужна система для сборки проектов Python:

    $ pip install --upgrade build

И утилита для загрузки пакетов в PyPI:

    $ pip install --upgrade twine

## Структура проекта

Будем создавать проект с названием `project-a`. Для этого нужна следующая структура файлов:

**Директория проекта:**

```sh {hl_lines=[2, 4, 5, 6, 7, 8]}
package-a/
├── src
│   └── package_a
│       ├── __init__.py
│       └── main.py
├── README.md
├── LICENSE.txt
└── pyproject.toml
```

1. **<2>** Директория с исходным кодом проекта.
1. **<4>** Пустой файл `\\__init__.py` для обозначения пакета.
1. **<5>** Главный файл с кодом.
1. **<6>** Файл с описанием проекта.
1. **<7>** Лицензия проекта (выбираем лицензию и копируем текст отсюда: https://choosealicense.com/).
1. **<8>** Файл с описанием пакета (необходим для сборки).

Добавим простой код в `main.py`, который выводит название проекта:

**main.py:**

```python
#!/usr/bin/env python3

def cli():
    print("Project A")

if __name__ == "__main__":
    cli()
```

Для описания сборки используется файл `pyproject.toml`, который является "фронтендом" для разных систем сборки (в данном примере используется `setuptools`).

**pyproject.toml:**

```toml {hl_lines=[1, 5, 22]}
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "package-a"
version = "0.0.1"
authors = [
  { name="Developer Name", email="developer-email@test.com" },
]
description = "Dummy package A"
readme = "README.md"
license = { file = "LICENSE.txt" }
requires-python = ">=3.7"
classifiers = [
    "Programming Language :: Python :: 3",
    "License :: OSI Approved :: MIT License",
    "Operating System :: OS Independent",
]
keywords = ["dummy", "test"]

[project.scripts]
package-a = "package_a.main:cli"

[project.urls]
"Homepage" = "https://github.com/anlar/package-a"
"Repository" = "https://github.com/anlar/package-a"
"Bug Tracker" = "https://github.com/anlar/package-a/issues"
```

1. **<1>** Описание выбранной системы сборки для пакета.
1. **<5>** Мета-информация о пакете.
1. **<22>** Название исполняемого файла, который будет создан для запуска скрипта.

## Сборка

Запускаем сборку пакета из директории `package-a`:

    $ python -m build

В результате получим собранный пакет в директории `dist`:

    package_a-0.0.1-py3-none-any.whl
    package-a-0.0.1.tar.gz

## Публикация пакета

Для публикации сначала можно использовать тестовый репозиторий PyPI - [TestPyPI](https://test.pypi.org/). После того, как загрузка и установка пакета будут протестированы, по аналогичной схеме можно загружать пакет в PyPI.

Регистрируемся в TestPyPI, подключаем двухфакторную аутентификацию (без неё не будет работать загрузка пакетов) и создаём API token: https://test.pypi.org/manage/account/#api-tokens.

Теперь можно загрузить собранный пакет:

    $ python -m twine upload --repository testpypi dist/*

Потребуется ввести имя - используется `__token__`, и пароль - созданный API token.

После успешной загрузки можно установить загруженный пакет из репозитория:

    $ pip install -i https://test.pypi.org/simple/ package-a

Далее, после завершения тестирования в TestPyPI, нужно зарегистрироваться в основном репозитории PyPI (и получить новый API token) и использовать аналогичные команды для загрузки и установки пакета:

    $ python -m twine upload dist/*
    $ pip install package-a

