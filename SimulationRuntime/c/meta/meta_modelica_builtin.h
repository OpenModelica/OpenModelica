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

/* File: meta_modelica_builtin.h
 * Description: This is the C header file for the new builtin
 * functions existing in MetaModelica.
 */

#ifndef META_MODELICA_BUILTIN_H_
#define META_MODELICA_BUILTIN_H_

#include "openmodelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

#include "meta_modelica_builtin_boxptr.h"

typedef modelica_metatype metamodelica_string;
typedef const modelica_metatype metamodelica_string_const;

extern metamodelica_string intString(modelica_integer);
extern modelica_metatype boxptr_intMax(threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_intMin(threadData_t*,modelica_metatype,modelica_metatype);

/* String Character Conversion */

#define stringCharInt(X) mmc_unbox_integer(boxptr_stringCharInt(threadData,X))
#define intStringChar(X) boxptr_intStringChar(threadData,mmc_mk_icon(X))
extern modelica_metatype boxptr_stringCharInt(threadData_t*,metamodelica_string i);
extern metamodelica_string boxptr_intStringChar(threadData_t*,modelica_metatype ix);

/* String Operations */
#define stringInt(X) mmc_unbox_integer(boxptr_stringInt(threadData,X))
extern modelica_metatype boxptr_stringInt(threadData_t*,metamodelica_string s);
#define stringReal(X) mmc_unbox_real(boxptr_stringReal(threadData,X))
extern modelica_metatype boxptr_stringReal(threadData_t*,metamodelica_string s);
extern modelica_metatype stringListStringChar(metamodelica_string s);
#define stringAppend(X,Y) boxptr_stringAppend(NULL,X,Y)
extern metamodelica_string stringAppendList(modelica_metatype lst);
extern metamodelica_string boxptr_stringDelimitList(threadData_t*,modelica_metatype lst,metamodelica_string_const delimiter);
#define stringDelimitList(X,Y) boxptr_stringDelimitList(NULL,X,Y)
#define stringLength(x) MMC_STRLEN(x)
extern modelica_integer mmc_stringCompare(const void * str1,const void * str2);
#define stringGetStringChar(X,Y) boxptr_stringGetStringChar(threadData,X,mmc_mk_icon(Y))
extern metamodelica_string boxptr_stringGetStringChar(threadData_t*,metamodelica_string str,modelica_metatype ix);
#define stringGet(X,Y) mmc_unbox_integer(boxptr_stringGet(threadData,X,mmc_mk_icon(Y)))
extern modelica_metatype boxptr_stringGet(threadData_t*,metamodelica_string str,modelica_metatype ix);
#define stringGetNoBoundsChecking(str,ix) MMC_STRINGDATA((str))[(ix)-1]
#define stringUpdateStringChar(X,Y,Z) boxptr_stringUpdateStringChar(threadData,X,Y,mmc_mk_icon(Z))
extern metamodelica_string boxptr_stringUpdateStringChar(threadData_t *,metamodelica_string str, metamodelica_string c, modelica_metatype ix);
extern modelica_integer stringHash(metamodelica_string_const);
extern modelica_integer stringHashDjb2(metamodelica_string_const s);
extern modelica_integer stringHashDjb2Mod(metamodelica_string_const s,modelica_integer mod);
extern modelica_integer stringHashSdbm(metamodelica_string_const str);
#define substring(X,Y,Z) boxptr_substring(threadData,X,mmc_mk_icon(Y),mmc_mk_icon(Z))
extern metamodelica_string boxptr_substring(threadData_t *,metamodelica_string_const str, modelica_metatype start, modelica_metatype stop);

#define System_stringHashDjb2Mod stringHashDjb2Mod
#define boxptr_System_stringHashDjb2Mod boxptr_stringHashDjb2Mod

extern modelica_metatype boxptr_stringEq(threadData_t*,modelica_metatype a, modelica_metatype b);
#define boxptr_stringEqual boxptr_stringEq
extern metamodelica_string_const boxptr_stringAppend(threadData_t*,metamodelica_string_const s1,metamodelica_string_const s2);
extern modelica_metatype boxptr_stringHash(threadData_t*,modelica_metatype str);
extern modelica_metatype boxptr_stringHashDjb2(threadData_t*,modelica_metatype str);
extern modelica_metatype boxptr_stringHashDjb2Mod(threadData_t*,modelica_metatype v,modelica_metatype mod);
extern modelica_metatype boxptr_stringHashSdmb(threadData_t*,modelica_metatype str);

/* List Operations */
#define listReverse(X) boxptr_listReverse(NULL,X)
#define listReverseInPlace(X) boxptr_listReverseInPlace(NULL,X)
#define listMember(X,Y) mmc_unbox_integer(boxptr_listMember(NULL,X,Y))
#define listAppend(X,Y) boxptr_listAppend(NULL,X,Y)
extern modelica_integer listLength(modelica_metatype);
#define listGet(X,Y) boxptr_listGet(threadData,X,mmc_mk_icon(Y))
#define listEmpty(LST) MMC_NILTEST(LST)
#define listDelete(X,Y) boxptr_listDelete(threadData,X,mmc_mk_icon(Y))
#define listRest(X) MMC_CDR(X)
#define listFirst(X) MMC_CAR(X)

extern modelica_metatype boxptr_listNth(threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listGet(threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listDelete(threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listAppend(threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listFirst(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listRest(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listReverse(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listReverseInPlace(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listMember(threadData_t*,modelica_metatype, modelica_metatype);

/* Option Operations */
#define optionNone(x) (0==MMC_HDRSLOTS(MMC_GETHDR(x)) ? 1 : 0)

/* Array Operations */
extern modelica_integer arrayLength(modelica_metatype);
#define listArray(X) boxptr_listArray(NULL,X)
#define arrayList(X) boxptr_arrayList(NULL,X)
#define arrayCopy(X) boxptr_arrayCopy(NULL,X)
#define arrayGet(X,Y) boxptr_arrayGet(threadData,X,mmc_mk_icon(Y))
extern modelica_metatype arrayCreate(modelica_integer, modelica_metatype);
#define arrayGetNoBoundsChecking(arr,ix) (MMC_STRUCTDATA((arr))[(ix)-1])
#define arrayUpdate(X,Y,Z) boxptr_arrayUpdate(threadData,X,mmc_mk_icon(Y),Z)
extern modelica_metatype arrayAdd(modelica_metatype, modelica_metatype);

extern modelica_metatype boxptr_arrayList(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listArray(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_arrayCopy(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_arrayNth(threadData_t *threadData,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_arrayGet(threadData_t *threadData,modelica_metatype,modelica_metatype);
static inline modelica_metatype boxptr_arrayUpdate(threadData_t *threadData,modelica_metatype arr, modelica_metatype i, modelica_metatype val)
{
  int ix = mmc_unbox_integer(i);
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  if (ix < 1 || ix > nelts)
    MMC_THROW_INTERNAL();
  MMC_STRUCTDATA(arr)[ix-1] = val;
#if defined(_MMC_GC_)
  /* save it in the array trail! */
  if (!MMC_IS_IMMEDIATE(val))
  {
    mmc_uint_t idx;
    /* also check here if the array is not already in the trail */
    for (idx = mmc_GC_state->gen.array_trail_size; &mmc_GC_state->gen.array_trail[idx] >= mmc_GC_state->gen.ATP; idx--)
    if (mmc_GC_state->gen.array_trail[idx] == val) /* if found, do not add again */
    {
      return arr;
    }
    /* add the address of the array into the roots to be
    taken into consideration at the garbage collection time */
    if( mmc_GC_state->gen.ATP == mmc_GC_state->gen.array_trail )
    {
      (void)fprintf(stderr, "Array Trail Overflow!\n");
      mmc_exit(1);
    }
    *--mmc_GC_state->gen.ATP = arr;
  }
#endif
  return arr;
}

extern modelica_metatype boxptr_arrayUpdate(threadData_t *threadData,modelica_metatype, modelica_metatype, modelica_metatype);

/* Misc Operations */
#define print(X) boxptr_print(NULL,X)
extern void boxptr_print(threadData_t*,modelica_metatype);
extern modelica_integer tick(void);
extern modelica_real mmc_clock(void);
#define equality(X,Y) boxptr_equality(threadData,X,Y)
extern void boxptr_equality(threadData_t *,modelica_metatype, modelica_metatype);

/* Weird RML stuff */
#define getGlobalRoot(X) boxptr_getGlobalRoot(threadData,mmc_mk_icon(X))
#define setGlobalRoot(X,V) boxptr_setGlobalRoot(threadData,mmc_mk_icon(X),V)
#define valueConstructor(val) MMC_HDRCTOR(MMC_GETHDR(val))

extern modelica_metatype boxptr_getGlobalRoot(threadData_t*,modelica_metatype);
extern void boxptr_setGlobalRoot(threadData_t*,modelica_metatype, modelica_metatype);
extern modelica_metatype boxptr_valueConstructor(threadData_t*,modelica_metatype);
#define referenceEq(X,Y) ((X) == (Y))

extern modelica_real realMaxLit(void);
extern modelica_integer intMaxLit(void);

extern modelica_boolean setStackOverflowSignal(modelica_boolean);
extern metamodelica_string referenceDebugString(modelica_metatype fnptr);

#if defined(__cplusplus)
}
#endif

#endif /* META_MODELICA_BUILTIN_H_ */
