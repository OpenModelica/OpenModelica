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
  Initialization(shared_ptr<ISystemInitialization> system_initialization, shared_ptr<ISolver>);
  ~Initialization(void);
  void initializeSystem(/*double start_time, double end_time*/);

private:
  shared_ptr<ISystemInitialization> _system;
  shared_ptr<ISolver> _solver;
};
/** @} */ // end of coreSimcontroller