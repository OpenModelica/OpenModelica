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

#include "omc_error.h"
#include "nonlinearSystem.h"
#include "kinsolSolver.h"
#include "nonlinearSolverHybrd.h"
#include "nonlinearSolverNewton.h"
#include "blaswrap.h"
#include "f2c.h"

extern doublereal enorm_(integer *n, doublereal *x);

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
      if (nonlinsys[i].initialAnalyticalJacobian(data)){
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
    if (nonlinsys[i].method == 1)
    {
      allocateNewtonData(size, &nonlinsys[i].solverData);
    }
    else
    {
      switch(data->simulationInfo.nlsMethod)
      {
      case NS_HYBRID:
        allocateHybrdData(size, &nonlinsys[i].solverData);
        break;
      case NS_KINSOL:
        nls_kinsol_allocate(data, &nonlinsys[i]);
        break;
      case NS_NEWTON:
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
 *  Thi function frees memory of nonlinear systems.
 *
 *  \param [ref] [data]
 */
int freeNonlinearSystem(DATA *data)
{
  int i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;

  for(i=0;i<data->modelData.nNonLinearSystems;++i)
  {
    free(nonlinsys[i].nlsx);
    free(nonlinsys[i].nlsxExtrapolation);
    free(nonlinsys[i].nlsxOld);
    free(nonlinsys[i].nominal);
    free(nonlinsys[i].min);
    free(nonlinsys[i].max);

    /* free solver data */
    if (nonlinsys[i].method == 1)
    {
      freeNewtonData(&nonlinsys[i].solverData);
    }
    else
    {
      switch(data->simulationInfo.nlsMethod)
      {
      case NS_HYBRID:
        freeHybrdData(&nonlinsys[i].solverData);
        break;
      case NS_KINSOL:
        nls_kinsol_free(&nonlinsys[i]);
        break;
      case NS_NEWTON:
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
 *  \param  [in]  [data]
 *                [sysNumber] index of corresponding non-linear System
 *
 *  \author wbraun
 */
int solve_nonlinear_system(DATA *data, int sysNumber)
{
  /* NONLINEAR_SYSTEM_DATA* system = &(data->simulationInfo.nonlinearSystemData[sysNumber]); */
  int success;
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
  if (nonlinsys[sysNumber].method == 1)
  {
    success = solveNewton(data, sysNumber);
  }
  else
  {
    switch(data->simulationInfo.nlsMethod)
    {
    case NS_HYBRID:
      success = solveHybrd(data, sysNumber);
      break;
    case NS_KINSOL:
      success = nonlinearSolve_kinsol(data, sysNumber);
      break;
    case NS_NEWTON:
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
 *   This function check whether some of non-linear systems
 *   are failed to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param  [in]  [data]
 *
 *  \author wbraun
 */
int check_nonlinear_solutions(DATA *data)
{
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;
  int i;

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
    if(nonlinsys[i].solved == 0)
      return 1;

  return 0;
}

/*! \fn extraPolate
 *   This function extrapolates linear next value from
 *   the both old values,
 *
 *  \param  [in]  [data]
 *
 *  \author wbraun
 */
double extraPolate(DATA *data, double old1, double old2)
{
  double retValue;

  if (data->localData[1]->timeValue == data->localData[2]->timeValue)
  {
    retValue = old1;
  }
  else
  {
    retValue = old2 + ((data->localData[0]->timeValue - data->localData[2]->timeValue)/(data->localData[1]->timeValue - data->localData[2]->timeValue)) * (old1-old2);
  }

  return retValue;
}
