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

#include "../../../Compiler/runtime/config.h"
#ifdef WITH_SUNDIALS

#ifndef _RADAU_H_
#define _RADAU_H_

  #include "simulation_data.h"
  #include "../simulation/solver/solver_main.h"
  #include <math.h>
  #include "omc_error.h"

  #include <kinsol/kinsol.h>
  #include <kinsol/kinsol_dense.h>
  #include <nvector/nvector_serial.h>
  #include <sundials/sundials_types.h>
  #include <sundials/sundials_math.h>

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
    }KINSOLRADAU;

    typedef struct
    {
      /* state */
      double* x0;

      int nState;
      double* dt;
      double* t0;

      double* derx;
      double* min;
      double* max;
      double* s;

      double C[3][4];
      DATA* data;
      double a[3];
      KINSOLRADAU* kData;

    }RADAUIIA;

    int allocateRadauIIA(RADAUIIA* rData,DATA* data, SOLVER_INFO* solverInfo);
    int allocateKinsol(KINSOLRADAU* kData, void* userData);

    int freeRadauIIA(RADAUIIA* rData);
    int freeKinsol(KINSOLRADAU* kData);

    int kinsolRadauIIA(RADAUIIA* rData);

  #ifdef __cplusplus
  };
  #endif


#endif /* _RADAU_H_ */

#endif /* SUNDIALS */
