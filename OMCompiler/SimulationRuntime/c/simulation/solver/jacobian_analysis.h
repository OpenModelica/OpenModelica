/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Open Source Modelica Consortium (OSMC),
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

/*! \file jacobian_analysis.h
 */

#ifndef _JACOBIAN_ANALYSIS_H
#define _JACOBIAN_ANALYSIS_H

#include <stdio.h>
#include <stdlib.h>

#include "../../simulation_data.h"
#include "../simulation_info_json.h"
#include "../jacobian_util.h"
#include "../options.h"
#include "sundials_util.h"
#include "nonlinearSystem.h"
#include "simulation_data.h"
#include "sundials_error.h"
#include "simulation_data.h"
#include "util/simulation_options.h"

#include <kinsol/kinsol.h>
#include <nvector/nvector_serial.h>

#ifdef __cplusplus
extern "C" {
#endif

// TODO: add the derivative test here, so we only have one code with all the analysis methods
// unify all the debug messages of them

typedef enum SolverCaller {
    KINSOL_JAC_EVAL,
    KINSOL_ENTRY_POINT,
    KINSOL_B_JAC_EVAL,
    KINSOL_B_ENTRY_POINT
} SolverCaller;

static inline const char* SolverCaller_toString(SolverCaller caller) {
    switch (caller) {
        case KINSOL_JAC_EVAL:     return "kinsol: Jacobian eval";
        case KINSOL_ENTRY_POINT:  return "kinsol: Kinsol entry point";
        case KINSOL_B_JAC_EVAL:   return "experimental-kinsol: Jacobian eval";
        case KINSOL_B_ENTRY_POINT:return "experimental-kinsol: Kinsol entry point";
        default:                  return "UNKNOWN_SOLVER_CALLER";
    }
}

static inline const char* SolverCaller_callerString(SolverCaller caller) {
    switch (caller) {
        case KINSOL_JAC_EVAL:     return "kinsol";
        case KINSOL_ENTRY_POINT:  return "kinsol";
        case KINSOL_B_JAC_EVAL:   return "experimental-kinsol";
        case KINSOL_B_ENTRY_POINT:return "experimental-kinsol";
        default:                  return "UNKNOWN_SOLVER";
    }
}

typedef struct SVD_Component {
    int index;
    modelica_real value;
} SVD_Component;

typedef struct SVD_DATA {
    DATA *data;
    NONLINEAR_SYSTEM_DATA *nls_data;
    SolverCaller caller;

    modelica_boolean scaled;        // NLS is scaled

    int rows;                       // #rows
    int cols;                       // #columns
    int min_rows_cols;              // min(#rows, #cols)
    modelica_real  *A_dense;        // dense column-major matrix (m × n)
    modelica_real  *S;              // singular values (min(m, n))
    modelica_real  *U;              // left singular vectors (m × m if full)
    modelica_real  *VT;             // right singular vectors transpose (n × n if full)
    SPARSE_PATTERN *sparse_pattern; // sparse pattern
    modelica_real  *sp_values;      // CSC values (same order as sp->index)

    // statistics
    modelica_real sigma_max;        // largest singular value
    modelica_real sigma_min;        // smallest singular value
    modelica_real cond;             // condition = largest singular value / smallest singular value
    modelica_real rank_est_tol;     // tolerance for rank estimation, ranks count if sigma_i > rank_est_tol
    int estimated_rank;             // estimated rank
    int least_one_percent;          // index for first singular value < 1% of largest
} SVD_DATA;

static inline modelica_real _svd_max2(modelica_real a, modelica_real b) { return (a > b ? a : b); };

// entry point for svd analysis
int svd_compute(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values, modelica_boolean scaled, SolverCaller caller);

// entry point for jacobian sums of abs rows and cols
void nlsJacobianRowColSums(DATA *data, NONLINEAR_SYSTEM_DATA *nlsData, SUNMatrix J,
                           SolverCaller caller, modelica_boolean scaled);

#ifdef __cplusplus
};
#endif

#endif // _JACOBIAN_ANALYSIS_H
