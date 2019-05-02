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
```
