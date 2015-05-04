#!/bin/sh
# Not a proper package; will be added somewhere else anyway
mkdir -p m4 # Needed in OSX
for f in AUTHORS ChangeLog COPYING README NEWS; do
  test -f "$f" || touch "$f"
done
autoreconf --force --install
