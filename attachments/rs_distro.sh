#! /bin/sh

set +e

# ensure some sane paths
export PATH="$PATH:/usr/local/bin:/usr/bin:/usr/sbin"

if [ -e /etc/redhat-release ]; then
  if grep -i 'atomic host' /etc/redhat-release >/dev/null 2>&1; then
    distro=atomichost
  elif grep -i 'red hat' /etc/redhat-release | grep -i enterprise > /dev/null 2>&1; then
    distro=redhatenterpriseserver
  elif grep -i 'centos' /etc/redhat-release >/dev/null 2>&1; then
    distro=centos
  fi
elif type lsb_release >/dev/null 2>&1; then
  if lsb_release -d | grep -i ubuntu >/dev/null 2>&1; then
    distro=ubuntu
  elif lsb_release -d | grep -i debian >/dev/null 2>&1; then
    distro=debian
  fi
else
  distro=unknown
fi

export RS_DISTRO="$distro"
