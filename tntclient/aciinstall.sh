
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

./aciinstall-pre.sh

# change root
cp ./aciinstall-main.sh /mnt
arch-chroot /mnt ./aciinstall-main.sh
rm /mnt/aciinstall-main.sh

./aciinstall-post.sh
