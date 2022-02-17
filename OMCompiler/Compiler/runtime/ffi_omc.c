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


#include "ffi.h"

#include <gc.h>

#include "systemimpl.h"
#include "meta/meta_modelica.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif

#define UNBOX_OFFSET 1

/* Function pointer type used by mk_array_exp to construct scalar expression */
typedef void* (*mk_exp_fn_t)(void*, void*);

enum ArgSpec {
  INPUT_ARG = 1,
  OUTPUT_ARG = 2,
  LOCAL_ARG = 3
};

struct Alignment
{
  size_t size;
  size_t *offsets;
  struct Alignment *fields;
  size_t field_count;
};

static void* increment_ptr(void *ptr, size_t bytes);
static int is_exp_pointer_type(void *exp);
static size_t array_dim_size(void *dim);
static size_t array_length(void *type);
static size_t array_scalar_count(void *arr);
static ffi_type* mk_ffi_struct_from_exp(void *exp);
static size_t size_of_type(void *type);
static size_t size_of_exp(void *exp, struct Alignment *align);
static void* unlift_array_type(void *type);

static void* mk_int_exp(void *ptr, void *type);
static void* mk_bool_exp(void *ptr, void *type);
static void* mk_real_exp(void *ptr, void *type);
static void* mk_string_exp(void *ptr, void *type);
static void* lookup_enum_literal_name(int index, void *enum_type);
static void* mk_enum_exp(void *ptr, void *type);
static void* mk_array_exp(void *arr, void *type);
static void* mk_record_exp(void *value, void *arg, struct Alignment *align);
static void* mk_exp_from_type(void *type, void *value);
static void* mk_exp_from_arg(void *arg, void *value, struct Alignment *align);

static ffi_type* type_to_type_spec(void *type);
static void* alloc_return_type(void *type);
static void* alloc_exp(void *exp, struct Alignment *align);
static void* write_exp_value(void *exp, void *ptr, struct Alignment *align);
static void* mk_ffi_value(void *exp, struct Alignment *align, int wrap_pointer);

extern void* FFI_callFunction(int fnHandle, void *args, void *specs, void *returnType, void **outputArgs);

/* Increments a pointer the given amount of bytes */
void* increment_ptr(void *ptr, size_t bytes)
{
  return (char*)ptr + bytes;
}

static int is_exp_pointer_type(void *exp)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(exp))) {
    case NFExpression__ARRAY_3dBOX3: return 1;
    case NFExpression__RECORD_3dBOX3: return 1;
  }

  return 0;
}

/* Returns the size of an array dimension */
static size_t array_dim_size(void *dim)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(dim))) {
    case NFDimension__INTEGER_3dBOX2:
      return MMC_UNTAGFIXNUM(MMC_STRUCTDATA(dim)[UNBOX_OFFSET]);

    case NFDimension__BOOLEAN_3dBOX0:
      return 2;

    case NFDimension__ENUM_3dBOX1: {
      void *ty = MMC_STRUCTDATA(dim)[UNBOX_OFFSET];
      return listLength(MMC_STRUCTDATA(ty)[UNBOX_OFFSET]);
      }

    default:
      return 0;
  }
}

/* Returns the number of elements in an array, i.e. Real[2, 3] => 2 */
static size_t array_length(void *type)
{
  void *dims = MMC_STRUCTDATA(type)[UNBOX_OFFSET+1];
  return array_dim_size(MMC_CAR(dims));
}

/* Returns the number of scalar elements in an array, i.e. Real[2, 3] => 6 */
static size_t array_scalar_count(void *arr)
{
  void *dims = MMC_STRUCTDATA(arr)[UNBOX_OFFSET+1];
  size_t count = 1;

  while (!listEmpty(dims)) {
    count *= array_dim_size(MMC_CAR(dims));
    dims = MMC_CDR(dims);
  }

  return count;
}

static ffi_type* exp_alignment_and_type(void *exp, struct Alignment *align, int field)
{
  align->offsets = NULL;
  align->fields = NULL;
  align->field_count = 0;

  switch (MMC_HDRCTOR(MMC_GETHDR(exp))) {
    case NFExpression__INTEGER_3dBOX1:
    case NFExpression__BOOLEAN_3dBOX1:
    case NFExpression__ENUM_5fLITERAL_3dBOX3:
      align->size = sizeof(int);
      return &ffi_type_sint;

    case NFExpression__REAL_3dBOX1:
      align->size = sizeof(double);
      return &ffi_type_double;

    case NFExpression__STRING_3dBOX1:
      align->size = sizeof(char*);
      return &ffi_type_pointer;

    case NFExpression__ARRAY_3dBOX3: {
      align->size = sizeof(void*);
      void *elems = MMC_STRUCTDATA(exp)[UNBOX_OFFSET+1];

      if (arrayLength(elems) > 0) {
        align->fields = (struct Alignment*)generic_alloc(1, sizeof(struct Alignment));
        exp_alignment_and_type(MMC_STRUCTDATA(elems)[0], &align->fields[0], 0);
      }
      }
      return &ffi_type_pointer;

    case NFExpression__RECORD_3dBOX3: {
      void *elems = MMC_STRUCTDATA(exp)[UNBOX_OFFSET+2];
      size_t count = listLength(elems);

      ffi_type *ty = (ffi_type*)generic_alloc(1, sizeof(ffi_type));
      ty->size = 0;
      ty->alignment = 0;
      ty->type = FFI_TYPE_STRUCT;
      ty->elements = (ffi_type**)generic_alloc(count + 1, sizeof(ffi_type*));
      ty->elements[count] = NULL;

      align->offsets = (size_t*)generic_alloc(count, sizeof(size_t));
      align->fields = (struct Alignment*)generic_alloc(count, sizeof(struct Alignment));
      align->field_count = count;

      for (int i = 0; i < count; ++i) {
        ty->elements[i] = exp_alignment_and_type(MMC_CAR(elems), &align->fields[i], 1);
        elems = MMC_CDR(elems);
      }

      ffi_get_struct_offsets(FFI_DEFAULT_ABI, ty, align->offsets);
      align->size = ty->size;

      return field ? ty : &ffi_type_pointer;
      }

    case NFExpression__EMPTY_3dBOX1: {
      void *type = MMC_STRUCTDATA(exp)[UNBOX_OFFSET];
      align->size = size_of_type(type);
      return type_to_type_spec(type);
      }
  }

  MMC_THROW();
}

/* Returns the size in bytes of the C type corresponding to the given type */
static size_t size_of_type(void *type)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(type))) {
    case NFType__INTEGER_3dBOX0:
    case NFType__BOOLEAN_3dBOX0:
    case NFType__ENUMERATION_3dBOX2:
      return sizeof(int);

    case NFType__REAL_3dBOX0:
      return sizeof(double);

    case NFType__STRING_3dBOX0:
      return sizeof(char*);

    case NFType__ARRAY_3dBOX2:
      return size_of_type(MMC_STRUCTDATA(type)[UNBOX_OFFSET]) * array_scalar_count(type);

    default:
      return 0;
  }
}

/* Returns the size in bytes of the C type corresponding to the given expression */
static size_t size_of_exp(void *exp, struct Alignment *align)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(exp))) {
    case NFExpression__INTEGER_3dBOX1:
    case NFExpression__BOOLEAN_3dBOX1:
    case NFExpression__ENUM_5fLITERAL_3dBOX3:
      return sizeof(int);

    case NFExpression__REAL_3dBOX1:
      return sizeof(double);

    case NFExpression__STRING_3dBOX1:
      return sizeof(char*);

    case NFExpression__ARRAY_3dBOX3:
      return size_of_type(MMC_STRUCTDATA(exp)[UNBOX_OFFSET]);

    case NFExpression__RECORD_3dBOX3:
      return align->size;

    case NFExpression__EMPTY_3dBOX1:
      return size_of_type(MMC_STRUCTDATA(exp)[UNBOX_OFFSET]);

    default:
      return 0;
  }
}

/* Returns the given array type with the first dimension removed */
static void* unlift_array_type(void *type)
{
  void *elem_ty = MMC_STRUCTDATA(type)[UNBOX_OFFSET];
  void *dims = MMC_STRUCTDATA(type)[UNBOX_OFFSET+1];
  return NFType__ARRAY(elem_ty, MMC_CDR(dims));
}

/* Constructs an integer expression given a pointer to an int */
static void* mk_int_exp(void *ptr, void *type)
{
  return NFExpression__INTEGER(mmc_mk_icon(*(int*)ptr));
}

/* Constructs a boolean expression given a pointer to an int */
static void* mk_bool_exp(void *ptr, void *type)
{
  return NFExpression__BOOLEAN(mmc_mk_icon((*(int*)ptr) ? 1 : 0));
}

/* Constructs a real expression given a pointer to a real */
static void* mk_real_exp(void *ptr, void *type)
{
  return NFExpression__REAL(mmc_mk_rcon(*(double*)ptr));
}

/* Constructs a string expression given a pointer to a char* */
static void* mk_string_exp(void *ptr, void *type)
{
  return NFExpression__STRING(mmc_mk_scon(*(char**)ptr));
}

/* Looks up the name of an enumeration literal given its index and enum type */
static void* lookup_enum_literal_name(int index, void *enum_type)
{
  void *literals = MMC_STRUCTDATA(enum_type)[UNBOX_OFFSET+1];

  if (index < 1 || index > listLength(literals)) {
    MMC_THROW();
  }

  for (int i = 1; i < index; ++i) {
    literals = MMC_CDR(literals);
  }

  return MMC_CAR(literals);
}

/* Constructs an enumeration literal expression given a pointer to an int and an
 * enumeration type */
static void* mk_enum_exp(void *ptr, void *type)
{
  int index = *(int*)ptr;
  void *name = lookup_enum_literal_name(index, type);
  return NFExpression__ENUM_5fLITERAL(type, name, mmc_mk_icon(index));
}

/* Helper function to mk_array_exp */
static void* mk_array_exp_2(void *arr, void *type, mk_exp_fn_t mkExpFn,
                            size_t dimCount, size_t elemCount, size_t elemSize)
{
  void *elems;

  if (dimCount == 1) { /* 1-dimensional array */
    elems = arrayCreateNoInit(elemCount, 0);

    /* Use the given function to construct an array of scalar elements */
    for (int i = 0; i < elemCount; ++i) {
      MMC_STRUCTDATA(elems)[i] = mkExpFn(increment_ptr(arr, i*elemSize), type);
    }
  } else { /* Multidimensional array */
    /* The length of this array */
    size_t arr_len = array_length(type);
    /* The total number of scalar elements each array element will contain */
    size_t arr_scalar_count = elemCount / arr_len;
    /* The number of bytes corresponding to each array element in the C array */
    size_t elems_bytes = elemSize * arr_scalar_count;
    /* The (array) type of each array element */
    void *elem_ty = unlift_array_type(type);

    elems = arrayCreateNoInit(arr_len, 0);

    /* Divide the array up into equal sized chunks and convert each chunk
     * recursively into an array */
    for (int i = 0; i < arr_len; ++i) {
      void *arr_ptr = increment_ptr(arr, i*elems_bytes);
      void *elem = mk_array_exp_2(arr_ptr, elem_ty, mkExpFn, dimCount - 1, arr_scalar_count, elemSize);
      MMC_STRUCTDATA(elems)[i] = elem;
    }
  }

  return NFExpression__ARRAY(type, elems, mmc_mk_icon(1));
}

/* Constructs an array expression given a C array and the expected type of the array */
static void* mk_array_exp(void *arr, void *type)
{
  void *elem_ty = MMC_STRUCTDATA(type)[UNBOX_OFFSET];
  void *dims = MMC_STRUCTDATA(type)[UNBOX_OFFSET+1];

  /* Calculate the length of the array, the total number of scalar elements, and
   * the size in bytes of each scalar element in the C array */
  size_t dim_count = listLength(dims);
  size_t elem_count = array_scalar_count(type);
  size_t elem_size = size_of_type(elem_ty);

  /* Decide which function to use when constructing scalar elements */
  mk_exp_fn_t mk_exp_fn = NULL;
  switch (MMC_HDRCTOR(MMC_GETHDR(elem_ty))) {
    case NFType__INTEGER_3dBOX0:     mk_exp_fn = &mk_int_exp;    break;
    case NFType__BOOLEAN_3dBOX0:     mk_exp_fn = &mk_bool_exp;   break;
    case NFType__REAL_3dBOX0:        mk_exp_fn = &mk_real_exp;   break;
    case NFType__STRING_3dBOX0:      mk_exp_fn = &mk_string_exp; break;
    case NFType__ENUMERATION_3dBOX2: mk_exp_fn = &mk_enum_exp;   break;
  }

  return mk_array_exp_2(arr, type, mk_exp_fn, dim_count, elem_count, elem_size);
}

/* Constructs a record expression given a C struct and another record expression
 * of the same type */
static void* mk_record_exp(void *value, void *arg, struct Alignment *align)
{
  void *path = MMC_STRUCTDATA(arg)[UNBOX_OFFSET];
  void *ty = MMC_STRUCTDATA(arg)[UNBOX_OFFSET+1];
  void *elems = MMC_STRUCTDATA(arg)[UNBOX_OFFSET+2];
  void *out_elems = mmc_mk_nil();

  for (int i = 0; i < align->field_count; ++i) {
    void *field_val = increment_ptr(value, align->offsets[i]);
    void *e = mk_exp_from_arg(MMC_CAR(elems), field_val, &align->fields[i]);
    out_elems = mmc_mk_cons(e, out_elems);
    elems = MMC_CDR(elems);
  }

  out_elems = listReverseInPlace(out_elems);
  return NFExpression__RECORD(path, ty, out_elems);
}

/* Converts a C value to an expression based on the expected type of the expression */
static void* mk_exp_from_type(void *type, void *value)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(type))) {
    case NFType__INTEGER_3dBOX0:     return mk_int_exp(value, NULL);
    case NFType__BOOLEAN_3dBOX0:     return mk_bool_exp(value, NULL);
    case NFType__REAL_3dBOX0:        return mk_real_exp(value, NULL);
    case NFType__STRING_3dBOX0:      return mk_string_exp(value, NULL);
    case NFType__ENUMERATION_3dBOX2: return mk_enum_exp(value, type);
    case NFType__ARRAY_3dBOX2:       return mk_array_exp(value, type);
    default:                         return NFExpression__EMPTY(type);
  }
}

/* Converts a C value to an expression of the same type as the given expression */
static void* mk_exp_from_arg(void *arg, void *value, struct Alignment *align)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(arg))) {
    case NFExpression__INTEGER_3dBOX1: return mk_int_exp(value, NULL);
    case NFExpression__BOOLEAN_3dBOX1: return mk_bool_exp(value, NULL);
    case NFExpression__REAL_3dBOX1:    return mk_real_exp(value, NULL);
    case NFExpression__STRING_3dBOX1:  return mk_string_exp(value, NULL);

    case NFExpression__ENUM_5fLITERAL_3dBOX3:
      return mk_enum_exp(value, MMC_STRUCTDATA(arg)[UNBOX_OFFSET]);

    case NFExpression__ARRAY_3dBOX3:
      return mk_array_exp(value, MMC_STRUCTDATA(arg)[UNBOX_OFFSET]);

    case NFExpression__RECORD_3dBOX3:
      return mk_record_exp(value, arg, align);

    case NFExpression__EMPTY_3dBOX1:
      return mk_exp_from_type(MMC_STRUCTDATA(arg)[UNBOX_OFFSET], value);
  }

  MMC_THROW();
}

/* Returns the appropriate ffi_type for a type */
static ffi_type* type_to_type_spec(void *type)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(type))) {
    case NFType__INTEGER_3dBOX0:
    case NFType__BOOLEAN_3dBOX0:
    case NFType__ENUMERATION_3dBOX2:
      return &ffi_type_sint;

    case NFType__REAL_3dBOX0:
      return &ffi_type_double;

    case NFType__STRING_3dBOX0:
    case NFType__ARRAY_3dBOX2:
    case NFType__COMPLEX_3dBOX2:
      return &ffi_type_pointer;

    default:
      return &ffi_type_void;
  }
}

/* Allocates memory to hold the return value of the FFI call given the type of
 * the function */
static void* alloc_return_type(void *type)
{
  /* libffi requires integral return types to at least be as large as ffi_arg */
  if (type_to_type_spec(type) == &ffi_type_sint && sizeof(int) <= sizeof(ffi_arg)) {
    return generic_alloc(1, sizeof(ffi_arg));
  }

  size_t sz = size_of_type(type);
  return sz == 0 ? NULL : generic_alloc(1, sz);
}

/* Allocates memory for storing the C value of an expression */
static void* alloc_exp(void *exp, struct Alignment *align)
{
  return generic_alloc(1, size_of_exp(exp, align));
}

/* Writes the value of an expression to the given memory location, and returns
 * the address of the next memory position (for writing array elements) */
static void* write_exp_value(void *exp, void *ptr, struct Alignment *align)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(exp))) {
    case NFExpression__INTEGER_3dBOX1:
    case NFExpression__BOOLEAN_3dBOX1:
      *(int*)ptr = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(exp)[UNBOX_OFFSET]);
      return ((int*)ptr)+1;

    case NFExpression__REAL_3dBOX1:
      *(double*)ptr = mmc_prim_get_real(MMC_STRUCTDATA(exp)[UNBOX_OFFSET]);
      return ((double*)ptr)+1;

    case NFExpression__STRING_3dBOX1:
      *(char**)ptr = MMC_STRINGDATA(MMC_STRUCTDATA(exp)[UNBOX_OFFSET]);
      return ((char**)ptr)+1;

    case NFExpression__ENUM_5fLITERAL_3dBOX3:
      *(int*)ptr = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(exp)[UNBOX_OFFSET+2]);
      return ((int*)ptr)+1;

    case NFExpression__ARRAY_3dBOX3: {
      void *elems = MMC_STRUCTDATA(exp)[UNBOX_OFFSET+1];
      int len = arrayLength(elems);

      for (int i = 0; i < len; ++i) {
        ptr = write_exp_value(MMC_STRUCTDATA(elems)[i], ptr, align);
      }
      }
      return ptr;

    case NFExpression__RECORD_3dBOX3: {
      void *elems = MMC_STRUCTDATA(exp)[UNBOX_OFFSET+2];

      for (int i = 0; i < align->field_count; ++i) {
        write_exp_value(MMC_CAR(elems), increment_ptr(ptr, align->offsets[i]), &align->fields[i]);
        elems = MMC_CDR(elems);
      }
      }
      return increment_ptr(ptr, align->size);

    default:
      return ptr;
  }
}

/* Converts an expression into a C value */
static void* mk_ffi_value(void *exp, struct Alignment *align, int wrap_pointer)
{
  void *v = alloc_exp(exp, align);
  write_exp_value(exp, v, align);

  if (wrap_pointer) {
    void *ptr = generic_alloc(1, sizeof(void*));
    *(void**)ptr = v;
    v = ptr;
  }

  return v;
}

extern void* FFI_callFunction(int fnHandle, void *args, void *specs, void *returnType, void **outputArgs)
{
  /* Fetch the function pointer associated with the handle */
  modelica_ptr_t func = lookup_ptr(fnHandle);
  if (func == NULL) MMC_THROW();

  /* Count the number of arguments and allocate arrays for the ffi arguments */
  int num_args = arrayLength(args);
  ffi_type **arg_specs = (ffi_type**)generic_alloc(num_args, sizeof(ffi_type*));
  void **arg_values = generic_alloc(num_args, sizeof(void*));
  struct Alignment *arg_aligns = (struct Alignment*)generic_alloc(num_args, sizeof(struct Alignment));

  /* Set up the type specifiers and pointers to the arguments */
  for (int i = 0; i < num_args; ++i) {
    void *arg = MMC_STRUCTDATA(args)[i];
    int spec = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(specs)[i]);

    switch (spec) {
      case INPUT_ARG:
        arg_specs[i] = exp_alignment_and_type(arg, &arg_aligns[i], 0);
        arg_values[i] = mk_ffi_value(arg, &arg_aligns[i], is_exp_pointer_type(arg));

        break;

      case LOCAL_ARG:
      case OUTPUT_ARG:
        exp_alignment_and_type(arg, &arg_aligns[i], 0);
        arg_specs[i] = &ffi_type_pointer;
        arg_values[i] = mk_ffi_value(arg, &arg_aligns[i], 1);
        break;
    }
  }

  /* Prepare the call interface */
  ffi_cif cif;
  ffi_type *ret_spec = type_to_type_spec(returnType);

  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, num_args, ret_spec, arg_specs) != FFI_OK) {
    MMC_THROW();
  }

  /* Call the function */
  void *rc = alloc_return_type(returnType);
  ffi_call(&cif, FFI_FN(func->data.func.handle), rc, arg_values);

  /* Construct the list of output arguments (if any) */
  *outputArgs = mmc_mk_nil();
  for (int i = num_args-1; i >= 0; --i) {
    if (MMC_UNTAGFIXNUM(MMC_STRUCTDATA(specs)[i]) == OUTPUT_ARG) {
      void *ov = mk_exp_from_arg(MMC_STRUCTDATA(args)[i], *(void**)(arg_values[i]), &arg_aligns[i]);
      *outputArgs = mmc_mk_cons(ov, *outputArgs);
    }
  }

  /* Convert the return value to an expression and return it */
  return mk_exp_from_type(returnType, rc);
}
