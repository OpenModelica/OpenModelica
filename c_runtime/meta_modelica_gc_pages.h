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

#ifndef META_MODELICA_GC_PAGES_H_
#define META_MODELICA_GC_PAGES_H_

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

struct mmc_GC_page_type
{
  modelica_metatype       start;           /* the start of the page */
  size_t                  size;            /* the size of the page in words */
  mmc_GC_free_list_type  *free;            /* the free list in the page, classified */
  size_t                  maxFree;         /* the max size of all free slots */
};
typedef struct mmc_GC_page_type mmc_GC_page_type;


struct mmc_GC_pages_type
{
  mmc_GC_page_type*       start;           /* the start of the array of pages */
  size_t                  current;         /* the current limit */
  size_t                  limit;           /* the limit of pages */
};
typedef struct mmc_GC_pages_type mmc_GC_pages_type;

/* create the pages structure and allocate the default pages with default size */
mmc_GC_pages_type pages_create(size_t default_pages_size, size_t default_page_size, size_t default_number_of_pages, size_t default_free_slots_size);
/* add a new page */
mmc_GC_pages_type pages_add(mmc_GC_pages_type pages, mmc_GC_page_type page);
/* create a new page */
mmc_GC_page_type page_create(size_t default_page_size, size_t default_free_slots_size);
/* realloc and increase the pages structure */
mmc_GC_pages_type pages_increase(mmc_GC_pages_type pages, size_t default_pages_size);
/* realloc and decrease the pages structure */
mmc_GC_pages_type pages_decrease(mmc_GC_pages_type pages, size_t default_pages_size);
/* populate the free list with free space */
mmc_GC_page_type list_populate(mmc_GC_page_type page);

int is_in_free(modelica_metatype p);
int is_inside_page(modelica_metatype p);
size_t pages_list_length(mmc_GC_pages_type pages);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_PAGES_H_ */

