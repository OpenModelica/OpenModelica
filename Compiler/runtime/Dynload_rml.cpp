/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#if defined(_MSC_VER)
 #define WIN32_LEAN_AND_MEAN
 #include <Windows.h>
#endif

extern "C" {

#include "rml.h"
#include "Absyn.h"
#include "Values.h"
#define UNBOX_OFFSET 0

}

#include "Dynload.cpp"

extern "C" {

void DynLoad_5finit(void)
{
}

RML_BEGIN_LABEL(DynLoad__executeFunction)
{
  modelica_integer funcIndex = RML_UNTAGFIXNUM(rmlA0);
  modelica_ptr_t func = NULL;
  /* modelica_ptr_t lib = NULL; */
  int retval = -1;
  void *retarg = NULL;
  func = lookup_ptr(funcIndex);
  if (func == NULL)
    RML_TAILCALLK(rmlFC);

  /* lib = lookup_ptr(func->data.func.lib); */
  /* fprintf(stderr, "CALL FUNCTION LIB \n"); */
  /* index[%d]/count[%d]/handle[%ul].\n", (lib-ptr_vector),((modelica_ptr_t)(lib-ptr_vector))->cnt, lib->data.lib); fflush(stderr); */

  retval = execute_function(rmlA1, &retarg, func->data.func.handle);
  if (retval) {
    RML_TAILCALLK(rmlFC);
  } else {
    if (retarg)
      rmlA0 = retarg;
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

}
