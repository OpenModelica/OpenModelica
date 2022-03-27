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

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

void setButcherTableau(BUTCHER_TABLEAU* tableau, double *c, double *A, double *b, double * bt) {
  tableau->c = malloc(sizeof(double)*tableau->stages);
  tableau->A = malloc(sizeof(double)*tableau->stages * tableau->stages);
  tableau->b = malloc(sizeof(double)*tableau->stages);
  tableau->bt = malloc(sizeof(double)*tableau->stages);

  memcpy(tableau->c, c, tableau->stages*sizeof(double));
  memcpy(tableau->A, A, tableau->stages * tableau->stages * sizeof(double));
  memcpy(tableau->b, b, tableau->stages*sizeof(double));
  memcpy(tableau->bt, bt, tableau->stages*sizeof(double));
}

void getButcherTableau_ESDIRK2(BUTCHER_TABLEAU* tableau) {
  // ESDIRK2 method
  tableau->stages = 3;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 0.9;

  /* initialize values of the Butcher tableau */
  double gam = (2.0-sqrt(2.0))*0.5;
  double c2 = 2.0*gam;
  double b1 = sqrt(2.0)/4.0;
  double b2 = b1;
  double b3 = gam;
  double bt1 = 1.75-sqrt(2.0);
  double bt2 = bt1;
  double bt3 = 2.0*sqrt(2.0)-2.5;

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
  //ESDIRK3
  tableau->stages = 4;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 0.9;

//   double gam=0.43586652150845899941601945;
//   double c3=3./5;
//   double a32=(c3*(c3-2*gam))/(4*gam);
//   double a31=c3-a32-gam;
//   double A=1-6*gam+6*gam*gam;
//   double b2=(-2+3*c3+6*gam*(1-c3))/(12*gam*(c3-2*gam));
//   double b3=A/(3*c3*(c3-2*gam));
//   double b4=gam;

//   double b1=1-b2-b3-b4;
//   double bt2=((c3*(-1+6*gam-24*gam*gam*gam+12*gam*gam*gam*gam-6*gam*gam*gam*gam*gam))/(4*gam*(2*gam-c3)*A)+
//                 (3-27*gam+68*gam*gam-55*gam*gam*gam+21*gam*gam*gam*gam-6*gam*gam*gam*gam*gam)/(2*(2*gam-c3)*A));
//   double bt3=((-gam*(-2+21*gam-68*gam*gam+79*gam*gam*gam-33*gam*gam*gam*gam+12*gam*gam*gam*gam*gam))/(c3*(c3-2*gam)*A));
//   double bt4=(-3*gam*gam*(-1+4*gam-2*gam*gam+gam*gam*gam))/A;
//   double bt1=1-bt2-bt3-bt4;

//   const double c_ESDIRK3[] = {0.0, 2*gam, c3, 1};
//   const double A_ESDIRK3[] = {0.0, 0.0, 0.0, 0.0,
//                               gam, gam, 0.0, 0.0,
//                               a31, a32, gam, 0.0,
//                               b1,  b2,  b3, gam
//  };
//   const double b_ESDIRK3[] = {b1, b2, b3, b4};
//   const double bt_ESDIRK3[] = {bt1, bt2, bt3, bt4};

  /* Butcher Tableau */
  const double c[]  = {0.0, 0.87173304301691799883203890238711368505858818587690, 3./5, 1.};

  const double A[]  = {0, 0, 0, 0,
                          0.43586652150845899941601945119355684252929409293845, 0.43586652150845899941601945119355684252929409293845, 0.0, 0.0,
                          0.25764824606642724579999601628407970926431835216613, -0.093514767574886245216015467477636551793612445104585, 0.43586652150845899941601945119355684252929409293845, 0.0,
                          0.18764102434672382516129214416680439137952555421072, -0.59529747357695494804782302758588517377818522805180, 0.97178992772177212347051143222552393986936558090263, 0.43586652150845899941601945119355684252929409293845};

  const double b[]  = {0.18764102434672382516129214416680439137952555421072, -0.59529747357695494804782302758588517377818522805180, 0.97178992772177212347051143222552393986936558090263, 0.43586652150845899941601945119355684252929409293845};
  const double  bt[] = {0.10889661761586445415613073807049608218243112728445, -0.91532581187071275348163809781681834549906345402560, 1.2712735973021521678447158941356428765353629368204, 0.53515559695269613148079146561067938678126938992075};

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_SDIRK3(BUTCHER_TABLEAU* tableau) {
  //SDIRK3
  tableau->stages = 3;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 0.9;

  //double gam = 4./5;
  //double c2 = (6*gam*gam - 9*gam + 2)/(3*(2*gam*gam - 4*gam + 1));
  //double b1 = (4*gam - 1)/(4*(3*gam*gam*gam - 9*gam*gam + 6*gam - 1));
  //double b2 = 1 - b1 - gam;

  //const double c[]  = {gam, c2, 1};

  //const double A[]  = {gam,      0,   0,
  //                        c2-gam, gam,   0,
  //                        b1, b2,  gam};

  //const double b[]  = {b1, b2, gam};
  // const double bt[] = {-2741./4876, 6399./5300, 204./575};  gam = 4/5, lim = -2/5
  //const double bt[] = {-9909./4876 , 9471./5300, 716./575}; //  gam = 4/5, lim = 2/5
  // const double bt[] = {3./37, 34./37, 0.0}; gam = 5/6, lim = -17/25
  // const double bt[] = {105./629, 33./37, -1./17}; gam = 5/6, lim = -91/125
  // Stability of the embedded RK method is larger than the main RK method
  /* Butcher Tableau */
  const double c[]  = {0.211324865405187117745425609748, 0.5, 1.};

  const double A[]  = {0.211324865405187117745425609748,0.,0.,
                          0.288675134594812882254574390252, 0.211324865405187117745425609748, 0.,
                          0.366025403784438646763723170761, 0.422649730810374235490851219493, 0.211324865405187117745425609748};

  const double b[]  = {0.366025403784438646763723170761, 0.422649730810374235490851219493, 0.211324865405187117745425609748};
  // //const double bt[] = {0.351869322027954749581941158535, 0.444978830179634461030230691032, 0.203151847792410789387828150409};
  // //const double bt[] = {0.337713240271470852400159146338, 0.589316397477040902157517889986, 0.0729703622514882454423229451520};
  const double bt[] = {0.337713240271470852400159146338, 0.101282525764456039805887004958, 0.561004233964073107793953837265};

// const double c[]  = {         0.21132486540518711774,                             0.5,                               1};
// const double A[]  = {
//                                   0.21132486540518711774,                                0,                                0,
//                                   0.28867513459481288226,           0.21132486540518711774,                                0,
//                                    0.3660254037844386468,           0.42264973081037423546,           0.21132486540518711774};
// const double b[]  = {          0.3660254037844386468,          0.42264973081037423546,          0.21132486540518711774};
// const double bt[]  = {          0.4226497308103742353,          0.33333333333333333351,          0.24401693585629243119};


  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_SDIRK2(BUTCHER_TABLEAU* tableau)
{
  //SDIRK3

  tableau->stages = 2;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 0.9;

  /* Butcher Tableau */
  const double c[]  = {                            0.5,                               1};
  const double A[]  = {
                                                      0.5,                                0,
                                                      0.5,                              0.5};
  const double b[]  = {                            0.5,                             0.5};
  const double bt[]  = {                           0.25,                            0.75};


  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *)bt);
}

void getButcherTableau_EXPLEULER(BUTCHER_TABLEAU* tableau) {
  //explicit Euler with Richardson-Extrapolation for step size control

  tableau->stages = 2;
  tableau->order_b = 1;
  tableau->order_bt = 2;
  tableau->fac = 0.9;

  /* Butcher Tableau */
  const double c[] = {0.0, 0.5};
  const double A[] = {0.0, 0.0,
                                   0.5, 0.0};
  const double b[]  = {0,1}; // explicit midpoint rule
  const double  bt[] = {1,0}; // explicit Euler step

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_IMPLEULER(BUTCHER_TABLEAU* tableau) {
  //explicit Euler with Richardson-Extrapolation for step size control
  tableau->stages = 3;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 0.9;

  /* Butcher Tableau */
  const double c[] = {1.0, 0.5, 1.0};
  const double A[] = {1.0, 0.0, 0.0,
                         0.0, 0.5, 0.0,
                         0.0, 0.5, 0.5};
  const double  bt[] = {1.0, 0.0, 0.0}; // implicit Euler step
  //const double  bt[] = {0.0, 0.5, 0.5}; // implicit Euler step, with half step size
  const double b[] = {-1.0, 1.0, 1.0}; // Richardson extrapolation

  setButcherTableau(tableau, (double *)c, (double *)A, (double *)b, (double *) bt);
}

void getButcherTableau_MERSON(BUTCHER_TABLEAU* tableau) {
  //explicit Merson method
  tableau->stages = 5;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac = 0.9;

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

  tableau->stages = 7;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 0.5;

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

void analyseButcherTableau(BUTCHER_TABLEAU* tableau, int nStates, unsigned int* nlSystemSize, enum RK_type* expl) {
  modelica_boolean isGenericIRK = FALSE;  /* generic implicit Runge-Kutta method */
  modelica_boolean isDIRK = FALSE;        /* diagonal something something Runge-Kutta method */
  int i, j, l;

  for (i=0; i<tableau->stages; i++) {
    /* Check if values on diagonal are non-zero (= dirk method) */
    if (fabs(tableau->A[i*tableau->stages + i])>0) {    // TODO: This assumes that A is saved in row major format
      isDIRK = TRUE;
    }
    /* Check if values above diagonal are non-zero (= implicit method) */
    for (j=i+1; j<tableau->stages; j++) {
      if (fabs(tableau->A[i * tableau->stages + j])>0) {    // TODO: This assumes that A is saved in row major format
        isGenericIRK = TRUE;
      }
    }
  }
  if (isGenericIRK) {
    *expl = RK_TYPE_IMPLICIT;
    *nlSystemSize = tableau->stages*nStates;
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method is fully implicit");
  } else if (isDIRK) {
    *expl = RK_TYPE_DIRK;
    *nlSystemSize = nStates;
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method diagonally implicit");
  } else {
    *expl = RK_TYPE_EXPLICIT;
    *nlSystemSize = nStates;
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method is explicit");
  }
  // set order for error control!
  tableau->error_order = fmin(tableau->order_b, tableau->order_bt) + 1;
}

BUTCHER_TABLEAU* initButcherTableau(enum RK_SINGLERATE_METHOD RK_method) {
  BUTCHER_TABLEAU* tableau = (BUTCHER_TABLEAU*) malloc(sizeof(BUTCHER_TABLEAU));

  switch(RK_method)
  {
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
    default:
      errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow Runge Kutta method %i.", RK_method);
      free(tableau);
      return NULL;
  }

  return tableau;
}

void freeButcherTableau(BUTCHER_TABLEAU* tableau) {
  free(tableau->c);
  free(tableau->A);
  free(tableau->b);
  free(tableau->bt);

  free(tableau);
  tableau = NULL;
}

void printButcherTableau(BUTCHER_TABLEAU* tableau) {
  int i, j;
  char Butcher_row[1024];
  infoStreamPrint(LOG_SOLVER, 1, "Butcher tableau of RK-method:");
  for (i = 0; i<tableau->stages; i++) {
    // TODO AHeu: Use snprintf instead of sprintf
    sprintf(Butcher_row, "%10g | ", tableau->c[i]);
    for (j = 0; j<tableau->stages; j++) {
      sprintf(Butcher_row, "%s %10g", Butcher_row, tableau->A[i*tableau->stages + j]);
    }
    infoStreamPrint(LOG_SOLVER, 0, "%s", Butcher_row);
  }
  infoStreamPrint(LOG_SOLVER, 0, "------------------------------------------------");
  sprintf(Butcher_row, "%10s | ", "");
  for (j = 0; j<tableau->stages; j++) {
    sprintf(Butcher_row, "%s %10g", Butcher_row, tableau->b[j]);
  }
  infoStreamPrint(LOG_SOLVER, 0, "%s",Butcher_row);
  sprintf(Butcher_row, "%10s | ", "");
  for (j = 0; j<tableau->stages; j++) {
    sprintf(Butcher_row, "%s %10g", Butcher_row, tableau->bt[j]);
  }
  infoStreamPrint(LOG_SOLVER, 0, "%s",Butcher_row);
  messageClose(LOG_SOLVER);
}
