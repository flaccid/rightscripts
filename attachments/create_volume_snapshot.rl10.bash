#! /bin/bash -e

if [ -z "$1" ]; then
  echo "Please provide a volume lineage name to snapshot."
  exit 1
fi

# path sanity
export PATH="$PATH:/usr/local/bin"

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

echo "Querying instance self..."
instance_href=$(sudo /usr/local/bin/rsc --rl10 cm15 --x1 ':has(.rel:val("self")).href' index_instance_session /api/sessions/instance)
server_href=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 show --x1 ':has(.rel:val("parent")).href' "$instance_href")
cloud_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("cloud")).href')
datacenter_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("datacenter")).href')
echo "cloud href:      $cloud_href"
echo "instance href:   $instance_href"
echo "server href:     $server_href"
echo "datacenter href: $datacenter_href"

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
  echo 'Taking snapshot.'
  sudo /usr/local/bin/rsc --rl10 cm15 create "/api/clouds/$cloud_id/volume_snapshots" \
    "volume_snapshot[name]=$lineage-$(date +%Y%m%d%H%M%S)" \
    "volume_snapshot[description]=Snapshot taken on $(hostname -f)" \
    "volume_snapshot[parent_volume_href]=$href"
else
  echo "No volume found attached to instance with name, '$lineage', exiting."
  exit 1
fi

echo 'Snapshot creation complete.'

# end
