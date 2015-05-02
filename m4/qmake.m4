dnl Check for Qt

AC_CHECK_PROGS(QMAKE,qmake-qt4 qmake-mac qmake,"")
AC_CHECK_PROGS(LRELEASE,lrelease-qt4 lrelease,"")

if test -n "$QMAKE"; then
  AC_MSG_CHECKING([for qmake arguments])
  if test "$DARWIN" = "1"; then
    echo "#!/bin/sh -x" > ./qmake.sh
    echo "$QMAKE \$*" >> ./qmake.sh
    echo 'MAKEFILE=`echo -- $* | grep -o "Makefile@<:@A-Z.a-z@:>@*"`' >> ./qmake.sh
    echo 'if test -z "$MAKEFILE"; then MAKEFILE=Makefile; fi' >> ./qmake.sh
    # echo 'echo $MAKEFILE' >> ./qmake.sh
    echo 'cat $MAKEFILE | \
      sed "s/-arch i386//g" | \
      sed "s/-arch x86_64//g" | \
      sed "s/-arch//g" > $MAKEFILE.fixed && \
      mv $MAKEFILE.fixed $MAKEFILE' >> qmake.sh
    QMAKE="sh `pwd`/qmake.sh"
  # Needed? Maybe
  elif test "$host" != "$build"; then
    QMAKE_LIBDIR_QT=`$QMAKE -query QT_INSTALL_LIBS | sed "s/$build_short/$host_short/"`
    QMAKE="$QMAKE -spec linux-g++ QMAKE_CXX=\"$CXX\" QMAKE_CC=\"$CC\" QMAKE_LINK=\"$CXX\" QMAKE_LIBDIR_QT=\"$QMAKE_LIBDIR_QT\""
  fi
  AC_MSG_RESULT([$QMAKE])
fi
