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

/*! \file jacobian_svd.h
 */

#ifndef _JACOBIAN_SVD_H
#define _JACOBIAN_SVD_H

#include <stdio.h>
#include <stdlib.h>

#include "../../simulation_data.h"
#include "../simulation_info_json.h"
#include "../jacobian_util.h"
#include "../options.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SVD_Component {
    int index;
    modelica_real value;
} SVD_Component;

typedef struct SVD_DATA {
    DATA *data;
    NONLINEAR_SYSTEM_DATA *nls_data;

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

// only entry point
int svd_compute(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values,
                modelica_real *x_scale, modelica_real *f_scale);

#ifdef __cplusplus
};
#endif

#endif // _JACOBIAN_SVD_H
