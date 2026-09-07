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

/* The result writers of the Rust runtime (libomc_result: .mat, .arrow, .csv,
 * .plt) behind the simulation_result interface. Selected instead of the C
 * writers when OM_RUST_RESULT_WRITERS is defined. */

#ifndef _SIMULATION_RESULT_RUST_H
#define _SIMULATION_RESULT_RUST_H

#include "simulation_result.h"

#ifdef __cplusplus
extern "C" {
#endif

void rust_result_init(simulation_result *self, DATA *data, threadData_t *threadData);
void rust_result_emit(simulation_result *self, DATA *data, threadData_t *threadData);
void rust_result_writeParameterData(simulation_result *self, DATA *data, threadData_t *threadData);
void rust_result_free(simulation_result *self, DATA *data, threadData_t *threadData);

#ifdef __cplusplus
}
#endif

#endif
