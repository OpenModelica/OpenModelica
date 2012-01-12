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

#ifdef __cplusplus
extern "C" {
#endif

void initializeXDataStruc(_X_DATA *data);

void DeinitializeXDataStruc(_X_DATA *data);

void update_DAEsystem(_X_DATA *data);

void SaveZeroCrossings(_X_DATA *data);

void copyStartValuestoInitValues(_X_DATA *data);

void printAllVars(_X_DATA *data, int ringSegment);

void overwriteOldSimulationData(_X_DATA *data);

void
restoreExtrapolationDataOld(_X_DATA *data);

void storeStartValues(_X_DATA* data);

void storeStartValuesParam(_X_DATA *data);

void storeInitialValuesParam(_X_DATA *data);

void storePreValues(_X_DATA *data);

void resetAllHelpVars(_X_DATA* data);

double getNextSampleTimeFMU(_X_DATA *data);


/* functions used in function_ZeroCrossings */
double Less(double a, double b);
double LessEq(double a, double b);
double Greater(double a, double b);
double GreaterEq(double a, double b);

#ifdef __cplusplus
}
#endif


#endif
