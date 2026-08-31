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

#ifndef __OMC_OPC_UA_H
#define __OMC_OPC_UA_H

#include "simulation_data.h"

#if !defined(OPC_UA_EXPORT)
  #if defined _WIN32 || defined __CYGWIN__
    /* Note: both gcc & MSVC on Windows support this syntax. */
    #define OPC_UA_EXPORT __declspec(dllexport)
  #else
    #if __GNUC__ >= 4
      #define OPC_UA_EXPORT __attribute__ ((visibility ("default")))
    #else
      #define OPC_UA_EXPORT
    #endif
  #endif
#endif

OPC_UA_EXPORT void* omc_embedded_server_init(DATA *data, double t, double step, const char *argv_0, void (*omc_real_time_sync_update)(DATA *data, double scaling), int port);
OPC_UA_EXPORT void omc_wait_for_step(void*);
OPC_UA_EXPORT void omc_embedded_server_deinit(void*);
OPC_UA_EXPORT int omc_embedded_server_update(void*, double t, int*);

#define OMC_OPC_NODEID_STEP 10000
#define OMC_OPC_NODEID_RUN  10001
#define OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR 10002
#define OMC_OPC_NODEID_ENABLE_STOP_TIME 10003
#define OMC_OPC_NODEID_TIME 10004
#define OMC_OPC_NODEID_TERMINATE 10005

#define MAX_VARS_KIND 100000000
#define ALIAS_START_ID (MAX_VARS_KIND/2)

typedef enum {
  VARKIND_REAL = 1,
  VARKIND_BOOL = 2
} var_kind_t;

#define OMC_OPC_NS_REAL_VARIABLES 3

#endif
