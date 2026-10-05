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

/*! \file linearSystem.h
 */


#ifndef _LINEARSYSTEM_H_
#define _LINEARSYSTEM_H_

#include <math.h>
#include "../../simulation_data.h"
#include "../../util/simulation_options.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef VOID
#undef VOID
#endif

typedef void* LS_SOLVER_DATA;

int initializeLinearSystems(DATA *data, threadData_t *threadData);
int updateStaticDataOfLinearSystems(DATA *data, threadData_t *threadData);
int freeLinearSystems(DATA *data, threadData_t *threadData);
int solve_linear_system(DATA *data, threadData_t *threadData, int sysNumber, double* aux_x);
int check_linear_solutions(DATA *data, int printFailingSystems);
void printLinearSystemSolvingStatistics(DATA *data, int sysNumber, int logLevel);

#if defined(OMC_RUST_SIMULATION_RUNTIME)
/* Set by the runtime when no logging or statistics need solve_linear_system. */
extern int omc_ls_inline;
#endif

/* solve_linear_system for a system of size 1. A torn system with a 1x1
 * Jacobian is solved here, x = x0 + r(x0)/(-J), as the runtime's LAPACK path
 * does; everything else, and a solve that fails, goes to solve_linear_system.
 */
static inline int solve_linear_system_small(DATA *data, threadData_t *threadData, int sysNumber, double *aux_x)
{
#if defined(OMC_RUST_SIMULATION_RUNTIME) && (!defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS > 0)
  LINEAR_SYSTEM_DATA *ls = &data->simulationInfo->linearSystemData[sysNumber];
  JACOBIAN *jac = ls->jacobian;
  SPARSE_PATTERN *sp = jac ? jac->sparsePattern : NULL;
  const int lsMethod = data->simulationInfo->lsMethod;
  if (omc_ls_inline && (lsMethod == LS_DEFAULT || lsMethod == LS_LAPACK) &&
      ls->method == 1 && ls->size == 1 && !ls->useSparseSolver && ls->jacobianIndex != -1 &&
      sp && sp->maxColors == 1 && sp->colorCols[0] == 1 && sp->leadindex[1] == 1 &&
      !jac->isRowEval && !(jac->isBidirectional && jac->adjointJacobian) && jac->evalColumn &&
      data->simulationInfo->currentContext != CONTEXT_SYM_JACOBIAN) {
    const int flag = 1;
    RESIDUAL_USERDATA user = {data, threadData, NULL};
    const int stage = threadData->currentErrorStage;
    const double x0 = aux_x[0];
    double r = 0.0, dx, J;
    data->simulationInfo->noThrowDivZero = 1;
    threadData->currentErrorStage = ERROR_NONLINEARSOLVER;
    if (jac->constantEqns) {
      jac->constantEqns(data, threadData, jac, ls->parentJacobian);
    }
    if (!OMC_ERROR_RAISED()) {
      jac->seedVars[0] = 1.0;
      jac->evalColumn(data, threadData, jac, ls->parentJacobian);
      jac->seedVars[0] = 0.0;
    }
    threadData->currentErrorStage = stage;
    J = jac->resultVars[0];
    if (OMC_ERROR_RAISED()) {
      OMC_ERROR_CLEAR();
    } else if (-J != 0.0) {
      ls->residualFunc(&user, &x0, &r, &flag);
      dx = r != 0.0 ? r / -J : r;
      aux_x[0] = x0 + dx;
      r = 0.0;
      ls->residualFunc(&user, aux_x, &r, &flag);
      r = sqrt(r * r);
      if (!(isnan(r) || r > 1e-4)) {
        ls->failed = 0;
        ls->solved = 1;
        ls->numberOfCall++;
        return 0;
      }
      aux_x[0] = x0;
    }
  }
#endif
  return solve_linear_system(data, threadData, sysNumber, aux_x);
}

#ifdef __cplusplus
}
#endif

#endif
