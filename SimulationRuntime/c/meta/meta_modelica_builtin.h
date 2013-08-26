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
extern modelica_metatype boxptr_intMax(modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_intMin(modelica_metatype,modelica_metatype);

/* String Character Conversion */

extern modelica_integer stringCharInt(metamodelica_string i);
extern metamodelica_string intStringChar(modelica_integer ix);

/* String Operations */
extern modelica_integer stringInt(metamodelica_string s);
extern modelica_real stringReal(metamodelica_string s);
extern modelica_metatype stringListStringChar(metamodelica_string s);
extern metamodelica_string stringAppendList(modelica_metatype lst);
extern metamodelica_string stringDelimitList(modelica_metatype lst,metamodelica_string_const delimiter);
#define boxptr_stringDelimitList stringDelimitList
extern metamodelica_string_const stringAppend(metamodelica_string_const s1,metamodelica_string_const s2);
#define stringLength(x) MMC_STRLEN(x)
extern modelica_integer mmc_stringCompare(const void * str1,const void * str2);
extern metamodelica_string stringGetStringChar(metamodelica_string str,modelica_integer ix);
extern metamodelica_string stringUpdateStringChar(metamodelica_string str, metamodelica_string c, modelica_integer ix);
extern modelica_integer stringHash(metamodelica_string_const);
extern modelica_integer stringHashDjb2(metamodelica_string_const s);
extern modelica_integer stringHashDjb2Mod(metamodelica_string_const s,modelica_integer mod);
extern modelica_integer stringHashSdbm(metamodelica_string_const str);

#define System_stringHashDjb2Mod stringHashDjb2Mod
#define boxptr_System_stringHashDjb2Mod boxptr_stringHashDjb2Mod

extern modelica_metatype boxptr_stringEq(modelica_metatype a, modelica_metatype b);
#define boxptr_stringEqual boxptr_stringEq
#define boxptr_stringAppend stringAppend
extern modelica_metatype boxptr_stringHash(modelica_metatype str);
extern modelica_metatype boxptr_stringHashDjb2(modelica_metatype str);
extern modelica_metatype boxptr_stringHashDjb2Mod(modelica_metatype v,modelica_metatype mod);
extern modelica_metatype boxptr_stringHashSdmb(modelica_metatype str);

/* List Operations */
extern modelica_metatype listReverse(modelica_metatype);
extern modelica_metatype listAppend(modelica_metatype,modelica_metatype);
extern modelica_integer listLength(modelica_metatype);
extern modelica_boolean listMember(modelica_metatype, modelica_metatype);
extern modelica_metatype listGet(modelica_metatype, modelica_integer);
#define listEmpty(LST) MMC_NILTEST(LST)
extern modelica_metatype listDelete(modelica_metatype, modelica_integer);
#define listRest(X) MMC_CDR(X)
#define listFirst(X) MMC_CAR(X)

extern modelica_metatype boxptr_listNth(modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listGet(modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_listDelete(modelica_metatype,modelica_metatype);
#define boxptr_listAppend listAppend
extern modelica_metatype boxptr_listFirst(modelica_metatype);
extern modelica_metatype boxptr_listRest(modelica_metatype);
#define boxptr_listReverse listReverse
#define boxptr_listMember listMember

/* Option Operations */
#define optionNone(x) (0==MMC_HDRSLOTS(MMC_GETHDR(x)) ? 1 : 0)

/* Array Operations */
extern modelica_integer arrayLength(modelica_metatype);
extern modelica_metatype arrayGet(modelica_metatype, modelica_integer);
extern modelica_metatype arrayCreate(modelica_integer, modelica_metatype);
extern modelica_metatype arrayList(modelica_metatype);
extern modelica_metatype listArray(modelica_metatype);
extern modelica_metatype arrayUpdate(modelica_metatype, modelica_integer, modelica_metatype);
extern modelica_metatype arrayCopy(modelica_metatype);
extern modelica_metatype arrayAdd(modelica_metatype, modelica_metatype);

#define boxptr_listArray listArray
#define boxptr_arrayList arrayList
#define boxptr_arrayCopy arrayCopy
extern modelica_metatype boxptr_arrayNth(modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_arrayGet(modelica_metatype,modelica_metatype);
extern modelica_metatype boxptr_arrayUpdate(modelica_metatype, modelica_integer, modelica_metatype);

/* Misc Operations */
extern void print(modelica_metatype);
extern modelica_integer tick(void);
extern modelica_real mmc_clock(void);
extern void equality(modelica_metatype, modelica_metatype);
extern void fail();

#define boxptr_print print

/* Weird RML stuff */
extern modelica_metatype getGlobalRoot(int ix);
extern void setGlobalRoot(int ix, modelica_metatype val);
#define valueConstructor(val) MMC_HDRCTOR(MMC_GETHDR(val))

extern modelica_metatype boxptr_getGlobalRoot(modelica_metatype);
extern void boxptr_setGlobalRoot(modelica_metatype, modelica_metatype);
extern modelica_metatype boxptr_valueConstructor(modelica_metatype);
#define referenceEq(X,Y) ((X) == (Y))

extern modelica_real realMaxLit(void);
extern modelica_integer intMaxLit(void);

extern modelica_boolean setStackOverflowSignal(modelica_boolean);
extern metamodelica_string referenceDebugString(modelica_metatype fnptr);

#if defined(__cplusplus)
}
#endif

#endif /* META_MODELICA_BUILTIN_H_ */
