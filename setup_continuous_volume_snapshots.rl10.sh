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
: "${CONTINUOUS_SNAPSHOT_PRUNE_AGE:=30}"

# install attachment scripts
sudo mkdir -p /usr/local/bin
sudo cp "$RS_ATTACH_DIR/create_volume_snapshot.rl10.bash" /usr/local/bin/
sudo cp "$RS_ATTACH_DIR/prune_volume_snapshot_lineage.rl10.bash" /usr/local/bin/
sudo chmod +x /usr/local/bin/*.bash

job="$CONTINUOUS_SNAPSHOT_CRON_SCHEDULE    /usr/local/bin/create_volume_snapshot.rl10.bash $CONTINUOUS_SNAPSHOT_LINEAGE_NAME && /usr/local/bin/prune_volume_snapshot_lineage.rl10.bash $CONTINUOUS_SNAPSHOT_LINEAGE_NAME $CONTINUOUS_SNAPSHOT_PRUNE_AGE"
echo 'Cron job:'
echo "$job"

echo 'Updating crontab'
cat <(fgrep -i -v "create_volume_snapshot" <(crontab -l)) <(echo "$job") | crontab -

echo 'Done.'
