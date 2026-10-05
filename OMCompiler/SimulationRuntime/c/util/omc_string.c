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


#include "omc_string.h"
#include "../gc/omc_gc.h"
#include <string.h>

#if defined(__cplusplus)
extern "C" {
#endif

modelica_string omc_string_alloc(mmc_uint_t len)
{
  modelica_string s;

  if (len == 0) {
    return omc_string_empty;
  }
  s = (modelica_string) omc_rc_alloc(sizeof(mmc_uint_t) + len + 1);
  s->len = len;
  s->data[len] = '\0';
  return s;
}

modelica_string omc_string_new_len(const char *str, mmc_uint_t len)
{
  modelica_string s;

  if (len == 0) {
    return omc_string_empty;
  }
  s = omc_string_alloc(len);
  memcpy(s->data, str, len);
  return s;
}

modelica_string omc_string_new(const char *str)
{
  return omc_string_new_len(str, (mmc_uint_t) strlen(str));
}

modelica_string omc_string_new_persist(const char *str)
{
  size_t len = strlen(str);
  modelica_string s;

  if (len == 0) {
    return omc_string_empty;
  }
  s = (modelica_string) omc_alloc_interface.malloc_string_persist(sizeof(mmc_uint_t) * 2 + len + 1);
  s = (modelica_string) (((mmc_uint_t*) s) + 1);
  *omc_rc_hdr(s) = OMC_RC_IMMORTAL;
  s->len = (mmc_uint_t) len;
  memcpy(s->data, str, len + 1);
  return s;
}

void omc_string_slots_store(modelica_string *dst, const modelica_string *src, size_t n)
{
  size_t i;

  for (i = 0; i < n; i++) {
    omc_string_store(dst + i, src[i]);
  }
}

void omc_string_slots_release(modelica_string *slots, size_t n)
{
  size_t i;

  for (i = 0; i < n; i++) {
    omc_rc_release_inline(slots[i]);
    slots[i] = NULL;
  }
}

#if defined(__cplusplus)
} /* end extern "C" */
#endif
