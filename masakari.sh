#!/bin/bash
#openstack masakari installation script
#usage ./masakari.sh
#


# Directories
TOP_DIR=$(cd $(dirname "$0") && pwd)
CONTROLLER_DIR="$TOP_DIR/masakari-controller"
HOSTMON_DIR="$TOP_DIR/masakari-hostmonitor"
INSTANCEMON_DIR="$TOP_DIR/masakari-instancemonitor"
PROCESSMON_DIR="$TOP_DIR/masakari-processmonitor"
LOGDIR="$TOP_DIR/log"
LOGFILE="${LOGDIR}/masakari.log"

FNAME="mdcMasakari.sh"
LOCAL_CONF="$TOP_DIR/local.conf"
TAB="	"
TABLE_TOP="+----------------------------------+-------------------------------+"
TABLE_LEFT3="| "
TABLE_RIGHT4="$TAB$TAB$TAB$TAB|"
TABLE_RIGHT3="$TAB$TAB$TAB|"
TABLE_RIGHT2="$TAB$TAB|"
TABLE_BOTTOM="+----------------------------------+-------------------------------+"



#This function outputs the console print
#Argument
#	$1 : Message
echo_console() {
	echo "`date +'%Y-%m-%d %H:%M:%S'`::${FNAME}::${HOST_NAME}::$1" 
}

#This function outputs the error print
#Argument
#	$1 : Message
echo_error () {
	echo_console "###########################################################"
	echo_console "# $1 "
	echo_console "# :-( :-( :-("
	echo_console "###########################################################"
}

# This function outputs the debug log
# Argument
#   $1 : Message
log_error () {
    log_print_level="ERROR"
    if [ ! -e ${LOGDIR} ]; then
        mkdir -p ${LOGDIR}
    fi
    
    log_print "$1" $log_print_level
}

# This function outputs the debug log
# Argument
#   $1 : Message
log_debug () {
    log_print_level="DEBUG"
    if [ ! -e ${LOGDIR} ]; then
        mkdir -p ${LOGDIR}
    fi

    if [ "${LOG_LEVEL}" == "debug" ]; then
        log_print "$1" $log_print_level
    fi
}

# This function outputs the info log
# Argument 
#   $1 : Message
log_info () {
    log_print_level="INFO"
    if [ ! -e ${LOGDIR} ]; then
        mkdir -p ${LOGDIR}
    fi

    log_print "$1" $log_print_level
}

#This function will print the entire log of masakari
#Argument
#	$1 : Message
#	$2 : Log print level
log_print () {
	echo "`date +'%Y-%m-%d %H:%M:%S'`::${FNAME}::${HOST_NAME}::$2::$1" >> $LOGFILE
}

#This function will used to print msg in both console and log file
#Argument
#	$1 : Log level
#		1 : info
#		2 : debug
#		3 : error
#	$2 : Message
print () {
	log_level=$1
	echo_console "$2"
	case $log_level in
	1)
		log_info "$2"
		;;
	2)
		log_debug "$2"
		;;
	3)
		log_error "$2"
		;;
	esac
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
	msg="config file read error. [$LOCAL_CONF]"
        echo_console "$msg"
	log_info "$msg"
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
    
    LOG_LEVEL=${LOG_LEVEL:-10}
    check_config_type 'string' LOG_LEVEL $LOG_LEVEL
    
    return 0
}

#
#
#
echo_default_value () {
	print 1 "$TABLE_TOP"
	print 1 "$TABLE_LEFT3 Host Name $TABLE_RIGHT3 $HOST_NAME $TABLE_RIGHT3"
	print 1 "$TABLE_LEFT3 Host IP $TABLE_RIGHT3 $HOST_IP $TABLE_RIGHT2"
	print 1 "$TABLE_LEFT3 CONTROLLER_IP $TABLE_RIGHT3 $CONTROLLER_IP $TABLE_RIGHT2"
	print 1 "$TABLE_LEFT3 REVISION $TABLE_RIGHT3 $REVISION $TABLE_RIGHT3"
	if [ $HOST_NAME == "controller" ]; then
		print 1 "$TABLE_LEFT3 DATABASE_NAME $TABLE_RIGHT3 vm_ha $TABLE_RIGHT3"
		print 1 "$TABLE_LEFT3 DATABASE_USERNAME $TABLE_RIGHT2 vm_ha $TABLE_RIGHT3"
		print 1 "$TABLE_LEFT3 DATABASE_PASSWORD $TABLE_RIGHT2 accl $TABLE_RIGHT4"
		print 1 "$TABLE_BOTTOM"
	elif [ $HOST_NAME == "compute" ]; then
		print 1 "$TABLE_BOTTOM"
	else
		print 1 "+--------------------------+--------------------------+"
		print 1 "+Information error         | :-(                      +"
		print 1 "+--------------------------+--------------------------+"
	fi
}
#This function build masakari monitors
#Arguments
#	$1 : Components to build
#Output
#	0 : Success
build() {
	M_COMP=$1
	#sFNAME="BUILD"
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
	#FNAME="create_masakari_database"
	echo_console "+++++++++++database bulding masakari+++++++++++"
	sudo  apt-get install expect -y
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
	echo_console "$MYSQL_CMD"
        return $MYSQL_CMD
}

#This function will clone masakari according to the revision
#Accoriding to the revision
#
mdc_masakari_clone() {
	#FNAME="mdc_masakari_clone"
	echo_console "+++++++++++clonnig masakari+++++++++++"
	cd $TOP_DIR
	git clone "https://github.com/ntt-sic/masakari.git" --branch $REVISION
	return $?
}

#This function will build the required package
#
#
#
mdc_masakari_build () {
	#FNAME="mdc_masakari_build"
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
	fi
	return 0
}

#This function will install masakari monitors
#
#
#
mdc_masakari_install () {
	#FNAME="mdc_masakari_install"
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
		sudo dpkg -i masakari-hostmonitor_1.0.0-1_all.deb
		sudo dpkg -i masakari-instancemonitor_1.0.0-1_all.deb
		sudo dpkg -i masakari-processmonitor_1.0.0-1_all.deb
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
	#FNAME="mdc_masakari_conf"
	echo_console "+++++++++++configuring masakari+++++++++++"
	if [ $HOST_NAME == "controller" ]; then
		#masakari controller configuration
		echo_console "etc/masakari-controller ->  /etc/masakari/masakari-controller.conf"
		sudo cp $TOP_DIR/etc/masakari-controller.conf.sample /etc/masakari/masakari-controller.conf -v
		sudo sed -i "s/host = <controller_ip>.*/host = $HOST_IP/g" /etc/masakari/masakari-controller.conf
		
		#masakari database setting
		echo_console "etc/masakari_database_setting.sh ->  $TOP_DIR/masakari_database_setting.sh"
		sudo cp $TOP_DIR/etc/masakari_database_setting.sh.sample $TOP_DIR/masakari_database_setting.sh -v
		sudo sed -i "s/DB_HOST=<controller ip>.*/DB_HOST=$HOST_IP/g" $TOP_DIR/masakari_database_setting.sh
		sudo chmod 0755 $TOP_DIR/masakari_database_setting.sh
		
		#masakari reserve host adding
		echo_console "etc/reserved_host_add.sh ->  $TOP_DIR/reserved_host_add.sh"
		sudo cp $TOP_DIR/etc/reserved_host_add.sh.sample $TOP_DIR/reserved_host_add.sh -v
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_add.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_add.sh
		
		#masakari reserve host delete
		echo_console "etc/reserved_host_delete.sh ->  $TOP_DIR/reserved_host_delete.sh"
		sudo cp $TOP_DIR/etc/reserved_host_delete.sh.sample $TOP_DIR/reserved_host_delete.sh -v
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_delete.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_delete.sh 
		
		#masakari reserve host list
		echo_console "etc/reserved_host_list.sh ->  $TOP_DIR/reserved_host_list.sh"
		sudo cp $TOP_DIR/etc/reserved_host_list.sh.sample $TOP_DIR/reserved_host_list.sh -v
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_list.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_list.sh
		
		#masakari reserve host update
		echo_console "etc/reserved_host_update.sh ->  $TOP_DIR/reserved_host_update.sh"
		sudo cp $TOP_DIR/etc/reserved_host_update.sh.sample $TOP_DIR/reserved_host_update.sh -v
		sudo sed -i "s/DB_HOST=<controller ip>.*/host = $HOST_IP/g" $TOP_DIR/reserved_host_update.sh
		sudo chmod 0755 $TOP_DIR/reserved_host_update.sh
	elif [ $HOST_NAME == "compute" ]; then
		#masakari hostmointor configuration
		echo_console "etc/masakari-hostmonitor.conf ->  /etc/masakari/masakari-hostmonitor.conf"
		sudo cp $TOP_DIR/etc/masakari-hostmonitor.conf.sample /etc/masakari/masakari-hostmonitor.conf -v
		sudo sed -i 's/RM_URL="http://<controller ip>:15868".*/RM_URL="http://$CONTROLLER_IP:15868"/g' /etc/masakari/masakari-controller.conf
		
		#masakari instancemonitor configuration
		echo_console "etc/masakari-instancemonitor.conf ->  /etc/masakari/masakari-instancemonitor.conf"
		sudo cp $TOP_DIR/etc/masakari-instancemonitor.conf.sample /etc/masakari/masakari-instancemonitor.conf -v
		sudo sed -i 's/url = http://<controller ip>:15868".*/url = http://$CONTROLLER_IP:15868/g' /etc/masakari/masakari-instancemonitor.conf
		
		#masakari processmonitor configuration
		echo_console "etc/masakari-processmonitor.conf ->  /etc/masakari/masakari-processmonitor.conf"
		sudo cp $TOP_DIR/etc/masakari-processmonitor.conf.sample /etc/masakari/masakari-processmonitor.conf -v
		sudo sed -i 's/RESOURCE_MANAGER_URL="http://<controller ip>:15868".*/RESOURCE_MANAGER_URL="http://$CONTROLLER_IP:15868"/g' /etc/masakari/masakari-processmonitor.conf
		
		#masakari process list
		echo_console "etc/proc.list ->  /etc/masakari/proc.list"
		sudo cp $TOP_DIR/etc/proc.list.sample /etc/masakari/proc.list
		
		#pacemaker configuration
		echo_console "etc/corosync.conf ->  /etc/corosync/corosync.conf"
		sudo cp $TOP_DIR/etc/corosync.conf.sample /etc/corosync/corosync.conf -v
		sudo sed -i 's/bindnetaddr: <bind_ip>".*/RESOURCE_MANAGER_URL="http://$CONTROLLER_IP:15868"/g' /etc/corosync/corosync.conf
	else
		return -1
	fi
	return 0
}

#
#
#
mdc_masakari_database_populate () {
	#FNAME="mdc_masakari_database_populate"
	echo_console "+++++++++++populating masakari database+++++++++++"
	cd $TOP_DIR
	sudo ./masakari_database_setting.sh
	return $?
}

#
#
#
mdc_masakari_start () {
	#FNAME="mdc_masakari_start"
	echo_console "+++++++++++starting masakari $HOST_NAME services+++++++++++"
	if [ $HOST_NAME == "controller" ]; then
		sudo service masakari-controller restart
	elif [ $HOST_NAME == "compute" ]; then
		sudo service corosync restart
		sudo service pacemaker restart
		sudo service masakari-instancemonitor restart
		sudo service masakari-processmonitor restart
		sudo service masakari-hostmonitor restart
	else
		return 1
	fi
	return 0
}

#
#
#
mdc_masakari_status () {
	#FNAME="mdc_masakari_status"
	echo_console "+++++++++++status of masakari $HOST_NAME services+++++++++++"
	if [ $HOST_NAME == "controller" ]; then
		sudo service masakari-controller status
	elif [ $HOST_NAME == "compute" ]; then
		sudo service corosync status
		sudo service pacemaker status
		sudo service masakari-instancemonitor status
		sudo service masakari-processmonitor status
		sudo service masakari-hostmonitor status
		sudo crm status
	else
		return 1
	fi
	return 0
}
#main routine
result=0
FNAME="masakari.sh"
set_conf_value

print 1 "###########################################################"
print 1 "####################masakari.sh starts#####################"
print 1 "###########################################################"

#mdc_masakari_clone
result=$?
if [ $result -ne 0 ]; then
	echo_error "error while cloning."
	log_error "error while cloning."
	exit 1
fi

#mdc_masakari_build
result=$?
if [ $result -ne 0 ]; then
	echo_error "error while bulding."
	log_error "error while bulding."
	exit 1
fi

#mdc_masakari_install
result=$?
if [ $result -ne 0 ]; then
	echo_error "error while installing."
	log_error "error while installing."
	exit 1
fi

#mdc_masakari_conf
result=$?
if [ $result -ne 0 ]; then
	echo_error "error while seting configuration file."
	log_error "error while seting configuration file."
	exit 1
fi

if [ $HOST_NAME == "controller" ]; then
	mdc_masakari_database_populate
	result=$?
	if [ $result -ne 0 ]; then
		echo_error "error while populating database."
		log_error "error while populating database."
		#log_error "$result"
		exit 1
	fi
fi

#mdc_masakari_start
result=$?
if [ $result -ne 0 ]; then
	echo_error "error while starting service."
	log_error "error while starting service."
	exit 1
fi

#mdc_masakari_status
#result=$?
#if [ $result -ne 0 ]; then
#	echo_error "error while checking status."
#	exit 1
#fi


print 1 "################################################################"
print 1 "#masakari installation in $HOST_NAME				#"  
print 1 "#is success         :-)  :-) :-)				#"
print 1 "################################################################"

echo_default_value
#end
