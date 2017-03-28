#!/bin/bash -e

: "${NGROK_AUTH_TOKEN:=}"
: "${NGROK_LOG_FILE:=/tmp/ngrok.log}"
: "${NGROK_LOG_LEVEL:=info}"
: "${NGROK_REGION:=us}"
: "${NGROK_TUNNEL_PROTO:=tcp}"
: "${NGROK_TUNNEL_PORT:=22}"
: "${NGROK_DISABLE_PROXY_VARIABLES:=false}"
: "${NGROK_NOHUP_BACKGROUNDED:=true}"
: "${NGROK_KILL_EXISTING_PROCESSES:=true}"

[ -z "$NGROK_AUTH_TOKEN" ] && echo '$NGROK_AUTH_TOKEN not set, exiting!' && exit 1

# sane path
export PATH="$PATH:/usr/local/bin"

mkdir -p "$HOME/.ngrok2"

if [ "$NGROK_DISABLE_PROXY_VARIABLES" = 'true' ]; then
  unset http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY
fi

if ! type ngrok > /dev/null 2>&1; then
  echo 'installing ngrok...'

  if ! type unzip > /dev/null 2>&1; then
    sudo apt-get -y install unzip || sudo yum -y install unzip
  fi

  cd /tmp
  curl -Ss https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip > ngrok.zip
  unzip ngrok.zip
  sudo mkdir -p /usr/local/bin
  sudo mv ./ngrok /usr/local/bin/ngrok
  sudo chmod +x /usr/local/bin/ngrok
  rm ngrok.zip

  ngrok --version
fi

if [ "$NGROK_KILL_EXISTING_PROCESSES" = 'true' ]; then
  echo 'killing any existing ngrok processes found'
  if pgrep ngrok; then
    pgrep ngrok | xargs kill
  fi
fi

echo 'starting ngrok'

if [ "$NGROK_NOHUP_BACKGROUNDED" = 'true' ]; then
  nohup ngrok "$NGROK_TUNNEL_PROTO" "$NGROK_TUNNEL_PORT" \
    --authtoken "$NGROK_AUTH_TOKEN" \
    --log "$NGROK_LOG_FILE" \
    --log-level "$NGROK_LOG_LEVEL" \
    --region "$NGROK_REGION" \
      > /dev/null &

    sleep 5

    echo 'last 50 lines of log:'
    tail -n 50 "$NGROK_LOG_FILE"

    ngrok_tunnels=$(curl -Ss http://127.0.0.1:4040/api/tunnels)

    echo "$ngrok_tunnels"
else
  echo 'logging to standard out instead of log file'
  ngrok "$NGROK_TUNNEL_PROTO" "$NGROK_TUNNEL_PORT" \
    --authtoken "$NGROK_AUTH_TOKEN" \
    --log stdout \
    --log-level "$NGROK_LOG_LEVEL" \
    --region "$NGROK_REGION"
fi

echo 'Done.'
