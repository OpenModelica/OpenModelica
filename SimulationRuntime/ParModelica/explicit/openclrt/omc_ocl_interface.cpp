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

 See the header file for more comments.

 Mahder.Gebremedhin@liu.se  2012-03-31

*/



#include <omc_ocl_interface.h>


size_t modelica_array_nr_of_elements(base_array_t *a){
    int i;
    size_t nr_of_elements = 1;
    for (i = 0; i < a->ndims; ++i) {
        nr_of_elements *= a->dim_size[i];
    }
    return nr_of_elements;
}

size_t device_array_nr_of_elements(device_array *a){
    int i;
    size_t nr_of_elements = 1;
    for (i = 1; i <= a->info[0]; ++i) {
        nr_of_elements *= a->info[i];
    }
    return nr_of_elements;
}


static inline modelica_real *real_ptrget(real_array_t *a, size_t i){
    return ((modelica_real *) a->data) + i;
}

static inline modelica_integer *integer_ptrget(integer_array_t *a, size_t i){
    return ((modelica_integer *) a->data) + i;
}


int array_shape_eq(const base_array_t *a, const device_array *b)
{
    int i;

    if(a->ndims != b->info[0]) {
        fprintf(stderr, "a->ndims != b->ndims, %d != %ld\n", a->ndims, b->info[0]);
        return 0;
    }

    for(i = 0; i < a->ndims; ++i) {
        if(a->dim_size[i] != b->info[i+1]) {
            fprintf(stderr, "a->dim_size[%d] != b->dim_size[%d], %d != %d\n",
                    i, i, (int) a->dim_size[i], (int) b->info[i+1]);
            return 0;
        }
    }

    return 1;
}

int array_shape_eq(const device_array *a, const device_array *b)
{
    int i;

    if(a->info[0] != b->info[0]) {
        fprintf(stderr, "a->ndims != b->ndims, %ld != %ld\n", a->info[0], b->info[0]);
        return 0;
    }

    for(i = 0; i < a->info[0]; ++i) {
        if(a->info[i+1] != b->info[i+1]) {
            fprintf(stderr, "a->dim_size[%d] != b->dim_size[%d], %d != %d\n",
                    i, i, (int) a->info[i+1], (int) b->info[i+1]);
            return 0;
        }
    }

    return 1;
}


/* One based index*/
size_t ocl_calc_base_index_va(base_array_t *source, int ndims, va_list ap){
    int i;
    size_t index;
    int dim_i;

    index = 0;
    for (i = 0; i < ndims; ++i) {
        dim_i = va_arg(ap, modelica_integer) - 1;
        index = index * source->dim_size[i] + dim_i;
    }

    return index;
}




//functions for allocating device arrays. these should be the entry points to allocate
//device arrays. the first one is a base array which only initializes the info of the array.
//the rest allocate the space for the actuall data
size_t alloc_device_base_array(device_array *dest, int ndims, va_list ap){

    int i;

    dest->info = (modelica_integer*)malloc((ndims + 1)*sizeof(modelica_integer));
    dest->info[0] = ndims;

    for (i = 1; i < ndims + 1; i++) {
        dest->info[i] = va_arg(ap, modelica_integer);
    }
    va_end(ap);
    return device_array_nr_of_elements(dest);

}

//entry point for allocating integer array on device
void alloc_integer_array(device_integer_array *dest, int ndims, ...){

    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_device_base_array(dest,ndims,ap);
    va_end(ap);
    dest->data = ocl_device_alloc(elements*sizeof(modelica_integer));
    dest->info_dev = ocl_device_alloc_init(dest->info,
        (ndims+1)*sizeof(modelica_integer));

}

//entry point for allocating real array on device
void alloc_real_array(device_real_array *dest, int ndims, ...){

    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_device_base_array(dest,ndims,ap);
    va_end(ap);
    dest->data = ocl_device_alloc(elements*sizeof(modelica_real));
    dest->info_dev = ocl_device_alloc_init(dest->info,
        (ndims+1)*sizeof(modelica_integer));

}

//entry point for allocating LOCAL real array on device
void alloc_device_local_real_array(device_local_real_array *dest, int ndims, ...){

    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_device_base_array(dest,ndims,ap);
    va_end(ap);
    // dest->data = ocl_device_alloc(elements*sizeof(modelica_real));
    // dest->info_dev = ocl_device_alloc_init(dest->info,
        // (ndims+1)*sizeof(modelica_integer));

}


void free_device_array(device_array* dest){
    cl_int err;
    err = clReleaseMemObject(dest->data);
    ocl_error_check(OCL_REALEASE_MEM_OBJECT, err);
    err = clReleaseMemObject(dest->info_dev);
    ocl_error_check(OCL_REALEASE_MEM_OBJECT, err);
    free(dest->info);
}

// This is just overloaded to allow the device arrays
// be freed properly.
void free_device_array(base_array_t* dest){
}




void copy_real_array_data(device_real_array dev_array, real_array_t* host_array_ptr){
    assert(array_shape_eq(host_array_ptr, &dev_array));
    int nr_of_elm = device_array_nr_of_elements(&dev_array);
    ocl_copy_back_to_host_real(dev_array.data, (modelica_real* )host_array_ptr->data, nr_of_elm);
}

void copy_real_array_data(real_array_t host_array, device_real_array* dev_array_ptr){
    assert(array_shape_eq(&host_array, dev_array_ptr));
    int nr_of_elm = modelica_array_nr_of_elements(&host_array);
    ocl_copy_to_device_real(dev_array_ptr->data, (modelica_real* )host_array.data, nr_of_elm);
}

void copy_real_array_data(device_real_array dev_array1, device_real_array* dev_array_ptr2){
    assert(array_shape_eq(&dev_array1, dev_array_ptr2));
    int nr_of_elm = device_array_nr_of_elements(&dev_array1);
    ocl_copy_device_to_device_real(dev_array1.data, dev_array_ptr2->data, nr_of_elm);
}

void copy_integer_array_data(device_integer_array dev_array, integer_array_t* host_array_ptr){
    assert(array_shape_eq(host_array_ptr, &dev_array));
    int nr_of_elm = device_array_nr_of_elements(&dev_array);
    ocl_copy_back_to_host_integer(dev_array.data, (modelica_integer* )host_array_ptr->data, nr_of_elm);
}

void copy_integer_array_data(integer_array_t host_array, device_integer_array* dev_array_ptr){
    assert(array_shape_eq(&host_array, dev_array_ptr));
    int nr_of_elm = modelica_array_nr_of_elements(&host_array);
    ocl_copy_to_device_integer(dev_array_ptr->data, (modelica_integer* )host_array.data, nr_of_elm);
}


void copy_integer_array_data(device_integer_array dev_array1, device_integer_array* dev_array_ptr2){
    assert(array_shape_eq(&dev_array1, dev_array_ptr2));
    int nr_of_elm = device_array_nr_of_elements(&dev_array1);
    ocl_copy_device_to_device_integer(dev_array1.data, dev_array_ptr2->data, nr_of_elm);
}



// //functions used for copying scalars. Scalars in the normal(serial C) code genertation
// //of modelica are copied by assignment (a = b). However to be able to copy them b'n
// //GPU and host CPU we need to change the assignments to copy functions.
// void copy_assignment_helper_integer(modelica_integer* v1, modelica_integer* v2){
    // *v1 = *v2;
// }

// void copy_assignment_helper_integer(device_integer* v1, modelica_integer* v2){
    // ocl_copy_to_device_integer(*v1, (modelica_integer* )v2, 1);
// }

// void copy_assignment_helper_integer(modelica_integer* v1, device_integer* v2){
    // ocl_copy_back_to_host_integer(*v2, (modelica_integer* )v1, 1);
// }

// void copy_assignment_helper_integer(device_integer* v1, device_integer* v2){
    // ocl_copy_device_to_device_integer(*v2, *v1, 1);
// }

// void copy_assignment_helper_real(modelica_real* v1, modelica_real* v2){
    // *v1 = *v2;
// }

// void copy_assignment_helper_real(device_real* v1, modelica_real* v2){
    // ocl_copy_to_device_real(*v1, (modelica_real* )v2, 1);
// }

// void copy_assignment_helper_real(modelica_real* v1, device_real* v2){
    // ocl_copy_back_to_host_real(*v2, (modelica_real* )v1, 1);
// }

// void copy_assignment_helper_real(device_real* v1, device_real* v2){
    // ocl_copy_device_to_device_real(*v2, *v1, 1);
// }



//this function is added to solve a problem with a memory leak when returning arrays
//from functions. Arrays used to be assigned just like normal scalar variables. Which causes the
//allocated memory on the lhs to be lost when the pointer is replaced with the new one.
//this fixes the problem for parallel arrays. for serial arrays the memory is restored when the
//function returns(not dynamic allocation), So the only lose in serial case is visible just until
//the function returns.
void swap_and_release(device_array* lhs, device_array* rhs){
    clReleaseMemObject(lhs->data);
    clReleaseMemObject(lhs->info_dev);
    free(lhs->info);
    lhs->data = rhs->data;
    lhs->info_dev = rhs->info_dev;
    lhs->info = rhs->info;
}

//simple assignemnt works fine for srial arrays.
void swap_and_release(base_array_t* lhs, base_array_t* rhs){
    *lhs = *rhs;
}


//functions following here are just the same function(the one in real/integer_array.c/h) declared with different names
//this is done to be able to use the same generated code in normal c runtime and as well as in OpenCL kernels
//which, right now, doesn't support overloading or the stdarg standard library.
//even though the functions have the same body here they will have different body on the OpenCL counterparts

m_real* real_array_element_addr_c99_1(real_array_t* source,int ndims,...){
    va_list ap;
    m_real* tmp;

    va_start(ap,ndims);
    tmp = real_ptrget(source, ocl_calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}

m_real* real_array_element_addr_c99_2(real_array_t* source,int ndims,...){
    va_list ap;
    m_real* tmp;

    va_start(ap,ndims);
    tmp = real_ptrget(source, ocl_calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}

m_real* real_array_element_addr_c99_3(real_array_t* source,int ndims,...){
    va_list ap;
    m_real* tmp;

    va_start(ap,ndims);
    tmp = real_ptrget(source, ocl_calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}

m_integer* integer_array_element_addr_c99_1(integer_array_t* source,int ndims,...){
    va_list ap;
    m_integer* tmp;

    va_start(ap,ndims);
    tmp = integer_ptrget(source, ocl_calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}

m_integer* integer_array_element_addr_c99_2(integer_array_t* source,int ndims,...){
    va_list ap;
    m_integer* tmp;

    va_start(ap,ndims);
    tmp = integer_ptrget(source, ocl_calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}

m_integer* integer_array_element_addr_c99_3(integer_array_t* source,int ndims,...){
    va_list ap;
    m_integer* tmp;

    va_start(ap,ndims);
    tmp = integer_ptrget(source, ocl_calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}


//array dimension size functions.
modelica_integer size_of_dimension_real_array(device_real_array dev_arr, modelica_integer dim){
    return dev_arr.info[dim];
}

//array dimension size functions.
modelica_integer size_of_dimension_integer_array(device_integer_array dev_arr, modelica_integer dim){
    return dev_arr.info[dim];
}


/*
void print_array_info(device_real_array* arr){

    printf("nr of dims = %ld \n", arr->info[0]);

    for (int i = 1; i <= arr->info[0]; i++){
        printf("size of dim %d = %ld \n", i,arr->info[i]);
    }
    printf("array data pts to %d\n", arr->data);
}
*/

void print_array(real_array_t* arr){
  printf("\n\n");
  for(int q = 1; q < arr->dim_size[0]; q++){
    printf(" | %f", (*real_array_element_addr_c99_1(arr, 1, ((modelica_integer) q))));
  }
  printf("\n\n\n");
}

/*
void print_array(device_real_array* dev_arr){
  real_array_t arr;
  int nr_of_elm = device_array_nr_of_elements(dev_arr);
  alloc_real_array(&arr, 1, nr_of_elm);
  copy_real_array_data(dev_arr, &arr);
  print_array(&arr);
}
*/
