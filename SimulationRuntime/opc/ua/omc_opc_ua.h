/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Linköping University,
* Department of Computer and Information Science,
* SE-58183 Linköping, Sweden.
*
* All rights reserved.
*
* THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
* AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
* ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
* ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
*
* The OpenModelica software and the Open Source Modelica
* Consortium (OSMC) Public License (OSMC-PL) are obtained
* from Linköping University, either from the above address,
* from the URLs: http://www.ida.liu.se/projects/OpenModelica or
* http://www.openmodelica.org, and in the OpenModelica distribution.
* GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
*
* This program is distributed WITHOUT ANY WARRANTY; without
* even the implied warranty of  MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
* IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
* OF OSMC-PL.
*
* See the full OSMC Public License conditions for more details.
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

OPC_UA_EXPORT void* omc_embedded_server_init(DATA *data, double t, double step, const char *argv_0, void (*omc_real_time_sync_update)(DATA *data, double scaling));
OPC_UA_EXPORT void omc_embedded_server_deinit(void*);
OPC_UA_EXPORT void omc_embedded_server_update(void*, double t);

#define OMC_OPC_NODEID_STEP 10000
#define OMC_OPC_NODEID_RUN  10001
#define OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR 10002
#define OMC_OPC_NODEID_ENABLE_STOP_TIME 10003
#define OMC_OPC_NODEID_TIME 10004

#define MAX_VARS_KIND 100000000
#define ALIAS_START_ID (MAX_VARS_KIND/2)

typedef enum {
  VARKIND_REAL = 1,
  VARKIND_BOOL = 2
} var_kind_t;

#define OMC_OPC_NS_REAL_VARIABLES 3

#endif
