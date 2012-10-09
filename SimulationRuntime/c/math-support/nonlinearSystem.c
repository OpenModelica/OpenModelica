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
#include "nonlinearSolverHybrd.h"


/*! \fn allocateNonlinearSystem
 *
 *  This function allocates memory of nonlinear systems
 *
 *  \param [ref] [data]
 */
int allocateNonlinearSystem(DATA *data){

  int *size;
  int i;

  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;

  for(i=0;i<data->modelData.nNonLinearSystems;++i){
    SOLVER_DATA* solverData = (SOLVER_DATA*) malloc(sizeof(SOLVER_DATA));
    size = (int*)&(nonlinsys[i].size);

    /* allocate system data */
    nonlinsys[i].nlsx = (double*) malloc(*size*sizeof(double));
    nonlinsys[i].nlsxExtrapolation = (double*) malloc(*size*sizeof(double));
    nonlinsys[i].nlsxOld = (double*) malloc(*size*sizeof(double));
    nonlinsys[i].nlsxScaling = (double*) malloc(*size*sizeof(double));

    nonlinsys[i].solverData = (void*) solverData;

    /* allocate solver data */
    allocateHybrdData(size, &((SOLVER_DATA*)nonlinsys[i].solverData)->hybrdData);
  }

  return 0;
}

/*! \fn freeNonlinearSystem
 *
 *  Thi function frees memory of nonlinear systems.
 *
 *  \param [ref] [data]
 */
int freeNonlinearSystem(DATA *data){

  int i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;

  for(i=0;i<data->modelData.nNonLinearSystems;++i){
    free(nonlinsys[i].nlsx);
    free(nonlinsys[i].nlsxExtrapolation);
    free(nonlinsys[i].nlsxOld);
    free(nonlinsys[i].nlsxScaling);

    /* allocate solver data */
    freeHybrdData(&((SOLVER_DATA*)nonlinsys[i].solverData)->hybrdData);


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

  /* strategy for solving nonlinear system
   *
   *
   *
   */


  /* for now just use hybrd solver as before */
  success = solveHybrd(data, sysNumber);
  nonlinsys[sysNumber].solved = success;

  return 0;
}

/*! \fn check_nonlinear_solutions
 *   This function check whether some of non-linear systems
 *   are failed to solve. if one is failed it return true, otherwise false.
 *
 *  \param  [in]  [data]
 *
 *  \author wbraun
 */
int check_nonlinear_solutions(DATA *data)
{
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;
  int i,returnValue = 0;

  for(i=0;i<data->modelData.nNonLinearSystems;++i){
    if (nonlinsys[i].solved == 0){
      returnValue = 1;
      break;
    }
  }

  return returnValue;
}


