#!/bin/bash
#openstack masakari installation script
#usage ./masakari.sh
#


# Directories
TOP_DIR=$(cd $(dirname "$0") && pwd)
MASAKARI_DIR="$TOP_DIR/masakari"
MASAKARIMONITOR_DIR="$TOP_DIR/masakari-monitors"
ETC_DIR="$TOP_DIR/etc"
LOGDIR="$TOP_DIR/log"
LOGFILE="${LOGDIR}/masakari.log"
LOCAL_CONF="$TOP_DIR/local.conf"
MASAKARI_CONF="/etc/masakari"
MASAKARIMONITOR_CONF="/etc/masakarimonitors"
LIB_SERVICE_DIR="/lib/systemd/system"
SERVICE_DIR="/etc/systemd/system"


# Color
RED=`tput setaf 1`
GREEN=`tput setaf 2`
CYAN=`tput setaf 6`
RESET=`tput sgr0`

# Macros
FNAME="masakari.sh"


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
	x=0
	y=`tput cols`
	while [ $x -lt $y ]; do echo -n "-"; x=` expr $x + 1 `;done
	echo "${RED}# $1 ${RESET}"
	echo "${RED}# :-( :-( :-(${RESET}"
}

#This function outputs the success print
#
echo_success() {
	x=0
	y=`tput cols`
	while [ $x -lt $y ]; do echo -n "-"; x=` expr $x + 1 `;done
	#echo "${GREEN}                 ;;         ;;       ;;            ,''.          ;;                          "
	#echo ",,               ;;         ;;';; ;;';;           :              ;;  ''            ;;  ..  ''      "
	#echo ";;''; ;'';;  ;;'';;  ,;';;  ;;  ;;   ;; ,;';;     '..   ,;';;    ;;''    ,;';;     ;;''  . ;;     "          
	#echo ";;  ;;   ;; ;;   ;; ;       ;;       ;; ;    ;   ,,  ': ;    ;   ;;,,    ;    ;    ;;      ;;      "
	#echo ";;  ;;   ;;  ;;..;;  ';.;;  ;;       ;; ';.;; '.   ..'  ';.;; '. ;;  ,,  ';.;; '.  ;;      ;;         "
	echo "${GREEN}mdcMasakari"
	echo "Success :-)${RESET}"
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
        return 1
    fi

    echo_console "config file parameter : ${parameter_name}=${value}"
    return 0
}

# This function reads the configuration file and set the value.
# If invalid value is set, return 1.
# Return value
#   0 : Setting completion
#   1 : Reading failure of the configuration or invalid setting value
mdc_set_conf_value () {
    # Read the configuration file
    source $LOCAL_CONF > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	msg="config file read error. [$LOCAL_CONF]"
        echo_console "$msg"
        return 1
    fi
    
    CONTROLLER_IP=${CONTROLLER_IP:-""}
    check_config_type 'string' CONTROLLER_IP $CONTROLLER_IP
    result=$?

    my_ip=${my_ip:-""}
    check_config_type 'string' my_ip $my_ip ; result=` expr $result + $? `
        
    if [ "$my_ip" == "$CONTROLLER_IP" ]; then
	HOST_NAME="controller"
    else
	HOST_NAME="compute"
    fi
    
    LOG_LEVEL=${LOG_LEVEL:-"info"}
    check_config_type 'string' LOG_LEVEL $LOG_LEVEL ; result=` expr $result + $? `
    if [ "$LOG_LEVEL" == "debug" ]; then
	debug="true"
    else
	debug="false"
    fi
    
    LOG_DIR=${LOG_DIR:-"var/log/masakari"}
    check_config_type 'string' LOG_DIR $LOG_DIR ; result=` expr $result + $? `
    if [ ! -e ${LOG_DIR} ]; then
        mkdir -p ${LOG_DIR}
    fi
    
    USER_PASSWORD=${USER_PASSWORD:-""}
    check_config_type 'string' USER_PASSWORD $USER_PASSWORD ; result=` expr $result + $? `
    
    NOVA_PASSWORD=${NOVA_PASSWORD:-""}
    check_config_type 'string' NOVA_PASSWORD $NOVA_PASSWORD ; result=` expr $result + $? `
    
    DB_PASSWORD=${DB_PASSWORD:-""}
    check_config_type 'string' DB_PASSWORD $DB_PASSWORD ; result=` expr $result + $? `
    
    MYSQL_USER=${MYSQL_USER:-"root"}
    check_config_type 'string' MYSQL_USER $MYSQL_USER ; result=` expr $result + $? `
    
    MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}
    check_config_type 'string' MYSQL_PASSWORD $MYSQL_PASSWORD ; result=` expr $result + $? `
    
    
    if [ $HOST_NAME == "compute" ]; then
	BIND_IP=${BIND_IP:-""}
	check_config_type 'string' BIND_IP $BIND_IP ; result=` expr $result + $? `
	
	CLUSTER_NODES=${CLUSTER_NODES:-""}
	check_config_type 'string' CLUSTER_NODES $CLUSTER_NODES ; result=` expr $result + $? `
	IFS=', ' read -r -a COMPUTE <<< "$CLUSTER_NODES"
	
	CLUSTER_INTERFACES=${CLUSTER_INTERFACES:-""}
	check_config_type 'string' CLUSTER_INTERFACES $CLUSTER_INTERFACES ; result=` expr $result + $? `
		
	CLUSTER_PORTS=${CLUSTER_PORTS:-""}
	check_config_type 'string' CLUSTER_PORTS $CLUSTER_PORTS ; result=` expr $result + $? `
    fi
    www_authenticate_uri=${www_authenticate_uri:-"http://controller:5000/v3"}
    check_config_type 'string' www_authenticate_uri $www_authenticate_uri ; result=` expr $result + $? `
    
    region=${region:-"RegionOne"}
    check_config_type 'string' region $region ; result=` expr $result + $? `

    OS_AUTH_URL=${auth_url:-"http://controller:5000/v3"}
    check_config_type 'string' OS_AUTH_URL $OS_AUTH_URL ; result=` expr $result + $? `
    
    memcached_servers=${memcached_servers:-"controller:11211"}
    check_config_type 'string' memcached_servers $memcached_servers ; result=` expr $result + $? `
    
    
    signing_dir=${signing_dir:-"/var/cache/masakari"}
    check_config_type 'string' signing_dir $signing_dir ; result=` expr $result + $? `
    
    OS_PROJECT_DOMAIN_ID=${project_domain_id:-"default"}
    check_config_type 'string' OS_PROJECT_DOMAIN_ID $OS_PROJECT_DOMAIN_ID ; result=` expr $result + $? `
    
    OS_PROJECT_DOMAIN_NAME=${project_domain_name:-"Default"}
    check_config_type 'string' OS_PROJECT_DOMAIN_NAME $OS_PROJECT_DOMAIN_NAME ; result=` expr $result + $? `
    
    OS_USER_DOMAIN_ID=${user_domain_id:-"default"}
    check_config_type 'string' OS_USER_DOMAIN_ID $OS_USER_DOMAIN_ID ; result=` expr $result + $? `
    
    OS_USER_DOMAIN_NAME=${user_domain_name:-"Default"}
    check_config_type 'string' OS_USER_DOMAIN_NAME $OS_USER_DOMAIN_NAME ; result=` expr $result + $? `
    
    OS_PROJECT_NAME=${project_name:-""}
    check_config_type 'string' OS_PROJECT_NAME $OS_PROJECT_NAME ; result=` expr $result + $? `
    
    OS_USERNAME=${user_name:-""}
    check_config_type 'string' OS_USERNAME $OS_USERNAME ; result=` expr $result + $? `
    
    OS_PASSWORD=${password:-""}
    check_config_type 'string' OS_PASSWORD $OS_PASSWORD ; result=` expr $result + $? `
    
    OS_IDENTITY_API_VERSION=${identity_api_version:-3}
    check_config_type 'int' OS_IDENTITY_API_VERSION $OS_IDENTITY_API_VERSION ; result=` expr $result + $? `
    
    OS_IMAGE_API_VERSION=${image_api_version:-2}
    check_config_type 'int' OS_IMAGE_API_VERSION $OS_IMAGE_API_VERSION ; result=` expr $result + $? `
    
    auth_type=${auth_type:-"password"}
    check_config_type 'string' auth_type $auth_type ; result=` expr $result + $? `
       
    return $result
}

# this function will print all values
#
print (){
	echo "LOG_LEVEL=$LOG_LEVEL"
	echo "CONTROLLER_IP $CONTROLLER_IP"
	echo "LOCAL_CONF $LOCAL_CONF"
	echo "MASAKARI_DIR $MASAKARI_DIR"
	echo "TOP_DIR $TOP_DIR"
	echo "MASAKARIMONITOR_DIR $MASAKARIMONITOR_DIR"
	echo "ETC_DIR $ETC_DIR"
	echo "LOGDIR $LOGDIR"
	echo "LOGFILE $LOGFILE"
	echo "MASAKARI_CONF $MASAKARI_CONF"
	echo "LOCAL_CONF $LOCAL_CONF"
	echo "MASAKARIMONITOR_CONF $MASAKARIMONITOR_CONF"
	echo "FNAME $FNAME"
	echo "my_ip $my_ip"
	echo "HOST_NAME $HOST_NAME"
	echo "debug $debug"
	echo "LOG_LEVEL $LOG_LEVEL"
	echo "LOG_DIR $LOG_DIR"
	echo "USER_PASSWORD $USER_PASSWORD"
	echo "NOVA_PASSWORD $NOVA_PASSWORD"
	echo "DB_PASSWORD $DB_PASSWORD"
	echo "MYSQL_USER $MYSQL_USER"
	echo "MYSQL_PASSWORD $MYSQL_PASSWORD"
	echo "BIND_IP $BIND_IP"
	echo "CLUSTER_NODES $CLUSTER_NODES"
	echo "CLUSTER_INTERFACES $CLUSTER_INTERFACES"
	echo "CLUSTER_PORTS $CLUSTER_PORTS             "
	echo "www_authenticate_uri $www_authenticate_uri  "
	echo "region $region"
	echo "OS_AUTH_URL $OS_AUTH_URL"
	echo "memcached_servers $memcached_servers"
	echo "signing_dir $signing_dir"
	echo "OS_PROJECT_DOMAIN_ID $OS_PROJECT_DOMAIN_ID"
	echo "OS_PROJECT_DOMAIN_NAME $OS_PROJECT_DOMAIN_NAME   "
	echo "OS_USER_DOMAIN_ID $OS_USER_DOMAIN_ID "
	echo "OS_USER_DOMAIN_NAME $OS_USER_DOMAIN_NAME"
	echo "OS_PROJECT_NAME $OS_PROJECT_NAME   "
	echo "OS_USERNAME $OS_USERNAME"
	echo "OS_PASSWORD $OS_PASSWORD"
	echo "OS_IDENTITY_API_VERSION $OS_IDENTITY_API_VERSION"
	echo "OS_IMAGE_API_VERSION $OS_IMAGE_API_VERSION"
	echo "auth_type $auth_type"
}
# This function used for keystone authentication
# Output : 0 : Success
#
mdc_admin-openrc(){
	echo_console "++-- . admin-openrc"
	echo_console "++-- export OS_PROJECT_DOMAIN_ID=$OS_PROJECT_DOMAIN_ID"
	#export OS_PROJECT_DOMAIN_ID=$OS_PROJECT_DOMAIN_ID
	echo_console "++-- export OS_USER_DOMAIN_ID=$OS_USER_DOMAIN_ID"
	#export OS_USER_DOMAIN_ID=$OS_USER_DOMAIN_ID
	echo_console "++-- export OS_PROJECT_DOMAIN_NAME=$OS_PROJECT_DOMAIN_NAME"
	#export OS_PROJECT_DOMAIN_NAME=$OS_PROJECT_DOMAIN_NAME
	echo_console "++-- export OS_USER_DOMAIN_NAME=$OS_USER_DOMAIN_NAME"
	#export OS_USER_DOMAIN_NAME=$OS_USER_DOMAIN_NAME
	echo_console "++-- export OS_PROJECT_NAME=admin"
	#export OS_PROJECT_NAME=admin
	echo_console "++-- export OS_USERNAME=$OS_USERNAME"
	#export OS_USERNAME=$OS_USERNAME
	echo_console "++-- export OS_PASSWORD=$OS_PASSWORD"
	#export OS_PASSWORD=$OS_PASSWORD
	echo_console "++-- export OS_AUTH_URL=$OS_AUTH_URL"
	#export OS_AUTH_URL=$OS_AUTH_URL
	echo_console "++-- export OS_IDENTITY_API_VERSION=3"
	#export OS_IDENTITY_API_VERSION=$OS_IDENTITY_API_VERSION
	echo_console "++-- export OS_IMAGE_API_VERSION=$OS_IMAGE_API_VERSION"
	#export OS_IMAGE_API_VERSION=$OS_IMAGE_API_VERSION
	return 0
}

# This function is used to create masakari user and requirements
# 
mdc_create_masakari_user() {
	echo_console "++-- creating openstack user masakari"
	openstack_user="masakari"
	mdc_admin-openrc
	result=$?
	echo_console "++-- openstack user create --domain default --password $USER_PASSWORD $openstack_user"
	#openstack user create --domain default --password $USER_PASSWORD $openstack_user ; result=` expr $result + $? `
	echo_console "++-- openstack role add --project service --user $openstack_user admin"
	#openstack role add --project service --user $openstack_user admin ; result=` expr $result + $? `
	echo_console "++-- openstack service create --name $openstack_user --description \"OpenStack Compute\" instance-ha"
	#openstack service create --name $openstack_user --description "OpenStack Compute" instance-ha ; result=` expr $result + $? `
	echo_console "++-- openstack endpoint create --region $region $openstack_user public http://controller:15868/v1/%\(tenant_id\)s"
	#openstack endpoint create --region $region $openstack_user public http://controller:15868/v1/%\(tenant_id\)s ; result=` expr $result + $? `
	echo_console "++-- openstack endpoint create --region $region $openstack_user internal http://controller:15868/v1/%\(tenant_id\)s"
	#openstack endpoint create --region $region $openstack_user internal http://controller:15868/v1/%\(tenant_id\)s ; result=` expr $result + $? `
	echo_console "++-- openstack endpoint create --region $region $openstack_user admin http://controller:15868/v1/%\(tenant_id\)s"
	#openstack endpoint create --region $region $openstack_user admin http://controller:15868/v1/%\(tenant_id\)s ; result=` expr $result + $? `
	return $result
}

#This function creates the masakari database
#
mdc_create_masakari_database() {
	#FNAME="create_masakari_database"
	MYSQL_HOST="localhost"
	echo_console "++--  database bulding masakari"
	result=$?
	#sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "DROP DATABASE IF EXISTS $db;" ; result=` expr $result + $? `
	#sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "CREATE DATABASE $db CHARACTER SET utf8;" ; result=` expr $result + $? `
	#sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "GRANT ALL PRIVILEGES ON $db.* TO '$db'@'localhost' IDENTIFIED BY '$DB_PASSWORD'" ; result=` expr $result + $? `
	#sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "GRANT ALL PRIVILEGES ON $db.* TO '$db'@'%' IDENTIFIED BY '$DB_PASSWORD'" ; result=` expr $result + $? `
	return $result
}

#This funcrion will create services
#
mdc_enable_masakari_service () {
	echo_console "${CYAN}++-- Copying The Services Started${RESET}"
	if [ "$HOST_NAME" == "controller" ]; then
		# Service Script
		msg=`sudo cp $ETC_DIR/servicescript.service.tmp $LIB_SERVICE_DIR/masakari-api.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Api/g" $LIB_SERVICE_DIR/masakari-api.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-api/g" $LIB_SERVICE_DIR/masakari-api.service
		echo_console "${CYAN}++--$msg${RESET}"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-api.service $SERVICE_DIR -v`
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`sudo systemctl enable masakari-api.service`
		echo_console "${CYAN}++-- $msg${RESET}"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.tmp $LIB_SERVICE_DIR/masakari-engine.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Engine/g" $LIB_SERVICE_DIR/masakari-engine.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-engine/g" $LIB_SERVICE_DIR/masakari-engine.service
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-engine.service $SERVICE_DIR -v`
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`sudo systemctl enable masakari-engine.service`
		echo_console "${CYAN}++-- $msg${RESET}"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.tmp $LIB_SERVICE_DIR/masakari-wsgi.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Wsgi/g" $LIB_SERVICE_DIR/masakari-wsgi.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-wsgi/g" $LIB_SERVICE_DIR/masakari-wsgi.service
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-wsgi.service $SERVICE_DIR -v`
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`sudo systemctl enable masakari-wsgi.service`
		echo_console "${CYAN}++-- $msg${RESET}"
	elif [ "$HOST_NAME" == "compute" ]; then
		# Service Script
		msg=`sudo cp $ETC_DIR/servicescript.service.tmp $LIB_SERVICE_DIR/masakari-hostmonitor.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Hostmonitor/g" $LIB_SERVICE_DIR/masakari-hostmonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-hostmonitor/g" $LIB_SERVICE_DIR/masakari-hostmonitor.service
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-hostmonitor.service $SERVICE_DIR -v`
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`sudo systemctl enable masakari-hostmonitor.service`
		echo_console "${CYAN}++-- $msg${RESET}"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.tmp $LIB_SERVICE_DIR/masakari-instancemonitor.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Instancemonitor/g" $LIB_SERVICE_DIR/masakari-instancemonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-instancemonitor/g" $LIB_SERVICE_DIR/masakari-instancemonitor.service
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-instancemonitor.service $SERVICE_DIR -v`
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`sudo systemctl enable masakari-instancemonitor.service`
		echo_console "${CYAN}++-- $msg${RESET}"
		
		msg=`sudo cp $ETC_DIR/servicescript.service.tmp $LIB_SERVICE_DIR/masakari-processmonitor.service -v`
		sudo sed -i "s/<DESCRIPTION>.*/Masakari Processmonitor/g" $LIB_SERVICE_DIR/masakari-processmonitor.service
		sudo sed -i "s/<SCRIPT_FILE>.*/masakari-processmonitor/g" $LIB_SERVICE_DIR/masakari-processmonitor.service
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`ln -s $LIB_SERVICE_DIR/masakari-processmonitor.service $LIB_SERVICE_DIR -v`
		echo_console "${CYAN}++-- $msg${RESET}"
		msg=`sudo systemctl enable masakari-processmonitor.service`
		echo_console "${CYAN}++-- $msg${RESET}"
	fi
	#sudo systemctl daemon-reload
	echo_console "${CYAN}++-- Copying The Services Ends${RESET}"
}

# This function will install the masakari services
#
mdc_install_masakari () {
	if [ "$HOST_NAME" == "controller" ]; then
		cd $MASAKARI_DIR
		result=$?
		echo_console "++-- installing masakari controller service"
		#sudo python setup.py install --record installedfiles.txt ; result=` expr $result + $? `
		cd $TOP_DIR
		echo_console "++-- installing python-masakariclient"
		#sudo pip install python-masakariclient ; result=` expr $result + $? `
		echo_console "++-- installing masakari-dashboard"
		#sudo pip install -e masakari-dashboard ; result=` expr $result + $? `
	elif [ "$HOST_NAME" == "compute" ]; then
		echo_console "++-- installing corosync pacemaker"
		result=$?
		#sudo apt-get install corosync pacemaker -y ; result=` expr $result + $? `
		echo_console "++-- installing crm114"
		#sudo apt install crm114 -y ; result=` expr $result + $? `
		echo_console "++-- installing crmsh"
		#sudo apt install crmsh -y ; result=` expr $result + $? `
		cd $MASAKARIMONITOR_DIR
		echo_console "++-- installing masakari-monitors"
		#sudo python setup.py install --record installedfiles.txt ; result=` expr $result + $? `
	fi
	mdc_enable_masakari_service
	return $result
}

# This Function will create the configuration file of masakari services
#
mdc_create_masakari_conf () {
	echo_console "++-- Creating Configuration file of $HOST_NAME"
	if [ "$HOST_NAME" == "controller" ]; then
		if [ ! -e ${MASAKARI_CONF} ]; then
			sudo mkdir -p ${MASAKARI_CONF}
		fi
		#moving configuration files.
		echo_console "++-- cp $ETC_DIR/masakari.conf.tmp $MASAKARI_CONF/masakari.conf"
		sudo cp $ETC_DIR/masakari.conf.tmp $MASAKARI_CONF/masakari.conf -v
		echo_console "++-- cp $ETC_DIR/api-paste.ini.tmp $MASAKARI_CONF/api-paste.ini"
		sudo cp $ETC_DIR/api-paste.ini.tmp $MASAKARI_CONF/api-paste.ini -v
		#editing masakari.conf
		sudo sed -i "s/os_privileged_user_password = <os_privileged_user_password>.*/os_privileged_user_password = $NOVA_PASSWORD/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/log_dir = <log_dir>.*/log_dir = $LOG_DIR/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/masakari_api_listen = <listen_ip>.*/masakari_api_listen = $CONTROLLER_IP/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/connection = <database_connection>.*/connection = mysql+pymysql://masakari:$DB_PASSWORD@controller/masakari?charset=utf8/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/www_authenticate_uri = <www_authenticate_uri>.*/www_authenticate_uri = $www_authenticate_uri/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/region = <region>.*/region = $region/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/auth_url = <auth_url>.*/auth_url = $OS_AUTH_URL/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/memcached_servers = <memcached_servers>.*/memcached_servers = $memcached_servers/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/signing_dir = <signing_dir>.*/signing_dir = $signing_dir/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/project_domain_id = <project_domain_id>.*/project_domain_id = $OS_PROJECT_DOMAIN_ID/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/project_domain_name = <project_domain_name>.*/project_domain_name = $OS_PROJECT_DOMAIN_NAME/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/user_domain_id = <user_domain_id>.*/user_domain_id = $OS_USER_DOMAIN_ID/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/user_domain_name = <user_domain_name>.*/user_domain_name = $OS_USER_DOMAIN_NAME/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/project_name = <project_name>.*/project_name = $OS_PROJECT_NAME/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/username = <username>.*/username = masakari/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/password = <password>.*/password = $USER_PASSWORD/g" $MASAKARI_CONF/masakari.conf
		sudo sed -i "s/host = <hostname>.*/host = $my_ip/g" $MASAKARI_CONF/masakari.conf
		
	elif [ "$HOST_NAME" == "compute" ]; then
		if [ ! -e ${MASAKARIMONITOR_CONF} ]; then
			sudo mkdir -p ${MASAKARIMONITOR_CONF}
		fi
		#moving configuration files.
		echo_console "++-- cp $ETC_DIR/masakarimonitors.conf.tmp $MASAKARIMONITOR_CONF/masakarimonitors.conf"
		sudo cp $ETC_DIR/masakarimonitors.conf.tmp $MASAKARIMONITOR_CONF/masakarimonitors.conf -v
		echo_console "++-- cp $ETC_DIR/process_list.yaml.tmp $MASAKARIMONITOR_CONF/process_list.yaml"
		sudo cp $ETC_DIR/process_list.yaml.tmp $MASAKARIMONITOR_CONF/process_list.yaml -v
		echo_console "++-- cp $ETC_DIR/corosync.tmp /etc/corosync/corosync"
		sudo cp $ETC_DIR/corosync.tmp /etc/default/corosync -v
		echo_console "++-- cp $ETC_DIR/corosync.conf.tmp /etc/corosync/corosync.conf"
		sudo cp $ETC_DIR/corosync.conf.tmp /etc/corosync/corosync.conf -v
		#editing masakarimonitor.conf
		sudo sed -i "s/host = <hostname>.*/host = $my_ip/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/debug = <debug>.*/debug = $debug/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/log_dir = <log_dir>.*/log_dir = $LOG_DIR/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/region = <region>.*/region = $region/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/auth_url = <auth_url>.*/auth_url = $OS_AUTH_URL/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/password = <password>.*/password = $USER_PASSWORD/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/project_domain_id = <project_domain_id>.*/project_domain_id = $OS_PROJECT_DOMAIN_ID/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/project_domain_name = <project_domain_name>.*/project_domain_name = $OS_PROJECT_DOMAIN_NAME/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/user_domain_id = <user_domain_id>.*/user_domain_id = $OS_USER_DOMAIN_ID/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/user_domain_name = <user_domain_name>.*/user_domain_name = $OS_USER_DOMAIN_NAME/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/corosync_multicast_interfaces = <corosync_multicast_interfaces>.*/corosync_multicast_interfaces = '$CLUSTER_INTERFACES'/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		sudo sed -i "s/corosync_multicast_ports = <corosync_multicast_ports>.*/corosync_multicast_ports = '$CLUSTER_PORTS'/g" $MASAKARIMONITOR_CONF/masakarimonitors.conf
		#editting corosync.conf
		sudo sed -i "s/bindnetaddr: <bind_ip>.*/bindnetaddr: $BIND_IP/g" /etc/corosync/corosync.conf
		size=${#COMPUTE[@]}
		echo "nodelist {" >> /etc/corosync/corosync.conf
		c=0
		while [ $c -lt $size ]
		do
		echo "	node {
			ring0_addr: ${COMPUTE[$c]}
			nodeid:` expr $c + 1 ` 
		}" >> /etc/corosync/corosync.conf
		c=` expr $c + 1 `
		done
		echo "}" >> /etc/corosync/corosync.conf
		echo "quorum {
		# Enable and configure quorum subsystem (default: off)
		# see also corosync.conf.5 and votequorum.5
		provider: corosync_votequorum
		two_node: 1
	}" >> /etc/corosync/corosync.conf
		
	fi
	return 0
}

#main routine
result=0
FNAME="masakari.sh"
mdc_set_conf_value
if [ $? -gt 0 ]; then echo_error "error in local.conf"; exit 1; fi
echo_console "${CYAN}++-- masakari.sh starts${RESET}"

mdc_create_masakari_user
if [ $? -gt 0 ]; then echo_error "error while creating masakari user"; exit 1; fi

mdc_create_masakari_database
if [ $? -gt 0 ]; then echo_error "error while creating masakari database"; exit 1; fi

mdc_install_masakari
if [ $? -gt 0 ]; then echo_error "error while installing masakari service"; exit 1; fi

mdc_create_masakari_conf
if [ $? -gt 0 ]; then echo_error "error while creating masakari configuration"; exit 1; fi

echo_success
#print

#end
# new version


