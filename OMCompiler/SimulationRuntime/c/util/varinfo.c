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

#include "omc_error.h"
#include "../simulation_data.h"
#include "varinfo.h"


void printErrorEqSyst(EQUATION_SYSTEM_ERROR err, EQUATION_INFO eq, double time)
{
  int indexes[2] = {1,eq.id};
  switch(err)
  {
  case ERROR_AT_TIME:
    warningStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "Error solving nonlinear system %d at time %g", eq.id, time);
    break;
  case NO_PROGRESS_START_POINT:
    warningStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "Solving nonlinear system %d: iteration not making progress, trying with different starting points (+%g)", eq.id, time);
    break;
  case NO_PROGRESS_FACTOR:
    warningStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "Solving nonlinear system %d: iteration not making progress, trying to decrease factor to %g", eq.id, time);
    break;
  case IMPROPER_INPUT:
    warningStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "improper input parameters to nonlinear eq. syst: %d at time %g", eq.id, time);
    break;
  default:
    warningStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "Unknown equation system error: %d %d %g", err, eq.id, time);
    break;
  }
}

void freeVarInfo(VAR_INFO* info)
{
  free((void*)info->info.filename);
  free((void*)info->name);
  free((void*)info->comment);
}

