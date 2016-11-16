#! /bin/bash -e

: "${DOCKER_DIR_BLOCK_DEVICE:=/dev/sdc}"
: "${DOCKER_DIR_VOLUME_SIZE:=10}"
: "${DOCKER_DIR_VOLUME_NAME:=$(hostname)-dockerdata}"
: "${DOCKER_DIR_VOLUME_TYPE_HREF:=}"
: "${DOCKER_DIR_VOLUME_SNAPSHOT_HREF:=}"
: "${DOCKER_DIR_SAS_DEVICE:=}"

# TODO: use --xh Location to get the location href returned

# when on vsphere, assign the sas device to the api for attachment
[ ! -z "$DOCKER_DIR_SAS_DEVICE" ] && DOCKER_DIR_BLOCK_DEVICE="$DOCKER_DIR_SAS_DEVICE"

echo "Querying instance self..."
instance_href=$(sudo /usr/local/bin/rsc --rl10 cm15 --x1 ':has(.rel:val("self")).href' index_instance_session /api/sessions/instance)
server_href=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 show --x1 ':has(.rel:val("parent")).href' "$instance_href")
cloud_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("cloud")).href')
# not all clouds have 'datacenters'
datacenter_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("datacenter")).href' 2>/dev/null || true)
placement_group_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("placement_group")).href')
cloud_type=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$cloud_href" --x1 ".cloud_type")
echo "cloud href:      $cloud_href"
echo "instance href:   $instance_href"
echo "server href:     $server_href"
echo "datacenter href: $datacenter_href"
echo "placement group href: $placement_group_href"
echo "cloud type: $cloud_type"
echo

# construct the volume creation command
# name and size are basically the only two common params between all clouds
cmd="sudo /usr/local/bin/rsc --rl10 cm15 create --dump=debug $cloud_href/volumes \
  'volume[name]=$DOCKER_DIR_VOLUME_NAME' \
  'volume[size]=$DOCKER_DIR_VOLUME_SIZE'"

# any other params not found to be empty, append to the command
[ ! -z "$datacenter_href" ] && cmd="$cmd 'volume[datacenter_href]=$datacenter_href'"
[ ! -z "$placement_group_href" ] && cmd="$cmd 'volume[placement_group_href]=$placement_group_href'"
[ ! -z "$DOCKER_DIR_VOLUME_TYPE_HREF" ] && cmd="$cmd 'volume[volume_type_href]=$DOCKER_DIR_VOLUME_TYPE_HREF'"
[ ! -z "$DOCKER_DIR_VOLUME_SNAPSHOT_HREF" ] && cmd="$cmd 'volume[parent_volume_snapshot_href]=$DOCKER_DIR_VOLUME_SNAPSHOT_HREF'"

echo "Creating new ${DOCKER_DIR_VOLUME_SIZE}GB volume..."
echo "> $cmd"
api_result=$(eval "$cmd" 2>&1 || true)

case "$api_result" in
  *"201 Created"*)
    volume_href=$(echo "$api_result" | grep 'Location:' | awk '/Location:/ { print $2 }' | tr -d '\r' | tr -d '\n')
    echo "Volume, '$DOCKER_DIR_VOLUME_NAME' successfully created ($volume_href)."
  ;;
  *)
    echo "Volume creation FAILED: $api_result"
    exit 1
  ;;
esac

# corner case for GCE which doesn’t like full device paths/names but only wants the short name
[[ "$cloud_href" = '/api/clouds/2175' ]] && DOCKER_DIR_BLOCK_DEVICE=$(echo "$DOCKER_DIR_BLOCK_DEVICE" | awk -F'[=/]' '{print $3}')

# corner case for Azure where it needs iscsi device instead of linux logical device name
[[ "$cloud_type" == *"azure"* ]] && DOCKER_DIR_BLOCK_DEVICE='01'

echo 'Attaching the volume...'
cmd="sudo /usr/local/bin/rsc --rl10 cm15 create --dump=debug $cloud_href/volume_attachments \
  volume_attachment[device]=$DOCKER_DIR_BLOCK_DEVICE \
  volume_attachment[instance_href]=$instance_href \
  volume_attachment[volume_href]=$volume_href"
echo "> $cmd"
api_result=$(eval "$cmd" 2>&1 || true)

case "$api_result" in
  *"201 Created"*)
    volume_attchment_href=$(echo "$api_result" | grep 'Location:' | awk '/Location:/ { print $2 }' | tr -d '\r' | tr -d '\n')
  ;;
  *)
    echo "Volume attachment creation FAILED: $api_result"
    exit 1
  ;;
esac

echo 'Waiting for the volume to be attached...'
while sleep 5s; do
  state=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$volume_attchment_href" --x1 .state)
  echo "($state)"
  if [ "$state" = 'attached' ]; then
    break
  fi
done

echo 'Done.'
