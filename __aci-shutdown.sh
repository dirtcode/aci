export ACI_PACKAGEINSTALL_DEV=no
export ACI_PACKAGEINSTALL_LAPTOP=no
export ACI_PACKAGEINSTALL_X=no
export ACI_HOSTNAME=shutdown
export ACI_USERNAME=dirt




#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# create partitions
write_green ">>> Create partitions <<<"
parted -s /dev/sda print free
while true
do
  echo -n "Is drive ready for partition creation [y][n]? "
  read answer
  case $answer in
    y )
      break
      ;;
    n )
      write_red_terminate "Drive not ready."
      ;;
    * ) echo "Please answer yes or no.";;
  esac
done
parted -s /dev/sda mklabel gpt
parted -s -a optimal /dev/sda mkpart primary 0% 257MiB name 1 boot
parted -s -a optimal /dev/sda mkpart primary 257MiB 100% name 2 lvm
#parted -s -a optimal /dev/sda mkpart primary 257MiB 48GiB name 2 root
#parted -s -a optimal /dev/sda mkpart primary 48GiB 100% name 3 home

cryptsetup -c aes-xts-plain64 -s 512 -i 5000 -h sha512 --use-random luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 lvm
pvcreate /dev/mapper/lvm
vgcreate arch /dev/mapper/lvm
lvcreate -C y -L 8G arch -n swap
lvcreate -L 48G arch -n root
lvcreate -l +100%FREE arch -n home
vgchange -ay
mkswap /dev/mapper/arch-swap
swapon /dev/mapper/arch-swap

mkfs.btrfs --quiet -f --label boot /dev/sda1
mkfs.f2fs -l root /dev/mapper/arch-root
mkfs.f2fs -l home /dev/mapper/arch-home

mount /dev/mapper/arch-root /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
mount /dev/mapper/arch-home /mnt/home

loadkeys us
timedatectl set-ntp true
curl -o /etc/pacman.d/mirrorlist.all https://www.archlinux.org/mirrorlist/all/
  awk '/^## Australia$/ {f=1} f==0 {next} /^$/ {exit} {print substr($0, 2)}' /etc/pacman.d/mirrorlist.all > /etc/pacman.d/mirrorlist.australia
cp /etc/pacman.d/mirrorlist.australia  /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel zsh zsh-completions \
  grml-zsh-config openssh openssl \
  acpi sysstat unrar wget p7zip intel-ucode \
  syslinux gptfdisk f2fs-tools btrfs-progs \
  iw wpa_supplicant wpa_actiond ifplugd \
  nftables nmap openvpn dnscrypt-proxy \
  firejail  linux-hardened sshfs encfs rsync
genfstab -p -U /mnt > /mnt/etc/fstab

arch-chroot /mnt /bin/zsh



#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# encrypt partitions
write_green ">>> Encrypt partitions <<<"
cryptsetup -c aes-xts-plain64 -s 512 -i 5000 -h sha512 luksFormat /dev/sda2
if [ $? -ne 0 ]; then; write_red_terminate "Failed to encrypt root partition with interactive passphrase."; fi
cryptsetup -s 512 -i 5000 luksFormat /dev/sda3
#mkdir /etc/keys
ACI_CRYPTKEYFILE=/sda3.key
dd if=/dev/urandom of=$ACI_CRYPTKEYFILE bs=1024 count=1 iflag=fullblock
#dd if=/dev/random of=/etc/keys/sda6.key bs=1 count=32
#chmod 400 $ACI_CRYPTKEYFILE
cryptsetup  -i 5000  luksAddKey  /dev/sda3 $ACI_CRYPTKEYFILE
if [ $? -ne 0 ]; then; write_red_terminate "Failed to encrypt home partition with key."; fi
cryptsetup luksOpen /dev/sda2 root
if [ $? -ne 0 ]; then; write_red_terminate "Failed to open encrypted root partition."; fi
cryptsetup --key-file /sda3.key luksOpen /dev/sda3 home
if [ $? -ne 0 ]; then; write_red_terminate "Failed to open encrypted home partition."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# format partitions
write_green ">>> Format partitions <<<"
mkfs.btrfs --quiet -f --label boot /dev/sda1
if [ $? -ne 0 ]; then; write_red_terminate "Failed to format boot partition."; fi
mkfs.f2fs -l root /dev/mapper/root
if [ $? -ne 0 ]; then; write_red_terminate "Failed to format root partition."; fi
mkfs.f2fs -l home /dev/mapper/home
if [ $? -ne 0 ]; then; write_red_terminate "Failed to format root partition."; fi


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# mount partitions
write_green ">>> Mount partitions <<<"
mount /dev/mapper/root /mnt
if [ $? -ne 0 ]; then; write_red_terminate "Failed to mount root partition."; fi
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
if [ $? -ne 0 ]; then; write_red_terminate "Failed to mount boot partition."; fi
mkdir -p /mnt/home
mount /dev/mapper/home /mnt/home
if [ $? -ne 0 ]; then; write_red_terminate "Failed to mount home partition."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# other
cp -v $ACI_CRYPTKEYFILE /mnt/$ACI_CRYPTKEYFILE
chmod 400 /mnt/$ACI_CRYPTKEYFILE
