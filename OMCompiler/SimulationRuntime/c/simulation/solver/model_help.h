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

#include "../../simulation_data.h"

extern int maxEventIterations;
extern double linearSparseSolverMaxDensity;
extern int linearSparseSolverMinSize;
extern double nonlinearSparseSolverMaxDensity;
extern int nonlinearSparseSolverMinSize;
extern double newtonXTol;
extern double newtonFTol;
extern double maxStepFactor;
extern double steadyStateTol;
extern const size_t SIZERINGBUFFER;
extern int compiledInDAEMode;
extern int compiledWithSymSolver;
extern double numericalDifferentiationDeltaXlinearize;
extern double numericalDifferentiationDeltaXsolver;
extern double homAdaptBend;
extern double homHEps;
extern int homMaxLambdaSteps;
extern int homMaxNewtonSteps;
extern int homMaxTries;
extern double homTauDecreasingFactor;
extern double homTauDecreasingFactorPredictor;
extern double homTauIncreasingFactor;
extern double homTauIncreasingThreshold;
extern double homTauMax;
extern double homTauMin;
extern double homTauStart;
extern int homBacktraceStrategy;

void initializeDataStruc(DATA *data, threadData_t *threadData);

void deInitializeDataStruc(DATA *data);

void updateDiscreteSystem(DATA *data, threadData_t *threadData);

void saveZeroCrossings(DATA *data, threadData_t *threadData);

void copyStartValuestoInitValues(DATA *data);

/* functions that are only used in USE_DEBUG_OUTPUT mode */
#ifdef USE_DEBUG_OUTPUT
  void printAllVarsDebug(DATA *data, int ringSegment, int stream);
  void printRelationsDebug(DATA *data, int stream);
#else
  #define printAllVarsDebug(data, ringSegment, stream) {}
  #define printRelationsDebug(data, stream) {}
#endif

void printAllVars(DATA *data, int ringSegment, int stream);
void printRelations(DATA *data, int stream);
void printZeroCrossings(DATA *data, int stream);
void printParameters(DATA *data, int stream);
void printSparseStructure(SPARSE_PATTERN *sparsePattern, int sizeRows, int sizeCols, int stream, const char*);
modelica_boolean sparsitySanityCheck(SPARSE_PATTERN *sparsePattern, int nlsSize, int stream);

void overwriteOldSimulationData(DATA *data);
void copyRingBufferSimulationData(DATA *data, threadData_t *threadData, SIMULATION_DATA **destData, RINGBUFFER* destRing);
void printRingBufferSimulationData(RINGBUFFER* rb, DATA* data);

void restoreExtrapolationDataOld(DATA *data);

void setAllVarsToStart(DATA* data);
void setAllStartToVars(DATA* data);
void setAllParamsToStart(DATA *data);

void restoreOldValues(DATA *data);

void storePreValues(DATA *data);

void updateRelationsPre(DATA *data);

modelica_boolean checkRelations(DATA *data);

void printHysteresisRelations(DATA *data);
void activateHysteresis(DATA* data);
void storeRelations(DATA* data);
void setZCtol(double relativeTol);

int getNextSampleTimeFMU(DATA *data, double *nextSampleEvent);

void storeOldValues(DATA *data);

modelica_integer _event_integer(modelica_real x, modelica_integer index, DATA *data);
modelica_real _event_floor(modelica_real x, modelica_integer index, DATA *data);
modelica_real _event_ceil(modelica_real x, modelica_integer index, DATA *data);
modelica_integer _event_mod_integer(modelica_integer x1, modelica_integer x2, modelica_integer index, DATA *data, threadData_t *threadData);
modelica_real _event_mod_real(modelica_real x1, modelica_real x2, modelica_integer index, DATA *data, threadData_t *threadData);
modelica_integer _event_div_integer(modelica_integer x1, modelica_integer x2, modelica_integer index, DATA *data, threadData_t *threadData);
modelica_real _event_div_real(modelica_real x1, modelica_real x2, modelica_integer index, DATA *data, threadData_t *threadData);

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


/**
 * @brief Relation function for compare functions.
 *
 * Used for cases where exp1 or exp2 are discrete.
 *
 * Two cases:
 *   1. During initialization or discrete calls or not continuous mode: Use op_w(exp1,exp2) and update relations[index] and return result in res.
 *   2. Else (Not discrete call or in continuous mode) : Only return pre-value of relation in res
 *
 * @param[in]   data      Pointer to data struct
 * @param[out]  res       Gets overwritten with result of relation.
 * @param[in]   exp1      First value (left side of relation).
 * @param[in]   exp2      Second value (right side of relation).
 * @param[in]   index     Index of relation in data->simulationInfo->relations.
 * @param[in]   op_w      Comparison function, e.g. Less.
 */
static inline void relation(DATA* data, modelica_boolean* res, double exp1, double exp2, int index, modelica_boolean(*op_w)(double, double))
{
  if(data->simulationInfo->initial || !(data->simulationInfo->discreteCall == 0 || data->simulationInfo->solveContinuous) )
  {
    *res = op_w(exp1,exp2);
    data->simulationInfo->relations[index] = *res;
  }
  else
  {
    *res = data->simulationInfo->relationsPre[index];
  }
}

/**
 * @brief Relation hysteresis function for compare functions.
 *
 * Used for cases where exp1 and exp2 are continuous.
 *
 * Three cases:
 *   1. During initialization: Use op_w(exp1,exp2) and update relations[index] and return result in res.
 *   2. No descrete call or in continuous case: Only return pre-value of relation in res
 *   3. Else (events, zero-crossing): Use op_w_zc(exp1,exp2,...) to update relations[index] and return result in res.
 *
 * @param[in]   data      Pointer to data struct
 * @param[out]  res       Gets overwritten with result of relation.
 * @param[in]   exp1      First value (left side of relation).
 * @param[in]   exp2      Second value (right side of relation).
 * @param[in]   index     Index of relation in data->simulationInfo->relations.
 * @param[in]   op_w      Comparison function, e.g. Less.
 * @param[in]   op_w_zc   Matching comparison function of op_w for zero-crossing, e.g. LessZC.
 */
static inline void relationhysteresis(DATA* data, modelica_boolean* res, double exp1, double exp2, int index, modelica_boolean(*op_w)(double, double), modelica_boolean(*op_w_zc)(double, double, modelica_boolean))
{
  if(data->simulationInfo->initial)
  {
    *res = op_w(exp1,exp2);
    data->simulationInfo->relations[index] = *res;
  }
  else if(data->simulationInfo->discreteCall == 0 || data->simulationInfo->solveContinuous)
  {
    *res = data->simulationInfo->relationsPre[index];
  }
  else
  {
    *res = op_w_zc(exp1, exp2, data->simulationInfo->storedRelations[index]);
    data->simulationInfo->relations[index] = *res;
  }
}

extern int measure_time_flag;

#ifdef __cplusplus
}
#endif

#endif
