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
#include "../localFunction.h"
#include "../../simulation/results/simulation_result.h"
#include "../../simulation/options.h"

#ifdef WITH_IPOPT

static int res2file(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo);
static int set_optimizer_flags(IPOPT_DATA_ *iData,IpoptProblem *nlp);

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
  IPOPT_DATA_*iData = ((IPOPT_DATA_*)solverInfo->solverData);

  iData->current_var = 0;
  iData->current_time = 0;
  iData->data = data;

  iData->sopt.mayer = (modelica_boolean) (iData->data->callback->mayer(data, &obj) >= 0);
  iData->sopt.lagrange = (modelica_boolean) (iData->data->callback->lagrange(data, &obj) >= 0);

  iData->mayer_index = 0;
  iData->lagrange_index = (iData->sopt.mayer)? 1 : 0;

  iData->sopt.matrixA = (modelica_boolean)data->callback->initialAnalyticJacobianA((void*) iData->data);
  iData->sopt.matrixB = (modelica_boolean)data->callback->initialAnalyticJacobianB((void*) iData->data);
  iData->sopt.matrixC = (modelica_boolean)data->callback->initialAnalyticJacobianC((void*) iData->data);
  /*iData->matrixD = data->callback->initialAnalyticJacobianD((void*) iData->data);*/

  /*ToDo*/
  loadDAEmodel(data, iData);
  iData->index_debug_iter=0;
  iData->degub_step =  10;
  iData->index_debug_next=0;

  /*ToDo*/
  for(i=0; i<iData->dim.nx; i++)
  {
    iData->bounds.Vmin[i] = iData->bounds.Vmax[i] = iData->x0[i]*iData->scalVar[i];
    iData->v[i] = iData->bounds.Vmin[i];
  }

  initial_guess_ipopt(iData,solverInfo);

  ipoptDebuge(iData,iData->v);

  if(flag == 5){
    int tmp_dim = iData->dim.NRes +iData->dim.nc*iData->dim.deg*iData->dim.nsi;

    nlp = CreateIpoptProblem(iData->dim.NV, iData->bounds.Vmin, iData->bounds.Vmax,
        tmp_dim, iData->bounds.gmin, iData->bounds.gmax, iData->dim.njac, iData->dim.nhess, 0, &evalfF,
                  &evalfG, &evalfDiffF, &evalfDiffG, &ipopt_h);

    AddIpoptNumOption(nlp, "tol", 1e-8);
    res = set_optimizer_flags(iData,&nlp);

    if(res >= 0)
      res = IpoptSolve(nlp, iData->v, NULL, &obj, iData->mult_g, iData->mult_x_L, iData->mult_x_U, (void*)iData);
    if(res < 0 && !ACTIVE_STREAM(LOG_IPOPT))
      warningStreamPrint(LOG_STDOUT, 0, "No optimal solution found!\nUse -lv=LOG_IPOPT for more information.");

    FreeIpoptProblem(nlp);

    iData->current_var = 0;
    res2file(iData,solverInfo);
  }
  return 0;
}

/*!
 *  eval model DAE
 *  author: Vitalij Ruge
 **/
int refreshSimData(double *x, double *u, long double t, IPOPT_DATA_ *iData)
{
  int i,j;
  DATA* data = iData->data;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  /*MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);*/
  for(j = 0; j<iData->dim.nx;++j){
    sData->realVars[j] = x[j]*iData->vnom[j];
  }

  for(i = 0; i<iData->dim.nu;++i,++j){
    data->simulationInfo.inputVars[i] = u[i]*iData->vnom[j];
  }

  data->callback->input_function(data);
  sData->timeValue = (double) t;
  /* updateContinuousSystem(iData->data); */
  data->simulationInfo.discreteCall=1;
  data->callback->functionDAE(data);

  return 0;
}


/*!
 *  function write results in the cvs
 *  author: Lennart Ochel
 **/
int ipoptDebuge(IPOPT_DATA_ *iData, double *x)
{
  if(ACTIVE_STREAM(LOG_IPOPT_FULL)){
    int i,j,k;
    double tmp;
    
    if(iData->index_debug_iter++ < iData->index_debug_next)
      return 0;

    iData->index_debug_next += iData->degub_step;

    for(j=0; j<iData->dim.nv; ++j){
      fprintf(iData->pFile[j], "\n");
      fprintf(iData->pFile[j], "%ld,", iData->index_debug_iter);
    }

    for(i=0; i<iData->dim.NV; ++i){
      j = i % iData->dim.nv;
      tmp = x[i]*iData->vnom[j];
      fprintf(iData->pFile[j], "%.16g,", tmp);
    }

    for(j=0; j<iData->dim.nv; ++j)
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
  char buffer[4096];
  DATA * data = iData->data;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_INFO *simInfo = &(data->simulationInfo);
  FILE * pFile;

  solverInfo->currentTime = iData->dtime.time[0];
  
  pFile = fopen("optimizeInput.csv", "wt");
  fprintf(pFile, "%s ", "time");
  for(i=0; i< iData->dim.nu; ++i){
    sprintf(buffer, "%s", iData->input_name[i]);
    fprintf(pFile, "%s ", buffer);
  }
  fprintf(pFile, "%s", "\n");


  while(solverInfo->currentTime < simInfo->stopTime){
    for(i=0; i< iData->dim.nx; ++i){
      sData->realVars[i] = iData->v[k++]*iData->vnom[i];
    }
    
    fprintf(pFile, "%lf ",(double)iData->dtime.time[iData->current_time]);
    for(i=0,j=iData->dim.nx; i< iData->dim.nu; ++i,++j){
      data->simulationInfo.inputVars[i] = iData->v[k]*iData->vnom[j];
      fprintf(pFile, "%lf ", iData->v[k++]*iData->vnom[j]);
    }
    fprintf(pFile, "%s", "\n");

    solverInfo->currentTime = iData->dtime.time[iData->current_time++];
    sData->timeValue = solverInfo->currentTime;

    /*updateDiscreteSystem(data);*/
    data->callback->input_function(data);
    data->callback->functionDAE(data);

    sim_result.emit(&sim_result,data);
  }
  fclose(pFile);
  return 0;
}

/*!
 *  set optimizer options
 *  author: Vitalij Ruge
 **/
static int set_optimizer_flags(IPOPT_DATA_ *iData, IpoptProblem *nlp)
{
  char *cflags;
  int max_iter;

  AddIpoptNumOption(*nlp, "tol", iData->data->simulationInfo.tolerance);

  if(ACTIVE_STREAM(LOG_IPOPT)){
    AddIpoptIntOption(*nlp, "print_level", 5);
  }else if(ACTIVE_STREAM(LOG_STATS)){
    AddIpoptIntOption(*nlp, "print_level", 3);
  }else {
    AddIpoptIntOption(*nlp, "print_level", 2);
  }
  AddIpoptIntOption(*nlp, "file_print_level", 0);

  AddIpoptStrOption(*nlp, "mu_strategy", "adaptive");
  AddIpoptStrOption(*nlp, "fixed_variable_treatment", "make_parameter");

  cflags = (char*)omc_flagValue[FLAG_IPOPT_HESSE];
  if(cflags){
    if(!strcmp(cflags,"BFGS"))
      AddIpoptStrOption(*nlp, "hessian_approximation", "limited-memory");
    else if(!strcmp(cflags,"const") || !strcmp(cflags,"CONST"))
      AddIpoptStrOption(*nlp, "hessian_constant", "yes");
    else
      warningStreamPrint(LOG_STDOUT, 1, "not support ipopt_hesse=%s",cflags);
  }

  cflags = (char*)omc_flagValue[FLAG_LS_IPOPT];
  if(cflags)
    AddIpoptStrOption(*nlp, "linear_solver", cflags);

  //AddIpoptStrOption(*nlp,"nlp_scaling_method","gradient-based");
  //AddIpoptStrOption(*nlp,"linear_system_scaling","slack-based");
  AddIpoptStrOption(*nlp,"dependency_detection_with_rhs","yes");

  AddIpoptNumOption(*nlp,"bound_mult_init_val",1e-3);
  AddIpoptNumOption(*nlp,"mu_init",1e-3);
  AddIpoptNumOption(*nlp,"nu_init",1e-9);
  AddIpoptStrOption(*nlp,"bound_mult_init_method","constant");
  //AddIpoptStrOption(*nlp,"print_options_documentation","yes");
  //AddIpoptStrOption(*nlp,"bound_mult_init_method","mu-based");
  AddIpoptNumOption(*nlp,"eta_phi",1e-010);

  //dependency_detection_with_rhs


  if(ACTIVE_STREAM(LOG_IPOPT_JAC) && ACTIVE_STREAM(LOG_IPOPT_HESSE)){
    AddIpoptIntOption(*nlp, "print_level", 4);
    AddIpoptStrOption(*nlp, "derivative_test", "second-order");
  }else if(ACTIVE_STREAM(LOG_IPOPT_JAC)){
    AddIpoptIntOption(*nlp, "print_level", 4);
    AddIpoptStrOption(*nlp, "derivative_test", "first-order");
  }else if(ACTIVE_STREAM(LOG_IPOPT_HESSE)){
    AddIpoptIntOption(*nlp, "print_level", 4);
    AddIpoptStrOption(*nlp, "derivative_test", "only-second-order");
  }else{
    AddIpoptStrOption(*nlp, "derivative_test", "none");
  }

  if(ACTIVE_STREAM(LOG_IPOPT_FULL))
    AddIpoptIntOption(*nlp, "print_level", 7);

  /*
   * AddIpoptStrOption(nlp, "derivative_test_print_all", "yes");
   * AddIpoptNumOption(nlp,"derivative_test_perturbation",1e-6);
   *
   */
  cflags = (char*)omc_flagValue[FLAG_IPOPT_MAX_ITER];
  if(cflags){
    char buffer[100];
    char c;
    int index_e = -1,i=0;
    strcpy(buffer,cflags);

    while(buffer[i] != '\0'){
      if(buffer[i] == 'e'){
        index_e = i;
        break;
      }
      ++i;
    }

    if(index_e < 0){
      max_iter = atoi(cflags);
      if(max_iter < 0)
        return -1;
      AddIpoptIntOption(*nlp, "max_iter", max_iter);
      printf("\nmax_iter = %i",atoi(cflags));
    }else{
      max_iter =  (atoi(cflags)*pow(10.0, (double)atoi(cflags+index_e+1)));
      if(max_iter < 0)
        return -1;
      AddIpoptIntOption(*nlp, "max_iter", (int)max_iter);
      printf("\nmax_iter = (int) %i | (double) %g",(int)max_iter, atoi(cflags)*pow(10.0, (double)atoi(cflags+index_e+1)));
    }

  }else
    AddIpoptIntOption(*nlp, "max_iter", 5000);

  return 0;
}

#endif
