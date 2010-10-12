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
			if (j+1==col)
				retVal << array[k++];
			else
				retVal << array[k++] << ",";
		}
		if (!((i+1) == row) and !(col == 0))
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
	double* matrixA	 = new double[size_A*size_A];
	double* matrixB = new double[size_A*size_Inputs];
	double* matrixC = new double[size_Outputs*size_A];
	double* matrixD = new double[size_Outputs*size_Inputs];
	string strA, strB, strC, strD, strX, strU, filename, linearModel;

	// Determine Matrix A
	if (functionJacA(&globalData->timeValue,globalData->states,globalData->statesDerivatives,matrixA)){
	    cerr << "Error, can not get Matrix A " << endl;
	    exit(-1);
	}
	strA = array2string(matrixA,size_A,size_A);

	// Determine Matrix B
	if (functionJacB(&globalData->timeValue,globalData->states,globalData->statesDerivatives,matrixB)){
	    cerr << "Error, can not get Matrix B " << endl;
	    exit(-1);
	}
	strB = array2string(matrixB,size_A,size_Inputs);
	// Determine Matrix C
	if (functionJacC(&globalData->timeValue,globalData->states,globalData->statesDerivatives,matrixC)){
	    cerr << "Error, can not get Matrix C " << endl;
	    exit(-1);
	}
	strC = array2string(matrixC,size_Outputs,size_A);
	// Determine Matrix D
	if (functionJacD(&globalData->timeValue,globalData->states,globalData->statesDerivatives,matrixD)){
	    cerr << "Error, can not get Matrix D " << endl;
	    exit(-1);
	}
	strD = array2string(matrixD,size_Outputs,size_Inputs);

    strX = array2string(globalData->states,1,size_A);
    strU = array2string(globalData->inputVars,1,size_Inputs);

    delete [] matrixA;
    delete [] matrixB;
    delete [] matrixC;
    delete [] matrixD;

    if (linear_model_frame(linearModel, strA, strB, strC, strD, strX, strU)){
    	cerr << "Error, can not get Frame for linear model" << endl;
    }
    filename = "linear_";
    filename += globalData->modelName;
    filename += ".mo";

    ofstream FileLinModel(filename.c_str());
    FileLinModel << linearModel.c_str() << endl;
    FileLinModel.close();

    if (sim_verbose){
    	cout << linearModel << endl;
    }

    return 0;
}

