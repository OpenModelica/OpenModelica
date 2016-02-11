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
  description:

               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)"


public import DAE;

protected import ComponentReference;
public import System;


public uniontype Unit
  record UNIT
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

  record UNKNOWN "unknown unit"
    String unit;
  end UNKNOWN;
end Unit;

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





public function hashUnitMod
  input Unit inKey;
  input Integer inMod;
  output Integer outHash;
protected
  String str;
  Integer i;
algorithm
  str := unit2string(inKey);
  outHash := System.stringHashDjb2Mod(str,inMod);
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

annotation(__OpenModelica_Interface="backend");
end Unit;
