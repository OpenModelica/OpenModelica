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

/*
 * File: simulation_input.h
 *
 *
 *
 */

#ifndef _SIMULATION_INPUT_H
#define _SIMULATION_INPUT_H

#include "simulation_runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Reads <prefix>_init.bin, see util/omc_init_bin.h. An FMU ignores the
 * simulation flags for the experiment and -override. */
void read_input(MODEL_DATA* modelData,
                SIMULATION_INFO* simulationInfo,
                modelica_boolean isFMU,
                threadData_t* threadData);
/* The default experiment, OPENMODELICAHOME and the start values again, for
 * model data that read_input filled before. */
void read_input_defaults(MODEL_DATA* modelData,
                         SIMULATION_INFO* simulationInfo,
                         modelica_boolean isFMU,
                         threadData_t* threadData);
/* -listVariables: JSON on stdout. */
void list_variables(MODEL_DATA* modelData, threadData_t* threadData);
void parseVariableStr(char* variableStr);
int isQuantityOverridden(const char *name);

#ifdef __cplusplus
}
#endif


#endif
