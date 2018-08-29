#!/bin/bash

pacman-key --init
pacman-key --populate archlinux

echo LANG=de_DE.UTF-8 > /etc/locale.conf
echo LANGUAGE=de_DE >> /etc/locale.conf

echo KEYMAP=de-latin1-nodeadkeys > /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

sed -i 's/^#de_DE/de_DE/g' locale.gen
locale-gen

sed -i 's/#\[multilib\]/\[multilib\]/g' pacman.conf
sed -i '/\[multilib\]/{n;s/^#//}' pacman.conf
sed -n '/\[multilib\]/,+4p' pacman.conf

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
grep -E -A 1 ".*Germany.*$" /etc/pacman.d/mirrorlist.bak | sed '/--/d' > /etc/pacman.d/mirrorlist

pacman -Sy
pacman -S sudo vim rsync

cd /root
touch /root/.bashrc
echo alias ls='ls --color=auto -h --group-directories-first' > .bashrc
alias ll='ls -l' >> .bashrc
alias hh='history | grep $1' >> .bashrc
alias ..='cd ..' >> .bashrc

touch /root/.vimrc




