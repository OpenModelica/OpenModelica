/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

/*! \file rk_butcher.c
 *
 * Containing Butcher tableau for generic Runge-Kutta methods.
 */

// BB ToDo: generate automatically the Butcher tableau for Richardson extrapolation
// (depending on order) and introduce a corresponding flag

#include "rk_butcher.h"

#include <string.h>

#include "util/omc_error.h"
#include "util/simulation_options.h"
#include "simulation/options.h"


#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

void setButcherTableau(BUTCHER_TABLEAU* tableau, double *c, double *A, double *b, double * bt) {
  tableau->c = malloc(sizeof(double)*tableau->nStages);
  tableau->A = malloc(sizeof(double)*tableau->nStages * tableau->nStages);
  tableau->b = malloc(sizeof(double)*tableau->nStages);
  tableau->bt = malloc(sizeof(double)*tableau->nStages);

  memcpy(tableau->c, c, tableau->nStages*sizeof(double));
  memcpy(tableau->A, A, tableau->nStages * tableau->nStages * sizeof(double));
  memcpy(tableau->b, b, tableau->nStages*sizeof(double));
  memcpy(tableau->bt, bt, tableau->nStages*sizeof(double));
}

void getButcherTableau_ESDIRK2(BUTCHER_TABLEAU* tableau) {
  double lim = 0.7;

  // ESDIRK2 method
  /* initialize values of the Butcher tableau */
  double gam = (2.0-sqrt(2.0))*0.5;
  double c2 = 2.0*gam;
  double b1 = sqrt(2.0)/4.0;
  double b2 = b1;
  double b3 = gam;

  double bt1;
  double bt2;
  double bt3;

  tableau->nStages = 3;
  tableau->fac = 1.0;
  tableau->order_b = 2;

  if (lim<100)
  {
    tableau->order_bt = 1;

    bt1 = 1.0/4.0*(-3.0*lim+1.0)*sqrt(2.0)+lim;
    bt2 = -1.0/4.0*(3.0*sqrt(2.0)-4.0)*(-2.0*sqrt(2.0)+lim-3.0);
    bt3 = 1.0/2.0*(3.0*sqrt(2.0)-4.0)*(1.0+lim+sqrt(2.0));
  }
  else
  {
    tableau->order_bt = 3;

    bt1 = 1.0/3.0-(sqrt(2.0))/12.0;
    bt2 = 1.0/3.0+(sqrt(2.0))/4.0;
    bt3 = -(sqrt(2.0))/6.0+1.0/3.0;
  }
  /* Butcher Tableau */
  const double c[] = {0.0, c2, 1.0};
  const double A[] = {0.0, 0.0, 0.0,
                      gam, gam, 0.0,
                      b1, b2, b3};
  const double b[]  = {b1, b2, b3};
  const double bt[] = {bt1, bt2, bt3};

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_ESDIRK3(BUTCHER_TABLEAU* tableau) {
  double lim = 0.7;

  //ESDIRK3
  tableau->nStages = 4;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[]  = {0.0, .871733043016917998832038902388, 3./5., 1.0};
  const double A[]  = {
                          0.0, 0.0, 0.0, 0.0,
                          .435866521508458999416019451194, .435866521508458999416019451194, 0.0, 0.0,
                          .257648246066427245799996016284, -.935147675748862452160154674779e-1, .435866521508458999416019451194, 0.0,
                          .187641024346723825161292144158, -.595297473576954948047823027584, .971789927721772123470511432228, .435866521508458999416019451194};
  const double b[]  = {.187641024346723825161292144158, -.595297473576954948047823027584, .971789927721772123470511432228, .435866521508458999416019451194};
  const double bt[]  = {.187641024346723825161292144140-.36132349168887087099928261975*lim, -1.46846946256021140302557262326*lim-.595297473576954948047823027622, 1.37419900268512763072398740524*lim+.971789927721772123470511432300, .455593951563954643300867837766*lim+.435866521508458999416019451180};

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_SDIRK3(BUTCHER_TABLEAU* tableau) {
  //SDIRK3
  tableau->nStages = 3;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  double gam;

  gam = 1.0/2.0 + sqrt(3.0)/6.0;
  const double c[]  = {gam, (3.0*gam - 2.0)/(6.0*gam - 3.0), 1.0};
  const double A[]  = {
                        gam, 0, 0,
                        (-6*gam*gam+6*gam-2)/(6*gam-3), gam, 0,
                          0, 1-gam, gam};
  const double b[]  = {1.0/(12.0*gam*gam - 12.0*gam + 4.0), 3.0*(2.0*gam - 1.0)*(2.0*gam - 1.0)/(12.0*gam*gam - 12.0*gam + 4.0), 0.0};
  const double bt[]  = {(2.0*sqrt(3.0) + 1.0)/(-3.0 + sqrt(3.0)), 1.0 + 1.0/3.0*sqrt(3.0), (-6.0 - 3.0*sqrt(3.0))/(-9.0 + 3.0*sqrt(3.0))};

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);

}

void getButcherTableau_SDIRK2(BUTCHER_TABLEAU* tableau)
{
  //SDIRK2

  tableau->nStages = 2;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[]   = {0.5, 1.0};
  const double A[]   = {0.5, 0.0,
                        0.5, 0.5};
  const double b[]   = { 0.5,  0.5};
  const double bt[]  = {0.25, 0.75};


  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *)bt);
}

void getButcherTableau_MS(BUTCHER_TABLEAU* tableau)
{
  //ADAMS-MOULTON

  // tableau->nStages = 4;
  // tableau->order_b = 3;
  // tableau->order_bt = 2;
  // tableau->fac = 1.0;

  // /* Butcher Tableau */
  // const double c[]   = {0.0, 0.0, -1.0, 1.0};
  // const double A[]   = {0.0, 0.0, 0.0, 0.0,
  //                       0.0, 0.0, 0.0, 0.0,
  //                       0.0, 0.0, 0.0, 0.0,
  //                       0.0, 0.0, 0.0, 0.0};
  // const double b[]   = { 0.0,  -1./12., 8./12., 5./12.};
  // const double bt[]  = {5./12., -16./12., 23./12., 0.0};

  tableau->nStages = 2;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[]   = {-1.0, 1.0};
  const double A[]   = {0.0, 0.0,
                        0.0, 0.0};
  const double b[]   = {0.5, 0.5};
  const double bt[]  = {1.0, 0.0};

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *)bt);
}

void getButcherTableau_EXPLEULER(BUTCHER_TABLEAU* tableau) {
  //explicit Euler with Richardson-Extrapolation for step size control

  tableau->nStages = 2;
  tableau->order_b = 1;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[] = {0.0, 0.5};
  const double A[] = {0.0, 0.0,
                      0.5, 0.0};
  const double b[]  = {0,1}; // explicit midpoint rule
  const double  bt[] = {1,0}; // explicit Euler step

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_GAUSS2(BUTCHER_TABLEAU* tableau) {
  //implicit Gauss-Legendre with Richardson-Extrapolation for step size control

  tableau->nStages = 2;
  tableau->order_b = 4;
  tableau->order_bt = 1;
  tableau->fac = 1.0;

  const double sqrt3 = sqrt(3);
  const double c1 = 1./2. - sqrt3/6.;
  const double c2 = 1./2. + sqrt3/6.;
  const double a11 = 1./4.;
  const double a12 = 1./4. - sqrt3/6.;
  const double a21 = 1./4. + sqrt3/6.;
  const double a22 = 1./4.;
  const double b1 = 1./2.;
  const double b2 = 1./2.;
  const double bt1 = 1./2. - sqrt3/2.;
  const double bt2 = 1./2. + sqrt3/2.;


  /* Butcher Tableau */
  // const double c[] = {c1, c2, c1/2., c2/2., 1./2. + c1/2., 1./2. + c2/2.};
  // const double A[] = {a11, a12, 0.0, 0.0, 0.0, 0.0,
  //                     a21, a22, 0.0, 0.0, 0.0, 0.0,
  //                     0.0, 0.0, a11, a12, 0.0, 0.0,
  //                     0.0, 0.0, a21, a22, 0.0, 0.0,
  //                     0.0, 0.0, b1/2., b2/2., a11, a12,
  //                     0.0, 0.0, b1/2., b2/2., a21, a22,
  //                     };
  // const double b[]  = {b1, b2, 0.0, 0.0, 0.0, 0.0}; // implicit Gauss-Legendre rule
  // const double  bt[] = {-b1, -b2, 4./7.*b1, 4./7.*b2, 4./7.*b1, 4./7.*b2}; // Richardson-Extrapolation

  const double c[] = {c1, c2};
  const double A[] = {a11, a12,
                      a21, a22
                      };
  const double b[]  = {b1, b2}; // implicit Gauss-Legendre rule
  const double  bt[] = {bt1, bt2}; // Embedded method

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}



void getButcherTableau_IMPLEULER(BUTCHER_TABLEAU* tableau) {
  // Implicit Euler with Richardson-Extrapolation for step size control
  tableau->nStages = 3;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[] = {1.0, 0.5, 1.0};
  const double A[] = {1.0, 0.0, 0.0,
                      0.0, 0.5, 0.0,
                      0.0, 0.5, 0.5};
  const double bt[] = {1.0, 0.0, 0.0}; // implicit Euler step
  const double b[]  = {-1.0, 1.0, 1.0}; // Richardson extrapolation for error estimator

  // /* Butcher Tableau */
  // const double c[] = {0.0, 1.0};
  // const double A[] = {0.0, 0.0,
  //                     0.0, 1.0};
  // const double  b[] = {0.0, 1.0}; // implicit Euler step
  // const double  bt[] = {0.5, 0.5}; // trapezoidal rule for error estimator

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_MERSON(BUTCHER_TABLEAU* tableau) {
  //explicit Merson method
  tableau->nStages = 5;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac = 1.e7;

  /* Butcher Tableau */
  const double c[] = {0.0, 1./3, 1./3, 1./2, 1.0};
  const double A[] = { 0.0,  0.0,   0.0, 0.0, 0.0,
                         1./3,  0.0,   0.0, 0.0, 0.0,
                         1./6, 1./6,   0.0, 0.0, 0.0,
                         1./8,  0.0,  3./8, 0.0, 0.0,
                         1./2,  0.0, -3./2, 2.0, 0.0
                        };
  const double b[] = {1./6, 0.0,   0.0, 2./3, 1./6};   // 4th order???
  // const double bt_EXPLEULER_SC[]  = {1./2, 0.0, -3./2,  2.0,  0.0}; // 3th order???
  const double  bt[]  = {1./10, 0.0, 3./10,  2./5,  1./5}; // 3th order???

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_DOPRI45(BUTCHER_TABLEAU* tableau) {
  //DOPRI45 this is the real one

  tableau->nStages = 7;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1e3;

  /* Butcher Tableau */
  const double c[] = {0.0, 1./5, 3./10, 4./5, 8./9, 1., 1.};
  const double A[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                         1./5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                         3./40, 9./40, 0.0, 0.0, 0.0, 0.0, 0.0,
                         44./45, -56./15, 32./9, 0.0, 0.0, 0.0, 0.0,
                         19372./6561, -25360./2187, 64448./6561, -212./729, 0.0, 0.0, 0.0,
                         9017./3168, -355./33, 46732./5247, 49./176, -5103./18656, 0.0, 0.0,
                         35./384, 0.0, 500./1113, 125./192, -2187./6784, 11./84, 0.0
                        };
  const double b[] = {35./384, 0.0, 500./1113, 125./192, -2187./6784, 11./84, 0.0};
  const double  bt[] = {5179./57600, 0.0, 7571./16695, 393./640, -92097./339200, 187./2100, 1./40};

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_FEHLBERG54(BUTCHER_TABLEAU* tableau) {
  //Fehlberg45

  tableau->nStages = 6;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1e3;

  /* Butcher Tableau */
  const double c[]  = {                              0,                            0.25,                           0.375, 0.923076923076923076923076923077,                               1,                             0.5};
  const double A[]  = {
                                                       0,                                0,                                0,                                 0,                                0,                                0,
                                                    0.25,                                0,                                0,                                 0,                                0,                                0,
                                                 0.09375,                          0.28125,                                0,                                 0,                                0,                                0,
                          0.87938097405553026854802002731, -3.27719617660446062812926718252,  3.32089212562585343650432407829,                                0,                                0,                                0,
                          2.03240740740740740740740740741,                               -8,  7.17348927875243664717348927875, -0.20589668615984405458089668616,                                0,                                0,
                        -0.296296296296296296296296296296,                                2, -1.38167641325536062378167641326, 0.452972709551656920077972709552,                             -0.275,                              0};
  const double b[]   = {0.121296296296296296296296296296, -0.0304761904761904761904761904762, 0.578869395711500974658869395712, 0.516977165135059871901977165135, -0.186666666666666666666666666667,                               0};
  const double bt[]  = {0.115740740740740740740740740741,                               0, 0.548927875243664717348927875244,    0.535331384015594541910331384016,                              -0.2,                               0};

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_FEHLBERG87(BUTCHER_TABLEAU* tableau) {
  //Fehlberg45

  tableau->nStages = 13;
  tableau->order_b = 8;
  tableau->order_bt = 7;
  tableau->fac = 1e3;

  /* Butcher Tableau */
const double c[]  = {                              0, 0.0740740740740740740740740740741, 0.111111111111111111111111111111, 0.166666666666666666666666666667, 0.416666666666666666666666666667,                             0.5, 0.833333333333333333333333333333, 0.166666666666666666666666666667, 0.666666666666666666666666666667, 0.333333333333333333333333333333,                               1,                               0,                               1};
const double A[]  = {
                                                       0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                        0.0740740740740740740740740740741,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                        0.0277777777777777777777777777778, 0.0833333333333333333333333333333,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                        0.0416666666666666666666666666667,                                0,                            0.125,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                        0.416666666666666666666666666667,                                0,                          -1.5625,                           1.5625,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                                                    0.05,                                0,                                0,                             0.25,                              0.2,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                        -0.231481481481481481481481481481,                                0,                                0,  1.15740740740740740740740740741, -2.40740740740740740740740740741,  2.31481481481481481481481481481,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                        0.103333333333333333333333333333,                                0,                                0,                                0, 0.271111111111111111111111111111, -0.222222222222222222222222222222, 0.0144444444444444444444444444444,                                0,                                0,                                0,                                0,                                0,                                0,
                                                       2,                                0,                                0, -8.83333333333333333333333333333,  15.6444444444444444444444444444, -11.8888888888888888888888888889, 0.744444444444444444444444444444,                                3,                                0,                                0,                                0,                                0,                                0,
                        -0.842592592592592592592592592593,                                0,                                0, 0.212962962962962962962962962963, -7.22962962962962962962962962963,  5.75925925925925925925925925926, -0.316666666666666666666666666667,  2.83333333333333333333333333333, -0.0833333333333333333333333333333,                                0,                                0,                                0,                                0,
                        0.581219512195121951219512195122,                                0,                                0, -2.07926829268292682926829268293,  4.38634146341463414634146341463, -3.67073170731707317073170731707, 0.520243902439024390243902439024, 0.548780487804878048780487804878, 0.274390243902439024390243902439, 0.439024390243902439024390243902,                                0,                                0,                                0,
                        0.0146341463414634146341463414634,                                0,                                0,                                0,                                0, -0.146341463414634146341463414634, -0.0146341463414634146341463414634, -0.0731707317073170731707317073171, 0.0731707317073170731707317073171, 0.146341463414634146341463414634,                                0,                                0,                                0,
                        -0.433414634146341463414634146341,                                0,                                0, -2.07926829268292682926829268293,  4.38634146341463414634146341463, -3.52439024390243902439024390244, 0.534878048780487804878048780488, 0.621951219512195121951219512195, 0.201219512195121951219512195122, 0.292682926829268292682926829268,                                0,                                1,                                0};
const double b[]  = {                              0,                               0,                               0,                               0,                               0, 0.32380952380952380952380952381, 0.257142857142857142857142857143, 0.257142857142857142857142857143, 0.0321428571428571428571428571429, 0.0321428571428571428571428571429,                               0, 0.0488095238095238095238095238095, 0.0488095238095238095238095238095};
const double bt[]  = {0.0488095238095238095238095238095,                               0,                               0,                               0,                               0, 0.32380952380952380952380952381, 0.257142857142857142857142857143, 0.257142857142857142857142857143, 0.0321428571428571428571428571429, 0.0321428571428571428571428571429, 0.0488095238095238095238095238095,                               0,                               0};


  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

/**
 * @brief Analyse Butcher tableau and return size and if the method is explicit.
 *
 * Sets error_order
 *
 * @param tableau       Butcher tableau. error_order will be set after return.
 * @param nStates       Number of states of ODE/DAE system.
 * @param nlSystemSize  Contains size of internal non-linear system on return.
 * @param rk_type        Contains Runge-Kutta method type on return.
 */
void analyseButcherTableau(BUTCHER_TABLEAU* tableau, int nStates, unsigned int* nlSystemSize, enum RK_type* rk_type) {
  modelica_boolean isGenericIRK = FALSE;  /* generic implicit Runge-Kutta method */
  modelica_boolean isDIRK = FALSE;        /* diagonal something something Runge-Kutta method */
  int i, j, l;

  for (i=0; i<tableau->nStages; i++) {
    /* Check if values on diagonal are non-zero (= dirk method) */
    if (fabs(tableau->A[i*tableau->nStages + i])>0) {    // TODO: This assumes that A is saved in row major format
      isDIRK = TRUE;
    }
    /* Check if values above diagonal are non-zero (= implicit method) */
    for (j=i+1; j<tableau->nStages; j++) {
      if (fabs(tableau->A[i * tableau->nStages + j])>0) {    // TODO: This assumes that A is saved in row major format
        isGenericIRK = TRUE;
      }
    }
  }
  if (isGenericIRK) {
    *rk_type = RK_TYPE_IMPLICIT;
    *nlSystemSize = tableau->nStages*nStates;
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method is fully implicit");
  } else if (isDIRK) {
    *rk_type = RK_TYPE_DIRK;
    *nlSystemSize = nStates;
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method diagonally implicit");
  } else {
    *rk_type = RK_TYPE_EXPLICIT;
    *nlSystemSize = 0;
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method is explicit");
  }

  // set order for error control!
  tableau->error_order = fmin(tableau->order_b, tableau->order_bt) + 1;
}

/**
 * @brief Allocate memory and initialize Butcher tableau for given method.
 *
 * @param RK_method           Runge-Kutta method.
 * @return BUTCHER_TABLEAU*   Return pointer to Butcher tableau on success, NULL on failure.
 */
BUTCHER_TABLEAU* initButcherTableau(enum RK_SINGLERATE_METHOD RK_method) {
  BUTCHER_TABLEAU* tableau = (BUTCHER_TABLEAU*) malloc(sizeof(BUTCHER_TABLEAU));

  switch(RK_method)
  {
    case MS_ADAMS_MOULTON:
      getButcherTableau_MS(tableau);
      break;
    case RK_DOPRI45:
      getButcherTableau_DOPRI45(tableau);
      break;
    case RK_MERSON:
      //getButcherTableau_MERSON(tableau);
      //getButcherTableau_FEHLBERG54(tableau);
      getButcherTableau_FEHLBERG87(tableau);
      break;
    case RK_SDIRK2:
      getButcherTableau_SDIRK2(tableau);
      break;
    case RK_SDIRK3:
      getButcherTableau_SDIRK3(tableau);
      break;
    case RK_ESDIRK2:
      getButcherTableau_ESDIRK2(tableau);
      break;
    case RK_ESDIRK2_test:
      getButcherTableau_ESDIRK2(tableau);
      // //ESDIRK2 not optimized (just for testing) solved with genericRK solver method
      // getButcherTableau_ESDIRK2(userdata);
      break;
    case RK_EXPL_EULER:
      getButcherTableau_EXPLEULER(tableau);
      break;
    case RK_IMPL_EULER:
      getButcherTableau_IMPLEULER(tableau);
      break;
    case RK_ESDIRK3_test:
      //ESDIRK3 not optimized (just for testing) solved with genericRK solver method
      getButcherTableau_ESDIRK3(tableau);
      break;
    case RK_ESDIRK3:
      getButcherTableau_ESDIRK3(tableau);
      break;
    case RK_GAUSS2:
      getButcherTableau_GAUSS2(tableau);
      break;
    default:
      errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow Runge Kutta method %i.", RK_method);
      free(tableau);
      return NULL;
  }

  return tableau;
}

/**
 * @brief Free Butcher Tableau memory.
 *
 * @param tableau   Butcher tableau.
 */
void freeButcherTableau(BUTCHER_TABLEAU* tableau) {
  free(tableau->c);
  free(tableau->A);
  free(tableau->b);
  free(tableau->bt);

  free(tableau);
  tableau = NULL;
}

/**
 * @brief Print given Butcher tableau
 *
 * @param tableau   Butcher tableau.
 */
void printButcherTableau(BUTCHER_TABLEAU* tableau) {
  int i, j;
  char Butcher_row[1024];
  infoStreamPrint(LOG_SOLVER, 1, "Butcher tableau of RK-method:");
  for (i = 0; i<tableau->nStages; i++) {
    // TODO AHeu: Use snprintf instead of sprintf
    sprintf(Butcher_row, "%10g | ", tableau->c[i]);
    for (j = 0; j<tableau->nStages; j++) {
      sprintf(Butcher_row, "%s %10g", Butcher_row, tableau->A[i*tableau->nStages + j]);
    }
    infoStreamPrint(LOG_SOLVER, 0, "%s", Butcher_row);
  }
  infoStreamPrint(LOG_SOLVER, 0, "------------------------------------------------");
  sprintf(Butcher_row, "%10s | ", "");
  for (j = 0; j<tableau->nStages; j++) {
    sprintf(Butcher_row, "%s %10g", Butcher_row, tableau->b[j]);
  }
  infoStreamPrint(LOG_SOLVER, 0, "%s",Butcher_row);
  sprintf(Butcher_row, "%10s | ", "");
  for (j = 0; j<tableau->nStages; j++) {
    sprintf(Butcher_row, "%s %10g", Butcher_row, tableau->bt[j]);
  }
  infoStreamPrint(LOG_SOLVER, 0, "%s",Butcher_row);
  messageClose(LOG_SOLVER);
}
