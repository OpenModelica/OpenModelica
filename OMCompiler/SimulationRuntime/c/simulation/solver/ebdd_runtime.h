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

#ifdef __cplusplus
}
#endif

#endif /* EBDD_RUNTIME_H */
