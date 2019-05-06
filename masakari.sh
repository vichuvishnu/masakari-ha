#!/bin/bash
#openstack masakari installation script
#usage ./masakari.sh
#


# Directories
TOP_DIR=$(cd $(dirname "$0") && pwd)
ETC_DIR="$TOP_DIR/etc"
LOGDIR="$TOP_DIR/log"
LOGFILE="${LOGDIR}/masakari.log"
LOCAL_CONF="$TOP_DIR/local.conf"

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
	echo_console "${RED}###########################################################${RESET}"
	echo_console "${RED}# $1 ${RESET}"
	echo_console "${RED}# :-( :-( :-(${RESET}"
	echo_console "${RED}###########################################################${RESET}"
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
mdc_set_conf_value () {
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

    my_ip=${my_ip:-""}
    check_config_type 'string' my_ip $my_ip
    if [ "$my_ip" == "$CONTROLLER_IP" ]; then
	HOST_NAME="controller"
    else
	HOST_NAME="compute"
    fi
    
    LOG_LEVEL=${LOG_LEVEL:-"info"}
    check_config_type 'string' LOG_LEVEL $LOG_LEVEL
    
    LOG_DIR=${LOG_DIR:-"var/log/masakari"}
    check_config_type 'string' LOG_DIR $LOG_DIR
    if [ ! -e ${LOG_DIR} ]; then
        mkdir -p ${LOG_DIR}
    fi
    
    USER_PASSWORD=${USER_PASSWORD:-""}
    check_config_type 'string' USER_PASSWORD $USER_PASSWORD
    
    NOVA_PASSWORD=${NOVA_PASSWORD:-""}
    check_config_type 'string' NOVA_PASSWORD $NOVA_PASSWORD
    
    DB_PASSWORD=${DB_PASSWORD:-""}
    check_config_type 'string' DB_PASSWORD $DB_PASSWORD
    
    MYSQL_USER=${MYSQL_USER:-"root"}
    check_config_type 'string' MYSQL_USER $MYSQL_USER
    
    MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}
    check_config_type 'string' MYSQL_PASSWORD $MYSQL_PASSWORD
    
    MYSQL_HOST=${MYSQL_HOST:-"127.0.0.1"}
    check_config_type 'string' MYSQL_HOST $MYSQL_HOST
    
    if [ $HOST_NAME == "compute" ]; then
	BIND_IP=${BIND_IP:-""}
	check_config_type 'string' BIND_IP $BIND_IP
	
	CLUSTER_NODES=${CLUSTER_NODES:-""}
	check_config_type 'string' CLUSTER_NODES $CLUSTER_NODES
	IFS=', ' read -r -a COMPUTE <<< "$CLUSTER_NODES"
    fi
    www_authenticate_uri=${www_authenticate_uri:-"http://controller:5000/v3"}
    check_config_type 'string' www_authenticate_uri $www_authenticate_uri
    
    region=${region:-"RegionOne"}
    check_config_type 'string' region $region

    OS_AUTH_URL=${auth_url:-"http://controller:5000/v3"}
    check_config_type 'string' OS_AUTH_URL $OS_AUTH_URL
    
    memcached_servers=${memcached_servers:-"controller:11211"}
    check_config_type 'string' memcached_servers $memcached_servers
    
    
    signing_dir=${signing_dir:-"/var/cache/masakari"}
    check_config_type 'string' signing_dir $signing_dir
    
    OS_PROJECT_DOMAIN_ID=${project_domain_id:-"default"}
    check_config_type 'string' OS_PROJECT_DOMAIN_ID $OS_PROJECT_DOMAIN_ID
    
    OS_PROJECT_DOMAIN_NAME=${project_domain_name:-"Default"}
    check_config_type 'string' OS_PROJECT_DOMAIN_NAME $OS_PROJECT_DOMAIN_NAME
    
    OS_USER_DOMAIN_ID=${user_domain_id:-"default"}
    check_config_type 'string' OS_USER_DOMAIN_ID $OS_USER_DOMAIN_ID
    
    OS_USER_DOMAIN_NAME=${user_domain_name:-"Default"}
    check_config_type 'string' OS_USER_DOMAIN_NAME $OS_USER_DOMAIN_NAME
    
    OS_PROJECT_NAME=${project_name:-"Default"}
    check_config_type 'string' OS_PROJECT_NAME $OS_PROJECT_NAME
    
    OS_USERNAME=${user_name:-"Default"}
    check_config_type 'string' OS_USERNAME $OS_USERNAME
    
    OS_PASSWORD=${password:-"Default"}
    check_config_type 'string' OS_PASSWORD $OS_PASSWORD
    
    OS_IDENTITY_API_VERSION=${identity_api_version:-"Default"}
    check_config_type 'string' OS_IDENTITY_API_VERSION $OS_IDENTITY_API_VERSION
    
    OS_IMAGE_API_VERSION=${image_api_version:-"Default"}
    check_config_type 'string' OS_IMAGE_API_VERSION $OS_IMAGE_API_VERSION
    
    auth_type=${auth_type:-"Default"}
    check_config_type 'string' auth_type $auth_type
    
    return 0
}
# This function used for keystone authentication
# Output : 0 : Success
#
mdc_admin-openrc(){
	echo_console "++-- . admin-openrc"
	echo_console "++-- export OS_PROJECT_DOMAIN_ID=$OS_PROJECT_DOMAIN_ID"
	export OS_PROJECT_DOMAIN_ID=$OS_PROJECT_DOMAIN_ID
	echo_console "++-- export OS_USER_DOMAIN_ID=$OS_USER_DOMAIN_ID"
	export OS_USER_DOMAIN_ID=$OS_USER_DOMAIN_ID
	echo_console "++-- export OS_PROJECT_DOMAIN_NAME=$OS_PROJECT_DOMAIN_NAME"
	export OS_PROJECT_DOMAIN_NAME=$OS_PROJECT_DOMAIN_NAME
	echo_console "++-- export OS_USER_DOMAIN_NAME=$OS_USER_DOMAIN_NAME"
	export OS_USER_DOMAIN_NAME=$OS_USER_DOMAIN_NAME
	echo_console "++-- export OS_PROJECT_NAME=$OS_PROJECT_NAME"
	export OS_PROJECT_NAME=$OS_PROJECT_NAME
	echo_console "++-- export OS_USERNAME=$OS_USERNAME"
	export OS_USERNAME=$OS_USERNAME
	echo_console "++-- export OS_PASSWORD=$OS_PASSWORD"
	export OS_PASSWORD=$OS_PASSWORD
	echo_console "++-- export OS_AUTH_URL=$OS_AUTH_URL"
	export OS_AUTH_URL=$OS_AUTH_URL
	echo_console "++-- export OS_IDENTITY_API_VERSION=3"
	export OS_IDENTITY_API_VERSION=$OS_IDENTITY_API_VERSION
	echo_console "++-- export OS_IMAGE_API_VERSION=$OS_IMAGE_API_VERSION"
	export OS_IMAGE_API_VERSION=$OS_IMAGE_API_VERSION
	return 0
}

# This function is used to create masakari user and requirements
# 
mdc_create_masakari_user() {
	echo_console "++--  creating openstack user masakari"
	openstack_user="masakari"
	mdc_admin-openrc
	echo_console "++--  openstack user create --domain default --password $USER_PASSWORD $openstack_user"
	openstack user create --domain default --password $USER_PASSWORD $openstack_user
	echo_console "++--  openstack role add --project service --user $openstack_user admin"
	openstack role add --project service --user $openstack_user admin
	echo_console "++--  openstack service create --name $openstack_user --description \"OpenStack Compute\" instance-ha"
	openstack service create --name $openstack_user --description "OpenStack Compute" instance-ha
	echo_console "++--  openstack endpoint create --region $region $openstack_user public http://controller:15868/v1/%\(tenant_id\)s"
	openstack endpoint create --region $region $openstack_user public http://controller:15868/v1/%\(tenant_id\)s
	echo_console "++--  openstack endpoint create --region $region $openstack_user internal http://controller:15868/v1/%\(tenant_id\)s"
	openstack endpoint create --region $region $openstack_user internal http://controller:15868/v1/%\(tenant_id\)s
	echo_console "++--  openstack endpoint create --region $region $openstack_user admin http://controller:15868/v1/%\(tenant_id\)s"
	openstack endpoint create --region $region $openstack_user admin http://controller:15868/v1/%\(tenant_id\)s
}

#This function creates the masakari database
#
mdc_create_masakari_database() {
	#FNAME="create_masakari_database"
	echo_console "++--  database bulding masakari"
	sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "DROP DATABASE IF EXISTS $db;"
	sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "CREATE DATABASE $db CHARACTER SET utf8;"
	sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "GRANT ALL PRIVILEGES ON $db.* TO '$db'@'localhost' IDENTIFIED BY '$DB_PASSWORD'"
	sudo mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "GRANT ALL PRIVILEGES ON $db.* TO '$db'@'%' IDENTIFIED BY '$DB_PASSWORD'"
}

# This Function will create the configuration file of masakari services
#
mdc_create_conf () {
	echo_console "++-- Creating Configuration file of $HOST_NAME"
	if [ "$HOST_NAME" == "controller" ]; then
		
	elif [ "$HOST_NAME" == "compute" ]; then
	
	fi

}
#main routine
result=0
FNAME="masakari.sh"
mdc_set_conf_value
echo_console "${CYAN}###########################################################${RESET}"
echo_console "${CYAN}####################masakari.sh starts#####################${RESET}"
echo_console "${CYAN}###########################################################${RESET}"


echo_console "${GREEN}###########################################################${RESET}"
echo_console "${GREEN}#masakari installation in $HOST_NAME${RESET}"  
echo_console "${GREEN}#is success         :-)  :-) :-)${RESET}"
echo_console "${GREEN}###########################################################${RESET}"

#echo_default_value
#end

# new version
