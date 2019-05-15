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
 * This file defines functions for the FMI used via the OpenModelica Simulation
 * Interface (OMSI). These are the common functions for getting and setting
 * variables and FMI informations.
 */

#ifndef OMSU_GETTERSANDSETTERS__H_
#define OMSU_GETTERSANDSETTERS__H_

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include <omsic.h>
#include <omsi_input_model_variables.h>
#include <omsi_getters_and_setters.h>

#include <omsu_common.h>
#include <omsu_helper.h>

#ifdef __cplusplus
extern "C" {
#endif



/* function prototypes */

omsi_status omsic_get_real(osu_t*                    OSU,
                           const omsi_unsigned_int   vr[],
                           omsi_unsigned_int         nvr,
                           omsi_real                 value[]);

omsi_status omsic_get_integer(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              omsi_int                   value[]);

omsi_status omsic_get_boolean(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              omsi_bool                  value[]);

omsi_status omsic_get_string(osu_t*                  OSU,
                             const omsi_unsigned_int vr[],
                             omsi_unsigned_int       nvr,
                             omsi_string             value[]);

omsi_status omsi_get_fmu_state(osu_t*        OSU,
                               void **      FMUstate);

omsi_status omsi_get_clock(osu_t*               OSU,
                           const omsi_int       clockIndex[],
                           omsi_unsigned_int    nClockIndex,
                           omsi_bool            tick[]);

omsi_status omsi_get_interval(osu_t*            OSU,
                              const omsi_int    clockIndex[],
                              omsi_unsigned_int nClockIndex,
                              omsi_real         interval[]);

omsi_status omsic_set_real(osu_t*                    OSU,
                           const omsi_unsigned_int   vr[],
                           omsi_unsigned_int         nvr,
                           const omsi_real           value[]);

omsi_status omsic_set_integer(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              const omsi_int             value[]);

omsi_status omsic_set_boolean(osu_t*                     OSU,
                              const omsi_unsigned_int    vr[],
                              omsi_unsigned_int          nvr,
                              const omsi_bool            value[]);

omsi_status omsic_set_string(osu_t*                  OSU,
                             const omsi_unsigned_int vr[],
                             omsi_unsigned_int       nvr,
                             const omsi_string       value[]);

omsi_status omsi_set_time(osu_t*    OSU,
                          omsi_real time);

omsi_status omsi_set_fmu_state(osu_t*   OSU,
                               void *   FMUstate);

omsi_status omsi_set_clock(osu_t*               OSU,
                           const omsi_int       clockIndex[],
                           omsi_unsigned_int    nClockIndex,
                           const omsi_bool      tick[],
                           const omsi_bool      subactive[]);

omsi_status omsi_set_interval(osu_t*            OSU,
                              const omsi_int    clockIndex[],
                              omsi_unsigned_int nClockIndex,
                              const omsi_real   interval[]);


#ifdef __cplusplus
}
#endif
#endif
