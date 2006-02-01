/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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


typedef real_array_t real_array;
typedef integer_array_t integer_array;
typedef modelica_string_t modelica_string;

typedef modelica_integer size_real_array_rettype;
typedef modelica_integer size_integer_array_rettype;

typedef modelica_real cos_rettype;
typedef modelica_real sin_rettype;
typedef modelica_real pre_rettype;
typedef modelica_real edge_rettype;
typedef modelica_real initial_rettype;
#if defined(__cplusplus)
}
#endif

#endif
