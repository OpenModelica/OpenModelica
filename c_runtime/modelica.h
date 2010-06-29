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

/* File: modelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef MODELICA_H_
#define MODELICA_H_

#if defined(__cplusplus)
extern "C" {
#endif

typedef void* modelica_complex; /* currently only External objects are represented using modelica_complex.*/
typedef void* modelica_metatype; /* MetaModelica extension, added by sjoelund */
typedef void(* modelica_fnptr) (void); /*MetaModelica extension, function pointer, added by stefan */

#include <stdlib.h>

#include "compat.h"
#include "modelica_string.h"
#include "memory_pool.h"
#include "index_spec.h"

#include "string_array.h"
#include "boolean_array.h"

#include "real_array.h"
#include "integer_array.h"

#include "utility.h"
#include "division.h"


#include <assert.h>
#include "read_write.h"
#include "matrix.h"
#include "meta_modelica.h"
#include "meta_modelica_builtin.h"


typedef real_array_t real_array;
typedef integer_array_t integer_array;
typedef modelica_string_t modelica_string;
typedef boolean_array_t boolean_array;
typedef string_array_t string_array;

typedef modelica_integer size_real_array_rettype;
typedef modelica_integer size_integer_array_rettype;

/* math functions (-lm)*/
typedef modelica_real cos_rettype;
typedef modelica_real cosh_rettype;
typedef modelica_real acos_rettype;
typedef modelica_real sin_rettype;
typedef modelica_real sinh_rettype;
typedef modelica_real asin_rettype;
typedef modelica_real log_rettype;
typedef modelica_real log10_rettype;
typedef modelica_real tan_rettype;
typedef modelica_real tanh_rettype;
typedef modelica_real atan_rettype;
typedef modelica_real exp_rettype;
typedef modelica_real sqrt_rettype;
typedef modelica_real arctan_rettype;
typedef modelica_real atan2_rettype;
typedef modelica_real div_rettype;
typedef modelica_real mod_rettype;
typedef modelica_real rem_rettype;
#define arctan atan

/* Not correct - min,max,abs may return integers.
 *  So don't generate code containing these types!
 * bad typedef modelica_real abs_rettype;
 * bad typedef modelica_real max_rettype;
 * bad typedef modelica_real min_rettype;
 */

/* div is already defined in stdlib, so it's redefined here to modelica_div so
 * that it can be implemented without changing the name. Hopefully no one uses
 * the stdlib div and includes this header... */
#define div modelica_div

/* fmod in math.h does not work in the same way as mod defined by modelica, so
 * we need to define our own mod. */
#define mod modelica_mod

/* Special Modelica builtin functions*/
typedef modelica_real    pre_rettype;
typedef modelica_real    edge_rettype;
typedef modelica_real    initial_rettype;
typedef modelica_real    noEvent_rettype;
typedef modelica_real    floor_rettype;
typedef modelica_real    ceil_rettype;
typedef modelica_real    sample_rettype;
#define smooth(P,EXP)    (EXP)
typedef modelica_real    smooth_rettype;
typedef modelica_boolean change_rettype;
typedef modelica_integer integer_rettype;
typedef modelica_real    sign_rettype;

/* sign function */
#define sign(v) (v>0?1:(v<0?-1:0))

#if defined(__cplusplus)
}
#endif

#endif
