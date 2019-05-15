AC_SUBST(OMBUILDDIR)
AC_ARG_WITH(ombuilddir,  [  --with-ombuilddir=[build]       (where build files are generated; OPENMODELICAHOME)],[OMBUILDDIR="$withval"; USINGPRESETBUILDDIR="yes"],[OMBUILDDIR="no"])
if test "$OMBUILDDIR" = "no"; then
  OMBUILDDIR=$ac_pwd/build
  ac_configure_args="$ac_configure_args --with-ombuilddir=$OMBUILDDIR"
fi

if test "$prefix" = "NONE"; then
  PREFIX="$OMBUILDDIR"
else
  PREFIX=$prefix
fi
AC_PREFIX_DEFAULT($PREFIX)
prefix=$PREFIX
