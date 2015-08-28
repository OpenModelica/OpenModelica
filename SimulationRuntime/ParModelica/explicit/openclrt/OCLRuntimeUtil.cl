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


/*

 This file contains functions and objects used at runtime
 by OpenCL code. This file is included in every OpenCL
 computation from modelica. It provides utilities when running
 computations on GPUs and also on CPUs in OpenCL mode.

 It is the OpenCL counterpart of the C runtime for
 normal modelica execution.

 Mahder.Gebremedhin@liu.se  2012-03-31

*/


#ifdef cl_amd_printf
  #pragma OPENCL EXTENSION cl_amd_printf : enable
  #define PRINTF_AVAILABLE
#endif

#ifdef cl_intel_printf
  #pragma OPENCL EXTENSION cl_intel_printf : enable
  #define PRINTF_AVAILABLE
#endif

#ifdef PRINTF_AVAILABLE
  #define omc_assert(td,i,s) (printf("Assertion: %s, Line %d, info %d\n", s, __LINE__, i))
  #define omc_assert_withEquationIndexes(td,i,idx,s) (printf("Assertion: %s, Line %d, info %d\n", s, __LINE__, i))
  #define throwStreamPrint(td,str,exp) (printf("Assertion: %s\n, expression %s, Line %d\n", str, exp, __LINE__))
  #define printline() printf("At line %d\n", __LINE__)
#else
  #define omc_assert(td,i,s)
  #define omc_assert_withEquationIndexes(td,i,idx,s)
  #define throwStreamPrint(td,str,exp)
  #define printline()
#endif

#ifdef cl_khr_fp64
  #pragma OPENCL EXTENSION cl_khr_fp64 : enable
  #define DOUBLE_PREC_AVAILABLE
#endif

#ifdef cl_amd_fp64
  #pragma OPENCL EXTENSION cl_amd_fp64 : enable
  #define DOUBLE_PREC_AVAILABLE
#endif


#define FILE_INFO modelica_integer
#define threadData_t integer
#define threadData NULL
#define omc_dummyFileInfo __LINE__

#define sin(v,m) (sin(v))
#define cos(v,m) (cos(v))

#ifdef DOUBLE_PREC_AVAILABLE
typedef long  modelica_integer;
typedef double modelica_real;
#else
typedef float modelica_real;
typedef int  modelica_integer;
#endif

typedef bool modelica_boolean;
typedef modelica_integer _index_t;


#define state modelica_boolean

modelica_boolean get_memory_state() {return true;}
void restore_memory_state(modelica_boolean in_state) {}


struct gr_array
{
    int ndims;
    __global modelica_integer* dim_size;
    __global modelica_real* data;
};

struct gi_array
{
    int ndims;
    __global modelica_integer* dim_size;
    __global modelica_integer* data;
};
typedef struct gr_array real_array;
typedef struct gi_array integer_array;

struct lr_array
{
    int ndims;
    local modelica_integer* dim_size;
    local modelica_real* data;
};

struct li_array
{
    int ndims;
    local modelica_integer* dim_size;
    local modelica_integer* data;
};
typedef struct lr_array local_real_array;
typedef struct li_array local_integer_array;


// ParModelica versions of OpenCL thread managment functions.
// They start counting from 0. Parmodelica/Modelica starts from 1.
modelica_integer  oclGetGlobalId(modelica_integer dim) {
    return get_global_id(dim - 1) + 1;
}

modelica_integer  oclGetLocalId(modelica_integer dim) {
    return get_local_id(dim - 1) + 1;
}

modelica_integer  oclGetLocalSize(modelica_integer dim) {
    return get_local_size(dim - 1);
}

modelica_integer  oclGetGlobalSize(modelica_integer dim) {
    return get_global_size(dim - 1);
}

modelica_integer  oclGetGroupId(modelica_integer dim) {
    return get_group_id(dim - 1) + 1;
}

modelica_integer  oclGetNumGroups(modelica_integer dim) {
    return get_num_groups(dim - 1);
}

#define oclGlobalBarrier() barrier(CLK_GLOBAL_MEM_FENCE)
#define oclLocalBarrier() barrier(CLK_LOCAL_MEM_FENCE)



inline int in_range_integer(modelica_integer i,
         modelica_integer start,
         modelica_integer stop)
{
  if (start <= stop) {
      if ((i >= start) && (i <= stop)) {
          return 1;
      }
  } else {
      if ((i >= stop) && (i <= start)) {
          return 1;
      }
  }
  return 0;
}

inline int in_range_real(modelica_real i,
      modelica_real start,
      modelica_real stop)
{
  if (start <= stop) {
      if ((i >= start) && (i <= stop)) {
          return 1;
      }
  } else {
      if ((i >= stop) && (i <= start)) {
          return 1;
      }
  }
  return 0;
}


size_t integer_array_nr_of_elements(integer_array *a)
{
    int i;
    size_t nr_of_elements = 1;
    for (i = 0; i < a->ndims; ++i) {
       nr_of_elements *= a->dim_size[i];
    }
    return nr_of_elements;
}

size_t real_array_nr_of_elements(real_array *a)
{
    int i;
    size_t nr_of_elements = 1;
    for (i = 0; i < a->ndims; ++i) {
       nr_of_elements *= a->dim_size[i];
    }
    return nr_of_elements;
}

void copy_integer_array_data(integer_array *source, integer_array *dest)
{
    size_t i, nr_of_elements;


    nr_of_elements = integer_array_nr_of_elements(source);

    for (i = 0; i < nr_of_elements; ++i) {
        ((__global modelica_integer *) dest->data)[i] = ((__global modelica_integer *) source->data)[i];
    }
}

void copy_real_array_data(real_array *source, real_array *dest)
{
    size_t i, nr_of_elements;


    nr_of_elements = real_array_nr_of_elements(source);

    for (i = 0; i < nr_of_elements; ++i) {
        ((__global modelica_real *) dest->data)[i] = ((__global modelica_real *) source->data)[i];
    }
}



#define integer_array_element_addr_c99_1(L, d, i) (((L)->data) + i - 1)
#define integer_array_element_addr_c99_2(L, d, i, j) ((((L)->data)) + (i - 1)*((L)->dim_size[1]) + (j - 1))

#define real_array_element_addr_c99_1(L, d, i) (((L)->data) + i - 1)
#define real_array_element_addr_c99_2(L, d, i, j) ((((L)->data)) + (i - 1)*((L)->dim_size[1]) + (j - 1))



// typedef modelica_real cos_rettype;
// typedef modelica_real cosh_rettype;
// typedef modelica_real acos_rettype;
// typedef modelica_real sin_rettype;
// typedef modelica_real sinh_rettype;
// typedef modelica_real asin_rettype;
// typedef modelica_real log_rettype;
// typedef modelica_real log10_rettype;
// typedef modelica_real tan_rettype;
// typedef modelica_real tanh_rettype;
// typedef modelica_real atan_rettype;
// typedef modelica_real exp_rettype;
// typedef modelica_real sqrt_rettype;
// typedef modelica_real atan2_rettype;
// typedef modelica_real div_rettype;
// typedef modelica_real mod_rettype;


// ///////////////////////////////////////////////////////////
// //memory_pool

// #define NR_REAL_ELEMENTS    1024
// #define NR_INTEGER_ELEMENTS 1024
// #define NR_BOOLEAN_ELEMENTS 1
// #define NR_SIZE_ELEMENTS    100

// #define PRECENTAGE_REAL_BUFFER       40
// #define PRECENTAGE_INTEGER_BUFFER     40
// #define PRECENTAGE_BOOLEAN_BUFFER    15
// #define PRECENTAGE_SIZE_BUFFER        5


// struct gr_array
// {
    // int ndims;
    // __global modelica_integer* dim_size;
    // __global modelica_real* data;
// };

// struct gi_array
// {
    // int ndims;
    // __global modelica_integer* dim_size;
    // __global modelica_integer* data;
// };
// typedef struct gr_array real_array;
// typedef struct gi_array integer_array;

// struct lr_array
// {
    // int ndims;
    // __local modelica_integer* dim_size;
    // __local modelica_real* data;
// };

// struct li_array
// {
    // int ndims;
    // __local modelica_integer* dim_size;
    // __local modelica_integer* data;
// };
// typedef __local struct lr_array local_real_array;
// typedef __local struct li_array local_integer_array;



// // HELL starts here. Enjoy!

// struct local_state_s {
  // _index_t real_count;
  // _index_t integer_count;
  // _index_t boolean_count;
  // _index_t size_count;
  // __local modelica_real* local_real_buffer_ptr;
  // __local modelica_integer* local_integer_buffer_ptr;
  // __local modelica_boolean* local_boolean_buffer_ptr;
  // __local modelica_integer* local_size_buffer_ptr;
// };
// typedef __local struct local_state_s local_state;

// struct global_state_s {
  // __global modelica_real* global_real_buffer_ptr;
  // __global modelica_integer* global_integer_buffer_ptr;
  // __global modelica_boolean* global_boolean_buffer_ptr;
  // __global modelica_integer* global_size_buffer_ptr;
// };
// typedef struct global_state_s global_state;


// struct state_s{
  // global_state saved_global_state;
  // local_state saved_local_state;
// };
// typedef struct state_s state;

// struct buffer_s{
  // __global modelica_real* global_real_buffer;
  // __global modelica_integer* global_integer_buffer;
  // __global modelica_boolean* global_boolean_buffer;
  // __global modelica_integer* global_size_buffer;
  // __local modelica_real* local_real_buffer;
  // __local modelica_integer* local_integer_buffer;
  // __local modelica_boolean* local_boolean_buffer;
  // __local modelica_integer* local_size_buffer;
// };
// typedef struct buffer_s buffer;


// struct memory_s{
    // global_state* current_global_state;
    // local_state* current_local_state;
    // buffer* data_buffer;
// };
// typedef struct memory_s memory;

// /*
// void print_memory_state(memory* m)
// {
  // printf("=== Current state ===\n");
  // printf("real ptr at: %d\n",(int)m->current_global_state->global_real_buffer_ptr);
  // printf("integer ptr at: %d\n",(int)m->current_global_state->global_integer_buffer_ptr);
  // printf("boolean ptr at: %d\n",(int)m->current_global_state->global_boolean_buffer_ptr);
  // printf("size ptr at: %d\n",(int)m->current_global_state->global_size_buffer_ptr);
  // printf("real counter at: %d\n",(int)m->current_global_state->real_count);
  // printf("integer counter at: %d\n",(int)m->current_global_state->integer_count);
  // printf("boolean counter at: %d\n",(int)m->current_global_state->boolean_count);
  // printf("size counter at: %d\n",(int)m->current_global_state->size_count);
// }


// void print_state(state* m)
// {
  // printf("=== Current state ===\n");
  // printf("real ptr at: %d\n",(int)m->global_real_buffer_ptr);
  // printf("integer ptr at: %d\n",(int)m->global_integer_buffer_ptr);
  // printf("boolean ptr at: %d\n",(int)m->global_boolean_buffer_ptr);
  // printf("size ptr at: %d\n",(int)m->global_size_buffer_ptr);
  // printf("real counter at: %d\n",(int)m->real_count);
  // printf("integer counter at: %d\n",(int)m->integer_count);
  // printf("boolean counter at: %d\n",(int)m->boolean_count);
  // printf("size counter at: %d\n",(int)m->size_count);
// }


// */
// void initialize_global_buffer(__global void* exec_buffer, modelica_integer buffer_size, memory* current_memory){
    // size_t num_threads = 1;
    // size_t ndims = get_work_dim();
    // for(int i = 0; i < ndims; i++)
        // num_threads *= get_global_size(i);

    // size_t universalId;
    // if(ndims == 1)
        // universalId = get_global_id(0);
    // else if(ndims == 2)
        // universalId = get_global_id(1)*get_global_size(0) + get_global_id(0);
    // else if(ndims == 3)
        // universalId = get_global_id(2)*get_global_size(1)*get_global_size(0) + get_global_id(1)*get_global_size(0) + get_global_id(0);


// typedef __global void* global_void_ptr;

    // global_void_ptr  thread_buff_start;
    // size_t buffer_per_thread;
    // size_t real_buffer_per_thread;
    // size_t integer_buffer_per_thread;
    // size_t boolean_buffer_per_thread;
    // size_t size_buffer_per_thread;

    // buffer_per_thread = (buffer_size/num_threads);
    // thread_buff_start = exec_buffer + universalId*buffer_per_thread;

    // global_void_ptr real_start = thread_buff_start;
    // current_memory->data_buffer->global_real_buffer = (__global modelica_real*)real_start;
    // real_buffer_per_thread = (buffer_per_thread*PRECENTAGE_REAL_BUFFER)/100;

    // global_void_ptr integer_start = real_start + real_buffer_per_thread;
    // current_memory->data_buffer->global_integer_buffer = (__global modelica_integer*)integer_start;
    // integer_buffer_per_thread = (buffer_per_thread*PRECENTAGE_INTEGER_BUFFER)/100;

    // global_void_ptr size_start = integer_start + integer_buffer_per_thread;
    // current_memory->data_buffer->global_size_buffer = (__global modelica_integer*)size_start;
    // size_buffer_per_thread = (buffer_per_thread*PRECENTAGE_SIZE_BUFFER)/100;

    // global_void_ptr boolean_start = size_start + size_buffer_per_thread;
    // current_memory->data_buffer->global_boolean_buffer = (__global modelica_boolean*)boolean_start;
    // boolean_buffer_per_thread = (buffer_per_thread*PRECENTAGE_BOOLEAN_BUFFER)/100;


    // current_memory->current_global_state->global_real_buffer_ptr = current_memory->data_buffer->global_real_buffer;
    // current_memory->current_global_state->global_integer_buffer_ptr = current_memory->data_buffer->global_integer_buffer;
    // current_memory->current_global_state->global_size_buffer_ptr = current_memory->data_buffer->global_size_buffer;
    // current_memory->current_global_state->global_boolean_buffer_ptr = current_memory->data_buffer->global_boolean_buffer;

    // /*
    // if(get_global_id(0) == 0){
        // printf("execution buffer starts from %d\n", exec_buffer);
        // printf("execution buffer per thread %d KB\n", buffer_per_thread/1024);
        // printf("thread %d starts from %d\n", get_global_id(0), thread_buff_start);
        // //printf("REAL buffer SIZE  %d KB\n", (integer_start - real_start)/1024);
        // printf("max nr of real elements  %d\n", (integer_start - real_start)/sizeof(modelica_real));
        // //printf("INTEGER buffer SIZE  %d KB\n", (boolean_start - integer_start)/1024);
        // printf("max nr of integer elements  %d\n", (boolean_start - integer_start)/sizeof(modelica_integer));
        // //printf("BOOLEAN buffer SIZE  %d B\n", (size_start - boolean_start));
        // printf("max nr of boolean elements  %d\n", sizeof(modelica_boolean));
        // //printf("SIZE buffer SIZE  %d KB\n", (thread_buff_start + buffer_per_thread - size_start)/1024);
        // printf("max nr of size elements  %d\n", (thread_buff_start + buffer_per_thread - size_start)/sizeof(modelica_integer));
        // //printf("execution buffer for this thread ends at %d\n", current_memory->data_buffer->global_size_buffer + size_buffer_per_thread);
        // //printf("thread %d starts from %d\n", get_global_id(0) + 1, thread_buff_start + buffer_per_thread);
        // print_current_global_state(current_memory);
    // }
    // */

// ///////////////////////////////Global Memory initialized!////////////////////////////////////////////////////////////////////////

// }

// // HELL ends here. You made it! yay!



// /*
// state get_memory_state(){
  // return current_state;
// }
// */

// #define get_memory_state() (state){*(memory_state->current_global_state), *(memory_state->current_local_state)}; barrier(CLK_LOCAL_MEM_FENCE);

// /*
// void restore_memory_state(state s){
    // current_state = s;
// }
// */

// #define restore_memory_state(s) *(memory_state->current_global_state) = s.saved_global_state; *(memory_state->current_local_state) = s.saved_local_state; barrier(CLK_LOCAL_MEM_FENCE);

// //memory_pool ends here.
// ///////////////////////////////////////////////////////////


// ///////////////////////////////////////////////////////////
// //utility + builtin functions

// int in_range_integer(modelica_integer i,
         // modelica_integer start,
         // modelica_integer stop)
// {
  // if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  // if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  // return 0;
// }

// int in_range_real(modelica_real i,
      // modelica_real start,
      // modelica_real stop)
// {
  // if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  // if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  // return 0;
// }

// modelica_real modelica_div(modelica_real x, modelica_real y)
// {
  // return (modelica_real)((modelica_integer)(x/y));
// }

// modelica_real modelica_mod_real(modelica_real x, modelica_real y)
// {
  // return (x - floor(x/y) * y);
// }

// modelica_integer modelica_mod_integer(modelica_integer x, modelica_integer y)
// {
  // return x % y;
// }

// modelica_real modelica_rem_real(modelica_real x, modelica_real y)
// {
  // return x - y*(modelica_div(x,y));
// }

// modelica_integer modelica_rem_integer(modelica_integer x, modelica_integer y)
// {
  // return x - y*((x/y));
// }


// //utility + builtin functions ends here
// ///////////////////////////////////////////////////////////







// ///////////////////////////////////////////////////////////
// //Array related utilities


// void alloc_integer_array_c99_1(integer_array* dest, int ndims, modelica_integer size_1, memory* memory_state)
// {
    // size_t elements = 0;
    // _index_t start;
    // dest->ndims = 1;

    // //assert(n>=0);
    // //assert(n + current_global_state.global_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_global_state->global_size_buffer_ptr + 2 >= memory_state->current_global_state->global_boolean_buffer_ptr){
        // //printf("Size buffer pointer passed limit\n");
    // }

    // dest->dim_size = memory_state->current_global_state->global_size_buffer_ptr;
    // memory_state->current_global_state->global_size_buffer_ptr += 1;
    // dest->dim_size[0] = size_1;

    // elements = integer_array_nr_of_elements(dest);
    // //assert(n>=0);
    // //assert(current_global_state.global_integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);
    // if( memory_state->current_global_state->global_integer_buffer_ptr + elements >= memory_state->current_global_state->global_size_buffer_ptr){
        // //printf("Integer buffer pointer passed limit\n");
    // }

    // dest->data = memory_state->current_global_state->global_integer_buffer_ptr;
    // memory_state->current_global_state->global_integer_buffer_ptr += elements;
// }

// void alloc_real_array_c99_1(real_array* dest, int ndims, modelica_integer size_1, memory* memory_state)
// {
    // size_t elements = 0;
    // _index_t start;
    // dest->ndims = 1;

    // //assert(n>=0);
    // //assert(n + current_global_state.global_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_global_state->global_size_buffer_ptr + 2 >= memory_state->current_global_state->global_boolean_buffer_ptr){
        // //printf("Size buffer pointer passed limit\n");
    // }
    // dest->dim_size = memory_state->current_global_state->global_size_buffer_ptr;
    // memory_state->current_global_state->global_size_buffer_ptr += 1;
    // dest->dim_size[0] = size_1;

    // elements = real_array_nr_of_elements(dest);
    // //assert(n>=0);
    // //assert(current_global_state.global_integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);
    // if( memory_state->current_global_state->global_real_buffer_ptr + elements >= memory_state->current_global_state->global_integer_buffer_ptr){
        // //printf("Real buffer pointer passed limit\n");
    // }

    // dest->data = memory_state->current_global_state->global_real_buffer_ptr;
    // memory_state->current_global_state->global_real_buffer_ptr += elements;

// }


// void alloc_integer_array_c99_2(integer_array* dest, int ndims, modelica_integer size_1, modelica_integer size_2, memory* memory_state)
// {
    // size_t elements = 0;
    // _index_t start;
    // dest->ndims = 2;

    // //assert(n>=0);
    // //assert(n + current_global_state->global_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_global_state->global_size_buffer_ptr + 2 >= memory_state->current_global_state->global_boolean_buffer_ptr){
        // //printf("Size buffer pointer passed limit\n");
    // }
    // dest->dim_size = memory_state->current_global_state->global_size_buffer_ptr;
    // memory_state->current_global_state->global_size_buffer_ptr += 2;
    // dest->dim_size[0] = size_1;
    // dest->dim_size[1] = size_2;

    // elements = integer_array_nr_of_elements(dest);
    // //assert(n>=0);
    // //assert(current_global_state->global_integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);

    // if( memory_state->current_global_state->global_integer_buffer_ptr + elements >= memory_state->current_global_state->global_size_buffer_ptr){
        // //printf("Integer buffer pointer passed limit\n");
    // }
    // dest->data = memory_state->current_global_state->global_integer_buffer_ptr;
    // memory_state->current_global_state->global_integer_buffer_ptr += elements;
// }

// void alloc_real_array_c99_2(real_array* dest, int ndims, modelica_integer size_1, modelica_integer size_2, memory* memory_state)
// {
    // size_t elements = 0;
    // _index_t start;
    // dest->ndims = 2;

    // //assert(n>=0);
    // //assert(n + current_global_state->global_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_global_state->global_size_buffer_ptr + 2 >= memory_state->current_global_state->global_boolean_buffer_ptr){
        // //printf("Size buffer pointer passed limit\n");
    // }
    // dest->dim_size = memory_state->current_global_state->global_size_buffer_ptr;
    // memory_state->current_global_state->global_size_buffer_ptr += 2;
    // dest->dim_size[0] = size_1;
    // dest->dim_size[1] = size_2;

    // elements = real_array_nr_of_elements(dest);
    // //assert(n>=0);
    // //assert(current_global_state->global_integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);

    // if( memory_state->current_global_state->global_real_buffer_ptr + elements >= memory_state->current_global_state->global_integer_buffer_ptr){
        // //printf("Real buffer pointer passed limit\n");
    // }
    // dest->data = memory_state->current_global_state->global_real_buffer_ptr;
    // memory_state->current_global_state->global_real_buffer_ptr += elements;
// }

// void copy_integer_array_data(integer_array *source, integer_array *dest)
// {
    // size_t i, nr_of_elements;


    // nr_of_elements = real_array_nr_of_elements(source);

    // for (i = 0; i < nr_of_elements; ++i) {
        // ((__global modelica_integer *) dest->data)[i] = ((__global modelica_integer *) source->data)[i];
    // }
// }

// void copy_real_array_data(real_array *source, real_array *dest)
// {
    // size_t i, nr_of_elements;


    // nr_of_elements = real_array_nr_of_elements(source);

    // for (i = 0; i < nr_of_elements; ++i) {
        // ((__global modelica_real *) dest->data)[i] = ((__global modelica_real *) source->data)[i];
    // }
// }

// #define real_array_element_addr_c99_1(L, d, i) (((L)->data) + i - 1)
// /*
// __global modelica_real* real_array_element_addr_c99_1(real_array* L, int dim, modelica_integer i){
    // return ((__global modelica_real*)(L->data)) + i - 1;
// }

// __local modelica_real* local_integer_array_element_addr_c99_1(local_real_array* L, int dim, modelica_integer i){
    // return ((__local modelica_real*)(L->data)) + i - 1;
// }
// */

// #define integer_array_element_addr_c99_1(L, d, i) (((L)->data) + i - 1)
// /*
// __global modelica_integer* integer_array_element_addr_c99_1(integer_array* L, int dim, modelica_integer i){
    // return ((__global modelica_integer*)(L->data)) + i - 1;
// }

// __local modelica_integer* local_integer_array_element_addr_c99_1(local_integer_array* L, int dim, modelica_integer i){
    // return ((__local modelica_integer*)(L->data)) + i - 1;
// }
// */

// #define real_array_element_addr_c99_2(L, d, i, j) ((((L)->data)) + (i - 1)*((L)->dim_size[1]) + (j - 1))
// /*
// __global modelica_real* real_array_element_addr_c99_2(real_array* L, int dim, modelica_integer i, modelica_integer j){
    // return ((__global modelica_real*)(L->data)) + (i - 1)*L->dim_size[1] + (j - 1);
// }

// __local modelica_real* real_array_element_addr_c99_2(local_real_array* L, int dim, modelica_integer i, modelica_integer j){
    // return ((__local modelica_real*)(L->data)) + (i - 1)*L->dim_size[1] + (j - 1);
// }
// */

// #define integer_array_element_addr_c99_2(L, d, i, j) ((((L)->data)) + (i - 1)*((L)->dim_size[1]) + (j - 1))
// /*
// __global modelica_integer* integer_array_element_addr_c99_2(integer_array* L, int dim, modelica_integer i, modelica_integer j){
    // return ((__global modelica_integer*)(L->data)) + (i - 1)*L->dim_size[1] + (j - 1);
// }

// __local modelica_integer* integer_array_element_addr_c99_2(local_integer_array* L, int dim, modelica_integer i, modelica_integer j){
    // return ((__local modelica_integer*)(L->data)) + (i - 1)*L->dim_size[1] + (j - 1);
// }
// */

// #define real_array_element_addr_c99_3(L, d, i, j, k) ((((L)->data)) + (i - 1)*((L)->dim_size[1])*((L)->dim_size[2]) + (j - 1)*((L)->dim_size[2]) + (k - 1))
// /*
// __global modelica_real* real_array_element_addr_c99_3(real_array* L, int dim, modelica_integer i, modelica_integer j, modelica_integer k){
    // return ((__global modelica_real*)(L->data)) + (i - 1)*L->dim_size[1]*L->dim_size[2] + (j - 1)*L->dim_size[2] + (k - 1);
// }

// __local modelica_real* real_array_element_addr_c99_3(local_real_array* L, int dim, modelica_integer i, modelica_integer j, modelica_integer k){
    // return ((__local modelica_real*)(L->data)) + (i - 1)*L->dim_size[1]*L->dim_size[2] + (j - 1)*L->dim_size[2] + (k - 1);
// }
// */

// #define integer_array_element_addr_c99_3(L, d, i, j, k) ((((L)->data)) + (i - 1)*((L)->dim_size[1])*((L)->dim_size[2]) + (j - 1)*((L)->dim_size[2]) + (k - 1))
// /*
// __global modelica_integer* integer_array_element_addr_c99_3(integer_array* L, int dim, modelica_integer i, modelica_integer j, modelica_integer k){
    // return ((__global modelica_integer*)(L->data)) + (i - 1)*L->dim_size[1]*L->dim_size[2] + (j - 1)*L->dim_size[2] + (k - 1);
// }

// __local modelica_integer* integer_array_element_addr_c99_3(local_integer_array* L, int dim, modelica_integer i, modelica_integer j, modelica_integer k){
    // return ((__local modelica_integer*)(L->data)) + (i - 1)*L->dim_size[1]*L->dim_size[2] + (j - 1)*L->dim_size[2] + (k - 1);
// }
// */

// //uArray related utilities end here
// ///////////////////////////////////////////////////////////




// size_t local_integer_array_nr_of_elements(local_integer_array *a)
// {
    // int i;
    // size_t nr_of_elements = 1;
    // for (i = 0; i < a->ndims; ++i) {
       // nr_of_elements *= a->dim_size[i];
    // }
    // return nr_of_elements;
// }

// size_t local_real_array_nr_of_elements(local_real_array *a)
// {
    // int i;
    // size_t nr_of_elements = 1;
    // for (i = 0; i < a->ndims; ++i) {
       // nr_of_elements *= a->dim_size[i];
    // }
    // return nr_of_elements;
// }


// void alloc_local_integer_array_c99_1(local_integer_array* dest, int ndims, modelica_integer size_1, memory* memory_state)
// {
    // size_t elements = 0;
    // dest->ndims = 1;

    // //assert(n>=0);
    // //assert(n + current_state.local_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_local_state->size_count + 2 >= NR_SIZE_ELEMENTS){
        // //printf("Size buffer pointer passed limit\n");
    // }


    // dest->dim_size = memory_state->current_local_state->local_size_buffer_ptr;

    // memory_state->current_local_state->local_size_buffer_ptr += 1;
    // memory_state->current_local_state->size_count += 1;
    // dest->dim_size[0] = size_1;

    // elements = local_integer_array_nr_of_elements(dest);

    // //assert(n>=0);
    // //assert(current_state.global_integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);
    // if( memory_state->current_local_state->integer_count + elements >= NR_INTEGER_ELEMENTS){
        // //printf("Integer buffer pointer passed limit\n");
    // }

    // dest->data = memory_state->current_local_state->local_integer_buffer_ptr;
    // memory_state->current_local_state->local_integer_buffer_ptr += elements;
    // memory_state->current_local_state->integer_count += elements;
// }

// void alloc_local_integer_array_c99_2(local_integer_array* dest, int ndims, modelica_integer size_1, modelica_integer size_2, memory* memory_state)
// {
    // size_t elements = 0;
    // dest->ndims = 2;

    // //assert(n>=0);
    // //assert(n + current_state.local_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_local_state->size_count + 2 >= NR_SIZE_ELEMENTS){
        // //printf("Size buffer pointer passed limit\n");
    // }


    // dest->dim_size = memory_state->current_local_state->local_size_buffer_ptr;

    // memory_state->current_local_state->local_size_buffer_ptr += 2;
    // memory_state->current_local_state->size_count += 2;
    // dest->dim_size[0] = size_1;
    // dest->dim_size[1] = size_2;

    // elements = local_integer_array_nr_of_elements(dest);

    // //assert(n>=0);
    // //assert(current_state.global_integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);
    // if( memory_state->current_local_state->integer_count + elements >= NR_INTEGER_ELEMENTS){
        // //printf("Integer buffer pointer passed limit\n");
    // }

    // dest->data = memory_state->current_local_state->local_integer_buffer_ptr;
    // memory_state->current_local_state->local_integer_buffer_ptr += elements;
    // memory_state->current_local_state->integer_count += elements;
// }


// void alloc_local_real_array_c99_1(local_real_array* dest, int ndims, modelica_integer size_1, memory* memory_state)
// {
    // size_t elements = 0;
    // dest->ndims = 1;

    // //assert(n>=0);
    // //assert(n + current_state.local_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_local_state->size_count + 2 >= NR_SIZE_ELEMENTS){
        // //printf("Size buffer pointer passed limit\n");
    // }


    // dest->dim_size = memory_state->current_local_state->local_size_buffer_ptr;

    // memory_state->current_local_state->local_size_buffer_ptr += 1;
    // memory_state->current_local_state->size_count += 1;
    // dest->dim_size[0] = size_1;

    // elements = local_real_array_nr_of_elements(dest);

    // //assert(n>=0);
    // //assert(current_state.global_real_buffer_ptr +n < NR_REAL_ELEMENTS);
    // if( memory_state->current_local_state->real_count + elements >= NR_REAL_ELEMENTS){
        // //printf("Integer buffer pointer passed limit\n");
    // }

    // dest->data = memory_state->current_local_state->local_real_buffer_ptr;
    // memory_state->current_local_state->local_real_buffer_ptr += elements;
    // memory_state->current_local_state->integer_count += elements;
// }

// void alloc_local_real_array_c99_2(local_real_array* dest, int ndims, modelica_integer size_1, modelica_integer size_2, memory* memory_state)
// {
    // size_t elements = 0;
    // dest->ndims = 2;

    // //assert(n>=0);
    // //assert(n + current_state.local_size_buffer_ptr < NR_SIZE_ELEMENTS);
    // if( memory_state->current_local_state->size_count + 2 >= NR_SIZE_ELEMENTS){
        // //printf("Size buffer pointer passed limit\n");
    // }


    // dest->dim_size = memory_state->current_local_state->local_size_buffer_ptr;

    // memory_state->current_local_state->local_size_buffer_ptr += 2;
    // memory_state->current_local_state->size_count += 2;
    // dest->dim_size[0] = size_1;
    // dest->dim_size[1] = size_2;

    // elements = local_real_array_nr_of_elements(dest);

    // //assert(n>=0);
    // //assert(current_state.global_real_buffer_ptr +n < NR_REAL_ELEMENTS);
    // if( memory_state->current_local_state->real_count + elements >= NR_REAL_ELEMENTS){
        // //printf("Integer buffer pointer passed limit\n");
    // }

    // dest->data = memory_state->current_local_state->local_real_buffer_ptr;
    // memory_state->current_local_state->local_real_buffer_ptr += elements;
    // memory_state->current_local_state->integer_count += elements;
// }
