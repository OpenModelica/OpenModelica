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

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* a free slot */
struct mmc_GC_free_slot
{
  modelica_metatype        start; /* the start of the free slot */
  long                     size;  /* the free slot size */
};
typedef struct mmc_GC_free_slot mmc_GC_free_slot;

/* a linked list */
struct mmc_ListElement
{
  mmc_GC_free_slot el;
  struct mmc_ListElement *next;
};
typedef struct mmc_ListElement* mmc_List;

/* make an empty list */
mmc_List list_create(void);
/* return nonzero if the list is empty */
int list_empty(mmc_List list);
/* number of elements */
int list_length(mmc_List list);
/* deleting a node from list depending upon the data in the node */
int list_delete(mmc_List* list, mmc_GC_free_slot slot);
/* deleting a node from list depending on the location */
int list_delete_nth(mmc_List* list, int loc);
/* delete the entire list */
int list_clear(mmc_List* list);
/* adding a mmc_GC_free_slot at the end of the list */
int list_add(mmc_List* list, mmc_GC_free_slot slot);
/* adding a mmc_GC_free_slot at the end of the list */
int list_cons(mmc_List* list, mmc_GC_free_slot slot);
/* displaying list contents */
void list_dump(mmc_List* list);
/* reversing a list */
int list_reverse(mmc_List* list);
/* clone a list in reverse! */
mmc_List list_clone(mmc_List list);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_LIST_H_ */

