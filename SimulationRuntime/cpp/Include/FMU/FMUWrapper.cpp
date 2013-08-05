#include "Modelica.h"
#include "FMU/FMUWrapper.h"
#include "System/AlgLoopSolverFactory.h"


FMUWrapper::FMUWrapper(fmiString instanceName, fmiString GUID,
    fmiCallbackFunctions functions, fmiBoolean loggingOn) :
  IFMUInterface(instanceName, GUID, functions, loggingOn),
  _global_settings()
{
  boost::shared_ptr<IAlgLoopSolverFactory>
      solver_factory(new AlgLoopSolverFactory(_global_settings));
  _model = boost::shared_ptr<MODEL_IDENTIFIER>
      (new MODEL_IDENTIFIER(&_global_settings, solver_factory));
  _model->setInitial(true);
}

FMUWrapper::~FMUWrapper() 
{
}

fmiStatus FMUWrapper::setDebugLogging(fmiBoolean loggingOn)
{
  return fmiOK;
}

/*  independent variables and re-initialization of caching */
fmiStatus FMUWrapper::setTime(fmiReal time)
{
  _model->setTime(time);
  _need_update = true;
  return fmiOK;
}

fmiStatus FMUWrapper::setContinuousStates(const fmiReal states[], size_t nx)
{
  // to set states do the folowing
  _model->setVars(states);
  _need_update = true;
  return fmiOK;
}

fmiStatus FMUWrapper::getContinuousStates(fmiReal states[], size_t nx)
{
  _model->giveVars(states);
  return fmiOK;
}

fmiStatus FMUWrapper::getDerivatives(fmiReal derivatives[], size_t nx)
{
  updateModel();
  _model->giveRHS(derivatives);
  return fmiOK;
}


void FMUWrapper::updateModel()
{
  // only call update if, time, states or imputs changed
  if(!_need_update)
    return;

  _model->update(); // This will calculate the values for derivate variables, algebraic variables
  _need_update = false;
}

fmiStatus FMUWrapper::completedIntegratorStep(fmiBoolean& callEventUpdate)
{
  _model->saveAll();
  callEventUpdate = false;
  return fmiOK;
}

// Functions for setting inputs and start values
fmiStatus FMUWrapper::setReal(const fmiValueReference vr[], size_t nvr,
    const fmiReal value[])
{ _need_update = true; return fmiOK; }

fmiStatus FMUWrapper::setInteger(const fmiValueReference vr[], size_t nvr,
    const fmiInteger value[])
{ _need_update = true; return fmiOK; }

fmiStatus FMUWrapper::setBoolean(const fmiValueReference vr[], size_t nvr,
    const fmiBoolean value[])
{ _need_update = true; return fmiOK; }

fmiStatus FMUWrapper::setString(const fmiValueReference vr[], size_t nvr,
    const fmiString  value[])
{ _need_update = true; return fmiOK; }

/*  of the model equations */
fmiStatus FMUWrapper::initialize(fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo& eventInfo)
{
  // TODO: here is some code duplication to SimulationRuntime/cpp/Core/Solver/Initailization.cpp
  _model->init();
  _model->setInitial(true);

  bool restart=true;
  int iter=0;
  while(restart && !(iter++ > 10))
  {
    _model->update(IContinuous::ALL);
    restart = _model->checkForDiscreteEvents();
  }

  _model->saveAll();
  _model->checkConditions(0,true);
 
  _model->setInitial(false);
  _need_update = false;
  // TODO set options for algerbraic solver according to toleranceControlled and relativeTolerance
  eventInfo.terminateSimulation = fmiFalse;
  eventInfo.upcomingTimeEvent = fmiFalse;
  //eventInfo.nextTimeEvent no need to set this for this model
  return fmiOK;
}

fmiStatus FMUWrapper::getEventIndicators(fmiReal eventIndicators[], size_t ni)
{
  updateModel();
  bool conditions[NUMBER_OF_EVENT_INDICATORS];
  _model->giveConditions(conditions);
  _model->giveZeroFunc(eventIndicators);
  for(int i = 0; i < ni; i++)
    if(!conditions[i]) eventIndicators[i] = -eventIndicators[i];
  return fmiOK;
}

// Funktions for reading the values of variables that have a reference by the modelDescription.xml
fmiStatus FMUWrapper::getReal(const fmiValueReference vr[], size_t nvr, fmiReal value[])
{
  updateModel();
  for(size_t i = 0; i < nvr; ++i)
    _model->getReal(vr[i], value[i]);
  return fmiOK;
}

fmiStatus FMUWrapper::getInteger(const fmiValueReference vr[], size_t nvr, fmiInteger value[])
{
  updateModel();
  for(size_t i = 0; i < nvr; ++i)
    _model->getInteger(vr[i], value[i]);
  return fmiOK;
}

fmiStatus FMUWrapper::getBoolean(const fmiValueReference vr[], size_t nvr, fmiBoolean value[])
{
  updateModel();
  for(size_t i = 0; i < nvr; ++i)
    _model->getBoolean(vr[i], (bool&) value[i]);
  return fmiOK;
}

fmiStatus FMUWrapper::getString(const fmiValueReference vr[], size_t nvr, fmiString value[])
{
  updateModel();
//  for(size_t i = 0; i < nvr; ++i)
//TODO    _model->getString(vr[i], value[i]);
  return fmiOK;
}


fmiStatus FMUWrapper::eventUpdate(fmiBoolean intermediateResults,
    fmiEventInfo& eventInfo)
{
  updateModel();
  // Check if an Zero Crossings happend
  double f[NUMBER_OF_EVENT_INDICATORS];
  bool events[NUMBER_OF_EVENT_INDICATORS];
  _model->giveZeroFunc(f);
  for(int i=0; i<NUMBER_OF_EVENT_INDICATORS; i++)
    events[i] = f[i] >= 0;
  // Handle Zero Crossings if nessesary
  bool state_vars_reinitialized = _model->handleSystemEvents(events);
  // everything is done
  eventInfo.iterationConverged = fmiTrue;
  eventInfo.stateValueReferencesChanged = fmiFalse; // will never change for open Modelica Models
  eventInfo.stateValuesChanged = state_vars_reinitialized; // TODO
  eventInfo.terminateSimulation = fmiFalse;
  eventInfo.upcomingTimeEvent = fmiFalse;
  //eventInfo.nextEventTime = _time;
  return fmiOK;
}

fmiStatus FMUWrapper::getNominalContinuousStates(fmiReal x_nominal[], size_t nx)
{
  updateModel();
  for(int i = 0; i < nx; ++i)
    x_nominal[i] = 1.0;
  return fmiOK;
}

fmiStatus FMUWrapper::getStateValueReferences(fmiValueReference vrx[], size_t nx)
{
  updateModel();
  for(int i = 0; i < nx; i++)
    vrx[i] = i;
  return fmiOK;
}

fmiStatus FMUWrapper::terminate()
{
  return fmiOK;
}

fmiStatus FMUWrapper::setExternalFunction(fmiValueReference vr[], size_t nvr, const void* value[])
{
  return fmiOK;
}

