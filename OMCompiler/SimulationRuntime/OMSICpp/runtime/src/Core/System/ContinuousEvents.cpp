/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/ContinuousEvents.h>
#include <Core/Math/Functions.h>
#include <Core/Utils/extension/logger.hpp>

ContinuousEvents::ContinuousEvents()
: _event_system(NULL)
, _countinous_system(NULL)
, _mixed_system(NULL)
, _conditions0(NULL)
, _conditions1(NULL)
,_clockconditions0(NULL)
,_clockconditions1(NULL)

{
}

ContinuousEvents::~ContinuousEvents(void)
{

  if(_conditions0)
    delete[] _conditions0;
  if(_conditions1)
    delete[] _conditions1;


  if(_clockconditions0)
    delete[] _clockconditions0;
  if(_clockconditions1)
    delete[] _clockconditions1;


}

/**
Inits the event variables
*/
void ContinuousEvents::initialize(IEvent* system)
{
  // _dimH=dim;
  _event_system=system;
    unsigned int dimZero = _event_system->getDimZeroFunc();
   unsigned int dimClock = _event_system->getDimClock();

  _countinous_system = dynamic_cast<IContinuous*>(_event_system);
  _mixed_system= dynamic_cast<IMixedSystem*>(_event_system);


  if(_conditions0)
    delete[] _conditions0;
  if(_conditions1)
    delete[] _conditions1;

  if(_clockconditions0)
    delete[] _clockconditions0;
  if(_clockconditions1)
    delete[] _clockconditions1;

   if(dimZero> 0)
  {
	_conditions0 = new bool[_event_system->getDimZeroFunc()];
	_conditions1 = new bool[_event_system->getDimZeroFunc()];
  }
  if(dimClock > 0)
  {
	_clockconditions0 = new bool[_event_system->getDimClock()];
	_clockconditions1 = new bool[_event_system->getDimClock()];
  }
}



/**
Handles all events occurred a the same time.
*/
bool ContinuousEvents::startEventIteration(bool& state_vars_reinitialized)
{
  //save discrete variables
  //Deactivated: _event_system->saveDiscreteVars(); // store values of discrete vars vor next check

  unsigned int dim = _event_system->getDimZeroFunc();
  //unsigned int dimClock = _event_system->getDimClock();

  _event_system->getConditions(_conditions0);
  //_event_system->getClockConditions(_clockconditions0);

  //Handle all events
  bool assert = false;
  bool drestart = false;
  bool crestart = false;
  try
  {

	  state_vars_reinitialized = _countinous_system->evaluateConditions();


	  //check if discrete variables changed
	   drestart = _event_system->checkForDiscreteEvents(); //discrete time conditions

	  _event_system->getConditions(_conditions1);
	  //_event_system->getClockConditions(_clockconditions1);

	  if (dim > 0)
	  {
		  LOGGER_WRITE_VECTOR("conditions", _conditions1, dim, LC_EVENTS, LL_DEBUG);
		  crestart = !std::equal(_conditions1, _conditions1 + dim, _conditions0);
	  }
  }
  catch (std::exception& ex)
  {

	 // if  evaluateConditions throws and error during event iteration the event iteration will restarted
	  assert = true;
  }
  return(drestart || crestart || assert); //returns true if new events occurred
}

