dnl Check for Qt

AC_SUBST(QMAKE)

AC_MSG_CHECKING([for qmake in env.vars QMAKE and QTDIR])
if test ! -z "$QMAKE"; then
  AC_MSG_RESULT([$QMAKE])
elif test -f $QTDIR/bin/qmake; then
  QMAKE=$QTDIR/bin/qmake
  AC_MSG_RESULT([$QMAKE])
else
  AC_MSG_RESULT([no])
  AC_CHECK_PROGS(QMAKE,qmake-qt4 qmake-mac qmake,"")
fi

AC_MSG_CHECKING([for lrelease in env.vars LRELEASE and QTDIR])
if test ! -z "$LRELEASE"; then
  AC_MSG_RESULT([$LRELEASE])
elif test -f $QTDIR/bin/lrelease; then
  LRELEASE=$QTDIR/bin/lrelease
  AC_MSG_RESULT([$LRELEASE])
else
  AC_MSG_RESULT([no])
  AC_CHECK_PROGS(LRELEASE,lrelease-qt4 lrelease,"")
fi

if test -n "$QMAKE"; then
  AC_MSG_CHECKING([for qmake arguments])
  if echo $host | grep darwin; then
    echo "#!/bin/sh -x" > ./qmake.sh
    echo "$QMAKE \$*" >> ./qmake.sh
    echo 'MAKEFILE=`echo -- $* | grep -o "Makefile@<:@A-Z.a-z@:>@*"`' >> ./qmake.sh
    echo 'if test -z "$MAKEFILE"; then MAKEFILE=Makefile; fi' >> ./qmake.sh
    # echo 'echo $MAKEFILE' >> ./qmake.sh
    echo 'cat $MAKEFILE | \
      sed "s/-arch i386//g" | \
      sed "s/-arch x86_64//g" | \
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
fi
