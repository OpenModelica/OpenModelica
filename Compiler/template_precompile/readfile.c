#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include "rml.h"

void System_5finit ()
{
}

RML_BEGIN_LABEL(System__readFile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    fprintf(stderr, "Error opening file %s\n", filename);
    abort();
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);

  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
    fprintf(stderr, "Error reading file %s\n", filename);
    abort();
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  
  rmlA0 = (void*) mk_scon(buf);
  free(buf);

  RML_TAILCALLK(rmlSC);  
  return buf;
}
RML_END_LABEL

