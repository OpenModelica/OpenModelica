/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/* File: meta_modelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef META_MODELICA_H_
#define META_MODELICA_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include "../gc/omc_gc.h"
#include "../omc_inline.h"
#include "../openmodelica.h"
#include "meta_modelica_data.h"
#include "../util/omc_init.h"

static inline void* mmc_mk_icon(mmc_sint_t i)
{
    return MMC_IMMEDIATE(MMC_TAGFIXNUM(i));
}

union mmc_double_as_words {
    double d;
    mmc_uint_t data[2];
};

static inline double mmc_prim_get_real(void *p)
{
  union mmc_double_as_words u;
  mmc_uint_t *data = &(MMC_REALDATA(p)[0]);

  u.data[0] = *data;
  u.data[1] = *(data + 1);
  return u.d;
}

static inline void mmc_prim_set_real(struct mmc_real *p, double d)
{
  union mmc_double_as_words u;
  mmc_uint_t *data;
  u.d = d;

  data = &(p->data[0]);
  *data = u.data[0];
  *(data + 1) = u.data[1];
}

char* mmc_mk_scon_len_ret_ptr(size_t nbytes);

/* Non-varargs versions */
#include "meta_modelica_mk_box.h"

static inline void *mmc_mk_box(mmc_sint_t _slots, mmc_uint_t ctor, ...)
{
  mmc_sint_t i;
  va_list argp;

  struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(_slots+1);
  p->header = MMC_STRUCTHDR(_slots, ctor);
  va_start(argp, ctor);
  for (i = 0; i < _slots; i++) {
    p->data[i] = va_arg(argp, void*);
  }
  va_end(argp);
#ifdef MMC_MK_DEBUG
  fprintf(stderr, "BOXNN slots:%d ctor: %u\n", _slots, ctor); fflush(NULL);
#endif
  return MMC_TAGPTR(p);
}

static const MMC_DEFSTRUCT0LIT(mmc_nil,0);
static const MMC_DEFSTRUCT0LIT(mmc_none,1);

#define mmc_mk_nil() MMC_REFSTRUCTLIT(mmc_nil)
#define mmc_mk_none() MMC_REFSTRUCTLIT(mmc_none)

#define MMC_CONS_CTOR 1

static inline void *mmc_mk_cons(void *car, void *cdr)
{
    return mmc_mk_box2(MMC_CONS_CTOR, car, cdr);
}

static inline void *mmc_mk_some(void *x)
{
    return mmc_mk_box1(1, x);
}

static inline void *mmc__mk__some(void *x)
{
    return mmc_mk_some(x);
}

extern void *mmc_mk_box_arr(mmc_sint_t _slots, mmc_uint_t ctor, void** args);
static inline void *mmc_mk_box_no_assign(mmc_sint_t _slots, mmc_uint_t ctor, int is_atomic)
{
    struct mmc_struct *p = NULL;
    if (is_atomic)
    {
      p = (struct mmc_struct*)mmc_alloc_words_atomic(_slots+1);
    }
    else
    {
      p = (struct mmc_struct*)mmc_alloc_words(_slots+1);
    }
    p->header = MMC_STRUCTHDR(_slots, ctor);
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "STRUCT NO ASSIGN slots%d ctor %u\n", _slots, ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
}

extern modelica_boolean valueEq(modelica_metatype lhs,modelica_metatype rhs);
extern modelica_integer valueCompare(modelica_metatype lhs,modelica_metatype rhs);

extern modelica_integer valueHashMod(modelica_metatype p,modelica_integer mod);
extern void* boxptr_valueHashMod(threadData_t *,void *p, void *mod);

extern void mmc__unbox(modelica_metatype box, void* res);

#define mmc__uniontype__metarecord__typedef__equal(UT,CTOR,NFIELDS) (MMC_GETHDR(UT)==MMC_STRUCTHDR(NFIELDS+1,CTOR+3))

extern void debug__print(void*prefix,void*any); /* For debugging */
extern void initializeStringBuffer(void);
extern char* anyString(void*any); /* For debugging in external functions */
extern void* mmc_anyString(void*any); /* For debugging */
modelica_metatype mmc_gdb_listGet(threadData_t* threadData, modelica_metatype lst, modelica_integer i); /* For debugging */
modelica_metatype mmc_gdb_arrayGet(threadData_t* threadData, modelica_metatype arr, modelica_integer i); /* For debugging */
extern void printAny(void*any); /* For debugging */
extern void printTypeOfAny(void*any); /* For debugging */
extern char* getTypeOfAny(void*any, int inRecord); /* For debugging */
extern char* getRecordElementName(void*any, int element); /* For debugging */
extern int isOptionNone(void*any); /* For debugging */
extern void changeStdStreamBuffer(void); /* For debugging */
extern modelica_integer mmc_gdb_arrayLength(modelica_metatype arr); /* For debugging */

/* Debugging functions used by OMEdit */
typedef enum metaType
{
  record_metaType = 0,
  list_metaType,
  option_metaType,
  tuple_metaType,
  array_metaType
} metaType;

extern char* getMetaTypeElement(modelica_metatype arr, modelica_integer i, metaType mt);

/*
 * Generated (Meta)Records should access a static, constant value of
 * the record_description structure. This means the additional cost
 * of including the description is 1 word of memory and O(1) time.
 * When sending structures between the compiler and generated files,
 * the descriptions will be duplicated, and cost additional memory
 * for each and every Values.Value copied. /sjoelund 2009-05-20
 */
struct record_description {
  const char* path; /* package_record__X */
  const char* name; /* package.record_X */
  const char** fieldNames;
};

#if defined(OMC_MINIMAL_RUNTIME)
static void* mmc_mk_rcon(double d)
{
    struct mmc_real *p = (struct mmc_real*)mmc_alloc_words_atomic(MMC_SIZE_DBL/MMC_SIZE_INT + 1);
    mmc_prim_set_real(p, d);
    p->header = MMC_REALHDR;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "REAL size: %u\n", MMC_SIZE_DBL/MMC_SIZE_INT+1); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
}
static void* mmc_mk_modelica_array(base_array_t arr)
{
  base_array_t *cpy = mmc_alloc_words(sizeof(arr)/sizeof(void*) + 1);
  memcpy(cpy, &arr, sizeof(base_array_t));
  clone_base_array_spec(&arr, cpy);
  /* Note: The data is hopefully not stack-allocated and can be passed this way */
  return cpy;
}
#else
void* mmc_mk_rcon(double d);
void* mmc_mk_modelica_array(base_array_t);
#endif

#include "../openmodelica.h"
#include "meta_modelica_segv.h"
#include "meta_modelica_builtin.h"
#include "../util/omc_error.h"

#if defined(__cplusplus)
}
#endif

/* adrpo: undefine _inline for mingw32 and mingw64 */
#if defined(_inline) && (defined(__MINGW32__) || defined(__MINGW64__))
#undef _inline
#endif

#endif
