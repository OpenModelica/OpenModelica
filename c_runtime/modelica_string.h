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

typedef char* modelica_string_t;
typedef const char* modelica_string_const;

int modelica_string_ok(modelica_string_t* a);

int modelica_string_length(modelica_string_const a);

void init_modelica_string(modelica_string_t* dest, const char* str);

void alloc_modelica_string(modelica_string_t* dest,int length);

void modelica_real_to_modelica_string(modelica_string_t* dest,modelica_real r,modelica_integer minLen,
modelica_boolean leftJustified,modelica_integer signDigits);

void modelica_integer_to_modelica_string(modelica_string_t* dest,modelica_integer i,
	modelica_integer minLen,modelica_boolean leftJustified,modelica_integer signDigits);

void modelica_boolean_to_modelica_string(modelica_string_t* dest,modelica_boolean b,
modelica_integer minLen, modelica_boolean leftJustified, modelica_integer signDigits);

void modelica_enumeration_to_modelica_string(modelica_string_t* dest,modelica_integer nr, modelica_string_t e[],
modelica_integer minLen, modelica_boolean leftJustified, modelica_integer signDigits);


/* Frees memory*/
void free_modelica_string(modelica_string_t*);

/* Copy string*/
void copy_modelica_string(modelica_string_const source, modelica_string_t* dest);

/* Concatenate strings */
void cat_modelica_string(modelica_string_t* dest, modelica_string_const s1, modelica_string_const s2);
#endif
