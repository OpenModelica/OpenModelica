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
#include "../../simulation/options.h"

#ifdef WITH_IPOPT

#include "../localFunction.h"

static int freeIpoptData(IPOPT_DATA_ *iData);

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
 *  allocate
 *  author: Vitalij Ruge
 **/
int allocateIpoptData(IPOPT_DATA_ *iData)
{
  int deg1, deg2;
  long int i, j;
  int ng;
  OPTIMIZER_DIM_VARS* dim = &iData->dim;
  OPTIMIZER_MBASE *mbase = &iData->mbase;
  OPTIMIZER_STUCTURE *sopt = &iData->sopt;
  OPTIMIZER_BOUNDS *bounds = &iData->bounds;

  ng = dim->NRes+dim->nc*dim->deg*dim->nsi;
  deg1 = dim->deg + 1;
  deg2 = deg1 + 1;

  dim->nJ = dim->nc + dim->nx;
  bounds->gmin = (double*)calloc(ng,sizeof(double));
  bounds->gmax = (double*)calloc(ng,sizeof(double));
  iData->mult_g = (double*)malloc(ng*sizeof(double));
  iData->mult_x_L = (double*)malloc(dim->NV*sizeof(double));
  iData->mult_x_U = (double*)malloc(dim->NV*sizeof(double));
  iData->lhs = (double*)malloc((int)dim->nJ*sizeof(double));
  iData->rhs = (double*)malloc((int)dim->nJ*sizeof(double));

  for(i =0; i< dim->deg + 1; ++i)
    mbase->dotx[i] = (double*)malloc(dim->nx*sizeof(double));

  bounds->xmin = (double*)malloc(dim->nx*sizeof(double));
  bounds->xmax = (double*)malloc(dim->nx*sizeof(double));
  bounds->umin = (double*)malloc(dim->nu*sizeof(double));
  bounds->umax = (double*)malloc(dim->nu*sizeof(double));
  bounds->vmin = (double*)malloc(dim->nv*sizeof(double));
  bounds->vmax = (double*)malloc(dim->nv*sizeof(double));
  iData->vnom = (double*)malloc(dim->nv*sizeof(double));
  iData->scalVar = (double*)malloc(dim->nv*sizeof(double));
  iData->scalf = (double*)malloc(dim->nx*sizeof(double));
  bounds->Vmin = (double*)malloc(dim->NV*sizeof(double));
  bounds->Vmax = (double*)malloc(dim->NV*sizeof(double));
  iData->v = (double*)malloc(dim->NV*sizeof(double));
  iData->w = (double*)malloc((dim->nsi + 1)*(dim->nv)*sizeof(double));
  iData->dtime.time = (long double*)malloc((dim->deg*dim->nsi +1) *sizeof(long double));
  iData->start_u = (double*)malloc(dim->nv*sizeof(double));

  iData->J = (double**) malloc(dim->nJ * sizeof(double*));
  for(i = 0; i < dim->nJ; i++)
    iData->J[i] = (double*) calloc(dim->nv, sizeof(double));

  iData->gradF = (double*) calloc(dim->nv, sizeof(double));
  iData->gradF_ = (double*) calloc(dim->nv, sizeof(double));
  iData->gradF0 = (double*) calloc(dim->nv, sizeof(double));
  iData->gradF00 = (double*) calloc(dim->nv, sizeof(double));

  iData->sv = (double*)malloc(dim->nv*sizeof(double));
  iData->sh = (double*)malloc(dim->nJ*sizeof(double));

  iData->J0 = (double**) malloc(dim->nJ * sizeof(double*));
  for(i = 0; i < dim->nJ; i++)
    iData->J0[i] = (double*) calloc(dim->nv, sizeof(double));

  iData->gradFomc = (double**) malloc((2) * sizeof(double*));
  for(i = 0; i < 2; i++)
    iData->gradFomc[i] = (double*) calloc(dim->nv, sizeof(double));

  sopt->gradFs = (modelica_boolean**) malloc((2) * sizeof(modelica_boolean*));
  for(i = 0; i < 2; i++)
    sopt->gradFs[i] = (modelica_boolean*) calloc(dim->nv, sizeof(modelica_boolean));

  iData->H = (long double***) malloc(dim->nJ * sizeof(long double**));
  for(i = 0; i < dim->nJ; i++)
  {
    iData->H[i] = (long double**) malloc(dim->nv* sizeof(long double*));
    for(j = 0; j < dim->nv; j++)
      iData->H[i][j] = (long double*) malloc(dim->nv* sizeof(long double));
  }
  iData->oH = (long double**) malloc(dim->nv * sizeof(long double*));
  for(i = 0; i < dim->nv; i++)
    iData->oH[i] = (long double*) calloc(dim->nv, sizeof(long double));

  iData->mH = (long double**) malloc(dim->nv * sizeof(long double*));
  for(i = 0; i < dim->nv; i++)
    iData->mH[i] = (long double*) calloc(dim->nv, sizeof(long double));

  dim->nlocalJac = 0;

  sopt->knowedJ = (modelica_boolean**) malloc(dim->nJ* sizeof(modelica_boolean*));
  for(i = 0; i < dim->nJ; i++)
    sopt->knowedJ[i] = (modelica_boolean*) calloc(dim->nv, sizeof(modelica_boolean));

  sopt->Hg = (modelica_boolean**) malloc(dim->nv * sizeof(modelica_boolean*));
  for(i = 0; i < dim->nv; i++)
    sopt->Hg[i] = (modelica_boolean*) calloc(dim->nv, sizeof(modelica_boolean));

  iData->dtime.dt = (long double*)malloc((dim->nsi) *sizeof(long double));
  iData->input_name = (char**)malloc(dim->nv*sizeof(char*));

  if(dim->nc > 0)
    for(i = dim->nx; i<ng; i+=dim->nJ)
      for(j=0;j<dim->nc;++j)
        bounds->gmin[i+j] = -1e21;

  return 0;
}

/*!
 *  free
 *  author: Vitalij Ruge
 **/
static int freeIpoptData(IPOPT_DATA_ *iData)
{
  int i,j;
  OPTIMIZER_DIM_VARS* dim = &iData->dim;
  OPTIMIZER_MBASE *mbase = &iData->mbase;
  OPTIMIZER_TIME *dtime = &iData->dtime;
  OPTIMIZER_STUCTURE *sopt = &iData->sopt;
  OPTIMIZER_BOUNDS *bounds = &iData->bounds;

  for(i = 0; i < dim->nJ; i++){
    free(iData->J[i]);
    free(iData->J0[i]);
    free(sopt->knowedJ[i]);
  }
  free(iData->J0);
  free(iData->J);
  free(sopt->knowedJ);

  for(i=0;i<2;++i){
    free(iData->gradFomc[i]);
    free(sopt->gradFs[i]);
  }

  for(i = 0; i < dim->nv; i++){
    free(iData->oH[i]);
    free(iData->mH[i]);
    free(sopt->Hg[i]);
  }
  free(iData->oH);
  free(iData->mH);
  free(sopt->Hg);

  for(i = 0; i < dim->nJ; i++){

    for(j = 0;j<dim->nv; ++j)
      free(iData->H[i][j]);

    free(iData->H[i]);
  }
  free(iData->H);

  free(iData->gradF);
  free(iData->gradF_);
  free(iData->gradF0);
  free(iData->gradF00);
  free(bounds->gmin);
  free(bounds->gmax);
  free(iData->mult_g);
  free(iData->mult_x_L);
  free(iData->mult_x_U);

  for(i = 0; i<dim->deg+1; ++i)
    free(mbase->dotx[i]);


  free(bounds->xmin);
  free(bounds->xmax);
  free(bounds->umin);
  free(bounds->umax);
  free(bounds->vmin);
  free(bounds->vmax);
  free(iData->vnom);
  free(iData->scalVar);
  free(iData->scalf);
  free(bounds->Vmin);
  free(bounds->Vmax);
  free(iData->v);
  free(dtime->time);
  free(iData->w);
  free(dtime->dt);
  free(iData->lhs);
  free(iData->rhs);
  free(iData->sv);
  free(iData->sh);
  free(iData->start_u);

  for(i = 0; i<3;++i) {
    if(iData->data->simulationInfo.analyticJacobians[i].seedVars){
        free(iData->data->simulationInfo.analyticJacobians[i].seedVars);
        free(iData->data->simulationInfo.analyticJacobians[i].resultVars);
        free(iData->data->simulationInfo.analyticJacobians[i].tmpVars);
        free(iData->data->simulationInfo.analyticJacobians[i].sparsePattern.leadindex);
        free(iData->data->simulationInfo.analyticJacobians[i].sparsePattern.index);
       free(iData->data->simulationInfo.analyticJacobians[i].sparsePattern.colorCols);
    }
  }

  if(ACTIVE_STREAM(LOG_IPOPT_FULL))
  {
    for(i =0; i<dim->nv;++i)
      if(iData->pFile[i])
        fclose(iData->pFile[i]);
    if(iData->pFile)
      free(iData->pFile);
  }

  free(iData->input_name);
  free(iData);
  iData = NULL;
  return 0;
}

#endif
