#pragma once
#include <iostream>
#include <vector>
#include <assert.h>
#include <FMU/IFMUInterface.h>
#include <FMU/FMUGlobalSettings.h>
#include <FMU/FMULogger.h>
#include <Core/SimController/ISimObjects.h>

class FMUWrapper : public IFMUInterface
{
private:
    FMUGlobalSettings _global_settings;
    MODEL_CLASS *_model;
    double _need_update;

    void updateModel()
    {
      // only call update if, time, states or imputs changed
      if(!_need_update)
        return;

      //LOGGER_WRITE("Update completed",LC_OTHER,LL_INFO);
      _model->evaluateAll(); // This will calculate the values for derivate variables, algebraic variables
      _need_update = false;
    }

public:
    FMUWrapper(fmiString instanceName, fmiString GUID, fmiCallbackFunctions functions, fmiBoolean loggingOn) : IFMUInterface(instanceName, GUID, functions, loggingOn), _need_update(true)
    {
      //FMULogger::initialize(functions.logger, this, instanceName);
      _model = createSystemFMU(&_global_settings);
      _model->setInitial(true);
    }

    virtual ~FMUWrapper()
    {
      delete _model;
    }

    virtual fmiStatus setDebugLogging(fmiBoolean loggingOn)
    {
      //LOGGER_WRITE("Debug logging set to " + boost::lexical_cast<std::string>((int)loggingOn),LC_OTHER,LL_INFO);
      Logger::setEnabled(loggingOn);
      return fmiOK;
    }

    virtual fmiStatus setTime(fmiReal time)
    {
      //LOGGER_WRITE("Set time to " + boost::lexical_cast<std::string>(time),LC_OTHER,LL_DEBUG);
      _model->setTime(time);
      //LOGGER_WRITE("Set time finished",LC_OTHER,LL_DEBUG);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus setContinuousStates(const fmiReal states[], size_t nx)
    {
      // to set states do the folowing
      //LOGGER_WRITE("Set continuous states (number of states: " + boost::lexical_cast<std::string>(nx) + ")",LC_OTHER,LL_DEBUG);

      //for(size_t i = 0; i < nx; i++)
      //  LOGGER_WRITE("  Set continuous state " + boost::lexical_cast<std::string>(i) + " to " + boost::lexical_cast<std::string>(states[i]),LC_OTHER,LL_DEBUG);

      _model->setContinuousStates(states);
      //LOGGER_WRITE("Set continuous states finished",LC_OTHER,LL_DEBUG);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus completedIntegratorStep(fmiBoolean& callEventUpdate)
    {
      //LOGGER_WRITE("Completed integrator step",LC_OTHER,LL_DEBUG);
      _model->saveAll();
      callEventUpdate = false;
      //LOGGER_WRITE("Completed integrator step finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setReal(const fmiValueReference vr[], size_t nvr, const fmiReal    value[])
    {
      //LOGGER_WRITE("Set real values",LC_OTHER,LL_DEBUG);
      //for(size_t i = 0; i < nvr; i++)
      //  LOGGER_WRITE("  Set real value " + boost::lexical_cast<std::string>(vr[i]) + " to " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);
      if(_model->initial())
      {
        double *realVars = _model->getSimVars()->getRealVarsVector();
        for(size_t i = 0; i < nvr; i++)
          _model->setRealStartValue(realVars[vr[i]], value[i]);
      }
      else
        _model->setReal(vr, nvr, value);

      _need_update = true;
      //LOGGER_WRITE("Set real values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setInteger(const fmiValueReference vr[], size_t nvr, const fmiInteger value[])
    {
      //LOGGER_WRITE("Set int values",LC_OTHER,LL_DEBUG);
      //for(size_t i = 0; i < nvr; i++)
      //  LOGGER_WRITE("  Set int value " + boost::lexical_cast<std::string>(vr[i]) + " to " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);
      if(_model->initial())
      {
        int *intVars = _model->getSimVars()->getIntVarsVector();
        for(size_t i = 0; i < nvr; i++)
          _model->setIntStartValue(intVars[vr[i]], value[i]);
      }
      else
        _model->setInteger(vr, nvr, value);

      _need_update = true;
      //LOGGER_WRITE("Set int values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setBoolean(const fmiValueReference vr[], size_t nvr, const fmiBoolean value[])
    {
      //LOGGER_WRITE("Set bool values",LC_OTHER,LL_DEBUG);
      if(_model->initial())
      {
        bool *boolVars = _model->getSimVars()->getBoolVarsVector();
        for(size_t i = 0; i < nvr; i++)
          _model->setBoolStartValue(boolVars[vr[i]], value[i]);
      }
      else
      {
        int val;
        for(size_t i = 0; i < nvr; i++)
        {
          val = value[i];
          _model->setBoolean(vr + i, 1, &val);
        }
      }

      _need_update = true;
      //LOGGER_WRITE("Set bool values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setString(const fmiValueReference vr[], size_t nvr, const fmiString  value[])
    {
      //LOGGER_WRITE("Set string values",LC_OTHER,LL_DEBUG);
      // TODO implement strings
      _need_update = true;
      //LOGGER_WRITE("Set string finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus initialize(fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo& eventInfo)
    {
      //LOGGER_WRITE("Initialize",LC_OTHER,LL_DEBUG);
      Logger::write("Initializing memory and variables", LC_MODEL, LL_DEBUG);
      _model->initializeMemory();
      _model->initializeFreeVariables();
      _model->initializeBoundVariables();
      _model->saveAll();

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
      // TODO set options for algerbraic solver according to toleranceControlled and relativeTolerance
      eventInfo.terminateSimulation = fmiFalse;
      //time events
      _model->initTimeEventData();
      eventInfo.nextEventTime = _model->computeNextTimeEvents(_model->getTime());
      if (eventInfo.nextEventTime > 0)
        eventInfo.upcomingTimeEvent = fmiTrue;
      else
        eventInfo.upcomingTimeEvent = fmiFalse;
      //eventInfo.nextTimeEvent no need to set this for this model
      //LOGGER_WRITE("Initialize completed",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getDerivatives(fmiReal derivatives[]    , size_t nx)
    {
      //LOGGER_WRITE("Get derivatives (number of derivatives: " + boost::lexical_cast<std::string>(nx) + ")",LC_OTHER,LL_DEBUG);
      updateModel();
      _model->computeTimeEventConditions(_model->getTime());
      _model->getRHS(derivatives);

      //for(size_t i = 0; i < nx; i++)
      //  LOGGER_WRITE("  Get derivative " + boost::lexical_cast<std::string>(i) + " with value " + boost::lexical_cast<std::string>(derivatives[i]),LC_OTHER,LL_DEBUG);

      //LOGGER_WRITE("Get derivatives finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getEventIndicators(fmiReal eventIndicators[], size_t ni)
    {
      //LOGGER_WRITE("Get event indicators (number of event indicators: " + boost::lexical_cast<std::string>(ni) + ")",LC_OTHER,LL_DEBUG);
      updateModel();
      bool conditions[NUMBER_OF_EVENT_INDICATORS];
      _model->getConditions(conditions);
      _model->getZeroFunc(eventIndicators);
      for(int i = 0; i < ni; i++)
      {
        if(!conditions[i])
          eventIndicators[i] = -eventIndicators[i];
        //LOGGER_WRITE("  Get event indicator " + boost::lexical_cast<std::string>(i) + " with value " + boost::lexical_cast<std::string>(eventIndicators[i]),LC_OTHER,LL_DEBUG);
      }
      //LOGGER_WRITE("Get event indicators finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getReal(const fmiValueReference vr[], size_t nvr, fmiReal    value[])
    {
      //LOGGER_WRITE("Get real values",LC_OTHER,LL_DEBUG);
      updateModel();
      _model->getReal(vr, nvr, value);

      //for(size_t i = 0; i < nvr; i++)
      //  LOGGER_WRITE("  Get real " + boost::lexical_cast<std::string>(vr[i]) + " with value " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);

      //LOGGER_WRITE("Get real values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getInteger(const fmiValueReference vr[], size_t nvr, fmiInteger value[])
    {
      //LOGGER_WRITE("Get int values",LC_OTHER,LL_DEBUG);
      updateModel();
      _model->getInteger(vr, nvr, value);

      //for(size_t i = 0; i < nvr; i++)
      //  LOGGER_WRITE("  Get int " + boost::lexical_cast<std::string>(vr[i]) + " with value " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);

      //LOGGER_WRITE("Get int values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getBoolean(const fmiValueReference vr[], size_t nvr, fmiBoolean value[])
    {
      //LOGGER_WRITE("Get bool values",LC_OTHER,LL_DEBUG);
      int val;
      updateModel();
      for (size_t i = 0; i < nvr; i++) {
        _model->getBoolean(vr + i, 1, &val);
        //LOGGER_WRITE("  Get bool " + boost::lexical_cast<std::string>(vr[i]) + " with value " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);
        value[i] = (fmiBoolean)val;
      }
      //LOGGER_WRITE("Get bool values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getString(const fmiValueReference vr[], size_t nvr, fmiString  value[])
    {
      //LOGGER_WRITE("Get string values",LC_OTHER,LL_DEBUG);
      updateModel();
    //  for(size_t i = 0; i < nvr; ++i)
    //TODO    _model->getString(vr[i], value[i]);
      //LOGGER_WRITE("Get string values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus eventUpdate(fmiBoolean intermediateResults, fmiEventInfo& eventInfo)
    {
      //LOGGER_WRITE("Event update",LC_OTHER,LL_DEBUG);
      updateModel();
      // Check if an Zero Crossings happend
      double f[NUMBER_OF_EVENT_INDICATORS];
      bool events[NUMBER_OF_EVENT_INDICATORS];
      _model->getZeroFunc(f);
      for(int i=0; i<NUMBER_OF_EVENT_INDICATORS; i++)
        events[i] = f[i] >= 0;
      // Handle Zero Crossings if nessesary
      bool state_vars_reinitialized = _model->handleSystemEvents(events);
      //time events
      eventInfo.nextEventTime = _model->computeNextTimeEvents(_model->getTime());
      if ((eventInfo.nextEventTime != 0.0) && (eventInfo.nextEventTime != std::numeric_limits<double>::max()))
        eventInfo.upcomingTimeEvent = fmiTrue;
      else
        eventInfo.upcomingTimeEvent = fmiFalse;
      // everything is done
      eventInfo.iterationConverged = fmiTrue;
      eventInfo.stateValueReferencesChanged = fmiFalse; // will never change for open Modelica Models
      eventInfo.stateValuesChanged = state_vars_reinitialized; // TODO
      eventInfo.terminateSimulation = fmiFalse;
      //LOGGER_WRITE("Event update finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getContinuousStates       (fmiReal states[], size_t nx)
    {
      //LOGGER_WRITE("Get continuous states",LC_OTHER,LL_DEBUG);
      _model->getContinuousStates(states);

      //for(size_t i = 0; i < nx; i++)
      //  LOGGER_WRITE("  Get continuous state " + boost::lexical_cast<std::string>(i) + " with value " + boost::lexical_cast<std::string>(states[i]),LC_OTHER,LL_DEBUG);

      //LOGGER_WRITE("Get continuous states finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getNominalContinuousStates(fmiReal x_nominal[], size_t nx)
    {
      updateModel();
      for(int i = 0; i < nx; ++i)
        x_nominal[i] = 1.0;
      return fmiOK;
    }

    virtual fmiStatus getStateValueReferences(fmiValueReference vrx[], size_t nx)
    {
      updateModel();
      for(int i = 0; i < nx; i++)
        vrx[i] = i;
      return fmiOK;
    }

    virtual fmiStatus terminate()
    {
      //LOGGER_WRITE("Terminate",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }
    virtual fmiStatus setExternalFunction(fmiValueReference vr[], size_t nvr, const void* value[])
    {
      //LOGGER_WRITE("SetExternalFunction not implemented!",LC_OTHER,LL_WARNING);
      return fmiOK;
    }
};
