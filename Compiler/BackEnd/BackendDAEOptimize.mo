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

encapsulated package BackendDAEOptimize
" file:        BackendDAEOptimize.mo
  package:     BackendDAEOptimize
  description: BackendDAEOptimize contains functions that do some kind of
               optimazation on the BackendDAE datatype:
               - removing simpleEquations
               - Tearing/Relaxation
               - Linearization
               - Inline Integration
               - and so on ...

  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;
public import HashTable2;

protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import BaseHashTable;
protected import Builtin;
protected import Ceval;
protected import CevalScript;
protected import CheckModel;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Error;
protected import Flags;
protected import Graph;
protected import HashTableExpToIndex;
protected import Inline;
protected import List;
protected import System;
protected import Types;
protected import Util;
protected import Values;
protected import ValuesUtil;

// =============================================================================
// inline arrayeqns stuff
//
// =============================================================================
public function inlineArrayEqn "function inlineArrayEqn
  author: Frenkel TUD 2011-3"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,inlineArrayEqn1,false);
end inlineArrayEqn;

public function inlineArrayEqnShared "function inlineArrayEqnShared"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match(inDAE)
    local
      BackendDAE.Variables ordvars,knvars,exobj,knvars1,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns,eqns1,inieqns1,remeqns1,eqns2;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcTree;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EventInfo ev;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs,systs1;
      BackendDAE.Shared shared;
      list<BackendDAE.Var> ordvarslst;
      list<BackendDAE.Equation> eqnslst;
      Boolean b;
    case (_) then inDAE;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,ev,eoc,btp,symjacs)))
      equation
        eqnslst = BackendEquation.equationList(inieqns);
        (eqnslst,b) = getScalarArrayEqns(eqnslst,{},false);
        inieqns = Debug.bcallret1(b,BackendEquation.listEquation,eqnslst,inieqns);
        eqnslst = BackendEquation.equationList(remeqns);
        (eqnslst,b) = getScalarArrayEqns(eqnslst,{},false);
        remeqns = Debug.bcallret1(b,BackendEquation.listEquation,eqnslst,remeqns);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,ev,eoc,btp,symjacs));
  end match;
end inlineArrayEqnShared;

protected function inlineArrayEqn1 "function: inlineArrayEqn1
  author: Frenkel TUD 2011-5"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedOptimized;
algorithm
  (osyst,osharedOptimized) := matchcontinue (isyst,sharedOptimized)
    local
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> eqnslst;
      Integer oldsize,newsize;
      BackendDAE.Matching matching;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.StateSets stateSets;
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=m,mT=mT,matching=matching,stateSets=stateSets),(shared,_))
      equation
        eqnslst = BackendEquation.equationList(eqns);
        (eqnslst,true) = getScalarArrayEqns(eqnslst,{},false);
        eqns = BackendEquation.listEquation(eqnslst);
      then
        (BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets),(shared,true));
    else
      then
        (isyst,sharedOptimized);
  end matchcontinue;
end inlineArrayEqn1;

public function getScalarArrayEqns
  input list<BackendDAE.Equation> iEqsLst;
  input list<BackendDAE.Equation> iAcc;
  input Boolean iFound;
  output list<BackendDAE.Equation> oEqsLst;
  output Boolean oFound;
algorithm
  (oEqsLst,oFound) := match(iEqsLst,iAcc,iFound)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns,eqns1;
      Boolean b;
    case ({},_,_) then (listReverse(iAcc),iFound);
    case (eqn::eqns,_,_)
     equation
       (eqns1,b) = getScalarArrayEqns1(eqn,iAcc);
       (eqns1,b) = getScalarArrayEqns(eqns,eqns1,b or iFound);
     then
       (eqns1,b);
  end match;
end getScalarArrayEqns;

protected function getScalarArrayEqns1 "function getScalarArrayEqns1
  author: Frenkel TUD 2012-06"
  input  BackendDAE.Equation iEqn;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEqsLst;
  output Boolean oFound;
algorithm
  (outEqsLst,oFound) := matchcontinue (iEqn,iAcc)
    local
      DAE.ElementSource source;
      DAE.Exp e1,e2,e1_1,e2_1;
      list<DAE.Exp> ea1,ea2;
      list<BackendDAE.Equation> eqns;
      Boolean diffed;
    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2,source=source,differentiated=diffed),_)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
        ((_,eqns)) = List.threadFold3(ea1,ea2,generateScalarArrayEqns2,source,diffed,DAE.EQUALITY_EXPS(e1,e2),(1,iAcc));
      then
        (eqns,true);
    case (BackendDAE.ARRAY_EQUATION(left=e1 as DAE.CREF(componentRef =_),right=e2,source=source,differentiated=diffed),_)
      equation
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        ea1 = Expression.flattenArrayExpToList(e1_1);
        ea2 = Expression.flattenArrayExpToList(e2);
        ((_,eqns)) = List.threadFold3(ea1,ea2,generateScalarArrayEqns2,source,diffed,DAE.EQUALITY_EXPS(e1,e2),(1,iAcc));
      then
        (eqns,true);
    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2 as DAE.CREF(componentRef =_),source=source,differentiated=diffed),_)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2_1);
        ((_,eqns)) = List.threadFold3(ea1,ea2,generateScalarArrayEqns2,source,diffed,DAE.EQUALITY_EXPS(e1,e2),(1,iAcc));
      then
        (eqns,true);
    case (BackendDAE.ARRAY_EQUATION(left=e1 as DAE.CREF(componentRef =_),right=e2 as DAE.CREF(componentRef =_),source=source,differentiated=diffed),_)
      equation
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        ea1 = Expression.flattenArrayExpToList(e1_1);
        ea2 = Expression.flattenArrayExpToList(e2_1);
        ((_,eqns)) = List.threadFold3(ea1,ea2,generateScalarArrayEqns2,source,diffed,DAE.EQUALITY_EXPS(e1,e2),(1,iAcc));
      then
        (eqns,true);
    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2,source=source,differentiated=diffed),_)
      equation
        ea1 = Expression.splitRecord(e1,Expression.typeof(e1));
        ea2 = Expression.splitRecord(e2,Expression.typeof(e2));
        ((_,eqns)) = List.threadFold3(ea1,ea2,generateScalarArrayEqns2,source,diffed,DAE.EQUALITY_EXPS(e1,e2),(1,iAcc));
      then
        (eqns,true);
    case (_,_) then (iEqn::iAcc,false);
  end matchcontinue;
end getScalarArrayEqns1;

protected function generateScalarArrayEqns2 "function generateScalarArrayEqns2
  author: Frenkel TUD 2012-06"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource inSource;
  input Boolean diffed;
  input DAE.EquationExp eqExp "Original expressions; for the symbolic trace";
  input tuple<Integer /* Current index; for the symbolic trace */,list<BackendDAE.Equation>> iEqns;
  output tuple<Integer,list<BackendDAE.Equation>> oEqns;
algorithm
  oEqns := matchcontinue(inExp1,inExp2,inSource,diffed,eqExp,iEqns)
    local
      Expression.Type tp;
      Integer size,i;
      DAE.Dimensions dims;
      list<Integer> ds;
      Boolean b1,b2;
      list<BackendDAE.Equation> eqns;
      DAE.ElementSource source;
    // complex types to complex equations
    case (_,_,_,_,_,(i,eqns))
      equation
        tp = Expression.typeof(inExp1);
        true = DAEUtil.expTypeComplex(tp);
        size = Expression.sizeOf(tp);
        source = DAEUtil.addSymbolicTransformation(inSource,DAE.OP_SCALARIZE(eqExp,i,DAE.EQUALITY_EXPS(inExp1,inExp2)));
      then
        ((i+1,BackendDAE.COMPLEX_EQUATION(size,inExp1,inExp2,source,diffed)::eqns));

    // array types to array equations
    case (_,_,_,_,_,(i,eqns))
      equation
        tp = Expression.typeof(inExp1);
        true = DAEUtil.expTypeArray(tp);
        dims = Expression.arrayDimension(tp);
        ds = Expression.dimensionsSizes(dims);
        source = DAEUtil.addSymbolicTransformation(inSource,DAE.OP_SCALARIZE(eqExp,i,DAE.EQUALITY_EXPS(inExp1,inExp2)));
      then
        ((i+1,BackendDAE.ARRAY_EQUATION(ds,inExp1,inExp2,source,diffed)::eqns));
    // other types
    case (_,_,_,_,_,(i,eqns))
      equation
        tp = Expression.typeof(inExp1);
        b1 = DAEUtil.expTypeComplex(tp);
        b2 = DAEUtil.expTypeArray(tp);
        false = b1 or b2;
        //Error.assertionOrAddSourceMessage(not b1,Error.INTERNAL_ERROR,{str}, Absyn.dummyInfo);
        source = DAEUtil.addSymbolicTransformation(inSource,DAE.OP_SCALARIZE(eqExp,i,DAE.EQUALITY_EXPS(inExp1,inExp2)));
      then
        ((i+1,BackendDAE.EQUATION(inExp1,inExp2,source,diffed)::eqns));
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAEOptimize.generateScalarArrayEqns2 failed on: " +& ExpressionDump.printExpStr(inExp1) +& " = " +& ExpressionDump.printExpStr(inExp2) +& "\n");
      then
        fail();
  end matchcontinue;
end generateScalarArrayEqns2;




// =============================================================================
// inline functions stuff
//
// =============================================================================
public function lateInlineFunction "function lateInlineFunction"
    input BackendDAE.BackendDAE inDAE;
    output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := Inline.inlineCalls({DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()},inDAE);
end lateInlineFunction;




// =============================================================================
// remove simply equations stuff
//
// =============================================================================
protected function updateEquationSystemMatching
" function: updateEquationSystemMatching
  author: Frenkel TUD 2012-09"
  input BackendDAE.Variables ordvars;
  input BackendDAE.EquationArray eqns;
  input array<Integer> ass1 "ass[varindx]=eqnindx";
  input array<Integer> ass2 "ass[eqnindx]=varindx";
  input BackendDAE.StrongComponents comps;
  input BackendDAE.StateSets stateSets;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := matchcontinue(ordvars,eqns,ass1,ass2,comps,stateSets)
    local
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
      Integer bucketSize,numberOfVars,size,neqns,nvars,arrSizeEqns,arrSizeVars,neqns1,nvars1;
      array<Option<BackendDAE.Var>> varOptArr;
      array<Option<BackendDAE.Equation>> equOptArr;
      array<Integer> eqnindxs,varindxs;
      BackendDAE.StrongComponents comps_1;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns1;
      BackendDAE.VariableArray varArr;
    case(BackendDAE.VARIABLES(varArr=BackendDAE.VARIABLE_ARRAY(nvars,arrSizeVars,varOptArr),bucketSize=bucketSize),
         BackendDAE.EQUATION_ARRAY(size, neqns, arrSizeEqns, equOptArr),
         _,_,_,_)
      equation
        // update equationsarray
        eqnindxs = arrayCreate(neqns,-1);
        neqns1 = updateEquationArray(1,neqns,1,equOptArr,ass1,ass2,eqnindxs);
        // update variablearray
        varindxs = arrayCreate(nvars,-1);
        crefIdxLstArr = arrayCreate(bucketSize, {});
        nvars1 = updateVarArray(1,nvars,1,varOptArr,crefIdxLstArr,bucketSize,ass1,ass2,varindxs);
        // update strongComponents
        comps_1 = List.fold2(comps,updateStrongComponent,varindxs,eqnindxs,{});
        comps_1 = listReverse(comps_1);
        // generate updated data structs
        varArr = BackendDAE.VARIABLE_ARRAY(nvars1,arrSizeVars,varOptArr);
        vars = BackendDAE.VARIABLES(crefIdxLstArr, varArr, bucketSize, nvars1);
        eqns1 = BackendDAE.EQUATION_ARRAY(size, neqns1, arrSizeEqns, equOptArr);
      then
        BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),BackendDAE.MATCHING(ass1,ass2,comps_1),stateSets);
    else
      equation
        print("BackendDAEOptimize.updateEquationSystemMatching failed\n");
      then
        fail();
  end matchcontinue;
end updateEquationSystemMatching;

protected function updateStrongComponent
" function: updateStrongComponent
  author: Frenkel TUD 2012-09"
  input BackendDAE.StrongComponent iComp;
  input array<Integer> varindxs;
  input array<Integer> eqnindxs;
  input BackendDAE.StrongComponents iAcc;
  output BackendDAE.StrongComponents oComps;
algorithm
  oComps := matchcontinue(iComp,varindxs,eqnindxs,iAcc)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp;
      Integer v,e;
      list<Integer> vars,eqns;
      BackendDAE.JacobianType jacType;
      Boolean b;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v),_,_,_)
      equation
        e = eqnindxs[e];
        v = varindxs[v];
        comps = List.consOnTrue(intGt(e,0), BackendDAE.SINGLEEQUATION(e,v), iAcc);
      then
        comps;
    case (BackendDAE.EQUATIONSYSTEM(eqns=eqns,vars=vars,jacType=jacType),_,_,_)
      equation
        eqns = List.map1r(eqns,arrayGet,eqnindxs);
        eqns = List.select1(eqns,intGt,0);
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        e::_ = eqns;
        v::_ = vars;
        comp = Util.if_(intEq(listLength(eqns),1),BackendDAE.SINGLEEQUATION(e,v),BackendDAE.EQUATIONSYSTEM(eqns,vars,NONE(),jacType));
        comps = List.consOnTrue(intGt(listLength(eqns),0), comp, iAcc);
      then
        comps;
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=eqns,disc_vars=vars),_,_,_)
      equation
        comp::_ =updateStrongComponent(comp,varindxs,eqnindxs,{});
        eqns = List.map1r(eqns,arrayGet,eqnindxs);
        eqns = List.select1(eqns,intGt,0);
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        comp = Util.if_(intEq(listLength(eqns),0),comp,BackendDAE.MIXEDEQUATIONSYSTEM(comp,eqns,vars));
        comps = List.consOnTrue(intGt(listLength(eqns),0), comp, iAcc);
      then
        comps;
    case (BackendDAE.SINGLEIFEQUATION(eqn=e,vars=vars),_,_,_)
      equation
        e = eqnindxs[e];
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        comps = List.consOnTrue(intGt(e,0), BackendDAE.SINGLEIFEQUATION(e,vars), iAcc);
      then
        comps;
    case (BackendDAE.SINGLEARRAY(eqn=e,vars=vars),_,_,_)
      equation
        e = eqnindxs[e];
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        comps = List.consOnTrue(intGt(e,0), BackendDAE.SINGLEARRAY(e,vars), iAcc);
      then
        comps;
    case (BackendDAE.SINGLEALGORITHM(eqn=e,vars=vars),_,_,_)
      equation
        e = eqnindxs[e];
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        comps = List.consOnTrue(intGt(e,0), BackendDAE.SINGLEALGORITHM(e,vars), iAcc);
      then
        comps;
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e,vars=vars),_,_,_)
      equation
        e = eqnindxs[e];
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        comps = List.consOnTrue(intGt(e,0), BackendDAE.SINGLECOMPLEXEQUATION(e,vars), iAcc);
      then
        comps;
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e,vars=vars),_,_,_)
      equation
        e = eqnindxs[e];
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        comps = List.consOnTrue(intGt(e,0), BackendDAE.SINGLEWHENEQUATION(e,vars), iAcc);
      then
        comps;
    case (BackendDAE.TORNSYSTEM(tearingvars=vars,residualequations=eqns,otherEqnVarTpl=eqnvartpllst,linear=b),_,_,_)
      equation
        eqns = List.map1r(eqns,arrayGet,eqnindxs);
        eqns = List.select1(eqns,intGt,0);
        vars = List.map1r(vars,arrayGet,varindxs);
        vars = List.select1(vars,intGt,0);
        eqnvartpllst = updateTornSystemComp(eqnvartpllst,varindxs,eqnindxs,{});
        comp = BackendDAE.TORNSYSTEM(vars,eqns,eqnvartpllst,b);
      then
        comp::iAcc;
    case (_,_,_,_)
      equation
        print("BackendDAEOptimize.updateStrongComponent failed for Comp:\n");
        BackendDump.dumpComponent(iComp);
        print("Size EqnsIndx: " +& intString(arrayLength(eqnindxs)) +& "\n");
        print("Size VarsIndx: " +& intString(arrayLength(varindxs)) +& "\n");
      then
        fail();
  end matchcontinue;
end updateStrongComponent;

protected function updateEquationSystemComp
  input list<Integer> eqns;
  input list<Integer> vars;
  input BackendDAE.JacobianType jacType;
  input BackendDAE.StrongComponents iAcc;
  output BackendDAE.StrongComponents oComps;
algorithm
  oComps := match(eqns,vars,jacType,iAcc)
    local
      Integer e,v;
    case ({},{},_,_) then iAcc;
    case ({},v::_,_,_)
      //equation
      then
        fail();
    case (e::{},v::_,_,_)
      then
        BackendDAE.SINGLEEQUATION(e,v)::iAcc;
    case (_,_,_,_)
      then
        BackendDAE.EQUATIONSYSTEM(eqns,vars,NONE(),jacType)::iAcc;
  end match;
end updateEquationSystemComp;

protected function updateTornSystemComp
  input list<tuple<Integer,list<Integer>>> inEqnVarTplLst;
  input array<Integer> varindxs;
  input array<Integer> eqnindxs;
  input list<tuple<Integer,list<Integer>>> iAcc;
  output list<tuple<Integer,list<Integer>>> oAcc;
algorithm
  oAcc := match(inEqnVarTplLst,varindxs,eqnindxs,iAcc)
    local
      Integer e;
      list<Integer> vars;
      list<tuple<Integer,list<Integer>>> rest,acc;
    case({},_,_,_) then listReverse(iAcc);
    case((e,vars)::rest,_,_,_)
      equation
        e = eqnindxs[e];
        vars = List.map1r(vars,arrayGet,varindxs);
        acc = List.consOnTrue(intGt(e,0), (e,vars), iAcc);
      then
        updateTornSystemComp(rest,varindxs,eqnindxs,acc);
  end match;
end updateTornSystemComp;

protected function updateVarArray
" function: updateVarArray
  author: Frenkel TUD 2012-09"
  input Integer index;
  input Integer numberOfElement;
  input Integer insertindex;
  input array<Option<BackendDAE.Var>> varOptArr;
  input array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
  input Integer bucketSize;
  input array<Integer> ass1 "ass[varindx]=eqnindx";
  input array<Integer> ass2 "ass[eqnindx]=varindx";
  input array<Integer> newindexarr;
  output Integer newnumberOfElement;
algorithm
  newnumberOfElement := matchcontinue(index,numberOfElement,insertindex,varOptArr,crefIdxLstArr,bucketSize,ass1,ass2,newindexarr)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      Integer e,indx,i;
      list<BackendDAE.CrefIndex> indexes;
    // found element
    case(_,_,_,_,_,_,_,_,_)
      equation
        true = intLe(index,numberOfElement);
        SOME(var as BackendDAE.VAR(varName=cr)) = varOptArr[index];
        // insert on new pos
        _ = arrayUpdate(varOptArr,insertindex,SOME(var));
        // store new pos
        _ = arrayUpdate(newindexarr,index,insertindex);
        // add to hash vec
        indx = ComponentReference.hashComponentRefMod(cr, bucketSize);
        indexes = crefIdxLstArr[indx + 1];
        i = insertindex-1;
        _ = arrayUpdate(crefIdxLstArr, indx + 1, (BackendDAE.CREFINDEX(cr,i) :: indexes));
        // update assignments
        e = ass1[index];
        _ = arrayUpdate(ass1,insertindex,e);
        _ = arrayUpdate(ass2,e,insertindex);
      then
        updateVarArray(index+1,numberOfElement,insertindex+1,varOptArr,crefIdxLstArr,bucketSize,ass1,ass2,newindexarr);
    // found non element
    case(_,_,_,_,_,_,_,_,_)
      equation
        true = intLe(index,numberOfElement);
        NONE() = varOptArr[index];
      then
        updateVarArray(index+1,numberOfElement,insertindex,varOptArr,crefIdxLstArr,bucketSize,ass1,ass2,newindexarr);
    // at the end
    case(_,_,_,_,_,_,_,_,_)
      equation
        false = intLe(index,numberOfElement);
      then
        insertindex-1;
    else
      equation
        print("BackendDAEOptimize.updateVarArray failed\n");
      then
        fail();
  end matchcontinue;
end updateVarArray;

protected function updateEquationArray
" function: updateEquationArray
  author: Frenkel TUD 2012-09"
  input Integer index;
  input Integer numberOfElement;
  input Integer insertindex;
  input array<Option<BackendDAE.Equation>> equOptArr;
  input array<Integer> ass1 "ass[varindx]=eqnindx";
  input array<Integer> ass2 "ass[eqnindx]=varindx";
  input array<Integer> newindexarr;
  output Integer newnumberOfElement;
algorithm
  newnumberOfElement := matchcontinue(index,numberOfElement,insertindex,equOptArr,ass1,ass2,newindexarr)
    local
      BackendDAE.Equation eqn;
      Integer v;
    // found element
    case(_,_,_,_,_,_,_)
      equation
        true = intLe(index,numberOfElement);
        SOME(eqn) = equOptArr[index];
        // insert on new pos
        _ = arrayUpdate(equOptArr,insertindex,SOME(eqn));
        // store new pos
        _ = arrayUpdate(newindexarr,index,insertindex);
        // update assignments
        v = ass2[index];
        _ = arrayUpdate(ass2,insertindex,v);
        _ = arrayUpdate(ass1,v,insertindex);
      then
        updateEquationArray(index+1,numberOfElement,insertindex+1,equOptArr,ass1,ass2,newindexarr);
    // found non element
    case(_,_,_,_,_,_,_)
      equation
        true = intLe(index,numberOfElement);
        NONE() = equOptArr[index];
      then
        updateEquationArray(index+1,numberOfElement,insertindex,equOptArr,ass1,ass2,newindexarr);
    // at the end
    case(_,_,_,_,_,_,_)
      equation
        false = intLe(index,numberOfElement);
      then
        insertindex-1;
    else
      equation
        print("BackendDAEOptimize.updateEquationArray failed\n");
      then
        fail();
  end matchcontinue;
end updateEquationArray;

protected function traverseIncidenceMatrix
" function: traverseIncidenceMatrix
  author: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := traverseIncidenceMatrix1(inM,func,1,arrayLength(inM),inTypeA);
end traverseIncidenceMatrix;

protected function traverseIncidenceMatrix1
" function: traverseIncidenceMatrix1
  author: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := traverseIncidenceMatrix2(inM,func,pos,len,intGt(pos,len),inTypeA);
end traverseIncidenceMatrix1;

protected function traverseIncidenceMatrix2
" function: traverseIncidenceMatrix1
  author: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Boolean stop;
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  (outM,outTypeA) := match (inM,func,pos,len,stop,inTypeA)
    local
      BackendDAE.IncidenceMatrix m,m1,m2;
      Type_a extArg,extArg1,extArg2;
      list<Integer> eqns,eqns1;

    case(_,_,_,_,true,_)
    then (inM,inTypeA);

    case(_,_,_,_,false,_)
      equation
        ((eqns,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
        eqns1 = List.removeOnTrue(pos,intLt,eqns);
        (m1,extArg1) = traverseIncidenceMatrixList(eqns1,m,func,arrayLength(m),pos,extArg);
        (m2,extArg2) = traverseIncidenceMatrix1(m1,func,pos+1,len,extArg1);
      then (m2,extArg2);

  end match;
end traverseIncidenceMatrix2;

protected function traverseIncidenceMatrixList
" function: traverseIncidenceMatrixList
  author: Frenkel TUD 2011-04"
  replaceable type Type_a subtypeof Any;
  input list<Integer> inLst "elements to traverse";
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer len "length of array";
  input Integer maxpos "do not go further than this position";
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := matchcontinue(inLst,inM,func,len,maxpos,inTypeA)
    local
      BackendDAE.IncidenceMatrix m,m1;
      Type_a extArg,extArg1;
      list<Integer> rest,eqns,eqns1,alleqns;
      Integer pos;

    case({},_,_,_,_,_) then (inM,inTypeA);

    case(pos::rest,_,_,_,_,_) equation
      // do not leave the list
      true = intLt(pos,len+1);
      // do not more than necesary
      true = intLt(pos,maxpos);
      ((eqns,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
      eqns1 = List.removeOnTrue(maxpos,intLt,eqns);
      alleqns = List.unionOnTrueList({rest, eqns1},intEq);
      (m1,extArg1) = traverseIncidenceMatrixList(alleqns,m,func,len,maxpos,extArg);
    then (m1,extArg1);

    case(pos::rest,_,_,_,_,_) equation
      // do not leave the list
      true = intLt(pos,len+1);
      (m,extArg) = traverseIncidenceMatrixList(rest,inM,func,len,maxpos,inTypeA);
    then (m,extArg);

    case (_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAEOptimize.traverseIncidenceMatrixList failed");
      then
        fail();
  end matchcontinue;
end traverseIncidenceMatrixList;

protected function toplevelInputOrUnfixed
  input BackendDAE.Var inVar;
  output Boolean b;
algorithm
  b := BackendVariable.isVarOnTopLevelAndInput(inVar) or
       BackendVariable.isParam(inVar) and not BackendVariable.varFixed(inVar);
end toplevelInputOrUnfixed;

protected function traversingTimeEqnsFinder "function traversingTimeEqnsFinder
  author: Frenkel 2010-12"
  input tuple<DAE.Exp, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean> > inExp;
  output tuple<DAE.Exp, Boolean, tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean> > outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e;
      Boolean b,b1,b2;
      BackendDAE.Variables vars,knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<BackendDAE.Var> vlst;

    case((e as DAE.CREF(DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_), (_,vars,knvars,b1,b2)))
      then ((e,false,(true,vars,knvars,b1,b2)));
    // inputs not constant and parameter(fixed=false) are constant but evaluated after konstant variables are evaluted
    case((e as DAE.CREF(cr,_), (_,vars,knvars,b1,b2)))
      equation
        (vlst,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        false = List.mapAllValueBool(vlst,toplevelInputOrUnfixed,false);
      then ((e,false,(true,vars,knvars,b1,b2)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {_,_,_}), (_,vars,knvars,b1,b2))) then ((e,false,(true,vars,knvars,b1,b2)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {_}), (_,vars,knvars,b1,b2))) then ((e,false,(true,vars,knvars,b1,b2)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "change"), expLst = {_}), (_,vars,knvars,b1,b2))) then ((e,false,(true,vars,knvars,b1,b2)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "edge"), expLst = {_}), (_,vars,knvars,b1,b2))) then ((e,false,(true,vars,knvars,b1,b2)));
    // case for finding simple equation in jacobians
    // there are all known variables mark as input
    // and they are all time-depending
    case((e as DAE.CREF(cr,_), (_,vars,knvars,true,b2)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, knvars);
        DAE.INPUT() = BackendVariable.getVarDirection(var);
      then ((e,false,(true,vars,knvars,true,b2)));
    // unkown var
    case((e as DAE.CREF(cr,_), (_,vars,knvars,b1,true)))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, vars);
      then ((e,false,(true,vars,knvars,b1,true)));
    case((e,(b,vars,knvars,b1,b2))) then ((e,not b,(b,vars,knvars,b1,b2)));

  end matchcontinue;
end traversingTimeEqnsFinder;

public function countSimpleEquations
"function: countSimpleEquations
  author: Frenkel TUD 2011-05
  This function count the simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE. Note this functions does not use variable replacements, because
  of this the number of simple equations is maybe smaller than using variable replacements."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.IncidenceMatrix inM;
  output Integer outSimpleEqns;
algorithm
  outSimpleEqns:=
  match (inDlow,inM)
    local
      BackendDAE.BackendDAE dlow;
      BackendDAE.EquationArray eqns;
      Integer n;
    case (dlow,inM)
      equation
        // check equations
       (_,(_,n)) = traverseIncidenceMatrix(inM,countSimpleEquationsFinder,(dlow,0));
      then n;
  end match;
end countSimpleEquations;

protected function countSimpleEquationsFinder
"author: Frenkel TUD 2011-05"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,Integer>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,l,i,n,n_1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.BackendDAE dae;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case ((elem,pos,m,(dae as BackendDAE.DAE({syst},shared),n)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intLt(l,3);
        true = intGt(l,0);
        countsimpleEquation(elem,l,pos,syst,shared);
        n_1 = n+1;
      then (({},m,(dae,n_1)));
    case ((elem,pos,m,(dae,n)))
      then (({},m,(dae,n)));
  end matchcontinue;
end countSimpleEquationsFinder;

protected function countsimpleEquation
" function: countsimpleEquation
  author: Frenkel TUD 2011-05"
  input BackendDAE.IncidenceMatrixElement elem;
  input Integer length;
  input Integer pos;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
algorithm
  _ := matchcontinue(elem,length,pos,syst,shared)
    local
      DAE.ComponentRef cr;
      Integer i,j,pos_1;
      DAE.Exp es,cre,e1,e2;
      BackendDAE.Variables vars,knvars;
      BackendDAE.Var var;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      Boolean negate;
      DAE.ElementSource source;
    // a = const
    // wbraun:
    // speacial case for Jacobains, since there are all known variablen
    // time depending input variables
    case ({i},_,_,_,BackendDAE.SHARED(backendDAEType = BackendDAE.JACOBIAN()))
      equation
        vars = BackendVariable.daeVars(syst);
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (_,{}) = ExpressionSolve.solve(e1,e2,cre);
      then ();
    // a = const
    case ({i},_,_,_,_)
      equation
        vars = BackendVariable.daeVars(syst);
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        BackendDAE.EQUATION(exp=e1,scalar=e2,source=source) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        ((_,(false,_,_,_,_))) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (_,{}) = ExpressionSolve.solve(e1,e2,cre);
      then ();
    // a = der(b)
    case ({i,j},_,_,_,_)
      equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        eqn = BackendDAEUtil.equationNth(eqns,pos_1);
        (cr,_,_,_,_) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        vars = BackendVariable.daeVars(syst);
        ((_::_),(_::_)) = BackendVariable.getVar(cr,vars);
      then ();
    // a = b
    case ({i,j},_,_,_,_)
      equation
        pos_1 = pos-1;
        eqns = BackendEquation.daeEqns(syst);
        (eqn as BackendDAE.EQUATION(source=source)) = BackendDAEUtil.equationNth(eqns,pos_1);
        _ = BackendEquation.aliasEquation(eqn);
      then ();
  end matchcontinue;
end countsimpleEquation;

// =============================================================================
// remove parameters stuff
//
// =============================================================================
public function removeParameters
"function: removeParameters
  author wbraun"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (inDAE)
    local
      BackendDAE.Variables knvars,exobj,knvars1,av;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs)))
      equation
        repl = BackendVarTransform.emptyReplacements();
        ((repl1,_)) = BackendVariable.traverseBackendDAEVars(knvars,removeParametersFinder,(repl,knvars));
        (knvars1,repl2) = replaceFinalVars(1,knvars,repl1);
        (knvars1,repl2) = replaceFinalVars(1,knvars1,repl2);
        Debug.fcall(Flags.DUMP_PARAM_REPL, BackendVarTransform.dumpReplacements, repl2);
        systs= List.map1(systs,removeParameterswork,repl2);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars1,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end removeParameters;

protected function removeParameterswork
"function: removeParameterswork
  author wbraun"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (isyst,repl)
    local
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      list<BackendDAE.Equation> eqns_1,lsteqns;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching,stateSets),_)
      equation
        lsteqns = BackendEquation.equationList(eqns);
        (vars,_) = replaceFinalVars(1,vars,repl); // replacing variable attributes (e.g start) in unknown vars
        (eqns_1,_) = BackendVarTransform.replaceEquations(lsteqns, repl,NONE());
        eqns1 = BackendEquation.listEquation(eqns_1);
      then
        BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),matching,stateSets);
  end match;
end removeParameterswork;

protected function removeParametersFinder
"author: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp,exp1;
      Values.Value bindValue;
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),(repl,vars)))
      equation
        ((exp1, _)) = Expression.traverseExp(exp, BackendDAEUtil.replaceCrefsWithValues, (vars, varName));
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp1,NONE());
      then ((v,(repl_1,vars)));
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue),values=values),(repl,vars)))
      equation
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp,NONE());
      then ((v,(repl_1,vars)));
    case _ then inTpl;
  end matchcontinue;
end removeParametersFinder;

protected function replaceFinalVars
" function: replaceFinalVars
  author: Frenkel TUD 2011-04"
  input Integer inNumRepl;
  input BackendDAE.Variables inVars;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Variables outVars;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  (outVars,outRepl) := matchcontinue(inNumRepl,inVars,inRepl)
    local
      Integer numrepl;
      BackendDAE.Variables knvars,knvars1,knvars2;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;

    case(numrepl,knvars,repl)
      equation
      true = intEq(0,numrepl);
    then (knvars,repl);

    case(numrepl,knvars,repl)
      equation
      (knvars1,(repl1,numrepl)) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceFinalVarTraverser,(repl,0));
      (knvars2,repl2) = replaceFinalVars(numrepl,knvars1,repl1);
    then (knvars2,repl2);

  end matchcontinue;
end replaceFinalVars;


protected function replaceFinalVarTraverser
"author: Frenkel TUD 2011-04"
 input tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,Integer>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v,v1;
      BackendVarTransform.VariableReplacements repl,repl_1;
      Integer numrepl;
      DAE.Exp e,e1;
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> attr,new_attr;

    case ((v as BackendDAE.VAR(varName=cr,bindExp=SOME(e),values=attr),(repl,numrepl)))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        (e1,_) = ExpressionSimplify.simplify(e1);
        v1 = BackendVariable.setBindExp(v,e1);
        repl_1 = addConstExpReplacement(e1,cr,repl);
        (attr,repl_1) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,repl_1);
        v1 = BackendVariable.setVarAttributes(v1,attr);
      then ((v1,(repl_1,numrepl+1)));

    case  ((v as BackendDAE.VAR(values=attr),(repl,numrepl)))
      equation
        (new_attr,repl) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,repl);
        v1 = BackendVariable.setVarAttributes(v,new_attr);
      then ((v1,(repl,numrepl)));
  end matchcontinue;
end replaceFinalVarTraverser;

protected function addConstExpReplacement
  input DAE.Exp inExp;
  input DAE.ComponentRef cr;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  outRepl := matchcontinue(inExp,cr,inRepl)
    case (_,_,_)
      equation
        true = Expression.isConst(inExp);
      then
        BackendVarTransform.addReplacement(inRepl, cr, inExp,NONE());
    else
      inRepl;
  end matchcontinue;
end addConstExpReplacement;

protected function traverseExpVisitorWrapper "help function to replaceFinalVarTraverser"
  input tuple<DAE.Exp,BackendVarTransform.VariableReplacements> inTpl;
  output tuple<DAE.Exp,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local
    DAE.Exp exp;
    BackendVarTransform.VariableReplacements repl;
    DAE.ComponentRef cr;

    case((exp as DAE.CREF(cr,_),repl)) equation
      (exp,_) = BackendVarTransform.replaceExp(exp,repl,NONE());
    then ((exp,repl));

    case _ then inTpl;
  end matchcontinue;
end traverseExpVisitorWrapper;


// =============================================================================
// remove protected parameters stuff
//
// =============================================================================
public function removeProtectedParameters
"function: removeProtectedParameters
  author Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (inDAE)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,av;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl,repl1;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs)))
      equation
        repl = BackendVarTransform.emptyReplacements();
        repl1 = BackendVariable.traverseBackendDAEVars(knvars,protectedParametersFinder,repl);
        Debug.fcall(Flags.DUMP_PP_REPL, BackendVarTransform.dumpReplacements, repl1);
        systs = List.map1(systs,removeProtectedParameterswork,repl1);
      then
        (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs)));
  end match;
end removeProtectedParameters;

protected function removeProtectedParameterswork
"function: removeProtectedParameterswork
  author Frenkel TUD"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (isyst,repl)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      list<BackendDAE.Equation> eqns_1,lsteqns;
      Boolean b;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets),_)
      equation
        lsteqns = BackendEquation.equationList(eqns);
        (eqns_1,b) = BackendVarTransform.replaceEquations(lsteqns, repl,NONE());
        eqns1 = Debug.bcallret1(b, BackendEquation.listEquation,eqns_1,eqns);
        syst = Util.if_(b,BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets),isyst);
      then
        syst;
  end match;
end removeProtectedParameterswork;

protected function protectedParametersFinder
"author: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp;
      Values.Value bindValue;
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),repl))
      equation
        true = DAEUtil.getProtectedAttr(values);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp,NONE());
      then ((v,repl_1));
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue),values=values),repl))
      equation
        true = DAEUtil.getProtectedAttr(values);
        true = BackendVariable.varFixed(v);
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp,NONE());
      then ((v,repl_1));
    case _ then inTpl;
  end matchcontinue;
end protectedParametersFinder;


// =============================================================================
// remove equal function calls equations stuff
//
// =============================================================================
public function removeEqualFunctionCalls
"function: removeEqualFunctionCalls
  author: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem(dae,removeEqualFunctionCallsWork);
end removeEqualFunctionCalls;

protected function removeEqualFunctionCallsWork
"function: removeEqualFunctionCalls
  author: Frenkel TUD 2011-04
  This function detect equal function call on the form a=f(b) and c=f(b)
  in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := match (isyst,ishared)
    local
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      list<Integer> changed;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StateSets stateSets;
      DAE.FunctionTree funcs;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets),shared)
      equation
        funcs = BackendDAEUtil.getFunctions(shared);
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL(),SOME(funcs));
        // check equations
        (m_1,(mT_1,_,eqns1,changed)) = traverseIncidenceMatrix(m,removeEqualFunctionCallFinder,(mT,vars,eqns,{}));
        b = intGt(listLength(changed),0);
        // update arrayeqns and algorithms, collect info for wrappers
        syst = BackendDAE.EQSYSTEM(vars,eqns,SOME(m_1),SOME(mT_1),BackendDAE.NO_MATCHING(),stateSets);
        syst = BackendDAEUtil.updateIncidenceMatrix(syst,BackendDAE.NORMAL(),NONE(),changed);
      then (syst,shared);
  end match;
end removeEqualFunctionCallsWork;

protected function removeEqualFunctionCallFinder
"author: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,pos_1;
      BackendDAE.IncidenceMatrix m,mT;
      list<Integer> changed;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      DAE.Exp exp,e1,e2,ecr;
      list<Integer> expvars,controleqns,expvars1;
      list<list<Integer>> expvarseqns;

    case ((elem,pos,m,(mT,vars,eqns,changed)))
      equation
        // check number of vars in eqns
        _::_ = elem;
        pos_1 = pos-1;
        BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendDAEUtil.equationNth(eqns,pos_1);
        // BackendDump.debugStrExpStrExpStr(("Test ",e1," = ",e2,"\n"));
        (ecr,exp) = functionCallEqn(e1,e2,vars);
        // TODO: Handle this with alias-equations instead?; at least they don't replace back to the original expression...
        // failure(DAE.CREF(componentRef=_) = exp);
        // failure(DAE.UNARY(operator=DAE.UMINUS(ty=_),exp=DAE.CREF(componentRef=_)) = exp);
        // BackendDump.debugStrExpStrExpStr(("Found ",ecr," = ",exp,"\n"));
        expvars = BackendDAEUtil.incidenceRowExp(exp,vars,{},NONE(),BackendDAE.NORMAL());
        // print("expvars "); BackendDump.debuglst((expvars,intString," ","\n"));
        (expvars1::expvarseqns) = List.map1(expvars,varEqns,(pos,mT));
        // print("expvars1 "); BackendDump.debuglst((expvars1,intString," ","\n"));;
        controleqns = getControlEqns(expvars1,expvarseqns);
        // print("controleqns "); BackendDump.debuglst((controleqns,intString," ","\n"));
        (eqns1,changed) = removeEqualFunctionCall(controleqns,ecr,exp,eqns,changed);
        //print("changed1 "); BackendDump.debuglst((changed1,intString," ","\n"));
        //print("changed2 "); BackendDump.debuglst((changed2,intString," ","\n"));
        // print("Next\n");
      then (({},m,(mT,vars,eqns1,changed)));
    case ((elem,pos,m,(mT,vars,eqns,changed)))
      then (({},m,(mT,vars,eqns,changed)));
  end matchcontinue;
end removeEqualFunctionCallFinder;

protected function functionCallEqn
"function functionCallEqn
  author Frenkel TUD 2011-04"
  input DAE.Exp ie1;
  input DAE.Exp ie2;
  input BackendDAE.Variables inVars;
  output DAE.Exp outECr;
  output DAE.Exp outExp;
algorithm
  (outECr,outExp) := match (ie1,ie2,inVars)
      local
        DAE.ComponentRef cr;
        DAE.Exp e1,e2;
        DAE.Operator op;

      case (e1 as DAE.CREF(componentRef = cr),DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=DAE.CREF(componentRef = _)),_)
        then fail();
      case (e1 as DAE.CREF(componentRef = cr),DAE.CREF(componentRef = _),_)
        then fail();
      case (DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=e1 as DAE.CREF(componentRef = cr)),DAE.CREF(componentRef = _),_)
        then fail();
      // a = -f(...);
      case (e1 as DAE.CREF(componentRef = cr),DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=e2),_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (DAE.UNARY(op,e1),e2);
      // a = f(...);
      case (e1 as DAE.CREF(componentRef = cr),e2,_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (e1,e2);
      // a = -f(...);
      case (DAE.UNARY(operator=op as DAE.UMINUS(ty=_),exp=e1),e2 as DAE.CREF(componentRef = cr),_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (DAE.UNARY(op,e2),e1);
      // f(...)=a;
      case (e1,e2 as DAE.CREF(componentRef = cr),_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (e2,e1);
  end match;
end functionCallEqn;

protected function varEqns
"function varEqns
  author Frenkel TUD 2011-04"
  input Integer v;
  input tuple<Integer,BackendDAE.IncidenceMatrixT> inTpl;
  output list<Integer> outVarEqns;
protected
  Integer pos;
  list<Integer> vareqns,vareqns1;
  BackendDAE.IncidenceMatrix mT;
algorithm
  pos := Util.tuple21(inTpl);
  mT := Util.tuple22(inTpl);
  vareqns := mT[intAbs(v)];
  vareqns1 := List.map(vareqns, intAbs);
  outVarEqns := List.removeOnTrue(intAbs(pos),intEq,vareqns1);
end varEqns;

protected function getControlEqns
"function getControlEqns
  author Frenkel TUD 2011-04"
  input list<Integer> inVarsEqn;
  input list<list<Integer>> inVarsEqns;
  output list<Integer> outEqns;
algorithm
  outEqns := match(inVarsEqn,inVarsEqns)
    local
      list<Integer> a,b,c,d;
      list<list<Integer>> rest;
    case (a,{}) then a;
    case (a,b::rest)
      equation
       c = List.intersectionOnTrue(a,b,intEq);
       d = getControlEqns(c,rest);
      then d;
  end match;
end getControlEqns;

protected function removeEqualFunctionCall
"function removeEqualFunctionCall
  author: Frenkel TUD 2011-04"
  input list<Integer> inEqsLst;
  input DAE.Exp inExp;
  input DAE.Exp inECr;
  input BackendDAE.EquationArray inEqns;
  input list<Integer> ichanged;
  output BackendDAE.EquationArray outEqns;
  output list<Integer> outEqsLst;
algorithm
  (outEqns,outEqsLst):=
  matchcontinue (inEqsLst,inExp,inECr,inEqns,ichanged)
    local
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1,i;
      list<Integer> rest,changed;
    case ({},_,_,_,_) then (inEqns,ichanged);
    case (pos::rest,_,_,_,_)
      equation
        pos_1 = pos-1;
        eqn = BackendDAEUtil.equationNth(inEqns,pos_1);
        //BackendDump.printEquationList({eqn});
        //BackendDump.debugStrExpStrExpStr(("Repalce ",inExp," with ",inECr,"\n"));
        (eqn1,(_,_,i)) = BackendDAETransform.traverseBackendDAEExpsEqnWithSymbolicOperation(eqn, replaceExp, (inECr,inExp,0));
        //BackendDump.printEquationList({eqn1});
        //print("i="); print(intString(i)); print("\n");
        true = intGt(i,0);
        eqns =  BackendEquation.equationSetnth(inEqns,pos_1,eqn1);
        changed = List.consOnTrue(not listMember(pos,ichanged),pos,ichanged);
        (eqns,changed) = removeEqualFunctionCall(rest,inExp,inECr,eqns,changed);
      then (eqns,changed);
    case (pos::rest,_,_,_,_)
      equation
        (eqns,changed) = removeEqualFunctionCall(rest,inExp,inECr,inEqns,ichanged);
      then (eqns,changed);
  end matchcontinue;
end removeEqualFunctionCall;

public function replaceExp
"function: replaceExp
  author: Frenkel TUD"
  input tuple<DAE.Exp,tuple<list<DAE.SymbolicOperation>,tuple<DAE.Exp,DAE.Exp,Integer>>> inTpl;
  output tuple<DAE.Exp,tuple<list<DAE.SymbolicOperation>,tuple<DAE.Exp,DAE.Exp,Integer>>> outTpl;
protected
  DAE.Exp e,e1,se,te;
  Integer i,j;
  list<DAE.SymbolicOperation> ops;
algorithm
  (e,(ops,(se,te,i))) := inTpl;
  // BackendDump.debugStrExpStrExpStr(("Repalce ",se," with ",te,"\n"));
  ((e1,j)) := Expression.replaceExp(e,se,te);
  ops := Util.if_(j>0, DAE.SUBSTITUTION({e1},e)::ops, ops);
  // BackendDump.debugStrExpStrExpStr(("Old ",e," new ",e1,"\n"));
  outTpl := ((e1,(ops,(se,te,i+j))));
end replaceExp;

// =============================================================================
// remove unused parameter
//
// =============================================================================
public function removeUnusedParameter
"function: removeUnusedParameter
  author: Frenkel TUD 2011-04
  This function remove unused parameters
  in BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (inDlow)
    local
      BackendDAE.Variables knvars,exobj,knvars1,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;
    case (BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp,symjacs)))
      equation
        knvars1 = BackendVariable.emptyVars();
        ((knvars,knvars1)) = BackendVariable.traverseBackendDAEVars(knvars,copyNonParamVariables,(knvars,knvars1));
        ((_,knvars1)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(aliasVars,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedParameter,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedParameter,(knvars,knvars1));
        (_,(_,knvars1)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedParameter,(knvars,knvars1));
      then
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end removeUnusedParameter;

protected function copyNonParamVariables
"author: Frenkel TUD 2011-05"
 input tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
    case ((v as BackendDAE.VAR(varName = cr,varKind = BackendDAE.PARAM()),(vars,vars1)))
      then
        ((v,(vars,vars1)));
    case ((v as BackendDAE.VAR(varName = cr),(vars,vars1)))
      equation
        vars1 = BackendVariable.addVar(v,vars1);
      then
        ((v,(vars,vars1)));
  end matchcontinue;
end copyNonParamVariables;

protected function checkUnusedParameter
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case ((exp,(vars,vars1)))
      equation
         ((_,(_,vars1))) = Expression.traverseExp(exp,checkUnusedParameterExp,(vars,vars1));
       then
        ((exp,(vars,vars1)));
    case _ then inTpl;
  end matchcontinue;
end checkUnusedParameter;

protected function checkUnusedParameterExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;
      BackendDAE.Var var;

    // special case for time, it is never part of the equation system
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));

    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1)))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,vars1))) = Expression.traverseExpList(expl,checkUnusedParameterExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY(ty=_)),(vars,vars1)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,vars1))) = Expression.traverseExp(e1,checkUnusedParameterExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // case for functionpointers
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
      then
        ((e, (vars,vars1)));

    // already there
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (_,_) = BackendVariable.getVar(cr, vars1);
      then
        ((e, (vars,vars1)));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (var::_,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVar(var,vars1);
      then
        ((e, (vars,vars1)));

    case _ then inTuple;
  end matchcontinue;
end checkUnusedParameterExp;

// =============================================================================
// remove unused variables
//
// =============================================================================
public function removeUnusedVariables
"function: removeUnusedVariables
  author: Frenkel TUD 2011-04
  This function remove unused variables
  from BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (inDlow)
    local
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,knvars1,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;

    case (BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp,symjacs)))
      equation
        knvars1 = BackendVariable.emptyVars();
        ((_,knvars1)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsVars(aliasVars,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedVariables,(knvars,knvars1));
        ((_,knvars1)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedVariables,(knvars,knvars1));
        (_,(_,knvars1)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedVariables,(knvars,knvars1));
      then
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end removeUnusedVariables;

protected function checkUnusedVariables
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case ((exp,(vars,vars1)))
      equation
         ((_,(_,vars1))) = Expression.traverseExp(exp,checkUnusedVariablesExp,(vars,vars1));
       then
        ((exp,(vars,vars1)));
    case _ then inTpl;
  end matchcontinue;
end checkUnusedVariables;

protected function checkUnusedVariablesExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;
      BackendDAE.Var var;

    // special case for time, it is never part of the equation system
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));

    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1)))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,vars1))) = Expression.traverseExpList(expl,checkUnusedVariablesExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY(ty=_)),(vars,vars1)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,vars1))) = Expression.traverseExp(e1,checkUnusedVariablesExp,(vars,vars1));
      then
        ((e, (vars,vars1)));

    // case for functionpointers
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
      then
        ((e, (vars,vars1)));

    // already there
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (_,_) = BackendVariable.getVar(cr, vars1);
      then
        ((e, (vars,vars1)));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (var::_,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVar(var,vars1);
      then
        ((e, (vars,vars1)));

    case _ then inTuple;
  end matchcontinue;
end checkUnusedVariablesExp;

// =============================================================================
// remove unused functions
//
// =============================================================================
public function removeUnusedFunctions
"function: removeUnusedFunctions
  author: Frenkel TUD 2012-03
  This function remove unused functions
  from DAE.FunctionTree to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (inDlow)
    local
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs,usedfuncs;
      BackendDAE.Variables knvars,exobj,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenClauseLst;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;

    case (BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo as BackendDAE.EVENT_INFO(whenClauseLst=whenClauseLst),eoc,btp,symjacs)))
      equation
        usedfuncs = copyRecordConstructorAndExternalObjConstructorDestructor(funcs);
        ((_,usedfuncs)) = List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsVars(knvars,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsVars(exobj,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsVars(aliasVars,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns,checkUnusedFunctions,(funcs,usedfuncs));
        ((_,usedfuncs)) = BackendDAEUtil.traverseBackendDAEExpsEqns(inieqns,checkUnusedFunctions,(funcs,usedfuncs));
        (_,(_,usedfuncs)) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,checkUnusedFunctions,(funcs,usedfuncs));
        //traverse Symbolic jacobians
        ((funcs,usedfuncs)) = removeUnusedFunctionsSymJacs(symjacs,(funcs,usedfuncs));
      then
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,usedfuncs,einfo,eoc,btp,symjacs));
  end match;
end removeUnusedFunctions;

protected function copyRecordConstructorAndExternalObjConstructorDestructor
  input DAE.FunctionTree inFunctions;
  output DAE.FunctionTree outFunctions;
protected
  list<DAE.Function> funcelems;
algorithm
  funcelems := DAEUtil.getFunctionList(inFunctions);
  outFunctions := List.fold(funcelems,copyRecordConstructorAndExternalObjConstructorDestructorFold,DAEUtil.emptyFuncTree);
end copyRecordConstructorAndExternalObjConstructorDestructor;

protected function copyRecordConstructorAndExternalObjConstructorDestructorFold
  input DAE.Function inFunction;
  input DAE.FunctionTree inFunctions;
  output DAE.FunctionTree outFunctions;
algorithm
  outFunctions :=
  matchcontinue (inFunction,inFunctions)
    local
      DAE.Function f;
      DAE.FunctionTree funcs,funcs1;
      Absyn.Path path;
    // copy record constructors
    case (f as DAE.RECORD_CONSTRUCTOR(path=path),funcs)
      equation
         funcs1 = DAEUtil.avlTreeAdd(funcs, path, SOME(f));
       then
        funcs1;
    // copy external objects constructors/destructors
    case (f as DAE.FUNCTION(path = path),funcs)
      equation
         true = boolOr(
                  stringEq(Absyn.pathLastIdent(path), "constructor"),
                  stringEq(Absyn.pathLastIdent(path), "destructor"));
         funcs1 = DAEUtil.avlTreeAdd(funcs, path, SOME(f));
       then
        funcs1;
    case (f,funcs) then funcs;
  end matchcontinue;
end copyRecordConstructorAndExternalObjConstructorDestructorFold;

protected function removeUnusedFunctionsSymJacs
  input BackendDAE.SymbolicJacobians inSymJacs;
  input tuple<DAE.FunctionTree,DAE.FunctionTree> inFuncsTpl;
  output tuple<DAE.FunctionTree,DAE.FunctionTree> outFuncsTpl;
algorithm
  outFuncsTpl := match(inSymJacs,inFuncsTpl)
  local
    BackendDAE.BackendDAE bdae;
    BackendDAE.SymbolicJacobians rest;
    DAE.FunctionTree funcs, usedfuncs, usedfuncs2;
    list<tuple<DAE.AvlKey, DAE.AvlValue>> treelst;
    case ({},(funcs,usedfuncs)) then ((funcs,usedfuncs));
    case ((NONE(),_,_)::rest,(funcs,usedfuncs))
      then removeUnusedFunctionsSymJacs(rest,(funcs,usedfuncs));
    case ((SOME((bdae,_,_,_,_)),_,_)::rest,(funcs,usedfuncs))
      equation
         bdae = BackendDAEUtil.addBackendDAEFunctionTree(funcs,bdae);
         BackendDAE.DAE(shared=BackendDAE.SHARED(functionTree=usedfuncs2)) = removeUnusedFunctions(bdae);
         treelst = DAEUtil.avlTreeToList(usedfuncs2);
         usedfuncs = DAEUtil.avlTreeAddLst(treelst, usedfuncs);
      then removeUnusedFunctionsSymJacs(rest,(funcs,usedfuncs));
      //else then inFuncsTpl;
  end match;
end removeUnusedFunctionsSymJacs;

protected function checkUnusedFunctions
  input tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> inTpl;
  output tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local
      DAE.Exp exp;
      DAE.FunctionTree func,usefuncs,usefuncs1;
    case ((exp,(func,usefuncs)))
      equation
         ((_,(_,usefuncs1))) = Expression.traverseExp(exp,checkUnusedFunctionsExp,(func,usefuncs));
       then
        ((exp,(func,usefuncs1)));
    case _ then inTpl;
  end matchcontinue;
end checkUnusedFunctions;

protected function checkUnusedFunctionsExp
  input tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> inTuple;
  output tuple<DAE.Exp, tuple<DAE.FunctionTree,DAE.FunctionTree>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      DAE.FunctionTree func,usefuncs,usefuncs1,usefuncs2;
      Absyn.Path path;
      Option<DAE.Function> f;
      list<DAE.Element> body;

    // already there
    case ((e as DAE.CALL(path = path),(func,usefuncs)))
      equation
         _ = DAEUtil.avlTreeGet(usefuncs, path);
      then
        ((e, (func,usefuncs)));

    // add it
    case ((e as DAE.CALL(path = path),(func,usefuncs)))
      equation
         (f,body) = getFunctionAndBody(path,func);
         usefuncs1 = DAEUtil.avlTreeAdd(usefuncs, path, f);
         // print("add function " +& Absyn.pathStringNoQual(path) +& "\n");
         (_,(_,usefuncs2)) = DAEUtil.traverseDAE2(body,checkUnusedFunctions,(func,usefuncs1));
      then
        ((e, (func,usefuncs2)));

    // already there
    case ((e as DAE.PARTEVALFUNCTION(path = path),(func,usefuncs)))
      equation
         _ = DAEUtil.avlTreeGet(usefuncs, path);
      then
        ((e, (func,usefuncs)));

    // add it
    case ((e as DAE.PARTEVALFUNCTION(path = path),(func,usefuncs)))
      equation
         (f as SOME(_)) = DAEUtil.avlTreeGet(func, path);
         usefuncs1 = DAEUtil.avlTreeAdd(usefuncs, path, f);
         // print("add partial function " +& Absyn.pathStringNoQual(path) +& "\n");
      then
        ((e, (func,usefuncs1)));

    case _ then inTuple;
  end matchcontinue;
end checkUnusedFunctionsExp;

protected function getFunctionAndBody
"function: getFunctionBody
  returns the body of a function"
  input Absyn.Path inPath;
  input DAE.FunctionTree fns;
  output Option<DAE.Function> outFn;
  output list<DAE.Element> outFnBody;
algorithm
  (outFn,outFnBody) := matchcontinue(inPath,fns)
    local
      Absyn.Path p;
      Option<DAE.Function> fn;
      list<DAE.Element> body;
      DAE.FunctionTree ftree;
      String msg;
    // handle normal functions
    case(p,ftree)
      equation
        (fn as SOME(DAE.FUNCTION(functions = DAE.FUNCTION_DEF(body = body)::_))) = DAEUtil.avlTreeGet(ftree,p);
      then (fn,body);
    // adrpo: also the external functions!
    case(p,ftree)
      equation
        (fn as SOME(DAE.FUNCTION(functions = DAE.FUNCTION_EXT(body = body)::_))) = DAEUtil.avlTreeGet(ftree,p);
      then (fn,body);

    case(p,_)
      equation
        msg = "BackendDAEOptimize.getFunctionBody failed for function " +& Absyn.pathStringNoQual(p);
        // print(msg +& "\n");
        Debug.fprintln(Flags.FAILTRACE, msg);
        // Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end matchcontinue;
end getFunctionAndBody;

/*
 * constant jacobians. Linear system of equations (A x = b) where
 * A and b are constants.
 */

public function constantLinearSystem
"function constantLinearSystem"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,constantLinearSystem0,false);
end constantLinearSystem;

protected function constantLinearSystem0
"function constantLinearSystem"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) :=
    match(isyst,sharedChanged)
    local
      BackendDAE.StrongComponents comps;
      Boolean b,b1,b2;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
    case (syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),(shared, b1))
      equation
        (syst,shared,b2) = constantLinearSystem1(syst,shared,comps);
        syst = constantLinearSystem2(b2,syst);
        b = b1 or b2;
      then
        (syst,(shared,b));
  end match;
end constantLinearSystem0;

protected function constantLinearSystem2
"function constantLinearSystem"
  input Boolean b;
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match(b,isyst)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponents comps;
      array<Integer> ass1,ass2;
      BackendDAE.StateSets stateSets;
    case (false,_) then isyst;
//    case (true,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=BackendDAE.NO_MATCHING()))
    case (true,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets))
      equation
        // remove empty entries from vars/eqns
        vars = BackendVariable.listVar1(BackendVariable.varList(vars));
        eqns = BackendEquation.listEquation(BackendEquation.equationList(eqns));
      then
        BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets);
/*    case (true,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2,comps=comps)))
      then
        updateEquationSystemMatching(vars,eqns,ass1,ass2,comps);
*/  end match;
end constantLinearSystem2;

protected function constantLinearSystem1
"function constantLinearSystem1"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponents inComps;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
algorithm
  (osyst,oshared,outRunMatching):=
  matchcontinue (isyst,ishared,inComps)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp,comp1;
      Boolean b,b1;
      list<BackendDAE.Equation> eqn_lst;
      list<BackendDAE.Var> var_lst;
      list<Integer> eindex,vindx;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;

    case (syst,shared,{})
      then (syst,shared,false);
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),shared,(comp as BackendDAE.EQUATIONSYSTEM(eqns=eindex,vars=vindx,jac=SOME(jac),jacType=BackendDAE.JAC_CONSTANT()))::comps)
      equation
        eqn_lst = BackendEquation.getEqns(eindex,eqns);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        (syst,shared) = solveLinearSystem(syst,shared,eqn_lst,eindex,var_lst,vindx,jac);
        (syst,shared,b) = constantLinearSystem1(syst,shared,comps);
      then
        (syst,shared,true);
    case (syst,shared,(comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1))::comps)
      equation
        (syst,shared,b) = constantLinearSystem1(syst,shared,{comp1});
        (syst,shared,b1) = constantLinearSystem1(syst,shared,comps);
      then
        (syst,shared,b1 or b);
    case (syst,shared,comp::comps)
      equation
        (syst,shared,b) = constantLinearSystem1(syst,shared,comps);
      then
        (syst,shared,b);
  end matchcontinue;
end constantLinearSystem1;

protected function solveLinearSystem
"function constantLinearSystem1"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared ishared;
  input list<BackendDAE.Equation> eqn_lst;
  input list<Integer> eqn_indxs;
  input list<BackendDAE.Var> var_lst;
  input list<Integer> var_indxs;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared):=
  match (syst,ishared,eqn_lst,eqn_indxs,var_lst,var_indxs,jac)
    local
      BackendDAE.Variables vars,vars1,v;
      BackendDAE.EquationArray eqns,eqns1;
      list<DAE.Exp> beqs;
      list<DAE.ElementSource> sources;
      list<Real> rhsVals,solvedVals;
      list<list<Real>> jacVals;
      Integer linInfo;
      list<DAE.ComponentRef> names;
      BackendDAE.Matching matching;
      DAE.FunctionTree funcs;
      BackendDAE.Shared shared;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching,stateSets=stateSets),BackendDAE.SHARED(functionTree=funcs),_,_,_,_,_)
      equation
        eqns1 = BackendEquation.listEquation(eqn_lst);
        v = BackendVariable.listVar1(var_lst);
        (beqs,sources) = BackendDAEUtil.getEqnSysRhs(eqns1,v,SOME(funcs));
        beqs = listReverse(beqs);
        rhsVals = ValuesUtil.valueReals(List.map(beqs,Ceval.cevalSimple));
        jacVals = evaluateConstantJacobian(listLength(var_lst),jac);
        (solvedVals,linInfo) = System.dgesv(jacVals,rhsVals);
        names = List.map(var_lst,BackendVariable.varCref);
        checkLinearSystem(linInfo,names,jacVals,rhsVals,eqn_lst);
        sources = List.map1(sources, DAEUtil.addSymbolicTransformation, DAE.LINEAR_SOLVED(names,jacVals,rhsVals,solvedVals));
        (vars1,shared) = changeconstantLinearSystemVars(var_lst,solvedVals,sources,var_indxs,vars,ishared);
        eqns = List.fold(eqn_indxs,BackendEquation.equationRemove,eqns);
      then
        (BackendDAE.EQSYSTEM(vars1,eqns,NONE(),NONE(),matching,stateSets),shared);
  end match;
end solveLinearSystem;

protected function changeconstantLinearSystemVars
  input list<BackendDAE.Var> inVarLst;
  input list<Real> inSolvedVals;
  input list<DAE.ElementSource> inSources;
  input list<Integer> var_indxs;
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared ishared;
  output BackendDAE.Variables outVars;
  output BackendDAE.Shared oshared;
algorithm
    (outVars,oshared) := match (inVarLst,inSolvedVals,inSources,var_indxs,inVars,ishared)
    local
      BackendDAE.Var v,v1;
      list<BackendDAE.Var> varlst;
      DAE.ElementSource s;
      list<DAE.ElementSource> slst;
      BackendDAE.Variables vars,vars1,vars2;
      Real r;
      list<Real> rlst;
      BackendDAE.Shared shared;
      Integer indx;
      list<Integer> vindxs;
    case ({},{},{},_,vars,_) then (vars,ishared);
    case (v::varlst,r::rlst,s::slst,indx::vindxs,vars,_)
      equation
        v1 = BackendVariable.setBindExp(v,DAE.RCONST(r));
        v1 = BackendVariable.setVarStartValue(v1,DAE.RCONST(r));
        // ToDo: merge source of var and equation
        (vars1,_) = BackendVariable.removeVar(indx, vars);
        shared = BackendVariable.addKnVarDAE(v1,ishared);
        (vars2,shared) = changeconstantLinearSystemVars(varlst,rlst,slst,vindxs,vars1,shared);
      then (vars2,shared);
  end match;
end changeconstantLinearSystemVars;

public function evaluateConstantJacobian
  "Evaluate a constant jacobian so we can solve a linear system during runtime"
  input Integer size;
  input list<tuple<Integer,Integer,BackendDAE.Equation>> jac;
  output list<list<Real>> vals;
protected
  array<array<Real>> valarr;
  array<Real> tmp;
  list<array<Real>> tmp2;
  list<Real> rs;
algorithm
  rs := List.fill(0.0,size);
  tmp := listArray(rs);
  tmp2 := List.map(List.fill(tmp,size),arrayCopy);
  valarr := listArray(tmp2);
  List.map1_0(jac,evaluateConstantJacobian2,valarr);
  tmp2 := arrayList(valarr);
  vals := List.map(tmp2,arrayList);
end evaluateConstantJacobian;

protected function evaluateConstantJacobian2
  input tuple<Integer,Integer,BackendDAE.Equation> jac;
  input array<array<Real>> vals;
algorithm
  _ := match (jac,vals)
    local
      DAE.Exp exp;
      Integer i1,i2;
      Real r;
    case ((i1,i2,BackendDAE.RESIDUAL_EQUATION(exp=exp)),_)
      equation
        Values.REAL(r) = Ceval.cevalSimple(exp);
        _ = arrayUpdate(arrayGet(vals,i1),i2,r);
      then ();
  end match;
end evaluateConstantJacobian2;

protected function checkLinearSystem
  input Integer info;
  input list<DAE.ComponentRef> vars;
  input list<list<Real>> jac;
  input list<Real> rhs;
  input list<BackendDAE.Equation> eqnlst;
algorithm
  _ := matchcontinue (info,vars,jac,rhs,eqnlst)
    local
      String infoStr,syst,varnames,varname,rhsStr,jacStr,eqnstr;
    case (0,_,_,_,_) then ();
    case (_,_,_,_,_)
      equation
        true = info > 0;
        varname = ComponentReference.printComponentRefStr(listGet(vars,info));
        infoStr = intString(info);
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ;\n  ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ;\n  ");
        eqnstr = BackendDump.dumpEqnsStr(eqnlst);
        syst = stringAppendList({"\n",eqnstr,"\n[\n  ", jacStr, "\n]\n  *\n[\n  ",varnames,"\n]\n  =\n[\n  ",rhsStr,"\n]"});
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
      then fail();
    case (_,_,_,_,_)
      equation
        true = info < 0;
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ; ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ; ");
        eqnstr = BackendDump.dumpEqnsStr(eqnlst);
        syst = stringAppendList({eqnstr,"\n[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
      then fail();
  end matchcontinue;
end checkLinearSystem;

// =============================================================================
// Generate sparse pattern
//
// =============================================================================
 public function detectSparsePatternODE
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.BackendDAE DAE;
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.SparseColoring coloredCols;
  BackendDAE.SparsePattern sparsePattern;
  list<BackendDAE.Var> states;
  BackendDAE.Var dummyVar;
  BackendDAE.Variables v;
algorithm
  BackendDAE.DAE(eqs = eqs) := inBackendDAE;
  // prepare a DAE
  DAE := BackendDAEUtil.copyBackendDAE(inBackendDAE);
  DAE := BackendDAEUtil.addDummyStateIfNeeded(DAE);
  DAE := collapseIndependentBlocks(DAE);
  DAE := BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());

  //get states for DAE
  BackendDAE.DAE(eqs = {BackendDAE.EQSYSTEM(orderedVars = v)}, shared=shared) := DAE;
  states := BackendVariable.getAllStateVarFromVariables(v);
  // generate sparse pattern
  (sparsePattern, coloredCols) := generateSparsePattern(DAE, states, states);
  shared := BackendDAEUtil.addBackendDAESharedJacobianSparsePattern(sparsePattern, coloredCols, BackendDAE.SymbolicJacobianAIndex, shared);

  outBackendDAE := BackendDAE.DAE(eqs,shared);
end detectSparsePatternODE;

public function generateSparsePattern
"
function: generateSparsePattern
  Function generated for a given set of variables and
  equations the sparsity pattern and a coloring of d jacobian matrix A^(NxM).
  col: N = size(diffVars)
  rows : M = size(diffedVars)
  The sparsity pattern is represented basically as a list of lists, every list
  represents the non-zero elements of a row.

  The coloring is saved as a list of lists, every list contains the
  cols with the same color.

Author: wbraun
"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inDiffVars;    // "vars"
  input list<BackendDAE.Var> inDiffedVars;  // "eqns"
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outColoredCols;
algorithm
  (outSparsePattern,outColoredCols) := matchcontinue(inBackendDAE,inDiffVars,inDiffedVars)
    local
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst, syst1;
      BackendDAE.StrongComponents comps;
      BackendDAE.IncidenceMatrix adjMatrix, adjMatrixT;
      BackendDAE.Matching bdaeMatching;

      list<tuple<Integer, list<Integer>>>  sparseGraph, sparseGraphT;
      array<tuple<Integer, list<Integer>>> arraysparseGraph;

      Integer sizeN, adjSize, adjSizeT;
      Integer nonZeroElements, maxColor;
      list<Integer> nodesList, nodesEqnsIndex;
      list<list<Integer>> sparsepattern,sparsepatternT, coloredlist;
      list<BackendDAE.Var> jacDiffVars, indiffVars, indiffedVars;
      BackendDAE.Variables diffedVars, diffVars, varswithDiffs;
      BackendDAE.EquationArray orderedEqns;
      array<Option<list<Integer>>> forbiddenColor;
      array<Integer> colored, colored1, ass1, ass2;
      array<list<Integer>> coloredArray;
      list<Integer> varsIndexes;

      list<DAE.ComponentRef> diffCompRefs, diffedCompRefs;

      array<list<Integer>> eqnSparse, varSparse, sparseArray, sparseArrayT;
      array<Integer> mark, usedvar;

      BackendDAE.SparseColoring coloring;
      list<list<DAE.ComponentRef>> translated;
      list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsetuple;

    case (_,{},_) then (({},({},{})),{});
    case (_,_,{}) then (({},({},{})),{});
    case(BackendDAE.DAE(eqs = (syst as BackendDAE.EQSYSTEM(matching=bdaeMatching as BackendDAE.MATCHING(comps=comps, ass1=ass1, ass2=ass2)))::{}, shared=shared),indiffVars,indiffedVars)
      equation
        Debug.fcall(Flags.JAC_DUMP,print," start getting sparsity pattern diff Vars : " +& intString(listLength(indiffedVars))  +& " diffed vars: " +& intString(listLength(indiffVars)) +&"\n");
        // prepare crefs
        diffCompRefs = List.map(indiffVars, BackendVariable.varCref);
        diffedCompRefs = List.map(indiffedVars, BackendVariable.varCref);
        // create jacobian vars
        jacDiffVars =  List.map(indiffVars,BackendVariable.createpDerVar);
        sizeN = listLength(jacDiffVars);

        // generate adjacency matrix including diff vars
        (syst1 as BackendDAE.EQSYSTEM(orderedVars=varswithDiffs,orderedEqs=orderedEqns)) = BackendDAEUtil.addVarsToEqSystem(syst,jacDiffVars);
        (adjMatrix, adjMatrixT) = BackendDAEUtil.incidenceMatrix(syst1,BackendDAE.SPARSE(),NONE());
        adjSize = arrayLength(adjMatrix) "number of equations";
        adjSizeT = arrayLength(adjMatrixT) "number of variables";

        // Debug dumping
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.printVarList,BackendVariable.varList(varswithDiffs));
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.printEquationList,BackendEquation.equationList(orderedEqns));
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpIncidenceMatrix,adjMatrix);
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpIncidenceMatrixT,adjMatrixT);
        Debug.fcall(Flags.JAC_DUMP2, BackendDump.dumpFullMatching, bdaeMatching);

        // get indexes of diffed vars (rows)
        diffedVars = BackendVariable.listVar1(indiffedVars);
        nodesEqnsIndex = BackendVariable.getVarIndexFromVariables(diffedVars,varswithDiffs);
        nodesEqnsIndex = List.map1(nodesEqnsIndex, Util.arrayGetIndexFirst, ass1);

        // debug dump
        Debug.fcall(Flags.JAC_DUMP2, print, "nodesEqnsIndexs: ");
        Debug.fcall(Flags.JAC_DUMP2, BackendDump.dumpIncidenceRow, nodesEqnsIndex);
        Debug.fcall(Flags.JAC_DUMP2, print, "\n");
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> build sparse graph: " +& realString(clock()) +& "\n");

        // prepare data for getSparsePattern
        eqnSparse = arrayCreate(adjSizeT, {});
        varSparse = arrayCreate(adjSizeT, {});
        mark = arrayCreate(adjSizeT, 0);
        usedvar = arrayCreate(adjSizeT, 0);
        usedvar = Util.arraySet(adjSizeT-(sizeN-1), adjSizeT, usedvar, 1);

        //Debug.execStat("generateSparsePattern -> start ",CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        eqnSparse = getSparsePattern(comps, eqnSparse, varSparse, mark, usedvar, 1, adjMatrix, adjMatrixT);
        //Debug.execStat("generateSparsePattern -> end ",CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        // debug dump
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpSparsePatternArray,eqnSparse);
        Debug.fcall(Flags.JAC_DUMP,print, "analytical Jacobians[SPARSE] -> prepared arrayList for transpose list: " +& realString(clock()) +& "\n");

        // select nodesEqnsIndex and map index to incoming vars
        sparseArray = Util.arraySelect(eqnSparse, nodesEqnsIndex);
        sparsepattern = arrayList(sparseArray);
        sparsepattern = List.map1List(sparsepattern, intSub, adjSizeT-sizeN);

        //Debug.execStat("generateSparsePattern -> postProcess ",CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);

        // transpose the column-based pattern to row-based pattern
        sparseArrayT = arrayCreate(sizeN,{});
        sparseArrayT = transposeSparsePattern(sparsepattern, sparseArrayT, 1);
        sparsepatternT = arrayList(sparseArrayT);
        Debug.execStat("generateSparsePattern -> postProcess2 " ,CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);

        // dump statistics
        nonZeroElements = List.lengthListElements(sparsepattern);
        dumpSparsePatternStatistics(Flags.isSet(Flags.JAC_DUMP),nonZeroElements,sparsepatternT);
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpSparsePattern,sparsepattern);
        Debug.fcall(Flags.JAC_DUMP2,BackendDump.dumpSparsePattern,sparsepatternT);
        //Debug.execStat("generateSparsePattern -> nonZeroElements: " +& intString(nonZeroElements) +& " " ,CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);

        // translated to DAE.ComRefs
        translated = List.mapList1_1(sparsepatternT, List.getIndexFirst, diffedCompRefs);
        sparsetuple = List.threadTuple(diffCompRefs, translated);

        // build up a bi-partied graph of pattern
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> build sparse graph.\n");
        sparseArray = listArray(sparsepattern);
        nodesList = List.intRange2(1,adjSize);
        sparseGraph = Graph.buildGraph(nodesList,createBipartiteGraph,sparseArray);
        sparseGraphT = Graph.buildGraph(List.intRange2(1,sizeN),createBipartiteGraph,sparseArrayT);

        // debug dump
        Debug.fcall(Flags.JAC_DUMP2,print,"sparse graph: \n");
        Debug.fcall(Flags.JAC_DUMP2,Graph.printGraphInt,sparseGraph);
        Debug.fcall(Flags.JAC_DUMP2,print,"transposed sparse graph: \n");
        Debug.fcall(Flags.JAC_DUMP2,Graph.printGraphInt,sparseGraphT);
        Debug.fcall(Flags.JAC_DUMP,print,"analytical Jacobians[SPARSE] -> builded graph for coloring.\n");

        // color sparse bipartite graph
        forbiddenColor = arrayCreate(sizeN,NONE());
        colored = arrayCreate(sizeN,0);
        arraysparseGraph = listArray(sparseGraph);
        //Debug.execStat("generateSparsePattern -> coloring start " ,CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        colored1 = Graph.partialDistance2colorInt(sparseGraphT, forbiddenColor, nodesList, arraysparseGraph, colored);
        //Debug.execStat("generateSparsePattern -> coloring end " ,CevalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        // get max color used
        maxColor = Util.arrayFold(colored1, intMax, 0);

        // map index of that array into colors
        coloredArray = arrayCreate(maxColor, {});
        coloredlist = arrayList(mapIndexColors(colored1, listLength(diffCompRefs), coloredArray));

        Debug.fcall(Flags.JAC_DUMP2, print, "Print Coloring Cols: \n");
        Debug.fcall(Flags.JAC_DUMP2, BackendDump.dumpSparsePattern, coloredlist);

        coloring = List.mapList1_1(coloredlist, List.getIndexFirst, diffCompRefs);

        //without coloring
        //coloring = List.transposeList({diffCompRefs});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians[SPARSE] -> ready! " +& realString(clock()) +& "\n");
      then ((sparsetuple, (diffCompRefs, diffedCompRefs)), coloring);
        else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSparsePattern failed"});
      then fail();
  end matchcontinue;
end generateSparsePattern;

protected function dumpSparsePatternStatistics
  input Boolean dump;
  input Integer nonZeroElements;
  input list<list<Integer>> sparsepatternT;
algorithm
  _ := match(dump,nonZeroElements,sparsepatternT)
    local
      Integer maxdegree;
      list<Integer> alldegrees;
    // dump statistics
    case (true,_,_)
      equation
        (alldegrees, maxdegree) = List.mapFold(sparsepatternT, findDegrees, 1);
        print("analytical Jacobians[SPARSE] -> got sparse pattern nonZeroElements: "+& intString(nonZeroElements) +& " maxNodeDegree: " +& intString(maxdegree) +& " time : " +& realString(clock()) +& "\n");
      then ();
    else then ();
  end match;
end dumpSparsePatternStatistics;

protected function getSparsePattern
  input BackendDAE.StrongComponents inComponents;
  input array<list<Integer>> ineqnSparse; //
  input array<list<Integer>> invarSparse; //
  input array<Integer> inMark; //
  input array<Integer> inUsed; //
  input Integer inmarkValue;
  input BackendDAE.IncidenceMatrix inMatrix;
  input BackendDAE.IncidenceMatrix inMatrixT;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := matchcontinue(inComponents, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue, inMatrix, inMatrixT)
  local
    list<Integer> vars, vars1, vars2, eqns, eqns1,  eqns2;
    list<Integer> inputVars;
    list<list<Integer>> inputVarsLst;
    list<Integer> solvedVars;
    array<list<Integer>> result;
    Integer var, eqn;
    BackendDAE.StrongComponents rest;
    BackendDAE.StrongComponent comp;
    list<tuple<Integer,list<Integer>>> otherEqnVarTpl;
    case ({}, result,_,_,_,_,_,_) then result;

    case(BackendDAE.SINGLEEQUATION(eqn=eqn,var=var)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.removeOnTrue(var, intEq, inputVars);

        getSparsePattern2(inputVars, {var}, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEARRAY(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEIFEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrixT, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEALGORITHM(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEWHENEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEIFEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.EQUATIONSYSTEM(eqns=eqns,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVarsLst = List.map1(eqns, Util.arrayGetIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.TORNSYSTEM(residualequations=eqns,tearingvars=vars,otherEqnVarTpl=otherEqnVarTpl)::rest,result,_,_,_,_,_,_)
      equation
        inputVarsLst = List.map(otherEqnVarTpl,Util.tuple22);
        vars1 = List.flatten(inputVarsLst);
        eqns1 = List.map(otherEqnVarTpl,Util.tuple21);
        eqns = listAppend(eqns, eqns1);
        solvedVars = listAppend(vars, vars1);

        inputVarsLst = List.map1(eqns, Util.arrayGetIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.EQUATIONSYSTEM(eqns=eqns1,vars=vars1), disc_eqns=eqns,disc_vars=vars)::rest,result,_,_,_,_,_,_)
      equation
        eqns = listAppend(eqns, eqns1);
        solvedVars = listAppend(vars, vars1);
        inputVarsLst = List.map1(eqns, Util.arrayGetIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.TORNSYSTEM(residualequations=eqns1,tearingvars=vars1,otherEqnVarTpl=otherEqnVarTpl), disc_eqns=eqns,disc_vars=vars)::rest,result,_,_,_,_,_,_)
      equation
        inputVarsLst = List.map(otherEqnVarTpl,Util.tuple22);
        vars2 = List.flatten(inputVarsLst);
        eqns2 = List.map(otherEqnVarTpl,Util.tuple21);
        eqns1 = listAppend(eqns1, eqns2);
        vars1 = listAppend(vars1, vars2);
        eqns = listAppend(eqns, eqns1);
        solvedVars = listAppend(vars, vars1);

        inputVarsLst = List.map1(eqns, Util.arrayGetIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    else
       equation
         (comp::rest) = inComponents;
         BackendDump.dumpComponent(comp);
         Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.getSparsePattern failed"});
       then fail();
  end matchcontinue;
end getSparsePattern;

protected function getSparsePattern2
  input list<Integer> inInputVars;
  input list<Integer> inSolvedVars;
  input list<Integer> inEqns;
  input array<list<Integer>> ineqnSparse;
  input array<list<Integer>> invarSparse;
  input array<Integer> inMark;
  input array<Integer> inUsed;
  input Integer inmarkValue;
protected
  list<Integer> localList;
algorithm
  localList := getSparsePatternHelp(inInputVars, invarSparse, inMark, inUsed, inmarkValue, {});
  List.map2_0(inSolvedVars, Util.arrayUpdateIndexFirst, localList, invarSparse);
  List.map2_0(inEqns, Util.arrayUpdateIndexFirst, localList, ineqnSparse);
end getSparsePattern2;

protected function getSparsePatternHelp
  input list<Integer> inInputVars;
  input array<list<Integer>> invarSparse;
  input array<Integer> inMark;
  input array<Integer> inUsed;
  input Integer inmarkValue;
  input list<Integer> inLocalList;
  output list<Integer> outLocalList;
algorithm
  outLocalList := matchcontinue(inInputVars, invarSparse, inMark, inUsed, inmarkValue, inLocalList)
  local
    list<Integer> localList, varSparse, rest;
    Integer arrayElement, var;
    case ({},_,_,_,_,_) then inLocalList;
    case (var::rest,_,_,_,_,_)
      equation
        arrayElement = arrayGet(inUsed, var);
        false = intEq(1, arrayElement);

        varSparse = arrayGet(invarSparse, var);
        localList = List.fold2(varSparse, getSparsePatternHelp2, inMark, inmarkValue, inLocalList);
        localList =  getSparsePatternHelp(rest, invarSparse, inMark, inUsed, inmarkValue, localList);
      then localList;
    case (var::rest,_,_,_,_,_)
      equation
        arrayElement = arrayGet(inUsed, var);
        true = intEq(1, arrayElement);
        localList = getSparsePatternHelp2(var, inMark, inmarkValue, inLocalList);

        varSparse = arrayGet(invarSparse, var);
        localList = List.fold2(varSparse, getSparsePatternHelp2, inMark, inmarkValue, localList);
        localList =  getSparsePatternHelp(rest, invarSparse, inMark, inUsed, inmarkValue, localList);
      then localList;
  end matchcontinue;
end getSparsePatternHelp;

protected function getSparsePatternHelp2
  input Integer inInputVar; //
  input array<Integer> inMark; //
  input Integer inmarkValue;
  input list<Integer> inLocalList; //
  output list<Integer> outLocalList; //
algorithm
  outLocalList := matchcontinue(inInputVar, inMark, inmarkValue, inLocalList)
    local
      Integer arrayElement;
    case (_,_,_,_)
      equation
        arrayElement = arrayGet(inMark, inInputVar);
        false  = intEq(inmarkValue, arrayElement);
        _ = arrayUpdate(inMark, inInputVar, inmarkValue);
      then inInputVar::inLocalList;
   else
      then inLocalList;
  end matchcontinue;
end getSparsePatternHelp2;

public function findDegrees
  input list<ElementType> inList;
  input Integer inValue;
  output Integer outDegree;
  output Integer outMaxDegree;
replaceable type ElementType subtypeof Any;
algorithm
  outDegree := listLength(inList);
  outMaxDegree := intMax(inValue,outDegree);
end findDegrees;

protected function transposeSparsePattern
  input list<list<Integer>> inSparsePattern;
  input array<list<Integer>> inAccumList;
  input Integer inValue;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := match(inSparsePattern, inAccumList, inValue)
  local
    list<Integer> oneElem;
    list<list<Integer>> rest;
    array<list<Integer>>  accumList;
    case ({},_,_) then inAccumList;
    case (oneElem::rest, _, _)
      equation
        accumList = transposeSparsePattern2(oneElem, inAccumList, inValue);
       then transposeSparsePattern(rest, accumList, inValue+1);
  end match;
end transposeSparsePattern;

protected function transposeSparsePattern2
  input list<Integer> inSparsePatternElem;
  input array<list<Integer>> inAccumList;
  input Integer inValue;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := match(inSparsePatternElem, inAccumList, inValue)
  local
    Integer oneElem;
    list<Integer> rest, tmplist;
    array<list<Integer>>  accumList;
    case ({},_,_) then inAccumList;
    case (oneElem::rest,_, _)
      equation
        tmplist = arrayGet(inAccumList,oneElem);
        accumList = arrayUpdate(inAccumList, oneElem, inValue::tmplist);
       then transposeSparsePattern2(rest, accumList, inValue);
  end match;
end transposeSparsePattern2;

protected function mapIndexColors
  input array<Integer> inColors;
  input Integer inMaxIndex;
  input array<list<Integer>> inArray;
  output array<list<Integer>> outColors;
algorithm
  outColors := matchcontinue(inColors, inMaxIndex, inArray)
    local
      Integer i, index;
      list<Integer> lst;
    case (_, 0, _) then inArray;
    case (_, i, _)
      equation
        index = arrayGet(inColors, i);
        lst = arrayGet(inArray, index);
        lst = listAppend({i},lst);
        _ = arrayUpdate(inArray, index, lst);
      then
        mapIndexColors(inColors, i-1, inArray);
   else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSparsePattern: mapIndexColors failed"});
      then
         fail();
 end matchcontinue;
end mapIndexColors;

protected function createBipartiteGraph
  input Integer inNode;
  input array<list<Integer>> inSparsePattern;
  output list<Integer> outEdges;
algorithm
  outEdges := matchcontinue(inNode,inSparsePattern)
    case(_, _)
      equation
        outEdges = arrayGet(inSparsePattern,inNode);
    then outEdges;
    case(_, _)
      then {};
  end matchcontinue;
end createBipartiteGraph;


// =============================================================================
// initialization stuff
//
// =============================================================================
public function collectInitialEquations "function collectInitialEquations
  author: lochel
  This function collects all initial equations in the following order:
    - initial equations
    - implicit initial equations
    - initial algorithms"
  input BackendDAE.BackendDAE inDAE;
  output list<BackendDAE.Equation> outEquations;
  output Integer outNumberOfInitialEquations;
  output Integer outNumberOfInitialAlgorithms;
algorithm
  (outEquations, outNumberOfInitialEquations, outNumberOfInitialAlgorithms) := matchcontinue(inDAE)
    local
      BackendDAE.EqSystems eqs;
      BackendDAE.EquationArray initialEqs;

      Integer numberOfInitialEquations, numberOfInitialAlgorithms;
      list<BackendDAE.Equation> initialEqs_lst, initialEqs_lst1, initialEqs_lst2, initialEqs_lst3;

    case (BackendDAE.DAE(eqs=eqs, shared=BackendDAE.SHARED(initialEqs=initialEqs))) equation
      // [initial equations]
      // initial_equation
      initialEqs_lst = BackendEquation.equationList(initialEqs);
      // [initial algorithms]
      // remove algorithms, I have no clue what the reason is but is was done before also
      // but they are moved to the end
      (initialEqs_lst1,initialEqs_lst3) = List.splitOnTrue(initialEqs_lst, BackendEquation.isNotAlgorithm);

      // [orderedVars] with fixed=true
      // 0 = v - start(v); fixed(v) = true
      initialEqs_lst2 = List.fold(eqs,generateImplicitInitialEquationsSystem,initialEqs_lst3);

      // append and count
      initialEqs_lst = listAppend(initialEqs_lst1, initialEqs_lst2);
      numberOfInitialEquations = BackendEquation.equationLstSize(initialEqs_lst);
      numberOfInitialAlgorithms = BackendEquation.equationLstSize(initialEqs_lst3);
      numberOfInitialEquations = numberOfInitialEquations-numberOfInitialAlgorithms;
    then (initialEqs_lst, numberOfInitialEquations, numberOfInitialAlgorithms);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function collectInitialEquations failed"});
    then fail();
  end matchcontinue;
end collectInitialEquations;



protected function generateImplicitInitialEquationsSystem "function generateImplicitInitialEquationsSystem
  author: Frenkel TUD
  Helper for collectInitialEquations.
  This function generates implicit initial equations for fixed variables."
  input BackendDAE.EqSystem system;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
protected
  BackendDAE.Variables vars;
algorithm
  vars := BackendVariable.daeVars(system);
  outEqns := BackendVariable.traverseBackendDAEVars(vars, generateImplicitInitialEquations, inEqns);
end generateImplicitInitialEquationsSystem;

protected function generateImplicitInitialEquations "function generateImplicitInitialEquations
  author: lochel
  Helper for collectInitialEquations.
  This function generates implicit initial equations for fixed variables."
  input tuple<BackendDAE.Var,list<BackendDAE.Equation>> inTpl;
  output tuple<BackendDAE.Var,list<BackendDAE.Equation>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local
    BackendDAE.Var var;
    BackendDAE.Equation eqn;
    list<BackendDAE.Equation> eqns;
    DAE.Exp e, e1, crefExp, startExp;
    DAE.ComponentRef cref;
    DAE.Type tp;

    case((var,eqns)) equation
      true = BackendVariable.varFixed(var);
      false = BackendVariable.isStateVar(var);
      false = BackendVariable.isParam(var);
      false = BackendVariable.isVarDiscrete(var);

      cref = BackendVariable.varCref(var);
      crefExp = DAE.CREF(cref, DAE.T_REAL_DEFAULT);

      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);
      e1 = DAE.BINARY(crefExp, DAE.SUB(DAE.T_REAL_DEFAULT), startExp);

      eqn = BackendDAE.RESIDUAL_EQUATION(e1, DAE.emptyElementSource,false);
    then ((var,eqn::eqns));

    else then inTpl;
  end matchcontinue;
end generateImplicitInitialEquations;

public function convertInitialResidualsIntoInitialEquations "function convertInitialResidualsIntoInitialEquations
  author: lochel
  This function converts initial residuals into initial equations of the following form:
    e.g.: 0 = a+b -> $res1 = a+b"
  input list<BackendDAE.Equation> inResidualList;
  output list<BackendDAE.Equation> outEquationList;
  output list<BackendDAE.Var> outVariableList;
algorithm
  (outEquationList, outVariableList) := convertInitialResidualsIntoInitialEquations2(inResidualList, 1, {}, {});
end convertInitialResidualsIntoInitialEquations;

protected function convertInitialResidualsIntoInitialEquations2 "function generateInitialResidualEquations2
  author: lochel
  This is a helper function of convertInitialResidualsIntoInitialEquations."
  input list<BackendDAE.Equation> inEquationList;
  input Integer inIndex;
  input list<BackendDAE.Equation> iEquationList;
  input list<BackendDAE.Var> iVariableList;
  output list<BackendDAE.Equation> outEquationList;
  output list<BackendDAE.Var> outVariableList;
algorithm
  (outEquationList, outVariableList) := matchcontinue(inEquationList, inIndex, iEquationList, iVariableList)
    local
      Integer index;
      list<BackendDAE.Equation> restEquationList;
      list<BackendDAE.Equation> equationList;
      list<BackendDAE.Var> variableList;

      DAE.Exp expVarName;
      DAE.Exp exp;
      DAE.ElementSource source "origin of equation";

      String varName, errorMessage;
      DAE.ComponentRef componentRef;
      BackendDAE.Equation currEquation;
      BackendDAE.Var currVariable;

    case({}, _, _ , _)
    then (listReverse(iEquationList), listReverse(iVariableList));

    case((BackendDAE.RESIDUAL_EQUATION(exp=exp,source=source))::restEquationList, index,_,_) equation
      varName = "$res" +& intString(index);
      componentRef = DAE.CREF_IDENT(varName, DAE.T_REAL_DEFAULT, {});
      expVarName = DAE.CREF(componentRef, DAE.T_REAL_DEFAULT);
      currEquation = BackendDAE.EQUATION(expVarName, exp, source, false);

      currVariable = BackendDAE.VAR(componentRef, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());

      (equationList, variableList) = convertInitialResidualsIntoInitialEquations2(restEquationList, index+1,currEquation::iEquationList,currVariable::iVariableList);
    then (equationList, variableList);

    case(currEquation::_, _,_,_) equation
      errorMessage = "./Compiler/BackEnd/BackendDAEOptimize.mo: function convertInitialResidualsIntoInitialEquations2 failed: " +& BackendDump.equationString(currEquation);
      Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
    then fail();

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function convertInitialResidualsIntoInitialEquations2 failed"});
    then fail();
  end matchcontinue;
end convertInitialResidualsIntoInitialEquations2;

protected function redirectOutputToBiDir "function redirectOutputToBiDir
  author: lochel
  This is a helper function of generateInitialMatrices."
  input tuple<BackendDAE.Var,Integer> inTpl;
  output tuple<BackendDAE.Var,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var;
      Integer i;
    case ((var,i))
      equation
        true = BackendVariable.isOutputVar(var);
        //true = BackendVariable.isVarOnTopLevelAndOutput(variable);
        var = BackendVariable.setVarDirection(var, DAE.BIDIR());
      then ((var,i));
    else then inTpl;
  end matchcontinue;
end redirectOutputToBiDir;

public function generateInitialMatrices "function generateInitialMatrices
  author: lochel
  This function generates symbolic matrices for initialization."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.SymbolicJacobian outJacG;
  output BackendDAE.SparsePattern outSparsityPattern;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outJacG, outSparsityPattern, outDAE) := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE DAE;

      list<BackendDAE.Equation> initialEqs_lst, initialEquationList;
      list<BackendDAE.Var>  initialVariableList;
      BackendDAE.Variables initialVars;
      BackendDAE.EquationArray initialEqs;
      BackendDAE.EqSystem initEqSystem;
      BackendDAE.SymbolicJacobian jacobian;

      BackendDAE.Variables orderedVars, knownVars;
      BackendDAE.EquationArray orderedEqs;

      list<BackendDAE.Var>  orderedVarList, knownVarList, states, inputs, outputs, parameters;
      list<DAE.ComponentRef> orderedVarCrefList, knownVarCrefList;
      BackendDAE.SparsePattern sparsityPattern;

      BackendDAE.Shared shared;

    case(DAE) equation
      (initialEqs_lst, _, _) = collectInitialEquations(DAE);

      //BackendDump.dumpBackendDAEEqnList(initialEqs_lst, "initial residuals 1", false);
      initialEqs_lst = BackendEquation.traverseBackendDAEEqns(BackendEquation.listEquation(initialEqs_lst), BackendDAEUtil.traverseEquationToScalarResidualForm, {});  // ugly
      //BackendDump.dumpBackendDAEEqnList(initialEqs_lst, "initial residuals 2", false);

      (initialEquationList, initialVariableList) = convertInitialResidualsIntoInitialEquations(initialEqs_lst);
      initialEqs = BackendEquation.listEquation(initialEquationList);
      initialVars = BackendVariable.listVar1(initialVariableList);
      //BackendDump.dumpBackendDAEEqnList(initialEquationList, "initial equations", false);
      //BackendDump.dumpBackendDAEVarList(initialVariableList, "initial vars");

      initEqSystem = BackendDAE.EQSYSTEM(initialVars, initialEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{});

      // redirect output to bidir
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays
      DAE = collapseIndependentBlocks(DAE);
      BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, shared=shared) = DAE;
      (orderedVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(orderedVars, redirectOutputToBiDir, 1);

      // add initial equations and $res-variables
      DAE = BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{}), initEqSystem}, shared);
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays

      DAE = collapseIndependentBlocks(DAE);                             // merge everything together
      DAE = BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());  // calculate matching

      // preparing all needed variables
      BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, BackendDAE.SHARED(knownVars=knownVars)) = DAE;

      orderedVarList = BackendVariable.varList(orderedVars);
      orderedVarCrefList = List.map(orderedVarList, BackendVariable.varCref);
      knownVarList = BackendVariable.varList(knownVars);
      knownVarCrefList = List.map(knownVarList, BackendVariable.varCref);
      states = BackendVariable.getAllStateVarFromVariables(orderedVars);
      inputs = List.select(knownVarList, BackendVariable.isInput);
      parameters = List.select(knownVarList, BackendVariable.isParam);
      outputs = List.select(orderedVarList, BackendVariable.isVarOnTopLevelAndOutput);

      (jacobian, sparsityPattern, _) = createJacobian(DAE,                                     // DAE
                                                      states,                                  //
                                                      BackendVariable.listVar1(states),         //
                                                      BackendVariable.listVar1(inputs),         //
                                                      BackendVariable.listVar1(parameters),     //
                                                      BackendVariable.listVar1(outputs),        //
                                                      orderedVarList,                          //
                                                      "G");                                    // name
    then (jacobian, sparsityPattern, DAE);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateInitialMatrices failed"});
    then fail();
  end matchcontinue;
end generateInitialMatrices;

public function generateInitialMatricesDAE "function generateInitialMatricesDAE
  author: lochel
  This function generates a DAE for the symbolic matrices for initialization."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output list<BackendDAE.Var> outVars;  // "initial equation"
algorithm
  (outDAE, outVars) := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE DAE;

      list<BackendDAE.Equation> initialEqs_lst, initialEquationList;
      list<BackendDAE.Var>  initialVariableList;
      BackendDAE.Variables initialVars;
      BackendDAE.EquationArray initialEqs;
      BackendDAE.EqSystem initEqSystem;
      BackendDAE.SymbolicJacobian jacobian;

      BackendDAE.Variables orderedVars, knownVars;
      BackendDAE.EquationArray orderedEqs;

      list<BackendDAE.Var>  orderedVarList, knownVarList, states, inputs, outputs, parameters;
      list<DAE.ComponentRef> orderedVarCrefList, knownVarCrefList;
      BackendDAE.SparsePattern sparsityPattern;

      BackendDAE.Shared shared;

    case(DAE) equation
      (initialEqs_lst, _, _) = collectInitialEquations(DAE);

      //BackendDump.dumpBackendDAEEqnList(initialEqs_lst, "initial residuals 1", false);
      initialEqs_lst = BackendEquation.traverseBackendDAEEqns(BackendEquation.listEquation(initialEqs_lst), BackendDAEUtil.traverseEquationToScalarResidualForm, {});  // ugly
      //BackendDump.dumpBackendDAEEqnList(initialEqs_lst, "initial residuals 2", false);

      (initialEquationList, initialVariableList) = convertInitialResidualsIntoInitialEquations(initialEqs_lst);
      initialEqs = BackendEquation.listEquation(initialEquationList);
      initialVars = BackendVariable.listVar1(initialVariableList);
      //BackendDump.dumpBackendDAEEqnList(initialEquationList, "initial equations", false);
      //BackendDump.dumpBackendDAEVarList(initialVariableList, "initial vars");

      initEqSystem = BackendDAE.EQSYSTEM(initialVars, initialEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{});

      // redirect output to bidir
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays
      DAE = collapseIndependentBlocks(DAE);
      BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, shared=shared) = DAE;
      (orderedVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(orderedVars, redirectOutputToBiDir, 1);

      // add initial equations and $res-variables
      DAE = BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{}), initEqSystem}, shared);
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays

      DAE = collapseIndependentBlocks(DAE);                             // merge everything together
      DAE = BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());  // calculate matching

      // preparing all needed variables
      BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, BackendDAE.SHARED(knownVars=knownVars)) = DAE;

      orderedVarList = BackendVariable.varList(orderedVars);
      orderedVarCrefList = List.map(orderedVarList, BackendVariable.varCref);
      knownVarList = BackendVariable.varList(knownVars);
      knownVarCrefList = List.map(knownVarList, BackendVariable.varCref);
      states = BackendVariable.getAllStateVarFromVariables(orderedVars);
      inputs = List.select(knownVarList, BackendVariable.isInput);
      parameters = List.select(knownVarList, BackendVariable.isParam);
      outputs = List.select(orderedVarList, BackendVariable.isVarOnTopLevelAndOutput);
    then (DAE, outputs);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateInitialMatricesDAE failed"});
    then fail();
  end matchcontinue;
end generateInitialMatricesDAE;

public function generateInitialMatricesSparsityPattern "function generateInitialMatricesSparsityPattern
  author: lochel
  This function generates symbolic matrices for initialization."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.SparsePattern outSparsityPattern;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outSparsityPattern, outDAE) := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE DAE;

      list<BackendDAE.Equation> initialEqs_lst, initialEquationList;
      list<BackendDAE.Var>  initialVariableList;
      BackendDAE.Variables initialVars;
      BackendDAE.EquationArray initialEqs;
      BackendDAE.EqSystem initEqSystem;
      BackendDAE.SymbolicJacobian jacobian;

      BackendDAE.Variables orderedVars, knownVars;
      BackendDAE.EquationArray orderedEqs;

      list<BackendDAE.Var>  orderedVarList, knownVarList, states, inputs, outputs, parameters;
      list<DAE.ComponentRef> orderedVarCrefList, knownVarCrefList;
      BackendDAE.SparsePattern sparsityPattern;

      BackendDAE.Shared shared;

    case(DAE) equation
      (initialEqs_lst, _, _) = collectInitialEquations(DAE);
      initialEqs_lst = BackendEquation.traverseBackendDAEEqns(BackendEquation.listEquation(initialEqs_lst), BackendDAEUtil.traverseEquationToScalarResidualForm, {});  // ugly

      //BackendDump.dumpBackendDAEEqnList(initialEqs_lst, "initial residuals", false);
      (initialEquationList, initialVariableList) = convertInitialResidualsIntoInitialEquations(initialEqs_lst);
      initialEqs = BackendEquation.listEquation(initialEquationList);
      initialVars = BackendVariable.listVar1(initialVariableList);
      //BackendDump.dumpBackendDAEEqnList(initialEquationList, "initial equations", false);
      //BackendDump.dumpBackendDAEVarList(initialVariableList, "initial vars");

      initEqSystem = BackendDAE.EQSYSTEM(initialVars, initialEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{});

      // redirect output to bidir
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays
      DAE = collapseIndependentBlocks(DAE);
      BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, shared=shared) = DAE;
      (orderedVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(orderedVars, redirectOutputToBiDir, 1);

      // add initial equations and $res-variables
      DAE = BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{}), initEqSystem}, shared);
      DAE = BackendDAEUtil.copyBackendDAE(DAE);                         // to avoid side effects from arrays

      DAE = collapseIndependentBlocks(DAE);                             // merge everything together
      DAE = BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());  // calculate matching

      // preparing all needed variables
      BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)}, BackendDAE.SHARED(knownVars=knownVars)) = DAE;

      orderedVarList = BackendVariable.varList(orderedVars);
      orderedVarCrefList = List.map(orderedVarList, BackendVariable.varCref);
      knownVarList = BackendVariable.varList(knownVars);
      knownVarCrefList = List.map(knownVarList, BackendVariable.varCref);
      states = BackendVariable.getAllStateVarFromVariables(orderedVars);
      inputs = List.select(knownVarList, BackendVariable.isInput);
      parameters = List.select(knownVarList, BackendVariable.isParam);
      outputs = List.select(orderedVarList, BackendVariable.isVarOnTopLevelAndOutput);

      (sparsityPattern, _) = generateSparsePattern(DAE, states, outputs);
    then (sparsityPattern, DAE);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateInitialMatricesSparsityPattern failed"});
    then fail();
  end matchcontinue;
end generateInitialMatricesSparsityPattern;




// =============================================================================
// Symbolic Jacobian subsection
//
// =============================================================================
public function generateSymbolicJacobianPast
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.SymbolicJacobian symJacA;
  BackendDAE.SparsePattern sparsePattern;
  BackendDAE.SparseColoring sparseColoring;
algorithm
  System.realtimeTick(CevalScript.RT_CLOCK_EXECSTAT_JACOBIANS);
  BackendDAE.DAE(eqs=eqs,shared=shared) := inBackendDAE;
  (symJacA , sparsePattern, sparseColoring ):= createSymbolicJacobianforStates(inBackendDAE);
  shared := BackendDAEUtil.addBackendDAESharedJacobian(symJacA, sparsePattern, sparseColoring, shared);
  outBackendDAE := BackendDAE.DAE(eqs,shared);
  _ := Flags.enableDebug(Flags.JACOBIAN);
  _ := System.realtimeTock(CevalScript.RT_CLOCK_EXECSTAT_JACOBIANS);
end generateSymbolicJacobianPast;

public function generateSymbolicLinearizationPast
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.SymbolicJacobians linearModelMatrixes;
algorithm
  System.realtimeTick(CevalScript.RT_CLOCK_EXECSTAT_JACOBIANS);
  BackendDAE.DAE(eqs=eqs,shared=shared) := inBackendDAE;
  linearModelMatrixes := createLinearModelMatrixes(inBackendDAE);
  shared := BackendDAEUtil.addBackendDAESharedJacobians(linearModelMatrixes, shared);
  outBackendDAE := BackendDAE.DAE(eqs,shared);
  _ := Flags.enableDebug(Flags.JACOBIAN);
  _ := System.realtimeTock(CevalScript.RT_CLOCK_EXECSTAT_JACOBIANS);
end generateSymbolicLinearizationPast;

protected function createSymbolicJacobianforStates
" fuction creates symbolic jacobian
  all functionODE equation are differentiated
  with respect to the states.

  author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.SymbolicJacobian outJacobian;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outSparseColoring;
algorithm
  (outJacobian, outSparsePattern, outSparseColoring) :=
  matchcontinue (inBackendDAE)
    local
      BackendDAE.BackendDAE backendDAE, backendDAE2;

      list<BackendDAE.Var>  varlst, knvarlst,  states, inputvars, paramvars;
      list<DAE.ComponentRef> comref_vars,comref_knvars;

      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray e;

      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;

    case (backendDAE)
      equation

        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> start generate system for matrix A time : " +& realString(clock()) +& "\n");

        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = collapseIndependentBlocks(backendDAE2);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        BackendDAE.DAE({syst as BackendDAE.EQSYSTEM(orderedVars = v,orderedEqs = e)},shared as BackendDAE.SHARED(knownVars = kv)) = backendDAE2;

        /*
        (blt_states, _) = BackendDAEUtil.generateStatePartition(syst);

        newEqns = BackendEquation.emptyEqns();
        newVars = BackendVariable.emptyVars();
        (newEqns, newVars) = BackendDAEUtil.splitoutEquationAndVars(blt_states,e,v,newEqns,newVars);
        backendDAE2 = BackendDAE.DAE(BackendDAE.EQSYSTEM(newVars,newEqns,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        */
        // Prepare all needed variables
        varlst = BackendVariable.varList(v);
        comref_vars = List.map(varlst,BackendVariable.varCref);
        knvarlst = BackendVariable.varList(kv);
        comref_knvars = List.map(knvarlst,BackendVariable.varCref);
        states = BackendVariable.getAllStateVarFromVariables(v);
        inputvars = List.select(knvarlst,BackendVariable.isInput);
        paramvars = List.select(knvarlst, BackendVariable.isParam);

        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> prepared vars for symbolic matrix A time: " +& realString(clock()) +& "\n");
        (outJacobian, outSparsePattern, outSparseColoring)  = createJacobian(backendDAE2,states,BackendVariable.listVar1(states),BackendVariable.listVar1(inputvars),BackendVariable.listVar1(paramvars),BackendVariable.listVar1(states),varlst,"A");

      then
        (outJacobian, outSparsePattern, outSparseColoring);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of symbolic Jacobian Matrix code failed. Function: BackendDAEOpimize.createSymcolicaJacobianforStates"});
      then
        fail();
  end matchcontinue;
end createSymbolicJacobianforStates;

protected function createLinearModelMatrixes
"fuction creates the linear model matrices column-wise
 author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.SymbolicJacobians outJacobianMatrixes;
algorithm
  outJacobianMatrixes :=
  matchcontinue (inBackendDAE)
    local
      BackendDAE.BackendDAE backendDAE,backendDAE2;

      list<BackendDAE.Var>  varlst, knvarlst,  states, inputvars, inputvars2, outputvars, paramvars;
      list<DAE.ComponentRef> comref_states, comref_inputvars, comref_outputvars, comref_vars, comref_knvars;

      BackendDAE.Variables v,kv,statesarr,inputvarsarr,paramvarsarr,outputvarsarr;
      BackendDAE.EquationArray e;

      BackendDAE.SymbolicJacobians linearModelMatrices;
      BackendDAE.SymbolicJacobian linearModelMatrix;

      BackendDAE.SparsePattern sparsePattern;
      BackendDAE.SparseColoring sparseColoring;

    case (backendDAE)
      equation
        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = collapseIndependentBlocks(backendDAE2);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v,orderedEqs = e)},BackendDAE.SHARED(knownVars = kv)) = backendDAE2;

        // Prepare all needed variables
        varlst = BackendVariable.varList(v);
        comref_vars = List.map(varlst,BackendVariable.varCref);
        knvarlst = BackendVariable.varList(kv);
        comref_knvars = List.map(knvarlst,BackendVariable.varCref);
        states = BackendVariable.getAllStateVarFromVariables(v);
        inputvars = List.select(knvarlst,BackendVariable.isInput);
        paramvars = List.select(knvarlst, BackendVariable.isParam);
        inputvars2 = List.select(knvarlst,BackendVariable.isVarOnTopLevelAndInput);
        outputvars = List.select(varlst,BackendVariable.isVarOnTopLevelAndOutput);

        comref_states = List.map(states,BackendVariable.varCref);
        comref_inputvars = List.map(inputvars2,BackendVariable.varCref);
        comref_outputvars = List.map(outputvars,BackendVariable.varCref);

        statesarr = BackendVariable.listVar1(states);
        inputvarsarr = BackendVariable.listVar1(inputvars);
        paramvarsarr = BackendVariable.listVar1(paramvars);
        outputvarsarr = BackendVariable.listVar1(outputvars);

        // Differentiate the System w.r.t states for matrices A
        (linearModelMatrix, sparsePattern, sparseColoring) = createJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"A");
        linearModelMatrices = {(SOME(linearModelMatrix),sparsePattern,sparseColoring)};
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix A time: " +& realString(clock()) +& "\n");


        // Differentiate the System w.r.t inputs for matrices B
        (linearModelMatrix, sparsePattern, sparseColoring) = createJacobian(backendDAE2,inputvars2,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"B");
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix B time: " +& realString(clock()) +& "\n");


        // Differentiate the System w.r.t states for matrices C
        (linearModelMatrix, sparsePattern, sparseColoring) = createJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,outputvarsarr,varlst,"C");
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix C time: " +& realString(clock()) +& "\n");


        // Differentiate the System w.r.t inputs for matrices D
        (linearModelMatrix, sparsePattern, sparseColoring) = createJacobian(backendDAE2,inputvars2,statesarr,inputvarsarr,paramvarsarr,outputvarsarr,varlst,"D");
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated system for matrix D time: " +& realString(clock()) +& "\n");

      then
        linearModelMatrices;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of LinearModel Matrices failed. Function: BackendDAEOpimize.createLinearModelMatrixes"});
      then
        fail();
  end matchcontinue;
end createLinearModelMatrixes;

public function createJacobian "function createJacobian
  author: wbraun
  helper fuction of createSymbolicJacobian*"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inDiffVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParameterVars;
  input BackendDAE.Variables inDifferentiatedVars;
  input list<BackendDAE.Var> inVars;
  input String inName;
  output BackendDAE.SymbolicJacobian outJacobian;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outSparseColoring;
algorithm
  (outJacobian, outSparsePattern, outSparseColoring) :=
  matchcontinue (inBackendDAE,inDiffVars,inStateVars,inInputVars,inParameterVars,inDifferentiatedVars,inVars,inName)
    local
      BackendDAE.BackendDAE backendDAE;

      list<DAE.ComponentRef> comref_vars, comref_seedVars, comref_differentiatedVars;

      BackendDAE.Shared shared;
      BackendDAE.Variables  knvars, knvars1;
      list<BackendDAE.Var> diffedVars, diffVarsTmp, seedlst, knvarsTmp;
      String s,s1;

      BackendDAE.SparsePattern sparsepattern;
      BackendDAE.SparseColoring colsColors;

    case (_,_,_,_,_,_,_,_)
      equation

        diffedVars = BackendVariable.varList(inDifferentiatedVars);
        s =  intString(listLength(diffedVars));
        comref_differentiatedVars = List.map(diffedVars, BackendVariable.varCref);

        comref_vars = List.map(inDiffVars, BackendVariable.varCref);
        seedlst = List.map1(comref_vars, createSeedVars, (inName,false));
        comref_seedVars = List.map(seedlst, BackendVariable.varCref);
        s1 =  intString(listLength(inVars));

        Debug.execStat("analytical Jacobians -> starting to generate the jacobian. DiffVars:"
                       +& s +& " diffed equations: " +&  s1 +& "\n", CevalScript.RT_CLOCK_EXECSTAT_JACOBIANS);

        // Differentiate the ODE system w.r.t states for jacobian
        (backendDAE as BackendDAE.DAE(shared=shared)) = generateSymbolicJacobian(inBackendDAE, comref_vars, inDifferentiatedVars, BackendVariable.listVar1(seedlst), inStateVars, inInputVars, inParameterVars, inName);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated equations for Jacobian " +& inName +& " time: " +& realString(clock()) +& "\n");

        knvars1 = BackendVariable.daeKnVars(shared);
        knvarsTmp = BackendVariable.varList(knvars1);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> sorted know temp vars(" +& intString(listLength(knvarsTmp)) +& ") for Jacobian DAE time: " +& realString(clock()) +& "\n");

        (backendDAE as BackendDAE.DAE(shared=shared)) = optimizeJacobianMatrix(backendDAE,comref_differentiatedVars,comref_vars);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> generated Jacobian DAE time: " +& realString(clock()) +& "\n");

        knvars = BackendVariable.daeKnVars(shared);
        diffVarsTmp = BackendVariable.varList(knvars);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> sorted know diff vars(" +& intString(listLength(diffVarsTmp)) +& ") for Jacobian DAE time: " +& realString(clock()) +& "\n");
        (_,knvarsTmp,_) = List.intersection1OnTrue(diffVarsTmp, knvarsTmp, BackendVariable.varEqual);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> sorted know vars(" +& intString(listLength(knvarsTmp)) +& ") for Jacobian DAE time: " +& realString(clock()) +& "\n");
        knvars = BackendVariable.listVar1(knvarsTmp);
        backendDAE = BackendDAEUtil.addBackendDAEKnVars(knvars,backendDAE);
        Debug.execStat("analytical Jacobians -> generated optimized jacobians", CevalScript.RT_CLOCK_EXECSTAT_JACOBIANS);

        // generate sparse pattern
        (sparsepattern,colsColors) = generateSparsePattern(inBackendDAE, inDiffVars, diffedVars);
     then
        ((backendDAE, inName, inDiffVars, diffedVars, inVars), sparsepattern, colsColors);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.createJacobian failed"});
      then
        fail();
  end matchcontinue;
end createJacobian;

public function optimizeJacobianMatrix
  // function: optimizeJacobianMatrix
  // author: wbraun
  input BackendDAE.BackendDAE inBackendDAE;
  input list<DAE.ComponentRef> inComRef1; // eqnvars
  input list<DAE.ComponentRef> inComRef2; // vars to differentiate
  output BackendDAE.BackendDAE outJacobian;
algorithm
  outJacobian :=
    matchcontinue (inBackendDAE,inComRef1,inComRef2)
    local
      BackendDAE.BackendDAE backendDAE, backendDAE2;
      BackendDAE.Variables v;
      BackendDAE.EquationArray e;

      BackendDAE.Shared shared;
      array<Integer> ea;

      Option<BackendDAE.IncidenceMatrix> om,omT;
      Boolean b;
      BackendDAE.StateSets stateSets;

      case (backendDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=e,m=om,mT=omT,stateSets=stateSets)::{},shared),{},_)
        equation
          v = BackendVariable.listVar({});
          ea = listArray({});
        then (BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,BackendDAE.MATCHING(ea,ea,{}),stateSets)::{},shared));
      case (backendDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=e,m=om,mT=omT,stateSets=stateSets)::{},shared),_,{})
        equation
          v = BackendVariable.listVar({});
          ea = listArray({});
        then (BackendDAE.DAE(BackendDAE.EQSYSTEM(v,e,om,omT,BackendDAE.MATCHING(ea,ea,{}),stateSets)::{},shared));
      case (backendDAE,_,_)
        equation
          Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> optimize jacobians time: " +& realString(clock()) +& "\n");

          b = Flags.disableDebug(Flags.EXEC_STAT);

          backendDAE2 = BackendDAEUtil.getSolvedSystemforJacobians(backendDAE,
                                                                   SOME({"removeSimpleEquationsFast"}),
                                                                   NONE(),
                                                                   NONE(),
                                                                   SOME({"inlineArrayEqn",
                                                                         "constantLinearSystem",
                                                                         "removeSimpleEquations",
                                                                         "collapseIndependentBlocks"}));
          _ = Flags.set(Flags.EXEC_STAT, b);
          //Debug.fcall(Flags.JAC_DUMP2, BackendDump.bltdump, ("jacdump2",backendDAE2));
        then backendDAE2;
     else
       equation
         Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.optimizeJacobianMatrix failed"});
       then fail();
   end matchcontinue;
end optimizeJacobianMatrix;

public function generateSymbolicJacobian "function generateSymbolicJacobian
  author: lochel"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<DAE.ComponentRef> inVars;      // wrt
  input BackendDAE.Variables indiffedVars;  // unknowns?
  input BackendDAE.Variables inseedVars;    //
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input String inMatrixName;
  output BackendDAE.BackendDAE outJacobian;
algorithm
  outJacobian := matchcontinue(inBackendDAE, inVars, indiffedVars, inseedVars, inStateVars, inInputVars, inParamVars, inMatrixName)
    local
      BackendDAE.BackendDAE bDAE;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars, comref_diffvars;
      DAE.ComponentRef x;
      String dummyVarName;
      BackendDAE.Variables stateVars;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables diffedVars;
      BackendDAE.BackendDAE jacobian;

      // BackendDAE
      BackendDAE.Variables orderedVars, jacOrderedVars; // ordered Variables, only states and alg. vars
      BackendDAE.Variables knownVars, jacKnownVars; // Known variables, i.e. constants and parameters
      BackendDAE.Variables jacExternalObjects; // External object variables
      BackendDAE.Variables jacAliasVars; // mappings of alias-variables to real-variables
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs; // ordered Equations
      BackendDAE.EquationArray removedEqs, jacRemovedEqs; // Removed equations a=b
      BackendDAE.EquationArray jacInitialEqs; // Initial equations
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      BackendDAE.EventInfo jacEventInfo; // eventInfo
      BackendDAE.ExternalObjectClasses jacExtObjClasses; // classes of external objects, contains constructor & destructor
      // end BackendDAE

      list<BackendDAE.Var> derivedVariables,diffvars;
      list<BackendDAE.Equation> derivedEquations;
      list<list<BackendDAE.Equation>> derivedEquationslst;


      Env.Cache cache;
      Env.Env env;

      String matrixName;
      array<Integer> ass2;

    case(BackendDAE.DAE(shared=BackendDAE.SHARED(cache=cache,env=env)), {}, _, _, _, _, _, _) equation
      jacOrderedVars = BackendVariable.emptyVars();
      jacKnownVars = BackendVariable.emptyVars();
      jacExternalObjects = BackendVariable.emptyVars();
      jacAliasVars =  BackendVariable.emptyVars();
      jacOrderedEqs = BackendEquation.emptyEqns();
      jacRemovedEqs = BackendEquation.emptyEqns();
      jacInitialEqs = BackendEquation.emptyEqns();
      constrs = listArray({});
      clsAttrs = listArray({});
      functions = DAEUtil.avlTreeNew();
      jacEventInfo = BackendDAE.EVENT_INFO(BackendDAE.SAMPLE_LOOKUP(0, {}), {}, {}, {}, {}, 0, 0);
      jacExtObjClasses = {};

      jacobian = BackendDAE.DAE({BackendDAE.EQSYSTEM(jacOrderedVars, jacOrderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{})}, BackendDAE.SHARED(jacKnownVars, jacExternalObjects, jacAliasVars, jacInitialEqs, jacRemovedEqs, constrs, clsAttrs, cache, env, functions, jacEventInfo, jacExtObjClasses,BackendDAE.JACOBIAN(),{}));
    then jacobian;

    case(bDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,matching=BackendDAE.MATCHING(ass2=ass2))::{}, BackendDAE.SHARED(knownVars=knownVars, removedEqs=removedEqs ,cache=cache,env=env,  functionTree=functions)), vars, diffedVars, _, stateVars, inputVars, paramVars, matrixName) equation

      // Generate tmp varibales
      diffvars = BackendVariable.varList(orderedVars);
      dummyVarName = ("dummyVar" +& matrixName);
      x = DAE.CREF_IDENT(dummyVarName,DAE.T_REAL_DEFAULT,{});

      // differentiate the equation system
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> derived all algorithms time: " +& realString(clock()) +& "\n");
      derivedEquationslst = deriveAll(BackendEquation.equationList(orderedEqs),arrayList(ass2), {x}, functions, inputVars, paramVars, stateVars, knownVars, orderedVars, vars, (matrixName,false), {});
      derivedEquations = List.flatten(derivedEquationslst);
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> created all derived equation time: " +& realString(clock()) +& "\n");

      // create BackendDAE.DAE with derivied vars and equations

      // all variables for new equation system
      // d(ordered vars)/d(dummyVar)
      diffvars = BackendVariable.varList(orderedVars);
      derivedVariables = creatallDiffedVars(diffvars, x, diffedVars, 0, (matrixName, false),{});

      jacOrderedVars = BackendVariable.listVar1(derivedVariables);
      // known vars: all variable from original system + seed
      jacKnownVars = BackendVariable.emptyVars();
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars, orderedVars);
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars, knownVars);
      jacKnownVars = BackendVariable.mergeVariables(jacKnownVars, inseedVars);
      (jacKnownVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(jacKnownVars, BackendVariable.setVarDirectionTpl, (DAE.INPUT()));
      jacExternalObjects = BackendVariable.emptyVars();
      jacAliasVars =  BackendVariable.emptyVars();
      jacOrderedEqs = BackendEquation.listEquation(derivedEquations);
      jacRemovedEqs = BackendEquation.emptyEqns();
      jacInitialEqs = BackendEquation.emptyEqns();
      constrs = listArray({});
      clsAttrs = listArray({});
      functions = DAEUtil.avlTreeNew();
      jacEventInfo = BackendDAE.EVENT_INFO(BackendDAE.SAMPLE_LOOKUP(0, {}), {}, {}, {}, {}, 0, 0);
      jacExtObjClasses = {};

      jacobian = BackendDAE.DAE(BackendDAE.EQSYSTEM(jacOrderedVars, jacOrderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),{})::{}, BackendDAE.SHARED(jacKnownVars, jacExternalObjects, jacAliasVars, jacInitialEqs, jacRemovedEqs, constrs, clsAttrs, cache, env, functions, jacEventInfo, jacExtObjClasses, BackendDAE.JACOBIAN(),{}));

    then jacobian;

    case(bDAE as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,matching=BackendDAE.MATCHING(ass2=ass2))::{}, BackendDAE.SHARED(knownVars=knownVars, removedEqs=removedEqs, functionTree=functions)), vars, diffedVars, _, stateVars, inputVars, paramVars, _) equation

      diffvars = BackendVariable.varList(orderedVars);
      (derivedVariables,comref_diffvars) = generateJacobianVars(diffvars, vars, (inMatrixName,false));
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> created all derived vars: " +& "No. :" +& intString(listLength(comref_diffvars)) +& "time: " +& realString(clock()) +& "\n");
      derivedEquationslst = deriveAll(BackendEquation.equationList(orderedEqs),arrayList(ass2), vars, functions, inputVars, paramVars, stateVars, knownVars, orderedVars, comref_diffvars, (inMatrixName,false), {});
      derivedEquations = List.flatten(derivedEquationslst);
      false = (listLength(derivedVariables) == listLength(derivedEquations));
      Debug.fcall(Flags.JAC_DUMP, print, "*** analytical Jacobians -> failed vars are not equal to equations: " +& intString(listLength(derivedEquations)) +& " time: " +& realString(clock()) +& "\n");
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSymbolicJacobian failed"});
    then fail();

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

public function createSeedVars
  // function: createSeedVars
  // author: wbraun
  input DAE.ComponentRef indiffVar;
  input tuple<String,Boolean> inMatrixName;
  output BackendDAE.Var outseedVar;
algorithm
  outseedVar := match(indiffVar,inMatrixName)
    local
      BackendDAE.Var  jacvar;
      DAE.ComponentRef derivedCref;
    case (_, _)
      equation
        derivedCref = differentiateVarWithRespectToX(indiffVar, indiffVar, inMatrixName);
        jacvar = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      then jacvar;
  end match;
end createSeedVars;

protected function generateJacobianVars "function generateJacobianVars
  author: lochel"
  input list<BackendDAE.Var> inVars1;
  input list<DAE.ComponentRef> inVars2;
  input tuple<String,Boolean> inMatrixName;
  output list<BackendDAE.Var> outVars;
  output list<DAE.ComponentRef> outcrefVars;
algorithm
  (outVars, outcrefVars) := matchcontinue(inVars1, inVars2, inMatrixName)
  local
    BackendDAE.Var currVar;
    list<BackendDAE.Var> restVar, r1, r2, r;
    list<DAE.ComponentRef> vars2,res,res1,res2;

    case({}, _, _)
    then ({},{});

    case(currVar::restVar, vars2, _) equation
      (r1,res1) = generateJacobianVars2(currVar, vars2, inMatrixName);
      (r2,res2) = generateJacobianVars(restVar, vars2, inMatrixName);
      res = listAppend(res1, res2);
      r = listAppend(r1, r2);
    then (r,res);

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateJacobianVars failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars;

protected function generateJacobianVars2 "function generateJacobianVars2
  author: lochel"
  input BackendDAE.Var inVar1;
  input list<DAE.ComponentRef> inVars2;
  input tuple<String,Boolean> inMatrixName;
  output list<BackendDAE.Var> outVars;
  output list<DAE.ComponentRef> outcrefVars;
algorithm
  (outVars,outcrefVars) := matchcontinue(inVar1, inVars2, inMatrixName)
  local
    BackendDAE.Var var, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<DAE.ComponentRef> restVar,res,res1;
    list<BackendDAE.Var> r,r2;

    case(_, {}, _)
    then ({},{});

    // skip for dicrete variable
    case(var as BackendDAE.VAR(varName=cref,varKind=BackendDAE.DISCRETE()), currVar::restVar, _ ) equation
      (r2,res) = generateJacobianVars2(var, restVar, inMatrixName);
    then (r2,res);

    case(var as BackendDAE.VAR(varName=cref,varKind=BackendDAE.STATE(index=_)), currVar::restVar, _) equation
      cref = ComponentReference.crefPrefixDer(cref);
      derivedCref = differentiateVarWithRespectToX(cref, currVar, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      (r2,res1) = generateJacobianVars2(var, restVar, inMatrixName);
      res = listAppend({derivedCref}, res1);
      r = listAppend({r1}, r2);
    then (r,res);

    case(var as BackendDAE.VAR(varName=cref), currVar::restVar, _) equation
      derivedCref = differentiateVarWithRespectToX(cref, currVar, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      (r2,res1) = generateJacobianVars2(var, restVar, inMatrixName);
      res = listAppend({derivedCref}, res1);
      r = listAppend({r1}, r2);
    then (r,res);

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

public function creatallDiffedVars
  // function: help function for creatallDiffedVars
  // author: wbraun
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inIndex;
  input tuple<String,Boolean> inMatrixName;
  input list<BackendDAE.Var> iVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars, inCref,inAllVars,inIndex,inMatrixName,iVars)
  local
    BackendDAE.Var  r1,v1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<BackendDAE.Var> restVar;

    case({}, _, _, _, _,_)
    then listReverse(iVars);
    // skip for dicrete variable
    case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.DISCRETE())::restVar,cref,_,_, _, _) equation
     then
       creatallDiffedVars(restVar,cref,inAllVars,inIndex, inMatrixName,iVars);

     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE(index=_))::restVar,cref,_,_, _, _) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
    then
      creatallDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName,r1::iVars);

    case(BackendDAE.VAR(varName=currVar)::restVar,cref,_,_, _, _) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
    then
      creatallDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName,r1::iVars);

     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE(index=_))::restVar,cref,_,_, _, _) equation
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
    then
      creatallDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName,r1::iVars);

    case(BackendDAE.VAR(varName=currVar)::restVar,cref,_,_, _, _) equation
      derivedCref = differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
    then
      creatallDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName,r1::iVars);

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.creatallDiffedVars failed"});
    then fail();
  end matchcontinue;
end creatallDiffedVars;

protected function deriveAll "function deriveAll
  author: lochel"
  input list<BackendDAE.Equation> inEquations;
  input list<Integer> ass2;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inorderedVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  input list<list<BackendDAE.Equation>> inDerivedEquations;
  output list<list<BackendDAE.Equation>> outDerivedEquations;
algorithm
  outDerivedEquations :=
  matchcontinue(inEquations, ass2, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName, inDerivedEquations)
    local
      BackendDAE.Equation currEquation;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      list<BackendDAE.Equation> restEquations, currDerivedEquations;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      list<Integer> ass2_1,solvedfor;

    case({},_, _, _, _, _, _, _, _, _, _, _) then listReverse(inDerivedEquations);

    case(currEquation::restEquations,_, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _, _)
      equation
      //Debug.fcall(Flags.JAC_DUMP_EQN, print, "Derive Equation! Left on Stack: " +& intString(listLength(restEquations)) +& "\n");
      //Debug.fcall(Flags.JAC_DUMP_EQN, BackendDump.printEquationList, {currEquation});
      //Debug.fcall(Flags.JAC_DUMP_EQN, print, "\n");
      //dummycref = ComponentReference.makeCrefIdent("$pDERdummy", DAE.T_REAL_DEFAULT, {});
      //Debug.fcall(Flags.JAC_DUMP_EQN,print, "*** analytical Jacobians -> derive one equation: " +& realString(clock()) +& "\n" );
      (solvedfor,ass2_1) = List.split(ass2, BackendEquation.equationSize(currEquation));
      currDerivedEquations = derive(currEquation, solvedfor, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      //Debug.fcall(Flags.JAC_DUMP_EQN, BackendDump.printEquationList, currDerivedEquations);
      //Debug.fcall(Flags.JAC_DUMP_EQN, print, "\n");
      //Debug.fcall(Flags.JAC_DUMP_EQN,print, "*** analytical Jacobians -> created other equations from that: " +& realString(clock()) +& "\n" );
     then
       deriveAll(restEquations, ass2_1, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName, currDerivedEquations::inDerivedEquations);

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.deriveAll failed"});
    then fail();
  end matchcontinue;
end deriveAll;

protected function derive "function derive
  author: lochel"
  input BackendDAE.Equation inEquation;
  input list<Integer> solvedfor;
  input list<DAE.ComponentRef> inVar;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inorderedVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, solvedfor, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName)
    local
      BackendDAE.Equation currEquation;
      list<BackendDAE.Equation> derivedEqns;
      DAE.FunctionTree functions;
      DAE.ComponentRef cref;
      DAE.Exp exp,lhs, rhs;
      list<DAE.ComponentRef> vars, crefs;
      list<DAE.Exp> lhs_, rhs_, exps;
      DAE.ElementSource source;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      Integer size;
      DAE.Algorithm alg;
      list<DAE.Algorithm> algs;
      list<Integer> ds;
      list<Option<Integer>> ad;
      list<list<DAE.Subscript>> subslst;
      list<BackendDAE.Var> solvedvars;
      String dumpBuffer;

    case(currEquation as BackendDAE.WHEN_EQUATION(size=_),_, vars, functions, inputVars, paramVars, stateVars, knownVars,  _, _, _) equation
      Debug.fcall(Flags.JAC_DUMP, print,"BackendDAEOptimize.derive: WHEN_EQUATION has been removed.\n");
    then {};

    //remove dicrete Equation
    case(currEquation,_, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      solvedvars = List.map1r(solvedfor,BackendVariable.getVarAt,inorderedVars);
      List.mapAllValue(solvedvars, BackendVariable.isVarDiscrete, true);
      Debug.fcall(Flags.JAC_DUMP, print,"BackendDAEOptimize.derive: discrete equation has been removed.\n");
    then {};

    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source),_, vars, functions, inputVars, paramVars, stateVars, knownVars, _,  _, _) equation
      lhs_ = differentiateWithRespectToXVec(lhs, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      rhs_ = differentiateWithRespectToXVec(rhs, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      derivedEqns = List.threadMap1(lhs_, rhs_, BackendEquation.generateEQUATION, source);
    then derivedEqns;

    case(currEquation as BackendDAE.ARRAY_EQUATION(dimSize=ds,left=lhs,right=rhs,source=source),_, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
        ad = List.map(ds,Util.makeOption);
        subslst = BackendDAEUtil.arrayDimensionsToRange(ad);
        subslst = BackendDAEUtil.rangesToSubscripts(subslst);
        lhs_ = List.map1r(subslst,Expression.applyExpSubscripts,lhs);
        lhs_ = ExpressionSimplify.simplifyList(lhs_, {});
        rhs_ = List.map1r(subslst,Expression.applyExpSubscripts,rhs);
        rhs_ = ExpressionSimplify.simplifyList(rhs_, {});
    then
      deriveLst(lhs_,rhs_,source,vars, functions, inputVars, paramVars, stateVars, knownVars,inorderedVars, inDiffVars, inMatrixName, {});

    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source),_, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      crefs = List.map2(vars,differentiateVarWithRespectToXR,cref, inMatrixName);
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      derivedEqns = List.threadMap1(crefs, exps, createSolvedEqn, source);
    then derivedEqns;

    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source),_, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      exps = differentiateWithRespectToXVec(exp, vars, functions, inputVars, paramVars, stateVars, knownVars, inorderedVars, inDiffVars, inMatrixName);
      derivedEqns = List.map1(exps, createResidualEqn, source);
    then derivedEqns;

    case(currEquation as BackendDAE.ALGORITHM(size=size,alg=alg, source=source),_, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _)
    equation
      algs = deriveOneAlg(alg,vars,functions,inputVars,paramVars,stateVars,knownVars,inorderedVars,0,inDiffVars,inMatrixName);
      derivedEqns = List.map2(algs, createAlgorithmEqn, size, source);
    then derivedEqns;

    case(currEquation as BackendDAE.COMPLEX_EQUATION(source=_),_, vars, functions, inputVars, paramVars, stateVars, knownVars, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed: COMPLEX_EQUATION-case"});
    then fail();

    case(currEquation, _, _, _, _, _, _, _, _, _, _) equation
      dumpBuffer = "BackendDAEOptimize.derive failed: " +& BackendDump.equationString(currEquation);
      Error.addMessage(Error.INTERNAL_ERROR, {dumpBuffer});
    then fail();

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.derive failed"});
    then fail();
  end matchcontinue;
end derive;

protected function deriveLst "function derivelst
  author: Frenkel TUD
  helper for derive to handle array equations"
  input list<DAE.Exp> lhslst;
  input list<DAE.Exp> rhslst;
  input DAE.ElementSource source;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree functions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inorderedVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  input list<BackendDAE.Equation> inDerivedEquations;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := match(lhslst, rhslst, source, inVars, functions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName, inDerivedEquations)
    local
      list<BackendDAE.Equation> derivedEqns;
      DAE.Exp lhs, rhs;
      list<DAE.Exp> lhsrest,rhsrest,lhs_,rhs_;

    case({},{},_,_,_,_,_,_,_,_,_,_,_) then inDerivedEquations;

    case(lhs::lhsrest,rhs::rhsrest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        lhs_ = differentiateWithRespectToXVec(lhs, inVars, functions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName);
        rhs_ = differentiateWithRespectToXVec(rhs, inVars, functions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName);
        derivedEqns = List.threadMap1(lhs_, rhs_, BackendEquation.generateEQUATION, source);
        derivedEqns = listAppend(inDerivedEquations,derivedEqns);
      then
        deriveLst(lhsrest,rhsrest, source, inVars, functions, inInputVars, inParamVars, inStateVars, inKnownVars, inorderedVars, inDiffVars, inMatrixName, derivedEqns);

  end match;
end deriveLst;

protected function createSolvedEqn
  input DAE.ComponentRef inCref;
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAE.SOLVED_EQUATION(inCref,inRHS,Source,false);
end createSolvedEqn;

protected function createResidualEqn
  input DAE.Exp inRHS;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAE.RESIDUAL_EQUATION(inRHS, Source, false);
end createResidualEqn;

protected function createAlgorithmEqn
  input DAE.Algorithm Alg;
  input Integer Size;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAE.ALGORITHM(Size, Alg, Source);
end createAlgorithmEqn;

public function differentiateVarWithRespectToX "function differentiateVarWithRespectToX
  author: lochel"
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  input tuple<String,Boolean> inMatrixName;
  //input list<BackendDAE.Var> inStateVars;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inX, inMatrixName)//, inStateVars)
    local
      DAE.ComponentRef cref, x;
      String id,str;
      String matrixName;
     /* replace the subscripts with strings because not all elements of the arrays may be derived, this avoid trouble when generate simulation code */
     case(cref, x, (matrixName,true))
      equation
        cref = ComponentReference.joinCrefs(ComponentReference.makeCrefIdent(BackendDAE.partialDerivativeNamePrefix, ComponentReference.crefType(cref), {}),cref);
        cref = ComponentReference.appendStringCref(matrixName, cref);
        cref = ComponentReference.joinCrefs(cref, x);
        cref = ComponentReference.replaceSubsWithString(cref);
      then
        cref;
    case(cref, x, (matrixName,false))
      equation
        id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& matrixName +& "$P" +& ComponentReference.printComponentRefStr(x);
        id = Util.stringReplaceChar(id, ",", "$c");
        id = Util.stringReplaceChar(id, ".", "$P");
        id = Util.stringReplaceChar(id, "[", "$lB");
        id = Util.stringReplaceChar(id, "]", "$rB");
      then ComponentReference.makeCrefIdent(id, DAE.T_REAL_DEFAULT, {});

    case(cref, _, _)
      equation
        str = "BackendDAEOptimize.differentiateVarWithRespectToX failed: " +&  ComponentReference.printComponentRefStr(cref);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end differentiateVarWithRespectToX;

public function differentiateVarWithRespectToXR
"  function: differentiateVarWithRespectToXR
   author: wbraun
   This function create a differentiated ComponentReference. "
  input DAE.ComponentRef inX;
  input DAE.ComponentRef inCref;
  input tuple<String,Boolean> inMatrixName;
  output DAE.ComponentRef outCref;
algorithm
  outCref := differentiateVarWithRespectToX(inCref, inX, inMatrixName);
end differentiateVarWithRespectToXR;

protected function deriveExpListwrtstate
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input list<tuple<Integer,DAE.derivativeCond>> inConditios;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inConditios, inState, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars;
      list<DAE.ComponentRef> diffVars;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then ({});
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars, knownVars, _, diffVars,_) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      true = checkcondition(conditions,argnum);
      {r1} = differentiateWithRespectToXVec(curr, {x}, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars,inMatrixName);
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars,inMatrixName);
    then (r1::r2);
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars,knownVars, _, diffVars, _) equation
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars, inMatrixName);
    then r2;
  end matchcontinue;
end deriveExpListwrtstate;

protected function deriveExpListwrtstate2
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := match(inExpList, inLengthExpList, inState, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      BackendDAE.Variables inputVars, paramVars, stateVars,knownVars;
      list<DAE.ComponentRef> diffVars;
    case ({}, _, _, _, _, _, _, _, _,_, _) then ({});
    case (curr::rest, LengthExpList, x, functions, inputVars, paramVars, stateVars, knownVars, _, diffVars, _) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      {r1} = differentiateWithRespectToXVec(curr, {x}, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars, inMatrixName);
      r2 = deriveExpListwrtstate2(rest,LengthExpList, x, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, diffVars, inMatrixName);
    then (r1::r2);
  end match;
end deriveExpListwrtstate2;

protected function checkcondition
  input list<tuple<Integer,DAE.derivativeCond>> inConditions;
  input Integer inArgs;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(inConditions, inArgs)
    local
      list<tuple<Integer,DAE.derivativeCond>> rest;
      Integer i,nArgs;
      DAE.derivativeCond cond;
      Boolean res;
    case ({},_) then true;
    case((i,cond)::rest,nArgs)
      equation
        equality(i = nArgs);
        cond = DAE.ZERO_DERIVATIVE();
      then false;
      case((i,cond)::rest,nArgs)
       equation
         equality(i = nArgs);
         DAE.NO_DERIVATIVE(_) = cond;
       then false;
    case((i,cond)::rest,nArgs)
      equation
        res = checkcondition(rest,nArgs);
      then res;
  end matchcontinue;
end checkcondition;

protected function partialAnalyticalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.Exp functionCall;
  input Absyn.Path derFname;
  input Integer nDerArgs;
  output DAE.Exp outExp;
algorithm
  outExp := match(varExpList, derVarExpList, functionCall, derFname, nDerArgs)
    local
      DAE.Exp e, currVar, currDerVar, derFun;
      list<DAE.Exp> restVar, restDerVar, varExpList1Added, varExpListTotal;
      Integer nArgs1, nArgs2;
      DAE.CallAttributes attr;
    case ( _, {}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, DAE.CALL(expLst=varExpListTotal, attr=attr), _, _)
      equation
        e = partialAnalyticalDifferentiation(restVar, restDerVar, functionCall, derFname, nDerArgs);
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restDerVar);
        varExpList1Added = List.replaceAtWithFill(DAE.RCONST(0.0),nArgs1 + nDerArgs - 1, varExpListTotal ,DAE.RCONST(0.0));
        varExpList1Added = List.replaceAtWithFill(DAE.RCONST(1.0),nArgs1 + nDerArgs - (nArgs2 + 1), varExpList1Added,DAE.RCONST(0.0));
        derFun = DAE.CALL(derFname, varExpList1Added, attr);
      then DAE.BINARY(e, DAE.ADD(DAE.T_REAL_DEFAULT), DAE.BINARY(derFun, DAE.MUL(DAE.T_REAL_DEFAULT), currDerVar));
  end match;
end partialAnalyticalDifferentiation;

protected function partialNumericalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.ComponentRef inState;
  input DAE.Exp functionCall;
  output DAE.Exp outExp;
algorithm
  outExp := match(varExpList, derVarExpList, inState, functionCall)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpListHAdded, varExpListTotal;
      Absyn.Path fname;
      Integer nArgs1, nArgs2;
      DAE.CallAttributes attr;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, _, DAE.CALL(path=fname, expLst=varExpListTotal, attr=attr))
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.T_REAL_DEFAULT),DAE.RCONST(1e-8),-1,NONE()),DAE.OR(DAE.T_BOOL_DEFAULT),DAE.RELATION(currVar,DAE.LESS(DAE.T_REAL_DEFAULT),DAE.RCONST(-1e-8),-1,NONE()));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.T_REAL_DEFAULT),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = List.replaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.T_REAL_DEFAULT),delta),nArgs1-(nArgs2+1), varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, attr), DAE.SUB(DAE.T_REAL_DEFAULT), DAE.CALL(fname, varExpListTotal, attr)), DAE.DIV(DAE.T_REAL_DEFAULT), delta);
      then DAE.BINARY(e, DAE.ADD(DAE.T_REAL_DEFAULT), DAE.BINARY(derFun, DAE.MUL(DAE.T_REAL_DEFAULT), currDerVar));
  end match;
end partialNumericalDifferentiation;

protected function deriveOneAlg "function deriveOneAlg
  author: lochel"
  input DAE.Algorithm inAlgorithm;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input Integer inAlgIndex;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Algorithm> outDerivedAlgorithms;
algorithm
  outDerivedAlgorithms := match(inAlgorithm, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inAlgIndex, inDiffVars, inMatrixName)
    local
      DAE.Algorithm currAlg;
      list<DAE.Statement> statementLst, derivedStatementLst;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      DAE.FunctionTree functions;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables stateVars;
      BackendDAE.Variables knownVars;
      list<DAE.ComponentRef> diffVars;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
    case(_, {}, _, _, _, _, _, _, _,_, _) then {};

    case(currAlg as DAE.ALGORITHM_STMTS(statementLst=statementLst), currVar::restVars, functions, inputVars, paramVars, stateVars, knownVars, _, algIndex, diffVars, _)equation
      derivedStatementLst = differentiateAlgorithmStatements(statementLst, currVar, functions, inputVars, paramVars, stateVars, {}, knownVars, inAllVars, diffVars, inMatrixName);
      rAlgs1 = {DAE.ALGORITHM_STMTS(derivedStatementLst)};
      rAlgs2 = deriveOneAlg(currAlg, restVars, functions, inputVars, paramVars, stateVars, knownVars, inAllVars, algIndex, diffVars, inMatrixName);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
    then rAlgs1;
  end match;
end deriveOneAlg;

protected function differentiateAlgorithmStatements "function differentiateAlgorithmStatements
  author: lochel"
  input list<DAE.Statement> inStatements;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input list<BackendDAE.Var> inControlVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := matchcontinue(inStatements, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inControlVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
    local
      list<DAE.Statement> restStatements;
      DAE.ComponentRef var;
      DAE.FunctionTree functions;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables stateVars;
      list<BackendDAE.Var> controlVars;
      BackendDAE.Variables controlparaVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables allVars;
      list<DAE.ComponentRef> diffVars;
      DAE.Statement currStatement;
      DAE.ElementSource source;
      list<DAE.Statement> derivedStatements1;
      list<DAE.Statement> derivedStatements2;
      DAE.Exp exp;
      DAE.Type type_;
      DAE.Exp lhs, rhs;
      DAE.Exp derivedLHS, derivedRHS;
      //list<DAE.Exp> derivedLHS, derivedRHS;
      DAE.Exp elseif_exp;
      list<DAE.Statement> statementLst,else_statementLst,elseif_statementLst;
      DAE.Else elseif_else_;
      Boolean iterIsArray;
      DAE.Ident ident;
      DAE.ComponentRef cref;
      BackendDAE.Var controlVar;
      list<DAE.Exp> lhsTuple;
      list<DAE.Exp> derivedLHSTuple;
      DAE.ElementSource source_;
      Integer index;
    case({}, _, _, _, _, _, _, _, _,_, _) then {};

    //remove dicrete Equation
    case ((currStatement as DAE.STMT_ASSIGN(type_=type_, exp1=lhs, exp=rhs,source=source_))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      true = BackendDAEUtil.isDiscreteExp(lhs,allVars,knownVars);
      true = BackendDAEUtil.isDiscreteExp(rhs,allVars,knownVars);
      Debug.fcall(Flags.JAC_DUMP,print,"BackendDAEOptimize.differentiateAlgorithmStatements: discrete equation has been removed.\n");
    then {};

    case((currStatement as DAE.STMT_ASSIGN(type_=type_, exp1=lhs, exp=rhs,source=source_))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      controlparaVars = BackendVariable.addVars(controlVars, paramVars);
      {derivedLHS} = differentiateWithRespectToXVec(lhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      {derivedRHS} = differentiateWithRespectToXVec(rhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_ASSIGN(type_, derivedLHS, derivedRHS, source_), currStatement};
      //derivedStatements1 = List.threadMap3(derivedLHS, derivedRHS, createDiffStatements, type_, currStatement, source);
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case ((currStatement as DAE.STMT_TUPLE_ASSIGN(type_=type_,exp=rhs,expExpLst=lhsTuple,source=source_))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, _)
    equation
      controlparaVars = BackendVariable.addVars(controlVars, paramVars);
      {derivedLHSTuple} = List.map9(lhsTuple,differentiateWithRespectToXVec, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      {derivedRHS} = differentiateWithRespectToXVec(rhs, {var}, functions, inputVars, controlparaVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_TUPLE_ASSIGN(type_, derivedLHSTuple, derivedRHS, source_), currStatement};
      //Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed: DAE.STMT_TUPLE_ASSIGN"});
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_ASSIGN_ARR(exp=rhs)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed: DAE.STMT_ASSIGN_ARR"});
    then fail();

    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE(), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements2 = differentiateAlgorithmStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements2 = differentiateAlgorithmStatements(else_statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, iter=ident, index=index, range=exp, statementLst=statementLst, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      cref = ComponentReference.makeCrefIdent(ident, DAE.T_INTEGER_DEFAULT, {});
      controlVar = BackendDAE.VAR(cref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      controlVars = listAppend(controlVars, {controlVar});
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);

      derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, index, exp, derivedStatements1, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_WHILE(exp=exp, statementLst=statementLst, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = {DAE.STMT_WHILE(exp, derivedStatements1, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;

    case(DAE.STMT_WHEN(exp=exp)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      //derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      Debug.fcall(Flags.JAC_DUMP,print,"BackendDAEOptimize.differentiateAlgorithmStatements: WHEN has been removed.\n");
    then {};

    case((currStatement as DAE.STMT_ASSERT(cond=exp))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars,  diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;

    case((currStatement as DAE.STMT_TERMINATE(msg=exp))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;

    case(DAE.STMT_REINIT(value=exp)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
    then derivedStatements1;

    case(DAE.STMT_NORETCALL(exp=exp, source=source)::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      // e2 = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      // derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      // derivedStatements1 = listAppend({DAE.STMT_NORETCALL(e2, elemSrc)}, derivedStatements2);
    then fail();

    case((currStatement as DAE.STMT_RETURN(source=source))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;

    case((currStatement as DAE.STMT_BREAK(source=source))::restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, _)
    equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions, inputVars, paramVars, stateVars, controlVars, knownVars, allVars, diffVars, inMatrixName);
      derivedStatements1 = currStatement::derivedStatements2;
    then derivedStatements1;

    case(_, _, _, _, _, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEOptimize.differentiateAlgorithmStatements failed"});
    then fail();
  end matchcontinue;
end differentiateAlgorithmStatements;

protected function createDiffStatements
  input DAE.Exp inLHS;
  input DAE.Exp inRHS;
  input DAE.Type inType;
  input DAE.Statement inStmt;
  input DAE.ElementSource Source;
  output list<DAE.Statement> outEqn;
algorithm outEqn := match(inLHS,inRHS,inType,inStmt,Source)
  local
  case (inLHS,inRHS,inType,inStmt,Source) then {DAE.STMT_ASSIGN(inType, inLHS, inRHS, Source), inStmt};
 end match;
end createDiffStatements;

protected function differentiateWithRespectToXVec "function differentiateWithRespectToXVec
  author: wbraun"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inX;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inKnownVars;
  input BackendDAE.Variables inAllVars;
  input list<DAE.ComponentRef> inDiffVars;
  input tuple<String,Boolean> inMatrixName;
  output list<DAE.Exp> outExp;
algorithm
  outExp := matchcontinue(inExp, inX, inFunctions, inInputVars, inParamVars, inStateVars, inKnownVars, inAllVars, inDiffVars, inMatrixName)
    local
      list<DAE.ComponentRef> xlist;
      list<DAE.Exp> dxlist,dxlist1,dxlist2;
      DAE.ComponentRef  cref;
      DAE.FunctionTree functions;
      DAE.Exp e1,  e2,  e;
      DAE.Type et;
      DAE.Operator op;

      Absyn.Path fname;

      list<DAE.Exp> expList1;
      list<list<DAE.Exp>> expListLst;
      Boolean  b;
      BackendDAE.Variables inputVars, paramVars, stateVars, knownVars, allVars;
      list<DAE.ComponentRef> diffVars;
      String str;
      BackendDAE.Var v1;
      Integer index;
      Option<tuple<DAE.Exp,Integer,Integer>> optionExpisASUB;
      list<DAE.Var> varLst;

    case(e as DAE.ICONST(_), xlist,functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        dxlist = createDiffListMeta(e,xlist,diffInt, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    case( e as DAE.RCONST(_), xlist,functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _)
      equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    // d(time)/d(x)
    case(e as DAE.CREF(componentRef=(cref as DAE.CREF_IDENT(ident = "time",subscriptLst = {}))), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _)
      equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

  // case for Records
    case (e as DAE.CREF(componentRef=cref, ty = et as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(fname))), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        expList1 = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cref);
        e1 = DAE.CALL(fname,expList1,DAE.CALL_ATTR(et,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
      then
        differentiateWithRespectToXVec(e1,xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
    // case for arrays
    case (e as DAE.CREF(componentRef=cref, ty = et as DAE.T_ARRAY(dims=_)), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
      then
        differentiateWithRespectToXVec(e1,xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);

    case(e as DAE.CREF(componentRef=cref),xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars, _) equation
      dxlist = createDiffListMeta(e,xlist,diffCref, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    // dummy diff
    case(e as DAE.CREF(componentRef=cref),xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars, _) equation
      dxlist = createDiffListMeta(e,xlist,diffCref, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    // known vars
    case (DAE.CREF(componentRef=cref, ty=et), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
      ({(v1 as BackendDAE.VAR(bindExp=SOME(e1)))}, _) = BackendVariable.getVar(cref, knownVars);
      dxlist = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
    then dxlist;

    // diff crefVar
    case(e as DAE.CREF(componentRef=cref),xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _) equation
      dxlist = createDiffListMeta(e,xlist,diffCrefVar, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    // binary
    case(DAE.BINARY(exp1=e1, operator=op, exp2=e2),xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName);
      dxlist2 = differentiateWithRespectToXVec(e2, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName);
      dxlist = List.threadMap3(dxlist1,dxlist2,mergeBin,op,e1,e2);
    then dxlist;

    // uniary
    case(DAE.UNARY(operator=op, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars, _) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars,  allVars, diffVars, inMatrixName);
      dxlist = List.map1(dxlist1,mergeUn,op);
    then dxlist;

    // der(x)
    case (e as DAE.CALL(path=fname, expLst={e1}), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, _)
      equation
      Builtin.isDer(fname);
      dxlist = createDiffListMeta(e,xlist,diffDerCref, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars,  diffVars, inMatrixName)));
    then dxlist;

    // function call
    case (e as DAE.CALL(path=_, expLst={e1}), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        dxlist = List.map2(dxlist1,mergeCall,e1,e);
    then dxlist;

    // function call more than one argument
    case (e as DAE.CALL(path=_, expLst=expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        expListLst = List.map9( expList1, differentiateWithRespectToXVec, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        expListLst = List.transposeList(expListLst);
        dxlist = List.map1(expListLst,mergeCallExpList,e);
    then dxlist;

    // extern functions (analytical and numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
       dxlist = createDiffListMeta(e,xlist,diffNumCall, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName)));
    then dxlist;

    // cast
    case (DAE.CAST(ty=et, exp=e1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _) equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      dxlist = List.map1(dxlist1,mergeCast,et);
    then dxlist;

    // relations
    case (e as DAE.RELATION(e1, op, e2, index, optionExpisASUB), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _) equation
        dxlist = createDiffListMeta(e,xlist,diffRealZero, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName)));
    then dxlist;

      // differentiate if-expressions
    case (DAE.IFEXP(expCond=e, expThen=e1, expElse=e2), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
      dxlist1 = differentiateWithRespectToXVec(e1, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      dxlist2 = differentiateWithRespectToXVec(e2, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
      dxlist = List.threadMap1(dxlist1,dxlist2,mergeIf,e);
    then dxlist;


    case (e as DAE.ARRAY(ty = et,scalar = b,array = expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        expListLst = List.map9(expList1, differentiateWithRespectToXVec, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        expListLst = List.transposeList(expListLst);
        dxlist = List.map2(expListLst, mergeArray, et, b);
      then
        dxlist;

    case (DAE.TUPLE(PR = expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars,diffVars, _)
      equation
        expListLst = List.map9(expList1, differentiateWithRespectToXVec, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        expListLst = List.transposeList(expListLst);
        dxlist = List.map(expListLst, mergeTuple);
      then
        dxlist;

    case (DAE.ASUB(exp = e,sub = expList1), xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, _)
      equation
        dxlist = differentiateWithRespectToXVec(e, xlist, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        dxlist = List.map1(dxlist,Expression.makeASUB, expList1);
      then
       dxlist;

    case(e, xlist, _, _, _, _, _, _,_, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE_JAC);
        str = "BackendDAEOptimize.differentiateWithRespectToXVec failed: " +& ExpressionDump.printExpStr(e) +& "\n";
        print(str);
        //Error.addMessage(Error.INTERNAL_ERROR, {str});
      then {};
  end matchcontinue;
end differentiateWithRespectToXVec;

protected function createDiffListMeta
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> indiffVars;
  input FuncExpType func;
  input Option<Type_a> inTypeA;
  output list<DAE.Exp> outExpList;
  partial function FuncExpType
    input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
    output DAE.Exp outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
   outExpList := matchcontinue (inExp, indiffVars, func, inTypeA)
   local
     DAE.Exp e,e1;
     DAE.ComponentRef diff_cref;
     list<DAE.ComponentRef> rest;
     list<DAE.Exp> res;
     Option<Type_a> typea;
     String str;

     case(e, {}, _, _) then {};

     case(e, diff_cref::rest, _, typea)
       equation
         e1 = func((e, diff_cref, typea));
         res = createDiffListMeta(e,rest,func,typea);
       then e1::res;

     case(e, diff_cref::rest, _, _)
       equation
        true = Flags.isSet(Flags.FAILTRACE_JAC);
         str = "BackendDAEOptimize.createDiffListMeta failed: " +& ExpressionDump.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(diff_cref) +& "\n";
         print(str);
        //Error.addMessage(Error.INTERNAL_ERROR, {str});
       then fail();
  end matchcontinue;
end createDiffListMeta;




// =============================================================================
// diff functions for differemtiatewrtX vectorize
//
// =============================================================================
protected function diffInt
  input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := match(inTplExpTypeA)
    case(_) then DAE.ICONST(0);
 end match;
end diffInt;

protected function diffRealZero
  input tuple<DAE.Exp, DAE.ComponentRef, Option<Type_a>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := match(inTplExpTypeA)
    case(_) then DAE.RCONST(0.0);
 end match;
end diffRealZero;

protected function diffCrefVar
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := match(inTplExpTypeA)
  local
    DAE.ComponentRef cref,cref_,x;
    DAE.Type et;
    tuple<String,Boolean> matrixName;
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, _, matrixName))))
      equation
      cref_ = differentiateVarWithRespectToX(cref, x, matrixName);
      //print(" *** diffCrefVar : " +& ComponentReference.printComponentRefStr(cref) +& " w.r.t " +& ComponentReference.printComponentRefStr(x) +& "\n");
    then DAE.CREF(cref_, et);
 end match;
end diffCrefVar;

protected function diffCref
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    DAE.Type et;
    DAE.ComponentRef x, cref,cref_;
    list<DAE.ComponentRef> diffVars;
    DAE.Exp e1;
    BackendDAE.Variables inputVars, paramVars, stateVars, allVars;
    BackendDAE.Var v1;
    list<Boolean> b_lst;
    String matrixName;

    // d(discrete)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, allVars, _, _))))
      equation
      ({v1 as BackendDAE.VAR(varKind = BackendDAE.DISCRETE())}, _) = BackendVariable.getVar(cref, allVars);
    then DAE.RCONST(0.0);

    //tearing
    // d(x)/d(x)
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, _, (_,true)))))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cref, x);
        e1 = Expression.makeConstOne(et);
      then
        e1;
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, diffVars, (_,true)))))
      equation
      b_lst = List.map1(diffVars,ComponentReference.crefEqual,cref);
      true = Util.boolOrList(b_lst);
      (e1,_) = Expression.makeZeroExpression(Expression.arrayDimension(et));
    then
      e1;

    // d(x)/d(x)
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, _, _, _, diffVars, (matrixName,false)))))
      equation
      b_lst = List.map1(diffVars,ComponentReference.crefEqual,cref);
      true = Util.boolOrList(b_lst);
      cref_ = differentiateVarWithRespectToX(cref, cref, (matrixName,false));
      //print(" *** diffCref : " +& ComponentReference.printComponentRefStr(cref) +& " w.r.t " +& ComponentReference.printComponentRefStr(x) +& "\n");
    then
      DAE.CREF(cref_, et);

    // d(state)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, _, stateVars, _, _, _, _))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, stateVars);
    then DAE.RCONST(0.0);

    // d(input)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, inputVars, _, _, _, _, _, _))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, inputVars);
    then DAE.RCONST(0.0);

    // d(parameter)/d(x) = 0
    case((DAE.CREF(componentRef=cref, ty=et),x,SOME((_, _, paramVars, _, _, _, _, _))))
      equation
      ({v1}, _) = BackendVariable.getVar(cref, paramVars);
    then DAE.RCONST(0.0);

 end matchcontinue;
end diffCref;

protected function diffDerCref
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    Absyn.Path fname;
    DAE.Exp e1;
    DAE.ComponentRef x,cref;
    tuple<String,Boolean> matrixName;
    Option<tuple<DAE.FunctionTree,BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>> tpl;

    case((DAE.CALL(path=fname, expLst={e1}),x,tpl as SOME((_, _, _, _, _, _, _, matrixName as (_,true)))))
      equation
        e1 = diffCref((e1,x,tpl));
    then e1;

    case((DAE.CALL(path=fname, expLst={e1}),x,SOME((_, _, _, _, _, _, _, matrixName))))
      equation
      cref = Expression.expCref(e1);
      cref = ComponentReference.crefPrefixDer(cref);
      //x = DAE.CREF_IDENT("pDERdummy",DAE.T_REAL_DEFAULT,{});
      cref = differentiateVarWithRespectToX(cref, x, matrixName);
    then DAE.CREF(cref, DAE.T_REAL_DEFAULT);
 end matchcontinue;
end diffDerCref;

protected function diffNumCall
  input tuple<DAE.Exp, DAE.ComponentRef, Option<tuple<DAE.FunctionTree, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, BackendDAE.Variables, list<DAE.ComponentRef>, tuple<String,Boolean>>>> inTplExpTypeA;
  output DAE.Exp outTplExpTypeA;
algorithm
  outTplExpTypeA := matchcontinue(inTplExpTypeA)
  local
    Absyn.Path fname,derFname;
    DAE.ComponentRef x;
    DAE.Exp e,e1;
    list<DAE.Exp> expList1,expList2;
    DAE.Type tp;
    Integer nArgs;
    BackendDAE.Variables inputVars, paramVars, stateVars, knownVars, allVars;
    list<DAE.ComponentRef> diffVars;
    DAE.FunctionTree functions;
    list<tuple<Integer,DAE.derivativeCond>> conditions;
    tuple<String,Boolean> inMatrixName;
    //Option<tuple<DAE.FunctionTree, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>, list<BackendDAE.Var>>> inTpl;
    // extern functions (analytical)
    case ((e as DAE.CALL(path=fname, expLst=expList1), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName))))
      equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));
        (e1,_) = ExpressionSimplify.simplify(e1);
      then e1;
    case ((e as DAE.CALL(path=fname, expLst=expList1), x, SOME((functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName))))
      equation
        //(SOME((functions, inputVars, paramVars, stateVars, knownVars, diffVars))) = inTpl;
        Debug.fcall(Flags.JAC_DUMP,print,"differentiate function call " +& Absyn.pathString(fname) +& "(" +& ExpressionDump.printExpListStr(expList1) +& ") numerical.\n");
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars, knownVars, allVars, diffVars, inMatrixName);
        Debug.fcall(Flags.JAC_DUMP,print,"derived ExpList args: (" +& ExpressionDump.printExpListStr(expList2) +& "\n");
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);
        Debug.fcall(Flags.JAC_DUMP,print,"derived exp : (" +& ExpressionDump.printExpStr(e1) +& "\n");
        (e1,_) = ExpressionSimplify.simplify(e1);
        Debug.fcall(Flags.JAC_DUMP,print,"derived exp simplify: (" +& ExpressionDump.printExpStr(e1) +& "\n");
      then e1;
 end matchcontinue;
end diffNumCall;




// =============================================================================
// Merge functions for differemtiatewrtX vectorize
//
// =============================================================================
protected function mergeCall
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inOrgExp1;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp1,inExp2,inOrgExp1)
  local
    DAE.Exp e;
    //sin(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("sin")))
      equation
        e = DAE.BINARY(inExp1, DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("cos"),{inExp2},DAE.callAttrBuiltinReal));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // cos(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("cos")))
      equation
        e = DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT), DAE.BINARY(inExp1,DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("sin"),{inExp2},DAE.callAttrBuiltinReal)));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // ln(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("log")))
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.T_REAL_DEFAULT), inExp2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // log10(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("log10")))
      equation
        e = DAE.BINARY(inExp1, DAE.DIV(DAE.T_REAL_DEFAULT), DAE.BINARY(inExp2, DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},DAE.callAttrBuiltinReal)));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // exp(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("exp")))
      equation
        e = DAE.BINARY(inExp1,DAE.MUL(DAE.T_REAL_DEFAULT), DAE.CALL(Absyn.IDENT("exp"),{inExp2},DAE.callAttrBuiltinReal));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    // sqrt(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("sqrt")))
      equation
        e = DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.T_REAL_DEFAULT),
          DAE.CALL(Absyn.IDENT("sqrt"),{inExp2},DAE.callAttrBuiltinReal))),DAE.MUL(DAE.T_REAL_DEFAULT),inExp1);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
   // abs(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("abs")))
      equation
        e = DAE.IFEXP(DAE.RELATION(inExp2,DAE.GREATEREQ(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE()), inExp1, DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),inExp1));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;

    // openmodelica build call $_start(x)
    case (_,_,DAE.CALL(path=Absyn.IDENT("$_start")))
      equation
        e = DAE.RCONST(0.0);
      then e;
  end match;
end mergeCall;


protected function mergeCallExpList
  input list<DAE.Exp> inExp1Lst;
  input DAE.Exp inOrgExp1;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp1Lst,inOrgExp1)
  local
    DAE.Exp e,z1,z2;
    DAE.Exp dz1,dz2;
    //max(x,y)
    case ({dz1,dz2},DAE.CALL(path=Absyn.IDENT("max"),expLst={z1,z2}))
      equation
        e = DAE.IFEXP(DAE.RELATION(z1, DAE.GREATER(DAE.T_REAL_DEFAULT), z2, -1, NONE()),
                      dz1, dz2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
  end match;
end mergeCallExpList;

protected function mergeBin
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Operator inOp;
  input DAE.Exp inOrgExp1;
  input DAE.Exp inOrgExp2;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp1,inExp2,inOp,inOrgExp1,inOrgExp2)
  local
    DAE.Exp e,z1,z2;
    DAE.Type et;
    case (_,_,DAE.ADD(_), _, _)
      equation
        e = DAE.BINARY(inExp1,inOp,inExp2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (_,_,DAE.SUB(_), _, _)
      equation
        e = DAE.BINARY(inExp1,inOp,inExp2);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (_,_,DAE.MUL(et),_,_)
      equation
        e = DAE.BINARY(DAE.BINARY(inExp1, DAE.MUL(et), inOrgExp2), DAE.ADD(et), DAE.BINARY(inOrgExp1, DAE.MUL(et), inExp2));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (_,_,DAE.MUL_ARRAY_SCALAR(et),_,_)
      equation
        e = DAE.BINARY(DAE.BINARY(inExp1, DAE.MUL_ARRAY_SCALAR(et), inOrgExp2), DAE.ADD_ARR(et), DAE.BINARY(inOrgExp1, DAE.MUL_ARRAY_SCALAR(et), inExp2));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (_,_,DAE.DIV(et),_,_)
      equation
        e = DAE.BINARY(DAE.BINARY(DAE.BINARY(inExp1, DAE.MUL(et), inOrgExp2), DAE.SUB(et), DAE.BINARY(inOrgExp1, DAE.MUL(et), inExp2)), DAE.DIV(et), DAE.BINARY(inOrgExp2, DAE.MUL(et), inOrgExp2));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (_,_,DAE.POW(et),_,_)
      equation
        true = Expression.isConst(inOrgExp2);
        e = DAE.BINARY(inExp1, DAE.MUL(et), DAE.BINARY(inOrgExp2, DAE.MUL(et), DAE.BINARY(inOrgExp1, DAE.POW(et), DAE.BINARY(inOrgExp2, DAE.SUB(et), DAE.RCONST(1.0)))));
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
    case (_,_,DAE.POW(et),_,_)
      equation
        z1 = DAE.BINARY(inExp1, DAE.DIV(et), inOrgExp1);
        z1 = DAE.BINARY(inOrgExp2, DAE.MUL(et), z1);
        z2 = DAE.CALL(Absyn.IDENT("log"), {inOrgExp1}, DAE.callAttrBuiltinReal);
        z2 = DAE.BINARY(inExp2, DAE.MUL(et), z2);
        z1 = DAE.BINARY(z1, DAE.ADD(et), z2);
        z2 = DAE.BINARY(inOrgExp1, DAE.POW(et), inOrgExp2);
        z1 = DAE.BINARY(z1, DAE.MUL(et), z2);
        (e,_) = ExpressionSimplify.simplify(z1);
      then e;
 end matchcontinue;
end mergeBin;

protected function mergeIf
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inOrgExp1;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp1,inExp2,inOrgExp1)
    case (_,_,_) then DAE.IFEXP(inOrgExp1, inExp1, inExp2);
 end match;
end mergeIf;

protected function mergeUn
  input DAE.Exp inExp1;
  input DAE.Operator inOp;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp1,inOp)
  local
    DAE.Exp e;
    case (_,_)
      equation
        e = DAE.UNARY(inOp,inExp1);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
 end match;
end mergeUn;

protected function mergeCast
  input DAE.Exp inExp1;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp1,inType)
  local
    DAE.Exp e;
    case (_,_)
      equation
        e = DAE.CAST(inType,inExp1);
        (e,_) = ExpressionSimplify.simplify(e);
      then e;
 end match;
end mergeCast;

protected function mergeRelation
  input DAE.Exp inExp0;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Operator inOp;
  input Integer inIndex;
  input Option<tuple<DAE.Exp,Integer,Integer>> inOptionExpisASUB;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp0,inExp1,inExp2,inOp, inIndex, inOptionExpisASUB)
  local
    DAE.Exp e;
    case (inExp0,inExp1,inExp2,inOp,inIndex,inOptionExpisASUB)
      equation
        e = DAE.RELATION(inExp1,inOp,inExp2,inIndex,inOptionExpisASUB);
    then e;
 end matchcontinue;
end mergeRelation;

protected function mergeArray
  input list<DAE.Exp> inExplst;
  input DAE.Type inType;
  input Boolean inScalar;
  output DAE.Exp outExp;
algorithm
  outExp :=  DAE.ARRAY(inType, inScalar, inExplst);
end mergeArray;

protected function mergeTuple
  input list<DAE.Exp> inExplst;
  output DAE.Exp outExp;
algorithm
  outExp :=  DAE.TUPLE(inExplst);
end mergeTuple;




// =============================================================================
// parallel backend stuff
//
// =============================================================================
public function collapseIndependentBlocks
  "Finds independent partitions of the equation system by "
  input BackendDAE.BackendDAE dlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (dlow)
    local
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(systs,shared))
      equation
        // We can use listReduce as if there is no eq-system something went terribly wrong
        syst = List.reduce(systs,mergeIndependentBlocks);
      then BackendDAE.DAE({syst},shared);
  end match;
end collapseIndependentBlocks;

protected function mergeIndependentBlocks
  input BackendDAE.EqSystem syst1;
  input BackendDAE.EqSystem syst2;
  output BackendDAE.EqSystem syst;
protected
  BackendDAE.Variables vars,vars1,vars2;
  BackendDAE.EquationArray eqs,eqs1,eqs2;
  BackendDAE.StateSets stateSets,statSets1;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars1,orderedEqs=eqs1,stateSets=stateSets) := syst1;
  BackendDAE.EQSYSTEM(orderedVars=vars2,orderedEqs=eqs2,stateSets=statSets1) := syst2;
  vars := BackendVariable.addVars(BackendVariable.varList(vars2),vars1);
  eqs := BackendEquation.addEquations(BackendEquation.equationList(eqs2),eqs1);
  stateSets := listAppend(stateSets,statSets1);
  syst := BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets);
end mergeIndependentBlocks;

public function partitionIndependentBlocks
  "Finds independent partitions of the equation system by "
  input BackendDAE.BackendDAE dlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (dlow)
    local
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE({syst},shared))
      equation
        (systs,shared) = partitionIndependentBlocksHelper(syst,shared,Error.getNumErrorMessages(),false);
      then BackendDAE.DAE(systs,shared);
    else // TODO: Improve support for partitioned systems of equations
      equation
        BackendDAE.DAE({syst},shared) = collapseIndependentBlocks(dlow);
        (systs,shared) = partitionIndependentBlocksHelper(syst,shared,Error.getNumErrorMessages(),false);
      then BackendDAE.DAE(systs,shared);
  end match;
end partitionIndependentBlocks;

public function partitionIndependentBlocksHelper
  "Finds independent partitions of the equation system by "
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer numErrorMessages;
  input Boolean throwNoError;
  output list<BackendDAE.EqSystem> systs;
  output BackendDAE.Shared oshared;
algorithm
  (systs,oshared) := matchcontinue (isyst,ishared,numErrorMessages,throwNoError)
    local
      BackendDAE.IncidenceMatrix m,mT;
      array<Integer> ixs;
      Boolean b;
      Integer i;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;
    case (syst,shared,_,_)
      equation
        // print("partitionIndependentBlocks: TODO: Implement me\n");
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL(),SOME(funcs));
        ixs = arrayCreate(arrayLength(m),0);
        // ixsT = arrayCreate(arrayLength(mT),0);
        i = partitionIndependentBlocks0(arrayLength(m),0,mT,m,ixs);
        // i2 = partitionIndependentBlocks0(arrayLength(mT),0,mT,m,ixsT);
        b = i > 1;
        // Debug.bcall2(b,BackendDump.dumpBackendDAE,BackendDAE.DAE({syst},shared), "partitionIndependentBlocksHelper");
        // printPartition(b,ixs);
        systs = Debug.bcallret5(b,partitionIndependentBlocksSplitBlocks,i,syst,ixs,mT,throwNoError,{syst});
        // print("Number of partitioned systems: " +& intString(listLength(systs)) +& "\n");
      then (systs,shared);
    else
      equation
        Error.assertion(not (numErrorMessages==Error.getNumErrorMessages()),"BackendDAEOptimize.partitionIndependentBlocks failed without good error message",Absyn.dummyInfo);
      then fail();
  end matchcontinue;
end partitionIndependentBlocksHelper;

protected function partitionIndependentBlocksSplitBlocks
  "Partitions the independent blocks into list<array<...>> by first constructing an array<list<...>> structure for the algorithm complexity"
  input Integer n;
  input BackendDAE.EqSystem syst;
  input array<Integer> ixs;
  input BackendDAE.IncidenceMatrix mT;
  input Boolean throwNoError;
  output list<BackendDAE.EqSystem> systs;
algorithm
  systs := match (n,syst,ixs,mT,throwNoError)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray arr;
      array<list<BackendDAE.Equation>> ea;
      array<list<BackendDAE.Var>> va;
      list<list<BackendDAE.Equation>> el;
      list<list<BackendDAE.Var>> vl;
      Integer i1,i2;
      String s1,s2;
      Boolean b;
    case (_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=arr),_,_,_)
      equation
        ea = arrayCreate(n,{});
        va = arrayCreate(n,{});
        i1 = BackendDAEUtil.equationSize(arr);
        i2 = BackendVariable.numVariables(vars);
        s1 = intString(i1);
        s2 = intString(i2);
        Error.assertionOrAddSourceMessage((i1 == i2) or throwNoError,
          Util.if_(i1 > i2, Error.OVERDET_EQN_SYSTEM, Error.UNDERDET_EQN_SYSTEM),
          {s1,s2}, Absyn.dummyInfo);

        partitionEquations(BackendDAEUtil.equationArraySize(arr),arr,ixs,ea);
        partitionVars(i2,arr,vars,ixs,mT,va);
        el = arrayList(ea);
        vl = arrayList(va);
        (systs,(b,_)) = List.threadMapFold(el,vl,createEqSystem,(true,throwNoError));
        true = throwNoError or b;
      then systs;
  end match;
end partitionIndependentBlocksSplitBlocks;

protected function createEqSystem
  input list<BackendDAE.Equation> el;
  input list<BackendDAE.Var> vl;
  input tuple<Boolean,Boolean> iTpl;
  output BackendDAE.EqSystem syst;
  output tuple<Boolean,Boolean> oTpl;
protected
  BackendDAE.EquationArray arr;
  BackendDAE.Variables vars;
  Integer i1,i2;
  String s1,s2,s3,s4;
  list<String> crs;
  Boolean success,throwNoError;
algorithm
  (success,throwNoError) := iTpl;
  vars := BackendVariable.listVar1(vl);
  arr := BackendEquation.listEquation(el);
  i1 := BackendDAEUtil.equationSize(arr);
  i2 := BackendVariable.numVariables(vars);
  s1 := intString(i1);
  s2 := intString(i2);
  crs := Debug.bcallret3(i1<>i2,List.mapMap,vl,BackendVariable.varCref,ComponentReference.printComponentRefStr,{});
  s3 := stringDelimitList(crs,"\n");
  s4 := Debug.bcallret1(i1<>i2,BackendDump.dumpEqnsStr,el,"");
  // Can this even be triggered? We check that all variables are defined somewhere, so everything should be balanced already?
  Debug.bcall3((i1<>i2) and not throwNoError,Error.addSourceMessage,Error.IMBALANCED_EQUATIONS,{s1,s2,s3,s4},Absyn.dummyInfo);
  syst := BackendDAE.EQSYSTEM(vars,arr,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
  success := success and i1==i2;
  oTpl := (success,throwNoError);
end createEqSystem;

protected function partitionEquations
  input Integer n;
  input BackendDAE.EquationArray arr;
  input array<Integer> ixs;
  input array<list<BackendDAE.Equation>> ea;
algorithm
  _ := match (n,arr,ixs,ea)
    local
      Integer ix;
      list<BackendDAE.Equation> lst;
      BackendDAE.Equation eq;
    case (0,_,_,_) then ();
    case (_,_,_,_)
      equation
        ix = ixs[n];
        lst = ea[ix];
        eq = BackendDAEUtil.equationNth(arr,n-1);
        lst = eq::lst;
        // print("adding eq " +& intString(n) +& " to group " +& intString(ix) +& "\n");
        _ = arrayUpdate(ea,ix,lst);
        partitionEquations(n-1,arr,ixs,ea);
      then ();
  end match;
end partitionEquations;

protected function partitionVars
  input Integer n;
  input BackendDAE.EquationArray arr;
  input BackendDAE.Variables vars;
  input array<Integer> ixs;
  input BackendDAE.IncidenceMatrix mT;
  input array<list<BackendDAE.Var>> va;
algorithm
  _ := match (n,arr,vars,ixs,mT,va)
    local
      Integer ix,eqix;
      list<BackendDAE.Var> lst;
      BackendDAE.Var v;
      Boolean b;
      DAE.ComponentRef cr;
      String name;
      Absyn.Info info;
    case (0,_,_,_,_,_) then ();
    case (_,_,_,_,_,_)
      equation
        v = BackendVariable.getVarAt(vars,n);
        cr = BackendVariable.varCref(v);
        // Select any equation that could define this variable
        b = not List.isEmpty(mT[n]);
        name = Debug.bcallret1(not b,ComponentReference.printComponentRefStr,cr,"");
        info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(v));
        Error.assertionOrAddSourceMessage(b,Error.EQUATIONS_VAR_NOT_DEFINED,{name},info);
        // print("adding var " +& intString(n) +& " to group ???\n");
        eqix::_ = mT[n];
        eqix = intAbs(eqix);
        // print("var " +& intString(n) +& " has eq " +& intString(eqix) +& "\n");
        // That's the index of the indep.system
        ix = ixs[eqix];
        lst = va[ix];
        lst = v::lst;
        // print("adding var " +& intString(n) +& " to group " +& intString(ix) +& " (comes from eq: "+& intString(eqix) +&")\n");
        _ = arrayUpdate(va,ix,lst);
        partitionVars(n-1,arr,vars,ixs,mT,va);
      then ();
  end match;
end partitionVars;

protected function partitionIndependentBlocks0
  input Integer n;
  input Integer n2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Integer on;
algorithm
  on := match (n,n2,m,mT,ixs)
    local
      Boolean b;
    case (0,_,_,_,_) then n2;
    case (_,_,_,_,_)
      equation
        b = partitionIndependentBlocks1(n,n2+1,m,mT,ixs);
      then partitionIndependentBlocks0(n-1,Util.if_(b,n2+1,n2),m,mT,ixs);
  end match;
end partitionIndependentBlocks0;

protected function partitionIndependentBlocks1
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Boolean ochange;
algorithm
  ochange := partitionIndependentBlocks2(ixs[ix] == 0,ix,n,m,mT,ixs);
end partitionIndependentBlocks1;

protected function partitionIndependentBlocks2
  input Boolean b;
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> inIxs;
  output Boolean change;
algorithm
  change := match (b,ix,n,m,mT,inIxs)
    local
      list<Integer> lst;
      list<list<Integer>> lsts;
      array<Integer> ixs;

    case (false,_,_,_,_,_) then false;
    case (true,_,_,_,_,ixs)
      equation
        // i = ixs[ix];
        // print(intString(ix) +& "; update crap\n");
        // print("mark\n");
        ixs = arrayUpdate(ixs,ix,n);
        // print("mark OK\n");
        lst = List.map(mT[ix],intAbs);
        // print(stringDelimitList(List.map(lst,intString),",") +& "\n");
        // print("len:" +& intString(arrayLength(m)) +& "\n");
        lsts = List.map1r(lst,arrayGet,m);
        // print("arrayNth OK\n");
        lst = List.map(List.flatten(lsts),intAbs);
        // print(stringDelimitList(List.map(lst,intString),",") +& "\n");
        // print("lst get\n");
        _ = List.map4(lst,partitionIndependentBlocks1,n,m,mT,ixs);
      then true;
  end match;
end partitionIndependentBlocks2;

protected function arrayUpdateForPartition
  input Integer ix;
  input array<Integer> ixs;
  input Integer val;
  output array<Integer> oixs;
algorithm
  // print("arrayUpdate("+&intString(ix+1)+&","+&intString(val)+&")\n");
  oixs := arrayUpdate(ixs,ix+1,val);
end arrayUpdateForPartition;

protected function printPartition
  input Boolean b;
  input array<Integer> ixs;
algorithm
  _ := match (b,ixs)
    case (true,ixs)
      equation
        print("Got partition!\n");
        print(stringDelimitList(List.map(arrayList(ixs), intString), ","));
        print("\n");
      then ();
    else ();
  end match;
end printPartition;

public function residualForm
  "Puts equations like x=y in the form of 0=x-y"
  input BackendDAE.BackendDAE dlow;
  output BackendDAE.BackendDAE odlow;
algorithm
  odlow := BackendDAEUtil.mapEqSystem1(dlow,residualForm1,1);
end residualForm;

protected function residualForm1
  "Puts equations like x=y in the form of 0=x-y"
  input BackendDAE.EqSystem syst;
  input Integer i;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
protected
  BackendDAE.EquationArray eqs;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=eqs) := syst;
  (_,_) := BackendEquation.traverseBackendDAEEqnsWithUpdate(eqs, residualForm2, 1);
  osyst := syst;
  oshared := shared;
end residualForm1;

protected function residualForm2
  input tuple<BackendDAE.Equation,Integer> tpl;
  output tuple<BackendDAE.Equation,Integer> otpl;
algorithm
  otpl := matchcontinue tpl
    local
      tuple<BackendDAE.Equation,Integer> ntpl;
      DAE.Exp e1,e2,e;
      DAE.ElementSource source;
      Integer i;
      Boolean diffed;
    case ((BackendDAE.EQUATION(e1,e2,source,diffed),i))
      equation
        // This is ok, because EQUATION is not an array equation :D
        DAE.T_REAL(source = _) = Expression.typeof(e1);
        false = Expression.isZero(e1) or Expression.isZero(e2);
        e = DAE.BINARY(e1,DAE.SUB(DAE.T_REAL_DEFAULT),e2);
        (e,_) = ExpressionSimplify.simplify(e);
        source = DAEUtil.addSymbolicTransformation(source, DAE.OP_RESIDUAL(e1,e2,e));
        ntpl = (BackendDAE.EQUATION(DAE.RCONST(0.0),e,source,diffed),i);
      then ntpl;
    else tpl;
  end matchcontinue;
end residualForm2;




// =============================================================================
// simplify time independent function calls
//
// =============================================================================
public function simplifyTimeIndepFuncCalls "function simplifyTimeIndepFuncCalls
  simplifies time independent built in function calls like
  pre(param) -> param
  der(param) -> 0.0
  change(param) -> false
  edge(param) -> false
  author: Frenkel TUD 2012-06"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,simplifyTimeIndepFuncCalls0,false);
  outDAE := simplifyTimeIndepFuncCallsShared(outDAE);
end simplifyTimeIndepFuncCalls;

protected function simplifyTimeIndepFuncCalls0 "function simplifyTimeIndepFuncCalls0
  author: Frenkel TUD 2012-06"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) :=
    matchcontinue(isyst,sharedChanged)
    local
      BackendDAE.Variables orderedVars,knvars,aliasvars;
      BackendDAE.EquationArray orderedEqs;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
      BackendDAE.Shared shared;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching,stateSets),(shared as BackendDAE.SHARED(knownVars = knvars,aliasVars = aliasvars), _))
      equation
        ((_,_,true)) = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(orderedEqs,traversersimplifyTimeIndepFuncCalls,(knvars,aliasvars,false));
      then
        (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching,stateSets),(shared,true));
    else
      (isyst,sharedChanged);
  end matchcontinue;
end simplifyTimeIndepFuncCalls0;

protected function traversersimplifyTimeIndepFuncCalls "function traversersimplifyTimeIndepFuncCalls
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Variables,Boolean>> itpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Variables,Boolean>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,BackendDAE.Variables,Boolean> tpl;
algorithm
  (e,tpl) := itpl;
  outTpl := Expression.traverseExp(e,traverserExpsimplifyTimeIndepFuncCalls,tpl);
end traversersimplifyTimeIndepFuncCalls;

protected function traverserExpsimplifyTimeIndepFuncCalls "function traverserExpsimplifyTimeIndepFuncCalls
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Variables,Boolean>> tpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Variables,Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      BackendDAE.Variables knvars,aliasvars;
      DAE.Type tp;
      DAE.Exp e,zero;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      DAE.CallAttributes attr;
      Boolean negate;
    case((e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr,ty=tp)}),(knvars,aliasvars,_)))
      equation
        (var::{},_) = BackendVariable.getVar(cr, knvars);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        ((zero,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "pre"),expLst={e as DAE.CREF(componentRef=cr)}),(knvars,aliasvars,_)))
      equation
        (_::{},_) = BackendVariable.getVar(cr, knvars);
      then
        ((e,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "pre"),expLst={e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}),(knvars,aliasvars,_)))
      then
        ((e,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "pre"),expLst={e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")))}),(knvars,aliasvars,_)))
      then
        ((e,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "pre"),expLst={DAE.CREF(componentRef=cr,ty=tp)},attr=attr),(knvars,aliasvars,_)))
      equation
        (var::{},_) = BackendVariable.getVar(cr, aliasvars);
        (cr,negate) = BackendVariable.getAlias(var);
        e = DAE.CREF(cr,tp);
        e = Debug.bcallret1(negate,Expression.negate,e,e);
        (e,_) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT("pre"),{e},attr));
        ((e,_)) = Expression.traverseExp(e,traverserExpsimplifyTimeIndepFuncCalls,(knvars,aliasvars,false));
      then
        ((e,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "change"),expLst={e as DAE.CREF(componentRef=cr,ty=tp)}),(knvars,aliasvars,_)))
      equation
        (_::_,_) = BackendVariable.getVar(cr, knvars);
        zero = Expression.arrayFill(Expression.arrayDimension(tp),DAE.BCONST(false));
      then
        ((zero,(knvars,aliasvars,true)));
    case((e as DAE.CALL(path=Absyn.IDENT(name = "change"),expLst={DAE.CREF(componentRef=cr,ty=tp)}),(knvars,aliasvars,_)))
      equation
        (_::_,_) = BackendVariable.getVar(cr, aliasvars);
        zero = Expression.arrayFill(Expression.arrayDimension(tp),DAE.BCONST(false));
      then
        ((zero,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "change"),expLst={e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}),(knvars,aliasvars,_)))
      then
        ((DAE.BCONST(false),(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "change"),expLst={DAE.CREF(componentRef=cr,ty=tp)},attr=attr),(knvars,aliasvars,_)))
      equation
        (var::{},_) = BackendVariable.getVar(cr, aliasvars);
        (cr,negate) = BackendVariable.getAlias(var);
        e = DAE.CREF(cr,tp);
        e = Debug.bcallret1(negate,Expression.negate,e,e);
        (e,_) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT("change"),{e},attr));
        ((e,_)) = Expression.traverseExp(e,traverserExpsimplifyTimeIndepFuncCalls,(knvars,aliasvars,false));
      then
        ((e,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "edge"),expLst={e as DAE.CREF(componentRef=cr,ty=tp)}),(knvars,aliasvars,_)))
      equation
        (_::{},_) = BackendVariable.getVar(cr, knvars);
        zero = Expression.arrayFill(Expression.arrayDimension(tp),DAE.BCONST(false));
      then
        ((zero,(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "edge"),expLst={e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}),(knvars,aliasvars,_)))
      then
        ((DAE.BCONST(false),(knvars,aliasvars,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "edge"),expLst={DAE.CREF(componentRef=cr,ty=tp)},attr=attr),(knvars,aliasvars,_)))
      equation
        (var::{},_) = BackendVariable.getVar(cr, aliasvars);
        (cr,negate) = BackendVariable.getAlias(var);
        e = DAE.CREF(cr,tp);
        e = Debug.bcallret1(negate,Expression.negate,e,e);
        (e,_) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT("edge"),{e},attr));
        ((e,_)) = Expression.traverseExp(e,traverserExpsimplifyTimeIndepFuncCalls,(knvars,aliasvars,false));
      then
        ((e,(knvars,aliasvars,true)));
    case _ then tpl;
  end matchcontinue;
end traverserExpsimplifyTimeIndepFuncCalls;

protected function simplifyTimeIndepFuncCallsShared "function simplifyTimeIndepFuncCallsShared
  simplifies time independent built in function calls like
  pre(param) -> param
  der(param) -> 0.0
  change(param) -> false
  edge(param) -> false
  author: Frenkel TUD 2012-06"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:= match (inDAE)
    local
      BackendDAE.Variables knvars,exobj,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcTree;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,eventInfo,eoc,btp,symjacs)))
      equation
        _ = BackendDAEUtil.traverseBackendDAEExpsVarsWithUpdate(knvars,traversersimplifyTimeIndepFuncCalls,(knvars,aliasVars,false));
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(inieqns,traversersimplifyTimeIndepFuncCalls,(knvars,aliasVars,false));
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(remeqns,traversersimplifyTimeIndepFuncCalls,(knvars,aliasVars,false));
        (eventInfo,_) = traverseEventInfoExps(eventInfo,traversersimplifyTimeIndepFuncCalls,(knvars,aliasVars,false));
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,eventInfo,eoc,btp,symjacs));
  end match;
end simplifyTimeIndepFuncCallsShared;

protected function traverseEventInfoExps
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EventInfo iEventInfo;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.EventInfo oEventInfo;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
protected
  BackendDAE.SampleLookup sampleLookup;
  list<BackendDAE.WhenClause> whenClauseLst;
  list<BackendDAE.ZeroCrossing> zeroCrossingLst,sampleLst,relationsLst;
  Integer relationsNumber,numberMathEvents;
algorithm
  BackendDAE.EVENT_INFO(sampleLookup,whenClauseLst,zeroCrossingLst,sampleLst,relationsLst,relationsNumber,numberMathEvents) := iEventInfo;
  (whenClauseLst,outTypeA) := traverseWhenClauseExps(whenClauseLst,func,inTypeA,{});
  (zeroCrossingLst,outTypeA) := traverseZeroCrossingExps(zeroCrossingLst,func,outTypeA,{});
  (sampleLst,outTypeA) := traverseZeroCrossingExps(sampleLst,func,outTypeA,{});
  (relationsLst,outTypeA) := traverseZeroCrossingExps(relationsLst,func,outTypeA,{});
  oEventInfo := BackendDAE.EVENT_INFO(sampleLookup,whenClauseLst,zeroCrossingLst,sampleLst,relationsLst,relationsNumber,numberMathEvents);
end traverseEventInfoExps;

protected function traverseWhenClauseExps
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.WhenClause> iWhenClauses;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<BackendDAE.WhenClause> iAcc;
  output list<BackendDAE.WhenClause> oWhenClauses;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (oWhenClauses,outTypeA) := match(iWhenClauses,func,inTypeA,iAcc)
    local
      list<BackendDAE.WhenClause> whenClause;
      DAE.Exp condition;
      list<BackendDAE.WhenOperator> reinitStmtLst;
      Option<Integer> elseClause;
      Type_a arg;
    case({},_,_,_) then (listReverse(iAcc),inTypeA);
    case(BackendDAE.WHEN_CLAUSE(condition,reinitStmtLst,elseClause)::whenClause,_,_,_)
      equation
        ((condition,arg)) = Expression.traverseExp(condition,func,inTypeA);
        (whenClause,arg) = traverseWhenClauseExps(whenClause,func,arg,BackendDAE.WHEN_CLAUSE(condition,reinitStmtLst,elseClause)::iAcc);
      then
        (whenClause,arg);
  end match;
end traverseWhenClauseExps;

protected function traverseZeroCrossingExps
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.ZeroCrossing> iZeroCrossing;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<BackendDAE.ZeroCrossing> iAcc;
  output list<BackendDAE.ZeroCrossing> oZeroCrossing;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (oZeroCrossing,outTypeA) := match(iZeroCrossing,func,inTypeA,iAcc)
    local
      list<BackendDAE.ZeroCrossing> zeroCrossing;
      DAE.Exp relation_;
      list<Integer> occurEquLst,occurWhenLst;
      Type_a arg;
    case({},_,_,_) then (listReverse(iAcc),inTypeA);
    case(BackendDAE.ZERO_CROSSING(relation_,occurEquLst,occurWhenLst)::zeroCrossing,_,_,_)
      equation
        ((relation_,arg)) = Expression.traverseExp(relation_,func,inTypeA);
        (zeroCrossing,arg) = traverseZeroCrossingExps(zeroCrossing,func,arg,BackendDAE.ZERO_CROSSING(relation_,occurEquLst,occurWhenLst)::iAcc);
      then
        (zeroCrossing,arg);
  end match;
end traverseZeroCrossingExps;

// =============================================================================
// section for tearing
//
// =============================================================================

// =============================================================================
// countOperations
//
// =============================================================================
public function countOperations "function countOperations
  author: Frenkel TUD 2011-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    case (_)
      equation
        true = Flags.isSet(Flags.COUNT_OPERATIONS);
        (outDAE,_) = BackendDAEUtil.mapEqSystemAndFold(inDAE,countOperations0,false);
      then
        outDAE;
    else then inDAE;
  end matchcontinue;
end countOperations;

protected function countOperations0 "function countOperations0
  author: Frenkel TUD 2011-05"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) :=
    match(isyst,sharedChanged)
    local
      BackendDAE.Shared shared;
      Boolean b;
      Integer i1,i2,i3;
      BackendDAE.StrongComponents comps;

    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),(shared, b))
      equation
        ((i1,i2,i3)) = countOperationstraverseComps(comps,isyst,shared,(0,0,0));
        print("Add Operations: " +& intString(i1) +& "\n");
        print("Mul Operations: " +& intString(i2) +& "\n");
        print("Oth Operations: " +& intString(i3) +& "\n");
      then
        (isyst,(shared,b));
  end match;
end countOperations0;

protected function countOperations1 "function countOperations1
  author: Frenkel TUD 2011-05
  count the mathematical operations ((+,-),(*,/),(other))"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  outTpl:=
  matchcontinue (isyst,ishared,inTpl)
    local
      BackendDAE.Shared shared;
      array<DAE.ClassAttributes> clsAttrs;
      BackendDAE.EquationArray eqns;

    case (BackendDAE.EQSYSTEM(orderedEqs = eqns),shared,_)
      then
        BackendDAEUtil.traverseBackendDAEExpsEqns(eqns,countOperationsExp,inTpl);
  end matchcontinue;
end countOperations1;

protected function countOperationstraverseComps "function countOperationstraverseComps
  author: Frenkel TUD 2012-05"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  outTpl :=
  matchcontinue (inComps,isyst,ishared,inTpl)
    local
      Integer e;
      BackendDAE.StrongComponent comp,comp1;
      BackendDAE.StrongComponents rest;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      tuple<Integer,Integer,Integer> tpl;
      list<BackendDAE.Equation> eqnlst;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      list<BackendDAE.Var> varlst;
      list<DAE.Exp> explst;
      DAE.FunctionTree funcs;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
      list<Integer> vlst;
    case ({},_,_,_) then inTpl;
    case (BackendDAE.SINGLEEQUATION(eqn=e)::rest,_,_,_)
      equation
        eqns = BackendEquation.daeEqns(isyst);
        eqn = BackendDAEUtil.equationNth(eqns, e-1);
        (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case ((comp as BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1))::rest,_,_,_)
      equation
        tpl = countOperationstraverseComps({comp1},isyst,ishared,inTpl);
        (eqnlst,_,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.daeEqns(isyst), BackendVariable.daeVars(isyst));
        tpl = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendEquation.listEquation(eqnlst),countOperationsExp,tpl);
      then
        countOperationstraverseComps(rest,isyst,ishared,tpl);
    case ((comp as BackendDAE.EQUATIONSYSTEM(jac=jac,jacType=BackendDAE.JAC_TIME_VARYING()))::rest,_,BackendDAE.SHARED(functionTree=funcs),_)
      equation
        (eqnlst,varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.daeEqns(isyst), BackendVariable.daeVars(isyst));
        tpl = addJacSpecificOperations(listLength(eqnlst),inTpl);
        tpl = countOperationsJac(jac,tpl);
        (explst,_) = BackendDAEUtil.getEqnSysRhs(BackendEquation.listEquation(eqnlst),BackendVariable.listVar1(varlst),SOME(funcs));
        ((_,tpl)) = Expression.traverseExpList(explst,countOperationsExp,tpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case ((comp as BackendDAE.EQUATIONSYSTEM(jac=_))::rest,_,_,_)
      equation
        (eqnlst,_,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.daeEqns(isyst), BackendVariable.daeVars(isyst));
        tpl = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendEquation.listEquation(eqnlst),countOperationsExp,inTpl);
      then
        countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (BackendDAE.SINGLEARRAY(eqn=e)::rest,_,_,_)
      equation
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (BackendDAE.SINGLEIFEQUATION(eqn=e)::rest,_,_,_)
      equation
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (BackendDAE.SINGLEALGORITHM(eqn=e)::rest,_,_,_)
      equation
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e)::rest,_,_,_)
      equation
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e)::rest,_,_,_)
      equation
         eqn = BackendDAEUtil.equationNth(BackendEquation.daeEqns(isyst), e-1);
         (_,tpl) = BackendEquation.traverseBackendDAEExpsEqn(eqn,countOperationsExp,inTpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case ((comp as BackendDAE.TORNSYSTEM(tearingvars=vlst, otherEqnVarTpl=eqnvartpllst, linear=_))::rest,_,BackendDAE.SHARED(functionTree=funcs),_)
      equation
        (eqnlst,varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.daeEqns(isyst), BackendVariable.daeVars(isyst));
        tpl = addJacSpecificOperations(listLength(vlst),inTpl);
        (explst,_) = BackendDAEUtil.getEqnSysRhs(BackendEquation.listEquation(eqnlst),BackendVariable.listVar1(varlst),SOME(funcs));
        ((_,tpl)) = Expression.traverseExpList(explst,countOperationsExp,tpl);
      then
         countOperationstraverseComps(rest,isyst,ishared,tpl);
    case (_::rest,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDAEOptimize.countOperationstraverseComps failed!");
      then
         countOperationstraverseComps(rest,isyst,ishared,inTpl);
    case (_::rest,_,_,_)
      then
        countOperationstraverseComps(rest,isyst,ishared,inTpl);
  end matchcontinue;
end countOperationstraverseComps;

protected function countOperationsJac
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inJac;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  outTpl := match(inJac,inTpl)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      case (NONE(),_) then inTpl;
      case (SOME(jac),_)
        then List.fold(jac,countOperationsJac1,inTpl);
  end match;
end countOperationsJac;

protected function countOperationsJac1
  input tuple<Integer, Integer, BackendDAE.Equation> inJac;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
algorithm
  (_,outTpl) := BackendEquation.traverseBackendDAEExpsEqn(Util.tuple33(inJac),countOperationsExp,inTpl);
end countOperationsJac1;

protected function addJacSpecificOperations
  input Integer n;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
protected
  Integer i1,i2,i3,i1_1,i2_1,n2,n3;
algorithm
  (i1,i2,i3) := inTpl;
  n2 := n*n;
  n3 := n*n*n;
  i1_1 := intDiv(2*n3+3*n2-5*n,6) + i1;
  i2_1 := intDiv(2*n3+6*n2-2*n,6) + i2;
  outTpl := (i1_1,i2_1,i3);
end addJacSpecificOperations;

protected function countOperationsExp
  input tuple<DAE.Exp, tuple<Integer,Integer,Integer>> inTpl;
  output tuple<DAE.Exp, tuple<Integer,Integer,Integer>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      DAE.Exp exp;
      Integer i1,i2,i3,i1_1,i2_1,i3_1;
    case ((exp,(i1,i2,i3))) equation
      ((_,(i1_1,i2_1,i3_1))) = Expression.traverseExp(exp,traversecountOperationsExp,(i1,i2,i3));
    then ((exp,(i1_1,i2_1,i3_1)));
    case _ then inTpl;
  end matchcontinue;
end countOperationsExp;

protected function traversecountOperationsExp
  input tuple<DAE.Exp, tuple<Integer,Integer,Integer>> inTuple;
  output tuple<DAE.Exp, tuple<Integer,Integer,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      Integer i1,i2,i3,i1_1,i2_1,i3_1,iexp2;
      Real rexp2;
      DAE.Operator op;
    case ((e as DAE.BINARY(operator=DAE.POW(ty=_),exp2=DAE.RCONST(rexp2)),(i1,i2,i3))) equation
      iexp2 = realInt(rexp2);
      true = realEq(rexp2, intReal(iexp2));
      i2_1 = i2+intAbs(iexp2)-1;
      then ((e, (i1,i2_1,i3)));
    case ((e as DAE.BINARY(operator=op),(i1,i2,i3))) equation
      (i1_1,i2_1,i3_1) = countOperator(op,i1,i2,i3);
      then ((e, (i1_1,i2_1,i3_1)));
    case _ then inTuple;
  end matchcontinue;
end traversecountOperationsExp;

protected function countOperator
  input DAE.Operator op;
  input Integer inInt1;
  input Integer inInt2;
  input Integer inInt3;
  output Integer outInt1;
  output Integer outInt2;
  output Integer outInt3;
algorithm
  (outInt1,outInt2,outInt3) := match(op, inInt1, inInt2, inInt3)
    local
      DAE.Type tp;
      Integer i;
    case (DAE.ADD(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.SUB(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.MUL(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.DIV(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.POW(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.UMINUS(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.UMINUS_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2,inInt3+i);
    case (DAE.ADD_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1+i,inInt2,inInt3);
    case (DAE.SUB_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1+i,inInt2,inInt3);
    case (DAE.MUL_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2+i,inInt3);
    case (DAE.DIV_ARR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2+i,inInt3);
    case (DAE.MUL_ARRAY_SCALAR(ty=tp),_,_,_) equation
      i = Expression.sizeOf(tp);
      then (inInt1,inInt2+i,inInt3);
    case (DAE.ADD_ARRAY_SCALAR(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.SUB_SCALAR_ARRAY(ty=_),_,_,_)
      then (inInt1+1,inInt2,inInt3);
    case (DAE.MUL_SCALAR_PRODUCT(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.MUL_MATRIX_PRODUCT(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.DIV_ARRAY_SCALAR(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.DIV_SCALAR_ARRAY(ty=_),_,_,_)
      then (inInt1,inInt2+1,inInt3);
    case (DAE.POW_ARRAY_SCALAR(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.POW_SCALAR_ARRAY(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.POW_ARR(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.POW_ARR2(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.AND(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.OR(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.NOT(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.NOT(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.LESS(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.LESSEQ(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.GREATER(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.GREATEREQ(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.EQUAL(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.NEQUAL(ty=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    case (DAE.USERDEFINED(fqName=_),_,_,_)
      then (inInt1,inInt2,inInt3+1);
    else
      then(inInt1,inInt2,inInt3+1);
  end match;
end countOperator;


// =============================================================================
// simplify if equations
//
// =============================================================================

public function simplifyIfEquations
"function: simplifyIfEquations
  author: Frenkel TUD 2012-07
  This function traveres all if equations and if expressions and tries to simplify it by using the
  information from evaluation of parameters"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem(dae,simplifyIfEquationsWork);
end simplifyIfEquations;

protected function simplifyIfEquationsWork
"function: simplifyIfEquationsWork
  author: Frenkel TUD 2012-07
  This function traveres all if equations and tries to simplify it by using the
  information from evaluation of parameters"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := matchcontinue (isyst,ishared)
    local
      BackendDAE.Variables vars,knvars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> eqnslst,asserts;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets),shared as BackendDAE.SHARED(knownVars=knvars))
      equation
        // traverse the equations
        eqnslst = BackendEquation.equationList(eqns);
        // traverse equations in reverse order, than branch equations of if equaitions need no reverse
        ((eqnslst,asserts,true)) = List.fold1(listReverse(eqnslst), simplifyIfEquationsFinder, knvars, ({},{},false));
        eqns = BackendEquation.listEquation(eqnslst);
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets);
        shared = BackendEquation.requationsAddDAE(asserts,shared);
      then (syst,shared);
    case (_,_)
      then (isyst,ishared);
  end matchcontinue;
end simplifyIfEquationsWork;

protected function simplifyIfEquationsFinder
"function: simplifyIfEquationsFinder
  author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input BackendDAE.Equation inElem;
  input BackendDAE.Variables inConstArg;
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,Boolean> inArg;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,Boolean> outArg;
algorithm
  outArg := matchcontinue(inElem,inConstArg,inArg)
    local
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqnslst,acc,asserts,asserts1;
      list<list<BackendDAE.Equation>> eqnslstlst;
      DAE.ElementSource source;
      BackendDAE.Variables knvars;
      Boolean b;
      BackendDAE.Equation eqn;
    case (BackendDAE.IF_EQUATION(conditions=explst, eqnstrue=eqnslstlst, eqnsfalse=eqnslst, source=source),knvars,(acc,asserts,_))
      equation
        // check conditions
        ((explst,_)) = Expression.traverseExpList(explst, simplifyevaluatedParamter, (knvars,false));
        explst = ExpressionSimplify.simplifyList(explst, {});
        // simplify if equation
        (acc,asserts1) = simplifyIfEquation(explst,eqnslstlst,eqnslst,{},{},source,knvars,acc);
        asserts = listAppend(asserts,asserts1);
      then
        ((acc,asserts,true));
    case (eqn,knvars,(acc,asserts,b))
      equation
        (eqn,(_,b)) = BackendEquation.traverseBackendDAEExpsEqn(eqn, simplifyIfExpevaluatedParamter, (knvars,b));
      then
        ((eqn::acc,asserts,b));
  end matchcontinue;
end simplifyIfEquationsFinder;

protected function simplifyIfExpevaluatedParamter
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean>> tpl1;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean>> tpl2;
algorithm
  tpl2 := matchcontinue(tpl1)
    local
      BackendDAE.Variables knvars;
      DAE.Exp e,cond,expThen,expElse;
      Boolean b,b1;
    case ((e as DAE.IFEXP(expCond=cond, expThen=expThen, expElse=expElse),(knvars,b)))
      equation
        ((cond,(_,b1))) = Expression.traverseExp(cond, simplifyevaluatedParamter, (knvars,false));
        e = Util.if_(b1,DAE.IFEXP(cond,expThen,expElse),e);
        (e,_) = ExpressionSimplify.condsimplify(b1,e);
      then
        ((e,(knvars,b or b1)));
    case _ then tpl1;
  end matchcontinue;
end simplifyIfExpevaluatedParamter;

protected function simplifyevaluatedParamter
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean>> tpl1;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean>> tpl2;
algorithm
  tpl2 := matchcontinue(tpl1)
    local
      BackendDAE.Variables knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      DAE.Exp e;
      Boolean b;
    case ((DAE.CREF(componentRef = cr),(knvars,_)))
      equation
        (v::{},_::{}) = BackendVariable.getVar(cr,knvars);
        true = BackendVariable.isFinalVar(v);
        e = BackendVariable.varBindExpStartValue(v);
      then
        ((e,(knvars,true)));
    case _ then tpl1;
  end matchcontinue;
end simplifyevaluatedParamter;

protected function simplifyIfEquation
"function: simplifyIfEquation
  author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input list<BackendDAE.Equation> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<BackendDAE.Equation>> theneqns1;
  input DAE.ElementSource source;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outAsserts;
algorithm
  (outEqns,outAsserts) := match(conditions,theneqns,elseenqs,conditions1,theneqns1,source,knvars,inEqns)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns,elseenqs1,asserts;

    // no true case left with condition<>false
    case ({},{},_,{},{},_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold1(listReverse(elseenqs), simplifyIfEquationsFinder, knvars, ({},{},false));
      then
        (listAppend(eqns,inEqns),asserts);
    // true case left with condition<>false
    case ({},{},_,_,_,_,_,_)
      equation
        explst = listReverse(conditions1);
        eqnslst = listReverse(theneqns1);
        // simplify nested if equations
        ((elseenqs1,asserts,_)) = List.fold1(listReverse(elseenqs), simplifyIfEquationsFinder, knvars, ({},{},false));
        elseenqs1 = listAppend(elseenqs1,asserts);
        (eqnslst,elseenqs1,asserts) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs1,{},{},{});
        eqns = simplifyIfEquation1(explst,eqnslst,elseenqs1,source,knvars,inEqns);
      then
        (eqns,asserts);
    // if true and first use it
    case(DAE.BCONST(true)::_,eqns::_,_,{},_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold1(listReverse(eqns), simplifyIfEquationsFinder, knvars, ({},{},false));
      then
        (listAppend(eqns,inEqns),asserts);
    // if true and not first use it as new else
    case(DAE.BCONST(true)::_,eqns::_,_,_,_,_,_,_)
      equation
        explst = listReverse(conditions1);
        eqnslst = listReverse(theneqns1);
        // simplify nested if equations
        ((elseenqs1,asserts,_)) = List.fold1(listReverse(eqns), simplifyIfEquationsFinder, knvars, ({},{},false));
        elseenqs1 = listAppend(elseenqs1,asserts);
        (eqnslst,elseenqs1,asserts) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs1,{},{},{});
        eqns = simplifyIfEquation1(explst,eqnslst,elseenqs1,source,knvars,inEqns);
      then
        (eqns,asserts);
    // if false skip it
    case(DAE.BCONST(false)::explst,_::eqnslst,_,_,_,_,_,_)
      equation
        (eqns,asserts) = simplifyIfEquation(explst,eqnslst,elseenqs,conditions1,theneqns1,source,knvars,inEqns);
      then
        (eqns,asserts);
    // all other cases
    case(e::explst,eqns::eqnslst,_,_,_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold1(listReverse(eqns), simplifyIfEquationsFinder, knvars, ({},{},false));
        eqns = listAppend(eqns,asserts);
        (eqns,asserts) = simplifyIfEquation(explst,eqnslst,elseenqs,e::conditions1,eqns::theneqns1,source,knvars,inEqns);
      then
        (eqns,asserts);
  end match;
end simplifyIfEquation;

protected function simplifyIfEquation1
"function: simplifyIfEquation1
  author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input list<BackendDAE.Equation> elseenqs;
  input DAE.ElementSource source;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(conditions,theneqns,elseenqs,source,knvars,inEqns)
    local
      DAE.Exp e;
      list<DAE.Exp> explst,fbsExp;
      list<list<DAE.Exp>> tbsExp;
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns;
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> crexplst;

    // true case left with condition<>false
    case (_,_,_,_,_,_)
      equation
        _ = countEquationsInBranches(theneqns,elseenqs,source);
        // simplify if eqution
        // if .. then a=.. elseif .. then a=... else a=.. end if;
        // to
        // a=if .. then .. else if .. then else ..;
        ht = HashTable2.emptyHashTable();
        ht = simplifySolvedIfEqnsElse(elseenqs,ht);
        ht = simplifySolvedIfEqns(listReverse(conditions),listReverse(theneqns),ht);
        crexplst = BaseHashTable.hashTableList(ht);
        eqns = simplifySolvedIfEqns2(crexplst,inEqns);
        // ToDo: check if the same cref is not used more than once on the lhs, merge sources
      then
        eqns;
    case (_,_,_,_,_,_)
      equation
        _ = countEquationsInBranches(theneqns,elseenqs,source);
        fbsExp = makeEquationLstToResidualExpLst(elseenqs);
        tbsExp = List.map(theneqns, makeEquationLstToResidualExpLst);
        eqns = makeEquationsFromResiduals(conditions, tbsExp, fbsExp, source);
      then
        listAppend(eqns,inEqns);
    case (_,_,_,_,_,_)
      then
        BackendDAE.IF_EQUATION(conditions,theneqns,elseenqs,source)::inEqns;
  end matchcontinue;
end simplifyIfEquation1;

protected function simplifySolvedIfEqns2
  input list<tuple<DAE.ComponentRef,DAE.Exp>> crexplst;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := match(crexplst,inEqns)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,crexp;
      list<tuple<DAE.ComponentRef,DAE.Exp>> rest;
    case ({},_)
      then
        inEqns;
    case ((cr,e)::rest,_)
      equation
        crexp = Expression.crefExp(cr);
      then
       simplifySolvedIfEqns2(rest,BackendDAE.EQUATION(crexp,e,DAE.emptyElementSource,false)::inEqns);
  end match;
end simplifySolvedIfEqns2;

protected function simplifySolvedIfEqns
"function: simplifySolvedIfEqns
  author: Frenkel TUD 2012-10
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input HashTable2.HashTable iHt;
  output HashTable2.HashTable oHt;
algorithm
  oHt := match(conditions,theneqns,iHt)
    local
      HashTable2.HashTable ht;
      DAE.Exp c;
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> rest;
    case ({},{},_)
      then
        iHt;
    case (c::explst,eqns::rest,_)
      equation
        ht = simplifySolvedIfEqns1(c,eqns,iHt);
      then
        simplifySolvedIfEqns(explst,rest,ht);
  end match;
end simplifySolvedIfEqns;

protected function simplifySolvedIfEqns1
"function: simplifySolvedIfEqns1
  author: Frenkel TUD 2012-10
  helper for simplifyIfEquations"
  input DAE.Exp condition;
  input list<BackendDAE.Equation> brancheqns;
  input HashTable2.HashTable iHt;
  output HashTable2.HashTable oHt;
algorithm
  oHt := match(condition,brancheqns,iHt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,exp;
      DAE.ElementSource source;
      HashTable2.HashTable ht;
      list<BackendDAE.Equation> rest;
    case (_,{},_)
      then
        iHt;
    case (_,BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e, source=source)::rest,_)
      equation
        false = Expression.expHasCref(e, cr);
        exp = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        ht = BaseHashTable.add((cr,exp), iHt);
      then
        simplifySolvedIfEqns1(condition,rest,ht);
    case (_,BackendDAE.EQUATION(exp=DAE.UNARY(operator=DAE.UMINUS(ty=_), exp=DAE.CREF(componentRef=cr)), scalar=e, source=source)::rest,_)
      equation
        false = Expression.expHasCref(e, cr);
        exp = BaseHashTable.get(cr, iHt);
        e = Expression.negate(e);
        exp = DAE.IFEXP(condition, e, exp);
        ht = BaseHashTable.add((cr,exp), iHt);
      then
        simplifySolvedIfEqns1(condition,rest,ht);
  end match;
end simplifySolvedIfEqns1;

protected function simplifySolvedIfEqnsElse
"function: simplifySolvedIfEqnsElse
  author: Frenkel TUD 2012-10
  helper for simplifyIfEquations"
  input list<BackendDAE.Equation> elseenqs;
  input HashTable2.HashTable iHt;
  output HashTable2.HashTable oHt;
algorithm
  oHt := match(elseenqs,iHt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      DAE.ElementSource source;
      HashTable2.HashTable ht;
      list<BackendDAE.Equation> rest;
    case ({},_)
      then
        iHt;
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e, source=source)::rest,_)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCref(e, cr);
        ht = BaseHashTable.add((cr,e), iHt);
      then
        simplifySolvedIfEqnsElse(rest,ht);
    case (BackendDAE.EQUATION(exp=DAE.UNARY(operator=DAE.UMINUS(ty=_), exp=DAE.CREF(componentRef=cr)), scalar=e, source=source)::rest,_)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCref(e, cr);
        e = Expression.negate(e);
        ht = BaseHashTable.add((cr,e), iHt);
      then
        simplifySolvedIfEqnsElse(rest,ht);
  end match;
end simplifySolvedIfEqnsElse;

protected function simplifyIfEquationAsserts
"function: simplifyIfEquationAsserts
  author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input list<BackendDAE.Equation> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<BackendDAE.Equation>> theneqns1;
  input list<BackendDAE.Equation> inEqns;
  output list<list<BackendDAE.Equation>> otheneqns;
  output list<BackendDAE.Equation> oelseenqs;
  output list<BackendDAE.Equation> outEqns;
algorithm
  (otheneqns,oelseenqs,outEqns) := match(conditions,theneqns,elseenqs,conditions1,theneqns1,inEqns)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqns,eqns1,beqns;
      list<list<BackendDAE.Equation>> eqnslst,eqnslst1;

    case (_,{},_,_,_,_)
      equation
        (beqns,eqns) = simplifyIfEquationAsserts1(elseenqs,NONE(),conditions1,{},inEqns);
      then
        (listReverse(theneqns1),beqns,eqns);
    case (e::explst,eqns::eqnslst,_,_,_,_)
      equation
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,SOME(e),conditions1,{},inEqns);
        (eqnslst1,eqns1,eqns) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs,e::conditions1,beqns::theneqns1,eqns);
      then
        (eqnslst1,eqns1,eqns);
  end match;
end simplifyIfEquationAsserts;

protected function simplifyIfEquationAsserts1
"function: simplifyIfEquationAsserts1
  author: Frenkel TUD 2012-07
  helper for simplifyIfEquationAsserts"
  input list<BackendDAE.Equation> brancheqns;
  input Option<DAE.Exp> condition;
  input list<DAE.Exp> conditions "reversed";
  input list<BackendDAE.Equation> brancheqns1;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> obrancheqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  (obrancheqns,outEqns) := match(brancheqns,condition,conditions,brancheqns1,inEqns)
    local
      DAE.Exp e,cond,msg,level;
      list<DAE.Exp> explst;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns,beqns;
      list<list<BackendDAE.Equation>> eqnslst;
      Integer size;
      DAE.ElementSource source,source1;
    case ({},_,_,_,_)
      then
        (listReverse(brancheqns1),inEqns);
    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond=cond,msg=msg,level=level,source=source1)}),source=source)::eqns,NONE(),_,_,_)
      equation
        e = List.fold(conditions,makeIfExp,cond);
        (beqns,eqns) =  simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(e,msg,level,source1)}),source)::inEqns);
      then
        (beqns,eqns);
    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond=cond,msg=msg,level=level,source=source1)}),source=source)::eqns,SOME(e),_,_,_)
      equation
        e = DAE.IFEXP(e,cond,DAE.BCONST(true));
        e = List.fold(conditions,makeIfExp,e);
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(e,msg,level,source1)}),source)::inEqns);
      then
        (beqns,eqns);
    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg=msg,source=source1)}),source=source)::eqns,NONE(),_,_,_)
      equation
        e = List.fold(conditions,makeIfExp,DAE.BCONST(true));
        (beqns,eqns) =  simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_IF(e,{DAE.STMT_TERMINATE(msg,source1)},DAE.NOELSE(),source1)}),source)::inEqns);
      then
        (beqns,eqns);
    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg=msg,source=source1)}),source=source)::eqns,SOME(e),_,_,_)
      equation
        e = List.fold(conditions,makeIfExp,e);
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_IF(e,{DAE.STMT_TERMINATE(msg,source1)},DAE.NOELSE(),source1)}),source)::inEqns);
      then
        (beqns,eqns);
    case (eqn::eqns,_,_,_,_)
      equation
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,condition,conditions,eqn::brancheqns1,inEqns);
      then
        (beqns,eqns);
  end match;
end simplifyIfEquationAsserts1;

protected function makeIfExp
  input DAE.Exp cond;
  input DAE.Exp else_;
  output DAE.Exp oExp;
algorithm
  oExp := DAE.IFEXP(cond,DAE.BCONST(true),else_);
end makeIfExp;

protected function countEquationsInBranches "
Checks that the number of equations is the same in all branches
of an if-equation"
  input list<list<BackendDAE.Equation>> trueBranches;
  input list<BackendDAE.Equation> falseBranch;
  input DAE.ElementSource source;
  output Integer nrOfEquations;
algorithm
  nrOfEquations := matchcontinue(trueBranches,falseBranch,source)
    local
      list<Boolean> b;
      list<String> strs;
      String str,eqstr;
      list<Integer> nrOfEquationsBranches;
    case (_,_,_)
      equation
        nrOfEquations = BackendEquation.equationLstSize(falseBranch);
        nrOfEquationsBranches = List.map(trueBranches, BackendEquation.equationLstSize);
        b = List.map1(nrOfEquationsBranches, intEq, nrOfEquations);
        true = List.reduce(b,boolAnd);
      then (nrOfEquations);
    case (_,_,_)
      equation
        nrOfEquations = BackendEquation.equationLstSize(falseBranch);
        nrOfEquationsBranches = List.map(trueBranches, BackendEquation.equationLstSize);
        eqstr = stringDelimitList(List.map(listAppend(trueBranches,{falseBranch}),BackendDump.dumpEqnsStr),"\n");
        strs = List.map(nrOfEquationsBranches, intString);
        str = stringDelimitList(strs,",");
        str = "{" +& str +& "," +& intString(nrOfEquations) +& "}";
        Error.addSourceMessage(Error.IF_EQUATION_UNBALANCED_2,{str,eqstr},DAEUtil.getElementSourceFileInfo(source));
      then fail();
  end matchcontinue;
end countEquationsInBranches;

protected function makeEquationLstToResidualExpLst
  input list<BackendDAE.Equation> eqLst;
  output list<DAE.Exp> oExpLst;
algorithm
  oExpLst := matchcontinue(eqLst)
    local
      list<BackendDAE.Equation> rest;
      list<DAE.Exp> exps1,exps2,exps;
      BackendDAE.Equation eq;
      DAE.ElementSource source;
      String str;
    case ({}) then {};
    case ((eq as BackendDAE.ALGORITHM(source = source))::rest)
      equation
        str = BackendDump.equationString(eq);
        str = Util.stringReplaceChar(str,"\n","");
        Error.addSourceMessage(Error.IF_EQUATION_WARNING,{str},DAEUtil.getElementSourceFileInfo(source));
        exps = makeEquationLstToResidualExpLst(rest);
      then exps;
    case (eq::rest)
      equation
        exps1 = makeEquationToResidualExpLst(eq);
        exps2 = makeEquationLstToResidualExpLst(rest);
        exps = listAppend(exps1,exps2);
      then
        exps;
  end matchcontinue;
end makeEquationLstToResidualExpLst;

protected function makeEquationToResidualExpLst "
If-equations with more than 1 equation in each branch cannot be transformed
to a single equation with residual if-expression. This function translates such
equations to a list of residual if-expressions. Normal equations are translated
to a list with a single residual expression."
  input BackendDAE.Equation eq;
  output list<DAE.Exp> oExpLst;
algorithm
  oExpLst := matchcontinue(eq)
    local
      list<list<BackendDAE.Equation>> tbs;
      list<BackendDAE.Equation> fbs;
      list<DAE.Exp> conds, fbsExp,exps;
      list<list<DAE.Exp>> tbsExp;
      BackendDAE.Equation elt;
      DAE.Exp exp;

    case (BackendDAE.IF_EQUATION(conditions=conds,eqnstrue=tbs,eqnsfalse=fbs))
      equation
        fbsExp = makeEquationLstToResidualExpLst(fbs);
        tbsExp = List.map(tbs, makeEquationLstToResidualExpLst);
        exps = makeResidualIfExpLst(conds,tbsExp,fbsExp);
      then
        exps;
    case (elt)
      equation
        exp=makeEquationToResidualExp(elt);
      then
        {exp};
  end matchcontinue;
end makeEquationToResidualExpLst;

protected function makeResidualIfExpLst
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Exp>> inExpLst2;
  input list<DAE.Exp> inExpLst3;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match (inExp1,inExpLst2,inExpLst3)
    local
      list<list<DAE.Exp>> tbs,tbsRest;
      list<DAE.Exp> tbsFirst,fbs,rest_res;
      list<DAE.Exp> conds;
      DAE.Exp ifexp,fb;

    case (_,tbs,{})
      equation
        List.map_0(tbs, List.assertIsEmpty);
      then {};

    case (conds,tbs,fb::fbs)
      equation
        tbsRest = List.map(tbs,List.rest);
        rest_res = makeResidualIfExpLst(conds, tbsRest, fbs);

        tbsFirst = List.map(tbs,List.first);

        ifexp = Expression.makeNestedIf(conds,tbsFirst,fb);
      then
        (ifexp :: rest_res);
  end match;
end makeResidualIfExpLst;

protected function makeEquationToResidualExp ""
  input BackendDAE.Equation eq;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(eq)
    local
      DAE.Exp e1,e2;
      DAE.ComponentRef cr1;
      String str;
      DAE.Type ty;
    // normal equation
    case(BackendDAE.EQUATION(exp=e1,scalar=e2))
      equation
        ty = Expression.typeof(e1);
        true = Types.isIntegerOrRealOrSubTypeOfEither(ty);
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // equation from array TODO! check if this works!
    case(BackendDAE.ARRAY_EQUATION(left=e1,right=e2))
      equation
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // solved equation
    case(BackendDAE.SOLVED_EQUATION(componentRef=cr1, exp=e2))
      equation
        e1 = Expression.crefExp(cr1);
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // residual equation
    case(BackendDAE.RESIDUAL_EQUATION(exp = oExp))
      then
        oExp;
    // complex equation
    case(BackendDAE.COMPLEX_EQUATION(left = e1, right = e2))
      equation
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // failure
    case _
      equation
        str = "- BackendDAEOptimize.makeEquationToResidualExp failed to transform equation: " +& BackendDump.equationString(eq) +& " to residual form!";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end makeEquationToResidualExp;

protected function makeEquationsFromResiduals
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Exp>> inExpLst2;
  input list<DAE.Exp> inExpLst3;
  input DAE.ElementSource source "the origin of the element";
  output list<BackendDAE.Equation> outExpLst;
algorithm
  outExpLst := match (inExp1,inExpLst2,inExpLst3,source)
    local
      list<list<DAE.Exp>> tbs,tbsRest;
      list<DAE.Exp> tbsFirst,fbs;
      list<DAE.Exp> conds;
      DAE.Exp ifexp,fb;
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> rest_res;
      DAE.ElementSource src;

    case (_,tbs,{},_)
      equation
        List.map_0(tbs, List.assertIsEmpty);
      then {};

    case (conds,tbs,fb::fbs,src)
      equation
        tbsRest = List.map(tbs,List.rest);
        rest_res = makeEquationsFromResiduals(conds, tbsRest,fbs,src);

        tbsFirst = List.map(tbs,List.first);

        ifexp = Expression.makeNestedIf(conds,tbsFirst,fb);
        eq = BackendDAE.EQUATION(DAE.RCONST(0.0),ifexp,src,false);
      then
        (eq :: rest_res);
  end match;
end makeEquationsFromResiduals;


// =============================================================================
// simplify semiLinear calls
//
// =============================================================================

public function simplifysemiLinear
"function: simplifysemiLinear
  author: Frenkel TUD 2012-08
  This function traveres all equations and tries to simplify calls to semiLinear"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem(dae,simplifysemiLinearWork);
end simplifysemiLinear;

protected function simplifysemiLinearWork "function simplifysemiLinearWork
  author: Frenkel TUD 2012-08
  This function traveres all equations and tries to simplify calls to semiLinear"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := matchcontinue (isyst,ishared)
    local
      BackendDAE.Variables vars,knvars;
      BackendDAE.EquationArray eqns;
      list<tuple<BackendDAE.Equation,Integer>> eqnslst;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Boolean b;
      HashTableExpToIndex.HashTable ht;
      array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets),shared)
      equation
        // traverse the equations and collect all semiLinear calls  y=semiLinear(x,sa,sb)
        (eqns,(eqnslst,_,true)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,simplifysemiLinearFinder,({},0,false));
        // sort for (y,x) pairs
        eqnsarray = arrayCreate(5,{});
        ht = HashTableExpToIndex.emptyHashTable();
        eqnsarray = semiLinearSort(eqnslst,ht,1,eqnsarray);
        eqnsarray = semiLinearSort1(arrayList(eqnsarray),1,arrayCreate(5,{}));
        // optimize
        // y = semiLinear(x,sa,s1)
        // y = semiLinear(x,s1,s2)
        // y = semiLinear(x,s2,s3)
        // ...
        // y = semiLinear(x,sn,sb)
        // ->
        // s1 = if (x>=0) then sa else sb
        // s2 = s1
        // s3 = s2
        // ..
        // sn = sn-1
        // y = semiLinear(x,sa,sb)
        eqnslst = List.fold(arrayList(eqnsarray),semiLinearOptimize,{});
        // replace the equations in the system
        eqns = List.fold(eqnslst,semiLinearReplaceEqns,eqns);
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets);
      then (syst,shared);
    case (_,_)
      then (isyst,ishared);
  end matchcontinue;
end simplifysemiLinearWork;

protected function semiLinearReplaceEqns
"function: semiLinearReplaceEqns
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input tuple<BackendDAE.Equation,Integer> iTpl;
  input BackendDAE.EquationArray iEqns;
  output BackendDAE.EquationArray oEqns;
protected
  BackendDAE.Equation eqn;
  Integer index;
algorithm
  (eqn,index) := iTpl;
  Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Replace with ",eqn,"\n"));
  oEqns := BackendEquation.equationSetnth(iEqns, index, eqn);
end semiLinearReplaceEqns;

protected function semiLinearOptimize
"function: semiLinearOptimize
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input list<tuple<BackendDAE.Equation,Integer>> iAcc;
  output list<tuple<BackendDAE.Equation,Integer>> oAcc;
algorithm
  oAcc := matchcontinue(eqnslst,iAcc)
    local
      HashTableExpToIndex.HashTable ht,ht1;
      array<tuple<BackendDAE.Equation,Integer>> eqnsarray;
      list<DAE.Exp> explst;
    case (_::{},_) then iAcc;
    case (_,_)
      equation
        // get HashMab sa-> index
        ht = HashTableExpToIndex.emptyHashTable();
        ht1 = HashTableExpToIndex.emptyHashTable();
        (ht,ht1) = semiLinearOptimize1(eqnslst,1,ht,ht1);
        // get sa
        explst = List.fold1(BaseHashTable.hashTableKeyList(ht),semiLinearGetSA,ht1,{});
        eqnsarray = listArray(eqnslst);
        // optimize
      then
        semiLinearOptimize2(explst,ht,eqnsarray,iAcc);
    case(_,_) then iAcc;
  end matchcontinue;
end semiLinearOptimize;

protected function semiLinearOptimize2
"function: semiLinearOptimize2
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<DAE.Exp> saLst;
  input HashTableExpToIndex.HashTable iHt;
  input array<tuple<BackendDAE.Equation,Integer>> IEqnsarray;
  input list<tuple<BackendDAE.Equation,Integer>> iAcc;
  output list<tuple<BackendDAE.Equation,Integer>> oAcc;
algorithm
  oAcc := matchcontinue(saLst,iHt,IEqnsarray,iAcc)
    local
      DAE.Exp sa,sb,s1,y,x;
      list<DAE.Exp> rest;
      list<tuple<DAE.Exp,Integer,DAE.ElementSource>> explst;
      array<tuple<BackendDAE.Equation,Integer>> eqnsarray;
      list<tuple<BackendDAE.Equation,Integer>> acc;
      HashTableExpToIndex.HashTable ht;
      BackendDAE.Equation eqn,eqn1;
      Integer i1,index,index1;
      Absyn.Path path;
      DAE.CallAttributes attr;
      DAE.ElementSource source,source1;
      Boolean diffed;
    case ({},_,_,_) then iAcc;
    case (sa::rest,_,_,_)
      equation
        i1 = BaseHashTable.get(sa,iHt);
        ((BackendDAE.EQUATION(exp=y,scalar=DAE.CALL(path=path,expLst = {x,_,s1},attr=attr),source=source,differentiated=diffed),index)) = IEqnsarray[i1];
        // get Order of s1,s2,s3,..,sn,sb
        (sb,source1,index1,explst) = semiLinearOptimize3(s1,source,index,iHt,IEqnsarray,{});
        // generate optimized equations
        // s1 = if (x>=0) then sa else sb
        // s2 = s1
        // ..
        // sn = sn-1
        // y = semiLinear(x,sa,sb)
        eqn = BackendDAE.EQUATION(s1,DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(x,DAE.GREATEREQ(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE())},DAE.callAttrBuiltinBool),sa,sb),source,diffed);
        eqn1 = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source1,diffed);
        acc = semiLinearOptimize4(explst,(eqn1,index1)::iAcc);
      then
        semiLinearOptimize2(rest,iHt,IEqnsarray,(eqn,index)::acc);
    case (_::rest,_,_,_)
      then
        semiLinearOptimize2(rest,iHt,IEqnsarray,iAcc);
  end matchcontinue;
end semiLinearOptimize2;

protected function semiLinearOptimize4
"function: semiLinearOptimize3
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<tuple<DAE.Exp,Integer,DAE.ElementSource>> explst;
  input list<tuple<BackendDAE.Equation,Integer>> iAcc;
  output list<tuple<BackendDAE.Equation,Integer>> oAcc;
algorithm
  oAcc := match(explst,iAcc)
    local
      DAE.Exp s1,s2;
      list<tuple<DAE.Exp,Integer,DAE.ElementSource>> rest;
      Integer index;
      BackendDAE.Equation eqn;
      DAE.ElementSource source;
    case ({},_) then iAcc;
    case (_::{},_) then iAcc;
    case((s2,index,source)::(rest as ((s1,_,_)::_)),_)
      equation
        eqn = BackendDAE.EQUATION(s2,s1,source,false);
      then
        semiLinearOptimize4(rest,(eqn,index)::iAcc);
  end match;
end semiLinearOptimize4;

protected function semiLinearOptimize3
"function: semiLinearOptimize3
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input DAE.Exp exp;
  input DAE.ElementSource isource;
  input Integer iIndex;
  input HashTableExpToIndex.HashTable iHt;
  input array<tuple<BackendDAE.Equation,Integer>> IEqnsarray;
  input list<tuple<DAE.Exp,Integer,DAE.ElementSource>> iAcc;
  output DAE.Exp slast;
  output DAE.ElementSource osource;
  output Integer oIndex;
  output list<tuple<DAE.Exp,Integer,DAE.ElementSource>> oAcc;
algorithm
  (slast,osource,oIndex,oAcc) := matchcontinue(exp,isource,iIndex,iHt,IEqnsarray,iAcc)
    local
      DAE.Exp sb;
      Integer i,index;
      DAE.ElementSource source;
    case(_,_,_,_,_,_)
      equation
        i = BaseHashTable.get(exp,iHt);
        ((BackendDAE.EQUATION(scalar=DAE.CALL(expLst = {_,_,sb}),source=source),index)) = IEqnsarray[i];
        (sb,source,index,oAcc) = semiLinearOptimize3(sb,source,index,iHt,IEqnsarray,(exp,iIndex,source)::iAcc);
      then
        (sb,source,index,oAcc);
    case(_,_,_,_,_,_)
      then
        (exp,isource,iIndex,iAcc);
  end matchcontinue;
end semiLinearOptimize3;

protected function semiLinearGetSA
"function: semiLinearGetSA
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input DAE.Exp key;
  input HashTableExpToIndex.HashTable iHt1;
  input list<DAE.Exp> iAcc;
  output list<DAE.Exp> oAcc;
algorithm
  oAcc := matchcontinue(key,iHt1,iAcc)
    case (_,_,_)
      equation
        _ = BaseHashTable.get(key,iHt1);
      then
        iAcc;
    case(_,_,_)
      then
        key::iAcc;
  end matchcontinue;
end semiLinearGetSA;

protected function semiLinearOptimize1
"function: semiLinearOptimize1
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input Integer i;
  input HashTableExpToIndex.HashTable iHt;
  input HashTableExpToIndex.HashTable iHt1;
  output HashTableExpToIndex.HashTable oHt;
  output HashTableExpToIndex.HashTable oHt1;
algorithm
  (oHt,oHt1) := match(eqnslst,i,iHt,iHt1)
    local
     BackendDAE.Equation eqn;
      list<tuple<BackendDAE.Equation,Integer>> rest;
      HashTableExpToIndex.HashTable ht,ht1;
      DAE.Exp sa,sb;
    case ({},_,_,_) then (iHt,iHt1);
    case ((eqn as BackendDAE.EQUATION(scalar=DAE.CALL(expLst = {_,sa,sb})),_)::rest,_,_,_)
      equation
        ht = BaseHashTable.add((sa,i), iHt);
        ht1 = BaseHashTable.add((sb,i), iHt1);
        (ht,ht1) = semiLinearOptimize1(rest,i+1,ht,ht1);
      then
        (ht,ht1);
  end match;
end semiLinearOptimize1;

protected function semiLinearSort "function semiLinearSort
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input  list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input  HashTableExpToIndex.HashTable iHt;
  input  Integer size;
  input  array<list<tuple<BackendDAE.Equation,Integer>>> iEqnsarray;
  output  array<list<tuple<BackendDAE.Equation,Integer>>> oEqnsarray;
algorithm
  oEqnsarray := matchcontinue(eqnslst,iHt,size,iEqnsarray)
    local
     BackendDAE.Equation eqn;
     Integer index,i;
     list<tuple<BackendDAE.Equation,Integer>> rest,eqns;
     HashTableExpToIndex.HashTable ht;
     DAE.Exp y;
     array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
    case ({},_,_,_) then iEqnsarray;
    case ((eqn as BackendDAE.EQUATION(exp=y),index)::rest,_,_,_)
      equation
        i = BaseHashTable.get(y,iHt);
        eqns = iEqnsarray[i];
        eqnsarray = arrayUpdate(iEqnsarray,i,(eqn,index)::eqns);
      then
        semiLinearSort(rest,iHt,size,eqnsarray);
    case ((eqn as BackendDAE.EQUATION(exp=y),index)::rest,_,_,_)
      equation
        ht = BaseHashTable.add((y,size), iHt);
        // expand if necesarray
        eqnsarray = Debug.bcallret3(intGt(size,arrayLength(iEqnsarray)), Util.arrayExpand,5, iEqnsarray, {},iEqnsarray);
        eqnsarray = arrayUpdate(eqnsarray,size,{(eqn,index)});
      then
        semiLinearSort(rest,ht,size+1,eqnsarray);
  end matchcontinue;
end semiLinearSort;

protected function semiLinearSort1
"function: semiLinearSort1
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input  list<list<tuple<BackendDAE.Equation,Integer>>> eqnslstlst;
  input  Integer size;
  input  array<list<tuple<BackendDAE.Equation,Integer>>> iEqnsarray;
  output  array<list<tuple<BackendDAE.Equation,Integer>>> oEqnsarray;
algorithm
  oEqnsarray := match(eqnslstlst,size,iEqnsarray)
    local
     Integer size1;
     tuple<BackendDAE.Equation,Integer> tpl;
     list<tuple<BackendDAE.Equation,Integer>> eqns;
     list<list<tuple<BackendDAE.Equation,Integer>>> rest;
     HashTableExpToIndex.HashTable ht;
     array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
    case ({},_,_) then iEqnsarray;
    case ((tpl::{})::rest,_,_)
      equation
        // expand if necesarray
        eqnsarray = Debug.bcallret3(intGt(size,arrayLength(iEqnsarray)), Util.arrayExpand,5, iEqnsarray, {},iEqnsarray);
        eqnsarray = arrayUpdate(eqnsarray,size,{tpl});
      then
        semiLinearSort1(rest,size+1,eqnsarray);
    case (eqns::rest,_,_)
      equation
        ht = HashTableExpToIndex.emptyHashTable();
        (size1,eqnsarray) = semiLinearSort2(eqns,ht,size,iEqnsarray);
      then
        semiLinearSort1(rest,size1,eqnsarray);
  end match;
end semiLinearSort1;

protected function semiLinearSort2
"function: semiLinearSort2
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input  list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input  HashTableExpToIndex.HashTable iHt;
  input  Integer size;
  input  array<list<tuple<BackendDAE.Equation,Integer>>> iEqnsarray;
  output  Integer osize;
  output  array<list<tuple<BackendDAE.Equation,Integer>>> oEqnsarray;
algorithm
  (osize,oEqnsarray) := matchcontinue(eqnslst,iHt,size,iEqnsarray)
    local
     BackendDAE.Equation eqn;
     Integer index,i;
     list<tuple<BackendDAE.Equation,Integer>> rest,eqns;
     HashTableExpToIndex.HashTable ht;
     DAE.Exp x;
     array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
    case ({},_,_,_) then (size,iEqnsarray);
    case ((eqn as BackendDAE.EQUATION(scalar=DAE.CALL(expLst = x::_)),index)::rest,_,_,_)
      equation
        i = BaseHashTable.get(x,iHt);
        eqns = iEqnsarray[i];
        eqnsarray = arrayUpdate(iEqnsarray,i,(eqn,index)::eqns);
        (i,eqnsarray) = semiLinearSort2(rest,iHt,size,eqnsarray);
      then
        (i,eqnsarray);
    case ((eqn as BackendDAE.EQUATION(scalar=DAE.CALL(expLst = x::_)),index)::rest,_,_,_)
      equation
        ht = BaseHashTable.add((x,size), iHt);
        // expand if necesarray
        eqnsarray = Debug.bcallret3(intGt(size,arrayLength(iEqnsarray)), Util.arrayExpand,5, iEqnsarray, {},iEqnsarray);
        eqnsarray = arrayUpdate(eqnsarray,size,{(eqn,index)});
        (i,eqnsarray) = semiLinearSort2(rest,ht,size+1,eqnsarray);
      then
        (i,eqnsarray);
  end matchcontinue;
end semiLinearSort2;

protected function simplifysemiLinearFinder
"function: simplifysemiLinearFinder
  author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input tuple<BackendDAE.Equation,tuple<list<tuple<BackendDAE.Equation,Integer>>,Integer,Boolean>> inTpl;
  output tuple<BackendDAE.Equation,tuple<list<tuple<BackendDAE.Equation,Integer>>,Integer,Boolean>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Equation eqn;
      list<tuple<BackendDAE.Equation,Integer>> eqnslst;
      Integer index;
      Boolean b;
      DAE.Exp x,y,sa,sb;
      DAE.ElementSource source;
      Absyn.Path path;
      DAE.CallAttributes attr;
      Boolean diffed;
    // 0 = semiLinear(0,sa,sb) -> sa=sb
    case ((BackendDAE.EQUATION(exp=y,scalar=DAE.CALL(path = Absyn.IDENT("semiLinear"), expLst = {x,sa,sb}),source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then ((BackendDAE.EQUATION(sa,sb,source,diffed),(eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=DAE.CALL(path = Absyn.IDENT("semiLinear"), expLst = {x,sa,sb}),scalar=y,source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then ((BackendDAE.EQUATION(sa,sb,source,diffed),(eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=y,scalar=DAE.UNARY(exp=DAE.CALL(path = Absyn.IDENT("semiLinear"), expLst = {x,sa,sb})),source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then ((BackendDAE.EQUATION(sa,sb,source,diffed),(eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=DAE.UNARY(exp=DAE.CALL(path = Absyn.IDENT("semiLinear"), expLst = {x,sa,sb})),scalar=y,source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then ((BackendDAE.EQUATION(sa,sb,source,diffed),(eqnslst,index+1,true)));
    // y = -semiLinear(-x,sb,sa) -> y = semiLinear(x,sa,sb)
    case ((BackendDAE.EQUATION(exp=y,scalar=DAE.UNARY(exp=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr)),source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=DAE.UNARY(exp=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr)),scalar=y,source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    // -y = semiLinear(-x,sb,sa) -> y = semiLinear(x,sa,sb)
    case ((BackendDAE.EQUATION(exp=DAE.UNARY(exp=y),scalar=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),scalar=DAE.UNARY(exp=y),source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    // y = semiLinear(-x,sb,sa) -> -y = semiLinear(x,sa,sb)
    case ((BackendDAE.EQUATION(exp=y,scalar=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),scalar=y,source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    // y = semiLinear(x,sa,sb)
    case ((eqn as BackendDAE.EQUATION(scalar=DAE.CALL(path =Absyn.IDENT("semiLinear"))),(eqnslst,index,_)))
      equation
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    case ((eqn as BackendDAE.EQUATION(exp=DAE.CALL(path =Absyn.IDENT("semiLinear"))),(eqnslst,index,_)))
      equation
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=y,scalar=DAE.UNARY(exp= x as DAE.CALL(path = Absyn.IDENT("semiLinear"))),source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,x,source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));
    case ((BackendDAE.EQUATION(exp=DAE.UNARY(exp= x as DAE.CALL(path = Absyn.IDENT("semiLinear"))),scalar=y,source=source,differentiated=diffed),(eqnslst,index,_)))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,x,source,diffed);
        Debug.fcall(Flags.SEMILINEAR,BackendDump.debugStrEqnStr,("Found semiLinear ",eqn,"\n"));
      then ((eqn,((eqn,index)::eqnslst,index+1,true)));

    case ((eqn,(eqnslst,index,b))) then ((eqn,(eqnslst,index+1,b)));
  end matchcontinue;
end simplifysemiLinearFinder;

// =============================================================================
// check for derivatives of inputs
//
// =============================================================================
public function inputDerivativesUsed "function inputDerivativesUsed
  checks if der(input) is used and report a warning/error.
  author: Frenkel TUD 2012-10"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,inputDerivativesUsedWork,false);
end inputDerivativesUsed;

protected function inputDerivativesUsedWork "function inputDerivativesUsedWork
  author: Frenkel TUD 2012-10"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) :=
    matchcontinue(isyst,sharedChanged)
    local
      BackendDAE.Variables orderedVars "orderedVars ; ordered Variables, only states and alg. vars" ;
      BackendDAE.EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
      BackendDAE.Shared shared;
      list<DAE.Exp> explst;
      String s;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching,stateSets),(shared, _))
      equation
        ((_,explst as _::_)) = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(orderedEqs,traverserinputDerivativesUsed,(BackendVariable.daeKnVars(shared),{}));
        s = stringDelimitList(List.map(explst,ExpressionDump.printExpStr),"\n");
        Error.addMessage(Error.DERIVATIVE_INPUT,{s});
      then
        (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching,stateSets),(shared,true));
    else
      (isyst,sharedChanged);
  end matchcontinue;
end inputDerivativesUsedWork;

protected function traverserinputDerivativesUsed "function traverserinputDerivativesUsed
  author: Frenkel TUD 2012-10"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,list<DAE.Exp>>> itpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,list<DAE.Exp>>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,list<DAE.Exp>> tpl;
algorithm
  (e,tpl) := itpl;
  outTpl := Expression.traverseExpTopDown(e,traverserExpinputDerivativesUsed,tpl);
end traverserinputDerivativesUsed;

protected function traverserExpinputDerivativesUsed "function traverserExpinputDerivativesUsed
  author: Frenkel TUD 2012-10"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,list<DAE.Exp>>> tpl;
  output tuple<DAE.Exp,Boolean,tuple<BackendDAE.Variables,list<DAE.Exp>>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      BackendDAE.Variables vars;
      DAE.Type tp;
      DAE.Exp e,zero;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<DAE.Exp> explst;
    case((e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr,ty=tp)})}),(vars,explst)))
      equation
        (var::{},_) = BackendVariable.getVar(cr, vars);
        true = BackendVariable.isVarOnTopLevelAndInput(var);
      then
        ((e,false,(vars,e::explst)));
    case((e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr,ty=tp)}),(vars,explst)))
      equation
        (var::{},_) = BackendVariable.getVar(cr, vars);
        true = BackendVariable.isVarOnTopLevelAndInput(var);
      then
        ((e,false,(vars,e::explst)));
    case ((e,(vars,explst))) then ((e,true,(vars,explst)));
  end matchcontinue;
end traverserExpinputDerivativesUsed;


// =============================================================================
// remove constants stuff
//
// =============================================================================
public function removeConstants
"function: removeConstants
  author Frenkel TUD"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := match (dae)
    local
      DAE.FunctionTree funcs;
      BackendDAE.Variables knvars,exobj,av;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
      list<BackendDAE.Equation> lsteqns;
      Boolean b;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs)))
      equation
        repl = BackendVarTransform.emptyReplacements();
        repl = BackendVariable.traverseBackendDAEVars(knvars,removeConstantsFinder,repl);
        Debug.fcall(Flags.DUMP_CONST_REPL, BackendVarTransform.dumpReplacements, repl);
        (knvars,(repl,_)) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceFinalVarTraverser,(repl,0));
        lsteqns = BackendEquation.equationList(remeqns);
        (lsteqns,b) = BackendVarTransform.replaceEquations(lsteqns, repl,NONE());
        remeqns = Debug.bcallret1(b,BackendEquation.listEquation,lsteqns,remeqns);
        lsteqns = BackendEquation.equationList(inieqns);
        (lsteqns,b) = BackendVarTransform.replaceEquations(lsteqns, repl,NONE());
        inieqns = Debug.bcallret1(b,BackendEquation.listEquation,lsteqns,inieqns);
        systs = List.map1(systs,removeConstantsWork,repl);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end removeConstants;

protected function removeConstantsWork
"function: removeConstantsWork
  author Frenkel TUD"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (isyst,repl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      list<BackendDAE.Equation> eqns_1,lsteqns;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,stateSets=stateSets),_)
      equation
        (vars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars,replaceFinalVarTraverser,(repl,0));
        lsteqns = BackendEquation.equationList(eqns);
        (eqns_1,b) = BackendVarTransform.replaceEquations(lsteqns, repl,NONE());
        eqns1 = Debug.bcallret1(b,BackendEquation.listEquation,eqns_1,eqns);
        syst = Util.if_(b,BackendDAE.EQSYSTEM(vars,eqns1,NONE(),NONE(),BackendDAE.NO_MATCHING(),stateSets),isyst);
      then
        syst;
  end match;
end removeConstantsWork;

protected function removeConstantsFinder
"author: Frenkel TUD 2012-10"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      DAE.Exp exp;
    case ((v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.CONST(),bindExp=SOME(exp)),repl))
      equation
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp,NONE());
      then ((v,repl_1));
    case _ then inTpl;
  end matchcontinue;
end removeConstantsFinder;


// =============================================================================
// reaplace edge and change with (b and not pre(b)) and (v <> pre(v)
//
// =============================================================================
public function replaceEdgeChange "function replaceEdgeChange
  replace
  edge(b) = b and not pre(b)
  change(b) = v <> pre(v)
  author: Frenkel TUD 2012-11"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,replaceEdgeChange0,false);
  outDAE := replaceEdgeChangeShared(outDAE);
end replaceEdgeChange;

protected function replaceEdgeChange0 "function replaceEdgeChange0
  author: Frenkel TUD 2012-11"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) :=
    matchcontinue(isyst,sharedChanged)
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
      BackendDAE.Matching matching;
      BackendDAE.Shared shared;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching,stateSets),(shared, _))
      equation
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(orderedEqs,traverserreplaceEdgeChange,false);
      then
        (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching,stateSets),(shared,true));
    else
      (isyst,sharedChanged);
  end matchcontinue;
end replaceEdgeChange0;

protected function traverserreplaceEdgeChange "function
  author: Frenkel TUD 2012-11"
  input tuple<DAE.Exp,Boolean> itpl;
  output tuple<DAE.Exp,Boolean> outTpl;
protected
  DAE.Exp e;
  Boolean b;
algorithm
  (e,b) := itpl;
  outTpl := Expression.traverseExp(e,traverserExpreplaceEdgeChange,b);
end traverserreplaceEdgeChange;

protected function traverserExpreplaceEdgeChange "function traverserExpreplaceEdgeChange
  author: Frenkel TUD 2012-11"
  input tuple<DAE.Exp,Boolean> tpl;
  output tuple<DAE.Exp,Boolean> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      DAE.Exp e;
      DAE.Type ty;
    // change(v) -> v <> pre(v)
    case((DAE.CALL(path=Absyn.IDENT(name = "change"),expLst={e}),_))
      equation
        ty = Expression.typeof(e);
      then
        ((DAE.RELATION(e,DAE.NEQUAL(ty),DAE.CALL(Absyn.IDENT("pre"),{e},DAE.CALL_ATTR(ty,false,true,false,DAE.NO_INLINE(),DAE.NO_TAIL())),-1,NONE()),true));
    // edge(b) = b and not pre(b)
    case((DAE.CALL(path=Absyn.IDENT(name = "edge"),expLst={e}),_))
      equation
        ty = Expression.typeof(e);
      then
        ((DAE.LBINARY(e,DAE.AND(ty),DAE.LUNARY(DAE.NOT(ty),DAE.CALL(Absyn.IDENT("pre"),{e},DAE.CALL_ATTR(ty,false,true,false,DAE.NO_INLINE(),DAE.NO_TAIL())))),true));
    case _ then tpl;
  end matchcontinue;
end traverserExpreplaceEdgeChange;

protected function replaceEdgeChangeShared "function replaceEdgeChangeShared
  author: Frenkel TUD 2012-11"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:= match (inDAE)
    local
      BackendDAE.Variables knvars,exobj,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcTree;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,eventInfo,eoc,btp,symjacs)))
      equation
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(remeqns,traverserreplaceEdgeChange,false);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,eventInfo,eoc,btp,symjacs));
  end match;
end replaceEdgeChangeShared;


// =============================================================================
// optimize inital system
//
// =============================================================================
public function optimizeInitialSystem "function optimizeInitialSystem
  author Frenkel TUD 2012-08"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue (inDAE)
    local
      BackendDAE.EqSystems systs;
      BackendDAE.Variables knvars;
      BackendDAE.EquationArray inieqns;
      HashTable2.HashTable initalAliases;
      list<BackendDAE.Equation> eqnlst;
      Boolean optimizationfound;
    case (BackendDAE.DAE(systs,BackendDAE.SHARED(knownVars=knvars,initialEqs=inieqns)))
      equation
        // search
        initalAliases = HashTable2.emptyHashTable();
        eqnlst = BackendEquation.equationList(inieqns);
        (eqnlst,initalAliases,optimizationfound) = optimizeInitialSystem1(eqnlst,knvars,initalAliases,{},false);
      then
        // do optimization
        optimizeInitialSystemWork(optimizationfound,inDAE,eqnlst,initalAliases);
    else then inDAE;
  end matchcontinue;
end optimizeInitialSystem;

protected function optimizeInitialSystemWork "function optimizeInitialSystemWork
  author Frenkel TUD 2012-08"
  input Boolean optimizationfound;
  input BackendDAE.BackendDAE inDAE;
  input list<BackendDAE.Equation> eqnlst;
  input HashTable2.HashTable initalAliases;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match (optimizationfound,inDAE,eqnlst,initalAliases)
    local
      BackendDAE.EqSystems systs;
      BackendDAE.Variables knvars,knvars1,exobj,av;
      BackendDAE.EquationArray remeqns,inieqns;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
    case (true,BackendDAE.DAE(systs,BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs)),_,_)
      equation
        (knvars1,(_,_)) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,optimizeInitialAliasesFinder,(initalAliases,false));
        inieqns = BackendEquation.listEquation(eqnlst);
        systs= List.map1(systs,optimizeInitialAliases,initalAliases);
      then
        BackendDAE.DAE(systs,BackendDAE.SHARED(knvars1,exobj,av,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs));
    case(false,_,_,_)
      then inDAE;
  end match;
end optimizeInitialSystemWork;

protected function optimizeInitialSystem1 "function optimizeInitialSystem1
  author: Frenkel TUD 2012-06"
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Variables knvars;
  input HashTable2.HashTable iInitalAliases;
  input list<BackendDAE.Equation> iAcc;
  input Boolean iOptimizationfound;
  output list<BackendDAE.Equation> outEqsLst;
  output HashTable2.HashTable oInitalAliases;
  output Boolean oOptimizationfound;
algorithm
  (outEqsLst,oInitalAliases,oOptimizationfound) := matchcontinue (iEqns,knvars,iInitalAliases,iAcc,iOptimizationfound)
    local
      list<BackendDAE.Equation> eqnslst,eqnslst1;
      BackendDAE.Equation eqn;
      HashTable2.HashTable initalAliases;
      Boolean optimizationfound,negate;
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e1,e2,e1_1,e2_1;
      list<DAE.Exp> ea1,ea2;

    case ({},_,_,_,_) then (listReverse(iAcc),iInitalAliases,iOptimizationfound);
    case ((eqn as BackendDAE.EQUATION(exp=e1,scalar=e2))::eqnslst,_,_,_,_)
      equation
        ((cr1,cr2,e1,e2,negate)::{}) = BackendEquation.aliasEquation(eqn);
        initalAliases = addInitialAlias(cr1,cr2,e1,e2,negate,knvars,iInitalAliases);
        (eqnslst1,initalAliases,optimizationfound) = optimizeInitialSystem1(eqnslst,knvars,initalAliases,iAcc,true);
       then
         (eqnslst1,initalAliases,optimizationfound);
    case (eqn::eqnslst,_,_,_,_)
      equation
        (eqnslst1,initalAliases,optimizationfound) = optimizeInitialSystem1(eqnslst,knvars,iInitalAliases,eqn::iAcc,iOptimizationfound);
       then
         (eqnslst1,initalAliases,optimizationfound);
  end matchcontinue;
end optimizeInitialSystem1;

protected function addInitialAlias
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input Boolean negate;
  input BackendDAE.Variables knvars;
  input HashTable2.HashTable iInitalAliases;
  output HashTable2.HashTable oInitalAliases;
algorithm
  oInitalAliases := matchcontinue(cr1,cr2,e1,e2,negate,knvars,iInitalAliases)
    local
      HashTable2.HashTable initalAliases;
      DAE.Exp e;
    case(_,_,_,_,_,_,_)
      equation
        (_::_,_) = BackendVariable.getVar(cr2, knvars);
        e = Debug.bcallret1(negate, Expression.negate, e2, e2);
        initalAliases = BaseHashTable.add((cr1,e),iInitalAliases);
        Debug.fcall(Flags.DUMPOPTINIT,BackendDump.debugStrCrefStrExpStr,("Found initial Alias ",cr1," = ",e,"\n"));
      then
        initalAliases;
    case(_,_,_,_,_,_,_)
      equation
        (_::_,_) = BackendVariable.getVar(cr1, knvars);
        e = Debug.bcallret1(negate, Expression.negate, e1, e1);
        initalAliases = BaseHashTable.add((cr2,e),iInitalAliases);
        Debug.fcall(Flags.DUMPOPTINIT,BackendDump.debugStrCrefStrExpStr,("Found initial Alias ",cr2," = ",e,"\n"));
      then
        initalAliases;
  end matchcontinue;
end addInitialAlias;

protected function optimizeInitialAliases "function optimizeInitialAliases
  author Frenkel TUD 2012-08"
  input BackendDAE.EqSystem isyst;
  input HashTable2.HashTable initalAliases;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (isyst,initalAliases)
    local
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.Matching matching;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching,stateSets),_)
      equation
        (vars,(_,b)) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars,optimizeInitialAliasesFinder,(initalAliases,false));
        syst = Util.if_(b,BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching,stateSets),isyst);
      then
        syst;
  end match;
end optimizeInitialAliases;

protected function optimizeInitialAliasesFinder "function optimizeInitialAliasesFinder
  author: Frenkel TUD 2011-03"
  input tuple<BackendDAE.Var, tuple<HashTable2.HashTable,Boolean>> inTpl;
  output tuple<BackendDAE.Var, tuple<HashTable2.HashTable,Boolean>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      HashTable2.HashTable initalAliases;
      DAE.ComponentRef varName;
      DAE.Exp exp;
    case ((v as BackendDAE.VAR(varName=varName),(initalAliases,_)))
      equation
        exp = BaseHashTable.get(varName,initalAliases);
        v = BackendVariable.setVarStartValue(v, exp);
        v = BackendVariable.setVarFixed(v, true);
        Debug.fcall(Flags.DUMPOPTINIT,BackendDump.debugStrCrefStrExpStr,("Set Var ",varName," (start= ",exp,", fixed=true)\n"));
      then ((v,(initalAliases,true)));
    case _ then inTpl;
  end matchcontinue;
end optimizeInitialAliasesFinder;

// =============================================================================
// section for preOptModule >>encapsulateWhenConditions<<
//
// This module encapsulates each when-condition in a boolean-variable
// $whenConditionN and generates to each of these variables an initial equation
// $whenConditionN = pre($whenConditionN)
// =============================================================================

public function encapsulateWhenConditions "function encapsulateWhenConditions
  author: lochel"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  BackendDAE.Variables knownVars;
  BackendDAE.Variables externalObjects;
  BackendDAE.Variables aliasVars;
  BackendDAE.EquationArray initialEqs;
  BackendDAE.EquationArray removedEqs;
  array<DAE.Constraint> constraints;
  array<DAE.ClassAttributes> classAttrs;
  Env.Cache cache;
  Env.Env env;
  DAE.FunctionTree functionTree;
  BackendDAE.EventInfo eventInfo;
  BackendDAE.ExternalObjectClasses extObjClasses;
  BackendDAE.BackendDAEType backendDAEType;
  BackendDAE.SymbolicJacobians symjacs;
  list<BackendDAE.Equation> additionalInitialEquations;

  BackendDAE.SampleLookup sampleLookup;
  list<BackendDAE.WhenClause> whenClauseLst;
  list<BackendDAE.ZeroCrossing> zeroCrossingLst;
  list<BackendDAE.ZeroCrossing> sampleLst;
  list<BackendDAE.ZeroCrossing> relationsLst;
  Integer relationsNumber;
  Integer numberMathEvents;

  Integer index;
  HashTableExpToIndex.HashTable ht;   // is used to avoid redundant condition-variables
  list<BackendDAE.Var> vars;
  list<BackendDAE.Equation> eqns;
  BackendDAE.Variables vars_;
  BackendDAE.EquationArray eqns_;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  BackendDAE.SHARED(knownVars=knownVars,
                    externalObjects=externalObjects,
                    aliasVars=aliasVars,
                    initialEqs=initialEqs,
                    removedEqs=removedEqs,
                    constraints=constraints,
                    classAttrs=classAttrs,
                    cache=cache,
                    env=env,
                    functionTree=functionTree,
                    eventInfo=eventInfo,
                    extObjClasses=extObjClasses,
                    backendDAEType=backendDAEType,
                    symjacs=symjacs) := shared;
  BackendDAE.EVENT_INFO(sampleLookup=sampleLookup,
                        whenClauseLst=whenClauseLst,
                        zeroCrossingLst=zeroCrossingLst,
                        sampleLst=sampleLst,
                        relationsLst=relationsLst,
                        relationsNumber=relationsNumber,
                        numberMathEvents=numberMathEvents) := eventInfo;

  ht := HashTableExpToIndex.emptyHashTable();

  // equation system
  (systs, (additionalInitialEquations, index, ht)) := List.mapFold(systs, encapsulateWhenConditions1, ({}, 1, ht));

  // when clauses
  (whenClauseLst, vars, eqns, additionalInitialEquations, ht, index) := encapsulateWhenConditionsFromWhenClause(whenClauseLst, {}, {}, {}, additionalInitialEquations, ht, index);

  // removed equations
  ((removedEqs, vars, eqns, additionalInitialEquations, index, ht)) := BackendEquation.traverseBackendDAEEqns(removedEqs, encapsulateWhenConditions2, (BackendEquation.emptyEqns(), vars, eqns, additionalInitialEquations, index, ht));
  vars_ := BackendVariable.listVar(vars);
  eqns_ := BackendEquation.listEquation(eqns);
  systs := listAppend(systs, {BackendDAE.EQSYSTEM(vars_, eqns_, NONE(), NONE(), BackendDAE.NO_MATCHING(), {})});

  initialEqs := BackendEquation.addEquations(additionalInitialEquations, initialEqs);
  eventInfo := BackendDAE.EVENT_INFO(sampleLookup,
                                     whenClauseLst,
                                     zeroCrossingLst,
                                     sampleLst,
                                     relationsLst,
                                     relationsNumber,
                                     numberMathEvents);
  shared := BackendDAE.SHARED(knownVars,
                              externalObjects,
                              aliasVars,
                              initialEqs,
                              removedEqs,
                              constraints,
                              classAttrs,
                              cache,
                              env,
                              functionTree,
                              eventInfo,
                              extObjClasses,
                              backendDAEType,
                              symjacs);
  outDAE := Util.if_(intGt(index, 1), BackendDAE.DAE(systs, shared), inDAE);
  Debug.fcall2(Flags.DUMP_ENCAPSULATEWHENCONDITIONS, BackendDump.dumpBackendDAE, outDAE, "DAE after PreOptModule >>encapsulateWhenConditions<<");
end encapsulateWhenConditions;

protected function encapsulateWhenConditionsFromWhenClause
  input list<BackendDAE.WhenClause> inWhenClause;
  input list<BackendDAE.WhenClause> inWhenClause_done;
  input list<BackendDAE.Var> inVars;
  input list<BackendDAE.Equation> inEqns;
  input list<BackendDAE.Equation> inAdditionalInitialEquations;
  input HashTableExpToIndex.HashTable inHT;
  input Integer inIndex;
  output list<BackendDAE.WhenClause> outWhenClause;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outAdditionalInitialEquations;
  output HashTableExpToIndex.HashTable outHT;
  output Integer outIndex;
algorithm
  (outWhenClause, outVars, outEqns, outAdditionalInitialEquations, outHT, outIndex) := match(inWhenClause, inWhenClause_done, inVars, inEqns, inAdditionalInitialEquations, inHT, inIndex)
    local
      list<BackendDAE.Equation> additionalInitialEquations;
      HashTableExpToIndex.HashTable ht;
      Integer index;
      DAE.Exp condition;
      list<BackendDAE.WhenOperator> reinitStmtLst;
      Option<Integer> elseClause;

      list<BackendDAE.Var> vars;
      list<BackendDAE.Equation> eqns;
      list<BackendDAE.WhenClause> rest, whenClause_done;

    case ({}, _, _, _, _, _, _) then (inWhenClause_done, inVars, inEqns, inAdditionalInitialEquations, inHT, inIndex);

    case (BackendDAE.WHEN_CLAUSE(condition, reinitStmtLst, elseClause)::rest, _, _, _, _, ht, index) equation
      (condition, vars, eqns, additionalInitialEquations, index, ht) = encapsulateWhenConditionsForEquations1(condition, DAE.emptyElementSource, index, ht);
      vars = listAppend(vars, inVars);
      eqns = listAppend(eqns, inEqns);
      additionalInitialEquations = listAppend(additionalInitialEquations, inAdditionalInitialEquations);
      whenClause_done = listAppend({BackendDAE.WHEN_CLAUSE(condition, reinitStmtLst, elseClause)}, inWhenClause_done);

      (whenClause_done, vars, eqns, additionalInitialEquations, ht, index) = encapsulateWhenConditionsFromWhenClause(rest, whenClause_done, vars, eqns, additionalInitialEquations, ht, index);
    then (whenClause_done, vars, eqns, additionalInitialEquations, ht, index);
  end match;
end encapsulateWhenConditionsFromWhenClause;

protected function encapsulateWhenConditions1 "function encapsulateWhenConditions1
  author: lochel
  This is a helper function for encapsulateWhenConditions."
  input BackendDAE.EqSystem inEqSystem;
  input tuple<list<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable> inTpl;
  output BackendDAE.EqSystem outEqSystem;
  output tuple<list<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable> outTpl;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.StateSets stateSets;
  list<BackendDAE.Var> varLst;
  list<BackendDAE.Equation> eqnLst, additionalInitialEquations;
  Integer index;
  HashTableExpToIndex.HashTable ht;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets) := inEqSystem;
  (additionalInitialEquations, index, ht) := inTpl;

  ((orderedEqs, varLst, eqnLst, additionalInitialEquations, index, ht)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, encapsulateWhenConditions2, (BackendEquation.emptyEqns(), {}, {}, additionalInitialEquations, index, ht));

  orderedVars := BackendVariable.addVars(varLst, orderedVars);
  orderedEqs := BackendEquation.addEquations(eqnLst, orderedEqs);

  outTpl := (additionalInitialEquations, index, ht);
  outEqSystem := BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets);
end encapsulateWhenConditions1;

protected function encapsulateWhenConditions2 "function encapsulateWhenConditions2
  author: lochel
  This is a helper function for encapsulateWhenConditions1."
  input tuple<BackendDAE.Equation, tuple<BackendDAE.EquationArray, list<BackendDAE.Var>, list<BackendDAE.Equation>, list<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.EquationArray, list<BackendDAE.Var>, list<BackendDAE.Equation>, list<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      BackendDAE.Equation eqn, eqn2;
      list<BackendDAE.Var> vars, vars1;
      list<BackendDAE.Equation> eqns, eqns1, additionalInitialEquations, additionalInitialEquations1;
      BackendDAE.WhenEquation whenEquation;
      DAE.ElementSource source;
      Integer index, size, sizePre;
      BackendDAE.EquationArray equationArray;
      DAE.Algorithm alg_;
      list<DAE.Statement> stmts, preStmts;
      HashTableExpToIndex.HashTable ht;

    // when equation
    case ((BackendDAE.WHEN_EQUATION(size=size, whenEquation=whenEquation, source=source), (equationArray, vars, eqns, additionalInitialEquations, index, ht))) equation
      (whenEquation, vars1, eqns1, additionalInitialEquations1, index, ht) = encapsulateWhenConditionsForEquations(whenEquation, source, index, ht);
      vars = listAppend(vars, vars1);
      eqns = listAppend(eqns, eqns1);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
      eqn = BackendDAE.WHEN_EQUATION(size, whenEquation, source);
      equationArray = BackendEquation.addEquations({eqn}, equationArray);
    then ((eqn, (equationArray, vars, eqns, additionalInitialEquations, index, ht)));

    // removed algorithm
    case ((BackendDAE.ALGORITHM(size=0, alg=alg_, source=source), (equationArray, vars, eqns, additionalInitialEquations, index, ht))) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg_;
      size = -index;
      (stmts, preStmts, vars1, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms(stmts, vars, index);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
      sizePre = listLength(preStmts);
      size = size+index-sizePre;

      alg_ = DAE.ALGORITHM_STMTS(stmts);
      eqn = BackendDAE.ALGORITHM(size, alg_, source);
      equationArray = BackendEquation.addEquations({eqn}, equationArray);

      alg_ = DAE.ALGORITHM_STMTS(preStmts);
      eqn2 = BackendDAE.ALGORITHM(sizePre, alg_, source);
      eqns = Util.if_(intGt(sizePre, 0), eqn2::eqns, eqns);
    then ((eqn, (equationArray, vars1, eqns, additionalInitialEquations, index, ht)));

    // algorithm
    case ((BackendDAE.ALGORITHM(size=size, alg=alg_, source=source), (equationArray, vars, eqns, additionalInitialEquations, index, ht))) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg_;
      size = size-index;
      (stmts, preStmts, vars1, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms(stmts, vars, index);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
      size = size+index;

      stmts = listAppend(preStmts, stmts);

      alg_ = DAE.ALGORITHM_STMTS(stmts);
      eqn = BackendDAE.ALGORITHM(size, alg_, source);
      equationArray = BackendEquation.addEquations({eqn}, equationArray);
    then ((eqn, (equationArray, vars1, eqns, additionalInitialEquations, index, ht)));

    case ((eqn, (equationArray, vars, eqns, additionalInitialEquations, index, ht))) equation
      equationArray = BackendEquation.addEquations({eqn}, equationArray);
    then ((eqn, (equationArray, vars, eqns, additionalInitialEquations, index, ht)));
  end match;
end encapsulateWhenConditions2;

protected function encapsulateWhenConditionsForEquations "function encapsulateWhenConditionsForEquations
  author: lochel
  This is a helper function for encapsulateWhenConditions2."
  input BackendDAE.WhenEquation inWhenEquation;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output BackendDAE.WhenEquation outWhenEquation;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outAdditionalInitialEquations;
  output Integer outIndex;
  output HashTableExpToIndex.HashTable outHT;
algorithm
  (outWhenEquation, outVars, outEqns, outAdditionalInitialEquations, outIndex, outHT) := matchcontinue(inWhenEquation, inSource, inIndex, inHT)
    local
      Integer index;
      BackendDAE.WhenEquation elsewhenPart, whenEquation;
      list<BackendDAE.Var> vars, vars1;
      list<BackendDAE.Equation> eqns, eqns1, additionalInitialEquations, additionalInitialEquations1;
      String crStr;

      DAE.Exp condition;
      DAE.ComponentRef left;
      DAE.Exp right;

      HashTableExpToIndex.HashTable ht;

    // when
    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=NONE()), _, index, ht) equation
      (condition, vars, eqns, additionalInitialEquations, index, ht) = encapsulateWhenConditionsForEquations1(condition, inSource, index, ht);
      whenEquation = BackendDAE.WHEN_EQ(condition, left, right, NONE());
    then (whenEquation, vars, eqns, additionalInitialEquations, index, ht);

    // when - elsewhen
    case (whenEquation as BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=SOME(elsewhenPart)), _, index, ht) equation
      (elsewhenPart, vars1, eqns1, additionalInitialEquations1, index, ht) = encapsulateWhenConditionsForEquations(elsewhenPart, inSource, index, ht);
      (condition, vars, eqns, additionalInitialEquations, index, ht) = encapsulateWhenConditionsForEquations1(condition, inSource, index, ht);
      whenEquation = BackendDAE.WHEN_EQ(condition, left, right, SOME(elsewhenPart));
      vars = listAppend(vars, vars1);
      eqns = listAppend(eqns, eqns1);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
    then (whenEquation, vars, eqns, additionalInitialEquations, index, ht);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function encapsulateWhenConditionsForEquations failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditionsForEquations;

protected function encapsulateWhenConditionsForEquations1 "function encapsulateWhenConditionsForEquations1
  author: lochel
  This is a helper function for encapsulateWhenConditionsForEquations."
  input DAE.Exp inCondition;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output DAE.Exp outCondition;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outAdditionalInitialEquations;
  output Integer outIndex;
  output HashTableExpToIndex.HashTable outHT;
algorithm
  (outCondition, outVars, outEqns, outAdditionalInitialEquations, outIndex, outHT) := matchcontinue(inCondition, inSource, inIndex, inHT)
    local
      Integer index, localIndex;
      BackendDAE.WhenEquation elsewhenPart, whenEquation;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      BackendDAE.Equation initialEqn;
      list<BackendDAE.Equation> initialEqns;
      list<BackendDAE.Var> vars;
      list<BackendDAE.Equation> eqns;
      String crStr;
      DAE.Exp crefPreExp;

      DAE.Exp condition;
      DAE.ComponentRef left;
      DAE.Exp right;
      list<DAE.Exp> array;

      DAE.Type ty;
      Boolean scalar "scalar for codegen" ;

      HashTableExpToIndex.HashTable ht;

    // we do not replace initial()
    case (condition as DAE.CALL(path = Absyn.IDENT(name = "initial")), _, index, ht)
    then (condition, {}, {}, {}, index, ht);

    // array-condition
    case (condition as DAE.ARRAY(ty=ty, scalar=scalar, array=array), _, _, ht) equation
      (array, vars, eqns, initialEqns, index, ht) = encapsulateWhenConditionsForEquationsWithArrayConditions(array, inSource, inIndex, ht);
    then (DAE.ARRAY(ty, scalar, array), vars, eqns, initialEqns, index, ht);

    // simple condition [already in ht]
    case (condition, _, index, ht) equation
      localIndex = BaseHashTable.get(condition, ht);
      crStr = "$whenCondition" +& intString(localIndex);
      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
    then (condition, {}, {}, {}, index, ht);

    // simple condition [not yet in ht]
    case (condition, _, index, ht) equation
      ht = BaseHashTable.add((condition, index), ht);
      crStr = "$whenCondition" +& intString(index);

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      eqn = BackendDAE.EQUATION(DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), condition, inSource, false);

      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
      crefPreExp = Expression.makeBuiltinCall("pre", {condition}, DAE.T_BOOL_DEFAULT);
      initialEqn = BackendDAE.EQUATION(condition, crefPreExp, inSource, false);
    then (condition, {var}, {eqn}, {initialEqn}, index+1, ht);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function encapsulateWhenConditionsForEquations1 failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditionsForEquations1;

protected function encapsulateWhenConditionsForEquationsWithArrayConditions "function encapsulateWhenConditionsForEquationsWithArrayConditions
  author: lochel
  This is a helper function for encapsulateWhenConditionsForEquations1."
  input list<DAE.Exp> inConditionList;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output list<DAE.Exp> outConditionList;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outAdditionalInitialEquations;
  output Integer outIndex;
  output HashTableExpToIndex.HashTable outHT;
algorithm
  (outConditionList, outVars, outEqns, outAdditionalInitialEquations, outIndex, outHT) := matchcontinue(inConditionList, inSource, inIndex, inHT)
    local
      Integer index;
      BackendDAE.WhenEquation elsewhenPart, whenEquation;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> vars1, vars2;
      list<BackendDAE.Equation> eqns1, eqns2;
      String crStr;

      DAE.Exp condition;
      list<DAE.Exp> conditionList;
      DAE.ComponentRef left;
      DAE.Exp right;
      list<DAE.Exp> array;
      list<BackendDAE.Equation> additionalInitialEquations, additionalInitialEquations1;

      HashTableExpToIndex.HashTable ht;

    case ({}, _, _, _) equation
    then ({}, {}, {}, {}, inIndex, inHT);

    case (condition::conditionList, _, index, ht) equation
      (condition, vars1, eqns1, additionalInitialEquations, index, ht) = encapsulateWhenConditionsForEquations1(condition, inSource, index, ht);
      (conditionList, vars2, eqns2, additionalInitialEquations1, index, ht) = encapsulateWhenConditionsForEquationsWithArrayConditions(conditionList, inSource, index, ht);
      vars1 = listAppend(vars1, vars2);
      eqns1 = listAppend(eqns1, eqns2);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
    then (condition::conditionList, vars1, eqns1, additionalInitialEquations, index, ht);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function encapsulateWhenConditionsForEquationsWithArrayConditions failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditionsForEquationsWithArrayConditions;

protected function encapsulateWhenConditionsForAlgorithms "function encapsulateWhenConditionsForAlgorithms
  author: lochel
  This is a helper function for encapsulateWhenConditions2."
  input list<DAE.Statement> inStmts;
  input list<BackendDAE.Var> inVars;
  input Integer inIndex;
  output list<DAE.Statement> outStmts;
  output list<DAE.Statement> outPreStmts; // these are additional statements that should be inserted directly before a STMT_WHEN
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outAdditionalInitialEquations;
  output Integer outIndex;
algorithm
  (outStmts, outPreStmts, outVars, outAdditionalInitialEquations, outIndex) := matchcontinue(inStmts, inVars, inIndex)
    local
      DAE.Exp condition;
      list<DAE.ComponentRef> crefLst;
      DAE.Statement stmt, elseWhen;
      list<DAE.Statement> stmts, rest, stmts1, stmts_, preStmts, preStmts2, elseWhenList;
      list<tuple<DAE.ComponentRef, Integer>> crintLst;
      list<BackendDAE.Var> vars1, vars2;
      list<BackendDAE.Equation> eqns, additionalInitialEquations, additionalInitialEquations1;
      Integer index;
      DAE.ElementSource source;
      list<BackendDAE.Var> vars;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case ({}, _, _)
    then ({}, {}, inVars, {}, inIndex);

    // when statement (without outputs)
    case ((DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=NONE(), source=source))::rest, _, _) equation
      (condition, vars, preStmts, additionalInitialEquations, index) = encapsulateWhenConditionsForAlgorithms1(condition, source, inIndex);
      (conditions, initialCall) = getConditionList(condition);
      vars = listAppend(vars, inVars);

      {} = CheckModel.algorithmStatementListOutputs({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)});

      (stmts, preStmts2, vars, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms(rest, vars, index);
      preStmts = listAppend(preStmts, preStmts2);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)}, stmts);

      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
    then (stmts_, preStmts, vars, additionalInitialEquations, index);

    // when statement
    case ((DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=NONE(), source=source))::rest, _, _) equation
      (condition, vars, preStmts, additionalInitialEquations, index) = encapsulateWhenConditionsForAlgorithms1(condition, source, inIndex);
      (conditions, initialCall) = getConditionList(condition);
      vars = listAppend(vars, inVars);

      (stmts, stmts_, vars, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms(rest, vars, index);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)}, stmts_);
      stmts_ = listAppend(stmts_, stmts);

      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
    then (stmts_, preStmts, vars, additionalInitialEquations, index);

    // when - elsewhen statement (without outputs)
    case ((DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=SOME(elseWhen), source=source))::rest, _, _) equation
      (condition, vars, preStmts, additionalInitialEquations, index) = encapsulateWhenConditionsForAlgorithms1(condition, source, inIndex);
      (conditions, initialCall) = getConditionList(condition);
      vars = listAppend(vars, inVars);

      (elseWhenList, _, vars, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms({elseWhen}, vars, index);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
      elseWhen = List.last(elseWhenList);
      preStmts2 = List.stripLast(elseWhenList);
      preStmts = listAppend(preStmts, preStmts2);

      {} = CheckModel.algorithmStatementListOutputs({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, SOME(elseWhen), source)});

      (stmts, preStmts2, vars, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms(rest, vars, index);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
      preStmts = listAppend(preStmts, preStmts2);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, SOME(elseWhen), source)}, stmts);
    then (stmts_, preStmts, vars, additionalInitialEquations, index);

    // when - elsewhen statement
    case ((DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=SOME(elseWhen), source=source))::rest, _, _) equation
      (condition, vars, preStmts, additionalInitialEquations, index) = encapsulateWhenConditionsForAlgorithms1(condition, source, inIndex);
      (conditions, initialCall) = getConditionList(condition);
      vars = listAppend(vars, inVars);

      ({elseWhen}, preStmts2, vars, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms({elseWhen}, vars, index);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
      preStmts = listAppend(preStmts, preStmts2);

      (stmts, stmts_, vars, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithms(rest, vars, index);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, SOME(elseWhen), source)}, stmts_);
      stmts_ = listAppend(stmts_, stmts);
    then (stmts_, preStmts, vars, additionalInitialEquations, index);

    // no when statement
    case (stmt::rest, _, _) equation
      (stmts, preStmts, vars, additionalInitialEquations, index) = encapsulateWhenConditionsForAlgorithms(rest, inVars, inIndex);
      stmts = listAppend(preStmts, stmts);
    then (stmt::stmts, {}, vars, additionalInitialEquations, index);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function encapsulateWhenConditionsForAlgorithms failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditionsForAlgorithms;

protected function encapsulateWhenConditionsForAlgorithms1 "function encapsulateWhenConditionsForAlgorithms1
  author: lochel
  This is a helper function for encapsulateWhenConditionsForEquations."
  input DAE.Exp inCondition;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  output DAE.Exp outCondition;
  output list<BackendDAE.Var> outVars;
  output list<DAE.Statement> outStmts;
  output list<BackendDAE.Equation> outAdditionalInitialEquations;
  output Integer outIndex;
algorithm
  (outCondition, outVars, outStmts, outAdditionalInitialEquations, outIndex) := matchcontinue(inCondition, inSource, inIndex)
    local
      Integer index;
      BackendDAE.WhenEquation elsewhenPart, whenEquation;
      BackendDAE.Var var;
      DAE.Statement stmt;
      list<BackendDAE.Var> vars;
      list<DAE.Statement> stmts;
      String crStr;
      DAE.Exp crefPreExp;

      DAE.Exp condition;
      DAE.ComponentRef left;
      DAE.Exp right;
      list<DAE.Exp> array;

      DAE.Type ty;
      Boolean scalar "scalar for codegen" ;

      BackendDAE.Equation initialEqn;
      list<BackendDAE.Equation> initialEqns;

    // we do not replace initial()
    case (condition as DAE.CALL(path = Absyn.IDENT(name = "initial")), _, index)
    then (condition, {}, {}, {}, index);

    // array-condition
    case (DAE.ARRAY(array={condition}), _, index) equation
      crStr = "$whenCondition" +& intString(index);

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      stmt = DAE.STMT_ASSIGN(DAE.T_BOOL_DEFAULT, DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), condition, inSource);

      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
      crefPreExp = Expression.makeBuiltinCall("pre", {condition}, DAE.T_BOOL_DEFAULT);
      initialEqn = BackendDAE.EQUATION(condition, crefPreExp, inSource, false);
    then (condition, {var}, {stmt}, {initialEqn}, index+1);

    // array-condition
    case (condition as DAE.ARRAY(ty=ty, scalar=scalar, array=array), _, _) equation
      (array, vars, stmts, initialEqns, index) = encapsulateWhenConditionsForAlgorithmsWithArrayConditions(array, inSource, inIndex);
    then (DAE.ARRAY(ty, scalar, array), vars, stmts, initialEqns, index);

    // simple condition
    case (condition, _, index) equation
      crStr = "$whenCondition" +& intString(index);

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      stmt = DAE.STMT_ASSIGN(DAE.T_BOOL_DEFAULT, DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), condition, inSource);

      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
      crefPreExp = Expression.makeBuiltinCall("pre", {condition}, DAE.T_BOOL_DEFAULT);
      initialEqn = BackendDAE.EQUATION(condition, crefPreExp, inSource, false);
    then (condition, {var}, {stmt}, {initialEqn}, index+1);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function encapsulateWhenConditionsForAlgorithms1 failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditionsForAlgorithms1;

protected function encapsulateWhenConditionsForAlgorithmsWithArrayConditions "function encapsulateWhenConditionsForAlgorithmsWithArrayConditions
  author: lochel
  This is a helper function for encapsulateWhenConditionsForAlgorithms1."
  input list<DAE.Exp> inConditionList;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  output list<DAE.Exp> outConditionList;
  output list<BackendDAE.Var> outVars;
  output list<DAE.Statement> outStmts;
  output list<BackendDAE.Equation> outAdditionalInitialEquations;
  output Integer outIndex;
algorithm
  (outConditionList, outVars, outStmts, outAdditionalInitialEquations, outIndex) := matchcontinue(inConditionList, inSource, inIndex)
    local
      Integer index;
      BackendDAE.WhenEquation elsewhenPart, whenEquation;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> vars1, vars2;
      list<DAE.Statement> stmt1, stmt2;
      String crStr;

      DAE.Exp condition;
      list<DAE.Exp> conditionList;
      DAE.ComponentRef left;
      DAE.Exp right;
      list<DAE.Exp> array;

      list<BackendDAE.Equation> additionalInitialEquations, additionalInitialEquations1;

    case ({}, _, _) equation
    then ({}, {}, {}, {}, inIndex);

    case (condition::conditionList, _, index) equation
      (condition, vars1, stmt1, additionalInitialEquations, index) = encapsulateWhenConditionsForAlgorithms1(condition, inSource, index);
      (conditionList, vars2, stmt2, additionalInitialEquations1, index) = encapsulateWhenConditionsForAlgorithmsWithArrayConditions(conditionList, inSource, index);
      vars1 = listAppend(vars1, vars2);
      stmt1 = listAppend(stmt1, stmt2);
      additionalInitialEquations = listAppend(additionalInitialEquations, additionalInitialEquations1);
    then (condition::conditionList, vars1, stmt1, additionalInitialEquations, index);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEOptimize.mo: function encapsulateWhenConditionsForAlgorithmsWithArrayConditions failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditionsForAlgorithmsWithArrayConditions;

// =============================================================================
// section for ???
//
// =============================================================================

public function getConditionList "function getConditionList
  author: lochel
  This function extracts all when-conditions. A when-condition can only be a
  ComponentRef or initial()-call. If one condion is equal to >initial()<, the
  second output becomes true."
  input DAE.Exp inCondition;
  output list<DAE.ComponentRef> outConditionVarList;
  output Boolean outInitialCall;
algorithm
  (outConditionVarList, outInitialCall) := match (inCondition)
    local
      list<DAE.Exp> conditionList;
      list<DAE.ComponentRef> conditionVarList;
      Boolean initialCall;

    case DAE.ARRAY(array=conditionList) equation
      (conditionVarList, initialCall) = getConditionList1(conditionList, {}, false);
    then (conditionVarList, initialCall);

    else equation
      (conditionVarList, initialCall) = getConditionList1({inCondition}, {}, false);
    then (conditionVarList, initialCall);
  end match;
end getConditionList;

protected function getConditionList1 "function getConditionList1
  author: lochel"
  input list<DAE.Exp> inConditionList;
  input list<DAE.ComponentRef> inConditionVarList;
  input Boolean inInitialCall;
  output list<DAE.ComponentRef> outConditionVarList;
  output Boolean outInitialCall;
algorithm
  (outConditionVarList, outInitialCall) := matchcontinue (inConditionList, inConditionVarList, inInitialCall)
    local
      list<DAE.Exp> conditionList;
      list<DAE.ComponentRef> conditionVarList;
      Boolean initialCall;
      DAE.ComponentRef componentRef;
      DAE.Exp exp;
      String msg;

    case ({}, _, _)
    then (inConditionVarList, inInitialCall);

    case (DAE.CALL(path = Absyn.IDENT(name = "initial"))::conditionList, _, _) equation
      (conditionVarList, initialCall) = getConditionList1(conditionList, inConditionVarList, true);
    then (conditionVarList, initialCall);

    case (DAE.CREF(componentRef=componentRef)::conditionList, _, _) equation
      (conditionVarList, initialCall) = getConditionList1(conditionList, componentRef::inConditionVarList, inInitialCall);
    then (conditionVarList, initialCall);

    case (exp::_, _ ,_) equation
      msg = "./Compiler/BackEnd/BackendDAEOptimize.mo: function getConditionList1 failed for " +& ExpressionDump.printExpStr(exp) +& "\n";
      Error.addMessage(Error.INTERNAL_ERROR, {msg});
   then fail();
  end matchcontinue;
end getConditionList1;



end BackendDAEOptimize;
