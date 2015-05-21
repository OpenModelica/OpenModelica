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
  // gibt die Time events (Startzeit und Frequenz) zurück
  virtual void getTimeEvent(time_event_type& time_events) = 0;
  // Wird vom Solver zur Behandlung der Time events aufgerufen (wenn zero_sign[i] = 0  kein time event,zero_sign[i] = n  Anzahl von vorgekommen time events )
  virtual void handleTimeEvent(int* time_events) = 0;
  /// Set current integration time
  virtual void setTime(const double& time) = 0;
};
/** @} */ // end of coreSystem