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
#include "linearSolverLis.h"
#include "simulation_info_xml.h"
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
  int i,nnz;
  int size;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo.linearSystemData;

  for(i=0; i<data->modelData.nLinearSystems; ++i)
  {
    size = linsys[i].size;
    nnz = linsys[i].nnz;

    /* allocate system data */
    linsys[i].x = (double*) malloc(size*sizeof(double));
    linsys[i].b = (double*) malloc(size*sizeof(double));

    /* allocate solver data */
    /* the implementation of matrix A is solver-specific */
    switch(data->simulationInfo.lsMethod){
    case LS_LAPACK:
      linsys[i].A = (double*) malloc(size*size*sizeof(double));
      linsys[i].setAElement = setAElementLAPACK;
      allocateLapackData(size, &linsys[i].solverData);
      break;
    case LS_LIS:
      linsys[i].setAElement = setAElementLis;
      allocateLisData(size, size, nnz, &linsys[i].solverData);
      break;
    default:
      THROW("unrecognized linear solver");
    }
  }
  return 0;
}

/*! \fn freelinearSystem
 *
 *  This function frees memory of linear systems.
 *
 *  \param [ref] [data]
 */
int freelinearSystem(DATA *data)
{
  int i;
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;

  for(i=0;i<data->modelData.nLinearSystems;++i)
  {
    /* free system and solver data */
    free(linsys[i].x);
    free(linsys[i].b);

    switch(data->simulationInfo.lsMethod){
    case LS_LAPACK:
      freeLapackData(&linsys[i].solverData);
      free(linsys[i].A);
      break;
    case LS_LIS:
      freeLisData(&linsys[i].solverData);
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
 *  \param [in]  [data]
 *                [sysNumber] index of corresponding non-linear System
 *
 *  \author wbraun
 */
int solve_linear_system(DATA *data, int sysNumber)
{
  int success;
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;

  switch(data->simulationInfo.lsMethod){
  case LS_LAPACK:
    success = solveLapack(data, sysNumber);
    break;
  case LS_LIS:
    success = solveLis(data, sysNumber);
    break;
  default:
    THROW("unrecognized linear solver");
  }
  linsys[sysNumber].solved = success;

  return 0;
}

/*! \fn check_linear_solutions
 *   This function check whether some of linear systems
 *   are failed to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *
 *  \author wbraun
 */
int check_linear_solutions(DATA *data, int printFailingSystems)
{
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;
  int i, j, retVal=0;

  for(i=0; i<data->modelData.nLinearSystems; ++i)
    if(linsys[i].solved == 0)
    {
      retVal = 1;
      if(printFailingSystems)
      {
        WARNING2(LOG_LS, "linear system fails: %s at t=%g", modelInfoXmlGetEquation(&data->modelData.modelDataXml, linsys->equationIndex).name, data->localData[0]->timeValue);
        INDENT(LOG_LS);
        for(j=0; j<modelInfoXmlGetEquation(&data->modelData.modelDataXml, linsys->equationIndex).numVar; ++j)
          WARNING2(LOG_LS, "[%d] %s", j+1, modelInfoXmlGetEquation(&data->modelData.modelDataXml, linsys->equationIndex).vars[j]->name);
        RELEASE(LOG_LS);
      }
    }

  return retVal;
}

void setAElementLAPACK(int row, int col, double value, int nth, void *data )
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->A[row + col * linsys->size] = value;
}

void setAElementLis(int row, int col, double value, int nth, void *data )
{
  LINEAR_SYSTEM_DATA* linSys = (LINEAR_SYSTEM_DATA*) data;
  DATA_LIS* sData = (DATA_LIS*) linSys->solverData;
  lis_matrix_set_value(LIS_INS_VALUE, row, col, value, sData->A);
}
