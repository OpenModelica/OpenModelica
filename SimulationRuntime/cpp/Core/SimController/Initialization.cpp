/** @addtogroup coreSimcontroller
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/Initialization.h>

Initialization::Initialization(boost::shared_ptr<ISystemInitialization> system_initialization, boost::shared_ptr<ISolver> solver)
  : _system(system_initialization)
  , _solver(solver)
{
}

Initialization::~Initialization(void)
{
}

void Initialization::initializeSystem()
{
  boost::shared_ptr<IContinuous> continous_system = boost::dynamic_pointer_cast<IContinuous>(_system);
  boost::shared_ptr<IEvent> event_system = boost::dynamic_pointer_cast<IEvent>(_system);
  boost::shared_ptr<IMixedSystem> mixed_system = boost::dynamic_pointer_cast<IMixedSystem>(_system);
  int dim = event_system->getDimZeroFunc();
  bool* conditions0 = new bool[dim];
  bool* conditions1 = new bool[dim];

  _system->setInitial(true);
  //Initialization of continous equations and bounded parameters

  _system->initialize();
  _solver->stateSelection();
  bool restart = true;
  int iter = 0;
  bool cond_restart = true;
  while((restart /*|| cond_restart*/) && !(iter++ > 15))
  {
    event_system->getConditions(conditions0);
    _system->initEquations();    // vxworksupdate
    restart = event_system->checkForDiscreteEvents();
    event_system->getConditions(conditions1);
    //Deactivated: event_system->saveDiscreteVars();
    event_system->saveAll();

    cond_restart = !std::equal (conditions1, conditions1+dim, conditions0);
  }

  event_system->saveAll();
  _system->setInitial(false);

  if( _solver->stateSelection())
  {
    _system->initEquations();

    /* report a warning about strange start values */
    if(_solver->stateSelection())
      cout << "Cannot initialize the dynamic state selection in an unique way." << std::endl;
  }
  delete[] conditions0;
  delete[] conditions1;
}
/** @} */ // end of coreSimcontroller