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

/*! \file ebdd_runtime.h
 *
 *  Runtime side of the Equation-Based Declarative Debugger (EBDD) bridge.
 *
 *  When the OMC_LOG_EBDD stream is active (-lv=LOG_EBDD) the runtime appends
 *  per-equation runtime records to "<modelFilePrefix>_dbg.json". The records are
 *  keyed by the same equation index (eqIndex / EQUATION_INFO.id) that the static
 *  "<model>_info.json" uses, so the OMEdit transformational debugger can overlay
 *  runtime values onto the equations it already displays.
 *
 *  The file is newline-delimited JSON (one JSON object per line): the first line
 *  is a meta object, every following line is one record. JSONL keeps the file
 *  valid and parseable even if the simulation aborts.
 */

#ifndef EBDD_RUNTIME_H
#define EBDD_RUNTIME_H

#include "../../simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Append a record for a just-solved nonlinear system to the EBDD file.
 *
 * No-op unless the OMC_LOG_EBDD stream is active. Emits the equation index, the
 * solve time, the solver status, the iteration count and, for each iteration
 * variable, its name, solved value, residual and nominal.
 *
 * @param data        Runtime data struct.
 * @param nonlinsys   The nonlinear system that was just solved.
 */
void ebddRuntimeLogNonlinearSystem(DATA *data, NONLINEAR_SYSTEM_DATA *nonlinsys);

/**
 * @brief Append one Newton-iteration record for a nonlinear system.
 *
 * No-op unless the OMC_LOG_EBDD stream is active. For the given iteration emits,
 * per iteration variable, its name, the current iterate value (the initial guess
 * entering this iteration), the residual and the scaled residual (residual /
 * resScaling), plus the nominal. Both scaled and unscaled values are recoverable.
 *
 * @param data        Runtime data struct.
 * @param nonlinsys   The nonlinear system being solved.
 * @param iteration   1-based Newton iteration counter.
 * @param size        Number of iteration variables (== nonlinsys->size).
 * @param x           Current iterate (initial guess of this iteration), length size.
 * @param residual    Residual values at x, length size.
 * @param resScaling  Residual scaling factors, length size (NULL => scale 1.0).
 * @param nominal     Variable nominal values, length size (NULL => omitted).
 */
void ebddRuntimeLogNewtonIteration(DATA *data, NONLINEAR_SYSTEM_DATA *nonlinsys,
                                   int iteration, int size, const double *x,
                                   const double *residual, const double *resScaling,
                                   const double *nominal);

/**
 * @brief Append the Newton-iteration Jacobian of a nonlinear system.
 *
 * No-op unless the OMC_LOG_EBDD stream is active. The homotopy solver stores the
 * Jacobian column-major and column-scaled by the variable nominal, i.e.
 * jacColMajorScaled[col*size + row] == (d f_row / d x_col) * colScaling[col].
 * This emits the unscaled partial derivatives d f_row / d x_col as a dense
 * size x size matrix (row-major "rows"), labelled by the system's variables.
 *
 * @param data                Runtime data struct.
 * @param nonlinsys           The nonlinear system being solved.
 * @param iteration           1-based Newton iteration counter.
 * @param size                Dimension of the (square) system.
 * @param jacColMajorScaled   Column-major, column-scaled Jacobian, length size*size.
 * @param colScaling          Column scaling (variable nominal), length >= size.
 */
void ebddRuntimeLogJacobian(DATA *data, NONLINEAR_SYSTEM_DATA *nonlinsys,
                            int iteration, int size,
                            const double *jacColMajorScaled, const double *colScaling);

#ifdef __cplusplus
}
#endif

#endif /* EBDD_RUNTIME_H */
