#!/bin/bash
#openstack masakari uninstallation script
#usage ./uninstallMasakari.sh
#
TOP_DIR=$(cd $(dirname "$0") && pwd)
FNAME="uninstallMasakari.sh"
LOCAL_CONF="$TOP_DIR/local.conf"

#This function outputs the console print
#Argument
#	$1 : Message
echo_console() {
	echo "`date +'%Y-%m-%d %H:%M:%S'`::${FNAME}::$1" 
}

mdc_drop_database() {
	echo_console "Dropping masakari database"
	sudo  apt-get install expect -y
	MYSQL_CMD=$(expect -c "
        set timeout 3
        spawn mysql
        expect \")]>\"
        send \"DROP DATABASE vm_ha;\r\"
        expect \")]>\"
        send \"exit\r\"
         ")
	echo_console "$MYSQL_CMD"
	return 0
}
mdc_stop_masakariServices() {
	echo_console "stopping masakari $HOST_NAME services"
	if [ "$HOST_NAME" == "controller" ]; then
		sudo service masakari-controller stop
	elif [ "$HOST_NAME" == "compute" ]; then
		sudo service masakari-hostmonitor stop
		sudo service masakari-instancemonitor stop
		sudo service masakari-processmonitor stop
		sudo service pacemaker stop
		sudo service corosync stop
	fi
}
mdc_uninstall_masakariServices() {
	cd $TOP_DIR
	echo_console "Unstalling masakari $HOST_NAME services"
	if [ "$HOST_NAME" == "controller" ]; then
		echo_console "removing masakari-controller"
		sudo dpkg --purge masakari-controller
	elif [ "$HOST_NAME" == "compute" ]; then
		echo_console "removing masakari-hostmonitor"
		sudo dpkg --purge masakari-hostmonitor 
		echo_console "removing masakari-instancemonitor"
		sudo dpkg --purge masakari-instancemonitor
		echo_console "removing masakari-processmonitor"
		sudo dpkg --purge masakari-processmonitor
		echo_console "removing pacemaker"
		echo_console "removing corosync"
		sudo apt-get remove --purge corosync pacemaker -y
		sudo apt-get clean -y
	fi
}
mdc_remove_masakariconif_files() {
	echo_console "Removing masakari $HOST_NAME configuration files"
	if [ "$HOST_NAME" == "controller" ];then
		sudo rm masakari-controller_1.0.0-1_all.deb masakari_database_setting.sh reserved_host_add.sh reserved_host_delete.sh reserved_host_list.sh reserved_host_update.sh
		sudo rm -r /etc/masakari
		sudo rm /usr/local/bin/mdc-masakari
		sudo rm -r /etc/masakari
	elif [ "$HOST_NAME" == "compute" ]; then
		sudo rm -r /etc/corosync
		sudo rm /etc/default/corosync
		sudo rm -r /etc/masakari
		sudo rm masakari-hostmonitor_1.0.0-1_all.deb masakari-instancemonitor_1.0.0-1_all.deb masakari-processmonitor_1.0.0-1_all.deb
	fi
}

# main 
echo_console "Masakari removal begining..."
source $LOCAL_CONF > /dev/null 2>&1
HOST_NAME=${HOST_NAME:-""}
mdc_stop_masakariServices
mdc_uninstall_masakariServices
if [ "$HOST_NAME" == "controller" ];then
	mdc_drop_database
	if [ $? -ne 0 ]; then echo_console "Error while droping database"; fi
fi
mdc_remove_masakariconif_files
#end





