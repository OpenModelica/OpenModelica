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

/** \file omsi_getters_and_setters.c
 *  \brief Containing Base getter and setter functions for OMSI Base.
 */

/** \defgroup getterAndSetters Base getter and setter
 *  \ingroup OMSIBase
 *
 * \brief Getter and setter functions provided for OMSIC and OMSICpp.
 *
 * Defines basic getters and setters operationg on `omsi_t` structure.
 */

/** \addtogroup getterAndSetters
  *  \{ */

#include <omsi_global.h>
#include <omsi_getters_and_setters.h>


/*
 * ============================================================================
 * Getters for
 *   - reals
 *   - integers
 *   - booleans
 *   - strings
 * ============================================================================
 */

/**
 * \brief Getter function for reals.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in]  omsu    Central data structure containing all informations.
 * \param [in]  vr      Array of value references for real variables to get.
 * \param [in]  nvr     Length of array `vr`.
 * \param [out] value   Contains asked reals.
 * \return              `omsi_status omsi_ok` if successful <br>
 *                      `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_get_real(omsi_t*                   omsu,
                          const omsi_unsigned_int*  vr,
                          omsi_unsigned_int         nvr,
                          omsi_real*                value){

    /* Variables */
    omsi_unsigned_int i;
    omsi_int index;

    if (!model_variables_allocated(omsu, "fmi2GetReal")) {
        return omsi_error;
    }

    if (nvr > 0 && vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetReal: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr > 0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetReal: Invalid argument value[] = NULL.");
      return omsi_error;
    }

    /* Get reals */
    for (i = 0; i < nvr; i++) {
        /* Check for negated alias */
        index = omsi_get_negated_index(&omsu->model_data->model_vars_info[vr[i]], vr[i]);

        if (index < 0) {
            if (omsi_vr_out_of_range(omsu, "fmi2GetReal", -index, omsu->sim_data->model_vars_and_params->n_reals)) {
                return omsi_error;
            }
            value[i] =getReal(omsu, -index);
        } else {
            if (omsi_vr_out_of_range(omsu, "fmi2GetReal", index, omsu->sim_data->model_vars_and_params->n_reals)) {
                return omsi_error;
            }
            value[i] =getReal(omsu, index);
        }
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2GetReal: vr = %i, value = %f", vr[i], value[i]);
    }
    return omsi_ok;
}


/**
 * \brief Getter function for integers.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in]  omsu    Central data structure containing all informations.
 * \param [in]  vr      Array of value references for integer variables to get.
 * \param [in]  nvr     Length of array `vr`.
 * \param [out] value   Contains asked integers.
 * \return              `omsi_status omsi_ok` if successful <br>
 *                      `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_get_integer(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             omsi_int*                  value){

    /* Variables */
    omsi_unsigned_int i;
    omsi_unsigned_int n_prev_model_vars;
    omsi_int index;

    if (!model_variables_allocated(omsu, "fmi2GetInteger")) {
        return omsi_error;
    }

    if (nvr > 0 &&  vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetInteger: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr > 0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetInteger: Invalid argument value[] = NULL.");
        return omsi_error;
    }

    /* Get integers */
    for (i = 0; i < nvr; i++) {
        /* Check for negated alias */
        n_prev_model_vars = omsu->model_data->n_states +omsu->model_data->n_derivatives + omsu->model_data->n_real_vars + omsu->model_data->n_real_parameters + omsu->model_data->n_real_aliases;
        index = omsi_get_negated_index(&omsu->model_data->model_vars_info[vr[i]+n_prev_model_vars], vr[i]);

        if (index < 0) {
            if (omsi_vr_out_of_range(omsu, "fmi2GetInteger", -index, omsu->sim_data->model_vars_and_params->n_ints)) {
                return omsi_error;
            }
            value[i] =getInteger(omsu, -index);
        } else {
            if (omsi_vr_out_of_range(omsu, "fmi2GetInteger", index, omsu->sim_data->model_vars_and_params->n_ints)) {
                return omsi_error;
            }
            value[i] =getInteger(omsu, index);
        }
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2GetInteger: #i%u# = %d", vr[i], value[i]);
    }
    return omsi_ok;
}


/**
 * \brief Getter function for booleans.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in]  omsu    Central data structure containing all informations.
 * \param [in]  vr      Array of value references for boolean variables to get.
 * \param [in]  nvr     Length of array `vr`.
 * \param [out] value   Contains asked booleans.
 * \return              `omsi_status omsi_ok` if successful <br>
 *                      `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_get_boolean(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             omsi_bool*                 value){

    /* Variables */
    omsi_unsigned_int i;
    omsi_unsigned_int n_prev_model_vars;
    omsi_int index;

    if (!model_variables_allocated(omsu, "fmi2GetBoolean")) {
        return omsi_error;
    }

    if (nvr > 0 && vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetBoolean: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr > 0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetBoolean: Invalid argument value[] = NULL.");
        return omsi_error;
    }

    /* Get bool values */
    for (i = 0; i < nvr; i++){
        /* Check for negated alias */
        n_prev_model_vars = omsu->model_data->n_states +omsu->model_data->n_derivatives + omsu->model_data->n_real_vars + omsu->model_data->n_real_parameters + omsu->model_data->n_real_aliases
                          + omsu->model_data->n_int_vars + omsu->model_data->n_int_parameters + omsu->model_data->n_int_aliases;
        index = omsi_get_negated_index(&omsu->model_data->model_vars_info[vr[i]+n_prev_model_vars], vr[i]);

        if (index < 0) {
            if (omsi_vr_out_of_range(omsu, "fmi2GetBoolean", -index, omsu->sim_data->model_vars_and_params->n_bools)) {
                return omsi_error;
            }
            value[i] =getBoolean(omsu, -index);
        } else {
            if (omsi_vr_out_of_range(omsu, "fmi2GetBoolean", index, omsu->sim_data->model_vars_and_params->n_bools)) {
                return omsi_error;
            }
            value[i] =getBoolean(omsu, index);
        }
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2GetBoolean: #b%u# = %s", vr[i], value[i] ? "true" : "false");
    }
    return omsi_ok;
}


/**
 * \brief Getter function for strings.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in]  omsu    Central data structure containing all informations.
 * \param [in]  vr      Array of value references for string variables to get.
 * \param [in]  nvr     Length of array `vr`.
 * \param [out] value   Contains asked strings.
 * \return              `omsi_status omsi_ok` if successful <br>
 *                      `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_get_string(omsi_t*                     omsu,
                            const omsi_unsigned_int*    vr,
                            omsi_unsigned_int           nvr,
                            omsi_string*                value){

    /* Variables */
    omsi_unsigned_int i;
    omsi_unsigned_int n_prev_model_vars;
    omsi_int index;

    if (!model_variables_allocated(omsu, "fmi2GetString")) {
        return omsi_error;
    }

    if (nvr>0 && vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetString: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr>0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2GetString: Invalid argument value[] = NULL.");
        return omsi_error;
    }

    for (i = 0; i < nvr; i++) {
        /* Check for negated alias */
        n_prev_model_vars = omsu->model_data->n_states +omsu->model_data->n_derivatives + omsu->model_data->n_real_vars + omsu->model_data->n_real_parameters + omsu->model_data->n_real_aliases
                          + omsu->model_data->n_int_vars + omsu->model_data->n_int_parameters + omsu->model_data->n_int_aliases
                          + omsu->model_data->n_bool_vars + omsu->model_data->n_bool_parameters + omsu->model_data->n_bool_aliases;
        index = omsi_get_negated_index(&omsu->model_data->model_vars_info[vr[i]+n_prev_model_vars], vr[i]);

        if (index < 0) {
            if (omsi_vr_out_of_range(omsu, "fmi2GetString", -index, omsu->sim_data->model_vars_and_params->n_strings)) {
                return omsi_error;
            }
            value[i] =getString(omsu, -index);
        } else {
            if (omsi_vr_out_of_range(omsu, "fmi2GetString", index, omsu->sim_data->model_vars_and_params->n_strings)) {
                return omsi_error;
            }
            value[i] =getString(omsu, index);
        }
        if (omsi_vr_out_of_range(omsu, "fmi2GetString", vr[i], omsu->sim_data->model_vars_and_params->n_strings)) {
            return omsi_error;
        }
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2GetString: #s%u# = '%s'", vr[i], value[i]);
    }
    return omsi_ok;
}


/*
 * ============================================================================
 * Setters for
 *   - reals
 *   - integers
 *   - booleans
 *   - strings
 * ============================================================================
 */

/* ToDo: Include code for negated aliases */


/**
 * \brief Setter function for reals.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in,out]  omsu    Central data structure containing all informations.
 * \param [in]      vr      Array of value references for real variables to set.
 * \param [in]      nvr     Length of array `vr`.
 * \param [in]      value   Contains reals to be set.
 * \return                  `omsi_status omsi_ok` if successful <br>
 *                          `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_set_real(omsi_t*                   omsu,
                          const omsi_unsigned_int*  vr,
                          omsi_unsigned_int         nvr,
                          const omsi_real*          value) {

    /* Variables */
    omsi_unsigned_int i;

    if (!model_variables_allocated(omsu, "fmi2SetReal"))
        return omsi_error;

    if (nvr>0 && vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetReal: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr>0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetReal: Invalid argument value[] = NULL.");
        return omsi_error;
    }

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
        "fmi2SetReal: nvr = %d", nvr);

    for (i = 0; i < nvr; i++) {
        if (omsi_vr_out_of_range(omsu, "fmi2SetReal", vr[i], omsu->sim_data->model_vars_and_params->n_reals))
            return omsi_error;
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2SetReal: #r%d# = %.16g", vr[i], value[i]);
        setReal(omsu, vr[i], value[i]);
    }

    return omsi_ok;
}


/**
 * \brief Setter function for integers.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in,out]  omsu    Central data structure containing all informations.
 * \param [in]      vr      Array of value references for integer variables to set.
 * \param [in]      nvr     Length of array `vr`.
 * \param [in]      value   Contains integers to be set.
 * \return                  `omsi_status omsi_ok` if successful <br>
 *                          `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_set_integer(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             const omsi_int*            value) {

    /* Variables */
    omsi_unsigned_int i;

    if (!model_variables_allocated(omsu, "fmi2SetInteger"))
        return omsi_error;

    if (nvr>0 && vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetInteger: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr>0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetInteger: Invalid argument value[] = NULL.");
        return omsi_error;
    }

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
        "fmi2SetInteger: nvr = %d", nvr);

    for (i = 0; i < nvr; i++) {
        if (omsi_vr_out_of_range(omsu, "fmi2SetInteger", vr[i], omsu->sim_data->model_vars_and_params->n_ints))
            return omsi_error;
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2SetInteger: #i%d# = %d", vr[i], value[i]);
        setInteger(omsu, vr[i], value[i]);
    }

    return omsi_ok;
}


/**
 * \brief Setter function for booleans.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in,out]  omsu    Central data structure containing all informations.
 * \param [in]      vr      Array of value references for boolean variables to set.
 * \param [in]      nvr     Length of array `vr`.
 * \param [in]      value   Contains booleans to be set.
 * \return                  `omsi_status omsi_ok` if successful <br>
 *                          `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_set_boolean(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             const omsi_bool*           value) {

    /* Variables */
    omsi_unsigned_int i;

    if (!model_variables_allocated(omsu, "fmi2SetBoolean"))
        return omsi_error;

    if (nvr>0 && vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetBoolean: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr>0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetBoolean: Invalid argument value[] = NULL.");
        return omsi_error;
    }

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
        "fmi2SetBoolean: nvr = %d", nvr);

    for (i = 0; i < nvr; i++) {
        if (omsi_vr_out_of_range(omsu, "fmi2SetBoolean", vr[i], omsu->sim_data->model_vars_and_params->n_bools))
            return omsi_error;
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2SetBoolean: #b%d# = %s", vr[i], value[i] ? "true" : "false");

        setBoolean(omsu, vr[i], value[i]);
    }

    return omsi_ok;
}


/**
 * \brief Setter function for strings.
 *
 * Used by OMSIC or OMSICpp library.
 *
 * \param [in,out]  omsu    Central data structure containing all informations.
 * \param [in]      vr      Array of value references for string variables to set.
 * \param [in]      nvr     Length of array `vr`.
 * \param [in]      value   Contains strings to be set.
 * \return                  `omsi_status omsi_ok` if successful <br>
 *                          `omsi_status omsi_error` if something went wrong.
 */
omsi_status omsi_set_string(omsi_t*                     omsu,
                            const omsi_unsigned_int*    vr,
                            omsi_unsigned_int           nvr,
                            const omsi_string*          value) {

    /* Variables */
    omsi_unsigned_int i;

    if (!model_variables_allocated(omsu, "fmi2SetString"))
        return omsi_error;

    if (nvr>0 && vr==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetString: Invalid argument vr[] = NULL.");
        return omsi_error;
    }
    if (nvr>0 && value==NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2SetString: Invalid argument value[] = NULL.");
        return omsi_error;
    }

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
        "fmi2SetString: nvr = %d", nvr);

    for (i = 0; i < nvr; i++) {
        if (omsi_vr_out_of_range(omsu, "fmi2SetString", vr[i], omsu->sim_data->model_vars_and_params->n_strings))
            return omsi_error;
        filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2SetString: #s%d# = '%s'", vr[i], value[i]);

        setString(omsu, vr[i], value[i]);
    }

    return omsi_ok;
}


/*
 * ============================================================================
 * Helper functions for getters and setters
 *   - get/set real
 *   - get/set integer
 *   - get/set boolean
 *   - get/set string
 * ============================================================================
 */

/* What happens for alias variables for getters and setters? */

/*
 * Get real number of struct OSU with value reference vr.
 */
omsi_real getReal (omsi_t*                  osu_data,
                   const omsi_unsigned_int  vr) {

    omsi_real output = osu_data->sim_data->model_vars_and_params->reals[vr];
    return output;
}


/*
 * Set real number of struct OSU for index reference vr with value
*/
omsi_status setReal(omsi_t*                 osu_data,
                    const omsi_unsigned_int vr,
                    const omsi_real         value) {

    osu_data->sim_data->model_vars_and_params->reals[vr] = value;
    return omsi_ok;
}


/*
 * Get integer number of struct OSU with value reference vr
*/
omsi_int getInteger (omsi_t*                    osu_data,
                     const omsi_unsigned_int    vr) {

    /* Variables */
    omsi_int output;

    /*index = vr - osu_data->sim_data->model_vars_and_params->n_reals;*/
    output = osu_data->sim_data->model_vars_and_params->ints[vr];
   return output;
}


/*
 * Set integer number of struct OSU for index reference vr with value
 */
omsi_status setInteger(omsi_t*                  osu_data,
                       const omsi_unsigned_int  vr,
                       const omsi_int           value) {

    /* index = vr - osu_data->sim_data->model_vars_and_params->n_reals; */
    osu_data->sim_data->model_vars_and_params->ints[vr] = value;
    return omsi_ok;
}


/*
 * Get boolean variable of struct OSU with value reference vr
 */
omsi_bool getBoolean (omsi_t*                  osu_data,
                      const omsi_unsigned_int   vr) {
    /* Variables */
    omsi_bool output;

   /*index = vr - osu_data->sim_data->model_vars_and_params->n_reals
               - osu_data->sim_data->model_vars_and_params->n_ints; */
    output = osu_data->sim_data->model_vars_and_params->bools[vr];
    return output;
}


/*
 * Set boolean variable of struct OSU for index reference vr with value
 */
omsi_status setBoolean(omsi_t*                  osu_data,
                       const omsi_unsigned_int  vr,
                       const omsi_bool          value) {

    /* index = vr - osu_data->sim_data->model_vars_and_params->n_reals
               - osu_data->sim_data->model_vars_and_params->n_ints; */
    osu_data->sim_data->model_vars_and_params->bools[vr] = value;
    return omsi_ok;
}

/*
 * Get string of struct OSU with value reference vr
*/
omsi_string getString (omsi_t*                  osu_data,
                       const omsi_unsigned_int  vr) {

    /* Variables */
    omsi_string output;

    output = osu_data->sim_data->model_vars_and_params->strings[vr];
    return output;
}


/*
 * Set string of struct OSU for index reference vr with value
 */
omsi_status setString(omsi_t*                  osu_data,
                      const omsi_unsigned_int   vr,
                      const omsi_string         value) {

    osu_data->sim_data->model_vars_and_params->strings[vr] = value;
    return omsi_error;
}

/** \} */
