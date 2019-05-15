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

/*
 * This file defines functions for the FMI continuous simulation used via the OpenModelica
 * Simulation Interface (OMSI). These are the functions to evaluate the
 * model equations during continuous-time mode with OMSI.
 */

#ifndef OMSU_CONTINUOUSSIMULATION__H_
#define OMSU_CONTINUOUSSIMULATION__H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include <omsic.h>

#include <omsu_getters_and_setters.h>
#include <omsu_event_simulation.h>
#include <omsu_helper.h>

/*#include <omsu_helper.h>
#include <omsu_me.h>*/

/* function prototypes */
omsi_status omsi_new_discrete_state(osu_t*              OSU,
                                    omsi_event_info*    eventInfo);

omsi_status omsi_enter_continuous_time_mode(osu_t* OSU);

omsi_status omsi_set_continuous_states(osu_t*               OSU,
                                       const omsi_real      x[],
                                       omsi_unsigned_int    nx);

omsi_status omsi_get_continuous_states(osu_t*               OSU,
                                       omsi_real            x[],
                                       omsi_unsigned_int    nx);

omsi_status omsi_get_nominals_of_continuous_states(osu_t*               OSU,
                                                   omsi_real            x_nominal[],
                                                   omsi_unsigned_int    nx);

omsi_status omsi_completed_integrator_step(osu_t*       OSU,
                                           omsi_bool    noSetFMUStatePriorToCurrentPoint,
                                           omsi_bool*   enterEventMode,
                                           omsi_bool*   terminateSimulation);

omsi_status omsi_get_derivatives(osu_t*             OSU,
                                 omsi_real          derivatives[],
                                 omsi_unsigned_int  nx);

omsi_status omsi_get_directional_derivative(osu_t*                  OSU,
                                            const omsi_unsigned_int vUnknown_ref[],
                                            omsi_unsigned_int       nUnknown,
                                            const omsi_unsigned_int vKnown_ref[],
                                            omsi_unsigned_int       nKnown,
                                            const omsi_real         dvKnown[],
                                            omsi_real               dvUnknown[]);


#ifdef __cplusplus
}
#endif
#endif
