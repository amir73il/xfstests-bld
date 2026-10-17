#!/bin/bash
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

./filesystems/fanotify/mount-notify_test
./filesystems/fanotify/mount-notify_test_ns
./filesystems/fanotify/ns-notify_test
./filesystems/overlayfs/dev_in_maps
./filesystems/overlayfs/idmapped_mounts
./filesystems/overlayfs/automount_in_layer
./filesystems/overlayfs/set_layers_via_fds
