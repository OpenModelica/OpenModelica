#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include "test.c"


int main(int argc, char** argv)
{

  if (argc != 3)
    {
      fprintf(stderr,"# Incorrrect number of arguments\n");
      return 1;
    }

  
  t_read_call_write(argv[1],argv[2]);

  return 0;

}
