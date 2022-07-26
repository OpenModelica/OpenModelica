/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Open Source Modelica Consortium (OSMC),
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

/*! \file gbode_conf.h
 */

#ifndef _GBODE_CONF_H_
#define _GBODE_CONF_H_

#include "../../simulation/options.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Step size controller method
 */
enum GB_CTRL_METHOD {
  GB_CTRL_UNKNOWN = 0,  /* Unknown controller */
  GB_CTRL_I = 1,        /* I controller */
  GB_CTRL_PI = 2,       /* PI controller */
  GB_CTRL_CNST = 3,     /* Constant step size */

  GB_CTRL_MAX
};

extern const char *GB_CTRL_METHOD_NAME[GB_CTRL_MAX];
extern const char *GB_CTRL_METHOD_DESC[GB_CTRL_MAX];

enum GB_INTERPOL_METHOD {
  GB_INTERPOL_UNKNOWN = 0,      /* Unknown interpolation method */
  GB_INTERPOL_LIN,              /* Linear interpolation */
  GB_INTERPOL_HERMITE,          /* Hermite interpolation */
  GB_INTERPOL_HERMITE_a,        /* Hermite interpolation (only for left hand side)*/
  GB_INTERPOL_HERMITE_b,        /* Hermite interpolation (only for right hand side)*/
  GB_INTERPOL_HERMITE_ERRCTRL,  /* Hermite interpolation with error control */
  GB_DENSE_OUTPUT,              /* Dense output, if available else hermite */
  GB_DENSE_OUTPUT_ERRCTRL,      /* Dense output, if available else hermite with error control */

  GB_INTERPOL_MAX
};

extern const char *GB_INTERPOL_METHOD_NAME[GB_INTERPOL_MAX];
extern const char *GB_INTERPOL_METHOD_DESC[GB_INTERPOL_MAX];

enum GB_METHOD getGB_method(enum _FLAG flag);
enum GB_NLS_METHOD getGB_NLS_method(enum _FLAG flag);
enum GB_CTRL_METHOD getControllerMethod();
enum GB_INTERPOL_METHOD getInterpolationMethod(enum _FLAG flag);
double getGBRatio();

#ifdef __cplusplus
};
#endif

#endif  /* _GBODE_CONF_H_ */
