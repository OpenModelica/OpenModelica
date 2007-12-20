/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
typedef modelica_real pre_rettype;
typedef modelica_real edge_rettype;
typedef modelica_real initial_rettype;
typedef modelica_real noEvent_rettype;
typedef modelica_real floor_rettype;
typedef modelica_real ceil_rettype;
typedef modelica_real sample_rettype;
typedef modelica_integer integer_rettype;

#if defined(__cplusplus)
}
#endif

#endif
