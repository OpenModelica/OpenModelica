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
#if defined(__MINGW64__)

#define CONFIG_MODELICA_SPEC_PLATFORM "win64"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "mingw64"
#define CONFIG_GCC_DUMPMACHINE "x86_64-w64-mingw32"
#define CONFIG_GCC_VERSION "5.3.0" /* adrpo, change here when we upgrade! */

#elif defined(__MINGW32__)

#define CONFIG_MODELICA_SPEC_PLATFORM "win32"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "mingw32"
#define CONFIG_GCC_DUMPMACHINE "i686-w64-mingw32"
#define CONFIG_GCC_VERSION "5.3.0" /* adrpo, change here when we upgrade! */

#elif defined(_MSV_VER) && defined(_M_IX86)

#define CONFIG_MODELICA_SPEC_PLATFORM "win32"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "msvc32"
#define CONFIG_GCC_DUMPMACHINE ""
#define CONFIG_GCC_VERSION ""

#elif defined(_MSV_VER) && defined(_M_X64)

#define CONFIG_MODELICA_SPEC_PLATFORM "win64"
#define CONFIG_OPENMODELICA_SPEC_PLATFORM "msvc64"
#define CONFIG_GCC_DUMPMACHINE ""
#define CONFIG_GCC_VERSION ""

#endif

#define DEFAULT_CC "gcc"
#define DEFAULT_CXX "g++"
#define DEFAULT_OMPCC "gcc -fopenmp"

/* adrpo: add -loleaut32 as is used by ExternalMedia */
#define DEFAULT_LDFLAGS "-fopenmp -Wl,-Bstatic -lregex -ltre -lintl -liconv -lexpat -lomcgc -lpthread -loleaut32 -limagehlp -lhdf5 -lz -lszip -Wl,-Bdynamic"


#define CONFIG_WITH_OPENMP 1

#define CONFIG_DEFAULT_OPENMODELICAHOME NULL

/* adrpo: add -loleaut32 as is used by ExternalMedia */
#define CONFIG_DLL_EXT ".dll"
#define CONFIG_LPSOLVEINC "lpsolve/lp_lib.h"

#if defined(__i386__) || defined(__x86_64__) || defined(_MSC_VER)
  /*
   * if we are on i386 or x86_64 or compiling with
   * Visual Studio then use the SSE instructions,
   * not the normal i387 FPU
   */
  #define DEFAULT_CFLAGS "-falign-functions -fno-ipa-pure-const -mstackrealign -msse2 -mfpmath=sse ${MODELICAUSERCFLAGS}"
#else
  #define DEFAULT_CFLAGS "-falign-functions -fno-ipa-pure-const ${MODELICAUSERCFLAGS}"
#endif
#if defined(__x86_64__)
  /* -fPIC needed on x86_64! */
  #define DEFAULT_LINKER "g++ -shared -Xlinker --export-all-symbols -fPIC"
#else
  #define DEFAULT_LINKER "g++ -shared -Xlinker --export-all-symbols"
#endif

#define CONFIG_IPOPT_INC /* Without IPOPT */
#define CONFIG_IPOPT_LIB /* Without IPOPT */

#define WITH_HWLOC 0
#define WITH_SUNDIALS

#if defined(__MINGW32__)
#define WITH_IPOPT
#else
/* Without IPOPT for MSVC */
#endif

#include "revision.h"

#define WITH_UMFPACK

#else /* Unix */ /* #if !defined(MSYS2_AUTOCONF) && (defined(__MINGW32__) || defined(_MSC_VER)) */

#define CONFIG_GCC_DUMPMACHINE ""
#define CONFIG_GCC_VERSION ""
#define DEFAULT_LDFLAGS ""

#include "config.unix.h"

#endif /* #if !defined(MSYS2_AUTOCONF) && (defined(__MINGW32__) || defined(_MSC_VER)) */

#ifdef CONFIG_REVISION
#define CONFIG_VERSION CONFIG_REVISION
#else
#define CONFIG_VERSION "unknown"
#endif


#endif
