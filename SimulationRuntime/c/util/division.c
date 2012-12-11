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

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "division.h"
#include "omc_error.h"

modelica_real division_error_time(modelica_real b, const char* division_str, modelica_real time, const char* file, long line, modelica_boolean noThrow)
{
  if(noThrow){
    WARNING1(LOG_UTIL, "division by zero in partial equation: %s", division_str);
    WARNING1(LOG_UTIL, "at Time=%f", time);
    WARNING(LOG_UTIL,  "solver will try to handle that.");
  } else {
    WARNING1(LOG_STDOUT, "division by zero in partial equation: %s", division_str);
    WARNING1(LOG_STDOUT, "at Time=%f", time);
    WARNING2(LOG_STDOUT, "[line] %ld | [file] %s", line, file);
#ifndef __APPLE_CC__
    THROW("division by zero");
#endif
  }
  return b;
}

modelica_real division_warning_time(modelica_real b, const char* division_str, modelica_real time, const char* file, long line)
{
  WARNING1(LOG_STDOUT, "division by zero in partial equation: %s", division_str);
  WARNING1(LOG_STDOUT, "at Time=%f", time);

  return b;
}



modelica_real division_error(modelica_real b, const char* division_str, const char* file, long line)
{
  WARNING1(LOG_STDOUT, "division by zero in partial equation: %s", division_str);
  WARNING2(LOG_STDOUT, "[line] %ld | [file] %s", line, file);
#ifndef __APPLE_CC__
  THROW("division by zero");
#endif
  return b;
}

#if defined(_MSC_VER)
#include <float.h>
#define isnan _isnan
#endif

modelica_real isnan_error(modelica_real b, const char* division_str, const char* file, long line)
{
  if(isnan(b))
  {
    WARNING1(LOG_STDOUT, "division result in NAN in partial equation: %s", division_str);
    WARNING2(LOG_STDOUT, "[line] %ld | [file] %s", line, file);
#ifndef __APPLE_CC__
    THROW("division by zero");
#endif
  }
  return b;
}
