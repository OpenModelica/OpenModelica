/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

// Simulate.h : Deklaration von CSimulate

#pragma once


#include <Core/SimController/SimManager.h>
#include <Core/SimController/threading/Communicator.h>
#include <Core/SimController/threading/Runnable.h>


	/**
	Klasse für Simulations- Thread
	*/
	class SimulationThread : public Runnable
	{

	public:
		SimulationThread(Communicator* communicator);
        ~SimulationThread(void);
		//void setSimManager(shared_ptr<SimManager> simManager, shared_ptr<IGlobalSettings> global_settings, shared_ptr<IMixedSystem> system);
		void Run(shared_ptr<SimManager> simManager, shared_ptr<IGlobalSettings> global_settings, shared_ptr<IMixedSystem> system, shared_ptr<ISimObjects> sim_objects, string modelKey);
        virtual void Stop();
	private:
		///Manager für Simulation zum Starten der Simulation
        shared_ptr<SimManager> _simManager;
        Communicator* _communicator;
      
	};

