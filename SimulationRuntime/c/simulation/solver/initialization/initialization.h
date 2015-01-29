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

/*! \file initialization.h
 */

#ifndef _INITIALIZATION_H_
#define _INITIALIZATION_H_

#include "simulation_data.h"

#ifdef __cplusplus
#include <cstdlib>
extern "C"
{
#endif

  enum INIT_INIT_METHOD
  {
    IIM_UNKNOWN = 0,
    IIM_NONE,
    IIM_SYMBOLIC,
    IIM_MAX
  };

  static const char *INIT_METHOD_NAME[IIM_MAX] = {
    "unknown",
    "none",
    "symbolic"
  };
  static const char *INIT_METHOD_DESC[IIM_MAX] = {
    "unknown",
    "sets all variables to their start values and skips the initialization process",
    "solves the initialization problem symbolically - default"
  };

  extern int initialization(DATA *data, const char* pInitMethod, const char* pInitFile, double initTime, int lambda_steps);

#ifdef __cplusplus
}
#endif

#endif
