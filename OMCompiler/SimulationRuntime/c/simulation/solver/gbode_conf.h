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
 * @brief Extrapolation method for single-rate / multi-rate error estimation.
 */
enum GB_EXTRAPOL_METHOD{
  GB_EXT_UNKNOWN = 0,    /* Unknown method */

  GB_EXT_DEFAULT,        /* Default, depending on the Runge-Kutta method */
  GB_EXT_RICHARDSON,     /* Richardson extrapolation */
  GB_EXT_EMBEDDED        /* Embedded scheme */
};

/**
 * @brief Variants of PI controller.
 */
typedef enum {
  GB_PI_UNKNOWN = 0,    /* Unknown method */

  GB_PI_34,             /* PI34-Controller (Hairer) */
  GB_PI_33,             /* PI33-Controller (Hairer) */
  GB_PI_42              /* PI42-Controller (Soederlind) */
} GB_PI_VARIANTS;

typedef enum {
    GB_PID_UNKNOWN = 0, /* Unknown method */

    GB_PID_H312,        /* PIDH312-Controller (Hairer) */
    GB_PID_SOEDERLIND,  /* PID-Controller (Soederlind) */
    GB_PID_STIFF        /* PID-Controller for stiff systems */
} GB_PID_VARIANTS;

// Declaration only
extern GB_PI_VARIANTS pi_type;
extern GB_PID_VARIANTS pid_type;
extern unsigned int use_fhr;
extern double use_filter;

enum GB_METHOD getGB_method(enum _FLAG flag);
enum GB_INTERPOL_METHOD getInterpolationMethod(enum _FLAG flag);
enum GB_CTRL_METHOD getControllerMethod(enum _FLAG flag);
enum GB_NLS_METHOD getGB_NLS_method(enum _FLAG flag);
double getGBRatio();
double getGBCtrlFilterValue();
enum GB_EXTRAPOL_METHOD getGBErr(enum _FLAG flag);

#ifdef __cplusplus
};
#endif

#endif  /* _GBODE_CONF_H_ */
