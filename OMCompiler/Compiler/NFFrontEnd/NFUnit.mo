/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
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

encapsulated package NFUnit
" file:        NFUnit.mo
  package:     Unit
  description: This package defines the type Unit, which represents a unit based
               on SI base units, and some auxiliary functions therefore.

               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)"

public
import ComponentRef = NFComponentRef;
import Absyn;
import AbsynUtil;
import NFInstNode.InstNode;
import Type = NFType;
import UnorderedMap;

protected
import Debug;
import Error;
import Flags;
import Util;

public
type StringToUnitTable = UnorderedMap<String, Unit>;
type UnitToStringTable = UnorderedMap<Unit, String>;
type CrefToUnitTable = UnorderedMap<ComponentRef, Unit>;

public uniontype Unit
  record UNIT "based on SI base units"
    Integer s   "second";
    Integer m   "meter";
    Integer g   "gram";
    Integer A   "ampere";
    Integer K   "kelvin";
    Integer mol "mole";
    Integer cd  "candela";
    Real factor "prefix";
    //Real K_shift;
  end UNIT;

  record MASTER "unknown unit that belongs to all the variables from varList"
    list<ComponentRef> varList;
  end MASTER;

  record UNKNOWN "unknown SI base unit decomposition"
    String unit;
  end UNKNOWN;
end Unit;

public constant Unit ONE = UNIT(0, 0, 0, 0, 0, 0, 0, 1e0);
public constant Unit SECOND = UNIT(1, 0, 0, 0, 0, 0, 0, 1e0);
//public constant Unit THRICE = ?

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

public constant ComponentRef UPDATECREF = ComponentRef.CREF(InstNode.NAME_NODE("jhagemann"), {},
  Type.UNKNOWN(), NFComponentRef.Origin.CREF, ComponentRef.EMPTY());

/* from https://www.bipm.org/documents/d/guest/si-brochure-9-en-pdf */
public constant list<tuple<String, Unit>> LU_COMPLEXUNITS = {
  /*                 s, m, g, A, K,mol,cd,factor */
  ("1",         UNIT(0, 0, 0, 0, 0, 0, 0, 1e0)), // 1

  /* base units */
  ("s",         UNIT(1, 0, 0, 0, 0, 0, 0, 1e0)), // second
  ("m",         UNIT(0, 1, 0, 0, 0, 0, 0, 1e0)), // meter
  ("g",         UNIT(0, 0, 1, 0, 0, 0, 0, 1e0)), // gram
  ("A",         UNIT(0, 0, 0, 1, 0, 0, 0, 1e0)), // ampere
  ("K",         UNIT(0, 0, 0, 0, 1, 0, 0, 1e0)), // kelvin
  ("mol",       UNIT(0, 0, 0, 0, 0, 1, 0, 1e0)), // mole
  ("cd",        UNIT(0, 0, 0, 0, 0, 0, 1, 1e0)), // candela

  /* derived units */
  ("rad",       UNIT(0, 0, 0, 0, 0, 0, 0, 1e0)), // radian
//("sr",        UNIT(0, 0, 0, 0, 0, 0, 0, 1e0)), // steradian
  ("Hz",        UNIT(-1,0, 0, 0, 0, 0, 0, 1e0)), // hertz
  ("N",         UNIT(-2,1, 1, 0, 0, 0, 0, 1e3)), // newton
  ("Pa",        UNIT(-2,-1,1, 0, 0, 0, 0, 1e3)), // pascal
  ("J",         UNIT(-2,2, 1, 0, 0, 0, 0, 1e3)), // joule
  ("W",         UNIT(-3,2, 1, 0, 0, 0, 0, 1e3)), // watt
  ("C",         UNIT(1, 0, 0, 1, 0, 0, 0, 1e0)), // coulomb
  ("V",         UNIT(-3,2, 1,-1, 0, 0, 0, 1e3)), // volt
  ("F",         UNIT(4,-2,-1, 2, 0, 0, 0,1e-3)), // farad
  ("Ohm",       UNIT(-3,2, 1,-2, 0, 0, 0, 1e3)), // ohm
  ("S",         UNIT(3,-2,-1, 2, 0, 0, 0,1e-3)), // siemens
  ("Wb",        UNIT(-2,2, 1,-1, 0, 0, 0, 1e3)), // weber
  ("T",         UNIT(-2,0, 1,-1, 0, 0, 0, 1e3)), // tesla
  ("H",         UNIT(-2,2, 1,-2, 0, 0, 0, 1e3)), // henry
  ("degC",      UNIT(0, 0, 0, 0, 1, 0, 0, 1e0)), // °Celsius
//("lm",        UNIT(0, 0, 0, 0, 0, 0, 1, 1e0)), // lumen
//("lx",        UNIT(0,-2, 0, 0, 0, 0, 1, 1e0)), // lux
//("Bq",        UNIT(-1,0, 0, 0, 0, 0, 0, 1e0)), // becquerel
//("Gy",        UNIT(-2,2, 0, 0, 0, 0, 0, 1e0)), // gray
//("Sv",        UNIT(-2,2, 0, 0, 0, 0, 0, 1e0)), // sievert
  ("kat",       UNIT(-1,0, 0, 0, 0, 1, 0, 1e0)), // katal

  /* accepted non-SI units */
  ("min",       UNIT(1, 0, 0, 0, 0, 0, 0,  60)), // minute
  ("h",         UNIT(1, 0, 0, 0, 0, 0, 0,3600)), // hour
  ("d",         UNIT(1, 0, 0, 0, 0, 0, 0,86400)), // day
//("au",        UNIT(0, 1, 0, 0, 0, 0, 0,149597870700)), // astronomical unit
//("deg",       UNIT(0, 0, 0, 0, 0, 0, 0,1.7453292519943295e-2)), // degree
//("???",       UNIT(0, 0, 0, 0, 0, 0, 0,2.908882086657216e-4)), // arcminute
//("???",       UNIT(0, 0, 0, 0, 0, 0, 0,4.84813681109536e-6)), // arcsecond
//("ha",        UNIT(0, 2, 0, 0, 0, 0, 0, 1e4)), // hectare
  ("l",         UNIT(0, 3, 0, 0, 0, 0, 0,1e-3)), // liter
//("L",         UNIT(0, 3, 0, 0, 0, 0, 0,1e-3)), // liter
//("t",         UNIT(0, 0, 1, 0, 0, 0, 0, 1e6)), // tonne
//("eV",        UNIT(-2,2, 1, 0, 0, 0, 0,1.602176634e-16)), // electronvolt
//("B",         UNIT(0, 0, 0, 0, 0, 0, 0,1e-2)), // bel (dezibel dB)

  /* custom units */
  ("bar",       UNIT(-2,-1,1, 0, 0, 0, 0, 1e8)), // bar = 100kPa
  ("degF",      UNIT(0, 0, 0, 0, 0, 0, 1, 0.5555555555555556))//°Fahrenheit

/* old implementation */
/*                   fac,mol,cd, m, s, A, K, g*/
//("VA",        UNIT(1e3, 0, 0, 2,-3, 0, 0, 1)), //Voltampere=Watt
//("var",       UNIT(1e3, 0, 0, 2,-3, 0, 0, 1)), //Var=Watt
//("R",         UNIT(2.58e-7, 0, 0, 0, 1, 1, 0,-1)), //Röntgen    2, 58*10^-4 C/kg
//("phon",      UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)), //Phon
//("sone",      UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)), //Sone
};

public function getKnownUnits
  output StringToUnitTable outKnownUnits;
protected
  String s;
  Unit ut;
algorithm
  outKnownUnits := UnorderedMap.new<Unit>(stringHashDjb2, stringEq);

  for unit in LU_COMPLEXUNITS loop
    (s, ut) := unit;
    UnorderedMap.add(s, ut, outKnownUnits);
  end for;
end getKnownUnits;

public function getKnownUnitsInverse
  output UnitToStringTable outKnownUnitsInverse;
protected
  String s;
  Unit ut;
algorithm
  outKnownUnitsInverse := UnorderedMap.new<String>(hashUnit, unitEqual);

  for unit in LU_COMPLEXUNITS loop
    (s, ut) := unit;
    UnorderedMap.tryAdd(ut, s, outKnownUnitsInverse);
  end for;
end getKnownUnitsInverse;

public function newCrefUnitTable
  input Integer size;
  output CrefToUnitTable table;
algorithm
  table := UnorderedMap.new<Unit>(ComponentRef.hash, ComponentRef.isEqual);
end newCrefUnitTable;

public function isUnit
  input Unit inUnit;
  output Boolean b;
algorithm
  b := match inUnit
    case UNIT() then true;
    else false;
  end match;
end isUnit;

public function isMaster
  input Unit unit;
  output Boolean res;
algorithm
  res := match unit
    case MASTER() then true;
    else false;
  end match;
end isMaster;

public function hashUnit
  input Unit inKey;
  output Integer outHash = stringHashDjb2(unit2string(inKey));
end hashUnit;

function realAlmostEqRel
  // TODO move to MetaModelicaBuiltin.mo?
  input Real a;
  input Real b;
  input Real relTol = 1e-3;
  output Boolean c;
algorithm
  c := if a == b then true else relTol > abs(a - b)/(abs(a) + abs(b));
end realAlmostEqRel;

public function unitEqual
  input Unit unit1;
  input Unit unit2;
  output Boolean res;
algorithm
  res := match (unit1, unit2)
    case (UNIT(), UNIT())
    then  unit1.s   == unit2.s
      and unit1.m   == unit2.m
      and unit1.g   == unit2.g
      and unit1.A   == unit2.A
      and unit1.K   == unit2.K
      and unit1.mol == unit2.mol
      and unit1.cd  == unit2.cd
      and realAlmostEqRel(unit1.factor, unit2.factor);

    case (MASTER(), MASTER()) //equation
      // lcr comparison????
    then true;

    case (UNKNOWN(), UNKNOWN()) then unit1.unit == unit2.unit;

    else false;
  end match;
end unitEqual;

public function unit2string
  input Unit unit;
  output String outString;
algorithm
  outString := match unit
    local
      String s, str;
      Boolean b;
      list<ComponentRef> crefList;

    case UNIT() equation
      str = realString(unit.factor) + " * ";

      b = false;
      s = "mol^(" + intString(unit.mol) + ")";
      s = if intEq(unit.mol, 0) then "" else s;
      b = b or intNe(unit.mol, 0);
      str = str + s;

      s = if b and intNe(unit.cd, 0) then " * " else "";
      str = str + s;
      s = "cd^(" + intString(unit.cd) + ")";
      s = if intEq(unit.cd, 0) then "" else s;
      b = b or intNe(unit.cd, 0);
      str = str + s;

      s = if b and intNe(unit.m, 0) then " * " else "";
      str = str + s;
      s = "m^(" + intString(unit.m) + ")";
      s = if intEq(unit.m, 0) then "" else s;
      b = b or intNe(unit.m, 0);
      str = str + s;

      s = if b and intNe(unit.s, 0) then " * " else "";
      str = str + s;
      s = "s^(" + intString(unit.s) + ")";
      s = if intEq(unit.s, 0) then "" else s;
      b = b or intNe(unit.s, 0);
      str = str + s;

      s = if b and intNe(unit.A, 0) then " * " else "";
      str = str + s;
      s = "A^(" + intString(unit.A) + ")";
      s = if intEq(unit.A, 0) then "" else s;
      b = b or intNe(unit.A, 0);
      str = str + s;

      s = if b and intNe(unit.K, 0) then " * " else "";
      str = str + s;
      //s = "(K-" + realString(unit.shift) + ")^(" + intString(unit.K) + ")";
      s = "K^(" + intString(unit.K) + ")";
      s = if intEq(unit.K, 0) then "" else s;
      b = b or intNe(unit.K, 0);
      str = str + s;

      s = if b and intNe(unit.g, 0) then " * " else "";
      str = str + s;
      s = "g^(" + intString(unit.g) + ")";
      s = if intEq(unit.g, 0) then "" else s;
      b = b or intNe(unit.g, 0);
      str = str + s;

      str = str + (if b then "" else "1");
    then str;

    case MASTER()   then "MASTER(" + printListCr(unit.varList) + ")";
    case UNKNOWN()  then "UNKOWN(" + unit.unit + ")";
  end match;
end unit2string;

public function printListCr
 input list<ComponentRef> inlCr;
 output String outS;
algorithm
  outS := match(inlCr)

  local
    list<ComponentRef> lCr;
    ComponentRef cr;
    String s;

    case {} then "";

    case cr::{} equation
      s = ComponentRef.toString(cr);
    then s;

    case cr::lCr equation
      s = ComponentRef.toString(cr);
      s = s + ", " + printListCr(lCr);
    then s;

  end match;
end printListCr;

public function unitMul
  input Unit inUnit1;
  input Unit inUnit2;
  output Unit outUnit;
algorithm
  outUnit := match (inUnit1, inUnit2)
    case (UNIT(), UNIT())
    then UNIT(
      s   = inUnit1.s + inUnit2.s,
      m   = inUnit1.m + inUnit2.m,
      g   = inUnit1.g + inUnit2.g,
      A   = inUnit1.A + inUnit2.A,
      K   = inUnit1.K + inUnit2.K,
      mol = inUnit1.mol + inUnit2.mol,
      cd  = inUnit1.cd + inUnit2.cd,
      factor = inUnit1.factor * inUnit2.factor
    );
  end match;
end unitMul;

public function unitDiv
  input Unit inUnit1;
  input Unit inUnit2;
  output Unit outUnit;
algorithm
  outUnit := match (inUnit1, inUnit2)
    case (UNIT(), UNIT())
    then UNIT(
      s   = inUnit1.s - inUnit2.s,
      m   = inUnit1.m - inUnit2.m,
      g   = inUnit1.g - inUnit2.g,
      A   = inUnit1.A - inUnit2.A,
      K   = inUnit1.K - inUnit2.K,
      mol = inUnit1.mol - inUnit2.mol,
      cd  = inUnit1.cd - inUnit2.cd,
      factor = inUnit1.factor / inUnit2.factor
    );
  end match;
end unitDiv;

public function unitPow
  input Unit inUnit;
  input Integer inExp "exponent";
  output Unit outUnit;
algorithm
  outUnit := match inUnit
    case UNIT()
    then UNIT(
      s   = inUnit.s * inExp,
      m   = inUnit.m * inExp,
      g   = inUnit.g * inExp,
      A   = inUnit.A * inExp,
      K   = inUnit.K * inExp,
      mol = inUnit.mol * inExp,
      cd  = inUnit.cd * inExp,
      factor = inUnit.factor^inExp
    );
  end match;
end unitPow;

public function unitMulReal
  input Unit inUnit;
  input Real inFactor;
  output Unit outUnit;
algorithm
  outUnit := match inUnit
    local
      Unit unit;
    case unit as UNIT() algorithm
      unit.factor := unit.factor * inFactor;
    then unit;
  end match;
end unitMulReal;

public function unitRoot
  input Unit inUnit;
  input Real inExponent;
  output Unit outUnit;
algorithm
  outUnit := match inUnit
    local
      Real r, factor;
      Integer i, s, m, g, A, K, mol, cd;

    case UNIT() algorithm
      i := realInt(inExponent);
      r := realDiv(1.0, inExponent);
      factor := realPow(inUnit.factor, r);

      r := realDiv(intReal(inUnit.s),inExponent);
      s := intDiv(inUnit.s, i);
      true := realEq(r, intReal(s));

      r := realDiv(intReal(inUnit.m),inExponent);
      m := intDiv(inUnit.m, i);
      true := realEq(r, intReal(m));

      r := realDiv(intReal(inUnit.g),inExponent);
      g := intDiv(inUnit.g, i);
      true := realEq(r, intReal(g));

      r := realDiv(intReal(inUnit.A),inExponent);
      A := intDiv(inUnit.A, i);
      true := realEq(r, intReal(A));

      r := realDiv(intReal(inUnit.K),inExponent);
      K := intDiv(inUnit.K, i);
      true := realEq(r, intReal(K));

      r := realDiv(intReal(inUnit.mol),inExponent);
      mol := intDiv(inUnit.mol, i);
      true := realEq(r, intReal(mol));

      r := realDiv(intReal(inUnit.cd),inExponent);
      cd := intDiv(inUnit.cd, i);
      true := realEq(r, intReal(cd));
    then UNIT(s, m, g, A, K, mol, cd, factor);
  end match;
end unitRoot;

public function unitString "Unit to Modelica unit string"
  input Unit inUnit;
  input UnitToStringTable inHtU2S = getKnownUnitsInverse();
  output String outString;
protected
  Option<String> opt_s;
  String s, s1, s2, s3, s4, s5, s6, s7, sExponent;
  Boolean b;
  Unit unit;
algorithm
  opt_s := UnorderedMap.get(inUnit, inHtU2S);

  if isSome(opt_s) then
    SOME(outString) := opt_s;
    return;
  end if;

  outString := match inUnit
    case unit as UNIT() equation
      s = if unit.factor == 1.0 then "" else prefix2String(unit.factor);
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
  "from https://www.bipm.org/en/measurement-units/si-prefixes"
  input Real inReal;
  output String outPrefix;
algorithm
  outPrefix := match(inReal)
    case 1e30   then "Q";   // quetta
    case 1e27   then "R";   // ronna
    case 1e24   then "Y";   // yotta
    case 1e21   then "Z";   // zetta
    case 1e18   then "E";   // exa
    case 1e15   then "P";   // peta
    case 1e12   then "T";   // tera
    case 1e9    then "G";   // giga
    case 1e6    then "M";   // mega
    case 1e3    then "k";   // kilo
    case 1e2    then "h";   // hecto
    case 1e1    then "da";  // deca
    case 1e-1   then "d";   // deci
    case 1e-2   then "c";   // centi
    case 1e-3   then "m";   // milli
    case 1e-6   then "u";   // micro
    case 1e-9   then "n";   // nano
    case 1e-12  then "p";   // pico
    case 1e-15  then "f";   // femto
    case 1e-18  then "a";   // atto
    case 1e-21  then "z";   // zepto
    case 1e-24  then "y";   // yocto
    case 1e-27  then "r";   // ronto
    case 1e-30  then "q";   // quecto
    else realString(inReal);
  end match;
end prefix2String;

public function parseUnitString "author: lochel
  The second argument is optional."
  input String inUnitString;
  input StringToUnitTable inKnownUnits = getKnownUnits();
  input SourceInfo info = AbsynUtil.dummyInfo;
  output Unit outUnit;
protected
  list<String> charList;
  list<Token> tokenList;
algorithm
  charList := stringListStringChar(inUnitString);
  if listEmpty(charList) then
    fail();
  end if;

  try
    tokenList := lexer(charList);
  else
    Error.addSourceMessage(Error.INVALID_UNIT, {inUnitString}, info);
    fail();
  end try;

  outUnit := parser3({true, true}, tokenList, NFUnit.ONE, inKnownUnits);
  if not isUnit(outUnit) then
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.traceln(getInstanceName() + ": failed to parse unit string " + inUnitString);
    end if;
  end if;
end parseUnitString;

protected function parser3
  input list<Boolean> inMul "true=Mul, false=Div, initial call with true";
  input list<Token> inTokenList "Tokenliste";
  input Unit inUnit "initial call with NFUnit.ONE";
  input StringToUnitTable inHtS2U;
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
      ut = NFUnit.ONE;
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

    else UNKNOWN("");
  end matchcontinue;
end parser3;

protected function unitToken2unit
  input String inS;
  input StringToUnitTable inHtS2U;
  output Unit outUnit;
protected
  Option<Unit> opt_unit;
  String s, s2;
  Real r;
algorithm
  opt_unit := UnorderedMap.get(inS, inHtS2U);

  if isSome(opt_unit) then
    SOME(outUnit) := opt_unit;
  else
    s := stringGetStringChar(inS, 1);
    (r, s) := getPrefix(s, inS);
    outUnit := unitToken2unit(s, inHtS2U);
    outUnit := unitMulReal(outUnit, r);
  end if;
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

annotation(__OpenModelica_Interface="frontend");
end NFUnit;
