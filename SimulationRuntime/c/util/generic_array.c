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
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


#include "generic_array.h"
#include "index_spec.h"
#include "memory_pool.h"
#include "division.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>
#include <math.h>


static inline size_t generic_array_nr_of_elements(const base_array_t *a)
{ return base_array_nr_of_elements(a); }


void* generic_ptrget(const base_array_t *a, size_t sze, size_t i) {
  return (a->data) + (i*sze);
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


void alloc_generic_array_data(base_array_t* a, size_t sze)
{
    a->data = generic_alloc(base_array_nr_of_elements(a),sze);
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

