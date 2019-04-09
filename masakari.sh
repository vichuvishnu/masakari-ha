#!/bin/bash
#openstack masakari installation script
#usage ./masakari.sh
#
#
#
TOP_DIR=$(cd $(dirname "$0") && pwd)
MASAKARI_DIR="$TOP_DIR/masakari"
FNAME="masakari.sh"
LOCAL_CONF="$TOP_DIR/local.conf"



#This function outputs the console print
#Argument
#	$1 : Message
echo_console() {
	echo "`date +'%Y-%m-%d %H:%M:%S'`::${FNAME} ::  $1" 
}

# Check the value is correct type
# Argument
#   $1: Type
#   $2: Parameter Name
#   $3: Value
# Return
#   0: The value is correct type
#   1: The value is not correct type
check_config_type() {
    expected_type=$1
    parameter_name=$2
    value=$3

    ret=0
    case $expected_type in
        int)
            expr $value + 1 > /dev/null 2>&1
            if [ $? -ge 2 ]; then ret=1; fi
            ;;
        string)
            if [ -z $value ] ; then ret=1; fi
            ;;
        *)
            ret=1
            ;;
    esac

    if [ $ret -eq 1 ] ; then
        echo_console "config file parameter error. [${LOCAL_CONF}:${parameter_name}]"
        exit 1
    fi

    echo_console "config file parameter : ${parameter_name}=${value}"
    return 0
}

# This function reads the configuration file and set the value.
# If invalid value is set, return 1.
# Return value
#   0 : Setting completion
#   1 : Reading failure of the configuration or invalid setting value
set_conf_value () {
    # Read the configuration file
    source $LOCAL_CONF > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_info "config file read error. [$LOCAL_CONF]"
        return 1
    fi
    CONTROLLER_IP=${CONTROLLER_IP:-""}
    check_config_type 'string' CONTROLLER_IP $CONTROLLER_IP

    HOST_IP=${HOST_IP:-""}
    check_config_type 'string' HOST_IP $HOST_IP
    
    HOST_NAME=${HOST_NAME:-""}
    check_config_type 'string' HOST_NAME $HOST_NAME
    
    REVISION=${REVISION:-""}
    check_config_type 'string' REVISION $REVISION
    return 0
}

#
#
#
echo_default_value () {
	echo_console "+--------------------------+--------------------------+"
	echo_console "| Host Name                | $HOST_NAME               |"
	echo_console "| HOST_IP                  | $HOSY_IP                 |"
	echo_console "| CONTROLLER_IP            | $CONTROLLER_IP           |"
	echo_console "| REVISION                 | $REVISION                |"
	if [ $HOST_NAME == "controller" ]; then
		echo_console "| DATABASE_NAME            | vm_ha                    |"
		echo_console "| DATABASE_USERNAME        | vm_ha                    |"
		echo_console "| DATABASE_PASSWORD        | accl                     |"
		echo_console "+--------------------------+--------------------------+"
	elif [ $HOST_NAME == "compute" ]; then
		echo_console "+--------------------------+--------------------------+"
	else
		echo_console "+--------------------------+--------------------------+"
		echo_console "+Information error         | :-(                      +"
		echo_console "+--------------------------+--------------------------+"
	fi
}
#This function build masakari monitors
#Arguments
#	$1 : Components to build
#Output
#	0 : Success
build() {
	M_COMP=$1
	FNAME="BUILD"
	BULD_PATH="$MASAKARI_DIR/$M_COMP"
	echo_console "+++++++++++bulding $M_COMP+++++++++++"
	cd $BULD_PATH
	sudo ./debian/rules binary
	return $?
}

#This function creates the masakari database
#
#
#
create_masakari_database() {
	FNAME="create_masakari_database"
	echo_console "+++++++++++databse bulding masakari+++++++++++"
	MYSQL_CMD=$(expect -c "
        set timeout 3
        spawn mysql
        expect \")]>\"
        send \"CREATE DATABASE vm_ha;\r\"
        expect \")]>\"
        send \"GRANT ALL PRIVILEGES ON vm_ha.* TO 'vm_ha'@'localhost' IDENTIFIED BY 'accl';\r\"
        expect \")]>\"
        send \"GRANT ALL PRIVILEGES ON vm_ha.* TO 'vm_ha'@'%' IDENTIFIED BY 'accl';\r\"
        expect \")]>\"
        send \"exit\r\"
        ")
        return $MYSQL_CMD
}

#This function will clone masakari according to the revision
#Accoriding to the revision
#
mdc_masakari_clone() {
	FNAME="mdc_masakari_clone"
	echo_console "+++++++++++clonnig masakari+++++++++++"
	cd $TOP_DIR
	git clone "https://github.com/ntt-sic/masakari.git" --branch $REVISION
	return $?
}

#This function will build the required package
#
#
#
mdc_masakari_build() {
	FNAME="mdc_masakari_build"
	echo_console "+++++++++++bulding masakari+++++++++++"
	sudo apt-get install python-daemon dpkg-dev debhelper -y
	sudo useradd -s /bin/bash -d /home/openstack -m openstack
	echo "openstack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/openstack
	if [ $HOST_NAME == "controller" ]; then
		build "masakari-controller"
	elif [ $HOST_NAME == "compute" ]; then
		build "masakari-hostmonitor"
		build "masakari-instancemonitor"
		build "masakari-processmonitor"
	else
		return 1
	return 0
}

#This function will install masakari monitors
#
#
#
mdc_masakari_install () {
	FNAME="mdc_masakari_install"
	echo_console "+++++++++++installing masakari+++++++++++"
	result=0
	sudo apt-get install build-essential python-dev libmysqlclient-dev libffi-dev libssl-dev python-pip -y
	sudo pip install -U pip
	if [ $HOST_NAME == "controller" ]; then
		cd $MASAKARI_DIR/masakari-controller
		sudo pip install -r requirements.txt
		create_masakari_database
		cd $MASAKARI_DIR
		sudo dpkg -i masakari-controller_1.0.0-1_all.deb
	elif [ $HOST_NAME == "compute" ]; then
		sudo apt-get install corosync pacemaker -y
		sudo apt install crm114 -y
		sudo apt install crmsh -y
	else
		return -1
	fi
	return 0	
}

#
#
#
#
mdc_masakari_conf () {
	FNAME="mdc_masakari_conf"
	echo_console "+++++++++++configuring masakari+++++++++++"
	if [ $HOST_NAME == "controller" ]; then
		#masakari controller configuration
		echo_console "etc/masakari-controller ->  /etc/masakari/masakari-controller.conf"
		sudo mv $TOP_DIR/etc/masakari-controller.conf.sample /etc/masakari/masakari-controller.conf
		sudo sed -i "s/host = <controller_ip>.*/host = $HOST_IP/g" /etc/masakari/masakari-controller.conf
		
		#masakari database setting
		echo_console "etc/masakari_database_setting.sh ->  $TOP_DIR/masakari_database_setting.sh"
		sudo mv $TOP_DIR/etc/masakari_databse_setting.sh.sample $TOP_DIR/masakari_databse_setting.sh
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/masakari_databse_setting.sh
		sudo chmod 0755 $TOP_DIR/masakari_databse_setting.sh
		
		#masakari reserve host adding
		echo_console "etc/reserved_host_add.sh ->  $TOP_DIR/reserved_host_add.sh"
		sudo mv $TOP_DIR/etc/reserved_host_add.sh.sample $TOP_DIR
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_add.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_add.sh
		
		#masakari reserve host delete
		echo_console "etc/reserved_host_delete.sh ->  $TOP_DIR/reserved_host_delete.sh"
		sudo mv $TOP_DIR/etc/reserved_host_delete.sh.sample $TOP_DIR
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_delete.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_delete.sh
		
		#masakari reserve host list
		echo_console "etc/reserved_host_list.sh ->  $TOP_DIR/reserved_host_list.sh"
		sudo mv $TOP_DIR/etc/reserved_host_list.sh.sample $TOP_DIR
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_list.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_list.sh
		
		#masakari reserve host update
		echo_console "etc/reserved_host_update.sh ->  $TOP_DIR/reserved_host_update.sh"
		sudo mv $TOP_DIR/etc/reserved_host_update.sh.sample $TOP_DIR
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_update.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_update.sh
	elif [ $HOST_NAME == "compute" ]; then
		#masakari hostmointor configuration
		echo_console "etc/masakari-hostmonitor.conf ->  /etc/masakari/masakari-hostmonitor.conf"
		sudo mv $TOP_DIR/etc/masakari-hostmonitor.conf.sample /etc/masakari/masakari-hostmonitor.conf
		sudo sed -i 's/RM_URL="http://<controller ip>:15868".*/RM_URL="http://$CONTROLLER_IP:15868"/g' /etc/masakari/masakari-controller.conf
		
		#masakari instancemonitor configuration
		echo_console "etc/masakari-instancemonitor.conf ->  /etc/masakari/masakari-instancemonitor.conf"
		sudo mv $TOP_DIR/etc/masakari-instancemonitor.conf.sample /etc/masakari/masakari-instancemonitor.conf
		sudo sed -i 's/url = http://<controller ip>:15868".*/url = http://$CONTROLLER_IP:15868/g' /etc/masakari/masakari-instancemonitor.conf
		
		#masakari processmonitor configuration
		echo_console "etc/masakari-processmonitor.conf ->  /etc/masakari/masakari-processmonitor.conf"
		sudo mv $TOP_DIR/etc/masakari-processmonitor.conf.sample /etc/masakari/masakari-processmonitor.conf
		sudo sed -i 's/RESOURCE_MANAGER_URL="http://<controller ip>:15868".*/RESOURCE_MANAGER_URL="http://$CONTROLLER_IP:15868"/g' /etc/masakari/masakari-processmonitor.conf
		
		#masakari process list
		echo_console "etc/proc.list ->  /etc/masakari/proc.list"
		sudo mv $TOP_DIR/etc/proc.list.sample /etc/masakari/proc.list
	else
		return -1
	if
	return 0
}


#main routine

FNAME="masakari.sh"

echo_console "###########################################################"
echo_console "####################masakari.sh starts#####################"
echo_console "###########################################################"

set_conf_value

mdc_masakari_clone
mdc_masakari_build
mdc_masakari_install
mdc_masakari_conf

echo_console "###########################################################"
echo_console "#            masakari installation in controller          #"  
echo_console "#            is success         :-)  :-) :-)              #"
echo_console "###########################################################"

echo_default_value
#end
