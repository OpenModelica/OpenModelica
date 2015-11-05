 Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OpenModelica Exported FMU],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_SUBST(DLLEXT)
AC_SUBST(FMIPLATFORM)
AC_SUBST(NEED_DGESV)
AC_SUBST(NEED_RUNTIME)

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

build_short=$build_cpu-$build_os
host_short=$host_cpu-$host_os

echo "build_short: $build_short"
echo "host_short: $host_short"

dnl Checks for programs.
AC_LANG([C])
AC_PROG_CC
AC_PROG_CPP
AC_PROG_MAKE_SET

AC_MSG_CHECKING([for cross-compilation flags])
if test "$host_short" = "$build_short"; then
  # Not cross-compiling or found a good tool; don't need special flags
  AC_MSG_RESULT([not cross-compiling])
elif echo "$CC" | grep -q "$host_short" || echo "$CC" | grep -q "$host"; then
  AC_MSG_RESULT([not needed; $CC contains the prefix])
elif test "$host_short" = "x86_64"; then
  CFLAGS_BEFORE="$CFLAGS"
  CFLAGS="$CFLAGS -m64"
  AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([-m64])], [AC_MSG_ERROR([-m64 not working])])
elif echo "$host_short" | grep -q "i.86"; then
  CFLAGS_BEFORE="$CFLAGS"
  CFLAGS="$CFLAGS -m32"
  LDFLAGS="$LDFLAGS -m32"
  AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([-m32])], [AC_MSG_ERROR([-m32 not working])])
else
  AC_MSG_ERROR([unknown platform])
fi

if flase; then
CC_BEFORE="$CC"
CC="clang -target $host_short"
AC_MSG_CHECKING([looking for $CC to replace $CC_BEFORE])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([yes])], [CC="$CC_BEFORE";AC_MSG_RESULT([no])])
fi

LDFLAGS_BEFORE="$LDFLAGS"
LDFLAGS="$LDFLAGS -Wl,--no-undefined"
AC_MSG_CHECKING([looking for --no-undefined])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([yes]);LD_NOUNDEFINED=" -Wl,--no-undefined"], [AC_MSG_RESULT([no])])
LDFLAGS="$LDFLAGS_BEFORE"

CFLAGS_BEFORE="$CFLAGS"
CFLAGS="$CFLAGS -Werror"
AC_MSG_CHECKING([if -Werror works])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([ok])], [AC_MSG_ERROR([failed (check your CFLAGS)])])
CFLAGS="$CFLAGS_BEFORE"

dnl Disables the default CFLAGS="-g -O2"

LDFLAGS="$LDFLAGS -shared"

TRY_FLAGS="-fno-stack-protector -Wno-parentheses-equality -Wno-unused-variable -fPIC"

for flag in $TRY_FLAGS; do
  OLD_CFLAGS="$CFLAGS"
  CFLAGS="$RUNTIMECFLAGS $flag -Werror"
  AC_TRY_LINK([], [return 0;], [CFLAGS="$OLD_CFLAGS $flag"],[CFLAGS="$OLD_CFLAGS"])
done
OLD_CFLAGS="$CFLAGS"

if test "`getconf LONG_BIT`" = "32"; then
dnl Simulations spin forever unless -msse2 -mfpmath=sse is set

CFLAGS_BEFORE=$CFLAGS
CFLAGS="-mfpmath=sse -Werror"
AC_MSG_CHECKING([for floating point bugs])
AC_TRY_LINK([int abc() {}], [abc();], [AC_MSG_RESULT([force SSE2]); FPMATHFORTRAN="-msse -mfpmath=sse"], [AC_MSG_RESULT([no]); FPMATHFORTRAN=-ffloat-store])
CFLAGS=$CFLAGS_BEFORE

fi # End x86-specific CFLAGS

dnl Checks for libraries.

dnl Checks for header files.
AC_HEADER_STDC

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T

dnl Checks for library functions.
AC_FUNC_VPRINTF
AC_CHECK_FUNCS(strdup strerror)

# Cannot use AX_LAPACK since it assumes a Fortran compiler is used
AC_ARG_WITH(lapack,  [  --with-lapack=[-llapack -lblas]    (use -llapack -lblas to use system-provided version.)],[LD_LAPACK="$withval"],[
  LD_LAPACK="-Wl,-Bstatic -llapack -lblas -Wl,-Bdynamic"
])

AC_MSG_CHECKING([LAPACK/BLAS flags])

OLDLIBS="$LIBS"
LIBS="$LIBS $LD_LAPACK"
AC_LINK_IFELSE([AC_LANG_CALL([], [dgesv_])],[
  AC_LINK_IFELSE([AC_LANG_CALL([], [dswap_])],[AC_MSG_RESULT([$LD_LAPACK])],[LIBS="$OLDLIBS"; NEED_DGESV=1; AC_MSG_RESULT([dswap (BLAS) linking failed using $LD_LAPACK])])
],[LIBS="$OLDLIBS"; NEED_DGESV=1; AC_MSG_RESULT([dgesv (LAPACK) linking failed using $LD_LAPACK])])

AC_MSG_CHECKING([for static pthreads])
OLDLIBS=$LIBS
LIBS="$OLDLIBS -Wl,-Bstatic -lpthread -Wl,-Bdynamic"
AC_LINK_IFELSE([AC_LANG_CALL([], [pthread_mutex_lock])],[AC_MSG_RESULT([OK (static)])],[
  AC_MSG_RESULT([no])
  LIBS="$OLDLIBS"
  AC_CHECK_LIB(pthread,[pthread_mutex_lock],[],[AC_MSG_ERROR([pthreads not found])])
])

AC_CHECK_LIB([m],[cos],[],[AC_MSG_ERROR([math library not found])])

AC_ARG_WITH(dynamic-om-runtime,  [  --with-dynamic-om-runtime    (uses the OMC runtime as a shared object instead of compiling it statically into the the FMU.)],[OPENMODELICADYNAMIC=yes],[OPENMODELICADYNAMIC=no])

if test "$OPENMODELICADYNAMIC" = "no"; then
  CPPFLAGS="$CPPFLAGS -DOMC_MINIMAL_RUNTIME=1 -DCMINPACK_NO_DLL=1"
  NEED_RUNTIME=1
fi

if test "$host_os" = darwin; then
  DLLEXT=".dylib"
  if echo "$host_cpu" | grep -q i@<:@3456@:>@86; then
    FMIPLATFORM=darwin32
  elif echo "$host_cpu" | grep -q x86_64; then
    FMIPLATFORM=darwin64
  fi
elif echo "$host_os" | grep -q mingw; then
  DLLEXT=".dll"
  if echo "$host_cpu" | grep -q i@<:@3456@:>@86; then
    FMIPLATFORM=win32
  elif echo "$host_cpu" | grep -q x86_64; then
    FMIPLATFORM=win64
  fi
elif echo "$host_os" | grep -q linux; then
  DLLEXT=".so"
  if echo "$host_cpu" | grep -q i@<:@3456@:>@86; then
    FMIPLATFORM=linux32
  elif echo "$host_cpu" | grep -q x86_64; then
    FMIPLATFORM=linux64
  fi
else
  DLLEXT=".so"
fi

# Non-standard platforms also need some love
if test -z "$FMIPLATFORM"; then
  FMIPLATFORM=$host_short
fi

AC_OUTPUT(Makefile)
