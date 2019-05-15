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

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>

#include "division.h"
#include "omc_msvc.h"
#include "omc_error.h"

int valid_number(double a)
{
  return !isnan(a) && !isinf(a);
}


modelica_real division_error_equation_time(threadData_t *threadData, modelica_real a, modelica_real b, const char *msg, const int *indexes, modelica_real time, modelica_boolean noThrow)
{
  if(noThrow){
    warningStreamPrintWithEquationIndexes(LOG_UTIL, 0, indexes, "solver will try to handle division by zero at time %.16g: %s", time, msg);
  } else {
    throwStreamPrintWithEquationIndexes(threadData, indexes, "division by zero at time %.16g, (a=%.16g) / (b=%.16g), where divisor b expression is: %s", time, a, b, msg);
  }
  return b;
}

modelica_real division_error_time(threadData_t *threadData, modelica_real b, const char* division_str, modelica_real time, const char* file, long line, modelica_boolean noThrow)
{
  if(noThrow){
    warningStreamPrint(LOG_UTIL, 0,
      "division by zero in partial equation: %s\n"
      "at Time=%f\n"
      "solver will try to handle that.", division_str, time);
  } else {
    warningStreamPrint(LOG_STDOUT, 0,
      "division by zero in partial equation: %s\n"
      "at Time=%f\n"
      "[line] %ld | [file] %s", division_str, time, line, file);
#ifndef __APPLE_CC__
    throwStreamPrint(threadData,"division by zero");
#endif
  }
  return b;
}

modelica_real division_error(threadData_t *threadData, modelica_real b, const char* division_str, const char* file, long line)
{
  warningStreamPrint(LOG_STDOUT, 0, "division by zero in partial equation: %s\n"
                                 "[line] %ld | [file] %s", division_str, line, file);
#ifndef __APPLE_CC__
  throwStreamPrint(threadData,"division by zero");
#endif
  return b;
}

modelica_real isnan_error(threadData_t *threadData,modelica_real b, const char* division_str, const char* file, long line)
{
  if(isnan(b))
  {
    warningStreamPrint(LOG_STDOUT, 0, "division result in NAN in partial equation: %s\n"
                                      "[line] %ld | [file] %s", division_str, line, file);
#ifndef __APPLE_CC__
    throwStreamPrint(threadData,"division by zero");
#endif
  }
  return b;
}
