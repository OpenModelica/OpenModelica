/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2018, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 *  This file contains the implementation for operations on modelica_arrays consisting of integers for the JIT.
 *  The reason for this duplication of code is that the JIT needs to be able to pass arrays as pointers of i8* type
 *  allocated with malloc and not through allocations of C structs on the stack.
 * Note the implementation of this functionality was not finalised....
 */

#ifndef _INTEGER_ARRAY_JIT_H
#define _INTEGER_ARRAY_JIT_H

#include "util/base_array.h"
#include "util/integer_array.h"
#include "openmodelica.h"
#include "meta_modelica_builtin.h"
#include "llvm_gen_modelica_constants.h"

#ifdef __cplusplus
extern "C" {
#endif

modelica_integer integer_get_jit(const integer_array_t *a, size_t i);
modelica_metatype createIntegerArray1D(const modelica_integer siz);
modelica_metatype integerArrayUpdate_jit(modelica_metatype arr,modelica_integer i,modelica_metatype val);
modelica_metatype integer_set_jit(integer_array *a, size_t i, modelica_integer r);
void add_integer_array_jit(const integer_array_t *a, const integer_array_t *b,integer_array_t **dest);
void simple_alloc_1d_integer_array_jit(integer_array_t* dest, int n);

#ifdef __cplusplus
}
#endif

#endif
