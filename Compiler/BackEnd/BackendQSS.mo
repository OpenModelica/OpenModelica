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
    case (dlow, ass1, ass2, m, mt, comps,SimCode.SIMCODE(odeEquations={eqs}))
      equation
        print("\n ----------------------------\n");
        print("BackEndQSS analysis initialized");
        print("\n ----------------------------\n");
        (allVarsList, stateVarsList,orderedVarsList) = getAllVars(dlow);
        stateVarsList = List.filterOnTrue(orderedVarsList,BackendVariable.isStateVar);
        algVarsList = List.filterOnTrue(orderedVarsList,BackendVariable.isVarAlg);
        discVarsLst = List.filterOnTrue(orderedVarsList,isDiscreteVar);
        disc = List.map(discVarsLst,getCref);
        algs = List.map(algVarsList,getCref);
        states = List.map(stateVarsList,getCref);
        s = computeStateRef(List.map(states,ComponentReference.crefPrefixDer),eqs,{});
      then
        (QSSINFO(s,states,disc,algs),simCode);
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
      p = List.position(cr,states);
      ident = stringAppend(stringAppend("x[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs)))
      equation
      p = List.position(cr,states);
      ident = stringAppend(stringAppend("x[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs)))
      equation
      p = List.position(cr,disc);
      ident = stringAppend(stringAppend("d[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs)))
      equation
      p = List.position(cr,disc);
      ident = stringAppend(stringAppend("d[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_IDENT(_,t1,subs),ty=t),(states,disc,algs)))
      equation
      p = List.position(cr,algs);
      ident = stringAppend(stringAppend("a[",intString(p+1)),"]");
      then ((DAE.CREF(DAE.CREF_IDENT(ident,t1,subs),t),(states,disc,algs)));
    case ((e as DAE.CREF(componentRef = cr as DAE.CREF_QUAL(_,t1,subs,_),ty=t),(states,disc,algs)))
      equation
      p = List.position(cr,algs);
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
    case ((e as DAE.IFEXP(expCond=expCond, expThen=expThen,expElse=expElse),(states,disc,algs)))
      then ((DAE.BINARY(DAE.BINARY(expCond,DAE.MUL(DAE.T_REAL_DEFAULT),expThen),DAE.ADD(DAE.T_REAL_DEFAULT),
             DAE.BINARY(DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),expCond),DAE.MUL(DAE.T_REAL_DEFAULT),expElse)),(states,disc,algs)));
    case ((DAE.CALL(Absyn.IDENT("noEvent"),{e},_),(states,disc,algs)))
      then ((e,(states,disc,algs)));
    case ((DAE.CALL(Absyn.IDENT("smooth"),{_,e},_),(states,disc,algs)))
      then ((e,(states,disc,algs)));
    case ((DAE.CALL(Absyn.IDENT("DIVISION"),{e,e2,_},_),(states,disc,algs)))
      then ((DAE.BINARY(e,DAE.DIV(DAE.T_REAL_DEFAULT),e2),(states,disc,algs)));
    case ((e,(states,disc,algs))) 
      equation
        print("****** NOT REPLACING *********\n");
        print(ExpressionDump.dumpExpStr(e,0));
        print("*********\n");
      then ((e,(states,disc,algs)));

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
        p=List.position(cr,states);
        then stringAppend(stringAppend("x[",intString(p+1)),"]");
      case (DAE.CREF_QUAL(ident,identType,subscriptLst,r),_,_,_)
      equation
        ident=DAE.derivativeNamePrefix;
        identType=DAE.T_REAL_DEFAULT;
        subscriptLst={};
        p=List.position(r,states);
        then stringAppend(stringAppend("der(x[",intString(p+1)),"])");
      case (_,_,_,_)
      equation
        p=List.position(cr,disc);
        then stringAppend(stringAppend("d[",intString(p+1)),"]");
      case (_,_,_,_)
      equation
        p=List.position(cr,algs);
        then stringAppend(stringAppend("a[",intString(p+1)),"]");
 
    end matchcontinue;
end replaceCref;

  


////////////////////////////////////////////////////////////////////////////////////////////////////
/////  END OF PACKAGE
////////////////////////////////////////////////////////////////////////////////////////////////////
end BackendQSS;
