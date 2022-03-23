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

/* BB: ToDo's
 *
 * 1) Check pointer, especially, if there is no memory leak!
 * 2) Check necessary function evaluation and counting of it (use userdata->f, userdata->fOld)
 * 3) Use analytical Jacobian of the functionODE, if available
 * 4) Use sparsity pattern and kinsol solver
 * 5) Optimize evaluation of the Jacobian (e.g. in case it is constant)
 * 6) Introduce generic multirate-method, that might also be used for higher order
 *    ESDIRK and explicit RK methods
 * 7) Implement other ESDIRK methods
 *
 *
*/

/*! \file esdirkmr.c
 *  % Implementation of  multirate  DIRK method  ESDIRK2(1)3L[2]SA
 * (section 4.1.1 of the Carpenter & Kennedy NASA review), with variable time
 * step. Uses embedded method of order 1 for error estimation.
 *
 * Based on work from S. Fernandez Garcia, U. Sevilla
 * and L.Bonaventura,  Polimi  2020-22
 *
 *  \author bbachmann
 */

#include <string.h>
#include <float.h>

#include "simulation/results/simulation_result.h"
#include "util/omc_error.h"
#include "util/varinfo.h"
#include "model_help.h"
#include "external_input.h"
#include "newtonIteration.h"
#include "jacobianSymbolical.h"
#include "esdirkmr.h"
#include "simulation/options.h"

//auxiliary vector functions
void linear_interpolation(double a, double* fa, double b, double* fb, double t, double *f, int n);
void printVector_ESDIRKMR(char name[], double* a, int n, double time);
void printMatrix_ESDIRKMR(char name[], double* a, int n, double time);

// singlerate step function
int esdirkmr_imp_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int esdirkmr_impRK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);


/*! \fn allocateESDIRKMR
 *
 *   Function allocates memory needed for ESDIRK method.
 *
 */

int allocateESDIRKMR(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*) malloc(sizeof(DATA_ESDIRKMR));
  solverInfo->solverData = (void*) userdata;

  int size = data->modelData->nStates;
  /* only flags from 0 to 9 are supported */
  int RK_method;
  if(omc_flag[FLAG_RK])
    RK_method = ((int) *omc_flagValue[FLAG_RK]) - '0';

  if (!(RK_method >=0 && RK_method <= 5) || !(omc_flag[FLAG_RK]))
    RK_method = 0;
  switch(RK_method){
    case 0:
    //ESDIRK2_OPT
    // Reduced nonlinear system size
    // Systems solved in cascade
      userdata->stages = 3;
      userdata->expl = 0;
      userdata->nlSystemSize = size;
      userdata->step_fun = &(esdirkmr_imp_step);

      /* Butcher Tableau */
      userdata->order_b = 2;
      userdata->order_bt = 1;
      userdata->error_order = fmin(userdata->order_b, userdata->order_bt) + 1;

      userdata->c = malloc(sizeof(double)*userdata->stages);
      userdata->A = malloc(sizeof(double)*userdata->stages * userdata->stages);
      userdata->b = malloc(sizeof(double)*userdata->stages);
      userdata->bt = malloc(sizeof(double)*userdata->stages);

      /* initialize values of the Butcher tableau */
      userdata->gam = (2.0-sqrt(2.0))*0.5;
      userdata->c2 = 2.0*userdata->gam;
      userdata->b1 = sqrt(2.0)/4.0;
      userdata->b2 = userdata->b1;
      userdata->b3 = userdata->gam;
      userdata->bt1 = 1.75-sqrt(2.0);
      userdata->bt2 = userdata->bt1;
      userdata->bt3 = 2.0*sqrt(2.0)-2.5;

      const double c_ESDIRK2[] = {0.0 , userdata->c2, 1.0};
      const double A_ESDIRK2[] = {
                          0.0, 0.0, 0.0,
                          userdata->gam, userdata->gam, 0.0,
                          userdata->b1, userdata->b2, userdata->b3
                        };
      const double b_ESDIRK2[] = {userdata->b1, userdata->b2, userdata->b3};
      const double bt_ESDIRK2[] = {userdata->bt1, userdata->bt2, userdata->bt3};
      memcpy(userdata->c, c_ESDIRK2, userdata->stages*sizeof(double));
      memcpy(userdata->A, A_ESDIRK2, userdata->stages * userdata->stages * sizeof(double));
      memcpy(userdata->b, b_ESDIRK2, userdata->stages*sizeof(double));
      memcpy(userdata->bt, bt_ESDIRK2, userdata->stages*sizeof(double));

      infoStreamPrint(LOG_SOLVER, 0, "Optimized ESDIRK2 method:");
      break;

    case 1:
    //ESDIRK2
      userdata->stages = 3;
      userdata->expl = 0;
      userdata->nlSystemSize = userdata->stages*size;
      userdata->step_fun = &(esdirkmr_impRK);

      /* Butcher Tableau */
      userdata->order_b = 2;
      userdata->order_bt = 1;
      userdata->error_order = fmin(userdata->order_b, userdata->order_bt) + 1;

      userdata->c = malloc(sizeof(double)*userdata->stages);
      userdata->A = malloc(sizeof(double)*userdata->stages * userdata->stages);
      userdata->b = malloc(sizeof(double)*userdata->stages);
      userdata->bt = malloc(sizeof(double)*userdata->stages);

      /* initialize values of the Butcher tableau */
      userdata->gam = (2.0-sqrt(2.0))*0.5;
      userdata->c2 = 2.0*userdata->gam;
      userdata->b1 = sqrt(2.0)/4.0;
      userdata->b2 = userdata->b1;
      userdata->b3 = userdata->gam;
      userdata->bt1 = 1.75-sqrt(2.0);
      userdata->bt2 = userdata->bt1;
      userdata->bt3 = 2.0*sqrt(2.0)-2.5;

      const double c_ESDIRK2_N[] = {0.0 , userdata->c2, 1.0};
      const double A_ESDIRK2_N[] = {
                          0.0, 0.0, 0.0,
                          userdata->gam, userdata->gam, 0.0,
                          userdata->b1, userdata->b2, userdata->b3
                        };
      const double b_ESDIRK2_N[] = {userdata->b1, userdata->b2, userdata->b3};
      const double bt_ESDIRK2_N[] = {userdata->bt1, userdata->bt2, userdata->bt3};
      memcpy(userdata->c, c_ESDIRK2_N, userdata->stages*sizeof(double));
      memcpy(userdata->A, A_ESDIRK2_N, userdata->stages * userdata->stages * sizeof(double));
      memcpy(userdata->b, b_ESDIRK2_N, userdata->stages*sizeof(double));
      memcpy(userdata->bt, bt_ESDIRK2_N, userdata->stages*sizeof(double));

      infoStreamPrint(LOG_SOLVER, 0, "ESDIRK2 method as usual implicit RK method:");
      break;

      case 2:
     //IRKSCO
      userdata->stages = 3;
      userdata->expl = 0;
      userdata->nlSystemSize = userdata->stages*size;
      userdata->step_fun = &(esdirkmr_impRK);

      /* Butcher Tableau */
      userdata->order_b = 1;
      userdata->order_bt = 2;
      userdata->error_order = fmin(userdata->order_b, userdata->order_bt) + 1;

      userdata->c = malloc(sizeof(double)*userdata->stages);
      userdata->A = malloc(sizeof(double)*userdata->stages * userdata->stages);
      userdata->b = malloc(sizeof(double)*userdata->stages);
      userdata->bt = malloc(sizeof(double)*userdata->stages);

      const double c_IRKSCO[] = {0.0, 0.5, 1.0};
      const double A_IRKSCO[] = {0.0, 0.0, 0.0,
                                 0.0, 0.5, 0.0,
                                 0.0, 0.0, 1.0};
      const double b_IRKSCO[] = {0,0,1};
      const double bt_IRKSCO[] = {-1,0,2};
      memcpy(userdata->c, c_IRKSCO, userdata->stages*sizeof(double));
      memcpy(userdata->A, A_IRKSCO, userdata->stages * userdata->stages * sizeof(double));
      memcpy(userdata->b, b_IRKSCO, userdata->stages*sizeof(double));
      memcpy(userdata->bt, bt_IRKSCO, userdata->stages*sizeof(double));

      infoStreamPrint(LOG_SOLVER, 0, "New realization of the IRKSCO method:");
      break;

      case 3:
     //DOPRI
      userdata->stages = 7;
      userdata->expl = 1;
      userdata->nlSystemSize = size;
      userdata->step_fun = &(esdirkmr_imp_step);

      /* Butcher Tableau */
      userdata->order_b = 5;
      userdata->order_bt = 4;
      userdata->error_order = fmin(userdata->order_b, userdata->order_bt) + 1;

      userdata->c = malloc(sizeof(double)*userdata->stages);
      userdata->A = malloc(sizeof(double)*userdata->stages * userdata->stages);
      userdata->b = malloc(sizeof(double)*userdata->stages);
      userdata->bt = malloc(sizeof(double)*userdata->stages);

      const double c_DOPRI[] = {0.0, 1./5, 3./10, 4./5, 8./9, 1., 1.};
	    const double A_DOPRI[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                1./5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	 	                            3./40, 9./40, 0.0, 0.0, 0.0, 0.0, 0.0,
		                            44./45, -56./15, 32./9, 0.0, 0.0, 0.0, 0.0,
	 	                            19372./6561, -25360./2187, 64448./6561, -212./729, 0.0, 0.0, 0.0,
                                9017./3168, -355./33, 46732./5247, 49./176, -5103./18656, 0.0, 0.0,
                                35./384, 0.0, 500./1113, 125./192, -2187./6784, 11./84, 0.0
     };
      const double b_DOPRI[] = {35./384, 0.0, 500./1113, 125./192, -2187./6784, 11./84, 0.0};
      const double bt_DOPRI[] = {5179./57600, 	0.0, 	7571./16695, 	393./640, 	-92097./339200, 	187./2100, 	1./40};
      memcpy(userdata->c, c_DOPRI, userdata->stages*sizeof(double));
      memcpy(userdata->A, A_DOPRI, userdata->stages * userdata->stages * sizeof(double));
      memcpy(userdata->b, b_DOPRI, userdata->stages*sizeof(double));
      memcpy(userdata->bt, bt_DOPRI, userdata->stages*sizeof(double));

      infoStreamPrint(LOG_SOLVER, 0, "DOPRI(4/5):");
      break;

    case 4:
     //ESDIRK3
      userdata->stages = 4;
      userdata->expl = 0;
      userdata->nlSystemSize = userdata->stages*size;
      userdata->step_fun = &(esdirkmr_impRK);

      /* Butcher Tableau */
      userdata->order_b = 3;
      userdata->order_bt = 2;
      userdata->error_order = fmin(userdata->order_b, userdata->order_bt) + 1;

      userdata->c = malloc(sizeof(double)*userdata->stages);
      userdata->A = malloc(sizeof(double)*userdata->stages * userdata->stages);
      userdata->b = malloc(sizeof(double)*userdata->stages);
      userdata->bt = malloc(sizeof(double)*userdata->stages);

    //   double gam=0.43586652150845899941601945;
    //   double c3=3./5;
    //   double a32=(c3*(c3-2*gam))/(4*gam);
    //   double a31=c3-a32-gam;
    //   double A=1-6*gam+6*gam*gam;
    //   double b2=(-2+3*c3+6*gam*(1-c3))/(12*gam*(c3-2*gam));
    //   double b3=A/(3*c3*(c3-2*gam));
    //   double b4=gam;

    //   double b1=1-b2-b3-b4;
    //   double bt2=((c3*(-1+6*gam-24*gam*gam*gam+12*gam*gam*gam*gam-6*gam*gam*gam*gam*gam))/(4*gam*(2*gam-c3)*A)+
    //                 (3-27*gam+68*gam*gam-55*gam*gam*gam+21*gam*gam*gam*gam-6*gam*gam*gam*gam*gam)/(2*(2*gam-c3)*A));
    //   double bt3=((-gam*(-2+21*gam-68*gam*gam+79*gam*gam*gam-33*gam*gam*gam*gam+12*gam*gam*gam*gam*gam))/(c3*(c3-2*gam)*A));
    //   double bt4=(-3*gam*gam*(-1+4*gam-2*gam*gam+gam*gam*gam))/A;
    //   double bt1=1-bt2-bt3-bt4;

    //   const double c_ESDIRK3[] = {0.0, 2*gam, c3, 1};
	  //   const double A_ESDIRK3[] = {0.0, 0.0, 0.0, 0.0,
    //                               gam, gam, 0.0, 0.0,
	 	//                               a31, a32, gam, 0.0,
		//                               b1,  b2,  b3, gam
    //  };
    //   const double b_ESDIRK3[] = {b1, b2, b3, b4};
    //   const double bt_ESDIRK3[] = {bt1, bt2, bt3, bt4};

      const double c_ESDIRK3_N[]  = {0.0, 0.87173304301691799883203890238711368505858818587690, 3./5, 1.};

      const double A_ESDIRK3_N[]  = {0, 0, 0, 0,
                                  0.43586652150845899941601945119355684252929409293845, 0.43586652150845899941601945119355684252929409293845, 0.0, 0.0,
                                  0.25764824606642724579999601628407970926431835216613, -0.093514767574886245216015467477636551793612445104585, 0.43586652150845899941601945119355684252929409293845, 0.0,
                                  0.18764102434672382516129214416680439137952555421072, -0.59529747357695494804782302758588517377818522805180, 0.97178992772177212347051143222552393986936558090263, 0.43586652150845899941601945119355684252929409293845};

      const double b_ESDIRK3_N[]  = {0.18764102434672382516129214416680439137952555421072, -0.59529747357695494804782302758588517377818522805180, 0.97178992772177212347051143222552393986936558090263, 0.43586652150845899941601945119355684252929409293845};
      const double bt_ESDIRK3_N[] = {0.10889661761586445415613073807049608218243112728445, -0.91532581187071275348163809781681834549906345402560, 1.2712735973021521678447158941356428765353629368204, 0.53515559695269613148079146561067938678126938992075};

      memcpy(userdata->c, c_ESDIRK3_N, userdata->stages*sizeof(double));
      memcpy(userdata->A, A_ESDIRK3_N, userdata->stages * userdata->stages * sizeof(double));
      memcpy(userdata->b, b_ESDIRK3_N, userdata->stages*sizeof(double));
      memcpy(userdata->bt, bt_ESDIRK3_N, userdata->stages*sizeof(double));

      infoStreamPrint(LOG_SOLVER, 0, "ESDIRK3_N:");
      break;

    case 5:
     //ESDIRK3
      userdata->stages = 4;
      userdata->expl = 0;
      userdata->nlSystemSize = size;
      userdata->step_fun = &(esdirkmr_imp_step);

      /* Butcher Tableau */
      userdata->order_b = 3;
      userdata->order_bt = 2;
      userdata->error_order = fmin(userdata->order_b, userdata->order_bt) + 1;

      userdata->c = malloc(sizeof(double)*userdata->stages);
      userdata->A = malloc(sizeof(double)*userdata->stages * userdata->stages);
      userdata->b = malloc(sizeof(double)*userdata->stages);
      userdata->bt = malloc(sizeof(double)*userdata->stages);

      const double c_ESDIRK3[]  = {0.0, 0.87173304301691799883203890238711368505858818587690, 3./5, 1.};

      const double A_ESDIRK3[]  = {0, 0, 0, 0,
                                  0.43586652150845899941601945119355684252929409293845, 0.43586652150845899941601945119355684252929409293845, 0.0, 0.0,
                                  0.25764824606642724579999601628407970926431835216613, -0.093514767574886245216015467477636551793612445104585, 0.43586652150845899941601945119355684252929409293845, 0.0,
                                  0.18764102434672382516129214416680439137952555421072, -0.59529747357695494804782302758588517377818522805180, 0.97178992772177212347051143222552393986936558090263, 0.43586652150845899941601945119355684252929409293845};

      const double b_ESDIRK3[]  = {0.18764102434672382516129214416680439137952555421072, -0.59529747357695494804782302758588517377818522805180, 0.97178992772177212347051143222552393986936558090263, 0.43586652150845899941601945119355684252929409293845};
      const double bt_ESDIRK3[] = {0.10889661761586445415613073807049608218243112728445, -0.91532581187071275348163809781681834549906345402560, 1.2712735973021521678447158941356428765353629368204, 0.53515559695269613148079146561067938678126938992075};

      memcpy(userdata->c, c_ESDIRK3, userdata->stages*sizeof(double));
      memcpy(userdata->A, A_ESDIRK3, userdata->stages * userdata->stages * sizeof(double));
      memcpy(userdata->b, b_ESDIRK3, userdata->stages*sizeof(double));
      memcpy(userdata->bt, bt_ESDIRK3, userdata->stages*sizeof(double));

      infoStreamPrint(LOG_SOLVER, 0, "ESDIRK3:");
      break;

  }

  allocateNewtonData(userdata->nlSystemSize, &(userdata->solverData));

  userdata->firstStep = 1;
  userdata->y = malloc(sizeof(double)*size);
  userdata->yOld = malloc(sizeof(double)*size);
  userdata->yt = malloc(sizeof(double)*size);
  userdata->f = malloc(sizeof(double)*size);
  userdata->Jf = malloc(sizeof(double)*size*size);
  userdata->k = malloc(sizeof(double)*size*userdata->stages);
  userdata->res_const = malloc(sizeof(double)*size);
  userdata->errest = malloc(sizeof(double)*size);
  userdata->errtol = malloc(sizeof(double)*size);


  char Butcher_row[1024];
  infoStreamPrint(LOG_SOLVER, 1, "Butcher tableau of ESDIRK-method:");
  for (int i = 0; i<userdata->stages; i++)
  {
    sprintf(Butcher_row, "%10g | ", userdata->c[i]);
    for (int j = 0; j<userdata->stages; j++)
    {
      sprintf(Butcher_row, "%s %10g", Butcher_row, userdata->A[i*userdata->stages + j]);
    }
    infoStreamPrint(LOG_SOLVER, 0, "%s",Butcher_row);
  }
  infoStreamPrint(LOG_SOLVER, 0, "------------------------------------------------");
  sprintf(Butcher_row, "%10s | ", "");
  for (int j = 0; j<userdata->stages; j++)
  {
    sprintf(Butcher_row, "%s %10g", Butcher_row, userdata->b[j]);
  }
  infoStreamPrint(LOG_SOLVER, 0, "%s",Butcher_row);
  sprintf(Butcher_row, "%10s | ", "");
  for (int j = 0; j<userdata->stages; j++)
  {
    sprintf(Butcher_row, "%s %10g", Butcher_row, userdata->bt[j]);
  }
  infoStreamPrint(LOG_SOLVER, 0, "%s",Butcher_row);
  messageClose(LOG_SOLVER);

  /* initialize stats */
  userdata->stepsDone = 0;
  userdata->evalFunctionODE = 0;
  userdata->evalJacobians = 0;
  userdata->errorTestFailures = 0;
  userdata->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available */
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian))
  {
    userdata->symJac = 0;
    infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
  } else {
    userdata->symJac = 1;
    ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
    infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
    infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jac->sizeCols, jac->sizeRows);
    infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jac->sparsePattern->numberOfNonZeros, jac->sparsePattern->maxColors);
    messageClose(LOG_SOLVER);
  }

  return 0;
}

/*! \fn freeESDIRKmr
 *
 *   Memory needed for solver is set free.
 */
int freeESDIRKMR(SOLVER_INFO* solverInfo)
{
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*) solverInfo->solverData;
  freeNewtonData(&(userdata->solverData));

  free(userdata->y);
  free(userdata->yOld);
  free(userdata->yt);
  free(userdata->f);
  free(userdata->Jf);
  free(userdata->k);
  free(userdata->res_const);
  free(userdata->errest);
  free(userdata->errtol);
  free(userdata->A);
  free(userdata->b);
  free(userdata->bt);
  free(userdata->c);

  return 0;
}

/*!	\fn wrapper_f_ESDIRKMR
 *
 *  calculate function values of function ODE f(t,y)
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      data           data of the underlying DAE
 *  \param [in]      threadData     data for error handling
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [out]     stateDer       pointer to state derivatives
 *
 */
int wrapper_f_ESDIRKMR(DATA* data, threadData_t *threadData, void* userdata, modelica_real* stateDer)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  stateDer = sData->realVars + data->modelData->nStates;

  ESDIRKMRData->evalFunctionODE++;

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

/*
 * Sets element (i,j) in matrixA to given value val.
 */
void setJacElementESDIRKSparse(int i, int j, int nth, double val, void* Jf,
                              int rows)
{
  int l  = j*rows + i;
  ((double*) Jf)[l]=val;
}

/*!	\fn wrapper_Jf_ESDIRKMR
 *
 *  calculate the Jacobian of functionODE with respect to the states
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      n              pointer to number of states
 *  \param [in]      x              pointer to state vector
 *  \param [in]      fvec           pointer to corresponding fODE-values usually
 *                                  stored in userdata->f (verify before calling)
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [out]     fODE           pointer to state derivatives
 *
 *  result of the Jacobian is stored in solverData->fjac (DATA_NEWTON) ???????
 *
 */
int wrapper_Jf_ESDIRKMR(int* n, double* x, double* fvec, void* userdata, double* fODE)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  DATA* data = ESDIRKMRData->data;
  threadData_t* threadData = ESDIRKMRData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)ESDIRKMRData->solverData;

  double delta_h = sqrt(solverData->epsfcn);
  double delta_hh;
  double xsave;

  int i,j,l;

  /* profiling */
  rt_tick(SIM_TIMER_JACOBIAN);

  if (solverData->calculate_jacobian>=0)
  {
    ESDIRKMRData->evalJacobians++;

    if (ESDIRKMRData->symJac)
    {
      const int index = data->callback->INDEX_JAC_A;
      ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);

#ifdef USE_PARJAC
      //ANALYTIC_JACOBIAN* t_jac = (dasslData->jacColumns);
      ANALYTIC_JACOBIAN* t_jac = jac;
#else
      ANALYTIC_JACOBIAN* t_jac = jac;
#endif

      unsigned int columns = jac->sizeCols;
      unsigned int rows = jac->sizeRows;
      unsigned int sizeTmpVars = jac->sizeTmpVars;
      SPARSE_PATTERN* spp = jac->sparsePattern;

       /* Evaluate constant equations if available */
       // BB: Do I need this?
       if (jac->constantEqns != NULL) {
         jac->constantEqns(data, threadData, jac, NULL);
       }
       genericColoredSymbolicJacobianEvaluation(rows, columns, spp, ESDIRKMRData->Jf, t_jac,
                                           data, threadData, &setJacElementESDIRKSparse);
    }
    else
    {
      for(i = 0; i < *n; i++)
      {
        delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(fvec[i])), delta_h);
        delta_hh = ((fvec[i] >= 0) ? delta_hh : -delta_hh);
        delta_hh = x[i] + delta_hh - x[i];
        xsave = x[i];
        x[i] += delta_hh;
        delta_hh = 1. / delta_hh;

        wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);
        // this should not count on function evaluation, since
        // it belongs to jacobian evaluation
        ESDIRKMRData->evalFunctionODE--;

        /* BB: Is this necessary for the statistics? */
        solverData->nfev++;

        for(j = 0; j < *n; j++)
        {
          l = i * *n + j;
          ESDIRKMRData->Jf[l] = (fODE[j] - fvec[j]) * delta_hh;
        }
        x[i] = xsave;
      }
    }
    // Has to be refacturede for general RK method
    if (solverData->calculate_jacobian==0)
      solverData->calculate_jacobian = 1;
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  return 0;
}

/*!	\fn wrapper_DIRK
 *      residual function res = yOld-y+gam*h*(k1+f(tOld+c2*h,y)); c2=2*gam;
 *      i.e. solve for:
 *           y1g = yOld+gam*h*(k1+f(tOld+c2*h,y1g)) = yOld+gam*h*(k1+k2)
 *      <=>  k2  = f(tOld+c2*h,yOld+gam*h*(k1+k2))
 *
 *  calculate function values or jacobian matrix for Newton-solver
 *  \param [in]      n_p            pointer to number of states
 *  \param [in]      x              pointer to unknowns (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  res            pointer to residual function (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_DIRK(int* n_p, double* x, double* res, void* userdata, int fj)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  DATA* data = ESDIRKMRData->data;
  threadData_t* threadData = ESDIRKMRData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)ESDIRKMRData->solverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  int n = (*n_p);

  int i, j, l, k;

// index of diagonal element of A
  k = ESDIRKMRData->act_stage * ESDIRKMRData->stages + ESDIRKMRData->act_stage;
  if (fj)
  {
    // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
    // set correct time value and states of simulation system
    sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->c[ESDIRKMRData->act_stage]*ESDIRKMRData->stepSize;
    memcpy(sData->realVars, x, n*sizeof(double));
    wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    for (j=0; j<n; j++)
    {
      res[j] = ESDIRKMRData->res_const[j] - x[j] + ESDIRKMRData->stepSize * ESDIRKMRData->A[k]  * fODE[j];
    }
  }
  else
  {
    if (solverData->calculate_jacobian>=0)
    {
    /*!
     *  fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
     *  set correct time value and states of simulation system
     *  this should not count on function evaluation, since
     *  it belongs to the jacobian evaluation
     *  \ToBeChecked: This calculation maybe not be necessary since f has already
     *                just evaluated!
     */
    // sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->c2*ESDIRKMRData->stepSize;
    // memcpy(sData->realVars, x, n*sizeof(double));
    // wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);
    // ESDIRKMRData->evalFunctionODE--;

    /* store values for finite differences scheme
     * not necessary for analytic Jacobian */
    memcpy(ESDIRKMRData->f, fODE, n*sizeof(double));

    /* Calculate Jacobian of the ODE system, result is in solverData->fjac */
    wrapper_Jf_ESDIRKMR(n_p, x, ESDIRKMRData->f, userdata, fODE);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    // jacobian          Jac = -E + gam*h*Jf(tk+c2*h,x))
    for(i = 0; i < n; i++)
    {
      for(j = 0; j < n; j++)
      {
        l = i * n + j;
        solverData->fjac[l] = ESDIRKMRData->stepSize * ESDIRKMRData->A[k] * ESDIRKMRData->Jf[l];
        if (i==j) solverData->fjac[l] -= 1;
      }
    }
    solverData->calculate_jacobian=-1;
    }
  }
  return 0;
}
/*!	\fn wrapper_RK_ESDIRKMR
 *      residual function res = yOld-y+h*(b1*k1+b2*k2+b3*f(tk+h,y));
 *      i.e. solve for:
 *           y2g = yOld+h*(b1*k1+b2*k2+b3*f(tOld+h,y2g)) = yOld+h*(b1*k1+b2*k2+b3*f(tOld+h,y2g))
 *      <=>  k3  = f(tOld+h,yOld+h*(b1*k1+b2*k2+b3*k3))
 *
 *  calculate function values or jacobian matrix for Newton-solver
 *  \param [in]      n_p            pointer to number of states
 *  \param [in]      x              pointer to unknowns (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  res            pointer to residual function (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_RK(int* n_p, double* x, double* res, void* userdata, int fj)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  DATA* data = ESDIRKMRData->data;
  threadData_t* threadData = ESDIRKMRData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)ESDIRKMRData->solverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  int n = data->modelData->nStates;

  int i, j, k, l, ind, stages = ESDIRKMRData->stages;
  double sum;

  if (fj)
  {
    // k[i] = f(tOld + c[i]*h,x); x ~ yOld + h*(a[i][1]*k[1]+...+a[i][stages]*k[stages])
    // set correct time value and states of simulation system
    // residual function res = yOld-x[i]+h*(a[l][1]*k[1]+...+a[l][stages]*k[stages])
    // residual function res = yOld-x[i]+h*(a[l][1]*f(t[1],x[1])+...+a[l][stages]*f(t[stages],x[stages]))
    //printVector_ESDIRKMR("x ", x, stages * n, sData->timeValue);
    for (l=0; l<stages; l++)
    {
      for (i=0; i<n; i++)
      {
        res[l * n + i] = ESDIRKMRData->yOld[i] - x[l * n + i];
      }
    }
    for (k=0; k<stages; k++)
    {
      // calculate f[k] and sweap over the stages
      //printf("c[k] = %g\n",ESDIRKMRData->c[k]);
      sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->c[k] * ESDIRKMRData->stepSize;
      memcpy(sData->realVars, (x + k * n), n*sizeof(double));
      wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);
      memcpy(ESDIRKMRData->k + k * n, fODE, n*sizeof(double));
      for (l=0; l<stages; l++)
      {
        //printf("A[%d,%d] = %g  ",l,k,ESDIRKMRData->A[l * stages + k]);
        for (i=0; i<n; i++)
        {
          res[l * n + i] += ESDIRKMRData->stepSize * ESDIRKMRData->A[l * stages + k] * fODE[i];
        }
      }
      //printf("\n");
    }
    //printVector_ESDIRKMR("res ", res, stages * n, sData->timeValue);
  }
  else
  {
    if (solverData->calculate_jacobian>=0)
    {
    /*!
     *  fODE = f(tOld + h,x); x ~ yOld + h*(b1*k1+b2*k2+b3*k3)
     *  set correct time value and states of simulation system
     *  this should not count on function evaluation, since
     *  it belongs to the jacobian evaluation
     *  \ToBeChecked: This calculation maybe not be necessary since f has already
     *                just evaluated! works so far
     */
    // sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->stepSize;
    // memcpy(sData->realVars, x, n*sizeof(double));
    // wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);
    // ESDIRKMRData->evalFunctionODE--;

    /* store values for finite differences scheme
     * not necessary for analytic Jacobian */
    //memcpy(ESDIRKMRData->f, fODE, n*sizeof(double));

    /* Calculate Jacobian of the ODE system, stored in  solverData->fjac */
    //wrapper_Jf_ESDIRKMR(&n, x, ESDIRKMRData->f, userdata, fODE);
    // set correct time value and states of simulation system

    // residual function res = yOld-x[i]+h*(a[l][1]*k[1]+...+a[l][stages]*k[stages])
    // residual function res = yOld-x[i]+h*(a[l][1]*f(t[1],x[1])+...+a[l][stages]*f(t[stages],x[stages]))
    // jacobian          Jac = -E + h*(a[l][1]*Jf(t[1],x[1])+...+a[l][stages]*Jf(t[stages],x[stages]))
    for (i=0; i < stages * n; i++)
    {
      for (j=0; j < stages * n; j++)
      {
        if (i==j)
          solverData->fjac[i * stages*n + j] = -1;
        else
          solverData->fjac[i * stages*n + j] = 0;
      }
    }
    //printMatrix_ESDIRKMR("Jacobian of solver", solverData->fjac, stages * n, ESDIRKMRData->time);
    for (k=0; k<stages && !ESDIRKMRData->expl; k++)
    {
      // calculate Jf[k] and sweap over the stages
      sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->c[k] * ESDIRKMRData->stepSize;
      memcpy(sData->realVars, (x + k * n), n*sizeof(double));
      // works only for analytical Jacobian!!!
      //printf("Hier: %d\n", k);
      wrapper_Jf_ESDIRKMR(&n, (x + k * n), ESDIRKMRData->f, userdata, fODE);
      //printMatrix_ESDIRKMR("Jacobian of system", ESDIRKMRData->Jf, n, sData->timeValue);
      //printMatrix_ESDIRKMR("Jacobian of solver", solverData->fjac, stages * n, sData->timeValue);
      for (l=0; l<stages; l++)
      {
        for (i=0; i<n; i++)
        {
          for (j=0; j<n; j++)
          {
            ind = l * stages * n * n + i * stages * n + j + k*n;
            solverData->fjac[ind] += ESDIRKMRData->stepSize * ESDIRKMRData->A[l * stages + k] * ESDIRKMRData->Jf[i * n + j];
            //solverData->fjac[ind] += ESDIRKMRData->Jf[i * n + j];
            //printf("Hier2: l=%d i=%d j=%d\n", l,i,j);
            //printMatrix_ESDIRKMR("Jacobian of solver", solverData->fjac, stages * n, ind);
          }
        }
      }
    }
    solverData->calculate_jacobian=-1;
    }
  }
  return 0;
}

/*!	\fn esdirkmr_imp_step
 *
 *  function does one implicit ESDIRK2 step with the stepSize given in stepSize
 *  function omc_newton is used for solving nonlinear system
 *  results will be saved in y and the embedded result in yt
 *
 */
int esdirkmr_imp_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  int i, j, l, k, n=data->modelData->nStates;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*) userdata->solverData;

  userdata->data = (void*) data;
  userdata->threadData = threadData;

  sData->timeValue = userdata->time;
  solverInfo->currentTime = sData->timeValue;

  solverData->initialized = 1;
  solverData->numberOfIterations = 0;
  solverData->numberOfFunctionEvaluations = 0;
  solverData->n = n;

  // setting the start vector for the newton step
  memcpy(solverData->x, userdata->yOld, n*sizeof(double));

  // sweep over the stages
  for (userdata->act_stage = 0; userdata->act_stage < userdata->stages; userdata->act_stage++)
  {
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    k = userdata->act_stage * userdata->stages;
    for (j=0; j<n; j++)
    {
      userdata->res_const[j] = userdata->yOld[j];
      for (l=0; l<userdata->act_stage; l++)
        userdata->res_const[j] += userdata->stepSize * userdata->A[k + l] * (userdata->k + l * n)[j];
    }

    // index of diagonal element of A
    k = userdata->act_stage * userdata->stages + userdata->act_stage;
    if (userdata->A[k] == 0)
    {
      // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
      // set correct time value and states of simulation system
      sData->timeValue = userdata->time + userdata->c[userdata->act_stage]*userdata->stepSize;
      memcpy(sData->realVars, userdata->res_const, n*sizeof(double));
      wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);
    }
    else
    {
      // solve for x: 0 = yold-x + h*(sum(a[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      // set good starting values for the newton solver (solution of the last newton iteration!)
      // set newton strategy
      solverData->newtonStrategy = NEWTON_DAMPED2;
      _omc_newton(wrapper_DIRK, solverData, (void*)userdata);
      /* if newton solver did not converge, do ??? */
      if (solverData->info == -1)
      {
        userdata->convergenceFailures++;
        // to be defined!
        // reject and reduce time step would be an option
        // or influence the calculation of the Jacobian during the newton steps
        solverData->numberOfIterations = 0;
        solverData->numberOfFunctionEvaluations = 0;
        solverData->calculate_jacobian = 1;

        warningStreamPrint(LOG_SOLVER, 0, "nonlinear solver did not converge at time %e, do iteration again with calculating jacobian in every step", solverInfo->currentTime);
        _omc_newton(wrapper_DIRK, solverData, (void*)userdata);

        solverData->calculate_jacobian = -1;
      }
    }
    // copy last calculation of stateDer, which should coincide with k[i]
    memcpy(userdata->k + userdata->act_stage * n, stateDer, n*sizeof(double));

  }

  return 0;
}

/*!	\fn esdirkmr_impRK
 *
 *  function does one implicit ESDIRK2 step with the stepSize given in stepSize
 *  function omc_newton is used for solving nonlinear system
 *  results will be saved in y and the embedded result in yt
 *
 */
int esdirkmr_impRK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  int i, j, k, l, n=data->modelData->nStates;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*) userdata->solverData;

  userdata->data = (void*) data;
  userdata->threadData = threadData;

  sData->timeValue = userdata->time;
  solverInfo->currentTime = sData->timeValue;

  solverData->initialized = 1;
  solverData->numberOfIterations = 0;
  solverData->numberOfFunctionEvaluations = 0;
  solverData->n = userdata->stages*n;

  // set good starting values for the newton solver
  for (k=0; k<userdata->stages; k++)
    memcpy((solverData->x + k*n), userdata->yOld, n*sizeof(double));
  // set newton strategy
  solverData->newtonStrategy = NEWTON_DAMPED2;
  _omc_newton(wrapper_RK, solverData, (void*)userdata);

  /* if newton solver did not converge, do ??? */
  if (solverData->info == -1)
  {
    userdata->convergenceFailures++;
    // to be defined!
    // reject and reduce time step would be an option
    // or influence the calculation of the Jacobian during the newton steps
    solverData->numberOfIterations = 0;
    solverData->numberOfFunctionEvaluations = 0;
    solverData->calculate_jacobian = 1;

    warningStreamPrint(LOG_SOLVER, 0, "nonlinear solver did not converge at time %e, do iteration again with calculating jacobian in every step", solverInfo->currentTime);
    _omc_newton(wrapper_RK, solverData, (void*)userdata);

    solverData->calculate_jacobian = -1;
  }

  return 0;
}

/*! \fn ESDIRKMR_first_step
 *
 *  function initializes values and calculates
 *  initial step size at the beginning or after an event
 *  BB: ToDo: lookup the reference in Hairers book
 *
 */
void ESDIRKMR_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*)solverInfo->solverData;
  const int n = data->modelData->nStates;
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  double Atol = 1e-6, Rtol = 1e-3;

  int i,j;

  /* store Startime of the simulation */
  userdata->time = sDataOld->timeValue;

  /* set correct flags in order to calculate initial step size */
  userdata->firstStep = 0;
  solverInfo->didEventStep = 0;

 /* reset statistics because it is accumulated in solver_main.c */
  userdata->stepsDone = 0;
  userdata->evalFunctionODE = 0;
  userdata->evalJacobians = 0;
  userdata->errorTestFailures = 0;
  userdata->convergenceFailures = 0;

  /* calculate starting step size 1st Version */
  /* BB: What is the difference between sData and sDataOld at this time instance?
         Is this important for the restart after an event?
         And should this also been copied to userdata->old (see above?)
  */
  /* initialize start values of the integrator and calculate ODE function*/
  //printVector_ESDIRKMR("sData->realVars: ", sData->realVars, data->modelData->nStates, sData->timeValue);
  //printVector_ESDIRKMR("sDataOld->realVars: ", sDataOld->realVars, data->modelData->nStates, sDataOld->timeValue);
  memcpy(userdata->yOld, sData->realVars, data->modelData->nStates*sizeof(double));
  wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);
  /* store values of the state derivatives at initial or event time */
  memcpy(userdata->f, stateDer, data->modelData->nStates*sizeof(double));

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(sDataOld->realVars[i])*Rtol;
    d0 += ((sDataOld->realVars[i] * sDataOld->realVars[i])/(sc*sc));
    d1 += ((stateDer[i] * stateDer[i]) / (sc*sc));
  }
  d0 /= data->modelData->nStates;
  d1 /= data->modelData->nStates;

  d0 = sqrt(d0);
  d1 = sqrt(d1);

  /* calculate first guess of the initial step size */
  if (d0 < 1e-5 || d1 < 1e-5)
  {
    h0 = 1e-6;
  }
  else
  {
    h0 = 0.01 * d0/d1;
  }


  for (i=0; i<data->modelData->nStates; i++)
  {
    sData->realVars[i] = userdata->yOld[i] + stateDer[i] * h0;
  }
  sData->timeValue += h0;

  wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(userdata->yOld[i])*Rtol;
    d2 += ((stateDer[i]-userdata->f[i])*(stateDer[i]-userdata->f[i])/(sc*sc));
  }

  d2 /= h0;
  d2 = sqrt(d2);


  d = fmax(d1,d2);

  if (d > 1e-15)
  {
    h1 = sqrt(0.01/d);
  }
  else
  {
    h1 = fmax(1e-6, h0*1e-3);
  }

  userdata->stepSize = 0.5*fmin(100*h0,h1);

  /* end calculation new step size */

  infoStreamPrint(LOG_SOLVER, 0, "initial step size = %e at time %g", userdata->stepSize, userdata->time);
}

/*! \fn esdirkmr_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'ESDIRKMR'
 */
int esdirkmr_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->solverData;

  double err;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;
  int i, l, n=data->modelData->nStates;
  int esdirk_imp_step_info;
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.3;
  double norm_errtol;
  double norm_errest;
  double targetTime;

  /* Calculate steps until targetTime is reached */
  if (solverInfo->integratorSteps) // 1 => stepSizeControl; 0 => equidistant grid
  {
    if (data->simulationInfo->nextSampleEvent < data->simulationInfo->stopTime)
    {
      targetTime = data->simulationInfo->nextSampleEvent;
    }
    else
    {
      targetTime = data->simulationInfo->stopTime;
    }
  }
  else
  {
    targetTime = sDataOld->timeValue + solverInfo->currentStepSize;
  }

  if (userdata->firstStep  || solverInfo->didEventStep == 1)
  {
    ESDIRKMR_first_step(data, threadData, solverInfo);
    // side effect:
    //    sData->realVars, userdata->yOld, and userdata->f are consistent
    //    userdata->time and userdata->stepSize are defined
  }

  while (userdata->time < targetTime)
  {
    do
    {
      /* calculate jacobian:
       *    once for the first iteration after initial or an event
       *    solverData->calculate_jacobian = 0
       *    always
       *    solverData->calculate_jacobian = 1
       *
       * BB: How does this actually works in combination with the Newton method?
       */
      if (userdata->stepsDone == 0)
        solverData->calculate_jacobian = 0;

      // calculate one step of the integrator
      esdirk_imp_step_info = userdata->step_fun(data, threadData, solverInfo);

      // printVector_ESDIRKMR("y ", userdata->y, data->modelData->nStates, userdata->time);
      // printVector_ESDIRKMR("yt ", userdata->yt, data->modelData->nStates, userdata->time);
      // y       = yold+h*sum(b[i]*k[i], i=1..stages);
      // yt      = yold+h*sum(bt[i]*k[i], i=1..stages);
      // calculate corresponding values for error estimator and step size control
      for (i=0; i<n; i++)
      {
        userdata->y[i]  = userdata->yOld[i];
        userdata->yt[i] = userdata->yOld[i];
        for (l=0; l<userdata->stages; l++)
        {
          userdata->y[i]  += userdata->stepSize * userdata->b[l]  * (userdata->k + l * n)[i];
          userdata->yt[i] += userdata->stepSize * userdata->bt[l] * (userdata->k + l * n)[i];
        }
        //userdata->errtol[i] = Rtol*fabs(userdata->yOld[i]) + Atol;
        userdata->errtol[i] = Rtol*fmax(fabs(userdata->y[i]),fabs(userdata->yt[i])) + Atol;
        userdata->errest[i] = fabs(userdata->y[i] - userdata->yt[i]);
      }

      //printVector_ESDIRKMR("y ", userdata->y, n, userdata->time);
      //printVector_ESDIRKMR("yt ", userdata->yt, n, userdata->time);



      /*** calculate error (infinity norm!)***/
      // norm_errtol = 0;
      // norm_errest = 0;
      // for (i=0; i<data->modelData->nStates; i++)
      // {
      //    norm_errtol = fmax(norm_errtol, userdata->errtol[i]);
      //    norm_errest = fmax(norm_errest, userdata->errest[i]);
      // }
      // err = norm_errest/norm_errtol;
      /*** calculate error (euclidian norm) ***/
      for (i=0, err=0.0; i<data->modelData->nStates; i++)
      {
        err += (userdata->errest[i]*userdata->errest[i])/(userdata->errtol[i]*userdata->errtol[i]);
      }

      err /= data->modelData->nStates;
      err = sqrt(err);

      // Store performed stepSize for adjusting the time and interpolation purposes
      userdata->lastStepSize = userdata->stepSize;
      userdata->stepSize *= fmin(facmax, fmax(facmin, fac*pow(1.0/err, 1./userdata->error_order)));
      /*
       * step size control from Luca, etc.:
       * stepSize = seccoeff*sqrt(norm_errtol/fmax(norm_errest,errmin));
       * printf("Error:  %g, New stepSize: %g from %g to  %g\n", err, userdata->stepSize, userdata->time, userdata->time+stepSize);
       */
      if (err>1)
      {
        userdata->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        userdata->time, userdata->time + userdata->lastStepSize, err, userdata->stepSize);
      }
      userdata->stepsDone += 1;
    } while  (err>1);

    /* update time with performed stepSize */
    userdata->time += userdata->lastStepSize;

    /* store yOld in yt for interpolation purposes, if necessary
     * BB: Check condition
     */
    if (userdata->time > targetTime )
      memcpy(userdata->yt, userdata->yOld, data->modelData->nStates*sizeof(double));

    /* step is accepted and yOld needs to be updated */
    memcpy(userdata->yOld, userdata->y, data->modelData->nStates*sizeof(double));
    infoStreamPrint(LOG_SOLVER, 1, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    userdata->time- userdata->lastStepSize, userdata->time, err, userdata->stepSize);

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      sData->timeValue = userdata->time;
      memcpy(sData->realVars, userdata->y, data->modelData->nStates*sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
    }
    messageClose(LOG_SOLVER);
  }

  if (!solverInfo->integratorSteps)
  {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
    sData->timeValue = solverInfo->currentTime;
    linear_interpolation(userdata->time-userdata->lastStepSize, userdata->yt, userdata->time, userdata->y, sData->timeValue, sData->realVars, data->modelData->nStates);
    // printVector_ESDIRKMR("yOld: ", userdata->yt, data->modelData->nStates, userdata->time-userdata->lastStepSize);
    // printVector_ESDIRKMR("y:    ", userdata->y, data->modelData->nStates, userdata->time);
    // printVector_ESDIRKMR("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
  }else{
    // Integrator emits result on the simulation grid
    solverInfo->currentTime = userdata->time;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }

  if(ACTIVE_STREAM(LOG_SOLVER))
  {
    infoStreamPrint(LOG_SOLVER, 1, "ESDIRKMR call statistics: ");
    infoStreamPrint(LOG_SOLVER, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER, 0, "current integration time value: %0.4g", userdata->time);
    infoStreamPrint(LOG_SOLVER, 0, "step size h to be attempted on next step: %0.4g", userdata->stepSize);
    infoStreamPrint(LOG_SOLVER, 0, "number of steps taken so far: %d", userdata->stepsDone);
    infoStreamPrint(LOG_SOLVER, 0, "number of calls of functionODE() : %d", userdata->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER, 0, "number of calculation of jacobian : %d", userdata->evalJacobians);
    infoStreamPrint(LOG_SOLVER, 0, "error test failure : %d", userdata->errorTestFailures);
    infoStreamPrint(LOG_SOLVER, 0, "convergence failure : %d", userdata->convergenceFailures);
    messageClose(LOG_SOLVER);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = userdata->stepsDone;
  solverInfo->solverStatsTmp[1] = userdata->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = userdata->evalJacobians;
  solverInfo->solverStatsTmp[3] = userdata->errorTestFailures;
  solverInfo->solverStatsTmp[4] = userdata->convergenceFailures;

  infoStreamPrint(LOG_SOLVER, 0, "Finished ESDIRKMR step.");

  return 0;
}

//auxiliary vector functions for better code structure
void linear_interpolation(double ta, double* fa, double tb, double* fb, double t, double* f, int n)
{
  double lambda, h0, h1;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (int i=0; i<n; i++)
  {
    f[i] = h0*fa[i] + h1*fb[i];
  }
}

void printVector_ESDIRKMR(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n", name, time);
  for (int i=0;i<n;i++)
    printf("%6g ", a[i]);
  printf("\n");
}

void printMatrix_ESDIRKMR(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n ", name, time);
  for (int i=0;i<n;i++)
  {
    for (int j=0;j<n;j++)
      printf("%6g ", a[i*n + j]);
    printf("\n");
  }
  printf("\n");
}

