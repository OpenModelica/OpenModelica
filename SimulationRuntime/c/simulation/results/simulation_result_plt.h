/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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

#ifndef _SIMULATION_RESULT_PLT_H
#define _SIMULATION_RESULT_PLT_H

#include "simulation_result.h"

class simulation_result_plt : public simulation_result { 
private:

double* simulationResultData;
long currentPos;
long actualPoints; /* the number of actual points saved */
long maxPoints;
long dataSize;
int num_vars;
MODEL_DATA *modelData;

void add_result(double *data, long *actualPoints, DATA *simData);
void deallocResult();
void printPltLine(FILE* f, double time, double val);

public:

simulation_result_plt(const char* filename, long numpoints, MODEL_DATA *modeldata);
virtual ~simulation_result_plt();
virtual void emit(DATA *data);
void writeParameterData(MODEL_DATA *modelData) { /* do nothing */ };
virtual const char* result_type() {return "plt";};

};

#endif
