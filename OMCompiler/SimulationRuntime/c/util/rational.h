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
 * @brief Underlying integer type
 */
typedef long rat_int_t;
#define RAT_INT_ABS labs
#define RAT_INT_MIN LONG_MIN
#define RAT_FMT "%ld"

/**
 * @brief Rational number num/den
 */
typedef struct RATIONAL {
  rat_int_t num;  /**< numerator */
  rat_int_t den;  /**< denominator */
} RATIONAL;

RATIONAL makeRATIONAL(rat_int_t num, rat_int_t den);

RATIONAL addRat(RATIONAL r1, RATIONAL r2);
RATIONAL negRat(RATIONAL r);
RATIONAL subRat(RATIONAL r1, RATIONAL r2);
RATIONAL mulRat(RATIONAL r1, RATIONAL r2);
RATIONAL invRat(RATIONAL r);
RATIONAL divRat(RATIONAL r1, RATIONAL r2);

double rat2Real(RATIONAL r);
RATIONAL int2Rat(rat_int_t n);
rat_int_t ceilRat(RATIONAL r);
rat_int_t ceilRatStrict(RATIONAL r);
rat_int_t floorRat(RATIONAL r);
rat_int_t floorRatStrict(RATIONAL r);

#ifdef __cplusplus
}
#endif

#endif
