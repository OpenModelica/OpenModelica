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

/* Implement FMU3Wrapper. */

#include "FMU3Wrapper.h"

#include <cstdarg>
#include <cstdio>
#include <cstdint>
#include <cstring>

static fmi3String const _LogCategoryFMUNames[] = {
  "logEvents",
  "logSingularLinearSystems",
  "logNonlinearSystems",
  "logDynamicStateSelection",
  "logStatusWarning",
  "logStatusDiscard",
  "logStatusError",
  "logStatusFatal",
  "logStatusPending",
  "logFmi3Call"
};

fmi3String FMU3Wrapper::LogCategoryFMUName(LogCategoryFMU category) {
  return _LogCategoryFMUNames[category];
}

void FMU3Wrapper::fmiLog(fmi3Status status, LogCategoryFMU category,
                         const char *message, ...) {
  if (_logMessage == NULL)
    return;
  char buffer[2048];
  va_list args;
  va_start(args, message);
  vsnprintf(buffer, sizeof(buffer), message, args);
  va_end(args);
  _logMessage(_instanceEnvironment, status, LogCategoryFMUName(category), buffer);
}

FMU3Logger::FMU3Logger(FMU3Wrapper *wrapper,
                       LogSettings &logSettings, bool enabled) :
  Logger(logSettings, enabled),
  _wrapper(wrapper)
{
}

void FMU3Logger::initialize(FMU3Wrapper *wrapper, LogSettings &logSettings, bool enabled)
{
  _instance = new FMU3Logger(wrapper, logSettings, enabled);
}

void FMU3Logger::writeInternal(string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls)
{
  LogCategoryFMU category;
  fmi3Status status;

  if (ls == LS_END)
    return;

  // determine FMI status and category from LogLevel
  switch (lvl) {
  case LL_ERROR:
    status = fmi3Error;
    category = logStatusError;
    break;
  case LL_WARNING:
    status = fmi3Warning;
    category = logStatusWarning;
    break;
  default:
    status = fmi3OK;
    category = logStatusWarning;
  }

  // override FMU category with matching LogCategory
  switch (cat) {
  case LC_NLS:
    category = logNonlinearSystems;
    break;
  case LC_EVENTS:
    category = logEvents;
    break;
  }

  // call FMU log function
  FMU3_LOG(_wrapper, status, category, msg.c_str());
}

FMU3Wrapper::FMU3Wrapper(fmi3String instanceName, fmi3String instantiationToken,
                         fmi3InstanceEnvironment instanceEnvironment,
                         fmi3LogMessageCallback logMessage, fmi3Boolean loggingOn) :
  _globalSettings(),
  _logMessage(logMessage),
  _instanceEnvironment(instanceEnvironment)
{
  _instanceName = instanceName;
  _GUID = instantiationToken;

  // setup logger
  _logger = NULL;
  _logCategories = 0x0000;
  if (loggingOn) {
    // only instantiate logger if requested as it is not thread save
    setDebugLogging(loggingOn, 0, NULL);
  }

  // setup model
  _model = createSystemFMU(&_globalSettings);
  _model->initializeMemory();
  _model->initializeFreeVariables();
  _needUpdate = true;
  _stringBuffer.resize(_model->getDimString());
  _clockTick = new bool[_model->getDimClock()];
  _clockSubactive = new bool[_model->getDimClock()];
  std::fill(_clockTick, _clockTick + _model->getDimClock(), false);
  std::fill(_clockSubactive, _clockSubactive + _model->getDimClock(), false);
  _nclockTick = 0;
}

FMU3Wrapper::~FMU3Wrapper()
{
  delete [] _clockSubactive;
  delete [] _clockTick;
  delete _model;
}

fmi3Status FMU3Wrapper::setDebugLogging(fmi3Boolean loggingOn,
                                        size_t nCategories,
                                        const fmi3String categories[])
{
  fmi3Status ret = fmi3OK;

  if (_logger == NULL) {
    LogSettings logSettings = _globalSettings.getLogSettings();
    FMU3Logger::initialize(this, logSettings, loggingOn);
    _logger = Logger::getInstance();
  }
  else {
    _logger->setEnabled(loggingOn);
  }
  if (nCategories == 0) {
    _logCategories = loggingOn? 0xFFFF: 0x0000;
    _logger->setAll(loggingOn? LL_DEBUG: LL_ERROR);
  }
  else {
    int i, j, nSupported = sizeof(_LogCategoryFMUNames) / sizeof(fmi3String);
    for (i = 0; i < nCategories; i++) {
      if (strcmp(categories[i], "logAll") == 0) {
        _logCategories = loggingOn? 0xFFFF: 0x0000;
        _logger->setAll(loggingOn? LL_DEBUG: LL_ERROR);
        continue;
      }
      for (j = 0; j < nSupported; j++) {
        if (strcmp(categories[i], _LogCategoryFMUNames[j]) == 0) {
          if (loggingOn)
            _logCategories |= (1 << j);
          else
            _logCategories &= ~(1 << j);
          switch (j) {
          case logEvents:
            _logger->set(LC_EVENTS, loggingOn? LL_DEBUG: LL_ERROR);
            break;
          case logNonlinearSystems:
            _logger->set(LC_NLS, loggingOn? LL_DEBUG: LL_ERROR);
            break;
          }
          break;
        }
      }
      // warn about unsupported log category
      if (j == nSupported) {
        unsigned int logCategories_bak = _logCategories;
        _logCategories = 0xFFFF;
        FMU3_LOG(this, fmi3Warning, logStatusWarning,
                 "Unsupported log category \"%s\"", categories[i]);
        _logCategories = logCategories_bak;
        ret = fmi3Warning;
      }
    }
  }
  return ret;
}

fmi3Status FMU3Wrapper::setupExperiment(fmi3Boolean toleranceDefined,
                                        fmi3Float64 tolerance,
                                        fmi3Float64 startTime,
                                        fmi3Boolean stopTimeDefined,
                                        fmi3Float64 stopTime)
{
  // ToDo: setup tolerance and stop time
  return setTime(startTime);
}

fmi3Status FMU3Wrapper::enterInitializationMode()
{
  _model->setInitial(true);
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::exitInitializationMode()
{
  if (_needUpdate)
    updateModel();
  _model->saveAll();
  _model->setInitial(false);
  _model->initTimeEventData();
  return fmi3OK;
}

fmi3Status FMU3Wrapper::terminate()
{
  return fmi3OK;
}

fmi3Status FMU3Wrapper::reset()
{
  _model->initializeFreeVariables();
  _needUpdate = true;
  return fmi3OK;
}

void FMU3Wrapper::updateModel()
{
  if (_model->initial()) {
    _model->initializeBoundVariables();
    _model->saveAll();
  }
  _model->evaluateAll();     // derivatives and algebraic variables
  _needUpdate = false;
  _needJacUpdate = true;
}

fmi3Status FMU3Wrapper::setTime(fmi3Float64 time)
{
  if (_nclockTick > 0) {
    std::fill(_clockTick, _clockTick + _model->getDimClock(), false);
    std::fill(_clockSubactive, _clockSubactive + _model->getDimClock(), false);
    _nclockTick = 0;
  }
  _model->setTime(time);
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::setContinuousStates(const fmi3Float64 states[], size_t nx)
{
  _model->setContinuousStates(states);
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getContinuousStates(fmi3Float64 states[], size_t nx)
{
  _model->getContinuousStates(states);
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getDerivatives(fmi3Float64 derivatives[], size_t nx)
{
  if (_needUpdate)
    updateModel();
  _model->computeTimeEventConditions(_model->getTime());
  _model->getRHS(derivatives);
  return fmi3OK;
}

fmi3Status FMU3Wrapper::completedIntegratorStep(fmi3Boolean noSetFMUStatePriorToCurrentPoint,
                                                fmi3Boolean *enterEventMode,
                                                fmi3Boolean *terminateSimulation)
{
  _model->saveAll();
  *enterEventMode = fmi3False;
  *terminateSimulation = fmi3False;
  return fmi3OK;
}

// Functions for setting inputs and start values
fmi3Status FMU3Wrapper::setReal(const unsigned int vr[], size_t nvr,
                                const double value[])
{
  _model->setReal(vr, nvr, value);
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::setInteger(const unsigned int vr[], size_t nvr,
                                   const int value[])
{
  _model->setInteger(vr, nvr, value);
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::setBoolean(const unsigned int vr[], size_t nvr,
                                   const int value[])
{
  _model->setBoolean(vr, nvr, value);
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::setString(const unsigned int vr[], size_t nvr,
                                  const fmi3String value[])
{
  if (nvr > _stringBuffer.size()) {
    FMU3_LOG(this, fmi3Error, logStatusError,
             "Attempt to set %d strings; FMU only has %d",
             nvr, _stringBuffer.size());
    return fmi3Error;
  }
  for (size_t i = 0; i < nvr; i++)
    _stringBuffer[i] = string(value[i]); // convert to string
  _model->setString(vr, nvr, &_stringBuffer[0]);
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::setClock(const int clockIndex[],
                                 size_t nClockIndex, const int tick[],
                                 const int *subactive)
{
  for (int i = 0; i < nClockIndex; i++) {
    _clockTick[clockIndex[i] - 1] = tick[i];
    if (subactive != NULL)
      _clockSubactive[clockIndex[i] - 1] = subactive[i];
  }
  _nclockTick = 0;
  for (int i = 0; i < _model->getDimClock(); i++) {
    _nclockTick += _clockTick[i]? 1: 0;
  }
  return fmi3OK;
}

fmi3Status FMU3Wrapper::setInterval(const int clockIndex[],
                                    size_t nClockIndex, const double interval[])
{
  double *clockInterval = _model->clockInterval();
  for (int i = 0; i < nClockIndex; i++) {
    clockInterval[clockIndex[i] - 1] = interval[i];
    _model->setIntervalInTimEventData((clockIndex[i] - 1), interval[i]);
  }
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getEventIndicators(fmi3Float64 eventIndicators[], size_t ni)
{
  if (_needUpdate)
    updateModel();
  bool conditions[NUMBER_OF_EVENT_INDICATORS + 1];
  _model->getConditions(conditions);
  _model->getZeroFunc(eventIndicators);
  for (int i = 0; i < ni; i++)
    if (!conditions[i]) eventIndicators[i] = -eventIndicators[i];
  return fmi3OK;
}

// Functions for reading the values of variables
fmi3Status FMU3Wrapper::getReal(const unsigned int vr[], size_t nvr,
                                double value[])
{
  if (_needUpdate)
    updateModel();
  _model->getReal(vr, nvr, value);
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getInteger(const unsigned int vr[], size_t nvr,
                                   int value[])
{
  if (_needUpdate)
    updateModel();
  _model->getInteger(vr, nvr, value);
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getBoolean(const unsigned int vr[], size_t nvr,
                                   int value[])
{
  if (_needUpdate)
    updateModel();
  _model->getBoolean(vr, nvr, value);
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getString(const unsigned int vr[], size_t nvr,
                                  fmi3String value[])
{
  if (nvr > _stringBuffer.size()) {
    FMU3_LOG(this, fmi3Error, logStatusError,
             "Attempt to get %d strings; FMU only has %d",
             nvr, _stringBuffer.size());
    return fmi3Error;
  }
  if (_needUpdate)
    updateModel();
  _model->getString(vr, nvr, &_stringBuffer[0]);
  for (size_t i = 0; i < nvr; i++)
    value[i] = _stringBuffer[i].c_str(); // convert to fmi3String
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getClock(const int clockIndex[],
                                 size_t nClockIndex, int tick[])
{
  for (int i = 0; i < nClockIndex; i++) {
    tick[i] = _clockTick[clockIndex[i] - 1];
  }
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getInterval(const int clockIndex[],
                                    size_t nClockIndex, double interval[])
{
  double *clockInterval = _model->clockInterval();
  for (int i = 0; i < nClockIndex; i++) {
    interval[i] = clockInterval[clockIndex[i] - 1];
  }
  return fmi3OK;
}

fmi3Status FMU3Wrapper::newDiscreteStates(FMU3EventInfo *eventInfo)
{
  if (_needUpdate || _nclockTick > 0) {
    if (_nclockTick > 0)
      _model->setClock(_clockTick, _clockSubactive);
    updateModel();
    if (_nclockTick > 0) {
      // reset clocks
      std::fill(_clockTick, _clockTick + _model->getDimClock(), false);
      std::fill(_clockSubactive, _clockSubactive + _model->getDimClock(), false);
      _nclockTick = 0;
    }
  }
  // Check if an Zero Crossings happend
  double f[NUMBER_OF_EVENT_INDICATORS + 1];
  bool events[NUMBER_OF_EVENT_INDICATORS + 1];
  _model->getZeroFunc(f);
  for (int i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++)
    events[i] = f[i] >= 0;
  // Handle Zero Crossings if nessesary
  bool state_vars_reinitialized = _model->handleSystemEvents(events);
  //time events
  eventInfo->nextEventTime = _model->computeNextTimeEvents(_model->getTime());
  if ((eventInfo->nextEventTime != 0.0) && (eventInfo->nextEventTime != std::numeric_limits<double>::max()))
    eventInfo->nextEventTimeDefined = true;
  else
    eventInfo->nextEventTimeDefined = false;
  // everything is done
  eventInfo->newDiscreteStatesNeeded = false;
  eventInfo->terminateSimulation = false;
  eventInfo->nominalsOfContinuousStatesChanged = state_vars_reinitialized;
  eventInfo->valuesOfContinuousStatesChanged = state_vars_reinitialized;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getNominalsOfContinuousStates(fmi3Float64 x_nominal[], size_t nx)
{
  for (int i = 0; i < nx; i++)
    x_nominal[i] = 1.0;  // TODO
  return fmi3OK;
}

fmi3Status FMU3Wrapper::getDirectionalDerivative(const unsigned int vrUnknown[],
                                                 size_t nUnknown,
                                                 const unsigned int vrKnown[],
                                                 size_t nKnown,
                                                 const double dvKnown[],
                                                 double dvUnknown[])
{
  if (_needUpdate)
    updateModel();
  SystemLockFreeVariables slfv(_model, !_needJacUpdate);
  if (_nclockTick > 0) {
    // set clock for subactive evaluation
    _model->setClock(_clockTick, _clockSubactive);
  }
  _model->getDirectionalDerivative(vrUnknown, nUnknown,
                                   vrKnown, nKnown, dvKnown,
                                   dvUnknown);
  if (_nclockTick > 0) {
    // reset clocks
    std::fill(_clockTick, _clockTick + _model->getDimClock(), false);
    std::fill(_clockSubactive, _clockSubactive + _model->getDimClock(), false);
    _nclockTick = 0;
  }
  _needJacUpdate = false;
  return fmi3OK;
}

// ---------------------------------------------------------------------------
// FMU state get/set/free and (de)serialization
//
// The state is a complete snapshot of the model variables (time, continuous
// states and the full real/integer/boolean/string arrays), taken and restored
// through the bulk IContinuous accessors. This mirrors the C runtime, which
// snapshots the simulation-data arrays.
// ---------------------------------------------------------------------------
fmi3Status FMU3Wrapper::getFMUState(fmi3FMUState* state)
{
  if (_needUpdate)
    updateModel();

  FMU3State* s = (FMU3State*) (*state);
  if (s == NULL)
    s = new FMU3State();

  int nReal   = _model->getDimReal();
  int nInt    = _model->getDimInteger();
  int nBool   = _model->getDimBoolean();
  int nString = _model->getDimString();
  int nStates = _model->getDimContinuousStates();

  // the bulk array accessors live on IContinuous; the per-value-reference
  // overloads on the model hide them, so reach them through the base interface
  IContinuous* ic = _model;

  s->time = _model->getTime();
  s->reals.resize(nReal);
  s->integers.resize(nInt);
  s->booleans.resize(nBool);
  s->strings.resize(nString);
  s->states.resize(nStates);

  if (nReal)   ic->getReal(&s->reals[0]);
  if (nInt)    ic->getInteger(&s->integers[0]);
  if (nBool) {
    // getBoolean expects bool*; snapshot via a temporary, store as char
    bool* raw = new bool[nBool];
    ic->getBoolean(raw);
    for (int i = 0; i < nBool; i++) s->booleans[i] = raw[i] ? 1 : 0;
    delete[] raw;
  }
  if (nString) ic->getString(&s->strings[0]);
  if (nStates) ic->getContinuousStates(&s->states[0]);

  *state = (fmi3FMUState) s;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::setFMUState(fmi3FMUState state)
{
  FMU3State* s = (FMU3State*) state;
  if (s == NULL)
    return fmi3Error;

  IContinuous* ic = _model;

  _model->setTime(s->time);
  if (!s->reals.empty())    ic->setReal(&s->reals[0]);
  if (!s->integers.empty()) ic->setInteger(&s->integers[0]);
  if (!s->booleans.empty()) {
    bool* raw = new bool[s->booleans.size()];
    for (size_t i = 0; i < s->booleans.size(); i++) raw[i] = s->booleans[i] != 0;
    ic->setBoolean(raw);
    delete[] raw;
  }
  if (!s->strings.empty())  ic->setString(&s->strings[0]);
  if (!s->states.empty())   ic->setContinuousStates(&s->states[0]);

  // algebraic variables / derivatives are recomputed on the next access
  _needUpdate = true;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::freeFMUState(fmi3FMUState* state)
{
  if (state != NULL && *state != NULL) {
    delete (FMU3State*) (*state);
    *state = NULL;
  }
  return fmi3OK;
}

fmi3Status FMU3Wrapper::serializedFMUStateSize(fmi3FMUState state, size_t* size)
{
  FMU3State* s = (FMU3State*) state;
  if (s == NULL || size == NULL)
    return fmi3Error;

  size_t sz = sizeof(double);                          // time
  sz += 5 * sizeof(uint32_t);                          // the five array lengths
  sz += s->reals.size()    * sizeof(double);
  sz += s->integers.size() * sizeof(int32_t);
  sz += s->booleans.size() * sizeof(char);
  sz += s->states.size()   * sizeof(double);
  for (size_t i = 0; i < s->strings.size(); i++)       // each string: length + bytes
    sz += sizeof(uint32_t) + s->strings[i].size();

  *size = sz;
  return fmi3OK;
}

// helper: append raw bytes to a moving cursor
static inline void omc_pack(fmi3Byte** p, const void* src, size_t n)
{
  memcpy(*p, src, n);
  *p += n;
}
// helper: read raw bytes from a moving cursor
static inline void omc_unpack(const fmi3Byte** p, void* dst, size_t n)
{
  memcpy(dst, *p, n);
  *p += n;
}
// helper: bounds-checked read; returns false if fewer than n bytes remain
static inline bool omc_unpack_chk(const fmi3Byte** p, const fmi3Byte* end, void* dst, size_t n)
{
  if ((size_t)(end - *p) < n)
    return false;
  memcpy(dst, *p, n);
  *p += n;
  return true;
}

fmi3Status FMU3Wrapper::serializeFMUState(fmi3FMUState state, fmi3Byte serializedState[], size_t size)
{
  FMU3State* s = (FMU3State*) state;
  if (s == NULL || serializedState == NULL)
    return fmi3Error;

  // Validate the buffer is large enough BEFORE writing anything, otherwise a
  // too-small buffer would already be corrupted by the time the trailing size
  // check below caught it.
  size_t required = 0;
  if (serializedFMUStateSize(state, &required) != fmi3OK || size < required)
    return fmi3Error;

  fmi3Byte* p = serializedState;
  uint32_t nReal   = (uint32_t) s->reals.size();
  uint32_t nInt    = (uint32_t) s->integers.size();
  uint32_t nBool   = (uint32_t) s->booleans.size();
  uint32_t nString = (uint32_t) s->strings.size();
  uint32_t nStates = (uint32_t) s->states.size();

  omc_pack(&p, &s->time, sizeof(double));
  omc_pack(&p, &nReal,   sizeof(uint32_t));
  omc_pack(&p, &nInt,    sizeof(uint32_t));
  omc_pack(&p, &nBool,   sizeof(uint32_t));
  omc_pack(&p, &nString, sizeof(uint32_t));
  omc_pack(&p, &nStates, sizeof(uint32_t));
  if (nReal)   omc_pack(&p, &s->reals[0],    nReal   * sizeof(double));
  if (nInt) {
    for (uint32_t i = 0; i < nInt; i++) {
      int32_t v = (int32_t) s->integers[i];
      omc_pack(&p, &v, sizeof(int32_t));
    }
  }
  if (nBool)   omc_pack(&p, &s->booleans[0], nBool   * sizeof(char));
  if (nStates) omc_pack(&p, &s->states[0],   nStates * sizeof(double));
  for (uint32_t i = 0; i < nString; i++) {
    uint32_t len = (uint32_t) s->strings[i].size();
    omc_pack(&p, &len, sizeof(uint32_t));
    if (len) omc_pack(&p, s->strings[i].data(), len);
  }

  // sanity: we must have written exactly `size` bytes
  if ((size_t)(p - serializedState) != size)
    return fmi3Error;
  return fmi3OK;
}

fmi3Status FMU3Wrapper::deSerializeFMUState(const fmi3Byte serializedState[], size_t size, fmi3FMUState* state)
{
  if (serializedState == NULL || state == NULL)
    return fmi3Error;

  FMU3State* s = new FMU3State();
  const fmi3Byte* p = serializedState;
  const fmi3Byte* end = serializedState + size;
  uint32_t nReal = 0, nInt = 0, nBool = 0, nString = 0, nStates = 0;

  // Header: time + five array lengths. Bail out (freeing s) on any short read.
  if (!omc_unpack_chk(&p, end, &s->time, sizeof(double)) ||
      !omc_unpack_chk(&p, end, &nReal,   sizeof(uint32_t)) ||
      !omc_unpack_chk(&p, end, &nInt,    sizeof(uint32_t)) ||
      !omc_unpack_chk(&p, end, &nBool,   sizeof(uint32_t)) ||
      !omc_unpack_chk(&p, end, &nString, sizeof(uint32_t)) ||
      !omc_unpack_chk(&p, end, &nStates, sizeof(uint32_t))) {
    delete s;
    return fmi3Error;
  }

  // Reject counts that cannot fit in the remaining buffer before resizing, so a
  // corrupt blob cannot drive a huge allocation (each string costs at least its
  // uint32_t length prefix).
  size_t remaining = (size_t)(end - p);
  if ((size_t)nReal   * sizeof(double)   > remaining ||
      (size_t)nInt    * sizeof(int32_t)  > remaining ||
      (size_t)nBool   * sizeof(char)     > remaining ||
      (size_t)nStates * sizeof(double)   > remaining ||
      (size_t)nString * sizeof(uint32_t) > remaining) {
    delete s;
    return fmi3Error;
  }

  s->reals.resize(nReal);
  s->integers.resize(nInt);
  s->booleans.resize(nBool);
  s->strings.resize(nString);
  s->states.resize(nStates);

  bool ok = true;
  if (nReal) ok = omc_unpack_chk(&p, end, &s->reals[0], nReal * sizeof(double));
  for (uint32_t i = 0; ok && i < nInt; i++) {
    int32_t v = 0;
    ok = omc_unpack_chk(&p, end, &v, sizeof(int32_t));
    if (ok) s->integers[i] = (int) v;
  }
  if (ok && nBool)   ok = omc_unpack_chk(&p, end, &s->booleans[0], nBool * sizeof(char));
  if (ok && nStates) ok = omc_unpack_chk(&p, end, &s->states[0], nStates * sizeof(double));
  for (uint32_t i = 0; ok && i < nString; i++) {
    uint32_t len = 0;
    ok = omc_unpack_chk(&p, end, &len, sizeof(uint32_t));
    if (ok) {
      if ((size_t)(end - p) < len) {
        ok = false;
      } else {
        s->strings[i].assign((const char*) p, len);
        p += len;
      }
    }
  }
  if (!ok) {
    delete s;
    return fmi3Error;
  }

  *state = (fmi3FMUState) s;
  return fmi3OK;
}

/** @} */ // end of fmu3
