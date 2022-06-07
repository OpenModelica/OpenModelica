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

/*! \file gbode_util.h
 */
#include "gbode_main.h"
#include "gbode_tableau.h"
#include "nonlinearSystem.h"


// Interpolation functions for the whole vector or indices referenced by index vector
void linear_interpolation_gb(double a, double* fa, double b, double* fb, double t, double *f, int n);
void hermite_interpolation_gb(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int n);
void linear_interpolation_gbf(double ta, double* fa, double tb, double* fb, double t, double* f, int nIdx, int* idx);
void hermite_interpolation_gbf(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int nIdx, int* idx);

// Copy only specific values referenced by an index vector
void copyVector_gbf(double* a, double* b, int nIndx, int* indx);

// Debug functions for the development of gbode
void printVector_gb(enum LOG_STREAM stream, char name[], double* a, int n, double time);
void printIntVector_gb(enum LOG_STREAM stream, char name[], int* a, int n, double time);
void printMatrix_gb(char name[], double* a, int n, double time);
void printVector_gbf(enum LOG_STREAM stream, char name[], double* a, int n, double time, int nIndx, int* indx);
void printSparseJacobianLocal(ANALYTIC_JACOBIAN* jacobian, const char* name);

void debugRingBuffer(enum LOG_STREAM stream, double* x, double* k, int nStates, BUTCHER_TABLEAU* tableau, double time, double stepSize);

