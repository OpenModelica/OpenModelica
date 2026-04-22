/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
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



//copies data of an array (or any memory elem_sze*nr_of_elem) to ALREADY allocated device buffer
void ocl_copy_to_device(cl_mem dev_dest_array, void* src_host_array, size_t elem_sze, int nr_of_elem);

//copies one buffer to another on the device
void ocl_copy_device_to_device(cl_mem dev_src_array, cl_mem device_dest_array, size_t elem_sze, int nr_of_elem);

//copies a double array back to host
void ocl_copy_back_to_host(cl_mem dev_output_array, void* dest_host_array, size_t elem_sze, int nr_of_elem);


#endif
