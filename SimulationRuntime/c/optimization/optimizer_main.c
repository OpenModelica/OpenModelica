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

/*! optimizer_main.c
 * move model data in optimizer structure
 */

#include "OptimizerData.h"
#include "OptimizerLocalFunction.h"
#include "simulation_data.h"
#include "simulation/options.h"

static inline void optimizationWithIpopt(OptData*optData);
static inline void freeOptimizerData(OptData*optData);

int runOptimizer(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo){
  OptData *optData, optData_;

  solverInfo->solverData = &optData_;

  pickUpModelData(data, threadData, solverInfo);
  optData =  (OptData*) solverInfo->solverData;

  initial_guess_optimizer(optData, solverInfo);
  allocate_der_struct(&optData->s, &optData->dim ,data, optData);

  optimizationWithIpopt(optData);
  res2file(optData, solverInfo, optData->ipop.vopt);
  freeOptimizerData(optData);
  return 0;
}

/*!
 *  run optimization with ipopt
 *  author: Vitalij Ruge
 **/
static inline void optimizationWithIpopt(OptData*optData){
  IpoptProblem nlp = NULL;

  const int NV = optData->dim.NV;
  const int NRes = optData->dim.NRes;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const int nx = optData->dim.nx;
  const int NJ = optData->dim.nJderx;
  const int NJf = optData->dim.nJfderx;
  const int nH0 = optData->dim.nH0_;
  const int nH1 = optData->dim.nH1_;
  const int njac = np*(NJ*nsi + nx*(np*nsi - 1)) + NJf;
  const int nhess = (nsi*np-1)*nH0+nH1;

  Number * Vmin = optData->bounds.Vmin;
  Number * Vmax = optData->bounds.Vmax;
  Number * gmin = optData->ipop.gmin;
  Number * gmax = optData->ipop.gmax;
  Number * vopt = optData->ipop.vopt;
  Number * mult_g = optData->ipop.mult_g;
  Number * mult_x_L = optData->ipop.mult_x_L;
  Number * mult_x_U = optData->ipop.mult_x_U;
  Number obj;

  char *cflags;
  int max_iter = 5000;
  int res = 0;

  nlp = CreateIpoptProblem(NV, Vmin, Vmax,
      NRes, gmin, gmax, njac, nhess, 0, &evalfF,
                 &evalfG, &evalfDiffF, &evalfDiffG, &ipopt_h);

  /********************************************************************/
  /*******************       ipopt flags       ************************/
  /********************************************************************/

  /*tol */
  AddIpoptNumOption(nlp, "tol", optData->data->simulationInfo.tolerance);
  AddIpoptStrOption(nlp, "evaluate_orig_obj_at_resto_trial", "yes");

  /* print level */
  if(ACTIVE_STREAM(LOG_IPOPT_FULL)){
    AddIpoptIntOption(nlp, "print_level", 7);
  }else if(ACTIVE_STREAM(LOG_IPOPT)){
    AddIpoptIntOption(nlp, "print_level", 5);
  }else if(ACTIVE_STREAM(LOG_STATS)){
    AddIpoptIntOption(nlp, "print_level", 3);
  }else {
    AddIpoptIntOption(nlp, "print_level", 2);
  }
  AddIpoptIntOption(nlp, "file_print_level", 0);

  /* derivative_test */
  if(ACTIVE_STREAM(LOG_IPOPT_JAC) && ACTIVE_STREAM(LOG_IPOPT_HESSE)){
    AddIpoptIntOption(nlp, "print_level", 4);
    AddIpoptStrOption(nlp, "derivative_test", "second-order");
  }else if(ACTIVE_STREAM(LOG_IPOPT_JAC)){
    AddIpoptIntOption(nlp, "print_level", 4);
    AddIpoptStrOption(nlp, "derivative_test", "first-order");
  }else if(ACTIVE_STREAM(LOG_IPOPT_HESSE)){
    AddIpoptIntOption(nlp, "print_level", 4);
    AddIpoptStrOption(nlp, "derivative_test", "only-second-order");
  }else{
    AddIpoptStrOption(nlp, "derivative_test", "none");
  }


  cflags = (char*)omc_flagValue[FLAG_IPOPT_HESSE];
  if(cflags){
    if(!strcmp(cflags,"BFGS"))
      AddIpoptStrOption(nlp, "hessian_approximation", "limited-memory");
    else if(!strcmp(cflags,"const") || !strcmp(cflags,"CONST"))
      AddIpoptStrOption(nlp, "hessian_constant", "yes");
    else if(!(!strcmp(cflags,"num") || !strcmp(cflags,"NUM")))
      warningStreamPrint(LOG_STDOUT, 0, "not support ipopt_hesse=%s",cflags);
  }

  /*linear_solver e.g. mumps, MA27, MA57,...
   * be sure HSL solver are installed if your try HSL solver*/
  cflags = (char*)omc_flagValue[FLAG_LS_IPOPT];
  if(cflags)
    AddIpoptStrOption(nlp, "linear_solver", cflags);
  AddIpoptNumOption(nlp,"mumps_pivtolmax",1e-5);


  /* max iter */
  cflags = (char*)omc_flagValue[FLAG_IPOPT_MAX_ITER];
  if(cflags){
    char buffer[100];
    char c;
    int index_e = -1, i = 0;
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
      if(max_iter >= 0)
        AddIpoptIntOption(nlp, "max_iter", max_iter);
      printf("\nmax_iter = %i",atoi(cflags));

    }else{
      max_iter =  (atoi(cflags)*pow(10.0, (double)atoi(cflags+index_e+1)));
      if(max_iter >= 0)
        AddIpoptIntOption(nlp, "max_iter", (int)max_iter);
      printf("\nmax_iter = (int) %i | (double) %g",(int)max_iter, atoi(cflags)*pow(10.0, (double)atoi(cflags+index_e+1)));
    }
  }else
    AddIpoptIntOption(nlp, "max_iter", 5000);

  /*heuristic optition */
  {
    int ws = 0;
    cflags = (char*)omc_flagValue[FLAG_IPOPT_WARM_START];
    if(cflags){
      ws = atoi(cflags);
    }

    if(ws > 0){
      double shift = pow(10,-1.0*ws);
      AddIpoptNumOption(nlp,"mu_init",shift);
      AddIpoptNumOption(nlp,"bound_mult_init_val",shift);
      AddIpoptStrOption(nlp,"mu_strategy", "monotone");
      AddIpoptNumOption(nlp,"bound_push", 1e-5);
      AddIpoptNumOption(nlp,"bound_frac", 1e-5);
      AddIpoptNumOption(nlp,"slack_bound_push", 1e-5);
      AddIpoptNumOption(nlp,"constr_mult_init_max", 1e-5);
      AddIpoptStrOption(nlp,"bound_mult_init_method","mu-based");
    }else{
      AddIpoptStrOption(nlp,"mu_strategy","adaptive");
      AddIpoptStrOption(nlp,"bound_mult_init_method","constant");
    }
    AddIpoptStrOption(nlp,"fixed_variable_treatment","make_parameter");
    AddIpoptStrOption(nlp,"dependency_detection_with_rhs","yes");
    AddIpoptNumOption(nlp,"nu_init",1e-9);
    AddIpoptNumOption(nlp,"eta_phi",1e-10);
  }

  /********************************************************************/


  if(max_iter >=0){
    optData->iter_ = 0.0;
    optData->index = 1;
    res = IpoptSolve(nlp, vopt, NULL, &obj, mult_g, mult_x_L, mult_x_U, (void*)optData);
  }
  if(res != 0 && !ACTIVE_STREAM(LOG_IPOPT))
    warningStreamPrint(LOG_STDOUT, 0, "No optimal solution found!\nUse -lv=LOG_IPOPT for more information.");
  FreeIpoptProblem(nlp);
}


static inline void freeOptimizerData(OptData*optData){
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const int nv = optData->dim.nv;
  const int nJ = optData->dim.nJ;

  int i,j,k;

  /*************************/
  for(i=0; i < nsi; ++i)
    free(optData->time.t[i]);
  free(optData->time.t);
  free(optData->time.dt);
  /*************************/
  free(optData->bounds.vmin);
  free(optData->bounds.vmax);
  free(optData->bounds.Vmin);
  free(optData->bounds.Vmax);
  free(optData->bounds.vnom);
  free(optData->bounds.scalF);
  for(i=0; i < nsi; ++i)
    free(optData->bounds.scaldt[i]);
  free(optData->bounds.scaldt);
  for(i = 0; i < nsi; ++i){
    free(optData->bounds.scalb[i]);
  }
  free(optData->bounds.scalb);
  free(optData->bounds.u0);
  /*************************/
  free(optData->ipop.vopt);
  free(optData->ipop.gmin);
  free(optData->ipop.gmax);
  free(optData->ipop.mult_g);
  free(optData->ipop.mult_x_L);
  free(optData->ipop.mult_x_U);
  /*************************/

  for(k = 0; k < nv; ++k){
    free(optData->s.H0[k]);
    free(optData->s.H1[k]);
    free(optData->s.Hm[k]);
    free(optData->s.Hl[k]);
  }
  free(optData->s.H0);
  free(optData->s.H1);
  free(optData->s.Hm);
  free(optData->s.Hl);
  for(j = 0; j < nJ; ++j){
    for(k = 0; k < nv; ++k)
      free(optData->s.Hg[j][k]);
    free(optData->s.Hg[j]);
  }
  free(optData->s.Hg);
  free(optData->s.lindex);
  free(optData->s.seedVec);
  free(optData->s.indexCon2);
  free(optData->s.indexCon3);
  free(optData->s.indexJ2);
  free(optData->s.indexJ3);

  /*************************/
  for(i = 0; i < nsi; ++i){
    for(j = 0; j < np; ++j){
      free(optData->v[i][j]);
    }
    free(optData->v[i]);
  }
  free(optData->v);
  free(optData->v0);
  free(optData->sv0);
  free(optData->b0);
  free(optData->i0);
  free(optData->b0Pre);
  free(optData->i0Pre);
  free(optData->v0Pre);
  free(optData->rePre);
  free(optData->re);
  free(optData->storeR);

  for(i = 0; i < nsi; ++i){
    for(j = 0; j < np; ++j){
      for(k = 0; k < nJ; ++k)
        free(optData->J[i][j][k]);
      free(optData->J[i][j]);
    }
    free(optData->J[i]);
  }
  free(optData->J);
  for(k = 0; k < nJ; ++k)
    free(optData->tmpJ[k]);
  for(k = 0; k < nJ; ++k){
    for(j = 0; j < nv; ++j){
      free(optData->H[k][j]);
    }
    free(optData->H[k]);
  }
  free(optData->H);
  for(j = 0; j < nv; ++j){
    free(optData->Hl[j]);
    free(optData->Hm[j]);
  }
  free(optData->Hl);
  free(optData->Hm);
  if(optData->dim.updateHessian > 0)
    free(optData->oldH);

  free(optData->dim.inputName);

  for(k = 0; k < 2; ++k){
  if(optData->s.matrix[2+k]){
    for(i = 0; i< nsi; ++i){
      for(j = 0; j< np; ++j){
        free(optData->dim.analyticJacobians_tmpVars[k][i][j]);
      }
      free(optData->dim.analyticJacobians_tmpVars[k][i]);
    }
    free(optData->dim.analyticJacobians_tmpVars[k]);
  }
  }
  free(optData->dim.analyticJacobians_tmpVars);

  for(i = 0; i< optData->dim.nJ; ++i)
    free(optData->s.JderCon[i]);
  free(optData->s.JderCon);
  free(optData->s.gradM);
  free(optData->s.gradL);
}
