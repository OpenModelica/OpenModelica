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

#ifndef MODELICA_STRING_H_
#define MODELICA_STRING_H_

#include "openmodelica.h"
#include <stdarg.h>

#define stringCompare(x,y) mmc_stringCompare(x,y)
#define stringEqual(x,y) (MMC_STRLEN(x) == MMC_STRLEN(y) && !stringCompare(x,y))

#define modelica_string_length(STR) MMC_STRLEN(STR)

extern modelica_string alloc_modelica_string(int length);

/* formatting String functions */
extern modelica_string modelica_real_to_modelica_string_format(modelica_real r, modelica_string format);
extern modelica_string modelica_integer_to_modelica_string_format(modelica_integer i, modelica_string format);
extern modelica_string modelica_stringo_modelica_string_format(modelica_string s, modelica_string format);

extern modelica_string modelica_real_to_modelica_string(modelica_real r,modelica_integer minLen,
                                   modelica_boolean leftJustified,modelica_integer signDigits);

extern modelica_string modelica_integer_to_modelica_string(modelica_integer i,
                                   modelica_integer minLen,modelica_boolean leftJustified);

extern modelica_string modelica_boolean_to_modelica_string(modelica_boolean b,
                                   modelica_integer minLen, modelica_boolean leftJustified);

extern modelica_string modelica_enumeration_to_modelica_string(modelica_integer nr, const modelica_string e[],
                                   modelica_integer minLen, modelica_boolean leftJustified);

/* Escape string */
int omc__escapedStringLength(const char* str, int nl, int *hasEscape);
extern char* omc__escapedString(const char* str, int nl);

int GC_vasprintf(char **strp, const char *fmt, va_list ap);
int GC_asprintf(char **strp, const char *fmt, ...);

#endif
