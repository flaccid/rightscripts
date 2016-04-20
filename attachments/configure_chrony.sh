#! /bin/bash -e

# usage: configure_chrony.sh [nameserver nameserver..]

# configures chrony
# this script should be run as root

ntp_servers="$@"
[ -z "$ntp_servers" ] && ntp_servers=pool.ntp.org

# convert to array
read -a ntp_servers <<<$ntp_servers

echo "configuring to sync with: [$ntp_servers]"

# we assume that /etc/chrony.conf exists

# remove any servers already configured
sed -i '/^server /d' /etc/chrony.conf

# remove some undesirable comments
sed -i '/^# Use public servers from/d' /etc/chrony.conf
sed -i '/^# Please consider joining/d' /etc/chrony.conf

# add each server to top of config file
for s in "${ntp_servers[@]}"
do
   :
   sed -i "1s/^/server $s\n/" /etc/chrony.conf
done

type timedatectl > /dev/null 2>&1 && timedatectl set-ntp yes

echo 'restarting chronyd'
systemctl restart chronyd
systemctl status chronyd

chronyc activity
