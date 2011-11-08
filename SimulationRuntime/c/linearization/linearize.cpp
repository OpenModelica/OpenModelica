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

#include "simulation_runtime.h"
#include "linearize.h"
#include <iostream>
#include <sstream>
#include <string>


using namespace std;

string array2string(double* array, int row, int col){

    ostringstream retVal(ostringstream::out);
    retVal.precision(16);
    int k=0;
    for (int i=0;i<row;i++){
        for (int j=0;j<col;j++){
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


int linearize()
{

    // init Matrix A
    int size_A = globalData->nStates;
    int size_Inputs = globalData->nInputVars;
    int size_Outputs = globalData->nOutputVars;
    double* matrixA = new double[size_A*size_A];
    double* matrixB = new double[size_A*size_Inputs];
    double* matrixC = new double[size_Outputs*size_A];
    double* matrixD = new double[size_Outputs*size_Inputs];
    string strA, strB, strC, strD, strX, strU, filename, linearModel;

    // Determine Matrix A
    if (functionJacA(matrixA)){
        cerr << "Error, can not get Matrix A " << endl;
        exit(-1);
    }
    strA = array2string(matrixA,size_A,size_A);

    // Determine Matrix B
    if (functionJacB(matrixB)){
        cerr << "Error, can not get Matrix B " << endl;
        exit(-1);
    }
    strB = array2string(matrixB,size_A,size_Inputs);
    // Determine Matrix C
    if (functionJacC(matrixC)){
        cerr << "Error, can not get Matrix C " << endl;
        exit(-1);
    }
    strC = array2string(matrixC,size_Outputs,size_A);
    // Determine Matrix D
    if (functionJacD(matrixD)){
        cerr << "Error, can not get Matrix D " << endl;
        exit(-1);
    }
    strD = array2string(matrixD,size_Outputs,size_Inputs);

    // The empty array {} is not valid modelica, so we need to put something
    // inside the curly braces for x0 and u0. {for i in in 1:0} will create an
    // empty array if needed.
    if(size_A) {
        strX = array2string(globalData->states,1,size_A);
    } else {
        strX = "i for i in 1:0";
    }

    if(size_Inputs) {
        strU = array2string(globalData->inputVars,1,size_Inputs);
    } else {
        strU = "i for i in 1:0";
    }

    delete [] matrixA;
    delete [] matrixB;
    delete [] matrixC;
    delete [] matrixD;

    filename = "linear_" + string(globalData->modelName) + ".mo";

    FILE *fout = fopen(filename.c_str(),"wb");
    fprintf(fout, linear_model_frame, strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str());
    if (sim_verbose>=LOG_STATS)
        printf(linear_model_frame, strX.c_str(), strU.c_str(), strA.c_str(), strB.c_str(), strC.c_str(), strD.c_str());
    fflush(fout);
    fclose(fout);

    return 0;
}

