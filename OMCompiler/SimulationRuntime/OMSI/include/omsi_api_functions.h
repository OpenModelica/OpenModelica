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

/*! \file omsi_api_functions.h
 *  \brief API functions for OMSI Model Exchange and Co-Simulation
 *
 *  Description: Header file for all usable API functions for OpenModelica
 *  Simulation Interface (OMSI) Model Exchange (ME) and Co-Simulation (CS).
 *  In fact all Functional Mockup Interface (FMI) ME and CS function with some
 *  additional functions are provided.
 */

#ifndef OMSI_API_FUNC_H
#define OMSI_API_FUNC_H

#include <omsi.h>

#ifdef __cplusplus
extern "C" {
#endif


/* Export for dynamic linking on Windows */
#if !defined(FMI2_Export)
    #if defined(__MINGW32__) || defined(_MSC_VER) || defined(_WIN32) || definded(__CYGWIN__)
        #define OMSI_DLLImport   __declspec( dllimport )
        #define OMSI_DLLExport   __declspec( dllexport )
    #else
        #if __GNUC__>=4
            #define OMSI_DLLExport __attribute__ ((visibility ("default")))
            #define OMSI_DLLImport /* nothing */
        #else
            #define OMSI_DLLImport /* extern */
            #define OMSI_DLLExport /* nothing */
        #endif
    #endif

    #if defined(IMPORT_INTO)
        #define OMSI_DLLDirection OMSI_DLLImport
    #else /* we export from the dll */
        #define OMSI_DLLDirection OMSI_DLLExport
    #endif

#else /* Use defined FMI2_Export */
    #define OMSI_DLLDirection FMI2_Export
#endif



/* ToDo: Add all added functions for ME here */
/* ToDo: Add Doxygen documentation */

/*
 * ============================================================================
 * Common functions
 * ============================================================================
 */

/*! \fn omsi_instantiate
 *
 *  This function instantiates the osu instance.
 *
 *  \param [ref] [data]
 */
OMSI_DLLDirection osu_t* omsi_instantiate(omsi_string                    instanceName,
                                          omsu_type                      fmuType,
                                          omsi_string                    fmuGUID,
                                          omsi_string                    fmuResourceLocation,
                                          const omsi_callback_functions* functions,
                                          omsi_bool                      visible,
                                          omsi_bool                      loggingOn);






/*
 * ============================================================================
 * Model Exchange functions
 * ============================================================================
 */



/*
 * ============================================================================
 * Co-Simulation functions
 * ============================================================================
 */



/*
 * ============================================================================
 * Additional API functions
 * ============================================================================
 */


/* call from fmi2_setup_expriment */
OMSI_DLLDirection void omsi_setup_experiment(omsi_t* omsi, bool tolerance_defined,
                          double relative_tolerance);
/* called from fmi2_enter_intialization_mode */
OMSI_DLLDirection int omsi_initialize(omsi_t* omsi);
/* called from fmi2_set_real */
OMSI_DLLDirection int omsi_set_real(omsi_t* omsi, const int* vr, size_t nvr, const double* value);
/* called from fmi2_set_integer */
OMSI_DLLDirection int omsi_set_integer(omsi_t* omsi, const int* vr, size_t nvr, const int* value);
/* called from fmi2_set_booleanomsi_vector_t */
OMSI_DLLDirection int omsi_set_boolean(omsi_t* omsi, const int* vr, size_t nvr, const bool* value);
/* called from fmi2_set_string */
OMSI_DLLDirection int omsi_set_string(omsi_t* omsi, const int* vr, size_t nvr, const const char** value);
/* called from fmi2_get_real */
OMSI_DLLDirection int omsi_get_real(omsi_t* omsi, const int* vr, size_t nvr, double* value);
/* called from fmi2_get_integer */
OMSI_DLLDirection int omsi_get_integer(omsi_t* omsi, const int* vr, size_t nvr, int* value);
/* called from fmi2_get_boolean */
OMSI_DLLDirection int omsi_get_boolean(omsi_t* omsi, const int* vr, size_t nvr, bool* value);
/* called from fmi2_get_string */
OMSI_DLLDirection int omsi_get_string(omsi_t* omsi, const int* vr, size_t nvr, const char** value);
/* called from fmi2_get_directional_derivative */
OMSI_DLLDirection int omsi_get_directional_derivative(omsi_t* omsi,
                const int* vUnknown_ref, size_t nUnknown,
                const int* vKnown_ref,   size_t nKnown,
                const double* dvKnown, double* dvUnknown);

/* called from fmi2_get_derivatives */
OMSI_DLLDirection int omsi_get_derivatives(omsi_t* omsi, double* derivatives , size_t nx);
/* called from fmi2_get_event_indicators */
OMSI_DLLDirection int omsi_get_event_indicators(omsi_t* omsi, double* eventIndicators, size_t ni);
/* called from fmi2_get_nominals_of_continuous_states */
OMSI_DLLDirection int omsi_get_nominal_continuous_states(omsi_t* omsi, double* x_nominal, size_t nx);
/* called from fmi2_completed_integrator_step */
OMSI_DLLDirection int omsi_completed_integrator_step(omsi_t* omsi, double* triggered_event);
/* called from fmi2_set_time */
OMSI_DLLDirection int omsi_set_time(omsi_t* omsi, double time);
/* called from  fmi2_set_continuous_states */
OMSI_DLLDirection int omsi_set_continuous_states(omsi_t* omsi, const double* x, size_t nx);
/* called from fmi2_terminate */
OMSI_DLLDirection int omsi_terminate(omsi_t* omsi);
/* called from fmi2_terminate */
OMSI_DLLDirection int omsi_terminate(omsi_t* omsi);

OMSI_DLLDirection int omsi_next_time_event(omsi_t* omsi);

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif
