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
} ModelicaMatReader;


/* The Qt GUI clients call these directly, so on MSVC they must be exported from
 * OpenModelicaCompiler.dll and imported (IMPORT_INTO) on the consumer side. */
#ifndef DLLDirection
#include "../openmodelica.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

DLLDirection const char* omc_new_matlab4_reader(const char *filename, ModelicaMatReader *reader);

DLLDirection void omc_free_matlab4_reader(ModelicaMatReader *reader);

DLLDirection ModelicaMatVariable_t *omc_matlab4_find_var(ModelicaMatReader *reader, const char *varName);

DLLDirection double* omc_matlab4_read_vals(ModelicaMatReader *reader, int varIndex);

DLLDirection int omc_matlab4_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t *var, double time);

DLLDirection int omc_matlab4_read_vars_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t **var, int N, double time);

DLLDirection void omc_matlab4_print_all_vars(FILE *stream, ModelicaMatReader *reader);

DLLDirection double omc_matlab4_startTime(ModelicaMatReader *reader);
DLLDirection double omc_matlab4_stopTime(ModelicaMatReader *reader);

DLLDirection void matrix_transpose(double *m, int w, int h);
DLLDirection void matrix_transpose_uint32(uint32_t *m, int w, int h);
DLLDirection int omc_matlab4_read_all_vals(ModelicaMatReader *reader);

DLLDirection char* openmodelicaStyleVariableName(const char *varName);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif
