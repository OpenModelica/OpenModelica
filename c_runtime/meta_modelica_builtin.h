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

typedef modelica_metatype metamodelica_string;
typedef const modelica_metatype metamodelica_string_const;

typedef metamodelica_string intString_rettype;
intString_rettype intString(modelica_integer);
modelica_metatype boxptr_intString(modelica_metatype);

/* String Character Conversion */
typedef modelica_integer stringCharInt_rettype;
typedef metamodelica_string intStringChar_rettype;

stringCharInt_rettype stringCharInt(metamodelica_string);
intStringChar_rettype intStringChar(modelica_integer);

/* String Operations */
typedef modelica_integer stringInt_rettype;
typedef modelica_integer stringHash_rettype;
typedef modelica_integer stringHashDjb2_rettype;
typedef modelica_integer stringHashSdbm_rettype;
typedef modelica_metatype stringListStringChar_rettype;
typedef metamodelica_string stringAppendList_rettype;
typedef modelica_integer stringLength_rettype;
typedef modelica_integer stringCompare_rettype;
typedef metamodelica_string stringGetStringChar_rettype;
typedef metamodelica_string stringUpdateStringChar_rettype;

stringInt_rettype stringInt(metamodelica_string);
stringListStringChar_rettype stringListStringChar(metamodelica_string);
stringAppendList_rettype stringAppendList(modelica_metatype);
metamodelica_string_const stringAppend(metamodelica_string_const,metamodelica_string_const);
#define stringLength(x) MMC_STRLEN(x)
stringCompare_rettype mmc_stringCompare(const void *,const void *);
stringGetStringChar_rettype stringGetStringChar(metamodelica_string,modelica_integer);
stringUpdateStringChar_rettype stringUpdateStringChar(metamodelica_string, metamodelica_string, modelica_integer);
stringHash_rettype stringHash(metamodelica_string_const);
stringHashDjb2_rettype stringHashDjb2(metamodelica_string_const);
stringHashSdbm_rettype stringHashSdbm(metamodelica_string_const);

modelica_metatype boxptr_stringHash(modelica_metatype);
modelica_metatype boxptr_stringHashDjb2(modelica_metatype);
modelica_metatype boxptr_stringHashSdmb(modelica_metatype);

/* List Operations */
typedef modelica_metatype listReverse_rettype;
typedef modelica_metatype listAppend_rettype;
typedef modelica_integer listLength_rettype;
typedef modelica_boolean listMember_rettype;
typedef modelica_metatype listGet_rettype;
typedef modelica_integer listEmpty_rettype;
typedef modelica_metatype listDelete_rettype;

listReverse_rettype listReverse(modelica_metatype);
listAppend_rettype listAppend(modelica_metatype,modelica_metatype);
listLength_rettype listLength(modelica_metatype);
listMember_rettype listMember(modelica_metatype, modelica_metatype);
listGet_rettype listGet(modelica_metatype, modelica_integer);
#define listEmpty(LST) MMC_NILTEST(LST)
listDelete_rettype listDelete(modelica_metatype, modelica_integer);

modelica_metatype boxptr_listGet(modelica_metatype,modelica_metatype);
#define boxptr_listAppend listAppend

/* Option Operations */
typedef modelica_boolean optionNone_rettype;
optionNone_rettype optionNone(modelica_metatype);

/* Array Operations */
typedef modelica_integer arrayLength_rettype;
typedef modelica_metatype arrayGet_rettype;
typedef modelica_metatype arrayCreate_rettype;
typedef modelica_metatype arrayList_rettype;
typedef modelica_metatype listArray_rettype;
typedef modelica_metatype arrayUpdate_rettype;
typedef modelica_metatype arrayCopy_rettype;
typedef modelica_metatype arrayAdd_rettype;

arrayLength_rettype arrayLength(modelica_metatype);
arrayGet_rettype arrayGet(modelica_metatype, modelica_integer);
arrayCreate_rettype arrayCreate(modelica_integer, modelica_metatype);
arrayList_rettype arrayList(modelica_metatype);
listArray_rettype listArray(modelica_metatype);
arrayUpdate_rettype arrayUpdate(modelica_metatype, modelica_integer, modelica_metatype);
arrayCopy_rettype arrayCopy(modelica_metatype);
arrayAdd_rettype arrayAdd(modelica_metatype, modelica_metatype);

/* Misc Operations */
typedef modelica_integer tick_rettype;
typedef modelica_real mmc_clock_rettype;

void print(modelica_metatype);
tick_rettype tick();
mmc_clock_rettype mmc_clock();
void equality(modelica_metatype, modelica_metatype);

#define boxptr_print print

/* Weird RML stuff */
typedef modelica_metatype getGlobalRoot_rettype;
typedef modelica_integer valueConstructor_rettype;
typedef modelica_boolean referenceEq_rettype;

getGlobalRoot_rettype getGlobalRoot(int ix);
void setGlobalRoot(int ix, modelica_metatype val);
valueConstructor_rettype valueConstructor(modelica_metatype val);

modelica_metatype boxptr_getGlobalRoot(modelica_metatype);
void boxptr_setGlobalRoot(modelica_metatype, modelica_metatype);
modelica_metatype boxptr_valueConstructor(modelica_metatype);
#define referenceEq(X,Y) ((X) == (Y))

#if defined(__cplusplus)
}
#endif

#endif /* META_MODELICA_BUILTIN_H_ */
