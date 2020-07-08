/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Solver/FactoryExport.h>
#include <Core/Solver/SimulationMonitor.h>
/*_time_out(0)
   ,*/
SimulationMonitor::SimulationMonitor()
  :_time_out(0)
   ,_interrupt(false)
{
}

SimulationMonitor::~SimulationMonitor()
{
}

void SimulationMonitor::initialize()
{
   #ifdef USE_CHRONO
       _t_s = high_resolution_clock::now();
      _interrupt = false;
  #else
       throw ModelicaSimulationError(SOLVER,"simulation time out is only supported for c++11");
  #endif
}

void SimulationMonitor::setTimeOut(unsigned int time_out)
{
    #ifdef USE_CHRONO
      _time_out = seconds(time_out);
    #else
       throw ModelicaSimulationError(SOLVER,"simulation time out is only supported for c++11");
    #endif
}
void SimulationMonitor::stop()
{
  _interrupt =true;
}
void SimulationMonitor::checkTimeout()
{
  #ifdef USE_CHRONO
  high_resolution_clock::time_point t1 = high_resolution_clock::now();
  seconds elapsed = duration_cast<std::chrono::seconds>(t1 - _t_s);
  if ((_time_out > seconds(0)) && (elapsed >= _time_out))
  {
    _interrupt =true;
  }
  #else
       throw ModelicaSimulationError(SOLVER,"simulation time out is only supported for c++11");
  #endif

}
 /** @} */ // end of coreSolver
