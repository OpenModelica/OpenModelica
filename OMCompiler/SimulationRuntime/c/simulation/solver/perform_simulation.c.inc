/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#include "solver_main.h"
#include "events.h"
#include "dassl.h"

#include "../simulation_runtime.h"
#include "../results/simulation_result.h"
#include "../../openmodelica_func.h"
#include "linearSystem.h"
#include "nonlinearSystem.h"
#include "mixedSystem.h"
#include "../../meta/meta_modelica.h"
#include "dae_mode.h"

#include "../../util/omc_error.h"
#include "../../util/omc_file.h"
#include "external_input.h"
#include "../options.h"
#include <math.h>
#include <string.h>
#include <errno.h>
#include <float.h>

#include "synchronous.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "embedded_server.h"
#include "real_time_sync.h"
#endif

/*! \fn updateContinuousSystem
 *
 *  Function to update the whole system with EventIteration.
 *  Evaluate the functionDAE()
 *
 *  \param [ref] [data]
 */
static void prefixedName_updateContinuousSystem(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);

  if (compiledInDAEMode) /* dae mode */
  {
    data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_ALGEBRAIC);
  }
  else /* ode mode */
  {
    data->callback->functionODE(data, threadData);
    data->callback->functionAlgebraics(data, threadData);
  }
  data->callback->output_function(data, threadData);
  data->callback->setc_function(data, threadData);
  data->callback->function_storeDelayed(data, threadData);
  data->callback->function_storeSpatialDistribution(data, threadData);
  storePreValues(data);

  TRACE_POP
}

static fire_timer_t simulationUpdate(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  int foundEvent = 0 /* false */;
  int timerWasActivated = 0 /* false */;
  data->simulationInfo->noThrowAsserts = 1 /* true */;
  data->simulationInfo->needToReThrow = 0 /* false */;

  prefixedName_updateContinuousSystem(data, threadData);

  if (solverInfo->solverMethod == S_SYM_SOLVER_SSC) {
    data->simulationInfo->inlineData->dt = solverInfo->solverStepSize;
    //data->callback->symbolicInlineSystems(data, threadData);
  }

  saveZeroCrossings(data, threadData);

  /***** Event handling *****/
  if (measure_time_flag) rt_tick(SIM_TIMER_EVENT);

  fire_timer_t syncRet = handleTimers(data, threadData, solverInfo);
  fire_timer_t syncRet1;

  timerWasActivated = syncRet == TIMER_FIRED || syncRet == TIMER_FIRED_EVENT || timerWasActivated;
  do
  {
    int eventType = checkEvents(data, threadData, solverInfo->eventLst, !solverInfo->solverRootFinding, /*out*/ &solverInfo->currentTime);
    if(eventType > 0 || syncRet == TIMER_FIRED_EVENT) /* event */
    {
      foundEvent = 1;
      threadData->currentErrorStage = ERROR_EVENTHANDLING;
      infoStreamPrint(LOG_EVENTS, 1, "%s event at time=%.12g", eventType == 1 ? "time" : "state", solverInfo->currentTime);
      /* prevent emit if noEventEmit flag is used */
      if (!(omc_flag[FLAG_NOEVENTEMIT])) /* output left limit */ {
        rt_accumulate(SIM_TIMER_EVENT);
        sim_result.emit(&sim_result, data, threadData);
        rt_tick(SIM_TIMER_EVENT);
      }
      handleEvents(data, threadData, solverInfo->eventLst, &(solverInfo->currentTime), solverInfo);
      cleanUpOldValueListAfterEvent(data, solverInfo->currentTime);
      messageClose(LOG_EVENTS);
      threadData->currentErrorStage = ERROR_SIMULATION;
      solverInfo->didEventStep = 1;
      overwriteOldSimulationData(data);
    }
    else /* no event */
    {
      solverInfo->laststep = solverInfo->currentTime;
      solverInfo->didEventStep = 0;
    }

    if (measure_time_flag) { rt_accumulate(SIM_TIMER_EVENT); rt_tick(SIM_TIMER_EVENT); }
    /***** End event handling *****/


    /***** check state selection *****/
    if (stateSelection(data, threadData, 1, 1))
    {
      /* if new set is calculated reinit the solver */
      solverInfo->didEventStep = 1;
      overwriteOldSimulationData(data);
    }

    /* Check for warning of variables out of range assert(min<x || x>xmax, ...)*/
    data->callback->checkForAsserts(data, threadData);

    storePreValues(data);
    storeOldValues(data);

    syncRet1 = handleTimers(data, threadData, solverInfo);
    syncRet = syncRet1 == NO_TIMER_FIRED ? syncRet : syncRet1;
  } while (syncRet1 != NO_TIMER_FIRED);

  /* Update continous system because hold() needs to be re-evaluated */
  if (timerWasActivated == 1) {
    prefixedName_updateContinuousSystem(data, threadData);
  }

  /* Add event to spatialDistribution */
  if (foundEvent==1) {
    data->callback->function_storeDelayed(data, threadData);
    data->callback->function_storeSpatialDistribution(data, threadData);
  }

  /* Check if ignored assert throw was actually a valid throw */
  data->simulationInfo->noThrowAsserts = 0 /* false */;
  if (data->simulationInfo->needToReThrow && !foundEvent) {
    errorStreamPrint(LOG_ASSERT, 0, "No event found, but assert was triggered. Throwing now!");
    omc_throw(threadData);
  } else if (data->simulationInfo->needToReThrow) {
    infoStreamPrint(LOG_ASSERT, 0, "Found event, previous asserts are ignored.");
  }

  return syncRet;
}

static int simulationStep(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_INFO *simInfo = data->simulationInfo;

  if(0 != strcmp("ia", data->simulationInfo->outputFormat)) {
    communicateStatus("Running", (solverInfo->currentTime - simInfo->startTime)/(simInfo->stopTime - simInfo->startTime), solverInfo->currentTime, solverInfo->currentStepSize);
  }
  return solver_main_step(data, threadData, solverInfo);
}

typedef struct MEASURE_TIME {
  FILE *fmtReal;
  FILE *fmtInt;
  unsigned int stepNo;
} MEASURE_TIME;

static void fmtInit(DATA* data, MEASURE_TIME* mt)
{
  mt->fmtReal = NULL;
  mt->fmtInt = NULL;
  if(measure_time_flag)
  {
    const char* fullFileName;
    if (omc_flag[FLAG_OUTPUT_PATH]) { /* read the output path from the command line (if any) */
      if (0 > GC_asprintf(&fullFileName, "%s/%s", omc_flagValue[FLAG_OUTPUT_PATH], data->modelData->modelFilePrefix)) {
        throwStreamPrint(NULL, "perform_simulation.c: Error: can not allocate memory.");
      }
    } else {
      fullFileName = data->modelData->modelFilePrefix;
    }
    size_t len = strlen(fullFileName);
    char* filename = (char*) malloc((len+15) * sizeof(char));
    strncpy(filename,fullFileName,len);
    strncpy(&filename[len],"_prof.realdata",15);
    mt->fmtReal = omc_fopen(filename, "wb");
    if(!mt->fmtReal)
    {
      warningStreamPrint(LOG_STDOUT, 0, "Time measurements output file %s could not be opened: %s", filename, strerror(errno));
    }
    strncpy(&filename[len],"_prof.intdata",14);
    mt->fmtInt = omc_fopen(filename, "wb");
    if(!mt->fmtInt)
    {
      warningStreamPrint(LOG_STDOUT, 0, "Time measurements output file %s could not be opened: %s", filename, strerror(errno));
      fclose(mt->fmtReal);
      mt->fmtReal = NULL;
    }
    free(filename);
  }
}

static void fmtEmitStep(DATA* data, threadData_t *threadData, MEASURE_TIME* mt, SOLVER_INFO* solverInfo)
{
  if(mt->fmtReal)
  {
    int i, flag=1;
    double tmpdbl;
    unsigned int tmpint;
    int total = data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nProfileBlocks;
    rt_accumulate(SIM_TIMER_STEP);
    rt_tick(SIM_TIMER_OVERHEAD);

    /* Disable time measurements if we have trouble writing to the file... */
    flag = flag && 1 == fwrite(&mt->stepNo, sizeof(unsigned int), 1, mt->fmtInt);
    mt->stepNo++;
    flag = flag && 1 == fwrite(&(data->localData[0]->timeValue), sizeof(double), 1, mt->fmtReal);
    tmpdbl = rt_accumulated(SIM_TIMER_STEP);
    flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, mt->fmtReal);
    flag = flag && total == fwrite(rt_ncall_arr(SIM_TIMER_FIRST_FUNCTION), sizeof(uint32_t), total, mt->fmtInt);
    for(i=0; i<data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nProfileBlocks; i++) {
      tmpdbl = rt_accumulated(i + SIM_TIMER_FIRST_FUNCTION);
      flag = flag && 1 == fwrite(&tmpdbl, sizeof(double), 1, mt->fmtReal);
    }
    rt_accumulate(SIM_TIMER_OVERHEAD);

    if(!flag)
    {
      warningStreamPrint(LOG_SOLVER, 0, "Disabled time measurements because the output file could not be generated: %s", strerror(errno));
      fclose(mt->fmtInt);
      fclose(mt->fmtReal);
      mt->fmtInt = NULL;
      mt->fmtReal = NULL;
    }
  }

  /* prevent emit if noEventEmit flag is used, if it's an event */
  if (!omc_flag[FLAG_NOEVENTEMIT] || !solverInfo->didEventStep) {
    sim_result.emit(&sim_result, data, threadData);
  }
#if !defined(OMC_MINIMAL_RUNTIME)
  int terminate=0;

  if (embedded_server_update(data->embeddedServerState, data->localData[0]->timeValue, &terminate)) {
    solverInfo->didEventStep = 1;
    overwriteOldSimulationData(data);
    storePreValues(data); // Maybe??
    storeOldValues(data); // Maybe??
    sim_result.emit(&sim_result, data, threadData);
  }

  if (terminate) {
    omc_terminate((FILE_INFO) omc_dummyFileInfo, "The embedded server received command to terminate.");
  }

  if (data->real_time_sync.enabled) {
    double time = data->localData[0]->timeValue;
    int64_t res = rt_ext_tp_sync_nanosec(&data->real_time_sync.clock, (uint64_t) (data->real_time_sync.scaling*(time-data->real_time_sync.time)*1e9));
    int64_t maxLateNano = data->simulationInfo->stepSize*1e9*0.1*data->real_time_sync.scaling /* Maximum late time: 10% of step size */;
    if (res > maxLateNano) {
      int t=0,tMaxLate=0;
      const char *unit = prettyPrintNanoSec(res, &t);
      const char *unit2 = prettyPrintNanoSec(maxLateNano, &tMaxLate);
      errorStreamPrint(LOG_RT, 0, "Missed deadline at time %g; delta was %d %s (maxLate=%d %s)", time, t, unit, tMaxLate, unit2);
    }
    if (res > data->real_time_sync.maxLate) {
      data->real_time_sync.maxLate = res;
    }
  }

  printAllVarsDebug(data, 0, LOG_DEBUG);  /* ??? */
#endif
}

static void fmtClose(MEASURE_TIME* mt)
{
  if(mt->fmtInt)
  {
    fclose(mt->fmtInt);
    mt->fmtInt = NULL;
  }
  if(mt->fmtReal)
  {
    fclose(mt->fmtReal);
    mt->fmtReal = NULL;
  }
}

static void checkSimulationTerminated(DATA* data, SOLVER_INFO* solverInfo)
{
  if(terminationTerminate)
  {
    if (TermInfo.filename != NULL && TermInfo.filename[0] != '\0') {
      printInfo(stdout, TermInfo);
      fputc('\n', stdout);
    }

    infoStreamPrint(LOG_STDOUT, 0, "Simulation call terminate() at time %f\nMessage : %s", data->localData[0]->timeValue, TermMsg);
    data->simulationInfo->stopTime = solverInfo->currentTime;
  }
}

static void clear_rt_step(DATA* data)
{
  int i;
  if(measure_time_flag)
  {
    for(i=0; i<data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nProfileBlocks; i++)
    {
      rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    }
    rt_clear(SIM_TIMER_STEP);
    rt_tick(SIM_TIMER_STEP);
  }
}

static void retrySimulationStep(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  /* reduce step size by a half and try again */
  solverInfo->laststep = solverInfo->currentTime - solverInfo->laststep;

  /* restore old values and try another step with smaller step-size by dassl*/
  restoreOldValues(data);
  solverInfo->currentTime = data->localData[0]->timeValue;
  overwriteOldSimulationData(data);
  updateDiscreteSystem(data, threadData);
  warningStreamPrint(LOG_STDOUT, 0, "Integrator attempt to handle a problem with a called assert.");
  solverInfo->didEventStep = 1;
}

static void saveIntegratorStats(SOLVER_INFO* solverInfo)
{
  int ui;
  if (!(omc_flag[FLAG_NO_RESTART] && solverInfo->solverMethod==S_DASSL) && solverInfo->didEventStep)
  {
    for(ui=0; ui<numStatistics; ui++)
    {
      solverInfo->solverStats[ui] += solverInfo->solverStatsTmp[ui];
    }
  }
}

/*! \fn performSimulation(DATA* data, SOLVER_INFO* solverInfo)
 *
 *  \param [ref] [data]
 *  \param [ref] [solverInfo]
 *
 *  This function performs the simulation controlled by solverInfo.
 */
int prefixedName_performSimulation(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH

  int retValIntegrator=0;
  int retValue=0;
  int i, retry=0, steadStateReached=0;

  unsigned int __currStepNo = 0;

  SIMULATION_INFO *simInfo = data->simulationInfo;
  solverInfo->currentTime = simInfo->startTime;

  MEASURE_TIME fmt;
  fmtInit(data, &fmt);

  printAllVarsDebug(data, 0, LOG_DEBUG); /* ??? */
  if (!compiledInDAEMode)
  {
    printSparseStructure(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern,
        data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sizeRows,
        data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sizeCols,
        LOG_SOLVER, "ODE sparse pattern");
  }
  else
  {
    printSparseStructure(data->simulationInfo->daeModeData->sparsePattern,
        data->simulationInfo->daeModeData->nResidualVars,
        data->simulationInfo->daeModeData->nResidualVars,
        LOG_SOLVER, "DAE sparse pattern");
  }

  if(terminationTerminate)
  {
    printInfo(stdout, TermInfo);
    fputc('\n', stdout);
    infoStreamPrint(LOG_STDOUT, 0, "Simulation call terminate() at initialization (time %f)\nMessage : %s", data->localData[0]->timeValue, TermMsg);
    data->simulationInfo->stopTime = solverInfo->currentTime;
  } else {
    fire_timer_t syncStep = NO_TIMER_FIRED;

    /***** Start main simulation loop *****/
    while(solverInfo->currentTime < simInfo->stopTime || !simInfo->useStopTime)
    {
      int success = 0;
      threadData->currentErrorStage = ERROR_SIMULATION;

      /* Check if loggin should be activated or deactivated */
      if ((simInfo->useLoggingTime == 1) &&
          (solverInfo->currentTime >= simInfo->loggingTimeRecord[0] || solverInfo->currentTime + solverInfo->currentStepSize >= simInfo->loggingTimeRecord[0]) &&
          (solverInfo->currentTime + solverInfo->currentStepSize < simInfo->loggingTimeRecord[1]))
      {
        reactivateLogging();
      }
      if ((simInfo->useLoggingTime == 1) &&
          (solverInfo->currentTime > simInfo->loggingTimeRecord[1]))
      {
        deactivateLogging();
      }

#ifdef USE_DEBUG_TRACE
      if(useStream[LOG_TRACE]) {
        printf("TRACE: push loop step=%u, time=%.12g\n", __currStepNo, solverInfo->currentTime);
      }
#endif

      /* check for steady state */
      if (omc_flag[FLAG_STEADY_STATE])
      {
        if (0 < data->modelData->nStates)
        {
          int i;
          double maxDer = 0.0;
          double currDer;
          for(i=data->modelData->nStates; i<2*data->modelData->nStates; ++i)
          {
            currDer = fabs(data->localData[0]->realVars[i] / data->modelData->realVarsData[i].attribute.nominal);
            if(maxDer < currDer)
              maxDer = currDer;
          }
          if (maxDer < steadyStateTol) {
            steadStateReached=1;
            infoStreamPrint(LOG_STDOUT, 0, "steady state reached at time = %g\n  * max(|d(x_i)/dt|/nominal(x_i)) = %g\n  * relative tolerance = %g", solverInfo->currentTime, maxDer, steadyStateTol);
            break;
          }
        }
        else
          throwStreamPrint(threadData, "No states in model. Flag -steadyState can only be used if states are present.");
      }

      omc_alloc_interface.collect_a_little();

      /* try */
#if !defined(OMC_EMCC)
      MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      {
        printAllVars(data, 0, LOG_SOLVER_V);

        clear_rt_step(data);
        if (!compiledInDAEMode || data->modelData->nStates == 0) { /* do not use ringbuffer for daeMode */
          rotateRingBuffer(data->simulationData, 1);
          lookupRingBuffer(data->simulationData, (void**) data->localData);
        }

        modelica_boolean syncEventStep = solverInfo->didEventStep || syncStep == TIMER_FIRED || syncStep == TIMER_FIRED_EVENT;

        /***** Calculation next step size *****/
        if(syncEventStep) {
          infoStreamPrint(LOG_SOLVER, 0, "offset value for the next step: %.16g", (solverInfo->currentTime - solverInfo->laststep));
        } else {
          if (solverInfo->solverNoEquidistantGrid)
          {
            if (solverInfo->currentTime >= solverInfo->lastdesiredStep)
            {
              do {
                __currStepNo++;
                solverInfo->currentStepSize = (double)(__currStepNo*(simInfo->stopTime-simInfo->startTime))/(simInfo->numSteps) + simInfo->startTime - solverInfo->currentTime;
              } while(solverInfo->currentStepSize <= 0);
            }
          } else {
            __currStepNo++;
          }
        }

        // Calculate integrator step size
        if(simInfo->numSteps == 0) {
          if(fabs(simInfo->stopTime-simInfo->startTime) < 1e-16) {
            solverInfo->currentStepSize = 0;
          } else {
            errorStreamPrint(LOG_STDOUT, 1, "Number of integrator steps to do is 0, but experiment start time is not equal stop time.");
            infoStreamPrint(LOG_STDOUT, 0, "start time: %f, stop time: %f, integrator step size: %f",simInfo->startTime, simInfo->stopTime, simInfo->stepSize);
            messageClose(LOG_STDOUT);
            errorStreamPrint(LOG_STDOUT, 0, "model terminate | Integrator failed. | Simulation terminated at time %g", solverInfo->currentTime);
            retValue = -1;
            break;
          }
        } else {
          solverInfo->currentStepSize = (double)(__currStepNo*(simInfo->stopTime-simInfo->startTime))/(simInfo->numSteps) + simInfo->startTime - solverInfo->currentTime;
        }

        solverInfo->lastdesiredStep = solverInfo->currentTime + solverInfo->currentStepSize;

        /* if retry reduce stepsize */
        if (0 != retry) {
          solverInfo->currentStepSize /= 2;
        }
        /***** End calculation next step size *****/

        checkForSynchronous(data, solverInfo);
        /* check for next time event */
        checkForSampleEvent(data, solverInfo);

        /* if regular output point and last time events are almost equals
        * skip that step and go further */
        if (solverInfo->currentStepSize < 1e-15 && syncEventStep){
          __currStepNo++;
          rotateRingBuffer(data->simulationData, 1);
          lookupRingBuffer(data->simulationData, (void**) data->localData);
          continue;
        }

        /*
        * integration step determine all states by a integration method
        * update continuous system
        */
        infoStreamPrint(LOG_SOLVER, 1, "call solver from %g to %g (stepSize: %.15g)", solverInfo->currentTime, solverInfo->currentTime + solverInfo->currentStepSize, solverInfo->currentStepSize);
        retValIntegrator = simulationStep(data, threadData, solverInfo);
        infoStreamPrint(LOG_SOLVER, 0, "finished solver step %g", solverInfo->currentTime);
        messageClose(LOG_SOLVER);

        if (S_OPTIMIZATION == solverInfo->solverMethod) break;
        syncStep = simulationUpdate(data, threadData, solverInfo);
        retry = 0; /* reset retry */

        fmtEmitStep(data, threadData, &fmt, solverInfo);
        saveIntegratorStats(solverInfo);
        checkSimulationTerminated(data, solverInfo);

        /* terminate for some cases:
        * - integrator fails
        * - non-linear system failed to solve
        * - assert was called
        */
        if (retValIntegrator) {
          retValue = -1 + retValIntegrator;
          infoStreamPrint(LOG_STDOUT, 0, "model terminate | Integrator failed. | Simulation terminated at time %g", solverInfo->currentTime);
          break;
        } else if(check_nonlinear_solutions(data, 0)) {
          retValue = -2;
          infoStreamPrint(LOG_STDOUT, 0, "model terminate | non-linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
          break;
        } else if(check_linear_solutions(data, 0)) {
          retValue = -3;
          infoStreamPrint(LOG_STDOUT, 0, "model terminate | linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
          break;
        } else if(check_mixed_solutions(data, 0)) {
          retValue = -4;
          infoStreamPrint(LOG_STDOUT, 0, "model terminate | mixed system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
          break;
        }
        success = 1;
      }
#if !defined(OMC_EMCC)
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      if (!success) { /* catch */
        if(0 == retry) {
          retrySimulationStep(data, threadData, solverInfo);
          retry = 1;
        } else {
          retValue =  -1;
          infoStreamPrint(LOG_STDOUT, 0, "model terminate | Simulation terminated by an assert at time: %g", data->localData[0]->timeValue);
          break;
        }
      }

      TRACE_POP /* pop loop */
    } /* end while solver */
  } /* end else */

  fmtClose(&fmt);

  if (omc_flag[FLAG_STEADY_STATE] && !steadStateReached) {
    warningStreamPrint(LOG_STDOUT, 0, "Steady state has not been reached.\nThis may be due to too restrictive relative tolerance (%g) or short stopTime (%g).", steadyStateTol, simInfo->stopTime);
  }

  TRACE_POP
  return retValue;
}
