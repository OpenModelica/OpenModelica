//
// Copyright PELAB, Linkoping University
//

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include CFILE_TO_INCLUDE



int main(int argc, char** argv)
{

  if (argc != 3)
    {
      fprintf(stderr,"# Incorrrect number of arguments\n");
      return 1;
    }

  
  CFUNCTION_TO_CALL(argv[1],argv[2]);

  return 0;

}
