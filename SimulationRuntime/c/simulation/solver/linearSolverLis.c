/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

/*! \file linearSolverLis.c
 */

#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "simulation_data.h"
#include "simulation_info_xml.h"
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
  char buffer[128];
  assertStreamPrint(NULL, 0 != data, "Could not allocate data for linear solver Lis.");

  data->n_col = n_col;
  data->n_row = n_row;
  data->nnz = nz;

  lis_vector_create(LIS_COMM_WORLD, &(data->b));
  lis_vector_set_size(data->b, data->n_row, 0);

  lis_vector_create(LIS_COMM_WORLD, &(data->x));
  lis_vector_set_size(data->x, data->n_row, 0);

  lis_matrix_create(LIS_COMM_WORLD, &(data->A));
  lis_matrix_set_size(data->A, data->n_row, 0);
  lis_matrix_set_type(data->A, LIS_MATRIX_CSR);

  lis_solver_create(&(data->solver));

  lis_solver_set_option("-print none",data->solver);
  sprintf(buffer,"-maxiter %d", n_row*100);
  lis_solver_set_option(buffer,data->solver);
  lis_solver_set_option("-scale none",data->solver);
  lis_solver_set_option("-p none",data->solver);
  lis_solver_set_option("-initx_zeros 0",data->solver);
  lis_solver_set_option("-tol 1.0e-12",data->solver);


  rt_ext_tp_tick(&(data->timeClock));


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

  lis_matrix_destroy(data->A);
  lis_vector_destroy(data->b);
  lis_vector_destroy(data->x);
  lis_solver_destroy(data->solver);

  return 0;
}


void printLisMatrixCSR(LIS_MATRIX A, int n)
{
  char buffer[16384];
  int i, j;
  /* A matrix */
  infoStreamPrint(LOG_LS_V, 1, "A matrix [%dx%d] nnz = %d ", n, n, A->nnz);
  for(i=0; i<n; i++)
  {
    buffer[0] = 0;
    for(j=A->ptr[i]; j<A->ptr[i+1]; j++){
       sprintf(buffer, "%s(%d,%d,%g) ", buffer, i, A->index[j], A->value[j]);
    }
    infoStreamPrint(LOG_LS_V, 0, "%s", buffer);
  }

  messageClose(LOG_LS_V);

}



/*! \fn solve linear system with Lis method
 *
 *  \param  [in]  [data]
 *                [sysNumber] index of the corresponding linear system
 *
 */

int
solveLis(DATA *data, int sysNumber)
{
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.linearSystemData[sysNumber]);
  DATA_LIS* solverData = (DATA_LIS*)systemData->solverData;
  int i, ret, success = 1, ni, iflag = 1, n = systemData->size, eqSystemNumber = systemData->equationIndex;
  char *lis_returncode[] = {"LIS_SUCCESS", "LIS_ILL_OPTION", "LIS_BREAKDOWN", "LIS_OUT_OF_MEMORY", "LIS_MAXITER", "LIS_NOT_IMPLEMENTED", "LIS_ERR_FILE_IO"};
  LIS_INT err;

  int indexes[2] = {1,eqSystemNumber};
  infoStreamPrintWithEquationIndexes(LOG_LS, 0, indexes, "Start solving Linear System %d (size %d) at time %g with Lis Solver",
         eqSystemNumber, (int) systemData->size,
         data->localData[0]->timeValue);

  /* set old values as start value for the iteration */
  for(i=0; i<n; i++){
    err = lis_vector_set_value(LIS_INS_VALUE, i, systemData->x[i], solverData->x);
  }

  rt_ext_tp_tick(&(solverData->timeClock));
  if (0 == systemData->method)
  {

    lis_matrix_set_size(solverData->A, solverData->n_row, 0);
    /* set A matrix */
    systemData->setA(data, systemData);
    lis_matrix_assemble(solverData->A);

    /* set b vector */
    systemData->setb(data, systemData);

  } else {
    assertStreamPrint(data->threadData, 0, "Tearing system not implemented yet!");

  }
  infoStreamPrint(LOG_LS, 0, "###  %f  time to set Matrix A and vector b.", rt_ext_tp_tock(&(solverData->timeClock)));


  rt_ext_tp_tick(&(solverData->timeClock));
  err = lis_solve(solverData->A,solverData->b,solverData->x,solverData->solver);
  infoStreamPrint(LOG_LS, 0, "Solve System: %f", rt_ext_tp_tock(&(solverData->timeClock)));

  if (err){
    warningStreamPrint(LOG_LS_V, 0, "lis_solve : %s(code=%lld)\n\n ", lis_returncode[err], err);
    printLisMatrixCSR(solverData->A, solverData->n_row);
    success = 0;
  }


  /* Log A*x=b */
  if(ACTIVE_STREAM(LOG_LS_V))
  {
    char buffer[16384];

    printLisMatrixCSR(solverData->A, n);

    /* b vector */
    infoStreamPrint(LOG_LS_V, 1, "b vector [%d]", n);
    for(i=0; i<n; i++)
    {
      buffer[0] = 0;
      sprintf(buffer, "%s%20.12g ", buffer, solverData->b->value[i]);
      infoStreamPrint(LOG_LS_V, 0, "%s", buffer);
    }
    messageClose(LOG_LS_V);

    messageClose(LOG_LS_V);
  }


  /* write solution */
  lis_vector_get_values(solverData->x, 0, solverData->n_col, systemData->x);

  if (ACTIVE_STREAM(LOG_LS_V)){
    infoStreamPrint(LOG_LS_V, 1, "System %d numVars %d.", eqSystemNumber, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber).numVar);

    for(i = 0; i < systemData->size; ++i) {
      infoStreamPrint(LOG_LS_V, 0, "[%d] %s = %g", i+1, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber).vars[i], systemData->x[i]);
    }

    messageClose(LOG_LS);
  }

  return success;
}
