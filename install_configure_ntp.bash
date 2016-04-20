#! /usr/bin/sudo /bin/bash

set +e

# Keeping in time is not necessarily simple these days.

# Upstream Documentation
# - https://support.rackspace.com/how-to/using-ntp-to-sync-time/
## Arch Linux
# - https://wiki.archlinux.org/index.php/time
# - https://wiki.archlinux.org/index.php/systemd-timesyncd
# - https://wiki.archlinux.org/index.php/Network_Time_Protocol_daemon
## Debian
# - https://wiki.debian.org/NTP
## RHEL
# - https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/chap-Configuring_the_Date_and_Time.html#sect-Configuring_the_Date_and_Time-timedatectl-NTP

# INPUTS
# ---
# RightScript Name: Install and configure NTP
# Description: >
#   Installs and configures an appropriate ntp client for the system.
# Inputs:
#   NTP_SERVERS:
#     Input Type: array
#     Category: System
#     Default: array:["text:time.rightscale.com","text:ec2-us-east.time.rightscale.com","text:ec2-us-west.time.rightscale.com"]
#     Description: >
#       A comma-separated list of fully qualified domain names for the array of servers that instances should talk to.
#       Example: time1.example.com, time2.example.com, time3.example.com
#     Advanced: true
# ...
#

source "$RS_ATTACH_DIR/rs_distro.sh"

if [ "$RS_DISTRO" = 'atomichost' ]; then
  echo 'Red Hat Enterprise Linux Atomic Host not yet supported, but will exit gracefully.'
  exit 0
fi

# Use defaults for inputs that are not set
: ${NTP_SERVERS:=time.rightscale.com,ec2-us-east.time.rightscale.com,ec2-us-west.time.rightscale.com}

if systemctl status systemd-timesyncd.service > /dev/null 2>&1; then
  echo 'systemd-timesyncd found'
  sudo sh -e "$RS_ATTACH_DIR/configure_systemd-timesyncd.sh" "${NTP_SERVERS//,/ }"
  echo 'Done' && exit 0
elif systemctl status chronyd | grep -i ntp > /dev/null 2>&1; then
  echo 'chrony found'
  sudo sh -e "$RS_ATTACH_DIR/configure_chrony.sh" "${NTP_SERVERS//,/ }"
else
  echo 'systemd-timesyncd or chrony not found, ntpd is not yet supported.'
  exit 1
fi

echo 'Done'
