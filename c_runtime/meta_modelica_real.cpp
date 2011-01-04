/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

#define __OPENMODELICA__METAMODELICA

#include "meta_modelica_real.h"
#include "meta_modelica_builtin.h"
#include <limits.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include <stdio.h>

#if defined(_MSC_VER)
#include <float.h>
#define isinf(d) (!_finite(d) && !_isnan(d))
#define isnan _isnan
#define snprintf _snprintf
#endif

extern "C" {

static const MMC_DEFSTRINGLIT(_OMC_LIT_NEG_INF,4,"-inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_POS_INF,3,"inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_NAN,    3,"NaN");

realString_rettype realString(modelica_real r)
{
  /* 64-bit (1+11+52) double: -d.[15 digits]E-[4 digits] = ~24 digits max.
   * Add safety margin. */
  static char buffer[32];
  modelica_string res;
  // fprintf(stderr, "\nrealString(%g)\n", r);
  if (isinf(r) && r < 0)
    res = MMC_REFSTRINGLIT(_OMC_LIT_NEG_INF);
  else if (isinf(r))
    res = MMC_REFSTRINGLIT(_OMC_LIT_POS_INF);
  else if (isnan(r))
    res = MMC_REFSTRINGLIT(_OMC_LIT_NAN);
  else {
    char* endptr;
    int ix = snprintf(buffer, 32, "%.15g", r);
    long ignore;
    if (ix < 0)
      MMC_THROW();
    errno = 0;
    /* If it looks like an integer, we need to append .0 so it looks like real */
    ignore = strtol(buffer,&endptr,10);
    if (errno == 0 && *endptr == '\0') {
      if (ix > 30)
        MMC_THROW();
      buffer[ix++] = '.';
      buffer[ix++] = '0';
      buffer[ix] = '\0';
    }
    res = mmc_mk_scon(buffer);
  }
  return res;
}

modelica_metatype boxptr_realString(modelica_metatype r)
{
  return realString(mmc_prim_get_real(r));
}

}
