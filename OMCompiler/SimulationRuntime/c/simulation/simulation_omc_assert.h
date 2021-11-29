/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#ifndef OMC_SIMULATION_OMC_ASSERT_H
#define OMC_SIMULATION_OMC_ASSERT_H

#include "../util/omc_error.h"

DLLExport extern void (*omc_assert_withEquationIndexes)(threadData_t*, FILE_INFO info, const int *indexes, const char *msg, ...)  __attribute__ ((noreturn));

DLLExport extern void (*omc_assert_warning_withEquationIndexes)(FILE_INFO info, const int *indexes, const char *msg, ...);



void omc_assert_simulation_withEquationIndexes(threadData_t *threadData, FILE_INFO info, const int *indexes, const char *msg, ...) __attribute__ ((noreturn));

void omc_assert_warning_simulation_withEquationIndexes(FILE_INFO info, const int *indexes, const char *msg, ...);

void omc_assert_simulation(threadData_t *threadData, FILE_INFO info, const char *msg, ...) __attribute__ ((noreturn));
void omc_terminate_simulation(FILE_INFO info, const char *msg, ...);
void omc_throw_simulation(threadData_t* threadData) __attribute__ ((noreturn));
void omc_assert_warning_simulation(FILE_INFO info, const char *msg, ...);

#endif // Header
