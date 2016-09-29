#! /bin/bash -e

# Register with Rancher server

# Inputs:

# $CATTLE_HOST_LABELS
# $RANCHER_AGENT_TAG

: "${RANCHER_HOST_EXTERNAL_DNS_IP:=}"

# https://github.com/rancher/rancher/issues/1370
# Note that due this bug you may need to action the following if
# receiving 401 Unauthorized we a previously registered host:
sudo rm -Rf /var/lib/rancher/state

: "${RANCHER_AGENT_TAG:=v1.0.1}"

# currently we assume the device name will always reside in the 5th column
iface=$(ip route | awk '/default/ { print $5 }')

# we do this because currently (-rwx--x--x 1 root root)
private_ip=`ifconfig $iface | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'`

env=$(sudo cat /var/spool/rancher/registration.sh)
eval "$env"

# pre-add in the external DNS label if provided
if [ ! -z "$RANCHER_HOST_EXTERNAL_DNS_IP" ]; then
  CATTLE_HOST_LABELS="$CATTLE_HOST_LABELS&io.rancher.host.external_dns_ip=$RANCHER_HOST_EXTERNAL_DNS_IP"
fi

if [ ! -z "$CATTLE_HOST_LABELS" ]; then
  labels=(${CATTLE_HOST_LABELS//&/ })

  echo 'Labels will be added with registration of host:'
  for label in "${labels[@]}"
  do
    echo "    $label"
  done
  cattle_labels="-e CATTLE_HOST_LABELS=$CATTLE_HOST_LABELS"
fi

set -x

echo 'Running rancher/agent container.'

sudo docker run -d --privileged \
  -e CATTLE_AGENT_IP="${private_ip}" \
  $cattle_labels \
  -v /var/run/docker.sock:/var/run/docker.sock "rancher/agent:$RANCHER_AGENT_TAG" \
  "$CATTLE_URL/scripts/$CATTLE_REGISTRATION_SECRET_KEY"

{ set +x; } 2>/dev/null

echo 'Done.'
