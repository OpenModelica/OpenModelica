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
#include "real_array_jit.h"

#ifdef __cplusplus
extern "C" {
#endif
modelica_real real_get_jit(const real_array_t *a,size_t i)
{
  DBG("%p\n",a);
  return ((modelica_real *) a->data)[i];
}

modelica_metatype real_set_jit(real_array *a, size_t i, modelica_real r)
{
  ((modelica_real *) a->data)[i] = r;
  return a;
}

void copy_real_array_jit(const real_array_t *source, real_array_t **dest)
{
  copy_real_array(*source,*dest);
}

void copy_real_array_data_jit(const real_array_t *source, real_array_t **dest)
{
  copy_real_array_data(*source,*dest);
}


modelica_metatype createRealArray1D(const modelica_integer siz)
{
  //MEMORY LEAK! To ensure that the address that refers to the array does not change.
  //Did do it with Boehm GC before, that lead to BOEHM deleting the variable when printing in the
  //ceval context. Spent a couple of days to fix it. Did not manage to.
  real_array_t *realArr = malloc(sizeof(real_array_t));
  simple_alloc_1d_real_array(realArr,siz);
  alloc_real_array_data(realArr);
  return realArr;
}

/*Since I changed the array semantics we need an other model*/
void alloc_real_array_jit(real_array_t **dest, int ndims, ...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(*dest, ndims, ap);
    va_end(ap);
    (*dest)->data = real_alloc(elements);
}


void add_real_array_jit(const real_array_t * a, const real_array_t * b, real_array_t** dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert a and b are of the same size */
    /* Assert that dest are of correct size */
    nr_of_elements = base_array_nr_of_elements(*a);
    for(i = 0; i < nr_of_elements; ++i) {
        real_set_jit(*dest, i, real_get(*a, i)+real_get(*b, i));
    }
}

void mul_real_array_jit(const real_array_t *a,const real_array_t *b,real_array_t** dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that a,b have same sizes? */
  nr_of_elements = base_array_nr_of_elements(*a);
  for(i=0; i < nr_of_elements; ++i) {
    real_set_jit(*dest, i, real_get(*a, i) * real_get(*b, i));
  }
}

#ifdef __cplusplus
}
#endif
