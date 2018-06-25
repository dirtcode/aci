ACI_CRYPTRANDOMDEVICE=/dev/urandom
ACI_CRYPTKEYFILE=aci_cryptkeyfile.bin


if [ "x$1" = "x-f" ]
then
  #echo "Forcing  generation.."
  ACI_OUTFILE=$2
  ACI_FORCECREATE=1
else
  ACI_OUTFILE=$1
  ACI_FORCECREATE=0
fi


if [ "x$ACI_OUTFILE" = "x" ]
then
  echo "No destination file specified."
  exit 1
fi

if [ -f "$ACI_OUTFILE" ] && [ "$ACI_FORCECREATE" = "0" ]
then
  echo "$ACI_OUTFILE exists, aborting."
  exit 2
fi



while true; do
  echo -n "Do you wish to encrypt paritions [y][n]?"
  read answer
  case $answer in
    y )
      ACI_CRYPTPART=true
      break
      ;;
    n )
      ACI_CRYPTPART=false
      break
      ;;
    * ) echo "Please answer yes or no.";;
  esac
done

#echo $ACI_CRYPTPART




echo "" > $ACI_OUTFILE
echo "loadkeys us" >> $ACI_OUTFILE
echo "timedatectl set-ntp true" >> $ACI_OUTFILE



#echo "mkdir /mnt/boot" >> $ACI_OUTFILE

if [ "x$ACI_CRYPTPART" = "xtrue" ]
then

  echo "parted -s /dev/sda mklabel gpt" >> $ACI_OUTFILE

  echo "parted -s -a optimal /dev/sda mkpart primary 0%     257MiB name 1 boot" >> $ACI_OUTFILE
  echo "mkfs.btrfs --quiet -f --label boot /dev/sda1" >> $ACI_OUTFILE

  echo "parted -s -a optimal /dev/sda mkpart primary 257MiB 100GiB name 2 aux" >> $ACI_OUTFILE

  echo "parted -s -a optimal /dev/sda mkpart primary 100GiB 130GiB name 3 root" >> $ACI_OUTFILE
  echo "cryptsetup -s 512 -i 5000 luksFormat /dev/sda3" >> $ACI_OUTFILE
  echo "cryptsetup luksOpen /dev/sda3 root" >> $ACI_OUTFILE
  echo "mkfs.f2fs -l root /dev/mapper/root" >> $ACI_OUTFILE

  echo "dd if=$ACI_CRYPTRANDOMDEVICE of=$ACI_CRYPTKEYFILE bs=1024 count=20 iflag=fullblock" >> $ACI_OUTFILE

  echo "parted -s -a optimal /dev/sda mkpart primary 130GiB 140GiB name 4 var" >> $ACI_OUTFILE
  echo "cryptsetup -s 512 -i 5000 --key-file $ACI_CRYPTKEYFILE luksFormat /dev/sda4" >> $ACI_OUTFILE
  echo "cryptsetup --key-file $ACI_CRYPTKEYFILE luksOpen /dev/sda4 var" >> $ACI_OUTFILE
  echo "mkfs.f2fs -l var /dev/mapper/var" >> $ACI_OUTFILE

  echo "parted -s -a optimal /dev/sda mkpart primary 140GiB 150GiB name 5 tmp" >> $ACI_OUTFILE
  #echo "mkfs.f2fs -l tmp /dev/sda5" >> $ACI_OUTFILE

  #echo "parted -s -a optimal /dev/sda mkpart primary 140GiB 148GiB name 6 swap" >> $ACI_OUTFILE
  #echo "echo 'swap	/dev/sda6	/dev/urandom	swap,cipher=aes-xts-plain64,size=256' >> /mnt/etc/crypttab" >> $ACI_OUTFILE

  echo "parted -s -a optimal /dev/sda mkpart primary 150GiB 100%   name 6 home" >> $ACI_OUTFILE
  echo "cryptsetup -s 512 -i 5000 --key-file $ACI_CRYPTKEYFILE luksFormat /dev/sda6" >> $ACI_OUTFILE
  echo "cryptsetup --key-file $ACI_CRYPTKEYFILE luksOpen /dev/sda6 home" >> $ACI_OUTFILE
  echo "mkfs.f2fs -l home /dev/mapper/home" >> $ACI_OUTFILE

#  echo "parted -s -a optimal /dev/sda mkpart primary 257MiB 10GiB  name 2 var" >> $ACI_OUTFILE
#  echo "parted -s -a optimal /dev/sda mkpart primary 10GiB  20GiB  name 3 tmp" >> $ACI_OUTFILE
#  echo "parted -s -a optimal /dev/sda mkpart primary 20GiB  30GiB  name 4 home" >> $ACI_OUTFILE
#  echo "parted -s -a optimal /dev/sda mkpart primary 30GiB  100%   name 5 root" >> $ACI_OUTFILE

  echo "mount /dev/mapper/root /mnt" >> $ACI_OUTFILE
  echo "mv $ACI_CRYPTKEYFILE /mnt" >> $ACI_OUTFILE
  echo "chmod 600 /mnt/$ACI_CRYPTKEYFILE" >> $ACI_OUTFILE

  echo "mkdir /mnt/{boot,var,tmp,home}" >> $ACI_OUTFILE
  echo "mount /dev/sda1 /mnt/boot" >> $ACI_OUTFILE
  #echo "mount -o noexec,nosuid /dev/sda5 /mnt/tmp" >> $ACI_OUTFILE
  echo "mount -o noexec,nosuid /dev/mapper/var /mnt/var" >> $ACI_OUTFILE
  echo "mount -o noexec,nosuid /dev/mapper/home /mnt/home" >> $ACI_OUTFILE

else
  echo "Non encrypted partitions not yet supported."
  exit 3
fi

echo "curl -o /etc/pacman.d/mirrorlist.all https://www.archlinux.org/mirrorlist/all/" >> $ACI_OUTFILE
echo "awk '/^## Australia$/ {f=1} f==0 {next} /^$/ {exit} {print substr($0, 2)}' /etc/pacman.d/mirrorlist.all > /etc/pacman.d/mirrorlist.australia" >> $ACI_OUTFILE
echo "mkdir -p /mnt/etc/pacman.d" >> $ACI_OUTFILE
echo "rankmirrors -n 4 /etc/pacman.d/mirrorlist.australia > /mnt/etc/pacman.d/mirrorlist" >> $ACI_OUTFILE
echo "cp /mnt/etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist" >> $ACI_OUTFILE

echo "pacstrap /mnt base base-devel" >> $ACI_OUTFILE
echo "genfstab -p -U /mnt > /mnt/etc/fstab" >> $ACI_OUTFILE



echo "echo '/dev/sda5 /tmp     	f2fs      	rw,nosuid,noexec,relatime,lazytime,background_gc=on,no_heap,inline_xattr,inline_data,inline_dentry,flush_merge,extent_cache,mode=adaptive,active_logs=6	0 0' >> /mnt/etc/fstab" >> $ACI_OUTFILE
echo "echo 'var  /dev/sda4 /$ACI_CRYPTKEYFILE' >> /mnt/etc/crypttab" >> $ACI_OUTFILE
echo "echo 'tmp  /dev/sda5 /dev/urandom tmp,cipher=aes-xts-plain64,size=256 ' >> /mnt/etc/crypttab" >> $ACI_OUTFILE
echo "echo 'home /dev/sda6 /$ACI_CRYPTKEYFILE ' >> /mnt/etc/crypttab" >> $ACI_OUTFILE
