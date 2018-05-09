if [ "x$1" = "x" ]
then
  echo "No server specified."
  exit 1
fi

OVPN_FILE=/etc/openvpn/client/ovpn_udp/$1.nordvpn.com.udp.ovpn
CONF_FILE=/etc/openvpn/client/nordvpn.conf

if [ -f "$OVPN_FILE" ]
then
  echo "Enabling $1..."
else
  echo "OVPN file does not exist."
  exit 1
fi

if [ -f "/etc/openvpn/client/login.key" ]
then
  echo "Using login.key for authentication..."
else
  echo "login.key does not exist."
  exit 1
fi

#cp $OVPN_FILE $CONF_FILE
awk '"HOOKS="{gsub("auth-user-pass", "auth-user-pass login.key")};{print}' $OVPN_FILE > $CONF_FILE
systemctl restart openvpn-client@nordvpn.service

echo "Done."

