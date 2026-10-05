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


#ifndef OMC_STRING_H_
#define OMC_STRING_H_

#include "../openmodelica_types.h"
#include "../gc/omc_rc.h"
/* meta/meta_modelica_string.h defines the same names for MetaModelica. */
#if !defined(OMC_METAMODELICA_RUNTIME)

#if defined(__cplusplus)
extern "C" {
#endif

/* The simulation's String. A counted object like any other, so the reference
 * count sits in the word before it (see gc/omc_rc.h):
 *
 *     [ rc : mmc_uint_t ][ len : mmc_uint_t ][ bytes ... '\0' ]
 *
 * The pointer is untagged and the slot holds nothing but a string, so
 * retain/release need not decode it. Its own type, so a mix-up with
 * modelica_metatype is a compile error. */

struct omc_string_s {
  mmc_uint_t len;
  char data[1];   /* len bytes plus the terminator */
};

/* A literal: static, never freed, never written to. */
#define OMC_DEFSTRINGLIT(NAME,LEN,VAL) \
  struct { \
    mmc_uint_t rc; \
    mmc_uint_t len; \
    const char data[(LEN)+1]; \
  } NAME = { OMC_RC_IMMORTAL, (LEN), VAL }
#define OMC_REFSTRINGLIT(NAME) ((modelica_string) &((NAME).len))

static inline char* omc_string_data(modelica_string s)
{
  return s->data;
}

static inline mmc_uint_t omc_string_len(modelica_string s)
{
  return s->len;
}

static inline modelica_string omc_string_retain(modelica_string s)
{
  omc_rc_retain_inline(s);
  return s;
}

static inline void omc_string_release(modelica_string s)
{
  omc_rc_release_inline(s);
}

/* Uninitialised string of `len` bytes (count 1, terminator written). */
modelica_string omc_string_alloc(mmc_uint_t len);
modelica_string omc_string_new(const char *str);
modelica_string omc_string_new_len(const char *str, mmc_uint_t len);
/* Outlives the heap: used for strings handed to code that never releases. */
modelica_string omc_string_new_persist(const char *str);

/* store copies (takes its own reference), move takes over the caller's.
   Retaining before releasing is what makes s := s safe. */
static inline void omc_string_store(modelica_string *slot, modelica_string s)
{
  modelica_string old = *slot;
  omc_rc_retain_inline(s);
  *slot = s;
  omc_rc_release_inline(old);
}

static inline void omc_string_move(modelica_string *slot, modelica_string s)
{
  modelica_string old = *slot;
  *slot = s;
  if (old != s) {
    omc_rc_release_inline(old);
  }
}

/* The caller takes the reference, so the release at _return: finds nothing. */
#define omc_string_disown(X)  ((void) ((X) = NULL))

/* n slots at a time: the ring buffer of past values, which holds the same
   strings as the current step. */
void omc_string_slots_store(modelica_string *dst, const modelica_string *src, size_t n);
void omc_string_slots_release(modelica_string *slots, size_t n);

DLLDataDirection extern modelica_string omc_string_empty;
/* The 256 one-byte strings, shared and immortal. */
DLLDataDirection extern modelica_string omc_strings_len1[256];

#if defined(__cplusplus)
} /* end extern "C" */
#endif

#endif /* !OMC_METAMODELICA_RUNTIME */
#endif /* OMC_STRING_H_ */
