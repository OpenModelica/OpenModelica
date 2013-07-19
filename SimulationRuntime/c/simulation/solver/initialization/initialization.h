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

/*! \file initialization.h
 */

#ifndef _INITIALIZATION_H_
#define _INITIALIZATION_H_

#include "simulation_data.h"
#include "initialization_data.h"

#ifdef __cplusplus
#include <cstdlib>
extern "C"
{
#endif
  enum INIT_INIT_METHOD
  {
    IIM_UNKNOWN = 0,
    IIM_NONE,
    IIM_NUMERIC,
    IIM_SYMBOLIC,
    IIM_MAX
  };

  static const char *INIT_METHOD_NAME[IIM_MAX] = {
    "unknown",
    "none",
    "numeric",
    "symbolic"
  };
  static const char *INIT_METHOD_DESC[IIM_MAX] = {
    "unknown",
    "sets all variables to their start values and skips the initialization process",
    "solves the initialization problem numerically",
    "solves the initialization problem symbolically - default"
  };

  enum INIT_OPTI_METHOD
  {
    IOM_UNKNOWN = 0,
    IOM_SIMPLEX,
    IOM_NEWUOA,
    IOM_NELDER_MEAD_EX,
    IOM_KINSOL,
    IOM_KINSOL_SCALED,
    IOM_IPOPT,
    IOM_MAX
  };

  static const char *OPTI_METHOD_NAME[IOM_MAX] = {
    "unknown",
    "simplex",
    "newuoa",
    "nelder_mead_ex",
    "kinsol",
    "kinsol_scaled",
    "ipopt"
  };
  static const char *OPTI_METHOD_DESC[IOM_MAX] = {
    "unknown",
    "Nelder-Mead method",
    "Brent's method",
    "Extended Nelder-Mead method (see -ils for global homotopy) - default",
    "sundials/kinsol",
    "sundials/kinsol with scaling",
    "Interior Point OPTimizer"
  };

  extern void dumpInitialization(INIT_DATA *initData);
  extern int reportResidualValue(INIT_DATA *initData);
  extern double leastSquareWithLambda(INIT_DATA *initData, double lambda);
  extern int initialization(DATA *data, const char* pInitMethod, const char* pOptiMethod, const char* pInitFile, double initTime, int lambda_steps);

#ifdef __cplusplus
}
#endif

#endif
