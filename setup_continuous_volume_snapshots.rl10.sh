#!/bin/bash -e

# RightScript: Setup continuous volume snapshots rl10

# Inputs:
# CONTINUOUS_SNAPSHOT_CRON_SCHEDULE
# CONTINUOUS_SNAPSHOT_LINEAGE_NAME
# CONTINUOUS_SNAPSHOT_PRUNE_AGE

# Attachments:
# create_volume_snapshot.rl10.bash
# prune_volume_snapshot_lineage.rl10.bash

: "${CONTINUOUS_SNAPSHOT_CRON_SCHEDULE:=30 2 * * *}"
: "${CONTINUOUS_SNAPSHOT_LINEAGE_NAME:=}"
: "${CONTINUOUS_SNAPSHOT_PRUNE_AGE:=672}"

# age is in hours
# 1d = 24
# 1w = 168
# 2w = 336
# 3w = 504
# 4w = 672

# install attachment scripts
sudo mkdir -p /usr/local/bin
sudo cp "$RS_ATTACH_DIR/create_volume_snapshot.rl10.bash" /usr/local/bin/
sudo cp "$RS_ATTACH_DIR/prune_volume_snapshot_lineage.rl10.bash" /usr/local/bin/
sudo chmod +x /usr/local/bin/*.bash

# create the log file
sudo touch "/var/log/cron-snapshots-$CONTINUOUS_SNAPSHOT_LINEAGE_NAME.log"
sudo chown root:root "/var/log/cron-snapshots-$CONTINUOUS_SNAPSHOT_LINEAGE_NAME.log"
sudo chmod 660 "/var/log/cron-snapshots-$CONTINUOUS_SNAPSHOT_LINEAGE_NAME.log"

job="$CONTINUOUS_SNAPSHOT_CRON_SCHEDULE    (/usr/local/bin/create_volume_snapshot.rl10.bash $CONTINUOUS_SNAPSHOT_LINEAGE_NAME; /usr/local/bin/prune_volume_snapshot_lineage.rl10.bash $CONTINUOUS_SNAPSHOT_LINEAGE_NAME $CONTINUOUS_SNAPSHOT_PRUNE_AGE) >> /var/log/cron-snapshots-$CONTINUOUS_SNAPSHOT_LINEAGE_NAME.log 2>&1"
echo 'Cron job:'
echo "$job"

# in case host /etc/sudoers configures tty requirement (cron has no tty)
sudo sed -i '/Defaults \+requiretty/s/^/#/' /etc/sudoers

echo 'Updating crontab'
cat <(fgrep -i -v "create_volume_snapshot" <(crontab -l)) <(echo "$job") | sudo crontab -u root -

echo 'Done.'
