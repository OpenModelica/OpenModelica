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

/*! \file gbode_nls.h
 */

#ifndef GBODE_NLS_H
#define GBODE_NLS_H

#include "simulation_data.h"
#include "nonlinearSystem.h"

#include "gbode_main.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct KLUInternals KLUInternals;

typedef struct GB_INTERNAL_NLS_DATA
{
  NLS_USERDATA *nls_user_data;       // pointer to data, gbode data, etc.
  KLUInternals *klu_internals_real;  // internal data structures for real systems with klu linear solver (might change for ptr + enum, e.g. to have LAPACK)
  KLUInternals *klu_internals_cmplx; // internal data structures for complex systems with klu linear solver (might change for ptr + enum, e.g. to have LAPACK)
  double *jacobian_callback;         // buffer for continuous ODE Jacobian (size = nnz(J_f))
  int *ode_to_nls;                   // mapping ODE Jacobian nnz -> NLS Jacobian nnz
  int *nls_diag_indices;             // all diagonal nz indices of NLS Jacobian (size = cols)
  double *scal;                      // scaling vector for termination of Newton loop
  double *etas;                      // Newton contraction factors for each NLS stage (size == number of stages)
  double rtol;                       // Integrator RTOL
  double atol;                       // Integrator ATOL
  double rtol_sc;                    // scaled Integrator RTOL
  double atol_sc;                    // scaled Integrator ATOL
  double fnewt;                      // Newton tolerance: if eta * norm(dx) <= fnewt -> convergence
  double theta_keep;                 // if norm(dx_k) / norm(dx_{k-1}) = theta_{k} < theta_keep -> keep old jacobian_callback
  modelica_boolean call_jac;         // call jacobian in the next call to NLS solve
  double theta_divergence;           // if norm(dx_k) / norm(dx_{k-1}) = theta_{k} > theta_divergence -> divergence of Newton
  int max_newton_it;                 // maximum number of Newton iterations
  int size;                          // size of the system
  BUTCHER_TABLEAU *tabl;             // butcher tableau of the method
  modelica_boolean use_t_transform;  // use T transform to solve the system (false for (E)SDIRK, true for FIRK)
  double **real_nls_jacs;            // real NLS jacobians
  double **cmplx_nls_jacs;           // complex NLS jacobians (packed as real, imag)
} GB_INTERNAL_NLS_DATA;

NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GBODE* gbData);
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GBODEF* gbfData);
void freeRK_NLS_DATA( NONLINEAR_SYSTEM_DATA* nlsData);

//Specific treatment of NLS within gbode
NLS_SOLVER_STATUS solveNLS_gb(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, DATA_GBODE* gbData);

// Residuum and Jacobian functions for diagonal implicit (DIRK) and implicit (IRK) Runge-Kutta methods.
void residual_MS(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);
void residual_DIRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);
void residual_IRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);

void residual_MS_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);
void residual_DIRK_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);

GB_INTERNAL_NLS_DATA* gbInternalNlsAllocate(int size, NLS_USERDATA* userData, modelica_boolean attemptRetry, modelica_boolean isPatternAvailable);

int jacobian_SR_DIRK_assemble(DATA *data, threadData_t *threadData, DATA_GBODE* gbData, GB_INTERNAL_NLS_DATA *nls,
                              JACOBIAN *jac_ode, double *jac_buf_ode, double *jac_buf_nls);

int jacobian_SR_real_assemble(DATA *data, threadData_t *threadData, DATA_GBODE* gbData, GB_INTERNAL_NLS_DATA *nls,
                              double gamma, JACOBIAN *jac_ode, double *jac_buf_ode, double *jac_buf_nls);

int jacobian_SR_cmplx_assemble(DATA *data, threadData_t *threadData, DATA_GBODE* gbData, GB_INTERNAL_NLS_DATA *nls,
                               double alpha, double beta, JACOBIAN *jac_ode, double *jac_buf_ode, double *jac_buf_nls);

#ifdef __cplusplus
};
#endif

#endif  /* #ifndef GBODE_NLS_H*/
