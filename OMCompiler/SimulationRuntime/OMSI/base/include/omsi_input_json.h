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

#ifndef OMSU_INPUT_JSON_H
#define OMSU_INPUT_JSON_H

#include <stdio.h>
#include <stdlib.h>

#include <omsi.h>
#include <omsi_callbacks.h>
#include <omsi_utils.h>

#include <uthash.h>
#include <omsi_mmap.h>



/* function prototypes */
omsi_status omsu_process_input_json(omsi_t*                         osu_data,
                                    omsi_string                     fileName,
                                    omsi_string                     fmuGUID,
                                    omsi_string                     instanceName,
                                    const omsi_callback_functions*  functions);

omsi_string readEquation(omsi_string        str,
                         equation_info_t*   equation_info,
                         omsi_unsigned_int  expected_id,
                         omsi_unsigned_int* count_init_eq,
                         omsi_unsigned_int* count_regular_eq,
                         omsi_unsigned_int* count_alias_eq);

omsi_string readEquations(omsi_string       str,
                          model_data_t*     model_data);











#endif
