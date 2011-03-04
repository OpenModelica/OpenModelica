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

#ifndef META_MODELICA_GC_STACK_H_
#define META_MODELICA_GC_STACK_H_

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* A stack as a linked list. */
struct mmc_StackElement
{
  long        el;
  struct mmc_StackElement* next;
};

typedef struct mmc_StackElement* mmc_Stack;

/* make an empty stack */
mmc_Stack stack_create(void);
/* check if stack is empty, nonzero */
int stack_empty(mmc_Stack stack);
/* peek stack  */
long stack_peek(mmc_Stack stack);
/* pop the stack */
long stack_pop(mmc_Stack* stack);
/* push stack */
void stack_push(mmc_Stack* stack, long el);
/* delete stack */
void stack_clear(mmc_Stack* stack);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_STACK_H_ */

