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

#ifndef MODELICA_STRING_H_
#define MODELICA_STRING_H_

#include <string.h>
#include <stdarg.h>

#include "../openmodelica.h"
#include "omc_string.h"
#include "modelica_string_lit.h"
#include "omc_str_utils.h"

/* The simulation's string builtins; meta/meta_modelica_string.h defines the
   same names for MetaModelica. */
#if !defined(OMC_METAMODELICA_RUNTIME)

extern modelica_string stringAppend(modelica_string s1, modelica_string s2);
extern modelica_integer stringCompare(modelica_string str1, modelica_string str2);
#define stringEqual(x,y) (omc_string_len(x) == omc_string_len(y) && !stringCompare(x,y))

#define modelica_string_length(STR) omc_string_len(STR)

extern modelica_string alloc_modelica_string(int length);

/* formatting String functions */
extern modelica_string modelica_real_to_modelica_string_format(modelica_real r, modelica_string format);
extern modelica_string modelica_integer_to_modelica_string_format(modelica_integer i, modelica_string format);
extern modelica_string modelica_stringo_modelica_string_format(modelica_string s, modelica_string format);

extern modelica_string modelica_real_to_modelica_string(modelica_real r, modelica_integer signDigits,
                                   modelica_integer minLen, modelica_boolean leftJustified);

extern modelica_string modelica_string_to_modelica_string(modelica_string s);
extern modelica_string modelica_integer_to_modelica_string(modelica_integer i,
                                   modelica_integer minLen,modelica_boolean leftJustified);

extern modelica_string modelica_boolean_to_modelica_string(modelica_boolean b,
                                   modelica_integer minLen, modelica_boolean leftJustified);

extern modelica_string enum_to_modelica_string(modelica_integer nr, const char *e[],
                                   modelica_integer minLen, modelica_boolean leftJustified);

#endif /* !OMC_METAMODELICA_RUNTIME */
#endif
