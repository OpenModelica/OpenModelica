#include <stdio.h>
#include "modelica.h"

#include "matrix_vector_product.c"

int main(int argc, char** argv)
{

  if (argc != 3)
    {
      fprintf(stderr,"# Incorrrect number of arguments\n");
      return 1;
    }
  
  matrix_vector_product_read_call_write(argv[1],argv[2]);

  return 0;

}
