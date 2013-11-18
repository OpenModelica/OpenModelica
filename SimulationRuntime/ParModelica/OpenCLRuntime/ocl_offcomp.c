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
#include "omc_ocl_util.h"
#include "omc_ocl_common_header.h"


extern cl_command_queue device_comm_queue;
extern cl_context  device_context;
extern cl_device_id ocl_device;


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
    const char* flags = "-g -w -I\"";
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








