#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
/*
#ifdef RUNTIME_STATIC_LINKING
class ContinuousEvents
#else*/
class BOOST_EXTENSION_EVENTHANDLING_DECL ContinuousEvents
/*#endif*/
{
public:
  ContinuousEvents();
  virtual ~ContinuousEvents(void);
  //Inits the event variables
  void initialize(IEvent* system);
  bool startEventIteration(bool& state_vars_reinitialized);

private:
  IEvent* _event_system;
  event_times_type _time_events;
  IContinuous* _countinous_system; //just a cast of _event_system -> required in IterateEventQueue
  IMixedSystem* _mixed_system; //just a cast of _event_system -> required in IterateEventQueue
  bool* _conditions0;
  bool* _conditions1;
  bool* _clockconditions0;
  bool* _clockconditions1;
};
/** @} */ // end of coreSystem