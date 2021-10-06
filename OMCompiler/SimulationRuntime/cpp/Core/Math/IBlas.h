#pragma once
/** @addtogroup math
 *   @{
*/

/*************************
    copies a vector, x, to a vector, y.
    uses unrolled loops for increments equal to one.
    jack dongarra, linpack, 3/11/78.
    modified 12/3/93, array(1) declarations changed to array(*)
*************************/

extern "C" void DCOPY(long int* n, double* dx, long int* incx, double* dy, long int* incy);
extern "C" void daxpy_(long int *N, double *DA, double *DX, long int *INCX, double *DY, long int *INCY);
// Matrix vector multiplication
extern "C" void dcopy_(long int *n, double *DX, long int *INCX, double *DY, long int *INCY);
// y := alpha*A*x + beta*y
extern "C" void dgemv_(char *trans, long int *m, long int *n, double *alpha, double *a, long int *lda, double *x, long int *incx, double *beta, double *y, long int *incy);
extern "C" void dscal_(long int *n, double *da, double *dx, long int *incx);
extern "C" void dger_(long int *m, long int *n, double *alpha, double *x, long int *incx, double *y, long int *incy, 	double *a, long int *lda);
//A := alpha*x*y' + A,
extern "C" double ddot_(long int *n, double *dx, long int *incx, double *dy, long int *incy);
// dot product
extern "C" double dnrm2_(long int *n, double *x, long int *incx);
//Euclidean norm

/** @} */ // end of math