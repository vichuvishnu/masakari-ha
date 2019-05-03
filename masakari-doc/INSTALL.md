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
  compute public http://controller:15868/v1/%\(tenant_id\)s
$ openstack endpoint create --region RegionOne \
  compute internal http://controller:15868/v1/%\(tenant_id\)s
$ openstack endpoint create --region RegionOne \
  compute admin http://controller:15868/v1/%\(tenant_id\)s
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
$ sudo cp etc/masakari/masakari.conf /etc/masakari/api-paste.ini -v
```
* Edit the configuration file, sample configuration is in the same directory.
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

