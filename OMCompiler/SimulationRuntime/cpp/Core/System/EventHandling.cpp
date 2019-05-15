/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/ContinuousEvents.h>
#include <Core/System/DiscreteEvents.h>
#include <Core/System/EventHandling.h>

/**
Constructor
\param system Modelica system object
\param dim Dimenson of help variables
*/
EventHandling::EventHandling()
{
  _continuousEvents =  shared_ptr<ContinuousEvents>(new ContinuousEvents());
}

EventHandling::EventHandling(EventHandling& instance)
{
  _continuousEvents =  shared_ptr<ContinuousEvents>(new ContinuousEvents());
}

EventHandling::~EventHandling(void)
{
}

/**
Inits the event variables
*/
shared_ptr<DiscreteEvents> EventHandling::initialize(IEvent* event_system,shared_ptr<ISimVars> sim_vars)
{

  shared_ptr<DiscreteEvents> discreteEvents = shared_ptr<DiscreteEvents>(new DiscreteEvents(sim_vars));
  discreteEvents->initialize();
  //initialize continuous event handling
  _continuousEvents->initialize(event_system);
  return discreteEvents;
}




bool EventHandling::startEventIteration(bool& state_vars_reinitialized)
{
   return _continuousEvents->startEventIteration(state_vars_reinitialized);
}

/** @} */ // end of coreSystem

