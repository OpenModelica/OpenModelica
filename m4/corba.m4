AC_SUBST(USE_CORBA)
AC_SUBST(QT_USE_CORBA)
AC_SUBST(CORBA_QMAKE_INCLUDES)
AC_SUBST(CORBACFLAGS)
AC_SUBST(CORBALIBS)
AC_SUBST(IDLCMD)

dnl should we use corba?

if test -z "$OMNIORB_DEFAULT"; then
  OMNIORB_DEFAULT="no"
fi

WANT_ORBIT2="no"
WANT_MICO="no"
AC_ARG_WITH(MICO, [  --with-MICO=DIR                  use mico corba installed in DIR (or use mico-config)],[WANT_MICO="$withval"],[])
AC_ARG_WITH(omniORB, [  --with-omniORB=DIR               use omniORB installed in DIR (recommended CORBA implementation)],[WANT_OMNIORB="$withval"],[WANT_OMNIORB="$OMNIORB_DEFAULT"])

if test ! "$WANT_MICO" = "no"; then
  if test "$WANT_MICO" = "yes"; then
    MICO="mico-config";
    IDLCMD="idl";
  else
    MICO="$WANT_MICO/bin/mico-config";
    IDLCMD="$WANT_MICO/bin/idl";
  fi
  if test "$USE_CORBA" = "no"; then
    AC_MSG_ERROR([failed to find mico-corba])
  fi
  AC_MSG_CHECKING([mico version])
  if ! $MICO --version; then
    AC_MSG_ERROR([failed to call $MICO])
  fi
  USE_CORBA="-DUSE_CORBA -DUSE_MICO"
  QT_USE_CORBA="USE_MICO"
  AC_MSG_CHECKING([mico settings])
  CORBACFLAGS="-I`$MICO --prefix`/include -I.";
  CORBA_QMAKE_INCLUDES="`$MICO --prefix`/include -I.";
  CORBALIBS="`$MICO --libs`";
  AC_MSG_RESULT([$CORBACFLAGS $USE_CORBA $QT_USE_CORBA])
  DESIRED_CORBA="mico"
elif test ! "$WANT_ORBIT2" = "no"; then
  if test "$WANT_ORBIT2" = "yes"; then
    ORBIT2="orbit2-config";
  else
    ORBIT2="$withval/bin/orbit2-config";
  fi
  AC_CHECK_PROG(USE_CORBA,$ORBIT2,[-DUSE_CORBA -DUSE_ORBIT2],[no])
  if test "$USE_CORBA" = "no"; then
    AC_MSG_ERROR([failed to find orbit2])
  fi
  USE_CORBA="-DUSE_CORBA -DUSE_ORBIT"
  QT_USE_CORBA="USE_ORBIT2"
  CORBACFLAGS=`orbit2-config --cflags`;
  # Don't have orbit2-config installed to verify
  CORBA_QMAKE_INCLUDES=`orbit2-config --prefix`/include/;
  CORBALIBS=`orbit2-config --libs`;
  IDLCMD="orbit-idl-2";
  DESIRED_CORBA="orbit2"
  AC_MSG_ERROR([ORBIT2 is not supported yet])
elif test ! "$WANT_OMNIORB" = "no"; then
  if test "$WANT_OMNIORB" = "yes"; then
    OMNIORB_LDFLAGS="";
    IDLPATH="omniidl";
  else
    CORBA_QMAKE_INCLUDES="$WANT_OMNIORB/include";
    CORBACFLAGS="-I$CORBA_QMAKE_INCLUDES";
    IDLPATH="$WANT_OMNIORB/bin/omniidl"
    OMNIORB_LDFLAGS="-L'$WANT_OMNIORB/lib'";
  fi
  AC_PATH_PROG(IDLPATH,$IDLPATH,[no])
  if test "$IDLPATH" = "no"; then
    AC_MSG_ERROR([failed to find $IDLPATH])
  fi
  USE_CORBA="-DUSE_CORBA -DUSE_OMNIORB"
  # Cannot search for libs (C++ symbols) or includes (automatically generated; may differ between platforms)
  IDLCMD="$IDLPATH -bcxx -Wbh=.h -Wbs=.cc";
  IDLPYTHONCMD="$IDLPATH -bpython";
  QT_USE_CORBA="USE_OMNIORB"
  CORBALIBS="$LIBS -lomniORB4 -lomnithread -lpthread"
  DESIRED_CORBA="omniorb"
  PYTHON_INTERFACE="yes"
else
  USE_CORBA="";
  CORBACFLAGS="";
  CORBALIBS="";
  IDLCMD="";
  DESIRED_CORBA="none"
fi

AC_MSG_CHECKING([for CORBA]);
AC_MSG_RESULT([$DESIRED_CORBA]);
