function m() {
  command="time ~/mount/mount.sh $@"
  echo $command
  eval $command
}
