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

/*! \file sundials_error.h
 */

#ifndef _SUNDIALS_ERROR_H
#define _SUNDIALS_ERROR_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <string.h>

#ifndef OMC_FMI_RUNTIME
  #include "omc_config.h"
#endif
#include "../../simulation_data.h"
#include "../../util/simulation_options.h"
#include "../../util/omc_error.h"
#include "../simulation_info_json.h"

#ifdef WITH_SUNDIALS

#include <cvode/cvode.h>
#ifndef OMC_FMI_RUNTIME
#include <ida/ida.h>
#include <kinsol/kinsol.h>
#include "kinsolSolver.h"
#endif

/**
 * @brief Specify type of flag used by different SUNDIALS module for error
 * dispaly.
 */
typedef enum sundialsFlagType {
  SUNDIALS_UNKNOWN_FLAG, /* Unknown flag type */

  SUNDIALS_CV_FLAG,       /* CVODE main solver module flags */
  SUNDIALS_CVLS_FLAG,     /* CVODE main solver module flags */

  SUNDIALS_IDA_FLAG,      /* IDA main solver module flags */
  SUNDIALS_IDALS_FLAG,    /* IDA linear solver module flags */

  SUNDIALS_KIN_FLAG,      /* KINSOL main solver module flags */
  SUNDIALS_KINLS_FLAG,    /* KINSOL linear solver interface flags */

  SUNDIALS_SUNLS_FLAG     /* SUNDIALS linear solver flags */
} sundialsFlagType;

/* Function prototypes */
void checkReturnFlag_SUNDIALS(int flag, sundialsFlagType type,
                              const char *functionName);
#ifndef OMC_FMI_RUNTIME
void kinsolErrorHandlerFunction(int errorCode, const char *module,
                                const char *function, char *msg,
                                void *userData);
void kinsolInfoHandlerFunction(const char *module, const char *function,
                               char *msg, void *user_data);
void sundialsPrintSparseMatrix(SUNMatrix A, const char* name, const int logLevel);
#endif /* OMC_FMI_RUNTIME */
#endif /* WITH_SUNDIALS */

#ifdef __cplusplus
};
#endif

#endif /* _SUNDIALS_ERROR_H */