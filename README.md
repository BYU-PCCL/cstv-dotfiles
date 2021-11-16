# Footron Controller Setup

Base system is Ubuntu 20.04 Server. For best results, try to follow each section in order.

## BIOS setup

This section (which may be incomplete) assumes you're configuring an Asus Pro WS WRX80E-SAGE SE WIFI.

- Boot
  - Enable Fast Boot
  - Set "Next Boot after AC Power Loss" to "Fast Boot"
  - Disable "Wait for 'F1' If Error"
- Server Mgmt
  - Disable BCM in Server Management (@vinhowe has observed that disabling this feature makes boot times faster, which is something we probably care about more than remote BIOS administration)

## Add users

- Create default `remote` user with sudoer permissions—this can just be done through the default Ubuntu Server setup
- Create `ft` user IN GROUP `docker` and `ft`
- Add sudoers file from dotfiles (or just take relevant `ft` line out)

## Install applications

- Update repositories and upgrade packages before doing anything else: `sudo apt update && sudo apt upgrade`
- Set Vim as default editor (useful for `sudoedit`, which you'll use a lot): `sudo update-alternatives --set editor /usr/bin/vim.basic`
- Install Xorg: `sudo apt install xorg`
- Install Python: `sudo apt install python python3-pip`
- Build and install [`hsetroot`](https://github.com/himdel/hsetroot)
- Build and install picom (X compositor) (https://www.linuxfordevices.com/tutorials/linux/picom)
- Install fonts:
  - From Ubuntu repositories:
    ```sh
    sudo apt install ubuntu-mono fonts-open-sans fonts-lato fonts-noto-cjk fonts-ubuntu ttf-dejavu-core ttf-liberation fonts-noto-color-emoji
    ```
  - Manually (copy .ttf files to `/usr/share/fonts/truetype/<lowercase hyphenated font name>/`):
    - [Work Sans](https://fonts.google.com/specimen/Work+Sans) (for @wingated's clock)
    - [Montserrat](https://fonts.google.com/specimen/Montserrat) (Placard title font)
  - Clear cache with `fc-cache -fv`
- Disable startup network device wait service:
  - `systemctl disable systemd-networkd-wait-online.service`
  - `systemctl mask systemd-networkd-wait-online.service`


## Network Time

- Install Chrony and synchronize network time:
  - `sudo apt install chrony`
  - `sudo chrony -q`
- Assuming we're always in MDT: `sudo timedatectl set-timezone America/Denver`

## Drivers

- Install `ubuntu-drivers`: `sudo apt install ubuntu-drivers-common`
- Use `ubuntu-drivers` to find the newest version nvidia drivers and install them.
- Follow instructions on [Nvidia's website](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=20.04&target_type=deb_local)
  to install the latest CUDA release.

Do _not_ do the following unless you've tried everything else and found that nothing works--I'm not sure this actually fixes anything for us but it's useful for reference:

- Set up early KMS for nvidia modules in `/etc/initramfs-tools/modules`: https://itectec.com/ubuntu/ubuntu-how-to-enable-early-kms-on-ubuntu/
  - We may want to reevaluate this step at some point and decide if it helps us on our new hardware setup

## Docker

- Install Docker
- Follow steps to make it work for all users
- [Install Docker Nvidia runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Add `ft` user to `docker` group
- [Configure /etc/docker/daemon.json `log-driver: "journald"`](https://docs.docker.com/config/containers/logging/configure/)

## GPU bug reboot timer

We automatically restart the machine every night at 3 AM to try to prevent our nasty
unresolved GPU crashes from rebooting the machine during the day.

- Copy `etc/systemd/system/gpu-reboot.timer` from dotfiles to `/etc/systemd/system/`
- Enable and start the timer:
  - `systemctl enable gpu-reboot.timer`
  - `systemctl start gpu-reboot.timer`

## Magewell EDID setup service

- Copy `etc/systemd/system/set-capture-edid.service` from dotfiles to `/etc/systemd/system/`
- Enable and start the service
  ```
  systemctl enable set-capture-edid.service
  systemctl start set-capture-edid.service
  ```

## Silent boot

The advice here is based on [this page](https://wiki.archlinux.org/title/Silent_boot) in the Arch Linux wiki.

- `sudoedit /etc/default/grub` and edit the `GRUB_CMDLINE_LINUX_DEFAULT` line:
  ```
  GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 vga=current rd.systemd.show_status=auto rd.udev.log_level=3 fsck.mode=skip vt.global_cursor_default=0"
  ```
- `sudo grub-mkconfig -o /boot/grub/grub.cfg` to update GRUB config
- Copy `etc/sysctl.d/20-quiet-printk.conf` to corresponding path on target machine
- Run `TERM=linux sudo sh -c "setterm -cursor on >> /etc/issue"` to keep cursor on terminal

## Footron apps

- Build and copy `footron-placard` AppImage to `/home/ft/.local/bin/footron-placard`
- Build and copy `footron-loader` AppImage to `/home/ft/.local/share/footron/bin/footron-loader` _(note that this is a different path than the last one)_
- Build and copy `footron-web-shell` AppImage to `/home/ft/.local/share/footron/bin/footron-web-shell`
- Install packages:
  - `pip install --user --upgrade git+https://github.com/BYU-PCCL/footron-wm.git`
  - `pip install --user --upgrade git+https://github.com/BYU-PCCL/footron-controller.git`
- Follow [controller setup instructions](https://github.com/BYU-PCCL/footron-controller/blob/main/README.md)

## User systemd setup

- Install getty override from `etc/systemd/system/getty@tty1.service.d/override.conf` to the same directory relative to `/` on the target machine, creating directories as needed.
- Copy everything from dotfiles `./home/ft/` to `/home/ft/` with rsync: `rsync -azP ./*. ft@<hostname>:~/`
  - Use `rsync -azP` here because the -a flag includes the `-l` flag, which will preserve symlinks. This is important for us.
- Reload daemon: `systemctl --user daemon-reload`
