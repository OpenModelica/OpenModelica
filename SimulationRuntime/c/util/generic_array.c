/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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


#include "generic_array.h"
#include "index_spec.h"
#include "../gc/omc_gc.h"
#include "division.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>
#include <math.h>


static inline void* generic_ptrget(const base_array_t *a, size_t sze, size_t i) {
  return ((char*)a->data) + (i*sze);
}

void alloc_generic_array(base_array_t* dest, size_t sze, int ndims,...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = generic_alloc(elements, sze);
}


void* generic_array_element_addr(const base_array_t* source, size_t sze, int ndims,...) {
  va_list ap;
  void* tmp;
  va_start(ap,ndims);
  tmp = generic_ptrget(source, calc_base_index_va(source, ndims, ap), sze);
  va_end(ap);
  return tmp;
}

void* generic_array_element_addr1(const base_array_t* source, size_t sze, int dim1) {
  return generic_ptrget(source, dim1-1, sze);
}


void alloc_generic_array_data(base_array_t* a, size_t sze)
{
    a->data = generic_alloc(base_array_nr_of_elements(*a),sze);
}

// void copy_generic_array_data(const base_array_t * source, base_array_t* dest)
// {
    // size_t i, nr_of_elements;

    // assert(base_array_ok(source));
    // assert(base_array_ok(dest));
    // assert(base_array_shape_eq(source, dest));

    // nr_of_elements = generic_array_nr_of_elements(source);

    // for(i = 0; i < nr_of_elements; ++i) {
        // integer_set(dest, i, integer_get(source, i));
    // }
// }

