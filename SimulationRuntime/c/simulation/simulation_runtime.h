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

/*! \file simulation_runtime.h
 *
 *  This file is a C++ header file for the simulation runtime. It contains
 *  solver functions and other simulation runtime specific functions
 */

#ifndef _SIMULATION_RUNTIME_H
#define _SIMULATION_RUNTIME_H

#include "openmodelica.h"
#include "simulation_varinfo.h"

#include "simulation_data.h"

#include "rtclock.h"
#include <stdlib.h>
#include "events.h"
#include "simulation_inline_solver.h"
#include "delay.h"

#ifdef __cplusplus

#include "linearize.h"
#include "simulation_result.h"

#include <fstream>
#include <iostream>
#include <string>

using namespace std;

extern "C" {


/* \brief This class is used for throwing an exception when simulation code should be terminated.
 * For instance, when a terminate call occurse or if an assert becomes active
 */

class TerminateSimulationException {
public:
  TerminateSimulationException(const std::string& msg) : currentTime(0.0), errorMessage(msg) {}
  TerminateSimulationException(double time) : currentTime(time), errorMessage("") {}
  TerminateSimulationException(double time, const std::string& msg) : currentTime(time), errorMessage(msg) {}
  TerminateSimulationException() : currentTime(0.0) {}
  virtual ~TerminateSimulationException() {}
  const std::string& getMessage() const { return errorMessage; }
  double getTime() const { return currentTime; }
protected:
  double currentTime;
  std::string errorMessage;
};

extern simulation_result *sim_result;
/* function with template for linear model */
int callSolver(string, string, string, double, double, double, long, double);

#ifndef NO_INTERACTIVE_DEPENDENCY
#include "../../../interactive/socket.h"
extern Socket sim_communication_port;
#endif

#endif /* cplusplus */

/* C-Interface for sim_result->emit(); */
#ifdef __cplusplus
extern "C" {
#endif /* cplusplus */
void sim_result_emit();
#ifdef __cplusplus
}
#endif /* cplusplus */
extern char* TermMsg; /* message for termination. */

extern int measure_time_flag;
extern int sim_verbose; /* control debug output during simulation. */
extern int sim_noemit; /* control emitting result data to file */
extern int acceptedStep; /* !=0 when accepted step is calculated, 0 otherwise. */
extern int modelTermination; /* Becomes non-zero when user terminates simulation. */
extern int terminationTerminate; /* Becomes non-zero when user terminates simulation. */
extern int terminationAssert; /* Becomes non-zero when model call assert simulation. */
extern int warningLevelAssert; /* Becomes non-zero when model call assert with warning level. */
extern omc_fileInfo TermInfo; /* message for termination. */
extern const char *linear_model_frame; /* printf format-string with holes for 6 strings */

/* Flags for controlling logging to stdout */
extern const int LOG_STATS;
extern const int LOG_INIT;
extern const int LOG_RES_INIT;
extern const int LOG_SOLVER;
extern const int LOG_JAC;
extern const int LOG_ENDJAC;
extern const int LOG_EVENTS;
extern const int LOG_NONLIN_SYS;
extern const int LOG_ZEROCROSSINGS;
extern const int LOG_DEBUG;
/* Flags for modelErrorCodes */
extern const int ERROR_NONLINSYS;
extern const int ERROR_LINSYS;

int useVerboseOutput(int level);

/* Global data */
extern DATA *globalData;

extern char hasNominalValue[];  /* for all variables and parameters */
extern double nominalValue[];   /* for all variables and parameters */


extern int modelErrorCode;

extern double *gout;
extern double *gout_old;
extern modelica_boolean *gout_res;
extern modelica_boolean *backuprelations;

/*
 * this is used for initialize the DATA structure that is used in
 * all the generated functions.
 * The parameter controls what vectors should be initilized in
 * in the structure. Usually you can use the "ALL" flag which
 * initilizes all the vectors. This is needed for example in those ocasions
 * when another process have allocated the needed vectors.
 * Make sure that you call this function first because it sets the non-initialize
 * pointer to 0.
 *
 * This flag should be the same for second argument in callExternalObjectDestructors
 * to avoid memory leak.
 */
DATA* initializeDataStruc();
DATA *initializeDataStruc2(DATA *returnData);

/* this frees the memory that is allocated in the data-structure.
 * The second argument must have the same value as the argument in initializeDataStruc
 */
void callExternalObjectDestructors(DATA* data);
/* this is used to set the localData in the generated code
 * that is used in the diferrent generated functions
 *
 */
void setLocalData(DATA* data);
void init_Alias(DATA* data);


int
initializeEventData();
void
deinitializeEventData();


/* defined in model code. Used to get name of variable by investigating its pointer in the state or alg vectors. */
const char* getNameReal(double* ptr);
const char* getNameInt(modelica_integer* ptr);
const char* getNameBool(modelica_boolean* ptr);
const char* getNameString(const char** ptr);

void storeExtrapolationData();
void storeExtrapolationDataEvent();
void overwriteOldSimulationData(_X_DATA *data);
void restoreExtrapolationDataOld();

/* function for calculating ouput values */
/*used in DDASRT fortran function*/
int functionODE();          /* functionODE with respect to start-values */
int functionAlgebraics();   /* functionAlgebraics with respect to start-values */
int functionAliasEquations();

/* function do an event update step */
void
update_DAEsystem();

/* function for calculating state values on residual form */
/*used in DDASRT fortran function*/
int
functionODE_residual(double *t, double *x, double *xprime, double *delta, fortran_integer *ires, double *rpar, fortran_integer* ipar);

/* Function for calling external object constructors */
void
callExternalObjectConstructors(DATA*);

/*   function for calculating all equation sorting order 
  uses in EventHandle  */
int
functionDAE(int *needToIterate);

/* function for storing value histories of delayed expressions
 * called from functionDAE_output()
 */
int
function_storeDelayed();

/* function for calculating states on explicit ODE form */
/*used in functionDAE_res function*/
int functionODE_inline();

/* function for calculate initial values from initial equations and fixed start attibutes */
int initial_function();

/* function for calculating bound parameters that depend on other parameters, e.g. parameter Real n=1/m; */
int bound_parameters();

/* function for checking for asserts and terminate */
int checkForAsserts();

/* function for calculate residual values for the initial equations and fixed start attibutes */
int initial_residual(double);

/* function for initializing time instants when sample() is activated */
void function_sampleInit();
void function_initMemoryState();

/* function for calculation Jacobian */
extern int jac_flag;  /* Flag for DASSL to work with analytical Jacobian */
extern int num_jac_flag;  /* Flag for DASSL to work with selfmade numerical Jacobian */
int functionJacA(double* jac);
int functionJacB(double* jac);
int functionJacC(double* jac);
int functionJacD(double* jac);

int isInteractiveSimulation();

double newTime(double t, double step,double stop);

void setTermMsg(const char*);

#define MODELICA_ASSERT(info,msg) { terminationAssert = 1; setTermMsg(msg); TermInfo = info; }

#define MODELICA_TERMINATE(msg)  { modelTermination=1; terminationTerminate = 1; setTermMsg(msg); TermInfo.filename=""; TermInfo.lineStart=-1; TermInfo.colStart=-1; TermInfo.lineEnd=-1; TermInfo.colEnd=-1; TermInfo.readonly=-1; }

#define initial() localData->init
#define terminal() localData->terminal

/* _X_DATA *allocXData(void); */
/* void freeXData(_X_DATA *data); */

/* the main function of the simulation runtime!
 * simulation runtime no longer has main, is defined by the generated model code which calls this function.
 */
extern int _main_SimulationRuntime(int argc, char**argv, _X_DATA *data);
void communicateStatus(const char *phase, double completionPercent);

#ifdef __cplusplus
}
#endif

#endif
