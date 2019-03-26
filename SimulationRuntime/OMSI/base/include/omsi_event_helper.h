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


#ifndef OMSI_EVENT_HELPER__H_
#define OMSI_EVENT_HELPER__H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <assert.h>
#include <math.h>   /* fmin, fmod */

/* Public OMSI headers */
#include <omsi.h>
#include <omsi_utils.h>


/* Function prototypes */
omsi_bool omsi_function_zero_crossings (omsi_function_t*    this_function,
                                        omsi_bool           new_zero_crossing,
                                        omsi_unsigned_int   index,
                                        ModelState          model_state);

omsi_bool omsi_on_sample_event (omsi_function_t*    this_function,
                                omsi_unsigned_int   sample_id,
                                ModelState          model_state);

omsi_real omsi_next_sample(omsi_real    time,
                           omsi_sample* sample_event);

omsi_real omsi_compute_next_event_time (omsi_real           time,
                                        omsi_sample*        sample_events,
                                        omsi_unsigned_int   n_sample_events);

omsi_bool omsi_check_discrete_changes (omsi_t* omsi_data);

#ifdef __cplusplus
}
#endif
#endif

