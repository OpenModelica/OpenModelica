/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2018, Open Source Modelica Consortium (OSMC),
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

#include "arrayIndex.h"

#include "dae_mode.h"

#ifdef __cplusplus
extern "C" {
#endif

/* EVAL_DYNAMIC = 1000 */
const int EVAL_DYNAMIC = 1;
/* EVAL_ALGEBRAIC = 0100 */
const int EVAL_ALGEBRAIC = 2;
/* EVAL_ZEROCROSS = 0010 */
const int EVAL_ZEROCROSS = 4;
/* EVAL_DISCRETE = 0001 */
const int EVAL_DISCRETE = 8;
/* EVAL_ALL = 1111 */
const int EVAL_ALL = 15;


/*! \fn void evaluateDAEResiduals_wrapperEventUpdate
 *
 * wrapper function of the main evaluation function for DAE mode
 */
int evaluateDAEResiduals_wrapperEventUpdate(DATA* data, threadData_t* threadData)
{
  int retVal;

  data->simulationInfo->discreteCall = 1;
  retVal = data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_DISCRETE);
  data->simulationInfo->discreteCall = 0;

  return retVal;
}

/*! \fn void evaluateDAEResiduals_wrapperZeroCrossingsEquations
 *
 * wrapper function of the ZeroCrossing function for DAE mode
 */
int evaluateDAEResiduals_wrapperZeroCrossingsEquations(DATA* data, threadData_t* threadData)
{
  int retVal;
  retVal = data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_ZEROCROSS);

  return retVal;
}

/*! \fn void getAlgebraicDAEVarNominals
 *
 *  collects DAE mode algebraic nominal values from modelData
 */
void getAlgebraicDAEVarNominals(DATA* data, double *algebraicNominals)
{
  int i;

  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    algebraicNominals[i] = getNominalFromScalarIdx(data->simulationInfo, data->modelData, daeModeData->algIndexes[i]);
  }
}

/*! \fn getAlgebraicVars
 *
 *  function obtains algebraic variable values for DAEmode
 */
void getAlgebraicDAEVars(DATA *data, double* algebraic)
{
  int i;
  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    algebraic[i] = data->localData[0]->realVars[daeModeData->algIndexes[i]];
  }
}

/*! \fn setAlgebraicVars
 *
 *  function set algebraic variable values for DAEmode
 */
void setAlgebraicDAEVars(DATA *data, double* algebraic)
{
  int i;
  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    data->localData[0]->realVars[daeModeData->algIndexes[i]] = algebraic[i];
  }
}

#ifdef __cplusplus
}
#endif
