/** @addtogroup fmu2
 *
 *  @{
 */
/*
 * Implement FMU2Wrapper.
 *
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "FMU2Wrapper.h"

static fmi2String const _LogCategoryFMUNames[] = {
  "logEvents",
  "logSingularLinearSystems",
  "logNonlinearSystems",
  "logDynamicStateSelection",
  "logStatusWarning",
  "logStatusDiscard",
  "logStatusError",
  "logStatusFatal",
  "logStatusPending",
  "logFmi2Call"
};

fmi2String FMU2Wrapper::LogCategoryFMUName(LogCategoryFMU category) {
  return _LogCategoryFMUNames[category];
}

FMU2Logger::FMU2Logger(FMU2Wrapper *wrapper,
                       LogSettings &logSettings, bool enabled) :
  Logger(logSettings, enabled),
  _wrapper(wrapper)
{
}

void FMU2Logger::initialize(FMU2Wrapper *wrapper, LogSettings &logSettings, bool enabled)
{
  _instance = new FMU2Logger(wrapper, logSettings, enabled);
}

void FMU2Logger::writeInternal(string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls)
{
  LogCategoryFMU category;
  fmi2Status status;

  if (ls == LS_END)
    return;

  // determine FMI status and category from LogLevel
  switch (lvl) {
  case LL_ERROR:
    status = fmi2Error;
    category = logStatusError;
    break;
  case LL_WARNING:
    status = fmi2Warning;
    category = logStatusWarning;
    break;
  default:
    status = fmi2OK;
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
  FMU2_LOG(_wrapper, status, category, msg.c_str());
}

FMU2Wrapper::FMU2Wrapper(fmi2String instanceName, fmi2String GUID,
                         const fmi2CallbackFunctions *functions,
                         fmi2Boolean loggingOn) :
  _functions(*functions),
  callbackLogger(_functions.logger)
{
  _global_settings = shared_ptr<FMU2GlobalSettings>(new FMU2GlobalSettings());
  _instanceName = instanceName;
  _GUID = GUID;

  // setup logger
  _logger = NULL;
  _logCategories = 0x0000;
  if (loggingOn) {
    // only instantiate logger if requested as it is not thread save
    setDebugLogging(loggingOn, 0, NULL);
  }

  // setup model
  _model = createSystemFMU(_global_settings);
  _model->initializeMemory();
  _model->initializeFreeVariables();
  _need_update = true;
  _string_buffer.resize(_model->getDimString());
  _clockTick = new bool[_model->getDimClock()];
  _clockSubactive = new bool[_model->getDimClock()];
  std::fill(_clockTick, _clockTick + _model->getDimClock(), false);
  std::fill(_clockSubactive, _clockSubactive + _model->getDimClock(), false);
  _nclockTick = 0;
}

FMU2Wrapper::~FMU2Wrapper()
{
  delete [] _clockSubactive;
  delete [] _clockTick;
  delete _model;
}

fmi2Status FMU2Wrapper::setDebugLogging(fmi2Boolean loggingOn,
                                        size_t nCategories,
                                        const fmi2String categories[])
{
  fmi2Status ret = fmi2OK;

  if (_logger == NULL) {
    LogSettings logSettings = _global_settings->getLogSettings();
    FMU2Logger::initialize(this, logSettings, loggingOn);
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
    int i, j, nSupported = sizeof(_LogCategoryFMUNames) / sizeof(fmi2String);
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
        FMU2_LOG(this, fmi2Warning, logStatusWarning,
                 "Unsupported log category \"%s\"", categories[i]);
        _logCategories = logCategories_bak;
        ret = fmi2Warning;
      }
    }
  }
  return ret;
}

fmi2Status FMU2Wrapper::setupExperiment(fmi2Boolean toleranceDefined,
                                        fmi2Real tolerance,
                                        fmi2Real startTime,
                                        fmi2Boolean stopTimeDefined,
                                        fmi2Real stopTime)
{
  // ToDo: setup tolerance and stop time
  return setTime(startTime);
}

fmi2Status FMU2Wrapper::enterInitializationMode()
{
  _model->setInitial(true);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::exitInitializationMode()
{
  if (_need_update)
    updateModel();
  _model->saveAll();
  _model->setInitial(false);
  _model->initTimeEventData();
  return fmi2OK;
}

fmi2Status FMU2Wrapper::terminate()
{
  return fmi2OK;
}

fmi2Status FMU2Wrapper::reset()
{
  _model->initializeFreeVariables();
 _need_update = true;
 _needJacUpdate = true;
  return fmi2OK;
}

void FMU2Wrapper::updateModel()
{
  if (_model->initial()) {
    _model->initializeBoundVariables();
    _model->saveAll();
  }
  _model->evaluateAll();     // derivatives and algebraic variables
  _need_update = false;
  _needJacUpdate = true;
}

fmi2Status FMU2Wrapper::setTime(fmi2Real time)
{
  if (_nclockTick > 0) {
    std::fill(_clockTick, _clockTick + _model->getDimClock(), false);
    std::fill(_clockSubactive, _clockSubactive + _model->getDimClock(), false);
    _nclockTick = 0;
  }
  _model->setTime(time);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setContinuousStates(const fmi2Real states[], size_t nx)
{
  _model->setContinuousStates(states);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getContinuousStates(fmi2Real states[], size_t nx)
{
  _model->getContinuousStates(states);
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getDerivatives(fmi2Real derivatives[], size_t nx)
{
  if (_need_update)
    updateModel();
  _model->computeTimeEventConditions(_model->getTime());
  _model->getRHS(derivatives);
  return fmi2OK;
}

fmi2Status FMU2Wrapper::completedIntegratorStep(fmi2Boolean noSetFMUStatePriorToCurrentPoint,
                                                fmi2Boolean *enterEventMode,
                                                fmi2Boolean *terminateSimulation)
{
  _model->saveAll();
  *enterEventMode = fmi2False;
  *terminateSimulation = fmi2False;
  return fmi2OK;
}

// Functions for setting inputs and start values
fmi2Status FMU2Wrapper::setReal(const fmi2ValueReference vr[], size_t nvr,
                                const fmi2Real value[])
{
  _model->setReal(vr, nvr, value);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setInteger(const fmi2ValueReference vr[], size_t nvr,
                                   const fmi2Integer value[])
{
  _model->setInteger(vr, nvr, value);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setBoolean(const fmi2ValueReference vr[], size_t nvr,
                                   const fmi2Boolean value[])
{
  _model->setBoolean(vr, nvr, value);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setString(const fmi2ValueReference vr[], size_t nvr,
                                  const fmi2String  value[])
{
  if (nvr > _string_buffer.size()) {
    FMU2_LOG(this, fmi2Error, logStatusError,
             "Attempt to set %d fmi2String; FMU only has %d",
             nvr, _string_buffer.size());
    return fmi2Error;
  }
  for (size_t i = 0; i < nvr; i++)
    _string_buffer[i] = string(value[i]); // convert to string
  _model->setString(vr, nvr, &_string_buffer[0]);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setClock(const fmi2Integer clockIndex[],
                                 size_t nClockIndex, const fmi2Boolean tick[],
                                 const fmi2Boolean *subactive)
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
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setInterval(const fmi2Integer clockIndex[],
                                    size_t nClockIndex, const fmi2Real interval[])
{
  double *clockInterval = _model->clockInterval();
  for (int i = 0; i < nClockIndex; i++) {
    clockInterval[clockIndex[i] - 1] = interval[i];
    _model->setIntervalInTimEventData((clockIndex[i] - 1), interval[i]);
  }
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getEventIndicators(fmi2Real eventIndicators[], size_t ni)
{
  if (_need_update)
    updateModel();
  bool conditions[NUMBER_OF_EVENT_INDICATORS + 1];
  _model->getConditions(conditions);
  _model->getZeroFunc(eventIndicators);
  for (int i = 0; i < ni; i++)
    if (!conditions[i]) eventIndicators[i] = -eventIndicators[i];
  return fmi2OK;
}

// Functions for reading the values of variables
fmi2Status FMU2Wrapper::getReal(const fmi2ValueReference vr[], size_t nvr,
                                fmi2Real value[])
{
  if (_need_update)
    updateModel();
  _model->getReal(vr, nvr, value);
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getInteger(const fmi2ValueReference vr[], size_t nvr,
                                   fmi2Integer value[])
{
  if (_need_update)
    updateModel();
  _model->getInteger(vr, nvr, value);
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getBoolean(const fmi2ValueReference vr[], size_t nvr,
                                   fmi2Boolean value[])
{
  if (_need_update)
    updateModel();
  _model->getBoolean(vr, nvr, value);
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getString(const fmi2ValueReference vr[], size_t nvr,
                                  fmi2String value[])
{
  if (nvr > _string_buffer.size()) {
    FMU2_LOG(this, fmi2Error, logStatusError,
             "Attempt to get %d fmi2String; FMU only has %d",
             nvr, _string_buffer.size());
    return fmi2Error;
  }
  if (_need_update)
    updateModel();
  _model->getString(vr, nvr, &_string_buffer[0]);
  for (size_t i = 0; i < nvr; i++)
    value[i] = _string_buffer[i].c_str(); // convert to fmi2String
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getClock(const fmi2Integer clockIndex[],
                                 size_t nClockIndex, fmi2Boolean tick[])
{
  for (int i = 0; i < nClockIndex; i++) {
    tick[i] = _clockTick[clockIndex[i] - 1];
  }
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getInterval(const fmi2Integer clockIndex[],
                                    size_t nClockIndex, fmi2Real interval[])
{
  double *clockInterval = _model->clockInterval();
  for (int i = 0; i < nClockIndex; i++) {
    interval[i] = clockInterval[clockIndex[i] - 1];
  }
  return fmi2OK;
}

fmi2Status FMU2Wrapper::newDiscreteStates(fmi2EventInfo *eventInfo)
{
  if (_need_update|| _nclockTick > 0) {
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
    eventInfo->nextEventTimeDefined = fmi2True;
  else
    eventInfo->nextEventTimeDefined = fmi2False;
  // everything is done
  eventInfo->newDiscreteStatesNeeded = fmi2False;
  eventInfo->terminateSimulation = fmi2False;
  eventInfo->nominalsOfContinuousStatesChanged = state_vars_reinitialized;
  eventInfo->valuesOfContinuousStatesChanged = state_vars_reinitialized;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getNominalsOfContinuousStates(fmi2Real x_nominal[], size_t nx)
{
  for (int i = 0; i < nx; i++)
    x_nominal[i] = 1.0;  // TODO
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getDirectionalDerivative(const fmi2ValueReference vrUnknown[],
                                                 size_t nUnknown,
                                                 const fmi2ValueReference vrKnown[],
                                                 size_t nKnown,
                                                 const fmi2Real dvKnown[],
                                                 fmi2Real dvUnknown[])
{
  if (_need_update)
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
  return fmi2OK;
}

/** @} */ // end of fmu2
