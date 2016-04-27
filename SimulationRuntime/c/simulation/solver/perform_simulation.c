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

#include "simulation/simulation_runtime.h"
#include "simulation/results/simulation_result.h"
#include "openmodelica_func.h"
#include "linearSystem.h"
#include "nonlinearSystem.h"
#include "mixedSystem.h"
#include "meta/meta_modelica.h"

#include "util/omc_error.h"
#include "simulation/solver/external_input.h"
#include "simulation/options.h"
#include <math.h>
#include <string.h>
#include <errno.h>
#include <float.h>

#include "simulation/solver/synchronous.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "simulation/solver/embedded_server.h"
#include "simulation/solver/real_time_sync.h"
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
  if (!omc_flag[FLAG_DAE_MODE])
    data->callback->functionODE(data, threadData);
  data->callback->functionAlgebraics(data, threadData);
  data->callback->output_function(data, threadData);
  data->callback->function_storeDelayed(data, threadData);
  storePreValues(data);

  TRACE_POP
}

static int simulationUpdate(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  prefixedName_updateContinuousSystem(data, threadData);

  if (solverInfo->solverMethod == S_SYM_IMP_EULER) data->callback->symEulerUpdate(data, solverInfo->solverStepSize);

  saveZeroCrossings(data, threadData);

  /***** Event handling *****/
  if (measure_time_flag) rt_tick(SIM_TIMER_EVENT);

  int syncRet = handleTimers(data, threadData, solverInfo);
  int syncRet1;
  do
  {
    int eventType = checkEvents(data, threadData, solverInfo->eventLst, !solverInfo->solverRootFinding, /*out*/ &solverInfo->currentTime);
    if(eventType > 0 || syncRet == 2) /* event */
    {
      threadData->currentErrorStage = ERROR_EVENTHANDLING;
      infoStreamPrint(LOG_EVENTS, 1, "%s event at time=%.12g", eventType == 1 ? "time" : "state", solverInfo->currentTime);
      /* prevent emit if noEventEmit flag is used */
      if (!(omc_flag[FLAG_NOEVENTEMIT])) /* output left limit */
        sim_result.emit(&sim_result, data, threadData);
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

    if (measure_time_flag) rt_accumulate(SIM_TIMER_EVENT);
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
    syncRet = syncRet1 == 0 ? syncRet : syncRet1;
  } while (syncRet1);
  return syncRet;
}

static int simulationStep(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_INFO *simInfo = data->simulationInfo;

  if(0 != strcmp("ia", data->simulationInfo->outputFormat))
  {
    communicateStatus("Running", (solverInfo->currentTime - simInfo->startTime)/(simInfo->stopTime - simInfo->startTime));
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
    size_t len = strlen(data->modelData->modelFilePrefix);
    char* filename = (char*) malloc((len+15) * sizeof(char));
    strncpy(filename,data->modelData->modelFilePrefix,len);
    strncpy(&filename[len],"_prof.realdata",15);
    mt->fmtReal = fopen(filename, "wb");
    if(!mt->fmtReal)
    {
      warningStreamPrint(LOG_STDOUT, 0, "Time measurements output file %s could not be opened: %s", filename, strerror(errno));
    }
    strncpy(&filename[len],"_prof.intdata",14);
    mt->fmtInt = fopen(filename, "wb");
    if(!mt->fmtInt)
    {
      warningStreamPrint(LOG_STDOUT, 0, "Time measurements output file %s could not be opened: %s", filename, strerror(errno));
      fclose(mt->fmtReal);
      mt->fmtReal = NULL;
    }
    free(filename);
  }
}

static void fmtEmitStep(DATA* data, threadData_t *threadData, MEASURE_TIME* mt, int didEventStep)
{
  if(mt->fmtReal)
  {
    int i, flag=1;
    double tmpdbl;
    unsigned int tmpint;
    int total = data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nProfileBlocks;
    rt_tick(SIM_TIMER_OVERHEAD);
    rt_accumulate(SIM_TIMER_STEP);

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
  if ((omc_flag[FLAG_NOEVENTEMIT] && didEventStep == 0) || !omc_flag[FLAG_NOEVENTEMIT]) {
    sim_result.emit(&sim_result, data, threadData);
  }
#if !defined(OMC_MINIMAL_RUNTIME)
  embedded_server_update(data->embeddedServerState, data->localData[0]->timeValue);
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
    printInfo(stdout, TermInfo);
    fputc('\n', stdout);
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
  if (solverInfo->didEventStep == 1)
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
  int i, retry=0;

  unsigned int __currStepNo = 0;

  SIMULATION_INFO *simInfo = data->simulationInfo;
  solverInfo->currentTime = simInfo->startTime;

  MEASURE_TIME fmt;
  fmtInit(data, &fmt);

  printAllVarsDebug(data, 0, LOG_DEBUG); /* ??? */
  printSparseStructure(data, LOG_SOLVER);

  modelica_boolean syncStep = 0;

  /***** Start main simulation loop *****/
  while(solverInfo->currentTime < simInfo->stopTime || !simInfo->useStopTime)
  {
    int success = 0;
    threadData->currentErrorStage = ERROR_SIMULATION;

#ifdef USE_DEBUG_TRACE
    if(useStream[LOG_TRACE]) {
      printf("TRACE: push loop step=%u, time=%.12g\n", __currStepNo, solverInfo->currentTime);
    }
#endif

    omc_alloc_interface.collect_a_little();

    /* try */
#if !defined(OMC_EMCC)
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
    {
      clear_rt_step(data);
      rotateRingBuffer(data->simulationData, 1, (void**) data->localData);

      modelica_boolean syncEventStep = solverInfo->didEventStep || syncStep;

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
      solverInfo->currentStepSize = (double)(__currStepNo*(simInfo->stopTime-simInfo->startTime))/(simInfo->numSteps) + simInfo->startTime - solverInfo->currentTime;
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

      fmtEmitStep(data, threadData, &fmt, solverInfo->didEventStep);
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

  fmtClose(&fmt);

  TRACE_POP
  return retValue;
}
