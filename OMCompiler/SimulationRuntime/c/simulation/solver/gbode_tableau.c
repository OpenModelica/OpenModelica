/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Open Source Modelica Consortium (OSMC),
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

/*! \file gbode_tableau.c
 *
 * Containing Butcher tableau for generic Runge-Kutta methods.
 */

#include "gbode_tableau.h"
#include "gbode_conf.h"

#include <string.h>

#include "util/omc_error.h"
#include "omc_math.h"
#include "util/simulation_options.h"
#include "simulation/options.h"

/**
 * @brief Set Butcher tableau
 *
 * @param tableau     Pointer to tableau to set.
 * @param c           Vector c.
 * @param A           Matrix A.
 * @param b           Vector b.
 * @param bt          Vector b transposed. Can be NULL.
 */
void setButcherTableau(BUTCHER_TABLEAU* tableau, const double *c, const double *A, const double *b, const double *bt)
{
  assertStreamPrint(NULL, c != NULL, "setButcherTableau: c is NULL");
  assertStreamPrint(NULL, A != NULL, "setButcherTableau: A is NULL");
  assertStreamPrint(NULL, b != NULL, "setButcherTableau: b is NULL");

  const size_t n = sizeof(double) * tableau->nStages;
  const size_t nn = n * tableau->nStages;

  tableau->c = malloc(n);
  tableau->A = malloc(nn);
  tableau->b = malloc(n);
  if (bt != NULL) {
    tableau->bt = malloc(n);
  } else {
    tableau->bt = NULL;
  }
  tableau->b_dt = malloc(n);

  memcpy(tableau->c, c, n);
  memcpy(tableau->A, A, nn);
  memcpy(tableau->b, b, n);
  if (bt != NULL) {
    memcpy(tableau->bt, bt, n);
  }

  tableau->withDenseOutput = FALSE;
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void denseOutput(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  int i, j;

  if (idx == NULL) {
    // TODO memory layout may be bad, better to iterate over j on the outside?
    for (i=0; i<nStates; i++) {
      y[i] = yOld[i];
      for (j = 0; j<tableau->nStages; j++) {
        y[i] += dt * stepSize * tableau->b_dt[j] * k[j * nStates + i];
      }
    }
  } else {
    for (int ii=0; ii<nIdx; ii++) {
      i = idx[ii];
      y[i] = yOld[i];
      for (j = 0; j<tableau->nStages; j++) {
        y[i] += dt * stepSize * tableau->b_dt[j] * k[j * nStates + i];
      }
    }
  }
}

// TODO: Describe me
void denseOutput_ESDIRK2(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (-0.353553390593273762200422174434 * dt + 0.707106781186547524400844364376);
  tableau->b_dt[1] = (-0.353553390593273762200422174434 * dt + 0.707106781186547524400844364376);
  tableau->b_dt[2] = (0.707106781186547524400844364376 * dt - 0.414213562373095048801688728752);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_ESDIRK2(BUTCHER_TABLEAU* tableau)
{
  /* initialize values of the Butcher tableau */
  const double gam = (2.0-sqrt(2.0))*0.5;
  const double c2 = 2.0*gam;
  const double b1 = sqrt(2.0)/4.0;
  const double b2 = b1;
  const double b3 = gam;
  const double bt1 = 1.0/3.0-(sqrt(2.0))/12.0;
  const double bt2 = 1.0/3.0+(sqrt(2.0))/4.0;
  const double bt3 = -(sqrt(2.0))/6.0+1.0/3.0;

  tableau->nStages = 3;
  tableau->order_b = 2;
  tableau->order_bt = 3;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[] = {0.0, c2, 1.0};
  const double A[] = {0.0, 0.0, 0.0,
                      gam, gam, 0.0,
                      b1, b2, b3};
  const double b[] = {b1, b2, b3};
  const double bt[] = {bt1, bt2, bt3};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_ESDIRK2;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void denseOutput_ESDIRK3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (( 0.72725113948167801576010183297 * dt -  1.64214330331007985668149581856) * dt +  1.10253318817512566608268612912);
  tableau->b_dt[1] = (( 2.95565086274697614850386507333 * dt -  5.31600425191699734895990708092) * dt +  1.76505591559306625240821895982);
  tableau->b_dt[2] = ((-2.76590870387663402359101154815 * dt +  4.56002748003149592371151163314) * dt - 0.822328848433089776649988630911);
  tableau->b_dt[3] = ((-0.916993298352020140672955364224 * dt +  2.39812007519558128192989126681) * dt -  1.04526025533510214184091644271);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// TODO: Describe me
void getButcherTableau_ESDIRK3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  const double c[] = {                              0, 0.871733043016917998832038902387,                             0.6,                               1};
  const double A[] = {
                                                        0,                                0,                                0,                                0,
                          0.435866521508458999416019451194, 0.435866521508458999416019451194,                                0,                                0,
                          0.257648246066427245799996016284, -0.0935147675748862452160154674776, 0.435866521508458999416019451194,                                0,
                          0.187641024346723825161292144167, -0.595297473576954948047823027586, 0.971789927721772123470511432226, 0.435866521508458999416019451194};
  const double b[] = {0.187641024346723825161292144167, -0.595297473576954948047823027586, 0.971789927721772123470511432226, 0.435866521508458999416019451194};
  const double bt[] = {0.10889661761586445415613073807, -0.915325811870712753481638097817, 1.27127359730215216784471589414, 0.535155596952696131480791465611};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_ESDIRK3;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void denseOutput_TSIT5(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((           -1.0530884977290216 * dt +   2.913255461821912743750681) * dt    -2.763706197274825911336736) * dt + 1;
  tableau->b_dt[1] = ((                        0.1017 * dt        -0.22339999999999999818) * dt +       0.13169999999999999727) * dt;
  tableau->b_dt[2] = ((          2.490627285651252793 * dt    -5.941033872131504734702492) * dt +   3.930296236894751528506874) * dt;
  tableau->b_dt[3] = ((         -16.54810288924490272 * dt +   30.33818863028232159817299) * dt    -12.41107716693367698373438) * dt;
  tableau->b_dt[4] = ((          47.37952196281928122 * dt    -88.17890489476640110142767) * dt +   37.50931341651103919496904) * dt;
  tableau->b_dt[5] = ((         -34.87065786149660974 * dt +   65.09189467479367152629022) * dt    -27.89652628919728780594826) * dt;
  tableau->b_dt[6] = ((                           2.5 * dt                             -4) * dt +                          1.5) * dt;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// TODO: Describe me
void getButcherTableau_TSIT5(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1.0;

  const double c[] = {                              0,                           0.161,                           0.327,                             0.9, 0.980025540904509685729810286287,                               1,                               1};
  const double A[] = {
                                                        0,                                0,                                0,                                0,                                0,                                0,                                0,
                                                    0.161,                                0,                                0,                                0,                                0,                                0,                                0,
                          -0.00848065549235698854442687425023,  0.33548065549235698854442687425,                                0,                                0,                                0,                                0,                                0,
                          2.89715305710549343213043259419, -6.35944848997507484314815991238,  4.36229543286958141101772731819,                                0,                                0,                                0,                                0,
                          5.32586482843925660442887792084, -11.7488835640628278777471703398,  7.49553934288983620830460478456, -0.0924950663617552492565020793321,                                0,                                0,                                0,
                          5.86145544294642002865925148698, -12.9209693178471092917061186818,  8.15936789857615864318040079454, -0.0715849732814009972245305425258, -0.0282690503940683829090030572127,                                0,                                0,
                          0.0964607668180652295181673131651,                             0.01, 0.479889650414499574775249532291,  1.37900857410374189319227482186, -3.29006951543608067990104758571,   2.3247105240997739824153559184,                                0};
  const double b[] = {0.0964607668180652295181673131651,                            0.01, 0.479889650414499574775249532291, 1.37900857410374189319227482186, -3.29006951543608067990104758571,  2.3247105240997739824153559184,                               0};
  const double bt[] = {0.0982407778702910009615458637727, 0.0108164344596567469032236360634, 0.472008772404237578764934804618, 1.52371958127700480072943996983, -3.87242668088863590492098519636, 2.78279263002896092907699243723, -0.0151515151515151515151515151515};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_TSIT5;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void denseOutput_ESDIRK4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (((-1.814633935531616 * dt +  4.618832897422703) * dt -  3.778176353214843) * dt + 0.9583897562880389);
  tableau->b_dt[1] = (((-1.814633935531616 * dt +  4.618832897422703) * dt -  3.778176353214843) * dt + 0.9583897562880389);
  tableau->b_dt[2] = ((( 2.714470299415405 * dt -  6.218774114213813) * dt +  3.906479659268208) * dt - 0.01451817355659667);
  tableau->b_dt[3] = ((( 1.971766118125971 * dt -  6.260604445464527) * dt +  6.104137916978977) * dt -  1.313526970068258);
  tableau->b_dt[4] = ((( 8.360167968264329 * dt -  18.18832628590062) * dt +  11.40440368742219) * dt -  1.684500390199829);
  tableau->b_dt[5] = (((-9.417136514742473 * dt +  21.43003905073355) * dt -  13.85866855723969) * dt +  2.095766021248606);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// TODO: Describe me
void getButcherTableau_ESDIRK4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 6;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac      = 1.0;

  const double c[] = {                                         0,                                        0.5, 0.1464466094067262377995778189475754803576,                                      0.625,                                       1.04,                                          1};
  const double A[] = {
                                                                  0,                                          0,                                          0,                                          0,                                          0,                                          0,
                                                                0.25,                                       0.25,                                          0,                                          0,                                          0,                                          0,
                          -0.05177669529663688110021109052621225982121, -0.05177669529663688110021109052621225982121,                                       0.25,                                          0,                                          0,                                          0,
                          -0.07655460838455727096268470421043572734356, -0.07655460838455727096268470421043572734356, 0.5281092167691145419253694084208714546871,                                       0.25,                                          0,                                          0,
                          -0.7274063478261298469327624106373817880569, -0.7274063478261298469327624106373817880569,  1.584995061740679345833468104380843436484, 0.6598176339115803480320567168939201396298,                                       0.25,                                          0,
                          -0.01558763503571650073772070605100653051431, -0.01558763503571650073772070605100653051431,  0.387657670913203331289370193410831477968, 0.5017726195721631659377339675717638134054, -0.1082550204139334957516627488805822303448,                                       0.25};
  const double b[] = {-0.01558763503571650073772070605100653051431, -0.01558763503571650073772070605100653051431,  0.387657670913203331289370193410831477968, 0.5017726195721631659377339675717638134054, -0.1082550204139334957516627488805822303448,                                       0.25};
  const double bt[] = {-2.667188974897924510050644590292388423568, -2.667188974897924510050644590292388423568,  4.816367603349776043955031144306489058251,  1.117615208084968171607210516087674894326, 0.7337284716944381378723808535239462278927, -0.3333333333333333333333333333333333333333};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_ESDIRK4;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_SDIRK3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  const double c[] = {0.788675134594812882254574390252, 0.21132486540518711774542560975,                               1};
  const double A[] = {
                          0.788675134594812882254574390252,                                0,                                0,
                          -0.577350269189625764509148780509, 0.788675134594812882254574390252,                                0,
                                                        0, 0.211324865405187117745425609748, 0.788675134594812882254574390252};
  const double b[] = {0.5, 0.5, 0.0};
  const double bt[] = {-3.52072594216369017578202073251, 1.57735026918962576450914878069, 2.94337567297406441127287195182};

  setButcherTableau(tableau, c, A, b, bt);
}

// TODO: Describe me
void getButcherTableau_SDIRK2(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 2;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1.5;

  /* Butcher Tableau */
  const double c[] = {0.5, 1.0};
  const double A[] = {0.5, 0.0,
                      0.5, 0.5};
  const double b[] = { 0.5,  0.5};
  const double bt[] = {0.25, 0.75};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_MS(BUTCHER_TABLEAU* tableau)
{
  if (tableau->richardson) {
    warningStreamPrint(OMC_LOG_STDOUT, 0,"Richardson extrapolation is not available for multi-step methods");
    tableau->richardson = FALSE;
  }

  tableau->nStages = 2;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[] = {-1.0, 1.0};
  const double A[] = {0.0, 0.0,
                      0.0, 0.0};
  const double b[] = {0.5, 0.5};
  const double bt[] = {1.0, 0.0};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods
void getButcherTableau_HEUN(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 2;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[] = {0.0, 1.0};
  const double A[] = {0.0, 0.0,
                      1.0, 0.0};
  const double b[] = {0.5, 0.5};
  const double bt[] = {1.0, 0.0};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_EXPLEULER(BUTCHER_TABLEAU* tableau)
{
  if (tableau->richardson) {
    tableau->nStages = 1;
    tableau->order_b = 1;

    /* Butcher Tableau */
    const double c[] = {0.0};
    const double A[] = {0.0};
    const double b[] = {1.0};
    const double* bt = NULL;

    setButcherTableau(tableau, c, A, b, bt);
    tableau->isKLeftAvailable = FALSE;
    tableau->isKRightAvailable = FALSE;
  } else {
    tableau->nStages = 2;
    tableau->order_b = 1;
    tableau->order_bt = 2;
    tableau->fac = 1.0;

    /* Butcher Tableau */
    const double c[] = {0.0, 0.5};
    const double A[] = {0.0, 0.0,
                        0.5, 0.0};
    const double b[] = {1,0};     // explicit Euler step
    const double bt[] = {0,1};    // explicit midpoint rule corresponds to Richardson extrapolation

    setButcherTableau(tableau, c, A, b, bt);
    tableau->isKLeftAvailable = TRUE;
    tableau->isKRightAvailable = FALSE;
  }
}

// TODO: Describe me
void getButcherTableau_RUNGEKUTTA(BUTCHER_TABLEAU* tableau)
{
  if (tableau->richardson) {
    tableau->nStages = 4;
    tableau->order_b = 4;

    /* Butcher Tableau */
    const double c[] = {0, 0.5, 0.5, 1};
    const double A[] = {0,   0,   0, 0,
                        0.5, 0,   0, 0,
                        0,   0.5, 0, 0,
                        0,   0,   1, 0};
    const double b[] = {0.166666666666666666666666666667, 0.333333333333333333333333333333, 0.333333333333333333333333333333, 0.166666666666666666666666666667};
    const double* bt = NULL;

    setButcherTableau(tableau, c, A, b, bt);
    tableau->isKLeftAvailable = FALSE;
    tableau->isKRightAvailable = FALSE;
  } else {
    tableau->nStages = 5;
    tableau->order_b = 4;
    tableau->order_bt = 3;
    tableau->fac = 1.0;

    /* Butcher Tableau */
    const double c[] = {                              0,                             0.5,                             0.5,                               1,                               1};
    const double A[] = {
                                                          0,                                0,                                0,                                0,                                0,
                                                        0.5,                                0,                                0,                                0,                                0,
                                                          0,                              0.5,                                0,                                0,                                0,
                                                          0,                                0,                                1,                                0,                                0,
                            0.166666666666666666666666666667, 0.333333333333333333333333333333, 0.333333333333333333333333333333, 0.166666666666666666666666666667,                                0};
    const double b[] = {0.166666666666666666666666666667, 0.333333333333333333333333333333, 0.333333333333333333333333333333, 0.166666666666666666666666666667,                               0};
    const double bt[] = {0.166666666666666666666666666667, 0.333333333333333333333333333333, 0.333333333333333333333333333333, 0.0666666666666666666666666666667,                             0.1};

    setButcherTableau(tableau, c, A, b, bt);
    tableau->isKLeftAvailable = TRUE;
    tableau->isKRightAvailable = FALSE;
  }
}

// TODO: Describe me
void getButcherTableau_RADAU_IA_2(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 2;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {                                         0, 0.6666666666666666666666666666666666666667};
  const double A[] = {
                                                                0.25,                                      -0.25,
                                                                0.25, 0.4166666666666666666666666666666666666667};
  const double b[] = {                                      0.25,                                       0.75};
  const double bt[] = {                                         1,                                          0};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RADAU_IA_3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {                                         0, 0.3550510257216821901802715925294108608034, 0.8449489742783178098197284074705891391966};
  const double A[] = {
                          0.1111111111111111111111111111111111111111, -0.1916383190435098943442935597058828551092, 0.08052720793239878323318244859477174399811,
                          0.1111111111111111111111111111111111111111, 0.2920734116652284630205027458970589992882, -0.04813349705465738395134226447875924959593,
                          0.1111111111111111111111111111111111111111, 0.5370223859435462728402311533676481384848, 0.1968154772236604258683861429918298896007};
  const double b[] = {0.1111111111111111111111111111111111111111, 0.5124858261884216138388134465196080942213, 0.3764030627004672750500754423692807946676};
  const double bt[] = {                                        -1,  2.428869016623520557281749043578436645313, -0.4288690166235205572817490435784366453135};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RADAU_IA_4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0e2;

  const double c[] = {                                         0, 0.2123405382391529439747581101240003766519, 0.5905331355592652891350737479311701059481, 0.9114120404872960526044538562305438031143};
  const double A[] = {
                                                              0.0625, -0.1272343654635525399261022740747629483888,  0.099672075604073291167510764268264869924, -0.03493771014052075124140849019350192153521,
                                                              0.0625, 0.1890365181700563424729334195950234041041, -0.05649428442966990931221809509015575158053, 0.01729830449876651081404278561913272412831,
                                                              0.0625, 0.3440329094988014313829271454479024823512, 0.2068925739353589001046450988221595237882, -0.02289234787489504235249849633889190019127,
                                                              0.0625,  0.323205386248104141430923784055699840505, 0.4127071749160357251796800191634554619301, 0.1129994793231561859938500530113885006791};
  const double b[] = {                                    0.0625,  0.328844319980059743944289221072796831749, 0.3881934688431718807802323068900171791981, 0.2204622111767683752754784720371859890529};
  const double bt[] = {                                      2.25, -4.124358471244279153469290371543906361858,  3.876716114985737071643109056279287626538,  -1.00235764374145791817381868473538126468};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RADAU_IIA_2(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 2;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {0.3333333333333333333333333333333333333333,                                          1};
  const double A[] = {
                          0.4166666666666666666666666666666666666667, -0.08333333333333333333333333333333333333333,
                                                                0.75,                                       0.25};
  const double b[] = {                                      0.75,                                       0.25};
  const double bt[] = {                                       1.5,                                       -0.5};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RADAU_IIA_3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {0.1550510257216821901802715925294108608034, 0.6449489742783178098197284074705891391966,                                          1};
  const double A[] = {
                          0.1968154772236604258683861429918298896007, -0.06553542585019838810852278256960869180125, 0.02377097434822015242040823210718966300399,
                          0.3944243147390872769974116714584975806901, 0.2920734116652284630205027458970589992882, -0.04154875212599793019818600988496744078177,
                          0.3764030627004672750500754423692807946676, 0.5124858261884216138388134465196080942213, 0.1111111111111111111111111111111111111111};
  const double b[] = {0.3764030627004672750500754423692807946676, 0.5124858261884216138388134465196080942213, 0.1111111111111111111111111111111111111111};
  const double bt[] = {-0.4288690166235205572817490435784366453135,  2.428869016623520557281749043578436645313,                                         -1};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RADAU_IIA_4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {0.08858795951270394739554614376945619688573, 0.4094668644407347108649262520688298940519, 0.7876594617608470560252418898759996233481,                                          1};
  const double A[] = {
                          0.1129994793231561859938500530113885006791, -0.0403092207235222057355498883931598949343, 0.02580237742033639103594009159581420862867, -0.009904676507266423898694112444586617487772,
                          0.2343839957474002565736616739674733665127, 0.2068925739353589001046450988221595237882, -0.04785712804854071885000849114278849491118, 0.01604742280651627303662797042198549866226,
                          0.216681784623250341844052497071844297893, 0.4061232638673733112251985775422159337208, 0.1890365181700563424729334195950234041041, -0.02418210489983293951694260433308401236982,
                          0.2204622111767683752754784720371859890529, 0.3881934688431718807802323068900171791981,  0.328844319980059743944289221072796831749,                                     0.0625};
  const double b[] = {0.2204622111767683752754784720371859890529, 0.3881934688431718807802323068900171791981,  0.328844319980059743944289221072796831749,                                     0.0625};
  const double bt[] = { 1.443282066094994668724775628809753242785, -3.100329177299393310082644442499253268142,  4.782047111204398641357868813689500025357,                                     -2.125};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_LOBATTO_IIIA_3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 2*tableau->nStages - 2;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {                                         0,                                        0.5,                                          1};
  const double A[] = {
                                                                  0,                                          0,                                          0,
                          0.2083333333333333333333333333333333333333, 0.3333333333333333333333333333333333333333, -0.04166666666666666666666666666666666666667,
                          0.1666666666666666666666666666666666666667, 0.6666666666666666666666666666666666666667, 0.1666666666666666666666666666666666666667};
  const double b[] = {0.1666666666666666666666666666666666666667, 0.6666666666666666666666666666666666666667, 0.1666666666666666666666666666666666666667};
  const double bt[] = {                                      -0.5,                                          2,                                       -0.5};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_LOBATTO_IIIA_4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 2*tableau->nStages - 2;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {                                         0, 0.2763932022500210303590826331268723764559, 0.7236067977499789696409173668731276235441,                                          1};
  const double A[] = {
                                                                  0,                                          0,                                          0,                                          0,
                          0.1103005664791649141367431139060939686287, 0.1896994335208350858632568860939060313713, -0.03390736422914388377766048077922159217273, 0.01030056647916491413674311390609396862867,
                          0.07303276685416841919659021942723936470466, 0.4505740308958105504443271474458882588394, 0.2269672331458315808034097805727606352953, -0.02696723314583158080340978057276063529534,
                          0.08333333333333333333333333333333333333333, 0.4166666666666666666666666666666666666667, 0.4166666666666666666666666666666666666667, 0.08333333333333333333333333333333333333333};
  const double b[] = {0.08333333333333333333333333333333333333333, 0.4166666666666666666666666666666666666667, 0.4166666666666666666666666666666666666667, 0.08333333333333333333333333333333333333333};
  const double bt[] = { 1.333333333333333333333333333333333333333, -2.378418305208070453844800419247428627634,  3.211751638541403787178133752580761960967, -1.166666666666666666666666666666666666667};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_LOBATTO_IIIB_3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 2*tableau->nStages - 2;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {                                         0,                                        0.5,                                          1};
  const double A[] = {
                          0.1666666666666666666666666666666666666667, -0.1666666666666666666666666666666666666667,                                          0,
                          0.1666666666666666666666666666666666666667, 0.3333333333333333333333333333333333333333,                                          0,
                          0.1666666666666666666666666666666666666667, 0.8333333333333333333333333333333333333333,                                          0};
  const double b[] = {0.1666666666666666666666666666666666666667, 0.6666666666666666666666666666666666666667, 0.1666666666666666666666666666666666666667};
  const double bt[] = {                                      -0.5,                                          2,                                       -0.5};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_LOBATTO_IIIB_4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 2*tableau->nStages - 2;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {                                         0, 0.2763932022500210303590826331268723764559, 0.7236067977499789696409173668731276235441,                                          1};
  const double A[] = {
                          0.08333333333333333333333333333333333333333, -0.1348361657291579040170489028638031764767, 0.05150283239582457068371556953046984314336,                                          0,
                          0.08333333333333333333333333333333333333333, 0.2269672331458315808034097805727606352953, -0.03390736422914388377766048077922159217273,                                          0,
                          0.08333333333333333333333333333333333333333, 0.4505740308958105504443271474458882588394, 0.1896994335208350858632568860939060313713,                                          0,
                          0.08333333333333333333333333333333333333333, 0.3651638342708420959829510971361968235233, 0.5515028323958245706837155695304698431434,                                          0};
  const double b[] = {0.08333333333333333333333333333333333333333, 0.4166666666666666666666666666666666666667, 0.4166666666666666666666666666666666666667, 0.08333333333333333333333333333333333333333};
  const double bt[] = { 1.333333333333333333333333333333333333333, -2.378418305208070453844800419247428627634,  3.211751638541403787178133752580761960967, -1.166666666666666666666666666666666666667};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_LOBATTO_IIIC_3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 2*tableau->nStages - 2;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {0., .500000000000000000000000000000000000000000000000000000000000, 1.};
  const double A[] = {
                          .166666666666666666666666666666666666666666666666666666666666, -.333333333333333333333333333333333333333333333333333333333332, .166666666666666666666666666666666666666666666666666666666666,
                          .166666666666666666666666666666666666666666666666666666666666, .416666666666666666666666666666666666666666666666666666666668, -.833333333333333333333333333333333333333333333333333333333340e-1,
                          .166666666666666666666666666666666666666666666666666666666666, .666666666666666666666666666666666666666666666666666666666668, .166666666666666666666666666666666666666666666666666666666666};
  const double b[] = {.166666666666666666666666666666666666666666666666666666666666, .66666666666666666666666666666666666666666666666666666666667, .166666666666666666666666666666666666666666666666666666666666};
  const double bt[] = {-.50000000000000000000000000000000000000000000000000000000000, 2.00000000000000000000000000000000000000000000000000000000000, -.500000000000000000000000000000000000000000000000000000000000};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_LOBATTO_IIIC_4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 2*tableau->nStages - 2;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {                                         0, 0.2763932022500210303590826331268723764559, 0.7236067977499789696409173668731276235441,                                          1};
  const double A[] = {
                          0.08333333333333333333333333333333333333333, -0.1863389981249824747007644723942730196201, 0.1863389981249824747007644723942730196201, -0.08333333333333333333333333333333333333333,
                          0.08333333333333333333333333333333333333333,                                       0.25, -0.09420793070830879791440359468531556080141, 0.03726779962499649494015289447885460392401,
                          0.08333333333333333333333333333333333333333, 0.4275412640416421312477369280186488941347,                                       0.25, -0.03726779962499649494015289447885460392401,
                          0.08333333333333333333333333333333333333333, 0.4166666666666666666666666666666666666667, 0.4166666666666666666666666666666666666667, 0.08333333333333333333333333333333333333333};
  const double b[] = {0.08333333333333333333333333333333333333333, 0.4166666666666666666666666666666666666667, 0.4166666666666666666666666666666666666667, 0.08333333333333333333333333333333333333333};
  const double bt[] = { 1.333333333333333333333333333333333333333, -2.378418305208070453844800419247428627634,  3.211751638541403787178133752580761960967, -1.166666666666666666666666666666666666667};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_GAUSS2(BUTCHER_TABLEAU* tableau)
{
  //implicit Gauss-Legendre, order 2*s, but embedded scheme has order s

  tableau->nStages = 2;
  tableau->order_b = 2*tableau->nStages;
  tableau->order_bt = tableau->nStages - 1;
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

  const double c[] = {c1, c2};
  const double A[] = {a11, a12,
                      a21, a22
                      };
  const double b[] = {b1, b2};    // implicit Gauss-Legendre rule
  const double bt[] = {bt1, bt2}; // Embedded method (order 1)

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_GAUSS3(BUTCHER_TABLEAU* tableau)
{
  //implicit Gauss-Legendre, order 2*s, but embedded scheme has order s

  tableau->nStages = 3;
  tableau->order_b = 2*tableau->nStages;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {0.112701665379258311482073460022,                             0.5, 0.887298334620741688517926539978};
  const double A[] = {
                          0.13888888888888888888888888889, -0.0359766675249389034563954710967, 0.00978944401530832604958004222935,
                          0.300263194980864592438024947213, 0.222222222222222222222222222223, -0.022485417203086814660247169435,
                          0.267988333762469451728197735546,  0.48042111196938334790083991554, 0.138888888888888888888888888886};
  const double b[] = {0.277777777777777777777777777778, 0.444444444444444444444444444443, 0.277777777777777777777777777778};
  const double bt[] = {-0.833333333333333333333333333333, 2.66666666666666666666666666666, -0.833333333333333333333333333333};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_GAUSS4(BUTCHER_TABLEAU* tableau)
{
  //implicit Gauss-Legendre, order 2*s, but embedded scheme has order s

  tableau->nStages = 4;
  tableau->order_b = 2*tableau->nStages;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {0.06943184420297371238802675555359524745214, 0.3300094782075718675986671204483776563997, 0.6699905217924281324013328795516223436003, 0.9305681557970262876119732444464047525479};
  const double A[] = {
                          0.08696371128436346434326598730549985180884, -0.02660418008499879331338513047695310932617, 0.01262746268940472451505688057461809356577, -0.0035551496857956831569109818495695885963,
                          0.1881181174998680716506855450871711600564, 0.1630362887156365356567340126945001481912, -0.02788042860247089522415110641899741073777, 0.006735500594538155515398669085703758889893,
                          0.1671919219741887731711333055252959447278, 0.3539530060337439665376191318079977071201, 0.1630362887156365356567340126945001481912, -0.01419069493114114296415357047617145643876,
                          0.177482572254522611843442956460569292214, 0.3134451147418683467984111448143822028166, 0.3526767575162718646268531558659534057085, 0.08696371128436346434326598730549985180884};
  const double b[] = {0.1739274225687269286865319746109997036177, 0.3260725774312730713134680253890002963823, 0.3260725774312730713134680253890002963823, 0.1739274225687269286865319746109997036177};
  const double bt[] = { 2.029062439578463454986692572724958069163,  -4.37278977445749213150196088214782025746,  5.024934929320038274128896932925820850225, -1.681207594441009597613628623502958661928};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_GAUSS5(BUTCHER_TABLEAU* tableau)
{
  //implicit Gauss-Legendre, order 2*s, but embedded scheme has order s

  tableau->nStages = 5;
  tableau->order_b = 2*tableau->nStages;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = {0.04691007703066800360118656085030351743717, 0.2307653449471584544818427896498955975164,                                        0.5, 0.7692346550528415455181572103501044024836, 0.9530899229693319963988134391496964825628};
  const double A[] = {
                          0.05923172126404727187856601017997934066082, -0.01957036435907603749264321405088406001825, 0.01125440081864295555271624421509074877307, -0.005593793660812184876817721964475928215541, 0.001588112967865998539365242470593416237085,
                          0.1281510056700452834961668483295138221932, 0.1196571676248416170103228787089095482281, -0.0245921146196422003893182516860040166299, 0.01031828067068335740895394505635583948635, -0.002768994398769603044282630758879595761319,
                          0.1137762880042246025287412738153655768598, 0.2600046516806415185924058951875739793891, 0.1422222222222222222222222222222222222222, -0.02069031643095828457176013776975488293293, 0.00468715452386994122839074654459310446188,
                          0.1212324369268641468014146511188382770829, 0.2289960545789998766116918123614632569698, 0.3090365590640866448337626961304484610743, 0.1196571676248416170103228787089095482281, -0.009687563141950739739034827969555140871526,
                          0.1168753295602285452177667778893652650845, 0.2449081289104954188974634793822950246717, 0.2731900436258014888917282002293536956714, 0.2588846996087592715132889714687031564744, 0.05923172126404727187856601017997934066082};
  const double b[] = {0.1184634425280945437571320203599586813216, 0.2393143352496832340206457574178190964561, 0.2844444444444444444444444444444444444444, 0.2393143352496832340206457574178190964561, 0.1184634425280945437571320203599586813216};
  const double bt[] = {-3.549480780358140059259512996235616229578,  10.62725855813591783703729077401339400736, -13.15555555555555555555555555555555555556,  10.62725855813591783703729077401339400736, -3.549480780358140059259512996235616229578};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_GAUSS6(BUTCHER_TABLEAU* tableau)
{
  //implicit Gauss-Legendre, order 2*s, but embedded scheme has order s

  tableau->nStages = 6;
  tableau->order_b = 2*tableau->nStages;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 0.01;

  const double c[] = {0.03376524289842398609384922275300269543262, 0.1693953067668677431693002024900473264968, 0.3806904069584015456847491391596440322907, 0.6193095930415984543152508608403559677093, 0.8306046932331322568306997975099526735032, 0.9662347571015760139061507772469973045674};
  const double A[] = {
                          0.04283112309479258626007403554318322338171, -0.014763725997197412475372591060520651442, 0.009325050706477751191438884508003148588288, -0.005668858049483511900921256416216506562144, 0.002854433315099335130929285830116021533671, -0.000812780171264762112299135651562540066904,
                          0.09267349143037886318651229176332031614335, 0.09019039326203465189245837845942902791538, -0.02030010229323958595249408052427246010673, 0.0103631562402464237307199458065599778725, -0.004887192928037671463414203765789644071376, 0.001355561055485061775517870750800108743645,
                          0.08224792261284387380777165114112892155544, 0.1960321623332450060557597815638013827888, 0.1169784836431727618474675859973877487029, -0.02048252774565609762985901186540064382199, 0.007989991899662335797204421480308270793628, -0.00207562578486633419359528915758164772806,
                          0.08773787197445150671374336024394809449147, 0.1723907946244069679877123354385497850371, 0.2544394950320016213247941838601761412278, 0.1169784836431727618474675859973877487029, -0.015651375809175702270843024644943326958, 0.003414323576741298712376419945237525207972,
                          0.08430668513410011074463020033556633801977, 0.1852679794521069752483309606846476999021, 0.2235938110460990999642152261882155195333, 0.2542570695795851096474292525190479575126, 0.09019039326203465189245837845942902791538, -0.007011245240793690666364220676953869379937,
                          0.08647502636084993463244720673792898683032, 0.1775263532089699686539874710887420342971,  0.239625825335829035595856428410992003968, 0.2246319165798677725034962874867723488175, 0.1951445125212667162602893479793787072728, 0.04283112309479258626007403554318322338171};
  const double b[] = {0.08566224618958517252014807108636644676341, 0.1803807865240693037849167569188580558308, 0.2339569672863455236949351719947754974058, 0.2339569672863455236949351719947754974058, 0.1803807865240693037849167569188580558308, 0.08566224618958517252014807108636644676341};
  const double bt[] = { 8.226923975198260790695004480367583058809, -24.35335795417146225501811412781707093571,  36.40229746275844889842270132076392111778, -35.93438352818575785103283097677437012297,  24.71411952721960086258794764165478704738, -8.055599482819090445654708338194850165283};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_IMPLEULER(BUTCHER_TABLEAU* tableau)
{
  if (tableau->richardson) {
    tableau->nStages = 1;
    tableau->order_b = 1;

    /* Butcher Tableau */
    const double c[] = {1.0};
    const double A[] = {1.0};
    const double b[] = {1.0};
    const double* bt = NULL;

    setButcherTableau(tableau, c, A, b, bt);
    tableau->isKLeftAvailable = FALSE;
    tableau->isKRightAvailable = FALSE;
  } else {
    tableau->nStages  = 2;
    tableau->order_b  = 1;
    tableau->order_bt = 2;
    tableau->fac      = 1.e0;

    /* Butcher Tableau */
    const double c[] = {0.0, 1.0};
    const double A[] = {0.0, 0.0,
                        0.0, 1.0};
    const double b[] = {0.0, 1.0};  // implicit Euler step
    const double bt[] = {0.5, 0.5}; // trapezoidal rule for error estimator

    setButcherTableau(tableau, c, A, b, bt);
    tableau->isKLeftAvailable = TRUE;
    tableau->isKRightAvailable = TRUE;
  }
}

// https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods
void getButcherTableau_TRAPEZOID(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages  = 2;
  tableau->order_b  = 2;
  tableau->order_bt = 1;
  tableau->fac      = 1.e0;

  // /* Butcher Tableau */
  const double c[] = {0.0, 1.0};
  const double A[] = {0.0, 0.0,
                      0.5, 0.5};
  const double b[] = {0.5, 0.5};  // trapezoidal rule
  const double bt[] = {1.0, 0.0}; // implicit Euler step

  setButcherTableau(tableau, c, A, b, bt);

  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_MERSON(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac = 1e5;

  /* Butcher Tableau */
  const double c[] = {0.0, 1./3, 1./3, 1./2, 1.0};
  const double A[] = { 0.0,  0.0,   0.0, 0.0, 0.0,
                         1./3,  0.0,   0.0, 0.0, 0.0,
                         1./6, 1./6,   0.0, 0.0, 0.0,
                         1./8,  0.0,  3./8, 0.0, 0.0,
                         1./2,  0.0, -3./2, 2.0, 0.0
                        };
  const double b[] = {1./6,  0.0,   0.0,  2./3,  1./6};   // 4th order
  const double bt[] = {1./10, 0.0, 3./10,  2./5,  1./5};   // 3th order

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

void getButcherTableau_MERSONSSC1(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 1;
  tableau->order_bt = 4;
  tableau->fac = 1e0;

  /* Butcher Tableau */
  const double c[] = {0.0, 1./3, 1./3, 1./2, 1.0};
  const double A[] = { 0.0,  0.0,   0.0, 0.0, 0.0,
                         1./3,  0.0,   0.0, 0.0, 0.0,
                         1./6, 1./6,   0.0, 0.0, 0.0,
                         1./8,  0.0,  3./8, 0.0, 0.0,
                         1./2,  0.0, -3./2, 2.0, 0.0
                        };
  const double b[] = {0.512782397120662718471749459233, 0.330103091995730873405418477521, 0.146713304970630735231072129528, 0.0103570041584038638446238467251, 4.42017545718090471360869927930e-05};
  const double bt[] = {1./6,  0.0,   0.0,  2./3,  1./6};   // 4th order

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

void getButcherTableau_MERSONSSC2(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 2;
  tableau->order_bt = 4;
  tableau->fac = 1e0;

  /* Butcher Tableau */
  const double c[] = {0.0, 1./3, 1./3, 1./2, 1.0};
  const double A[] = { 0.0,  0.0,   0.0, 0.0, 0.0,
                         1./3,  0.0,   0.0, 0.0, 0.0,
                         1./6, 1./6,   0.0, 0.0, 0.0,
                         1./8,  0.0,  3./8, 0.0, 0.0,
                         1./2,  0.0, -3./2, 2.0, 0.0
                        };
  const double b[] = {-0.35629337268078937564325457003, 0.146074652453948837652304806997, 0.934217301122925451486796787885, 0.272197473925746365767707013552, 0.00380394517816872073644596159715};
  const double bt[] = {1./6,  0.0,   0.0,  2./3,  1./6};   // 4th order

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void denseOutput_DOPRI45(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] =  ((((157015080. * dt - 13107642775.) * dt + 34969693132.) * dt - 32272833064.) * dt + 11282082432.)/11282082432.;
  tableau->b_dt[1] = 0.0;
  tableau->b_dt[2] = - 100. * dt * (((15701508. * dt - 914128567.) * dt + 2074956840.) * dt - 1323431896.)/32700410799.;
  tableau->b_dt[3] = 25. * dt *(((94209048. * dt - 1518414297.) * dt + 2460397220.) * dt - 889289856.)/5641041216.;
  tableau->b_dt[4] = -2187. * dt * (((52338360. * dt - 451824525.) * dt + 687873124.) * dt - 259006536.)/199316789632.;
  tableau->b_dt[5] = 11. * dt * (((106151040. * dt - 661884105.) * dt + 946554244.) * dt - 361440756.)/2467955532.;
  tableau->b_dt[6] = dt * (1 - dt) * ((8293050. * dt - 82437520.) * dt + 44764047.) / 29380423.;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// TODO: Describe me
void getButcherTableau_DOPRI45(BUTCHER_TABLEAU* tableau)
{
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
  const double bt[] = {5179./57600, 0.0, 7571./16695, 393./640, -92097./339200, 187./2100, 1./40};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_DOPRI45;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_DOPRISSC1(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 1;
  tableau->order_bt = 5;
  tableau->fac = 1e0;

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
  const double b[] = {0.278585202707552297491652379451, 0.499359343897282505016199003177, 0.21994590092478885648226620836, 0.00221513041070919707891834807597, -0.000108554006807565712812909262366, 2.90820039199235629183419683848e-06, 6.78660827172874851360023304864e-08};
  const double bt[] = {35./384, 0.0, 500./1113, 125./192, -2187./6784, 11./84, 0.0};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_DOPRI45;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_DOPRISSC2(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 2;
  tableau->order_bt = 5;
  tableau->fac = 1e0;

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
  const double b[] = {-0.486346436598901828254513839047, -0.234874439261298143693150869933, 1.65868062062825029557032033231, 0.0708767352953961545635216713703, -0.00905214141822685142604628709823, 0.000667704407394041424018354604235, 4.79569473863318158506377905590e-05};
  const double bt[] = {35./384, 0.0, 500./1113, 125./192, -2187./6784, 11./84, 0.0};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_DOPRI45;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_FEHLBERG12(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1e3;

  /* Butcher Tableau */
  const double c[] = {0.0, 0.5, 1.0};
  const double A[] = {   0.0,      0.0, 0.0,
                          0.5,      0.0, 0.0,
                       1./256., 255./256., 0.0};
  const double b[] = {1./256., 255./256., 0.0};
  const double bt[] = {1./512., 255./256., 1./512.};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_FEHLBERG45(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 6;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1e3;

  /* Butcher Tableau */
  const double c[] = {                              0,                            0.25,                           0.375, 0.923076923076923076923076923077,                               1,                             0.5};
  const double A[] = {
                                                       0,                                0,                                0,                                 0,                                0,                                0,
                                                    0.25,                                0,                                0,                                 0,                                0,                                0,
                                                 0.09375,                          0.28125,                                0,                                 0,                                0,                                0,
                          0.87938097405553026854802002731, -3.27719617660446062812926718252,  3.32089212562585343650432407829,                                0,                                0,                                0,
                          2.03240740740740740740740740741,                               -8,  7.17348927875243664717348927875, -0.20589668615984405458089668616,                                0,                                0,
                        -0.296296296296296296296296296296,                                2, -1.38167641325536062378167641326, 0.452972709551656920077972709552,                             -0.275,                              0};
  const double b[] = {0.121296296296296296296296296296, -0.0304761904761904761904761904762, 0.578869395711500974658869395712, 0.516977165135059871901977165135, -0.186666666666666666666666666667,                               0};
  const double bt[] = {0.115740740740740740740740740741,                               0, 0.548927875243664717348927875244,    0.535331384015594541910331384016,                              -0.2,                               0};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_FEHLBERG78(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 13;
  tableau->order_b = 8;
  tableau->order_bt = 7;
  tableau->fac = 1e3;

  /* Butcher Tableau */
  const double c[] = {0, 0.0740740740740740740740740740741, 0.111111111111111111111111111111, 0.166666666666666666666666666667, 0.416666666666666666666666666667, 0.5, 0.833333333333333333333333333333, 0.166666666666666666666666666667, 0.666666666666666666666666666667, 0.333333333333333333333333333333, 1, 0, 1};
  const double A[] = {
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
  const double b[] = {                              0,                               0,                               0,                               0,                               0, 0.32380952380952380952380952381, 0.257142857142857142857142857143, 0.257142857142857142857142857143, 0.0321428571428571428571428571429, 0.0321428571428571428571428571429,                               0, 0.0488095238095238095238095238095, 0.0488095238095238095238095238095};
  const double bt[] = {0.0488095238095238095238095238095,                               0,                               0,                               0,                               0, 0.32380952380952380952380952381, 0.257142857142857142857142857143, 0.257142857142857142857142857143, 0.0321428571428571428571428571429, 0.0321428571428571428571428571429, 0.0488095238095238095238095238095,                               0,                               0};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

void getButcherTableau_FEHLBERGSSC1(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 13;
  tableau->order_b = 1;
  tableau->order_bt = 8;
  tableau->fac = 1e0;

  /* Butcher Tableau */
  const double c[] = {0, 0.0740740740740740740740740740741, 0.111111111111111111111111111111, 0.166666666666666666666666666667, 0.416666666666666666666666666667, 0.5, 0.833333333333333333333333333333, 0.166666666666666666666666666667, 0.666666666666666666666666666667, 0.333333333333333333333333333333, 1, 0, 1};
  const double A[] = {
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
  const double b[] = {-0.364851774598758815913721254923, 0.301330765163132508037187549082,  0.8325767564796758519952730731,                               0, -0.0268487161606468393107786573864, 0.0959117920564658481117857153644, -0.0286739781279975214853581446154, 0.213522659333043888240291858263, -0.00908604512512093286675314270667, 0.00681453439485641598976617630506, 0.0103479967072222251389783702879, -0.0310439901218725048480067038039, -1.23088664838968206937943710922e-16};
  const double bt[] = {                              0,                               0,                               0,                               0,                               0, 0.32380952380952380952380952381, 0.257142857142857142857142857143, 0.257142857142857142857142857143, 0.0321428571428571428571428571429, 0.0321428571428571428571428571429,                               0, 0.0488095238095238095238095238095, 0.0488095238095238095238095238095};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

void getButcherTableau_FEHLBERGSSC2(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 13;
  tableau->order_b = 2;
  tableau->order_bt = 8;
  tableau->fac = 1e0;

  /* Butcher Tableau */
  const double c[] = {                              0, 0.0740740740740740740740740740741, 0.111111111111111111111111111111, 0.166666666666666666666666666667, 0.416666666666666666666666666667,                             0.5, 0.833333333333333333333333333333, 0.166666666666666666666666666667, 0.666666666666666666666666666667, 0.333333333333333333333333333333,                               1,                               0,                               1};
  const double A[] = {
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
  const double b[] = {1.36308696433418349654697814366,                               0, -3.26459140897742935132414339163, -1.62051733050260843967905937243, -0.29368516237586603628166052316,  1.8370371692484130907915149173, -0.526247844078595836398397402697, 3.92724305645149417982124010038, -0.167071106248436357738384607217, 0.12530612140680376084342193382, 0.190280224596084454633821394807, -0.570840683836337962747432519784, -1.77049984678986730541092039109e-11};
  const double bt[] = {                              0,                               0,                               0,                               0,                               0, 0.32380952380952380952380952381, 0.257142857142857142857142857143, 0.257142857142857142857142857143, 0.0321428571428571428571428571429, 0.0321428571428571428571428571429,                               0, 0.0488095238095238095238095238095, 0.0488095238095238095238095238095};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RK810(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 17;
  tableau->order_b = 10;
  tableau->order_bt = 8;
  tableau->fac = 1e0;

  /* Butcher Tableau */
  const double c[] = {                              0,                             0.1, 0.539357840802981787532485197881, 0.809036761204472681298727796822, 0.309036761204472681298727796822, 0.981074190219795268254879548311, 0.833333333333333333333333333333, 0.354017365856802376329264185949, 0.88252766196473234642550148698, 0.64261575824032254815707549702, 0.35738424175967745184292450298, 0.11747233803526765357449851302, 0.833333333333333333333333333333, 0.309036761204472681298727796822, 0.539357840802981787532485197881,                             0.1,                               1};
  const double A[] = {
                                                        0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                                                      0.1,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          -0.915176561375291440520015019275,  1.45453440217827322805250021716,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.202259190301118170324681949205,                                0, 0.606777570903354510974045847616,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.184024714708643575149100693471,                                0,  0.19796683122719236906814177051, -0.0729547847313632629185146671596,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.0879007340206681337319777094132,                                0,                                0,  0.41045970252026064531817489592, 0.482713753678866489204726942977,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.0859700504902460302188480225946,                                0,                                0, 0.330885963040722183948884057659, 0.489662957309450192844507011136, -0.0731856375070850736789057580559,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.120930449125333720660378854928,                                0,                                0,                                0, 0.260124675758295622809007617838, 0.0325402621549091330158899334391, -0.0595780211817361001560122202563,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.11085437958039148350893617101,                                0,                                0,                                0,                                0, -0.0605761488255005587620924953656,  0.32176370560177839010089879905, 0.510485725608063031577759012285,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.112054414752879004829715002762,                                0,                                0,                                0,                                0, -0.144942775902865915672349828341, -0.333269719096256706589705211416,  0.49926922955688006135331684397, 0.509504608929686104236098690045,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.113976783964185986138004186737,                                0,                                0,                                0,                                0, -0.0768813364203356938586214289121, 0.239527360324390649107711455272, 0.397774662368094639047830462489, 0.0107558956873607455550609147441, -0.32776912416401887414706108735,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.0798314528280196046351426864486,                                0,                                0,                                0,                                0, -0.0520329686800603076514949887613, -0.0576954146168548881732784355283, 0.194781915712104164976306262147, 0.145384923188325069727524825977, -0.0782942710351670777553986729726, -0.114503299361098912184303164291,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.985115610164857280120041500307,                                0,                                0, 0.330885963040722183948884057659, 0.489662957309450192844507011136, -1.37896486574843567582112720931, -0.861164195027635666673916999666,  5.78428813637537220022999785487,  3.28807761985103566890460615937, -2.38633905093136384013422325216, -3.25479342483643918654589367588,   -2.163435416864229823539542113,                                0,                                0,                                0,                                0,                                0,
                          0.895080295771632891049613132337,                                0,  0.19796683122719236906814177051, -0.0729547847313632629185146671596,                                0, -0.851236239662007619739049371446, 0.398320112318533301719718614174,  3.63937263181035606029412920047,  1.54822877039830322365301663075,  -2.1222171470405371602606242746, -1.58350398545326172713384349626, -1.71561608285936264922031819751, -0.0244036405750127452135415444412,                                0,                                0,                                0,                                0,
                          -0.915176561375291440520015019275,  1.45453440217827322805250021716,                                0,                                0, -0.777333643644968233538931228575,                                0, -0.0910895662155176069593203555807,                                0,                                0,                                0,                                0,                                0, 0.0910895662155176069593203555807, 0.777333643644968233538931228575,                                0,                                0,                                0,
                                                      0.1,                                0, -0.157178665799771163367058998273,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0, 0.157178665799771163367058998273,                                0,                                0,
                          0.181781300700095283888472062582,                            0.675, 0.342758159847189839942220553414,                                0, 0.259111214548322744512977076192, -0.358278966717952089048961276722, -1.04594895940883306095050068756, 0.930327845415626983292300564432,  1.77950959431708102446142106795,                              0.1, -0.282547569539044081612477785222, -0.159327350119972549169261984373, -0.145515894647001510860991961081, -0.259111214548322744512977076192, -0.342758159847189839942220553414,                           -0.675,                                0};
  const double b[] = {0.0333333333333333333333333333333,                           0.025, 0.0333333333333333333333333333333,                               0,                            0.05,                               0,                            0.04,                               0, 0.189237478148923490158306404106, 0.277429188517743176508360262561, 0.277429188517743176508360262561, 0.189237478148923490158306404106,                           -0.04,                           -0.05, -0.0333333333333333333333333333333,                          -0.025, 0.0333333333333333333333333333333};
  const double bt[] = {0.0333333333333333333333333333333, 0.0277777777777777777777777777778, 0.0333333333333333333333333333333,                               0,                            0.05,                               0,                            0.04,                               0, 0.189237478148923490158306404106, 0.277429188517743176508360262561, 0.277429188517743176508360262561, 0.189237478148923490158306404106,                           -0.04,                           -0.05, -0.0333333333333333333333333333333, -0.0277777777777777777777777777778, 0.0333333333333333333333333333333};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RK1012(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 25;
  tableau->order_b = 12;
  tableau->order_bt = 10;
  tableau->fac = 1e0;

  /* Butcher Tableau */
  const double c[] = {                              0,                             0.2, 0.555555555555555555555555555556, 0.833333333333333333333333333333, 0.333333333333333333333333333333,                               1, 0.671835709170513812712245661003, 0.288724941110620201935458488967,                          0.5625, 0.833333333333333333333333333333, 0.947695431179199287562380162102, 0.0548112876863802643887753674811, 0.0848880518607165350639838930163, 0.265575603264642893098114059046,                             0.5, 0.734424396735357106901885940954, 0.915111948139283464936016106984, 0.947695431179199287562380162102, 0.833333333333333333333333333333, 0.288724941110620201935458488967, 0.671835709170513812712245661003, 0.333333333333333333333333333333, 0.555555555555555555555555555556,                             0.2,                               1};
  const double A[] = {
                                                        0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                                                      0.2,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          -0.216049382716049382716049382716, 0.771604938271604938271604938272,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.208333333333333333333333333333,                                0,                            0.625,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.193333333333333333333333333333,                                0,                             0.22,                            -0.08,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                                                      0.1,                                0,                                0,                              0.4,                              0.5,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.10336447165001047757039543569,                                0,                                0, 0.124053094528946761061581889237, 0.483171167561032899288836480452, -0.0387530245694763252085681443768,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.12403826143183332408190458598,                                0,                                0,                                0, 0.217050632197958486317846256953, 0.0137455792075966759812907801835, -0.0661095317267682844455831341498,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.091477489485688298314499184698,                                0,                                0,                                0,                                0, -0.00544348523717469689965754944145, 0.0680716801688453518578515120895, 0.408394315582641046727306852654,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.0890013652502551018954509355424,                                0,                                0,                                0,                                0, 0.00499528226645532360197793408421, 0.397918238819828997341739603001, 0.427930210752576611068192608301, -0.0865117637557827005740277475955,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.069508762413490754311269390641,                                0,                                0,                                0,                                0, 0.129146941900176461970759579483,  1.53073638102311295076342566143, 0.577874761129140052546751349455, -0.951294772321088980532340837389, -0.40827664296563195149748498152,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.0444861403295135866269453507092,                                0,                                0,                                0,                                0, -0.00380476867056961731984232686575, 0.0106955064029624200721262602809, 0.0209616244499904333296674205929, -0.0233146023259321786648561431552, 0.00263265981064536974369934736325, 0.00315472768977025060103545855572,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.0194588815119755475588801096525,                                0,                                0,                                0,                                0,                                0,                                0,                                0, 6.78512949171812509306121653452e-05, -4.29795859049273623271005330230e-05, 1.76358982260285155407485928953e-05, 0.0653866627415027051009595231385,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.206836835664277105916828174798,                                0,                                0,                                0,                                0,                                0,                                0,                                0, 0.0166796067104156472828045866665, -0.0087950156320071021445702417825, 0.00346675455362463910824462315246, -0.861264460105717678161432562258, 0.908651882074050281096239478469,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.0203926084654484010091511314677,                                0,                                0,                                0,                                0,                                0,                                0,                                0, 0.0869469392016685948675400555584, -0.0191649630410149842286436611791, 0.00655629159493663287364871573244, 0.0987476128127434780903798528674, 0.00535364695524996055083260173616, 0.301167864010967916837091303817,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.228410433917778099547115412893,                                0,                                0,                                0,                                0,                                0,                                0,                                0, -0.498707400793025250635016567443, 0.134841168335724478552596703793, -0.0387458244055834158439904226924, -1.27473257473474844240388430825,  1.43916364462877165201184452437, -0.214007467967990254219503540827,  0.95820241775443023989272413911,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          2.00222477655974203614249646013,                                0,                                0,                                0,                                0,                                0,                                0,                                0,  2.06701809961524912091954656438, 0.623978136086139541957471279831, -0.0462283685500311430283203554129, -8.84973288362649614860075246727,  7.74257707850855976227437225792, -0.588358519250869210993353314128, -1.10683733362380649395704708017, -0.929529037579203999778397238291,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                            3.1378953341207344293445160899,                                0,                                0,                                0,                                0, 0.129146941900176461970759579483,  1.53073638102311295076342566143, 0.577874761129140052546751349455,  5.42088263055126683050056840892, 0.231546926034829304872663800878, 0.0759292995578913560162301311785, -12.3729973380186513287414553403,  9.85455883464769543935957209317, 0.0859111431370436529579357709052, -5.65242752862643921117182090082, -1.94300935242819610883833776782, -0.128352601849404542018428714319,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          1.38360054432196014878538118298,                                0,                                0,                                0,                                0, 0.00499528226645532360197793408421, 0.397918238819828997341739603001, 0.427930210752576611068192608301, -1.30299107424475770916551439123, 0.661292278669377029097112528108, -0.144559774306954349765969393689, -6.96576034731798203467853867461,  6.65808543235991748353408295542, -1.66997375108841486404695805726,  2.06413702318035263832289040302, -0.674743962644306471862958129571, -0.00115618834794939500490703608436, -0.00544057908677007389319819914242,                                0,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.951236297048287669474637975895,                                0,                                0,                                0, 0.217050632197958486317846256953, 0.0137455792075966759812907801835, -0.0661095317267682844455831341498,                                0, 0.152281696736414447136604697041, -0.337741018357599840802300793134, -0.0192825981633995781534949199287, -3.68259269696866809932409015535,   3.1619787040698206354153352842, -0.370462522106885290716991856022, -0.0514974200365440434996434456698, -0.000829625532120152946787043541793, 2.79801041419278598986586589070e-06, 0.0418603916412360287969841020777, 0.279084255090877355915660874555,                                0,                                0,                                0,                                0,                                0,                                0,
                          0.10336447165001047757039543569,                                0,                                0, 0.124053094528946761061581889237, 0.483171167561032899288836480452, -0.0387530245694763252085681443768,                                0, -0.438313820361122420391059788941,                                0, -0.218636633721676647685111485017, -0.0312334764394719229981634995206,                                0,                                0,                                0,                                0,                                0,                                0, 0.0312334764394719229981634995206, 0.218636633721676647685111485017, 0.438313820361122420391059788941,                                0,                                0,                                0,                                0,                                0,
                          0.193333333333333333333333333333,                                0,                             0.22,                            -0.08,                                0,                                0, 0.0984256130499315928152900286856, -0.19641088922305465344652650439,                                0, 0.436457930493068729391826122588, 0.0652613721675721098560370939806,                                0,                                0,                                0,                                0,                                0,                                0, -0.0652613721675721098560370939806, -0.436457930493068729391826122588,  0.19641088922305465344652650439, -0.0984256130499315928152900286856,                                0,                                0,                                0,                                0,
                          -0.216049382716049382716049382716, 0.771604938271604938271604938272,                                0,                                0, -0.666666666666666666666666666667,                                0, -0.390696469295978451446999802258,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0, 0.390696469295978451446999802258, 0.666666666666666666666666666667,                                0,                                0,                                0,
                                                      0.2,                                0, -0.164609053497942386831275720165,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0,                                0, 0.164609053497942386831275720165,                                0,                                0,
                          1.47178724881110408452949550989,                           0.7875, 0.421296296296296296296296296296,                                0, 0.291666666666666666666666666667,                                0,  0.34860071762832956320685442163, 0.229499544768994849582890233711,  5.79046485790481979159831978177, 0.418587511856506868874073759427,  0.30703988022247400264965381749, -4.68700905350603332214256344684,    3.135716655938022621520381524,  1.40134829710965720817510506276, -5.52931101439499023629010306006, -0.853138235508063349309546894975, 0.103575780373610140411804607168, -0.140474416950600941142546901202, -0.418587511856506868874073759427, -0.229499544768994849582890233711, -0.34860071762832956320685442163, -0.291666666666666666666666666667, -0.421296296296296296296296296296,                          -0.7875,                                0};
  const double b[] = {0.0238095238095238095238095238095,                       0.0234375,                         0.03125,                               0, 0.0416666666666666666666666666667,                               0,                            0.05,                            0.05,                               0,                             0.1, 0.0714285714285714285714285714286,                               0, 0.138413023680782974005350203145, 0.215872690604931311708935511141, 0.24380952380952380952380952381, 0.215872690604931311708935511141, 0.138413023680782974005350203145, -0.0714285714285714285714285714286,                            -0.1,                           -0.05,                           -0.05, -0.0416666666666666666666666666667,                        -0.03125,                      -0.0234375, 0.0238095238095238095238095238095};
  const double bt[] = {0.0238095238095238095238095238095,                             0.1,                         0.03125,                               0, 0.0416666666666666666666666666667,                               0,                            0.05,                            0.05,                               0,                             0.1, 0.0714285714285714285714285714286,                               0, 0.138413023680782974005350203145, 0.215872690604931311708935511141, 0.24380952380952380952380952381, 0.215872690604931311708935511141, 0.138413023680782974005350203145, -0.0714285714285714285714285714286,                            -0.1,                           -0.05,                           -0.05, -0.0416666666666666666666666666667,                        -0.03125,                            -0.1, 0.0238095238095238095238095238095};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

// TODO: Describe me
void getButcherTableau_RK1214(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 35;
  tableau->order_b = 14;
  tableau->order_bt = 12;
  tableau->fac = 1e0;

  /* Butcher Tableau */
  const double c[] = {                                                     0,   0.11111111111111111111111111111111111111111111111111,   0.55555555555555555555555555555555555555555555555556,   0.83333333333333333333333333333333333333333333333333,   0.33333333333333333333333333333333333333333333333333,                                                      1,   0.66998697927277292176468378550599851393884522963846,   0.29706838421381835738958471680821941322333209469892,   0.72727272727272727272727272727272727272727272727273,   0.14015279904218876527618748796694671762980646308253,   0.70070103977015073715109985483074933794140704926555,   0.36363636363636363636363636363636363636363636363636,   0.26315789473684210526315789473684210526315789473684,  0.039217224665027085912519664250120864886371431526613,   0.81291750292837676298339315927803650618961237261724,   0.16666666666666666666666666666666666666666666666667,                                                    0.9,  0.064129925745196692331277119389668280948109665161508,   0.20414990928342884892774463430102340502714950524133,   0.39535039104876056561567136982732437235222729745666,   0.60464960895123943438432863017267562764777270254334,   0.79585009071657115107225536569897659497285049475867,   0.93587007425480330766872288061033171905189033483849,   0.16666666666666666666666666666666666666666666666667,   0.81291750292837676298339315927803650618961237261724,  0.039217224665027085912519664250120864886371431526613,   0.36363636363636363636363636363636363636363636363636,   0.70070103977015073715109985483074933794140704926555,   0.14015279904218876527618748796694671762980646308253,   0.29706838421381835738958471680821941322333209469892,   0.66998697927277292176468378550599851393884522963846,   0.33333333333333333333333333333333333333333333333333,   0.55555555555555555555555555555555555555555555555556,   0.11111111111111111111111111111111111111111111111111,                                                      1};
  const double A[] = {
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                                                                              0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0, 0.0024916320485581740753894914880599514945988465358542,  0.023013878785459314963839984637374276877208712263814, -0.0032215595669297709872447609246712087818946360476062, 0.0098844254944766466894633541448788525604081998278601, -0.021301077132888735138430764287592738488663456542957,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            0.3435118942902430010494322347351479430833531749807,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,   0.21045191202362738560909701199901065578880740522563,    1.0342745205723041193648292682882570993866799969832, 0.0060030364586442248705124044820664057493907809240616,   0.85593812509961953757801210600240772891506265261642,  -0.97723500503676681087226485237252563301310765689284,  -0.66002698047929469461622501385632769372057398121997,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                          -0.01435740016721680695382063999350763666577559543784,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0, -0.036625327004903997029368579684897479173311908173355,   0.03502549756362136819768494069798465243467890824711,  0.036094601636211350893178665875833523982368992986424, -0.026521996755368110635159594683460192364962701245746,  0.044569901130569811963891153750883990810433632308223,   0.12434309333135824328622559574178644803897340889511, 0.0041382969323948069440351249620433596042619290867448,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            0.35603240442512029097560911639808917626410622237975,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,  -0.45019275894756259596682177907595617511064510021476,   0.43052790708371089862665629280878291779303015409471,   0.51197302901102223766855696039407169207712578703065,    0.9083036388864042603901591246381102139974962148199,   -1.2392109337193393175737246915153402885441388924861,  -0.64904866167176146514167234887906255390540283196719,   0.25170890458681929221048052994897054140488785293145,   0.77990647034558639881075679528233447602354059341155,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                          0.013093568740651306640688120641883498012747043821319,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0, -9.3205306798511394590846196276710823785863150968467e-05,  0.050537433426229935964009044313859072677094234471612, 8.0447034194448797910957910961019779764131186893087e-07, 0.00059172602949417119052875574277771725984434097192432, -4.0161472215455733706469168490637558773226424795009e-07,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                          0.020792648446605301254194454400076565216725520614437,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0, 0.00058269591880008591510190269783728410895140610302987, -0.0080170073235881593908334218652585274664055846591963, 4.0384764384713694037517082174356057048411729033090e-06,  0.085460999805550614422505611456753560251011462203362, -2.0448648093580424270670756969100430790444283755268e-06,   0.10532857882443189339979940297909399735424090423517,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                              1.401534497957360214154462473557713067184864529176,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,  -0.23025200098422126161627241036741562126113029827446,   -7.2110684046691290565958223710687424716585649350996, 0.0037290156069483633523699532785213234021775956667866,   -4.7141549572712502067877817939222475701132337322182, -0.001763676575453492420538419950327976735749038866956,    7.6413054803869876556302931088023765118517336781394,    3.5060204365975183498989608294974471096821294989338,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            11.951465069412068679937238583071640167447361082655,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,    7.7948093210817596878351670023176438822028427959898,   -56.450139386732579252356099112090428144046810006134,  0.091237630693064490134453044929027664570960745040367,   -12.733627992543488620194552430919927503816271752992, -0.039689592190471971231354281093973667471238307043315,    54.439214188357088699622576515530779186143837842331,   -3.6441163792156923684640699036135064580672147840927,  -0.80450324991050991089903078795857949931569491321079,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            -148.80942650710048842783886826864762556193061208215,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,   -91.729527829125648435793566240232162349522872903635,    707.65614497159835983457571928633571615482112896665,   -1.1056361185748244090529696131159093080133830894264,     176.1345918838113725878598980760556604069995167623,   0.49138482421488066226889834516445455741688463140276,    -684.2780004498149443582375356108950819560771678936,    27.991060499839825898422433212438040744600251840067,    13.193971003028233344367096437115323843506415962374,     1.251287812839804454501149741480560063172688300774,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            -9.6730794694819676364412611843321939583995140857188,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,   -4.4699015085850553144384622770196036049783068140875,     45.51271286909526819682419504000527511789059078174, -0.071308508618382691279149202443824612993055980535239,    11.227361406841274158259062447993938420782680077679,   0.12624437671762272451623791290913880936178688981911,   -43.543933954948331360581062490724210762381430446762,   0.78717430754305897839879299499655090206454609144323,    0.5322646967446842156693007086038866907853957768215,    0.4224227339963253260102251274713887725750865388096,  0.085913124950306710730843803149985944344111505629415,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            -10.066403244705470240339660690042689147220282475797,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0, -0.036625327004903997029368579684897479173311908173355,   0.03502549756362136819768494069798465243467890824711,  0.036094601636211350893178665875833523982368992986424, -0.026521996755368110635159594683460192364962701245746,    -6.270889721814641435905531494788716038393561229574,    48.207923744256298909070210300819506392349259314164, -0.069447168913616564088239518058373283455775416914909,    12.681069020485029569834137091360980706610848381141,   0.01196711689683237548381614355010112941009278139642,    -46.72497649924824080033582682426626955932013216598,    1.3302961332662671131471003929821659139903351119123,    1.0076678750339829835343890361992665777116271779366,  0.020951205193366509166412238847548070289277075386449,  0.021013470633126417731773542433139640742441218844376, 0.0095219601441712179417510154245457590737636023365836,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            -409.47808167774370877258909740937035762442434160675,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,   0.21045191202362738560909701199901065578880740522563,    1.0342745205723041193648292682882570993866799969832, 0.0060030364586442248705124044820664057493907809240616,   0.85593812509961953757801210600240772891506265261642,   -250.51699854744786049277765772931613038658405042078,    1946.4246665238842776605375032826475859582985089576,    -3.045038821023103655061058090868608827869505440976,    490.62637952828171352120826529916808384159854227406,    1.5664758953127090711548406701359744573959561524597,   -1881.9742899401117336221726737703587061921590663845,    75.259222472484717527883771364330314982162061891425,    34.573435698033106762243434473655468969672864479355,    3.2114767944096896143541736184707375516902296674889,  -0.46040804173841439130720140423705884886724509526538, -0.087071833984181052243188413795798624572425204738894,   -7.3935181415830306756701695219552106399918577324913,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            3.4334747585355087892109349625759678112062389107201,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0, 0.0024916320485581740753894914880599514945988465358542,  0.023013878785459314963839984637374276877208712263814, -0.0032215595669297709872447609246712087818946360476062, 0.0098844254944766466894633541448788525604081998278601,    2.1625279937792250778830784190475735404575922533573,   -16.269986454645742132806564066013948900698755204023,  -0.12853450212052455284358341747093501053802903754265,   -8.9891504266650425308930782083337933048651174606355, -0.0034859536323202533338708020185101365019240176725051,    15.793619411333980753623518738869557413585338702514,  -0.57440333091409506562816548201733582014838366319568,  -0.34560203902139329669272249660812498253523722882766, -0.0066224149020658509173161999138375778113306799270742, -0.0077778812924220416403254645860736430975934720962676, -0.0035608419240227491333882723269743736467524081879171,    4.7928250644993079964979774962984018945729693413936,   0.15372546487306857784457638740251208275703427306988,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            32.303852087198544232699473444003153509136497504778,                                                      0,                                                      0,                                                      0,                                                      0, -0.003179876962662050939019128476927124079886091697031,   0.80639771490619207726082171152037950639354311156742,  0.097598312641238897909352285068428885131467204800305,   0.77857557815839890902751244645292723899976346059418,   0.20489042383159942818949920209810560331202923508142,   -1.5626157962746818830707094395052782521146289223642,                                                      0,    16.342989188231057064850424397392717470875335350415,   -154.54455529354362123073018963147103639931668366961,     1.569710887033348726920342834176217614662635935825,    3.2768554508724813132142981726990073116552240497473, -0.050348924519365317634804072719978362653408109569163,    153.32115185804166507059376788591469401122436310259,    7.1756818632772049584676648481478414356782630803487,   -2.9403674867530048194591765989693098921532059438078, -0.066584594607680314447074967602262887028192049319726, -0.046234605499084366122924866856221726117696651401686, -0.020419873358567940153938822861726977884857977482158,   -53.352310643873585051595344116599810797404509049579,   -1.3554871471507865497873218670599640401755450161419,   -1.5719627580123275188290173517145924917768721911444,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            -16.645146748634151287203129440393175876456037113082,                                                      0,                                                      0,                                                      0,                                                      0, 0.0059223278032450330804299000579804652473838956044426,   0.47032615996384111221722430320589411345536253074611,   0.29968886384867900085398183709619239913683112167178,  -0.24765687759399491468999227632981082585395806926395,   0.11089502977143768289399985183906171452244517360068,                                                      0,  -0.49171904384622914707066662870419409767808190721067,   -11.474315442728949696838949256435253635084245413085,    80.259316657623027254170248588648440015279336662359,  -0.38413230398004284762531252675902910374692684134209,    7.2814766746810758347132695092613611576761258186288,  -0.13269938461224837951057170817603527483682734161675,   -81.079983252573072667467928975225524000607071663363,    -1.250374928356206395217681856561791199622537474924,     2.592635949695436810237763795043773249942264473593,  -0.30144029834640453983016399726052687526443153727564,   0.22138446078983233745170645157277379169524683905732,  0.082757727477189293195598987097469315299627643542981,    18.996066204061152046467245003724326399817516141224,   0.26923194640963968562346801512833416746005191034891,    1.6267482744706653746298936492962893398812502928418,   0.49171904384622914707066662870419409767808190721067,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                          0.083847981240905266461696879137281408598053313922491,                                                      0,                                                      0,                                                      0,                                                      0, -0.011794936710097381431975505603129577536796196059074,  -0.24729902056881265233947383874319459832599284035334,  0.097808085836772901225931301408129166550374065547673,   0.21759068924342063136000865176786031834416812002478,                                                      0,   0.13758560676332522486565963219678774664744722297508,  0.043987022971504668505879009234154502604610389029426,                                                      0,  -0.51370081376819334195700445661863030373875736364196,   0.82635569115131550864421130839915345870142315861617,    25.701813971981183262587388297251993951113655634196,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,   -25.701813971981183262587388297251993951113655634196,  -0.82635569115131550864421130839915345870142315861617,   0.51370081376819334195700445661863030373875736364196, -0.043987022971504668505879009234154502604610389029426,  -0.13758560676332522486565963219678774664744722297508,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            0.12438052665409441288151642086879931626849146635967,                                                      0,                                                      0,                                                      0,   0.22612028219758430142223866297920290119675232074263,  0.013788588761808088060769583701647781453096941749149, -0.067221013399668444974939950741430585695008634152538,                                                      0,                                                      0,  -0.85623897508542835475534976987950177211212159741156,   -1.9633752286685890892826285002809381398818044051827,  -0.23233282272411940123724625730892184725010819923042,                                                      0,    4.3066071908645334946166893687656294777243256205348,   -2.9272296324946548265978791120239044668768739495063,   -82.313166639785894445449233410545870773576196642814,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,    82.313166639785894445449233410545870773576196642814,    2.9272296324946548265978791120239044668768739495063,   -4.3066071908645334946166893687656294777243256205348,   0.23233282272411940123724625730892184725010819923042,    1.9633752286685890892826285002809381398818044051827,   0.85623897508542835475534976987950177211212159741156,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            0.10348456163667977667299354651191034449974479820197,                                                      0,                                                      0,   0.12206888730640722258964408286896207713959271483416,   0.48257449033124662247513478012568811286591902385017, -0.038140960001560699973088624000562020566411307247841,                                                      0,  -0.55049952531080232413838850702050817741141431100004,                                                      0,  -0.71191581158518922788764826204379438757829188240675,  -0.58412960567155134043298873015848087209533532964523,                                                      0,                                                      0,    2.1104630812586493212871730004662275030037505427894, -0.083749473673957213552574202300103799269526017533512,     5.100214990723209140752959690433441131075450608628,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,    -5.100214990723209140752959690433441131075450608628,  0.083749473673957213552574202300103799269526017533512,   -2.1104630812586493212871730004662275030037505427894,                                                      0,   0.58412960567155134043298873015848087209533532964523,   0.71191581158518922788764826204379438757829188240675,   0.55049952531080232413838850702050817741141431100004,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,
                            0.19333333333333333333333333333333333333333333333333,                                                      0,                                                   0.22,                                                  -0.08,                                                      0,                                                      0,   0.10999342558072470391946240486506834084511905829585,   -0.2542970480762701613840685069971531221418356269767,                                                      0,   0.86557077711669425434377034382109828183284740123301,    3.3241644911409308310679955278657201833686009293699,                                                      0,                                                      0,     -12.0102223315977933882352385148661841260301942634,   0.47660146624249323943044277686206189960296378200358,   -29.024301122103639052580262321365409959625122133247,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,    29.024301122103639052580262321365409959625122133247,  -0.47660146624249323943044277686206189960296378200358,      12.0102223315977933882352385148661841260301942634,                                                      0,   -3.3241644911409308310679955278657201833686009293699,  -0.86557077711669425434377034382109828183284740123301,    0.2542970480762701613840685069971531221418356269767,  -0.10999342558072470391946240486506834084511905829585,                                                      0,                                                      0,                                                      0,                                                      0,
                          -0.83333333333333333333333333333333333333333333333333,    1.3888888888888888888888888888888888888888888888889,                                                      0,                                                      0,                                                  -0.75,                                                      0,  -0.49252954371802630442268204911402132020021468158066,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,   0.49252954371802630442268204911402132020021468158066,                                                   0.75,                                                      0,                                                      0,                                                      0,
                            0.11111111111111111111111111111111111111111111111111,                                                      0,  -0.22222222222222222222222222222222222222222222222222,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,                                                      0,   0.22222222222222222222222222222222222222222222222222,                                                      0,                                                      0,
                            0.2858351403889715587960888421638364148529275378946,   0.29166666666666666666666666666666666666666666666667,                                                0.21875,                                                      0,                                              0.1640625,                                                      0,   0.21819435494555665832718824158135210709328882432219,   0.18039289847869776686363522194677543771962005364185,                                                      0,   0.20571383940484501885912075512292954227757009498281,   0.24271579158177023997028292795944651576274597138667,   0.24646578081362930583360929118189140779922810386931,   -3.4499194079089082497983415460162266206037046061493,   0.22887556216003608176072906073845858429422037255274,   0.28329059970215141532152741905673333597843659549386,    3.2108512583776664096013149054423678700555732033224,  -0.22353877736484569992023375621416250796412523008367,  -0.70712115720441907351872728620748721213009123195521,    3.2112334515028708040817472920285650089326003444302,    1.4095434830966976603041447430112317576904594557355,  -0.15136205344374261312160227674251811109096302620368,   0.37235057452701427645472408021461998439712102820215,   0.25297874640636133672219990776214128591577572812941,   -3.2108512583776664096013149054423678700555732033224,  -0.28329059970215141532152741905673333597843659549386,  -0.22887556216003608176072906073845858429422037255274,  -0.24646578081362930583360929118189140779922810386931,  -0.24271579158177023997028292795944651576274597138667,  -0.20571383940484501885912075512292954227757009498281,  -0.18039289847869776686363522194677543771962005364185,  -0.21819435494555665832718824158135210709328882432219,                                             -0.1640625,                                               -0.21875,  -0.29166666666666666666666666666666666666666666666667,                                                      0};
  const double b[] = { 0.017857142857142857142857142857142857142857142857143,                                            0.005859375,                                             0.01171875,                                                      0,                                            0.017578125,                                                      0,                                              0.0234375,                                            0.029296875,                                                      0,                                             0.03515625,                                            0.041015625,                                               0.046875,                                                      0,                                            0.052734375,                                             0.05859375,                                            0.064453125,                                                      0,   0.10535211357175301969149603288787816222767308308052,   0.17056134624175218238212033855387408588755548780279,   0.20622939732935194078352648570110489474191428625954,   0.20622939732935194078352648570110489474191428625954,   0.17056134624175218238212033855387408588755548780279,   0.10535211357175301969149603288787816222767308308052,                                           -0.064453125,                                            -0.05859375,                                           -0.052734375,                                              -0.046875,                                           -0.041015625,                                            -0.03515625,                                           -0.029296875,                                             -0.0234375,                                           -0.017578125,                                            -0.01171875,                                           -0.005859375,  0.017857142857142857142857142857142857142857142857143};
  const double bt[] = { 0.017857142857142857142857142857142857142857142857143,                                            0.004859375,                                             0.01171875,                                                      0,                                            0.017578125,                                                      0,                                              0.0234375,                                            0.029296875,                                                      0,                                             0.03515625,                                            0.041015625,                                               0.046875,                                                      0,                                            0.052734375,                                             0.05859375,                                            0.064453125,                                                      0,   0.10535211357175301969149603288787816222767308308052,   0.17056134624175218238212033855387408588755548780279,   0.20622939732935194078352648570110489474191428625954,   0.20622939732935194078352648570110489474191428625954,   0.17056134624175218238212033855387408588755548780279,   0.10535211357175301969149603288787816222767308308052,                                           -0.064453125,                                            -0.05859375,                                           -0.052734375,                                              -0.046875,                                           -0.041015625,                                            -0.03515625,                                           -0.029296875,                                             -0.0234375,                                           -0.017578125,                                            -0.01171875,                                           -0.004859375,  0.017857142857142857142857142857142857142857142857143};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;
}

/** @brief Get Runge-Kutta Ssc Butcher tableau.
 * Solving Stiff Systems of ODEs by Explicit Methods with Conformed Stability Domains
 * From:  Anton E. Novikov     Mikhail V. Rybkov     Yury V. Shornikov     Lyudmila V. Knaub
 * EUROSIM 2016 & SIMS 2016
 *
 * @param tableau    Pointer to Butcher tableau to fill.
 */
void getButcherTableau_RKSSC(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 1;
  tableau->order_bt = 2;
  tableau->fac = 1e0;

  const double c[] = {                              0,               0.041324301621055,                    0.1611647763,                    0.3608883044,                      0.64049984};
  const double A[] = {
                                                        0,                                0,                                0,                                0,                                0,
                                        0.041324301621055,                                0,                                0,                                0,                                0,
                                        0.0805823881610573,               0.0805823881610573,                                0,                                0,                                0,
                                        0.1191668151228434,               0.1597820013984078,               0.0819394878966193,                                0,                                0,
                                        0.1570787892802991,                0.237958302195982,               0.1631711307360486,               0.0822916178203657,                                0};
  const double b[] = {             0.1945277188657676,              0.3151822878089125,              0.2437005934695969,              0.1641555613805598,              0.0824338384751631};
  const double bt[] = {         0.12149281854707711872,          0.18276003767888932578,          0.14735209191059650291,         -0.42005655782840578172,          0.96845160969184283432};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
}

/**
 * @brief Analyse Butcher tableau and return size and if the method is explicit.
 *
 * Sets error_order
 *
 * @param tableau       Butcher tableau. error_order will be set after return.
 * @param nStates       Number of states of ODE/DAE system.
 * @param nlSystemSize  Contains size of internal non-linear system on return.
 * @param GM_TYPE       Contains Runge-Kutta method type on return.
 */
void analyseButcherTableau(BUTCHER_TABLEAU* tableau, int nStates, unsigned int* nlSystemSize, enum GM_TYPE* GM_type)
{
  modelica_boolean isGenericIRK = FALSE;  /* generic implicit Runge-Kutta method */
  modelica_boolean isDIRK = FALSE;        /* diagonal something something Runge-Kutta method */
  int i, j, l;

  for (i=0; i<tableau->nStages; i++) {
    /* Check if values on diagonal are non-zero (= dirk method) */
    if (fabs(tableau->A[i*tableau->nStages + i])>0) {    // This assumes that A is saved in row major format
      isDIRK = TRUE;
    }
    /* Check if values above diagonal are non-zero (= implicit method) */
    for (j=i+1; j<tableau->nStages; j++) {
      if (fabs(tableau->A[i * tableau->nStages + j])>0) {    // This assumes that A is saved in row major format
        isGenericIRK = TRUE;
        break;
      }
    }
  }
  if (isGenericIRK) {
    *GM_type = GM_TYPE_IMPLICIT;
    *nlSystemSize = tableau->nStages*nStates;
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Chosen RK method is fully implicit");
  } else if (isDIRK) {
    *GM_type = GM_TYPE_DIRK;
    *nlSystemSize = nStates;
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Chosen RK method diagonally implicit");
  } else {
    *GM_type = GM_TYPE_EXPLICIT;
    *nlSystemSize = 0;
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Chosen RK method is explicit");
  }

  if (tableau->richardson) {
    tableau->fac = 1.0;
    tableau->order_bt = tableau->order_b + 1;
  }
  // set order for error control!
  tableau->error_order = fmin(tableau->order_b, tableau->order_bt) + 1;
}

/**
 * @brief Allocate memory and initialize Butcher tableau for given method.
 *
 * @param method              Runge-Kutta method.
 * @param flag                Flag specifying error estimation.
 *                            Allowed values: FLAG_SR_ERR, FLAG_MR_ERR
 * @return BUTCHER_TABLEAU*   Return pointer to Butcher tableau on success, NULL on failure.
 */
BUTCHER_TABLEAU* initButcherTableau(enum GB_METHOD method, enum _FLAG flag)
{
  BUTCHER_TABLEAU* tableau = (BUTCHER_TABLEAU*) malloc(sizeof(BUTCHER_TABLEAU));
  enum GB_EXTRAPOL_METHOD extrapolMethod;

  assertStreamPrint(NULL, flag==FLAG_SR_ERR || flag==FLAG_MR_ERR, "Illegal input 'flag' to initButcherTableau!");

  extrapolMethod = getGBErr(flag);
  tableau->richardson = extrapolMethod == GB_EXT_RICHARDSON;
  if (tableau->richardson) {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Richardson extrapolation is used for step size control");
  }

  switch(method)
  {
    case MS_ADAMS_MOULTON:
      getButcherTableau_MS(tableau);
      break;
    case RK_IMPL_EULER:
      getButcherTableau_IMPLEULER(tableau);
      break;
    case RK_TRAPEZOID:
      getButcherTableau_TRAPEZOID(tableau);
      break;
    case RK_RUNGEKUTTA:
      getButcherTableau_RUNGEKUTTA(tableau);
      break;
    case RK_TSIT5:
      getButcherTableau_TSIT5(tableau);
      break;
    case RK_DOPRI45:
      getButcherTableau_DOPRI45(tableau);
      break;
    case RK_DOPRISSC1:
      getButcherTableau_DOPRISSC1(tableau);
      break;
    case RK_DOPRISSC2:
      getButcherTableau_DOPRISSC2(tableau);
      break;
    case RK_RKSSC:
      getButcherTableau_RKSSC(tableau);
      break;
    case RK_RK810:
      getButcherTableau_RK810(tableau);
      break;
    case RK_RK1012:
      getButcherTableau_RK1012(tableau);
      break;
    case RK_RK1214:
      getButcherTableau_RK1214(tableau);
      break;
    case RK_MERSON:
      getButcherTableau_MERSON(tableau);
      break;
    case RK_MERSONSSC1:
      getButcherTableau_MERSONSSC1(tableau);
      break;
    case RK_MERSONSSC2:
      getButcherTableau_MERSONSSC2(tableau);
      break;
    case RK_EXPL_EULER:
      getButcherTableau_EXPLEULER(tableau);
      break;
    case RK_HEUN:
      getButcherTableau_HEUN(tableau);
      break;
    case RK_FEHLBERG12:
      getButcherTableau_FEHLBERG12(tableau);
      break;
    case RK_FEHLBERG45:
      getButcherTableau_FEHLBERG45(tableau);
      break;
    case RK_FEHLBERG78:
      getButcherTableau_FEHLBERG78(tableau);
      break;
    case RK_FEHLBERGSSC1:
      getButcherTableau_FEHLBERGSSC1(tableau);
      break;
    case RK_FEHLBERGSSC2:
      getButcherTableau_FEHLBERGSSC2(tableau);
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
    case RK_ESDIRK3:
      getButcherTableau_ESDIRK3(tableau);
      break;
    case RK_ESDIRK4:
      getButcherTableau_ESDIRK4(tableau);
      break;
    case RK_RADAU_IA_2:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IA_2(tableau);
      break;
    case RK_RADAU_IA_3:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IA_3(tableau);
      break;
    case RK_RADAU_IA_4:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IA_4(tableau);
      break;
    case RK_RADAU_IIA_2:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IIA_2(tableau);
      break;
    case RK_RADAU_IIA_3:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IIA_3(tableau);
      break;
    case RK_RADAU_IIA_4:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IIA_4(tableau);
      break;
    case RK_LOBA_IIIA_3:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_LOBATTO_IIIA_3(tableau);
      break;
    case RK_LOBA_IIIA_4:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_LOBATTO_IIIA_4(tableau);
      break;
    case RK_LOBA_IIIB_3:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_LOBATTO_IIIB_3(tableau);
      break;
    case RK_LOBA_IIIB_4:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_LOBATTO_IIIB_4(tableau);
      break;
    case RK_LOBA_IIIC_3:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_LOBATTO_IIIC_3(tableau);
      break;
    case RK_LOBA_IIIC_4:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_LOBATTO_IIIC_4(tableau);
      break;
    case RK_GAUSS2:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_GAUSS2(tableau);
      break;
    case RK_GAUSS3:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_GAUSS3(tableau);
      break;
    case RK_GAUSS4:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_GAUSS4(tableau);
      break;
    case RK_GAUSS5:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_GAUSS5(tableau);
      break;
    case RK_GAUSS6:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_GAUSS6(tableau);
      break;
    default:
      throwStreamPrint(NULL, "Error: Unknown Runge Kutta method %i.", method);
  }

  return tableau;
}

/**
 * @brief Free Butcher Tableau memory.
 *
 * @param tableau   Butcher tableau.
 */
void freeButcherTableau(BUTCHER_TABLEAU* tableau)
{
  free(tableau->c);
  free(tableau->A);
  free(tableau->b);
  free(tableau->bt);
  free(tableau->b_dt);

  free(tableau);
}

/**
 * @brief Print given Butcher tableau
 *
 * Prints into OMC_LOG_SOLVER stream if it is active.
 * c | A
 * --|---
 *   | b
 *   | b^t
 *
 * @param tableau   Butcher tableau.
 */
void printButcherTableau(BUTCHER_TABLEAU* tableau)
{
  if (omc_useStream[OMC_LOG_SOLVER]) {
    int i, j;
    char buffer[1024];
    int buffSize = 1024;
    int ct;
    const char* line = "----------";
    infoStreamPrint(OMC_LOG_SOLVER, 1, "Butcher tableau of gbode method:");
    for (i = 0; i<tableau->nStages; i++) {
      ct = snprintf(buffer, buffSize, "%10g | ", tableau->c[i]);
      for (j = 0; j<tableau->nStages; j++) {
        ct += snprintf(buffer+ct, buffSize-ct, "%10g", tableau->A[i*tableau->nStages + j]);
      }
      infoStreamPrint(OMC_LOG_SOLVER, 0, "%s", buffer);
    }
    ct = snprintf(buffer, buffSize, "%s | ", line);
      for (j = 0; j<tableau->nStages; j++) {
        ct += snprintf(buffer+ct, buffSize-ct, "%s", line);
      }
    infoStreamPrint(OMC_LOG_SOLVER, 0, "%s", buffer);
    ct = snprintf(buffer, buffSize, "%10s | ", "");
    for (j = 0; j<tableau->nStages; j++) {
      ct += snprintf(buffer+ct, buffSize-ct, "%10g", tableau->b[j]);
    }
    infoStreamPrint(OMC_LOG_SOLVER, 0, "%s", buffer);
    ct = snprintf(buffer, buffSize, "%10s | ", "");
    for (j = 0; j<tableau->nStages; j++) {
      ct += snprintf(buffer+ct, buffSize-ct, "%10g", tableau->bt[j]);
    }
    infoStreamPrint(OMC_LOG_SOLVER, 0, "%s", buffer);
    messageClose(OMC_LOG_SOLVER);
  }
}
