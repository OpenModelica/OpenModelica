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
  const char* flag_value = omc_flagValue[FLAG_RK_PAR];
  double lim;

  // ESDIRK2 method
  if (flag_value != NULL) {
    lim = atof(omc_flagValue[FLAG_RK_PAR]);
    //printf("embedded method yields R(\u221e) =  %.19g\n", lim);
  } else
  {
    lim = 0.7;
  }
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
  const char* flag_value = omc_flagValue[FLAG_RK_PAR];
  double lim;

  // ESDIRK2 method
  if (flag_value != NULL) {
    lim = atof(omc_flagValue[FLAG_RK_PAR]);
    //printf("embedded method yields R(\u221e) =  %.19g\n", lim);
  } else
  {
    lim = 0.3;
  }

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

  const char* flag_value = omc_flagValue[FLAG_RK_PAR];
  double gam;

  gam = 1.0/2.0 + sqrt(3.0)/6.0;
  const double c[]  = {gam, (3.0*gam - 2.0)/(6.0*gam - 3.0), 1.0};
  const double A[]  = {
                        gam, 0, 0,
                        (-6*gam*gam+6*gam-2)/(6*gam-3), gam, 0,
                          0, 1-gam, gam};
  const double b[]  = {1.0/(12.0*gam*gam - 12.0*gam + 4.0), 3.0*(2.0*gam - 1.0)*(2.0*gam - 1.0)/(12.0*gam*gam - 12.0*gam + 4.0), 0.0};
  const double bt[]  = {(2.0*sqrt(3.0) + 1.0)/(-3.0 + sqrt(3.0)), 1.0 + 1.0/3.0*sqrt(3.0), (-6.0 - 3.0*sqrt(3.0))/(-9.0 + 3.0*sqrt(3.0))};
  // ESDIRK2 method
  if (flag_value != NULL) {
    gam = 1.0/2.0 - sqrt(3.0)/6.0;
    const double c1[]  = {gam, (3.0*gam - 2.0)/(6.0*gam - 3.0), 1.0};
    const double A1[]  = {
                          gam, 0, 0,
                          (-6*gam*gam+6*gam-2)/(6*gam-3), gam, 0,
                           0, 1-gam, gam};
    const double b1[]  = {1.0/(12.0*gam*gam - 12.0*gam + 4.0), 3.0*(2.0*gam - 1.0)*(2.0*gam - 1.0)/(12.0*gam*gam - 12.0*gam + 4.0), 0.0};
    const double bt1[]  = {(2.0*sqrt(3.0) - 1.0)/(sqrt(3.0) + 3.0), 1.0 - 1.0/3.0*sqrt(3.0), sqrt(3.0)*(2*sqrt(3.0) - 3.0)/(3.0*sqrt(3.0) + 9.0)};
    setButcherTableau(tableau, (double *)c1, (double *)A1, (double *)b1, (double *) bt1);

    printf("Main routine is not A-stable\n");
  } else
    setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);


//   //double gam = 4./5;
//   //double c2 = (6*gam*gam - 9*gam + 2)/(3*(2*gam*gam - 4*gam + 1));
//   //double b1 = (4*gam - 1)/(4*(3*gam*gam*gam - 9*gam*gam + 6*gam - 1));
//   //double b2 = 1 - b1 - gam;

//   //const double c[]  = {gam, c2, 1};

//   //const double A[]  = {gam,      0,   0,
//   //                        c2-gam, gam,   0,
//   //                        b1, b2,  gam};

//   //const double b[]  = {b1, b2, gam};
//   // const double bt[] = {-2741./4876, 6399./5300, 204./575};  gam = 4/5, lim = -2/5
//   //const double bt[] = {-9909./4876 , 9471./5300, 716./575}; //  gam = 4/5, lim = 2/5
//   // const double bt[] = {3./37, 34./37, 0.0}; gam = 5/6, lim = -17/25
//   // const double bt[] = {105./629, 33./37, -1./17}; gam = 5/6, lim = -91/125
//   // Stability of the embedded RK method is larger than the main RK method
//   /* Butcher Tableau */
//   const double c[]  = {0.211324865405187117745425609748, 0.5, 1.};

//   const double A[]  = {0.211324865405187117745425609748,0.,0.,
//                        0.288675134594812882254574390252, 0.211324865405187117745425609748, 0.,
//                        0.366025403784438646763723170761, 0.422649730810374235490851219493, 0.211324865405187117745425609748};

//   const double b[]  = {0.366025403784438646763723170761, 0.422649730810374235490851219493, 0.211324865405187117745425609748};
//   // //const double bt[] = {0.351869322027954749581941158535, 0.444978830179634461030230691032, 0.203151847792410789387828150409};
//   // //const double bt[] = {0.337713240271470852400159146338, 0.589316397477040902157517889986, 0.0729703622514882454423229451520};
//   const double bt[] = {0.337713240271470852400159146338, 0.101282525764456039805887004958, 0.561004233964073107793953837265};

// // const double c[]  = {         0.21132486540518711774,                             0.5,                               1};
// // const double A[]  = {
// //                                   0.21132486540518711774,                                0,                                0,
// //                                   0.28867513459481288226,           0.21132486540518711774,                                0,
// //                                    0.3660254037844386468,           0.42264973081037423546,           0.21132486540518711774};
// // const double b[]  = {          0.3660254037844386468,          0.42264973081037423546,          0.21132486540518711774};
// // const double bt[]  = {          0.4226497308103742353,          0.33333333333333333351,          0.24401693585629243119};


//  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_SDIRK2(BUTCHER_TABLEAU* tableau)
{
  //SDIRK3

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
  tableau->order_b = 1;
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
  //DOPRI45

  tableau->nStages = 7;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1e7;

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
      getButcherTableau_MERSON(tableau);
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
