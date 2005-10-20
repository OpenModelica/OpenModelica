#ifndef __MATRIX_H
#define __MATRIX_H

#include "blaswrap.h"
#include "f2c.h"


#if defined(__cplusplus)
extern "C" {

#endif



int dgesv_(integer *n, integer *nrhs, doublereal *a, integer 
	   *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info);

void hybrd_(void (*) (int*, double *, double*, int*),
	    int* n, double* x,double* fvec,double* xtol,
	    int* maxfev, int* ml,int* mu,double* epsfcn,
	    double* diag,int* mode, double* factor, 
	    int* nprint,int* info,int* nfev,double* fjac,
	    int* ldfjac,double* r, int* lr, double* qtf,
	    double* wa1,double* wa2,double* wa3,double* wa4);
  
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
} while (0) /* (no trailing ; ) */ 


#define start_nonlinear_system(size) { double nls_x[size]; \
double nls_fvec[size]; \
double nls_diag[size]; \
double nls_r[(size*(size+1)/2)]; \
double nls_qtf[size]; \
double nls_wa1[size]; \
double nls_wa2[size]; \
double nls_wa3[size]; \
double nls_wa4[size]; \
double xtol = 1e-6; \
double epsfcn=1e-6; \
int maxfev=2000; \
int n=size; \
int ml=size-1; \
int mu = size-1; \
int mode=1; \
int info,nfev; \
double factor=100.0; \
int nprint = 0; \
int lr = (size*(size+1))/2; \
int ldfjac = size; \
double nls_fjac[size*size]

#define end_nonlinear_system() } do {} while(0)

#endif
