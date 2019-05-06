#!/bin/bash
# This script is used to create Masakari services
# Usage:- 	sudo -s
#		./enableService.sh {controller|compute}


# Directories
TOP_DIR=$(cd $(dirname "$0") && pwd)
ETC_DIR="$TOP_DIR/etc"
SERVICE_DIR="/etc/systemd/system"
LIB_SERVICE_DIR="/lib/systemd/system"

# Color
RED=`tput setaf 1`
GREEN=`tput setaf 2`
CYAN=`tput setaf 6`
RESET=`tput sgr0`

# Macros
HOST_NAME=`hostname`
FNAME="enableservice.sh"

#This function outputs the console print
#Argument
#	$1 : Message
echo_console() {
	echo "`date +'%Y-%m-%d %H:%M:%S'`::${FNAME}::${HOST_NAME}::$1" 
}

#This function will copy the masakari services
#Argument
#	$1 : 0 : controller
#	   : 1 : compute
copy_services() {
	choice=$1
	echo_console "${CYAN}++++++++++++++++++++Copying The Services Started++++++++++++++++++++${RESET}"
	case $choice in
	0)
		# Service Script
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $LIB_SERVICE_DIR/masakari-api.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Api/g" $LIB_SERVICE_DIR/masakari-api.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-api/g" $LIB_SERVICE_DIR/masakari-api.service
		echo_console "$msg"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-api.service $SERVICE_DIR -v`
		echo_console "$msg"
		msg=`sudo systemctl enable masakari-api.service`
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $LIB_SERVICE_DIR/masakari-engine.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Engine/g" $LIB_SERVICE_DIR/masakari-engine.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-engine/g" $LIB_SERVICE_DIR/masakari-engine.service
		echo_console "$msg"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-engine.service $SERVICE_DIR -v`
		echo_console "$msg"
		msg=`sudo systemctl enable masakari-engine.service`
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $LIB_SERVICE_DIR/masakari-wsgi.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Wsgi/g" $LIB_SERVICE_DIR/masakari-wsgi.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-wsgi/g" $LIB_SERVICE_DIR/masakari-wsgi.service
		echo_console "$msg"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-wsgi.service $SERVICE_DIR -v`
		echo_console "$msg"
		msg=`sudo systemctl enable masakari-wsgi.service`
		echo_console "$msg"
		;;
	1)
		# Service Script
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $LIB_SERVICE_DIR/masakari-hostmonitor.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Hostmonitor/g" $LIB_SERVICE_DIR/masakari-hostmonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-hostmonitor/g" $LIB_SERVICE_DIR/masakari-hostmonitor.service
		echo_console "$msg"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-hostmonitor.service $SERVICE_DIR -v`
		echo_console "$msg"
		msg=`sudo systemctl enable masakari-hostmonitor.service`
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $LIB_SERVICE_DIR/masakari-instancemonitor -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Instancemonitor/g" $LIB_SERVICE_DIR/masakari-instancemonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-instancemonitor/g" $LIB_SERVICE_DIR/masakari-instancemonitor.service
		echo_console "$msg"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-instancemonitor.service $SERVICE_DIR -v`
		echo_console "$msg"
		msg=`sudo systemctl enable masakari-instancemonitor.service`
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $LIB_SERVICE_DIR/masakari-processmonitor.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Processmonitor/g" $LIB_SERVICE_DIR/masakari-processmonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-processmonitor/g" $LIB_SERVICE_DIR/masakari-processmonitor.service
		echo_console "$msg"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-processmonitor.service $LIB_SERVICE_DIR -v`
		echo_console "$msg"
		msg=`sudo systemctl enable masakari-processmonitor.service`
		echo_console "$msg"
		;;
	esac
	sudo systemctl daemon-reload
	echo_console "${CYAN}++++++++++++++++++++Copying The Services Ends++++++++++++++++++++${RESET}"
}

# main

echo_console "${CYAN}Masakari-$HOST_NAME Servies Setting up${RESET}"
if [ "$1" == "controller" ] ; then
	copy_services 0
elif [ "$1" == "compute" ]; then
	copy_services 1
else 
	echo_console "${RED}Usage: $0 {controller|compute}${RESET}"
	exit 1
fi
echo_console "${GREEN}Masakari-$HOST_NAME Servies Setting up Success :-) :-) :-) ${RESET}"

