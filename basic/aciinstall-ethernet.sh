if [ "x$1" = "x" ]
then
  echo "Need ethernet adapter name as param."
  exit 1
fi

ACI_ADAPTERNAME=$1
ACI_CONFIGFILE=/etc/netctl/ethernet-dhcp-home

echo "" > $ACI_CONFIGFILE
echo "Description='DHCP ethernet'" >> $ACI_CONFIGFILE
echo "Interface=$ACI_ADAPTERNAME" >> $ACI_CONFIGFILE
echo "Connection=ethernet" >> $ACI_CONFIGFILE
echo "IP=dhcp" >> $ACI_CONFIGFILE
echo "#DNS=('127.0.0.1')" >> $ACI_CONFIGFILE
chmod 600 $ACI_CONFIGFILE

systemctl enable netctl-ifplugd@$ACI_ADAPTERNAME.service # configure and enable ethernet dhcp

exit 0
