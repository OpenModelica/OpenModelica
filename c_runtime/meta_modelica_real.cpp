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

/* Real Operations */
realAdd_rettype realAdd(modelica_real r1, modelica_real r2)
{
  return r1+r2;
}

realSub_rettype realSub(modelica_real r1, modelica_real r2)
{
  return r1-r2;
}

realMul_rettype realMul(modelica_real r1, modelica_real r2)
{
  return r1*r2;
}

realDiv_rettype realDiv(modelica_real r1, modelica_real r2)
{
  return r1/r2;
}

realMod_rettype realMod(modelica_real r1, modelica_real r2)
{
  return fmod(r1,r2);
}

realPow_rettype realPow(modelica_real r1, modelica_real r2)
{
  return pow(r1,r2);
}

realMax_rettype realMax(modelica_real r1, modelica_real r2)
{
  return r1 > r2 ? r1 : r2;
}

realMin_rettype realMin(modelica_real r1, modelica_real r2)
{
  return r1 < r2 ? r1 : r2;
}

realLt_rettype realLt(modelica_real r1, modelica_real r2)
{
  return r1 < r2;
}

realLe_rettype realLe(modelica_real r1, modelica_real r2)
{
  return r1 <= r2;
}

realEq_rettype realEq(modelica_real r1, modelica_real r2)
{
  return r1 == r2;
}

realNe_rettype realNe(modelica_real r1, modelica_real r2)
{
  return r1 != r2;
}

realGe_rettype realGe(modelica_real r1, modelica_real r2)
{
  return r1 >= r2;
}

realGt_rettype realGt(modelica_real r1, modelica_real r2)
{
  return r1 > r2;
}

realInt_rettype realInt(modelica_real r)
{
  return (modelica_integer) r;
}

realString_rettype realString(modelica_real r)
{
  /* 64-bit (1+11+52) double: -d.[15 digits]E-[4 digits] = ~24 digits max.
   * Add safety margin. */
  static char buffer[32];
  modelica_string res;
  if (isinf(r) && r < 0)
    res = "-inf";
  else if (isinf(r))
    res = "inf";
  else if (isnan(r))
    res = "NaN";
  else {
    char* endptr;
    int ix = snprintf(buffer, 32, "%.15g", r);
    long ignore;
    if (ix < 0)
      throw 1;
    errno = 0;
    /* If it looks like an integer, we need to append .0 so it looks like real */
    ignore = strtol(buffer,&endptr,10);
    if (errno == 0 && *endptr == '\0') {
      if (ix > 30)
        throw 1;
      buffer[ix++] = '.';
      buffer[ix++] = '0';
      buffer[ix] = '\0';
    }
    res = strdup(buffer);
  }
  return res;
}

modelica_metatype boxptr_realString(modelica_metatype r)
{
  return mmc_mk_scon(realString(mmc_prim_get_real(r)));
}

modelica_metatype boxptr_realAdd(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(mmc_prim_get_real(r1)+mmc_prim_get_real(r2));
}

modelica_metatype boxptr_realSub(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(mmc_prim_get_real(r1)-mmc_prim_get_real(r2));
}

modelica_metatype boxptr_realMul(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(mmc_prim_get_real(r1)*mmc_prim_get_real(r2));
}

modelica_metatype boxptr_realDiv(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(mmc_prim_get_real(r1)/mmc_prim_get_real(r2));
}

modelica_metatype boxptr_realMod(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(fmod(mmc_prim_get_real(r1),mmc_prim_get_real(r2)));
}

modelica_metatype boxptr_realPow(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(pow(mmc_prim_get_real(r1),mmc_prim_get_real(r2)));
}

modelica_metatype boxptr_realMax(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(mmc_prim_get_real(r1) > mmc_prim_get_real(r2) ? mmc_prim_get_real(r1) : mmc_prim_get_real(r2));
}

modelica_metatype boxptr_realMin(modelica_metatype r1, modelica_metatype r2)
{
  return mmc_mk_rcon(mmc_prim_get_real(r1) < mmc_prim_get_real(r2) ? mmc_prim_get_real(r1) : mmc_prim_get_real(r2));
}

modelica_metatype boxptr_realAbs(modelica_metatype r)
{
  return mmc_mk_rcon(fabs(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realNeg(modelica_metatype r)
{
  return mmc_mk_rcon(-(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realCos(modelica_metatype r)
{
  return mmc_mk_rcon(cos(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realSin(modelica_metatype r)
{
  return mmc_mk_rcon(sin(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realAtan(modelica_metatype r)
{
  return mmc_mk_rcon(atan(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realExp(modelica_metatype r)
{
  return mmc_mk_rcon(exp(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realLn(modelica_metatype r)
{
  return mmc_mk_rcon(log(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realLog10(modelica_metatype r)
{
  return mmc_mk_rcon(log10(mmc_prim_get_real(r)));
}
modelica_metatype boxptr_realSqrt(modelica_metatype r)
{
  return mmc_mk_rcon(sqrt(mmc_prim_get_real(r)));
}

}
