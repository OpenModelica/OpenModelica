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
void extrapolation_gbf(DATA_GBODE* gbData, double* nlsxExtrapolation, double time);

// Copy only specific values referenced by an index vector
void copyVector_gbf(double* a, double* b, int nIndx, int* indx);
void projVector_gbf(double* a, double* b, int nIndx, int* indx);

// Debug functions for the development of gbode
void printVector_gb(enum OMC_LOG_STREAM stream, char name[], double* a, int n, double time);
void printIntVector_gb(enum OMC_LOG_STREAM stream, char name[], int* a, int n, double time);
void printVector_gbf(enum OMC_LOG_STREAM stream, char name[], double* a, int n, double time, int nIndx, int* indx);
void printSparseJacobianLocal(ANALYTIC_JACOBIAN* jacobian, const char* name);

void debugRingBuffer(enum OMC_LOG_STREAM stream, double* x, double* k, int nStates, BUTCHER_TABLEAU* tableau, double time, double stepSize);
void debugRingBufferSteps(enum OMC_LOG_STREAM stream, double* x, double* k, double* t, int nStates, int size);
void dumpFastStates_gb(DATA_GBODE *gbData, modelica_boolean event, double time, int rejectedType);
void dumpFastStates_gbf(DATA_GBODE *gbData, double time, int rejectedType);

modelica_boolean checkFastStatesChange(DATA_GBODE* gbData);

void logSolverStats(enum OMC_LOG_STREAM stream, const char* name, double timeValue, double integratorTime, double stepSize, SOLVERSTATS* stats);

void deprecationWarningGBODE(enum SOLVER_METHOD method);

#ifdef __cplusplus
};
#endif

#endif  /* _GBODE_UTIL_H_ */
