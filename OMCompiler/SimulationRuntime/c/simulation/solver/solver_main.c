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

 /*! \file solver_main.c
 */

#include "omc_config.h"
#include "simulation/simulation_runtime.h"
#include "simulation/results/simulation_result.h"
#include "solver_main.h"
#include "openmodelica_func.h"
#include "initialization/initialization.h"
#include "nonlinearSystem.h"
#include "newtonIteration.h"
#include "cvode_solver.h"
#include "dassl.h"
#include "ida_solver.h"
#include "delay.h"
#include "events.h"
#include "util/parallel_helper.h"
#include "util/varinfo.h"
#include "model_help.h"
#include "meta/meta_modelica.h"
#include "simulation/solver/epsilon.h"
#include "simulation/solver/external_input.h"
#include "synchronous.h"
#include "linearSystem.h"
#include "sym_solver_ssc.h"
#include "gbode_main.h"
#include "gbode_util.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "simulation/solver/embedded_server.h"
#include "simulation/solver/real_time_sync.h"
#endif
#include "simulation/simulation_input_xml.h"

#include "optimization/OptimizerInterface.h"

/*
 * #include "dopri45.h"
 */
#include "util/rtclock.h"
#include "util/omc_error.h"
#include "simulation/options.h"
#include <math.h>
#include <string.h>
#include <errno.h>
#include <float.h>

double** work_states;

typedef struct RK4_DATA
{
  double** work_states;
  int work_states_ndims;
  const double *b;
  const double *c;
  double h;
}RK4_DATA;


static int euler_ex_step(DATA* data, SOLVER_INFO* solverInfo);
static int rungekutta_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
static int sym_solver_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

#ifdef OMC_HAVE_IPOPT
static int ipopt_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
#endif

static void writeOutputVars(char* names, DATA* data);

int solver_main_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  int retVal;

  switch(solverInfo->solverMethod)
  {
  case S_EULER:
    retVal = euler_ex_step(data, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
  case S_RUNGEKUTTA:
    retVal = rungekutta_step(data, threadData, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;

#if !defined(OMC_MINIMAL_RUNTIME)
  case S_DASSL:
    retVal = dassl_step(data, threadData, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
#endif

#ifdef OMC_HAVE_IPOPT
  case S_OPTIMIZATION:
    if ((int)(data->modelData->nStates + data->modelData->nInputVars) > 0){
      retVal = ipopt_step(data, threadData, solverInfo);
    } else {
      solverInfo->solverMethod = S_EULER;
      retVal = euler_ex_step(data, solverInfo);
    }
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
#endif
#ifdef WITH_SUNDIALS
  case S_IDA:
    retVal = ida_solver_step(data, threadData, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
  case S_CVODE:
    retVal = cvode_solver_step(data, threadData, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
#endif
  case S_SYM_SOLVER:
    retVal = sym_solver_step(data, threadData, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
  case S_SYM_SOLVER_SSC:
    retVal = sym_solver_ssc_step(data, threadData, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
  case S_GBODE:
    retVal = gbode_main(data, threadData, solverInfo);
    if(omc_flag[FLAG_SOLVER_STEPS])
      data->simulationInfo->solverSteps = solverInfo->solverStats.nStepsTaken + solverInfo->solverStatsTmp.nStepsTaken;
    return retVal;
  default:
    throwStreamPrint(threadData, "Unhandled case in solver_main_step.");
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
int initializeSolverData(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  int retValue = 0;
  int i;

  SIMULATION_INFO *simInfo = data->simulationInfo;

  /* initial solverInfo */
  solverInfo->currentTime = simInfo->startTime;
  solverInfo->currentStepSize = simInfo->stepSize;
  solverInfo->laststep = 0;
  solverInfo->solverRootFinding = 0;
  solverInfo->solverNoEquidistantGrid = omc_flag[FLAG_NOEQUIDISTANT_GRID];
  solverInfo->lastdesiredStep = solverInfo->currentTime + solverInfo->currentStepSize;
  solverInfo->eventLst = allocList(eventListAlloc, eventListFree, eventListCopy);
  solverInfo->didEventStep = 0;
  solverInfo->stateEvents = 0;
  solverInfo->sampleEvents = 0;
  resetSolverStats(&solverInfo->solverStats);
  resetSolverStats(&solverInfo->solverStatsTmp);

  switch (solverInfo->solverMethod)
  {
  case S_SYM_SOLVER:
  case S_EULER:
  case S_QSS: break;
  case S_SYM_SOLVER_SSC:
  {
    allocateSymSolverSsc(solverInfo, data->modelData->nStates);
    break;
  }
  case S_GBODE:
  {
    if (gbode_allocateData(data, threadData, solverInfo) != 0) {
      throwStreamPrint(threadData, "Failed to allocate memory for generic multigrid solver.");
    }
    break;
  }
  case S_RUNGEKUTTA:
  {
    /* Allocate RK work arrays */

    static const int rungekutta_s = 4;
    static const double rungekutta_b[4] = { 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0 };
    static const double rungekutta_c[4] = { 0.0, 0.5, 0.5, 1.0 };

    static const int heun_s = 2;
    static const double heun_b[2] = { 1.0 / 2.0, 1.0 / 2.0 };
    static const double heun_c[2] = { 0.0, 1.0 };

    RK4_DATA* rungeData = (RK4_DATA*) malloc(sizeof(RK4_DATA));

    rungeData->work_states_ndims = rungekutta_s;
    rungeData->b = rungekutta_b;
    rungeData->c = rungekutta_c;

    rungeData->work_states = (double**) malloc((rungeData->work_states_ndims + 1) * sizeof(double*));
    for (i = 0; i < rungeData->work_states_ndims + 1; i++) {
      rungeData->work_states[i] = (double*) calloc(data->modelData->nStates, sizeof(double));
    }
    solverInfo->solverData = rungeData;
    break;
  }
#if !defined(OMC_MINIMAL_RUNTIME)
  case S_DASSL:
  {
    /* Initial DASSL solver */
    DASSL_DATA* dasslData = (DASSL_DATA*) malloc(sizeof(DASSL_DATA));
    retValue = dassl_initial(data, threadData, solverInfo, dasslData);
    solverInfo->solverData = dasslData;
    break;
  }
#endif
#ifdef OMC_HAVE_IPOPT
  case S_OPTIMIZATION:
  {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Initializing optimizer");
    /* solverInfo->solverData = malloc(sizeof(OptData)); */
    break;
  }
#endif
#ifdef WITH_SUNDIALS
  case S_IDA:
  {
    IDA_SOLVER* idaData = NULL;
    /* Allocate ida working data */
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Initializing IDA DAE Solver");
    idaData = (IDA_SOLVER*) malloc(sizeof(IDA_SOLVER));
    retValue = ida_solver_initial(data, threadData, solverInfo, idaData);
    solverInfo->solverData = idaData;
    break;
  }
  case S_CVODE:
  {
    CVODE_SOLVER* cvodeData = NULL;
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Initializing CVODE ODE Solver");
    cvodeData = (CVODE_SOLVER*) calloc(1, sizeof(CVODE_SOLVER));
    assertStreamPrint(threadData, cvodeData != NULL, "Out of memory");
    retValue = cvode_solver_initial(data, threadData, solverInfo, cvodeData, 0 /* not FMI */);
    solverInfo->solverData = cvodeData;
    break;
  }
#endif
  default:
    errorStreamPrint(OMC_LOG_SOLVER, 0, "Solver %s disabled on this configuration", SOLVER_METHOD_NAME[solverInfo->solverMethod]);
    return 1;
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

  freeList(solverInfo->eventLst);
  /* deintialize solver related workspace */
  switch (solverInfo->solverMethod)
  {
  case S_EULER:
  case S_SYM_SOLVER:
  case S_QSS: break;
  case S_SYM_SOLVER_SSC:
    freeSymSolverSsc(solverInfo);
    break;
  case S_RUNGEKUTTA:
    /* free RK work arrays */
    for(i = 0; i < ((RK4_DATA*)(solverInfo->solverData))->work_states_ndims + 1; i++) {
      free(((RK4_DATA*)(solverInfo->solverData))->work_states[i]);
    }
    free(((RK4_DATA*)(solverInfo->solverData))->work_states);
    free((RK4_DATA*)solverInfo->solverData);
    break;
  case S_GBODE:
    gbode_freeData(data, solverInfo->solverData);
    solverInfo->solverData = NULL;
    break;
#if !defined(OMC_MINIMAL_RUNTIME)
  case S_DASSL:
    /* De-Initial DASSL solver */
    dassl_deinitial(data, solverInfo->solverData);
    break;
#endif
#ifdef OMC_HAVE_IPOPT
  case S_OPTIMIZATION:
    /* free  work arrays */
    /*destroyIpopt(solverInfo);*/
    break;
#endif
#ifdef WITH_SUNDIALS
  case S_IDA:
    /* free work arrays */
    ida_solver_deinitial(solverInfo->solverData);
    break;
  case S_CVODE:
    /* free work arrays */
    cvode_solver_deinitial(solverInfo->solverData);
    break;
#endif
  default:
    throwStreamPrint(NULL, "Unknown solver %u encountered. Possibly leaking memory!", solverInfo->solverMethod);
  }

  return retValue;
}


/*! \fn initializeModel(DATA* data, const char* init_initMethod,
 *   const char* init_file, double init_time)
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitMethod] user defined initialization method
 *  \param [in]  [pInitFile] extra argument for initialization-method "file"
 *  \param [in]  [initTime] extra argument for initialization-method "file"
 *
 *  This function starts the initialization process of the model.
 */
int initializeModel(DATA* data, threadData_t *threadData, const char* init_initMethod,
    const char* init_file, double init_time)
{
  int retValue = 0;
  int usedLocal = 0;

  SIMULATION_INFO *simInfo = data->simulationInfo;

  if(measure_time_flag)
  {
    rt_accumulate(SIM_TIMER_PREINIT);
    rt_tick(SIM_TIMER_INIT);
  }

  copyStartValuestoInitValues(data);

  data->localData[0]->timeValue = simInfo->startTime;

  /* read input vars */
  data->callback->input_function_init(data, threadData);
  externalInputUpdate(data);
  data->callback->input_function_updateStartValues(data, threadData);
  data->callback->input_function(data, threadData);

  threadData->currentErrorStage = ERROR_SIMULATION;
  /* try */
  {
    int success = 0;
#if !defined(OMC_EMCC)
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
    if(initialization(data, threadData, init_initMethod, init_file, init_time))
    {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Error in initialization. Storing results and exiting.\nUse -lv=LOG_INIT -w for more information.");
      simInfo->stopTime = simInfo->startTime;
      retValue = -1;
    }
    if (!retValue)
    {
      if (data->simulationInfo->homotopySteps == 0) {
        infoStreamPrint(OMC_LOG_SUCCESS, 0, "The initialization finished successfully without homotopy method.");
      }
      else {
        usedLocal = data->callback->homotopyMethod == LOCAL_EQUIDISTANT_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY ;
        infoStreamPrint(OMC_LOG_SUCCESS, 0, "The initialization finished successfully with %d %shomotopy steps.", data->simulationInfo->homotopySteps, usedLocal? "local ":"");
      }
    }

    success = 1;
#if !defined(OMC_EMCC)
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

    if (!success)
    {
      retValue =  -1;
      infoStreamPrint(OMC_LOG_ASSERT, 0, "simulation terminated by an assertion at initialization");
    }
  }

  /* adrpo: write the parameter data in the file once again after bound parameters and initialization! */
  sim_result.writeParameterData(&sim_result,data,threadData);
  infoStreamPrint(OMC_LOG_SOLVER, 0, "Wrote parameters to the file after initialization (for output formats that support this)");

  /* Initialization complete */
  if (measure_time_flag) {
    rt_accumulate(SIM_TIMER_INIT);
  }

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
int finishSimulation(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, const char* outputVariablesAtEnd)
{
  int retValue = 0;
  int ui;
  double t, total100;

  SIMULATION_INFO *simInfo = data->simulationInfo;

  /* Last step with terminal()=true */
  if (solverInfo->currentTime >= simInfo->stopTime && solverInfo->solverMethod != S_OPTIMIZATION) {
    infoStreamPrint(OMC_LOG_EVENTS_V, 0, "terminal event at stop time %g", solverInfo->currentTime);
    data->simulationInfo->terminal = 1;
    updateDiscreteSystem(data, threadData);

    /* prevent emit if noeventemit flag is used */
    if (!(omc_flag[FLAG_NOEVENTEMIT])) {
      sim_result.emit(&sim_result, data, threadData);
    }

    data->simulationInfo->terminal = 0;
  }

  if (0 != strcmp("ia", data->simulationInfo->outputFormat)) {
    if (simInfo->simulationSuccess) {
      communicateStatus("Finished", 1, solverInfo->currentTime, solverInfo->currentStepSize);
    } else {
      communicateStatus("Simulation aborted", (solverInfo->currentTime-simInfo->startTime)/(simInfo->stopTime-simInfo->startTime), solverInfo->currentTime, 0.0);
    }
  }

  /* we have output variables in the command line -output a,b,c */
  if(outputVariablesAtEnd)
  {
    writeOutputVars(strdup(outputVariablesAtEnd), data);
  }

  if(OMC_ACTIVE_STREAM(OMC_LOG_STATS))
  {
    rt_accumulate(SIM_TIMER_TOTAL);

    infoStreamPrint(OMC_LOG_STATS, 1, "### STATISTICS ###");

    total100 = rt_accumulated(SIM_TIMER_TOTAL)/100.0;

    infoStreamPrint(OMC_LOG_STATS, 1, "timer");
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs          reading init.xml", rt_accumulated(SIM_TIMER_INIT_XML));
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs          reading info.xml", rt_accumulated(SIM_TIMER_INFO_XML));
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] pre-initialization", rt_accumulated(SIM_TIMER_PREINIT), rt_accumulated(SIM_TIMER_PREINIT)/total100);
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] initialization", rt_accumulated(SIM_TIMER_INIT), rt_accumulated(SIM_TIMER_INIT)/total100);
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] steps", rt_accumulated(SIM_TIMER_STEP), rt_accumulated(SIM_TIMER_STEP)/total100);
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] solver (excl. callbacks)", rt_accumulated(SIM_TIMER_SOLVER), rt_accumulated(SIM_TIMER_SOLVER)/total100);
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] creating output-file", rt_accumulated(SIM_TIMER_OUTPUT), rt_accumulated(SIM_TIMER_OUTPUT)/total100);
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] event-handling", rt_accumulated(SIM_TIMER_EVENT), rt_accumulated(SIM_TIMER_EVENT)/total100);
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] overhead", rt_accumulated(SIM_TIMER_OVERHEAD), rt_accumulated(SIM_TIMER_OVERHEAD)/total100);

    t = rt_accumulated(SIM_TIMER_TOTAL)-rt_accumulated(SIM_TIMER_OVERHEAD)-rt_accumulated(SIM_TIMER_EVENT)-rt_accumulated(SIM_TIMER_OUTPUT)-rt_accumulated(SIM_TIMER_STEP)-rt_accumulated(SIM_TIMER_INIT)-rt_accumulated(SIM_TIMER_PREINIT)-rt_accumulated(SIM_TIMER_SOLVER);
    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [%5.1f%%] %s", t, t/total100, S_OPTIMIZATION == solverInfo->solverMethod ? "optimization" : "simulation");

    infoStreamPrint(OMC_LOG_STATS, 0, "%12gs [100.0%%] total", rt_accumulated(SIM_TIMER_TOTAL));
    messageClose(OMC_LOG_STATS);

    infoStreamPrint(OMC_LOG_STATS, 1, "events");
    infoStreamPrint(OMC_LOG_STATS, 0, "%5ld state events", solverInfo->stateEvents);
    infoStreamPrint(OMC_LOG_STATS, 0, "%5ld time events", solverInfo->sampleEvents);
    messageClose(OMC_LOG_STATS);

    if(S_OPTIMIZATION == solverInfo->solverMethod || /* skip solver statistics for optimization */
       S_QSS == solverInfo->solverMethod) /* skip also for qss, since not available*/
    {
    }
    else
    {
      /* save stats before print */
      addSolverStats(&(solverInfo->solverStats), &(solverInfo->solverStatsTmp));

      infoStreamPrint(OMC_LOG_STATS, 1, "solver: %s", SOLVER_METHOD_NAME[solverInfo->solverMethod]);
      infoStreamPrint(OMC_LOG_STATS, 0, "%5d steps taken", solverInfo->solverStats.nStepsTaken);
      infoStreamPrint(OMC_LOG_STATS, 0, "%5d calls of functionODE", solverInfo->solverStats.nCallsODE);
      infoStreamPrint(OMC_LOG_STATS, 0, "%5d evaluations of jacobian", solverInfo->solverStats.nCallsJacobian);
      infoStreamPrint(OMC_LOG_STATS, 0, "%5d error test failures", solverInfo->solverStats.nErrorTestFailures);
      infoStreamPrint(OMC_LOG_STATS, 0, "%5d convergence test failures", solverInfo->solverStats.nConvergenceTestFailures);
      infoStreamPrint(OMC_LOG_STATS, 0, "%gs time of jacobian evaluation", rt_accumulated(SIM_TIMER_JACOBIAN));
#ifdef USE_PARJAC
      infoStreamPrint(OMC_LOG_STATS, 0, "%i OpenMP-threads used for jacobian evaluation", omc_get_max_threads());
      int chunk_size;
      omp_sched_t kind;
      omp_get_schedule(&kind, &chunk_size);
      infoStreamPrint(OMC_LOG_STATS, 0, "Schedule: %i Chunk Size: %i", kind, chunk_size);
#endif

      messageClose(OMC_LOG_STATS);
    }

    infoStreamPrint(OMC_LOG_STATS_V, 1, "function calls");
    if (compiledInDAEMode)
    {
      infoStreamPrint(OMC_LOG_STATS_V, 1, "%5u calls of functionDAE", rt_ncall(SIM_TIMER_DAE));
      infoStreamPrint(OMC_LOG_STATS_V, 0, "%12gs [%5.1f%%]", rt_accumulated(SIM_TIMER_DAE), rt_accumulated(SIM_TIMER_DAE)/total100);
      messageClose(OMC_LOG_STATS_V);
    }
    if (data->simulationInfo->callStatistics.functionODE) {
      infoStreamPrint(OMC_LOG_STATS_V, 1, "%5ld calls of functionODE", data->simulationInfo->callStatistics.functionODE);
      infoStreamPrint(OMC_LOG_STATS_V, 0, "%12gs [%5.1f%%]", rt_accumulated(SIM_TIMER_FUNCTION_ODE), rt_accumulated(SIM_TIMER_FUNCTION_ODE)/total100);
      messageClose(OMC_LOG_STATS_V);
    }

    if (rt_ncall(SIM_TIMER_RESIDUALS)) {
      infoStreamPrint(OMC_LOG_STATS_V, 1, "%5d calls of functionODE_residual", rt_ncall(SIM_TIMER_RESIDUALS));
      infoStreamPrint(OMC_LOG_STATS_V, 0, "%12gs [%5.1f%%]", rt_accumulated(SIM_TIMER_RESIDUALS), rt_accumulated(SIM_TIMER_RESIDUALS)/total100);
      messageClose(OMC_LOG_STATS_V);
    }

    if (data->simulationInfo->callStatistics.functionAlgebraics) {
      infoStreamPrint(OMC_LOG_STATS_V, 1, "%5ld calls of functionAlgebraics", data->simulationInfo->callStatistics.functionAlgebraics);
      infoStreamPrint(OMC_LOG_STATS_V, 0, "%12gs [%5.1f%%]", rt_accumulated(SIM_TIMER_ALGEBRAICS), rt_accumulated(SIM_TIMER_ALGEBRAICS)/total100);
      messageClose(OMC_LOG_STATS_V);
    }

    infoStreamPrint(OMC_LOG_STATS_V, 1, "%5d evaluations of jacobian", rt_ncall(SIM_TIMER_JACOBIAN));
    infoStreamPrint(OMC_LOG_STATS_V, 0, "%12gs [%5.1f%%]", rt_accumulated(SIM_TIMER_JACOBIAN), rt_accumulated(SIM_TIMER_JACOBIAN)/total100);
    messageClose(OMC_LOG_STATS_V);

    infoStreamPrint(OMC_LOG_STATS_V, 0, "%5ld calls of updateDiscreteSystem", data->simulationInfo->callStatistics.updateDiscreteSystem);
    infoStreamPrint(OMC_LOG_STATS_V, 0, "%5ld calls of functionZeroCrossingsEquations", data->simulationInfo->callStatistics.functionZeroCrossingsEquations);

    infoStreamPrint(OMC_LOG_STATS_V, 1, "%5ld calls of functionZeroCrossings", data->simulationInfo->callStatistics.functionZeroCrossings);
    infoStreamPrint(OMC_LOG_STATS_V, 0, "%12gs [%5.1f%%]", rt_accumulated(SIM_TIMER_ZC), rt_accumulated(SIM_TIMER_ZC)/total100);
    messageClose(OMC_LOG_STATS_V);

    messageClose(OMC_LOG_STATS_V);  // closes section "function calls"

    infoStreamPrint(OMC_LOG_STATS_V, 1, "linear systems");
    for(ui=0; ui<data->modelData->nLinearSystems; ui++)
      printLinearSystemSolvingStatistics(data, ui, OMC_LOG_STATS_V);
    messageClose(OMC_LOG_STATS_V);

    infoStreamPrint(OMC_LOG_STATS_V, 1, "non-linear systems");
    for(ui=0; ui<data->modelData->nNonLinearSystems; ui++)
      printNonLinearSystemSolvingStatistics(&data->simulationInfo->nonlinearSystemData[ui], OMC_LOG_STATS_V);
    messageClose(OMC_LOG_STATS_V);

    messageClose(OMC_LOG_STATS);  // closes section "### STATISTICS ###"
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
 *  \param [in]  [solverID] selects the ode solver
 *  \param [in]  [outputVariablesAtEnd] ???
 *
 *  This is the main function of the solver, it performs the simulation.
 */
int solver_main(DATA* data, threadData_t *threadData, const char* init_initMethod, const char* init_file,
    double init_time, int solverID, const char* outputVariablesAtEnd, const char *argv_0)
{
  int i, retVal = 1, initSolverInfo = 0;
  unsigned int ui;
  SOLVER_INFO solverInfo;
  SIMULATION_INFO *simInfo = data->simulationInfo;
  void *dllHandle=NULL;

  solverInfo.solverMethod = solverID;

  /* do some solver specific checks */
  switch(solverInfo.solverMethod)
  {
#ifndef OMC_HAVE_IPOPT
  case S_OPTIMIZATION:
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Ipopt is needed but not available.");
    return 1;
#endif
  default:
    break;
  }

  /* first initialize the model then allocate SolverData memory
   * due to be able to use the initialized values for the integrator
   */
  simInfo->useStopTime = 1;

  /* Use minStepSize if stepSize is getting too small, but
   * allow stepSize to be zero if startTime == stopTime.
   */
  if ((simInfo->stepSize < simInfo->minStepSize) && (simInfo->stopTime > simInfo->startTime)){
    warningStreamPrint(OMC_LOG_STDOUT, 0, "The step-size %g is too small. Adjust the step-size to %g.", simInfo->stepSize, simInfo->minStepSize);
    simInfo->stepSize = simInfo->minStepSize;
    simInfo->numSteps = round((simInfo->stopTime - simInfo->startTime)/simInfo->stepSize);
  }
  /* Check step size is not larger then stopTime-startTime, up to 6 decimals
   * Ignored when linearizing model */
  if (!data->modelData->create_linearmodel && simInfo->stepSize > (simInfo->stopTime - simInfo->startTime + 1e-7)) {
    warningStreamPrint(OMC_LOG_STDOUT, 1, "Integrator step size greater than length of experiment");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "start time: %f, stop time: %f, integrator step size: %f",simInfo->startTime, simInfo->stopTime, simInfo->stepSize);
    messageCloseWarning(OMC_LOG_STDOUT);
  }
#if !defined(OMC_EMCC)
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /*  initialize external input structure */
  externalInputallocate(data);
  /* set tolerance for ZeroCrossings */
  setZCtol(fmin(data->simulationInfo->stepSize, data->simulationInfo->tolerance));
  omc_alloc_interface.collect_a_little();

  /* initialize solver data */
  /* For the DAEmode we need to initialize solverData before the initialization,
   * since the solver is used to obtain consistent values also via updateDiscreteSystem
   */
  retVal = initializeSolverData(data, threadData, &solverInfo);
  initSolverInfo = 1;

  /* initialize all parts of the model */
  if (0 == retVal){
    retVal = initializeModel(data, threadData, init_initMethod, init_file, init_time);
    omc_alloc_interface.collect_a_little();
  }

#if !defined(OMC_MINIMAL_RUNTIME)
  dllHandle = embedded_server_load_functions(omc_flagValue[FLAG_EMBEDDED_SERVER]);
  omc_real_time_sync_init(threadData, data);
  int port = 4841;
  /* If an embedded server is specified */
  if (dllHandle != NULL) {
    if (omc_flag[FLAG_EMBEDDED_SERVER_PORT]) {
      port = atoi(omc_flagValue[FLAG_EMBEDDED_SERVER_PORT]);
      /* In case of a bad conversion, don't spawn a server on port 0...*/
      if (port == 0) {
        port = 4841;
      }
    }
  }
  data->embeddedServerState = embedded_server_init(data, data->localData[0]->timeValue, solverInfo.currentStepSize, argv_0, omc_real_time_sync_update, port);
  /* If an embedded server is specified */
  if (dllHandle != NULL) {
    infoStreamPrint(OMC_LOG_STDOUT, 0, "The embedded server is initialized.");
  }
  wait_for_step(data->embeddedServerState);
#endif
  if(0 == retVal) {
    retVal = -1;
    /* if the model has no time changing variables skip the main loop*/
    if(data->modelData->nVariablesReal == 0    &&
       data->modelData->nVariablesInteger == 0 &&
       data->modelData->nVariablesBoolean == 0 &&
       data->modelData->nVariablesString == 0 ) {
      /* prevent emit if noeventemit flag is used */
      if (!(omc_flag[FLAG_NOEVENTEMIT])) {
        sim_result.emit(&sim_result, data, threadData);
      }

      infoStreamPrint(OMC_LOG_SOLVER, 0, "The model has no time changing variables, no integration will be performed.");
      solverInfo.currentTime = simInfo->stopTime;
      data->localData[0]->timeValue = simInfo->stopTime;
      overwriteOldSimulationData(data);
      retVal = finishSimulation(data, threadData, &solverInfo, outputVariablesAtEnd);
    } else if(S_QSS == solverInfo.solverMethod) {
      /* starts the simulation main loop - special solvers */
      sim_result.emit(&sim_result,data,threadData);

      /* overwrite the whole ring-buffer with initialized values */
      overwriteOldSimulationData(data);

      infoStreamPrint(OMC_LOG_SOLVER, 0, "Start numerical integration (startTime: %g, stopTime: %g)", simInfo->startTime, simInfo->stopTime);
      retVal = data->callback->performQSSSimulation(data, threadData, &solverInfo);
      omc_alloc_interface.collect_a_little();

      /* terminate the simulation */
      finishSimulation(data, threadData, &solverInfo, outputVariablesAtEnd);
      omc_alloc_interface.collect_a_little();
    } else {
      /* starts the simulation main loop - standard solver interface */
      if(omc_flag[FLAG_SOLVER_STEPS])
        data->simulationInfo->solverSteps = 0;
      if(solverInfo.solverMethod != S_OPTIMIZATION) {
        sim_result.emit(&sim_result,data,threadData);
      }

      /* overwrite the whole ring-buffer with initialized values */
      overwriteOldSimulationData(data);

      /* store all values for non-dassl event search */
      storeOldValues(data);

      infoStreamPrint(OMC_LOG_SOLVER, 0, "Start numerical solver from %g to %g", simInfo->startTime, simInfo->stopTime);
      retVal = data->callback->performSimulation(data, threadData, &solverInfo);
      omc_alloc_interface.collect_a_little();
      /* terminate the simulation */
      //if (solverInfo.solverMethod == S_SYM_SOLVER_SSC) data->callback->symbolicInlineSystems(data, threadData, 0, 2);
      finishSimulation(data, threadData, &solverInfo, outputVariablesAtEnd);
      omc_alloc_interface.collect_a_little();
    }
  }

  if (data->real_time_sync.enabled) {
    int tMaxLate=0;
    const char *unit = prettyPrintNanoSec(data->real_time_sync.maxLate, &tMaxLate);
    infoStreamPrint(OMC_LOG_RT, 0, "Maximum real-time latency was (positive=missed dealine, negative is slack): %d %s", tMaxLate, unit);
  }
#if !defined(OMC_MINIMAL_RUNTIME)
  embedded_server_deinit(data->embeddedServerState);
  embedded_server_unload_functions(dllHandle);
#endif

#if !defined(OMC_EMCC)
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  /*  free external input data */
  externalInputFree(data);

  /* free SolverInfo memory */
  if (initSolverInfo)
  {
    freeSolverData(data, &solverInfo);
  }

  if (!retVal)
    infoStreamPrint(OMC_LOG_SUCCESS, 0, "The simulation finished successfully.");

  return retVal;
}

/***************************************    EULER_EXP     *********************************/
static int euler_ex_step(DATA* data, SOLVER_INFO* solverInfo)
{
  int i;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  modelica_real* stateDer = sDataOld->realVars + data->modelData->nStates;

  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;

  for(i = 0; i < data->modelData->nStates; i++)
  {
    sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
  }
  sData->timeValue = solverInfo->currentTime;

  /* save stats */
  /* steps */
  solverInfo->solverStatsTmp.nStepsTaken += 1;
  /* function ODE evaluation is done directly after this function */
  solverInfo->solverStatsTmp.nCallsODE += 1;

  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  return 0;
}

/***************************************    SYM_SOLVER     *********************************/
static int sym_solver_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo){
  int retVal,i,j;

  modelica_integer nStates = data->modelData->nStates;
  SIMULATION_DATA *sData = data->localData[0];
  SIMULATION_DATA *sDataOld = data->localData[1];
  modelica_real* stateDer = sDataOld->realVars + data->modelData->nStates;

  if (solverInfo->currentStepSize >= DASSL_STEP_EPS){
    /* time */
    solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
    sData->timeValue = solverInfo->currentTime;
    /* update dt */
    data->simulationInfo->inlineData->dt = solverInfo->currentStepSize;
    /* copy old states to workspace */
    memcpy(data->simulationInfo->inlineData->algOldVars, sDataOld->realVars, nStates * sizeof(double));
    memcpy(sData->realVars, sDataOld->realVars, nStates * sizeof(double));

    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    retVal = data->callback->symbolicInlineSystems(data, threadData);

    if(retVal != 0){
      return -1;
    }


    /* update der(x) */
    for(i=0; i<nStates; ++i, ++j)
    {
      stateDer[i] = (sData->realVars[i]-data->simulationInfo->inlineData->algOldVars[i])/solverInfo->currentStepSize;
    }

    /* save stats */
    /* steps */
    solverInfo->solverStatsTmp.nStepsTaken += 1;
    /* function ODE evaluation is done directly after this */
    solverInfo->solverStatsTmp.nCallsODE += 1;
  }
  else
  /* in case desired step size is too small */
  {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Desired step to small try next one");
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Interpolate linear");

    /* explicit euler step*/
    for(i = 0; i < nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
    }
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    solverInfo->currentTime = sData->timeValue;
  }
  return retVal;
}

/***************************************    RK4      ***********************************/
static int rungekutta_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  RK4_DATA *rk = ((RK4_DATA*)(solverInfo->solverData));
  double** k = rk->work_states;
  double sum;
  int i,j;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  modelica_real* stateDerOld = sDataOld->realVars + data->modelData->nStates;

  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;

  /* We calculate k[0] before returning from this function.
   * We only want to calculate f() 4 times per call */
  memcpy(k[0], stateDerOld, data->modelData->nStates*sizeof(modelica_real));

  for (j = 1; j < rk->work_states_ndims; j++)
  {
    for(i = 0; i < data->modelData->nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + solverInfo->currentStepSize * rk->c[j] * k[j - 1][i];
    }
    sData->timeValue = sDataOld->timeValue + rk->c[j] * solverInfo->currentStepSize;
    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    /* eval ode equations */
    data->callback->functionODE(data, threadData);
    if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);
    memcpy(k[j], stateDer, data->modelData->nStates*sizeof(modelica_real));

  }

  for(i = 0; i < data->modelData->nStates; i++)
  {
    sum = 0;
    for(j = 0; j < rk->work_states_ndims; j++)
    {
      sum = sum + rk->b[j] * k[j][i];
    }
    sData->realVars[i] = sDataOld->realVars[i] + solverInfo->currentStepSize * sum;
  }
  sData->timeValue = solverInfo->currentTime;

  /* save stats */
  /* steps */
  solverInfo->solverStatsTmp.nStepsTaken += 1;
  /* function ODE evaluation is done directly after this */
  solverInfo->solverStatsTmp.nCallsODE += rk->work_states_ndims+1;
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  return 0;
}

/***************************************    Run Ipopt for optimization     ***********************************/
#if defined(OMC_HAVE_IPOPT)
static int ipopt_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  int cJ, res;

  cJ = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_OPTIMIZE;
  res = runOptimizer(data, threadData, solverInfo);
  threadData->currentErrorStage = cJ;
  return res;
}
#endif

static void writeOutputVars(char* names, DATA* data)
{
  int i = 0;
  char *p = NULL;
  /* fix names to contain | instead of , for splitting */
  parseVariableStr(names);
  p = strtok(names, "!");

  fprintf(stdout, "time=%.20g", data->localData[0]->timeValue);

  while(p)
  {
    for(i = 0; i < data->modelData->nVariablesReal; i++)
      if(!strcmp(p, data->modelData->realVarsData[i].info.name))
        fprintf(stdout, ",%s=%.20g", p, (data->localData[0])->realVars[i]);
    for(i = 0; i < data->modelData->nVariablesInteger; i++)
      if(!strcmp(p, data->modelData->integerVarsData[i].info.name))
        fprintf(stdout, ",%s=%li", p, (data->localData[0])->integerVars[i]);
    for(i = 0; i < data->modelData->nVariablesBoolean; i++)
      if(!strcmp(p, data->modelData->booleanVarsData[i].info.name))
        fprintf(stdout, ",%s=%i", p, (data->localData[0])->booleanVars[i]);
    for(i = 0; i < data->modelData->nVariablesString; i++)
      if(!strcmp(p, data->modelData->stringVarsData[i].info.name))
        fprintf(stdout, ",%s=\"%s\"", p, MMC_STRINGDATA((data->localData[0])->stringVars[i]));

    for(i = 0; i < data->modelData->nAliasReal; i++)
      if(!strcmp(p, data->modelData->realAlias[i].info.name))
      {
       if(data->modelData->realAlias[i].negate)
         fprintf(stdout, ",%s=%.20g", p, -(data->localData[0])->realVars[data->modelData->realAlias[i].nameID]);
       else
         fprintf(stdout, ",%s=%.20g", p, (data->localData[0])->realVars[data->modelData->realAlias[i].nameID]);
      }
    for(i = 0; i < data->modelData->nAliasInteger; i++)
      if(!strcmp(p, data->modelData->integerAlias[i].info.name))
      {
        if(data->modelData->integerAlias[i].negate)
          fprintf(stdout, ",%s=%li", p, -(data->localData[0])->integerVars[data->modelData->integerAlias[i].nameID]);
        else
          fprintf(stdout, ",%s=%li", p, (data->localData[0])->integerVars[data->modelData->integerAlias[i].nameID]);
      }
    for(i = 0; i < data->modelData->nAliasBoolean; i++)
      if(!strcmp(p, data->modelData->booleanAlias[i].info.name))
      {
        if(data->modelData->booleanAlias[i].negate)
          fprintf(stdout, ",%s=%i", p, -(data->localData[0])->booleanVars[data->modelData->booleanAlias[i].nameID]);
        else
          fprintf(stdout, ",%s=%i", p, (data->localData[0])->booleanVars[data->modelData->booleanAlias[i].nameID]);
      }
    for(i = 0; i < data->modelData->nAliasString; i++)
      if(!strcmp(p, data->modelData->stringAlias[i].info.name))
        fprintf(stdout, ",%s=\"%s\"", p, MMC_STRINGDATA((data->localData[0])->stringVars[data->modelData->stringAlias[i].nameID]));

    /* parameters */
    for(i = 0; i < data->modelData->nParametersReal; i++)
      if(!strcmp(p, data->modelData->realParameterData[i].info.name))
        fprintf(stdout, ",%s=%.20g", p, data->simulationInfo->realParameter[i]);

    for(i = 0; i < data->modelData->nParametersInteger; i++)
      if(!strcmp(p, data->modelData->integerParameterData[i].info.name))
        fprintf(stdout, ",%s=%li", p, data->simulationInfo->integerParameter[i]);

    for(i = 0; i < data->modelData->nParametersBoolean; i++)
      if(!strcmp(p, data->modelData->booleanParameterData[i].info.name))
        fprintf(stdout, ",%s=%i", p, data->simulationInfo->booleanParameter[i]);

    for(i = 0; i < data->modelData->nParametersString; i++)
      if(!strcmp(p, data->modelData->stringParameterData[i].info.name))
        fprintf(stdout, ",%s=\"%s\"", p, MMC_STRINGDATA(data->simulationInfo->stringParameter[i]));

    /* move to next */
    p = strtok(NULL, "!");
  }
  fprintf(stdout, "\n"); fflush(stdout);
}

/**
 * @brief Set all solver stats to zero.
 *
 * @param stats   Pointer to solver stats.
 */
void resetSolverStats(SOLVERSTATS* stats) {
  stats->nStepsTaken = 0;
  stats->nCallsODE = 0;
  stats->nCallsJacobian = 0;
  stats->nErrorTestFailures = 0;
  stats->nConvergenceTestFailures = 0;
}

/**
 * @brief Add two solver statistics.
 *
 * destStats += addStats
 *
 * @param destStats   Pointer to solver stats to add stats to.
 *                    On return has result of addition.
 * @param addStats    Pointer to solver stats to add.
 */
void addSolverStats(SOLVERSTATS* destStats, SOLVERSTATS* addStats) {
  destStats->nStepsTaken              += addStats->nStepsTaken;
  destStats->nCallsODE                += addStats->nCallsODE;
  destStats->nCallsJacobian           += addStats->nCallsJacobian;
  destStats->nErrorTestFailures       += addStats->nErrorTestFailures;
  destStats->nConvergenceTestFailures += addStats->nConvergenceTestFailures;
}
