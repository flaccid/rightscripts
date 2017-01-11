#! /bin/sh -e

: "${RANCHER_COMPOSE_INSTALL:=true}"
: "${RANCHER_COMPOSE_TARBALL_URL:=https://github.com/rancher/rancher-compose/releases/download/v0.8.2/rancher-compose-linux-amd64-v0.8.2.tar.gz}"

if [ ! "$RANCHER_COMPOSE_INSTALL" = 'true' ]; then
  echo '$RANCHER_COMPOSE_INSTALL not set to true, skippping.'
  exit 0
fi

tmpdir=$(mktemp -d /tmp/rc.XXXXXX)
cd "$tmpdir"

echo 'Downloading rancher-compose...'
curl -LSs "$RANCHER_COMPOSE_TARBALL_URL" > ./rancher-compose.tar.gz

echo 'Unarchiving rancher-compose...'
tar zxvf ./rancher-compose.tar.gz
cd rancher-compose-v0*

sudo mkdir -p /usr/local/bin

echo 'Copying binary to /usr/local/bin'
sudo cp -v ./rancher-compose /usr/local/bin/
sudo chmod +x /usr/local/bin/rancher-compose

rm -rfv "$tmpdir"

echo 'Done.'
