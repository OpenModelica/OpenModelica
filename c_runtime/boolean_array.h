/*
// Copyright PELAB, Linkoping University
*/

#ifndef BOOLEAN_ARRAY_H_
#define BOOLEAN_ARRAT_H_

typedef char modelica_boolean;

struct boolean_array_s
{
  int ndims;
  int* dim_size;
  modelica_boolean* data;
};

typedef struct boolean_array_s boolean_array_t;

#endif
