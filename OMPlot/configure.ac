dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OMOptim],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_SUBST(APP)
AC_SUBST(EXE)
AC_SUBST(SHREXT)
AC_SUBST(RPATH_QMAKE)
AC_SUBST(OPENMODELICAHOME)
AC_SUBST(host_short)

m4_include([common/m4/ombuilddir.m4])
m4_include([common/m4/pre-commit.m4])
m4_include([common/m4/ax_cxx_compile_stdcxx_11.m4])
cp common/install-sh common/config.guess common/config.sub ./

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

rm install-sh

dnl Checks for programs.
test -z "$CXXFLAGS" && CXXFLAGS="$CFLAGS"
AC_LANG([C++])
AC_PROG_CC
AC_PROG_CXX
AX_CXX_COMPILE_STDCXX_11([noext],[mandatory])

host_short=$host_cpu-$host_os

m4_include([common/m4/qmake.m4])

if test -z "$QMAKE"; then
  AC_MSG_ERROR([Could not find qmake (QT4)])
elif test -z "$LRELEASE"; then
  AC_MSG_ERROR([Could not find lrelease (QT4)])
fi

m4_include([common/m4/omhome.m4])
FIND_OPENMODELICAHOME()

AC_OUTPUT(Makefile qwt/Makefile.unix OMPlot/OMPlotGUI/Makefile.unix OMPlot/OMPlotGUI/OMPlotGUI.config qwt/qwt.config)
