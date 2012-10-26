/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef _MATRIX_H_
#define _MATRIX_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "simulation_data.h"
#include "blaswrap.h"
#include "f2c.h"
#ifdef VOID
#undef VOID
#endif

extern
int _omc_dgesv_(integer *n, integer *nrhs, doublereal *a, integer
     *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info);

#ifdef __cplusplus
}
#endif

#define print_matrix(A,d1,d2) do {\
  int r = 0, c = 0;\
  printf("{{"); \
  for(r = 0; r < d1; r++) {\
    for (c = 0; c < d2; c++) {\
      printf("%2.3f",A[r + d1 * c]);\
      if (c != d2-1) printf(",");\
    }\
    if(r != d1-1) printf("},{");\
  }\
  printf("}}\n"); \
} while(0)
#define print_vector(b,d1) do {\
  int i = 0; \
  printf("{");\
  for(i = 0;i < d1; i++) { \
    printf("%2.3f", b[i]); \
    if (i != d1-1) printf(",");\
  } \
  printf("}\n"); \
} while(0)

/* Matrixes using column major order (as in Fortran) */
#define set_matrix_elt(A,r,c,n_rows,value) A[r + n_rows * c] = value
#define get_matrix_elt(A,r,c,n_rows) A[r + n_rows * c]

/* Vectors */
#define set_vector_elt(v,i,value) v[i] = value
#define get_vector_elt(v,i) v[i]

#define solve_linear_equation_system(A,b,size,id) do { integer n = size; \
integer nrhs = 1; /* number of righthand sides*/\
integer lda = n /* Leading dimension of A */; integer ldb=n; /* Leading dimension of b*/\
integer * ipiv = (integer*) calloc(n,sizeof(integer)); /* Pivott indices */ \
integer info = 0; /* output */ \
assert(ipiv != 0); \
_omc_dgesv_(&n,&nrhs,&A[0],&lda,ipiv,&b[0],&ldb,&info); \
 if (info < 0) { \
   INFO3(LOG_NONLIN_SYS,"Error solving linear system of equations (no. %d) at time %f. Argument %d illegal.\n",id,data->localData[0]->timeValue,info); \
   data->simulationInfo.found_solution = -1; \
 } \
 else if (info > 0) { \
   INFO2(LOG_NONLIN_SYS,"Error solving linear system of equations (no. %d) at time %f, system is singular.\n",id,data->localData[0]->timeValue); \
   data->simulationInfo.found_solution = -1; \
 } \
free(ipiv); \
} while (0) /* (no trailing ; ) */

#define extraPolate(v,old1,old2) (data->localData[1]->timeValue == data->localData[2]->timeValue ) ? v: \
(((old1)-(old2))/(data->localData[1]->timeValue-data->localData[2]->timeValue)*data->localData[0]->timeValue \
+(data->localData[1]->timeValue*(old2)-data->localData[2]->timeValue*(old1))/ \
(data->localData[1]->timeValue-data->localData[2]->timeValue))

#define mixed_equation_system(size) do { \
    int stepCount = 0; \
    data->simulationInfo.found_solution = 0; \
    do { \
        double discrete_loc[size] = {0}; \
        double discrete_loc2[size] = {0};

#define mixed_equation_system_end(size) \
    stepCount++; \
    INFO1(LOG_NONLIN_SYS," ####  hybrid equation system solver step %d.", stepCount); \
 } while (!data->simulationInfo.found_solution); \
 } while(0)

#define check_discrete_values(boolVar, size, index) \
do { \
  int i = 0; \
  INFO1(LOG_NONLIN_SYS," ####  Check VAR (system %d)", index); \
  if (data->simulationInfo.found_solution == -1) { \
      /*system of equations failed */ \
      data->simulationInfo.found_solution = 0; \
      INFO(LOG_NONLIN_SYS," ####  NO SOLUTION "); \
  } else { \
      data->simulationInfo.found_solution = 1; \
      for (i = 0; i < size; i++) { \
          if (fabs((discrete_loc[i] - discrete_loc2[i])) > 1e-12) {\
          data->simulationInfo.found_solution=0;\
              break;\
          }\
      }\
      INFO1(LOG_NONLIN_SYS," #### SOLUTION = %c",data->simulationInfo.found_solution?'T':'F'); \
  }\
  if (!data->simulationInfo.found_solution ) { \
    if (nextVar(boolVar,size)) { \
      /* try next set of values*/ \
      INFO(LOG_NONLIN_SYS," #### next STATE "); \
      for (i = 0; i < size; i++) { \
        *loc_ptrs[i] = *loc_prePtrs[i] != boolVar[i];  \
        int ix = (loc_ptrs[i]-data->localData[0]->booleanVars); \
        const char *__name = data->modelData.booleanVarsData[ix].info.name; \
        INFO4(LOG_NONLIN_SYS, "%s = %d  pre(%s)= %d",__name, *loc_ptrs[i], __name, *loc_prePtrs[i]); \
      } \
    } else  {\
      /* while the initialization it's ok to every time a solution */ \
      if (!data->simulationInfo.initial){ \
        WARNING2(LOG_STDOUT, "Error solving hybrid equation system with index %d at time %e", index, data->localData[0]->timeValue); \
      } \
      data->simulationInfo.needToIterate = 1; \
      data->simulationInfo.found_solution = -1; \
      /*TODO: "break simulation?"*/ \
    } \
  } \
  /* we found a solution*/ \
  if (data->simulationInfo.found_solution && DEBUG_STREAM(LOG_NONLIN_SYS)){ \
    int i = 0; \
    INFO1(LOG_NONLIN_SYS," #### SOLUTION FOUND! (system %d)", index); \
    for (i = 0; i < size; i++) { \
        int ix = (loc_ptrs[i]-data->localData[0]->booleanVars); \
        const char *__name = data->modelData.booleanVarsData[ix].info.name; \
        INFO4(LOG_NONLIN_SYS, "%s = %d  pre(%s)= %d",__name, *loc_ptrs[i], __name, data->simulationInfo.booleanVarsPre[ix]); \
    } \
  } \
} while(0)

#endif
