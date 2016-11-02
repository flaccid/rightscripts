# service mgmt functions
if pidof systemd >/dev/null 2>&1; then
  # systemd
  initsys='systemd'
elif pidof /sbin/init >/dev/null 2>&1; then
  # sysvinit
  initsys='sysvinit'
  sudo apt-get -y install sysvinit-utils >/dev/null 2>&1 || sudo yum -y install sysvinit-tools >/dev/null 2>&1 || sudo apt-get -y install sysvinit-utils >/dev/null 2>&1 || true
else
  # currently unsupported
  initsys='unknown'
fi

# if docker system service is configured correctly, this shouldn't be needed
function wait_for_docker_daemon()
{
    echo 'Checking/waiting for docker service to be ready.'
    local i=0
    while true
    do
        if ! sudo systemctl is-active docker; then
          echo "Sleeping 10 seconds, waiting for Docker daemon to start."
          sleep 10
          i=$((i+1))
          if [ "$i" > 29 ]; then
            echo 'Service not active after 5mins, exiting!'
            exit 1
          fi
        else
          return
        fi
    done
}

docker_service() {
  case "$1" in
    status*)
      case "$initsys" in
        systemd*)
          systemctl status docker
        ;;
        sysvinit*)
          service docker status
        ;;
      esac
    ;;
    enable*)
      case "$initsys" in
        systemd*)
          # reload before also just in case of edge cases like 'access denied'
          sudo systemctl daemon-reload || true
          sudo systemctl enable docker
          sudo systemctl daemon-reload
        ;;
        sysvinit*)
          # we generally assume that other distros such as ubuntu enable it on install
          if type -P chkconfig > /dev/null 2>&1; then
            sudo chkconfig docker on
          fi

          # some distro releases might still have systemd (arggh ubuntu)
          if type -P systemctl > /dev/null 2>&1; then
            sudo systemctl daemon-reload || true
            sudo systemctl enable docker
            sudo systemctl daemon-reload
          fi
        ;;
      esac
    ;;
    start*)
      case "$initsys" in
        systemd*)
          sudo systemctl start docker
        ;;
        sysvinit*)
          if ! service docker status | grep 'start/running'; then
            sudo service docker start
          fi
        ;;
      esac
      # wait_for_docker_daemon
    ;;
    stop*)
      case "$initsys" in
        systemd*)
          sudo systemctl stop docker
        ;;
        sysvinit*)
          if service docker status | grep 'start/running'; then
            sudo service docker stop
          fi
        ;;
      esac
    ;;
    restart*)
      case "$initsys" in
        systemd*)
          sudo systemctl restart docker
        ;;
        sysvinit*)
        if ! service docker status | grep 'start/running'; then
          sudo service docker restart
        else
          sudo service docker start
        fi
        ;;
      esac
      # wait_for_docker_daemon
    ;;
  esac
}
