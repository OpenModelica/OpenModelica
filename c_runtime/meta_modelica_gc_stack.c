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

/* make an empty stack.  */
mmc_Stack stack_create(void)
{
  return NULL;
}

/* Return nonzero if the stack is empty.  */
int stack_empty(mmc_Stack stack)
{
  return stack == NULL;
}

/* peek stack  */
long stack_peek(mmc_Stack stack)
{
  assert (!stack_empty(stack));
  return (stack->el);
}

/* pop the stack  */
long stack_pop(mmc_Stack* stack)
{
  long top;
  mmc_Stack rest;

  assert (!stack_empty(*stack));
  top = (*stack)->el;
  rest = (*stack)->next;
  free (*stack);
  *stack = rest;
  return top;
}

/* push stack */
void stack_push(mmc_Stack* stack, long el)
{
  mmc_Stack newStack = (mmc_Stack) malloc (sizeof (struct mmc_StackElement));

  assert(newStack != NULL);

  newStack->el = el;
  newStack->next = *stack;
  *stack = newStack;
}

/* delete stack */
void stack_clear(mmc_Stack* stack)
{
  while (!stack_empty (*stack)) {
    stack_pop(stack);
  }
  stack = NULL;
}

