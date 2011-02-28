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
#include "simulation_input.h"
#include "simulation_init.h"
#include "simulation_events.h"
#include "simulation_result.h"
#include "simulation_runtime.h"
#include "options.h"
#include <cmath>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <algorithm>
#include <cstdarg>
#include "rtclock.h"

using namespace std;

// Internal definitions; do not expose
int
euler_ex_step(double* step, int
    (*f)());
int
rungekutta_step(double* step, int
    (*f)());
int
dasrt_step(double* step, double &start, double &stop, bool &trigger);

#define MAXORD 5

//provides a dummy Jacobian to be used with DASSL
int
dummy_Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar)
{
  return 0;
}

//provides a analytical Jacobian to be used with DASSL
int
Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar)
{
  int size_A = globalData->nStates;
  double* matrixA = new double[size_A * size_A];
  //double* backupStates;
  //backupStates = globalData->states;

  //globalData->states = y;
  //functionODE_new();
  //functionAlgebraics();
  functionJacA(matrixA);

  int k = 0;
  int l;

  // transpose matrix A, add cj to diagonal elements and store in pd
  for (int i = 0; i < globalData->nStates; i++)
    {
      for (int j = 0; j < globalData->nStates; j++, k++)
        {
          l = i + j * globalData->nStates;
          pd[l] = matrixA[k];
          if (i == j)
            {
              pd[l] -= (double) *cj;
            }
        }
    }

  delete[] matrixA;

  return 0;
}


//provides a numerical Jacobian to be used with DASSL
int
JacA_num(double *t, double *y, double *matrixA)
{
  double delta_h = 1.e-8;
  double delta_hh;
  double* yprime = new double[globalData->nStates];
  double* yprime_delta_h = new double[globalData->nStates];

  memcpy(globalData->states,y,globalData->nStates*sizeof(double));
  functionODE_new();
  memcpy(yprime,globalData->statesDerivatives,globalData->nStates*sizeof(double));

  // matrix A, add cj to diagonal elements and store in pd
  int l;
  for (int i = 0; i < globalData->nStates; i++)
    {
      delta_hh = delta_h*(globalData->states[i]>0?globalData->states[i]:-globalData->states[i]);
      delta_hh = ((delta_h > delta_hh)?delta_h:delta_hh);
      globalData->states[i] += delta_hh;
      functionODE_new();
      memcpy(yprime_delta_h,globalData->statesDerivatives,globalData->nStates*sizeof(double));
      globalData->states[i] -= delta_hh;

      for (int j = 0; j < globalData->nStates; j++)
        {
          l = j + i * globalData->nStates;
          matrixA[l] = (yprime_delta_h[j] - yprime[j])/delta_hh;
        }
    }

  delete[] yprime;
  delete[] yprime_delta_h;

  return 0;
}

//provides a numerical Jacobian to be used with DASSL
int
Jacobian_num(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar)
{

  if (JacA_num(t, y, pd))
    {
      cerr << "Error, can not get Matrix A " << endl;
      return 1;
    }

  //  add cj to diagonal elements and store in pd
  for (int i = 0; i < globalData->nStates; i++)
    {
      for (int j = 0; j < globalData->nStates; j++)
        {
          if (i == j)
            {
              pd[i+j*globalData->nStates] -= (double) *cj;
            }
        }
    }

  return 0;
}

int
dummy_zeroCrossing(fortran_integer *neqm, double *t, double *y,
    fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar)
{
  return 0;
}
bool
continue_MINE(fortran_integer* idid, double* atol, double *rtol);

double
calcTinyStep(double start, double stop);

fortran_integer info[15];
double reltol = 1.0e-5;
double abstol = 1.0e-5;
fortran_integer idid = 0;
fortran_integer ipar = 0;

// work arrays for DASSL
fortran_integer liw;
fortran_integer lrw;
double *rwork;
fortran_integer *iwork;
fortran_integer NG_var = 0; //->see ddasrt.c LINE 250 (number of constraint functions)
fortran_integer *jroot;

// work array for inline implementation
double **work_states;

const int rungekutta_s = 4;
const double rungekutta_b[rungekutta_s] =
    { 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0 };
const double rungekutta_c[rungekutta_s] =
    { 0, 0.5, 0.5, 1 };

// Used when calculating residual for its side effects. (alg. var calc)
double *dummy_delta;

int euler_in_use;

int
solver_main_step(int flag, double &start, double &stop, bool &reset)
{
  switch (flag)
  {
  case 2:
    return rungekutta_step(&globalData->current_stepsize, functionODE_new);
  case 3:
    return dasrt_step(&globalData->current_stepsize, start, stop, reset);
  case 4:
    return functionODE_inline();
  case 1:
  default:
    return euler_ex_step(&globalData->current_stepsize, functionODE_new);
  }
}

/* The main function for a solver with synchronous event handling
 flag 1=explicit euler
 2=rungekutta
 3=dassl
 4=inline
 */
int
solver_main(int argc, char** argv, double &start, double &stop, double &step,
    long &outputSteps, double &tolerance, int flag)
{

  //Stats
  int stateEvents = 0;
  int sampleEvents = 0;

  //Workaround for Relation in simulation_events
  euler_in_use = 1;

  //Flags for event handling
  int dideventstep = 0;
  bool reset = false;

  double laststep = 0;
  double offset = 0;
  globalData->oldTime = start;
  globalData->timeValue = start;

  if (outputSteps > 0)
    { // Use outputSteps if set, otherwise use step size.
      step = (stop - start) / outputSteps;
    }
  else
    {
      if (step == 0)
        { // outputsteps not defined and zero step, use default 1e-3
          step = 1e-3;
        }
    }

  int sampleEvent_actived = 0;

  double uround = dlamch_((char*) "P", 1);

  const string *init_method = getFlagValue("im", argc, argv);

  int retValIntegrator;

  switch (flag)
  {
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

  if (initializeEventData())
    {
      cout << "Internal error, allocating event data structures" << endl;
      return -1;
    }

  if (bound_parameters())
    {
      printf("Error calculating bound parameters\n");
      return -1;
    }
  if (sim_verbose)
    {
      cout << "Calculated bound parameters" << endl;
    }

  // Calculate initial values from initial_function()
  // saveall() value as pre values
  if (measure_time_flag)
    rt_tick( SIM_TIMER_INIT);
  globalData->init = 1;
  initial_function();
  saveall();
  storeExtrapolationData();
  storeExtrapolationData();
  // Calculate initial values from (fixed) start attributes

  int needToIterate = 0;
  int IterationNum = 0;
  functionDAE(&needToIterate);
  functionAliasEquations();

  //work-around problem with discrete algorithm vars
  //
  //functionDAE(needToIterate);
  //functionAliasEquations();
  if (sim_verbose)
    {
      sim_result->emit();
    }
  while (checkForDiscreteChanges() || needToIterate)
    {
      saveall();
      functionDAE(&needToIterate);
      IterationNum++;
      if (IterationNum > IterationMax)
        {
          throw TerminateSimulationException(globalData->timeValue, string(
              "ERROR: Too many Iteration. System is not consistent!\n"));
        }
    }

  if (initialize(init_method))
    {
      throw TerminateSimulationException(globalData->timeValue, string(
          "Error in initialization. Storing results and exiting.\n"));
    }
  SaveZeroCrossings();
  saveall();
  if (sim_verbose)
    {
      sim_result->emit();
    }

  // Calculate stable discrete state
  // and initial ZeroCrossings
  if (globalData->curSampleTimeIx < globalData->nSampleTimes)
    {
      sampleEvent_actived = checkForSampleEvent();
      activateSampleEvents();
    }
  //Activate sample and evaluate again
  needToIterate = 0;
  IterationNum = 0;
  functionDAE(&needToIterate);
  if (sim_verbose)
    {
      sim_result->emit();
    }
  while (checkForDiscreteChanges() || needToIterate)
    {
      saveall();
      functionDAE(&needToIterate);
      IterationNum++;
      if (IterationNum > IterationMax)
        {
          throw TerminateSimulationException(globalData->timeValue, string(
              "ERROR: Too many Iteration. System is not consistent!\n"));
        }
    }
  functionAliasEquations();
  SaveZeroCrossings();
  if (sampleEvent_actived)
    {
      deactivateSampleEventsandEquations();
      sampleEvent_actived = 0;
    }

  saveall();
  sim_result->emit();

  // Initialization complete
  if (measure_time_flag)
    rt_accumulate( SIM_TIMER_INIT);
  globalData->init = 0;

  if (globalData->timeValue >= stop)
    {
      if (sim_verbose)
        {
          cout << "Simulation done!" << endl;
        }
      return 0;
    }

  /*
  // Do a tiny step to initialize ZeroCrossing that are fulfilled

  globalData->current_stepsize = calcTinyStep(start,stop);
  solver_main_step(flag, start, stop, reset);
  functionAlgebraics();


  //evaluate the system for events
  needToIterate = 0;
  IterationNum = 0;
  functionDAE(needToIterate);
  while (checkForDiscreteChanges() || needToIterate)
    {
      saveall();
      functionDAE(needToIterate);
      IterationNum++;
      if (IterationNum > IterationMax)
        {
          throw TerminateSimulationException(globalData->timeValue, string(
              "ERROR: Too many Iteration. System is not consistent!\n"));
        }
    }
  functionAliasEquations();
  // Put initial values to delayed expression buffers
  function_storeDelayed();
  SaveZeroCrossings();
  initializeZeroCrossings();
  reset = true;
  saveall();
  if (sim_verbose)
    {
      sim_result->emit();
    }
   */





  if (sim_verbose)
    {
      cout << "Performed initial value calculation." << endl;
      cout << "Start numerical solver from " << globalData->timeValue << " to "
          << stop << endl;
    }
  std::ofstream fmt;
  long stepNo = 0;
  if (measure_time_flag)
    {
      fmt.open("omc_mt.log");
      fmt << "step,time,solver time";
      for (int i = 0; i < globalData->nFunctions; i++)
        fmt << "," << globalData->functionNames[i].name << ",";
      for (int i = 0; i < globalData->nProfileBlocks; i++)
        fmt << ","
        << globalData->equationInfo[globalData->equationInfo_reverse_prof_index[i]].name
        << ",";
      fmt << endl;
    }

  try
  {
      while (globalData->timeValue < stop)
        {
          if (measure_time_flag)
            {
              for (int i = 0; i < globalData->nFunctions
              + globalData->nProfileBlocks; i++)
                rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
              rt_tick( SIM_TIMER_STEP);
            }

          /*
           * Calculate new step size after an event
           */
          if (dideventstep == 1)
            {
              offset = globalData->timeValue - laststep;
              dideventstep = 0;
              if (offset + 16 * uround > step)
                offset = 0;
            }
          else
            {
              offset = 0;
            }
          globalData->current_stepsize = step - offset;
          if (globalData->timeValue + globalData->current_stepsize > stop)
            {
              globalData->current_stepsize = stop - globalData->timeValue;
            }

          if (globalData->curSampleTimeIx < globalData->nSampleTimes)
            {
              sampleEvent_actived = checkForSampleEvent();
            }
          if (sim_verbose)
            {
              cout << "Call Solver from " << globalData->timeValue << " to "
                  << globalData->timeValue + globalData->current_stepsize
                  << endl;
            }
          /* do one integration step
           *
           * one step means:
           * determine all states by Integration-Method
           * update continuous part with
           * functionODE_new() and functionAlgebraics();
           */

          retValIntegrator = solver_main_step(flag, start, stop, reset);

          functionAlgebraics();
          functionAliasEquations();
          function_storeDelayed();
          SaveZeroCrossings();

          if (reset)
            reset = false;

          //Check for Events
          if (measure_time_flag)
            rt_tick( SIM_TIMER_EVENT);
          if (CheckForNewEvent(&sampleEvent_actived))
            {
              stateEvents++;
              reset = true;
              dideventstep = 1;
            }
          else if (sampleEvent_actived)
            {
              EventHandle(1);
              sampleEvents++;
              reset = true;
              dideventstep = 1;
              sampleEvent_actived = 0;
            }
          else
            {
              laststep = globalData->timeValue;
            }
          if (measure_time_flag)
            rt_accumulate( SIM_TIMER_EVENT);

          // Emit this time step
          saveall();
          if (measure_time_flag)
            {
              fmt << stepNo++ << "," << globalData->timeValue << ","
                  << rt_tock(SIM_TIMER_STEP);
              for (int i = 0; i < globalData->nFunctions; i++)
                fmt << "," << rt_ncall(i + SIM_TIMER_FIRST_FUNCTION) << ","
                << rt_total(i + SIM_TIMER_FIRST_FUNCTION);
              for (int i = globalData->nFunctions; i < globalData->nFunctions
              + globalData->nProfileBlocks; i++)
                fmt << "," << rt_ncall(i + SIM_TIMER_FIRST_FUNCTION) << ","
                << rt_total(i + SIM_TIMER_FIRST_FUNCTION);
              fmt << endl;
            }
          SaveZeroCrossings();
          sim_result->emit();

          //Check for termination of terminate() or assert()
          if (terminationAssert || terminationTerminate)
            {
              terminationAssert = 0;
              terminationTerminate = 0;
              checkForAsserts();
              checkTermination();
            }

          if (retValIntegrator)
            {
              throw TerminateSimulationException(globalData->timeValue, string(
                  "Error in Simulation. Solver exit with error.\n"));
            }
          if (sim_verbose)
            {
              cout << "** Step to " << globalData->timeValue << " Done!"
                  << endl;
            }

        }
  }
  catch (TerminateSimulationException &e)
  {
      cout << e.getMessage() << endl;
      if (modelTermination)
        { // terminated from assert, etc.
          cout << "Simulation terminated at time " << globalData->timeValue
              << endl;
          return -1;
        }
  }

  if (sim_verbose)
    {
      cout << "\t*** Statistics ***" << endl;
      cout << "Events: " << stateEvents + sampleEvents << endl;
      cout << "State Events: " << stateEvents << endl;
      cout << "Sample Events: " << sampleEvents << endl;
    }

  deinitializeEventData();

  return 0;
}

int
euler_ex_step(double* step, int
    (*f)())
{
  globalData->timeValue += *step;
  for (int i = 0; i < globalData->nStates; i++)
    {
      globalData->states[i] = globalData->states[i]
                                                 + globalData->statesDerivatives[i] * (*step);
    }
  f();
  return 0;
}

int
rungekutta_step(double* step, int
    (*f)())
{
  double* backupstates = work_states[rungekutta_s];
  double** k = work_states;

  /* We calculate k[0] before returning from this function.
   * We only want to calculate f() 4 times per call */
  for (int i = 0; i < globalData->nStates; i++)
    {
      k[0][i] = globalData->statesDerivatives[i];
      backupstates[i] = globalData->states[i];
    }

  for (int j = 1; j < rungekutta_s; j++)
    {
      globalData->timeValue = globalData->oldTime + rungekutta_c[j] * (*step);
      for (int i = 0; i < globalData->nStates; i++)
        {
          globalData->states[i] = backupstates[i] + (*step) * rungekutta_c[j]
                                                                           * k[j - 1][i];
        }
      f();
      for (int i = 0; i < globalData->nStates; i++)
        {
          k[j][i] = globalData->statesDerivatives[i];
        }
    }

  for (int i = 0; i < globalData->nStates; i++)
    {
      double sum = 0;
      for (int j = 0; j < rungekutta_s; j++)
        {
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
int
dasrt_step(double* step, double &start, double &stop, bool &trigger1)
{
  double tout;
  int i;
  extern fortran_integer info[15];
  extern double reltol;
  extern double abstol;
  extern fortran_integer idid;
  extern fortran_integer ipar;
  extern fortran_integer liw;
  extern fortran_integer lrw;
  extern double *rwork;
  extern fortran_integer *iwork;
  double *rpar;
  extern fortran_integer NG_var; //->see ddasrt.c LINE 250 (number of constraint functions)
  extern fortran_integer *jroot;
  extern double *dummy_delta;

  if (globalData->timeValue == start)
    {
      if (sim_verbose)
        {
          cout << "**Calling DDASRT the first time..." << endl;
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
  if (trigger1)
    {
      if (sim_verbose)
        {
          cout << "Event-management forced reset of DDASRT... " << endl;
        }
      // obtain reset
      info[0] = 0;
    }

  // Calculate time steps until TOUT is reached (DASSL calculates beyond TOUT unless info[6] is set to 1!)
  try
  {
      do
        {

          tout = globalData->timeValue + *step;
          // Check that tout is not less than timeValue
          // else will dassl get in trouble
          if (globalData->timeValue - tout >= -1e-13)
            {
              if (sim_verbose)
                {
                  cout << "**Desired step to small try next one. " << endl;
                }
              globalData->timeValue = tout;
              return 0;
            }

          if (sim_verbose)
            {
              cout << "**Calling DDASRT from " << globalData->timeValue
                  << " to " << tout << "..." << endl;
            }

          // Save all statesDerivatives due to avoid this in functionODE_residual
          memcpy(globalData->statesDerivativesBackup,globalData->statesDerivatives,globalData->nStates*sizeof(double));

          if (jac_flag)
            {
              DDASRT(functionODE_residual, &globalData->nStates,
                  &globalData->timeValue, globalData->states,
                  globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
                  &idid, rwork, &lrw, iwork, &liw, globalData->algebraics,
                  &ipar, Jacobian, dummy_zeroCrossing, &NG_var, jroot);
            }
          else if(num_jac_flag)
            {
              DDASRT(functionODE_residual, &globalData->nStates,
                  &globalData->timeValue, globalData->states,
                  globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
                  &idid, rwork, &lrw, iwork, &liw, globalData->algebraics,
                  &ipar, Jacobian_num, dummy_zeroCrossing, &NG_var, jroot);
            }
          else
            {
              DDASRT(functionODE_residual, &globalData->nStates,
                  &globalData->timeValue, globalData->states,
                  globalData->statesDerivativesBackup, &tout, info, &reltol, &abstol,
                  &idid, rwork, &lrw, iwork, &liw, globalData->algebraics,
                  &ipar, dummy_Jacobian, dummy_zeroCrossing, &NG_var, jroot);
            }


          if (sim_verbose){
              cout << " value of idid: " << idid << endl;
              cout << " step size H to be attempted on next step: " << rwork[2] << endl;
              cout << " current value of independent variable: " << rwork[3] << endl;
              cout << " stepsize used on last successful step : " << rwork[6] << endl;
              cout << " number of steps taken so far: " << iwork[10] << endl << endl;
              cout << " actual time point outputed: " << tout << endl<< endl;
          }

          if (idid < 0)
            {
              fflush( stderr);
              fflush( stdout);
              if (idid == -1)
                {
                  if (sim_verbose)
                    {
                      cout << "DDASRT will try again..." << endl;
                    }
                  info[0] = 1; // try again
                }
              if (!continue_MINE(&idid, &abstol, &reltol))
                throw TerminateSimulationException(globalData->timeValue);
            }

          functionODE_new();
        }
      while (idid == -1 && globalData->timeValue <= stop);
  }
  catch (TerminateSimulationException &e)
  {
      cout << e.getMessage() << endl;
      //free DASSL specific work arrays.
      return 1;

  }

  if (tout > stop)
    {
      if (sim_verbose)
        {
          cout << "**Deleting work arrays after last DDASRT call..." << endl;
        }
    }
  return 0;
}

bool
continue_MINE(fortran_integer* idid, double* atol, double *rtol)
{
  static int atolZeroIterations = 0;
  bool retValue = true;
  switch (*idid)
  {
  case 1:
  case 2:
  case 3:
  case 4:
    /* 1-4 means success */
    break;
  case -1:
    std::cerr
    << "DDASRT: A large amount of work has been expended.(About 500 steps). Trying to continue ..."
    << std::endl;
    retValue = true; /* adrpo: try to continue */
    break;
  case -2:
    std::cerr << "DDASRT: The error tolerances are too stringent." << std::endl;
    retValue = false;
    break;
  case -3:
    if (atolZeroIterations > 10)
      {
        std::cerr
        << "DDASRT: The local error test cannot be satisfied because you specified a zero component in ATOL and the corresponding computed solution component is zero. Thus, a pure relative error test is impossible for this component."
        << std::endl;
        retValue = false;
        atolZeroIterations++;
      }
    else
      {
        *atol = 1e-6;
        retValue = true;
      }
    break;
  case -6:
    std::cerr
    << "DDASRT: DDASSL had repeated error test failures on the last attempted step."
    << std::endl;
    retValue = false;
    break;
  case -7:
    std::cerr << "DDASRT: The corrector could not converge." << std::endl;
    retValue = false;
    break;
  case -8:
    std::cerr << "DDASRT: The matrix of partial derivatives is singular."
    << std::endl;
    retValue = false;
    break;
  case -9:
    std::cerr
    << "DDASRT: The corrector could not converge. There were repeated error test failures in this step."
    << std::endl;
    retValue = false;
    break;
  case -10:
    std::cerr
    << "DDASRT: The corrector could not converge because IRES was equal to minus one."
    << std::endl;
    retValue = false;
    break;
  case -11:
    std::cerr
    << "DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program."
    << std::endl;
    retValue = false;
    break;
  case -12:
    std::cerr << "DDASRT: DDASSL failed to compute the initial YPRIME."
    << std::endl;
    retValue = false;
    break;
  case -33:
    std::cerr
    << "DDASRT: The code has encountered trouble from which it cannot recover. "
    << std::endl;
    retValue = false;
    break;
  }
  return retValue;
}

