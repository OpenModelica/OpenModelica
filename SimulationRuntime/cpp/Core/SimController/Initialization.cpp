#include "stdafx.h"
#include  "Initialization.h"


Initialization::Initialization(boost::shared_ptr<ISystemInitialization> system_initialization)
:_system(system_initialization)
{
}


Initialization::~Initialization(void)
{
}
void Initialization::initializeSystem()
{
    boost::shared_ptr<IContinuous> continous_system = boost::dynamic_pointer_cast<IContinuous>(_system);
    boost::shared_ptr<IEvent> event_system =boost::dynamic_pointer_cast<IEvent>(_system);
      boost::shared_ptr<IMixedSystem> mixed_system = boost::dynamic_pointer_cast<IMixedSystem>(_system);
    //Initialization of continous equations and bounded parameters
    _system->initialize();
  
    //Intialization of discrete equations 
    _system->setInitial(true);
   bool restart=true;
   int iter=0;
  bool cond_restart = true;
   while((restart /*|| cond_restart*/) && !(iter++ > 15))
   {
    
     continous_system->evaluate(IContinuous::ALL);    // vxworksupdate
      restart = event_system->checkForDiscreteEvents();
      cond_restart = event_system->checkConditions(NULL,true);
   }

   mixed_system->saveAll();
    event_system->checkConditions(0,true);
  _system->setInitial(false);

}