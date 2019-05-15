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

/** \file omsi_event_helper.c
 */

/** \defgroup EventHelper Base event functions.
 *  \ingroup OMSIBase
 *
 * \brief Event helper functions provided for OMSIC and OMSICpp.
 *
 * Defines basic functionalities for event handling.
 */

/** \addtogroup EventHelper
  *  \{ */

#include <omsi_global.h>

#include <omsi_event_helper.h>


/**
 * \brief Evaluate zero crossing.
 *
 * Return preValue of zeroCrossing in `modelContinuousTimeMode` and value of
 * the zeroCrossing in `modelEventMode` and set `pre_zerocrossing_vars` in
 * `modelInitializationMode`.
 *
 * \param [in]  this_function       OMSI function containing zero crossing.
 * \param [in]  new_zero_crossing   New value for zero_crossing. Only used in eventMode.
 * \param [in]  index               Index of zero crossing to evaluate.
 * \param [in]  model_state         Event mode or continuous-time mode.
 * \return `omsi_bool`              Return preValue of zeroCrossing in `modelContinuousTimeMode` and value of
 *                                  the zeroCrossing in `modelEventMode` and set `pre_zerocrossing_vars` in
 *                                  `modelInitializationMode`.
 */
omsi_bool omsi_function_zero_crossings (omsi_function_t*    this_function,
                                        omsi_bool           new_zero_crossing,
                                        omsi_unsigned_int   index,
                                        ModelState          model_state)
{
    if (this_function->zerocrossings_vars == NULL
            || this_function->pre_zerocrossings_vars == NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Evaluate: in omsi_function_zero_crossings: No memory for zero crossings allocated.");
        return new_zero_crossing;
    }
    /* Update zerocrossing variable */
    if (new_zero_crossing) {
        this_function->zerocrossings_vars[index] = 1;
    } else {
        this_function->zerocrossings_vars[index] = -1;
    }


    /* Return bool */
    if (model_state == modelEventMode ) {
        return this_function->zerocrossings_vars[index]>0;
    } else if (model_state == modelContinuousTimeMode) {
        return this_function->pre_zerocrossings_vars[index]>0;
    } else if (model_state == modelInitializationMode) {
        this_function->pre_zerocrossings_vars[index] = this_function->zerocrossings_vars[index];
        return this_function->zerocrossings_vars[index]>0;
    } else {
        return this_function->zerocrossings_vars[index]>0;
    }
}


/**
 * \brief Helper function for sample events.
 *
 * Check if on sample event.
 *
 * \param [in]  this_function   OMSI function containing sample.
 * \param [in]  sample_id       ID of sample to check for.
 * \param [in]  model_state     State of Model.
 * \return      omsi_bool       Return `omsi_true` at time instants `start + i*interval, (i=0, 1, ...)`
 *                              if in `modelEventMode` and `omsi_false` else.
 */
omsi_bool omsi_on_sample_event (omsi_function_t*    this_function,
                                omsi_unsigned_int   sample_id,
                                ModelState          model_state)
{
    /* Variables */
    omsi_real modulo_value;
    omsi_real time;
    omsi_sample* sample;
    omsi_bool is_on_sample;

    time = this_function->function_vars->time_value;
    sample = &this_function->sample_events[sample_id];
    is_on_sample = omsi_false;

    if (time>= sample->start_time) {
        modulo_value = (omsi_real)fmod(time+sample->start_time, sample->interval);
        if ((fabs(modulo_value-sample->interval) < 1e-8) || (modulo_value > -1e-8  && modulo_value < 1e-8)) {       /* ToDo: Some epsilon */
            is_on_sample = omsi_true;
        }
    }

    /* Return bool */
    if (model_state == modelEventMode ) {
        return is_on_sample;
    } else if (model_state == modelContinuousTimeMode) {
        return omsi_false;
    } else if (model_state == modelInitializationMode) {
        printf("Not implemented yet!"); fflush(stdout);
        return omsi_false;
    } else {
        return omsi_false;
    }
}


/**
 * \brief Compute next sample time for given sample.
 *
 * Helper function for omsi_compute_next_event_time
 *
 * \param [in]  time            Current model time.
 * \param [in]  sample_event    Struct with sample event informations.
 * \return      `omsi_real`     Return time for next sample event for this sample.
 */
omsi_real omsi_next_sample(omsi_real    time,
                           omsi_sample* sample_event)
{
    /* Variables */
    omsi_real dist_prev_event;

    /* Compute next sample time */
    if (time < sample_event->start_time - 1e-8) {       /* ToDo: minus some epsilon */
        return sample_event->start_time;
    } else {
        dist_prev_event = fmod(time+sample_event->start_time, sample_event->interval);
        if (fabs(dist_prev_event-sample_event->interval) < 1e-8) {  /* nearly on an sample event */
            return time + sample_event->interval;
        } else {
            return time + sample_event->interval - dist_prev_event;
        }
    }
}


/**
 * \brief Compute next event time from samples.
 * \param [in]  time            Current model time.
 * \param [in]  sample_events   Array of samples.
 * \param [in]  n_sample_events Length of array `ample_events`.
 * \return      `omsi_real`     Return time for next sample event.
 */
omsi_real omsi_compute_next_event_time (omsi_real           time,
                                        omsi_sample*        sample_events,
                                        omsi_unsigned_int   n_sample_events)
{
    /* Variables */
    omsi_real next_event_time;
    omsi_unsigned_int i;

    if (n_sample_events>0) {
        next_event_time = omsi_next_sample(time, &sample_events[0]);
    }
    else {
        next_event_time = -1;
    }

    for (i=1; i<n_sample_events; i++) {
        next_event_time = (omsi_real) __builtin_fmin(omsi_next_sample(time, &sample_events[i]), next_event_time);
    }

    return next_event_time;
}


/**
 * \brief Checks for discrete changes.
 *
 * Compares discrete real, integer and boolean variables to their pre values.
 * Returns true if the values are different.
 *
 * \param [in]  omsi_data       OMSI data containing model variables and pre values.
 * \return      `omsi_boolen`   Return `omsi_true` if some discrete variable
 *                              changed compared to its pre-value. Otherwise
 *                              return `omsi_false`.
 */
omsi_bool omsi_check_discrete_changes (omsi_t* omsi_data)
{
    /* Variables */
    omsi_unsigned_int i;
    omsi_unsigned_int start_discrete_real_vars, n_discrete_real_vars;
    omsi_values* model_vars_and_params;
    omsi_values* pre_model_vars_and_params;

    /* Set pointers */
    start_discrete_real_vars = omsi_data->model_data->start_index_disc_reals;
    n_discrete_real_vars = omsi_data->model_data->n_discrete_reals;
    model_vars_and_params = omsi_data->sim_data->model_vars_and_params;
    pre_model_vars_and_params = omsi_data->sim_data->pre_vars;

    /* Compare all real discrete variables to pre variables */
    for (i=start_discrete_real_vars; i<n_discrete_real_vars; i++) {
        if (fabs(model_vars_and_params->reals[i] - pre_model_vars_and_params->reals[i]) > 1e-8) {  /* ToDo: insert pre vars mapping */
            return omsi_true;
        }
    }

    /* Compare all integer variables to pre variables */
    for (i=0; i<omsi_data->model_data->n_int_vars; i++) {
        if (model_vars_and_params->ints[i] != pre_model_vars_and_params->ints[i] ) {  /* ToDo: insert pre vars mapping */
            return omsi_true;
        }
    }

    /* Compare all integer variables to pre variables */
    for (i=0; i<omsi_data->model_data->n_bool_vars; i++) {
        if (model_vars_and_params->bools[i] != pre_model_vars_and_params->bools[i] ) {  /* ToDo: insert pre vars mapping */
            return omsi_true;
        }
    }

    return omsi_false;
}

/** \} */
