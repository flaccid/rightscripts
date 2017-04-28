#!/bin/sh -e

: "${RENDEZVOUS_TOKEN:=$(date | md5 | cut -d' ' -f1)}"
: "${TUNNEL_URL:=wss://wstunnel10-1.rightscale.com}"
: "${NSX_ENDPOINT_URL:=http://nsx.local/}"

nohup /usr/local/bin/wstunnel cli \
  -token "$RENDEZVOUS_TOKEN" \
  -tunnel "$TUNNEL_URL" \
  -server "$NSX_ENDPOINT_URL" \
  -logfile /var/log/wstuncli-nsx.log > /var/log/wstuncli-nsx.log 2>&1&

sleep 5

head -n 50 /var/log/wstuncli-nsx.log
