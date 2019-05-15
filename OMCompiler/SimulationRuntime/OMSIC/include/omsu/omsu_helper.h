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

#ifndef OMSU_HELPER_H
#define OMSU_HELPER_H

#include <stdio.h>
#include <string.h>
#include <stddef.h>

#include <omsic.h>

#ifdef __cplusplus
extern "C" {
#endif



/* extern function prototypes
extern void printLapackData(solver_data_lapack*    lapack_data,
                            omsi_string     indent);*/


/* function prototypes */
void omsu_free_osu(osu_t* OSU);

omsi_string stateToString(osu_t* OSU);

omsi_bool invalidState(osu_t*       OSU,
                       omsi_string  function_name,
                       omsi_int     meStates,
                       omsi_int     csStates);

omsi_bool nullPointer(osu_t*        OSU,
                      omsi_string   function_name,
                      omsi_string   arg,
                      const void *  pointer);

omsi_bool vrOutOfRange(osu_t*               OSU,
                       omsi_string          function_name,
                       omsi_unsigned_int    vr,
                       omsi_int             end);

omsi_status unsupportedFunction(osu_t*      OSU,
                                omsi_string function_name,
                                omsi_int    statesExpected);

omsi_bool invalidNumber(osu_t*          OSU,
                        omsi_string     function_name,
                        omsi_string     arg,
                        omsi_int        n,
                        omsi_int        nExpected);

omsi_status omsi_set_debug_logging(osu_t*               OSU,
                                   omsi_bool            loggingOn,
                                   omsi_unsigned_int    nCategories,
                                   const omsi_string    categories[]);

ModelState omsic_get_model_state (void);

omsi_bool omsu_discrete_changes(osu_t*  OSU,
                                void*   threadData);

void omsu_storePreValues(omsi_t* omsi_data);

void omsu_update_pre_zero_crossings(sim_data_t*          sim_data,
                                    omsi_unsigned_int    n_zero_crossings);

omsi_bool omsu_values_equal(omsi_values*    vars_1,
                            omsi_values*    vars_2);

omsi_status omsu_copy_values(omsi_values*   target_vars,
                             omsi_values*   source_vars);

void omsu_print_osu (osu_t* OSU);

omsi_real division_error_time(const char*   msg,
                              omsi_real     time);

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif
