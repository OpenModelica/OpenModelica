/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */


/* The typed element allocators the array code calls; the heap itself is
   gc/omc_rc.c. */

#include "../omc_simulation_settings.h"
#define OMC_NO_GC_MAPPING
#include "omc_gc.h"
#include <string.h>

#if defined(__cplusplus)
extern "C" {
#endif

/* allocates n reals */
modelica_real* real_alloc(int n)
{
  return (modelica_real*) omc_alloc_interface.malloc_atomic(n*sizeof(modelica_real));
}

/* allocates n integers */
modelica_integer* integer_alloc(int n)
{
  return (modelica_integer*) omc_alloc_interface.malloc_atomic(n*sizeof(modelica_integer));
}

/* allocates n strings */
modelica_string* string_alloc(int n)
{
  return (modelica_string*) omc_alloc_interface.malloc(n*sizeof(modelica_string));
}

/* allocates n booleans */
modelica_boolean* boolean_alloc(int n)
{
  return (modelica_boolean*) omc_alloc_interface.malloc_atomic(n*sizeof(modelica_boolean));
}

_index_t* size_alloc(int n)
{
  return (_index_t*) omc_alloc_interface.malloc(n*sizeof(_index_t));
}

_index_t** index_alloc(int n)
{
  return (_index_t**) omc_alloc_interface.malloc(n*sizeof(_index_t*));
}

/* allocates n elements of size sze */
void* generic_alloc(int n, size_t sze)
{
  return (void*) omc_alloc_interface.malloc(n*sze);
}


#if defined(__cplusplus)
} /* end extern "C" */
#endif
