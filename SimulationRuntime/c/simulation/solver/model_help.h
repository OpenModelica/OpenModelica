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
  gout[ind] = exp; \
}

#define RELATION(res,exp1,exp2,index,op_w) { \
  if (data->simulationInfo.discreteCall == 0){ \
    res = data->simulationInfo.backupRelationsPre[index]; \
  } else{ \
    if (data->simulationInfo.solveContinuous){ \
      res = data->simulationInfo.backupRelationsPre[index]; \
      data->simulationInfo.backupRelations[index] = ((op_w)((exp1),(exp2))); \
    } else { \
      res = ((op_w)((exp1),(exp2))); \
      data->simulationInfo.backupRelations[index] = res; \
    }\
  }\
}

#define RELATIONHYSTERESIS(res,exp1,exp2,index,op_w) { \
  if (data->simulationInfo.discreteCall == 0){ \
    res = data->simulationInfo.backupRelationsPre[index]; \
  } else{ \
    if (data->simulationInfo.solveContinuous){ \
      res = data->simulationInfo.backupRelationsPre[index]; \
      data->simulationInfo.backupRelations[index] = ((op_w##ZC)((exp1),(exp2),data->simulationInfo.backupRelationsPre[index])); \
    } else { \
      res = ((op_w##ZC)((exp1),(exp2),data->simulationInfo.backupRelationsPre[index])); \
      data->simulationInfo.backupRelations[index] = res; \
    }\
  }\
}


void initializeDataStruc(DATA *data);

void deInitializeDataStruc(DATA *data);

void updateDiscreteSystem(DATA *data);

void updateContinuousSystem(DATA *data);

void saveZeroCrossings(DATA *data);

void copyStartValuestoInitValues(DATA *data);

void printAllVars(DATA *data, int ringSegment);
void printParameters(DATA *data);
void printRelations(DATA *data);

void overwriteOldSimulationData(DATA *data);

void restoreExtrapolationDataOld(DATA *data);

void setAllVarsToStart(DATA* data);
void setAllParamsToStart(DATA *data);

void storePreValues(DATA *data);

void storeRelations(DATA *data);

modelica_boolean checkRelations(DATA *data);

void resetAllHelpVars(DATA* data);

double getNextSampleTimeFMU(DATA *data);

void storeOldValues(DATA *data);

/* functions used for relation which
 * are not used as zero-crossings
 */
modelica_boolean Less(double a, double b);
modelica_boolean LessEq(double a, double b);
modelica_boolean Greater(double a, double b);
modelica_boolean GreaterEq(double a, double b);

/* functions used to evaluate relation in
 * zero-crossing with hysteresis effect
 */
modelica_boolean LessZC(double a, double b, modelica_boolean);
modelica_boolean LessEqZC(double a, double b, modelica_boolean);
modelica_boolean GreaterZC(double a, double b, modelica_boolean);
modelica_boolean GreaterEqZC(double a, double b, modelica_boolean);

modelica_boolean nextVar(modelica_boolean *b, int n);

#ifdef __cplusplus
}
#endif

#endif
