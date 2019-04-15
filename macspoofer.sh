#!/bin/bash

if [ "$EUID" != "0" ];
then
	echo "This script must be run as root" 1>&2
	exit
fi

#Get ethernet interface
get_interface()
{
INTERFACE=`ip link show | awk -F: '$0 !~ "lo|vir|vbox|wl|tun|^[^0-9]" {print $2;exit}'| sed 's/ //'`
echo  "Interface = " ${INTERFACE}
}

change_originalmac()
{
	ORIGINALMAC=`ip addr show ${INTERFACE} | awk 'NR==2{print $2}' `
	echo 'Original Mac =  ' ${ORIGINALMAC}
	VENDORBYTES=`echo ${ORIGINALMAC}| cut -f 1-3 -d ":" `
	NONVENDORBYTES=`echo ${ORIGINALMAC} | cut -f 4-6 -d ":" | rev `
	NEWMAC="${VENDORBYTES}:${NONVENDORBYTES}"
	echo 'New Mac =	' ${NEWMAC}
}

set_newmac()
{
	ip link set dev ${INTERFACE} down
	ip link set dev ${INTERFACE} address ${NEWMAC}
	ip link set dev ${INTERFACE} up
}

#Check if mac address has changed
check()
{
	CHECKMASK=`ip addr show ${INTERFACE} | awk 'NR==2{print $2}'`
	if [ ${CHECKMASK} == ${NEWMAC} ];
	then
		echo "Mac address has changed"
	else
		echo "Failed"
	fi 
}

setPermanently()
{
	echo "Set new Mac Address permanently"
	cat << EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
# The loopback network interface
auto lo
iface lo inet loopback
auto ${INTERFACE}
#Your static network configuration  
iface ${INTERFACE} inet dhcp
	hwaddress ether ${NEWMAC}
EOF
	systemctl restart networking
	ip link set dev ${INTERFACE} down
	ip link set dev ${INTERFACE} up
}

get_interface
change_originalmac
set_newmac
check
setPermanently
