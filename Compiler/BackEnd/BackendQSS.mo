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

encapsulated package BackendQSS
" file:        BackendQSS.mo
  package:     BackendQSS
  description: BackendQSS contains the datatypes used by the backend for QSS
               solver.
  authors:     florosx, fbergero

  $Id$"

public import ExpressionSimplify;
public import SimCode;
public import SimCodeVar;
public import System;
public import BackendDAE;
public import DAE;
public import Absyn;
public import Util;
public import ExpressionDump;
public import Expression;


protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import HpcOmSimCode;
protected import List;
protected import SimCodeUtil;

public
uniontype QSSinfo "- equation indices in static blocks and DEVS structure"
  record QSSINFO
    list<list<Integer>> stateVarIndex;
    list<DAE.ComponentRef> stateVars;
    list<DAE.ComponentRef> discreteVars;
    list<DAE.ComponentRef> algVars;
    BackendDAE.EquationArray eqs;
    list<DAE.Exp> zcs;
    Integer zc_offset;
  end QSSINFO;
end QSSinfo;

public function generateStructureCodeQSS
  input BackendDAE.BackendDAE inBackendDAE;
  /*input array<Integer> equationIndices;
  input array<Integer> variableIndices;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.StrongComponents strongComponents;
  */
  input SimCode.SimCode simCode;

  output QSSinfo QSSinfo_out;
  output SimCode.SimCode simC;
algorithm
  (QSSinfo_out,simC) :=
  matchcontinue (inBackendDAE, /*equationIndices, variableIndices, inIncidenceMatrix, inIncidenceMatrixT, strongComponents,*/ simCode)
    local
      BackendDAE.BackendDAE dlow;
      list<BackendDAE.Var> allVarsList, stateVarsList,orderedVarsList,discVarsLst;
      list<SimCode.SimEqSystem> eqs;
      list<DAE.ComponentRef> disc;
      BackendDAE.EquationArray eqsdae;
      BackendDAE.Shared shared;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<DAE.Exp> zc_exps;
      list<Integer> eqsindex;
      SimCode.SimCode sc;
      Integer offset;

    case (dlow as BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedEqs=eqsdae)},_), sc as SimCode.SIMCODE(odeEquations={_},zeroCrossings=zeroCrossings))
      equation
        print("\n ----------------------------\n");
        print("BackEndQSS analysis initialized");
        print("\n ----------------------------\n");
        (_,_,orderedVarsList) = getAllVars(dlow);
        // _ = List.filterOnTrue(orderedVarsList,BackendVariable.isStateVar); // TODO: Did this do anything?
        discVarsLst = List.filterOnTrue(orderedVarsList,isDiscreteVar);
        disc = List.map(discVarsLst,BackendVariable.varCref);
        (eqsindex,zc_exps) = getEquationsWithDiscont(zeroCrossings);
        disc = listAppend(disc, newDiscreteVariables(getEquations(eqsdae,eqsindex),0));
        //states = List.map(stateVarsList,BackendVariable.varCref);
        //algs = computeAlgs(eqs,states,{});
        //s = computeStateRef(List.map(states,ComponentReference.crefPrefixDer),eqs,{});
        sc = replaceDiscontsInOde(sc,zc_exps);
      then
        (QSSINFO({},{},disc,{},eqsdae,zc_exps,0),sc);
    else
      equation
        print("- Main function BackendQSS.generateStructureCodeQSS failed\n");
      then
        fail();
  end matchcontinue;
end generateStructureCodeQSS;

public function getAllVars
" outputs a list with all variables and the subset of state variables contained in DAELow
 author: XF
"
  input BackendDAE.BackendDAE inDAELow1;
  output list<BackendDAE.Var> allVarsList;
  output list<BackendDAE.Var> stateVarsList;
  output list<BackendDAE.Var> orderedVarsList;

algorithm
  (allVarsList, stateVarsList, orderedVarsList):=
  match (inDAELow1)
    local
      list<BackendDAE.Var> knownVarsList;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables v,kn;

  case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = v)::{},shared=BackendDAE.SHARED(knownVars = kn)))
    equation
      orderedVarsList = BackendVariable.varList(v);
      knownVarsList = BackendVariable.varList(kn);
      allVarsList = listAppend(orderedVarsList, knownVarsList);
      stateVarsList = BackendVariable.getAllStateVarFromVariables(v);
  then
     (allVarsList, stateVarsList,orderedVarsList) ;
  end match;
end getAllVars;

public function getStateIndices
" finds the indices of the state indices inside a list with variables.
 author: XF
"
  input list<BackendDAE.Var> allVars;
  input list<Integer> stateIndices1;
  input Integer loopIndex1;

  output list<Integer> stateIndices;

algorithm
  stateIndices:=
  matchcontinue (allVars, stateIndices1, loopIndex1)
    local

      list<Integer> stateIndices2;
      Integer loopIndex;
      list<BackendDAE.Var> rest;
      BackendDAE.Var var1;

    case ({}, stateIndices2, _)
      equation
      then
        stateIndices2;

    case (var1::rest, stateIndices2, loopIndex)
      equation
        false = BackendVariable.isStateVar(var1);
        stateIndices = getStateIndices(rest, stateIndices2, loopIndex+1);
      then
        stateIndices;
    case (var1::rest, stateIndices2, loopIndex)
      equation
        true = BackendVariable.isStateVar(var1);
        stateIndices2 = listAppend(stateIndices2, {loopIndex});
        stateIndices2 = getStateIndices(rest, stateIndices2, loopIndex+1);
      then
        stateIndices2;
  end matchcontinue;
end getStateIndices;

public function getDiscreteIndices
" finds the indices of the state indices inside a list with variables.
 author: XF
"

  input list<BackendDAE.Var> allVars;
  input list<Integer> stateIndices1;
  input Integer loopIndex1;

  output list<Integer> stateIndices;

algorithm
  stateIndices:=
  matchcontinue (allVars, stateIndices1, loopIndex1)
    local

      list<Integer> stateIndices2;
      Integer loopIndex;
      list<BackendDAE.Var> rest;
      BackendDAE.Var var1;

    case ({}, stateIndices2, _)
      equation
      then
        stateIndices2;

    case (var1::rest, stateIndices2, loopIndex)
      equation
        false = BackendVariable.isVarDiscrete(var1);
      then
        getDiscreteIndices(rest, stateIndices2, loopIndex+1);
    case (var1::rest, stateIndices2, loopIndex)
      equation
        true = BackendVariable.isVarDiscrete(var1);
        stateIndices2 = listAppend(stateIndices2, {loopIndex});
      then
        getDiscreteIndices(rest, stateIndices2, loopIndex+1);
  end matchcontinue;
end getDiscreteIndices;



////////////////////////////////////////////////////////////////////////////////////////////////////
/////  EQUATION GENERATION
////////////////////////////////////////////////////////////////////////////////////////////////////

public function getStateIndexList
  input QSSinfo qssInfo;
  output list<list<Integer>> refs;
algorithm
  QSSINFO(stateVarIndex=refs) := qssInfo;
end getStateIndexList;

public function getZCExps
  input QSSinfo qssInfo;
  output list<DAE.Exp> exps;
algorithm
  QSSINFO(zcs=exps) := qssInfo;
end getZCExps;

public function getZCOffset
  input QSSinfo qssInfo;
  output Integer o;
algorithm
  QSSINFO(zc_offset=o) := qssInfo;
end getZCOffset;


public function getStates
  input QSSinfo qssInfo;
  output list<DAE.ComponentRef> refs;
algorithm
  QSSINFO(stateVars=refs) := qssInfo;
end getStates;

public function getEqs
  input QSSinfo qssInfo;
  output BackendDAE.EquationArray eqs;
algorithm
  QSSINFO(eqs=eqs) := qssInfo;
end getEqs;


public function getAlgs
  input QSSinfo qssInfo;
  output list<DAE.ComponentRef> algVars;
algorithm
  QSSINFO(algVars=algVars) := qssInfo;
end getAlgs;



public function getDisc
  input QSSinfo qssInfo;
  output list<DAE.ComponentRef> refs;
algorithm
  QSSINFO(discreteVars=refs) := qssInfo;
end getDisc;


protected function replaceInExp
  input DAE.Exp inExp;
  input tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef> > inTpl;
  output DAE.Exp outExp;
  output tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef> > outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp e,e2,expCond,expThen,expElse;
      list<DAE.ComponentRef> states;
      list<DAE.ComponentRef> disc;
      list<DAE.ComponentRef> algs;
      DAE.ComponentRef cr;
      DAE.Type t,t1;
      list<DAE.Subscript> subs;
      Integer p;
      String ident;

    case (DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs))
      equation
      p = List.position1OnTrue(states,ComponentReference.crefEqual,cr);
      ident = stringAppend(stringAppend("x[",intString(p)),"]");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs))
      equation
      p = List.position1OnTrue(states,ComponentReference.crefEqual,cr);
      ident = stringAppend(stringAppend("x[",intString(p)),"]");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs))
      equation
      //p = List.position(cr,disc);
      p = List.position1OnTrue(disc,ComponentReference.crefEqual,cr);
      ident = stringAppend(stringAppend("d[",intString(p)),"]");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs))
      equation
      p = List.position1OnTrue(disc,ComponentReference.crefEqual,cr);
      ident = stringAppend(stringAppend("d[",intString(p)),"]");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs))
      equation
      //p = List.position(cr,algs);
      p = List.position1OnTrue(algs,ComponentReference.crefEqual,cr);
      ident = stringAppend(stringAppend("a[",intString(p)),"]");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs))
      equation
      //p = List.position(cr,algs);
      p = List.position1OnTrue(algs,ComponentReference.crefEqual,cr);
      ident = stringAppend(stringAppend("a[",intString(p)),"]");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.CREF(cr as DAE.CREF_IDENT(_,t1,subs),t),(states,disc,algs))
      equation
      ident=System.stringReplace(ComponentReference.crefStr(cr),".","_");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.CREF(cr as DAE.CREF_QUAL(_,t1,subs,_),t),(states,disc,algs))
      equation
      ident=System.stringReplace(ComponentReference.crefStr(cr),".","_");
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs));
    case (DAE.IFEXP(expCond=expCond as DAE.RELATION(_,_,_,_,_), expThen=expThen,expElse=expElse),(states,disc,algs))
      then (DAE.BINARY(DAE.BINARY(DAE.CALL(Absyn.IDENT("boolToReal"),{expCond},DAE.callAttrBuiltinReal),DAE.MUL(DAE.T_REAL_DEFAULT),expThen),DAE.ADD(DAE.T_REAL_DEFAULT),
            DAE.BINARY(DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("boolToReal"),{expCond},DAE.callAttrBuiltinReal)),DAE.MUL(DAE.T_REAL_DEFAULT),expElse)),(states,disc,algs));
    case (DAE.IFEXP(expCond=expCond, expThen=expThen,expElse=expElse),(states,disc,algs))
      then (DAE.BINARY(DAE.BINARY(expCond,DAE.MUL(DAE.T_REAL_DEFAULT),expThen),DAE.ADD(DAE.T_REAL_DEFAULT),
            DAE.BINARY(DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),expCond),DAE.MUL(DAE.T_REAL_DEFAULT),expElse)),(states,disc,algs));
    case (DAE.CALL(Absyn.IDENT("noEvent"),{e},_),(states,disc,algs))
      then (e,(states,disc,algs));
    case (DAE.CALL(Absyn.IDENT("smooth"),{_,e},_),(states,disc,algs))
      then (e,(states,disc,algs));
    case (DAE.CALL(Absyn.IDENT("DIVISION"),{e,e2,_},_),(states,disc,algs))
      then (DAE.BINARY(e,DAE.DIV(DAE.T_REAL_DEFAULT),e2),(states,disc,algs));
    case (DAE.LBINARY(e as DAE.RCONST(_),DAE.AND(_),e2 as DAE.RELATION(_,_,_,_,_)),(states,disc,algs))
      then (DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("boolToReal"),{e2},DAE.callAttrBuiltinReal)),(states,disc,algs));
    case (DAE.LBINARY(e as DAE.RELATION(_,_,_,_,_),DAE.AND(_),e2 as DAE.RCONST(_)),(states,disc,algs))
      then (DAE.BINARY(e2,DAE.MUL(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("boolToReal"),{e},DAE.callAttrBuiltinReal)),(states,disc,algs));
    case (DAE.BINARY(e,DAE.POW(_),e2),(states,disc,algs))
      then (DAE.CALL(Absyn.IDENT("pow"),{e,e2},DAE.callAttrBuiltinReal),(states,disc,algs));
    case (DAE.BCONST(true),(states,disc,algs))
      then (DAE.RCONST(1.0),(states,disc,algs));
    case (DAE.BCONST(false),(states,disc,algs))
      then (DAE.RCONST(0.0),(states,disc,algs));
    case (e,(states,disc,algs)) then (e,(states,disc,algs));
    end matchcontinue;
end replaceInExp;

public function replaceVars
  input DAE.Exp exp;
  input list<DAE.ComponentRef> states;
  input list<DAE.ComponentRef> disc;
  input list<DAE.ComponentRef> algs;
  output DAE.Exp expout;
algorithm
expout := match (exp,states,disc,algs)
  local
    DAE.Exp e;
  case (_,_,_,_)
  equation
    (e,_)=Expression.traverseExpBottomUp(exp,replaceInExp,(states,disc,algs));
    (e,_)=ExpressionSimplify.simplify(e);
  then e;
  end match;
end replaceVars;



// function computeStateRef
//   input list<DAE.ComponentRef> stateVarsList;
//   input list<SimCode.SimEqSystem> eqs;
//   input list<list<Integer>> acc;
//   output list<list<Integer>> indexs;
// algorithm
// indexs:=
//   matchcontinue (stateVarsList,eqs,acc)
//     local
//       DAE.ComponentRef cref;
//       list<SimCode.SimEqSystem> tail;
//       Integer p;
//       list<list<Integer>> acc_1;
//
//     case (_,{},_) then acc;
//     case (_,((SimCode.SES_SIMPLE_ASSIGN(cref=cref))::tail),_)
//     equation
//       /*
//       print(ComponentReference.crefStr(cref));
//       print("\n");
//       print(ComponentReference.crefStr(listGet(stateVarsList,1)));
//       print("\n");
//       print(ComponentReference.crefStr(listGet(stateVarsList,2)));
//       print("\n");
//       print(ComponentReference.crefStr(listGet(stateVarsList,3)));
//       print("\n");
//       print(ComponentReference.crefStr(listGet(stateVarsList,4)));
//       print("\n");
//       */
//       p = List.position(cref,stateVarsList);
//       acc_1 = listAppend(acc,{{p}});
//     then computeStateRef(stateVarsList,tail,acc_1);
//     case (_,(_::tail),_) then computeStateRef(stateVarsList,tail,acc);
//   end matchcontinue;
// end computeStateRef;

protected function isDiscreteVar
  input BackendDAE.Var var;
  output Boolean result;
algorithm
result :=
          BackendVariable.isVarDiscrete(var) or
          BackendVariable.isVarIntAlg(var) or
          BackendVariable.isVarBoolAlg(var) ;
end isDiscreteVar;

public function replaceCref
  input DAE.ComponentRef cr;
  input list<DAE.ComponentRef> states;
  input list<DAE.ComponentRef> disc;
  input list<DAE.ComponentRef> algs;
  output String out;
algorithm
  out:=matchcontinue (cr,states,disc,algs)
      local
        Integer p;
        DAE.ComponentRef r;
        DAE.Ident ident;
        DAE.Type identType;
        list<DAE.Subscript> subscriptLst;
      case (_,_,_,_)
      equation
        p = List.position1OnTrue(states,ComponentReference.crefEqual,cr);
        then stringAppend(stringAppend("x[",intString(p)),"]");
      case (DAE.CREF_QUAL(_,_,_,r),_,_,_)
      equation
        p = List.position1OnTrue(states,ComponentReference.crefEqual,r);
        then stringAppend(stringAppend("der(x[",intString(p)),"])");
      case (_,_,_,_)
      equation
        p = List.position1OnTrue(disc,ComponentReference.crefEqual,cr);
        then stringAppend(stringAppend("d[",intString(p)),"]");
      case (_,_,_,_)
      equation
        p = List.position1OnTrue(algs,ComponentReference.crefEqual,cr);
        then stringAppend(stringAppend("a[",intString(p)),"]");
      case (_,_,_,_)
      then ComponentReference.printComponentRefStr(cr);
    end matchcontinue;
end replaceCref;

public function negate
  input DAE.Exp exp;
  output DAE.Exp exp_out;
algorithm
  exp_out:=
    matchcontinue (exp)
    local
      DAE.Exp e1,e2;
      Integer i;
      DAE.Type t;
      Option<tuple<DAE.Exp,Integer,Integer>> o;
    case (DAE.RELATION(e1,DAE.LESS(t),e2,i,o)) then DAE.RELATION(e1,DAE.GREATER(t),e2,i,o);
    case (DAE.RELATION(e1,DAE.LESSEQ(t),e2,i,o)) then DAE.RELATION(e1,DAE.GREATER(t),e2,i,o);
    case (DAE.RELATION(e1,DAE.GREATER(t),e2,i,o)) then DAE.RELATION(e1,DAE.LESS(t),e2,i,o);
    case (DAE.RELATION(e1,DAE.GREATEREQ(t),e2,i,o)) then DAE.RELATION(e1,DAE.LESS(t),e2,i,o);
    case (e1) then e1;
  end matchcontinue;
end negate;

public  function generateHandler
    input BackendDAE.EquationArray eqs;
    input list<Integer> handlers;
    input list<DAE.ComponentRef> states;
    input list<DAE.ComponentRef> disc;
    input list<DAE.ComponentRef> algs;
    input DAE.Exp condition;
    input Boolean v;
    input list<DAE.Exp> zc_exps;
    input Integer offset;
    output String out;
algorithm
  out:=
    matchcontinue (eqs,handlers,states,disc,algs,condition,v,zc_exps,offset)
      local
        Integer h;
        DAE.Exp exp,e1;
        DAE.Exp scalar "scalar";
        String s;
        Integer p;
       case (_,{h},_,_,_,_,true,_,_)
       equation
         BackendDAE.EQUATION(exp=exp as DAE.CREF(ty = DAE.T_BOOL(_,_)),scalar=scalar) = BackendEquation.equationNth1(eqs,h);
         s = stringAppend("",ExpressionDump.printExpStr(replaceVars(exp,states,disc,algs)));
         s = stringAppend(s," := ");
         ((e1,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(1.0));
         s= stringAppend(s,ExpressionDump.printExpStr(replaceVars(e1,states,disc,algs)));
         s= stringAppend(s,";");
       then s;
       case (_,{h},_,_,_,_,true,_,_)
       equation
         BackendDAE.EQUATION(exp=exp as DAE.CREF(ty = DAE.T_INTEGER(_,_)),scalar=scalar) = BackendEquation.equationNth1(eqs,h);
         s = stringAppend("",ExpressionDump.printExpStr(replaceVars(exp,states,disc,algs)));
         s = stringAppend(s," := ");
         ((e1,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(1.0));
         s= stringAppend(s,ExpressionDump.printExpStr(replaceVars(e1,states,disc,algs)));
         s= stringAppend(s,";");
       then s;

       case (_,{h},_,_,_,_,true,_,_)
       equation
         BackendDAE.EQUATION() = BackendEquation.equationNth1(eqs,h);
         s = stringAppend("/* We are adding a new discrete variable for ","");
         s = stringAppend(s,ExpressionDump.printExpStr(condition));
         s = stringAppend(s,"*/\n");
         p = List.position1OnTrue(zc_exps,Expression.expEqual,condition);
         s = stringAppend(s,"d[");
         s = stringAppend(s,intString(p+offset));
         s = stringAppend(s,"] := 1.0;\n");
       then s;

       case (_,{h},_,_,_,_,false,_,_)
       equation
         BackendDAE.EQUATION(exp=exp as DAE.CREF(ty=DAE.T_BOOL(_,_)),scalar=scalar) = BackendEquation.equationNth1(eqs,h);
         s= stringAppend("",ExpressionDump.printExpStr(replaceVars(exp,states,disc,algs)));
         s= stringAppend(s," := ");
         ((e1,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(0.0));
         s= stringAppend(s,ExpressionDump.printExpStr(replaceVars(e1,states,disc,algs)));
         s= stringAppend(s,";");
         ((_,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(0.0));
       then s;
       case (_,{h},_,_,_,_,false,_,_)
       equation
         BackendDAE.EQUATION(exp=exp as DAE.CREF(ty=DAE.T_INTEGER(_,_)),scalar=scalar) = BackendEquation.equationNth1(eqs,h);
         s= stringAppend("",ExpressionDump.printExpStr(replaceVars(exp,states,disc,algs)));
         s= stringAppend(s," := ");
         ((e1,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(0.0));
         s= stringAppend(s,ExpressionDump.printExpStr(replaceVars(e1,states,disc,algs)));
         s= stringAppend(s,";");
         ((_,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(0.0));
       then s;
       case (_,{h},_,_,_,_,false,_,_)
       equation
         BackendDAE.EQUATION() = BackendEquation.equationNth1(eqs,h);
         s = stringAppend("/* We are adding a new discrete variable for ","");
         s = stringAppend(s,ExpressionDump.printExpStr(condition));
         s = stringAppend(s,"*/\n");
         p = List.position1OnTrue(zc_exps,Expression.expEqual,condition);
         s = stringAppend(s,"d[");
         s = stringAppend(s,intString(p+offset));
         s = stringAppend(s,"] := 0.0;\n");
       then s;
    end matchcontinue;
end generateHandler;

// function createDummyVars
//   input  Integer n;
//   output list<DAE.ComponentRef> o;
// algorithm
//   o:=match n
//     case 0 then {};
//     case _ then listAppend({DAE.CREF_IDENT("dummy",DAE.T_REAL_DEFAULT,{})},createDummyVars(n-1));
//   end match;
// end createDummyVars;

// function computeAlgs
//   input list<SimCode.SimEqSystem> eqs;
//   input list<DAE.ComponentRef> states;
//   input list<DAE.ComponentRef> i_algs;
//   output list<DAE.ComponentRef> algs;
// algorithm
//   algs:=matchcontinue (eqs,states,i_algs)
//     local
//       list<SimCode.SimEqSystem> tail;
//       list<SimCodeVar.SimVar> vars;
//       DAE.ComponentRef cref;
//       list<DAE.ComponentRef> vars_cref;
//     case (SimCode.SES_SIMPLE_ASSIGN(cref=cref) :: tail,_,_)
//     equation
//       true = List.notMember(cref,List.map(states,ComponentReference.crefPrefixDer));
//       true = List.notMember(cref,states);
//       print("Adding algebraic var:");
//       print(ComponentReference.printComponentRefStr(cref));
//       print("\n");
//     then computeAlgs(tail,states,listAppend(i_algs,{cref}));
//     case ((SimCode.SES_LINEAR(vars=vars)) :: tail,_,_)
//     equation
//       vars_cref = List.map(vars,SimCodeUtil.varName);
//     then computeAlgs(tail,states,listAppend(i_algs,vars_cref));
//     case ({},_,_)
//     equation
//       then i_algs;
//     case (_ :: tail,_,_)
//     then computeAlgs(tail,states,i_algs);
//   end matchcontinue;
// end computeAlgs;

protected function getExpResidual
  input SimCode.SimEqSystem i;
  output DAE.Exp o;
algorithm
  o:=match (i)
  local DAE.Exp e;
  case (SimCode.SES_RESIDUAL(exp=e)) then e;
  end match;
end getExpResidual;

protected function getExpCrefs
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> i;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> out;
algorithm
  (outExp,out) :=matchcontinue (inExp,i)
    local
      list<DAE.ComponentRef> l;
      DAE.ComponentRef cr;
      DAE.Exp e;
    case (e as DAE.CREF(cr,_),l) then (e,listAppend(l,{cr}));
    case (e,l) then (e,l);
  end matchcontinue;
end getExpCrefs;

function getCrefs
  input list<DAE.Exp> e;
  input list<DAE.ComponentRef> acc;
  output list<DAE.ComponentRef> out;
algorithm
  out:=match(e,acc)
    local DAE.Exp e1;
          list<DAE.Exp> tail;
          list<DAE.ComponentRef> l;
    case ({},_) then acc;
    case (e1 :: tail ,_)
    equation
      (_,l) = Expression.traverseExpBottomUp(e1,getExpCrefs,{});
      then getCrefs(tail,listAppend(acc,l));
  end match;
end getCrefs;

public function getRHSVars
  input list<DAE.Exp> beqs;
  input list<SimCodeVar.SimVar> vars;
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
  input list<DAE.ComponentRef> states,disc,algs;
  output list<DAE.ComponentRef> out;
algorithm
  out:= match (beqs,vars,simJac,states,disc,algs)
    local
      list<DAE.ComponentRef> vars_cref;
      list<DAE.Exp> eqs;
  case (_,_,_,_,_,_)
  equation
    vars_cref = getCrefs(beqs,{});
    eqs = List.map(List.map(simJac,Util.tuple33),getExpResidual);
    vars_cref = getCrefs(eqs,vars_cref);
    /* TODO: Check matrix A for discrete values */
    vars_cref = List.intersectionOnTrue(listAppend(states,listAppend(disc,algs)),vars_cref,ComponentReference.crefEqual);
    then vars_cref;
  end match;
end getRHSVars;

function getInitExp
  input  list<SimCodeVar.SimVar> vars;
  input  DAE.ComponentRef d;
  output String s;
algorithm
  s:=
    matchcontinue(vars,d)
    local
      list<SimCodeVar.SimVar> tail;
      DAE.Exp initialExp;
      DAE.ComponentRef name;
      String t;
    case ({},_) then stringAppend(stringAppend("0.0 /* ",ComponentReference.crefStr(d))," */ ;");
    case (SimCodeVar.SIMVAR(name=name,initialValue=SOME(initialExp as DAE.BCONST(_))):: _,_)
    equation
      true = ComponentReference.crefEqual(name,d);
      t = stringAppend("(",ExpressionDump.printExpStr(replaceVars(initialExp,{},{},{})));
      t = stringAppend(t,") /* ");
      t = stringAppend(t,ComponentReference.crefStr(d));
      t = stringAppend(t,"*/;");
    then t;
    case (SimCodeVar.SIMVAR(name=name,initialValue=SOME(initialExp)):: _,_)
    equation
      true = ComponentReference.crefEqual(name,d);
      t = stringAppend("",ExpressionDump.printExpStr(replaceVars(initialExp,{},{},{})));
      t = stringAppend(t," /* ");
      t = stringAppend(t,ComponentReference.crefStr(d));
      t = stringAppend(t,"*/;");
    then t;

    case (_:: tail,_) then getInitExp(tail,d);
  end matchcontinue;
end getInitExp;

public function generateDInit
  input  list<DAE.ComponentRef> disc;
  //input  list<SimCode.SampleCondition> sample;
  input  SimCodeVar.SimVars vars;
  input  Integer acc;
  input  Integer total;
  input  Integer nWhenClause;
  output String out;
algorithm
  out:=matchcontinue(disc,vars,acc,total,nWhenClause)
    local
      list<DAE.ComponentRef> tail;
      DAE.ComponentRef cref;
      String s;
      list<SimCodeVar.SimVar> intAlgVars;
      list<SimCodeVar.SimVar> boolAlgVars;
      list<SimCodeVar.SimVar> algVars;
    case ({},_,_,_,_) then "";
    case (_::tail,_,_,_,_)
    equation
      true = total - acc -1  < nWhenClause;
      s=stringAppend("","d[");
      s=stringAppend(s,intString(acc+1));
      s=stringAppend(s,"]:=");
      //s=stringAppend(s,getStartTime(listGet({},total-acc-1)));
      s=stringAppend(s,";\n");
    then stringAppend(s,generateDInit(tail,vars,acc+1,total,nWhenClause));

    case (cref::tail,SimCodeVar.SIMVARS(intAlgVars=intAlgVars,boolAlgVars=boolAlgVars,algVars=algVars),_,_,_)
    equation
      s=stringAppend("","d[");
      s=stringAppend(s,intString(acc+1));
      s=stringAppend(s,"]:=");
      s=stringAppend(s,getInitExp(listAppend(algVars,listAppend(intAlgVars,boolAlgVars)),cref));
      s=stringAppend(s,"\n");
    then stringAppend(s,generateDInit(tail,vars,acc+1,total,nWhenClause));

  end matchcontinue;
end generateDInit;


public function generateInitialParamEquations
  input  SimCode.SimEqSystem eq;
  output String t;
algorithm
  t:=
  match (eq)
  local
    DAE.ComponentRef cref;
    DAE.Exp exp;
  case (SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp))

  equation
    t = stringAppend("",System.stringReplace(replaceCref(cref,{},{},{}),".","_"));
    t = stringAppend(t," := ");
    t = stringAppend(t,ExpressionDump.printExpStr(replaceVars(exp,{},{},{})));
    t = stringAppend(t,";");
  then t;
  end match;
end generateInitialParamEquations;

public function generateExtraParams
  input SimCode.SimEqSystem eq;
  input SimCodeVar.SimVars vars;
  output String s;
algorithm
  s:=
  match (eq,vars)
  local
    DAE.ComponentRef cref;
    list<SimCodeVar.SimVar> paramVars;
    list<SimCodeVar.SimVar> intParamVars;
    list<SimCodeVar.SimVar> boolParamVars;
    Integer i;
    DAE.Exp exp;
    String t;
  case (SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp),
        SimCodeVar.SIMVARS(paramVars=paramVars,intParamVars=intParamVars,boolParamVars=boolParamVars))
  equation
    failure(_ = List.position(cref,List.map(paramVars,SimCodeUtil.varName)));
    failure(_ = List.position(cref,List.map(intParamVars,SimCodeUtil.varName)));
    failure(_ = List.position(cref,List.map(boolParamVars,SimCodeUtil.varName)));
    t = stringAppend("parameter Real ",System.stringReplace(replaceCref(cref,{},{},{}),".","_"));
    t = stringAppend(t," = ");
    t = stringAppend(t,ExpressionDump.printExpStr(replaceVars(exp,{},{},{})));
    t = stringAppend(t,";");
  then t;
  end match;
end generateExtraParams;

public function replaceVarsInputs
  input DAE.Exp exp;
  input list<DAE.ComponentRef> inp;
  output DAE.Exp exp_out;
algorithm
  exp_out:=
    match (exp,inp)
    local
      DAE.Exp e;
    case (_,_)
    equation
      (e,_) = Expression.traverseExpBottomUp(exp, replaceInExpInputs, inp);
      then replaceVars(e,{},{},{});
    end match;
end replaceVarsInputs;

protected function replaceInExpInputs
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inTpl;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
     local
       DAE.ComponentRef cr;
       DAE.Type t,t1;
       list<DAE.Subscript> subs;
       list<DAE.ComponentRef> inputs;
       Integer p;
       String ident;
       DAE.Exp e;
     case (DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),inputs)
      equation
      p = List.position1OnTrue(inputs,ComponentReference.crefEqual,cr)-1 "shift to zero-based index";
      ident = stringAppend("i",intString(p));
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),inputs);
    case (DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),inputs)
      equation
      p = List.position1OnTrue(inputs,ComponentReference.crefEqual,cr)-1 "shift to zero-based index";
      ident = stringAppend("i",intString(p));
      then (DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),inputs);
    case (e,inputs) then (e,inputs);
  end matchcontinue;
end replaceInExpInputs;


public function getDiscRHSVars
  input list<DAE.Exp> beqs;
  input list<SimCodeVar.SimVar> vars;
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
  input list<DAE.ComponentRef> states;
  input list<DAE.ComponentRef> disc;
  input list<DAE.ComponentRef> algs;
  output list<DAE.ComponentRef> out;
algorithm
  out:= match (beqs,vars,simJac,states,disc,algs)
    local
      list<DAE.ComponentRef> vars_cref;
      list<DAE.Exp> eqs;
  case (_,_,_,_,_,_)
  equation
    vars_cref = {};
    eqs = List.map(List.map(simJac,Util.tuple33),getExpResidual);
    vars_cref = getCrefs(eqs,vars_cref);
    /* TODO: Check matrix A for discrete values */
    vars_cref = List.intersectionOnTrue(listAppend(states,listAppend(disc,algs)),vars_cref,ComponentReference.crefEqual);
    then vars_cref;
  end match;

end getDiscRHSVars;


public function simpleWhens
  input list<SimCode.SimWhenClause> i;
  output list<SimCode.SimWhenClause> o;
algorithm
  o:=
    match i
    local
      list<SimCode.SimWhenClause> tail;
      SimCode.SimWhenClause head;
    case {} then {};
    /* lochel: conditions is now a list of ComponentRefs
    case (SimCode.SIM_WHEN_CLAUSE(conditions={DAE.CALL(path=Absyn.IDENT(name="sample"))}) :: tail)
      then simpleWhens(tail);
     */
    case (head :: tail)
      then listAppend({head},simpleWhens(tail));
    end match;
end simpleWhens;


public function sampleWhens
  input list<SimCode.SimWhenClause> i;
  output list<SimCode.SimWhenClause> o;
algorithm
  o:=
    match i
    local
      list<SimCode.SimWhenClause> tail;
      SimCode.SimWhenClause head;
    case {} then {};
    /* lochel: conditions is now a list of ComponentRefs
    case ((head as SimCode.SIM_WHEN_CLAUSE(conditions={DAE.CALL(path=Absyn.IDENT(name="sample"))})) :: tail)
      then listAppend({head},sampleWhens(tail));
     */
    case (_ :: tail)
      then sampleWhens(tail);
    end match;
end sampleWhens;

function newDiscreteVariables
  input list<BackendDAE.Equation> inEquationLst;
  input Integer zc;
  output list<DAE.ComponentRef> d;
algorithm
  d := match (inEquationLst,zc)
    local
      list<BackendDAE.Equation> tail;
      String s;
    case ({},_) then {};
    case (BackendDAE.EQUATION(exp=DAE.CREF(ty = DAE.T_BOOL(_,_))) :: tail,_) then newDiscreteVariables(tail,zc);
    case (BackendDAE.EQUATION(exp=DAE.CREF(ty = DAE.T_INTEGER(_,_))) :: tail,_) then newDiscreteVariables(tail,zc);
    case ( _ :: tail,_)
    equation
      print("Found one discontinuous equation\n");
      s = stringAppend("zc ",intString(zc));
    then listAppend({DAE.CREF_IDENT(s,DAE.T_REAL_DEFAULT,{})},newDiscreteVariables(tail,zc+1));
  end match;
end newDiscreteVariables;

function getEquationsWithDiscont
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  output list<Integer> out;
  output list<DAE.Exp> outexp;
algorithm
 (out,outexp) := match zeroCrossings
  local
    list<BackendDAE.ZeroCrossing> tail;
    list<Integer> occurEquLst;
    list<Integer> o;
    list<DAE.Exp> exps;
    DAE.Exp relation;
  case ({}) then ({},{});
  case (BackendDAE.ZERO_CROSSING(occurEquLst=occurEquLst,relation_=relation) :: tail)
    equation
      (o,exps) = getEquationsWithDiscont(tail);
    then (listAppend(occurEquLst,o),listAppend({relation},exps));
  end match;
end getEquationsWithDiscont;


function getEquations
  input BackendDAE.EquationArray eqsdae;
  input list<Integer> indx "zero-based indexing";
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := match (eqsdae,indx)
    local
      list<Integer> tail;
      Integer p;
      list<BackendDAE.Equation> res;
      BackendDAE.Equation eq;
    case (_,{}) then {};
    case (_,p::tail)
    equation
      eq = BackendEquation.equationNth1(eqsdae,p+1);
      res = listAppend({eq},getEquations(eqsdae,tail));
    then res;
  end match;
end getEquations;

function replaceDiscontsInOde
  input SimCode.SimCode sin;
  input list<DAE.Exp> zc_exps;
  output SimCode.SimCode sout;
algorithm
  sout:=match (sin,zc_exps)
    local
      SimCode.ModelInfo modelInfo;
      list<DAE.Exp> literals "shared literals";
      list<SimCode.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<list<SimCode.SimEqSystem>> algebraicEquations,odeEquations;
      list<SimCode.SimEqSystem> allEquations,startValueEquations,nominalValueEquations,minValueEquations,maxValueEquations,parameterEquations,removedEquations,algorithmAndEquationAsserts,jacobianEquations;
      list<SimCode.SimEqSystem> equationsForZeroCrossings;
      list<SimCode.StateSet> stateSets;
      Boolean useSymbolicInitialization, useHomotopy;
      list<SimCode.SimEqSystem> initialEquations, removedInitialEquations;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings,relations;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      list<SimCode.SimEqSystem> eqs;
      list<BackendDAE.TimeEvent> timeEvents;
      HpcOmSimCode.HpcOmData hpcomData;
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      HashTableCrILst.HashTable varToIndexMapping;
      Option<SimCode.FmiModelStructure> modelStruct;
      list<SimCodeVar.SimVar> mixedArrayVars;
      Option<SimCode.BackendMapping> backendMapping;
      list<BackendDAE.BaseClockPartitionKind> partitionsKind;
      list<DAE.ClockKind> baseClocks;

    case (SimCode.SIMCODE( modelInfo, literals, recordDecls, externalFunctionIncludes, allEquations, odeEquations, algebraicEquations, partitionsKind, baseClocks,
                           useSymbolicInitialization, useHomotopy, initialEquations, removedInitialEquations, startValueEquations, nominalValueEquations,
                           minValueEquations, maxValueEquations, parameterEquations, removedEquations, algorithmAndEquationAsserts, equationsForZeroCrossings,
                           jacobianEquations, stateSets, constraints, classAttributes, zeroCrossings, relations, timeEvents, whenClauses, discreteModelVars,
                           extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, hpcomData, varToArrayIndexMapping,
                           varToIndexMapping, crefToSimVarHT, backendMapping, modelStruct ),_)
    equation
      {eqs} = odeEquations;
      eqs = List.map1(eqs,replaceZC,zc_exps);
    then SimCode.SIMCODE( modelInfo, literals, recordDecls, externalFunctionIncludes, allEquations, {eqs}, algebraicEquations, partitionsKind, baseClocks,
                          useSymbolicInitialization, useHomotopy, initialEquations, removedInitialEquations, startValueEquations, nominalValueEquations,
                          minValueEquations, maxValueEquations, parameterEquations, removedEquations, algorithmAndEquationAsserts, equationsForZeroCrossings,
                          jacobianEquations, stateSets, constraints, classAttributes, zeroCrossings, relations, timeEvents, whenClauses, discreteModelVars,
                          extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, hpcomData, varToArrayIndexMapping,
                          varToIndexMapping, crefToSimVarHT, backendMapping, modelStruct);

  end match;
end replaceDiscontsInOde;


function replaceZC
  input SimCode.SimEqSystem eq;
  input list<DAE.Exp> zc_exps;
  output SimCode.SimEqSystem eq_out;
algorithm
  eq_out :=
    matchcontinue (eq,zc_exps)
      local
        Integer index;
        DAE.Exp exp;
        DAE.ComponentRef cref;
        DAE.ElementSource source;
      case (SimCode.SES_SIMPLE_ASSIGN(index,cref,exp,source),_)
      equation
        exp = replaceExpZC(exp,zc_exps,0);
      then SimCode.SES_SIMPLE_ASSIGN(index,cref,exp,source);
      case (_,_) then eq;
    end matchcontinue;
end replaceZC;

function replaceExpZC
  input DAE.Exp exp;
  input list<DAE.Exp> zc_exps;
  input Integer indx;
  output DAE.Exp out;
algorithm
  out :=
    match (exp,zc_exps,indx)
    local
      DAE.Exp exp1,e;
      list<DAE.Exp> tail;
    case (_,{},_) then exp;
    case (_,exp1::tail,_)
      equation
        (e,_) = Expression.traverseExpBottomUp(exp, replaceInExpZC, (exp1,indx));
      then replaceExpZC(e,tail,indx+1);
    end match;
end replaceExpZC;


function replaceInExpZC
  input DAE.Exp inExp;
  input tuple<DAE.Exp,Integer> inTpl;
  output DAE.Exp outExp;
  output tuple<DAE.Exp,Integer> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp e,zc;
      Integer i;
      String s;
    case (e,(zc,i))
      equation
        true = Expression.expEqual(e,zc);
        s = stringAppend("zc ",intString(i));
      then (DAE.CREF(DAE.CREF_IDENT(s,DAE.T_REAL_DEFAULT,{}),DAE.T_REAL_DEFAULT),(zc,i));
    else (inExp,inTpl);
  end matchcontinue;
end replaceInExpZC;

////////////////////////////////////////////////////////////////////////////////////////////////////
/////  END OF PACKAGE
////////////////////////////////////////////////////////////////////////////////////////////////////
annotation(__OpenModelica_Interface="backend");
end BackendQSS;
