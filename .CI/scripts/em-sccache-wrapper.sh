#!/usr/bin/env bash
# EM_COMPILER_WRAPPER shim. sccache <=0.16 marks any TU non-cacheable when it
# hits em++'s `-Xclang -iwithsysroot/PATH`; rewrite it to the equivalent
# `-isystem <sysroot>/PATH` (same search order, identical output) so sccache caches.
set -euo pipefail
argv=("$@")
sysroot=
prev=
for a in "${argv[@]}"; do
  case "$a" in --sysroot=*) sysroot="${a#--sysroot=}";; esac
  [[ "$prev" == "-isysroot" ]] && sysroot="$a"
  prev="$a"
done
out=(); i=0; n=${#argv[@]}
while (( i < n )); do
  a="${argv[i]}"
  if [[ "$a" == "-Xclang" && $((i+1)) -lt n && "${argv[i+1]}" == -iwithsysroot/* && -n "$sysroot" ]]; then
    out+=("-isystem" "${sysroot}${argv[i+1]#-iwithsysroot}"); i=$((i+2)); continue
  fi
  out+=("$a"); i=$((i+1))
done
exec sccache "${out[@]}"
