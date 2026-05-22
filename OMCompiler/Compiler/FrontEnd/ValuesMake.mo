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

encapsulated package ValuesMake
" file:        ValuesMake.mo
  package:     ValuesMake
  description: Evaluated expression values


  The package Values contains utility functions for handling evaluated
  expression values."

public import Absyn;
public import AbsynUtil;
public import DAE;
public import Values;

protected
import List;

public function makeZero "Returns a zero value based on a DAE.Type"
  input DAE.Type ty;
  output Values.Value zero;
algorithm
  zero := match ty
    case DAE.T_REAL() then Values.REAL(0.0);
    case DAE.T_INTEGER() then Values.INTEGER(0);
  end match;
end makeZero;

public function makeBoolean
  input Boolean b;
  output Values.Value v;
algorithm
  v := Values.BOOL(b);
end makeBoolean;

public function makeReal "Creates a real value "
  input Real r;
  output Values.Value v;
algorithm
  v := Values.REAL(r);
end makeReal;

public function makeInteger "Creates an integer value "
  input Integer i;
  output Values.Value v;
algorithm
  v := Values.INTEGER(i);
end makeInteger;

public function makeString "Creates a string value "
  input String s;
  output Values.Value v;
algorithm
  v := Values.STRING(s);
end makeString;

public function makeTuple "Construct a tuple of a list of Values."
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
algorithm
  outValue := Values.TUPLE(inValueLst);
end makeTuple;

public function makeList "Construct a list from a list of Values."
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
algorithm
  outValue := Values.LIST(inValueLst);
end makeList;

public function makeArray "
  Construct an array of a list of Values.
"
  input list<Values.Value> inValueLst;
  output Values.Value outValue;
algorithm
  outValue:=
  matchcontinue (inValueLst)
    local
      Integer i1;
      list<Integer> il;
      list<Values.Value> vlst;
    case (vlst as (Values.ARRAY(dimLst = il)::_))
      algorithm
        i1 := listLength(vlst);
      then Values.ARRAY(vlst,i1::il);
    case (vlst)
      algorithm
        i1 := listLength(vlst);
      then Values.ARRAY(vlst,{i1});
  end matchcontinue;
end makeArray;

function makeEmptyArray
  output Values.Value outValue = Values.Value.ARRAY({}, {0});
end makeEmptyArray;

public function makeStringArray
  "Creates a Values.ARRAY from a list of Strings."
  input list<String> inReals;
  output Values.Value outArray;
algorithm
  outArray := makeArray(List.map(inReals, makeString));
end makeStringArray;

public function makeIntArray
  "Creates a Value.ARRAY from a list of integers."
  input list<Integer> inInts;
  output Values.Value outArray;
algorithm
  outArray := makeArray(List.map(inInts, makeInteger));
end makeIntArray;

public function makeRealArray
  "Creates a Values.ARRAY from a list of reals."
  input list<Real> inReals;
  output Values.Value outArray;
algorithm
  outArray := makeArray(List.map(inReals, makeReal));
end makeRealArray;

public function makeRealMatrix
  "Creates a matrix (ARRAY of ARRAY) from a list of list of reals."
  input list<list<Real>> inReals;
  output Values.Value outArray;
algorithm
  outArray := makeArray(List.map(inReals, makeRealArray));
end makeRealMatrix;

public function makeCodeTypeName
  input Absyn.Path path;
  output Values.Value val;
algorithm
  val := Values.CODE(Absyn.C_TYPENAME(path));
end makeCodeTypeName;

public function makeCodeTypeNameStr
  input String str;
  output Values.Value val;
algorithm
  val := Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(str)));
end makeCodeTypeNameStr;

public function makeCodeTypeNameArray
  input list<Absyn.Path> paths;
  output Values.Value val;
algorithm
  val := makeArray(list(makeCodeTypeName(p) for p in paths));
end makeCodeTypeNameArray;

annotation(__OpenModelica_Interface="frontend_dump");
end ValuesMake;
