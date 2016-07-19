#!/bin/bash -e

# Description: Initialises and mounts an additional partitionless volume
# Author: Martin Baillie <martin.baillie@iag.com.au>
# Contributor: Chris Fordham <chris.fordham@industrieit.com>

# Note: Will not reinitialise the volume if it's already mounted or
# it already has a filesystem unless $ADD_VOLUME_REINITIALISE is true

# Inputs:
# $ADD_VOLUME_FS_TYPE
# $ADD_VOLUME_FS_OPTIONS
# $ADD_VOLUME_BLOCK_DEVICE
# $ADD_VOLUME_MOUNT_POINT
# $ADD_VOLUME_MOUNT_OPTIONS
# $ADD_VOLUME_INITIALISE
# $ADD_VOLUME_REINITIALISE

: "${ADD_VOLUME_FS_TYPE:=ext4}"
: "${ADD_VOLUME_FS_OPTIONS:=}"
: "${ADD_VOLUME_BLOCK_DEVICE:=/dev/sdc}"
: "${ADD_VOLUME_MOUNT_POINT:=/mnt/data}"
: "${ADD_VOLUME_MOUNT_OPTIONS:=defaults,noatime}"
: "${ADD_VOLUME_INITIALISE:=false}"
: "${ADD_VOLUME_REINITIALISE:=false}"

# exit gracefully if told to not initialise the volume
if [ "$ADD_VOLUME_INITIALISE" != 'true' ]; then
  echo '$ADD_VOLUME_INITIALISE not set to true, skipping.'
  exit 0
fi

# Install required tools:
# only xfs currently
case $ADD_VOLUME_FS_TYPE in
*xfs*)
  pkg=xfsprogs
  if type apt-get > /dev/null 2>&1; then
    sudo apt-get -y install "$pkg"
  else
    sudo yum -y install "$pkg"
  fi
  ;;
esac

# Sanity checks:
if [ ! -b "${ADD_VOLUME_BLOCK_DEVICE}" ]; then
    echo "ERROR: block device ${ADD_VOLUME_BLOCK_DEVICE} not attached"
    exit 1
fi

# Idempotency:
if mount | grep "${ADD_VOLUME_BLOCK_DEVICE}" > /dev/null; then
    echo "Volume ${ADD_VOLUME_BLOCK_DEVICE} is currently mounted"

    if [ "${ADD_VOLUME_REINITIALISE}" != "true" ]; then
        echo '$ADD_VOLUME_REINITIALISE != true. Nothing to do here'
        exit 0
    fi
    echo '$ADD_VOLUME_REINITIALISE == true. Unmounting and reinitialising'
    sudo umount -f "${ADD_VOLUME_BLOCK_DEVICE}"
fi

# Initialisation:
if [ "${ADD_VOLUME_REINITIALISE}" = "true" ] ||
    ! sudo blkid | grep "${ADD_VOLUME_BLOCK_DEVICE}" | grep TYPE > /dev/null; then
    echo "Wiping block device ${ADD_VOLUME_BLOCK_DEVICE}"
    sudo wipefs -a "${ADD_VOLUME_BLOCK_DEVICE}"

    echo "Creating ${ADD_VOLUME_FS_TYPE} filesystem on ${ADD_VOLUME_BLOCK_DEVICE}"
    # mkfs.xfs does not support -F
    [ "$ADD_VOLUME_FS_TYPE" != 'xfs' ] && ADD_VOLUME_FS_OPTIONS="-F $ADD_VOLUME_FS_OPTIONS"
    sudo mkfs."${ADD_VOLUME_FS_TYPE}" ${ADD_VOLUME_FS_OPTIONS} "${ADD_VOLUME_BLOCK_DEVICE}"
else
    echo "Not (re-)initialising volume. Continuing to ensure it is correctly mounted"
fi

# Mounting:
if [ -e "${ADD_VOLUME_MOUNT_POINT}" ]; then
    echo "Mount point exists. Removing"
    sudo rm -rf "${ADD_VOLUME_MOUNT_POINT}"
fi
echo "Recreating mount point"
sudo mkdir -p "${ADD_VOLUME_MOUNT_POINT}"

if ! grep "${ADD_VOLUME_BLOCK_DEVICE}" /etc/fstab > /dev/null; then
    echo "Editing fstab to automount ${ADD_VOLUME_BLOCK_DEVICE} at ${ADD_VOLUME_MOUNT_POINT}"
    echo "${ADD_VOLUME_BLOCK_DEVICE} ${ADD_VOLUME_MOUNT_POINT} ${ADD_VOLUME_FS_TYPE} " \
        "${ADD_VOLUME_MOUNT_OPTIONS} 0 0" | sudo tee -a /etc/fstab
fi

echo "Mounting ${ADD_VOLUME_BLOCK_DEVICE} at ${ADD_VOLUME_MOUNT_POINT}"
sudo mount "${ADD_VOLUME_MOUNT_POINT}"

echo "Done."
