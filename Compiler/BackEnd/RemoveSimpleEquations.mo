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

encapsulated package RemoveSimpleEquations
" file:        RemoveSimpleEquations.mo
  package:     RemoveSimpleEquations
  description: RemoveSimpleEquations contains functions to remove simple equations.
               Simple equations are either alias equations or time independent equations.
               Alias equations can be simplified to 'a = b', 'a = -b' or 'a = not b'.
               The package contains three main functions. 
               fastAcausal: to remove with a linear skaling with respect to the 
                            number of equations in an acausal system as much as 
                            possible simple equations.
               causal:      to remove with a linear skaling with respect to the
                            number of equations in an causal system all 
                            simple equations
               allAcausal   to remove all simple equations in an acausal system
                            the function may needs a lots of time.  
               
  RCS: $Id: RemoveSimpleEquations.mo 14235 2012-12-05 04:34:35Z wbraun $"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import BaseHashTable;
protected import BaseHashSet;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import Flags;
protected import HashSet;
protected import List;
protected import Util;

protected
uniontype SimpleContainer 
  record ALIAS
    DAE.ComponentRef cr1;
    Integer i1;
    DAE.ComponentRef cr2;
    Integer i2;
    DAE.ElementSource source;
    Boolean negate;
    Integer visited;
  end ALIAS;
  record PARAMETERALIAS
    DAE.ComponentRef cr;
    Integer i1;
    DAE.ComponentRef paramcr;
    Integer i2;
    DAE.ElementSource source;
    Boolean negate;
    Integer visited;
  end PARAMETERALIAS;
  record TIMEALIAS
    DAE.ComponentRef cr;
    Integer i;
    DAE.ElementSource source;
    Boolean negate;
    Integer visited;
  end TIMEALIAS;  
  record TIMEINDEPENTVAR
    DAE.ComponentRef cr;
    Integer i;
    DAE.Exp exp;
    DAE.ElementSource source;
    Integer visited;
  end TIMEINDEPENTVAR;
end SimpleContainer;

protected type AccTuple = tuple<BackendDAE.Variables,BackendDAE.Shared,list<BackendDAE.Equation>,list<SimpleContainer>,Integer,array<list<Integer>>,Boolean>;

protected type VarSetAttributes = 
  tuple<Boolean,tuple<Integer,list<tuple<Option<DAE.Exp>,DAE.ComponentRef>>>,Option<DAE.Exp>,Integer,tuple<Option<DAE.Exp>,Option<DAE.Exp>>>
  "fixed,list<startvalue,origin,cr>,nominal,nNominals,min,max";

protected constant VarSetAttributes EMPTYVARSETATTRIBUTES  = (false,(-1,{}),NONE(),0,(NONE(),NONE()));

/*
 * fastAcausal
 *
 */

public function fastAcausal
"function: fastAcausal
  autor: Frenkel TUD 2012-12
  This Function remove with a linear skaling with respect to the 
  number of equations in an acausal system as much as 
  possible simple equations."
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
protected
  BackendVarTransform.VariableReplacements repl;
  Boolean b;
  Integer size;
algorithm
  // get the size of the system to set up the replacement hashmap 
  size := BackendDAEUtil.daeSize(dae);
  size := intMax(BaseHashTable.defaultBucketSize,realInt(realMul(intReal(size),0.7)));
  repl := BackendVarTransform.emptyReplacementsSized(size);
  // traverse all systems and remove simple equations 
  (odae,(repl,b)) := BackendDAEUtil.mapEqSystemAndFold(dae,fastAcausal1,(repl,false));
  // traverse the shared parts
  odae := removeSimpleEquationsShared(b,odae,repl);
end fastAcausal;

protected function fastAcausal1
"function: fastAcausal1
  autor: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input BackendDAE.EqSystem isyst; 
  input tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,tuple<BackendVarTransform.VariableReplacements,Boolean>> osharedOptimized;
algorithm
  (osyst,osharedOptimized):=
  match (isyst,sharedOptimized)
    local
      tuple<BackendVarTransform.VariableReplacements,Boolean> tpl;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      list<BackendDAE.Equation> eqnslst;
      list<SimpleContainer> simpleeqnslst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<list<Integer>> mT;
      Boolean b;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),(shared,tpl))
      equation
        // transform to list, this is later not neccesary because the acausal system should save the equations as list
        eqnslst = BackendEquation.equationList(eqns);
        // collect simple equations
         mT = arrayCreate(BackendVariable.varsSize(vars),{});
        ((_,_,eqnslst,simpleeqnslst,_,mT,b)) = List.fold(eqnslst,simpleEquationsFinderAcausal,(vars,shared,{},{},1,mT,false));
        // check if simple equations are found
        (syst,shared,tpl) = fastAcausal2(b,simpleeqnslst,eqnslst,mT,isyst,shared,tpl);
      then (syst,(shared,tpl));
  end match;
end fastAcausal1;

protected function simpleEquationsFinderAcausal
"autor: Frenkel TUD 2012-12
  map from equation to lhs and rhs"
  input BackendDAE.Equation eqn;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl:=
  matchcontinue (eqn,inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp e1,e2;
      DAE.ElementSource source;
      BackendDAE.Variables v;
      BackendDAE.Shared s;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      Boolean b;
    case (BackendDAE.EQUATION(exp=e1,scalar=e2,source=source),_)
      then simpleEquationAcausal(e1,e2,source,false,inTpl);
    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2,source=source),_)
      then simpleEquationAcausal(e1,e2,source,false,inTpl);
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e2,source=source),_)
      equation
        e1 = Expression.crefExp(cr);
      then simpleEquationAcausal(e1,e2,source,false,inTpl);
    case (BackendDAE.RESIDUAL_EQUATION(exp=e1,source=source),_)
      then simpleExpressionAcausal(e1,source,false,inTpl);
    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2,source=source),_)
      then simpleEquationAcausal(e1,e2,source,false,inTpl);
     case (_,(v,s,eqns,seqns,index,mT,b))
      then ((v,s,eqn::eqns,seqns,index,mT,b));
   end matchcontinue;
end simpleEquationsFinderAcausal;

protected function simpleEquationAcausal
"function simpleEquationAcausal
  autor Frenkel TUD 2012-12
  helper for simpleEquationsFinderAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (lhs,rhs,source,selfCalled,inTpl)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e,e1,e2,ne,ne1;
      DAE.Type ty;
      list<DAE.Exp> elst1,elst2;
      list<list<DAE.Exp>> elstlst1,elstlst2;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> tpls;
      list<DAE.Var> varLst1,varLst2;
      Absyn.Path patha,patha1,pathb,pathb1;
      DAE.Dimensions dims;
    // a = b;
    case (DAE.CREF(componentRef = cr1),DAE.CREF(componentRef = cr2),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,lhs,rhs,false,source,selfCalled,inTpl);
    // a = -b;
    case (DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS(ty),DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,DAE.UNARY(DAE.UMINUS(ty),lhs),rhs,true,source,selfCalled,inTpl);
    case (DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS_ARR(ty),DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,DAE.UNARY(DAE.UMINUS_ARR(ty),lhs),rhs,true,source,selfCalled,inTpl);
    // -a = b;
    case (DAE.UNARY(DAE.UMINUS(ty),DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr2),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,lhs,DAE.UNARY(DAE.UMINUS(ty),rhs),true,source,selfCalled,inTpl);
    case (DAE.UNARY(DAE.UMINUS_ARR(ty),e1 as DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr2),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,lhs,DAE.UNARY(DAE.UMINUS_ARR(ty),rhs),true,source,selfCalled,inTpl);
    // -a = -b;
    case (DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(componentRef = cr1)),DAE.UNARY(DAE.UMINUS(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,e2,false,source,selfCalled,inTpl);
    case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,e2,false,source,selfCalled,inTpl);
    // a = not b;
    case (DAE.CREF(componentRef = cr1),DAE.LUNARY(DAE.NOT(ty),DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,DAE.LUNARY(DAE.NOT(ty),lhs),rhs,true,source,selfCalled,inTpl);
    // not a = b;
    case (DAE.LUNARY(DAE.NOT(ty),DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr2),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,lhs,DAE.LUNARY(DAE.NOT(ty),rhs),true,source,selfCalled,inTpl);
    // not a = not b;
    case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,e2,false,source,selfCalled,inTpl);
    // {a1,a2,a3,..} = {b1,b2,b3,..};
    case (DAE.ARRAY(array = elst1),DAE.ARRAY(array = elst2),_,_,_)
      then List.threadFold2(elst1,elst2,simpleEquationAcausal,source,true,inTpl);
    case (DAE.MATRIX(matrix = elstlst1),DAE.MATRIX(matrix = elstlst2),_,_,_)
      then List.threadFold2(elstlst1,elstlst2,simpleEquationAcausalLst,source,true,inTpl);
    // a = {b1,b2,b3,..}
    case (DAE.CREF(componentRef = cr1),DAE.ARRAY(ty=ty),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.CREF(componentRef = cr1),DAE.MATRIX(ty=ty),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // -a = {b1,b2,b3,..}
    case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ARRAY(ty=ty),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.MATRIX(ty=ty),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // a = -{b1,b2,b3,..}
    case (DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // -a = -{b1,b2,b3,..}
    case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    // {a1,a2,a3,..} = b      
    case (DAE.ARRAY(ty=ty),DAE.CREF(componentRef = cr2),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.MATRIX(ty=ty),DAE.CREF(componentRef = cr2),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // -{a1,a2,a3,..} = b      
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.ARRAY(ty=ty)),DAE.CREF(componentRef = cr2),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.MATRIX(ty=ty)),DAE.CREF(componentRef = cr2),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // {a1,a2,a3,..} = -b      
    case (DAE.ARRAY(ty=ty),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.MATRIX(ty=ty),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // -{a1,a2,a3,..} = -b      
    case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.ARRAY(ty=ty)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.MATRIX(ty=ty)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    // not a = {b1,b2,b3,..}
    case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ARRAY(ty=ty),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.MATRIX(ty=ty),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // a = not {b1,b2,b3,..}
    case (DAE.CREF(componentRef = cr1),DAE.LUNARY(DAE.NOT(_),DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.CREF(componentRef = cr1),DAE.LUNARY(DAE.NOT(_),DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // not a = not {b1,b2,b3,..}
    case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.LUNARY(DAE.NOT(_),e2 as DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.LUNARY(DAE.NOT(_),e2 as DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    // {a1,a2,a3,..} = not b      
    case (DAE.ARRAY(ty=ty),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.MATRIX(ty=ty),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // not {a1,a2,a3,..} = b      
    case (DAE.LUNARY(DAE.NOT(_),DAE.ARRAY(ty=ty)),DAE.CREF(componentRef = cr2),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    case (DAE.LUNARY(DAE.NOT(_),DAE.MATRIX(ty=ty)),DAE.CREF(componentRef = cr2),_,_,_)
      then simpleArrayEquationAcausal(lhs,rhs,ty,source,inTpl);
    // not {a1,a2,a3,..} = not b      
    case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.ARRAY(ty=ty)),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.MATRIX(ty=ty)),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    // time independent equations
    else
      then simpleEquationAcausal1(lhs,rhs,source,selfCalled,inTpl);
  end match;
end simpleEquationAcausal;


protected function simpleArrayEquationAcausal
"function simpleArrayEquationAcausal
  autor Frenkel TUD 2012-12
  helper for simpleEquationAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type ty;
  input DAE.ElementSource source;
  input AccTuple inTpl;
  output AccTuple outTpl;
protected 
  DAE.Dimensions dims;
  list<Integer> ds;
  list<Option<Integer>> ad;
  list<list<DAE.Subscript>> subslst;
  list<DAE.Exp> elst1,elst2;
algorithm
  dims := Expression.arrayDimension(ty);
  ds := Expression.dimensionsSizes(dims);  
  ad := List.map(ds,Util.makeOption);
  subslst := BackendDAEUtil.arrayDimensionsToRange(ad);
  subslst := BackendDAEUtil.rangesToSubscripts(subslst);
  elst1 := List.map1r(subslst,Expression.applyExpSubscripts,lhs);
  elst2 := List.map1r(subslst,Expression.applyExpSubscripts,rhs);  
  outTpl := List.threadFold2(elst1,elst2,simpleEquationAcausal,source,true,inTpl); 
end simpleArrayEquationAcausal;

protected function simpleEquationAcausalLst
"function simpleEquationAcausalLst
  autor Frenkel TUD 2012-12
  helper for simpleEquationAcausal"
  input list<DAE.Exp> elst1;
  input list<DAE.Exp> elst2;
  input DAE.ElementSource source;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := List.threadFold2(elst1,elst2,simpleEquationAcausal,source,selfCalled,inTpl); 
end simpleEquationAcausalLst;

protected function simpleEquationAcausal1
"function simpleEquationAcausal1
  autor Frenkel TUD 2012-12
  helper for simpleEquationAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (lhs,rhs,source,selfCalled,inTpl)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e,e1,e2,ne,ne1;
      DAE.Type ty;
      list<DAE.Exp> elst1,elst2;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> tpls;
      list<DAE.Var> varLst1,varLst2;
      Absyn.Path patha,patha1,pathb,pathb1;
      DAE.Dimensions dims;
    // Record
    case (_,_,_,_,_)
      equation
        elst1 = Expression.splitRecord(lhs,Expression.typeof(lhs));
        elst2 = Expression.splitRecord(rhs,Expression.typeof(rhs));        
      then List.threadFold2(elst1,elst2,simpleEquationAcausal,source,true,inTpl);
    // {a1+b1,a2+b2,a3+b3,..} = 0;
    case (DAE.ARRAY(array = elst1),_,_,_,_)
      equation
        true = Expression.isZero(rhs);  
      then List.fold2(elst1,simpleExpressionAcausal,source,true,inTpl); 
    // 0 = {a1+b1,a2+b2,a3+b3,..};
    case (_,DAE.ARRAY(array = elst2),_,_,_)
      equation
        true = Expression.isZero(lhs);  
      then List.fold2(elst2,simpleExpressionAcausal,source,true,inTpl);    
     // lhs = 0
    case (_,_,_,_,_)
      equation
        true = Expression.isZero(rhs);
      then simpleExpressionAcausal(lhs,source,selfCalled,inTpl);
    // 0 = rhs
    case (_,_,_,_,_)
      equation
        true = Expression.isZero(lhs);
      then simpleExpressionAcausal(rhs,source,selfCalled,inTpl);
    // time independent equations
    else
      then timeIndependentEquationAcausal(lhs,rhs,source,selfCalled,inTpl);
  end matchcontinue;
end simpleEquationAcausal1;

protected function generateEquation
"function generateEquation
  autor Frenkel TUD 2012-12
  helper to generate an equation from lhs and rhs.
  This function is called if an equation is found which is not simple"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type ty;
  input DAE.ElementSource source;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (lhs,rhs,ty,source,inTpl)
    local
      Integer size;
      DAE.Dimensions dims;
      list<Integer> ds;
      BackendDAE.Variables v;
      BackendDAE.Shared s;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      Boolean b,b1,b2;
    // complex types to complex equations  
    case (_,_,_,_,(v,s,eqns,seqns,index,mT,b))
      equation 
        true = DAEUtil.expTypeComplex(ty);
        size = Expression.sizeOf(ty);
        //  print("Add Equation:\n" +& BackendDump.equationStr(BackendDAE.COMPLEX_EQUATION(size,lhs,rhs,source)) +& "\n");
       then
        ((v,s,BackendDAE.COMPLEX_EQUATION(size,lhs,rhs,source)::eqns,seqns,index,mT,b));
    // array types to array equations  
    case (_,_,_,_,(v,s,eqns,seqns,index,mT,b))
      equation 
        true = DAEUtil.expTypeArray(ty);
        dims = Expression.arrayDimension(ty);
        ds = Expression.dimensionsSizes(dims);
        //  print("Add Equation:\n" +& BackendDump.equationStr(BackendDAE.ARRAY_EQUATION(ds,lhs,rhs,source)) +& "\n");
      then
        ((v,s,BackendDAE.ARRAY_EQUATION(ds,lhs,rhs,source)::eqns,seqns,index,mT,b));
    // other types  
    case (_,_,_,_,(v,s,eqns,seqns,index,mT,b))
      equation
        b1 = DAEUtil.expTypeComplex(ty);
        b2 = DAEUtil.expTypeArray(ty);
        false = b1 or b2;
        //  print("Add Equation:\n" +& BackendDump.equationStr(BackendDAE.EQUATION(lhs,rhs,source)) +& "\n");
        //Error.assertionOrAddSourceMessage(not b1,Error.INTERNAL_ERROR,{str}, Absyn.dummyInfo);
      then
        ((v,s,BackendDAE.EQUATION(lhs,rhs,source)::eqns,seqns,index,mT,b));
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAEOptimize.generateEquation failed on: " +& ExpressionDump.printExpStr(lhs) +& " = " +& ExpressionDump.printExpStr(rhs) +& "\n");
      then
        fail();      
  end matchcontinue;  
end generateEquation;

protected function simpleExpressionAcausal
"function simpleExpressionAcausal
  autor Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp exp;
  input DAE.ElementSource source;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (exp,source,selfCalled,inTpl)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e,e1,e2,ne,ne1;
      DAE.Type ty;
      list<DAE.Exp> elst1,elst2;
    // a + b
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,DAE.UNARY(DAE.UMINUS(ty),e1),DAE.UNARY(DAE.UMINUS(ty),e2),true,source,selfCalled,inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.UNARY(DAE.UMINUS_ARR(ty),e2),true,source,selfCalled,inTpl);
    // a - b 
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,e2,false,source,selfCalled,inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,e2,false,source,selfCalled,inTpl);
    // -a + b
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,e2,false,source,selfCalled,inTpl);
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,e2,false,source,selfCalled,inTpl);
    // -a - b = 0
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,DAE.UNARY(DAE.UMINUS(ty),e2),true,source,selfCalled,inTpl);
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_,_,_)
      then addSimpleEquationAcausal(cr1,cr2,e1,DAE.UNARY(DAE.UMINUS_ARR(ty),e2),true,source,selfCalled,inTpl);

    // a + {b1,b2,b3}
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(_),e2 as DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(_),e2 as DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    // a - {b1,b2,b3}
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(_),e2 as DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(_),e2 as DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    // -a + {b1,b2,b3}
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(_),e2 as DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(_),e2 as DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    // -a - {b1,b2,b3}
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(_),e2 as DAE.ARRAY(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(_),e2 as DAE.MATRIX(ty=ty)),_,_,_)
      then simpleArrayEquationAcausal(e1,e2,ty,source,inTpl);

    // time independent equations
    else
      then timeIndependentExpressionAcausal(exp,source,selfCalled,inTpl);  
  end match;
end simpleExpressionAcausal;

protected function addSimpleEquationAcausal
"function addSimpleEquationAcausal
  autor Frenkel TUD 2012-12
  add a simple equation to the list of simple equations"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input Boolean negate;
  input DAE.ElementSource source "the source of the equation";
  input Boolean genEqn "true if not possible to get the Alias generate an equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue(cr1,cr2,e1,e2,negate,source,genEqn,inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      list<BackendDAE.Var> vars1,vars2;
      list<Integer> ilst1,ilst2,ilsta;
      Boolean b,varskn1,varskn2,time1,time2;
      DAE.Exp e;
      DAE.Type ty;
    case(_,_,_,_,_,_,_,(vars,shared,eqns,seqns,index,mT,b))
      equation
        Debug.fcall(Flags.DEBUG_ALIAS,BackendDump.debugStrCrefStrCrefStr,("Alias Equation ",cr1," = ",cr2," found.\n"));
        // get Variables
        (vars1,ilst1,varskn1,time1) =  getVars(cr1,vars,shared);
        (vars2,ilst2,varskn2,time2) =  getVars(cr2,vars,shared);
        // add to Simple Equations List
        (seqns,index,mT) = generateSimpleContainters(vars1,ilst1,varskn1,time1,vars2,ilst2,varskn2,time2,negate,source,seqns,index,mT);  
      then
        ((vars,shared,eqns,seqns,index,mT,true));
    case(_,_,_,_,_,_,true,_)
      equation
        e = Expression.crefExp(cr1);
        ty = Expression.typeof(e);
      then
        generateEquation(e,e2,ty,source,inTpl);
  end matchcontinue;  
end addSimpleEquationAcausal;

protected function getVars
"function: getVars
  author: Frenkel TUD 2012-11"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared shared;
  output list<BackendDAE.Var> oVars;
  output list<Integer> oIndexs;
  output Boolean varskn;
  output Boolean time_;
algorithm
  (oVars,oIndexs,varskn,time_) := matchcontinue(cr,vars,shared)
    case (DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_,_)
      then
        ({},{},true,true);
    case (_,_,_)
      equation
        (oVars as _::_,oIndexs) = BackendVariable.getVar(cr,vars);
      then
        (oVars,oIndexs,false,false);
    case (_,_,_)
      equation
        (oVars as _::_,oIndexs) = BackendVariable.getVarShared(cr,shared);
      then
        (oVars,oIndexs,true,false);
  end matchcontinue;
end getVars;

protected function generateSimpleContainters
"function generateSimpleContainters
  autor Frenkel TUD 2012-12
  add a simple equation to the list of simple equations"
  input list<BackendDAE.Var> vars1;
  input list<Integer> ilst1;
  input Boolean varskn1;
  input Boolean time1;
  input list<BackendDAE.Var> vars2;
  input list<Integer> ilst2;
  input Boolean varskn2;
  input Boolean time2;
  input Boolean negate;
  input DAE.ElementSource source "the source of the equation";
  input list<SimpleContainer> iSeqns;
  input Integer iIndex;
  input array<list<Integer>> iMT;
  output list<SimpleContainer> oSeqns;
  output Integer oIndex;
  output array<list<Integer>> oMT;
algorithm
  (oSeqns,oIndex,oMT) := match(vars1,ilst1,varskn1,time1,vars2,ilst2,varskn2,time2,negate,source,iSeqns,iIndex,iMT)
    local
      BackendDAE.Var v1,v2;
      Integer i1,i2;
      list<BackendDAE.Var> vlst1,vlst2;
      list<Integer> irest1,irest2,colum;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      DAE.ComponentRef cr1,cr2;
    case (_,_,true,true,{BackendDAE.VAR(varName=cr2)},{i2},false,false,_,_,_,_,_)
      equation
        colum = iMT[i2];
        _ = arrayUpdate(iMT,i2,iIndex::colum);
      then 
        (TIMEALIAS(cr2,i2,source,negate,-1)::iSeqns,iIndex+1,iMT);
    case ({BackendDAE.VAR(varName=cr1)},{i1},false,false,_,_,true,true,_,_,_,_,_)
      equation
        colum = iMT[i1];
        _ = arrayUpdate(iMT,i1,iIndex::colum);
      then 
        (TIMEALIAS(cr1,i1,source,negate,-1)::iSeqns,iIndex+1,iMT);       
    case({},_,_,_,{},_,_,_,_,_,_,_,_) then (iSeqns,iIndex,iMT);
    case(v1::vlst1,i1::irest1,_,false,v2::vlst2,i2::irest2,_,false,_,_,_,_,_)
      equation
        (seqns,index,mT) = generateSimpleContainter(v1,i1,varskn1,v2,i2,varskn2,negate,source,iSeqns,iIndex,iMT); 
        (seqns,index,mT) = generateSimpleContainters(vlst1,irest1,varskn1,time1,vlst2,irest2,varskn2,time2,negate,source,seqns,index,mT); 
      then
        (seqns,index,mT);
  end match;
end generateSimpleContainters;

protected function generateSimpleContainter
"function generateSimpleContainter
  autor Frenkel TUD 2012-12
  add a simple equation to the list of simple equations"
  input BackendDAE.Var v1;
  input Integer i1;
  input Boolean varskn1;
  input BackendDAE.Var v2;
  input Integer i2;
  input Boolean varskn2;
  input Boolean negate;
  input DAE.ElementSource source "the source of the equation";
  input list<SimpleContainer> iSeqns;
  input Integer iIndex;
  input array<list<Integer>> iMT;
  output list<SimpleContainer> oSeqns;
  output Integer oIndex;
  output array<list<Integer>> oMT;
algorithm
  (oSeqns,oIndex,oMT) := match(v1,i1,varskn1,v2,i2,varskn2,negate,source,iSeqns,iIndex,iMT)
    local
      DAE.ComponentRef cr1,cr2;
      list<Integer> colum;
      DAE.Exp crexp1,crexp2;
      String msg;
    case (BackendDAE.VAR(varName=cr1),_,false,BackendDAE.VAR(varName=cr2),_,false,_,_,_,_,_)
      equation
        colum = iMT[i1];
        _ = arrayUpdate(iMT,i1,iIndex::colum);
        colum = iMT[i2];
        _ = arrayUpdate(iMT,i2,iIndex::colum);
      then 
        (ALIAS(cr1,i1,cr2,i2,source,negate,-1)::iSeqns,iIndex+1,iMT);
    case (BackendDAE.VAR(varName=cr1),_,true,BackendDAE.VAR(varName=cr2),_,false,_,_,_,_,_)
      equation
        colum = iMT[i2];
        _ = arrayUpdate(iMT,i2,iIndex::colum);
      then 
        (PARAMETERALIAS(cr2,i2,cr1,i1,source,negate,-1)::iSeqns,iIndex+1,iMT);
    case (BackendDAE.VAR(varName=cr1),_,false,BackendDAE.VAR(varName=cr2),_,true,_,_,_,_,_)
      equation
        colum = iMT[i1];
        _ = arrayUpdate(iMT,i1,iIndex::colum);
      then 
        (PARAMETERALIAS(cr1,i1,cr2,i2,source,negate,-1)::iSeqns,iIndex+1,iMT);
    case (BackendDAE.VAR(varName=cr1),_,true,BackendDAE.VAR(varName=cr2),_,true,_,_,_,_,_)
      equation
        crexp1 = Expression.crefExp(cr1);
        crexp2 = Expression.crefExp(cr2);
        crexp2 = Debug.bcallret1(negate,Expression.negate,crexp2,crexp2);
        msg = "Found Equation without time dependent variables ";
        msg = msg +& ExpressionDump.printExpStr(crexp1) +& " = " +& ExpressionDump.printExpStr(crexp2) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});       
      then 
        fail();
  end match;
end generateSimpleContainter;

protected function timeIndependentEquationAcausal
"function timeIndependentEquationAcausal
  autor Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (lhs,rhs,source,selfCalled,inTpl)
    local
      DAE.Type ty;
      BackendDAE.Variables vars,knvars;
      list<Integer> ilst;
      list<BackendDAE.Var> vlst;
    case (_,_,_,_,(vars,BackendDAE.SHARED(knownVars=knvars),_,_,_,_,_))
      equation
        // collect vars and check if variable time not there
        ((_,(false,_,_,_,_,ilst))) = Expression.traverseExpTopDown(lhs, traversingTimeVarsFinder, (false,vars,knvars,false,false,{}));
        ((_,(false,_,_,_,_,ilst))) = Expression.traverseExpTopDown(rhs, traversingTimeVarsFinder, (false,vars,knvars,false,false,ilst));
        ilst = List.uniqueIntN(ilst,BackendVariable.varsSize(vars));
        vlst = List.map1r(ilst,BackendVariable.getVarAt,vars);
      then
        solveTimeIndependentAcausal(vlst,ilst,lhs,rhs,source,inTpl);
    // in all other case keep the equation
    case (_,_,_,true,_)
      equation
        ty = Expression.typeof(lhs);
      then
        generateEquation(lhs,rhs,ty,source,inTpl);
  end matchcontinue;
end timeIndependentEquationAcausal;

protected function timeIndependentExpressionAcausal
"function timeIndependentExpressionAcausal
  autor Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp exp;
  input DAE.ElementSource source;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (exp,source,selfCalled,inTpl)
    local
      DAE.Exp e2;
      DAE.Type ty;
      BackendDAE.Variables vars,knvars;
      list<Integer> ilst;
      list<BackendDAE.Var> vlst;
    case (_,_,_,(vars,BackendDAE.SHARED(knownVars=knvars),_,_,_,_,_))
      equation
        // collect vars and check if variable time not there
        ((_,(false,_,_,_,_,ilst))) = Expression.traverseExpTopDown(exp, traversingTimeVarsFinder, (false,vars,knvars,false,false,{}));
        ilst = List.uniqueIntN(ilst,BackendVariable.varsSize(vars));
        vlst = List.map1r(ilst,BackendVariable.getVarAt,vars);
      then
        // shoulde be ok since solve checks only for iszero
        solveTimeIndependentAcausal(vlst,ilst,exp,DAE.RCONST(0.0),source,inTpl);    
    // in all other case keep the equation
    case (_,_,true,_)
      equation
        ty = Expression.typeof(exp);
        e2 = Expression.makeConstZero(ty);        
      then
        generateEquation(exp,e2,ty,source,inTpl);
  end matchcontinue;
end timeIndependentExpressionAcausal;

protected function toplevelInputOrUnfixed
" function toplevelInputOrUnfixed
  autor Frenkel TUD 2012-12
  return true is var on topliven and input or is unfixed parameter"
  input BackendDAE.Var inVar;
  output Boolean b;
algorithm
  b := BackendVariable.isVarOnTopLevelAndInput(inVar) or 
       BackendVariable.isParam(inVar) and not BackendVariable.varFixed(inVar);
end toplevelInputOrUnfixed;

protected function traversingTimeVarsFinder "
Author: Frenkel 2012-12"
  input tuple<DAE.Exp, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean,list<Integer>> > inExp;
  output tuple<DAE.Exp, Boolean, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean,list<Integer>> > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e;
      Boolean b,b1,b2;
      BackendDAE.Variables vars,knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<Integer> ilst,vlst;
      list<BackendDAE.Var> varlst;
    
    case((e as DAE.CREF(DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_), (_,vars,knvars,b1,b2,ilst)))
      then ((e,false,(true,vars,knvars,b1,b2,ilst)));       
    case((e as DAE.CREF(cr,_), (_,vars,knvars,b1,b2,ilst)))
      equation
        (varlst,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        false = List.mapAllValueBool(varlst,toplevelInputOrUnfixed,false);
      then ((e,false,(true,vars,knvars,b1,b2,ilst)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {_,_}), (_,vars,knvars,b1,b2,ilst))) then ((e,false,(true,vars,knvars,b1,b2,ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {_}), (_,vars,knvars,b1,b2,ilst))) then ((e,false,(true,vars,knvars,b1,b2,ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "change"), expLst = {_}), (_,vars,knvars,b1,b2,ilst))) then ((e,false,(true,vars,knvars,b1,b2,ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "edge"), expLst = {_}), (_,vars,knvars,b1,b2,ilst))) then ((e,false,(true,vars,knvars,b1,b2,ilst) ));
    // case for finding simple equation in jacobians 
    // there are all known variables mark as input
    // and they are all time-depending  
    case((e as DAE.CREF(cr,_), (_,vars,knvars,true,b2,ilst)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        DAE.INPUT() = BackendVariable.getVarDirection(var);
      then ((e,false,(true,vars,knvars,true,b2,ilst)));  
    // var
    case((e as DAE.CREF(cr,_), (b,vars,knvars,b1,b2,ilst)))
      equation
        (var::_,vlst)= BackendVariable.getVar(cr, vars);
        ilst = listAppend(ilst,vlst);
      then ((e,true,(b,vars,knvars,b1,b2,ilst)));          
    case((e,(b,vars,knvars,b1,b2,ilst))) then ((e,not b,(b,vars,knvars,b1,b2,ilst)));
    
  end matchcontinue;
end traversingTimeVarsFinder;

protected function solveTimeIndependentAcausal
"function solveTimeIndependentAcausal
  autor Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input list<BackendDAE.Var> vlst;
  input list<Integer> ilst;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (vlst,ilst,lhs,rhs,source,inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp cre,es;
      BackendDAE.Var v;
      Integer i,size;
    case ({v as BackendDAE.VAR(varName=cr)},{i},_,_,_,_)
      equation
        // try to solve the equation
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(lhs,rhs,cre);
        // constant or alias
      then
        constOrAliasAcausal(v,i,cr,es,source,inTpl);
/*    else
      equation
        // size of equation have to be equal with number of vars
        size = Expression.sizeOf(Expression.typeof(lhs));
        true = intEq(size,listLength(vlst));
      then
        solveTimeIndependentAcausal1(vlst,ilst,lhs,rhs,source,inTpl);
*/  end match;
end solveTimeIndependentAcausal;

protected function solveTimeIndependentAcausal1
"function solveTimeIndependentAcausal1
  autor Frenkel TUD 2012-12
  helper for simpleEquations"
  input list<BackendDAE.Var> vlst;
  input list<Integer> ilst;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (vlst,ilst,lhs,rhs,source,inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp cre,es;
      list<DAE.ComponentRef> crlst;
      BackendDAE.Var v;
      Integer i;
    // a = ...
    case (_,_,_,_,_,_)
      equation
        cr::crlst = List.map(vlst,BackendVariable.varCref);
        cr = ComponentReference.crefStripLastSubs(cr);
        List.map1rAllValue(crlst,ComponentReference.crefPrefixOf,true,cr);
        // try to solve the equation
        cre = Expression.crefExp(cr);
        (es,{}) = ExpressionSolve.solve(lhs,rhs,cre);
        // constant or alias   
      then
        constOrAliasArrayAcausal(vlst,ilst,es,source,inTpl);
    // {a1,a2,a3,..} = ...
    
  end matchcontinue;
end solveTimeIndependentAcausal1;

protected function constOrAliasArrayAcausal
"function constOrAliasArrayAcausal
  autor Frenkel TUD 2012-12"
  input list<BackendDAE.Var> vars;
  input list<Integer> indxs;
  input DAE.Exp exp;
  input DAE.ElementSource source;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (vars,indxs,exp,source,inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
      Integer i;
      list<Integer> ilst;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Subscript> subs;
      AccTuple tpl;
    case ({},_,_,_,_) then inTpl;
    case ((v as BackendDAE.VAR(varName=cr))::vlst,i::ilst,_,_,_)
      equation
        subs = ComponentReference.crefLastSubs(cr);
        e = Expression.applyExpSubscripts(exp,subs);
        tpl = constOrAliasAcausal(v,i,cr,e,source,inTpl); 
      then
        constOrAliasArrayAcausal(vlst,ilst,exp,source,tpl);
  end match;  
end constOrAliasArrayAcausal;

protected function constOrAliasAcausal
"function constOrAliasAcausal
  autor Frenkel TUD 2012-12"
  input BackendDAE.Var var;
  input Integer i;
  input DAE.ComponentRef cr;
  input DAE.Exp exp;
  input DAE.ElementSource source;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (var,i,cr,exp,source,inTpl)
    local
      BackendDAE.Variables vars,knvars;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      DAE.ComponentRef cra;
      list<BackendDAE.Var> vars2;
      list<Integer> ilst2;
      Boolean b,negate;
      list<Integer> colum;
    // alias a
    case (_,_,_,_,_,(vars,shared,eqns,seqns,index,mT,b))
      equation
        // alias
        (negate,cra) = aliasExp(exp);
        // get Variables
        knvars = BackendVariable.daeKnVars(shared);
        (vars2,ilst2) = BackendVariable.getVar(cra,knvars);
        // add to Simple Equations List
        (seqns,index,mT) = generateSimpleContainters({var},{i},false,false,vars2,ilst2,true,false,negate,source,seqns,index,mT);  
      then
        ((vars,shared,eqns,seqns,index,mT,true));        
    // const
    case (_,_,_,_,_,(vars,shared,eqns,seqns,index,mT,b))
      equation
        Debug.fcall(Flags.DEBUG_ALIAS,BackendDump.debugStrCrefStrExpStr,("Const Equation ",cr," = ",exp," found.\n"));
        colum = mT[i];
        _ = arrayUpdate(mT,i,index::colum);
      then
        ((vars,shared,eqns,TIMEINDEPENTVAR(cr,i,exp,source,-1)::seqns,index+1,mT,true));
  end matchcontinue;
end constOrAliasAcausal;

protected function aliasExp
"function aliasExp
  autor Frenkel TUD 2011-04"
  input DAE.Exp exp;
  output Boolean negate;
  output DAE.ComponentRef outCr;
algorithm
  (negate,outCr) := match (exp)
    local DAE.ComponentRef cr;
    // alias a
    case (DAE.CREF(componentRef = cr)) then (false,cr);
    // alias -a
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr))) then (true,cr);
    // alias -a
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr))) then (true,cr);
    // alias not a
    case (DAE.LUNARY(DAE.NOT(_),DAE.CREF(componentRef = cr))) then (true,cr);
  end match;
end aliasExp;

protected function fastAcausal2
"function: fastAcausal2
  autor: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input Boolean foundSimple;
  input list<SimpleContainer> iSimpleeqnslst;
  input list<BackendDAE.Equation> iEqnslst;
  input array<list<Integer>> iMT;
  input BackendDAE.EqSystem isyst; 
  input BackendDAE.Shared ishared;
  input tuple<BackendVarTransform.VariableReplacements,Boolean> iTpl;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output tuple<BackendVarTransform.VariableReplacements,Boolean> oTpl;
algorithm
  (osyst,oshared,oTpl):=
  match (foundSimple,iSimpleeqnslst,iEqnslst,iMT,isyst,ishared,iTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendVarTransform.VariableReplacements repl;
      Boolean b;
      array<SimpleContainer> simpleeqns;
      list<list<SimpleContainer>> sets;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
    case (false,_,_,_,_,_,_) then (isyst,ishared,iTpl);
    case (true,_,_,_,BackendDAE.EQSYSTEM(orderedVars=vars),_,(repl,b))
      equation
        // transform simpleeqns to array
        simpleeqns = listArray(listReverse(iSimpleeqnslst));
        // collect and handle sets
        (vars,eqnslst,shared,repl) = fastAcausal3(arrayLength(simpleeqns),1,simpleeqns,iMT,vars,iEqnslst,ishared,repl);
        // remove empty entries from vars
        vars = BackendVariable.listVar1(BackendVariable.varList(vars));
        // replace unoptimized equations with optimized
        eqns = BackendEquation.listEquation(listReverse(eqnslst));        
      then 
        (BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING()),shared,(repl,true));
  end match;
end fastAcausal2;

protected function fastAcausal3
"function: fastAcausal3
  autor: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input Integer index "downwarts";
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oVars,oEqnslst,oshared,oRepl):=
  matchcontinue (index,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl)
    local
      Option<tuple<Integer,Integer>> rmax,smax;
      Option<Integer> unremovable,const;
      
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
    case (0,_,_,_,_,_,_,_) then (iVars,iEqnslst,ishared,iRepl);
    case (_,_,_,_,_,_,_,_)
      equation
        true = intGt(getVisited(simpleeqnsarr[index]),0);
        (vars,eqnslst,shared,repl) =  fastAcausal3(index-1,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl); 
      then
        (vars,eqnslst,shared,repl);
   case (_,_,_,_,_,_,_,_)
      equation
        // collect set
        (rmax,smax,unremovable,const,_) = getAlias({index},NONE(),mark,simpleeqnsarr,iMT,iVars,NONE(),NONE(),NONE(),NONE());
        // traverse set and add replacements, move vars, ...
        (vars,eqnslst,shared,repl) = handleSet(rmax,smax,unremovable,const,mark+1,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl);
        // next
        (vars,eqnslst,shared,repl) =  fastAcausal3(index-1,mark+2,simpleeqnsarr,iMT,vars,eqnslst,shared,repl); 
      then
        (vars,eqnslst,shared,repl);
  end matchcontinue;
end fastAcausal3;

protected function getAlias
  input list<Integer> rows;
  input Option<Integer> i;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables vars;
  input Option<tuple<Integer,Integer>> iRmax;
  input Option<tuple<Integer,Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  output Option<tuple<Integer,Integer>> oRmax;
  output Option<tuple<Integer,Integer>> oSmax;
  output Option<Integer> oUnremovable;
  output Option<Integer> oConst;
  output Boolean oContinue;
algorithm
  (oRmax,oSmax,oUnremovable,oConst,oContinue) := match(rows,i,mark,simpleeqnsarr,iMT,vars,iRmax,iSmax,iUnremovable,iConst)
    local
      Integer r;
      list<Integer> rest,next,colls;
      SimpleContainer s;
      Option<tuple<Integer,Integer>> rmax,smax;
      Option<Integer> unremovable,const;
      Boolean b,continue;
    case ({},_,_,_,_,_,_,_,_,_) then (iRmax,iSmax,iUnremovable,iConst,true);
    case (r::rest,_,_,_,_,_,_,_,_,_)
      equation
        s = simpleeqnsarr[r];
        b = isVisited(mark,s);
        (rmax,smax,unremovable,const,continue) = getAlias1(b,s,r,rest,i,mark,simpleeqnsarr,iMT,vars,iRmax,iSmax,iUnremovable,iConst);
      then
        (rmax,smax,unremovable,const,continue);
  end match;
end getAlias;

protected function getAlias1
  input Boolean visited;
  input SimpleContainer s;
  input Integer r;
  input list<Integer> rows;
  input Option<Integer> i;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables vars;
  input Option<tuple<Integer,Integer>> iRmax;
  input Option<tuple<Integer,Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  output Option<tuple<Integer,Integer>> oRmax;
  output Option<tuple<Integer,Integer>> oSmax;
  output Option<Integer> oUnremovable;
  output Option<Integer> oConst;
  output Boolean oContinue;
algorithm
  (oRmax,oSmax,oUnremovable,oConst,oContinue) := match(visited,s,r,rows,i,mark,simpleeqnsarr,iMT,vars,iRmax,iSmax,iUnremovable,iConst)
    local
      list<Integer> rest,next;
      Option<tuple<Integer,Integer>> rmax,smax;
      Option<Integer> unremovable,const;
      Boolean b,continue;
    case (true,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // report error 
        Error.addMessage(Error.INTERNAL_ERROR, {"Circular Equalities Detected"});
      then 
        fail();
    case (false,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // set visited
        _= arrayUpdate(simpleeqnsarr,r,setVisited(mark,s));
        // check alias connection
        (rmax,smax,unremovable,const,continue) = getAlias2(s,r,i,mark,simpleeqnsarr,iMT,vars,iRmax,iSmax,iUnremovable,iConst);
        // next arm
        (rmax,smax,unremovable,const,continue) = getAliasContinue(continue,rows,i,mark,simpleeqnsarr,iMT,vars,rmax,smax,unremovable,const);
      then
        (rmax,smax,unremovable,const,continue);
  end match;
end getAlias1;

protected function getAlias2
  input SimpleContainer s;
  input Integer r;
  input Option<Integer> oi;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables vars;
  input Option<tuple<Integer,Integer>> iRmax;
  input Option<tuple<Integer,Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  output Option<tuple<Integer,Integer>> oRmax;
  output Option<tuple<Integer,Integer>> oSmax;
  output Option<Integer> oUnremovable;
  output Option<Integer> oConst;
  output Boolean oContinue;
algorithm
  (oRmax,oSmax,oUnremovable,oConst,oContinue) := match(s,r,oi,mark,simpleeqnsarr,iMT,vars,iRmax,iSmax,iUnremovable,iConst)
    local
      list<Integer> rest,next;
      Option<tuple<Integer,Integer>> rmax,smax;
      Option<Integer> unremovable,const;
      BackendDAE.Var v;
      Integer i1,i2,i;
      Boolean state,replacable,continue;
    case (ALIAS(i1=i1,i2=i2),_,NONE(),_,_,_,_,_,_,_,_)
      equation
        // collect next rows
        next = List.removeOnTrue(r,intEq,iMT[i1]);
        v = BackendVariable.getVarAt(vars,i1);
        // update max
        replacable = replaceableAlias(v);
        state = BackendVariable.isStateVar(v);
        (rmax,smax,unremovable) = getAlias3(v,i1,state,replacable,r,iRmax,iSmax,iUnremovable);
        // go deeper
        (rmax,smax,unremovable,const,continue) = getAlias(next,SOME(i1),mark,simpleeqnsarr,iMT,vars,rmax,smax,unremovable,iConst);    
        // collect next rows
        next = List.removeOnTrue(r,intEq,iMT[i2]);
        v = BackendVariable.getVarAt(vars,i2);
        // update max
        replacable = replaceableAlias(v);
        state = BackendVariable.isStateVar(v);
        (rmax,smax,unremovable) = getAlias3(v,i2,state,replacable,r,rmax,smax,unremovable);
        // go deeper
        (rmax,smax,unremovable,const,continue) = getAliasContinue(continue,next,SOME(i2),mark,simpleeqnsarr,iMT,vars,rmax,smax,unremovable,const);    
       then 
         (rmax,smax,unremovable,const,continue);      
    case (ALIAS(i1=i1,i2=i2),_,SOME(i),_,_,_,_,_,_,_,_)
      equation
        i = Util.if_(intEq(i,i1),i2,i1);
        // collect next rows
        next = List.removeOnTrue(r,intEq,iMT[i]);
        v = BackendVariable.getVarAt(vars,i);
        // update max
        replacable = replaceableAlias(v);
        state = BackendVariable.isStateVar(v);
        (rmax,smax,unremovable) = getAlias3(v,i,state,replacable,r,iRmax,iSmax,iUnremovable);
        // go deeper
        (rmax,smax,unremovable,const,continue) = getAlias(next,SOME(i),mark,simpleeqnsarr,iMT,vars,rmax,smax,unremovable,iConst);    
       then 
         (rmax,smax,unremovable,const,continue);  
    case (PARAMETERALIAS(visited=_),_,_,_,_,_,_,_,_,_,_)
       then
        (NONE(),NONE(),NONE(),SOME(r),false);
    case (TIMEALIAS(visited=_),_,_,_,_,_,_,_,_,_,_)
      then
        (NONE(),NONE(),NONE(),SOME(r),false);
    case (TIMEINDEPENTVAR(visited=_),_,_,_,_,_,_,_,_,_,_)
      then
        (NONE(),NONE(),NONE(),SOME(r),false);
  end match;
end getAlias2;

protected function getAlias3
  input BackendDAE.Var var;
  input Integer i;
  input Boolean state;
  input Boolean replacable;
  input Integer r;
  input Option<tuple<Integer,Integer>> iRmax;
  input Option<tuple<Integer,Integer>> iSmax;
  input Option<Integer> iUnremovable;
  output Option<tuple<Integer,Integer>> oRmax;
  output Option<tuple<Integer,Integer>> oSmax;
  output Option<Integer> oUnremovable;
algorithm
  (oRmax,oSmax,oUnremovable) := match(var,i,state,replacable,r,iRmax,iSmax,iUnremovable)
    local
      Integer w,w1,w2;
      Option<tuple<Integer,Integer>> tpl;
    case(_,_,false,false,_,_,_,NONE())
      equation
        w1 = BackendVariable.calcAliasKey(var);
      then
        (SOME((i,w1)),iSmax,SOME(i));
    case(_,_,true,false,_,_,_,NONE())
      equation
        w1 = BackendVariable.varStateSelectPrioAlias(var);
      then
        (iRmax,SOME((i,w1)),SOME(i));
    case(_,_,true,_,_,_,NONE(),_)
      equation
        w1 = BackendVariable.varStateSelectPrioAlias(var);
      then
        (iRmax,SOME((i,w1)),iUnremovable);
    case(_,_,true,_,_,_,SOME((_,w2)),_)
      equation
        w1 = BackendVariable.varStateSelectPrioAlias(var);
        tpl = Util.if_(intGt(w1,w2),SOME((i,w1)),iSmax);
      then
        (iRmax,tpl,iUnremovable);
    case(_,_,false,_,_,NONE(),_,_)
      equation
        w1 = BackendVariable.calcAliasKey(var);
      then
        (SOME((i,w1)),iSmax,iUnremovable);
    case(_,_,false,_,_,SOME((_,w2)),_,_)
      equation
        w1 = BackendVariable.calcAliasKey(var);
        tpl = Util.if_(intGt(w1,w2),SOME((i,w1)),iRmax);
      then
        (tpl,iSmax,iUnremovable);
  end match;
end getAlias3;

protected function getAliasContinue
  input Boolean iContinue;
  input list<Integer> rows;
  input Option<Integer> i;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables vars;
  input Option<tuple<Integer,Integer>> iRmax;
  input Option<tuple<Integer,Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  output Option<tuple<Integer,Integer>> oRmax;
  output Option<tuple<Integer,Integer>> oSmax;
  output Option<Integer> oUnremovable;
  output Option<Integer> oConst;
  output Boolean oContinue;
algorithm
  (oRmax,oSmax,oUnremovable,oConst,oContinue) := match(iContinue,rows,i,mark,simpleeqnsarr,iMT,vars,iRmax,iSmax,iUnremovable,iConst)
    local
      Option<tuple<Integer,Integer>> rmax,smax;
      Option<Integer> unremovable,const;
      Boolean continue;
    case (true,_,_,_,_,_,_,_,_,_,_)
      equation
        // update candidates
        (rmax,smax,unremovable,const,continue) = getAlias(rows,i,mark,simpleeqnsarr,iMT,vars,iRmax,iSmax,iUnremovable,iConst);
      then
        (rmax,smax,unremovable,const,continue);
    case (false,_,_,_,_,_,_,_,_,_,_)
      then 
        (iRmax,iSmax,iUnremovable,iConst,iContinue);
  end match;
end getAliasContinue;

protected function appendNextRow
  input Integer nr;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input list<Integer> iNext;
  output list<Integer> oNext;
algorithm
  oNext := List.consOnTrue(intNe(getVisited(simpleeqnsarr[nr]),mark),nr,iNext);
end appendNextRow;

protected function isVisited
  input Integer mark;
  input SimpleContainer iS;
  output Boolean visited;
algorithm
  visited := intEq(mark,getVisited(iS));  
end isVisited;

protected function getVisited
  input SimpleContainer iS;
  output Integer visited;
algorithm
  visited := match(iS)
    case ALIAS(visited=visited) then visited;
    case PARAMETERALIAS(visited=visited) then visited;
    case TIMEALIAS(visited=visited) then visited;
    case TIMEINDEPENTVAR(visited=visited) then visited;
  end match;
end getVisited;

protected function setVisited
  input Integer visited;
  input SimpleContainer iS;
  output SimpleContainer oS;
algorithm
  oS := match(visited,iS)
    local
      DAE.ComponentRef cr1,cr2;
      Integer i1,i2;
      DAE.ElementSource source;
      Boolean negate;
      DAE.Exp exp;
    case (_,ALIAS(cr1,i1,cr2,i2,source,negate,_)) then ALIAS(cr1,i1,cr2,i2,source,negate,visited);
    case (_,PARAMETERALIAS(cr1,i1,cr2,i2,source,negate,_)) then PARAMETERALIAS(cr1,i1,cr2,i2,source,negate,visited);
    case (_,TIMEALIAS(cr1,i1,source,negate,_)) then TIMEALIAS(cr1,i1,source,negate,visited);
    case (_,TIMEINDEPENTVAR(cr1,i1,exp,source,_)) then TIMEINDEPENTVAR(cr1,i1,exp,source,visited);
  end match;
end setVisited;

protected function replaceableAlias
"function replaceableAlias
  autor Frenkel TUD 2012-11
  check if the variable is a replaceable alias."
  input BackendDAE.Var var;
  output Boolean res;
algorithm
  res := matchcontinue (var)
    local
      BackendDAE.VarKind kind;
    case BackendDAE.VAR(varKind=kind)
      equation
        //false = BackendVariable.isStateorStateDerVar(var) "cr1 not state";
        BackendVariable.isVarKindVariable(kind) "cr1 not constant";
        false = BackendVariable.isVarOnTopLevelAndOutput(var);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
        false = BackendVariable.varHasUncertainValueRefine(var);
      then
        true;        
    else
      then
        false;
  end matchcontinue;
end replaceableAlias;

protected function handleSet
"function: handleSet
  autor: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input Option<tuple<Integer,Integer>> iRmax;
  input Option<tuple<Integer,Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oVars,oEqnslst,oshared,oRepl):=
  matchcontinue (iRmax,iSmax,iUnremovable,iConst,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl)
    local
      SimpleContainer s;
      Integer r,i,i2;
      BackendDAE.Var v,pv;
      DAE.ComponentRef pcr,cr;
      DAE.ElementSource source;
      Boolean negate,replacable,constExp;
      DAE.Exp exp,exp1,expcr;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      VarSetAttributes vsattr;
   // constant alias set
   case (_,_,_,SOME(r),_,_,_,_,_,_,_)
     equation
       s = simpleeqnsarr[r];
       PARAMETERALIAS(cr=cr,i1=i,i2=i2,paramcr=pcr,source=source,negate=negate) =  s;
       _= arrayUpdate(simpleeqnsarr,r,setVisited(mark,s));
       // generate exp from cref an negate if necessary
       exp = Expression.crefExp(pcr);
       exp1 = Debug.bcallret1(negate,Expression.negate,exp,exp);
       v = BackendVariable.getVarAt(iVars,i);
       replacable = replaceableAlias(v);
       (vars,eqnslst,shared,repl) = handleSetVar(replacable,v,i,source,exp1,iMT,iVars,iEqnslst,ishared,iRepl);
       expcr = Expression.crefExp(cr);
       pv = BackendVariable.getVarSharedAt(i2,ishared);
       vsattr = addVarSetAttributes(pv,false,mark,simpleeqnsarr,EMPTYVARSETATTRIBUTES);
       (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(List.removeOnTrue(r,intEq,iMT[i]),i,exp,SOME(expcr),negate,true,mark,simpleeqnsarr,iMT,vars,eqnslst,shared,repl,vsattr);
     then
       (vars,eqnslst,shared,repl);
   // time set
   case (_,_,_,SOME(r),_,_,_,_,_,_,_)
     equation
       s = simpleeqnsarr[r];
       TIMEALIAS(cr=cr,i=i,source=source,negate=negate) =  s;
       _= arrayUpdate(simpleeqnsarr,r,setVisited(mark,s));
       // generate exp from cref an negate if necessary
       exp = Expression.crefExp(DAE.crefTime);
       exp1 = Debug.bcallret1(negate,Expression.negate,exp,exp);
       v = BackendVariable.getVarAt(iVars,i);
       replacable = replaceableAlias(v);
       (vars,eqnslst,shared,repl) = handleSetVar(replacable,v,i,source,exp1,iMT,iVars,iEqnslst,ishared,iRepl);
       expcr = Expression.crefExp(cr);
       vsattr = EMPTYVARSETATTRIBUTES;
       (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(List.removeOnTrue(r,intEq,iMT[i]),i,exp,SOME(expcr),negate,false,mark,simpleeqnsarr,iMT,vars,eqnslst,shared,repl,vsattr);
     then
       (vars,eqnslst,shared,repl);
   // constant set
   case (_,_,_,SOME(r),_,_,_,_,_,_,_)
     equation
       s = simpleeqnsarr[r];
       TIMEINDEPENTVAR(cr=cr,i=i,exp=exp,source=source) =  s;
       _= arrayUpdate(simpleeqnsarr,r,setVisited(mark,s));
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars,i);
       replacable = replaceableAlias(v);
       // set fixed=true if replacable
       v = Debug.bcallret2(replacable,BackendVariable.setVarFixed,v,true,v);
       (vars,shared,_) = optMoveVarShared(replacable,v,i,source,exp,BackendVariable.addKnVarDAE,iVars,ishared);
       constExp = Expression.isConst(exp);
       // add to replacements if constant
       repl = Debug.bcallret4(replacable and constExp, BackendVarTransform.addReplacement,iRepl, cr, exp,SOME(BackendVarTransform.skipPreChangeEdgeOperator),iRepl);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v,false,mark,simpleeqnsarr,EMPTYVARSETATTRIBUTES);
       (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(List.removeOnTrue(r,intEq,iMT[i]),i,exp,NONE(),false,true,mark,simpleeqnsarr,iMT,vars,iEqnslst,shared,repl,vsattr);
     then
       (vars,eqnslst,shared,repl);
   // variable set
   case (NONE(),NONE(),SOME(i),NONE(),_,_,_,_,_,_,_)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars,i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v,false,mark,simpleeqnsarr,EMPTYVARSETATTRIBUTES);
       (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(iMT[i],i,exp,NONE(),false,false,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl,vsattr);
       vars = handleVarSetAttributes(vsattr,v,i,vars,shared);
     then
       (vars,eqnslst,shared,repl);
   // variable set
   case (_,SOME((i,_)),_,NONE(),_,_,_,_,_,_,_)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars,i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v,false,mark,simpleeqnsarr,EMPTYVARSETATTRIBUTES);
       (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(iMT[i],i,exp,NONE(),false,false,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl,vsattr);
       vars = handleVarSetAttributes(vsattr,v,i,vars,shared);
     then
       (vars,eqnslst,shared,repl);
   // variable set
   case (SOME((i,_)),NONE(),_,NONE(),_,_,_,_,_,_,_)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars,i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v,false,mark,simpleeqnsarr,EMPTYVARSETATTRIBUTES);
       (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(iMT[i],i,exp,NONE(),false,false,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl,vsattr);
       vars = handleVarSetAttributes(vsattr,v,i,vars,shared);
     then
       (vars,eqnslst,shared,repl);
  end matchcontinue;
end handleSet;

protected function handleSetVar
"function: handleSet
  autor: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input Boolean replacable;
  input BackendDAE.Var v;
  input Integer i;
  input DAE.ElementSource source;
  input DAE.Exp exp;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oVars,oEqnslst,oshared,oRepl):=
  match (replacable,v,i,source,exp,iMT,iVars,iEqnslst,ishared,iRepl)
    local
      DAE.ComponentRef cr;
      DAE.Exp crexp;
      BackendDAE.Variables vars;
      Boolean bs;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
   case (true,BackendDAE.VAR(varName=cr),_,_,_,_,_,_,_,_)
     equation
       (vars,shared,bs) = moveVarShared(v,i,source,exp,BackendVariable.addAliasVarDAE,iVars,ishared);
       // add to replacements
       repl = BackendVarTransform.addReplacement(iRepl, cr, exp,SOME(BackendVarTransform.skipPreChangeEdgeOperator));
       // if state der(var) has to replaced to 0
       repl = Debug.bcallret3(bs,BackendVarTransform.addDerConstRepl, cr, DAE.RCONST(0.0), repl, repl);
     then
       (vars,iEqnslst,shared,repl);
   case (false,BackendDAE.VAR(varName=cr),_,_,_,_,_,_,_,_)
     equation
       crexp = Expression.crefExp(cr);
       ((vars,shared,eqnslst,_,_,_,_)) = generateEquation(crexp,exp,Expression.typeof(exp),source,(iVars,ishared,iEqnslst,{},-1,iMT,false));
     then
       (vars,eqnslst,shared,iRepl);
  end match;
end handleSetVar;

protected function optMoveVarShared
"function: optMoveVarShared
  autor: Frenkel TUD 2012-12"
  input Boolean replacable;
  input BackendDAE.Var v;
  input Integer i;
  input DAE.ElementSource source;
  input DAE.Exp exp;
  input FuncMoveVarShared func;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  output BackendDAE.Variables oVars;
  output BackendDAE.Shared oshared;
  output Boolean bs;
  partial function FuncMoveVarShared
    input BackendDAE.Var v;
    input BackendDAE.Shared ishared;
    output BackendDAE.Shared oshared;
  end FuncMoveVarShared;  
algorithm
  (oVars,oshared,bs) := match(replacable,v,i,source,exp,func,iVars,ishared)
    case(true,_,_,_,_,_,_,_)
      equation
        (oVars,oshared,bs) = moveVarShared(v,i,source,exp,func,iVars,ishared);
      then
        (oVars,oshared,bs);
    case(false,_,_,_,_,_,_,_) then (iVars,ishared,false);
  end match;
end optMoveVarShared;

protected function moveVarShared
"function: moveVarShared
  autor: Frenkel TUD 2012-12"
  input BackendDAE.Var v;
  input Integer i;
  input DAE.ElementSource source;
  input DAE.Exp exp;
  input FuncMoveVarShared func;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  output BackendDAE.Variables oVars;
  output BackendDAE.Shared oshared;
  output Boolean bs;
  partial function FuncMoveVarShared
    input BackendDAE.Var v;
    input BackendDAE.Shared ishared;
    output BackendDAE.Shared oshared;
  end FuncMoveVarShared;  
protected
  DAE.ComponentRef cr;
  list<DAE.SymbolicOperation> ops;
  BackendDAE.Var v1;
algorithm
  BackendDAE.VAR(varName=cr) := v;
  // add bindExp
  v1 := BackendVariable.setBindExp(v,exp);
  ops := DAEUtil.getSymbolicTransformations(source);
  v1 := BackendVariable.mergeVariableOperations(v1,DAE.SOLVED(cr,exp)::ops);
  // State?
  bs := BackendVariable.isStateVar(v);
  v1 := Debug.bcallret2(bs,BackendVariable.setVarKind,v1,BackendDAE.DUMMY_STATE(),v1);
  // remove from vars
  (oVars,_) := BackendVariable.removeVar(i,iVars);
  // store changed var
  oshared := func(v1,ishared);
end moveVarShared;

protected function traverseAliasTree
"function: traverseAliasTree
  autor: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input list<Integer> rows;
  input Integer ilast;
  input DAE.Exp exp;
  input Option<DAE.Exp> optExp;
  input Boolean globalnegate;
  input Boolean replaceState;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input VarSetAttributes iAttributes "fixed,list<startvalue,origin,cr>,nominal,min,max";
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
  output VarSetAttributes oAttributes "fixed,list<startvalue,origin,cr>,nominal,min,max";
algorithm
 (oVars,oEqnslst,oshared,oRepl,oAttributes):=
  match (rows,ilast,exp,optExp,globalnegate,replaceState,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl,iAttributes)
    local
      Integer r;
      list<Integer> rest;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      SimpleContainer s;
      VarSetAttributes vsattr;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_) then (iVars,iEqnslst,ishared,iRepl,iAttributes);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        s = simpleeqnsarr[r];
        _= arrayUpdate(simpleeqnsarr,r,setVisited(mark,s));
        (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree1(s,r,ilast,exp,optExp,globalnegate,replaceState,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl,iAttributes);
        (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(rest,ilast,exp,optExp,globalnegate,replaceState,mark,simpleeqnsarr,iMT,vars,eqnslst,shared,repl,vsattr);
      then 
        (vars,eqnslst,shared,repl,vsattr);
  end match;   
end traverseAliasTree;

protected function traverseAliasTree1
"function: traverseAliasTree
  autor: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input SimpleContainer sc;
  input Integer r;
  input Integer ilast;
  input DAE.Exp exp;
  input Option<DAE.Exp> optExp;
  input Boolean globalnegate;
  input Boolean replaceState;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input VarSetAttributes iAttributes "fixed,list<startvalue,origin,cr>,nominal,min,max";
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
  output VarSetAttributes oAttributes "fixed,list<startvalue,origin,cr>,nominal,min,max";
algorithm
 (oVars,oEqnslst,oshared,oRepl,oAttributes):=
  match (sc,r,ilast,exp,optExp,globalnegate,replaceState,mark,simpleeqnsarr,iMT,iVars,iEqnslst,ishared,iRepl,iAttributes)
    local
      Integer i1,i2,i;
      list<Integer> rest;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cr,cr1,cr2;
      Boolean negate,replacable,state,globalnegate1;
      DAE.ElementSource source;
      DAE.Exp crexp,exp1;
      String msg;
      VarSetAttributes vsattr;
    case (ALIAS(cr1,i1,cr2,i2,source,negate,_),_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        i = Util.if_(intEq(i1,ilast),i2,i1);
        (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars,i);
        state = BackendVariable.isStateVar(v);
        replacable = replaceableAlias(v);
        replacable = Util.if_(state,replacable and replaceState,replacable);
        crexp = Expression.crefExp(cr);
        // negate if necessary
        globalnegate1 = Util.if_(negate,not globalnegate,globalnegate);
        exp1 = Debug.bcallret1(globalnegate1,Expression.negate,exp,exp);
        crexp = Debug.bcallret1(negate,Expression.negate,crexp,crexp);
        // replace alias with selected variable if replacable
        source = Debug.bcallret3(replacable,addSubstitutionOption,optExp,crexp,source,source);
        (vars,eqnslst,shared,repl) = handleSetVar(replacable,v,i,source,exp1,iMT,iVars,iEqnslst,ishared,iRepl);
        vsattr = addVarSetAttributes(v,globalnegate,mark,simpleeqnsarr,iAttributes);
        (vars,eqnslst,shared,repl,vsattr) = traverseAliasTree(List.removeOnTrue(r,intEq,iMT[i]),i,exp,SOME(crexp),globalnegate1,replaceState,mark,simpleeqnsarr,iMT,vars,eqnslst,shared,repl,vsattr);
      then
        (vars,eqnslst,shared,repl,vsattr);
    case (PARAMETERALIAS(cr1,i1,cr2,i2,source,negate,_),_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // report error
        cr = Util.if_(intEq(i1,ilast),cr2,cr1);
        crexp = Expression.crefExp(cr);
        crexp = Debug.bcallret1(negate,Expression.negate,crexp,crexp);
        msg = "Found Equation without time dependent variables ";
        msg = msg +& ExpressionDump.printExpStr(exp) +& " = " +& ExpressionDump.printExpStr(crexp) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});        
      then
        fail();
    case (TIMEALIAS(cr=cr,negate=negate),_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // report error
        msg = "Found Equation without time dependent variables ";
        msg = msg +& " time = " +& ExpressionDump.printExpStr(exp) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});        
      then
        fail();
    case (TIMEINDEPENTVAR(cr=cr,exp=exp1),_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // report error
        msg = "Found Equation without time dependent variables ";
        msg = msg +& ExpressionDump.printExpStr(exp) +& " = " +& ExpressionDump.printExpStr(exp1) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});        
      then
        fail();
  end match;   
end traverseAliasTree1;

protected function addSubstitutionOption
"autor: Frenkel TUD 2012-12"
 input Option<DAE.Exp> optExp;
 input DAE.Exp exp;
 input DAE.ElementSource iSource;
 output DAE.ElementSource oSource;
algorithm
  oSource := match(optExp,exp,iSource)
    local DAE.Exp e;
    case (NONE(),_,_) then iSource;
    case (SOME(e),_,_) then DAEUtil.addSymbolicTransformationSubstitution(true,iSource,exp,e);
  end match;
end addSubstitutionOption;

protected function addVarSetAttributes
"autor: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;  
  input VarSetAttributes iAttributes "fixed,list<startvalue,origin,cr>,nominal,min,max";
  output VarSetAttributes oAttributes "fixed,list<startvalue,origin,cr>,nominal,min,max";
protected
  Boolean fixed,fixedset;
  Option<DAE.Exp> start,origin,nominalset;
  tuple<Option<DAE.Exp>,Option<DAE.Exp>> minmaxset;
  Integer nNominal;
  tuple<Integer,list<tuple<Option<DAE.Exp>,DAE.ComponentRef>>> startvalues;
algorithm
  (fixedset,startvalues,nominalset,nNominal,minmaxset) := iAttributes;
  // get attributes
  // fixed
  fixed := BackendVariable.varFixed(inVar);
  // start, add only if fixed == fixedset or fixed
  start := BackendVariable.varStartValueOption(inVar);
  origin := BackendVariable.varStartOrigin(inVar);
  (fixedset,startvalues) := addStartValue(fixed,fixedset,BackendVariable.varCref(inVar),start,origin,negate,mark,simpleeqnsarr,startvalues);
  // nominal
  (nominalset,nNominal) := addNominalAttribute(inVar,negate,nominalset,nNominal);
  // minmax
  minmaxset := addMinMaxAttribute(inVar,negate,mark,simpleeqnsarr,minmaxset);  
  oAttributes := (fixedset,startvalues,nominalset,nNominal,minmaxset);
end addVarSetAttributes;

protected function addStartValue
"autor: Frenkel TUD 2012-12"
  input Boolean fixed;
  input Boolean fixedset;
  input DAE.ComponentRef cr;
  input Option<DAE.Exp> start;
  input Option<DAE.Exp> origin;
  input Boolean negate;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;   
  input tuple<Integer,list<tuple<Option<DAE.Exp>,DAE.ComponentRef>>> iStartvalues;
  output Boolean oFixed;
  output  tuple<Integer,list<tuple<Option<DAE.Exp>,DAE.ComponentRef>>> oStartvalues;
algorithm
  (oFixed,oStartvalues) := matchcontinue(fixed,fixedset,cr,start,origin,negate,mark,simpleeqnsarr,iStartvalues)
    local
      DAE.Exp startexp;
      Integer setorigin,originvalue;
      list<tuple<Option<DAE.Exp>,DAE.ComponentRef>> startvalues,startvalues1;
      Boolean b,b1;
    case (false,true,_,_,_,_,_,_,_) then (fixedset,iStartvalues);
    case (true,false,_,NONE(),_,_,_,_,_)
      equation
        originvalue = BackendVariable.startOriginToValue(origin); 
      then
        (true,(originvalue,{(start,cr)}));
    case (true,false,_,SOME(startexp),_,_,_,_,_)
      equation
        startexp = Debug.bcallret1(negate,Expression.negate,startexp,startexp);
        originvalue = BackendVariable.startOriginToValue(origin); 
      then
        (true,(originvalue,{(SOME(startexp),cr)}));
    case (_,_,_,NONE(),_,_,_,_,(setorigin,startvalues))
      equation
        originvalue = BackendVariable.startOriginToValue(origin); 
        b = intGt(originvalue,setorigin);
        b1 = intEq(originvalue,setorigin);
        startvalues = List.consOnTrue(b1 and fixed,(start,cr),startvalues);
        startvalues1 = Util.if_(fixed,{(start,cr)},{});
        ((setorigin,startvalues)) = Util.if_(b,(originvalue,startvalues1),((setorigin,startvalues)));
      then 
        (fixedset,(setorigin,startvalues));
    case (_,_,_,SOME(startexp),_,_,_,_,(setorigin,startvalues))
      equation
        startexp = Debug.bcallret1(negate,Expression.negate,startexp,startexp);
        originvalue = BackendVariable.startOriginToValue(origin); 
        b = intGt(originvalue,setorigin);
        b1 = intEq(originvalue,setorigin);
        startvalues = List.consOnTrue(b1,(SOME(startexp),cr),startvalues);
        ((setorigin,startvalues)) = Util.if_(b,(originvalue,{(SOME(startexp),cr)}),((setorigin,startvalues)));
      then 
        (fixedset,(setorigin,startvalues));
    else
      equation
        print("RemoveSimpleEquations.addStartValue failed!\n");
      then
        fail();
  end matchcontinue;
end addStartValue;

protected function addNominalAttribute
"autor: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;  
  input Option<DAE.Exp> iNominal;
  input Integer iNNominals;
  output Option<DAE.Exp> oNominal;
  output Integer oNNominals;
algorithm
  (oNominal,oNNominals):= matchcontinue(inVar,negate,iNominal,iNNominals)
    local
      DAE.Exp nominal,nominalset;
    case(_,_,SOME(nominalset),_)
      equation
        nominal = BackendVariable.varNominalValue(inVar);
        nominal = Debug.bcallret1(negate,Expression.negate,nominal,nominal);
        nominalset = Expression.expAdd(nominal,nominalset);
      then
        (SOME(nominalset),iNNominals+1);
    case(_,_,NONE(),_)
      equation
        nominal = BackendVariable.varNominalValue(inVar);
        nominal = Debug.bcallret1(negate,Expression.negate,nominal,nominal);
      then
        (SOME(nominal),1);
    else then (iNominal,iNNominals);
  end matchcontinue;
end addNominalAttribute;

protected function addMinMaxAttribute
"autor: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;  
  input tuple<Option<DAE.Exp>,Option<DAE.Exp>> iMinMax;
  output tuple<Option<DAE.Exp>,Option<DAE.Exp>> oMinMax;
protected
  Option<DAE.VariableAttributes> attr;
  list<Option<DAE.Exp>> ominmax;
algorithm
  BackendDAE.VAR(values = attr) := inVar;
  ominmax := DAEUtil.getMinMax(attr);
  oMinMax := mergeMinMax(negate,ominmax,iMinMax,mark,simpleeqnsarr);
end addMinMaxAttribute;

protected function mergeMinMax
"autor: Frenkel TUD 2012-12"
  input Boolean negate;
  input list<Option<DAE.Exp>> ominmax;
  input tuple<Option<DAE.Exp>,Option<DAE.Exp>> ominmax1;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  output tuple<Option<DAE.Exp>,Option<DAE.Exp>> outMinMax;
algorithm
  outMinMax :=
  match (negate,ominmax,ominmax1,mark,simpleeqnsarr)
    local
      DAE.Exp min,max,min1,max1;
      Option<DAE.Exp> omin,omax;
      tuple<Option<DAE.Exp>,Option<DAE.Exp>> minMax;
    case (_,{},_,_,_)
      then
        ominmax1;
    case (false,{omin,omax},_,_,_)
      equation
        minMax = mergeMinMax1((omin,omax),ominmax1);
        checkMinMax(minMax,mark,simpleeqnsarr);
      then
        minMax;
    // in case of a=-b, min and max have to be changed and negated
    case (true,{NONE(),NONE()},_,_,_)
      then
        ominmax1;
    case (true,{SOME(min),SOME(max)},_,_,_)
      equation
        min1 = Expression.negate(min);
        max1 = Expression.negate(max);
        minMax = mergeMinMax1((SOME(max1),SOME(min1)),ominmax1);
        checkMinMax(minMax,mark,simpleeqnsarr);
      then
        minMax;        
    case (true,{NONE(),SOME(max)},_,_,_)
      equation
        max1 = Expression.negate(max);
        minMax = mergeMinMax1((SOME(max1),NONE()),ominmax1);
        checkMinMax(minMax,mark,simpleeqnsarr);
      then
        minMax;        
    case (true,{SOME(min),NONE()},_,_,_)
      equation
        min1 = Expression.negate(min);
        minMax = mergeMinMax1((NONE(),SOME(min1)),ominmax1);
        checkMinMax(minMax,mark,simpleeqnsarr);
      then
        minMax;
    else
      equation
        print("RemoveSimpleEquations.mergeMinMax failed!\n");
      then
        fail();        
  end match;
end mergeMinMax;

protected function checkMinMax
"autor: Frenkel TUD 2012-12"
  input tuple<Option<DAE.Exp>,Option<DAE.Exp>> minmax;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
algorithm
  _ :=
  matchcontinue (minmax,mark,simpleeqnsarr)
    local
      DAE.Exp min,max;
      String s,s1,s2,s3,s4,s5;
      Real rmin,rmax;
    case ((SOME(min),SOME(max)),_,_)
      equation
        rmin = Expression.expReal(min);
        rmax = Expression.expReal(max);
        true = realGt(rmin,rmax);
        s4 = ExpressionDump.printExpStr(min);
        s5 = ExpressionDump.printExpStr(max);
        s = stringAppendList({"Alias variables with invalid limits min ",s4," > max ",s5});
        Error.addMessage(Error.COMPILER_WARNING,{s});        
      then ();
    // no error
    else
      ();
  end matchcontinue;
end checkMinMax;

protected function mergeMinMax1
"autor: Frenkel TUD 2012-12"
  input tuple<Option<DAE.Exp>,Option<DAE.Exp>> ominmax;
  input tuple<Option<DAE.Exp>,Option<DAE.Exp>> ominmax1;
  output tuple<Option<DAE.Exp>,Option<DAE.Exp>> minMax;
algorithm
  minMax :=
  match (ominmax,ominmax1)
    local
      DAE.Exp min,max,min1,max1,min_2,max_2,smin,smax;
    // (_,_),()
    case (_,(NONE(),NONE()))
      then ominmax;
    case ((NONE(),NONE()),_)
      then ominmax1;
    // (min,),(min,)
    case ((SOME(min),NONE()),(SOME(min1),NONE()))
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),NONE()));
    // (,max),(,max)
    case ((NONE(),SOME(max)),(NONE(),SOME(max1)))
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((NONE(),SOME(smax)));
    // (min,),(,max)
    case ((SOME(min),NONE()),(NONE(),SOME(max1)))
      then ((SOME(min),SOME(max1))); 
    // (,max),(min,)
    case ((NONE(),SOME(max)),(SOME(min1),NONE()))
      then ((SOME(min1),SOME(max)));               
    // (,max),(min,max)
    case ((NONE(),SOME(max)),(SOME(min1),SOME(max1)))
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min1),SOME(smax)));
    // (min,max),(,max)
    case ((SOME(min),SOME(max)),(NONE(),SOME(max1)))
      equation
        max_2 = Expression.expMinScalar(max,max1);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min),SOME(smax)));
    // (min,),(min,max)
    case ((SOME(min),NONE()),(SOME(min1),SOME(max1)))
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),SOME(max1)));
    // (min,max),(min,)
    case ((SOME(min),SOME(max)),(SOME(min1),NONE()))
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin),SOME(max)));
    // (min,max),(min,max)
    case ((SOME(min),SOME(max)),(SOME(min1),SOME(max1)))
      equation
        min_2 = Expression.expMaxScalar(min,min1);
        max_2 = Expression.expMinScalar(max,max1);
        (smin,_) = ExpressionSimplify.simplify(min_2);
        (smax,_) = ExpressionSimplify.simplify(max_2);
      then ((SOME(smin),SOME(smax)));
    else
      equation
        print("RemoveSimpleEquations.mergeMinMax1 failed!\n");
      then
        fail();         
  end match;
end mergeMinMax1;

protected function handleVarSetAttributes
"autor: Frenkel TUD 2012-12"
  input VarSetAttributes iAttributes "fixed,list<startvalue,origin,cr>,nominal,min,max";
  input BackendDAE.Var inVar;
  input Integer i;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  output BackendDAE.Variables oVars;
algorithm
  oVars := matchcontinue(iAttributes,inVar,i,iVars,ishared)
    local
		  Boolean fixedset;
		  Option<DAE.Exp> nominalset;
		  tuple<Option<DAE.Exp>,Option<DAE.Exp>> minmaxset;
		  Integer nNominal;
		  tuple<Integer,list<tuple<Option<DAE.Exp>,DAE.ComponentRef>>> startvalues;
		  BackendDAE.Var v;
		  BackendDAE.Variables vars;
    case((fixedset,startvalues,nominalset,nNominal,minmaxset),_,_,_,_)
      equation
        // start and fixed
        v = mergeStartFixedAttributes(inVar,fixedset,startvalues,ishared);
        // nominal
        v = mergeNominalAttribute(nominalset,nNominal,v);
        // min max
        v = BackendVariable.setVarMinMax(v,minmaxset);
        // update vars
        vars = BackendVariable.addVar(v,iVars);
      then
        vars;
    else
      equation
        print("RemoveSimpleEquations.handleVarSetAttributes failed!\n");
      then
        fail();          
  end matchcontinue;
end handleVarSetAttributes;

protected function mergeStartFixedAttributes
  input BackendDAE.Var inVar;
  input Boolean fixed;
  input tuple<Integer,list<tuple<Option<DAE.Exp>,DAE.ComponentRef>>> startvalues;
  input BackendDAE.Shared ishared;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(inVar,fixed,startvalues,ishared)
    local
      DAE.ComponentRef cr;
      Option<DAE.Exp> start,start1;
      tuple<Option<DAE.Exp>,DAE.ComponentRef> value;
      list<tuple<Option<DAE.Exp>,DAE.ComponentRef>> values;
      list<tuple<DAE.Exp,DAE.ComponentRef>> zerofreevalues;
      BackendDAE.Var v;
      BackendDAE.Variables knVars;
      Option<tuple<Option<DAE.Exp>,DAE.ComponentRef>> tpl;
    // default value
    case (_,_,(_,{}),_) then inVar;
    // fixed true only one start value -> nothing changed
    case (_,true,(_,{(start,_)}),_)
      equation
        v = BackendVariable.setVarFixed(inVar, true);
      then
        BackendVariable.setVarStartValueOption(v, start);
    // fixed true several start values, this need some investigation
    case (_,true,(_,(start,cr)::values),BackendDAE.SHARED(knownVars=knVars))
      equation
        v = BackendVariable.setVarFixed(inVar, true);
        start1 = optExpReplaceCrefWithBindExp(start,knVars);
        ((_,start,_)) = equalNonFreeStartValues(values,knVars,(start1,start,cr));
      then
        BackendVariable.setVarStartValueOption(v, start);
    case (_,true,(_,values),BackendDAE.SHARED(knownVars=knVars))
      equation
        v = BackendVariable.setVarFixed(inVar, true);
        // get all nonzero values
        zerofreevalues = List.fold(values,getZeroFreeValues,{});
      then
        selectFreeValue1(zerofreevalues,NONE(),"fixed Aliasset with several free start values\n",v);
    // fixed false only one start value -> nothing changed
    case (_,false,(_,{(start,_)}),_)
      then
        BackendVariable.setVarStartValueOption(inVar, start);
    // fixed false several start value, this need some investigation
    case (_,false,(_,(start,cr)::values),BackendDAE.SHARED(knownVars=knVars))
      equation
        start1 = optExpReplaceCrefWithBindExp(start,knVars);
        ((_,start,_)) = equalFreeStartValues(values,knVars,(start1,start,cr));
      then
        BackendVariable.setVarStartValueOption(inVar, start);
    case (_,false,(_,values),_)
      equation
        // get all nonzero values
        zerofreevalues = List.fold(values,getZeroFreeValues,{});
      then
        selectFreeValue(zerofreevalues,inVar);
  end matchcontinue;
end mergeStartFixedAttributes;

protected function optExpReplaceCrefWithBindExp
  input Option<DAE.Exp> iOExp;
  input BackendDAE.Variables knVars;
  output Option<DAE.Exp> oOExp;
algorithm
  oOExp := match(iOExp,knVars)
    local 
      DAE.Exp e;
      Boolean b;
    case(NONE(),_) then iOExp;
    case(SOME(e),_)
      equation
        ((e, (_,b,_))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        (e,_) = ExpressionSimplify.condsimplify(b,e);
      then
        SOME(e);
 end match;
end optExpReplaceCrefWithBindExp;

protected function equalNonFreeStartValues
  input list<tuple<Option<DAE.Exp>,DAE.ComponentRef>> iValues;
  input BackendDAE.Variables knVars;
  input tuple<Option<DAE.Exp>,Option<DAE.Exp>,DAE.ComponentRef> iValue;
  output tuple<Option<DAE.Exp>,Option<DAE.Exp>,DAE.ComponentRef> oValue;
algorithm
  oValue := matchcontinue(iValues,knVars,iValue)
    local
      Option<tuple<Option<DAE.Exp>,DAE.ComponentRef>> value;
      list<tuple<Option<DAE.Exp>,DAE.ComponentRef>> values;
      DAE.Exp e,e1,e2;
      Boolean b;
      DAE.ComponentRef cr;
    case ({},_,_) then iValue;
    case (((NONE(),_))::values,_,_)
      then
        equalNonFreeStartValues(values,knVars,iValue);
    case (((NONE(),_))::values,_,(NONE(),_,_))
      then 
        equalNonFreeStartValues(values,knVars,iValue);
    case (((NONE(),cr))::values,_,(SOME(e2),_,_))
      equation
        true = Expression.isZero(e2);
      then 
        equalNonFreeStartValues(values,knVars,(NONE(),NONE(),cr));
    case (((SOME(e),_))::values,_,(SOME(e2),_,_))
      equation
        ((e1, (_,b,_))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        (e1,_) = ExpressionSimplify.condsimplify(b,e1);
        true = Expression.expEqual(e1, e2);
      then
        equalNonFreeStartValues(values,knVars,iValue);
  end matchcontinue;
end equalNonFreeStartValues;

protected function equalFreeStartValues
  input list<tuple<Option<DAE.Exp>,DAE.ComponentRef>> iValues;
  input BackendDAE.Variables knVars;
  input tuple<Option<DAE.Exp>,Option<DAE.Exp>,DAE.ComponentRef> iValue;
  output tuple<Option<DAE.Exp>,Option<DAE.Exp>,DAE.ComponentRef> oValue;
algorithm
  oValue := matchcontinue(iValues,knVars,iValue)
    local
      Option<tuple<Option<DAE.Exp>,DAE.ComponentRef>> value;
      list<tuple<Option<DAE.Exp>,DAE.ComponentRef>> values;
      DAE.Exp e,e1,e2;
      Boolean b;
      DAE.ComponentRef cr;
    case ({},_,_) then iValue;
    // ignore default values
    case (((NONE(),_))::values,_,_)
      then
        equalFreeStartValues(values,knVars,iValue);
    case (((SOME(e),cr))::values,_,(NONE(),_,_))
      equation
        ((e1, (_,b,_))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        (e1,_) = ExpressionSimplify.condsimplify(b,e1);
      then
        equalFreeStartValues(values,knVars,(SOME(e1),SOME(e),cr));
    // compare
    case (((SOME(e),_))::values,_,(SOME(e2),_,_))
      equation
        ((e1, (_,b,_))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        (e1,_) = ExpressionSimplify.condsimplify(b,e1);
        true = Expression.expEqual(e1, e2);
      then
        equalFreeStartValues(values,knVars,iValue);
  end matchcontinue;
end equalFreeStartValues;

protected function replaceCrefWithBindExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,HashSet.HashSet>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,HashSet.HashSet>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      Boolean b;
      HashSet.HashSet hs;
    // true if crefs replaced in expression
    case ((DAE.CREF(componentRef=cr), (vars,_,hs)))
      equation
        // check for cyclic bindings in start value
        false = BaseHashSet.has(cr, hs);
        ({BackendDAE.VAR(bindExp = SOME(e))}, _) = BackendVariable.getVar(cr, vars);
        hs = BaseHashSet.add(cr,hs);
        ((e, (_,_,hs))) = Expression.traverseExp(e, replaceCrefWithBindExp, (vars,false,hs));
      then
        ((e, (vars,true,hs)));
    // true if crefs in expression
    case ((e as DAE.CREF(componentRef=cr), (vars,_,hs)))
      then
        ((e, (vars,true,hs)));        
    else then inTuple;
  end matchcontinue;
end replaceCrefWithBindExp;

protected function getZeroFreeValues
  input tuple<Option<DAE.Exp>,DAE.ComponentRef> inTpl;
  input list<tuple<DAE.Exp,DAE.ComponentRef>> iAcc;
  output list<tuple<DAE.Exp,DAE.ComponentRef>> oAcc;
algorithm
  oAcc := match(inTpl,iAcc)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
    case((NONE(),_),_) then iAcc;
    case ((SOME(e),cr),_) then (e,cr)::iAcc;
  end match;
end getZeroFreeValues;

protected function selectFreeValue
  input list<tuple<DAE.Exp,DAE.ComponentRef>> iZeroFreeValues;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match(iZeroFreeValues,inVar)
    local
      DAE.Exp e,e1;
      DAE.ComponentRef cr,cr1;
      BackendDAE.Var v;
      list<tuple<DAE.Exp,DAE.ComponentRef>> zerofreevalues;
      Integer i,i1;
      Option<tuple<DAE.Exp,DAE.ComponentRef,Integer>> favorit;
    case ({},_) then inVar;
    case (_,_)
      then
        selectFreeValue1(iZeroFreeValues,NONE(),"Aliasset with several free start values\n",inVar);
  end match;  
end selectFreeValue;

protected function selectFreeValue1
  input list<tuple<DAE.Exp,DAE.ComponentRef>> iZeroFreeValues;
  input Option<tuple<DAE.Exp,DAE.ComponentRef,Integer>> iFavorit;
  input String iStr;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match(iZeroFreeValues,iFavorit,iStr,inVar)
    local
      DAE.Exp e,e1;
      DAE.ComponentRef cr,cr1;
      BackendDAE.Var v;
      list<tuple<DAE.Exp,DAE.ComponentRef>> zerofreevalues;
      Integer i,i1;
      Option<tuple<DAE.Exp,DAE.ComponentRef,Integer>> favorit;
      String s;
    case ({},NONE(),_,_) then inVar;
    case ({},SOME((e,cr,_)),_,_)
      equation
        s = iStr +& "Select value from " +& ComponentReference.printComponentRefStr(cr) +& "(start = " +& ExpressionDump.printExpStr(e) +& ")";
        Error.addMessage(Error.COMPILER_WARNING,{s});
        v = BackendVariable.setVarStartValue(inVar, e);
      then
        v;
    case ((e,cr)::zerofreevalues,NONE(),_,_)
      equation
        s = iStr +& "Candidate " +& ComponentReference.printComponentRefStr(cr) +& "(start = " +& ExpressionDump.printExpStr(e) +& ")\n";
        i = ComponentReference.crefDepth(cr);
      then
        selectFreeValue1(zerofreevalues,SOME((e,cr,i)),s,inVar);
    case ((e,cr)::zerofreevalues,SOME((_,_,i1)),_,_)
      equation
        s = iStr +& "Candidate " +& ComponentReference.printComponentRefStr(cr) +& "(start = " +& ExpressionDump.printExpStr(e) +& ")\n";
        i = ComponentReference.crefDepth(cr);
        favorit = Util.if_(intGt(i,i1),SOME((e,cr,i)),iFavorit);
      then
        selectFreeValue1(zerofreevalues,favorit,s,inVar);
  end match;  
end selectFreeValue1;

protected function mergeNominalAttribute
"autor: Frenkel TUD 2012-12"
  input Option<DAE.Exp> nominal;
  input Integer n;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  match (nominal,n,inVar)
    local
      Real r;
      DAE.Exp e;
    case (SOME(e),_,_)
      equation 
        r = intReal(n);
        e = Expression.expDiv(e,DAE.RCONST(r)); // Real is legal because only Reals have nominal attribute
        (e,_) = ExpressionSimplify.simplify(e); 
      then 
        BackendVariable.setVarNominalValue(inVar,e);
    case (NONE(),_,_) then inVar;
  end match;
end mergeNominalAttribute;

protected function removeSimpleEquationsShared
"function: removeSimpleEquationsShared"
  input Boolean b;
  input BackendDAE.BackendDAE inDAE;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:=
  match (b,inDAE,repl)
    local
      BackendDAE.Variables ordvars,knvars,exobj,knvars1;
      BackendDAE.Variables aliasVars;      
      BackendDAE.EquationArray remeqns,inieqns,remeqns1;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcTree;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst,whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst, relationsLst,sampleLst;
      Integer numberOfRealtions,numMathFunctions;
      BackendDAE.BackendDAEType btp; 
      BackendDAE.EqSystems systs,systs1;
      list<BackendDAE.Equation> eqnslst;
    case (false,_,_) then inDAE;
    case (true,BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst,zeroCrossingLst,sampleLst,relationsLst,numberOfRealtions,numMathFunctions),eoc,btp,symjacs)),_)
      equation
        Debug.fcall(Flags.DUMP_REPL, BackendVarTransform.dumpReplacements, repl);
        Debug.fcall(Flags.DUMP_REPL, BackendVarTransform.dumpExtendReplacements, repl);        
        // replace moved vars in knvars,remeqns
        (aliasVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars,replaceAliasVarTraverser,repl);
        (knvars1,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceVarTraverser,repl);
        ((_,eqnslst)) = BackendEquation.traverseBackendDAEEqns(inieqns,replaceEquationTraverser,(repl,{}));
        inieqns = BackendEquation.listEquation(eqnslst);
        ((_,eqnslst)) = BackendEquation.traverseBackendDAEEqns(remeqns,replaceEquationTraverser,(repl,{}));
        remeqns1 = BackendEquation.listEquation(eqnslst);
        (whenClauseLst1,_) = BackendVarTransform.replaceWhenClauses(whenClauseLst, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        systs1 = removeSimpleEquationsShared1(systs,{},repl);
        // remove asserts with condition=true from removed equations
        remeqns1 = BackendEquation.listEquation(List.select(BackendEquation.equationList(remeqns1),assertWithCondTrue));
      then 
        BackendDAE.DAE(systs1,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns1,constrs,clsAttrs,cache,env,funcTree,BackendDAE.EVENT_INFO(whenClauseLst1,zeroCrossingLst,sampleLst,relationsLst,numberOfRealtions,numMathFunctions),eoc,btp,symjacs));
  end match;
end removeSimpleEquationsShared;

protected function replaceAliasVarTraverser
"autor: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v,v1;
      BackendVarTransform.VariableReplacements repl;
      DAE.Exp e,e1;
      Boolean b;
    case ((v as BackendDAE.VAR(bindExp=SOME(e)),repl))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        b = Expression.isConst(e1);
        v1 = Debug.bcallret2(not b,BackendVariable.setBindExp,v,e1,v);
      then ((v1,repl));
    case _ then inTpl;
  end matchcontinue;
end replaceAliasVarTraverser;

protected function replaceVarTraverser
"autor: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v,v1;
      BackendVarTransform.VariableReplacements repl;
      DAE.Exp e,e1;
    case ((v as BackendDAE.VAR(bindExp=SOME(e)),repl))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v,e1);
      then ((v1,repl));
    case _ then inTpl;
  end matchcontinue;
end replaceVarTraverser;

protected function assertWithCondTrue
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match inEqn
    case BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond=DAE.BCONST(true))})) then false;
    else then true;
  end match;
end assertWithCondTrue;

protected function removeSimpleEquationsShared1
  input BackendDAE.EqSystems inSysts;
  input BackendDAE.EqSystems inSysts1;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystems outSysts;
algorithm
  outSysts := match (inSysts,inSysts1,repl)
    local
      BackendDAE.EqSystems rest,systs;
      BackendDAE.Variables v;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
      list<BackendDAE.Equation> eqnslst;
      case ({},_,_) then inSysts1;
      case (BackendDAE.EQSYSTEM(v,eqns,m,mT,matching)::rest,_,_)
        equation
        ((_,eqnslst)) = BackendEquation.traverseBackendDAEEqns(eqns,replaceEquationTraverser,(repl,{}));
        eqns = BackendEquation.listEquation(eqnslst);        
        systs = BackendDAE.EQSYSTEM(v,eqns,m,mT,matching)::inSysts1;
        then
          removeSimpleEquationsShared1(rest,systs,repl);
    end match;
end removeSimpleEquationsShared1;

protected function replaceEquationTraverser
  "Help function to e.g. removeSimpleEquations"
  input tuple<BackendDAE.Equation,tuple<BackendVarTransform.VariableReplacements,list<BackendDAE.Equation>>> inTpl;
  output tuple<BackendDAE.Equation,tuple<BackendVarTransform.VariableReplacements,list<BackendDAE.Equation>>> outTpl;
algorithm
  outTpl:=  
  match (inTpl)
    local
      BackendDAE.Equation e;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqns,eqns1;
    case ((e,(repl,eqns)))
      equation
        (eqns1,_) = BackendVarTransform.replaceEquations({e},repl,SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        eqns = listAppend(eqns1,eqns);
      then ((e,(repl,eqns)));
  end match;
end replaceEquationTraverser;

end RemoveSimpleEquations;
