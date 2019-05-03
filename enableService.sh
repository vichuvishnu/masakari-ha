#!/bin/bash
# This script is used to create Masakari services
# Usage:- 	sudo -s
#		./enableService.sh {controller|compute}


# Directories
TOP_DIR=$(cd $(dirname "$0") && pwd)
ETC_DIR="$TOP_DIR/etc"
SERVICE_DIR="/etc/systemd/system"
INIT_DIR="/etc/init.d"

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
		# Init Script
		msg=`sudo cp $ETC_DIR/initscript.sh.sample $INIT_DIR/masakari-api -v`
		sudo chmod 0755 $INIT_DIR/masakari-api
		sudo sed -i "s/<PROGRAM_NAME>.*/masakari-api/g" $INIT_DIR/masakari-api
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-api/g" $INIT_DIR/masakari-api
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/initscript.sh.sample $INIT_DIR/masakari-engine -v`
		sudo chmod 0755 $INIT_DIR/masakari-engine
		sudo sed -i "s/<PROGRAM_NAME>.*/masakari-engine/g" $INIT_DIR/masakari-engine
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-engine/g" $INIT_DIR/masakari-engine
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/initscript.sh.sample $INIT_DIR/masakari-wsgi -v`
		sudo chmod 0755 $INIT_DIR/masakari-wsgi
		sudo sed -i "s/<PROGRAM_NAME>.*/masakari-wsgi/g" $INIT_DIR/masakari-wsgi
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-wsgi/g" $INIT_DIR/masakari-wsgi
		echo_console "$msg"
		
		# Service Script
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $SERVICE_DIR/masakari-api.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Api/g" $SERVICE_DIR/masakari-api.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-api/g" $SERVICE_DIR/masakari-api.service
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $SERVICE_DIR/masakari-engine.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Engine/g" $SERVICE_DIR/masakari-engine.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-engine/g" $SERVICE_DIR/masakari-engine.service
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $SERVICE_DIR/masakari-wsgi.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Wsgi/g" $SERVICE_DIR/masakari-wsgi.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-wsgi/g" $SERVICE_DIR/masakari-wsgi.service
		echo_console "$msg"
		;;
	1)
		# Init Script
		msg=`sudo cp $ETC_DIR/initscript.sh.sample $INIT_DIR/masakari-hostmonitor -v`
		sudo 0755 $INIT_DIR/masakari-hostmonitor
		sudo sed -i "s/<PROGRAM_NAME>.*/masakari-hostmonitor/g" $INIT_DIR/masakari-hostmonitor
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-hostmonitor/g" $INIT_DIR/masakari-hostmonitor
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/initscript.sh.sample $INIT_DIR/masakari-instancemonitor -v`
		sudo 0755 $INIT_DIR/masakari-instancemonitor
		sudo sed -i "s/<PROGRAM_NAME>.*/masakari-instancemonitor/g" $INIT_DIR/masakari-instancemonitor
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-instancemonitor/g" $INIT_DIR/masakari-instancemonitor
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/initscript.sh.sample $INIT_DIR/masakari-processmonitor -v`
		sudo 0755 $INIT_DIR/masakari-processmonitor
		sudo sed -i "s/<PROGRAM_NAME>.*/masakari-processmonitor/g" $INIT_DIR/masakari-processmonitor
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-processmonitor/g" $INIT_DIR/masakari-processmonitor
		echo_console "$msg"
		
		# Service Script
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $SERVICE_DIR/masakari-hostmonitor.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Hostmonitor/g" $SERVICE_DIR/masakari-hostmonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-hostmonitor/g" $SERVICE_DIR/masakari-hostmonitor.service
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $SERVICE_DIR/masakari-instancemonitor -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Instancemonitor/g" $SERVICE_DIR/masakari-instancemonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-instancemonitor/g" $SERVICE_DIR/masakari-instancemonitor.service
		echo_console "$msg"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.sample $SERVICE_DIR/masakari-processmonitor.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Processmonitor/g" $SERVICE_DIR/masakari-processmonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-processmonitor/g" $SERVICE_DIR/masakari-processmonitor.service
		echo_console "$msg"
		;;
	esac
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
