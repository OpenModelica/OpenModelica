#pragma once
#include <iostream>
#include <vector>
#include <assert.h>
#include <FMU/IFMUInterface.h>
#include <FMU/FMUGlobalSettings.h>
#include <FMU/FMULogger.h>
#include <Core/System/AlgLoopSolverFactory.h>

// build MODEL_CLASS from MODEL_IDENTIFIER
#define FMU_PASTER(a, b) a ## b
#define FMU_CONCAT(a, b) FMU_PASTER(a, b)
#define MODEL_CLASS FMU_CONCAT(MODEL_IDENTIFIER_SHORT, FMU)

class FMUWrapper : public IFMUInterface
{
private:
    FMUGlobalSettings _global_settings;
    boost::shared_ptr<MODEL_CLASS> _model;
    double _need_update;

    void updateModel()
    {
      // only call update if, time, states or imputs changed
      if(!_need_update)
        return;

      //Logger::writeInfo("Update completed");
      _model->evaluateAll(); // This will calculate the values for derivate variables, algebraic variables
      _need_update = false;
    }

public:
    FMUWrapper(fmiString instanceName, fmiString GUID, fmiCallbackFunctions functions, fmiBoolean loggingOn) : IFMUInterface(instanceName, GUID, functions, loggingOn), _need_update(true)
    {
      FMULogger::initialize(functions.logger, this, instanceName);
      boost::shared_ptr<IAlgLoopSolverFactory>
          solver_factory(new AlgLoopSolverFactory(&_global_settings,PATH(""),PATH("")));
      _model = boost::shared_ptr<MODEL_CLASS>(new MODEL_CLASS(&_global_settings, solver_factory, boost::shared_ptr<ISimData>(new SimData()), boost::shared_ptr<ISimVars>(MODEL_SIMVARS_FACTORY())));
      _model->setInitial(true);
    }

    virtual ~FMUWrapper()
    {
    }

    virtual fmiStatus setDebugLogging(fmiBoolean loggingOn)
    {
      Logger::write("Debug logging set to " + boost::lexical_cast<std::string>((int)loggingOn),LC_OTHER,LL_INFO);
      Logger::setEnabled(loggingOn);
      return fmiOK;
    }

    virtual fmiStatus setTime(fmiReal time)
    {
      Logger::write("Set time to " + boost::lexical_cast<std::string>(time),LC_OTHER,LL_DEBUG);
      _model->setTime(time);
      Logger::write("Set time finished",LC_OTHER,LL_DEBUG);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus setContinuousStates(const fmiReal states[], size_t nx)
    {
      // to set states do the folowing
      Logger::write("Set continuous states (number of states: " + boost::lexical_cast<std::string>(nx) + ")",LC_OTHER,LL_DEBUG);

      for(size_t i = 0; i < nx; i++)
        Logger::write("  Set continuous state " + boost::lexical_cast<std::string>(i) + " to " + boost::lexical_cast<std::string>(states[i]),LC_OTHER,LL_DEBUG);

      _model->setContinuousStates(states);
      Logger::write("Set continuous states finished",LC_OTHER,LL_DEBUG);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus completedIntegratorStep(fmiBoolean& callEventUpdate)
    {
      Logger::write("Completed integrator step",LC_OTHER,LL_DEBUG);
      _model->saveAll();
      callEventUpdate = false;
      Logger::write("Completed integrator step finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setReal(const fmiValueReference vr[], size_t nvr, const fmiReal    value[])
    {
      Logger::write("Set real values",LC_OTHER,LL_DEBUG);
      for(size_t i = 0; i < nvr; i++)
        Logger::write("  Set real value " + boost::lexical_cast<std::string>(vr[i]) + " to " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);
      _model->setReal(vr, nvr, value);
      _need_update = true;
      Logger::write("Set real values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setInteger(const fmiValueReference vr[], size_t nvr, const fmiInteger value[])
    {
      Logger::write("Set int values",LC_OTHER,LL_DEBUG);
      for(size_t i = 0; i < nvr; i++)
        Logger::write("  Set int value " + boost::lexical_cast<std::string>(vr[i]) + " to " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);
      _model->setInteger(vr, nvr, value);
      _need_update = true;
      Logger::write("Set int values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setBoolean(const fmiValueReference vr[], size_t nvr, const fmiBoolean value[])
    {
      Logger::write("Set bool values",LC_OTHER,LL_DEBUG);
      int val;
      for (size_t i = 0; i < nvr; i++) {
        val = value[i];
        Logger::write("  Set bool value " + boost::lexical_cast<std::string>(vr[i]) + " to " + boost::lexical_cast<std::string>(val),LC_OTHER,LL_DEBUG);
        _model->setBoolean(vr + i, 1, &val);
      }
      _need_update = true;
      Logger::write("Set bool values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus setString(const fmiValueReference vr[], size_t nvr, const fmiString  value[])
    {
      Logger::write("Set string values",LC_OTHER,LL_DEBUG);
      // TODO implement strings
      _need_update = true;
      Logger::write("Set string finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus initialize(fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo& eventInfo)
    {
      Logger::write("Initialize",LC_OTHER,LL_DEBUG);
      // TODO: here is some code duplication to SimulationRuntime/cpp/Core/Solver/Initailization.cpp
      _model->initialize();
      _model->initializeBoundVariables();
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
      eventInfo.upcomingTimeEvent = fmiFalse;
      //eventInfo.nextTimeEvent no need to set this for this model
      Logger::write("Initialize completed",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getDerivatives(fmiReal derivatives[]    , size_t nx)
    {
      Logger::write("Get derivatives (number of derivatives: " + boost::lexical_cast<std::string>(nx) + ")",LC_OTHER,LL_DEBUG);
      updateModel();
      _model->getRHS(derivatives);

      for(size_t i = 0; i < nx; i++)
        Logger::write("  Get derivative " + boost::lexical_cast<std::string>(i) + " with value " + boost::lexical_cast<std::string>(derivatives[i]),LC_OTHER,LL_DEBUG);

      Logger::write("Get derivatives finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getEventIndicators(fmiReal eventIndicators[], size_t ni)
    {
      Logger::write("Get event indicators (number of event indicators: " + boost::lexical_cast<std::string>(ni) + ")",LC_OTHER,LL_DEBUG);
      updateModel();
      bool conditions[NUMBER_OF_EVENT_INDICATORS];
      _model->getConditions(conditions);
      _model->getZeroFunc(eventIndicators);
      for(int i = 0; i < ni; i++)
      {
        if(!conditions[i])
          eventIndicators[i] = -eventIndicators[i];
        Logger::write("  Get event indicator " + boost::lexical_cast<std::string>(i) + " with value " + boost::lexical_cast<std::string>(eventIndicators[i]),LC_OTHER,LL_DEBUG);
      }
      Logger::write("Get event indicators finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getReal(const fmiValueReference vr[], size_t nvr, fmiReal    value[])
    {
      Logger::write("Get real values",LC_OTHER,LL_DEBUG);
      updateModel();
      _model->getReal(vr, nvr, value);

      for(size_t i = 0; i < nvr; i++)
        Logger::write("  Get real " + boost::lexical_cast<std::string>(vr[i]) + " with value " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);

      Logger::write("Get real values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getInteger(const fmiValueReference vr[], size_t nvr, fmiInteger value[])
    {
      Logger::write("Get int values",LC_OTHER,LL_DEBUG);
      updateModel();
      _model->getInteger(vr, nvr, value);

      for(size_t i = 0; i < nvr; i++)
        Logger::write("  Get int " + boost::lexical_cast<std::string>(vr[i]) + " with value " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);

      Logger::write("Get int values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getBoolean(const fmiValueReference vr[], size_t nvr, fmiBoolean value[])
    {
      Logger::write("Get bool values",LC_OTHER,LL_DEBUG);
      int val;
      updateModel();
      for (size_t i = 0; i < nvr; i++) {
        _model->getBoolean(vr + i, 1, &val);
        Logger::write("  Get bool " + boost::lexical_cast<std::string>(vr[i]) + " with value " + boost::lexical_cast<std::string>(value[i]),LC_OTHER,LL_DEBUG);
        value[i] = (fmiBoolean)val;
      }
      Logger::write("Get bool values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getString(const fmiValueReference vr[], size_t nvr, fmiString  value[])
    {
      Logger::write("Get string values",LC_OTHER,LL_DEBUG);
      updateModel();
    //  for(size_t i = 0; i < nvr; ++i)
    //TODO    _model->getString(vr[i], value[i]);
      Logger::write("Get string values finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus eventUpdate(fmiBoolean intermediateResults, fmiEventInfo& eventInfo)
    {
      Logger::write("Event update",LC_OTHER,LL_DEBUG);
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
      eventInfo.iterationConverged = fmiTrue;
      eventInfo.stateValueReferencesChanged = fmiFalse; // will never change for open Modelica Models
      eventInfo.stateValuesChanged = state_vars_reinitialized; // TODO
      eventInfo.terminateSimulation = fmiFalse;
      eventInfo.upcomingTimeEvent = fmiFalse;
      //eventInfo.nextEventTime = _time;
      Logger::write("Event update finished",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }

    virtual fmiStatus getContinuousStates       (fmiReal states[], size_t nx)
    {
      Logger::write("Get continuous states",LC_OTHER,LL_DEBUG);
      _model->getContinuousStates(states);

      for(size_t i = 0; i < nx; i++)
        Logger::write("  Get continuous state " + boost::lexical_cast<std::string>(i) + " with value " + boost::lexical_cast<std::string>(states[i]),LC_OTHER,LL_DEBUG);

      Logger::write("Get continuous states finished",LC_OTHER,LL_DEBUG);
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
      Logger::write("Terminate",LC_OTHER,LL_DEBUG);
      return fmiOK;
    }
    virtual fmiStatus setExternalFunction(fmiValueReference vr[], size_t nvr, const void* value[])
    {
      Logger::write("SetExternalFunction not implemented!",LC_OTHER,LL_WARNING);
      return fmiOK;
    }
};
