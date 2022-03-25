# Footron Controller Setup

Base system is Ubuntu 20.04 Server. For best results, try to follow each section in order.

It might be easiest to clone this repository to the target machine so that moving files (and dealing with permissions) is easier.

## BIOS setup

This section (which may be incomplete) assumes you're configuring an Asus Pro WS WRX80E-SAGE SE WIFI.

- Boot
  - Enable Fast Boot
  - Set "Next Boot after AC Power Loss" to "Fast Boot"
  - Disable "Wait for 'F1' If Error"
- Server Mgmt
  - Disable BMC in Server Management (@vinhowe has observed that disabling this feature makes boot times faster, which is something we probably care about more than remote BIOS administration)

## Add users

- Create default `remote` user with sudoer permissions—this can just be done through the default Ubuntu Server setup
- Create `ft` user
  ```sh
  sudo useradd -m ft --shell /bin/bash
  ```
- Add sudoers file from dotfiles (or just take relevant `ft` line out)

## Install applications

- Update repositories and upgrade packages before doing anything else: `sudo apt update && sudo apt upgrade`
- Set Vim as default editor (useful for `sudoedit`, which you'll use a lot): `sudo update-alternatives --set editor /usr/bin/vim.basic`
- Install Xorg: `sudo apt install xorg --no-install-recommends --no-install-suggests`
- Install Python: `sudo apt install python3 python3-pip`
- Build and install [`hsetroot`](https://github.com/himdel/hsetroot)
  ```sh
  # Install build dependencies
  sudo apt install libx11-dev libxinerama-dev libimlib2-dev
  # Create and cd to temp dir
  cd $(mktemp -d)
  # Clone and cd into hsetroot repository
  git clone https://github.com/himdel/hsetroot.git && cd hsetroot
  # Build and install
  make && sudo make install
  ```
- Build and install picom (X compositor) (Steps based on https://www.linuxfordevices.com/tutorials/linux/picom)
  ```sh
  # Install build dependencies
  sudo apt install cmake meson asciidoc libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libxcb-glx0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libpcre3-dev
  # Create and cd to temp dir
  cd $(mktemp -d)
  # Clone and cd into picom repository
  git clone https://github.com/jonaburg/picom && cd picom
  # Setup repository
  git submodule update --init --recursive
  # Set up build
  meson --buildtype=release . build
  # Build and install
  ninja -C build && sudo ninja -C build install
  ```
- Install fonts:
  - From Ubuntu repositories (if one of these packages isn't available, Ubuntu might have changed the name from `ttf-*` `fonts-*`):
    ```sh
    sudo apt install ubuntu-mono fonts-open-sans fonts-lato fonts-noto-cjk fonts-ubuntu ttf-dejavu-core fonts-liberation fonts-noto-color-emoji
    ```
  - Manually (copy .ttf files to `/usr/share/fonts/truetype/<lowercase hyphenated font name>/`):
    ```sh
    # Create and cd to temp dir
    cd $(mktemp -d)
    # Work Sans (for @wingated's clock)
    curl -L https://fonts.google.com/download?family=Work%20Sans -o work-sans.zip
    # Montserrat (placard title font)
    curl -L https://fonts.google.com/download?family=Montserrat -o montserrat.zip
    # Unzip fonts
    unzip -d work-sans work-sans.zip
    unzip -d montserrat montserrat.zip
    # Make system font directories and copy files
    sudo mkdir /usr/share/fonts/truetype/{work-sans,montserrat}
    sudo cp montserrat/static/* /usr/share/fonts/truetype/montserrat/
    sudo cp work-sans/static/* /usr/share/fonts/truetype/work-sans/
    ```
    (for @wingated's clock)
  - Clear cache with `fc-cache -fv`
- Disable startup network device wait service (fixes `A start job is running Wait for Network to be Configured` message that hangs for several minutes at startup):
  - `systemctl disable systemd-networkd-wait-online.service`
  - `systemctl mask systemd-networkd-wait-online.service`

## Network Time

- Install Chrony and synchronize network time:
  - `sudo apt install chrony`
  - `sudo chronyd -q`
- Assuming we're always in MDT: `sudo timedatectl set-timezone America/Denver`

## Drivers

- Install `ubuntu-drivers`: `sudo apt install ubuntu-drivers-common`
- Use `ubuntu-drivers list` to find the newest version nvidia driver and install it with `sudo apt install nvidia-drivers-{latest version}`
- Follow instructions on [Nvidia's website](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=20.04&target_type=deb_local)
  to install the latest CUDA release.
- Add `remote`, `ft` users to `video` group:
  ```sh
  sudo usermod -aG video remote
  sudo usermod -aG video ft
  ```

Do _not_ do the following unless you've tried everything else and found that nothing works--I'm not sure this actually fixes anything for us but it's useful for reference:

- Set up early KMS for nvidia modules in `/etc/initramfs-tools/modules`: https://itectec.com/ubuntu/ubuntu-how-to-enable-early-kms-on-ubuntu/
  - We may want to reevaluate this step at some point and decide if it helps us on our new hardware setup

## Docker

- [Install Docker](https://docs.docker.com/engine/install/ubuntu/)
- Create `docker` group and add `remote` and `ft` users:
  ```sh
  sudo usermod -aG docker remote
  sudo usermod -aG docker ft
  ```
  - Eventually we should see if we can get Docker's [rootless mode](https://docs.docker.com/engine/security/rootless/) working because it looks like putting `ft` in the `docker` group might cancel out our token efforts to make the `ft` have as few privileges as possible.
- [Install Docker Nvidia runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- [Configure /etc/docker/daemon.json `log-driver: "journald"`](https://docs.docker.com/config/containers/logging/configure/)
  - To apply this immediately, restart Docker with `sudo systemctl restart docker`

## Set default systemd target

One of the steps before this sometimes changes the default systemctl target to `graphical.target`.

You can check this first if you like:

```sh
systemctl get-default
```

If the output of this command is `multi-user.target`, you can skip to the next step. Otherwise, change the default target.

```sh
systemctl set-default multi-user.target
```

You will need to reboot at some point for this to take effect.

```sh
sudo reboot
```

## Disable unattended upgrades

Run the following command and select `<No>`:

```sh
sudo dpkg-reconfigure unattended-upgrades
```

## GPU bug reboot timer

We automatically restart the machine every night at 3 AM to try to prevent our nasty
unresolved GPU crashes from rebooting the machine during the day.

- Copy `etc/systemd/system/gpu-reboot.timer` from dotfiles to `/etc/systemd/system/`
- Copy `etc/systemd/system/gpu-reboot.service` from dotfiles to `/etc/systemd/system/`
- Enable and start the timer:
  - `systemctl enable gpu-reboot.service`
  - `systemctl enable gpu-reboot.timer`
  - `systemctl start gpu-reboot.timer`

## Silent boot

The advice here is based on [this page](https://wiki.archlinux.org/title/Silent_boot) in the Arch Linux wiki.

- `sudoedit /etc/default/grub` and edit the `GRUB_CMDLINE_LINUX_DEFAULT` line:
  ```
  GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 vga=current rd.systemd.show_status=auto rd.udev.log_level=3 fsck.mode=skip vt.global_cursor_default=0"
  ```
- `sudo grub-mkconfig -o /boot/grub/grub.cfg` to update GRUB config
- Copy `etc/sysctl.d/20-quiet-printk.conf` to corresponding path on target machine
- Run `TERM=linux sudo sh -c "setterm -cursor on >> /etc/issue"` to keep cursor on terminal

## Magewell setup

### Driver

- Download and unzip the newest Magewell Pro Capture driver (this link might not be the newest, you can find the newest download link
  by downloading from https://www.magewell.com/downloads/pro-capture#/driver/linux-x86 and checking the URL)
  ```
  curl -LO https://www.magewell.com/files/drivers/ProCaptureForLinux_4236.tar.gz
  tar xvf ProCaptureForLinux_4236.tar.gz
  cd ProCaptureForLinux_4236
  ./install.sh
  ```

### EDID setup

- Copy `etc/systemd/system/set-capture-edid.service` from dotfiles to `/etc/systemd/system/`
- Enable and start the service
  ```
  systemctl enable set-capture-edid.service
  systemctl start set-capture-edid.service
  ```

### Copy footron-capture-shell, install dependencies

- Install dependencies
  ```sh
  sudo apt install libglfw3 libglew2.1
  ```
- Do this step as `ft` user: copy footron-capture-shell binary to `~/.local/share/footron/bin/footron-capture-shell` (you will have to build it, if you don't have a copy of this binary, pester @vinhowe about how to do this)
  - The parent directory won't exist yet, create it with `mkdir -p ~/.local/share/footron/bin`
  - Make sure it has executable permissions (`chmod +x`)

### Physical installation

At this point, turn off the machine and install the Magewell capture card in a PCIe slot.

## Footron apps

Do all of these steps as the `ft` user:

- Make `~/.local/bin`: `mkdir -p ~/.local/bin/`
- Build and copy `footron-placard` AppImage to `/home/ft/.local/bin/footron-placard`
- Build and copy `footron-loader` AppImage to `/home/ft/.local/share/footron/bin/footron-loader` _(notice that this is a different path than the last one)_
- Build and copy `footron-web-shell` AppImage to `/home/ft/.local/share/footron/bin/footron-web-shell`
- Install packages:
  - `pip install --user --upgrade git+https://github.com/BYU-PCCL/footron-wm.git`
  - `pip install --user --upgrade git+https://github.com/BYU-PCCL/footron-controller.git`
- Follow [controller setup instructions](https://github.com/BYU-PCCL/footron-controller/blob/main/README.md)
  - At this point, you will need to copy the experiences you want to `~/.local/share/footron/experiences`, which won't yet exist. This should probably be better documented but we might not continue to use the system we use now.

## User systemd setup

- As `remote` using sudo: Install getty override from `etc/systemd/system/getty@tty1.service.d/override.conf` to the same directory relative to `/` on the target machine, creating directories as needed.
- As `ft`: Copy everything from dotfiles `./home/ft/` to `/home/ft/`
  - It is going to be a lot easier to do this is you just clone this repository from the `ft` user and copy files out of it. The following assumes you've cloned it to `~/footron-controller-dotfiles` (note the dot at the end of the first path, this is important because it copies hidden files and directories):
    ```sh
    cp -r footron-controller-dotfiles/home/ft/. ~
    ```
  - If instead you decide to copy from another machine (as we have done in the past), use `rsync -azP ./*. ft@<hostname>:~/`. We use `rsync -azP` here because the -a flag includes the `-l` flag, which will preserve symlinks. This is important for us.
- Reload daemon: `systemctl --user daemon-reload`

## (Staging only) API setup

As `ft`:

- Install the API package:
  ```sh
  pip install --user --upgrade git+https://github.com/BYU-PCCL/footron-api.git
  ```
- Copy files from staging-only/ to / on the target machine
- Create a file at `~/.config/footron-api/env`:
  ```ini
  FT_BASE_URL=http://<network visible hostname>
  FT_CONTROLLER_URL=http://localhost:8000
  ```

## TODO

- API setup, which is as described in api-dotfiles unless the target is a staging machine that hosts the API and the controller
- Detailed instructions about setting up experiences
- ??
