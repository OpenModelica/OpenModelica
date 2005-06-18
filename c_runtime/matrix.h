#ifndef __MATRIX_H
#define __MATRIX_H


#if defined(__cplusplus)
extern "C" {

#endif

#include "blaswrap.h"
#include "f2c.h"


int dgesv_(integer *n, integer *nrhs, doublereal *a, integer 
	   *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info);
#if defined(__cplusplus)
}
#endif

#define declare_matrix(A,nrows,ncols) double *A = new double[nrows*ncols]; \
assert(A!=0); 

#define declare_vector(v,nelts) double *v=new double[nelts];\
assert(v!=0);

/* Matrixes using column major order (as in Fortran) */
#define set_matrix_elt(A,r,c,n_rows,value) A[r+n_rows*c]=value
#define get_matrix_elt(A,r,c,n_rows) A[r+n_rows*c]

/* Vectors */
#define set_vector_elt(v,i,value) v[i]=value
#define get_vector_elt(v,i) v[i]

#define solve_linear_equation_system(A,b,size) do { long int n=size; \
long int nrhs=1; /* number of righthand sides*/\
long int lda=n /* Leading dimension of A */; long int ldb=n; /* Leading dimension of b*/\
long int * ipiv=new long int[n]; /* Pivott indices */ \
assert(ipiv != 0); \
for(int i=0; i<n; i++) ipiv[i] = 0; \
long int info; /* output */ \
dgesv_(&n,&nrhs,&A[0],&lda,ipiv,&b[0],&ldb,&info); \
 if (info < 0) { \
   printf("Error solving linear system of equations. Argument %d illegal.\n",info); \
 } \
 else if (info > 0) { \
   printf("Error sovling linear system of equations, system is singular.\n"); \
 } \
} while (0) /* (no trailing ; ) */ \


#endif
