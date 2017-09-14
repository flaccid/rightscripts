#! /bin/bash -e

: "${SNAPSHOT_RESTORE_LINEAGE_NAME:=}"
: "${SNAPSHOT_RESTORE_ATTACH:=true}"
: "${SNAPSHOT_RESTORE_MOUNTPOINT:=}"
: "${SNAPSHOT_RESTORE_BLOCK_DEVICE=/dev/sdd}"

if [ -z "$SNAPSHOT_RESTORE_LINEAGE_NAME" ]; then
  echo 'Please provide a $SNAPSHOT_RESTORE_LINEAGE_NAME to restore from.'
  exit 1
fi

# path sanity
export PATH="$PATH:/usr/local/bin"

snapfound=0
lineage="$SNAPSHOT_RESTORE_LINEAGE_NAME"

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
cloud_type=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$cloud_href" --x1 ".cloud_type")
echo "cloud href:      $cloud_href"
echo "instance href:   $instance_href"
echo "server href:     $server_href"
echo "cloud type:      $cloud_type"
cloud_id=$(basename "$cloud_href")

snapshots=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 index --xm ".href" "$cloud_href/volume_snapshots" | grep "/volume_snapshots/" | grep -v recurring | tr -d '"')

mapfile -t snaps <<< "$snapshots"

for s in "${snaps[@]}"
do
  snap=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 show "$s")
  name=$(echo "$snap" | jq --raw-output .name)
  if [ "$name" = "$lineage" ]; then
    snapfound=1
    href="$s"
    echo "Found snapshot: $lineage"
    break
  fi
done

if [ "$snapfound" -eq 1 ]; then
  echo "Restoring from snapshot: $lineage"
  echo 'Creating volume...'
  api_result=$(sudo /usr/local/bin/rsc --rl10 --dump=debug cm15 create "$cloud_href/volumes" \
    "volume[parent_volume_snapshot_href]=$href" \
    "volume[name]=$lineage" 2>&1)
  echo "$api_result"

  case "$api_result" in
    *"201 Created"*)
      volume_href=$(echo "$api_result" | grep 'Location:' | awk '/Location:/ { print $2 }' | tr -d '\r' | tr -d '\n')
      echo "$volume_href"
    ;;
    *)
      echo "Volume creation FAILED: $api_result"
      exit 1
    ;;
  esac

else
  echo "No snapshot found stored with name, '$lineage', exiting."
  exit 1
fi

echo 'Volume created from snapshot.'
# corner case for GCE which doesn’t like full device paths/names but only wants the short name
[[ "$cloud_href" = '/api/clouds/2175' ]] && SNAPSHOT_RESTORE_BLOCK_DEVICE=$(echo "$SNAPSHOT_RESTORE_BLOCK_DEVICE" | awk -F'[=/]' '{print $3}')

# corner case for Azure where it needs iscsi device instead of linux logical device name
if [[ "$cloud_type" == *"azure"* ]]; then
  volume_attachment_device='01'
else
  volume_attachment_device="$SNAPSHOT_RESTORE_BLOCK_DEVICE"
fi

echo 'Attaching the volume...'
api_result=$(sudo /usr/local/bin/rsc --rl10 cm15 create --dump=debug "$cloud_href/volume_attachments" \
  volume_attachment[device]="$volume_attachment_device" \
  volume_attachment[instance_href]="$instance_href" \
  volume_attachment[volume_href]="$volume_href" 2>&1)
echo "$api_result"

case "$api_result" in
  *"201 Created"*)
    volume_attachment_href=$(echo "$api_result" | grep 'Location:' | awk '/Location:/ { print $2 }' | tr -d '\r' | tr -d '\n')
    echo "$volume_attachment_href"
  ;;
  *)
 echo "Volume attachment creation FAILED: $api_result"
 exit 1
  ;;
esac

echo 'Waiting for the volume to be attached...'
while sleep 5s; do
  state=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$volume_attachment_href" --x1 .state)
  echo "($state)"
  if [ "$state" = 'attached' ]; then
    break
  fi
done

echo "Waiting for the disk's block device special to be available..."
state='not-found'
while sleep 5s; do
  [ -e "$SNAPSHOT_RESTORE_BLOCK_DEVICE" ] && state='found'
  echo "($state)"
  if [ "$state" = 'found' ]; then
    break
  fi
done

if [ ! -z "$SNAPSHOT_RESTORE_MOUNTPOINT" ]; then
  echo "Mounting to $SNAPSHOT_RESTORE_MOUNTPOINT ..."
  sudo mkdir -p "$SNAPSHOT_RESTORE_MOUNTPOINT"
  sudo mount "$SNAPSHOT_RESTORE_BLOCK_DEVICE" "$SNAPSHOT_RESTORE_MOUNTPOINT"
fi

echo 'Done.'
echo "Finished on $(date)"

# end
