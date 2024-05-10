/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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
