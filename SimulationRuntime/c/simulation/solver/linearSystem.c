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

/*! \file linearSystem.c
 */

#include <math.h>

#include "omc_error.h"
#include "linearSystem.h"
#include "linearSolverLapack.h"
#include "blaswrap.h"
#include "f2c.h"

/*! \fn int allocatelinearSystem(DATA *data)
 *
 *  This function allocates memory for all linear systems.
 *
 *  \param [ref] [data]
 */
int allocatelinearSystem(DATA *data)
{
  int i;
  int size;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo.linearSystemData;

  for(i=0; i<data->modelData.nLinearSystems; ++i)
  {
    size = linsys[i].size;

    /* allocate system data */
    linsys[i].x = (double*) malloc(size*sizeof(double));
    linsys[i].b = (double*) malloc(size*sizeof(double));
    linsys[i].A = (double*) malloc(size*size*sizeof(double));

    /* allocate solver data */
    switch(data->simulationInfo.lsMethod)
    {
    case LS_LAPACK:
      allocateLapackData(size, &linsys[i].solverData);
      break;
    default:
      THROW("unrecognized linear solver");
    }
  }
  return 0;
}

/*! \fn freelinearSystem
 *
 *  Thi function frees memory of linear systems.
 *
 *  \param [ref] [data]
 */
int freelinearSystem(DATA *data)
{
  int i;
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;

  for(i=0;i<data->modelData.nLinearSystems;++i)
  {
    free(linsys[i].x);
    free(linsys[i].b);
    free(linsys[i].A);

    /* allocate solver data */
    switch(data->simulationInfo.lsMethod)
    {
    case LS_LAPACK:
      freeLapackData(&linsys[i].solverData);
      break;
    default:
      THROW("unrecognized linear solver");
    }

    free(linsys[i].solverData);
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
int solve_linear_system(DATA *data, int sysNumber)
{
  /* NONLINEAR_SYSTEM_DATA* system = &(data->simulationInfo.nonlinearSystemData[sysNumber]); */
  int success;
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;

  data->simulationInfo.currentLinearSystemIndex = sysNumber;

  /* for now just use lapack solver as before */
  switch(data->simulationInfo.lsMethod)
  {
  case LS_LAPACK:
    success = solveLapack(data, sysNumber);
    break;
  default:
    THROW("unrecognized linear solver");
  }
  linsys[sysNumber].solved = success;

  return 0;
}

/*! \fn check_linear_solutions
 *   This function check whether some of linear systems
 *   are failed to solve. if one is failed it return true, otherwise false.
 *
 *  \param  [in]  [data]
 *
 *  \author wbraun
 */
int check_linear_solutions(DATA *data)
{
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;
  int i,returnValue = 0;

  for(i=0;i<data->modelData.nLinearSystems;++i)
  {
    if(linsys[i].solved == 0)
    {
      returnValue = 1;
      break;
    }
  }

  return returnValue;
}
