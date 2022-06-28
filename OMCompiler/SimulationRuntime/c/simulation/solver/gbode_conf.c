/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Linköpings University,
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

#include "../../util/omc_error.h"
#include "../../simulation/options.h"

/**
 * @brief Get Runge-Kutta method from simulation flag FLAG_SR or FLAG_MR.
 *
 * Defaults to method RK_LOBA_IIIB_4 for single-rate.
 *
 * Defaults to method RK_SDIRK2 for multi-rate method, if single-rate method is implicit.
 * Otherwise us same method as single-rate method.
 *
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @param flag                          FLAG_SR for single-rate method.
 *                                      FLAG_MR for multi-rate method.
 * @return enum GB_SINGLERATE_METHOD    Runge-Kutta method.
 */
enum GB_SINGLERATE_METHOD getGB_method(enum _FLAG flag) {
  enum GB_SINGLERATE_METHOD method;
  const char* flag_value;
  assertStreamPrint(NULL, flag==FLAG_SR || flag==FLAG_MR,
                    "Illegal input to getGB_method. Expected FLAG_SR or FLAG_MR ");
  flag_value = omc_flagValue[flag];
  char* GB_method_string;

  // Get method from flag
  if (flag_value != NULL) {
    GB_method_string = strdup(flag_value);
    for (method=RK_UNKNOWN; method<RK_MAX; method++) {
      if (strcmp(GB_method_string, GB_SINGLERATE_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: %s", GB_SINGLERATE_METHOD_NAME[method]);
        free(GB_method_string);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow gbode method %s.", GB_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose gbode method: %s [from command line]", GB_method_string);
    free(GB_method_string);
    return RK_UNKNOWN;
  }

  // Default value for multi-rate method
  if (flag == FLAG_MR) {
    enum GB_SINGLERATE_METHOD singleRateMethod = getGB_method(FLAG_SR);
    switch (singleRateMethod)
    {
    case RK_GAUSS2:
    case RK_GAUSS3:
    case RK_GAUSS4:
    case RK_GAUSS5:
    case RK_GAUSS6:
    case RK_RADAU_IA_2:
    case RK_RADAU_IA_3:
    case RK_RADAU_IA_4:
    case RK_RADAU_IIA_2:
    case RK_RADAU_IIA_3:
    case RK_RADAU_IIA_4:
    case RK_LOBA_IIIA_3:
    case RK_LOBA_IIIA_4:
    case RK_LOBA_IIIB_3:
    case RK_LOBA_IIIB_4:
    case RK_LOBA_IIIC_3:
    case RK_LOBA_IIIC_4:
      return RK_SDIRK2;
      break;
    default:
      return singleRateMethod;
      break;
    }
  }

  // Default value for single-rate method
  infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: lobattoIIIB4 [default]");
  return RK_LOBA_IIIB_4;
}

/**
 * @brief Get non-linear solver method for Runge-Kutta from flag FLAG_SR_NLS.
 *
 * Defaults to RK_NLS_KINSOL for single-rate.
 * Defaults to nls method of single-rate for multi-rate.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @param flag        FLAG_SR_NLS for single-rate method.
 *                    FLAG_MR_NLS for multi-rate method.
 *
 * @return enum GB_NLS_METHOD   NLS method.
 */
enum GB_NLS_METHOD getGB_NLS_METHOD(enum _FLAG flag) {
  enum GB_NLS_METHOD method;
  const char* flag_value;
  assertStreamPrint(NULL, flag==FLAG_SR_NLS || flag==FLAG_MR_NLS,
                    "Illegal input to getGB_NLS_METHOD. Expected FLAG_SR_NLS or FLAG_MR_NLS ");
  flag_value = omc_flagValue[flag];
  char* GB_NLS_METHOD_string;

  // Get method from flag
  if (flag_value != NULL) {
    GB_NLS_METHOD_string = strdup(flag_value);
    for (method=GB_NLS_UNKNOWN; method<RK_NLS_MAX; method++) {
      if (strcmp(GB_NLS_METHOD_string, GB_NLS_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: %s", GB_NLS_METHOD_NAME[method]);
        free(GB_NLS_METHOD_string);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow non-linear solver method %s for gbode.", GB_NLS_METHOD_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose gbode NLS method: %s [from command line]", GB_NLS_METHOD_string);
    free(GB_NLS_METHOD_string);
    return GB_NLS_UNKNOWN;
  }

  // Default value
  if (flag == FLAG_MR_NLS) {
    return getGB_NLS_METHOD(FLAG_SR_NLS);
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: kinsol [default]");
    return RK_NLS_KINSOL;
  }
}
