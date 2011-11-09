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
 * RCS: $Id: meta_modelica_gc_roots.h 8047 2011-03-01 10:19:49Z perost $
 *
 */

#ifndef META_MODELICA_GC_ROOTS_H_
#define META_MODELICA_GC_ROOTS_H_

#include "openmodelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* the roots type is an array of void* with a current index and limits */
struct mmc_GC_roots_type
{
    modelica_metatype*       start;           /* the start of the array of roots */
    size_t                   current;         /* the current limit */
    size_t                   limit;           /* the limit of roots */
    mmc_Stack_type           *marks;          /* the marks in the roots, saves current at certain points */
    size_t                   rootsStackIndex; /* the current state of the marks stack, basically number of elements */
};
typedef struct mmc_GC_roots_type mmc_GC_roots_type;

/* create the roots structure */
mmc_GC_roots_type roots_create(size_t default_roots_size, size_t default_roots_mark_size);
/* realloc and increase the roots structure */
mmc_GC_roots_type roots_increase(mmc_GC_roots_type roots, size_t default_roots_size);
/* realloc and decrease the roots structure */
mmc_GC_roots_type roots_decrease(mmc_GC_roots_type roots, size_t default_roots_size);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_ROOTS_H_ */

