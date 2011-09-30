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
 * This file implements the new MetaModelica Garbage Collector
 * which is a mark-and-sweep collector. See more information
 * in meta_modelica_gc.h file.
 *
 * RCS: $Id: meta_modelica_gc.c 8047 2011-03-01 10:19:49Z perost $
 *
 */

#include "modelica.h"

#if defined(_MMC_GC_)

mmc_GC_state_type *mmc_GC_state = NULL;

char debug = 0;

void mmc_GC_set_state(mmc_GC_state_type* state)
{
  if (debug)
  {
    fprintf(stderr, "setting state -> before: %p, after: %p\n", (void*)mmc_GC_state, (void*)state);
    fflush(NULL);
  }
  mmc_GC_state = state;
}

/* initialization of MetaModelica GC */
int mmc_GC_init(mmc_GC_settings_type settings)
{
  /* already done the GC init */
  if (mmc_GC_state) return 0;

  {
  int i = 0;
  mmc_GC_state = (mmc_GC_state_type*) malloc (sizeof(mmc_GC_state_type));

  if (debug) { fprintf(stderr, "mmc_GC_init!\n"); fflush(NULL); }

  if (!mmc_GC_state)
  {
    fprintf(stderr, "not enough memory to allocate the GC state structure!\n");
    fflush(NULL);
    assert(mmc_GC_state != 0);
  }

  /* create the GC state structures */
  mmc_GC_state->settings = settings;
  mmc_GC_state->totalPageSize = 0;
  mmc_GC_state->totalFreeSize = 0;
  mmc_GC_state->pages = pages_create(settings.pages_size, settings.page_size, settings.number_of_pages, settings.free_slots_size);
  mmc_GC_state->roots = roots_create(settings.roots_size, settings.roots_marks_size);
  mmc_GC_state->stats = stats_create();
  
  for (i=0; i < 1024; i++)
  {
    mmc_GC_state->global_roots[i] = 0;
  }

  return 0;
  }
}

int mmc_GC_init_default(void)
{
  mmc_GC_init(mmc_GC_settings_default);
  
  return 0;
}

int mmc_GC_clear(void)
{
  /* already done the GC clear */
  if (!mmc_GC_state) return 0;

  {
  if (debug) { fprintf(stderr, "mmc_GC_clear!\n"); fflush(NULL); }

  free(mmc_GC_state->roots.marks->start);
  free(mmc_GC_state->roots.marks);
  free(mmc_GC_state->roots.start);
  free(mmc_GC_state);
  mmc_GC_state = NULL;

  return 0;
  }
}

/* add pointers to roots */
int mmc_GC_add_roots(modelica_metatype* p, int n, mmc_GC_local_state_type local_GC_state, const char* name)
{
  int i;
  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }

  assert(mmc_GC_state != NULL);

  while (mmc_GC_state->roots.current + n >=  mmc_GC_state->roots.limit)
  {
    /* roots are filled, realloc! */
    mmc_GC_state->roots = roots_increase(mmc_GC_state->roots, mmc_GC_state->settings.roots_size);
  }

  if (p)
  {
    /* if p is not null and inside the page, add it */
    /* if (!*p || (*p && is_inside_page(*p))) */

    {
      /* check if already added
      size_t i = 0;
      for (i = 0; i < mmc_GC_state->roots.current; i++)
      {
        if (mmc_GC_state->roots.start[i] == *p)
        {
          if (debug)
          {
            fprintf(stderr, "root: PRESENT %ld -> ", i, p, *p); fflush(NULL);
          }
        }
      }
      */
      for (i=0; i<n; i++) {
        /* set the pointer to current */
        mmc_GC_state->roots.start[mmc_GC_state->roots.current] = p+i;
        if (debug)
        {
          fprintf(stderr, "root: ADDED  %ld %p *%p ->", mmc_GC_state->roots.current, (void*) p, *p); fflush(NULL);
        }
        /* increase the current */
        mmc_GC_state->roots.current++;
      }
    }

    if (debug)
    {
      fprintf(stderr, " %s.%s\n", local_GC_state.functionName, name);
      /*
      mmc_Stack s = mmc_GC_state->roots.marks;
      while (s != NULL)
      {
        fprintf(stderr, "%s / ", s->el.functionName); fflush(NULL);
        s = s->next;
      }
      fprintf(stderr, "\n", name);
      */
    }


  }

  return 0;
}

/* save the current roots mark */
mmc_GC_local_state_type mmc_GC_save_roots_state(const char* name)
{
  mmc_GC_local_state_type local_GC_state = {0, 0};
  size_t mark = 0;

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }

  assert(mmc_GC_state != NULL);

  mark = mmc_GC_state->roots.current;

  /* increasing stack index */
  mmc_GC_state->roots.rootsStackIndex++;
  local_GC_state.functionName = name;
  local_GC_state.rootsMark = mark;
  local_GC_state.rootsStackIndex = mmc_GC_state->roots.rootsStackIndex;

  /* push the current index in the roots */
  mmc_GC_state->roots.marks = stack_push(mmc_GC_state->roots.marks, local_GC_state);

  if (debug)
  {
    fprintf(stderr, "stack: -> %ld %ld %s\n",
      local_GC_state.rootsStackIndex,
      local_GC_state.rootsMark,
      name);
    fflush(NULL);
  }

  return local_GC_state;
}

/* unwind to current function */
int mmc_GC_unwind_roots_state(mmc_GC_local_state_type local_GC_state)
{
/*  return mmc_GC_undo_roots_state(local_GC_state); */
  mmc_GC_local_state_type roots_index = {0, 0, 0};

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }

  assert(mmc_GC_state != NULL);

  roots_index = stack_peek(mmc_GC_state->roots.marks);

  if (debug)
  {
    fprintf(stderr, "stack: UW %ld %ld %s - top stack: %ld %ld %s\n",
        local_GC_state.rootsStackIndex,
        local_GC_state.rootsMark,
        local_GC_state.functionName,
        roots_index.rootsStackIndex,
        roots_index.rootsMark,
        roots_index.functionName
        );
    fflush(NULL);
  }

  /* pop until you reach the function scope or empty! */
  while (roots_index.rootsStackIndex > local_GC_state.rootsStackIndex)
  {
    if (debug)
    {
      fprintf(stderr, "stack: -- %ld %ld %s\n",
          roots_index.rootsStackIndex,
          roots_index.rootsMark,
          roots_index.functionName);
      fflush(NULL);
    }

    /* pop the marks stack */
    roots_index = stack_pop(mmc_GC_state->roots.marks);

    if (debug)
    {
      fprintf(stderr, "stack: <- %ld %ld %s\n",
          roots_index.rootsStackIndex,
          roots_index.rootsMark,
          roots_index.functionName);
      fflush(NULL);
    }

    if (stack_empty(mmc_GC_state->roots.marks))
      break;

    roots_index = stack_peek(mmc_GC_state->roots.marks);
  }


  if (debug)
  {
    fprintf(stderr, "stack: UF %ld %ld %s\n",
        roots_index.rootsStackIndex,
        roots_index.rootsMark,
        roots_index.functionName);
    fflush(NULL);
  }

  /* reset the roots current index */
  mmc_GC_state->roots.current         = roots_index.rootsMark;
  mmc_GC_state->roots.rootsStackIndex = roots_index.rootsStackIndex;

  /* decrease the roots size if we can */
  mmc_GC_state->roots = roots_decrease(mmc_GC_state->roots, mmc_GC_state->settings.roots_size);
  /* decrease the stack size if we can */
  mmc_GC_state->roots.marks = stack_decrease(mmc_GC_state->roots.marks, mmc_GC_state->settings.roots_marks_size);

  return 0;

}


/* remove the current roots mark */
int mmc_GC_undo_roots_state(mmc_GC_local_state_type local_GC_state)
{
  mmc_GC_local_state_type roots_index = {0, 0, 0};

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }

  assert(mmc_GC_state != NULL);

  roots_index = stack_peek(mmc_GC_state->roots.marks);

  if (debug)
  {
    fprintf(stderr, "stack: GC %ld %ld %s - top stack: %ld %ld %s\n",
        local_GC_state.rootsStackIndex,
        local_GC_state.rootsMark,
        local_GC_state.functionName,
        roots_index.rootsStackIndex,
        roots_index.rootsMark,
        roots_index.functionName
        );
    fflush(NULL);
  }

  /* pop until you reach the function scope or empty! */
  while (roots_index.rootsStackIndex >= local_GC_state.rootsStackIndex)
  {
    if (debug)
    {
      fprintf(stderr, "stack: -- %ld %ld %s\n",
          roots_index.rootsStackIndex,
          roots_index.rootsMark,
          roots_index.functionName);
      fflush(NULL);
    }

    /* pop the marks stack */
    roots_index = stack_pop(mmc_GC_state->roots.marks);

    if (debug)
    {
      fprintf(stderr, "stack: <- %ld %ld %s\n",
          roots_index.rootsStackIndex,
          roots_index.rootsMark,
          roots_index.functionName);
      fflush(NULL);
    }

    if (stack_empty(mmc_GC_state->roots.marks))
      break;

    roots_index = stack_peek(mmc_GC_state->roots.marks);
  }


  if (debug)
  {
    fprintf(stderr, "stack: FI %ld %ld %s\n",
        roots_index.rootsStackIndex,
        roots_index.rootsMark,
        roots_index.functionName);
    fflush(NULL);
  }

  /* reset the roots current index */
  mmc_GC_state->roots.current         = roots_index.rootsMark;
  mmc_GC_state->roots.rootsStackIndex = roots_index.rootsStackIndex;

  /* decrease the roots size if we can */
  mmc_GC_state->roots = roots_decrease(mmc_GC_state->roots, mmc_GC_state->settings.roots_size);
  /* decrease the stack size if we can */
  mmc_GC_state->roots.marks = stack_decrease(mmc_GC_state->roots.marks, mmc_GC_state->settings.roots_marks_size);

  return 0;
}

void walk_object(modelica_metatype p)
{
mmc_walk_top:

  /* if (debug) fprintf(stderr, "walking: %p\n", p); fflush(NULL); */

  assert(p != NULL);
  /*
  if (is_in_free(MMC_UNTAGPTR(p)))
  {
    if (debug) fprintf(stderr, "walking: %p\n", p); fflush(NULL);
    assert(0);
  }
  */

  if( MMC_IS_IMMEDIATE(p) )
  {
    /* if (debug) fprintf(stderr, "immediate: %p\n", p); fflush(NULL); */
    return;
  }
  else
  {
    mmc_uint_t hdr;
    struct mmc_header* sh = NULL;

    if (!is_inside_page(p)) /* do not mark/unmark outside pages, but dive in! */
    {
      return;
    }
    hdr = MMC_GETHDR(p);

    assert(MMC_HDRCTOR(MMC_HDR_UNMARK(hdr)) != MMC_FREE_OBJECT_CTOR);
    assert(MMC_HDRCTOR(hdr) != MMC_FREE_OBJECT_CTOR);

    if (MMC_HDR_UNMARK(hdr) == MMC_NILHDR) /* do not mark nil! */
      return;
    if (MMC_HDR_UNMARK(hdr) == MMC_STRUCTHDR(0,1)) /* do not mark none! */
      return;

    /* if we should mark it and is already marked, return */
    if ( MMC_HDRISMARKED(hdr) ) return;
    /* else, mark it */
    /* if (debug) fprintf(stderr, "casting the header\n"); fflush(NULL); */
    sh = ((struct mmc_header*)MMC_UNTAGPTR(p));
    /* if (debug) fprintf(stderr, "marking: %p %ul\n", p, sh->header); fflush(NULL); */
    sh->header = MMC_HDR_MARK(hdr);
    /* if (debug) fprintf(stderr, "marked: %p\n", p); fflush(NULL); */

    /* if is string or real, just return */
    if( MMC_HDRISSTRING(MMC_HDR_UNMARK(hdr)) || (MMC_HDR_UNMARK(hdr) == MMC_REALHDR) )
    {
      /* if (debug) fprintf(stderr, "real or string: %p\n", p); fflush(NULL); */
      return;
    }

    /* if is a structure, dive in! */
    if( MMC_HDRISSTRUCT(MMC_HDR_UNMARK(hdr)) )
    {
      mmc_uint_t slots = MMC_HDRSLOTS(MMC_HDR_UNMARK(hdr));
      mmc_uint_t ctor  = MMC_HDRCTOR(MMC_HDR_UNMARK(hdr));
      mmc_uint_t slotsMin  = 0, index = 0;
      void **pp = NULL;

      /* if (debug) fprintf(stderr, "structure: %p\n", p); fflush(NULL); */
      if (slots == 0) return;

      pp = MMC_STRUCTDATA(p);

      if (slots > 0 && ctor != MMC_ARRAY_TAG && ctor > 1) /* RECORD */
      {
        slotsMin = 1; /* ignore the fields slot! */
      }

      for(index = slotsMin; index < slots; index++)
      {
        if (pp[index])
        {
          walk_object(pp[index]);
          /* goto mmc_walk_top; */
        }
      }
    }
    else /* not a structure, move on! */
    {
      return;
    }
  }
  return;
}

/* the mark phase */
int mmc_GC_collect_mark(void)
{
  size_t index = 0;
  modelica_metatype* p = NULL;

  assert(mmc_GC_state != NULL);

  /*
   * here we should start a number of mark threads:
   *   mmc_GC_state->default_number_of_mark_threads
   * we can mark objects using multiple threads,
   * each thread marking starting from a different
   * root or a different root set.
   * for now, we just do it in serial
   */

  for(index = 0; index < mmc_GC_state->roots.current; index++)
  {
    p = (void**)(mmc_GC_state->roots.start[index]);
    if (p && *p)
    {
      int a=0;
      if (debug)
      {
        fprintf(stderr, "marking object: %ld %p *%p ->", index, (void*) p, *p); fflush(NULL);
        /* printAny(*p); */
        fprintf(stderr, "\n"); fflush(NULL);
      }

      if (!MMC_IS_IMMEDIATE(*p) && !MMC_HDRISMARKED(MMC_GETHDR(*p)))
      {
        /* assert(is_in_free(*p) == 0); */
        walk_object(*p);
        if (debug) { fprintf(stderr, ">> marking done <<\n"); fflush(NULL); }
      }
      else
      {
        if (debug) { fprintf(stderr, ">> obj skipped a:%d <<\n", a); fflush(NULL); }
      }
    }
  }

  /* mark global roots! */
  for(index = 0; index < 1024; index++)
  {
    p = &mmc_GC_state->global_roots[index];
    if (p && *p && !MMC_IS_IMMEDIATE(*p) && !MMC_HDRISMARKED(MMC_GETHDR(*p)) /*&&  is_inside_page(*p) */)
    {
      if (debug) { fprintf(stderr, "marking global object: %ld %p ->", index, mmc_GC_state->global_roots[index]); fflush(NULL); }
      /* printAny(mmc_GC_state->global_roots[index]); */
      if (debug) { fprintf(stderr, "\n"); fflush(NULL); }

      /* assert(is_in_free(*p) == 0); */

      walk_object(*p);
    }
  }

  return 0;
}


/*
 * walk page object by object and add all
 * unmarked objects region to the free list!
 */
int sweep_page(mmc_GC_page_type page)
{
  modelica_metatype scan = page.start;
  mmc_uint_t hdr = 0, unmarkedHdr = 0, slots = 0, sz = 0, ctor = 0;

  /*
  if (debug) fprintf(stderr, "sweeping page: %p, filled: %u\n", (void*)scan, filledSize); fflush(NULL);
  */

  /* scan the page */
  while ((char*)scan < (char*)page.start + page.size)
  {
    assert(scan >= page.start);
    /* get the obj header */
    hdr = MMC_GETHDR(MMC_TAGPTR(scan));
    unmarkedHdr = MMC_HDR_UNMARK(hdr);
    ctor  = MMC_HDRCTOR(unmarkedHdr);
    /*
     * for real we need to use struct mmc_real to find out the slots
     * as the structures might be aligned at different boundery.
     */
    if (MMC_HDR_UNMARK(hdr) == MMC_REALHDR)
    {
      slots = (sizeof(struct mmc_real)/sizeof(void*)) - 1;
    }
    else
    {
      slots = MMC_HDRSLOTS(MMC_HDR_UNMARK(hdr));
    }

    /* skip fre objects! */
    if (ctor == MMC_FREE_OBJECT_CTOR || MMC_HDRCTOR(hdr) == MMC_FREE_OBJECT_CTOR)
    {
      sz = (slots + 1) * sizeof(void*);
      if (debug) 
      {
        fprintf(stderr, "skipping free object: %p size:%ld\n", scan, sz); 
        fflush(NULL);
      }
      scan = (void*)((char*)scan + sz);
      continue;
    }

    if (debug) 
    {
      fprintf(stderr, "get obj header: hdr:%ld ctor:%ld slots:%ld\n", MMC_HDR_UNMARK(hdr), ctor, slots); 
      fflush(NULL);
    }

    /* if the object is marked, skip it */
    if (MMC_HDRISMARKED(hdr))
    {
      /* do nothing */
      if (debug) 
      {
        fprintf(stderr, "skipping and unmarking marked obj: %p size:%ld\n", scan, (slots+1)*sizeof(void*)); 
        fflush(NULL);
      }
      ((struct mmc_header*)scan)->header = MMC_HDR_UNMARK(hdr);
    }
    else /* object is unmarked, add it to the free list */
    {
      if (debug)
      {
        fprintf(stderr, "add free obj: hdr:%ld ctor:%ld slots:%ld p:%p\n", MMC_HDR_UNMARK(hdr), ctor, slots, scan); 
        printAny(MMC_TAGPTR(scan));
        fprintf(stderr, "\n");
        fflush(NULL);
      }
      
      page.free = list_add(page.free, scan, slots + 1);
      mmc_GC_state->totalFreeSize += (size_t)MMC_WORDS_TO_BYTES(slots + 1);
  
      if (debug)
      {
        size_t sz = pages_list_size(mmc_GC_state->pages);
        if (sz != mmc_GC_state->totalFreeSize)
        {
          fprintf(stderr, "add free obj: hdr:%ld/%lu ctor:%ld slots:%ld p:%p\n", MMC_HDR_UNMARK(hdr), hdr, ctor, slots, scan);
          fflush(NULL);
        }
        assert(sz == mmc_GC_state->totalFreeSize);
      }

      assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);

    }
    /* move to next object which should be after slots + 1 (the header) */
    scan = (void*)((char*)scan + (slots + 1)*sizeof(void*));
  }
  
  return 0;
}

/* the sweep phase */
int mmc_GC_collect_sweep(void)
{
  size_t i = 0;
  mmc_GC_page_type page = {0};

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }

  assert(mmc_GC_state != NULL);

  /*
   * here we should start a number of sweep threads:
   *   mmc_GC_state->default_number_of_sweep_threads
   * we can sweep using multiple threads, for example
   * one for each page, or one for each half page.
   * for now, we just do it in serial
   */

  /*
   * walk all pages object by object and add all
   * unmarked objects region to the free list!
   */

  for (i = 0; i < mmc_GC_state->pages.current; i++)
  {
    page = mmc_GC_state->pages.start[i];
    sweep_page(page);
  }

  return 0;
}

int compareAddress (const void* a, const void* b)
{
  return ( (char*)((mmc_GC_free_slot_type*)a)->start - (char*)((mmc_GC_free_slot_type*)b)->start );
}

int compareSize (const void* a, const void* b)
{
  return ( (char*)((mmc_GC_free_slot_type*)a)->size - (char*)((mmc_GC_free_slot_type*)b)->size );
}

/* try to join all possible slots in the list! */
mmc_GC_pages_type free_list_compact(mmc_GC_pages_type pages)
{
  size_t i = 0, j = 0, k = 0;

  for (i = 0; i < pages.current; i++)
  {
    size_t len = pages.start[i].free->szLarge.current;
    mmc_GC_free_slot_type* freeArr = (mmc_GC_free_slot_type*)malloc(sizeof(mmc_GC_free_slot_type) * len);
    mmc_GC_free_slot_type slot = {0, 0}, joinSlot = {0, 0};
    memcpy(freeArr, pages.start[i].free->szLarge.start, len * sizeof(mmc_GC_free_slot_type));
    /* sort the array in the order of addresses */
    qsort (freeArr, len, sizeof(mmc_GC_free_slot_type), compareAddress);
    /* join the slots */
    k = 0;
    slot = freeArr[0];
    joinSlot = freeArr[0];
    for (j = 1; j < len; j++)
    {
      /* join if possible*/
      if (((char*)joinSlot.start + joinSlot.size*MMC_SIZE_META) == freeArr[j].start)
      {
        joinSlot.size  = joinSlot.size + freeArr[j].size;
      }
      else /* add it like it is! */
      {
        pages.start[i].free->szLarge.start[k] = joinSlot;
        MMC_TAG_AS_FREE_OBJECT(joinSlot.start, joinSlot.size - 1);
        k++;
        joinSlot = freeArr[j];
      }
    }
    pages.start[i].free->szLarge.start[k++] = joinSlot;
    pages.start[i].free->szLarge.current = k;
    pages.start[i].free->szLarge.start = 
      (mmc_GC_free_slot_type*)realloc(
        pages.start[i].free->szLarge.start,
        (k+1)*sizeof(mmc_GC_free_slot_type));
    pages.start[i].free->szLarge.limit = k+1;
    /*
    qsort (pages.start[i].free->szLarge.start, k, sizeof(mmc_GC_free_slot_type), compareSize);
    */
    free(freeArr);
  }
  
  return pages;
}


/* do garbage collection */
int mmc_GC_collect(mmc_GC_local_state_type local_GC_state)
{
  size_t sizeFree = 0, sizePages = 0, saved;

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }

  assert(mmc_GC_state != NULL);

  sizePages = mmc_GC_state->totalPageSize;
  sizeFree = mmc_GC_state->totalFreeSize;
  saved = sizeFree;
  assert(sizeFree <= sizePages);

  /* only collect if sizeof free is 5% sizeof pages */
  if ((double)sizeFree * 4 > mmc_GC_state->settings.page_size)
  {
    return 0;
  }

  if (debug)
  {
    fprintf(stderr, "GC before: [%s] sizeFree: %ld sizePages: %ld procent: %.3g\n",
        local_GC_state.functionName,
        sizeFree, sizePages,
        (double)sizeFree*100/(double)sizePages);
  }


  if (debug) fprintf(stderr, "mark\n"); fflush(NULL);
  mmc_GC_collect_mark();
  if (debug) fprintf(stderr, "sweep\n"); fflush(NULL);
  mmc_GC_collect_sweep();
  if (debug) fprintf(stderr, "collect done\n"); fflush(NULL);

  sizePages = mmc_GC_state->totalPageSize;
  sizeFree = mmc_GC_state->totalFreeSize;
  assert(sizeFree <= sizePages);

  mmc_GC_state->pages = free_list_compact(mmc_GC_state->pages);

  if ((sizeFree - saved) && debug)
  {
    fprintf(stderr, "GC collect: free: %8.2fMb pages: %8.2fMb free: %8.3f%% freed: %8.4fMb  lst: %10lu p: %4ld s: %6lu r:%6lu [%s]\n",
        (double)sizeFree/(1024.0*1024.0),
        (double)sizePages/(1024.0*1024.0),
        (double)sizeFree*100.0/(double)sizePages,
        (double)(sizeFree-saved)/(1024.0*1024.0),
        pages_list_length(mmc_GC_state->pages),
        (long) mmc_GC_state->pages.current,
        mmc_GC_state->roots.rootsStackIndex,
        mmc_GC_state->roots.current,
        local_GC_state.functionName);
  }

  /* if after the collect we still have less than half a page add a new page to speed things up */
  if (((double)sizeFree * 4 <= mmc_GC_state->settings.page_size) || 
      ((sizeFree-saved) * 4 <= mmc_GC_state->settings.page_size) )
  {
    mmc_GC_page_type page = page_create(mmc_GC_state->settings.page_size, mmc_GC_state->settings.free_slots_size);
    /* add it to pages */
    mmc_GC_state->pages = pages_add(mmc_GC_state->pages, page);
  }

  return 0;
}

/* get a region of memory of required size */
modelica_metatype allocate_from_free(unsigned nbytes)
{
  modelica_metatype p = NULL;
  size_t i = 0, szWords = nbytes/MMC_SIZE_META;
  mmc_GC_page_type page = {0};
  
  assert(((double)nbytes / (double)MMC_SIZE_META) == (double)(nbytes / MMC_SIZE_META));

  /* find a free slot, look in all pages */
  for (i = 0; i < mmc_GC_state->pages.current; i++)
  {
    page = mmc_GC_state->pages.start[i];
    p = list_get(page.free, szWords);
    if (p) 
      break;
  }

  if (!p) /* add a new page */
  {
    mmc_GC_state->pages = 
      pages_add(mmc_GC_state->pages, 
        page_create(
          (mmc_GC_state->settings.page_size > nbytes) ? mmc_GC_state->settings.page_size : mmc_GC_state->settings.page_size + nbytes,
          mmc_GC_state->settings.free_slots_size));
    p = list_get(mmc_GC_state->pages.start[mmc_GC_state->pages.current - 1].free, szWords);
  }

  assert(p != NULL);
  assert(mmc_GC_state->totalFreeSize >= nbytes);

  mmc_GC_state->totalFreeSize -= (size_t)nbytes;

  if (debug)
  {
    size_t sz = pages_list_size(mmc_GC_state->pages);
    assert(sz == mmc_GC_state->totalFreeSize);
  }

  return p;
}

void *mmc_alloc_bytes(unsigned nbytes)
{
  modelica_metatype p = NULL;

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }

  assert(mmc_GC_state != NULL);

  p = allocate_from_free(nbytes);

  if (debug) 
  {
    fprintf(stderr, "alloc obj: %p, tag:%p size:%lu\n", p, MMC_TAGPTR(p), (unsigned long) nbytes); 
    fflush(NULL);
  }

  return p;
}


#else /* normal GC */

void *mmc_alloc_bytes(unsigned nbytes)
{
  static char *mmc_cur_malloc_buf = NULL;
  static long mmc_cur_malloc_buf_ix = 0;
  /* Until we have GC, we simply allocate in 256MB chunks... */
  const long mmc_cur_malloc_buf_sz = (MMC_GC_PAGE_SIZE<nbytes)?(nbytes+MMC_GC_PAGE_SIZE):(MMC_GC_PAGE_SIZE);
  void *p=0;
  /* fprintf(stderr, "1 mmc_alloc_bytes(%ld): %ld,%ld\n", nbytes, mmc_cur_malloc_buf, mmc_cur_malloc_buf_ix); */
  if (mmc_cur_malloc_buf == NULL || nbytes>(mmc_cur_malloc_buf_sz-mmc_cur_malloc_buf_ix)) {
    if ( (mmc_cur_malloc_buf = (char*)malloc(mmc_cur_malloc_buf_sz)) == 0 ) {
      fflush(NULL);
      fprintf(stderr, "malloc(%u) failed: %s\n", nbytes, strerror(errno));
      assert(p != 0);
    }
    mmc_cur_malloc_buf_ix = 0;
    assert(nbytes <= mmc_cur_malloc_buf_sz);
  }
  p = mmc_cur_malloc_buf + mmc_cur_malloc_buf_ix;

  /* Force 16-byte alignment, like malloc... TODO: Check if this is needed :) */
  mmc_cur_malloc_buf_ix += nbytes; /* + ((nbytes%16) ? 16-(nbytes%16): 0); */

  /* fprintf(stderr, "2 mmc_alloc_bytes(%ld): %ld,%ld => %ld\n", nbytes, mmc_cur_malloc_buf, mmc_cur_malloc_buf_ix, p); */
  return p;
}

static mmc_GC_state_type x_mmc_GC_state;
mmc_GC_state_type *mmc_GC_state = &x_mmc_GC_state;
mmc_GC_local_state_type dummy_local_GC_state = {0,0};

#endif /* defined(_MMC_GC_) */

/* global functions, not ifdef dependent */
/* primary allocation routine for MetaModelica */
void *mmc_alloc_words(unsigned nwords)
{
  return mmc_alloc_bytes(nwords * sizeof(void*));
}

int is_in_range(modelica_metatype p, modelica_metatype start, size_t bytes)
{
  size_t diff = 0;
  diff = (char*)p - (char*)start;
  
  if (diff >= 0 && diff < bytes)
  {
    return 1;
  }
  
  return 0;
}





