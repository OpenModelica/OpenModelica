/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
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

/* y := alpha * A * x + beta * y */
extern void dgemv_(const char *trans,
                   const int *m,
                   const int *n,
                   const double *alpha, const double *A, const int *ldA,
                   const double *x, const int *incX,
                   const double *beta, double *y, const int *incY
);

/* y := a * x + y */
extern void daxpy_(const int *n,
                   const double *alpha,
                   const double *x, const int *incX,
                   double *y, const int *incY);

static const double DBL_ZERO = 0.0;
static const double DBL_ONE = 1.0;
static const int INT_ONE = 1;
static const char CHAR_NO_TRANS = 'N';

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
  tableau->contraction = NULL;
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

void setContractiveDefectError(BUTCHER_TABLEAU *tableau, const double *dT_A, modelica_boolean only_filter)
{
  if (tableau->t_transform == NULL && !only_filter)
  {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Cannot set contractive error, if T-Transformation is NULL and filtering is disabled. Defaulting to standard embedded scheme.");
    return;
  }

  CONTRACTIVE_ERROR *contraction = (CONTRACTIVE_ERROR *) malloc(sizeof(CONTRACTIVE_ERROR));

  tableau->contraction = contraction;

  if (!only_filter)
  {
    // perform contractive defect: ERR := ((1 / (h * gamma)) * I - J)^(-1) (f(t0, x0) - 1/h * d^T * A * k)
    contraction->dT_A = (double *) malloc(tableau->nStages * sizeof(double));
    memcpy(contraction->dT_A, dT_A, tableau->nStages * sizeof(double));

    // order of contractive error is = s
    tableau->order_bt = tableau->nStages;
  }
  else
  {
    // perform filtering only: ERR = (I - h gamma J)^(-1) * ERR, where previous ERR is unbounded for z -> -oo
    contraction->dT_A = NULL;

    // order stays the same
  }

  contraction->apply_filter_only = only_filter;
}

void setTTransformLowerTriangular(BUTCHER_TABLEAU *tableau, const double *A_part_inv, const double *T, const double *T_inv, const double *gamma, const double *alpha, const double *beta,
                                  modelica_boolean f_row_zero, modelica_boolean l_col_zero, int n_real_blocks, int n_cmplx_blocks, int n_real_eigs, int n_cmplx_eigs,
                                  const int *real_eig_index, const int *cmplx_eig_index, const double *L, const modelica_boolean *hasL, const double *phi, const double *rho)
{
  tableau->t_transform = (T_TRANSFORM *) malloc(sizeof(T_TRANSFORM));

  T_TRANSFORM *tr = tableau->t_transform;
  tr->firstRowZero = f_row_zero;
  tr->lastColumnZero = l_col_zero;
  tr->nRealEigenvalues = n_real_eigs;
  tr->nComplexEigenpairs = n_cmplx_eigs;
  tr->nRealBlocks = n_real_blocks;
  tr->nComplexBlocks = n_cmplx_blocks;
  tr->size = n_real_blocks + 2 * n_cmplx_blocks;

  assert(tr->size == tableau->nStages - (int)f_row_zero - (int)l_col_zero);
  assert(n_real_eigs <= n_real_blocks);
  assert(n_cmplx_eigs <= n_cmplx_blocks);

  tr->A_part_inv = (double *) malloc(tr->size * tr->size * sizeof(double));
  tr->T = (double *) malloc(tr->size * tr->size * sizeof(double));
  tr->T_inv = (double *) malloc(tr->size * tr->size * sizeof(double));
  tr->gamma = (double *) malloc(n_real_eigs * sizeof(double));
  tr->alpha = (double *) malloc(n_cmplx_eigs * sizeof(double));
  tr->beta = (double *) malloc(n_cmplx_eigs * sizeof(double));
  tr->realEigenvalueIndex = (int *) malloc(n_real_blocks * sizeof(int));
  tr->complexEigenpairIndex = (int *) malloc(n_cmplx_blocks * sizeof(int));
  tr->L = (double *) calloc(tr->size * (tr->size - 1) / 2, sizeof(double));
  tr->hasL = (modelica_boolean *) calloc(tr->size, sizeof(modelica_boolean));

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

  if (real_eig_index)
  {
    memcpy(tr->realEigenvalueIndex, real_eig_index, n_real_blocks * sizeof(int));
  }
  else
  {
    for (int i = 0; i < n_real_blocks; i++) tr->realEigenvalueIndex[i] = i;
  }

  if (cmplx_eig_index)
  {
    memcpy(tr->complexEigenpairIndex, cmplx_eig_index, n_cmplx_blocks * sizeof(int));
  }
  else
  {
    for (int i = 0; i < n_cmplx_blocks; i++) tr->complexEigenpairIndex[i] = i;
  }

  if (L)
  {
    memcpy(tr->L, L, tr->size * (tr->size - 1) / 2 * sizeof(double));
  }

  if (hasL)
  {
    memcpy(tr->hasL, hasL, tr->size * sizeof(modelica_boolean));
  }
}

void setTTransform(BUTCHER_TABLEAU *tableau, const double *A_part_inv, const double *T, const double *T_inv, const double *gamma, const double *alpha, const double *beta,
                   modelica_boolean f_row_zero, modelica_boolean l_col_zero, int n_real_eigs, int n_cmplx_eigs, const double *phi, const double *rho)
{
  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, alpha, beta,
                               f_row_zero, l_col_zero, n_real_eigs, n_cmplx_eigs, n_real_eigs, n_cmplx_eigs,
                               NULL, NULL, NULL, NULL, phi, rho);
}

// TODO: Describe me
void denseOutput(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  if (idx == NULL)
  {
    // split BLAS operations into matrix-vector product and axpy operation to ensure proper numerical stability in dgemv
    // alternative: memcpy(y, yOld) and then provide beta = 1 instead of the additional axpy operation
    // flops should be roughly the same in both cases

    // y := K * b_dt + y
    int nStages = (int)tableau->nStages;
    double dt_h = dt * stepSize;

    // y := dt * h * (K otimes I) * b_dt
    dgemv_(&CHAR_NO_TRANS,
           &nStates,
           &nStages,
           &dt_h, k, &nStates,
           tableau->b_dt, &INT_ONE,
           &DBL_ZERO, y, &INT_ONE);

    // y := yOld + y = yOld + dt * h * (K otimes I) * b_dt
    daxpy_(&nStates, &DBL_ONE, yOld, &INT_ONE, y, &INT_ONE);
  }
  else
  {
    for (int stage = 0; stage < tableau->nStages; stage++)
    {
      tableau->b_dt[stage] *= dt * stepSize;
    }

    for (int ii = 0; ii < nIdx; ii++)
    {
      int state = idx[ii];
      y[state] = yOld[state];

      for (int stage = 0; stage < tableau->nStages; stage++)
      {
        y[state] += tableau->b_dt[stage] * k[stage * nStates + state];
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
  tableau->isKRightAvailable = TRUE;

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
  tableau->isKRightAvailable = TRUE;

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
  tableau->isKRightAvailable = TRUE;
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
  tableau->isKRightAvailable = TRUE;

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
 *  => Quartic C0 interpolant (order 4), pinned to 2 L-stable points (at theta=0.08493322596570153 and theta=0.5709617099460419) for
 *     stability on stiff problems. Preferred over the C1 interpolant for stiff ODEs despite ~2x larger error on non-stiff problems.
 *     (see e.g. https://github.com/WRKampi/extensisq for numeric values, MIT license)
 */
void denseOutput_C0_ESDIRK4_7L2SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((-9.810193992009567 * dt + 19.33290157583574) * dt + (-11.67529655238061)) * dt + 1.751737353544831;
  tableau->b_dt[1] = ((-9.810193992009567 * dt + 19.33290157583574) * dt + (-11.67529655238061)) * dt + 1.751737353544831;
  tableau->b_dt[2] = ((16.15992821734386 * dt + (-30.87602826958563)) * dt + 17.31058741533003) * dt + (-1.65533494856435);
  tableau->b_dt[3] = ((8.166079369090214 * dt + (-18.38973592743151)) * dt + 12.32790098775139) * dt + (-1.585702145515156);
  tableau->b_dt[4] = ((-12.76282880391497 * dt + 25.48988276667239) * dt + (-13.43221397813055)) * dt + 1.480670047540331;
  tableau->b_dt[5] = ((6.741924328533505 * dt + (-12.78698063999065)) * dt + 6.127838415643804) * dt + (-0.6392836047534802);
  tableau->b_dt[6] = ((1.315284872966521 * dt + (-2.102941081336072)) * dt + 1.016480264166559) * dt + (-0.1038240557970074);
  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

/* Alternative dense output of the ESDIRK4(3)7L2SA
 *  => Quartic C1 interpolant (order 4), 2 free parameters minimized for smallest squared error.
 *     Smoother than C0 but fails on stiff problems as it is not pinned to L-stable points.
 *     (see e.g. https://github.com/WRKampi/extensisq for numeric values, MIT license)
 */
void denseOutput_C1_ESDIRK4_7L2SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
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
  tableau->dense_output = denseOutput_C0_ESDIRK4_7L2SA;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = TRUE;

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

// order 2 dense output, minimal (L2-norm) leading coefficient for order 3 linear problems
void denseOutput_SDIRK3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = -0.7500000000000000 * dt + 1.9584966491760105;
  tableau->b_dt[1] = -0.2726301276675501 * dt + (-0.3717330430169189);
  tableau->b_dt[2] =  1.0226301276675507 * dt + (-0.5867636061590916);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

// 3-stage order 3(2), L-stable SDIRK
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
  const double bt[] = {0.825, 0.1226301276675510709204581, 0.05236987233244892907954193};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SDIRK3;
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;

  const double A_predictor[] = {
                                0, 0, 0,
                                0.7179332607542294997080097,                            0,  0,  // order 1, R(-inf) = 0 => L-stable
                                0.7726301276675510709204581,  0.2273698723324489290795419,  0,  // order 2, R(-inf) = 0 => L-stable
                               };

  const STAGE_VALUE_PREDICTOR_TYPE svp_type[] = {SVP_NOT_AVAILABLE, SVP_LINEAR_COMBINATION, SVP_LINEAR_COMBINATION};

  setContractiveDefectError(tableau, NULL, TRUE);

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
  tableau->isKRightAvailable = TRUE;

  setContractiveDefectError(tableau, NULL, TRUE);

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

// unique order 2 dense output
void denseOutput_SDIRK2(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
    tableau->b_dt[0] = -0.707106781186547524400844362104849 * dt +   1.414213562373095048801688724209;  // -1/sqrt(2), sqrt(2)
    tableau->b_dt[1] =  0.707106781186547524400844362104849 * dt + (-0.414213562373095048801688724209); //  1/sqrt(2), 1-sqrt(2)

    denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  const double bt[] = {0.585786437626904951198311275790301, 0.414213562373095048801688724209};

  setButcherTableau(tableau, c, A, b, bt);
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SDIRK2;
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;

  setContractiveDefectError(tableau, NULL, TRUE);

  // predictor can't be stable for stage 2
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

  const double *gamma = NULL;
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
  tableau->isKRightAvailable = TRUE;
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

  const double *gamma = NULL;
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
  tableau->isKRightAvailable = TRUE;
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

  const double dT_A[] = { 1.558078204724922382431975, -0.8914115380582557157653087, 0.3333333333333333333333333 };

  setContractiveDefectError(tableau, dT_A, FALSE);
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
  tableau->isKRightAvailable = TRUE;
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

  const double *gamma = NULL;
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
  tableau->isKRightAvailable = TRUE;
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

  const double dT_A[] = { 1.586407900186328249755967, -1.008117881498372989065673, 0.7309748661597874614134016, -0.5092648848477427221036966, 0.2 };

  setContractiveDefectError(tableau, dT_A, FALSE);
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
  tableau->isKRightAvailable = TRUE;
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

  const double *gamma = NULL;
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
  tableau->isKRightAvailable = TRUE;
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

  const double dT_A[] = { 1.594064218561041781197339, -1.036553752196476461002723, 0.7938217234907926875176341, -0.6325776522499342252619287, 0.4976107136030013134425167, -0.3592223940655679530356959, 0.1428571428571428571428571 };

  setContractiveDefectError(tableau, dT_A, FALSE);
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
  tableau->isKRightAvailable = TRUE;
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

  const double *gamma = NULL;
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
  tableau->isKRightAvailable = TRUE;
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

// only order 2 accurate dense output: order 3 cannot exist
void denseOutput_LOBATTO_IIIB_3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(0.6666666666666666666666667*dt - 1.5) + 1.0;
  tableau->b_dt[1] = dt*(2.0 - 1.333333333333333333333333*dt);
  tableau->b_dt[2] = dt*(0.6666666666666666666666667*dt - 0.5);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_LOBATTO_IIIB_3;

  const double T[] = {
      -0.5, -0.8660254037844386467637231707529361834716,
      1.0, 0.0,
  };

  const double T_inv[] = {
      0.0, 1.0,
      -1.154700538379251529018297561003914911295, -0.5773502691896257645091487805019574556471,
  };

  const double *gamma = NULL;
  const double alpha[] = { 3.0 };
  const double beta[] = { -1.732050807568877293527446341505872366943 };

  const double A_part_inv[] = {
      4.0, 2.0,
      -2.0, 2.0,
  };

  setTTransform(tableau, A_part_inv, T, T_inv, gamma, alpha, beta, FALSE, TRUE, 0, 1, NULL, NULL);
}

// only order 3: order 4 cannot exist
void denseOutput_LOBATTO_IIIB_4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(3.333333333333333333333333 - 1.25*dt) - 3.0) + 1.0;
  tableau->b_dt[1] = dt*(dt*(2.795084971874737120511467*dt - 6.423503277082807574356268) + 4.045084971874737120511467);
  tableau->b_dt[2] = dt*(dt*(4.756836610416140907689601 - 2.795084971874737120511467*dt) - 1.545084971874737120511467);
  tableau->b_dt[3] = dt*(dt*(1.25*dt - 1.666666666666666666666667) + 0.5);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_LOBATTO_IIIB_4;

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

// order 3 accurate dense output, as A * c = [0, 1/8, 1/2] == A * c of IIIA
void denseOutput_LOBATTO_IIIC_3(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(0.6666666666666666666666667*dt - 1.5) + 1.0;
  tableau->b_dt[1] = dt*(2.0 - 1.333333333333333333333333*dt);
  tableau->b_dt[2] = dt*(0.6666666666666666666666667*dt - 0.5);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_LOBATTO_IIIC_3;

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

// order 4
void denseOutput_LOBATTO_IIIC_4(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = dt*(dt*(3.333333333333333333333333 - 1.25*dt) - 3.0) + 1.0;
  tableau->b_dt[1] = dt*(dt*(2.795084971874737120511467*dt - 6.423503277082807574356268) + 4.045084971874737120511467);
  tableau->b_dt[2] = dt*(dt*(4.756836610416140907689601 - 2.795084971874737120511467*dt) - 1.545084971874737120511467);
  tableau->b_dt[3] = dt*(dt*(1.25*dt - 1.666666666666666666666667) + 0.5);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_LOBATTO_IIIC_4;

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

  const double *gamma = NULL;
  const double alpha[] = { 2.220980032989806897423925140476047787088, 3.779019967010193102576074859523952212912 };
  const double beta[] = { -4.160391445506931982228485188880642430211, -1.380176524272843046226884893083007281595 };

  const double A_part_inv[] = {
      6.0, 8.090169943749474241022934171828190588602, -3.090169943749474241022934171828190588601, 1.0,
      -1.61803398874989484820458683436563811772 /* golden ratio nice! */, 0.0, 2.236067977499789696409173668731276235441, -0.6180339887498948482045868343656381177202,
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

  const double *gamma = NULL;
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

  const double dT_A[] = { 1.478830557701236147529878, -0.6666666666666666666666667, 0.1878361089654305191367891 };

  setContractiveDefectError(tableau, dT_A, FALSE);
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

  const double *gamma = NULL;
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

  const double dT_A[] = { 1.551408049094313012813028, -0.8931583920000717373261768, 0.5333333333333333333333333, -0.2679416522233875093041099, 0.07635866179581290048392539 };

  setContractiveDefectError(tableau, dT_A, FALSE);
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

  const double *gamma = NULL;
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

// unique order 2 dense output
void denseOutput_TRAPEZOID(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = -0.5 * dt + 1.0;
  tableau->b_dt[1] =  0.5 * dt;

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
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
  const double bt[] = {0.0, 1.0};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_TRAPEZOID;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = TRUE;
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
  const double b[] = {35./384, 0.0, 500./1113, 125./192, -2187./6784, 11./84, 0.0};
  const double bt[] = {5179./57600, 0.0, 7571./16695, 393./640, -92097./339200, 187./2100, 1./40};

  setButcherTableau(tableau, c, A, b, bt);

  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_DOPRI45;
  tableau->isKLeftAvailable = TRUE;
  tableau->isKRightAvailable = TRUE;
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

/* SIRK3(2)4L[3]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 3
 */
void denseOutput_SIRK3_2_4L3SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((12.14845596004806624122215900267477576206 * dt - 15.07636801077929049328546847471580325153) * dt + 5.094510410495165135466613956872210162433);
  tableau->b_dt[1] = ((-18.67611666011345622713015754590645043165 * dt + 20.17898976874423160081419720942018869209) * dt - 3.610200012155823514529243753024512466647);
  tableau->b_dt[2] = ((13.87111783348683230211173534297544340046 * dt - 9.133645992789968701853984021435739801141) * dt - 3.031641698244440218610838622956685702152);
  tableau->b_dt[3] = ((-7.343457133421442316203736799742813516391 * dt + 4.031024234825027594325255286732309575054) * dt + 2.547331299905098597673468419109943220844);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK3_2_4L3SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 4;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  const double c[] = {
      0.3924050632911392405063291139240506329114, 0.5178571428571428571428571428571428571429, 0.8829787234042553191489361702127659574468, 1.0
  };

  const double A[] = {
      2.110455313955157408740060400778703758181, -2.314289794300208588790347030814177389742, 1.272679050736730576546959019462440672145, -0.6764395071005401559903432755046380263084,
      2.45968036456693610516039552435948924704, -2.738529643963157842638568734071051606356, 1.791488780754060964430778847125511547475, -0.9947823585006963698097484945553448212112,
      2.529891533176930901987119235424728697061, -2.72093332020245526441086494544963882039, 2.28917592869931655810352142719435890467, -1.215155418269536876530839546955427006598,
      2.166598359763940883403304484831567444568, -2.107326903525048140845204089510670557514, 1.705830142452423381646912698582031082508, -0.7651015986913161242050130939019827908717
  };

  const double b[] = {
      2.166598359763940883403304484831567444568, -2.107326903525048140845204089510670557514, 1.705830142452423381646912698582031082508, -0.7651015986913161242050130939019827908717
  };

  const double bt[] = {
      2.134246984384455698748982306489579869292, -2.028619792060449745592048286001129035046, 1.549520621184347866521330102219073696991, -0.6551478135083538196782641227085671530116
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK3_2_4L3SA;

  const double A_part_inv[] = {
      -80.94076296552636936169189605459374625654, 102.390402554200654603392025977773793827, -58.56723933822639869975191703309209547839, 31.45159011578804941570820169113473185482,
      -72.46154708010356543715282297656406174846, 90.0869768641165433206601787323272105284, -50.83079298431507695324663942632443292284, 27.66460221956948532337019102291658073541,
      67.58481292162023297227012270581032649464, -87.84535806913273804312658652563410629569, 48.90841198041670140106143432733856894871, -23.21436382328217904675174815903170475044,
      121.0587646999212346872595190072420649075, -154.0358713717599137878939011874296060388, 83.19791303770866705263966492171164307488, -40.19748302186401821717257414860089457765
  };

  const double T[] = {
      -0.5946012307931282500522403799928555034132, -0.6325171693630877249347801278500553310935, -0.471754319518118232724829270883469752383, 0.1543349241623594509844124256732774643831,
      0.6761801223277586211982947398843159842059, -0.0920014367643697340203558294900128584569, -0.7309428526971558695427963713142834089165, -0.006222852485232187434520094191893742739113,
      -0.3859319883816083904505427220077538471133, 0.5173962083253426868968398550004373658313, -0.4166912558613523409249774320241754851891, -0.6400984777696832451686373972027185140681,
      0.2007145207799687486161451616454170957604, -0.5689981807569838505675924061465919869874, 0.2637021148865327272608666292376365920139, -0.7526061028504088079929308703933693600191
  };

  const double T_inv[] = {
      -0.5946012307931282500522403799928555034132, 0.6761801223277586211982947398843159842059, -0.3859319883816083904505427220077538471133, 0.2007145207799687486161451616454170957604,
      -0.6325171693630877249347801278500553310935, -0.0920014367643697340203558294900128584569, 0.5173962083253426868968398550004373658313, -0.5689981807569838505675924061465919869874,
      -0.471754319518118232724829270883469752383, -0.7309428526971558695427963713142834089165, -0.4166912558613523409249774320241754851891, 0.2637021148865327272608666292376365920139,
      0.1543349241623594509844124256732774643831, -0.006222852485232187434520094191893742739113, -0.6400984777696832451686373972027185140681, -0.7526061028504088079929308703933693600191
  };

  const double gamma[] = {
      4.464285714285714285714285714285714285714
  };
  const int real_eig_index[] = {
      0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -45.02620203658075677138661355699933559458,
      -169.1630286473195371004807910426578435062, 5.640388831799288733398544502424513441099,
      263.3806239842497056326108330796725276706, -6.073750572015246623475168186768110936561, -12.00651748930180257997790618864309925874
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 4, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK3(2)5L[3]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 3
 */
void denseOutput_SIRK3_2_5L3SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((1.211834414914790788988557454774912899752 * dt - 1.71353086283050875309371567563289517152) * dt + 1.320866379350105394465341373768070662978);
  tableau->b_dt[1] = ((-0.2141328853276802242487199861240366779265 * dt - 1.76135233576388170158890624396799302453) * dt + 1.578899864422757755122974521727862191921);
  tableau->b_dt[2] = ((-2.136060582441859203201501423747235429854 * dt + 5.073277036428185128924619078889391733089) * dt - 2.789690045140010559504834256160964094185);
  tableau->b_dt[3] = ((-0.2559736012524525716765952405388385264067 * dt + 0.7993230819271432241428272940512480234106) * dt + 0.02119740456800018014816718455268376635173);
  tableau->b_dt[4] = ((1.394332654107201210138259195635184554174 * dt - 2.397716919760937898384824453339764740712) * dt + 0.8687263967991472297683511761123342926714);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK3_2_5L3SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  const double c[] = {
      0.256097560975609756097560975609756097561, 0.385542168674698795180722891566265060241, 0.6573426573426573426573426573426573426573, 0.8516483516483516483516483516483516483516, 1.0
  };

  const double A[] = {
      0.7551235931363042883273035521073605359126, -0.5852693351948411051244010693232597450229, -0.0591500019163336241385377132865407420479, 0.2794563275050621999371475094009397321154, -0.1340630225545820029039513032885100006521,
      0.8983241765265808879552139041356075738377, -0.6333965226189115292410768760436329064477, -0.1013467504188582698229022553006908358713, 0.4508066030595386753284155547175510950848, -0.2288453378736509690389274359433678171225,
      0.798308455277279454855747049842518285418, -0.380045981710818043405121813758326511424, 0.1445785388823616850078540964781082867527, 0.2117313688331975309126924432094501401402, -0.1172297239393632847138291184311606900026,
      0.8269238912365132578735560752505735179304, -0.3747401508875654896416082642870257622477, 0.01013414503848817057733854172806302901162, 0.6783522594548350143841333090475259503718, -0.2890217931939193048417713100906366739962,
      0.8191699314343874303601831529100774505509, -0.3965853566688041707146517083641754659269, 0.1475264088463153662182833989811945718161, 0.564546885242690832614399238065106365588, -0.1346578688545894584782140815922227043949
  };

  const double b[] = {
      0.8191699314343874303601831529100774505509, -0.3965853566688041707146517083641754659269, 0.1475264088463153662182833989811945718161, 0.564546885242690832614399238065106365588, -0.1346578688545894584782140815922227043949
  };

  const double bt[] = {
      0.8458492124678900658111292150057927472306, -0.4312399966104417037434353049736868507957, 0.1941680310721804437429846883697167017554, 0.4665698029589058647161120257450054501929, -0.07534704988853467052679062414654394582976
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK3_2_5L3SA;

  const double A_part_inv[] = {
      -58.07314075405004460430725755059720497532, 58.42843192090919856064042974523853553578, 5.421032659046369433069455643099407074592, -27.79170968591034811754266223456493852878, 13.45105308011237414115088004453676975572,
      -66.96807238422486208506144516653164505138, 65.41688830394929107013830294538501667209, 5.588841904369921665837160250941994542514, -29.83107656749388517946042763649711363549, 14.6611940138983393181505440415876999631,
      80.53050442334723692833542141016420133722, -84.17881256331995595714788467370166118678, -2.930993494692929833995994678481827178286, 39.14264765185203355475658477217761480778, -18.57828811422793793576498872916092934673,
      -4.702550597222075582285557451566837400721, 4.793044718134478474129763011299386142889, -2.788565441364423525635274941558832471719, -2.491384306562692045969955185382020364531, 4.311217238535671903400109223620651112537,
      -87.5377586933493820515380540353269878124, 90.64999499958250472473348757449666223279, 1.61608983280306663554492288991071660588, -48.77170448915712228138163402770122629633, 28.94282778222057294499910200408491889401
  };

  const double T[] = {
      -0.7422142052612821448842905481620580514664, -0.5256511185077544130111294818827202205677, 0.3559082563886533014921216634657171775464, 0.212332908722580735935035599365437039199, 0.03245033170411184062167933953074342113733,
      0.5947171829502215200912147936214434753996, -0.3472678555903091259329911619679183203727, 0.7205075268297464503959021122916899240886, -0.0009511222292633062173299475656371765722593, 0.08114498090238331300582376643366365763369,
      0.0316172803340841969278832248792901396641, -0.5552331908534957591546909402242517541568, -0.2823938269482459604242186384640599863556, -0.7739347395560723533852111103208084682431, -0.1095225856557452485298665337719679797206,
      -0.2766805634450322610325060384894508177635, 0.4636686388447425223988298292504946091197, 0.3958758246958207544043415319170256411057, -0.5578068969163240790790119825360247493916, 0.4905028606823699254377975563545098638376,
      0.1337077380263816001086747004784900824476, -0.2825304146667473598324619944779279386836, -0.3431242846826769465592413830845839425195, 0.2116372271146290008233337759238331201444, 0.8601012817920552930584525355863355520704
  };

  const double T_inv[] = {
      -0.7422142052612821448842905481620580514664, 0.5947171829502215200912147936214434753996, 0.0316172803340841969278832248792901396641, -0.2766805634450322610325060384894508177635, 0.1337077380263816001086747004784900824476,
      -0.5256511185077544130111294818827202205677, -0.3472678555903091259329911619679183203727, -0.5552331908534957591546909402242517541568, 0.4636686388447425223988298292504946091197, -0.2825304146667473598324619944779279386836,
      0.3559082563886533014921216634657171775464, 0.7205075268297464503959021122916899240886, -0.2823938269482459604242186384640599863556, 0.3958758246958207544043415319170256411057, -0.3431242846826769465592413830845839425195,
      0.212332908722580735935035599365437039199, -0.0009511222292633062173299475656371765722593, -0.7739347395560723533852111103208084682431, -0.5578068969163240790790119825360247493916, 0.2116372271146290008233337759238331201444,
      0.03245033170411184062167933953074342113733, 0.08114498090238331300582376643366365763369, -0.1095225856557452485298665337719679797206, 0.4905028606823699254377975563545098638376, 0.8601012817920552930584525355863355520704
  };

  const double gamma[] = {
      6.172839506172839506172839506172839506173
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -46.97468078925615598888944783266537786,
      93.48732146490736177458189398852216941912, -7.047127374975832256400848860630818737555,
      138.5189887053226343406995122194370300707, -14.85212429357250404421693066437158188805, 8.983764614155039822351564258592700358422,
      145.2885870138217297077178763728110685972, -17.07324222270688328183815705439338005809, 5.441737197879833821814206833375410917209, 14.06817587550906913045367909881113005609
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 5, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK4(3)5L[3]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 4
 */
void denseOutput_SIRK4_3_5L3SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (((-4.33808140831440507228905103155290997831 * dt + 13.8174741731550727251869692626309427944) * dt - 15.97136727725731700873120687048870695795) * dt + 7.81909721969839783723465428689970453407);
  tableau->b_dt[1] = (((8.527567063194435949215979857782535244191 * dt - 25.2603931287867121671626074929897506778) * dt + 26.06628105352181842314946109439311295711) * dt - 10.39477934024369253851986171635733827795);
  tableau->b_dt[2] = (((-9.326153876270411097099367280922076387388 * dt + 23.03742759203433837735106243800531252376) * dt - 20.57608194495550856258340926279307053887) * dt + 7.644679763306799223266517356029181755422);
  tableau->b_dt[3] = (((-1.186955691215024179864899517064871222202 * dt + 3.056102003992147489633249496004201085429) * dt - 1.188722445263382984393823957412966415642) * dt - 0.2182668162673882540045037732170275594776);
  tableau->b_dt[4] = (((6.323623912605404400037337971757323946293 * dt - 14.65061064039484642500867370365070412321) * dt + 11.66989061395439013255897899630163255794) * dt - 3.85073082649411626797680615335451884948);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK4_3_5L3SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac = 1.0;

  const double c[] = {
      0.3469387755102040816326530612244897959184, 0.5140186915887850467289719626168224299065, 0.8732394366197183098591549295774647887324, 0.8913043478260869565217391304347826086957, 1.0
  };

  const double A[] = {
      1.320640597385347272607961053589073548741, -1.425534649586250566899994776401601973476, 0.5271826425554972138586220407120846413626, 0.4623329204643473927992527309159783169485, -0.5376827353087372307331879875920018131154,
      1.531671414721622251526429133387957271556, -1.597199464659601225305455946954102125586, 0.8293260841334033380336588341673719699133, 0.4850158883746566604568946806194185230628, -0.7347952309812959779825547386056369948073,
      1.386481014020600699231543468433649335393, -1.17961940249381246634788456872563317371, 1.121394698883494701474600747699242735427, 0.1622258805574086151611218443800887266014, -0.6172427543479732396602265622110820935847,
      1.569814016927972997732480662938467803578, -1.532345026885607609465821439196200306825, 0.9107548439209899600781032005724822585263, 0.9029911087199274116120570346100982417317, -0.9599105948571958034350803284890302692079,
      1.327122707281748481401365647488990689269, -1.061324352314150333317028257171487348621, 0.7798715341152179409348032503193384838141, 0.4621570512463520713700222483093313478864, -0.507826940329168160389162888946239075787
  };

  const double b[] = {
      1.327122707281748481401365647488990689269, -1.061324352314150333317028257171487348621, 0.7798715341152179409348032503193384838141, 0.4621570512463520713700222483093313478864, -0.507826940329168160389162888946239075787
  };

  const double bt[] = {
      2.012234317718305184354922503528720352839, -2.381690182330916481822647661299340365161, 0.1397227027143164100299340954514151781168, 2.995827050337972206074480679491729566073, -1.766093888439677318636689617173804137383
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK4_3_5L3SA;

  const double A_part_inv[] = {
      -52.85745030441606278521950325852866037287, 69.16361773150715431073324138298141903313, -29.54133667870019243145150313773500173476, -17.80700144079278929527241934606866232861, 25.45502479753495632867767298196915752235,
      -44.41824481354538846307118217758983269592, 55.86817970265626664247466660360955093202, -23.67481138381372345915063642349855503791, -13.41379713070475966842294132220008470101, 20.3226774920512498964030330042569361145,
      52.84183325728700877653848422047024596763, -71.11496193082656074795021858870685296382, 30.40543982151457241090854571661664418009, 17.34235824616188119336413836876985612456, -22.78700968820361654032303480503263201578,
      40.65384280451673995701081459723195862801, -54.67396625422183883851622782737230542681, 20.91457215516081946467255735196255034301, 13.92454398873787981535468755669941943992, -15.67538964899161943500911096123049994614,
      72.84399684638929237628759602345628886866, -94.98146254494176351612501886425674339338, 38.00473667304515882228035018103012703506, 20.80325101439307191993287444700361812993, -27.17942288591201092222807404120911583022
  };

  const double T[] = {
      0.6220683186624109403154087928869298515517, 0.4327923583784913212774394628422294994372, 0.5883630620186956968607561987383093039558, -0.1328787874870387357814443001522109735101, 0.2487848800342648006612757575869920484377,
      -0.6655640261700043773187445365487583278838, 0.1140751187572055747971855563199021328373, 0.6842392847766238339329905710910904176529, 0.275315995702675219608084148388871728579, -0.005394258755562664589288383353844365403828,
      0.3180458334000041568673117705694045892813, 0.09288496184646311866897742998878269499932, 0.03399653615476877498041300637789759120745, 0.6321772491359674149183476120547361793509, -0.6995822988927295442446885785789873101372,
      0.1341691804742977262239638734601949706204, -0.661866514491126519466047288884491046907, 0.4177392167363343717752406093999480242914, -0.4476694995053001701357082068794460386507, -0.4111171536428644844155509175687322558499,
      -0.2256125281376169745053035162194752105972, 0.594123507923951345835401985699726982517, -0.09991842047565638421480123406332790601834, -0.5536138322276403842901414528247011784465, -0.5288140301612349310668424967582311446589
  };

  const double T_inv[] = {
      0.6220683186624109403154087928869298515517, -0.6655640261700043773187445365487583278838, 0.3180458334000041568673117705694045892813, 0.1341691804742977262239638734601949706204, -0.2256125281376169745053035162194752105972,
      0.4327923583784913212774394628422294994372, 0.1140751187572055747971855563199021328373, 0.09288496184646311866897742998878269499932, -0.661866514491126519466047288884491046907, 0.594123507923951345835401985699726982517,
      0.5883630620186956968607561987383093039558, 0.6842392847766238339329905710910904176529, 0.03399653615476877498041300637789759120745, 0.4177392167363343717752406093999480242914, -0.09991842047565638421480123406332790601834,
      -0.1328787874870387357814443001522109735101, 0.275315995702675219608084148388871728579, 0.6321772491359674149183476120547361793509, -0.4476694995053001701357082068794460386507, -0.5536138322276403842901414528247011784465,
      0.2487848800342648006612757575869920484377, -0.005394258755562664589288383353844365403828, -0.6995822988927295442446885785789873101372, -0.4111171536428644844155509175687322558499, -0.5288140301612349310668424967582311446589
  };

  const double gamma[] = {
      4.032258064516129032258064516129032258065
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -13.51832585968350998269182336832436380121,
      -89.444546079243349818812327519403792861, 7.571284227469051745595330175744955144557,
      -52.04815627311411295262062700469385752483, 1.198912241434664034819674063588912786375, 3.513963379703586245748841733496497389805,
      -190.4831362582219258336998406097080670406, 12.61492885272747170961698269346035645155, 13.39784267793509911990929585809020479877, 7.256559917114660812960554454363868712258
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 5, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK5(4)5L[3]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 4
 */
void denseOutput_SIRK5_4_5L3SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (((-40.94942876313250036433308945757165447685 * dt + 93.09041971787153242942146742210436770209) * dt - 83.62519527519272547042488296826995181786) * dt + 36.65601090722744815620646474230531893728);
  tableau->b_dt[1] = (((72.10440500225137491187088708679734099433 * dt - 158.0159627453024233136397892054326798542) * dt + 135.3344156171563581748449806778523226075) * dt - 56.57410686216420689106313056980426663823);
  tableau->b_dt[2] = (((-56.2846150981423435082171523672057995796 * dt + 112.1797681495274255654462641338774810641) * dt - 87.44055192307521924722535283909917439818) * dt + 36.14469665306030150200384644646873514439);
  tableau->b_dt[3] = (((41.68914332413663676021490298580769003611 * dt - 77.50003674204087014598835132659010950636) * dt + 58.62903999895093741591715730866238448267) * dt - 25.7101682978678722429848425400359297362);
  tableau->b_dt[4] = (((-16.55950446511316779953554824782802257649 * dt + 30.24581161994433546476040897604049499182) * dt - 22.89770841783935087311190217914602647658) * dt + 10.48356759974432947583766192106569669026);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK5_4_5L3SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1.0;

  const double c[] = {
      0.3897116134060795011691348402182385035074, 0.4714747039827771797631862217438105489774, 0.6929791271347248576850094876660341555977, 0.9001536098310291858678955453149001536098, 1.0
  };

  const double A[] = {
      3.375451283069345925639090186275496956848, -3.925656307345272706574465427248297225343, 1.008590163870741221264618155066250619856, 0.1895487099544490311917655587391825461226, -0.2582222361431839703518736326137556798724,
      4.070514973119400341165867495985018135379, -4.989556901635133022746986049865982744766, 1.73851178693945335289088309326932575046, -0.2054143135571189929094437049582052304295, -0.1425808408838244986371346126883825862455,
      5.601808537595053514093893278010119932548, -7.538305234979021853256530837944458351126, 3.794363771295291611308384240073081723368, -1.468390330409409500570720267558977325911, 0.3035023836328110861099830750839991589823,
      5.71266632117937670429585623219600247508, -7.849440556544580584874930237071751879104, 4.43998506984982687267922457319953565119, -2.062155283783389157493177921021501189335, 0.6590980591297953512609228980131684035317,
      5.171806586773754750869959738568210755865, -7.15124898805889711798705201058702183243, 4.599297781370164312007605374041836913344, -2.892021716821168212841133572155121258879, 1.272166336736146267950620470133071146791
  };

  const double b[] = {
      5.171806586773754750869959738568210755865, -7.15124898805889711798705201058702183243, 4.599297781370164312007605374041836913344, -2.892021716821168212841133572155121258879, 1.272166336736146267950620470133071146791
  };

  const double bt[] = {
      5.861568995310649069921130261302657126537, -8.44970314912743086604733955839757695098, 5.846255584441229577308713080703608757618, -4.069131780807692427665574028573051835764, 1.811010350183244646483070244964469734598
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK5_4_5L3SA;

  const double A_part_inv[] = {
      -132.5237800156364871159517906116218810575, 174.998824771648671955330178808735590163, -61.93902964303681249406827050906759232331, 14.57928386455160388206634220568576443291, -0.06260328380480570089535486921530731571427,
      -136.2428688617558263832128608854769979296, 179.4440875074593803399395201939108747899, -64.72562704664826896807000435733341711626, 16.87335033987290923971362011454159933441, -0.8430184841973683901918429459697640707966,
      -61.95121306456777095797243855804976011487, 82.16616376008172878863750886158978559453, -35.1375223179991153923051829369549592945, 15.01431403280081786764538615594025139542, -2.761779970486822846242071782228397304806,
      62.49807392869227756278146733051728242513, -77.79519562311338345227484455365082144218, 14.35862205216423480876379735311666325368, 7.409475006390108379192851305077230334755, -3.297649448354503115166500357566114336432,
      138.9429503589693951355478999951631647279, -176.6300277203834134873886258381864179485, 47.63605202869381517527927983542990461355, -1.857182744786627851603480456267167325736, -1.210131325010275804759465004263446931976
  };

  const double T[] = {
      0.6019507326673412617020034235309357433872, 0.4905779210696832172809036389029554730374, 0.4456616113910037830218176192586195925855, -0.3752931868072132435697866531743233850881, -0.239852810841688464569429801873896254015,
      -0.7423408417146100991878239433581606093848, 0.2770920272678139491769923676850425644846, 0.1274420345792180391093513565589086344863, -0.5746122499086187236586129644868599325937, -0.1604037818267441614323761059061274782055,
      0.2772281939512006281818260813021032817735, -0.4917944279621687616684221614122240641893, -0.3356591442786285932342521292661257324154, -0.726323315094072132554687945452880803926, 0.2026577161541466948689710824850127330551,
      -0.09459324131401412251915994481959828925509, -0.3224925899742649785151987749006663120383, 0.7642197402527264260456719068316060102215, -0.01740226067883061800065316484776186174233, 0.5501963268150021716161576701360333333622,
      0.0279649305373610261940123390247867501452, 0.5802500166485258464860339586258151854764, -0.2973976856414277262934086763017288300061, -0.03357662081068432068629338652690232169992, 0.7569379815741076314070121152290877676411
  };

  const double T_inv[] = {
      0.6019507326673412617020034235309357433872, -0.7423408417146100991878239433581606093848, 0.2772281939512006281818260813021032817735, -0.09459324131401412251915994481959828925509, 0.0279649305373610261940123390247867501452,
      0.4905779210696832172809036389029554730374, 0.2770920272678139491769923676850425644846, -0.4917944279621687616684221614122240641893, -0.3224925899742649785151987749006663120383, 0.5802500166485258464860339586258151854764,
      0.4456616113910037830218176192586195925855, 0.1274420345792180391093513565589086344863, -0.3356591442786285932342521292661257324154, 0.7642197402527264260456719068316060102215, -0.2973976856414277262934086763017288300061,
      -0.3752931868072132435697866531743233850881, -0.5746122499086187236586129644868599325937, -0.726323315094072132554687945452880803926, -0.01740226067883061800065316484776186174233, -0.03357662081068432068629338652690232169992,
      -0.239852810841688464569429801873896254015, -0.1604037818267441614323761059061274782055, 0.2026577161541466948689710824850127330551, 0.5501963268150021716161576701360333333622, 0.7569379815741076314070121152290877676411
  };

  const double gamma[] = {
      3.596425771040722081223186588794554029053
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -22.58596035571910365970944826344197489356,
      -87.39017411315023544976678994067834969085, 3.696460265421947919493390153305989372577,
      290.7408654506376284404170002140602569188, -10.64998809574574848309416373409917714676, -2.628570156326884901062490542012182811864,
      297.0940584297276166977641507823311122966, -7.472108500351103190607077961270696656903, 30.83988106483085148290198973504632672568, 19.74265694784862237314819326591325043213
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 5, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK4(3)6L[4]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 4
 */
void denseOutput_SIRK4_3_6L4SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (((-7.641950844712842754843055045550273848042 * dt + 20.74949278815255092789423576219672178773) * dt - 19.01028129057561074475850579430203791054) * dt + 6.946885639699900975167570112691718744785);
  tableau->b_dt[1] = (((-6.296325971971680981698057153079077614859 * dt + 14.87508514483355324783043436502604042506) * dt - 11.65992621135788091190483499101055438744) * dt + 3.780700132896547079921993374398125643097);
  tableau->b_dt[2] = (((12.2512156716016192408688814437637956951 * dt - 31.79934346696645738007798627407990255463) * dt + 26.7669934988363377930186748246153865526) * dt - 8.201423011324581014098497218958620848509);
  tableau->b_dt[3] = (((-1.183503082039272863850702599928591942254 * dt + 0.7890184357848384829717492154804970977019) * dt + 0.03292655571819218919443471343697744494078) * dt - 0.4903341556310419893256978289677453288675);
  tableau->b_dt[4] = (((1.339390612331885116942928848241455147784 * dt - 2.769200558452614646172678315609803884167) * dt + 3.311579552607195196906450784421118685274) * dt - 1.168344215028521552359988857055868109628);
  tableau->b_dt[5] = (((1.531173614790292242580004506552477935862 * dt - 1.845052343351870632445754753013767498099) * dt + 0.558707894771766477543780462838894988765) * dt + 0.1325156093876965006946204178921752727175);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK4_3_6L4SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 6;
  tableau->order_b = 4;
  tableau->order_bt = 3;
  tableau->fac = 1.0;

  const double c[] = {
      0.2201834862385321100917431192660550458716, 0.6060606060606060606060606060606060606061, 0.3269230769230769230769230769230769230769, 0.8571428571428571428571428571428571428571, 0.7291666666666666666666666666666666666667, 1.0
  };

  const double A[] = {
      0.9065760307362414221301669835511117816158, 0.5011117402084431186542355242724014460752, -0.9938797579040008096640789102454105390953, -0.3906814244174660048256585293921158111555, 0.06033839582208373517910974977098141274522, 0.1367185017932306486179683013070268446323,
      0.9171763023022223909488239901040830428479, 0.7160812422302112090729615718344192126825, -0.7644759070175900728181119714916894963639, -0.3698333311310712069873279862587180916135, -0.02780874797389130828568004255550007880331, 0.1349210476507250486753950444301617320636,
      0.9945602945855246676073939778112507818983, 0.6693975750248687301875546615909245611405, -1.018238987735013229995195716896997158299, -0.3327863109533023974705694691040780251179, -0.1214725752443344056214390721345345635097, 0.1354630812453335583691786956555251605069,
      0.901156038626981759680289890564868866422, 0.495975877882689411663414845909194968538, -0.7141377322117196572362406005424989117523, -0.6192178886041151965547330423426716073553, 0.5937394968026074412282023514646530173976, 0.1996270646464133840762094120897173592375,
      1.009914514775971335911721044289500186151, 0.5822153093205997559126940002229970656373, -0.9124901373447845003733264768629661393381, -1.049758765777338945717472289080139566007, 0.7774548277747912069741495695813261875138, 0.3218309179174278139589008185157146991126,
      1.044146292563998403460245035035945769182, 0.6995330944005384341495355953348446689063, -0.9825573078530813602889272246594575055344, -0.8518922461672841810102164999777334426328, 0.7134253914579441153167124599975532616064, 0.377344775597884588372650634271614190667
  };

  const double b[] = {
      1.044146292563998403460245035035945769182, 0.6995330944005384341495355953348446689063, -0.9825573078530813602889272246594575055344, -0.8518922461672841810102164999777334426328, 0.7134253914579441153167124599975532616064, 0.377344775597884588372650634271614190667
  };

  const double bt[] = {
      0.8826150461808577893934341141844647361342, 0.5369817275366970150186113014894336642312, -0.6589586680640259237702006670849926714906, 0.002173919507041442867056417679258366319843, 0.160258221036243773059168368830402291732, 0.07692975380318590343193046490148646264167
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK4_3_6L4SA;

  const double A_part_inv[] = {
      -86.00365703540347807223507453934299477843, -61.18721077830249845783830878078757047391, 111.3075996869283939453459807080929989125, 27.07446997369666765709144548668211633737, 10.77238349702740711800732959856720849673, -10.43083140726382984496522876244459308383,
      76.75090884339787789599341787110987805546, 58.98752630681690409940695231328719842179, -102.3565518884391504765181675444818531169, -22.56229184261475932604987243387743721335, -11.07989575508722709218963678089061790332, 9.231618210385478180751806849303318577222,
      -56.63884693987230199830288243813998726299, -37.09978761217741700532143139368724493413, 70.21668035431976961049193972424035199408, 16.30290894706435357180510397996446213353, 7.503213261019962188142617529154009199421, -6.444809609504320928017428631268111362061,
      0.6850431827683155329554601111349699175936, -0.8027813101637026179167700924242771791197, -0.3524135099508213744797604732704334762255, 2.304844713302296291051498450204589746497, -4.278471302840290937286577679901522890834, 2.595048515678963048220115901240443493518,
      43.64491326957738112669098469906095869138, 30.36590417018337207985930014187850057269, -57.08260597450153985076296139743612781335, -9.455981787934159125758548522855204402309, -7.512539801303100299333365528892524328372, 5.23117459065567082671813363233611481449,
      -132.7542440978325809308070073265551741376, -95.86905011697006101534949804197887515982, 171.7163101470427041191932991779006117776, 32.44121119107856526929397998583887953091, 14.81400293956689431265487541800706004586, -6.413907169311338997803003050172036622582
  };

  const double T[] = {
      -0.6055649360564090986087983605822882443084, 0.1452015127839118439944207123630308154922, 0.2506062414765122621714423744666764051019, -0.7149518996379185620415827292183698302606, 0.1687303420987918441419928526626448963165, -0.09888373727076139749855869434945724168608,
      -0.4177976188588510569244706865029312380767, -0.5196381623163920255485296401534467707838, 0.4285675574207979089194926815035664242864, 0.2575419974730480609493987080890745504151, -0.5454597315686572302587258280174172958801, 0.0888649505785561705260782268777693539802,
      0.6483743107271625101410111511025313598174, -0.3766656741210287745886012704407748830616, 0.4804947921730773365101129430701739945015, -0.4533571941489356458929110879578592970497, 0.02921808958896210704197493990976162341249, 0.02172637974340744732451356721573949426592,
      0.1516980836914127556062627321132459824797, 0.6332391368088657256926473193271734122759, 0.4692009839484490849579392850791806169832, 0.1432531326968050182208594220689822254988, -0.3573962502841449166332829580739330214782, -0.4556235111746401195226420331622266020696,
      0.1042788577381960788954389718439295267483, -0.0745115741207730912341179426048180201189, -0.5450252822014319326041330757619268816784, -0.4212556434714329643299938236287296311136, -0.6741003000241475416806908105185297050455, -0.2337816401322702528016086571629164962349,
      -0.06678789049759317197143044990411764717927, -0.40058943049494532137836862844660682181, -0.07381729862975912935251369162774508265676, 0.137859994455059121799932269860313849913, 0.3016732701503922939454127169832745053455, -0.8482961465710199334715559050757003467888
  };

  const double T_inv[] = {
      -0.6055649360564090986087983605822882443084, -0.4177976188588510569244706865029312380767, 0.6483743107271625101410111511025313598174, 0.1516980836914127556062627321132459824797, 0.1042788577381960788954389718439295267483, -0.06678789049759317197143044990411764717927,
      0.1452015127839118439944207123630308154922, -0.5196381623163920255485296401534467707838, -0.3766656741210287745886012704407748830616, 0.6332391368088657256926473193271734122759, -0.0745115741207730912341179426048180201189, -0.40058943049494532137836862844660682181,
      0.2506062414765122621714423744666764051019, 0.4285675574207979089194926815035664242864, 0.4804947921730773365101129430701739945015, 0.4692009839484490849579392850791806169832, -0.5450252822014319326041330757619268816784, -0.07381729862975912935251369162774508265676,
      -0.7149518996379185620415827292183698302606, 0.2575419974730480609493987080890745504151, -0.4533571941489356458929110879578592970497, 0.1432531326968050182208594220689822254988, -0.4212556434714329643299938236287296311136, 0.137859994455059121799932269860313849913,
      0.1687303420987918441419928526626448963165, -0.5454597315686572302587258280174172958801, 0.02921808958896210704197493990976162341249, -0.3573962502841449166332829580739330214782, -0.6741003000241475416806908105185297050455, 0.3016732701503922939454127169832745053455,
      -0.09888373727076139749855869434945724168608, 0.0888649505785561705260782268777693539802, 0.02172637974340744732451356721573949426592, -0.4556235111746401195226420331622266020696, -0.2337816401322702528016086571629164962349, -0.8482961465710199334715559050757003467888
  };

  const double gamma[] = {
      5.263157894736842105263157894736842105263
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -30.65042167927604869351424227884440297147,
      50.45610588345702106432031945895656139446, -2.106761381908861457855112595137432387361,
      -127.0097000833427576985434238305976122289, -0.01652156728847581775871993935224603441422, -11.18750644521823487861663341975698916146,
      232.2555040659001519152464269332994845637, -8.684784426024140461445106741742726936112, 14.43183578046160604687937882945589884974, -13.50712866841016986662625032109825188689,
      -209.7358831194142077254734612461255514332, 8.905936341228691442898672454022759256974, -15.73908826116729129231765671993083055748, 7.962396037911287117856190199608653843767, -11.56095124342709237260363769455665309454
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 6, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK5(4)6L[4]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 5
 */
void denseOutput_SIRK5_4_6L4SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((((9.694030046054966955938199296598417975881 * dt - 34.14974019607798644279572960326963106224) * dt + 45.73563136637744670125521872743810866619) * dt - 28.68950123160666371504377301824880586684) * dt + 8.229533349709954963372713963665137666426);
  tableau->b_dt[1] = ((((2.063467078636946509169324358603167892084 * dt - 9.027425277468191774111474403928289026426) * dt + 12.40071512182512508274597276743561405965) * dt - 6.803997418853100104731394837854166435583) * dt + 1.594844848479069615249501088572059144273);
  tableau->b_dt[2] = ((((-17.08643331270091673941628494348011458065 * dt + 58.30469927353598288708817192366495313051) * dt - 74.10162685359886575214825581648944940711) * dt + 42.37947909776872399794851280239937628041) * dt - 10.06861839911967781062626765960074896256);
  tableau->b_dt[3] = ((((18.95411260561905193064442109871995375773 * dt - 52.62698923148295725833582709919254495624) * dt + 52.21591618261767912219048150148164269922) * dt - 22.17899019385197051107488422315355464141) * dt + 4.119558020860306860385556144270605232727);
  tableau->b_dt[4] = ((((-19.94750232313291689918903611328760367321 * dt + 53.15938334649278791716938246143359740733) * dt - 50.43443107431801049634086266862412272432) * dt + 21.06762808259427550304691857232998325846) * dt - 3.941603062172673519260861045514707050151);
  tableau->b_dt[5] = ((((6.322325905522868242853376302846046860403 * dt - 15.65992791499963532901452327870821726068) * dt + 14.18379525709662534229744548875807493862) * dt - 5.7746183360512651701453792954729643628) * dt + 1.066285242243019890879357508607522201527);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK5_4_6L4SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 6;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1.0;

  const double c[] = {
      0.2133775566611387506909894969596462133776, 0.5694117647058823529411764705882352941176, 0.3115727002967359050445103857566765578635, 0.6544766708701134930643127364438839848676, 0.8345473465140478668054110301768990634755, 1.0
  };

  const double A[] = {
      0.8933048587540269751604040453432078152776, 0.3442067566069767901635762074264111438086, -0.9568084452151428752345044176725842369166, 0.1324389434266565392389680937829034208334, -0.2862459688262656554036706027668282686369, 0.0864814119148869767662161708479063682954,
      1.175425121128175902054183615479355324013, 1.02036294788080606931799127781115939504, -1.257849526993984893993053739411656547338, 0.02193808357175524667250583444004111045135, -0.5942324907794067476586809180699976188242, 0.203767629898536776548230400339842518866,
      0.984416595839063714853673876600031422748, 0.3643466891919020722034233166314983767696, -0.9848196966044081844301193483424096662883, 0.2091878174696793220555366104811805700313, -0.3778492799324855251926711126948438149328, 0.1162905743329845055546670430825231041111,
      0.8317571273998041782169634385473735907464, 0.3211321774443339591682668845296027503984, -0.6000577221248419912712884526535997063349, 0.3164949998152431720490971417802767668104, -0.2931837873056976263177978246766761961343, 0.07833387564127180121907154891599782865363,
      1.039689602926195081336734479490766652817, 0.9182524614210145759686738304035988026415, -1.012057237491781831322231831519437354669, 0.04631692762282831036559923442312433569245, -0.2792032636572810089676498426216792617931, 0.1215488556930727394242851600002176818847,
      0.8199533344577184627266293661831047366774, 0.2276043526198493283219289728282458425482, -0.5725001941147534171541236935061047186633, 0.4836073837621101438097474221259441393663, -0.09652503053653749457445879366308087596124, 0.1378601538116129768702767260301172551311
  };

  const double b[] = {
      0.8199533344577184627266293661831047366774, 0.2276043526198493283219289728282458425482, -0.5725001941147534171541236935061047186633, 0.4836073837621101438097474221259441393663, -0.09652503053653749457445879366308087596124, 0.1378601538116129768702767260301172551311
  };

  const double bt[] = {
      0.9571870101884205599442175766372731256346, 0.3236308716095026285950456263249976079752, -0.8196403889619955579032555211590764239465, 0.6597465864153680493069140311307890784738, -0.3384137190879105331951984886483381052955, 0.2174896398366148532522767757131878900041
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK5_4_6L4SA;

  const double A_part_inv[] = {
      -87.81963519695055471415996327090675207342, -28.59134166212671314357288241588180354405, 108.5566848506725165176935329636064052855, -23.92666880722979610255479421669674196007, 32.22424480951600389907914737851799400274, -9.037525391080674399213891773356209460038,
      35.73567872361668528604840413632855252636, 11.68016427495702941851702259100152781073, -46.71881357921599017920478241643030705194, 11.62959363607225600955406910801586079071, -11.6575970582354109999655885353615115383, 3.397811103176988872195915232011685457782,
      -64.64947623035133335623487798249544421979, -19.4271559102718636652995448329906453169, 77.01717967607294779054566756815420250289, -16.04807988786433361577123419910071546209, 22.45507682547424786169490166166867740802, -6.376383114975537401021559642297167536557,
      88.7363577168127351937154811744515368921, 27.84193408760349968787639594498704604742, -111.15559227605115283371026619347365563, 27.63818779594319885231654316942701301861, -32.13513162308002001792956222907666713818, 9.574915708611997333031849321221001291384,
      -15.9902718272329493239535515851298517807, -7.220829548924785534781098511123879988263, 20.80264723987401066470427372714091248611, -8.228017706756512981467605258855407437176, 8.573722174814932951197256895791651449948, 0.2719220009259607912784951512044726659713,
      -127.6253492540973639741817998701285547733, -32.63086828832349609664674837686879408813, 155.7954249359918262824817780389603424662, -46.24950928041627394142285725052629077074, 39.56795539574570956285841667132783095127, -4.480923072663641254938266086039608460403
  };

  const double T[] = {
      0.6590745563460989730898622437684073085207, -0.06402707714525128447681882304101278290502, 0.4342901739854011100230778042410414966392, 0.5883666488447320101875771463009123585427, -0.126853069271008953874606546724442988878, 0.1031808736777475633484292768708250521145,
      0.1759805083916430618574829022521486444801, 0.62550570244325360047920716637093779973, -0.3898337315458353403361640018580769088089, 0.2738660013822060978816081561710608551857, 0.5885113589862041834168773794454007265171, 0.06674527891448887393934822182197940519986,
      -0.6635243057702864850249119220666127815101, 0.3644513173894865110358109613815282146376, 0.5216971806464054634107682895332919051518, 0.392519285141320095240521094576005556091, -0.02587138390325227392959955912249462652775, -0.001437670962531281336101315748843106591964,
      0.1939428004971090011789443754236570152075, 0.09491556225588194470524822951083474029658, 0.6213791378882285468925368166243851762257, -0.5524932765736377852537042386691177046325, 0.5116303335757864932102955211287809018362, -0.01583585426573050656376580905854067870905,
      -0.228571331149699151206913740356165336785, -0.5720861528244712286140454567521501349391, -0.03145642734752937957664144869391183644231, 0.220838249087064433709097485204658559688, 0.4873227040531157566641694501414561927734, 0.577260879807387404113081500735846905456,
      0.06729355249401065716543012351486818732445, 0.3681397243499012064604172203095070020367, 0.01233768252885695196492229117742523555507, -0.2659555558497957379049110402975665712192, -0.3710044939554709051107316811830407074909, 0.8071033456228532196337977855914752833165
  };

  const double T_inv[] = {
      0.6590745563460989730898622437684073085207, 0.1759805083916430618574829022521486444801, -0.6635243057702864850249119220666127815101, 0.1939428004971090011789443754236570152075, -0.228571331149699151206913740356165336785, 0.06729355249401065716543012351486818732445,
      -0.06402707714525128447681882304101278290502, 0.62550570244325360047920716637093779973, 0.3644513173894865110358109613815282146376, 0.09491556225588194470524822951083474029658, -0.5720861528244712286140454567521501349391, 0.3681397243499012064604172203095070020367,
      0.4342901739854011100230778042410414966392, -0.3898337315458353403361640018580769088089, 0.5216971806464054634107682895332919051518, 0.6213791378882285468925368166243851762257, -0.03145642734752937957664144869391183644231, 0.01233768252885695196492229117742523555507,
      0.5883666488447320101875771463009123585427, 0.2738660013822060978816081561710608551857, 0.392519285141320095240521094576005556091, -0.5524932765736377852537042386691177046325, 0.220838249087064433709097485204658559688, -0.2659555558497957379049110402975665712192,
      -0.126853069271008953874606546724442988878, 0.5885113589862041834168773794454007265171, -0.02587138390325227392959955912249462652775, 0.5116303335757864932102955211287809018362, 0.4873227040531157566641694501414561927734, -0.3710044939554709051107316811830407074909,
      0.1031808736777475633484292768708250521145, 0.06674527891448887393934822182197940519986, -0.001437670962531281336101315748843106591964, -0.01583585426573050656376580905854067870905, 0.577260879807387404113081500735846905456, 0.8071033456228532196337977855914752833165
  };

  const double gamma[] = {
      5.434782608695652173913043478260869565217
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -37.40334751967026900578388318506592815769,
      -51.53733927211962786683103355691722361123, 1.930957171734861666882842786087053725015,
      -144.7529777981101247826752216996220888888, 0.2122127534844130302056024456896513468279, 14.60910321409754270434077882141404375896,
      199.0725298172891201695598650338682911512, -11.04503098974782735407297741791386878107, -14.01097145905763307686464707178417026425, -10.76810149119406992363718171037164840007,
      -200.9008363536960474799276690887898199975, 12.14088454309329329492581983711398013882, 8.86375610241310914818287173131370704905, 12.46247868259785602584889629484270049695, -9.597445156827823793768749894234144622963
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 6, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK5(4)7L[4]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 5
 */
void denseOutput_SIRK5_4_7L4SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((((-1.160562957437794117006810244973662062542 * dt + 0.9360089666499492498742676125893781210556) * dt + 3.187257476716450235507108278525854502729) * dt - 4.612508107169380736405006113676063027025) * dt + 2.026768276235539832730104157379457738514);
  tableau->b_dt[1] = ((((7.849975075670924450024819712196927707709 * dt - 21.47491669848849315154092259246217106614) * dt + 20.88462550145246387615061022110539955994) * dt - 9.518780311687397146868884319728605193273) * dt + 2.311291888705545046356467186122853358373);
  tableau->b_dt[2] = ((((-23.59292078576944183659974432555535746486 * dt + 73.52041783634772434525109142070225138584) * dt - 84.88019357919564067133133241781500771308) * dt + 44.54594835474672085475634016424619905342) * dt - 9.665337349730382647651397449340232416345);
  tableau->b_dt[3] = ((((34.23568356395460894361922240222724883571 * dt - 102.875023935060181410840473108051020292) * dt + 112.3168090450470553878369695919602016369) * dt - 54.24029515626662115655148104483982484466) * dt + 11.09446750992429027070586752144809247528);
  tableau->b_dt[4] = ((((-32.28695879111732834064487028070913202327 * dt + 95.49284232040263246495090344577249135541) * dt - 101.2742205512905612153582478483629662558) * dt + 46.45794526476449075182068203126666421407) * dt - 8.867857495739191524492271486969721263182);
  tableau->b_dt[5] = ((((-11.8328601283744700422430599884593927624 * dt + 30.91005135886049613105287040451514341703) * dt - 29.42800570671235935461453437942759224128) * dt + 13.31680445425231892888817312025168427884) * dt - 2.775681111270765989398300583059080511265);
  tableau->b_dt[6] = ((((26.78764402307350094285044272527362875041 * dt - 76.5093798487121276287477371830658119404) * dt + 79.19372781398259174180942655401437149133) * dt - 35.9491144986401314956398238375197935006) * dt + 6.876348281874965011749530654418891599391);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK5_4_7L4SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1.0;

  const double c[] = {
      0.1641791044776119402985074626865671641791, 0.2611111111111111111111111111111111111111, 0.4621848739495798319327731092436974789916, 0.6692913385826771653543307086614173228346, 0.9534883720930232558139534883720930232558, 0.8341968911917098445595854922279792746114, 1.0
  };

  const double A[] = {
      0.4816888333415901350467192975764918139521, -0.4041889688044248998058498920450451734236, 0.03269817359327239645018898352026900678274, 0.1338444522441201498643388758674667547492, -0.229053429575115448538382386405884210121, -0.02683051493310276563120156650157140853052, 0.1760205586112723729126941506773987461849,
      0.535326463933790808079012224095953531675, -0.366821879457317774948545764191085893649, 0.03960764448072061074389516499441941541562, 0.1314281506179369449876325065536383031993, -0.301360108651604899524070213558450768126, -0.0007484627098065705465807202967464062135823, 0.2236793028973919923197679135122410688146,
      0.5322908623627105515063326299256401183672, -0.2985759050411997484053203938296658527987, 0.2436969121131585515384691167594946064137, 0.02323022264684497091940471073397354130555, -0.1573696715814656837235418934930701677555, -0.002019040378554909360052951855200115866223, 0.1209314938280860994574818910038464773276,
      0.4128376281529494073006590035628995538717, -0.02096453385845067823060694817981345838232, -0.0224959785491504762915183948765511497063, 0.5229558044258251142951456613683389417837, -0.1992423447274191738438655744568383332326, -0.2161130468959548574880260983180827591217, 0.1923138100348778296125430595605285518032,
      0.4603260359307755687823132744488470583317, -0.1325325580338427977782590152681855507395, 0.1223217003736110907693071250612486324453, 0.4154514347287423135656335004465622172843, -0.3205132328430942466374070700564468198454, 0.1436812194072864334997998795897418456748, 0.2647537725295448936125657941523738439869,
      0.4056812151762143505492640926422295184213, -0.009801300196682259863089895403829977785332, -0.01619900839805546042754661206489534505437, 0.532725422803370095350489039739608741409, -0.4222291106300373536785757582324031692871, 0.03976779084103964868377984542401561912324, 0.3042518815958608239452647801210222307525,
      0.3769636549947644646996636898452606054956, 0.05219545565304307412209020723470852459271, -0.07208552360101995557504260776189183811902, 0.5316410275991520347701053627447174364677, -0.4782492529799578637238041390035564755903, 0.1903088667552196736851485738203611176755, 0.3992257715787985720218389131201494000887
  };

  const double b[] = {
      0.3769636549947644646996636898452606054956, 0.05219545565304307412209020723470852459271, -0.07208552360101995557504260776189183811902, 0.5316410275991520347701053627447174364677, -0.4782492529799578637238041390035564755903, 0.1903088667552196736851485738203611176755, 0.3992257715787985720218389131201494000887
  };

  const double bt[] = {
      0.7264082857156683914647084840682314985972, -0.8497028850272479006391109931574646842292, 1.287247126874550662037732634570764248633, -0.9948221182327760161595402831343875618334, -0.02618177701237273210668265332584671675382, 0.9565675227867380328932819793645963526943, -0.09951615510456043749038916838497478123081
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK5_4_7L4SA;

  const double A_part_inv[] = {
      -97.02525438076115942314408561888077172798, 117.9464021275283257276709387968200169964, -43.42354907009390485809364537978698460954, 13.47014645708864833982121328325920460826, 53.61168843505701540334424999401850018849, -24.11253061207568703751965993367144303337, -33.81686499063820092856194008162491087996,
      -43.86017411536169244587875912719528947125, 49.50149367282702177204904124423296653672, -15.90273159477471086681283656130389955405, 5.916288168959586421316521881621777414945, 19.86965843821120916743884537169988301991, -9.339171255319200654938979159019759847852, -12.48896498733830252196115488189227211155,
      84.88236999668430453977622184605529224842, -107.2204755626223650846772600776789132773, 43.37308624071985235899564074556438081735, -11.87197135421535326474158904392948054184, -47.79090214938885548550184998601650659771, 22.26784078550887570806073895017974444788, 29.95227515278602814523005035162642022564,
      -3.237252648150986092364534417387885586879, 4.469461647767238375678183419736440376362, -5.149064096054264831335163449674748037759, 1.102209286838267114469062598553396799337, 7.144628200227386598108738684960864574978, -0.2716177593423449242078703114806542862557, -4.579153666377763933115258616724082855424,
      7.089379331391156453111978411656684804492, -8.486933583143832017382879418269677204933, 2.087461818652094877178327211118124877507, 4.403268159738656252259598109122126561449, 0.6330596070648948156091551319609800592795, -12.75363966437592897013698839969714976768, 8.175673774816278343200864776013958991864,
      -65.04375984542337627230166178950074291188, 79.95660537566357002106735875328852814797, -32.77259309944226785011507342196101280874, 6.914548063812691957250054606930123827805, 41.66278015849309047549346162470668004112, -17.35824950186048564330369925803969355872, -23.92436080489957360984579135333993577889,
      156.4854820099931987364459198578939857559, -191.434970404789712018774759328728024219, 75.89294007758757907990142904095068130681, -15.12521604470821687489771915891385632215, -90.46562708764034388774833436105224493644, 21.36788963429731890841258266232563319342, 68.77365507517160900532488515360820535061
  };

  const double T[] = {
      0.6115874084567701345429147273675531056205, -0.1016234643076188430320293981094492992152, -0.2364155757822627844253191303418232943836, 0.7061837335149900172127803699444013722303, 0.1960572835538892160543538769518096772272, 0.1498777857314839727326862181083358525374, -0.01199642760649675729121827202669197423287,
      -0.623626236061739483397587063195337223734, -0.04333392906332007117449863255184493551112, 0.2981033296127661045641666855266549134244, 0.6915720384419711709304721508104054936788, -0.2030848451035615645467914485179674603844, -0.004973573055940622377894094680633162633235, 0.02840454306482730419920702989375683844729,
      0.3523734341165314940025971389107170968581, -0.4680955392152474407235636309272510971903, 0.2757481896765564289271850962936978682472, -0.05408363205256175279955068881030977817166, -0.7559637594171220333451115893236756444056, -0.07442444738692180661608029203435626688442, 0.02715182883153736204827012883698807171548,
      -0.1867394844864631007326618783740294882052, 0.1582546327318887368290003181542145773898, -0.6450754539569729376474820037534436564386, -0.01619228661101954928660467496070166125804, -0.4721841293178378913190261013247131637203, 0.5477956502955744159347949295847749342525, 0.02571727525887970177732051789773815648247,
      -0.1987609088495847179522198737008020384761, -0.7102827788151664630927521126936908160885, -0.1410738806229070231586404749323133798205, -0.09507810509897153342051616959882030555432, 0.3019805205744533111435514986295712174333, 0.2033239438879143020175192924059442994756, 0.5426950602356000340043422053783546199353,
      0.1607263379377169382600239675187181471635, 0.2603675730587238793818977517394516231346, 0.5808870666700311241904147550993238049504, -0.07326694381821582848004658955965442530377, 0.06927970421964317900789352391497553050934, 0.7102204150966354985644721028833359960102, 0.2331635187478256416671711390301197419782,
      0.112577230298447673864773158889055008016, 0.4139371697466300465817715772978075779221, -0.07583568404854953189793572066974239325223, 0.07373960697402281935364216010630142527625, -0.1728789099336301474757746508039905613752, -0.3551607747000106055821201286818764908887, 0.8054610559942256918240408892474075911309
  };

  const double T_inv[] = {
      0.6115874084567701345429147273675531056205, -0.623626236061739483397587063195337223734, 0.3523734341165314940025971389107170968581, -0.1867394844864631007326618783740294882052, -0.1987609088495847179522198737008020384761, 0.1607263379377169382600239675187181471635, 0.112577230298447673864773158889055008016,
      -0.1016234643076188430320293981094492992152, -0.04333392906332007117449863255184493551112, -0.4680955392152474407235636309272510971903, 0.1582546327318887368290003181542145773898, -0.7102827788151664630927521126936908160885, 0.2603675730587238793818977517394516231346, 0.4139371697466300465817715772978075779221,
      -0.2364155757822627844253191303418232943836, 0.2981033296127661045641666855266549134244, 0.2757481896765564289271850962936978682472, -0.6450754539569729376474820037534436564386, -0.1410738806229070231586404749323133798205, 0.5808870666700311241904147550993238049504, -0.07583568404854953189793572066974239325223,
      0.7061837335149900172127803699444013722303, 0.6915720384419711709304721508104054936788, -0.05408363205256175279955068881030977817166, -0.01619228661101954928660467496070166125804, -0.09507810509897153342051616959882030555432, -0.07326694381821582848004658955965442530377, 0.07373960697402281935364216010630142527625,
      0.1960572835538892160543538769518096772272, -0.2030848451035615645467914485179674603844, -0.7559637594171220333451115893236756444056, -0.4721841293178378913190261013247131637203, 0.3019805205744533111435514986295712174333, 0.06927970421964317900789352391497553050934, -0.1728789099336301474757746508039905613752,
      0.1498777857314839727326862181083358525374, -0.004973573055940622377894094680633162633235, -0.07442444738692180661608029203435626688442, 0.5477956502955744159347949295847749342525, 0.2033239438879143020175192924059442994756, 0.7102204150966354985644721028833359960102, -0.3551607747000106055821201286818764908887,
      -0.01199642760649675729121827202669197423287, 0.02840454306482730419920702989375683844729, 0.02715182883153736204827012883698807171548, 0.02571727525887970177732051789773815648247, 0.5426950602356000340043422053783546199353, 0.2331635187478256416671711390301197419782, 0.8054610559942256918240408892474075911309
  };

  const double gamma[] = {
      7.0
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      24.57715576511614716982721293043938867005,
      -22.96702646632931632224102415596969286128, -4.02184736433540919636893064279337865395,
      -148.8589589586224283364348509538031706614, -25.17640984111261040220662630055568392043, 17.84695967638969198942743335971259703111,
      -182.8773529540897831848653250085957649203, -32.59013975359512620439406719675201085798, 17.30355998795059043995535146946243276531, 12.85643983612046442380255390710943609772,
      -219.2749592250793151409089453154159977442, -45.21455160646947895196938506536249805551, 24.03580819489232808383419207229938580576, 11.86346270845133215080919973926227849958, 15.40631235053245603240287402769376220708,
      201.8638281211549873082432642715363713179, 36.90217014087979104950071306300507447303, -40.56902721039718774084993065636941379745, -9.579948469388209043284869746128921362678, -14.54931410819574876804170022757038709341, -18.2324149064266062446738575636358954891
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 7, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK6(5)7L[4]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 6
 */
void denseOutput_SIRK6_5_7L4SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (((((-40.30579001336730269954549383353289334033 * dt + 176.0428287608220818289290534925173637011) * dt - 300.9011087924169721848032920784420929048) * dt + 256.0988348260049074495513213655839159422) * dt - 113.5175393488225939025712529231438399211) * dt + 23.9636056653917612483294056048062479199);
  tableau->b_dt[1] = (((((85.75566647035136364150143074025281558807 * dt - 376.7119987126959979612043829379295427107) * dt + 640.3752746233957901112114741159221717331) * dt - 534.7691200314000177789843655303718736506) * dt + 227.9932978538122520091172211485354845207) * dt - 44.15433936563580316911391192933042281656);
  tableau->b_dt[2] = (((((-75.59628656834448051499612282380617161219 * dt + 381.2626509602027277256478626668870019627) * dt - 702.3175442443439157489759567581487873298) * dt + 614.2286570362826117388794421963591374615) * dt - 268.6521277609319684412563574490705848544) * dt + 51.15292599944500912351563896877411845703);
  tableau->b_dt[3] = (((((42.87910011209810627724113673050807423535 * dt - 117.5265512458747830517749322516167056531) * dt + 105.0397624737185463185287018989310717715) * dt - 24.16816142434298053262326130412853899507) * dt - 10.59840823110671649721815228639070736435) * dt + 3.900406397153466913619121770143907193565);
  tableau->b_dt[4] = (((((4.541082126636578581414563636030066842643 * dt - 113.5104341994927359080632202570732017662) * dt + 310.359959492447623143356376321572316611) * dt - 334.6463127900773032272325047599893189041) * dt + 168.3876131657027848331841526329603164766) * dt - 33.97044769331994450626757682146269219604);
  tableau->b_dt[5] = (((((-43.49731816981819803363388040039616472261 * dt + 124.4122163208198480155578201722397888029) * dt - 129.293272671674871768284880814760871165) * dt + 58.73388883855655120376981591787681574719) * dt - 10.36487058832994607318047983455210902426) * dt + 0.6239927624996737322052167135572805807984);
  tableau->b_dt[6] = (((((26.22354604244393274801836595094451677887 * dt - 73.96871188378114064909220088502446056695) * dt + 76.73692911887380012896757731492643505375) * dt - 35.4777864550237688533604478853298938313) * dt + 6.75203490967618807192486871166168393656) * dt - 0.5161437655341633422878943064881953688966);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK6_5_7L4SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 6;
  tableau->order_bt = 5;
  tableau->fac = 1.0;

  const double c[] = {
      0.2131258457374830852503382949932341001353, 0.2841918294849023090586145648312611012433, 0.4342168674698795180722891566265060240964, 0.6827133479212253829321663019693654266958, 0.515222482435597189695550351288056206089, 0.9378283712784588441330998248686514886165, 1.0
  };

  const double A[] = {
      0.9640596196465586659983442797626470398726, -0.8479830638173285175908116047672970611125, -0.2800745630137189874824359040068347226145, 0.1140869443020604882377662215768564835553, 0.3741804581941751915940163590658702906597, -0.326787872767622737087311562560390440862, 0.2156443231933589815807705059194021290491,
      1.167160054550300730807691124264458385335, -1.139671288767012270936725057263214209424, -0.1447640313348675064533704337466778903871, -0.1277383055284631267288161667029591281824, 0.5621260676455510037973117188607225637814, -0.1428964060442573258293821735209208540927, 0.1099757389636508044019055529391426816804,
      1.018127079714277142573317066568381408867, -0.8499756953103503245808222659055503842151, 0.3051217469917456179138785144076278163049, 0.3855327272180582620532580057231112226728, -0.2402533097718078448687523783358486927632, -0.5028231930582499851874874491892511012299, 0.3184875116862066501688976633577686367754,
      0.688142124634020552111748725963488786128, -0.09694640701211328973361054617050156600375, -0.707645883302279753581215816066402165408, 0.5316469766774499834178588916581250081144, 0.5187446892674765731452485472181321335111, -0.6788913240308198605846860427424164692522, 0.4276631716874911781568225421089426081308,
      1.229816427504031643051580220130484951659, -1.209438154420969194064596782706692996792, 0.003519516103430771016905340798302759304202, -0.3663089236697867528261882323247507414298, 0.8043773891889912010669143073504209519386, 0.07720411968284073193485273753794297629968, -0.0239478919529412104839172394966609525692,
      1.085475509362731096687415099599292429031, -0.8484671411812395303446839354348309011103, -0.6466096630344564561738000707496796620253, -0.1754569156117620374462334941695085882617, 1.360468108627199738694580314123765507514, 0.2132975896074186983694601633945935750743, -0.05087911649143266565363825189637357253616,
      1.380831097611881739889741627788907985959, -1.511219162172413147472534392921176725018, 0.07827542230998388281450680099485634625259, -0.4738519183543605722273854425529437675835, 1.161460101897002916391790752037588546955, 0.6146364920530570764336117539641537124365, -0.2501320333451518958297310993107298883048
  };

  const double b[] = {
      1.380831097611881739889741627788907985959, -1.511219162172413147472534392921176725018, 0.07827542230998388281450680099485634625259, -0.4738519183543605722273854425529437675835, 1.161460101897002916391790752037588546955, 0.6146364920530570764336117539641537124365, -0.2501320333451518958297310993107298883048
  };

  const double bt[] = {
      0.9915072149046932327366310931077749718825, -0.8175648709086375061724735804989188987865, 0.3596076532193498028680288410488735665471, 0.5886268619684020250250648081778748526865, -0.1500912256613756812904629298452719336487, -0.2, 0.227914366477568126833211768008468679185
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK6_5_7L4SA;

  const double A_part_inv[] = {
      -108.4312037574161152687086525385226312475, 123.7653835939044964953262909207152108318, 15.44712216382926326750112479054947281742, 2.412446949294348247792974836761461466635, -48.07941737779969263473872277684121229527, 21.81607237918881168138809698015889802233, -15.10616436777781743956880294924948761276,
      -88.02571330466173285347125309273258865812, 99.14620720225610036363809489499118722415, 10.96962819313050863048887313744579486772, 4.165926489435404326043585735909083110547, -37.83595757965564125351064478557495229719, 15.05312513529822821303850437278492468056, -10.64663046749311506129306941324210885811,
      43.38524998239663997999219941308801931678, -54.55442103356361348407551009765752012165, -5.328444071673849290780520807970467140242, 0.2022074637754340496127346520858434107619, 23.2089837258830205081514924697239010724, -9.91424828697787069789115381831165071279, 6.773126297079435486397848293254822239003,
      79.8928003717801932878651797358997180565, -96.63572642701890283035327548319405382113, -4.125156957034689896417390623080723949959, -7.918282009395023511573469687466238480932, 35.78973089589626108011099970566057586247, -5.417644413504281774551527744692609976143, 5.274139430046035414856733780636893636716,
      77.43740442638252564270816481410544171167, -93.28389079443705325234248466094935968571, -9.725592150134926244271445862261204125204, -1.557550622315837949356302528771658220704, 38.07613979938787574614353512509285886257, -14.13244533129833564402763391476248810546, 9.92910895211979778196840282500199461359,
      -140.2361995119883185791222488690464660706, 171.6170440540117147146898600467726923627, 6.613392604574170608953125189948160698825, 17.80674566416807523344223167329425403829, -72.346362870695252035430688101807427039, 5.467120181091555164944734979618398524166, -0.7655004061609174659145081686330952952058,
      -189.5567744818746393629361754532815420887, 238.7730037011933816222788299156482079659, -3.762305664635908371681546798923349123315, 39.73548480461037356952664715005278872659, -98.33313767991774456665693201496674000747, -15.54027499866849201626128551974395727357, 13.28537593355445434655675819005356883077
  };

  const double T[] = {
      0.6751423246270945437304431151129789807045, -0.008607263493186870239737578939881892802442, 0.12821814901387832972541060972022733523, -0.5801959281099963099456663821522641475907, 0.4118332553691910685092186043278275925229, -0.1176500267839259266368004048216569942288, -0.08714005250212323680801846167959412452882,
      -0.6353184150034129648592936123262456081292, -0.2821532024324294308585601025586616556809, 0.5153508056611216551578816880315533284155, -0.3757584331682598782586285022828813462851, 0.3233195996535768192999297526237520869224, -0.07344080899237867801989828180137806679715, -0.007079051944899757534450354128621003711792,
      -0.1070800878675768776163949209399402163822, 0.2910271958804007560377186417054909716979, -0.01796621967732062454850558634493179098405, -0.6208635799547695501759133963295960199661, -0.6701951457147431517275577429939661337172, -0.1144806924350602753905753434424553259155, 0.2361679355808064108185564444265682410772,
      0.03800787971695385998483412963364072137781, -0.5155718924229213965600280079182631794569, -0.2011898114864686283564774662819905348733, -0.2491161208924772599183584135617770434472, -0.1743466758547394091774319730731481064843, 0.7610661030236884141840563831118241770069, -0.1434798464423903821063823036996960961381,
      0.2704750514615998617231922772911609090815, 0.1789460925046128320940136096858717586708, 0.795967197762888363574871888293290883077, 0.2358552247064236104243341686266027800229, -0.2195577138214091655016861243008073540005, 0.3713694227100724599048884996761309986314, 0.1396754729931370494573902483589671267767,
      -0.1907663792742479068126745202991209408981, 0.6126767204659540697665653188636157577793, -0.01722123332569457296970701972238905152496, -0.1106735657774734939183898878488044269618, 0.1061302841916863030769091126008369955302, 0.2764074595820078500205684849102294698489, -0.6985882154483646941059507187359061871283,
      0.1345141033193408765677038822064299258503, -0.4030010081254580333439235023269445318557, 0.2081181810430557677931144476460542933182, 0.08228932568400457363484689042474809950181, -0.4322386870810735050078882733339525061319, -0.4172782582685327296114836047838463286754, -0.6391087588373902116593196736694761371179
  };

  const double T_inv[] = {
      0.6751423246270945437304431151129789807045, -0.6353184150034129648592936123262456081292, -0.1070800878675768776163949209399402163822, 0.03800787971695385998483412963364072137781, 0.2704750514615998617231922772911609090815, -0.1907663792742479068126745202991209408981, 0.1345141033193408765677038822064299258503,
      -0.008607263493186870239737578939881892802442, -0.2821532024324294308585601025586616556809, 0.2910271958804007560377186417054909716979, -0.5155718924229213965600280079182631794569, 0.1789460925046128320940136096858717586708, 0.6126767204659540697665653188636157577793, -0.4030010081254580333439235023269445318557,
      0.12821814901387832972541060972022733523, 0.5153508056611216551578816880315533284155, -0.01796621967732062454850558634493179098405, -0.2011898114864686283564774662819905348733, 0.795967197762888363574871888293290883077, -0.01722123332569457296970701972238905152496, 0.2081181810430557677931144476460542933182,
      -0.5801959281099963099456663821522641475907, -0.3757584331682598782586285022828813462851, -0.6208635799547695501759133963295960199661, -0.2491161208924772599183584135617770434472, 0.2358552247064236104243341686266027800229, -0.1106735657774734939183898878488044269618, 0.08228932568400457363484689042474809950181,
      0.4118332553691910685092186043278275925229, 0.3233195996535768192999297526237520869224, -0.6701951457147431517275577429939661337172, -0.1743466758547394091774319730731481064843, -0.2195577138214091655016861243008073540005, 0.1061302841916863030769091126008369955302, -0.4322386870810735050078882733339525061319,
      -0.1176500267839259266368004048216569942288, -0.07344080899237867801989828180137806679715, -0.1144806924350602753905753434424553259155, 0.7610661030236884141840563831118241770069, 0.3713694227100724599048884996761309986314, 0.2764074595820078500205684849102294698489, -0.4172782582685327296114836047838463286754,
      -0.08714005250212323680801846167959412452882, -0.007079051944899757534450354128621003711792, 0.2361679355808064108185564444265682410772, -0.1434798464423903821063823036996960961381, 0.1396754729931370494573902483589671267767, -0.6985882154483646941059507187359061871283, -0.6391087588373902116593196736694761371179
  };

  const double gamma[] = {
      4.899559039686428221460068593826555609995
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      2.336170156644418886192120248616048076536,
      -77.6003569520725042369291773692327680653, -28.51999482352344781896232819828035215194,
      104.7788475050696353628165094167589221323, 7.242445902717446691899485114531753051243, -3.905799927409254361460124746324837984247,
      -109.3199082598175445808359289662336138493, 15.49334634385467617688997952215971395828, 3.403367430628603441073226738548740477395, -9.328778860635097610063410348222700448468,
      228.6789126687213735136282578625011394995, 64.88650296995962523681956332362528809837, -13.19432388806271948421622697816713289155, 7.348908371808930862878381929132733120526, -7.644623255075582190623751701171371290032,
      381.1962430981094924170220085908749534545, 123.1485531566260817728886747065363061102, -16.9769862614172732681190866549994395952, 14.16334084135339002863887759572974230231, -12.28872736686734522750418415546877139091, 13.88631979269439730551187508055435114071
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 7, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK6(5)8L[4]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 6
 */
void denseOutput_SIRK6_5_8L4SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = (((((-24.78660583051819566775434270600553941644 * dt + 129.5891809634219545194516450973019624733) * dt - 245.2778867241127725870564610689332378596) * dt + 218.9658655211593007976929383833543008894) * dt - 96.03777904228268743922551554483614158577) * dt + 17.68696105803621430678135826799785780155);
  tableau->b_dt[1] = (((((42.1708317877349724730362113112862458341 * dt - 229.0098538616774610911585594345473634404) * dt + 438.7900550865341394435267111804289364759) * dt - 390.1156926188405510680103341285098775111) * dt + 167.1645430815182207309742067301988536367) * dt - 28.42375158849348450670488931798760414316);
  tableau->b_dt[2] = (((((-18.43650934274687017943142211241146612316 * dt + 135.5407589935166495649191440430391076027) * dt - 291.5771808114086165075350501188772080271) * dt + 273.9831347031886353897123056307420066834) * dt - 120.9232531598116747852268619434674895441) * dt + 20.51297337310001625445236586515785088841);
  tableau->b_dt[3] = (((((-16.54685645589223568236318180440513809515 * dt - 6.774881534228980283212651910513255970558) * dt + 110.9982647591548618411334302567155499442) * dt - 155.5423788419869092884165807042833530334) * dt + 84.98122903123815099143858721245802377819) * dt - 15.55313707061621809020608020233882538535);
  tableau->b_dt[4] = (((((52.47370577779284294124494514093972733104 * dt - 106.8843960888599712650267755726319121692) * dt + 21.54647864216989250402566565848725189513) * dt + 84.84392589191092033263447622399029105369) * dt - 66.44576085633933133812149809167844595236) * dt + 13.12069214127510261198714414293138834335);
  tableau->b_dt[5] = (((((-60.52891988007794126000820871460935139251 * dt + 133.0233476224019237511659714733791665427) * dt - 59.87171263522731588444186376629377414486) * dt - 51.51649528439090462679811790067307199662) * dt + 50.44119683096631776589783091167383971272) * dt - 9.880177555767226061424860251324574637564);
  tableau->b_dt[6] = (((((-3.290614290422221156168439898626787114908 * dt + 20.75598278510579006050235869642698764144) * dt - 39.99689406690794493498543168413549389486) * dt + 33.25259380428563914092508830452995088885) * dt - 12.10278701983784058314220475676945840608) * dt + 0.3746741595339930580817901386948579295549);
  tableau->b_dt[7] = (((((28.94496823412964853144443878383230897428 * dt - 76.24013887967990525664113239245469268273) * dt + 65.3888757497977561253329995426079756084) * dt - 13.87095317532613067773977580915024697695) * dt - 7.07738886545115534259454451757918164204) * dt + 3.161765482931602427033171356869049200444);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK6_5_8L4SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 8;
  tableau->order_b = 6;
  tableau->order_bt = 5;
  tableau->fac = 1.0;

  const double c[] = {
      0.1517857142857142857142857142857142857143, 0.2114014251781472684085510688836104513064, 0.3639705882352941176470588235294117647059, 0.566197183098591549295774647887323943662, 0.7783132530120481927710843373493975903614, 0.9188712522045855379188712522045855379189, 0.985, 1.0
  };

  const double A[] = {
      0.8127565233186455603845262038154309486271, -0.9651737333547232187204834264354478460631, 0.4322810121028860643302506457475385441874, -0.1688292586983520338150895040121441205887, 0.04473032925027046871113745312630533266619, 0.01587654777966347243944752194552378817024, -0.05998640148178157229303866220691681633702, 0.0401306953691055446775354823054244519356,
      0.7757777654611756667706511269956862369901, -0.7978353000379587080212599692832302422427, 0.2883499514452990740228243601877513087414, -0.02161432985650131260490927330259750657788, -0.1290861323469938576700885945711082004244, 0.2645837526128286670766566410682392577789, -0.4446143569921815801527298764861641968465, 0.2758400748924793189874066542750338063429,
      0.4475903120149544981684949570736454548627, -0.0702207309306056551825695335574298033546, -0.2668594554762832005012745117740314324977, 0.567942571822836769275653086340013257288, -0.7132359584898113624065865506584418211023, 0.8414751740593346043299736510024913927211, -0.889381832194831504694685542153378760434, 0.4466605074296999686580532672565434927268,
      0.1779129195527025915818210291511662628706, 0.475142778629038038430202597130805803361, -0.7269551736314781589633995079768566108884, 1.212294925398696809771636504274687380946, -1.187802504873458662787974353622450232721, 1.071567963171461191068398653622801651934, -0.4563077177757434359584852465487873489623, 0.0003439926273731761535749718559570366292085,
      0.3172297586148407013739691117024914615814, 0.191708701063004894644318170951117436894, -0.4525501723760357473919696747338456754706, 1.063540680695951204129282527132315430976, -0.837615366736923165570617443422941729094, 0.9931327911367267650515512321385114193431, -0.8831763700229513852623378104526904795542, 0.3860432306374349257968882240344397402998,
      0.402909525492485432734313947577510759253, 0.01482856544070362377296385692624296926068, -0.2720013787745881357347918242152772278292, 0.8975986750930780281551582825236858860618, -0.6454572746904295090736993578177529181608, 1.089279820132167001213405490408869686785, -1.226725255144913667502442696274761418924, 0.6584385746560827643539635530760678202815,
      0.7338231504949082518617531576948235362643, -0.6687621664146275235798939285380361544933, 0.4354214348176919712676377173718778355849, 0.2096290559568125595193887670312746756518, 0.07825630518379712805444724453608821516038, 0.285884574262298980013166087173042412013, -0.239149693000160104111573238143997102142, 0.1498973386992787369750741928749265781721,
      0.1397359457038139298896224288792022988891, 0.5761318867758359816633463408691908480174, -0.9000762441618602631095186358171985247393, 1.562239887668669488373522847633001233088, -1.345354492050544213256042497961699498173, 1.667239097904853684390751752152234093392, -1.007044628242584414786839199879942939425, 0.3071285464018158068351569641252124998432
  };

  const double b[] = {
      0.1397359457038139298896224288792022988891, 0.5761318867758359816633463408691908480174, -0.9000762441618602631095186358171985247393, 1.562239887668669488373522847633001233088, -1.345354492050544213256042497961699498173, 1.667239097904853684390751752152234093392, -1.007044628242584414786839199879942939425, 0.3071285464018158068351569641252124998432
  };

  const double bt[] = {
      0.2890395308019656346660491119315910642148, 0.1995732391842089019497416890156561366589, -0.3284919489499406556216094388577725811699, 0.7906776944782210691129742470719911613377, -0.4548698553426108599536814388074863798869, 1.258225311406222613535737353785066871832, -2.523861776427936169442963886950218802976, 1.769707804849869465753752362811172548134
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK6_5_8L4SA;

  const double A_part_inv[] = {
      -193.4103237898061144097618352124018205711, 276.9125402585880363731875135619004791708, -149.7243364338062784177955424737556244089, 85.79977283391990992797869277992990873718, -55.74910661465872268999868369901550448343, 35.34574460680391020978755802043423905111, 0.258360522228329898706610901492373266444, -11.60952159739432091194404188421939173612,
      -95.31193731141601304604792064745905874005, 133.116551108095600359743164399870763665, -72.07395689388213172962072208742485885392, 46.35932298264177100085325500478104656553, -33.04856096296422348807546935372785963672, 21.94228158572117675113774319174989545809, 1.421939211036567530586033707995157859837, -8.53036461961722463125427002631059608315,
      191.726008527193522630315084305753921444, -279.5701952874536285237676320889266313607, 151.7395381100420145782547334783402700828, -76.69258361526301590054014037637664205237, 45.88345015773079147020035956530298045301, -27.69443505596457493826070206799120721995, 3.58960663431766004595210581903487943623, 5.394824765193142774251793975070273954353,
      47.6119017944405559552900675566438204305, -68.79077053168683754828644502161031574489, 36.53074205635205483545059196064886734865, -23.92629069329493552086559618617826861097, 20.60735740482403732409771754194128329406, -12.65685151551928925149589544570536617216, 0.9339276533472698798940904769849157527279, 3.237662009505574632098099146654913983609,
      -189.4021611894445151865244550314964169676, 276.3731006455043261280844677402282234385, -157.6188593332778171949397586031726069856, 87.40216156395035595162052224828691794902, -60.56034519847353095471838541890819182703, 43.9049305301183570815953905049723479991, -3.33614644112519138041986648911854520147, -10.71730873439316559450372509474474593779,
      11.89982224227291049822295425189864762372, -20.58576617871713288627367670107264730412, 16.79610006625121198934852625406256803677, -13.28471687451484316723648191798951922208, 7.208407451998462928629763128495301136704, -11.52736109994304234440854859599175938343, 3.544941999378996604832367934560216021701, 6.444113947218360892930284507830926136752,
      167.547934805806571810556937946624044217, -258.8329776037805548748831463743804454035, 171.8073552706147141317176793464942577471, -120.690182549945625951192414114224918552, 100.1785971574542463342950775837057476628, -94.3309887050508078182582323735214849542, 15.36757947453851295192164452826722205108, 29.65853270826972446875734655225678284637,
      241.5952071511847663126729353625644869959, -371.4057372478051379672356618834006186705, 243.9195823453108955140553919681985132263, -169.8105699551804389120248137950045506415, 141.0695916646196388328418498650328476152, -128.4274523481562185199979578542915532336, 19.51575905271101747150724783827524470895, 39.20065208884149533983482300700170553428
  };

  const double T[] = {
      -19331.71048774575441107044608283163013136, -4212.163044696997060799547687327915393977, 562.9504438311203847036661068851982683838, -114.7139837281890497848065274152393076152, 17.55079937653928090308560817828066488195, -1.853155678125729332438023028431063463545, 0.1607249066951625858854615272731296759777, -0.02456196695726121914481714457516126612127,
      36736.05886650963391286562037675747768311, 1496.309985051233153554419329043256262857, 751.5121508988282240824179244820861425899, -99.70220742141801565086128750543736930304, 4.47151777817601689460902216899443007844, 0.9369657070648346399194684976921732052386, 0.1604546905773642495337984059458008678519, 0.04224082785087934458747611382395362923631,
      66295.68605402811533751926234616395082577, 8334.460732965125919206911070694802801565, 334.6100043775589354406689536873951467136, 42.46579527534884379896389603683847435393, -26.11330140305831843274664670036055326799, 5.688784948263964225005674010244253628416, 0.02203538472115733422162529158306475685629, 0.1109126473042331496484648770153613675089,
      -84947.32879231933113949917982173931978954, -6853.80898076755981247431125402816464721, -626.4260417048024980792515719969734307461, 114.0354781742812086318521058947874431371, -8.363442273273174983033448152584407765157, 0.6862629160213060360897154906121481623157, 0.3463385382792640054232030556785419900544, -0.03991232821762228869757703587116154991973,
      -33507.78586563259441063676872001412899542, -4476.604672430762134346331390706732021822, -124.1313643164131965093795043201908614408, -50.41032763855827039423746876067671239481, 19.02890422536152273372352904815341162567, -3.087874235530706503849248093011896569375, 1.472994393611303090464068213040897510033, 0.07103077846199869779134606421330002362641,
      59307.03957703617858878564255844766279973, 5627.861675639374364717380555112496006221, 500.7402595602977556654797637963411232766, -94.49569310055914207485829471425777910599, 8.013551442393466109987282576645404767022, -0.06169923997613848951032111363755875920789, 1.451100655130611770230215438949667045513, 0.3716198971960323353811177300046560109558,
      -29289.53537145255567105917766557686090829, -2927.067007757309681117929492055298201713, 273.595184839249970990965296875940713702, -25.59044613491473534610233744436580055643, 1.594834495618968739359222162721653228711, -0.09195540453549119277484814142097394405123, 0.6546369682585750966149462949255707483078, 0.4538420407624452466978209078740969795191,
      -8380.0, -1694.0, 168.6, -17.03, -0.005, 1.62, 0.615, 0.505
  };

  const double T_inv[] = {
      -0.0001178651858499780618069176951553448977192, 0.0001402571823125088807693695248622688617664, -0.00007312626216671271847018076765799593722215, 0.00003004863274316859629839342603674604785483, -0.00001387298488534073771944982952865986006864, 6.711064577344435825547674473233579472588E-6, -4.123115937115384801749466721872954720664E-6, 1.689198143818141161362863911095853767966E-6,
      0.0008003525521830344868504113856059286279467, -0.0008550989750626191979394868205890762432681, 0.0001570975747280877653401406471529749308449, 0.0001838600338096908519307496867451473302865, -0.0004451109019961086181022818154864872021777, 0.0005233337310348927665794766023335796874416, -0.0001926727241198968834093011676271623523827, -0.00005886965442089450286775904987633980969614,
      -0.01019115916852929931770936933088818526999, 0.02072768365560555204343348856536921930646, -0.02049165501320627780783145756714031845321, 0.02117611994705307916678299009367887880822, -0.02269358376541412748724835083618648704553, 0.02105871653146457369675450889559000366093, -0.005492056105617076842114906035830867232068, -0.003424290450561276995479895743538572355062,
      -0.1145748616957174550562156772086054793917, 0.2123622618101866627777376346974383796894, -0.217477411856722476769456851532763209338, 0.2184408608168598424498286523204033545971, -0.2322316114942956162760868730916661061352, 0.2174576765094499786876254229001499122298, -0.07175539057098258333227301389293100609971, -0.0211791232630701326946711480636609378467,
      -0.2340549512645128795626086618627237527927, 0.6366036043298251746934616177595284280896, -0.8224897447417469813706054939244571168794, 0.8808396696041587028721618484868557023638, -0.9845845877233654409204059020068610481909, 0.9445493648932877115987333443620411215611, -0.4284847409533301864232085258352558372273, 0.0141152967339169080977064110489806608753,
      0.5995521141515097191109445011819928394132, -0.2570626788020473618290596548172020181563, -0.133583300523073324133887008600380730846, 0.5617784884531080233516163985259801142017, -0.6260174899722314711602562101641618997024, 0.6269918313336165447653150585202897653234, -0.798026858900597378426691904252740116178, 0.4682469157619690162684989923872212434816,
      -0.7100019079748686897266375850049226106313, 0.8688063628153256467213478402397377141629, 0.02789715049050787183594422669498277454529, 0.3394276468916493411403843545916858042785, 0.5912579574109560196527712600081641244589, 0.06796209457917011952966414318095356668162, 0.2168291896699114774295851454733273964763, -0.4145440081170765997502919110307377462218,
      -0.7934396419128875188803717471409981200363, -0.5267959943273844130243035283380505459407, -0.7926461851268703728048411592758939658672, -0.7948603554159117615136582884892402781976, -0.6998769014077933227670965516900462166002, 0.08469302411896780813586822276155316368449, 0.9907686887886714055403504945523300684695, 1.242654108103028839116529563549936265373
  };

  const double gamma[] = {
      6.25
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -39.0625,
      244.140625, -39.0625,
      -1525.87890625, 244.140625, -39.0625,
      9536.7431640625, -1525.87890625, 244.140625, -39.0625,
      -59604.644775390625, 9536.7431640625, -1525.87890625, 244.140625, -39.0625,
      372529.02984619140625, -59604.644775390625, 9536.7431640625, -1525.87890625, 244.140625, -39.0625,
      -2328306.4365386962890625, 372529.02984619140625, -59604.644775390625, 9536.7431640625, -1525.87890625, 244.140625, -39.0625
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 8, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK5(4)7L[5]SA taken from https://ntrs.nasa.gov/citations/20250008379 + https://ntrs.nasa.gov/api/citations/20250008379/downloads/SIRKs
 * Dense output has order 5
 */
void denseOutput_SIRK5_4_7L5SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((((-20.9939076594860711013905331556390232275 * dt + 73.69630411956539060551430313782880054895) * dt - 116.3855093776941001686228426714769700421) * dt + 48.06647271960503706177898142438613103091) * dt + 2.835774814121148725978572310093667031361);
  tableau->b_dt[1] = ((((15.52123439967019928828030729791792521099 * dt - 58.13982840377480662059750495080975713115) * dt + 92.55353297558898526741723345796584885723) * dt - 54.1799251082490730771916999101291863717) * dt + 11.82186169919887640483015468759325451524);
  tableau->b_dt[2] = ((((-31.1772184045523460077205180509780857224 * dt + 128.0710334887859185688482163075977322819) * dt - 168.4045995666049897766555989913675033191) * dt + 160.2521821538385587596519646665620261113) * dt - 79.14184112421836060395699439100245895307);
  tableau->b_dt[3] = ((((49.25181885561472199224433531899522522207 * dt - 181.7486969128052905435029998725061447568) * dt + 233.0267101526289354411954706842402665931) * dt - 205.4900436914218214099657595754553982083) * dt + 93.23359816432210579914568559942237835694);
  tableau->b_dt[4] = ((((11.05755252440358941979025682299902681264 * dt - 43.54331240282940315791741749057370716465) * dt + 60.3920627958826396178025737461358129428) * dt - 22.45321736186237042055195590356433095601) * dt + 0.8236391644534505301327912216186506230117);
  tableau->b_dt[5] = ((((-59.27145744865942191383150991793026965251 * dt + 196.3830395106056649269061883296075088197) * dt - 237.850567051764756614688907655710033218) * dt + 166.9505668616898969234677735030438656475) * dt - 62.5428536946158417768750196563600227371);
  tableau->b_dt[6] = ((((35.61197773300932832262766168462590533424 * dt - 114.7185393995474737792507854611537286204) * dt + 136.6683700719632862335520714302032821636) * dt - 93.14603557360022783718930420485240327616) * dt + 33.96982097673862092074481022862523514114);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK5_4_7L5SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 7;
  tableau->order_b = 5;
  tableau->order_bt = 4;
  tableau->fac = 1.0;

  const double c[] = {
      0.4371727748691099476439790575916230366492, 0.3643835616438356164383561643835616438356, 0.6098484848484848484848484848484848484848, 0.7158774373259052924791086350974930362117, 0.6449704142011834319526627218934911242604, 0.9358024691358024691358024691358024691358, 1.0
  };

  const double A[] = {
      -14.2799509638398614799184305779458800876, 8.195701121494907799764162315627806779255, 12.00578914216754094209096291817135010493, -13.94478486295526068743036817694004176071, 6.076108931827048077568214576728099496674, 4.520241233373834865797786027885951437785, -2.135931827199099570228348025938666016881,
      -14.80251191550936098733013842192740254165, 8.3724209293748051406334535925481356416, 12.71159243547065971783629215370754337502, -14.75037355891892470735726604555083262722, 6.26669745635574851253770629322552955966, 4.894395271244742501855647295740563710984, -2.327837056373834561737338703359436199637,
      -14.71878489558965156443673711777410555106, 8.409210573109215536243537942706115914504, 13.04653074570377542013817659418775572549, -14.78841336620005841711419940401936511077, 6.079225561852316159444046637589758570403, 4.926739579400471882708852156425352515885, -2.344659713427584168498828324267181790142,
      -14.45104936958065467310798735406827484006, 8.294156316343753049368353582044789960218, 12.56481036699805374023116883258766831224, -14.37031913106474617549406163308023512086, 6.191978924124212023003675871832842037236, 4.729083557106892488186926329455388515764, -2.242783226601605159708966993675716850563,
      -13.16366706799907833661476495847429535808, 7.736840100930212404318583726192539937137, 10.54679782605921145791260894612348384336, -12.3215755173083268089485734997517519358, 5.842596453601941778302220664276847548322, 3.736566097378004106709409204667556353262, -1.73258747846078116972682136114117767401,
      -13.263897826520392738916442895457857897, 7.7861789622453015782607396221041040009, 10.35338920580075881363122783190112306274, -12.50698185138857094191913095375700334606, 6.397588265841808682952649934536723129688, 4.003128157660551455854187682536877102914, -1.833602444503654380727428752726519947889,
      -12.78086538388859487674151895481244231376, 7.576875562434181262738490582531617704867, 9.599556547248780940167069540811963553231, -11.72661343166134872088326784529840426528, 6.276724720047905989256248396617195978619, 3.668728177255541544978524602672669368162, -1.614406191436466139515546322523417149909
  };

  const double b[] = {
      -12.78086538388859487674151895481244231376, 7.576875562434181262738490582531617704867, 9.599556547248780940167069540811963553231, -11.72661343166134872088326784529840426528, 6.276724720047905989256248396617195978619, 3.668728177255541544978524602672669368162, -1.614406191436466139515546322523417149909
  };

  const double bt[] = {
      -13.56122472236872793701951976770327776893, 7.85112736040522576490692428160825917758, 11.55713689832861419049952878162235994384, -13.71626961325604856568921319826094682262, 6.226067309660017722097407102829552411391, 4.983836118077694448040786394462527664561, -2.340673350846775622835913594558744498371
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK5_4_7L5SA;

  const double A_part_inv[] = {
      -2313.637482581083145889116815907862093966, 1205.384893265870871229979805583875025552, 2201.534554946306316787373612149733169436, -2543.136453961119482787155209809645191217, 1008.57765784675696068851845726049644746, 877.6439225808579102301971600431504406312, -420.5957270112306989384993943104566135916,
      -1739.437324939799322536509599409252188256, 902.9872017816196694622175008021144548974, 1669.001513825553695637400262440438261357, -1927.684356315582886451911849999908778978, 760.0610144654702920740250539529339025834, 666.7841960164574253130285932040931032008, -319.6465224239562002222689128915256633418,
      1200.604904034791418036768144948459968712, -629.1560634567997373926007225984700033837, -1145.635712187632184040192382847042648551, 1328.383595726135492356941906812392543908, -524.3003348624591006882927253012469914279, -457.1229686367877221161446339020718920736, 219.0217156766509604886807879965635540243,
      3164.809572829312184272851620010188771369, -1656.129283122810341639790185349706897551, -3003.974018277325420658692033812519503405, 3476.590585625818286003880054943048254039, -1380.663998976082184288442664659777726587, -1195.177335841960561308282285079797765926, 572.9912815706144086444887853211248942854,
      459.5875520771341073533711604263912381154, -240.7186068704185385042093754368349144881, -444.2923393355993810022857749281299539935, 515.297330948813617769396434763128085857, -201.7373401832254763915758307635866059913, -175.172995975456639772777633617390671279, 83.89795313917995607748197692169090808039,
      619.0554300183448815274547858736621587672, -324.4738817252136156792895117680303886658, -579.3112421679732846947179476282499983082, 674.0440076841394351196420425069164366257, -274.6665184563506302139797421470511908918, -239.8287700422640791907559192258234095577, 120.9420883218944645575222417477540210474,
      -2502.829894255765556115192871353548812752, 1310.573139423591738706890659739108684128, 2368.122162764072848746533009972324411963, -2732.779717430364187870286873633488507221, 1085.184260735994433917708643201243159442, 918.5529833312593481243595948425162994488, -429.7384824132330699544566072832076849194
  };

  const double T[] = {
      0.5344386012170108311339723424704414219212, 0.4363151291206883689025537717211069480294, -0.09080833887921588943707807840229573051661, 0.3127536685111874954093450547934845137668, 0.6237784208178234265887290010368361208441, -0.1642135772354659309863171604002542589671, 0.0433342915708529333949971857142994460374,
      -0.2918196313052629371035883574441653456353, -0.6404372854416881718429341469846796786819, -0.4335113592301066350293109084367136736034, 0.2770736355057177300112773531940345114898, 0.4343470285059855668389474639051827119592, -0.2161249827738585991828721741268467929386, 0.06791272911665404759452344012783191578367,
      -0.4784916761413239574938148823596634202887, 0.2928466651950593463738779103021084092871, 0.1170536770783570740732962043176080320023, 0.7239426244098055314159332724339600559225, -0.04087874268259805696727682978413396638082, 0.3280025160039341712147928189855262763442, -0.1955385836208725176038165166736861558425,
      0.5528917546148464854809940595885519737897, -0.4065657561506038871198673329293148300508, -0.1200116537714950285289829826342695458742, 0.2002613340257937810494750198860146272766, -0.1226714711487887172118206324214382576412, 0.6579637464387335012932250774174121632864, -0.1629202663769680797692216211715757252613,
      -0.2278274801589539478185012788805353919918, -0.09505999383207964017601834216070001125561, 0.4673424591500938178581632843290854310792, -0.3652486406154189724629956864684038968919, 0.630747003598047456530086365029257997087, 0.4298207014716087951442118371350881115252, -0.0682281122392866236450725323452356473227,
      -0.1864419898048914442464774563092923762936, 0.3216404819678881297308158430501950473184, -0.5926371090107863355205939904088809644799, -0.2208254481115951961270442071090676616971, 0.04188161223247815420113483819124785345503, 0.4483599189405828915299535180054243865524, 0.5089434909016031339354256219430989128443,
      0.08892205338644740267711901724510851395994, -0.1895397215847084389428971782571763209984, 0.453971000779575873413187164643537799794, 0.2811536412572195457314477748316092782771, -0.07699303294336331914971156030680449416401, -0.007035510924872237957169407477881655144525, 0.8155078769002382842561303364335374817301
  };

  const double T_inv[] = {
      0.5344386012170108311339723424704414219212, -0.2918196313052629371035883574441653456353, -0.4784916761413239574938148823596634202887, 0.5528917546148464854809940595885519737897, -0.2278274801589539478185012788805353919918, -0.1864419898048914442464774563092923762936, 0.08892205338644740267711901724510851395994,
      0.4363151291206883689025537717211069480294, -0.6404372854416881718429341469846796786819, 0.2928466651950593463738779103021084092871, -0.4065657561506038871198673329293148300508, -0.09505999383207964017601834216070001125561, 0.3216404819678881297308158430501950473184, -0.1895397215847084389428971782571763209984,
      -0.09080833887921588943707807840229573051661, -0.4335113592301066350293109084367136736034, 0.1170536770783570740732962043176080320023, -0.1200116537714950285289829826342695458742, 0.4673424591500938178581632843290854310792, -0.5926371090107863355205939904088809644799, 0.453971000779575873413187164643537799794,
      0.3127536685111874954093450547934845137668, 0.2770736355057177300112773531940345114898, 0.7239426244098055314159332724339600559225, 0.2002613340257937810494750198860146272766, -0.3652486406154189724629956864684038968919, -0.2208254481115951961270442071090676616971, 0.2811536412572195457314477748316092782771,
      0.6237784208178234265887290010368361208441, 0.4343470285059855668389474639051827119592, -0.04087874268259805696727682978413396638082, -0.1226714711487887172118206324214382576412, 0.630747003598047456530086365029257997087, 0.04188161223247815420113483819124785345503, -0.07699303294336331914971156030680449416401,
      -0.1642135772354659309863171604002542589671, -0.2161249827738585991828721741268467929386, 0.3280025160039341712147928189855262763442, 0.6579637464387335012932250774174121632864, 0.4298207014716087951442118371350881115252, 0.4483599189405828915299535180054243865524, -0.007035510924872237957169407477881655144525,
      0.0433342915708529333949971857142994460374, 0.06791272911665404759452344012783191578367, -0.1955385836208725176038165166736861558425, -0.1629202663769680797692216211715757252613, -0.0682281122392866236450725323452356473227, 0.5089434909016031339354256219430989128443, 0.8155078769002382842561303364335374817301
  };

  const double gamma[] = {
      7.0
  };
  const int real_eig_index[] = {
      0, 0, 0, 0, 0, 0, 0
  };
  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
  };
  const double L[] = {
      -381.3874973765223731889176856085659624131,
      -1063.806278209832169928846718916177914156, 13.19405503849866440595909114370133319867,
      -1371.230527961048768703961766142387431487, 47.2078055458074764219185194723531884958, 8.673997212687813240303531601244015943935,
      -4121.137038252929310001739377206974553543, 154.6712643763703691321574522006904305005, 7.722806244647233745000525448422130658298, 12.2380317502056150141305333122675610843,
      7215.643616979552161362850781752181811826, -260.9719428592350472314571252683433061561, -14.73647538438286408426891197341492274542, -19.57896425427126430360386431791420164538, -18.93503481564942981511259494259491886002,
      -5262.736220531681306800768945884743929118, 170.5250942747848039648911203763536596995, 32.93897146530310096553478707019821068459, 32.22829106092182770685704101284495814128, 3.556464553977176636460570860668443910167, -14.98357179916151083004524701977922606102
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 7, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* SIRK3(2)3L[2]SA constructed by @linuslangenkamp
 * Dense output has order 3
 * Internal Stability: [L, L, L]
 * Comment: This is a very famous SIRK method (triple eigenvalue 0.43586652..), but I dicovered it in when enforcing
 *          simplifying assumptions B(2s-3), C(s-1), D(s-3) + forcing the remaining 2 DOF such that we have a triple real eigenvalue
 *          => general method with s stages (s odd) => order 2s-3, stage order s-1, 3 same real eigenvalues, + (s-3) / 2 complex conjugate pairs
 */
void denseOutput_SIRK3_2_3L2SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((0.8888193455201129579457025392994137251277 * dt - 2.417138295894903250808499207310438746517) * dt + 2.167818555229467627779890796722636317652);
  tableau->b_dt[1] = ((-3.388819345520112957945702539299413725128 * dt + 6.542138295894903250808499207310438746517) * dt - 2.917818555229467627779890796722636317652);
  tableau->b_dt[2] = ((2.5 * dt - 4.125) * dt + 1.75);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_SIRK3_2_3L2SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 3;
  tableau->order_b = 3;
  tableau->order_bt = 2;
  tableau->fac = 1.0;

  const double c[] = {
      0.2870044360323416659118617618342943123176, 0.8129955639676583340881382381657056876824, 1.0
  };

  const double A[] = {
      0.2795361379593003960409051905806461886097, 0.2487140815180665450018245992322299545607, -0.2412457834450252751308680279785818308528,
      0.4398874544469346273928637704905042575789, 0.9030634265660766022071531630000243389782, -0.5299553170453528955118786953248229088747,
      0.6394996048546773349170941287116112962621, 0.2355003951453226650829058712883887037379, 0.125
  };

  const double b[] = {
      0.6394996048546773349170941287116112962621, 0.2355003951453226650829058712883887037379, 0.125
  };

  const double bt[] = {
      0.6355252094072296753490442393082399340765, 0.2506536523813882108298175493096462447853, 0.1138211382113821138211382113821138211382
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_SIRK3_2_3L2SA;

  const double A_part_inv[] = {
      2.870423751823104825432835576012493449032, -1.061553441624325806039559248730291273754, 1.039213888889348969845119999655642011332,
      -4.756820740387965319729655160331382604313, 2.285089886593368520566598158923098357913, 0.5074607128342258496177015733052161546198,
      -5.723213528476190262785835322118683609905, 1.125787481724482342728670743914459409933, 1.727327442420651813466717349143189799935
  };

  const double T[] = {
      2.158440533161152312081176454173113632197, -1.041364909927715149993936389902229245302, -0.1010644881793152254941994633594710608527,
      -1.521179148122072731327809802063510933009, -0.4764713350663474072782504980749194029519, -1.0,
      1.349645967740455926473935450245796612651, 0.6025238303299091267587684311385390383075, -0.9654661233524565391833273970279014808818
  };

  const double T_inv[] = {
      0.2021599330220091430417666053154440968844, -0.2028744657259608803771301406614669941286, 0.1889691115533045798624417862251606543501,
      -0.5362108676308546955717353483088516999959, -0.3705330375222970831561894120853689874237, 0.4399169521772483280759706905167565661962,
      -0.05203236672167732383771668700395748196928, -0.514843221976824296530174372139251723835, -0.4970636896562528096631349011118468271271
  };

  const double gamma[] = {
      2.29428036027904171982205036135959386896
  };

  const int real_eig_index[] = {
      0, 0, 0
  };

  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE
  };
  const double L[] = {
      -5.263722371562129474894569959397685875815,
      12.07645485903641431725422313010648324105, -5.263722371562129474894569959397685875815
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, NULL, NULL,
                               FALSE, FALSE, 3, 0, 1, 0,
                               real_eig_index, NULL, L, hasL, NULL, NULL);
}

/* FIRK7(6TS)5L[4]SA constructed by @linuslangenkamp
 * Dense output has order 5
 * Internal Stability: [A(87.140°), A(89.9996°), L, L, L]; so stages 1 and 2 are almost internally L stable (note that A stability => L stability for internal stages ofc)
 * Comment: Discovered by simplifying assumptions B(2s-3), C(s-1), D(s-3) + forcing the remaining 2 DOF such that we have a triple real eigenvalue
 *          => general method with s stages (s odd) => order 2s-3, stage order s-1, 3 same real eigenvalues, + (s-3) / 2 complex conjugate pairs
 *          Method has a trivial embedded method of order 4, but a stable two-step estimator of order 6 can be constructed.
 *          Has very similar properties to Radau IIA (cost of LU factorizations is same as order 5 Radau), is also L-stable, high stage order.
 *          Thus this 7th order method has the same cost for factorization as 5th order method with similar properties. Since it has more stages, it will take more LU-solves
 *          and RHS evaluations, but this allows very good extrapolation and especially an two-step embedded method of 1 order less. (Radau IIA: order 2s-1 + two-step error of order s only!)
 */
void denseOutput_FIRK7_6_5L4SA(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates)
{
  tableau->b_dt[0] = ((((1.468796196021988210613169913750170131782 * dt - 5.464264470749474076621409671236961144387) * dt + 7.84076862826184513779047259518344064467) * dt - 5.361370574016952768814235174541012432984) * dt + 1.713512166136325377676841679728696850598);
  tableau->b_dt[1] = ((((-6.052037538871420656057967212258056246023 * dt + 20.34554862197086713524753975631542702094) * dt - 24.7573615409288360166484950109268457259) * dt + 12.34028251158488125778697076728564963065) * dt - 1.530487193909619726328779465762188937215);
  tableau->b_dt[2] = ((((15.44899254056479661033716594820304037841 * dt - 45.46888298668514069099014798516954401428) * dt + 46.05258846098512510751757590490227564693) * dt - 17.78386112402080332491844765952063174434) * dt + 2.040526109002811039558929803997410712967);
  tableau->b_dt[3] = ((((-23.46575119771536416489236864969515426417 * dt + 62.96259883546374763236401790009107813774) * dt - 58.19155110387368978421510904471442612126) * dt + 21.22161585311954150261237873344266121334) * dt - 2.390217747896183357573658684630585293016);
  tableau->b_dt[4] = ((((12.6 * dt - 32.375) * dt + 29.05555555555555555555555555555555555556) * dt - 10.41666666666666666666666666666666666667) * dt + 1.166666666666666666666666666666666666667);

  denseOutput(tableau, yOld, x, k, dt, stepSize, y, nIdx, idx, nStates);
}

void getButcherTableau_FIRK7_6_5L4SA(BUTCHER_TABLEAU* tableau)
{
  tableau->nStages = 5;
  tableau->order_b = 7;
  tableau->order_bt = 4;
  tableau->fac = 1.0;

  const double c[] = {
      0.07936894202885614189857346696998223163424, 0.3661408265431655202725168379045070337591, 0.7010262039595140472028491509607112906459, 0.9090195830240198461816160997203549995164, 1.0
  };

  const double A[] = {
      0.09917465323724796106945445429512232596064, -0.02747467051496388832410863398603865669626, 0.00009930326040850126349374620724070047419693, 0.02529494327592701865509710353766482265388, -0.01772528722976345076536320308400696075823,
      0.2093814828308615551062485631910397101671, 0.1863908504856106976881546475083260067326, -0.04558652798968104789433911423309923542821, 0.02013405750058447618315708785973880969998, -0.004179036284210160810704346421498257412346,
      0.2012882824881965285641677041081149672835, 0.3323576991534776005339407323407981086079, 0.2394441810510012473945208456326660103512, -0.1347589124924606750859072728956933510953, 0.06269495375929934579612714177482555549861,
      0.1863801950246908704063755347852608131305, 0.3912476802155226783527381757489225281856, 0.1765602464156194941927534878422116179949, 0.2581991621356775680415669141153079503142, -0.1033677007674907648118180127713479101088,
      0.1974419456537318806448393428843340496788, 0.3459448598458719939992688346539857424417, 0.2893629998467887415050760124125509796867, 0.1366946390980518282952602544935736726373, 0.03055555555555555555555555555555555555556
  };

  const double b[] = {
      0.1974419456537318806448393428843340496788, 0.3459448598458719939992688346539857424417, 0.2893629998467887415050760124125509796867, 0.1366946390980518282952602544935736726373, 0.03055555555555555555555555555555555555556
  };

  const double bt[] = {
      0.1938800501166415212275675463562802861317, 0.3606213177223238518512612595514369370418, 0.2518985117634085028115775941078257935839, 0.1936001203976261241095935999844569832426, 0.0
  };

  setButcherTableau(tableau, c, A, b, bt);
  tableau->isKLeftAvailable = FALSE;
  tableau->isKRightAvailable = TRUE;
  tableau->withDenseOutput = TRUE;
  tableau->dense_output = denseOutput_FIRK7_6_5L4SA;

  const double A_part_inv[] = {
      7.081745891557630035321472266155803145431, 1.444729823500549439237271077635871288049, 0.3107976818271026161524438201611266038671, -0.9266002428302470115411633851370136546416, 0.5333751964386555808404912698709829841977,
      -6.800911089875854403308751950387634588336, 2.399910763004599626309803383903558366669, 0.5315699152226191450773865766231609910576, 1.16406039253963090920441317350848338729, -0.769722324809327147734729705494685498175,
      4.846275705048664132212285268547770793333, -5.361813804295172567797058318899180522292, 2.03111600935565390552166927224991774608, 0.7558745443467562444072742458869499943547, 0.4675648536247776308617006877615992276758,
      -1.428871969464794041743737151128804148209, 1.683940808171019107850831238615169353217, -4.777030015397985587659788907853532623213, -1.248246174077396746862134655127349708654, 4.980352011723877726764433471989435725672,
      -8.263871723693508735043585740885465209476, 6.736509364883155389210456325358434370501, -5.890706391704246778761186013317878340287, -8.765820652928634624212404196906866561176, 11.28722582410264324164703738026243018307
  };

  const double T[] = {
      4.348110100246887877479974760386181598654, -0.5628639470324634239312923402564964601062, 0.01829732741453861408338984677735971965213, 0.0, -0.06259729061887727284331719865515895282666,
      -16.92461191379145670890633364885349161159, -0.7998879779658604873369630221976202482631, -0.1127830703924333173356121190534801254328, -0.1060461955386727808491951516537530288557, 0.1410990658121878927145690571362746169389,
      35.25487539919672725050005335018076365084, -0.6297522938527773232866253909869732323015, -0.1163748785993767657563961253827326026633, 0.4668342100917464934274336678261080172043, 0.1429670798595173884770262376497888433408,
      -16.12988881777823836575531607465124754454, -1.523440206774769799449375408121174975801, -0.7484505952729372787927693092383018857267, 0.6029769337399318047857991011105898484561, -0.559907539668549189750899077286056121335,
      9.958011533711180466778695015577114361779, 1.293421992564391406142334044012861269891, -1.0, 0.5250019421248109445667435688837312778966, -1.0
  };

  const double T_inv[] = {
      0.04899097407928203672107738378293297158014, 0.01508435284979262700065427632397543487509, 0.01603658644060451876240255305405169157214, -0.02135056797047662298224913262865337716906, 0.01330873377054810827875998139842624342427,
      -1.048780074916802801723157789349018873534, -0.2433073288193404368104820878116423559668, -0.03795535607763248280986964735428316179105, -0.07014770575868400784674849751465640665951, 0.06517021726447800792533161365694794424165,
      0.07696711739186103461745470707487199594851, -3.881619201548677878599771374098343920593, -0.9240793166321237645959294651390114513421, 1.227054156885899441875792060561455422725, -1.37166057167216770465330595556811062018,
      -4.140106421989528896990712898691895992346, -3.07841770674027052138136356705530001587, 0.2865236647020689707902272713178867719477, 1.97480265900334897813411463901482733746, -1.239945864190763028164120664388155108831,
      -3.11919355887125257578849080078003070753, 2.100955036448402355608967101924777887209, 1.185105017515901849922080393518683151105, -0.4936187130534088837263925264450105399592, -0.06249229850132496223806354248303833514235
  };

  const double gamma[] = {
      4.95188287370231533499240065774882845495
  };

  const double alpha[] = {
      3.348051846418092028480322837098937183871
  };
  const double beta[] = {
      4.581870356476078951465044796737423269106
  };

  const int real_eig_index[] = {
      0, 0, 0
  };
  const int cmplx_eig_index[] = {
      0
  };

  const modelica_boolean hasL[] = {
      FALSE, TRUE, TRUE, FALSE, FALSE
  };
  const double L[] = {
      -24.52114399486630068708149963428620467956,
      121.4258329917668097563784300758287452341, -24.52114399486630068708149963428620467956,
      0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0
  };

  setTTransformLowerTriangular(tableau, A_part_inv, T, T_inv, gamma, alpha, beta,
                               FALSE, FALSE, 3, 1, 1, 1,
                               real_eig_index, cmplx_eig_index, L, hasL, NULL, NULL);
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
  tableau->error_order = (unsigned int) fmin(tableau->order_b, tableau->order_bt);
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
    case RK_SIRK3_2_3L2SA:
      getButcherTableau_SIRK3_2_3L2SA(tableau);
      break;
    case RK_SIRK3_2_4L3SA:
      getButcherTableau_SIRK3_2_4L3SA(tableau);
      break;
    case RK_SIRK3_2_5L3SA:
      getButcherTableau_SIRK3_2_5L3SA(tableau);
      break;
    case RK_SIRK4_3_5L3SA:
      getButcherTableau_SIRK4_3_5L3SA(tableau);
      break;
    case RK_SIRK5_4_5L3SA:
      getButcherTableau_SIRK5_4_5L3SA(tableau);
      break;
    case RK_SIRK4_3_6L4SA:
      getButcherTableau_SIRK4_3_6L4SA(tableau);
      break;
    case RK_SIRK5_4_6L4SA:
      getButcherTableau_SIRK5_4_6L4SA(tableau);
      break;
    case RK_SIRK5_4_7L4SA:
      getButcherTableau_SIRK5_4_7L4SA(tableau);
      break;
    case RK_SIRK6_5_7L4SA:
      getButcherTableau_SIRK6_5_7L4SA(tableau);
      break;
    case RK_SIRK6_5_8L4SA:
      getButcherTableau_SIRK6_5_8L4SA(tableau);
      break;
    case RK_SIRK5_4_7L5SA:
      getButcherTableau_SIRK5_4_7L5SA(tableau);
      break;
    case RK_FIRK7_6_5L4SA:
      getButcherTableau_FIRK7_6_5L4SA(tableau);
      break;
    case RK_RADAU_IA_2:
      getButcherTableau_RADAU_IA_2(tableau);
      break;
    case RK_RADAU_IA_3:
      getButcherTableau_RADAU_IA_3(tableau);
      break;
    case RK_RADAU_IA_4:
      getButcherTableau_RADAU_IA_4(tableau);
      break;
    case RK_RADAU_IIA_2:
      getButcherTableau_RADAU_IIA_2(tableau);
      break;
    case RK_RADAU_IIA_3:
      getButcherTableau_RADAU_IIA_3(tableau);
      break;
    case RK_RADAU_IIA_4:
      getButcherTableau_RADAU_IIA_4(tableau);
      break;
    case RK_RADAU_IIA_5:
      getButcherTableau_RADAU_IIA_5(tableau);
      break;
    case RK_RADAU_IIA_6:
      getButcherTableau_RADAU_IIA_6(tableau);
      break;
    case RK_RADAU_IIA_7:
      getButcherTableau_RADAU_IIA_7(tableau);
      break;
    case RK_LOBA_IIIA_3:
      getButcherTableau_LOBATTO_IIIA_3(tableau);
      break;
    case RK_LOBA_IIIA_4:
      getButcherTableau_LOBATTO_IIIA_4(tableau);
      break;
    case RK_LOBA_IIIB_3:
      getButcherTableau_LOBATTO_IIIB_3(tableau);
      break;
    case RK_LOBA_IIIB_4:
      getButcherTableau_LOBATTO_IIIB_4(tableau);
      break;
    case RK_LOBA_IIIC_3:
      getButcherTableau_LOBATTO_IIIC_3(tableau);
      break;
    case RK_LOBA_IIIC_4:
      getButcherTableau_LOBATTO_IIIC_4(tableau);
      break;
    case RK_GAUSS2:
      getButcherTableau_GAUSS2(tableau);
      break;
    case RK_GAUSS3:
      getButcherTableau_GAUSS3(tableau);
      break;
    case RK_GAUSS4:
      getButcherTableau_GAUSS4(tableau);
      break;
    case RK_GAUSS5:
      getButcherTableau_GAUSS5(tableau);
      break;
    case RK_GAUSS6:
      getButcherTableau_GAUSS6(tableau);
      break;
    default:
      throwStreamPrint(NULL, "Error: Unknown Runge Kutta method.");
  }

  return tableau;
}

void freeContractiveDefectError(CONTRACTIVE_ERROR *contraction)
{
  free(contraction->dT_A);
  free(contraction);
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
  free(t_transform->realEigenvalueIndex);
  free(t_transform->complexEigenpairIndex);
  free(t_transform->L);
  free(t_transform->hasL);
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

  if (tableau->contraction)
  {
    freeContractiveDefectError(tableau->contraction);
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
