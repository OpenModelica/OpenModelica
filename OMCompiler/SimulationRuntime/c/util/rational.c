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
#include "omc_msvc.h"

RATIONAL makeRATIONAL(long a, long b)
{
  RATIONAL x = {a, b};
  return x;
}

static long long gcd(long long a, long long b)
{
  while(a != 0)
  {
    long long tmp = a;
    a = b % a;
    b = tmp;
  }
  return b;
}

static void simplifyRat(long long *a, long long *b)
{
  long long tmp = gcd(*a, *b);
  if(tmp != 0)
  {
    *a /= tmp;
    *b /= tmp;
  }
}

RATIONAL addInt2Rat(long a, RATIONAL b) {
  long long m = (long long)a * b.n + b.m;
  long long n = b.n;
  simplifyRat(&m, &n);
  return makeRATIONAL(m, n);
}

RATIONAL subInt2Rat(long a, RATIONAL b) {
  long long m = (long long)a * b.n - b.m;
  long long n = b.n;
  simplifyRat(&m, &n);
  return makeRATIONAL(m, n);
}

RATIONAL addRat2Rat(RATIONAL a, RATIONAL b) {
  long long m = (long long)a.m * b.n + (long long)b.m * a.n;
  long long n = (long long)a.n * b.n;
  simplifyRat(&m, &n);
  return makeRATIONAL(m, n);
}

RATIONAL multRat2Rat(RATIONAL a, RATIONAL b) {
  long long m = (long long)a.m * b.m;
  long long n = (long long)a.n * b.n;
  simplifyRat(&m, &n);
  return makeRATIONAL(m, n);
}

RATIONAL divRat2Rat(RATIONAL a, RATIONAL b) {
  long long m = (long long)a.m * b.n;
  long long n = (long long)a.n * b.m;
  n = n ? n : 1;  /*TODO: FIX ME!*/
  simplifyRat(&m, &n);
  return makeRATIONAL(m, n);
}

RATIONAL multInt2Rat(long a, RATIONAL b) {
  long long m = (long long)a * b.m;
  long long n = b.n;
  simplifyRat(&m, &n);
  return makeRATIONAL(m, n);
}

double rat2Real(RATIONAL a) {
  return (double)a.m / a.n;
}

static OMC_INLINE int sign(long n) {
  return n > 0 ? 1 : -1;
}

/*
 * Return minimum a, for which a >= m / n
 */
long ceilRat(RATIONAL a) {
  long k = a.m / a.n;
  return k + (a.m > 0 && a.m % a.n ? 1 : 0);
}

/*
 * Return minimum a, for which a > m / n
 */
long ceilRatStrict(RATIONAL a) {
  long k = a.m / a.n;
  return k + (a.m <= 0 && a.m % a.n ? 0 : 1);
}

/*
 * Return maximum a, for which a <= m / n
 */
long floorRat(RATIONAL a) {
  long k = a.m / a.n;
  return k - (a.m < 0 && a.m % a.n ? 1 : 0);
}

/*
 * Return maximum a, for which a < m / n
 */
long floorRatStrict(RATIONAL a) {
  long k = a.m / a.n;
  return k - (a.m >= 0 && a.m % a.n ? 0 : 1);
}
