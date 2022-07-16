#!/bin/bash
modprobe btusb
sleep 10
systemctl restart bluetooth.service

