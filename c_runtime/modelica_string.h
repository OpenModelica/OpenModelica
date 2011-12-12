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

#ifndef MODELICA_STRING_H_
#define MODELICA_STRING_H_

#include "real_array.h"
#include "integer_array.h"
#include "boolean_array.h"

#ifdef __OPENMODELICA__METAMODELICA
/* When MetaModelica grammar is enabled, all strings are boxed */
typedef modelica_metatype modelica_string_t;
typedef const modelica_metatype modelica_string_const;
typedef modelica_string_t modelica_string;
#define stringCompare(x,y) mmc_stringCompare(x,y)
#define stringEqual(x,y) (MMC_STRLEN(x) == MMC_STRLEN(y) && !stringCompare(x,y))

#else
typedef char* modelica_string_t;
typedef const char* modelica_string_const;
typedef modelica_string_const modelica_string;
#define stringCompare(x,y) strcmp(x,y)
#define stringEqual(x,y) (stringCompare(x,y)==0)

int modelica_string_ok(modelica_string_t* a);

int modelica_string_length(modelica_string_const a);

modelica_string_const init_modelica_string(modelica_string_const str);

modelica_string_t alloc_modelica_string(int length);

/* formatting String functions */
modelica_string_const modelica_real_to_modelica_string_format(modelica_real r, modelica_string_const format);
modelica_string_const modelica_integer_to_modelica_string_format(modelica_integer i, modelica_string_const format);
modelica_string_const modelica_string_to_modelica_string_format(modelica_string_const s, modelica_string_const format);

modelica_string_const modelica_real_to_modelica_string(modelica_real r,modelica_integer minLen,
modelica_boolean leftJustified,modelica_integer signDigits);

modelica_string_const modelica_integer_to_modelica_string(modelica_integer i,
  modelica_integer minLen,modelica_boolean leftJustified);

modelica_string_const modelica_boolean_to_modelica_string(modelica_boolean b,
modelica_integer minLen, modelica_boolean leftJustified);

modelica_string_const modelica_enumeration_to_modelica_string(modelica_integer nr, modelica_string_t e[],
modelica_integer minLen, modelica_boolean leftJustified);


/* Frees memory*/
void free_modelica_string(modelica_string_t* a);

/* Copy string*/
modelica_string_const copy_modelica_string(modelica_string_const source);

/* Concatenate strings */
modelica_string_const cat_modelica_string(modelica_string_const s1, modelica_string_const s2);
#endif

#endif
