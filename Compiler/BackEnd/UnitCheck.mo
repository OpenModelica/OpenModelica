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

public
import Absyn;
import BackendDAE;
import DAE;
import Unit;

protected
import BackendDump;
import BackendEquation;
import BackendVariable;
import BackendDAEUtil;
import BaseHashTable;
import ComponentReference;
import Error;
import Expression;
import ExpressionDump;
import Flags;
import HashTableCrToUnit;
import HashTableStringToUnit;
import HashTableUnitToString;
import List;

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
  BackendDAE.Variables orderedVars, globalKnownVars, aliasVars;
  HashTableCrToUnit.HashTable HtCr2U1, HtCr2U2;
  HashTableStringToUnit.HashTable HtS2U;
  HashTableUnitToString.HashTable HtU2S;
  list<BackendDAE.Equation> eqList;
  list<BackendDAE.Var> varList, paraList, aliasList;
algorithm
  try
    BackendDAE.DAE({syst}, shared) := inDAE;

    varList := BackendVariable.varList(syst.orderedVars);
    paraList := BackendVariable.varList(shared.globalKnownVars);
    aliasList := BackendVariable.varList(shared.aliasVars);
    eqList := BackendEquation.equationList(syst.orderedEqs);

    HtCr2U1 := HashTableCrToUnit.emptyHashTableSized(2053);
    HtS2U := Unit.getKnownUnits();
    HtU2S := Unit.getKnownUnitsInverse();

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
    globalKnownVars := BackendVariable.listVar(paraList);
    aliasVars := BackendVariable.listVar(aliasList);

    syst := BackendDAEUtil.setEqSystVars(syst, orderedVars);
    shared := BackendDAEUtil.setSharedGlobalKnownVars(shared, globalKnownVars);
    shared := BackendDAEUtil.setSharedAliasVars(shared, aliasVars);
    outDAE := BackendDAE.DAE({syst}, shared);
  else
    // if Flags.getConfigBool(Flags.NEW_UNIT_CHECKING) then
    //   Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: unit check module failed");
    // end if;
    outDAE := inDAE;
  end try;
end unitChecking;

protected function addUnit2HtS2U
  input tuple<String, Unit.Unit> inTpl;
  input HashTableStringToUnit.HashTable inHtS2U;
  output HashTableStringToUnit.HashTable outHtS2U;
algorithm
  outHtS2U := BaseHashTable.add(inTpl,inHtS2U);
end addUnit2HtS2U;

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
  outVar := match(inVar)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      Unit.Unit ut;
      String s;

    case BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(unit=SOME(_))))
    then inVar;

    else equation
      cr = BackendVariable.varCref(inVar);
      ut = BaseHashTable.get(cr, inHtCr2U);
      if Unit.isUnit(ut) then
        s = Unit.unitString(ut, inHtU2S);
        var = BackendVariable.setUnit(inVar, DAE.SCONST(s));
      else
        var = inVar;
      end if;
    then var;
  end match;
end returnVar;

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
      s1 = Unit.unitString(ut, inHtU2S);
      s = "- sub-expression \"" + s + "\" has unit \"" + s1 + "\"";
    then s;

    case ((exp, ut)::expList, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = Unit.unitString(ut, inHtU2S);
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
      s1="\"" + ComponentReference.crefStr(cr1) + "\" has the Unit \"" + Unit.unitString(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtU2S) + "\"" + "\n";
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
      //s1="(" + Unit.unitString(ut, HtU2S) + ").(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitMul(ut, ut2);
      s1 = Unit.unitString(ut, HtU2S);
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
      //s1="(" + Unit.unitString(inUt, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitDiv(inUt, ut2);
      s1 = Unit.unitString(ut, HtU2S);
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
      //s1="(" + Unit.unitString(inUt, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitDiv(inUt, ut2);
      s1 = Unit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = listAppend(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      expListList = listAppend(expListList, expListList2);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //DIV
    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      //s1="(" + Unit.unitString(ut, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitDiv(ut, ut2);
      s1 = Unit.unitString(ut, HtU2S);
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
      //s1="(" + Unit.unitString(inUt, HtU2S) + ").(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitMul(inUt, ut2);
      s1 = Unit.unitString(ut, HtU2S);
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
      //s1="(" + Unit.unitString(ut2, HtU2S) + ")/(" + Unit.unitString(inUt, HtU2S) + ")";
      ut = Unit.unitDiv(ut2, inUt);
      s1 = Unit.unitString(ut, HtU2S);
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
      ut = Unit.unitPow(ut, i);
      s1 = Unit.unitString(ut, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(r)), (HtCr2U, HtS2U, HtU2S), ut as Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = Unit.unitRoot(ut, r);
      HtCr2U = List.fold1(lcr, updateHtCr2U, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtCr2U);
      s1 = Unit.unitString(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(_)), (HtCr2U, HtS2U, HtU2S), _) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //DER
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      ut = Unit.unitMul(inUt, Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      s1 = Unit.unitString(ut, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList)=insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      ut=Unit.unitDiv(ut, Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      s1=Unit.unitString(ut, HtU2S);
      HtS2U=addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S=addUnit2HtU2S((s1, ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //SQRT
    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = Unit.unitRoot(ut, 2.0);
      s1 = Unit.unitString(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}));
      ut = Unit.unitPow(inUt, 2);
      s1 = Unit.unitString(ut, HtU2S);
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

protected function parse "author: lochel"
  input String inUnitString;
  input DAE.ComponentRef inCref;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output Unit.Unit outUnit;
  output HashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output HashTableUnitToString.HashTable outHtU2S = inHtU2S;
algorithm
  try
    outUnit := BaseHashTable.get(inUnitString, inHtS2U);
  else
    outUnit := matchcontinue(inUnitString)
      case ""
      then Unit.MASTER({inCref});

      case _
      then Unit.parseUnitString(inUnitString, inHtS2U);

      else Unit.UNKNOWN(inUnitString);
    end matchcontinue;
    outHtS2U := addUnit2HtS2U((inUnitString, outUnit), outHtS2U);
    outHtU2S := addUnit2HtU2S((inUnitString, outUnit), outHtU2S);
  end try;
end parse;

annotation(__OpenModelica_Interface="backend");
end UnitCheck;
