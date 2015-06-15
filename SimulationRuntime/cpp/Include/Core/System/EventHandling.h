#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
/**
Auxiliary  class to handle system events
Implements the Modelica pre,edge,change operators
Holds a help vector for the discrete variables
Holds an event queue to handle all events occured at the same time
*/

class ContinuousEvents;
class DiscreteEvents;
/*
#ifdef RUNTIME_STATIC_LINKING
class EventHandling
#else*/
class BOOST_EXTENSION_EVENTHANDLING_DECL EventHandling
/*#endif*/
{
public:
  EventHandling();
  virtual ~EventHandling(void);
  //Inits the event variables
   boost::shared_ptr<DiscreteEvents> initialize(IEvent* system,boost::shared_ptr<ISimVars> sim_vars);


  //saves a variable in _pre_vars vector
  bool startEventIteration(bool& state_vars_reinitialized);

private:
boost::shared_ptr<ContinuousEvents> _continuousEvents;

};
/** @} */ // end of coreSystem