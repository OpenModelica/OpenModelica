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

 This file contains functions for memory related operations.
 Allocating, initializing, copying of memory on/from GPU/CPU
 to GPU/CPU is handled by this functions.

 Mahder.Gebremedhin@liu.se  2012-03-31

*/


#ifndef _OMC_OCL_MEMORY_OPS_H
#define _OMC_OCL_MEMORY_OPS_H


#include "omc_ocl_common_header.h"


extern cl_command_queue device_comm_queue;
extern cl_context  device_context;
extern cl_device_id ocl_device;


cl_mem ocl_device_alloc_init(modelica_integer* host_array, size_t size);

cl_mem ocl_device_alloc_init(modelica_real* host_array, size_t size);

cl_mem ocl_device_alloc(size_t size);


//allocates memory space on device and returns the handle to the buffer object
//also initializes if from host memory IF src_data is not NULL.
//size is the actuall size in bytes.
cl_mem ocl_alloc_init(void* src_data, size_t size);

//ATTENTION: This function allocates a large amount of memory
//to be used for creatinfg arrays inside parallel functions.
//If this fails try reducing the amount by increasing the #define OCL_BUFFER_SIZE_FRACTION
//which defines the freaction of memory from the availabel GLOBAL_MEM_SIZE to be used as buffer.
void ocl_create_execution_memory_buffer(device_buffer* d_buff);

//allocates a double array on device and returns the handle to the buffer object
//also initializes if from host array IF host array is not NULL.
//Use size 1 to allocate a Scalar.
cl_mem ocl_alloc_init_real_arr(modelica_real* host_array, int a_size);

//allocates an int array on device and returns the handle to the buffer object
//also initializes if from host array IF host array is not NULL.
//Use size 1 to allocate a Scalar.
cl_mem ocl_alloc_init_integer_arr(modelica_integer* host_array, int a_size);



//copies a double array to ALREADY allocated device buffer
//Size is the number of elements in the src array
void ocl_copy_to_device_real(cl_mem dev_dest_array, modelica_real* src_host_array, int a_size);

//copies one buffer to another on the device
//Size is the number of elements in the src array
void ocl_copy_device_to_device_real(cl_mem dev_src_array, cl_mem device_dest_array, int a_size);

//copies a double array back to host
void ocl_copy_back_to_host_real(cl_mem dev_output_array, modelica_real* dest_host_array, int a_size);

//copies an integer array to ALREADY allocated device buffer
void ocl_copy_to_device_integer(cl_mem dev_dest_array, modelica_integer* src_host_array, int a_size);

//Size is the number of elements in the src array
void ocl_copy_device_to_device_integer(cl_mem dev_src_array, cl_mem device_dest_array, int a_size);

//copies an int array back to host
void ocl_copy_back_to_host_integer(cl_mem dev_output_array, modelica_integer* dest_host_array, int a_size);

#endif
