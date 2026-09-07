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

/*! \file nonlinearSolverIpopt.h
 *
 * Solve a nonlinear system g(z) = 0 subject to the box constraints
 * z_min <= z <= z_max with the IPOPT interior-point solver, treating the
 * residuals as equality constraints and a constant (zero) objective. Used as a
 * robust fallback for the standard nonlinear solvers (ticket #14104).
 */

#ifndef _NONLINEARSOLVERIPOPT_H_
#define _NONLINEARSOLVERIPOPT_H_

#include "../../simulation_data.h"
#include "../../util/simulation_options.h"

#ifdef __cplusplus
extern "C" {
#endif

NLS_SOLVER_STATUS solveNlsIpopt(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nlsData);

#ifdef __cplusplus
}
#endif

#endif /* _NONLINEARSOLVERIPOPT_H_ */
