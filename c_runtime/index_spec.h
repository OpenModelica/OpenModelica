/*
// Copyright PELAB, Linkoping University
*/

#ifndef INDEX_SPEC_H_
#define INDEX_SPEC_H_

struct index_spec_s
{
  int ndims;
  int* dim_size;
  int** index;
};

typedef struct index_spec_s index_spec_t;

int index_spec_ok(index_spec_t* s);
void alloc_index_spec(index_spec_t* s);
void create_index_spec(index_spec_t* dest, int nridx, ...);
int* make_index_array(int nridx,...);
#endif
