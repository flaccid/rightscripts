#! /bin/bash -e

# usage: prune_volume_snapshot_lineage.rl10.bash <lineage_name> <age_keep_younger_than_in_hours>

if [ -z "$1" ]; then
  echo "Please provide a volume snapshot lineage name to prune."
  exit 1
fi

if [ -z "$2" ]; then
  echo "Please provide the volume snapshot age to prune in hours."
  exit 1
fi

# path sanity
export PATH="$PATH:/usr/local/bin"

lineage="$1"
age="$2"

# age is in hours
# 1d = 24
# 1w = 168
# 2w = 336
# 3w = 504
# 4w = 672

# if jq is not installed, lets install the linux binary
if ! type jq > /dev/null 2>&1; then
  echo 'Installing jq...'
  source /etc/profile.d/*proxy* > /dev/null 2>&1 || true
  curl -SsLk "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" | sudo tee /usr/local/bin/jq > /dev/null 2>&1
  sudo chmod +x /usr/local/bin/jq
  /usr/local/bin/jq --version
fi

echo "Started on $(date)"

echo "Querying instance self..."
instance_href=$(sudo /usr/local/bin/rsc --rl10 cm15 --x1 ':has(.rel:val("self")).href' index_instance_session /api/sessions/instance)
server_href=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 show --x1 ':has(.rel:val("parent")).href' "$instance_href")
cloud_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("cloud")).href')
echo "cloud href:      $cloud_href"
echo "instance href:   $instance_href"
echo "server href:     $server_href"

cloud_id=$(basename "$cloud_href")

# find the volume first by name
volume=$(sudo /usr/local/bin/rsc --rl10 cm15 index "/api/clouds/$cloud_id/volumes" "filter[]=name==$lineage")
snapshots_href=$(echo $volume | jq --raw-output '.[] .links | .[] | select(.rel | contains("volume_snapshots")) | .href')
volume_snapshots=$(sudo /usr/local/bin/rsc --rl10 cm15 index "$snapshots_href")
snap_count=$(echo "$volume_snapshots" | jq '. | length')

echo "Found $snap_count snapshots for volume name/lineage, '$lineage'"
echo "Will delete volume snapshots older than $age hours."

count=0
while [ $count -lt $snap_count ]; do
  vol=$(echo "$volume_snapshots" | jq --raw-output ".[$count]")
  href=$(echo $vol |  jq --raw-output '.links | .[] | select(.rel | contains("self")) | .href')
  now=$(date +%s)
  created_at=$(echo "$volume_snapshots" | jq --raw-output ".[$count] | .created_at")
  created=$(date -d "$created_at" +%s)
  diff=$(($now - $created))
  minutes=$(($diff / 60))
  hours=$(($diff / 3600))
  days=$(($diff / 86400))
  weeks=$(($diff / 604800))
  #echo "now: $now - then: $created"
  #echo "minutes: $minutes"
  #echo "hours: $hours"
  #echo "days: $days"
  #echo "weeks: $weeks"

  echo "processing $href"
  if [ "$hours" -gt "$age" ]; then
    echo " ==> age exceeded $age hour(s)"
    echo "     is $hours hour(s) old, deleting snapshot."
    echo "== destroying =="
    echo "$vol"
    if [ "$DRY_RUN" != 'true' ]; then
      sudo /usr/local/bin/rsc --rl10 cm15 destroy "$href"
    else
      echo 'dry run setting, skipping deletion.'
    fi
    echo "========"
  else
    echo " ==> not old enough yet ($hours hour(s) of age), keeping."
  fi
  let count=count+1
done

echo "Finished on $(date)"

echo 'Done.'
