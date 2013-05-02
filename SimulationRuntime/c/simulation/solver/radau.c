/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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
 * from Linköpings University, either from the above address,
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

/*! \file radau.c
 * author: team Bielefeld :)
 */

#include <string.h>

#include "radau.h"
#ifdef WITH_SUNDIALS

extern int functionODE(DATA *data);

#ifdef __cplusplus  /* wrapper to enable C++ usage */
extern "C" {
#endif
int KINSpbcg(void *kinmem, int maxl);
#ifdef __cplusplus
}
#endif

static int allocateNlpOde(KINODE *kinOde);
static int allocateKINSOLODE(KINODE *kinOde);

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

int allocateKinOde(DATA* data, SOLVER_INFO* solverInfo, int flag, int N)
{
  KINODE *kinOde = (KINODE*) solverInfo->solverData;
  kinOde->kData = (KDATAODE*) malloc(sizeof(KDATAODE));
  kinOde->nlp = (NLPODE*) malloc(sizeof(NLPODE));
  kinOde->N = N;
  kinOde->flag = flag;
  kinOde->data = data;
  allocateNlpOde(kinOde);
  allocateKINSOLODE(kinOde);
  kinOde->solverInfo = solverInfo;
  kinOde->kData->mset = 10;

  kinOde->kData->fnormtol = kinOde->data->simulationInfo.tolerance;
  kinOde->kData->scsteptol = kinOde->data->simulationInfo.tolerance;

  KINSetFuncNormTol(kinOde->kData->kmem, kinOde->kData->fnormtol);
  KINSetScaledStepTol(kinOde->kData->kmem, kinOde->kData->scsteptol);
  KINSetNumMaxIters(kinOde->kData->kmem, 10000);
  KINSetMaxSetupCalls(kinOde->kData->kmem, kinOde->kData->mset);
  kinOde->nlp->currentStep = &kinOde->solverInfo->currentStepSize;

  switch(kinOde->flag)
  {
    case 6:
      KINInit(kinOde->kData->kmem, radau5Res, kinOde->kData->x);
      break;
    case 7:
      KINInit(kinOde->kData->kmem, radau3Res, kinOde->kData->x);
      break;
    case 8:
      KINInit(kinOde->kData->kmem, radau1Res, kinOde->kData->x);
      break;
    case 9:
      KINInit(kinOde->kData->kmem, lobatto2Res, kinOde->kData->x);
      break;
    case 10:
      KINInit(kinOde->kData->kmem, lobatto4Res, kinOde->kData->x);
      break;
    case 11:
      KINInit(kinOde->kData->kmem, lobatto6Res, kinOde->kData->x);
      break;

    default:
      assert(0);
  }
  /* Call KINDense to specify the linear solver */
  KINSpbcg(kinOde->kData->kmem, 3*N*kinOde->nlp->nStates);
  kinOde->kData->glstr = KIN_LINESEARCH;

  return 0;
}

static int allocateNlpOde(KINODE *kinOde)
{
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  SOLVER_INFO* solverInfo = kinOde->solverInfo;
  nlp->nStates = kinOde->data->modelData.nStates;

  switch(kinOde->flag)
  {
  case 6:
    radau5Coeff(kinOde);
    break;
  case 7:
    radau3Coeff(kinOde);
    break;
  case 8:
    radau1Coeff(kinOde);
    break;
  case 9:
    radau1Coeff(kinOde);
    break;
  case 10:
    lobatto4Coeff(kinOde);
    break;
  case 11:
    lobatto6Coeff(kinOde);
    break;
  default:
    assert(0);
  }

  boundsVars(kinOde);
  return 0;
}

static int boundsVars(KINODE *kinOde)
{
  int i;
  double tmp;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  DATA * data = (DATA*) kinOde->data;

  nlp->min = (double*) calloc(nlp->nStates, sizeof(double));
  nlp->max = (double*) calloc(nlp->nStates, sizeof(double));
  nlp->s = (double*) calloc(nlp->nStates, sizeof(double));

  for(i =0;i<nlp->nStates;i++)
  {
    nlp->min[i] = data->modelData.realVarsData[i].attribute.min;
    nlp->max[i] = data->modelData.realVarsData[i].attribute.max;
    tmp = fabs(data->modelData.realVarsData[i].attribute.nominal);
    tmp = tmp >= 0.0 ? tmp : 1.0;
    nlp->s[i] = 1.0/tmp;
  }
  return 0;
}

static int radau5Coeff(KINODE *kinOde)
{
  int i, N;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  N = kinOde->N;

  nlp->c = (double**) malloc(N * sizeof(double*));
  for(i = 0; i < N; i++)
    nlp->c[i] = (double*) calloc(N+1, sizeof(double));

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
  int i, N;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  N = kinOde->N;

  nlp->c = (double**) malloc(N * sizeof(double*));
  for(i = 0; i < N; i++)
    nlp->c[i] = (double*) calloc(N+1, sizeof(double));

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
  nlp->c = (double**) malloc(kinOde->N * sizeof(double*));
  nlp->c[0] = (double*) malloc(kinOde->N * sizeof(double));
  nlp->a = (double*) malloc(kinOde->N * sizeof(double));
  nlp->a[0] = 1.0;
  return 0;
}

static int lobatto4Coeff(KINODE *kinOde)
{
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  nlp->c = (double**) malloc(kinOde->N * sizeof(double*));
  nlp->c[0] = (double*) malloc(kinOde->N * sizeof(double));
  nlp->c[1] = (double*) malloc(kinOde->N * sizeof(double));
  nlp->a = (double*) malloc(kinOde->N * sizeof(double));
  nlp->a[0] = 0.5;
  nlp->a[1] = 1.0;
  return 0;
}

static int lobatto6Coeff(KINODE *kinOde)
{
  int i, N;
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  N = kinOde->N;

  nlp->c = (double**) malloc(N * sizeof(double*));
  for(i = 0; i < N; i++)
    nlp->c[i] = (double*) malloc((N+2)* sizeof(double));

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
  int n = data->modelData.nStates;
  int nn; /* 3*N*n = N*(subintervalls) * 3*var(eq,low,up)*nStates */
  int i, j, k;
  double* ceq,*clow,*cup;
  KDATAODE * kData = (kinOde)->kData;
  m =  kinOde->N*n;
  nn = 3*m;  
  kData->x = N_VNew_Serial(nn);
  kData->sVars = N_VNew_Serial(nn);
  kData->sEqns = N_VNew_Serial(nn);
  kData->c = N_VNew_Serial(nn);
  kData->kmem = KINCreate();
  ceq = NV_DATA_S(kData->c);

  clow = ceq + m;
  cup = clow + m;

  for(j=0, k=0; j< kinOde->N; ++j)
  {
    for(i=0; i<n; ++i, ++k)
    {
      ceq[k] = 0;
      clow[k] = 1;
      cup[k] = -1;
    }
  }
  KINSetUserData(kinOde->kData->kmem, (void*) kinOde);
  KINSetConstraints(kinOde->kData->kmem, kData->c);
  return 0;
}

int freeKinOde(DATA* data, SOLVER_INFO* solverInfo, int flag, int N)
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

  for(i=0; i<N; i++)
    free(nlp->c[i]);
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
  int i,j,k, N;
  double* seq,*slow,*sup;
  double* sveq,*svlow,*svup;
  double* xlow,*xup;
  double tmp,h,hf;
  int nStates = kinOde->nlp->nStates;
  DATA *data= kinOde->data;
  KDATAODE *kData = kinOde->kData;
  double* xeq = NV_DATA_S(kData->x);
  NLPODE *nlp = kinOde->nlp;
  double *f2 = data->localData[2]->realVars + nStates;
  nlp->dt = *(nlp->currentStep);
  nlp->derx = data->localData[0]->realVars + nStates;
  nlp->x0 = data->localData[1]->realVars;
  nlp->f0 = data->localData[1]->realVars + nStates;
  nlp->t0 = data->localData[1]->timeValue;

  N = kinOde->N*nStates;
  xlow = xeq + N;
  xup  = xlow + N;

  sveq = NV_DATA_S(kData->sVars);
  svlow = sveq + N;
  svup = svlow + N;

  seq = NV_DATA_S(kData->sEqns);
  slow = seq + N;
  sup = slow + N;

  for(j=0,k=0;j<kinOde->N;j++)
  {
    tmp = 0.5*nlp->a[j]*nlp->dt;
    for(i=0;i<nStates;i++,k++)
    {
      hf = tmp*(nlp->f0[i] + f2[i]);
      xeq[k] = nlp->x0[i] + hf;
      seq[k] = 1e-12 + 1.0/(fabs(hf) + 1e-6);
      xlow[k] = xeq[k] - nlp->min[i];
      xup[k] = xeq[k] - nlp->max[i];

      sveq[k] = 1.0/(fabs(xeq[k])+1e-6) + 1e-6;
      svlow[k] = sveq[k];
      svup[k] = sveq[k];
      slow[k] = seq[k];
      sup[k] = seq[k];

    }
  }
  return 0;
}

static int refreshModell(DATA* data, double* x, double time)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  memcpy(sData->realVars, x, sizeof(double)*data->modelData.nStates);
  sData->timeValue = time;
  functionODE(data);

  return 0;
}

static int radau5Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  int N = kinOde->N*nlp->nStates;

  double *x0,*x1,*x2,*x3;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double*a = nlp->a;
  double* flow, *fup;
  double* feq = NV_DATA_S(f);
  flow = feq + N;
  fup  = flow + N;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;
  x3 = x2 + nlp->nStates;

  xlow = x1 + N;
  xup  = xlow + N;

  refreshModell(kinOde->data, x1,nlp->t0 + a[0]*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->c[0][0]*x0[i] + nlp->c[0][3]*x3[i] + nlp->dt*derx[i]) -
       (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);

    flow[i] = xlow[i] - x1[i] + nlp->min[i];
    fup[i] = xup[i] - x1[i] +  nlp->max[i];
  }

  refreshModell(kinOde->data, x2,nlp->t0 + a[1]*nlp->dt);
  for(i = 0, k=nlp->nStates; i<nlp->nStates; i++, k++)
  {
    feq[k] = (nlp->c[1][1]*x1[i] + nlp->dt*derx[i]) -
          (nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i] + nlp->c[1][3]*x3[i]);

    flow[k] = xlow[k] - x2[i] + nlp->min[i];
    fup[k] = xup[k] -  x2[i] + nlp->max[i];
  }

  refreshModell(kinOde->data, x3, nlp->t0 + nlp->dt);
  for(i = 0;i<nlp->nStates;i++,k++)
  {
    feq[k] =  (nlp->c[2][0]*x0[i] + nlp->c[2][2]*x2[i] + nlp->dt*derx[i]) -
           (nlp->c[2][1]*x1[i] + nlp->c[2][3]*x3[i]);

    flow[k] = xlow[k] - x3[i] + nlp->min[i];
    fup[k] = xup[k] - x3[i] + nlp->max[i];
  }

  return 0;
}

static int radau3Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k,N;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;

  double* feq = NV_DATA_S(f);

  double *x0,*x1,*x2;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double* flow, *fup;

  N = kinOde->N*nlp->nStates;
  flow = feq + N;
  fup  = flow + N;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;

  xlow = x2 + nlp->nStates;
  xup  = xlow + N;
  refreshModell(data, x1,nlp->t0 + 0.5*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->c[0][0]*x0[i] + nlp->dt*derx[i]) -
       (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);
    flow[i] = xlow[i] - x1[i] + nlp->min[i];
    fup[i] = xup[i] - x1[i] +  nlp->max[i];
  }

  refreshModell(data, x2,nlp->t0 + nlp->dt);
  for(i = 0, k=nlp->nStates;i<nlp->nStates;i++,k++)
  {
    feq[k] = (nlp->c[1][1]*x1[i] + nlp->dt*derx[i]) -
          (nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i]);
    flow[k] = xlow[k] - x2[i] + nlp->min[i];
    fup[k] = xup[k] -  x2[i] + nlp->max[i];
  }

  return 0;
}


static int radau1Res(N_Vector x, N_Vector f, void* user_data)
{
  int i;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  double* feq = NV_DATA_S(f);

  double *x0,*x1;

  double* xlow, *xup;
  double*derx = nlp->derx;
  double* flow, *fup;

  flow = feq + nlp->nStates;
  fup  = flow + nlp->nStates;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);

  xlow = x1 + nlp->nStates;
  xup  = xlow + nlp->nStates;
  refreshModell(kinOde->data, x1, nlp->t0 + nlp->dt);
  for(i = 0; i<nlp->nStates; ++i)
  {
    feq[i] = x0[i] - x1[i] + nlp->dt*derx[i];
    flow[i] = xlow[i] - x1[i] + nlp->min[i];
    fup[i] = xup[i] - x1[i] +  nlp->max[i];
  }
  return 0;
}

static int lobatto2Res(N_Vector x, N_Vector f, void* user_data)
{
  int i;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;

  double* feq = NV_DATA_S(f);
  double *x0,*x1, *f0;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double* flow, *fup;

  flow = feq + nlp->nStates;
  fup  = flow + nlp->nStates;

  x0 = nlp->x0;
  f0 = nlp->f0;
  x1 = NV_DATA_S(x);
  xlow = x1 + nlp->nStates;
  xup  = xlow + nlp->nStates;

  refreshModell(data, x1,nlp->t0 + nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = x0[i] - x1[i] + 0.5*nlp->dt*(f0[i]+derx[i]);
    flow[i] = xlow[i] - x1[i] + nlp->min[i];
    fup[i] = xup[i] - x1[i] +  nlp->max[i];
  }
  return 0;
}

static int lobatto4Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k, N;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;

  double* feq = NV_DATA_S(f);

  double *x0, *x1, *x2, *f0;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double* flow, *fup;

  N = kinOde->N*nlp->nStates;

  flow = feq + N;
  fup  = flow + N;

  f0 = nlp->f0;
  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;
  xlow = x2 + nlp->nStates;
  xup  = xlow + N;

  refreshModell(data, x1,nlp->t0 + 0.5*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->dt*(2.0*derx[i] +f0[i]) + 5.0*x0[i]) - (4*x1[i] + x2[i]);
    flow[i] = xlow[i] - x1[i] + nlp->min[i];
    fup[i] = xup[i] - x1[i] +  nlp->max[i];
  }

  refreshModell(data, x2,nlp->t0 + nlp->dt);
  for(i = 0,k=nlp->nStates;i<nlp->nStates;i++,k++)
  {
    feq[k] = (2.0*nlp->dt*derx[i] + 16.0*x1[i]) - (8.0*(x0[i] + x2[i]) +2.0*nlp->dt*f0[i]);
    flow[k] = xlow[k] - x2[i] + nlp->min[i];
    fup[k] = xup[k] - x2[i] +  nlp->max[i];
  }
  return 0;
}

static int lobatto6Res(N_Vector x, N_Vector f, void* user_data)
{
  int i, k, N;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;

  double* feq = NV_DATA_S(f);

  double *x0, *x1, *x2, *x3, *f0;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double* flow, *fup;

  N = kinOde->N*nlp->nStates;

  flow = feq + N;
  fup  = flow + N;

  f0 = nlp->f0;
  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + nlp->nStates;
  x3 = x2 + nlp->nStates;

  xlow = x3 + nlp->nStates;
  xup  = xlow + N;

  refreshModell(data, x1,nlp->t0 + nlp->a[0]*nlp->dt);
  for(i = 0;i<nlp->nStates;i++)
  {
    feq[i] = (nlp->dt*(derx[i] + nlp->c[0][4]*f0[i]) + nlp->c[0][0]*x0[i] + nlp->c[0][3]*x3[i]) - (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);
    flow[i] = xlow[i] - x1[i] + nlp->min[i];
    fup[i] = xup[i] - x1[i] +  nlp->max[i];
  }

  refreshModell(data, x2,nlp->t0 + nlp->a[1]*nlp->dt);
  for(i = 0,k=nlp->nStates;i<nlp->nStates;i++,k++)
  {
    feq[k] = (nlp->dt*derx[i] + nlp->c[1][1]*x1[i]) - (nlp->dt*nlp->c[1][4]*f0[i] + nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i] + nlp->c[1][3]*x3[i]);
    flow[k] = xlow[k] - x2[i] + nlp->min[i];
    fup[k] = xup[k] - x2[i] +  nlp->max[i];
  }

  refreshModell(data, x3,nlp->t0 + nlp->dt);
  for(i = 0;i<nlp->nStates;i++,k++)
  {
    feq[k] = (nlp->dt*(f0[i] + derx[i]) +  nlp->c[2][0]*x0[i] + nlp->c[2][2]*x2[i]) - (nlp->c[2][1]*x1[i] + nlp->c[2][3]*x3[i]);
    flow[k] = xlow[k] - x3[i] + nlp->min[i];
    fup[k] = xup[k] - x3[i] +  nlp->max[i];
  }

  return 0;
}

int kinsolOde(void* ode)
{
  KINODE *kinOde = (KINODE*) ode;
  KDATAODE *kData = kinOde->kData;
  initKinsol(kinOde);
  kData->error_code = KINSol( kData->kmem,     /* KINSol memory block */
                          kData->x,              /* initial guess on input; solution vector */
                          kData->glstr,          /* global stragegy choice */
                          kData->sVars,          /* scaling vector, for the variable cc */
                          kData->sEqns );

  return kData->error_code;
}
#else

int kinsolOde(void* ode)
{
  assert(0);
  return -1;
}
#endif
