#include <limits>
#include <iostream>
#include <string>
#include <cmath>
#include <algorithm>

#include "omp.h"

#define TRUE_ (1)
#define FALSE_ (0)




double pow_dd(double *ap, double *bp) {
    return pow(*ap,*bp);
}

double d_sign(double *a, double *b) {
    double x;
    x=(*a>=0? *a : - *a );
    return (*b>=0 ? x : -x);
}

extern "C" {
    int dcopy_(int *, double *, int *, double *, int *);
    extern int daxpy_(int *, double *, double *, int *, double *, int *);
    extern int dgbtrf_(int *, int *, int *, int *, double *, int *, int *, int *);
    extern int dgetrf_(int *, int *, double *, int *, int *, int *);
    extern int dscal_(int *, double *, double *, int *);
    extern int dgetrs_(char *trans, int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, int *info, int);
    extern int dgbtrs_(char *trans, int *n, int *kl, int *ku, int *nrhs, double *ab, int *ldab, int *ipiv, double *b, int *ldb, int *info, int);
    extern double dnrm2_(int *, double *, int *);
    extern double ddot_(int *, double *, int *, double *, int *);
}
