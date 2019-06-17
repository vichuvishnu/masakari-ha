# README maskari-deployment
# [maskari-deploy]
# [Vargrantfile]
1) vagrant up command will up the vm with given name for ubuntu 18.04 ubuntu/cosmic64. it will up 3 vm controller and 2 compute nodes.
2) in vagrant file it calling or accessing the .json files of controller and compute.

# [controller.json]
1) in json file there is a run list 
		recipe[guestos]
		recipe[devstack]
		recipe[masakari]
		recipe[controller_conf]
		recipe[masakari_controller_conf]
 it will run the following recipes in order (i think)

## [guestos]
1) in the guestos folder there is two sections templates and recipes the recipe that have to run said by the json file is in the recipes folder
2) it will contain default.rb ruby file say what to do with the guestos.

## [default.rb]
1) default.rb file will do to stop locale warning at login
		apt-get update
		sudo update-locale LC_CTYPE=en_US.UTF-8
		sudo update-locale LC_ALL=en_US.UTF-8

## [devstack]
1) in the devstack folder there is two sections templates and recipes the recipe that have to run said by the json file is in the recipes folder
2) it will contain default.rb ruby file say what to do with the devstack.also it contain setup_stack.rb for setup stack just run ./stack.sh

## [default.rb]
1) it will create a stack user and with no password.
2) clone devstack git repository
3) creates an bash script with executable mode (755) for owner  only  here owner is stack.

## [setup_stack.rb]
1) it will execute the command ./stack.sh

## [masakari]
1) in the masakari folder there is three sections templates,recipes and attributes the recipe that have to run said by the json file is in the recipes folder

## [default.rb]
1) clone masakari git repository in user stack
2) create a user openstack required by masakari with no password
3) install python-daemon,dpkg-dev,debhelper
4) build masakari-controller_1.0.0-1_all.deb,masakari-hostmonitor_1.0.0-1_all.deb,masakari-instancemonitor_1.0.0-1_all.deb,masakari-processmonitor_1.0.0-1_all.deb by running command sudo ./debian/rules binary

## [controller_conf]
1) in the controller_conf folder there is three sections templates,recipes and attributes the recipe that have to run said by the json file is in the recipes folder

## [default.rb]
1) create and edit the local.conf file with mode 0644
2) install nfs-kernel-server
3) create a directory in root /export with mode 0755
4) create another directory in stack /export/instances with mode 0755
5) enable and start nfs-kernel-server
6) run command exportfs -ra

## [masakari_controller_conf]
1) in the masakari_controller_conf folder there is three sections templates,recipes and attributes the recipe that have to run said by the json file is in the recipes folder

## [default.rb]
1) install the following packages
		build-essential
		python-dev
		python-pip
		libmysqlclient-dev
		libffi-dev
		libssl-dev
2) sudo pip install -U pip
3) pip install -r requirements.txt
4) dpkg -i /home/stack/masakari/masakari-controller_1.0.0-1_all.deb
5) create or edit masakari-controller.conf
6) /home/stack/masakari/masakari_database_setting.sh edit the template with host ips
7) add host lists in /ete/hosts
8) /home/stack/masakari/reserved_host_add.sh edit the template with host ips
9) /home/stack/masakari/reserved_host_delete.sh edit the template with host ips
10) /home/stack/masakari/reserved_host_list.sh edit the template with host ips
11) /home/stack/masakari/reserved_host_update.sh edit the template with host ips

# [compute.json]
1) in json file there is a run list 
		recipe[guestos]
		recipe[pacemaker]
		recipe[devstack]
		recipe[masakari]
		recipe[compute_conf]
		recipe[masakari_compute_conf]
## [guestos]
1) in the guestos folder there is two sections templates and recipes the recipe that have to run said by the json file is in the recipes folder
2) it will contain default.rb ruby file say what to do with the guestos.

## [default.rb]
1) default.rb file will do to stop locale warning at login
		apt-get update
		sudo update-locale LC_CTYPE=en_US.UTF-8
		sudo update-locale LC_ALL=en_US.UTF-8

## [pacemaker]
1) in the pacemaker folder there is three sections templates,recipes and attributes the recipe that have to run said by the json file is in the recipes folder
## [default.rb]
1) if platform version == 15.04 download http://launchpadlibrarian.net/220534376/libopenhpi2_2.14.1-1.3ubuntu2.1_amd64.deb in /root/libopenhpi2_2.14.1-1.3ubuntu2.1_amd64.deb and http://launchpadlibrarian.net/220534378/openhpid_2.14.1-1.3ubuntu2.1_amd64.deb in /root/openhpid_2.14.1-1.3ubuntu2.1_amd64.deb 
2) install the downloaded packages
3) download and install the corosync pacemaker
4) in /etc/default/corosync edit the corosync file with respect to corosync.erb template mode '0644'
5) in /etc/corosync/corosync.conf edit the corosync.conf file with respect to corosync.conf.erb template mode '0644'
6) corosync pacemaker action [:enable, :start]
  
## [devstack]
1) in the devstack folder there is two sections templates and recipes the recipe that have to run said by the json file is in the recipes folder
2) it will contain default.rb ruby file say what to do with the devstack.also it contain setup_stack.rb for setup stack just run ./stack.sh

## [default.rb]
1) it will create a stack user and with no password.
2) clone devstack git repository
3) creates an bash script with executable mode (755) for owner  only  here owner is stack.

## [setup_stack.rb]
1) it will execute the command ./stack.sh

## [masakari]
1) in the masakari folder there is three sections templates,recipes and attributes the recipe that have to run said by the json file is in the recipes folder

## [default.rb]
1) clone masakari git repository in user stack
2) create a user openstack required by masakari with no password
3) install python-daemon,dpkg-dev,debhelper
4) build masakari-controller_1.0.0-1_all.deb,masakari-hostmonitor_1.0.0-1_all.deb,masakari-instancemonitor_1.0.0-1_all.deb,masakari-processmonitor_1.0.0-1_all.deb by running command sudo ./debian/rules binary

## [compute_conf]
1) in the compute_conf folder there is three sections templates,recipes and attributes the recipe that have to run said by the json file is in the recipes folder

## [default.rb]
1) create and edit the local.conf file with mode 0644
2) install nfs-common
3) create directory /mnt/instances owner 'stack'  group 'stack'   mode '0755'
4) mount '/mnt/instances' do doubt

## [masakari_compute_conf]
1) in the masakari_compute_conf folder there is two sections templates and recipes the recipe that have to run said by the json file is in the recipes folder

## [default.rb]
1) sudo dpkg -i /home/stack/masakari/masakari-hostmonitor_1.0.0-1_all.deb
2) sudo dpkg -i /home/stack/masakari/masakari-instancemonitor_1.0.0-1_all.deb
3) sudo dpkg -i /home/stack/masakari/masakari-processmonitor_1.0.0-1_all.deb
4) edit /etc/masakari/masakari-hostmonitor.conf with template masakari-hostmonitor.conf.erb owner 'root'  group 'root'  mode '0644'
5) edit /etc/masakari/masakari-instancemonitor.conf with template masakari-instancemonitor.conf.erb owner 'root'  group 'root'  mode '0644'
5) edit /etc/masakari/masakari-processmonitor.conf with template masakari-processmonitor.conf.erb owner 'root'  group 'root'  mode '0644'
