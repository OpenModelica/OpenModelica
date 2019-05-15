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


#ifndef DIVISION_H
#define DIVISION_H

#include "../openmodelica.h"
#include "omc_error.h"

/* #define CHECK_NAN */
#ifdef CHECK_NAN
#define DIVISION(a,b,c) (((b) != 0) ? (isnan_error(((a) / (b)), c, __FILE__, __LINE__)) : ((a) / division_error(threadData, b, c, __FILE__, __LINE__)))
#else
#define DIVISION(a,b,c) (((b) != 0) ? ((a) / (b)) : ((a) / division_error_time(threadData, b, c, data->localData[0]->timeValue, __FILE__, __LINE__,data->simulationInfo->noThrowDivZero?1:0)))
#endif

#define DIVISION_SIM(a,b,msg,equation) (__OMC_DIV_SIM(threadData, a, b, msg, equationIndexes, data->simulationInfo->noThrowDivZero, data->localData[0]->timeValue, initial()))

#define DIVISIONNOTIME(a,b,c) (((b) != 0) ? ((a) / (b)) : ((a) / division_error(threadData, b, c, __FILE__, __LINE__)))

modelica_real division_error_equation_time(threadData_t*, modelica_real a, modelica_real b, const char *division_str, const int *indexes, modelica_real time, modelica_boolean noThrow);
modelica_real division_error_time(threadData_t*,modelica_real b, const char* division_str, modelica_real time, const char* file, long line, modelica_boolean noThrow);
modelica_real division_error(threadData_t*,modelica_real b, const char* division_str, const char* file, long line);
modelica_real isnan_error(threadData_t*,modelica_real b, const char* division_str, const char* file, long line);
int valid_number(double a);

static inline modelica_real __OMC_DIV_SIM(threadData_t *threadData, const modelica_real a, const modelica_real b, const char *msg, const int *equationIndexes, modelica_boolean noThrowDivZero, const modelica_real time_, const modelica_boolean initial_)
{
  modelica_real res;
  if(b != 0.0)
    res = a/b;
  else if(initial_ && a == 0.0)
    res = 0.0;
  else
    res = a / division_error_equation_time(threadData, a, b, msg, equationIndexes, time_, noThrowDivZero);

  if(!valid_number(res)){
    if(noThrowDivZero) {
      warningStreamPrintWithEquationIndexes(LOG_UTIL, 0, equationIndexes, "division leads to inf or nan at time %g, (a=%g) / (b=%g), where divisor b is: %s", time_, a, b, msg);
    }
    else {
      throwStreamPrintWithEquationIndexes(threadData, equationIndexes, "division leads to inf or nan at time %g, (a=%g) / (b=%g), where divisor b is: %s", time_, a, b, msg);
    }
  }
  return res;
}

#endif
