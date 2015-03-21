/*
 * Implement FMU2Wrapper.
 *
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "FMU2Wrapper.h"

#include <Core/Modelica.h>
/*workarround until cmake file is modified*/
//#define OMC_BUILD
#include <Core/Solver/ISolverSettings.h>
#include <Core/SimulationSettings/ISettingsFactory.h>
#include <Core/Solver/ISolver.h>
#include <Core/DataExchange/SimData.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
/*end workarround*/
#include <System/AlgLoopSolverFactory.h>

FMU2Wrapper::FMU2Wrapper(fmi2String instanceName, fmi2String GUID,
     const fmi2CallbackFunctions *functions, fmi2Boolean loggingOn) :
  _instanceName(instanceName), _GUID(GUID), _functions(*functions),
  _global_settings()
{
  boost::shared_ptr<IAlgLoopSolverFactory>
      solver_factory(new AlgLoopSolverFactory(&_global_settings,PATH(""),PATH("")));
  _model = boost::shared_ptr<MODEL_IDENTIFIER>
      (new MODEL_IDENTIFIER(&_global_settings, solver_factory,boost::shared_ptr<ISimData>(new SimData())));
  _model->setInitial(true);
  _model->initialize(); // set default start values
  _tmp_real_buffer.resize(_model->getDimContinuousStates() + _model->getDimRHS() + _model->getDimReal());
  _tmp_int_buffer.resize(_model->getDimInteger());
  _tmp_bool_buffer.resize(_model->getDimBoolean());
}

FMU2Wrapper::~FMU2Wrapper()
{
}

fmi2Status FMU2Wrapper::setDebugLogging(fmi2Boolean loggingOn)
{
  return fmi2OK;
}

/*  independent variables and re-initialization of caching */
fmi2Status FMU2Wrapper::setupExperiment(fmi2Boolean toleranceDefined,
                                        fmi2Real tolerance,
                                        fmi2Real startTime,
                                        fmi2Boolean stopTimeDefined,
                                        fmi2Real stopTime)
{
  // ToDo: setup tolerance and stop time
  return setTime(startTime);
}

fmi2Status FMU2Wrapper::setTime(fmi2Real time)
{
  _model->setTime(time);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setContinuousStates(const fmi2Real states[], size_t nx)
{
  // to set states do the folowing
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
  updateModel();
  _model->getRHS(derivatives);
  return fmi2OK;
}


void FMU2Wrapper::updateModel()
{
  // only call update if, time, states or imputs changed
  if(!_need_update)
    return;

  _model->evaluateAll(); // This will calculate the values for derivate variables, algebraic variables
  _need_update = false;
}

fmi2Status FMU2Wrapper::completedIntegratorStep(fmi2Boolean noSetFMUStatePriorToCurrentPoint,
            fmi2Boolean *enterEventMode,
            fmi2Boolean *terminateSimulation)
{
  _model->saveAll();
  *enterEventMode = false;
  *terminateSimulation = fmi2False;
  return fmi2OK;
}

// Functions for setting inputs and start values
fmi2Status FMU2Wrapper::setReal(const fmi2ValueReference vr[], size_t nvr,
                                const fmi2Real value[])
{
  _model->getReal(&_tmp_real_buffer[0]);
  for(size_t i = 0; i < nvr; ++i)
    _tmp_real_buffer[vr[i]] = value[i];
  _model->setReal(&_tmp_real_buffer[0]);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setInteger(const fmi2ValueReference vr[], size_t nvr,
                                   const fmi2Integer value[])
{
  _model->getInteger(&_tmp_int_buffer[0]);
  for(size_t i = 0; i < nvr; ++i)
    _tmp_int_buffer[vr[i]] = value[i];
  _model->setInteger(&_tmp_int_buffer[0]);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setBoolean(const fmi2ValueReference vr[], size_t nvr,
                                   const fmi2Boolean value[])
{
  _model->getBoolean((bool*) &_tmp_bool_buffer[0]);
  for(size_t i = 0; i < nvr; ++i)
    _tmp_bool_buffer[vr[i]] = value[i];
  _model->setBoolean((bool*) &_tmp_bool_buffer[0]);
  _need_update = true;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::setString(const fmi2ValueReference vr[], size_t nvr,
                                  const fmi2String  value[])
{
  // TODO implement strings
  _need_update = true;
  return fmi2OK;
}

/*  of the model equations */
fmi2Status FMU2Wrapper::initialize()
{
  // TODO: here is some code duplication to SimulationRuntime/cpp/Core/Solver/Initailization.cpp
  _model->setInitial(true);

  bool restart=true;
  int iter=0;
  while(restart && !(iter++ > 10))
  {
    _model->evaluateAll(IContinuous::ALL);
    restart = _model->checkForDiscreteEvents();
  }

  _model->saveAll();
   int dim = _model->getDimZeroFunc();
   for(int i=0;i<dim;i++)
   {
     _model->getCondition(i);
   }

  _model->setInitial(false);
  _need_update = false;
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getEventIndicators(fmi2Real eventIndicators[], size_t ni)
{
  updateModel();
  bool conditions[NUMBER_OF_EVENT_INDICATORS];
  _model->getConditions(conditions);
  _model->getZeroFunc(eventIndicators);
  for(int i = 0; i < ni; i++)
    if(!conditions[i]) eventIndicators[i] = -eventIndicators[i];
  return fmi2OK;
}

// Funktions for reading the values of variables that have a reference by the modelDescription.xml
fmi2Status FMU2Wrapper::getReal(const fmi2ValueReference vr[], size_t nvr,
                                fmi2Real value[])
{
  updateModel();
  _model->getReal(&_tmp_real_buffer[0]);
  for(size_t i = 0; i < nvr; ++i)
    value[i] = _tmp_real_buffer[vr[i]];
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getInteger(const fmi2ValueReference vr[], size_t nvr,
                                   fmi2Integer value[])
{
  updateModel();
  _model->getInteger(&_tmp_int_buffer[0]);
  for(size_t i = 0; i < nvr; ++i)
    value[i] = _tmp_int_buffer[vr[i]];
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getBoolean(const fmi2ValueReference vr[], size_t nvr,
                                   fmi2Boolean value[])
{
  updateModel();
  _model->getBoolean((bool*) &_tmp_bool_buffer[0]);
  for(size_t i = 0; i < nvr; ++i)
    value[i] = _tmp_bool_buffer[vr[i]];
  return fmi2OK;
}

fmi2Status FMU2Wrapper::getString(const fmi2ValueReference vr[], size_t nvr,
                                  fmi2String value[])
{
  updateModel();
//  for(size_t i = 0; i < nvr; ++i)
//TODO    _model->getString(vr[i], value[i]);
  return fmi2OK;
}


fmi2Status FMU2Wrapper::newDiscreteStates(fmi2EventInfo *eventInfo)
{
  updateModel();
  // Check if an Zero Crossings happend
  double f[NUMBER_OF_EVENT_INDICATORS];
  bool events[NUMBER_OF_EVENT_INDICATORS];
  _model->getZeroFunc(f);
  for(int i=0; i<NUMBER_OF_EVENT_INDICATORS; i++)
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
  updateModel();
  for(int i = 0; i < nx; ++i)
    x_nominal[i] = 1.0;  // TODO
  return fmi2OK;
}

fmi2Status FMU2Wrapper::terminate()
{
  return fmi2OK;
}

fmi2Status FMU2Wrapper::reset()
{
  // Note: initialize() leeks memory and does not appear needed here
  //_model->initialize();
  return fmi2OK;
}
