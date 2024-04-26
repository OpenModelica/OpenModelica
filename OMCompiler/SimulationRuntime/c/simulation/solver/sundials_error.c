/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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

/** \file sundials_error.c
 */

#include "sundials_error.h"

#ifdef WITH_SUNDIALS

#define UNUSED(x) (void)(x)   /* Surpress compiler warnings for unused function input */

/* Internal function prototypes */
#ifdef OMC_HAVE_CVODE
static void checkReturnFlag_CV(int flag, const char *functionName);
static void checkReturnFlag_CVLS(int flag, const char *functionName);
#endif
#ifdef OMC_HAVE_IDA
static void checkReturnFlag_IDA(int flag, const char *functionName);
static void checkReturnFlag_IDALS(int flag, const char *functionName);
#endif
#ifndef OMC_FMI_RUNTIME
static void checkReturnFlag_KIN(int flag, const char *functionName);
static void checkReturnFlag_KINLS(int flag, const char *functionName);
static void checkReturnFlag_SUNLS(int flag, const char *functionName);
static void checkReturnFlag_SUNMatrix(int flag, const char *functionName);
#endif

/**
 * @brief Checks given flag and reports potential error.
 *
 * Checks sundialsFlagType type to decide what kind given flag is.
 * Possible kinds are: SUNDIALS_KIN_FLAG, SUNDIALS_KINLS_FLAG,
 * SUNDIALS_SUNLS_FLAG or SUNDIALS_UNKNOWN_FLAG.
 *
 * @param flag          Return value of Sundials routine.
 * @param type          Type of Sundials flag returned by routine specifyied by
 *                      functionName.
 * @param functionName  Name of Sundials function that returned the flag.
 */
void checkReturnFlag_SUNDIALS(int flag, sundialsFlagType type,
                              const char *functionName) {
  switch (type) {
  case SUNDIALS_UNKNOWN_FLAG:
    if (flag < 0) {
      //assertStreamPrint(NULL, NULL, "##SUNDIALS##: Some error with value %u occured in function %s.", flag, functionName);
      throwStreamPrint(NULL, "##SUNDIALS##: Some error with value %u occured in function %s.", flag, functionName);
    }
#ifdef OMC_HAVE_CVODE
  case SUNDIALS_CV_FLAG:
    checkReturnFlag_CV(flag, functionName);
    break;
  case SUNDIALS_CVLS_FLAG:
    checkReturnFlag_CVLS(flag, functionName);
    break;
#endif /* OMC_HAVE_CVODE */
#ifdef OMC_HAVE_IDA
  case SUNDIALS_IDA_FLAG:
    checkReturnFlag_IDA(flag, functionName);
    break;
  case SUNDIALS_IDALS_FLAG:
    checkReturnFlag_IDALS(flag, functionName);
    break;
#endif /* OMC_HAVE_IDA */
#ifndef OMC_FMI_RUNTIME
  case SUNDIALS_KIN_FLAG:
    checkReturnFlag_KIN(flag, functionName);
    break;
  case SUNDIALS_KINLS_FLAG:
    checkReturnFlag_KINLS(flag, functionName);
    break;
  case SUNDIALS_SUNLS_FLAG:
    checkReturnFlag_SUNLS(flag, functionName);
    break;
  case SUNDIALS_MATRIX_FLAG:
    checkReturnFlag_SUNMatrix(flag, functionName);
    break;
#endif
  default:
    throwStreamPrint(NULL, "In function checkReturnFlag_SUNDIALS: Invalid sundialsFlagType %u.", type);
  }
}

#ifdef OMC_HAVE_CVODE
/**
 * @brief Checks given CVODE flag and reports potential error.
 *
 * @param flag          Return value of CVODE routine.
 * @param functionName  Name of CVODE function that returned the flag.
 */
static void checkReturnFlag_CV(int flag, const char *functionName) {

  const char* flagName = CVodeGetLinReturnFlagName(flag);

  switch (flag) {
    case CV_SUCCESS:
    case CV_TSTOP_RETURN:
    case CV_ROOT_RETURN:
      break;
    case CV_WARNING:
      warningStreamPrint(LOG_STDOUT, 0, "##CVODE## %s In function %s: Got some warning.", flagName, functionName);
      break;
    case CV_TOO_MUCH_WORK:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The solver took maximum number of internal steps but could not reach tout.", flagName, functionName);
      break;
    case CV_TOO_MUCH_ACC:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The solver could not satisfy the accuracy demanded by the user for some internal step.", flagName, functionName);
      break;
    case CV_ERR_FAILURE:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: Error test failures occurred too many times during one internal time step or minimum step size was reached.", flagName, functionName);
      break;
    case CV_CONV_FAILURE:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: Convergence test failures occurred too many times during one internal time step or minimum step size was reached.", flagName, functionName);
      break;
    case CV_LINIT_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The linear solver’s initialization function failed.", flagName, functionName);
      break;
    case CV_LSETUP_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The linear solver’s setup function failed in an unrecoverable manner.", flagName, functionName);
      break;
    case CV_LSOLVE_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The linear solver’s solve function failed in an unrecoverable manner.", flagName, functionName);
      break;
    case CV_RHSFUNC_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The right-hand side function failed in an unrecoverable manner.", flagName, functionName);
      break;
    case CV_FIRST_RHSFUNC_ERR:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The right-hand side function failed at the first call.", flagName, functionName);
      break;
    case CV_REPTD_RHSFUNC_ERR:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The right-hand side function had repetead recoverable errors.", flagName, functionName);
      break;
    case CV_UNREC_RHSFUNC_ERR:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The right-hand side function had a recoverable error, but no recovery is possible.", flagName, functionName);
      break;
    case CV_RTFUNC_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The rootfinding function failed in an unrecoverable manner.", flagName, functionName);
      break;
    case CV_NLS_INIT_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The nonlinear solver’s init routine failed.", flagName, functionName);
      break;
    case CV_NLS_SETUP_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The nonlinear solver’s setup routine failed.", flagName, functionName);
      break;
    case CV_CONSTR_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The inequality constraints were violated and the solver was unable to recover.", flagName, functionName);
      break;
    case CV_NLS_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The nonlinear solver failed in an unrecoverable manner.", flagName, functionName);
      break;
    case CV_MEM_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: A memory allocation failed.", flagName, functionName);
      break;
    case CV_MEM_NULL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The cvode mem argument was NULL.", flagName, functionName);
      break;
    case CV_ILL_INPUT:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: One of the function inputs is illegal.", flagName, functionName);
      break;
    case CV_NO_MALLOC:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The cvode memory block was not allocated by a call to CVodeMalloc.", flagName, functionName);
      break;
    case CV_BAD_K:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The derivative order k is larger than the order used.", flagName, functionName);
      break;
    case CV_BAD_T:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The time t is outside the last step taken.", flagName, functionName);
      break;
    case CV_BAD_DKY:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The output derivative vector is NULL.", flagName, functionName);
      break;
    case CV_TOO_CLOSE:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The output and initial times are too close to each other.", flagName, functionName);
      break;
    case CV_VECTOROP_ERR:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: A vector operation failed.", flagName, functionName);
      break;
    case CV_PROJ_MEM_NULL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s:  The projection memory was NULL.", flagName, functionName);
      break;
    case CV_PROJFUNC_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The projection function failed in an unrecoverable manner.", flagName, functionName);
      break;
    case CV_REPTD_PROJFUNC_ERR:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The projection function had repeated recoverable errors.", flagName, functionName);
      break;
    case CV_UNRECOGNIZED_ERR:
    default:
      throwStreamPrint(NULL,"##CVODE## In function %s: Error with flag %i.", functionName, flag);
  }
}

/**
 * @brief Checks given CVODE linear solver flag and reports potential error.
 *
 * @param flag          Return value of Cvode linear solver routine.
 * @param functionName  Name of CVODE function that returned the flag.
 */
static void checkReturnFlag_CVLS(int flag, const char *functionName) {

  const char* flagName = CVodeGetLinReturnFlagName(flag);

  switch (flag) {
    case CVLS_SUCCESS:
      break;
    case CVLS_MEM_NULL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The cvode mem argument was NULL.", flagName, functionName);
      break;
    case CVLS_LMEM_NULL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The cvls linear solver has not been initialized.", flagName, functionName);
      break;
    case CVLS_ILL_INPUT:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The cvls solver is not compatible with the current nvector module.", flagName, functionName);
      break;
    case CVLS_MEM_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: A memory allocation request failed.", flagName, functionName);
      break;
    case CVLS_PMEM_NULL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The preconditioner module has not been initialized.", flagName, functionName);
      break;
    case CVLS_JACFUNC_UNRECVR:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The Jacobian function failed in an unrecoverable manner.", flagName, functionName);
      break;
    case CVLS_JACFUNC_RECVR:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: The Jacobian function had a recoverable error.", flagName, functionName);
      break;
    case CVLS_SUNMAT_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: An error occurred with the current sunmatrix module", flagName, functionName);
      break;
    case CVLS_SUNLS_FAIL:
      throwStreamPrint(NULL, "##CVODE## %s In function %s: An error occurred with the current sunlinsol module", flagName, functionName);
      break;
    default:
      throwStreamPrint(NULL,"##CVODE## In function %s: Error with flag %i.", functionName, flag);
  }
}

/**
 * @brief Error handler function for CVODE
 *
 * @param errorCode   Error code from CVODE
 * @param module      Name of the CVODE module reporting the error.
 * @param function    Name of the function in which the error occurred.
 * @param msg         Error Message.
 * @param userData    Pointer to user data given with CVodeSetUserData.
 */
void cvodeErrorHandlerFunction(int errorCode, const char *module,
                               const char *function, char *msg, void *userData)
{
  /* Variables */
  CVODE_SOLVER* cvodeData;
  DATA* data;

  if (userData != NULL && ACTIVE_STREAM(LOG_SOLVER)) {
    cvodeData = (CVODE_SOLVER*) userData;
    data = (DATA*)cvodeData->simData->data;

    infoStreamPrint(LOG_SOLVER, 1, "#### CVODE error message #####");
    infoStreamPrint(LOG_SOLVER, 0, " -> error code %d\n -> module %s\n -> function %s", errorCode, module, function);
    infoStreamPrint(LOG_SOLVER, 0, " Message: %s", msg);
    messageClose(LOG_SOLVER);
  }
}
#endif /* OMC_HAVE_CVODE */

#ifdef OMC_HAVE_IDA
/**
 * @brief Checks given IDA/IDAS flag and reports potential error.
 *
 * Throws on errors.
 *
 * TODO: Make it optionla to throw error and only report error instead.
 *
 * @param flag          Return value of IDA routine.
 * @param functionName  Name of IDA function that returned the flag.
 */
static void checkReturnFlag_IDA(int flag, const char *functionName) {
  switch (flag) {
  case IDA_SUCCESS:       /* Successful function return. */
  case IDA_TSTOP_RETURN:  /* IDASolve succeeded by reaching the specified stopping point. */
  case IDA_ROOT_RETURN:   /* IDASolve succeeded and found one or more roots. */
    break;
  case IDA_WARNING:
    warningStreamPrint(LOG_STDOUT, 0,
                       "##IDA## In function %s: Got some warning.",
                       functionName);
    break;
  case IDA_TOO_MUCH_WORK:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The solver took mxstep internal "
                     "steps but could not reach tout.",
                     functionName);
    break;
  case IDA_TOO_MUCH_ACC:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The solver could not satisfy the "
                     "accuracy demanded by the user for some internal step.",
                     functionName);
    break;
  case IDA_ERR_FAIL:
    throwStreamPrint(
        NULL,
        "##IDA## In function %s: Error test failures occurred too many times "
        "during one internal time step or minimum step size was reached.",
        functionName);
    break;
  case IDA_CONV_FAIL:
    throwStreamPrint(
        NULL,
        "##IDA## In function %s: Convergence test failures occurred too many "
        "times during one internal time step or minimum step size was reached.",
        functionName);
    break;
  case IDA_LINIT_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The linear solver's "
                     "initialization function failed.",
                     functionName);
    break;
  case IDA_LSETUP_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The linear solver's setup "
                     "function failed in an unrecoverable manner.",
                     functionName);
    break;
  case IDA_LSOLVE_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The linear solver's solve "
                     "function failed in an unrecoverable manner.",
                     functionName);
    break;
  case IDA_RES_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided residual "
                     "function failed in an unrecoverable manner.",
                     functionName);
    break;
  case IDA_REP_RES_ERR:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided residual "
                     "function repeatedly returned a recoverable error flag, "
                     "but the solver was unable to recover.",
                     functionName);
    break;
  case IDA_RTFUNC_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The rootfinding function failed "
                     "in an unrecoverable manner.",
                     functionName);
    break;
  case IDA_CONSTR_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The inequality constraints were "
                     "violated and the solver was unable to recover.",
                     functionName);
    break;
  case IDA_FIRST_RES_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided residual "
                     "function failed recoverably on the first call.",
                     functionName);
    break;
  case IDA_LINESEARCH_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The line search failed.",
                     functionName);
    break;
  case IDA_NO_RECOVERY:
    throwStreamPrint(
        NULL,
        "##IDA## In function %s: The residual function, linear solver setup "
        "function, or linear solver solve function had a recoverable failure, "
        "but IDACalcIC could not recover.",
        functionName);
    break;
  case IDA_NLS_INIT_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The nonlinear solver's init routine failed.",
                     functionName);
    break;
  case IDA_NLS_SETUP_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The nonlinear solver's setup routine failed.",
                     functionName);
    break;
  case IDA_NLS_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: IDA_NLS_FAIL.",
                     functionName);
    break;
  case IDA_MEM_NULL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The ida_mem argument was NULL.",
                     functionName);
    break;
  case IDA_MEM_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: A memory allocation failed.",
                     functionName);
    break;
  case IDA_ILL_INPUT:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: One of the function inputs is illegal.",
                     functionName);
    break;
  case IDA_NO_MALLOC:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The ida memory was not allocated by a call to IDAInit.",
                     functionName);
    break;
  case IDA_BAD_EWT:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: Zero value of some error weight component.",
                     functionName);
    break;
  case IDA_BAD_K:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The k-th derivative is not available.",
                     functionName);
    break;
  case IDA_BAD_T:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The time t is outside the last step taken.",
                     functionName);
    break;
  case IDA_BAD_DKY:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The vector argument where derivative should be stored is NULL.",
                     functionName);
    break;
  case IDA_NO_QUAD:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: Quadratures were not initialized.",
                     functionName);
    break;
  case IDA_QRHS_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided right-hand side function for quadratures "
                     "failed in an unrecoverable manner.",
                     functionName);
    break;
  case IDA_FIRST_QRHS_ERR:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided right-hand side function for quadratures "
                     "failed in an unrecoverable manner on the first call.",
                     functionName);
    break;
  case IDA_REP_QRHS_ERR:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided right-hand side repeatedly returned "
                     "a recoverable error flag, but the solver was unable to recover.",
                     functionName);
    break;
  case IDA_NO_SENS:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: Sensitivities were not initialized.",
                     functionName);
    break;
  case IDA_SRES_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided sensitivity residual function failed "
                     "in an unrecoverable manner.",
                     functionName);
    break;
  case IDA_REP_SRES_ERR:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided sensitivity residual function repeatedly "
                     "returned a recoverable error flag, but the solver was unable to recover.",
                     functionName);
    break;
  case IDA_BAD_IS:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The sensitivity identifier is not valid.",
                     functionName);
    break;
  case IDA_NO_QUADSENS:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: Sensitivity-dependent quadratures were not initialized.",
                     functionName);
    break;
  case IDA_QSRHS_FAIL:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided sensitivity-dependent quadrature "
                     "righthand side function failed in an unrecoverable manner.",
                     functionName);
    break;
  case IDA_FIRST_QSRHS_ERR:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided sensitivity-dependent quadrature "
                     "righthand side function failed in an unrecoverable manner on the first call.",
                     functionName);
    break;
  case IDA_REP_QSRHS_ERR:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: The user-provided sensitivity-dependent quadrature "
                     "righthand side repeatedly returned a recoverable error flag, but the solver "
                     "was unable to recover.",
                     functionName);
    break;
  default:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: Error with flag %i.",
                     functionName, flag);
  }
}

/**
 * @brief Checks given IDALS flag and reports potential error.
 *
 * @param flag          Return value of Kinsol routine.
 * @param functionName  Name of IDALS function that returned the flag.
 */
static void checkReturnFlag_IDALS(int flag, const char *functionName) {
  switch (flag) {
  case IDALS_SUCCESS:
    break;
  case IDALS_MEM_NULL:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: The ida_mem argument was NULL.",
                     functionName);
    break;
  case IDALS_LMEM_NULL:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: The IDALS linear solver has "
                     "not been initialized.",
                     functionName);
    break;
  case IDALS_ILL_INPUT:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: The IDALS solver is not "
                     "compatible with the current NVECTOR module.",
                     functionName);
    break;
  case IDALS_MEM_FAIL:
    throwStreamPrint(
        NULL, "##IDALS## In function %s: A memory allocation request failed.",
        functionName);
    break;
  case IDALS_PMEM_NULL:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: The preconditioner module has "
                     "not been initialized.",
                     functionName);
    break;
  case IDALS_JACFUNC_UNRECVR:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: The Jacobian function failed "
                     "in an unrecoverable manner.",
                     functionName);
    break;
  case IDALS_JACFUNC_RECVR:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: The Jacobian function had a "
                     "recoverable error.",
                     functionName);
    break;
  case IDALS_SUNMAT_FAIL:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: An error occurred with the "
                     "current SUNMATRIX module.",
                     functionName);
    break;
  case IDALS_SUNLS_FAIL:
    throwStreamPrint(NULL,
                     "##IDALS## In function %s: An error occurred with the "
                     "current SUNLINSOL module.",
                     functionName);
    break;
  default:
    throwStreamPrint(NULL, "##IDALS## In function %s: Error with flag %i.",
                     functionName, flag);
  }
}

/**
 * @brief Error handler function for IDA
 *
 * @param errorCode   Error code from IDA
 * @param module      Name of the IDA module reporting the error.
 * @param function    Name of the function in which the error occurred.
 * @param msg         Error Message.
 * @param userData    Pointer to user data given with IDASetUserData.
 */
void idaErrorHandlerFunction(int errorCode, const char *module,
                             const char *function, char *msg, void *userData)
{
  /* Variables */
  IDA_SOLVER* idaData;
  DATA* data;

  if (userData != NULL && ACTIVE_STREAM(LOG_SOLVER)) {
    idaData = (IDA_SOLVER*) userData;
    data = (DATA*)idaData->userData->data;

    infoStreamPrint(LOG_SOLVER, 1, "#### IDA error message #####");
    infoStreamPrint(LOG_SOLVER, 0, " -> error code %d\n -> module %s\n -> function %s", errorCode, module, function);
    infoStreamPrint(LOG_SOLVER, 0, " Message: %s", msg);
    messageClose(LOG_SOLVER);
  }
}
#endif /* OMC_HAVE_IDA */

#ifndef OMC_FMI_RUNTIME
/**
 * @brief Checks given KINSOL flag and reports potential error.
 *
 * @param flag          Return value of Kinsol routine.
 * @param functionName  Name of Kinsol function that returned the flag.
 */
static void checkReturnFlag_KIN(int flag, const char *functionName) {

  const char* flagName = KINGetLinReturnFlagName(flag); /* memory is allocated here so it must be freed at the end, see kinsol_ls.c */

  switch (flag) {
  case KIN_SUCCESS:
  case KIN_INITIAL_GUESS_OK:
  case KIN_STEP_LT_STPTOL:
    break;
  case KIN_WARNING:
    warningStreamPrint(LOG_STDOUT, 0,
                       "##KINSOL## %s In function %s: Got some warning.", flagName, functionName);
    break;
  case KIN_MEM_NULL:
    throwStreamPrint(NULL, "##KINSOL## %s In function %s: Out of memory.", flagName, functionName);
    break;
  case KIN_ILL_INPUT:
    throwStreamPrint(NULL, "##KINSOL## %s In function %s: An input argument has an illegal value.", flagName, functionName);
    break;
  case KIN_NO_MALLOC:
    throwStreamPrint(NULL, "##KINSOL## %s In function %s: Kinsol memory was not allocated by a call to KINCreate.", flagName, functionName);
    break;
  case KIN_MEM_FAIL:
    throwStreamPrint(NULL, "##KINSOL## %s In function %s: A memory allocation request has failed.", flagName, functionName);
    break;
  case KIN_LINESEARCH_NONCONV:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: The line search algorithm was "
                     "unable to find an iterate sufficiently distinct from the "
                     "current iterate, or could not find an iterate satisfying "
                     "the sufficient decrease condition.", flagName,
                     functionName);
    break;
  case KIN_MAXITER_REACHED:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: The maximum number of "
                     "nonlinear iterations has been reached.", flagName,
                     functionName);
    break;
  case KIN_MXNEWT_5X_EXCEEDED:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_MXNEWT_5X_EXCEEDED.", flagName,
                     functionName);
    break;
  case KIN_LINESEARCH_BCFAIL:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_LINESEARCH_BCFAIL.", flagName,
                     functionName);
    break;
  case KIN_LINSOLV_NO_RECOVERY:
    throwStreamPrint(
        NULL,
        "##KINSOL## %s In function %s: Error KIN_LINSOLV_NO_RECOVERY.", flagName,
        functionName);
    break;
  case KIN_LINIT_FAIL:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_LINIT_FAIL.", flagName,
                     functionName);
    break;
  case KIN_LSETUP_FAIL:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_LSETUP_FAIL.", flagName,
                     functionName);
    break;
  case KIN_LSOLVE_FAIL:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_LSOLVE_FAIL.", flagName,
                     functionName);
    break;
  case KIN_SYSFUNC_FAIL:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_SYSFUNC_FAIL.", flagName,
                     functionName);
    break;
  case KIN_FIRST_SYSFUNC_ERR:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_FIRST_SYSFUNC_ERR.", flagName,
                     functionName);
    break;
  case KIN_REPTD_SYSFUNC_ERR:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_REPTD_SYSFUNC_ERR.", flagName,
                     functionName);
    break;
  case KIN_VECTOROP_ERR:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error KIN_VECTOROP_ERR.", flagName,
                     functionName);
    break;
  default:
    throwStreamPrint(NULL,
                     "##KINSOL## %s In function %s: Error with flag %i.", flagName,
                     functionName, flag);
  }

  free((char*)flagName);
}

/**
 * @brief Checks given KINLS flag and reports potential error.
 *
 * @param flag          Return value of Kinsol routine.
 * @param functionName  Name of Kinsol function that returned the flag.
 */
static void checkReturnFlag_KINLS(int flag, const char *functionName) {
  switch (flag) {
  case KINLS_SUCCESS:
    break;
  case KINLS_MEM_NULL:
    throwStreamPrint(NULL,
                     "##KINLS## In function %s: The kin_mem pointer is NULL.",
                     functionName);
    break;
  case KINLS_ILL_INPUT:
    throwStreamPrint(NULL,
                     "##KINLS## In function %s: An input argument has an "
                     "illegal value or is incompatible.",
                     functionName);
    break;
  case KINLS_MEM_FAIL:
    throwStreamPrint(
        NULL,
        "##KINLS## In function %s: A memory allocation request failed.",
        functionName);
    break;
  case KINLS_PMEM_NULL:
    throwStreamPrint(NULL,
                     "##KINLS## In function %s: TODO: ADD ERROR MESSAGE.",
                     functionName);
    break;
  case KINLS_JACFUNC_ERR:
    throwStreamPrint(NULL,
                     "##KINLS## In function %s: TODO: ADD ERROR MESSAGE.",
                     functionName);
    break;
  case KINLS_SUNMAT_FAIL:
    throwStreamPrint(NULL,
                     "##KINLS## In function %s: TODO: ADD ERROR MESSAGE.",
                     functionName);
    break;
  case KINLS_SUNLS_FAIL:
    throwStreamPrint(
        NULL,
        "##KINLS## In function %s: A call to the LS object failed.",
        functionName);
    break;
  default:
    throwStreamPrint(NULL,
                     "##KINLS## In function %s: Error with flag %i.",
                     functionName, flag);
  }
}

/**
 * @brief Error handler function given to KINSOL.
 *
 * @param errorCode   Error code from KINSOL
 * @param module      Name of the KINSOL module reporting the error.
 * @param function    Name of the function in which the error occurred.
 * @param msg         Error Message.
 * @param userData    Pointer to user data given with KINSetUserData.
 */
void kinsolErrorHandlerFunction(int errorCode, const char* module,
                                const char *function, char* msg,
                                void* userData) {
  /* Variables */
  NLS_KINSOL_DATA* kinsolData;
  DATA* data;
  NONLINEAR_SYSTEM_DATA* nlsData;
  long eqSystemNumber;

  if (userData != NULL) {
    kinsolData = (NLS_KINSOL_DATA *)userData;
    data = kinsolData->userData->data;
    nlsData = kinsolData->userData->nlsData;
    if (nlsData) {
      eqSystemNumber = nlsData->equationIndex;
    } else {
      eqSystemNumber = -1;
    }
  }

  if (ACTIVE_STREAM(LOG_NLS)) {
    if (userData != NULL && eqSystemNumber > 0) {
      warningStreamPrint(
          LOG_NLS, 1, "kinsol failed for system %d",
          modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber).id);
    } else {
      warningStreamPrint(
          LOG_NLS, 1, "kinsol failed");
    }

    warningStreamPrint(LOG_NLS, 0,
                       "[module] %s | [function] %s | [error_code] %d", module,
                       function, errorCode);
    if (msg) {
      warningStreamPrint(LOG_NLS, 0, "%s", msg);
    }

    messageClose(LOG_NLS);
  }
}

/**
 * @brief Info handler function given to KINSOL.
 *
 * Will only print information when stream LOG_NLS_V is active.
 *
 * @param module      Name of the KINSOL module reporting the information.
 * @param function    Name of the function reporting the information.
 * @param msg         Message.
 * @param user_data   Pointer to user data given with KINSetInfoHandlerFn.
 */
void kinsolInfoHandlerFunction(const char *module, const char *function,
                               char *msg, void *user_data) {
  UNUSED(user_data);  /* Disables compiler warning */

  if (ACTIVE_STREAM(LOG_NLS_V)) {
    warningStreamPrint(LOG_NLS_V, 1, "[module] %s | [function] %s:", module, function);
    if (msg) {
      warningStreamPrint(LOG_NLS_V, 0, "%s", msg);
    }

    messageClose(LOG_NLS_V);
  }
}

/**
 * @brief Checks given SUNLS flag and reports potential error.
 *
 * @param flag          Return value of SUNLS routine.
 * @param functionName  Name of SUNLS function that returned the flag.
 */
static void checkReturnFlag_SUNLS(int flag, const char *functionName) {
  switch (flag) {
  case SUNLS_SUCCESS:
    break;
  case SUNLS_MEM_NULL:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Mem argument is NULL.",
                     functionName);
    break;
  case SUNLS_ILL_INPUT:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Illegal function input.",
                     functionName);
    break;
  case SUNLS_MEM_FAIL:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Failed memory access.",
                     functionName);
    break;
  case SUNLS_ATIMES_FAIL_UNREC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Atimes unrecoverable failure.",
                     functionName);
    break;
  case SUNLS_PSET_FAIL_UNREC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Pset unrecoverable failure.",
                     functionName);
    break;
  case SUNLS_PSOLVE_FAIL_UNREC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Psolve unrecoverable failure.",
                     functionName);
    break;
  case SUNLS_PACKAGE_FAIL_UNREC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: External package unrec. fail.",
                     functionName);
    break;
  case SUNLS_GS_FAIL:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Gram-Schmidt failure.",
                     functionName);
    break;
  case SUNLS_QRSOL_FAIL:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: QRsol found singular R.",
                     functionName);
    break;
  case SUNLS_VECTOROP_ERR:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Vector operation error.",
                     functionName);
    break;
  case SUNLS_RES_REDUCED:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Monconv. solve, resid reduced.",
                     functionName);
    break;
  case SUNLS_CONV_FAIL:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Nonconvergent solve.",
                     functionName);
    break;
  case SUNLS_ATIMES_FAIL_REC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Atimes failed recoverably.",
                     functionName);
    break;
  case SUNLS_PSET_FAIL_REC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Pset failed recoverably.",
                     functionName);
    break;
  case SUNLS_PSOLVE_FAIL_REC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Psolve failed recoverably.",
                     functionName);
    break;
  case SUNLS_PACKAGE_FAIL_REC:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: External package recov. fail.",
                     functionName);
    break;
  case SUNLS_QRFACT_FAIL:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: QRfact found singular matrix.",
                     functionName);
    break;
  case SUNLS_LUFACT_FAIL:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: LUfact found singular matrix.",
                     functionName);
    break;
  default:
    throwStreamPrint(NULL,
                     "##SUNLS## In function %s: Error with flag %i.",
                     functionName, flag);
  }
}

/**
 * @brief Checks given SUNMatrix flag and reports potential error.
 *
 * @param flag          Return value of SUNMatrix routine.
 * @param functionName  Name of SUNMatrix function that returned the flag.
 */
static void checkReturnFlag_SUNMatrix(int flag, const char *functionName) {
  switch (flag) {
  case SUNMAT_SUCCESS:
    break;
  case SUNMAT_ILL_INPUT:
    throwStreamPrint(NULL,
                     "##SUNMatrix## In function %s: Illegal function input.",
                     functionName);
    break;
  case SUNMAT_MEM_FAIL:
    throwStreamPrint(NULL,
                     "##SUNMatrix## In function %s: Failed memory access/alloc.",
                     functionName);
    break;
  case SUNMAT_OPERATION_FAIL:
    throwStreamPrint(NULL,
                     "##SUNMatrix## In function %s: A SUNMatrix operation returned nonzero.",
                     functionName);
    break;
  case SUNMAT_MATVEC_SETUP_REQUIRED:
    throwStreamPrint(NULL,
                     "##SUNMatrix## In function %s: The SUNMatMatvecSetup routine needs to be called.",
                     functionName);
    break;
  default:
    throwStreamPrint(NULL,
                     "##SUNMatrix## In function %s: Error with flag %i.",
                     functionName, flag);
  }
}

/**
 * @brief Debug print function for CSC SunMatrix
 *
 * @param A           CSC SUNMatrix
 * @param name        Name of matrix A
 * @param logLevel    Stream to print output to
 */
void sundialsPrintSparseMatrix(SUNMatrix A, const char* name, const int logLevel) {

  int i;
  long int columns, rows, nnz, np;
  int lengthData, lengthIndexptrs;

  double* data;
  sunindextype* indexvals;
  sunindextype* indexptrs;

  assertStreamPrint(NULL, NULL != SM_DATA_S(A), "matrix data is NULL pointer");

  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(LOG_STDOUT, 0,
                     "In function sundialsPrintSparseMatrix: Wrong sparse format "
                     "of SUNMatrix A%s.", name);
  }

  if (ACTIVE_STREAM(logLevel)) {
    nnz = SUNSparseMatrix_NNZ(A);
    np = SM_NP_S(A);
    columns = SUNSparseMatrix_Columns(A);
    rows = SUNSparseMatrix_Rows(A);

    data = SM_DATA_S(A);
    indexvals = SM_INDEXVALS_S(A);
    indexptrs = SM_INDEXPTRS_S(A);

    infoStreamPrint(logLevel, 1, "##SUNDIALS## Sparse Matrix %s", name);
    infoStreamPrint(logLevel, 0, "Columns: N=%li, Rows: M=%li, CSC matrix, NNZ: %li, NP: %li", columns, rows, nnz, np);

    /* Print data array */
    lengthData = indexptrs[SUNSparseMatrix_NP(A)];

    const int tmpBuffSize = 20;
    const int bufferSize = fmax(1,lengthData)*fmax(1,columns);
    char *buffer = (char*)malloc(sizeof(char)*bufferSize*tmpBuffSize);
    char *tmpBuffer = (char*)malloc(sizeof(char)*tmpBuffSize);
    buffer[0] = 0;
    for (i=0; i<lengthData-1; i++) {
      snprintf(tmpBuffer, tmpBuffSize, "%10g, ", data[i]);
      strncat(buffer, tmpBuffer, tmpBuffSize);
    }
    snprintf(tmpBuffer, tmpBuffSize, "%10g", data[lengthData-1]);
    strncat(buffer, tmpBuffer, tmpBuffSize);
    infoStreamPrint(logLevel, 0, "data = {%s}", buffer);

    /* Print indexvals array */
    buffer[0] = 0;
    for (i=0; i<lengthData-1; i++) {
      snprintf(tmpBuffer, tmpBuffSize, "%li, ", indexvals[i]);
      strncat(buffer, tmpBuffer, tmpBuffSize);
    }
    snprintf(tmpBuffer, tmpBuffSize, "%li", indexvals[lengthData-1]);
    strncat(buffer, tmpBuffer, tmpBuffSize);
    infoStreamPrint(logLevel, 0, "indexvals = {%s}", buffer);

    /* Print indexptrs array */
    buffer[0] = 0;
    for (i=0; i<SUNSparseMatrix_NP(A); i++) {
      snprintf(tmpBuffer, tmpBuffSize, "%li, ", indexptrs[i]);
      strncat(buffer, tmpBuffer, tmpBuffSize);
    }
    snprintf(tmpBuffer, tmpBuffSize, "%li", indexptrs[SUNSparseMatrix_NP(A)]);
    strncat(buffer, tmpBuffer, tmpBuffSize);
    infoStreamPrint(logLevel, 0, "indexvals = {%s}", buffer);

    messageClose(logLevel);
    free(buffer);
    free(tmpBuffer);
  }
}
#endif /* #ifndef OMC_FMI_RUNTIME */

#else /* WITH_SUNDIALS */

/**
 * @brief Function not supported without WITH_SUNDIALS
 *
 * @param flag
 * @param type
 * @param functionName
 */
void checkReturnFlag_SUNDIALS(int flag, int type, const char *functionName) {
  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
}


/**
 * @brief Function not supported without WITH_SUNDIALS
 *
 * @param errorCode
 * @param module
 * @param function
 * @param msg
 * @param userData
 */
void kinsolErrorHandlerFunction(int errorCode, const char *module,
                                const char *function, char *msg,
                                void *userData) {
  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
}

/**
 * @brief  Function not supported without WITH_SUNDIALS
 *
 * @param module
 * @param function
 * @param msg
 * @param user_data
 */
void kinsolInfoHandlerFunction(const char *module, const char *function,
                               char *msg, void *user_data) {
  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
}

#endif /* WITH_SUNDIALS */
