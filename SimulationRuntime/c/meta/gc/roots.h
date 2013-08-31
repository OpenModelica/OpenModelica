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
 * This file implements GC roots
 *
 * RCS: $Id: roots.h 8047 2011-03-01 10:19:49Z perost $
 *
 */


#ifndef META_MODELICA_GC_ROOTS_H_
#define META_MODELICA_GC_ROOTS_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include "common.h"

struct mmc_GC_root_type
{
  modelica_metatype*       start;
  size_t                   count;
};
typedef struct mmc_GC_root_type mmc_GC_root_type;

/* the roots type is an array of void* with a current index and limits */
struct mmc_GC_roots_type
{
    mmc_GC_root_type*        start;           /* the start of the array of roots */
    size_t                   current;         /* the current limit */
    size_t                   limit;           /* the limit of roots */
    mmc_stack_type           *marks;          /* the marks in the roots, saves current at certain points */
    size_t                   rootsStackIndex; /* the current state of the marks stack, basically number of elements */
};
typedef struct mmc_GC_roots_type mmc_GC_roots_type;


/* create the roots structure */
mmc_GC_roots_type roots_create(size_t default_roots_size, size_t default_roots_mark_size);
/* realloc and increase the roots structure */
mmc_GC_roots_type roots_increase(mmc_GC_roots_type roots, size_t default_roots_size);
/* realloc and decrease the roots structure */
mmc_GC_roots_type roots_decrease(mmc_GC_roots_type roots, size_t default_roots_size);


#if defined(_MMC_GC_)

/* add pointers to roots */
#define mmc_GC_add_root(A,B,C) mmc_GC_add_roots(A,1,B,C)
void mmc_GC_add_roots_fallback(modelica_metatype*, int, mmc_GC_local_state_type local_GC_state, const char*);

/* save the current roots mark */
/*mmc_GC_local_state_type mmc_GC_save_roots_state(const char* name);*/
/* remove the current roots mark */
/*int mmc_GC_undo_roots_state(mmc_GC_local_state_type local_GC_state);*/
/* unwind to current function */
/*int mmc_GC_unwind_roots_state(mmc_GC_local_state_type local_GC_state);*/

#define mmc_GC_save_roots_state(name)                  (mmc_GC_state->roots.current)
#define mmc_GC_undo_roots_state(local_GC_state)        (mmc_GC_state->roots.current = local_GC_state);
#define mmc_GC_unwind_roots_state(local_GC_state)


#else /* NO GC */

#define mmc_GC_add_root(A,B,C)
#define mmc_GC_add_roots(p, n, local_GC_state, name)
#define mmc_GC_save_roots_state(name)                  (0)
#define mmc_GC_undo_roots_state(local_GC_state)
#define mmc_GC_unwind_roots_state(local_GC_state)


#endif /* defined(_MMC_GC_) */

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_ROOTS_H_ */

