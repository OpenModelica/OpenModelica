# Based on https://github.com/postgres/postgres/blob/master/config/llvm.m4
# PostgreSQL Database Management System
# (formerly known as Postgres, then as Postgres95)
#
# Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
#
# Portions Copyright (c) 1994, The Regents of the University of California
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without a written agreement
# is hereby granted, provided that the above copyright notice and this
# paragraph and the following two paragraphs appear in all copies.
#
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
# LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
# DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

# OMC_AC_LLVM_SUPPORT
# -----------------
#
# Look for the LLVM installation, check that it's new enough, set the
# corresponding LLVM_{CFLAGS,CXXFLAGS,BINPATH} and LDFLAGS
# variables. Also verify that CLANG is available, to transform C
# into bitcode.
#
AC_DEFUN([OMC_AC_LLVM_SUPPORT],
[
  AC_REQUIRE([AC_PROG_AWK])

  AC_ARG_VAR(LLVM_CONFIG, [path to llvm-config command])
  #We currently only supports LLVM-5. Breaking changes in the later v:s
  #We first check for generic llvm-config. If that does not work we fall back to five.
  AC_CHECK_PROGS(LLVM_CONFIG, llvm-config llvm-config-5.0)
  # no point continuing if llvm wasn't found
  if test -z "$LLVM_CONFIG"; then
    AC_MSG_RESULT([llvm-config not found; specify with LLVM_CONFIG=])
  else
    # check if detected $LLVM_CONFIG is executable
    omc_ac_llvm_version="$($LLVM_CONFIG --version 2> /dev/null || echo no)"
    if test "x$omc_ac_llvm_version" = "xno"; then
      AC_MSG_RESULT([$LLVM_CONFIG does not work])
      LLVM_CONFIG=""
    # and whether the version is supported
    elif echo $omc_ac_llvm_version | $AWK -F '.' '{ if ([$]1 >= 5 || ([$]1 == 5 && [$]2 >= 9)) exit 1; else exit 0;}';then
      AC_MSG_RESULT([$LLVM_CONFIG version is $omc_ac_llvm_version but at least 5.0 is required])
      LLVM_CONFIG=""
    fi
  fi
  if test -z "$LLVM_CONFIG"; then
    false
  else

  # need clang to create some bitcode files
  if false; then
    # AC_ARG_VAR(CLANG, [path to clang compiler to generate bitcode])
    # OMC_AC_PATH_PROGS(CLANG, clang clang-7 clang-6.0 clang-5.0 clang-4.0 clang-3.9)
    if test -z "$CLANG"; then
      AC_MSG_ERROR([clang not found, but required when compiling --with-llvm, specify with CLANG=])
    fi
    # make sure clang is executable
    if test "x$($CLANG --version 2> /dev/null || echo no)" = "xno"; then
      AC_MSG_ERROR([$CLANG does not work])
    fi
  fi
  # Could check clang version, but it doesn't seem that
  # important. Systems with a new enough LLVM version are usually
  # going to have a decent clang version too. It's also not entirely
  # clear what the minimum version is.

  # Collect compiler flags necessary to build the LLVM dependent
  # shared library.
  for omc_ac_option in `$LLVM_CONFIG --cppflags`; do
    case $omc_ac_option in
      -I*|-D*) LLVM_CPPFLAGS="$omc_ac_option $LLVM_CPPFLAGS";;
    esac
  done

  for omc_ac_option in `$LLVM_CONFIG --ldflags`; do
    case $omc_ac_option in
      -L*) LDFLAGS="$LDFLAGS $omc_ac_option";;
    esac
  done

  # ABI influencing options, standard influencing options
  for omc_ac_option in `$LLVM_CONFIG --cxxflags`; do
    case $omc_ac_option in
      -fno-rtti*) LLVM_CXXFLAGS="$LLVM_CXXFLAGS $omc_ac_option";;
      -std=*) LLVM_CXXFLAGS="$LLVM_CXXFLAGS $omc_ac_option";;
    esac
  done

  # Look for components we're interested in, collect necessary
  # libs. As some components are optional, we can't just list all of
  # them as it'd raise an error.
  omc_ac_components='';
  for omc_ac_component in `$LLVM_CONFIG --components`; do
    case $omc_ac_component in
      engine) omc_ac_components="$omc_ac_components $omc_ac_component";;
      debuginfodwarf) omc_ac_components="$omc_ac_components $omc_ac_component";;
      orcjit) omc_ac_components="$omc_ac_components $omc_ac_component";;
      passes) omc_ac_components="$omc_ac_components $omc_ac_component";;
      perfjitevents) omc_ac_components="$omc_ac_components $omc_ac_component";;
    esac
  done;

  # And then get the libraries that need to be linked in for the
  # selected components.  They're large libraries, we only want to
  # link them into the LLVM using shared library.
  for omc_ac_option in `$LLVM_CONFIG --libs --system-libs $omc_ac_components`; do
    case $omc_ac_option in
      -l*) LLVM_LIBS="$LLVM_LIBS $omc_ac_option";;
    esac
  done

  LLVM_BINPATH=`$LLVM_CONFIG --bindir`
  fi

  # LLVM_CONFIG, CLANG are already output via AC_ARG_VAR
  if test -z "$LLVM_BINPATH"; then
    HAVE_LLVM="No"
  else
    HAVE_LLVM="Yes"
  fi

  AC_SUBST(HAVE_LLVM)
  AC_SUBST(LLVM_LIBS)
  AC_SUBST(LLVM_CPPFLAGS)
  AC_SUBST(LLVM_CFLAGS)
  AC_SUBST(LLVM_CXXFLAGS)
  AC_SUBST(LLVM_BINPATH)

])# PGAC_LLVM_SUPPORT


# PGAC_CHECK_LLVM_FUNCTIONS
# -------------------------
#
# Check presence of some optional LLVM functions.
# (This shouldn't happen until we're ready to run AC_CHECK_DECLS tests;
# because PGAC_LLVM_SUPPORT runs very early, it's not an appropriate place.)
#
AC_DEFUN([OMC_AC_CHECK_LLVM_FUNCTIONS],
[
  # Check which functionality is present
  if test "$HAVE_LLVM" = "yes"; then
  SAVE_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="$CPPFLAGS $LLVM_CPPFLAGS"
  AC_CHECK_DECLS([LLVMOrcGetSymbolAddressIn], [], [HAVE_LLVM="No"], [[#include <llvm-c/OrcBindings.h>]])
  AC_CHECK_DECLS([LLVMGetHostCPUName, LLVMGetHostCPUFeatures], [], [HAVE_LLVM="No"], [[#include <llvm-c/TargetMachine.h>]])
  AC_CHECK_DECLS([LLVMCreateGDBRegistrationListener, LLVMCreatePerfJITEventListener], [], [HAVE_LLVM="No"], [[#include <llvm-c/ExecutionEngine.h>]])
  CPPFLAGS="$SAVE_CPPFLAGS"
  fi
])# PGAC_CHECK_LLVM_FUNCTIONS
