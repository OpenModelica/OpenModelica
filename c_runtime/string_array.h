#ifndef STRING_ARRAY_H_
#define STRING_ARRAY_H_

typedef char* modelica_string;

struct string_array_s
{
  int ndims;
  int* dim_size;
  modelica_string* data;
};

typedef struct string_array_s string_array_t;

#endif
