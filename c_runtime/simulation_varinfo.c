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

#include "simulation_varinfo.h"

const omc_fileInfo omc_dummyFileInfo = {"",-1,-1,-1,-1,1};

void printErrorEqSyst(equationSystemError err, struct omc_equationInfo eq, double var)
{
  switch (err) {
  case ERROR_AT_TIME:
    printf("Error solving nonlinear system %s at time %g\n", eq.name, var);
    break;
  case NO_PROGRESS_START_POINT:
    printf("Solving nonlinear system %s: iteration not making progress, trying with different starting points (+%g)\n", eq.name, var);
    break;
  case NO_PROGRESS_FACTOR:
    printf("Solving nonlinear system %s: iteration not making progress, trying to decrease factor to %g\n", eq.name, var);
    break;
  case IMPROPER_INPUT:
    printf("improper input parameters to nonlinear eq. syst: %s at time %g\n", eq.name, var);
    break;
  default:
    printf("Unknown equation system error: %d %s %g\n", err, eq.name, var);
  }
}

void printInfo(FILE *stream, omc_fileInfo info)
{
  fprintf(stream, "[%s:%d:%d-%d:%d:%s] ", info.filename, info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}
