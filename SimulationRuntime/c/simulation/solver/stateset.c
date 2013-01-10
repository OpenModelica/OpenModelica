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

#include "stateset.h"
#include "matrix.h"
#include "omc_error.h"

#include <memory.h>


/* initialize jacobians for state selection */
void initializeStateSetJacobians(DATA *data)
{
  long i=0;
  modelica_integer n=0;
  /* go troug all state sets*/
  for (i=0;i<data->modelData.nStateSets;i++)
  {
    STATE_SET_DATA *set = &(data->simulationInfo.stateSetData[i]);
    if(set->initialAnalyticalJacobian(data))
    {
      THROW("Error, can not initialze Jacobians for dynamic state selection");
    }
    initializeStateSetPivoting(data);
  }
}

/* initialize pivoting data for state selection */
void initializeStateSetPivoting(DATA *data)
{
  long i=0;
  modelica_integer n=0;
  /* go troug all state sets*/
  for (i=0;i<data->modelData.nStateSets;i++)
  {
    STATE_SET_DATA *set = &(data->simulationInfo.stateSetData[i]);
    unsigned int aid = set->A->id - data->modelData.integerVarsData[0].info.id;
    modelica_integer *A = &(data->localData[0]->integerVars[aid]);
    memset(A,0,set->nCandidates*set->nStates*sizeof(modelica_integer));
    /* initialize row and col indizes */
    for (n=0;n<set->nDummyStates;n++)
    {
      set->rowPivot[n] = n;
    }
    for (n=0;n<set->nCandidates;n++)
    {
      set->colPivot[n] = set->nCandidates-n-1;
    }
    for (n=0;n<set->nStates;n++)
    {
      /* set A[row,col] */
      set_matrix_elt(A,n,n,set->nStates,1);
    }
  }
}

/*! \fn getAnalyticalJacobian
 *
 *  function calculates analytical jacobian
 *
 *  \param  [ref]  [data]
 *  \param  [out]  [jac]
 *
 *  \author wbraun
 *
 */
void getAnalyticalJacobianSet(DATA* data, unsigned int index)
{
  unsigned int i,j,k,l,ii;
  unsigned int jacIndex = data->simulationInfo.stateSetData[index].jacobianIndex;
  unsigned int nrows = data->simulationInfo.analyticJacobians[jacIndex].sizeRows;
  unsigned int ncols = data->simulationInfo.analyticJacobians[jacIndex].sizeCols;
  double* jac = data->simulationInfo.stateSetData[index].J;

  /* set all elements to zero */
  memset(jac, 0, (nrows*ncols*sizeof(double)));

  for(i=0; i < data->simulationInfo.analyticJacobians[jacIndex].sparsePattern.maxColors; i++)
  {
    for(ii=0; ii < data->simulationInfo.analyticJacobians[jacIndex].sizeCols; ii++)
      if(data->simulationInfo.analyticJacobians[jacIndex].sparsePattern.colorCols[ii]-1 == i)
        data->simulationInfo.analyticJacobians[jacIndex].seedVars[ii] = 1;

    if(DEBUG_STREAM(LOG_DSSJAC)){
      INFO(LOG_DSSJAC,"Caluculate one col:\n");
      for(l=0;  l < data->simulationInfo.analyticJacobians[jacIndex].sizeCols;l++)
        INFO2(LOG_DSSJAC,"seed: data->simulationInfo.analyticJacobians[index].seedVars[%d]= %f",l,data->simulationInfo.analyticJacobians[jacIndex].seedVars[l]);
    }

    ((data->simulationInfo.stateSetData[index].analyticalJacobianColumn))(data);

    for(j = 0; j < data->simulationInfo.analyticJacobians[jacIndex].sizeCols; j++)
    {
      if(data->simulationInfo.analyticJacobians[jacIndex].seedVars[j] == 1)
      {
        if(j==0)
          ii = 0;
        else
          ii = data->simulationInfo.analyticJacobians[jacIndex].sparsePattern.leadindex[j-1];
        INFO2(LOG_DSSJAC," take for %d -> %d\n",j,ii);
        while(ii < data->simulationInfo.analyticJacobians[jacIndex].sparsePattern.leadindex[j])
        {
          l  = data->simulationInfo.analyticJacobians[jacIndex].sparsePattern.index[ii];
          k  = j*data->simulationInfo.analyticJacobians[jacIndex].sizeRows + l;
          jac[k] = data->simulationInfo.analyticJacobians[jacIndex].resultVars[l];
          INFO7(LOG_DSSJAC,"write %d. in jac[%d]-[%d,%d]=%f from col[%d]=%f",ii,k,l,j,jac[k],l,data->simulationInfo.analyticJacobians[jacIndex].resultVars[l]);
          ii++;
        };
      }
    }
    for(ii=0; ii < data->simulationInfo.analyticJacobians[jacIndex].sizeCols; ii++)
      if(data->simulationInfo.analyticJacobians[jacIndex].sparsePattern.colorCols[ii]-1 == i) data->simulationInfo.analyticJacobians[jacIndex].seedVars[ii] = 0;

  }
  if(DEBUG_STREAM(LOG_DSS))
  {
    INFO(LOG_DSS,"Print jac:");
    for(i=0;  i < data->simulationInfo.analyticJacobians[jacIndex].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo.analyticJacobians[jacIndex].sizeCols;j++)
        printf("% .5e ",jac[i*data->simulationInfo.analyticJacobians[jacIndex].sizeCols+j]);
      printf("\n");
    }
  }
}

void setAMatrix(modelica_integer* newEnable, modelica_integer nCandidates, modelica_integer nStates, VAR_INFO* Ainfo, VAR_INFO** states, VAR_INFO** statecandidates, DATA *data)
{
  modelica_integer col;
  modelica_integer row=0;
  /* clear old values */
  unsigned int aid = Ainfo->id - data->modelData.integerVarsData[0].info.id;
  modelica_integer *A = &(data->localData[0]->integerVars[aid]);
  memset(A,0,nCandidates*nStates*sizeof(modelica_integer));

  for (col=0;col<nCandidates;col++)
  {
    if (newEnable[col]==2)
    {
      unsigned int firstrealid = data->modelData.realVarsData[0].info.id;
      unsigned int id = statecandidates[col]->id-firstrealid;
      unsigned int sid = states[row]->id-firstrealid;
      INFO1(LOG_DSS," select %s\n",statecandidates[col]->name);
      /* set A[row,col] */
      set_matrix_elt(A,row,col,nStates,1);
      /* reinit state */
      data->localData[0]->realVars[sid] = data->localData[0]->realVars[id];
      row++;
    }
  } 
}

int comparePivot(modelica_integer *oldPivot, modelica_integer *newPivot, modelica_integer nCandidates, modelica_integer nDummyStates, modelica_integer nStates, VAR_INFO* A, VAR_INFO** states, VAR_INFO** statecandidates, DATA *data)
{
  modelica_integer i;
  int ret = 0;
  modelica_integer* oldEnable = (modelica_integer*) calloc(nCandidates,sizeof(modelica_integer));
  modelica_integer* newEnable = (modelica_integer*) calloc(nCandidates,sizeof(modelica_integer));

  for (i=0; i<nCandidates; i++)
  {
    modelica_integer entry = (i < nDummyStates) ? 1: 2;
    newEnable[ newPivot[i] ] = entry;
    oldEnable[ oldPivot[i] ] = entry;
  }

  for (i=0; i<nCandidates; i++)
  {
    if (newEnable[i] != oldEnable[i])
    {
      INFO1(LOG_DSS,"Select new States at time %f:",data->localData[0]->timeValue);
      ret = -1;
      break;
    }
  }

  if (ret)
  {
    setAMatrix(newEnable,nCandidates,nStates,A,states,statecandidates,data);
  }

  free(oldEnable);
  free(newEnable);

  return ret;
}

/*! \fn stateSelection
 *
 *  function to select the actual states
 *
 *  \param  [DATA]  [data]
 *
 *  \author Frenkel TUD
 *
 */
int stateSelection(DATA *data)
{
  long i=0;
  long j=0;
  int globalres=0;
  /* go troug all state sets*/
  for (i=0;i<data->modelData.nStateSets;i++)
  {
    int res=0;
    STATE_SET_DATA *set = &(data->simulationInfo.stateSetData[i]);
    modelica_integer* oldColPivot = (modelica_integer*) calloc(set->nCandidates,sizeof(modelica_integer));
    /* generate jacobian, stored in set->J */
    getAnalyticalJacobianSet(data,i);
    /* call pivoting function to select the states */
    memcpy(oldColPivot,set->colPivot,set->nCandidates*sizeof(modelica_integer));
    if (pivot(set->J,set->nDummyStates,set->nCandidates,set->rowPivot,set->colPivot) != 0)
    {
      /* error, report the matrix and the time */
      for(i=0;  i < data->simulationInfo.analyticJacobians[set->jacobianIndex].sizeRows;i++)
      {
        for(j=0;  j < data->simulationInfo.analyticJacobians[set->jacobianIndex].sizeCols;j++)
          printf("% .5e ",set->J[i*data->simulationInfo.analyticJacobians[set->jacobianIndex].sizeCols+j]);
        printf("\n");
      }
      for (i=0;i<set->nCandidates;i++)
      {
        printf("%s\n",set->statescandidates[i]->name);
      }
      THROW1("Error, singular Jacobian for dynamic state selection at time %f\nUse -lv LOG_DSSJAC to get the Jacobian\n",data->localData[0]->timeValue);
    }
    /* if we have a new set throw event for reinitialization 
       and set the A matrix for set.x=A*(states) */
    res = comparePivot(oldColPivot,set->colPivot,set->nCandidates,set->nDummyStates,set->nStates,set->A,set->states,set->statescandidates,data);
    if (res)
    {
      INFO(LOG_DSS,"Select new States:");
      globalres = 1;
    }
    free(oldColPivot);
  }
  return globalres;
}
