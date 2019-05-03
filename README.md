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
