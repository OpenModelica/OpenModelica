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

#define MMC_GC_ROOTS_MARKS_SIZE_INITIAL 8*1024  /* initial size of roots, reallocate on full */

struct mmc_GC_local_state_type /* the structure of local GC state that is saved on stack */
{
  const char* functionName; /* the function name */
  size_t rootsMark;         /* the roots mark */
  size_t rootsStackIndex;   /* the index in the mark stack (basically the depth) */
};
typedef struct mmc_GC_local_state_type mmc_GC_local_state_type;

/* A stack as an array. */
struct mmc_Stack_type
{
  mmc_GC_local_state_type  *start; /* the stack array of marks */
  size_t                   current; /* the current limit */
  size_t                   limit;   /* the limit of roots */
};

typedef struct mmc_Stack_type  mmc_Stack_type;

/* make an empty stack */
mmc_Stack_type* stack_create(size_t default_stack_size);
/* check if stack is empty, nonzero */
int stack_empty(mmc_Stack_type* stack);
/* peek stack  */
mmc_GC_local_state_type stack_peek(mmc_Stack_type* stack);
/* pop the stack */
mmc_GC_local_state_type stack_pop(mmc_Stack_type* stack);
/* push stack */
mmc_Stack_type* stack_push(mmc_Stack_type* stack, mmc_GC_local_state_type el);
/* stack decrease */
mmc_Stack_type* stack_decrease(mmc_Stack_type* stack, size_t default_stack_size);
/* delete stack */
mmc_Stack_type* stack_clear(mmc_Stack_type* stack);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_STACK_H_ */

