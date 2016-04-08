/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file radau.h
 * author: team Bielefeld
 */

#ifndef _RADAU_H_
#define _RADAU_H_

#include "simulation_data.h"
#include "solver_main.h"
#include "omc_config.h"

#ifdef WITH_SUNDIALS
  #include <math.h>
  #include <nvector/nvector_serial.h>

  #ifdef __cplusplus
  extern "C"
  {
  #endif

    typedef struct{
      N_Vector x;
      N_Vector sVars;
      N_Vector sEqns;
      N_Vector c;
      void* kmem;
      int glstr;
      int error_code;
      int mset;
      double fnormtol;
      double scsteptol;
    }KDATAODE;

    typedef struct{
      double *x0;
      double *f0;
      double *x;
      int nStates;
      double dt;
      double *currentStep;
      double t0;
      double *min;
      double *max;
      double *derx;
      double *s;
      long double **c;
      double *a;
    }NLPODE;

    typedef struct{
      KDATAODE *kData;
      NLPODE *nlp;
      DATA *data;
      threadData_t *threadData;
      SOLVER_INFO *solverInfo;
      int N;
      int flag;
    }KINODE;

#else
    typedef struct{
      void *kData;
      void *nlp;
      DATA *data;
      SOLVER_INFO *solverInfo;
      int N;
      int flag;
    }KINODE;

#endif /* SUNDIALS */
  int allocateKinOde(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, int flag, int N);
  int freeKinOde(DATA* data, SOLVER_INFO* solverInfo, int N);
  int kinsolOde(SOLVER_INFO* solverInfo);
#ifdef __cplusplus
};
#endif

#endif /* _RADAU_H_ */
