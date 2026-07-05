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

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "read_csv.h"
#include "read_matlab4.h"
#include "libcsv.h"
#include "omc_file.h"
#include "omc_numbers.h"
#include "omc_strdup.h"

struct cell_row_count
{
  int cell_count;
  int row_count;
};

struct csv_head
{
  char **variables;
  int size;
  int buffer_size;
  int found_row;
};

struct csv_body
{
  double *res;
  int size;
  int buffer_size;
  int found_first_row;
  int cur_size;
  int row_length;
  int error;
  /* String result support, only used when keepStrings is set. */
  int keepStrings;
  char **strres;     /* raw (un-escaped) text of every data cell */
  char *isStringCol; /* per-column flag, set when a non-numeric cell is seen */
};

/* In-place transpose of a w*h matrix of pointers, same layout/semantics as
   matrix_transpose (used to lay String cells out column-major like the data). */
static void transpose_str(char **m, int w, int h)
{
  int start;
  char *tmp;
  if (!m) {
    return;
  }
  for (start = 0; start <= w * h - 1; start++) {
    int next = start;
    int i = 0;
    do {  i++;
      next = (next % h) * w + next / h;
    } while (next > start);
    if (next < start || i == 1) continue;

    tmp = m[next = start];
    do {
      i = (next % h) * w + next / h;
      m[next] = (i == start) ? tmp : m[i];
      next = i;
    } while (next > start);
  }
}

static void do_nothing(void *data, size_t len, void *t)
{
}

static void found_first_row(int c, void *t)
{
  struct csv_head *head = (struct csv_head*) t;
  head->found_row++;
}

static void add_variable(void *data, size_t len, void *t)
{
  struct csv_head *head = (struct csv_head*) t;
  if (head->found_row) {
    return;
  }
  if (head->size+1 >= head->buffer_size) {
    head->buffer_size = head->buffer_size ? 2*head->buffer_size : 512;
    head->variables = (char**) realloc(head->variables, sizeof(char*)*head->buffer_size);
  }
  head->variables[head->size++] = omc_strdup(data ? (char*) data : "");
}

static void row_count(int c, void *t)
{
  struct cell_row_count *s =  (struct cell_row_count *) t;
  s->row_count++;
}

int read_csv_dataset_size(const char* filename)
{
  const int buf_size = 4096;
  char buf[4096];
  FILE *f;
  struct csv_parser p;
  struct cell_row_count count = {0};
  size_t offset=0;
  unsigned char delim = CSV_COMMA;
  f = omc_fopen(filename,"r");
  if (f == NULL) {
    return -1;
  }

  /* determine delim */
  omc_fread(buf, 1, 5, f, 0);
  if (0 == strcmp(buf, "\"sep="))
  {
    omc_fread(&delim, 1, 1, f, 0);
    offset = 8;
  }
  fseek(f, offset, SEEK_SET);

  csv_init(&p, CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL | CSV_EMPTY_IS_NULL, delim);
  csv_set_realloc_func(&p, realloc);
  csv_set_free_func(&p, free);
  do {
    size_t len = omc_fread(buf, 1, buf_size, f, 1);
    if (len != buf_size && !feof(f)) {
      csv_free(&p);
      fclose(f);
      return -1;
    }
    csv_parse(&p,buf,len,do_nothing,row_count,&count);
  } while (!feof(f));
  csv_fini(&p,do_nothing,row_count,&count);
  csv_free(&p);
  fclose(f);
  return count.row_count - 1; /* The header is excluded */
}

char** read_csv_variables(FILE *fin, int *length, unsigned char delim)
{
  const int buf_size = 4096;
  char buf[4096];
  char **res;
  struct csv_parser p;
  struct csv_head head = {0};
  csv_init(&p, CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL | CSV_EMPTY_IS_NULL, delim);
  csv_set_realloc_func(&p, realloc);
  csv_set_free_func(&p, free);
  do {
    size_t len = omc_fread(buf, 1, buf_size, fin, 1);
    if (len != buf_size && !feof(fin)) {
      csv_free(&p);
      return NULL;
    }
    csv_parse(&p,buf,len,add_variable,found_first_row,&head);
  } while (!head.found_row && !feof(fin));
  csv_free(&p);
  if (!head.found_row) {
    return NULL;
  }
  *length = head.size-1;
  return head.variables;
}

static void add_cell(void *data, size_t len, void *t)
{
  struct csv_body *body = (struct csv_body*) t;
  char *endptr = "";
  int idx;
  if (body->error) {
    return;
  }
  if (!body->found_first_row) {
    body->cur_size++;
    body->row_length++;
    return;
  }
  if (body->size+1 >= body->buffer_size) {
    body->buffer_size = body->res ? 2*body->buffer_size : body->row_length*1024; /* Guess it's 1024 time points; we could also take the size of the file or something, but this is cool too */
    body->buffer_size = body->buffer_size > 0 ? body->buffer_size : 1024;
    body->res = body->res ? (double*)realloc(body->res, sizeof(double)*body->buffer_size) : (double*) malloc(sizeof(double)*body->buffer_size);
    if (body->keepStrings) {
      body->strres = body->strres ? (char**)realloc(body->strres, sizeof(char*)*body->buffer_size) : (char**) malloc(sizeof(char*)*body->buffer_size);
    }
  }
  idx = body->size;
  /* libcsv has already un-escaped the cell (doubled quotes collapsed, quotes and
     embedded newlines removed), so store its content verbatim. */
  if (body->keepStrings) {
    body->strres[idx] = omc_strdup(data ? (char*) data : "");
  }
  if (data == NULL) {
    body->res[idx] = 0.0;
    body->size++;
    return;
  }
  body->res[idx] = om_strtod((const char*)data,&endptr);
  if (*endptr) {
    if (body->keepStrings) {
      /* A non-numeric cell (e.g. a String value): remember that this column is a
         String column and store NaN so numeric readers skip it. */
      if (body->isStringCol && body->row_length > 0) {
        body->isStringCol[idx % body->row_length] = 1;
      }
      body->res[idx] = NAN;
    } else {
      fprintf(stderr,"Found non-double data in csv result-file: %s\n", (char*) data);
      body->error = 1;
    }
  }
  body->size++;
}

static void add_row(int c, void *t)
{
  struct csv_body *body = (struct csv_body*) t;
  body->found_first_row++;
  if (body->cur_size != body->row_length) {
    fprintf(stderr,"Did not find time points for all variables for row: %d\n", body->found_first_row);
    body->error = 1;
    return;
  }
  /* The header row has just been counted, so row_length is now known: allocate
     the per-column String flags before the first data row is parsed. */
  if (body->keepStrings && body->found_first_row == 1 && !body->isStringCol && body->row_length > 0) {
    body->isStringCol = (char*) calloc(body->row_length, sizeof(char));
  }
}

double* read_csv_dataset_var(const char *filename, const char *var, int dimsize)
{
  const int buf_size = 4096;
  char buf[4096];
  char **res;
  struct csv_parser p;
  struct csv_body body = {0};
  FILE *fin = omc_fopen(filename, "r");
  size_t offset = 0;
  unsigned char delim = CSV_COMMA;
  if (!fin) {
    return NULL;
  }

  /* determine delim */
  omc_fread(buf, 1, 5, fin, 0);
  if (0 == strcmp(buf, "\"sep="))
  {
    omc_fread(&delim, 1, 1, fin, 0);
    offset = 8;
  }
  fseek(fin, offset, SEEK_SET);

  csv_init(&p, CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL | CSV_EMPTY_IS_NULL, delim);
  csv_set_realloc_func(&p, realloc);
  csv_set_free_func(&p, free);
  do {
    size_t len = omc_fread(buf, 1, buf_size, fin, 1);
    if (len != buf_size && !feof(fin)) {
      csv_free(&p);
      fclose(fin);
      return NULL;
    }
    csv_parse(&p,buf,len,add_cell,add_row,&body);
  } while (!body.error && !feof(fin));
  csv_fini(&p,add_cell,add_row,&body);
  csv_free(&p);
  fclose(fin);
  if (body.error) {
    return NULL;
  }
  return body.res;
}

static struct csv_data* read_csv_internal(const char *filename, int keepStrings)
{
  const int buf_size = 4096;
  char buf[4096];
  char **variables;
  int dummy;
  struct csv_parser p;
  struct csv_body body = {0};
  struct csv_data *res;
  size_t offset = 0;
  unsigned char delim = CSV_COMMA;
  size_t len;

  body.keepStrings = keepStrings;

  FILE *fin = omc_fopen(filename, "r");
  if (!fin) {
    return NULL;
  }

  /* determine delim */
  len = omc_fread(buf, 1, 5, fin, 0);
  // Terminate the string in the buffer to make sure strcmp works as expected.
  buf[len] = '\0';
  if (0 == strcmp(buf, "\"sep="))
  {
    omc_fread(&delim, 1, 1, fin, 0);
    offset = 8;
  }
  fseek(fin, offset, SEEK_SET);

  variables = read_csv_variables(fin, &dummy, delim);
  if (!variables) {
    fclose(fin);
    return NULL;
  }
  fseek(fin,offset,SEEK_SET);

  csv_init(&p, CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL | CSV_EMPTY_IS_NULL, delim);
  csv_set_realloc_func(&p, realloc);
  csv_set_free_func(&p, free);
  do {
    len = omc_fread(buf, 1, buf_size, fin, 1);
    if (len != buf_size && !feof(fin)) {
      csv_free(&p);
      fclose(fin);
      return NULL;
    }
    csv_parse(&p,buf,len,add_cell,add_row,&body);
  } while (!body.error && !feof(fin));
  csv_fini(&p,add_cell,add_row,&body);
  csv_free(&p);
  fclose(fin);
  if (body.error) {
    return NULL;
  }
  res = (struct csv_data*) malloc(sizeof(struct csv_data));
  if (!res) {
    return NULL;
  }
  res->variables = variables;
  res->data = body.res;
  res->numvars = body.row_length;
  res->numsteps = body.row_length ? body.size / body.row_length : 0;
  res->strdata = NULL;
  res->isStringVar = NULL;
  matrix_transpose(res->data,res->numvars,res->numsteps);
  if (keepStrings) {
    /* Free the String storage of the numeric columns to keep memory low, then
       lay out the String columns column-major like the data. */
    if (body.strres && body.isStringCol && res->numvars > 0) {
      int i;
      for (i = 0; i < body.size; i++) {
        if (!body.isStringCol[i % res->numvars]) {
          free(body.strres[i]);
          body.strres[i] = NULL;
        }
      }
    }
    transpose_str(body.strres, res->numvars, res->numsteps);
    res->strdata = body.strres;
    res->isStringVar = body.isStringCol;
  }
  /* printf("num vars %d in %s num steps %d\n", body.row_length, filename, res->numsteps); */
  return res;
}

struct csv_data* read_csv(const char *filename)
{
  return read_csv_internal(filename, 0);
}

struct csv_data* read_csv_all(const char *filename)
{
  return read_csv_internal(filename, 1);
}

double* read_csv_dataset(struct csv_data *data, const char *var)
{
  int i,found=-1;
  for (i=0; i<data->numvars; i++) {
    if (0==strcmp(data->variables[i],var)) {
      found=i;
      break;
    }
  }
  if (found == -1) {
    return NULL;
  }
  return data->data + found*data->numsteps;
}

char** read_csv_dataset_str(struct csv_data *data, const char *var)
{
  int i,found=-1;
  if (!data->strdata) {
    return NULL;
  }
  for (i=0; i<data->numvars; i++) {
    if (0==strcmp(data->variables[i],var)) {
      found=i;
      break;
    }
  }
  if (found == -1 || (data->isStringVar && !data->isStringVar[found])) {
    return NULL;
  }
  return data->strdata + found*data->numsteps;
}

void omc_free_csv_reader(struct csv_data *data)
{
  int i;
  for (i=0; i<data->numvars; i++) {
    free(data->variables[i]);
  }
  free(data->variables);
  free(data->data);
  if (data->strdata) {
    for (i=0; i<data->numvars*data->numsteps; i++) {
      free(data->strdata[i]);
    }
    free(data->strdata);
  }
  free(data->isStringVar);
  data->variables = 0;
  data->data = 0;
  data->strdata = 0;
  data->isStringVar = 0;
  free(data);
}
