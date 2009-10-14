/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef READ_WRITE_H_
#define READ_WRITE_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

typedef struct type_desc_s type_description;

#include "modelica.h"

enum type_desc_e {
  TYPE_DESC_NONE,
  TYPE_DESC_REAL,
  TYPE_DESC_REAL_ARRAY,
  TYPE_DESC_INT,
  TYPE_DESC_INT_ARRAY,
  TYPE_DESC_BOOL,
  TYPE_DESC_BOOL_ARRAY,
  TYPE_DESC_STRING,
  TYPE_DESC_STRING_ARRAY,
  TYPE_DESC_TUPLE,
  TYPE_DESC_COMPLEX,
  TYPE_DESC_RECORD,
  /* function pointer - added by stefan */
  TYPE_DESC_FUNCTION,
  TYPE_DESC_MMC,
  TYPE_DESC_NORETCALL
};

struct type_desc_s {
  enum type_desc_e type;
  int retval : 1;
  union {
    modelica_real real;
    real_array_t real_array;
    modelica_integer integer;
    integer_array_t int_array;
    modelica_boolean boolean;
    boolean_array_t bool_array;
    modelica_string_t string;
    string_array_t string_array;
    struct {
      size_t elements;
      struct type_desc_s *element;
    } tuple;
    modelica_complex complex;
    struct {
      const char *record_name;
      size_t elements;
      char **name;
      struct type_desc_s *element;
    } record;
    /* function pointer - stefan */
    modelica_fnptr function;
    void* mmc;
  } data;
};

void init_type_description(type_description *);
void free_type_description(type_description *);

int read_modelica_real(type_description **, modelica_real *);
int read_real_array(type_description **, real_array_t *);
void write_modelica_real(type_description *, modelica_real *);
void write_real_array(type_description *, real_array_t *);

int read_modelica_integer(type_description **, modelica_integer *);
int read_integer_array(type_description **, integer_array_t *);
void write_modelica_integer(type_description *, modelica_integer *);
void write_integer_array(type_description *, integer_array_t *);

int read_modelica_boolean(type_description **, modelica_boolean *);
int read_boolean_array(type_description **, boolean_array_t *);
void write_modelica_boolean(type_description *, modelica_boolean *);
void write_boolean_array(type_description *, boolean_array_t *);

int read_modelica_string(type_description **, modelica_string_t *);
int read_string_array(type_description **, string_array_t *);
void write_modelica_string(type_description *, modelica_string_t *);
void write_string_array(type_description *, string_array_t *);

int read_modelica_complex(type_description **, modelica_complex *);
void write_modelica_complex(type_description *, modelica_complex *);

/* function pointer functions - added by stefan */
int read_modelica_fnptr(type_description **, modelica_fnptr *);
void write_modelica_fnptr(type_description *, modelica_fnptr *);

int read_metamodelica_type(type_description **, metamodelica_type*);
void write_metamodelica_type(type_description *, metamodelica_type*);

int read_modelica_record(type_description **, ...);
void write_modelica_record(type_description *, void *, ...);

void write_noretcall(type_description *);

type_description *add_modelica_record_member(type_description *desc,
                                             const char *name, size_t nlen);

type_description *add_tuple_member(type_description *desc);

char *my_strdup(const char *s);

#endif
