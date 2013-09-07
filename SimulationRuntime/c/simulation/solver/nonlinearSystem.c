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

/*! \file nonlinearSystem.c
 */

#include <math.h>
#include <string.h>

#include "omc_error.h"
#include "nonlinearSystem.h"
#include "kinsolSolver.h"
#include "nonlinearSolverHybrd.h"
#include "nonlinearSolverNewton.h"
#include "simulation_info_xml.h"
#include "blaswrap.h"
#include "f2c.h"
#include "simulation_runtime.h"

/* nonlinear JumpBuffer */
jmp_buf nonlinearJmpbuf;

extern doublereal enorm_(integer *n, doublereal *x);


const char *NLS_NAME[NLS_MAX+1] = {
  "NLS_UNKNOWN",

  /* NLS_HYBRID */       "hybrid",
  /* NLS_KINSOL */       "kinsol",
  /* NLS_NEWTON */       "newton",

  "NLS_MAX"
};

const char *NLS_DESC[NLS_MAX+1] = {
  "unknown",

  /* NLS_HYBRID */       "default method",
  /* NLS_KINSOL */       "sundials/kinsol",
  /* NLS_NEWTON */       "Newton Raphson",

  "NLS_MAX"
};

/*! \fn int allocateNonlinearSystem(DATA *data)
 *
 *  This function allocates memory for all nonlinear systems.
 *
 *  \param [ref] [data]
 */
int allocateNonlinearSystem(DATA *data)
{
  int i;
  int size;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo.nonlinearSystemData;

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
  {
    size = nonlinsys[i].size;

    /* check if residual function pointer are valid */
    ASSERT(nonlinsys[i].residualFunc, "residual function pointer is invalid" );

    /* check if analytical jacobian is created */
    if(nonlinsys[i].jacobianIndex != -1){
      ASSERT(nonlinsys[i].analyticalJacobianColumn, "jacobian function pointer is invalid" );
      if(nonlinsys[i].initialAnalyticalJacobian(data))
      {
        nonlinsys[i].jacobianIndex = -1;
      }
    }

    /* allocate system data */
    nonlinsys[i].nlsx = (double*) malloc(size*sizeof(double));
    nonlinsys[i].nlsxExtrapolation = (double*) malloc(size*sizeof(double));
    nonlinsys[i].nlsxOld = (double*) malloc(size*sizeof(double));

    nonlinsys[i].nominal = (double*) malloc(size*sizeof(double));
    nonlinsys[i].min = (double*) malloc(size*sizeof(double));
    nonlinsys[i].max = (double*) malloc(size*sizeof(double));

    nonlinsys[i].initializeStaticNLSData(data, &nonlinsys[i]);

    /* allocate solver data */
    if(nonlinsys[i].method == 1)
    {
      allocateNewtonData(size, &nonlinsys[i].solverData);
    }
    else
    {
      switch(data->simulationInfo.nlsMethod)
      {
      case NLS_HYBRID:
        allocateHybrdData(size, &nonlinsys[i].solverData);
        break;
      case NLS_KINSOL:
        nls_kinsol_allocate(data, &nonlinsys[i]);
        break;
      case NLS_NEWTON:
        allocateNewtonData(size, &nonlinsys[i].solverData);
        break;
      default:
        THROW("unrecognized nonlinear solver");
      }
    }

  }

  return 0;
}

/*! \fn freeNonlinearSystem
 *
 *  This function frees memory of nonlinear systems.
 *
 *  \param [ref] [data]
 */
int freeNonlinearSystem(DATA *data)
{
  int i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
  {
    free(nonlinsys[i].nlsx);
    free(nonlinsys[i].nlsxExtrapolation);
    free(nonlinsys[i].nlsxOld);
    free(nonlinsys[i].nominal);
    free(nonlinsys[i].min);
    free(nonlinsys[i].max);

    /* free solver data */
    if(nonlinsys[i].method == 1)
    {
      freeNewtonData(&nonlinsys[i].solverData);
    }
    else
    {
      switch(data->simulationInfo.nlsMethod)
      {
      case NLS_HYBRID:
        freeHybrdData(&nonlinsys[i].solverData);
        break;
      case NLS_KINSOL:
        nls_kinsol_free(&nonlinsys[i]);
        break;
      case NLS_NEWTON:
        freeNewtonData(&nonlinsys[i].solverData);
        break;
      default:
        THROW("unrecognized nonlinear solver");
      }
    }
    free(nonlinsys[i].solverData);
  }

  return 0;
}

/*! \fn solve non-linear systems
 *
 *  \param [in]  [data]
 *  \param [in]  [sysNumber] index of corresponding non-linear System
 *
 *  \author wbraun
 */
int solve_nonlinear_system(DATA *data, int sysNumber)
{
  /* NONLINEAR_SYSTEM_DATA* system = &(data->simulationInfo.nonlinearSystemData[sysNumber]); */
  int success, saveJumpState;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;

  data->simulationInfo.currentNonlinearSystemIndex = sysNumber;

  /* enable to avoid division by zero */
  data->simulationInfo.noThrowDivZero = 1;

  /* strategy for solving nonlinear system
   *
   *
   *
   */

  /* for now just use hybrd solver as before */
  if(nonlinsys[sysNumber].method == 1)
  {
    success = solveNewton(data, sysNumber);
  }
  else
  {
    switch(data->simulationInfo.nlsMethod)
    {
    case NLS_HYBRID:
      saveJumpState = currectJumpState;
      currectJumpState = ERROR_NONLINEARSOLVER;
      success = solveHybrd(data, sysNumber);
      currectJumpState = saveJumpState;
      break;
    case NLS_KINSOL:
      success = nonlinearSolve_kinsol(data, sysNumber);
      break;
    case NLS_NEWTON:
      success = solveNewton(data, sysNumber);
      break;
    default:
      THROW("unrecognized nonlinear solver");
    }
  }
  nonlinsys[sysNumber].solved = success;

  /* enable to avoid division by zero */
  data->simulationInfo.noThrowDivZero = 0;

  return 0;
}

/*! \fn check_nonlinear_solutions
 *
 *   This function check whether some of non-linear systems
 *   are failed to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *
 *  \author wbraun
 */
int check_nonlinear_solutions(DATA *data, int printFailingSystems)
{
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;
  long i, j;

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
    if(nonlinsys[i].solved == 0)
    {
      if(printFailingSystems)
      {
        WARNING2(LOG_NLS, "nonlinear system fails: %s at t=%g", modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).name, data->localData[0]->timeValue);
        INDENT(LOG_NLS);
        if(data->simulationInfo.initial)
        {
          WARNING(LOG_NLS, "proper start-values for some of the following iteration variables might help");
          INDENT(LOG_NLS);
          for(j=0; j<modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).numVar; ++j)
          {
            int done=0;
            long k;
            const MODEL_DATA *mData = &(data->modelData);
            for(k=0; k<mData->nVariablesReal && !done; ++k)
            {
              if(!strcmp(mData->realVarsData[k].info.name, modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).vars[j]->name))
              {
                done = 1;
                WARNING4(LOG_NLS, "[%ld] Real %s(start=%g, nominal=%g)", j+1,
                                                                         mData->realVarsData[k].info.name,
                                                                         mData->realVarsData[k].attribute.start,
                                                                         mData->realVarsData[k].attribute.nominal);
              }
            }
            if(!done)
              WARNING2(LOG_NLS, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).vars[j]->name);
          }
          RELEASE(LOG_NLS);
        }
        else
          for(j=0; j<modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).numVar; ++j)
            WARNING2(LOG_NLS, "[%ld] Real %s", j+1, modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).vars[j]->name);
        RELEASE(LOG_NLS);
      }
      return 1;
    }

  return 0;
}

/*! \fn extraPolate
 *   This function extrapolates linear next value from
 *   the both old values,
 *
 *  \param [in]  [data]
 *
 *  \author wbraun
 */
double extraPolate(DATA *data, double old1, double old2)
{
  double retValue;

  if(data->localData[1]->timeValue == data->localData[2]->timeValue)
  {
    retValue = old1;
  }
  else
  {
    retValue = old2 + ((data->localData[0]->timeValue - data->localData[2]->timeValue)/(data->localData[1]->timeValue - data->localData[2]->timeValue)) * (old1-old2);
  }

  return retValue;
}
