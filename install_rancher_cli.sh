#! /bin/sh -e

: "${RANCHER_CLI_INSTALL:=true}"
: "${RANCHER_CLI_TARBALL_URL:=https://github.com/rancher/cli/releases/download/v0.4.1/rancher-linux-amd64-v0.4.1.tar.gz}"

if [ ! "$RANCHER_CLI_INSTALL" = 'true' ]; then
  echo '$RANCHER_CLI_INSTALL not set to true, skippping.'
  exit 0
fi

tmpdir=$(mktemp -d /tmp/rcli.XXXXXX)
cd "$tmpdir"

echo 'Downloading Rancher CLI...'
curl -LSs "$RANCHER_CLI_TARBALL_URL" > ./rancher-cli.tar.gz

echo 'Unarchiving Rancher CLI...'
tar zxvf ./rancher-cli.tar.gz
cd rancher-v0*

sudo mkdir -p /usr/local/bin

echo 'Copying binary to /usr/local/bin'
sudo cp -v ./rancher /usr/local/bin/
sudo chmod +x /usr/local/bin/rancher

rm -rfv "$tmpdir"

echo 'Done.'
