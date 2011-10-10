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
 * This file implements the new MetaModelica Garbage Collector (GC)
 * which is a mark-and-sweep collector.
 *
 * RCS: $Id: meta_modelica_gc.h 8047 2011-03-01 10:19:49Z perost $
 *
 * At first a configurable number of pages of configurable size
 * are allocated and then made part of the free list. Allocation
 * picks up a slot from the free list and updates it.
 * All live data (made via mmc_mk_* functions) is added to the
 * array of roots. The upper limit mark of the roots array is
 * saved in a stack called marks which is pop-ed when a function
 * exits of fails.
 *
 * Garbage collection happens in several phases:
 * - mark phase when we start from roots (0 - currentMark)
 *   and marks all the objects that are live
 * - sweep phase collects all the other parts of the pages
 *   which are not marked by the mark phase into the free
 *   list which can then be reused for allocation.
 * - unmark phase when we start from roots (0 - currentMark)
 *   and un-marks all the objects that are live
 *
 * For more information see paper at Modelica Conference 2011:
 *  Martin Sjölund, Peter Fritzson, Adrian Pop
 *  "Bootstrapping a Modelica Compiler aiming at Modelica 4"
 * or contact Adrian Pop.
 *
 */

#ifndef META_MODELICA_GC_H_
#define META_MODELICA_GC_H_

#include "modelica.h"
#include "meta_modelica_gc_settings.h"
#include "meta_modelica_gc_stack.h"
#include "meta_modelica_gc_list.h"
#include "meta_modelica_gc_roots.h"
#include "meta_modelica_gc_pages.h"
#include "meta_modelica_gc_stats.h"

#if defined(__cplusplus)
extern "C" {
#endif

#define MMC_GC_MARK   1
#define MMC_GC_UNMARK 0

struct mmc_GC_state_type /* the structure of GC state */
{
  mmc_GC_settings_type    settings; /* defaults settings */
  mmc_GC_pages_type       pages; /* the allocated pages which contain a free list */
  mmc_GC_roots_type       roots; /* the current roots */
  modelica_metatype       global_roots[1024]; /* the global roots ! */
  size_t                  totalPageSize; /* the total size of pages */
  size_t                  totalFreeSize; /* the total size of free slots */
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
void *mmc_alloc_bytes(unsigned nbytes);
void *mmc_alloc_words(unsigned nwords);

/* define this to have GC!
#define _MMC_GC_
*/

#if defined(_MMC_GC_)

DLLExport void mmc_GC_set_state(mmc_GC_state_type* state);
/* initialization of MetaModelica GC */
int mmc_GC_init(mmc_GC_settings_type settings);
/* initialization with defaults */
int mmc_GC_init_default(void);
/* clear of MetaModelica GC */
int mmc_GC_clear(void);
/* add pointers to roots */
#define mmc_GC_add_root(A,B,C) mmc_GC_add_roots(A,1,B,C)
void mmc_GC_add_roots(modelica_metatype*, int, mmc_GC_local_state_type local_GC_state, const char*);
/* save the current roots mark */
mmc_GC_local_state_type mmc_GC_save_roots_state(const char* name);
/* remove the current roots mark */
int mmc_GC_undo_roots_state(mmc_GC_local_state_type local_GC_state);
/* unwind to current function */
int mmc_GC_unwind_roots_state(mmc_GC_local_state_type local_GC_state);
/* do garbage collection */
int mmc_GC_collect(mmc_GC_local_state_type local_GC_state);

#else /* NO GC */

extern mmc_GC_local_state_type dummy_local_GC_state;

#define mmc_GC_init(settings)                          
#define mmc_GC_init_default(void)                      
#define mmc_GC_clear(void)                             
#define mmc_GC_add_root(A,B,C)                         
#define mmc_GC_add_roots(p, n, local_GC_state, name)   
#define mmc_GC_save_roots_state(name)                  (dummy_local_GC_state)
#define mmc_GC_undo_roots_state(local_GC_state)        
#define mmc_GC_unwind_roots_state(local_GC_state)      
#define mmc_GC_collect(local_GC_state)                 

#endif /* defined(_MMC_GC_) */

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_H_ */
