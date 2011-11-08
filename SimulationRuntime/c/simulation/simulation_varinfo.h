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

#ifndef _SIMULATION_VARINFO_H
#define _SIMULATION_VARINFO_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  const char* filename;
  int lineStart;
  int colStart;
  int lineEnd;
  int colEnd;
  int readonly;
} omc_fileInfo;

#define omc_dummyFileInfo {"",-1,-1,-1,-1,1}

struct omc_varInfo {
  int id;
  const char* name;
  const char* comment;
  const omc_fileInfo info;
};

struct omc_equationInfo {
  int id;
  const char *name;
  int numVar;
  const struct omc_varInfo** vars; /* The variables involved in the equation */
};

struct omc_functionInfo {
  int id;
  const char* name;
  const omc_fileInfo info;
};

typedef enum {ERROR_AT_TIME,NO_PROGRESS_START_POINT,NO_PROGRESS_FACTOR,IMPROPER_INPUT} equationSystemError;

void printErrorEqSyst(equationSystemError,struct omc_equationInfo,double var);

void printInfo(FILE *stream, omc_fileInfo info);

#ifdef __cplusplus
}
#endif

#endif

