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


#ifndef OMC_STR_UTILS_H_
#define OMC_STR_UTILS_H_
#include <stdarg.h>
#include "../openmodelica_types.h"
#if defined(__cplusplus)
extern "C" {
#endif
int omc__escapedStringLength(const char* str, int nl, int *hasEscape);
char* omc__escapedString(const char* str, int nl);
int GC_vasprintf(const char **strp, const char *fmt, va_list ap);
int GC_asprintf(const char **strp, const char *fmt, ...);

/* String(x) for the builtin scalar types, built into both runtimes: each
   allocates its own kind of string. */
extern modelica_string modelica_integer_to_modelica_string(modelica_integer i, modelica_integer minLen, modelica_boolean leftJustified);
extern modelica_string modelica_real_to_modelica_string(modelica_real r, modelica_integer signDigits, modelica_integer minLen, modelica_boolean leftJustified);
extern modelica_string modelica_boolean_to_modelica_string(modelica_boolean b, modelica_integer minLen, modelica_boolean leftJustified);
extern modelica_string enum_to_modelica_string(modelica_integer nr, const char *e[], modelica_integer minLen, modelica_boolean leftJustified);
#if defined(__cplusplus)
}
#endif
#endif
