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

/*! \file linearSolverLis.c
 */

#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "simulation_data.h"
#include "omc_error.h"
#include "varinfo.h"
#include "model_help.h"

#include "linearSystem.h"
#include "linearSolverLis.h"

/*! \fn allocate memory for linear system solver Lis 
 *
 */
int
allocateLisData(int n_row, int n_col, int nz, void** voiddata)
{
  DATA_LIS* data = (DATA_LIS*) malloc(sizeof(DATA_LIS));
  ASSERT(data, "Could not allocate data for linear solver Lis.");

  data->n_col = n_col;
  data->n_row = n_row;
  data->nnz = nz;

  lis_vector_create(0, &(data->b));
  lis_vector_set_size(data->b, data->n_row, 0);

  lis_solver_create(&(data->solver));
  lis_solver_set_option("-i fgmres ",data->solver);

  *voiddata = (void*)data;
  return 0;
}

/*! \fn free memory for linear system solver Lis 
 *
 */
int 
freeLisData(void **voiddata)
{
  DATA_LIS* data = (DATA_LIS*) *voiddata;
  
  lis_solver_destroy(data->solver);
  lis_vector_destroy(data->b);
  lis_vector_destroy(data->x);

  return 0;
}

/*! \fn solve linear system with Lis method
 *
 *  \param  [in]  [data]
 *                [sysNumber] index of the corresponing non-linear system
 *
 *  \author swagner
 */
int
solveLis(DATA *data, int sysNumber)
{
  int i, ret, success = 1;
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.linearSystemData[sysNumber]);
  DATA_LIS* sData = (DATA_LIS*)systemData->solverData;

  /* Destroy the old matrix, create a new one and fill it with values */
  lis_matrix_destroy(sData->A);
  lis_matrix_create(0, &(sData->A));
  lis_matrix_set_size(sData->A, sData->n_row, 0);
  systemData->setA(data, systemData);
  lis_matrix_set_type(sData->A, LIS_MATRIX_CSR);
  lis_matrix_assemble(sData->A);

  /* fill b with values */
  systemData->setb(data, systemData);
  for(i=0; i<sData->n_row; i++)
  {
    lis_vector_set_value(LIS_INS_VALUE, i, systemData->b[i], sData->b);
  }

  /* Create a new Vector for the solution */
  lis_vector_destroy(sData->x);
  lis_vector_duplicate(sData->A,&(sData->x));
  
  /* solve */
  ret = lis_solve(sData->A,sData->b,sData->x,sData->solver);

  /* handle return status */
  switch(ret){
    case LIS_SUCCESS:
      success = 1;
      break;
    case LIS_ILL_OPTION:
    case LIS_BREAKDOWN:
    case LIS_OUT_OF_MEMORY:
    case LIS_MAXITER:
    case LIS_ERR_NOT_IMPLEMENTED:
    case LIS_ERR_FILE_IO:
    default:
      success = 0;
      break;
  }

  /* write solution */
  lis_vector_get_values(sData->x, 0, sData->n_col, systemData->x);

  lis_matrix_destroy(sData->A);

  return success;
}
