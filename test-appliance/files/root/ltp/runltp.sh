set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

./fcntl/fcntl38 $*
./fcntl/fcntl39 $*
./inotify/inotify01 $*
./inotify/inotify02 $*
./inotify/inotify03 $*
./inotify/inotify04 $*
./inotify/inotify05 $*
./inotify/inotify06 $*
./inotify/inotify07 $*
./inotify/inotify08 $*
./inotify/inotify10 $*
./inotify/inotify11 $*
./inotify/inotify12 $*
./fanotify/fanotify01 $*
./fanotify/fanotify02 $*
./fanotify/fanotify03 $*
./fanotify/fanotify04 $*
./fanotify/fanotify05 $*
./fanotify/fanotify06 $*
./fanotify/fanotify07 $*
./fanotify/fanotify08 $*
./fanotify/fanotify09 $*
./fanotify/fanotify10 $*
./fanotify/fanotify11 $*
./fanotify/fanotify12 $*
./fanotify/fanotify13 $*
./fanotify/fanotify14 $*
./fanotify/fanotify15 $*
./fanotify/fanotify16 $*
./fanotify/fanotify17 $*
./fanotify/fanotify18 $*
./fanotify/fanotify19 $*
./fanotify/fanotify20 $*
./fanotify/fanotify21 $*
./fanotify/fanotify22 $*
./fanotify/fanotify23 $*
./fanotify/fanotify24 $*
