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
    size_t i = size;

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
