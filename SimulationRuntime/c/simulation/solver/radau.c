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
 * author: team Bielefeld :)
 */

#include <string.h>

#include "radau.h"
#include "external_input.h"
#ifdef WITH_SUNDIALS

#include <kinsol/kinsol.h>
#include <kinsol/kinsol_dense.h>
#include <kinsol/kinsol_spgmr.h>
#include <kinsol/kinsol_sptfqmr.h>
#include <sundials/sundials_types.h>
#include <sundials/sundials_math.h>

#ifdef __cplusplus  /* wrapper to enable C++ usage */
extern "C" {
#endif
int KINSpbcg(void *kinmem, int maxl);
extern int KINSetErrHandlerFn(void * kmem,  KINErrHandlerFn kinsol_errorHandler, void *);
extern int KINSetInfoHandlerFn(void *kinmem, KINInfoHandlerFn ihfun, void *ih_data);
#ifdef __cplusplus
}
#endif

static int allocateNlpOde(KINODE *kinOde);
static int allocateKINSOLODE(KINODE *kinOde);


static void kinsol_errorHandler(int error_code, const char* module, const char* function, char* msg, void* user_data);

static void kinsol_infoHandler(const char* module, const char* function, char* msg, void* user_data);

static int freeImOde(void *nlpode, int N);
static int freeKinsol(void * kOde);

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

int allocateKinOde(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, int flag, int N)
{
  KINODE *kinOde = (KINODE*) solverInfo->solverData;
  kinOde->kData = (KDATAODE*) malloc(sizeof(KDATAODE));
  kinOde->nlp = (NLPODE*) malloc(sizeof(NLPODE));
  kinOde->N = N;
  kinOde->flag = flag;
  kinOde->data = data;
  kinOde->threadData = threadData;
  allocateNlpOde(kinOde);
  allocateKINSOLODE(kinOde);
  kinOde->solverInfo = solverInfo;
  kinOde->kData->mset = 50;

  kinOde->kData->fnormtol = kinOde->data->simulationInfo->tolerance;
  kinOde->kData->scsteptol = kinOde->data->simulationInfo->tolerance;

  KINSetFuncNormTol(kinOde->kData->kmem, kinOde->kData->fnormtol);
  KINSetScaledStepTol(kinOde->kData->kmem, kinOde->kData->scsteptol);
  KINSetNumMaxIters(kinOde->kData->kmem, 10000);
  if (ACTIVE_STREAM(LOG_SOLVER)) {
    KINSetPrintLevel(kinOde->kData->kmem,2);
  }
  //KINSetEtaForm(kinOde->kData->kmem, KIN_ETACHOICE2);
  KINSetMaxSetupCalls(kinOde->kData->kmem, kinOde->kData->mset);
  kinOde->nlp->currentStep = &kinOde->solverInfo->currentStepSize;
  KINSetErrHandlerFn(kinOde->kData->kmem, kinsol_errorHandler, NULL);
  KINSetInfoHandlerFn(kinOde->kData->kmem, kinsol_infoHandler, NULL);
  switch(kinOde->flag)
  {
    case S_RADAU5:
      KINInit(kinOde->kData->kmem, radau5Res, kinOde->kData->x);
      break;
    case S_RADAU3:
      KINInit(kinOde->kData->kmem, radau3Res, kinOde->kData->x);
      break;
    case S_RADAU1:
      KINInit(kinOde->kData->kmem, radau1Res, kinOde->kData->x);
      break;
    case S_LOBATTO2:
      KINInit(kinOde->kData->kmem, lobatto2Res, kinOde->kData->x);
      break;
    case S_LOBATTO4:
      KINInit(kinOde->kData->kmem, lobatto4Res, kinOde->kData->x);
      break;
    case S_LOBATTO6:
      KINInit(kinOde->kData->kmem, lobatto6Res, kinOde->kData->x);
      break;

    default:
      assert(0);
  }
  /* Call KINDense to specify the linear solver */
 /*KINSpbcg*/
  if(kinOde->nlp->nStates < 10)
    KINSpgmr(kinOde->kData->kmem, N*kinOde->nlp->nStates+1);
  else
    KINSpbcg(kinOde->kData->kmem, N*kinOde->nlp->nStates+1);
  kinOde->kData->glstr = KIN_LINESEARCH;

  return 0;
}

static int allocateNlpOde(KINODE *kinOde)
{
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  nlp->nStates = kinOde->data->modelData->nStates;

  switch(kinOde->flag)
  {
  case S_RADAU5:
    radau5Coeff(kinOde);
    break;
  case S_RADAU3:
    radau3Coeff(kinOde);
    break;
  case S_RADAU1:
    radau1Coeff(kinOde);
    break;
  case S_LOBATTO2:
    radau1Coeff(kinOde); /* TODO: Is this right? */
    break;
  case S_LOBATTO4:
    lobatto4Coeff(kinOde);
    break;
  case S_LOBATTO6:
    lobatto6Coeff(kinOde);
    break;
  default:
    assert(0);
  }

  boundsVars(kinOde);
  return 0;
}

static void kinsol_errorHandler(int error_code, const char* module, const char* function, char* msg, void* user_data)
  {
      warningStreamPrint(LOG_SOLVER, 0, "[module] %s | [function] %s | [error_code] %d", module, function, error_code);
      if (msg) warningStreamPrint(LOG_SOLVER, 0, "%s", msg);
  }

static void kinsol_infoHandler(const char* module, const char* function, char* msg, void* user_data)
  {
    infoStreamPrint(LOG_SOLVER, 0, " %s: %s ", module, function);
    if (msg) infoStreamPrint(LOG_SOLVER, 0, "%s", msg);
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
  const int N = 3;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;

  nlp->c = (long double**) malloc(N * sizeof(long double*));
  for(i = 0; i < N; i++)
    nlp->c[i] = (long double*) calloc(N+1, sizeof(long double));

  nlp->a = (double*) malloc(N * sizeof(double));

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
  const int N = 2;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;

  nlp->c = (long double**) malloc(N * sizeof(long double*));
  for(i = 0; i < N; i++)
    nlp->c[i] = (long double*) calloc(N+1, sizeof(long double));

  nlp->a = (double*) malloc(N * sizeof(double));

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
  const int N = 3;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;


  nlp->c = (long double**) malloc(N * sizeof(long double*));
  for(i = 0; i < N; ++i)
    nlp->c[i] = (long double*) malloc((N+2)* sizeof(long double));

  nlp->a = (double*) malloc(N * sizeof(double));

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

static int allocateKINSOLODE(KINODE *kinOde)
{
  int m;
  DATA *data = kinOde->data;
  int n = data->modelData->nStates;
  int i, j, k;
  double* c;
  KDATAODE * kData = (kinOde)->kData;
  m =  kinOde->N*n;
  kData->x = N_VNew_Serial(m);
  kData->sVars = N_VNew_Serial(m);
  kData->sEqns = N_VNew_Serial(m);
  kData->c = N_VNew_Serial(m);
  kData->kmem = KINCreate();
  c = NV_DATA_S(kData->c);

  for(j=0, k=0; j< kinOde->N; ++j)
    for(i=0; i<n; ++i, ++k)
      c[k] = 0;

  KINSetUserData(kinOde->kData->kmem, (void*) kinOde);
  KINSetConstraints(kinOde->kData->kmem, kData->c);
  return 0;
}

int freeKinOde(DATA* data, SOLVER_INFO* solverInfo, int N)
{
  KINODE *kinOde = (KINODE*) solverInfo->solverData;
  freeImOde((void*) kinOde->nlp ,N);
  freeKinsol((void*) kinOde->kData);
  free(kinOde);
  return 0;
}

static int freeImOde(void *nlpode, int N)
{
  int i;
  NLPODE *nlp = (NLPODE*) nlpode;
  free(nlp->min);
  free(nlp->max);
  free(nlp->s);

  for(i=0; i<N; i++) {
    free(nlp->c[i]);
  }
  free(nlp->c);

  free(nlp->a);
  return 0;
}

static int freeKinsol(void * kOde)
{
  KDATAODE *kData = (KDATAODE*) kOde;
  N_VDestroy_Serial(kData->x);
  N_VDestroy_Serial(kData->sVars);
  N_VDestroy_Serial(kData->sEqns);
  N_VDestroy_Serial(kData->c);
  KINFree(&kData->kmem);
  return 0;
}

static int initKinsol(KINODE *kinOde)
{
  int i,j,k, n;
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
  f2 = data->localData[2]->realVars + n;
  nlp->dt = *(nlp->currentStep);
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
  KINSetMaxNewtonStep(kinOde->kData->kmem, hf_min);
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

int kinsolOde(SOLVER_INFO* solverInfo)
{
  KINODE *kinOde = (KINODE*) solverInfo->solverData;
  KDATAODE *kData = kinOde->kData;
  int i, flag, dense=0;
  long int tmp;
  initKinsol(kinOde);
  for(i = 0; i < 3; ++i)
  {

    kData->error_code = KINSol(kData->kmem,           /* KINSol memory block */
                               kData->x,              /* initial guess on input; solution vector */
                               kData->glstr,          /* global strategy choice */
                               kData->sVars,          /* scaling vector, for the variable cc */
                               kData->sEqns );

    if(kData->error_code>=0)
    {
      break;
    }

    if(i == 0)
    {
     KINDense(kinOde->kData->kmem, kinOde->N*kinOde->nlp->nStates);
     dense=1;
     infoStreamPrint(LOG_SOLVER,0,"Restart Kinsol: change linear solver to KINDense.");
    }
    else if(i == 1)
    {
      KINSptfqmr(kinOde->kData->kmem, kinOde->N*kinOde->nlp->nStates);
      dense=0;
      infoStreamPrint(LOG_SOLVER,0,"Restart Kinsol: change linear solver to KINSptfqmr.");
    }
    else if(i == 2)
    {
      KINSpbcg(kinOde->kData->kmem, kinOde->N*kinOde->nlp->nStates);
      infoStreamPrint(LOG_SOLVER,0,"Restart Kinsol: change linear solver to KINSpbcg.");
    }
  }
  /* save stats */
  /* steps */
  solverInfo->solverStatsTmp[0] += 1;
  /* functionODE evaluations */
  tmp = 0;
  flag = KINGetNumFuncEvals(kData->kmem, &tmp);
  if (flag == KIN_SUCCESS)
  {
    solverInfo->solverStatsTmp[1] += tmp;
  }

  /* Jacobians evaluations */
  tmp = 0;
  flag = KINDlsGetNumJacEvals(kData->kmem, &tmp);
  if (flag == KIN_SUCCESS)
  {
    solverInfo->solverStatsTmp[2] += tmp;
  }

  /* beta-condition failures evaluations */
  tmp = 0;
  flag = KINGetNumBetaCondFails(kData->kmem, &tmp);
  if (flag == KIN_SUCCESS)
  {
    solverInfo->solverStatsTmp[4] += tmp;
  }


  return (kData->error_code<0) ? -1 : 0;
}
#else

int kinsolOde(void* ode)
{
  assert(0);
  return -1;
}
#endif
