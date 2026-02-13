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
  tableau->t_transform = NULL;
}

void setStageValuePredictors(BUTCHER_TABLEAU *tableau, const double *A_pred, const STAGE_VALUE_PREDICTOR_TYPE *type, gb_dense_output dense_output_pred)
{
  tableau->svp = (STAGE_VALUE_PREDICTORS *) malloc(sizeof(STAGE_VALUE_PREDICTORS));

  int stages = tableau->nStages;
  tableau->svp->nStages = stages;

  tableau->svp->A_predictor = (double *) malloc(stages * stages * sizeof(double));
  memcpy(tableau->svp->A_predictor, A_pred, stages * stages * sizeof(double));

  tableau->svp->dense_output_predictor = dense_output_pred;

  tableau->svp->type = (STAGE_VALUE_PREDICTOR_TYPE *) malloc(stages * sizeof(STAGE_VALUE_PREDICTOR_TYPE));
  memcpy(tableau->svp->type, type, stages * sizeof(STAGE_VALUE_PREDICTOR_TYPE));
}

void setTTransform(BUTCHER_TABLEAU *tableau, const double *A_part_inv, const double *T, const double *T_inv, const double *gamma, const double *alpha, const double *beta,
                   modelica_boolean f_row_zero, modelica_boolean l_col_zero, int n_real_eigs, int n_cmplx_eigs, const double *phi, const double *rho)
{
  tableau->t_transform = (T_TRANSFORM *) malloc(sizeof(T_TRANSFORM));

  T_TRANSFORM *tr = tableau->t_transform;
  tr->firstRowZero = f_row_zero;
  tr->lastColumnZero = l_col_zero;
  tr->nRealEigenvalues = n_real_eigs;
  tr->nComplexEigenpairs = n_cmplx_eigs;
  tr->size = n_real_eigs + 2 * n_cmplx_eigs;
  assert(tr->size == tableau->nStages - (int)f_row_zero - (int)l_col_zero);

  tr->A_part_inv = (double *) malloc(tr->size * tr->size * sizeof(double));
  tr->T = (double *) malloc(tr->size * tr->size * sizeof(double));
  tr->T_inv = (double *) malloc(tr->size * tr->size * sizeof(double));
  tr->gamma = (double *) malloc(n_real_eigs * sizeof(double));
  tr->alpha = (double *) malloc(n_cmplx_eigs * sizeof(double));
  tr->beta = (double *) malloc(n_cmplx_eigs * sizeof(double));

  if (phi)
  {
    tr->phi = (double *) malloc(tr->size * sizeof(double));
    memcpy(tr->phi, phi, tr->size * sizeof(double));
  }
  else
  {
    tr->phi = NULL;
  }

  if (rho)
  {
    tr->rho = (double *) malloc(tr->size * sizeof(double));
    memcpy(tr->rho, rho, tr->size * sizeof(double));
  }
  else
  {
    tr->rho = NULL;
  }

  memcpy(tr->A_part_inv, A_part_inv, tr->size * tr->size * sizeof(double));
  memcpy(tr->T, T, tr->size * tr->size * sizeof(double));
  memcpy(tr->T_inv, T_inv, tr->size * tr->size * sizeof(double));
  memcpy(tr->gamma, gamma, n_real_eigs * sizeof(double));
  memcpy(tr->alpha, alpha, n_cmplx_eigs * sizeof(double));
  memcpy(tr->beta, beta, n_cmplx_eigs * sizeof(double));
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

  // predictor cant be stable for stage 2
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

  const double A_predictor[] = {
                                0, 0,     0, 0,
                                0, 0,     0, 0,
                                0.3, 0.3, 0, 0,  // order 1, R_int(-inf) = -0.37657 => strongly A-stable
                                0.5333190407494745800028006, 0.8095865780886579710085016, -0.3429056188381325309677550, 0.0 // order 2, R_int(-inf) = -0.95666 => strongly A-stable
                               };

  const STAGE_VALUE_PREDICTOR_TYPE svp_type[] = {SVP_NOT_AVAILABLE, SVP_NOT_AVAILABLE, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION};

  setStageValuePredictors(tableau, A_predictor, svp_type, NULL);
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
  const double bt[] = {-0.09651334216818033766775798, -0.09651334216818033766775798, 0.5228199509962342402149691, 0.5205678646221884951929862, -0.08255805440762121384324234, 0.232196923125559153770803};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_ESDIRK4;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;

  const double A_predictor[] = {
                                0, 0, 0, 0, 0, 0,
                                0, 0, 0, 0, 0, 0,
                                0.07322330470336311889978890, 0.07322330470336311889978890, 0, 0, 0, 0, /* order 1, R(-inf) = sqrt(2) - 1 => strongly A-stable */
                                0.5011104345603980506876319, 0.5011104345603980506876319, -0.3772208691207961013752639, 0, 0, 0, /* order 2, R(-inf) = -0.875 => strongly A-stable */
                                2.755721730042486125344791, 2.755721730042486125344791, -4.090643460084972250689581, -0.3808, 0, 0, /* order 2, R(-inf) = 0 => L-stable */
                                0.3245695011190811847458344, 0.3245695011190811847458344, -0.1203242647439138855925758, 0.3245695011190811847458344, 0.1466157613866703313550725, 0, /* order 2, R(-inf) = 0 => L-stable, minimizes infinity norm over all order 2 L-stable methods */
                               };

  const STAGE_VALUE_PREDICTOR_TYPE svp_type[] = {SVP_NOT_AVAILABLE, SVP_NOT_AVAILABLE, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION};

  setStageValuePredictors(tableau, A_predictor, svp_type, NULL);
}

/* Dense Output from "Intrastep, Stage-Value Predictors for Diagonally-Implicit Runge–Kutta Methods"
 *  => I noticed that this dense output is used as extrapolation only. So it is not used for having a continuous
 *     solution but rather as a stable, low order extrapolation for guesses of the stage 2 system in the next iteration!
 */
void predictor_denseOutput_ESDIRK4_7L2SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (-27.59333059022041759502043 * dt + 64.65274650435436557321524) * dt - 37.46026752914355622243673;
  tableau->b_dt[1] = tableau->b_dt[0];
  tableau->b_dt[2] = (48.80073718304123520372254 * dt - 113.4655885884012189742302) * dt + 65.60400381988389248115137;
  tableau->b_dt[3] = (6.195923997399599986313684 * dt - 20.18211580148779384670407) * dt + 14.50473408798312502327690;
  tableau->b_dt[4] = (-2.0 * dt + 3.84221138118028167447597) * dt - 1.066701349013079462428321;
  tableau->b_dt[5] = (1.94 * dt + 1.5) * dt - 3.996501500566825597103974;
  tableau->b_dt[6] = (0.25 * dt - 1.0) * dt + 0.875;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* Real dense output of the ESDIRK4(3)7L2SA
 *  => Quartic C1 interpolant (order 4), remaining 2 degrees of freedom are chosen to minimize the error
 *     (see e.g. https://github.com/WRKampi/extensisq for numeric values, MIT license)
 */
void denseOutput_ESDIRK4_7L2SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((2.940701270662915 * dt + (-4.079699311306614)) * dt + (-0.2618535743659094)) * dt + 1.0;
  tableau->b_dt[1] = ((9.138591896250813 * dt + (-17.47548056248241)) * dt + 7.936037051221989) * dt;
  tableau->b_dt[2] = ((-8.276798249263065 * dt + 14.67529166947831) * dt + (-5.459341005691339)) * dt;
  tableau->b_dt[3] = ((-3.271794891939533 * dt + 5.506505216089204) * dt + (-1.71616804025474)) * dt;
  tableau->b_dt[4] = ((-3.684277016082155 * dt + 5.817533967829905) * dt + (-1.357746919580548)) * dt;
  tableau->b_dt[5] = ((2.144128340407973 * dt + (-3.175253679682295)) * dt + 0.4746238387074965) * dt;
  tableau->b_dt[6] = ((1.009448649963051 * dt + (-1.268897299926103)) * dt + 0.3844486499630515) * dt;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* 7 stage, L-stable, 4(3) ESDIRK method with stage-value predictor */
void getButcherTableau_ESDIRK4_7L2SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac      = 1.0;

  /* method from "Diagonally implicit Runge–Kutta methods for stiff ODEs" */
  const double c[] = { 0.0, 0.25, 0.07322330470336312069346008, 0.5, 0.6966490299823633325360106, 0.7063492063492063932628184, 1.0 };

  const double A[] = {
                      0, 0, 0, 0, 0, 0, 0,
                      0.125, 0.125, 0, 0, 0, 0, 0,
                      -0.02588834764831843965326996, -0.02588834764831843965326996, 0.125, 0, 0, 0, 0,
                      0.3383883476483184327143761, 0.3383883476483184327143761, -0.3017766952966368654287521, 0.125, 0, 0, 0,
                      -0.3592453618381594160346992, -0.3592453618381594160346992, 0.93650786004636443760063, 0.3536318936123176159824766, 0.125, 0, 0,
                      0.2336106109124456153836036, 0.2336106109124456153836036, -0.04331537381018980142899366, 0.01903274535895701016774417, 0.1384106129755478808984748, 0.125, 0,
                      -0.4008516150096082530929209, -0.4008516150096082530929209, 0.9391524145239087406622502, 0.5185422838949311774570106, 0.7755100321672021568275568, -0.5565015005668255687609758, 0.125
                     };

  const double b[] = { -0.4008516150096082530929209, -0.4008516150096082530929209, 0.9391524145239087406622502, 0.5185422838949311774570106, 0.7755100321672021568275568, -0.5565015005668255687609758, 0.125 };

  const double bt[] = { -0.2421068937666858433832573, -0.2421068937666858433832573, 0.6587096818817366195020213, 0.5004777357240689505957221, 0.7607872310157867135060883, -0.5714751468025063285693932, 0.1357142857142857039765005 };

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_ESDIRK4_7L2SA;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = FALSE;

  /* SVP from "Intrastep, Stage-Value Predictors for Diagonally-Implicit Runge–Kutta Methods" (properties of paper can be reproduced) */
  const double A_predictor[] = {
                                0, 0, 0, 0, 0, 0, 0,
                                0, 0, 0, 0, 0, 0, 0,
                                0.03661165235168154462996192, 0.03661165235168154462996192, 0, 0, 0, 0, 0, /* order 1, R(-inf) = sqrt(2) - 1 => strongly A-stable */
                                0.8535533905932738214801523, 0.8535533905932738214801523, -1.207106781186547581023924, 0, 0, 0, 0, /* order 2, R(-inf) = 1 => A-stable */
                                -0.9517714576323296493843248, -0.9517714576323296493843248, 1.920191945247022028907364, 0.68, 0, 0, 0, /* order 2, R(-inf) = -0.05615 => strongly A-stable */
                                -0.2103336111576326549491873, -0.2103336111576326549491873, 0.6941969710616575148587203, 0.2558194576028144989674432, 0.177, 0, 0, /* order 2, R(-inf) = 0 => L-stable! */
                                -1.489680406763977982227047, -1.489680406763977982227047, 2.936560813527956077505104, 0.3579, 0.5498, 0.1351, 0, /* order 2, R(-inf) = 1e-7 => strongly A-stable */
                               };

  const STAGE_VALUE_PREDICTOR_TYPE svp_type[] = {SVP_NOT_AVAILABLE, SVP_DENSE_OUTPUT, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION};

  setStageValuePredictors(tableau, A_predictor, svp_type, predictor_denseOutput_ESDIRK4_7L2SA);
}

// 3-stage order 3(2), L-stable SDIRK, embedded bt might be bad, dense output missing
void getButcherTableau_SDIRK3(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  const double c[] = {0.4358665215084589994160194, 0.7179332607542294997080097,                               1};
  const double A[] = {
                      0.4358665215084589994160194,                           0,                           0,
                      0.2820667392457705002919903, 0.4358665215084589994160194,                           0,
                      1.2084966491760100703364772, -0.644363170684469069752496, 0.4358665215084589994160194};

  const double b[] = {1.2084966491760100703364772, -0.644363170684469069752496, 0.4358665215084589994160194};
  const double bt[] = {0.0, 1.7726301276675510709204584, -0.7726301276675510709204578};

  setButcherTableau(tableau, c, A, b, bt);

  const double A_predictor[] = {
                                0, 0, 0,
                                0.7179332607542294997080097,                            0,  0,  // order 1, R(-inf) = 0 => L-stable
                                0.7726301276675510709204581,  0.2273698723324489290795419,  0,  // order 2, R(-inf) = 0 => L-stable
                               };

  const STAGE_VALUE_PREDICTOR_TYPE svp_type[] = {SVP_NOT_AVAILABLE, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION};

  setStageValuePredictors(tableau, A_predictor, svp_type, NULL);
}

void denseOutput_SDIRK4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (((-20./9.  * dt +  217./36.)   * dt -  463./72.)    * dt + 11./3.);
  tableau->b_dt[1] = (((-10.     * dt +  661./24.)   * dt -  385./16.)    * dt + 11./2.);
  tableau->b_dt[2] = (((250./27. * dt -  8875./216.) * dt +  20125./432.) * dt - 125./18.);
  tableau->b_dt[3] = ((                  85./6.      * dt -  85./4.)      * dt);
  tableau->b_dt[4] = ((( 80./27. * dt -  359./54.)   * dt +  557./108.)    * dt - 11./9.);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// L-stable, SDIRK, order 4(3), 5 stages, gamma = 0.25
// also implemented in Hairer and Wanner legacy Fortran code `SDIRK4`
void getButcherTableau_SDIRK4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac = 1.0;

  const double c[] = {0.25, 0.75, 0.55, 0.5, 1.0};
  const double A[] = {
                          0.25,       0.0,         0.0,      0.0,      0.0,
                          0.5,        0.25,        0.0,      0.0,      0.0,
                          17./50.,    -1./25.,     0.25,     0.0,      0.0,
                          371./1360., -137./2720., 15./544., 0.25,     0.0,
                          25./24.,    -49./48.,    125./16., -85./12., 0.25};
  const double b[]  = {25./24., -49./48., 125./16., -85./12., 0.25};
  const double bt[] = {59./48., -17./96., 225./32., -85./12., 0.0};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SDIRK4;
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;

  const double A_predictor[] = {
                                0, 0, 0, 0, 0,
                                0, 0, 0, 0, 0,
                                0.275, 0.275, 0, 0, 0, /* order 1, R(-inf) = 1 => A-stable */
                                0.1875, -0.46875, 0.78125, 0, 0, /* order 2, R(-inf) = 0 => L-stable */
                                1.03125, 1.03125, 0, -1.0625, 0, /* order 2, R(-inf) = 0 => L-stable */
                               };

  const STAGE_VALUE_PREDICTOR_TYPE svp_type[] = {SVP_NOT_AVAILABLE, SVP_NOT_AVAILABLE, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION};

  setStageValuePredictors(tableau, A_predictor, svp_type, NULL);
}

// 2 stage, L-stable, order 2(1), SDIRK with gamma = 0.29289
void getButcherTableau_SDIRK2(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 2;
  tableau->order_b = 2;
  tableau->order_bt = 1;
  tableau->fac = 1.0;

  /* Butcher Tableau */
  const double c[] = {0.29289321881345247559915563789, 1.0};
  const double A[] = {0.29289321881345247559915563789, 0.0,
                      0.707106781186547524400844362104849, 0.29289321881345247559915563789};
  const double b[] = {0.707106781186547524400844362104849, 0.29289321881345247559915563789};
  const double bt[] = {0.25, 0.75};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;

  // predictor cant be stable for stage 2
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

void denseOutput_Radau_IA_2(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = 1.0 - 0.75*dt;
  tableau->b_dt[1] = 0.75*dt;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IA_2;

  const double T[] = {
      -0.3333333333333333333333333333333333333333, -0.9428090415820633658677924828064653857131,
      1.0, 0.0,
  };

  const double T_inv[] = {
      0.0, 1.0,
      -1.060660171779821286601266543157273558927, -0.3535533905932737622004221810524245196424,
  };

  const double *gamma = NULL;
  const double alpha[] = { 2.0 };
  const double beta[] = { -1.41421356237309504880168872420969807857 };

  const double A_part_inv[] = {
      2.5, 1.5,
      -1.5, 1.5,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 1, NULL, NULL);
}

void denseOutput_Radau_IA_3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(1.111111111111111111111111*dt - 2.0) + 1.0;
  tableau->b_dt[1] = dt*(2.428869016623520557281749 - 1.916383190435098943442936*dt);
  tableau->b_dt[2] = dt*(0.8052720793239878323318245*dt - 0.428869016623520557281749);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IA_3;

  const double T[] = {
      0.424293819848497965354371036408369014402, -0.3235571519651980681202894497035499844, 0.522137786846287839586599927945046950886,
      0.05759460949980612889629158542933523690317, 0.003148663231849760131614374283781867410255, -0.4524292476743597785777285103817324145978,
      1.0, 1.0, 0.0,
  };

  const double T_inv[] = {
      1.233523612685027760114769983066164237455, 1.423580134265707095505388133369554087793, 0.3946330125758354736049045150429623937006,
      -1.233523612685027760114769983066164237455, -1.423580134265707095505388133369554087793, 0.6053669874241645263950954849570376062994,
      0.1484438963257383124456490049673412705421, -2.03897479493989610968207047178531547655, 0.05445012928926867352993558316925400219062,
  };

  const double gamma[] = { 3.637834252744495732208418513577775797946 };
  const double alpha[] = { 2.681082873627752133895790743211112101027 };
  const double beta[] = { -3.050430199247410569426377624787567904441 };

  const double A_part_inv[] = {
      5.0, 4.857738033247041114563498087156873290627, -0.857738033247041114563498087156873290627,
      -1.632993161855452065464856049803927594644, 0.7752551286084109509013579626470543040172, 0.8577380332470411145634980871568732906269,
      1.632993161855452065464856049803927594644, -4.857738033247041114563498087156873290626, 3.224744871391589049098642037352945695983,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 1, 1, NULL, NULL);
}

void denseOutput_Radau_IA_4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(5.0 - 2.1875*dt) - 3.75) + 1.0;
  tableau->b_dt[1] = dt*(dt*(4.45320279122433889741358*dt - 8.917955266981970717009466) + 4.793596795737691563540175);
  tableau->b_dt[2] = dt*(dt*(5.226981759397764219465792 - 3.488522646142565190862877*dt) - 1.350265644412027147822682);
  tableau->b_dt[3] = dt*(dt*(1.222819854918226293449297*dt - 1.309026492415793502456326) + 0.3066688486743355842825069);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// TODO: Describe me
void getButcherTableau_RADAU_IA_4(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IA_4;

  const double T[] = {
      0.4596810142815956455308121716669939327617, 0.1399487775423729845360368598977359444425, -0.1244200895100983358061251873386804058926, -0.1753809052622923798882653257620600100744,
      -0.2912293126476195093651071608956069810829, 0.0, 0.0572125318878470286026075375380116821287, 0.01056535127722349801603696476943187929979,
      0.3405537054979965130441822541024432834589, -0.3949691005204159378079550283159342199022, 0.1573735208178755115678079780871490628484, -0.1313955561093213295646768821774711762092,
      1.0, 0.6318461245268408380546926958693830110734, 1.0, 0.0,
  };

  const double T_inv[] = {
      -0.2838802337480674984008318103996664659889, -3.285479728790676599552866968576976152613, 0.1147293361991207033850265456189706930225, 0.1345948500784760351393457728368935398759,
      1.24808182996096621499119816828424477612, 1.270102290454182816966533940406804613162, -1.563756419222931720714249553293717683651, 0.328714538600899775259530084628955888896,
      -0.5047154336051365530937773542884424581718, 2.482970518814537231947094666425822929513, 0.8733240969908585386817372570066286580769, 0.6577081426309168159531893796896226327998,
      -5.09194593702242144137000294311631453467, -9.359370126275934829659807517276652291987, -1.566681181856267151030109472634035397665, 0.1484870261226446416736623853207948772257,
  };

  const double gamma[] = {  };
  const double alpha[] = { 3.212806896871533982914109940306805502411, 4.787193103128466017085890059693194497589 };
  const double beta[] = { -4.773087433276642499827429345261277978816, -1.567476416895208124112099648396772661243 };

  const double A_part_inv[] = {
      8.5, 9.587193591475383127080350958152541085909, -2.700531288824054295645364844598573226012, 0.6133376973486711685650138864460321401041,
      -2.313357087542357488622512389828233777221, 0.63479209515521873889236075248215867637, 2.071362217177840932628172737279989617223, -0.3927972247907021828980210999339145163721,
      1.061847731699696823886930479457823709979, -3.375342923186382293532331878083728931248, 1.221100028894691785921766123178559987957, 1.092395162591993683723635275447345233311,
      -1.962776358443053620978703803915304218474, 5.209408237612634665779116203558318805905, -8.890739755119670519986285523982295923106, 5.644107875950089475185873124339281335674,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 2, NULL, NULL);
}

void denseOutput_Radau_IIA_2(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = 1.5 - 0.75*dt;
  tableau->b_dt[1] = 0.75*dt - 0.5;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* 2-step, order 3(1), L-stable Radau IIA */
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IIA_2;

  const double T[] = {
      0.1111111111111111111111111111111111111111, -0.3142696805273544552892641609354884619044,
      1.0, 0.0,
  };

  const double T_inv[] = {
      0.0, 1.0,
      -3.181980515339463859803799629471820676782, 0.3535533905932737622004221810524245196425,
  };

  const double gamma[] = {  };
  const double alpha[] = { 2.0 };
  const double beta[] = { -1.41421356237309504880168872420969807857 };

  const double A_part_inv[] = {
      1.5, 0.5,
      -4.5, 2.5,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 1, NULL, NULL);
}

void denseOutput_Radau_IIA_3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(0.8052720793239878323318245*dt - 1.986947221348442939713724) + 1.558078204724922382431975;
  tableau->b_dt[1] = dt*(3.320280554681776273047058 - 1.916383190435098943442936*dt) - 0.8914115380582557157653087;
  tableau->b_dt[2] = dt*(1.111111111111111111111111*dt - 1.333333333333333333333333) + 0.3333333333333333333333333;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// TODO: use embedded method / error estimate from Hairer `Solving ODEs II` pp. 123 (use LU solve to get better error estimate for stiff problems)
/* 3-step, order 5(2), L-stable Radau IIA */
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IIA_3;

  const double T[] = {
      0.09443876248897524148749007950641658628684, -0.1412552950209542084279903838077973094093, 0.03002919410514742449186111708905386666835,
      0.2502131229653333113765090675125016843586, 0.2041293522937999319959908102983381740865, -0.3829421127572619377954382335998732103578,
      1.0, 1.0, 0.0,
  };

  const double T_inv[] = {
      4.17871859155190472734646265851205623, 0.3276828207610623870825332724296162342454, 0.52337644549944954803993091590898750206,
      -4.17871859155190472734646265851205623, -0.3276828207610623870825332724296162342454, 0.47662355450055045196006908409101249794,
      0.5028726349457868759512473431395442928592, -2.571926949855605429186785353601675054695, 0.5960392048282249249688219110993024032899,
  };

  const double gamma[] = { 3.637834252744495732208418513577775797946 };
  const double alpha[] = { 2.681082873627752133895790743211112101027 };
  const double beta[] = { -3.050430199247410569426377624787567904441 };

  const double A_part_inv[] = {
      3.224744871391589049098642037352945695983, 1.167840084690405494924041272215695012234, -0.2531972647421808261859424199215710378575,
      -3.567840084690405494924041272215695012233, 0.7752551286084109509013579626470543040171, 1.053197264742180826185942419921571037858,
      5.531972647421808261859424199215710378576, -7.531972647421808261859424199215710378577, 5.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 1, 1, NULL, NULL);
}

void denseOutput_Radau_IIA_4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(3.582252927257111671340863 - 1.222819854918226293449297*dt) - 3.716508500936312837609313) + 1.577537639774195834993226;
  tableau->b_dt[1] = dt*(dt*(3.488522646142565190862877*dt - 8.727108825172496543985716) + 6.600456243074125634602569) - 0.9736765952010224006994974;
  tableau->b_dt[2] = dt*(dt*(8.894855897915384872644852 - 4.45320279122433889741358*dt) - 4.758947742137812796993255) + 0.6461389554268265657062718;
  tableau->b_dt[3] = dt*(dt*(2.1875*dt - 3.75) + 1.875) - 0.25;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* 4-step, order 7(3), L-stable Radau IIA */
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IIA_4;

  const double T[] = {
      0.07123402525218481887381633748646685662888, 0.03545885592224043673823296558715169925362, -0.01178089927329709192120307304120022451655, -0.03545032992850723496445567647562283269565,
      -0.1994810827230478943203809451008415140774, 0.0, 0.04634447901554471411288231518543351472243, -0.03220730760558414029133566082066998549373,
      0.2263428533849796285405132956577294710278, -0.4781476917330068561879375571176378807926, 0.3368476074591732346912783221942524204093, -0.1260666211747527339910021827677285012458,
      1.0, -0.1515563106538475731161345101479080696596, 1.0, 0.0,
  };

  const double T_inv[] = {
      2.486335101864526740662016402488078062952, -3.292076411161209112171217869193786806831, 0.1418894057344082618334775030181480926074, 0.1340657227039199440994862543062892653211,
      4.658362365094468791965671611950347346486, 2.442479726346917144352967828054658539109, -1.933947117516822965233867603497682772791, 0.5931297068662242041622614981917761067601,
      -1.78033088812207732202898659959643861105, 3.662249627333167095902383128195239777126, -0.4349912958649009426908992476664027339523, 0.9558268274079230792935976991411604260505,
      -17.96130656749639676506023969758331297225, -5.389086980398025669078941718352030134169, -1.504742273383398638930933017879633925149, 0.545022919619391945643865700981719104208,
  };

  const double gamma[] = {  };
  const double alpha[] = { 3.212806896871533982914109940306805502411, 4.78719310312846601708589005969319449759 };
  const double beta[] = { -4.773087433276642499827429345261277978816, -1.567476416895208124112099648396772661243 };

  const double A_part_inv[] = {
      5.644107875950089475185873124339281335674, 1.923507277054712676909381646891212291057, -0.5859014821038162923727992472033879019122, 0.173878352574245724838471938326822229815,
      -5.049214638391408870439161818242149871801, 1.221100028894691785921766123178559987957, 1.754680988760836795174600675333025557611, -0.4347914612125814012409853796201461027369,
      3.492466158625437409809252496299123113557, -3.984517895782496412958824773485986453816, 0.6347920951552187388923607524821586763698, 1.822137598434254043749452216803527954555,
      -6.923488256445454508537916405090468743462, 6.595237669628143898443354470278302412971, -12.17174941318268938990543806518783366951, 8.5,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 2, NULL, NULL);
}

void denseOutput_Radau_IIA_5(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(dt*(2.282881805816479072042229*dt - 7.763720273930763938098749) + 9.977775909015967027179954) - 5.939631780296784469555989) + 1.586407900186328249755967;
  tableau->b_dt[1] = dt*(dt*(dt*(21.98658623905104856719118 - 7.03307788889556246946698*dt) - 24.44476872321270683543143) + 10.78073426970505578696508) - 1.008117881498372989065673;
  tableau->b_dt[2] = dt*(dt*(dt*(10.75006644246363701374663*dt - 29.48457468794770677433421) + 26.82627186871280746067823) - 8.510911966412783907422194) + 0.7309748661597874614134016;
  tableau->b_dt[3] = dt*(dt*(dt*(26.46170872282742214524178 - 11.03987035938455361632188*dt) - 20.75927905451606765242676) + 6.069809477004512590013105) - 0.5092648848477427221036966;
  tableau->b_dt[4] = dt*(dt*(dt*(5.04*dt - 11.2) + 8.4) - 2.4) + 0.2;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* 5-step, order 9(4), L-stable Radau IIA */
void getButcherTableau_RADAU_IIA_5(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = { 0.05710419611451768219312119255411562123507794559875, 0.27684301363812382768004599768562514111088916969503, 0.58359043236891682005669766866291724869343263989677, 0.86024013565621944784791291887511976673837802258723, 1.0 };
  const double A[] = {
                         0.072998864317903324305568533778137426004163039777915, -0.026735331107945571877697965352751601211787338539052, 0.018676929763984354412247354802088259852773575327219, -0.012879106093306439853646949838298551565502926670061, 0.0050428392338820152066502191649400881554315957027286,
                         0.15377523147918246866812357088175097494716794709251, 0.14621486784749350664968724512404244842221927972759, -0.036444568905128089526650202198483305919654211399984, 0.021233063119304719421507662919772852230792907023364, -0.0079355799027287775326222790414578285696367527484454,
                         0.1400630456848098715137557368144872671248133759532, 0.29896712949128347939830345517875687328015051590253, 0.16758507013524896344206140916157860596789903711498, -0.033969101686617746571922141643423777169061257085197, 0.010944288744192252274499209151518279489630968011257,
                         0.14489430810953475753660064709320210901047840637514, 0.27650006876015922755593438832926660305873502019195, 0.32579792291042102998492897281091929529418345389728, 0.12875675325490976115823836749179707516127419893507, -0.01570891737880532838778945685006531578629305681221,
                         0.14371356079122594132341221985411022715892296173188, 0.28135601514946206019217265034065989120000299266737, 0.31182652297574125408185491157664052198806076863409, 0.22310390108357074440256021822858935965301327696665, 0.04,
  };

  const double b[] = { 0.14371356079122594132341221985411022715892296173188, 0.28135601514946206019217265034065989120000299266737, 0.31182652297574125408185491157664052198806076863409, 0.22310390108357074440256021822858935965301327696665, 0.04 };
  const double bt[] = { -0.3273572880280475179868889735847914204879, 1.732626055715213045955200342283536620404, -1.906441155627866383675385786616933133121, 2.501172387940700855707074417918187933204, -1.0 };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IIA_5;

  const double T[] = {
      0.01357686734494794324766390817021999803797, -0.03148028100471519415428175690692863340515, -0.0431111479250580662973038265172483283624, -0.01147851525522951470794155541215550493855, 0.0140198588928754102810778942934959307831,
      0.001617900401719087476438624531872425012895, 0.0921967418813908872382363920296397980126, 0.07198031230119928258134925493044486460326, -0.007668830749180162885156876792036080741161, -0.02470857842651852681252520537778038265537,
      0.07915785334744720764489838756150393956204, -0.2762927085439168114226356899220493142912, 0.0, 0.01939846399882895091122328964083308722858, -0.08180035370375117083639081222875725330713,
      0.412256082680461451978718545345271705818, 0.1699640831948430356688757904455530175956, -0.6350920657639433360094201530375953615483, 0.4076011712801990666216623702189598727463, -0.199682427886802525936540566022390695167,
      1.0, 1.0, -0.4454899495059430496620701331980063414799, 1.0, 0.0,
  };

  const double T_inv[] = {
      27.69769377568408840916613663851359043543, 12.78333791130440601500090610772214820099, 3.208489386713429859797686375147941186252, -0.9514904122489162212716699357512562546035, 0.7415504960259896033537032273913420094652,
      3.065984257033151558597036016460687978092, 5.314212297391761634120492618650282902689, -2.145320556037258493894963059624829924819, 0.436523216090390802570474859992269229371, -0.06036470885664840718608936049758332373722,
      -5.113924979291519864418947587489420612756, 1.617537568314967167553705069291328747309, 2.00013438779111874611154981417514901898, -1.378565273632228552455277468742193211401, 0.4768096412572696210179697709175100909288,
      -33.04188021351900000806144694261095077429, -17.37695347906356701945498060589871058527, -0.1721290632540055611515288064277513837495, -0.09916977798254264258816622140173685847264, 0.5312281158383066671849114226060247954266,
      8.611443979875291977700082512570348519505, -9.699991409528808231335894053420032664971, -1.91472863969687428485137560339172471528, -2.418692006084940026426563434082983507712, 1.047463487935337418694432999211736017659,
  };

  const double gamma[] = { 6.286704751729276645173153341869409049591 };
  const double alpha[] = { 3.655694325463572258243207960095433854357, 5.700953298671789419170215368969861620848 };
  const double beta[] = { -6.543736899360077294021071509393686318364, -3.210265600308549888425010652972117212322 };

  const double A_part_inv[] = {
      8.755923977938361667631660594828012928629, 2.891942615380117404357456676227386342843, -0.8751863962002650264162825986308431580122, 0.3997052079399654826216566948809341984769, -0.1337061638492158356717020324726304308951,
      -7.161380720145387027392470252081544389489, 1.806077724083644363529878440042442407507, 2.36379717606860836942210341579987402084, -0.8659007802831345191395346004640476681994, 0.2743380777751942021737668114372655260447,
      4.122165246243373781044035152113440886055, -4.496017125813394719848837121225239110708, 0.8567652453971776050861934092691799619881, 2.518320949211064374937135022866937259275, -0.6570627571343601062552304235652085673138,
      -3.878663219724010333635279609635936935001, 3.39315191806495416869295389614082378173, -5.188340906407186879197120489434857930142, 0.5812330525808163637522675558603647018757, 2.809983655279712329602274012227459617569,
      8.412424223594288656407174329133920050716, -6.970256116656660967032272257996600422679, 8.777114204150473239214026630269378362588, -18.21928231108810092858892870140669799063, 13.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 1, 2, NULL, NULL);
}

void denseOutput_Radau_IIA_6(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(dt*(dt*(18.9225493385218286667573 - 4.877573129141801435353665*dt) - 28.98893240310024716281628) + 22.11011240729804065906351) - 8.656553506300387740043632) + 1.591191485349307432497373;
  tableau->b_dt[1] = dt*(dt*(dt*(dt*(15.64370724304611046709081*dt - 57.71990808176219927045815) + 81.70883091587129711062254) - 54.27568436856385767983224) + 15.87752143417611490469568) - 1.026016475611511662638945;
  tableau->b_dt[2] = dt*(dt*(dt*(dt*(88.46775869913640827170171 - 26.00690297479666724299257*dt) - 111.154501422397282403308) + 61.18357947116082384375687) - 13.00063798928688484071886) + 0.7711676077783898628459521;
  tableau->b_dt[3] = dt*(dt*(dt*(dt*(31.63423192612264259314153*dt - 97.83568254816011542580486) + 109.0676231164860909954399) - 52.24124717777430826707687) + 10.20850197388310732726579) - 0.5907336963229322648856225;
  tableau->b_dt[4] = dt*(dt*(dt*(dt*(83.16528259226407775780401 - 29.22679639856361771521944*dt) - 85.63302020685985853993822) + 38.77879522343485699964428) - 7.345498579138616317865656) + 0.4210577454734132988479087;
  tableau->b_dt[5] = dt*(dt*(dt*(dt*(12.83333333333333333333333*dt - 35.0) + 35.0) - 15.55555555555555555555556) + 2.916666666666666666666667) - 0.1666666666666666666666667;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* 6-step, order 11(5), L-stable Radau IIA */
void getButcherTableau_RADAU_IIA_6(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 6;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = { 0.039809857051468742340806690093333167704262654228385, 0.19801341787360817253579213679529623603818635883379, 0.43797481024738614400501252000522885251679027421474, 0.69546427335363609451461482372116716139400155499865, 0.90146491420117357387650110211224730961948643045171, 1.0 };
  const double A[] = {
                         0.050950010994640609251478059633024629369673958557677, -0.018907306554292139093302793813918249853741307729611, 0.013686071433088228819012995720112285258120537385948, -0.010370038766046045839009537968545118512361729041913, 0.0073606563966398039365575429778365553030154189796668, -0.0029095364525617147339295764551769338604442239233829,
                         0.10822165891905866038457804818157049157131605614756, 0.10697551993733260380284870869670734188993967399452, -0.027539023355392420328824862378693123673003724790065, 0.017496747141228161531087490197110541281123440201633, -0.011653721891195586803761017683165506213203011975441, 0.0045122371225767539498637697817664911820139252555853,
                         0.09777967009264535465982146161839735529224057032578, 0.22317225063689583566719958767108380482274346965384, 0.13631467927305188653151585886467910012672516478677, -0.029646965988196216350882814027078247408353061629895, 0.016358578843437159707327494725790347334132545244331, -0.0060034026104478762099690688476435076506984141660894,
                         0.10212237561293384100253249087632606054417775295884, 0.20297595737309107918373442944059116349390035078792, 0.27639913638074783302191977602414971750729661532819, 0.1310060231360429803526599625595164053496782580727, -0.024876303199822286536339815419573239269286280557463, 0.0078370840506426474901079802401570537682348584084609,
                         0.10033100138496080156934198475643763175703379375978, 0.21024730855333846180365503705179494054249856988659, 0.25608537205033761639808891688573084503296586073936, 0.25336593470456565097236321199032658663712429116967, 0.092430534335699596829174177922840200031659712265102, -0.010995236827728553696122226494882894381795797368795,
                         0.1007941926267404201046003778745677818586739544979, 0.20845066715595386947970319137132312166770750468809, 0.26046339159478749128511470328476850990576171084536, 0.2426935942344849580799139577934448339939675840621, 0.15982037661025548327288999189811797479611146812877, 0.027777777777777777777777777777777777777777777777778,
  };

  const double b[] = { 0.1007941926267404201046003778745677818586739544979, 0.20845066715595386947970319137132312166770750468809, 0.26046339159478749128511470328476850990576171084536, 0.2426935942344849580799139577934448339939675840621, 0.15982037661025548327288999189811797479611146812877, 0.027777777777777777777777777777777777777777777777778 };
  const double bt[] = { 0.4914223436619063359229674710991495189894, -1.044400345815271427668262344714238545442, 2.343267309489758677412225550810475596188, -2.290783854394384686825360119129050716831, 2.500494547057991101158429441933664147096, -1.0 };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IIA_6;

  const double T[] = {
      -0.1038148248226006161898205420695064592091, -0.01908836807153628814776296557732806093783, 0.0088597273659501606601164392696922504676, 0.2086160715225811696558159893778163643127, -0.002985389218706438089935116050639871855584, -0.005216901633623462885945406085306618216142,
      0.2112130549617691439111184274195597250668, 0.0, -0.184524594298304021447761374819871369398, -0.2548868410891171762475437838952948767519, 0.003766304136060634630428850049513875410583, 0.001540000791140032695111797113983390890518,
      -0.4009740551871843064891164933499985899574, 0.1790921711487228785111392987797925981642, 0.2698618618370164674137442733216215429443, -0.3897248318075563415076872084219020493825, 0.006604094642671578758085016324748662744946, -0.01470932441894906164864106080679880145681,
      0.3197068864656914815962191759363006753834, -0.948332174735003426582138073372013360924, 2.859222562066303274049801708234606998207, 0.0, 0.09164124566731780643202190459884795348705, -0.04635622100372256061266550220804048376218,
      1.937954480829633716467533394917733949804, 0.9207094338279246586718159903217984034954, 5.612734773430258153255302523460278509845, 9.574346752968413606451068310589284175782, 0.4711629358247579089069386214883825567558, -0.07707921396504256162139415312248054628802,
      1.0, 3.06156126660675828987093787421894995163, 1.0, 20.88199218332491628229333911231506984253, 1.0, 0.0,
  };

  const double T_inv[] = {
      0.8084950779165254542799921043285139353482, 2.604743750958376218809479953620346112733, -0.5949028048095340521559393281580243877771, -0.2081006594973723424839559934261300867909, 0.236001974138585593793882553611834742599, -0.09559256958251549602891021558598191784984,
      -2.263136997333665548232848628888629021464, 0.04468151003048068274204591942336662721394, 1.398667223466118352550835182350765083553, -0.7615728986538168848208122177182908477042, 0.3451717129302118907612314118422026080058, -0.1090021881944551695579922956379202971038,
      -2.47776392250236581502010802217796646673, -2.072183788096792577336568852374120898836, 0.02020794372477232859056092587350893572213, -0.013260861215732987303166228450989898173, 0.1304186132420477334053478512954582778365, -0.05995924536272943628901326776409652990988,
      1.33732872125142115375992879998278850874, -0.6109311332541626587528235740567151720736, -0.5114313686547837336994356292413955129613, -0.09271259527455791996673380714846279579753, 0.05063711026665349416782816226004094971608, -0.005691091452767005680906638056461907628984,
      -19.32808648706076917151450700377418786363, 12.08810400585885280910901831703294905415, 6.972295307404832111033849209928302103698, 4.488987298748150372314998615936042819647, -2.480588674790497343771940112296136873848, 1.608110019528037191337226250501880475189,
      -139.162365235214475741044940263579506341, -86.86394280102758379741501913701080348712, -17.68623066595332555896275574105054248767, 0.6289016427699384262857419024505555951776, -2.293422051615319474905768647962374667987, 1.051445880391877517282717746914888988258,
  };

  const double gamma[] = {  };
  const double alpha[] = { 4.038847534488800154166195229640030659658, 6.470514936701569753598584495713229000395, 7.490637528809630092235220274646740339948 };
  const double beta[] = { -8.345600414872215667958594699304708933405, -4.900121147421386424219683046996816065052, -1.621502388778393978353342752338923527676 };

  const double A_part_inv[] = {
      12.55970347629150885675922532331891964013, 4.075825988876295481749454735031003108456, -1.217203808464260506775607847197515447421, 0.5662318669441424697889579708094353051037, -0.3071042122568407960667849760996157949078, 0.1090860107880072772249851745292611816196,
      -9.802838712568015725430576296432169103899, 2.525081407963725234258772437798811089788, 3.13222586264734150140421533731192086218, -1.157409992774380785128892186776465603445, 0.5833821924541103918317275645901196840306, -0.2025476984690533992461768091638209559495,
      5.182157838558718444070870675008570635823, -5.544522909527438071467296426228820867017, 1.141618166847494000345653302051089213997, 2.974976253821251159057453740379448461022, -1.178019327058829407691465284519597084855, 0.3845423620091725705442407299486040901576,
      -4.10823909345880706187287203809880418017, 3.49150290911386180937795214804147340843, -5.069878750993607337617481796899618876632, 0.7189441918977704032300544771680751155747, 3.46004179608626687413342831161607655431, -0.9264431104031318893392858740223827889184,
      4.385785063400934178368949557383407904832, -3.464005047451488633583200446630886373753, 3.951542456587611640146050419506078880989, -6.810539438891445229513105959783181559137, 0.5546527569995015054062944596631049405146, 4.01713280695131170404962247640658312851,
      -9.9429774219288117999498665906756735229, 7.676062157233047637263503126199316779647, -8.232737128218406491411113845062543173202, 11.63870727736801986481207712855794924705, -25.63905488445384921071459981901904933059, 18.5,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 3, NULL, NULL);
}

void denseOutput_Radau_IIA_7(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(dt*(dt*(dt*(11.45608158833036806214456*dt - 49.98555780882076668092527) + 88.92081439940893102211075) - 82.61199090290419802347197) + 42.5684376486618505389208) - 11.86735490768121638204296) + 1.594064218561041781197339;
  tableau->b_dt[1] = dt*(dt*(dt*(dt*(dt*(158.9633239184234411749878 - 37.62732723293232866726756*dt) - 269.587887412209742431544) + 232.1402530759686509011186) - 104.588261408003973813966) + 21.89555492668408003854636) - 1.036553752196476461002723;
  tableau->b_dt[2] = dt*(dt*(dt*(dt*(dt*(65.57712817876552134254661*dt - 262.5896479037349742050365) + 412.8817621034525634663054) - 317.623307111820279973304) + 119.443396578879996734224) - 18.27080167953064224805401) + 0.7938217234907926875176341;
  tableau->b_dt[3] = dt*(dt*(dt*(dt*(dt*(324.5017915419364571467466 - 86.63425000191077201940796*dt) - 468.1955191607219892722909) + 322.418851602326298352926) - 106.1667493619430980736871) + 14.93200794707032132572501) - 0.6325776522499342252619287;
  tableau->b_dt[4] = dt*(dt*(dt*(dt*(dt*(93.83554041388908853603364*dt - 328.4240528650374306928517) + 439.5825098856763818801198) - 280.6792430349470227530511) + 87.24612664352795011661773) - 11.86801681988985282340799) + 0.4976107136030013134425167;
  tableau->b_dt[5] = dt*(dt*(dt*(dt*(dt*(270.6770002600904161142219 - 81.62758110940718337649827*dt) - 345.0302512441775732361296) + 212.0697220856622657814968) - 64.2172358154084397878237) + 8.607181961918738660662159) - 0.3592223940655679530356959;
  tableau->b_dt[6] = dt*(dt*(dt*(dt*(dt*(35.02040816326530612244898*dt - 113.1428571428571428571429) + 141.4285714285714285714286) - 85.71428571428571428571429) + 25.71428571428571428571429) - 3.428571428571428571428571) + 0.1428571428571428571428571;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* 7-step, order 13(6), L-stable Radau IIA */
void getButcherTableau_RADAU_IIA_7(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 2*tableau->nStages - 1;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;

  const double c[] = { 0.029316427159784891972050276913164910373730392563715, 0.14807859966848429184997685249597921223024877480859, 0.33698469028115429909705297208077570519756875002847, 0.55867151877155013208139334180552194007436828896541, 0.7692338620300545009168833601156454518371421433223, 0.92694567131974111485187396581968201105617241954228, 1.0 };
  const double A[] = {
                         0.037546264993921331333686127624105551409844147085069, -0.014039334556460401537626568603936253927078900617188, 0.010352789600742300936755479003273124789107137783342, -0.0081583225402750119092045435772132783491910230755902, 0.0063884138795346849437559514864056804089198993395116, -0.0046023267791486554993520258547685217738229482397359, 0.0018289425614706437040358568352986078159520802883062,
                         0.080147596515618967795215595316188773478794694453719, 0.081062063985891536679584719357221980974798332396676, -0.021237992120711034937085469604419103836950630324492, 0.014000291238817118983742204835134926788498535743389, -0.010234185730090163829199816607636044633616515605306, 0.0071534651513645904980623821669621411752507610622935, -0.0028126393724067233403427629674734617165264029176848,
                         0.072063846941881902113362526561137596779695354775321, 0.17106835498388661942435250400905030280034964311372, 0.10961456404007210923322040746184569082289243085783, -0.02461987172898405386231886444110056108884624668374, 0.014760377043950817073195348981742706482163192669642, -0.0095752593967914005563287247266417134307882145349237, 0.003672678397138305671569774234741682832102589830622,
                         0.075705125819824420424641229496338921969891121384815, 0.15409015514217114464633168204648291517195590999536, 0.22710773667320238641128128794936635009809331118652, 0.11747818703702478198791268067393216144249387082062, -0.02381082715304417358204792932577433437596089393164, 0.012709985533661205633610757619788395064712864489453, -0.0046088442812896334403363666546124692968178949797229,
                         0.073912342163191846540806321243016399213366859606731, 0.1613556076159424321862201459030948103738282915228, 0.20686724155210419781957884643767073090996149315046, 0.23700711534269423476224677295732751474653439325044, 0.10308679353381344662410584574572164064619759515728, -0.018854139152580448840052190417863035124650910366617, 0.0058589009748887918239776182466773910719044210011886,
                         0.074705562059796230172292559361766628755621292318113, 0.1583072238724687006584793845146287165740587429923, 0.21415342326720003110869745785686139661908996932591, 0.21987784703186003998748735549076677110629790633148, 0.19875212168063526980182646918453450476047373969754, 0.06926550160550913323097216576197674236468414173589, -0.0081160081977282901078814263508527491240533728589524,
                         0.074494235556010317933248780209166920975326449423939, 0.15910211573365074087243521723493418210816301632787, 0.21235188950297780419915401957510412235603856069468, 0.22355491450728323474967447682122101798551083778481, 0.19047493682211557690296917393806276186714739147125, 0.11961374461265620289353874038477630083026272388929, 0.020408163265306122448979591836734693877551020408163,
  };

  const double b[] = { 0.074494235556010317933248780209166920975326449423939, 0.15910211573365074087243521723493418210816301632787, 0.21235188950297780419915401957510412235603856069468, 0.22355491450728323474967447682122101798551083778481, 0.19047493682211557690296917393806276186714739147125, 0.11961374461265620289353874038477630083026272388929, 0.020408163265306122448979591836734693877551020408163 };
  const double bt[] = { -0.2593076755258768633646696264711447439871, 1.255469459350560084324287142896233783625, -1.698403593561285638182740271940617400542, 2.747862898245942093124032369910816949049, -2.543660856123370685801973692928840823266, 2.498039767614031009901064078533552235122, -1.0 };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = FALSE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_Radau_IIA_7;

  const double T[] = {
      0.002443584304870611540711873536202848531561, 0.03057363256226740727160820228319680784585, 0.0133303521408942932586562905165599057705, 0.1553315749912116897933707446524199175021, -0.1504188680838382591931303390622714502, -0.001238646187952874056376868703911052855813, 0.002760617480543852499548003790966755920215,
      -0.001815339648319317160533175196391990035361, -0.06020251369529888889323777376286722108714, -0.01757207293401259272454901288788359061642, -0.1367404059668601680786084200734766453885, 0.3070044919395954545321010518225509827266, -0.00006666635339396338181760478974025762882138, -0.00318547482516620984874835878222687621122,
      0.004605339331161874804215399488991374721478, 0.1177378929732031113462122942426312152543, 0.0, -0.2578060284538247855586838325247457259425, -0.3012645979829834810979759483212861641103, -0.002352180982943338340535195325555294917767, -0.0004169077725297562691408880305994094134255,
      0.01787002334285306905849068257903824855579, -0.2081500996515612103846240651203372481344, 0.1265540284996107334107347947615003451285, 0.2592448513227470991176436144863913501697, -1.353657393765926793632746160886720826536, 0.003115071152346175252725470862893152080544, -0.02511660491343882192836382347144669827898,
      0.1281810080772839100766671546312430702377, 0.03131924638361855826193352153184082217154, -0.5290498247463721566805307728877424022864, 6.961244384316622065828028476816056097468, 0.0, 0.101717732481715146808078931323995112561, -0.09504502035604622821038921444856478951832,
      0.5200651497488246865988548621276895804526, 1.030227455588015574500700958824363139562, 0.05872839551725000246836177128214284856939, 10.44620810225192099638681714800056701753, 18.6818938966530354810119464511591412779, 0.5217519452747652852946094531818070342094, -0.1280719446355438944141149395109133576625,
      1.0, 1.0, 1.025332904316196527949082325304222479118, 1.0, 36.00143595926366042046186224468310042601, 1.0, 0.0,
  };

  const double T_inv[] = {
      227.5153059626806890388393011506457218667, 166.6480224676097461089729683041486557709, 43.26514588452621505369067359414994228903, 3.62309006134101613248691820771427384463, 3.572674832938798031294821819808770156796, -2.743556365603367314479807161010513177255, 1.451453540254750351507119589228455610535,
      -5.685745523645763079350865514048924866961, -5.695328798344218027141733594297767776647, 4.194542877032578517961843086390874046146, -0.5634710992339321996180808377612010516316, -0.3498848724553411615264254867470154394264, 0.3756069796496611179047645140420989062868, -0.1561849137021767433223279595403627514527,
      2.612181217358560762931282975078711182941, -5.189082743784435650126341469959843985057, -2.639867899983247950322993120931920391563, 2.627302066922130948814091292133320033929, -1.430029415997415535093704930283998215574, 0.7399729444472437474488158235476292082286, -0.2521270225044929403266869628692369766825,
      1.677273518349435847211732932365551834263, -0.2120738668416560450302516429945034788731, -0.8397244598554052735510482356390976884977, -0.03117486427587609209826264725770145751818, -0.005764602480954630438139204022698978950742, 0.05455416283154177035418802690334441677937, -0.02769204001386686020220964034033505132671,
      2.027726305119479435876562291686551684322, 2.433810222066891779687285693147447606983, 0.1351024776550297482121930310824296295656, -0.1023190145818236310904197663912611548392, -0.09511646667027558029043440693235869873963, 0.07338736849061530135022500434731027343894, -0.02530456575744630621852587940170682984603,
      -299.1862480282520966786364252394472810794, -243.0407453687447911819005652300830926691, -48.77710407803786921219093448873880326946, -2.03867190574193440528015205293433905622, 1.673560239861084944268290423092132021109, -1.087374032057106164455596925503231110736, 0.9019382492960993738427155148390040529634,
      93.07650289743530591157194526373738385457, -23.8816310562811442770319002318043863377, -39.27888073081384382710156461367603668344, -14.3889156854910800698761307424979534709, 3.510438399399361221087084324808457349722, -4.863284885566180701214910586997343135036, 2.246482729591239916400469248397112322789,
  };

  const double gamma[] = { 8.93683278840521633730209691330107970355 };
  const double alpha[] = { 4.378693561506806002523349192688561291658, 7.141055219187640105774981425715568043182, 8.511834825102945723050620924945330813385 };
  const double beta[] = { -10.16969328379501162731835441884772989301, -6.623045922639275970620558115911861104681, -3.281013624325058830035942527039391584679 };

  const double A_part_inv[] = {
      17.05528430442165547204579642034083780888, 5.475299512185491994676800899743790661694, -1.618581105190787041889955300745135338827, 0.7496541282385066885049184474288358203896, -0.4218913759830160165720142934789005507972, 0.2510502142463927595842150825808914698727, -0.09232481935368412048374538505584093461111,
      -12.94898869881152283841754403823425013411, 3.376585145452421994964218930429040150483, 4.054013503925585809637295490354844936871, -1.486313976006544588232954347118687355463, 0.7728544737788971220359256391434762225789, -0.4449469472010699808091899446981067943297, 0.1617747003353813970800048389116167321952,
      6.526797433701593265807091002677945510913, -6.912304925481828620862501995874923241214, 1.483746931004011403533388291859476275869, 3.594603354455891352594802457908711647105, -1.450215601222529072070450317290051019103, 0.7670384491813573773469544044383559470547, -0.2714284856198724333173372620881037731888,
      -4.760415643167770722198704938659524225423, 3.990860318095922048352078547892569959329, -5.660688333657834999015734815429094521088, 0.8949802937859413769491873647105581662855, 3.735899391500152218956023361695343496729, -1.541978502549350374113869407329397092427, 0.5117126570997155963060826760189857664119,
      4.329451016638691199204567685388105273598, -3.35352800167791874660934423411227064496, 3.690617931862721646605844851741172496253, -6.037309187265788303408780583517567006976, 0.6499973865951115045278719586572919678705, 4.577300941414560376336218683666625758555, -1.244056646677253406230335427134392699808,
      -4.943623833507561010702885328788319861744, 3.704802676027051056417306323704679214844, -3.745728431373815632639674243616945678846, 4.781665625762614880423664752694490182187, -8.783388755925044456571959399515027354807, 0.53940593874085824797953703400279563061, 5.443680188059144140702182988806165557866,
      11.4954552051166652806851254229789747493, -8.517072423056624626784124125074774924435, 8.381031301964824604182700076614229058938, -10.03344165195040099094892792489048742766, 15.09439394299116654063449881984594504531, -34.42036637506563080776927226947388650146, 25.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 1, 3, NULL, NULL);
}

void denseOutput_LOBATTO_IIIA_3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(0.6666666666666666666666667*dt - 1.5) + 1.0;
  tableau->b_dt[1] = dt*(2.0 - 1.333333333333333333333333*dt);
  tableau->b_dt[2] = dt*(0.6666666666666666666666667*dt - 0.5);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_LOBATTO_IIIA_3;

  const double T[] = {
      0.125, -0.2165063509461096616909307926882340458679,
      1.0, 0.0,
  };

  const double T_inv[] = {
      0.0, 1.0,
      -4.618802153517006116073190244015659645181, 0.5773502691896257645091487805019574556476,
  };

  const double phi[] = {
      -1.0, -2.886751345948128822545743902509787278238,
  };

  const double rho[] = {
    -0.5, 1.0
  };

  const double gamma[] = {  };
  const double alpha[] = { 3.0 };
  const double beta[] = { -1.732050807568877293527446341505872366943 };

  const double A_part_inv[] = {
      2.0, 0.5,
      -8.0, 4.0
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, TRUE, FALSE, 0, 1, phi, rho);
}

void denseOutput_LOBATTO_IIIA_4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(3.333333333333333333333333 - 1.25*dt) - 3.0) + 1.0;
  tableau->b_dt[1] = dt*(dt*(2.795084971874737120511467*dt - 6.423503277082807574356268) + 4.045084971874737120511467);
  tableau->b_dt[2] = dt*(dt*(4.756836610416140907689601 - 2.795084971874737120511467*dt) - 1.545084971874737120511467);
  tableau->b_dt[3] = dt*(dt*(1.25*dt - 1.666666666666666666666667) + 0.5);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_LOBATTO_IIIA_4;

  const double T[] = {
      0.05303036326129938105898786144870852883518, -0.07776129960563076320631956091016912560723, 0.006043307469475508514468017399717100581556,
      0.2637242522173698467283726114649606009693, 0.2193839918662961493126393244533345607049, 0.3198765142300936188514264752235344493226,
      1.0, 1.0, 0.0,
  };

  const double T_inv[] = {
      7.695032983257654470769069079238550159564, -0.1453793830957233720334601186354032099476, 0.6302696746849084900422461036874826845811,
      -7.695032983257654470769069079238550159564, 0.1453793830957233720334601186354032099476, 0.3697303253150915099577538963125173154189,
      -1.066660885401270392058552736086175818405, 3.146358406832537460764521760668933441691, -0.7732056038202974770406168510664737222942,
  };

  const double phi[] = {
      4.136608679244136045317158325069029505281, -3.13660867924413604531715832506902950528, -2.657325109410866710940683346427133588849,
  };

  const double rho[] = {
      -0.447213595499957939281834733746255247088313521, 0.447213595499957939281834733746255247088313521, -1.0,
  };

  const double gamma[] = { 4.644370709252171185822941421408063969864 };
  const double alpha[] = { 3.677814645373914407088529289295968015068 };
  const double beta[] = { 3.508761919567443321903661209182446413836 };

  const double A_part_inv[] = {
      3.618033988749894848204586834365638117721, 0.854101966249684544613760503096914353161, -0.1708203932499369089227521006193828706321,
      -5.854101966249684544613760503096914353162, 1.38196601125010515179541316563436188228, 1.170820393249936908922752100619382870632,
      11.18033988749894848204586834365638117721, -11.1803398874989484820458683436563811772, 7.0
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, TRUE, FALSE, 1, 1, phi, rho);
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

  const double T[] = {
      -0.5, -0.8660254037844386467637231707529361834716,
      1.0, 0.0,
  };

  const double T_inv[] = {
      0.0, 1.0,
      -1.154700538379251529018297561003914911295, -0.5773502691896257645091487805019574556471,
  };

  const double gamma[] = {  };
  const double alpha[] = { 3.0 };
  const double beta[] = { -1.732050807568877293527446341505872366943 };

  const double A_part_inv[] = {
      4.0, 2.0,
      -2.0, 2.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, TRUE, 0, 1, NULL, NULL);
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

  const double T[] = {
      0.4095301969830458833321950974758598628846, -0.1673815592420907613613286431634840957528, 0.525607543214227178899726386274854899297,
      -0.01889262637496554605520143939163372812018, -0.07414582181377904851735726791652572329615, -0.3986038741564085382228374985742072476019,
      1.0, 1.0, 0.0,
  };

  const double T_inv[] = {
      1.539006596651530894153813815847710031913, 2.029366819297621588718516807615183650697, 0.4080703944098336948671786386275812012701,
      -1.539006596651530894153813815847710031913, -2.029366819297621588718516807615183650697, 0.5919296055901663051328213613724187987299,
      0.2133321770802540784117105472172351636811, -2.227452004563088309499495665221802992863, -0.1294483869928769569618834998706596880356,
  };

  const double gamma[] = { 4.644370709252171185822941421408063969863 };
  const double alpha[] = { 3.677814645373914407088529289295968015068 };
  const double beta[] = { -3.508761919567443321903661209182446413836 };

  const double A_part_inv[] = {
      7.0, 5.854101966249684544613760503096914353162, -0.8541019662496845446137605030969143531609,
      -2.236067977499789696409173668731276235441, 1.38196601125010515179541316563436188228, 0.854101966249684544613760503096914353161,
      2.236067977499789696409173668731276235441, -5.854101966249684544613760503096914353162, 3.618033988749894848204586834365638117721,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, TRUE, 1, 1, NULL, NULL);
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

  const double T[] = {
      0.455410041101028467211172034828748294958, -0.602705020550514233605586017414374147479, 0.4309321229203225731070721341350345638889,
      0.2073983055356404377998207752658662409196, 0.1775508472321797811000896123670668795402, -0.5194499080011394844329178845743292375758,
      1.0, 1.0, 0.0,
  };

  const double T_inv[] = {
      0.9234665031131368612140762392432519779126, 0.766101551858351241079239349573394780247, 0.4205559181381766909344950150991348065152,
      -0.9234665031131368612140762392432519779126, -0.766101551858351241079239349573394780247, 0.5794440818618233090655049849008651934848,
      0.05306214809504116746618873404230997578571, -1.881093442936075912563125426209995453221, 0.3659705575742745254721332009249516414254,
  };

  const double gamma[] = { 2.625816818958466716011888933765283331279 };
  const double alpha[] = { 1.68709159052076664199405553311735833436 };
  const double beta[] = { -2.508731754924880510838743672432351514192 };

  const double A_part_inv[] = {
      3.0, 4.0, -1.0,
      -1.0, 0.0, 1.0,
      1.0, -4.0, 3.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 1, 1, NULL, NULL);
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

  const double T[] = {
      0.5476452038202714922036315112488560856846, 0.1785412628034932093817159389309281985364, -0.116586249887015966241810926513722590616, -0.2331588855995925881890963658008489845825,
      -0.3452980030318587067517740490632527531279, 0.0, 0.06854105219638146056196079302833999354915, -0.01174994570529409329215202085259075914414,
      0.3297049014432367490412414319564127862527, -0.4798440649214683812526552805265999166067, 0.3151194350690626574023974106907723462365, -0.1462672571725994138598319831765198375652,
      1.0, 0.1209077169702495639254744487130712632666, 1.0, 0.0,
  };

  const double T_inv[] = {
      0.07505408143888482727247086654377807832544, -2.293655690307507431864588601090242744067, 0.06461325673597880267044867004091320603325, 0.1455989553229545430061738977300993432369,
      0.9348105874590660620392769696329348986682, 1.443808767633432752284503957504533835992, -1.606128903955311262980555484407219419312, 0.5161483215050650446091082595192052794877,
      -0.1880798953681783131618295873950584167982, 2.119088068471319525358160650028831297255, 0.1295801222011871168763466323760704183975, 0.7919947295058416761575457646970583566547,
      -3.302757250041810136591302948414990966281, -5.341364646141195278576399308543633031624, -1.142921928129632462955369184619120229001, 0.341203583261795719175206722672451293619,
  };

  const double gamma[] = {  };
  const double alpha[] = { 2.220980032989806897423925140476047787088, 3.779019967010193102576074859523952212912 };
  const double beta[] = { -4.160391445506931982228485188880642430211, -1.380176524272843046226884893083007281595 };

  const double A_part_inv[] = {
      6.0, 8.090169943749474241022934171828190588602, -3.090169943749474241022934171828190588601, 1.0,
      -1.61803398874989484820458683436563811772 /* golden ration nice! */, 0.0, 2.236067977499789696409173668731276235441, -0.6180339887498948482045868343656381177202,
      0.6180339887498948482045868343656381177203, -2.23606797749978969640917366873127623544, 0.0, 1.61803398874989484820458683436563811772,
      -1.0, 3.090169943749474241022934171828190588602, -8.090169943749474241022934171828190588603, 6.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 2, NULL, NULL);
}

void denseOutput_GAUSS2(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = 1.366025403784438646763723 - 0.8660254037844386467637232*dt;
  tableau->b_dt[1] = 0.8660254037844386467637232*dt - 0.3660254037844386467637232;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_GAUSS2;

  const double T[] = {
      0.0, -0.2679491924311227064725536584941276330572,
      1.0, 0.0,
  };

  const double T_inv[] = {
      0.0, 1.0,
      -3.732050807568877293527446341505872366943, 0.0,
  };

  const double gamma[] = {  };
  const double alpha[] = { 3.0 };
  const double beta[] = { -1.732050807568877293527446341505872366943 };

  const double A_part_inv[] = {
      3.0, 0.4641016151377545870548926830117447338856,
      -6.464101615137754587054892683011744733886, 3.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 1, NULL, NULL);
}

void denseOutput_GAUSS3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(1.111111111111111111111111*dt - 2.312163891034569480863211) + 1.478830557701236147529878;
  tableau->b_dt[1] = dt*(3.333333333333333333333333 - 2.222222222222222222222222*dt) - 0.6666666666666666666666667;
  tableau->b_dt[2] = dt*(1.111111111111111111111111*dt - 1.021169442298763852470122) + 0.1878361089654305191367891;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_GAUSS3;

  const double T[] = {
      0.07215185205520017032081769924185183680953, -0.08224123057363067064866206597566072403805, 0.0601207386193085017308594892116360125871,
      0.1188325787412778070708888193783509970306, 0.05306509074206139504614411374578745388787, -0.3162050511322915732224862926149834184227,
      1.0, 1.0, 0.0,
  };

  const double T_inv[] = {
      5.991698084937800775649580744061578687781, 1.139214295155735444567002236908970407541, 0.432312113783858385569637590121887828978,
      -5.991698084937800775649580744061578687781, -1.139214295155735444567002236908970407541, 0.567687886216141614430362409878112171022,
      1.246213273586231410815571640505856386175, -2.925559646192313662599230367093796217197, 0.2577352012734324923468722837107305932477,
  };

  const double gamma[] = { 4.644370709252171185822941421433771597933 };
  const double alpha[] = { 3.677814645373914407088529289322555238311 };
  const double beta[] = { -3.508761919567443321903661209178714122399 };

  const double A_part_inv[] = {
      5.0, 1.163977794943222513572353866371255812337, -0.1639777949432225135723538663774535501041,
      -5.727486121839514070982721166429537582427, 2.0, 0.7274861218395140709827211664861235829424,
      10.16397779494322251357235386648904159981, -9.163977794943222513572353866527039952332, 5.0,
  };
  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 1, 1, NULL, NULL);
}

void denseOutput_GAUSS4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(4.775286118057296050988874 - 1.855135017009736526300161*dt) - 4.273011803936099382986509) + 1.526788125457266786984328;
  tableau->b_dt[1] = dt*(dt*(4.698862351888765202815429*dt - 10.46274078781535340401941) + 6.903583462844788533079347) - 0.8136324494869272605618981;
  tableau->b_dt[2] = dt*(dt*(8.332708619739707407242305 - 4.698862351888765202815429*dt) - 3.70853521073131953791369) + 0.4007615203116504048002818;
  tableau->b_dt[3] = dt*(dt*(1.855135017009736526300161*dt - 2.645253949981650054211769) + 1.077963551822630387820852) - 0.113917196281989931222712;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_GAUSS4;

  const double T[] = {
      0.04730400631161964234420937974006781428749, 0.02187190815439641835934120923073859847639, -0.01234175974136383238608052655020345874402, -0.02349691821560328668263181158236618754457,
      -0.1349975425610351328663664399711196541213, 0.0, 0.02852518491163969017631882672517969123804, -0.01204093363760083640724996665987680462528,
      0.2147011579332122077737256695166471089732, -0.334766179208954323584200600152395864739, 0.18350916094694874723981328658122864136, -0.1119907859499068431427388614943290829784,
      1.0, 0.3216155572199857781177657679192506941681, 1.0, 0.0,
  };

  const double T_inv[] = {
      1.669850586762205520596031861539765228369, -5.461099863299409029009900408746579322831, 0.2368087530409240829949289898937929519132, 0.1329312025919072622801237161391647934907,
      8.402299185842810339912921813324204658757, 2.67367529961376021766570870971994802357, -2.050362283792074957624838226344615963836, 0.4036923378475160276114618769449201479523,
      -4.372160721346073806888385976269741348943, 4.601204291988817110521118696455859499853, 0.4226196553637067191106536419577821831716, 0.7372350612258251163716227958516220162549,
      -29.07934128989777863623880820139910620706, -10.92230382520138929261285243127942797139, -1.653799987630558089871389676805016519187, 0.2561579407420976532158914021132743634997,
  };

  const double gamma[] = {  };
  const double alpha[] = { 4.207578794359255663211212149448079704083, 5.792421205640744336788787850551920295917 };
  const double beta[] = { -5.31483608371350543371664419726353845149, -1.734468257869007503637946429840248583809 };

  const double A_part_inv[] = {
      7.738612787525830567284848914004010669764, 2.04508965030390878520553575776619365287, -0.4370708023957989035724639019492015165686, 0.08664402350326167465672853302061613601977,
      -7.201340999706890565151442798549179026359, 2.261387212474169432715151085995989330236, 1.448782034533681252431492636019454861218, -0.2331339812124165654350344952622329984738,
      6.343622218624971332778961412625599489274, -5.97155645948202011786179480801143352169, 2.261387212474169432715151085995989330236, 1.090852762294335797807515881185812535556,
      -15.56386959855492280922642636102863747553, 11.89278387805684136460746043690763843845, -13.50080272596495124624053229272463057475, 7.738612787525830567284848914004010669764,
  };
  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 2, NULL, NULL);
}

void denseOutput_GAUSS5(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(dt*(3.667944222886234603016645*dt - 11.24724626396974944179701) + 12.88149968511473190032678) - 6.735142250597435530602309) + 1.551408049094313012813028;
  tableau->b_dt[1] = dt*(dt*(dt*(29.46585378166175338889907 - 10.38794422288623460301664*dt) - 29.40760360938762868341979) + 11.46216677786186486888419) - 0.8931583920000717373261768;
  tableau->b_dt[2] = dt*(dt*(dt*(13.44*dt - 33.6) + 27.37777777777777777777778) - 7.466666666666666666666667) + 0.5333333333333333333333333;
  tableau->b_dt[3] = dt*(dt*(dt*(22.47386733276941962618415 - 10.38794422288623460301664*dt) - 15.42363071160296115798994) + 3.844963589192846878147194) - 0.2679416522233875093041099;
  tableau->b_dt[4] = dt*(dt*(dt*(3.667944222886234603016645*dt - 7.092474850461423573286212) + 4.571956858098080163305177) - 1.105321449790609549762404) + 0.07635866179581290048392539;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_GAUSS5;

  const double T[] = {
      0.009323625971241084234125362511609184374953, -0.01799870502724134184583176080246228861218, -0.02185893512453071237635098757998244801498, -0.004813985322905043796019789085560666218955, 0.01099049998197756305998379949701398666478,
      -0.002857691612154794301347917390595674820835, 0.05228601530547596095168002368451364683454, 0.0367617051800750632906330336222283844775, -0.006025133670529664441842082298146755226649, -0.01589274424617578981886017578601875195185,
      0.04408309618988790251682803452432779562795, -0.160622018595476812593779173256702189655, 0.0, -0.0007999407257445558616264797911019250438662, -0.03731987583729495972503055453663663949612,
      0.2527928412780782471292841047213249534309, 0.1775067252685303890873671777361937740463, -0.4032710731180368812921980374012739318658, 0.233510552626602054532817531198683051005, -0.1863630466929573859788469309909198630385,
      1.0, 1.0, 0.08123245710832020252305207300392224228782, 1.0, 0.0,
  };

  const double T_inv[] = {
      49.03245971237229820996405937135298161224, 25.03991305561248256273090267488467640131, 5.190018151503777492134043587759401467981, -0.2830631957231549903573419830229027466225, 0.4571603148081065026084176830680204865824,
      8.692220721583551633260725493273878348402, 9.65427587695765282713927657159919786605, -3.59506867758227605762871441054389418069, 0.4092358024655398495996961643586842989021, 0.00157580539262831196872703645190078235787,
      -8.504708028585885269813124292942875154115, 4.815817020051187574782824815582403574008, 2.98799206972764001461788317539150909754, -1.510594722031058113824911357742024792845, 0.3432044265344927046810278071226538100014,
      -57.03382210380496045118190681604479225117, -35.08538958209296189726356511163991551407, -1.837671411565652859834427241248535850488, -0.003463285776942052125913197948808879981098, 0.5133845409414163747840157939206194379759,
      21.73009042501717049712136794657127806511, -11.22153121403806680664442968680435633773, -5.152501451319085262908023899013025657394, -2.095607516918431410369494304164556510833, 0.5222218844325478716275632159479129582531,
  };

  const double gamma[] = { 7.293477190659286519470339272318890840413 };
  const double alpha[] = { 4.649348606363290454232001865356827891725, 6.703912798307066286032828498483726688067 };
  const double beta[] = { -7.142045840675952800772205226991909306832, -3.485322832366395445452646937918374204533 };

  const double A_part_inv[] = {
      11.18330013267037773989086012892593744696, 3.131312162011810835274612961546364914478, -0.7587317959808073905318921552256490821719, 0.2391012233536860499432317710450626622847, -0.05431476056533892370823464201185494830169,
      -9.447599601516149885127420878486756347847, 2.816699867329622260109139871074062553035, 2.217886332274818116899623167368125991838, -0.5571226202937973011826062428567480978308, 0.1183579496046673873215749075103437964386,
      6.420116503559336619975153316944029317543, -6.220120454669751668308558046671189144163, 2.0, 1.865995288831779493444982885513767335458, -0.3159913377213644451115781557866075088352,
      -8.015920784810970304463709598174255884543, 6.190522354953041821400885985004873203904, -7.393116276382380167011291621118496236493, 2.816699867329622260109139871074062553036, 1.550036766309846967985286187822844259737,
      22.42091502590609440348995489986372984221, -16.19339023999923498465294893223300242602, 15.4154432215698509221250420904575008083, -19.08560117865735976998433012273430467822, 11.18330013267037773989086012892593744696,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 1, 2, NULL, NULL);
}

void denseOutput_GAUSS6(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(dt*(dt*(28.97867220869568670696536 - 8.141261729008675572710428*dt) - 40.40836214083929518310538) + 27.78539055506886821337222) - 9.69444984787807092507418) + 1.565673200151071932738285;
  tableau->b_dt[1] = dt*(dt*(dt*(dt*(24.5337387406955313936922*dt - 83.3343792263619446848799) + 107.8110526437797865347941) - 64.86334697344168417895328) + 16.97377844502872916807496) - 0.9404628431763489277291894;
  tableau->b_dt[2] = dt*(dt*(dt*(dt*(113.6832974690219996604287 - 36.16834049547210301700248*dt) - 130.8540651977090431843572) + 65.10138838898368337822447) - 12.14525325296868002204901) + 0.6169300554304887058203335;
  tableau->b_dt[3] = dt*(dt*(dt*(dt*(36.16834049547210261301717*dt - 103.3267455038106176737392) + 104.9626852846805898729287) - 44.84870762107455330454365) + 7.657612014133437770294686) - 0.3792277021146137486624434;
  tableau->b_dt[4] = dt*(dt*(dt*(dt*(63.86805321781124357030767 - 24.53373874069553130227924*dt) - 59.14523762240303412292029) + 23.71184615196864317386496) - 3.912342234195919969888969) + 0.1918000140386679528147223;
  tableau->b_dt[5] = dt*(dt*(dt*(dt*(8.141261729008675885282672*dt - 19.86889816535636757908232) + 17.63392703249099608265977) - 6.886570501504957281964625) + 1.120654875880503978642494) - 0.05471272432926591498170661;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// TODO: Describe me
void getButcherTableau_GAUSS6(BUTCHER_TABLEAU* tableau)
{
  //implicit Gauss-Legendre, order 2*s, but embedded scheme has order s

  tableau->nStages = 6;
  tableau->order_b = 2*tableau->nStages;
  tableau->order_bt = tableau->nStages - 1;
  tableau->fac = 1.0;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_GAUSS6;

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

  const double T[] = {
      0.05819683935124533314911203101952425284358, 0.01062152459310018313199363717518304567091, -0.0004746860484211858111608812112351382463726, -0.01921278325428977724269892914965453894981, -0.00235681976437158541906022285308857072551, -0.003177782710744506699484802371032335488547,
      -0.1215758135445271454597586360295355513517, 0.0, 0.01442091809146646435345065098028802009371, 0.02602632232137340314773930072090330315228, 0.002941489411118684236986634547883615348973, 0.00168123065728675620144692573672573396192,
      0.2442333476716466341990224494944017253434, -0.1034843360479971971328629452729889031961, -0.02554199437406594590880776440672062478007, 0.01784039361333296999716470083259079887593, 0.0009243261163793195253317369338204985665452, -0.008475334509244045017164613916401537952978,
      -0.2656065435197511550550565046939077414743, 0.6014736332403497379588638572970355887575, -0.2214875160995942478676042513701476070444, 0.0, 0.04570485885553615895431239704346178379978, -0.02718216003024652855300999473237305800227,
      -1.260107221648044085093700477177678381058, -1.078999721026795053186743428998621083242, -0.4287233565511875140024312513805998977395, -1.058729747126248293033772175349953539975, 0.304101382122127392340523983467495195864, -0.07664808166169705959481845218970346541497,
      1.0, -3.165704361806567902232981719484219334379, 1.0, -2.918135493882638647778178244313391685839, 1.0, 0.0,
  };

  const double T_inv[] = {
      -2.845253842542181554792756974029665087239, -4.782550498200484074792798922715820027441, 1.308563721296768892382996006809439439714, 0.215649761341470304382930262204969038454, -0.2081110615058965058726423368697217778863, 0.05958315106980261841434685561994927298963,
      3.729024127142732630487442086792070525363, -1.21920159004996221168005033270283770315, -2.17365740529480671946516070330148298055, 1.000563193693654344649996668545792306372, -0.2958297485233179423246460492210778672959, 0.05861571049456421855089674896808375933753,
      35.10591074875389467428313257331890200671, 25.90321350163068798574667563400524167247, -0.3327751195480372218010139658283992990618, -0.6153631714635718282345716523482991733333, -0.6322715174670294389669233340718896758887, 0.2272515980386304700078796442828330614505,
      -10.23642127812902738752288980937832394265, 11.91681092488190180105359254237172597496, 7.163267968471419528862877616768165322931, 0.7992654130156962829327949079820259306681, -0.3897399844355586883145615573320567664608, 0.01619038624866213238912315971842440945678,
      -50.32693322367783528220877492962831833242, 9.794574138813399998320765671535001334358, 13.04644118022538335002568953192470831371, 5.899565447415082969620156478634841273828, -1.233441028246152707554212064518149202617, 0.9459710020464902286056916079073339919118,
      -260.357477667464378861674032468098642792, -174.8433416109965751208330708174578391066, -36.23587733711121805597974087130028813489, -1.822207721476954667948237294424499052019, -1.434475189058847998141941112030882310654, 0.4536875908856169837921210999406586510558,
  };

  const double gamma[] = {  };
  const double alpha[] = { 5.031864495621642774245116554146952829577, 7.47141671265162933588272393956048621508, 8.496718791726727889872159506292560955338 };
  const double beta[] = { -8.985345907307885071836487841700655722412, -5.252544622894251280987103176618812732347, -1.735019346462731212772883142500590703561 };

  const double A_part_inv[] = {
      15.32559943877134810291330377951104089402, 4.428784593210072962562794358135200768771, -1.135792531200900913361545189434368833845, 0.4136558226524937119178704526283795504533, -0.1537363938179938229939126930621035408299, 0.03747594392723112965647722377429377405147,
      -12.27449151016906408662667928446698215309, 3.553646711862092105198489815866834937049, 3.104594335912446176940805523770551435049, -0.8962488866310468971150149574131487188661, 0.3084380741837899184933458668943631180377, -0.07300891114463974895157950338498592680059,
      7.3152536048277401633713305287682793454, -7.214666938638727677327275078776365932649, 2.120753849366559791888206404622124168927, 2.576076559634156611098818162595398987216, -0.6910077565416664142984095472654927956789, 0.1514581391989234463726075832383778559242,
      -7.05084663619705766195910197506038377504, 5.51203293000633515475857142554820015323, -6.817584258367276194875230971839647325068, 2.120753849366559791888206404622124168927, 2.393641765174058936867113200493658575098, -0.4158651078296059477848361369462734262881,
      10.24428508749221524726642191025332196249, -7.415731497907974128890325498628032992139, 7.149201047056500819382640271798621728013, -9.357546496337900099208430838156024444196, 3.553646711862092105198489815866834937048, 2.103215333821488588311836877598646117407,
      -30.68867482146992733548308478279637556212, 21.57160573829669739604721954283601850167, -19.25696288835293632212376234618755233478, 19.97909959690134352356743708299354161816, -25.84665393768877653561610120790911572958, 15.32559943877134810291330377951104089402,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, FALSE, 0, 3, NULL, NULL);
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
  const double bt[] = {1.0, 0.0}; // explicit Euler

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
  tableau->fac = 7;

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
  tableau->error_order = fmin(tableau->order_b, tableau->order_bt);
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

  // set optionals to default value
  tableau->t_transform = NULL;
  tableau->svp = NULL;

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
    case RK_SDIRK4:
      getButcherTableau_SDIRK4(tableau);
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
    case RK_ESDIRK4_7L2SA:
      getButcherTableau_ESDIRK4_7L2SA(tableau);
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
    case RK_RADAU_IIA_5:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IIA_5(tableau);
      break;
    case RK_RADAU_IIA_6:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IIA_6(tableau);
      break;
    case RK_RADAU_IIA_7:
      if (extrapolMethod == GB_EXT_DEFAULT) tableau->richardson = TRUE;
      getButcherTableau_RADAU_IIA_7(tableau);
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
      throwStreamPrint(NULL, "Error: Unknown Runge Kutta method.");
  }

  return tableau;
}

void freeStageValuePredictors(STAGE_VALUE_PREDICTORS *svp)
{
  free(svp->A_predictor);
  free(svp->type);
  free(svp);
}

void freeTTransform(T_TRANSFORM *t_transform)
{
  free(t_transform->A_part_inv);
  free(t_transform->T);
  free(t_transform->T_inv);
  free(t_transform->alpha);
  free(t_transform->beta);
  free(t_transform->gamma);
  if (t_transform->phi) free(t_transform->phi);
  if (t_transform->rho) free(t_transform->rho);
  free(t_transform);
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

  if (tableau->t_transform)
  {
    freeTTransform(tableau->t_transform);
  }

  if (tableau->svp)
  {
    freeStageValuePredictors(tableau->svp);
  }

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
    if (!tableau->richardson){
      ct = snprintf(buffer, buffSize, "%10s | ", "");
      for (j = 0; j<tableau->nStages; j++) {
        ct += snprintf(buffer+ct, buffSize-ct, "%10g", tableau->bt[j]);
      }
      infoStreamPrint(OMC_LOG_SOLVER, 0, "%s", buffer);
    }
    messageClose(OMC_LOG_SOLVER);
  }
}
