#include "memory_pool.h"
#include <assert.h>
#include <stdio.h>

state current_state = {
  0,/*real buffer*/
  0,/*integer buffer*/
  0,/*string buffer*/
  0 /*boolean buffer*/
};

size_mem current_buffer_index = {
  0
};

state get_memory_state()
{
  return current_state;
}

void print_current_state()
{
  printf("=== Current state ===\n");
  printf("real index: %d\n",current_state.real_buffer_ptr);
  printf("integer index: %d\n",current_state.integer_buffer_ptr);
  printf("string index: %d\n",current_state.string_buffer_ptr);
  printf("boolean: %d\n",current_state.boolean_buffer_ptr);
}

void print_state(state s)
{
  printf("=== State ===\n");
  printf("real index: %d\n",s.real_buffer_ptr);
  printf("integer index: %d\n",s.integer_buffer_ptr);
  printf("string index: %d\n",s.string_buffer_ptr);
  printf("boolean: %d\n",s.boolean_buffer_ptr);
}

void restore_memory_state(state restore_state)
{
  current_state = restore_state;
}

void clear_current_state()
{
  current_state.real_buffer_ptr = 0;
  current_state.integer_buffer_ptr = 0;
  current_state.string_buffer_ptr = 0;
  current_state.boolean_buffer_ptr = 0;
}

/* allocates n reals in the real_buffer */
real* real_alloc(int n)
{
  index_t start;

  assert(n>=0);
  assert(current_state.real_buffer_ptr +n < NR_REAL_ELEMENTS);
  
  start = current_state.real_buffer_ptr;
  current_state.real_buffer_ptr += n;
  return real_buffer+start;
  /*return start;*/

}

/* allocates n integers in the integer_buffer */
integer* integer_alloc(int n)
{
  index_t start;

  assert(n>=0);
  assert(current_state.integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);
  
  start = current_state.integer_buffer_ptr;
  current_state.integer_buffer_ptr += n;

  return integer_buffer+start;
  /*  return start;*/

}

/* allocates n strings in the string_buffer */
string* string_alloc(int n)
{
  index_t start;

  assert(n>=0);
  assert(current_state.string_buffer_ptr +n < NR_STRING_ELEMENTS);
  
  start = current_state.string_buffer_ptr;
  current_state.string_buffer_ptr += n;

  return string_buffer+start;
  /*return start;*/

}

/* allocates n booleans in the boolean_buffer */
boolean* boolean_alloc(int n)
{
  index_t start;

  assert(n>=0);
  assert(current_state.boolean_buffer_ptr +n < NR_BOOLEAN_ELEMENTS);
  
  start = current_state.boolean_buffer_ptr;
  current_state.boolean_buffer_ptr += n;

  return boolean_buffer+start;
  /*  return start;*/

}

int* size_alloc(int n)
{
  index_t start;
  
  assert(n>=0);
  assert(n+current_buffer_index.size_buffer_ptr<NR_SIZE_ELEMENTS);
 
  start = current_buffer_index.size_buffer_ptr;
  current_buffer_index.size_buffer_ptr += n;
  return size_buffer+n;

  /*  return start;*/
}

index_t real_free(int n)
{
  assert(n>=0);
  assert(current_state.real_buffer_ptr-n>=0);
  
  current_state.real_buffer_ptr -= n;
  return current_state.real_buffer_ptr; 
}

index_t integer_free(int n)
{
  assert(n>=0);
  assert(current_state.integer_buffer_ptr-n>=0);
  
  current_state.integer_buffer_ptr -= n;
  return current_state.integer_buffer_ptr; 
}

index_t string_free(int n)
{
  assert(n>=0);
  assert(current_state.string_buffer_ptr-n>=0);
  
  current_state.string_buffer_ptr -= n;
  return current_state.string_buffer_ptr; 
}

index_t boolean_free(int n)
{
  assert(n>=0);
  assert(current_state.boolean_buffer_ptr-n>=0);
  
  current_state.boolean_buffer_ptr -= n;
  return current_state.boolean_buffer_ptr; 
}

index_t size_free(int n)
{
  assert(n>=0);
  assert(current_buffer_index.size_buffer_ptr-n>=0);
  
  current_buffer_index.size_buffer_ptr -= n;
  return current_buffer_index.size_buffer_ptr; 
}
