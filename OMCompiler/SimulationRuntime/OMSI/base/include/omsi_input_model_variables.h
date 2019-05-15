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

#ifndef OMSU_INPUT_MODEL_VARIABLES_H
#define OMSU_INPUT_MODEL_VARIABLES_H

#include <omsi.h>
#include <omsi_callbacks.h>

#include <omsi_utils.h>

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* public function prototypes */

omsi_status omsi_allocate_model_variables(omsi_t*                           omsu,
                                          const omsi_callback_functions*    functions);

omsi_status omsi_initialize_model_variables(omsi_t*                         omsu,
                                            const omsi_callback_functions*  functions,
                                            omsi_string                     instanceName);

omsi_status omsi_free_model_variables(sim_data_t* sim_data);


void *alignedMalloc(size_t required_bytes,
                    size_t alignment);

void alignedFree(void* p);

omsi_bool model_variables_allocated(omsi_t*     omsu,
                                    omsi_string functionName);


#ifdef __cplusplus
}  /* end of extern "C" { */
#endif
#endif
