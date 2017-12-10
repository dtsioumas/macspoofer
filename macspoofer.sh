#!/bin/bash

if [ "$EUID" != "0" ];
then
	echo "This script must be run as root" 1>&2
	exit
fi

#Get ethernet interface
get_interface()
{
INTERFACE=`ip link show | awk -F: '$0 !~ "lo|vir|vbox|wl|tun|^[^0-9]" {print $2;exit}'`
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
ifdown ${INTERFACE}
ip link set dev ${INTERFACE} address ${NEWMAC}
ifup ${INTERFACE}
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

get_interface
change_originalmac
set_newmac
check
