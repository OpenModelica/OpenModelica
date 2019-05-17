/** @addtogroup coreSimcontroller
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/Initialization.h>

Initialization::Initialization(shared_ptr<ISystemInitialization> system_initialization, shared_ptr<ISolver> solver)
  : _system(system_initialization)
  , _solver(solver)
{
}

Initialization::~Initialization(void)
{
}

void Initialization::initializeSystem()
{
  shared_ptr<IContinuous> continous_system = dynamic_pointer_cast<IContinuous>(_system);
  shared_ptr<IEvent> event_system = dynamic_pointer_cast<IEvent>(_system);
  shared_ptr<IMixedSystem> mixed_system = dynamic_pointer_cast<IMixedSystem>(_system);
  shared_ptr<IStepEvent> step_event_system = dynamic_pointer_cast<IStepEvent>(_system);
  int dim = event_system->getDimZeroFunc();
  bool* conditions0 = new bool[dim];
  bool* conditions1 = new bool[dim];

  _system->setInitial(true);
  //Initialization of continous equations and bounded parameters

  _system->initialize();
  _solver->stateSelection();
  /*deactivated initialization loop*/
  //bool restart = true;
  //int iter = 0;
  //bool cond_restart = true;
  //while((restart /*|| cond_restart*/) && !(iter++ > 15))
  //{
  //  event_system->getConditions(conditions0);
  //  _system->initEquations();    // vxworksupdate
  //  restart = event_system->checkForDiscreteEvents();
  //  event_system->getConditions(conditions1);
  //  //Deactivated: event_system->saveDiscreteVars();
  //  event_system->saveAll();

  //  cond_restart = !std::equal (conditions1, conditions1+dim, conditions0);
  //}

  event_system->saveAll();
  _system->setInitial(false);

  if( _solver->stateSelection())
  {
    _system->initEquations();
	step_event_system->stepCompleted(0.0);


    /* report a warning about strange start values */
    if(_solver->stateSelection())
      cout << "Cannot initialize the dynamic state selection in an unique way." << std::endl;
  }
  delete[] conditions0;
  delete[] conditions1;
}
/** @} */ // end of coreSimcontroller