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
 * libomc_init: reads <prefix>_init.bin, the variables and default experiment
 * of a model, written by omc (Compiler/SimCode/SerializeInitBin.mo). The C
 * simulation runtime has its own reader, c/util/omc_init_bin.h.
 *
 * Format, version 1. All numbers are little-endian.
 *
 *   Header: "OMCINIT\0", u32 version, u32 number of sections, then per section
 *   {u32 id, u32 count, u64 offset, u64 size}. Each section starts at a
 *   multiple of 8. The record size of a section is size/count; a reader
 *   ignores fields after the ones it knows, so later versions can add fields.
 *
 *   STRINGS       NUL-terminated UTF-8 strings; offset 0 is "". A string field
 *                 is a u32 offset into this section.
 *   MODEL         one record: strings modelName, modelIdentifier, description,
 *                 guid, generationTool, generationDateAndTime, OPENMODELICAHOME;
 *                 i32 the counts in omc_init_bin_model, in that order.
 *   EXPERIMENT    one record: f64 startTime, stopTime, stepSize, tolerance;
 *                 strings solver, outputFormat, variableFilter; u32 0.
 *   ENUMERATIONS  {string name, u32 numLiterals, u32 firstLiteral}: the literal
 *                 names are string offsets in INTEGERS, values 1..numLiterals.
 *   VARIABLES     the fields of omc_init_bin_variable in that order: 7 strings,
 *                 7 i32, 6 u8, u16 flags, u32 numDimensions, u32 firstDimension,
 *                 {u32 count, u32 index} for start, min, max and nominal.
 *                 Ordered by class type, as the runtime arrays.
 *   REALS         f64 values: start, min, max and nominal of Real variables.
 *   INTEGERS      i64 values: of Integer, Boolean (0, 1) and enumeration
 *                 variables, string offsets of String variables, dimensions
 *                 (two per dimension: size or -1, value reference of the
 *                 Integer parameter giving the size or -1), enumeration literals.
 *
 * An attribute with count 0 is not given. A start value with count 1 for an
 * array variable is the value of all elements.
 */

#ifndef OMC_INIT_FILE_H
#define OMC_INIT_FILE_H

#ifdef __cplusplus
extern "C" {
#endif

/* The file as text, one line per variable; NULL with the reason in *error
 * (if error is not NULL) on failure. Free both with omc_init_free_string. */
char *omc_init_file_text(const char *path, char **error);
void omc_init_free_string(char *s);

#ifdef __cplusplus
}
#endif

#endif
