
#include "read_write.h"

void read_modelica_real(FILE* file, modelica_real* data)
{
  float f;
  fscanf(file,"%e",&f);
  *data = f;
}

void read_modelica_integer(FILE* file, modelica_integer* data)
{
  fscanf(file,"%d",data);
}

void read_real_array(FILE* file, real_array_t* arr)
{
  int nr_elements;
  int i;
  float f;
  nr_elements = real_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fscanf(file,"%e",&f);
      arr->data[i] = f;
    }
  fprintf(stderr,"Real array read\n");
}
/*
void read_integer_array(FILE* file, integer_array_t* arr)
{
  int nr_elements;
  int i;
  nr_elements = integer_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fscanf(file,"%d",arr->data + i);
    }
}
*/
void write_modelica_real(FILE* file, modelica_real* data)
{
  fprintf(file,"%e\n",*data);
}

void write_modelica_integer(FILE* file, modelica_integer* data)
{
  fprintf(file,"%d\n",*data);
}

void write_real_array(FILE* file, real_array_t* arr)
{
  int nr_elements;
  int i;
  nr_elements = real_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fprintf(file,"%e\n",arr->data[i]);
    }
}
/*
void write_integer_array(FILE* file, integer_array_t* arr)
{
  int nr_elements;
  int i;
  nr_elements = integer_array_nr_of_elements(arr);
  for (i = 0; i < nr_elements; ++i)
    {
      fprintf(file,"%d\n",arr->data[i]);
    }
}
*/
