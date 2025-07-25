/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#if !defined(OMC_NO_STATESELECTION)

#include "stateset.h"
#include "../../util/omc_error.h"
#include "../jacobian_util.h"

/*! \fn printStateSelectionInfo
 *
 *  function prints actually information about current state selection
 *
 *  \param [in]  [data]
 *  \param [in]  [set]
 *
 *  \author wbraun
 */
void printStateSelectionInfo(DATA *data, STATE_SET_DATA *set)
{
  long k, l;

  infoStreamPrint(OMC_LOG_DSS, 0, "Select %ld state%s from %ld candidates.", set->nStates, set->nStates == 1 ? "" : "s", set->nCandidates);
  infoStreamPrint(OMC_LOG_DSS, 1, "State candidates:");
  for(k=0; k < set->nCandidates; k++)
  {
    infoStreamPrint(OMC_LOG_DSS, 0, "[%ld] %s", k+1, set->statescandidates[k]->name);
  }
  messageClose(OMC_LOG_DSS);

  infoStreamPrint(OMC_LOG_DSS, 1, "Selected state%s", set->nStates == 1 ? "" : "s");
  {
    unsigned int aid = set->A->id - data->modelData->integerVarsData[0].info.id;
    modelica_integer *Adump = &(data->localData[0]->integerVars[aid]);
    for(k=0; k < set->nStates; k++)
    {
      for(l=0; l < set->nCandidates; l++)
      {
        if (Adump[k*set->nCandidates+l] == 1)
        {
          infoStreamPrint(OMC_LOG_DSS, 0, "[%ld] %s", l+1, set->statescandidates[l]->name);
          break;
        }
      }
    }
  }
  messageClose(OMC_LOG_DSS);
}

/*! \fn initializeStateSetJacobians
 *
 *  initialize jacobians for state selection
 *
 *  \param [ref] [data] ???
 *
 *  \author ???
 */
void initializeStateSetJacobians(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  long i = 0;
  STATE_SET_DATA *set = NULL;
  JACOBIAN* jacobian;

  /* go troug all state sets*/
  for(i=0; i<data->modelData->nStateSets; i++)
  {
    set = &(data->simulationInfo->stateSetData[i]);
    jacobian = &(data->simulationInfo->analyticJacobians[set->jacobianIndex]);

    if(set->initialAnalyticalJacobian(data, threadData, jacobian))
    {
      throwStreamPrint(threadData, "can not initialze Jacobians for dynamic state selection");
    }
  }
  initializeStateSetPivoting(data);
  TRACE_POP
}

/*! \fn initializeStateSetPivoting
 *
 *  initialize pivoting data for state selection
 *
 *  \param [ref] [data] ???
 *
 *  \author ???
 */
void initializeStateSetPivoting(DATA *data)
{
  TRACE_PUSH
  long i = 0;
  long n = 0;
  STATE_SET_DATA *set = NULL;
  unsigned int aid = 0;
  modelica_integer *A = NULL;

  /* go trough all state sets */
  for(i=0; i<data->modelData->nStateSets; i++)
  {
    set = &(data->simulationInfo->stateSetData[i]);
    aid = set->A->id - data->modelData->integerVarsData[0].info.id;
    A = &(data->localData[0]->integerVars[aid]);

    memset(A, 0, set->nCandidates*set->nStates*sizeof(modelica_integer));

    /* initialize row and col indices */
    for(n=0; n<set->nDummyStates; n++)
      set->rowPivot[n] = n;

    for(n=0; n<set->nCandidates; n++)
      set->colPivot[n] = set->nCandidates-n-1;

    for(n=0; n<set->nStates; n++)
      A[n*set->nCandidates + n] = 1;  /* set A[row, col] */
  }
  TRACE_POP
}

/*! \fn freeStateSetData
 *
 *  free jacobians for state selection
 *
 *  \param [ref] [data] ???
 *
 *  \author ???
 */
void freeStateSetData(DATA *data)
{
  TRACE_PUSH
  long i=0;

  /* go through all state sets */
  for(i=0; i<data->modelData->nStateSets; i++)
  {
     STATE_SET_DATA *set = &(data->simulationInfo->stateSetData[i]);
     free(set->states);
     free(set->statescandidates);
     free(set->rowPivot);
     free(set->colPivot);
     free(set->J);
  }
  TRACE_POP
}

/*! \fn getAnalyticalJacobianSet
 *
 *  function calculates analytical jacobian
 *
 *  \param [ref] [data] ???
 *  \param [out] [index] ???
 *
 *  \author wbraun
 */
static void getAnalyticalJacobianSet(DATA* data, threadData_t *threadData, unsigned int index)
{
  TRACE_PUSH
  unsigned int i, j, k, l, ii;
  const unsigned int jacIndex = data->simulationInfo->stateSetData[index].jacobianIndex;
  JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[jacIndex]);
  const SPARSE_PATTERN* sp = jacobian->sparsePattern;

  modelica_real* jac = data->simulationInfo->stateSetData[index].J;

  /* call generic dense Jacobian */
  evalJacobian(data, threadData, jacobian, NULL, jac, TRUE);

  if(OMC_ACTIVE_STREAM(OMC_LOG_DSS_JAC))
  {
    char *buffer = (char*)malloc(sizeof(char)*jacobian->sizeCols*20);

    infoStreamPrint(OMC_LOG_DSS_JAC, 1, "jacobian %zux%zu [id: %d]", jacobian->sizeRows, jacobian->sizeCols, jacIndex);

    for(i=0; i<jacobian->sizeRows; i++)
    {
      buffer[0] = 0;
      for(j=0; j < jacobian->sizeCols; j++)
        sprintf(buffer, "%s%.5e ", buffer, jac[i*jacobian->sizeCols+j]);
      infoStreamPrint(OMC_LOG_DSS_JAC, 0, "%s", buffer);
    }
    messageClose(OMC_LOG_DSS_JAC);
    free(buffer);

  }

  TRACE_POP
}

/*! \fn setAMatrix
 *
 *  ??? desc ???
 *
 *  \param [ref] [newEnable]
 *  \param [ref] [nCandidates]
 *  \param [ref] [nStates]
 *  \param [ref] [Ainfo]
 *  \param [ref] [states]
 *  \param [ref] [statecandidates]
 *  \param [ref] [data]
 */
static void setAMatrix(modelica_integer* newEnable, modelica_integer nCandidates, modelica_integer nStates, VAR_INFO* Ainfo, VAR_INFO** states, VAR_INFO** statecandidates, DATA *data)
{
  TRACE_PUSH
  modelica_integer col;
  modelica_integer row=0;
  /* clear old values */
  unsigned int aid = Ainfo->id - data->modelData->integerVarsData[0].info.id;
  modelica_integer *A = &(data->localData[0]->integerVars[aid]);
  memset(A, 0, nCandidates*nStates*sizeof(modelica_integer));

  for(col=0; col<nCandidates; col++)
  {
    if(newEnable[col]==2)
    {
      unsigned int firstrealid = data->modelData->realVarsData[0].info.id;
      unsigned int id = statecandidates[col]->id-firstrealid;
      unsigned int sid = states[row]->id-firstrealid;
      /* set A[row, col] */
      A[row*nCandidates + col] = 1;
      /* reinit state */
      data->localData[0]->realVars[sid] = data->localData[0]->realVars[id];
      row++;
    }
  }
  TRACE_POP
}

/*! \fn comparePivot
 *
 *  ??? desc ???
 *
 *  \param [ref] [oldPivot]
 *  \param [ref] [set]
 *  \param [ref] [setIndex]
 *  \param [ref] [data]
 *  \param [ref] [switchStates]
 *  \return ???
 */
static int comparePivot(modelica_integer *oldPivot, STATE_SET_DATA *set, long setIndex, DATA *data, int switchStates)
{
  TRACE_PUSH
  modelica_integer i;
  int ret = 0;
  modelica_integer *newPivot = set->colPivot;
  modelica_integer nCandidates = set->nCandidates;
  modelica_integer nDummyStates = set->nDummyStates;
  modelica_integer nStates = set->nStates;
  VAR_INFO* A = set->A;
  VAR_INFO** states = set->states;
  VAR_INFO** statecandidates = set->statescandidates;
  modelica_integer* oldEnable = (modelica_integer*) calloc(nCandidates, sizeof(modelica_integer));
  modelica_integer* newEnable = (modelica_integer*) calloc(nCandidates, sizeof(modelica_integer));

  for(i=0; i<nCandidates; i++)
  {
    modelica_integer entry = (i < nDummyStates) ? 1: 2;
    newEnable[ newPivot[i] ] = entry;
    oldEnable[ oldPivot[i] ] = entry;
  }

  for(i=0; i<nCandidates; i++)
  {
    if(newEnable[i] != oldEnable[i])
    {
      if(switchStates)
      {
        setAMatrix(newEnable, nCandidates, nStates, A, states, statecandidates, data);
        /* debug */
        if(OMC_ACTIVE_STREAM(OMC_LOG_DSS)){
          infoStreamPrint(OMC_LOG_DSS, 1, "StateSelection Set %ld at time = %f", setIndex, data->localData[0]->timeValue);
          printStateSelectionInfo(data, set);
          messageClose(OMC_LOG_DSS);
        }
      }
      ret = -1;
      break;
    }
  }

  free(oldEnable);
  free(newEnable);

  TRACE_POP
  return ret;
}

/*! \fn stateSelectionSet
 *
 *  function to select the actual states for an individual stateSet
 *
 *  \param [ref] [data]
 *  \param [ref] [threadData]
 *  \param [in]  [reportError]
 *  \param [in]  [switchStates] flag for switch states, function does switch only if this switchStates = 1
 *  \param [in]  [setIndex] unique index of the stateSet
 *  \param [in]  [globalres] flag for discontinuous timestep in the case of a state switch for all sets before
 *  \return      [globalres] flag for discontinuous timestep in the case of a state switch for at least one set
 *
 *  \author Abdelhak / Frenkel TUD
 */
int stateSelectionSet(DATA *data, threadData_t *threadData, char reportError, int switchStates, long setIndex, int globalres)
{
    long j=0;
    long k=0;
    long l=0;
    long m=0;
    int res=0;
    STATE_SET_DATA *set = &(data->simulationInfo->stateSetData[setIndex]);
    modelica_integer* oldColPivot = (modelica_integer*) malloc(set->nCandidates * sizeof(modelica_integer));
    modelica_integer* oldRowPivot = (modelica_integer*) malloc(set->nDummyStates * sizeof(modelica_integer));

    /* generate jacobian, stored in set->J */
    getAnalyticalJacobianSet(data, threadData, setIndex);

    /* call pivoting function to select the states */
    memcpy(oldColPivot, set->colPivot, set->nCandidates*sizeof(modelica_integer));
    memcpy(oldRowPivot, set->rowPivot, set->nDummyStates*sizeof(modelica_integer));
    if((pivot(set->J, set->nDummyStates, set->nCandidates, set->rowPivot, set->colPivot) != 0) && reportError)
    {
      /* error, report the matrix and the time */

      char *buffer = (char*)malloc(sizeof(char)*data->simulationInfo->analyticJacobians[set->jacobianIndex].sizeCols*100+5);
      warningStreamPrint(OMC_LOG_DSS, 1, "jacobian %zux%zu [id: %ld]", data->simulationInfo->analyticJacobians[set->jacobianIndex].sizeRows, data->simulationInfo->analyticJacobians[set->jacobianIndex].sizeCols, set->jacobianIndex);

      for(m=0; m < data->simulationInfo->analyticJacobians[set->jacobianIndex].sizeRows; m++)
      {
        buffer[0] = 0;
        for(j=0; j < data->simulationInfo->analyticJacobians[set->jacobianIndex].sizeCols; j++)
          sprintf(buffer, "%s%.5e ", buffer, set->J[m*data->simulationInfo->analyticJacobians[set->jacobianIndex].sizeCols+j]);
        warningStreamPrint(OMC_LOG_DSS, 0, "%s", buffer);
      }

      free(buffer);

      for(m=0; m<set->nCandidates; m++)
        warningStreamPrint(OMC_LOG_DSS, 0, "%s", set->statescandidates[m]->name);
      messageClose(OMC_LOG_DSS);

      throwStreamPrint(threadData, "Error, singular Jacobian for dynamic state selection at time %f\nUse -lv LOG_DSS_JAC to get the Jacobian", data->localData[0]->timeValue);
    }
    /* if we have a new set throw event for reinitialization
       and set the A matrix for set.x=A*(states) */
    res = comparePivot(oldColPivot, set, setIndex, data, switchStates);
    if(!switchStates)
    {
      memcpy(set->colPivot, oldColPivot, set->nCandidates*sizeof(modelica_integer));
      memcpy(set->rowPivot, oldRowPivot, set->nDummyStates*sizeof(modelica_integer));
    }
    if(res)
      globalres = 1;

    free(oldColPivot);
    free(oldRowPivot);
    return globalres;
}

/*! \fn stateSelection
 *
 *  function to select the actual states
 *
 *  \param [ref] [data]
 *  \param [ref] [threadData]
 *  \param [in]  [reportError]
 *  \param [in]  [switchStates] flag for switch states, function does switch only if this switchStates = 1
 *  \return      [globalres] flag for discontinuous timestep in the case of a state switch for at least one set
 *
 *  \author Frenkel TUD
 */
int stateSelection(DATA *data, threadData_t *threadData, char reportError, int switchStates)
{
  TRACE_PUSH
  long i=0;
  int globalres=0;

  /* go through all the state sets */
  for(i=0; i<data->modelData->nStateSets; i++)
  {
    globalres = stateSelectionSet(data, threadData, reportError, switchStates, i, globalres);
  }

  TRACE_POP
  return globalres;
}

#endif /* OMC_NO_STATESELECTION */
