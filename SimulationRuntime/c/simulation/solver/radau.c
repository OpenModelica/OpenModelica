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
  return 0;
}

static int allocateNlpOde(KINODE *kinOde)
{
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  int flag = kinOde->flag;
  DATA* data = kinOde->data;
  SOLVER_INFO* solverInfo = kinOde->solverInfo;
  nlp->nStates = data->modelData.nStates;

  switch(flag)
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
  nlp->c = NULL;
  nlp->a = NULL;
  return 0;
}

static int lobatto4Coeff(KINODE *kinOde)
{
  NLPODE * nlp = (NLPODE*) kinOde->nlp;
  nlp->c = NULL;
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
    nlp->c[i] = (double*) calloc(N+2, sizeof(double));

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
  int N = kinOde->N;
  DATA *data = kinOde->data;
  int n = data->modelData.nStates;
  int nn = 3*N*n; /* 3*N = N*(subintervalls) * 3*var(eq,low,up) */
  int i, j, k;
  double* ceq,*clow,*cup;
  double* seq,*slow,*sup;
  double* sveq,*svlow,*svup;
  KDATAODE * kData = (kinOde)->kData;
  NLPODE *nlp = kinOde->nlp;
  double*s = nlp->s;
  kData->x = N_VNew_Serial(nn);
  kData->sVars = N_VNew_Serial(nn);
  kData->sEqns = N_VNew_Serial(nn);
  kData->c = N_VNew_Serial(nn);
  kData->kmem = KINCreate();
  ceq = NV_DATA_S(kData->c);
  clow = ceq + N*n;
  cup = clow + N*n;
  sveq = NV_DATA_S(kData->sVars);
  svlow = sveq + N*n;
  svup = svlow + N*n;
  seq = NV_DATA_S(kData->sEqns);
  slow = seq + N*n;
  sup = slow + N*n;

  for(j=0, k=0; j<N; j++)
  {
    for(i=0; i<n; i++, k++)
    {
      ceq[k] = 0;
      clow[k] = 1;
      cup[k] = -1;
      sveq[k] = s[i];
      svlow[k] = s[i];
      svup[k] = s[i];
      slow[k] = s[i];
      sup[k] = s[i];
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
  if(nlp->c != NULL)
  {
    for(i=0; i<N; i++)
      free(nlp->c[i]);
    free(nlp->c);
  }
  if(nlp->a != NULL)
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
  int i,j,k;
  int flag = kinOde->flag;
  int N = kinOde->N;
  int nStates = kinOde->nlp->nStates;
  DATA *data= kinOde->data;
  double* xlow,*xup;
  double* seq,*slow,*sup;
  KDATAODE *kData = kinOde->kData;
  NLPODE *nlp = kinOde->nlp;
  double* derx;
  double tmp,h;
  double* xeq = NV_DATA_S(kData->x);

  nlp->currentStep = &kinOde->solverInfo->currentStepSize;
  nlp->derx = data->localData[0]->realVars + nStates;
  nlp->x0 = data->localData[1]->realVars;
  nlp->f0 = data->localData[1]->realVars + nStates;
  nlp->t0 = data->localData[1]->timeValue;
  derx = nlp->derx;

  xlow = xeq + N*nStates;
  xup = xlow + N*nStates;

  seq = NV_DATA_S(kData->sEqns);
  slow = seq + N*nStates;
  sup = slow + N*nStates;
  switch(flag)
  {
    case 6:
      nlp->dt = *(nlp->currentStep);
      KINInit(kData->kmem, radau5Res, kinOde->kData->x);
      break;
    case 7:
      nlp->dt = *(nlp->currentStep);
      KINInit(kData->kmem, radau3Res, kinOde->kData->x);
      break;
    case 8:
      nlp->dt = *(nlp->currentStep);
      KINInit(kData->kmem, radau1Res, kinOde->kData->x);
      break;
    case 9:
      nlp->dt = *(nlp->currentStep);
      KINInit(kData->kmem, lobatto2Res, kinOde->kData->x);
      break;
    case 10:
      nlp->dt = *(nlp->currentStep);
      KINInit(kData->kmem, lobatto4Res, kinOde->kData->x);
      break;
    case 11:
      nlp->dt = *(nlp->currentStep);
      KINInit(kData->kmem, lobatto6Res, kinOde->kData->x);
      break;

    default:
      assert(0);
  }

  h = nlp->dt;

  for(j=0,k=0;j<N;j++)
  {
    for(i=0;i<nStates;i++,k++)
    {
      if(nlp->a != NULL)
        xeq[k] = nlp->x0[i] + nlp->a[j]*nlp->f0[i]*h;
      else
        xeq[k] = nlp->x0[i] + nlp->f0[i]*h;

      xlow[k] = xeq[k] - nlp->min[i];
      xup[k] = xeq[k] - nlp->max[i];
      tmp = 1.0/(fabs(nlp->x0[i] - xeq[k]) + 1e-6);
      seq[k] = tmp;
    }
  }

  kData->mset = 1;

  kData->fnormtol = data->simulationInfo.tolerance;
  kData->scsteptol = data->simulationInfo.tolerance;

  KINSetFuncNormTol(kData->kmem, kData->fnormtol);
  KINSetScaledStepTol(kData->kmem, kData->scsteptol);

  return 0;
}

extern int functionODE(DATA *data);

static int refreshModell(DATA* data, double* x, double time)
{
  int i;
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
  DATA *data = kinOde->data;
  int N = kinOde->N;

  double* feq = NV_DATA_S(f);
  double h = nlp->dt;
  double t0 = nlp->t0;

  double* lb = nlp->min;
  double* ub = nlp->max;

  double *x0,*x1,*x2,*x3;
  int n = nlp->nStates;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double*a = nlp->a;
  double* flow, *fup;


  flow = feq + N*n;
  fup  = flow + N*n;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + n;
  x3 = x2 + n;

  xlow = x1 + N*n;
  xup  = xlow + N*n;

  refreshModell(data, x1,t0 + a[0]*h);
  for(i = 0;i<n;i++)
  {
    feq[i] = (nlp->c[0][0]*x0[i] + nlp->c[0][3]*x3[i] + h*derx[i]) -
             (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);

    flow[i] = xlow[i] - x1[i] + lb[i];
    fup[i] = xup[i] - x1[i] +  ub[i];
  }

  refreshModell(data, x2,t0 + a[1]*h);
  for(i = 0, k=n; i<n; i++, k++)
  {
    feq[k] = (nlp->c[1][1]*x1[i] + h*derx[i]) -
                (nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i] + nlp->c[1][3]*x3[i]);

    flow[k] = xlow[k] - x2[i] + lb[i];
    fup[k] = xup[k] -  x2[i] + ub[i];
  }

  refreshModell(data, x3, t0 + h);
  for(i = 0;i<n;i++,k++)
  {
    feq[k] =  (nlp->c[2][0]*x0[i] + nlp->c[2][2]*x2[i] + h*derx[i]) -
                 (nlp->c[2][1]*x1[i] + nlp->c[2][3]*x3[i]);

    flow[k] = xlow[k] - x3[i] + lb[i];
    fup[k] = xup[k] - x3[i] + ub[i];
  }

  return 0;
}

static int radau3Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k, N;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;

  double* feq = NV_DATA_S(f);
  double h = nlp->dt;
  double t0 = nlp->t0;

  double* lb = nlp->min;
  double* ub = nlp->max;

  double *x0,*x1,*x2;
  int n = nlp->nStates;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double*a = nlp->a;
  double* flow, *fup;

  N = kinOde->N;
  flow = feq + N*n;
  fup  = flow + N*n;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + n;

  xlow = x2 + n;
  xup  = xlow + N*n;
  refreshModell(data, x1,t0 + a[0]*h);
  for(i = 0;i<n;i++)
  {
    feq[i] = (nlp->c[0][0]*x0[i] + h*derx[i]) -
             (nlp->c[0][1]*x1[i] + nlp->c[0][2]*x2[i]);
    flow[i] = xlow[i] - x1[i] + lb[i];
    fup[i] = xup[i] - x1[i] +  ub[i];
  }

  refreshModell(data, x2,t0 + h);
  for(i = 0, k=n;i<n;i++,k++)
  {
    feq[k] = (nlp->c[1][1]*x1[i] + h*derx[i]) -
                (nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i]);
    flow[k] = xlow[k] - x2[i] + lb[i];
    fup[k] = xup[k] -  x2[i] + ub[i];
  }

  return 0;
}


static int radau1Res(N_Vector x, N_Vector f, void* user_data)
{
  int i, N;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;
  double* feq = NV_DATA_S(f);
  double h = nlp->dt;
  double t0 = nlp->t0;

  double* lb = nlp->min;
  double* ub = nlp->max;

  double *x0,*x1;
  int n = nlp->nStates;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double* flow, *fup;

  N = kinOde->N;

  flow = feq + N*n;
  fup  = flow + N*n;

  x0 = nlp->x0;
  x1 = NV_DATA_S(x);

  xlow = x1 + n;
  xup  = xlow + N*n;
  refreshModell(data, x1,t0 + h);
  for(i = 0;i<n;i++)
  {
    feq[i] = x0[i]- x1[i] + h*derx[i];
    flow[i] = xlow[i] - x1[i] + lb[i];
    fup[i] = xup[i] - x1[i] +  ub[i];
  }
  return 0;
}

static int lobatto2Res(N_Vector x, N_Vector f, void* user_data)
{
  int i, N;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;

  double* feq = NV_DATA_S(f);
  double h = nlp->dt;
  double t0 = nlp->t0;

  double* lb = nlp->min;
  double* ub = nlp->max;

  double *x0,*x1, *f0;
  int n = nlp->nStates;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double* flow, *fup;

  N = kinOde->N;

  flow = feq + n;
  fup  = flow + n;

  x0 = nlp->x0;
  f0 = nlp->f0;
  x1 = NV_DATA_S(x);
  xlow = x1 + n;
  xup  = xlow + n;

  refreshModell(data, x1,t0 + h);
  for(i = 0;i<n;i++)
  {
    feq[i] = x0[i] - x1[i] + 0.5*h*(f0[i]+derx[i]);
    flow[i] = xlow[i] - x1[i] + lb[i];
    fup[i] = xup[i] - x1[i] +  ub[i];
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
  double h = nlp->dt;
  double t0 = nlp->t0;

  double* lb = nlp->min;
  double* ub = nlp->max;

  double *x0, *x1, *x2, *f0;
  int n = nlp->nStates;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double*a = nlp->a;
  double* flow, *fup;

  N = kinOde->N;

  flow = feq + N*n;
  fup  = flow + N*n;

  f0 = nlp->f0;
  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + n;
  xlow = x2 + n;
  xup  = xlow + N*n;

  refreshModell(data, x1,t0 + 0.5*h);
  for(i = 0;i<n;i++)
  {
    feq[i] = (h*(2.0*derx[i] +f0[i]) + 5.0*x0[i]) - (4*x1[i] + x2[i]);
    flow[i] = xlow[i] - x1[i] + lb[i];
    fup[i] = xup[i] - x1[i] +  ub[i];
  }

  refreshModell(data, x2,t0 + h);
  for(i = 0,k=n;i<n;i++,k++)
  {
    feq[k] = (2.0*h*derx[i] + 16.0*x1[i]) - (8.0*(x0[i] + x2[i]) +2.0*h*f0[i]);
    flow[k] = xlow[k] - x2[i] + lb[i];
    fup[k] = xup[k] - x2[i] +  ub[i];
  }
  return 0;
}

static int lobatto6Res(N_Vector x, N_Vector f, void* user_data)
{
  int i,k, N;
  KINODE* kinOde = (KINODE*)user_data;
  NLPODE *nlp = kinOde->nlp;
  DATA *data = kinOde->data;

  double* feq = NV_DATA_S(f);
  double h = nlp->dt;
  double t0 = nlp->t0;

  double* lb = nlp->min;
  double* ub = nlp->max;

  double *x0, *x1, *x2, *x3, *f0;
  int n = nlp->nStates;
  double* xlow, *xup;
  double*derx = nlp->derx;
  double*a = nlp->a;
  double* flow, *fup;

  N = kinOde->N;

  flow = feq + N*n;
  fup  = flow + N*n;

  f0 = nlp->f0;
  x0 = nlp->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + n;
  x3 = x2 + n;

  xlow = x3 + n;
  xup  = xlow + N*n;

  refreshModell(data, x1,t0 + nlp->a[0]*h);
  for(i = 0;i<n;i++)
  {
    feq[i] = (h*(derx[i] + nlp->c[0][4]*f0[i]) + nlp->c[0][0]*x0[i] + nlp->c[0][3]*x3[i]) - (nlp->c[0][1]*x1[i] + nlp->c[0][3]*x3[i]);
    flow[i] = xlow[i] - x1[i] + lb[i];
    fup[i] = xup[i] - x1[i] +  ub[i];
  }

  refreshModell(data, x2,t0 + nlp->a[1]*h);
  for(i = 0,k=n;i<n;i++,k++)
  {
    feq[k] = (h*derx[i] + nlp->c[1][1]*x1[i]) - (h*nlp->c[1][4]*f0[i] + nlp->c[1][0]*x0[i] + nlp->c[1][2]*x2[i] + nlp->c[1][3]*x3[i]);
    flow[k] = xlow[k] - x2[i] + lb[i];
    fup[k] = xup[k] - x2[i] +  ub[i];
  }

  refreshModell(data, x3,t0 + h);
  for(i = 0;i<n;i++,k++)
  {
    feq[k] = (h*(f0[i] + derx[i]) +  nlp->c[2][0]*x0[i] + nlp->c[2][2]*x2[i]) - (nlp->c[2][1]*x1[i] + nlp->c[2][3]*x3[i]);
    flow[k] = xlow[k] - x3[i] + lb[i];
    fup[k] = xup[k] - x3[i] +  ub[i];
  }

  return 0;
}

#ifdef __cplusplus  /* wrapper to enable C++ usage */
extern "C" {
#endif
int KINSpbcg(void *kinmem, int maxl);
#ifdef __cplusplus
}
#endif

int kinsolOde(void* ode)
{
  KINODE *kinOde = (KINODE*) ode;
  KDATAODE *kData = kinOde->kData;
  NLPODE *nlp = kinOde->nlp;
  int N = kinOde->N;
  int i;
  kData->glstr = KIN_NONE;
  initKinsol(kinOde);
  do{
    /* Call KINDense to specify the linear solver */
    KINSpbcg(kData->kmem, 3*N*nlp->nStates);
    KINSetMaxSetupCalls(kData->kmem, kData->mset);

    kData->error_code = KINSol( kData->kmem,           /* KINSol memory block */
                                kData->x,              /* initial guess on input; solution vector */
                                kData->glstr,          /* global stragegy choice */
                                kData->sVars,          /* scaling vector, for the variable cc */
                                kData->sEqns );
  }while(kData->error_code < 0 && (++kData->glstr) <= KIN_LINESEARCH);
  refreshModell(kinOde->data, NV_DATA_S(kData->x) + (N-1)*nlp->nStates, nlp->t0 + (nlp->dt));
  return kData->error_code;
}
#else

int kinsolOde(void* ode)
{
  assert(0);
  return -1;
}
#endif
