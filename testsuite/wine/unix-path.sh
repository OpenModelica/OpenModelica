# unix_path ARG: ARG with a leading Windows path, bare or after an option such
# as /I, /LIBPATH: or -DVAR=, turned into the Unix path wine maps it to.
unix_path() {
  if [[ $1 =~ ^([/-][A-Za-z0-9_]+[:=]?)?([A-Za-z]):[\\/](.*)$ ]]; then
    local drive
    drive=$(readlink -f "${WINEPREFIX:-$HOME/.wine}/dosdevices/${BASH_REMATCH[2],,}:")
    printf '%s%s/%s' "${BASH_REMATCH[1]}" "${drive%/}" "${BASH_REMATCH[3]//\\//}"
  else
    printf '%s' "$1"
  fi
}
