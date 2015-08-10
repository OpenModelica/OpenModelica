/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/ContinuousEvents.h>
#include <Core/Math/Functions.h>


ContinuousEvents::ContinuousEvents() : _event_system(NULL), _countinous_system(NULL), _mixed_system(NULL), _conditions0(NULL), _conditions1(NULL)
{
}

ContinuousEvents::~ContinuousEvents(void)
{

  if(_conditions0)
    delete[] _conditions0;
  if(_conditions1)
    delete[] _conditions1;
}

/**
Inits the event variables
*/
void ContinuousEvents::initialize(IEvent* system)
{
  // _dimH=dim;
  _event_system=system;
  _countinous_system = dynamic_cast<IContinuous*>(_event_system);
  _mixed_system= dynamic_cast<IMixedSystem*>(_event_system);


  if(_conditions0)
    delete[] _conditions0;
  if(_conditions1)
    delete[] _conditions1;

  _conditions0 = new bool[_event_system->getDimZeroFunc()];
  _conditions1 = new bool[_event_system->getDimZeroFunc()];
}



/**
Handles all events occurred a the same time.
*/
bool ContinuousEvents::startEventIteration(bool& state_vars_reinitialized)
{
  //save discrete variables
  //Deactivated: _event_system->saveDiscreteVars(); // store values of discrete vars vor next check

  unsigned int dim = _event_system->getDimZeroFunc();

  _event_system->getConditions(_conditions0);
  //Handle all events

  state_vars_reinitialized = _countinous_system->evaluateConditions();


  //check if discrete variables changed
  bool drestart= _event_system->checkForDiscreteEvents(); //discrete time conditions


  _event_system->getConditions(_conditions1);
  bool crestart = !std::equal (_conditions1, _conditions1+dim,_conditions0);

  return((drestart||crestart)); //returns true if new events occurred
}
/** @} */ // end of coreSystem
/*
bool ContinuousEvents::checkConditions(const bool* events, bool all)
{
IEvent* event_system= dynamic_cast<IEvent*>(_system);
int dim = event_system->getDimZeroFunc();
bool* conditions0 = new bool[dim];
bool* conditions1 = new bool[dim];
event_system->getConditions(conditions0);

for(int i=0;i<dim;i++)
{
if(all||events[i])
getCondition(i);
}
event_system->getConditions(conditions1);
return !std::equal (conditions1, conditions1+dim,conditions0);

}
*/

