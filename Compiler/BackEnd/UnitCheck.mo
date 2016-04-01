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

encapsulated package UnitCheck
" file:        UnitCheck.mo
  package:     UnitCheck
  description: This package provides everything for advanced unit checking:
                 - for all variables unspecified units get calculated if possible
                 - inconsistent equations get reported in a user friendly way

               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)"


public import Absyn;
public import BackendDAE;
public import DAE;
public import Unit;

protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendDAEUtil;
protected import BaseHashTable;
protected import ComponentReference;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import HashTableCrToUnit;
protected import HashTableStringToUnit;
protected import HashTableUnitToString;
protected import List;

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



// =============================================================================
// section for preOptModule >>unitChecking<<
// The unit check module verifies the consistency of units.
//
// =============================================================================

public function unitChecking "author: jhagemann"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
  BackendDAE.Variables orderedVars, knownVars, aliasVars;
  HashTableCrToUnit.HashTable HtCr2U1, HtCr2U2;
  HashTableStringToUnit.HashTable HtS2U;
  HashTableUnitToString.HashTable HtU2S;
  list<BackendDAE.Equation> eqList;
  list<BackendDAE.Var> varList, paraList, aliasList;
algorithm
  try
    BackendDAE.DAE({syst}, shared) := inDAE;

    varList := BackendVariable.varList(syst.orderedVars);
    paraList := BackendVariable.varList(shared.knownVars);
    aliasList := BackendVariable.varList(shared.aliasVars);
    eqList := BackendEquation.equationList(syst.orderedEqs);

    HtCr2U1 := HashTableCrToUnit.emptyHashTableSized(2053);
    HtS2U := foldComplexUnits(HashTableStringToUnit.emptyHashTableSized(2053));
    HtU2S := foldComplexUnits2(HashTableUnitToString.emptyHashTableSized(2053));

    if Flags.isSet(Flags.DUMP_EQ_UNIT) then
      BackendDump.dumpEquationList(eqList, "########### Equation-Liste: #########\n");
    end if;
    ((HtCr2U1, HtS2U, HtU2S)) := List.fold(varList, convertUnitString2unit, (HtCr2U1, HtS2U, HtU2S));
    ((HtCr2U1, HtS2U, HtU2S)) := List.fold(paraList, convertUnitString2unit, (HtCr2U1, HtS2U, HtU2S));
    ((HtCr2U1, HtS2U, HtU2S)) := List.fold(aliasList, convertUnitString2unit, (HtCr2U1, HtS2U, HtU2S));

    HtCr2U2 := BaseHashTable.copy(HtCr2U1);
    if Flags.isSet(Flags.DUMP_UNIT) then
      print("#####################################\n");
      BaseHashTable.dumpHashTable(HtCr2U1);
    end if;
    ((HtCr2U2, HtS2U, HtU2S)) := algo(paraList, eqList, HtCr2U2, HtS2U, HtU2S);
    if Flags.isSet(Flags.DUMP_UNIT) then
      BaseHashTable.dumpHashTable(HtCr2U2);
      print("######## UnitCheck COMPLETED ########\n");
    end if;
    notification(HtCr2U1, HtCr2U2, HtU2S);
    varList := List.map2(varList, returnVar, HtCr2U2, HtU2S);
    paraList := List.map2(paraList, returnVar, HtCr2U2, HtU2S);
    aliasList := List.map2(aliasList, returnVar, HtCr2U2, HtU2S);

    orderedVars := BackendVariable.listVar(varList);
    knownVars := BackendVariable.listVar(paraList);
    aliasVars := BackendVariable.listVar(aliasList);

    syst := BackendDAEUtil.setEqSystVars(syst, orderedVars);
    shared := BackendDAEUtil.setSharedKnVars(shared, knownVars);
    shared := BackendDAEUtil.setSharedAliasVars(shared, aliasVars);
    outDAE := BackendDAE.DAE({syst}, shared);
  else
    // if Flags.getConfigBool(Flags.NEW_UNIT_CHECKING) then
    //   Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: unit check module failed");
    // end if;
    outDAE := inDAE;
  end try;
end unitChecking;

//
//
protected function foldComplexUnits
  input HashTableStringToUnit.HashTable inHtS2U;
  output HashTableStringToUnit.HashTable outHtS2U;
algorithm
  outHtS2U := List.fold(Unit.LU_COMPLEXUNITS, addUnit2HtS2U, inHtS2U);
end foldComplexUnits;

//
//
protected function addUnit2HtS2U
  input tuple<String, Unit.Unit> inTpl;
  input HashTableStringToUnit.HashTable inHtS2U;
  output HashTableStringToUnit.HashTable outHtS2U;
algorithm
  outHtS2U := BaseHashTable.add(inTpl,inHtS2U);
end addUnit2HtS2U;

//
//
protected function foldComplexUnits2
  input HashTableUnitToString.HashTable inHtU2S;
  output HashTableUnitToString.HashTable outHtU2S;
algorithm
  outHtU2S := List.fold(Unit.LU_COMPLEXUNITS, addUnit2HtU2S, inHtU2S);
end foldComplexUnits2;

//
//
protected function addUnit2HtU2S
  input tuple<String, Unit.Unit> inTpl;
  input HashTableUnitToString.HashTable inHtU2S;
  output HashTableUnitToString.HashTable outHtU2S;
algorithm
  outHtU2S := matchcontinue(inTpl, inHtU2S)
  local
    String s;
    Unit.Unit ut;
    HashTableUnitToString.HashTable HtU2S;

  case ((s, ut), _)
    equation
      false = BaseHashTable.hasKey(ut, inHtU2S);
      HtU2S = BaseHashTable.add((ut,s),inHtU2S);
  then HtU2S;

  else inHtU2S;
  end matchcontinue;
end addUnit2HtU2S;

//
//
protected function returnVar "returns the new calculated units in DAE"
  input BackendDAE.Var inVar;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output BackendDAE.Var outVar;
algorithm
  outVar := match(inVar, inHtCr2U, inHtU2S)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      Unit.Unit ut;
      String s;

    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(unit=SOME(_)))), _, _)
    then inVar;

    else equation
      cr = BackendVariable.varCref(inVar);
      ut = BaseHashTable.get(cr, inHtCr2U);
      s = unit2String(ut, inHtU2S);
      var = BackendVariable.setUnit(inVar, DAE.SCONST(s));
    then var;
  end match;
end returnVar;

//
//
protected function unit2String "transforms the unit in string"
  input Unit.Unit inUt;
  input HashTableUnitToString.HashTable inHtU2S;
  output String outS;
algorithm
  outS := matchcontinue(inUt, inHtU2S)
    local
      String s, s1, s2, s3, s4, s5, s6, s7, sExponent;
      Integer prefix, exponent, i1, i2, i3, i4, i5, i6, i7;
      Real factor;
      Boolean b;
      Unit.Unit ut;

    case (ut, _) equation
      s = BaseHashTable.get(ut, inHtU2S);
    then s;

    case (Unit.UNIT(factor, i1, i2, i3, i4, i5, i6, i7), _) equation
      s = prefix2String(factor);

      s= if realEq(factor, 1.0) then "" else s;
      b = false;
      sExponent = if intEq(i1, 1) then "" else intString(i1);
      s1 = "mol" + sExponent;
      s1 = if intEq(i1, 0) then "" else s1;
      b = b or intNe(i1, 0);

      s2 = if b and intNe(i2, 0) then "." else "";
      sExponent = if intEq(i2, 1) then "" else intString(i2);
      s2 = s2 + "cd" + sExponent;
      s2 = if intEq(i2, 0) then "" else s2;
      b = b or intNe(i2, 0);

      s3 = if b and intNe(i3, 0) then "." else "";
      sExponent = if intEq(i3, 1) then "" else intString(i3);
      s3 = s3 + "m" + sExponent;
      s3 = if intEq(i3, 0) then "" else s3;
      b = b or intNe(i3, 0);

      s4 = if b and intNe(i4, 0) then "." else "";
      sExponent = if intEq(i4, 1) then "" else intString(i4);
      s4 = s4 + "s" + sExponent;
      s4 = if intEq(i4, 0) then "" else s4;
      b = b or intNe(i4, 0);

      s5 = if b and intNe(i5, 0) then "." else "";
      sExponent = if intEq(i5, 1) then "" else intString(i5);
      s5 = s5 + "A" + sExponent;
      s5 = if intEq(i5, 0) then "" else s5;
      b = b or intNe(i5, 0);

      s6 = if b and intNe(i6, 0) then "." else "";
      sExponent = if intEq(i6, 1) then "" else intString(i6);
      s6 = s6 + "K" + sExponent;
      s6 = if intEq(i6, 0) then "" else s6;
      b = b or intNe(i6, 0);

      s7 = if b and intNe(i7, 0) then "." else "";
      sExponent = if intEq(i7, 1) then "" else intString(i7);
      s7 = s7 + "g" + sExponent;
      s7 = if intEq(i7, 0) then "" else s7;
      b = b or intNe(i7, 0);
      s = s + s1 + s2 + s3 + s4 + s5 + s6 + s7;
      s = if b then s else "1";
    then s;

    else equation
      Error.addCompilerWarning("function unit2String failed: \"" + Unit.unit2string(inUt) +"\" can not return in DAE!!!");
    then Unit.unit2string(inUt);
  end matchcontinue;
end unit2String;

//
//
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

//
//
protected function algo "algorithm to check the consistency"
  input list<BackendDAE.Var> inparaList;
  input list<BackendDAE.Equation> ineqList;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
protected
  HashTableCrToUnit.HashTable HtCr2U;
  HashTableStringToUnit.HashTable HtS2U;
  HashTableUnitToString.HashTable HtU2S;
  Boolean b1, b2, b3;

algorithm
  ((HtCr2U, b1, HtS2U, HtU2S)) := List.fold(inparaList, foldBindingExp, (inHtCr2U, true, inHtS2U, inHtU2S));
  ((HtCr2U, b2, HtS2U, HtU2S)) := List.fold(ineqList, foldEquation, (HtCr2U, true, HtS2U, HtU2S));
  b3 := BaseHashTable.hasKey(Unit.UPDATECREF, HtCr2U);
  outTpl := algo2(b1, b2, b3, inparaList, ineqList, HtCr2U, HtS2U, HtU2S);
end algo;

//
//
protected function algo2 "help-function"
  input Boolean inB1;
  input Boolean inB2;
  input Boolean inB3;
  input list<BackendDAE.Var> inparaList;
  input list<BackendDAE.Equation> ineqList;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
algorithm
  outTpl:=match(inB1, inB2, inB3, inparaList, ineqList, inHtCr2U, inHtS2U, inHtU2S)
    local
      HashTableCrToUnit.HashTable HtCr2U;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      DAE.ComponentRef cr;

    case (true, true, false, _, _, _, _, _)
      equation
    then ((inHtCr2U, inHtS2U, inHtU2S));

    case (true, true, true, _, _, _, _, _) equation
      BaseHashTable.delete(Unit.UPDATECREF,inHtCr2U);
      ((HtCr2U, HtS2U, HtU2S))=algo(inparaList, ineqList, inHtCr2U, inHtS2U, inHtU2S);
    then ((HtCr2U, HtS2U, HtU2S));

    else fail();
  end match;
end algo2;

//
//
protected function foldEquation "folds the equations or return the error message of incosistent equations"
  input BackendDAE.Equation inEq;
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* inHtS2U */, HashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
protected
  HashTableCrToUnit.HashTable HtCr2U;
  HashTableStringToUnit.HashTable HtS2U;
  HashTableUnitToString.HashTable HtU2S;
  list<list<tuple<DAE.Exp, Unit.Unit>>> expListList;
  Boolean b;
algorithm
  if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
    BackendDump.printEquation(inEq);
  end if;
  (HtCr2U, b, HtS2U, HtU2S):=inTpl;
  (HtCr2U, HtS2U, HtU2S, expListList):=foldEquation2(inEq, HtCr2U, HtS2U, HtU2S);
  List.map2_0(expListList, Errorfunction, inEq, HtU2S);
  b := listEmpty(expListList) and b;
  outTpl := (HtCr2U, b, HtS2U, HtU2S);
end foldEquation;

//
//
protected function foldEquation2 "help-function"
  input BackendDAE.Equation inEq;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output HashTableCrToUnit.HashTable outHtCr2U;
  output HashTableStringToUnit.HashTable outHtS2U;
  output HashTableUnitToString.HashTable outHtU2S;
  output list<list<tuple<DAE.Exp, Unit.Unit>>> outexpListList;

algorithm
  (outHtCr2U, outHtS2U, outHtU2S, outexpListList) := match(inEq, inHtCr2U, inHtS2U, inHtU2S)
    local
      DAE.Exp temp, rhs, lhs;
      BackendDAE.Equation eq;
      HashTableCrToUnit.HashTable HtCr2U;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      list<list<tuple<DAE.Exp, Unit.Unit>>> expList;
      DAE.ComponentRef cr;

    case (BackendDAE.EQUATION(exp=lhs, scalar=rhs), HtCr2U, HtS2U, HtU2S) equation
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
      (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (HtCr2U, HtS2U, HtU2S, expList);

    case (BackendDAE.ARRAY_EQUATION(left=lhs, right=rhs), HtCr2U, HtS2U, HtU2S) equation
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
      (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (HtCr2U, HtS2U, HtU2S, expList);

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=rhs), HtCr2U, HtS2U, HtU2S) equation
      lhs = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
      (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (HtCr2U, HtS2U, HtU2S, expList);

    case (BackendDAE.RESIDUAL_EQUATION(exp=rhs), HtCr2U, HtS2U, HtU2S) equation
      lhs = DAE.RCONST(0.0);
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
      (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (HtCr2U, HtS2U, HtU2S, expList);

    case (BackendDAE.ALGORITHM(), _, _, _) equation
      //Error.addCompilerWarning("ALGORITHM, these types of equations are not yet supported\n");
    then (inHtCr2U, inHtS2U, inHtU2S, {});

    case (BackendDAE.WHEN_EQUATION(), _, _, _) equation
      //Error.addCompilerWarning("WHEN_EQUATION, these types of equations are not yet supported\n");
    then (inHtCr2U, inHtS2U, inHtU2S, {});

    case (BackendDAE.COMPLEX_EQUATION(left=lhs, right=rhs), HtCr2U, HtS2U, HtU2S) equation
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
      (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (HtCr2U, HtS2U, HtU2S, expList);

    case (BackendDAE.IF_EQUATION(), _, _, _) equation
       //Error.addCompilerWarning("IF_EQUATION, these types of equations are not yet supported\n");
    then (inHtCr2U, inHtS2U, inHtU2S, {});

    else equation
      Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: function foldEquation failed", sourceInfo());
    then fail();
  end match;
end foldEquation2;

//
//
protected function foldBindingExp "folds the Binding expressions"
  input BackendDAE.Var inVar;
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* inHtS2U */, HashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
algorithm
  outTpl := matchcontinue(inVar, inTpl)
    local
      DAE.Exp exp, crefExp;
      DAE.ComponentRef cref;
      HashTableCrToUnit.HashTable HtCr2U;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      Boolean b;
      BackendDAE.Equation eq;

    case (BackendDAE.VAR(varType=DAE.T_REAL(), bindExp=SOME(exp)), (HtCr2U, b, HtS2U, HtU2S)) equation
      cref = BackendVariable.varCref(inVar);
      crefExp = Expression.crefExp(cref);
      eq = BackendDAE.EQUATION(crefExp, exp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
      ((HtCr2U, b, HtS2U, HtU2S))=foldEquation(eq, (HtCr2U, b, HtS2U, HtU2S));
    then ((HtCr2U, b, HtS2U, HtU2S));

    case (BackendDAE.VAR(varType=DAE.T_REAL(), bindExp=SOME(_)), (HtCr2U, _, HtS2U, HtU2S))
    then ((HtCr2U, false, HtS2U, HtU2S));

    else inTpl;
  end matchcontinue;
end foldBindingExp;

//
//
protected function Errorfunction "returns the incostinent Equation with sub-expression"
  input list<tuple<DAE.Exp, Unit.Unit>> inexpList;
  input BackendDAE.Equation inEq;
  input HashTableUnitToString.HashTable inHtU2S;
algorithm
  _ := match(inexpList, inEq, inHtU2S)
    local
      String s, s1, s2, s3, s4;
      list<tuple<DAE.Exp, Unit.Unit>> expList;
      DAE.Exp exp1, exp2;
      Integer i;

    case (expList, _, _)
      equation
        s = BackendDump.equationString(inEq);
        s1 = Errorfunction2(expList, inHtU2S);
        Error.addCompilerWarning("The following equation is INCONSISTENT due to specified unit information: " + s + "\n" +
        "The units of following sub-expressions need to be equal:\n" + s1 );
    then ();
  end match;
end Errorfunction;

//
//
protected function Errorfunction2 "help-function"
  input list<tuple<DAE.Exp, Unit.Unit>> inexpList;
  input HashTableUnitToString.HashTable inHtU2S;
  output String outS;
algorithm
  outS := match(inexpList, inHtU2S)
    local
      list<tuple<DAE.Exp, Unit.Unit>> expList;
      DAE.Exp exp;
      Unit.Unit ut;
      String s, s1, s2;

    case ((exp, ut)::{}, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = unit2String(ut, inHtU2S);
      s = "- sub-expression \"" + s + "\" has unit \"" + s1 + "\"";
    then s;

    case ((exp, ut)::expList, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = unit2String(ut, inHtU2S);
      s2 = Errorfunction2(expList, inHtU2S);
      s = "- sub-expression \"" + s + "\" has unit \"" + s1 + "\"\n" + s2;
    then s;
  end match;
end Errorfunction2;

//
//
protected function notification "dumps the calculated units"
  input HashTableCrToUnit.HashTable inHtCr2U1;
  input HashTableCrToUnit.HashTable inHtCr2U2;
  input HashTableUnitToString.HashTable inHtU2S;
algorithm
  _ := matchcontinue(inHtCr2U1, inHtCr2U2, inHtU2S)
  local
    String str;
    list<tuple<DAE.ComponentRef, Unit.Unit>> lt1;

  case (_,_,_)
    equation
      lt1 = BaseHashTable.hashTableList(inHtCr2U1);
      str = notification2(lt1, inHtCr2U2, inHtU2S);
      false = stringEqual(str, "");
      if Flags.isSet(Flags.DUMP_UNIT) then
        Error.addCompilerNotification(str);
      end if;
    then ();

  else ();
  end matchcontinue;
end notification;

//
//
protected function notification2 "help-function"
  input list<tuple<DAE.ComponentRef, Unit.Unit>> inLt1;
  input HashTableCrToUnit.HashTable inHtCr2U2;
  input HashTableUnitToString.HashTable inHtU2S;
  output String outS;

algorithm
  outS := matchcontinue(inLt1, inHtCr2U2, inHtU2S)
    local
      String s1, s2;
      list<tuple<DAE.ComponentRef, Unit.Unit>> lt1;
      tuple<DAE.ComponentRef, Unit.Unit> t1;
      DAE.ComponentRef cr1;
      Real factor1;
      Integer i1, i2, i3, i4, i5, i6, i7;

    case ({}, _, _)
    then "";

    case (t1::lt1, _, _) equation
      (cr1, Unit.MASTER())=t1;
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)=BaseHashTable.get(cr1, inHtCr2U2);
      s1="\"" + ComponentReference.crefStr(cr1) + "\" has the Unit \"" + unit2String(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtU2S) + "\"" + "\n";
      s2=notification2(lt1, inHtCr2U2, inHtU2S);
    then s1 + s2;

    case (_::lt1, _, _) equation
      s1 = notification2(lt1, inHtCr2U2, inHtU2S);
    then s1;
  end matchcontinue;
end notification2;

//
//
protected function insertUnitInEquation "inserts the units in Equation and check if the equation is consistent or not"
  input DAE.Exp inEq;
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, HashTableStringToUnit.HashTable /* inHtS2U */, HashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  input Unit.Unit inUt;
  output Unit.Unit outUt;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
  output list<list<tuple<DAE.Exp, Unit.Unit>>> outexpList;
algorithm
  (outUt, outTpl, outexpList) := matchcontinue(inEq, inTpl, inUt)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp1, exp2, exp3;
      DAE.Type ty;
      HashTableCrToUnit.HashTable HtCr2U;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      Integer i, i1, i2, i3, i4, i5, i6, i7;
      list<DAE.ComponentRef> lcr, lcr2;
      list<DAE.Exp> ExpList;
      list<list<tuple<DAE.Exp, Unit.Unit>>> expListList, expListList2, expListList3;
      Real factor1;
      Real r;
      String s1, s2;
      Unit.Unit ut, ut2;

    //SUB equal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList=listAppend(expListList, expListList2);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //SUB equal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList=listAppend(expListList, expListList2);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //SUB unequal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //SUB unequal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //ADD equal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //ADD equal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //ADD unequal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //ADD unequal
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //MUL
    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      //s1="(" + unit2String(ut, HtU2S) + ").(" + unit2String(ut2, HtU2S) + ")";
      ut = unitMul(ut, ut2);
      s1 = unit2String(ut, HtU2S);
      expListList = listAppend(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      expListList = listAppend(expListList, expListList2);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      //s1="(" + unit2String(inUt, HtU2S) + ")/(" + unit2String(ut2, HtU2S) + ")";
      ut = unitDiv(inUt, ut2);
      s1 = unit2String(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      expListList = listAppend(expListList, expListList2);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      //s1="(" + unit2String(inUt, HtU2S) + ")/(" + unit2String(ut2, HtU2S) + ")";
      ut = unitDiv(inUt, ut2);
      s1 = unit2String(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), _) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //DIV
    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      //s1="(" + unit2String(ut, HtU2S) + ")/(" + unit2String(ut2, HtU2S) + ")";
      ut = unitDiv(ut, ut2);
      s1 = unit2String(ut, HtU2S);
      expListList = listAppend(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      expListList = listAppend(expListList, expListList2);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      //s1="(" + unit2String(inUt, HtU2S) + ").(" + unit2String(ut2, HtU2S) + ")";
      ut = unitMul(inUt, ut2);
      s1 = unit2String(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      expListList = listAppend(expListList, expListList2);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      //s1="(" + unit2String(ut2, HtU2S) + ")/(" + unit2String(inUt, HtU2S) + ")";
      ut = unitDiv(ut2, inUt);
      s1 = unit2String(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      expListList = listAppend(expListList, expListList2);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //POW
    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(r)), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      i = realInt(r);
      true = realEq(r, intReal(i));
      ut = unitPow(ut, i);
      s1 = unit2String(ut, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(r)), (HtCr2U, HtS2U, HtU2S), ut as Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = unitRoot(ut, r);
      HtCr2U = List.fold1(lcr, updateHtCr2U, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtCr2U);
      s1 = unit2String(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(_)), (HtCr2U, HtS2U, HtU2S), _) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //DER
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      ut = unitMul(inUt, Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      s1 = unit2String(inUt, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList)=insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      ut=unitDiv(ut, Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      s1=unit2String(ut, HtU2S);
      HtS2U=addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S=addUnit2HtU2S((s1, ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //SQRT
    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = unitRoot(ut, 2.0);
      s1 = unit2String(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      ut = unitPow(inUt, 2);
      s1 = unit2String(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //IFEXP
    case (DAE.IFEXP(exp1, exp2, exp3), (HtCr2U, HtS2U, HtU2S), _) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList3) = insertUnitInEquation(exp3, (HtCr2U, HtS2U, HtU2S), ut);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      expListList = listAppend(expListList, expListList3);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.IFEXP(exp1, exp2, exp3), (HtCr2U, HtS2U, HtU2S), _) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList3) = insertUnitInEquation(exp3, (HtCr2U, HtS2U, HtU2S), ut);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      expListList = listAppend(expListList, expListList3);
      expListList = {(exp2, ut), (exp3, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //RELATIONS
    case (DAE.RELATION(exp1=exp1), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.RELATION(exp1=exp1, exp2=exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //all other BINARIES
    case (DAE.BINARY(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

    //LBINARY
    case (DAE.LBINARY(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

    //LUNARY
    case (DAE.LUNARY(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

    //MATRIX
    case (DAE.MATRIX(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

    //ARRAY
    case (DAE.ARRAY(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

    //CALL
    case (DAE.CALL(expLst=ExpList), (HtCr2U, HtS2U, HtU2S), _) equation
      (HtCr2U, HtS2U, HtU2S, expListList) = foldCallArg(ExpList, HtCr2U, HtS2U, HtU2S);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //UMINUS
    case (DAE.UNARY(DAE.UMINUS(), exp1), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //ICONST
    case (DAE.ICONST(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

    //BCONST
    case (DAE.BCONST(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

    //SCONST
    case (DAE.SCONST(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

    //RCONST
    case (DAE.RCONST(), (HtCr2U, HtS2U, HtU2S), _)
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

    //"time"
    case (DAE.CREF(componentRef=cr), (HtCr2U, HtS2U, HtU2S), _) equation
      true = ComponentReference.crefEqual(cr, DAE.crefTime);
      ut = Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0);
      HtS2U = addUnit2HtS2U(("time", ut), HtS2U);
      HtU2S = addUnit2HtU2S(("time", ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), {});

    //CREF
    case (DAE.CREF(componentRef=cr, ty=DAE.T_REAL()), (HtCr2U, _, _), _) equation
      ut = BaseHashTable.get(cr, HtCr2U);
    then (ut, inTpl, {});

    //NO UNIT IN EQUATION
    case (DAE.CREF(), _, _)
    then (Unit.MASTER({}), inTpl, {});

    // all unhandled expressions, e.g. DAE.CAST, DAE.TUPLE, ...
    else
      //Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: function insertUnitInEquation failed for " + ExpressionDump.printExpStr(inEq), sourceInfo());
    //then fail();
    then (Unit.MASTER({}), inTpl, {});
  end matchcontinue;
end insertUnitInEquation;

//
//
protected function foldCallArg "help-function for CALL case in function insertUnitInEquation"
  input list<DAE.Exp> inExpList;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output HashTableCrToUnit.HashTable outHtCr2U = inHtCr2U;
  output HashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output HashTableUnitToString.HashTable outHtU2S = inHtU2S;
  output list<list<tuple<DAE.Exp, Unit.Unit>>> outExpListList = {};
protected
  list<list<tuple<DAE.Exp, Unit.Unit>>> expListList;
algorithm
  for exp in inExpList loop
    (_, (outHtCr2U, outHtS2U, outHtU2S), expListList) :=
      insertUnitInEquation(exp, (outHtCr2U, outHtS2U, outHtU2S), Unit.MASTER({}));
    outExpListList := List.append_reverse(expListList, outExpListList);
  end for;

  outExpListList := listReverse(outExpListList);
end foldCallArg;

//
//
protected function UnitTypesEqual "checks equality of two UnitExp's"
  input Unit.Unit inut;
  input Unit.Unit inut2;
  input HashTableCrToUnit.HashTable inHtCr2U;
  output Boolean b;
  output Unit.Unit outUt;
  output HashTableCrToUnit.HashTable outHtCr2U;
algorithm
  (b, outUt, outHtCr2U) := matchcontinue(inut, inut2, inHtCr2U)
    local
      String s, s2;
      Integer i1, i2, i3, i4, i5, i6, i7;
      Integer j1, j2, j3, j4, j5, j6, j7;
      list<DAE.ComponentRef> lcr, lcr2;
      HashTableCrToUnit.HashTable HtCr2U;
      Real factor1, factor2, r;
      Unit.Unit ut;

    case (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), Unit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7), _) equation
      true = realEq(factor1,factor2);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then (true, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtCr2U);

    case (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), Unit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7), _) equation
      r=realMax(realAbs(factor1), realAbs(factor2));
      true = realLe(realDiv(realAbs(realSub(factor1,factor2)),r),1e-3);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then (true, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtCr2U);

    case (ut as Unit.UNIT(), Unit.MASTER(lcr), _) equation
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, inHtCr2U);
    then (true, ut , HtCr2U);

    case (Unit.MASTER(lcr), ut as Unit.UNIT(), _) equation
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, inHtCr2U);
    then (true, ut, HtCr2U);

    case (Unit.MASTER(lcr), Unit.MASTER(lcr2), _) equation
      lcr2 = listAppend(lcr, lcr2);
    then (true, Unit.MASTER(lcr2), inHtCr2U);

    case (Unit.UNKNOWN(s), Unit.UNKNOWN(s2), _) equation
      true = stringEqual(s, s2);
    then (true, Unit.UNKNOWN(s), inHtCr2U);

    case (Unit.UNKNOWN(s), _, _) then (true, Unit.UNKNOWN(s), inHtCr2U);
    case (_, Unit.UNKNOWN(s), _) then (true, Unit.UNKNOWN(s), inHtCr2U);

    else (false, inut, inHtCr2U);
  end matchcontinue;
end UnitTypesEqual;

protected function updateHtCr2U
  input DAE.ComponentRef inCr;
  input Unit.Unit inUt;
  input HashTableCrToUnit.HashTable inHtCr2U;
  output HashTableCrToUnit.HashTable outHtCr2U;
algorithm
  outHtCr2U:=matchcontinue(inCr, inUt, inHtCr2U)
  local
    DAE.ComponentRef cr;
    HashTableCrToUnit.HashTable HtCr2U;

  case (_,_,_)
    equation
      true = BaseHashTable.hasKey(Unit.UPDATECREF, inHtCr2U);
      BaseHashTable.update((inCr,inUt),inHtCr2U);
    then inHtCr2U;

  else
    equation
      HtCr2U = BaseHashTable.add((Unit.UPDATECREF, Unit.MASTER({})),inHtCr2U);
      BaseHashTable.update((inCr,inUt),HtCr2U);
    then HtCr2U;

  end matchcontinue;
end updateHtCr2U;

//
//
protected function convertUnitString2unit "converts String to unit"
  input BackendDAE.Var var;
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, HashTableStringToUnit.HashTable /* HtS2U */, HashTableUnitToString.HashTable /* HtU2S */> inTpl;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* HtS2U */, HashTableUnitToString.HashTable /* HtU2S */> outTpl;

algorithm
  outTpl := matchcontinue(var, inTpl)

  local
    String unitString, s;
    list<String> listStr;
    DAE.ComponentRef cr;
    Unit.Unit ut;
    HashTableStringToUnit.HashTable HtS2U;
    HashTableUnitToString.HashTable HtU2S;
    HashTableCrToUnit.HashTable HtCr2U;

  case (BackendDAE.VAR(varType=DAE.T_REAL(), values = SOME(DAE.VAR_ATTR_REAL(unit=SOME(DAE.SCONST(unitString))))), (HtCr2U, HtS2U, HtU2S))
    guard(unitString <> "")
    equation
      cr = BackendVariable.varCref(var);
      (ut, HtS2U, HtU2S) = parse(unitString, cr, HtS2U, HtU2S);
      HtCr2U = BaseHashTable.add((cr,ut),HtCr2U);
  then ((HtCr2U, HtS2U, HtU2S));

  //case NO UNIT
  case (BackendDAE.VAR(varType=DAE.T_REAL()), (HtCr2U, HtS2U, HtU2S))
    equation
      cr = BackendVariable.varCref(var);
      HtCr2U = BaseHashTable.add((cr,Unit.MASTER({cr})),HtCr2U);
      HtS2U = addUnit2HtS2U(("-",Unit.MASTER({cr})),HtS2U);
      HtU2S = addUnit2HtU2S(("-",Unit.MASTER({cr})),HtU2S);
  then ((HtCr2U, HtS2U, HtU2S));

  else inTpl; //skip Non-Real Variables

  end matchcontinue;
end convertUnitString2unit;

//
//
protected function token2string
  input Token inToken;
  output String outString;
algorithm
  outString := match(inToken)
    local
      String s;
      Integer i;

    case T_UNIT(s) then s;
    case T_NUMBER(i) then intString(i);
    case T_LPAREN() then "(";
    case T_RPAREN() then ")";
    case T_MUL() then "*";
    case T_DIV() then "/";
    else "<UNKNOWN TOKEN>";
  end match;
end token2string;

//
//
protected function tokenList2string
  input list<Token> inListString;
  input String inDeliminator;
  output String outString;
algorithm
  outString := match(inListString, inDeliminator)
    local
      Token curr;
      String str;
      list<Token> rest;

    case ({}, _)
    then "";

    case (curr::{}, _)
    then token2string(curr);

    case (curr::rest, _) equation
      str = token2string(curr) + inDeliminator + tokenList2string(rest, inDeliminator);
    then str;
  end match;
end tokenList2string;

//
//
protected function parse "author: lochel"
  input String inUnitString;
  input DAE.ComponentRef inCref;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output Unit.Unit outUnit;
  output HashTableStringToUnit.HashTable outHtS2U;
  output HashTableUnitToString.HashTable outHtU2S;
algorithm
  (outUnit, outHtS2U, outHtU2S):=matchcontinue(inUnitString, inCref, inHtS2U, inHtU2S)

  local
    Unit.Unit unit;
    HashTableStringToUnit.HashTable HtS2U;
    HashTableUnitToString.HashTable HtU2S;
    list<String> charList;
    list<Token> tokenList;


  case (_, _, _, _) equation
    unit=BaseHashTable.get(inUnitString, inHtS2U);
  then (unit, inHtS2U, inHtU2S);

  else equation
    charList = stringListStringChar(inUnitString);
    tokenList = lexer(charList);
    unit = parser(tokenList, inCref, inHtS2U);
    HtS2U = addUnit2HtS2U((inUnitString, unit), inHtS2U);
    HtU2S = addUnit2HtU2S((inUnitString, unit), inHtU2S);
  then (unit, HtS2U, HtU2S);
  end matchcontinue;
end parse;

//
//
protected function parser "author: lochel"
  input list<Token> inTokenList;
  input DAE.ComponentRef inCref;
  input HashTableStringToUnit.HashTable inHtS2U;
  output Unit.Unit outUnit;
algorithm
  outUnit := matchcontinue(inTokenList, inCref, inHtS2U)
    local
      String str;

    case (_, _, _) then parser2(inTokenList, inCref, inHtS2U);

    else equation
      str = tokenList2string(inTokenList, "");
    then Unit.UNKNOWN(str);
  end matchcontinue;
end parser;

//
//
protected function parser2
  input list<Token> inTokenList;
  input DAE.ComponentRef inCref;
  input HashTableStringToUnit.HashTable inHtS2U;
  output Unit.Unit outUnit;
algorithm
  outUnit := match(inTokenList, inCref, inHtS2U)
    local
      String str;
      Unit.Unit unit;
      list<Token> tokens;

    // no unit
    case ({}, _, _)
    then Unit.MASTER({inCref});

    else equation
      unit = parser3({true, true}, inTokenList, Unit.UNIT(1e0, 0, 0, 0, 0, 0, 0, 0), inHtS2U);
    then unit;
  end match;
end parser2;

//
//
protected function parser3
  input list<Boolean> inMul "true=Mul, false=Div, initial call with true";
  input list<Token> inTokenList "Tokenliste";
  input Unit.Unit inUnit "initial call with UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)";
  input HashTableStringToUnit.HashTable inHtS2U;
  output Unit.Unit outUnit;
algorithm
  outUnit := matchcontinue(inMul, inTokenList, inUnit, inHtS2U)
    local
      String s, s1, s2, unit;
      list<Token> tokens;
      Unit.Unit ut;
      Integer exponent;
      Boolean bMul, b;
      list<Boolean> bRest;

    // ""
    case ({true}, {}, _, _) then inUnit;

    // "1"
    case (bMul::bRest, T_NUMBER(number=1)::tokens, _, _) equation
      ut = Unit.UNIT(1e0, 0, 0, 0, 0, 0, 0, 0/* , 0e0 */);
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

//
//
protected function unitToken2unit
  input String inS;
  input HashTableStringToUnit.HashTable inHtS2U;
  output Unit.Unit outUnit;
algorithm
  outUnit := matchcontinue(inS, inHtS2U)
    local
      String s, s2;
      Real r;
      Unit.Unit ut;

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

//
//
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

//
//
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

//
//
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

//
//
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

//
//
protected function unitMul
  input Unit.Unit inUt1;
  input Unit.Unit inUt2;
  output Unit.Unit outUt;
protected
  Real factor1, factor2, shift1, shift2;
  Integer i1, i2, i3, i4, i5, i6, i7;
  Integer j1, j2, j3, j4, j5, j6, j7;
algorithm
  Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) := inUt1;
  Unit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7) := inUt2;
  factor1 := factor1 * factor2;
  i1 := i1+j1;
  i2 := i2+j2;
  i3 := i3+j3;
  i4 := i4+j4;
  i5 := i5+j5;
  i6 := i6+j6;
  i7 := i7+j7;
  outUt := Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7);
end unitMul;

//
//
protected function unitDiv
  input Unit.Unit inUt1;
  input Unit.Unit inUt2;
  output Unit.Unit outUt;
protected
  Real factor1, factor2, shift1, shift2;
  Integer i1, i2, i3, i4, i5, i6, i7;
  Integer j1, j2, j3, j4, j5, j6, j7;
algorithm
  Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) := inUt1;
  Unit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7) := inUt2;
  factor1 := factor1 / factor2;
  i1 := i1-j1;
  i2 := i2-j2;
  i3 := i3-j3;
  i4 := i4-j4;
  i5 := i5-j5;
  i6 := i6-j6;
  i7 := i7-j7;
  outUt := Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7);
end unitDiv;

//
//
protected function unitPow
  input Unit.Unit inUt;
  input Integer inExp "exponent";
  output Unit.Unit outUt;
protected
  Real factor, shift;
  Integer i1, i2, i3, i4, i5, i6, i7;
algorithm
  Unit.UNIT(factor, i1, i2, i3, i4, i5, i6, i7) := inUt;
  factor:=realPow(factor, intReal(inExp));
  i1 := i1*inExp;
  i2 := i2*inExp;
  i3 := i3*inExp;
  i4 := i4*inExp;
  i5 := i5*inExp;
  i6 := i6*inExp;
  i7 := i7*inExp;
  outUt := Unit.UNIT(factor, i1, i2, i3, i4, i5, i6, i7);
end unitPow;

//
//
protected function unitMulReal
  input Unit.Unit inUt;
  input Real inFactor;
  output Unit.Unit outUt;
protected
  Real factor, shift;
  Integer i1, i2, i3, i4, i5, i6, i7;
algorithm
  Unit.UNIT(factor, i1, i2, i3, i4, i5, i6, i7) := inUt;
  factor := factor * inFactor;
  outUt := Unit.UNIT(factor, i1, i2, i3, i4, i5, i6, i7);
end unitMulReal;

//
//
protected function unitRoot
  input Unit.Unit inUt;
  input Real inExponent;
  output Unit.Unit outUt;
algorithm
  outUt := match(inUt, inExponent)
    local
      Real factor1, r, r1, r2, r3, r4, r5, r6, r7;
      Real q1, q2, q3, q4, q5, q6, q7;
      Integer i, i1, i2, i3, i4, i5, i6, i7;
      Integer j1, j2, j3, j4, j5, j6, j7;

    case (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), r) equation
      i = realInt(r);
      r1 = realDiv(1.0, r);
      factor1 = realPow(factor1, r1);

      j1 = intDiv(i1, i);
        r1 = intReal(i1);
        r1 = realDiv(r1, r);
      q1 = intReal(j1);
      true = realEq(r1, q1);

      j2 = intDiv(i2, i);
        r2 = intReal(i2);
        r2 = realDiv(r2, r);
      q2 = intReal(j2);
      true = realEq(r2, q2);

      j3 = intDiv(i3, i);
        r3 = intReal(i3);
        r3 = realDiv(r3, r);
      q3 = intReal(j3);
      true = realEq(r3, q3);

      j4 = intDiv(i4, i);
        r4 = intReal(i4);
        r4 = realDiv(r4, r);
      q4 = intReal(j4);
      true = realEq(r4, q4);

      j5 = intDiv(i5, i);
        r5 = intReal(i5);
        r5 = realDiv(r5, r);
      q5 = intReal(j5);
      true = realEq(r5, q5);

      j6 = intDiv(i6, i);
        r6 = intReal(i6);
        r6 = realDiv(r6, r);
      q6 = intReal(j6);
      true = realEq(r6, q6);

      j7 = intDiv(i7, i);
        r7 = intReal(i7);
        r7 = realDiv(r7, r);
      q7 = intReal(j7);
      true = realEq(r7, q7);
    then Unit.UNIT(factor1, j1, j2, j3, j4, j5 , j6, j7);

    else fail();
  end match;
end unitRoot;

annotation(__OpenModelica_Interface="backend");
end UnitCheck;
