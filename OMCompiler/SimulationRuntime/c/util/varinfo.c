/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include <math.h>

#include "omc_error.h"
#include "../simulation_data.h"
#include "varinfo.h"

const char *var_type_names[VAR_TYPE_MAX] = {
    [VAR_TYPE_UNKNOWN] = "unknown",

    [VAR_TYPE_REAL]    = "real",
    [VAR_TYPE_INTEGER] = "integer",
    [VAR_TYPE_BOOLEAN] = "boolean",
    [VAR_TYPE_STRING]  = "string"
};

const char *var_kind_names[VAR_KIND_MAX] = {
    [VAR_KIND_UNKNOWN]   = "unknown",

    [VAR_KIND_STATE]     = "state",
    [VAR_KIND_VARIABLE]  = "variable",
    [VAR_KIND_PARAMETER] = "parameter"
};

void printErrorEqSyst(EQUATION_SYSTEM_ERROR err, EQUATION_INFO eq, double time)
{
  int indexes[2] = {1,eq.id};
  switch(err)
  {
  case ERROR_AT_TIME:
    warningStreamPrintWithEquationIndexes(OMC_LOG_NLS, omc_dummyFileInfo, 0, indexes, "Error solving nonlinear system %d at time %g", eq.id, time);
    break;
  case NO_PROGRESS_START_POINT:
    warningStreamPrintWithEquationIndexes(OMC_LOG_NLS, omc_dummyFileInfo, 0, indexes, "Solving nonlinear system %d: iteration not making progress, trying with different starting points (+%g)", eq.id, time);
    break;
  case NO_PROGRESS_FACTOR:
    warningStreamPrintWithEquationIndexes(OMC_LOG_NLS, omc_dummyFileInfo, 0, indexes, "Solving nonlinear system %d: iteration not making progress, trying to decrease factor to %g", eq.id, time);
    break;
  case IMPROPER_INPUT:
    warningStreamPrintWithEquationIndexes(OMC_LOG_NLS, omc_dummyFileInfo, 0, indexes, "improper input parameters to nonlinear eq. syst: %d at time %g", eq.id, time);
    break;
  default:
    warningStreamPrintWithEquationIndexes(OMC_LOG_NLS, omc_dummyFileInfo, 0, indexes, "Unknown equation system error: %d %d %g", err, eq.id, time);
    break;
  }
}

/**
 * @brief Free memory allocated by `read_var_info`.
 *
 * @param info  Pointer to variable info.
 */
void freeVarInfo(VAR_INFO* info)
{
  free((void*)info->info.filename);
  free((void*)info->name);
  free((void*)info->comment);
}

/**
 * @brief Split the nominal values just written to `positiveNominal` into
 * magnitude and sign.
 *
 * The solvers scale by the magnitude. It is 1.0 if the nominal is 0, inf or
 * NaN, with a warning if the model gave that value. `nominalSign` gets the
 * same number of elements.
 *
 * @param attribute  Attribute of a real variable or parameter.
 * @param name       Name of the variable, for the warning.
 */
void normalizeNominal(REAL_ATTRIBUTE *attribute, const char *name)
{
  size_t i, n = base_array_nr_of_elements(attribute->positiveNominal);
  modelica_real *nominal = (modelica_real*) attribute->positiveNominal.data;
  modelica_real *sign;
  int warned = 0;

  if (attribute->nominalSign.data == NULL || base_array_nr_of_elements(attribute->nominalSign) != n) {
    omc_array_release(&attribute->nominalSign);
    simple_alloc_1d_real_array(&attribute->nominalSign, (int) n);
  }
  sign = (modelica_real*) attribute->nominalSign.data;
  for (i = 0; i < n; i++) {
    modelica_real magnitude = fabs(nominal[i]);
    sign[i] = nominal[i] < 0 ? -1.0 : 1.0;
    if (isnormal(magnitude)) {
      nominal[i] = magnitude;
      continue;
    }
    if (attribute->useNominal && !warned) {
      warningStreamPrint(OMC_LOG_STDOUT, 0,
                         "The nominal value of %s is %g, but it must be nonzero and finite. The solvers use 1.0 instead.",
                         name, nominal[i]);
      warned = 1;
    }
    nominal[i] = 1.0;
  }
}
