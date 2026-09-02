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

#ifndef OMC_READ_CSV_H
#define OMC_READ_CSV_H

struct csv_data {
  char **variables;
  double *data;
  int numvars;
  int numsteps;
  /* String result support. strdata holds the (already un-escaped) raw text of
     the cells of the String columns, laid out like data (numvars*numsteps,
     column-major after read_csv_all); it is NULL for numeric-only columns and
     for readers that did not request strings. isStringVar[i] is non-zero if
     variable i is a String column. Both are only populated by read_csv_all. */
  char **strdata;
  char *isStringVar;
};

#ifdef __cplusplus
extern "C" {
#endif

int read_csv_dataset_size(const char* filename);

char** read_csv_variables(FILE *fin, int *length, unsigned char delim);

/* Reads a CSV result file. Non-numeric cells are an error (used e.g. for
   numeric external input files). */
struct csv_data* read_csv(const char *filename);
/* Like read_csv, but tolerates String columns: non-numeric cells are kept as
   strings (see strdata / isStringVar) and stored as NaN in the numeric matrix,
   so numeric variables stay readable even when the file has String columns. */
struct csv_data* read_csv_all(const char *filename);
double* read_csv_dataset(struct csv_data *data, const char *var);
/* Returns the numsteps un-escaped String values of a String variable, or NULL
   if the variable is not a String column. Only valid after read_csv_all. */
char** read_csv_dataset_str(struct csv_data *data, const char *var);
void omc_free_csv_reader(struct csv_data *data);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif
