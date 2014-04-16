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

 Common hader file included by other headers in the openCLRuntime

 Mahder.Gebremedhin@liu.se  2012-03-31

*/



#ifndef _OMC_OCL_COMMON_HEADER
#define _OMC_OCL_COMMON_HEADER

#include <stdio.h>
#ifdef __APPLE__
#include <OpenCL/cl.h>
#else
#include <CL/cl.h>
#endif
#include <openmodelica.h>
#include <stdarg.h>
#include <sys/time.h>



#define MAX_DEVICE 4
#define SHOW_DEVICE_SELECTION
// #define SHOW_ARG_SET_ERRORS
#define DEFAULT_DEVICE 1
#define OCL_BUFFER_SIZE_FRACTION 4


// DEFINED IN: omc_ocl_util
void ocl_initialize();
void ocl_error_check(int operation, cl_int error_code);
cl_program ocl_build_p_from_src(const char* source, int isfile);
cl_kernel ocl_create_kernel(cl_program program, const char* kernel_name);


//executes a kernel
void ocl_execute_kernel(cl_kernel kernel);


typedef cl_mem device_integer;
typedef cl_mem device_real;


struct dev_buff{
 cl_mem buffer;
 modelica_integer size;
};

typedef struct dev_buff device_buffer;


typedef struct dev_arr{
 cl_mem data;
 cl_mem info_dev;
 modelica_integer* info;
} device_array;

typedef device_array device_integer_array;
typedef device_array device_real_array;

// typedef struct dev_local_arr{
 // cl_mem data;
 // cl_mem info_dev;
 // modelica_integer* info;
// } device_local_array;

typedef device_array device_local_real_array;
typedef device_array device_local_integer_array;


enum ocl_error {OCL_BUILD_PROGRAM, OCL_CREATE_KERNEL, OCL_CREATE_BUFFER, OCL_CREATE_CONTEXT,
                OCL_CREATE_COMMAND_QUEUE, OCL_SET_KER_ARGS, OCL_ENQUE_ND_RANGE_KERNEL, OCL_COPY_DEV_TO_DEV,
                OCL_COPY_HOST_TO_DEV, OCL_COPY_DEV_TO_HOST, OCL_REALEASE_MEM_OBJECT};



// Defined in: omc_ocl_interface.cpp
size_t device_array_nr_of_elements(device_array *a);

#endif
