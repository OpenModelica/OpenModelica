#pragma once

/**
Auxiliary  class to handle system events
Implements the Modelica pre,edge,change operators
Holds a help vector for the discrete variables
Holds an event queue to handle all events occured at the same time
*/

class ContinuousEvents;
class DiscreteEvents;
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
boost::shared_ptr<ContinuousEvents> _continuousEvents;

};
