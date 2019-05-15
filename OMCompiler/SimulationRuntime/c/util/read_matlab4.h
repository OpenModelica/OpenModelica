/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#ifndef OMC_READ_MATLAB4_H
#define OMC_READ_MATLAB4_H

#include <stdio.h>
#include <stdint.h>
#include "omc_msvc.h"

typedef struct {
  char *name,*descr;
  int isParam;
  /* Parameters are stored in data_1, variables in data_2; parameters are defined at any time, variables only within the simulation start/stop interval */
  int index;
} ModelicaMatVariable_t;

typedef struct {
  FILE *file;
  char *fileName;
  uint32_t nall;
  ModelicaMatVariable_t *allInfo; /* Sorted array of variables and their associated information */
  uint32_t nparam;
  double startTime, stopTime;
  double *params; /* This has size nparam */
  uint32_t nvar,nrows;
  size_t var_offset; /* This is the offset in the file */
  int readAll; /* Read all variables already */
  double **vars;
  char doublePrecision; /* data_1 and data_2 in double ore single precision */
} ModelicaMatReader;

/* Returns 0 on success; the error message on error.
 * The internal data is free'd by omc_free_matlab4_reader.
 * The data persists until free'd, and is safe to use in your own data-structures
 */
#ifdef __cplusplus
extern "C" {
#endif
const char* omc_new_matlab4_reader(const char *filename, ModelicaMatReader *reader);

void omc_free_matlab4_reader(ModelicaMatReader *reader);

/* Returns a variable or NULL */
ModelicaMatVariable_t *omc_matlab4_find_var(ModelicaMatReader *reader, const char *varName);

/* Writes the number of values in the returned array if nvals is non-NULL
 * Returns all values that the given variable may have.
 * Note: This function is _not_ defined for parameters; check var->isParam and then send the index
 * No bounds checking is performed. The returned data persists until the reader is closed.
 */
double* omc_matlab4_read_vals(ModelicaMatReader *reader, int varIndex);

/* Returns 0 on success */
int omc_matlab4_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t *var, double time);

/* Reads multiple variables values in single time
 * Returns 0 on success */
int omc_matlab4_read_vars_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t **var, int N, double time);

/* For debugging */
void omc_matlab4_print_all_vars(FILE *stream, ModelicaMatReader *reader);

double omc_matlab4_startTime(ModelicaMatReader *reader);
double omc_matlab4_stopTime(ModelicaMatReader *reader);

void matrix_transpose(double *m, int w, int h);
void matrix_transpose_uint32(uint32_t *m, int w, int h);
int omc_matlab4_read_all_vals(ModelicaMatReader *reader);

/* Fix the placement of a.der(b) -> der(a.b) */
char* openmodelicaStyleVariableName(const char *varName);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif
