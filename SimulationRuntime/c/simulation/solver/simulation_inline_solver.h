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

/*
 * Inline solver implementation using C preprocessor macros
 * Code generation is the same for each inline method (euler,rk,none)
 * They are changed during compile-time through the use of preprocessor macros
 */
#ifndef SIMULATION_INLINE_SOLVER_H_
#define SIMULATION_INLINE_SOLVER_H_

#ifdef __cplusplus
extern "C" {
#endif

/* The inline implementations require the use of some temporary storage
 * Dimension 0 is swapped with the states array at the end of each time step
 */
extern double** work_states;
extern const int inline_work_states_ndims;


#define swap_double_arr(A,B) \
  { \
    double *C; \
    C=A;A=B;B=C;\
  }

/*
   If OMC_FORCE_SOLVER is defined, only that solver produces correct results.
   No other solver is allowed.

   The char pointer is stored in the simulation file; the simulation runtime
   may _not_ depend on the macro!
*/
extern const char* _omc_force_solver;

#if defined(_OMC_INLINE_EULER)

#define _OMC_ENABLE_INLINE
#define _OMC_FORCE_SOLVER "inline-euler"
#define _OMC_SOLVER_WORK_STATES_NDIMS 1

#define begin_inline(void) { data->localData[0]->timeValue += stepSize;
#define end_inline(void) swap_double_arr(data->localData[0]->realVars,work_states[0]);}

#define inline_integrate(derx) { long _omc_index = &derx-(data->localData[0]->realVars + data->modelData.nStates); work_states[0][_omc_index] = data->localData[0]->realVars[_omc_index] + data->localData[0]->realVars[_omc_index + data->modelData.nStates] * stepSize; }
#define inline_integrate_array(sz,derx) { long _omc_size = sz; long _omc_index; \
  for(_omc_index = &derx-(data->localData[0]->realVars + data->modelData.nStates); _omc_index < &derx-(data->localData[0]->realVars + data->modelData.nStates)+_omc_size; _omc_index++) \
    work_states[0][_omc_index] = data->localData[0]->realVars[_omc_index] + data->localData[0]->realVars[_omc_index + data->modelData.nStates] * stepSize; \
}

#elif defined(_OMC_INLINE_RK)

#define _OMC_ENABLE_INLINE

#define _OMC_FORCE_SOLVER "inline-rungekutta"
#define _OMC_SOLVER_WORK_STATES_NDIMS 4

#define _OMC_RK_RESULT_DIM 0
#define _OMC_RK_X_BACKUP_DIM 1
#define _OMC_RK_NEXT_RESULT_DIM 2 /* We need to swap these every step due to mixed systems code generation */
#define _OMC_RK_NEXT_X_VECTOR_DIM 3

#if 1
/* RK4 */
const int _omc_rk_s = 4;
/* Note: These arrays may look erroneous; but we calculate index 2,3,4 then 1 */
const double _omc_rk_b[4] = {1.0/3.0,1.0/3.0,1.0/6.0,1.0/6.0};
const double _omc_rk_c[4] = {0.5,0.5,1.0,1.0};
#endif
#if 0
/* euler */
const int _omc_rk_s = 1;
const double _omc_rk_b[1] = {1.0};
const double _omc_rk_c[1] = {1.0};
#endif

#define copy_double_arr(A,B,n) \
  { \
    double *C  = work_states[_OMC_RK_X_BACKUP_DIM]; \
    memcpy(C,A,n*sizeof(double)); \
    memcpy(A,B,n*sizeof(double)); \
    memcpy(B,C,n*sizeof(double)); \
  }

#define begin_inline(void) { /* begin block */ \
  double _omc_rk_time_backup = data->localData[1]->timeValue; \
  static int initial = 1; \
  int _omc_rk_ix; \
  if(initial) { \
    int i; \
    memcpy(work_states[_OMC_RK_RESULT_DIM],data->localData[1]->realVars,data->modelData.nStates*sizeof(double)); \
    memcpy(work_states[_OMC_RK_X_BACKUP_DIM],data->localData[1]->realVars,data->modelData.nStates*sizeof(double)); \
    for(i=0; i<data->modelData.nStates; i++) { \
      work_states[_OMC_RK_RESULT_DIM][i] += data->localData[1]->realVars[i + data->modelData.nStates]*_omc_rk_b[_omc_rk_s-1]* stepSize; \
    } \
    initial = 0; \
  } \
  for(_omc_rk_ix = 0; _omc_rk_ix < _omc_rk_s; _omc_rk_ix++) { /* begin for */ \
    double _omc_rk_cur_step = _omc_rk_c[_omc_rk_ix] *  stepSize; \
    data->localData[0]->timeValue = _omc_rk_time_backup + _omc_rk_cur_step;

#define inline_integrate(derx) { \
  long _omc_index = &derx-(data->localData[0]->realVars + data->modelData.nStates); \
  work_states[_OMC_RK_NEXT_RESULT_DIM][_omc_index] = work_states[_OMC_RK_RESULT_DIM][_omc_index] + data->localData[0]->realVars[_omc_index + data->modelData.nStates]*_omc_rk_b[_omc_rk_ix]*stepSize; \
  work_states[_OMC_RK_NEXT_X_VECTOR_DIM][_omc_index] = work_states[_OMC_RK_X_BACKUP_DIM][_omc_index] + data->localData[0]->realVars[_omc_index + data->modelData.nStates]*_omc_rk_cur_step; \
}

#define inline_integrate_array(sz,derx) { \
  long _omc_size = sz; long _omc_index; \
  for(_omc_index = &derx-(data->localData[0]->realVars + data->modelData.nStates); _omc_index < &derx-(data->localData[0]->realVars + data->modelData.nStates)+_omc_size; _omc_index++) { \
    work_states[_OMC_RK_NEXT_RESULT_DIM][_omc_index] = work_states[_OMC_RK_RESULT_DIM][_omc_index] + data->localData[0]->realVars[_omc_index + data->modelData.nStates]*_omc_rk_b[_omc_rk_ix]* stepSize; \
    work_states[_OMC_RK_NEXT_X_VECTOR_DIM][_omc_index] = work_states[_OMC_RK_X_BACKUP_DIM][_omc_index] + data->localData[0]->realVars[_omc_index + data->modelData.nStates]*_omc_rk_cur_step; \
  } \
}

#define end_inline(void) \
    copy_double_arr(work_states[_OMC_RK_RESULT_DIM],work_states[_OMC_RK_NEXT_RESULT_DIM],data->modelData.nStates); \
    copy_double_arr(data->localData[0]->realVars,work_states[_OMC_RK_NEXT_X_VECTOR_DIM],data->modelData.nStates); \
    if(_omc_rk_ix == _omc_rk_s-2) { /* s-2 is the "last" step; s-1 is step 0, but we calculate the steps in the order 1,2,..,s-1,0  */ \
      copy_double_arr(data->localData[0]->realVars,work_states[_OMC_RK_RESULT_DIM],data->modelData.nStates); \
      memcpy(work_states[_OMC_RK_RESULT_DIM],data->localData[0]->realVars,data->modelData.nStates*sizeof(double)); \
      memcpy(work_states[_OMC_RK_X_BACKUP_DIM],data->localData[0]->realVars,data->modelData.nStates*sizeof(double)); \
    } \
  } /* end for*/ \
} /* end block */

#else

#define _OMC_FORCE_SOLVER NULL
#define _OMC_SOLVER_WORK_STATES_NDIMS 0

#define begin_inline(void)
#define end_inline(void)

#define inline_integrate(x)
#define inline_integrate_array(sz,x)

#endif

#ifdef __cplusplus
}
#endif

#endif /* SIMULATION_INLINE_SOLVER_H_ */
