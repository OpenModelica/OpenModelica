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

#include "rational.h"
#include "omc_msvc.h"
#include "omc_error.h"
#include <assert.h>
#include <stdlib.h>
#include <limits.h>


/*
 * Rational arithmetic is particularly prone to overflow because numerator
 * and/or denominator can grow quickly during computations. Therefore overflow
 * is checked during critical steps in the calculations below.
 */
#if defined __has_builtin
#if __has_builtin(__builtin_add_overflow)
#define RAT_INT_ADD(a, b, c, op) \
  assertStreamPrint(NULL, !__builtin_add_overflow((a), (b), &(c)), \
    "RATIONAL overflow. Unable to store result of " \
    "("RAT_FMT"/"RAT_FMT") %c ("RAT_FMT"/"RAT_FMT")", \
    r1.num, r1.den, op, r2.num, r2.den)
#define RAT_INT_MUL(a, b, c, op) \
  assertStreamPrint(NULL, !__builtin_mul_overflow((a), (b), &(c)), \
    "RATIONAL overflow. Unable to store result of " \
    "("RAT_FMT"/"RAT_FMT") %c ("RAT_FMT"/"RAT_FMT")", \
    r1.num, r1.den, op, r2.num, r2.den)
#endif
#endif

#if !(defined RAT_INT_ADD) /* no overflow checks available */
#define RAT_INT_ADD(a, b, c, op) (c) = (a) + (b)
#define RAT_INT_MUL(a, b, c, op) (c) = (a) * (b)
#endif


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
static rat_int_t gcd(rat_int_t a, rat_int_t b)
{
  while(a != 0) {
    rat_int_t tmp = a;
    a = b % a;
    b = tmp;
  }
  return RAT_INT_ABS(b);
}


/**
 * @brief Simplify rational number.
 *
 * Divide numerator a and denominator b by gcd(a,b).
 *
 * @param a     Numerator.
 * @param b     Denominator.
 */
static void simplifyRat(rat_int_t *a, rat_int_t *b)
{
  rat_int_t tmp = gcd(*a, *b);
  if(tmp != 0) {
    *a /= tmp;
    *b /= tmp;
  }
}


/**
 * @brief Create rational number from numerator and denominator.
 *
 * Asserts denominator is non-zero and simplifies rational.
 *
 * @param numerator
 * @param denominator
 * @return RATIONAL   numerator/denominator
 */
RATIONAL makeRATIONAL(rat_int_t numerator, rat_int_t denominator)
{
  assertStreamPrint(NULL, denominator != 0, "RATIONAL zero denominator.");
  simplifyRat(&numerator, &denominator);
  if(denominator < 0) {
    assertStreamPrint(NULL, numerator != RAT_INT_MIN, "RATIONAL numerator overflow.");
    assertStreamPrint(NULL, denominator != RAT_INT_MIN, "RATIONAL denominator overflow.");
    return (RATIONAL){-numerator, -denominator};
  }
  return (RATIONAL){numerator, denominator};
}


/**
 * @brief Addition of two rational numbers.
 *
 * a/b + c/d = (ad+bc)/(bd) = (a(d/g)+(b/g)c)/((b/g)d)
 *
 * @param r1          First rational number.
 * @param r2          Second rational number.
 * @return RATIONAL   Sum of r1 and r2.
 */
RATIONAL addRat(RATIONAL r1, RATIONAL r2)
{
  rat_int_t num, den;
  rat_int_t g = gcd(r1.den, r2.den);
  rat_int_t num1 = r2.den/g;
  rat_int_t num2 = r1.den/g;
  RAT_INT_MUL(num2, r2.den, den, '+');   /* den = (r1.den/g)*r2.den */
  RAT_INT_MUL(num1, r1.num, num1, '+');  /* num1 *= r1.num */
  RAT_INT_MUL(num2, r2.num, num2, '+');  /* num2 *= r2.num */
  RAT_INT_ADD(num1, num2, num, '+');     /* num = num1 + num2 */
  simplifyRat(&num, &den);
  return (RATIONAL){num, den};
}


/**
 * @brief Negation of a rational number.
 *
 * -(a/b) = (-a)/b
 *
 * @param r           Rational number.
 * @return RATIONAL   Negative of r.
 */
RATIONAL negRat(RATIONAL r)
{
  assertStreamPrint(NULL, r.num != RAT_INT_MIN,
    "RATIONAL overflow. Unable to store result of -("RAT_FMT"/"RAT_FMT")",
    r.num, r.den);
  return (RATIONAL){-r.num, r.den};
}


/**
 * @brief Subtraction of two rational numbers.
 *
 * a - b = a + (-b)
 *
 * @param r1          First rational number.
 * @param r2          Second rational number.
 * @return RATIONAL   Difference of r1 and r2.
 */
RATIONAL subRat(RATIONAL r1, RATIONAL r2) {
  return addRat(r1, negRat(r2));
}


/**
 * @brief Multiplication of two rational numbers.
 *
 * a/b * c/d = (ac)/(bd)
 *
 * @param r1          First rational number.
 * @param r2          Second rational number.
 * @return RATIONAL   Product of r1 and r2.
 */
RATIONAL mulRat(RATIONAL r1, RATIONAL r2)
{
  rat_int_t num, den;
  rat_int_t g1 = gcd(r1.num, r2.den);
  rat_int_t g2 = gcd(r2.num, r1.den);
  RAT_INT_MUL(r1.num/g1, r2.num/g2, num, '*');  /* num = (a/g1)*(c/g2) */
  RAT_INT_MUL(r1.den/g2, r2.den/g1, den, '*');  /* den = (b/g2)*(d/g1) */
  return (RATIONAL){num, den};
}


/**
 * @brief Reciprocal of a rational number.
 *
 * (a/b)^(-1) = b/a
 *
 * @param r           Rational number.
 * @return RATIONAL   Reciprocal of r.
 */
RATIONAL invRat(RATIONAL r)
{
  assertStreamPrint(NULL, r.num != 0, "RATIONAL division by zero.");
  if(r.num < 0) {
    assertStreamPrint(NULL, r.num != RAT_INT_MIN,
      "RATIONAL overflow. Unable to store result of ("RAT_FMT"/"RAT_FMT")^(-1)",
      r.num, r.den);
    return (RATIONAL){-r.den, -r.num};
  }
  return (RATIONAL){r.den, r.num};
}


/**
 * @brief Division of two rational numers.
 * A.k.a multiplication with multiplicative inverse.
 *
 * (a/b) / (c/d) = a/b * d/c = (ad)/(bc)
 *
 * @param r1          First rational number.
 * @param r2          Second rational number.
 * @return RATIONAL   Quotient of r1 and r2.
 */
RATIONAL divRat(RATIONAL r1, RATIONAL r2) {
  return mulRat(r1, invRat(r2));
}


/**
 * @brief Get real approximation of rational number.
 *
 * @param a         Rational number.
 * @return double   Real approximation.
 */
double rat2Real(RATIONAL a) {
  return (double)a.num / a.den;
}


/**
 * @brief Convert integer to rational number.
 *
 * @param n          Integer
 * @return RATIONAL  Rational representation of n.
 */
RATIONAL int2Rat(rat_int_t n) {
  return (RATIONAL){n, 1};
}


/**
 * @brief Ceil rational number.
 *
 * Return minimum integer a, for which a >= m / n
 *
 * @param a           Rational number.
 * @return long       Smallest integer number greater or equal rational number.
 */
rat_int_t ceilRat(RATIONAL a) {
  return a.num / a.den + (a.num > 0 && a.num % a.den ? 1 : 0);
}


/**
 * @brief Strict ceil rational number.
 *
 * Return minimum integer a, for which a > m / n
 *
 * @param a           Rational number.
 * @return long       Smallest integer number greater rational number.
 */
rat_int_t ceilRatStrict(RATIONAL a) {
  return a.num / a.den + (a.num < 0 && a.num % a.den ? 0 : 1);
}


/**
 * @brief Floor rational number
 *
 * Return maximum a, for which a <= m / n
 *
 * @param a           Rational number.
 * @return long       Biggest integer number smaller or equal to rational number.
 */
rat_int_t floorRat(RATIONAL a) {
  return a.num / a.den - (a.num < 0 && a.num % a.den ? 1 : 0);
}


/**
 * @brief Strict floor rational number.
 *
 * Return maximum a, for which a < m / n
 *
 * @param a           Rational number.
 * @return long       Biggest integer number smaller then rational number.
 */
rat_int_t floorRatStrict(RATIONAL a) {
  return a.num / a.den - (a.num > 0 && a.num % a.den ? 0 : 1);
}
