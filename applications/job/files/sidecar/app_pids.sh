#!/bin/sh

# Usage: app_pids.sh [sidecar_names]?
#
# Prints live PIDs outside PID 1 (pause) and this container's cgroup, skipping processes whose comm
# equals one of the "|"-separated names exactly (comm is truncated to 15 characters).
# Uses only shell builtins per process: it runs every second on a 10m CPU sidecar.

read_cgroup() {
  cgroup=""
  while IFS= read -r line; do
    cgroup="$cgroup$line
"
  done < "$1"
}

read_cgroup /proc/self/cgroup
own_cgroup=$cgroup

for dir in /proc/[0-9]*; do
  pid=${dir#/proc/}
  [ "$pid" = 1 ] && continue
  read -r stat 2>/dev/null < "$dir/stat" || continue
  state=${stat##*) }
  [ "${state%% *}" = Z ] && continue
  read_cgroup "$dir/cgroup" 2>/dev/null || continue
  [ "$cgroup" = "$own_cgroup" ] && continue
  read -r comm 2>/dev/null < "$dir/comm" || continue
  case "|$1|" in
    *"|$comm|"*) continue ;;
  esac
  echo "$pid"
done
