#!/bin/zsh
#
# AUTHOR: Lucien Zerger
# DESCRIPTION: Arch Custom Installer Prep


if [ "$EUID" -ne 0 ]
then
  echo "Please run as root."
  exit 1
fi

ACI_INSTALL_LOG_FILE=./aci-inst-prep-log.txt
ACI_ESC_SEQ="\x1b["
ACI_COL_GREEN=$ACI_ESC_SEQ"32;01m"
ACI_COL_RED=$ACI_ESC_SEQ"31;01m"
ACI_COL_RESET=$ACI_ESC_SEQ"39;49;00m"
#ACI_HOSTNAME=$1
ACI_USERNAME=dirt


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



#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# grab hostname from input
while true
do
  echo -n "Enter hostname: "
  read ACI_HOSTNAME
  if [ "x$ACI_HOSTNAME" != "x" ]
  then
    echo -n "Use '$ACI_HOSTNAME' as hostname [y][n]? "
    read answer
    case $answer in
      y) break;;
      n) ;;
      *) echo "Please answer yes or no.";;
    esac
  fi
done
echo "New hostname is '$ACI_HOSTNAME'"



#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# set keyboard layout
write_green ">>> Set Keyboard <<<"
loadkeys us
if [ $? -ne 0 ]; then; write_red_terminate "Invalid keyboard layout."; fi


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# update the system clock
write_green ">>> Enable network time synchronization <<<"
timedatectl set-ntp true
if [ $? -ne 0 ]; then; write_red_terminate "Could not set network time."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# load dm_crypt kernal module
write_green ">>> Load dm_crypt kernal module <<<"
modprobe dm_crypt
if [ $? -ne 0 ]; then; write_red_terminate "Invalid module."; fi

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
parted -s -a optimal /dev/sda mkpart primary 257MiB 100% name 2 root

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# encrypt partitions
write_green ">>> Encrypt partitions <<<"
cryptsetup -s 512 -i 5000 luksFormat /dev/sda2
if [ $? -ne 0 ]; then; write_red_terminate "Failed to encrypt root partition."; fi
cryptsetup luksOpen /dev/sda2 root
if [ $? -ne 0 ]; then; write_red_terminate "Failed to open encrypted root partition."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# format partitions
write_green ">>> Format partitions <<<"
mkfs.btrfs --quiet -f --label boot /dev/sda1
if [ $? -ne 0 ]; then; write_red_terminate "Failed to format boot partition."; fi
mkfs.f2fs -l root /dev/mapper/root
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


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# set Australian mirrors
write_green ">>> Set mirrors <<<"
curl -o /etc/pacman.d/mirrorlist.all https://www.archlinux.org/mirrorlist/all/
if [ -f "/etc/pacman.d/mirrorlist.all" ]
then
  awk '/^## Australia$/ {f=1} f==0 {next} /^$/ {exit} {print substr($0, 2)}' /etc/pacman.d/mirrorlist.all > /etc/pacman.d/mirrorlist.australia
else
  write_red_terminate "Failed to get mirrorlist."
fi
rankmirrors -n 4 /etc/pacman.d/mirrorlist.australia > /etc/pacman.d/mirrorlist
if [ $? -ne 0 ]; then; cp /etc/pacman.d/mirrorlist.australia /etc/pacman.d/mirrorlist; fi


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# install base packages
write_green ">>> Install base and dev packages <<<"
pacstrap /mnt base base-devel zsh zsh-completions grml-zsh-config
if [ $? -ne 0 ]; then; write_red_terminate "Failed to install base packages."; fi

#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# generate /etc/fstab using UUIDs
write_green ">>> Generate /etc/fstab <<<"
genfstab -p -U /mnt > /mnt/etc/fstab
if [ $? -ne 0 ]; then; write_red_terminate "Failed to generate /etc/fstab."; fi


#  __________________________________________________________________________________________________________
# [ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ▇ ▄ ▅ █ ▇ ▂ ▃ ▁ ▄ ▅ █ ▅ ▇ ]
# chroot and execute main installation
cp ./aci-inst-main.sh /mnt
arch-chroot /mnt /bin/zsh /aci-inst-main.sh $ACI_HOSTNAME $ACI_USERNAME
rm /mnt/aci-inst-main.sh
umount /mnt/boot
umount /mnt
write_green "Done.  Remove install media and restart."
