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


#ifndef OMSI_INITIALIZATION__H_
#define OMSI_INITIALIZATION__H_

#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

/* Public OMSI headers */
#include <omsi.h>
#include <omsi_callbacks.h>

/* OMSIBase headers */
#include <omsi_input_xml.h>
#include <omsi_input_json.h>
#include <omsi_input_sim_data.h>
#include <omsi_input_model_variables.h>
#include <omsi_utils.h>

typedef struct modelDescriptionData {
    omsi_char* modelName;
} modelDescriptionData;


omsi_t* omsi_instantiate(omsi_string                            instanceName,
                         omsu_type                              fmuType,
                         omsi_string                            fmuGUID,
                         omsi_string                            fmuResourceLocation,
                         const omsi_callback_functions*         functions,
                         omsi_template_callback_functions_t*    template_functions,
                         omsi_bool                              __attribute__((unused)) visible,
                         omsi_bool                              loggingOn,
                         ModelState*                            model_state);

omsi_string omsi_get_model_name(omsi_string fmuResourceLocation);

omsi_status omsi_intialize_callbacks(omsi_t*                                omsu,
                                     omsi_template_callback_functions_t*    template_functions );
#ifdef __cplusplus
}
#endif
#endif
