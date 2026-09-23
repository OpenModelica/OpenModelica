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


#ifndef OMC_RC_H_
#define OMC_RC_H_

#include <stdlib.h>
#include "../openmodelica_types.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* A counted block is [ rc : mmc_uint_t ][ object ... ]; the pointer handed out
 * is the object. rc == OMC_RC_IMMORTAL is never written and never freed.
 *
 * The counts are not atomic: only --hpcom shares a modelica_string between
 * threads. Define OMC_RC_ATOMIC for that, at a locked op per retain. */


#if defined(OMC_RC_ATOMIC)
#if !defined(__GNUC__) && !defined(__clang__)
#error "OMC_RC_ATOMIC needs the GCC/Clang __atomic builtins"
#endif
#define OMC_RC_LOAD(rc)  __atomic_load_n((rc), __ATOMIC_RELAXED)
#define OMC_RC_INC(rc)   ((void) __atomic_fetch_add((rc), 1, __ATOMIC_RELAXED))
#define OMC_RC_DEC(rc)   (__atomic_sub_fetch((rc), 1, __ATOMIC_ACQ_REL))
#else
#define OMC_RC_LOAD(rc)  (*(rc))
#define OMC_RC_INC(rc)   ((void) (*(rc))++)
#define OMC_RC_DEC(rc)   (--(*(rc)))
#endif

/* rc = 1. malloc_atomic and malloc are the same block; nothing scans it. */
void* omc_rc_alloc(size_t nbytes);
void* omc_rc_alloc_zero(size_t nbytes);
char* omc_rc_strdup(const char *str);

/* Out of line for generated code, which emits them whichever heap it gets. */
void* omc_rc_retain(void *obj);
void omc_rc_release(void *obj);

/* Whether releasing `obj` would free it; always 0 on a collected heap. */
int omc_rc_is_last(void *obj);

static inline mmc_uint_t* omc_rc_hdr(void *obj)
{
  return ((mmc_uint_t*)obj) - 1;
}

/* A collected object has no count in front of it to touch. */
#if defined(OMC_METAMODELICA_RUNTIME)

static inline void* omc_rc_retain_inline(void *obj) { return obj; }
static inline void omc_rc_release_inline(void *obj) { (void) obj; }

#else

static inline void* omc_rc_retain_inline(void *obj)
{
  if (obj) {
    mmc_uint_t *rc = omc_rc_hdr(obj);
    if (OMC_RC_LOAD(rc) != OMC_RC_IMMORTAL) {
      OMC_RC_INC(rc);
    }
  }
  return obj;
}

static inline void omc_rc_release_inline(void *obj)
{
  if (obj) {
    mmc_uint_t *rc = omc_rc_hdr(obj);
    if (OMC_RC_LOAD(rc) != OMC_RC_IMMORTAL && OMC_RC_DEC(rc) == 0) {
      free(rc);
    }
  }
}

#endif /* OMC_METAMODELICA_RUNTIME */

#if defined(__cplusplus)
} /* end extern "C" */
#endif

#endif /* OMC_RC_H_ */
