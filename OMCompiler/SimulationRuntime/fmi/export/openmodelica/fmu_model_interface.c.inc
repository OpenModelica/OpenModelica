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
 * The model interface that FMI 2.0 and FMI 3.0 FMUs share. It is included once,
 * by fmu2_model_interface.c or fmu3_model_interface.c, which define before the
 * include:
 *   OMC_FMI_VERSION          2 or 3
 *   fmiX<Type>, fmiX<Status> the FMI types and constants of that version
 *   FMIX(name), FMIX_STR     the function names and the prefix in log messages
 *   FMIX_ME, FMIX_CS         the ModelInstance type values
 *   FMIX_LOG                 a log message that is always sent
 *   LOG_FMIX_CALL, FMIX_SETUP_DATA_STRUC
 */

#include "../simulation/solver/solver_main.h"
#include "../util/omc_fmu_init.h"
#include "../util/omc_fmu_paramdeps.h"
#include "../util/omc_mmap.h"
#include "../util/omc_file.h"

#if OMC_FMI_VERSION == 2
#define SET_DISCRETE_ME_STATES (model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode)
#define SET_DISCRETE_CS_STATES (model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete)
#define FMU_STATE_ME_STATES (model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error)
#define FMU_STATE_CS_STATES (model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error)
#else
#define SET_DISCRETE_ME_STATES (model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated)
#define SET_DISCRETE_CS_STATES (model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated)
#define FMU_STATE_ME_STATES (model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated)
#define FMU_STATE_CS_STATES (model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated)
#endif

/**
  * @brief Skips to a given character or end of string.
 *
  * @param str            Null terminated string.
  * @param c              Character to move pointer to.
  * @return const char*   Position of character `c` or `\0`.
 */
static inline const char* skipTo(const char *str, char c)
{
  while(*str != c && *str != '\0') {
    str++;
  }
  return str;
}

/**
  * @brief Puts double quotes around a string
 *
  * @param str      Null terminated string.
  * @return char*   Newly allocated string with double quotes around `str`.
  *                 Needs to be freed with `free`
 */
static inline char* quote(const char *str)
{
  size_t len = strlen(str) + 3; // +2 for quotes, +1 for null terminator
  char* tmp = (char*) malloc(len);
  if (tmp == NULL) {
    return NULL;
  }
  snprintf(tmp, len, "\"%s\"", str);
  return tmp;
 }

/**
 * @brief Parse and sets the solver method string
 *
 * @param  solverInfo   Solver info to set solver method in.
 * @param  str          string that starts at solver method string
 * @return const char*  input string skipped to endline
 */
static inline const char* setSolverMethod(SOLVER_INFO *solverInfo, const char *str)
{
  /* Variables */
  int i;
  char* value;
  for(i=1; i<S_MAX; i++)
  {
    value = quote(SOLVER_METHOD_NAME[i]);
    if (value == NULL) {
      continue;
    }
    if (strncmp(str, value, strlen(SOLVER_METHOD_NAME[i]) + 2) == 0)
    {
      solverInfo->solverMethod = i;
      free(value);
      break;
    }
    free(value);
  }
  return skipTo(str, '\n');
}

/**
 * @brief parses flags from resources/modelName_flags.json
 *
 * @param solverInfo
 * @param str           string read from file
 */
void parseFlags(SOLVER_INFO *solverInfo, const char *str)
{
  /* Variables */
  int i, k;
  const int k_max = 1000;
  char* value;

  str = skipTo(str, '\"');
  k = 0;
  while(*str != '\0' && k < k_max)
  {
    k++;
    for(i=1; i<FMU_FLAG_MAX; i++)
    {
      // map the fmu flags to regular flags
      value = quote(FLAG_NAME[FMU_FLAG_MAP[i]]);
      if (value == NULL) {
        /* If allocation failed, skip this entry */
        continue;
      }

      if (strncmp(str, value, strlen(FLAG_NAME[FMU_FLAG_MAP[i]]) + 2) == 0)
      {
        str = skipTo(str, ':');
        str = skipTo(str, '\"');

        switch(i) {
          case FMU_FLAG_SOLVER: str = setSolverMethod(solverInfo, str); break;
          default: str = skipTo(str, '\n'); break;
        }
      }

      free(value);
    }
    str = skipTo(str, '\"');
   }
}

/**
 * @brief Initialize solver data.
 *
 * Reads optional FMU simulation flags from <fmiPrefix>.fmu/resources/<fmiPrefix>_flags.json.
 * Initialize solver euler or CVODE.
 *
 * @param comp          FMU component.
 * @return int          Return 0 on success and -1 when an error occurred.
 */
int fmuInitializeSolverData(ModelInstance* comp)
{
  /* Variables */
  DATA* data;
  threadData_t* threadData;
  SOLVER_INFO* solverInfo;

  int retValue;

  data = comp->fmuData;
  threadData = comp->threadData;

  /* Allocate memory */
  solverInfo = (SOLVER_INFO*) calloc(1, sizeof(SOLVER_INFO));

  /* Initialize solverInfo */
  solverInfo->currentTime = 0;
  solverInfo->currentStepSize = 0;
  solverInfo->laststep = 0;
  solverInfo->solverMethod = 0;
  solverInfo->solverRootFinding = 0;
  solverInfo->solverNoEquidistantGrid = FALSE;
  solverInfo->lastdesiredStep = solverInfo->currentTime + solverInfo->currentStepSize;
  solverInfo->eventLst = allocList(eventListAlloc, eventListFree, eventListCopy);
  solverInfo->didEventStep = 0;
  solverInfo->stateEvents = 0;
  solverInfo->sampleEvents = 0;

  /* read fmu flags from flags.json */
  size_t filename_len = strlen(comp->fmuData->modelData->resourcesDir) + strlen(comp->fmuData->modelData->modelFilePrefix) + 13;
  char* flags_filename = calloc(filename_len, sizeof(char));
  snprintf(flags_filename, filename_len, "%s/%s_flags.json",
           comp->fmuData->modelData->resourcesDir,
           comp->fmuData->modelData->modelFilePrefix);
  FILTERED_LOG(comp, fmiXOK, LOG_ALL, FMIX_STR "Instantiate: Trying to find simulation settings %s.", flags_filename)

  if( omc_file_exists( flags_filename) )
  {
    FILTERED_LOG(comp, fmiXOK, LOG_ALL, FMIX_STR "Instantiate: Found simulation settings %s.", flags_filename)
    omc_mmap_read mmap_reader = {0};
    mmap_reader = omc_mmap_open_read(flags_filename);
    parseFlags(solverInfo, mmap_reader.data);
    omc_mmap_close_read(mmap_reader);
  }
  else
  {
    FILTERED_LOG(comp, fmiXOK, LOG_ALL, FMIX_STR "Instantiate: Using default simulation settings.")
    solverInfo->solverMethod = S_EULER;
  }

#ifdef OMC_FMI_HAVE_IDA
  /* IDA is the only method that integrates the residual form of a --daeMode model. */
  if (compiledInDAEMode)
  {
    solverInfo->solverMethod = S_IDA;
  }
  else
#endif
  /* If no states are present, we can use Euler's method since it is doing nothing. */
  if (data->modelData->nStates < 1)
  {
    FILTERED_LOG(comp, fmiXOK, LOG_ALL, FMIX_STR "Instantiate: No states present, continuing without ODE solver.")
    solverInfo->solverMethod = S_EULER;
  }

  switch (solverInfo->solverMethod)
  {
    case S_EULER:
      /* Needs no initialization */
      retValue = 0;
      break;
      case S_CVODE:
#ifdef OMC_FMI_HAVE_CVODE
      omc_useStream[OMC_LOG_SOLVER] = 1;
      CVODE_SOLVER* cvodeData = NULL;
      FILTERED_LOG(comp, fmiXOK, LOG_ALL, "Initializing CVODE ODE Solver")
      cvodeData = (CVODE_SOLVER*) calloc(1, sizeof(CVODE_SOLVER));
      if (!cvodeData) {
        FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "Instantiate: Out of memory.")
        freeList(solverInfo->eventLst);
        free(solverInfo);
        return -1;
      } else {
        cvodeData->freeSolverMemory = free;
        retValue = cvode_solver_initial(data, threadData, solverInfo, cvodeData);
      }
      solverInfo->solverData = cvodeData;
      omc_useStream[OMC_LOG_SOLVER] = 0;
#else
      solverInfo->solverData = NULL;
      FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "Instantiate: FMU not compiled with SUNDIALS but solver CVODE selected.")
      retValue = -1;
#endif /* OMC_FMI_HAVE_CVODE */
      break;
    case S_IDA:
#ifdef OMC_FMI_HAVE_IDA
    {
      IDA_SOLVER* idaData = (IDA_SOLVER*) calloc(1, sizeof(IDA_SOLVER));
      if (!idaData) {
        FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "Instantiate: Out of memory.")
        freeList(solverInfo->eventLst);
        free(solverInfo);
        free(flags_filename);
        return -1;
      }
      FILTERED_LOG(comp, fmiXOK, LOG_ALL, "Initializing IDA DAE Solver")
      retValue = ida_solver_initial(data, threadData, solverInfo, idaData);
      solverInfo->solverData = idaData;
    }
#else
      solverInfo->solverData = NULL;
      FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "Instantiate: FMU not compiled with SUNDIALS IDA but solver IDA selected.")
      retValue = -1;
#endif /* OMC_FMI_HAVE_IDA */
      break;
    default:
      FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "Instantiate: Unknown solver method.")
      retValue = -1;
  }

  free(flags_filename);

  comp->solverInfo = solverInfo;

  return retValue;
}

/**
 * @brief Deinitialize solver data.
 *
 * Use for solver data allocated with fmuInitializeSolverData.
 * Frees everything inside comp->solverInfo.
 *
 * @param comp          FMU component.
 * @return int          Return 0 on success and -1 else.
 */
int fmuDeInitializeSolverData(ModelInstance* comp)
{
  /* Variables */
  DATA* data;
  threadData_t* threadData;
  SOLVER_INFO* solverInfo;
  int retValue;

  data = comp->fmuData;
  threadData = comp->threadData;
  solverInfo = comp->solverInfo;

  /* Log function call */
  FILTERED_LOG(comp, fmiXOK, LOG_ALL, FMIX_STR "FreeInstance: Freeing solver data.")

  switch (solverInfo->solverMethod)
  {
    case S_EULER:
      /* Needs no freeing */
      retValue = 0;
      break;
    case S_CVODE:
#ifdef OMC_FMI_HAVE_CVODE
      retValue = cvode_solver_deinitial(solverInfo->solverData);
      break;
#else
      FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "Instantiate: FMU not compiled with SUNDIALS but solver CVODE selected.")
      retValue = -1;
      break;
#endif /* OMC_FMI_HAVE_CVODE */
    case S_IDA:
#ifdef OMC_FMI_HAVE_IDA
      ida_solver_deinitial(solverInfo->solverData);
      free(solverInfo->solverData);
      retValue = 0;
#else
      retValue = -1;
#endif /* OMC_FMI_HAVE_IDA */
      break;
    default:
      FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "FreeInstance: Unknown solver method.")
      retValue = -1;
  }

  freeList(comp->solverInfo->eventLst);
  free(comp->solverInfo);
  comp->solverInfo = NULL;

  return retValue;
}

/* An FMI 3.0 Model Exchange FMU of a --daeMode model serves fmi-ls-dae. A
 * --daeMode FMU has the sources of dae_mode.c with those of IDA. */
#if OMC_FMI_VERSION == 3 && defined(OMC_FMI_HAVE_IDA)
#define OMC_FMI_LS_DAE 1
#endif

#ifdef OMC_FMI_LS_DAE
/* ODE mode: der(x) and the algebraic variables from the residual, with IDA's
 * IDACalcIC as after an event. */
static void solveDAEModeUnknowns(ModelInstance *comp)
{
  if (comp->daeMode || comp->daeSolved || !comp->solverInfo) {
    return;
  }
  if (ida_solver_consistent_ic(comp->fmuData, comp->threadData, (IDA_SOLVER*) comp->solverInfo->solverData) < 0) {
    throwStreamPrint(comp->threadData, "The derivatives of the DAE-mode model could not be solved for (IDACalcIC failed).");
  }
  comp->daeSolved = 1;
}
#define DAE_MODE_CHANGED(comp) ((comp)->daeSolved = 0)
#else
#define DAE_MODE_CHANGED(comp)
#endif

/* A --daeMode model has its continuous equations in the DAE residual function,
 * not in functionODE. In Co-Simulation IDA owns the states, their derivatives
 * and the algebraic DAE variables. In Model Exchange the importer owns them in
 * DAE mode; in ODE mode the residual is solved for them. */
static void evalDAEModeContinuous(ModelInstance* comp)
{
#ifdef OMC_FMI_HAVE_IDA
  if (!compiledInDAEMode) {
    return;
  }
#ifdef OMC_FMI_LS_DAE
  if (FMIX_ME == comp->type) {
    solveDAEModeUnknowns(comp);
    comp->fmuData->simulationInfo->daeModeData->evaluateDAEResiduals(comp->fmuData, comp->threadData, EVAL_DYNAMIC | EVAL_ALGEBRAIC);
    return;
  }
#endif
  comp->fmuData->simulationInfo->daeModeData->evaluateDAEResiduals(comp->fmuData, comp->threadData, EVAL_ALGEBRAIC | EVAL_ZEROCROSS);
#endif
}

#ifdef OMC_FMI_LS_DAE
/* A Model Exchange instance gets its own callbacks, for its IDA instance. */
static void setupDAEModeCallbacks(ModelInstance *comp)
{
  if (!compiledInDAEMode || FMIX_ME != comp->type) {
    return;
  }
  if (!comp->daeCallbacks) {
    comp->daeCallbacks = malloc(sizeof(*comp->daeCallbacks));
  }
  memcpy(comp->daeCallbacks, comp->fmuData->callback, sizeof(*comp->daeCallbacks));
  comp->daeCallbacks->function_ZeroCrossingsEquations = evaluateDAEResiduals_wrapperZeroCrossingsEquations;
  comp->fmuData->callback = comp->daeCallbacks;
}

/* The event iteration of a Model Exchange instance: in ODE mode it solves for
 * the unknowns again between the discrete passes (ida_event_update), in DAE
 * mode the importer does. */
static void setDAEModeEventUpdate(ModelInstance *comp)
{
  if (compiledInDAEMode && FMIX_ME == comp->type) {
    comp->daeCallbacks->functionDAE = comp->daeMode ? evaluateDAEResiduals_wrapperEventUpdate : ida_event_update;
    /* The importer's integrator and its event indicators see der(x) and the
     * algebraic variables as a function of x: IDACalcIC's default stops at
     * IDA's tolerance, and the noise makes the event indicators chatter. */
    IDASetNonlinConvCoefIC(((IDA_SOLVER*) comp->solverInfo->solverData)->ida_mem, 1e-6);
  }
}
#endif

// ---------------------------------------------------------------------------
// Private helpers used below to validate function arguments
// ---------------------------------------------------------------------------
static fmiXBoolean isModelExchange(ModelInstance *comp)
{
  return (FMIX_ME == comp->type);
}

static fmiXBoolean isCoSimulation(ModelInstance *comp)
{
  return (FMIX_CS == comp->type);
}

const char* stateToString(ModelInstance *comp)
{
  if (isModelExchange(comp))
  {
    switch (comp->state)
    {
      case model_state_start_end:               return "model_state_start_end";
      case model_state_instantiated:            return "model_state_instantiated";
      case model_state_initialization_mode:     return "model_state_initialization_mode";
      case model_state_cs_step_complete:        return "model_state_cs_step_complete (invalid!)";
      case model_state_cs_step_in_progress:     return "model_state_cs_step_in_progress (invalid!)";
      case model_state_cs_step_failed:          return "model_state_cs_step_failed (invalid!)";
      case model_state_cs_step_canceled:        return "model_state_cs_step_canceled (invalid!)";
      case model_state_me_event_mode:           return "model_state_me_event_mode";
      case model_state_me_continuous_time_mode: return "model_state_me_continuous_time_mode";
      case model_state_terminated:              return "model_state_terminated";
      case model_state_error:                   return "model_state_error";
      case model_state_fatal:                   return "model_state_fatal";
    }
  }

  if (isCoSimulation(comp))
  {
    switch (comp->state)
    {
      case model_state_start_end:               return "model_state_start_end";
      case model_state_instantiated:            return "model_state_instantiated";
      case model_state_initialization_mode:     return "model_state_initialization_mode";
      case model_state_cs_step_complete:        return "model_state_cs_step_complete";
      case model_state_cs_step_in_progress:     return "model_state_cs_step_in_progress";
      case model_state_cs_step_failed:          return "model_state_cs_step_failed";
      case model_state_cs_step_canceled:        return "model_state_cs_step_canceled";
      case model_state_me_event_mode:           return "model_state_me_event_mode (invalid!)";
      case model_state_me_continuous_time_mode: return "model_state_me_continuous_time_mode (invalid!)";
      case model_state_terminated:              return "model_state_terminated";
      case model_state_error:                   return "model_state_error";
      case model_state_fatal:                   return "model_state_fatal";
    }
  }

  return "Unknown";
}

static fmiXBoolean invalidNumber(ModelInstance *comp, const char *func, const char *arg, int n, int nExpected)
{
  if (n != nExpected)
  {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, "%s: Invalid argument %s = %d. Expected %d.", func, arg, n, nExpected)
    return fmiXTrue;
  }
  return fmiXFalse;
}

static fmiXBoolean invalidState(ModelInstance *comp, const char *func, int meStates, int csStates)
{
  if (!comp)
    return fmiXTrue;

  if (isModelExchange(comp))
  {
    if (!(comp->state & meStates))
    {
      FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, "%s: Illegal model exchange call sequence. %s is not allowed in %s state.", func, func, stateToString(comp))
      comp->state = model_state_error;
      return fmiXTrue;
    }
  }

  if (isCoSimulation(comp))
  {
    if (!(comp->state & csStates))
    {
      FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, "%s: Illegal co-simulation call sequence. %s is not allowed in %s state.", func, func, stateToString(comp))
      comp->state = model_state_error;
      return fmiXTrue;
    }
  }

  return fmiXFalse;
}

static fmiXBoolean nullPointer(ModelInstance* comp, const char *func, const char *arg, const void *p)
{
  if (!p)
  {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, "%s: Invalid argument %s = NULL.", func, arg)
    return fmiXTrue;
  }
  return fmiXFalse;
}

static fmiXBoolean vrOutOfRange(ModelInstance *comp, const char *func, fmiXValueReference vr, int end)
{
  if (vr >= end) {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, "%s: Illegal value reference %u.", func, vr)
    return fmiXTrue;
  }
  return fmiXFalse;
}

static fmiXStatus unsupportedFunction(ModelInstance *comp, const char *func)
{
  FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, "%s: Function not implemented.", func)
  return fmiXError;
}

/**
 * @brief Helper for macro FILTERED_LOG
 *
 * @param comp            Pointer to FMU component.
 * @param categoryIndex   Logging category index.
 * @return fmiXBoolean    Return `fmiXTrue` if logging category is enabled,
 *                        otherwise return `fmiXFalse`.
 */
fmiXBoolean isCategoryLogged(ModelInstance *comp, int categoryIndex)
{
  if (categoryIndex < NUMBER_OF_CATEGORIES && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
    return fmiXTrue;
  }
  return fmiXFalse;
}

static void omc_assert_fmi_common(threadData_t *threadData, fmiXStatus status, int categoryIndex, FILE_INFO info, const char *msg, va_list args)
{
  ModelInstance* c = threadData ? (ModelInstance*) threadData->localRoots[LOCAL_ROOT_FMI_DATA] : NULL;
  char str[2048];
  if (c && !isCategoryLogged(c, categoryIndex)) {
    return;
  }
  vsnprintf(str, sizeof(str), msg, args);
  if (c) {
    if (info.lineStart) {
      FILTERED_LOG(c, status, categoryIndex, "%s:%d: %s", info.filename, info.lineStart, str)
    } else {
      FILTERED_LOG(c, status, categoryIndex, "%s", str)
    }
  } else {
    printInfo(stderr, info);
    fputs("Modelica Assert: ", stderr);
    fputs(str, stderr);
    fputs("!\n", stderr);
  }
}

static void omc_assert_fmi(threadData_t *threadData, FILE_INFO info, const char *msg, ...)
{
  va_list args;
  /* In a nonlinear solve or the integrator's right-hand side the solver may still
   * recover: return the error to it, as omc_assert_function does. Like -lv LOG_NLS
   * in the simulation executable, the message is only debug output then. */
  int toSolver = threadData && (threadData->currentErrorStage == ERROR_NONLINEARSOLVER ||
                                threadData->currentErrorStage == ERROR_INTEGRATOR);
  va_start(args, msg);
  if (toSolver) {
    omc_assert_fmi_common(threadData, fmiXOK,
        threadData->currentErrorStage == ERROR_NONLINEARSOLVER ? LOG_NONLINEARSYSTEMS : LOG_ALL,
        info, msg, args);
  } else {
    omc_assert_fmi_common(threadData, fmiXError, LOG_STATUSERROR, info, msg, args);
  }
  va_end(args);
  if (toSolver) {
    OMC_ERROR_RAISE();
  } else if (threadData) {
    OMC_THROW_INTERNAL();
  } else {
    OMC_THROW();
  }
}

static void omc_assert_fmi_warning(FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  omc_assert_fmi_common((threadData_t*)pthread_getspecific(mmc_thread_data_key), fmiXWarning, LOG_STATUSWARNING, info, msg, args);
  va_end(args);
}

/* Modelica 8.3.8: the simulation stops once the current step or event
   iteration has completed, so only record the request. */
static void omc_terminate_fmi(FILE_INFO info, const char *msg, ...)
{
  threadData_t *threadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  ModelInstance* c = threadData ? (ModelInstance*) threadData->localRoots[LOCAL_ROOT_FMI_DATA] : NULL;
  const char *str;
  va_list ap;
  va_start(ap, msg);
  GC_vasprintf(&str, msg, ap);
  va_end(ap);
  if (c) {
    c->_terminate_simulation_requested = 1;
    FILTERED_LOG(c, fmiXOK, LOG_EVENTS, "%s:%d: terminate(): %s", info.filename, info.lineStart, str)
  } else {
    printInfo(stderr, info);
    fprintf(stderr, "Modelica Terminate: %s!\n", str);
  }
}

// ---------------------------------------------------------------------------
// Private helpers functions
// ---------------------------------------------------------------------------
/* Code without a threadData argument (warning asserts, terminate, ModelicaError)
   finds it through the key. The importer may call from any thread. */
static inline void setThreadData(ModelInstance* comp)
{
#if defined(OM_HAVE_PTHREADS)
  pthread_setspecific(mmc_thread_data_key, comp->threadData);
#endif
}

static void holdAsserts(ModelInstance *comp, int hold);
static void releaseAsserts(ModelInstance *comp);

/* The slot (omc_fmu_paramdeps.h) of value reference vr of a variable of type ty,
 * through aliases; -1 if there is none. */
static long variableSlot(ModelInstance *comp, int ty, fmiXValueReference vr)
{
  MODEL_DATA *md = comp->fmuData->modelData;
  const int *aliases;
  long first, nAliases, v = (long) vr;
  switch (ty) {
  case OMC_SLOT_REAL:
    first = md->nVariablesReal + md->nParametersReal;
    nAliases = md->nAliasReal;
    aliases = comp->fmuData->callback->fmiRealAliasIndexes;
    break;
  case OMC_SLOT_INTEGER:
    first = md->nVariablesInteger + md->nParametersInteger;
    nAliases = md->nAliasInteger;
    aliases = comp->fmuData->callback->fmiIntegerAliasIndexes;
    break;
  case OMC_SLOT_BOOLEAN:
    first = md->nVariablesBoolean + md->nParametersBoolean;
    nAliases = md->nAliasBoolean;
    aliases = comp->fmuData->callback->fmiBooleanAliasIndexes;
    break;
  default:
    first = md->nVariablesString + md->nParametersString;
    nAliases = md->nAliasString;
    aliases = comp->fmuData->callback->fmiStringAliasIndexes;
    break;
  }
  if (v >= first) {
    if (!aliases || v - first >= nAliases) {
      return -1;
    }
    v = aliases[v - first];
    v = v >= 0 ? v : -(v + 1);
  }
  return v < first ? (long) OMC_SLOT(v, ty) : -1;
}

static int isParameterSlot(ModelInstance *comp, long slot)
{
  MODEL_DATA *md = comp->fmuData->modelData;
  long index = slot / 8;
  switch (slot % 8) {
  case OMC_SLOT_REAL: return index >= md->nVariablesReal;
  case OMC_SLOT_INTEGER: return index >= md->nVariablesInteger;
  case OMC_SLOT_BOOLEAN: return index >= md->nVariablesBoolean;
  case OMC_SLOT_STRING: return index >= md->nVariablesString;
  default: return 0;
  }
}

#ifdef OMC_FMI_LS_DAE
/* der(x) or an algebraic DAE variable: the unknowns of the residual. */
static int isDAEModeUnknown(ModelInstance *comp, long index)
{
  long i, nStates = comp->fmuData->modelData->nStates;
  DAEMODE_DATA *daeModeData = comp->fmuData->simulationInfo->daeModeData;
  if (index >= nStates && index < 2*nStates) {
    return 1;
  }
  for (i = 0; i < daeModeData->nAlgebraicDAEVars; i++) {
    if (daeModeData->algIndexes[i] == index) {
      return 1;
    }
  }
  return 0;
}
#endif

/* FMI 2.0 and 3.0: whether the importer may set the variable now, by the
 * causality, variability and initial attributes of modelDescription.xml. */
static fmiXBoolean settableNow(ModelInstance *comp, long slot)
{
  unsigned char f = slot >= 0 && (size_t) slot < comp->paramDeps->nSlots ? comp->paramDeps->flags[slot] : 0;
#ifdef OMC_FMI_LS_DAE
  /* fmi-ls-dae: the importer solves for der(x) and the algebraic variables */
  if (comp->daeMode && (comp->state & (model_state_me_event_mode | model_state_me_continuous_time_mode)) &&
      slot >= 0 && slot % 8 == OMC_SLOT_REAL && isDAEModeUnknown(comp, slot / 8)) {
    return fmiXTrue;
  }
#endif
  switch (comp->state) {
  case model_state_instantiated:
    return (f & (OMC_PARAMDEPS_INITIAL_EXACT | OMC_PARAMDEPS_INITIAL_APPROX | OMC_PARAMDEPS_INPUT)) != 0;
  case model_state_initialization_mode:
    return (f & (OMC_PARAMDEPS_INITIAL_EXACT | OMC_PARAMDEPS_INPUT)) != 0;
  case model_state_me_event_mode:
  case model_state_cs_step_complete:
    return (f & (OMC_PARAMDEPS_INPUT | OMC_PARAMDEPS_TUNABLE)) != 0;
  case model_state_me_continuous_time_mode:
    return (f & OMC_PARAMDEPS_INPUT) && (f & OMC_PARAMDEPS_CONTINUOUS);
  default:
    return fmiXFalse;
  }
}

/* Checks that the importer may set value reference vr now and records the
 * write: before the end of initialization for SetFMUstate, after it as a
 * tunable parameter to update. */
static fmiXStatus recordSet(ModelInstance *comp, const char *func, int ty, fmiXValueReference vr)
{
  long slot;
  if (!comp->paramDeps->checked) {
    return fmiXOK;
  }
  slot = variableSlot(comp, ty, vr);
  if (!settableNow(comp, slot)) {
    FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, "%s: Variable #%u# cannot be set in state %s.", func, vr, stateToString(comp))
    return fmiXError;
  }
  if (comp->state & (model_state_instantiated | model_state_initialization_mode)) {
    if (isParameterSlot(comp, slot)) {
      comp->slotSetBeforeInit[slot] = 1;
    }
  } else if (comp->paramDeps->flags[slot] & OMC_PARAMDEPS_TUNABLE) {
    comp->slotDirty[slot] = 1;
    comp->_tunable_dirty = 1;
  }
  return fmiXOK;
}

/* Evaluates the parameter equations that depend on the tunable parameters set
 * since the last call. */
static void applyTunableParameters(ModelInstance *comp)
{
  if (!comp->_tunable_dirty) {
    return;
  }
  comp->_tunable_dirty = 0;
  comp->_tunable_applied = 1;
  if (omc_fmu_paramdeps_select(comp->paramDeps, comp->slotDirty, comp->eqMask)) {
    memset(comp->slotDirty, 0, comp->paramDeps->nSlots);
    comp->fmuData->callback->updateTunableParameters(comp->fmuData, comp->threadData, comp->eqMask);
  } else {
    memset(comp->slotDirty, 0, comp->paramDeps->nSlots);
  }
}

fmiXStatus internalEventUpdate(fmiXComponent c, fmiXEventInfo* eventInfo)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  fmiXReal nextSampleEvent;
  fmiXBoolean nextSampleEventDefined;
  modelica_boolean nextTimerDefined;
  fmiXReal nextTimerActivationTime;
  int syncRet;

  if (nullPointer(comp, "internalEventUpdate", "eventInfo", eventInfo)) {
    return fmiXError;
  }

  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "internalEventUpdate: Start Event Update! Next Sample Event %g", eventInfo->nextEventTime)

  setThreadData(comp);
  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;
    /* As simulationUpdate does, hold a violated assert() over the event: the event
     * makes the point it was raised for obsolete. The window spans the whole
     * iteration the master drives, not one pass of it, so `_event_found` and
     * `needToReThrow` accumulate over the passes and are settled by the last. */
    holdAsserts(comp, 1);
    applyTunableParameters(comp);
    if (comp->_tunable_applied) {
      eventInfo->nominalsOfContinuousStatesChanged = fmiXTrue;
      if (!isCoSimulation(comp)) {
        comp->_tunable_applied = 0;
      }
    }

    /* simulationUpdate's order: the timers (a tick coincident with an event samples
     * the values before it), then the event, then the timers again below. */
    if (comp->_need_update) {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      evalDAEModeContinuous(comp);
      comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
      /* the update below raises the same violation again */
      comp->_held_assert_logged |= comp->fmuData->simulationInfo->needToReThrow;
      holdAsserts(comp, 1);
    }
    syncRet = handleTimersFMI(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, &nextTimerDefined, &nextTimerActivationTime);
    if (syncRet != 0) {
      eventInfo->valuesOfContinuousStatesChanged = fmiXTrue;
      comp->_event_found = 1;
    }

#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 1)) {
      FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "internalEventUpdate: Need to iterate state values changed!")
      /* if new set is calculated reinit the solver */
      eventInfo->valuesOfContinuousStatesChanged = fmiXTrue;
    }
#endif

    /* store pre-values after events are handled, this will override pre values
     * soon and there is no chance of event triggering for conditons change(u) (i.e) u <> pre(u)
     *https://github.com/OpenModelica/OpenModelica/issues/13811
     */
    //storePreValues(comp->fmuData);

    /* activate sample event */
    for(i=0; i<comp->fmuData->modelData->nSamples; ++i) {
      if (comp->fmuData->simulationInfo->nextSampleTimes[i] <= comp->fmuData->localData[0]->timeValue) {
        comp->fmuData->simulationInfo->samples[i] = 1;
        comp->_event_found = 1;
        infoStreamPrint(LOG_EVENTS, 0, "[%ld] sample(%g, %g)", comp->fmuData->modelData->samplesInfo[i].index, comp->fmuData->modelData->samplesInfo[i].start, comp->fmuData->modelData->samplesInfo[i].interval);
      }
    }

    /* fix issue https://github.com/OpenModelica/OpenModelica/issues/12350
     * we need to update discreteSystem during event update, before evaluating functionDAE
    */
    comp->_held_assert_logged |= comp->fmuData->simulationInfo->needToReThrow;
    holdAsserts(comp, 1);
    updateDiscreteSystem(comp->fmuData, threadData);
    /* The event iteration moved something, so this really is an event: the FMU has
     * no checkEvents() of its own, and by the time updateDiscreteSystem returns the
     * pre-values it settled make the checks below see nothing. */
    if (comp->fmuData->simulationInfo->discreteStateChanged) {
      comp->_event_found = 1;
    }

    comp->fmuData->callback->functionDAE(comp->fmuData, comp->threadData);

    /* deactivate sample events */
    for(i=0; i<comp->fmuData->modelData->nSamples; ++i) {
      if (comp->fmuData->simulationInfo->samples[i]) {
        comp->fmuData->simulationInfo->samples[i] = 0;
        advanceSample(comp->fmuData, i);
      }
    }

    /* Handle clock timers */
    syncRet = handleTimersFMI(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, &nextTimerDefined, &nextTimerActivationTime);

    if (syncRet != 0) {
      comp->_event_found = 1;
    }

    if (checkForDiscreteChanges(comp->fmuData, comp->threadData) || comp->fmuData->simulationInfo->needToIterate || checkRelations(comp->fmuData) || syncRet==2 ) {
      FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "internalEventUpdate: Need to iterate(discrete changes)!")
      comp->_event_found = 1;
      eventInfo->newDiscreteStatesNeeded = fmiXTrue;
      eventInfo->valuesOfContinuousStatesChanged = fmiXTrue;
      eventInfo->terminateSimulation = fmiXFalse;
    } else {
      eventInfo->newDiscreteStatesNeeded = fmiXFalse;
      eventInfo->terminateSimulation = fmiXFalse;
    }
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "internalEventUpdate: newDiscreteStatesNeeded %s",eventInfo->newDiscreteStatesNeeded?"true":"false");


    /* TODO: check the event iteration for relation
     * in FMI import and export. This is an workaround,
     * since the iteration seem not starting.
     */
    storePreValues(comp->fmuData);
    updateRelationsPre(comp->fmuData);
    /* due to an event overwrite old values */
    overwriteOldSimulationData(comp->fmuData);

    updateNextSampleEvent(comp->fmuData, comp->threadData);
    nextSampleEventDefined = getNextSampleTimeFMU(comp->fmuData, &nextSampleEvent);

    /* Get next event time */
    if (nextSampleEventDefined && !nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmiXTrue;
      eventInfo->nextEventTime = nextSampleEvent;
    }
    else if (!nextSampleEventDefined && nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmiXTrue;
      eventInfo->nextEventTime = nextTimerActivationTime;
    }
    else if (nextSampleEventDefined && nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmiXTrue;
      eventInfo->nextEventTime = fmin(nextSampleEvent,nextTimerActivationTime);
    }
    else {
      if (eventInfo->nextEventTime <= comp->fmuData->localData[0]->timeValue) {
        eventInfo->nextEventTimeDefined = fmiXFalse;
      }
    }
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "internalEventUpdate: Checked for Sample Events! Next Sample Event %g",eventInfo->nextEventTime)

    /* Check if ignored assert throw was actually a valid throw */
    releaseAsserts(comp);
    if (comp->fmuData->simulationInfo->needToReThrow && !eventInfo->newDiscreteStatesNeeded) {
      comp->fmuData->simulationInfo->needToReThrow = 0;
      comp->_held_assert_logged = 0;
      if (comp->_event_found) {
        infoStreamPrint(OMC_LOG_ASSERT, 0, "Found event, previous asserts are ignored.");
      } else {
        errorStreamPrint(OMC_LOG_ASSERT, 0, "No event found, but assert was triggered. Throwing now!");
        omc_throw(threadData);
      }
    }

    done=1;

  /* catch */
  OMC_CATCH_INTERNAL(simulationJumpBuffer)
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }
  threadData->mmc_jumper = old_jmp;
  releaseAsserts(comp);

  if (done) {
#ifdef OMC_FMI_LS_DAE
    if (compiledInDAEMode && isModelExchange(comp)) {
      comp->_need_update = 1;
      DAE_MODE_CHANGED(comp);
    }
#endif
    if (comp->_terminate_simulation_requested && !eventInfo->newDiscreteStatesNeeded) {
      comp->_terminate_simulation_requested = 0;
      eventInfo->terminateSimulation = fmiXTrue;
      FILTERED_LOG(comp, fmiXOK, LOG_EVENTS, "internalEventUpdate: terminate simulation requested by the model.")
    }
    return fmiXOK;
  }

  FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, "internalEventUpdate: terminated by an assertion.")
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXError;
}


fmiXStatus internalEventIteration(fmiXComponent c, fmiXEventInfo *eventInfo)
{
  fmiXStatus status = fmiXOK;
  ((ModelInstance *)c)->_event_found = 0;
  eventInfo->newDiscreteStatesNeeded = fmiXTrue;
  eventInfo->terminateSimulation     = fmiXFalse;
  while (eventInfo->newDiscreteStatesNeeded && !eventInfo->terminateSimulation && status != fmiXError) {
    status = internalEventUpdate((ModelInstance *)c, eventInfo);
  }
  return status;
}

/********************************************************************
 * Private helpers for (modelica_)string array handling             *
 ********************************************************************/

  /* size of array of strings is not known at compile-time!      */
  /* figure out total size by repeatedly scanning with strlen(). */
  /* this code relies on the assumption of 1 char = 1 byte.      */

/* A modelica_string array is an array of pointers; what goes into the serialized
   state is the bytes they point at, one NUL-terminated run per element. */
size_t getStringArraySize(const modelica_string *stringArray, int elements) {
    size_t totalSize = 0;
    for (int j = 0; j < elements; j++) {
        totalSize += (stringArray[j] ? omc_string_len(stringArray[j]) : 0) + 1;
    }
    return totalSize;
}

size_t copyStringArray(char* destination, const modelica_string *stringArray, int elements) {
    size_t copiedBytes = 0;
    for (int j = 0; j < elements; j++) {
        const char *str = stringArray[j] ? omc_string_data(stringArray[j]) : "";
        size_t len = strlen(str) + 1;
        memcpy(destination + copiedBytes, str, len);
        copiedBytes += len;
    }
    return copiedBytes;
}

/* The dual of copyStringArray: rebuild counted strings the state buffer owns. */
size_t readStringArray(modelica_string *destination, const char *bytes, int elements) {
    size_t readBytes = 0;
    for (int j = 0; j < elements; j++) {
        const char *str = bytes + readBytes;
        omc_string_move(destination + j, omc_string_new(str));
        readBytes += strlen(str) + 1;
    }
    return readBytes;
}

/**
 * @brief Open C's `noThrowAsserts` for one evaluation.
 *
 * The master cannot say which of its evaluations is an accepted point, so a held
 * violation is logged once and stays quiet until an event settles it.
 */
static void holdAsserts(ModelInstance *comp, int hold)
{
  comp->fmuData->simulationInfo->noThrowAsserts = hold;
  omc_useStream[OMC_LOG_ASSERT] = !hold || !comp->_held_assert_logged;
}

/**
 * @brief Close the window, latching whether it caught a violation.
 */
static void releaseAsserts(ModelInstance *comp)
{
  comp->_held_assert_logged |= comp->fmuData->simulationInfo->needToReThrow;
  comp->fmuData->simulationInfo->noThrowAsserts = 0;
  omc_useStream[OMC_LOG_ASSERT] = 1;
}

/**
 * @brief Helper function for the Get functions to update the component if needed.
 *
 * @param comp          FMI component
 * @param func          Name of the Get function calling this function.
 * @return fmiXStatus   Returns fmiXError if an error was caught, fmiXOK otherwise.
 */
fmiXStatus updateIfNeeded(ModelInstance *comp, const char *func)
{
  /* Variables */
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp=threadData->mmc_jumper;
  int success = 0;

  if (comp->_need_update)
  {
    setThreadData(comp);

    /* TRY */
    OMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

    if (model_state_initialization_mode == comp->state)
    {
      DAE_MODE_CHANGED(comp);
      initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0);
    }
    else
    {
      /* As in simulationUpdate, a violated assert() is held (needToReThrow);
       * completedIntegratorStep turns it into an event, Event Mode evaluates live. */
      holdAsserts(comp, (comp->state & (model_state_me_continuous_time_mode | model_state_cs_step_in_progress | model_state_cs_step_complete)) != 0);
      applyTunableParameters(comp);
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      evalDAEModeContinuous(comp);
      overwriteOldSimulationData(comp->fmuData);
      comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
      comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeSpatialDistribution(comp->fmuData, threadData);
      storePreValues(comp->fmuData);
      releaseAsserts(comp);
    }
    comp->_need_update = 0;
    success = 1;

    /* CATCH */
    OMC_CATCH_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = old_jmp;
    if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); success = 0; }

    releaseAsserts(comp);
    if (!success)
    {
      FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, "%s: terminated by an assertion.", func)
      // TODO: Check if fmiXError or fmiXDiscard should be returned
      return fmiXError;
    }
  }

  return fmiXOK;
}


#ifdef OMC_FMI_LS_DAE
/* fmi-ls-dae: residual i at the values the importer set. Outside of
 * initialization it evaluates only the residual: a DAE-mode importer reads it
 * at its Newton iterates, which must not reach the delay buffers. */
static fmiXStatus internalGetDAEResidual(ModelInstance *comp, long i, fmiXReal *value)
{
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  int done = 0;
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;

  if (invalidState(comp, FMIX_STR "GetFloat64", meStates, csStates))
    return fmiXError;
  if (model_state_initialization_mode == comp->state && updateIfNeeded(comp, FMIX_STR "GetFloat64") != fmiXOK)
    return fmiXError;

  setThreadData(comp);
  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;
    holdAsserts(comp, (comp->state & (model_state_me_continuous_time_mode | model_state_cs_step_complete)) != 0);
    applyTunableParameters(comp);
    if (isModelExchange(comp)) {
      solveDAEModeUnknowns(comp);
    }
    comp->fmuData->simulationInfo->daeModeData->evaluateDAEResiduals(comp->fmuData, threadData, EVAL_DYNAMIC);
    releaseAsserts(comp);
    *value = comp->fmuData->simulationInfo->daeModeData->residualVars[i];
    done = 1;
  /* catch */
  OMC_CATCH_INTERNAL(simulationJumpBuffer)
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }
  threadData->mmc_jumper = old_jmp;
  releaseAsserts(comp);

  if (!done) {
    FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, FMIX_STR "GetFloat64: terminated by an assertion.")
    return fmiXError;
  }
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetFloat64: residual %ld = %.16g", i, *value)
  return fmiXOK;
}
#endif

/***************************************************
Common Functions
****************************************************/
fmiXStatus FMIX(SetDebugLogging)(fmiXComponent c, fmiXBoolean loggingOn, size_t nCategories, const fmiXString categories[])
{
  int i, j;
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, FMIX_STR "SetDebugLogging", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_in_progress|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmiXError;

  comp->loggingOn = loggingOn;
  for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
    comp->logCategories[j] = fmiXFalse;
  }
  for (i = 0; i < nCategories; i++) {
    fmiXBoolean categoryFound = fmiXFalse;
    for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
      if (strcmp(logCategoriesNames[j], categories[i]) == 0) {
        comp->logCategories[j] = loggingOn;
        categoryFound = fmiXTrue;
        break;
      }
    }
    if (!categoryFound) {
      FMIX_LOG(comp, fmiXWarning, LOG_STATUSERROR,
          "logging category '%s' is not supported by model", categories[i]);
    }
  }

  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetDebugLogging")
  return fmiXOK;
}

#if OMC_FMI_VERSION == 2
fmiXComponent FMIX(Instantiate)(fmiXString instanceName, fmi2Type fmuType, fmiXString fmuGUID, fmiXString fmuResourceLocation, const fmi2CallbackFunctions* functions,
    fmiXBoolean visible, fmiXBoolean loggingOn)
#define INSTANTIATE_ERROR(...) functions->logger(functions->componentEnvironment, instanceName, fmiXError, "error", __VA_ARGS__)
#else
ModelInstance* FMIX(Instantiate)(fmiXString instanceName, OMC_FmuType fmuType, fmiXString fmuGUID, fmiXString fmuResourceLocation,
    fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage, fmiXBoolean visible, fmiXBoolean loggingOn)
#define INSTANTIATE_ERROR(...) omc_fmi3_logCallback(logMessage, instanceEnvironment, fmiXError, "logStatusError", __VA_ARGS__)
#endif
{
  /*
  TODO: We should set the interface, but we can't until it's no longer a global variable.
  * The problem is that we might overwrite the main simulation's copy of the interface...
  */
  ModelInstance *comp;
  OMC_FMU_INIT *init;
#if OMC_FMI_VERSION == 2
  if (!functions->logger) {
    return NULL;
  }
#else
  if (!logMessage) {
    return NULL;
  }
#endif
  mmc_init_nogc();
  omc_alloc_interface.init();

  // ignoring arguments: fmuResourceLocation, visible
  if (!instanceName || strlen(instanceName) == 0) {
    INSTANTIATE_ERROR(FMIX_STR "Instantiate: Missing instance name.");
    return NULL;
  }
  if (strcmp(fmuGUID, MODEL_GUID) != 0) {
    INSTANTIATE_ERROR(FMIX_STR "Instantiate: Wrong GUID %s. Expected %s.", fmuGUID, MODEL_GUID);
    return NULL;
  }
  comp = (ModelInstance *)calloc(1, sizeof(ModelInstance));
  if (!comp) {
    INSTANTIATE_ERROR(FMIX_STR "Instantiate: Out of memory.");
    return NULL;
  }
#if OMC_FMI_VERSION == 2
  comp->logger = functions->logger;
  comp->componentEnvironment = functions->componentEnvironment;
#else
  comp->logMessage = logMessage;
  comp->instanceEnvironment = instanceEnvironment;
#endif

  DATA* fmudata = NULL;
  MODEL_DATA* modelData = NULL;
  SIMULATION_INFO* simInfo = NULL;
  threadData_t *threadData = NULL;
  int i;

  comp->state = model_state_start_end;
  comp->instanceName = (fmiXString)calloc(1 + strlen(instanceName), sizeof(char));
  comp->GUID = (fmiXString)calloc(1 + strlen(fmuGUID), sizeof(char));
  fmudata = (DATA *)calloc(1, sizeof(DATA));
  modelData = (MODEL_DATA *)calloc(1, sizeof(MODEL_DATA));
  simInfo = (SIMULATION_INFO *)calloc(1, sizeof(SIMULATION_INFO));
  threadData = (threadData_t *)calloc(1, sizeof(threadData_t));

  /* Every allocation has to be checked before any of them is dereferenced below. */
  if (!comp->instanceName || !comp->GUID || !fmudata || !modelData || !simInfo || !threadData) {
    INSTANTIATE_ERROR(FMIX_STR "Instantiate: Out of memory.");
    free(threadData);
    free(simInfo);
    free(modelData);
    free(fmudata);
    free((void*)comp->GUID);
    free((void*)comp->instanceName);
    free(comp);
    return NULL;
  }

  memset(threadData, 0, sizeof(threadData_t));
  fmudata->modelData = modelData;
  fmudata->simulationInfo = simInfo;
  /*
  pthread_key_create(&fmu_thread_data_key,NULL);
  pthread_setspecific(fmu_thread_data_key, threadData);
  */

  comp->threadData = threadData;
  comp->fmuData = fmudata;
  threadData->localRoots[LOCAL_ROOT_FMI_DATA] = comp;

  // set all categories to on or off. SetDebugLogging should be called to choose specific categories.
  for (i = 0; i < NUMBER_OF_CATEGORIES; i++) {
    comp->logCategories[i] = loggingOn;
  }

  setThreadData(comp);
  omc_assert = omc_assert_fmi;
  omc_assert_warning = omc_assert_fmi_warning;
  omc_terminate = omc_terminate_fmi;

  strcpy((char*)comp->instanceName, (const char*)instanceName);
  comp->type = fmuType;
  strcpy((char*)comp->GUID, (const char*)fmuGUID);
  comp->loggingOn = loggingOn;
  comp->state = model_state_instantiated;

  /* Add the resourcesDir */
  fmuResourceLocation = OpenModelica_parseFmuResourcePath(fmuResourceLocation);
  if (fmuResourceLocation) {
    comp->fmuData->modelData->resourcesDir = calloc(1 + strlen(fmuResourceLocation), sizeof(char));
    strcpy(comp->fmuData->modelData->resourcesDir, fmuResourceLocation);
    free((void*)fmuResourceLocation);
  } else {
    FILTERED_LOG(comp, fmiXOK, LOG_STATUSWARNING, FMIX_STR "Instantiate: Ignoring unknown resource URI: %s", fmuResourceLocation)
  }

  /* initialize modelData */
  omc_useStream[OMC_LOG_STDOUT] = 1;
  omc_useStream[OMC_LOG_ASSERT] = 1;
  FMIX_SETUP_DATA_STRUC(comp->fmuData, comp->threadData);
  init = omc_fmu_init_load(comp->fmuData->modelData);
  if (omc_fmu_init_error(init)) {
    INSTANTIATE_ERROR(FMIX_STR "Instantiate: %s", omc_fmu_init_error(init));
    omc_fmu_init_free(init);
    free(comp->fmuData->modelData->resourcesDir);
    free(threadData);
    free(simInfo);
    free(modelData);
    free(fmudata);
    free((void*)comp->GUID);
    free((void*)comp->instanceName);
    free(comp);
    return NULL;
  }
  comp->paramDeps = omc_fmu_paramdeps_load(comp->fmuData->modelData);
  if (comp->paramDeps->error[0]) {
    INSTANTIATE_ERROR(FMIX_STR "Instantiate: %s", comp->paramDeps->error);
    omc_fmu_paramdeps_free(comp->paramDeps);
    omc_fmu_init_free(init);
    free(comp->fmuData->modelData->resourcesDir);
    free(threadData);
    free(simInfo);
    free(modelData);
    free(fmudata);
    free((void*)comp->GUID);
    free((void*)comp->instanceName);
    free(comp);
    return NULL;
  }
#undef INSTANTIATE_ERROR
#ifdef OMC_FMI_LS_DAE
  setupDAEModeCallbacks(comp);
#endif
  /*
   * load the simulation settings before initializing the DataStruct for fmus
   * fix issue #11855, always take the startTime provided in modeldescription.xml
   * to handle model that have startTime > 0 (e.g) startTime = 0.2
   */
  omc_fmu_init_experiment(init, comp->fmuData->simulationInfo);
  allocModelDataVars(comp->fmuData->modelData, FALSE, comp->threadData);
  scalarAllocArrayAttributes(comp->fmuData->modelData);
  if (comp->fmuData->callback->updateStructuralParameters) {
    comp->fmuData->callback->updateStructuralParameters(comp->fmuData, comp->threadData);
  }
  calculateAllScalarLength(comp->fmuData->modelData);

  /* setup model data with default start data */
  omc_fmu_init_variables(init, comp->fmuData->modelData, 1);
  initializeDataStruc(comp->fmuData, comp->threadData);
  omc_fmu_paramdeps_resize(comp->paramDeps, comp->fmuData->modelData);
  comp->slotDirty = (unsigned char*) calloc(comp->paramDeps->nSlots + 1, 1);
  comp->slotSetBeforeInit = (unsigned char*) calloc(comp->paramDeps->nSlots + 1, 1);
  comp->eqMask = (unsigned char*) calloc(comp->paramDeps->nEqs + 1, 1);

  setAllParamsToStart(comp->fmuData->simulationInfo, comp->fmuData->modelData);
  setAllVarsToStart(comp->fmuData->localData[0], comp->fmuData->simulationInfo, comp->fmuData->modelData);
  omc_fmu_init_variables(init, comp->fmuData->modelData, 0);
  omc_fmu_init_free(init);


#if !defined(OMC_MINIMAL_METADATA)
  modelInfoInit(&(comp->fmuData->modelData->modelDataXml));
#endif

#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeLinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  /* allocate memory for mixed system solvers */
  initializeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NO_STATESELECTION)
  /* allocate memory for state selection */
  initializeStateSetJacobians(comp->fmuData, comp->threadData);
#endif

  /* allocate memory for Jacobian */
  comp->_has_jacobian = 0;
  comp->fmiDerJac = NULL;
  if (comp->fmuData->callback->initialPartialFMIDER != NULL)
  {
    comp->fmiDerJac = (JACOBIAN*) calloc(1, sizeof(JACOBIAN));
    if (! comp->fmuData->callback->initialPartialFMIDER(comp->fmuData, comp->threadData, comp->fmiDerJac))
    {
      comp->_has_jacobian = 1;
    }
  }

  /* allocate memory for Jacobian during initialization DAE */
  comp->_has_jacobian_intialization = 0;
  comp->fmiDerJacInitialization = NULL;
  if (comp->fmuData->callback->initialPartialFMIDERINIT != NULL)
  {
    comp->fmiDerJacInitialization = (JACOBIAN*) calloc(1, sizeof(JACOBIAN));
    if (! comp->fmuData->callback->initialPartialFMIDERINIT(comp->fmuData, comp->threadData, comp->fmiDerJacInitialization))
    {
      comp->_has_jacobian_intialization = 1;
    }
  }

  // int cols = comp->fmiDerJac->sizeCols;
  // int rows = comp->fmiDerJac->sizeRows;
  // printf("\nFMIDER number of rows and colums");
  // printf("\nNumber of rows   : %i", rows);
  // printf("\nNumber of columns: %i", cols);
  // printf("\n");

  // int cols_ = comp->fmiDerJacInitialization->sizeCols;
  // int rows_ = comp->fmiDerJacInitialization->sizeRows;
  // printf("\nFMIDER INITIALIZATION number of rows and colums");
  // printf("\nNumber of rows   : %i", rows_);
  // printf("\nNumber of columns: %i", cols_);
  // printf("\n");

#if NUMBER_OF_STATES > 0
  comp->states = (fmiXReal*)calloc(NUMBER_OF_STATES, sizeof(fmiXReal));
  comp->states_der = (fmiXReal*)calloc(NUMBER_OF_STATES, sizeof(fmiXReal));
#else
  comp->states = NULL;
  comp->states_der = NULL;
#endif
#if NUMBER_OF_EVENT_INDICATORS > 0
  comp->event_indicators = (fmiXReal*)calloc(NUMBER_OF_EVENT_INDICATORS, sizeof(fmiXReal));
  comp->event_indicators_prev = (fmiXReal*)calloc(NUMBER_OF_EVENT_INDICATORS, sizeof(fmiXReal));
#else
  comp->event_indicators = NULL;
  comp->event_indicators_prev = NULL;
#endif
#if NUMBER_OF_REAL_INPUTS > 0
  comp->input_real_derivative = (fmiXReal*)calloc(NUMBER_OF_REAL_INPUTS, sizeof(fmiXReal));
#else
  comp->input_real_derivative = NULL;
#endif

  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);

  /* Initialize solverInfo */
  if (isCoSimulation(comp) || (compiledInDAEMode && isModelExchange(comp))) {
    fmuInitializeSolverData(comp);
#ifdef OMC_FMI_LS_DAE
    setDAEModeEventUpdate(comp);
#endif
  } else {
    comp->solverInfo = NULL;
  }

  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "Instantiate: GUID=%s", fmuGUID)
  return comp;
}

void FMIX(FreeInstance)(fmiXComponent c)
{
  ModelInstance *comp = (ModelInstance *)c;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;

  if (invalidState(comp, FMIX_STR "FreeInstance", meStates, csStates))
    return;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "FreeInstance...")

  /* Free CS simulator (CVODE & co) first, while the model data it references
   * (e.g. the states array wrapped by the solver's N_Vector y) is still alive. */
  if (comp->solverInfo) {
    fmuDeInitializeSolverData(comp);
  }

  setThreadData(comp);
  /* call external objects destructors */
  comp->fmuData->callback->callExternalObjectDestructors(comp->fmuData, comp->threadData);
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  /* free nonlinear system data */
  freeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  /* free mixed system data */
  freeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  /* free linear system data */
  freeLinearSystems(comp->fmuData, comp->threadData);
#endif
  /* free data struct */
  deInitializeDataStruc(comp->fmuData);

  /* Free jacobian data */
  if (comp->_has_jacobian == 1) {
    free(comp->fmiDerJac->seedVars); comp->fmiDerJac->seedVars = NULL;
    free(comp->fmiDerJac->resultVars); comp->fmiDerJac->resultVars = NULL;
    free(comp->fmiDerJac->tmpVars); comp->fmiDerJac->tmpVars = NULL;

    free(comp->fmiDerJac->sparsePattern->leadindex); comp->fmiDerJac->sparsePattern->leadindex = NULL;
    free(comp->fmiDerJac->sparsePattern->index); comp->fmiDerJac->sparsePattern->index = NULL;
    free(comp->fmiDerJac->sparsePattern->colorCols); comp->fmiDerJac->sparsePattern->colorCols = NULL;
    free(comp->fmiDerJac->sparsePattern); comp->fmiDerJac->sparsePattern = NULL;

    free(comp->fmiDerJac); comp->fmiDerJac=NULL;
  }


  /* Free jacobian data */
  if (comp->_has_jacobian_intialization == 1) {
    free(comp->fmiDerJacInitialization->seedVars); comp->fmiDerJacInitialization->seedVars = NULL;
    free(comp->fmiDerJacInitialization->resultVars); comp->fmiDerJacInitialization->resultVars = NULL;
    free(comp->fmiDerJacInitialization->tmpVars); comp->fmiDerJacInitialization->tmpVars = NULL;

    free(comp->fmiDerJacInitialization->sparsePattern->leadindex); comp->fmiDerJacInitialization->sparsePattern->leadindex = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern->index); comp->fmiDerJacInitialization->sparsePattern->index = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern->colorCols); comp->fmiDerJacInitialization->sparsePattern->colorCols = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern); comp->fmiDerJacInitialization->sparsePattern = NULL;

    free(comp->fmiDerJacInitialization); comp->fmiDerJacInitialization=NULL;
  }

  free(comp->states); comp->states = NULL;
  free(comp->states_der); comp->states_der = NULL;
  free(comp->event_indicators); comp->event_indicators = NULL;
  free(comp->event_indicators_prev); comp->event_indicators_prev = NULL;
  free(comp->input_real_derivative); comp->input_real_derivative = NULL;
  free(comp->slotDirty);
  free(comp->slotSetBeforeInit);
  free(comp->eqMask);
#ifdef OMC_FMI_LS_DAE
  free(comp->daeCallbacks);
#endif
  omc_fmu_paramdeps_free(comp->paramDeps);

  free(comp->fmuData->modelData->resourcesDir);

  /* free simuation data */
  free(comp->fmuData->modelData);
  free(comp->fmuData->simulationInfo);

  /* free fmuData */
  free(comp->threadData);
  free(comp->fmuData);
  /* free instanceName & GUID */
  free((void*)comp->instanceName);
  free((void*)comp->GUID);
  /* free comp */
  free(comp);
}

fmiXStatus FMIX(SetupExperiment)(fmiXComponent c, fmiXBoolean toleranceDefined, fmiXReal tolerance, fmiXReal startTime, fmiXBoolean stopTimeDefined, fmiXReal stopTime)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, FMIX_STR "SetupExperiment", model_state_instantiated, model_state_instantiated))
    return fmiXError;

  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL,
    FMIX_STR "SetupExperiment: toleranceDefined=%d tolerance=%g startTime=%g stopTimeDefined=%d stopTime=%g",
    toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime)

  comp->toleranceDefined = toleranceDefined;
  comp->tolerance = tolerance;
  if (toleranceDefined) {
    comp->fmuData->simulationInfo->tolerance = tolerance;
  }
  comp->startTime = startTime;
  comp->stopTimeDefined = stopTimeDefined;
  comp->stopTime = stopTime;
  /* fix issue https://github.com/OpenModelica/OpenModelica/issues/12561
    update the startTime values provided by users (e.g) OMSimulator test.fmu --startTime=2.5
  */
  comp->fmuData->localData[0]->timeValue = startTime;
  return fmiXOK;
}

fmiXStatus FMIX(EnterInitializationMode)(fmiXComponent c)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, FMIX_STR "EnterInitializationMode", model_state_instantiated, model_state_instantiated))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "EnterInitializationMode...")

  setZCtol(comp->fmuData->simulationInfo->tolerance); /* set zero-crossing tolerance */
  setStartToCurrentValues(comp->fmuData);
  copyStartValuestoInitValues(comp->fmuData);
  comp->state = model_state_initialization_mode;

  return fmiXOK;
}

fmiXStatus FMIX(ExitInitializationMode)(fmiXComponent c)
{
  fmiXStatus res = fmiXError;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  fmiXReal nextSampleEvent;
  fmiXBoolean nextSampleEventDefined;
  int done=0;

  threadData->currentErrorStage = ERROR_SIMULATION;
  if (invalidState(comp, FMIX_STR "ExitInitializationMode", model_state_initialization_mode, model_state_initialization_mode))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "ExitInitializationMode...")

  setThreadData(comp);

  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = threadData->simulationJumpBuffer;

  if (comp->_need_update)
  {
    DAE_MODE_CHANGED(comp);
    if (initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0))
    {
      comp->state = model_state_error;
      OMC_RESTORE_INTERNAL(simulationJumpBuffer);
      threadData->mmc_jumper = old_jmp;
      FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, FMIX_STR "ExitInitializationMode: failed")
      return fmiXError;
    }
  }

#ifdef OMC_FMI_HAVE_CVODE
  /* As updateSolverNominals: the nominals and the tolerance are known now. */
  if (comp->solverInfo && comp->solverInfo->solverMethod == S_CVODE) {
    cvode_solver_setNominals(comp->fmuData, comp->threadData, comp->solverInfo->solverData);
  }
#endif
#ifdef OMC_FMI_HAVE_IDA
  if (comp->solverInfo && comp->solverInfo->solverMethod == S_IDA) {
    ida_solver_setNominals(comp->fmuData, comp->threadData, comp->solverInfo->solverData);
  }
#endif

  /* use defined stopTime, if stopTimeDefined is given to calculate the sample events beforehand.
   * TODO: when stopTime is not defined we use an arbitrary constant 100.0, maybe issue a warning
   */
  initSample(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, comp->stopTimeDefined ? comp->stopTime : 100.0 /* default stopTime */);
  /* overwrite old values due to an event */
  overwriteOldSimulationData(comp->fmuData);

  comp->eventInfo.terminateSimulation = fmiXFalse;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmiXTrue;

  /* get next event time (sample calls) */
  nextSampleEventDefined = getNextSampleTimeFMU(comp->fmuData, &nextSampleEvent);
  if (nextSampleEventDefined)
  {
    comp->eventInfo.nextEventTimeDefined = fmiXTrue;
    comp->eventInfo.nextEventTime = nextSampleEvent;
    internalEventUpdate(comp, &(comp->eventInfo));
  }
  else
  {
    comp->eventInfo.nextEventTimeDefined = fmiXFalse;
  }
  res = fmiXOK;

  done = 1;
  /* catch */
  OMC_CATCH_INTERNAL(simulationJumpBuffer)
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }
  threadData->mmc_jumper = old_jmp;

  if (!done)
  {
    FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, FMIX_STR "ExitInitializationMode: terminated by an assertion.")
  }

  comp->state = isCoSimulation(comp) ? model_state_cs_step_complete : model_state_me_event_mode;

  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "ExitInitializationMode: succeed")
  return res;
}

/*
 * fmiXStatus FMIX(Terminate)(fmiXComponent c);
 * Informs the FMU that the simulation run is terminated. After calling this function, the final
 * values of all variables can be inquired with the Get functions. It is not allowed
 * to call this function after one of the functions returned with a status flag of fmiXError or
 * fmiXFatal.
 *
 */
fmiXStatus FMIX(Terminate)(fmiXComponent c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, FMIX_STR "Terminate", model_state_me_event_mode|model_state_me_continuous_time_mode, model_state_cs_step_complete|model_state_cs_step_failed))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "Terminate...")

  comp->state = model_state_terminated;
  return fmiXOK;
}

/*!
 * Is called by the environment to reset the FMU after a simulation run. Before starting a new run, EnterInitializationMode has to be called.
 */
fmiXStatus FMIX(Reset)(fmiXComponent c)
{
  ModelInstance* comp = (ModelInstance *)c;
  modelica_boolean modelDataVarsFreed = FALSE;
  OMC_FMU_INIT *init;
  if (invalidState(comp, FMIX_STR "Reset", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "Reset")

  setThreadData(comp);
  /* Free CS simulator (CVODE & co) first, while the model data it references
   * (e.g. the states array wrapped by the solver's N_Vector y) is still alive,
   * see #16319/#14074/#8615. */
  if (comp->solverInfo) {
    fmuDeInitializeSolverData(comp);
  }

  /* Free modelData */
  if (!(comp->state & model_state_terminated)) {
    /* call external objects destructors */
    comp->fmuData->callback->callExternalObjectDestructors(comp->fmuData, comp->threadData);
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
    /* free nonlinear system data */
    freeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
    /* free mixed system data */
    freeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
    /* free linear system data */
    freeLinearSystems(comp->fmuData, comp->threadData);
#endif
    /* free data struct */
    deInitializeDataStruc(comp->fmuData);
    modelDataVarsFreed = TRUE;
  }

  /* Initialize modelData */
  omc_useStream[OMC_LOG_STDOUT] = 1;
  omc_useStream[OMC_LOG_ASSERT] = 1;
  FMIX_SETUP_DATA_STRUC(comp->fmuData, comp->threadData);
#ifdef OMC_FMI_LS_DAE
  setupDAEModeCallbacks(comp);
#endif
  init = omc_fmu_init_load(comp->fmuData->modelData);
  if (omc_fmu_init_error(init)) {
    FILTERED_LOG(comp, fmiXError, LOG_STATUSERROR, FMIX_STR "Reset: %s", omc_fmu_init_error(init))
    omc_fmu_init_free(init);
    comp->state = model_state_error;
    return fmiXError;
  }
  if (modelDataVarsFreed) {
    /* deInitializeDataStruc freed the var data arrays; re-allocate them before they are
     * initialized and filled again, mirroring Instantiate. */
    allocModelDataVars(comp->fmuData->modelData, FALSE, comp->threadData);
    scalarAllocArrayAttributes(comp->fmuData->modelData);
    if (comp->fmuData->callback->updateStructuralParameters) {
      comp->fmuData->callback->updateStructuralParameters(comp->fmuData, comp->threadData);
    }
    calculateAllScalarLength(comp->fmuData->modelData);
  }
  omc_fmu_init_experiment(init, comp->fmuData->simulationInfo);
  initializeDataStruc(comp->fmuData, comp->threadData);

  /* reset model data with default start data */
  omc_fmu_init_variables(init, comp->fmuData->modelData, 1);
  setAllParamsToStart(comp->fmuData->simulationInfo, comp->fmuData->modelData);
  setAllVarsToStart(comp->fmuData->localData[0], comp->fmuData->simulationInfo ,comp->fmuData->modelData);
  omc_fmu_init_variables(init, comp->fmuData->modelData, 0);
  omc_fmu_init_free(init);
#if !defined(OMC_MINIMAL_METADATA)
  modelInfoInit(&(comp->fmuData->modelData->modelDataXml));
#endif

#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeLinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  /* allocate memory for mixed system solvers */
  initializeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NO_STATESELECTION)
  /* allocate memory for state selection */
  initializeStateSetJacobians(comp->fmuData, comp->threadData);
#endif

  /* Initialize solverInfo */
  if (isCoSimulation(comp) || (compiledInDAEMode && isModelExchange(comp))) {
    fmuInitializeSolverData(comp);
#ifdef OMC_FMI_LS_DAE
    setDAEModeEventUpdate(comp);
#endif
  } else {
    comp->solverInfo = NULL;
  }

  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  comp->_terminate_simulation_requested = 0;
  memset(comp->slotDirty, 0, comp->paramDeps->nSlots);
  memset(comp->slotSetBeforeInit, 0, comp->paramDeps->nSlots);
  comp->_tunable_dirty = 0;
  comp->_tunable_applied = 0;
#if OMC_FMI_VERSION == 2
  comp->terminated = fmiXFalse;
#endif
  comp->state = model_state_instantiated;
  return fmiXOK;
}

fmiXStatus FMIX(GetReal)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, fmiXReal value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance*)c;

  // Model exchange
  // - initialization mode (2) for a variable with causality = "output", or continuous-time states or state derivatives
  // - event mode
  // - continuous-time mode
  // - terminated
  // - error (7) always, but retrieved values are usable for debugging only
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;

  // Co-simulation
  // - initialization mode (2) for a variable with causality = "output" or continuous-time states or state derivatives (if element <Derivatives> is present)
  // - stepComplete
  // - stepFailed (8) always, but if status is other than terminated, retrieved values are useable for debugging only
  // - stepCanceled (7) always, but retrieved values are usable for debugging only
  // - terminated
  // - error (7) always, but retrieved values are usable for debugging only
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;

  /* Check for valid call sequence */
  if (invalidState(comp, FMIX_STR "GetReal", meStates, csStates))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetReal", "vr[]", vr))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetReal", "value[]", value))
    return fmiXError;

#if NUMBER_OF_REALS > 0
  if (updateIfNeeded(comp, FMIX_STR "GetReal") != fmiXOK)
    return fmiXError;
#endif

  for (i = 0; i < nvr; i++)
  {
#if OMC_FMI_VERSION == 2
    if (vr[i] == FMI2_TIME_VR) {
      value[i] = comp->fmuData->localData[0]->timeValue;
      continue;
    }
#endif
    if (vrOutOfRange(comp, FMIX_STR "GetReal", vr[i], NUMBER_OF_REALS)) {
      return fmiXError;
    }
#if NUMBER_OF_REALS > 0
    value[i] = getReal(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetReal: #r%u# = %.16g", vr[i], value[i])
#endif
  }
  return fmiXOK;
}

fmiXStatus FMIX(GetInteger)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, fmiXInteger value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, FMIX_STR "GetInteger", meStates, csStates))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetInteger", "vr[]", vr))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetInteger", "value[]", value))
    return fmiXError;

#if NUMBER_OF_INTEGERS > 0
  if (updateIfNeeded(comp, FMIX_STR "GetInteger") != fmiXOK)
    return fmiXError;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "GetInteger", vr[i], NUMBER_OF_INTEGERS)) {
      return fmiXError;
    }
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetInteger: #i%u# = %d", vr[i], value[i])
  }
#endif
  return fmiXOK;
}

fmiXStatus FMIX(GetBoolean)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, fmiXBoolean value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, FMIX_STR "GetBoolean", meStates, csStates))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetBoolean", "vr[]", vr))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetBoolean", "value[]", value))
    return fmiXError;

#if NUMBER_OF_BOOLEANS > 0
  if (updateIfNeeded(comp, FMIX_STR "GetBoolean") != fmiXOK)
    return fmiXError;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "GetBoolean", vr[i], NUMBER_OF_BOOLEANS)) {
      return fmiXError;
    }
    value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false")
  }
#endif
  return fmiXOK;
}

fmiXStatus FMIX(GetString)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, fmiXString value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, FMIX_STR "GetString", meStates, csStates))
    return fmiXError;
  if (nvr>0 && nullPointer(comp, FMIX_STR "GetString", "vr[]", vr))
    return fmiXError;
  if (nvr>0 && nullPointer(comp, FMIX_STR "GetString", "value[]", value))
    return fmiXError;

#if NUMBER_OF_STRINGS > 0
  if (updateIfNeeded(comp, FMIX_STR "GetString") != fmiXOK)
    return fmiXError;

  for (i=0; i<nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "GetString", vr[i], NUMBER_OF_STRINGS))
      return fmiXError;
    value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetString: #s%u# = '%s'", vr[i], value[i])
  }
#endif
  return fmiXOK;
}

fmiXStatus FMIX(SetReal)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, const fmiXReal value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  // Model exchange
  // - instantiated (1) for a variable with variability != "constant" that has initial = "exact" or "approx"
  // - initialization mode (3) for a variable with variability != "constant" that has initial = "exact", or causality = "input"
  // - event mode (4) for a variable with causality = "input", or (causality = "parameter" and variability = "tunable")
  // - continuous-time mode (5) for a variable with causality = "input" and variability = "continuous"
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode;

  // Co-simulation
  // - instantiated (1) for a variable with variability != "constant" that has initial = "exact" or "approx"
  // - initialization mode (3) for a variable with variability != "constant" that has initial = "exact", or causality = "input"
  // - stepComplete (6) for a variable with causality = "input" or (causality = "parameter" and variability = "tunable")
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, FMIX_STR "SetReal", meStates, csStates))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "SetReal", "vr[]", vr))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "SetReal", "value[]", value))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetReal: nvr = %zu", nvr)
  // no check whether setting the value is allowed in the current state
  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "SetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmiXError;
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetReal: #r%u# = %.16g", vr[i], value[i])
    if (recordSet(comp, FMIX_STR "SetReal", OMC_SLOT_REAL, vr[i]) != fmiXOK)
      return fmiXError;
    if (setReal(comp, vr[i], value[i]) != fmiXOK) // to be implemented by the includer of this file
      return fmiXError;
  }
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXOK;
}

fmiXStatus FMIX(SetInteger)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, const fmiXInteger value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = SET_DISCRETE_ME_STATES;
  int csStates = SET_DISCRETE_CS_STATES;

  if (invalidState(comp, FMIX_STR "SetInteger", meStates, csStates))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "SetInteger", "vr[]", vr))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "SetInteger", "value[]", value))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetInteger: nvr = %zu", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "SetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiXError;
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetInteger: #i%u# = %d", vr[i], value[i])
    if (recordSet(comp, FMIX_STR "SetInteger", OMC_SLOT_INTEGER, vr[i]) != fmiXOK)
      return fmiXError;
    if (setInteger(comp, vr[i], value[i]) != fmiXOK) // to be implemented by the includer of this file
      return fmiXError;
  }
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXOK;
}

fmiXStatus FMIX(SetBoolean)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, const fmiXBoolean value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = SET_DISCRETE_ME_STATES;
  int csStates = SET_DISCRETE_CS_STATES;

  if (invalidState(comp, FMIX_STR "SetBoolean", meStates, csStates))
    return fmiXError;
  if (nvr>0 && nullPointer(comp, FMIX_STR "SetBoolean", "vr[]", vr))
    return fmiXError;
  if (nvr>0 && nullPointer(comp, FMIX_STR "SetBoolean", "value[]", value))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetBoolean: nvr = %zu", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "SetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiXError;
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetBoolean: #b%u# = %s", vr[i], value[i] ? "true" : "false")
    if (recordSet(comp, FMIX_STR "SetBoolean", OMC_SLOT_BOOLEAN, vr[i]) != fmiXOK)
      return fmiXError;
    if (setBoolean(comp, vr[i], value[i]) != fmiXOK) // to be implemented by the includer of this file
      return fmiXError;
  }
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXOK;
}

fmiXStatus FMIX(SetString)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, const fmiXString value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = SET_DISCRETE_ME_STATES;
  int csStates = SET_DISCRETE_CS_STATES;

  if (invalidState(comp, FMIX_STR "SetString", meStates, csStates))
    return fmiXError;
  if (nvr>0 && nullPointer(comp, FMIX_STR "SetString", "vr[]", vr))
    return fmiXError;
  if (nvr>0 && nullPointer(comp, FMIX_STR "SetString", "value[]", value))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetString: nvr = %zu", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "SetString", vr[i], NUMBER_OF_STRINGS))
      return fmiXError;
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetString: #s%u# = '%s'", vr[i], value[i])
    if (recordSet(comp, FMIX_STR "SetString", OMC_SLOT_STRING, vr[i]) != fmiXOK)
      return fmiXError;
    if (setString(comp, vr[i], value[i]) != fmiXOK) // to be implemented by the includer of this file
      return fmiXError;
  }
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXOK;
}

fmiXStatus FMIX(FreeFMUstate)(fmiXComponent c, fmiXFMUstate* FMUstate);

fmiXStatus FMIX(GetFMUstate)(fmiXComponent c, fmiXFMUstate* FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;
  int meStates = FMU_STATE_ME_STATES;
  int csStates = FMU_STATE_CS_STATES;

  if (invalidState(comp, FMIX_STR "GetFMUstate", meStates, csStates))
    return fmiXError;
  if (comp->_tunable_dirty) {
    comp->_need_update = 1;
    DAE_MODE_CHANGED(comp);
    if (updateIfNeeded(comp, FMIX_STR "GetFMUstate") != fmiXOK)
      return fmiXError;
  }
  /* Restoring a state this instance saved restores all its parameters. */
  memset(comp->slotSetBeforeInit, 0, comp->paramDeps->nSlots);

  INTERNAL_FMU_STATE* internal_state = (INTERNAL_FMU_STATE*) calloc(1, sizeof(INTERNAL_FMU_STATE));
  internal_state->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));

  DATA* fmudata = (DATA *) comp->fmuData;

  /* prepare RingBuffer, by allocating memory for real Vars
   * copy the ring buffer data to INTERNAL_FMU_STATE
  */
  SIMULATION_DATA tmpSimData = {0};
  for (int i = 0; i < SIZERINGBUFFER; i++)
  {
    tmpSimData.timeValue = fmudata->localData[i]->timeValue;
    /* allocate memory for all Real variables */
    tmpSimData.realVars = (modelica_real *)calloc(fmudata->modelData->nVariablesReal, sizeof(modelica_real));
    memcpy(tmpSimData.realVars, fmudata->localData[i]->realVars, sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    /* allocate memory for all Integer variables */
    tmpSimData.integerVars = (modelica_integer*)calloc(fmudata->modelData->nVariablesInteger, sizeof(modelica_integer));
    memcpy(tmpSimData.integerVars, fmudata->localData[i]->integerVars, sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    /* allocate memory for all boolean variables */
    tmpSimData.booleanVars = (modelica_boolean*)calloc(fmudata->modelData->nVariablesBoolean, sizeof(modelica_boolean));
    memcpy(tmpSimData.booleanVars, fmudata->localData[i]->booleanVars, sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    /* allocate memory for all string variables */
    #if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
      tmpSimData.stringVars = (modelica_string*) omc_alloc_interface.malloc_uncollectable(fmudata->modelData->nVariablesString * sizeof(modelica_string));
      omc_string_slots_store(tmpSimData.stringVars, fmudata->localData[i]->stringVars, fmudata->modelData->nVariablesString);
    #endif
    appendRingData(internal_state->simulationData, &tmpSimData);
  }

  // copy real parameter variables
  internal_state->realParameter = (modelica_real*)calloc(fmudata->modelData->nParametersReal, sizeof(modelica_real));
  for (int i = 0; i < fmudata->modelData->nParametersReal; ++i)
  {
    internal_state->realParameter[i] = fmudata->simulationInfo->realParameter[i];
    // infoStreamPrint(OMC_LOG_STDOUT, 0, "Copy Real parameter %s = %g", fmudata->modelData->realParameterData[i].info.name, internal_state->realParameter[i]);
  }

  // copy Integer parameter variables
  internal_state->integerParameter = (modelica_integer*)calloc(fmudata->modelData->nParametersInteger, sizeof(modelica_integer));
  for (int i = 0; i < fmudata->modelData->nParametersInteger; ++i)
  {
    internal_state->integerParameter[i] = fmudata->simulationInfo->integerParameter[i];
    // infoStreamPrint(OMC_LOG_STDOUT, 0, "Copy Integer parameter %s = %ld", fmudata->modelData->integerParameterData[i].info.name, (long)internal_state->integerParameter[i]);
  }

  // copy Boolean parameter variables
  internal_state->booleanParameter = (modelica_boolean*)calloc(fmudata->modelData->nParametersBoolean, sizeof(modelica_boolean));
  for (int i = 0; i < fmudata->modelData->nParametersBoolean; ++i)
  {
    internal_state->booleanParameter[i] = fmudata->simulationInfo->booleanParameter[i];
    // infoStreamPrint(OMC_LOG_STDOUT, 0, "Copy Boolean parameter %s = %s", fmudata->modelData->booleanParameterData[i].info.name, internal_state->booleanParameter[i] ? "true" : "false");
  }

  // copy String parameter variables
  internal_state->stringParameter = (modelica_string*) omc_alloc_interface.malloc_uncollectable(fmudata->modelData->nParametersString * sizeof(modelica_string));
  for (int i = 0; i < fmudata->modelData->nParametersString; ++i)
  {
    omc_string_store(&internal_state->stringParameter[i], fmudata->simulationInfo->stringParameter[i]);
    // infoStreamPrint(OMC_LOG_STDOUT, 0, "Copy String parameter %s = %s", fmudata->modelData->stringParameterData[i].info.name, MMC_STRINGDATA(internal_state->stringParameter[i]));
  }

  //infoRingBuffer( fmudata->simulationData);
  //printRingBufferSimulationData(fmudata->simulationData, fmudata); // original ringBuffer data
  //printRingBufferSimulationData(internal_state->simulationData, fmudata); // copied ringBuffer data

  internal_state->nHistory = delayStateWords(fmudata, NULL) + spatialDistributionStateWords(fmudata, NULL);
  internal_state->history = (double*) calloc(internal_state->nHistory ? internal_state->nHistory : 1, sizeof(double));
  spatialDistributionStateWords(fmudata, internal_state->history + delayStateWords(fmudata, internal_state->history));

  /* release previous fmu state if existent */
  /* TODO: ideally, previous state's memory should be re-used instead of re-allocation */
  if (*FMUstate != NULL) FMIX(FreeFMUstate)(c, FMUstate);

  // return the fmu state
  *FMUstate = (fmiXFMUstate) internal_state;
  return fmiXOK;
}

fmiXStatus FMIX(SetFMUstate)(fmiXComponent c, fmiXFMUstate FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;
  fmiXStatus status = fmiXOK;

  int meStates = FMU_STATE_ME_STATES;
  int csStates = FMU_STATE_CS_STATES;

  if (invalidState(comp, FMIX_STR "SetFMUstate", meStates, csStates))
    return fmiXError;

  INTERNAL_FMU_STATE * internal_state = (INTERNAL_FMU_STATE *) FMUstate;
  DATA* fmudata = (DATA *) comp->fmuData;

  //printRingBufferSimulationData(internal_state->simulationData, fmudata); // copied ringBuffer data

  /* The parameters come from the state, except those the importer set before
   * the end of initialization and the values calculated from them: those keep
   * their current values (#15216). */
  OMC_FMU_PARAMDEPS *deps = comp->paramDeps;
  MODEL_DATA *md = fmudata->modelData;
  unsigned char *keep = (unsigned char*) malloc(deps->nSlots + 1);
  unsigned char *mask = (unsigned char*) calloc(deps->nEqs + 1, 1);
  modelica_real *curReal = (modelica_real*) malloc((md->nVariablesReal + 1) * sizeof(modelica_real));
  modelica_integer *curInt = (modelica_integer*) malloc((md->nVariablesInteger + 1) * sizeof(modelica_integer));
  modelica_boolean *curBool = (modelica_boolean*) malloc((md->nVariablesBoolean + 1) * sizeof(modelica_boolean));
  if (!keep || !mask || !curReal || !curInt || !curBool) { status = fmiXError; goto cleanup; }
  if (deps->checked) {
    memcpy(keep, comp->slotSetBeforeInit, deps->nSlots);
    omc_fmu_paramdeps_select(deps, keep, mask);
  } else {
    memset(keep, 1, deps->nSlots);
  }
  memcpy(curReal, fmudata->localData[0]->realVars, md->nVariablesReal * sizeof(modelica_real));
  memcpy(curInt, fmudata->localData[0]->integerVars, md->nVariablesInteger * sizeof(modelica_integer));
  memcpy(curBool, fmudata->localData[0]->booleanVars, md->nVariablesBoolean * sizeof(modelica_boolean));

  // override the SIMULATION_DATA with INTERNAL_FMU_STATE
  for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++)
  {
    SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
    fmudata->localData[i]->timeValue = sdata->timeValue;
    memcpy(fmudata->localData[i]->realVars, sdata->realVars, sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    memcpy(fmudata->localData[i]->integerVars, sdata->integerVars, sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    memcpy(fmudata->localData[i]->booleanVars, sdata->booleanVars, sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    omc_string_slots_store(fmudata->localData[i]->stringVars, sdata->stringVars, fmudata->modelData->nVariablesString);
  }

  {
    long k = setDelayStateWords(fmudata, internal_state->history, internal_state->nHistory);
    if (k < 0 || setSpatialDistributionStateWords(fmudata, internal_state->history + k, internal_state->nHistory - k) < 0) {
      status = fmiXError;
      goto cleanup;
    }
  }

  for (long i = 0; i < md->nParametersReal; i++) {
    if (!keep[OMC_SLOT(md->nVariablesReal + i, OMC_SLOT_REAL)]) fmudata->simulationInfo->realParameter[i] = internal_state->realParameter[i];
  }
  for (long i = 0; i < md->nParametersInteger; i++) {
    if (!keep[OMC_SLOT(md->nVariablesInteger + i, OMC_SLOT_INTEGER)]) fmudata->simulationInfo->integerParameter[i] = internal_state->integerParameter[i];
  }
  for (long i = 0; i < md->nParametersBoolean; i++) {
    if (!keep[OMC_SLOT(md->nVariablesBoolean + i, OMC_SLOT_BOOLEAN)]) fmudata->simulationInfo->booleanParameter[i] = internal_state->booleanParameter[i];
  }
  for (long i = 0; i < md->nParametersString; i++) {
    if (!keep[OMC_SLOT(md->nVariablesString + i, OMC_SLOT_STRING)]) omc_string_store(&fmudata->simulationInfo->stringParameter[i], internal_state->stringParameter[i]);
  }
  for (int r = 0; r < ringBufferLength(internal_state->simulationData); r++) {
    for (long i = 0; i < md->nVariablesReal; i++) {
      if (keep[OMC_SLOT(i, OMC_SLOT_REAL)]) fmudata->localData[r]->realVars[i] = curReal[i];
    }
    for (long i = 0; i < md->nVariablesInteger; i++) {
      if (keep[OMC_SLOT(i, OMC_SLOT_INTEGER)]) fmudata->localData[r]->integerVars[i] = curInt[i];
    }
    for (long i = 0; i < md->nVariablesBoolean; i++) {
      if (keep[OMC_SLOT(i, OMC_SLOT_BOOLEAN)]) fmudata->localData[r]->booleanVars[i] = curBool[i];
    }
  }
  /* Calculate again what the tunable parameters reach, min, max and nominal too. */
  for (size_t k = 0; k < deps->nSlots; k++) {
    comp->slotDirty[k] = (deps->flags[k] & OMC_PARAMDEPS_TUNABLE) != 0;
  }
  comp->_tunable_dirty = 1;
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  if (!(comp->state & (model_state_instantiated | model_state_initialization_mode)) &&
      updateIfNeeded(comp, FMIX_STR "SetFMUstate") != fmiXOK) {
    status = fmiXError;
    goto cleanup;
  }

  // After restoring the FMU state, the internal solver (CVODE/Euler) has
  // outdated step history, Jacobians, and time.  Reinitialize it so that the
  // next doStep starts from a clean solver state.
  if (status == fmiXOK && isCoSimulation(comp) && comp->solverInfo) {
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetFMUstate: reinitialising solver")
    fmuDeInitializeSolverData(comp);
    fmuInitializeSolverData(comp);
    comp->solverInfo->currentTime = comp->fmuData->localData[0]->timeValue;
  }

cleanup:
  free(keep);
  free(mask);
  free(curReal);
  free(curInt);
  free(curBool);

#if OMC_FMI_VERSION == 2
  /* FMI 2.0, 4.2.3: a discarded step is redone by restoring an FMU state. */
  if (status == fmiXOK && comp->state == model_state_cs_step_failed) {
    comp->state = model_state_cs_step_complete;
    comp->terminated = fmiXFalse;
  }
#endif
  return status;
}

fmiXStatus FMIX(FreeFMUstate)(fmiXComponent c, fmiXFMUstate* FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;
  int meStates = FMU_STATE_ME_STATES;
  int csStates = FMU_STATE_CS_STATES;

  if (invalidState(comp, FMIX_STR "FreeFMUstate", meStates, csStates))
    return fmiXError;

  if (*FMUstate)
  {
    INTERNAL_FMU_STATE* internal_state = (INTERNAL_FMU_STATE*) *FMUstate;
    // free the SIMULATION_DATA variable buffers
    for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++)
    {
      SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
      free(sdata->realVars);
      free(sdata->integerVars);
      free(sdata->booleanVars);
      omc_string_slots_release(sdata->stringVars, comp->fmuData->modelData->nVariablesString);
      free(sdata->stringVars);
    }
    freeRingBuffer(internal_state->simulationData);
    free(internal_state->realParameter);
    free(internal_state->integerParameter);
    free(internal_state->booleanParameter);
    omc_string_slots_release(internal_state->stringParameter, comp->fmuData->modelData->nParametersString);
    free(internal_state->stringParameter);
    free(internal_state->history);
    free(*FMUstate);
    *FMUstate = NULL;
  }
  return fmiXOK;
}

fmiXStatus FMIX(SerializedFMUstateSize)(fmiXComponent c, fmiXFMUstate FMUstate, size_t *size)
{
  /* portable serialization is tricky. for now only x86_64 tested!          */
  /* TODO: make serialization format architecture- & endianness-independent */

  ModelInstance *comp = (ModelInstance *) c;
  DATA *fmudata = (DATA *) comp->fmuData;
  INTERNAL_FMU_STATE *internal_state = (INTERNAL_FMU_STATE *) FMUstate;

  size_t stateSize = 0;

  /* space for ringbuffer / simulation data contents */
  stateSize += ringBufferLength(internal_state->simulationData)    /* timeValue */
                   * sizeof(modelica_real);
  stateSize += ringBufferLength(internal_state->simulationData)    /* realVars */
                   * fmudata->modelData->nVariablesReal
                   * sizeof(modelica_real);
  stateSize += ringBufferLength(internal_state->simulationData)    /* integerVars */
                   * fmudata->modelData->nVariablesInteger
                   * sizeof(modelica_integer);
  stateSize += ringBufferLength(internal_state->simulationData)    /* booleanVars */
                   * fmudata->modelData->nVariablesBoolean
                   * sizeof(modelica_boolean);
                                                            /* stringVars */
  for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++) {
    SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
    stateSize += getStringArraySize(sdata->stringVars,
                                    fmudata->modelData->nVariablesString);
  }

  /* space for model parameters */
  stateSize += fmudata->modelData->nParametersReal * sizeof(modelica_real);
  stateSize += fmudata->modelData->nParametersInteger * sizeof(modelica_integer);
  stateSize += fmudata->modelData->nParametersBoolean * sizeof(modelica_boolean);
  stateSize += getStringArraySize(internal_state->stringParameter,
                                  fmudata->modelData->nParametersString);

  stateSize += sizeof(size_t) + internal_state->nHistory * sizeof(double);

  *size = stateSize;
  return fmiXOK;
}

fmiXStatus FMIX(SerializeFMUstate)(fmiXComponent c, fmiXFMUstate FMUstate, fmiXByte serializedState[], size_t size)
{
  /* portable serialization is tricky. for now only x86_64 tested!          */
  /* TODO: make serialization format architecture- & endianness-independent */

  ModelInstance *comp = (ModelInstance *) c;
  DATA *fmudata = (DATA *) comp->fmuData;
  INTERNAL_FMU_STATE *internal_state = (INTERNAL_FMU_STATE *) FMUstate;

  /* assumption sizeof(fmiXByte) == sizeof(char) */
  /* probably true for most modern platforms     */
  fmiXByte *serialVec = serializedState;

  fmiXByte *currElement = serialVec;
  char *currStr;
  int currStrLen;
  for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++) {
    SIMULATION_DATA *sdata =
                        (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
    memcpy(currElement, &(sdata->timeValue), sizeof(modelica_real));
    currElement += sizeof(modelica_real);
    memcpy(currElement, sdata->realVars,
                        sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    currElement += sizeof(modelica_real)*fmudata->modelData->nVariablesReal;
    memcpy(currElement, sdata->integerVars,
                        sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    currElement += sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger;
    memcpy(currElement, sdata->booleanVars,
                        sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    currElement += sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean;

    currElement += copyStringArray((char *)currElement, sdata->stringVars,
                                   fmudata->modelData->nVariablesString);
  }
  memcpy(currElement, internal_state->realParameter,
                      sizeof(modelica_real)*fmudata->modelData->nParametersReal);
  currElement += sizeof(modelica_real)*fmudata->modelData->nParametersReal;
  memcpy(currElement, internal_state->integerParameter,
                      sizeof(modelica_integer)*fmudata->modelData->nParametersInteger);
  currElement += sizeof(modelica_integer)*fmudata->modelData->nParametersInteger;
  memcpy(currElement, internal_state->booleanParameter,
                      sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean);
  currElement += sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean;
  currElement += copyStringArray((char *)currElement, internal_state->stringParameter,
                                 fmudata->modelData->nParametersString);
  memcpy(currElement, &internal_state->nHistory, sizeof(size_t));
  currElement += sizeof(size_t);
  memcpy(currElement, internal_state->history, internal_state->nHistory * sizeof(double));

  return fmiXOK;
}

fmiXStatus FMIX(DeSerializeFMUstate)(fmiXComponent c, const fmiXByte serializedState[], size_t size, fmiXFMUstate* FMUstate)
{
  /* portable serialization is tricky. for now only x86_64 tested!          */
  /* TODO: make serialization format architecture- & endianness-independent */

  ModelInstance *comp = (ModelInstance *) c;
  INTERNAL_FMU_STATE *internal_state =
            (INTERNAL_FMU_STATE *) calloc(1, sizeof(INTERNAL_FMU_STATE));
  internal_state->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  DATA *fmudata = (DATA *) comp->fmuData;

  fmiXByte *currElement = (fmiXByte *) serializedState;

  SIMULATION_DATA tmpSimData = {0};
  for (int i = 0; i < SIZERINGBUFFER; i++) {

    /* timeValue */
    memcpy(&(tmpSimData.timeValue), currElement, sizeof(modelica_real));
    currElement += sizeof(modelica_real);

    /* realVars */
    tmpSimData.realVars = (modelica_real *) calloc(fmudata->modelData->nVariablesReal, sizeof(modelica_real));
    memcpy(tmpSimData.realVars, currElement,
                                sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    currElement += sizeof(modelica_real)*fmudata->modelData->nVariablesReal;

    /* integerVars */
    tmpSimData.integerVars = (modelica_integer *) calloc(fmudata->modelData->nVariablesInteger, sizeof(modelica_integer));
    memcpy(tmpSimData.integerVars, currElement,
                                   sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    currElement += sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger;

    /* booleanVars */
    tmpSimData.booleanVars = (modelica_boolean *) calloc(fmudata->modelData->nVariablesBoolean, sizeof(modelica_boolean));
    memcpy(tmpSimData.booleanVars, currElement,
                                   sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    currElement += sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean;

    /* stringVars */
    tmpSimData.stringVars = (modelica_string *) calloc(fmudata->modelData->nVariablesString, sizeof(modelica_string));
    currElement += readStringArray(tmpSimData.stringVars, (const char *)currElement,
                                   fmudata->modelData->nVariablesString);

    appendRingData(internal_state->simulationData, &tmpSimData);
  }

  /* realParameter */
  internal_state->realParameter = (modelica_real *) calloc(fmudata->modelData->nParametersReal, sizeof(modelica_real));
  memcpy(internal_state->realParameter, currElement,
                                        sizeof(modelica_real)*fmudata->modelData->nParametersReal);
  currElement += sizeof(modelica_real)*fmudata->modelData->nParametersReal;

  /* integerParameter */
  internal_state->integerParameter = (modelica_integer *) calloc(fmudata->modelData->nParametersInteger, sizeof(modelica_integer));
  memcpy(internal_state->integerParameter, currElement,
                                   sizeof(modelica_integer)*fmudata->modelData->nParametersInteger);
  currElement += sizeof(modelica_integer)*fmudata->modelData->nParametersInteger;

  /* booleanParameter */
  internal_state->booleanParameter = (modelica_boolean *) calloc(fmudata->modelData->nParametersBoolean, sizeof(modelica_boolean));
  memcpy(internal_state->booleanParameter, currElement,
                                   sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean);
  currElement += sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean;

  /* stringParameter */
  internal_state->stringParameter = (modelica_string *) calloc(fmudata->modelData->nParametersString, sizeof(modelica_string));
  currElement += readStringArray(internal_state->stringParameter, (const char *)currElement,
                                 fmudata->modelData->nParametersString);

  /* delay() and spatialDistribution() histories */
  memcpy(&internal_state->nHistory, currElement, sizeof(size_t));
  currElement += sizeof(size_t);
  internal_state->history = (double*) calloc(internal_state->nHistory ? internal_state->nHistory : 1, sizeof(double));
  memcpy(internal_state->history, currElement, internal_state->nHistory * sizeof(double));

  *FMUstate = (fmiXFMUstate) internal_state;
  return fmiXOK;
}

fmiXStatus FMIX(GetDirectionalDerivativeForInitialization)(fmiXComponent c,
    const fmiXValueReference vUnknown_ref[], size_t nUnknown,
    const fmiXValueReference vKnown_ref[] , size_t nKnown,
    const fmiXReal dvKnown[], fmiXReal dvUnknown[])
{
  ModelInstance *comp = (ModelInstance *)c;
  DATA* fmudata = (DATA *) comp->fmuData;
  threadData_t* td = comp->threadData;

  /***************************************/
  /* This code assumes that the FMU variables are always sorted,
     states first and then derivatives.
     This is true for the actual OMC FMUs.
     The input values references are mapped with mapInputReference2InputNumber
     and mapOutputReference2OutputNumber functions
  */
  /* eval constant part of jacobian */

  int i,j;

  int independent = comp->fmiDerJacInitialization->sizeCols;
  int dependent = comp->fmiDerJacInitialization->sizeRows;

  /* TODO: Evaluate only once for one evaluation of jacobian */
  if (comp->fmiDerJacInitialization->constantEqns != NULL) {
    comp->fmiDerJacInitialization->constantEqns(fmudata, td, comp->fmiDerJacInitialization, NULL);
  }

  /* clear out the seeds */
  for (i = 0; i < independent; i++)
  {
    comp->fmiDerJacInitialization->seedVars[i] = 0;
  }

  for (i = 0; i < nKnown; i++)
  {
    // map the known ValueReferences to an internal index
    int idx = mapInitialUnknownsIndependentIndex(vKnown_ref[i]);
    if (vrOutOfRange(comp, FMIX_STR "GetDirectionalDerivative input index during initialization", idx, independent))
      return fmiXError;
    /* Put the supplied value in the seeds */
    comp->fmiDerJacInitialization->seedVars[idx] = dvKnown[i];
  }

  /* Call the Jacobian evaluation function. This function evaluates the whole column of the Jacobian.
   * More efficient code could only evaluate the equations needed for the
   * known variables only */
  setThreadData(comp);
  fmudata->callback->functionJacFMIDERINIT_column(fmudata, td, comp->fmiDerJacInitialization, NULL);

  /* Write the results to dvUnknown array */
  for (i=0;i<nUnknown; i++)
  {
    // map the Unknown ValueReferences to an internal index
    int idx = mapInitialUnknownsdependentIndex(vUnknown_ref[i]);
    if (vrOutOfRange(comp, FMIX_STR "GetDirectionalDerivative output index during initialization", idx, dependent))
      return fmiXError;
    dvUnknown[i] = comp->fmiDerJacInitialization->resultVars[idx];
  }

  return fmiXOK;
}

fmiXStatus FMIX(GetDirectionalDerivative)(fmiXComponent c,
    const fmiXValueReference vUnknown_ref[], size_t nUnknown,
    const fmiXValueReference vKnown_ref[] , size_t nKnown,
    const fmiXReal dvKnown[], fmiXReal dvUnknown[])
{
  ModelInstance *comp = (ModelInstance *)c;
  DATA* fmudata = (DATA *) comp->fmuData;
  MODEL_DATA* modelData = (MODEL_DATA*) fmudata->modelData;
  threadData_t* td = comp->threadData;

  int i;

  int independent = modelData->nStates+modelData->nInputVars;
  int dependent = modelData->nStates+modelData->nOutputVars;

  if (invalidState(comp, FMIX_STR "GetDirectionalDerivative", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmiXError;
  if (!comp->_has_jacobian)
    return unsupportedFunction(comp, FMIX_STR "GetDirectionalDerivative");

  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetDirectionalDerivative")

  if (updateIfNeeded(comp, FMIX_STR "GetDirectionalDerivative") != fmiXOK)
    return fmiXError;

  if (model_state_initialization_mode == comp->state)
  {
    // directional derivative in initialization mode
    return FMIX(GetDirectionalDerivativeForInitialization)(c, vUnknown_ref, nUnknown, vKnown_ref, nKnown, dvKnown, dvUnknown);
  }

  /***************************************/
  /* This code assumes that the FMU variables are always sorted,
     states first and then derivatives.
     This is true for the actual OMC FMUs.
     The input values references are mapped with mapInputReference2InputNumber
     and mapOutputReference2OutputNumber functions
  */
  /* eval constant part of jacobian */
  /* TODO: Evaluate only once for one evaluation of jacobian */
  if (comp->fmiDerJac->constantEqns != NULL) {
    comp->fmiDerJac->constantEqns(fmudata, td, comp->fmiDerJac, NULL);
  }

  /* clear out the seeds */
  for (i=0;i<independent; i++) {
    comp->fmiDerJac->seedVars[i]=0;
  }
  for (i=0;i<nKnown; i++) {
    int idx = vKnown_ref[i];
    /* if idx is > nStates it's an input so we need a mapping */
    if (idx >= modelData->nStates){
      idx = mapInputReference2InputNumber(vKnown_ref[i]);
      idx = modelData->nStates + idx;
    }
    if (vrOutOfRange(comp, FMIX_STR "GetDirectionalDerivative input index", idx, independent))
      return fmiXError;
    /* Put the supplied value in the seeds */
    comp->fmiDerJac->seedVars[idx]=dvKnown[i];
  }
  /* Call the Jacobian evaluation function. This function evaluates the whole column of the Jacobian.
   * More efficient code could only evaluate the equations needed for the
   * known variables only */
  setThreadData(comp);
  fmudata->callback->functionJacFMIDER_column(fmudata, td, comp->fmiDerJac, NULL);

  /* Write the results to dvUnknown array */
  for (i=0;i<nUnknown; i++) {
    /* derivatives are behind the states */
    int idx = vUnknown_ref[i] - modelData->nStates;
    /* if idx is > nStates it's an output so we need a mapping */
    if (idx >= modelData->nStates){
      idx = mapOutputReference2OutputNumber(vUnknown_ref[i]);
      idx = modelData->nStates + idx;
    }
    if (vrOutOfRange(comp, FMIX_STR "GetDirectionalDerivative output index", idx, dependent))
      return fmiXError;
    dvUnknown[i] = comp->fmiDerJac->resultVars[idx];
  }
  /***************************************/
  return fmiXOK;
}



/***************************************************
Functions for Model Exchange
****************************************************/
fmiXStatus FMIX(EnterEventMode)(fmiXComponent c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, FMIX_STR "EnterEventMode", model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_EVENTS, FMIX_STR "EnterEventMode")
  comp->state = model_state_me_event_mode;
  comp->fmuData->simulationInfo->needToReThrow = 0;
  comp->_event_found = 0;

  // Reset eventInfo
  comp->eventInfo.newDiscreteStatesNeeded = fmiXFalse;
  comp->eventInfo.terminateSimulation = fmiXFalse;
  comp->eventInfo.nominalsOfContinuousStatesChanged = fmiXFalse;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmiXFalse;
  comp->eventInfo.nextEventTimeDefined = fmiXFalse;
  comp->eventInfo.nextEventTime = 0;

  return fmiXOK;
}

fmiXStatus FMIX(NewDiscreteStates)(fmiXComponent c, fmiXEventInfo* eventInfo)
{
  ModelInstance *comp = (ModelInstance *)c;
  double nextSampleEvent = 0;
  fmiXStatus returnValue = fmiXOK;

  if (invalidState(comp, FMIX_STR "NewDiscreteStates", model_state_me_event_mode, 0))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "NewDiscreteStates")

  returnValue = internalEventUpdate(comp, eventInfo);

  return returnValue;
}

fmiXStatus FMIX(EnterContinuousTimeMode)(fmiXComponent c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, FMIX_STR "EnterContinuousTimeMode", model_state_me_event_mode, 0))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "EnterContinuousTimeMode")
  comp->state = model_state_me_continuous_time_mode;
  return fmiXOK;
}

fmiXStatus internal_CompletedIntegratorStep(fmiXComponent c, const char *func, fmiXBoolean noSetFMUStatePriorToCurrentPoint, fmiXBoolean* enterEventMode, fmiXBoolean* terminateSimulation)
{
  int done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp=threadData->mmc_jumper;

  if (nullPointer(comp, func, "enterEventMode", enterEventMode))
    return fmiXError;
  if (nullPointer(comp, func, "terminateSimulation", terminateSimulation))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, func)

  setThreadData(comp);

  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;
    holdAsserts(comp, 1);
    evalDAEModeContinuous(comp);
    comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
    comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeSpatialDistribution(comp->fmuData, threadData);
    storePreValues(comp->fmuData);
    releaseAsserts(comp);
    *enterEventMode = fmiXFalse;
    *terminateSimulation = fmiXFalse;
    if (comp->fmuData->simulationInfo->needToReThrow)
    {
      /* A held assert() asks for Event Mode. */
      comp->fmuData->simulationInfo->needToReThrow = 0;
      *enterEventMode = fmiXTrue;
      FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "%s: Need to iterate, an assertion was violated at this point!", func)
    }
    /******** check state selection ********/
#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 0))
    {
      /* if new set is calculated reinit the solver */
      *enterEventMode = fmiXTrue;
      FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "%s: Need to iterate state values changed!", func)
    }
#endif
    /* TODO: fix the extrapolation in non-linear system
     *       then we can stop to save all variables in
     *       in the whole ringbuffer
     */
    overwriteOldSimulationData(comp->fmuData);
    comp->_need_update = 1;
    done=1;
  /* catch */
  OMC_CATCH_INTERNAL(simulationJumpBuffer)
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }
  threadData->mmc_jumper = old_jmp;
  releaseAsserts(comp);

  if (done) {
    if (comp->_terminate_simulation_requested) {
      comp->_terminate_simulation_requested = 0;
      *terminateSimulation = fmiXTrue;
      FILTERED_LOG(comp, fmiXOK, LOG_EVENTS, "%s: terminate simulation requested by the model.", func)
    }
    return fmiXOK;
  }

  FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, "%s: terminated by an assertion.", func)
  return fmiXError;
}

fmiXStatus FMIX(CompletedIntegratorStep)(fmiXComponent c, fmiXBoolean noSetFMUStatePriorToCurrentPoint, fmiXBoolean* enterEventMode, fmiXBoolean* terminateSimulation)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, FMIX_STR "CompletedIntegratorStep", model_state_me_continuous_time_mode, 0))
    return fmiXError;

  return internal_CompletedIntegratorStep(c, FMIX_STR "CompletedIntegratorStep", noSetFMUStatePriorToCurrentPoint, enterEventMode, terminateSimulation);
}

fmiXStatus FMIX(SetTime)(fmiXComponent c, fmiXReal t)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, FMIX_STR "SetTime", model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmiXError;
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetTime: time=%.16g", t)
  comp->fmuData->localData[0]->timeValue = t;
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXOK;
}

fmiXStatus internalSetContinuousStates(fmiXComponent c, const fmiXReal x[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  int i;
  if (invalidNumber(comp, FMIX_STR "SetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiXError;
  if (nullPointer(comp, FMIX_STR "SetContinuousStates", "x[]", x))
    return fmiXError;
#if NUMBER_OF_STATES > 0
  for (i = 0; i < nx; i++) {
    fmiXValueReference vr = vrStates[i];
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetContinuousStates: #r%u# = %.16g", vr, x[i])
    if (vr < 0 || vr >= NUMBER_OF_REALS|| setReal(comp, vr, x[i]) != fmiXOK) { // to be implemented by the includer of this file
      return fmiXError;
    }
  }
#endif
  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXOK;
}

fmiXStatus FMIX(SetContinuousStates)(fmiXComponent c, const fmiXReal x[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  /* According to FMI RC2 specification SetContinuousStates should only be allowed in Continuous-Time Mode.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call SetContinuousStates after EnterInitializationMode.
   */
  if (invalidState(comp, FMIX_STR "SetContinuousStates", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmiXError;

  return internalSetContinuousStates(c, x, nx);
}

fmiXStatus internalGetDerivatives(fmiXComponent c, const char *func, fmiXReal derivatives[], size_t nx)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  if (invalidNumber(comp, func, "nx", nx, NUMBER_OF_STATES))
    return fmiXError;
  if (nullPointer(comp, func, "derivatives[]", derivatives))
    return fmiXError;

  setThreadData(comp);
  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

    /* A violated assert() is held, see updateIfNeeded. */
    holdAsserts(comp, (comp->state & (model_state_me_continuous_time_mode | model_state_cs_step_in_progress | model_state_cs_step_complete)) != 0);
    if (comp->_need_update)
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      evalDAEModeContinuous(comp);
      overwriteOldSimulationData(comp->fmuData);
    }
    releaseAsserts(comp);

#if NUMBER_OF_STATES > 0
    for (i = 0; i < nx; i++) {
      fmiXValueReference vr = vrStatesDerivatives[i];
      derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
      FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "%s: #r%u# = %.16g", func, vr, derivatives[i])
    }
#endif

    done=1;
  /* catch */
  OMC_CATCH_INTERNAL(simulationJumpBuffer)
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }

  threadData->mmc_jumper = old_jmp;
  releaseAsserts(comp);

  if (done) {
    return fmiXOK;
  }
  FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, "%s: terminated by an assertion.", func)
  return fmiXError;
}

fmiXStatus FMIX(GetDerivatives)(fmiXComponent c, fmiXReal derivatives[], size_t nx)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, FMIX_STR "GetDerivatives", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmiXError;

  return internalGetDerivatives(c, FMIX_STR "GetDerivatives", derivatives, nx);
}

fmiXStatus internalGetEventIndicators(fmiXComponent c, const char *func, fmiXReal eventIndicators[], size_t nx)
{
  int i, done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  if (invalidNumber(comp, func, "nx", nx, NUMBER_OF_EVENT_INDICATORS))
    return fmiXError;

  setThreadData(comp);
  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

#if NUMBER_OF_EVENT_INDICATORS > 0
    /* eval needed equations*/
    /* A violated assert() is held, see updateIfNeeded. */
    holdAsserts(comp, (comp->state & (model_state_me_continuous_time_mode | model_state_cs_step_in_progress | model_state_cs_step_complete)) != 0);
    if (comp->_need_update)
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      evalDAEModeContinuous(comp);
      comp->_need_update = 0;
    }
    releaseAsserts(comp);
    comp->fmuData->callback->function_ZeroCrossings(comp->fmuData, comp->threadData, comp->fmuData->simulationInfo->zeroCrossings);
    for (i = 0; i < nx; i++) {
      eventIndicators[i] = comp->fmuData->simulationInfo->zeroCrossings[i];
      FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "%s: z%d = %.16g", func, i, eventIndicators[i])
    }
#endif
    done=1;

  /* catch */
  OMC_CATCH_INTERNAL(simulationJumpBuffer)
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }
  threadData->mmc_jumper = old_jmp;
  releaseAsserts(comp);

  if (done) {
    return fmiXOK;
  }
  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, "%s: terminated by an assertion.", func)
  return fmiXError;
}

fmiXStatus FMIX(GetEventIndicators)(fmiXComponent c, fmiXReal eventIndicators[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  /* According to FMI RC2 specification GetEventIndicators should only be allowed in Event Mode, Continuous-Time Mode & terminated.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call GetEventIndicators after EnterInitializationMode.
   */
  if (invalidState(comp, FMIX_STR "GetEventIndicators", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
  /*if (invalidState(comp, FMIX_STR "GetEventIndicators", model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error))*/
    return fmiXError;

  return internalGetEventIndicators(c, FMIX_STR "GetEventIndicators", eventIndicators, nx);
}

fmiXStatus internalGetContinuousStates(fmiXComponent c, fmiXReal x[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidNumber(comp, FMIX_STR "GetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiXError;
  if (nullPointer(comp, FMIX_STR "GetContinuousStates", "states[]", x))
    return fmiXError;
#if NUMBER_OF_STATES > 0
  for (i = 0; i < nx; i++)
  {
    fmiXValueReference vr = vrStates[i];
    x[i] = getReal(comp, vr); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetContinuousStates: #r%u# = %.16g", vr, x[i])
  }
#endif
  return fmiXOK;
}

fmiXStatus FMIX(GetContinuousStates)(fmiXComponent c, fmiXReal x[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, FMIX_STR "GetContinuousStates", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmiXError;

  return internalGetContinuousStates(c, x, nx);
}

fmiXStatus internalGetNominalsOfContinuousStates(fmiXComponent c, fmiXReal x_nominal[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidNumber(comp, FMIX_STR "GetNominalsOfContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiXError;
  if (nullPointer(comp, FMIX_STR "GetNominalsOfContinuousStates", "x_nominal[]", x_nominal))
    return fmiXError;
#if NUMBER_OF_STATES > 0
  DATA* fmudata = (DATA *) comp->fmuData;
  for (i = 0; i < nx; i++)
  {
    /* Floored as ida_solver_setNominals floors it. */
    modelica_real nominal = getNominalFromScalarIdx(fmudata->simulationInfo, fmudata->modelData, VAR_KIND_STATE, i);
    x_nominal[i] = fmax(fabs(nominal), 1e-32);
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetNominalsOfContinuousStates: x_nominal[%d] = %.16g", i, x_nominal[i])
  }
#endif
  return fmiXOK;
}

fmiXStatus FMIX(GetNominalsOfContinuousStates)(fmiXComponent c, fmiXReal x_nominal[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, FMIX_STR "GetNominalsOfContinuousStates", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmiXError;

  return internalGetNominalsOfContinuousStates(c, x_nominal, nx);
}

/***************************************************
Functions for Co-Simulation
****************************************************/
fmiXStatus FMIX(SetRealInputDerivatives)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, const fmiXInteger order[], const fmiXReal value[])
{
  /* Variables */
  int i;
  int mappedIndex;
  ModelInstance *comp = (ModelInstance*)c;

  /* Check for valid call sequence */
  if (invalidState(comp, FMIX_STR "SetRealInputDerivatives", 0, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "SetRealInputDerivatives", "vr[]", vr))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "SetRealInputDerivatives", "value[]", value))
    return fmiXError;

  FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetRealInputDerivatives: nvr = %zu", nvr)

#if NUMBER_OF_REAL_INPUTS > 0
  for (i = 0; i < nvr; i++)
  {
    if (order[i] > 1) // currently first order derivative is supported
      return fmiXError;
    if (vrOutOfRange(comp, FMIX_STR "SetRealInputDerivatives", vr[i], NUMBER_OF_REALS))
      return fmiXError;
    // check valueReference is an input of type Real
    mappedIndex = mapInputReference2InputNumber(vr[i]);
    if (mappedIndex == -1)
      return fmiXError;
    comp->input_real_derivative[mappedIndex] = value[i]; // store the values in an external array
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "SetRealInputDerivatives: #r%u# = %.16g", vr[i], value[i])
  }
#endif

  comp->_need_update = 1;
  DAE_MODE_CHANGED(comp);
  return fmiXOK;
}

fmiXStatus FMIX(GetRealOutputDerivatives)(fmiXComponent c, const fmiXValueReference vr[], size_t nvr, const fmiXInteger order[], fmiXReal value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance*)c;

  /* Check for valid call sequence */
  if (invalidState(comp, FMIX_STR "GetRealOutputDerivatives", 0, model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetRealOutputDerivatives", "vr[]", vr))
    return fmiXError;
  if (nvr > 0 && nullPointer(comp, FMIX_STR "GetRealOutputDerivatives", "value[]", value))
    return fmiXError;

#if NUMBER_OF_REALS > 0
  if (updateIfNeeded(comp, FMIX_STR "GetRealOutputDerivatives") != fmiXOK)
    return fmiXError;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, FMIX_STR "GetRealOutputDerivatives", vr[i], NUMBER_OF_REALS)) {
      return fmiXError;
    }
    fmiXValueReference mappedVR = mapOutputReference2RealOutputDerivatives(vr[i]);
    value[i] = getReal(comp, mappedVR); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiXOK, LOG_FMIX_CALL, FMIX_STR "GetRealOutputDerivatives: #r%u# = %.16g", vr[i], value[i])
  }
#endif
  return fmiXOK;
}

/**
 * @brief Internal Co-Simulation step, called from fmi2DoStep and fmi3DoStep.
 *
 * Compute time step to next communication point with explicit Euler or CVODE.
 *
 * When @p eventModeUsed and @p earlyReturnAllowed are both true (FMI 3.0
 * Co-Simulation with Event Mode), the step stops at the first encountered event
 * (state event, time event or state-selection event) and reports it through
 * @p eventEncountered / @p earlyReturn / @p lastSuccessfulTime instead of
 * resolving it internally. The master is then expected to call
 * fmi3EnterEventMode / fmi3UpdateDiscreteStates / fmi3EnterStepMode and resume
 * with a new step from @p lastSuccessfulTime. Otherwise events are handled
 * internally (FMI 2.0 behaviour) and the step always advances to the
 * communication point.
 *
 * @param c                                  FMU component instance.
 * @param currentCommunicationPoint          Current communication point of the master algorithm.
 * @param communicationStepSize              Communication step size.
 * @param noSetFMUStatePriorToCurrentPoint   Unused.
 * @param eventModeUsed                      True if the importer uses FMI 3.0 Co-Simulation Event Mode for this instance.
 * @param earlyReturnAllowed                 True if the master allows the step to return early on a deferred event; only relevant when @p eventModeUsed is true.
 * @param eventEncountered                   Output, may be NULL. Set to fmiXTrue if an event was encountered and deferred to the master.
 * @param terminateSimulationOut             Output, may be NULL. Set to fmiXTrue if the simulation should terminate.
 * @param earlyReturn                        Output, may be NULL. Set to fmiXTrue if the step returned before reaching the requested communication point due to a deferred event.
 * @param lastSuccessfulTime                 Output, may be NULL. Simulation time actually reached by this step.
 * @return fmiXStatus                        Returns fmiXOK if the step (or partial step up to a deferred event) completed successfully, fmiXError/fmiXFatal otherwise.
 */
static fmiXStatus doStepInternal(ModelInstance* c, fmiXReal currentCommunicationPoint,
    fmiXReal communicationStepSize, fmiXBoolean noSetFMUStatePriorToCurrentPoint,
    fmiXBoolean eventModeUsed, fmiXBoolean earlyReturnAllowed,
    fmiXBoolean* eventEncountered, fmiXBoolean* terminateSimulationOut,
    fmiXBoolean* earlyReturn, fmiXReal* lastSuccessfulTime)
{
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  int i, zc_event = 0, time_event = 0;
  int flag;
  int done = 0;
  fmiXBoolean ev = fmiXFalse;   /* event encountered and deferred to the master */
  fmiXBoolean term = fmiXFalse; /* simulation terminated by an internal event */

  fmiXStatus status = fmiXOK;
  fmiXReal* states = comp->states;
  fmiXReal* states_der = comp->states_der;
  fmiXReal* event_indicators = comp->event_indicators;
  fmiXReal* event_indicators_prev = comp->event_indicators_prev;
  fmiXReal t = comp->fmuData->localData[0]->timeValue;
  fmiXReal tNext, tEnd;
  fmiXBoolean enterEventMode = fmiXFalse, terminateSimulation = fmiXFalse;

  fmiXEventInfo eventInfo;

  if (eventEncountered)       *eventEncountered = fmiXFalse;
  if (terminateSimulationOut) *terminateSimulationOut = fmiXFalse;
  if (earlyReturn)            *earlyReturn = fmiXFalse;
  if (lastSuccessfulTime)     *lastSuccessfulTime = currentCommunicationPoint + communicationStepSize;

  if (invalidState(comp, FMIX_STR "DoStep", 0, model_state_cs_step_complete))
    return fmiXError;


  setThreadData(comp);

  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

  eventInfo.newDiscreteStatesNeeded           = fmiXFalse;
  eventInfo.terminateSimulation               = fmiXFalse;
  eventInfo.nominalsOfContinuousStatesChanged = fmiXFalse;
  eventInfo.valuesOfContinuousStatesChanged   = fmiXTrue;
  eventInfo.nextEventTimeDefined              = fmiXFalse;
  eventInfo.nextEventTime                     = 0.0;

  comp->fmuData->localData[0]->timeValue = currentCommunicationPoint;
  tEnd = currentCommunicationPoint + communicationStepSize;
  if (comp->stopTimeDefined && (tEnd > comp->stopTime))
    status=fmiXError;

  // copy the input values
#if NUMBER_OF_REAL_INPUTS > 0
  fmiXReal realInputDerivatives[NUMBER_OF_REAL_INPUTS];
  for (int i = 0; i < NUMBER_OF_REALS; ++i)
  {
    int mappedIndex = mapInputReference2InputNumber(i);
    if (mappedIndex != -1)
      realInputDerivatives[mappedIndex] = getReal(comp, i);
  }
#endif

  status = internalEventIteration(c, &eventInfo);
  if (eventInfo.terminateSimulation) {
    term = fmiXTrue;
    done = 1;
    goto doStep_cleanup;
  }
  if (status != fmiXOK) goto doStep_cleanup;
  if (comp->_tunable_applied) {
    comp->_tunable_applied = 0;
    comp->solverInfo->didEventStep = 1;
  }

  /* Integration loop */
  while (status == fmiXOK && comp->fmuData->localData[0]->timeValue < tEnd)
  {
    /* fprintf(stderr, "DoStep %g -> %g State: %s\n", comp->fmuData->localData[0]->timeValue, tNext, stateToString(comp)); */

    /* Both describe this sub-step only. Left set, a time event or zero
       crossing in an earlier sub-step would make every later one end in a
       spurious event iteration (and, in Event Mode, report an event that
       is not there). */
    zc_event = 0;
    time_event = 0;

    // set the real Inputs with output_derivative values
#if NUMBER_OF_REAL_INPUTS > 0
    for (int i = 0; i < NUMBER_OF_REALS; ++i)
    {
      int mappedIndex = mapInputReference2InputNumber(i);
      if (mapInputReference2InputNumber(i) != -1)
      {
        double dt = comp->fmuData->localData[0]->timeValue - t;
        double new_input_value = realInputDerivatives[mappedIndex] + comp->input_real_derivative[mappedIndex] * dt;
        if (setReal(comp, i, new_input_value) != fmiXOK) // to be implemented by the includer of this file
        {
          status = fmiXError;
          goto doStep_cleanup;
        }
      }
    }
#endif

#if NUMBER_OF_STATES > 0
    status = internalGetDerivatives(c, FMIX_STR "DoStep", states_der, NUMBER_OF_STATES);
  if (status != fmiXOK) goto doStep_cleanup;

    status = internalGetContinuousStates(c, states, NUMBER_OF_STATES);
  if (status != fmiXOK) goto doStep_cleanup;
#endif

#if NUMBER_OF_EVENT_INDICATORS > 0
    status = internalGetEventIndicators(c, FMIX_STR "DoStep", event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
  if (status != fmiXOK) goto doStep_cleanup;
#endif

    /* adjust for time events */
    if (eventInfo.nextEventTimeDefined && (eventInfo.nextEventTime <= tEnd))
    {
      tNext = eventInfo.nextEventTime;
      time_event = 1;
    }
    else
    {
      tNext = tEnd;
    }

    /* integrate */
#if NUMBER_OF_STATES > 0
    fmiXReal states_t0[NUMBER_OF_STATES];
    memcpy(states_t0, states, NUMBER_OF_STATES * sizeof(fmiXReal));
    fmiXReal t0 = comp->fmuData->localData[0]->timeValue;
#endif
    switch(comp->solverInfo->solverMethod)
    {
      case S_EULER:
        for (i = 0; i < NUMBER_OF_STATES; i++)
        {
          states[i] = states[i] + (tNext - comp->fmuData->localData[0]->timeValue) * states_der[i];
        }
        break;
      case S_CVODE:
#ifdef OMC_FMI_HAVE_CVODE
        comp->solverInfo->currentTime = comp->fmuData->localData[0]->timeValue;
        comp->solverInfo->currentStepSize = tNext - comp->solverInfo->currentTime;
        flag = cvode_solver_step(comp->fmuData, comp->threadData, comp->solverInfo);
        memcpy(states, comp->fmuData->localData[0]->realVars, NUMBER_OF_STATES * sizeof(fmiXReal));
        if (flag != 0)
        {
          FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "DoStep: CVODE integrator step failed with flag %d at time %.15g.", flag, comp->solverInfo->currentTime)
          status = fmiXFatal;
          goto doStep_cleanup;
        }
        /* CVODE stopped at a root of the event indicators */
        if (comp->solverInfo->currentTime < tNext)
        {
          tNext = comp->solverInfo->currentTime;
          time_event = 0;
        }
#else
        FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "DoStep: FMU not compiled with SUNDIALS but solver CVODE selected.")
        status = fmiXFatal;
        goto doStep_cleanup;
#endif /* OMC_FMI_HAVE_CVODE */
        break;
      case S_IDA:
#ifdef OMC_FMI_HAVE_IDA
        comp->solverInfo->currentTime = comp->fmuData->localData[0]->timeValue;
        comp->solverInfo->currentStepSize = tNext - comp->solverInfo->currentTime;
        flag = ida_solver_step(comp->fmuData, comp->threadData, comp->solverInfo);
        memcpy(states, comp->fmuData->localData[0]->realVars, NUMBER_OF_STATES * sizeof(fmiXReal));
        if (flag != 0)
        {
          FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "DoStep: IDA integrator step failed with flag %d at time %.15g.", flag, comp->solverInfo->currentTime)
          status = fmiXFatal;
          goto doStep_cleanup;
        }
        /* IDA stopped at a root of the event indicators */
        if (comp->solverInfo->currentTime < tNext)
        {
          tNext = comp->solverInfo->currentTime;
          time_event = 0;
        }
#else
        FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "DoStep: FMU not compiled with SUNDIALS IDA but solver IDA selected.")
        status = fmiXFatal;
        goto doStep_cleanup;
#endif /* OMC_FMI_HAVE_IDA */
        break;
      default:
        FILTERED_LOG(comp, fmiXFatal, LOG_STATUSFATAL, FMIX_STR "DoStep: Unknown solver method %d.", comp->solverInfo->solverMethod)
        status = fmiXFatal;
        goto doStep_cleanup;
    }

#if NUMBER_OF_STATES > 0 && NUMBER_OF_EVENT_INDICATORS > 0
    /* A solver without root finding: findRoot locates a crossing inside the
       sub-step, as in the simulation. */
    if (!comp->solverInfo->solverRootFinding)
    {
      DATA *data = comp->fmuData;
      data->localData[0]->timeValue = tNext;
      status = internalSetContinuousStates(c, states, NUMBER_OF_STATES);
      if (status != fmiXOK) goto doStep_cleanup;
      status = internalGetEventIndicators(c, FMIX_STR "DoStep", event_indicators, NUMBER_OF_EVENT_INDICATORS);
      if (status != fmiXOK) goto doStep_cleanup;
      memcpy(data->simulationInfo->zeroCrossingsPre, event_indicators_prev, NUMBER_OF_EVENT_INDICATORS * sizeof(fmiXReal));
      if (checkForStateEvent(data, comp->solverInfo->eventLst))
      {
        tNext = findRoot(data, comp->threadData, comp->solverInfo->eventLst, t0, states_t0, tNext, states);
        memcpy(states, data->localData[0]->realVars, NUMBER_OF_STATES * sizeof(fmiXReal));
        listClear(comp->solverInfo->eventLst);
        time_event = 0;
      }
    }
#endif

    // update time
    comp->fmuData->localData[0]->timeValue = tNext;
    comp->_need_update = 1;
    DAE_MODE_CHANGED(comp);

    // set the real Inputs with output_derivative values
#if (NUMBER_OF_REAL_INPUTS > 0)
    for (int i = 0; i < NUMBER_OF_REALS; ++i)
    {
      int mappedIndex = mapInputReference2InputNumber(i);
      if (mapInputReference2InputNumber(i) != -1)
      {
        double dt = comp->fmuData->localData[0]->timeValue - t;
        double new_input_value = realInputDerivatives[mappedIndex] + comp->input_real_derivative[mappedIndex] * dt;
        if (setReal(comp, i, new_input_value) != fmiXOK) // to be implemented by the includer of this file
        {
          status = fmiXError;
          goto doStep_cleanup;
        }
      }
    }
#endif

    /* set the continuous states */
#if NUMBER_OF_STATES > 0
    status = internalSetContinuousStates(c, states, NUMBER_OF_STATES);
    if (status != fmiXOK) goto doStep_cleanup;
#endif

    /* signal completed integrator step */
    status = internal_CompletedIntegratorStep(c, FMIX_STR "DoStep", fmiXTrue, &enterEventMode, &terminateSimulation);
    if (terminateSimulation) {
      term = fmiXTrue;
      done = 1;
      goto doStep_cleanup;
    }
    if (status != fmiXOK) goto doStep_cleanup;

    /* check for events */
#if NUMBER_OF_EVENT_INDICATORS > 0
    status = internalGetEventIndicators(c, FMIX_STR "DoStep", event_indicators, NUMBER_OF_EVENT_INDICATORS);
  if (status != fmiXOK) goto doStep_cleanup;

    for (i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++)
    {
      if (event_indicators[i]*event_indicators_prev[i] < 0)
      {
        zc_event = 1;
        break;
      }
    }
#endif

    comp->solverInfo->didEventStep = 0;

    if (enterEventMode || zc_event || time_event)
    {
      /* fprintf(stderr, "enterEventMode = %d, zc_event = %d, time_event = %d\n", enterEventMode, zc_event, time_event); */

      if (eventModeUsed &&
          (earlyReturnAllowed || comp->fmuData->localData[0]->timeValue >= tEnd))
      {
        /* FMI 3.0 Co-Simulation with Event Mode: do not resolve the event here.
           Stop the step at the event and let the master handle it via
           fmi3EnterEventMode / fmi3UpdateDiscreteStates / fmi3EnterStepMode. The
           continuous states have already been advanced to and stored at this
           point, so the deferred event update operates on a consistent state.
           An event landing exactly at the communication point is reported
           without an early return; an event strictly inside the step is only
           deferred when the master allows early return, otherwise it is handled
           internally below. */
        ev = fmiXTrue;
        FILTERED_LOG(comp, fmiXOK, LOG_EVENTS, FMIX_STR "DoStep: event encountered at %g, deferring to the master", comp->fmuData->localData[0]->timeValue)
        break;
      }

      // Reset eventInfo
      eventInfo.newDiscreteStatesNeeded           = fmiXFalse;
      eventInfo.terminateSimulation               = fmiXFalse;
      eventInfo.nominalsOfContinuousStatesChanged = fmiXFalse;
      eventInfo.valuesOfContinuousStatesChanged   = fmiXTrue;
      eventInfo.nextEventTimeDefined              = fmiXFalse;
      eventInfo.nextEventTime                     = 0.0;
      status = internalEventIteration(c, &eventInfo);
      if (eventInfo.terminateSimulation) {
        term = fmiXTrue;
        done = 1;
        goto doStep_cleanup;
      }
      if (status != fmiXOK) goto doStep_cleanup;

      if (eventInfo.valuesOfContinuousStatesChanged)
      {
        #if NUMBER_OF_STATES > 0
          status = internalGetContinuousStates(c, states, NUMBER_OF_STATES);
          if (status != fmiXOK) goto doStep_cleanup;
        #endif
      }

      if (eventInfo.nominalsOfContinuousStatesChanged)
      {
        #if NUMBER_OF_STATES > 0
          status = internalGetNominalsOfContinuousStates(c, states, NUMBER_OF_STATES);
          if (status != fmiXOK) goto doStep_cleanup;
        #endif
      }

      #if NUMBER_OF_EVENT_INDICATORS > 0
        status = internalGetEventIndicators(c, FMIX_STR "DoStep", event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
        if (status != fmiXOK) goto doStep_cleanup;
      #endif

      comp->solverInfo->didEventStep = 1;

      if (eventInfo.terminateSimulation)
      {
        term = fmiXTrue;
        break;
      }
    }
  }

  done = 1;

  /* catch */
  OMC_CATCH_INTERNAL(simulationJumpBuffer)

doStep_cleanup:
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }
  threadData->mmc_jumper = old_jmp;

  if (!done && status == fmiXOK)
  {
    FILTERED_LOG(comp, fmiXError, LOG_FMIX_CALL, FMIX_STR "DoStep: terminated by an assertion.")
    status = fmiXError;
  }

  if (status <= fmiXWarning)
  {
    fmiXReal reached = comp->fmuData->localData[0]->timeValue;
    if (lastSuccessfulTime)     *lastSuccessfulTime = reached;
    if (eventEncountered)       *eventEncountered = ev;
    if (terminateSimulationOut) *terminateSimulationOut = term;
    /* An early return happened when the step stopped (for an event) before the
       requested communication point. */
    if (earlyReturn)            *earlyReturn = (ev && reached < tEnd) ? fmiXTrue : fmiXFalse;
  }

  return status;
}
