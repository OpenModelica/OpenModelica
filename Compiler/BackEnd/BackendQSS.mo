/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


encapsulated package BackendQSS
" file:        BackendQSS.mo
  package:     BackendQSS
  description: BackendQSS contains the datatypes used by the backend for QSS solver.
  authors: florosx, fbergero

  $Id$
"

public import ExpressionSimplify;
public import SimCode;
public import System;
public import BackendDAE;
public import DAE;
public import Absyn;
public import Util;
public import ExpressionDump;
public import Expression;
public import BackendDAEUtil;
public import BackendDump;


protected import BackendVariable;
protected import BackendDAETransform;
protected import ComponentReference;
protected import List;

public
uniontype QSSinfo "- equation indices in static blocks and DEVS structure"
  record QSSINFO
    list<list<Integer>> stateVarIndex;
    list<DAE.ComponentRef> stateVars;
    list<DAE.ComponentRef> discreteVars;
    list<DAE.ComponentRef> algVars;
    BackendDAE.EquationArray eqs;
  end QSSINFO;
end QSSinfo;

public function generateStructureCodeQSS 
  input BackendDAE.BackendDAE inBackendDAE;
  input array<Integer> equationIndices;
  input array<Integer> variableIndices;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.StrongComponents strongComponents;
  input SimCode.SimCode simCode;
  
  output QSSinfo QSSinfo_out;
  output SimCode.SimCode simC;
algorithm
  (QSSinfo_out,simC) :=
  matchcontinue (inBackendDAE, equationIndices, variableIndices, inIncidenceMatrix, inIncidenceMatrixT, strongComponents,simCode)
    local
       QSSinfo qssInfo;
       BackendDAE.BackendDAE dlow;
       list<BackendDAE.Var> allVarsList, stateVarsList,orderedVarsList,discVarsLst,algVarsList;
       BackendDAE.StrongComponents comps;
       BackendDAE.IncidenceMatrix m, mt;
       array<Integer> ass1, ass2;
       BackendDAE.EqSystem syst;
       list<SimCode.SimEqSystem> eqs;
       list<list<Integer>> s;
       list<DAE.ComponentRef> states,disc,algs;
       list<SimCode.SampleCondition> sampleConditions;
        BackendDAE.EquationArray eqsdae;
        BackendDAE.Shared shared;
    case (dlow as BackendDAE.DAE({BackendDAE.EQSYSTEM(_,eqsdae,_,_,_)},shared), ass1, ass2, 
          m, mt, comps,SimCode.SIMCODE(odeEquations={eqs},sampleConditions=sampleConditions))
      equation
        print("\n ----------------------------\n");
        print("BackEndQSS analysis initialized");
        print("\n ----------------------------\n");
        (allVarsList, stateVarsList,orderedVarsList) = getAllVars(dlow);
        stateVarsList = List.filterOnTrue(orderedVarsList,BackendVariable.isStateVar);
        discVarsLst = List.filterOnTrue(orderedVarsList,isDiscreteVar);
        disc = List.map(discVarsLst,getCref);
        disc = listAppend(disc, createDummyVars(listLength(sampleConditions)));
        states = List.map(stateVarsList,getCref);
        algs = computeAlgs(eqs,states,{});
        s = computeStateRef(List.map(states,ComponentReference.crefPrefixDer),eqs,{});
      then
        (QSSINFO(s,states,disc,algs,eqsdae),simCode);
    else
      equation
        print("- Main function BackendQSS.generateStructureCodeQSS failed\n");
      then
        fail();          
  end matchcontinue;
end generateStructureCodeQSS;

public function getAllVars
"function: getAllVars 
 outputs a list with all variables and the subset of state variables contained in DAELow
 author: XF
"
  input BackendDAE.BackendDAE inDAELow1;
  output list<BackendDAE.Var> allVarsList; 
  output list<BackendDAE.Var> stateVarsList; 
  output list<BackendDAE.Var> orderedVarsList; 
   
algorithm 
  (allVarsList, stateVarsList, orderedVarsList):=
  matchcontinue (inDAELow1)
    local
      list<BackendDAE.Var> orderedVarsList, knownVarsList, allVarsList;
      BackendDAE.BackendDAE dae;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> alg;
  case (dae as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = v)::{},shared=BackendDAE.SHARED(knownVars = kn)))
    equation
      orderedVarsList = BackendDAEUtil.varList(v);
      knownVarsList = BackendDAEUtil.varList(kn);
      allVarsList = listAppend(orderedVarsList, knownVarsList);
      stateVarsList = BackendVariable.getAllStateVarFromVariables(v);
  then
     (allVarsList, stateVarsList,orderedVarsList) ;
  end matchcontinue;     
end getAllVars;

public function getStateIndices 
"function: getStateIndices 
 finds the indices of the state indices inside a list with variables.
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
    
    case ({}, stateIndices2, loopIndex)
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
"function: getDiscreteIndices 
 finds the indices of the state indices inside a list with variables.
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
    
    case ({}, stateIndices2, loopIndex)
      equation             
      then
        stateIndices2;
        
    case (var1::rest, stateIndices2, loopIndex)
      equation     
        false = BackendVariable.isVarDiscrete(var1);
        stateIndices = getDiscreteIndices(rest, stateIndices2, loopIndex+1);  
      then
        stateIndices;
    case (var1::rest, stateIndices2, loopIndex)
      equation     
        true = BackendVariable.isVarDiscrete(var1);
        stateIndices2 = listAppend(stateIndices2, {loopIndex});
        stateIndices2 = getDiscreteIndices(rest, stateIndices2, loopIndex+1);  
      then
        stateIndices2;
  end matchcontinue;
end getDiscreteIndices;



////////////////////////////////////////////////////////////////////////////////////////////////////
/////  EQUATION GENERATION 
////////////////////////////////////////////////////////////////////////////////////////////////////

public function getCref
  input BackendDAE.Var var;
  output DAE.ComponentRef cr;
algorithm
  cr := matchcontinue (var)
    local
      DAE.ComponentRef cref;
    case (BackendDAE.VAR(varName = cref))
    then cref;
  end matchcontinue;
end getCref;

public function getStateIndexList
  input QSSinfo qssInfo;
  output list<list<Integer>> refs;
algorithm
refs := match qssInfo 
  local 
    list<list<Integer>> s;
  case (QSSINFO(stateVarIndex=s))
  then s;
  end match;
end getStateIndexList;

public function getStates
  input QSSinfo qssInfo;
  output list<DAE.ComponentRef> refs;
algorithm
refs := match qssInfo 
  local 
    list<DAE.ComponentRef> s;
  case (QSSINFO(stateVars=s))
  then s;
  end match;
end getStates;

public function getEqs
  input QSSinfo qssInfo;
  output BackendDAE.EquationArray eqs;
algorithm
eqs := match qssInfo 
  local 
    BackendDAE.EquationArray s;
  case (QSSINFO(eqs=s))
  then s;
  end match;
end getEqs;


public function getAlgs
  input QSSinfo qssInfo;
  output list<DAE.ComponentRef> refs;
algorithm
refs := match qssInfo 
  local 
    list<DAE.ComponentRef> s;
  case (QSSINFO(algVars=s))
  then s;
  end match;
end getAlgs;



public function getDisc
  input QSSinfo qssInfo;
  output list<DAE.ComponentRef> refs;
algorithm
refs := match qssInfo 
  local 
    list<DAE.ComponentRef> s;
  case (QSSINFO(discreteVars=s))
  then s;
  end match;
end getDisc;


function replaceInExp
  input tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef> > > tplExpStates;
  output tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>,list<DAE.ComponentRef> > > tplExpStatesOut;
algorithm
  tplExpStatesOut:=
  matchcontinue (tplExpStates)
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

    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs)))
      equation
      p = List.positionOnTrue(cr,states,ComponentReference.crefEqual);
      ident = stringAppend(stringAppend("x[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs)))
      equation
      p = List.positionOnTrue(cr,states,ComponentReference.crefEqual);
      ident = stringAppend(stringAppend("x[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs)))
      equation
      //p = List.position(cr,disc);
      p = List.positionOnTrue(cr,disc,ComponentReference.crefEqual);
      ident = stringAppend(stringAppend("d[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs)))
      equation
      p = List.positionOnTrue(cr,disc,ComponentReference.crefEqual);
      ident = stringAppend(stringAppend("d[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs)))
      equation
      //p = List.position(cr,algs);
      p = List.positionOnTrue(cr,algs,ComponentReference.crefEqual);
      ident = stringAppend(stringAppend("a[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs)))
      equation
      //p = List.position(cr,algs);
      p = List.positionOnTrue(cr,algs,ComponentReference.crefEqual);
      ident = stringAppend(stringAppend("a[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(cr as DAE.CREF_IDENT(_,t1,subs),t),(states,disc,algs)))
      equation
      ident=System.stringReplace(ComponentReference.crefStr(cr),".","_");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(cr as DAE.CREF_QUAL(_,t1,subs,_),t),(states,disc,algs)))
      equation
      ident=System.stringReplace(ComponentReference.crefStr(cr),".","_");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.IFEXP(expCond=expCond as DAE.RELATION(_,_,_,_,_), expThen=expThen,expElse=expElse),(states,disc,algs))) 
      then ((DAE.BINARY(DAE.BINARY(DAE.CALL(Absyn.IDENT("boolToReal"),{expCond},DAE.callAttrBuiltinReal),DAE.MUL(DAE.T_REAL_DEFAULT),expThen),DAE.ADD(DAE.T_REAL_DEFAULT),
             DAE.BINARY(DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("boolToReal"),{expCond},DAE.callAttrBuiltinReal)),DAE.MUL(DAE.T_REAL_DEFAULT),expElse)),(states,disc,algs)));
    case ((e as DAE.IFEXP(expCond=expCond, expThen=expThen,expElse=expElse),(states,disc,algs)))
      then ((DAE.BINARY(DAE.BINARY(expCond,DAE.MUL(DAE.T_REAL_DEFAULT),expThen),DAE.ADD(DAE.T_REAL_DEFAULT),
             DAE.BINARY(DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),expCond),DAE.MUL(DAE.T_REAL_DEFAULT),expElse)),(states,disc,algs)));
    case ((DAE.CALL(Absyn.IDENT("noEvent"),{e},_),(states,disc,algs)))
      then ((e,(states,disc,algs)));
    case ((DAE.CALL(Absyn.IDENT("smooth"),{_,e},_),(states,disc,algs)))
      then ((e,(states,disc,algs)));
    case ((DAE.CALL(Absyn.IDENT("DIVISION"),{e,e2,_},_),(states,disc,algs)))
      then ((DAE.BINARY(e,DAE.DIV(DAE.T_REAL_DEFAULT),e2),(states,disc,algs)));
    case ((DAE.LBINARY(e as DAE.RCONST(_),DAE.AND(_),e2 as DAE.RELATION(_,_,_,_,_)),(states,disc,algs)))
      then ((DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("boolToReal"),{e2},DAE.callAttrBuiltinReal)),(states,disc,algs)));
    case ((DAE.LBINARY(e as DAE.RELATION(_,_,_,_,_),DAE.AND(_),e2 as DAE.RCONST(_)),(states,disc,algs)))
      then ((DAE.BINARY(e2,DAE.MUL(DAE.T_REAL_DEFAULT),DAE.CALL(Absyn.IDENT("boolToReal"),{e},DAE.callAttrBuiltinReal)),(states,disc,algs)));
    case ((DAE.BINARY(e,DAE.POW(_),e2),(states,disc,algs)))
      then ((DAE.CALL(Absyn.IDENT("pow"),{e,e2},DAE.callAttrBuiltinReal),(states,disc,algs)));
    case ((DAE.BCONST(true),(states,disc,algs)))
      then ((DAE.RCONST(1.0),(states,disc,algs)));
    case ((DAE.BCONST(false),(states,disc,algs)))
      then ((DAE.RCONST(0.0),(states,disc,algs)));
    case ((e,(states,disc,algs))) then ((e,(states,disc,algs)));
    end matchcontinue;
end replaceInExp;

public function replaceVars
  input DAE.Exp exp;
  input list<DAE.ComponentRef> states;
  input list<DAE.ComponentRef> disc;
  input list<DAE.ComponentRef> algs;
  output DAE.Exp expout;
algorithm
expout := matchcontinue (exp,states,disc,algs)
  local
    DAE.Exp e;
  case (_,_,_,_) 
  equation 
    ((e,_))=Expression.traverseExp(exp,replaceInExp,(states,disc,algs));
    (e,_)=ExpressionSimplify.simplify(e);
  then e;
  end matchcontinue;
end replaceVars;



function computeStateRef
  input list<DAE.ComponentRef> stateVarsList;
  input list<SimCode.SimEqSystem> eqs;
  input list<list<Integer>> acc;
  output list<list<Integer>> indexs;
algorithm
indexs:=
  matchcontinue (stateVarsList,eqs,acc)
    local 
      DAE.ComponentRef cref;
      list<SimCode.SimEqSystem> tail;
      Integer p;
      list<list<Integer>> acc_1;

    case (_,{},acc) then acc;
    case (_,((SimCode.SES_SIMPLE_ASSIGN(cref=cref))::tail),_) 
    equation
      /*
      print(ComponentReference.crefStr(cref));
      print("\n");
      print(ComponentReference.crefStr(listNth(stateVarsList,0)));
      print("\n");
      print(ComponentReference.crefStr(listNth(stateVarsList,1)));
      print("\n");
      print(ComponentReference.crefStr(listNth(stateVarsList,2)));
      print("\n");
      print(ComponentReference.crefStr(listNth(stateVarsList,3)));
      print("\n");
      */
      p = List.position(cref,stateVarsList)+1;
      acc_1 = listAppend(acc,{{p}});
    then computeStateRef(stateVarsList,tail,acc_1);
    case (_,(_::tail),_) then computeStateRef(stateVarsList,tail,acc);
  end matchcontinue;
end computeStateRef;

function isDiscreteVar
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
        p = List.positionOnTrue(cr,states,ComponentReference.crefEqual);
        then stringAppend(stringAppend("x[",intString(p+1)),"]");
      case (DAE.CREF_QUAL(ident,identType,subscriptLst,r),_,_,_)
      equation
        ident=DAE.derivativeNamePrefix;
        identType=DAE.T_REAL_DEFAULT;
        subscriptLst={};
        p = List.positionOnTrue(r,states,ComponentReference.crefEqual);
        then stringAppend(stringAppend("der(x[",intString(p+1)),"])");
      case (_,_,_,_)
      equation
        p = List.positionOnTrue(cr,disc,ComponentReference.crefEqual);
        then stringAppend(stringAppend("d[",intString(p+1)),"]");
      case (_,_,_,_)
      equation
        p = List.positionOnTrue(cr,algs,ComponentReference.crefEqual);
        then stringAppend(stringAppend("a[",intString(p+1)),"]");
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
      DAE.Operator op;
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
    output String out;
algorithm
  out:=
    matchcontinue (eqs,handlers,states,disc,algs,condition,v) 
      local 
        Integer h;
        Boolean b;
        BackendDAE.Equation eq;
        DAE.Exp exp,e1;
        DAE.Exp scalar "scalar" ;
        String s;
       case (_,{h},_,_,_,_,true) 
       equation
         BackendDAE.EQUATION(exp=exp,scalar=scalar) = BackendDAEUtil.equationNth(eqs,h-1);
         s = stringAppend("",ExpressionDump.printExpStr(replaceVars(exp,states,disc,algs)));
         s = stringAppend(s," := ");
         ((e1,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(1.0));
         s= stringAppend(s,ExpressionDump.printExpStr(replaceVars(e1,states,disc,algs)));
         s= stringAppend(s,";");
       then s;
       case (_,{h},_,_,_,_,false) 
       equation
         BackendDAE.EQUATION(exp=exp,scalar=scalar) = BackendDAEUtil.equationNth(eqs,h-1);
         s= stringAppend("",ExpressionDump.printExpStr(replaceVars(exp,states,disc,algs)));
         s= stringAppend(s," := ");
         ((e1,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(0.0));
         s= stringAppend(s,ExpressionDump.printExpStr(replaceVars(e1,states,disc,algs)));
         s= stringAppend(s,";");
         ((e1,_))=Expression.replaceExp(scalar,condition,DAE.RCONST(0.0));
       then s;
    end matchcontinue;
end generateHandler;

function createDummyVars
  input  Integer n;
  output list<DAE.ComponentRef> o;
algorithm
  o:=match n
    case 0 then {};
    case _ then listAppend({DAE.CREF_IDENT("dummy",DAE.T_REAL_DEFAULT,{})},createDummyVars(n-1));
  end match;
end createDummyVars;

function computeAlgs
  input list<SimCode.SimEqSystem> eqs;
  input list<DAE.ComponentRef> states;
  input list<DAE.ComponentRef> i_algs;
  output list<DAE.ComponentRef> algs;
algorithm
  algs:=matchcontinue (eqs,states,i_algs)
    local 
      list<SimCode.SimEqSystem> tail;
      list<SimCode.SimVar> vars;
      SimCode.SimEqSystem eq;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> vars_cref;
    case (SimCode.SES_SIMPLE_ASSIGN(cref,_,_) :: tail,_,i_algs) 
    equation
      true = List.notMember(cref,List.map(states,ComponentReference.crefPrefixDer));
      true = List.notMember(cref,states);
      print("Adding algebraic var:");
      print(ComponentReference.printComponentRefStr(cref));
      print("\n");
    then computeAlgs(tail,states,listAppend(i_algs,{cref}));
    case ((SimCode.SES_LINEAR(vars=vars)) :: tail,_,i_algs) 
    equation
      vars_cref = List.map(vars,SimCode.varName);
    then computeAlgs(tail,states,listAppend(i_algs,vars_cref));
    case ({},_,i_algs)
    equation
      then i_algs;
    case (_ :: tail,_,i_algs) 
    then computeAlgs(tail,states,i_algs);
  end matchcontinue;
end computeAlgs;

function getExpResidual 
  input SimCode.SimEqSystem i;
  output DAE.Exp o;
algorithm
  o:=match (i) 
  local DAE.Exp e;
  case (SimCode.SES_RESIDUAL(e,_)) then e;
  end match;
end getExpResidual;

function getExpCrefs
  input tuple<DAE.Exp,list<DAE.ComponentRef> > i;
  output tuple<DAE.Exp,list<DAE.ComponentRef>> out;
algorithm
  out:=matchcontinue (i)
    local 
      list<DAE.ComponentRef> l;
      DAE.ComponentRef cr;
      DAE.Exp e;
    case ((e as DAE.CREF(cr,_),l)) then ((e,listAppend(l,{cr})));
    case ((e,l)) then ((e,l));
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
    case ({},acc) then acc;
    case (e1 :: tail ,acc) 
    equation
      ((_,l)) = Expression.traverseExp(e1,getExpCrefs,{});
      then getCrefs(tail,listAppend(acc,l));
  end match;
end getCrefs;

public function getRHSVars
  input list<DAE.Exp> beqs;
  input list<SimCode.SimVar> vars;
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
  input list<DAE.ComponentRef> states,disc,algs;
  output list<DAE.ComponentRef> out;
algorithm
  out:=matchcontinue (beqs,vars,simJac,states,disc,algs) 
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
  end matchcontinue;
end getRHSVars;

function getInitExp
  input  list<SimCode.SimVar> vars;
  input  DAE.ComponentRef d;
  output String s;
algorithm
  s:=
    matchcontinue(vars,d) 
    local 
      list<SimCode.SimVar> tail;
      DAE.Exp initialExp;
      DAE.ComponentRef name;
      String t;
    case ({},_) then stringAppend(stringAppend("0.0 /* ",ComponentReference.crefStr(d))," */ ;");
    case (SimCode.SIMVAR(name=name,initialValue=SOME(initialExp as DAE.BCONST(_))):: tail,_) 
    equation
      true = ComponentReference.crefEqual(name,d);
      t = stringAppend("(",ExpressionDump.printExpStr(replaceVars(initialExp,{},{},{})));
      t = stringAppend(t,") /* ");
      t = stringAppend(t,ComponentReference.crefStr(d));
      t = stringAppend(t,"*/;");
    then t;
    case (SimCode.SIMVAR(name=name,initialValue=SOME(initialExp)):: tail,_) 
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

function getStartTime
  input SimCode.SampleCondition cond;
  output String s;
algorithm
  s:=
    matchcontinue (cond)
    local
      DAE.Exp start;
    case ((DAE.CALL(path=Absyn.IDENT(name="sample"),expLst=(start:: _)),_) )
      then ExpressionDump.printExpStr(replaceVars(start,{},{},{}));
    end matchcontinue; 
end getStartTime;

public function generateDInit
  input  list<DAE.ComponentRef> disc;
  input  list<SimCode.SampleCondition> sample;
  input  SimCode.SimVars vars;
  input  Integer acc;
  input  Integer total;
  input  Integer nWhenClause;
  output String out;
algorithm
  out:=matchcontinue(disc,sample,vars,acc,total,nWhenClause)
    local 
      list<DAE.ComponentRef> tail;
      DAE.ComponentRef cref;
      String s;
      list<SimCode.SimVar> intAlgVars;
      list<SimCode.SimVar> boolAlgVars;
      list<SimCode.SimVar> algVars;
    case ({},_,_,_,_,_) then "";
    case (cref::tail,_,_,_,_,_) 
    equation
      true = total - acc -1  < nWhenClause;
      s=stringAppend("","d[");
      s=stringAppend(s,intString(acc+1));
      s=stringAppend(s,"]:=");
      s=stringAppend(s,getStartTime(listNth(sample,total-acc-2)));
      s=stringAppend(s,";\n");
    then stringAppend(s,generateDInit(tail,sample,vars,acc+1,total,nWhenClause));
 
    case (cref::tail,_,SimCode.SIMVARS(intAlgVars=intAlgVars,boolAlgVars=boolAlgVars,algVars=algVars),_,_,_) 
    equation
      s=stringAppend("","d[");
      s=stringAppend(s,intString(acc+1));
      s=stringAppend(s,"]:=");
      s=stringAppend(s,getInitExp(listAppend(algVars,listAppend(intAlgVars,boolAlgVars)),cref));
      s=stringAppend(s,"\n");
    then stringAppend(s,generateDInit(tail,sample,vars,acc+1,total,nWhenClause));
 
  end matchcontinue;
end generateDInit;


public function generateInitialParamEquations
  input  SimCode.SimEqSystem eq;
  output String t;
algorithm
  s:= 
  matchcontinue (eq)
  local
    DAE.ComponentRef cref;
    list<SimCode.SimVar> paramVars;
    list<SimCode.SimVar> intParamVars;
    list<SimCode.SimVar> boolParamVars;
    Integer i;
    DAE.Exp exp;
    String t;
  case (SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp))
        
  equation
    t = stringAppend("",System.stringReplace(replaceCref(cref,{},{},{}),".","_"));
    t = stringAppend(t," := ");
    t = stringAppend(t,ExpressionDump.printExpStr(replaceVars(exp,{},{},{})));
    t = stringAppend(t,";");
  then t;
  end matchcontinue;
end generateInitialParamEquations;

public function generateExtraParams
  input SimCode.SimEqSystem eq;
  input SimCode.SimVars vars;
  output String s;
algorithm
  s:= 
  matchcontinue (eq,vars)
  local
    DAE.ComponentRef cref;
    list<SimCode.SimVar> paramVars;
    list<SimCode.SimVar> intParamVars;
    list<SimCode.SimVar> boolParamVars;
    Integer i;
    DAE.Exp exp;
    String t;
  case (SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp),
        SimCode.SIMVARS(paramVars=paramVars,intParamVars=intParamVars,boolParamVars=boolParamVars))
  equation
    failure(i = List.position(cref,List.map(paramVars,SimCode.varName)));  
    failure(i = List.position(cref,List.map(intParamVars,SimCode.varName)));  
    failure(i = List.position(cref,List.map(boolParamVars,SimCode.varName)));  
    t = stringAppend("parameter Real ",System.stringReplace(replaceCref(cref,{},{},{}),".","_"));
    t = stringAppend(t," = ");
    t = stringAppend(t,ExpressionDump.printExpStr(replaceVars(exp,{},{},{})));
    t = stringAppend(t,";");
  then t;
  end matchcontinue;
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
      ((e,_))=Expression.traverseExp(exp,replaceInExpInputs,inp);
      then replaceVars(e,{},{},{});
    end match;
end replaceVarsInputs;

function replaceInExpInputs
  input tuple<DAE.Exp, list<DAE.ComponentRef> > tplExp;
  output tuple<DAE.Exp, list<DAE.ComponentRef>> tplExpOut;
algorithm
  tplExpOut:=
    matchcontinue (tplExp)
     local
       DAE.ComponentRef cr;
       DAE.Type t,t1;
       list<DAE.Subscript> subs;
       list<DAE.ComponentRef> inputs;
       Integer p;
       String ident;
       DAE.Exp e;
     case ((e as DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),inputs))
      equation
      p = List.positionOnTrue(cr,inputs,ComponentReference.crefEqual);
      ident = stringAppend("i",intString(p));
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),inputs));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),inputs))
      equation
      p = List.positionOnTrue(cr,inputs,ComponentReference.crefEqual);
      ident = stringAppend("i",intString(p));
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),inputs));
    case ((e,inputs)) then ((e,inputs));
  end matchcontinue;
end replaceInExpInputs;


public function getDiscRHSVars
  input list<DAE.Exp> beqs;
  input list<SimCode.SimVar> vars;
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
  input list<DAE.ComponentRef> states;
  input list<DAE.ComponentRef> disc;
  input list<DAE.ComponentRef> algs;
  output list<DAE.ComponentRef> out;
algorithm
  out:=matchcontinue (beqs,vars,simJac,states,disc,algs) 
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
  end matchcontinue;

end getDiscRHSVars;


public function simpleWhens
  input list<SimCode.SimWhenClause> i;
  output list<SimCode.SimWhenClause> o;
algorithm
  o:=
    matchcontinue i
    local 
      list<SimCode.SimWhenClause> tail;
      SimCode.SimWhenClause head;
    case {} then {};
    case (SimCode.SIM_WHEN_CLAUSE(conditions={(DAE.CALL(path=Absyn.IDENT(name="sample")),_)}) :: tail) 
      then simpleWhens(tail);
    case (head :: tail) 
      then listAppend({head},simpleWhens(tail));
    end matchcontinue;
end simpleWhens;


public function sampleWhens
  input list<SimCode.SimWhenClause> i;
  output list<SimCode.SimWhenClause> o;
algorithm
  o:=
    matchcontinue i
    local 
      list<SimCode.SimWhenClause> tail;
      SimCode.SimWhenClause head;
    case {} then {};
    case ((head as SimCode.SIM_WHEN_CLAUSE(conditions={(DAE.CALL(path=Absyn.IDENT(name="sample")),_)})) :: tail) 
      then listAppend({head},sampleWhens(tail));
    case (head :: tail) 
      then sampleWhens(tail);
    end matchcontinue;
end sampleWhens;

////////////////////////////////////////////////////////////////////////////////////////////////////
/////  END OF PACKAGE
////////////////////////////////////////////////////////////////////////////////////////////////////
end BackendQSS;
