#! /bin/bash -e

# Inputs:
# $VOLUME_SNAPSHOTTING_LINEAGES

: "${VOLUME_SNAPSHOTTING_LINEAGES:=}"

lineages=(${VOLUME_SNAPSHOTTING_LINEAGES//,/ })

for lineage in "${lineages[@]}"
do
  sudo bash -e "$RS_ATTACH_DIR/create_volume_snapshot-rl10.bash" "$lineage"
done

echo 'Done.'
