/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
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

/* Boolean Operations */
typedef modelica_boolean boolAnd_rettype;
typedef modelica_boolean boolOr_rettype;
typedef modelica_boolean boolNot_rettype;

boolAnd_rettype boolAnd(modelica_boolean,modelica_boolean);
boolOr_rettype boolOr(modelica_boolean,modelica_boolean);
boolNot_rettype boolNot(modelica_boolean);

/* Integer Operations */
typedef modelica_integer intAdd_rettype;
typedef modelica_integer intSub_rettype;
typedef modelica_integer intMul_rettype;
typedef modelica_integer intDiv_rettype;
typedef modelica_integer intMod_rettype;
typedef modelica_integer intMax_rettype;
typedef modelica_integer intMin_rettype;

intAdd_rettype intAdd(modelica_integer, modelica_integer);
intSub_rettype intSub(modelica_integer, modelica_integer);
intMul_rettype intMul(modelica_integer, modelica_integer);
intDiv_rettype intDiv(modelica_integer, modelica_integer);
intMod_rettype intMod(modelica_integer, modelica_integer);
intMax_rettype intMax(modelica_integer, modelica_integer);
intMin_rettype intMin(modelica_integer, modelica_integer);

typedef modelica_boolean intLt_rettype;
typedef modelica_boolean intLe_rettype;
typedef modelica_boolean intEq_rettype;
typedef modelica_boolean intNe_rettype;
typedef modelica_boolean intGe_rettype;
typedef modelica_boolean intGt_rettype;

intLt_rettype intLt(modelica_integer, modelica_integer);
intLe_rettype intLe(modelica_integer, modelica_integer);
intEq_rettype intEq(modelica_integer, modelica_integer);
intNe_rettype intNe(modelica_integer, modelica_integer);
intGe_rettype intGe(modelica_integer, modelica_integer);
intGt_rettype intGt(modelica_integer, modelica_integer);

typedef modelica_integer intAbs_rettype;
typedef modelica_integer intNeg_rettype;
typedef modelica_real intReal_rettype;
typedef modelica_string_t intString_rettype;

intAbs_rettype intAbs(modelica_integer);
intNeg_rettype intNeg(modelica_integer);
intReal_rettype intReal(modelica_integer);
intString_rettype intString(modelica_integer);

/* Real Operations */
typedef modelica_real realAdd_rettype;
typedef modelica_real realSub_rettype;
typedef modelica_real realMul_rettype;
typedef modelica_real realDiv_rettype;
typedef modelica_real realMod_rettype;
typedef modelica_real realPow_rettype;
typedef modelica_real realMax_rettype;
typedef modelica_real realMin_rettype;

realAdd_rettype realAdd(modelica_real,modelica_real);
realSub_rettype realSub(modelica_real,modelica_real);
realMul_rettype realMul(modelica_real,modelica_real);
realDiv_rettype realDiv(modelica_real,modelica_real);
realMod_rettype realMod(modelica_real,modelica_real);
realPow_rettype realPow(modelica_real,modelica_real);
realMax_rettype realMax(modelica_real,modelica_real);
realMin_rettype realMin(modelica_real,modelica_real);

typedef modelica_real realAbs_rettype;
typedef modelica_real realNeg_rettype;
typedef modelica_real realCos_rettype;
typedef modelica_real realSin_rettype;
typedef modelica_real realAtan_rettype;
typedef modelica_real realExp_rettype;
typedef modelica_real realLn_rettype;
typedef modelica_real realFloor_rettype;
typedef modelica_real realSqrt_rettype;

realAbs_rettype realAbs(modelica_real);
realNeg_rettype realNeg(modelica_real);
realCos_rettype realCos(modelica_real);
realSin_rettype realSin(modelica_real);
realAtan_rettype realAtan(modelica_real);
realExp_rettype realExp(modelica_real);
realLn_rettype realLn(modelica_real);
realFloor_rettype realFloor(modelica_real);
realSqrt_rettype realSqrt(modelica_real);

typedef modelica_boolean realLt_rettype;
typedef modelica_boolean realLe_rettype;
typedef modelica_boolean realEq_rettype;
typedef modelica_boolean realNe_rettype;
typedef modelica_boolean realGe_rettype;
typedef modelica_boolean realGt_rettype;

realLt_rettype realLt(modelica_real, modelica_real);
realLe_rettype realLe(modelica_real, modelica_real);
realEq_rettype realEq(modelica_real, modelica_real);
realNe_rettype realNe(modelica_real, modelica_real);
realGe_rettype realGe(modelica_real, modelica_real);
realGt_rettype realGt(modelica_real, modelica_real);

typedef modelica_integer realInt_rettype;
typedef modelica_string_t realString_rettype;

realInt_rettype realInt(modelica_real);
realString_rettype realString(modelica_real);

/* String Character Conversion */
typedef modelica_integer stringCharInt_rettype;
typedef modelica_string_t intStringChar_rettype;

stringCharInt_rettype stringCharInt(modelica_string_t);
intStringChar_rettype intStringChar(modelica_integer);

/* String Operations */
typedef modelica_integer stringInt_rettype;
typedef modelica_metatype stringListStringChar_rettype;
typedef modelica_string_t listStringCharString_rettype;
typedef modelica_string_t stringAppendList_rettype;
typedef modelica_string_t stringAppend_rettype;
typedef modelica_integer stringLength_rettype;
typedef modelica_integer stringCompare_rettype;
typedef modelica_boolean stringEqual_rettype;
typedef modelica_string_t stringGetStringChar_rettype;
typedef modelica_string_t stringUpdateStringChar_rettype;

stringInt_rettype stringInt(modelica_string_t);
stringListStringChar_rettype stringListStringChar(modelica_string_t);
listStringCharString_rettype listStringCharString(modelica_metatype);
stringAppendList_rettype stringAppendList(modelica_metatype);
stringAppend_rettype stringAppend(modelica_string_t,modelica_string_t);
stringLength_rettype stringLength(modelica_string_t);
stringCompare_rettype stringCompare(modelica_string_t,modelica_string_t);
stringEqual_rettype stringEqual(modelica_string_t,modelica_string_t);
stringGetStringChar_rettype stringGetStringChar(modelica_string_t,modelica_integer);
stringUpdateStringChar_rettype stringUpdateStringChar(modelica_string_t, modelica_string_t, modelica_integer);

/* List Operations */
typedef modelica_metatype listReverse_rettype;
typedef modelica_metatype listAppend_rettype;
typedef modelica_integer listLength_rettype;
typedef modelica_boolean listMember_rettype;
typedef modelica_metatype listGet_rettype;
typedef modelica_metatype listNth_rettype;
typedef modelica_metatype listRest_rettype;
typedef modelica_integer listEmpty_rettype;
typedef modelica_metatype listDelete_rettype;

listReverse_rettype listReverse(modelica_metatype);
listAppend_rettype listAppend(modelica_metatype,modelica_metatype);
listLength_rettype listLength(modelica_metatype);
listMember_rettype listMember(modelica_metatype, modelica_metatype);
listGet_rettype listGet(modelica_metatype, modelica_integer);
listNth_rettype listNth(modelica_metatype, modelica_integer);
listRest_rettype listRest(modelica_metatype);
listEmpty_rettype listEmpty(modelica_metatype);
listDelete_rettype listDelete(modelica_metatype, modelica_integer);

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
typedef modelica_metatype if__exp_rettype;
typedef modelica_integer tick_rettype;
typedef modelica_real mmc__clock_rettype;

if__exp_rettype if__exp(modelica_boolean, modelica_metatype, modelica_metatype);
void print(modelica_string_t);
tick_rettype tick();
mmc__clock_rettype mmc__clock();
void equality(modelica_metatype, modelica_metatype);

#if defined(__cplusplus)
}
#endif

#endif
