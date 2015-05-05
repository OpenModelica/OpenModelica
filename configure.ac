dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OpenModelica],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

m4_include([common/m4/pre-commit.m4])
m4_include([common/m4/ombuilddir.m4])
cp common/install-sh common/config.guess common/config.sub ./

for dir in OMCompiler OMPlot; do
  test -d "$dir" || AC_MSG_ERROR("Subproject $dir does not exist")
  (cd "$dir" && autoconf || AC_MSG_ERROR("Failed to autoconf $dir"))
done

AC_CONFIG_SUBDIRS([OMCompiler OMPlot])

AC_OUTPUT(Makefile)
