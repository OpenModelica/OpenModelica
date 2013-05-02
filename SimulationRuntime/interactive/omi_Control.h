/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 3. October 2009
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: omi_Control.h
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <string>
#include "thread.h"

//#ifndef _MY_SIMULATIONCONTROL_H
#define _MY_SIMULATIONCONTROL_H

struct SimulationStatus
{
  enum type
  {
   RUNNING,
   PAUSED,
   STOPPED,
   SHUTDOWN
  };
};

extern SimulationStatus::type simulationStatus;
extern Mutex* mutexSimulationStatus;
/*
 * The waitForResume Semaphore signals to the calculation and the transfer thread to start/go-on there process
 * The threads will organize there running or waiting using this semaphore. If the status of the simulation has been changed to
 * pause there won't increase the semaphore so they have to wait. The start method of control will increase the semaphore again
 */
extern Semaphore* waitForResume;

THREAD_RET_TYPE threadServerControl(THREAD_PARAM_TYPE);

//****** Network Configuration ******
void setControlClientIPandPort(std::string, int);
void resetControlClientIPandPortToDefault(void);
void setControlServerPort(int);
void resetControlServerPortToDefault(void);
