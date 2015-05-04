#include <stdlib.h>

void ExternalFunction2_f(double* x, size_t xdim1, double* y, size_t ydim1)
{
  size_t i;
  for(i=0; i<ydim1; i++) {
    y[i] = 3*x[i];
  }
}
