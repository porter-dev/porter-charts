#!/bin/sh

# Usage: job_killer.sh [-c]? [grace_period_seconds] [process_pattern] [sidecar]?
#
# Tracks the process matching process_pattern, or with sidecar names and no match in 10s, every job
# process (app_pids.sh). When it exits or TIMEOUT passes, TERMs what remains (with -c, also the matched
# process's children), waits up to the grace period, then stops the sidecars.

kill_child_procs=false

while getopts ":c" opt; do
  case $opt in
    c)
      kill_child_procs=true
  esac
done

if $kill_child_procs
then
  grace_period_seconds=$2
  target=$3
  sidecar=$4
else
  grace_period_seconds=$1
  target=$2
  sidecar=$3
fi  

global_timeout=$TIMEOUT

if [ -z "$global_timeout" ]; then
  global_timeout=3600
fi

echo "set global timeout value of $global_timeout"

pattern="$(printf '[%s]%s' $(echo $target | cut -c 1) $(echo $target | cut -c 2-))"

graceful_shutdown() {
    echo "starting graceful shutdown..."

    local timeout=$1

    echo "searching for process pattern: $pattern"

    local target_pid=""
    local signal_children=$kill_child_procs

    if [ -n "$target" ]; then
      target_pid=$(pgrep -f $pattern -l | grep -v 'job_killer.sh' | grep -v 'wait_for_job.sh' | grep -v 'app_pids.sh' | grep -v 'grep' | awk '{ printf "%d ", $1 }' | sort)
    fi

    if [ -z "$target_pid" ] && [ -n "$job_pids" ]; then
      target_pid=$(./app_pids.sh "$sidecar" | tr '\n' ' ')
      signal_children=false
      if [ -n "$target_pid" ]; then
        echo "no process matches $pattern, signalling job pids $target_pid"
      fi
    fi

    local list="$target_pid"

    if [ -n "$target_pid" ]; then
      # request graceful shutdown from target_pid
      kill -TERM ${target_pid} 2>/dev/null || true

      if $signal_children
      then
          for c in $(ps -o pid= --ppid $target_pid); do
            # request graceful shutdown of all children, and append to process list
            kill -0 $c 2>/dev/null && kill -TERM $c && list="$list $c" || true
          done
      fi

      # schedule hard kill after timeout
      (sleep ${timeout}; kill -9 -${target_pid} 2>/dev/null || true) &
      local killer=${!}

      # wait for processes to finish
      for c in $list; do
        echo "waiting for process $c"
        tail --pid=$c -f /dev/null 
      done

      wait ${list} 2>/dev/null || true

      # children exited gracefully - cancel timer
      sleep 0.1 && kill -9 ${killer} 2>/dev/null && target_pid="" || true
    fi

    # run the sidecar killer, this will terminate any additional sidecars if necessary
    if [ -n "$sidecar" ]; then
        echo "killing sidecar command: $sidecar"
        ./sidecar_killer.sh $sidecar
    fi

    echo "Exit Gracefully (0)" && exit 0
}

trap 'graceful_shutdown $grace_period_seconds $target' TERM INT HUP

sleep 2

echo "waiting for job to start..."

timeout 10s ./wait_for_job.sh $pattern

target_pid=$(pgrep -f $pattern -l | grep -v 'job_killer.sh' | grep -v 'wait_for_job.sh' | grep -v 'grep' | awk '{ printf "%d ", $1 }' | sort)
target_pid_name=$(pgrep -f $pattern -l | grep -v 'job_killer.sh' | grep -v 'wait_for_job.sh' | grep -v 'grep')

if [ -z "$target_pid" ] && [ -n "$sidecar" ]; then
    job_pids=$(./app_pids.sh "$sidecar" | tr '\n' ' ')
fi

if [ -n "$target_pid" ] || [ -n "$job_pids" ]; then
    # schedule hard kill after global timeout
    is_global_shutdown=""
    (sleep ${global_timeout}; echo "triggering global shutdown" && is_global_shutdown="true" && graceful_shutdown $grace_period_seconds $target || true) &
    global_killer=${!}

    if [ -n "$target_pid" ]; then
      echo "targeting pids $target_pid matched by $target_pid_name"
      tail --pid=$target_pid -f /dev/null &
      child=$!

      wait "$child"
    else
      echo "no process matches $pattern, tracking job pids $job_pids"
      while [ -n "$(./app_pids.sh "$sidecar")" ]; do
        sleep 1
      done
    fi

    if [ -z "$is_global_shutdown" ]; then
      # cancel hard kill timer
      sleep 0.1 && kill -9 ${global_killer} 2>/dev/null || true
      graceful_shutdown $grace_period_seconds $target
    fi
else 
  echo "no job process found to watch within 10s, exiting"

  if [ -n "$sidecar" ]; then
    echo "killing sidecar command: $sidecar"
    ./sidecar_killer.sh $sidecar
  fi
fi
