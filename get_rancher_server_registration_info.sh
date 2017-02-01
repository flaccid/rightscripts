#! /bin/bash -e

# required inputs:
# $RANCHER_URL
# $RANCHER_ACCESS_KEY
# $RANCHER_SECRET_KEY
# $RANCHER_REGISTRATION_METHOD
# $RANCHER_SERVER_IDENTIFIER
# $RANCHER_REGISTRATION_ENVIRONMENT

: "${RANCHER_REGISTRATION_METHOD:=manual}"
: "${RANCHER_SERVER_IDENTIFIER:=default}"

sudo mkdir -p /usr/local/bin
sudo cp "$RS_ATTACH_DIR/rancher-get-host-registration-info.py" /usr/local/bin/
sudo chmod +x /usr/local/bin/rancher-get-host-registration-info.py

export RANCHER_URL
export RANCHER_ACCESS_KEY
export RANCHER_SECRET_KEY

# source proxy settings if needed
source /etc/profile.d/*proxy* > /dev/null 2>&1 || true

# if using discovery registration, update fstab first
if [ "$RANCHER_REGISTRATION_METHOD" = 'discovery' ]; then
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

  # get the rancher server (currently first found)
  rancher_instance_href=$(sudo /usr/local/bin/rsc cm15 --rl10 by_tag /api/tags/by_tag \
    'resource_type=instances' \
    'match_all=true' \
    "tags[]=rancher:server_identifier=$RANCHER_SERVER_IDENTIFIER" \
    'tags[]=rancher:server=true' \
    --xm '.links .href' | head -n1 | sed -e 's/^"//' -e 's/"$//')
  rancher_instance=$(sudo /usr/local/bin/rsc cm15 --rl10 show "$rancher_instance_href")

  # get private IP of the rancher server
  rancher_server_ip=$(echo "$rancher_instance" | jq --raw-output '.private_ip_addresses[]')

  # get the tags of the rancher server
  rancher_instance_tags=$(sudo /usr/local/bin/rsc cm15 --rl10 by_resource /api/tags/by_resource \
    "resource_hrefs[]=$rancher_instance_href" --pp)

  rancher_server_proto=$(echo "$rancher_instance_tags" | jq --raw-output '.[][][] | select(.name | index("rancher:proto")) .name' | cut -d = -f 2)
  rancher_server_hostname=$(echo "$rancher_instance_tags" | jq --raw-output '.[][][] | select(.name | index("rancher:endpoint_host")) .name' | cut -d = -f 2)

  # update fstab
  if grep -q "$rancher_server_hostname" /etc/hosts; then
    echo 'Updating host in fstab.'
    sudo sed -i "s/.*$rancher_server_hostname.*/$rancher_server_ip    $rancher_server_hostname/" /etc/hosts
  else
    echo 'Adding host to fstab.'
    echo "$rancher_server_ip    $rancher_server_hostname" | sudo tee -a /etc/hosts >/dev/null 2>&1
  fi

  grep "$rancher_server_hostname" /etc/hosts

  # we currently don't care if the ping fails
  ping -c 3 "$rancher_server_hostname" || true

  # if RANCHER_REGISTRATION_ENVIRONMENT is set; lets update the RANCHER_URL to be project-specific
  if [ ! -z "$RANCHER_REGISTRATION_ENVIRONMENT" ]; then
    project_id=$(rancher environment ls | grep "$RANCHER_REGISTRATION_ENVIRONMENT" | awk -F ' ' '{print $1}')
    # we currently assume that RANCHER_URL does not have a href with api version

    # support if the RANCHER_URL has a trailing or no trailing forward slash
    export RANCHER_URL="${RANCHER_URL%/}/v1/projects/$project_id"
  fi
fi

sudo -E /usr/local/bin/rancher-get-host-registration-info.py

echo 'Done.'
