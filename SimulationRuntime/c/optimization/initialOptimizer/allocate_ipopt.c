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
#include "simulation_data.h"

#ifdef WITH_IPOPT

static int local_jac_struct(IPOPT_DATA_ *iData);

/*!
 *  allocate
 *  author: Vitalij Ruge
 **/
int allocateIpoptData(IPOPT_DATA_ *iData)
{
  int deg1, deg2, i, j;
  deg1 = iData->deg + 1;
  deg2 = deg1 + 1;
  iData->gmin = (double*)calloc(iData->NRes,sizeof(double));
  iData->gmax = (double*)calloc(iData->NRes,sizeof(double));
  iData->mult_g = (double*)malloc(iData->NRes*sizeof(double));
  iData->mult_x_L = (double*)malloc(iData->NV*sizeof(double));
  iData->mult_x_U = (double*)malloc(iData->NV*sizeof(double));
  iData->a1 = (double*)malloc(deg1*sizeof(double));
  iData->a2 = (double*)malloc(deg1*sizeof(double));
  iData->a3 = (double*)malloc(deg1*sizeof(double));
  iData->d1 = (double*)malloc(deg2*sizeof(double));
  iData->d2 = (double*)malloc(deg2*sizeof(double));
  iData->d3 = (double*)malloc(deg2*sizeof(double));
  iData->lhs = (double*)malloc(iData->nx*sizeof(double));
  iData->rhs = (double*)malloc(iData->nx*sizeof(double));
  iData->dotx0 = (double*)malloc(iData->nx*sizeof(double));
  iData->dotx1 = (double*)malloc(iData->nx*sizeof(double));
  iData->dotx2 = (double*)malloc(iData->nx*sizeof(double));
  iData->dotx3 = (double*)malloc(iData->nx*sizeof(double));
  iData->xmin = (double*)malloc(iData->nx*sizeof(double));
  iData->xmax = (double*)malloc(iData->nx*sizeof(double));
  iData->umin = (double*)malloc(iData->nu*sizeof(double));
  iData->umax = (double*)malloc(iData->nu*sizeof(double));
  iData->vmin = (double*)malloc(iData->nv*sizeof(double));
  iData->vmax = (double*)malloc(iData->nv*sizeof(double));
  iData->vnom = (double*)malloc(iData->nv*sizeof(double));
  iData->scalVar = (double*)malloc(iData->nv*sizeof(double));
  iData->scalf = (double*)malloc(iData->nx*sizeof(double));
  iData->Vmin = (double*)malloc(iData->NV*sizeof(double));
  iData->Vmax = (double*)malloc(iData->NV*sizeof(double));
  iData->v = (double*)malloc(iData->NV*sizeof(double));
  iData->w = (double*)malloc((iData->nsi + 1)*(iData->nv)*sizeof(double));
  iData->time = (double*)malloc((iData->deg*iData->nsi +1) *sizeof(double));


  iData->J = (double**) malloc(iData->nx * sizeof(double*));
  for(i = 0; i < iData->nx; i++)
    iData->J[i] = (double*) calloc(iData->nv, sizeof(double));

  iData->a1_ = (double**) malloc(deg1 * sizeof(double*));
  iData->a2_ = (double**) malloc(deg1 * sizeof(double*));
  iData->a3_ = (double**) malloc(deg1 * sizeof(double*));

  iData->sv = (double*)malloc(iData->nv*sizeof(double));
  iData->sh = (double*)malloc(iData->nv*sizeof(double));

  for(i = 0; i < deg1; i++)
  {
    iData->a1_[i] = (double*) malloc(iData->nx* sizeof(double));
    iData->a2_[i] = (double*) malloc(iData->nx* sizeof(double));
    iData->a3_[i] = (double*) malloc(iData->nx* sizeof(double));
  }

  iData->d1_ = (double**) malloc(deg2 * sizeof(double*));
  iData->d2_ = (double**) malloc(deg2 * sizeof(double*));
  iData->d3_ = (double**) malloc(deg2 * sizeof(double*));

  for(i = 0; i < deg2; i++)
  {
    iData->d1_[i] = (double*) malloc(iData->nx* sizeof(double));
    iData->d2_[i] = (double*) malloc(iData->nx* sizeof(double));
    iData->d3_[i] = (double*) malloc(iData->nx* sizeof(double));
  }

  iData->J0 = (double**) malloc(iData->nx * sizeof(double*));
  for(i = 0; i < iData->nx; i++)
    iData->J0[i] = (double*) calloc(iData->nv, sizeof(double));

  iData->numJ = (double**) malloc(iData->nx * sizeof(double*));
  for(i = 0; i < iData->nx; i++)
    iData->numJ[i] = (double*) calloc(iData->nv, sizeof(double));

  iData->H = (long double***) malloc(iData->nx * sizeof(long double**));
  for(i = 0; i < iData->nx; i++)
  {
    iData->H[i] = (long double**) malloc(iData->nv* sizeof(long double*));
    for(j = 0; j < iData->nv; j++)
      iData->H[i][j] = (long double*) malloc(iData->nv* sizeof(long double));
  }
  iData->oH = (long double**) malloc(iData->nv * sizeof(long double*));
  for(i = 0; i < iData->nv; i++)
    iData->oH[i] = (long double*) calloc(iData->nv, sizeof(long double));

  iData->mH = (long double**) malloc(iData->nv * sizeof(long double*));
  for(i = 0; i < iData->nv; i++)
    iData->mH[i] = (long double*) calloc(iData->nv, sizeof(long double));

  return 0;
}

/*!
 *  free
 *  author: Vitalij Ruge
 **/
int freeIpoptData(IPOPT_DATA_ *iData)
{
  int i,j;
  for(i = 0; i < iData->nx; i++)
    free(iData->J[i]);
  free(iData->J);

  for(i = 0; i < iData->nx; i++)
    free(iData->J0[i]);
  free(iData->J0);

  for(i = 0; i < iData->nx; i++)
  {
    for(j = 0;j<iData->nv; ++j)
      free(iData->H[i][j]);
    free(iData->H[i]);
  }
  free(iData->H);


  free(iData->gmin);
  free(iData->gmax);
  free(iData->mult_g);
  free(iData->mult_x_L);
  free(iData->mult_x_U);
  free(iData->a1);
  free(iData->a2);
  free(iData->a3);
  free(iData->d1);
  free(iData->d2);
  free(iData->d3);
  free(iData->dotx0);
  free(iData->dotx1);
  free(iData->dotx2);
  free(iData->dotx3);
  free(iData->xmin);
  free(iData->xmax);
  free(iData->umin);
  free(iData->umax);
  free(iData->vmin);
  free(iData->vmax);
  free(iData->vnom);
  free(iData->scalVar);
  free(iData->scalf);
  free(iData->Vmin);
  free(iData->Vmax);
  free(iData->v);
  free(iData->time);
  free(iData->w);
  free(iData->dt);
  free(iData);
    iData = NULL;
  return 0;
}
/*!
 *  free
 *  intarface to simulation
 *  author: Vitalij Ruge
 **/
int destroyIpopt(SOLVER_INFO* solverInfo)
{
  return freeIpoptData( (IPOPT_DATA_*)solverInfo->solverData );
}

/*!
 *  set data from model
 *  author: Vitalij Ruge
 **/
int loadDAEmodel(DATA *data, IPOPT_DATA_ *iData)
{
  int i,j,k,l,id;
  double tmp;
  double *u0;
  char buffer[4096];

  iData->nx = data->modelData.nStates;
  iData->nu = data->modelData.nInputVars;

  iData->deg = 3;
  iData->nsi = data->simulationInfo.numSteps;
  iData->t0 = data->simulationInfo.startTime;
  iData->tf = data->simulationInfo.stopTime;

  iData->dt_default = (iData->tf - iData->t0)/iData->nsi;
  move_grid(iData);

  iData->nX = iData->nx * iData->deg;
  iData->nU = iData->nu * iData->deg;

  iData->NX = iData->nX * iData->nsi + iData->nx;
  iData->NU = iData->nU * iData->nsi + iData->nu;

  iData->nv = iData->nx + iData->nu;
  iData->nV = iData->nX + iData->nU;
  iData->NV = iData->NX + iData->NU;

  iData->nRes = iData->nx*iData->deg;
  iData->NRes = iData->nRes * iData->nsi;

  iData->endN = iData->NV - iData->nv - 1;

  /* iData->njac =  iData->nX*iData->nsi*(iData->nv + iData->deg) + iData->nX*(iData->nv-1); */
  local_jac_struct(iData);
  iData->njac = iData->deg*(iData->nlocalJac-iData->nx+iData->nsi*iData->nlocalJac+iData->deg*iData->nsi*iData->nx);
  iData->nhess = 0.5*iData->nv*(iData->nv + 1)*(1+iData->deg*iData->nsi);

  allocateIpoptData(iData);

  iData->c1 = 0.15505102572168219018027159252941086080340525193433;
  iData->c2 = 0.64494897427831780981972840747058913919659474806567;
  iData->c3 = 1.0;

  iData->e1 = 0.27639320225002103035908263312687237645593816403885;
  iData->e2 = 0.72360679774997896964091736687312762354406183596115;
  iData->e3 = 1.0;

  iData->a1[0] = 4.1393876913398137178367408896470696703591369767880;
  iData->a1[1] = 3.2247448713915890490986420373529456959829737403284;
  iData->a1[2] = 1.1678400846904054949240412722156950122337492313015;
  iData->a1[3] = 0.25319726474218082618594241992157103785758599484179;

  iData->a2[0] = 1.7393876913398137178367408896470696703591369767880;
  iData->a2[1] = 3.5678400846904054949240412722156950122337492313015;
  iData->a2[2] = 0.7752551286084109509013579626470543040170262596716;
  iData->a2[3] = 1.0531972647421808261859424199215710378575859948418;

  iData->a3[0] = 3.0;
  iData->a3[1] = 5.5319726474218082618594241992157103785758599484179;
  iData->a3[2] = 7.5319726474218082618594241992157103785758599484179;
  iData->a3[3] = 5.0;

  iData->d1[0] = 4.3013155617496424838955952368431696002490512113396;
  iData->d1[1] = 3.6180339887498948482045868343656381177203091798058;
  iData->d1[2] = 0.8541019662496845446137605030969143531609275394172;
  iData->d1[3] = 0.17082039324993690892275210061938287063218550788345;
  iData->d1[4] = 0.44721359549995793928183473374625524708812367192230;

  iData->d2[0] = 3.3013155617496424838955952368431696002490512113396;
  iData->d2[1] = 5.8541019662496845446137605030969143531609275394172;
  iData->d2[2] = 1.3819660112501051517954131656343618822796908201942;
  iData->d2[3] = 1.1708203932499369089227521006193828706321855078834;
  iData->d2[4] = 0.44721359549995793928183473374625524708812367192230;

  iData->d3[0] = 7.0;
  iData->d3[1] = 11.180339887498948482045868343656381177203091798058;
  iData->d3[2] = 11.180339887498948482045868343656381177203091798058;
  iData->d3[3] = 7.0;
  iData->d3[4] = 1.0;

  iData->bl[0] = 0.083333333333333333333333333333333333333333333333333;
  iData->bl[1] = 0.41666666666666666666666666666666666666666666666667;
  iData->bl[2] = iData->bl[1];
  iData->bl[3] = 1.0 - (iData->bl[0]+iData->bl[1]+iData->bl[2]);

  iData->br[2] = 0.11111111111111111111111111111111111111111111111111;
  iData->br[1] = 0.51248582618842161383881344651960809422127631890713;
  iData->br[0] = 1.0 - (iData->br[1] + iData->br[2]);

  iData->x0 = iData->data->localData[1]->realVars;


  for(i =0;i<iData->nx;++i)
  {
    if(data->modelData.realVarsData[i].attribute.nominal)
      iData->vnom[i] = fmax(fabs(data->modelData.realVarsData[i].attribute.nominal),1e-16);
    else
    {
      iData->vnom[i] = 0.5*(fabs(data->modelData.realVarsData[i].attribute.max) + fabs(data->modelData.realVarsData[i].attribute.min));
      if(iData->vnom[i] > 1e12)
        iData->vnom[i] = fabs(iData->x0[i]);
      iData->vnom[i] = fmax(iData->vnom[i],1e-16);
    }
    /* printf("\nvnom[%i] = %g",i,iData->vnom[i]); */
    iData->scalVar[i] = 1.0 / iData->vnom[i];
    iData->scalf[i] = iData->scalVar[i];

    iData->xmin[i] = data->modelData.realVarsData[i].attribute.min*iData->scalVar[i];
    iData->xmax[i] = data->modelData.realVarsData[i].attribute.max*iData->scalVar[i];
  }
  iData->index_u = data->modelData.nVariablesReal - iData->nu;
  id = iData->index_u;

  for(i =0,j = iData->nx;i<iData->nu;++i,++j)
  {
    iData->vnom[j] = fmax(fabs(data->modelData.realVarsData[id +i].attribute.nominal),1e-16);
    iData->scalVar[j] = 1.0 / iData->vnom[j];
    iData->umin[i] = data->modelData.realVarsData[id +i].attribute.min*iData->scalVar[j];
    iData->umax[i] = data->modelData.realVarsData[id +i].attribute.max*iData->scalVar[j];
  }

  for(i = 0; i<iData->deg + 1; ++i)
    for(j = 0; j<iData->nx; ++j)
    {
      iData->a1_[i][j] = iData->a1[i];
      iData->a2_[i][j] = iData->a2[i];
      iData->a3_[i][j] = iData->a3[i];
      iData->d1_[i][j] = iData->d1[i];
      iData->d2_[i][j] = iData->d2[i];
      iData->d3_[i][j] = iData->d3[i];
    }

  for(j = 0; j<iData->nx; ++j)
  {
    iData->d1_[i][j] = iData->d1[i];
    iData->d2_[i][j] = iData->d2[i];
    iData->d3_[i][j] = iData->d3[i];
  }

  memcpy(iData->vmin, iData->xmin, sizeof(double)*iData->nx);
  memcpy(iData->vmin + iData->nx, iData->umin, sizeof(double)*iData->nu);

  memcpy(iData->vmax, iData->xmax, sizeof(double)*iData->nx);
  memcpy(iData->vmax + iData->nx, iData->umax, sizeof(double)*iData->nu);


  memcpy(iData->Vmin, iData->vmin, sizeof(double)*iData->nv);
  memcpy(iData->Vmax, iData->vmax, sizeof(double)*iData->nv);
  for(i = 0,id = iData->nv; i < iData->nsi*iData->deg;i++,id += iData->nv)
  {
    memcpy(iData->Vmin + id, iData->vmin, sizeof(double)*iData->nv);
    memcpy(iData->Vmax + id, iData->vmax, sizeof(double)*iData->nv);
  }

  iData->time[0] = iData->t0;
  for(i = 0,k=0,id=0; i<iData->nsi; ++i,id += iData->deg)
  {
    if(i>0)
    {
      iData->time[++k] = iData->time[id] + iData->c1*iData->dt[i];
      iData->time[++k] = iData->time[id] + iData->c2*iData->dt[i];
      iData->time[++k] = iData->time[id] + iData->c3*iData->dt[i];
    }else{
      iData->time[++k] = iData->time[id] + iData->e1*iData->dt[i];
      iData->time[++k] = iData->time[id] + iData->e2*iData->dt[i];
      iData->time[++k] = iData->time[id] + iData->e3*iData->dt[i];
    }
  }
  iData->time[k] = iData->tf;

  if(ACTIVE_STREAM(LOG_IPOPT))
  {
    iData->pFile = (FILE**) calloc(iData->nv, sizeof(FILE*));
    for(i=0, j=0; i<iData->nv; i++, ++j)
    {
      if(j <iData->nx)
      {
        sprintf(buffer, "./%s_ipoptPath_states.csv", iData->data->modelData.realVarsData[j].info.name);
      }
      else if(j< iData->nv)
      {
        sprintf(buffer, "./%s_ipoptPath_input.csv", iData->data->modelData.realVarsData[iData->index_u + j-iData->nx].info.name);
      }
      iData->pFile[j] = fopen(buffer, "wt");
      fprintf(iData->pFile[j], "%s,", "iteration");
    }


    for(i=0 ,k=0,j =0; i<iData->NV; ++i,++j)
    {
      if(j >= iData->nv)
      {
        j = 0;
        ++k;
      }

      if(j < iData->nx)
      {
        fprintf(iData->pFile[j], "%s(%g),", iData->data->modelData.realVarsData[j].info.name, iData->time[k]);
      }
      else if(j < iData->nv)
      {
        fprintf(iData->pFile[j], "%s(%g),", iData->data->modelData.realVarsData[iData->index_u + j-iData->nx].info.name, iData->time[k]);
      }
    }
  }

/*
  printf("\nk = %i , NX = %i",(int)k,(int)(iData->deg*iData->nsi +1));
  for(i = 0; i<(iData->deg*iData->nsi +1); ++i)
    printf("\nt[%i] = %g", i, iData->time[i]);
*/
  return 0;
}

/*!
 *  time grid for optimization
 *  author: Vitalij Ruge
 **/
int move_grid(IPOPT_DATA_ *iData)
{
  int i;
  double t;
  iData->dt = (double*)malloc((iData->nsi) *sizeof(double));
  t = iData->t0;

  for(i =0; i< 0.2*iData->nsi;++i)
  {
    iData->dt[i] = iData->dt_default;
    t += iData->dt[i];
  }

  for(; i< 0.3*iData->nsi;++i)
  {
    iData->dt[i] = iData->dt_default;
    t += iData->dt[i];
  }

  for(; i< 0.4*iData->nsi;++i)
  {
    iData->dt[i] = iData->dt_default;
    t += iData->dt[i];
  }

  for(; i< 0.6*iData->nsi;++i)
  {
    iData->dt[i] = iData->dt_default;
    t += iData->dt[i];
  }

  for(; i< 0.7*iData->nsi;++i)
  {
    iData->dt[i] = iData->dt_default;
    t += iData->dt[i];
  }

  for(; i< 0.8*iData->nsi;++i)
  {
    iData->dt[i] = iData->dt_default;
    t += iData->dt[i];
  }

  for(; i< iData->nsi;++i)
  {
    iData->dt[i] = iData->dt_default;
    t += iData->dt[i];
  }
  iData->dt[iData->nsi-1] = iData->dt_default + (iData->tf - t );
/*
  for(i = 0; i<iData->nsi;++i){
    printf("\n*dt[%i] =%g | %i",i,iData->dt[i],iData->nsi);
  }
*/
  return 0;
}

/*
 *  function calculates a jacobian matrix struct
 *  author: Willi
 */
int local_jac_struct(IPOPT_DATA_ *iData)
{
  DATA * data = iData->data;
  const int index1 = 1;
  const int index2 = 2;
  int index;
  int **J;

  int i,j,l,ii,nx,k;
  int *cC,*lindex;

  iData->nlocalJac = 0;
  iData->knowedJ = (int**) malloc(iData->nx * sizeof(int*));
  for(i = 0; i < iData->nx; i++)
    iData->knowedJ[i] = (int*) calloc(iData->nv, sizeof(int));

  J = iData->knowedJ;

  for(index=index1; index<index2+1; ++index)
  {
    nx = data->simulationInfo.analyticJacobians[index].sizeCols;
    cC =  data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
    lindex = data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;

    k = (index == index1) ? 0: iData->nx;

    for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i)
    {
      for(ii = 0; ii<nx; ++ii)
      {
        if(cC[ii] == i)
        {
          data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1.0;
        }
      }

      for(ii = 0; ii < nx; ii++)
      {
        if(cC[ii] == i)
        {
          if(0 == ii)
            j = 0;
          else
            j = lindex[ii-1];

          for(; j<lindex[ii]; ++j)
          {
            l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
            J[l][ii + k] = 1;
            ++iData->nlocalJac;
          }
        }
      }

      for(ii = 0; ii<nx; ++ii)
      {
        if(cC[ii] == i)
        {
          data->simulationInfo.analyticJacobians[index].seedVars[ii] = 0.0;
        }
      }
    }
  }

  for(ii = 0; ii < iData->nx; ii++)
  {
    if(J[ii][ii] == 0)
      ++iData->nlocalJac;
    J[ii][ii] = 1.0;
  }

  if(ACTIVE_STREAM(LOG_IPOPT))
  {
    for(ii = 0; ii < iData->nx; ++ii)
    {
      printf("\n");
      for(j =0;j<iData->nv;++j)
        printf("%i \t",J[ii][j]);
      printf("\n");
    }
  }

  return 0;
}

#endif
