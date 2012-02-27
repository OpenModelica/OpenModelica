#include "stdafx.h"
#include "Initialization.h"


Initialization::Initialization(ISystemInitialization* system_initialization)
:_system(system_initialization)
{
}


Initialization::~Initialization(void)
{
}
void Initialization::initializeSystem(double start_time, double end_time)
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	IEvent* event_system = dynamic_cast<IEvent*>(_system);
	
	//Initialization of continous equations and bounded parameters
	_system->init(start_time,end_time);
  
	//Intialization of discrete equations 
	_system->setInitial(true);
   bool restart=true;
   int iter=0;
  
   while(restart && !(iter++ > 10))
   {
	
     continous_system->update(IContinous::ALL);
	  restart = event_system->checkForDiscreteEvents();
   }

   event_system->saveAll();
    event_system->checkConditions(0,true);
	 event_system->saveConditions();
  _system->setInitial(false);

}