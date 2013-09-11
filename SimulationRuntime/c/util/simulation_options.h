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

/* Simulation help constants are available in the regular runtime so we can link omc with them */

#ifndef OPENMODELICA_SIMULATION_OPTIONS_H

#if defined(__cplusplus)
  extern "C" {
#endif

enum _FLAG
{
  FLAG_UNKNOWN = 0,

  FLAG_CLOCK,
  FLAG_CPU,
  FLAG_F,
  FLAG_HELP,
  FLAG_IIF,
  FLAG_IIM,
  FLAG_IIT,
  FLAG_ILS,
  FLAG_INTERACTIVE,
  FLAG_IOM,
  FLAG_L,
  FLAG_LS,
  FLAG_LS_IPOPT,
  FLAG_LV,
  FLAG_MEASURETIMEPLOTFORMAT,
  FLAG_NLS,
  FLAG_NOEMIT,
  FLAG_OUTPUT,
  FLAG_OVERRIDE,
  FLAG_OVERRIDE_FILE,
  FLAG_PORT,
  FLAG_R,
  FLAG_S,
  FLAG_W,

  FLAG_MAX
};

enum _FLAG_TYPE
{
  FLAG_TYPE_UNKNOWN = 0,

  FLAG_TYPE_FLAG,         /* e.g. -f */
  FLAG_TYPE_OPTION,       /* e.g. -f=value or -f value */

  FLAG_TYPE_MAX
};

extern const char *FLAG_NAME[FLAG_MAX+1];
extern const char *FLAG_DESC[FLAG_MAX+1];
extern const char *FLAG_DETAILED_DESC[FLAG_MAX+1];
extern const int FLAG_TYPE[FLAG_MAX];

#if defined(__cplusplus)
  }
#endif

#endif
