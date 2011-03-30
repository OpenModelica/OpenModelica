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

#ifndef META_MODELICA_GC_LIST_H_
#define META_MODELICA_GC_LIST_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include "modelica.h"

/*
 * 
 */
struct mmc_GC_free_slot_type
{
  modelica_metatype start;
  size_t            size;
};
typedef struct mmc_GC_free_slot_type mmc_GC_free_slot_type;

struct mmc_GC_free_slots_type
{
  mmc_GC_free_slot_type*  start;
  size_t                  current;
  size_t                  limit;
};
typedef struct mmc_GC_free_slots_type mmc_GC_free_slots_type;

struct mmc_GC_free_slots_fixed_type
{
  modelica_metatype*  start;
  size_t              current;
  size_t              limit;
};
typedef struct mmc_GC_free_slots_fixed_type mmc_GC_free_slots_fixed_type;

struct mmc_GC_free_list_type
{
   mmc_GC_free_slots_fixed_type szSmall[MMC_GC_FREE_SIZES]; /* the array points to free slots of sizes equal to the index. */
   mmc_GC_free_slots_type       szLarge; /* for sizes bigger than the index in sizes */
};
typedef struct mmc_GC_free_list_type mmc_GC_free_list_type;

mmc_GC_free_list_type* list_create(size_t default_free_slots_size);
mmc_GC_free_list_type* list_add(mmc_GC_free_list_type* free, modelica_metatype p, size_t size);
size_t list_length(mmc_GC_free_list_type* free);
modelica_metatype list_get(mmc_GC_free_list_type* free, size_t size);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_LIST_H_ */

