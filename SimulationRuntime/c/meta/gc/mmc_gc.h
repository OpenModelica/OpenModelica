/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * Adrian Pop [Adrian.Pop@liu.se]
 * This file defines the MetaModelica garbage collector (GC) interface
 *  We have two collectors:
 *  - generational
 *  - mark-and-sweep
 *  and we can switch between them at runtime when needed.
 *  We start with the generational and if there is not enough
 *  memory to allocate a new older generation we switch to a
 *  mark-and-sweep collector.
 *
 * RCS: $Id: mmc_gc.h 8047 2011-03-01 10:19:49Z perost $
 *
 */

#ifndef META_MODELICA_GC_H_
#define META_MODELICA_GC_H_

/* uncomment this to use the MetaModelica Garbage collector */
/* #define _MMC_GC_ 1 */

/* uncomment this to use the BOEHM Garbage collector */

#if !defined(_MSC_VER)  /* no gc on MSVC! */
#define _MMC_USE_BOEHM_GC_
#endif

#if defined(__cplusplus)
extern "C" {
#endif

#include "modelica.h"
#include "common.h"
#include "roots.h"
#include "generational.h"
#include "marksweep.h"

struct mmc_GC_state_type /* the structure of GC state */
{
  mmc_GC_settings_type    settings; /* defaults settings */
  mmc_GC_roots_type       roots; /* the current roots */
  mmc_GC_gen_state_type   gen; /* the generational state */
  mmc_GC_mas_state_type   mas; /* the mark-and-swep state */
  modelica_metatype       global_roots[MMC_GC_GLOBAL_ROOTS_SIZE]; /* the global roots ! */
  mmc_GC_stats_type       stats; /* the statistics */
};
typedef struct mmc_GC_state_type mmc_GC_state_type;
extern mmc_GC_state_type* mmc_GC_state;

/* tag the free reqion as a free object with 250 ctor*/
#define MMC_FREE_OBJECT_CTOR           200
#define MMC_TAG_AS_FREE_OBJECT(p, sz)  (((struct mmc_header*)p)->header = MMC_STRUCTHDR(sz, MMC_FREE_OBJECT_CTOR))

/* checks if the pointer is in range */
int is_in_range(modelica_metatype p, modelica_metatype start, size_t bytes);
/* primary allocation routines for MetaModelica */
void *mmc_alloc_words(unsigned nwords);

#if defined(_MMC_GC_)

DLLExport void mmc_GC_set_state(mmc_GC_state_type* state);
/* initialization of MetaModelica GC */
int mmc_GC_init(mmc_GC_settings_type settings);
/* initialization with defaults */
int mmc_GC_init_default(void);
/* clear of MetaModelica GC */
int mmc_GC_clear(void);
/* do garbage collection */
int mmc_GC_collect(mmc_GC_local_state_type local_GC_state);


static inline void mmc_GC_add_roots(modelica_metatype* p, int n, mmc_GC_local_state_type local_GC_state, const char* name)
{
  if (mmc_GC_state->roots.current + 1 <  mmc_GC_state->roots.limit)
  {
    if (p)
    {
    mmc_GC_state->roots.start[mmc_GC_state->roots.current].start = p;
    mmc_GC_state->roots.start[mmc_GC_state->roots.current++].count = n;
    }
  }
  else
  {
    mmc_GC_add_roots_fallback(p, n, local_GC_state, name);
  }
}

#else

#if defined(_MMC_USE_BOEHM_GC_) /* use the BOEHM Garbage collector */

#define LARGE_CONFIG
#include <gc.h>

#define mmc_GC_init(settings) GC_INIT()
#define mmc_GC_init_default(void) GC_INIT()
#define mmc_GC_clear(void)
#define mmc_GC_collect(local_GC_state)

#else /* NO_GC */

#define mmc_GC_init(settings)
#define mmc_GC_init_default(void)
#define mmc_GC_clear(void)
#define mmc_GC_collect(local_GC_state)

#endif
#endif /* defined(_MMC_GC_) */


#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_H_ */
