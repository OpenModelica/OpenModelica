/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#if defined(__cplusplus)
extern "C"
{
#endif

#include "read_write.h"
#include "real_array.h"
#include "integer_array.h"
#include "boolean_array.h"
#include "string_array.h"
#include "../meta/meta_modelica.h"
#include <string.h>

int getMyBool(const type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_BOOL:
    /*fprintf(stderr,"returning %d\n",desc->data.boolean ? 1:0);*/
    return desc->data.boolean ? 1:0;
  default:
    /*fprintf(stderr, "UNKNOWN: Values.Value!\n");*/
    break;
  }
  return 0;
}
#if 1 /* only used for debug */
void puttype(const type_description *desc)
{
  fprintf(stderr, "TYPE[%d] -> ", desc->type);
  switch (desc->type) {
  case TYPE_DESC_REAL:
    fprintf(stderr, "REAL: %g\n", desc->data.real);
    break;
  case TYPE_DESC_INT:
    fprintf(stderr, "INT: %ld\n", desc->data.integer);
    break;
  case TYPE_DESC_BOOL:
    fprintf(stderr, "BOOL: %c\n", desc->data.boolean ? 't' : 'f');
    break;
  case TYPE_DESC_STRING:
    fprintf(stderr, "STR: '%s'\n", MMC_STRINGDATA(desc->data.string));
    break;
  case TYPE_DESC_TUPLE: {
      size_t e;
      fprintf(stderr, "TUPLE (%u):\n", (unsigned) desc->data.tuple.elements);
      for(e = 0; e < desc->data.tuple.elements; ++e) {
        fprintf(stderr, "\t");
        puttype(desc->data.tuple.element + e);
      }
    }
    break;
  case TYPE_DESC_REAL_ARRAY: {
      int d;
      fprintf(stderr, "REAL ARRAY [%d] (", desc->data.real_array.ndims);
      for(d = 0; d < desc->data.real_array.ndims; ++d) {
        fprintf(stderr, "%d, ", (int) desc->data.real_array.dim_size[d]);
      }
      fprintf(stderr, ")\n");
      if(desc->data.real_array.ndims == 1) {
        int e;
        fprintf(stderr, "\t[");
        for(e = 0; e < desc->data.real_array.dim_size[0]; ++e) {
          fprintf(stderr, "%g, ",
                  ((modelica_real *) desc->data.real_array.data)[e]);
        }
        fprintf(stderr, "]\n");
      }
    }
    break;
  case TYPE_DESC_INT_ARRAY: {
      int d;
      fprintf(stderr, "INT ARRAY [%d] (", desc->data.int_array.ndims);
      for(d = 0; d < desc->data.int_array.ndims; ++d) {
        fprintf(stderr, "%d, ", (int) desc->data.int_array.dim_size[d]);
      }
      fprintf(stderr, ")\n");
      if(desc->data.int_array.ndims == 1) {
        int e;
        fprintf(stderr, "\t[");
        for(e = 0; e < desc->data.int_array.dim_size[0]; ++e) {
          fprintf(stderr, "%ld, ", ((modelica_integer *) desc->data.int_array.data)[e]);
        }
        fprintf(stderr, "]\n");
      }
    }
    break;
  case TYPE_DESC_BOOL_ARRAY: {
      int d;
      fprintf(stderr, "BOOL ARRAY [%d] (", desc->data.bool_array.ndims);
      for(d = 0; d < desc->data.bool_array.ndims; ++d) {
        fprintf(stderr, "%d, ", (int) desc->data.bool_array.dim_size[d]);
      }
      fprintf(stderr, ")\n");
      if(desc->data.bool_array.ndims == 1) {
        int e;
        fprintf(stderr, "\t[");
        for(e = 0; e < desc->data.bool_array.dim_size[0]; ++e) {
          fprintf(stderr, "%c, ",
                  ((modelica_boolean *) desc->data.bool_array.data)[e] ? 'T':'F');
        }
        fprintf(stderr, "]\n");
      }
    }
    break;
  case TYPE_DESC_STRING_ARRAY: {
      int d;
      fprintf(stderr, "STRING ARRAY [%d] (", desc->data.string_array.ndims);
      for(d = 0; d < desc->data.string_array.ndims; ++d) {
        fprintf(stderr, "%d, ", (int) desc->data.string_array.dim_size[d]);
      }
      fprintf(stderr, ")\n");
      if(desc->data.string_array.ndims == 1) {
        int e;
        fprintf(stderr, "\t[");
        for(e = 0; e < desc->data.string_array.dim_size[0]; ++e) {
          fprintf(stderr, "%s, ",
                MMC_STRINGDATA(((modelica_string *) desc->data.string_array.data)[e]));
        }
        fprintf(stderr, "]\n");
      }
    }
    break;
  case TYPE_DESC_COMPLEX:
    fprintf(stderr, "COMPLEX\n");
    break;
  case TYPE_DESC_NONE:
    fprintf(stderr, "NONE\n");
    break;
  case TYPE_DESC_RECORD: {
      size_t i;
      fprintf(stderr, "RECORD: %s ", desc->data.record.record_name?desc->data.record.record_name:"[no name]");
      if(!desc->data.record.elements) {
        fprintf(stderr, "has no members!?\n");
      } else {
        fprintf(stderr, "has the following members:\n");
      }
      for(i = 0; i < desc->data.record.elements; i++) {
        fprintf(stderr, "NAME: %s\n", desc->data.record.name[i]);
        puttype(&(desc->data.record.element[i]));
      }
    }
    break;
  case TYPE_DESC_MMC:
    fprintf(stderr, "%s\n", anyString(desc->data.mmc));
    break;
  default:
    fprintf(stderr, "UNKNOWN: Values.Value!\n");
    break;
  }
  fflush(stderr);
}
#endif

static void in_report(const char *str)
{
  fprintf(stderr, "input failed: %s\n", str); fflush(stderr);
}

static type_description *add_tuple_item(type_description *desc);

void init_type_description(type_description *desc)
{
  desc->type = TYPE_DESC_NONE;
  desc->retval = 0;
  memset(&(desc->data), 0, sizeof(desc->data));
}

void free_type_description(type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_NONE:
    break;
  case TYPE_DESC_REAL:
  case TYPE_DESC_INT:
  case TYPE_DESC_BOOL:
    break;
  case TYPE_DESC_STRING:
    break;
  case TYPE_DESC_REAL_ARRAY:
    if(desc->retval) {
      free(desc->data.real_array.dim_size);
      free(desc->data.real_array.data);
    }
    break;
  case TYPE_DESC_INT_ARRAY:
    if(desc->retval) {
      free(desc->data.int_array.dim_size);
      free(desc->data.int_array.data);
    }
    break;
  case TYPE_DESC_BOOL_ARRAY:
    if(desc->retval) {
      free(desc->data.bool_array.dim_size);
      free(desc->data.bool_array.data);
    }
    break;
  case TYPE_DESC_STRING_ARRAY:
    if(desc->retval) {
      free(desc->data.string_array.dim_size);
      free(desc->data.string_array.data);
    }
    break;
  case TYPE_DESC_TUPLE: {
      size_t i;
      type_description *e = desc->data.tuple.element;
      for(i = 0; i < desc->data.tuple.elements; ++i, ++e) {
        free_type_description(e);
      }
      if(desc->data.tuple.elements > 0) {
        free(desc->data.tuple.element);
      }
    }
    break;
  case TYPE_DESC_FUNCTION:
  case TYPE_DESC_MMC:
  case TYPE_DESC_COMPLEX:
  case TYPE_DESC_NORETCALL:
    break;
  case TYPE_DESC_RECORD: {
      size_t i;
      type_description *e = desc->data.record.element;
      /* char **n = desc->data.record.name; */
      for(i = 0; i < desc->data.record.elements; i++, e++) {
        free(desc->data.record.name[i]);
        free_type_description(e);
      }
      if(desc->data.record.elements > 0) {
        free(desc->data.record.element);
        free(desc->data.record.name);
      }
    }
    break;
  }
}

int read_modelica_real(type_description **descptr, modelica_real *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_REAL:
    *data = desc->data.real;
    return 0;
  case TYPE_DESC_INT:
    *data = (modelica_real)desc->data.integer;
    return 0;
  default:
    break;
  }
  in_report("rs type");
  fprintf(stderr, "Expected real scalar, got:"); puttype(desc); fflush(stderr);
  return -1;
}

int read_modelica_integer(type_description **descptr, modelica_integer *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_INT:
    *data = desc->data.integer;
    return 0;
  default:
    break;
  }

  in_report("is type");
  fprintf(stderr, "Expected integer scalar, got:"); puttype(desc); fflush(stderr);
  return -1;
}

int read_modelica_boolean(type_description **descptr, modelica_boolean *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_BOOL:
    *data = desc->data.boolean;
    return 0;
  default:
    break;
  }

  in_report("bs type");
  fprintf(stderr, "Expected boolean scalar, got:"); puttype(desc); fflush(stderr);
  return -1;
}

int read_real_array(type_description **descptr, real_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_REAL_ARRAY:
    *arr = desc->data.real_array;
    return 0;
  case TYPE_DESC_INT_ARRAY:
    cast_integer_array_to_real(&(desc->data.int_array), arr);
    return 0;
  default:
    break;
  }

  in_report("ra type");
  fprintf(stderr, "Expected real array, got:"); puttype(desc); fflush(stderr);
  return -1;
}

int read_integer_array(type_description **descptr, integer_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_INT_ARRAY:
    *arr = desc->data.int_array;
    return 0;
  case TYPE_DESC_REAL_ARRAY:
    /* Empty arrays automaticly get to be real arrays */
    if(desc->data.real_array.dim_size[desc->data.real_array.ndims - 1] == 0) {
      int dims = desc->data.real_array.ndims;
      _index_t *dim_size = desc->data.real_array.dim_size;
      desc->type = TYPE_DESC_INT_ARRAY;
      desc->data.int_array.ndims = dims;
      desc->data.int_array.dim_size = dim_size;
      alloc_integer_array_data(&(desc->data.int_array));
      *arr = desc->data.int_array;
      return 0;
    }
    break;
  default:
    break;
  }

  in_report("ia type");
  fprintf(stderr, "Expected integer array, got:"); puttype(desc); fflush(stderr);
  return -1;
}

int read_boolean_array(type_description **descptr, boolean_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_BOOL_ARRAY:
    *arr = desc->data.bool_array;
    return 0;
  case TYPE_DESC_REAL_ARRAY:
    /* Empty arrays automaticly get to be real arrays */
    if(desc->data.real_array.dim_size[desc->data.real_array.ndims - 1] == 0) {
      int dims = desc->data.real_array.ndims;
      _index_t *dim_size = desc->data.real_array.dim_size;
      desc->type = TYPE_DESC_BOOL_ARRAY;
      desc->data.bool_array.ndims = dims;
      desc->data.bool_array.dim_size = dim_size;
      alloc_boolean_array_data(&(desc->data.bool_array));
      *arr = desc->data.bool_array;
      return 0;
    }
    break;
  default:
    break;
  }

  in_report("ba type");
  fprintf(stderr, "Expected boolean array, got:"); puttype(desc); fflush(stderr);
  return -1;
}

int read_string_array(type_description **descptr, string_array_t *arr)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_STRING_ARRAY:
    *arr = desc->data.string_array;
    return 0;
  case TYPE_DESC_REAL_ARRAY:
    /* Empty arrays automaticly get to be real arrays */
    if(desc->data.real_array.dim_size[desc->data.real_array.ndims - 1] == 0) {
      int dims = desc->data.real_array.ndims;
      _index_t *dim_size = desc->data.real_array.dim_size;
      desc->type = TYPE_DESC_STRING_ARRAY;
      desc->data.string_array.ndims = dims;
      desc->data.string_array.dim_size = dim_size;
      alloc_string_array_data(&(desc->data.string_array));
      *arr = desc->data.string_array;
      return 0;
    }
    break;
  default:
    break;
  }

  in_report("sa type");
  fprintf(stderr, "Expected string array, got:"); puttype(desc); fflush(stderr);
  return -1;
}

void write_modelica_real(type_description *desc, const modelica_real *data)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_REAL;
  desc->data.real = *data;
}

void write_modelica_integer(type_description *desc, const modelica_integer *data)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_INT;
  desc->data.integer = *data;
}

void write_modelica_boolean(type_description *desc, const modelica_boolean *data)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_BOOL;
  desc->data.boolean = *data;
}

void write_noretcall(type_description *desc)
{
  desc->type = TYPE_DESC_NORETCALL;
}

void write_real_array(type_description *desc, const real_array_t *arr)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_REAL_ARRAY;
  if(desc->retval) {
    /* Can't use memory pool for these */
    size_t nr_elements;
    desc->data.real_array.ndims = arr->ndims;
    desc->data.real_array.dim_size = (_index_t*)malloc(sizeof(*(arr->dim_size)) * arr->ndims);
    memcpy(desc->data.real_array.dim_size, arr->dim_size, sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = base_array_nr_of_elements(*arr);
    desc->data.real_array.data = malloc(sizeof(modelica_real) * nr_elements);
    memcpy(desc->data.real_array.data, arr->data,
           sizeof(modelica_real) * nr_elements);
  } else {
    copy_real_array(*arr, &(desc->data.real_array));
  }
}

void write_integer_array(type_description *desc, const integer_array_t *arr)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_INT_ARRAY;
  if(desc->retval) {
    /* Can't use memory pool for these */
    size_t nr_elements;
    desc->data.int_array.ndims = arr->ndims;
    desc->data.int_array.dim_size = (_index_t*)malloc(sizeof(*(arr->dim_size)) * arr->ndims);
    memcpy(desc->data.int_array.dim_size, arr->dim_size, sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = base_array_nr_of_elements(*arr);
    desc->data.int_array.data = malloc(sizeof(modelica_integer) * nr_elements);
    memcpy(desc->data.int_array.data, arr->data,
           sizeof(modelica_integer) * nr_elements);
  } else {
    clone_integer_array_spec(arr, &(desc->data.int_array));
    integer_array_copy_data(*arr, desc->data.int_array);
  }
}

void write_boolean_array(type_description *desc, const boolean_array_t *arr)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_BOOL_ARRAY;
  if(desc->retval) {
    /* Can't use memory pool for these */
    size_t nr_elements;
    desc->data.bool_array.ndims = arr->ndims;
    desc->data.bool_array.dim_size = (_index_t*)malloc(sizeof(*(arr->dim_size)) * arr->ndims);
    memcpy(desc->data.bool_array.dim_size, arr->dim_size, sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = base_array_nr_of_elements(*arr);
    desc->data.bool_array.data = malloc(sizeof(modelica_boolean) * nr_elements);
    memcpy(desc->data.bool_array.data, arr->data,
           sizeof(modelica_boolean) * nr_elements);
  } else {
    copy_boolean_array(*arr, &(desc->data.bool_array));
  }
}

void write_string_array(type_description *desc, const string_array_t *arr)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_STRING_ARRAY;
  if(desc->retval) {
    size_t i;
    size_t nr_elements;
    modelica_string *dst = NULL, *src = NULL;
    desc->data.string_array.ndims = arr->ndims;
    desc->data.string_array.dim_size = (_index_t*)malloc(sizeof(*(arr->dim_size)) * arr->ndims);
    memcpy(desc->data.string_array.dim_size, arr->dim_size, sizeof(*(arr->dim_size)) * arr->ndims);
    nr_elements = base_array_nr_of_elements(*arr);
    desc->data.string_array.data = malloc(sizeof(modelica_string)* nr_elements);
    dst = (modelica_string*)desc->data.string_array.data;
    src = (modelica_string*)arr->data;
    for(i = 0; i < nr_elements; ++i) {
      *dst = *src;
      ++src;
      ++dst;
    }
  } else {
    copy_string_array(*arr, &(desc->data.string_array));
  }
}

int read_modelica_string(type_description **descptr, modelica_string *str)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_STRING:
    *str = desc->data.string;
    return 0;
  default:
    break;
  }

  in_report("ms type");
  return -1;
}

void write_modelica_string(type_description *desc, modelica_string *str)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_STRING;
  if(desc->retval) {
    /* Can't use memory pool */
    desc->data.string = *str;
  } else {
    *str = desc->data.string;
  }
}

int read_modelica_complex(type_description **descptr, modelica_complex *data)
{
  type_description *desc = (*descptr)++;
  switch (desc->type) {
  case TYPE_DESC_COMPLEX:
    *data = desc->data.om_complex;
    return 0;
  default:
    break;
  }

  in_report("mc type");
  return -1;
}

void write_modelica_complex(type_description *desc, const modelica_complex *data)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_COMPLEX;
  desc->data.om_complex = *data;
}

/* function pointer functions - added by stefan */

int read_modelica_fnptr(type_description **descptr, modelica_fnptr *fn)
{
  type_description *desc = (*descptr)++;
  switch(desc->type) {
  case TYPE_DESC_FUNCTION:
    *fn = desc->data.function;
    return 0;
  default:
    break;
  }

  in_report("mc type");
  return -1;
}

void write_modelica_fnptr(type_description *desc, const modelica_fnptr *fn)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_FUNCTION;
  desc->data.function = *fn;
}

int read_modelica_metatype(type_description **descptr, modelica_metatype *ut)
{
  type_description *desc = (*descptr)++;
  switch(desc->type) {
  case TYPE_DESC_INT:
    *ut = mmc_mk_icon(desc->data.integer);
    return 0;
  case TYPE_DESC_REAL:
    *ut = mmc_mk_rcon(desc->data.real);
    return 0;
  case TYPE_DESC_STRING:
    *ut = desc->data.string;
    return 0;
  case TYPE_DESC_BOOL:
    *ut = mmc_mk_icon((desc->data.boolean == 0) ? 0 : 1);
    return 0;
  case TYPE_DESC_MMC:
    *ut = desc->data.mmc;
    return 0;
  default:
    break;
  }

  in_report("MMC type");
  return -1;
}

void write_modelica_metatype(type_description *desc, const modelica_metatype *ut)
{
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_MMC;
  desc->data.mmc = *ut;
}

static int read_modelica_record_helper(type_description **descptr, va_list *arg)
{
  type_description *desc = (*descptr)++;
  type_description *elem = NULL;
  size_t e;
  switch (desc->type) {
  case TYPE_DESC_RECORD:
    elem = desc->data.record.element;
    for(e = 0; e < desc->data.record.elements; ++e) {
      switch (elem->type) {
      case TYPE_DESC_NONE:
        return -1;
      case TYPE_DESC_REAL:
        read_modelica_real(&elem, va_arg(*arg, modelica_real *));
        break;
      case TYPE_DESC_REAL_ARRAY:
        read_real_array(&elem, va_arg(*arg, real_array_t *));
        break;
      case TYPE_DESC_INT:
        read_modelica_integer(&elem, va_arg(*arg, modelica_integer *));
        break;
      case TYPE_DESC_INT_ARRAY:
        read_integer_array(&elem, va_arg(*arg, integer_array_t *));
        break;
      case TYPE_DESC_BOOL:
        read_modelica_boolean(&elem, va_arg(*arg, modelica_boolean *));
        break;
      case TYPE_DESC_BOOL_ARRAY:
        read_boolean_array(&elem, va_arg(*arg, boolean_array_t *));
        break;
      case TYPE_DESC_STRING:
        read_modelica_string(&elem, va_arg(*arg, modelica_string *));
        break;
      case TYPE_DESC_STRING_ARRAY:
        read_string_array(&elem, va_arg(*arg, string_array_t *));
        break;
      case TYPE_DESC_TUPLE:
        in_report("tuple in record is unsupported.");
        return -1;
      case TYPE_DESC_COMPLEX:
        read_modelica_complex(&elem, va_arg(*arg, modelica_complex *));
        break;
      case TYPE_DESC_MMC:
        read_modelica_metatype(&elem, va_arg(*arg, void **));
        break;
      case TYPE_DESC_RECORD:
        read_modelica_record_helper(&elem, arg);
        break;
      case TYPE_DESC_FUNCTION:
        in_report("function pointer in record is unsupported.");
        return -1;
      case TYPE_DESC_NORETCALL:
        in_report("noretcall in record is invalid.");
        return -1;
      }
    }
    return 0;
  default:
    break;
  }

  in_report("mr type");
  return -1;
}

int read_modelica_record(type_description **descptr, ...)
{
  va_list arg;
  int res;
  va_start(arg, descptr);
  res = read_modelica_record_helper(descptr,&arg);
  va_end(arg);
  return res;
}

type_description *add_modelica_record_member(type_description *desc,
                                             const char *name, size_t nlen)
{
  type_description *elem;
  assert(desc->type == TYPE_DESC_RECORD);
  desc->data.record.name = (char**)realloc(desc->data.record.name, sizeof(char *)
                                   * (desc->data.record.elements + 1));
  desc->data.record.element = (struct type_desc_s*)realloc(desc->data.record.element,
                                      sizeof(struct type_desc_s)
                                      * (desc->data.record.elements + 1));
  elem = desc->data.record.element + desc->data.record.elements;
  desc->data.record.name[desc->data.record.elements] = (char*)malloc(nlen + 1);
  memcpy(desc->data.record.name[desc->data.record.elements], name, nlen + 1);
  /*
   * strdup is not ansi!
   * desc->data.record.name[desc->data.record.elements] = strdup(name);
   */
  ++desc->data.record.elements;
  init_type_description(elem);
  return elem;
}

/* Help write_modelica_record work recursively. sjoelund */
static void write_modelica_record_helper(type_description *desc, const void* rec_desc_void, va_list* arg)
{
  enum type_desc_e type;
  const struct record_description rec_desc = *((const struct record_description*) rec_desc_void);
  if(desc->type != TYPE_DESC_NONE) {
    desc = add_tuple_item(desc);
  }
  desc->type = TYPE_DESC_RECORD;
  desc->data.record.record_name = rec_desc.path;
  desc->data.record.elements = 0;
  desc->data.record.name = NULL;
  desc->data.record.element = NULL;
  /* atleast small enums gets casted to ints */
  while((type = (enum type_desc_e) va_arg(*arg, int)) != TYPE_DESC_NONE) {
    type_description *elem;
    const char *name;
    size_t nlen;
    name = rec_desc.fieldNames[desc->data.record.elements];
    nlen = strlen(name);

    elem = add_modelica_record_member(desc, name, nlen);
    elem->retval = desc->retval;

    switch (type) {
    case TYPE_DESC_NONE:
      break;
    case TYPE_DESC_REAL:
      write_modelica_real(elem, va_arg(*arg, modelica_real *));
      break;
    case TYPE_DESC_REAL_ARRAY:
      write_real_array(elem, va_arg(*arg, real_array_t *));
      break;
    case TYPE_DESC_INT:
      write_modelica_integer(elem, va_arg(*arg, modelica_integer *));
      break;
    case TYPE_DESC_INT_ARRAY:
      write_integer_array(elem, va_arg(*arg, integer_array_t *));
      break;
    case TYPE_DESC_BOOL:
      write_modelica_boolean(elem, va_arg(*arg, modelica_boolean *));
      break;
    case TYPE_DESC_BOOL_ARRAY:
      write_boolean_array(elem, va_arg(*arg, boolean_array_t *));
      break;
    case TYPE_DESC_STRING:
      write_modelica_string(elem, va_arg(*arg, modelica_string *));
      break;
    case TYPE_DESC_STRING_ARRAY:
      write_string_array(elem, va_arg(*arg, string_array_t *));
      break;
    case TYPE_DESC_COMPLEX:
      write_modelica_complex(elem, va_arg(*arg, modelica_complex *));
      break;
    case TYPE_DESC_MMC:
      write_modelica_metatype(elem, va_arg(*arg, void **));
      break;
    case TYPE_DESC_TUPLE:
      in_report("tuple in record is unsupported.");
      assert(0);
      return;
    case TYPE_DESC_RECORD: {
        struct record_description* new_desc = va_arg(*arg, struct record_description*);
        write_modelica_record_helper(elem, new_desc, arg);
      }
      break;
    case TYPE_DESC_FUNCTION:
      in_report("function pointer in record is unsupported.");
      assert(0);
      return;
    case TYPE_DESC_NORETCALL:
      in_report("noretcall in record is invalid.");
      assert(0);
      return;
    }
  }
}

void write_modelica_record(type_description *desc, void* rec_desc_void, ...)
{
  va_list arg;
  va_start(arg, rec_desc_void);
  write_modelica_record_helper(desc, rec_desc_void, &arg);
  va_end(arg);
}

type_description *add_tuple_member(type_description *desc)
{
  type_description *ret = NULL;
  assert(desc->type == TYPE_DESC_TUPLE);
  desc->data.tuple.element = (struct type_desc_s*)realloc(desc->data.tuple.element,
                                     (desc->data.tuple.elements + 1)
                                     * sizeof(struct type_desc_s));
  ret = desc->data.tuple.element + desc->data.tuple.elements;
  ++(desc->data.tuple.elements);
  init_type_description(ret);
  return ret;
}

static type_description *add_tuple_item(type_description *desc)
{
  type_description *ret = NULL;

  if(desc->type == TYPE_DESC_TUPLE) {
    desc->data.tuple.element = (struct type_desc_s*)realloc(desc->data.tuple.element,
                                       (desc->data.tuple.elements + 1)
                                       * sizeof(struct type_desc_s));
    ret = desc->data.tuple.element + desc->data.tuple.elements;
    ++(desc->data.tuple.elements);
  } else {
    struct type_desc_s tmp;
    memcpy(&tmp, desc, sizeof(tmp));
    desc->type = TYPE_DESC_TUPLE;
    desc->retval = tmp.retval;
    desc->data.tuple.elements = 2;
    desc->data.tuple.element = (struct type_desc_s*)malloc(2 * sizeof(struct type_desc_s));
    memcpy(desc->data.tuple.element, &tmp, sizeof(tmp));
    ret = desc->data.tuple.element + 1;
  }

  init_type_description(ret);
  ret->retval = desc->retval;
  return ret;
}

#if defined(__cplusplus)
}
#endif

