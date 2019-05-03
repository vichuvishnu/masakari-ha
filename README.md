# [MDCMASAKARI_INSTALLATION]
The project is reffer from ntt masakari. For further information you can reffer

[1] https://github.com/ntt-sic/masakari

This scritp is under development so it may contain some bugs.To install the masakari you need a healty Openstack environment.It capable of live-migrate,migrate,evacuate

# [Installation using script]
* Masakari Installation usiing script 1st need to clone the repository
```bash
$ sudo -s
# git clone https://github.com/vichuvishnu/mdcMasakari --branch stable/rocky
# cd mdcMasakari
```
* Edit the local.conf file
```bash
# vi local.conf
```
* Now the script is ready to run 
```bash
# ./masakari.sh
```
# [Installation by manually]
Steps to follow in masakari installation. Check /masakari-doc/INSTALL.md

# [Verify Operation]
* In controller add the reserve host in to the database
```bash
cd masakari
./reserved_host_add.sh <compute host name>
./reserved_host_list.sh
```
* Create an instance in host that is going to down.
* Verify that the instance is in the correct host.
* Poweroff the host that contain instance.
* After a few minutes the instance is move to the reserved host
