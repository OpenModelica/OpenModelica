/*
// Copyright PELAB, Linkoping University
*/

#ifndef INTEGER_ARRAY_H_
#define INTEGER_ARRAY_H_

typedef int modelica_integer;

struct integer_array_s
{
  int ndims;
  int* dim_size;
  modelica_integer* data;
};

typedef struct integer_array_s integer_array_t;

#endif
