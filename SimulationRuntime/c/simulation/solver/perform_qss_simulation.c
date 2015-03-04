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

#include "simulation/simulation_runtime.h"
#include "simulation/results/simulation_result.h"
#include "openmodelica_func.h"

#include "util/omc_error.h"
#include "simulation/options.h"

static int qss_step(DATA* data, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH

  int i;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  modelica_real* stateDer = sDataOld->realVars + data->modelData.nStates;
  SIMULATION_INFO *simInfo = &(data->simulationInfo);

  infoStreamPrint(LOG_SOLVER, 1, "call solver from %g to %g (stepSize: %.15g)", solverInfo->currentTime, solverInfo->currentTime + solverInfo->currentStepSize, solverInfo->currentStepSize);

  /* calculate states */
  /* TODO: use QSS solver instead of euler method */
  solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
  for(i = 0; i < data->modelData.nStates; i++)
  {
    sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
  }
  sData->timeValue = solverInfo->currentTime;
  solverInfo->laststep = solverInfo->currentTime;

  /* update continous system */
  externalInputUpdate(data);
  data->callback->input_function(data);
  data->callback->functionODE(data);
  data->callback->functionAlgebraics(data);
  data->callback->output_function(data);
  data->callback->function_storeDelayed(data);

  messageClose(LOG_SOLVER);

  TRACE_POP
  return 0;
}

/*! \fn performQSSSimulation(DATA* data, SOLVER_INFO* solverInfo)
 *
 *  \param [ref] [data]
 *  \param [ref] [solverInfo]
 *
 *  This function performs the simulation controlled by solverInfo.
 */
int prefixedName_performQSSSimulation(DATA* data, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH

  SIMULATION_INFO *simInfo = &(data->simulationInfo);
  unsigned int currStepNo = 0;
  int retValIntegrator = 0;
  int retValue = 0;

  solverInfo->currentTime = simInfo->startTime;

  warningStreamPrint(LOG_STDOUT, 0, "This QSS method is under development and should not be used yet.");

  if (data->callback->initialAnalyticJacobianA(data))
  {
    if(data->modelData.nStates == 1) /* TODO: is it the dummy state? */
    {
      infoStreamPrint(LOG_SOLVER, 0, "No SparsePattern, since there are no states! Switch back to normal.");
    }
    else
    {
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
    }
  }
  printSparseStructure(data, LOG_SOLVER);

  /***** Start main simulation loop *****/
  while(solverInfo->currentTime < simInfo->stopTime)
  {
    int success = 0;
    threadData->currentErrorStage = ERROR_SIMULATION;
    omc_alloc_interface.collect_a_little();

#if !defined(OMC_EMCC)
    /* try */
    MMC_TRY_INTERNAL(simulationJumpBuffer)
    {
#endif

#ifdef USE_DEBUG_TRACE
    if(useStream[LOG_TRACE])
      printf("TRACE: push loop step=%u, time=%.12g\n", currStepNo, solverInfo->currentTime);
#endif

    rotateRingBuffer(data->simulationData, 1, (void**) data->localData);

    currStepNo++;
    solverInfo->currentStepSize = (double)(currStepNo*(simInfo->stopTime-simInfo->startTime))/(simInfo->numSteps) + simInfo->startTime - solverInfo->currentTime;

    if(0 != strcmp("ia", MMC_STRINGDATA(data->simulationInfo.outputFormat)))
    {
      communicateStatus("Running", (solverInfo->currentTime-simInfo->startTime)/(simInfo->stopTime-simInfo->startTime));
    }

    retValIntegrator = qss_step(data, solverInfo);

    sim_result.emit(&sim_result, data);

    /* check if terminate()=true */
    if(terminationTerminate)
    {
      printInfo(stdout, TermInfo);
      fputc('\n', stdout);
      infoStreamPrint(LOG_STDOUT, 0, "Simulation call terminate() at time %f\nMessage : %s", data->localData[0]->timeValue, TermMsg);
      simInfo->stopTime = solverInfo->currentTime;
    }

    /* terminate for some cases:
     * - integrator fails
     * - non-linear system failed to solve
     * - assert was called
     */
    if(retValIntegrator)
    {
      retValue = -1 + retValIntegrator;
      infoStreamPrint(LOG_STDOUT, 0, "model terminate | Integrator failed. | Simulation terminated at time %g", solverInfo->currentTime);
      break;
    }
    else if(check_nonlinear_solutions(data, 0))
    {
      retValue = -2;
      infoStreamPrint(LOG_STDOUT, 0, "model terminate | non-linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
      break;
    }
    else if(check_linear_solutions(data, 0))
    {
      retValue = -3;
      infoStreamPrint(LOG_STDOUT, 0, "model terminate | linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
      break;
    }
    else if(check_mixed_solutions(data, 0))
    {
      retValue = -4;
      infoStreamPrint(LOG_STDOUT, 0, "model terminate | mixed system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
      break;
    }
    success = 1;
#if !defined(OMC_EMCC)
    }
    /* catch */
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
    if (!success)
    {
      retValue =  -1;
      infoStreamPrint(LOG_STDOUT, 0, "model terminate | Simulation terminated by an assert at time: %g", data->localData[0]->timeValue);
      break;
    }

    TRACE_POP /* pop loop */
  }

  TRACE_POP
  return retValue;
}
