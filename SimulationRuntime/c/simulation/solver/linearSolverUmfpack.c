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

/*! \file linearSolverUmfpack.c
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
#include "linearSolverUmfpack.h"

#include "../../../../build/include/omc/c/suitesparse/Include/umfpack.h"

/*! \fn allocate memory for linear system solver UmfPack
 *
 */
int
allocateUmfPackData(int n_row, int n_col, int nz, void** voiddata)
{
  DATA_UMFPACK* data = (DATA_UMFPACK*) malloc(sizeof(DATA_UMFPACK));
  assertStreamPrint(NULL, 0 != data, "Could not allocate data for linear solver UmfPack.");

  data->n_col = n_col;
  data->n_row = n_row;
  data->nnz = nz;


  data->Ap = (int*) calloc((n_row+1),sizeof(int));

  data->Ai = (int*) malloc(nz*sizeof(int));
  data->Ax = (double*) malloc(nz*sizeof(double));

  data->numberSolving=0;

  *voiddata = (void*)data;

  return 0;
}


/*! \fn free memory for linear system solver UmfPack
 *
 */
int
freeUmfPackData(void **voiddata)
{
  DATA_UMFPACK* data = (DATA_UMFPACK*) *voiddata;

  free(data->Ap);
  free(data->Ai);
  free(data->Ax);

  umfpack_di_free_symbolic (&data->symbolic);
  umfpack_di_free_numeric (&data->numeric);

  return 0;
}

/*! \fn solve linear system with UmfPack method
 *
 *  \param  [in]  [data]
 *                [sysNumber] index of the corresponding linear system
 *
 */
int
solveUmfPack(DATA *data, int sysNumber)
{
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.linearSystemData[sysNumber]);
  DATA_UMFPACK* solverData = (DATA_UMFPACK*)systemData->solverData;

  double control[UMFPACK_CONTROL], info[UMFPACK_INFO];

  int i, j, status = 0, success = 0, ni=0, n = systemData->size, eqSystemNumber = systemData->equationIndex, indexes[2] = {1,eqSystemNumber};
  
  infoStreamPrintWithEquationIndexes(LOG_LS, 0, indexes, "Start solving Linear System %d (size %d) at time %g with UMFPACK Solver",
         eqSystemNumber, (int) systemData->size,
         data->localData[0]->timeValue);


  rt_ext_tp_tick(&(solverData->timeClock));
  if (0 == systemData->method)
  {
    /* set A matrix */
	  solverData->Ap[0] = 0;
	  systemData->setA(data, systemData);
	  solverData->Ap[solverData->n_row] = solverData->nnz;

	  /* set b vector */
	  systemData->setb(data, systemData);
  } else {
    assertStreamPrint(data->threadData, 0, "Tearing system not implemented yet!");
  }
  infoStreamPrint(LOG_LS, 0, "###  %f  time to set Matrix A and vector b.", rt_ext_tp_tock(&(solverData->timeClock)));

  if (ACTIVE_STREAM(LOG_LS_V))
  {
		infoStreamPrint(LOG_LS_V, 1, "Matrix A");
	  for (i=0; i<solverData->n_row; i++)
	    for (j=solverData->Ap[i]; j<solverData->Ap[i+1]; j++)
		    infoStreamPrint(LOG_LS_V, 0, "A[%d,%d] = %f", i, solverData->Ai[j], solverData->Ax[j]);
    
    messageClose(LOG_LS_V);

	  for (i=0; i<solverData->n_row; i++)
		  infoStreamPrint(LOG_LS_V, 0, "b[%d] = %e", i, systemData->b[i]);
  }

  control[UMFPACK_PIVOT_TOLERANCE] = 1.0;

  if (0 == solverData->numberSolving)
  {
    status = umfpack_di_symbolic(solverData->n_col, solverData->n_row, solverData->Ap, solverData->Ai, solverData->Ax, &(solverData->symbolic), control, info);
  }
  if (0 == status){
    status = umfpack_di_numeric(solverData->Ap, solverData->Ai, solverData->Ax, solverData->symbolic, &(solverData->numeric), control, info);
  }
  if (0 == status){
    status = umfpack_di_solve(UMFPACK_Aat, solverData->Ap, solverData->Ai, solverData->Ax, systemData->x, systemData->b, solverData->numeric, control, info);
  }

  if (status == UMFPACK_OK){
    success = 1;
  } else {

    warningStreamPrint(LOG_STDOUT, 0,
      "Failed to solve linear system of equations (no. %d) at time %f, system status %d.",
        (int)systemData->equationIndex, data->localData[0]->timeValue, status);

    success = 0;
  }

  if (1 == success){


    if (ACTIVE_STREAM(LOG_LS_V))
    {
      infoStreamPrint(LOG_LS_V, 1, "Solution x:");
      infoStreamPrint(LOG_LS_V, 0, "System %d numVars %d.", eqSystemNumber, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber).numVar);

      for(i = 0; i < systemData->size; ++i)
        infoStreamPrint(LOG_LS_V, 0, "[%d] %s = %g", i+1, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber).vars[i], systemData->x[i]);


      messageClose(LOG_LS_V);
    }
  }
  solverData->numberSolving += 1;

  return success;
}
