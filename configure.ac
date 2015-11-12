dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OMCompiler],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])
AC_SUBST(date)
AC_SUBST(host_short)
AC_SUBST(omc_antlr_jar)
AC_SUBST(antlrinc)
AC_SUBST(antlrlib)
AC_SUBST(with_paradiseo)
AC_SUBST(with_paradiseo_include)
AC_SUBST(with_paradiseo_lib)
AC_SUBST(with_qwt)
AC_SUBST(with_qwt_suffix)
AC_SUBST(EXTRA_CFLAGS_GENERATED_CODE)
AC_SUBST(HAVE_GETTEXT)
AC_SUBST(LIBSOCKET)
AC_SUBST(LIBNSL)
AC_SUBST(LIBLPSOLVE55)
AC_SUBST(NO_LPLIB)
AC_SUBST(LPSOLVEINC)
AC_SUBST(OPENCL)
AC_SUBST(USE_GRAPH)
AC_SUBST(USE_METIS)
AC_SUBST(USE_PATOH)
AC_SUBST(GRAPHLIB)
AC_SUBST(GENERATED_AUTOCONF_FILES)
AC_SUBST(RT_LDFLAGS)
AC_SUBST(RT_LDFLAGS_OPTIONAL)
AC_SUBST(RT_LDFLAGS_SIM)
AC_SUBST(RT_LDFLAGS_SIM_OPTIONAL)
AC_SUBST(RT_LDFLAGS_GENERATED_CODE)
AC_SUBST(RT_LDFLAGS_GENERATED_CODE_SIM)
AC_SUBST(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU)
AC_SUBST(SUNDIALS_LDFLAGS)
AC_SUBST(IPOPT_LDFLAGS)
AC_SUBST(IPOPT_CFLAGS)
AC_SUBST(QMAKE)
AC_SUBST(EXE)
AC_SUBST(SOURCE_REVISION)
AC_SUBST(OMSHELL_TERMINAL)
AC_SUBST(MODELICA_SPEC_PLATFORM)
AC_SUBST(OPENMODELICA_SPEC_PLATFORM)
AC_SUBST(OMC_LIBS)
AC_SUBST(OMPCC)
AC_SUBST(RUNTIMECC)
AC_SUBST(RUNTIMECFLAGS)
AC_SUBST(MAKE)
AC_SUBST(LD_LAPACK)
AC_SUBST(NO_LAPACK)
AC_SUBST(WITH_SUNDIALS)
AC_SUBST(WITH_IPOPT)
AC_SUBST(WITH_UMFPACK)
AC_SUBST(UMFPACK_TARGET)
AC_SUBST(UMFPACK_LDFLAGS)
AC_SUBST(OMNOTEBOOK)
AC_SUBST(FPMATHFORTRAN)
AC_SUBST(OMOPTIM_CC)
AC_SUBST(OMOPTIM_CXX)
AC_SUBST(LIBGC)
AC_SUBST(LIBSIMULATION)
AC_SUBST(LIBRUNTIME)
AC_SUBST(LIBFMIRUNTIME)
AC_SUBST(LIBFMILIB)
AC_SUBST(WITH_FMIL)
AC_SUBST(NO_FMIL)
AC_SUBST(FMILIB_SHARED)
AC_SUBST(LIBCMINPACKLIB)
AC_SUBST(CMINPACKLIB_SHARED)
AC_SUBST(SHREXT)
AC_SUBST(LINK)
AC_SUBST(RPATH)
AC_SUBST(RPATH_QMAKE)
AC_SUBST(MSL_EXTRA_ARGS)
AC_SUBST(WITH_HWLOC)
AC_SUBST(OS_TARGET)
AC_SUBST(LIS_LDFLAGS)
AC_SUBST(LAPACK_TARGET)
AC_SUBST(CONFIG_WITH_OPENMP)
AC_SUBST(OPENBLAS_EXTRA_ARGS)
AC_SUBST(AR)
AC_SUBST(AR_SH)
AC_SUBST(LDFLAGS_SOCKET)
AC_SUBST(APP)
AC_SUBST(OMC)
AC_SUBST(OMCTARGET)
AC_SUBST(BOOTSTRAP_STATIC)
AC_SUBST(LIBDL)
AC_SUBST(LIBDL)
AC_SUBST(BOOST_INCLUDE)
AC_SUBST(LDFLAGS_LIBSTDCXX)
AC_SUBST(CPP_RUNTIME_ARGS)

FINAL_MESSAGES="\nConfigured OpenModelica successfully using the following options:"

m4_include([common/m4/pre-commit.m4])
cp common/install-sh common/config.guess common/config.sub ./
m4_include([common/m4/ombuilddir.m4])

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

build_short=$build_cpu-$build_os
host_short=$host_cpu-$host_os

echo "build_short: $build_short"
echo "host_short: $host_short"

if echo $host | grep -i darwin; then
  DARWIN=1
else
  DARWIN=0
fi

if test -z "$AR"; then
  AR=ar
fi

if test -z "$MAKE"; then
  MAKE=make
fi

AC_ARG_ENABLE(non-free-packages, [  --enable-non-free-packages     Enables you to link non-free packages. But doing so limits your ability to distribute code under GPL3, even to co-workers and the like. If you are an OSMC member you might be allowed to link and ship such libraries if you have a commercial license for the linked packages.],[test "yes" = "$enableval" && ENABLE_NON_FREE_PACKAGES=1 && NON_FREE_VERSION=") (non-free version for personal use only; seriously do not distribute this binary"] && FINAL_MESSAGES="$FINAL_MESSAGES\nLinking against non-free packages: Yes (this version of omc not for distribution)")

dnl Checks for programs.
AC_LANG([C])
AC_PROG_CC
AC_PROG_CXX
AC_PROG_CPP
AC_PROG_MAKE_SET
AC_PROG_FC

CFLAGS_BEFORE="$CFLAGS"
CFLAGS="$CFLAGS -Werror"
AC_MSG_CHECKING([if -Werror works])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([ok])], [AC_MSG_ERROR([failed (check your CFLAGS)])])
CFLAGS="$CFLAGS_BEFORE"

dnl Disables the default CFLAGS="-g -O2"
if test -z "$CFLAGS"; then
if test "$DARWIN" = "1"; then
CFLAGS="-O3"
else
CFLAGS_BEFORE="$CFLAGS"
CFLAGS="-O3 -march=native"
AC_MSG_CHECKING([looking for -march=native])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([yes])], [AC_MSG_RESULT([no]);CFLAGS="-O3"])
fi
fi

dnl Disables the default CFLAGS="-g -O2"
LDFLAGS_BEFORE="$LDFLAGS"
LDFLAGS="$LDFLAGS -Wl,--no-undefined"
AC_MSG_CHECKING([looking for --no-undefined])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([yes]);LD_NOUNDEFINED=" -Wl,--no-undefined"], [AC_MSG_RESULT([no])])
LDFLAGS="$LDFLAGS_BEFORE"

TRY_FLAGS="-fno-stack-protector"

# GCC 5.x generates bad code due to detecting some impure functions as pure
if $CC --version | grep -q gcc && $CC -dumpversion | grep -q "^5"; then
  TRY_FLAGS="$TRY_FLAGS -fno-ipa-pure-const"
fi

for flag in $TRY_FLAGS; do
  OLD_CFLAGS="$CFLAGS"
  CFLAGS="$RUNTIMECFLAGS $flag -Werror"
  AC_TRY_LINK([], [return 0;], [CFLAGS="$OLD_CFLAGS $flag"],[CFLAGS="$OLD_CFLAGS"])
done
OLD_CFLAGS="$CFLAGS"
for flag in -Wno-parentheses-equality -Wno-unused-variable; do
  CFLAGS="$RUNTIMECFLAGS $flag -Werror"
  AC_TRY_LINK([], [return 0;], [EXTRA_CFLAGS_GENERATED_CODE="$EXTRA_CFLAGS_GENERATED_CODE $flag"],[])
done
CFLAGS="$OLD_CFLAGS"

if test ! "$DARWIN" = "1"; then

if test "`getconf LONG_BIT`" = "64"; then

AC_MSG_CHECKING([getconf LONG_BIT = 64 CFLAGS])

if echo $CFLAGS | grep -q -- -fPIC; then
  AC_MSG_RESULT([already got -fPIC])
else
  CFLAGS_BEFORE="$CFLAGS"
  CFLAGS="$CFLAGS -fPIC -Werror"
  AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([adding -fPIC]); CFLAGS="$CFLAGS_BEFORE -fPIC"; FPIC="-fPIC"], [AC_MSG_RESULT([does not need -fPIC]); CFLAGS="$CFLAGS_BEFORE"])
fi

else

AC_MSG_CHECKING([getconf LONG_BIT != 64 CFLAGS])

if echo $CFLAGS | grep -q -- -fPIC; then
  AC_MSG_RESULT([already got -fPIC])
else
  CFLAGS_BEFORE="$CFLAGS"
  CFLAGS="$CFLAGS -fPIC -Werror"
  AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([adding -fPIC]); CFLAGS="$CFLAGS_BEFORE -fPIC"; FPIC="-fPIC"], [AC_MSG_RESULT([does not need -fPIC]); CFLAGS="$CFLAGS_BEFORE"])
fi

fi

else # Is Darwin

AC_LANG_PUSH([C++])
OLD_CXXFLAGS=$CXXFLAGS
for flag in -stdlib=libstdc++; do
  CXXFLAGS="$OLD_CXXFLAGS $flag"
  AC_TRY_LINK([], [return 0;], [LDFLAGS_LIBSTDCXX="$flag"],[CXXFLAGS="$OLD_CXXFLAGS"])
done
AC_LANG_POP([C++])

fi

m4_include([common/m4/ax_cxx_compile_stdcxx_11.m4])
HAVE_CXX_STD=0
for flag in $CXXFLAGS; do
  (echo $flag | grep -q "^-std=") && HAVE_CXX_STD=1
done
if test "$HAVE_CXX_STD" = 0; then
  AX_CXX_COMPILE_STDCXX_11([noext],[optional])
fi

if test "`getconf LONG_BIT`" = "32"; then
dnl Simulations spin forever unless -msse2 -mfpmath=sse is set

CFLAGS_BEFORE=$CFLAGS
CFLAGS="-mfpmath=sse -Werror"
AC_MSG_CHECKING([for floating point bugs])
AC_TRY_LINK([int abc() {}], [abc();], [AC_MSG_RESULT([force SSE2]); FPMATHFORTRAN="-msse -mfpmath=sse"], [AC_MSG_RESULT([no]); FPMATHFORTRAN=-ffloat-store])
CFLAGS=$CFLAGS_BEFORE

fi # End x86-specific CFLAGS

dnl check for environment variables

AC_ARG_WITH(omc,  [  --with-omc=[omc]       (the installed omc path which we will use to compile omc)],[OMC="$withval"],[OMC=`which omc`])
while test -h "$OMC"; do
  OMC=`readlink "$OMC"`
done

AC_MSG_CHECKING([for omc])

if test "$OMC" = "no" ; then
  if test "$host" != "$build"; then
    AC_MSG_ERROR([cross-compilation attempt detected, but no omc executable was given])
  fi
  AC_MSG_RESULT([building it through bootstrapping (you might end up unable to recompile omc if you modify source code)])
  OMC="$OMBUILDDIR/bin/omc"
elif "$OMC" --version > /dev/null 2>&1; then
  AC_MSG_RESULT([$OMC])
else
  AC_MSG_RESULT([failed (tried $OMC). Building it through bootstrapping (you might end up unable to recompile omc if you modify source code).])
  OMC="$OMBUILDDIR/bin/omc"
fi

dnl Checks for libraries.

if test ! "$DARWIN" = "1" && (! echo $host | grep -q mingw ); then
  LIBS=""
  AC_SEARCH_LIBS(clock_gettime,rt,[],[AC_MSG_ERROR([clock_gettime missing])])
  LIBRT="$LIBS"
  LIBS=""
fi

dnl Checks for boost include for Mac.

if test ! "$DARWIN" = "1"; then
  if test -f "$prefix/include/boost/array.hpp"; then
    BOOST_INCLUDE="-DBOOST_ROOT=$prefix/include/"
  else
    if test -f "/opt/local/include/boost/array.hpp"; then
      BOOST_INCLUDE="-DBOOST_ROOT=/opt/local/include/"
    else
      BOOST_INCLUDE=""
    fi
  fi
else
  BOOST_INCLUDE=""
fi


dnl Checks for header files.
AC_HEADER_STDC

AC_CHECK_HEADERS(sys/time.h, [], [AC_MSG_ERROR(Missing header files)])
# AC_CHECK_HEADERS(sqlite3.h, [], [AC_MSG_ERROR(Missing header files)])

AC_MSG_CHECKING([for antlr.Tool support])
mkdir -p "$OMBUILDDIR/share/omc/java"
cp "3rdParty/antlr/3.2/tool/antlr-3.2.jar" "3rdParty/antlr/3.2/tool/antlr-2.7.7.jar" $OMBUILDDIR/share/omc/java/
echo "" > $$grammar.g
if java -cp "$OMBUILDDIR/share/omc/java/antlr-3.2.jar" antlr.Tool $$grammar.g ; then
  rm -f $$grammar.g
  AC_MSG_RESULT([yes])
else
  rm -f $$grammar.g
  AC_MSG_ERROR([no antlr.Tool support (JRE not working)])
fi

dnl Misc. headers

AC_CHECK_HEADER(expat.h,,
  CPPFLAGS="$CPPFLAGS -I \"$ac_top_srcdir/3rdParty/FMIL/Expat/lib\""
  AC_MSG_RESULT([using local expat.h])
)

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T

dnl Checks for library functions.
AC_FUNC_VPRINTF
AC_CHECK_FUNCS(getcwd select strdup strerror)


dnl Check if scandir is available
AC_MSG_CHECKING([for scandir])

AC_TRY_LINK([
#include <dirent.h>
], [
int file_select_directories(const struct dirent *entry) {
 return 0;
}

int main() {
char dir[]=".";
int count;
struct dirent **files;
scandir(dir, &files, file_select_directories, 0);
return 0;
}
], [AC_MSG_RESULT([yes]); AC_DEFINE([HAVE_SCANDIR])],
      [AC_MSG_RESULT([no])])

dnl Check if OpenMP is available
AC_MSG_CHECKING([for OpenMP])

AC_ARG_VAR(OMPCC, [Selects a compiler to be used to compile OpenMP code. Useful if the main CC does not support OpenMP.])

CC_OLD="$CC"
CFLAGS_OLD="$CFLAGS"
if test -z "$OMPCC"; then
  CFLAGS=" -fopenmp"
else
  CC="$OMPCC"
  CFLAGS=""
fi

AC_TRY_LINK([
#if !defined(_OPENMP)
  #error "Not an OpenMP compiler"
#endif
#include <omp.h>
#include <stdio.h>
], [int main() {
  int i;
#pragma omp parallel for private(i) schedule(dynamic)
  for (i=0; i<16; i++)
    printf("Thread %d\n", i);
  return 0;
}
], [OMPCC="$CC$CFLAGS"; AC_MSG_RESULT([$OMPCC]); CONFIG_WITH_OPENMP=1],
  [
  if test -z "$OMPCC"; then
    OMPCC="$CC_OLD"
    AC_MSG_RESULT([no]);
  else
    AC_MSG_ERROR([failed (user gave $OMPCC)]);
  fi
  CONFIG_WITH_OPENMP=0
  ]
)
CC="$CC_OLD"
CFLAGS="$CFLAGS_OLD"

AC_ARG_VAR(RUNTIMECC, [Selects a compiler to be used to compile generated code. It is more important to compile fast than to generate fast code for the runtime compiler.])
AC_ARG_VAR(RUNTIMECFLAGS, [CFLAGS for the selected runtime compiler (defaults to -O0 -falign-functions -march=native -mfpmath=sse -fPIC as long as neither gives warnings to the CC). Note that heavy optimisations may cause the run-time to be faster while increasing compile-time. -O0 is often best.])

CC_OLD="$CC"
CFLAGS_OLD="$CFLAGS"
if test ! -z "$RUNTIMECC"; then
  CC="$RUNTIMECC"
else
  RUNTIMECC="$CC"
fi
AC_MSG_CHECKING([runtime compiler])
if test -z "$RUNTIMECFLAGS"; then
  CFLAGS="$FPIC -Werror"
  AC_TRY_LINK([], [return 0;], [AC_MSG_RESULT($CC ok);],[AC_MSG_ERROR($CC failed)])
  CFLAGS="$FPIC"
  AC_MSG_CHECKING([runtime compiler CFLAGS])
  for flag in -O0 -falign-functions -march=native -mfpmath=sse; do
    RUNTIMECFLAGS="$CFLAGS"
    CFLAGS="$RUNTIMECFLAGS $flag -Werror"
    AC_TRY_LINK([], [return 0;], [CFLAGS="$RUNTIMECFLAGS $flag"],[CFLAGS="$RUNTIMECFLAGS"])
  done
else
  CFLAGS="$RUNTIMECFLAGS $FPIC -Werror"
  AC_TRY_LINK([], [return 0;], [RUNTIMECFLAGS="$RUNTIMECFLAGS $FPIC"],[AC_MSG_ERROR([$CC $CFLAGS -Werror failed])])
fi
AC_MSG_RESULT([$RUNTIMECFLAGS])

LIBS=""
AC_SEARCH_LIBS(dlopen,dl)
LIBDL="$LIBS"
LIBS=""

CC="$CC_OLD"
CFLAGS="$CFLAGS_OLD"

if echo "$host" | grep -q "mingw"; then
  true
else
dnl check for lpsolve55

AC_ARG_WITH(lpsolve,  [  --with-lpsolve        (default searching for lpsolve; disable if only using omc to cross-compile)],[if test "$withval" = "no"; then NO_LPLIB="#define NO_LPLIB"; fi],[])

if test -z "$NO_LPLIB"; then

echo "NO_LPLIB: '$NO_LPLIB'"

AC_ARG_WITH(static-lpsolve,  [  --with-static-lpsolve=DIR        (default to dynamic linking; searches /usr if no other directory is provided)],[WANT_STATIC_LPSOLVE="$withval"],[WANT_STATIC_LPSOLVE="no"])

if test "$WANT_STATIC_LPSOLVE" = "no"; then
  LIBS=""
  AC_SEARCH_LIBS(dlopen,dl)
  LIBDL="$LIBS"
  AC_SEARCH_LIBS(sqrt,m)
  AC_SEARCH_LIBS(colamd,colamd)
  AC_SEARCH_LIBS(make_lp,[lpsolve55_pic lpsolve55],[],[AC_MSG_ERROR([lpsolve linking failed using $LIBS])])
  LIBLPSOLVE55=$LIBS
  LIBS=""
else
  if test "$WANT_STATIC_LPSOLVE" = "yes"; then
    LPLIB=/usr/lib;
  else
    LPLIB=$WANT_STATIC_LPSOLVE/lib
  fi
  LIBS=""
  AC_SEARCH_LIBS(dlopen,dl)
  AC_SEARCH_LIBS(sqrt,m)
  LIBS="$LPLIB/liblpsolve55_pic.a $LPLIB/libcolamd.a $LIBS"
  AC_MSG_CHECKING([for static lpsolve55])
  AC_LINK_IFELSE([AC_LANG_CALL([], [make_lp])], [LIBLPSOLVE55=$LIBS], [AC_MSG_ERROR([failed])])
  AC_MSG_RESULT([$LIBLPSOLVE55])
  LIBS=""
fi
AC_CHECK_HEADER([lp_lib.h],[LPSOLVEINC=lp_lib.h],[
  AC_CHECK_HEADER([lpsolve/lp_lib.h],[LPSOLVEINC=lpsolve/lp_lib.h],[AC_MSG_ERROR([failed to find lpsolve55 headers])])
])

fi
fi # NO_LPLIB

if ! (echo "$host" | grep -q "mingw"); then
  AC_CHECK_FUNC(socket,[LIBSOCKET=""],
   [AC_MSG_CHECKING([for libsocket]);
    AC_CHECK_LIB(socket, socket,[AC_MSG_RESULT([yes]); LIBSOCKET="-lsocket"],[AC_MSG_ERROR([neither socket nor libsocket.a found])])
  ])

  AC_CHECK_FUNC(gethostbyname,
   [LIBNSL=""],
   [AC_MSG_CHECKING([for libnsl]);
    AC_CHECK_LIB(nsl,gethostbyname, [AC_MSG_RESULT([yes]); LIBNSL="-lnsl"],[AC_MSG_ERROR([neither gethostbyname nor libnsl.a found])])
  ])
fi


# Sqlite is not used
if false; then

AC_ARG_WITH(static-sqlite,  [  --with-static-sqlite=FILE        (default to dynamic linking)],[WANT_STATIC_SQLITE="$withval"],[WANT_STATIC_SQLITE="no"])

LIBS=""
AC_CHECK_LIB(sqlite3,sqlite3_libversion,[],[AC_MSG_ERROR([sqlite3 not found])])

if test "$WANT_STATIC_SQLITE" = "no"; then
  OMC_LIBS=$LIBS
elif test ! -f "$WANT_STATIC_SQLITE" ; then
  AC_ERROR([File not found: $WANT_STATIC_SQLITE])
else
  OMC_LIBS=$WANT_STATIC_SQLITE
fi

fi

# Cannot use AX_LAPACK since it assumes a Fortran compiler is used
AC_ARG_WITH(lapack,  [  --with-lapack=[-llapack -lblas]    (use -llapack -lblas to use system-provided version instead of OpenBLAS. Use openblas for automatically detected OpenBLAS. Use --with-lapack=openblas-NEHALEM or other OpenBLAS target to compile against a certain architecture. Note that you need to include BLAS in this.)],[LD_LAPACK="$withval"],[LD_LAPACK="-llapack -lblas"])

if test "$LD_LAPACK" = "no"; then
  FINAL_MESSAGES="$FINAL_MESSAGES\nLAPACK IS NOT AVAILABLE! ONLY USED FOR CROSS-COMPILING/BOOTSTRAPPING"
  LD_LAPACK=""
  NO_LAPACK="#define NO_LAPACK"
else

AC_MSG_CHECKING([LAPACK/BLAS flags])
if echo "$LD_LAPACK" | grep -oq "^openblas"; then
  LD_LAPACK=`echo $LD_LAPACK | sed s/"^openblas-//"`
  if test "$LD_LAPACK" = "openblas"; then
    AC_MSG_RESULT([OpenBLAS compiled using auto detected architecture])
  else
    OPENBLAS_EXTRA_ARGS="TARGET=$LD_LAPACK"
    AC_MSG_RESULT([OpenBLAS compiled using architecture $LD_LAPACK])
  fi
  LD_LAPACK="-lopenblas_openmodelica"
  LAPACK_TARGET="openblas"
else
  LIBS="$LD_LAPACK"
  AC_LINK_IFELSE([AC_LANG_CALL([], [dgesv_])],[],[AC_MSG_ERROR([dgesv (LAPACK) linking failed using $LD_LAPACK])])
  AC_LINK_IFELSE([AC_LANG_CALL([], [dswap_])],[AC_MSG_RESULT([$LD_LAPACK])],[AC_MSG_ERROR([dswap (BLAS) linking failed using $LD_LAPACK])])
fi
fi

AC_CHECK_HEADERS(kinsol/kinsol.h kinsol/kinsol_dense.h nvector/nvector_serial.h sundials/sundials_types.h sundials/sundials_math.h,[],[NO_SUNDIALS="yes"])
SUNDIALS_LDFLAGS="-lsundials_kinsol -lsundials_nvecserial $LD_LAPACK"
LIBS="$SUNDIALS_LDFLAGS -lm"
AC_MSG_CHECKING([Sundials linking])
AC_LINK_IFELSE([AC_LANG_CALL([], [KINInit])],
  [AC_MSG_RESULT([ok])],
  [LIBS="-lsundials_kinsol -lsundials_nvecserial -llapack -lblas -lm";
  AC_LINK_IFELSE([AC_LANG_CALL([], [KINInit])],
  [AC_MSG_RESULT([ok])],[AC_MSG_RESULT([failed to link KINInit]); NO_SUNDIALS="yes"])])

if ! test "$NO_SUNDIALS" = "yes"; then
  FINAL_MESSAGES="$FINAL_MESSAGES\nSimulations may use sundials suite: Yes"
  WITH_SUNDIALS="#define WITH_SUNDIALS"
else
  FINAL_MESSAGES="$FINAL_MESSAGES\nSimulations may use sundials suite: No"
  WITH_SUNDIALS="/* Without Sundials */"
# We need -llapack regardless if we use Sundials or not
  SUNDIALS_LDFLAGS="$LD_LAPACK"
fi

LIBS=""

AC_CHECK_HEADERS(locale.h libintl.h,[
AC_MSG_CHECKING([gettext linking])
AC_TRY_LINK([
#include <libintl.h>
], [
  gettext("");
], [AC_MSG_RESULT([in C-library])],
  [
  LIBS="-lintl";
  AC_TRY_LINK([
    #include <libintl.h>
  ], [
      gettext("");
  ], [AC_MSG_RESULT([in intl]);RT_LDFLAGS_OPTIONAL="$RT_LDFLAGS_OPTIONAL $LIBS"],
      [
        HAVE_GETTEXT="#define NO_GETTEXT 1"
        AC_MSG_RESULT([no])
      ])
])
],[
  HAVE_GETTEXT="#define NO_GETTEXT 1"
  AC_MSG_RESULT([gettext headers not found])
])

LIBS=""
AC_CHECK_HEADERS(hwloc.h,
  [AC_CHECK_LIB(hwloc,hwloc_get_nbobjs_by_depth,
    [WITH_HWLOC="#define WITH_HWLOC 1";OMC_LIBS="$OMC_LIBS -lhwloc"],
    [WITH_HWLOC="/* Without hwloc */"])],
  [WITH_HWLOC="/* Without hwloc */"]
)

LIBS=""

AC_CHECK_LIB(pthread,pthread_self,[RT_LDFLAGS="$RT_LDFLAGS $LIBS"],[AC_MSG_ERROR([pthreads not found])])

LIBS=""

if ! test "$NO_IPOPT" = "yes"; then
  FINAL_MESSAGES="$FINAL_MESSAGES\nSimulations may use IPOPT: Yes"
  WITH_IPOPT="#define WITH_IPOPT"
  IPOPT_LDFLAGS="-lipopt -lcoinmumps"
else
  FINAL_MESSAGES="$FINAL_MESSAGES\nSimulations may use IPOPT: No"
  WITH_IPOPT="/* Without IPOPT */"
  IPOPT_CFLAGS=""
  IPOPT_LDFLAGS=""
fi

# check for umfpack
AC_ARG_WITH(UMFPACK, [  --without-UMFPACK              Disable compilation with UMFPACK, a sparse linear systems solver],
[],[with_UMFPACK=yes])

AS_IF([test "x$with_UMFPACK" = xyes],
[
  FINAL_MESSAGES="$FINAL_MESSAGES\nSimulations may use UMFPACK: Yes"
  UMFPACK_TARGET="umfpack";
  WITH_UMFPACK="#define WITH_UMFPACK"
  UMFPACK_LDFLAGS="-lumfpack -lklu -lbtf -lcolamd -lamd"
],[
  FINAL_MESSAGES="$FINAL_MESSAGES\nSimulations may use UMFPACK: No"
  UMFPACK_TARGET="";
  WITH_UMFPACK="/* Without UMFPACK */"
  UMFPACK_LDFLAGS=""
])

m4_include([common/m4/corba.m4])

AC_MSG_CHECKING([for OpenCL])
AC_CHECK_HEADER([CL/cl.h],[OPENCL="Yes"],[
  AC_CHECK_HEADER([OpenCL/cl.h],[OPENCL="Yes"],[OPENCL="No"])
])
FINAL_MESSAGES="$FINAL_MESSAGES\nParModelica: $OPENCL"

AC_SUBST(CMAKE_LDFLAGS)
if test "$DARWIN" = "1"; then
  APP=".app"
  EXE=".app"
  SHREXT=".dylib"
  LIBGC="$OMBUILDDIR/lib/$host_short/omc/libomcgc.a"
  LIBSIMULATION=libSimulationRuntimeC.dylib
  LIBRUNTIME=libOpenModelicaRuntimeC.dylib
  LIBFMIRUNTIME=libOpenModelicaFMIRuntimeC.dylib
  LIBFMILIB=libfmilib_shared.dylib
  FMILIB_SHARED=ON
  LIBCMINPACKLIB=libcminpack.dylib
  CMINPACKLIB_SHARED=ON
  RT_LDFLAGS_SIM="$LDFLAGS $RT_LDFLAGS -lexpat -lomcgc -lpthread -lm $LIBDL -lstdc++"
  RT_LDFLAGS_SIM_OPTIONAL="$SUNDIALS_LDFLAGS $IPOPT_LDFLAGS $UMFPACK_LDFLAGS -llis -lcdaskr -lcminpack -liconv"
  RT_LDFLAGS="$LDFLAGS $RT_LDFLAGS -lomcgc -lm -lpthread $LIBDL -lstdc++"
  RT_LDFLAGS_OPTIONAL="$RT_LDFLAGS_OPTIONAL -liconv"
  # All libraries are dynamically linked; we don't need anything else
  RT_LDFLAGS_GENERATED_CODE="$LDFLAGS -lOpenModelicaRuntimeC $LD_LAPACK -lm"
  RT_LDFLAGS_GENERATED_CODE_SIM="$LDFLAGS -lSimulationRuntimeC $LD_LAPACK -lm -lomcgc"
  RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU="$LDFLAGS $LD_LAPACK -lm$LD_NOUNDEFINED"
  LINK="cp -fr"
  RPATH="-Wl,-rpath,'@loader_path/../lib/$host_short/omc/'"
  RPATH_QMAKE="-Wl,-rpath,'@loader_path/../../../../lib/$host_short/omc',-rpath,'@loader_path/../../../../lib/',-rpath,'$PREFIX/lib/$host_short/omc',-rpath,'$PREFIX/lib/'"
  MSL_EXTRA_ARGS="--disable-hdf5 --enable-static-zlib --enable-static --enable-shared"
  OS_TARGET="osx"
  LIS_LDFLAGS="-Wl,-install_name,@rpath/liblis.dylib"
  AR_SH="sh -x ar.sh"
  OMC_LIBS="$(OMC_LIBS) -Wl,-undefined -Wl,dynamic_lookup"
  BOOTSTRAP_STATIC=""
  CMAKE_LDFLAGS="-Wl,-undefined -Wl,dynamic_lookup"
elif test "$host" = "i586-pc-mingw32msvc"; then
  APP=".exe"
  EXE=".exe"
  # Yes, we build static libs on Windows, so the "shared" extension is .a
  SHREXT=".a"
  LIBGC="$OMBUILDDIR/lib/$host_short/omc/libomcgc.a"
  LIBSIMULATION=libSimulationRuntimeC.a
  LIBRUNTIME=libOpenModelicaRuntimeC.a
  LIBFMIRUNTIME=libOpenModelicaFMIRuntimeC.a
  LIBFMILIB=libfmilib.a
  FMILIB_SHARED=OFF
  LIBCMINPACKLIB=libcminpack.a
  CMINPACKLIB_SHARED=OFF
  RT_LDFLAGS_SIM="$LDFLAGS $RT_LDFLAGS -lstdc++ -lomcgc -lexpat -lm"
  RT_LDFLAGS_SIM_OPTIONAL="$SUNDIALS_LDFLAGS $IPOPT_LDFLAGS $UMFPACK_LDFLAGS -llis -lcminpack"
  RT_LDFLAGS="$LDFLAGS $RT_LDFLAGS -lomcgc -lexpat -lpthread -lm"
  RT_LDFLAGS_OPTIONAL="$RT_LDFLAGS_OPTIONAL"
  RT_LDFLAGS_GENERATED_CODE="$LDFLAGS -lOpenModelicaRuntimeC $RT_LDFLAGS"
  RT_LDFLAGS_GENERATED_CODE_SIM="$LDFLAGS -lSimulationRuntimeC -lcdaskr $RT_LDFLAGS_SIM"
  RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU="$LDFLAGS $LD_LAPACK -lm$LD_NOUNDEFINED"
  LINK="cp -frl"
  RPATH="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib/$host_short/omc' -Wl,-rpath,'\$\$ORIGIN'"
  RPATH_QMAKE="-Wl,-z,origin -Wl,-rpath,\\'\\\$\$ORIGIN/../lib/$host_short/omc\\' -Wl,-rpath,\\'\\\$\$ORIGIN\\'"
  OS_TARGET="windows"
  AR_SH="$AR -ru"
  LDFLAGS_SOCKET=" -lwsock32"
  BOOTSTRAP_STATIC="static"
else
  APP=""
  EXE=""
  SHREXT=".so"
  LIBGC="$OMBUILDDIR/lib/$host_short/omc/libomcgc.so"
  LIBSIMULATION=libSimulationRuntimeC.so
  LIBRUNTIME=libOpenModelicaRuntimeC.so
  LIBFMIRUNTIME=libOpenModelicaFMIRuntimeC.so
  LIBFMILIB=libfmilib_shared.so
  FMILIB_SHARED=ON
  LIBCMINPACKLIB=libcminpack.so
  CMINPACKLIB_SHARED=ON
  # For static runtime on Linux:
  # -Wl,-whole-archive -lSimulationRuntimeC -Wl,-no-whole-archive
  RT_LDFLAGS_SIM="$LDFLAGS -Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN' $RT_LDFLAGS $LIBRT -lexpat -lomcgc -lpthread -lm $LIBDL -lstdc++ -rdynamic"
  RT_LDFLAGS_SIM_OPTIONAL="$SUNDIALS_LDFLAGS $IPOPT_LDFLAGS $UMFPACK_LDFLAGS -llis -lcdaskr -lcminpack"
  RT_LDFLAGS="$LDFLAGS $RT_LDFLAGS -lomcgc $LIBRT -lpthread -lm $LIBDL -lstdc++ -rdynamic"
  RT_LDFLAGS_OPTIONAL="$RT_LDFLAGS_OPTIONAL"
  # All libraries are dynamically linked; we don't need anything else
  RT_LDFLAGS_GENERATED_CODE="$LDFLAGS -lOpenModelicaRuntimeC $LD_LAPACK -lm -lomcgc -lpthread -rdynamic" # Some of our tests refer to the testsuite itself
  RT_LDFLAGS_GENERATED_CODE_SIM="$LDFLAGS -lSimulationRuntimeC $LD_LAPACK -lm -lomcgc -lpthread -rdynamic$LD_NOUNDEFINED"
  RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU="$LDFLAGS $LD_LAPACK -lm -lpthread -rdynamic$LD_NOUNDEFINED"
  LINK="cp -frl"
  RPATH="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib/$host_short/omc' -Wl,-rpath,'\$\$ORIGIN'"
  RPATH_QMAKE="-Wl,-z,origin -Wl,-rpath,\\'\\\$\$ORIGIN/../lib/$host_short/omc\\' -Wl,-rpath,\\'\\\$\$ORIGIN\\'"
  OS_TARGET="linux"
  AR_SH="$AR -ru"
  BOOTSTRAP_STATIC=""
fi

AC_ARG_WITH(FMIL, [  --with-FMIL                 Link omc to FMIL (only disable when cross-compiling)],
[
  if test "$withval" = "no"; then
    WITH_FMIL=no
    NO_FMIL="#define NO_FMIL"
  else
    WITH_FMIL=yes
  fi
], [
    WITH_FMIL=yes
])

AC_ARG_WITH(METIS, [  --with-METIS=DIR                 Compile with Metis graph partitioner in DIR],
[
  if test "$withval" = "no"; then
    USE_METIS=0
    USE_GRAPH=0
    USE_PATOH=0
    AC_MSG_RESULT([Disabling METIS...]);
  else
    USE_METIS=1
    USE_GRAPH=1
    AC_MSG_RESULT([Enabling METIS... METISHOME="$withval"]);
    GRAPHLIB="-L$withval -lmetis";
    USE_PATOH=0
  fi
], [
    USE_GRAPH=1
    GRAPHLIB="-L$PREFIX/lib/$host_short/omc -lmetis";
    USE_METIS=1
])

AC_ARG_WITH(PATOH, [  --with-PATOH=DIR                 Compile with PATOH hypergraph partitioner in DIR],
[
    USE_PATOH=1
    if test "$ENABLE_NON_FREE_PACKAGES" = ""; then
      AC_MSG_ERROR([May not compile PATOH unless non-free packages are enabled (enabling those limits your ability to distribute code under GPL3, even to co-workers and the like; if you are an OSMC member you might be allowed to link and ship the library, but only if you have a commercial license...)] )
    fi
    if test "$USE_METIS" = 1; then
      AC_MSG_ERROR([Cannot compile with METIS and PATOH] )
      METISHOME="";
    fi
    USE_METIS=0
    USE_GRAPH=1
    AC_MSG_RESULT([Enabling PATOH... PATOHHOME="$withval"]);
    GRAPHLIB="-L$withval -lpatoh";
], [
    if test "$USE_METIS" = 0; then
        USE_GRAPH=0
    fi
    USE_PATOH=0;
])

m4_include([common/m4/semver.m4])

SOURCE_REVISION="$SOURCE_REVISION$NON_FREE_VERSION"

AC_MSG_CHECKING([for OpenModelica platform name])
# I don't really agree with the Modelica specification since "Intel 32-bit" is
# very unspecific.
# Also, they forgot about Mac users.
# We will just default to use the $host_cpu-$host_os (treating gnu-linux as linux).
# We then patch it up a bit to look for Modelica/FMU standard locations as well.

if test "$DARWIN" = "1"; then
OPENMODELICA_SPEC_PLATFORM=`echo $host_cpu-darwin | sed "s/i@<:@3456@:>@86/i386/" | tr "@<:@:upper:@:>@ " "@<:@:lower:@:>@-"`
else
OPENMODELICA_SPEC_PLATFORM=`echo $host_cpu-$host_os | sed "s/linux-gnu/linux/" | sed "s/linux-gnu/linux/" | sed "s/i@<:@3456@:>@86/i386/" | tr "@<:@:upper:@:>@ " "@<:@:lower:@:>@-"`
fi
AC_MSG_RESULT([$OPENMODELICA_SPEC_PLATFORM])
AC_MSG_CHECKING([for Modelica platform name])
if test "$OPENMODELICA_SPEC_PLATFORM" = "x86_64-linux" -o "$OPENMODELICA_SPEC_PLATFORM" = "i386-linux"; then
  MODELICA_SPEC_PLATFORM=`echo $OPENMODELICA_SPEC_PLATFORM | sed "s/x86_64-linux/linux64/" | sed "s/i.86-linux/linux32/"`
elif echo "$OPENMODELICA_SPEC_PLATFORM" | grep -q darwin; then
  MODELICA_SPEC_PLATFORM=`echo $OPENMODELICA_SPEC_PLATFORM | sed "s/x86_64-darwin/darwin64/" | sed "s/i.86-darwin/darwin32/"`
else
  MODELICA_SPEC_PLATFORM=$OPENMODELICA_SPEC_PLATFORM
fi
AC_MSG_RESULT([$MODELICA_SPEC_PLATFORM])

CFLAGS="$CFLAGS"

date=`date "+%Y-%m-%d %H:%M:%S"`

GENERATED_AUTOCONF_FILES="Makefile \
Compiler/Makefile \
Compiler/Script/Makefile \
Compiler/Template/Makefile \
Compiler/runtime/Makefile \
Compiler/runtime/config.unix.h \
Parser/Makefile \
SimulationRuntime/cpp/Makefile.env \
SimulationRuntime/c/Makefile \
SimulationRuntime/fmi/export/buildproject/Makefile \
SimulationRuntime/java_interface/Makefile \
SimulationRuntime/ParModelica/Makefile \
SimulationRuntime/ParModelica/auto/Makefile \
SimulationRuntime/ParModelica/explicit/openclrt/Makefile \
Compiler/boot/Makefile \
Compiler/Lexers/Makefile \
"

AC_CONFIG_SUBDIRS([SimulationRuntime/cpp])
for dir_target in SimulationRuntime/cpp; do
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

AC_CONFIG_COMMANDS([config.unix.h.fix],[./configure-post.sh $ac_cs_config])

AC_OUTPUT(${GENERATED_AUTOCONF_FILES})

echo -e "$FINAL_MESSAGES"
