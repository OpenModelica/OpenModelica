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

 This file contains OpenCL related utility functions.
 These include
   - Functions for selection and initlizing of an
     OpenCL device, building/compiling OpenCL source code, creating
     kernels from OpenCl programs and executing the kernels.
   - Functions and variables for thread managment i.e. number
     of threads to be used, arrangment of threads in to dimensions,
     organization of threads in to work groups.
   - Error handling.


 Mahder.Gebremedhin@liu.se  2012-03-31

*/



#ifndef _OMC_OCL_UTIL_H
#define _OMC_OCL_UTIL_H


#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <sys/stat.h>

#include "omc_ocl_common_header.h"

// The compiled OpenCL program containing kerenls generated for a simulation
cl_program omc_ocl_program = NULL;

// The ParModelica kernels file containing kerenls generated for a simulation
// This should be initialzed in the generated code.
extern const char* omc_ocl_kernels_source;

// The default OpenCL device. If not set (=0) show the selection option.*/
// This should be initialzed in the generated code.
extern unsigned int default_ocl_device;


extern modelica_integer* integer_array_element_addr_c99_1(integer_array* source,int ndims,...);


//Reads kernels from a file
char* load_source_file(const char* fileName);

//initializes OCL environment on first call
void ocl_initialize();

//Gets available OCL_enabled devices.
void ocl_get_device();

//Creates context and command queues neccesary for launching kernel
void ocl_create_context_and_comm_queue();

//Extracts and creates a kernel from a given program.
cl_kernel ocl_create_kernel(cl_program program, const char* kernel_name);

//sets Kernel arguments. count is the number of arguments beieng passed
void ocl_set_kernel_args(cl_kernel kernel, int count, ...);

//sets a single Kernel cl_mem (device pointer) argument.
void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, cl_mem in_arg);

//sets a single Kernel Real argument.
void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, modelica_real in_arg);

//sets a single Kernel Integer argument.
void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, modelica_integer in_arg);

// sets a __local Kernel argument. The size should be given.
void ocl_set_local_kernel_arg(cl_kernel kernel, int arg_nr, size_t in_size);

//executes a kernel
void ocl_execute_kernel(cl_kernel kernel);

// sets the number of threads for subsequent parallel operations
// arguments are arrays of work_dim size specifiying each workgroup dimension
void ocl_set_num_threads(integer_array global_threads_in, integer_array local_threads_in);

// sets the number of threads for subsequent parallel operations.
// similar to the above function with arrays of size 1 only.
void ocl_set_num_threads(modelica_integer global_threads_in, modelica_integer local_threads_in);

//sets the number of threads for subsequent parallel operations.
//This time only the total number of threads desired is given. OpenCL will
//automatically distribute workitems/threads into work groups.
//it ca also be used(by passing 0) to reset the number of total threads to the max value of one group (default).
void ocl_set_num_threads(modelica_integer global_threads_in);

//returns the current number of threads.
modelica_integer ocl_get_num_threads();

//Builds a program from a source file containing Kernels.
// Puts the program in the global var omc_ocl_program
void ocl_build_p_from_src();

void ocl_clean_up();

//checks error codes.
void ocl_error_check(int operation, cl_int error_code);

#endif
