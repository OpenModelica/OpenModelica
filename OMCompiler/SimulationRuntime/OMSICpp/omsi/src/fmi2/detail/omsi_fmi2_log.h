#ifndef OIS_LOG_H
#define OIS_LOG_H

#include "fmi2Functions.h"


#define LOG_CALL(w, ...) \
  FMU2_LOG(w, fmi2OK, logFmi2Call, __VA_ARGS__)

#define CATCH_EXCEPTION(w) \
  catch (std::exception &e) { \
    FMU2_LOG(w, fmi2Error, logStatusError, e.what()); \
    return fmi2Error; \
  }


// define logger as macro that passes through variadic args
#define FMU2_LOG(w, status, category, ...) \
  if ((w)->logCategories() & (1 << (category))) \
    (w)->callbackLogger((w)->componentEnvironment(), (w)->instanceName(), \
                        status, (w)->LogCategoryFMUName(category), __VA_ARGS__)

enum LogCategoryFMU {
  logEvents = 0,
  logSingularLinearSystems,
  logNonlinearSystems,
  logDynamicStateSelection,
  logStatusWarning,
  logStatusDiscard,
  logStatusError,
  logStatusFatal,
  logStatusPending,
  logFmi2Call
};




/**
 * Forward Logger messages to FMI callback function
 */
class OSU;
class FMU2Logger: public Logger
{
 public:
  static void initialize(OSU *wrapper, LogSettings &logSettings, bool enabled);

 protected:
  FMU2Logger(OSU *wrapper, LogSettings &logSettings, bool enabled);

  virtual void writeInternal(string msg, LogCategory cat, LogLevel lvl,
                             LogStructure ls);
  OSU *_wrapper;
};



#endif
