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

#ifndef _OPTIMIZER_DATA_H
#define _OPTIMIZER_DATA_H

#include "omc_config.h"
#include "../simulation_data.h"
#include "../simulation/solver/solver_main.h"
#include <string.h>
#include <Ipopt/IpStdCInterface.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <math.h>
#include <float.h>


typedef struct OptDataDim{
 int nx;
 int nu;
 int nc;
 int ncf;
 int nv;
 int NV;
 int NRes;
 int nJ;
 int nJ2;
 modelica_integer nsi;
 int nt;

 int np;
 int nReal;

 int index_con;
 int index_conf;
 int index_lagrange;
 int index_mayer;

 int nJderx;
 int nJfderx;
 int nH0;
 int nH1;
 int nH0_;
 int nH1_;

 char ** inputName;


 int updateHessian;
 int iter_updateHessian;

 modelica_real **** analyticJacobians_tmpVars;

 int dim_tmpVars[2];
 modelica_boolean exTimeGrid;

 int iter;

}OptDataDim;

typedef struct OptDataTime{
  long double t0;
  long double tf;
  long double *dt;

  long double **t;
  modelica_real *tt;
  modelica_boolean model_grid;
}OptDataTime;

typedef struct OptDataBounds{
  modelica_real *vmin;
  modelica_real *vmax;
  modelica_real *Vmin;
  modelica_real *Vmax;

  modelica_real *vnom;
  long double *scalF;
  long double **scaldt;
  long double **scalb;

  modelica_real *u0;
  double preSim;
}OptDataBounds;

typedef struct OptDataRK{
  long double a[5][5];
  long double b[5];
}OptDataRK;

typedef struct OptDataIpopt{
  double *vopt;
  double *gmin;
  double *gmax;
  double *mult_g;
  double *mult_x_L;
  double *mult_x_U;
  char * csvOstep;
  char * debugeJ;
}OptDataIpopt;

typedef struct OptDataStructure{
  modelica_boolean matrix[5];
  modelica_boolean ***J;
  modelica_boolean **Jf;
  modelica_boolean **H0;
  modelica_boolean **H1;
  modelica_boolean ***Hg;
  modelica_boolean ***Hcf;
  modelica_boolean **Hm;
  modelica_boolean **Hl;
  modelica_boolean lagrange;
  modelica_boolean mayer;
  short derIndex[3];
  unsigned int **lindex;
  modelica_real *pmayer;
  modelica_real *plagrange;
  modelica_real *** seedVec;
  modelica_boolean ** JderCon;
  modelica_boolean * gradM;
  modelica_boolean * gradL;
  int * indexCon2;
  int * indexCon3;
  int * indexJ2;
  int * indexJ3;
  int indexABCD[5];
}OptDataStructure;


typedef struct OptData{
  OptDataDim dim;
  OptDataTime time;
  OptDataBounds bounds;
  OptDataRK rk;
  OptDataStructure s;
  OptDataIpopt ipop;

  modelica_real ***v;
  modelica_real *v0;
  modelica_real *sv0;

  modelica_integer* i0;
  modelica_boolean* b0;
  modelica_integer* i0Pre;
  modelica_boolean* b0Pre;
  modelica_real* v0Pre;

  modelica_boolean* rePre;
  modelica_boolean* re;

  modelica_boolean * storeR;

  modelica_real ****J;
  modelica_real ** tmpJ;
  modelica_real ** Jf;
  modelica_real ** tmpJf;
  long double ***H;
  long double **Hl;
  long double **Hm;
  long double ***Hcf;
  DATA *data;
  threadData_t *threadData;
  FILE * pFile;

  double *oldH;
  int iter_;
  short index;
  modelica_boolean scc;

}OptData;

#endif
