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

/** \file omsu_initialization.c
 *
 *  \brief Functions for instantiation and initialization, termination and
 *  deallocation of OMSUs.
 *
 * This file defines functions for the OpenModelica Simulation Interface (OMSI).
 * These functions are used for instantiation and initialization
 * of an OMSU. Terminate and restart a simulation. Set experiment informations
 * and free an OMSU.
 */

/** \defgroup InitializationOMSIC Initialization and deallocation
 *  \ingroup OMSIC
 *
 * \brief Functions for instantiation and initialization, termination and
 * deallocation of OMSUs.
 */

/** \addtogroup InitializationOMSIC
  *  \{ */

#define DEBUG omsi_false
#define DEBUG_PRINT(function) if (DEBUG) {                                     \
    printf("\nDEBUG PRINT\n");                                                 \
    printf("=====================================================\n");         \
    fflush(stdout);                                                            \
    function; fflush(stdout);                                                  \
    }                                                                          \

#include <omsu_initialization.h>
#include <omsi_posix_func.h>


/**
 * \brief Return new instance of OMSU.
 *
 * \param [in]  instanceName            Unique identifier for FMU instance.
 * \param [in]  fmuType                 Is `fmi2ModelExchange` or `fmi2CoSimulation`.
 *                                      Only model exchange is supported at the moment.
 * \param [in]  fmuGUID                 Globally Unique Identifier from modelDescription.xml.
 * \param [in]  fmuResourceLocation     URI to resource directory of unzippedFMU.
 * \param [in]  functions               Callback functions used in FMU.
 * \param [in]  visible                 Defines if interaction with user should be reduced
 *                                      or be interactive. Unused at the moment.
 * \param [in]  loggingOn               Enable or disable debug logging.
 * \return New OMSU or `NULL` if instantiation failed.
 */
osu_t* omsic_instantiate(omsi_string                            instanceName,
                         omsu_type                              fmuType,
                         omsi_string                            fmuGUID,
                         omsi_string                            fmuResourceLocation,
                         const omsi_callback_functions*         functions,
                         omsi_bool                              __attribute__((unused)) visible,
                         omsi_bool                              loggingOn)
{
    /* Variables */
    osu_t *OSU;
    omsi_unsigned_int i;

    /* set global callback functions */
    global_callback = (omsi_callback_functions*) functions;
    global_instance_name = instanceName;

    /* allocate memory for OpenModelica Simulation Unit */
    OSU = functions->allocateMemory(1, sizeof(osu_t));
    if (!OSU) {
        filtered_base_logger(NULL, log_statuserror, omsi_error,
                "fmi2Instantiate: Not enough memory.");
        filtered_base_logger(global_logCategories, log_statusfatal, omsi_error,
                "Could not instantiate OSU component.");
        return NULL;
    }
    global_callback->componentEnvironment = functions->componentEnvironment;

    /* set general OSU data */
    OSU->GUID = (omsi_char*) functions->allocateMemory(1, strlen(fmuGUID) + 1);
    if (!OSU->GUID) {
        filtered_base_logger(NULL, log_statuserror, omsi_error,
                        "fmi2Instantiate: Not enough memory.");
        omsu_free_osu(OSU);
        filtered_base_logger(global_logCategories, log_statusfatal, omsi_error,
                        "Could not instantiate OSU component.");
        return NULL;
    }

    strcpy(OSU->GUID, fmuGUID);
    OSU->instanceName = omsi_strdup((omsi_char*)instanceName);
    OSU->type = fmuType;
    OSU->fmiCallbackFunctions = functions;

    OSU->osu_functions = (omsi_template_callback_functions_t*) functions->allocateMemory(1, sizeof(omsi_template_callback_functions_t));
    if (!OSU->osu_functions || !OSU->instanceName) {
        filtered_base_logger(NULL, log_statuserror, omsi_error,
                "fmi2Instantiate: Not enough memory.");
        omsu_free_osu(OSU);
        filtered_base_logger(global_logCategories, log_statusfatal, omsi_error,
                "Could not instantiate OSU component.");
        return NULL;
    }

    /* Set template function pointers */
    filtered_base_logger(NULL, log_all, omsi_ok,
            "fmi2Instantiate: Set callback functions from generated C-Code");
    initialize_start_function(OSU->osu_functions);      /* ToDo: At the moment only for static compilation */

    /* Call OMSIBase function for initialization of osu_data */
    OSU->osu_data = omsi_instantiate(instanceName, fmuType, fmuGUID, fmuResourceLocation, functions, OSU->osu_functions, visible, loggingOn, &OSU->state);
    if (OSU->osu_data == NULL || OSU->state==modelError) {
        omsu_free_osu(OSU);
        filtered_base_logger(global_logCategories, log_statusfatal, omsi_error,
                "Could not instantiate OSU component.");
        return NULL;
    }

    /* Initialize callbacks for initialization and simulation omsi_functions */
    omsi_intialize_callbacks(OSU->osu_data, OSU->osu_functions);

    /* Initialize sample events */
    OSU->osu_functions->initialize_samples(OSU->osu_data->sim_data->sample_events);

    OSU->vrStates = (omsi_unsigned_int *) functions->allocateMemory(OSU->osu_data->model_data->n_states, sizeof(omsi_unsigned_int));
    OSU->vrStatesDerivatives = (omsi_unsigned_int *) functions->allocateMemory(OSU->osu_data->model_data->n_states, sizeof(omsi_unsigned_int));
    if (!OSU->vrStates || !OSU->vrStatesDerivatives) {
        omsu_free_osu(OSU);
        filtered_base_logger(global_logCategories, log_statusfatal, omsi_error,
                "Could not instantiate OSU component.");
        return NULL;
    }

    /* Set OSU value reference arrays */
    for (i=0; i < OSU->osu_data->model_data->n_states; i++) {
        OSU->vrStates[i] = i;
        OSU->vrStatesDerivatives[i] = i+OSU->osu_data->model_data->n_states;
    }

    /* Set pointer to logCategories and loggingOn */
    OSU->logCategories = OSU->osu_data->logCategories;
    OSU->loggingOn = &OSU->osu_data->loggingOn;

    /* Set state and log informations */
    OSU->osu_data->state = &OSU->state;
    OSU->state = modelInstantiated;
    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2Instantiate: GUID=%s", fmuGUID);


    DEBUG_PRINT(omsu_print_osu(OSU))

    return OSU;
}


/**
 * \brief Informs the OMSU to enter initialization mode.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_enter_initialization_mode(osu_t* OSU) {

    /* Variables */
    omsi_status status;

    if (invalidState(OSU, "fmi2EnterInitializationMode", modelInstantiated, ~0)) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2EnterInitializationMode: Call was not allowed.");
        return omsi_error;
    }

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2EnterInitializationMode: Initialize model.");

    OSU->state = modelInitializationMode;

    /* ToDo: Is this the right location to solve initialization problem */
    /* Evaluate functionDAE for initialization problem */
    status = OSU->osu_data->sim_data->initialization->evaluate(OSU->osu_data->sim_data->initialization, OSU->osu_data->sim_data->initialization->function_vars, NULL);
    if (status != omsi_ok) {
        filtered_base_logger(global_logCategories, log_fmi2_call, status,
                    "fmi2EnterInitializationMode: Could not solve initialization problem.");
        return status;

    }
    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2EnterInitializationMode: Solved initialization problem successfully.");

    return omsi_ok;
}


/**
 * \brief Informs the OMSU to exit initialization mode.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_exit_initialization_mode(osu_t* OSU) {

    if (invalidState(OSU, "fmi2ExitInitializationMode", modelInitializationMode, ~0))
        return omsi_error;
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2ExitInitializationMode: ....");

    /* Set zero crossings */
    OSU->osu_data->sim_data->simulation->evaluate (OSU->osu_data->sim_data->simulation, OSU->osu_data->sim_data->model_vars_and_params, NULL);

    OSU->state = modelEventMode;
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2ExitInitializationMode: Success.");

    return omsi_ok;
}


/**
 * \brief Inform the OMSU  to setup the experiment.
 *
 * \param   [in,out]    OSU                 OMSU component.
 * \param   [in]        toleranceDefined    Boolean if tolerance is defined.
 * \param   [in]        tolerance           Value of tolerance, if defined.
 * \param   [in]        startTime           Start time for experiment.
 * \param   [in]        stopTimeDefined     If a stop time is defined.
 * \param   [in]        stopTime            Value of stop time, if defined.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_setup_experiment(osu_t*     OSU,
                                  omsi_bool  toleranceDefined,
                                  omsi_real  tolerance,
                                  omsi_real  startTime,
                                  omsi_bool  stopTimeDefined,
                                  omsi_real  stopTime) {

    if (invalidState(OSU, "fmi2SetupExperiment", modelInstantiated, ~0))
        return omsi_error;

    if (toleranceDefined) {
        OSU->osu_data->experiment->tolerance = tolerance;
    }
    else {
        OSU->osu_data->experiment->tolerance = 1e-5;    /* default tolerance */
    }
    OSU->osu_data->experiment->start_time = startTime;
    if (stopTimeDefined) {
        OSU->osu_data->experiment->stop_time = stopTime;
    }
    else {
        OSU->osu_data->experiment->stop_time = startTime+1;     /* default stop time */
    }
    OSU->osu_data->experiment->step_size = (OSU->osu_data->experiment->stop_time
                                            - OSU->osu_data->experiment->start_time) / 500;

    /* Log function call */
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2SetupExperiment: toleranceDefined=%s, tolerance=%g, startTime=%g, stopTimeDefined=%s, stopTime=%g",
            toleranceDefined ? "true" : "false", OSU->osu_data->experiment->tolerance, startTime,
            stopTimeDefined ? "true" : "false", OSU->osu_data->experiment->stop_time);

    return omsi_ok;
}


/**
 * \brief Free OMSU instance.
 *
 * Frees all allocated memory for the Openmodelica Simulation Unit.
 * Does nothing if a null pointer is provided.
 *
 * \param   [in,out]    OSU                 OMSU component.
 */
void omsi_free_instance(osu_t* OSU) {

    /* Variables */
    omsi_int meStates;
    omsi_int csStates;

    if (OSU==NULL) {
        return;
    }

    meStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError;
    csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError;

    if (invalidState(OSU, "fmi2FreeInstance", meStates, csStates)) {
        return;
    }
    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2FreeInstance");


    /* free OSU data */
    omsu_free_osu_data(OSU->osu_data);
    omsu_free_osu(OSU);

}


/**
 * \brief Reset the OMSU after a simulation run.
 *
 * \param   [in,out]    OSU                 OMSU component.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_reset(osu_t* OSU) {

    if (invalidState(OSU, "fmi2Reset", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
        return omsi_error;

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2Reset");

    if (OSU->state & modelTerminated) {
      /* initialize OSU */
      /* omsic_model_setup_data(OSU);*/            /* ToDo: implement */
    }
    /* reset the values to start */
    /*setDefaultStartValues(OSU);*/     /* ToDo: implement */

    OSU->state = modelInstantiated;
    return omsi_ok;
}


/**
 * \brief Informs the OMSU that the simulation run is terminated.
 *
 * \param   [in,out]    OSU                 OMSU component.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_terminate(osu_t* OSU) {

    if (invalidState(OSU, "fmi2Terminate", modelEventMode|modelContinuousTimeMode, ~0))
        return omsi_error;

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2Terminate");

    OSU->state = modelTerminated;
    return omsi_ok;
}


/**
 * \brief Free OMSU
 *
 * \param [in,out]      OSU     OMSU component.
 */
void omsu_free_osu(osu_t* OSU) {

    /* Log function call */
    if (OSU->state == modelError || OSU->state == 0) {      /* global logCategories already freed */
        filtered_base_logger(NULL, log_all, omsi_error,
                "Free OSU component.");
    }
    else {
        filtered_base_logger(NULL, log_all, omsi_ok,
                "Free OSU component.");
    }

    if (OSU==NULL) {
        return;
    }

    global_callback->freeMemory((omsi_char*) OSU->instanceName);
    global_callback->freeMemory(OSU->osu_functions);
    global_callback->freeMemory(OSU->vrStatesDerivatives);
    global_callback->freeMemory(OSU->vrStates);
    global_callback->freeMemory(OSU->GUID);

    global_callback->freeMemory(OSU);
}

/** \} */
