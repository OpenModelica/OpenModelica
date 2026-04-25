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

#pragma once


#include <algorithm>        ///< use of min, max, etc.
#include <limits>
#include <math.h>      ///< mathematical expressions
//vxworks: #include <memory.h>      ///< use of memset, etc.
#undef min
#undef max
using std::min;
using std::max;

/*****************************************************************************/
/**

Constant factors for open modelica.

\date     October, 1st, 2008
\author

*/


/// Machine presicion
#define UROUND    (std::numeric_limits<double>::epsilon( ))

/// Smalles possible number (represents -\inf)
#define MIN_DOUBLE    (std::numeric_limits<double>::min( ))

/// Largest possible number (represents +\inf)
#define MAX_DOUBLE    (std::numeric_limits<double>::max( ))

/// Pi
#define PI 3.141592653589793

/// Kelvin to Celsius
#define K2C    273.15

/// Degrees to Radians
#define DEG2RAD    0.017453292519943295769236907684886

/// Degrees to Radians
#define RAD2DEG    57.295779513082320876798154814105
