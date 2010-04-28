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
		STOPPED
	};
};

extern SimulationStatus::type simulationStatus;
extern Mutex* mutexSimulationStatus;
extern Semaphore* waitForResume;

THREAD_RET_TYPE threadServerControl(THREAD_PARAM_TYPE);

//****** Network Configuration ******
void setControlClientIPandPort(std::string, int);
void resetControlClientIPandPortToDefault(void);
void setControlServerPort(int);
void resetControlServerPortToDefault(void);
