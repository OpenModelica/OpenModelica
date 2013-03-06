
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

/***********************************************************************/
/***********************************************************************/
/***************************** SETTINGS ********************************/
/***********************************************************************/
/***********************************************************************/
mmc_GC_settings_type mmc_GC_settings_default =
{
  MMC_GC_GENERATIONAL,
  MMC_YOUNG_SIZE,
  MMC_GC_NUMBER_OF_PAGES,
  MMC_GC_PAGES_SIZE_INITIAL,
  MMC_GC_PAGE_SIZE,
  MMC_GC_FREE_SLOTS_SIZE_INITIAL,
  MMC_GC_NUMBER_OF_MARK_THREADS,
  MMC_GC_NUMBER_OF_SWEEP_THREADS,
  MMC_GC_ROOTS_SIZE_INITIAL,
  MMC_GC_ROOTS_MARKS_SIZE_INITIAL,
  0,0,0
};

/* create the settings */
mmc_GC_settings_type settings_create(
  size_t    number_of_pages,
  size_t    pages_size,
  size_t    page_size,
  size_t    free_slots_size,
  size_t    roots_size,
  size_t    roots_marks_size,
  size_t    number_of_mark_threads,
  size_t    number_of_sweep_threads)
{
  mmc_GC_settings_type settings = {0};

  settings.number_of_pages = number_of_pages;
  settings.pages_size = pages_size;
  settings.page_size = page_size;
  settings.free_slots_size = free_slots_size;
  settings.roots_size = roots_size;
  settings.roots_marks_size = roots_marks_size;
  settings.number_of_mark_threads = number_of_mark_threads;
  settings.number_of_sweep_threads = number_of_sweep_threads;
  return settings;
}

/***********************************************************************/
/***********************************************************************/
/***************************** STATISTICS ******************************/
/***********************************************************************/
/***********************************************************************/
/* create the statistics structure */
mmc_GC_stats_type stats_create(void)
{
  mmc_GC_stats_type stats = {0, 0, 0};
  return stats;
}



/***********************************************************************/
/***********************************************************************/
/******************************* LISTS *********************************/
/***********************************************************************/
/***********************************************************************/

/* make an empty list */
mmc_GC_free_list_type* list_create(size_t default_free_slots_size)
{
  mmc_GC_free_list_type* list = (mmc_GC_free_list_type*)malloc(sizeof(mmc_GC_free_list_type));
  size_t i = 0;

  if (!list)
  {
    fprintf(stderr, "not enough memory (%lu) to allocate the free list!\n", sizeof(mmc_GC_page_type));
    fflush(NULL);
    assert(list != 0);
  }

  list->szLarge.start = (mmc_GC_free_slot_type*)malloc(sizeof(mmc_GC_free_slot_type)*default_free_slots_size);

  if (!list->szLarge.start)
  {
    fprintf(stderr, "not enough memory (%lu) to allocate the free list!\n", sizeof(mmc_GC_free_slot_type)*default_free_slots_size);
    fflush(NULL);
    assert(list->szLarge.start != 0);
  }

  list->szLarge.current = 0;
  list->szLarge.limit = default_free_slots_size;
  memset(list->szLarge.start, 0, sizeof(mmc_GC_free_slot_type)*default_free_slots_size);

  list->szSmall[0].current = 0;
  list->szSmall[0].limit = 0;

  for (i = 0; i < MMC_GC_FREE_SIZES; i++)
  {
    list->szSmall[i].start = (modelica_metatype*)malloc(sizeof(modelica_metatype)*default_free_slots_size);

    if (!list->szSmall[i].start)
    {
      fprintf(stderr, "not enough memory (%lu) to allocate the free list!\n", sizeof(modelica_metatype)*default_free_slots_size);
      fflush(NULL);
      assert(list->szSmall[i].start != 0);
    }

    list->szSmall[i].current = 0;
    list->szSmall[i].limit = default_free_slots_size;
    memset(list->szSmall[i].start, 0, sizeof(modelica_metatype)*default_free_slots_size);
  }

  return list;
}


mmc_GC_free_list_type* list_add(mmc_GC_free_list_type* free, modelica_metatype p, size_t size)
{
  assert(size <= MMC_MAX_SLOTS);

  /* if size is small, add it to the small list! */
  if (size < MMC_GC_FREE_SIZES)
  {
    mmc_GC_free_slots_fixed_type* slot = &free->szSmall[size];

    if (slot->current + 1 == slot->limit) /* increase! */
    {
      slot->start = (modelica_metatype*)realloc(slot->start, (slot->limit + 1024) * sizeof(modelica_metatype));
      if (!slot->start)
      {
        fprintf(stderr, "not enough memory (%lu) to allocate the free list!\n", sizeof(modelica_metatype)*(slot->limit + 1024));
        fflush(NULL);
        assert(slot->start != 0);
      }
      slot->limit += 1024;
    }

    slot->start[ slot->current++ ] = p;
    assert(slot->current < slot->limit);

    MMC_TAG_AS_FREE_OBJECT(p, size - 1);
  }
  else /* if size is large, add it to the large list! */
  {
    mmc_GC_free_slots_type* slot = &free->szLarge;

    if (slot->current + 1 == slot->limit) /* increase! */
    {
      slot->start = (mmc_GC_free_slot_type*)realloc(slot->start, (slot->limit + 1024) * sizeof(mmc_GC_free_slot_type));
      if (!slot->start)
      {
        fprintf(stderr, "not enough memory (%lu) to allocate the free list!\n", sizeof(mmc_GC_free_slot_type)*(slot->limit + 1024));
        fflush(NULL);
        assert(slot->start != 0);
      }
      slot->limit += 1024;
    }

    slot->start[ slot->current   ].start = p;
    slot->start[ slot->current++ ].size = size;

    assert(slot->current < slot->limit);

    MMC_TAG_AS_FREE_OBJECT(p, size - 1);
  }

  return free;
}

size_t list_length(mmc_GC_free_list_type* free)
{
  size_t i = 0;
  size_t sz = 0;
  /* add the fixed size small list */
  for(i = 0; i < MMC_GC_FREE_SIZES; i++)
  {
    sz += free->szSmall[i].current;
  }
  /* add the large size list */
  sz += free->szLarge.current;

  return sz;
}


size_t list_size(mmc_GC_free_list_type* free)
{
  size_t i = 0;
  size_t sz = 0;
  /* add the fixed size small list */
  for(i = 0; i < MMC_GC_FREE_SIZES; i++)
  {
    sz += (free->szSmall[i].current * i) * MMC_SIZE_META;
  }
  /* add the large size list */
  for(i = 0; i < free->szLarge.current; i++)
  {
    sz += (free->szLarge.start[i].size) * MMC_SIZE_META;
  }

  return sz;
}


modelica_metatype list_get(mmc_GC_free_list_type* free, size_t size)
{
  modelica_metatype p = NULL;

  /* if size is small, add it to the small list! */
  if (size < MMC_GC_FREE_SIZES)
  {
    /*size_t i = size;*/

    mmc_GC_free_slots_fixed_type *slot = &free->szSmall[size];
    if (slot->current > 0)
    {
      slot->current--;
      p = slot->start[slot->current];
      MMC_TAG_AS_FREE_OBJECT(p, size - 1);
      return p;
    }
    /*
    for (i = MMC_GC_FREE_SIZES - 1; i > size; i--)
    {
      slot = &free->szSmall[i];
      if (slot->current > 0)
      {
        slot->current--;
        p = slot->start[slot->current];
        if (i > size)
        {
          size_t sz = i - size;
          free = list_add(free, (char*)p + sz*MMC_SIZE_META, sz);
        }
        return p;
      }
    }
    */
  }

  /* if size is large or we had no free slots above, add it to the large list! */
  {
    size_t i = 0;
    mmc_GC_free_slots_type *slot = &free->szLarge;
    for (i = 0; i < slot->current; i++)
    {
      if (slot->start[i].size >= size)
      {
        p = slot->start[i].start;
        if (slot->start[i].size > size) /* something to return to the list */
        {
          slot->start[i].start = (void*)(((char*)slot->start[i].start) + MMC_WORDS_TO_BYTES(size));
          slot->start[i].size = slot->start[i].size - size;

          MMC_TAG_AS_FREE_OBJECT(slot->start[i].start, slot->start[i].size - 1);
        }
        else /* equal, remove slot! */
        {
          slot->current--;
          /* move the last one in its place */
          slot->start[i] = slot->start[slot->current];
        }
        break;
      }
    }
  }

  return p;
}


/***********************************************************************/
/***********************************************************************/
/******************************* STACK *********************************/
/***********************************************************************/
/***********************************************************************/

/* make an empty stack */
mmc_stack_type* stack_create(size_t default_stack_size)
{
  mmc_stack_type* stack = (mmc_stack_type*)malloc(sizeof(mmc_stack_type));
  stack->start = (mmc_GC_local_state_type*)malloc(sizeof(mmc_GC_local_state_type)*MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
  assert(stack->start != NULL);
  stack->current = 0;
  stack->limit = MMC_GC_ROOTS_MARKS_SIZE_INITIAL;
  return stack;
}

/* check if stack is empty, nonzero */
int stack_empty(mmc_stack_type* stack)
{
  return (!stack->current);
}

/* peek stack  */
mmc_GC_local_state_type stack_peek(mmc_stack_type* stack)
{
  return stack->start[stack->current];
}

/* pop the stack */
mmc_GC_local_state_type stack_pop(mmc_stack_type* stack)
{
  assert(stack->current > 0);
  return stack->start[stack->current--];
}

/* push stack */
mmc_stack_type* stack_push(mmc_stack_type* stack, mmc_GC_local_state_type el)
{
  if ((stack->current + 1) == stack->limit) /* realloc when needed */
  {
    size_t sz = stack->limit + MMC_GC_ROOTS_MARKS_SIZE_INITIAL;
    stack->start = (mmc_GC_local_state_type*)realloc(stack->start, sizeof(mmc_GC_local_state_type)*(sz));
    assert(stack->start != NULL);
    stack->limit = sz;
  }
  stack->start[++stack->current] = el;
  return stack;
}

/* delete stack */
mmc_stack_type* stack_clear(mmc_stack_type* stack)
{
  free(stack->start);
  stack->start = NULL;
  stack->limit = 0;
  stack->current = 0;
  return stack;
}

/* realloc and decrease the stack structure */
mmc_stack_type* stack_decrease(mmc_stack_type* stack, size_t default_stack_size)
{
  size_t sz = 0;
  size_t current = stack->current;
  /*
   * do not shrink stack if stack->current is less than default_stack_size
   * and 2 * default_stack_size > stack->limits
   */
  if (stack->current < default_stack_size)
  {
    return stack;
  }
  if (stack->current * 3 < stack->limit)
  {
    sz =  stack->current * 2;
  }
  else
  {
    return stack;
  }

  /* reallocate! */
  stack->start = (mmc_GC_local_state_type*)realloc(stack->start, sz * sizeof(mmc_GC_local_state_type));
  if (!stack->start)
  {
    fprintf(stderr, "not enough memory (%lu) to re-allocate the stack array!\n", sz * sizeof(mmc_GC_local_state_type));
    fflush(NULL);
    assert(stack->start != 0);
  }
  /* the current index now points to start + current size */
  stack->current = current;
  /* the limit points to the end of the stack array */
  stack->limit   = sz;
  return stack;
}


/***********************************************************************/
/***********************************************************************/
/******************************* PAGES *********************************/
/***********************************************************************/
/***********************************************************************/
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
  mmc_GC_state->mas.totalPageSize += default_page_size;
  mmc_GC_state->mas.totalFreeSize += default_page_size;

  assert(mmc_GC_state->mas.totalFreeSize <= mmc_GC_state->mas.totalPageSize);

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

  for (i = 0; i < mmc_GC_state->mas.pages.current; i++)
  {
    page = mmc_GC_state->mas.pages.start[i];
    sz += list_length(page.free);
  }

  return sz;
}

size_t pages_list_size(mmc_GC_pages_type pages)
{
  size_t i = 0, sz = 0;
  mmc_GC_page_type page = {0};

  for (i = 0; i < mmc_GC_state->mas.pages.current; i++)
  {
    page = mmc_GC_state->mas.pages.start[i];
    sz += list_size(page.free);
  }

  return sz;
}

int is_in_free(modelica_metatype p)
{
  size_t i = 0, j = 0, k = 0;
  mmc_GC_page_type page = {0};

  for (k = 0; k < mmc_GC_state->mas.pages.current; k++)
  {
    page = mmc_GC_state->mas.pages.start[k];

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

  for(i = 0; i < mmc_GC_state->mas.pages.current; i++)
  {
    page = mmc_GC_state->mas.pages.start[i];
    if (is_in_range(p, page.start, page.size))
    {
      return 1;
    }
  }

  return 0;
}

