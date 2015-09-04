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

 See the header file for more comments.

 Mahder.Gebremedhin@liu.se  2012-03-31

*/

#include "omc_ocl_util.h"


cl_command_queue device_comm_queue = NULL;
cl_context  device_context = NULL;
cl_device_id ocl_device = NULL;



modelica_integer MAX_THREADS_WORKGROUP = 0;
modelica_integer WORK_DIM = 0;
size_t GLOBAL_SIZE[3];
size_t LOCAL_SIZE[3];

#if defined(__MINGW32__) || defined(_MSC_VER)
int setenv(const char* envname, const char* envvalue, int overwrite)
{
  int res;
  char *temp = (char*)malloc(strlen(envname)+strlen(envvalue)+2);
  sprintf(temp,"%s=%s", envname, envvalue);
  res = _putenv(temp);
  free(temp);
  return res;
}
#endif

char* load_source_file(const char* file_name){
    char* source = NULL;
    FILE* f;
    struct stat statbuf;

    f = fopen(file_name, "rb");
    if (!f){
        printf("OpenCL kernel file \"%s\" not found!", file_name);
        ocl_clean_up();
        exit(1);
    }

    stat(file_name, &statbuf);
    source = (char*)malloc(statbuf.st_size + 1);
    fread(source, statbuf.st_size + 1, 1, f);
    source[statbuf.st_size] = '\0';

    return source;
}


void ocl_get_device(){
    cl_uint nr_dev;
    cl_uint plat_id = -1;
    size_t arg_nr;
    clGetPlatformIDs(MAX_DEVICE, NULL, &nr_dev);

    //Get an OpenCL platform
    cl_platform_id* cpPlatform = new cl_platform_id[nr_dev];
    clGetPlatformIDs(nr_dev, cpPlatform, NULL);


    // If the default device id is given in to the Openmodelica compiler
    // Set our device to it.
    if (default_ocl_device)
    {
        // If the default device id is valid set our device to it.
        if(default_ocl_device >= 1 && default_ocl_device <= nr_dev)
        {
            plat_id = default_ocl_device;
        }
        // Not a valid id. set default_ocl_device=0 so that the next if can take care of it.
        else
        {
            printf("- The device id you provided to OMC is not valid.\n");
            printf("- Please select a valid OpenCL device number. \n");
            fflush(stdout);
            default_ocl_device = 0;
        }
    }


    // If the default device id is not given in to the Openmodelica compiler OR
    // If the given id was not valid then
    // Show the selection options to the user.
    if (!default_ocl_device)
    {
        printf("- %d OpenCL devices available.\n\n", nr_dev);

        for (unsigned int i = 1; i <= nr_dev; i++){
            char cBuffer[1024];
            cl_uint mem;
            cl_ulong mem2;


            clGetDeviceIDs(cpPlatform[i-1], CL_DEVICE_TYPE_ALL, 1, &ocl_device, NULL);


            clGetDeviceInfo(ocl_device, CL_DEVICE_NAME, sizeof(cBuffer), &cBuffer, NULL);
            printf("%d CL_DEVICE_NAME :\t\t%s\n", i, cBuffer);
            clGetDeviceInfo(ocl_device, CL_DRIVER_VERSION, sizeof(cBuffer), &cBuffer, NULL);
            printf("%d CL_DRIVER_VERSION :\t%s\n", i, cBuffer);
            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_COMPUTE_UNITS , sizeof(cl_uint), &mem, NULL);
            printf("%d CL_DEVICE_MAX_COMPUTE_UNITS :\t%d\n", i, mem);
            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_CLOCK_FREQUENCY , sizeof(cl_uint), &mem, NULL);
            printf("%d CL_DEVICE_MAX_CLOCK_FREQUENCY :\t%d\n", i,mem);
            clGetDeviceInfo(ocl_device, CL_DEVICE_LOCAL_MEM_SIZE, sizeof(cl_ulong), &mem2, NULL);
            printf("%d CL_DEVICE_LOCAL_MEM_SIZE :\t%I64d KB\n", i, mem2/1024);
            clGetDeviceInfo(ocl_device, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(cl_ulong), &mem2, NULL);
            printf("%d CL_DEVICE_GLOBAL_MEM_SIZE: %I64d MB\n", i, mem2/1024/1024);
            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_MEM_ALLOC_SIZE, sizeof(cl_ulong), &mem2, NULL);
            printf("%d CL_DEVICE_MAX_MEM_ALLOC_SIZE: %I64d MB\n", i, mem2/1024/1024);
            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_PARAMETER_SIZE, sizeof(size_t), &arg_nr, NULL);
            printf("%d CL_DEVICE_MAX_PARAMETER_SIZE: %d MB\n", i, arg_nr);

            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(size_t), &arg_nr, NULL);
            printf("%d CL_DEVICE_MAX_WORK_GROUP_SIZE: %d \n", i, arg_nr);
            MAX_THREADS_WORKGROUP = (modelica_integer)arg_nr;   //default number of threads is the max number of threads!

            clGetDeviceInfo(ocl_device, CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE  , sizeof(cl_uint), &mem, NULL);
            printf("%d CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE  : %d\n\n\n", i,mem);

            // MinGW needs fflush. They should put it in BIG LETTERS on A BIG BANNER!!
            fflush(stdout);
        }

        while(plat_id < 1 || plat_id > nr_dev)
        {
            printf("- Select your device:      ");     fflush(stdout);
            scanf ("%d",&plat_id);

            if(plat_id < 1 || plat_id > nr_dev)
                printf("- Please select a valid OpenCL device number. \n");
        };

    }



    clGetDeviceIDs(cpPlatform[plat_id - 1], CL_DEVICE_TYPE_ALL, 1, &ocl_device, NULL);
    clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(size_t), &arg_nr, NULL);

#if BE_OCL_VERBOSE
    printf("Using CL_DEVICE_MAX_WORK_GROUP_SIZE: %d \n", arg_nr);
#endif

    //default number of threads is the max number of threads!
    MAX_THREADS_WORKGROUP = (modelica_integer)arg_nr;
    GLOBAL_SIZE[0] = MAX_THREADS_WORKGROUP;

    return;
}



void ocl_initialize(){
    timeval t1, t2;
    double elapsedTime;
    gettimeofday(&t1, NULL);

    if (!device_comm_queue){
        if(!ocl_device){
            ocl_get_device();
        }
        ocl_create_context_and_comm_queue();
        ocl_build_p_from_src();
    }

    gettimeofday(&t2, NULL);

#if BE_OCL_VERBOSE
    elapsedTime = (t2.tv_sec - t1.tv_sec) * 1000.0;      // sec to ms
    elapsedTime += (t2.tv_usec - t1.tv_usec) / 1000.0;   // us to ms
    printf ("\tOpenCL initialization :        %lf ms\n", elapsedTime);
#endif

    setenv("CUDA_CACHE_DISABLE", "1", 1);
}

void ocl_create_context_and_comm_queue(){
    // Create a context to run OpenCL on the OCL-enabled Device
    cl_int err;

#if BE_OCL_VERBOSE
    printf("--- Creating OpenCL context");
#endif

    device_context = clCreateContext(0, 1, &ocl_device, NULL, NULL, &err);

    ocl_error_check(OCL_CREATE_CONTEXT, err);

    // Get the list of OCL_ devices associated with this context
    size_t ParmDataBytes;
    clGetContextInfo(device_context, CL_CONTEXT_DEVICES, 0, NULL, &ParmDataBytes);
    cl_device_id* OCL_Devices = (cl_device_id*)malloc(ParmDataBytes);
    clGetContextInfo(device_context, CL_CONTEXT_DEVICES, ParmDataBytes, OCL_Devices, NULL);

    // Create a command-queue on the first OCL_ device
#if BE_OCL_VERBOSE
    printf("--- Creating OpenCL command queue");
#endif

    device_comm_queue = clCreateCommandQueue(device_context,
        OCL_Devices[0], 0, &err);

    ocl_error_check(OCL_CREATE_COMMAND_QUEUE, err);

    free(OCL_Devices);
}

void ocl_build_p_from_src(){

    // Create OpenCL program with source code

    const char* program_source;


    program_source = load_source_file(omc_ocl_kernels_source);


#if BE_OCL_VERBOSE
    printf("--- Creating OpenCL program");
#endif
    // omc_ocl_program declared in omc_ocl_util.h
    omc_ocl_program = clCreateProgramWithSource(device_context, 1,
        (const char**)&program_source, NULL, NULL);

#if BE_OCL_VERBOSE
    printf("\t\t\t - OK.\n");
#endif

    free((void*)program_source);



    // Check for OpenModelica env variable.
    const char* OMHOME = getenv("OPENMODELICAHOME");
    if ( OMHOME == NULL )
    {
       printf("Couldn't find OPENMODELICAHOME!\n");
       exit(1);
    }


    // Build the program (OpenCL JIT compilation).
#if BE_OCL_VERBOSE
    printf("--- Building OpenCL program \n");
#endif

    char options[100];
    const char* flags = "-I\"";
    const char* OMEXT = "/include/omc/c/\"";


    strcpy(options, flags);
    strcat(options, OMHOME);
    strcat(options, OMEXT);

#if BE_OCL_VERBOSE
    printf("\t :Using flags %s\n",options);
#endif

    // Build the OpenCL program.
    cl_int err = 0;
    err = clBuildProgram(omc_ocl_program, 0, NULL, options, NULL, NULL);
    ocl_error_check(OCL_BUILD_PROGRAM, err);

    // Get build log size.
    size_t size;
    clGetProgramBuildInfo(omc_ocl_program, ocl_device, CL_PROGRAM_BUILD_LOG,
                              0, NULL, &size);

    // Get the build log.
    char * log = (char*)malloc(size);
    clGetProgramBuildInfo(omc_ocl_program,ocl_device,CL_PROGRAM_BUILD_LOG,size,log, NULL);

    if(err){
        printf("Build failed: Errors detected in compilation of OpenCL code:\n");
        printf("CL_PROGRAM_BUILD_LOG:  \n%s\n", log);
        free(log);
        exit(1);
    }

    free(log);

}

cl_kernel ocl_create_kernel(cl_program program, const char* kernel_name){

    if (!device_comm_queue)
        ocl_initialize();

    cl_kernel kernel;
    cl_int err;
    kernel = clCreateKernel(program, kernel_name, &err);
    ocl_error_check(OCL_CREATE_KERNEL, err);
    return kernel;
}

void ocl_set_kernel_args(cl_kernel kernel, int count, ...){

    cl_int err;
    va_list arguments;
    va_start(arguments, count);
    for (int i = 0; i < count; i++)
    {
        cl_mem tmp = va_arg(arguments, cl_mem);
        err = clSetKernelArg(kernel, i, sizeof(cl_mem),(void*)&tmp);
        //#ifdef SHOW_ARG_SET_ERRORS
        ocl_error_check(OCL_SET_KER_ARGS, err);
        if(err){
          printf("Error: setting argument nr:  %d\n", i + 1);
          exit(1);
        }
        //#endif
    }
    va_end(arguments);
}

void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, cl_mem in_arg){

    cl_int err;
    err = clSetKernelArg(kernel, arg_nr, sizeof(cl_mem),(void*)&in_arg);

    //#ifdef SHOW_ARG_SET_ERRORS
    ocl_error_check(OCL_SET_KER_ARGS, err);
    if(err){
       printf("Error: setting argument nr:  %d\n", arg_nr + 1);
       exit(1);
    }
    //#endif

}

void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, modelica_integer in_arg){

    cl_int err;
    err = clSetKernelArg(kernel, arg_nr, sizeof(modelica_integer),(void*)&in_arg);

    //#ifdef SHOW_ARG_SET_ERRORS
    ocl_error_check(OCL_SET_KER_ARGS, err);
    if(err){
       printf("Error: setting argument nr:  %d\n", arg_nr + 1);
       exit(1);
    }
    //#endif

}

void ocl_set_kernel_arg(cl_kernel kernel, int arg_nr, modelica_real in_arg){

    cl_int err;
    err = clSetKernelArg(kernel, arg_nr, sizeof(modelica_real),(void*)&in_arg);

    //#ifdef SHOW_ARG_SET_ERRORS
    ocl_error_check(OCL_SET_KER_ARGS, err);
    if(err){
       printf("Error: setting argument nr:  %d\n", arg_nr + 1);
       exit(1);
    }
    //#endif

}

void ocl_set_local_kernel_arg(cl_kernel kernel, int arg_nr, size_t in_size){

    cl_int err;

    // Allocate the memory in local space for the data
    err = clSetKernelArg(kernel, arg_nr, in_size, NULL);
    ocl_error_check(OCL_SET_KER_ARGS, err);
    if(err){
       printf("Error: setting argument nr:  %d. Local variable\n", arg_nr + 1);
       exit(1);
    }

}


void ocl_execute_kernel(cl_kernel kernel){

    cl_int err = 0;

    timeval t1, t2;
    double elapsedTime;
    gettimeofday(&t1, NULL);

    if (WORK_DIM == 0){
        size_t GlobalSize[1] = {GLOBAL_SIZE[0]}; // one dimensional Range
        //automatic division to workgroups by OpenCL.
        err = clEnqueueNDRangeKernel(device_comm_queue, kernel, 1, NULL,
        GlobalSize, NULL, 0, NULL, NULL);
    }

    else if (WORK_DIM == 1){
        size_t GlobalSize[1] = {GLOBAL_SIZE[0]}; // one dimensional Range
        size_t LocalSize[1] = {LOCAL_SIZE[0]}; // one dimensional Range
        err = clEnqueueNDRangeKernel(device_comm_queue, kernel, 1, NULL,
        GlobalSize, LocalSize, 0, NULL, NULL);
    }

    else if (WORK_DIM == 2){
        size_t GlobalSize[2] = {GLOBAL_SIZE[0], GLOBAL_SIZE[1]}; // two dimensional Range
        size_t LocalSize[2] = {LOCAL_SIZE[0], LOCAL_SIZE[1]}; // two dimensional Range

        //printf("Setting 2 dimensional arrangment with local size x = %d, local size y = %d, global size x = %d, global size x = %d \n",
        //LocalSize[0], LocalSize[1], GlobalSize[0], GlobalSize[1]);

        err = clEnqueueNDRangeKernel(device_comm_queue, kernel, 2, NULL,
        GlobalSize, LocalSize, 0, NULL, NULL);
    }

    else if (WORK_DIM == 3){
        size_t GlobalSize[3] = {GLOBAL_SIZE[0], GLOBAL_SIZE[1], GLOBAL_SIZE[2]}; // three dimensional Range
        size_t LocalSize[3] = {LOCAL_SIZE[0], LOCAL_SIZE[1], LOCAL_SIZE[2]}; // three dimensional Range
        err = clEnqueueNDRangeKernel(device_comm_queue, kernel, 3, NULL,
        GlobalSize, LocalSize, 0, NULL, NULL);
    }

    clFinish(device_comm_queue);
    ocl_error_check(OCL_ENQUE_ND_RANGE_KERNEL, err);


    gettimeofday(&t2, NULL);
#if BE_OCL_VERBOSE
    elapsedTime = (t2.tv_sec - t1.tv_sec) * 1000.0;      // sec to ms
    elapsedTime += (t2.tv_usec - t1.tv_usec) / 1000.0;   // us to ms
    printf ("\tKernel Execution      :        %lf ms\n", elapsedTime);
#endif


    if(err) exit(1);

}


void ocl_set_num_threads(integer_array_t global_threads_in, integer_array_t local_threads_in){

    WORK_DIM = global_threads_in.dim_size[0];

    for (modelica_integer i=0; i < WORK_DIM; i++){
        GLOBAL_SIZE[i] = (size_t)(*integer_array_element_addr_c99_1(&global_threads_in, 1, i+1));
        LOCAL_SIZE[i] = (size_t)(*integer_array_element_addr_c99_1(&local_threads_in, 1, i+1));
    }

}

void ocl_set_num_threads(modelica_integer global_threads_in, modelica_integer local_threads_in){

    WORK_DIM = 1;
    GLOBAL_SIZE[0] = global_threads_in;
    LOCAL_SIZE[0] = local_threads_in;
}


void ocl_set_num_threads(modelica_integer global_threads_in){

//doesn't mean work_dim will be zero. It is zero here to represent the fact that
//OpenCL will be responsible for arrangment of WORKITEMS into WORKGROUPS.
    WORK_DIM = 0;

    if(global_threads_in == 0)
        GLOBAL_SIZE[0] = MAX_THREADS_WORKGROUP;
    else
        GLOBAL_SIZE[0] = global_threads_in;
}

modelica_integer ocl_get_num_threads(){

    //TODO: fix to return the number of threads in each dimension
    return 0;
}



void ocl_clean_up(){
    if(device_context){clReleaseContext(device_context); device_context = NULL;}
    if(device_comm_queue){clReleaseCommandQueue(device_comm_queue); device_comm_queue=NULL;}
}


void ocl_error_check(int operation, cl_int error_code){

    switch(operation){
        case OCL_BUILD_PROGRAM:
            switch (error_code){
                case CL_INVALID_PROGRAM:
                    printf("Error building program:\n");
                    printf("CL_INVALID_PROGRAM \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error building program:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_DEVICE:
                    printf("Error building program:\n");
                    printf("CL_INVALID_DEVICE \n");
                    break;
                case CL_BUILD_PROGRAM_FAILURE:
                    printf("Error building program:\n");
                    printf("CL_BUILD_PROGRAM_FAILURE \n");
                    break;
                case CL_COMPILER_NOT_AVAILABLE:
                    printf("Error building program:\n");
                    printf("CL_COMPILER_NOT_AVAILABLE \n");
                    break;
                case CL_INVALID_BINARY:
                    printf("Error building program:\n");
                    printf("CL_INVALID_BINARY \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error building program:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
#if BE_OCL_VERBOSE
                    printf("\t\t\t\t\t\t - OK.\n");
#endif
                    break;
                default:
                    printf("Possible unknown error in : OCL_BUILD_PROGRAM\n");
            }
            break;

        case OCL_CREATE_KERNEL:
            switch (error_code){
                case CL_INVALID_PROGRAM:
                    printf("Error creating Kernel:\n");
                    printf("CL_INVALID_PROGRAM \n");
                    break;
                case CL_INVALID_PROGRAM_EXECUTABLE:
                    printf("Error creating Kernel:\n");
                    printf("CL_INVALID_PROGRAM_EXECUTABLE \n");
                    break;
                case CL_INVALID_KERNEL_NAME:
                    printf("Error creating Kernel:\n");
                    printf("CL_INVALID_KERNEL_NAME \n");
                    exit(1);
                    break;
                case CL_INVALID_KERNEL_DEFINITION:
                    printf("Error creating Kernel:\n");
                    printf("CL_INVALID_KERNEL_DEFINITION \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error creating Kernel:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error creating Kernel:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Kernel created.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_CREATE_KERNEL\n");
            }
            break;

        case OCL_CREATE_BUFFER:

            switch (error_code){
                case CL_INVALID_CONTEXT:
                    printf("Error allocating buffer on device\n");
                    printf("CL_INVALID_CONTEXT \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error allocating buffer on device\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_BUFFER_SIZE:
                    printf("Error allocating buffer on device\n");
                    printf("CL_INVALID_BUFFER_SIZE \n");
                    break;
                case CL_INVALID_HOST_PTR:
                    printf("Error allocating buffer on device\n");
                    printf("CL_INVALID_HOST_PTR \n");
                    break;
                case CL_MEM_OBJECT_ALLOCATION_FAILURE:
                    printf("Error allocating buffer on device\n");
                    printf("CL_MEM_OBJECT_ALLOCATION_FAILURE \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error allocating buffer on device\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Buffer allocated on device.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_CREATE_BUFFER\n");
            }
            break;

        case OCL_CREATE_CONTEXT:
            switch (error_code){
                case CL_INVALID_PLATFORM:
                    printf("Error creating context:\n");
                    printf("CL_INVALID_PLATFORM \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error creating context:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_DEVICE:
                    printf("Error creating context:\n");
                    printf("CL_INVALID_DEVICE \n");
                    break;
                case CL_DEVICE_NOT_AVAILABLE:
                    printf("Error creating context:\n");
                    printf("CL_DEVICE_NOT_AVAILABLE \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error creating context:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
#if BE_OCL_VERBOSE
                    printf("\t\t\t - OK.\n");
#endif
                    break;
                default:
                    printf("Possible unknown error in : OCL_CREATE_CONTEXT\n");
            }
            break;

        case OCL_CREATE_COMMAND_QUEUE:
            switch (error_code){
                case CL_INVALID_CONTEXT:
                    printf("Error creating command queue:\n");
                    printf("CL_INVALID_CONTEXT \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error creating command queue:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_DEVICE:
                    printf("Error creating command queue:\n");
                    printf("CL_INVALID_DEVICE \n");
                    break;
                case CL_INVALID_QUEUE_PROPERTIES:
                    printf("Error creating command queue:\n");
                    printf("CL_INVALID_QUEUE_PROPERTIES \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error creating command queue:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
#if BE_OCL_VERBOSE
                    printf("\t\t - OK.\n");
#endif
                    break;
                default:
                    printf("Possible unknown error in : OCL_CREATE_COMMAND_QUEUE\n");
            }
            break;

        case OCL_SET_KER_ARGS:
            switch (error_code){
                case CL_INVALID_KERNEL:
                    printf("Error setting kernel arguments:\n");
                    printf("CL_INVALID_KERNEL \n");
                    break;
                case CL_INVALID_ARG_INDEX:
                    //printf("Error setting kernel arguments:\n");
                    //printf("CL_INVALID_ARG_INDEX \n");
                    break;
                case CL_INVALID_ARG_VALUE:
                    printf("Error setting kernel arguments:\n");
                    printf("CL_INVALID_ARG_VALUE \n");
                    break;
                case CL_INVALID_MEM_OBJECT:
                    printf("Error setting kernel arguments:\n");
                    printf("CL_INVALID_MEM_OBJECT \n");
                    break;
                case CL_INVALID_SAMPLER:
                    printf("Error setting kernel arguments:\n");
                    printf("CL_INVALID_SAMPLER \n");
                    break;
                case CL_INVALID_ARG_SIZE:
                    printf("Error setting kernel arguments:\n");
                    printf("CL_INVALID_ARG_SIZE \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Successfuly set Kernel arguments.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_CREATE_COMMAND_QUEUE\n");
            }
            break;

        case OCL_ENQUE_ND_RANGE_KERNEL:
            switch (error_code){
                case CL_INVALID_PROGRAM_EXECUTABLE:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_PROGRAM_EXECUTABLE \n");
                    break;
                case CL_INVALID_COMMAND_QUEUE:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_COMMAND_QUEUE \n");
                    break;
                case CL_INVALID_KERNEL:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_KERNEL \n");
                    break;
                case CL_INVALID_CONTEXT:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_CONTEXT \n");
                    break;
                case CL_INVALID_KERNEL_ARGS:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_KERNEL_ARGS \n");
                    break;
                case CL_INVALID_WORK_DIMENSION:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_WORK_DIMENSION \n");
                    break;
                case CL_INVALID_WORK_GROUP_SIZE:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_WORK_GROUP_SIZE \n");
                    break;
                case CL_INVALID_WORK_ITEM_SIZE:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_WORK_ITEM_SIZE \n");
                    break;
                case CL_INVALID_GLOBAL_OFFSET:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_GLOBAL_OFFSET \n");
                    break;
                case CL_OUT_OF_RESOURCES:
                    printf("Error enquing range kernel:\n");
                    printf("CL_OUT_OF_RESOURCES \n");
                    break;
                case CL_MEM_OBJECT_ALLOCATION_FAILURE:
                    printf("Error enquing range kernel:\n");
                    printf("CL_MEM_OBJECT_ALLOCATION_FAILURE \n");
                    break;
                case CL_INVALID_EVENT_WAIT_LIST:
                    printf("Error enquing range kernel:\n");
                    printf("CL_INVALID_EVENT_WAIT_LIST \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error enquing range kernel:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Succesfuly enqued range Kernel.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_ENQUE_ND_RANGE_KERNEL\n");
            }
            break;

            case OCL_COPY_DEV_TO_DEV:
            switch (error_code){
                case CL_INVALID_COMMAND_QUEUE:
                    printf("Error copying device to device:\n");
                    printf("CL_INVALID_COMMAND_QUEUE \n");
                    break;
                case CL_INVALID_CONTEXT:
                    printf("Error copying device to device:\n");
                    printf("CL_INVALID_CONTEXT \n");
                    break;
                case CL_INVALID_MEM_OBJECT:
                    printf("Error copying device to device:\n");
                    printf("CL_INVALID_MEM_OBJECT \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error copying device to device:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_EVENT_WAIT_LIST:
                    printf("Error copying device to device:\n");
                    printf("CL_INVALID_EVENT_WAIT_LIST \n");
                    break;
                case CL_MEM_COPY_OVERLAP:
                    printf("Error copying device to device:\n");
                    printf("CL_MEM_COPY_OVERLAP \n");
                    break;
                case CL_MEM_OBJECT_ALLOCATION_FAILURE:
                    printf("Error copying device to device:\n");
                    printf("CL_MEM_OBJECT_ALLOCATION_FAILURE \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error copying device to device:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Successfuly copied data from dev mem to dev mem.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_COPY_DEV_TO_DEV\n");
            }
            break;

            case OCL_COPY_HOST_TO_DEV:
            switch (error_code){
                case CL_INVALID_COMMAND_QUEUE:
                    printf("Error copying host to device:\n");
                    printf("CL_INVALID_COMMAND_QUEUE \n");
                    break;
                case CL_INVALID_CONTEXT:
                    printf("Error copying host to device:\n");
                    printf("CL_INVALID_CONTEXT \n");
                    break;
                case CL_INVALID_MEM_OBJECT:
                    printf("Error copying host to device:\n");
                    printf("CL_INVALID_MEM_OBJECT \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error copying host to device:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_EVENT_WAIT_LIST:
                    printf("Error copying host to device:\n");
                    printf("CL_INVALID_EVENT_WAIT_LIST \n");
                    break;
                case CL_MEM_OBJECT_ALLOCATION_FAILURE:
                    printf("Error copying host to device:\n");
                    printf("CL_MEM_OBJECT_ALLOCATION_FAILURE \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error copying host to device:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Successfuly copied data from host mem to dev mem.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_COPY_HOST_TO_DEV\n");
            }
            break;

            case OCL_COPY_DEV_TO_HOST:
            switch (error_code){
                case CL_INVALID_COMMAND_QUEUE:
                    printf("Error copying device to host:\n");
                    printf("CL_INVALID_COMMAND_QUEUE \n");
                    break;
                case CL_INVALID_CONTEXT:
                    printf("Error copying device to host:\n");
                    printf("CL_INVALID_CONTEXT \n");
                    break;
                case CL_INVALID_MEM_OBJECT:
                    printf("Error copying device to host:\n");
                    printf("CL_INVALID_MEM_OBJECT \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error copying device to host:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_EVENT_WAIT_LIST:
                    printf("Error copying device to host:\n");
                    printf("CL_INVALID_EVENT_WAIT_LIST \n");
                    break;
                case CL_MEM_OBJECT_ALLOCATION_FAILURE:
                    printf("Error copying device to host:\n");
                    printf("CL_MEM_OBJECT_ALLOCATION_FAILURE \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error copying device to host:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Successfuly copied data from dev mem to host mem.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_COPY_DEV_TO_HOST\n");
            }
            break;

            case OCL_REALEASE_MEM_OBJECT:
            switch (error_code){
                case CL_INVALID_MEM_OBJECT:
                    printf("Error freeing device memory object:\n");
                    printf("CL_INVALID_MEM_OBJECT \n");
                    break;
                case CL_SUCCESS:
                    //printf("********** Successfuly copied data from dev mem to host mem.\n");
                    break;
                default:
                    printf("Possible unknown error in : OCL_COPY_DEV_TO_HOST\n");
            }
            break;


    }
}
