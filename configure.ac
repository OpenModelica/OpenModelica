dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OpenModelica],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_LANG([C])
AC_PROG_CC

m4_include([common/m4/pre-commit.m4])
m4_include([common/m4/ombuilddir.m4])
cp common/install-sh common/config.guess common/config.sub ./

AC_SUBST(OMC_TARGET)
AC_ARG_WITH(cppruntime,  [  --with-cppruntime       (build the optional cppruntime simulation libraries)],[OMC_TARGET="$withval"],[OMC_TARGET="no"])

AC_MSG_CHECKING([if cppruntime is requested])
if test "$OMC_OR_CPPRUNTIME" = "yes"; then
  OMC_TARGET=all-runtimeCPPinstall
else
  OMC_TARGET=
fi

AC_SUBST(OMLIBRARY_TARGET)
AC_ARG_WITH(omlibrary,  [  --with-omlibrary=[core,all,no]       (which libraries to build; default is core; the libraries used by the testsuite)],[OMLIBRARY_TARGET="$withval"],[OMLIBRARY_TARGET="core"])

AC_MSG_CHECKING([for omlibrary target])
case "$OMLIBRARY_TARGET" in
  "yes"|"core")
    OMLIBRARY_TARGET="omlibrary-core"
    AC_MSG_RESULT([core])
  ;;
  "no")
    OMLIBRARY_TARGET=""
    AC_MSG_RESULT([none])
  ;;
  "all")
    OMLIBRARY_TARGET="omlibrary-all"
    AC_MSG_RESULT([all])
  ;;
  *)
    AC_MSG_ERROR("unknown omlibrary target $OMLIBRARY_TARGET")
  ;;
esac


for dir in OMCompiler OMPlot OMEdit OMOptim; do
  if test ! -d "$dir"; then
    AC_MSG_ERROR("Subproject $dir does not exist")
  fi
  if !(cd "$dir" && autoconf); then
    AC_MSG_ERROR("Failed to autoconf $dir")
  fi
done

AC_CONFIG_SUBDIRS([OMCompiler OMPlot OMEdit OMOptim])

AC_OUTPUT(Makefile)
