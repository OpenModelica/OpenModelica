dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OMEdit],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_SUBST(APP)
AC_SUBST(EXE)
AC_SUBST(IDLCMD)
AC_SUBST(RPATH_QMAKE)
AC_SUBST(host_short)
AC_SUBST(SOURCE_REVISION)
AC_SUBST(QT4BUILD)
AC_SUBST(QMAKE_CONFIG_OSG)
AC_SUBST(LIBOSG)
AC_SUBST(LSB_RELEASE)
AC_SUBST(LIB_BOOST_REGEX)

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

if test -z "$WITH_OSG"; then
  WITH_OSG=1
else
  AC_MSG_RESULT([WITH_OSG=$WITH_OSG])
fi

if test "$WITH_OSG" = 1; then
  AC_PREPROC_IFELSE(
        [AC_LANG_PROGRAM([[]], [[]])],
  [],
  [AC_MSG_ERROR([C++ preprocessor broken?])]
  )
  AC_MSG_CHECKING([for osg/qt include order bugs (broken OSG version)])
  AC_PREPROC_IFELSE(
        [AC_LANG_PROGRAM([[
#include <osg/Version>
#if __arm__==1 && __clang_major__==3 && __clang_minor__==4 && OPENSCENEGRAPH_MAJOR_VERSION==3 && OPENSCENEGRAPH_MINOR_VERSION==2 && OPENSCENEGRAPH_PATCH_VERSION==0
#error "ARM+clang 3.4+OSG3.2.0 does not work together"
#endif
]],
  [[]])],
  [AC_MSG_RESULT([OK])],
  [AC_MSG_RESULT([no (giving up on OSG)]); WITH_OSG=0]
  )
  CPPFLAGS="$OLD_CPPFLAGS"
fi

if test "$WITH_OSG" = 1; then
  AC_MSG_CHECKING([for osg/qt broken OpenGL])
  OLD_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="$CPPFLAGS -Wl,--unresolved-symbols=ignore-all"
  AC_LINK_IFELSE( [AC_LANG_PROGRAM([[]], [[]])],
    [],
    [CPPFLAGS="$OLD_CPPFLAGS"]
  )
  CPPFLAGS="$CPPFLAGS -fPIC -I$QT_INSTALL_HEADERS -I$QT_INSTALL_HEADERS/QtOpenGL"
  AC_LINK_IFELSE(
        [AC_LANG_PROGRAM([[
#include <osgViewer/GraphicsWindow>
#include <QGLWidget>
]],
  [[]])],
  [AC_MSG_RESULT([OK])],
  [AC_MSG_RESULT([no (giving up on OSG)]); WITH_OSG=0]
  )
  CPPFLAGS="$OLD_CPPFLAGS"
fi

if test "$WITH_OSG" = 1; then
  AC_MSG_CHECKING([for osg/qt broken OpenGL])
  OLD_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="$CPPFLAGS -Wl,--unresolved-symbols=ignore-all"
  AC_LINK_IFELSE( [AC_LANG_PROGRAM([[]], [[]])],
    [],
    [CPPFLAGS="$OLD_CPPFLAGS"]
  )
  CPPFLAGS="$CPPFLAGS -fPIC -I$QT_INSTALL_HEADERS -I$QT_INSTALL_HEADERS/QtOpenGL -I$QT_INSTALL_HEADERS/QtWidgets"
  AC_LINK_IFELSE(
        [AC_LANG_PROGRAM([[
#include <osg/GL>
#include <QtWidgets>
]],
  [[]])],
  [AC_MSG_RESULT([OK])],
  [AC_MSG_RESULT([no (giving up on OSG)]); WITH_OSG=0]
  )
  CPPFLAGS="$OLD_CPPFLAGS"
fi

if test "$WITH_OSG" = 1; then
  AC_CHECK_HEADERS(osg/Uniform, [], [WITH_OSG=0])
fi

if test "$WITH_OSG" = 0; then
  CPPFLAGS="$CPPFLAGS -DWITHOUT_OSG"
  AC_MSG_RESULT("Disabled OSG")
else
  QMAKE_CONFIG_OSG="CONFIG += osg"
  LIBOSG="-losg -losgViewer -losgDB -losgGA -lOpenThreads"
  AC_MSG_RESULT("OSG is enabled")
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


for flag in -Wno-clobbered -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter; do
  OLD_CXXFLAGS="$CXXFLAGS"
  CXXFLAGS="$CXXFLAGS $flag -Werror"
  AC_TRY_LINK([], [return 0;], [CXXFLAGS="$OLD_CXXFLAGS $flag"],[CXXFLAGS="$OLD_CXXFLAGS"])
done

AC_MSG_CHECKING([for LSB description])
LSB_RELEASE="`lsb_release -ds | tr -d '\"'`"
if test ! -z "$LSB_RELEASE"; then
  AC_MSG_RESULT([$LSB_RELEASE])
  LSB_RELEASE="#define LSB_RELEASE \"$LSB_RELEASE\""
else
  AC_MSG_RESULT([no])
fi

m4_include([common/m4/semver.m4])
SOURCE_REVISION="$SOURCE_REVISION$NON_FREE_VERSION"

AC_OUTPUT(Makefile OMEdit/OMEditGUI/Makefile.unix OMEdit/OMEditGUI/OMEdit.config OMEdit/OMEditGUI/Debugger/Parser/Makefile.unix OMEdit/OMEditGUI/Debugger/Parser/Makefile.lib.unix OMEdit/OMEditGUI/omc_config.h)
