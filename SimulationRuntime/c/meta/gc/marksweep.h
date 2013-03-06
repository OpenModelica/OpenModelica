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
 * This file implements the MetaModelica mark-and-sweep garbage collector (GC)
 *
 * RCS: $Id: marksweep.h 8047 2011-03-01 10:19:49Z perost $
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

#ifndef META_MODELICA_GC_MARKSWEEP_H_
#define META_MODELICA_GC_MARKSWEEP_H_

#if defined(__cplusplus)
extern "C"
{
#endif

#include "modelica.h"

struct mmc_GC_mas_state_type /* the structure of GC state */
{
  mmc_GC_pages_type       pages; /* the allocated pages which contain a free list */
  size_t                  totalPageSize; /* the total size of pages */
  size_t                  totalFreeSize; /* the total size of free slots */
};
typedef struct mmc_GC_mas_state_type mmc_GC_mas_state_type;


#if defined(__cplusplus)
}
#endif

#endif /* META_MODELICA_GC_MARKSWEEP_H_ */

