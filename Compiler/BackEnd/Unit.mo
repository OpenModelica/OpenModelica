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

encapsulated package Unit
" file:        Unit.mo
  package:     Unit
  description: This package defines the type Unit, which represents a unit based
               on SI base units, and some auxiliary functions therefore.

               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)"

public
import DAE;
import HashTableStringToUnit;
import HashTableUnitToString;
import System;

protected
import ComponentReference;
import Error;
import Util;


public uniontype Unit
  record UNIT "based on SI base units"
    Real factor "prefix";
    Integer mol "exponent";
    Integer cd  "exponent";
    Integer m   "exponent";
    Integer s   "exponent";
    Integer A   "exponent";
    Integer K   "exponent";
    Integer g   "exponent";
    //Real K_shift;
  end UNIT;

  record MASTER "unknown unit that belongs to all the variables from varList"
    list<DAE.ComponentRef> varList;
  end MASTER;

  record UNKNOWN "unknown SI base unit decomposition"
    String unit;
  end UNKNOWN;
end Unit;

protected uniontype Token
  record T_NUMBER
    Integer number;
  end T_NUMBER;

  record T_UNIT
    String unit;
  end T_UNIT;

  record T_MUL end T_MUL;
  record T_DIV end T_DIV;
  record T_LPAREN end T_LPAREN;
  record T_RPAREN end T_RPAREN;
end Token;

public constant DAE.ComponentRef UPDATECREF = DAE.CREF_IDENT("jhagemann", DAE.T_REAL_DEFAULT, {});

public constant list<tuple<String, Unit>> LU_COMPLEXUNITS = {
/*                   fac,mol,cd, m, s, A, K, g*/
  ("mol",        UNIT(1e0, 1, 0, 0, 0, 0, 0, 0)), //Mol
  ("cd",         UNIT(1e0, 0, 1, 0, 0, 0, 0, 0)), //Candela
  ("m",          UNIT(1e0, 0, 0, 1, 0, 0, 0, 0)), //Meter
  ("s",          UNIT(1e0, 0, 0, 0, 1, 0, 0, 0)), //Sekunde
  ("A",          UNIT(1e0, 0, 0, 0, 0, 1, 0, 0)), //Ampere
  ("K",          UNIT(1e0, 0, 0, 0, 0, 0, 1, 0)), //Kelvin
  ("g",          UNIT(1e0, 0, 0, 0, 0, 0, 0, 1)), //Gramm
  ("V",          UNIT(1e3, 0, 0, 2,-3,-1, 0, 1)), //Volt
  ("W",          UNIT(1e3, 0, 0, 2,-3, 0, 0, 1)), //Watt
//("VA",         UNIT(1e3, 0, 0, 2,-3, 0, 0, 1)), //Voltampere=Watt
//("var",        UNIT(1e3, 0, 0, 2,-3, 0, 0, 1)), //Var=Watt
  ("Hz",         UNIT(1e0, 0, 0, 0,-1, 0, 0, 0)), //Hertz
  ("Ohm",        UNIT(1e3, 0, 0, 2,-3,-2, 0, 1)), //Ohm
  ("F",         UNIT(1e-3, 0, 0,-2, 4, 2, 0,-1)), //Farad
  ("H",          UNIT(1e3, 0, 0, 2,-2,-2, 0, 1)), //Henry
  ("C",          UNIT(1e0, 0, 0, 0, 1, 1, 0, 0)), //Coulomb
  ("T",          UNIT(1e3, 0, 0, 0,-2,-1, 0, 1)), //Tesla
  ("S",         UNIT(1e-3, 0, 0,-2, 3, 2, 0,-1)), //Siemens
  ("Wb",         UNIT(1e3, 0, 0, 2,-2,-1, 0, 1)), //Weber
//("lm",         UNIT(1e0, 0, 1, 0, 0, 0, 0, 0)), //Lumen=Candela
//("lx",         UNIT(1e0, 0, 1,-2, 0, 0, 0, 0)), //Lux=lm/m^2
  ("N",          UNIT(1e3, 0, 0, 1,-2, 0, 0, 1)), //Newton
  ("Pa",         UNIT(1e3, 0, 0,-1,-2, 0, 0, 1)), //Pascal; displayUnit ="bar"
  ("J",          UNIT(1e3, 0, 0, 2,-2, 0, 0, 1)), //Joule=N*m
  ("min",        UNIT(6e1, 0, 0, 0, 1, 0, 0, 0)), //Minute
  ("h",        UNIT(3.6e3, 0, 0, 0, 1, 0, 0, 0)), //Stunde
  ("d",       UNIT(8.64e4, 0, 0, 0, 1, 0, 0, 0)), //Tag
  ("l",         UNIT(1e-3, 0, 0, 3, 0, 0, 0, 0)), //Liter
  ("kg",         UNIT(1e3, 0, 0, 0, 0, 0, 0, 1)), //Kilogramm
//("Bq",         UNIT(1e0, 0, 0, 0,-1, 0, 0, 0)), //Becquerel = Hertz
//("Gy",         UNIT(1e0, 0, 0, 2,-2, 0, 0, 1)), //Gray
//("Sv",         UNIT(1e0, 0, 0, 2,-2, 0, 0, 1)), //Sievert=Gray
//("eV", UNIT(1.60218e-16, 0, 0, 2,-2, 0, 0, 1)), //Elektronenvolt    1, 602...*10^-19 kg*m^2/s^2
//("R",      UNIT(2.58e-7, 0, 0, 0, 1, 1, 0,-1)), //Röntgen    2, 58*10^-4 C/kg
  ("kat",        UNIT(1e0, 1, 0, 0,-1, 0, 0, 0)), //Katal
  ("1",          UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)), //1
  ("rad",        UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)), //rad; displayUnit ="deg"
//("B",         UNIT(1e-2, 0, 0, 0, 0, 0, 0, 0)), //Bel (dezibel dB)
//("phon",       UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)), //Phon
//("sone",       UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)), //Sone
//("sr",         UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)), //Steradiant=m^2/m^2
  ("degC",       UNIT(1e0, 0, 0, 0, 0, 0, 1, 0)), //°Celsius
  ("degF", UNIT(0.55555555555555555555555555555555555555, 0, 0, 0, 0, 0, 1, 0))};//°Fahrenheit
//("degF", UNIT(5.0 / 9.0, 0, 0, 0, 0, 0, 1, 0, 459.67)), //°Fahrenheit
//("degC",       UNIT(1e0, 0, 0, 0, 0, 0, 1, 0, 273.15))};//°Celsius
/*                 fac, mol, cd, m, s, A, K, g*/

public function getKnownUnits
  output HashTableStringToUnit.HashTable outKnownUnits;
algorithm
  outKnownUnits := HashTableStringToUnit.emptyHashTableSized(Util.nextPrime(4 * listLength(LU_COMPLEXUNITS)));

  for unit in LU_COMPLEXUNITS loop
    outKnownUnits := BaseHashTable.add(unit, outKnownUnits);
  end for;
end getKnownUnits;

public function getKnownUnitsInverse
  output HashTableUnitToString.HashTable outKnownUnitsInverse;
protected
  String s;
  Unit ut;
algorithm
  outKnownUnitsInverse := HashTableUnitToString.emptyHashTableSized(Util.nextPrime(4 * listLength(LU_COMPLEXUNITS)));

  for unit in LU_COMPLEXUNITS loop
    (s, ut) := unit;

    if not BaseHashTable.hasKey(ut, outKnownUnitsInverse) then
      outKnownUnitsInverse := BaseHashTable.add((ut, s), outKnownUnitsInverse);
    end if;
  end for;
end getKnownUnitsInverse;

public function isUnit
  input Unit inUnit;
  output Boolean b;
algorithm
  b := match inUnit
    case UNIT() then true;
    else false;
  end match;
end isUnit;

public function hashUnitMod
  input Unit inKey;
  input Integer inMod;
  output Integer outHash;
protected
  String str;
algorithm
  str := unit2string(inKey);
  outHash := stringHashDjb2Mod(str, inMod);
end hashUnitMod;

public function unitEqual
  input Unit inKey;
  input Unit inKey2;
  output Boolean res;
algorithm
  res := matchcontinue(inKey, inKey2)
    local
      Real factor1, factor2, r;
      Integer i1, i2, i3, i4, i5, i6, i7;
      Integer j1, j2, j3, j4, j5, j6, j7;
      String s, s2;
      list<DAE.ComponentRef> lcr, lcr2;

    case (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), UNIT(factor2, j1, j2, j3, j4, j5, j6, j7)) equation
      true = realEq(factor1, factor2);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then true;

    case (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), UNIT(factor2, j1, j2, j3, j4, j5, j6, j7)) equation
      r = realMax(realAbs(factor1), realAbs(factor2));
      true = realLe(realDiv(realAbs(realSub(factor1,factor2)),r),1e-3);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then true;

    case (MASTER(), MASTER()) //equation
      // lcr comparison????
    then true;

    case (UNKNOWN(s), UNKNOWN(s2)) equation
      true = stringEqual(s, s2);
    then true;

    else false;
  end matchcontinue;
end unitEqual;

public function unit2string
  input Unit inUnit;
  output String outString;
algorithm
  outString := match(inUnit)
    local
      String s, str;
      Boolean b;
      list<DAE.ComponentRef> crefList;
      Real factor1;
      Integer i1, i2, i3, i4, i5, i6, i7;

    case UNIT(factor1, i1, i2, i3, i4, i5, i6, i7/* , shift1 */) equation
      str = realString(factor1) + " * ";

      b = false;
      s = "mol^(" + intString(i1) + ")";
      s = if intEq(i1, 0) then "" else s;
      b = b or intNe(i1, 0);
      str = str + s;

      s = if b and intNe(i2, 0) then " * " else "";
      str = str + s;
      s = "cd^(" + intString(i2) + ")";
      s = if intEq(i2, 0) then "" else s;
      b = b or intNe(i2, 0);
      str = str + s;

      s = if b and intNe(i3, 0) then " * " else "";
      str = str + s;
      s = "m^(" + intString(i3) + ")";
      s = if intEq(i3, 0) then "" else s;
      b = b or intNe(i3, 0);
      str = str + s;

      s = if b and intNe(i4, 0) then " * " else "";
      str = str + s;
      s = "s^(" + intString(i4) + ")";
      s = if intEq(i4, 0) then "" else s;
      b = b or intNe(i4, 0);
      str = str + s;

      s = if b and intNe(i5, 0) then " * " else "";
      str = str + s;
      s = "A^(" + intString(i5) + ")";
      s = if intEq(i5, 0) then "" else s;
      b = b or intNe(i5, 0);
      str = str + s;

      s = if b and intNe(i6, 0) then " * " else "";
      str = str + s;
      //s = "(K-" + realString(shift1) + ")^(" + intString(i6) + ")";
      s = "K^(" + intString(i6) + ")";
      s = if intEq(i6, 0) then "" else s;
      b = b or intNe(i6, 0);
      str = str + s;

      s = if b and intNe(i7, 0) then " * " else "";
      str = str + s;
      s = "g^(" + intString(i7) + ")";
      s = if intEq(i7, 0) then "" else s;
      b = b or intNe(i7, 0);
      str = str + s;

      s = if b then "" else "1";
      str = str + s;
    then str;

    case MASTER(crefList) equation
      str = "MASTER(";
      str = str + printListCr(crefList);
      str = str + ")";
    then str;

    case UNKNOWN(s) equation
      str = "UNKOWN(" + s + ")";
    then str;
  end match;
end unit2string;

public function printListCr
 input list<DAE.ComponentRef> inlCr;
 output String outS;
algorithm
  outS := match(inlCr)

  local
    list<DAE.ComponentRef> lCr;
    DAE.ComponentRef cr;
    String s;

    case {} then "";

    case cr::{} equation
      s = ComponentReference.crefStr(cr);
    then s;

    case cr::lCr equation
      s = ComponentReference.crefStr(cr);
      s = s + ", " + printListCr(lCr);
    then s;

  end match;
end printListCr;

public function unitMul
  input Unit inUnit1;
  input Unit inUnit2;
  output Unit outUnit;
protected
  Real factor1, factor2;
  Integer i1, i2, i3, i4, i5, i6, i7;
  Integer j1, j2, j3, j4, j5, j6, j7;
algorithm
  UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) := inUnit1;
  UNIT(factor2, j1, j2, j3, j4, j5, j6, j7) := inUnit2;
  factor1 := factor1 * factor2;
  i1 := i1+j1;
  i2 := i2+j2;
  i3 := i3+j3;
  i4 := i4+j4;
  i5 := i5+j5;
  i6 := i6+j6;
  i7 := i7+j7;
  outUnit := UNIT(factor1, i1, i2, i3, i4, i5, i6, i7);
end unitMul;

public function unitDiv
  input Unit inUnit1;
  input Unit inUnit2;
  output Unit outUnit;
protected
  Real factor1, factor2;
  Integer i1, i2, i3, i4, i5, i6, i7;
  Integer j1, j2, j3, j4, j5, j6, j7;
algorithm
  UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) := inUnit1;
  UNIT(factor2, j1, j2, j3, j4, j5, j6, j7) := inUnit2;
  factor1 := factor1 / factor2;
  i1 := i1-j1;
  i2 := i2-j2;
  i3 := i3-j3;
  i4 := i4-j4;
  i5 := i5-j5;
  i6 := i6-j6;
  i7 := i7-j7;
  outUnit := UNIT(factor1, i1, i2, i3, i4, i5, i6, i7);
end unitDiv;

public function unitPow
  input Unit inUnit;
  input Integer inExp "exponent";
  output Unit outUnit;
protected
  Real factor;
  Integer i1, i2, i3, i4, i5, i6, i7;
algorithm
  UNIT(factor, i1, i2, i3, i4, i5, i6, i7) := inUnit;
  factor := realPow(factor, intReal(inExp));
  i1 := i1*inExp;
  i2 := i2*inExp;
  i3 := i3*inExp;
  i4 := i4*inExp;
  i5 := i5*inExp;
  i6 := i6*inExp;
  i7 := i7*inExp;
  outUnit := UNIT(factor, i1, i2, i3, i4, i5, i6, i7);
end unitPow;

public function unitMulReal
  input Unit inUnit;
  input Real inFactor;
  output Unit outUnit;
algorithm
  outUnit := match(inUnit)
    local
      Unit unit;

    case unit as UNIT() equation
      unit.factor = unit.factor * inFactor;
    then unit;

    else fail();
  end match;
end unitMulReal;

public function unitRoot
  input Unit inUnit;
  input Real inExponent;
  output Unit outUnit;
protected
  Real r, factor;
  Integer i, i1, i2, i3, i4, i5, i6, i7;
algorithm
  i := realInt(inExponent);
  r := realDiv(1.0, inExponent);
  UNIT(factor, i1, i2, i3, i4, i5, i6, i7) := inUnit;
  factor := realPow(factor, r);

  r := realDiv(intReal(i1),inExponent);
  i1 := intDiv(i1, i);
  true := realEq(r, intReal(i1));

  r := realDiv(intReal(i2),inExponent);
  i2 := intDiv(i2, i);
  true := realEq(r, intReal(i2));

  r := realDiv(intReal(i3),inExponent);
  i3 := intDiv(i3, i);
  true := realEq(r, intReal(i3));

  r := realDiv(intReal(i4),inExponent);
  i4 := intDiv(i4, i);
  true := realEq(r, intReal(i4));

  r := realDiv(intReal(i5),inExponent);
  i5 := intDiv(i5, i);
  true := realEq(r, intReal(i5));

  r := realDiv(intReal(i6),inExponent);
  i6 := intDiv(i6, i);
  true := realEq(r, intReal(i6));

  r := realDiv(intReal(i7),inExponent);
  i7 := intDiv(i7, i);
  true := realEq(r, intReal(i7));

  outUnit := UNIT(factor, i1, i2, i3, i4, i5, i6, i7);
end unitRoot;

public function unitString "Unit to Modelica unit string"
  input Unit inUnit;
  input HashTableUnitToString.HashTable inHtU2S = getKnownUnitsInverse();
  output String outString;
algorithm
  outString := match(inUnit)
    local
      String s, s1, s2, s3, s4, s5, s6, s7, sExponent;
      Boolean b;
      Unit unit;

    case _ guard BaseHashTable.hasKey(inUnit, inHtU2S) equation
      s = BaseHashTable.get(inUnit, inHtU2S);
    then s;

    case unit as UNIT() equation
      s = prefix2String(unit.factor);

      s = if realEq(unit.factor, 1.0) then "" else s;
      b = false;
      sExponent = if intEq(unit.mol, 1) then "" else intString(unit.mol);
      s1 = "mol" + sExponent;
      s1 = if intEq(unit.mol, 0) then "" else s1;
      b = b or intNe(unit.mol, 0);

      s2 = if b and intNe(unit.cd, 0) then "." else "";
      sExponent = if intEq(unit.cd, 1) then "" else intString(unit.cd);
      s2 = s2 + "cd" + sExponent;
      s2 = if intEq(unit.cd, 0) then "" else s2;
      b = b or intNe(unit.cd, 0);

      s3 = if b and intNe(unit.m, 0) then "." else "";
      sExponent = if intEq(unit.m, 1) then "" else intString(unit.m);
      s3 = s3 + "m" + sExponent;
      s3 = if intEq(unit.m, 0) then "" else s3;
      b = b or intNe(unit.m, 0);

      s4 = if b and intNe(unit.s, 0) then "." else "";
      sExponent = if intEq(unit.s, 1) then "" else intString(unit.s);
      s4 = s4 + "s" + sExponent;
      s4 = if intEq(unit.s, 0) then "" else s4;
      b = b or intNe(unit.s, 0);

      s5 = if b and intNe(unit.A, 0) then "." else "";
      sExponent = if intEq(unit.A, 1) then "" else intString(unit.A);
      s5 = s5 + "A" + sExponent;
      s5 = if intEq(unit.A, 0) then "" else s5;
      b = b or intNe(unit.A, 0);

      s6 = if b and intNe(unit.K, 0) then "." else "";
      sExponent = if intEq(unit.K, 1) then "" else intString(unit.K);
      s6 = s6 + "K" + sExponent;
      s6 = if intEq(unit.K, 0) then "" else s6;
      b = b or intNe(unit.K, 0);

      s7 = if b and intNe(unit.g, 0) then "." else "";
      sExponent = if intEq(unit.g, 1) then "" else intString(unit.g);
      s7 = s7 + "g" + sExponent;
      s7 = if intEq(unit.g, 0) then "" else s7;
      b = b or intNe(unit.g, 0);

      s = if b then s + s1 + s2 + s3 + s4 + s5 + s6 + s7 else "1";
    then s;

    else equation
      Error.addCompilerWarning("function Unit.unitString failed for \"" + unit2string(inUnit) +"\".");
    then fail();
  end match;
end unitString;

protected function prefix2String
  input Real inReal;
  output String outPrefix;
algorithm
  outPrefix := match(inReal)
    case 1e-24 then "y";
    case 1e-21 then "z";
    case 1e-18 then "a";
    case 1e-15 then "f";
    case 1e-12 then "p";
    case 1e-6 then "u";
    case 1e-3 then "m";
    case 1e-2 then "c";
    case 1e-1 then "d";
    case 1e1 then "da";
    case 1e2 then "h";
    case 1e3 then "k";
    case 1e6 then "M";
    case 1e9 then "G";
    case 1e12 then "T";
    case 1e15 then "P";
    case 1e18 then "E";
    case 1e21 then "Z";
    case 1e24 then "Y";
    else realString(inReal);
  end match;
end prefix2String;

public function parseUnitString "author: lochel
  The second argument is optional."
  input String inUnitString;
  input HashTableStringToUnit.HashTable inKnownUnits = getKnownUnits();
  output Unit outUnit;
protected
  list<String> charList;
  list<Token> tokenList;
algorithm
  charList := stringListStringChar(inUnitString);
  if listEmpty(charList) then
    fail();
  end if;
  tokenList := lexer(charList);
  outUnit := parser3({true, true}, tokenList, UNIT(1e0, 0, 0, 0, 0, 0, 0, 0), inKnownUnits);
  if not isUnit(outUnit) then
    fail();
  end if;
end parseUnitString;

protected function parser3
  input list<Boolean> inMul "true=Mul, false=Div, initial call with true";
  input list<Token> inTokenList "Tokenliste";
  input Unit inUnit "initial call with UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)";
  input HashTableStringToUnit.HashTable inHtS2U;
  output Unit outUnit;
algorithm
  outUnit := matchcontinue(inMul, inTokenList, inUnit, inHtS2U)
    local
      String s, s1, s2, unit;
      list<Token> tokens;
      Unit ut;
      Integer exponent;
      Boolean bMul, b;
      list<Boolean> bRest;

    // ""
    case ({true}, {}, _, _) then inUnit;

    // "1"
    case (bMul::bRest, T_NUMBER(number=1)::tokens, _, _) equation
      ut = UNIT(1e0, 0, 0, 0, 0, 0, 0, 0/* , 0e0 */);
      ut = if bMul then unitMul(inUnit,ut) else unitDiv(inUnit, ut);
      ut = parser3(bRest, tokens, ut, inHtS2U);
    then ut;

    // "unit^i"
    case (bMul::bRest, T_UNIT(unit=s)::T_NUMBER(exponent)::tokens, _, _) equation
      ut = unitToken2unit(s, inHtS2U);
      ut = unitPow(ut, exponent);
      ut = if bMul then unitMul(inUnit,ut) else unitDiv(inUnit, ut);
      ut = parser3(bRest, tokens, ut, inHtS2U);
    then ut;

    // "unit"
    case (bMul::bRest, T_UNIT(unit=s)::tokens, _, _) equation
      ut = unitToken2unit(s, inHtS2U);
      ut = if bMul then unitMul(inUnit,ut) else unitDiv(inUnit, ut);
      ut = parser3(bRest, tokens, ut, inHtS2U);
    then ut;

    // "*("
    case (bMul::_, T_MUL()::T_LPAREN()::tokens, _, _) equation
      ut = parser3(bMul::bMul::inMul, tokens, inUnit, inHtS2U);
    then ut;

    // "/("
    case (bMul::_, T_DIV()::T_LPAREN()::tokens, _, _) equation
      b = not bMul;
      ut = parser3(b::b::inMul, tokens, inUnit, inHtS2U);
    then ut;

    // ")"
    case (_::bRest, T_RPAREN()::tokens, _, _) equation
      ut = parser3(bRest, tokens, inUnit, inHtS2U);
    then ut;

    // "*"
    case (bMul::_, T_MUL()::tokens, _, _) equation
      ut = parser3(bMul::inMul, tokens, inUnit, inHtS2U);
    then ut;

    // "/"
    case (bMul::_, T_DIV()::tokens, _, _) equation
      b = not bMul;
      ut = parser3(b::inMul, tokens, inUnit, inHtS2U);
    then ut;

    else fail();
  end matchcontinue;
end parser3;

protected function unitToken2unit
  input String inS;
  input HashTableStringToUnit.HashTable inHtS2U;
  output Unit outUnit;
algorithm
  outUnit := matchcontinue(inS, inHtS2U)
    local
      String s, s2;
      Real r;
      Unit ut;

    case (_, _) equation
      ut=BaseHashTable.get(inS, inHtS2U);
    then ut;

    else equation
      s = stringGetStringChar(inS, 1);
      (r, s) = getPrefix(s, inS);
      ut = unitToken2unit(s, inHtS2U);
      ut = unitMulReal(ut, r);
    then ut;
  end matchcontinue;
end unitToken2unit;

protected function getPrefix
  input String inS;
  input String inS2;
  output Real outR;
  output String  outUnit;
algorithm
  (outR, outUnit) := matchcontinue(inS, inS2)
    local
      list<String> strRest;
      String s;

    case ("y", _) //-24
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-24, s);

    case ("z", _) //-21
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-21, s);

    case ("a", _) //-18
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-18, s);

    case ("f", _) //-15
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-15, s);

    case ("p", _) //-12
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-12, s);

    case ("u", _) //-6
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-6, s);

    case ("m", _) //-3
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-3, s);

    case ("c", _) //-2
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-2, s);

    case ("d", _)  //+1
      equation
        strRest = stringListStringChar(inS2);
        "d"::"a"::strRest = strRest;
        s = stringCharListString(strRest);
    then (1e1, s);

    case ("d", _) //-1
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e-1, s);

    case ("h", _) //+2
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e2, s);

    case ("k", _) //+3
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e3, s);

    case ("M", _) //+6
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e6, s);

    case ("G", _) //+9
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e9, s);

    case ("T", _) //+12
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e12, s);

    case ("P", _) //+15
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e15, s);

    case ("E", _) //+18
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e18, s);

    case ("Z", _) //+21
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e21, s);

    case ("Y", _) //+24
      equation
        _::strRest = stringListStringChar(inS2);
        s = stringCharListString(strRest);
    then (1e24, s);

    else fail();
  end matchcontinue;
end getPrefix;

protected function lexer "author: lochel
  Tokenizer: charList to tokenList"
  input list<String> inCharList;
  output list<Token> outTokenList;
algorithm
  outTokenList := matchcontinue(inCharList)
    local
      list<String> charList;
      String number;
      String unit;
      list<Token> tokenList;
      Integer i;

    case {} then {};

    case "."::charList equation
      tokenList = lexer(charList);
    then T_MUL()::tokenList;

    case "("::charList equation
      tokenList = lexer(charList);
    then T_LPAREN()::tokenList;

    case ")"::charList equation
      tokenList = lexer(charList);
    then T_RPAREN()::tokenList;

    case "/"::charList equation
      tokenList = lexer(charList);
    then T_DIV()::tokenList;

    case "+"::charList equation
      (charList, number) = popNumber(charList);
      false = (number == "");
      tokenList = lexer(charList);
      i = stringInt(number);
    then T_NUMBER(i)::tokenList;

    case "-"::charList equation
      (charList, number) = popNumber(charList);
      false = (number == "");
      tokenList = lexer(charList);
      i = -stringInt(number);
    then T_NUMBER(i)::tokenList;

    case charList equation
      (charList, number) = popNumber(charList);
      false = (number == "");
      tokenList = lexer(charList);
      i = stringInt(number);
    then T_NUMBER(i)::tokenList;

    case charList equation
      (charList, unit) = popUnit(charList);
      false = (unit == "");
      tokenList = lexer(charList);
    then T_UNIT(unit)::tokenList;

    else equation
      Error.addInternalError("function lexer failed", sourceInfo());
    then fail();
  end matchcontinue;
end lexer;

protected function popUnit
  input list<String> inCharList;
  output list<String> outCharList;
  output String outUnit;
algorithm
  (outCharList, outUnit) := matchcontinue(inCharList)
    local
      String s1, s2;
      list<String> strRest;

    case {}
    then ({}, "");

    case s1::strRest equation
      true = (stringCompare(s1, "a") >= 0) and (stringCompare(s1, "z") <= 0);
      (strRest, s2) = popUnit(strRest);
    then (strRest, s1 + s2);

    case s1::strRest equation
      true = (stringCompare(s1, "A") >= 0) and (stringCompare(s1, "Z") <= 0) ;
      (strRest, s2) = popUnit(strRest);
    then (strRest, s1 + s2);

    else (inCharList, "");
  end matchcontinue;
end popUnit;

protected function popNumber
  input list<String> inCharList;
  output list<String> outCharList;
  output String outNumber;
algorithm
  (outCharList, outNumber) := matchcontinue(inCharList)
    local
      String s1, s2;
      list<String> strRest;
      Integer i;

    case {}
    then ({}, "");

    case s1::strRest equation
      i = stringInt(s1);
      true = (intString(i) == s1);
      (strRest, s2) = popNumber(strRest);
    then (strRest, s1 + s2);

    else (inCharList, "");
  end matchcontinue;
end popNumber;

annotation(__OpenModelica_Interface="backend");
end Unit;
