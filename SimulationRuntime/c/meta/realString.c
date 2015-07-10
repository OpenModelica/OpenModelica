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

#include "meta_modelica.h"
#include <ctype.h>

static const MMC_DEFSTRINGLIT(_OMC_LIT_NEG_INF,4,"-inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_POS_INF,3,"inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_NAN,3,"NaN");

#if defined(_MSC_VER)
#include <float.h>
#define isnan _isnan
#define isinf !_finite
#endif

modelica_string _old_realString(modelica_real r)
{
  /* NOTE: The RML runtime uses the same code as this function.
   * If you update one, you must update the other or the testsuite might break
   *
   * 64-bit (1+11+52) double: -d.[15 digits]E-[4 digits] = ~24 digits max.
   * Add safety margin in case some C runtime is trigger happy. */
  char buffer[32];
  char* endptr = '\0';
  snprintf(buffer, 32, "%.16g", r);
  /* If it looks like an integer, we need to append .0 so it looks like real */
  endptr = buffer;
  if (*endptr == '-') endptr++;
  while (isdigit(*endptr)) endptr++;
  if (0 == *endptr) {
    *endptr++ = '.';
    *endptr++ = '0';
    *endptr++ = '\0';
  } else if ('E' == *endptr) {
    *endptr = 'e';
  }
  return mmc_mk_scon(buffer);
}

modelica_string realString(modelica_real r)
{
  if (isinf(r) && r < 0)
    return MMC_REFSTRINGLIT(_OMC_LIT_NEG_INF);
  else if (isinf(r))
    return MMC_REFSTRINGLIT(_OMC_LIT_POS_INF);
  else if (isnan(r))
    return MMC_REFSTRINGLIT(_OMC_LIT_NAN);
  return _old_realString(r);
}


#ifdef REAL_STRING_TEST_MAIN
#define c 15
int main()
{
  int i,j;
  double dds[c] = {-1.765,1.765,0,1,4,15e13,1.676e14,-15e-1,0.005,-0.03e13,1234567890,-1234567890,9.999999999999999e22,INFINITY,NAN};
  const char *res[c] = {
    "-1.765","1.765","0.0","1.0","4.0","150000000000000.0","167600000000000.0","-1.5","0.005","-300000000000.0","1234567890.0","-1234567890.0","9.999999999999999e+22","inf","NaN",
  };
  for (i=0;i<c;i++) {
    for (j=0;j<1;j++) {
    char *buf;
    buf = dtostr(dds[i]);
    fprintf(stderr, "%s%.15g to %s\n", strcmp(res[i],buf)==0 ? "" : "ERRROR: ",dds[i], buf);
    }
  }
}
#endif
