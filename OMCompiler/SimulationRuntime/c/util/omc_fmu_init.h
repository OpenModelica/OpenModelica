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
 * resources/<prefix>_init.bin of a C FMU 2.0 or 3.0: the default experiment
 * and the info and attributes of the variables, written by omc
 * (Compiler/SimCode/SerializeFmuInit.mo). FMI 1.0 compiles the same data as
 * <prefix>_init_fmu.c instead.
 *
 * Format version 1, little-endian, read front to back:
 *
 *   Header: "OMCFMUI\0", u32 version, u32 number of variables of
 *   realVarsData, realParameterData, integerVarsData, integerParameterData,
 *   booleanVarsData, booleanParameterData, stringVarsData and
 *   stringParameterData, f64 startTime, stopTime, stepSize, tolerance, string
 *   solver, varint number of file names, the file names.
 *
 *   Then one entry per variable, in the order of the counts and of the
 *   MODEL_DATA arrays: u8 flags (1 readonly, 2 fixed, 4 useNominal, 8 has
 *   dimensions, 16 has start, 32 min, 64 max, 128 nominal), string name,
 *   varint file name index, int lineStart, colStart, lineEnd, colEnd; if it
 *   has dimensions: varint n, n ints; for each of start, min, max and nominal
 *   it has: varint n and n values. A value is an f64 for a Real, an int for an
 *   Integer or enumeration, a u8 for a Boolean and a string for a String. One
 *   value is the value of all elements of an array variable; a missing
 *   attribute has its default value. The value reference (VAR_INFO.id) of
 *   variable k is 1000 + k.
 *
 *   varint: LEB128. int: bit 0 of the first byte is the sign, its bits 1-6 the
 *   low bits of n (of -n-1 if n < 0), bit 7 that a varint with the rest
 *   follows. string: varint length, then the UTF-8 bytes.
 */

#ifndef OMC_FMU_INIT_H
#define OMC_FMU_INIT_H

#include "../simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct OMC_FMU_INIT OMC_FMU_INIT;

/* Opens <resourcesDir>/<modelFilePrefix>_init.bin and checks all of it against
 * the sizes in modelData. Never NULL; omc_fmu_init_error says if it failed. */
OMC_FMU_INIT* omc_fmu_init_load(const MODEL_DATA *modelData);
const char* omc_fmu_init_error(const OMC_FMU_INIT *init);
void omc_fmu_init_free(OMC_FMU_INIT *init);

/* What the generated read_simulation_info set. */
void omc_fmu_init_experiment(const OMC_FMU_INIT *init, SIMULATION_INFO *simulationInfo);
/* With startOnly, the start attributes (the generated setDefaultStartValues),
 * else also the info, dimensions and other attributes (read_input_fmu). Each
 * call reads the variables once from the file. */
void omc_fmu_init_variables(OMC_FMU_INIT *init, MODEL_DATA *modelData, int startOnly);

#ifdef __cplusplus
}
#endif

#endif
