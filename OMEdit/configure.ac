dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OMEdit],[dev],[https://github.com/OpenModelica/OpenModelica/issues],[openmodelica],[https://openmodelica.org])

AC_SUBST(APP)
AC_SUBST(EXE)
AC_SUBST(IDLCMD)
AC_SUBST(RPATH_QMAKE)
AC_SUBST(host_short)
AC_SUBST(SOURCE_REVISION)
AC_SUBST(QMAKE_CONFIG_ANIMATION)
AC_SUBST(LSB_RELEASE)
AC_SUBST(LIB_BOOST_REGEX)
AC_SUBST(SHREXT)

m4_include([common/m4/pre-commit.m4])
cp common/install-sh common/config.guess common/config.sub ./
m4_include([common/m4/ombuilddir.m4])
m4_include([common/m4/ax_cxx_compile_stdcxx.m4])

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

dnl Checks for programs.
test -z "$CXXFLAGS" && CXXFLAGS="$CFLAGS"
AC_LANG([C++])
AC_PROG_CC
AC_PROG_CXX
AX_CXX_COMPILE_STDCXX(17, [noext],[mandatory])
host_short=$host_cpu-$host_os

m4_include([common/m4/qmake.m4])

m4_include([common/m4/omhome.m4])
FIND_OPENMODELICAHOME()
FIND_LIBOPENMODELICACOMPILER()
FIND_LIBOMQWT()

dnl The animation windows render with Qt Quick 3D.
dnl Override with WITH_ANIMATION=0 where that module is missing.
if test -z "$WITH_ANIMATION"; then
  WITH_ANIMATION=1
else
  AC_MSG_RESULT([WITH_ANIMATION=$WITH_ANIMATION])
fi

if test "$WITH_ANIMATION" = 0; then
  CPPFLAGS="$CPPFLAGS -DWITHOUT_ANIMATION"
  AC_MSG_RESULT("Disabled 3D animation")
else
  QMAKE_CONFIG_ANIMATION="CONFIG += animation"
  AC_MSG_RESULT("3D animation is enabled")
fi

AC_MSG_CHECKING([check if -lboost_regex is needed for OMSimulator])
AC_RUN_IFELSE( [AC_LANG_PROGRAM([[
#include <regex>
// adrpo: crap regex handling
#if __cplusplus >= 201103L &&                             \
    (!defined(__GLIBCXX__) || (__cplusplus >= 201402L) || \
        (defined(_GLIBCXX_REGEX_DFS_QUANTIFIERS_LIMIT) || \
         defined(_GLIBCXX_REGEX_STATE_LIMIT)           || \
             (defined(_GLIBCXX_RELEASE)                && \
             _GLIBCXX_RELEASE > 4)))
#define OMS_GOOD_REGEX 1
#else /* bad regex, filter by MSVC */
#if defined(_MSC_VER)
#define OMS_GOOD_REGEX 1
#else /* surely bad regex */
#define OMS_GOOD_REGEX 0
#endif
#endif
]],
[[
#if OMS_GOOD_REGEX
#else
exit(1);
#endif
]])],
  [AC_MSG_RESULT([no need for -lboost_regex, std::regex is good enough])],
  [AC_MSG_RESULT([bad std::regex, -lboost_regex is needed]); LIB_BOOST_REGEX=-lboost_regex]
  )


for flag in -Wno-clobbered; do
  OLD_CXXFLAGS="$CXXFLAGS"
  CXXFLAGS="$CXXFLAGS $flag -Werror"
  AC_LINK_IFELSE([AC_LANG_PROGRAM([[]], [[return 0;]])],[CXXFLAGS="$OLD_CXXFLAGS $flag"],[CXXFLAGS="$OLD_CXXFLAGS"])
done

AC_MSG_CHECKING([for LSB description])
LSB_RELEASE="`lsb_release -ds | tr -d '\"'`"
if test ! -z "$LSB_RELEASE"; then
  AC_MSG_RESULT([$LSB_RELEASE])
  LSB_RELEASE="#define LSB_RELEASE \"$LSB_RELEASE\""
else
  AC_MSG_RESULT([no])
fi

if echo $host | grep -i darwin; then
  SHREXT=".dylib"
else
  SHREXT=".so"
fi

m4_include([common/m4/semver.m4])
SOURCE_REVISION="$SOURCE_REVISION$NON_FREE_VERSION"

AC_CONFIG_FILES([Makefile.unix omedit_config.h OMEdit.animation.unix.config.pri OMEditLIB/OMEditLIB.unix.config.pri OMEditLIB/Debugger/Parser/Makefile.unix OMEditLIB/Debugger/Parser/Makefile.lib.unix OMEditGUI/OMEditGUI.unix.config.pri Testsuite/Makefile.unix])
AC_OUTPUT
