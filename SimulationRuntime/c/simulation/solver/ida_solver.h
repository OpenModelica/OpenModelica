/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2016, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

 /*! \file ida_solver.h
 */

#ifndef OMC_IDA_SOLVER_H
#define OMC_IDA_SOLVER_H

#include "openmodelica.h"
#include "simulation_data.h"
#include "util/simulation_options.h"
#include "simulation/solver/solver_main.h"

#ifdef WITH_SUNDIALS

#include <sundials/sundials_nvector.h>
#include <nvector/nvector_serial.h>
#include <ida/ida.h>
#include <ida/ida_dense.h>

typedef struct IDA_USERDATA
{
  DATA* data;
  threadData_t* threadData;
}IDA_USERDATA;

typedef struct IDA_SOLVER
{
  /* ### configuration  ### */
  int setInitialSolution;
  int jacobianMethod;            /* specifices the method to calculate the jacobian matrix */

  /* ### work arrays ### */
  N_Vector y;
  N_Vector yp;

  /* ### work array used in jacobian calculation */
  double sqrteps;
  double *ysave;
  double *ypsave;
  double *delta_hh;
  N_Vector errwgt;
  N_Vector newdelta;

  /* ### ida internal data */
  void* ida_mem;
  IDA_USERDATA* simData;

  /* ### daeMode ### */
  int daeMode;                  /* if TRUE then solve dae more with a reals residual function */
  long int N;
  double *states;
  double *statesDer;
  int (*residualFunction)(double time, N_Vector yy, N_Vector yp, N_Vector res, void* userData);

}IDA_SOLVER;

/* initial main ida Data */
int
ida_solver_initial(DATA* simData, threadData_t *threadData, SOLVER_INFO* solverInfo, IDA_SOLVER *idaData);

/* deinitial main ida Data */
int
ida_solver_deinitial(IDA_SOLVER *idaData);

/* main ida function to make a step */
int
ida_solver_step(DATA* simData, threadData_t *threadData, SOLVER_INFO* solverInfo);

#endif

#endif
