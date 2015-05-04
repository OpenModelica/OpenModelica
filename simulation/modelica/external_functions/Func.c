#include <stdlib.h>
#include <stdio.h>

void Trans(const double* x, size_t x_r, size_t x_c, double* y, size_t y_r, size_t y_c)
{
  size_t i, j;
  for(i = 0; i < x_r; i++)
    for(j = 0; j < x_c; j++)
      y[i*x_c + j] = x[j*x_r + i];
}

