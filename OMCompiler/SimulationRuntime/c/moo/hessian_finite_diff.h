/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef MOO_OM_HESSIAN_FINITE_DIFFERENCES_H
#define MOO_OM_HESSIAN_FINITE_DIFFERENCES_H

// TODO: maybe split this into the C++ part with pattern generation and the C part of evaluation and structs

#include <map>

#include "simulation_data.h"

typedef struct {
    int i;  // first variable index
    int j;  // second variable index
} VarPair;

/* Maps a (color1, color2) pair to all (i, j) variable pairs sharing these colors.
 * For each (i, j), stores the list of function rows f where both ∂f/∂xi and ∂f/∂xj are nonzero (overestimate).
 * Also stores the flat COO nz index for (i, j). */
typedef struct {
    // actual variable pairs, i.e. varPair[k] == (v1, v2); can also be accessed via HESSIAN->(row, col)[lnnzIndices[k]]
    VarPair* varPairs;        // is the variable pair contributing to the functions contributingRows[k]
    int** contributingRows;   // contributingRows[k] = functions affecting the varPair[k]
    int* numContributingRows; // number of rows for each pair
    int* lnnzIndices;         // mapping from variable pair to Hessian COO index
    int size;                 // number of variable pairs in this color group
} ColorPair;

/* Holds the compressed Hessian structure derived from a Jacobian.
 * COO format row/col lists lower-triangular nonzeros (∂²G/∂xi∂xj).
 * Variable pairs are grouped by (color1, color2) inside ColorPair blocks. */
typedef struct {
    /* this is an array of ptrs to ColorPair, is NULL if (c1, c2) is not contained */
    ColorPair** colorPairs;        // get_color_pair_index(c1, c2) with c1 >= c2 -> variable pairs for color pair
    int* row;                      // flat COO row indices (i)
    int* col;                      // flat COO column indices (j)
    int size;                      // number of variables (Hessian is size × size)
    int numFuncs;                  // number of functions in the Hessian
    int lnnz;                      // number of lower triangular nonzeros
    int** colsForColor;            // colsForColor[c] is an array of column indices in color c
    int* colorSizes;               // colorSizes[c] is the number of columns in colorCols[c]
    int numColors;                 // number of seed vector colors
    JACOBIAN* jac;                 // input Jacobian with sparsity + coloring
    int** cscJacIndexFromRowColor; // mapping of J[function / row][color] -> index in flat Jacobian CSC buffer
    modelica_real* ws_oldX;        // workspace array to remember old x values and seed vector for JVPs | size = #vars
    modelica_real* ws_h;           // workspace array to remember perturbation for variables during numerical Hessian eval | size = #vars
    modelica_real** ws_baseJac;    // workspace stores all rows x colors of the base Jacobian J(x)
} HESSIAN_PATTERN;

/* always use this if accessing HESSIAN_PATTERN.colorPairs
 * returns the index of a colorPair (c1, c2) in the HESSIAN_PATTERN.colorPairs */
static inline int get_color_pair_index(int c1, int c2) {
    if (c1 >= c2) return c1 * (c1 + 1) / 2 + c2;
    else return c2 * (c2 + 1) / 2 + c1;
}

static inline void set_seed_vector(int size, const int* cols, modelica_real value, modelica_real* seeds) {
    for (int i = 0; i < size; i++) { seeds[cols[i]] = value; }
}

HESSIAN_PATTERN* generate_hessian_pattern(JACOBIAN* jac);

void print_hessian_pattern(const HESSIAN_PATTERN* hes_pattern);

void free_hessian_pattern(HESSIAN_PATTERN* hes_pattern);

void eval_hessian_fwd_differences(DATA* data, threadData_t* threadData, HESSIAN_PATTERN* hes_pattern, modelica_real h,
                                  int* u_indices, const modelica_real* lambda, modelica_real* jac_csc, modelica_real* hes);

void hessian_fwd_differences_wrapper(void* args, modelica_real h, modelica_real* result);

// ===== EXTRAPOLATION =====

/* generic computation function of the form "result := f(args, h0)" */
typedef void (*computation_fn_t)(void* args, modelica_real h0, modelica_real* result);

/**
 * @brief Workspace for Richardson extrapolation.
 * Stores intermediate results and metadata for extrapolation steps.
 */
typedef struct {
    modelica_real** ws_results;
    int resultSize;
    int maxSteps;
} ExtrapolationData;

/* Hessian structure for richardson extrapolation scheme */
typedef struct {
    DATA* data;
    threadData_t* threadData;
    HESSIAN_PATTERN* hes_pattern; // Hessian structure
    int* u_indices;               // indices of the inputs in realVars (REMOVE ME!)
    const modelica_real* lambda;  // dual variables for each function
    modelica_real* jac_csc;       // precomputed Jacobian entries in CSC format (can be NULL)
} HessianFiniteDiffArgs;

ExtrapolationData* init_extrapolation_data(int resultSize, int maxSteps);

void free_extrapolation_data(ExtrapolationData* extrData);

void richardson_extrapolation(ExtrapolationData* extrData, computation_fn_t fn, void* args, modelica_real h0,
                             int steps, modelica_real stepDivisor, int methodOrder, modelica_real* result);

#endif // MOO_OM_HESSIAN_FINITE_DIFFERENCES_H
