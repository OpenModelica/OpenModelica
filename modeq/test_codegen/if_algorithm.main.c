#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include "if_algorithm.c"


int main(int argc, char** argv)
{

  if (argc != 3)
    {
      fprintf(stderr,"# Incorrrect number of arguments\n");
      return 1;
    }

  
  if_algorithm_read_call_write(argv[1],argv[2]);

  return 0;

}
