#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/Object/IObject.h>

class ICoupledSystem
{
public:
  virtual void addAcross(IObject&) = 0;
  virtual void addThrough(IObject&) = 0;
};
/** @} */ // end of coreSystem