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

/*! EvalF.c
 */

#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"

static inline void updateDer(OptData *optData);

/* eval object function
 * author: Vitalij Ruge
 */
Bool evalfF(Index n, Number * vopt, Bool new_x, Number *objValue, void * useData){

  OptData *optData = (OptData*)useData;

  const modelica_boolean la = optData->s.lagrange;
  const modelica_boolean ma = optData->s.mayer;

  long double mayer = 0.0;
  long double lagrange = 0.0;

  if(new_x)
    optData2ModelData(optData, vopt, 0);

  if(la){
    const int nsi = optData->dim.nsi;
    const int np = optData->dim.np;
    const int il = optData->dim.index_lagrange;

    const long double * const b = optData->rk.b;
    const long double * const dt = optData->time.dt;

    modelica_real *** v = optData->v;
    long double erg = 0.0;
    long double erg1 = 0.0;
    int i,j;

    for(i = 0; i + 1 < nsi; ++i){
      for(j = 0; j< np; ++j){
        erg += b[j]*v[i][j][il];
      }
    }

    i = nsi - 1;
    for(j = 0; j< np; ++j)
      erg1 += b[j]*v[i][j][il];

    lagrange = (erg*dt[0] + erg1*dt[1]);
  }

  if(ma){
    modelica_real *** v = optData->v;
    const int nsi = optData->dim.nsi;
    const int np = optData->dim.np;
    const int im = optData->dim.index_mayer;
    mayer = v[nsi-1][np-1][im];
  }

  *objValue = (Number)(lagrange + mayer);

  return TRUE;
}


/*!
 *  eval derivation (object func)
 *  author: Vitalij Ruge
 **/
Bool evalfDiffF(Index n, double * vopt, Bool new_x, Number *gradF, void * useData){
  OptData *optData = (OptData*)useData;

  const int nv = optData->dim.nv;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;

  const modelica_boolean la = optData->s.lagrange;
  const modelica_boolean ma = optData->s.mayer;

  if(new_x)
    optData2ModelData(optData, vopt, 3);
  else
    updateDer(optData);

  if(la){

    const int k = optData->s.derIndex[0];
    int i, j, ii;
    modelica_real * gradL;

    for(i = 0, ii = 0; i < nsi; ++i){
      for(j = 0; j < np; ++j, ii += nv){
        gradL = optData->J[i][j][k];
        memcpy(gradF + ii, gradL, nv*sizeof(modelica_real));
      }
    }
  }else{
    memset(gradF,0.0,n*sizeof(Number));
  }

  if(ma){
    const int k = optData->s.derIndex[1];
    modelica_real * gradM = optData->J[nsi - 1][np -1][k];

    int i, ii;

    for(i = 0, ii = n - nv; i < nv; ++i, ++ii){
      gradF[ii] += gradM[i];
    }

  }

  return TRUE;
}


/*!
 *  update jacobian matrix
 *  author: Vitalij Ruge
 **/
static inline void updateDer(OptData *optData){
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const modelica_boolean la = optData->s.lagrange;
  const modelica_boolean ma = optData->s.mayer;
  DATA * data = optData->data;
  modelica_real * realV[3];

  {
    int i;
    for(i = 0; i < 3; ++i)
      realV[i] = data->localData[i]->realVars;
  }

  if(la){
    const int index_la = optData->s.derIndex[0];
    long double *** scalb = optData->bounds.scalb;
    int i, j, ii;
    for(i = 0; i < nsi; ++i){
      for(j = 0; j < np; ++j){
        for(ii = 0; ii < 3; ++ii)
          data->localData[ii]->realVars = optData->v[i][j];

        data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
        diff_symColoredLagrange(optData, &optData->J[i][j][index_la], 2, scalb[i][j]);
      }
    }
  }

  if(ma){
    const int index_ma = optData->s.derIndex[1];
    const int i = nsi - 1;
    const int j = np - 1;
    int ii;

    for(ii = 0; ii < 3; ++ii)
      data->localData[ii]->realVars = optData->v[i][j];

    data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
    diff_symColoredMayer(optData, &optData->J[i][j][index_ma], 3);
  }

  {
    int ii;
    for(ii = 0; ii < 3; ++ii)
      data->localData[ii]->realVars = realV[ii];
  }

}
