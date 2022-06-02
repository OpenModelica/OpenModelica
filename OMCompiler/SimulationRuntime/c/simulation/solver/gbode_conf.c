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

/*! \file gbode_conf.c
 */
#include <string.h>

#include "util/omc_error.h"
#include "util/simulation_options.h"
#include "simulation/options.h"

/**
 * @brief Get Runge-Kutta method from simulation flag FLAG_SR.
 *
 * Defaults to RK_DOPRI45 if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum GB_SINGLERATE_METHOD    Runge-Kutta method.
 */
enum GB_SINGLERATE_METHOD getGB_method(enum _FLAG FLAG_METHOD) {
  enum GB_SINGLERATE_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_METHOD];
  char* GB_method_string;

  if (flag_value != NULL) {
    GB_method_string = GC_strdup(flag_value);
    for (method=RK_UNKNOWN; method<RK_MAX; method++) {
      if (strcmp(GB_method_string, GB_SINGLERATE_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: %s", GB_SINGLERATE_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow gbode method %s.", GB_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose gbode method: %s [from command line]", GB_method_string);
    return RK_UNKNOWN;
  } else {
    if (FLAG_METHOD == FLAG_MR) {
      return getGB_method(FLAG_SR);
    } else {

      infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: adams [default]");
      return MS_ADAMS_MOULTON;
    }
  }
}

/**
 * @brief Get non-linear solver method for Runge-Kutta from flag FLAG_SR_NLS.
 *
 * Defaults to Newton if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum GB_NLS_METHOD   NLS method.
 */
enum GB_NLS_METHOD getGB_NLS_METHOD(enum _FLAG FLAG_NLS_METHOD) {
  enum GB_NLS_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_NLS_METHOD];
  char* GB_NLS_METHOD_string;

  if (flag_value != NULL) {
    GB_NLS_METHOD_string = GC_strdup(flag_value);
    for (method=GB_NLS_UNKNOWN; method<RK_NLS_MAX; method++) {
      if (strcmp(GB_NLS_METHOD_string, GB_NLS_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: %s", GB_NLS_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow non-linear solver method %s for gbode.", GB_NLS_METHOD_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose gbode NLS method: %s [from command line]", GB_NLS_METHOD_string);
    return GB_NLS_UNKNOWN;
  } else {
    if (FLAG_NLS_METHOD == FLAG_MR_NLS) {
      return getGB_NLS_METHOD(FLAG_SR_NLS);
    } else {
      infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: newton [default]");
      return RK_NLS_KINSOL;
    }
  }
}

