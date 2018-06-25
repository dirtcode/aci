

# ====================================================================
# set keyboard layout
loadkeys us

# ====================================================================
# update the system clock
timedatectl set-ntp true

# ====================================================================
# create partitions
parted -s /dev/sda mklabel gpt
parted -s -a optimal /dev/sda mkpart primary 0% 257MiB name 1 boot
parted -s -a optimal /dev/sda mkpart primary 257MiB 100% name 2 root


# ====================================================================
# format partitions
#mkfs.ext4 -q -L boot /dev/sda1
mkfs.btrfs --quiet -f --label boot /dev/sda1
mkfs.ext4 -q -L root /dev/sda2

# ====================================================================
# mount partitions
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# set mirrors
curl -o /etc/pacman.d/mirrorlist.all https://www.archlinux.org/mirrorlist/all/
awk '/^## Australia$/ {f=1} f==0 {next} /^$/ {exit} {print substr($0, 2)}' /etc/pacman.d/mirrorlist.all > /etc/pacman.d/mirrorlist.australia
mkdir -p /mnt/etc/pacman.d
rankmirrors -n 4 /etc/pacman.d/mirrorlist.australia > /mnt/etc/pacman.d/mirrorlist
cp /mnt/etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist

# install base packages
pacstrap /mnt base base-devel

# generate /etc/fstab using UUIDs
genfstab -p -U /mnt > /mnt/etc/fstab

