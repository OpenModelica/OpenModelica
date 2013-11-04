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
    int dim = event_system->getDimZeroFunc();
    bool* conditions0 = new bool[dim];
    bool* conditions1 = new bool[dim];
   
    _system->setInitial(true);
  //Initialization of continous equations and bounded parameters
    _system->initialize();
    bool restart=true;
   int iter=0;
  bool cond_restart = true;
   while((restart /*|| cond_restart*/) && !(iter++ > 15))
   {
    event_system->getConditions(conditions0);
    _system->initEquations();    // vxworksupdate
    restart = event_system->checkForDiscreteEvents();
    event_system->getConditions(conditions1);
    event_system->saveDiscreteVars();
    cond_restart = !std::equal (conditions1, conditions1+dim,conditions0);
   }

   mixed_system->saveAll();
   _system->setInitial(false);

}