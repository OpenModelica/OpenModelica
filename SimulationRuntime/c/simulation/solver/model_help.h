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
#ifndef MODEL_HELP_H
#define MODEL_HELP_H

#ifdef __cplusplus
extern "C" {
#endif

#include "simulation_data.h"

#define ZEROCROSSING(ind,exp) { \
  data->simulationInfo.zeroCrossings[ind] = exp; \
}

#define RELATIONTOZC(res,exp1,exp2,index,op_w,op) { \
  if (index == -1){ \
  res = ((exp1) op (exp2)); \
  }else{ \
  res = data->simulationInfo.backupRelations[index];} \
}

#define SAVEZEROCROSS(res,exp1,exp2,index,op_w,op) { \
  if (index == -1){ \
  res = ((exp1) op (exp2)); \
  } else{ \
  res = ((exp1) op (exp2)); \
  data->simulationInfo.backupRelations[index] = ((exp1) op (exp2)); \
  }\
}

void initializeDataStruc(DATA *data);

void DeinitializeDataStruc(DATA *data);

void update_DAEsystem(DATA *data);

void SaveZeroCrossings(DATA *data);

void copyStartValuestoInitValues(DATA *data);

void printAllVars(DATA *data, int ringSegment);

void overwriteOldSimulationData(DATA *data);

void restoreExtrapolationDataOld(DATA *data);

void setAllVarsToStart(DATA* data);
void setAllParamsToStart(DATA *data);

void storeInitialValues(DATA *data);
void storeInitialValuesParam(DATA *data);

void storePreValues(DATA *data);

void resetAllHelpVars(DATA* data);

double getNextSampleTimeFMU(DATA *data);

void storeOldValues(DATA *data);

/* functions used in function_ZeroCrossings */
double Less(double a, double b);
double LessEq(double a, double b);
double Greater(double a, double b);
double GreaterEq(double a, double b);

#ifdef __cplusplus
}
#endif

#endif
