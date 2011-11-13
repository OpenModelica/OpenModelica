/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link?ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link?ping, Sweden.
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
 * from Link?ping University, either from the above address,
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
#include "simulation_runtime.h"
#include "initialization.h"
#include "events.h"
#include "dopri45.h"
#include "rtclock.h"
#include "error.h"
#include <math.h>
#include <string.h>
#include <errno.h>

int
euler_ex_step(double step, int(*f)());

int
rungekutta_step(double step, int(*f)());

int
dasrt_step(double step, double start, double stop, int trigger, int* stats, double tolerance);

/*********************variable declaration and functions for DASSL-solver**********************/


void  DDASRT(
    int (*res) (double *t, double *y, double *yprime, double *delta, fortran_integer *ires, double *rpar, fortran_integer* ipar),
    fortran_integer *neq,
    double *t,
    double *y,
    double *yprime,
    double *tout,
    fortran_integer *info,
    double *rtol,
    double *atol,
    fortran_integer *idid,
    double *rwork,
    fortran_integer *lrw,
    fortran_integer *iwork,
    fortran_integer *liw,
    double *rpar,
    fortran_integer *ipar,
    int (*jac) (double *t, double *y, double *yprime, double *delta, double *cj, double *rpar, fortran_integer* ipar),
    int (*g) (fortran_integer *neqm, double *t, double *y, fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar),
    fortran_integer *ng,
    fortran_integer *jroot
);

double dlamch_(char*,int);

#define MAXORD 5
#define DASSLSTATS 5
#define INFOLEN 15

/* external variables >> these variables mustn't be deleted or changed during the WHOLE integration process,
 *				            >> so they have to be declared outside dasrt_step
 *					          >> exception: solver has to be reset after an event */
fortran_integer info[INFOLEN];
fortran_integer idid = 0;
fortran_integer* ipar = 0;

/* work arrays for DASSL */
fortran_integer liw = 0;
fortran_integer lrw = 0;
double *rwork = NULL;
fortran_integer *iwork = 0;
fortran_integer NG_var = 0; /* ->see ddasrt.c LINE 250 (number of constraint functions) */
fortran_integer *jroot = NULL;

/* Used when calculating residual for its side effects. (alg. var calc) */
double *dummy_delta = NULL;

/* provides a dummy Jacobian to be used with DASSL */
int
dummy_Jacobian(double *t, double *y, double *yprime, double *pd,
               double *cj, double *rpar, fortran_integer* ipar) {
  return 0;
}
int Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar);
int JacA_num(double *t, double *y, double *matrixA);
int Jacobian_num(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar);

int
dummy_zeroCrossing(fortran_integer *neqm, double *t, double *y,
                   fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar) {
  return 0;
}

int
continue_DASRT(fortran_integer* idid, double* tolarence);

/*********************end of variable declaration and functions for DASSL-solver***************/

/*********************variable declaration for RK4-solver**************************************/
const int rungekutta_s = 4;
const double rungekutta_b[4] = { 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0 };
const double rungekutta_c[4] = { 0.0, 0.5, 0.5, 1.0 };

/*********************work array for inline implementation*************************************/
double **work_states = NULL;

int
solver_main_step(int flag, double start, double stop, int reset,
                 int reinit_step, int useInterpolation, double fixStep, int* stats, double tolarence,
                 int* reject) {
  switch (flag) {
  case 2:
    return rungekutta_step(globalData->current_stepsize, functionODE);
  case 3:
    return dasrt_step(globalData->current_stepsize, start, stop, reset, stats, tolarence);
  case 4:
    return functionODE_inline();
  case 6:
    return stepsize_control(start, stop, fixStep, functionODE, reinit_step,
                            useInterpolation, tolarence, reject);
    /* embedded DOPRI5(4) */
  case 1:
  default:
    return euler_ex_step(globalData->current_stepsize, functionODE);
  }
  return 1;
}

/*	function: update_DAEsystem
 *
 * 	! Function to update the whole system with EventIteration.
 * 	Evaluate the functionDAE() */
void
update_DAEsystem() {
  int needToIterate = 0;
  int IterationNum = 0;

  functionDAE(&needToIterate);
  while (checkForDiscreteChanges() || needToIterate) {
    if (needToIterate) {
    	DEBUG_INFO(LV_EVENTS, "reinit() call. Iteration needed!");
    } else {
    	DEBUG_INFO(LV_EVENTS, "discrete Variable changed. Iteration needed!");
    }
    saveall();
    functionDAE(&needToIterate);
    IterationNum++;
    if (IterationNum > IterationMax) {
      THROW("ERROR: Too many event iterations. System is inconsistent!");
    }
  }
}

/* The main function for a solver with synchronous event handling
 * flag 1=explicit euler
 * 2=rungekutta
 * 3=dassl
 * 4=inline
 * 5=free
 * 6=dopri5 with stepsize control & dense output */

int
solver_main(double start, double stop, double step, long outputSteps, double tolerance, int flag) {

	double interpolationStep; /* this variable is used for output at fixed points */
	int useInterpolation = 0;
	int i;

	/* Setup some variables for statistics */
	int stateEvents = 0;
	int sampleEvents = 0;

	int dasslStats[DASSLSTATS];
	int dasslStatsTmp[DASSLSTATS];

	int reject = 0;


	/* Flags for event handling */
	int dideventstep = 0;
	int reset = 0;
	int reinit_step = 1;

	int sampleEvent_actived = 0;

	double uround = dlamch_((char*) "P", 1);

	int retValIntegrator = 0;

	FILE *fmt = NULL;
	unsigned int stepNo = 0;

	double laststep = 0;
	double offset = 0;

	if (outputSteps > 0) { /* Use outputSteps if set, otherwise use step size. */
		step = (stop - start) / outputSteps;
	} else {
		if (step == 0) { /* outputsteps not defined and zero step, use default 1e-3 */
			step = 1e-3;
		}
	}
	globalData->current_stepsize = step;
	interpolationStep = step; /* first interpolation point is the value of the fixed external stepsize */

	/* Set user tolerance for solver (DASSL,Dopri5) */

	globalData->terminal = 0;
	globalData->oldTime = start;
	globalData->timeValue = start;


	for (i = 0; i < DASSLSTATS; i++) {
			dasslStats[i] = 0;
			dasslStatsTmp[i] = 0;
		}

	switch (flag) {
	/* Allocate RK work arrays */
	case 2:
		work_states = (double**) malloc((rungekutta_s + 1) * sizeof(double*));
		for (i = 0; i < rungekutta_s + 1; i++)
			work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
		break;
		/* Enable inlining solvers */
	case 4:
		work_states = (double**) malloc(inline_work_states_ndims * sizeof(double*));
		for (i = 0; i < inline_work_states_ndims; i++)
			work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
		break;
		/* Allocate DOPRI5(4) derivative array and activate dense output */
	case 6:
		useInterpolation = 1;
		work_states = (double**) malloc((9 + 1) * sizeof(double*));
		for (i = 0; i < 9 + 1; i++)
			work_states[i] = (double*) calloc(globalData->nStates, sizeof(double));
		break;
	}

	if (initializeEventData()) {
		INFO("Internal error, allocating event data structures");
		return -1;
	}

	if (bound_parameters()) {
		INFO("Error calculating bound parameters");
		return -1;
	}

	DEBUG_INFO(LV_SOLVER, "Calculated bound parameters");

	/* Evaluate all constant equations during initialization */
	globalData->init = 1;
	functionAliasEquations();

	/* Calculate initial values from initial_function()
	 * saveall() value as pre values */
	if (measure_time_flag) {
		rt_accumulate(SIM_TIMER_PREINIT);
		rt_tick(SIM_TIMER_INIT);
	}
	if(initialization("state",	"nelder_mead_ex")) {
			THROW("Error in initialization. Storing results and exiting.");
	}
	/*if (initialization(init_initMethod ? init_initMethod->c_str() : NULL,
			init_optiMethod ? init_optiMethod->c_str() : NULL)) {
		THROW("Error in initialization. Storing results and exiting.");
	*/

	SaveZeroCrossings();
	saveall();
	if (sim_verbose >= LOG_SOLVER) {
			sim_result_emit();
	}

	/* Activate sample and evaluate again */
	if (globalData->curSampleTimeIx < globalData->nSampleTimes) {
		sampleEvent_actived = checkForSampleEvent();
		activateSampleEvents();
	}
	update_DAEsystem();
	if (sampleEvent_actived) {
		deactivateSampleEventsandEquations();
		sampleEvent_actived = 0;
	}
	saveall();
	CheckForNewEvent(0);
	SaveZeroCrossings();
	saveall();
	sim_result_emit();
	storeExtrapolationDataEvent();

  /* Initialization complete */
  if (measure_time_flag)
    rt_accumulate( SIM_TIMER_INIT);

  if (globalData->timeValue >= stop) {
    if (sim_verbose >= LOG_SOLVER) {
      INFO("Simulation done!");
    }
    globalData->terminal = 1;
    update_DAEsystem();

    sim_result_emit();

    globalData->terminal = 0;
    return 0;
  }

  DEBUG_INFO(LV_SOLVER, "Performed initial value calculation.");
  DEBUG_INFO2(LV_SOLVER, "Start numerical solver from %g to %g", globalData->timeValue, stop);

  if (measure_time_flag) {
	char* filename = (char*) malloc(strlen(globalData->modelFilePrefix)+1+11);
	filename = strncpy(filename,globalData->modelFilePrefix,strlen(globalData->modelFilePrefix));
    filename = strcat(filename,"_prof.data");
    fmt = fopen(filename, "wb");
    if (!fmt) {
      WARNING2("Warning: Time measurements output file %s could not be opened: %s", filename, strerror(errno));
      fclose(fmt);
      fmt = NULL;
    }
  }

  while (globalData->timeValue < stop) {
	  if (measure_time_flag) {
		  for (i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++)
			  rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
		  rt_clear(SIM_TIMER_STEP);
		  rt_tick(SIM_TIMER_STEP);
	  }

	  /* Calculate new step size after an event */
	  if (dideventstep == 1) {
		  offset = globalData->timeValue - laststep;
		  dideventstep = 0;
		  if (offset + uround > step)
			  offset = 0;
		  DEBUG_INFO1(LV_SOLVER, "Offset value for the next step: %g", offset);
	  } else {
		  offset = 0;
	  }

	  if (flag != 6) {
		  /*!!!!! not for DOPRI5 with stepsize control */
		  globalData->current_stepsize = step - offset;

		  if (globalData->timeValue + globalData->current_stepsize > stop) {
			  globalData->current_stepsize = stop - globalData->timeValue;
		  }
	  }

	  if (globalData->curSampleTimeIx < globalData->nSampleTimes) {
		  sampleEvent_actived = checkForSampleEvent();
	  }

	  DEBUG_INFO2(LV_SOLVER, "Call Solver from %g to %g", globalData->timeValue,
				  globalData->timeValue + globalData->current_stepsize);
	  /* do one integration step
	   *
	   * one step means:
	   * determine all states by Integration-Method
	   * update continuous part with
	   * functionODE() and functionAlgebraics(); */

	  communicateStatus("Running", (globalData->timeValue-start)/(stop-start));
	  retValIntegrator = solver_main_step(flag, start, stop, reset,
			  reinit_step, useInterpolation, step, dasslStatsTmp, tolerance, &reject);

	  functionAlgebraics();
	  functionAliasEquations();
	  function_storeDelayed();
	  SaveZeroCrossings();

	  if (reset)
		  reset = 0;

	  /* Check for Events */
	  if (measure_time_flag)
		  rt_tick(SIM_TIMER_EVENT);

	  if (CheckForNewEvent(&sampleEvent_actived)) {
		  stateEvents++;
		  reset = 1;
		  dideventstep = 1;
		  /* due to an event overwrite old values */
		  storeExtrapolationDataEvent();
	  } else if (sampleEvent_actived) {
		  EventHandle(1);
		  sampleEvents++;
		  reset = 1;
		  dideventstep = 1;
		  sampleEvent_actived = 0;
		  /* due to an event overwrite old values */
		  storeExtrapolationDataEvent();
	  } else {
		  laststep = globalData->timeValue;
	  }

	  if (measure_time_flag)
		  rt_accumulate(SIM_TIMER_EVENT);

	  /******** Emit this time step ********/
	  saveall();
	  if (useInterpolation)
		  interpolation_control(dideventstep, interpolationStep, step, stop);

	  if (fmt) {
		  int flag = 1;
		  double tmpdbl;
		  unsigned int tmpint;
		  rt_tick(SIM_TIMER_OVERHEAD);
		  rt_accumulate(SIM_TIMER_STEP);
		  /* Disable time measurements if we have trouble writing to the file... */
		  flag = flag && 1 == fwrite(&stepNo, sizeof(unsigned int), 1, fmt);
		  stepNo++;
		  flag = flag && 1 == fwrite(&globalData->timeValue, sizeof(double), 1,
				  fmt);
		  tmpdbl = rt_accumulated(SIM_TIMER_STEP);
		  flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
		  for (i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++) {
			  tmpint = rt_ncall(i + SIM_TIMER_FIRST_FUNCTION);
			  flag = flag && 1 == fwrite(&tmpint, sizeof(unsigned int), 1, fmt);
		  }
		  for (i = 0; i < globalData->nFunctions + globalData->nProfileBlocks; i++) {
			  tmpdbl = rt_accumulated(i + SIM_TIMER_FIRST_FUNCTION);
			  flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
		  }
		  rt_accumulate(SIM_TIMER_OVERHEAD);
		  if (!flag) {
			  WARNING1("Warning: Disabled time measurements because the output file could not be generated: %s", strerror(errno));
			  fclose(fmt);
			  fmt = NULL;
		  }
	  }

	  SaveZeroCrossings();
	  if (!useInterpolation)
		    sim_result_emit();
	  /********* end of Emit this time step *********/

	  if (reset == 1) {
		  /* save dassl stats before reset */
		  for (i = 0; i < DASSLSTATS; i++)
			  dasslStats[i] += dasslStatsTmp[i];
	  }
	  /* Check for termination of terminate() or assert() */
	  if (terminationAssert || terminationTerminate || modelErrorCode) {
		  terminationAssert = 0;
		  terminationTerminate = 0;
		  checkForAsserts();
		  checkTermination();
		  if (modelErrorCode)
			  retValIntegrator = 1;
	  }

	  if (retValIntegrator) {
		  globalData->terminal = 1;
		  update_DAEsystem();
		  globalData->terminal = 0;
		  if (fmt)
			  fclose(fmt);
		  THROW1("model terminate | Simulation terminated at time %g",globalData->timeValue);
	  }

	  DEBUG_INFO1(LV_SOLVER, "** Step to  %g Done!", globalData->timeValue);

  }
  /* Last step with terminal()=true */
  if (globalData->timeValue >= stop) {
	  globalData->terminal = 1;
	  update_DAEsystem();
	  sim_result_emit();
	  globalData->terminal = 0;
  }
  communicateStatus("Finished", 1);

  if (sim_verbose >= LOG_STATS) {
	int i;
    /* save dassl stats before print */
    for (i = 0; i < DASSLSTATS; i++)
      dasslStats[i] += dasslStatsTmp[i];

    rt_accumulate(SIM_TIMER_TOTAL);

    INFO("##### Statistics #####");
    INFO_AL1("simulation time: %g", rt_accumulated(SIM_TIMER_TOTAL));
    INFO_AL1("Events: %d", stateEvents + sampleEvents);
    INFO_AL1("State Events: %d", stateEvents);
    INFO_AL1("Sample Events: %d", sampleEvents);
    INFO_AL("##### Solver Statistics #####");
    INFO_AL1("The number of steps taken: %d", dasslStats[0]);
    INFO_AL1("The number of calls to functionODE: %d", dasslStats[1]);
    INFO_AL1("The evaluations of Jacobian: %d", dasslStats[2]);
    INFO_AL1("The number of error test failures: %d", dasslStats[3]);
    INFO_AL1("The number of convergence test failures: %d", dasslStats[4]);
    if (flag == 6)
    {
        INFO1("DOPRI5: total number of steps rejected: %d", reject);
    }
  }

  if (fmt)
    fclose(fmt);

  return 0;
}

/***************************************		EULER_EXP     *********************************/
int
euler_ex_step(double step, int(*f)()) {
  int i;
  globalData->timeValue += step;
  for (i = 0; i < globalData->nStates; i++) {
    globalData->states[i] += globalData->statesDerivatives[i] * step;
  }
  f();
  return 0;
}

/***************************************		RK4  		***********************************/
int
rungekutta_step(double step, int(*f)()) {
  double* backupstates = work_states[rungekutta_s];
  double** k = work_states;
  double sum;
  int i,j;

  /* We calculate k[0] before returning from this function.
   * We only want to calculate f() 4 times per call */
  for (i = 0; i < globalData->nStates; i++) {
    k[0][i] = globalData->statesDerivatives[i];
    backupstates[i] = globalData->states[i];
  }

  for (j = 1; j < rungekutta_s; j++) {
    globalData->timeValue = globalData->oldTime + rungekutta_c[j] * step;
    for (i = 0; i < globalData->nStates; i++) {
      globalData->states[i] = backupstates[i] + step * rungekutta_c[j] * k[j - 1][i];
    }
    f();
    for (i = 0; i < globalData->nStates; i++) {
      k[j][i] = globalData->statesDerivatives[i];
    }
  }

  for (i = 0; i < globalData->nStates; i++) {
    sum = 0;
    for (j = 0; j < rungekutta_s; j++) {
      sum = sum + rungekutta_b[j] * k[j][i];
    }
    globalData->states[i] = backupstates[i] + step * sum;
  }
  f();
  return 0;
}

/**********************************************************************************************
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL performs a warm-start
 **********************************************************************************************/
int
dasrt_step(double step, double start, double stop, int trigger1,
           int* tmpStats, double tolerance) {
  double tout = 0;
  int i = 0;
  double *rpar = NULL;

  if (globalData->timeValue == start) {
    DEBUG_INFO(LV_SOLVER, "**Initializing DASSL");

    /* work arrays for DASSL */
    liw = 20 + globalData->nStates;
    lrw = 52 + (MAXORD + 4) * globalData->nStates + globalData->nStates
        * globalData->nStates + 3 * globalData->nZeroCrossing;
    rwork = (double*) calloc(lrw,sizeof(double));
    ASSERT(rwork,"out of memory");
    iwork = (fortran_integer*)  calloc(liw,sizeof(fortran_integer));
    ASSERT(iwork,"out of memory");
    jroot = (fortran_integer*)  calloc(globalData->nZeroCrossing,sizeof(fortran_integer));
    ASSERT(jroot,"out of memory");
    /* Used when calculating residual for its side effects. (alg. var calc) */
    dummy_delta = (double*) calloc(globalData->nStates,sizeof(double));
    ASSERT(dummy_delta,"out of memory");
    rpar = (double*) calloc(1,sizeof(double));
    ASSERT(rpar,"out of memory");
    ipar = (fortran_integer*) calloc(3,sizeof(fortran_integer));
    ASSERT(ipar,"out of memory");
    ipar[0] = sim_verbose;
    ipar[1] = LOG_JAC;
    ipar[2] = LOG_ENDJAC;

    memset(info,0,INFOLEN);
    /*********************************************************************
     *info[2] = 1;  //intermediate-output mode
     *********************************************************************
     *info[3] = 1;  //go not past TSTOP
     *rwork[0] = stop;  //TSTOP
     *********************************************************************
     *info[6] = 1;  //prohibit code to decide max. stepsize on its own
     *rwork[1] = *step;  //define max. stepsize
     *********************************************************************/

    if (jac_flag || num_jac_flag)
      info[4] = 1; /* use sub-routine JAC */
  }
  /* If an event is triggered and processed restart dassl. */
  if (trigger1) {
    DEBUG_INFO(LV_EVENTS, "Event-management forced reset of DDASRT");
    /* obtain reset */
    info[0] = 0;
  }

  /* Calculate time steps until TOUT is reached
   * (DASSL calculates beyond TOUT unless info[6] is set to 1!) */
    do {

      tout = globalData->timeValue + step;
      /* Check that tout is not less than timeValue
       * else will dassl get in trouble. If that is the case we skip the current step. */

      if (globalData->timeValue - tout >= -1e-13) {
        DEBUG_INFO(LV_SOLVER, "**Desired step to small try next one");

        globalData->timeValue = tout;
        return 0;
      }

      DEBUG_INFO2(LV_SOLVER, "**Calling DDASRT from %g to %g", globalData->timeValue, tout);

      /* Save all statesDerivatives due to avoid this in functionODE_residual */
      memcpy(globalData->statesDerivativesBackup,
             globalData->statesDerivatives, globalData->nStates * sizeof(double));

      if (jac_flag) {
        DDASRT(functionODE_residual, &globalData->nStates,
               &globalData->timeValue, globalData->states,
               globalData->statesDerivativesBackup, &tout, info, &tolerance, &tolerance,
               &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
               Jacobian, dummy_zeroCrossing, &NG_var, jroot);
      } else if (num_jac_flag) {
        DDASRT(functionODE_residual, &globalData->nStates,
               &globalData->timeValue, globalData->states,
               globalData->statesDerivativesBackup, &tout, info, &tolerance, &tolerance,
               &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
               Jacobian_num, dummy_zeroCrossing, &NG_var, jroot);
      } else {
        DDASRT(functionODE_residual, &globalData->nStates,
               &globalData->timeValue, globalData->states,
               globalData->statesDerivativesBackup, &tout, info, &tolerance, &tolerance,
               &idid, rwork, &lrw, iwork, &liw, globalData->algebraics, ipar,
               dummy_Jacobian, dummy_zeroCrossing, &NG_var, jroot);
      }

      if(sim_verbose == LOG_SOLVER)
      {
    	  INFO1("DASSL call | value of idid: %ld", idid);
    	  INFO_AL1("DASSL call | current time value: %0.4g", globalData->timeValue);
    	  INFO_AL1("DASSL call | current integration time value: %0.4g", rwork[3]);
    	  INFO_AL1("DASSL call | step size H to be attempted on next step: %0.4g", rwork[2]);
    	  INFO_AL1("DASSL call | step size used on last successful step: %0.4g", rwork[6]);
    	  INFO_AL1("DASSL call | number of steps taken so far: %ld", iwork[10]);
    	  INFO_AL1("DASSL call | number of calls of functionODE() : %ld", iwork[11]);
    	  INFO_AL1("DASSL call | number of calculation of jacobian : %ld", iwork[12]);
    	  INFO_AL1("DASSL call | total number of convergence test failures: %ld", iwork[13]);
    	  INFO_AL1("DASSL call | total number of error test failures: %ld", iwork[14]);
      }

      /* save dassl stats */
      for (i = 0; i < DASSLSTATS; i++) {
        assert(10 + i < liw);
        tmpStats[i] = iwork[10 + i];
      }

      if (idid < 0) {
        fflush( stderr);
        fflush( stdout);
        if (idid == -1) {
          DEBUG_INFO(LV_SOLVER, "DDASRT will try again...");

          info[0] = 1; /* try again */
        }
        if (!continue_DASRT(&idid, &tolerance))
          THROW1("DASRT can't continue. time = %f", globalData->timeValue);
      }

      functionODE();
    } while (idid == -1 && globalData->timeValue <= stop);

  if (tout > stop) {
    DEBUG_INFO(LV_SOLVER, "DDASRT finished");
  }
  return 0;
}

int
continue_DASRT(fortran_integer* idid, double* atol) {
  static int atolZeroIterations = 0;
  int retValue = 1;

  switch (*idid) {
  case 1:
  case 2:
  case 3:
    /* 1-4 means success */
    break;
  case -1:
    WARNING("DDASRT: A large amount of work has been expended.(About 500 steps). Trying to continue ...");
    retValue = 1; /* adrpo: try to continue */
    break;
  case -2:
    THROW("DDASRT: The error tolerances are too stringent");
    retValue = 0;
    break;
  case -3:
    if (atolZeroIterations > 10) {
      THROW("DDASRT: The local error test cannot be satisfied because you specified a zero component in ATOL and the corresponding computed solution component is zero. Thus, a pure relative error test is impossible for this component.");
      retValue = 0;
      atolZeroIterations++;
    } else {
      *atol = 1e-6;
      retValue = 1;
    }
    break;
  case -6:
    THROW("DDASRT: DDASSL had repeated error test failures on the last attempted step.");
    retValue = 0;
    break;
  case -7:
    THROW("DDASRT: The corrector could not converge.");
    retValue = 0;
    break;
  case -8:
    THROW("DDASRT: The matrix of partial derivatives is singular.");
    retValue = 0;
    break;
  case -9:
    THROW("DDASRT: The corrector could not converge. There were repeated error test failures in this step.");
    retValue = 0;
    break;
  case -10:
    THROW("DDASRT: The corrector could not converge because IRES was equal to minus one.");
    retValue = 0;
    break;
  case -11:
    THROW("DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program.");
    retValue = 0;
    break;
  case -12:
    THROW("DDASRT: DDASSL failed to compute the initial YPRIME.");
    retValue = 0;
    break;
  case -33:
    THROW("DDASRT: The code has encountered trouble from which it cannot recover.");
    retValue = 0;
    break;
  }
  return retValue;
}

/*
 * provides a analytical Jacobian to be used with DASSL
 */
int
Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
         double *rpar, fortran_integer* ipar) {
  double* backupStates;
  double backupTime;
  int i;
  backupStates = globalData->states;
  backupTime = globalData->timeValue;

  globalData->states = y;
  globalData->timeValue = *t;
  functionODE();
  functionJacA(pd);

  /* add cj to the diagonal elements of the matrix */
  for (i = 0; i < globalData->nStates; i++) {
    pd[i + i * globalData->nStates] -= (double) *cj;
  }
  globalData->states = backupStates;
  globalData->timeValue = backupTime;

  return 0;
}

/*
 *  provides a numerical Jacobian to be used with DASSL
 */
int
JacA_num(double *t, double *y, double *matrixA) {
  double delta_h = 1.e-10;
  double delta_hh;
  double* yprime = (double*) calloc(globalData->nStates,sizeof(double));
  double* yprime_delta_h = (double*) calloc(globalData->nStates,sizeof(double));

  double* backupStates;
  double backupTime;
  int i,j,l;
  backupStates = globalData->states;
  backupTime = globalData->timeValue;

  globalData->states = y;
  globalData->timeValue = *t;

  functionODE();
  memcpy(yprime, globalData->statesDerivatives,
      globalData->nStates * sizeof(double));

  /* matrix A, add cj to diagonal elements and store in pd */
  for (i = 0; i < globalData->nStates; i++) {
    delta_hh = delta_h * (globalData->states[i] > 0 ? globalData->states[i]
                                                                         : -globalData->states[i]);
    delta_hh = ((delta_h > delta_hh) ? delta_h : delta_hh);
    globalData->states[i] += delta_hh;
    functionODE();
    globalData->states[i] -= delta_hh;

    for (j = 0; j < globalData->nStates; j++) {
      l = j + i * globalData->nStates;
      matrixA[l] = (globalData->statesDerivatives[j] - yprime[j]) / delta_hh;
    }
  }

  globalData->states = backupStates;
  globalData->timeValue = backupTime;
  free(yprime);
  free(yprime_delta_h);

  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
int Jacobian_num(double *t, double *y, double *yprime, double *pd, double *cj,
   double *rpar, fortran_integer* ipar) {

  int i,j;
  if (JacA_num(t, y, pd)) {
	  THROW("Error, can not get Matrix A ");
    return 1;
  }

  /* add cj to diagonal elements and store in pd */
  for (i = 0; i < globalData->nStates; i++) {
    for (j = 0; j < globalData->nStates; j++) {
      if (i == j) {
        pd[i + j * globalData->nStates] -= (double) *cj;
      }
    }
  }
  return 0;
}

int functionODE_residual(double *t, double *x, double *xd, double *delta,
                    fortran_integer *ires, double *rpar, fortran_integer *ipar)
{
  double timeBackup;
  double* statesBackup;
  int i;

  timeBackup = globalData->timeValue;
  statesBackup = globalData->states;

  globalData->timeValue = *t;
  globalData->states = x;
  functionODE();

  /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
  for (i=0; i < globalData->nStates; i++) {
    delta[i] = globalData->statesDerivatives[i] - xd[i];
  }

  globalData->states = statesBackup;
  globalData->timeValue = timeBackup;

  return 0;
}
