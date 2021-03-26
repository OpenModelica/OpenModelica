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

#ifndef _RATIONAL_H_
#define _RATIONAL_H_

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Rational number m/n
 */
typedef struct RATIONAL {
  long m;       /**< numerator */
  long n;       /**< denominator */
} RATIONAL;

RATIONAL makeRATIONAL(long a, long b);
RATIONAL addInt2Rat(long integer, RATIONAL rational);
RATIONAL subInt2Rat(long integer, RATIONAL rational);
RATIONAL multInt2Rat(long integer, RATIONAL rational);
RATIONAL addRat2Rat(RATIONAL a, RATIONAL b);
RATIONAL multRat2Rat(RATIONAL a, RATIONAL b);
RATIONAL divRat2Rat(RATIONAL a, RATIONAL b);
double rat2Real(RATIONAL a);
long ceilRat(RATIONAL a);
long ceilRatStrict(RATIONAL a);
long floorRat(RATIONAL a);
long floorRatStrict(RATIONAL a);

#ifdef __cplusplus
}
#endif

#endif
