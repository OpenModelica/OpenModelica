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

#ifndef IPOPTODESTRUCT_H
#define IPOPTODESTRUCT_H

#include "../../../../Compiler/runtime/config.h"
#include "simulation_data.h"
#include "../simulation/solver/solver_main.h"

#ifdef WITH_IPOPT
#include <string.h>
#include <coin/IpStdCInterface.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <math.h>
#include <float.h>

typedef struct OPTIMIZER_DIM_VARS{

  int nx;
  int nu;
  int nv;
  int nX;
  int nU;
  int nV;
  int nRes;
  int NX;
  int NU;
  int NV;
  int NRes;
  int nc;
  int nJ;

  int njac;
  int nhess;
  int nsi;
  int np;
  int nlocalJac;

  int deg;

  int nH;

}OPTIMIZER_DIM_VARS;

typedef struct OPTIMIZER_MBASE{

  double bl[10];
  double br[10];

}OPTIMIZER_MBASE;
typedef struct IPOPT_DATA_
{
  /*#*/
  OPTIMIZER_DIM_VARS dim;
  /* ODE */
  double * x0;
  double * xmin;
  double * xmax;
  double * umin;
  double * umax;
  double * vmin;
  double * vmax;
  double * Vmin;
  double * Vmax;

  double * vnom;
  double * start_u;

  double *scalVar;
  double *scalRes;
  double *scalJac;
  double *scalf;

  /*time*/
  double t0;
  double tf;
  modelica_real startTimeOpt;
  /* double dt; */
  double t;
  double dt_min;
  double dt_max;
  double dt_default;
  double *dt;

  double *lhs;
  double *rhs;
  double *sh;
  double *sv;
  double *v;
  double *w;
  double *cv;
  double *dotx0;
  double *dotx1;
  double *dotx2;
  double *dotx3;

  double *x1;
  double *x2;
  double *x3;

  double *u1;
  double *u2;
  double *u3;

  double c1;
  double c2;
  double c3;

  double *a1;
  double *a2;
  double *a3;

  double **a1_;
  double **a2_;
  double **a3_;

  double *d1;
  double *d2;
  double *d3;
  double invd1_4;
  double **d1_;
  double **d2_;
  double **d3_;

  double e1;
  double e2;
  double e3;

  double bl[4];
  double br[3];

  double *gmin;
  double *gmax;

  long int endN;
  double **J0;
  double **J;
  double ** gradFomc;
  double * gradF;
  double * gradMF;
  double * gradF_;
  double * gradF0;
  double * gradF00;
  modelica_boolean ** gradFs;
  int **knowedJ;
  double **numJ;
  long double ***H;
  long double **oH;
  long double **mH;
  short **Hg;
  short **Hl;
  short **HH;

  int * iRow;
  int * iCol;

  double *mult_g;
  double *mult_x_L;
  double *mult_x_U;

  long int current_var;
  long int current_time;
  double *time;
  short mayer;
  short lagrange;
  double pmayer;
  double plagrange;
  int mayer_index;
  int lagrange_index;
  DATA * data;

  int matrixA;
  int matrixB;
  int matrixC;
  int matrixD;

  short useNumJac;
  double *vsave;
  double *eps;

  modelica_boolean preSim;
  char ** input_name;

  /*Debuger*/
  FILE **pFile;
  long index_debug_iter;
  int degub_step;
  long index_debug_next;

}IPOPT_DATA_;

#else /* WITH_IPOPT */

typedef struct IPOPT_DATA_
{
  void * empty_data;
}IPOPT_DATA_;

#endif /* WITH_IPOPT */
#endif /* IPOPTODESTRUCT_H */
