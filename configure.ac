dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OpenModelica],[dev],[https://github.com/OpenModelica/OpenModelica/issues],[openmodelica],[https://openmodelica.org])

AC_LANG([C])
AC_PROG_CC
AC_PROG_CXX
AC_PROG_CPP

m4_include([common/m4/pre-commit.m4])
m4_include([common/m4/ombuilddir.m4])
m4_include([common/m4/omhome.m4])
AC_SUBST(RPATH_QMAKE)
AC_SUBST(SHREXT)
AC_SUBST(APP)
AC_SUBST(CMAKE)

AC_SUBST(OMC_TARGET)
AC_ARG_WITH(cppruntime,  [  --with-cppruntime       (build the optional cppruntime simulation libraries)],[OMC_TARGET="$withval"],[OMC_TARGET="no"])

AC_MSG_CHECKING([if cppruntime is requested])
if test "$OMC_TARGET" = "yes"; then
  OMC_TARGET=all-runtimeCPPinstall
  AC_MSG_RESULT([yes])
else
  OMC_TARGET=
  AC_MSG_RESULT([no])
fi

AC_SUBST(CMAKE_LDFLAGS)
if echo $host | grep -i darwin; then
  CMAKE_LDFLAGS="-Wl,-U,libintl_gettext"
fi

m4_include([common/m4/corba.m4])
AC_SUBST(ALL_TARGETS)
if test ! -z "$USE_CORBA"; then
  CORBA_TARGETS="OMOptim-omoptim"
fi

for dir_target in OMCompiler-omc OMPlot-omplot OMEdit-omedit OMNotebook-omnotebook OMShell-omshell OMSens_Qt-omsens_qt $CORBA_TARGETS; do
  dir=`echo $dir_target | cut -d- -f1`
  if test ! -f "$dir/configure.ac"; then
    AC_MSG_NOTICE("Subproject $dir does not exist")
  else
    if !(cd "$dir" && autoconf); then
      AC_MSG_ERROR("Failed to autoconf $dir")
    fi
    ALL_TARGETS="$ALL_TARGETS `echo $dir_target | cut -d- -f2-`"
  fi
done

AC_SUBST(ALL_TARGETS)
if test -f testsuite/Makefile; then
  ALL_TARGETS="$ALL_TARGETS testsuite-depends"
fi


AC_CONFIG_SUBDIRS([OMCompiler OMPlot OMEdit OMNotebook OMShell OMSens_Qt])
if test ! -z "$USE_CORBA"; then
  AC_CONFIG_SUBDIRS([OMOptim])
fi

AC_OUTPUT([Makefile])
