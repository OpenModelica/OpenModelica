#pragma once

/**
Auxiliary  class to handle system events
Implements the Modelica pre,edge,change operators
Holds a help vector for the discrete variables
Holds an event queue to handle all events occured at the same time
*/
#include <Core/System/PreVariables.h>
#include <Core/System/DiscreteEvents.h>
#include <Core/System/ContinuousEvents.h>

class BOOST_EXTENSION_EVENTHANDLING_DECL EventHandling
{
public:
  EventHandling();
  virtual ~EventHandling(void);
  //Inits the event variables
   boost::shared_ptr<DiscreteEvents> initialize(IEvent* system);


  //saves a variable in _pre_vars vector
  bool startEventIteration(bool& state_vars_reinitialized);

private:
ContinuousEvents _continuousEvents;

};
