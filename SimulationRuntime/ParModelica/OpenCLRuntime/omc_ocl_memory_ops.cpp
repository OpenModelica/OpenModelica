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

 See the header file for more comments.

 Mahder.Gebremedhin@liu.se  2012-03-31

*/



#include <omc_ocl_memory_ops.h>



cl_mem ocl_device_alloc(size_t size){

    cl_int err;
    cl_mem tmp = NULL;

    if (!device_comm_queue)
        ocl_initialize();

    tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE,
            size, NULL, &err);

    ocl_error_check(OCL_CREATE_BUFFER, err);
    return tmp;
}

cl_mem ocl_device_alloc_init(modelica_integer* host_array, size_t size){

    cl_int err;
    cl_mem tmp = NULL;

    if (!device_comm_queue)
        ocl_initialize();

    if (host_array)
        tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE |
            CL_MEM_COPY_HOST_PTR, size, host_array, &err);

    ocl_error_check(OCL_CREATE_BUFFER, err);

    return tmp;

}

cl_mem ocl_device_alloc_init(modelica_real* host_array, size_t size){

    cl_int err;
    cl_mem tmp = NULL;

    if (!device_comm_queue)
        ocl_initialize();

    if (host_array)
        tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE |
            CL_MEM_COPY_HOST_PTR, size, host_array, &err);

    ocl_error_check(OCL_CREATE_BUFFER, err);

    return tmp;

}


cl_mem ocl_alloc_init(void* src_data, size_t size){
    cl_int err;
    cl_mem tmp = NULL;

    if (!device_comm_queue)
        ocl_initialize();

    if (src_data)
        tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE |
            CL_MEM_COPY_HOST_PTR, size, src_data, &err);

    else
        tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE,
            size, NULL, &err);

    ocl_error_check(OCL_CREATE_BUFFER, err);

    return tmp;

}


void ocl_create_execution_memory_buffer(device_buffer* d_buff){

    cl_int err;
    cl_ulong mem;
    cl_ulong mem2;
    cl_mem tmp;
    cl_ulong size;

    clGetDeviceInfo(ocl_device, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(cl_ulong), &mem, NULL);
    clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_MEM_ALLOC_SIZE, sizeof(cl_ulong), &mem2, NULL);
    size = mem/OCL_BUFFER_SIZE_FRACTION;
    size = (size > mem2 ? mem2 : size);
    size = 30 * 1024 * 1024 * sizeof(modelica_integer);
    //printf("Allocating : %llu MB for execution memory buffer \n", size/1024/1024);
    tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE,
            size, NULL, &err);

    ocl_error_check(OCL_CREATE_BUFFER, err);
    if(err){
        printf("Error: Allocating execution memory buffer");
        exit(1);
    }

    d_buff->buffer = tmp;
    d_buff->size = size;
}


cl_mem ocl_alloc_init_real_arr(modelica_real* host_array, int a_size){
    cl_int err;
    cl_mem tmp;
    if (!device_comm_queue)
        ocl_initialize();

    if (host_array)
        tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE |
            CL_MEM_COPY_HOST_PTR, sizeof(modelica_real) * a_size, host_array, &err);

    else
        tmp = clCreateBuffer(device_context, CL_MEM_READ_WRITE,
            sizeof(modelica_real) * a_size, NULL, &err);

    ocl_error_check(OCL_CREATE_BUFFER, err);

    return tmp;

}

cl_mem ocl_alloc_init_integer_arr(cl_int* host_array, int a_size){
    cl_int err;
    if (!device_comm_queue)
        ocl_initialize();

    if (host_array)
        return clCreateBuffer(device_context, CL_MEM_READ_WRITE |
            CL_MEM_COPY_HOST_PTR, sizeof(modelica_integer) * a_size, host_array, &err);

    else
        return clCreateBuffer(device_context, CL_MEM_READ_WRITE,
            sizeof(modelica_integer) * a_size, NULL, &err);

    ocl_error_check(OCL_CREATE_BUFFER, err);

}




void ocl_copy_to_device_real(cl_mem dev_dest_array, modelica_real* src_host_array, int a_size){
    cl_int err;
    if (!device_comm_queue)
        printf("ERROR: ocl_copy_to_device_real(): tryig to copy to device with no command queue created: not initialized OCL env?");

    err = clEnqueueWriteBuffer(device_comm_queue, dev_dest_array, CL_TRUE, 0,
        a_size * sizeof(modelica_real), src_host_array, 0, NULL, NULL);

    ocl_error_check(OCL_COPY_HOST_TO_DEV, err);
}

void ocl_copy_device_to_device_real(cl_mem dev_src_array, cl_mem device_dest_array, int a_size){
    cl_int err;
    if (!device_comm_queue)
        printf("ERROR: ocl_copy_device_to_device_real(): tryig to copy device to device with no command queue created: not initialized OCL env?");

    err = clEnqueueCopyBuffer(device_comm_queue, dev_src_array, device_dest_array, 0, 0,
        a_size * sizeof(modelica_real), 0, NULL, NULL);

    ocl_error_check(OCL_COPY_DEV_TO_DEV, err);
}

void ocl_copy_back_to_host_real(cl_mem dev_output_array, modelica_real* dest_host_array, int a_size){
    cl_int err;
    if (!device_comm_queue)
        printf("ERROR: ocl_copy_back_to_host_real(): tryig to copy back non existent data");

    err = clEnqueueReadBuffer(device_comm_queue, dev_output_array, CL_TRUE, 0,
        a_size * sizeof(modelica_real), dest_host_array, 0, NULL, NULL);

    ocl_error_check(OCL_COPY_DEV_TO_HOST, err);
}

void ocl_copy_to_device_integer(cl_mem dev_dest_array, modelica_integer* src_host_array, int a_size){
    cl_int err;
    if (!device_comm_queue)
        printf("ERROR: ocl_copy_to_device_integer(): tryig to copy to device with no command queue created: not initialized OCL env?");

    err = clEnqueueWriteBuffer(device_comm_queue, dev_dest_array, CL_TRUE, 0,
        a_size * sizeof(modelica_integer), src_host_array, 0, NULL, NULL);

    ocl_error_check(OCL_COPY_HOST_TO_DEV, err);
}

void ocl_copy_device_to_device_integer(cl_mem dev_src_array, cl_mem device_dest_array, int a_size){
    cl_int err;
    if (!device_comm_queue)
        printf("ERROR: ocl_copy_device_to_device_integer(): tryig to copy device to device with no command queue created: not initialized OCL env?");

    err = clEnqueueCopyBuffer(device_comm_queue, dev_src_array, device_dest_array, 0, 0,
        a_size * sizeof(modelica_integer), 0, NULL, NULL);

    ocl_error_check(OCL_COPY_DEV_TO_DEV, err);
}


void ocl_copy_back_to_host_integer(cl_mem dev_output_array, modelica_integer* dest_host_array, int a_size){
    cl_int err;
    if (!device_comm_queue)
        printf("ERROR: ocl_copy_back_to_host_int(): tryig to copy back non existent data");

    err = clEnqueueReadBuffer(device_comm_queue, dev_output_array, CL_TRUE, 0,
        a_size * sizeof(modelica_integer), dest_host_array, 0, NULL, NULL);

    ocl_error_check(OCL_COPY_DEV_TO_HOST, err);
}

