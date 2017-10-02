dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OMShell],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_SUBST(APP)
AC_SUBST(EXE)
AC_SUBST(IDLCMD)
AC_SUBST(RPATH)
AC_SUBST(RPATH_QMAKE)
AC_SUBST(host_short)

m4_include([common/m4/pre-commit.m4])
cp common/install-sh common/config.guess common/config.sub ./
m4_include([common/m4/ombuilddir.m4])
m4_include([common/m4/ax_cxx_compile_stdcxx_11.m4])

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

dnl Checks for programs.
test -z "$CXXFLAGS" && CXXFLAGS="$CFLAGS"
AC_LANG([C++])
AC_PROG_CXX
AC_PROG_CC
AX_CXX_COMPILE_STDCXX_11([noext],[mandatory])

host_short=$host_cpu-$host_os

m4_include([common/m4/qmake.m4])
m4_include([common/m4/omhome.m4])

FIND_OPENMODELICAHOME()

AC_SUBST(LIBREADLINE)
AC_SUBST(OMSHELL_TERMINAL)
AC_MSG_CHECKING([if the user wants to compile OMShell-terminal])
OMSHELL_TERMINAL="mosh"
AC_ARG_ENABLE(omshell-terminal, [  --disable-omshell-terminal    Disables compilation of OMShell-terminal (enabled by default)],[test
 "xno" = x"$enableval" && OMSHELL_TERMINAL=""])
if test -z "$OMSHELL_TERMINAL" ; then
  AC_MSG_RESULT([no])
else
  AC_MSG_RESULT([yes])
  AC_CHECK_HEADER(readline/readline.h,,AC_MSG_ERROR([readline missing]))
  AC_CHECK_HEADER(readline/history.h,,AC_MSG_ERROR([readline missing]))

  AC_ARG_WITH(static-readline,  [  --with-static-readline=DIR       (default to dynamic linking; searches /usr if no other directory is provided)],[WANT_STATIC_READLINE="$withval"],[WANT_STATIC_READLINE="no"])

  if test "$WANT_STATIC_READLINE" = "no"; then
    LIBS=""
    AC_SEARCH_LIBS(readline,readline,,[AC_MSG_ERROR([readline missing])])
    LIBREADLINE=$LIBS
    LIBS=""
  else
    if test "$WANT_STATIC_READLINE" = "yes"; then
      READLINELIB=/usr/lib;
    else
      READLINELIB=$WANT_STATIC_READLINE/lib
    fi
    test -f $READLINELIB/*/libreadline.a && READLINELIB=`dirname $READLINELIB/*/libreadline.a`
    LIBS="-lncurses $READLINELIB/libreadline.a -ltermcap"
    AC_MSG_CHECKING([for static readline $LIBS])
    AC_LINK_IFELSE([AC_LANG_CALL([], [rl_message])], [LIBREADLINE=$LIBS], [AC_MSG_ERROR([failed])])
    AC_MSG_RESULT([ok])
    LIBS=""
  fi
fi

AC_OUTPUT(Makefile OMShell/OMShellGUI/Makefile.unix OMShell/OMShellGUI/OMShell.config mosh/src/Makefile OMShell/OMShellGUI/omc_config.h mosh/src/omc_config.h)
# AC_CONFIG_COMMANDS([Clean qmake stuff],[make clean])
