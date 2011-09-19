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

/* File: meta_modelica_builtin.h
 * Description: This is the C header file for the new builtin
 * functions existing in MetaModelica.
 */

#ifndef META_MODELICA_BUILTIN_H_
#define META_MODELICA_BUILTIN_H_

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

#include "meta_modelica_builtin_boxptr.h"

typedef modelica_metatype metamodelica_string;
typedef const modelica_metatype metamodelica_string_const;

metamodelica_string intString(modelica_integer);
modelica_metatype boxptr_intMax(modelica_metatype,modelica_metatype);

/* String Character Conversion */

modelica_integer stringCharInt(metamodelica_string);
metamodelica_string intStringChar(modelica_integer);

/* String Operations */
modelica_integer stringInt(metamodelica_string);
modelica_real stringReal(metamodelica_string);
modelica_metatype stringListStringChar(metamodelica_string);
metamodelica_string stringAppendList(modelica_metatype);
metamodelica_string_const stringAppend(metamodelica_string_const,metamodelica_string_const);
#define stringLength(x) MMC_STRLEN(x)
modelica_integer mmc_stringCompare(const void *,const void *);
metamodelica_string stringGetStringChar(metamodelica_string,modelica_integer);
metamodelica_string stringUpdateStringChar(metamodelica_string, metamodelica_string, modelica_integer);
modelica_integer stringHash(metamodelica_string_const);
modelica_integer stringHashDjb2(metamodelica_string_const);
modelica_integer stringHashDjb2Mod(metamodelica_string_const,modelica_integer);
modelica_integer stringHashSdbm(metamodelica_string_const);

#define System_stringHashDjb2Mod stringHashDjb2Mod
#define boxptr_System_stringHashDjb2Mod boxptr_stringHashDjb2Mod

modelica_metatype boxptr_stringEq(modelica_metatype a, modelica_metatype b);
#define boxptr_stringEqual boxptr_stringEq
#define boxptr_stringAppend stringAppend
modelica_metatype boxptr_stringHash(modelica_metatype);
modelica_metatype boxptr_stringHashDjb2(modelica_metatype);
modelica_metatype boxptr_stringHashDjb2Mod(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_stringHashSdmb(modelica_metatype);

/* List Operations */
modelica_metatype listReverse(modelica_metatype);
modelica_metatype listAppend(modelica_metatype,modelica_metatype);
modelica_integer listLength(modelica_metatype);
modelica_boolean listMember(modelica_metatype, modelica_metatype);
modelica_metatype listGet(modelica_metatype, modelica_integer);
#define listEmpty(LST) MMC_NILTEST(LST)
modelica_metatype listDelete(modelica_metatype, modelica_integer);
#define listRest(X) MMC_CDR(X)
#define listFirst(X) MMC_CAR(X)

modelica_metatype boxptr_listNth(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_listGet(modelica_metatype,modelica_metatype);
#define boxptr_listAppend listAppend
modelica_metatype boxptr_listFirst(modelica_metatype);
modelica_metatype boxptr_listRest(modelica_metatype);
#define boxptr_listReverse listReverse
#define boxptr_listMember listMember

/* Option Operations */
#define optionNone(x) (0==MMC_HDRSLOTS(MMC_GETHDR(x)) ? 1 : 0)

/* Array Operations */
modelica_integer arrayLength(modelica_metatype);
modelica_metatype arrayGet(modelica_metatype, modelica_integer);
modelica_metatype arrayCreate(modelica_integer, modelica_metatype);
modelica_metatype arrayList(modelica_metatype);
modelica_metatype listArray(modelica_metatype);
modelica_metatype arrayUpdate(modelica_metatype, modelica_integer, modelica_metatype);
modelica_metatype arrayCopy(modelica_metatype);
modelica_metatype arrayAdd(modelica_metatype, modelica_metatype);

#define boxptr_arrayList arrayList
#define boxptr_arrayCopy arrayCopy
modelica_metatype boxptr_arrayNth(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_arrayGet(modelica_metatype,modelica_metatype);

/* Misc Operations */
void print(modelica_metatype);
modelica_integer tick();
modelica_real mmc_clock();
void equality(modelica_metatype, modelica_metatype);

#define boxptr_print print

/* Weird RML stuff */
modelica_metatype getGlobalRoot(int ix);
void setGlobalRoot(int ix, modelica_metatype val);
#define valueConstructor(val) MMC_HDRCTOR(MMC_GETHDR(val))

modelica_metatype boxptr_getGlobalRoot(modelica_metatype);
void boxptr_setGlobalRoot(modelica_metatype, modelica_metatype);
modelica_metatype boxptr_valueConstructor(modelica_metatype);
#define referenceEq(X,Y) ((X) == (Y))

modelica_real realMaxLit();
modelica_integer intMaxLit();

#if defined(__cplusplus)
}
#endif

#endif /* META_MODELICA_BUILTIN_H_ */
