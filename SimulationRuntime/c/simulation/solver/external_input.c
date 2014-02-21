/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
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
 * from Linköping University, either from the above address,
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

#include <string.h>
#include <setjmp.h>

#include "openmodelica.h"
#include "openmodelica_func.h"
#include "simulation_data.h"

#include "util/omc_error.h"
#include "util/memory_pool.h"

#include "simulation/simulation_runtime.h"
#include "simulation/solver/solver_main.h"
#include "simulation/solver/model_help.h"


int externalInputallocate(DATA* data)
{
	FILE * pFile;
	int n,m,c;
	int i,j;

	pFile = fopen("externalInput.csv","r");
	data->simulationInfo.external_input.active = (modelica_boolean) (pFile != NULL);
	n = 0;
	if(data->simulationInfo.external_input.active){
		while(1) {
		    c = fgetc(pFile);
		    if (c==EOF) break;
		    if (c=='\n') ++n;
		}
		--n;
		data->simulationInfo.external_input.n = n;
		rewind(pFile);

		do{
		  c = fgetc(pFile);
		}while(c!='\n');

		m = data->modelData.nInputVars;
		data->simulationInfo.external_input.u = (modelica_real**)calloc(n,sizeof(modelica_real*));
		for(i = 0; i<n; ++i)
			data->simulationInfo.external_input.u[i] = (modelica_real*)calloc(m,sizeof(modelica_real));
		data->simulationInfo.external_input.t = (modelica_real*)calloc(n,sizeof(modelica_real));

		for(i = 0; i < n; ++i){
			fscanf(pFile, "%f", &data->simulationInfo.external_input.t[i]);
			for(j = 0; j < m; ++j){
				fscanf(pFile, "%f", &data->simulationInfo.external_input.u[i][j]);
			}
		}
		fclose(pFile);
		data->simulationInfo.external_input.i = 0;
	}

	return 0;
}

int externalInputFree(DATA* data)
{
	if(data->simulationInfo.external_input.active){
		int j;

		free(data->simulationInfo.external_input.t);
		for(j = 0; j < data->simulationInfo.external_input.n; ++j)
			free(data->simulationInfo.external_input.u[j]);
		free(data->simulationInfo.external_input.u);
	}
	return 0;
}


int externalInputUpdate(DATA* data)
{
	double t;
	int i;
	t = data->localData[0]->timeValue;
	while(t > data->simulationInfo.external_input.t[data->simulationInfo.external_input.i+1]
	      && data->simulationInfo.external_input.i < (data->simulationInfo.external_input.n-2)){
		++data->simulationInfo.external_input.i;
	}

	data->simulationInfo.external_input.dt = (data->simulationInfo.external_input.t[data->simulationInfo.external_input.i+1] - data->simulationInfo.external_input.t[data->simulationInfo.external_input.i]);
	for(i = 0; i < data->modelData.nInputVars; ++i){
		data->simulationInfo.inputVars[i] =
				data->simulationInfo.external_input.u[data->simulationInfo.external_input.i][i] +
				data->simulationInfo.external_input.dt*(t -data->simulationInfo.external_input.t[data->simulationInfo.external_input.i])*
				data->simulationInfo.external_input.u[data->simulationInfo.external_input.i+1][i];
	}
 return 0;
}
