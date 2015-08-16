/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package MMath
" file:        MMath.mo
  package:     MMath
  description: Rational numbers and operations
  @author:     Peter Aronsson (peter.aronsson@mathcore.com)

  $Id$
"
public
uniontype Rational
record RATIONAL "represents a rational number, e.g. 6/7"
   Integer nom "numerator";
   Integer denom "denominator";
  end RATIONAL;
end Rational;

public constant Rational RAT0 = RATIONAL(0, 1);
public constant Rational RAT1 = RATIONAL(1, 1);

public function addRational "adds two rationals"
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := match(r1,r2)
  local Integer i1,i2,i3,i4,ri1,ri2,d;
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 = i1*i4 + i3*i2;
      ri2 = i2*i4;
      d = intGcd(ri1,ri2);
      ri1 = intDiv(ri1, d);
      ri2 = intDiv(ri2, d);
    then normalizeZero(RATIONAL(ri1,ri2));
  end match;
end addRational;

protected function normalizeZero "if numerator is zero, set denominator to 1"
  input Rational r;
  output Rational outR;
algorithm
  outR := match(r)
    case(RATIONAL(0,_)) then RATIONAL(0,1);
    else r;
  end match;
end normalizeZero;

public function rationalString "converts a rational to a string"
input Rational r;
output String str;
algorithm
  str := match(r)
  local Integer n,d;
    case(RATIONAL(n,d)) equation
      str = intString(n)+"/"+intString(d);
    then str;
  end match;
end rationalString;

public function equals
  input Rational r1;
  input Rational r2;
  output Boolean res;
algorithm
  res := match (r1, r2)
    local
      Integer i1, i2, i3, i4;
    case (RATIONAL(i1,i2), RATIONAL(i3,i4))
      then i1*i4 - i3*i2 == 0;
  end match;
end equals;

public function subRational "subtracts two rationals"
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := match(r1,r2)
  local Integer i1,i2,i3,i4,ri1,ri2,d;
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 =  i1*i4 - i3*i2;
      ri2 = i2*i4;
      d = intGcd(ri1,ri2);
      ri1 = intDiv(ri1, d);
      ri2 = intDiv(ri2, d);
    then normalizeZero(RATIONAL(ri1,ri2));
  end match;
end subRational;

public function multRational "multiply two rationals"
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := match(r1,r2)
    local Integer i1,i2,i3,i4,ri1,ri2,d;
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 = i1*i3;
      ri2 = i2*i4;
      d = intGcd(ri1,ri2);
      ri1 = intDiv(ri1,d);
      ri2 = intDiv(ri2,d);
   then normalizeZero(RATIONAL(ri1,ri2));
  end match;
end multRational;

public function divRational "division of two rationals i1/i2 / i3/i4 = (i1*i4) / (i3*i2) "
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := match(r1,r2)
  local Integer i1,i2,i3,i4,ri1,ri2,d;
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 = i1*i4;
      ri2 = i3*i2;
      d = intGcd(ri1,ri2);
      ri1 = intDiv(ri1, d);
      ri2 = intDiv(ri2, d);
   then normalizeZero(RATIONAL(ri1,ri2));
  end match;
end divRational;

public function intGcd "returns the greatest common divisor for two Integers"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := matchcontinue(i1,i2)
    case (_,0) then i1;
    else intGcd(i2,intMod(i1,i2));
  end matchcontinue;
end intGcd;

/* Tests */

public function testRational "test rational operators"
algorithm
  _ := matchcontinue()

    case() equation
      RATIONAL(7,6) =  addRational(RATIONAL(1,2),RATIONAL(2,3));
      RATIONAL(2,1) = addRational(RATIONAL(1,2),RATIONAL(3,2));

      RATIONAL(1,1) = subRational(RATIONAL(3,2),RATIONAL(1,2));
      RATIONAL(1,3) = subRational(RATIONAL(1,2),RATIONAL(1,6));

      RATIONAL(4,3) = multRational(RATIONAL(2,3),RATIONAL(4,2));
      RATIONAL(1,1) = multRational(RATIONAL(1,1),RATIONAL(1,1));

      RATIONAL(1,2) = divRational(RATIONAL(1,3),RATIONAL(2,3));
      print("testRational succeeded\n");
    then ();
    else equation
      print("testRationals failed\n");
    then ();

  end matchcontinue;
end testRational;

annotation(__OpenModelica_Interface="frontend");
end MMath;
