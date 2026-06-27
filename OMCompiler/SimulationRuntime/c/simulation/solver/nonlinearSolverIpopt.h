/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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
