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

#if !defined(_MMC_GC_)

/* primary allocation routine for MetaModelica */
void *mmc_alloc_words(unsigned nwords)
{
  return mmc_alloc_bytes(nwords * sizeof(void*));
}

void *mmc_alloc_bytes(unsigned nbytes)
{
  static char *mmc_cur_malloc_buf = NULL;
  static long mmc_cur_malloc_buf_ix=0;
  /* Until we have GC, we simply allocate in 256MB chunks... */
  const long mmc_cur_malloc_buf_sz = (MMC_GC_PAGE_SIZE<nbytes)?(nbytes+MMC_GC_PAGE_SIZE):(MMC_GC_PAGE_SIZE);
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

static mmc_GC_state_type x_mmc_GC_state;
mmc_GC_state_type *mmc_GC_state = &mmc_GC_state;

int mmc_GC_init(int nr_mark_threads, int nr_sweep_threads, size_t default_page_size, int default_number_of_pages, size_t default_roots_size, size_t default_roots_marks_size)
{
  return 0;
}

int mmc_GC_init_default(void)
{
  return 0;
}

int mmc_GC_clear(void)
{
  return 0;
}

int mmc_GC_add_root(modelica_metatype* p, mmc_GC_local_state_type local_GC_state, const char* name)
{
  return 0;
}

mmc_GC_local_state_type mmc_GC_save_roots_state(const char* name)
{
  mmc_GC_local_state_type local_GC_state = {0, 0};
  return local_GC_state;
}

int mmc_GC_undo_roots_state(mmc_GC_local_state_type local_GC_state)
{
  return 0;
}

int mmc_GC_unwind_roots_state(mmc_GC_local_state_type local_GC_state)
{
  return 0;
}

int mmc_GC_collect(mmc_GC_local_state_type local_GC_state)
{
  return 0;
}

#else /* normal GC */

mmc_GC_state_type *mmc_GC_state = NULL;

char debug = 0;

int is_inside_page(modelica_metatype p);
int is_in_free(modelica_metatype p);

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
int mmc_GC_init(int nr_mark_threads, int nr_sweep_threads, size_t default_page_size, int default_number_of_pages, size_t default_roots_size, size_t default_roots_marks_size)
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
  mmc_GC_state->default_number_of_mark_threads  = nr_mark_threads;
  mmc_GC_state->default_number_of_sweep_threads = nr_sweep_threads;
  mmc_GC_state->default_number_of_pages = default_number_of_pages;
  mmc_GC_state->default_page_size = default_page_size;
  mmc_GC_state->default_roots_size = default_roots_size;
  mmc_GC_state->default_roots_marks_size = default_roots_marks_size;
  mmc_GC_state->pages = pages_create(default_page_size, default_number_of_pages);
  mmc_GC_state->roots = roots_create(default_roots_size, default_roots_marks_size);
  mmc_GC_state->free = list_clone(mmc_GC_state->pages); /* initially the free list is the list of pages! */
  mmc_GC_state->stats = stats_create();
  /* at the beginning all allocation is free */
  mmc_GC_state->totalPageSize = default_page_size * default_number_of_pages;
  mmc_GC_state->totalFreeSize = default_page_size * default_number_of_pages;
  assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);
  for (i=0; i < 1024; i++)
  {
    mmc_GC_state->global_roots[i] = 0;
  }

  return 0;
  }
}

int mmc_GC_init_default(void)
{
  mmc_GC_init(
    MMC_GC_NUMBER_OF_MARK_THREADS,
    MMC_GC_NUMBER_OF_SWEEP_THREADS,
    MMC_GC_PAGE_SIZE,
    MMC_GC_NUMBER_OF_PAGES,
    MMC_GC_ROOTS_SIZE_INITIAL,
    MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
}

int mmc_GC_clear(void)
{
  /* already done the GC clear */
  if (!mmc_GC_state) return 0;

  {
  mmc_List lst = NULL;
  if (debug) { fprintf(stderr, "mmc_GC_clear!\n"); fflush(NULL); }

  /* delete the GC state structures */
  lst = mmc_GC_state->pages;
  while (lst != NULL)
  {
    free(lst->el.start);
    lst = lst->next;
  }
  list_clear(&mmc_GC_state->free);
  free(mmc_GC_state->roots.marks->start);
  free(mmc_GC_state->roots.marks);
  free(mmc_GC_state->roots.start);
  free(mmc_GC_state);
  mmc_GC_state = NULL;

  return 0;
  }
}

/* add pointers to roots */
int mmc_GC_add_root(modelica_metatype* p, mmc_GC_local_state_type local_GC_state, const char* name)
{
  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL,
      MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
  }

  assert(mmc_GC_state != NULL);

  if (mmc_GC_state->roots.current + 1 >=  mmc_GC_state->roots.limit)
  {
    /* roots are filled, realloc! */
    mmc_GC_state->roots = roots_increase(mmc_GC_state->roots, mmc_GC_state->default_roots_size);
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
      /* set the pointer to current */
      mmc_GC_state->roots.start[mmc_GC_state->roots.current] = p;
      if (debug)
      {
        fprintf(stderr, "root: ADDED  %ld %p *%p ->", mmc_GC_state->roots.current, p, *p); fflush(NULL);
      }
      /* increase the current */
      mmc_GC_state->roots.current++;
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
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL,
      MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
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
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL,
      MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
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
  mmc_GC_state->roots = roots_decrease(mmc_GC_state->roots, mmc_GC_state->default_roots_size);
  /* decrease the stack size if we can */
  mmc_GC_state->roots.marks = stack_decrease(mmc_GC_state->roots.marks, mmc_GC_state->default_roots_marks_size);

  return 0;

}


/* remove the current roots mark */
int mmc_GC_undo_roots_state(mmc_GC_local_state_type local_GC_state)
{
  mmc_GC_local_state_type roots_index = {0, 0, 0};

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL,
      MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
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
  mmc_GC_state->roots = roots_decrease(mmc_GC_state->roots, mmc_GC_state->default_roots_size);
  /* decrease the stack size if we can */
  mmc_GC_state->roots.marks = stack_decrease(mmc_GC_state->roots.marks, mmc_GC_state->default_roots_marks_size);

  return 0;
}

int is_inside_page(modelica_metatype p)
{
  mmc_List lst = mmc_GC_state->pages;
  int isInside = 0;
  size_t diff = 0;

  while (lst != NULL)
  {
    diff = (char*)MMC_UNTAGPTR(p) - (char*)lst->el.start;
    if (diff >=0 && diff <= lst->el.size)
    {
      isInside = 1;
      break;
    }
    lst = lst->next;
  }
  return isInside;
}

void walk_object(modelica_metatype p)
{
mmc_walk_top:

  /* if (debug) fprintf(stderr, "walking: %p\n", p); fflush(NULL); */

  assert(p != NULL);

  if( MMC_IS_IMMEDIATE(p) )
  {
    //if (debug) fprintf(stderr, "immediate: %p\n", p); fflush(NULL);
    return;
  }
  else
  {
    if (!is_inside_page(p)) /* do not mark/unmark outside pages, but dive in! */
    {
      return;
    }
    mmc_uint_t hdr = MMC_GETHDR(p);
    struct mmc_header* sh = NULL;

    if (MMC_HDR_UNMARK(hdr) == MMC_NILHDR) /* do not mark nil! */
      return;
    if (MMC_HDR_UNMARK(hdr) == MMC_STRUCTHDR(0,1)) /* do not mark none! */
      return;

    /* if we should mark it and is already marked, return */
    if ( MMC_HDRISMARKED(hdr) ) return;
    /* else, mark it */
    //if (debug) fprintf(stderr, "casting the header\n"); fflush(NULL);
    sh = ((struct mmc_header*)MMC_UNTAGPTR(p));
    //if (debug) fprintf(stderr, "marking: %p %ul\n", p, sh->header); fflush(NULL);
    sh->header = MMC_HDR_MARK(hdr);
    //if (debug) fprintf(stderr, "marked: %p\n", p); fflush(NULL);

    /* if is string or real, just return */
    if( MMC_HDRISSTRING(MMC_HDR_UNMARK(hdr)) || (MMC_HDR_UNMARK(hdr) == MMC_REALHDR) )
    {
      //if (debug) fprintf(stderr, "real or string: %p\n", p); fflush(NULL);
      return;
    }

    /* if is a structure, dive in! */
    if( MMC_HDRISSTRUCT(MMC_HDR_UNMARK(hdr)) )
    {
      mmc_uint_t slots = MMC_HDRSLOTS(MMC_HDR_UNMARK(hdr));
      mmc_uint_t ctor  = MMC_HDRCTOR(MMC_HDR_UNMARK(hdr));
      mmc_uint_t slotsMin  = 0, index = 0;
      void **pp = NULL;

      //if (debug) fprintf(stderr, "structure: %p\n", p); fflush(NULL);
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
          //goto mmc_walk_top;
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
      int a=0,b=0,c=0;
      if (debug)
      {
        fprintf(stderr, "marking object: %ld %p *%p ->", index, p, *p); fflush(NULL);
        //printAny(*p);
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
      //printAny(mmc_GC_state->global_roots[index]);
      if (debug) { fprintf(stderr, "\n"); fflush(NULL); }

      /* assert(is_in_free(*p) == 0); */

      walk_object(*p);
    }
  }

  return 0;
}

size_t get_filled_size(mmc_GC_free_slot page)
{
  mmc_List free = mmc_GC_state->free;
  size_t filledSize = 0, filledCurrent = 0;
  char found = 0;
  while (free != NULL)
  {
    /* see if free is within page boundaries */
    if ((free->el.start >= page.start) && ((char*)free->el.start < (char*)page.start + page.size))
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

int is_in_free(modelica_metatype p)
{
  mmc_List lst = mmc_GC_state->free;
  while (lst != NULL)
  {
    if ((char*)MMC_UNTAGPTR(p) >= (char*)lst->el.start && ((char*)p <= (char*)lst->el.start + lst->el.size))
    {
      if (debug) fprintf(stderr, "FATAL: object: %p is inside free slot: %p size:%ld\n", p, lst->el.start, lst->el.size); fflush(NULL);
      return 1;
    }
    lst = lst->next;
  }
  return 0;
}

inline mmc_GC_free_slot* join_slots(mmc_GC_free_slot slot)
{
  mmc_List lst = mmc_GC_state->free;
  while (lst != NULL)
  {
    /* our slot follows another free slot */
    if ((char*)lst->el.start + lst->el.size == (char*)slot.start)
    {
      lst->el.size += slot.size;
      return &lst->el;
    }
    /* our slot is followed by another free slot */
    if ((char*)slot.start + slot.size == (char*)lst->el.start)
    {
      lst->el.start = slot.start;
      lst->el.size += slot.size;
      return &lst->el;
    }
    lst = lst->next;
  }
  return NULL;
}

/*
 * walk page object by object and add all
 * unmarked objects region to the free list!
 */
int sweep_page(mmc_GC_free_slot page)
{
  modelica_metatype scan = page.start;
  mmc_uint_t hdr = 0, slots = 0, ctor = 0, sz = 0;
  mmc_GC_free_slot freeSlot = { 0, 0 };

  /*
  mmc_uint_t filledSize = get_filled_size(page);
  */

  /* if this page was not filled at all, return
  if (!filledSize)
    return 0;

  if (debug) fprintf(stderr, "sweeping page: %p, filled: %u\n", (void*)scan, filledSize); fflush(NULL);
  */

  /* scan the page */
  while ((char*)scan < ((char*)page.start + page.size))
  {
    /* get the obj header */
    hdr = ((struct mmc_header*)scan)->header;
    slots = MMC_HDRSLOTS(MMC_HDR_UNMARK(hdr));
    ctor  = MMC_HDRCTOR(MMC_HDR_UNMARK(hdr));
    
    /* skip fre objects! */
    if (ctor == MMC_FREE_OBJECT_CTOR)
    {
      sz = slots * sizeof(void*);
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
        fprintf(stderr, "adding obj to free list: %p ", scan); fflush(NULL);
        //printAny(MMC_TAGPTR(scan));
        //fprintf(stderr, "\n");
      }

      /* if (debug) fprintf(stderr, "adding obj to free list: %p\n", scan); fflush(NULL); */
      /* TODO! FIXME! collect larger free regions in a slot! */
      /* construct the free slot */
      freeSlot.start = scan;
      freeSlot.size  = (slots + 1) * sizeof(void*); /* header + slots */
      
      assert(mmc_GC_state->free != NULL);

      /* add it to the free list */
      if (mmc_GC_state->free)
      {
        mmc_GC_free_slot fs = mmc_GC_state->free->el;
        /* if the slot in the list is continued by the free slot, coalesce! */
        if (((char*)fs.start + fs.size) == freeSlot.start)
        {
          mmc_GC_state->free->el.size = mmc_GC_state->free->el.size + freeSlot.size;
          assert(page.size >= mmc_GC_state->free->el.size);
          
          if (debug)
          {
            fprintf(stderr, "add freeing memory: %p, size:%ld total: %p, size:%ld\n", freeSlot.start, freeSlot.size, mmc_GC_state->free->el.start, mmc_GC_state->free->el.size);
            //printAny(MMC_TAGPTR(scan));
            //fprintf(stderr, "\n");
            fflush(NULL);
          }

          /* memset(mmc_GC_state->free->el.start, 0, mmc_GC_state->free->el.size); */
          MMC_TAG_AS_FREE_OBJECT(mmc_GC_state->free->el.start, (mmc_uint_t)mmc_GC_state->free->el.size);
        }
        else /* search for a free slot that is before/after this slot */
        {
          assert(page.size >= freeSlot.size);
          /* update the total sizes before trying to join! */
          mmc_GC_state->totalFreeSize += freeSlot.size;
          assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);
          
          list_cons(&(mmc_GC_state->free), freeSlot);

          if (debug)
          {
            fprintf(stderr, "freeing memory: %p, size:%ld\n", freeSlot.start, freeSlot.size);
            //printAny(MMC_TAGPTR(scan));
            //fprintf(stderr, "\n");
            //fflush(NULL);
          }

          /* memset(freeSlot.start, 0, freeSlot.size); */
          MMC_TAG_AS_FREE_OBJECT(freeSlot.start, (mmc_uint_t)freeSlot.size);

          if (debug) 
          {
            fprintf(stderr, "slots: %u\n", MMC_HDRSLOTS(((struct mmc_header*)freeSlot.start)->header));
            fflush(NULL);
          }
        }
      }
    }
    /* move to next object which should be after slots + 1 (the header) */
    scan = (void*)((char*)scan + (slots + 1)*sizeof(void*));
  }
  return 0;
}

/* the sweep phase */
int mmc_GC_collect_sweep(void)
{
  mmc_List pages = NULL;
  mmc_GC_free_slot page = {0};

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL,
      MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
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

  pages = mmc_GC_state->pages;
  while (pages != NULL)
  {
    page = pages->el;
    sweep_page(page);
    pages = pages->next;
  }

  return 0;
}

size_t get_total_size(mmc_List lst)
{
  size_t sz = 0;
  mmc_List p = lst;

  while (p != NULL)
  {
    sz += p->el.size;
    p = p->next;
  }
  return sz;
}

int compare (const void* a, const void* b)
{
  return ( (char*)((mmc_GC_free_slot*)a)->start - (char*)((mmc_GC_free_slot*)b)->start );
}

/* try to join all possible slots in the list! */
mmc_List free_list_compact(mmc_List lst)
{
  size_t len = list_length(lst), i = 0;
  mmc_List keep = NULL, newLst = NULL;
  mmc_GC_free_slot* freeArray = (mmc_GC_free_slot*)malloc(len * sizeof(mmc_GC_free_slot));
  if (!freeArray)
  {
    /* we could not allocate the array, just return the current list */
    return lst;
  }
  /* push the list in the array! */
  while (lst != NULL)
  {
    freeArray[i++] = lst->el;
    keep = lst;
    lst = lst->next;
    free(keep);
  }
  /* sort the array in the order of addresses */
  qsort (freeArray, len, sizeof(mmc_GC_free_slot), compare);
  /* create the new list */
  newLst = list_create();
  list_cons(&newLst, freeArray[0]);
  i = 1;
  while (i < len)
  {
    mmc_GC_free_slot el = freeArray[i];
    if ((char*)newLst->el.start + newLst->el.size == el.start)
    {
      newLst->el.size += el.size;
      MMC_TAG_AS_FREE_OBJECT(newLst->el.start, (mmc_uint_t)newLst->el.size);
    }
    else /* add it to the start of the list */
    {
      list_cons(&newLst, el);
    }
    i++;
  }
  
  free(freeArray);
  
  return newLst;
}

/* do garbage collection */
int mmc_GC_collect(mmc_GC_local_state_type local_GC_state)
{
  size_t sizeFree = 0, sizePages = 0, saved;

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL,
      MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
  }

  assert(mmc_GC_state != NULL);

  sizePages = mmc_GC_state->totalPageSize;
  sizeFree = mmc_GC_state->totalFreeSize;
  saved = sizeFree;
  assert(sizeFree <= sizePages);

  /* only collect if sizeof free is 5% sizeof pages */
  if ((double)sizeFree * 4 > mmc_GC_state->default_page_size)
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

  mmc_GC_state->free = free_list_compact(mmc_GC_state->free);

  if (sizeFree - saved)
  {
    fprintf(stderr, "GC collect: free: %4.2gMb pages: %4.2gMb freed: %.3g%% freed: 4.4%gMb  lst: %d p: %d s: %lu r:%lu [%s]\n",
        (double)sizeFree/(1024.0*1024.0),
        (double)sizePages/(1024.0*1024.0),
        (double)sizeFree*100.0/(double)sizePages,
        (double)(sizeFree-saved)/(1024.0*1024.0),
        list_length(mmc_GC_state->free),
        list_length(mmc_GC_state->pages),
        mmc_GC_state->roots.rootsStackIndex,
        mmc_GC_state->roots.current,
        local_GC_state.functionName);
  }

  /* if after the collect we still have less than half a page add a new page to speed things up */
  if (((double)sizeFree * 4 <= mmc_GC_state->default_page_size) || 
      ((sizeFree-saved) * 4 <= mmc_GC_state->default_page_size))
  {
    mmc_GC_free_slot page = page_create(mmc_GC_state->default_page_size);

    MMC_TAG_AS_FREE_OBJECT(page.start, (mmc_uint_t)page.size);

    /* add it to pages */
    list_cons(&(mmc_GC_state->free), page);
    pages_add(&mmc_GC_state->pages, page);

    /* update the total sizes! */
    mmc_GC_state->totalPageSize += mmc_GC_state->default_page_size;
    mmc_GC_state->totalFreeSize += mmc_GC_state->default_page_size;
  }

  return 0;
}

/* get a region of memory of required size */
modelica_metatype allocate_from_free(unsigned nbytes)
{
  modelica_metatype p = NULL;
  mmc_List fl = NULL, prev = NULL;
  mmc_GC_free_slot slot;

  /* search in the free list for the big enough-slot */
  fl = mmc_GC_state->free;

  assert(fl != 0);

  /* try very fast allocation first */
  if (fl->el.size > nbytes)
  {
    /* found our free region, use it! */
    p = fl->el.start;
    fl->el.start = ((char*)fl->el.start + nbytes);
    fl->el.size  = fl->el.size - nbytes;

    MMC_TAG_AS_FREE_OBJECT(fl->el.start, (mmc_uint_t)fl->el.size);

    /* update the total sizes! */
    mmc_GC_state->totalFreeSize -= (size_t)nbytes;
    assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);

    /* return out region */
    return p;
  }

  /* go the long way by searching the entire list! */
  while (fl != NULL)
  {
    /* we found our slot! */
    if (fl->el.size >= nbytes)
      break;
    prev = fl;
    fl = fl->next;
  }

  /* we didn't find a big enough slot, create one! */
  if (!fl)
  {
    mmc_GC_free_slot slot = {0, 0};
    /* if the required allocation size is bigger than the default page size make a new page! */
    if (nbytes > mmc_GC_state->default_page_size)
    {
      /* make a new page of big-enough size */
      slot = page_create(nbytes + mmc_GC_state->default_page_size);
      /* update the total sizes! */
      mmc_GC_state->totalPageSize += nbytes + mmc_GC_state->default_page_size;
      mmc_GC_state->totalFreeSize += nbytes + mmc_GC_state->default_page_size;
      assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);
    }
    else
    {
      /* make a new page of default size */
      slot = page_create(mmc_GC_state->default_page_size);

      /* update the total sizes! */
      mmc_GC_state->totalPageSize += mmc_GC_state->default_page_size;
      mmc_GC_state->totalFreeSize += mmc_GC_state->default_page_size;
      assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);
    }

    /* add it to pages */
    pages_add(&mmc_GC_state->pages, slot);
    if (debug) fprintf(stderr, "added new page starting %p size: %ld\n", slot.start, slot.size); fflush(NULL);
    /* add it to the free list */
    list_cons(&(mmc_GC_state->free), slot);

    /* point to it */
    fl = mmc_GC_state->free;
    prev = NULL;
  }

  assert(fl != 0);

  /* remember our free slot */
  slot = fl->el;

  /* found our free region, use it! */
  p = slot.start;

  /* if the slot was NOT fully filled, return the rest to the free list! */
  if (slot.size > nbytes)
  {
    slot.start = ((char*)slot.start + nbytes);
    slot.size  = slot.size - nbytes;
    
    MMC_TAG_AS_FREE_OBJECT(slot.start, (mmc_uint_t)slot.size);

    /* update the total sizes! */
    mmc_GC_state->totalFreeSize -= (size_t)nbytes;
    assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);
    
    /* store the rest in the free list! */
    fl->el =  slot;
  }
  else if (slot.size == nbytes) /* no more info in this free slot, delete it */
  {
      list_delete_pointer(&(mmc_GC_state->free), fl, prev);

      /* update the total sizes! */
      mmc_GC_state->totalFreeSize -= (size_t)nbytes;
      assert(mmc_GC_state->totalFreeSize <= mmc_GC_state->totalPageSize);
  }

  return p;
}

void *mmc_alloc_bytes(unsigned nbytes)
{
  modelica_metatype p = NULL;

  /* init GC if is not already done */
  if (!mmc_GC_state)
  {
    mmc_GC_init(
      MMC_GC_NUMBER_OF_MARK_THREADS,
      MMC_GC_NUMBER_OF_SWEEP_THREADS,
      MMC_GC_PAGE_SIZE,
      MMC_GC_NUMBER_OF_PAGES,
      MMC_GC_ROOTS_SIZE_INITIAL,
      MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
  }

  assert(mmc_GC_state != NULL);

  p = allocate_from_free(nbytes);

  if (debug) 
  {
    fprintf(stderr, "alloc obj: %p, tag:%p size:%lu\n", p, MMC_TAGPTR(p), nbytes); 
    fflush(NULL);
  }

  return p;
}

#endif /* NORMAL GC */

