#!/bin/bash -e

# creates a wstunnel
# e.g.
# sudo http_proxy=http://localhost:8080/ \
#   RENDEZVOUS_TOKEN=superebde4c49ef5d7a2f9c3b642040f \
#   SERVER_URL=http://localhost/ \
#     ./create_wstunnel.sh

: "${RENDEZVOUS_TOKEN:=$(date | md5 | cut -d' ' -f1)}"
: "${TUNNEL_URL:=wss://wstunnel10-1.rightscale.com}"
: "${SERVER_URL:=https://www.google.com/}"
: "${WSTUNNEL_LOG_FILE:=/var/log/wstunnel-${RENDEZVOUS_TOKEN:0:7}.log}"

nohup /usr/local/bin/wstunnel cli \
  -token "$RENDEZVOUS_TOKEN" \
  -tunnel "$TUNNEL_URL" \
  -server "$SERVER_URL" \
  -logfile "$WSTUNNEL_LOG_FILE" > "$WSTUNNEL_LOG_FILE" 2>&1&

sleep 5

head -n 50 "$WSTUNNEL_LOG_FILE"
