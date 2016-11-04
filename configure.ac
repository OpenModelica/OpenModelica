dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OMOptim],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_SUBST(APP)
AC_SUBST(EXE)
AC_SUBST(IDLCMD)
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
AC_LANG([C++])
test -z "$CXXFLAGS" && CXXFLAGS="$CFLAGS"
AC_PROG_CC
AC_PROG_CXX
AX_CXX_COMPILE_STDCXX_11([noext],[mandatory])

host_short=$host_cpu-$host_os

m4_include([common/m4/qmake.m4])

m4_include([common/m4/omhome.m4])
FIND_OPENMODELICAHOME()
FIND_LIBOPENMODELICACOMPILER()
FIND_LIBOMQWT()
DRCONTROLDIR=`pwd`/DrControl
DRMODELICADIR=`pwd`/DrModelica
AC_SUBST([DRCONTROLDIR])
AC_SUBST([DRMODELICADIR])

AC_OUTPUT(Makefile OMNotebook/OMNotebookGUI/Makefile.unix OMNotebook/OMNotebookGUI/OMNotebook.config OMNotebook/OMNotebookGUI/omc_config.h)
