/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/*
 * FMI 3.0 model interface for OpenModelica generated FMUs.
 *
 * This header is self-contained and does NOT depend on fmu2_model_interface.h so
 * that the FMI 3.0 and FMI 2.0 model interfaces can evolve independently. It
 * declares the internal model instance and the model-state machine used by the
 * FMI 3.0 implementation (fmu3_model_interface.c).
 *
 * The internal model instance and the FMI 3.0 C API (fmi3*) layered on top use
 * the FMI 3.0 reference types (fmi3Float64 etc.) throughout; no FMI 2.0 headers
 * or types are used here. The generated per-base-type get/set helper functions
 * (getReal/setReal/...) are plain C and compatible with these types.
 */

#ifndef __FMU3_MODEL_INTERFACE_H__
#define __FMU3_MODEL_INTERFACE_H__

#include "fmi3Functions.h"
#include "../simulation_data.h"
#include "../simulation/solver/solver_main.h"

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
#define LOG_FMI3_CALL                   10

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

/* Which FMI 3.0 interface kind an instance implements. */
typedef enum {
  OMC_ME = 0,   /* Model Exchange */
  OMC_CS = 1    /* Co-Simulation */
} OMC_FmuType;

/* Internal event information. Replaces the FMI 2.0 fmi2EventInfo struct, which
   no longer exists in FMI 3.0; the fields mirror the values reported by
   fmi3UpdateDiscreteStates. */
typedef struct {
  fmi3Boolean newDiscreteStatesNeeded;
  fmi3Boolean terminateSimulation;
  fmi3Boolean nominalsOfContinuousStatesChanged;
  fmi3Boolean valuesOfContinuousStatesChanged;
  fmi3Boolean nextEventTimeDefined;
  fmi3Float64 nextEventTime;
} EventInfo;

typedef struct {
  fmi3String instanceName;
  OMC_FmuType type;
  fmi3String GUID;
  fmi3LogMessageCallback logMessage;
  fmi3InstanceEnvironment instanceEnvironment;
  fmi3Boolean loggingOn;
  fmi3Boolean logCategories[NUMBER_OF_CATEGORIES];
  ModelState state;
  EventInfo eventInfo;
  SOLVER_INFO* solverInfo;

  DATA* fmuData;
  threadData_t *threadData, *threadDataParent;
  fmi3Boolean toleranceDefined;
  fmi3Float64 tolerance;
  fmi3Float64 startTime;
  fmi3Boolean stopTimeDefined;
  fmi3Float64 stopTime;

  int _need_update;
  int _has_jacobian;
  int _has_jacobian_intialization;
  JACOBIAN* fmiDerJac;
  JACOBIAN* fmiDerJacInitialization;

  fmi3Float64* states;
  fmi3Float64* states_der;
  fmi3Float64* event_indicators;
  fmi3Float64* event_indicators_prev;
  fmi3Float64* input_real_derivative;
} ModelInstance;

typedef struct {
  RINGBUFFER* simulationData;
  modelica_real* realParameter;
  modelica_integer* integerParameter;
  modelica_boolean* booleanParameter;
  modelica_string* stringParameter;
} INTERNAL_FMU_STATE;

fmi3Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex);

static fmi3String logCategoriesNames[] = {"logEvents", "logSingularLinearSystems", "logNonlinearSystems", "logDynamicStateSelection",
    "logStatusWarning", "logStatusDiscard", "logStatusError", "logStatusFatal", "logStatusPending", "logAll", "logFmi3Call"};

/* Format a printf-style message and forward it to the instance log callback.
   The FMI 3.0 logger takes a pre-formatted message, so FILTERED_LOG routes
   through this helper to do the formatting the FMI 2.0 logger used to do. */
void omc_fmi3_logMessage(ModelInstance* comp, fmi3Status status, int categoryIndex, const char* message, ...);
/* Same, but for a raw callback when no ModelInstance exists yet (instantiation). */
void omc_fmi3_logCallback(fmi3LogMessageCallback logMessage, fmi3InstanceEnvironment instanceEnvironment,
    fmi3Status status, const char* category, const char* message, ...);

#ifndef FILTERED_LOG
/**
 * @brief Macro to be used to log messages.
 */
#define FILTERED_LOG(instance, status, categoryIndex, message, ...) if (isCategoryLogged(instance, categoryIndex)) { \
    omc_fmi3_logMessage(instance, status, categoryIndex, message, ##__VA_ARGS__); }
#endif

/* ---------------------------------------------------------------------------
 * FMI 3.0 wrapper around the internal model instance
 * ------------------------------------------------------------------------- */

/* Which FMI 3.0 interface an instance was created for. */
#define FMI3_INTERFACE_ME 0
#define FMI3_INTERFACE_CS 1
#define FMI3_INTERFACE_SE 2

/* Wrapper carrying the FMI 3.0 callback and environment around the internal
   model instance. */
typedef struct {
  ModelInstance      *comp;                 /* internal model instance */
  fmi3LogMessageCallback         logMessage;
  fmi3InstanceEnvironment        instanceEnvironment;
  fmi3IntermediateUpdateCallback intermediateUpdate; /* CS only, may be NULL */
  int                 interfaceType;        /* FMI3_INTERFACE_ME/CS/SE */
  int                 eventModeUsed;        /* CS only: master enabled Event Mode */
  int                 earlyReturnAllowed;   /* CS only: master allows early return */
} ModelInstance3;

/* reset alignment policy to the one set before reading this file */
#if defined _MSC_VER || defined __GNUC__
#pragma pack(pop)
#endif

#ifdef __cplusplus
}
#endif

#endif /* __FMU3_MODEL_INTERFACE_H__ */
