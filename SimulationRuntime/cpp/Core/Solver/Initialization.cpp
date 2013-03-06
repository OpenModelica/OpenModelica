#include "stdafx.h"
#include  <Solver/Initialization.h>
#include  <System/IMixedSystem.h>

Initialization::Initialization(ISystemInitialization* system_initialization)
:_system(system_initialization)
{
}


Initialization::~Initialization(void)
{
}
void Initialization::initializeSystem(double start_time, double end_time)
{
    IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
    IEvent* event_system = dynamic_cast<IEvent*>(_system);
      IMixedSystem* mixed_system = dynamic_cast<IMixedSystem*>(_system);
    //Initialization of continous equations and bounded parameters
    _system->init(start_time,end_time);

    //Intialization of discrete equations
    _system->setInitial(true);
   bool restart=true;
   int iter=0;

   while(restart && !(iter++ > 10))
   {

     continous_system->update(IContinuous::ALL);
      restart = event_system->checkForDiscreteEvents();
   }

   mixed_system->saveAll();
    event_system->checkConditions(0,true);
  _system->setInitial(false);

}
