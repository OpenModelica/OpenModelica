#include "Modelica.h"
#include "FactoryExport.h"
#include <Solver/SimulationMonitor.h>

SimulationMonitor::SimulationMonitor()
:/*_time_out(0)
,*/_interrupt(false)
{


}


SimulationMonitor::~SimulationMonitor()
{
}

void SimulationMonitor::initialize()
{
  /*_timer = cpu_timer();*/
  _interrupt =false;
}
void SimulationMonitor::setTimeOut(unsigned int time_out)
{
  /*_time_out = nanosecond_type(time_out* 1000000000LL);*/
}
 void SimulationMonitor::checkTimeout()
 {
   /* cpu_times  elapsed_times(_timer.elapsed());
    nanosecond_type elapsed(elapsed_times.system  + elapsed_times.user);
    if (elapsed >= _time_out)
    {
      _interrupt =true;
    }
 */
 }

