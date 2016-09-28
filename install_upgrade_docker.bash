#! /bin/bash -e

# Inputs:
# $DOCKER_UPGRADE           Whether to upgrade Docker (true|false).
# $DOCKER_HTTPS_PROXY       https_proxy URL for the Docker daemon.
# $DOCKER_NO_PROXY          no_proxy URL for the Docker daemon.
# $DOCKER_HTTP_PROXY        http_proxy URL for the Docker daemon.
# $DOCKER_VERSION           The version of Docker to install from the upstream official repository.
# $DOCKER_SKIP_ON_DETECT    If the docker command is found, skip Docker installation.
# $DOCKER_DAEMON_JSON       The JSON content for the Docker daemon configuration file.
# $DOCKER_USER_LIMITS       User limits not already declared by upstream Docker systemd unit file.

# Upstream documentation:
# https://docs.docker.com/engine/admin/systemd
# https://docs.docker.com/v1.10/engine/reference/commandline/daemon/#daemon-configuration-file

# systemd notes:
# Proxy settings do need to be set via drop-in as it cannot be done with `daemon.json`.

. "$RS_ATTACH_DIR/docker_service.sh"
. "$RS_ATTACH_DIR/rs_distro.sh"

if [ "$RS_DISTRO" = 'atomichost' ]; then
  echo 'Red Hat Enterprise Linux Atomic Host not yet supported, but will exit gracefully.'
  exit 0
fi

# defaults
: "${DOCKER_SKIP_ON_DETECT:=true}"
: "${DOCKER_UPGRADE:=true}"
: "${DOCKER_HTTP_PROXY:=}"
: "${DOCKER_HTTPS_PROXY:=}"
: "${DOCKER_NO_PROXY:=}"
: "${DOCKER_VERSION:=}"
: "${DOCKER_DAEMON_JSON:=}"
: "${DOCKER_USER_LIMITS:=}"

# no need to restart docker yet
restart_docker=0

if type docker >/dev/null 2>&1; then
  if [ "$DOCKER_SKIP_ON_DETECT" = 'true' ]; then
    echo '$DOCKER_SKIP_ON_DETECT set to true, skipping.'
    exit 0
  fi
fi

# key ensurance heh
type -P apt-get > /dev/null && sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com FE85409EEAB40ECCB65740816AF0E1940624A220 >/dev/null 2>&1 || true

if type apt-get >/dev/null 2>&1; then
  echo 'Updating package list...'
  sudo apt-get -y update
fi

# install wget
if ! type wget >/dev/null 2>&1; then
  echo 'Installing wget...'
  if type apt-get >/dev/null 2>&1; then
    sudo apt-get -y install wget
  elif type yum >/dev/null 2>&1; then
    sudo yum -y install wget
  fi
fi

set_daemon_json() {
  if [ ! -z "$DOCKER_DAEMON_JSON" ]; then
    echo 'Populate daemon configuration file.'
    echo '== /etc/docker/daemon.json =='
    echo "$DOCKER_DAEMON_JSON" | sudo tee /etc/docker/daemon.json
    echo '===='
  fi
}

install_docker() {
  # make sure we have docker supported with selinux e.g. on ec2
  # this needs to be done before installing the docker-engine package
  if grep -i enterprise /etc/redhat-release > /dev/null 2>&1; then
    sudo yum-config-manager --enable "Red Hat Enterprise Linux Server 7 Extra(RPMs)"
  fi
  # this is now looked after by the upstream script from docker
  #if type -P yum > /dev/null 2>&1; then
  #  sudo yum -y install docker-selinux
  #fi

  if type apt-get >/dev/null 2>&1; then
    # these can only help if available
    sudo apt-get -y install apparmor lxc aufs-tools >/dev/null 2>&1 || true
    sudo modprobe aufs >/dev/null 2>&1 || true
  fi

  set_daemon_json

  echo 'Installing docker...'
  if [ ! -z "$DOCKER_VERSION" ]; then
    curl -Ss https://get.docker.com/ > /tmp/install.docker.sh
    chmod +x /tmp/install.docker.sh

    # replace the package name with docker-engine
    sed -i -e "s/apt-get install -y -q docker-engine/apt-get install -y -q docker-engine=$DOCKER_VERSION/" /tmp/install.docker.sh
    sed -i -e "s/yum -y -q install docker-engine/yum -y -q install docker-engine-$DOCKER_VERSION/" /tmp/install.docker.sh
    sed -i -e "s/dnf -y -q install docker-engine/dnf -y -q install docker-engine-$DOCKER_VERSION/" /tmp/install.docker.sh

    /tmp/install.docker.sh
  else
    sudo wget -qO- https://get.docker.com/ | sh
  fi
}

remove_docker() {
  echo 'Removing existing docker install...'
  if type apt-get >/dev/null 2>&1; then
    sudo apt-get -y remove --purge lxc-docker* 'docker*'
    sudo apt-get -y autoremove
  elif type yum >/dev/null 2>&1; then
    sudo yum -y remove 'docker*'
  fi
}

set_docker_proxy_sysv() {
  md5_before=($(md5sum /etc/default/docker))

  if [[ ! -z "$DOCKER_HTTP_PROXY" ]]; then
    echo "Updating conf with http proxy ($DOCKER_HTTP_PROXY)..."
    sudo sed -i "/export http_proxy/c\export http_proxy=\"$DOCKER_HTTP_PROXY\"" /etc/default/docker
    restart_docker=1
  else
    sudo sed -i '/export http_proxy/d' /etc/default/docker
  fi

  if [[ ! -z "$DOCKER_HTTPS_PROXY" ]]; then
    echo "Updating conf with https proxy ($DOCKER_HTTPS_PROXY)..."
    sudo sed -i "/export https_proxy=/a export https_proxy=\"$DOCKER_HTTPS_PROXY\"" /etc/default/docker
    restart_docker=1
  else
    sudo sed -i '/export https_proxy/d' /etc/default/docker
  fi

  if [[ ! -z "$DOCKER_NO_PROXY" ]]; then
    echo "Updating conf with no proxy ($DOCKER_NO_PROXY)..."
    sudo sed -i "/export http_proxy=/a export no_proxy=\"$DOCKER_NO_PROXY\"" /etc/default/docker
    restart_docker=1
  else
    sudo sed -i '/export no_proxy/d' /etc/default/docker
  fi

  if ! md5sum /etc/default/docker | grep "$md5_before"; then
    restart_docker=1
  fi

  [ "$restart_docker" = 1 ] && docker_service restart
}

set_docker_proxy_systemd() {
  # systemd docker proxy configuration
  sudo mkdir -p /etc/systemd/system/docker.service.d

  if [[ ! -z "$DOCKER_HTTP_PROXY" ]]; then
    env="\"HTTP_PROXY=$DOCKER_HTTP_PROXY\""
  fi

  if [[ ! -z "$DOCKER_HTTPS_PROXY" ]]; then
    env="\"HTTP_PROXY=$DOCKER_HTTPS_PROXY\""
  fi

  if [[ ! -z "$DOCKER_NO_PROXY" ]]; then
    env="$env \"NO_PROXY=$DOCKER_NO_PROXY\""
  fi

  sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<EOF
[Service]
Environment=$env
EOF

  sudo systemctl daemon-reload

  docker_service start

  echo 'Verifying config:'
  sudo systemctl show docker --property Environment
}

docker_rs_users() {
  if grep rightlink /etc/passwd; then
    sudo usermod -aG docker rightlink
  elif grep rightlink /etc/passwd; then
    sudo usermod -aG docker rightscale
  else
    sudo usermod -aG docker root
  fi
}

if type docker >/dev/null 2>&1; then
  if [ "$DOCKER_UPGRADE" = 'true' ]; then
    remove_docker
    install_docker
  else
    echo '$DOCKER_UPGRADE not set to true, skipping.'
    echo 0
  fi
else
  install_docker
fi

echo 'Configuring any custom Docker daemon user limits'
if [ -n "${DOCKER_USER_LIMITS}" ]; then
    # ensure drop-in folder exists
    sudo mkdir -p /etc/systemd/system/docker.service.d

    # create a drop-in file using a newline separated variable of custom user limits
    sudo tee /etc/systemd/system/docker.service.d/user-limits.conf > /dev/null <<EOF
[Service]
${DOCKER_USER_LIMITS}
EOF
fi

if [[ ! -z "$DOCKER_HTTP_PROXY" ]] || [[ ! -z "$DOCKER_HTTPS_PROXY" ]] || [[ ! -z "$DOCKER_NO_PROXY" ]]; then
  # check for systemd first as preferred as some systems will also have /etc/default/docker
  if type systemctl >/dev/null 2>&1 && [ -e /lib/systemd/system/docker.service ]; then
    echo 'Setting proxy for systemd'
    set_docker_proxy_systemd
  elif [ -e /etc/default/docker ]; then
    echo 'Setting proxy for docker'
    set_docker_proxy_sysv
  fi
fi

echo 'Enabling the docker system service...'
docker_service enable

echo 'Starting/restarting docker service...'
docker_service restart

docker_rs_users

echo 'Done.'
