# encrypt root partition if set to true
export ACI_CRYPTPART=true

# name of user created by installer
#ACI_USERNAME=dieter
export ACI_USERNAME=user

# name of computer
#ACI_HOSTNAME=shutdown
export ACI_HOSTNAME=host

# desktop environment, can be i3 or kdeplasma
export ACI_DE=i3

# automatically set, do NOT modify
export ACI_USERHOME=/home/$ACI_USERNAME

# use vpn
export ACI_VPNENABLE=true
export ACI_VPNNAME=nordvpn

#ACI_CRYPT_KEYFILE=$1

if [ "x$ACI_HOSTNAME" = "x" ]
then
  echo "No hostname specified."
  exit 1
fi

if [ "x$ACI_USERNAME" = "x" ]
then
  echo "No username specified."
  exit 1
fi

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"


#####################################
# install additional packages
# the wpa_actiond package and start/enable netctl-auto@interface.service systemd unit. netctl profiles will be started/stopped automatically as you move from the range of one network into the range of another network (roaming).
# the ifplugd package and start/enable the netctl-ifplugd@interface.service systemd unit. DHCP profiles will be started/stopped when the network cable is plugged in/unplugged.
echo -e "$COL_GREEN *** Install additional packages *** $COL_RESET"
pacman -S --noconfirm sudo openssh openssl  zsh zsh-completions grml-zsh-config \
  acpi sysstat unrar wget p7zip intel-ucode \
  syslinux gptfdisk f2fs-tools btrfs-progs

# install network adapter packages
pacman -S --noconfirm iw wpa_supplicant wpa_actiond ifplugd

# install software dev tools
pacman -S --noconfirm git docker

# install laptop driver packages
pacman -S --noconfirm xf86-input-synaptics xf86-video-amdgpu

# install X and desktop applications
pacman -S --noconfirm xorg xorg-xinit lightdm lightdm-gtk-greeter vlc chromium \
  keepassx2 virtualbox gimp audacity audacious evince atom dolphin \
  libreoffice-fresh terminator pulseaudio pulseaudio-equalizer pulseaudio-alsa \
  arandr feh pavucontrol rofi alsa-utils scrot

if [ "x$ACI_DE" = "xkdeplasma" ]
then
  pacman -S --noconfirm plasma kde-applications
fi
if [ "x$ACI_DE" = "xi3" ]
then
  pacman -S --noconfirm i3 dmenu  rxvt-unicode xorg-xbacklight cairo-dock
fi
if [ "x$ACI_DE" = "xopenbox" ]
then
  pacman -S --noconfirm openbox obconf obmenu
  pacman -S --noconfirm lxappearance-gtk3 lxappearance-obconf-gtk3 lxinput-gtk3 lxrandr-gtk3 lxtask-gtk3 lxmenu-data
  pacman -S --noconfirm xfce4 xfce4-goodies
  pacman -S --noconfirm pcmanfm-gtk3 xarchiver
fi

# install security applications
pacman -S --noconfirm sshguard nftables nmap openvpn dnscrypt-proxy

# extra packages
#pacman -S adobe-source-sans-pro-fonts aspell-en enchant gst-libav gst-plugins-good hunspell-en icedtea-web jre8-openjdk languagetool libmythes mythes-en pkgstats ttf-anonymous-pro ttf-bitstream-vera ttf-dejavu ttf-droid ttf-gentium ttf-liberation ttf-ubuntu-font-family

#####################################
# configure AUR
#cat acires-aur >> /etc/pacman.conf
echo "" >> /etc/pacman.conf
echo "[archlinuxfr]" >> /etc/pacman.conf
echo "SigLevel = Never" >> /etc/pacman.conf
echo "Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf
pacman -Sy --noconfirm yaourt

#####################################
# set locale
echo -e "$COL_GREEN *** Set locale, language, timezone *** $COL_RESET"
echo "en_AU.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_AU.UTF-8" > /etc/locale.conf
export LANG=en_AU.UTF-8
ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc --utc
echo "KEYMAP=us" > /etc/vconsole.conf

#####################################
# configure boot loader
echo -e "$COL_GREEN *** Configure boot loader - /boot/syslinux/syslinux.cfg *** $COL_RESET"
syslinux-install_update -iam
cp /boot/syslinux/syslinux.cfg /boot/syslinux/syslinux.cfg.b
echo "DEFAULT arch" > /boot/syslinux/syslinux.cfg
echo "LABEL arch" >> /boot/syslinux/syslinux.cfg
echo "  LINUX ../vmlinuz-linux" >> /boot/syslinux/syslinux.cfg
if [ "x$ACI_CRYPTPART" = "xtrue" ]
then
  echo "  APPEND cryptdevice=/dev/sda3:root root=/dev/mapper/root rw" >> /boot/syslinux/syslinux.cfg
else
  echo "  APPEND root=/dev/sda2 rw" >> /boot/syslinux/syslinux.cfg
fi

echo "  INITRD ../intel-ucode.img,../initramfs-linux.img" >> /boot/syslinux/syslinux.cfg
#echo "DEFAULT arch" > /boot/syslinux/syslinux.cfg.tmp1
#awk '/^LABEL arch$/ {f=1} f==0 {next} /^$/ {exit} {print substr($0, 1)}' /boot/syslinux/syslinux.cfg.b >> /boot/syslinux/syslinux.cfg.tmp1
#awk '"APPEND"{gsub("root=/dev/sda3", "cryptdevice=/dev/sda2:root root=/dev/mapper/root")};{print}' /boot/syslinux/syslinux.cfg.tmp1 > /boot/syslinux/syslinux.cfg.tmp2
#awk '"INITRD"{gsub("../initramfs-linux.img", "../intel-ucode.img,../initramfs-linux.img")};{print}' /boot/syslinux/syslinux.cfg.tmp2 > /boot/syslinux/syslinux.cfg
#rm -f /boot/syslinux/syslinux.cfg.tmp*


#####################################
# config enc
echo -e "$COL_GREEN *** Add encryption hook - /etc/mkinitcpio.conf *** $COL_RESET"
if [ "x$ACI_CRYPTPART" = "xtrue" ]
then
  cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.b
  echo "MODULES=()" > /etc/mkinitcpio.conf
  echo "BINARIES=()" >> /etc/mkinitcpio.conf
  echo "FILES=()" >> /etc/mkinitcpio.conf
  echo "HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)" >> /etc/mkinitcpio.conf
fi
#awk '"HOOKS="{gsub("block filesystems", "block encrypt filesystems")};{print}' /etc/mkinitcpio.conf.b > /etc/mkinitcpio.conf
mkinitcpio -p linux

#####################################
# encrypt DNS traffic (no need to use 208.67.220.220,208.67.222.222) and put 127.0.0.1 in resolv.conf or NetworkManager
echo "ResolverName cisco" > /etc/dnscrypt-proxy.conf
#echo "ResolverName cisco-familyshield" > /etc/dnscrypt-proxy.conf
systemctl enable dnscrypt-proxy

#####################################
# disable ssh root AND password login, requiring keys only
echo -e "$COL_GREEN *** Security: remove ssh access to root *** $COL_RESET"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.b
awk '"HOOKS="{gsub("#PermitRootLogin prohibit-password", "PermitRootLogin no")};{print}' /etc/ssh/sshd_config.b > /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

#####################################
# set host name
echo -e "$COL_GREEN *** Set machine host name *** $COL_RESET"
echo "$ACI_HOSTNAME" > /etc/hostname
echo "127.0.0.1   localhost.localdomain   localhost $ACI_HOSTNAME" > /etc/hosts
echo "::1         localhost.localdomain   localhost $ACI_HOSTNAME" >> /etc/hosts

#####################################
# add first user as sudo user
echo -e "$COL_GREEN *** Create first user *** $COL_RESET"
#ACI_USERNAME=user
echo "Creating user $ACI_USERNAME:"
useradd -m -g users -s /bin/zsh $ACI_USERNAME
passwd $ACI_USERNAME
#passwd -e $ACI_USERNAME
echo "$ACI_USERNAME ALL=(ALL) ALL" >> /etc/sudoers
echo 'alias ls="ls --color=always"' >> $ACI_USERHOME/.zshrc
echo 'alias ll="ls -la --color=always"' >> $ACI_USERHOME/.zshrc
echo 'autoload -Uz promptinit' >> $ACI_USERHOME/.zshrc
echo 'promptinit' >> $ACI_USERHOME/.zshrc
echo 'prompt fade' >> $ACI_USERHOME/.zshrc
chown $ACI_USERNAME:users $ACI_USERHOME/.zshrc

#####################################
# init X
cp /etc/X11/xinit/xinitrc $ACI_USERHOME/.xinitrc
if [ "x$ACI_DE" = "xkdeplasma" ]
then
  sed "s/exec.*/exec startkde/g" /etc/X11/xinit/xinitrc > $ACI_USERHOME/.xinitrc
fi
if [ "x$ACI_DE" = "xi3" ]
then
  sed "s/exec.*/exec i3/g" /etc/X11/xinit/xinitrc > $ACI_USERHOME/.xinitrc
fi
chown $ACI_USERNAME:users $ACI_USERHOME/.xinitrc
echo 'exec /usr/bin/Xorg -nolisten tcp "$@" vt$XDG_VTNR' > $ACI_USERHOME/.xserverrc
chown $ACI_USERNAME:users $ACI_USERHOME/.xserverrc

#####################################
# DE terminal init, commented
echo "# initially commented, until DE has been configured" > $ACI_USERHOME/.zprofile
echo "#if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then" >> $ACI_USERHOME/.zprofile
echo "#  exec startx" >> $ACI_USERHOME/.zprofile
echo "#fi" >> $ACI_USERHOME/.zprofile

#####################################
# download and extract tor browser for user
#cd $ACI_USERHOME
#curl xxxxxxx
#tar xf tor-browser-linux64-7.5.3_en-US.tar.xz
#chown -R $ACI_USERNAME:users tor-browser_en-US

#####################################
# set root password or disable terminal access
echo -e "$COL_GREEN *** Disable root terminal access *** $COL_RESET"
#echo -e "$COL_GREEN *** Set root password *** $COL_RESET"
#echo "Set ROOT password:"
#passwd
passwd -l root

# set up openvpn for tunnelbear or nordvpn
#if [ "x$ACI_VPNENABLE" = "xtrue" ]
#then
#  cd /etc/openvpn/client
#  wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
#  sudo unzip ovpn.zip
#  sudo rm *.zip
#  cd ovpn_udp
  #sudo openvpn nz6.nordvpn.com.udp.ovpn
#  systemctl enable openvpn-client@$ACI_VPNNAME.service
#fi

#####################################
# set up swap file
#fallocate -l 8G /swapfile.bin
dd if=/dev/zero of=/swapfile.bin bs=1M count=8192
chmod 600 /swapfile.bin
mkswap /swapfile.bin
swapon /swapfile.bin
echo '/swapfile.bin none swap defaults 0 0' >> /etc/fstab


#####################################
# enable additional services
echo -e "$COL_GREEN *** Enabling essential services *** $COL_RESET"
systemctl enable sshd
#systemctl enable NetworkManager
systemctl enable nftables
systemctl enable docker
