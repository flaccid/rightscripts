#! /bin/bash -e

if [ -z "$1" ]; then
  echo "Please provide a volume lineage name to snapshot."
  exit 1
fi

# path sanity
export PATH="$PATH:/usr/local/bin"

snapfound=0
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
  sudo /usr/local/bin/rsc --rl10 cm15 create "$cloud_href/volumes" \
    "volume[parent_volume_snapshot_href]=$href" \
    "volume[name]=$lineage"
else
  echo "No snapshot found stored with name, '$lineage', exiting."
  exit 1
fi

echo 'Volume created from snapshot.'
echo "Finished on $(date)"

# end
