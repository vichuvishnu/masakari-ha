# Masakari Installation

New masakari service will contain
1) Masakari controller services.
	* masakari-api
	* masakari-engine
	* masakari-wsgi
2) Masakari compute services.
	* masakari-hostmonitor
	* masakari-instancemonitor
	* masakari-processmonitor
3) Masakari dashboard support.
4) Masakari cli commands.

# How to install masakari services in both controller and compute.
## In controller
In controller for installing masakari we have to follow some main steps
1) Clone masakari from git hub.
2) Create database.
3) Install masakari.
4) Install masakari rest apis.
5) Install masakari dashboard.

* Clone masakari from git hub.
```bash
git clone https://github.com/openstack/masakari.git --branch stable/rocky
git clone https://github.com/openstack/masakari-dashboard --branch stable/rocky
```

* Create database.
	* Use the database access client to connect to the database server as the root user:
```bash
mysql
```

* Create the masakari databases:
```bash
MariaDB [(none)]> CREATE DATABASE masakari;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON masakari.* TO 'masakari'@'localhost' \
  IDENTIFIED BY 'MASAKARI_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON masakari.* TO 'masakari'@'%' \
  IDENTIFIED BY 'MASAKARI_DBPASS';
```

* Create masakari user:
```bash
$ openstack user create --password-prompt masakari
(give password as masakari)
```

* Add admin role to masakari user:
```bash
$ openstack role add --project service --user masakari admin
```

* Create new service:
```bash
$ openstack service create --name masakari --description "masakari high availability" instance-ha
```

* Create endpoint for masakari service:
```bash
$ openstack endpoint create --region RegionOne \
  masakari public http://controller:15868/v1/%\(tenant_id\)s
$ openstack endpoint create --region RegionOne \
  masakari internal http://controller:15868/v1/%\(tenant_id\)s
$ openstack endpoint create --region RegionOne \
  masakari admin http://controller:15868/v1/%\(tenant_id\)s
```

* To install masakari run setup.py from masakari
```bash
$ sudo python setup.py install
```
* Create directory /etc/masakari for keep configuration files and log directory
```bash
$ sudo mkdir /etc/masakari
$ sudo mkdir /var/log/masakari
```
* Copy masakari.conf, api-paste.ini file from masakari/etc/ to /etc/masakari folder
```bash
$ sudo cp etc/masakari/api-paste.ini /etc/masakari/api-paste.ini -v
$ sudo cp etc/masakari/masakari.conf /etc/masakari/masakari.conf -v
```
* Edit the configuration file, sample configuration is in the same directory.
* Minimal maskari controller configuration. Open /etc/masakari/masakari.conf
```bash
[default]
auth_strategy = keystone
masakari_topic = ha_engine
os_privileged_user_tenant = service
os_privileged_user_auth_url = http://controller:5000/v3
os_privileged_user_name = nova
os_privileged_user_password = NOVA_PASS
log_dir = /var/log/masakari
debug = true
masakari_api_listen = <controller_ip>
masakari_api_listen_port = 15868

[keystone_authtoken]
service_token_roles_required = true
www_authenticate_uri = http://controller:5000/v3
region = RegionOne
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
signing_dir = /var/cache/masakari
project_domain_id = default
project_domain_name = Default
user_domain_id = default
user_domain_name = Default
project_name = service
username = masakari
password = MASAKARI_PASS
auth_type = password

[database]
connection = mysql+pymysql://masakari:MASAKARI_DBPASS@controller/masakari?charset=utf8
```
Replace MASAKARI_PASS and NOVA_PASS with the password you chose for the nova user and masakari user in the Identity
service. 
Replace MASAKARI_DBPASS with the password you chose for the Masakari databases .

* After running setup.py for masakari (sudo python setup.py install), run masakari-manage command to sync the database
```bash
masakari-manage db sync
```
* Run the enableService.sh script from mdcMasakari top directory to enable the masakari service with parameter controller.
```bash
$ sudo -s
# ./enableService.sh controller
```
* To install masakari cli commands
```bash
$ pip install python-masakariclient
```
* To install masakari dashboard
```bash
$ git clone https://github.com/openstack/masakari-dashboard --branch stable/rocky
$ sudo pip install -e masakari-dashboard
(run this command out side the masakari-dasboard directory)
$ HOME_DIR=pwd
(run this command out side the masakari-dasboard directory)
$ ln -s $HOME_DIR/masakari-dashboard/masakaridashboard/local/enabled/_50_masakaridashboard.py /usr/lib/python2.7/dist-packages/openstack_dashboard/local/enabled 
$ ln -s $HOME_DIR/masakari-dashboard/masakaridashboard/local/local_settings.d/_50_masakari.py /usr/lib/python2.7/dist-packages/openstack_dashboard/local/local_settings.d
$ ln -s $HOME_DIR/masakari-dashboard/masakaridashboard/conf/masakari_policy.json /usr/lib/python2.7/dist-packages/openstack_dashboard/conf
```
* Finilize Masakari Controller Service Installation.
```bash
# service masakari-api restart
# service masakari-engine restart
# service masakari-wsgi restart
# service apache2 reload
```
## In Compute
To install masakari compute services there is a basic environment consist of corosync and pacemaker .
Steps to follow while installing masakari in compute.
1) Install and setup the corosync and pacemaker
2) Clone masakari from git hub.
3) Install masakari.
4) Create configuration files.

* Install and setup the corosync and pacemaker
```bash 
$ sudo apt-get install corosync pacemaker 
$ sudo apt install crm114
$ sudo apt install crmsh
```
* Edit configuration files /etc/corosync/corosync.conf /etc/default/corosync according to the sample configuration.
* Minimal configuration of corosync. Open /etc/corosync/corosync.conf
```bash
totem {
        version: 2

        crypto_cipher: none
        crypto_hash: none

        interface {
                ringnumber: 0
                bindnetaddr: <bind-address>
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
                ring0_addr: <compute1-address>
                nodeid: 1
        }
        node {
                ring0_addr: <compute2-address>
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
```<bind-address>```will be like this 192.168.1.0,```<compute1-address>``` will be the ip address of compute1 and so on. node section will increase according to the no of compute node in the cluster.
	
* Open /etc/default/corosync
```bash
# Corosync runtime directory
#COROSYNC_RUN_DIR=/var/lib/corosync

# Path to corosync.conf
#COROSYNC_MAIN_CONFIG_FILE=/etc/corosync/corosync.conf

# Path to authfile
#COROSYNC_TOTEM_AUTHKEY_FILE=/etc/corosync/authkey

# Command line options
#OPTIONS=""
# start corosync at boot [yes|no]
START=yes

```
* Clone masakari from git hub.
```bash
$ git clone https://github.com/openstack/masakari-monitors.git --branch stable/rocky
```
* Create masakarimonitors directory in /etc/.
* Run setup.py from masakari-monitors:
```bash
$ sudo python setup.py install
```
* Copy masakarimonitors.conf and process_list.yaml files from masakari-monitors/etc/ to /etc/masakarimonitors folder and make necessary changes to the masakarimonitors.conf and process_list.yaml files. To generate the sample masakarimonitors.conf file, run the following command from the top level of the masakari-monitors directory:
```bash
$ tox -egenconfig
```
* While running the tox -egenconfig if any error occur the run the masakarireq.sh script and then again run tox -egenconfig
```bash
$ sudo -s
# ./masakarireq.sh
```
* Edit the configuration file, sample configuration is in the same directory.
* Open /etc/masakarimonitors/masakarimonitors.conf
```bash
[DEFAULT]
tempdir = /var/tmp/masakarimonitor
host = <host_name>
instancemonitor_manager = masakarimonitors.instancemonitor.instance.InstancemonitorManager
introspectiveinstancemonitor_manager = masakarimonitors.introspectiveinstancemonitor.instance.IntrospectiveInstanceMonitorManager
processmonitor_manager = masakarimonitors.processmonitor.process.ProcessmonitorManager
hostmonitor_manager = masakarimonitors.hostmonitor.host.HostmonitorManager
debug = true
log_dir = /var/log/masakarimonitor

[api]
region = RegionOne
api_version = v1
api_interface = public
auth_url = http://controller:5000/v3
auth_type = password
project_domain_id = default
project_domain_name = default
user_domain_id = default
user_domain_name = default
project_name = service
username = masakari
password = MASAKARI_PASS

[host]
corosync_multicast_interfaces = '<management_network_interface_name>'
corosync_multicast_ports = '5405'
```
* Replace MASAKARI_PASS with the password you chose for the masakari user in the Identity service.```<management_network_interface_name>``` will be the network interface name for example 'ens1' or 'enp2s0' 
* Run the enableService.sh script from mdcMasakari top directory to enable the masakari service with parameter compute.
```bash
$ sudo -s
# ./enableService.sh compute
```
* Finilize Masakari Controller Service Installation.
```bash
# service masakari-hostmonitor restart
# service masakari-processmonitor restart
# service masakari-instancemonitor restart
```
# Masakari Verification 
* In controller add the create segment and add host (mininum two compute host)
```bash
$ . admin-openrc
$ masakari segment-create --name failover --recovery-method auto --service-type compute --description instance_ha 
+-----------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Property        | Value                                                                                                                                                                 |
+-----------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| created_at      | 2019-05-03T09:59:08.085106                                                                                                                                            |
| description     | instance_ha                                                                                                                                                           |
| id              | 2                                                                                                                                                                     |
| location        | {"project": {"domain_id": null, "id": "b40d394fef1e4a12b78dddf24aca3087", "name": null, "domain_name": null}, "zone": null, "region_name": "", "cloud": "controller"} |
| name            | failover                                                                                                                                                              |
| recovery_method | auto                                                                                                                                                                  |
| service_type    | compute                                                                                                                                                               |
| updated_at      | -                                                                                                                                                                     |
| uuid            | 2c18541e-dc47-4f90-b415-a0d050841771                                                                                                                                  |
+-----------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
$ masakari host-create --name compute5 --type COMPUTE --control-attributes SSH --segment-id 2c18541e-dc47-4f90-b415-a0d050841771
+---------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Property            | Value                                                                                                                                                                 |
+---------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| control_attributes  | SSH                                                                                                                                                                   |
| created_at          | 2019-05-03T10:34:39.466620                                                                                                                                            |
| failover_segment_id | 2c18541e-dc47-4f90-b415-a0d050841771                                                                                                                                  |
| id                  | 4                                                                                                                                                                     |
| location            | {"project": {"domain_id": null, "id": "b40d394fef1e4a12b78dddf24aca3087", "name": null, "domain_name": null}, "zone": null, "region_name": "", "cloud": "controller"} |
| name                | compute5                                                                                                                                                              |
| on_maintenance      | False                                                                                                                                                                 |
| reserved            | False                                                                                                                                                                 |
| type                | COMPUTE                                                                                                                                                               |
| updated_at          | -                                                                                                                                                                     |
| uuid                | 7abd98c9-10eb-45df-9acc-88ae669a7cc8                                                                                                                                  |
+---------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
$ masakari host-create --name compute3 --type COMPUTE --control-attributes SSH --segment-id 2c18541e-dc47-4f90-b415-a0d050841771
+---------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Property            | Value                                                                                                                                                                 |
+---------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| control_attributes  | SSH                                                                                                                                                                   |
| created_at          | 2019-05-03T10:34:39.466620                                                                                                                                            |
| failover_segment_id | 2c18541e-dc47-4f90-b415-a0d050841771                                                                                                                                  |
| id                  | 5                                                                                                                                                                     |
| location            | {"project": {"domain_id": null, "id": "457823daef1e4a12b78dddf24aca3087", "name": null, "domain_name": null}, "zone": null, "region_name": "", "cloud": "controller"} |
| name                | compute3                                                                                                                                                              |
| on_maintenance      | False                                                                                                                                                                 |
| reserved            | False                                                                                                                                                                 |
| type                | COMPUTE                                                                                                                                                               |
| updated_at          | -                                                                                                                                                                     |
| uuid                | 42q848c9-10eb-45df-9acc-88ae669a7cc8                                                                                                                                  |
+---------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
* Create an instance in host that is going to down.
* Verify that the instance is in the correct host.
* Poweroff the host that contain instance.
* After a few minutes the instance is move to the reserved host

