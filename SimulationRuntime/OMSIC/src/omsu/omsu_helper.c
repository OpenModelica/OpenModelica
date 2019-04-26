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

/** \file omsu_helper.c
 *
 *  \brief Helper functions and functions for logging and debugging.
 *
 * This file defines helper functions used all over OMSI C-runtime. Also functions
 * for logging and debugging.
 */

/** \defgroup Logging Logging and Debugging
 *  \ingroup OMSIC
 *
 * \brief Functions used for logging and debugging
 */

/** \addtogroup Logging
  *  \{ */

#include <omsu_helper.h>

#define UNUSED(x) (void)(x)     /* ToDo: delete later */

/*
 * ============================================================================
 * Stuff I don't know where to put yet. ToDo: Do the thing!
 * ============================================================================
 */

/*
 * Helper function for logging.
 * Returns current state of component as string.
 */
omsi_string stateToString(osu_t* OSU) {
    switch (OSU->state) {
        case modelInstantiated: return "Instantiated";
        case modelInitializationMode: return "Initialization Mode";
        case modelEventMode: return "Event Mode";
        case modelContinuousTimeMode: return "Continuous-Time Mode";
        case modelTerminated: return "Terminated";
        case modelError: return "Error";
        default: break;
    }
    return "Unknown";
}


/*
 * Checks if component environment is allowed to execute function_name in its
 * current state.
 */
omsi_bool invalidState(osu_t*       OSU,            /* OSU component */
                       omsi_string  function_name,  /* name of function */
                       omsi_int     meStates,       /* valid Model Exchange states for function */
                       omsi_int     csStates) {     /* valid Co-Simulation state for function */

    /* Variables */
    omsi_int statesExpected;

    if (!OSU) {
        return omsi_true;
    }

    if (omsi_model_exchange == OSU->type) {
        statesExpected = meStates;
    }
    else { /* CoSimulation */
        statesExpected = csStates;
    }

    if (!(OSU->state & statesExpected)) {
        OSU->state = statesExpected;

        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "%s: Illegal call sequence. %s is not allowed in %s state.",
                function_name, function_name, stateToString(OSU));

        OSU->state = modelError;
        return omsi_true;
    }

    return omsi_false;
}


/*
 * Returns true if pointer is NULL pointer, emits error message and sets
 * model state to modelError.
 * Otherwise it returns false.
 */
omsi_bool nullPointer(osu_t*        OSU,
                      omsi_string   function_name,
                      omsi_string   arg,
                      const void *  pointer) {

    if (!pointer) {
        OSU->state = modelError;
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "%s: Invalid argument %s = NULL.", function_name, arg);

        return omsi_true;
    }
    return omsi_false;
}


/*
 * Returns true if vr is out of range of end, emits error message and sets
 * model state to modelError.
 * Otherwise it returns false.
 */
omsi_bool vrOutOfRange(osu_t*               OSU,
                       omsi_string          function_name,
                       omsi_unsigned_int    vr,
                       omsi_int             end) {

    if ((omsi_int)vr >= end) {
        OSU->state = modelError;
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "%s: Illegal value reference %u.", function_name, vr);
        return omsi_true;
    }
    return omsi_false;
}


/*
 * Logs error for call of unsupported function.
 */
omsi_status unsupportedFunction(osu_t*      OSU,
                                omsi_string function_name,
                                omsi_int    statesExpected) {

    if (invalidState(OSU, function_name, statesExpected, ~0)) {
        return omsi_error;
    }
    filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
            "%s: Function not implemented.", function_name);
    return omsi_error;
}


/*
 * Returns true if n is not equal to nExpected, emits error message and sets
 * model state to modelError.
 * Otherwise it returns false.
 */
omsi_bool invalidNumber(osu_t*          OSU,
                        omsi_string     function_name,
                        omsi_string     arg,
                        omsi_int        n,
                        omsi_int        nExpected) {

    if (n != nExpected) {
        OSU->state = modelError;
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "%s: Invalid argument %s = %d. Expected %d.",
                function_name, arg, n, nExpected);
        return omsi_true;
    }
    return omsi_false;
}


/**
 * \brief Enable or disable debug logging.
 *
 * \param   [in]        OSU             OMSU component.
 * \param   [in]        loggingOn       Set logging on or off.
 * \param   [in]        nCategories     Number of categories of OMSU. Set in modelDescription.xml.
 * \param   [in]        categories      Allowed categories. Set in modelDescription.xml.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_set_debug_logging(osu_t*               OSU,
                                   omsi_bool            loggingOn,
                                   omsi_unsigned_int    nCategories,
                                   const omsi_string    categories[]) {

    /* Variables */
    omsi_unsigned_int i, j;
    omsi_bool categoryFound;

    OSU->osu_data->loggingOn = loggingOn;

    for (i = 0; i < NUMBER_OF_CATEGORIES; i++) {
        OSU->osu_data->logCategories[i] = omsi_false;
    }
    for (i = 0; i < nCategories; i++) {
        categoryFound = omsi_false;
        for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
            if (strcmp(log_categories_names[j], categories[i]) == 0) {
                OSU->osu_data->logCategories[j] = loggingOn;
                categoryFound = omsi_true;
                break;
            }
        }
        if (!categoryFound) {
            filtered_base_logger(NULL, log_statuswarning, omsi_warning,
                    "logging category '%s' is not supported by model", categories[i]);
        }
    }

    filtered_base_logger(global_logCategories, log_fmi2_call, omsi_ok,
            "fmi2SetDebugLogging");

    return omsi_ok;
}


/*
 * \brief Returns model state of OSU.
 *
 * \return
 */
ModelState omsic_get_model_state (void)
{
    return *global_model_state;
}


/*
 * Checks for discrete changes.
 * Returns omsi_true if changes were found, otherwise omsi_false;
 */
omsi_bool omsu_discrete_changes(osu_t*  OSU,
                                void*   threadData) {     /* ToDo: threadData not implemented yet */

    /* ToDo: Log all changed variables */
    if (OSU->logCategories[log_all]) {
        /* ToDo: implement */
        return omsi_false;
    }
    else {
        return omsu_values_equal(OSU->osu_data->sim_data->model_vars_and_params, threadData);
    }
}


/*
 * Stores pre values of omsi_data->sim_data->model_vars_and_params.
 */
void omsu_storePreValues(omsi_t* omsi_data) {

    omsu_copy_values(omsi_data->sim_data->pre_vars, omsi_data->sim_data->model_vars_and_params);
}


/*
 * \brief Update values of `pre_zero_crossing` array.
 *
 * \param sim_data
 * \param n_zero_crossings
 */
void omsu_update_pre_zero_crossings(sim_data_t*          sim_data,
                                    omsi_unsigned_int    n_zero_crossings)
{
    /* Variables */
    omsi_unsigned_int i;

    for (i=0; i<n_zero_crossings; i++) {
        sim_data->pre_zerocrossings_vars[i] = sim_data->zerocrossings_vars[i];
    }


}


/*
 * ============================================================================
 * Section for data copying, comparing and such stuff
 * ============================================================================
 */

/*
 * Compare memory of vars_1 and vars_2 and returns omsi_true if they are equal.
 * Otherwise omsi_false is returned.
 */
omsi_bool omsu_values_equal(omsi_values*    vars_1,
                            omsi_values*    vars_2) {

    omsi_unsigned_int size;

    /* Check reals */
    if (vars_1->n_reals != vars_2->n_reals) {
        return omsi_false;
    }
    size = vars_1->n_reals*sizeof(omsi_real);
    if (0 != memcmp(vars_1->reals, vars_2->reals, size)) {
        return omsi_false;
    }

    /* Check ints */
    if (vars_1->n_ints != vars_2->n_ints) {
        return omsi_false;
    }
    size = vars_1->n_ints*sizeof(omsi_int);
    if (0 != memcmp(vars_1->ints, vars_2->ints, size)) {
        return omsi_false;
    }

    /* Check bools */
    if (vars_1->n_bools != vars_2->n_bools) {
        return omsi_false;
    }
    size = vars_1->n_bools*sizeof(omsi_bool);
    if (0 != memcmp(vars_1->bools, vars_2->bools, size)) {
        return omsi_false;
    }

    /* Check strings */
    if (vars_1->n_strings != vars_2->n_strings) {
        return omsi_false;
    }
    size = vars_1->n_strings*sizeof(omsi_string);
    if (0 != memcmp(vars_1->strings, vars_2->strings, size)) {
        return omsi_false;
    }

    /* Check externs */
    if (vars_1->n_externs != vars_2->n_externs) {
        return omsi_false;
    }
    size = vars_1->n_externs*sizeof(void*);
    if (0 != memcmp(vars_1->externs, vars_2->externs, size)) {
        return omsi_false;
    }

    /* Check time_value */
    if (0 != memcmp(&vars_1->time_value, &vars_2->time_value, sizeof(omsi_real))) {
        return omsi_false;
    }

    return omsi_true;
}


/*
 * Copies source_vars to target_vars.
 */
omsi_status omsu_copy_values(omsi_values*   target_vars,
                             omsi_values*   source_vars) {

    omsi_unsigned_int size;

    if (target_vars == NULL || source_vars == NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "copy_values: Pointer is NULL.");
        return omsi_error;
    }

    /* Copy values */
    size = sizeof(omsi_real)*source_vars->n_reals;
    memcpy(target_vars->reals, source_vars->reals, size);

    size = sizeof(omsi_int)*source_vars->n_reals;
    memcpy(target_vars->reals, source_vars->reals, size);

    size = sizeof(omsi_bool)*source_vars->n_bools;
    memcpy(target_vars->bools, source_vars->bools, size);

    size = sizeof(omsi_string)*source_vars->n_strings;
    memcpy(target_vars->strings, source_vars->strings, size);

    size = sizeof(void*)*source_vars->n_externs;
    memcpy(target_vars->externs, source_vars->externs, size);

    target_vars->time_value = source_vars->time_value;

    /* Copy meta information */
    target_vars->n_reals = source_vars->n_reals;
    target_vars->n_ints = source_vars->n_ints;
    target_vars->n_bools = source_vars->n_bools;
    target_vars->n_strings = source_vars->n_strings;
    target_vars->n_externs = source_vars->n_externs;

    return omsi_ok;
}


/*
 * ============================================================================
 * Section for print and debug functions
 * ============================================================================
 */

/**
 * \brief Print all data in osu_t structure.
 *
 * Used for debugging.
 *
 * \param   [in]    OSU     OMSU component.
 */
void omsu_print_osu (osu_t* OSU) {

    omsi_unsigned_int i;

    printf("\n========== omsu_print_osu start ==========\n");

    omsu_print_omsi_t(OSU->osu_data, "");

    /* print informations contained directly in OSU */
    printf("_need_update: \t\t%s\n", OSU->_need_update?"true":"false"); fflush(stdout);
    printf("_has_jacobian: \t\t%s\n", OSU->_has_jacobian?"true":"false");

    printf("state:\t\t\t");
    switch (OSU->state) {
    case modelInstantiated:
        printf("modelInstantiated\n");
        break;
    case modelInitializationMode:
        printf("modelInitializationMode\n");
        break;
    case modelContinuousTimeMode:
        printf("modelContinuousTimeMode\n");
        break;
    case modelEventMode:
        printf("modelEventMode\n");
        break;
    case modelSlaveInitialized:
        printf("modelSlaveInitialized\n");
        break;
    case modelTerminated:
        printf("modelTerminated\n");
        break;
    case modelError:
        printf("modelError\n");
        break;
    default:
        printf("unknown\n");
    }

    printf("GUID: \t\t\t%s\n", OSU->GUID);
    printf("instanceName: \t\t%s\n", OSU->instanceName);



    printf("toleranceDefined: \t%s\n", OSU->toleranceDefined?"true":"false");
    printf("tolerance: \t\t%f\n", OSU->tolerance);
    printf("startTime: \t\t%f\n", OSU->startTime);
    printf("stopTimeDefined: \t%s\n", OSU->stopTimeDefined?"true":"false");
    printf("stopTime: \t\t%f\n", OSU->stopTime);

    printf("type:\t\t\t");
    switch(OSU->type) {
    case omsi_model_exchange:
        printf("omsi_model_exchange\n");
        break;
    case omsi_co_simulation:
        printf("omsi_model_exchange\n");
        break;
    default:
        printf("unknown\n");
    }

    printf("vrStates: \t\t{ ");
    for (i=0; i<OSU->osu_data->model_data->n_states; i++) {
        printf("%u ", OSU->vrStates[i]);
    }
    printf("}\n");

    printf("vrStatesDerivatives: \t{ ");
    for (i=0; i<OSU->osu_data->model_data->n_states; i++) {
        printf("%u ", OSU->vrStatesDerivatives[i]);
    }
    printf("}\n");

    printf("\n==========  omsu_print_osu end  ==========\n\n");
}


/*
 *  division error logging
 */
omsi_real division_error_time(const char*   msg,
                              omsi_real     time) {

  /* call an assert after lgging */
  filtered_base_logger(global_logCategories, log_all, omsi_warning, "DIVISION: Divisor %s is zero at t = %f!", msg, time);
  return 0;
}


/*
 *  Modelica built-in homotopy function
 */
omsi_real homotopy(omsi_real actual, omsi_real siple) {

  UNUSED(siple);

  /* call an assert after logging */
  return actual;
}

/** \} */
