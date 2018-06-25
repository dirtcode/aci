#!/bin/zsh
#
# AUTHOR: Lucien Zerger
# DESCRIPTION: Arch Custom Installer Main


ACI_INSTALL_LOG_FILE=./__aci-1.txt
ACI_ESC_SEQ="\x1b["
ACI_COL_GREEN=$ACI_ESC_SEQ"32;01m"
ACI_COL_RED=$ACI_ESC_SEQ"31;01m"
ACI_COL_RESET=$ACI_ESC_SEQ"39;49;00m"
ACI_USERHOME=/home/$ACI_USERNAME
#ACI_USERGROUP=users

function write_green () {
  if (( $# == 0))
  then
    echo ""
    echo "" >> $ACI_INSTALL_LOG_FILE
  else
    echo -e "$ACI_COL_GREEN$@$ACI_COL_RESET"
    echo "$@" >> $ACI_INSTALL_LOG_FILE
  fi
}

function write_red_terminate () {
  if (( $# == 0))
  then
    echo ""
    echo "" >> $ACI_INSTALL_LOG_FILE
  else
    echo -e "$ACI_COL_RED$@$ACI_COL_RESET"
    echo "$@" >> $ACI_INSTALL_LOG_FILE
  fi
  exit 1
}

if [ "$EUID" -ne 0 ]
then
  write_red_terminate "Please run as root."
fi

#if [ "$#" -ne 2 ]
#then
#  echo "Usage: aci-inst-main.sh <hostname> <username>"
#  exit 1
#fi

if [ "x$ACI_USERNAME" == "x" ]
then
  write_red_terminate "Username not specified in configuration."
fi

if [ "x$ACI_HOSTNAME" == "x" ]
then
  write_red_terminate "Hostname not specified in configuration."
fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# init AUR
write_green ">>> Initialising AUR <<<"
echo "" >> /etc/pacman.conf
echo "[archlinuxfr]" >> /etc/pacman.conf
echo "SigLevel = Never" >> /etc/pacman.conf
echo "Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf
# yaourt might need to be built from source
#pacman -Sy --noconfirm yaourt
#if [ $? -ne 0 ]; then; write_red_terminate "Cannot install AUR package manager."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# install general packages
write_green ">>> Installing general packages <<<"
pacman -Sy --noconfirm openssh openssl \
  acpi sysstat unrar wget p7zip intel-ucode \
  syslinux gptfdisk f2fs-tools btrfs-progs \
  iw wpa_supplicant wpa_actiond ifplugd \
  nftables nmap openvpn dnscrypt-proxy \
  firejail  linux-hardened sshfs encfs rsync
if [ $? -ne 0 ]; then; write_red_terminate "Cannot install general packages."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# install dev packages
if [ "x$ACI_PACKAGEINSTALL_DEV" == "xyes" ]
then
  write_green ">>> Installing development packages <<<"
  pacman -S --noconfirm git docker
  if [ $? -ne 0 ]; then; write_red_terminate "Cannot install dev packages."; fi
  systemctl enable docker
fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# install laptop specific packages
if [ "x$ACI_PACKAGEINSTALL_LAPTOP" == "xyes" ]
then
  write_green ">>> Installing laptop specific packages <<<"
  pacman -S --noconfirm xf86-input-synaptics xf86-video-vesa xf86-video-ati xf86-video-intel xf86-video-amdgpu xf86-video-nouveau
  if [ $? -ne 0 ]; then; write_red_terminate "Cannot install laptop specific packages."; fi
fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# install X packages
if [ "x$ACI_PACKAGEINSTALL_X" == "xyes" ]
then
  write_green ">>> Installing X packages <<<"
  pacman -S --noconfirm xorg xorg-xinit lightdm lightdm-gtk-greeter vlc chromium \
    keepassxc virtualbox virtualbox-host-modules-arch gimp audacity audacious evince atom dolphin \
    libreoffice-fresh terminator pulseaudio pulseaudio-equalizer pulseaudio-alsa \
    arandr feh pavucontrol rofi alsa-utils scrot rxvt-unicode ttf-hack \
    xorg-xbacklight artwiz-fonts ttf-cheapskate termite ttf-roboto ttf-dejavu
  if [ $? -ne 0 ]
  then
    write_red_terminate "Cannot install X packages."
  else
    echo "greeter-session=lightdm-gtk-greeter.desktop" >> /etc/lightdm/lightdm.conf
    systemctl enable lightdm
  fi

  pacman -S --noconfirm openbox obconf obmenu \
    lxappearance-gtk3 lxappearance-obconf-gtk3 lxinput-gtk3 lxrandr-gtk3 lxtask-gtk3 lxmenu-data \
    xfce4 xfce4-goodies pcmanfm-gtk3 xarchiver
  if [ $? -ne 0 ]; then; write_red_terminate "Cannot install openbox packages."; fi

  pacman -S --noconfirm i3 dmenu  rxvt-unicode xorg-xbacklight cairo-dock
  if [ $? -ne 0 ]; then; write_red_terminate "Cannot install i3wm packages."; fi

  pacman -S --noconfirm awesome xfce4 xfce4-goodies
  if [ $? -ne 0 ]; then; write_red_terminate "Cannot install awesome wm packages."; fi

fi


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# set locale
write_green ">>> Setting locale, language and timezone <<<"
echo "en_AU.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_AU.UTF-8" > /etc/locale.conf
export LANG=en_AU.UTF-8
ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc --utc
if [ $? -ne 0 ]; then; write_red_terminate "Cannot set hardware clock."; fi
echo "KEYMAP=us" > /etc/vconsole.conf


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# configure boot loader
write_green ">>> Configure syslinux boot loader - /boot/syslinux/syslinux.cfg <<<"
syslinux-install_update -iam
cp /boot/syslinux/syslinux.cfg /boot/syslinux/syslinux.cfg.b
echo "DEFAULT arch" > /boot/syslinux/syslinux.cfg
echo "LABEL arch" >> /boot/syslinux/syslinux.cfg
echo "  LINUX ../vmlinuz-linux" >> /boot/syslinux/syslinux.cfg
echo "  APPEND cryptdevice=/dev/sda2:root root=/dev/mapper/root rw" >> /boot/syslinux/syslinux.cfg
echo "  INITRD ../intel-ucode.img,../initramfs-linux.img" >> /boot/syslinux/syslinux.cfg


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# init ramdisk encryption hook
write_green ">>> Configure ramdisk encryption hook - /etc/mkinitcpio.conf <<<"
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.b
awk '"HOOKS="{gsub("block filesystems", "block encrypt filesystems")};{print}' /etc/mkinitcpio.conf.b > /etc/mkinitcpio.conf
mkinitcpio -p linux
if [ $? -ne 0 ]; then; write_red_terminate "Ramdisk init failed."; fi


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# encrypt DNS traffic (cisco opendns auto resolves to 208.67.220.220, 208.67.222.222)
# don't forget to set DNS to 127.0.0.1 in resolv.conf or NetworkManager
write_green ">>> Init DNSCrypt-Proxy - /etc/dnscrypt-proxy.conf <<<"
echo "ResolverName cisco" > /etc/dnscrypt-proxy.conf
#echo "ResolverName cisco-familyshield" > /etc/dnscrypt-proxy.conf
systemctl enable dnscrypt-proxy

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# disable ssh root AND password login, requiring keys only
write_green ">>> Security: remove root ssh access and non-root password access - /etc/ssh/sshd_config <<<"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.b
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
systemctl enable sshd

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# set host name
write_green ">>> Set machine host name - /etc/host{s,name} <<<"
echo "$ACI_HOSTNAME" > /etc/hostname
echo "127.0.0.1   localhost.localdomain   localhost $ACI_HOSTNAME" > /etc/hosts
echo "::1         localhost.localdomain   localhost $ACI_HOSTNAME" >> /etc/hosts

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# add first user as sudo user
write_green ">>> Create first user <<<"
useradd -m -U -s /bin/zsh $ACI_USERNAME
if [ $? -ne 0 ]; then; write_red_terminate "Could not create user."; fi
while true
do
  passwd $ACI_USERNAME
  if [ $? -eq 0 ]; then; break; fi
done
echo "$ACI_USERNAME ALL=(ALL) ALL" >> /etc/sudoers
echo 'alias ls="ls --color=always"' >> $ACI_USERHOME/.zshrc
echo 'alias ll="ls -la --color=always"' >> $ACI_USERHOME/.zshrc
echo 'autoload -Uz promptinit' >> $ACI_USERHOME/.zshrc
echo 'promptinit' >> $ACI_USERHOME/.zshrc
echo 'prompt fade' >> $ACI_USERHOME/.zshrc
# copy awesome wm default config to user's home dir
mkdir -p $ACI_USERHOME/.config/awesome/
cp /etc/xdg/awesome/rc.lua $ACI_USERHOME/.config/awesome/rc.lua
touch $ACI_USERHOME/.config/awesome/autorun.sh
chown -R $ACI_USERNAME:$ACI_USERNAME $ACI_USERHOME/.config
chmod -R 600 $ACI_USERHOME/.config
chmod +x $ACI_USERHOME/.config/awesome/autorun.sh

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# disable root terminal access
write_green ">>> Disable root terminal access <<<"
passwd -l root
if [ $? -ne 0 ]; then; write_red_terminate "Could not disable root terminal access."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# init swap file
ACI_SWAP_FILENAME=/swapfile.bin
write_green ">>> Init swap file <<<"
dd if=/dev/zero of=$ACI_SWAP_FILENAME bs=1M count=4096 status=progress && sync
chmod 600 $ACI_SWAP_FILENAME
mkswap $ACI_SWAP_FILENAME
if [ $? -ne 0 ]; then; write_red_terminate "Failed to make swap space from file."; fi
swapon $ACI_SWAP_FILENAME
echo "$ACI_SWAP_FILENAME none swap defaults 0 0" >> /etc/fstab

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# assign dhcp ip to ethernet adapter
ACI_ETHERNET_CONFIG_FILENAME=/etc/netctl/ethernet-dhcp
write_green ">>> Init ethernet dhcp adapter <<<"
ip address show
while true
do
  echo -n "Name of ethernet adapter? [...][none] "
  read ACI_ETHERNET_ADAPTERNAME

  if [ "x$ACI_ETHERNET_ADAPTERNAME" = "xnone" ]
  then
    echo -n "Skip configuration? [y][n] "
    case $ACI_ETHERNET_ADAPTERNAME in
      y) break;;
      n) ;;
      *) echo "Please answer yes or no.";;
    esac


  else
    echo "" > $ACI_ETHERNET_CONFIG_FILENAME
    echo "Description='DHCP ethernet'" >> $ACI_ETHERNET_CONFIG_FILENAME
    echo "Interface=$ACI_ETHERNET_ADAPTERNAME" >> $ACI_ETHERNET_CONFIG_FILENAME
    echo "Connection=ethernet" >> $ACI_ETHERNET_CONFIG_FILENAME
    echo "IP=dhcp" >> $ACI_ETHERNET_CONFIG_FILENAME
    echo "# set DNS to localhost for dnscrypt-proxy to resolve" >> $ACI_ETHERNET_CONFIG_FILENAME
    echo "DNS=('127.0.0.1')" >> $ACI_ETHERNET_CONFIG_FILENAME
    chmod 600 $ACI_ETHERNET_CONFIG_FILENAME
    systemctl enable netctl-ifplugd@$ACI_ETHERNET_ADAPTERNAME.service
    break
  fi
done

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# enable additional services
systemctl enable nftables
