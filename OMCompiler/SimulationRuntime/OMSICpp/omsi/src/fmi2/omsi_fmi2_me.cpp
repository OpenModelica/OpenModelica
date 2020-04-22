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
 *  \brief Brief
 */

//Cpp Simulation kernel includes
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/IOMSI.h>
#include <Core/SimController/ISimController.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#ifdef RUNTIME_STATIC_LINKING
  #include <SimCoreFactory/OMCFactory/StaticOMCFactory.h>
#endif


//OpenModelica Simulation Interface
#include <omsi.h>
#include <omsi_global_settings.h>
#include <fmi2/omsi_fmi2_me.h>
#include <fmi2/detail/omsi_fmi2_log.h>
#include <fmi2/detail/omsi_fmi2_wrapper.h>
#include "fmi2Functions.h"


extern "C" {

fmi2Component omsi_fmi2_instantiate(fmi2String instanceName,
                                    fmi2Type fmuType,
                                    fmi2String fmuGUID,
                                    fmi2String fmuResourceLocation,
                                    const fmi2CallbackFunctions* functions,
                                    fmi2Boolean visible,
                                    fmi2Boolean loggingOn)
{
    fmi2Component component;
    fmi2Integer retval;
    if (fmuType == fmi2ModelExchange)
    {
        component = omsi_fmi2_me_instantiate(instanceName, fmuType, fmuGUID, fmuResourceLocation, functions, visible,
                                             loggingOn);
    }
    else if (fmuType == fmi2CoSimulation)
    {
        component = NULL;
    }
    else
    {
        component = NULL;
    }
    return component;
}

fmi2Status omsi_fmi2_set_debug_logging(fmi2Component c, fmi2Boolean loggingOn, size_t nCategories,
                                       const fmi2String categories[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetDebugLogging(%s, nCategories = %d)",
             loggingOn ? "true" : "false", nCategories);
    try
    {
        return osu->setDebugLogging(loggingOn, nCategories, categories);
    }
    CATCH_EXCEPTION(osu);
}

void omsi_fmi2_free_instance(fmi2Component c)
{
    if (((fmi2_me_t*)c)->fmu_type == fmi2ModelExchange)
    {
        omsi_fmi2_me_free_instance(c);
    }
    else if (((fmi2_me_t*)c)->fmu_type == fmi2CoSimulation)
    {
        //not yet supported
    }
}

fmi2Status omsi_fmi2_setup_experiment(fmi2Component c,
                                      fmi2Boolean toleranceDefined,
                                      fmi2Real tolerance,
                                      fmi2Real startTime,
                                      fmi2Boolean stopTimeDefined,
                                      fmi2Real stopTime)
{
    fmi2Status retval;

    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetupExperiment(startTime = %g)", startTime);
    try
    {
        return osu->setupExperiment(toleranceDefined, tolerance, startTime,
                                    stopTimeDefined, stopTime);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_enter_initialization_mode(fmi2Component c)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2EnterInitializationMode");
    try
    {
        return osu->enterInitializationMode();
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_exit_initialization_mode(fmi2Component c)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2ExitInitializationMode");
    try
    {
        return osu->exitInitializationMode();
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_terminate(fmi2Component c)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2Terminate");
    try
    {
        return osu->terminate();
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_reset(fmi2Component c)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2Reset");
    try
    {
        return osu->reset();
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_real(fmi2Component c, const fmi2ValueReference vr[],
                              size_t nvr, fmi2Real value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetReal(nvr = %d)", nvr);
    try
    {
        return osu->getReal(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_integer(fmi2Component c, const fmi2ValueReference vr[],
                                 size_t nvr, fmi2Integer value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetInteger(nvr = %d)", nvr);
    try
    {
        return osu->getInteger(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_boolean(fmi2Component c, const fmi2ValueReference vr[],
                                 size_t nvr, fmi2Boolean value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetBoolean(nvr = %d)", nvr);
    try
    {
        return osu->getBoolean(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_string(fmi2Component c, const fmi2ValueReference vr[],
                                size_t nvr, fmi2String value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetString(nvr = %d)", nvr);
    try
    {
        return osu->getString(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_set_real(fmi2Component c, const fmi2ValueReference vr[],
                              size_t nvr, const fmi2Real value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetReal(nvr = %d)", nvr);
    try
    {
        return osu->setReal(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_set_integer(fmi2Component c, const fmi2ValueReference vr[],
                                 size_t nvr, const fmi2Integer value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetInteger(nvr = %d)", nvr);
    try
    {
        return osu->setInteger(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_set_boolean(fmi2Component c, const fmi2ValueReference vr[],
                                 size_t nvr, const fmi2Boolean value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetBoolean(nvr = %d)", nvr);
    try
    {
        return osu->setBoolean(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_set_string(fmi2Component c, const fmi2ValueReference vr[],
                                size_t nvr, const fmi2String value[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetString(nvr = %d)", nvr);
    try
    {
        return osu->setString(vr, nvr, value);
    }
    CATCH_EXCEPTION(osu);
    return fmi2Warning;
}


fmi2Status omsi_fmi2_get_fmu_state(fmi2Component c, fmi2FMUstate* FMUstate)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetFMUstate not implemented");
    return fmi2Error;
}

fmi2Status omsi_fmi2_set_fmu_state(fmi2Component c, fmi2FMUstate FMUstate)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetFMUstate not implemented");
    return fmi2Error;
}

fmi2Status omsi_fmi2_free_fmu_state(fmi2Component c, fmi2FMUstate* FMUstate)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2FreeFMUstate not implemented");
    return fmi2Error;
}

fmi2Status omsi_fmi2_serialized_fmu_state_size(fmi2Component c, fmi2FMUstate FMUstate,
                                               size_t* size)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SerializedFMUstateSize not implemented");
    return fmi2Error;
}

fmi2Status omsi_fmi2_serialize_fmu_state(fmi2Component c, fmi2FMUstate FMUstate,
                                         fmi2Byte serializedState[], size_t size)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SerializeFMUstate not implemented");
    return fmi2Error;
}

fmi2Status omsi_fmi2_de_serialize_fmu_state(fmi2Component c,
                                            const fmi2Byte serializedState[],
                                            size_t size, fmi2FMUstate* FMUstate)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2DeSerializeFMUstate not implemented");
    return fmi2Error;
}

fmi2Status omsi_fmi2_get_directional_derivative(fmi2Component c,
                                                const fmi2ValueReference vUnknown_ref[], size_t nUnknown,
                                                const fmi2ValueReference vKnown_ref[], size_t nKnown,
                                                const fmi2Real dvKnown[], fmi2Real dvUnknown[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetDirectionalDerivative not implemented");
    return fmi2Error;
}

fmi2Status omsi_fmi2_enter_event_mode(fmi2Component c)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2EnterEventMode");
    return fmi2OK;
}

fmi2Status omsi_fmi2_new_discrete_state(fmi2Component c, fmi2EventInfo* fmiEventInfo)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2NewDiscreteStates");
    try
    {
        return osu->newDiscreteStates(fmiEventInfo);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_enter_continuous_time_mode(fmi2Component c)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2EnterContinuousTimeMode");
    return fmi2OK;
}

fmi2Status omsi_fmi2_completed_integrator_step(fmi2Component c,
                                               fmi2Boolean noSetFMUStatePriorToCurrentPoint,
                                               fmi2Boolean* enterEventMode,
                                               fmi2Boolean* terminateSimulation)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2CompletedIntegratorStep");
    try
    {
        return osu->completedIntegratorStep(noSetFMUStatePriorToCurrentPoint,
                                            enterEventMode, terminateSimulation);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_set_time(fmi2Component c, fmi2Real time)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetTime(%g)", time);
    try
    {
        return osu->setTime(time);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_set_continuous_states(fmi2Component c, const fmi2Real z[],
                                           size_t nz)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetContinuousStates(nz = %d)", nz);
    try
    {
        return osu->setContinuousStates(z, nz);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_derivatives(fmi2Component c, fmi2Real derivatives[], size_t nz)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetDerivatives(nz = %d)", nz);
    try
    {
        return osu->getDerivatives(derivatives, nz);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_event_indicators(fmi2Component c,
                                          fmi2Real eventIndicators[], size_t ni)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetEventIndicators(ni = %d)", ni);
    try
    {
        return osu->getEventIndicators(eventIndicators, ni);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_continuous_states(fmi2Component c, fmi2Real z[], size_t nz)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetContinuousStates(nz = %d)", nz);
    try
    {
        return osu->getContinuousStates(z, nz);
    }
    CATCH_EXCEPTION(osu);

    return fmi2OK;
}

fmi2Status omsi_fmi2_get_nominals_of_continuous_states(fmi2Component c,
                                                       fmi2Real z_nominal[],
                                                       size_t nz)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetNominalsOfContinuousStates(nz = %d)", nz);
    try
    {
        return osu->getNominalsOfContinuousStates(z_nominal, nz);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}


fmi2Component omsi_fmi2_me_instantiate(fmi2String instanceName,
                                       fmi2Type fmuType,
                                       fmi2String fmuGUID,
                                       fmi2String fmuResourceLocation,
                                       const fmi2CallbackFunctions* functions,
                                       fmi2Boolean visible,
                                       fmi2Boolean loggingOn)
{
    OSU* osu;
    try
    {
        osu = new OSU(instanceName, fmuGUID, functions, visible, loggingOn, fmuResourceLocation);
    }
    catch (std::exception& e)
    {
        if (functions && functions->logger)
            functions->logger(functions->componentEnvironment,
                              instanceName, fmi2Error,
                              OSU::LogCategoryFMUName(logStatusError),
                              e.what());
        return NULL;
    }
    LOG_CALL(osu, "fmi2Instantiate");
    return reinterpret_cast<fmi2Component>(osu);
}


void omsi_fmi2_me_free_instance(fmi2Component c)
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2FreeInstance");
    delete osu;
}

fmi2Status omsi_fmi2_get_clock(fmi2Component c, const fmi2Integer clockIndex[], size_t nClockIndex, fmi2Boolean tick[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetClock(nClockIndex = %d)", nClockIndex);
    try
    {
        return osu->getClock(clockIndex, nClockIndex, tick);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_get_interval(fmi2Component c, const fmi2Integer clockIndex[], size_t nClockIndex,
                                  fmi2Real interval[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2GetInterval(nClockIndex = %d)", nClockIndex);
    try
    {
        return osu->getInterval(clockIndex, nClockIndex, interval);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}


fmi2Status omsi_fmi2_set_clock(fmi2Component c, const fmi2Integer clockIndex[], size_t nClockIndex,
                               const fmi2Boolean tick[], const fmi2Boolean subactive[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetClock(nClockIndex = %d)", nClockIndex);
    try
    {
        return osu->setClock(clockIndex, nClockIndex, tick, subactive);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}

fmi2Status omsi_fmi2_set_interval(fmi2Component c, const fmi2Integer clockIndex[], size_t nClockIndex,
                                  const fmi2Real interval[])
{
    OSU* osu = reinterpret_cast<OSU*>(c);
    LOG_CALL(osu, "fmi2SetInterval(nClockIndex = %d)", nClockIndex);
    try
    {
        return osu->setInterval(clockIndex, nClockIndex, interval);
    }
    CATCH_EXCEPTION(osu);
    return fmi2OK;
}
}
