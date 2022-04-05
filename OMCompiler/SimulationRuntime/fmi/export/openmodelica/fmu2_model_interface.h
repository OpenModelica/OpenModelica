/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef __FMU2_MODEL_INTERFACE_H__
#define __FMU2_MODEL_INTERFACE_H__

#include "fmi2Functions.h"
#include "../simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

/* make sure all compiler use the same alignment policies for structures */
#if defined _MSC_VER || defined __GNUC__
#pragma pack(push,8)
#endif

// categories of logging supported by model.
// Value is the index in logCategories of a ModelInstance.
#define LOG_EVENTS                      0
#define LOG_SINGULARLINEARSYSTEMS       1
#define LOG_NONLINEARSYSTEMS            2
#define LOG_DYNAMICSTATESELECTION       3
#define LOG_STATUSWARNING               4
#define LOG_STATUSDISCARD               5
#define LOG_STATUSERROR                 6
#define LOG_STATUSFATAL                 7
#define LOG_STATUSPENDING               8
#define LOG_ALL                         9
#define LOG_FMI2_CALL                   10

#define NUMBER_OF_CATEGORIES 11

typedef enum {
  model_state_start_end               = 1<<0,  /* ME and CS */
  model_state_instantiated            = 1<<1,  /* ME and CS */
  model_state_initialization_mode     = 1<<2,  /* ME and CS */
  model_state_cs_step_complete        = 1<<3,  /* CS only */
  model_state_cs_step_in_progress     = 1<<4,  /* CS only */
  model_state_cs_step_failed          = 1<<5,  /* CS only */
  model_state_cs_step_canceled        = 1<<6,  /* CS only */
  model_state_me_event_mode           = 1<<7,  /* ME only */
  model_state_me_continuous_time_mode = 1<<8,  /* ME only */
  model_state_terminated              = 1<<9,  /* ME and CS */
  model_state_error                   = 1<<10, /* ME and CS */
  model_state_fatal                   = 1<<11  /* ME and CS */
} ModelState;

typedef struct {
  fmi2String instanceName;
  fmi2Type type;
  fmi2String GUID;
  const fmi2CallbackFunctions *functions;
  fmi2Boolean loggingOn;
  fmi2Boolean logCategories[NUMBER_OF_CATEGORIES];
  fmi2ComponentEnvironment componentEnvironment;
  ModelState state;
  fmi2EventInfo eventInfo;
  SOLVER_INFO* solverInfo;

  DATA* fmuData;
  threadData_t *threadData, *threadDataParent;
  fmi2Boolean toleranceDefined;
  fmi2Real tolerance;
  fmi2Real startTime;
  fmi2Boolean stopTimeDefined;
  fmi2Real stopTime;

  int _need_update;
  int _has_jacobian;
  int _has_jacobian_intialization;
  ANALYTIC_JACOBIAN* fmiDerJac;
  ANALYTIC_JACOBIAN* fmiDerJacInitialization;

  fmi2Real* states;
  fmi2Real* states_der;
  fmi2Real* event_indicators;
  fmi2Real* event_indicators_prev;
  fmi2Real* input_real_derivative;
} ModelInstance;

typedef struct {
  RINGBUFFER* simulationData;
  modelica_real* realParameter;
  modelica_integer* integerParameter;
  modelica_boolean* booleanParameter;
  modelica_string* stringParameter;
} INTERNAL_FMU_STATE;


/* reset alignment policy to the one set before reading this file */
#if defined _MSC_VER || defined __GNUC__
#pragma pack(pop)
#endif

#ifdef __cplusplus
}
#endif

#endif
