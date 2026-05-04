/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype Rational

protected
  import Util;

public
  record RATIONAL
    Integer n "numerator";
    Integer d "denominator";
  end RATIONAL;

  // constant Rational ZERO = RATIONAL(0, 1);
  // constant Rational ONE = RATIONAL(1, 1);

  function isEqual
    input Rational r1;
    input Rational r2;
    output Boolean b = r1.n == r2.n and r1.d == r2.d;
  end isEqual;

  function compare "Compares two rationals and return -1 if the first is smallest, 1 if the second is smallest, or 0 if they are equal."
    input Rational r1;
    input Rational r2;
    output Integer i;
  protected
    // Divide by common divisors to avoid overflow
    Integer gn = Util.gcd(r1.n, r2.n);
    Integer gd = Util.gcd(r1.d, r2.d);
  algorithm
    i := Util.intCompare(intDiv(r1.n, gn)*intDiv(r2.d, gd), intDiv(r2.n, gn)*intDiv(r1.d, gd));
  end compare;

  function toString
    input Rational r;
    output String str = intString(r.n) + "/" + intString(r.d);
  end toString;

  function normalize
    input output Rational r;
  algorithm
    if r.n == 0 then
      r.d := 1;
    elseif r.d < 0 then
      r := RATIONAL(-r.n, -r.d);
    end if;
  end normalize;

  function add "a/b + c/d = (ad + bc)/(bd) = (a(d/g) + (b/g)c)/((b/g)d)"
    input Rational r1;
    input Rational r2;
    output Rational r;
  protected
    Integer g = Util.gcd(r1.d, r2.d);
  algorithm
    r := reduce(r1.n*intDiv(r2.d, g) + intDiv(r1.d, g)*r2.n, intDiv(r1.d,g)*r2.d);
  end add;

  function neg "-(a/b) = (-a)/b"
    input Rational r;
    output Rational s = RATIONAL(-r.n, r.d);
  end neg;

  function sub "a/b - c/d = (ad - bc)/(bd) = (a(d/g) - (b/g)c)/((b/g)d)"
    input Rational r1;
    input Rational r2;
    output Rational r;
  protected
    Integer g = Util.gcd(r1.d, r2.d);
  algorithm
    r := reduce(r1.n*intDiv(r2.d, g) - intDiv(r1.d, g)*r2.n, intDiv(r1.d,g)*r2.d);
  end sub;

  function mul "a/b * c/d = (ac)/(bd) = ((a/g1)(c/g2))/((b/g2)(d/g1))"
    input Rational r1;
    input Rational r2;
    output Rational r;
  protected
    Integer g1 = Util.gcd(r1.n, r2.d);
    Integer g2 = Util.gcd(r2.n, r1.d);
  algorithm
    r := reduce(intDiv(r1.n, g1)*intDiv(r2.n, g2), intDiv(r1.d, g2)*intDiv(r2.d, g1));
  end mul;

  function inv "(a/b)^(-1) = b/a"
    input Rational r;
    output Rational s = RATIONAL(Util.intSign(r.n)*r.d, intAbs(r.n));
  end inv;

  function div "(a/b) / (c/d) = (ad)/(bc) = ((a/g1)(d/g2))/((b/g2)(c/g1))"
    input Rational r1;
    input Rational r2;
    output Rational r;
  protected
    Integer g1 = Util.gcd(r1.n, r2.n);
    Integer g2 = Util.gcd(r2.d, r1.d);
  algorithm
    r := reduce(intDiv(r1.n, g1)*intDiv(r2.d, g2), intDiv(r1.d, g2)*intDiv(r2.n, g1));
  end div;

protected
  function reduce
    input Integer i1;
    input Integer i2;
    output Rational r;
  protected
    Integer d = Util.gcd(i1, i2);
  algorithm
    r := normalize(RATIONAL(intDiv(i1, d), intDiv(i2, d)));
  end reduce;
  annotation(__OpenModelica_Interface="util");
end Rational;
