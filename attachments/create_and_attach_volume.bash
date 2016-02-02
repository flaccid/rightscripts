#! /bin/bash -e

: "${DOCKER_DIR_BLOCK_DEVICE:=/dev/sdb}"
: "${DOCKER_DIR_VOLUME_SIZE:=10}"
: "${DOCKER_DIR_VOLUME_NAME:=`hostname`-dockerdata}"
: "${DOCKER_DIR_VOLUME_TYPE_HREF:=}"
: "${DOCKER_DIR_VOLUME_SNAPSHOT_HREF:=}"
: "${DOCKER_DIR_SAS_DEVICE:=}"

# TODO: use --xh Location to get the location href returned

# when on vsphere, assign the sas device to the api for attachment
[ ! -z "$DOCKER_DIR_SAS_DEVICE" ] && DOCKER_DIR_BLOCK_DEVICE="$DOCKER_DIR_SAS_DEVICE"

echo "Querying instance self..."
instance_href=$(sudo /usr/local/bin/rsc --rl10 cm15 --x1 ':has(.rel:val("self")).href' index_instance_session /api/sessions/instance)
cloud_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("cloud")).href')
datacenter_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("datacenter")).href')
echo "cloud href:      $cloud_href"
echo "instance href:   $instance_href"
echo "datacenter href: $datacenter_href"

echo "Creating volume $DOCKER_DIR_VOLUME_SIZEGB volume..."
cmd="sudo /usr/local/bin/rsc --rl10 cm15 create --dump=debug "$cloud_href/volumes" \
  volume[name]=$DOCKER_DIR_VOLUME_NAME \
  volume[size]=$DOCKER_DIR_VOLUME_SIZE \
  volume[datacenter_href]=$datacenter_href"
[ ! -z "$DOCKER_DIR_VOLUME_TYPE_HREF" ] && cmd="$cmd 'volume[volume_type_href]=$DOCKER_DIR_VOLUME_TYPE_HREF'"
[ ! -z "$DOCKER_DIR_VOLUME_SNAPSHOT_HREF" ] && cmd="$cmd 'volume[parent_volume_snapshot_href]=$DOCKER_DIR_VOLUME_SNAPSHOT_HREF'"

api_result=$(eval "$cmd" 2>&1)

case "$api_result" in
  *"201 Created"*)
    volume_href=$(echo "$api_result" | grep 'Location:' | awk '/Location:/ { print $2 }' | tr -d '\r' | tr -d '\n')
    echo " volume, '$DOCKER_DIR_VOLUME_NAME' successfully created ($volume_href)."
  ;;
  *)
    echo "Volume creation FAILED: $api_result"
    exit 1
  ;;
esac

echo 'Attaching the volume...'
api_result=$(sudo /usr/local/bin/rsc --rl10 cm15 create --dump=debug "$cloud_href/volume_attachments" \
  volume_attachment[device]="$DOCKER_DIR_BLOCK_DEVICE" \
  volume_attachment[instance_href]="$instance_href" \
  volume_attachment[volume_href]="$volume_href" 2>&1)

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
