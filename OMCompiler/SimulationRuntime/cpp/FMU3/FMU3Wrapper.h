/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/** @addtogroup fmu3
 *
 *  @{
 */

/* Wrap a Modelica System of the Cpp runtime for FMI 3.0.
 *
 * The wrapper talks to the generated model using plain C++ types (double, int,
 * unsigned int, std::string), which is what the model accessors use. It only
 * depends on the FMI 3.0 reference header for the logging callback and the
 * status enum; the FMI 3.0 C API (and any value-reference offsetting) lives in
 * FMU3Interface.cpp. The wrapper is independent of the FMI 2.0 files. */

#pragma once


#include <iostream>
#include <string>
#include <vector>
#include <assert.h>

#include "fmi3Functions.h"
#include "FMU3GlobalSettings.h"

// define logger as macro that only formats/forwards if the category is enabled
#define FMU3_LOG(w, status, category, ...) \
  if ((w)->logCategories() & (1 << (category))) \
    (w)->fmiLog(status, category, __VA_ARGS__)

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
  logFmi3Call
};

/* Discrete-state update result (the FMI 3.0 fmi3UpdateDiscreteStates outputs),
   filled by FMU3Wrapper::newDiscreteStates. */
typedef struct {
  bool   newDiscreteStatesNeeded;
  bool   terminateSimulation;
  bool   nominalsOfContinuousStatesChanged;
  bool   valuesOfContinuousStatesChanged;
  bool   nextEventTimeDefined;
  double nextEventTime;
} FMU3EventInfo;

class FMU3Wrapper;

/**
 * Forward Logger messages to the FMI 3.0 log callback
 */
class FMU3Logger: public Logger
{
 public:
  static void initialize(FMU3Wrapper *wrapper, LogSettings &logSettings, bool enabled);

 protected:
  FMU3Logger(FMU3Wrapper *wrapper, LogSettings &logSettings, bool enabled);

  virtual void writeInternal(string msg, LogCategory cat, LogLevel lvl,
                             LogStructure ls);
  FMU3Wrapper *_wrapper;
};

/**
 * Wrap a model and a logger for FMI 3.0
 */
class FMU3Wrapper
{
 public:
  // Creation and destruction of FMU instances and setting logging status
  FMU3Wrapper(fmi3String instanceName, fmi3String instantiationToken,
              fmi3InstanceEnvironment instanceEnvironment,
              fmi3LogMessageCallback logMessage, fmi3Boolean loggingOn);
  virtual ~FMU3Wrapper();

  // Debug logging
  virtual fmi3Status setDebugLogging(fmi3Boolean loggingOn,
                                     size_t nCategories,
                                     const fmi3String categories[]);
  unsigned int logCategories() {
    return _logCategories;
  }
  fmi3String instanceName() {
    return _instanceName.c_str();
  }
  static fmi3String LogCategoryFMUName(LogCategoryFMU);
  // format a message (printf-style) and forward it to the FMI 3.0 log callback
  void fmiLog(fmi3Status status, LogCategoryFMU category, const char *message, ...);

  // Enter and exit initialization mode, terminate and reset
  virtual fmi3Status setupExperiment(fmi3Boolean toleranceDefined,
                                     fmi3Float64 tolerance,
                                     fmi3Float64 startTime,
                                     fmi3Boolean stopTimeDefined,
                                     fmi3Float64 stopTime);
  virtual fmi3Status enterInitializationMode();
  virtual fmi3Status exitInitializationMode();
  virtual fmi3Status terminate      ();
  virtual fmi3Status reset          ();

  // Getting and setting variable values. Booleans use int and value references
  // use unsigned int to match the generated model accessors.
  virtual fmi3Status getReal   (const unsigned int vr[], size_t nvr,
                                double value[]);
  virtual fmi3Status getInteger(const unsigned int vr[], size_t nvr,
                                int value[]);
  virtual fmi3Status getBoolean(const unsigned int vr[], size_t nvr,
                                int value[]);
  virtual fmi3Status getString (const unsigned int vr[], size_t nvr,
                                fmi3String value[]);
  virtual fmi3Status getClock  (const int clockIndex[],
                                size_t nClockIndex, int tick[]);
  virtual fmi3Status getInterval(const int clockIndex[],
                                 size_t nClockIndex, double interval[]);

  virtual fmi3Status setReal   (const unsigned int vr[], size_t nvr,
                                const double value[]);
  virtual fmi3Status setInteger(const unsigned int vr[], size_t nvr,
                                const int value[]);
  virtual fmi3Status setBoolean(const unsigned int vr[], size_t nvr,
                                const int value[]);
  virtual fmi3Status setString (const unsigned int vr[], size_t nvr,
                                const fmi3String value[]);
  virtual fmi3Status setClock  (const int clockIndex[],
                                size_t nClockIndex, const int tick[],
                                const int *subactive);
  virtual fmi3Status setInterval(const int clockIndex[],
                                 size_t nClockIndex, const double interval[]);

  // Enter and exit the different modes for Model Exchange
  virtual fmi3Status newDiscreteStates      (FMU3EventInfo *eventInfo);
  virtual fmi3Status completedIntegratorStep(fmi3Boolean noSetFMUStatePriorToCurrentPoint,
                                             fmi3Boolean *enterEventMode,
                                             fmi3Boolean *terminateSimulation);

  // Providing independent variables and re-initialization of caching
  virtual fmi3Status setTime                (fmi3Float64 time);
  virtual fmi3Status setContinuousStates    (const fmi3Float64 x[], size_t nx);

  // Evaluation of the model equations
  virtual fmi3Status getDerivatives     (fmi3Float64 derivatives[], size_t nx);
  virtual fmi3Status getEventIndicators (fmi3Float64 eventIndicators[], size_t ni);
  virtual fmi3Status getContinuousStates(fmi3Float64 states[], size_t nx);
  virtual fmi3Status getNominalsOfContinuousStates(fmi3Float64 x_nominal[], size_t nx);

  // Jacobian
  fmi3Status getDirectionalDerivative(const unsigned int vrUnknown[],
                                      size_t nUnknown,
                                      const unsigned int vrKnown[],
                                      size_t nKnown,
                                      const double dvKnown[],
                                      double dvUnknown[]);

 private:
  FMU3GlobalSettings _globalSettings;
  Logger *_logger;
  MODEL_CLASS *_model;
  std::vector<string> _stringBuffer;
  bool *_clockTick;
  bool *_clockSubactive;
  int _nclockTick;
  bool _needUpdate;
  bool _needJacUpdate;
  void updateModel();

  typedef enum {
    Instantiated       = 1 << 0,
    InitializationMode = 1 << 1,
    EventMode          = 1 << 2,
    ContinuousTimeMode = 1 << 3,
    Terminated         = 1 << 4,
    Error              = 1 << 5,
    Fatal              = 1 << 6
  } ModelState;

  unsigned int _logCategories;
  string _instanceName;
  string _GUID;
  fmi3LogMessageCallback _logMessage;
  fmi3InstanceEnvironment _instanceEnvironment;
  ModelState _state;
};

/** @} */ // end of fmu3
