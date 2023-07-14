/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2013, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef OPENMODELICA_CONFIG_H
#define OPENMODELICA_CONFIG_H

#if defined(__MINGW32__) || defined(_MSC_VER)
#define CONFIG_USER_IS_ROOT 0
#else
#define CONFIG_USER_IS_ROOT (geteuid() == 0 ? 1 : 0)
#endif

#if !defined(MSYS2_AUTOCONF) && (defined(__MINGW32__) || defined(_MSC_VER))
/* Windows */
#if defined(__MINGW64__) && defined(UCRT64) // MSYS with UCRT64

#define CONFIG_MODELICA_SPEC_PLATFORM "win64"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "ucrt64"
#define CONFIG_GCC_DUMPMACHINE "x86_64-w64-mingw32"
#define CONFIG_GCC_VERSION __VERSION__

#elif defined(__MINGW64__)  // MSYS with MINGW64

#define CONFIG_MODELICA_SPEC_PLATFORM "win64"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "mingw64"
#define CONFIG_GCC_DUMPMACHINE "x86_64-w64-mingw32"
#define CONFIG_GCC_VERSION __VERSION__

#elif defined(__MINGW32__)

#define CONFIG_MODELICA_SPEC_PLATFORM "win32"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "mingw32"
#define CONFIG_GCC_DUMPMACHINE "i686-w64-mingw32"
#define CONFIG_GCC_VERSION __VERSION__

#elif defined(_MSC_VER) && defined(_M_IX86)

#define CONFIG_MODELICA_SPEC_PLATFORM "win32"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "msvc32"
#define CONFIG_GCC_DUMPMACHINE ""
#define CONFIG_GCC_VERSION ""

#elif defined(_MSC_VER) && defined(_M_X64)

#define CONFIG_MODELICA_SPEC_PLATFORM "win64"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "msvc64"
#define CONFIG_GCC_DUMPMACHINE ""
#define CONFIG_GCC_VERSION ""

#endif

/* if we compiled omc with clang asume we
 * use it to compile simulation code with it
 */
#if defined(__clang__)
  #define DEFAULT_CC "clang"
  #define DEFAULT_CXX "clang++"
  #define DEFAULT_OMPCC "clang -fopenmp"
  #define DEFAULT_LD "clang++"
#else /* assume gcc */
  #define DEFAULT_CC "gcc"
  #define DEFAULT_CXX "g++"
  #define DEFAULT_OMPCC "gcc -fopenmp"
  #define DEFAULT_LD "g++"
#endif


#define CONFIG_TRIPLE ""

/* adrpo: add -loleaut32 as is used by ExternalMedia */
#define DEFAULT_LDFLAGS "-fopenmp -Wl,-Bstatic -lregex -ltre -lintl -liconv -lexpat -lpthread -loleaut32 -limagehlp -lhdf5 -lz -lsz -Wl,-Bdynamic"

#define CONFIG_WITH_OPENMP 1

#define CONFIG_DEFAULT_OPENMODELICAHOME NULL

/* adrpo: add -loleaut32 as is used by ExternalMedia */
#define CONFIG_DLL_EXT ".dll"

#if defined(__i386__) || defined(__x86_64__) || defined(_MSC_VER)
  /*
   * if we are on i386 or x86_64 or compiling with
   * Visual Studio then use the SSE instructions,
   * not the normal i387 FPU
   */
  #define DEFAULT_CFLAGS "-DOM_HAVE_PTHREADS -Wno-parentheses-equality -falign-functions -mstackrealign -msse2 -mfpmath=sse ${MODELICAUSERCFLAGS}"
#else
  #define DEFAULT_CFLAGS "-DOM_HAVE_PTHREADS -Wno-parentheses-equality -falign-functions ${MODELICAUSERCFLAGS}"
#endif

/* for windows/mingw we don't need -fPIC for x86_64 target, also clang doesn't support it, gcc ignores it */
#define DEFAULT_LINKER DEFAULT_LD" -shared -Xlinker --export-all-symbols"

#define CONFIG_IPOPT_INC /* Without IPOPT */
#define CONFIG_IPOPT_LIB /* Without IPOPT */

#define WITH_HWLOC 0
#define WITH_SUNDIALS

#include "revision.h"

#define WITH_SUITESPARSE

/* On Windows (with OMDev) assume we have lapack*/
#define HAVE_LAPACK
/* On Windows (with OMDev) assume we have deprecated lapack functions*/
#if !defined(_MSC_VER)
#define HAVE_LAPACK_DEPRECATED
#endif

#else /* Unix */ /* #if !defined(MSYS2_AUTOCONF) && (defined(__MINGW32__) || defined(_MSC_VER)) */

#define CONFIG_GCC_DUMPMACHINE ""
#define CONFIG_GCC_VERSION ""
#define DEFAULT_LDFLAGS ""

#include "omc_config.unix.h"

#endif /* #if !defined(MSYS2_AUTOCONF) && (defined(__MINGW32__) || defined(_MSC_VER)) */

#ifdef CONFIG_REVISION
#define CONFIG_VERSION CONFIG_REVISION
#else
#define CONFIG_VERSION "unknown"
#endif


#endif
