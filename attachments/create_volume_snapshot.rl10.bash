#! /bin/bash -e

: "${SNAPSHOT_FSFREEZE_MOUNTPOINT:=}"

if [ -z "$1" ]; then
  echo "Please provide a volume lineage name to snapshot."
  exit 1
fi

# path sanity
export PATH="$PATH:/usr/local/bin"

freeze(){
  echo "freezing mountpoint $1" && fsfreeze -f "$1"
}
unfreeze(){
  echo "un-freezing mountpoint $1" && fsfreeze -u "$1"
}

volfound=0
lineage="$1"

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

volumes=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 index --xm ".href" "$instance_href/volume_attachments" | grep "/volumes/" | tr -d '"')

mapfile -t vols <<< "$volumes"

for v in "${vols[@]}"
do
  echo "Looking up $v"
  vol=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 show "$v")
  name=$(echo "$vol" | jq --raw-output .name)
  if [ "$name" = "$lineage" ]; then
    volfound=1
    href="$v"
    break
  fi
done

if [ "$volfound" -eq 1 ]; then
  echo 'Volume found.'
  echo "$vol"

  # freeze the mountpoint if specified
  [ ! -z "$SNAPSHOT_FSFREEZE_MOUNTPOINT" ] && freeze "$SNAPSHOT_FSFREEZE_MOUNTPOINT"

  echo 'Taking snapshot.'
  api_result=$(sudo /usr/local/bin/rsc -v --rl10 cm15 create "/api/clouds/$cloud_id/volume_snapshots" \
    "volume_snapshot[name]=$lineage-$(date +%Y%m%d%H%M%S)" \
    "volume_snapshot[description]=Snapshot taken on $(hostname -f)" \
    "volume_snapshot[parent_volume_href]=$href" 2>&1)
  echo "$api_result"
  snapshot_href=$(echo "$api_result" | grep Location | awk '{ print $2 }')
else
  echo "No volume found attached to instance with name, '$lineage', exiting."
  exit 1
fi

if [ ! -z "$SNAPSHOT_FSFREEZE_MOUNTPOINT" ]; then
  # currently we only wait for snapshot to complete when freezing
  echo "waiting for $snapshot_href to complete"
  state='not-ready'
  i=1
  while [ "$state" != 'available' ]; do
    [ "$i" -gt 1800 ] && unfreeze "$SNAPSHOT_FSFREEZE_MOUNTPOINT" && echo 'timeout waiting for snapshot to complete!' && exit 1
    state=$(sudo /usr/local/bin/rsc --rl10 cm15 show $snapshot_href | jq -r .state | tr -d '[:space:]')
    echo "(poll $i) $state..."
    i=$((i + 1))
    sleep 3
  done
  echo 'snapshot is now complete.'
  unfreeze "$SNAPSHOT_FSFREEZE_MOUNTPOINT"
fi

echo 'snapshot creation complete'

echo "Finished on $(date)."

# end
