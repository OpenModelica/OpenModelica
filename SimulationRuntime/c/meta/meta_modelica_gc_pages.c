/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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

#include "openmodelica.h"
#include "meta_modelica.h"

/* create the pages structure and allocate the default pages with default size */
mmc_GC_pages_type pages_create(size_t default_pages_size, size_t default_page_size, size_t default_number_of_pages, size_t default_free_slots_size)
{
  mmc_GC_pages_type pages = {0, 0, 0,};
  size_t sz = sizeof(mmc_GC_page_type) * default_pages_size;
  size_t i = 0;

  pages.start = (mmc_GC_page_type*)malloc(sz);
  if (!pages.start)
  {
    fprintf(stderr, "not enough memory (%lu) to allocate the pages!\n",
        (long unsigned int)sz);
    fflush(NULL);
    assert(pages.start != 0);
  }  
  /* the current index points to the start at the begining! */
  pages.current = 0;
  /* the limit points to the end of the pages array */
  pages.limit   = default_pages_size;

  for (i = 0; i < default_number_of_pages; i++)
  {
    pages = pages_add(pages, page_create(default_page_size, default_free_slots_size));
  }

  return pages;
}

mmc_GC_page_type page_create(size_t default_page_size, size_t default_free_slots_size)
{
  mmc_GC_page_type page = {0, 0, 0, 0};
  
  page.start = (modelica_metatype)malloc(default_page_size);
  
  if (!page.start)
  {
    fprintf(stderr, "not enough memory (%lu) to allocate the pages!\n",
        (long unsigned int)default_page_size);
    fflush(NULL);
    assert(page.start != 0);
  }
  
  page.size = default_page_size;
  page.free = list_create(default_free_slots_size);
  page = list_populate(page);
  page.maxFree = default_page_size;
  
  /* update the total sizes! */
  mmc_GC_state->totalPageSize += default_page_size;
  mmc_GC_state->totalFreeSize += default_page_size;

  assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);

  return page;
}

/* add a new page */
mmc_GC_pages_type pages_add(mmc_GC_pages_type pages, mmc_GC_page_type page)
{
  if (pages.current + 1 >=  pages.limit)
  {
    /* roots are filled, realloc! */
    pages = pages_increase(pages, mmc_GC_state->settings.pages_size);
  }
  pages.start [ pages.current++ ] = page;
  
  return pages;
}

/* realloc and increase the pages structure */
mmc_GC_pages_type pages_increase(mmc_GC_pages_type pages, size_t default_pages_size)
{
  size_t sz = (pages.limit + default_pages_size) * sizeof(mmc_GC_page_type);
  size_t current = pages.current;

  /* reallocate! */
  pages.start = (mmc_GC_page_type*)realloc(pages.start, sz);
  if (!pages.start)
  {
    fprintf(stderr, "not enough memory (%lu) to re-allocate the pages array!\n",
        (long unsigned int)sz);
    fflush(NULL);
    assert(pages.start != 0);
  }

  /* the current index now points to start + current size */
  pages.current = current;
  /* the limit points to the end of the pages array */
  pages.limit   += default_pages_size;

  return pages;
}

/* realloc and decrease the pages structure */
mmc_GC_pages_type pages_decrease(mmc_GC_pages_type pages, size_t default_pages_size)
{
  size_t sz = 0;
  size_t current = pages.current;
  /* size_t i = 0; */
  /*
   * do not shrink pages if pages.current is less than default_pages_size
   * and 2 * default_pages_size > pages.limits
   */
  if (pages.current < default_pages_size)
  {
    return pages;
  }
  if (pages.current * 3 < pages.limit)
  {
    sz =  pages.current * 2;
  }
  else
  {
    return pages;
  }
  
  /* reallocate! */
  pages.start = (mmc_GC_page_type*)realloc(pages.start, sz * sizeof(mmc_GC_page_type));
  
  if (!pages.start)
  {
    fprintf(stderr, "not enough memory (%lu) to re-allocate the pages array!\n",
        (long unsigned int)(sz * sizeof(void*)));
    fflush(NULL);
    assert(pages.start != 0);
  }
  /* the current index now points to start + current size */
  pages.current = current;
  /* the limit points to the end of the pages array */
  pages.limit   = sz;

  return pages;
}

/* populate the free list with free space */
mmc_GC_page_type list_populate(mmc_GC_page_type page)
{
  /*size_t i = 0;*/ /* get rid of warnings*/
  size_t sz = MMC_MAX_OBJECT_SIZE_BYTES;
  modelica_metatype p = page.start;
  if (sz > page.size) /* we have pages less than max obj size! */
  {
    page.free = list_add(page.free, p, page.size/MMC_SIZE_META);
    return page;
  }
  
  /* 
   * if page size is bigger than the max object size
   * we need to generate several free slots!
   */
  while (sz < page.size)
  {    
    page.free = list_add(page.free, p, MMC_MAX_SLOTS);
    p = (void*)(((char*)p) + MMC_MAX_OBJECT_SIZE_BYTES);
    sz = sz + MMC_MAX_OBJECT_SIZE_BYTES;
  }
  /* add the last slot! */
  sz -= MMC_MAX_OBJECT_SIZE_BYTES;
  page.free = list_add(page.free, p, (page.size - sz)/MMC_SIZE_META);

  return page;
}

size_t pages_list_length(mmc_GC_pages_type pages)
{
  size_t i = 0, sz = 0;
  mmc_GC_page_type page = {0};
  
  for (i = 0; i < mmc_GC_state->pages.current; i++)
  {
    page = mmc_GC_state->pages.start[i];
    sz += list_length(page.free);
  }
  
  return sz;
}

size_t pages_list_size(mmc_GC_pages_type pages)
{
  size_t i = 0, sz = 0;
  mmc_GC_page_type page = {0};
  
  for (i = 0; i < mmc_GC_state->pages.current; i++)
  {
    page = mmc_GC_state->pages.start[i];
    sz += list_size(page.free);
  }
  
  return sz;
}

int is_in_free(modelica_metatype p)
{
  size_t i = 0, j = 0, k = 0;
  mmc_GC_page_type page = {0};
  
  for (k = 0; k < mmc_GC_state->pages.current; k++)
  {
    page = mmc_GC_state->pages.start[k];
    
    /* search in small */
    for (i = 0; i < MMC_GC_FREE_SIZES; i++)
    {
      for (j = 0; j < page.free->szSmall[i].current; j++)
      {
        if (is_in_range(p, page.free->szSmall[i].start[j], sizeof(modelica_metatype)*i))
        {
          return 1;
        }
      }
    }
    
    /* search in big */
    for (i = 0; i < page.free->szLarge.current; i++)
    {
      if (is_in_range(p, page.free->szLarge.start[i].start, page.free->szLarge.start[i].size * sizeof(modelica_metatype)))
      {
        return 1;
      }
    }
  }
  
  return 0;
}

int is_inside_page(modelica_metatype p)
{
  mmc_GC_page_type page;
  size_t i = 0;

  for(i = 0; i < mmc_GC_state->pages.current; i++)
  {
    page = mmc_GC_state->pages.start[i];
    if (is_in_range(p, page.start, page.size))
    {
      return 1;
    }
  }
  
  return 0;
}
