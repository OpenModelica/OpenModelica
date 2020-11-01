/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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


#ifndef UTILITY_H
#define UTILITY_H

#include "../openmodelica.h"
#include <math.h>

static inline int in_range_boolean(modelica_integer b,
         modelica_integer start,
         modelica_integer stop)
{
  if(start <= stop) {
      if((b >= start) && (b <= stop)) {
          return 1;
      }
  } else {
      if((b >= stop) && (b <= start)) {
          return 1;
      }
  }
  return 0;
}

static inline int in_range_integer(modelica_integer i,
         modelica_integer start,
         modelica_integer stop)
{
  if(start <= stop) {
      if((i >= start) && (i <= stop)) {
          return 1;
      }
  } else {
      if((i >= stop) && (i <= start)) {
          return 1;
      }
  }
  return 0;
}

static inline int in_range_real(modelica_real i,
      modelica_real start,
      modelica_real stop)
{
  if(start <= stop) {
      if((i >= start) && (i <= stop)) {
          return 1;
      }
  } else {
      if((i >= stop) && (i <= start)) {
          return 1;
      }
  }
  return 0;
}


/* div is already defined in stdlib, so it's redefined here to modelica_div */
static inline modelica_real modelica_div(modelica_real x, modelica_real y)
{
  return (modelica_real)((modelica_integer)(x/y));
}

static inline modelica_integer modelica_integer_min(modelica_integer x,modelica_integer y)
{
  return (x < y) ? x : y;
}

static inline modelica_integer modelica_integer_max(modelica_integer x,modelica_integer y)
{
  return (x > y) ? x : y;
}

static inline modelica_real modelica_real_min(modelica_real x,modelica_real y)
{
  return (x < y) ? x : y;
}

static inline modelica_real modelica_real_max(modelica_real x,modelica_real y)
{
  return (x > y) ? x : y;
}


#define reduction_sum(X,Y) ((X)+(Y))
#define reduction_product(X,Y) ((X)*(Y))

/* pow(), but for integer exponents (faster implementation) */
extern modelica_real real_int_pow(threadData_t *threadData, modelica_real base,modelica_integer n);

#if !defined(OMC_MINIMAL_RUNTIME)
/* Returns 0 on failure. The first element in nmatches contains the error-message. */
extern int OpenModelica_regexImpl(const char* str, const char* re, const int maxn, int extended, int sensitive, void*(*)(const char*), void **result);
/* Wrapper for the builtin call */
extern int OpenModelica_regex(const char* str, const char* re, int maxn, int extended, int sensitive, const char **result);
#endif

extern modelica_string OpenModelica_uriToFilename_impl(threadData_t *threadData, modelica_string uri, const char *resourcesDir);
#define OpenModelica_uriToFilename(URI) OpenModelica_uriToFilename_impl(threadData, URI, NULL)
#define OpenModelica__uriToFilename(URI) OpenModelica_uriToFilename(URI)
extern void OpenModelica_updateUriMapping(threadData_t *threadData, void *namesAndDirs);

static inline modelica_real modelica_real_mod(modelica_real x, modelica_real y)
{
  return x-floor(x/y)*y;
}

/* Returns res such that 0 <= abs(res) < abs(y) and res has the same sign as y */
static inline modelica_integer modelica_integer_mod(modelica_integer x, modelica_integer y)
{
  modelica_integer res = x % y;
  return ((y > 0 && res < 0) || (y < 0 && res > 0)) ? (res + y) : res;
}

#endif
