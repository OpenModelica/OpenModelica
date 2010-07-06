/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2010, Link�pings University,
* Department of Computer and Information Science,
* SE-58183 Link�ping, Sweden.
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
* from Link�pings University, either from the above address,
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

#include "solver_dasrt.h"
#include "simulation_input.h"
#include "simulation_init.h"
#include "simulation_events.h"
#include "simulation_result.h"
#include "simulation_runtime.h"
#include "options.h"
#include <math.h>
#include <string>
#include <iostream>
#include <iomanip>

using namespace std;

#define MAXORD 5

bool continue_with_dassl(fortran_integer* idid, double* atol, double *rtol);

// dummy Jacobian
int dummyJacobianDASSL(double *t, double *y, double *yprime, double *pd, double *cj, double *rpar, fortran_integer* ipar)
{
  return 0;
  //provides a dummy Jacobian to be used with DASSL
}

/* \brief
* calculates a tiny step
*
* A tiny step is taken at initialization to check events. The tiny step is calculated as
* 200*uround*max(abs(T0),abs(T1)) = 200*uround*abs(T1), when simulating from T0 to T1, and uround is the machine precision.
*/
double calcTinyStep(double tout)
{
  double uround = dlamch_("P",1);
  if (tout == 0.0) {
    return 1000.0*uround;
  } else {
    return 1000.0*uround*fabs(tout);
  }
}
/* Returns the index of the first root that is active*/
int activeEvent(int nRoots, fortran_integer *jroot)
{
  int i;
  for (i=0; i < nRoots; i++) {
    if (jroot[i]) return i;
  }
  return -1;
}

/* The main function for the dassl solver*/
int dassl_main(int argc, char**argv,double &start,  double &stop, double &step, long &outputSteps,
               double &tolerance)
{
  long numpoints;
  int status=0;

  fortran_integer info[15];
  status = 0;
  double tout;
  double rtol = 1.0e-5;
  double atol = 1.0e-5;
  double uround = dlamch_("P",1);
  fortran_integer idid = 0;


  //double rpar = 0.0;
  fortran_integer ipar = 0;
  int i;

  // work arrays for dassl
  fortran_integer liw = 20+globalData->nStates;
  fortran_integer lrw = 52+(MAXORD+4)*globalData->nStates+
    globalData->nStates*globalData->nStates+3*globalData->nZeroCrossing;
  fortran_integer *iwork = new fortran_integer[liw];
  double *rwork = new double[lrw];
  fortran_integer *jroot = new fortran_integer[globalData->nZeroCrossing];


  // Used when calculating residual for its side effects. (alg. var calc)
  double *dummy_delta = new double[globalData->nStates];

  for(i=0; i<15; i++)
    info[i] = 0;
  for(i=0; i<liw; i++)
    iwork[i] = 0;
  for(i=0; i<lrw; i++)
    rwork[i] = 0.0;
  for(i=0; i<globalData->nHelpVars; i++)
    globalData->helpVars[i] = 0;

  const string *init_method = getFlagValue("im",argc,argv);

  inUpdate = 0;

  if (tolerance != 0.0) {
    atol = tolerance;
    rtol = tolerance;
  }
  if (outputSteps > 0) { // Use outputSteps if set, otherwise use step size.
    numpoints = outputSteps;
    step = (stop-start)/outputSteps;
  } if (outputSteps < 0) { // Negative outputSteps means use automatic stepsize
    info[2]=1; // INFO(3) =1 => intermediate-output mode
    numpoints = - (long((stop-start)*10000)+2); // Try to estimate how many points will be used.
    step = stop-start; // Only take one step
  } else {
    if (step == 0) { // outputsteps not defined and zero step, use default 1e-3
      step = 1e-3;
    }
    numpoints = long((stop-start)/step)+2;
  }

  info[2] = 1;  // We need all time steps for calculating delayed values.

  try {

    // Set starttime for simulation.
    globalData->timeValue=start;

    if (initializeEventData()) {
      cout << "Internal error, allocating event data structures" << endl;
      return -1;
    }

    if(bound_parameters()) {
      printf("Error calculating bound parameters\n");
      return -1;
    }
    if (sim_verbose) { cout << "Calculated bound parameters" << endl; }
    // Calculate initial values from (fixed) start attributes and intial equation
    // sections
    globalData->init=1;
    initial_function(); // calculates e.g. start values depending on e.g parameters.
    saveall(); // adrpo: -> save the initial values to have them in pre(var);
    storeExtrapolationData();
    storeExtrapolationData();

    if (initialize(init_method)) {
      throw TerminateSimulationException(globalData->timeValue,
        string("Error in initialization. Storing results and exiting.\n"));
    }

    if (sim_verbose) { cout << "Checking events at initialization (at time "<< globalData->timeValue << ")." << endl; }

    // Need to check for events at init=1 since e.g. initial() generate event at initialization.
    //calcEnabledZeroCrossings();
    function_updateDependents();
    CheckForInitialEvents(&globalData->timeValue);
    StartEventIteration(&globalData->timeValue);

    if (sim_verbose)  {
      cout << "Starting numerical solver at time "<< start << endl;
    }

    // Calculate initial derivatives
    if(functionODE()) {
      throw TerminateSimulationException(globalData->timeValue,string("Error calculating initial derivatives\n"));
    }
    // Calculate initial output values
    acceptedStep = 1;
    if(functionDAE_output()|| functionDAE_output2()) {
      throw TerminateSimulationException(globalData->timeValue,
        string("Error calculating initial derivatives\n"));
      acceptedStep = 0;
    }


    tout = globalData->timeValue+calcTinyStep(globalData->timeValue); // take tiny step.
    //saveall();

    function_updateDependents();

    saveall();

    function_storeDelayed();

    sim_result->emit();
    calcEnabledZeroCrossings();
    globalData->init = 0;
    if (sim_verbose) { cout << "calling DDASRT from "<< globalData->timeValue << " to "<<
      tout << endl; }
    // Take an initial tiny step and then check for events at startTime
    // Such events will have zeroCrossingEnable[i] == 0.
    info[0]=0;
    DDASRT(functionDAE_res, &globalData->nStates,   &globalData->timeValue, globalData->states,
      globalData->statesDerivatives, &tout,
      info,&rtol, &atol,
      &idid,rwork,&lrw, iwork, &liw, globalData->algebraics,
      &ipar, dummyJacobianDASSL, function_zeroCrossing,
      &globalData->nZeroCrossing, jroot);
    checkForInitialZeroCrossings(jroot);

    if (idid < 0)
    {
      if(!continue_with_dassl(&idid,&atol,&rtol))
        throw TerminateSimulationException(globalData->timeValue);
    }

    info[0] = 1;

    functionDAE_res(&globalData->timeValue,globalData->states,globalData->statesDerivatives,
      dummy_delta,0,0,0); // Since residual function calculates
    // alg vars too.
    acceptedStep=1;
    functionDAE_output();
    function_storeDelayed(); //TODO NEW storeDelayed
    acceptedStep=0;

    tout = newTime(tout,step,stop);
    while(globalData->timeValue < stop && (idid > 0 || idid == -1)) {
      // TODO: check here if time event has been reached.

      while (idid == 4)
      {
        if (sim_verbose) {
          cout  << std::setprecision(20) <<
            "Found event " << activeEvent(globalData->nZeroCrossing,jroot) << " at time " << globalData->timeValue << endl;
       	}
        sim_result->emit();

        saveall();
        // Make a tiny step so we are sure that crossings have really occured.
        //This is needed since state events are found by numerical interpolation and therefore it is not
        // certain that the event will cause the relation to trigger, e.g x < 0 might correspond to 0.000000000000000145 < 0
        info[0]=1;
        tout=globalData->timeValue+calcTinyStep(tout);
        {
          long *tmp_jroot = new long[globalData->nZeroCrossing];
          int i;
          for (i=0;i<globalData->nZeroCrossing;i++) {
            tmp_jroot[i]=jroot[i];
          }
          DDASRT(functionDAE_res, &globalData->nStates,
            &globalData->timeValue, globalData->states, globalData->statesDerivatives, &tout,
            info,&rtol, &atol,
            &idid,rwork,&lrw, iwork, &liw, globalData->algebraics, &ipar, dummyJacobianDASSL,
            function_zeroCrossing, &globalData->nZeroCrossing, jroot);

          for (i=0;i<globalData->nZeroCrossing;i++) {
            jroot[i]=tmp_jroot[i];
          }
          delete[] tmp_jroot;
        } // end tiny step

        if (sim_verbose) { cout << "Checking events at time " << globalData->timeValue << endl; }
        //      emit();
        calcEnabledZeroCrossings();
        StateEventHandler(jroot, &globalData->timeValue);
        CheckForNewEvents(&globalData->timeValue);
        StartEventIteration(&globalData->timeValue);

        // Store new values after event into delayed expressions buffers 
        function_storeDelayed();

        sim_result->emit();
        if (sim_verbose) {
          cout << "Done checking events at time " << globalData->timeValue << endl;

        }
        saveall();
        // Restart simulation
        info[0] = 0;
        // Take a tiny step forward, but > HMIN in dassl.
        tout = globalData->timeValue +  8.0 * uround * fabs(globalData->timeValue);
        if (globalData->timeValue >= stop ) throw TerminateSimulationException(globalData->timeValue);
        calcEnabledZeroCrossings();
        do {
          // Calculate time steps until either a zero crossing is found or tout is reached. 
        DDASRT(functionDAE_res,
          &globalData->nStates,   &globalData->timeValue,
          globalData->states, globalData->statesDerivatives, &tout,
          info,&rtol, &atol,
          &idid,rwork,&lrw, iwork, &liw, globalData->algebraics,
          &ipar, dummyJacobianDASSL,
          function_zeroCrossing, &globalData->nZeroCrossing, jroot);

        if (idid < 0)
        {
          if(!continue_with_dassl(&idid,&atol,&rtol))
            throw TerminateSimulationException(globalData->timeValue);
        }

        functionDAE_res(&globalData->timeValue,globalData->states,
          globalData->statesDerivatives,
          dummy_delta,0,0,0); // Since residual function calculates
        // alg vars too.
        acceptedStep = 1;
        functionDAE_output();
          function_storeDelayed();
          acceptedStep = 0;
        } while (outputSteps >= 0 && idid == 1 && globalData->timeValue < tout); 

        info[0] = 1;

      } // end while (idid == 4)

      if (numpoints < 0 || globalData->forceEmit) { /* Only emit if automatic or at "sample time" */
        if (globalData->forceEmit) globalData->forceEmit=0;
        sim_result->emit();
      }
      saveall();

      tout = newTime(globalData->timeValue,step,stop); // TODO: check time events here. Maybe dassl should not be allowed to simulate past the scheduled time event.
      if (globalData->timeValue >= stop) throw TerminateSimulationException(globalData->timeValue);
      calcEnabledZeroCrossings();
      do {
        // Calculate time steps until either a zero crossing is found or tout is reached.
        DDASRT(functionDAE_res,
            &globalData->nStates, &globalData->timeValue,
            globalData->states, globalData->statesDerivatives, &tout,
            info,&rtol, &atol,
            &idid,rwork,&lrw, iwork, &liw, globalData->algebraics,
            &ipar, dummyJacobianDASSL,
            function_zeroCrossing, &globalData->nZeroCrossing, jroot);
               
        if (idid < 0)
        {
          fflush(stderr); fflush(stdout);
          if (idid == -1)
            info[0] = 1; // try again
          if(!continue_with_dassl(&idid,&atol,&rtol))
            throw TerminateSimulationException(globalData->timeValue);
        }
      
        functionDAE_res(&globalData->timeValue,globalData->states,globalData->statesDerivatives,dummy_delta,0,0,0); // Since residual function calculates
        // alg vars too.
        acceptedStep=1;
        functionDAE_output();  // discrete variables are seperated so that the can be emited before and after the event.
        function_storeDelayed();
        acceptedStep=0;
      } while (outputSteps >= 0 && idid == 1 && globalData->timeValue < tout);
    } // end while

    acceptedStep=1;
    functionDAE_output2(); // calculate discrete varibles separately, see above
    acceptedStep=0;

    if (sim_verbose) { cout << "Simulation stopped at time " << globalData->timeValue << endl; }

  } catch (TerminateSimulationException &e) {
    cout << e.getMessage() << endl;
    if (modelTermination) { // terminated from assert, etc.
      cout << "Simulation terminated at time " << globalData->timeValue << endl;
      status = 1;
    }
  }
  sim_result->emit();
  if (!continue_with_dassl(&idid,&atol,&rtol) || idid < 0)
  {
    cerr << "Error, simulation stopped at time: " << globalData->timeValue << " with idid: " << idid << endl;
    cerr << "Result written to file." << endl;
    status = 1;
  }

  //Free dassl specific work arrays.
  delete [] iwork;
  delete [] rwork;
  delete [] jroot;
  delete [] dummy_delta;

  deinitializeEventData();

  return status;
}


bool continue_with_dassl(fortran_integer* idid, double* atol, double *rtol)
{
  static int atolZeroIterations=0;
  bool retValue = true;
  switch(*idid ){
  case 1:
  case 2:
  case 3:
  case 4:
    /* 1-4 are means success */
    break;
  case -1:
    std::cerr << "DDASRT: A large amount of work has been expended.(About 500 steps). Trying to continue ..." << std::endl;
    retValue = true; /* adrpo: try to continue */
    break;
  case -2:
    std::cerr << "DDASRT: The error tolerances are too stringent." << std::endl;
    retValue = false;
    break;
  case -3:
    if (atolZeroIterations > 10) {
      std::cerr << "DDASRT: The local error test cannot be satisfied because you specified a zero component in ATOL and the corresponding computed solution component is zero. Thus, a pure relative error test is impossible for this component." << std::endl;
      retValue = false;
      atolZeroIterations++;
    } else {
      *atol = 1e-6;
      retValue = true;
    }
    break;
  case -6:
    std::cerr << "DDASRT: DDASSL had repeated error test failures on the last attempted step." << std::endl;
    retValue = false;
    break;
  case -7:
    std::cerr << "DDASRT: The corrector could not converge." << std::endl;
    retValue = false;
    break;
  case -8:
    std::cerr << "DDASRT: The matrix of partial derivatives is singular." << std::endl;
    retValue = false;
    break;
  case -9:
    std::cerr << "DDASRT: The corrector could not converge. There were repeated error test failures in this step." << std::endl;
    retValue = false;
    break;
  case -10:
    std::cerr << "DDASRT: The corrector could not converge because IRES was equal to minus one." << std::endl;
    retValue = false;
    break;
  case -11:
    std::cerr << "DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program." << std::endl;
    retValue = false;
    break;
  case -12:
    std::cerr << "DDASRT: DDASSL failed to compute the initial YPRIME." << std::endl;
    retValue = false;
    break;
  case -33:
    std::cerr << "DDASRT: The code has encountered trouble from which it cannot recover. " << std::endl;
    retValue = false;
    break;
  }
  return retValue;
}
