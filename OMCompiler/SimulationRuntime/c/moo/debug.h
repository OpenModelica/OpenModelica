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

#ifndef MOO_OM_PRINTS_H
#define MOO_OM_PRINTS_H

#include "simulation_data.h"
#include "simulation/solver/model_help.h"

#include <base/nlp_structs.h>

namespace OpenModelica {

void print_real_var_names(DATA* data);
void print_parameters(DATA* data);
void print_real_var_names_values(DATA* data);
void print_jacobian_sparsity(const JACOBIAN* jac, bool print_pattern, const char* name);
void print_bounds_fixed_vector(FixedVector<Bounds>& vec);
void disable_omc_logs();

} // namespace OpenModelica

#endif // MOO_OM_PRINTS_H