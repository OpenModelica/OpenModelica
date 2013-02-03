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

#include "radau.h"
#ifdef WITH_SUNDIALS

int radauIIAResidual(N_Vector z, N_Vector f, void* user_data);

int CoeffRadauIIA(RADAUIIA* rData)
{
  rData->C[0][0] = 4.1393876913398137178367408896470696703591369767880;
  rData->C[0][1] = 3.2247448713915890490986420373529456959829737403284;
  rData->C[0][2] = 1.1678400846904054949240412722156950122337492313015;
  rData->C[0][3] = 0.25319726474218082618594241992157103785758599484179;

  rData->C[1][0] = 1.7393876913398137178367408896470696703591369767880;
  rData->C[1][1] = 3.5678400846904054949240412722156950122337492313015;
  rData->C[1][2] = 0.7752551286084109509013579626470543040170262596716;
  rData->C[1][3] = 1.0531972647421808261859424199215710378575859948418;

  rData->C[2][0] = 3.0;
  rData->C[2][1] = 5.5319726474218082618594241992157103785758599484179;
  rData->C[2][2] = 7.5319726474218082618594241992157103785758599484179;
  rData->C[2][3] = 5.0;

  rData->a[0]    = 0.15505102572168219018027159252941086080340525193433;
  rData->a[1]    = 0.64494897427831780981972840747058913919659474806567;
  rData->a[2]    = 1.0;

  return 0;
}

int boundScalRadauIIA(RADAUIIA* rData)
{
  int i;
  DATA* data = rData->data;
  rData->min = (double*) calloc(rData->nState, sizeof(double));
  rData->max = (double*) calloc(rData->nState, sizeof(double));
  rData->s = (double*) calloc(rData->nState, sizeof(double));

  for(i =0;i<rData->nState;i++)
  {
    rData->min[i] = data->modelData.realVarsData[i].attribute.min;
    rData->max[i] = data->modelData.realVarsData[i].attribute.max;
    rData->s[i] = 1.0/data->modelData.realVarsData[i].attribute.nominal;
  }
  return 0;
}

int allocateRadauIIA(RADAUIIA* rData, DATA* data, SOLVER_INFO* solverInfo)
{
  rData->data = data;
  rData->nState = data->modelData.nStates;
  rData->dt = &(solverInfo->currentStepSize);
  CoeffRadauIIA(rData);
  boundScalRadauIIA(rData);
  return 0;
}

int freeRadauIIA(RADAUIIA* rData)
{
  free(rData->min);
  free(rData->max);
  free(rData->s);
}


int freeKinsol(KINSOLRADAU* kData)
{

  N_VDestroy_Serial(kData->x);
  N_VDestroy_Serial(kData->sVars);
  N_VDestroy_Serial(kData->sEqns);
  N_VDestroy_Serial(kData->c);
  KINFree(&kData->kmem);
}

int allocateKinsol(KINSOLRADAU* kData, void* userData)
{
  RADAUIIA* rData = (RADAUIIA*)userData;
  int n = rData->nState;
  int nn = 9*n; /* 9 = 3(subintervalls) * 3*var(eq,low,up) */
  int i,sub2,sub3;
  double* ceq,*clow,*cup;
  double* seq,*slow,*sup;
  double* sveq,*svlow,*svup;
  double*s = rData->s;


  kData->x = N_VNew_Serial(nn);
  kData->sVars = N_VNew_Serial(nn);
  kData->sEqns = N_VNew_Serial(nn);
  kData->c = N_VNew_Serial(nn);
  kData->kmem = KINCreate();

  ceq = NV_DATA_S(kData->c);
  clow = ceq + 3*n;
  cup = ceq + 6*n;

  seq = NV_DATA_S(kData->sEqns);
  slow = seq + 3*n;
  sup = seq + 6*n;

  sveq = NV_DATA_S(kData->sVars);
  svlow = sveq + 3*n;
  svup = sveq + 6*n;

  for(i = 0; i<n; i++)
  {
    sub2 = n + i;
    sub3 = 2*n + i;

    ceq[i] = 0; /*subintervall 1*/
    ceq[sub2] = 0; /*subintervall 2*/
    ceq[sub3] = 0; /*subintervall 3*/

    clow[i] = 1;
    clow[sub2] = 1;
    clow[sub3] = 1;

    cup[i] = -1;
    cup[sub2] = -1;
    cup[sub3] = -1;


    seq[i] = s[i]; /*subintervall 1*/
    seq[sub2] = s[i]; /*subintervall 2*/
    seq[sub3] = s[i]; /*subintervall 3*/

    slow[i] = s[i];
    slow[sub2] = s[i];
    slow[sub3] = s[i];

    sup[i] = s[i];
    sup[sub2] = s[i];
    sup[sub3] = s[i];

    sveq[i] = s[i]; /*subintervall 1*/
    sveq[sub2] = s[i]; /*subintervall 2*/
    sveq[sub3] = s[i]; /*subintervall 3*/

    svlow[i] = s[i];
    svlow[sub2] = s[i];
    svlow[sub3] = s[i];

    svup[i] = s[i];
    svup[sub2] = s[i];
    svup[sub3] = s[i];
  }

  KINSetUserData(kData->kmem, rData);
  KINSetConstraints(kData->kmem, kData->c);

  rData->kData = kData;
  return 0;
}

int initKinsol(RADAUIIA* rData, KINSOLRADAU* kData)
{
  int i,sub2,sub3;
  double* clow,*cup;

  double* x1 = NV_DATA_S(kData->x);
  double* x2 = x1 + rData->nState;
  double* x3 = x2 + rData->nState;

  DATA* data = rData->data;

  rData->derx = data->localData[0]->realVars + rData->nState;
  rData->x0 = data->localData[1]->realVars;
  rData->t0 = &(data->localData[1]->timeValue);

  clow = x3 + rData->nState;
  cup = clow + 3*rData->nState;

  for(i=0;i<rData->nState;i++)
  {
    sub2 = i + rData->nState;
    sub3 = i + 2*rData->nState;

    /* state */
    x1[i] = rData->x0[i];
    x2[i] = rData->x0[i];
    x3[i] = rData->x0[i];

    /* constrains low */
    clow[i] = x1[i] - rData->min[i];
    clow[sub2] = x2[i] - rData->min[i];
    clow[sub3] = x3[i] - rData->min[i];

    /* constrains up */
    cup[i] = x1[i] - rData->max[i];
    cup[sub2] = x2[i] - rData->max[i];
    cup[sub3] = x3[i] - rData->max[i];
  }

  KINInit(kData->kmem, radauIIAResidual, kData->x);
  kData->mset = 1;
  kData->glstr = KIN_NONE;

  kData->fnormtol = *(rData->dt);
  kData->scsteptol = *(rData->dt);

  KINSetFuncNormTol(kData->kmem, kData->fnormtol);
  KINSetScaledStepTol(kData->kmem, kData->scsteptol);

  return 0;
}

int refreshModell(DATA* data, double*x, double time)
{
  int i;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  for(i=0;i<data->modelData.nStates;i++)
    sData->realVars[i] = x[i];
  sData->timeValue = time;
  functionODE(data);
  return 0;
}


int radauIIAResidual(N_Vector x, N_Vector f, void* user_data)
{
  int i,sub2,sub3;

  RADAUIIA* rData = (RADAUIIA*) user_data;
  double* feq = NV_DATA_S(f);
  double h = *(rData->dt);
  double t0 = *rData->t0;

  double* lb = rData->min;
  double* ub = rData->max;
  DATA* data  = rData->data;

  double *x0,*x1,*x2,*x3;
  int n = rData->nState;
  double* xlow, *xup;
  double*derx = rData->derx;
  double*a = rData->a;
  double* flow, *fup;


  flow = feq + 3*n;
  fup  = flow + 3*n;

  x0 = rData->x0;
  x1 = NV_DATA_S(x);
  x2 = x1 + n;
  x3 = x2 + n;

  xlow = x1 + 3*n;
  xup  = xlow + 3*n;

  refreshModell(data, x1,t0 + a[0]*h);
  for(i = 0;i<n;i++)
  {
    feq[i] = (rData->C[0][0]*x0[i] + rData->C[0][3]*x3[i] + h*derx[i]) -
             (rData->C[0][1]*x1[i] + rData->C[0][2]*x2[i]);

    flow[i] = xlow[i] - x1[i] + lb[i];
    fup[i] = xup[i] - x1[i] +  ub[i];
  }

  refreshModell(data, x2,t0 + a[1]*h);
  for(i = 0;i<n;i++)
  {
    sub2 = i + n;

    feq[sub2] = (rData->C[1][1]*x1[i] + h*derx[i]) -
                (rData->C[1][0]*x0[i] + rData->C[1][2]*x2[i] + rData->C[1][3]*x3[i]);

    flow[sub2] = xlow[sub2] - x2[i] + lb[i];
    fup[sub2] = xup[sub2] -  x2[i] + ub[i];
  }

  refreshModell(data, x3, t0 + a[2]*h);
  for(i = 0;i<n;i++)
  {
    sub3 = i + 2*n;
    feq[sub3] =  (rData->C[2][0]*x0[i] + rData->C[2][2]*x2[i] + h*derx[i]) -
                 (rData->C[2][1]*x1[i] + rData->C[2][3]*x3[i]);

    flow[sub3] = xlow[sub3] - x3[i] + lb[i];
    fup[sub3] = xup[sub3] - x3[i] + ub[i];
  }

  return 0;
}

int kinsolRadauIIA(RADAUIIA* rData)
{

  KINSOLRADAU*kData = rData->kData;
  do{
    initKinsol(rData, kData);
    /* Call KINDense to specify the linear solver */
    KINDense(kData->kmem, 9*rData->nState);
    KINSetMaxSetupCalls(kData->kmem, kData->mset);

    kData->error_code = KINSol( kData->kmem,           /* KINSol memory block */
                                kData->x,              /* initial guess on input; solution vector */
                                kData->glstr,          /* global stragegy choice */
                                kData->sVars,          /* scaling vector, for the variable cc */
                                kData->sEqns );

  }while(kData->error_code < 0 && (kData->glstr++) <= KIN_LINESEARCH);

  kData->glstr = KIN_NONE;
  refreshModell(rData->data, NV_DATA_S(kData->x) + 2*rData->nState, *rData->t0 + rData->a[2]*(*rData->dt));
  return 0;
}

#endif
