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
    std::vector<fmiReal> _tmp_real_buffer;
    std::vector<fmiInteger> _tmp_int_buffer;
    std::vector<fmiBoolean> _tmp_bool_buffer;
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
      _tmp_real_buffer.resize(_model->getDimReal());
      _tmp_int_buffer.resize(_model->getDimInteger());
      _tmp_bool_buffer.resize(_model->getDimBoolean());
    }

    virtual ~FMUWrapper()
    {
    }

    virtual fmiStatus setDebugLogging  (fmiBoolean loggingOn)
    {
    	Logger::setEnabled(loggingOn);
        return fmiOK;
    }

/*  independent variables and re-initialization of caching */
    virtual fmiStatus setTime                (fmiReal time)
    {
      _model->setTime(time);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus setContinuousStates    (const fmiReal states[], size_t nx)
    {
    	Logger::writeInfo("setContinuousStates called");
      // to set states do the folowing
	  std::stringstream message;
	  message << "Setting continuous states";
	  Logger::writeInfo(message.str());
      _model->setContinuousStates(states);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus completedIntegratorStep(fmiBoolean& callEventUpdate)
    {
      _model->saveAll();
      callEventUpdate = false;
      return fmiOK;
    }

    virtual fmiStatus setReal                (const fmiValueReference vr[], size_t nvr, const fmiReal    value[])
    {
      _model->setReal(vr, nvr, value);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus setInteger             (const fmiValueReference vr[], size_t nvr, const fmiInteger value[])
    {
      _model->setInteger(vr, nvr, value);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus setBoolean             (const fmiValueReference vr[], size_t nvr, const fmiBoolean value[])
    {
      _model->setBoolean(vr, nvr, value);
      _need_update = true;
      return fmiOK;
    }

    virtual fmiStatus setString              (const fmiValueReference vr[], size_t nvr, const fmiString  value[])
    {
      // TODO implement strings
      _need_update = true;
      return fmiOK;
    }

/*  of the model equations */
    virtual fmiStatus initialize(fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo& eventInfo)
    {
      // TODO: here is some code duplication to SimulationRuntime/cpp/Core/Solver/Initailization.cpp
      _model->initialize();
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
      Logger::writeInfo("Initialization completed");
      return fmiOK;
    }

    virtual fmiStatus getDerivatives    (fmiReal derivatives[]    , size_t nx)
    {
	  Logger::writeInfo("Try to get derivatives");
      updateModel();
      _model->getRHS(derivatives);
      return fmiOK;
    }

    virtual fmiStatus getEventIndicators(fmiReal eventIndicators[], size_t ni)
    {
      updateModel();
      bool conditions[NUMBER_OF_EVENT_INDICATORS];
      _model->getConditions(conditions);
      _model->getZeroFunc(eventIndicators);
      for(int i = 0; i < ni; i++)
        if(!conditions[i]) eventIndicators[i] = -eventIndicators[i];
      return fmiOK;
    }

    virtual fmiStatus getReal   (const fmiValueReference vr[], size_t nvr, fmiReal    value[])
    {
      updateModel();
      _model->getReal(vr, nvr, value);
      return fmiOK;
    }

    virtual fmiStatus getInteger(const fmiValueReference vr[], size_t nvr, fmiInteger value[])
    {
      updateModel();
      _model->getInteger(vr, nvr, value);
      return fmiOK;
    }

    virtual fmiStatus getBoolean(const fmiValueReference vr[], size_t nvr, fmiBoolean value[])
    {
      updateModel();
      _model->getBoolean(vr, nvr, value);
      return fmiOK;
    }

    virtual fmiStatus getString (const fmiValueReference vr[], size_t nvr, fmiString  value[])
    {
      updateModel();
    //  for(size_t i = 0; i < nvr; ++i)
    //TODO    _model->getString(vr[i], value[i]);
      return fmiOK;
    }

    virtual fmiStatus eventUpdate               (fmiBoolean intermediateResults, fmiEventInfo& eventInfo)
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
      eventInfo.iterationConverged = fmiTrue;
      eventInfo.stateValueReferencesChanged = fmiFalse; // will never change for open Modelica Models
      eventInfo.stateValuesChanged = state_vars_reinitialized; // TODO
      eventInfo.terminateSimulation = fmiFalse;
      eventInfo.upcomingTimeEvent = fmiFalse;
      //eventInfo.nextEventTime = _time;
      return fmiOK;
    }

    virtual fmiStatus getContinuousStates       (fmiReal states[], size_t nx)
    {
      _model->getContinuousStates(states);
      return fmiOK;
    }

    virtual fmiStatus getNominalContinuousStates(fmiReal x_nominal[], size_t nx)
    {
      updateModel();
      for(int i = 0; i < nx; ++i)
        x_nominal[i] = 1.0;
      return fmiOK;
    }

    virtual fmiStatus getStateValueReferences   (fmiValueReference vrx[], size_t nx)
    {
      updateModel();
      for(int i = 0; i < nx; i++)
        vrx[i] = i;
      return fmiOK;
    }

    virtual fmiStatus terminate                 ()
    {
      return fmiOK;
    }
    virtual fmiStatus setExternalFunction       (fmiValueReference vr[], size_t nvr, const void* value[])
    {
      return fmiOK;
    }
};
