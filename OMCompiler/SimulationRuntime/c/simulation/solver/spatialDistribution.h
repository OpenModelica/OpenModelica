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

/** @file
 * For each step:
 * 1. Save the model state. Save the spatial history with spatialDistributionStateWords.
 * 2. Call spatialDistributionNeedsHistory(data, TRUE) to clear the missing history flag.
 *    During the step, spatialDistribution reads saved history. spatialDistributionZeroCrossing gives event indicators.
 * 3. Accept the step and find any events before saving new history.
 *    storeSpatialDistributionStep updates the inlet values and saves the history.
 *    If the point was already evaluated, the generated store callback calls storeSpatialDistribution directly.
 *
 * If history is missing: reject the step. Restore the model state and call setSpatialDistributionStateWords to restore history.
 * Clear the error and the missing history flag. Restart the solver with a smaller step.
 *
 * If an event is found: save the values before the event, run event iteration, then save the values after the event.
 * Use the same position for both history stores.
 * spatialDistributionStoresSolverSteps checks if the solver can store history at its internal steps.
 * If it cannot, the outer driver must find events before storing history.
 */

#include "../../simulation_data.h"
#include "../../util/doubleEndedList.h"

#ifdef __cplusplus
  extern "C" {
#endif

typedef enum SPATIAL_DISTRIBUTION_STEP_STATUS {
  SPATIAL_DISTRIBUTION_STEP_OK = 0,
  SPATIAL_DISTRIBUTION_STEP_MISSING_HISTORY,  /* a read went past the stored history */
  SPATIAL_DISTRIBUTION_STEP_STORE_FAILED      /* storing the accepted step failed */
} SPATIAL_DISTRIBUTION_STEP_STATUS;

SPATIAL_DISTRIBUTION_DATA* allocSpatialDistribution(unsigned int nSpatialDistributions);
modelica_boolean spatialDistributionStoresSolverSteps(DATA* data, modelica_boolean solverRootFinding);
modelica_boolean spatialDistributionNeedsHistory(DATA* data, modelica_boolean reset);
int storeSpatialDistributionStep(DATA* data, threadData_t* threadData);
SPATIAL_DISTRIBUTION_STEP_STATUS spatialDistributionAfterSolverCall(DATA* data, threadData_t* threadData, modelica_boolean storeSolverSteps, modelica_boolean intermediateStep);
void freeSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistributionData, unsigned int nSpatialDistributions);
void initSpatialDistribution(DATA* data, threadData_t* threadData, unsigned int index, real_array* initialPoints, real_array* initialValues, unsigned int length);
void storeSpatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double in0, double in1, double posX, modelica_boolean isPositiveVelocity) ;
double spatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double posX, modelica_boolean isPositiveVelocity, double* out1);
double spatialDistributionZeroCrossing (DATA* data, threadData_t *threadData, unsigned int index, unsigned int relationIndex, double posX, modelica_boolean isPositiveVelocity);

void printTransportedQuantity(void* data, int stream, void* nodePointer);
size_t spatialDistributionStateWords(DATA* data, double* out);
long setSpatialDistributionStateWords(DATA* data, const double* w, size_t len, int apply);

#ifdef __cplusplus
  }
#endif
