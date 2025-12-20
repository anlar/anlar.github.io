---
title: 'Install Nerd Fonts in Linux'
date: '2025-12-20T17:05:51+01:00'
draft: false
tags:
  - linux
  - fonts
  - neovim
---

When working in Neovim you may require custom icons to display specific things
(like file types in `lualine`, or icons in `gitsigns`). Most of these plugins
rely on [Nerd Fonts](https://www.nerdfonts.com/font-downloads) - project that
patches developer-oriented fonts with additional icons.

<!--more-->

To install these fonts you need to download them from their site, extract to
your font directory and update fonts cache. Below is the script to do it:

```sh
#! /usr/bin/env sh

release="v3.4.0"
main_link="https://github.com/ryanoasis/nerd-fonts/releases/download/$release"

# space-separated list of fonts
fonts="JetBrainsMono Ubuntu"

for font in $fonts; do
    link="$main_link/$font.zip"
    wget -O /tmp/"$font".zip "$link"
    unzip -o /tmp/"$font".zip -d "$HOME/.local/share/fonts"
    rm /tmp/"$font".zip
done

fc-cache -f -v
```

You need to replace `release` variable with current release (available on
[latest Nerd Font
release](https://github.com/ryanoasis/nerd-fonts/releases/latest)), and `fonts`
with space-separated list of your fonts.
