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
#include "omc_error.h"
#include <assert.h>
#include <stdlib.h>


/* Function prototypes */
static void simplifyRat(long *a, long *b);


/**
 * @brief Create rational number from numerator and denominator.
 *
 * Asserts denominator is non-zero and simplifies rational.
 *
 * @param m           Numerator
 * @param n           Denominator
 * @return RATIONAL   m/n.
 */
RATIONAL makeRATIONAL(long m, long n)
{
  assert(n!=0);
  simplifyRat(&m, &n);
  RATIONAL rational = {m, n};
  return rational;
}


/**
 * @brief Greatest common divisor.
 *
 * Largest positive integer that divides a and b.
 * gcd(a,b)
 *
 * @param a             First integer a.
 * @param b             Second integer b.
 * @return long long    Greatest common divisor of a and b.
 */
static long long gcd(long long a, long long b)
{
  while(a != 0)
  {
    long long tmp = a;
    a = b % a;
    b = tmp;
  }
  return llabs(b);
}


/**
 * @brief Simplify rational number.
 *
 * Divide numerator a and denominator b by gcd(a,b).
 *
 * @param a     Numerator.
 * @param b     Denominator.
 */
static void simplifyRat(long *a, long *b)
{
  long tmp = gcd(*a, *b);
  if(tmp != 0)
  {
    *a /= tmp;
    *b /= tmp;
  }
}


/**
 * @brief Add an integer to a rational number.
 *
 * a + m/n
 *
 * @param integer       Integer number.
 * @param rational      Rational number.
 * @return RATIONAL     Result of addition.
 */
RATIONAL addInt2Rat(long integer, RATIONAL rational) {
  long long m = (long long)integer * rational.n + rational.m;
  long long n = rational.n;
  return makeRATIONAL(m, n);
}


/**
 * @brief Substract integer from rational number.
 *
 * a - m/n
 *
 * @param integer       Integer number.
 * @param rational      Rational number.
 * @return RATIONAL     Result of substraction.
 */
RATIONAL subInt2Rat(long integer, RATIONAL rational) {
  long long m = (long long)integer * rational.n - rational.m;
  long long n = rational.n;
  return makeRATIONAL(m, n);
}


/**
 * @brief Multiplication of integer with rational number.
 *
 * a * (m/n).
 *
 * @param integer       Integer number.
 * @param rational      Rational number.
 * @return RATIONAL     Result of multiplication.
 */
RATIONAL multInt2Rat(long integer, RATIONAL rational) {
  long long m = (long long)integer * rational.m;
  long long n = rational.n;
  return makeRATIONAL(m, n);
}


/**
 * @brief Addition of two rational numbers.
 *
 * a/b + c/d = (ad+bc)/(bd)
 *
 * @param a           First rational number.
 * @param b           Second rational number.
 * @return RATIONAL   Result of addition.
 */
RATIONAL addRat2Rat(RATIONAL a, RATIONAL b) {
  long long m = (long long)a.m * b.n + (long long)b.m * a.n;
  long long n = (long long)a.n * b.n;
  return makeRATIONAL(m, n);
}


/**
 * @brief Multiplication of two rational numbers.
 *
 * a/b * c/d = (ac)/(bd)
 *
 * @param a           First rational number.
 * @param b           Second rational number.
 * @return RATIONAL   Result of multiplication.
 */
RATIONAL multRat2Rat(RATIONAL a, RATIONAL b) {
  long long m = (long long)a.m * b.m;
  long long n = (long long)a.n * b.n;
  return makeRATIONAL(m, n);
}


/**
 * @brief Division of two rational numers.
 * A.k.a multiplication with multiplicative inverse.
 *
 * (a/b) / (c/d) = a/b * d/c = (ad)/(bc)
 * b,c and d must be non-zero.
 *
 * @param a           First rational number.
 * @param b           Second rational number.
 * @return RATIONAL   Result of division.
 */
RATIONAL divRat2Rat(RATIONAL a, RATIONAL b) {
  assert(a.n != 0);
  assert(b.m != 0);
  assert(b.n != 0);
  long long m = (long long)a.m * b.n;
  long long n = (long long)a.n * b.m;
  return makeRATIONAL(m, n);
}


/**
 * @brief Get real approximation of rational number.
 *
 * @param a         Rational number.
 * @return double   Real approximation.
 */
double rat2Real(RATIONAL a) {
  assertStreamPrint(NULL, a.n != 0, "Invalid rational number %li/%li", a.m, a.n);
  return (double)a.m / a.n;
}


/**
 * @brief Ceil rational number.
 *
 * Return minimum integer a, for which a >= m / n
 *
 * @param a           Rational number.
 * @return long       Smallest integer number greater or equal rational number.
 */
long ceilRat(RATIONAL a) {
  long k = a.m / a.n;
  return k + (a.m > 0 && a.m % a.n ? 1 : 0);
}


/**
 * @brief Strict ceil rational number.
 *
 * Return minimum integer a, for which a > m / n
 *
 * @param a           Rational number.
 * @return long       Smallest integer number greater rational number.
 */
long ceilRatStrict(RATIONAL a) {
  long k = a.m / a.n;
  return k + (a.m <= 0 && a.m % a.n ? 0 : 1);
}


/**
 * @brief Floor rational number
 *
 * Return maximum a, for which a <= m / n
 *
 * @param a           Rational number.
 * @return long       Biggest integer number smaller or equal to rational number.
 */
long floorRat(RATIONAL a) {
  long k = a.m / a.n;
  return k - (a.m < 0 && a.m % a.n ? 1 : 0);
}


/**
 * @brief Strict floor rational number.
 *
 * Return maximum a, for which a < m / n
 *
 * @param a           Rational number.
 * @return long       Biggest integer number smaller then rational number.
 */
long floorRatStrict(RATIONAL a) {
  long k = a.m / a.n;
  return k - (a.m >= 0 && a.m % a.n ? 0 : 1);
}
