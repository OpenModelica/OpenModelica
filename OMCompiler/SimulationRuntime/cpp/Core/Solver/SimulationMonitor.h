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
  ///sets time out in seconds
  void setTimeOut(unsigned int time_out);
  void stop();
  void checkTimeout();

protected:
  #ifdef USE_CHRONO
   seconds _time_out;
   bool _interrupt;
   high_resolution_clock::time_point _t_s;
  #endif
};
 /** @} */ // end of coreSolver
