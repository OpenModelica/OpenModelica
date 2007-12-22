/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science, 
 * SE-58183 Linköping, Sweden. 
 * 
 * All rights reserved.
 * 
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC 
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF 
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC 
 * PUBLIC LICENSE. 
 * 
 * The OpenModelica software and the Open Source Modelica 
 * Consortium (OSMC) Public License (OSMC-PL) are obtained 
 * from Linköpings University, either from the above address, 
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 * 
 * This program is distributed  WITHOUT ANY WARRANTY; without 
 * even the implied warranty of  MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH 
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS 
 * OF OSMC-PL. 
 * 
 * See the full OSMC Public License conditions for more details.
 * 
 */

#include "read_write.h"


void cleanup_description(type_description* desc)
{
  if (desc->ndims > 0)
    {
      free(desc->dim_size);
    }
}

void in_report(const char *str)
{
  fprintf(stderr,"input failed: %s\n",str);
}

void read_to_eol(FILE* file)
{
  int c;
  while (((c = fgetc(file)) != '\n') && (c != EOF));
}

int read_type_description(FILE* file, type_description* desc)
{
  int c;
  int i;
  do 
    {
      if ((c = fgetc(file)) == EOF) return 1;
      if (c != '#') return 1;
      if ((c = fgetc(file)) == EOF) return 1;
      if (c != ' ') return 1;
      if ((c = fgetc(file)) == EOF) return 1;
      switch (c)
	{
	case 'i': /* integer */
	case 'r': /* real */
	case 'b': /* boolean */
	case 's': /* string */
	  desc->type = c;
	  break;
	default:
	  return 1;	  
	}
      if ((c = fgetc(file)) == EOF) return 1;
      if (c == '!') /* scalar */
	{
	  /* Scalar string */
	  if (desc->type == 's') {
	    if (fscanf(file,"%d",&desc->ndims) != 1) return 1;
	    desc->dim_size = (int*)malloc(desc->ndims*sizeof(int));
	    if (!desc->dim_size) return 1;
	    if (fscanf(file,"%d",desc->dim_size) != 1) return 1;
	    break;
	  } 
	  else {
	    /* other scalars. */
	    desc->ndims = 0;
	    desc->dim_size = 0;
	    break;
	  }
	}
      if (c != '[') return 1;
      /* now is an array dim description */
      if (fscanf(file,"%d",&desc->ndims) != 1) return 1;
      if (desc->ndims < 0) return 1;
      if (desc->ndims > 0)
	{
	  desc->dim_size = (int*)malloc(desc->ndims*sizeof(int));
	  if (!desc->dim_size) return 1;
	}
      else
	{
	  desc->dim_size = 0;
	}
      for (i = 0; i < desc->ndims; ++i)
	{
	  if (fscanf(file,"%d",&desc->dim_size[i]) != 1)
	    {
	      free(desc->dim_size);
	      return 1;
	    }	  
	}
      break;
      
    } while (0);

  read_to_eol(file);

  return 0;
}

int read_modelica_complex(FILE *file, modelica_complex data)
{
	printf("Internal Error, read_modelica_complex not supported\n");
	return -1;
}

int read_modelica_real(FILE* file, modelica_real* data)
{
  modelica_real f;
  type_description desc;
  if (read_type_description(file,&desc)) { in_report("rs type_desc"); return 1; }
  if ((desc.type != 'r') && (desc.type != 'i')) { cleanup_description(&desc); in_report("rs type"); return 1; }
  if (desc.ndims != 0) { cleanup_description(&desc); in_report("rs dims"); return 1; }
  if (fscanf(file,"%le",&f) != 1) { cleanup_description(&desc); in_report("rs parse"); return 1; }
  *data = f;
  read_to_eol(file);
  cleanup_description(&desc);
  return 0;
}

int read_modelica_integer(FILE* file, modelica_integer* data)
{
  type_description desc;
  if (read_type_description(file,&desc)) { in_report("is type_desc"); return 1; }
  if (desc.type != 'i') { cleanup_description(&desc); in_report("is type"); return 1; }
  if (desc.ndims != 0) { cleanup_description(&desc); in_report("is ndims"); return 1; }
  if (fscanf(file,"%d",data) != 1) { cleanup_description(&desc); in_report("is parse"); return 1; }
  read_to_eol(file);
  cleanup_description(&desc);
  return 0;
}

int read_modelica_boolean(FILE* file, modelica_boolean* data)
{
  type_description desc;
  if (read_type_description(file,&desc)) { in_report("is type_desc"); return 1; }
  if (desc.type != 'b') { cleanup_description(&desc); in_report("is type"); return 1; }
  if (desc.ndims != 0) { cleanup_description(&desc); in_report("is ndims"); return 1; }
  if (fscanf(file,"%e",(float*)data) != 1) { cleanup_description(&desc); in_report("is parse"); return 1; }
  read_to_eol(file);
  cleanup_description(&desc);
  return 0;
}

int read_real_array(FILE* file, real_array_t* arr)
{
  int nr_elements;
  int i;
  modelica_real f;
  real_array_t tmp;
  type_description desc;

  if (read_type_description(file,&desc)) { in_report("ra type_desc"); return 1; }
  if ((desc.type != 'r') && (desc.type != 'i')) { in_report("ra type"); return 1; }
  if (desc.ndims <= 0) { in_report("ra ndims"); return 1; }
  
  tmp.ndims = desc.ndims;
  tmp.dim_size = desc.dim_size;
  clone_real_array_spec(&tmp,arr);
  alloc_real_array_data(arr);
  cleanup_description(&desc);

  nr_elements = real_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      if (fscanf(file,"%le",&f) != 1) { in_report("ra parse"); return 1; }
      arr->data[i] = f;
    }
  read_to_eol(file);
  return 0;
}

int read_integer_array(FILE* file, integer_array_t* arr)
{
	
  int nr_elements;
  int i;
  int f;
  integer_array_t tmp;
  type_description desc;

  if (read_type_description(file,&desc)) { in_report("ia type_desc"); return 1; }
  if ((desc.type != 'r') && (desc.type != 'i')) { in_report("ia type"); return 1; }
  if (desc.ndims <= 0) { in_report("a ndims"); return 1; }
  
  tmp.ndims = desc.ndims;
  tmp.dim_size = desc.dim_size;
  clone_integer_array_spec(&tmp,arr);
  alloc_integer_array_data(arr);
  cleanup_description(&desc);

  nr_elements = integer_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      if (fscanf(file,"%d",&f) != 1) { in_report("ia parse"); return 1; }
      arr->data[i] = f;
    }
  read_to_eol(file);
  return 0;
}

int read_boolean_array(FILE* file, boolean_array_t* arr)
{
	
  int nr_elements;
  int i;
  float f;
  boolean_array_t tmp;
  type_description desc;

  if (read_type_description(file,&desc)) { in_report("ia type_desc"); return 1; }
  if ((desc.type != 'b')) { in_report("ia type"); return 1; }
  if (desc.ndims <= 0) { in_report("a ndims"); return 1; }
  
  tmp.ndims = desc.ndims;
  tmp.dim_size = desc.dim_size;
  clone_boolean_array_spec(&tmp,arr);
  alloc_boolean_array_data(arr);
  cleanup_description(&desc);

  nr_elements = boolean_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      if (fscanf(file,"%e",&f) != 1) { in_report("ia parse"); return 1; }
      arr->data[i] = f;
    }
  read_to_eol(file);
  return 0;
}

int write_modelica_real(FILE* file, modelica_real* data)
{
  fprintf(file,"# r!\n");
  fprintf(file,"%e\n",*data);
  return 0;
}

int write_modelica_boolean(FILE* file, modelica_boolean* data)
{
  fprintf(file,"# b!\n");
  fprintf(file,"%e\n",*data);
  return 0;
}

int write_modelica_integer(FILE* file, modelica_integer* data)
{
  fprintf(file,"# i!\n");
  fprintf(file,"%d\n",*data);
  return 0;
}

int write_real_array(FILE* file, real_array_t* arr)
{
  int nr_elements;
  int i;
  fprintf(file,"# r[ %d",arr->ndims);
  for (i = 0; i < arr->ndims; ++i) fprintf(file," %d",arr->dim_size[i]);
  fprintf(file,"\n");
  nr_elements = real_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fprintf(file,"%e\n",arr->data[i]);
    }
  return 0;
}

int write_boolean_array(FILE* file, boolean_array_t* arr)
{
  int nr_elements;
  int i;
  fprintf(file,"# b[ %d",arr->ndims);
  for (i = 0; i < arr->ndims; ++i) fprintf(file," %d",arr->dim_size[i]);
  fprintf(file,"\n");
  nr_elements = boolean_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fprintf(file,"%e\n",arr->data[i]);
    }
  return 0;
}

int write_integer_array(FILE* file, integer_array_t* arr)
{
  int nr_elements;
  int i;
  fprintf(file,"# i[ %d",arr->ndims);
  for (i = 0; i < arr->ndims; ++i) fprintf(file," %d",arr->dim_size[i]);
  fprintf(file,"\n");
  nr_elements = integer_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fprintf(file,"%d\n",arr->data[i]);
    }
    return 0;
}


int read_modelica_string(FILE* file, modelica_string_t* str)
{
  int length;
  int i;
  char c;
  type_description desc;

  if (read_type_description(file,&desc)) { in_report("ms type_desc"); return 1; }
  if (desc.type != 's') { cleanup_description(&desc); in_report("ms type"); return 1; }
  if (desc.ndims != 1) { cleanup_description(&desc); in_report("ms ndims"); return 1; }

  alloc_modelica_string(str,desc.dim_size[0]);
  length = desc.dim_size[0];
  for (i = 0; i< length; ++i) {
    if (fscanf(file,"%c",&c) != 1) { in_report("ms parse"); return 1; }
    (*str)[i] = c;
   
  }
  cleanup_description(&desc);
  read_to_eol(file);
  return 0;
}

int write_modelica_string(FILE* file, modelica_string_t* str)
{
  fprintf(file,"# s! %d %d", 1, modelica_string_length(str));
  fprintf(file,"\n");
  fprintf(file,"%s\n",*str);
  return 0;
}
