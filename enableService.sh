#!/bin/bash
# This script is used to create Masakari services
# Usage:- 	sudo -s
#		./enableService.sh {controller|compute}

# Directories
TOP_DIR=$(cd $(dirname "$0") && pwd)
SERVICE_DIR="/etc/systemd/system"
LIB_SERVICE_DIR="/lib/systemd/system"

# Color
RED=`tput setaf 1`
GREEN=`tput setaf 2`
CYAN=`tput setaf 6`
RESET=`tput sgr0`

# Macros
HOST_NAME="$1"
FNAME="enableservice.sh"
who_ami=`whoami`

#This function outputs the console print
#Argument
#	$1 : Message
echo_console() {
	#echo "`date +'%Y-%m-%d %H:%M:%S'`::${FNAME}::${HOST_NAME}::$1" 
	echo "$HOST_NAME:$1"
}

#
#main
if [ "$who_ami" != "root" ]; then echo_console "${RED} Go to root user by sudo -s ${RESET}" ; exit 1 ;fi
echo_console "${CYAN}++--  Masakari-$HOST_NAME Servies Setting up${RESET}"
if [ "$HOST_NAME" == "controller" ]; then
	SERVICES=(masakari-api masakari-engine masakari-wsgi)
	DESCRIPTION=(Masakari_Api Masakari_Engine Masakari_Wsgi)
elif [ "$HOST_NAME" == "compute" ]; then
	SERVICES=(masakari-hostmonitor masakari-instancemonitor masakari-processmonitor)
	DESCRIPTION=(Masakari_Hostmonitor Masakari_Instancemonitor Masakari_Processmonitor)
else
	HOST_NAME="UNKOWN"
	echo_console "${RED}Usage:- sudo -s
	      ./enableService.sh {controller|compute}${RESET}"
	exit 1
fi

size=${#SERVICES[@]}
n=0
while [ $n -lt $size ]
do
	LIB_SERVICE_FILE="$LIB_SERVICE_DIR/${SERVICES[$n]}.service"
	echo_console "++--  creating ${SERVICES[$n]}.service in $LIB_SERVICE_FILE"
	if [ ! -e ${LIB_SERVICE_FILE} ]; then touch $LIB_SERVICE_FILE ; fi
	echo "[Unit]
Description=${DESCRIPTION[$n]}

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/${SERVICES[$n]}

[Install]
WantedBy=multi-user.target" > $LIB_SERVICE_FILE
	sudo ln -s $LIB_SERVICE_DIR/${SERVICES[$n]}.service $SERVICE_DIR -v
	echo_console "${CYAN}++--  ln -s $LIB_SERVICE_DIR/${SERVICES[$n]}.service $SERVICE_DIR${RESET}"
	n=` expr $n + 1 `
done
sudo systemctl daemon-reload
x=0 ; y=`tput cols` ; while [ $x -lt $y ]; do echo -n "-"; x=` expr $x + 1 `;done
echo "${GREEN}Masakari-$HOST_NAME Servies Setting up Success :-) :-) :-) ${RESET}"
#end
