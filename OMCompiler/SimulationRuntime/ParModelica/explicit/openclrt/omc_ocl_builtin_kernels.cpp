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

 This file contains functions used to call and execute custom kernels or
 algoritms on OpenCL devices. For example a matrix multiplication or
 transpose can be computed with this kernels if the user has not provided
 the algorithm explicitly.
 e.g. in Modelica
   A := transpose(B);

 The operations are organized by argument type/number and return type.
 All operations that take similar type and number of arguments can be
 handled by one function

 See the header file for more comments.

 Mahder.Gebremedhin@liu.se  2012-03-31

*/


#include <omc_ocl_builtin_kernels.h>

void ocl_real_arr_arr_arr(const char* kernel_name, modelica_real* src_1, modelica_real* src_2, modelica_real* dest, int size_){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;

    if (!device_comm_queue)
        ocl_initialize();

    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("real_ar_ar_ar.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, size_);
    cl_mem device_array_2 = ocl_alloc_init_real_arr(src_2, size_);
    cl_mem device_array_output = ocl_alloc_init_real_arr(NULL, size_);


    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_mem),(void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(cl_mem), (void*)&device_array_2);
    err |= clSetKernelArg(OpenCLfunction, 2, sizeof(cl_mem), (void*)&device_array_output);
    ocl_error_check(OCL_SET_KER_ARGS, err);


    size_t WorkSize[1] = {static_cast<size_t>(size_)}; // one dimensional Range
    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 1, NULL,
        WorkSize, NULL, 0, NULL, NULL);
    clFinish(device_comm_queue);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);

    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(device_array_output, dest, size_);

    clReleaseMemObject(device_array_1);
    clReleaseMemObject(device_array_2);
    clReleaseMemObject(device_array_output);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}

void ocl_real_arr_arr_sca(const char* kernel_name, modelica_real* src_1, modelica_real* src_2, modelica_real* dest, int size_){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;
    cl_int inc1, inc2;
    inc1=1;
    inc2=1;

    size_t WorkSize[1] = {static_cast<size_t>(size_)};
    size_t localWorkSize[1] = {32};    // one dimensional Range

    if (!device_comm_queue)
        ocl_initialize();


    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("real_ar_ar_sca.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, size_);
    cl_mem device_array_2 = ocl_alloc_init_real_arr(src_2, size_);
    cl_mem result = ocl_alloc_init_real_arr(NULL, 1);

    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_int),(void*)&size_);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(cl_mem), (void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 2, sizeof(cl_int), (void*)&inc1);
    err |= clSetKernelArg(OpenCLfunction, 3, sizeof(cl_mem), (void*)&device_array_2);
    err |= clSetKernelArg(OpenCLfunction, 4, sizeof(cl_int), (void*)&inc2);
    err |= clSetKernelArg(OpenCLfunction, 5, sizeof(cl_mem), (void*)&result);
    err |= clSetKernelArg(OpenCLfunction, 6, sizeof(modelica_real)*localWorkSize[0], NULL);
    ocl_error_check(OCL_SET_KER_ARGS, err);

    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 1, NULL,
        WorkSize, localWorkSize, 0, NULL, NULL);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);
    clFinish(device_comm_queue);

    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(result, dest, 1);


    clReleaseMemObject(device_array_1);
    clReleaseMemObject(device_array_2);
    clReleaseMemObject(result);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}

void ocl_real_arr_sca_arr(const char* kernel_name, modelica_real* src_1, modelica_real src_2, modelica_real* dest, int size_){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;


    if (!device_comm_queue)
        ocl_initialize();

    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("real_arr_sca_arr.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, size_);
    cl_mem device_array_output = ocl_alloc_init_real_arr(NULL, size_);


    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_mem),(void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(modelica_real), (void*)&src_2);
    err |= clSetKernelArg(OpenCLfunction, 2, sizeof(cl_mem), (void*)&device_array_output);
    ocl_error_check(OCL_SET_KER_ARGS, err);

    size_t WorkSize[1] = {static_cast<size_t>(size_)};
    //size_t localWorkSize[1] = {32};    // one dimensional Range
    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 1, NULL,
        WorkSize, NULL, 0, NULL, NULL);
    clFinish(device_comm_queue);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);

    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(device_array_output, dest, size_);


    clReleaseMemObject(device_array_1);
    clReleaseMemObject(device_array_output);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}

void ocl_real_arr_arr(const char* kernel_name, modelica_real* src_1, modelica_real* dest, int size_){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;


    if (!device_comm_queue)
        ocl_initialize();

    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("real_ar_ar_sca.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, size_);
    cl_mem device_array_output = ocl_alloc_init_real_arr(NULL, size_);



    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_mem),(void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(cl_mem), (void*)&device_array_output);


    size_t WorkSize[1] = {static_cast<size_t>(size_)};
    //size_t localWorkSize[1] = {32};    // one dimensional Range
    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 1, NULL,
        WorkSize, NULL, 0, NULL, NULL);
    clFinish(device_comm_queue);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);

    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(device_array_output, dest, size_);


    clReleaseMemObject(device_array_1);
    clReleaseMemObject(device_array_output);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}

void ocl_real_arr_sca(const char* kernel_name, modelica_real* src_1, modelica_real* dest, int size_){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;

    if (!device_comm_queue)
        ocl_initialize();

    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("real_ar_ar_sca.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, size_);
    cl_mem tmp = ocl_alloc_init_real_arr(NULL, size_);
    cl_mem result = ocl_alloc_init_real_arr(NULL, 1);


    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_mem),(void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(cl_mem), (void*)&result);
    err |= clSetKernelArg(OpenCLfunction, 2, sizeof(cl_mem), (void*)&tmp);
    err |= clSetKernelArg(OpenCLfunction, 3, sizeof(cl_int), (void*)&size_);
    ocl_error_check(OCL_SET_KER_ARGS, err);

    size_t WorkSize[1] = {static_cast<size_t>(size_)};
    //size_t localWorkSize[1] = {32};    // one dimensional Range
    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 1, NULL,
        WorkSize, NULL, 0, NULL, NULL);
    clFinish(device_comm_queue);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);
    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(result, dest, 1);


    clReleaseMemObject(device_array_1);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}

void ocl_real_matrix_matrix_matrix(const char* kernel_name, modelica_real* src_1, int M, modelica_real* src_2, int N, modelica_real* dest, int K){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;


    size_t WorkSize[2] = {static_cast<size_t>(M), static_cast<size_t>(N)};
    size_t localWorkSize[2] = {16,16};

    if (!device_comm_queue){
    printf("------------------------------Initizlizing---------------------\n");
        ocl_initialize();
    }
    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("matrix.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, M*K);
    cl_mem device_array_2 = ocl_alloc_init_real_arr(src_2, K*N);
    cl_mem result = ocl_alloc_init_real_arr(NULL, M*N);

    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_mem), (void*)&result);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(cl_mem), (void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 2, sizeof(cl_mem), (void*)&device_array_2);
    err |= clSetKernelArg(OpenCLfunction, 3, sizeof(cl_int), (void*)&K);
    err |= clSetKernelArg(OpenCLfunction, 4, sizeof(cl_int), (void*)&N);
    ocl_error_check(OCL_SET_KER_ARGS, err);

    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 2, NULL,
        WorkSize, localWorkSize, 0, NULL, NULL);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);
    clFinish(device_comm_queue);

    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(result, dest, M*N);


    clReleaseMemObject(device_array_1);
    clReleaseMemObject(device_array_2);
    clReleaseMemObject(result);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}

void ocl_real_matrix_matrix_matrix2(const char* kernel_name, modelica_real* src_1, int M, modelica_real* src_2, int N, modelica_real* dest, int K){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;

    if (!device_comm_queue)
        ocl_initialize();

    size_t WorkSize[2] = {static_cast<size_t>(M/4), static_cast<size_t>(N/4)};
    size_t localWorkSize[2] = {16,16};

    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("matrix2.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, M*K);
    cl_mem device_array_2 = ocl_alloc_init_real_arr(src_2, K*N);
    cl_mem result = ocl_alloc_init_real_arr(NULL, M*N);

    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_mem), (void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(cl_mem), (void*)&device_array_2);
    err |= clSetKernelArg(OpenCLfunction, 2, sizeof(cl_mem), (void*)&result);
    err |= clSetKernelArg(OpenCLfunction, 3, sizeof(cl_int), (void*)&K);
    err |= clSetKernelArg(OpenCLfunction, 4, sizeof(cl_int), (void*)&N);
    ocl_error_check(OCL_SET_KER_ARGS, err);

    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 2, NULL,
        WorkSize, localWorkSize, 0, NULL, NULL);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);
    clFinish(device_comm_queue);

    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(result, dest, M*N);


    clReleaseMemObject(device_array_1);
    clReleaseMemObject(device_array_2);
    clReleaseMemObject(result);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}

void ocl_real_matrix_matrix(const char* kernel_name, modelica_real* src_1, int M, int N, modelica_real* dest){

    cl_program OpenCLProgram;
    cl_kernel OpenCLfunction;
    clock_t c0, c1;
    cl_int err;
    cl_int block_size = 16;

    size_t WorkSize[2] = {static_cast<size_t>(M), static_cast<size_t>(N)};
    size_t localWorkSize[2] = {static_cast<size_t>(block_size), static_cast<size_t>(block_size)};

    if (!device_comm_queue)
        ocl_initialize();

    //This can be moved out. left here hoping that similar ops will be called
    //sequentialy. If we kept them in one .cl file we dont have to build again
    OpenCLProgram = ocl_build_p_from_src("matrix.cl", true);


    OpenCLfunction = clCreateKernel(OpenCLProgram, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);

    cl_mem device_array_1 = ocl_alloc_init_real_arr(src_1, M*N);
    cl_mem result = ocl_alloc_init_real_arr(NULL, M*N);

    err = clSetKernelArg(OpenCLfunction, 0, sizeof(cl_mem), (void*)&result);
    err |= clSetKernelArg(OpenCLfunction, 1, sizeof(cl_mem), (void*)&device_array_1);
    err |= clSetKernelArg(OpenCLfunction, 2, sizeof(modelica_real)*16*16, NULL);
    err |= clSetKernelArg(OpenCLfunction, 3, sizeof(cl_int), (void*)&M);
    err |= clSetKernelArg(OpenCLfunction, 4, sizeof(cl_int), (void*)&N);
    err |= clSetKernelArg(OpenCLfunction, 5, sizeof(cl_int), (void*)&block_size);
    ocl_error_check(OCL_SET_KER_ARGS, err);

    c0 = clock();
    err = clEnqueueNDRangeKernel(device_comm_queue, OpenCLfunction, 2, NULL,
        WorkSize, localWorkSize, 0, NULL, NULL);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);
    clFinish(device_comm_queue);

    c1 = clock();
    printf ("\telapsed CPU CLOCKS:        %f sec\n", (float) (c1-c0)/1000);

    ocl_copy_back_to_host_real(result, dest, M*N);


    clReleaseMemObject(device_array_1);
    clReleaseMemObject(result);

    clReleaseKernel(OpenCLfunction);
    clReleaseProgram(OpenCLProgram);
}
