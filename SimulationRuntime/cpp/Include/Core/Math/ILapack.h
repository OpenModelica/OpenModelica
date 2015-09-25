#pragma once
/** @addtogroup math
 *   @{
*/


/********************************
*  DGESV computes the solution to a real system of linear equations
*     A * X = B,
*  where A is an N-by-N matrix and X and B are N-by-NRHS matrices.
*
*  The LU decomposition with partial pivoting and row interchanges is
*  used to factor A as
*     A = P * L * U,
*  where P is a permutation matrix, L is unit lower triangular, and U is
*  upper triangular.  The factored form of A is then used to solve the
*  system of equations A * X = B.
********************************/

extern "C" void dgesv_(long int *n, long int *nrhs, double *J, long int *ldj, long int *pivot,double *b, long int *ldb, long int *idid);
extern "C" void dgetrf_(long int *m, long int *n, double *a, long int *lda, long int *ipiv, long int *info);
extern "C" void dgetrs_(char *trans, long int *n, long int *nrhs, double *a, long int *lda, long int *ipiv, double *b, long int *ldb, long int *info);
extern "C" void dgetri_(long int *n, double *a, long int *lda, long int *ipiv, double *work, long int *lwork, long int *info);
extern "C" void dgesv_(long int *n, long int *nrhs, double *J, long int *ldj, long int *pivot,double *b, long int *ldb, long int *idid);
extern "C" void dgetc2_(long int *n, double *J, long int *ldj, long int *ipivot, long int *jpivot, long int *idid);
extern "C" void dgesc2_(long int *n, double *J, long int *ldj, double* f, long int *ipivot, long int *jpivot, double *scale);



/********************************
* DGESVX uses the LU factorization to compute the solution to a real
*  system of linear equations
*     A * X = B,
*  where A is an N-by-N matrix and X and B are N-by-NRHS matrices.
*
*  Error bounds on the solution and a condition estimate are also
*  provided.
*
*  Description
*  ===========
*
*  The following steps are performed:
*
*  1. If FACT = 'E', real scaling factors are computed to equilibrate
*     the system:
*        TRANS = 'N':  diag(R)*A*diag(C)     *inv(diag(C))*X = diag(R)*B
*        TRANS = 'T': (diag(R)*A*diag(C))**T *inv(diag(R))*X = diag(C)*B
*        TRANS = 'C': (diag(R)*A*diag(C))**H *inv(diag(R))*X = diag(C)*B
*     Whether or not the system will be equilibrated depends on the
*     scaling of the matrix A, but if equilibration is used, A is
*     overwritten by diag(R)*A*diag(C) and B by diag(R)*B (if TRANS='N')
*     or diag(C)*B (if TRANS = 'T' or 'C').
*
*  2. If FACT = 'N' or 'E', the LU decomposition is used to factor the
*     matrix A (after equilibration if FACT = 'E') as
*        A = P * L * U,
*     where P is a permutation matrix, L is a unit lower triangular
*     matrix, and U is upper triangular.
*
*  3. If some U(i,i)=0, so that U is exactly singular, then the routine
*     returns with INFO = i. Otherwise, the factored form of A is used
*     to estimate the condition number of the matrix A.  If the
*     reciprocal of the condition number is less than machine precision,
*     INFO = N+1 is returned as a warning, but the routine still goes on
*     to solve for X and compute error bounds as described below.
*
*  4. The system of equations is solved for X using the factored form
*     of A.
*
*  5. Iterative refinement is applied to improve the computed solution
*     matrix and calculate error bounds and backward error estimates
*     for it.
*
*  6. If equilibration was used, the matrix X is premultiplied by
*     diag(C) (if TRANS = 'N') or diag(R) (if TRANS = 'T' or 'C') so
*     that it solves the original system before equilibration.

********************************/
extern "C" void DGESVX(char *fact, char * trans, long int * n, long int *nrhs,
                       double *J, long int *ldj, double *Jscal, long int *ldjscal,
                       double *pivot, char *equilibriate, double *r, double *c,
                       double *b, long int *ldb, double *x, long int *ldx,
                       double* rcond, double *forwerr, double *backerr,
                       double* work, long int *iwork, long int *idid);



/********************************
*  DGESVD computes the singular value decomposition (SVD) of a real
*  M-by-N matrix A, optionally computing the left and/or right singular
*  vectors. The SVD is written
*
*       A = U * SIGMA * transpose(V)
*
*  where SIGMA is an M-by-N matrix which is zero except for its
*  min(m,n) diagonal elements, U is an M-by-M orthogonal matrix, and
*  V is an N-by-N orthogonal matrix.  The diagonal elements of SIGMA
*  are the singular values of A; they are real and non-negative, and
*  are returned in descending order.  The first min(m,n) columns of
*  U and V are the left and right singular vectors of A.
*
*  Note that the routine returns V**T, not V.
********************************/

extern "C" void DGESVD(char *JOBU, char *JOBVT, long int *M,  long int *N, double *A, long int *LDA,
            double *S, double *U, long int *LDU, double *VT, long int *LDVT,
            double *WORK, long int *LWORK, long int *INFO);




/********************************
DGELSS computes the minimum norm solution to a real linear least squares problem:

Minimize 2-norm(| b - A*x |)

using the singular value decomposition (SVD) of A. A is an M-by-N
matrix which may be rank-deficient.
********************************/
extern "C" void DGELSS(long int *M, long int *N, long int *NRHS, double *A, long int *LDA,
            double *B, long int *LDB, double *S, double *RCOND, long int *RANK,
            double *WORK, long int *LWORK, long int *INFO);




/********************************
DGEEV computes for an N-by-N real nonsymmetric matrix A, the
eigenvalues and, optionally, the left and/or right eigenvectors.

The right eigenvector v(j) of A satisfies
    A * v(j) = lambda(j) * v(j)
where lambda(j) is its eigenvalue.

The left eigenvector u(j) of A satisfies
    u(j)**H * A = lambda(j) * u(j)**H
where u(j)**H denotes the conjugate transpose of u(j).

The computed eigenvectors are normalized to have Euclidean norm
equal to 1 and largest component real.
********************************/
extern "C" void DGEEV(char *JOBVL, char *JOBVR, long int *N, double *A, long int *LDA,
           double *WR, double *WI, double *VL, long int *LDVL, double *VR, long int *LDVR,
           double *WORK, long int *LWORK, long int *INFO);





/********************************
*  SGESVD computes the singular value decomposition (SVD) of a real
*  M-by-N matrix A, optionally computing the left and/or right singular
*  vectors. The SVD is written
*
*       A = U * SIGMA * transpose(V)
*
*  where SIGMA is an M-by-N matrix which is zero except for its
*  min(m,n) diagonal elements, U is an M-by-M orthogonal matrix, and
*  V is an N-by-N orthogonal matrix.  The diagonal elements of SIGMA
*  are the singular values of A; they are real and non-negative, and
*  are returned in descending order.  The first min(m,n) columns of
*  U and V are the left and right singular vectors of A.
*
*  Note that the routine returns V**T, not V.
********************************/
extern "C" void SGESVD(char *JOBU, char *JOBVT, long int *M,  long int *N, double *A, long int *LDA,
            double *S, double *U, long int *LDU, double *VT, long int *LDVT,
            double *WORK, long int *LWORK, long int *INFO);



/********************************
*  DGGEV computes for a pair of N-by-N real nonsymmetric matrices (A,B)
*  the generalized eigenvalues, and optionally, the left and/or right
*  generalized eigenvectors.
*
*  A generalized eigenvalue for a pair of matrices (A,B) is a scalar
*  lambda or a ratio alpha/beta = lambda, such that A - lambda*B is
*  singular. It is usually represented as the pair (alpha,beta), as
*  there is a reasonable interpretation for beta=0, and even for both
*  being zero.
*
*  The right eigenvector v(j) corresponding to the eigenvalue lambda(j)
*  of (A,B) satisfies
*
*                   A * v(j) = lambda(j) * B * v(j).
*
*  The left eigenvector u(j) corresponding to the eigenvalue lambda(j)
*  of (A,B) satisfies
*
*                   u(j)**H * A  = lambda(j) * u(j)**H * B .
*
*  where u(j)**H is the conjugate-transpose of u(j).
********************************/

extern "C" void DGGEV(char *JOBVL, char *JOBVR,  long int *N, double* A, long int* LDA, double *B, long int *LDB, double *ALPHAR, double *ALPHAI, double *BETA, double* VL, long int* LDVL, double *VR, long int* LDVR, double* WORK, long int* LWORK, long int *INFO);
/** @} */ // end of math