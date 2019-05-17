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

