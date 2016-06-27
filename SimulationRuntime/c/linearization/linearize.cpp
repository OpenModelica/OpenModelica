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
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "simulation/solver/external_input.h"
#include "simulation/options.h"
#include "linearize.h"
#include <iostream>
#include <sstream>
#include <string>


using namespace std;

static string array2string(double* array, int row, int col){

  int i=0;
  int j=0;
  ostringstream retVal(ostringstream::out);
  retVal.precision(16);
  for(i=0;i<row;i++){
    int k = i;
    for(j=0;j<col-1;j++){
      retVal << array[k] << ",";
      k += row;
    }
    if(col > 0) {
      retVal << array[k];
    }
    if(!((i+1) == row) && !(col == 0)) {
      retVal << ";";
    }
  }
  return retVal.str();
}

extern "C" {

int functionODE_residual(DATA* data, threadData_t *threadData, double *dx, double *dy, double *dz)
{
    TRACE_PUSH

    long i;

//    printCurrentStatesVector(LOG_DASSL_STATES, y, data, data->localData[0]->timeValue);

    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);

    /* eval input vars */
    data->callback->functionODE(data, threadData);

    /* eval algebraic vars */
    data->callback->functionAlgebraics(data, threadData); //yes, this is necessary

    /* eval output vars */
    data->callback->output_function(data, threadData); //yes, this is necessary

    /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
    for(i=0; i < data->modelData->nStates; i++)
    {
        //        delta[i] = data->localData[0]->realVars[data->modelData.nStates + i] - yd[i];
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

    TRACE_POP
    return 0;
}

/*  Calculate the jacobian matrix by numerical finite difference */
int functionJacAC_num(DATA* data, threadData_t *threadData, double *matrixA, double *matrixC, double *matrixCz)
{
    const double delta_h = sqrt(DBL_EPSILON*2e1);
    double delta_hh;
    double xsave;

    int i,j,k;

    int do_data_recovery = 0;
    if(matrixCz){
        do_data_recovery = 1;
    }

    int size_A = data->modelData->nStates;
    int size_C = data->modelData->nOutputVars;
    int size_z = data->modelData->nVariablesReal - 2*data->modelData->nStates;
    double* x0 = (double*)calloc(size_A,sizeof(double));
    double* y0 = (double*)calloc(size_C,sizeof(double));
    double* x1 = (double*)calloc(size_A,sizeof(double));
    double* y1 = (double*)calloc(size_C,sizeof(double));
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

    double* xScaling = (double*)calloc(size_A,sizeof(double));
    for (i=0;i<size_A;i++){
        xScaling[i] = fmax(data->modelData->realVarsData[i].attribute.nominal,fabs(data->modelData->realVarsData[i].attribute.start));
    }

    functionODE_residual(data, threadData, x0, y0, z0);

    double* x = data->localData[0]->realVars;

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
    const double delta_h = sqrt(DBL_EPSILON*2e1);
    double delta_hh;
    double usave;

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

    double* u = data->simulationInfo->inputVars;

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
  unsigned int i,j,k;
  k = 0;
  for(i=0; i < data->simulationInfo->analyticJacobians[index].sizeCols; i++)
  {
    data->simulationInfo->analyticJacobians[index].seedVars[i] = 1.0;
    if(ACTIVE_STREAM(LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++)
      {
        infoStreamPrint(LOG_JAC,0,"seed: data->simulationInfo->analyticJacobians[index].seedVars[%d]= %f",j,data->simulationInfo->analyticJacobians[index].seedVars[j]);
      }
    }

    data->callback->functionJacA_column(data, threadData);

    for(j = 0; j < data->simulationInfo->analyticJacobians[index].sizeRows; j++)
    {
      jac[k++] = data->simulationInfo->analyticJacobians[index].resultVars[j];
      infoStreamPrint(LOG_JAC,0,"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,data->simulationInfo->analyticJacobians[index].resultVars[j]);
    }

    data->simulationInfo->analyticJacobians[index].seedVars[i] = 0.0;
  }
  if(ACTIVE_STREAM(LOG_JAC))
  {
    infoStreamPrint(LOG_JAC,0,"Print jac:");
    for(i=0;  i < data->simulationInfo->analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++) {
        printf("% .5e ",jac[i+j*data->simulationInfo->analyticJacobians[index].sizeCols]);
      }
      printf("\n");
    }
  }

  return 0;
}
int functionJacB(DATA* data, threadData_t *threadData, double* jac){

  const int index = data->callback->INDEX_JAC_B;
  unsigned int i,j,k;
  k = 0;
  for(i=0; i < data->simulationInfo->analyticJacobians[index].sizeCols; i++)
  {
    data->simulationInfo->analyticJacobians[index].seedVars[i] = 1.0;
    if(ACTIVE_STREAM(LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++)
      {
        infoStreamPrint(LOG_JAC,0,"seed: data->simulationInfo->analyticJacobians[index].seedVars[%d]= %f",j,data->simulationInfo->analyticJacobians[index].seedVars[j]);
      }
    }

    data->callback->functionJacB_column(data, threadData);

    for(j = 0; j < data->simulationInfo->analyticJacobians[index].sizeRows; j++)
    {
      jac[k++] = data->simulationInfo->analyticJacobians[index].resultVars[j];
      infoStreamPrint(LOG_JAC,0,"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,data->simulationInfo->analyticJacobians[index].resultVars[j]);
    }

    data->simulationInfo->analyticJacobians[index].seedVars[i] = 0.0;
  }
  if(ACTIVE_STREAM(LOG_JAC))
  {
    infoStreamPrint(LOG_JAC, 0, "Print jac:");
    for(i=0;  i < data->simulationInfo->analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++)
        printf("% .5e ",jac[i+j*data->simulationInfo->analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }

  return 0;
}
int functionJacC(DATA* data, threadData_t *threadData, double* jac){

  const int index = data->callback->INDEX_JAC_C;
  unsigned int i,j,k;
  k = 0;
  for(i=0; i < data->simulationInfo->analyticJacobians[index].sizeCols; i++)
  {
    data->simulationInfo->analyticJacobians[index].seedVars[i] = 1.0;
    if(ACTIVE_STREAM(LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++)
        infoStreamPrint(LOG_JAC,0,"seed: data->simulationInfo->analyticJacobians[index].seedVars[%d]= %f",j,data->simulationInfo->analyticJacobians[index].seedVars[j]);
    }

    data->callback->functionJacC_column(data, threadData);

    for(j = 0; j < data->simulationInfo->analyticJacobians[index].sizeRows; j++)
    {
      jac[k++] = data->simulationInfo->analyticJacobians[index].resultVars[j];
      infoStreamPrint(LOG_JAC,0,"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,data->simulationInfo->analyticJacobians[index].resultVars[j]);
    }

    data->simulationInfo->analyticJacobians[index].seedVars[i] = 0.0;
  }
  if(ACTIVE_STREAM(LOG_JAC))
  {
    infoStreamPrint(LOG_JAC, 0, "Print jac:");
    for(i=0;  i < data->simulationInfo->analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++)
        printf("% .5e ",jac[i+j*data->simulationInfo->analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }

  return 0;
}
int functionJacD(DATA* data, threadData_t *threadData, double* jac){

  const int index = data->callback->INDEX_JAC_D;
  unsigned int i,j,k;
  k = 0;
  for(i=0; i < data->simulationInfo->analyticJacobians[index].sizeCols; i++)
  {
    data->simulationInfo->analyticJacobians[index].seedVars[i] = 1.0;
    if(ACTIVE_STREAM(LOG_JAC))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++) {
        infoStreamPrint(LOG_JAC,0,"seed: data->simulationInfo->analyticJacobians[index].seedVars[%d]= %f",j,data->simulationInfo->analyticJacobians[index].seedVars[j]);
      }
    }

    data->callback->functionJacD_column(data, threadData);

    for(j = 0; j < data->simulationInfo->analyticJacobians[index].sizeRows; j++)
    {
      jac[k++] = data->simulationInfo->analyticJacobians[index].resultVars[j];
      infoStreamPrint(LOG_JAC,0, "write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k-1,i,j,jac[k-1],i,data->simulationInfo->analyticJacobians[index].resultVars[j]);
    }

    data->simulationInfo->analyticJacobians[index].seedVars[i] = 0.0;
  }
  if(ACTIVE_STREAM(LOG_JAC))
  {
    infoStreamPrint(LOG_JAC, 0, "Print jac:");
    for(i=0;  i < data->simulationInfo->analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo->analyticJacobians[index].sizeCols;j++)
        printf("% .5e ",jac[i+j*data->simulationInfo->analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }

  return 0;
}



int linearize(DATA* data, threadData_t *threadData)
{
    TRACE_PUSH
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
    string strA, strB, strC, strD, strCz, strDz, strX, strU, strZ0, filename;

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
            strZ0 = array2string(&data->localData[0]->realVars[2*size_A],1,size_z);
        }else{
            strZ0 = "i for i in 1:0";
        }
    }

    /* Can currently only extract data recovery matrices Cz and Dz numerically, so we do this first if necessary */
    if(do_data_recovery > 0 || data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sizeTmpVars == 0){
        /* Calculate numeric Jacobian */
        if(functionJacAC_num(data, threadData, matrixA, matrixC, matrixCz))
        {
            throwStreamPrint(threadData, "Error, can not get Matrix A or C ");
            TRACE_POP
            return 1;
        }
        if(functionJacBD_num(data, threadData, matrixB, matrixD, matrixDz))
        {
            throwStreamPrint(threadData, "Error, can not get Matrix B or D ");
            TRACE_POP
            return 1;
        }
    }

    /* Check if symbolic Jacobian available, if it is then use it (overwriting A,B,C,D if also doing data recovery) */
    if (data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sizeTmpVars > 0){
        /* Retrieve symbolic Jacobian */
        /* Determine Matrix A */
        if(!data->callback->initialAnalyticJacobianA(data, threadData)){
            assertStreamPrint(threadData,0==functionJacA(data, threadData, matrixA),"Error, can not get Matrix A ");
        }

        /* Determine Matrix B */
        if(!data->callback->initialAnalyticJacobianB(data, threadData)){
            assertStreamPrint(threadData,0==functionJacB(data, threadData, matrixB),"Error, can not get Matrix B ");
        }

        /* Determine Matrix C */
        if(!data->callback->initialAnalyticJacobianC(data, threadData)){
            assertStreamPrint(threadData,0==functionJacC(data, threadData, matrixC),"Error, can not get Matrix C ");
        }

        /* Determine Matrix D */
        if(!data->callback->initialAnalyticJacobianD(data, threadData)){
            assertStreamPrint(threadData,0==functionJacD(data, threadData, matrixD),"Error, can not get Matrix D ");
        }
    }

    strA = array2string(matrixA,size_A,size_A);
    strB = array2string(matrixB,size_A,size_Inputs);
    strC = array2string(matrixC,size_Outputs,size_A);
    strD = array2string(matrixD,size_Outputs,size_Inputs);
    if(do_data_recovery > 0){
        strCz = array2string(matrixCz,size_z,size_A);
        strDz = array2string(matrixDz,size_z,size_Inputs);
    }

    // The empty array {} is not valid modelica, so we need to put something
    //   inside the curly braces for x0 and u0. {for i in in 1:0} will create an
    //   empty array if needed.
    if(size_A)
      strX = array2string(data->localData[0]->realVars,1,size_A);
    else
      strX = "i for i in 1:0";

    if(size_Inputs)
      strU = array2string(data->simulationInfo->inputVars,1,size_Inputs);
    else
      strU = "i for i in 1:0";

    free(matrixA);
    free(matrixB);
    free(matrixC);
    free(matrixD);
    if(do_data_recovery > 0){
        free(matrixCz);
        free(matrixDz);
    }

    /* Use the result file name rather than the model name so that the linear file name can be changed with the -r flag, however strip _res.mat from the filename */
    filename = string(data->modelData->resultFileName) + ".mo";
    filename = filename.substr(0, filename.rfind("_res.mat")) + ".mo";
#if defined(__MINGW32__) || defined(_MSC_VER)
    if(filename.rfind('\\') >= filename.length()) {
      filename = "linear_" + filename;
    }else{
      filename.replace(filename.rfind('\\'), 1, "\\linear_");
    }
#else
    if(filename.rfind('/') >= filename.length()) {
      filename = "linear_" + filename;
    }else{
      filename.replace(filename.rfind('/'), 1, "/linear_");
    }
#endif


    FILE *fout = fopen(filename.c_str(),"wb");
    assertStreamPrint(threadData,0!=fout,"Cannot open File %s",filename.c_str());
    if(do_data_recovery > 0){
        fprintf(fout, data->callback->linear_model_datarecovery_frame(), strX.c_str(), strU.c_str(), strZ0.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str(), strCz.c_str(), strDz.c_str());
    }else{
        fprintf(fout, data->callback->linear_model_frame(), strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str());
    }
    if(ACTIVE_STREAM(LOG_STATS)) {
      infoStreamPrint(LOG_STATS, 0, data->callback->linear_model_frame(), strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str());
    }
    fflush(fout);
    fclose(fout);

    return 0;
}

}
