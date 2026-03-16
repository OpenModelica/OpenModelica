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

/*! \file gbode_util.h
 */

#ifndef _GBODE_UTIL_H_
#define _GBODE_UTIL_H_

#include "nonlinearSystem.h"
#include "simulation_data.h"
#include "solver_main.h"
#include "util/omc_error.h"

#include "gbode_main.h"
#include "gbode_tableau.h"

#ifdef __cplusplus
extern "C" {
#endif

// LA functions
void addSmultVec_gbf(double* a, double* b, double *c, double s, int nIdx, int* idx);
void addSmultVec_gb(double* a, double* b, double *c, double s, int n);

// Interpolation functions for the whole vector or indices referenced by index vector
void gb_interpolation(enum GB_INTERPOL_METHOD interpolMethod, double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f,
                        int nIdx, int* idx, int nStates, BUTCHER_TABLEAU* tableau, double* x, double *k);
double error_interpolation_gb(DATA_GBODE* gbData, int nIdx, int* idx, double tol);
void extrapolation_gb(DATA_GBODE* gbData, double* nlsxExtrapolation, double time);
void extrapolation_hermite_gb(double* nlsxExtrapolation, int nStates, double t0, double *x0, double* k0, double t1, double *x1, double* k1, double time);
void extrapolation_gbf(DATA_GBODE* gbData, double* nlsxExtrapolation, double time);

// Copy only specific values referenced by an index vector
void copyVector_gbf(double* a, double* b, int nIndx, int* indx);
void projVector_gbf(double* a, double* b, int nIndx, int* indx);

// Debug functions for the development of gbode
void printVector_gb(enum OMC_LOG_STREAM stream, char name[], double* a, int n, double time);
void printIntVector_gb(enum OMC_LOG_STREAM stream, char name[], int* a, int n, double time);
void printVector_gbf(enum OMC_LOG_STREAM stream, char name[], double* a, int n, double time, int nIndx, int* indx);
void printSparseJacobianLocal(JACOBIAN* jacobian, const char* name);

void debugRingBuffer_gb(enum OMC_LOG_STREAM stream, double* x, double* k, int nStates, BUTCHER_TABLEAU* tableau, double time, double stepSize);
void debugRingBuffer_gbf(enum OMC_LOG_STREAM stream, double* x, double* k, int nStates, BUTCHER_TABLEAU* tableau, double time, double stepSize, int nIndx, int* indx);
void debugRingBufferSteps_gb(enum OMC_LOG_STREAM stream, double* x, double* k, double* t, int nStates, int size);
void debugRingBufferSteps_gbf(enum OMC_LOG_STREAM stream, double* x, double* k, double *t, int nStates, int size, int nIndx, int* indx);
void dumpFastStates_gb(DATA_GBODE *gbData, modelica_boolean event, double time, int rejectedType);
void dumpFastStates_gbf(DATA_GBODE *gbData, double time, int rejectedType);

modelica_boolean checkFastStatesChange(DATA_GBODE* gbData);

void logSolverStats(enum OMC_LOG_STREAM stream, const char* name, double timeValue, double integratorTime, double stepSize, SOLVERSTATS* stats, int *fastStateUpdates);

void deprecationWarningGBODE(enum SOLVER_METHOD method);

/* cache for slow-state interpolations in multirate
 * avoids redundant slow-state interpolations during fast steps / NLS
 *
 * memory layout: n_stages + 2 slots total:
 *   - logical 0, ..., n_stages - 1 : tableau stage nodes
 *   - logical n_stages             : left boundary (t_n)
 *   - logical n_stages + 1         : right boundary (t_n+h)
 *
 * physical slot = (offset + logical) % (n_stages+2)
 * both states[] and valid[] accessed only via slowStateCache_slot()
 *
 * if the nodes of the RK method include 0.0 then left_stage is the index of that node,
 * same for right_stage with node 1.0 => we need the boundary of the interval in several occasions
 * and can rotate the buffer after a successful step in order to not interpolate to t_n + h =: t_{n+1} again */
typedef struct SLOW_STATE_CACHE
{
  int n_stages;            /* number of tableau stages */
  int n_states;            /* number of states (slow + fast) */
  double *states;          /* [(n_stages + 2) * n_states] */
  double *work;            /* [n_states], scratch buffer */
  modelica_boolean *valid; /* [n_stages + 2], indexed via slowStateCache_slot */
  int offset;              /* ring offset: physical = (offset + logical) % (n_stages + 2) */
  int left_stage;          /* logical index of left boundary - structural, set at alloc */
  int right_stage;         /* logical index of right boundary - structural, set at alloc */
} SLOW_STATE_CACHE;

SLOW_STATE_CACHE *slowStateCache_alloc(int n_stages, int n_states, double *c);
void slowStateCache_free(SLOW_STATE_CACHE *cache);

// hard invalidate: after events or fast state changes - full reset, offset=0
void slowStateCache_invalidate(SLOW_STATE_CACHE *cache);

// invalidate all except the left boundary - used for rejections (h := alpha * h, alpha < 1)
void slowStateCache_invalidate_keep_left(SLOW_STATE_CACHE *cache);

// soft invalidate: called at start of each fast step
// rotates offset so old right slot becomes new left slot
void slowStateCache_rotate(SLOW_STATE_CACHE *cache);

// fill x with interpolated slow states at a given stage or boundary
// => fast states are potentially overwritten
void slowStateCache_overwrite_stage(DATA_GBODE *gbData, SLOW_STATE_CACHE *cache, int stage, double *x);
void slowStateCache_overwrite_left (DATA_GBODE *gbData, SLOW_STATE_CACHE *cache, double *x);
void slowStateCache_overwrite_right(DATA_GBODE *gbData, SLOW_STATE_CACHE *cache, double *x);

// fill x with interpolated slow states at a given stage or boundary
// => guaranteed preservation of fast states
void slowStateCache_merge_stage(DATA_GBODE *gbData, SLOW_STATE_CACHE *cache, int stage, double *x);
void slowStateCache_merge_left (DATA_GBODE *gbData, SLOW_STATE_CACHE *cache, double *x);
void slowStateCache_merge_right(DATA_GBODE *gbData, SLOW_STATE_CACHE *cache, double *x);

#ifdef __cplusplus
};
#endif

#endif  /* _GBODE_UTIL_H_ */
