#! /bin/bash -e

# TODO: overlayfs support

source "$RS_ATTACH_DIR/rs_distro.sh"

if [ "$RS_DISTRO" = 'atomichost' ]; then
  echo 'Red Hat Enterprise Linux Atomic Host not yet supported, but will exit gracefully.'
  exit 0
fi

# used by create_and_attach_volume.bash:
# $DOCKER_DIR_VOLUME_SIZE
# $DOCKER_DIR_VOLUME_NAME
# $DOCKER_DIR_VOLUME_TYPE_HREF
# $DOCKER_DIR_VOLUME_SNAPSHOT_HREF
# $DOCKER_DIR_SAS_DEVICE

: "${DOCKER_DIR_BLOCK_DEVICE:=/dev/sdc}"
: "${DOCKER_DIR_INITIALISE:=true}"
: "${DOCKER_DIR_VOLUME_SIZE:=10}"
: "${DOCKER_DIR_VOLUME_NAME:=`hostname`-dockerdata}"
: "${DOCKER_DIR_VOLUME_FSTYPE:=btrfs}"
: "${DOCKER_DIR_VOLUME_PROTECTION:=false}"
: "${DOCKER_DIR_SAS_DEVICE:=}"

# exit if protection is on and volume is not initialised
if [ "$DOCKER_DIR_PROTECTION" = 'true' ]; then
  if mount | grep /var/lib/docker | grep "$DOCKER_DIR_BLOCK_DEVICE"; then
    echo '$DOCKER_DIR_PROTECTION = true and volume is currently mounted, skipping.'
    exit 0
  fi
  if blkid | grep "$DOCKER_DIR_BLOCK_DEVICE" | grep TYPE; then
    # assume volume is already formatted/initialised
    echo '$DOCKER_DIR_PROTECTION = true and volume appears initialised, skipping.'
    exit 0
  fi
fi

# exit if not intended to intialise
if ! [ "$DOCKER_DIR_INITIALISE" = 'true' ]; then
  echo '$DOCKER_DIR_INITIALISE != true, skipping.'
  exit 0
fi

# if the block special file doesn't exist, create and attach a new volume
if [ ! -e "$DOCKER_DIR_BLOCK_DEVICE" ]; then
  export DOCKER_DIR_VOLUME_SIZE
  export DOCKER_DIR_VOLUME_NAME
  export DOCKER_DIR_VOLUME_TYPE_HREF
  export DOCKER_DIR_VOLUME_SNAPSHOT_HREF
  export DOCKER_DIR_SAS_DEVICE
  sudo chmod +x "$RS_ATTACH_DIR/create_and_attach_volume.bash"
  ! "$RS_ATTACH_DIR/create_and_attach_volume.bash" && exit 1
fi

# a small sleep to let the block device settle, just to be sure
sleep 5

# install required packages
packages=('util-linux')
case $DOCKER_DIR_VOLUME_FSTYPE in
btrfs)
  if type yum > /dev/null 2>&1; then
    packages+=('btrfs-progs')
  else
    packages+=('btrfs-tools')
  fi
  ;;
aufs)
  if ! type yum > /dev/null 2>&1; then
    linux_extras=$(echo linux-image-extra-$(uname -r))
    packages+=('aufs-tools' "$linux_extras")
  fi
  ;;
esac
echo 'Installing any needed packages...'
if type yum > /dev/null 2>&1; then
  sudo yum -y install "${packages[@]}"
elif type apt-get > /dev/null 2>&1; then
  sudo apt-get -y install "${packages[@]}"
fi

. "$RS_ATTACH_DIR/docker_service.sh"

# stop docker daemon
echo 'Stopping Docker...'
docker_service stop
sleep 1

# unmount the volume if already mounted
if mount | grep "$DOCKER_DIR_BLOCK_DEVICE"; then
  echo 'Volume is currently mounted, unmounting...'
  sudo umount "$DOCKER_DIR_BLOCK_DEVICE"
fi

# clear contents of the mountpoint, if any
echo 'Clearing /var/lib/docker folder...'
if [ -e /var/lib/docker ]; then
  sudo rm -Rf /var/lib/docker
fi
sudo mkdir -p /var/lib/docker
# Relaxing permissions #
sudo chmod +rx /var/lib/docker

# initialise volume
echo 'Initialising volume...'
sudo wipefs "$DOCKER_DIR_BLOCK_DEVICE"
sleep 1
if [ "$DOCKER_DIR_VOLUME_FSTYPE" = 'btrfs' ]; then
  mkfs_cmd='mkfs.btrfs -f'
else
  mkfs_cmd='mkfs.ext4'
fi
sudo $mkfs_cmd "$DOCKER_DIR_BLOCK_DEVICE"

# add volume to fstab
if ! grep "$DOCKER_DIR_BLOCK_DEVICE /var/lib/docker $DOCKER_DIR_VOLUME_FSTYPE" /etc/fstab; then
  echo "$DOCKER_DIR_BLOCK_DEVICE /var/lib/docker $DOCKER_DIR_VOLUME_FSTYPE defaults 0 0" | sudo tee --append /etc/fstab
fi

# mount volume
echo 'Mounting Docker volume...'
sudo mount "$DOCKER_DIR_BLOCK_DEVICE" /var/lib/docker

# finally, restart/start docker daemon again
echo 'Attempting to restart/start docker daemon...'
docker_service restart

sleep 5
sudo docker info

echo 'Done.'
