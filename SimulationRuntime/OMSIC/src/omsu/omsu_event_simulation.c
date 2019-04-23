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

/*
 * This file defines functions for the FMI event mode used via the OpenModelica
 * Simulation Interface (OMSI). These are the core functions to evaluate the
 * model equations with OMSI.
 */

/** \file omsu_event_simulation.c
 *
 *  \brief Functions for OMSI event handling.
 *
 * This file defines functions for the OpenModelica Simulation Interface (OMSI).
 * These are the core functions to handle events with OMSI.
 */

/** \defgroup EventHandling Event simulation
 *  \ingroup OMSIC
 *
 * \brief Functions used for event simulation
 */

/** \addtogroup EventHandling
  *  \{ */

#include <omsu_event_simulation.h>

#define UNUSED(x) (void)(x)     /* ToDo: delete later */

/*
 * The model enters Event Mode from the Continuous-Time Mode and discrete-time
 * equations may become active (and relations are not “frozen”).
 */
omsi_status omsi_enter_event_mode(osu_t* OSU) {

    if (invalidState(OSU, "fmi2EnterEventMode", modelInitializationMode|modelContinuousTimeMode|modelEventMode, ~0)) {
        return omsi_error;
    }

    /* Log call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2EnterEventMode");

    OSU->state = modelEventMode;
    return omsi_ok;
}


/**
 * \brief Compute event indicators.
 *
 * Allowed to call in event mode, continuous-time mode and terminated.
 *
 * \param   [in,out]    OSU                 OMSU component.
 * \param   [out]       event_indicators    Array with values of event indicators.
 * \param   [in]        n_event_indicators  Length of array `event_indicators`.
 * \return              omsi_status         Exit status of function.
 */
omsi_status omsi_get_event_indicators(osu_t*            OSU,
                                      omsi_real*        event_indicators,
                                      omsi_unsigned_int n_event_indicators)
{
    /* Variables */
    omsi_unsigned_int i;

    if (invalidState(OSU, "fmi2GetEventIndicators",
            modelInstantiated|modelInitializationMode|modelContinuousTimeMode|
            modelEventMode|modelTerminated|modelError, ~0)) {
        return omsi_error;
    }
    /* Check if number of event indicators n_event_indicators is valid */
    if (invalidNumber(OSU, "fmi2GetEventIndicators", "n_event_indicators",
            n_event_indicators, OSU->osu_data->model_data->n_zerocrossings)) {
        return omsi_error;
    }

    /* Log call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2GetEventIndicators");

    /* If there are no event indicator there is nothing to do */
    if (OSU->osu_data->model_data->n_zerocrossings == 0) {
        return omsi_ok;
    }

    /* ToDo: try */
    /* MMC_TRY_INTERNAL(simulationJumpBuffer)*/

    /* Evaluate needed equations */
    if (OSU->_need_update) {
        OSU->osu_data->sim_data->simulation->evaluate (OSU->osu_data->sim_data->simulation, OSU->osu_data->sim_data->model_vars_and_params, NULL);
        OSU->_need_update = omsi_false;
    }

    /* Get event indicators */
    /*OSU->osu_functions->function_ZeroCrossings(OSU->osu_data->sim_data->simulation, OSU->osu_data->sim_data->model_vars_and_params, NULL);*/
    for (i=0; i<n_event_indicators; i++) {
        event_indicators[i] = OSU->osu_data->sim_data->zerocrossings_vars[i];
        filtered_base_logger(global_logCategories, log_events, omsi_ok,
                        "fmi2GetEventIndicators: z%d = %.16g", i, event_indicators[i]);
    }

    return omsi_ok;

    /* ToDo: catch */
    /* MMC_CATCH_INTERNAL(simulationJumpBuffer)

    FILTERED_LOG(OSU, omsi_ok, LOG_FMI2_CALL, "error", "fmi2GetEventIndicators: terminated by an assertion.");
    return omsi_error;*/
}



/**
 * \brief Event iteration to update discrete values.
 *
 * Update pre values, evaluate discrete equations and update discrete variables.
 * Computes next sample event time.
 * Called from function `omsi_new_discrete_state`.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \param   [out]       eventInfo       Informations about the event for integrator.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_event_update(osu_t*              OSU,
                              omsi_event_info*    eventInfo) {

    /* Variables */
    omsi_status status;
    omsi_real nextSampleEvent;

    if (nullPointer(OSU, "fmi2EventUpdate", "eventInfo", eventInfo)) {
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2EventUpdate: Start Event Update!");

    /* ToDo: try */
    /* MMC_TRY_INTERNAL(simulationJumpBuffer)*/

#if 0
#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(OSU->old_data, OSU->threadData, 1, 1)) {
        LOG_FILTER(OSU, LOG_FMI2_CALL,
            global_callback->logger(OSU, global_instance_name, omsi_ok, logCategoriesNames[LOG_ALL],
            "fmi2EventUpdate: Need to iterate state values changed!"))
        /* if new set is calculated reinit the solver */
        eventInfo->valuesOfContinuousStatesChanged = omsi_true;
    }
#endif
#endif

    /* Store pre values */
    omsu_storePreValues(OSU->osu_data);
    omsu_update_pre_zero_crossings(OSU->osu_data->sim_data, OSU->osu_data->model_data->n_zerocrossings);

    /*evaluate functionDAE */
    status = OSU->osu_data->sim_data->simulation->evaluate(OSU->osu_data->sim_data->simulation, OSU->osu_data->sim_data->simulation->function_vars, NULL);
    if (status != omsi_ok) {
        return status;
    }

    /* Check for discrete changes */
    if (omsi_check_discrete_changes(OSU->osu_data) || eventInfo->newDiscreteStatesNeeded) {
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
                "fmi2EventUpdate:  Need to iterate(discrete changes)!");
        eventInfo->newDiscreteStatesNeeded = omsi_true;
        eventInfo->valuesOfContinuousStatesChanged = omsi_true;         /* ToDo: Is this correct? */
    } else {
        eventInfo->newDiscreteStatesNeeded = omsi_false;
    }

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2EventUpdate: newDiscreteStatesNeeded %s",
            eventInfo->newDiscreteStatesNeeded ? "true" : "false");

#if 0
    /* due to an event overwrite old values */
    overwriteOldSimulationData(OSU->old_data);

    /* TODO: check the event iteration for relation
     * in fmi2 import and export. This is an workaround,
     * since the iteration seem not starting.
     */

    /* ToDo: enable, when preValues are implemented */
    /* omsu_storePreValues(OSU->osu_data); */
    updateRelationsPre(OSU->old_data);
#endif

    /* Get Next Event Time */
    nextSampleEvent = omsi_compute_next_event_time(
            OSU->osu_data->sim_data->model_vars_and_params->time_value,
            OSU->osu_data->sim_data->sample_events,
            OSU->osu_data->model_data->n_samples);
    if (nextSampleEvent < 0) {
        eventInfo->nextEventTimeDefined = omsi_false;
    } else {
        eventInfo->nextEventTimeDefined = omsi_true;
        eventInfo->nextEventTime = nextSampleEvent;
    }

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2EventUpdate: Checked for Sample Events! Next Sample Event %f",
            eventInfo->nextEventTime);

    return omsi_ok;


    /* ToDo: catch */
    /* MMC_CATCH_INTERNAL(simulationJumpBuffer)

    FILTERED_LOG(OSU, omsi_error, LOG_FMI2_CALL,
            "fmi2EventUpdate: terminated by an assertion.")
    OSU->_need_update = omsi_true;
    return omsi_error; */
}

/** \} */
