/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "util/omc_error.h"
#include "util/omc_file.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "simulation/arrayIndex.h"
#include "simulation/solver/external_input.h"
#include "simulation/options.h"
#include "simulation/solver/model_help.h"
#include "linearize.h"
#include <iostream>
#include <sstream>
#include <string>

using namespace std;

static string array2string(double* array, int row, int col, DATA *data)
{
  int i=0;
  int j=0;
  ostringstream retVal(ostringstream::out);
  retVal.precision(16);
  for(i=0; i<row; i++)
  {
    int k = i;
    for(j=0; j<col-1; j++)
    {
      if (data->modelData->linearizationDumpLanguage == OMC_LINEARIZE_DUMP_LANGUAGE_JULIA)
      {
        retVal << array[k] << " "; // Julia matrix accepts space as separators
      }
      else
      {
        retVal << array[k] << ", ";
      }
      k += row;
    }
    if(col > 0)
    {
      retVal << array[k];
    }
    if((i+1 != row) && (col != 0))
    {
      retVal << ";\n\t";
    }
  }
  return retVal.str();
}

static string array2PythonString(double* array, int row, int col)
{
  int i=0;
  int j=0;
  ostringstream retVal(ostringstream::out);
  if (row == 0 || col == 0)
  {
    retVal << "[]\n";
    return retVal.str();
  }

  retVal.precision(16);
  retVal << "[";
  for(i=0; i<row; i++)
  {
    int k = i;
    retVal << "[";
    for(j=0; j<col-1; j++)
    {
      retVal << array[k] << ", ";
      k += row;
    }
    if(col > 0)
    {
      retVal << array[k];
    }
    if((i+1 != row) && (col != 0))
    {
      retVal << "],\n\t";
    }
  }
  retVal << "]]\n";

  return retVal.str();
}

extern "C" {

int functionODE_residual(DATA* data, threadData_t *threadData, double *dx, double *dy, double *dz)
{
    long i;

    /* debug */
    /* printCurrentStatesVector(OMC_LOG_JAC, y, data, data->localData[0]->timeValue); */

    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);

    /* eval input vars */
    data->callback->functionODE(data, threadData);

    /* eval algebraic vars */
    data->callback->functionAlgebraics(data, threadData);

    /* eval output vars */
    data->callback->output_function(data, threadData);

    /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
    for(i=0; i < data->modelData->nStates; i++)
    {
        dx[i] = data->localData[0]->realVars[data->modelData->nStates + i];
    }
    for(i=0; i < data->modelData->nOutputVars; i++)
    {
        dy[i] = data->simulationInfo->outputVars[i];
    }
    if(dz){
        for(i=0; i < (data->modelData->nVariablesReal - 2*data->modelData->nStates); i++)
        {
            dz[i] = data->localData[0]->realVars[2*data->modelData->nStates + i];
        }
    }

    return 0;
}

/*  Calculate the jacobian matrix by numerical finite difference */
int functionJacAC_num(DATA* data, threadData_t *threadData, double *matrixA, double *matrixC, double *matrixCz)
{
    const double delta_h = numericalDifferentiationDeltaXlinearize;
    double delta_hh;
    double xsave;

    double* x;

    int i,j,k;

    int do_data_recovery = 0;

    int size_A = data->modelData->nStates;
    int size_C = data->modelData->nOutputVars;
    int size_z = data->modelData->nVariablesReal - 2*data->modelData->nStates;

    double* x0 = (double*)calloc(size_A,sizeof(double));
    double* y0 = (double*)calloc(size_C,sizeof(double));
    double* x1 = (double*)calloc(size_A,sizeof(double));
    double* y1 = (double*)calloc(size_C,sizeof(double));
    double* z0 = 0;
    double* z1 = 0;
    double *xScaling = (double*)calloc(size_A,sizeof(double));

    assertStreamPrint(threadData,0!=x0,"calloc failed");
    assertStreamPrint(threadData,0!=y0,"calloc failed");
    assertStreamPrint(threadData,0!=x1,"calloc failed");
    assertStreamPrint(threadData,0!=y1,"calloc failed");

    if(matrixCz){
        do_data_recovery = 1;
    }

    if(do_data_recovery > 0){
        z0 = (double*)calloc(size_z,sizeof(double));
        z1 = (double*)calloc(size_z,sizeof(double));
        assertStreamPrint(threadData,0!=z0,"calloc failed");
        assertStreamPrint(threadData,0!=z1,"calloc failed");
    }

    functionODE_residual(data, threadData, x0, y0, z0);

    x = data->localData[0]->realVars;

    /* use actually value for xScaling */
    for (i = 0; i < size_A; i++) {
        modelica_real nominal = getNominalFromScalarIdx(data->simulationInfo, data->modelData, i);
        xScaling[i] = fmax(nominal, fabs(x[i]));
    }

    /* solverData->f1 must be set outside this function based on x */
    for(i = 0; i < size_A; i++) {
        xsave = x[i];
        delta_hh = delta_h * (fabs(xsave) + 1.0);
        if ((xsave + delta_hh >=  data->modelData->realVarsData[i].attribute.max))
            delta_hh *= -1;
        x[i] += delta_hh / xScaling[i];
        /* Calculate scaled difference quotient */
        delta_hh = 1. / delta_hh * xScaling[i];

        functionODE_residual(data, threadData, x1, y1, z1);

        for(j = 0; j < size_A; j++) {
            k = i * size_A + j;
            matrixA[k] = (x1[j] - x0[j]) * delta_hh;
        }
        for(j = 0; j < size_C; j++) {
            k = i * size_C + j;
            matrixC[k] = (y1[j] - y0[j]) * delta_hh;
        }
        if(do_data_recovery > 0){
            for(j = 0; j < size_z; j++) {
                k = i * size_z + j;
                matrixCz[k] = (z1[j] - z0[j]) * delta_hh;
            }
        }
        x[i] = xsave;
    }

    free(xScaling);
    free(x0);
    free(y0);
    free(x1);
    free(y1);
    if(do_data_recovery > 0){
        free(z0);
        free(z1);
    }

    return 0;
}

int functionJacBD_num(DATA* data, threadData_t *threadData, double *matrixB, double *matrixD, double *matrixDz)
{
    const double delta_h = numericalDifferentiationDeltaXlinearize;
    double delta_hh;
    double usave;
    double* u;

    int i,j,k;

    int do_data_recovery = 0;
    if(matrixDz){
        do_data_recovery = 1;
    }

    int size_x = data->modelData->nStates;
    int size_u = data->modelData->nInputVars;
    int size_y = data->modelData->nOutputVars;
    int size_z = data->modelData->nVariablesReal - 2*data->modelData->nStates;
    double* x0 = (double*)calloc(size_x,sizeof(double));
    double* y0 = (double*)calloc(size_y,sizeof(double));
    double* x1 = (double*)calloc(size_x,sizeof(double));
    double* y1 = (double*)calloc(size_y,sizeof(double));
    double* z0 = 0;
    double* z1 = 0;

    assertStreamPrint(threadData,0!=x0,"calloc failed");
    assertStreamPrint(threadData,0!=y0,"calloc failed");
    assertStreamPrint(threadData,0!=x1,"calloc failed");
    assertStreamPrint(threadData,0!=y1,"calloc failed");

    if(do_data_recovery > 0){
        z0 = (double*)calloc(size_z,sizeof(double));
        z1 = (double*)calloc(size_z,sizeof(double));
        assertStreamPrint(threadData,0!=z0,"calloc failed");
        assertStreamPrint(threadData,0!=z1,"calloc failed");
    }

    functionODE_residual(data, threadData, x0, y0, z0);

    u = data->simulationInfo->inputVars;

    /* solverData->f1 must be set outside this function based on x */
    for(i = 0; i < size_u; i++) {
        usave = u[i];
        delta_hh = delta_h * (fabs(usave) + 1.0);
        u[i] += delta_hh;
        delta_hh = 1. / delta_hh;

        functionODE_residual(data, threadData, x1, y1, z1);

        for(j = 0; j < size_x; j++) {
            k = i * size_x + j;
            matrixB[k] = (x1[j] - x0[j]) * delta_hh;
        }
        for(j = 0; j < size_y; j++) {
            k = i * size_y + j;
            matrixD[k] = (y1[j] - y0[j]) * delta_hh;
        }
        if(do_data_recovery > 0){
            for(j = 0; j < size_z; j++) {
                k = i * size_z + j;
                matrixDz[k] = (z1[j] - z0[j]) * delta_hh;
            }
        }
        u[i] = usave;
    }

    free(x0);
    free(y0);
    free(x1);
    free(y1);
    if(do_data_recovery > 0){
        free(z0);
        free(z1);
    }

    return 0;
}


/*  Calculate the jacobian matrix by analytical finite difference */
int functionJacA(DATA* data, threadData_t *threadData, double* jac){

  const int index = data->callback->INDEX_JAC_A;
  JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);
  unsigned int i,j,k;
  k = 0;
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, NULL);
  }

  for(i=0; i < jacobian->sizeCols; i++)
  {
    jacobian->seedVars[i] = 1.0;
    if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < jacobian->sizeCols;j++)
      {
        infoStreamPrint(OMC_LOG_JAC,0,"seed: jacobian->seedVars[%d]= %f",j,jacobian->seedVars[j]);
      }
    }

    data->callback->functionJacA_column(data, threadData, jacobian, NULL);

    for(j = 0; j < jacobian->sizeRows; j++)
    {
      jac[k++] = jacobian->resultVars[j];
      infoStreamPrint(OMC_LOG_JAC,0,"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,jacobian->resultVars[j]);
    }

    jacobian->seedVars[i] = 0.0;
  }
  if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
  {
    infoStreamPrint(OMC_LOG_JAC,0,"Print jac:");
    for(i=0;  i < jacobian->sizeRows;i++)
    {
      for(j=0;  j < jacobian->sizeCols;j++) {
        printf("% .5e ",jac[i+j*jacobian->sizeCols]);
      }
      printf("\n");
    }
  }

  return 0;
}
int functionJacB(DATA* data, threadData_t *threadData, double* jac){

  const int index = data->callback->INDEX_JAC_B;
  JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);

  unsigned int i,j,k;
  k = 0;
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, NULL);
  }

  for(i=0; i < jacobian->sizeCols; i++)
  {
    jacobian->seedVars[i] = 1.0;
    if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < jacobian->sizeCols;j++)
      {
        infoStreamPrint(OMC_LOG_JAC,0,"seed: jacobian->seedVars[%d]= %f",j,jacobian->seedVars[j]);
      }
    }

    data->callback->functionJacB_column(data, threadData, jacobian, NULL);

    for(j = 0; j < jacobian->sizeRows; j++)
    {
      jac[k++] = jacobian->resultVars[j];
      infoStreamPrint(OMC_LOG_JAC,0,"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,jacobian->resultVars[j]);
    }

    jacobian->seedVars[i] = 0.0;
  }
  if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
  {
    infoStreamPrint(OMC_LOG_JAC, 0, "Print jac:");
    for(i=0;  i < jacobian->sizeRows;i++)
    {
      for(j=0;  j < jacobian->sizeCols;j++)
        printf("% .5e ",jac[i+j*jacobian->sizeCols]);
      printf("\n");
    }
  }

  return 0;
}
int functionJacC(DATA* data, threadData_t *threadData, double* jac){

  const int index = data->callback->INDEX_JAC_C;
  JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);
  unsigned int i,j,k;
  k = 0;
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, NULL);
  }

  for(i=0; i < jacobian->sizeCols; i++)
  {
    jacobian->seedVars[i] = 1.0;
    if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < jacobian->sizeCols;j++)
        infoStreamPrint(OMC_LOG_JAC,0,"seed: jacobian->seedVars[%d]= %f",j,jacobian->seedVars[j]);
    }

    data->callback->functionJacC_column(data, threadData, jacobian, NULL);

    for(j = 0; j < jacobian->sizeRows; j++)
    {
      jac[k++] = jacobian->resultVars[j];
      infoStreamPrint(OMC_LOG_JAC,0,"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,jacobian->resultVars[j]);
    }

    jacobian->seedVars[i] = 0.0;
  }
  if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
  {
    infoStreamPrint(OMC_LOG_JAC, 0, "Print jac:");
    for(i=0;  i < jacobian->sizeRows;i++)
    {
      for(j=0;  j < jacobian->sizeCols;j++)
        printf("% .5e ",jac[i+j*jacobian->sizeCols]);
      printf("\n");
    }
  }

  return 0;
}
int functionJacD(DATA* data, threadData_t *threadData, double* jac){

  const int index = data->callback->INDEX_JAC_D;
  JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);
  unsigned int i,j,k;
  k = 0;
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, NULL);
  }

  for(i=0; i < jacobian->sizeCols; i++)
  {
    jacobian->seedVars[i] = 1.0;
    if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < jacobian->sizeCols;j++) {
        infoStreamPrint(OMC_LOG_JAC,0,"seed: jacobian->seedVars[%d]= %f",j,jacobian->seedVars[j]);
      }
    }

    data->callback->functionJacD_column(data, threadData, jacobian, NULL);

    for(j = 0; j < jacobian->sizeRows; j++)
    {
      jac[k++] = jacobian->resultVars[j];
      infoStreamPrint(OMC_LOG_JAC,0, "write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,jacobian->resultVars[j]);
    }

    jacobian->seedVars[i] = 0.0;
  }
  if(OMC_ACTIVE_STREAM(OMC_LOG_JAC))
  {
    infoStreamPrint(OMC_LOG_JAC, 0, "Print jac:");
    for(i=0;  i < jacobian->sizeRows;i++)
    {
      for(j=0;  j < jacobian->sizeCols;j++)
        printf("% .5e ",jac[i+j*jacobian->sizeCols]);
      printf("\n");
    }
  }

  return 0;
}



int linearize(DATA* data, threadData_t *threadData)
{
    /* Check if data recovery is requested */
    int do_data_recovery = omc_flag[FLAG_L_DATA_RECOVERY] ? 1 : 0;

    /* init linearization sizes */
    int size_A = data->modelData->nStates;
    int size_Inputs = data->modelData->nInputVars;
    int size_Outputs = data->modelData->nOutputVars;
    int size_z = data->modelData->nVariablesReal - 2*data->modelData->nStates;
    double* matrixA = (double*)calloc(size_A*size_A,sizeof(double));
    double* matrixB = (double*)calloc(size_A*size_Inputs,sizeof(double));
    double* matrixC = (double*)calloc(size_Outputs*size_A,sizeof(double));
    double* matrixD = (double*)calloc(size_Outputs*size_Inputs,sizeof(double));
    double* matrixCz = 0;
    double* matrixDz = 0;
    string strA, strB, strC, strD, strCz, strDz, strX, strU, strZ0, filename, ext;

    assertStreamPrint(threadData,0!=matrixA,"calloc failed");
    assertStreamPrint(threadData,0!=matrixB,"calloc failed");
    assertStreamPrint(threadData,0!=matrixC,"calloc failed");
    assertStreamPrint(threadData,0!=matrixD,"calloc failed");

    if(do_data_recovery > 0){
        matrixCz = (double*)calloc(size_z*size_A,sizeof(double));
        matrixDz = (double*)calloc(size_z*size_Inputs,sizeof(double));
        assertStreamPrint(threadData,0!=matrixCz,"calloc failed");
        assertStreamPrint(threadData,0!=matrixDz,"calloc failed");
    }

    /* Need to do this before changing anything so that we get a proper z0 */
    if(do_data_recovery > 0){
        if(size_z){
            strZ0 = "{" + array2string(&data->localData[0]->realVars[2*size_A], 1, size_z, data) + "}";
        }else{
            strZ0 = "zeros(0)";
        }
    }

    /* Can currently only extract data recovery matrices Cz and Dz numerically, so we do this first if necessary */
    if(do_data_recovery > 0 || data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sizeTmpVars == 0){
        /* Calculate numeric Jacobian */
        if(functionJacAC_num(data, threadData, matrixA, matrixC, matrixCz))
        {
            throwStreamPrint(threadData, "Error, can not get Matrix A or C ");
            return 1;
        }
        if(functionJacBD_num(data, threadData, matrixB, matrixD, matrixDz))
        {
            throwStreamPrint(threadData, "Error, can not get Matrix B or D ");
            return 1;
        }
    }

    /* Check if symbolic Jacobian available, if it is then use it (overwriting A,B,C,D if also doing data recovery) */
    if (data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sizeTmpVars > 0){
        /* Retrieve symbolic Jacobian */
        /* Determine Matrix A */
        JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
        if(!data->callback->initialAnalyticJacobianA(data, threadData, jacobian)){
            assertStreamPrint(threadData,0==functionJacA(data, threadData, matrixA),"Error, can not get Matrix A ");
        }

        /* Determine Matrix B */
        jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_B]);
        if(!data->callback->initialAnalyticJacobianB(data, threadData, jacobian)){
            assertStreamPrint(threadData,0==functionJacB(data, threadData, matrixB),"Error, can not get Matrix B ");
        }

        /* Determine Matrix C */
        jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_C]);
        if(!data->callback->initialAnalyticJacobianC(data, threadData, jacobian)){
            assertStreamPrint(threadData,0==functionJacC(data, threadData, matrixC),"Error, can not get Matrix C ");
        }

        /* Determine Matrix D */
        jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_D]);
        if(!data->callback->initialAnalyticJacobianD(data, threadData, jacobian)){
            assertStreamPrint(threadData,0==functionJacD(data, threadData, matrixD),"Error, can not get Matrix D ");
        }
    }
    if (data->modelData->linearizationDumpLanguage != OMC_LINEARIZE_DUMP_LANGUAGE_PYTHON)
    {

      strA = array2string(matrixA, size_A, size_A, data);
      strB = array2string(matrixB, size_A, size_Inputs, data);
      strC = array2string(matrixC, size_Outputs, size_A, data);
      strD = array2string(matrixD, size_Outputs, size_Inputs, data);
      if (do_data_recovery > 0)
      {
        strCz = array2string(matrixCz, size_z, size_A, data);
        strDz = array2string(matrixDz, size_z, size_Inputs, data);
      }

      // The empty array {} is not valid modelica, so we need to put something
      //   inside the curly braces for x0 and u0. {for i in in 1:0} will create an
      //   empty array if needed.
      if (size_A)
      {
        // fix dummping julia vector braces
        if (data->modelData->linearizationDumpLanguage == OMC_LINEARIZE_DUMP_LANGUAGE_JULIA)
          strX = "[" + array2string(data->localData[0]->realVars, 1, size_A, data) + "]";
        else
          strX = "{" + array2string(data->localData[0]->realVars, 1, size_A, data) + "}";
      }
      else
      {
        strX = "zeros(0)";
      }

      if (size_Inputs)
      {
        // fix dummping julia vector braces
        if (data->modelData->linearizationDumpLanguage == OMC_LINEARIZE_DUMP_LANGUAGE_JULIA)
          strU = "[" + array2string(data->simulationInfo->inputVars, 1, size_Inputs, data) + "]";
        else
          strU = "{" + array2string(data->simulationInfo->inputVars, 1, size_Inputs, data) + "}";
      }
      else
      {
        strU = "zeros(0)";
      }
    }
    else
    {
      // convert the matrices to Python format
      //infoStreamPrint(OMC_LOG_STDOUT, 0, "Python selected");
      strA = array2PythonString(matrixA, size_A, size_A);
      strB = array2PythonString(matrixB, size_A, size_Inputs);
      strC = array2PythonString(matrixC, size_Outputs, size_A);
      strD = array2PythonString(matrixD, size_Outputs, size_Inputs);
      if (do_data_recovery > 0)
      {
        strCz = array2PythonString(matrixCz, size_z, size_A);
        strDz = array2PythonString(matrixDz, size_z, size_Inputs);
      }
      // strA = "[[-2.887152375617477, -1.62655852935388], [-2.380918056675567, -2.388394731625707]]";
      //infoStreamPrint(OMC_LOG_STDOUT, 0, strA.c_str());
      if (size_A)
        strX = "[" + array2string(data->localData[0]->realVars, 1, size_A, data) + "]";
      else
        strX = "[0]";

      if (size_Inputs)
        strU = "[" + array2string(data->simulationInfo->inputVars, 1, size_Inputs, data) + "]";
      else
        strU = "[0]";
    }

    free(matrixA);
    free(matrixB);
    free(matrixC);
    free(matrixD);
    if(do_data_recovery > 0){
        free(matrixCz);
        free(matrixDz);
    }
    switch(data->modelData->linearizationDumpLanguage){
      case OMC_LINEARIZE_DUMP_LANGUAGE_MODELICA:  ext = ".mo";  break;
      case OMC_LINEARIZE_DUMP_LANGUAGE_MATLAB:    ext = ".m";   break;
      case OMC_LINEARIZE_DUMP_LANGUAGE_JULIA:     ext = ".jl";  break;
      case OMC_LINEARIZE_DUMP_LANGUAGE_PYTHON:    ext = ".py";  break;
    }
    /* ticket #5927: Don't use the model name to prevent bad names for certain languages. */
    filename = "linearized_model" + string(ext);

    FILE *fout = omc_fopen(filename.c_str(),"wb");
    assertStreamPrint(threadData,0!=fout,"Cannot open File %s",filename.c_str());

    const char* frame = NULL;
    if(do_data_recovery > 0){
        frame = data->callback->linear_model_datarecovery_frame();
        fprintf(fout, frame, strX.c_str(), strU.c_str(), strZ0.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str(), strCz.c_str(), strDz.c_str());
    }else{
        frame = data->callback->linear_model_frame();
        fprintf(fout, frame, strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str(), (double) data->simulationInfo->stopTime);
    }
    if(OMC_ACTIVE_STREAM(OMC_LOG_STATS)) {
      infoStreamPrint(OMC_LOG_STATS, 0, data->callback->linear_model_frame(), strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str(), (double) data->simulationInfo->stopTime);
    }

    fflush(fout);
    fclose(fout);

    if (0 == strcmp(frame, "")) {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "Linear model could not be created.");
    } else {
        if (data->modelData->runTestsuite) {
            infoStreamPrint(OMC_LOG_STDOUT, 0, "Linear model is created.");
        }
        else {
            char* cwd = getcwd(NULL, 0); /* call with NULL and 0 to allocate the buffer dynamically (no pathmax needed) */
            if(!cwd) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "Linear model %s is created, but getting the full path failed.", filename.c_str());
            }
            else {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "Linear model is created at %s/%s", cwd, filename.c_str());
              free(cwd);
            }
            infoStreamPrint(OMC_LOG_STDOUT, 0, "The output format can be changed with the command line option --linearizationDumpLanguage.");
            infoStreamPrint(OMC_LOG_STDOUT, 0, "The options are: --linearizationDumpLanguage=none, modelica, matlab, julia, python.");
        }
      }
    return 0;
  }

}
