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


#include "omc_box.h"
#include "base_array.h"
#include <stdarg.h>

#if defined(__cplusplus)
extern "C" {
#endif

void* omc_box_new_n(int nfields, int ctor, ...)
{
  void **box;
  va_list ap;
  int i;

  box = (void**) omc_rc_alloc((nfields + 1) * sizeof(void*));
  box[0] = (void*) (intptr_t) ctor;
  va_start(ap, ctor);
  for (i = 1; i <= nfields; i++) {
    box[i] = va_arg(ap, void*);
  }
  va_end(ap);
  return box;
}

void* omc_mk_rcon(modelica_real r)
{
  modelica_real *p = (modelica_real*) omc_rc_alloc(sizeof(modelica_real));
  *p = r;
  return p;
}

void* omc_mk_icon(modelica_integer i)
{
  modelica_integer *p = (modelica_integer*) omc_rc_alloc(sizeof(modelica_integer));
  *p = i;
  return p;
}

void* omc_box_array(void *arr)
{
  base_array_t *p = (base_array_t*) omc_rc_alloc(sizeof(base_array_t));
  *p = *(base_array_t*) arr;
  omc_array_retain(p);
  return p;
}

#if defined(__cplusplus)
} /* end extern "C" */
#endif
