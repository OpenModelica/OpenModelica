#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
typedef std::vector<std::pair<double,double> > time_event_type;

class ITime
{
public:
  virtual ~ITime() {};
  virtual int getDimTimeEvent() const = 0;
  virtual std::pair<double, double>* getTimeEventData() const = 0;
  // gibt die Time events (Startzeit und Frequenz) zurück
  virtual void initTimeEventData() = 0;
  virtual void computeTimeEventConditions(double currTime) = 0;
  virtual double computeNextTimeEvents(double currTime) = 0;
  virtual void resetTimeConditions() = 0;

  /// Set current integration time
  virtual void setTime(const double& time) = 0;
};
/** @} */ // end of coreSystem
