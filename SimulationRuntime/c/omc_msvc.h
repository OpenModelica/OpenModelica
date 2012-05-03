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
#ifndef __OPENMODELICA_MSVC_H
#define __OPENMODELICA_MSVC_H

#include <math.h> /* Make sure we try to get INFINITY and NAN from the system. They are way cooler */

union MSVC_FLOAT_HACK
{
   unsigned char Bytes[4];
   float Value;
};
#ifndef INFINITY
static union MSVC_FLOAT_HACK __INFINITY = {{0x00, 0x00, 0x80, 0x7F}};
#define INFINITY (__INFINITY.Value)
#endif

#ifndef NAN
static union MSVC_FLOAT_HACK __NAN = {{0x00, 0x00, 0xC0, 0x7F}};
#define NAN (__NAN.Value)
#endif

/* Compatibility header for MSVC compiler.
 * (Things that MinGW has but MSVC does not)
 */
#if defined(_MSC_VER)
#ifndef WIN32
#define WIN32
#endif
#if defined(_WIN32) || defined(_WIN64)
#define fmax(x, y) ((x>y)?x:y)
#define fmin(x, y) ((x<y)?x:y)
#define snprintf sprintf_s
#define srandom srand
#define random rand
#endif

#define round(dbl) (dbl >= 0.0 ? (int)(dbl + 0.5) : ((dbl - (double)(int)dbl) <= -0.5 ? (int)dbl : (int)(dbl - 0.5)))

#define geteuid(void) (-1)

#endif

#endif
