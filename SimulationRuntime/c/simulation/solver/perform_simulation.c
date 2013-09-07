/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */



#include "solver_main.h"
#include "events.h"
#include "dassl.h"

#include "simulation_runtime.h"
#include "simulation_result.h"
#include "openmodelica_func.h"

/*
 * #include "dopri45.h"
 */
#include "omc_error.h"
#include <math.h>
#include <string.h>
#include <errno.h>
#include <float.h>




/*! \fn updateContinuousSystem
 *
 *  Function to update the whole system with EventIteration.
 *  Evaluate the functionDAE()
 *
 *  \param [ref] [data]
 */
void updateContinuousSystem(DATA *data)
{
  input_function(data);
  functionODE(data);
  functionAlgebraics(data);
  output_function(data);
  function_storeDelayed(data);
  storePreValues(data);
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
  int i, ui, eventType, retry = 0;

  FILE *fmt = NULL;
  unsigned int stepNo = 0;
  state mem_state;
  double oldStepSize;

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

  printAllVarsDebug(data, 0, LOG_DEBUG); /* ??? */

  /***** Start main simulation loop *****/
  while(solverInfo->currentTime < simInfo->stopTime)
  {
    mem_state = get_memory_state();
    currectJumpState = ERROR_SIMULATION;
    /* try */
    if(!setjmp(simulationJmpbuf))
    {
      if(measure_time_flag)
      {
        for(i = 0; i < data->modelData.modelDataXml.nFunctions + data->modelData.modelDataXml.nProfileBlocks; i++)
        {
          rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
        }
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
      } else {
        solverInfo->offset = 0;
      }
      solverInfo->currentStepSize = simInfo->stepSize - solverInfo->offset;

      /* adjust final step? */
      if(solverInfo->currentTime + solverInfo->currentStepSize > simInfo->stopTime) {
        solverInfo->currentStepSize = simInfo->stopTime - solverInfo->currentTime;
      }
      /***** End calculation next step size *****/

      /* check for next time event */
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
      if(solverInfo->solverMethod == S_OPTIMIZATION) 
        return 0;
      updateContinuousSystem(data);
      saveZeroCrossings(data);
      RELEASE(LOG_SOLVER);


      /***** Event handling *****/
      if(measure_time_flag)
        rt_tick(SIM_TIMER_EVENT);

      eventType = checkEvents(data, solverInfo->eventLst, &(solverInfo->currentTime), solverInfo);
      if(eventType > 0)
      {
        currectJumpState = ERROR_EVENTSEARCH;
        INFO2(LOG_EVENTS, "%s event at time %g", eventType == 1 ? "time" : "state", solverInfo->currentTime);
        INDENT(LOG_EVENTS);
        handleEvents(data, solverInfo->eventLst, &(solverInfo->currentTime), solverInfo);
        RELEASE(LOG_EVENTS);
        currectJumpState = ERROR_SIMULATION;

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
      if(stateSelection(data, 1, 1))
      {
        /* if new set is calculated reinit the solver */
        solverInfo->didEventStep = 1;
        overwriteOldSimulationData(data);
      }

      /* Check for warning of variables out of range assert(min<x || x>xmax, ...)*/
      checkForAsserts(data);

      restore_memory_state(mem_state);

      if(retry)
      {
        solverInfo->offset = simInfo->stepSize - oldStepSize;
        simInfo->stepSize = oldStepSize;
        retry = 0;
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

      printAllVarsDebug(data, 0, LOG_DEBUG);  /* ??? */

      /***** end of Emit this time step *****/

      /* save dassl stats before reset */
      if(solverInfo->didEventStep == 1 && solverInfo->solverMethod == 3)
      {
        for(ui = 0; ui < numStatistics; ui++)
          ((DASSL_DATA*)solverInfo->solverData)->dasslStatistics[ui] += ((DASSL_DATA*)solverInfo->solverData)->dasslStatisticsTmp[ui];
      }

      /* Check if terminate()=true */
      if(terminationTerminate)
      {
        printInfo(stdout, TermInfo);
        fputc('\n', stdout);
        INFO2(LOG_STDOUT, "Simulation call terminate() at time %f\nMessage : %s", data->localData[0]->timeValue, TermMsg);
        simInfo->stopTime = solverInfo->currentTime;
      }

      /* terminate for some cases:
       * - integrator fails
       * - non-linear system failed to solve
       * - assert was called
       */
      if( retValIntegrator != 0
          || check_nonlinear_solutions(data, 0)
          || check_linear_solutions(data, 0)
          || check_mixed_solutions(data, 0)
          )
      {
        if(retValIntegrator)
        {
          retValue = -1 + retValIntegrator;
          INFO1(LOG_STDOUT, "model terminate | Integrator failed. | Simulation terminated at time %g", solverInfo->currentTime);
        }
        else if(check_nonlinear_solutions(data, 0))
        {
          retValue = -2;
          INFO1(LOG_STDOUT, "model terminate | non-linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
        }
        else if(check_linear_solutions(data, 0))
        {
          retValue = -3;
          INFO1(LOG_STDOUT, "model terminate | linear system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
        }
        else if(check_mixed_solutions(data, 0))
        {
          retValue = -3;
          INFO1(LOG_STDOUT, "model terminate | mixed system solver failed. | Simulation terminated at time %g", solverInfo->currentTime);
        }
        else
        {
          retValue = -1;
          INFO1(LOG_STDOUT, "model terminate | probably a strong component solver failed. For more information use flags -lv LOG_NLS, LOG_LS. | Simulation terminated at time %g", solverInfo->currentTime);
        }
        break;
      }
    }
    else
    { /* catch */
      if(!retry)
      {
        restore_memory_state(mem_state);

        /* reduce step size by a half and try again */
        solverInfo->laststep = solverInfo->currentTime - solverInfo->laststep;
        oldStepSize = simInfo->stepSize;
        simInfo->stepSize /= 2;

        /* restore old values and try another step with smaller step-size by dassl*/
        restoreOldValues(data);
        solverInfo->currentTime = data->localData[0]->timeValue;
        overwriteOldSimulationData(data);
        WARNING(LOG_STDOUT, "Integrator attempt to handle a problem with a called assert.");
        retry = 1;
        solverInfo->didEventStep = 1;
        RELEASE(LOG_SOLVER);
      }
      else
      {
        retValue =  -1;
        INFO1(LOG_STDOUT, "model terminate | Simulation terminated by an assert at time: %g", data->localData[0]->timeValue);
        break;
      }
    }
  } /* end while solver */

  if(fmt)
    fclose(fmt);

  return retValue;
}
