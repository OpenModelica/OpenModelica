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

#ifndef _SIMULATION_VARINFO_H
#define _SIMULATION_VARINFO_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Variable data type.
 */
enum var_type {
  VAR_TYPE_UNKNOWN = 0, /* Unknown variable type */

  VAR_TYPE_REAL,        /* Real type */
  VAR_TYPE_INTEGER,     /* Integer type */
  VAR_TYPE_BOOLEAN,     /* Boolean type */
  VAR_TYPE_STRING,      /* String type */

  VAR_TYPE_MAX          /* Number of variable types */
};

extern const char *var_type_names[VAR_TYPE_MAX];

/**
 * @brief Variable kind.
 */
enum var_kind {
  VAR_KIND_UNKNOWN = 0, /* Unknown variable kind */

  VAR_KIND_STATE,       /* State */
  VAR_KIND_VARIABLE,    /* Variable */
  VAR_KIND_PARAMETER,   /* Parameter */

  VAR_KIND_MAX          /* Number of variable kinds */
};

extern const char *var_kind_names[VAR_KIND_MAX];

extern void printErrorEqSyst(EQUATION_SYSTEM_ERROR err, EQUATION_INFO eq, double time);

extern void freeVarInfo(VAR_INFO* info);

#ifdef __cplusplus
}
#endif

#endif
