/*
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

/**
 *  \file osi.cpp
 *  \brief Implement OSU
 */

//Cpp Simulation kernel includes
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/IOMSI.h>
#include <Core/SimController/ISimController.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/System/IOMSI.h>

//omsi base includes
#include <omsi_initialization.h>
#include <omsi_getters_and_setters.h>

//omsi cpp inlcudes
#include <omsi_global_settings.h>
#include "omsi_fmi2_log.h"
#include "omsi_fmi2_wrapper.h"
#include "omsi_factory.h"


//3rdparty includes
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

namespace fs = boost::filesystem;

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

IOMSI* OMSICallBackWrapper::_omsu_system;
IOMSIInitialize* OMSICallBackWrapper::_omsu_initialize;

fmi2String OSU::LogCategoryFMUName(LogCategoryFMU category)
{
    return _LogCategoryFMUNames[category];
}


OSU::OSU(fmi2String instanceName, fmi2String GUID,
         const fmi2CallbackFunctions* functions,
         fmi2Boolean visible, fmi2Boolean loggingOn, fmi2String fmuResourceLocations)
    : _functions(*functions),
      _osu_functions(NULL),
      callbackLogger(_functions.logger),
      _conditions(NULL),
      _zero_funcs(NULL),
      _events(NULL),
      _simTime(0.0)

{
    _global_settings = shared_ptr<OMSIGlobalSettings>(new OMSIGlobalSettings());
    fs::path p(instanceName);
    _instanceName = p.stem().string();

    _GUID = GUID;

    // setup logger
    _logCategories = loggingOn ? 0xFFFF : 0x0000;
    LogSettings logSettings = _global_settings->getLogSettings();
    logSettings.setAll(loggingOn ? LL_DEBUG : LL_ERROR);
    FMU2Logger::initialize(this, logSettings, loggingOn);


    // setup model


    /*Todo: only load if type is omsu, not for fmi*/

    /* set global callback functions */
    global_callback = (omsi_callback_functions*)functions;
    global_instance_name = _instanceName.c_str();
    global_callback->componentEnvironment = this;
    //setup omsi callback functions
    _osu_functions = (omsi_template_callback_functions_t*)functions->allocateMemory(
        1, sizeof(omsi_template_callback_functions_t));
    _osu_functions->initialize_initialization_problem = &OMSICallBackWrapper::setUpInitializeFunction;
    _osu_functions->initialize_simulation_problem = &OMSICallBackWrapper::setUpEvaluateFunction;
    _osu_functions->isSet = omsi_true;

    //instantiate omsi_t data structure
    _omsu = omsi_instantiate(_instanceName.c_str(), omsi_model_exchange, GUID, fmuResourceLocations,
                             (omsi_callback_functions *)functions, _osu_functions, visible, loggingOn, &_state);
    //instantiate Modelica system
    _model = createOSUSystem(_global_settings, _instanceName, _omsu);
    //initialize omsi callbacks for right hand side function (evaluate) and initialization function
    if (_omsu_system = dynamic_pointer_cast<IOMSI>(_model))
    {
        OMSICallBackWrapper::setOMSISystem(*(_omsu_system.get()));
    }
    else
        throw std::invalid_argument("Could not initilize OMSI callbacks");
    if (shared_ptr<IOMSIInitialize> omsu_initilize = dynamic_pointer_cast<IOMSIInitialize>(_model))
    {
        OMSICallBackWrapper::setOMSIInitialize(*(omsu_initilize.get()));
    }
    else
        throw std::invalid_argument("Could not initilize OMSI callbacks");
    //initialize omsi function callbacks
    omsi_intialize_callbacks(_omsu, _osu_functions);

    //Initilize systems:
    _initialize_model = dynamic_pointer_cast<ISystemInitialization>(_model);
    _continuous_model = dynamic_pointer_cast<IContinuous>(_model);
    _time_event_model = dynamic_pointer_cast<ITime>(_model);
    _event_model = dynamic_pointer_cast<IEvent>(_model);
    _step_event_system = dynamic_pointer_cast<IStepEvent>(_model);

    //start intialisation of Modelica system
    _initialize_model->initialize();

    _string_buffer.resize(_continuous_model->getDimString());
    _clockTick = new bool[_event_model->getDimClock()];
    _clockSubactive = new bool[_event_model->getDimClock()];
    std::fill(_clockTick, _clockTick + _event_model->getDimClock(), false);
    std::fill(_clockSubactive, _clockSubactive + _event_model->getDimClock(), false);
    _nclockTick = 0;
    unsigned int dimZero = _event_model->getDimZeroFunc();
    if (dimZero > 0)
    {
        _conditions = new bool[dimZero];
        _zero_funcs = new double[dimZero];;
        _events = new bool[dimZero];
    }


    LOG_CALL(this, "OSU instantiation completed");
}

OSU::~OSU()
{
    delete [] _clockSubactive;
    delete [] _clockTick;
    if (_conditions)
        delete [] _conditions;
    if (_zero_funcs)
        delete [] _zero_funcs;
    if (_events)
        delete [] _events;
    omsi_free_model_variables(_omsu->sim_data);
    free(_osu_functions);
}

fmi2Status OSU::setDebugLogging(fmi2Boolean loggingOn,
                                size_t nCategories,
                                const fmi2String categories[])
{
    fmi2Status ret = fmi2OK;
    _logger->setEnabled(loggingOn);
    if (nCategories == 0)
    {
        _logCategories = loggingOn ? 0xFFFF : 0x0000;
        _logger->setAll(loggingOn ? LL_DEBUG : LL_ERROR);
    }
    else
    {
        int i, j, nSupported = sizeof(_LogCategoryFMUNames) / sizeof(fmi2String);
        for (i = 0; i < nCategories; i++)
        {
            if (strcmp(categories[i], "logAll") == 0)
            {
                _logCategories = loggingOn ? 0xFFFF : 0x0000;
                _logger->setAll(loggingOn ? LL_DEBUG : LL_ERROR);
                continue;
            }
            for (j = 0; j < nSupported; j++)
            {
                if (strcmp(categories[i], _LogCategoryFMUNames[j]) == 0)
                {
                    if (loggingOn)
                        _logCategories |= (1 << j);
                    else
                        _logCategories &= ~(1 << j);
                    switch (j)
                    {
                    case logEvents:
                        _logger->set(LC_EVENTS, loggingOn ? LL_DEBUG : LL_ERROR);
                        break;
                    case logNonlinearSystems:
                        _logger->set(LC_NLS, loggingOn ? LL_DEBUG : LL_ERROR);
                        break;
                    }
                    break;
                }
            }
            // warn about unsupported log category
            if (j == nSupported)
            {
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

fmi2Status OSU::setupExperiment(fmi2Boolean toleranceDefined,
                                fmi2Real tolerance,
                                fmi2Real startTime,
                                fmi2Boolean stopTimeDefined,
                                fmi2Real stopTime)
{
    // ToDo: setup tolerance and stop time
    return setTime(startTime);
}

fmi2Status OSU::enterInitializationMode()
{
    _initialize_model->setInitial(true);
    _need_update = true;

    return fmi2OK;
}

fmi2Status OSU::exitInitializationMode()
{
    if (_need_update)
        updateModel();
    _event_model->saveAll();
    _initialize_model->setInitial(false);
    _time_event_model->initTimeEventData();
    return fmi2OK;
}

fmi2Status OSU::terminate()
{
    return fmi2OK;
}

fmi2Status OSU::reset()
{
    _initialize_model->initializeFreeVariables();
    return fmi2OK;
}

void OSU::updateModel()
{
    if (_initialize_model->initial())
    {
        _initialize_model->initializeBoundVariables();
        _event_model->saveAll();
    }
    _continuous_model->evaluateAll(); // derivatives and algebraic variables
    _need_update = false;
}

fmi2Status OSU::setTime(fmi2Real time)
{
    if (_nclockTick > 0)
    {
        std::fill(_clockTick, _clockTick + _event_model->getDimClock(), false);
        std::fill(_clockSubactive, _clockSubactive + _event_model->getDimClock(), false);
        _nclockTick = 0;
    }
    _time_event_model->setTime(time);
    _need_update = true;
    _simTime = time;
    return fmi2OK;
}

fmi2Status OSU::setContinuousStates(const fmi2Real states[], size_t nx)
{
    _continuous_model->setContinuousStates(states);

    /*log disabled
     unsigned int dim_z =   _continuous_model->getDimContinuousStates();
    for (int i = 0; i < dim_z; i++)
    {
        LOG_CALL(this, "new state var %i: %g", i,states[i] );
    }
    */
    _need_update = true;
    return fmi2OK;
}

fmi2Status OSU::getContinuousStates(fmi2Real states[], size_t nx)
{
    _continuous_model->getContinuousStates(states);
    return fmi2OK;
}

fmi2Status OSU::getDerivatives(fmi2Real derivatives[], size_t nx)
{
    if (_need_update)
        updateModel();
    _time_event_model->computeTimeEventConditions(_time_event_model->getTime());
    _continuous_model->getRHS(derivatives);
    return fmi2OK;
}

fmi2Status OSU::completedIntegratorStep(fmi2Boolean noSetFMUStatePriorToCurrentPoint,
                                        fmi2Boolean* enterEventMode,
                                        fmi2Boolean* terminateSimulation)
{
    bool stepCompleted = _step_event_system->stepCompleted(_simTime);
    if (stepCompleted)
    {
        *enterEventMode = fmi2True;
    }
    else
    {
        *enterEventMode = fmi2False;
    }
    *terminateSimulation = fmi2False;
    return fmi2OK;
}

// Functions for setting inputs and start values
fmi2Status OSU::setReal(const fmi2ValueReference vr[], size_t nvr,
                        const fmi2Real value[])
{
    omsi_status status = omsi_set_real(_omsu, vr, nvr, value);
    if (status)
        throw std::invalid_argument("getReal with wrong real vars memory allocation");
    _need_update = true;
    return fmi2OK;
}

fmi2Status OSU::setInteger(const fmi2ValueReference vr[], size_t nvr,
                           const fmi2Integer value[])
{
    omsi_status status = omsi_set_integer(_omsu, vr, nvr, value);
    if (status)
        throw std::invalid_argument("setInt with wrong Integer vars memory allocation");
    _need_update = true;
    return fmi2OK;
}

fmi2Status OSU::setBoolean(const fmi2ValueReference vr[], size_t nvr,
                           const fmi2Boolean value[])
{
    omsi_status status = omsi_set_boolean(_omsu, vr, nvr, value);
    if (status)
        throw std::invalid_argument("setBool with wrong Boolean vars memory allocation");
    _need_update = true;
    return fmi2OK;
}

fmi2Status OSU::setString(const fmi2ValueReference vr[], size_t nvr,
                          const fmi2String value[])
{
    //if (nvr > _string_buffer.size()) {
    //  FMU2_LOG(this, fmi2Error, logStatusError,
    //           "Attempt to set %d fmi2String; FMU only has %d",
    //           nvr, _string_buffer.size());
    //  return fmi2Error;
    //}
    //for (size_t i = 0; i < nvr; i++)
    //  _string_buffer[i] = string(value[i]); // convert to string


    omsi_status status = omsi_set_string(_omsu, vr, nvr, value);
    if (!status)
        throw std::invalid_argument("setString with wrong string vars memory allocation");
    _need_update = true;
    return fmi2OK;
}

fmi2Status OSU::setClock(const fmi2Integer clockIndex[],
                         size_t nClockIndex, const fmi2Boolean tick[],
                         const fmi2Boolean subactive[])
{
    for (int i = 0; i < nClockIndex; i++)
    {
        _clockTick[clockIndex[i] - 1] = tick[i];
        if (subactive != NULL)
            _clockSubactive[clockIndex[i] - 1] = subactive[i];
    }
    _nclockTick = 0;
    for (int i = 0; i < _event_model->getDimClock(); i++)
    {
        _nclockTick += _clockTick[i] ? 1 : 0;
    }
    _need_update = true;
    return fmi2OK;
}

fmi2Status OSU::setInterval(const fmi2Integer clockIndex[],
                            size_t nClockIndex, const fmi2Real interval[])
{
    double* clockInterval = _event_model->clockInterval();
    for (int i = 0; i < nClockIndex; i++)
    {
        clockInterval[clockIndex[i] - 1] = interval[i];
        _event_model->setIntervalInTimEventData((clockIndex[i] - 1), interval[i]);
    }
    _need_update = true;
    return fmi2OK;
}

fmi2Status OSU::getEventIndicators(fmi2Real eventIndicators[], size_t ni)
{
    if (_need_update)
        updateModel();
    _event_model->getConditions(_conditions);
    _event_model->getZeroFunc(eventIndicators);
    for (int i = 0; i < ni; i++)
        if (!_conditions[i]) eventIndicators[i] = -eventIndicators[i];
    return fmi2OK;
}

// Functions for reading the values of variables
fmi2Status OSU::getReal(const fmi2ValueReference vr[], size_t nvr,
                        fmi2Real value[])
{
    if (_need_update)
        updateModel();
    omsi_status status = omsi_get_real(_omsu, vr, nvr, value);
    if (status)
        throw std::invalid_argument("getReal with wrong real vars memory allocation");

    return fmi2OK;
}

fmi2Status OSU::getInteger(const fmi2ValueReference vr[], size_t nvr,
                           fmi2Integer value[])
{
    if (_need_update)
        updateModel();
    omsi_status status = omsi_get_integer(_omsu, vr, nvr, value);
    if (status)
        throw std::invalid_argument("getInteger with wrong int vars memory allocation");


    return fmi2OK;
}

fmi2Status OSU::getBoolean(const fmi2ValueReference vr[], size_t nvr,
                           fmi2Boolean value[])
{
    if (_need_update)
        updateModel();
    omsi_status status = omsi_get_boolean(_omsu, vr, nvr, value);
    if (status)
        throw std::invalid_argument("getBoolean with wrong bool vars memory allocation");
    return fmi2OK;
}

fmi2Status OSU::getString(const fmi2ValueReference vr[], size_t nvr,
                          fmi2String value[])
{
    if (_need_update)
        updateModel();

    omsi_status status = omsi_get_string(_omsu, vr, nvr, value);
    if (status)
        throw std::invalid_argument("getString with wrong string vars memory allocation");

    /*for (size_t i = 0; i < nvr; i++)
      value[i] = _string_buffer[i].c_str(); // convert to fmi2String*/
    return fmi2OK;
}

fmi2Status OSU::getClock(const fmi2Integer clockIndex[],
                         size_t nClockIndex, fmi2Boolean tick[])
{
    for (int i = 0; i < nClockIndex; i++)
    {
        tick[i] = _clockTick[clockIndex[i] - 1];
    }
    return fmi2OK;
}

fmi2Status OSU::getInterval(const fmi2Integer clockIndex[],
                            size_t nClockIndex, fmi2Real interval[])
{
    double* clockInterval = _event_model->clockInterval();
    for (int i = 0; i < nClockIndex; i++)
    {
        interval[i] = clockInterval[clockIndex[i] - 1];
    }
    return fmi2OK;
}

fmi2Status OSU::newDiscreteStates(fmi2EventInfo* eventInfo)
{
    if (_need_update)
    {
        if (_nclockTick > 0)
            _event_model->setClock(_clockTick, _clockSubactive);
        updateModel();
        if (_nclockTick > 0)
        {
            // reset clocks
            std::fill(_clockTick, _clockTick + _event_model->getDimClock(), false);
            std::fill(_clockSubactive, _clockSubactive + _event_model->getDimClock(), false);
            _nclockTick = 0;
        }
    }
    // Check if an Zero Crossings happend

    _event_model->getZeroFunc(_zero_funcs);
    for (int i = 0; i < _event_model->getDimZeroFunc(); i++)
        _events[i] = _zero_funcs[i] >= 0;
    LOG_CALL(this, "start event iteration at time %g", _simTime);
    /*disabled log
    for (int i = 0; i < _event_model->getDimZeroFunc(); i++)
    {
      _events[i] = _zero_funcs[i] >= 0;
       LOG_CALL(this, "with event indicator %i: %d", i,_events[i] );
    }
     bool* boolvars = _model->getSimObjects()->getSimVars(_model->getModelName())->getBoolVarsVector();
     unsigned int dimbool = _continuous_model->getDimBoolean();
     for (int i = 0; i < dimbool; i++)
     {
         LOG_CALL(this, "bevor event iteration boolean var %i: %d", i,boolvars[i] );
     } */
    // Handle Zero Crossings if nessesary
    bool state_vars_reinitialized = _model->handleSystemEvents(_events);
    /*disabled log
    for (int i = 0; i < dimbool; i++)
    {
        LOG_CALL(this, "after event iteration boolean var %i: %d", i,boolvars[i] );
    }
    unsigned int dim_z =   _continuous_model->getDimContinuousStates();
    double*  zvars = new double[dim_z];
    _continuous_model->getContinuousStates(zvars);
    for (int i = 0; i < dim_z; i++)
    {
        LOG_CALL(this, "after event iteration state var %i: %g", i,zvars[i] );
    }
    delete [] zvars;
    */
    //time events
    eventInfo->nextEventTime = _time_event_model->computeNextTimeEvents(_time_event_model->getTime());
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

fmi2Status OSU::getNominalsOfContinuousStates(fmi2Real x_nominal[], size_t nx)
{
    for (int i = 0; i < nx; i++)
        x_nominal[i] = 1.0; // TODO
    return fmi2OK;
}

/** @} */ // end of fmu2


/*old init file*/
/*
fs::path model_name_path(_model->getModelName() + ("_init.xml"));
fs::path init_file_path = fs::path(fmuResourceLocations);
init_file_path /= model_name_path;
_global_settings->setInitfilePath(init_file_path.string());
*/
