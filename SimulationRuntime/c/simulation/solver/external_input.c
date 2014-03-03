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
  m = 0;
  if(data->simulationInfo.external_input.active){

    while(1) {
        c = fgetc(pFile);
        if (c==EOF) break;
        if (c=='\n') ++n;
    }
    --n;
    data->simulationInfo.external_input.n = n;
    data->simulationInfo.external_input.N = data->simulationInfo.external_input.n;
    rewind(pFile);

    do{
      c = fgetc(pFile);
    }while(c!='\n');

    m = data->modelData.nInputVars;
    data->simulationInfo.external_input.u = (modelica_real**)calloc(n,sizeof(modelica_real*));
    for(i = 0; i<data->simulationInfo.external_input.n; ++i)
      data->simulationInfo.external_input.u[i] = (modelica_real*)calloc(m,sizeof(modelica_real));
    data->simulationInfo.external_input.t = (modelica_real*)calloc(data->simulationInfo.external_input.n,sizeof(modelica_real));

    for(i = 0; i < data->simulationInfo.external_input.n; ++i){
      c = fscanf(pFile, "%lf", &data->simulationInfo.external_input.t[i]);
      for(j = 0; j < m; ++j){
        c = fscanf(pFile, "%lf", &data->simulationInfo.external_input.u[i][j]);
      }
      if(c<0)
        data->simulationInfo.external_input.n = i;
    }

    if(ACTIVE_STREAM(LOG_SIMULATION)){
      printf("\nExternal Input");
      printf("\n========================================================");
      for(i = 0; i < data->simulationInfo.external_input.n; ++i){
        printf("\nInput: t=%f   \t", data->simulationInfo.external_input.t[i]);
        for(j = 0; j < m; ++j){
          printf("u%d(t)= %f \t",j+1,data->simulationInfo.external_input.u[i][j]);
        }
      }
      printf("\n========================================================\n");
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
    for(j = 0; j < data->simulationInfo.external_input.N; ++j)
      free(data->simulationInfo.external_input.u[j]);
    free(data->simulationInfo.external_input.u);
  }
  return 0;
}


int externalInputUpdate(DATA* data)
{
  double u1, u2;
  double t, t1, t2;
  long double dt;
  int i;

  if(!data->simulationInfo.external_input.active){
    return -1;
  }

  t = data->localData[0]->timeValue;
  t1 = data->simulationInfo.external_input.t[data->simulationInfo.external_input.i];
  t2 = data->simulationInfo.external_input.t[data->simulationInfo.external_input.i+1];

  while(data->simulationInfo.external_input.i > 0 && t < t1){
    --data->simulationInfo.external_input.i;
    t1 = data->simulationInfo.external_input.t[data->simulationInfo.external_input.i];
    t2 = data->simulationInfo.external_input.t[data->simulationInfo.external_input.i+1];
  }

  while(t > t2
        && data->simulationInfo.external_input.i+1 < (data->simulationInfo.external_input.n-1)){
    ++data->simulationInfo.external_input.i;
    t1 = data->simulationInfo.external_input.t[data->simulationInfo.external_input.i];
    t2 = data->simulationInfo.external_input.t[data->simulationInfo.external_input.i+1];
  }

  if(t == t1){
    for(i = 0; i < data->modelData.nInputVars; ++i){
      data->simulationInfo.inputVars[i] = data->simulationInfo.external_input.u[data->simulationInfo.external_input.i][i];
    }
    return 1;
  }else if(t == t2){
    for(i = 0; i < data->modelData.nInputVars; ++i){
      data->simulationInfo.inputVars[i] = data->simulationInfo.external_input.u[data->simulationInfo.external_input.i+1][i];
    }
    return 1;
  }

  dt = (data->simulationInfo.external_input.t[data->simulationInfo.external_input.i+1] - data->simulationInfo.external_input.t[data->simulationInfo.external_input.i]);
  for(i = 0; i < data->modelData.nInputVars; ++i){
    u1 = data->simulationInfo.external_input.u[data->simulationInfo.external_input.i][i];
    u2 = data->simulationInfo.external_input.u[data->simulationInfo.external_input.i+1][i];

    if(u1 != u2){
      data->simulationInfo.inputVars[i] =  (u1*(dt+t1-t)+(t-t1)*u2)/dt;
    }else{
      data->simulationInfo.inputVars[i] = u1;
    }
  }
 return 0;
}
