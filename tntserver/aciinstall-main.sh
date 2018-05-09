

#####################################
# install additional packages
pacman -S --noconfirm sudo openssh openssl iw wpa_supplicant zsh zsh-completions \
  wpa_actiond ifplugd pulseaudio pulseaudio-equalizer arandr feh \
  rofi pavucontrol alsa-utils acpi sysstat scrot unrar wget networkmanager network-manager-applet dhcp 
  #iproute2

# install software dev tools
pacman -S --noconfirm git docker

# install laptop driver packages
pacman -S --noconfirm xf86-input-synaptics xf86-video-amdgpu intel-ucode

# install X
pacman -S --noconfirm xorg-server xorg-xinit
#pacman -S --noconfirm plasma kde-applications
#pacman -S --noconfirm lxde
pacman -S --noconfirm xfce4 xfce4-goodies

# install disk utils and boot loader
pacman -S --noconfirm syslinux gptfdisk  btrfs-progs
#f2fs-tools 

# install web applications
#pacman -S --noconfirm vlc chromium keepassx2 virtualbox
pacman -S --noconfirm firefox

# install security applications
pacman -S --noconfirm sshguard nftables nmap openvpn dnscrypt-proxy

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
echo "en_AU.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_AU.UTF-8" > /etc/locale.conf
export LANG=en_AU.UTF-8
ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc --utc
echo "KEYMAP=us" > /etc/vconsole.conf

#####################################
# configure boot loader
syslinux-install_update -iam
cp /boot/syslinux/syslinux.cfg /boot/syslinux/syslinux.cfg.b
echo "DEFAULT arch" > /boot/syslinux/syslinux.cfg
echo "LABEL arch" >> /boot/syslinux/syslinux.cfg
echo "  LINUX ../vmlinuz-linux" >> /boot/syslinux/syslinux.cfg
echo "  APPEND root=/dev/sda2 rw" >> /boot/syslinux/syslinux.cfg
echo "  INITRD ../intel-ucode.img,../initramfs-linux.img" >> /boot/syslinux/syslinux.cfg


#####################################
# config enc
mkinitcpio -p linux

#####################################
# encrypt DNS traffic (no need to use 208.67.220.220,208.67.222.222) and put 127.0.0.1 in resolv.conf or NetworkManager
echo "ResolverName cisco" > /etc/dnscrypt-proxy.conf
#echo "ResolverName cisco-familyshield" > /etc/dnscrypt-proxy.conf
systemctl enable dnscrypt-proxy

#####################################
# disable ssh root AND password login, requiring keys only
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.b
awk '"HOOKS="{gsub("#PermitRootLogin prohibit-password", "PermitRootLogin no")};{print}' /etc/ssh/sshd_config.b > /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

#####################################
# set host name
echo "tntserver" > /etc/hostname
echo "127.0.0.1   localhost.localdomain   localhost tntserver" > /etc/hosts
echo "::1         localhost.localdomain   localhost tntserver" >> /etc/hosts

#####################################
# add first user as sudo user
#ACI_USERNAME=user
echo "Creating user dieter:"
useradd -m -g users -s /bin/zsh dieter
passwd dieter
#passwd -e dieter
echo "dieter ALL=(ALL) ALL" >> /etc/sudoers
echo 'alias ls="ls --color=always"' >> /home/dieter/.zshrc
echo 'alias ll="ls -la --color=always"' >> /home/dieter/.zshrc
echo 'autoload -Uz promptinit' >> /home/dieter/.zshrc
echo 'promptinit' >> /home/dieter/.zshrc
echo 'prompt oliver' >> /home/dieter/.zshrc
chown dieter:users /home/dieter/.zshrc

#####################################
# init X
#cp /etc/X11/xinit/xinitrc > /home/dieter/.xinitrc
sed "s/exec.*/exec startxfce4/g" /etc/X11/xinit/xinitrc > /home/dieter/.xinitrc
chown dieter:users /home/dieter/.xinitrc
echo 'exec /usr/bin/Xorg -nolisten tcp "$@" vt$XDG_VTNR' > /home/dieter/.xserverrc
chown dieter:users /home/dieter/.xserverrc

#####################################
# download and extract tor browser for user
#cd ACI_USERHOME
#curl xxxxxxx
#tar xf tor-browser-linux64-7.5.3_en-US.tar.xz
#chown -R dieter:users tor-browser_en-US

#####################################
# set root password or disable terminal access
#echo -e "$COL_GREEN *** Disable root terminal access *** $COL_RESET"
#echo -e "$COL_GREEN *** Set root password *** $COL_RESET"
#echo "Set ROOT password:"
#passwd
passwd -l root

# set up openvpn for tunnelbear or nordvpn
#if [ "x$ACI_VPNENABLE" = "xtrue" ]
#then
cd /etc/openvpn/client
mv /aciresetnordvpn.sh ./resetnordvpn.sh
wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
sudo unzip ovpn.zip
#  sudo rm *.zip
#  cd ovpn_udp
  #sudo openvpn nz6.nordvpn.com.udp.ovpn
#  systemctl enable openvpn-client@$ACI_VPNNAME.service
#fi

#####################################
# configure dhcpd
mv /etc/dhcpd.conf /etc/dhcpd.conf.example
mv /acidhcpd.conf /etc/dhcpd.conf
systemctl enable dhcpd4



#####################################
# enable additional services
systemctl enable sshd
systemctl enable NetworkManager
systemctl enable nftables
systemctl enable docker
