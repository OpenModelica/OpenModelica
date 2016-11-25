dnl Check for Qt

AC_SUBST(QMAKE)
AC_SUBST(LRELEASE)

AC_MSG_CHECKING([for qmake in env.vars QMAKE and QTDIR])
if test ! -z "$QMAKE"; then
  AC_MSG_RESULT([$QMAKE])
elif test -f $QTDIR/bin/qmake; then
  QMAKE=$QTDIR/bin/qmake
  AC_MSG_RESULT([$QMAKE])
else
  AC_MSG_RESULT([no])
  AC_CHECK_PROGS(QMAKE,qmake qmake-mac qmake-qt4,"")
fi

if test -n "$QMAKE"; then
  AC_MSG_CHECKING([for qmake arguments])

  if "$QMAKE" -qt5 -v > /dev/null 2>&1; then
    QMAKE="$QMAKE -qt5"
    QT4BUILD="-DQT4_BUILD:Boolean=OFF"
  elif "$QMAKE" -qt4 -v > /dev/null 2>&1; then
    QMAKE="$QMAKE -qt4"
    QT4BUILD="-DQT4_BUILD:Boolean=ON"
  elif "$QMAKE" -v 2>&1 | grep "Qt version 5"; then
    true
    QT4BUILD="-DQT4_BUILD:Boolean=OFF"
  elif "$QMAKE" -v 2>&1 | grep "Qt version 4"; then
    QT4BUILD="-DQT4_BUILD:Boolean=ON"
  else
    QMAKE_VERSION=`"$QMAKE" -v`
    AC_MSG_ERROR([qmake does not report qt version 4 or 5: $QMAKE_VERSION])
  fi

  if echo $host | grep darwin; then
    echo "#!/bin/sh -x" > ./qmake.sh
    echo "$QMAKE \"\$@\"" >> ./qmake.sh
    echo 'MAKEFILE=`echo -- \"$*\" | grep -o "Makefile@<:@A-Z.a-z@:>@*"`' >> ./qmake.sh
    echo 'if test -z "$MAKEFILE"; then MAKEFILE=Makefile; fi' >> ./qmake.sh
    # echo 'echo $MAKEFILE' >> ./qmake.sh
    echo 'cat $MAKEFILE | \
      sed "s/-arch@<:@\\@:>@* i386//g" | \
      sed "s/-arch@<:@\\@:>@* x86_64//g" | \
      sed "s/-arch//g" | \
      sed "s/-Xarch@<:@^ @:>@*//g" > $MAKEFILE.fixed && \
      mv $MAKEFILE.fixed $MAKEFILE' >> qmake.sh
    QMAKE="sh `pwd`/qmake.sh"
  # Needed? Maybe
  elif test "$host" != "$build"; then
    QMAKE_LIBDIR_QT=`$QMAKE -query QT_INSTALL_LIBS | sed "s/$build_short/$host_short/"`
    QMAKE="$QMAKE -spec linux-g++ QMAKE_CXX=\"$CXX\" QMAKE_CC=\"$CC\" QMAKE_LINK=\"$CXX\" QMAKE_LIBDIR_QT=\"$QMAKE_LIBDIR_QT\""
  fi
  AC_MSG_RESULT([$QMAKE])

  AC_MSG_CHECKING([for lrelease])
  LRELEASE=`$QMAKE -query QT_INSTALL_BINS`/lrelease
  QT_INSTALL_HEADERS=`$QMAKE -query QT_INSTALL_HEADERS`
  if test -f "$LRELEASE"; then
    AC_MSG_RESULT([$LRELEASE])
  else
    AC_MSG_ERROR([$LRELEASE does not exist])
  fi
fi
