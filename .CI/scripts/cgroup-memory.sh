#!/bin/bash
# Report the cgroup memory limit a test run is under (check) and what it used
# (report). The limit comes from `docker run --memory`; see .CI/common.groovy.

set -u

cg=/sys/fs/cgroup
rel=$(sed -n 's/^0:://p' /proc/self/cgroup 2>/dev/null | head -n1)
if [ -n "${rel:-}" ] && [ "$rel" != / ] && [ -d "${cg}${rel}" ]; then
  cg="${cg}${rel}"
fi

if [ -r "$cg/memory.max" ]; then
  f_max=$cg/memory.max
  f_swap=$cg/memory.swap.max
  f_peak=$cg/memory.peak
  f_events=$cg/memory.events
  oom_field=oom_kill
else
  # cgroup v1 host
  cg=/sys/fs/cgroup/memory
  f_max=$cg/memory.limit_in_bytes
  f_swap=$cg/memory.memsw.limit_in_bytes
  f_peak=$cg/memory.max_usage_in_bytes
  f_events=
  oom_field=
fi

show() {
  if [ -r "$1" ]; then cat "$1"; else echo '?'; fi
}

case "${1:-check}" in
check)
  max=$(show "$f_max")
  swap=$(show "$f_swap")
  echo "cgroup $cg: memory limit $max, swap limit $swap"
  case "$max" in
    max|'?'|9223372036854771712)
      echo "WARNING: no cgroup memory limit - a runaway test can take the machine down" >&2
      ;;
  esac
  if [ "$swap" != 0 ] && [ "$swap" != "$max" ]; then
    echo "WARNING: swapping is allowed ($swap); a test should be killed, not swapped" >&2
  fi
  # memory.oom.group would kill the whole run, not just the greediest process.
  if [ "$(show "$cg/memory.oom.group")" = 1 ]; then
    echo "WARNING: memory.oom.group is set; one runaway test takes down runtests.pl" >&2
  fi
  ;;
report)
  echo "cgroup $cg: peak memory $(show "$f_peak") of $(show "$f_max")"
  if [ -n "$f_events" ] && [ -r "$f_events" ]; then
    kills=$(awk -v k="$oom_field" '$1 == k { print $2 }' "$f_events")
    echo "OOM kills: ${kills:-0}"
    if [ "${kills:-0}" != 0 ]; then
      echo "WARNING: ${kills} process(es) hit the memory limit and were killed" >&2
    fi
  fi
  ;;
*)
  echo "usage: $0 [check|report]" >&2
  exit 2
  ;;
esac
