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

/* make an empty stack */
mmc_Stack_type* stack_create(size_t default_stack_size)
{
  mmc_Stack_type* stack = (mmc_Stack_type*)malloc(sizeof(mmc_Stack_type));
  stack->start = (mmc_GC_local_state_type*)malloc(sizeof(mmc_GC_local_state_type)*MMC_GC_ROOTS_MARKS_SIZE_INITIAL);
  assert(stack->start != NULL);
  stack->current = 0;
  stack->limit = MMC_GC_ROOTS_MARKS_SIZE_INITIAL;
  return stack;
}

/* check if stack is empty, nonzero */
int stack_empty(mmc_Stack_type* stack)
{
  return (!stack->current);
}

/* peek stack  */
mmc_GC_local_state_type stack_peek(mmc_Stack_type* stack)
{
  return stack->start[stack->current];
}

/* pop the stack */
mmc_GC_local_state_type stack_pop(mmc_Stack_type* stack)
{
  assert(stack->current > 0);
  return stack->start[stack->current--];
}

/* push stack */
mmc_Stack_type* stack_push(mmc_Stack_type* stack, mmc_GC_local_state_type el)
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
mmc_Stack_type* stack_clear(mmc_Stack_type* stack)
{
  free(stack->start);
  stack->start = NULL;
  stack->limit = 0;
  stack->current = 0;
  return stack;
}

/* realloc and decrease the stack structure */
mmc_Stack_type* stack_decrease(mmc_Stack_type* stack, size_t default_stack_size)
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


