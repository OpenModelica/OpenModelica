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

#include "modelica.h"

/* create and allocate a page */
mmc_GC_free_slot page_create(size_t page_size)
{
  mmc_GC_free_slot slot = {0, 0};

  slot.start = (modelica_metatype)malloc(page_size);

  if (!slot.start)
  {
    fprintf(stderr, "malloc(%ld) failed: %s\n", page_size, strerror(errno));
    fflush(NULL);
    assert(slot.start != 0);
  }

  slot.size = page_size;

  /*
  fprintf(stderr, "pages: created page of size: %lu\n", page_size); fflush(NULL);
  */
  
  /* tag the free slot! */
  MMC_TAG_AS_FREE_OBJECT(slot.start, page_size);

  return slot;
}

/* return the last allocated page */
mmc_GC_free_slot pages_current(mmc_List list)
{
  if (list_empty(list))
  {
    fprintf(stderr, "no current pages are allocated");
    fflush(NULL);
    assert(list_empty(list) != 0);
  }
    return list->el;
}

/* create the page list and add the first page */
mmc_List pages_create(size_t default_page_size, int default_number_of_pages)
{
  mmc_List list = NULL;
  int i = 0;

  for (i = 0; i < default_number_of_pages; i++)
  {
    list_cons(&list, page_create(default_page_size));
  }

  return list;
}

/* add a page */
int pages_add(mmc_List* list, mmc_GC_free_slot page)
{
  list_cons(list, page);
  return 0;
}
