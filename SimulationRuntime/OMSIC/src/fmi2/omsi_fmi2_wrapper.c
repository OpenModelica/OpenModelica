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

/** \file omsi_fmi2_wrapper.c
 *
 *  \brief Wrapper function for FMI compability.
 */

/** \defgroup FMI2Wrapper FMI 2.0 Wrapper
 *  \ingroup OMSIC
 *
 * \brief FMI Wrapper
 *
 * Wrapper functions to use FMI2 functions to interact with an OMSU.
 * See the <a href="https://fmi-standard.org/downloads/">FMI-standard specification</a> for Model Exchange and Co-Simulation 2.0 for more details on how to use these functions.
 */

/** \addtogroup FMI2Wrapper
  *  \{ */


/* TODO: implement external functions in FMU wrapper for c++ target
 */

#include <omsi.h>
#include <omsi_fmi2_wrapper.h>
#include <omsi_utils.h>
#include <omsu_initialization.h>
#include <omsu_getters_and_setters.h>
#include <omsu_continuous_simulation.h>


/**
 * \brief Uniquely identify the header file used for compilation of a binary.
 * \return              Returns the string to uniquely identify the "fmi2TypesPlatform.h"
 *                      header file used for compilation of the functions of the FMU.
 */
FMI2_Export const char* fmi2GetTypesPlatform(void) {
    return fmi2TypesPlatform;
}


/**
 * \brief Return the version of the "fmi2Functions.h" header file.
 *
 * \return              Return "fmiVersion" which is defaults to "2.0".
 */
FMI2_Export const char* fmi2GetVersion(void) {
    return fmi2Version;
}


/**
 * \brief Enable or disable debug logging.
 *
 * \param [in]  c               FMI 2.0 component
 * \param [in]  loggingOn       Set logging on or off.
 * \param [in]  nCategories     Number of categories of FMU. Set in modelDescription.xml.
 * \param [in]  categories      Allowed categories. Set in modelDescription.xml.
 * \return      fmi2Status
 */
FMI2_Export fmi2Status fmi2SetDebugLogging(fmi2Component    c,
                                           fmi2Boolean      loggingOn,
                                           size_t           nCategories,
                                           const fmi2String categories[]) {

    return omsi_set_debug_logging(c, loggingOn, nCategories, categories);
}


/**
 * \brief Return new instance of FMU.
 *
 * \param [in]  instanceName            Unique identifier for FMU instance.
 * \param [in]  fmuType                 Is `fmi2ModelExchange` or `fmi2CoSimulation`.
 *                                      Only model exchange is supported at the moment.
 * \param [in]  fmuGUID                 Globally Unique Identifier from modelDescription.xml.
 * \param [in]  fmuResourceLocation     URI to resource directory of unzippedFMU.
 * \param [in]  functions               Callback functions used in FMU.
 * \param [in]  visible                 Defines if interaction with user should be reduced
 *                                      or be interactive. Ignored at the moment.
 * \param [in]  loggingOn               Enable or disable debug logging.
 * \return New FMU / OMSU or `NULL` if instantiation failed.
 */
FMI2_Export fmi2Component fmi2Instantiate(fmi2String                    instanceName,
                                          fmi2Type                      fmuType,
                                          fmi2String                    fmuGUID,
                                          fmi2String                    fmuResourceLocation,
                                          const fmi2CallbackFunctions*  functions,
                                          fmi2Boolean                   visible,
                                          fmi2Boolean                   loggingOn)
{

    return (fmi2Component) omsic_instantiate(instanceName, fmuType, fmuGUID, fmuResourceLocation, (const omsi_callback_functions*)functions, visible, loggingOn);
}


/**
 * \brief Free FMU instance.
 * \param [in]  c       FMU
 */
FMI2_Export void fmi2FreeInstance(fmi2Component c) {
    omsi_free_instance(c);
}


/**
 * \brief Inform the FMU / OMSU  to setup the experiment.
 *
 * \param [in]  c                   FMI 2.0 component.
 * \param [in]  toleranceDefined    Boolean if tolerance is defined.
 * \param [in]  tolerance           Value of tolerance, if defined.
 * \param [in]  startTime           Start time for experiment.
 * \param [in]  stopTimeDefined     If a stop time is defined.
 * \param [in]  stopTime            Value of stop time, if defined.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2SetupExperiment(fmi2Component    c,
                                           fmi2Boolean      toleranceDefined,
                                           fmi2Real         tolerance,
                                           fmi2Real         startTime,
                                           fmi2Boolean      stopTimeDefined,
                                           fmi2Real         stopTime) {

    return omsi_setup_experiment(c, toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime);
}


/**
 * \brief Informs the FMU to enter initialization mode.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2EnterInitializationMode(fmi2Component c) {
    return omsi_enter_initialization_mode(c);
}



/**
 * \brief Informs the FMU to exit initialization mode.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2ExitInitializationMode(fmi2Component c) {
    return omsi_exit_initialization_mode(c);
}


/**
 * \brief Informs the FMU that the simulation run is terminated.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2Terminate(fmi2Component c) {
    return omsi_terminate(c);
}


/**
 * \brief Reset the FMU after a simulation run.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2Reset(fmi2Component c) {
    return omsi_reset(c);
}


/**
 * \brief Get real variables of FMU.
 *
 * \param [in]          c           FMI 2.0 component.
 * \param [in]          vr          Array of value references of variables to get.
 * \param [in]          nvr         Length of array `vr`.
 * \param [out]         value       Array with values of variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetReal(fmi2Component            c,
                                   const fmi2ValueReference vr[],
                                   size_t                   nvr,
                                   fmi2Real                 value[]) {

    /* ToDo: Check for Update */

    return omsic_get_real(c, vr, nvr, value);
}


/**
 * \brief Get integer variables of FMU.
 *
 * \param [in]          c           FMI 2.0 component.
 * \param [in]          vr          Array of value references of variables to get.
 * \param [in]          nvr         Length of array `vr`.
 * \param [out]         value       Array with values of variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetInteger(fmi2Component             c,
                                      const fmi2ValueReference  vr[],
                                      size_t                    nvr,
                                      fmi2Integer               value[]) {

    return omsic_get_integer(c, vr, nvr, value);
}


/**
 * \brief Get boolean variables of FMU.
 *
 * \param [in]          component   FMI 2.0 component.
 * \param [in]          vr          Array of value references of variables to get.
 * \param [in]          nvr         Length of array `vr`.
 * \param [out]         value       Array with values of variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetBoolean(fmi2Component             component,
                                      const fmi2ValueReference  vr[],
                                      size_t                    nvr,
                                      fmi2Boolean               value[]) {

    return omsic_get_boolean(component, vr, nvr, value);
}


/**
 * \brief Get string variables of FMU.
 *
 * \param [in]          c           FMI 2.0 component.
 * \param [in]          vr          Array of value references of variables to get.
 * \param [in]          nvr         Length of array `vr`.
 * \param [out]         value       Array with values of variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetString(fmi2Component              c,
                                     const fmi2ValueReference   vr[],
                                     size_t                     nvr,
                                     fmi2String                 value[]) {

    return omsic_get_string(c, vr, nvr, value);
}


/**
 * \brief Set real variables of FMU.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \param [in]          vr          Array of value references for variables to set.
 * \param [in]          nvr         Length of array `vr`.
 * \param [in]          value       Array with values for variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2SetReal(fmi2Component            c,
                                   const fmi2ValueReference vr[],
                                   size_t                   nvr,
                                   const fmi2Real           value[]) {

    return omsic_set_real(c, vr, nvr, value);
}


/**
 * \brief Set integer variables of FMU.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \param [in]          vr          Array of value references for variables to set.
 * \param [in]          nvr         Length of array `vr`.
 * \param [in]          value       Array with values for variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2SetInteger(fmi2Component             c,
                                      const fmi2ValueReference  vr[],
                                      size_t                    nvr,
                                      const fmi2Integer         value[]) {

    return omsic_set_integer(c, vr, nvr, value);
}


/**
 * \brief Set boolean variables of FMU.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \param [in]          vr          Array of value references for variables to set.
 * \param [in]          nvr         Length of array `vr`.
 * \param [in]          value       Array with values for variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2SetBoolean(fmi2Component             c,
                                      const fmi2ValueReference  vr[],
                                      size_t                    nvr,
                                      const fmi2Boolean         value[]) {

    return omsic_set_boolean(c, vr, nvr, value);
}


/**
 * \brief Set string variables of FMU.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \param [in]          vr          Array of value references for variables to set.
 * \param [in]          nvr         Length of array `vr`.
 * \param [in]          value       Array with values for variables.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2SetString(fmi2Component              c,
                                     const fmi2ValueReference   vr[],
                                     size_t                     nvr,
                                     const fmi2String           value[]) {

    return omsic_set_string(c, vr, nvr, value);
}


/* Not supported */
FMI2_Export fmi2Status fmi2GetFMUstate(fmi2Component c,
                                       fmi2FMUstate* FMUstate) {

    return omsi_get_fmu_state(c, FMUstate);
}


/* Not supported */
FMI2_Export fmi2Status fmi2SetFMUstate(fmi2Component    c,
                                       fmi2FMUstate     FMUstate) {

    return omsi_set_fmu_state(c, FMUstate);
}


/* Not supported */
FMI2_Export fmi2Status fmi2FreeFMUstate(__attribute__((unused)) fmi2Component c,
                                        __attribute__((unused)) fmi2FMUstate* FMUstate) {

    /*return omsi_free_fmu_state(c, FMUstate);*/
    return fmi2Error;
}


/* Not supported */
FMI2_Export fmi2Status fmi2SerializedFMUstateSize(__attribute__((unused)) fmi2Component c,
                                                  __attribute__((unused)) fmi2FMUstate  FMUstate,
                                                  __attribute__((unused)) size_t*       size) {

    /*return omsi_serialized_fmu_state_size(c, FMUstate, size);*/
    return fmi2Error;
}


/* Not supported */
FMI2_Export fmi2Status fmi2SerializeFMUstate(__attribute__((unused)) fmi2Component  c,
                                             __attribute__((unused)) fmi2FMUstate   FMUstate,
                                             __attribute__((unused)) fmi2Byte       serializedState[],
                                             __attribute__((unused))  size_t         size) {

    /*return omsi_serialize_fmu_state(c, FMUstate, serializedState, size);*/
    return fmi2Error;
}


/* Not supported */
FMI2_Export fmi2Status fmi2DeSerializeFMUstate(__attribute__((unused)) fmi2Component    c,
                                               __attribute__((unused)) const fmi2Byte   serializedState[],
                                               __attribute__((unused)) size_t size,
                                               __attribute__((unused)) fmi2FMUstate* FMUstate) {

    /*return omsi_de_serialize_fmu_state(c, serializedState, size, FMUstate);*/
    return fmi2Error;
}


/* Not supported */
FMI2_Export fmi2Status fmi2GetDirectionalDerivative(__attribute__((unused)) fmi2Component               c,
                                                    __attribute__((unused)) const fmi2ValueReference    vUnknown_ref[],
                                                    __attribute__((unused)) size_t                      nUnknown,
                                                    __attribute__((unused)) const fmi2ValueReference    vKnown_ref[],
                                                    __attribute__((unused)) size_t                      nKnown,
                                                    __attribute__((unused)) const fmi2Real              dvKnown[],
                                                    __attribute__((unused)) fmi2Real                    dvUnknown[]) {

    /*return omsi_get_directional_derivative(c, vUnknown_ref, nUnknown, vKnown_ref, nKnown, dvKnown, dvUnknown);*/
    return fmi2Error;
}


/**
 * \brief FMU enters event mode.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2EnterEventMode(fmi2Component c) {

    return omsi_enter_event_mode(c);
}


/**
 * \brief Evaluate discrete model equations.
 *
 * Only allowed if FMU is in event mode.
 *
 * \param [in,out]      c               FMI 2.0 component.
 * \param [out]         fmiEventInfo    Informations about the event for integrator.
 * \return      fmi2Status              Exit status of function.
 */
FMI2_Export fmi2Status fmi2NewDiscreteStates(fmi2Component  c,
                                             fmi2EventInfo* fmiEventInfo) {

    return omsi_new_discrete_state(c, (omsi_event_info*) fmiEventInfo);
}


/**
 * \brief FMU enters continuous-time mode.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \return      fmi2Status          Exit status of function.
 */
FMI2_Export fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c) {

    return omsi_enter_continuous_time_mode(c);
}


/**
 * \brief Has to be called after every completed integrator step.
 *
 * Unless capability flag `completedIntegratorStepNotNeeded = true`.
 *
 * \param [in,out]      c                                   FMI 2.0 component.
 * \param [in]          noSetFMUStatePriorToCurrentPoint    `true` if `fmi2SetFMUState` will no longer be called for time instants prior to current time in this simulation.
 * \param [out]         enterEventMode                      Signal if environment shall call `fmi2EnterEventMode`.
 * \param [out]         terminateSimulation                 Signal if the simulation should be terminated.
 * \return              fmi2Status                          Exit status of function.
 */
FMI2_Export fmi2Status fmi2CompletedIntegratorStep(fmi2Component    c,
                                                   fmi2Boolean      noSetFMUStatePriorToCurrentPoint,
                                                   fmi2Boolean*     enterEventMode,
                                                   fmi2Boolean*     terminateSimulation) {

    return omsi_completed_integrator_step(c, noSetFMUStatePriorToCurrentPoint, enterEventMode, terminateSimulation);
}


/**
 * \brief Set new time instant and re-initialize time-dependent caching variables.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \param [in]          time        Time to set in FMU.
 * \return              fmi2Status  Exit status of function.
 */
FMI2_Export fmi2Status fmi2SetTime(fmi2Component    c,
                                   fmi2Real         time) {

    return omsi_set_time(c, time);
}


/**
 * \brief Set a new continuous state vector and re-initalize depend states.
 *
 * \param [in,out]      c           FMI 2.0 component.
 * \param [in]          x           Array with values for continuous states.
 * \param [in]          nx          Length of array `x`.
 * \return              fmi2Status  Exit status of function.
 */
FMI2_Export fmi2Status fmi2SetContinuousStates(fmi2Component    c,
                                               const fmi2Real   x[],
                                               size_t           nx) {

    return omsi_set_continuous_states(c, x, nx);
}


/**
 * \brief Compute state derivatives.
 *
 * \param [in]          c               FMI 2.0 component.
 * \param [out]         derivatives     Array with computed state derivatives.
 * \param [in]          nx              Size of array `derivatives`
 * \return              fmi2Status      Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetDerivatives(fmi2Component c,
                                          fmi2Real      derivatives[],
                                          size_t        nx) {

    return omsi_get_derivatives(c, derivatives, nx);
}


/**
 * \brief Compute event indicators.
 *
 * \param [in]          c               FMI 2.0 component.
 * \param [out]         eventIndicators Array with values of event indicators.
 * \param [in]          ni              Length of array `eventIndicators`.
 * \return              fmi2Status      Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetEventIndicators(fmi2Component c,
                                              fmi2Real      eventIndicators[],
                                              size_t        ni) {

    return omsi_get_event_indicators(c, eventIndicators, ni);
}


/**
 * \brief Get new (continuous) state vector.
 *
 * \param [in]          c               FMI 2.0 component.
 * \param [out]         x               Array with values of continuous states.
 * \param [in]          nx              Length of array `x`.
 * \return              fmi2Status      Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetContinuousStates(fmi2Component    c,
                                               fmi2Real         x[],
                                               size_t           nx) {

    return omsi_get_continuous_states(c, x, nx);
}


/**
 * \brief Return the nominal values of the continuous states.
 *
 * \param [in]          c               FMI 2.0 component.
 * \param [out]         x_nominal       Array with nominal values of continuous states.ds
 * \param [in]          nx              Length of array `x`.
 * \return              fmi2Status      Exit status of function.
 */
FMI2_Export fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component  c,
                                                         fmi2Real       x_nominal[],
                                                         size_t         nx) {

    return omsi_get_nominals_of_continuous_states(c, x_nominal, nx);
}

/** \} */
