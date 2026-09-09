/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * The Windows side of omc_lapack.h: loading the library and resolving the
 * routines. Everywhere else the routines are linked in and this file is empty.
 */

#include "omc_lapack.h"

#if defined(HAVE_LAPACK) && defined(_WIN32)

#include <stdio.h>
#include <string.h>
#include <windows.h>

#include "meta/meta_modelica.h"
#include "errorext.h"

#ifndef OMC_LAPACK_DLL_NAMES
#define OMC_LAPACK_DLL_NAMES ""
#endif

/* Tried after whatever the build system derived from LAPACK_LIBRARIES. */
#define OMC_LAPACK_DLL_FALLBACKS "libopenblas.dll;openblas.dll;liblapack.dll;lapack.dll"

#define OMC_LAPACK_DEFINE_POINTER(name, ret, params) \
  omc_lapack_fp_##name omc_lapack_ptr_##name = NULL;
OMC_LAPACK_FUNCTIONS(OMC_LAPACK_DEFINE_POINTER)

#define OMC_LAPACK_RESOLVE(name, ret, params) \
  omc_lapack_ptr_##name = (omc_lapack_fp_##name) GetProcAddress(lib, #name);

static HMODULE omc_lapack_load_library(void)
{
  /* Pin OpenBLAS to a single thread across the load, then put the variable
     back the way it was so that child processes are unaffected. */
  char names[1024];
  char saved[64];
  DWORD saved_len;
  int had_saved;
  HMODULE lib = NULL;
  char *name;
  char *rest;

  snprintf(names, sizeof(names), "%s%s%s", OMC_LAPACK_DLL_NAMES,
           OMC_LAPACK_DLL_NAMES[0] ? ";" : "", OMC_LAPACK_DLL_FALLBACKS);

  saved_len = GetEnvironmentVariableA("OMP_NUM_THREADS", saved, sizeof(saved));
  had_saved = saved_len > 0 && saved_len < sizeof(saved);
  SetEnvironmentVariableA("OMP_NUM_THREADS", "1");

  rest = names;
  while ((name = strtok(rest, ";")) != NULL) {
    rest = NULL;
    lib = LoadLibraryA(name);
    if (lib) {
      break;
    }
  }

  SetEnvironmentVariableA("OMP_NUM_THREADS", had_saved ? saved : NULL);
  return lib;
}

void* omc_lapack_symbol(void **slot, const char *name)
{
  static int loaded = 0;

  if (!loaded) {
    HMODULE lib = omc_lapack_load_library();
    loaded = 1;
    if (lib) {
      OMC_LAPACK_FUNCTIONS(OMC_LAPACK_RESOLVE)
    }
  }

  if (!*slot) {
    const char *ctokens[1];
    ctokens[0] = name;
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error,
                  "The LAPACK routine %s could not be loaded. Make sure a LAPACK "
                  "library (libopenblas.dll for instance) can be found on the PATH.\n",
                  ctokens, 1);
    MMC_THROW();
  }

  return *slot;
}

#endif /* HAVE_LAPACK && _WIN32 */
