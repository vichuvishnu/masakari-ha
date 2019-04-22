# [MDCMASAKARI_INSTALLATION]
edit the local.conf.
run the script .
./masakari.sh
# [Installation using script]


# [Installation by manually]
Steps to follow in masakari installation.

## [Environment Bulding]
* All the environment bulding steps should be done in both controller and compute.
* Clone the masakari from git repo.
```bash
	$ sudo -s
	# git clone "https://github.com/ntt-sic/masakari.git"
```
* Install packages for buliding masakari services.
```bash
	# sudo apt-get install python-daemon dpkg-dev debhelper
```
* Create a user openstack required by masakari with no password .
```bash
	# sudo useradd -s /bin/bash -d /home/openstack -m openstack
	# echo "openstack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/openstack
```
## [Bulding Masakari Packages]
* Creating Masakari Packages it should be done in both controller and compute nodes.
```bash
	# cd masakari/masakari-controller
	# sudo ./debian/rules binary
	# cd masakari/masakari-hostmonitor
	# sudo ./debian/rules binary
	# cd masakari/masakari-instancemonitor
	# sudo ./debian/rules binary
	# cd masakari/masakari-processmonitor
	# sudo ./debian/rules binary
```
## [Installing Masakari Services]
* Here masakari-controller service will only run in controller and the remaning masakari-hostmonitor,masakari-instancemonitor,masakari-processmonitor will run compute.
* In controller
```bash
	# sudo apt-get install build-essential python-dev libmysqlclient-dev libffi-dev libssl-dev python-pip
	# pip install -U pip
	# cd masakari/masakari-controller
	# sudo pip install -r requirements.txt
```
* Create Database for masakari.
```bash
	# mysql
		MariaDB [(none)]> CREATE DATABASE vm_ha;
		MariaDB [(none)]> GRANT ALL PRIVILEGES ON vm_ha.* TO 'vm_ha'@'localhost' \
		IDENTIFIED BY 'accl';
		MariaDB [(none)]> GRANT ALL PRIVILEGES ON vm_ha.* TO 'vm_ha'@'%' \
		IDENTIFIED BY 'accl';
		MariaDB [(none)]> exit
	# cd masakari
	# sudo dpkg -i masakari-controller_1.0.0-1_all.deb
	# vi /etc/masakari/masakari-controller.conf
```
* in the db section.
```conf
	[db]
	drivername = mysql
	host = <controller_ip>
	name = vm_ha
	user = vm_ha
	passwd = accl
	charset = utf8
	lock_retry_max_cnt = 5
	innodb_lock_wait_timeout = 10
```
* in log section.
```conf
	[log]
	log_level = debug
```
* in nova section.
```conf
	[nova]
	domain = Default
	admin_user = admin
	admin_password = accl
	auth_url =  http://controller:5000/v3
	project_name = admin
```
* create database setting script
```bash
# cd masakari/
# vi masakari_database_setting.sh
```
edit masakari_database_setting.sh file
```bash
	#!/bin/bash

	DB_USER=vm_ha
	DB_PASSWORD=accl
	DB_HOST=<controller ip>

	cd masakari-controller/db
	sudo mysql -u${DB_USER} -p${DB_PASSWORD} -h${DB_HOST} -e "source create_vmha_database.sql"
```
change masakari_database_setting.sh script to execuitable mode
```bash
# chmod +x masakari_database_setting.sh
# vi reserved_host_add.sh
```
edit reserved_host_add.sh file
```bash
	#!/bin/bash

	DB_USER=vm_ha
	DB_PASSWORD=accl
	DB_HOST=<controller ip>
	MCASTADDR=226.94.1.1
	MCASTPORT=5405

	cd masakari-controller/utils
	sudo python reserve_host_manage.py --mode add \
	--port "226.94.1.1:5405" \
	--port "${MCASTADDR}:${MCASTPORT}" \
	--db-user ${DB_USER} --db-password ${DB_PASSWORD} --db-host ${DB_HOST} \
	--host $*
```
change reserved_host_add.sh script to execuitable mode
```bash
# chmod +x reserved_host_add.sh
# vi reserved_host_delete.sh
```
edit reserved_host_delete.sh file
```bash
	#!/bin/bash

	DB_USER=vm_ha
	DB_PASSWORD=accl
	DB_HOST=<controller ip>
	MCASTADDR=226.94.1.1
	MCASTPORT=5405

	cd masakari-controller/utils
	sudo python reserve_host_manage.py --mode delete \
	--port "226.94.1.1:5405" \
	--port "${MCASTADDR}:${MCASTPORT}" \
	--db-user ${DB_USER} --db-password ${DB_PASSWORD} --db-host ${DB_HOST} \
	--host $*
```
change reserved_host_delete.sh script to execuitable mode
```bash
# chmod +x reserved_host_delete.sh
# vi reserved_host_list.sh
```
edit reserved_host_list.sh file
```bash
	#!/bin/bash

	DB_USER=vm_ha
	DB_PASSWORD=accl
	DB_HOST=<controller ip>
	MCASTADDR=226.94.1.1
	MCASTPORT=5405

	cd masakari-controller/utils
	sudo python reserve_host_manage.py --mode list \
	--port "226.94.1.1:5405" \
	--port "${MCASTADDR}:${MCASTPORT}" \
	--db-user ${DB_USER} --db-password ${DB_PASSWORD} --db-host ${DB_HOST}
```
change reserved_host_list.sh script to execuitable mode
```bash
# chmod +x reserved_host_list.sh
# vi reserved_host_update.sh
```
edit reserved_host_update.sh file
```bash
	#!/bin/bash

	DB_USER=vm_ha
	DB_PASSWORD=accl
	DB_HOST=192.168.1.225
	MCASTADDR=226.94.1.1
	MCASTPORT=5405

	cd masakari-controller/utils
	sudo python reserve_host_manage.py --mode add \
	 --port "226.94.1.1:5405" \
	 --port "${MCASTADDR}:${MCASTPORT}" \
	 --db-user ${DB_USER} --db-password ${DB_PASSWORD} --db-host ${DB_HOST} \
	 --before-host $1 --after-host $2
```
change reserved_host_update.sh script to execuitable mode
```bash
# chmod +x reserved_host_update.sh	
```
* In Compute (in both compute node)
	** In compute section we need to install corosync and pacemaker
```bash
	# sudo apt-get install corosync pacemaker
	# vi /etc/default/corosync
```
	```conf
		# start corosync at boot [yes|no]
		START=yes
	```
```bash
	# vi /etc/corosync/corosync.conf
```
	```conf
		# Please read the corosync.conf.5 manual page
		totem {
			version: 2

			crypto_cipher: none
			crypto_hash: none

			interface {
				ringnumber: 0
				bindnetaddr: 192.168.1.0
				mcastaddr: 226.94.1.1
				mcastport: 5405
				ttl: 1
			}
			transport: udpu
		}

		logging {
			fileline: off
			to_logfile: yes
			to_syslog: yes
			logfile: /var/log/corosync/corosync.log
			debug: off
			timestamp: on
			logger_subsys {
				subsys: QUORUM
				debug: on
			}
		}

		nodelist {
			node {
				ring0_addr: <compute1>
				nodeid: 1
			}
			node {
				ring0_addr: <compute2>
				nodeid: 2
			}
		}
		quorum {
			# Enable and configure quorum subsystem (default: off)
			# see also corosync.conf.5 and votequorum.5
			provider: corosync_votequorum
			two_node: 1
		}
	```
```bash
	# sudo service corosync restart
	# sudo service pacemaker restart
	# cd masakari
	# sudo dpkg -i masakari-hostmonitor_1.0.0-1_all.deb
	# cd masakari
	# sudo dpkg -i masakari-instancemonitor_1.0.0-1_all.deb
	# cd masakari
	# sudo dpkg -i masakari-processmonitor_1.0.0-1_all.deb
	# sudo apt install crm114
	# sudo apt install crmsh
	# vi /etc/masakari/masakari-hostmonitor.conf
```
```conf
	
		RM_URL="http://<controller ip>:15868"
		
		LOG_LEVEL="debug"
```
```bash
	# vi /etc/masakari/masakari-instancemonitor.conf
```
```conf
		url = http://<controller ip>:15868
```
```bash
	# vi /etc/masakari/masakari-processmonitor.conf
```
```conf
		RESOURCE_MANAGER_URL="http://<controller ip>:15868"
		PROCESS_CHECK_INTERVAL=5
		PROCESS_REBOOT_RETRY=3
		REBOOT_INTERVAL=5
		RESOURCE_MANAGER_SEND_TIMEOUT=10
		RESOURCE_MANAGER_SEND_RETRY=12
		RESOURCE_MANAGER_SEND_DELAY=10
		RESOURCE_MANAGER_SEND_RETRY_TIMEOUT=120
		REGION_ID=RegionOne
		LOG_LEVEL="info"
```
* Finilize Installation
in controller
```bash
	# sudo service masakari-controller restart
```	
in compute
```bash
	# sudo service masakari-hostmonitor restart
	# sudo service masakari-processmonitor restart
	# sudo service masakari-instancemonitor restart
```
