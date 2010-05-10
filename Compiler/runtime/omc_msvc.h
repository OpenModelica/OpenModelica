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

/* Compatibility header for MSVC compiler */
#if defined(_MSC_VER)

union MSVC_FLOAT_HACK
{
   unsigned char Bytes[4];
   float Value;
};
static union MSVC_FLOAT_HACK __INFINITY = {{0x00, 0x00, 0x80, 0x7F}};
static union MSVC_FLOAT_HACK __NAN = {{0x00, 0x00, 0xC0, 0x7F}};
#define INFINITY (__INFINITY.Value)
#define NAN (__NAN.Value)

#define round(dbl) (dbl >= 0.0 ? (int)(dbl + 0.5) : ((dbl - (double)(int)dbl) <= -0.5 ? (int)dbl : (int)(dbl - 0.5)))

#endif

#endif
