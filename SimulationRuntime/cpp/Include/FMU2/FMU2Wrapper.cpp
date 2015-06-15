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

#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
/*workarround until cmake file is modified*/
//#define OMC_BUILD
#include <Core/Solver/ISolverSettings.h>
#include <Core/SimulationSettings/ISettingsFactory.h>
#include <Core/Solver/ISolver.h>
#include <Core/DataExchange/SimData.h>

/*end workarround*/
#include <System/AlgLoopSolverFactory.h>

static fmi2String const _logCategoryNames[] = {
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

fmi2String FMU2Wrapper::logCategoryName(LogCategory category) {
  return _logCategoryNames[category];
}

FMU2Wrapper::FMU2Wrapper(fmi2String instanceName, fmi2String GUID,
                         const fmi2CallbackFunctions *functions,
                         fmi2Boolean loggingOn) :
  _global_settings(), _functions(*functions), logger(_functions.logger),
  componentEnvironment(_functions.componentEnvironment),
  instanceName(_instanceName), logCategories(_logCategories)
{
  _instanceName = instanceName;
  _GUID = GUID;
  _logCategories = loggingOn? 0xFFFF: 0x0000;
  boost::shared_ptr<IAlgLoopSolverFactory>
    solver_factory(new AlgLoopSolverFactory(&_global_settings,
                                            PATH(""), PATH("")));
  _model = boost::shared_ptr<MODEL_CLASS>
    (new MODEL_CLASS(&_global_settings, solver_factory,
                     boost::shared_ptr<ISimData>(new SimData()),
                     boost::shared_ptr<ISimVars>(MODEL_CLASS::createSimVars())));
  _model->initialize();
  _string_buffer.resize(_model->getDimString());
}

FMU2Wrapper::~FMU2Wrapper()
{
}

fmi2Status FMU2Wrapper::setDebugLogging(fmi2Boolean loggingOn,
                                        size_t nCategories,
                                        const fmi2String categories[])
{
  fmi2Status ret = fmi2OK;
  if (nCategories == 0)
    _logCategories = loggingOn? 0xFFFF: 0x0000;
  else {
    int i, j, nSupported = sizeof(_logCategoryNames) / sizeof(fmi2String);
    for (i = 0; i < nCategories; i++) {
      if (strcmp(categories[i], "logAll") == 0) {
        _logCategories = loggingOn? 0xFFFF: 0x0000;
        continue;
      }
      for (j = 0; j < nSupported; j++) {
        if (strcmp(categories[i], _logCategoryNames[j]) == 0) {
          if (loggingOn)
            _logCategories |= (1 << j);
          else
            _logCategories &= ~(1 << j);
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
  return fmi2OK;
}

fmi2Status FMU2Wrapper::terminate()
{
  return fmi2OK;
}

fmi2Status FMU2Wrapper::reset()
{
  _model->initializeFreeVariables();
  return fmi2OK;
}

void FMU2Wrapper::updateModel()
{
  if (_model->initial())
    _model->initializeBoundVariables();
  _model->evaluateAll();     // derivatives and algebraic variables
  _need_update = false;
}

fmi2Status FMU2Wrapper::setTime(fmi2Real time)
{
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

fmi2Status FMU2Wrapper::getEventIndicators(fmi2Real eventIndicators[], size_t ni)
{
  if (_need_update)
    updateModel();
  bool conditions[NUMBER_OF_EVENT_INDICATORS];
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


fmi2Status FMU2Wrapper::newDiscreteStates(fmi2EventInfo *eventInfo)
{
  if (_need_update)
    updateModel();
  // Check if an Zero Crossings happend
  double f[NUMBER_OF_EVENT_INDICATORS];
  bool events[NUMBER_OF_EVENT_INDICATORS];
  _model->getZeroFunc(f);
  for (int i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++)
    events[i] = f[i] >= 0;
  // Handle Zero Crossings if nessesary
  bool state_vars_reinitialized = _model->handleSystemEvents(events);
  // everything is done
  eventInfo->newDiscreteStatesNeeded = fmi2False;
  eventInfo->terminateSimulation = fmi2False;
  eventInfo->nominalsOfContinuousStatesChanged = state_vars_reinitialized;
  eventInfo->valuesOfContinuousStatesChanged = state_vars_reinitialized;
  eventInfo->nextEventTimeDefined = fmi2False;
  //eventInfo->nextEventTime = _time;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getNominalsOfContinuousStates(fmi2Real x_nominal[], size_t nx)
{
  for (int i = 0; i < nx; i++)
    x_nominal[i] = 1.0;  // TODO
  return fmi2OK;
}
/** @} */ // end of fmu2
