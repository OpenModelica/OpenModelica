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

/** \file omsi_callbacks.h
 */

/** \addtogroup OMSIBase OMSI Base Library
  * \ingroup OMSI
  *  \{ */

#ifndef OMSI_CALLBACKS_H
#define OMSI_CALLBACKS_H

#include <omsi.h>

#ifdef __cplusplus
extern "C" {
#endif

int evaluate_ode(omsi_t);
int evaluate_outputs(omsi_t);
int evaluate_zerocrossings(omsi_t);
int evaluate_discrete_system(omsi_t);
int evaluate_bound_parameter(omsi_t);
int evaluate_intial_system(omsi_t);


/*
 * ============================================================================
 * OMSI callback functions
 * ============================================================================
 */

/**
 * \brief Function type for logger functions.
 *
 * \param [in]  componentEnvironment    OSU component
 * \param [in]  instanceName            Unique identifier for OMSU instance, e.g. the model name.
 * \param [in]  status                  Status for current log.
 * \param [in]  category                Category for which message should be logged.
 * \param [in]  message                 String with message to log. Can contain string formatters, e.g. %d.
 * \param [in]  ...                     Optional arguments for string formatters.
 */
typedef void      (*omsi_callback_logger)           (const void* componentEnvironment,
                                                     omsi_string instanceName,
                                                     omsi_status status,
                                                     omsi_string category,
                                                     omsi_string message, ...);


/**
 * \brief Function type for allocating memory.
 *
 * \param [in]  num     Number of elements.
 * \param [in]  size    Size of each element in bytes.
 *
 * \return              Pointer to allocated memory.
 */
typedef void*     (*omsi_callback_allocate_memory)  (omsi_unsigned_int  num,
                                                     omsi_unsigned_int  size);


/**
 * \brief Function type for deallocating memory.
 *
 * \param [in] pointer  Pointer to previously memory allocated.
 */
typedef void      (*omsi_callback_free_memory)      (void* pointer);


/**
 * \brief Function type to signal if the computation of communication step of
 * co-simulation slave is finished.
 *
 * Optional function. Is not used for modelExchange.
 *
 * \param [in]  componentEnvironment    OSU component
 * \param [in]  status                  Status for current log.
 */
typedef void      (*omsi_step_finished)             (void* componentEnvironment,
                                                     omsi_status status);


/**
 * \brief Callback functions to be used by OMSI library functions.
 *
 * Containing functions for logging of messages and memory handling.
 */
typedef struct omsi_callback_functions{
    const omsi_callback_logger          logger;                 /**< Logger function */
    const omsi_callback_allocate_memory allocateMemory;         /**< Allocate memory function */
    const omsi_callback_free_memory     freeMemory;             /**< Free memory function */
    const omsi_step_finished            stepFinished;           /**< Communication function for slaves */
    void*                               componentEnvironment;   /**< Pointer to component environment (not the OSU) */
}omsi_callback_functions;



/*
 * ============================================================================
 * Callbacks for template functions
 * ============================================================================
 */

/**
 * \brief Function type for allocating `omsi_function initialization` or `simulation`
 * from generated code.
 *
 * \param [in] omsi_function    Pointer to `omsi_function initialization` or `simulation`
 * \return                      `omsi_status omsi_ok` if successful <br>
 *                              `omsi_status omsi_error` if something went wrong.
 */
typedef omsi_status (*omsu_initialize_omsi_function) (omsi_function_t* omsi_function);


/**
 *\brief Function type for evaluating omsi_function->evaluate.
 *
 * Evaluate equations from generated code.
 *
 * \param [in]      function    Pointer to this omsi_function.
 * \param [in]      variables   Pointer to global model variables and parameters from `sim_data`.
 * \param [in,out]  data        Pointer to optional argument for evaluation function. Can be `NULL`.
 * \return                      `omsi_status omsi_ok` if successful <br>
 *                              `omsi_status omsi_error` if something went wrong.
 */
typedef omsi_status (*evaluate_function) (omsi_function_t*  function,
                                          omsi_values*      variables,
                                          void*             data);

/**
 * \brief Callback functions to generated code.
 */
typedef struct omsi_template_callback_functions_t {
    omsi_bool isSet;                                                 /**< Boolean if template functions are set */
    omsu_initialize_omsi_function initialize_initialization_problem; /**< Function pointer to initialize the initialization problem */
    omsu_initialize_omsi_function initialize_simulation_problem;     /**< Function pointer to initialize the simulation problem */

    void (*initialize_samples) (omsi_sample* sample_events);       /**< Function to initialize sampleEvents. */
}omsi_template_callback_functions_t;


#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif

/** \} */
