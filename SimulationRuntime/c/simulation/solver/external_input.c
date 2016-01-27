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

#include <string.h>
#include <setjmp.h>

#include "openmodelica.h"
#include "openmodelica_func.h"
#include "simulation_data.h"

#include "util/omc_error.h"
#include "util/memory_pool.h"
#include "util/read_csv.h"
#include "util/libcsv.h"
#include "util/read_matlab4.h"

#include "simulation/simulation_runtime.h"
#include "simulation/solver/solver_main.h"
#include "simulation/solver/model_help.h"
#include "simulation/options.h"

static inline void externalInputallocate1(DATA* data, FILE * pFile);
static inline void externalInputallocate2(DATA* data, char *filename);

int externalInputallocate(DATA* data)
{
  FILE * pFile = NULL;
  int i,j;
  short useLibCsvH = 1;
  char * cflags = NULL;


  cflags = (char*)omc_flagValue[FLAG_INPUT_CSV];
  if(!cflags){
    cflags = (char*)omc_flagValue[FLAG_INPUT_FILE];
    useLibCsvH = 0;
    if(cflags){
      pFile = fopen(cflags,"r");
      if(pFile == NULL)
        warningStreamPrint(LOG_STDOUT, 0, "OMC can't find the file %s.",cflags);
    }else
      pFile = fopen("externalInput.csv","r");
  }



  data->simulationInfo->external_input.active = (modelica_boolean) (pFile != NULL);
  if(data->simulationInfo->external_input.active || useLibCsvH){
    if(useLibCsvH){
      externalInputallocate2(data, cflags);
    }else
      externalInputallocate1(data, pFile);

    if(ACTIVE_STREAM(LOG_SIMULATION))
    {
      printf("\nExternal Input");
      printf("\n========================================================");
      for(i = 0; i < data->simulationInfo->external_input.n; ++i){
        printf("\nInput: t=%f   \t", data->simulationInfo->external_input.t[i]);
        for(j = 0; j < data->modelData->nInputVars; ++j){
          printf("u%d(t)= %f \t",j+1,data->simulationInfo->external_input.u[i][j]);
        }
      }
      printf("\n========================================================\n");
    }

    data->simulationInfo->external_input.i = 0;
  }

  return 0;
}

static inline void externalInputallocate2(DATA* data, char *filename){
  int i, j, k;
  struct csv_data *res = read_csv(filename);
  data->modelData->nInputVars = res->numvars - 1;
  data->simulationInfo->external_input.n = res->numsteps;
  data->simulationInfo->external_input.N = data->simulationInfo->external_input.n;

  data->simulationInfo->external_input.u = (modelica_real**)calloc(modelica_integer_max(1,res->numsteps),sizeof(modelica_real*));
  for(i = 0; i<data->simulationInfo->external_input.n; ++i)
    data->simulationInfo->external_input.u[i] = (modelica_real*)calloc(modelica_integer_max(1,data->modelData->nInputVars),sizeof(modelica_real));
  data->simulationInfo->external_input.t = (modelica_real*)calloc(modelica_integer_max(1,data->simulationInfo->external_input.n),sizeof(modelica_real));


  for(i = 0, k= 0; i < data->simulationInfo->external_input.n; ++i)
    data->simulationInfo->external_input.t[i] = res->data[k++];
  for(j = 0; j < data->modelData->nInputVars; ++j){
    for(i = 0; i < data->simulationInfo->external_input.n; ++i){
      data->simulationInfo->external_input.u[i][j] = res->data[k++];
    }
  }
  omc_free_csv_reader(res);
  data->simulationInfo->external_input.active = data->simulationInfo->external_input.n > 0;
}

static inline void externalInputallocate1(DATA* data, FILE * pFile){
	int n,m,c;
	int i,j;
	n = 0;

	while(1) {
		c = fgetc(pFile);
		if (c==EOF) break;
		if (c=='\n') ++n;
	}
	// check if csv file is empty!
	if (n == 0)
	{
	  fprintf(stderr, "External input file: externalInput.csv is empty!\n"); fflush(NULL);
	  EXIT(1);
	}

	--n;
	data->simulationInfo->external_input.n = n;
	data->simulationInfo->external_input.N = data->simulationInfo->external_input.n;
	rewind(pFile);

	do{
	  c = fgetc(pFile);
	  if (c==EOF) break;
	}while(c!='\n');

	m = data->modelData->nInputVars;
	data->simulationInfo->external_input.u = (modelica_real**)calloc(modelica_integer_max(1,n),sizeof(modelica_real*));
	for(i = 0; i<data->simulationInfo->external_input.n; ++i)
	  data->simulationInfo->external_input.u[i] = (modelica_real*)calloc(modelica_integer_max(1,m),sizeof(modelica_real));
	data->simulationInfo->external_input.t = (modelica_real*)calloc(modelica_integer_max(1,data->simulationInfo->external_input.n),sizeof(modelica_real));

	for(i = 0; i < data->simulationInfo->external_input.n; ++i){
	  c = fscanf(pFile, "%lf", &data->simulationInfo->external_input.t[i]);
	  for(j = 0; j < m; ++j){
		c = fscanf(pFile, "%lf", &data->simulationInfo->external_input.u[i][j]);
	  }
	  if(c<0)
		data->simulationInfo->external_input.n = i;
	}
	fclose(pFile);
}

int externalInputFree(DATA* data)
{
  if(data->simulationInfo->external_input.active){
    int j;

    free(data->simulationInfo->external_input.t);
    for(j = 0; j < data->simulationInfo->external_input.N; ++j)
      free(data->simulationInfo->external_input.u[j]);
    free(data->simulationInfo->external_input.u);
    data->simulationInfo->external_input.active = 0;
  }
  return 0;
}


int externalInputUpdate(DATA* data)
{
  double u1, u2;
  double t, t1, t2;
  long double dt;
  int i;

  if(!data->simulationInfo->external_input.active){
    return -1;
  }

  t = data->localData[0]->timeValue;
  t1 = data->simulationInfo->external_input.t[data->simulationInfo->external_input.i];
  t2 = data->simulationInfo->external_input.t[data->simulationInfo->external_input.i+1];

  while(data->simulationInfo->external_input.i > 0 && t < t1){
    --data->simulationInfo->external_input.i;
    t1 = data->simulationInfo->external_input.t[data->simulationInfo->external_input.i];
    t2 = data->simulationInfo->external_input.t[data->simulationInfo->external_input.i+1];
  }

  while(t > t2
        && data->simulationInfo->external_input.i+1 < (data->simulationInfo->external_input.n-1)){
    ++data->simulationInfo->external_input.i;
    t1 = data->simulationInfo->external_input.t[data->simulationInfo->external_input.i];
    t2 = data->simulationInfo->external_input.t[data->simulationInfo->external_input.i+1];
  }

  if(t == t1){
    for(i = 0; i < data->modelData->nInputVars; ++i){
      data->simulationInfo->inputVars[i] = data->simulationInfo->external_input.u[data->simulationInfo->external_input.i][i];
    }
    return 1;
  }else if(t == t2){
    for(i = 0; i < data->modelData->nInputVars; ++i){
      data->simulationInfo->inputVars[i] = data->simulationInfo->external_input.u[data->simulationInfo->external_input.i+1][i];
    }
    return 1;
  }

  dt = (data->simulationInfo->external_input.t[data->simulationInfo->external_input.i+1] - data->simulationInfo->external_input.t[data->simulationInfo->external_input.i]);
  for(i = 0; i < data->modelData->nInputVars; ++i){
    u1 = data->simulationInfo->external_input.u[data->simulationInfo->external_input.i][i];
    u2 = data->simulationInfo->external_input.u[data->simulationInfo->external_input.i+1][i];

    if(u1 != u2){
      data->simulationInfo->inputVars[i] =  (u1*(dt+t1-t)+(t-t1)*u2)/dt;
    }else{
      data->simulationInfo->inputVars[i] = u1;
    }
  }
 return 0;
}

