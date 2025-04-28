cp common/install-sh common/config.guess common/config.sub ./
AC_CANONICAL_TARGET
AC_SUBST(host_short)
build_short=$build_cpu-$build_os
host_short=$host_cpu-$host_os
echo "build_short: $build_short"
echo "host_short: $host_short"

AC_SUBST(OPENMODELICAHOME)
AC_ARG_WITH(openmodelicahome,  [  --with-openmodelicahome=[OPENMODELICAHOME|PREFIX]    (Find OPENMODELICAHOME - the directory where all OpenModelica dependencies are installed.)],[OMHOME="$withval"],[OMHOME=no])

if echo $host | grep -iq darwin; then
  APP=".app"
  EXE=".app"
  SHREXT=".dylib"
  RPATH="-Wl,-rpath,'@loader_path/../lib/$host_short/omc/'"
  RPATH_QMAKE="-Wl,-rpath,'@loader_path/../../../../lib/$host_short/omc',-rpath,'@loader_path/../../../../lib/',-rpath,'$PREFIX/lib/$host_short/omc',-rpath,'$PREFIX/lib/'"
elif test "$host" = "i586-pc-mingw32msvc"; then
  APP=".exe"
  EXE=".exe"
  # Yes, we build static libs on Windows, so the "shared" extension is .a
  SHREXT=".a"
  RPATH="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib/$host_short/omc' -Wl,-rpath,'\$\$ORIGIN'"
  RPATH_QMAKE="-Wl,-z,origin -Wl,-rpath,\\'\\\$\$ORIGIN/../lib/$host_short/omc\\' -Wl,-rpath,\\'\\\$\$ORIGIN/../lib\\' -Wl,-rpath,\\'\\\$\$ORIGIN\\'"
else
  APP=""
  EXE=""
  SHREXT=".so"
  RPATH="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib/$host_short/omc' -Wl,-rpath,'\$\$ORIGIN'"
  RPATH_QMAKE="-Wl,-z,origin -Wl,-rpath,\\'\\\$\$ORIGIN/../lib/$host_short/omc\\' -Wl,-rpath,\\'\\\$\$ORIGIN/../lib\\' -Wl,-rpath,\\'\\\$\$ORIGIN\\'"
fi

define(FIND_OPENMODELICAHOME, [
  AC_MSG_CHECKING([for OPENMODELICAHOME])
if test ! -z "$USINGPRESETBUILDDIR"; then
  OPENMODELICAHOME="$OMBUILDDIR"
  AC_MSG_RESULT($OPENMODELICAHOME)
else
  if test "$OMHOME" = "no"; then
    if test -z "$OPENMODELICAHOME"; then
      OPENMODELICAHOME="$PREFIX"
    else
      OPENMODELICAHOME="$OPENMODELICAHOME"
    fi
  else
    OPENMODELICAHOME="$OMHOME"
  fi

  AC_MSG_RESULT($OPENMODELICAHOME)

  AC_MSG_CHECKING([for $OPENMODELICAHOME/lib/omc/ModelicaBuiltin.mo])
  if test -f "$OPENMODELICAHOME/lib/omc/ModelicaBuiltin.mo"; then
    AC_MSG_RESULT(ok)
  else
    AC_MSG_ERROR(failed)
  fi

  AC_MSG_CHECKING([for $OPENMODELICAHOME/share/omc/omc_communication.idl])
  if test -f "$OPENMODELICAHOME/share/omc/omc_communication.idl"; then
    AC_MSG_RESULT(ok)
  else
    AC_MSG_ERROR(failed)
  fi
fi
if echo $host | grep -iq darwin; then
  true
elif test "$host" = "i586-pc-mingw32msvc"; then
  true
else
  LDFLAGS="$LDFLAGS -Wl,-rpath-link,$OPENMODELICAHOME/lib/$host_short/omc"
fi
])

define(FIND_LIBOPENMODELICACOMPILER, [
if test -z "$USINGPRESETBUILDDIR"; then
  AC_LANG_PUSH([C])
  AC_MSG_CHECKING([for libOpenModelicaCompiler])
  # Note: This does not do a full link. autoconf messes with some env
  # and the rpath of the resulting executable is wrong with the
  # exact same command running outside of autoconf
  LDFLAGS_SAVE="$LDFLAGS"
  LDFLAGS="$LDFLAGS -L$OPENMODELICAHOME/lib/$host_short/omc -lOpenModelicaCompiler"
  AC_LINK_IFELSE([AC_LANG_PROGRAM([], [])], [AC_MSG_RESULT([ok])], [AC_MSG_ERROR([failed])])
  LDFLAGS="$LDFLAGS_SAVE"
  AC_LANG_POP([C])
fi
])

define(FIND_LIBOMQWT, [
if test -z "$USINGPRESETBUILDDIR"; then
SAVED_LDFLAGS=$LDFLAGS
LDFLAGS="$LDFLAGS -L$OPENMODELICAHOME/lib/$host_short/omc -lomqwt"
AC_LINK_IFELSE([AC_LANG_PROGRAM([],[])], [], [AC_MSG_ERROR([OpenModelica version of qwt not found.])])
LDFLAGS=$SAVED_LDFLAGS
fi
])
