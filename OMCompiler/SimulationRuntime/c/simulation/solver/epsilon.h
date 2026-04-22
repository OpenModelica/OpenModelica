/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include <float.h>

#ifndef EPSILON_H
#define EPSILON_H

/*
 * used in events.c in function checkForSampleEvent and handleEvents
 * to detect sample time.
 */
static const double SAMPLE_EPS = 1e-14;

static const double SYNC_EPS = 1e-14;

/*
 * used in dassl.c for function dasrt_step
 * to prevent dassl errors, because of too small step size.
 */
static const double DASSL_STEP_EPS = 1e-13;

/*
 * used in solver_main.c for function initializeSolverData
 * defines the minimal step size
 */
static const double MINIMAL_STEP_SIZE = 1e-12;
static const double GB_MINIMAL_STEP_SIZE = 1e-20;

/*
 * used in model_help.c for function setZCtol
 * defines a threshold for relation hysteresis,
 * in multiplied by minimum(tolerance, step-size)
 */
static const double TOL_HYSTERESIS_ZEROCROSSINGS = 1e-4;

/*
 * used in spatialDistribution.c for function initSpatialDistribution
 */
static const double SPATIAL_EPS = DBL_EPSILON;

static const double SPATIAL_ZERO_DELTA_X = 1e-12;

#endif
