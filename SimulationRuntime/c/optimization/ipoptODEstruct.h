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

  double *dotx[5];

  double *x[5];
  double *u[5];

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



typedef struct IPOPT_DATA_
{
  /*#*/
  OPTIMIZER_DIM_VARS dim;

  /*coeff*/
  OPTIMIZER_MBASE mbase;

  /*time*/
  OPTIMIZER_TIME dtime;

  OPTIMIZER_STUCTURE sopt;

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

  double *lhs;
  double *rhs;
  double *sh;
  double *sv;
  double *v;
  double *w;
  double *cv;

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

  long double ***H;
  long double **oH;
  long double **mH;

  int * iRow;
  int * iCol;

  double *mult_g;
  double *mult_x_L;
  double *mult_x_U;

  long int current_var;
  long int current_time;
  double pmayer;
  double plagrange;
  int mayer_index;
  int lagrange_index;
  DATA * data;

  double *vsave;
  double *eps;

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
