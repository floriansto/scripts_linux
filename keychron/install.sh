#!/bin/bash

cp main.conf /etc/bluetooth/main.conf
cp hid_apple.conf /etc/modprobe.d/
cp btusb_disable_autosuspend.conf /etc/modprobe.d/

