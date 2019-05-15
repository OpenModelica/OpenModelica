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

 This file contains interfacing functions. Theses are the
 actuall functions that are available for calling by the
 code generated from Modelica source.
 If a function is not called from the generated code please
 don not add it here.
 If the feature involves complex operations then define it
 somewhere else and and just create interface for it here
 (If it needs to be exported.)


 Mahder.Gebremedhin@liu.se  2012-03-31

*/



#ifndef _OMC_OCL_INTERFACE_H
#define _OMC_OCL_INTERFACE_H


#include "omc_ocl_common_header.h"
#include "omc_ocl_memory_ops.h"



// Just to stick to  OpenModelica's function naming pattern
#define oclSetNumThreadsOnlyGlobal(...) ocl_set_num_threads( __VA_ARGS__ )
#define oclSetNumThreadsGlobalLocal(...) ocl_set_num_threads( __VA_ARGS__ )
#define oclSetNumThreadsGlobalLocal1D(...) ocl_set_num_threads( __VA_ARGS__ )
#define oclSetNumThreadsGlobalLocal2D(...) ocl_set_num_threads( __VA_ARGS__ )
#define oclSetNumThreadsGlobalLocal3D(...) ocl_set_num_threads( __VA_ARGS__ )


// sets the number of threads for subsequent parallel operations
// arguments are arrays of work_dim size specifiying each workgroup dimension
void ocl_set_num_threads(integer_array_t global_threads_in, integer_array_t local_threads_in);


// sets the number of threads for subsequent parallel operations.
// similar to the above function with arrays of size 1 only.
void ocl_set_num_threads(modelica_integer global_threads_in, modelica_integer local_threads_in);

//sets the number of threads for subsequent parallel operations.
//This time only the total number of threads desired is given. OpenCL will
//automatically distribute workitems/threads into work groups.
//it ca also be used(by passing 0) to reset the number of total threads to the max value of one group (default).
void ocl_set_num_threads(modelica_integer global_threads_in);

//sets a single Kernel cl_mem (device pointer) argument.
void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, cl_mem in_arg);
//sets a single Kernel Real argument.
void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, modelica_real in_arg);
//sets a single Kernel Integer argument.
void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, modelica_integer in_arg);

// sets a __local Kernel argument. The size should be given.
void ocl_set_local_kernel_arg(cl_kernel kernel, int arg_nr, size_t in_size);



//overloaded functions from real/integer/boolean _array in the C_runtime library
//for allocating and copying arrays to openCL device

void alloc_integer_array(device_integer_array *dest, int ndims, ...);

void alloc_real_array(device_integer_array *dest, int ndims, ...);

void alloc_device_local_real_array(device_local_real_array *dest, int ndims, ...);

void copy_real_array_data(device_real_array dev_array_ptr, real_array_t* host_array_ptr);

void copy_real_array_data(real_array_t host_array_ptr, device_real_array* dev_array_ptr);

void copy_real_array_data(device_real_array dev_array_ptr1, device_real_array* dev_array_ptr2);

void copy_integer_array_data(device_integer_array dev_array_ptr, integer_array_t* host_array_ptr);

void copy_integer_array_data(integer_array_t host_array_ptr, device_integer_array* dev_array_ptr);

void copy_integer_array_data(device_integer_array dev_array_ptr1, device_integer_array* dev_array_ptr2);


// //functions used for copying scalars. Scalars in the normal(serial C) code genertation
// //of modelica are copied by assignment (a = b). However to be able to copy them b'n
// //GPU and host CPU we need to change the assignments to copy functions.
// void copy_assignment_helper_integer(modelica_integer* i1, modelica_integer* i2);

// void copy_assignment_helper_integer(device_integer* i1, modelica_integer* i2);

// void copy_assignment_helper_integer(modelica_integer* i1, device_integer* i2);

// void copy_assignment_helper_integer(device_integer* i1, device_integer* i2);

// void copy_assignment_helper_real(modelica_real* i1, modelica_real* i2);

// void copy_assignment_helper_real(device_real* i1, modelica_real* i2);

// void copy_assignment_helper_real(modelica_real* i1, device_real* i2);

// void copy_assignment_helper_real(device_real* i1, device_real* i2);

//these functions are added to solve a problem with a memory leak when returning arrays
//from functions. Arrays used to be assigned just like normal scalar variables. Which causes the
//allocated memory on the lhs to be lost when the pointer is replaced with the new one.
//this fixes the problem for parallel arrays. for serial arrays the memory is restored when the
//function returns(not dynamic allocation), So the only lose in serial case is visible just until
//the function returns.
void swap_and_release(device_array* lhs, device_array* rhs);

void swap_and_release(base_array_t* lhs, base_array_t* rhs);

//functions fallowing here are just the same function(the one in real/integer_array.c/h) declared with different names
//this is done to be able to use the same generated code in normal c runtime and as well as in OpenCL kernels
//which right now doesn't support overloading or the stdarg standard library.
//even though the functions have the same body here they will have different body on the OpenCL counterparts

modelica_real* real_array_element_addr_c99_1(real_array_t* source,int ndims,...);

modelica_real* real_array_element_addr_c99_2(real_array_t* source,int ndims,...);

modelica_real* real_array_element_addr_c99_3(real_array_t* source,int ndims,...);

modelica_integer* integer_array_element_addr_c99_1(integer_array_t* source,int ndims,...);

modelica_integer* integer_array_element_addr_c99_2(integer_array_t* source,int ndims,...);

modelica_integer* integer_array_element_addr_c99_3(integer_array_t* source,int ndims,...);


//array dimension size functions. returns the size of a given dimension for device real array
modelica_integer size_of_dimension_real_array(device_real_array dev_arr, modelica_integer dim);

//array dimension size functions. returns the size of a given dimension for device integer array
modelica_integer size_of_dimension_integer_array(device_integer_array dev_arr, modelica_integer dim);

//Free a device array memory.
void free_device_array(device_array *dest);

// This is just overloaded to allow the device arrays
// be freed properly.
void free_device_array(base_array_t* dest);

//prints information about a device array. useful for debugging.
void print_array_info(device_real_array* arr);

//prints array. useful for debugging.
void print_array(real_array_t* arr);

//ATTENTION: printing a device array means copying back and then printing. Exprensive Operation.
//void print_array(device_real_array* dev_arr);




#endif






