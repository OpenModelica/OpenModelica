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

#include "omc_error.h"
#include "simulation_data.h"
#include "varinfo.h"


void printErrorEqSyst(equationSystemError err, EQUATION_INFO eq, double time)
{
  switch(err)
  {
  case ERROR_AT_TIME:
    WARNING2(LOG_NLS, "Error solving nonlinear system %s at time %g", eq.name, time);
    break;
  case NO_PROGRESS_START_POINT:
    WARNING2(LOG_NLS, "Solving nonlinear system %s: iteration not making progress, trying with different starting points (+%g)", eq.name, time);
    break;
  case NO_PROGRESS_FACTOR:
    WARNING2(LOG_NLS, "Solving nonlinear system %s: iteration not making progress, trying to decrease factor to %g", eq.name, time);
    break;
  case IMPROPER_INPUT:
    WARNING2(LOG_NLS, "improper input parameters to nonlinear eq. syst: %s at time %g", eq.name, time);
    break;
  default:
    WARNING3(LOG_NLS, "Unknown equation system error: %d %s %g", err, eq.name, time);
    break;
  }
}

void freeVarInfo(VAR_INFO* info)
{
  free((void*)info->info.filename);
  free((void*)info->name);
  free((void*)info->comment);
}

