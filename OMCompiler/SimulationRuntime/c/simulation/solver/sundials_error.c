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

/* Internal function prototypes */
static void checkReturnFlag_KIN(int flag, const char *functionName);
static void checkReturnFlag_KINLS(int flag, const char *functionName);
static void checkReturnFlag_IDA(int flag, const char *functionName);
static void checkReturnFlag_SUNLS(int flag, const char *functionName);



/**
 * @brief Error handler function given to KINSOL.
 *
 * @param errorCode   Error code from KINSOL
 * @param module      Name of the KINSOL module reporting the error.
 * @param function    Name of the function in which the error occurred.
 * @param msg         Error Message.
 * @param userData    Pointer to user data given with KINSetErrHandlerFn.
 */
void kinsolErrorHandlerFunction(int errorCode, const char *module,
                                const char *function, char *msg,
                                void *userData) {
  /* Variables */
  NLS_KINSOL_DATA *kinsolData;
  DATA *data;
  int sysNumber;
  long eqSystemNumber;

  if (userData != NULL) {
    kinsolData = (NLS_KINSOL_DATA *)userData;
    data = kinsolData->userData.data;
    sysNumber = kinsolData->userData.sysNumber;
    eqSystemNumber = data->simulationInfo->nonlinearSystemData[sysNumber].equationIndex;
  }

  if (ACTIVE_STREAM(LOG_NLS)) {
    if (userData != NULL) {
      warningStreamPrint(
          LOG_NLS, 1, "kinsol failed for system %d",
          modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber).id);
    } else {
      warningStreamPrint(
          LOG_NLS, 1, "kinsol failed for some system");
    }

    warningStreamPrint(LOG_NLS, 0,
                       "[module] %s | [function] %s | [error_code] %d", module,
                       function, errorCode);
    warningStreamPrint(LOG_NLS, 0, "%s", msg);

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
  UNUSED(user_data);  /* DIsables compiler warning */

  if (ACTIVE_STREAM(LOG_NLS_V)) {
    warningStreamPrint(LOG_NLS_V, 1, "[module] %s | [function] %s:", module, function);
    warningStreamPrint(LOG_NLS_V, 0, "%s", msg);

    messageClose(LOG_NLS_V);
  }
}


/**
 * @brief Checks given flag and reports potential error.
 *
 * Checky sundialsFlagType type to decide what kind given flag is.
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
      throwStreamPrint(NULL, "##SUNDIALS##: Some error with value %u occured in function %s.", flag, functionName);
    }
  case SUNDIALS_KIN_FLAG:
    checkReturnFlag_KIN(flag, functionName);
    break;
  case SUNDIALS_KINLS_FLAG:
    checkReturnFlag_KINLS(flag, functionName);
    break;
  case SUNDIALS_IDA_FLAG:
    checkReturnFlag_IDA(flag, functionName);
    break;
  case SUNDIALS_SUNLS_FLAG:
    checkReturnFlag_SUNLS(flag, functionName);
    break;
  default:
    throwStreamPrint(NULL, "In function checkReturnFlag_SUNDIALS: Invalid sundialsFlagType %u.", type);
    break;
  }
}

/**
 * @brief Checks given KINSOL flag and reports potential error.
 *
 * @param flag          Return value of Kinsol routine.
 * @param functionName  Name of Kinsol function that returned the flag.
 */
static void checkReturnFlag_KIN(int flag, const char *functionName) {

  const char* flagName = KINGetLinReturnFlagName(flag);

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
 * @brief Checks given IDA flag and reports potential error.
 *
 * @param flag          Return value of Kinsol routine.
 * @param functionName  Name of IDA function that returned the flag.
 */
static void checkReturnFlag_IDA(int flag, const char *functionName) {
  switch (flag) {
  case IDA_SUCCESS:
  case IDA_TSTOP_RETURN:
  case IDA_ROOT_RETURN:
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
                     "accuracy demanded by the user for some internal step..",
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
                     "##IDA## In function %s: The rootnding function failed "
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
                     "function failed recoverably on the rst call.",
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
  default:
    throwStreamPrint(NULL,
                     "##IDA## In function %s: Error with flag %i.",
                     functionName, flag);
  }
}

/**
 * @brief Checks given SUNLS flag and reports potential error.
 *
 * @param flag          Return value of Kinsol routine.
 * @param functionName  Name of Kinsol function that returned the flag.
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
                     "##SUNLS## In function %s: Gram-Schmidt failuret.",
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

#else

/**
 * @brief Function not supported
 *
 * @param flag
 * @param type
 * @param functionName
 */
void checkReturnFlag_SUNDIALS(int flag, int type, const char *functionName) {
  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
}


/**
 * @brief Function not supported
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

void kinsolInfoHandlerFunction(const char *module, const char *function,
                               char *msg, void *user_data) {
  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
}

#endif /* WITH_SUNDIALS */