#!/bin/sh

SOURCE_REVISION=""
if test -f REVISION; then
  SOURCE_REVISION=`test -f REVISION && head -n1 REVISION`
elif test "${PWD##*/}" != "OpenModelica" && test -f ../REVISION; then
  SOURCE_REVISION="OpenModelica `test -f ../REVISION && head -n1 ../REVISION`"
elif test -z "$SOURCE_REVISION" && test -e .git; then
  DESCRIBE_SHORT=`git describe --match "v[0-9]*.[0-9]*.[0-9]*" --always`
  DESCRIBE_LONG=`git describe --match "v[0-9]*.[0-9]*.[0-9]*" --always --long`
  if test "$DESCRIBE_SHORT" != "$DESCRIBE_LONG"; then
    SOURCE_REVISION="$DESCRIBE_SHORT"
  else
    HASH=`echo $DESCRIBE_SHORT | rev | cut -d- -f1 | rev`
    COMMIT_SINCE_LAST=`echo $DESCRIBE_SHORT | rev | cut -d- -f2 | rev`
    PRERELEASE=`echo $DESCRIBE_SHORT | rev | cut -d- -f3- | rev | cut -d- -f2-`
    RELEASE_MAJOR=`echo $DESCRIBE_LONG | cut -d. -f1`
    RELEASE_MINOR=`echo $DESCRIBE_LONG | cut -d. -f2`
    RELEASE_PATCH=`echo $DESCRIBE_LONG | cut -d. -f3 | cut -d- -f1`
    if test -z "$PRERELEASE"; then
      # Invent a pre-release tag
      PRERELEASE="dev"
      COMMIT_SINCE_LAST=$(($COMMIT_SINCE_LAST-1))
      RELEASE_PATCH=$(($COMMIT_SINCE_LAST+1))
    fi
    SOURCE_REVISION="$RELEASE_MAJOR.$RELEASE_MINOR.$RELEASE_PATCH-$PRERELEASE.$COMMIT_SINCE_LAST+$HASH"
  fi
  if test ! -z "$1"; then
    SOURCE_REVISION="$1 $SOURCE_REVISION"
  fi
fi
test -z "$SOURCE_REVISION" && SOURCE_REVISION="????"

echo "$SOURCE_REVISION"
