/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
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
 * from Linköping University, either from the above address,
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

#include "solver_main.h"
#include "simulation_input_xml.h"
#include "simulation_init.h"
#include "simulation_events.h"
#include "simulation_result.h"
#include "simulation_runtime.h"
#include "options.h"
#include <cmath>
#include <string.h>
#include <iostream>
#include <iomanip>
#include <algorithm>
#include <cstdarg>
#include <cfloat>
#include <stdint.h>
#include <errno.h>
#include "rtclock.h"
#include <assert.h>

using namespace std;

// Internal definitions; do not expose
int euler_ex_step(double* step, int(*f)());
int rungekutta_step(double* step, int(*f)());
int dasrt_step(double* step, double &start, double &stop, bool &trigger,
    int* stats);

#define MAXORD 5
#define DASSLSTATS 5

//provides a dummy Jacobian to be used with DASSL
int dummy_Jacobian(double *t, double *y, double *yprime, double *pd,
    double *cj, double *rpar, fortran_integer* ipar) {
  return 0;
}

//provides a analytical Jacobian to be used with DASSL
int Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar) {
  int size_A = globalData->nStates;
  double* matrixA = new double[size_A * size_A];
  double* backupStates;
  double backupTime;
  backupStates = globalData->states;
  backupTime = globalData->timeValue;

  globalData->states = y;
  globalData->timeValue = *t;
  functionODE();
  functionJacA(pd);

  /* add cj to the diagonal elements of the matrix */
  for (int i = 0; i < globalData->nStates; i++) {
    pd[i + i * globalData->nStates] -= (double) *cj;
  }
  globalData->states = backupStates;
  globalData->timeValue = backupTime;
  delete[] matrixA;

  return 0;
}

//provides a numerical Jacobian to be used with DASSL
int JacA_num(double *t, double *y, double *matrixA) {
  double delta_h = 1.e-10;
  double delta_hh;
  double* yprime = new double[globalData->nStates];
  double* yprime_delta_h = new double[globalData->nStates];

  double* backupStates;
  double backupTime;
  backupStates = globalData->states;
  backupTime = globalData->timeValue;

  globalData->states = y;
  globalData->timeValue = *t;

  functionODE();
  memcpy(yprime, globalData->statesDerivatives,
      globalData->nStates * sizeof(double));

  // matrix A, add cj to diagonal elements and store in pd
  int l;
  for (int i = 0; i < globalData->nStates; i++) {
    delta_hh = delta_h * (globalData->states[i] > 0 ? globalData->states[i]
                                                                         : -globalData->states[i]);
    delta_hh = ((delta_h > delta_hh) ? delta_h : delta_hh);
    globalData->states[i] += delta_hh;
    functionODE();
    globalData->states[i] -= delta_hh;

    for (int j = 0; j < globalData->nStates; j++) {
      l = j + i * globalData->nStates;
      matrixA[l] = (globalData->statesDerivatives[j] - yprime[j]) / delta_hh;
    }
  }

  globalData->states = backupStates;
  globalData->timeValue = backupTime;
  delete[] yprime;
  delete[] yprime_delta_h;

  return 0;
}

//provides a numerical Jacobian to be used with DASSL
int Jacobian_num(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar) {

  if (JacA_num(t, y, pd)) {
    cerr << "Error, can not get Matrix A " << endl;
    return 1;
  }

  //  add cj to diagonal elements and store in pd
  for (int i = 0; i < globalData->nStates; i++) {
    for (int j = 0; j < globalData->nStates; j++) {
      if (i == j) {
        pd[i + j * globalData->nStates] -= (double) *cj;
      }
    }
  }

  return 0;
}

int dummy_zeroCrossing(fortran_integer *neqm, double *t, double *y,
    fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar) {
  return 0;
}
bool
continue_MINE(fortran_integer* idid, double* atol, double *rtol);

double
calcTinyStep(double start, double stop);

fortran_integer info[15] = { 0 };
double reltol = 1.0e-5;
double abstol = 1.0e-5;
fortran_integer idid = 0;
fortran_integer* ipar = 0;

// work arrays for DASSL
fortran_integer liw = 0;
fortran_integer lrw = 0;
double *rwork = NULL;
fortran_integer *iwork = 0;
fortran_integer NG_var = 0; //->see ddasrt.c LINE 250 (number of constraint functions)
fortran_integer *jroot = NULL;

// work array for inline implementation
double **work_states = NULL;

const int rungekutta_s = 4;
const double rungekutta_b[rungekutta_s] = { 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0,
    1.0 / 6.0 };
const double rungekutta_c[rungekutta_s] = { 0, 0.5, 0.5, 1 };

// Used when calculating residual for its side effects. (alg. var calc)
double *dummy_delta = NULL;

int solver_main_step(int flag, double &start, double &stop, bool &reset,
    int* stats) {
  switch (flag) {
  case 2:
    return rungekutta_step(&globalData->current_stepsize, functionODE);
  case 3:
    return dasrt_step(&globalData->current_stepsize, start, stop, reset, stats);
  case 4:
    return functionODE_inline();
  case 1:
  default:
    return euler_ex_step(&globalData->current_stepsize, functionODE);
  }
}

/* function: update_DAEsystem
 *
 * function to update the whole system with EventIteration.
 * Evaluate the functionDAE()
 */
void update_DAEsystem() {
  int needToIterate = 0;
  int IterationNum = 0;

  functionDAE(&needToIterate);
  while (checkForDiscreteChanges() || needToIterate) {
    if (needToIterate) {
      if (sim_verbose >= LOG_EVENTS)
        fprintf(stdout, "| info LOG_EVENTS | reinit call. Iteration needed!\n");
    } else {
      if (sim_verbose >= LOG_EVENTS)
        fprintf(stdout,
            "| info LOG_EVENTS | discrete Var changed. Iteration needed!\n");
    }
    saveall();
    functionDAE(&needToIterate);
    IterationNum++;
    if (IterationNum > IterationMax) {
      throw TerminateSimulationException(globalData->timeValue,
          string("ERROR: Too many Iteration. System is not consistent!\n"));
    }
  }
}

/* The main function for a solver with synchronous event handling
 flag 1=explicit euler
 2=rungekutta
 3=dassl
 4=inline
 */
int solver_main(int argc, char** argv, double &start, double &stop,
    double &step, long &outputSteps, double &tolerance, int flag) {

  // Set tolerance for DASSL integration
  reltol = tolerance;
  abstol = tolerance;

  // Setup some variables for statistics
  int stateEvents = 0;
  int sampleEvents = 0;

  int dasslStats[DASSLSTATS];
  int dasslStatsTmp[DASSLSTATS];
  for (int i = 0; i < DASSLSTATS; i++) {
    dasslStats[i] = 0;
    dasslStatsTmp[i] = 0;
  }

  //Flags for event handling
  int dideventstep = 0;
  bool reset = false;

  double laststep = 0;
  double offset = 0;
  globalData->terminal = 0;
  globalData->oldTime = start;
  globalData->timeValue = start;

  if (outputSteps > 0) { // Use outputSteps if set, otherwise use step size.
    step = (stop - start) / outputSteps;
  } else {
    if (step == 0) { // outputsteps not defined and zero step, use default 1e-3
      step = 1e-3;
    }
  }

  int sampleEvent_actived = 0;

  double uround = dlamch_((char*) "P", 1);

  const std::string* init_method = getFlagValue("im", argc, argv); /* get the old initialization-flag */
  const std::string* init_initMethod = getFlagValue("iim", argc, argv); /* get the initialization method */
  const std::string* init_optiMethod = getFlagValue("iom", argc, argv); /* get the optimization method for the initialization */

  if (init_method) {
    fprintf(stdout,
        "Error: old flag:      initialization-method [im] is rejected\n");
    fprintf(
        stdout,
        "       new flag: init-initialization-method [iim] current options are: state or old\n");
    fprintf(
        stdout,
        "       new flag:   init-optimization-method [iom] current options are: simplex or newuoa\n");
    return -1;
  }

  int retValIntegrator = 0;

  switch (flag) {
  // Allocate RK work arrays
  case 2:
    work_states = (double**) malloc((rungekutta_s + 1) * sizeof(double*));
    for (int i = 0; i < rungekutta_s + 1; i++)
      work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
    break;
    // Enable inlining solvers
  case 4:
    work_states = (double**) malloc(inline_work_states_ndims * sizeof(double*));
    for (int i = 0; i < inline_work_states_ndims; i++)
      work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
    break;
  }

  if (initializeEventData()) {
    fprintf(stdout, "Internal error, allocating event data structures\n");
    return -1;
  }

  if (bound_parameters()) {
    fprintf(stdout, "Error calculating bound parameters\n");
    return -1;
  }
  if (sim_verbose >= LOG_SOLVER) {
    fprintf(stdout, "| info LOG_SOLVER | Calculated bound parameters\n");
  }
  // Evaluate all constant equations during initialization
  globalData->init = 1;
  functionAliasEquations();

  // Calculate initial values from initial_function()
  // saveall() value as pre values
  if (measure_time_flag) {
    rt_accumulate( SIM_TIMER_PREINIT);
    rt_tick( SIM_TIMER_INIT);
  }
  try {
    if (initialization(init_initMethod ? init_initMethod->c_str() : NULL,
        init_optiMethod ? init_optiMethod->c_str() : NULL)) {
      throw TerminateSimulationException(globalData->timeValue,
          string("Error in initialization. Storing results and exiting.\n"));
    }

    SaveZeroCrossings();
    saveall();
    if (sim_verbose >= LOG_SOLVER) {
      if (sim_result)
        sim_result->emit();
    }

    //Activate sample and evaluate again
    if (globalData->curSampleTimeIx < globalData->nSampleTimes) {
      sampleEvent_actived = checkForSampleEvent();
      activateSampleEvents();
    }
    update_DAEsystem();
    if (sampleEvent_actived) {
      deactivateSampleEventsandEquations();
      sampleEvent_actived = 0;
    }
    int tmp = 0;
    saveall();
    CheckForNewEvent(&tmp);
    SaveZeroCrossings();
    saveall();
    if (sim_result)
      sim_result->emit();
    storeExtrapolationDataEvent();
  } catch (TerminateSimulationException &e) {
    cout << e.getMessage() << endl;
    printf(
        "Simulation terminated while the initialization. Could not find suitable initial values.\n");
    return -1;
  }

  // Initialization complete
  if (measure_time_flag)
    rt_accumulate( SIM_TIMER_INIT);

  if (globalData->timeValue >= stop) {
    if (sim_verbose >= LOG_SOLVER) {
      fprintf(stdout, "| info LOG_SOLVER | Simulation done!\n");
    }
    globalData->terminal = 1;
    update_DAEsystem();
    if (sim_result)
      sim_result->emit();
    globalData->terminal = 0;
    return 0;
  }

  if (sim_verbose >= LOG_SOLVER) {
    fprintf(stdout,
        "| info LOG_SOLVER | Performed initial value calculation.\n");
    fprintf(stdout,
        "| info LOG_SOLVER | Start numerical solver from %f to %f\n",
        globalData->timeValue, stop);
  }
  FILE *fmt = NULL;
  uint32_t stepNo = 0;
  if (measure_time_flag) {
    const string filename = string(globalData->modelFilePrefix) + "_prof.data";
    fmt = fopen(filename.c_str(), "wb");
    if (!fmt) {
      fprintf(
          stderr,
          "Warning: Time measurements output file %s could not be opened: %s\n",
          filename.c_str(), strerror(errno));
      fclose(fmt);
      fmt = NULL;
    }
  }

  try {
    while (globalData->timeValue < stop) {
      if (measure_time_flag) {
        for (int i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++)
          rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
        rt_clear( SIM_TIMER_STEP);
        rt_tick(SIM_TIMER_STEP);
      }

      /*
       * Calculate new step size after an event
       */
      if (dideventstep == 1) {
        offset = globalData->timeValue - laststep;
        dideventstep = 0;
        if (offset + uround > step)
          offset = 0;
        if (sim_verbose >= LOG_SOLVER)
          fprintf(stdout,
              "| info LOG_SOLVER | Offset value for the next step: %g\n",
              offset);
      } else {
        offset = 0;
      }
      globalData->current_stepsize = step - offset;
      if (globalData->timeValue + globalData->current_stepsize > stop) {
        globalData->current_stepsize = stop - globalData->timeValue;
      }

      if (globalData->curSampleTimeIx < globalData->nSampleTimes) {
        sampleEvent_actived = checkForSampleEvent();
      }
      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout, "| info LOG_SOLVER | Call Solver from %f to %f\n",
            globalData->timeValue,
            globalData->timeValue + globalData->current_stepsize);
      }
      /* do one integration step
       *
       * one step means:
       * determine all states by Integration-Method
       * update continuous part with
       * functionODE() and functionAlgebraics();
       */

      retValIntegrator = solver_main_step(flag, start, stop, reset,
          dasslStatsTmp);

      functionAlgebraics();
      functionAliasEquations();
      function_storeDelayed();
      SaveZeroCrossings();

      if (reset)
        reset = false;

      //Check for Events
      if (measure_time_flag)
        rt_tick( SIM_TIMER_EVENT);
      if (CheckForNewEvent(&sampleEvent_actived)) {
        stateEvents++;
        reset = true;
        dideventstep = 1;

        //due to an event overwrite old values
        storeExtrapolationDataEvent();
      } else if (sampleEvent_actived) {
        EventHandle(1);
        sampleEvents++;
        reset = true;
        dideventstep = 1;
        sampleEvent_actived = 0;
        //due to an event overwrite old values
        storeExtrapolationDataEvent();
      } else {
        laststep = globalData->timeValue;
      }
      if (measure_time_flag)
        rt_accumulate( SIM_TIMER_EVENT);

      // Emit this time step
      saveall();
      if (fmt) {
        int flag = 1;
        double tmpdbl;
        uint32_t tmpint;
        rt_tick( SIM_TIMER_OVERHEAD);
        rt_accumulate( SIM_TIMER_STEP);
        /* Disable time measurements if we have trouble writing to the file... */
        flag = flag && 1 == fwrite(&stepNo, sizeof(uint32_t), 1, fmt);
        stepNo++;
        flag = flag && 1 == fwrite(&globalData->timeValue, sizeof(double), 1,
            fmt);
        tmpdbl = rt_accumulated(SIM_TIMER_STEP);
        flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
        for (int i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++) {
          tmpint = rt_ncall(i + SIM_TIMER_FIRST_FUNCTION);
          flag = flag && 1 == fwrite(&tmpint, sizeof(uint32_t), 1, fmt);
        }
        for (int i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++) {
          tmpdbl = rt_accumulated(i + SIM_TIMER_FIRST_FUNCTION);
          flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
        }
        rt_accumulate(SIM_TIMER_OVERHEAD);
        if (!flag) {
          fprintf(
              stderr,
              "Warning: Disabled time measurements because the output file could not be generated: %s\n",
              strerror(errno));
          fclose(fmt);
          fmt = NULL;
        }
      }
      SaveZeroCrossings();
      if (sim_result)
        sim_result->emit();

      if (reset == true) {
        // save dassl stats befor reset
        for (int i = 0; i < DASSLSTATS; i++)
          dasslStats[i] += dasslStatsTmp[i];
      }
      //Check for termination of terminate() or assert()
      if (terminationAssert || terminationTerminate || modelErrorCode) {
        terminationAssert = 0;
        terminationTerminate = 0;
        checkForAsserts();
        checkTermination();
        if (modelErrorCode)
          retValIntegrator = 1;
      }

      if (retValIntegrator) {
        throw TerminateSimulationException(globalData->timeValue,
            string("Error in Simulation. Solver exit with error.\n"));
      }
      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout, "| info LOG_SOLVER |** Step to  %f Done!\n",
            globalData->timeValue);
      }

    }
    // Last step with terminal()=true
    if (globalData->timeValue >= stop) {
      globalData->terminal = 1;
      update_DAEsystem();
      if (sim_result)
        sim_result->emit();
      globalData->terminal = 0;
    }

  } catch (TerminateSimulationException &e) {
    globalData->terminal = 1;
    update_DAEsystem();
    globalData->terminal = 0;
    cout << e.getMessage() << endl;
    if (modelTermination) { // terminated from assert, etc.
      fprintf(stdout, "| model terminate | Simulation terminated at time %f\n",
          globalData->timeValue);
      if (fmt)
        fclose(fmt);
      return -1;
    }
  }

  if (sim_verbose >= LOG_STATS) {
    // save dassl stats befor print
    for (int i = 0; i < DASSLSTATS; i++)
      dasslStats[i] += dasslStatsTmp[i];

    rt_accumulate( SIM_TIMER_TOTAL);
    fprintf(stdout, "| info LOG_STATS| ##### Statistics #####\n");
    fprintf(stdout, "| info LOG_STATS| Simulationtime : %f\n",
        rt_accumulated(SIM_TIMER_TOTAL));
    fprintf(stdout, "| info LOG_STATS| Events: %d\n",
        stateEvents + sampleEvents);
    fprintf(stdout, "| info LOG_STATS| State Events: %d\n", stateEvents);
    fprintf(stdout, "| info LOG_STATS| Sample Events: %d\n", sampleEvents);
    fprintf(stdout, "| info LOG_STATS| ##### Solver Statistics #####\n");
    fprintf(stdout, "| info LOG_STATS| The number of steps taken: %d\n",
        dasslStats[0]);
    fprintf(stdout,
        "| info LOG_STATS| The number of calls to functionODE: %d\n",
        dasslStats[1]);
    fprintf(stdout, "| info LOG_STATS| The evaluations of Jacobian: %d\n",
        dasslStats[2]);
    fprintf(stdout,
        "| info LOG_STATS| The number of error test failures: %d\n",
        dasslStats[3]);
    fprintf(stdout,
        "| info LOG_STATS| The number of convergence test failures: %d\n",
        dasslStats[4]);
  }

  deinitializeEventData();
  if (fmt)
    fclose(fmt);

  return 0;
}

int euler_ex_step(double* step, int(*f)()) {
  globalData->timeValue += *step;
  for (int i = 0; i < globalData->nStates; i++) {
    globalData->states[i] += globalData->statesDerivatives[i] * (*step);
  }
  f();
  return 0;
}

int rungekutta_step(double* step, int(*f)()) {
  double* backupstates = work_states[rungekutta_s];
  double** k = work_states;

  /* We calculate k[0] before returning from this function.
   * We only want to calculate f() 4 times per call */
  for (int i = 0; i < globalData->nStates; i++) {
    k[0][i] = globalData->statesDerivatives[i];
    backupstates[i] = globalData->states[i];
  }

  for (int j = 1; j < rungekutta_s; j++) {
    globalData->timeValue = globalData->oldTime + rungekutta_c[j] * (*step);
    for (int i = 0; i < globalData->nStates; i++) {
      globalData->states[i] = backupstates[i] + (*step) * rungekutta_c[j] * k[j
                                                                              - 1][i];
    }
    f();
    for (int i = 0; i < globalData->nStates; i++) {
      k[j][i] = globalData->statesDerivatives[i];
    }
  }

  for (int i = 0; i < globalData->nStates; i++) {
    double sum = 0;
    for (int j = 0; j < rungekutta_s; j++) {
      sum = sum + rungekutta_b[j] * k[j][i];
    }
    globalData->states[i] = backupstates[i] + (*step) * sum;
  }
  f();
  return 0;
}

/*
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL perform a warm-start
 */
int dasrt_step(double* step, double &start, double &stop, bool &trigger1,
    int* tmpStats) {
  double tout = 0;
  int i = 0;
  double *rpar = NULL;
  // extern variables??
  extern fortran_integer info[15];
  extern double reltol;
  extern double abstol;
  extern fortran_integer idid;
  extern fortran_integer* ipar;
  extern fortran_integer liw;
  extern fortran_integer lrw;
  extern double *rwork;
  extern fortran_integer *iwork;
  extern fortran_integer NG_var; //->see ddasrt.c LINE 250 (number of constraint functions)
  extern fortran_integer *jroot;
  extern double *dummy_delta;
  // end extern
  if (globalData->timeValue == start) {
    if (sim_verbose >= LOG_SOLVER) {
      fprintf(stdout, "| info LOG_SOLVER | **Initial DDASSL.\n");
    }
    // work arrays for DASSL
    liw = 20 + globalData->nStates;
    lrw = 52 + (MAXORD + 4) * globalData->nStates + globalData->nStates
        * globalData->nStates + 3 * globalData->nZeroCrossing;
    rwork = new double[lrw];
    iwork = new fortran_integer[liw];
    jroot = new fortran_integer[globalData->nZeroCrossing];
    // Used when calculating residual for its side effects. (alg. var calc)
    dummy_delta = new double[globalData->nStates];
    rpar = new double;
    ipar = new fortran_integer[3];
    ipar[0] = sim_verbose;
    ipar[1] = LOG_JAC;
    ipar[2] = LOG_ENDJAC;

    for (i = 0; i < 15; i++)
      info[i] = 0;
    for (i = 0; i < liw; i++)
      iwork[i] = 0;
    for (i = 0; i < lrw; i++)
      rwork[i] = 0.0;
    /*********************************************************************/
    //info[2] = 1;  //intermediate-output mode
    /*********************************************************************/
    //info[3] = 1;  //go not past TSTOP
    //rwork[0] = stop;  //TSTOP
    /*********************************************************************/
    //info[6] = 1;  //prohibit code to decide max. stepsize on its own
    //rwork[1] = *step;  //define max. stepsize
    /*********************************************************************/
    /*********************************************************************/

    if (jac_flag || num_jac_flag)
      info[4] = 1; //use sub-routine JAC
  }

  // If an event is triggered and processed restart dassl.
  if (trigger1) {
    if (sim_verbose >= LOG_EVENTS) {
      fprintf(stdout,
          "| info LOG_EVENTS | Event-management forced reset of DDASRT.\n");
    }
    // obtain reset
    info[0] = 0;
  }

  // Calculate time steps until TOUT is reached (DASSL calculates beyond TOUT
  // unless info[6] is set to 1!)
  try {
    do {

      tout = globalData->timeValue + *step;
      // Check that tout is not less than timeValue
      // else will dassl get in trouble. If that is the case we skip the current step.
      if (globalData->timeValue - tout >= -1e-13) {
        if (sim_verbose >= LOG_SOLVER) {
          fprintf(stdout,
              "| info LOG_SOLVER | **Desired step to small try next one.\n");
        }
        globalData->timeValue = tout;
        return 0;
      }

      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout,
            "| info LOG_SOLVER | **Calling DDASRT from %f to %f .\n",
            globalData->timeValue, tout);
      }

      // Save all statesDerivatives due to avoid this in functionODE_residual
      memcpy(globalData->statesDerivativesBackup,
          globalData->statesDerivatives, globalData->nStates * sizeof(double));

      if (jac_flag) {
        DDASRT(functionODE_residual, &globalData->nStates,
            &globalData->timeValue, globalData->states,
            globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
            &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
            Jacobian, dummy_zeroCrossing, &NG_var, jroot);
      } else if (num_jac_flag) {
        DDASRT(functionODE_residual, &globalData->nStates,
            &globalData->timeValue, globalData->states,
            globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
            &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
            Jacobian_num, dummy_zeroCrossing, &NG_var, jroot);
      } else {
        DDASRT(functionODE_residual, &globalData->nStates,
            &globalData->timeValue, globalData->states,
            globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
            &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
            dummy_Jacobian, dummy_zeroCrossing, &NG_var, jroot);
      }

      if (sim_verbose >= LOG_SOLVER) {
        fprintf(stdout, "| info LOG_SOLVER | value of idid: %i\n", idid);
        fprintf(stdout, "| info LOG_SOLVER | current time value: %0.4g\n",
            globalData->timeValue);
        fprintf(stdout,
            "| info LOG_SOLVER | current integration time value: %0.4g\n",
            rwork[3]);
        fprintf(
            stdout,
            "| info LOG_SOLVER | step size H to be attempted on next step: %0.4g\n",
            rwork[2]);
        fprintf(
            stdout,
            "| info LOG_SOLVER | stepsize used on last successful step: %0.4g\n",
            rwork[6]);
        fprintf(stdout,
            "| info LOG_SOLVER | number of steps taken so far: %i\n", iwork[10]);
        fprintf(stdout,
            "| info LOG_SOLVER | number of calls of functionODE() : %i\n",
            iwork[11]);
        fprintf(stdout,
            "| info LOG_SOLVER | number of calculation of Jacobian : %i\n",
            iwork[12]);
        fprintf(
            stdout,
            "| info LOG_SOLVER | total number of convergence test failures: %i\n",
            iwork[13]);
        fprintf(stdout,
            "| info LOG_SOLVER | total number of error test failures: %i\n",
            iwork[14]);
      }

      // save dassl stats
      for (i = 0; i < DASSLSTATS; i++) {
        assert(10 + i < liw);
        tmpStats[i] = iwork[10 + i];
      }

      if (idid < 0) {
        fflush( stderr);
        fflush( stdout);
        if (idid == -1) {
          if (sim_verbose >= LOG_SOLVER) {
            fprintf(stdout, "| info LOG_SOLVER | DDASRT will try again...\n");
          }
          info[0] = 1; // try again
        }
        if (!continue_MINE(&idid, &abstol, &reltol))
          throw TerminateSimulationException(globalData->timeValue);
      }

      functionODE();
    } while (idid == -1 && globalData->timeValue <= stop);
  } catch (TerminateSimulationException &e) {

    cout << e.getMessage() << endl;
    //free DASSL specific work arrays.
    return 1;

  }

  if (tout > stop) {
    if (sim_verbose >= LOG_SOLVER) {
      fprintf(stdout, "| info LOG_SOLVER | DDASRT finished.\n");
    }

  }
  return 0;
}

bool continue_MINE(fortran_integer* idid, double* atol, double *rtol) {
  static int atolZeroIterations = 0;
  bool retValue = true;
  switch (*idid) {
  case 1:
  case 2:
  case 3:
  case 4:
    /* 1-4 means success */
    break;
  case -1:
    fprintf(
        stderr,
        "| warning | DDASRT: A large amount of work has been expended.(About 500 steps). Trying to continue ...\n");
    retValue = true; /* adrpo: try to continue */
    break;
  case -2:
    fprintf(stderr,
        "| error | DDASRT: The error tolerances are too stringent.\n");
    retValue = false;
    break;
  case -3:
    if (atolZeroIterations > 10) {
      fprintf(
          stderr,
          "| error | DDASRT: The local error test cannot be satisfied because you specified a zero component in ATOL and the corresponding computed solution component is zero. Thus, a pure relative error test is impossible for this component.\n");
      retValue = false;
      atolZeroIterations++;
    } else {
      *atol = 1e-6;
      retValue = true;
    }
    break;
  case -6:
    fprintf(
        stderr,
        "| error | DDASRT: DDASSL had repeated error test failures on the last attempted step.\n");
    retValue = false;
    break;
  case -7:
    fprintf(stderr, "| error | DDASRT: The corrector could not converge.\n");
    retValue = false;
    break;
  case -8:
    fprintf(stderr,
        "| error | DDASRT: The matrix of partial derivatives is singular.\n");
    retValue = false;
    break;
  case -9:
    fprintf(
        stderr,
        "| error | DDASRT: The corrector could not converge. There were repeated error test failures in this step.\n");
    retValue = false;
    break;
  case -10:
    fprintf(
        stderr,
        "| error | DDASRT: The corrector could not converge because IRES was equal to minus one.\n");
    retValue = false;
    break;
  case -11:
    fprintf(
        stderr,
        "| error | DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program.\n");
    retValue = false;
    break;
  case -12:
    fprintf(stderr,
        "| error | DDASRT: DDASSL failed to compute the initial YPRIME.\n");
    retValue = false;
    break;
  case -33:
    fprintf(
        stderr,
        "| error | DDASRT: The code has encountered trouble from which it cannot recover.\n");
    retValue = false;
    break;
  }
  return retValue;
}

