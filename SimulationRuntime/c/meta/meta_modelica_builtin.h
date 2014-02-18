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
extern modelica_metatype boxptr_intMax(ERROR_HANDLE*,threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_intMin(ERROR_HANDLE*,threadData_t*,modelica_metatype,modelica_metatype);

/* String Character Conversion */

#define stringCharInt(X) mmc_unbox_integer(boxptr_stringCharInt(NULL,threadData,X))
#define intStringChar(X) boxptr_intStringChar(NULL,threadData,mmc_mk_icon(X))
extern modelica_metatype boxptr_stringCharInt(ERROR_HANDLE*,threadData_t*,metamodelica_string i);
extern metamodelica_string boxptr_intStringChar(ERROR_HANDLE*,threadData_t*,modelica_metatype ix);

/* String Operations */
#define stringInt(X) mmc_unbox_integer(boxptr_stringInt(NULL,threadData,X))
extern modelica_metatype boxptr_stringInt(ERROR_HANDLE*,threadData_t*,metamodelica_string s);
#define stringReal(X) mmc_unbox_real(boxptr_stringReal(NULL,threadData,X))
extern modelica_metatype boxptr_stringReal(ERROR_HANDLE*,threadData_t*,metamodelica_string s);
extern modelica_metatype stringListStringChar(metamodelica_string s);
#define stringAppend(X,Y) boxptr_stringAppend(NULL,NULL,X,Y)
extern metamodelica_string stringAppendList(modelica_metatype lst);
extern metamodelica_string boxptr_stringDelimitList(ERROR_HANDLE*,threadData_t*,modelica_metatype lst,metamodelica_string_const delimiter);
#define stringDelimitList(X,Y) boxptr_stringDelimitList(NULL,NULL,X,Y)
#define stringLength(x) MMC_STRLEN(x)
extern modelica_integer mmc_stringCompare(const void * str1,const void * str2);
#define stringGetStringChar(X,Y) boxptr_stringGetStringChar(NULL,threadData,X,mmc_mk_icon(Y))
extern metamodelica_string boxptr_stringGetStringChar(ERROR_HANDLE*,threadData_t*,metamodelica_string str,modelica_metatype ix);
#define stringUpdateStringChar(X,Y,Z) boxptr_stringUpdateStringChar(NULL,threadData,X,Y,mmc_mk_icon(Z))
extern metamodelica_string boxptr_stringUpdateStringChar(ERROR_HANDLE*,threadData_t *,metamodelica_string str, metamodelica_string c, modelica_metatype ix);
extern modelica_integer stringHash(metamodelica_string_const);
extern modelica_integer stringHashDjb2(metamodelica_string_const s);
extern modelica_integer stringHashDjb2Mod(metamodelica_string_const s,modelica_integer mod);
extern modelica_integer stringHashSdbm(metamodelica_string_const str);

#define System_stringHashDjb2Mod stringHashDjb2Mod
#define boxptr_System_stringHashDjb2Mod boxptr_stringHashDjb2Mod

extern modelica_metatype boxptr_stringEq(ERROR_HANDLE*,threadData_t*,modelica_metatype a, modelica_metatype b);
#define boxptr_stringEqual boxptr_stringEq
extern metamodelica_string_const boxptr_stringAppend(ERROR_HANDLE*,threadData_t*,metamodelica_string_const s1,metamodelica_string_const s2);
extern modelica_metatype boxptr_stringHash(ERROR_HANDLE*,threadData_t*,modelica_metatype str);
extern modelica_metatype boxptr_stringHashDjb2(ERROR_HANDLE*,threadData_t*,modelica_metatype str);
extern modelica_metatype boxptr_stringHashDjb2Mod(ERROR_HANDLE*,threadData_t*,modelica_metatype v,modelica_metatype mod);
extern modelica_metatype boxptr_stringHashSdmb(ERROR_HANDLE*,threadData_t*,modelica_metatype str);

/* List Operations */
#define listReverse(X) boxptr_listReverse(NULL,X)
#define listMember(X,Y) mmc_unbox_integer(boxptr_listMember(NULL,NULL,X,Y))
#define listAppend(X,Y) boxptr_listAppend(NULL,NULL,X,Y)
extern modelica_integer listLength(modelica_metatype);
#define listGet(X,Y) boxptr_listGet(NULL,threadData,X,mmc_mk_icon(Y))
#define listEmpty(LST) MMC_NILTEST(LST)
#define listDelete(X,Y) boxptr_listDelete(NULL,threadData,X,mmc_mk_icon(Y))
#define listRest(X) MMC_CDR(X)
#define listFirst(X) MMC_CAR(X)

extern modelica_metatype boxptr_listNth(ERROR_HANDLE*,threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listGet(ERROR_HANDLE*,threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listDelete(ERROR_HANDLE*,threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listAppend(ERROR_HANDLE*,threadData_t*,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listFirst(ERROR_HANDLE*,threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listRest(ERROR_HANDLE*,threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listReverse(threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listMember(ERROR_HANDLE*,threadData_t*,modelica_metatype, modelica_metatype);

/* Option Operations */
#define optionNone(x) (0==MMC_HDRSLOTS(MMC_GETHDR(x)) ? 1 : 0)

/* Array Operations */
extern modelica_integer arrayLength(modelica_metatype);
#define listArray(X) boxptr_listArray(NULL,NULL,X)
#define arrayList(X) boxptr_arrayList(NULL,NULL,X)
#define arrayCopy(X) boxptr_arrayCopya(NULL,NULL,X)
#define arrayGet(X,Y) boxptr_arrayGet(NULL,threadData,X,mmc_mk_icon(Y))
extern modelica_metatype arrayCreate(modelica_integer, modelica_metatype);
#define arrayUpdate(X,Y,Z) boxptr_arrayUpdate(NULL,threadData,X,mmc_mk_icon(Y),Z)
extern modelica_metatype arrayAdd(modelica_metatype, modelica_metatype);

extern modelica_metatype boxptr_arrayList(ERROR_HANDLE*,threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_listArray(ERROR_HANDLE*,threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_arrayCopy(ERROR_HANDLE*,threadData_t*,modelica_metatype);
extern modelica_metatype boxptr_arrayNth(ERROR_HANDLE*,threadData_t *threadData,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_arrayGet(ERROR_HANDLE*,threadData_t *threadData,modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_arrayUpdate(ERROR_HANDLE*,threadData_t *threadData,modelica_metatype, modelica_metatype, modelica_metatype);

/* Misc Operations */
#define print(X) boxptr_print(NULL,NULL,X)
extern void boxptr_print(ERROR_HANDLE*,threadData_t*,modelica_metatype);
extern modelica_integer tick(void);
extern modelica_real mmc_clock(void);
#define equality(X,Y) boxptr_equality(NULL,threadData,X,Y)
extern void boxptr_equality(ERROR_HANDLE*,threadData_t *,modelica_metatype, modelica_metatype);

/* Weird RML stuff */
#define getGlobalRoot(X) boxptr_getGlobalRoot(NULL,threadData,mmc_mk_icon(X))
#define setGlobalRoot(X,V) boxptr_setGlobalRoot(NULL,threadData,mmc_mk_icon(X),V)
#define valueConstructor(val) MMC_HDRCTOR(MMC_GETHDR(val))

extern modelica_metatype boxptr_getGlobalRoot(ERROR_HANDLE*,threadData_t*,modelica_metatype);
extern void boxptr_setGlobalRoot(ERROR_HANDLE*,threadData_t*,modelica_metatype, modelica_metatype);
extern modelica_metatype boxptr_valueConstructor(ERROR_HANDLE*,threadData_t*,modelica_metatype);
#define referenceEq(X,Y) ((X) == (Y))

extern modelica_real realMaxLit(void);
extern modelica_integer intMaxLit(void);

extern modelica_boolean setStackOverflowSignal(modelica_boolean);
extern metamodelica_string referenceDebugString(modelica_metatype fnptr);

#if defined(__cplusplus)
}
#endif

#endif /* META_MODELICA_BUILTIN_H_ */
