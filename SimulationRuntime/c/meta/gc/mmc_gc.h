/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*
 * Adrian Pop [Adrian.Pop@liu.se]
 * This file defines the MetaModelica garbage collector (GC) interface
 * We use Boehm GC mark-and-sweep collector.
 *
 *
 */

#ifndef META_MODELICA_GC_H_
#define META_MODELICA_GC_H_

#if defined(_MSC_VER)
#include "omc_inline.h"
#endif

#define _MMC_USE_BOEHM_GC_

#if defined(__cplusplus)
extern "C" {
#endif

#include "openmodelica_types.h"

/* global roots size */
#define MMC_GC_GLOBAL_ROOTS_SIZE 1024

struct mmc_GC_state_type /* the structure of GC state */
{
  modelica_metatype       global_roots[MMC_GC_GLOBAL_ROOTS_SIZE]; /* the global roots ! */
};
typedef struct mmc_GC_state_type mmc_GC_state_type;
extern mmc_GC_state_type* mmc_GC_state;

/* tag the free reqion as a free object with 250 ctor*/
#define MMC_FREE_OBJECT_CTOR           200
#define MMC_TAG_AS_FREE_OBJECT(p, sz)  (((struct mmc_header*)p)->header = MMC_STRUCTHDR(sz, MMC_FREE_OBJECT_CTOR))

#if defined(_MMC_USE_BOEHM_GC_) /* use the BOEHM Garbage collector */

#include <gc.h>
#include <pthread.h>
/* gc.h doesn't include this by default; and the actual header redirects dlopen, which does not have an implementation */
int GC_pthread_create(pthread_t *,const pthread_attr_t *,void *(*)(void *), void *);
int GC_pthread_join(pthread_t, void **);

static inline void mmc_GC_init(void)
{
  GC_init();
  GC_register_displacement(0);
#ifdef RML_STYLE_TAGPTR
  GC_register_displacement(3);
#endif
  GC_set_force_unmap_on_gcollect(1);
}

static inline void mmc_GC_init_default(void)
{
  mmc_GC_init();
}

#define mmc_GC_clear(void)
#define mmc_GC_collect(local_GC_state)

static inline void* mmc_alloc_words_atomic(unsigned int nwords) {
  return GC_MALLOC_ATOMIC((nwords) * sizeof(void*));
}

static inline void* mmc_alloc_words(unsigned int nwords) {
  return GC_MALLOC((nwords) * sizeof(void*));
}

/* for arrays only */
static inline void* mmc_alloc_words_atomic_ignore_off_page(unsigned int nwords) {
  return GC_MALLOC_ATOMIC_IGNORE_OFF_PAGE((nwords) * sizeof(void*));
}

/* for arrays only */
static inline void* mmc_alloc_words_ignore_off_page(unsigned int nwords) {
  return GC_MALLOC_IGNORE_OFF_PAGE((nwords) * sizeof(void*));
}

#else /* NO_GC */

/* primary allocation routines for MetaModelica */
void *mmc_alloc_words(unsigned nwords);
#define mmc_GC_init(void)
#define mmc_GC_init_default(void)
#define mmc_GC_clear(void)
#define mmc_GC_collect(local_GC_state)

#endif

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_H_ */
