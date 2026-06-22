/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 *  This file contains the implementation for operations on modelica_arrays consisting of reals for the JIT.
 *  The reason for this duplication of code is that the JIT needs to be able to pass arrays as pointers of i8* type
 *  allocated with GC_MALLOC and not through allocations of C structs on the stack.
 */

#ifndef _REAL_ARRAY_JIT_H
#define _REAL_ARRAY_JIT_H

#include "openmodelica.h"
#include "llvm_gen_modelica_constants.h"
#include "util/base_array.h"
#include "util/real_array.h"

#ifdef __cplusplus
extern "C" {
#endif
modelica_metatype createRealArray1D(const modelica_integer siz);
modelica_metatype real_set_jit(real_array *a, size_t i, modelica_real r);
modelica_real real_get_jit(const real_array *a,size_t i);
void mul_real_array_jit(const real_array *a,const real_array *b,real_array** dest);
void add_real_array_jit(const real_array * a, const real_array * b, real_array** dest);
#ifdef __cplusplus
}
#endif

#endif
