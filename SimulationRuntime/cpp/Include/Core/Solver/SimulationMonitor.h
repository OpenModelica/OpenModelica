#pragma once

#if defined(__vxworks)
#define BOOST_EXTENSION_MONITOR_DECL
#endif

class BOOST_EXTENSION_MONITOR_DECL SimulationMonitor
{
public:
  SimulationMonitor();
  ~SimulationMonitor();
   void initialize();
   void setTimeOut(unsigned int time_out);
   void checkTimeout();
 protected:
     /*nanosecond_type _time_out;*/

     bool _interrupt;
     /*cpu_timer _timer;*/

};
