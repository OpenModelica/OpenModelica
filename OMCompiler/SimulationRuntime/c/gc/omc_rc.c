/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */


#include "../omc_simulation_settings.h"
#include "omc_gc.h"
#include "omc_rc.h"
#include <string.h>

#if defined(__cplusplus)
extern "C" {
#endif

static void* rc_alloc(size_t nbytes, int zero)
{
  mmc_uint_t *block;

  /* The runtime asks for zero-size blocks; see #7611. They still need a header
     so that retain/release on the result are well defined. */
  block = (mmc_uint_t*) (zero ? calloc(1, sizeof(mmc_uint_t) + nbytes)
                              : malloc(sizeof(mmc_uint_t) + nbytes));
  if (!block) {
    mmc_do_out_of_memory();
  }
  *block = 1;
  return block + 1;
}

void* omc_rc_alloc(size_t nbytes)
{
  return rc_alloc(nbytes, 0);
}

void* omc_rc_alloc_zero(size_t nbytes)
{
  return rc_alloc(nbytes, 1);
}

char* omc_rc_strdup(const char *str)
{
  size_t len = strlen(str) + 1;
  return (char*) memcpy(rc_alloc(len, 0), str, len);
}

void* omc_rc_retain(void *obj)
{
  return omc_rc_retain_inline(obj);
}

void omc_rc_release(void *obj)
{
  omc_rc_release_inline(obj);
}

int omc_rc_is_last(void *obj)
{
#if defined(OMC_METAMODELICA_RUNTIME)
  /* Collected, not counted: the collector owns that decision. */
  (void) obj;
  return 0;
#else
  if (obj) {
    mmc_uint_t rc = *omc_rc_hdr(obj);
    return rc != OMC_RC_IMMORTAL && rc == 1;
  }
  return 0;
#endif
}

static void rc_init(void)
{
}

static int rc_collect_a_little(void)
{
  return 0;
}

static void* rc_malloc_uncollectable(size_t sz)
{
  void *addr = sz ? calloc(1, sz) : NULL;

  if (sz && !addr) {
    mmc_do_out_of_memory();
  }
  return addr;
}

#define OMC_RC_ALLOC_INTERFACE  \
  rc_init,                      \
  omc_rc_alloc_zero,            \
  omc_rc_alloc_zero,            \
  (char*(*)(size_t)) omc_rc_alloc_zero, \
  omc_rc_strdup,                \
  rc_collect_a_little,          \
  rc_malloc_uncollectable,      \
  free,                          \
  malloc,                        \
  free

omc_alloc_interface_t omc_alloc_interface_rc = { OMC_RC_ALLOC_INTERFACE };

#if !defined(OMC_METAMODELICA_RUNTIME)
omc_alloc_interface_t omc_alloc_interface = { OMC_RC_ALLOC_INTERFACE };
#endif

#if defined(__cplusplus)
} /* end extern "C" */
#endif
