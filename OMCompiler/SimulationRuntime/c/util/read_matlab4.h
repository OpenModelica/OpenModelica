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

#ifndef OMC_READ_MATLAB4_H
#define OMC_READ_MATLAB4_H

#include <stdio.h>
#include <stdint.h>
#include "omc_msvc.h"

/**
 * @brief Information about a single variable or parameter contained in a .mat file.
 *
 * This structure describes one entry from the MATLAB v4 variable metadata
 * tables (`name`, `description`, `dataInfo`). It carries the human-readable
 * name and description, a flag indicating whether the entry is a parameter
 * (stored in `data_1`) or a simulation variable (stored in `data_2`), and
 * the index used to find the actual numeric values in the corresponding
 * data block.
 */
typedef struct {
  /** Human-readable variable name (null-terminated, malloc'd) */
  char *name,
       *descr;
  /** Non-zero if this entry is a parameter (stored in data_1). */
  int isParam;
  /** Non-zero if this entry is a time-varying String variable (#15969); its
      value is stored in the stringData matrix, and `index` is the 1-based string
      signal index. */
  int isString;
  /** 1-based index into the appropriate data block; negative values indicate a
      negative alias (the file also contains negative alias columns). */
  int index;
} ModelicaMatVariable_t;

/**
 * @brief Runtime representation of an opened MATLAB v4 file for OpenModelica.
 *
 * Instances of this structure are initialized by `omc_new_matlab4_reader`
 * and used by the various accessor functions to read variable metadata and
 * time series data. Fields that own heap memory (e.g. `fileName`,
 * `allInfo`, `params`, `vars`) must be freed by calling
 * `omc_free_matlab4_reader`.
 */
typedef struct {
  /** Open FILE pointer to the .mat file (binary mode) */
  FILE *file;
  /** Path of the opened file (malloc'd) */
  char *fileName;
  /** Number of entries in `allInfo` */
  uint32_t nall;
  /** Sorted array of variable/parameter descriptors (length nall) */
  ModelicaMatVariable_t *allInfo;
  /** Number of parameters present (length of `params`) */
  uint32_t nparam;
  /** Start and stop times for the contained time series (NaN if unknown) */
  double startTime, stopTime;
  /** Parameter values stored in `data_1` (length nparam) */
  double *params;
  /** Number of variables (columns) in the data block and number of rows */
  uint32_t nvar,nrows;
  /** File offset (bytes) where the `data_2` block begins (for lazy reads) */
  size_t var_offset;
  /** Non-zero if all variables have been read into memory */
  int readAll;
  /** Cached variable time-series pointers (length 2*nvar to include negative aliases) */
  double **vars;
  /** 1 if stored in double precision, 0 if stored as float */
  char doublePrecision;
  /** #15969: string result support. stringData is a column-major char matrix of
      stringMaxLen rows and (nStringSignals * nStringRows) columns; the string
      for signal s (1-based) at time row r is stringData + (r*nStringSignals +
      (s-1)) * stringMaxLen. */
  char *stringData;
  uint32_t stringMaxLen;
  uint32_t nStringSignals;
  uint32_t nStringRows;
} ModelicaMatReader;


#ifdef __cplusplus
extern "C" {
#endif

const char* omc_new_matlab4_reader(const char *filename, ModelicaMatReader *reader);

void omc_free_matlab4_reader(ModelicaMatReader *reader);

ModelicaMatVariable_t *omc_matlab4_find_var(ModelicaMatReader *reader, const char *varName);

double* omc_matlab4_read_vals(ModelicaMatReader *reader, int varIndex);

int omc_matlab4_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t *var, double time);

int omc_matlab4_read_vars_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t **var, int N, double time);

/* #15969: read the value of a time-varying String variable at a given time.
   Returns a pointer into the reader's stringData (valid until the reader is
   freed), or NULL if `var` is not a string variable / has no data. */
const char* omc_matlab4_read_string_val(ModelicaMatReader *reader, ModelicaMatVariable_t *var, double time);

void omc_matlab4_print_all_vars(FILE *stream, ModelicaMatReader *reader);

double omc_matlab4_startTime(ModelicaMatReader *reader);
double omc_matlab4_stopTime(ModelicaMatReader *reader);

void matrix_transpose(double *m, int w, int h);
void matrix_transpose_uint32(uint32_t *m, int w, int h);
int omc_matlab4_read_all_vals(ModelicaMatReader *reader);

char* openmodelicaStyleVariableName(const char *varName);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif
