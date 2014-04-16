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

 This is an "offline" OpenCL compiler. "offline"
 in a sense that it is not used directly for executing
 a kernel or OpenCL program. This is used to test-compile
 (still JIT) the OpenCL code before the actuall simulation.
 This can detect errors in OpenCL code which would otherwise
 will be caught at simulation time.

 It also provides the built binary format of the OpenCL
 code for further use (No need to build again).

 See the header file for more comments.

 Mahder.Gebremedhin@liu.se  2012-03-31

*/


#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <sys/stat.h>
// #include "omc_ocl_common_header.h"

#include <stdio.h>
#ifdef __APPLE__
#include <OpenCL/cl.h>
#else
#include <CL/cl.h>
#endif


cl_command_queue device_comm_queue;
cl_context  device_context;
cl_device_id ocl_device;

int default_ocl_device = 0;

#define MAX_DEVICE 4

enum ocl_error {OCL_BUILD_PROGRAM, OCL_CREATE_KERNEL, OCL_CREATE_BUFFER, OCL_CREATE_CONTEXT,
                OCL_CREATE_COMMAND_QUEUE, OCL_SET_KER_ARGS, OCL_ENQUE_ND_RANGE_KERNEL, OCL_COPY_DEV_TO_DEV,
                OCL_COPY_HOST_TO_DEV, OCL_COPY_DEV_TO_HOST, OCL_REALEASE_MEM_OBJECT};



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


void ocl_clean_up(){
    if(device_context){clReleaseContext(device_context); device_context = NULL;}
    if(device_comm_queue){clReleaseCommandQueue(device_comm_queue); device_comm_queue=NULL;}
}

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
            printf("%d CL_DEVICE_LOCAL_MEM_SIZE :\t%lu KB\n", i, mem2/1024);
            clGetDeviceInfo(ocl_device, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(cl_ulong), &mem2, NULL);
            printf("%d CL_DEVICE_GLOBAL_MEM_SIZE: %lu MB\n", i, mem2/1024/1024);
            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_MEM_ALLOC_SIZE, sizeof(cl_ulong), &mem2, NULL);
            printf("%d CL_DEVICE_MAX_MEM_ALLOC_SIZE: %lu MB\n", i, mem2/1024/1024);
            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_PARAMETER_SIZE, sizeof(size_t), &arg_nr, NULL);
            printf("%d CL_DEVICE_MAX_PARAMETER_SIZE: %lu MB\n", i, arg_nr);

            clGetDeviceInfo(ocl_device, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(size_t), &arg_nr, NULL);
            printf("%d CL_DEVICE_MAX_WORK_GROUP_SIZE: %lu \n", i, arg_nr);

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

    return;
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

void ocl_initialize(){
    if (!device_comm_queue){
        if(!ocl_device){
            ocl_get_device();
        }
        ocl_create_context_and_comm_queue();
    }

    // setenv("CUDA_CACHE_DISABLE", "1", 1);
}



// Main function
// *********************************************************************
int main(int argc, char **argv)
{


    if (!device_comm_queue)
        ocl_initialize();

    const char* program_source;

    program_source = load_source_file(argv[1]);


    cl_program ocl_program = clCreateProgramWithSource(device_context, 1,
        (const char**)&program_source, NULL, NULL);
    printf("********** program created.\n");



    // Build the program (OpenCL JIT compilation)
    char options[100];
    const char* flags = "-I\"";
    const char* OMHOME = getenv("OPENMODELICAHOME");
    const char* OMINCL = "/include/omc\"";
    const char* OMBIN = "/bin\"";

    if ( OMHOME != NULL )
    {
        strcpy(options, flags);
        strcat(options, OMHOME);
        strcat(options, OMINCL);
        strcat(options, " -I\"");
        strcat(options, OMHOME);
        strcat(options, OMBIN);
        printf("Building OpenCL code with flags %s\n",options);
        cl_int err;
        err = clBuildProgram(ocl_program, 0, NULL, options, NULL, NULL);
        ocl_error_check(OCL_BUILD_PROGRAM, err);

        size_t size;
        clGetProgramBuildInfo(ocl_program, ocl_device, CL_PROGRAM_BUILD_LOG,        // Get build log size
                                  0, NULL, &size);
        char * log = (char*)malloc(size);
        clGetProgramBuildInfo(ocl_program,ocl_device,CL_PROGRAM_BUILD_LOG,size,log, NULL);
        printf("\t\tCL_PROGRAM_BUILD_LOG:  \t%s\n", log);
        free(log);

        if(err){
            printf("Errors detected in compilation of OpenCL code:\n");
            exit(1);
        }
        else
            printf("Program built successfuly.\n");

        //if no error create the binary
        clGetProgramInfo(ocl_program, CL_PROGRAM_BINARY_SIZES,
        sizeof(size_t), &size, NULL);
        unsigned char * binary = (unsigned char*)malloc(size);
        printf("Size of program binary :\t%d\n",size);
        clGetProgramInfo(ocl_program, CL_PROGRAM_BINARIES, sizeof(size_t), &binary, NULL);
        printf("Program binary retrived.\n");

        const char* binary_ext = ".bin";
        char* binary_name = strcat(argv[1],binary_ext);
        printf("binary file name %s\n", binary_name);
        FILE * cache;
        cache = fopen(binary_name, "wb");
        fwrite(binary, sizeof(char), size, cache);
        fclose(cache);
        //free(binary);



        err = 0;
        cl_program newprogram = clCreateProgramWithBinary(device_context, 1, &ocl_device, &size, (const unsigned char **)&binary, NULL, &err);
        if(!err)
            printf("Program created from binary\n");
        else{
            switch (err){
                case CL_INVALID_CONTEXT:
                    printf("Error building program:\n");
                    printf("CL_INVALID_CONTEXT \n");
                    break;
                case CL_INVALID_VALUE:
                    printf("Error building program:\n");
                    printf("CL_INVALID_VALUE \n");
                    break;
                case CL_INVALID_DEVICE:
                    printf("Error building program:\n");
                    printf("CL_INVALID_DEVICE \n");
                    break;
                case CL_INVALID_BINARY:
                    printf("Error building program:\n");
                    printf("CL_INVALID_BINARY \n");
                    break;
                case CL_OUT_OF_HOST_MEMORY:
                    printf("Error building program:\n");
                    printf("CL_OUT_OF_HOST_MEMORY \n");
                    break;
            }
        }




        return 0;

   }
   else
   {
       printf("Couldn't find OPENMODELICAHOME!\n");
       exit(1);
   }




    ocl_clean_up();


    return 0;
}








