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

/** \file omsu_getters_and_setters.c
 *
 *  \brief Getter and setter functions for OMSIC.
 *
 * This file defines functions for the FMI used via the OpenModelica Simulation
 * Interface (OMSI). These are the common functions for getting and setting
 * variables and FMI informations.
 */

/** \defgroup GetterAndSetter Get and set functions
 *  \ingroup OMSIC
 *
 * \brief Get and set functions using OMSI Base functions.
 */

/** \addtogroup GetterAndSetter
  *  \{ */

#include <omsu_getters_and_setters.h>

#define UNUSED(x) (void)(x)     /* ToDo: delete later */

/*
 * ============================================================================
 * Getters
 * ============================================================================
 */


/**
 * \brief Get real variables of OMSU.
 *
 * \param   [in]        OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to get.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [out]       value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_get_real(osu_t*                    OSU,
                           const omsi_unsigned_int   vr[],
                           omsi_unsigned_int         nvr,
                           omsi_real                 value[]){

    /* Variables */
    omsi_bool return_status;

    if (invalidState(OSU, "fmi2GetReal", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0)) {
      return omsi_error;
    }

    /* OMSIBase function call */
    return_status = omsi_get_real(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    return return_status;
}


/**
 * \brief Get integer variables of OMSU.
 *
 * \param   [in]        OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to get.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [out]       value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_get_integer(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              omsi_int                   value[]){

    /* Variables */
    omsi_bool return_status;

    if (invalidState(OSU, "fmi2GetInteger", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0)) {
      return omsi_error;
    }

    /* OMSIBase function call */
    return_status = omsi_get_integer(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    return return_status;
}


/**
 * \brief Get boolean variables of OMSU.
 *
 * \param   [in]        OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to get.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [out]       value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_get_boolean(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              omsi_bool                  value[]) {

    /* Variables */
    omsi_bool return_status;

    if (invalidState(OSU, "fmi2GetBoolean", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0)) {
        return omsi_error;
    }

    return_status = omsi_get_boolean(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    return return_status;
}


/**
 * \brief Get string variables of OMSU.
 *
 * \param   [in]        OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to get.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [out]       value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_get_string(osu_t*                  OSU,
                             const omsi_unsigned_int vr[],
                             omsi_unsigned_int       nvr,
                             omsi_string             value[]){

    /* Variables */
    omsi_bool return_status;

    if (invalidState(OSU, "fmi2GetString", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0)) {
        return omsi_error;
    }
    if (nvr>0 && nullPointer(OSU, "fmi2GetString", "vr[]", vr))
        return omsi_error;
    if (nvr>0 && nullPointer(OSU, "fmi2GetString", "value[]", value))
        return omsi_error;

    /* OMSIBase function call */
    return_status = omsi_get_string(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    return return_status;
}


omsi_status omsi_get_fmu_state(osu_t*        OSU,
                               void **      FMUstate) {

    /* TODO: implement */
    UNUSED(OSU); UNUSED (FMUstate);
    return omsi_error;
}

omsi_status omsi_get_clock(osu_t*               OSU,
                           const omsi_int       clockIndex[],
                           omsi_unsigned_int    nClockIndex,
                           omsi_bool            tick[]) {

    /* TODO: implement */
    UNUSED(OSU); UNUSED(clockIndex); UNUSED(nClockIndex); UNUSED(tick);
    return omsi_error;
}

omsi_status omsi_get_interval(osu_t*            OSU,
                              const omsi_int    clockIndex[],
                              omsi_unsigned_int nClockIndex,
                              omsi_real         interval[]) {

    /* TODO: implement */
    UNUSED(OSU); UNUSED(clockIndex); UNUSED(nClockIndex); UNUSED(interval);
    return omsi_error;
}


/*
 * ============================================================================
 * Setters
 * ============================================================================
 */


/**
 * \brief Set real variables of OMSU.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to set.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [in]        value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_set_real(osu_t*                    OSU,
                           const omsi_unsigned_int   vr[],
                           omsi_unsigned_int         nvr,
                           const omsi_real           value[]) {

    /* Variables */
    omsi_bool return_status;
    omsi_int meStates, csStates;

    meStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;
    csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

    if (invalidState(OSU, "fmi2SetReal", meStates, csStates))
        return omsi_error;

    /* OMSIBase function call */
    return_status = omsi_set_real(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    OSU->_need_update = omsi_true;

    return return_status;
}


/**
 * \brief Set integer variables of OMSU.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to set.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [in]        value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_set_integer(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              const omsi_int             value[]) {

    /* Variables */
    omsi_bool return_status;
    omsi_int meStates, csStates;

    meStates = modelInstantiated|modelInitializationMode|modelEventMode;
    csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

    if (invalidState(OSU, "fmi2SetInteger", meStates, csStates))
        return omsi_error;

    /* OMSIBase function call */
    return_status = omsi_set_integer(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    OSU->_need_update = omsi_true;

    return return_status;
}


/**
 * \brief Set boolean variables of OMSU.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to set.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [in]        value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_set_boolean(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              const omsi_bool            value[]) {

    /* Variables */
    omsi_bool return_status;
    omsi_int meStates, csStates;

    meStates = modelInstantiated|modelInitializationMode|modelEventMode;
    csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

    if (invalidState(OSU, "fmi2SetBoolean", meStates, csStates))
        return omsi_error;

    /* OMSIBase function call */
    return_status = omsi_set_boolean(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    OSU->_need_update = omsi_true;

    return return_status;
}


/**
 * \brief Set string variables of OMSU.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \param   [in]        vr              Array of value references of variables to set.
 * \param   [in]        nvr             Length of array `vr`.
 * \param   [in]        value           Array with values of variables.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsic_set_string(osu_t*                  OSU,
                             const omsi_unsigned_int vr[],
                             omsi_unsigned_int       nvr,
                             const omsi_string       value[]) {

    /* Variables */
    omsi_bool return_status;
    omsi_int meStates, csStates;

    meStates = modelInstantiated|modelInitializationMode|modelEventMode;
    csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

    if (invalidState(OSU, "fmi2SetString", meStates, csStates))
        return omsi_error;

    /* OMSIBase function call */
    return_status = omsi_set_string(OSU->osu_data, vr, nvr, value);
    if (return_status != omsi_ok) {
        OSU->state = modelError;
    }

    OSU->_need_update = omsi_true;

    return return_status;
}


/**
 * \brief Set time of OSU.
 *
 * \param   [in,out]    OSU             OMSU component.
 * \param   [in]        time            Time value to set.
 * \return              omsi_status     Exit status of function.
 */
omsi_status omsi_set_time(osu_t*    OSU,
                          omsi_real time) {

    if (invalidState(OSU, "fmi2SetTime", modelInstantiated|modelEventMode|modelContinuousTimeMode, ~0))
        return omsi_error;

    filtered_base_logger(global_logCategories, log_all, omsi_ok,
            "fmi2SetTime: time=%.16g", time);

    OSU->osu_data->sim_data->model_vars_and_params->time_value = time;
    OSU->_need_update = omsi_true;
    return omsi_ok;
}


omsi_status omsi_set_fmu_state(osu_t*   OSU,
                               void *   FMUstate) {

    /* TODO: implement */
    UNUSED(OSU); UNUSED(FMUstate);
    return omsi_error;
}


omsi_status omsi_set_clock(osu_t*               OSU,
                           const omsi_int       clockIndex[],
                           omsi_unsigned_int    nClockIndex,
                           const omsi_bool      tick[],
                           const omsi_bool      subactive[]) {

    /* TODO: implement */
    UNUSED(OSU); UNUSED(clockIndex); UNUSED(nClockIndex); UNUSED(tick); UNUSED(subactive);
    return omsi_error;
}


omsi_status omsi_set_interval(osu_t*            OSU,
                              const omsi_int    clockIndex[],
                              omsi_unsigned_int nClockIndex,
                              const omsi_real   interval[]) {

    /* TODO: implement */
    UNUSED(OSU); UNUSED(clockIndex); UNUSED(nClockIndex); UNUSED(interval);
    return omsi_error;
}

/** \} */
