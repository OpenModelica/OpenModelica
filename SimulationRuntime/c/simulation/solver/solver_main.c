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
#include "dassl.h"
#include "ida_solver.h"
#include "delay.h"
#include "events.h"
#include "util/varinfo.h"
#include "radau.h"
#include "model_help.h"
#include "meta/meta_modelica.h"
#include "simulation/solver/epsilon.h"
#include "simulation/solver/external_input.h"
#include "linearSystem.h"
#include "sym_imp_euler.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "simulation/solver/embedded_server.h"
#include "simulation/solver/real_time_sync.h"
#endif

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
  double *b;
  double *c;
}RK4_DATA;


static int euler_ex_step(DATA* data, SOLVER_INFO* solverInfo);
static int rungekutta_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
static int sym_euler_im_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

static int radau_lobatto_step(DATA* data, SOLVER_INFO* solverInfo);

#ifdef WITH_IPOPT
static int ipopt_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
#endif

static void writeOutputVars(char* names, DATA* data);

int solver_main_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  int retVal;

  switch(solverInfo->solverMethod)
  {
  case S_EULER:
    retVal = euler_ex_step(data, solverInfo);
    TRACE_POP
    return retVal;
  case S_HEUN:
  case S_RUNGEKUTTA:
    retVal = rungekutta_step(data, threadData, solverInfo);
    TRACE_POP
    return retVal;

#if !defined(OMC_MINIMAL_RUNTIME)
  case S_DASSL:
    retVal = dassl_step(data, threadData, solverInfo);
    TRACE_POP
    return retVal;
#endif

#ifdef WITH_IPOPT
  case S_OPTIMIZATION:
    if ((int)(data->modelData->nStates + data->modelData->nInputVars) > 0){
      retVal = ipopt_step(data, threadData, solverInfo);
    } else {
      solverInfo->solverMethod = S_EULER;
      retVal = euler_ex_step(data, solverInfo);
    }
    TRACE_POP
    return retVal;
#endif
#ifdef WITH_SUNDIALS
  case S_RADAU5:
  case S_RADAU3:
  case S_RADAU1:
  case S_LOBATTO2:
  case S_LOBATTO4:
  case S_LOBATTO6:
    retVal = radau_lobatto_step(data, solverInfo);
    TRACE_POP
    return retVal;
  case S_IDA:
    retVal = ida_solver_step(data, threadData, solverInfo);
    TRACE_POP
    return retVal;
#endif
  case S_SYM_EULER:
    retVal = sym_euler_im_step(data, threadData, solverInfo);
    return retVal;
  case S_SYM_IMP_EULER:
    retVal = sym_euler_im_with_step_size_control_step(data, threadData, solverInfo);
    return retVal;
  }

  TRACE_POP
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
  TRACE_PUSH
  int retValue = 0;
  int i;

  SIMULATION_INFO *simInfo = data->simulationInfo;

  /* initial solverInfo */
  solverInfo->currentTime = simInfo->startTime;
  solverInfo->currentStepSize = simInfo->stepSize;
  solverInfo->laststep = 0;
  solverInfo->solverRootFinding = 0;
  solverInfo->solverNoEquidistantGrid = 0;
  solverInfo->lastdesiredStep = solverInfo->currentTime + solverInfo->currentStepSize;
  solverInfo->eventLst = allocList(sizeof(long));
  solverInfo->didEventStep = 0;
  solverInfo->stateEvents = 0;
  solverInfo->sampleEvents = 0;
  solverInfo->solverStats = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));
  solverInfo->solverStatsTmp = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));

  /* if FLAG_NOEQUIDISTANT_GRID is set, choose dassl step method */
  if (omc_flag[FLAG_NOEQUIDISTANT_GRID])
  {
    solverInfo->integratorSteps = 1; /* TRUE */
  }

  switch (solverInfo->solverMethod)
  {
  case S_SYM_EULER:
  case S_EULER: break;
  case S_SYM_IMP_EULER:
  {
    allocateSymEulerImp(solverInfo, data->modelData->nStates);
    break;
  }
  case S_RUNGEKUTTA:
  case S_HEUN:
  {
    /* Allocate RK work arrays */

    static const int rungekutta_s = 4;
    static const double rungekutta_b[4] = { 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0 };
    static const double rungekutta_c[4] = { 0.0, 0.5, 0.5, 1.0 };

    static const int heun_s = 2;
    static const double heun_b[2] = { 1.0 / 2.0, 1.0 / 2.0 };
    static const double heun_c[2] = { 0.0, 1.0 };

    RK4_DATA* rungeData = (RK4_DATA*) malloc(sizeof(RK4_DATA));

    if (solverInfo->solverMethod==S_RUNGEKUTTA) {
      rungeData->work_states_ndims = rungekutta_s;
      rungeData->b = rungekutta_b;
      rungeData->c = rungekutta_c;
    } else if (solverInfo->solverMethod==S_HEUN) {
      rungeData->work_states_ndims = heun_s;
      rungeData->b = heun_b;
      rungeData->c = heun_c;
    } else {
      throwStreamPrint(threadData, "Unknown RK solver");
    }

    rungeData->work_states = (double**) malloc((rungeData->work_states_ndims + 1) * sizeof(double*));
    for (i = 0; i < rungeData->work_states_ndims + 1; i++) {
      rungeData->work_states[i] = (double*) calloc(data->modelData->nStates, sizeof(double));
    }
    solverInfo->solverData = rungeData;
    break;
  }
  case S_QSS: break;
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
#ifdef WITH_IPOPT
  case S_OPTIMIZATION:
  {
    infoStreamPrint(LOG_SOLVER, 0, "Initializing optimizer");
    /* solverInfo->solverData = malloc(sizeof(OptData)); */
    break;
  }
#endif
#ifdef WITH_SUNDIALS
  case S_RADAU5:
  {
    /* Allocate Radau5 IIA work arrays */
    infoStreamPrint(LOG_SOLVER, 0, "Initializing Radau IIA of order 5");
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, threadData, solverInfo, solverInfo->solverMethod, 3);
    break;
  }
  case S_RADAU3:
  {
    /* Allocate Radau3 IIA work arrays */
    infoStreamPrint(LOG_SOLVER, 0, "Initializing Radau IIA of order 3");
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, threadData, solverInfo, solverInfo->solverMethod, 2);
    break;
  }
  case S_RADAU1:
  {
    /* Allocate Radau1 IIA work arrays */
    infoStreamPrint(LOG_SOLVER, 0, "Initializing Radau IIA of order 1 (implicit euler) ");
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, threadData, solverInfo, solverInfo->solverMethod, 1);
    break;
  }
  case S_LOBATTO6:
  {
    /* Allocate Lobatto2 IIIA work arrays */
    infoStreamPrint(LOG_SOLVER, 0, "Initializing Lobatto IIIA of order 6");
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, threadData, solverInfo, solverInfo->solverMethod, 3);
    break;
  }
  case S_LOBATTO4:
  {
    /* Allocate Lobatto4 IIIA work arrays */
    infoStreamPrint(LOG_SOLVER, 0, "Initializing Lobatto IIIA of order 4");
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, threadData, solverInfo, solverInfo->solverMethod, 2);
    break;
  }
  case S_LOBATTO2:
  {
    /* Allocate Lobatto6 IIIA work arrays */
    infoStreamPrint(LOG_SOLVER, 0, "Initializing Lobatto IIIA of order 2 (trapeze rule)");
    solverInfo->solverData = calloc(1, sizeof(KINODE));
    allocateKinOde(data, threadData, solverInfo, solverInfo->solverMethod, 1);
    break;
  }
  case S_IDA:
  {
    IDA_SOLVER* idaData = NULL;
	/* Allocate Lobatto6 IIIA work arrays */
    infoStreamPrint(LOG_SOLVER, 0, "Initializing IDA DAE Solver");
    idaData = (IDA_SOLVER*) malloc(sizeof(IDA_SOLVER));
    retValue = ida_solver_initial(data, threadData, solverInfo, idaData);
    solverInfo->solverData = idaData;
    break;
  }
#endif
  default:
    errorStreamPrint(LOG_SOLVER, 0, "Solver %s disabled on this configuration", SOLVER_METHOD_NAME[solverInfo->solverMethod]);
    TRACE_POP
    return 1;
  }

  TRACE_POP
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
  if (solverInfo->solverMethod == S_SYM_IMP_EULER)
  {
    freeSymEulerImp(solverInfo);
  }
  else if(solverInfo->solverMethod == S_RUNGEKUTTA || solverInfo->solverMethod == S_HEUN)
  {
    /* free RK work arrays */
    for(i = 0; i < ((RK4_DATA*)(solverInfo->solverData))->work_states_ndims + 1; i++)
      free(((RK4_DATA*)(solverInfo->solverData))->work_states[i]);
    free(((RK4_DATA*)(solverInfo->solverData))->work_states);
    free((RK4_DATA*)solverInfo->solverData);
  }
#if !defined(OMC_MINIMAL_RUNTIME)
  else if(solverInfo->solverMethod == S_DASSL)
  {
    /* De-Initial DASSL solver */
    dassl_deinitial(solverInfo->solverData);
  }
#endif
#ifdef WITH_IPOPT
  else if(solverInfo->solverMethod == S_OPTIMIZATION)
  {
    /* free  work arrays */
    /*destroyIpopt(solverInfo);*/
  }
#endif
#ifdef WITH_SUNDIALS
  else if(solverInfo->solverMethod == S_RADAU5)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 3);
  }
  else if(solverInfo->solverMethod == S_RADAU3)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 2);
  }
  else if(solverInfo->solverMethod == S_RADAU1)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 1);
  }
  else if(solverInfo->solverMethod == S_LOBATTO6)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 3);
  }
  else if(solverInfo->solverMethod == S_LOBATTO4)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 2);
  }
  else if(solverInfo->solverMethod == S_LOBATTO2)
  {
    /* free  work arrays */
    freeKinOde(data, solverInfo, 1);
  }
  else if(solverInfo->solverMethod == S_IDA)
  {
    /* free  work arrays */
    ida_solver_deinitial(solverInfo->solverData);
  }
#endif
  {
    /* free other solver memory */
  }

  return retValue;
}


/*! \fn initializeModel(DATA* data, const char* init_initMethod,
 *   const char* init_file, double init_time, int lambda_steps)
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitMethod] user defined initialization method
 *  \param [in]  [pInitFile] extra argument for initialization-method "file"
 *  \param [in]  [initTime] extra argument for initialization-method "file"
 *  \param [in]  [lambda_steps] ???
 *
 *  This function starts the initialization process of the model .
 */
int initializeModel(DATA* data, threadData_t *threadData, const char* init_initMethod,
    const char* init_file, double init_time, int lambda_steps)
{
  TRACE_PUSH
  int retValue = 0;

  SIMULATION_INFO *simInfo = data->simulationInfo;

  if(measure_time_flag)
  {
    rt_accumulate(SIM_TIMER_PREINIT);
    rt_tick(SIM_TIMER_INIT);
    rt_tick(SIM_TIMER_TOTAL);
  }

  copyStartValuestoInitValues(data);

  /* read input vars */
  data->callback->input_function_init(data, threadData);
  externalInputUpdate(data);
  data->callback->input_function_updateStartValues(data, threadData);
  data->callback->input_function(data, threadData);

  data->localData[0]->timeValue = simInfo->startTime;

  /* instance all external Objects */
  data->callback->callExternalObjectConstructors(data, threadData);

  threadData->currentErrorStage = ERROR_SIMULATION;
  /* try */
  {
    int success = 0;
    MMC_TRY_INTERNAL(simulationJumpBuffer)
    if(initialization(data, threadData, init_initMethod, init_file, init_time, lambda_steps))
    {
      warningStreamPrint(LOG_STDOUT, 0, "Error in initialization. Storing results and exiting.\nUse -lv=LOG_INIT -w for more information.");
      simInfo->stopTime = simInfo->startTime;
      retValue = -1;
    }

    success = 1;
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
    if (!success)
    {
      retValue =  -1;
      infoStreamPrint(LOG_ASSERT, 0, "simulation terminated by an assertion at initialization");
    }
  }

  /* adrpo: write the parameter data in the file once again after bound parameters and initialization! */
  sim_result.writeParameterData(&sim_result,data,threadData);
  infoStreamPrint(LOG_SOLVER, 0, "Wrote parameters to the file after initialization (for output formats that support this)");

  /* Initialization complete */
  if (measure_time_flag) {
    rt_accumulate(SIM_TIMER_INIT);
  }

  TRACE_POP
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
  TRACE_PUSH

  int retValue = 0;
  int ui;

  SIMULATION_INFO *simInfo = data->simulationInfo;

  /* Last step with terminal()=true */
  if(solverInfo->currentTime >= simInfo->stopTime && solverInfo->solverMethod != S_OPTIMIZATION) {
    infoStreamPrint(LOG_EVENTS_V, 0, "terminal event at stop time %g", solverInfo->currentTime);
    data->simulationInfo->terminal = 1;
    updateDiscreteSystem(data, threadData);

    /* prevent emit if noeventemit flag is used */
    if (!(omc_flag[FLAG_NOEVENTEMIT])) {
      sim_result.emit(&sim_result, data, threadData);
    }

    data->simulationInfo->terminal = 0;
  }

  if (0 != strcmp("ia", data->simulationInfo->outputFormat)) {
    communicateStatus("Finished", 1);
  }

  /* we have output variables in the command line -output a,b,c */
  if(outputVariablesAtEnd)
  {
    writeOutputVars(strdup(outputVariablesAtEnd), data);
  }

  if(ACTIVE_STREAM(LOG_STATS))
  {
    rt_accumulate(SIM_TIMER_TOTAL);

    infoStreamPrint(LOG_STATS, 1, "### STATISTICS ###");

    infoStreamPrint(LOG_STATS, 1, "timer");
    infoStreamPrint(LOG_STATS, 0, "%12gs          reading init.xml", rt_accumulated(SIM_TIMER_INIT_XML));
    infoStreamPrint(LOG_STATS, 0, "%12gs          reading info.xml", rt_accumulated(SIM_TIMER_INFO_XML));
    infoStreamPrint(LOG_STATS, 0, "%12gs          pre-initialization", rt_accumulated(SIM_TIMER_PREINIT));
    infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] initialization", rt_accumulated(SIM_TIMER_INIT), rt_accumulated(SIM_TIMER_INIT)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] steps", rt_accumulated(SIM_TIMER_STEP), rt_accumulated(SIM_TIMER_STEP)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] creating output-file", rt_accumulated(SIM_TIMER_OUTPUT), rt_accumulated(SIM_TIMER_OUTPUT)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] event-handling", rt_accumulated(SIM_TIMER_EVENT), rt_accumulated(SIM_TIMER_EVENT)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] overhead", rt_accumulated(SIM_TIMER_OVERHEAD), rt_accumulated(SIM_TIMER_OVERHEAD)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);

    if(S_OPTIMIZATION != solverInfo->solverMethod)
      infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] simulation", rt_accumulated(SIM_TIMER_TOTAL)-rt_accumulated(SIM_TIMER_OVERHEAD)-rt_accumulated(SIM_TIMER_EVENT)-rt_accumulated(SIM_TIMER_OUTPUT)-rt_accumulated(SIM_TIMER_STEP)-rt_accumulated(SIM_TIMER_INIT)-rt_accumulated(SIM_TIMER_PREINIT), (rt_accumulated(SIM_TIMER_TOTAL)-rt_accumulated(SIM_TIMER_OVERHEAD)-rt_accumulated(SIM_TIMER_EVENT)-rt_accumulated(SIM_TIMER_OUTPUT)-rt_accumulated(SIM_TIMER_STEP)-rt_accumulated(SIM_TIMER_INIT)-rt_accumulated(SIM_TIMER_PREINIT))/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    else
      infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] optimization", rt_accumulated(SIM_TIMER_TOTAL)-rt_accumulated(SIM_TIMER_OVERHEAD)-rt_accumulated(SIM_TIMER_EVENT)-rt_accumulated(SIM_TIMER_OUTPUT)-rt_accumulated(SIM_TIMER_STEP)-rt_accumulated(SIM_TIMER_INIT)-rt_accumulated(SIM_TIMER_PREINIT), (rt_accumulated(SIM_TIMER_TOTAL)-rt_accumulated(SIM_TIMER_OVERHEAD)-rt_accumulated(SIM_TIMER_EVENT)-rt_accumulated(SIM_TIMER_OUTPUT)-rt_accumulated(SIM_TIMER_STEP)-rt_accumulated(SIM_TIMER_INIT)-rt_accumulated(SIM_TIMER_PREINIT))/rt_accumulated(SIM_TIMER_TOTAL)*100.0);

    infoStreamPrint(LOG_STATS, 0, "%12gs [%5.1f%%] total", rt_accumulated(SIM_TIMER_TOTAL), rt_accumulated(SIM_TIMER_TOTAL)/rt_accumulated(SIM_TIMER_TOTAL)*100.0);
    messageClose(LOG_STATS);

    infoStreamPrint(LOG_STATS, 1, "events");
    infoStreamPrint(LOG_STATS, 0, "%5ld state events", solverInfo->stateEvents);
    infoStreamPrint(LOG_STATS, 0, "%5ld time events", solverInfo->sampleEvents);
    messageClose(LOG_STATS);

    if(S_OPTIMIZATION == solverInfo->solverMethod || /* skip solver statistics for optimization */
       S_QSS == solverInfo->solverMethod) /* skip also for qss, since not available*/
    {
    }
    else
    {
      /* save stats before print */
      for(ui=0; ui<numStatistics; ui++)
        solverInfo->solverStats[ui] += solverInfo->solverStatsTmp[ui];

      infoStreamPrint(LOG_STATS, 1, "solver: %s", SOLVER_METHOD_NAME[solverInfo->solverMethod]);
      infoStreamPrint(LOG_STATS, 0, "%5d steps taken", solverInfo->solverStats[0]);
      infoStreamPrint(LOG_STATS, 0, "%5d calls of functionODE", solverInfo->solverStats[1]);
      infoStreamPrint(LOG_STATS, 0, "%5d evaluations of jacobian", solverInfo->solverStats[2]);
      infoStreamPrint(LOG_STATS, 0, "%5d error test failures", solverInfo->solverStats[3]);
      infoStreamPrint(LOG_STATS, 0, "%5d convergence test failures", solverInfo->solverStats[4]);
      messageClose(LOG_STATS);
    }

    infoStreamPrint(LOG_STATS_V, 1, "function calls");
    if (omc_flag[FLAG_DAE_MODE])
    {
      infoStreamPrint(LOG_STATS_V, 0, "%5ld calls of functionDAE", data->simulationInfo->callStatistics.functionEvalDAE);
    }
    else
    {
      infoStreamPrint(LOG_STATS_V, 0, "%5ld calls of functionODE", data->simulationInfo->callStatistics.functionODE);
    }
    infoStreamPrint(LOG_STATS_V, 0, "%5ld calls of updateDiscreteSystem", data->simulationInfo->callStatistics.updateDiscreteSystem);
    infoStreamPrint(LOG_STATS_V, 0, "%5ld calls of functionZeroCrossingsEquations", data->simulationInfo->callStatistics.functionZeroCrossingsEquations);
    infoStreamPrint(LOG_STATS_V, 0, "%5ld calls of functionZeroCrossings", data->simulationInfo->callStatistics.functionZeroCrossings);
    messageClose(LOG_STATS_V);

    infoStreamPrint(LOG_STATS_V, 1, "linear systems");
    for(ui=0; ui<data->modelData->nLinearSystems; ui++)
      printLinearSystemSolvingStatistics(data, ui, LOG_STATS_V);
    messageClose(LOG_STATS_V);

    infoStreamPrint(LOG_STATS_V, 1, "non-linear systems");
    for(ui=0; ui<data->modelData->nNonLinearSystems; ui++)
      printNonLinearSystemSolvingStatistics(data, ui, LOG_STATS_V);
    messageClose(LOG_STATS_V);

    messageClose(LOG_STATS);
    rt_tick(SIM_TIMER_TOTAL);
  }

  TRACE_POP
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
 *  \param [in]  [solverID] selects the ode solver
 *  \param [in]  [outputVariablesAtEnd] ???
 *
 *  This is the main function of the solver, it performs the simulation.
 */
int solver_main(DATA* data, threadData_t *threadData, const char* init_initMethod, const char* init_file,
    double init_time, int lambda_steps, int solverID, const char* outputVariablesAtEnd, const char *argv_0)
{
  TRACE_PUSH

  int i, retVal = 0, initSolverInfo = 0;
  unsigned int ui;
  SOLVER_INFO solverInfo;
  SIMULATION_INFO *simInfo = data->simulationInfo;
  void *dllHandle=NULL;

  solverInfo.solverMethod = solverID;

  /* do some solver specific checks */
  switch(solverInfo.solverMethod)
  {
#ifndef WITH_SUNDIALS
  case S_RADAU1:
  case S_RADAU3:
  case S_RADAU5:
  case S_LOBATTO2:
  case S_LOBATTO4:
  case S_LOBATTO6:
    warningStreamPrint(LOG_STDOUT, 0, "Sundial/kinsol is needed but not available. Please choose other solver.");
    TRACE_POP
    return 1;
#endif

#ifndef WITH_IPOPT
  case S_OPTIMIZATION:
    warningStreamPrint(LOG_STDOUT, 0, "Ipopt is needed but not available.");
    TRACE_POP
    return 1;
#endif

  }

  /* first initialize the model then allocate SolverData memory
   * due to be able to use the initialized values for the integrator
   */
  simInfo->useStopTime = 1;

  /* if the given step size is too small redefine it */
  if ((simInfo->stepSize < MINIMAL_STEP_SIZE) && (simInfo->stopTime > 0)){
    warningStreamPrint(LOG_STDOUT, 0, "The step-size %g is too small. Adjust the step-size to %g.", simInfo->stepSize, MINIMAL_STEP_SIZE);
    simInfo->stepSize = MINIMAL_STEP_SIZE;
    simInfo->numSteps = round((simInfo->stopTime - simInfo->startTime)/simInfo->stepSize);
  }

  /*  initialize external input structure */
  externalInputallocate(data);
  /* set tolerance for ZeroCrossings */
  setZCtol(fmin(data->simulationInfo->stepSize, data->simulationInfo->tolerance));

  omc_alloc_interface.collect_a_little();
  /* initialize all parts of the model */
  retVal = initializeModel(data, threadData, init_initMethod, init_file, init_time, lambda_steps);
  omc_alloc_interface.collect_a_little();

  if(0 == retVal) {
    retVal = initializeSolverData(data, threadData, &solverInfo);
    initSolverInfo = 1;
  }

#if !defined(OMC_MINIMAL_RUNTIME)
  dllHandle = embedded_server_load_functions(omc_flagValue[FLAG_EMBEDDED_SERVER]);
  omc_real_time_sync_init(threadData, data);
  data->embeddedServerState = embedded_server_init(data, data->localData[0]->timeValue, solverInfo.currentStepSize, argv_0, omc_real_time_sync_update);
#endif
  if(0 == retVal) {
    /* if the model has no time changing variables skip the main loop*/
    if(data->modelData->nVariablesReal == 0    &&
       data->modelData->nVariablesInteger == 0 &&
       data->modelData->nVariablesBoolean == 0 &&
       data->modelData->nVariablesString == 0 ) {
      /* prevent emit if noeventemit flag is used */
      if (!(omc_flag[FLAG_NOEVENTEMIT])) {
        sim_result.emit(&sim_result, data, threadData);
      }

      infoStreamPrint(LOG_SOLVER, 0, "The model has no time changing variables, no integration will be performed.");
      solverInfo.currentTime = simInfo->stopTime;
      data->localData[0]->timeValue = simInfo->stopTime;
      overwriteOldSimulationData(data);
      finishSimulation(data, threadData, &solverInfo, outputVariablesAtEnd);
    } else if(S_QSS == solverInfo.solverMethod) {
      /* starts the simulation main loop - special solvers */
      sim_result.emit(&sim_result,data,threadData);

      /* overwrite the whole ring-buffer with initialized values */
      overwriteOldSimulationData(data);

      infoStreamPrint(LOG_SOLVER, 0, "Start numerical integration (startTime: %g, stopTime: %g)", simInfo->startTime, simInfo->stopTime);
      retVal = data->callback->performQSSSimulation(data, threadData, &solverInfo);
      omc_alloc_interface.collect_a_little();

      /* terminate the simulation */
      finishSimulation(data, threadData, &solverInfo, outputVariablesAtEnd);
      omc_alloc_interface.collect_a_little();
    } else {
      /* starts the simulation main loop - standard solver interface */
      if(solverInfo.solverMethod != S_OPTIMIZATION) {
        sim_result.emit(&sim_result,data,threadData);
      }

      /* overwrite the whole ring-buffer with initialized values */
      overwriteOldSimulationData(data);

      /* store all values for non-dassl event search */
      storeOldValues(data);

      infoStreamPrint(LOG_SOLVER, 0, "Start numerical solver from %g to %g", simInfo->startTime, simInfo->stopTime);
      retVal = data->callback->performSimulation(data, threadData, &solverInfo);
      omc_alloc_interface.collect_a_little();
      /* terminate the simulation */
      if (solverInfo.solverMethod == S_SYM_IMP_EULER) data->callback->symEulerUpdate(data, 0);
      finishSimulation(data, threadData, &solverInfo, outputVariablesAtEnd);
      omc_alloc_interface.collect_a_little();
    }
  }

  if (data->real_time_sync.enabled) {
    int tMaxLate=0;
    const char *unit = prettyPrintNanoSec(data->real_time_sync.maxLate, &tMaxLate);
    infoStreamPrint(LOG_RT, 0, "Maximum real-time latency was (positive=missed dealine, negative is slack): %d %s", tMaxLate, unit);
  }
#if !defined(OMC_MINIMAL_RUNTIME)
  embedded_server_deinit(data->embeddedServerState);
  embedded_server_unload_functions(dllHandle);
#endif
  /*  free external input data */
  externalInputFree(data);

  /* free SolverInfo memory */
  if (initSolverInfo)
  {
    freeSolverData(data, &solverInfo);
  }

  TRACE_POP
  return retVal;
}

/***************************************    EULER_EXP     *********************************/
static int euler_ex_step(DATA* data, SOLVER_INFO* solverInfo)
{
  int i;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  modelica_real* stateDer = sDataOld->realVars + data->modelData->nStates;

  solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;

  for(i = 0; i < data->modelData->nStates; i++)
  {
    sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
  }
  sData->timeValue = solverInfo->currentTime;

  /* save stats */
  /* steps */
  solverInfo->solverStatsTmp[0] += 1;
  /* function ODE evaluation is done directly after this function */
  solverInfo->solverStatsTmp[1] += 1;

  return 0;
}

/***************************************    SYM_EULER_IMP     *********************************/
static int sym_euler_im_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo){
  int retVal,i,j;
  /*time*/
  solverInfo->currentTime = data->localData[1]->timeValue + solverInfo->currentStepSize;
  data->localData[0]->timeValue = solverInfo->currentTime;
  /*update dt*/
  retVal = data->callback->symEulerUpdate(data, solverInfo->currentStepSize);
  if(retVal != 0){
    errorStreamPrint(LOG_STDOUT, 0, "Solver %s disabled on this configuration, set compiler flag +symEuler!", SOLVER_METHOD_NAME[solverInfo->solverMethod]);
    EXIT(0);
  }
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval alg equations, note ode is empty */
  data->callback->functionODE(data, threadData);
  /* update der(x)*/
  for(i=0, j=data->modelData->nStates; i<data->modelData->nStates; ++i, ++j)
    data->localData[0]->realVars[j] = (data->localData[0]->realVars[i]-data->localData[1]->realVars[i])/solverInfo->currentStepSize;

  /* save stats */
  /* steps */
  solverInfo->solverStatsTmp[0] += 1;
  /* function ODE evaluation is done directly after this */
  solverInfo->solverStatsTmp[1] += 1;
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

  solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;

  /* We calculate k[0] before returning from this function.
   * We only want to calculate f() 4 times per call */
  for(i = 0; i < data->modelData->nStates; i++)
  {
    k[0][i] = stateDerOld[i];
  }

  for (j = 1; j < rk->work_states_ndims; j++)
  {
    for(i = 0; i < data->modelData->nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + solverInfo->currentStepSize * rk->c[j] * k[j - 1][i];
    }
    sData->timeValue = sDataOld->timeValue + rk->c[j] * solverInfo->currentStepSize;
    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    /* eval ode equations */
    data->callback->functionODE(data, threadData);
    for(i = 0; i < data->modelData->nStates; i++)
    {
      k[j][i] = stateDer[i];
    }
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
  solverInfo->solverStatsTmp[0] += 1;
  /* function ODE evaluation is done directly after this */
  solverInfo->solverStatsTmp[1] += rk->work_states_ndims+1;

  return 0;
}

/***************************************    Run Ipopt for optimization     ***********************************/
#if defined(WITH_IPOPT)
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

#if defined(WITH_SUNDIALS) && !defined(OMC_MINIMAL_RUNTIME)
/***************************************    Radau/Lobatto     ***********************************/
int radau_lobatto_step(DATA* data, SOLVER_INFO* solverInfo)
{
  if(kinsolOde(solverInfo) == 0)
  {
    solverInfo->currentTime += solverInfo->currentStepSize;
    return 0;
  }
  return -1;
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
