/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "read_csv.h"
#include <gc.h>
#include "libcsv.h"

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
};

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
    head->variables = GC_realloc(head->variables, sizeof(char*)*head->buffer_size);
  }
  head->variables[head->size++] = data ? GC_strdup(data) : data;
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
  f = fopen(filename,"r");
  if (f == NULL) {
    return -1;
  }
  csv_init(&p, CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL | CSV_EMPTY_IS_NULL);
  csv_set_realloc_func(&p, GC_realloc);
  csv_set_free_func(&p, GC_free);
  do {
    size_t len = fread(buf, 1, buf_size, f);
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

char** read_csv_variables(FILE *fin, int *length)
{
  const int buf_size = 4096;
  char buf[4096];
  char **res;
  struct csv_parser p;
  struct csv_head head = {0};
  fseek(fin,0,SEEK_SET);
  csv_init(&p, CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL | CSV_EMPTY_IS_NULL);
  csv_set_realloc_func(&p, GC_realloc);
  csv_set_free_func(&p, GC_free);
  do {
    size_t len = fread(buf, 1, buf_size, fin);
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
  char *endptr;
  if (!body->found_first_row) {
    body->cur_size++;
    body->row_length++;
    return;
  }
  if (body->size+1 >= body->buffer_size) {
    body->buffer_size = body->buffer_size ? 2*body->buffer_size : body->row_length*1024; /* Guess it's 1024 time points; we could also take the size of the file or something, but this is cool too */
    body->res = body->res ? (double*)GC_realloc(body->res, sizeof(double)*body->buffer_size) : (double*) GC_malloc_atomic(sizeof(double)*body->buffer_size);
  }
  body->res[body->size++] = strtod((const char*)data,&endptr);
  if (*endptr) {
    printf("Found non-double data in csv result-file: %s\n", (char*) data);
    body->error = 1;
  }
}

static void add_row(int c, void *t)
{
  struct csv_body *body = (struct csv_body*) t;
  body->found_first_row++;
  if (body->cur_size != body->row_length) {
    printf("Did not find time points for all variables for row: %d\n", body->found_first_row);
    body->error = 1;
    return;
  }
}

double* read_csv_dataset(const char *filename, const char *var, int dimsize)
{
  const int buf_size = 4096;
  char buf[4096];
  char **res;
  struct csv_parser p;
  struct csv_body body = {0};
  FILE *fin = fopen(filename, "r");
  if (!fin) {
    return NULL;
  }
  csv_init(&p, CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL | CSV_EMPTY_IS_NULL);
  csv_set_realloc_func(&p, GC_realloc);
  csv_set_free_func(&p, GC_free);
  do {
    size_t len = fread(buf, 1, buf_size, fin);
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
  if (!body.error) {
    return NULL;
  }
  return body.res;
}
