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
 * This file implements GC roots
 *
 * RCS: $Id: roots.c 8047 2011-03-01 10:19:49Z perost $
 *
 */

#include "modelica.h"

/* create the roots structure */
mmc_GC_roots_type roots_create(size_t default_roots_size, size_t default_roots_mark_size)
{
  mmc_GC_roots_type roots = {0, 0, 0, 0};
  size_t sz = sizeof(mmc_GC_root_type) * default_roots_size;

  roots.start = (mmc_GC_root_type*)malloc(sz);
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory (%lu) to allocate the roots array!\n", sz);
    fflush(NULL);
    assert(roots.start != 0);
  }
  /* the current index points to the start at the begining! */
  roots.current = 0;
  /* the limit points to the end of the roots array */
  roots.limit = default_roots_size;

  roots.marks            = stack_create(default_roots_mark_size);
  roots.rootsStackIndex  = 0;  /* set the stack element index to 0 */

  return roots;
}

/* realloc and increase the roots structure */
mmc_GC_roots_type roots_increase(mmc_GC_roots_type roots, size_t default_roots_size)
{
  size_t sz = (roots.limit + default_roots_size) * sizeof(mmc_GC_root_type);
  size_t current = roots.current;

  /* reallocate! */
  roots.start = (mmc_GC_root_type*)realloc(roots.start, sz);
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory (%lu) to re-allocate the roots array!\n", sz);
    fflush(NULL);
    assert(roots.start != 0);
  }

  /* the current index now points to start + current size */
  roots.current = current;
  /* the limit points to the end of the roots array */
  roots.limit   += default_roots_size;

  return roots;
}

/* realloc and decrease the roots structure */
mmc_GC_roots_type roots_decrease(mmc_GC_roots_type roots, size_t default_roots_size)
{
  size_t sz = 0;
  size_t current = roots.current;
  /*
   * do not shrink roots if roots.current is less than default_roots_size
   * and 2 * default_roots_size > roots.limits
   */
  if (roots.current < default_roots_size)
  {
    return roots;
  }
  if (roots.current * 3 < roots.limit)
  {
    sz =  roots.current * 2;
  }
  else
  {
    return roots;
  }

  /* reallocate! */
  roots.start = (mmc_GC_root_type*)realloc(roots.start, sz * sizeof(mmc_GC_root_type));
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory (%lu) to re-allocate the roots array!\n", sz * sizeof(void*));
    fflush(NULL);
    assert(roots.start != 0);
  }
  /* the current index now points to start + current size */
  roots.current = current;
  /* the limit points to the end of the roots array */
  roots.limit   = sz;

  return roots;
}



#if defined(_MMC_GC_)

/* add pointers to roots */
void mmc_GC_add_roots_fallback(modelica_metatype* p, int n, mmc_GC_local_state_type local_GC_state, const char* name)
{
  int i;
  /* init GC if is not already done
  if (!mmc_GC_state)
  {
    mmc_GC_init(mmc_GC_settings_default);
  }
  assert(mmc_GC_state != NULL);
  */

  while (mmc_GC_state->roots.current + 1 >=  mmc_GC_state->roots.limit)
  {
    /* roots are filled, realloc! */
    mmc_GC_state->roots = roots_increase(mmc_GC_state->roots, mmc_GC_state->settings.roots_size);
  }

  if (p)
  {
    /* set the pointer to current */
    mmc_GC_state->roots.start[mmc_GC_state->roots.current].start = p;
    mmc_GC_state->roots.start[mmc_GC_state->roots.current++].count = n;
  }
  /*
  if (mmc_GC_state->settings.debug)
  {
    fprintf(stderr, " %s.%s\n", local_GC_state.functionName, name);
  }
  */
}

#if 0

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

  if (mmc_GC_state->settings.debug)
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

  if (mmc_GC_state->settings.debug)
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
    if (mmc_GC_state->settings.debug)
    {
      fprintf(stderr, "stack: -- %ld %ld %s\n",
          roots_index.rootsStackIndex,
          roots_index.rootsMark,
          roots_index.functionName);
      fflush(NULL);
    }

    /* pop the marks stack */
    roots_index = stack_pop(mmc_GC_state->roots.marks);

    if (mmc_GC_state->settings.debug)
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


  if (mmc_GC_state->settings.debug)
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
  /* mmc_GC_state->roots = roots_decrease(mmc_GC_state->roots, mmc_GC_state->settings.roots_size); */
  /* decrease the stack size if we can */
  /* mmc_GC_state->roots.marks = stack_decrease(mmc_GC_state->roots.marks, mmc_GC_state->settings.roots_marks_size); */

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

  if (mmc_GC_state->settings.debug)
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
    if (mmc_GC_state->settings.debug)
    {
      fprintf(stderr, "stack: -- %ld %ld %s\n",
          roots_index.rootsStackIndex,
          roots_index.rootsMark,
          roots_index.functionName);
      fflush(NULL);
    }

    /* pop the marks stack */
    roots_index = stack_pop(mmc_GC_state->roots.marks);

    if (mmc_GC_state->settings.debug)
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


  if (mmc_GC_state->settings.debug)
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
  /* mmc_GC_state->roots = roots_decrease(mmc_GC_state->roots, mmc_GC_state->settings.roots_size); */
  /* decrease the stack size if we can */
  /* mmc_GC_state->roots.marks = stack_decrease(mmc_GC_state->roots.marks, mmc_GC_state->settings.roots_marks_size); */

  return 0;
}

#endif

#endif /* _MMC_GC_ */

