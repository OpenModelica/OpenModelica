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

/** \file omsu_continuous_simulation.c
 *
 *  \brief Functions for OMSI continuous simulation.
 *
 * This file defines functions for the continuous simulation with OpenModelica
 * Simulation Interface (OMSI). These are the functions to evaluate the
 * model equations during continuous-time mode with OMSI.
 */

/** \defgroup ContinuousSimulation Continuous Simulation
 *  \ingroup OMSIC
 *
 * \brief Functions used for continuous simulation
 */

/** \addtogroup ContinuousSimulation
  *  \{ */

#include <omsu_continuous_simulation.h>

#define UNUSED(x) (void)(x)     /* ToDo: delete later */


/**
 * \brief Evaluate discrete model equations.
 *
 * Only allowed if OMSU is in event mode.
 * Can be called with fmi2 wrapper function `fmi2NewDiscreteStates`.
 *
 * \param [in,out]      OSU             OMSU component.
 * \param [out]         eventInfo       Informations about the event for the integrator.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_new_discrete_state(osu_t*              OSU,
                                    omsi_event_info*    eventInfo) {

    /* Variables */
    omsi_status status;

    /* Check inputs */
    if (invalidState(OSU, "fmi2NewDiscreteStates", modelEventMode, ~0)) {
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2NewDiscreteStates");

    /* Set event info */
    eventInfo->newDiscreteStatesNeeded = omsi_false;
    eventInfo->terminateSimulation = omsi_false;
    eventInfo->nominalsOfContinuousStatesChanged = omsi_false;
    eventInfo->valuesOfContinuousStatesChanged = omsi_false;
    eventInfo->nextEventTimeDefined = omsi_false;
    eventInfo->nextEventTime = 0;

    status = omsi_event_update(OSU, eventInfo);

    return status;
}


/**
 * \brief OMSU enters continuous-time mode.
 *
 * The model enters Continuous-Time Mode and all discrete-time equations become
 * inactive and all relations are "frozen".
 * Can be called with fmi2 wrapper function `fmi2EnterContinuousTimeMode`.
 *
 * \param [in,out]      OSU             OMSU component.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_enter_continuous_time_mode(osu_t* OSU) {

    if (invalidState(OSU, "fmi2EnterContinuousTimeMode", modelEventMode, ~0)) {
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2EnterContinuousTimeMode");

    OSU->state = modelContinuousTimeMode;

    return omsi_ok;
}


/**
 * \brief Set a new continuous state vector and re-initalize depend states.
 *
 * Can be called with fmi2 wrapper `fmi2SetContinuousStates`.
 *
 * \param [in,out]      OSU             OMSU component.
 * \param [in]          x               Array with values for continuous states.
 * \param [in]          nx              Length of array `x`.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_set_continuous_states(osu_t*               OSU,
                                       const omsi_real      x[],
                                       omsi_unsigned_int    nx) {

    /* Variables */
    omsi_unsigned_int i, vr;

    /* According to FMI RC2 specification fmi2SetContinuousStates should only be
     * allowed in Continuous-Time Mode. The following code is done only to make
     * the FMUs compatible with Dymola because Dymola is trying to call
     * fmi2SetContinuousStates after fmi2EnterInitializationMode.
     */
    if (invalidState(OSU, "fmi2SetContinuousStates", modelInstantiated | modelInitializationMode | modelEventMode | modelContinuousTimeMode, ~0)) {
        return omsi_error;
    }
    if (invalidNumber(OSU, "fmi2SetContinuousStates", "nx", nx, OSU->osu_data->model_data->n_states)) {
        return omsi_error;
    }
    if (nullPointer(OSU, "fmi2SetContinuousStates", "x[]", x)) {
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2SetContinuousStates");

    /* Set continuous states */
    for (i = 0; i < nx; i++) {
        vr = OSU->vrStates[i];
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
                "fmi2SetContinuousStates: #r%d# = %.16g", vr, x[i]);
        if (setReal(OSU->osu_data, vr, x[i]) != omsi_ok) {
            return omsi_error;
        }
    }
    OSU->_need_update = omsi_true;

    return omsi_ok;
}

/**
 * \brief Get new (continuous) state vector.
 *
 * Can be called with fmi2 wrapper `fmi2GetContinuousStates`.
 *
 * \param [in,out]      OSU             OMSU component.
 * \param [out]         x               Array with values of continuous states.
 * \param [in]          nx              Length of array `x`.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_get_continuous_states(osu_t*               OSU,
                                       omsi_real            x[],
                                       omsi_unsigned_int    nx) {

    /* Variables */
    omsi_unsigned_int i, vr;

    if (invalidState(OSU, "fmi2GetContinuousStates", modelInitializationMode | modelEventMode | modelContinuousTimeMode | modelTerminated | modelError, ~0)) {
        return omsi_error;
    }
    if (invalidNumber(OSU, "fmi2GetContinuousStates", "nx", nx, OSU->osu_data->model_data->n_states)) {
        return omsi_error;
    }
    if (nullPointer(OSU, "fmi2GetContinuousStates", "states[]", x)) {
        return omsi_error;
    }

    /* Log call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2GetContinuousStates");

    for (i = 0; i < nx; i++) {
        vr = OSU->vrStates[i];
        x[i] = getReal(OSU->osu_data, vr);

        filtered_base_logger(global_logCategories, log_all, omsi_ok,
                "fmi2GetContinuousStates: #r%u# = %.16g", vr, x[i]);
    }

    return omsi_ok;
}


/**
 * \brief Return the nominal values of the continuous states.
 *
 * Since the component environment has no information about the nominal value of
 * the continuous states 1.0 is returned.
 * Can be called with fmi2 wrapper `fmi2GetNominalsOfContinuousStates`.
 *
 * \param [in,out]      OSU             OMSU component.
 * \param [out]         x_nominal       Array with nominal values of continuous states.ds
 * \param [in]          nx              Length of array `x`.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_get_nominals_of_continuous_states(osu_t*               OSU,
                                                   omsi_real            x_nominal[],
                                                   omsi_unsigned_int    nx) {

    /* Variables */
    omsi_unsigned_int i;

    if (invalidState(OSU, "fmi2GetNominalsOfContinuousStates", modelInstantiated | modelEventMode | modelContinuousTimeMode | modelTerminated | modelError, ~0)) {
        return omsi_error;
    }
    if (invalidNumber(OSU, "fmi2GetNominalsOfContinuousStates", "nx", nx, OSU->osu_data->model_data->n_states)) {
        return omsi_error;
    }
    if (nullPointer(OSU, "fmi2GetNominalsOfContinuousStates", "x_nominal[]", x_nominal)) {
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2GetNominalsOfContinuousStates: x_nominal[0, ... , %d] = 1.0",
            nx - 1);

    x_nominal[0] = 1;       /* ToDo: What happens for nx = 0, otherwise this line is unneccessary */

    for (i = 0; i < nx; i++) {
        x_nominal[i] = 1;
    }

    return omsi_ok;
}


/**
 * \brief Has to be called after every completed integrator step.
 *
 * ...provided the capability flag `completedIntegratorStepNotNeeded = false`.
 * The function returns enterEventMode to signal to the environment if the OMSU
 * shall call omsu_enter_event_mode, and it returns terminateSimulation to signal
 * if the simulation shall be terminated.
 *
 * \param [in,out]      OSU                                 OMSU component.
 * \param [in]          noSetFMUStatePriorToCurrentPoint    `omsi_true` if `fmi2SetFMUState` will no longer be called for
 *                                                          time instants prior to current time in this simulation.
 * \param [out]         enterEventMode                      Signal if environment shall call `fmi2EnterEventMode`.
 * \param [out]         terminateSimulation                 Signal if the simulation should be terminated.
 * \return              omsi_status                         Exit status of function.
 */
omsi_status omsi_completed_integrator_step(osu_t*       OSU,
                                           omsi_bool    noSetFMUStatePriorToCurrentPoint,
                                           omsi_bool*   enterEventMode,
                                           omsi_bool*   terminateSimulation) {

    /* Variables */
    omsi_status status;
    /*threadData_t *threadData = OSU->threadData;*/

    UNUSED(noSetFMUStatePriorToCurrentPoint);

    if (invalidState(OSU, "fmi2CompletedIntegratorStep", modelContinuousTimeMode, ~0)) {
        return omsi_error;
    }
    if (nullPointer(OSU, "fmi2CompletedIntegratorStep", "enterEventMode", enterEventMode)) {
        return omsi_error;
    }
    if (nullPointer(OSU, "fmi2CompletedIntegratorStep", "terminateSimulation", terminateSimulation)) {
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2CompletedIntegratorStep");

    /* ToDo: Do something useful with noSetFMUStatePriorToCurrentPoint */

    /* ToDo: try */
    /* MMC_TRY_INTERNAL (simulationJumpBuffer) */

    /* ToDo: evaluate stuff ... */
    /*OSU->osu_functions->functionAlgebraics(OSU->old_data, threadData);
    OSU->osu_functions->output_function(OSU->old_data, threadData);
    OSU->osu_functions->function_storeDelayed(OSU->old_data, threadData);


    storePreValues(OSU->osu_data); */

  if (OSU->_need_update)
  {
    status = OSU->osu_data->sim_data->simulation->evaluate (
        OSU->osu_data->sim_data->simulation,
        OSU->osu_data->sim_data->model_vars_and_params, NULL);
    OSU->_need_update = omsi_false;
  }
  else
  {
    status = omsi_ok;
  }


    *enterEventMode = omsi_false;
    *terminateSimulation = omsi_false;

    /******** check state selection ********/
/*#if !defined(OMC_NO_STATESELECTION) */
#if 0
    if (stateSelection(OSU->old_data, threadData, 1, 0)) {
        /* if new set is calculated reinit the solver */
        *enterEventMode = omsi_true;
        LOG_FILTER(OSU, LOG_ALL,
            global_callback->logger(OSU, global_instance_name, omsi_ok, logCategoriesNames[LOG_ALL],
            "fmi2CompletedIntegratorStep: Need to iterate state values changed!"))
    }
#endif
    /* TODO: fix the extrapolation in non-linear system
     *       then we can stop to save all variables in
     *       in the whole ringbuffer
     */

    /* overwriteOldSimulationData(OSU->old_data); */
    return status;

    /* ToDo: catch */
    /* MMC_CATCH_INTERNAL (simulationJumpBuffer)

    FILTERED_LOG(OSU, omsi_error, LOG_FMI2_CALL,
            "fmi2CompletedIntegratorStep: terminated by an assertion.")
    return omsi_error;*/
}


/**
 * \brief Computes state derivatives at the current time instant and for the current states.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \param   [out]       derivatives     Array with values of derivatives.
 * \param   [in]        nx              Length of array `x`.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_get_derivatives(osu_t*             OSU,
                                 omsi_real          derivatives[],
                                 omsi_unsigned_int  nx) {

    /* Variables */
    omsi_unsigned_int i, vr;

    /* threadData_t *threadData = OSU->threadData; */

    if (invalidState(OSU, "fmi2GetDerivatives",  modelEventMode | modelContinuousTimeMode | modelTerminated | modelError, ~0)) {
        return omsi_error;
    }
    if (invalidNumber(OSU, "fmi2GetDerivatives", "nx", nx, OSU->osu_data->model_data->n_states)) {
        return omsi_error;
    }
    if (nullPointer(OSU, "fmi2GetDerivatives", "derivatives[]", derivatives)) {
        return omsi_error;
    }

    /* ToDo: try */
    /* MMC_TRY_INTERNAL (simulationJumpBuffer) */

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2GetDerivatives");


    /* Evaluate needed equations */
    if (OSU->_need_update) {
        OSU->osu_data->sim_data->simulation->evaluate (OSU->osu_data->sim_data->simulation, OSU->osu_data->sim_data->model_vars_and_params, NULL);
        OSU->_need_update = omsi_false;
    }

    for (i = 0; i < nx; i++) {
        vr = nx + i;
        derivatives[i] = getReal(OSU->osu_data, vr);
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
                "fmi2GetDerivatives: #r%d# = %.16g", vr, derivatives[i]);
    }

    return omsi_ok;

    /* ToDo: catch */
    /* MMC_CATCH_INTERNAL (simulationJumpBuffer)

    FILTERED_LOG(OSU, omsi_error, LOG_FMI2_CALL,
            "fmi2GetDerivatives: terminated by an assertion.")
    return omsi_error;*/
}

/*
 * ToDo: Comment me
 * Actually does nothing at the moment ¯\_(ツ)_/¯
 */
omsi_status omsi_get_directional_derivative(osu_t*                  OSU,
                                            const omsi_unsigned_int vUnknown_ref[],
                                            omsi_unsigned_int       nUnknown,
                                            const omsi_unsigned_int vKnown_ref[],
                                            omsi_unsigned_int       nKnown,
                                            const omsi_real         dvKnown[],
                                            omsi_real               dvUnknown[]) {

    UNUSED(vUnknown_ref); UNUSED(nUnknown); UNUSED(vKnown_ref); UNUSED(nKnown);  UNUSED(dvKnown); UNUSED(dvUnknown);

    if (invalidState(OSU, "fmi2GetDirectionalDerivative", modelInstantiated | modelEventMode | modelContinuousTimeMode, ~0)) {
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2GetDirectionalDerivative");

    if (!OSU->_has_jacobian) {
        unsupportedFunction(OSU, "fmi2GetDirectionalDerivative", modelInitializationMode | modelEventMode | modelContinuousTimeMode | modelTerminated | modelError);
        return  omsi_error;
    }

#if 0
    /***************************************/
    // This code assumes that the FMU variables are always sorted,
    // states first and then derivatives.
    // This is true for the actual OMC FMUs.
    // Anyway we will check that the references are in the valid range
    for (i = 0; i < nUnknown; i++) {
        if (vUnknown_ref[i] >= OSU->osu_data->model_data->n_states)
            // We are only computing the A part of the Jacobian for now
            // so unknowns can only be states
            return omsi_error;
    }
    for (i = 0; i < nKnown; i++) {
        if (vKnown_ref[i] >= 2 * OSU->osu_data->model_data->n_states) {
            // We are only computing the A part of the Jacobian for now
            // so knowns can only be states derivatives
            return omsi_error;
        }
    }
    OSU->osu_functions->functionFMIJacobian(OSU->old_data, OSU->threadData,
            vUnknown_ref, nUnknown, vKnown_ref, nKnown, (double*) dvKnown,
            dvUnknown);

    /***************************************/
#endif

    return omsi_ok;
}

/** \} */
