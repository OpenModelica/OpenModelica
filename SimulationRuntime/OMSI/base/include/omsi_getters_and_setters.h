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

#ifndef OMSU_GETTERS_AND_SETTERS_H
#define OMSU_GETTERS_AND_SETTERS_H

#include <omsi.h>
#include <omsi_callbacks.h>

#include <omsi_utils.h>
#include <omsi_input_model_variables.h>

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Public function prototypes */
omsi_status omsi_get_real(omsi_t*                   omsu,
                          const omsi_unsigned_int*  vr,
                          omsi_unsigned_int         nvr,
                          omsi_real*                value);

omsi_status omsi_get_integer(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             omsi_int*                  value);

omsi_status omsi_get_boolean(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             omsi_bool*                 value);

omsi_status omsi_get_string(omsi_t*                     omsu,
                            const omsi_unsigned_int*    vr,
                            omsi_unsigned_int           nvr,
                            omsi_string*                value);

omsi_status omsi_set_real(omsi_t*                   omsu,
                          const omsi_unsigned_int*  vr,
                          omsi_unsigned_int         nvr,
                          const omsi_real*          value);

omsi_status omsi_set_integer(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             const omsi_int*            value);

omsi_status omsi_set_boolean(omsi_t*                    omsu,
                             const omsi_unsigned_int*   vr,
                             omsi_unsigned_int          nvr,
                             const omsi_bool*           value);

omsi_status omsi_set_string(omsi_t*                     omsu,
                            const omsi_unsigned_int*    vr,
                            omsi_unsigned_int           nvr,
                            const omsi_string*          value);

/* Private function prototypes */
omsi_real getReal (omsi_t*                  osu_data,
                   const omsi_unsigned_int  vr);

omsi_status setReal(omsi_t*                 osu_data,
                    const omsi_unsigned_int vr,
                    const omsi_real         value);

omsi_int getInteger (omsi_t*                    osu_data,
                     const omsi_unsigned_int    vr);

omsi_status setInteger(omsi_t*                  osu_data,
                       const omsi_unsigned_int  vr,
                       const omsi_int           value);

omsi_bool getBoolean (omsi_t*                  osu_data,
                      const omsi_unsigned_int   vr);

omsi_status setBoolean(omsi_t*                  osu_data,
                       const omsi_unsigned_int  vr,
                       const omsi_bool          value);

omsi_string getString (omsi_t*                  osu_data,
                       const omsi_unsigned_int  vr);

omsi_status setString(omsi_t*                  osu_data,
                      const omsi_unsigned_int   vr,
                      const omsi_string         value);

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif
#endif
