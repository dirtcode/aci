
./aciinstall-config.sh

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

#ACI_FOLDER=/aci
./aciinstall-pre.sh


# change root
cp ./aciinstall-main.sh /mnt
arch-chroot /mnt ./aciinstall-main.sh

# copy essential files
cp /mnt/etc/nftables.conf /mnt/etc/nftables.conf.b
cp ./acinftables.conf /mnt/etc/nftables.conf
chmod 600 /mnt/etc/nftables.conf

# remove unnecessary files
rm /mnt/aciinstall-main.sh

./aciinstall-post.sh
