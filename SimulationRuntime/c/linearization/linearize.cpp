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

#include "omc_error.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "linearize.h"
#include <iostream>
#include <sstream>
#include <string>


using namespace std;

string array2string(double* array, int row, int col){

    int i=0;
    int j=0;
    ostringstream retVal(ostringstream::out);
    retVal.precision(16);
    int k=0;
    for (i=0;i<row;i++){
        for (j=0;j<col;j++){
            k = i + j * row;
            if (j+1==col)
                retVal << array[k];
            else
                retVal << array[k] << ",";
        }
        if (!((i+1) == row) && !(col == 0))
            retVal << ";";
    }
    return retVal.str();
}


int linearize(DATA* data)
{
    /* init linearization sizes */
    int size_A = data->modelData.nStates;
    int size_Inputs = data->modelData.nInputVars;
    int size_Outputs = data->modelData.nOutputVars;
    double* matrixA = (double*)calloc(size_A*size_A,sizeof(double));
    double* matrixB = (double*)calloc(size_A*size_Inputs,sizeof(double));
    double* matrixC = (double*)calloc(size_Outputs*size_A,sizeof(double));
    double* matrixD = (double*)calloc(size_Outputs*size_Inputs,sizeof(double));
    string strA, strB, strC, strD, strX, strU, filename, linearModel;

    ASSERT(matrixA,"Calloc");
    ASSERT(matrixB,"Calloc");
    ASSERT(matrixC,"Calloc");;
    ASSERT(matrixD,"Calloc");

    /* Determine Matrix A */
    if (!initialAnalyticJacobianA(data, NULL)){
      if (functionJacA(data, matrixA))
        THROW("Error, can not get Matrix A ");
    }
    strA = array2string(matrixA,size_A,size_A);

    /* Determine Matrix B */
    if (!initialAnalyticJacobianB(data, NULL)){
      if (functionJacB(data, matrixB))
        THROW("Error, can not get Matrix B ");
    }
    strB = array2string(matrixB,size_A,size_Inputs);

    /* Determine Matrix C */
    if (!initialAnalyticJacobianC(data, NULL)){
      if (functionJacC(data, matrixC))
        THROW("Error, can not get Matrix C ");
    }
    strC = array2string(matrixC,size_Outputs,size_A);

    /* Determine Matrix D */
    if (!initialAnalyticJacobianD(data, NULL)){
      if (functionJacD(data, matrixD))
        THROW("Error, can not get Matrix D ");
    }
    strD = array2string(matrixD,size_Outputs,size_Inputs);

    // The empty array {} is not valid modelica, so we need to put something
    //   inside the curly braces for x0 and u0. {for i in in 1:0} will create an
    //   empty array if needed.
    if(size_A) {
        strX = array2string(data->localData[0]->realVars,1,size_A);
    } else {
        strX = "i for i in 1:0";
    }

    if(size_Inputs) {
        strU = array2string(data->simulationInfo.inputVars,1,size_Inputs);
    } else {
        strU = "i for i in 1:0";
    }

    free(matrixA);
    free(matrixB);
    free(matrixC);
    free(matrixD);

    filename = "linear_" + string(data->modelData.modelName) + ".mo";

    FILE *fout = fopen(filename.c_str(),"wb");
    ASSERT1(fout,"Cannot open File %s",filename.c_str());
    fprintf(fout, linear_model_frame, strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str());
    if (DEBUG_FLAG(LOG_STATS))
    DEBUG_INFO6(LOG_STATS, linear_model_frame, strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str());
    fflush(fout);
    fclose(fout);

    return 0;
}

