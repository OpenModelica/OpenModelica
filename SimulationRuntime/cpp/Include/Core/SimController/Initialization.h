#pragma once
/** @addtogroup coreSimcontroller
 *  
 *  @{
 */
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <Core/System/ISystemInitialization.h>
#endif
*/
class Initialization
{
public:
  Initialization(boost::shared_ptr<ISystemInitialization> system_initialization, boost::shared_ptr<ISolver>);
  ~Initialization(void);
  void initializeSystem(/*double start_time, double end_time*/);

private:
  boost::shared_ptr<ISystemInitialization> _system;
  boost::shared_ptr<ISolver> _solver;
};
/** @} */ // end of coreSimcontroller