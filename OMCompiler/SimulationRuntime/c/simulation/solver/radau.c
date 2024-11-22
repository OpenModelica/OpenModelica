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

/*! \file radau.c
 * author: Ru(n)ge, wbraun
 * description: This file contains implicit Runge-Kutta methods of different order,
 * based on Radau IIA and Lobatto IIA methods. The method with order one is
 * corresponding to the implicit euler method. Further orders 2 to 6.
 */


#include "radau.h"
#include "external_input.h"

#include "simulation/options.h"
#ifdef WITH_SUNDIALS


/* Private function prototypes */
static int allocateNlpOde(KINODE *kinOde, int order);
static KDATAODE* allocateKINSOLODE(KINODE *kinOde, int size);

static void kinsol_errorHandler(int error_code, const char* module, const char* function, char* msg, void* user_data);

static void freeImOde(NLPODE *nlp, int N);
static void freeKinsol(KDATAODE* kData);

static int boundsVars(KINODE *kinOde);

static int radau1Coeff(KINODE *kinOd);
static int radau3Coeff(KINODE *kinOde);
static int radau5Coeff(KINODE *kinOd);
static int lobatto4Coeff(KINODE *kinOd);
static int lobatto6Coeff(KINODE *kinOd);

static int radau1Res(N_Vector z, N_Vector f, void* user_data);
static int radau3Res(N_Vector z, N_Vector f, void* user_data);
static int radau5Res(N_Vector z, N_Vector f, void* user_data);
static int lobatto2Res(N_Vector z, N_Vector f, void* user_data);
static int lobatto4Res(N_Vector z, N_Vector f, void* user_data);
static int lobatto6Res(N_Vector z, N_Vector f, void* user_data);


/**
 * @brief Allocate memory and initialize ODE with KINSOL non-linear solver.
 *
 * Free memory with freeKinOde()
 *
 * @param data
 * @param threadData
 * @param solverInfo
 * @param order
 * @return int
 */
int allocateKinOde(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, int order)    /* TODO: Unify most of this function with init function from kinsolSolver.c */
{
  /* Variables */
  int i;
  int flag;

  KINODE *kinOde;
  KDATAODE* kinsolData;

  /* Set kinODE */
  kinOde = (KINODE*) solverInfo->solverData;
  kinOde->order = order;
  kinOde->N = ceil((double)order/2.0);
  kinOde->data = data;
  kinOde->threadData = threadData;
  kinOde->solverInfo = solverInfo;

  allocateNlpOde(kinOde, order);
  kinOde->kData = allocateKINSOLODE(kinOde, kinOde->N*data->modelData->nStates);
  kinsolData = kinOde->kData;


  kinsolData->mset = 50;
  kinsolData->fnormtol = kinOde->data->simulationInfo->tolerance;
  kinsolData->scsteptol = kinOde->data->simulationInfo->tolerance;

  /* Configure KINSOL */
  flag = KINSetFuncNormTol(kinsolData->kin_mem, kinsolData->fnormtol);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetFuncNormTol");

  flag = KINSetScaledStepTol(kinsolData->kin_mem, kinsolData->scsteptol);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetFuncNormTol");

  flag = KINSetNumMaxIters(kinsolData->kin_mem, 10000);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNumMaxIters");

  if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) {
    flag = KINSetPrintLevel(kinsolData->kin_mem,2);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetPrintLevel");
  }
  /* KINSetEtaForm(kinsolData->kin_mem, KIN_ETACHOICE2); */
  flag = KINSetMaxSetupCalls(kinsolData->kin_mem, kinsolData->mset);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetMaxSetupCalls");

  flag = KINSetErrHandlerFn(kinsolData->kin_mem, kinsolErrorHandlerFunction, NULL);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetErrHandlerFn");

  flag = KINSetInfoHandlerFn(kinsolData->kin_mem, kinsolInfoHandlerFunction, NULL);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetInfoHandlerFn");

  /* Set system function for Kinsol depending on order */
  switch(kinOde->order)
  {
    case 1:
      flag = KINInit(kinsolData->kin_mem, radau1Res, kinsolData->x);
      break;
    case 2:
      flag = KINInit(kinsolData->kin_mem, lobatto2Res, kinsolData->x);
      break;
    case 3:
      flag = KINInit(kinsolData->kin_mem, radau3Res, kinsolData->x);
      break;
    case 4:
      flag = KINInit(kinsolData->kin_mem, lobatto4Res, kinsolData->x);
      break;
    case 5:
      flag = KINInit(kinsolData->kin_mem, radau5Res, kinsolData->x);
      break;
    case 6:
      flag = KINInit(kinsolData->kin_mem, lobatto6Res, kinsolData->x);
      break;

    default:
      assert(0);
  }
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINInit");

  /* if FLAG_IMPRK_LS is set, choose linear solver method */
  if (omc_flag[FLAG_IMPRK_LS])
  {
    /* Set lsMethod to IMPRK_LS_ITERATIVE or IMPRK_LS_DENSE, warn if IMPRK_LS_UNKNOWN */
    for(i=1; i < IMPRK_LS_MAX; i++)
    {
      if (!strcmp((const char*)omc_flagValue[FLAG_IMPRK_LS], IMPRK_LS_METHOD[i])){
        kinOde->lsMethod = (enum IMPRK_LS)i;
        break;
      }
    }
    if (kinOde->lsMethod == IMPRK_LS_UNKNOWN)
    {
      if (OMC_ACTIVE_WARNING_STREAM(OMC_LOG_SOLVER))
      {
        warningStreamPrint(OMC_LOG_SOLVER, 1, "unrecognized linear solver method %s, current options are:", (const char*)omc_flagValue[FLAG_IMPRK_LS]);
        for(i=1; i < IMPRK_LS_MAX; ++i)
        {
          warningStreamPrint(OMC_LOG_SOLVER, 0, "%-15s [%s]", IMPRK_LS_METHOD[i], IMPRK_LS_METHOD_DESC[i]);
        }
        messageClose(OMC_LOG_SOLVER);
      }
      throwStreamPrint(threadData,"unrecognized linear solver method %s", (const char*)omc_flagValue[FLAG_IMPRK_LS]);
    }
  }
  else
  {
    kinOde->lsMethod = IMPRK_LS_ITERATIVE;
  }

  kinsolData->glstr = KIN_LINESEARCH;

  /* Create matrix object and set linear solver method */
  switch (kinOde->lsMethod){
    case IMPRK_LS_ITERATIVE:
      kinsolData->J = NULL;
      if (kinOde->nlp->nStates < 10) {    /* TODO: Is tis still a valid criteria? */
        kinsolData->linSol = SUNLinSol_SPGMR(
            kinsolData->y, PREC_NONE, kinOde->N * kinOde->nlp->nStates + 1);    /* TODO: Default number of Krylov vectors is 5. Seems we are using  some more... */
        if (kinsolData->linSol == NULL) {
          errorStreamPrint(
              OMC_LOG_STDOUT, 0,
              "##KINSOL## In function SUNLinSol_SPGMR: Input incompatible.");
        }
      } else {
        kinsolData->linSol = SUNLinSol_SPBCGS(
            kinsolData->y, PREC_NONE, kinOde->N * kinOde->nlp->nStates + 1);
        if (kinsolData->linSol == NULL) {
          errorStreamPrint(
              OMC_LOG_STDOUT, 0,
              "##KINSOL## In function SUNLinSol_SPBCGS: Input incompatible.");
        }
      }
      break;
    case IMPRK_LS_DENSE:
      /* TODO: Free kinsolData->J!! */
      /* TODO: Why do iterative and dense methods have different sizes? */
      kinsolData->J = SUNDenseMatrix(kinOde->N*kinOde->nlp->nStates, kinOde->N*kinOde->nlp->nStates);
      kinsolData->linSol = SUNLinSol_Dense(kinsolData->y, kinsolData->J);
      if (kinsolData->linSol == NULL) {
        errorStreamPrint(
            OMC_LOG_STDOUT, 0,
            "##KINSOL## In function SUNLinSol_Dense: Input incompatible.");
      }
      break;
    default:
      throwStreamPrint(threadData,"unrecognized linear solver method %s", (const char*)omc_flagValue[FLAG_IMPRK_LS]);
    break;
  }
  flag = KINSetLinearSolver(kinsolData->kin_mem, kinsolData->linSol, kinsolData->J);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetLinearSolver");

  KINSetNoInitSetup(kinsolData->kin_mem, SUNFALSE);

  return 0;
}


/**
 * @brief Allocate memory for nlp.
 *
 * @param kinOde      Solver data for KINSOL
 * @param order       Integration order
 * @return int
 */
static int allocateNlpOde(KINODE *kinOde, int order)
{
  /* Variables */
  NLPODE* nlp;

  nlp = (NLPODE*) malloc(sizeof(NLPODE));
  kinOde->nlp = nlp;
  nlp->nStates = kinOde->data->modelData->nStates;

  /* Initialize kinOde for specific solver */
  switch(order) {
  case 1:
    radau1Coeff(kinOde);
    break;
  case 2:
    radau1Coeff(kinOde); /* TODO: Is this right? */
    break;
  case 3:
    radau3Coeff(kinOde);
    break;
  case 4:
    lobatto4Coeff(kinOde);
    break;
  case 5:
    radau5Coeff(kinOde);
    break;
  case 6:
    lobatto6Coeff(kinOde);
    break;
  default:
    throwStreamPrint(NULL, "Invalid order %u in function allocateNlpOde. Use order 1 to 6.", order);
  }

  boundsVars(kinOde);
  return 0;
}

/**
 * @brief Allocate memory for KDATAODE.
 *
 * Allocates memory, creates N_Vector objects. Sets constrains to 0 and sets user data to KINSOL.
 * Will not allocate memory for linear solver object.
 *
 * @param kinOde          Pointer to solver data for KINSOL
 * @param size            Size for non-linear problem.
 * @return KDATAODE*      Allocated memory block.
 */
static KDATAODE* allocateKINSOLODE(KINODE *kinOde, int size) {
  KDATAODE* kData;
  int flag;

  /* Allocate memory */
  kData = (KDATAODE*) malloc(sizeof(KDATAODE));
  kData->x = N_VNew_Serial(size);
  kData->sVars = N_VNew_Serial(size);
  kData->sEqns = N_VNew_Serial(size);
  kData->c = N_VNew_Serial(size);
  kData->y = N_VNew_Serial(size);

  /* Create KINSOL memory block */
  kData->kin_mem = KINCreate();
  if (kData->kin_mem == NULL) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "##KINSOL## In function KINCreate: An error occured.");
  }

  flag = KINSetUserData(kData->kin_mem, (void*) kinOde);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetPrintLevel");

  /* Set zero constrains */
  N_VConst(0, kData->c);
  flag = KINSetConstraints(kData->kin_mem, kData->c);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetPrintLevel");

  return kData;
}

/**
 * @brief Free KINODE memory.
 *
 * Use for memory allocated with function allocateKinOde().
 * Called from solver_main.c.
 *
 * @param kinOde      Memory block that will be freed.
 */
void freeKinOde(KINODE *kinOde) {
  freeImOde(kinOde->nlp, kinOde->N);
  freeKinsol(kinOde->kData);
  free(kinOde);
}

/**
 * @brief Free NLPODE memory.
 *
 * Frees memory allocated with allocateNlpOde().
 *
 * @param nlp       Memory block for non-linear problem to free.
 * @param N
 */
static void freeImOde(NLPODE *nlp, int N) {
  int i;

  free(nlp->min);
  free(nlp->max);
  free(nlp->s);

  for(i=0; i<N; i++) {
    free(nlp->c[i]);
  }
  free(nlp->c);

  free(nlp->a);
}

/**
 * @brief Free KDATAODE memory.
 *
 * Frees memory allocated with allocateKINSOLODE().
 *
 * @param kData
 */
static void freeKinsol(KDATAODE* kData)
{
  N_VDestroy_Serial(kData->x);
  N_VDestroy_Serial(kData->sVars);
  N_VDestroy_Serial(kData->sEqns);
  N_VDestroy_Serial(kData->c);
  N_VDestroy_Serial(kData->y);

  SUNMatDestroy(kData->J);
  SUNLinSolFree(kData->linSol);

  KINFree(&kData->kin_mem);
}

static int initKinsol(KINODE *kinOde)
{
  int i,j,k,n;
  double *scal_eq, *scal_var, *x, *f2;
  long double tmp, h, hf, hf_min;
  DATA *data;
  NLPODE *nlp;
  KDATAODE * kData;

  n = kinOde->nlp->nStates;
  data= kinOde->data;
  kData = kinOde->kData;
  x = NV_DATA_S(kData->x);
  nlp = kinOde->nlp;

  nlp->currentStep = kinOde->solverInfo->currentStepSize;
  f2 = data->localData[2]->realVars + n;
  nlp->dt = nlp->currentStep;
  nlp->derx = data->localData[0]->realVars + n;
  nlp->x0 = data->localData[1]->realVars;
  nlp->f0 = data->localData[1]->realVars + n;
  nlp->t0 = data->localData[1]->timeValue;


  scal_var = NV_DATA_S(kData->sVars);
  scal_eq = NV_DATA_S(kData->sEqns);

  hf_min = 1e-6;
  for(j=0, k=0; j<kinOde->N; ++j)
  {
    for(i=0;i<n;++i,++k)
    {
      hf = 0.5*nlp->dt*nlp->a[j]*(3*nlp->f0[i]-f2[i]);
      if(fabsl(hf) < hf_min) hf_min = fabsl(hf);
      x[k] = (nlp->x0[i] + hf);
      tmp = fabs(x[k] + nlp->x0[i]) + 1e-12;
      tmp = (tmp < 1e-9) ? nlp->s[i] : 2.0/tmp;
      scal_var[k] = tmp + 1e-9;
      scal_eq[k] = 1.0/(scal_var[k])+ 1e-12;
    }
  }
  KINSetMaxNewtonStep(kinOde->kData->kin_mem, hf_min);
  return 0;
}





/**
 * @brief Solve non-linear system with KinSol.
 *
 * Will try to solve the non-linear system with different linear solvers.
 *  1st try: KINDense dense linear solver
 *  2nd try: KINSptfqmr iterative linear solver
 *  3rd try: KINSpbcg iterative linear solver
 * After that the function will give up and fail, returning -1.
 *
 * @param solverInfo
 * @return int              Return 0 on success and -1 if an error occured.
 */
int kinsolOde(SOLVER_INFO* solverInfo)  /* TODO: Unify this function with nlsKinsolSolve from kinsolSolver.c */
{
  KINODE *kinOde = (KINODE*) solverInfo->solverData;
  KDATAODE *kData = kinOde->kData;
  int flag, kinsol_flag;
  int use_dense = FALSE;
  int try_again = TRUE;
  int solvedSuccessfully = -1 /* FALSE */;
  int retries = 0;
  long int tmp;

  infoStreamPrint(OMC_LOG_SOLVER, 1, "##IMPRK## new step from %.15g to %.15g", solverInfo->currentTime, solverInfo->currentTime + solverInfo->currentStepSize);
  initKinsol(kinOde);

  do {
    kinsol_flag = KINSol(kData->kin_mem,        /* KINSol memory block */
                         kData->x,              /* initial guess on input; solution vector */
                         kData->glstr,          /* global strategy choice */
                         kData->sVars,          /* scaling vector for variable x */
                         kData->sEqns           /* scaling vector for residual eqns */
                         );

    if (kinsol_flag < 0) {
      switch (kinOde->lsMethod) {
      case IMPRK_LS_ITERATIVE:
        if (retries == 0) {
          /* Change from matrix-free to dense linear solver */
          flag = SUNLinSolFree(kData->linSol);
          checkReturnFlag_SUNDIALS(flag, SUNDIALS_SUNLS_FLAG, "SUNLinSolFree");
          SUNMatDestroy(kData->J);

          kData->J = SUNDenseMatrix(kinOde->N*kinOde->nlp->nStates, kinOde->N*kinOde->nlp->nStates);
          kData->linSol = SUNLinSol_Dense(kData->y, kData->J);
          flag = KINSetLinearSolver(kData->kin_mem, kData->linSol, kData->J);
          checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetLinearSolver");
          use_dense = TRUE;
          warningStreamPrint(OMC_LOG_SOLVER, 0, "Restart Kinsol: Change linear solver to SUNLinSol_Dense.");
        } else if (retries == 1) {
          /* Change from dense linear solver to SPTFQMR*/
          flag = SUNLinSolFree(kData->linSol);
          checkReturnFlag_SUNDIALS(flag, SUNDIALS_SUNLS_FLAG, "SUNLinSolFree");

          kData->linSol = SUNLinSol_SPTFQMR(kData->y, PREC_NONE, 5 /* default value */);
          flag = KINSetLinearSolver(kData->kin_mem, kData->linSol, NULL);
          checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetLinearSolver");
          use_dense = FALSE;
          warningStreamPrint(OMC_LOG_SOLVER, 0, "Restart Kinsol: change linear solver to SUNLinSol_SPTFQMR.");
        } else if (retries == 2) {
          /* Change from SPTFQMR solver to SPBCG*/
          flag = SUNLinSolFree(kData->linSol);
          checkReturnFlag_SUNDIALS(flag, SUNDIALS_SUNLS_FLAG, "SUNLinSolFree");

          kData->linSol = SUNLinSol_SPBCGS(kData->y, PREC_NONE, 5 /* default value */);
          flag = KINSetLinearSolver(kData->kin_mem, kData->linSol, NULL);
          checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetLinearSolver");
          use_dense = FALSE;
          warningStreamPrint(OMC_LOG_SOLVER, 0, "Restart Kinsol: change linear solver to SUNLinSol_SPBCGS.");
        } else {
          /* Give up */
          try_again = FALSE;
        }
        break;
      case IMPRK_LS_DENSE:
        use_dense = TRUE;
        if (retries == 1) {
          warningStreamPrint(OMC_LOG_SOLVER, 0, "Restart Kinsol: change KINSOL strategy to basic newton iteration.");
          kinOde->kData->glstr = KIN_NONE;    /* Switch to basic newton iteration */
        } else {
          try_again = FALSE;
        }
        break;
      default:
        throwStreamPrint(NULL,
                         "Unknown solver method %u for linear systems in "
                         "function kinsolOde.",
                         (int)kinOde->lsMethod);
        kinsol_flag = -42;
        try_again = FALSE;
        break;
      }
    } else {
      solvedSuccessfully = 0;
    }
    retries++;
  } while (kinsol_flag < 0 && try_again);

  /* Update statistics */
  /* TODO: Statistics are incomplete: If you retry you need to count that as well */
  solverInfo->solverStatsTmp.nStepsTaken += 1;                 /* Number of steps */

  tmp = 0;
  flag = KINGetNumFuncEvals(kData->kin_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumFuncEvals");
  solverInfo->solverStatsTmp.nCallsODE += tmp;               /* functionODE evaluations */

  tmp = 0;
  flag = KINGetNumJacEvals(kData->kin_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumJacEvals");
  solverInfo->solverStatsTmp.nCallsJacobian += tmp;               /* Jacobians evaluations */

  tmp = 0;
  flag = KINGetNumBetaCondFails(kData->kin_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSpilsGetNumJtimesEvals");
  solverInfo->solverStatsTmp.nErrorTestFailures += tmp;               /* beta-condition failures evaluations */

  if (solvedSuccessfully != 0) {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "##IMPRK## Integration step finished unsuccessful.");
  } else {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "##IMPRK## Integration step finished successful.");
  }
  messageClose(OMC_LOG_SOLVER);

  return solvedSuccessfully;
}


static int boundsVars(KINODE *kinOde)
{
  int i;
  double tmp;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  DATA * data = (DATA*) kinOde->data;

  nlp->min = (double*) malloc(nlp->nStates* sizeof(double));
  nlp->max = (double*) malloc(nlp->nStates* sizeof(double));
  nlp->s = (double*) malloc(nlp->nStates* sizeof(double));

  for(i =0;i<nlp->nStates;i++)
  {
    nlp->min[i] = data->modelData->realVarsData[i].attribute.min;
    nlp->max[i] = data->modelData->realVarsData[i].attribute.max;
    tmp = fabs(data->modelData->realVarsData[i].attribute.nominal);
    tmp = tmp >= 0.0 ? tmp : 1.0;
    nlp->s[i] = 1.0/tmp;
  }
  return 0;
}

static int radau5Coeff(KINODE *kinOde)
{
  int i;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;

  nlp->c = (long double**) malloc(kinOde->N * sizeof(long double*));
  for(i = 0; i < kinOde->N; i++)
    nlp->c[i] = (long double*) calloc(kinOde->N+1, sizeof(long double));

  nlp->a = (double*) malloc(kinOde->N * sizeof(double));

  nlp->c[0][0] = 4.1393876913398137178367408896470696703591369767880;
  nlp->c[0][1] = 3.2247448713915890490986420373529456959829737403284;
  nlp->c[0][2] = 1.1678400846904054949240412722156950122337492313015;
  nlp->c[0][3] = 0.25319726474218082618594241992157103785758599484179;

  nlp->c[1][0] = 1.7393876913398137178367408896470696703591369767880;
  nlp->c[1][1] = 3.5678400846904054949240412722156950122337492313015;
  nlp->c[1][2] = 0.7752551286084109509013579626470543040170262596716;
  nlp->c[1][3] = 1.0531972647421808261859424199215710378575859948418;

  nlp->c[2][0] = 3.0;
  nlp->c[2][1] = 5.5319726474218082618594241992157103785758599484179;
  nlp->c[2][2] = 7.5319726474218082618594241992157103785758599484179;
  nlp->c[2][3] = 5.0;

  nlp->a[0]    = 0.15505102572168219018027159252941086080340525193433;
  nlp->a[1]    = 0.64494897427831780981972840747058913919659474806567;
  nlp->a[2]    = 1.0;
  return 0;
}

static int radau3Coeff(KINODE *kinOde)
{
  int i;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;

  nlp->c = (long double**) malloc(kinOde->N  * sizeof(long double*));
  for(i = 0; i < kinOde->N; i++)
    nlp->c[i] = (long double*) calloc(kinOde->N+1, sizeof(long double));

  nlp->a = (double*) malloc(kinOde->N * sizeof(double));

  nlp->c[0][0] = 2.0;
  nlp->c[0][1] = 1.50;
  nlp->c[0][2] = 0.50;;

  nlp->c[1][0] = 2.0;
  nlp->c[1][1] = 4.50;
  nlp->c[1][2] = 2.50;

  nlp->a[0]    = 1.0/3.0;
  nlp->a[1]    = 1.0;
  return 0;
}

static int radau1Coeff(KINODE *kinOde)
{
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  nlp->c = (long double**) malloc(kinOde->N * sizeof(long double*));
  nlp->c[0] = (long double*) malloc(kinOde->N * sizeof(long double));
  nlp->a = (double*) malloc(kinOde->N * sizeof(double));
  nlp->a[0] = 1.0;
  return 0;
}

static int lobatto4Coeff(KINODE *kinOde)
{
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  nlp->c = (long double**) malloc(kinOde->N * sizeof(long double*));
  nlp->c[0] = (long double*) malloc(kinOde->N * sizeof(long double));
  nlp->c[1] = (long double*) malloc(kinOde->N * sizeof(long double));
  nlp->a = (double*) malloc(kinOde->N * sizeof(double));
  nlp->a[0] = 0.5;
  nlp->a[1] = 1.0;
  return 0;
}

static int lobatto6Coeff(KINODE *kinOde)
{
  int i;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;


  nlp->c = (long double**) malloc(kinOde->N * sizeof(long double*));
  for(i = 0; i < kinOde->N; ++i)
    nlp->c[i] = (long double*) malloc((kinOde->N+2)* sizeof(long double));

  nlp->a = (double*) malloc(kinOde->N * sizeof(double));

  nlp->c[0][0] = 4.3013155617496424838955952368431696002490512113396;
  nlp->c[0][1] = 3.6180339887498948482045868343656381177203091798058;
  nlp->c[0][2] = 0.8541019662496845446137605030969143531609275394172;
  nlp->c[0][3] = 0.17082039324993690892275210061938287063218550788345;
  nlp->c[0][4] = 0.44721359549995793928183473374625524708812367192230;

  nlp->c[1][0] = 3.3013155617496424838955952368431696002490512113396;
  nlp->c[1][1] = 5.8541019662496845446137605030969143531609275394172;
  nlp->c[1][2] = 1.3819660112501051517954131656343618822796908201942;
  nlp->c[1][3] = 1.1708203932499369089227521006193828706321855078834;
  nlp->c[1][4] = 0.44721359549995793928183473374625524708812367192230;

  nlp->c[2][0] = 7.0;
  nlp->c[2][1] = 11.180339887498948482045868343656381177203091798058;
  nlp->c[2][2] = 11.180339887498948482045868343656381177203091798058;
  nlp->c[2][3] = 7.0;
  nlp->c[2][4] = 1.0;

  nlp->a[0]    = 0.27639320225002103035908263312687237645593816403885;
  nlp->a[1]    = 0.72360679774997896964091736687312762354406183596115;
  nlp->a[2]    = 1.0;
  return 0;
}

static int refreshModell(DATA* data, threadData_t *threadData, double* x, double time)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  memcpy(sData->realVars, x, sizeof(double)*data->modelData->nStates);
  sData->timeValue = time;
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

static int radau5Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  threadData_t *threadData = kinOde->threadData;

  double *x0,*x1,*x2,*x3;
  double*derx = nlp->derx;
  double*a = nlp->a;
  double* feq = NV_DATA_S(f);

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;
  x3 = x2 + nlp->nStates;

  refreshModell(kinOde->data, threadData, x1, nlp->t0 + a[0]*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->c[0][0]*x0[i] + nlp->c[0][3]*x3[i] + nlp->dt*derx[i]) -
             (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);
    if(isnan(feq[i])) return -1;
  }

  refreshModell(kinOde->data, threadData, x2, nlp->t0 + a[1]*nlp->dt);
  for(i = 0, k=nlp->nStates; i<nlp->nStates; i++, k++)
  {
    feq[k] = (nlp->c[1][1]*x1[i] + nlp->dt*derx[i]) -
                (nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i] + nlp->c[1][3]*x3[i]);
   if(isnan(feq[k])) return -1;
  }

  refreshModell(kinOde->data, threadData, x3, nlp->t0 + nlp->dt);
  for(i = 0;i<nlp->nStates;i++,k++)
  {
    feq[k] =  (nlp->c[2][0]*x0[i] + nlp->c[2][2]*x2[i] + nlp->dt*derx[i]) -
                 (nlp->c[2][1]*x1[i] + nlp->c[2][3]*x3[i]);
    if(isnan(feq[k])) return -1;
  }

  return 0;
}

static int radau3Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;
  threadData_t *threadData = kinOde->threadData;

  double* feq = NV_DATA_S(f);

  double *x0,*x1,*x2;

  double*derx = nlp->derx;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;

  refreshModell(data, threadData, x1, nlp->t0 + 0.5*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->c[0][0]*x0[i] + nlp->dt*derx[i]) -
             (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);
    if(isnan(feq[i])) return -1;
  }

  refreshModell(data, threadData, x2, nlp->t0 + nlp->dt);
  for(i = 0, k=nlp->nStates;i<nlp->nStates;i++,k++)
  {
    feq[k] = (nlp->c[1][1]*x1[i] + nlp->dt*derx[i]) -
                (nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i]);
    if(isnan(feq[k])) return -1;
  }

  return 0;
}


static int radau1Res(N_Vector x, N_Vector f, void* user_data)
{
  int i;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  threadData_t *threadData = kinOde->threadData;
  double* feq = NV_DATA_S(f);

  double *x0,*x1;
  double*derx = nlp->derx;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);

  refreshModell(kinOde->data, threadData, x1, nlp->t0 + nlp->dt);
  for(i = 0; i<nlp->nStates; ++i)
  {
    feq[i] = x0[i] - x1[i] + nlp->dt*derx[i];
    if(isnan(feq[i])) return -1;
  }
  return 0;
}

static int lobatto2Res(N_Vector x, N_Vector f, void* user_data)
{
  int i;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;
  threadData_t *threadData = kinOde->threadData;

  double *feq = NV_DATA_S(f);
  double *x0,*x1, *f0;
  double *derx = nlp->derx;

  x0 = nlp->x0;
  f0 = nlp->f0;
  x1 = NV_DATA_S(x);

  refreshModell(data, threadData, x1, nlp->t0 + nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = x0[i] - x1[i] + 0.5*nlp->dt*(f0[i]+derx[i]);
    if(isnan(feq[i])) return -1;
  }
  return 0;
}

static int lobatto4Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;
  threadData_t *threadData = kinOde->threadData;

  double* feq = NV_DATA_S(f);

  double *x0, *x1, *x2, *f0;
  double*derx = nlp->derx;

  f0 = nlp->f0;
  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;

  refreshModell(data, threadData, x1,nlp->t0 + 0.5*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->dt*(2.0*derx[i] +f0[i]) + 5.0*x0[i]) - (4*x1[i] + x2[i]);
    if(isnan(feq[i])) return -1;
  }

  refreshModell(data, threadData, x2,nlp->t0 + nlp->dt);
  for(i = 0,k=nlp->nStates;i<nlp->nStates;i++,k++)
  {
    feq[k] = (2.0*nlp->dt*derx[i] + 16.0*x1[i]) - (8.0*(x0[i] + x2[i]) +2.0*nlp->dt*f0[i]);
    if(isnan(feq[k])) return -1;
  }
  return 0;
}

static int lobatto6Res(N_Vector x, N_Vector f, void* user_data)
{
  int i, k;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;
  threadData_t *threadData = kinOde->threadData;

  double* feq = NV_DATA_S(f);
  double *x0, *x1, *x2, *x3, *f0;
  double*derx = nlp->derx;

  f0 = nlp->f0;
  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;
  x3 = x2 + nlp->nStates;

  refreshModell(data, threadData, x1, nlp->t0 + nlp->a[0]*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->dt*(derx[i] + nlp->c[0][4]*f0[i]) + nlp->c[0][0]*x0[i] + nlp->c[0][3]*x3[i]) - (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);
   if(isnan(feq[i])) return -1;
  }

  refreshModell(data, threadData, x2,nlp->t0 + nlp->a[1]*nlp->dt);
  for(i = 0,k=nlp->nStates;i<nlp->nStates;i++,k++)
  {
    feq[k] = (nlp->dt*derx[i] + nlp->c[1][1]*x1[i]) - (nlp->dt*nlp->c[1][4]*f0[i] + nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i] + nlp->c[1][3]*x3[i]);
   if(isnan(feq[k])) return -1;
  }

  refreshModell(data, threadData, x3,nlp->t0 + nlp->dt);
  for(i = 0;i<nlp->nStates;i++,k++)
  {
    feq[k] = (nlp->dt*(f0[i] + derx[i]) +  nlp->c[2][0]*x0[i] + nlp->c[2][2]*x2[i]) - (nlp->c[2][1]*x1[i] + nlp->c[2][3]*x3[i]);
    if(isnan(feq[k])) return -1;
  }

  return 0;
}
#else

int kinsolOde(SOLVER_INFO* solverInfo)
{
  assert(0);
  return -1;
}
#endif
