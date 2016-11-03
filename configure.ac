dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OMOptim],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_SUBST(APP)
AC_SUBST(EXE)
AC_SUBST(IDLCMD)
AC_SUBST(RPATH_QMAKE)
AC_SUBST(host_short)
AC_SUBST(SOURCE_REVISION)
AC_SUBST(QT4BUILD)
AC_SUBST(QMAKE_CONFIG_OSG)
AC_SUBST(LIBOSG)

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
AC_PROG_CC
AC_PROG_CXX
AX_CXX_COMPILE_STDCXX_11([noext],[mandatory])

host_short=$host_cpu-$host_os

m4_include([common/m4/qmake.m4])

m4_include([common/m4/omhome.m4])
FIND_OPENMODELICAHOME()
FIND_LIBOPENMODELICACOMPILER()
FIND_LIBOMQWT()

WITH_OSG=1
AC_CHECK_HEADERS(osg/Vec3f, [], [WITH_OSG=0])
AC_CHECK_HEADERS(osg/GraphicsContext, [], [WITH_OSG=0])
AC_CHECK_HEADERS(osg/Matrix, [], [WITH_OSG=0])
AC_CHECK_HEADERS(osg/Uniform, [], [WITH_OSG=0])

if test "$WITH_OSG" = 0; then
  CPPFLAGS="$CPPFLAGS -DWITHOUT_OSG"
else
  QMAKE_CONFIG_OSG="CONFIG += osg"
  LIBOSG="-losg -losgViewer -losgDB -losgGA -lOpenThreads"
fi

m4_include([common/m4/semver.m4])
SOURCE_REVISION="$SOURCE_REVISION$NON_FREE_VERSION"

AC_OUTPUT(Makefile OMEdit/OMEditGUI/Makefile.unix OMEdit/OMEditGUI/OMEdit.config OMEdit/OMEditGUI/Debugger/Parser/Makefile.unix OMEdit/OMEditGUI/Debugger/Parser/Makefile.lib.unix OMEdit/OMEditGUI/omc_config.h)
