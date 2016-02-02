# RightScale Attachments

These are mostly used as libraries or specific scripts called from a RightScript.

## General

### rs_distro.sh

Simple Linux distribution detection.

 - `atomichost` - CentOS or RHEL Atomic Host
 - `redhatenterpriseserver` - RHEL (Red Hat Enterprise Linux)
 - `centos` - CentOS
 - `ubuntu` - Ubuntu
 - `debian` - Debian GNU/Linux
 - `archlinux` - Arch Linux
 - `unknown` - Unknown/unsupported

## Docker

### docker_service.sh

#### Requires

Sources the following dependency scripts:
 - `rs_distro.sh`

#### Functions

##### docker_service()

 - `status` - shows the status of the docker service

 - `enable` - enables the docker service

 - `start` - starts the docker service

 - `stop` - stops the docker service

 - `restart` - restarts the docker service

##### docker_service_setup()

 - `systemd_redhat`

 - `systemd_centos` - sets up the docker service for systemd

 - `systemd_proxy`

 - `sysvinit_proxy`

 - `upstart`
