#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */
#if defined(__vxworks) || defined (__TRICORE__)
#define BOOST_EXTENSION_MONITOR_DECL
#endif
/*
#ifdef RUNTIME_STATIC_LINKING
class SimulationMonitor
#else
*/
class BOOST_EXTENSION_MONITOR_DECL SimulationMonitor
/*#endif*/
{
public:
  SimulationMonitor();
  ~SimulationMonitor();
  void initialize();
  void setTimeOut(unsigned int time_out);
  void stop();
  void checkTimeout();

protected:
  /*nanosecond_type _time_out;*/
  bool _interrupt;
  /*cpu_timer _timer;*/
};
 /** @} */ // end of coreSolver
