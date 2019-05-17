#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
class IStepEvent
{
public:
  virtual ~IStepEvent(){};
  virtual bool stepCompleted(double time) = 0;
  //sets the initial status
  virtual void setTerminal(bool) = 0;
  //returns the intial status
  virtual bool terminal() = 0;
};
/** @} */ // end of coreSystem