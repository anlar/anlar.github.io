---
title: "Загрузка SSH-ключей с помощью Ansible"
date: 2022-12-02T00:00:00+04:00
draft: false
tags:
  - ansible
  - ssh
aliases: ['/ru/2022-12-02-ansible-ssh-key-deployment/']
---

При развёртывании систем бывает нужно сгенерировать SSH-ключи, которые будут использовать удалённые серверы для доступа друг к другу. Например, родительский сервер `head` должен иметь доступ по SSH к нескольким дочерним серверам `node*`. Ниже приведён пример плейбука для Ansible, который добавляет на сервер `head` новый SSH-ключ и размещает его публичную часть на серверы `node*`. Т.е. после его выполнения родительский сервер будет иметь доступ по SSH к дочерним.

<!--more-->

Плейбук является идемпотентным, т.е. при повторном выполнении он проверяет, что ключ уже сгенерирован и размещен на серверах. Но если ключ или запись в `known_hosts` будут удалены, то он их восстановит.

**Плейбук `deploy-ssh-key.yml`:**

```yml {hl_lines=[1, 4, 12, 16, 26]}
- name: Generate key on head host
  hosts: head
  tasks:
    - name: Generate SSH key
      community.crypto.openssh_keypair:
        path: /home/head-user/.ssh/id_ed25519
        type: ed25519
        owner: head-user
        group: head-user
      register: key_result

    - name: Set public SSH key variable
      ansible.builtin.set_fact:
        public_ssh_key: "{{ key_result.public_key }}"

    - name: Add host to known_hosts
      include_tasks:
        file: add-known-host.yml
      vars:
        cfg_node: "{{ item }}"
      loop:
        - node1
        - node2
        - node3

- name: Copy generated SSH public key to nodes
  hosts: node1,node2,node3
  tasks:
    - name: Copy SSH public key
      ansible.posix.authorized_key:
        user: node-user
        state: present
        key: "{{ hostvars['head']['public_ssh_key'] }}"
```

1. **<1>** Первый play: на главном хосте создаём SSH-ключ и добавляем в `known_hosts` все дочерние хосты.
1. **<4>** Генерируем ed25519 SSH-ключ.
1. **<12>** Записываем публичную часть ключа в переменную.
1. **<16>** Добавляем все дочерние хосты в `known_hosts`.
1. **<26>** Второй play: на каждом дочернем хосте заносим главный хост в список авторизованных ключей.

**Файл `add-known-host.yml`:**

```yml {hl_lines=[1, 5]}
- name: "Get key from host {{ cfg_node }}"
  command: "ssh-keyscan -t ecdsa {{ hostvars[ cfg_node ].ansible_host}} | grep -v ^#"
  register: ecdsa_key

- name: Add key to known_hosts
  known_hosts:
    name: "{{ hostvars[ cfg_node ].ansible_host }}"
    path: /home/head-user/.ssh/known_hosts
    key: "{{ ecdsa_key.stdout }}"
```

1. **<1>** Генерируем запись для `known_hosts`.
1. **<5>** Заносим родительский хост в `known_hosts`.

## Примечания

1. Запись дочерних хостов вынесена в отдельный файл, т.к. в Ansible [нельзя создавать цикл по нескольким переменным для блоков](https://github.com/ansible/ansible/issues/13262#issuecomment-335904803) (а у нас 2 задачи - генерация записи через `ssh-keyscan` и запись в `known_hosts`). Если дочерний хост только один, то можно объединить всё в один плейбук.
1. Для доступа к переменной `public_ssh_key` используется `hostvars['head']`, т.к. переменные хранятся на уровне хоста. Чтобы не привязываться к имени конкретного хоста, можно завести dummy-хост, в котором будут храниться общие переменные для всего плейбука. Например:

    ```yml
    - name: Add dummy host with variable
      ansible.builtin.add_host:
        name: dummy-host
        public_ssh_key: "{{ key_result.public_key }}"
    ```
	
3. Можно не добавлять родительский хост в `known_hosts` дочерних, тогда нужно будет при работе по SSH использовать атрибут `StrictHostKeyChecking=no`.

