#include <Core/Modelica.h>
#include "FactoryExport.h"
#include <Core/System/IEvent.h>
#include <Core/System/EventHandling.h>
#include <Core/Math/Functions.h>

/**
Constructor
\param system Modelica system object
\param dim Dimenson of help variables
*/
EventHandling::EventHandling()
{
}

EventHandling::~EventHandling(void)
{
  
 
}

/**
Inits the event variables
*/
boost::shared_ptr<DiscreteEvents> EventHandling::initialize(IEvent* event_system)
{
  //initialize prevars
  //event_system->initPreVariables(preVars->_pre_real_vars_idx,preVars->_pre_int_vars_idx,preVars->_pre_bool_vars_idx);
  //preVars->_pre_vars.resize((boost::extents[preVars->_pre_real_vars_idx.size()+preVars->_pre_int_vars_idx.size()+preVars->_pre_bool_vars_idx.size()]));
  //initialize discrete event handling
  PreVariables* preVars = dynamic_cast<PreVariables*>(event_system);
  boost::shared_ptr<DiscreteEvents> discreteEvents = boost::shared_ptr<DiscreteEvents>(new DiscreteEvents(preVars));
  discreteEvents->initialize();
  //initialize continuous event handling
  _continuousEvents.initialize(event_system);
  return discreteEvents;
}




bool EventHandling::startEventIteration(bool& state_vars_reinitialized)
{
   return _continuousEvents.startEventIteration(state_vars_reinitialized);
}



