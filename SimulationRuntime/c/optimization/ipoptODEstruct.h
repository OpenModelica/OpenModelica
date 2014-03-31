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

  long double b[3][5];

  long double c[3][5];

  long double a[5][5];
  long double d[5][5];

  long double invd1_4;

  double *dotx[7];

  double *x[7];
  double *u[7];

}OPTIMIZER_MBASE;

typedef struct OPTIMIZER_TIME{

  long double t0;
  long double tf;
  long double *dt;
  long double *time;

  long double startTimeOpt;

}OPTIMIZER_TIME;

typedef struct OPTIMIZER_STUCTURE{

  modelica_boolean matrixA;
  modelica_boolean matrixB;
  modelica_boolean matrixC;
  modelica_boolean matrixD;

  modelica_boolean ** gradFs;

  modelica_boolean **knowedJ;

  modelica_boolean **Hg;
  modelica_boolean **Hl;
  modelica_boolean **HH;

  modelica_boolean mayer;
  modelica_boolean lagrange;

  modelica_boolean useNumJac;

  modelica_boolean preSim;

}OPTIMIZER_STUCTURE;


typedef struct OPTIMIZER_BOUNDS{

  double * xmin;
  double * xmax;
  double * umin;
  double * umax;
  double * vmin;
  double * vmax;
  double * Vmin;
  double * Vmax;

  double *gmin;
  double *gmax;

}OPTIMIZER_BOUNDS;

typedef struct OPTIMIZER_SCALING{

  double * vnom;
  long double *scalVar;
  long double *scalRes;
  long double *scalJac;
  long double *scalf;
  long double ** scaldt;

  long double scald;

}OPTIMIZER_SCALING;


typedef struct OPTIMIZER_DF{

  long double **J0;
  long double **J;

  long double ** gradFomc;

  long double * gradF[4];

  long double ***H;
  long double **oH;
  long double **mH;

}OPTIMIZER_DF;


typedef struct IPOPT_DATA_
{
  /*#*/
  OPTIMIZER_DIM_VARS dim;

  /*coeff*/
  OPTIMIZER_MBASE mbase;

  /*time*/
  OPTIMIZER_TIME dtime;

  OPTIMIZER_STUCTURE sopt;

  OPTIMIZER_BOUNDS bounds;
  OPTIMIZER_SCALING scaling;

  OPTIMIZER_DF df;

  /* ODE */
  double * x0;
  double * start_u;

  double *sh;
  double *sv;
  double *v;
  double *w;
  double *cv;

  int endN;

  double *mult_g;
  double *mult_x_L;
  double *mult_x_U;

  int current_var;
  int current_time;

  short mayer_index;
  short lagrange_index;

  DATA * data;

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
