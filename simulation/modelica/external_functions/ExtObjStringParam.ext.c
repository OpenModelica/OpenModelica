#include <stdio.h>

void* constructor(const char* filename,const char* dummy)
{
  /* This is quite unsafe :) */
  printf("constructors says '%s'\n", (char*)filename);
  return (void*) filename;
}

void destructor(void* o)
{
  printf("destructor says '%s'\n", (char*)o);
}
