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

#include "gbode_conf.h"

void dumOptions(const char* flagName, const char* flagValue, const char** argsArr, unsigned int maxArgs);

const char *GB_CTRL_METHOD_NAME[GB_CTRL_MAX] = {
  /* GB_CTRL_UNKNOWN */   "unknown",
  /* GB_CTRL_I */         "i",
  /* GB_CTRL_PI */        "pi",
  /* GB_CTRL_CNST */      "const"
};

const char *GB_CTRL_METHOD_DESC[GB_CTRL_MAX] = {
  /* GB_CTRL_UNKNOWN */   "unknown",
  /* GB_CTRL_I */         "I controller for step size",
  /* GB_CTRL_PI */        "PI controller for step size",
  /* GB_CTRL_CNST */      "Constant step size"
};

const char *GB_INTERPOL_METHOD_NAME[GB_INTERPOL_MAX] = {
  /* GB_INTERPOL_UNKNOWN */           "unknown",
  /* GB_INTERPOL_LIN */               "linear",
  /* GB_INTERPOL_HERMITE */           "hermite",
  /* GB_INTERPOL_HERMITE_b */         "hermite_b",
  /* GB_INTERPOL_HERMITE_ERRCTRL */   "hermite_errctrl",
  /* GB_DENSE_OUTPUT */               "dense_output",
  /* GB_DENSE_OUTPUT_ERRCTRL */       "dense_output_errctrl"
};

const char *GB_INTERPOL_METHOD_DESC[GB_INTERPOL_MAX] = {
  /* GB_INTERPOL_UNKNOWN */         "unknown",
  /* GB_INTERPOL_LIN */             "Linear interpolation (1st order)",
  /* GB_INTERPOL_HERMITE */         "Hermite interpolation (2nd order)",
  /* GB_INTERPOL_HERMITE_b */       "Hermite interpolation (only for left hand side)",
  /* GB_INTERPOL_HERMITE_ERRCTRL */ "Hermite interpolation with error control",
  /* GB_DENSE_OUTPUT */             "use dense output formula for interpolation",
  /* GB_DENSE_OUTPUT_ERRCTRL */     "use dense output fomular with error control"
};

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

  // Get method from flag
  if (flag_value != NULL) {
    for (method=RK_UNKNOWN; method<RK_MAX; method++) {
      if (strcmp(flag_value, GB_SINGLERATE_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: %s", GB_SINGLERATE_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Unknown gbode method %s.", flag_value);
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
      // Default value for inner integration method
      // if the outer integration method is full implicit
      return RK_ESDIRK3;
    default:
      return singleRateMethod;
    }
  }

  // Default value for single-rate method
  infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: esdirk3 [default]");
  return RK_ESDIRK3;
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
 * @return enum GB_NLS_METHOD   NLS method.
 */
enum GB_NLS_METHOD getGB_NLS_method(enum _FLAG flag) {
  enum GB_NLS_METHOD method;
  const char* flag_value;

  assertStreamPrint(NULL, flag==FLAG_SR_NLS || flag==FLAG_MR_NLS,
                    "Illegal input to getGB_NLS_method. Expected FLAG_SR_NLS or FLAG_MR_NLS ");
  flag_value = omc_flagValue[flag];

  // Get method from flag
  if (flag_value != NULL) {
    for (method=GB_NLS_UNKNOWN; method<RK_NLS_MAX; method++) {
      if (strcmp(flag_value, GB_NLS_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: %s", GB_NLS_METHOD_NAME[method]);
        return method;
      }
    }
    dumOptions(FLAG_NAME[flag], flag_value, GB_NLS_METHOD_NAME, RK_NLS_MAX);
    return GB_NLS_UNKNOWN;
  }

  // Default value
  if (flag == FLAG_MR_NLS) {
    return getGB_NLS_method(FLAG_SR_NLS);
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: kinsol [default]");
    return RK_NLS_KINSOL;
  }
}

/**
 * @brief Get step size controller from simulation flag.
 *
 * Reads value from from FLAG_SR_CTRL or FLAG_MR_CTRL.
 * Defaults to IController (GB_CTRL_I) if flag is not set.
 *
 * @param flag                    FLAG_SR_CTRL for single-rate method.
 *                                FLAG_MR_CTRL for multi-rate method.
 * @return enum GB_CTRL_METHOD    Step size control method.
 */
enum GB_CTRL_METHOD getControllerMethod(enum _FLAG flag) {
  enum GB_CTRL_METHOD method;
  const char *flag_value;

  assertStreamPrint(NULL, flag==FLAG_SR_CTRL || flag==FLAG_MR_CTRL,
                    "Illegal input to getControllerMethod. Expected FLAG_SR_CTRL or FLAG_MR_CTRL ");

  flag_value = omc_flagValue[flag];
  if (flag_value != NULL) {
    for (method=GB_CTRL_UNKNOWN; method<GB_CTRL_MAX; method++) {
      if (strcmp(flag_value, GB_CTRL_METHOD_NAME[method]) == 0) {
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode step size control: %s", GB_CTRL_METHOD_NAME[method]);
        return method;
      }
    }
    dumOptions(FLAG_NAME[flag], flag_value, GB_CTRL_METHOD_NAME, GB_CTRL_MAX);
    return GB_CTRL_UNKNOWN;
  } else {
    return GB_CTRL_I;
  }
}

/**
 * @brief Get interpolation method from simulation flag.
 *
 * Reads value from from FLAG_SR_INT or FLAG_MR_INT.
 * Defaults to interpolatiom (GB_INTERPOL_HERMITE) if flag is not set.
 *
 * @param flag                        FLAG_SR_INT for single-rate method.
 *                                    FLAG_MR_INT for multi-rate method.
 * @return enum GB_INTERPOL_METHOD    Interpolation method for emitting
 *                                    results and slow states interpolation.
 */
enum GB_INTERPOL_METHOD getInterpolationMethod(enum _FLAG flag) {
  enum GB_INTERPOL_METHOD method;
  const char *flag_value;
  char* flag_value_string;

  assertStreamPrint(NULL, flag==FLAG_SR_INT || flag==FLAG_MR_INT,
                    "Illegal input to getInterpolationMethod. Expected FLAG_SR_INT or FLAG_MR_INT ");

  flag_value = omc_flagValue[flag];
  if (flag_value != NULL) {
    for (method=GB_INTERPOL_UNKNOWN; method<GB_INTERPOL_MAX; method++) {
      if (strcmp(flag_value, GB_INTERPOL_METHOD_NAME[method]) == 0) {
        if (flag == FLAG_MR_INT && (method == GB_INTERPOL_HERMITE_ERRCTRL || method == GB_DENSE_OUTPUT_ERRCTRL)) {
          warningStreamPrint(LOG_SOLVER, 0, "Chosen gbode interpolation method %s not supported for fast state integration", GB_INTERPOL_METHOD_NAME[method]);
          method = GB_INTERPOL_HERMITE;
        }
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode interpolation method: %s", GB_INTERPOL_METHOD_NAME[method]);
        return method;
      }
    }
    dumOptions(FLAG_NAME[flag], flag_value, GB_INTERPOL_METHOD_NAME, GB_INTERPOL_MAX);
    return GB_INTERPOL_UNKNOWN;
  } else {
    return GB_INTERPOL_HERMITE;
  }
}

/**
 * @brief Get percentage of states for the fast states selection.
 *
 * Read flag FLAG_MR_PAR to get percentage.
 * Defaults to 0.
 *
 * @return double   Percentage of fast states selection.
 */
double getGBRatio() {
  double percentage;
  const char *flag_value = omc_flagValue[FLAG_MR_PAR];

  if (flag_value) {
    percentage = atof(omc_flagValue[FLAG_MR_PAR]);
    if (percentage < 0 || percentage > 1) {
      throwStreamPrint(NULL, "Flag -gbratio has to be between 0 and 1.");
    }
  } else {
    percentage = 0;
  }
  return percentage;
}

/**
 * @brief Dump available flag options to stdout.
 *
 * @param flagName    Name of flag
 * @param flagValue   Given value of flag.
 * @param argsArr     Pointer to flag argument names.
 * @param maxArgs     Size of maxArgs.
 */
void dumOptions(const char* flagName, const char* flagValue, const char** argsArr, unsigned int maxArgs) {
  errorStreamPrint(LOG_STDOUT, 0, "Unknown flag value \"%s\" for flag %s.", flagValue, flagName);
  infoStreamPrint(LOG_STDOUT, 1, "Valid arguments are:");
  for (int i=0; i<maxArgs; i++) {
    infoStreamPrint(LOG_STDOUT, 0, "%s", argsArr[i]);
  }
  messageClose(LOG_STDOUT);
}