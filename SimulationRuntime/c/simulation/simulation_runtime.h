/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

/*! \file simulation_runtime.h
 *
 *  This file is a C++ header file for the simulation runtime. It contains
 *  solver functions and other simulation runtime specific functions
 */

#ifndef _SIMULATION_RUNTIME_H
#define _SIMULATION_RUNTIME_H

#include "openmodelica.h"

#include "simulation_data.h"

#include "rtclock.h"
#include <stdlib.h>
#include <string.h>
#include "simulation_inline_solver.h"

#ifdef __cplusplus
#include <string>

#include "linearize.h"
#include "simulation_result.h"

#ifndef NO_INTERACTIVE_DEPENDENCY
#include "../../../interactive/socket.h"
extern Socket sim_communication_port;
#endif

extern "C" {

extern int callSolver(DATA* simData, std::string result_file_cstr, std::string init_initMethod,
    std::string init_optiMethod, std::string init_file, double init_time, int lambda_steps, std::string outputVariablesAtEnd, int cpuTime);

extern int initializeResultData(DATA* simData, std::string result_file_cstr, int cpuTime);

#endif /* cplusplus */

extern int measure_time_flag;

extern const char *linear_model_frame; /* printf format-string with holes for 6 strings */

extern int modelTermination; /* Becomes non-zero when simulation terminates. */
extern int terminationTerminate; /* Becomes non-zero when user terminates simulation. */
extern int terminationAssert; /* Becomes non-zero when model call assert simulation. */
extern int warningLevelAssert; /* Becomes non-zero when model call assert with warning level. */
extern FILE_INFO TermInfo; /* message for termination. */

extern char* TermMsg; /* message for termination. */

/* defined in model code. Used to get name of variable by investigating its pointer in the state or alg vectors. */
extern const char* getNameReal(double* ptr);
extern const char* getNameInt(modelica_integer* ptr);
extern const char* getNameBool(modelica_boolean* ptr);
extern const char* getNameString(const char** ptr);


/* function for calculating state values on residual form */
/*used in DDASRT fortran function*/
extern int functionODE_residual(double *t, double *x, double *xprime, double *delta, fortran_integer *ires, double *rpar, fortran_integer* ipar);

/* function for calculating zeroCrossings */
/*used in DDASRT fortran function*/
extern int function_ZeroCrossingsDASSL(fortran_integer *neqm, double *t, double *y,
        fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar);

extern double getSimulationStepSize();
extern void printSimulationStepSize(double in_stepSize, double time);

/* the main function of the simulation runtime!
 * simulation runtime no longer has main, is defined by the generated model code which calls this function.
 */
extern int _main_SimulationRuntime(int argc, char**argv, DATA *data);
extern void communicateStatus(const char *phase, double completionPercent);

/* simulation JumpBuffer */
extern jmp_buf simulationJmpbuf;

/* integrator JumpBuffer */
extern jmp_buf integratorJmpbuf;

/* indicates the current possible jump place */
extern int currectJumpState;

#ifdef __cplusplus
}
#endif

#endif
