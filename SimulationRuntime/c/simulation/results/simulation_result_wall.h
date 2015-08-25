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
  Stores results in a Wall file format.

  Specification of the Wall format can be found at http://github.com/xogeny/recon
 */

#ifndef _SIMULATION_RESULT_WALL_H_
#define _SIMULATION_RESULT_WALL_H_

#include "simulation_result.h"
#include "simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif /* cplusplus */

#if !defined(OMC_MINIMAL_RUNTIME)
void recon_wall_init(simulation_result *self,DATA *data, threadData_t *threadData);
void recon_wall_emit(simulation_result *self,DATA *data, threadData_t *threadData);
void recon_wall_writeParameterData(simulation_result *self,DATA *data, threadData_t *threadData);
void recon_wall_free(simulation_result *self,DATA *data, threadData_t *threadData);
#endif

#ifdef __cplusplus
}
#endif /* cplusplus */

#endif /* _SIMULATION_RESULT_WALL_H_ */
