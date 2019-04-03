#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void* constructor(const char* filename,const char* dummy)
{
  printf("constructors says '%s'\n", (char*)filename);
  return (void*) strdup(filename);
}

void destructor(void* o)
{
  printf("destructor says '%s'\n", (char*)o);
  free(o);
}
