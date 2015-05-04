#include <stdlib.h>

void addmatrices(double *a,size_t row_a,size_t col_a,double *b, size_t row_b,size_t col_b,double *c,size_t row_c,size_t col_c){
  size_t i,j;
  for(i=0;i<row_a;i++){
    for(j=0;j<col_a;j++){
      c[i*col_c + j] = a[i*col_a + j] + b[i*col_b + j];
    }
  }
}
