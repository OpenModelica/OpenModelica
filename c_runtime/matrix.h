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

#define solve_nonlinear_system_mixed(residual,no) do { \
	 int giveUp=0; \
	 int retries = 0; \
	 while(!giveUp) { \
		 giveUp = 1; \
		 hybrd_(residual,&n, nls_x,nls_fvec,&xtol,&maxfev,&ml,&mu,&epsfcn, \
    	    nls_diag,&mode,&factor,&nprint,&info,&nfev,nls_fjac,&ldfjac, \
        nls_r,&lr,nls_qtf,nls_wa1,nls_wa2,nls_wa3,nls_wa4); \
	    if (info == 0) { \
	        printf("improper input parameters to nonlinear eq. syst.\n"); \
	    } \
	    if ((info == 4 || info == 5 )&& retries < 3) { /* First try to decrease factor*/ \
	    	retries++; giveUp = 0; \
	    	factor = factor / 10.0; \
	    	if (sim_verbose)  \
	    		printf("Solving nonlinear system: iteration not making progress, trying to decrease factor to %f\n",factor); \
	    } else if ((info == 4 || info == 5) && retries < 5) { /* Secondly, try with different starting point*/  \
	    	int i; \
	    	for (i=0; i < n; i++) { nls_x[i]+=1e-6; }; \
   		 	retries++; giveUp=0; \
   		 	if (sim_verbose) \
   		 		printf("Solving nonlinear system: iteration not making progress, trying with different starting points (+1e-6)"); \
	    } \
	    else if (info >= 2 && info <= 5) { \
	       found_solution=-1; \
	    } \
	 } \
} while(0) /* (no trailing ;)*/ 

#define solve_nonlinear_system(residual,no) do { \
	 int giveUp=0; \
	 int retries = 0; \
	 while(!giveUp) { \
		 giveUp = 1; \
		 hybrd_(residual,&n, nls_x,nls_fvec,&xtol,&maxfev,&ml,&mu,&epsfcn, \
    	    nls_diag,&mode,&factor,&nprint,&info,&nfev,nls_fjac,&ldfjac, \
        nls_r,&lr,nls_qtf,nls_wa1,nls_wa2,nls_wa3,nls_wa4); \
    	if (info == 0) { \
    	    printf("improper input parameters to nonlinear eq. syst.\n"); \
    	} \
    	if ((info == 4 || info == 5 )&& retries < 3) { /* First try to decrease factor*/ \
    		retries++; giveUp = 0; \
    		factor = factor / 10.0; \
    		 	if (sim_verbose)  \
	    		printf("Solving nonlinear system: iteration not making progress, trying to decrease factor to %f\n",factor); \
    	} else if ((info == 4 || info == 5) && retries < 5) { /* Secondly, try with different starting point*/  \
    		int i; \
    		for (i=0; i < n; i++) { nls_x[i]+=0.1; }; \
    		retries++; giveUp=0; \
    		if (sim_verbose) \
   		 		printf("Solving nonlinear system: iteration not making progress, trying with different starting points (+1e-6)"); \
    	} \
    	else if (info >= 2 && info <= 5) { \
    	    printf("error solving nonlinear system nr. %d at time %f\n",no,time); \
    	} \
	 }\
} while(0) /* (no trailing ;)*/ 

#define declare_matrix(A,nrows,ncols) double *A = new double[nrows*ncols]; \
assert(A!=0); \
for (int i=0;i<nrows*ncols;i++) A[i]=0.0;

#define free_matrix(A) delete []A;
#define free_vector(A) delete []A;

#define declare_vector(v,nelts) double *v=new double[nelts];\
assert(v!=0); \
for (int i=0;i<nelts;i++) v[i]=0.0;

/* Matrixes using column major order (as in Fortran) */
#define set_matrix_elt(A,r,c,n_rows,value) A[r+n_rows*c]=value
#define get_matrix_elt(A,r,c,n_rows) A[r+n_rows*c]

/* Vectors */
#define set_vector_elt(v,i,value) v[i]=value
#define get_vector_elt(v,i) v[i]

#define solve_linear_equation_system(A,b,size,id) do { long int n=size; \
long int nrhs=1; /* number of righthand sides*/\
long int lda=n /* Leading dimension of A */; long int ldb=n; /* Leading dimension of b*/\
long int * ipiv=new long int[n]; /* Pivott indices */ \
assert(ipiv != 0); \
for(int i=0; i<n; i++) ipiv[i] = 0; \
long int info; /* output */ \
dgesv_(&n,&nrhs,&A[0],&lda,ipiv,&b[0],&ldb,&info); \
 if (info < 0) { \
   printf("Error solving linear system of equations (no. %d) at time %f. Argument %d illegal.\n",id,localData->timeValue,info); \
 } \
 else if (info > 0) { \
   printf("Error sovling linear system of equations (no. %d) at time %f, system is singular.\n",id,localData->timeValue); \
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
double xtol = 1e-9; \
double epsfcn=1e-9; \
int maxfev=8000; \
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


#define mixed_equation_system(size) do { \
int found_solution = 0; \
int cur_value_indx=0; \
do { \
double discrete_loc[size]; \
double discrete_loc2[size];

#define mixed_equation_system_end(size) } while (!found_solution); \
 } while(0)

#define check_discrete_values(size) do {int i; \
if (!found_solution) { \
if (found_solution == -1) { /*system of equations failed*/ \
found_solution=0; \
} else { \
found_solution = 1; \
for (i=0; i < size; i++) { \
if (fabs((discrete_loc[i] - discrete_loc2[i])) > 1e-12) {\
found_solution=0;\
/*printf("did not find solution, iterate\n");*/ \
}\
 }\
}\
if (!found_solution ) { \
cur_value_indx++; \
/*printf("iterating mixed system, i=%d\n",cur_value_indx);*/ \
/* try next set of values*/ \
for (i=0; i < size; i++) { \
 *loc_ptrs[i]=values[cur_value_indx*size+i];  \
/*printf("Setting new value for disc[%d] = %f\n",i,values[cur_value_indx*size+i]);*/ \
} \
} \
} \
} while(0)
#define roundEps(x) (((x) > 0) ? (floor(x*1.0e10)*1e-10): (ceil(x*1.0e10)*1e-10))
#endif
