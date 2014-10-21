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

               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)

  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import FCore;
protected import Flags;
protected import List;
protected import Util;

public uniontype Token
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

protected constant list<tuple<String, Unit>> LU_COMPLEXUNITS = {
/*                 fac, mol, cd, m, s, A, K, g*/
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
//("Bq",         UNIT(1e0, 0, 0, 0,-1, 0, 0, 0)), //Becquerel
  ("kg",         UNIT(1e3, 0, 0, 0, 0, 0, 0, 1)), //Kilogramm
//("Bq",         UNIT(1e0, 0, 0, 0,-1, 0, 0, 0)), //Becquerel = Hertz
//("Gy",         UNIT(1e0, 0, 0, 2,-2, 0, 0, 1)), //Gray
//("Sv",         UNIT(1e0, 0, 0, 2,-2, 0, 0, 1)), //Sievert=Gray
//("eV", UNIT(1.60218e-16, 0, 0, 2,-2, 0, 0, 1)), //Elektronenvolt    1, 602...*10^-19 kg*m^2/s^2
//("R",      UNIT(2.58e-7, 0, 0, 0, 1, 1, 0,-1)), //Röntgen    2, 58*10^-4 C/kg
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

// =============================================================================
// section for preOptModule >>unitChecking<<
// The unit check module verifies the consistency of units.
//
// =============================================================================

public function unitChecking "author: jhagemann"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.EqSystems eqs_;
      BackendDAE.Shared shared;
      BackendDAE.Variables orderedVars, knownVars, aliasVars, externalObjects;
      BackendDAE.EquationArray orderedEqs, initialEqs, removedEqs;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets ;
      BackendDAE.BaseClockPartitionKind partitionKind;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttrs;
      FCore.Cache cache;
      FCore.Graph graph;
      DAE.FunctionTree functionTree;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      BackendDAE.BackendDAEType backendDAEType;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.ExtraInfo info;

      list<BackendDAE.Var> varList, paraList, aliasList;
      list<BackendDAE.Equation> eqList;
      list<tuple<DAE.ComponentRef, Unit>> lt, lt2;
      list<tuple<String, Unit>> ComplexUnits;
      Boolean b;
      String s;

    case BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars, orderedEqs, m, mT, matching, stateSets, partitionKind)}, shared as BackendDAE.SHARED(knownVars, externalObjects, aliasVars, initialEqs, removedEqs, constraints, classAttrs, cache, graph, functionTree, eventInfo, extObjClasses, backendDAEType, symjacs, info)) equation
      true = Flags.getConfigBool(Flags.NEW_UNIT_CHECKING);

      varList = BackendVariable.varList(orderedVars);
      paraList = BackendVariable.varList(knownVars);
      aliasList = BackendVariable.varList(aliasVars);
      eqList = BackendEquation.equationList(orderedEqs);

      Debug.fcall2(Flags.DUMP_EQ_UNIT, BackendDump.dumpEquationList, eqList, "########### Equation-Liste: #########\n");
      ((lt, ComplexUnits)) = List.fold(varList, convertUnitString2unit, ({}, LU_COMPLEXUNITS));
      ((lt, ComplexUnits)) = List.fold(paraList, convertUnitString2unit, (lt, ComplexUnits));
      ((lt, ComplexUnits)) = List.fold(aliasList, convertUnitString2unit, (lt, ComplexUnits));
      Debug.fcall2(Flags.DUMP_UNIT, printListTuple, lt, ComplexUnits);
      Debug.fcall(Flags.DUMP_UNIT, print, "#####################################\n");

      ((lt2, ComplexUnits)) = algo(paraList, eqList, lt, ComplexUnits);
      Debug.fcall2(Flags.DUMP_UNIT, printListTuple, lt2, ComplexUnits);
      Debug.fcall(Flags.DUMP_UNIT, print, "######## UnitCheck COMPLETED ########\n");

      s = notification(lt, lt2, lt2, ComplexUnits);
      Debug.fcall(Flags.DUMP_UNIT, Error.addCompilerNotification, s);
      varList = List.map2(varList, returnVar, lt2, ComplexUnits);
      paraList = List.map2(paraList, returnVar, lt2, ComplexUnits);
      aliasList = List.map2(aliasList, returnVar, lt2, ComplexUnits);

      orderedVars = BackendVariable.listVar(varList);
      knownVars = BackendVariable.listVar(paraList);
      aliasVars = BackendVariable.listVar(aliasList);
      shared = BackendDAE.SHARED(knownVars, externalObjects, aliasVars, initialEqs, removedEqs, constraints, classAttrs, cache, graph, functionTree, eventInfo, extObjClasses, backendDAEType, symjacs, info);
      dae = BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars, orderedEqs, m, mT, matching, stateSets, partitionKind)}, shared);
    then dae;

    //case _ equation
    //  true = Flags.getConfigBool(Flags.NEW_UNIT_CHECKING);
    //  Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: unit check module failed");
    //then inDAE;

    else inDAE;
  end matchcontinue;
end unitChecking;

//
//
protected function returnVar "returns the new calculated units in DAE"
  input BackendDAE.Var inVar;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<String, Unit>> inComplexUnits;
  output BackendDAE.Var outVar;
algorithm
  outVar := match(inVar, inLt, inComplexUnits)
    local
      list<tuple<DAE.ComponentRef, Unit>> lt;
      BackendDAE.Var var;
      DAE.ComponentRef cr;

    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(unit=SOME(_)))), _, _)
    then inVar;

    else equation
      var = returnVar2(inLt, inVar, inComplexUnits);
    then var;
  end match;
end returnVar;

//
//
protected function returnVar2 "help-function"
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input BackendDAE.Var inVar;
  input list<tuple<String, Unit>> inComplexUnits;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(inLt, inVar, inComplexUnits)
    local
      list<tuple<DAE.ComponentRef, Unit>> lt;
      DAE.ComponentRef cr, cr2;
      String s;
      BackendDAE.Var var;
      Unit ut;

    case ({}, _, _)
    then inVar;

    case((cr, MASTER(varList=_))::lt, _, _) equation
      var=returnVar2(lt, inVar, inComplexUnits);
    then var;

    case ((cr, UNIT(factor=_))::lt, _, _) equation
      cr2=BackendVariable.varCref(inVar);
      false=ComponentReference.crefEqual(cr, cr2);
      var=returnVar2(lt, inVar, inComplexUnits);
    then var;

    case ((cr, ut as UNIT(factor=_))::lt, _, _) equation
      cr2=BackendVariable.varCref(inVar);
      true=ComponentReference.crefEqual(cr, cr2);
      s=unit2String(ut, inComplexUnits, inLt);
      var=BackendVariable.setUnit(inVar, DAE.SCONST(s));
    then var;

    else inVar; //if unit2String fails
  end matchcontinue;
end returnVar2;

//
//
protected function unit2String "transforms the unit in string"
  input Unit inUt;
  input list<tuple<String, Unit>> inComplexUnits;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  output String outS;
algorithm
  outS := matchcontinue(inUt, inComplexUnits, inLt)
    local
      String s, s1, s2, s3, s4, s5, s6, s7, sExponent;
      Integer prefix, exponent, i1, i2, i3, i4, i5, i6, i7;
      Real factor1;
      Boolean b;

    case (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), _, _) equation
      s = findUnitRev(UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inComplexUnits, inLt);
    then s;

    case (UNIT(1.0, i1, i2, i3, i4, i5, i6, i7), _, _) equation
      b = false;

      sExponent=Util.if_(intEq(i1, 1), "", intString(i1));
      s1="mol" +& sExponent;
      s1=Util.if_(intEq(i1, 0), "", s1);
      b=b or intNe(i1, 0);

      s2=Util.if_(b and intNe(i2, 0), ".", "");
      sExponent=Util.if_(intEq(i2, 1), "", intString(i2));
      s2=s2 +& "cd" +& sExponent;
      s2=Util.if_(intEq(i2, 0), "", s2);
      b=b or intNe(i2, 0);

      s3=Util.if_(b and intNe(i3, 0), ".", "");
      sExponent=Util.if_(intEq(i3, 1), "", intString(i3));
      s3=s3 +& "m" +& sExponent;
      s3=Util.if_(intEq(i3, 0), "", s3);
      b=b or intNe(i3, 0);

      s4=Util.if_(b and intNe(i4, 0), ".", "");
      sExponent=Util.if_(intEq(i4, 1), "", intString(i4));
      s4=s4 +& "s" +& sExponent;
      s4=Util.if_(intEq(i4, 0), "", s4);
      b=b or intNe(i4, 0);

      s5=Util.if_(b and intNe(i5, 0), ".", "");
      sExponent=Util.if_(intEq(i5, 1), "", intString(i5));
      s5=s5 +& "A" +& sExponent;
      s5=Util.if_(intEq(i5, 0), "", s5);
      b=b or intNe(i5, 0);

      s6=Util.if_(b and intNe(i6, 0), ".", "");
      sExponent=Util.if_(intEq(i6, 1), "", intString(i6));
      s6=s6 +& "K" +& sExponent;
      s6=Util.if_(intEq(i6, 0), "", s6);
      b=b or intNe(i6, 0);

      s7=Util.if_(b and intNe(i7, 0), ".", "");
      sExponent=Util.if_(intEq(i7, 1), "", intString(i7));
      s7=s7 +& "g" +& sExponent;
      s7=Util.if_(intEq(i7, 0), "", s7);
      b=b or intNe(i7, 0);
      s=s1 +& s2 +& s3 +& s4 +& s5 +& s6 +& s7;
      s=Util.if_(b, s, "1");
    then s;

    else equation
      Error.addCompilerWarning("function unit2String failed: \"" +& unit2string(inUt) +&"\" can not return in DAE!!!");
    then unit2string(inUt);
  end matchcontinue;
end unit2String;

//
//
protected function match2Lists "matchs two lists if they are equal or not"
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<DAE.ComponentRef, Unit>> inLt2;
  output Boolean outB;
algorithm
  outB := matchcontinue(inLt, inLt2)
    local
      list<tuple<DAE.ComponentRef, Unit>> lt, lt2;
      tuple<DAE.ComponentRef, Unit> t, t2;
      Unit ut, ut2;
      Boolean b;
      list<DAE.ComponentRef> lcr, lcr2;
      list<String> strList;
      String s, s2;
      Integer i1, i2, i3, i4, i5, i6, i7;
      Integer j1, j2, j3, j4, j5, j6, j7;
      Real factor1, factor2;

    case ({}, {})
    then true;

    case ((t::lt), (t2::lt2)) equation
      (_, ut)=t;
      (_, ut2)=t2;
      UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)=ut;
      UNIT(factor2, j1, j2, j3, j4, j5, j6, j7)=ut;
      true=realEq(factor1, factor2);
      true=intEq(i1, j1);
      true=intEq(i2, j2);
      true=intEq(i3, j3);
      true=intEq(i4, j4);
      true=intEq(i5, j5);
      true=intEq(i6, j6);
      true=intEq(i7, j7);
      b=match2Lists(lt, lt2);
    then (b);

    case ((t::lt), (t2::lt2)) equation
      (_, ut)=t;
      (_, ut2)=t2;
      MASTER(lcr)=ut;
      MASTER(lcr2)=ut2;
      true=match2Lists2(lcr, lcr2);
      b=match2Lists(lt, lt2);
    then b;

    case ((t::lt), (t2::lt2)) equation
      (_, ut)=t;
      (_, ut2)=t2;
      UNKNOWN(s)=ut;
      UNKNOWN(s2)=ut2;
      true=stringEqual(s, s2);
      b=match2Lists(lt, lt2);
    then b;

    else false;
  end matchcontinue;
end match2Lists;

//
//
protected function match2Lists2 "help-function"
  input list<DAE.ComponentRef> inlCr;
  input list<DAE.ComponentRef> inlCr2;
  output Boolean outB;
algorithm
  outB := matchcontinue(inlCr, inlCr2)
    local
      list<DAE.ComponentRef> lcr, lcr2;
      DAE.ComponentRef cr, cr2;
      Boolean b;

    case ({}, {})
    then true;

    case ((cr::lcr), (cr2::lcr2)) equation
      true=ComponentReference.crefEqual(cr, cr2);
      b=match2Lists2(lcr, lcr2);
    then b;

    else false;
  end matchcontinue;
end match2Lists2;

//
//
protected function algo "algorithm to check the consistency"
  input list<BackendDAE.Var> inparaList;
  input list<BackendDAE.Equation> ineqList;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<String, Unit>> inComplexUnits;
  output tuple<list<tuple<DAE.ComponentRef, Unit>>/*  outLt */, list<tuple<String, Unit>> /* outComplexUnits */> outTpl;
protected
  list<BackendDAE.Var> paraList;
  list<BackendDAE.Equation> eqList;
  list<tuple<DAE.ComponentRef, Unit>> lt;
  list<tuple<String, Unit>> ComplexUnits;
  Boolean b1, b2, b3;
algorithm
  ((lt, b1, ComplexUnits)) := List.fold(inparaList, foldBindingExp , (inLt, true, inComplexUnits));
  ((lt, b2, ComplexUnits)) := List.fold(ineqList, foldEquation , (lt, true, ComplexUnits));
  b3 := match2Lists(inLt, lt);
  outTpl := algo2(b1, b2, b3, inparaList, ineqList, lt, ComplexUnits);
end algo;

//
//
protected function algo2 "help-function"
  input Boolean inB1;
  input Boolean inB2;
  input Boolean inB3;
  input list<BackendDAE.Var> inparaList;
  input list<BackendDAE.Equation> ineqList;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<String, Unit>> inComplexUnits;
  output tuple<list<tuple<DAE.ComponentRef, Unit>>/*  outLt */, list<tuple<String, Unit>> /* outComplexUnits */> outTpl;
algorithm
  outTpl:=match(inB1, inB2, inB3, inparaList, ineqList, inLt, inComplexUnits)
    local
      list<tuple<DAE.ComponentRef, Unit>> lt;
      list<tuple<String, Unit>> ComplexUnits;

    case (true, true, true, _, _, _, _)
    then ((inLt, inComplexUnits));

    case (true, true, false, _, _, _, _) equation
      ((lt, ComplexUnits))=algo(inparaList, ineqList, inLt, inComplexUnits);
    then ((lt, ComplexUnits));

    else fail();
  end match;
end algo2;

//
//
protected function foldEquation "folds the equations or return the error message of incosistent equations"
  input BackendDAE.Equation inEq;
  input tuple<list<tuple<DAE.ComponentRef, Unit>> /* inLt */, Boolean /* success */, list<tuple<String, Unit>> /* inComplexUnits */> inTpl;
  output tuple<list<tuple<DAE.ComponentRef, Unit>> /* outLt */, Boolean /* success */, list<tuple<String, Unit>> /* inComplexUnits */> outTpl;
protected
  list<tuple<DAE.ComponentRef, Unit>> lt;
  list<tuple<String, Unit>> ComplexUnits;
  list<list<tuple<DAE.Exp, Unit>>> expListList;
  list<String> strList;
  Boolean b;
  String s;
algorithm
  Debug.fcall(Flags.DUMP_EQ_UNIT_STRUCT, BackendDump.printEquation, inEq);
  (lt, b, ComplexUnits):=inTpl;
  (lt, ComplexUnits, expListList):=foldEquation2(inEq, lt, ComplexUnits);
  List.map3_0(expListList, Errorfunction, inEq, lt, ComplexUnits);
  b:=List.isEmpty(expListList) and b;
  outTpl:=(lt, b, ComplexUnits);
end foldEquation;

//
//
protected function foldEquation2 "help-function"
  input BackendDAE.Equation inEq;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<String, Unit>> inComplexUnits;
  output list<tuple<DAE.ComponentRef, Unit>> outLt;
  output list<tuple<String, Unit>> outComplexUnits;
  output list<list<tuple<DAE.Exp, Unit>>> outexpListList;

algorithm
  (outLt, outComplexUnits, outexpListList) := match(inEq, inLt, inComplexUnits)
    local
      DAE.Exp temp, rhs, lhs;
      BackendDAE.Equation eq;
      list<tuple<DAE.ComponentRef, Unit>> lt;
      list<tuple<String, Unit>> ComplexUnits;
      list<list<tuple<DAE.Exp, Unit>>> expList;
      Unit ut;
      DAE.ComponentRef cr;

    case (eq as BackendDAE.EQUATION(exp=lhs, scalar=rhs), lt, ComplexUnits) equation
      temp=DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      Debug.fcall(Flags.DUMP_EQ_UNIT_STRUCT, ExpressionDump.dumpExp, temp);
      (_, (lt, ComplexUnits), expList)=insertUnitinEquation(temp, (lt, ComplexUnits), MASTER({}));
    then (lt, ComplexUnits, expList);

    case (BackendDAE.ARRAY_EQUATION(left=lhs, right=rhs), lt, ComplexUnits) equation
      temp=DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      Debug.fcall(Flags.DUMP_EQ_UNIT_STRUCT, ExpressionDump.dumpExp, temp);
      (_, (lt, ComplexUnits), expList)=insertUnitinEquation(temp, (lt, ComplexUnits), MASTER({}));
    then (lt, ComplexUnits, expList);

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=rhs), lt, ComplexUnits) equation
      lhs=DAE.CREF(cr, DAE.T_REAL_DEFAULT);
      temp=DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      Debug.fcall(Flags.DUMP_EQ_UNIT_STRUCT, ExpressionDump.dumpExp, temp);
      (_, (lt, ComplexUnits), expList)=insertUnitinEquation(temp, (lt, ComplexUnits), MASTER({}));
    then (lt, ComplexUnits, expList);

    case (BackendDAE.RESIDUAL_EQUATION(exp=rhs), lt, ComplexUnits) equation
      lhs=DAE.RCONST(0.0);
      temp=DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      Debug.fcall(Flags.DUMP_EQ_UNIT_STRUCT, ExpressionDump.dumpExp, temp);
      (_, (lt, ComplexUnits), expList)=insertUnitinEquation(temp, (lt, ComplexUnits), MASTER({}));
    then (lt, ComplexUnits, expList);

    case (BackendDAE.ALGORITHM(alg=_), lt, ComplexUnits) equation
      Error.addCompilerWarning("ALGORITHM, these types of equations are not yet supported\n");
    then (inLt, inComplexUnits, {});

    case (BackendDAE.WHEN_EQUATION(size=_), lt, ComplexUnits) equation
      Error.addCompilerWarning("WHEN_EQUATION, these types of equations are not yet supported\n");
    then (inLt, inComplexUnits, {});

    case (BackendDAE.COMPLEX_EQUATION(left=lhs, right=rhs), lt, ComplexUnits) equation
      temp=DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      Debug.fcall(Flags.DUMP_EQ_UNIT_STRUCT, ExpressionDump.dumpExp, temp);
      (_, (lt, ComplexUnits), expList)=insertUnitinEquation(temp, (lt, ComplexUnits), MASTER({}));
    then (lt, ComplexUnits, expList);

    case (BackendDAE.IF_EQUATION(conditions=_), lt, ComplexUnits) equation
       Error.addCompilerWarning("IF_EQUATION, these types of equations are not yet supported\n");
    then (inLt, inComplexUnits, {});

    else equation
      Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: function foldEquation failed");
    then fail();
  end match;
end foldEquation2;

//
//
protected function foldBindingExp "folds the Binding expressions"
  input BackendDAE.Var inVar;
  input tuple<list<tuple<DAE.ComponentRef, Unit>> /* inLt */, Boolean /* success */, list<tuple<String, Unit>> /* inComplexUnits */> inTpl;
  output tuple<list<tuple<DAE.ComponentRef, Unit>> /* outLt */, Boolean /* success */, list<tuple<String, Unit>> /* outComplexUnits */> outTpl;
algorithm
  outTpl := matchcontinue(inVar, inTpl)
    local
      DAE.Exp exp, crefExp;
      DAE.ComponentRef cref;
      list<tuple<DAE.ComponentRef, Unit>> lt;
      list<tuple<String, Unit>> ComplexUnits;
      Boolean b;
      BackendDAE.Equation eq;

    case (BackendDAE.VAR(varType=DAE.T_REAL(varLst=_), bindExp=SOME(exp)), (lt, b, ComplexUnits)) equation
      cref = BackendVariable.varCref(inVar);
      crefExp = Expression.crefExp(cref);
      eq=BackendDAE.EQUATION(crefExp, exp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
      ((lt, b, ComplexUnits))=foldEquation(eq, (lt, b, ComplexUnits));
    then ((lt, b, ComplexUnits));

    case (BackendDAE.VAR(varType=DAE.T_REAL(varLst=_), bindExp=SOME(exp)), (lt, _, ComplexUnits))
    then ((lt, false, ComplexUnits));

    else inTpl;
  end matchcontinue;
end foldBindingExp;

//
//
protected function Errorfunction "returns the insostinent Equation with sub-expression"
  input list<tuple<DAE.Exp, Unit>> inexpList;
  input BackendDAE.Equation inEq;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<String, Unit>> inComplexUnits;
algorithm
  _ := match(inexpList, inEq, inLt, inComplexUnits)
    local
      String s, s1, s2, s3, s4;
      list<tuple<DAE.Exp, Unit>> expList;
      DAE.Exp exp1, exp2;
      Integer i;

    case (expList, _, _, _)
      equation
        s=BackendDump.equationString(inEq);
        s1=Errorfunction2(expList, inLt, inComplexUnits);
        Error.addCompilerWarning("The following equation is INCOSISTENT due to specified unit information: " +& s +& "\n" +&
        "The units of following sub-expressions need to be equal:\n" +& s1 );
    then ();
  end match;
end Errorfunction;

//
//
protected function Errorfunction2 "help-function"
  input list<tuple<DAE.Exp, Unit>> inexpList;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<String, Unit>> inComplexUnits;
  output String outS;
algorithm
  outS := match(inexpList, inLt, inComplexUnits)
    local
      list<tuple<DAE.Exp, Unit>> expList;
      DAE.Exp exp;
      Unit ut;
      String s, s1, s2;

    case ((exp, ut)::{}, _, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = unit2String(ut, inComplexUnits, inLt);
      s = "- sub-expression \"" +& s +& "\" has unit \"" +& s1 +& "\"";
    then s;

    case ((exp, ut)::expList, _, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = unit2String(ut, inComplexUnits, inLt);
      s2 = Errorfunction2(expList, inLt, inComplexUnits);
      s = "- sub-expression \"" +& s +& "\" has unit \"" +& s1 +& "\"\n" +& s2;
    then s;
  end match;
end Errorfunction2;

//
//
protected function notification "dumps the calculated units"
  input list<tuple<DAE.ComponentRef, Unit>> inLt1;
  input list<tuple<DAE.ComponentRef, Unit>> inLt2;
  input list<tuple<DAE.ComponentRef, Unit>> inLt3;
  input list<tuple<String, Unit>> inComplexUnits;
  output String outS;

algorithm
  outS := matchcontinue(inLt1, inLt2, inLt3, inComplexUnits)
    local
      String s1, s2;
      list<tuple<DAE.ComponentRef, Unit>> lt1, lt2;
      tuple<DAE.ComponentRef, Unit> t1, t2;
      DAE.ComponentRef cr1, cr2;
      Real factor1;
      Integer i1, i2, i3, i4, i5, i6, i7;

    case ({}, {}, _, _)
    then "";

    case (t1::lt1, t2::lt2, _, _) equation
      (cr1, MASTER(varList=_))=t1;
      (cr2, UNIT(factor1, i1, i2, i3, i4, i5, i6, i7))=t2;
      s1="\"" +& ComponentReference.crefStr(cr1) +& "\"" +& " has the Unit " +& "\"" +& unit2String(UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inComplexUnits, inLt3) +& "\"" +& "\n";
      s2=notification(lt1, lt2, inLt3, inComplexUnits);
      s1=s1 +& s2;
    then s1;

    case (t1::lt1, t2::lt2, _, _) equation
      s1="";
      s2=notification(lt1, lt2, inLt3, inComplexUnits);
      s1= s1 +& s2;
    then  s1;
  end matchcontinue;
end notification;

//
//
protected function insertUnitinEquation "inserts the units in Equation and check if the equation is consistent or not"
  input DAE.Exp inEq;
  input tuple<list<tuple<DAE.ComponentRef, Unit>> /* inLt */, list<tuple<String, Unit>> /* inComplexUnits */> inTpl;
  input Unit inUt;
  output Unit outUt;
  output tuple<list<tuple<DAE.ComponentRef, Unit>> /* outLt */, list<tuple<String, Unit>> /* outComplexUnits */> outTpl;
  output list<list<tuple<DAE.Exp, Unit>>> outexpList;

algorithm
  (outUt, outTpl, outexpList) := matchcontinue(inEq, inTpl, inUt)

  local
    DAE.Exp exp1, exp2, exp3;
    DAE.Type ty;
    Unit ut, ut2;
    DAE.ComponentRef cr;
    list<tuple<DAE.ComponentRef, Unit>> lt;
    list<tuple<String, Unit>> ComplexUnits;
    list<DAE.ComponentRef> lcr, lcr2;
    list<list<tuple<DAE.Exp, Unit>>> expListList, expListList2, expListList3;
    Real factor1, factor2;
    Integer i1, i2, i3, i4, i5, i6, i7;
    Integer j1, j2, j3, j4, j5, j6, j7;

    Integer prefix, exponent, prefix2, exponent2, i;
    Real r, r1, r2, r3, r4, r5, r6, r7;
    Real q, q1, q2, q3, q4, q5, q6, q7;
    list<DAE.Exp> ExpList;
    Boolean b;
    String s1, s2, s3, s4;

 //SUB equal summands
  case (DAE.BINARY(exp1, DAE.SUB(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), ut);
      (true, ut, lt)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
  then (ut, (lt, ComplexUnits), expListList);

  //SUB equal summands
  case (DAE.BINARY(exp1, DAE.SUB(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut2, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp2, (lt, ComplexUnits), inUt);
      (ut, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp1, (lt, ComplexUnits), ut2);
      (true, ut, lt)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
  then (ut, (lt, ComplexUnits), expListList);

  //SUB unequal summands
  case (DAE.BINARY(exp1, DAE.SUB(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), ut);
      (false, _, _)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
      expListList={(exp1, ut), (exp2, ut2)}::expListList;
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //SUB unequal summands
  case (DAE.BINARY(exp1, DAE.SUB(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut2, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp2, (lt, ComplexUnits), inUt);
      (ut, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp1, (lt, ComplexUnits), ut2);
      (false, _, _)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
      expListList={(exp1, ut), (exp2, ut2)}::expListList;
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //ADD equal summands
  case (DAE.BINARY(exp1, DAE.ADD(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), ut);
      (true, ut, lt)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
  then (ut, (lt, ComplexUnits), expListList);

  //ADD equal summands
  case (DAE.BINARY(exp1, DAE.ADD(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut2, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp2, (lt, ComplexUnits), inUt);
      (ut, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp1, (lt, ComplexUnits), ut2);
      (true, ut, lt)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
  then (ut, (lt, ComplexUnits), expListList);

  //ADD unequal summands
  case (DAE.BINARY(exp1, DAE.ADD(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), ut);
      (false, _, _)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
      expListList={(exp1, ut), (exp2, ut2)}::expListList;
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //ADD unequal
  case (DAE.BINARY(exp1, DAE.ADD(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut2, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp2, (lt, ComplexUnits), inUt);
      (ut, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp1, (lt, ComplexUnits), ut2);
      (false, _, _)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
      expListList={(exp1, ut), (exp2, ut2)}::expListList;
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //MUL
  case (DAE.BINARY(exp1, DAE.MUL(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (ut2 as UNIT(factor=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      ut=unitMul(ut, ut2);
      expListList=listAppend(expListList, expListList2);
  then (ut, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.MUL(ty=_), exp2), (lt, ComplexUnits), MASTER(varList=_))
    equation
      (MASTER(varList=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (UNIT(factor=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      expListList=listAppend(expListList, expListList2);
  then (MASTER({}), (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.MUL(ty=_), exp2), (lt, ComplexUnits), UNIT(factor=_))
    equation
      (MASTER(varList=lcr), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (ut2 as UNIT(factor=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      ut=unitDiv(inUt, ut2);
      lt=List.map2(lt, updateLt, lcr, ut);
      expListList=listAppend(expListList, expListList2);
  then (inUt, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.MUL(ty=_), exp2), (lt, ComplexUnits), MASTER(varList=_))
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (MASTER(varList=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      expListList=listAppend(expListList, expListList2);
  then (MASTER({}), (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.MUL(ty=_), exp2), (lt, ComplexUnits), UNIT(factor=_))
    equation
      (ut2 as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (MASTER(varList=lcr), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      ut=unitDiv(inUt, ut2);
      lt=List.map2(lt, updateLt, lcr, ut);
      expListList=listAppend(expListList, expListList2);
  then (inUt, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.MUL(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (MASTER(varList=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (MASTER(varList=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //DIV
  case (DAE.BINARY(exp1, DAE.DIV(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (ut2 as UNIT(factor=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      ut=unitDiv(ut, ut2);
      expListList=listAppend(expListList, expListList2);
  then (ut, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.DIV(ty=_), exp2), (lt, ComplexUnits), MASTER(varList=_))
    equation
      (MASTER(varList=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (UNIT(factor=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      expListList=listAppend(expListList, expListList2);
  then (MASTER({}), (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.DIV(ty=_), exp2), (lt, ComplexUnits), UNIT(factor=_))
    equation
      (MASTER(varList=lcr), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (ut2 as UNIT(factor=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      ut=unitMul(inUt, ut2);
      lt=List.map2(lt, updateLt, lcr, ut);
      expListList=listAppend(expListList, expListList2);
  then (inUt, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.DIV(ty=_), exp2), (lt, ComplexUnits), MASTER(varList=_))
    equation
      (UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (MASTER(varList=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      expListList=listAppend(expListList, expListList2);
  then (MASTER({}), (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.DIV(ty=_), exp2), (lt, ComplexUnits), UNIT(factor=_))
    equation
      (ut2 as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (MASTER(varList=lcr), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      ut=unitDiv(ut2, inUt);
      lt=List.map2(lt, updateLt, lcr, ut);
      expListList=listAppend(expListList, expListList2);
  then (inUt, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.DIV(ty=_), exp2), (lt, ComplexUnits), _)
    equation
      (MASTER(varList=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (MASTER(varList=_), (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), MASTER({}));
      expListList=listAppend(expListList, expListList2);
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //POW
  case (DAE.BINARY(exp1, DAE.POW(ty=_), DAE.RCONST(r)), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      i=realInt(r);
      true=realEq(r, intReal(i));
      ut=unitPow(ut, i);
  then (ut, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.POW(ty=_), DAE.RCONST(r)), (lt, ComplexUnits), ut as UNIT(factor=_))
    equation
      (MASTER(lcr), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)=unitRoot(ut, r);
      lt=List.map2(lt, updateLt, lcr, UNIT(factor1, i1, i2, i3, i4, i5, i6, i7));
  then (inUt, (lt, ComplexUnits), expListList);

  case (DAE.BINARY(exp1, DAE.POW(ty=_), DAE.RCONST(r)), (lt, ComplexUnits), _)
    equation
      (_, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //DER
  case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (lt, ComplexUnits), UNIT(factor=_))
    equation
      (MASTER(lcr), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      ut=unitMul(inUt, UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      lt=List.map2(lt, updateLt, lcr, ut);
  then (inUt, (lt, ComplexUnits), expListList);

  case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      ut=unitDiv(ut, UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
  then (ut, (lt, ComplexUnits), expListList);

  case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (lt, ComplexUnits), MASTER(varList=_))
    equation
      (MASTER(varList=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //SQRT
  case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (lt, ComplexUnits), _)
    equation
      (ut as UNIT(factor=_), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)=unitRoot(ut, 2.0);
  then (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), (lt, ComplexUnits), expListList);

  case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (lt, ComplexUnits), UNIT(factor=_))
    equation
      (MASTER(lcr), (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      ut=unitPow(inUt, 2);
      lt=List.map2(lt, updateLt, lcr, ut);
  then (inUt, (lt, ComplexUnits), expListList);

  case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (lt, ComplexUnits), _)
    equation
      (_, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //IFEXP
  case (DAE.IFEXP(exp1, exp2, exp3), (lt, ComplexUnits), _)
    equation
      (_, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (ut, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList3)=insertUnitinEquation(exp3, (lt, ComplexUnits), ut);
      (true, ut, lt)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
      expListList=listAppend(expListList, expListList3);
  then (ut, (lt, ComplexUnits), expListList);

  case (DAE.IFEXP(exp1, exp2, exp3), (lt, ComplexUnits), _)
    equation
      (_, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), MASTER({}));
      (ut, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp2, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList3)=insertUnitinEquation(exp3, (lt, ComplexUnits), ut);
      (false, _, _)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
      expListList=listAppend(expListList, expListList3);
      expListList={(exp2, ut), (exp3, ut2)}::expListList;
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //RELATIONS
  case (DAE.RELATION(exp1=exp1, operator=_, exp2=exp2, index=_, optionExpisASUB=_), (lt, ComplexUnits), _)
    equation
      (ut, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (true, ut, lt)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
  then (ut, (lt, ComplexUnits), expListList);

  case (DAE.RELATION(exp1=exp1, operator=_, exp2=exp2, index=_, optionExpisASUB=_), (lt, ComplexUnits), _)
    equation
      (ut, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (ut2, (lt, ComplexUnits), expListList2)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
      (false, _, _)=UnitTypesEqual(ut, ut2, lt);
      expListList=listAppend(expListList, expListList2);
      expListList={(exp1, ut), (exp2, ut2)}::expListList;
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //all other BINARIES
  case (DAE.BINARY(operator=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits), {});

  //LBINARY
  case (DAE.LBINARY(exp1=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits), {});

  //LUNARY
  case (DAE.LUNARY(exp=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits), {});

  //MATRIX
  case (DAE.MATRIX(ty=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits), {});

  //ARRAY
  case (DAE.ARRAY(ty=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits), {});

  //CALL
  case (DAE.CALL(expLst=ExpList), (lt, ComplexUnits), _)
    equation
      (lt, ComplexUnits, expListList)=foldCallArg(ExpList, lt, ComplexUnits);
  then (MASTER({}), (lt, ComplexUnits), expListList);

  //UMINUS
  case (DAE.UNARY(DAE.UMINUS(ty=_), exp1), (lt, ComplexUnits), _)
    equation
      (ut, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (lt, ComplexUnits), inUt);
  then (ut, (lt, ComplexUnits), expListList);

  //ICONST
  case (DAE.ICONST(integer=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits) , {});

  //BCONST
  case (DAE.BCONST(bool=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits) , {});

  //SCONST
  case (DAE.SCONST(string=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits) , {});

  //RCONST
  case (DAE.RCONST(real=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits) , {});

  //"time"
  case (DAE.CREF(componentRef=cr), (lt, ComplexUnits), _)
    equation
      true=ComponentReference.crefEqual(cr, DAE.crefTime);
      ut=UNIT(1e0, 0, 0, 0, 1, 0, 0, 0);
  then (ut, (lt, ComplexUnits), {});

  //CREF
  case (DAE.CREF(componentRef=cr, ty=DAE.T_REAL(varLst=_)), (lt, ComplexUnits), _)
    equation
      ut=insertUnitinEquation2(cr, lt);
  then (ut, (lt, ComplexUnits), {});

  //NO UNIT IN EQUATION
  case (DAE.CREF(componentRef=cr, ty=_), (lt, ComplexUnits), _)
  then (MASTER({}), (lt, ComplexUnits), {});

  else
    equation
      Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: function insertUnitinEquation failed");
  then fail();

  end matchcontinue;
end insertUnitinEquation;

//
//
protected function insertUnitinEquation2 "help-function for insertUnitinEquation"
  input DAE.ComponentRef incr;
  input list<tuple<DAE.ComponentRef, Unit>> lt;
  output Unit outUt;
algorithm
  outUt := matchcontinue(incr, lt)
    local
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef, Unit>> rest;
      tuple<DAE.ComponentRef, Unit> t;
      Unit ut;
      String s;

    case (_, {})
    then fail();

    case (_, (cr, ut)::_) equation
      true = ComponentReference.crefEqual(cr, incr);
    then ut;

    case (_, _::rest) equation
      ut = insertUnitinEquation2(incr, rest);
    then ut;
  end matchcontinue;
end insertUnitinEquation2;

//
//
protected function foldCallArg "help-function for CALL case in function insertUnitinEquation"
  input list<DAE.Exp> inExpList;
  input list<tuple<DAE.ComponentRef, Unit>>  inLt ;
  input list<tuple<String, Unit>> inComplexUnits;
  output list<tuple<DAE.ComponentRef, Unit>>  outLt ;
  output list<tuple<String, Unit>> outComplexUnits;
  output list<list<tuple<DAE.Exp, Unit>>> outExpListList;
algorithm
  (outLt, outComplexUnits, outExpListList) := match(inExpList, inLt, inComplexUnits)
    local
      DAE.Exp exp1;
      list<DAE.Exp> rest;
      list<list<tuple<DAE.Exp, Unit>>> expListList, expListList2;
      list<tuple<DAE.ComponentRef, Unit>> lt;
      list<tuple<String, Unit>> ComplexUnits;

    case ({}, _, _)
    then (inLt, inComplexUnits, {});

    case (exp1::rest, _, _) equation
      (_, (lt, ComplexUnits), expListList)=insertUnitinEquation(exp1, (inLt, inComplexUnits), MASTER({}));
      (lt, ComplexUnits, expListList2)=foldCallArg(rest, lt, ComplexUnits);
      expListList=listAppend(expListList, expListList2);
    then (lt, ComplexUnits, expListList);
  end match;
end foldCallArg;

//
//
protected function UnitTypesEqual "checks equality of two UnitExp's"
  input Unit inut;
  input Unit inut2;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  output Boolean b;
  output Unit outUt;
  output list<tuple<DAE.ComponentRef, Unit>> outLt;
algorithm
  (b, outUt, outLt) := matchcontinue(inut, inut2, inLt)
    local
      String s, s2;
      Integer i1, i2, i3, i4, i5, i6, i7;
      Integer j1, j2, j3, j4, j5, j6, j7;
      list<DAE.ComponentRef> lcr, lcr2;
      list<tuple<DAE.ComponentRef, Unit>> lt;
      Real factor1, factor2;
      Unit ut;

    case (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), UNIT(factor2, j1, j2, j3, j4, j5, j6, j7), _) equation
      true=realEq(factor1, factor2);
      true=intEq(i1, j1);
      true=intEq(i2, j2);
      true=intEq(i3, j3);
      true=intEq(i4, j4);
      true=intEq(i5, j5);
      true=intEq(i6, j6);
      true=intEq(i7, j7);
    then (true, UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inLt);

    case (ut as UNIT(factor=_), MASTER(lcr), _) equation
      lt = List.map2(inLt, updateLt, lcr, ut);
    then (true, ut , lt);

    case (MASTER(lcr), ut as UNIT(factor=_), _) equation
      lt = List.map2(inLt, updateLt, lcr, ut);
    then (true, ut, lt);

    case (MASTER(lcr), MASTER(lcr2), _) equation
      lcr = listAppend(lcr, lcr2);
    then (true, MASTER(lcr), inLt);

    case (UNKNOWN(s), UNKNOWN(s2), _) equation
      true = stringEqual(s, s2);
    then (true, UNKNOWN(s), inLt);

    case (UNKNOWN(s), _, _) then (true, UNKNOWN(s), inLt);
    case (_, UNKNOWN(s), _) then (true, UNKNOWN(s), inLt);

    else (false, inut, inLt);
  end matchcontinue;
end UnitTypesEqual;

//
//
protected function updateLt "updates the unitlist"
  input tuple<DAE.ComponentRef, Unit> inT;
  input list<DAE.ComponentRef> inlCr;
  input Unit inUt;
  output tuple<DAE.ComponentRef, Unit> outT;
algorithm
  outT := match(inT, inlCr, inUt)
    local
      DAE.ComponentRef cr, cr2;
      Unit ut, ut2;
      list<DAE.ComponentRef> lcr;
      tuple<DAE.ComponentRef, Unit> t;

    case (t, lcr, ut) equation
      t = List.fold1(lcr, updateLt2, ut, t);
    then t;
  end match;
end updateLt;

//
//
protected function updateLt2 "help-function"
  input DAE.ComponentRef inCr;
  input Unit inUt;
  input tuple<DAE.ComponentRef, Unit> inT;
  output tuple<DAE.ComponentRef, Unit> outT;
algorithm
  outT := matchcontinue(inCr, inUt, inT)
    local
      DAE.ComponentRef cr, cr2;
      Unit ut, ut2;
      list<DAE.ComponentRef> lcr;
      tuple<DAE.ComponentRef, Unit> t;

    case (cr, ut, (cr2, ut2)) equation
      true=ComponentReference.crefEqual(cr, cr2);
      t=(cr, ut);
    then t;

    else inT;
  end matchcontinue;
end updateLt2;

//
//
protected function dumpUnit "dumps units"
  input Unit inue;
  input list<tuple<String, Unit>> inComplexUnits;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
algorithm
  _ := matchcontinue(inue, inComplexUnits, inLt)
    local
      String s;
      Boolean b;
      list<DAE.ComponentRef> lcr;
      Real factor1;
      Integer i1, i2, i3, i4, i5, i6, i7;

    case (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), _, _) equation
      s=findUnitRev(UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inComplexUnits, inLt);
      print(s);
    then ();

    case (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), _, _) equation
      print(realString(factor1) +& " * ");

      b=false;
      s="mol^(" +& intString(i1) +& ")";
      s=Util.if_(intEq(i1, 0), "", s);
      b=b or intNe(i1, 0);
      print(s);

      s=Util.if_(b and intNe(i2, 0), " * ", "");
      print(s);
      s="cd^(" +& intString(i2) +& ")";
      s=Util.if_(intEq(i2, 0), "", s);
      b=b or intNe(i2, 0);
      print(s);

      s=Util.if_(b and intNe(i3, 0), " * ", "");
      print(s);
      s="m^(" +& intString(i3) +& ")";
      s=Util.if_(intEq(i3, 0), "", s);
      b=b or intNe(i3, 0);
      print(s);

      s=Util.if_(b and intNe(i4, 0), " * ", "");
      print(s);
      s="s^(" +& intString(i4) +& ")";
      s=Util.if_(intEq(i4, 0), "", s);
      b=b or intNe(i4, 0);
      print(s);

      s=Util.if_(b and intNe(i5, 0), " * ", "");
      print(s);
      s="A^(" +& intString(i5) +& ")";
      s=Util.if_(intEq(i5, 0), "", s);
      b=b or intNe(i5, 0);
      print(s);

      s=Util.if_(b and intNe(i6, 0), " * ", "");
      print(s);
      s="K^(" +& intString(i6) +& ")";
      s=Util.if_(intEq(i6, 0), "", s);
      b=b or intNe(i6, 0);
      print(s);

      s=Util.if_(b and intNe(i7, 0), " * ", "");
      print(s);
      s="g^(" +& intString(i7) +& ")";
      s=Util.if_(intEq(i7, 0), "", s);
      b=b or intNe(i7, 0);
      print(s);

      s=Util.if_(b , "", "1");
      print(s);
    then ();

    case (MASTER(lcr), _, _) equation
      print("MASTER( ");
      print(printListCr(lcr));
      print(" )");
    then ();

    case (UNKNOWN(s), _, _) equation
      print("UNKOWN ( " +& s +& " )");
    then ();
  end matchcontinue;
end dumpUnit;

//
//
protected function findUnitRev "helps to find a unit in list Complexunits"
  input Unit inUt;
  input list<tuple<String, Unit>> inComplexUnits;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  output String outS;
algorithm
  outS := matchcontinue(inUt, inComplexUnits, inLt)
    local
      Unit ut;
      String s;
      list<tuple<String, Unit>> rest;

    case (_, {}, _)
    then fail();

    case (_, (s, ut)::_, _) equation
      (true, _, _)=UnitTypesEqual(ut, inUt, inLt);
    then s;

    case (_, _::rest, _)
    then findUnitRev(inUt, rest, inLt);
  end matchcontinue;
end findUnitRev;

//
//
protected function dumpTuple "dumps tuple of Cref and Unit"
  input tuple<DAE.ComponentRef, Unit> inTup;
  input list<tuple<String, Unit>> inComplexUnits;
  input list<tuple<DAE.ComponentRef, Unit>> inLt;

algorithm
  _ := match(inTup, inComplexUnits, inLt)

  local
    DAE.ComponentRef cr;
    Unit ut;
    String s;

  case ((cr, ut), _, _)
    equation
      s=ComponentReference.crefStr(cr);
      print("( " +& s +& " , ");
      dumpUnit(ut, inComplexUnits, inLt);
      print(" )");
  then ();

  end match;
end dumpTuple;

//
//
protected function printListString
  input list<String> inPut;

algorithm
  _ := match(inPut)

  local
    String s;
    list<String> strRest;

    case {} then ();

    case s::strRest
      equation
        print(s +& "\n");
        printListString(strRest);
    then ();

  end match;
end printListString;

//
//
protected function printListTuple
  input list<tuple<DAE.ComponentRef, Unit>> inLt;
  input list<tuple<String, Unit>> inComplexUnits;

algorithm
  _ := match(inLt, inComplexUnits)

  local
    list<tuple<DAE.ComponentRef, Unit>> lt;
    tuple<DAE.ComponentRef, Unit> t;

    case ({}, _) then ();

    case (t::lt, _)
      equation
        dumpTuple(t, inComplexUnits, inLt);
        print("\n");
        printListTuple(lt, inComplexUnits);
    then ();

  end match;
end printListTuple;

//
//
protected function printListComplexUnits
  input list<tuple<String, Unit>> inComplexUnits;

algorithm
  _ := match(inComplexUnits)

  local
    list<tuple<String, Unit>> lCu;
    String s;
    Unit ut;

    case {} then ();

    case ((s, ut)::lCu)
      equation
        print(s +& " -> " +& unit2string(ut) +& "\n");
        printListComplexUnits(lCu);
    then ();

  end match;
end printListComplexUnits;

//
//
protected function printListCr
 input list<DAE.ComponentRef> inlCr;
 output String outS;
algorithm
  outS := match(inlCr)

  local
    list<DAE.ComponentRef> lCr;
    DAE.ComponentRef cr;
    String s;

    case {} then "";

    case cr::{}
      equation
        s=ComponentReference.crefStr(cr);
    then s;

    case cr::lCr
      equation
        s=ComponentReference.crefStr(cr);
        s=s +& ", " +& printListCr(lCr);
    then s;

  end match;
end printListCr;

//
//
protected function convertUnitString2unit "converts String to unit"
  input BackendDAE.Var var;
  input tuple<list<tuple<DAE.ComponentRef, Unit>> /* inLt */, list<tuple<String, Unit>> /* inComplexUnits */> inTpl;
  output tuple<list<tuple<DAE.ComponentRef, Unit>> /* outLt */, list<tuple<String, Unit>> /* outComplexUnits */> outTpl;

algorithm
  outTpl := matchcontinue(var, inTpl)

  local
    String unitString, s;
    list<String> listStr;
    list<tuple<DAE.ComponentRef, Unit>> lt;
    DAE.ComponentRef cr;
    Unit ut;
    list<tuple<String, Unit>> ComplexUnits;

  case (BackendDAE.VAR(varType=DAE.T_REAL(varLst=_), values = SOME(DAE.VAR_ATTR_REAL(unit=SOME(DAE.SCONST(unitString))))), (lt, ComplexUnits))
    equation
      cr=BackendVariable.varCref(var);
      (ut, ComplexUnits)=parse(unitString, cr, ComplexUnits);
      lt=(cr, ut)::lt;
  then ((lt, ComplexUnits));

  //case NO UNIT
  case (BackendDAE.VAR(varType=DAE.T_REAL(varLst=_)), (lt, ComplexUnits))
    equation
      cr=BackendVariable.varCref(var);
      lt=(cr, MASTER({cr}))::lt;
  then ((lt, ComplexUnits));

  else inTpl; //skip Non-Real Variables

  end matchcontinue;
end convertUnitString2unit;

//
//
protected function stringList2string
  input list<String> inListString;
  input String inDeliminator;
  output String outString;
algorithm
  outString := match(inListString, inDeliminator)
    local
      String curr, str;
      list<String> rest;

    case ({}, _)
    then "";

    case (curr::{}, _)
    then "\"" +& curr +& "\"";

    case (curr::rest, _) equation
      str = "\"" +& curr +& "\"" +& inDeliminator +& stringList2string(rest, inDeliminator);
    then str;
  end match;
end stringList2string;

//
//
protected function boolList2string
  input list<Boolean> inListBoolean;
  input String inDeliminator;
  output String outString;
algorithm
  outString := match(inListBoolean, inDeliminator)
    local
      String str;
      Boolean curr;
      list<Boolean> rest;

    case ({}, _)
    then "";

    case (curr::{}, _)
    then "\"" +& bool2string(curr) +& "\"";

    case (curr::rest, _) equation
      str = "\"" +& bool2string(curr) +& "\"" +& inDeliminator +& boolList2string(rest, inDeliminator);
    then str;
  end match;
end boolList2string;

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
protected function bool2string
  input Boolean inBool;
  output String outString;
algorithm
  outString := match(inBool)
    case true then "true";
    else "false";
  end match;
end bool2string;

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
      str = token2string(curr) +& inDeliminator +& tokenList2string(rest, inDeliminator);
    then str;
  end match;
end tokenList2string;

//
//
protected function unit2string
  input Unit inUnit;
  output String outString;
algorithm
  outString := match(inUnit)
    local
      String s, str;
      Boolean b;
      list<DAE.ComponentRef> crefList;
      Real factor1, shift1;
      Integer i1, i2, i3, i4, i5, i6, i7;

    case UNIT(factor1, i1, i2, i3, i4, i5, i6, i7/* , shift1 */) equation
      str = realString(factor1) +& " * ";

      b = false;
      s = "mol^(" +& intString(i1) +& ")";
      s = Util.if_(intEq(i1, 0), "", s);
      b = b or intNe(i1, 0);
      str = str +& s;

      s = Util.if_(b and intNe(i2, 0), " * ", "");
      str = str +& s;
      s = "cd^(" +& intString(i2) +& ")";
      s = Util.if_(intEq(i2, 0), "", s);
      b = b or intNe(i2, 0);
      str = str +& s;

      s = Util.if_(b and intNe(i3, 0), " * ", "");
      str = str +& s;
      s = "m^(" +& intString(i3) +& ")";
      s = Util.if_(intEq(i3, 0), "", s);
      b = b or intNe(i3, 0);
      str = str +& s;

      s = Util.if_(b and intNe(i4, 0), " * ", "");
      str = str +& s;
      s = "s^(" +& intString(i4) +& ")";
      s = Util.if_(intEq(i4, 0), "", s);
      b = b or intNe(i4, 0);
      str = str +& s;

      s = Util.if_(b and intNe(i5, 0), " * ", "");
      str = str +& s;
      s = "A^(" +& intString(i5) +& ")";
      s = Util.if_(intEq(i5, 0), "", s);
      b = b or intNe(i5, 0);
      str = str +& s;

      s = Util.if_(b and intNe(i6, 0), " * ", "");
      str = str +& s;
      //s = "(K-" +& realString(shift1) +& ")^(" +& intString(i6) +& ")";
      s = "K^(" +& intString(i6) +& ")";
      s = Util.if_(intEq(i6, 0), "", s);
      b = b or intNe(i6, 0);
      str = str +& s;

      s = Util.if_(b and intNe(i7, 0), " * ", "");
      str = str +& s;
      s = "g^(" +& intString(i7) +& ")";
      s = Util.if_(intEq(i7, 0), "", s);
      b = b or intNe(i7, 0);
      str = str +& s;

      s = Util.if_(b , "", "1");
      str = str +& s;
    then str;

    case MASTER(crefList) equation
      str = "MASTER(";
      str = str +& printListCr(crefList);
      str = str +& ")";
    then str;

    case UNKNOWN(s) equation
        str = "UNKOWN(" +& s +& ")";
    then str;
  end match;
end unit2string;

//
//
protected function parse "author: lochel"
  input String inUnitString;
  input DAE.ComponentRef inCref;
  input list<tuple<String, Unit>> inComplexUnits;
  output Unit outUnit;
  output list<tuple<String, Unit>> outComplexUnits;
algorithm
  (outUnit, outComplexUnits):=matchcontinue(inUnitString, inCref, inComplexUnits)

  local
    Unit unit;
    list<tuple<String, Unit>> ComplexUnits;
    list<String> charList;
    list<Token> tokenList;

  case (_, _, _) equation
    unit=findUnit(inUnitString, inComplexUnits);
  then (unit, inComplexUnits);

  else equation
    charList = stringListStringChar(inUnitString);
    tokenList = lexer(charList);
    unit = parser(tokenList, inCref, inComplexUnits);
    ComplexUnits=addUnit2List((inUnitString, unit), inComplexUnits);
  then (unit, ComplexUnits);
  end matchcontinue;
end parse;

//
//
protected function addUnit2List
  input tuple<String, Unit> inTpl;
  input list<tuple<String, Unit>> inComplexUnits;
  output list<tuple<String, Unit>> outComplexUnits;

algorithm
outComplexUnits:=match(inTpl, inComplexUnits)

  case ((_, UNIT(factor=_)), _)
  then inTpl::inComplexUnits;

  else inComplexUnits;

  end match;
end addUnit2List;

protected function parser "author: lochel"
  input list<Token> inTokenList;
  input DAE.ComponentRef inCref;
  input list<tuple<String, Unit>> inComplexUnits;
  output Unit outUnit;
algorithm
  outUnit := matchcontinue(inTokenList, inCref, inComplexUnits)
    local
      String str;

    case (_, _, _) then parser2(inTokenList, inCref, inComplexUnits);

    else equation
      str = tokenList2string(inTokenList, "");
    then UNKNOWN(str);
  end matchcontinue;
end parser;

//
//
protected function parser2
  input list<Token> inTokenList;
  input DAE.ComponentRef inCref;
  input list<tuple<String, Unit>> inComplexUnits;
  output Unit outUnit;
algorithm
  outUnit := match(inTokenList, inCref, inComplexUnits)
    local
      String str;
      Unit unit;
      list<Token> tokens;

    // no unit
    case ({}, _, _)
    then MASTER({inCref});

    else equation
      unit = parser3({true, true}, inTokenList, UNIT(1e0, 0, 0, 0, 0, 0, 0, 0), inComplexUnits);
    then unit;
  end match;
end parser2;

//
//
protected function parser3
  input list<Boolean> inMul "true=Mul, false=Div, initial call with true";
  input list<Token> inTokenList "Tokenliste";
  input Unit inUnit "initial call with UNIT(1e0, 0, 0, 0, 0, 0, 0, 0)";
  input list<tuple<String, Unit>> inComplexUnits;
  output Unit outUnit;
algorithm
  outUnit := matchcontinue(inMul, inTokenList, inUnit, inComplexUnits)
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
      ut = Debug.ifcallret2(bMul, unitMul, unitDiv, inUnit, ut);
      ut = parser3(bRest, tokens, ut, inComplexUnits);
    then ut;

    // "unit^i"
    case (bMul::bRest, T_UNIT(unit=s)::T_NUMBER(exponent)::tokens, _, _) equation
      ut = unitToken2unit(s, inComplexUnits);
      ut = unitPow(ut, exponent);
      ut = Debug.ifcallret2(bMul, unitMul, unitDiv, inUnit, ut);
      ut = parser3(bRest, tokens, ut, inComplexUnits);
    then ut;

    // "unit"
    case (bMul::bRest, T_UNIT(unit=s)::tokens, _, _) equation
      ut = unitToken2unit(s, inComplexUnits);
      ut = Debug.ifcallret2(bMul, unitMul, unitDiv, inUnit, ut);
      ut = parser3(bRest, tokens, ut, inComplexUnits);
    then ut;

    // "*("
    case (bMul::_, T_MUL()::T_LPAREN()::tokens, _, _) equation
      ut = parser3(bMul::bMul::inMul, tokens, inUnit, inComplexUnits);
    then ut;

    // "/("
    case (bMul::_, T_DIV()::T_LPAREN()::tokens, _, _) equation
      b = not bMul;
      ut = parser3(b::b::inMul, tokens, inUnit, inComplexUnits);
    then ut;

    // ")"
    case (_::bRest, T_RPAREN()::tokens, _, _) equation
      ut = parser3(bRest, tokens, inUnit, inComplexUnits);
    then ut;

    // "*"
    case (bMul::_, T_MUL()::tokens, _, _) equation
      ut = parser3(bMul::inMul, tokens, inUnit, inComplexUnits);
    then ut;

    // "/"
    case (bMul::_, T_DIV()::tokens, _, _) equation
      b = not bMul;
      ut = parser3(b::inMul, tokens, inUnit, inComplexUnits);
    then ut;

    else fail();
  end matchcontinue;
end parser3;

//
//
protected function unitToken2unit
  input String inS;
  input list<tuple<String, Unit>> inComplexUnits;
  output Unit outUnit;
algorithm
  outUnit := matchcontinue(inS, inComplexUnits)
    local
      String s, s2;
      Real r;
      Unit ut;

    case (_, _) equation
      ut=findUnit(inS, inComplexUnits);
    then ut;

    else equation
      s=stringGetStringChar(inS, 1);
      (r, s)=getPrefix(s, inS);
      ut=unitToken2unit(s, inComplexUnits);
      ut=unitMulReal(ut, r);
    then ut;
  end matchcontinue;
end unitToken2unit;

//
//
protected function findUnit
  input String inS;
  input list<tuple<String, Unit>> inComplexUnits;
  output Unit outUnit;
algorithm
  outUnit := matchcontinue(inS, inComplexUnits)
    local
      Unit ut;
      String s;
      list<tuple<String, Unit>> rest;

    case (_, {})
    then fail();

    case (_, (s, ut)::_) equation
      true=stringEqual(s, inS);
    then ut;

    case (_, _::rest)
    then findUnit(inS, rest);
  end matchcontinue;
end findUnit;

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
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-24, s);

case ("z", _) //-21
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-21, s);

case ("a", _) //-18
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-18, s);

case ("f", _) //-15
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-15, s);

case ("p", _) //-12
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-12, s);

case ("u", _) //-6
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-6, s);

case ("m", _) //-3
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-3, s);

case ("c", _) //-2
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-2, s);

case ("d", _)  //+1
  equation
    strRest=stringListStringChar(inS2);
    "d"::"a"::strRest=strRest;
    s=stringCharListString(strRest);
then (1e1, s);

case ("d", _) //-1
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e-1, s);

case ("h", _) //+2
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e2, s);

case ("k", _) //+3
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e3, s);

case ("M", _) //+6
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e6, s);

case ("G", _) //+9
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e9, s);

case ("T", _) //+12
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e12, s);

case ("P", _) //+15
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e15, s);

case ("E", _) //+18
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e18, s);

case ("Z", _) //+21
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
then (1e21, s);

case ("Y", _) //+24
  equation
    _::strRest=stringListStringChar(inS2);
    s=stringCharListString(strRest);
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
      false = (number ==& "");
      tokenList = lexer(charList);
      i=stringInt(number);
    then T_NUMBER(i)::tokenList;

    case "-"::charList equation
      (charList, number) = popNumber(charList);
      false = (number ==& "");
      tokenList = lexer(charList);
      i=-stringInt(number);
    then T_NUMBER(i)::tokenList;

    case charList equation
      (charList, number) = popNumber(charList);
      false = (number ==& "");
      tokenList = lexer(charList);
      i=stringInt(number);
    then T_NUMBER(i)::tokenList;

    case charList equation
      (charList, unit) = popUnit(charList);
      false = (unit ==& "");
      tokenList = lexer(charList);
    then T_UNIT(unit)::tokenList;

    else equation
      Error.addInternalError("./Compiler/BackEnd/UnitCheck.mo: function lexer failed");
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
    then (strRest, s1 +& s2);

    case s1::strRest equation
      true = (stringCompare(s1, "A") >= 0) and (stringCompare(s1, "Z") <= 0) ;
      (strRest, s2) = popUnit(strRest);
    then (strRest, s1 +& s2);

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
      true = (intString(i) ==& s1);
      (strRest, s2) = popNumber(strRest);
    then (strRest, s1 +& s2);

    else (inCharList, "");
  end matchcontinue;
end popNumber;

//
//
protected function unitMul
  input Unit inUt1;
  input Unit inUt2;
  output Unit outUt;
protected
  Real factor1, factor2, shift1, shift2;
  Integer i1, i2, i3, i4, i5, i6, i7;
  Integer j1, j2, j3, j4, j5, j6, j7;
algorithm
  UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) := inUt1;
  UNIT(factor2, j1, j2, j3, j4, j5, j6, j7) := inUt2;
  factor1:=factor1 *. factor2;
  i1 := i1+j1;
  i2 := i2+j2;
  i3 := i3+j3;
  i4 := i4+j4;
  i5 := i5+j5;
  i6 := i6+j6;
  i7 := i7+j7;
  outUt := UNIT(factor1, i1, i2, i3, i4, i5, i6, i7);
end unitMul;

//
//
protected function unitDiv
  input Unit inUt1;
  input Unit inUt2;
  output Unit outUt;
protected
  Real factor1, factor2, shift1, shift2;
  Integer i1, i2, i3, i4, i5, i6, i7;
  Integer j1, j2, j3, j4, j5, j6, j7;
algorithm
  UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) := inUt1;
  UNIT(factor2, j1, j2, j3, j4, j5, j6, j7) := inUt2;
  factor1 := factor1 /. factor2;
  i1 := i1-j1;
  i2 := i2-j2;
  i3 := i3-j3;
  i4 := i4-j4;
  i5 := i5-j5;
  i6 := i6-j6;
  i7 := i7-j7;
  outUt := UNIT(factor1, i1, i2, i3, i4, i5, i6, i7);
end unitDiv;

//
//
protected function unitPow
  input Unit inUt;
  input Integer inExp "exponent";
  output Unit outUt;
protected
  Real factor, shift;
  Integer i1, i2, i3, i4, i5, i6, i7;
algorithm
  UNIT(factor, i1, i2, i3, i4, i5, i6, i7) := inUt;
  factor:=realPow(factor, intReal(inExp));
  i1 := i1*inExp;
  i2 := i2*inExp;
  i3 := i3*inExp;
  i4 := i4*inExp;
  i5 := i5*inExp;
  i6 := i6*inExp;
  i7 := i7*inExp;
  outUt := UNIT(factor, i1, i2, i3, i4, i5, i6, i7);
end unitPow;

//
//
protected function unitMulReal
  input Unit inUt;
  input Real inFactor;
  output Unit outUt;
protected
  Real factor, shift;
  Integer i1, i2, i3, i4, i5, i6, i7;
algorithm
  UNIT(factor, i1, i2, i3, i4, i5, i6, i7) := inUt;
  factor:= factor *. inFactor;
  outUt := UNIT(factor, i1, i2, i3, i4, i5, i6, i7);
end unitMulReal;

//
//
protected function unitRoot
  input Unit inUt;
  input Real inExponent;
  output Unit outUt;
algorithm
  outUt := match(inUt, inExponent)
  local
    Real factor1, r, r1, r2, r3, r4, r5, r6, r7;
    Real q1, q2, q3, q4, q5, q6, q7;
    Integer i, i1, i2, i3, i4, i5, i6, i7;
    Integer j1, j2, j3, j4, j5, j6, j7;

  case (UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), r)
    equation
      i=realInt(r);
      r1=realDiv(1.0, r);
      factor1=realPow(factor1, r1);

      j1=intDiv(i1, i);
        r1=intReal(i1);
        r1=realDiv(r1, r);
      q1=intReal(j1);
      true=realEq(r1, q1);

      j2=intDiv(i2, i);
        r2=intReal(i2);
        r2=realDiv(r2, r);
      q2=intReal(j2);
      true=realEq(r2, q2);

      j3=intDiv(i3, i);
        r3=intReal(i3);
        r3=realDiv(r3, r);
      q3=intReal(j3);
      true=realEq(r3, q3);

      j4=intDiv(i4, i);
        r4=intReal(i4);
        r4=realDiv(r4, r);
      q4=intReal(j4);
      true=realEq(r4, q4);

      j5=intDiv(i5, i);
        r5=intReal(i5);
        r5=realDiv(r5, r);
      q5=intReal(j5);
      true=realEq(r5, q5);

      j6=intDiv(i6, i);
        r6=intReal(i6);
        r6=realDiv(r6, r);
      q6=intReal(j6);
      true=realEq(r6, q6);

      j7=intDiv(i7, i);
        r7=intReal(i7);
        r7=realDiv(r7, r);
      q7=intReal(j7);
      true=realEq(r7, q7);
  then UNIT(factor1, j1, j2, j3, j4, j5 , j6, j7);

  else fail();

  end match;
end unitRoot;

annotation(__OpenModelica_Interface="backend");
end UnitCheck;
