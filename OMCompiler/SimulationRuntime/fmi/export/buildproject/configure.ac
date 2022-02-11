 Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([OpenModelica Exported FMU],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_SUBST(AR)
AC_SUBST(DLLEXT)
AC_SUBST(FMIPLATFORM)
AC_SUBST(NEED_DGESV)
AC_SUBST(NEED_CMINPACK)
AC_SUBST(NEED_SUNDIALS)
AC_SUBST(NEED_RUNTIME)
AC_SUBST(LIBTYPE_STATIC)
AC_SUBST(LIBTYPE_DYNAMIC)
AC_SUBST(BSTATIC)
AC_SUBST(BDYNAMIC)

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

build_short=$build_cpu-$build_os
if test "$host_os" = "none"; then
  host_short=$host_cpu
else
  host_short=$host_cpu-$host_os
fi

echo "build_short: $build_short"
echo "host_short: $host_short"

ORIGCC="$CC"

dnl Checks for programs.
AC_LANG([C])
AC_PROG_CC
AC_PROG_CPP
AC_PROG_MAKE_SET

AC_MSG_CHECKING([for cross-compilation flags])
if test "$host_short" = "$build_short"; then
  # Not cross-compiling or found a good tool; don't need special flags
  AC_MSG_RESULT([not cross-compiling])
elif echo "$CC" | grep -q "$host_short" || echo "$CC" | grep -q "$host" || echo "$CC" | grep -q "$host_cpu"; then
  AC_MSG_RESULT([not needed; $CC contains the prefix])
elif test "$host_os" = "$build_os" && test "$host_short" = "x86_64"; then
  CFLAGS_BEFORE="$CFLAGS"
  CFLAGS="$CFLAGS -m64"
  AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([-m64])], [AC_MSG_ERROR([-m64 not working])])
elif test "$host_os" = "$build_os" && echo "$host_short" | grep -q "i.86"; then
  CFLAGS_BEFORE="$CFLAGS"
  CFLAGS="$CFLAGS -m32"
  LDFLAGS="$LDFLAGS -m32"
  AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([-m32])], [AC_MSG_ERROR([-m32 not working])])
elif test ! -z "$ORIGCC"; then
  AC_MSG_RESULT([user sent an explicit CC=$ORIGCC. Trusting the user.])
else
  CC="$host-cc"
  if which $host-cc > /dev/null 2>&1; then
    CC="$host-cc"
  else
    CC=clang
    CFLAGS="$CFLAGS -target $host"
  fi
  AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([$CC $CFLAGS])], [AC_MSG_ERROR([unknown platform and $CC $CFLAGS not working])])
fi

if false; then
CC_BEFORE="$CC"
CC="clang -target $host_short"
AC_MSG_CHECKING([looking for $CC to replace $CC_BEFORE])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([yes])], [CC="$CC_BEFORE";AC_MSG_RESULT([no])])
fi

CFLAGS_BEFORE="$CFLAGS"
CFLAGS="$CFLAGS -Werror"
AC_MSG_CHECKING([if -Werror works])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([ok])], [AC_MSG_ERROR([failed (check your CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS CPPFLAGS=$CPPFLAGS)])])
CFLAGS="$CFLAGS_BEFORE"

LDFLAGS_BEFORE="$LDFLAGS"
LDFLAGS="$LDFLAGS -Wl,--no-undefined -Werror"
AC_MSG_CHECKING([looking for --no-undefined])
AC_TRY_LINK([void abc() {}], [abc();], [AC_MSG_RESULT([yes]);LD_NOUNDEFINED=" -Wl,--no-undefined"], [AC_MSG_RESULT([no])])
LDFLAGS="$LDFLAGS_BEFORE"

dnl Enable to handle AVR pre-processor not handling $ as symbol names; but fails on assembler anyway

AC_MSG_CHECKING([looking for dollars in identifiers])
AC_TRY_LINK([
void $a$b$c() {}
#define $a$b$c$d $a$b$c
], [$a$b$c$d();], [AC_MSG_RESULT([not needed])], [
  CPPFLAGS="$CPPFLAGS -fdollars-in-identifiers"
  AC_TRY_LINK([
    void fx() {}
    #define \$a\$b fx
    ], [\$a\$b();], [AC_MSG_RESULT([CPPFLAGS: -fdollars-in-identifiers])], [
    AC_MSG_ERROR([the compiler does not handle dollar in identifiers])
  ])
])

dnl Disables the default CFLAGS="-g -O2"

AC_ARG_ENABLE(static, [  --enable-static], [
  if test "$enableval" = "yes"; then
    LIBTYPE_STATIC=1
  elif test "$enableval" = "no"; then
    LIBTYPE_STATIC=0
  else
    AC_MSG_ERROR([Unknown value --enable-static=$withval (use yes or no, or no value)])
  fi
], [LIBTYPE_STATIC=0])

AC_ARG_ENABLE(shared, [  --disable-shared], [
  if test "$enableval" = "yes"; then
    LIBTYPE_DYNAMIC=1
  elif test "$enableval" = "no"; then
    LIBTYPE_DYNAMIC=0
  else
    AC_MSG_ERROR([Unknown value --enable-dynamic=$withval (use yes or no, or no value)])
  fi
], [LIBTYPE_DYNAMIC=1])

if test "$LIBTYPE_DYNAMIC" = 0 -a "$LIBTYPE_STATIC" = 0; then
  AC_MSG_ERROR([Need to --enable-shared or --enable-static (both were disabled)])
fi

if test "$LIBTYPE_DYNAMIC" = 1; then
  LDFLAGS="$LDFLAGS -shared"
fi

if test "$LIBTYPE_STATIC" = 1; then
  AC_CHECK_TOOL([AR], [ar], [:])
  if test "$AR" = ":"; then
    AC_MSG_ERROR([Did not find a suitable ar])
  fi
fi


TRY_FLAGS="-fno-stack-protector -Wno-parentheses-equality -Wno-unused-variable -fPIC"

for flag in $TRY_FLAGS; do
  OLD_CFLAGS="$CFLAGS"
  CFLAGS="$RUNTIMECFLAGS $flag -Werror"
  AC_TRY_LINK([], [return 0;], [CFLAGS="$OLD_CFLAGS $flag"],[CFLAGS="$OLD_CFLAGS"])
done

TRY_FLAGS="-static-libgcc"
for flag in $TRY_FLAGS; do
  OLD_LDFLAGS="$LDFLAGS"
  LDFLAGS="$LDFLAGS $flag"
  AC_TRY_LINK([], [return 0;], [LDFLAGS="$OLD_LDFLAGS $flag"],[LDFLAGS="$OLD_LDFLAGS"])
done

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

m4_include([../../../../m4/lapack.m4])
OMC_AC_LAPACK(static)
if test -z "$LD_LAPACK"; then
  NEED_DGESV=1
else
  LIBS="$LIBS $LD_LAPACK"
fi

AC_ARG_ENABLE(static-user-libs, [  --disable-static-user-libs], [
  if test "$enableval" = "yes"; then
    STATIC_USER_LIBS=1
  elif test "$enableval" = "no"; then
    STATIC_USER_LIBS=0
  else
    AC_MSG_ERROR([Unknown value --enable-static-user-libs=$withval (use yes or no, or no value)])
  fi
], [STATIC_USER_LIBS=1])

if test "$STATIC_USER_LIBS" = "1"; then

  OLD_LDFLAGS="$LDFLAGS"
  LDFLAGS="$LDFLAGS -Wl,-Bstatic  -Wl,-Bdynamic"
  AC_TRY_LINK([], [return 0;], [BSTATIC="-Wl,-Bstatic" ; BDYNAMIC="-Wl,-Bdynamic"],[AC_MSG_RESULT(["Don't know the flags to force static linking"])])
  LDFLAGS="$OLD_LDFLAGS"

fi

AC_MSG_CHECKING([for static pthreads])
OLDLIBS=$LIBS
NEWLIBS="$OLDLIBS -Wl,-Bstatic -lpthread -Wl,-Bdynamic"
LIBS="$NEWLIBS -shared"
PTHREAD_STATIC=0
if echo $host_cpu | grep -q arm; then
  AC_MSG_RESULT([not looking (we have problems detecting if libpthread.a can be statically linked on ARM platforms)])
else
  AC_LINK_IFELSE([AC_LANG_CALL([], [pthread_mutex_lock])],[LIBS="$NEWLIBS";PTHREAD_STATIC=1;AC_MSG_RESULT([OK (static)])],[AC_MSG_RESULT([no])])
fi

if ! test "$PTHREAD_STATIC" = 1; then
  LIBS="$OLDLIBS -shared"
  AC_CHECK_LIB(pthread,[pthread_mutex_lock],[],[
    if test "$LIBTYPE_DYNAMIC" = 1; then
      AC_MSG_ERROR([pthreads not found and requested dynamic linking])
    else
      AC_MSG_RESULT([pthreads disabled])
      CPPFLAGS="$CPPFLAGS -DOMC_NO_THREADS"
    fi
  ])
fi

AC_CHECK_LIB([m],[cos],[],[AC_MSG_ERROR([math library not found])])

AC_MSG_CHECKING([for filesystem access])
AC_TRY_LINK([#include <stdio.h>], [fopen("a.txt", "r");], [AC_MSG_RESULT([OK])], [AC_MSG_RESULT([no]); CPPFLAGS="$CPPFLAGS -DOMC_NO_FILESYSTEM"])

if test -f isfmi1; then
AC_CHECK_HEADERS([fmiModelFunctions.h fmiModelTypes.h], [], [AC_MSG_ERROR([FMI headers need to be present in the include path. Try setting CPPFLAGS.])])
elif test -f isfmi2; then
AC_CHECK_HEADERS([fmi2Functions.h  fmi2FunctionTypes.h  fmi2TypesPlatform.h], [], [AC_MSG_ERROR([FMI headers need to be present in the include path. Try setting CPPFLAGS.])])
else
AC_MSG_ERROR([Neither file isfmi1 or isfmi2 exists in the source directory])
fi

AC_ARG_WITH(dynamic-om-runtime,  [  --with-dynamic-om-runtime    (uses the OMC runtime as a shared object instead of compiling it statically into the the FMU.)],[OPENMODELICADYNAMIC=yes],[OPENMODELICADYNAMIC=no])

if test "$OPENMODELICADYNAMIC" = "no"; then
  CPPFLAGS="$CPPFLAGS -DCMINPACK_NO_DLL=1"
  NEED_RUNTIME=1
fi

if test -f "external_solvers/hybrj_.c"; then
  NEED_CMINPACK=1
fi

if echo "$host_os" | grep -q darwin; then
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
