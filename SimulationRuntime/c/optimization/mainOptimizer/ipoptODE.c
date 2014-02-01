/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköping University, either from the above address,
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

/*
 * Developed by:
 * FH-Bielefeld
 * Developer: Vitalij Ruge
 * Contact: vitalij.ruge@fh-bielefeld.de
 */


#include "../ipoptODEstruct.h"
#include "../simulation/solver/solver_main.h"
#include "../OptimizationFlags.h"
#include "../localFunction.h"
#include "../../simulation/results/simulation_result.h"
#include "../../simulation/options.h"

#ifdef WITH_IPOPT

static int res2file(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo);

/*!
 *  start main optimization step
 *  author: Vitalij Ruge
 **/
int startIpopt(DATA* data, SOLVER_INFO* solverInfo, int flag)
{
  int i;
  int j,k,l;
  double obj;
  int res;
  char *cflags;
  double tmp;

  IpoptProblem nlp = NULL;
  IPOPT_DATA_ *iData = ((IPOPT_DATA_*)solverInfo->solverData);
  iData->current_var = 0;
  iData->current_time = 0;
  iData->data = data;
  iData->mayer = (short) (iData->data->callback->mayer(data, &obj) >= 0);
  iData->lagrange = (short) (iData->data->callback->lagrange(data, &obj) >= 0);

  iData->mayer_index = 0;
  iData->lagrange_index = (iData->mayer)? 1 : 0;

  iData->matrixA = data->callback->initialAnalyticJacobianA((void*) iData->data);
  iData->matrixB = data->callback->initialAnalyticJacobianB((void*) iData->data);
  iData->matrixC = data->callback->initialAnalyticJacobianC((void*) iData->data);
  //iData->matrixD = data->callback->initialAnalyticJacobianD((void*) iData->data);

  loadDAEmodel(data, iData);
  iData->index_debug_iter=0;
  iData->degub_step =  10;
  iData->index_debug_next=0;

  /*ToDo*/
  for(i=0; i<(*iData).nx; i++)
  {
    iData->Vmin[i] = (*iData).Vmax[i] = (*iData).x0[i]*iData->scalVar[i];
    iData->v[i] = iData->Vmin[i];
  }

  initial_guess_ipopt(iData,solverInfo);

  if(ACTIVE_STREAM(LOG_IPOPT)){
  for(i=0; i<iData->nx; i++)
    printf("\nx[%i] = %s = %g | %g",i, iData->data->modelData.realVarsData[i].info.name,iData->v[i],iData->vnom[i]);
    for(; i<iData->nv; ++i)
      printf("\nu[%i] = %s = %g| %g",i, iData->data->modelData.realVarsData[iData->index_u + i-iData->nx].info.name,iData->v[i],iData->vnom[i]);
  }

  ipoptDebuge(iData,iData->v);

  if(flag == 5)
  {
     nlp = CreateIpoptProblem(iData->NV, iData->Vmin, iData->Vmax,
         iData->NRes +iData->nc*iData->deg*iData->nsi, iData->gmin, iData->gmax, iData->njac, iData->nhess, 0, &evalfF,
                  &evalfG, &evalfDiffF, &evalfDiffG, &ipopt_h);

    AddIpoptNumOption(nlp, "tol", iData->data->simulationInfo.tolerance);

    if(ACTIVE_STREAM(LOG_IPOPT)){
      AddIpoptIntOption(nlp, "print_level", 5);
    } else if(ACTIVE_STREAM(LOG_STATS)){
      AddIpoptIntOption(nlp, "print_level", 3);
    } else {
      AddIpoptIntOption(nlp, "print_level", 2);
    }
    AddIpoptIntOption(nlp, "file_print_level", 0);

    AddIpoptStrOption(nlp, "mu_strategy", "adaptive");


    cflags = (char*)omc_flagValue[FLAG_IPOPT_HESSE];
    if(cflags){
      if(!strcmp(cflags,"BFGS"))
        AddIpoptStrOption(nlp, "hessian_approximation", "limited-memory");
    }


    cflags = (char*)omc_flagValue[FLAG_LS_IPOPT];
    if(cflags)
      AddIpoptStrOption(nlp, "linear_solver", cflags);
    else
      AddIpoptStrOption(nlp, "linear_solver", "mumps");

     AddIpoptStrOption(nlp,"nlp_scaling_method","gradient-based");
     AddIpoptNumOption(nlp,"mu_init",1e-6);
     if(ACTIVE_STREAM(LOG_JAC)){
       AddIpoptIntOption(nlp, "print_level", 4);
       AddIpoptStrOption(nlp, "derivative_test", "second-order");
     }
     /*AddIpoptStrOption(nlp, "derivative_test_print_all", "yes");*/
    /* AddIpoptNumOption(nlp,"derivative_test_perturbation",1e-6); */
    AddIpoptIntOption(nlp, "max_iter", 5000);

    res = IpoptSolve(nlp, iData->v, NULL, &obj, iData->mult_g, iData->mult_x_L, iData->mult_x_U, (void*)iData);

    FreeIpoptProblem(nlp);

    if(ACTIVE_STREAM(LOG_IPOPT))
    {
      for(i =0; i<iData->nv;++i)
        if(iData->pFile[i])
          fclose(iData->pFile[i]);
      if(iData->pFile)
        free(iData->pFile);
    }

    iData->current_var = 0;
    res2file(iData,solverInfo);
  }
  return 0;
}

/*!
 *  eval model DAE
 *  author: Vitalij Ruge
 **/
int refreshSimData(double *x, double *u, double t, IPOPT_DATA_ *iData)
{
  int i,j,k;
  DATA* data = iData->data;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);
  for(j = 0; j<iData->nx;++j)
  {
    sData->realVars[j] = x[j]*iData->vnom[j];
  }

  for(i = 0, k = iData->index_u; i<iData->nu;++i,++j,++k){
    data->simulationInfo.inputVars[i] = u[i]*iData->vnom[j];
  }
  data->callback->input_function(data);
  sData->timeValue = t;
  /* updateContinuousSystem(iData->data); */
  data->simulationInfo.discreteCall=1;
  /*data->callback->functionODE(data);*/
  data->callback->functionDAE(data);

  return 0;
}


/*!
 *  function write results in the cvs
 *  author: Lennart Ochel
 **/
int ipoptDebuge(IPOPT_DATA_ *iData, double *x)
{
  if(ACTIVE_STREAM(LOG_IPOPT))
  {
    int i,j,k;
    double tmp;
    
    if(iData->index_debug_iter++ < iData->index_debug_next)
      return 0;

    iData->index_debug_next += iData->degub_step;

    for(j=0; j<iData->nv; ++j)
    {
      fprintf(iData->pFile[j], "\n");
      fprintf(iData->pFile[j], "%ld,", iData->index_debug_iter);
    }

    for(i=0; i<iData->NV; ++i)
    {
      j = i % iData->nv;
      tmp = x[i]*iData->vnom[j];
      fprintf(iData->pFile[j], "%.16g,", tmp);
    }

    for(j=0; j<iData->nv; ++j)
      fprintf(iData->pFile[j], "\n");
  }

  return 0;
}


/*!
 *  write results in result file
 *  author: Vitalij Ruge
 **/
static int res2file(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo)
{
  int i,j,k =0;
  DATA * data = iData->data;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_INFO *simInfo = &(data->simulationInfo);
  solverInfo->currentTime = iData->time[0];
  
  while(solverInfo->currentTime < simInfo->stopTime)
  {
    for(i=0; i< iData->nx; ++i)
    {
      sData->realVars[i] = iData->v[k++]*iData->vnom[i];
    }
    
    for(i=0,j=iData->nx; i< iData->nu; ++i,++j){
      data->simulationInfo.inputVars[i] = iData->v[k++]*iData->vnom[j];
    }

    solverInfo->currentTime = iData->time[iData->current_time++];
    sData->timeValue = solverInfo->currentTime;

    data->simulationInfo.terminal = 1;
    data->callback->input_function(data);
    data->callback->functionDAE(data);
    sim_result.emit(&sim_result,data);
    data->simulationInfo.terminal = 0;
  }
  return 0;
}

#endif
