#include <stdio.h>
#include <stdlib.h>

void* obj_new(double x)
{
  double *o;
  if (x < 0) {
    return NULL;
  }
  o = malloc(sizeof(double));
  *o = x;
  return o;
}

void obj_free(void *o)
{
  if (!o) {
    printf("destructor called for an object that was not constructed\n");
    return;
  }
  free(o);
}
