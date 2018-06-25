if [ "x$1" = "x" ]
then
  echo "Need wireless adapter name as param."
  exit 1
fi

ACI_ADAPTERNAME=$1
ACI_CONFIGFILE=/etc/netctl/wireless-dhcp-home

echo "" > $ACI_CONFIGFILE
echo "Description='DHCP wireless'" >> $ACI_CONFIGFILE
echo "Interface=$ACI_ADAPTERNAME" >> $ACI_CONFIGFILE
echo "Connection=wireless" >> $ACI_CONFIGFILE
echo "Security=wpa" >> $ACI_CONFIGFILE
echo "IP=dhcp" >> $ACI_CONFIGFILE
echo "ESSID='Cataclysm733LN910'" >> $ACI_CONFIGFILE
echo "Key=''" >> $ACI_CONFIGFILE
echo "DNS=('127.0.0.1')" >> $ACI_CONFIGFILE
chmod 600 $ACI_CONFIGFILE

systemctl enable netctl-auto@$ACI_ADAPTERNAME.service # configure and enable wireless dhcp


exit 0
