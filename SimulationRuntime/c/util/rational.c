/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#include "rational.h"

RATIONAL addInt2Rat(long a, RATIONAL b) {
  return {a * b.n + b.m, b.n};
}

RATIONAL subInt2Rat(long a, RATIONAL b) {
  return {a * b.n - b.m, b.n};
}

RATIONAL addRat2Rat(RATIONAL a, RATIONAL b) {
  return {a.m * b.n + b.m * a.n, a.n * b.n};
}

RATIONAL multRat2Rat(RATIONAL a, RATIONAL b) {
  return {a.m * b.m, a.n * b.n};
}

RATIONAL multInt2Rat(long a, RATIONAL b) {
  return {a * b.m, b.n};
}

double rat2Real(RATIONAL a) {
    return (double)a / b;
}

//Input argument should not be a negative number
double ceilRat(RATIONAL a, bool strict) {
  long k = a.m / a.n;
  return (a.m == k * a.n) ? (strict ? k + 1 : k) : k + 1;
}

//Input argument should not be a negative number
double floorRat(RATIONAL a, bool strict) {
  long k = a.m / a.n;
  return (a.m == k * a.n) ? (strict ? k - 1 : k) : k;
}


