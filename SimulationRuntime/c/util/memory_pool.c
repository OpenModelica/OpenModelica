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


#include "memory_pool.h"
#include <gc.h>

/* allocates n reals in the real_buffer */
m_real* real_alloc(int n)
{
  return (m_real*) GC_malloc_atomic(n*sizeof(m_real));
}

/* allocates n integers in the integer_buffer */
m_integer* integer_alloc(int n)
{
  return (m_integer*) GC_malloc_atomic(n*sizeof(m_integer));
}

/* allocates n strings in the string_buffer */
m_string* string_alloc(int n)
{
  return (m_string*) GC_MALLOC(n*sizeof(m_string));
}

/* allocates n booleans in the boolean_buffer */
m_boolean* boolean_alloc(int n)
{
  return (m_boolean*) GC_malloc_atomic(n*sizeof(m_boolean));
}

_index_t* size_alloc(int n)
{
  return (_index_t*) GC_malloc_atomic(n*sizeof(_index_t));
}

_index_t** index_alloc(int n)
{
  return (_index_t**) GC_MALLOC(n*sizeof(_index_t*));
}

/* allocates n elements of size sze */
void* generic_alloc(int n, size_t sze)
{
  return (void*) GC_MALLOC(n*sze);
}
