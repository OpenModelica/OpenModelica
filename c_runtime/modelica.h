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

#include <stdlib.h>

#include "modelica_string.h"
#include "memory_pool.h"
#include "index_spec.h"

#include "string_array.h"
#include "boolean_array.h"

#include "real_array.h"
#include "integer_array.h"

#include "utility.h"


#include <assert.h>
#include "read_write.h"
#include "matrix.h"
#include "meta_modelica.h"


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
typedef modelica_real sin_rettype;
typedef modelica_real sinh_rettype;
typedef modelica_real log_rettype;
typedef modelica_real tan_rettype;
typedef modelica_real tanh_rettype;
typedef modelica_real exp_rettype;
typedef modelica_real sqrt_rettype;
typedef modelica_real abs_rettype;
typedef modelica_real max_rettype;
typedef modelica_real min_rettype;
typedef modelica_real arctan_rettype;
#define arctan atan


/* Special Modelica builtin functions*/
typedef modelica_boolean change_rettype;
typedef modelica_real    pre_rettype;
typedef modelica_real    edge_rettype;
typedef modelica_real    initial_rettype;
typedef modelica_real    noEvent_rettype;
typedef modelica_real    floor_rettype;
typedef modelica_real    ceil_rettype;
typedef modelica_real    sample_rettype;
#define smooth(P,EXP)    (EXP)
typedef modelica_real    smooth_rettype;
typedef modelica_integer integer_rettype;

#if defined(__cplusplus)
}
#endif

#endif
