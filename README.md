# Purpose
This is a collection of some scripts I use regulary on my linux machines

# Keychron config files
The files in the `keychron` folder make keychron keyboards usable under linux.

The `btusb_disable_autosuspend.conf` lets the keyboard reconnect after loss of connection due to
standby or power loss of eiher the keyboard or the pc.
`hid_apple.conf` makes the F-keys and their fn-representations functional.
By default the second layer (media keys etc.) is enabled, but pressing the fn-key has no effect.
With this configuration pressing the keys will fire the F-keys (F1 to F12) and pressing the fn-key in
combination with an F-key will get you the secondary function of the key.
The `main.conf` file is the bluetooth configuration file.
It's the standard configuration but with
```
FastConnectable = true
```
which lets you reconnect faster to known devices as bluetooth keyboards.

For faster reconnection of any keyboard it is also recommended to set your device to `trusted` e.g.
using `bluetoothctl`.

# backupPacman.sh
This script generates a file containing the names of all installed packages in your `~/.backup_pacman/` folder.
It's best to regulary call this script using a cronjob.
Currently 50 files are stored.
If this number is exceeded, the oldes files are deleted.

# mousespeed.sh
This script sets the mousespeed of my **Razer DeathAdder** mouse.

# startBackup.sh
It calls the [data-backup-tool](https://github.com/floriansto/data-backup-tool) running on my server,
to create regular backups of my desktop pc and my laptop.

# syncWallpaper.sh
Synchronize wallpapers with a remote location.
May also be run regulary as cronjob.
