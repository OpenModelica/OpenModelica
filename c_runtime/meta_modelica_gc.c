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

mmc_GC_state_type *mmc_GC_state = NULL;

const char debug = 1;

/* initialization of MetaModelica GC */
int mmc_GC_init(int nr_mark_threads, int nr_sweep_threads, long default_page_size, int default_number_of_pages, long default_roots_size)
{
  /*
  fprintf(stderr, "nilhdr: %ul\n", MMC_NILHDR); fflush(NULL);
  fprintf(stderr, "conshdr: %ul\n", MMC_CONSHDR); fflush(NULL);
  fprintf(stderr, "nonehdr: %ul\n", MMC_STRUCTHDR(0,1)); fflush(NULL);
  */

  /* do not init GC if already done */
  if (mmc_GC_state) return 0;
  mmc_GC_state = (mmc_GC_state_type*) malloc (sizeof(mmc_GC_state_type));

  if (!mmc_GC_state)
  {
    fprintf(stderr, "not enough memory to allocate the GC structure!\n");
    fflush(NULL);
    assert(mmc_GC_state != 0);
  }

  /* create the GC state structures */
  mmc_GC_state->default_number_of_mark_threads  = nr_mark_threads;
  mmc_GC_state->default_number_of_sweep_threads = nr_sweep_threads;
  mmc_GC_state->default_number_of_pages = default_number_of_pages;
  mmc_GC_state->default_page_size = default_page_size;
  mmc_GC_state->default_roots_size = default_roots_size;
  mmc_GC_state->pages = pages_create(default_page_size, default_number_of_pages);
  mmc_GC_state->roots = roots_create(default_roots_size);
  mmc_GC_state->free = list_clone(mmc_GC_state->pages); /* initially the free list is the list of pages! */
  mmc_GC_state->stats = stats_create();

  return 0;
}

/* add pointers to roots */
int mmc_GC_add_root(modelica_metatype p)
{
  /* if GC was not setup, init it */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL);
  }

  assert(mmc_GC_state != NULL);

  if (mmc_GC_state->roots.current ==  mmc_GC_state->roots.limit)
  {
    /* roots are filled, realloc! */
    mmc_GC_state->roots = roots_realloc(mmc_GC_state->roots, mmc_GC_state->default_roots_size);
  }

  /* set the pointer to current */
  *mmc_GC_state->roots.current = p;

  /* increase the current */
  mmc_GC_state->roots.current++;

  return 0;
}

/* save the current roots mark */
int mmc_GC_push_roots_mark(void)
{
  /* if GC was not setup, init it */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL);
  }

  assert(mmc_GC_state != NULL);

  {
    mmc_uint_t mark = mmc_GC_state->roots.current - mmc_GC_state->roots.start;

    if (debug) fprintf(stderr, "pushing stack %ld\n", (long)mark); fflush(NULL);

    /* push the current index in the roots */
    stack_push(&mmc_GC_state->roots.marks, mark);
  }

  return 0;
}

/* remove the current roots mark */
int mmc_GC_pop_roots_mark(void)
{
  long roots_index = 0;

  assert(mmc_GC_state != NULL);

  if (debug) fprintf(stderr, "poping stack: "); fflush(NULL);

  if (!stack_empty(mmc_GC_state->roots.marks))
  {
    /* pop the marks stack */
    stack_pop(&mmc_GC_state->roots.marks);
    /* get the previous mark */
    if (!stack_empty(mmc_GC_state->roots.marks))
    {
      roots_index = stack_peek(mmc_GC_state->roots.marks);
    }
  }

  if (debug) fprintf(stderr, "index: %ld\n", roots_index); fflush(NULL);

  /* reset the roots current index */
  mmc_GC_state->roots.current = mmc_GC_state->roots.start + roots_index;

  return 0;
}

void walk_object(modelica_metatype p, int markType)
{
mmc_walk_top:

  /* if (debug) fprintf(stderr, "walking: %p\n", p); fflush(NULL); */

  assert(p != NULL);

  if( MMC_IS_IMMEDIATE(p) )
  {
    if (debug) fprintf(stderr, "immediate: %p\n", p); fflush(NULL);
    return;
  }
  else
  {
     mmc_uint_t hdr = MMC_GETHDR(p);
     struct mmc_header* sh = NULL;

     /* see if we should mark/unmark */
     if (markType == MMC_GC_MARK)
     {
       /* if we should mark it and is already marked, return */
       if ( MMC_HDRISMARKED(hdr) ) return;
       /* else, mark it */
       if (debug) fprintf(stderr, "casting the header\n"); fflush(NULL);
       sh = ((struct mmc_header*)MMC_UNTAGPTR(p));
       if (debug) fprintf(stderr, "marking: %p %ul\n", p, sh->header); fflush(NULL);
       sh->header = MMC_HDR_MARK(hdr);
       if (debug) fprintf(stderr, "marked: %p\n", p); fflush(NULL);
     }
     else /* we should unmark */
     {
       /* if we should unmark it and is already unmarked, return */
       if ( !MMC_HDRISMARKED(hdr) ) return;
       /* else, unmark it */
       if (debug) fprintf(stderr, "casting the header\n"); fflush(NULL);
       sh = ((struct mmc_header*)MMC_UNTAGPTR(p));
       if (debug) fprintf(stderr, "unmarking: %p %p\n", p, (void*)sh); fflush(NULL);
       sh->header = MMC_HDR_UNMARK(hdr);
       if (debug) fprintf(stderr, "unmarked: %p\n", p); fflush(NULL);
     }

     /* if is string or real, just return */
     if( MMC_HDRISSTRING(hdr) && (hdr == MMC_REALHDR) )
     {
       if (debug) fprintf(stderr, "real or string: %p\n", p); fflush(NULL);
       return;
     }

     /* if is a structure, dive in! */
     if( MMC_HDRISSTRUCT(hdr) )
     {
       mmc_uint_t slots = MMC_HDRSLOTS(hdr);
       mmc_uint_t ctor  = MMC_HDRCTOR(hdr);
       mmc_uint_t slotsMin  = 0;
       void **pp = NULL;

       if (debug) fprintf(stderr, "structure: %p\n", p); fflush(NULL);
       if (slots == 0) return;

       if (slots > 0 && ctor > 1) /* RECORD */
       {
         slotsMin = 1; /* ignore the fields slot! */
       }


       pp = MMC_STRUCTDATA(p);

       while( --slots > slotsMin )
       {
         walk_object(*pp++, markType);
       }

       p = *pp;

       /* go to the begining */
       goto mmc_walk_top;
     }
     else /* not a structure, move on! */
     {
       return ;
     }
  }
}

/* the mark phase */
int mmc_GC_collect_mark(void)
{
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

  for(p = mmc_GC_state->roots.start; p < mmc_GC_state->roots.current; p++)
  {
    walk_object(*p, MMC_GC_MARK);
  }

  return 0;
}

/* the unmark phase */
int mmc_GC_collect_unmark(void)
{
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

  for(p = mmc_GC_state->roots.start; p < mmc_GC_state->roots.current; p++)
  {
    walk_object(*p, MMC_GC_UNMARK);
  }

  return 0;
}

long get_filled_size(mmc_GC_free_slot page)
{
  mmc_List free = mmc_GC_state->free;
  long filledSize = 0, filledCurrent = 0;
  char found = 0;
  while (free != NULL)
  {
    /* see if free is within page boundaries */
    if (free->el.start >= page.start && (char*)free->el.start < (char*)page.start + page.size)
    {
      filledCurrent = (char*)free->el.start - (char*)page.start;
      filledSize = (filledSize > filledCurrent)?filledSize : filledCurrent;
      found = 1;
    }
    free = free->next;
  }

  filledSize = found?filledSize:page.size;

  return filledSize;
}

/*
 * walk page object by object and add all
 * unmarked objects region to the free list!
 */
int sweep_page(mmc_GC_free_slot page)
{
  modelica_metatype scan = page.start;
  mmc_uint_t hdr = 0, slots = 0;
  mmc_GC_free_slot freeSlot = { 0 };

  mmc_uint_t filledSize = get_filled_size(page);

  /* if this page was not filled at all, return */
  if (!filledSize)
    return 0;

  if (debug) fprintf(stderr, "sweeping page: %p, size: %ul\n", (void*)scan, filledSize); fflush(NULL);

  /* scan the page */
  while ((char*)scan < ((char*)page.start + filledSize))
  {
    if (debug) fprintf(stderr, "get obj header:\n"); fflush(NULL);
    /* get the obj header */
    hdr = ((struct mmc_header*)scan)->header;

    /* if header is 0 it means this page is not filled, break */
    slots = MMC_HDRSLOTS(hdr);

    /* if the object is marked, skip it */
    if (MMC_HDRISMARKED(hdr))
    {
      /* do nothing */
      if (debug) fprintf(stderr, "skipping marked obj: %p\n", scan); fflush(NULL);
    }
    else /* object is unmarked, add it to the free list */
    {
      /* if (debug) fprintf(stderr, "adding obj to free list: %p\n", scan); fflush(NULL); */
      /* TODO! FIXME! collect larger free regions in a slot! */
      /* construct the free slot */
      freeSlot.start = scan;
      freeSlot.size  = slots * sizeof(void*);
      /* add it to the free list */
      list_cons(&(mmc_GC_state->free), freeSlot);
    }
    /* move to next object which should be after slots + 1 (the header) */
    scan = (modelica_metatype)((mmc_uint_t)scan + (slots + 1));
  }
  return 0;
}

/* the sweep phase */
int mmc_GC_collect_sweep(void)
{
  mmc_List pages = NULL;
  mmc_GC_free_slot page = {0};

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

  pages = mmc_GC_state->pages;
  while (pages != NULL)
  {
    page = pages->el;
    sweep_page(page);
    pages = pages->next;
  }


  return 0;
}

/* do garbage collection */
int mmc_GC_collect(void)
{
  assert(mmc_GC_state != NULL);

  /* only collect we have more than 3 pages */
  if (list_length(mmc_GC_state->pages) < 2)
    return 0;

  /* collect only if mark stack top is non-zero */
  if (!mmc_GC_state->roots.marks)
    return 0;
  if (!stack_peek(mmc_GC_state->roots.marks))
    return 0;

  if (debug) fprintf(stderr, "mark\n"); fflush(NULL);
  mmc_GC_collect_mark();
  if (debug) fprintf(stderr, "sweep\n"); fflush(NULL);
  mmc_GC_collect_sweep();
  if (debug) fprintf(stderr, "unmark\n"); fflush(NULL);
  mmc_GC_collect_unmark();
  if (debug) fprintf(stderr, "collect done\n"); fflush(NULL);

  return 0;
}

/* get a region of memory of required size */
modelica_metatype allocate_from_free(mmc_GC_state_type *gc_state, unsigned nbytes)
{
  modelica_metatype p = NULL;
  mmc_List fl = NULL;
  mmc_GC_free_slot slot;

  /* search in the free list for the big enough-slot */
  fl = gc_state->free;

  assert(fl != 0);

  /* try very fast allocation first */
  if (fl->el.size > nbytes)
  {
    /* found our free region, use it! */
    p = fl->el.start;
    fl->el.start = ((char*)fl->el.start + nbytes);
    fl->el.size  = fl->el.size - nbytes;

    /* return out region */
    return p;
  }

  /* go the long way by searching the entire list! */
  while (fl != NULL)
  {
    /* we found our slot! */
    if (fl->el.size >= nbytes)
      break;
    fl = fl->next;
  }

  /* we didn't find a big enough slot, create one! */
  if (!fl)
  {
    mmc_GC_free_slot slot = {0, 0};
    /* if the required allocation size is bigger than the default page size make a new page! */
    if (nbytes > gc_state->default_page_size)
    {
      /* make a new page of big-enough size */
      slot = page_create(nbytes);
    }
    else
    {
      /* make a new page of default size */
      slot = page_create(gc_state->default_page_size);
    }

    /* add it to pages */
    gc_state->pages = pages_add(gc_state->pages, slot);
    /* add it to the free list */
    list_cons(&(gc_state->free), slot);

    /* point to it */
    fl = gc_state->free;
  }

  assert(fl != 0);

  /* remember our free slot */
  slot = fl->el;

  /* delete the slot from the free list! */
  list_delete(&(gc_state->free), fl->el);

  /* found our free region, use it! */
  p = slot.start;

  /* if the slot was NOT fully filled, return the rest to the free list! */
  if (slot.size > nbytes)
  {
    slot.start = ((char*)slot.start + nbytes);
    slot.size  = slot.size  - nbytes;
    /* add the rest to the free list! */
    list_cons(&(gc_state->free), slot);
  }

  return p;
}

#if 0

/* primary allocation routine for MetaModelica */
void *mmc_alloc_bytes(unsigned nbytes)
{
  modelica_metatype p = NULL;

  /* if GC was not setup, init it */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL);
  }

  assert(mmc_GC_state != NULL);

  p = allocate_from_free(mmc_GC_state, nbytes);

  return p;
}

#endif

void *mmc_alloc_bytes(unsigned nbytes)
{
  static char *mmc_cur_malloc_buf = NULL;
  static long mmc_cur_malloc_buf_ix=0;
  /* Until we have GC, we simply allocate in 256MB chunks... */
  const long mmc_cur_malloc_buf_sz = MMC_GC_PAGE_SIZE;
  void *p=0;
  /* fprintf(stderr, "1 mmc_alloc_bytes(%ld): %ld,%ld\n", nbytes, mmc_cur_malloc_buf, mmc_cur_malloc_buf_ix); */
  if (mmc_cur_malloc_buf == NULL || nbytes>(mmc_cur_malloc_buf_sz-mmc_cur_malloc_buf_ix)) {
    if ( (mmc_cur_malloc_buf = malloc(mmc_cur_malloc_buf_sz)) == 0 ) {
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





