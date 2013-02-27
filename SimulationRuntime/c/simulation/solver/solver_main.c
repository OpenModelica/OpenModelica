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

 /*! \file solver_main.c
 */

#include "../../Compiler/runtime/config.h"
#include "solver_main.h"
#include "simulation_runtime.h"
#include "simulation_result.h"
#include "openmodelica_func.h"
#include "initialization.h"
#include "nonlinearSystem.h"
#include "dassl.h"
#include "delay.h"
#include "events.h"
#include "varinfo.h"
#include "stateset.h"
#include "radau.h"

/*
 * #include "dopri45.h"
 */
#include "rtclock.h"
#include "omc_error.h"
#include <math.h>
#include <string.h>
#include <errno.h>
#include <float.h>

double** work_states;

const int rungekutta_s = 4;
const double rungekutta_b[4] = { 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0 };
const double rungekutta_c[4] = { 0.0, 0.5, 0.5, 1.0 };

typedef struct RK4
{
  double** work_states;
  int work_states_ndims;
}RK4;


static int euler_ex_step(DATA* data, SOLVER_INFO* solverInfo);
static int rungekutta_step(DATA* data, SOLVER_INFO* solverInfo);

static int radau5_step(DATA* data, SOLVER_INFO* solverInfo);
static int radau3_step(DATA* data, SOLVER_INFO* solverInfo);
static int radau1_step(DATA* data, SOLVER_INFO* solverInfo);
static int lobatto2_step(DATA* data, SOLVER_INFO* solverInfo);
static int lobatto4_step(DATA* data, SOLVER_INFO* solverInfo);
static int lobatto6_step(DATA* data, SOLVER_INFO* solverInfo);

static void checkTermination(DATA* data);
static void writeOutputVars(char* names, DATA* data);

int solver_main_step(DATA* data, SOLVER_INFO* solverInfo)
{
  switch(solverInfo->solverMethod)
  {
  case 2:
    return rungekutta_step(data, solverInfo);

  case 3:
    return dasrt_step(data, solverInfo);

  case 4:
    functionODE_inline(data, solverInfo->currentStepSize);
    solverInfo->currentTime = data->localData[0]->timeValue;
    return 0;

#ifdef WITH_SUNDIALS
  case 6:
    return radau5_step(data, solverInfo);
  case 7:
    return radau3_step(data, solverInfo);
  case 8:
    return radau1_step(data, solverInfo);
  case 9:
    return lobatto2_step(data, solverInfo);
  case 10:
    return lobatto4_step(data, solverInfo);
  case 11:
    return lobatto6_step(data, solverInfo);
#endif

  case 1:
    return euler_ex_step(data, solverInfo);
  }
  return 1;
}

/*! \fn initializeSolverData(DATA* data, SOLVER_INFO* solverInfo)
 *
 *  \param [ref] [data]
 *  \param [ref] [solverInfo]
 *
 *  This function initializes solverInfo.
 */
int initializeSolverData(DATA* data, SOLVER_INFO* solverInfo)
{
  int retValue = 0;
  int i;

  SIMULATION_INFO *simInfo = &(data->simulationInfo);
  SIMULATION_DATA *sData = data->localData[0];

  /* initial solverInfo */
  solverInfo->currentTime = simInfo->startTime;
  solverInfo->currentStepSize = simInfo->stepSize;
  solverInfo->laststep = 0;
  solverInfo->offset = 0;
  solverInfo->solverRootFinding = 0;
  solverInfo->eventLst = allocList(sizeof(long));
  solverInfo->didEventStep = 0;
  solverInfo->stateEvents = 0;
  solverInfo->sampleEvents = 0;

  if(solverInfo->solverMethod == 2)
  {
    /* Allocate RK work arrays */
    RK4* rungeData = (RK4*) malloc(sizeof(RK4));
    rungeData->work_states_ndims = rungekutta_s;
    rungeData->work_states = (double**) malloc((rungeData->work_states_ndims + 1) * sizeof(double*));
    for(i = 0; i < rungeData->work_states_ndims + 1; i++)
      rungeData->work_states[i] = (double*) calloc(data->modelData.nStates, sizeof(double));
    solverInfo->solverData = rungeData;
  }
  else if(solverInfo->solverMethod == 3)
  {
    /* Initial DASSL solver */
    DASSL_DATA* dasslData = (DASSL_DATA*) malloc(sizeof(DASSL_DATA));
    INFO(LOG_SOLVER, "Initializing DASSL");
    retValue = dasrt_initial(data, solverInfo, dasslData);
    solverInfo->solverData = dasslData;
  }
  else if(solverInfo->solverMethod == 4)
  {
    /* Enable inlining solvers */
    work_states = (double**) malloc(inline_work_states_ndims * sizeof(double*));
    for(i = 0; i < inline_work_states_ndims; i++)
      work_states[i] = (double*) calloc(data->modelData.nVariablesReal, sizeof(double));
  }
#ifdef PATHCONSTRAINTS
  else if(solverInfo->solverMethod == 5)
  {
    int neqns = -1;
    /* Allocate work array for optimization*/
    pathConstraints(data, NULL, &neqns);
    /* allocateDaeIpopt(data,neqns); */
  }
#endif
#ifdef WITH_SUNDIALS
  else if (solverInfo->solverMethod == 6)
  {
    /* Allocate Radau5 IIA work arrays */
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, solverInfo, 6, 3);
  }
  else if (solverInfo->solverMethod == 7)
  {
    /* Allocate Radau3 IIA work arrays */
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, solverInfo, 7, 2);
  }
  else if (solverInfo->solverMethod == 8)
  {
    /* Allocate Radau1 IIA work arrays */
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, solverInfo, 8, 1);
  }
  else if (solverInfo->solverMethod == 9)
  {
    /* Allocate Lobatto2 IIIA work arrays */
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, solverInfo, 9, 1);
  }
  else if (solverInfo->solverMethod == 10)
  {
    /* Allocate Lobatto2 IIIA work arrays */
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, solverInfo, 10, 2);
  }
  else if (solverInfo->solverMethod == 11)
  {
    /* Allocate Lobatto2 IIIA work arrays */
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, solverInfo, 11, 3);
  }
#endif


  if(measure_time_flag)
  {
    rt_accumulate(SIM_TIMER_PREINIT);
    rt_tick(SIM_TIMER_INIT);
  }

  return retValue;
}

/*! \fn freeSolver(DATA* data, SOLVER_INFO* solverInfo)
 *
 *  \param [ref] [data]
 *  \param [ref] [solverInfo]
 *
 *  This function frees solverInfo.
 */
int freeSolverData(DATA* data, SOLVER_INFO* solverInfo)
{
  int retValue = 0;
  int i;

  /* deintialize solver related workspace */
  if(solverInfo->solverMethod == 2)
  {
    /* free RK work arrays */
    for(i = 0; i < ((RK4*)(solverInfo->solverData))->work_states_ndims + 1; i++)
      free(((RK4*)(solverInfo->solverData))->work_states[i]);
    free(((RK4*)(solverInfo->solverData))->work_states);
    free((RK4*)solverInfo->solverData);
  }
  else if(solverInfo->solverMethod == 3)
  {
    /* De-Initial DASSL solver */
    dasrt_deinitial(solverInfo->solverData);
  }
  else if(solverInfo->solverMethod == 4)
  {
    /* De-Initial inline solver */
    for(i = 0; i < inline_work_states_ndims; i++)
      free(work_states[i]);
    free(work_states);
  }
#ifdef WITH_SUNDIALS
  else if(solverInfo->solverMethod == 6)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 6, 3);
  }
  else if(solverInfo->solverMethod == 7)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 7, 2);
  }
  else if(solverInfo->solverMethod == 8)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 8, 1);
  }
  else if(solverInfo->solverMethod == 9)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 9, 1);
  }
  else if(solverInfo->solverMethod == 10)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 10, 2);
  }
  else if(solverInfo->solverMethod == 11)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 11, 3);
  }
#endif
  {
    /* free other solver memory */
  }

  /* free stateset data */
  freeStateSetData(data);

  return retValue;
}


/*! \fn initializeModel(DATA* data, const char* init_initMethod,
 *   const char* init_optiMethod, const char* init_file, double init_time,
 *   int lambda_steps)
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitMethod] user defined initialization method
 *  \param [in]  [pOptiMethod] user defined optimization method
 *  \param [in]  [pInitFile] extra argument for initialization-method "file"
 *  \param [in]  [initTime] extra argument for initialization-method "file"
 *  \param [in]  [lambda_steps] ???
 *
 *  This function starts the initialization process of the model .
 */
int initializeModel(DATA* data, const char* init_initMethod,
    const char* init_optiMethod, const char* init_file, double init_time,
    int lambda_steps)
{
  int retValue = 0;

  SIMULATION_INFO *simInfo = &(data->simulationInfo);

  copyStartValuestoInitValues(data);

  /* read input vars */
  input_function(data);

  data->localData[0]->timeValue = simInfo->startTime;

  /* instance all external Objects */
  callExternalObjectConstructors(data);

  /* allocate memory for state selection */
  initializeStateSetJacobians(data);


  if(initialization(data, init_initMethod, init_optiMethod, init_file, init_time, lambda_steps))
  {
    WARNING(LOG_STDOUT, "Error in initialization. Storing results and exiting.\nUse -lv=LOG_INIT for more information.");
    simInfo->stopTime = simInfo->startTime;
    retValue = -1;
  }

  /* adrpo: write the parameter data in the file once again after bound parameters and initialization! */
  sim_result.writeParameterData(&sim_result,data);
  INFO(LOG_SOLVER, "Wrote parameters to the file after initialization (for output formats that support this)");
  if(ACTIVE_STREAM(LOG_DEBUG))
    printParameters(data, LOG_DEBUG);

  /* initial delay again, due to maybe change
   * parameters during Initialization */
  initDelay(data, simInfo->startTime);

  storePreValues(data);
  storeOldValues(data);
  function_storeDelayed(data);
  function_updateRelations(data, 1);
  storeRelations(data);
  updateHysteresis(data);
  saveZeroCrossings(data);

  sim_result.emit(&sim_result,data);
  overwriteOldSimulationData(data);

  /* Initialization complete */
  if(measure_time_flag)
    rt_accumulate( SIM_TIMER_INIT);

  return retValue;
}


/*! \fn performSimulation(DATA* data, SOLVER_INFO* solverInfo)
 *
 *  \param [ref] [data]
 *  \param [ref] [solverInfo]
 *
 *  This function performs the simulation controlled by solverInfo.
 */
int performSimulation(DATA* data, SOLVER_INFO* solverInfo)
{

  int retValIntegrator = 0;
  int retValue = 0;
  int i, ui;

  FILE *fmt = NULL;
  unsigned int stepNo = 0;

  SIMULATION_INFO *simInfo = &(data->simulationInfo);

  solverInfo->currentTime = simInfo->startTime;

  if(measure_time_flag)
  {
    size_t len = strlen(data->modelData.modelFilePrefix);
    char* filename = (char*) malloc((len+11) * sizeof(char));
    strncpy(filename,data->modelData.modelFilePrefix,len);
    strncpy(&filename[len],"_prof.data",11);
    fmt = fopen(filename, "wb");
    if(!fmt)
    {
      WARNING2(LOG_SOLVER, "Time measurements output file %s could not be opened: %s", filename, strerror(errno));
      fclose(fmt);
      fmt = NULL;
    }
    free(filename);
  }

#ifdef USE_DEBUG_OUTPUT
  printAllVarsDebug(data, 0);
#endif

  /***** Start main simulation loop *****/
  while(solverInfo->currentTime < simInfo->stopTime)
  {
    if(measure_time_flag)
    {
      for(i = 0; i < data->modelData.modelDataXml.nFunctions + data->modelData.modelDataXml.nProfileBlocks; i++)
        rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
      rt_clear(SIM_TIMER_STEP);
      rt_tick(SIM_TIMER_STEP);
    }

    rotateRingBuffer(data->simulationData, 1, (void**) data->localData);

    /***** Calculation next step size *****/
    /* Calculate new step size after an event */
    if(solverInfo->didEventStep == 1)
    {
      solverInfo->offset = solverInfo->currentTime - solverInfo->laststep;
      if(solverInfo->offset + DBL_EPSILON > simInfo->stepSize)
        solverInfo->offset = 0;
      INFO1(LOG_SOLVER, "offset value for the next step: %.10f", solverInfo->offset);
    }
    else
      solverInfo->offset = 0;
    solverInfo->currentStepSize = simInfo->stepSize - solverInfo->offset;

    /* adjust final step? */
    if(solverInfo->currentTime + solverInfo->currentStepSize > simInfo->stopTime)
      solverInfo->currentStepSize = simInfo->stopTime - solverInfo->currentTime;
    /***** End calculation next step size *****/

    /* check for next sample event */
    checkForSampleEvent(data, solverInfo);
    INFO3(LOG_SOLVER, "call solver from %g to %g (stepSize: %g)", solverInfo->currentTime, solverInfo->currentTime + solverInfo->currentStepSize, solverInfo->currentStepSize);

    /*
     * integration step
     * determine all states by a integration method
     * update continuous system
     */
    INDENT(LOG_SOLVER);
    communicateStatus("Running", (solverInfo->currentTime-simInfo->startTime)/(simInfo->stopTime-simInfo->startTime));
    retValIntegrator = solver_main_step(data, solverInfo);
    updateContinuousSystem(data);
    saveZeroCrossings(data);
    RELEASE(LOG_SOLVER);

    /***** Event handling *****/
    if(measure_time_flag)
      rt_tick(SIM_TIMER_EVENT);

    if(checkEvents(data, solverInfo->eventLst, &(solverInfo->currentTime), solverInfo))
    {
      INFO1(LOG_EVENTS, "event handling at time %g", solverInfo->currentTime);
      INDENT(LOG_EVENTS);
      handleEvents(data, solverInfo->eventLst, &(solverInfo->currentTime), solverInfo);
      RELEASE(LOG_EVENTS);

      solverInfo->didEventStep = 1;
      overwriteOldSimulationData(data);
    }
    else
    {
      solverInfo->laststep = solverInfo->currentTime;
      solverInfo->didEventStep = 0;
    }
    if(measure_time_flag)
      rt_accumulate(SIM_TIMER_EVENT);
    /***** End event handling *****/

    /***** check state selection *****/
    if(stateSelection(data, 1))
    {
      /* if new set is calculated reinit the solver */
      solverInfo->didEventStep = 1;
      overwriteOldSimulationData(data);
    }

    /***** Emit this time step *****/
    storePreValues(data);
    storeOldValues(data);
    saveZeroCrossings(data);

    if(fmt)
    {
      int flag = 1;
      double tmpdbl;
      unsigned int tmpint;
      rt_tick(SIM_TIMER_OVERHEAD);
      rt_accumulate(SIM_TIMER_STEP);
      /* Disable time measurements if we have trouble writing to the file... */
      flag = flag && 1 == fwrite(&stepNo, sizeof(unsigned int), 1, fmt);
      stepNo++;
      flag = flag && 1 == fwrite(&(data->localData[0]->timeValue), sizeof(double), 1, fmt);
      tmpdbl = rt_accumulated(SIM_TIMER_STEP);
      flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
      for(i = 0; i < data->modelData.modelDataXml.nFunctions + data->modelData.modelDataXml.nProfileBlocks; i++)
      {
        tmpint = rt_ncall(i + SIM_TIMER_FIRST_FUNCTION);
        flag = flag && 1 == fwrite(&tmpint, sizeof(unsigned int), 1, fmt);
      }
      for(i = 0; i < data->modelData.modelDataXml.nFunctions + data->modelData.modelDataXml.nProfileBlocks; i++)
      {
        tmpdbl = rt_accumulated(i + SIM_TIMER_FIRST_FUNCTION);
        flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, fmt);
      }
      rt_accumulate(SIM_TIMER_OVERHEAD);
      if(!flag)
      {
        WARNING1(LOG_SOLVER, "Disabled time measurements because the output file could not be generated: %s", strerror(errno));
        fclose(fmt);
        fmt = NULL;
      }
    }
    sim_result.emit(&sim_result,data);

#ifdef USE_DEBUG_OUTPUT
    printAllVarsDebug(data, 0);
#endif

    /***** end of Emit this time step *****/

    /* save dassl stats before reset */
    if(solverInfo->didEventStep == 1 && solverInfo->solverMethod == 3)
    {
      for(ui = 0; ui < numStatistics; ui++)
        ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[ui] += ((DASSL_DATA*)solverInfo->solverData)->dasslStatisticsTmp[ui];
    }

    /* Check for termination of terminate() or assert() */
    checkForAsserts(data);
    if(terminationAssert || terminationTerminate)
    {
      terminationAssert = 0;
      checkForAsserts(data);
      checkTermination(data);
      if(!terminationAssert && terminationTerminate)
      {
        INFO2(LOG_STDOUT, "Simulation call terminate() at time %f\nMessage : %s", data->localData[0]->timeValue, TermMsg);
        simInfo->stopTime = solverInfo->currentTime;
      }
    }

    /* terminate for some cases:
     * - integrator fails
     * - non-linear system failed to solve
     * - assert was called
     */
    if( data->simulationInfo.simulationSuccess != 0
        || retValIntegrator != 0
        || check_nonlinear_solutions(data)
        || check_linear_solutions(data)
        || check_mixed_solutions(data)
        )
    {
      data->simulationInfo.terminal = 1;
      updateDiscreteSystem(data);
      data->simulationInfo.terminal = 0;

      if(data->simulationInfo.simulationSuccess)
      {
        retValue = -1;
        INFO1(LOG_STDOUT, "model terminate | Simulation terminated at time %g", solverInfo->currentTime);
      }
      else if(retValIntegrator)
      {
        retValue = -1 + retValIntegrator;
        INFO1(LOG_STDOUT, "model terminate | Integrator failed. | Simulation terminated at time %g", solverInfo->currentTime);
      }
      else if(check_nonlinear_solutions(data))
      {
        retValue = -2;
        INFO1(LOG_STDOUT, "model terminate | non-linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
      }
      else if(check_linear_solutions(data))
      {
        retValue = -3;
        INFO1(LOG_STDOUT, "model terminate | linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
      }
      else if(check_mixed_solutions(data))
      {
        retValue = -3;
        INFO1(LOG_STDOUT, "model terminate | mixed system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
      }
      break;
    }
  } /* end while solver */

  if(fmt)
    fclose(fmt);

  return retValue;
}

/*! \fn finishSimulation(DATA* data, SOLVER_INFO* solverInfo)
 *
 *  \param [ref] [data]
 *  \param [ref] [solverInfo]
 *
 *  This function performs the last step
 *  and outputs some statistics, this this simulation terminal step.
 */
int finishSimulation(DATA* data, SOLVER_INFO* solverInfo, const char* outputVariablesAtEnd)
{
  int retValue = 0;
  int ui;

  SIMULATION_INFO *simInfo = &(data->simulationInfo);

  /* Last step with terminal()=true */
  if(solverInfo->currentTime >= simInfo->stopTime)
  {
    data->simulationInfo.terminal = 1;
    updateDiscreteSystem(data);
    sim_result.emit(&sim_result,data);
    data->simulationInfo.terminal = 0;
  }
  communicateStatus("Finished", 1);

  /* we have output variables in the command line -output a,b,c */
  if(outputVariablesAtEnd)
  {
    writeOutputVars(strdup(outputVariablesAtEnd), data);
  }

  if(ACTIVE_STREAM(LOG_STATS))
  {
    rt_accumulate(SIM_TIMER_TOTAL);

    INFO(LOG_STATS, "### STATISTICS ###");

    INFO(LOG_STATS, "timer");
    INDENT(LOG_STATS);
    INFO2(LOG_STATS, "%12gs [%5.1f%%] pre-initialization", rt_accumulated(SIM_TIMER_PREINIT), rt_accumulated(SIM_TIMER_PREINIT)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    INFO2(LOG_STATS, "%12gs [%5.1f%%] initialization", rt_accumulated(SIM_TIMER_INIT), rt_accumulated(SIM_TIMER_INIT)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    INFO2(LOG_STATS, "%12gs [%5.1f%%] steps", rt_accumulated(SIM_TIMER_STEP), rt_accumulated(SIM_TIMER_STEP)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    INFO2(LOG_STATS, "%12gs [%5.1f%%] creating output-file", rt_accumulated(SIM_TIMER_OUTPUT), rt_accumulated(SIM_TIMER_OUTPUT)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    INFO2(LOG_STATS, "%12gs [%5.1f%%] event-handling", rt_accumulated(SIM_TIMER_EVENT), rt_accumulated(SIM_TIMER_EVENT)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    INFO2(LOG_STATS, "%12gs [%5.1f%%] overhead", rt_accumulated(SIM_TIMER_OVERHEAD), rt_accumulated(SIM_TIMER_OVERHEAD)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    INFO2(LOG_STATS, "%12gs [%5.1f%%] simulation", rt_accumulated(SIM_TIMER_TOTAL), rt_accumulated(SIM_TIMER_TOTAL)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    RELEASE(LOG_STATS);

    INFO(LOG_STATS, "events");
    INDENT(LOG_STATS);
    INFO1(LOG_STATS, "%5ld state events", solverInfo->stateEvents);
    INFO1(LOG_STATS, "%5ld sample events", solverInfo->sampleEvents);
    RELEASE(LOG_STATS);

    INFO(LOG_STATS, "solver");
    INDENT(LOG_STATS);
    if(solverInfo->solverMethod == 3) /* dassl */
    {
      /* save dassl stats before print */
      for(ui = 0; ui < numStatistics; ui++)
        ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[ui] += ((DASSL_DATA*)solverInfo->solverData)->dasslStatisticsTmp[ui];

      INFO1(LOG_STATS, "%5d steps taken", ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[0]);
      INFO1(LOG_STATS, "%5d calls of functionODE", ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[1]);
      INFO1(LOG_STATS, "%5d evaluations of jacobian", ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[2]);
      INFO1(LOG_STATS, "%5d error test failures", ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[3]);
      INFO1(LOG_STATS, "%5d convergence test failures", ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[4]);
    }
    else
    {
      INFO(LOG_STATS, "sorry - no solver statistics available. [not yet implemented]");
    }
    RELEASE(LOG_STATS);

    INFO(LOG_STATS, "### END STATISTICS ###");

    rt_tick(SIM_TIMER_TOTAL);
  }
  return retValue;
}

/*! \fn solver_main
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitMethod] user defined initialization method
 *  \param [in]  [pOptiMethod] user defined optimization method
 *  \param [in]  [pInitFile] extra argument for initialization-method "file"
 *  \param [in]  [initTime] extra argument for initialization-method "file"
 *  \param [in]  [lambda_steps] ???
 *  \param [in]  [flag] selects the ode solver
 *  \param [in]  [outputVariablesAtEnd] ???
 *
 *  This is the main function of the solver it perform
 *  the simulation.
 *
 */
int solver_main(DATA* data, const char* init_initMethod,
    const char* init_optiMethod, const char* init_file, double init_time,
    int lambda_steps, int flag, const char* outputVariablesAtEnd)
{
  int i;
  unsigned int ui;

  int retVal = 0;

  SOLVER_INFO solverInfo;
  SIMULATION_INFO *simInfo = &(data->simulationInfo);


  solverInfo.solverMethod = flag;

  /* allocate SolverInfo memory */
  retVal = initializeSolverData(data, &solverInfo);

  /* initialize all parts of the model */
  if (!retVal)
    retVal = initializeModel(data, init_initMethod, init_optiMethod, init_file, init_time, lambda_steps);

  /* starts the simulation main loop */
  if (!retVal)
  {
    INFO(LOG_SOLVER, "Performed initialization.");
    INFO2(LOG_SOLVER, "Start numerical solver from %g to %g", simInfo->startTime, simInfo->stopTime);
    retVal = performSimulation(data, &solverInfo);
  }
  else
    WARNING(LOG_STDOUT, "Initialization failed.");

  /* terminate the simulation */
  finishSimulation(data, &solverInfo, outputVariablesAtEnd);

  /* free SolverInfo memory */
  freeSolverData(data, &solverInfo);

  return retVal;
}

/***************************************    EULER_EXP     *********************************/
static int euler_ex_step(DATA* data, SOLVER_INFO* solverInfo)
{
  int i;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  modelica_real* stateDer = sDataOld->realVars + data->modelData.nStates;

  for(i = 0; i < data->modelData.nStates; i++)
  {
    sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
  }
  sData->timeValue = sDataOld->timeValue + solverInfo->currentStepSize;
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}

/***************************************    RK4      ***********************************/
static int rungekutta_step(DATA* data, SOLVER_INFO* solverInfo)
{
  double** k = ((RK4*)(solverInfo->solverData))->work_states;
  double sum;
  int i,j;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  modelica_real* stateDer = sData->realVars + data->modelData.nStates;
  modelica_real* stateDerOld = sDataOld->realVars + data->modelData.nStates;


  /* We calculate k[0] before returning from this function.
   * We only want to calculate f() 4 times per call */
  for(i = 0; i < data->modelData.nStates; i++)
  {
    k[0][i] = stateDerOld[i];
  }

  for(j = 1; j < rungekutta_s; j++)
  {
    for(i = 0; i < data->modelData.nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + solverInfo->currentStepSize * rungekutta_c[j] * k[j - 1][i];
    }
    sData->timeValue = sDataOld->timeValue + rungekutta_c[j] * solverInfo->currentStepSize;
    functionODE(data);
    for(i = 0; i < data->modelData.nStates; i++)
    {
      k[j][i] = stateDer[i];
    }
  }

  for(i = 0; i < data->modelData.nStates; i++)
  {
    sum = 0;
    for(j = 0; j < rungekutta_s; j++)
    {
      sum = sum + rungekutta_b[j] * k[j][i];
    }
    sData->realVars[i] = sDataOld->realVars[i] + solverInfo->currentStepSize * sum;
  }
  sData->timeValue = sDataOld->timeValue + solverInfo->currentStepSize;
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}

#ifdef WITH_SUNDIALS
/***************************************    Radau5 IIA     ***********************************/
int radau5_step(DATA* data, SOLVER_INFO* solverInfo)
{

  kinsolOde(solverInfo->solverData, 3, data, 6);
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}

/***************************************    Radau3 IIA     ***********************************/
int radau3_step(DATA* data, SOLVER_INFO* solverInfo)
{
  kinsolOde(solverInfo->solverData, 2, data, 7);
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}

/***************************************    Radau1 IIA     ***********************************/
int radau1_step(DATA* data, SOLVER_INFO* solverInfo)
{
  kinsolOde(solverInfo->solverData, 1, data, 8);
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}

/***************************************    Lobatto2 IIA     ***********************************/
int lobatto2_step(DATA* data, SOLVER_INFO* solverInfo)
{
  kinsolOde(solverInfo->solverData, 1, data, 9);
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}

/***************************************    Lobatto4 IIA     ***********************************/
int lobatto4_step(DATA* data, SOLVER_INFO* solverInfo)
{
  kinsolOde(solverInfo->solverData, 2, data, 10);
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}

/***************************************    Lobatto6 IIA     ***********************************/
int lobatto6_step(DATA* data, SOLVER_INFO* solverInfo)
{
  kinsolOde(solverInfo->solverData, 3, data, 11);
  solverInfo->currentTime += solverInfo->currentStepSize;
  return 0;
}
#endif

/*! \fn checkTermination
 *  \author wbraun
 *
 *  function checks if the model should really terminated.
 */
static void checkTermination(DATA *data)
{
  if(terminationAssert)
  {
    data->simulationInfo.simulationSuccess = -1;
    printInfo(stdout, TermInfo);
    fputc('\n', stdout);
  }

  if(terminationAssert)
  {
    if(warningLevelAssert)
    {
      /* terminated from assert, etc. */
      INFO2(LOG_STDOUT, "Simulation call assert() at time %f\nLevel : warning\nMessage : %s", data->localData[0]->timeValue, TermMsg);
    }
    else
    {
      INFO2(LOG_STDOUT, "Simulation call assert() at time %f\nLevel : error\nMessage : %s", data->localData[0]->timeValue, TermMsg);
      /* THROW1("timeValue = %f", data->localData[0]->timeValue); */
    }
  }
}

static void writeOutputVars(char* names, DATA* data)
{
  int i = 0;
  char *p = strtok(names, ",");

  fprintf(stdout, "time=%.20g", data->localData[0]->timeValue);

  while(p)
  {
    for(i = 0; i < data->modelData.nVariablesReal; i++)
      if(!strcmp(p, data->modelData.realVarsData[i].info.name))
        fprintf(stdout, ",%s=%.20g", p, (data->localData[0])->realVars[i]);
    for(i = 0; i < data->modelData.nVariablesInteger; i++)
      if(!strcmp(p, data->modelData.integerVarsData[i].info.name))
        fprintf(stdout, ",%s=%li", p, (data->localData[0])->integerVars[i]);
    for(i = 0; i < data->modelData.nVariablesBoolean; i++)
      if(!strcmp(p, data->modelData.booleanVarsData[i].info.name))
        fprintf(stdout, ",%s=%i", p, (data->localData[0])->booleanVars[i]);
    for(i = 0; i < data->modelData.nVariablesString; i++)
      if(!strcmp(p, data->modelData.stringVarsData[i].info.name))
        fprintf(stdout, ",%s=\"%s\"", p, (data->localData[0])->stringVars[i]);

    for(i = 0; i < data->modelData.nAliasReal; i++)
      if(!strcmp(p, data->modelData.realAlias[i].info.name))
      {
       if(data->modelData.realAlias[i].negate)
         fprintf(stdout, ",%s=%.20g", p, -(data->localData[0])->realVars[data->modelData.realAlias[i].nameID]);
       else
         fprintf(stdout, ",%s=%.20g", p, (data->localData[0])->realVars[data->modelData.realAlias[i].nameID]);
      }
    for(i = 0; i < data->modelData.nAliasInteger; i++)
      if(!strcmp(p, data->modelData.integerAlias[i].info.name))
      {
        if(data->modelData.integerAlias[i].negate)
          fprintf(stdout, ",%s=%li", p, -(data->localData[0])->integerVars[data->modelData.integerAlias[i].nameID]);
        else
          fprintf(stdout, ",%s=%li", p, (data->localData[0])->integerVars[data->modelData.integerAlias[i].nameID]);
      }
    for(i = 0; i < data->modelData.nAliasBoolean; i++)
      if(!strcmp(p, data->modelData.booleanAlias[i].info.name))
      {
        if(data->modelData.booleanAlias[i].negate)
          fprintf(stdout, ",%s=%i", p, -(data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID]);
        else
          fprintf(stdout, ",%s=%i", p, (data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID]);
      }
    for(i = 0; i < data->modelData.nAliasString; i++)
      if(!strcmp(p, data->modelData.stringAlias[i].info.name))
        fprintf(stdout, ",%s=\"%s\"", p, (data->localData[0])->stringVars[data->modelData.stringAlias[i].nameID]);

    /* parameters */
    for(i = 0; i < data->modelData.nParametersReal; i++)
      if(!strcmp(p, data->modelData.realParameterData[i].info.name))
        fprintf(stdout, ",%s=%.20g", p, data->simulationInfo.realParameter[i]);

    for(i = 0; i < data->modelData.nParametersInteger; i++)
      if(!strcmp(p, data->modelData.integerParameterData[i].info.name))
        fprintf(stdout, ",%s=%li", p, data->simulationInfo.integerParameter[i]);

    for(i = 0; i < data->modelData.nParametersBoolean; i++)
      if(!strcmp(p, data->modelData.booleanParameterData[i].info.name))
        fprintf(stdout, ",%s=%i", p, data->simulationInfo.booleanParameter[i]);

    for(i = 0; i < data->modelData.nParametersString; i++)
      if(!strcmp(p, data->modelData.stringParameterData[i].info.name))
        fprintf(stdout, ",%s=\"%s\"", p, data->simulationInfo.stringParameter[i]);

    /* move to next */
    p = strtok(NULL, ",");
  }
  fprintf(stdout, "\n"); fflush(stdout);
}
