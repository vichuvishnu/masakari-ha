#!/bin/bash
#run the script from masakari top directory after one try of 
#tox -e genconfig from top dir
#usage 	sudo -s
#	./masakarireq.sh

TOP_DIR="$(cd $(dirname "$0") && pwd)"
RED=`tput setaf 1`
GREEN=`tput setaf 2`
CYAN=`tput setaf 6`
RESET=`tput sgr0`

install (){
	echo "${CYAN}-----------------------------Installation Begin---------------------------------${RESET}"
	sudo apt-get install build-essential autoconf libtool pkg-config python-opengl python-pyrex python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 python-dev libvirt-dev python-dev python3-dev libssl-dev -y
	if [ $? -ne 0 ]; then
		return 1
	fi
	sudo apt install python-pip tox -y
	if [ $? -ne 0 ]; then
		return 1
	fi
	sudo pip install --upgrade setuptools
	if [ $? -ne 0 ]; then
		return 1
	fi	
	echo "${CYAN}-----------------------------Installation End---------------------------------${RESET}"
	echo "${CYAN}-----------------------------Installation PIP Requirements.tx---------------------------------${RESET}"
	sudo $TOP_DIR/.tox/genconfig/bin/pip install -r$TOP_DIR/test-requirements.txt 
	if [ $? -ne 0 ]; then
                return 1
        fi	
	sudo $TOP_DIR/.tox/genconfig/bin/pip install -chttps://git.openstack.org/cgit/openstack/requirements/plain/upper-constraints.txt?h=stable/rocky -r$TOP_DIR/test-requirements.txt
	if [ $? -ne 0 ]; then
                return 1
        fi
	echo "${CYAN}-----------------------------Installation End-----------------------------${RESET}"
	echo "${CYAN}-----------------------------Run tox cmd-----------------------------${RESET}"
	sudo tox -e genconfig
	if [ $? -ne 0 ]; then
                return 1
        fi
	return 0
}
error(){
	echo "${RED}########################################################################################"
	echo "# Error :-(                                                                            #"
        echo "# Usage :- sudo -s                                                                     #"
	echo "#          ./masakarireq.sh                                                            #"
	echo "# You may in the wrong directory go to masakari top directory .                        #"
	echo "# Check network connectivity .                                                         #"
	echo "# Run tox -e genconfig once in masakari top directory then again run the scritp        #"
	echo "########################################################################################${RESET}"
}

success(){ 
	echo "${GREEN}########################################################################################"
	echo "# Success :-)                                                                          #"
	echo "########################################################################################${RESET}"
}

# script begin
echo "${CYAN}----------------------------------Script Begin----------------------------------${RESET}"
echo "+------------------------------------------------------------------------------+"
echo "|Packages Installing:-                                                         |"
echo "|build-essential autoconf libtool pkg-config python-opengl python-pyrex        |"
echo "|python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4    |"
echo "|libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus    |"
echo "|python-qt4 python-qt4-gl libgle3 python-dev libvirt-dev python-dev python3-dev|"
echo "|libssl-dev                                                                    |"
echo "+------------------------------------------------------------------------------+"

install
if [ $? -eq 1 ]; then
	error
	exit 1
fi
success
#end
