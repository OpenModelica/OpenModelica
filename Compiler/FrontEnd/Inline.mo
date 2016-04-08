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

encapsulated package Inline
" file:        Inline.mo
  package:     Inline
  description: inline functions


  This module contains data structures and functions for inline functions.

  The entry point is the inlineCalls function, or inlineCallsInFunctions
  "

public import Absyn;
public import BaseHashTable;
public import DAE;
public import HashTableCG;
public import SCode;
public import Util;

public type Functiontuple = tuple<Option<DAE.FunctionTree>,list<DAE.InlineType>>;

protected import Ceval;
protected import ClassInf;
protected import ComponentReference;
protected import Config;
protected import Debug;
protected import ElementSource;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import Global;
protected import List;
protected import Types;
protected import VarTransform;

public function inlineStartAttribute
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  input DAE.ElementSource isource;
  input Functiontuple fns;
  output Option<DAE.VariableAttributes> outVariableAttributesOption;
  output DAE.ElementSource osource;
  output Boolean b;
algorithm
  (outVariableAttributesOption,osource,b):=matchcontinue (inVariableAttributesOption,isource,fns)
    local
      DAE.ElementSource source;
      DAE.Exp r;
      Option<DAE.Exp> quantity,unit,displayUnit,fixed,nominal,so,min,max;
      Option<DAE.StateSelect> stateSelectOption;
      Option<DAE.Uncertainty> uncertainOption;
      Option<DAE.Distribution> distributionOption;
      Option<DAE.Exp> equationBound;
      Option<Boolean> isProtected,finalPrefix;
      list<DAE.Statement> assrtLst;
    case (NONE(),_,_) then (NONE(),isource,false);
    case
      (SOME(DAE.VAR_ATTR_REAL(quantity=quantity,unit=unit,displayUnit=displayUnit,min=min,max=max,start = SOME(r),
          fixed=fixed,nominal=nominal,stateSelectOption=stateSelectOption,uncertainOption=uncertainOption,
          distributionOption=distributionOption,equationBound=equationBound,isProtected=isProtected,finalPrefix=finalPrefix,
          startOrigin=so)),_,_)
      equation
        (r,source,true,_) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,max,SOME(r),fixed,nominal,
          stateSelectOption,uncertainOption,distributionOption,equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_INT(quantity=quantity,min=min,max=max,start = SOME(r),
          fixed=fixed,uncertainOption=uncertainOption,distributionOption=distributionOption,equationBound=equationBound,
          isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,_) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_INT(quantity,min,max,SOME(r),fixed,uncertainOption,distributionOption,equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_BOOL(quantity=quantity,start = SOME(r),
          fixed=fixed,equationBound=equationBound,isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,_) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_BOOL(quantity,SOME(r),fixed,equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_STRING(quantity=quantity,start = SOME(r),
          equationBound=equationBound,isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,_) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_STRING(quantity,SOME(r),equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_ENUMERATION(quantity=quantity,min=min,max=max,start = SOME(r),
          fixed=fixed,equationBound=equationBound,
          isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,_) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_ENUMERATION(quantity,min,max,SOME(r),fixed,equationBound,isProtected,finalPrefix,so)),source,true);
    else (inVariableAttributesOption,isource,false);
  end matchcontinue;
end inlineStartAttribute;

public function inlineCallsInFunctions
"inlines calls in DAEElements"
  input list<DAE.Function> inElementList;
  input Functiontuple inFunctions;
  input list<DAE.Function> iAcc;
  output list<DAE.Function> outElementList;
algorithm
  outElementList := matchcontinue(inElementList,inFunctions,iAcc)
    local
      list<DAE.Function> cdr;
      list<DAE.Element> elist,elist_1;
      DAE.Function el,res;
      DAE.Type t;
      Boolean partialPrefix, isImpure;
      Absyn.Path p;
      DAE.ExternalDecl ext;
      DAE.InlineType inlineType;
      list<DAE.FunctionDefinition> funcDefs;
      DAE.ElementSource source;
      Option<SCode.Comment> cmt;
      SCode.Visibility visibility;

    case({},_,_) then listReverse(iAcc);

    case (DAE.FUNCTION(p,DAE.FUNCTION_DEF(body = elist)::funcDefs,t,visibility,partialPrefix,isImpure,inlineType,source,cmt) :: cdr,_,_)
      equation
        (elist_1,true)= inlineDAEElements(elist,inFunctions,{},false);
        res = DAE.FUNCTION(p,DAE.FUNCTION_DEF(elist_1)::funcDefs,t,visibility,partialPrefix,isImpure,inlineType,source,cmt);
      then
        inlineCallsInFunctions(cdr,inFunctions,res::iAcc);
    // external functions
    case (DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist,ext)::funcDefs,t,visibility,partialPrefix,isImpure,inlineType,source,cmt) :: cdr,_,_)
      equation
        (elist_1,true)= inlineDAEElements(elist,inFunctions,{},false);
        res = DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist_1,ext)::funcDefs,t,visibility,partialPrefix,isImpure,inlineType,source,cmt);
      then
        inlineCallsInFunctions(cdr,inFunctions,res::iAcc);

    case(el :: cdr,_,_)
      then
        inlineCallsInFunctions(cdr,inFunctions,el::iAcc);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Inline.inlineCallsInFunctions failed"});
      then fail();
  end matchcontinue;
end inlineCallsInFunctions;


protected function inlineDAEElementsLst
  input list<list<DAE.Element>> inElementList;
  input Functiontuple inFunctions;
  input list<list<DAE.Element>> iAcc;
  input Boolean iInlined;
  output list<list<DAE.Element>> outElementList;
  output Boolean OInlined;
algorithm
  (outElementList,OInlined) := match(inElementList,inFunctions,iAcc,iInlined)
    local
      list<DAE.Element> elem;
      list<list<DAE.Element>> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (elem::rest,_,_,_)
      equation
        (elem,inlined) = inlineDAEElements(elem,inFunctions,{},false);
        (acc,inlined) = inlineDAEElementsLst(rest,inFunctions,elem::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineDAEElementsLst;

protected function inlineDAEElements
  input list<DAE.Element> inElementList;
  input Functiontuple inFunctions;
  input list<DAE.Element> iAcc;
  input Boolean iInlined;
  output list<DAE.Element> outElementList;
  output Boolean OInlined;
algorithm
  (outElementList,OInlined) := match(inElementList,inFunctions,iAcc,iInlined)
    local
      DAE.Element elem;
      list<DAE.Element> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (elem::rest,_,_,_)
      equation
        (elem,inlined) = inlineDAEElement(elem,inFunctions);
        (acc,inlined) = inlineDAEElements(rest,inFunctions,elem::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineDAEElements;

protected function inlineDAEElement
"inlines calls in DAEElements"
  input DAE.Element inElement;
  input Functiontuple inFunctions;
  output DAE.Element outElement;
  output Boolean inlined;
algorithm
  (outElement,inlined) := matchcontinue(inElement,inFunctions)
    local
      Functiontuple fns;
      list<DAE.Element> elist,elist_1;
      list<list<DAE.Element>> dlist,dlist_1;
      DAE.Element el,el_1;
      DAE.ComponentRef componentRef;
      DAE.VarKind kind;
      DAE.VarDirection direction;
      DAE.VarParallelism parallelism;
      DAE.VarVisibility protection;
      DAE.Type ty;
      DAE.Exp binding,binding_1,exp,exp_1,exp1,exp1_1,exp2,exp2_1,exp3,exp3_1;
      DAE.InstDims dims;
      DAE.ConnectorType ct;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter;
      DAE.Dimensions dimension;
      DAE.Algorithm alg,alg_1;
      String i;
      Absyn.Path p;
      list<DAE.Exp> explst,explst_1;
      DAE.ElementSource source;
      Boolean b1,b2,b3;
      list<DAE.Statement> assrtLst;

    case (DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,SOME(binding),dims,ct,
                 source,variableAttributesOption,absynCommentOption,innerOuter),fns)
      equation
        (binding_1,source,true,_) = inlineExp(binding,fns,source);
      then
        (DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,SOME(binding_1),dims,ct,
                      source,variableAttributesOption,absynCommentOption,innerOuter),true);

    case (DAE.DEFINE(componentRef,exp,source) ,fns)
      equation
        (exp_1,source,true,_) = inlineExp(exp,fns,source);
      then
        (DAE.DEFINE(componentRef,exp_1,source),true);

    case(DAE.INITIALDEFINE(componentRef,exp,source) ,fns)
      equation
        (exp_1,source,true,_) = inlineExp(exp,fns,source);
      then
        (DAE.INITIALDEFINE(componentRef,exp_1,source),true);

    case(DAE.EQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,_) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,_) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.EQUATION(exp1_1,exp2_1,source),true);

    case(DAE.ARRAY_EQUATION(dimension,exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,_) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,_) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.ARRAY_EQUATION(dimension,exp1_1,exp2_1,source),true);

    case(DAE.INITIAL_ARRAY_EQUATION(dimension,exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,_) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,_) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.INITIAL_ARRAY_EQUATION(dimension,exp1_1,exp2_1,source),true);

    case(DAE.COMPLEX_EQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,_) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,_) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.COMPLEX_EQUATION(exp1_1,exp2_1,source),true);

    case(DAE.INITIAL_COMPLEX_EQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,_) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,_) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.INITIAL_COMPLEX_EQUATION(exp1_1,exp2_1,source),true);

    case(DAE.WHEN_EQUATION(exp,elist,SOME(el),source),fns)
      equation
        (exp_1,source,b1,_) = inlineExp(exp,fns,source);
        (elist_1,b2) = inlineDAEElements(elist,fns,{},false);
        (el_1,b3) = inlineDAEElement(el,fns);
        true = b1 or b2 or b3;
      then
        (DAE.WHEN_EQUATION(exp_1,elist_1,SOME(el_1),source),true);

    case(DAE.WHEN_EQUATION(exp,elist,NONE(),source),fns)
      equation
        (exp_1,source,b1,_) = inlineExp(exp,fns,source);
        (elist_1,b2) = inlineDAEElements(elist,fns,{},false);
        true = b1 or b2;
      then
        (DAE.WHEN_EQUATION(exp_1,elist_1,NONE(),source),true);

    case(DAE.IF_EQUATION(explst,dlist,elist,source) ,fns)
      equation
        (explst_1,source,b1) = inlineExps(explst,fns,source);
        (dlist_1,b2) = inlineDAEElementsLst(dlist,fns,{},false);
        (elist_1,b3) = inlineDAEElements(elist,fns,{},false);
        true = b1 or b2 or b3;
      then
        (DAE.IF_EQUATION(explst_1,dlist_1,elist_1,source),true);

    case(DAE.INITIAL_IF_EQUATION(explst,dlist,elist,source) ,fns)
      equation
        (explst_1,source,b1) = inlineExps(explst,fns,source);
        (dlist_1,b2) = inlineDAEElementsLst(dlist,fns,{},false);
        (elist_1,b3) = inlineDAEElements(elist,fns,{},false);
        true = b1 or b2 or b3;
      then
        (DAE.INITIAL_IF_EQUATION(explst_1,dlist_1,elist_1,source),true);

    case(DAE.INITIALEQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,_,_) = inlineExp(exp1,fns,source);
        (exp2_1,source,_,_) = inlineExp(exp2,fns,source);
      then
        (DAE.INITIALEQUATION(exp1_1,exp2_1,source),true);

    case((DAE.ALGORITHM(alg,source)),fns)
      equation
        (alg_1,true) = inlineAlgorithm(alg,fns);
      then
        (DAE.ALGORITHM(alg_1,source),true);

    case((DAE.INITIALALGORITHM(alg,source)) ,fns)
      equation
        (alg_1,true) = inlineAlgorithm(alg,fns);
      then
        (DAE.INITIALALGORITHM(alg_1,source),true);

    case(DAE.COMP(i,elist,source,absynCommentOption),fns)
      equation
        (elist_1,true) = inlineDAEElements(elist,fns,{},false);
      then
        (DAE.COMP(i,elist_1,source,absynCommentOption),true);

    case(DAE.ASSERT(exp1,exp2,exp3,source) ,fns)
      equation
        (exp1_1,source,b1,_) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,_) = inlineExp(exp2,fns,source);
        (exp3_1,source,b3,_) = inlineExp(exp3,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.ASSERT(exp1_1,exp2_1,exp3_1,source),true);

    case(DAE.TERMINATE(exp,source),fns)
      equation
        (exp_1,source,true,_) = inlineExp(exp,fns,source);
      then
        (DAE.TERMINATE(exp_1,source),true);

    case(DAE.REINIT(componentRef,exp,source),fns)
      equation
        (exp_1,source,true,_) = inlineExp(exp,fns,source);
      then
        (DAE.REINIT(componentRef,exp_1,source),true);

    case(DAE.NORETCALL(exp,source),fns)
      equation
        (exp,source,true,_) = inlineExp(exp,fns,source);
      then
        (DAE.NORETCALL(exp,source),true);

    case(DAE.INITIAL_NORETCALL(exp,source),fns)
      equation
        (exp,source,true,_) = inlineExp(exp,fns,source);
      then
        (DAE.INITIAL_NORETCALL(exp,source),true);

    case(el,_)
      then
        (el,false);
  end matchcontinue;
end inlineDAEElement;

public function inlineAlgorithm
"inline calls in an DAE.Algorithm"
  input DAE.Algorithm inAlgorithm;
  input Functiontuple inElementList;
  output DAE.Algorithm outAlgorithm;
  output Boolean inlined;
algorithm
  (outAlgorithm,inlined) := matchcontinue(inAlgorithm,inElementList)
    local
      list<DAE.Statement> stmts,stmts_1;
      Functiontuple fns;
    case(DAE.ALGORITHM_STMTS(stmts),fns)
      equation
        (stmts_1,inlined) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.ALGORITHM_STMTS(stmts_1),inlined);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inline.inlineAlgorithm failed\n");
      then
        fail();
  end matchcontinue;
end inlineAlgorithm;

public function inlineStatements
  input list<DAE.Statement> inStatements;
  input Functiontuple inElementList;
  input list<DAE.Statement> iAcc;
  input Boolean iInlined;
  output list<DAE.Statement> outStatements;
  output Boolean OInlined;
algorithm
  (outStatements,OInlined) := match(inStatements,inElementList,iAcc,iInlined)
    local
      DAE.Statement stmt;
      list<DAE.Statement> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (stmt::rest,_,_,_)
      equation
        (stmt,inlined) = inlineStatement(stmt,inElementList);
        (acc,inlined) = inlineStatements(rest,inElementList,stmt::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineStatements;

protected function inlineStatement
"inlines calls in an DAE.Statement"
  input DAE.Statement inStatement;
  input Functiontuple inElementList;
  output DAE.Statement outStatement;
  output Boolean inlined;
algorithm
  (outStatement,inlined) := matchcontinue(inStatement,inElementList)
    local
      Functiontuple fns;
      DAE.Statement stmt,stmt_1;
      DAE.Type t;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1,e3,e3_1;
      list<DAE.Exp> explst,explst_1;
      DAE.ComponentRef cref;
      DAE.Else a_else,a_else_1;
      list<DAE.Statement> stmts,stmts_1;
      Boolean b,b1,b2,b3;
      String i;
      Integer ix;
      DAE.ElementSource source;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;
      list<DAE.Statement> assrtLst;
    case (DAE.STMT_ASSIGN(t,e1,e2,source),fns)
      equation
        (e1_1,source,b1,_) = inlineExp(e1,fns,source);
        (e2_1,source,b2,_) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (DAE.STMT_ASSIGN(t,e1_1,e2_1,source),true);
    case(DAE.STMT_TUPLE_ASSIGN(t,explst,e,source),fns)
      equation
        (explst_1,source,b1) = inlineExps(explst,fns,source);
        (e_1,source,b2,_) = inlineExp(e,fns,source);
        true = b1 or b2;
      then
        (DAE.STMT_TUPLE_ASSIGN(t,explst_1,e_1,source),true);
    case(DAE.STMT_ASSIGN_ARR(t,e1,e2,source),fns)
      equation
        (e1_1,source,b1,_) = inlineExp(e1,fns,source);
        (e2_1,source,b2,_) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (DAE.STMT_ASSIGN_ARR(t,e1_1,e2_1,source),true);
    case(DAE.STMT_IF(e,stmts,a_else,source),fns)
      equation
        (e_1,source,b1,_) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        (a_else_1,source,b3) = inlineElse(a_else,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.STMT_IF(e_1,stmts_1,a_else_1,source),true);
    case(DAE.STMT_FOR(t,b,i,ix,e,stmts,source),fns)
      equation
        (e_1,source,b1,_) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        true = b1 or b2;
      then
        (DAE.STMT_FOR(t,b,i,ix,e_1,stmts_1,source),true);
    case(DAE.STMT_WHILE(e,stmts,source),fns)
      equation
        (e_1,source,b1,_) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        true = b1 or b2;
      then
        (DAE.STMT_WHILE(e_1,stmts_1,source),true);
    case(DAE.STMT_WHEN(e,conditions,initialCall,stmts,SOME(stmt),source),fns)
      equation
        (e_1,source,b1,_) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        (stmt_1,b3) = inlineStatement(stmt,fns);
        true = b1 or b2 or b3;
      then
        (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts_1,SOME(stmt_1),source),true);
    case(DAE.STMT_WHEN(e,conditions,initialCall,stmts,NONE(),source),fns)
      equation
        (e_1,source,b1,_) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        true = b1 or b2;
      then
        (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts_1,NONE(),source),true);
    case(DAE.STMT_ASSERT(e1,e2,e3,source),fns)
      equation
        (e1_1,source,b1,_) = inlineExp(e1,fns,source);
        (e2_1,source,b2,_) = inlineExp(e2,fns,source);
        (e3_1,source,b3,_) = inlineExp(e3,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.STMT_ASSERT(e1_1,e2_1,e3_1,source),true);
    case(DAE.STMT_TERMINATE(e,source),fns)
      equation
        (e_1,source,true,_) = inlineExp(e,fns,source);
      then
        (DAE.STMT_TERMINATE(e_1,source),true);
    case(DAE.STMT_REINIT(e1,e2,source),fns)
      equation
        (e1_1,source,b1,_) = inlineExp(e1,fns,source);
        (e2_1,source,b2,_) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (DAE.STMT_REINIT(e1_1,e2_1,source),true);
    case(DAE.STMT_NORETCALL(e,source),fns)
      equation
        (e_1,source,true,_) = inlineExp(e,fns,source);
      then
        (DAE.STMT_NORETCALL(e_1,source),true);
    case(DAE.STMT_FAILURE(stmts,source),fns)
      equation
        (stmts_1,true) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.STMT_FAILURE(stmts_1,source),true);
    case(stmt,_) then (stmt,false);
  end matchcontinue;
end inlineStatement;

protected function inlineElse
"inlines calls in an DAE.Else"
  input DAE.Else inElse;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output DAE.Else outElse;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outElse,outSource,inlined) := matchcontinue(inElse,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Else a_else,a_else_1;
      DAE.Exp e,e_1;
      list<DAE.Statement> stmts,stmts_1;
      DAE.ElementSource source;
      Boolean b1,b2,b3;
      list<DAE.Statement> assrtLst;
    case (DAE.ELSEIF(e,stmts,a_else),fns,source)
      equation
        (e_1,source,b1,_) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        (a_else_1,source,b3) = inlineElse(a_else,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.ELSEIF(e_1,stmts_1,a_else_1),source,true);
    case (DAE.ELSE(stmts),fns,source)
      equation
        (stmts_1,true) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.ELSE(stmts_1),source,true);
    case (a_else,_,source) then (a_else,source,false);
  end matchcontinue;
end inlineElse;

public function inlineExpOpt "
function: inlineExpOpt
  inlines calls in an DAE.Exp"
  input Option<DAE.Exp> inExpOption;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output Option<DAE.Exp> outExpOption;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outExpOption,outSource,inlined) := match(inExpOption,inElementList,inSource)
    local
      DAE.Exp exp;
      DAE.ElementSource source;
      Boolean b;
      list<DAE.Statement> assrtLst;
    case(NONE(),_,_) then (NONE(),inSource,false);
    case(SOME(exp),_,_)
      equation
        (exp,source,b,_) = inlineExp(exp,inElementList,inSource);
      then
        (SOME(exp),source,b);
  end match;
end inlineExpOpt;

public function inlineExp "
function: inlineExp
  inlines calls in a DAE.Exp"
  input DAE.Exp inExp;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output DAE.Exp outExp;
  output DAE.ElementSource outSource;
  output Boolean inlined;
  output list<DAE.Statement> assrtLstOut;
algorithm
  (outExp,outSource,inlined,assrtLstOut) := matchcontinue (inExp,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e_2;
      DAE.ElementSource source;
      list<DAE.Statement> assrtLst;
      DAE.EquationExp eq;

    // never inline WILD!
    case (DAE.CREF(componentRef = DAE.WILD()),_,_) then (inExp,inSource,false,{});

    case (e,fns,source)
      algorithm
        (e_1,assrtLst) := Expression.traverseExpBottomUp(e,function inlineCall(fns=fns),{});
        false := referenceEq(e, e_1);
        if Flags.isSet(Flags.INFO_XML_OPERATIONS) then
          eq := DAE.PARTIAL_EQUATION(e_1);
          source := ElementSource.addSymbolicTransformation(source,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e_1)));
          (DAE.PARTIAL_EQUATION(e_2),source) := ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e_1), source);
        else
          e_2 := ExpressionSimplify.simplify(e_1);
        end if;
      then
        (e_2,source,true,assrtLst);

    else (inExp,inSource,false,{});
  end matchcontinue;
end inlineExp;

public function forceInlineExp "
function: inlineExp
  inlines calls in an DAE.Exp"
  input DAE.Exp inExp;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output DAE.Exp outExp;
  output DAE.ElementSource outSource;
  output Boolean inlineperformed;
algorithm
  (outExp,outSource,inlineperformed) := matchcontinue (inExp,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e_2;
      DAE.ElementSource source;
      list<DAE.Statement> assrtLst;
      DAE.FunctionTree functionTree;
    case (e,(SOME(functionTree),_),source)
      equation
        true = Expression.isConst(inExp);
        e_1 = Ceval.cevalSimpleWithFunctionTreeReturnExp(inExp, functionTree);
        source = ElementSource.addSymbolicTransformation(source,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e_1)));
      then (e_1,source,true);
    case (e,fns,source)
      equation
        (e_1,_) = Expression.traverseExpBottomUp(e,function forceInlineCall(fns=fns),{});
        false = referenceEq(e, e_1);
        source = ElementSource.addSymbolicTransformation(source,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e_1)));
        (DAE.PARTIAL_EQUATION(e_2),source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e_1), source);
      then
        (e_2,source,true);
    else (inExp,inSource,false);
  end matchcontinue;
end forceInlineExp;

public function inlineExps "
function: inlineExp
  inlines calls in an DAE.Exp"
  input list<DAE.Exp> inExps;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output list<DAE.Exp> outExps;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outExps,outSource,inlined) := inlineExpsWork(inExps,inElementList,inSource,{},false);
end inlineExps;

protected function inlineExpsWork "
function: inlineExp
  inlines calls in an DAE.Exp"
  input list<DAE.Exp> inExps;
  input Functiontuple fns;
  input DAE.ElementSource inSource;
  input list<DAE.Exp> iAcc;
  input Boolean iInlined;
  output list<DAE.Exp> outExps;
  output DAE.ElementSource outSource;
  output Boolean oInlined;
algorithm
  (outExps,outSource,oInlined) := match (inExps,fns,inSource,iAcc,iInlined)
    local
      DAE.Exp e;
      list<DAE.Exp> exps;
      DAE.ElementSource source;
      Boolean b;
      list<DAE.Statement> assrtLst;

    case ({},_,_,_,_) then (listReverse(iAcc),inSource,iInlined);
    case (e::exps,_,_,_,_)
      equation
        (e,source,b,_) = inlineExp(e,fns,inSource);
        (exps,source,b) = inlineExpsWork(exps,fns,source,e::iAcc,b or iInlined);
      then
        (exps,source,b);
  end match;
end inlineExpsWork;

public function checkExpsTypeEquiv
"@author: adrpo
  check two types for equivalence"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean bEquiv;
algorithm
  bEquiv := match(inExp1, inExp2)
    local
      DAE.Type ty1,ty2;
      Boolean b;
    case (_, _)
      equation
        if Config.acceptMetaModelicaGrammar() then
          // adrpo: DO NOT COMPARE TYPES for equivalence for MetaModelica!
          b = true;
        else // compare
          ty1 = Expression.typeof(inExp1);
          ty2 = Expression.typeof(inExp2);
          ty2 = Types.traverseType(ty2, -1, Types.makeExpDimensionsUnknown);
          b = Types.equivtypes(ty1,ty2);
        end if;
      then b;
  end match;
end checkExpsTypeEquiv;

protected function inlineCall
"replaces an inline call with the expression from the function"
  input output DAE.Exp exp;
  input output list<DAE.Statement> assrtLst;
  input Functiontuple fns;
algorithm
  (exp,assrtLst) := matchcontinue exp
    local
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      list<DAE.ComponentRef> lst_cr;
      DAE.ElementSource source;
      DAE.Exp newExp,newExp1, e1, cond, msg, level, newAssrtCond, newAssrtMsg, newAssrtLevel;
      DAE.InlineType inlineType;
      DAE.Statement assrt;
      HashTableCG.HashTable checkcr;
      list<DAE.Statement> stmts,assrtStmts;
      VarTransform.VariableReplacements repl;
      Boolean generateEvents;
      Option<SCode.Comment> comment;
      DAE.Type ty;

    // If we disable inlining by use of flags, we still inline builtin functions
    case DAE.CALL(attr=DAE.CALL_ATTR(inlineType=inlineType))
      equation
        false = Flags.isSet(Flags.INLINE_FUNCTIONS);
        false = valueEq(DAE.BUILTIN_EARLY_INLINE(), inlineType);
      then (exp,assrtLst);

    case (e1 as DAE.CALL(p,args,DAE.CALL_ATTR(ty=ty,inlineType=inlineType)))
      equation
        //true = DAEUtil.convertInlineTypeToBool(inlineType);
        true = checkInlineType(inlineType,fns);
        (fn,comment) = getFunctionBody(p,fns);
        (checkcr,repl) = getInlineHashTableVarTransform();
        if (Config.acceptMetaModelicaGrammar())
        then // MetaModelica
          crefs = List.map(fn,getInputCrefs);
          crefs = List.select(crefs,removeWilds);
          argmap = List.threadTuple(crefs,args);
          false = List.exist(fn,DAEUtil.isProtectedVar);
          newExp = getRhsExp(fn);
          // compare types
          true = checkExpsTypeEquiv(e1, newExp);
          (argmap,checkcr) = extendCrefRecords(argmap,checkcr);
          // add noEvent to avoid events as usually for functions
          // MSL 3.2.1 need GenerateEvents to disable this
          newExp = Expression.addNoEventToRelationsAndConds(newExp);
          (newExp,(_,_,true)) = Expression.traverseExpBottomUp(newExp,replaceArgs,(argmap,checkcr,true));
          // for inlinecalls in functions
          (newExp1,assrtLst) = Expression.traverseExpBottomUp(newExp,function inlineCall(fns=fns),assrtLst);
        else // normal Modelica
          // get inputs, body and output
          (crefs,lst_cr,stmts,repl) = getFunctionInputsOutputBody(fn,{},{},{},repl);
          // merge statements to one line
          (repl,assrtStmts) = mergeFunctionBody(stmts,repl,{});
          // depend on detection of assert or not
          if (listEmpty(assrtStmts))
          then // no assert detected
            newExp = Expression.makeTuple(list( getReplacementCheckComplex(repl,cr,ty) for cr in lst_cr));
            // compare types
            true = checkExpsTypeEquiv(e1, newExp);
            argmap = List.threadTuple(crefs,args);
            (checkcr,_) = getInlineHashTableVarTransform();
            (argmap,checkcr) = extendCrefRecords(argmap,checkcr);
            // add noEvent to avoid events as usually for functions
            // MSL 3.2.1 need GenerateEvents to disable this
            generateEvents = hasGenerateEventsAnnotation(comment);
            newExp = if not generateEvents then Expression.addNoEventToRelationsAndConds(newExp) else newExp;
            (newExp,(_,_,true)) = Expression.traverseExpBottomUp(newExp,replaceArgs,(argmap,checkcr,true));
            // for inlinecalls in functions
            (newExp1,assrtLst) = Expression.traverseExpBottomUp(newExp,function inlineCall(fns=fns),assrtLst);
          else // assert detected
            true = listLength(assrtStmts) == 1;
            assrt = listHead(assrtStmts);
            DAE.STMT_ASSERT() = assrt;
            //newExp = getReplacementCheckComplex(repl,cr,ty); // the function that replaces the output variable
            newExp = Expression.makeTuple(list( getReplacementCheckComplex(repl,cr,ty) for cr in lst_cr));
            // compare types
            true = checkExpsTypeEquiv(e1, newExp);
            argmap = List.threadTuple(crefs,args);
            (argmap,checkcr) = extendCrefRecords(argmap,checkcr);
            // add noEvent to avoid events as usually for functions
            // MSL 3.2.1 need GenerateEvents to disable this
            generateEvents = hasGenerateEventsAnnotation(comment);
            newExp = if not generateEvents then Expression.addNoEventToRelationsAndConds(newExp) else newExp;
            (newExp,(_,_,true)) = Expression.traverseExpBottomUp(newExp,replaceArgs,(argmap,checkcr,true));
            assrt = inlineAssert(assrt,fns,argmap,checkcr);
            // for inlinecalls in functions
            (newExp1,assrtLst) = Expression.traverseExpBottomUp(newExp,function inlineCall(fns=fns),assrt::assrtLst);
          end if;
        end if;
      then
        (newExp1,assrtLst);

    else (exp,assrtLst);

  end matchcontinue;
end inlineCall;


protected function inlineAssert "inlines an assert.
author:Waurich TUD 2013-10"
  input DAE.Statement assrtIn;
  input Functiontuple fns;
  input list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
  input HashTableCG.HashTable checkcr;
  output DAE.Statement assrtOut;
protected
  DAE.ElementSource source;
  DAE.Exp cond, msg, level;
algorithm
  DAE.STMT_ASSERT(cond=cond, msg=msg, level=level, source=source) := assrtIn;
  (cond,(_,_,true)) := Expression.traverseExpBottomUp(cond,replaceArgs,(argmap,checkcr,true));
  //print("ASSERT inlined: "+ExpressionDump.printExpStr(cond)+"\n");
  (msg,(_,_,true)) := Expression.traverseExpBottomUp(msg,replaceArgs,(argmap,checkcr,true));
  // These clear checkcr/repl and need to be performed last
  // (cond,_,_,_) := inlineExp(cond,fns,source);
  // (msg,_,_,_) := inlineExp(msg,fns,source);
  assrtOut := DAE.STMT_ASSERT(cond, msg, level, source);
end inlineAssert;


protected function hasGenerateEventsAnnotation
  input Option<SCode.Comment> comment;
  output Boolean b;
algorithm
  b := match(comment)
    local
      SCode.Annotation anno;
      list<SCode.Annotation> annos;
    case (SOME(SCode.COMMENT(annotation_=SOME(anno))))
      then
        SCode.hasBooleanNamedAnnotation(anno,"GenerateEvents");
    else false;
  end match;
end hasGenerateEventsAnnotation;

protected function dumpArgmap
  input tuple<DAE.ComponentRef, DAE.Exp> inTpl;
protected
  DAE.ComponentRef cr;
  DAE.Exp exp;
algorithm
  (cr,exp) := inTpl;
  print(ComponentReference.printComponentRefStr(cr) + " -> " + ExpressionDump.printExpStr(exp) + "\n");
end dumpArgmap;

public function forceInlineCall
"replaces an inline call with the expression from the function"
  input output DAE.Exp exp;
  input output list<DAE.Statement> assrtLst;
  input Functiontuple fns;
algorithm
  (exp,assrtLst) := matchcontinue exp
    local
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      list<DAE.ComponentRef> lst_cr;
      list<DAE.ComponentRef> crefs;
      list<DAE.Statement> assrtStmts;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp newExp,newExp1, e1;
      DAE.InlineType inlineType;
      DAE.Statement assrt;
      HashTableCG.HashTable checkcr;
      list<DAE.Statement> stmts;
      VarTransform.VariableReplacements repl;
      Boolean generateEvents,b;
      Option<SCode.Comment> comment;

    case (e1 as DAE.CALL(p,args,DAE.CALL_ATTR(inlineType=inlineType)))
      equation
        //print(printInlineTypeStr(inlineType));
        false = Config.acceptMetaModelicaGrammar();
        true = checkInlineType(inlineType,fns);
        (fn,comment) = getFunctionBody(p,fns);
        (checkcr,repl) = getInlineHashTableVarTransform();
        // get inputs, body and output
        (crefs,lst_cr,stmts,repl) = getFunctionInputsOutputBody(fn,{},{},{},repl);
        // merge statements to one line
        (repl,_) = mergeFunctionBody(stmts,repl,{});
        //newExp = VarTransform.getReplacement(repl,cr);
        newExp = Expression.makeTuple(list( VarTransform.getReplacement(repl,cr) for cr in lst_cr));
        // compare types
        true = checkExpsTypeEquiv(e1, newExp);
        argmap = List.threadTuple(crefs,args);
        (argmap,checkcr) = extendCrefRecords(argmap,checkcr);
        // add noEvent to avoid events as usually for functions
        // MSL 3.2.1 need GenerateEvents to disable this
        generateEvents = hasGenerateEventsAnnotation(comment);
        newExp = if not generateEvents then Expression.addNoEventToRelationsAndConds(newExp) else newExp;
        (newExp,(_,_,true)) = Expression.traverseExpBottomUp(newExp,replaceArgs,(argmap,checkcr,true));
        // for inlinecalls in functions
        (newExp1,assrtLst) = Expression.traverseExpBottomUp(newExp,function forceInlineCall(fns=fns),assrtLst);
      then (newExp1,assrtLst);

    else (exp,assrtLst);
  end matchcontinue;
end forceInlineCall;

protected function mergeFunctionBody
  input list<DAE.Statement> iStmts;
  input VarTransform.VariableReplacements iRepl;
  input list<DAE.Statement> assertStmtsIn;
  output VarTransform.VariableReplacements oRepl;
  output list<DAE.Statement> assertStmtsOut;
algorithm
  (oRepl,assertStmtsOut) := match(iStmts,iRepl,assertStmtsIn)
    local
      list<DAE.Statement> stmts;
      VarTransform.VariableReplacements repl;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      DAE.Exp exp, exp1, exp2;
      DAE.Statement stmt;
      list<DAE.Exp> explst;
      list<DAE.Statement> assertStmts;
    case ({},_,_) then (iRepl,assertStmtsIn);
    case (DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = cr), exp = exp)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        repl = VarTransform.addReplacementNoTransitive(iRepl,cr,exp);
        (repl,assertStmts) = mergeFunctionBody(stmts,repl,assertStmtsIn);
      then
        (repl,assertStmts);
    case (DAE.STMT_ASSIGN_ARR(lhs = DAE.CREF(componentRef = cr), exp = exp)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        repl = VarTransform.addReplacementNoTransitive(iRepl,cr,exp);
        (repl,assertStmts) = mergeFunctionBody(stmts,repl,assertStmtsIn);
      then
        (repl,assertStmts);
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = explst, exp = exp)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        repl = addTplAssignToRepl(explst,1,exp,iRepl);
        (repl,assertStmts) = mergeFunctionBody(stmts,repl,assertStmtsIn);
      then
        (repl,assertStmts);
    case (DAE.STMT_ASSERT(cond = exp, msg = exp1, level = exp2, source = source)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        (exp1,_) = VarTransform.replaceExp(exp1,iRepl,NONE());
        (exp2,_) = VarTransform.replaceExp(exp2,iRepl,NONE());
        stmt = DAE.STMT_ASSERT(exp,exp1,exp2,source);
        (repl,assertStmts) = mergeFunctionBody(stmts,iRepl,stmt::assertStmtsIn);
      then
        (repl,assertStmts);
  end match;
end mergeFunctionBody;

protected function addTplAssignToRepl
  input list<DAE.Exp> explst;
  input Integer indx;
  input DAE.Exp iExp;
  input VarTransform.VariableReplacements iRepl;
  output VarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(explst,indx,iExp,iRepl)
    local
      VarTransform.VariableReplacements repl;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      list<DAE.Exp> rest;
      DAE.Type tp;
    case ({},_,_,_) then iRepl;
    case (DAE.CREF(componentRef = cr,ty=tp)::rest,_,_,_)
      equation
        exp = DAE.TSUB(iExp,indx,tp);
        repl = VarTransform.addReplacementNoTransitive(iRepl,cr,exp);
      then
        addTplAssignToRepl(rest,indx+1,iExp,repl);
  end match;
end addTplAssignToRepl;

protected function getFunctionInputsOutputBody
  input list<DAE.Element> fn;
  input list<DAE.ComponentRef> iInputs;
  input list<DAE.ComponentRef> iOutput;
  input list<DAE.Statement> iBody;
  input VarTransform.VariableReplacements iRepl;
  output list<DAE.ComponentRef> oInputs;
  output list<DAE.ComponentRef> oOutput;
  output list<DAE.Statement> oBody;
  output VarTransform.VariableReplacements oRepl;
algorithm
  (oInputs,oOutput,oBody,oRepl) := match(fn,iInputs,iOutput,iBody,iRepl)
    local
      DAE.ComponentRef cr;
      list<DAE.Statement> st;
      list<DAE.Element> rest;
      VarTransform.VariableReplacements repl;
      Option<DAE.Exp> binding;
      DAE.Type tp;
    case ({},_,_,_,_) then (listReverse(iInputs),listReverse(iOutput),iBody,iRepl);
    case (DAE.VAR(componentRef=cr,direction=DAE.INPUT())::rest,_,_,_,_)
      equation
         (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,cr::iInputs,iOutput,iBody,iRepl);
      then
        (oInputs,oOutput,oBody,repl);
    case (DAE.VAR(componentRef=cr,direction=DAE.OUTPUT())::rest,_,_,_,_)
      equation
        (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,iInputs,cr::iOutput,iBody,iRepl);
      then
        (oInputs,oOutput,oBody,repl);
    case (DAE.VAR(componentRef=cr,protection=DAE.PROTECTED(),binding=binding)::rest,_,_,_,_)
      equation
        // use type of cref, since var type is different
        // and has no hint on array or record type
        tp = ComponentReference.crefTypeFull(cr);
        false = Expression.isArrayType(tp);
        false = Expression.isRecordType(tp);
        repl = addOptBindingReplacements(cr,binding,iRepl);
        (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,iInputs,iOutput,iBody,repl);
      then
        (oInputs,oOutput,oBody,repl);
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(st))::rest,_,_,_,_)
      equation
        st = listAppend(iBody,st);
        (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,iInputs,iOutput,st,iRepl);
      then
        (oInputs,oOutput,oBody,repl);
  end match;
end getFunctionInputsOutputBody;

protected function addOptBindingReplacements
  input DAE.ComponentRef cr;
  input Option<DAE.Exp> binding;
  input VarTransform.VariableReplacements iRepl;
  output VarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(cr,binding,iRepl)
    local
      DAE.Exp e;
    case (_,SOME(e),_) then addReplacement(cr, e, iRepl);
    case (_,NONE(),_) then iRepl;
  end match;
end addOptBindingReplacements;

protected function addReplacement
  input DAE.ComponentRef iCr;
  input DAE.Exp iExp;
  input VarTransform.VariableReplacements iRepl;
  output VarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(iCr,iExp,iRepl)
    local
      DAE.Type tp;
    case (DAE.CREF_IDENT(identType=tp),_,_)
      equation
        false = Expression.isArrayType(tp);
        false = Expression.isRecordType(tp);
      then VarTransform.addReplacement(iRepl, iCr, iExp);
  end match;
end addReplacement;

protected function checkInlineType "
Author: Frenkel TUD, 2010-05"
  input DAE.InlineType inIT;
  input Functiontuple fns;
  output Boolean outb;
algorithm
  outb := matchcontinue(inIT,fns)
    local
      DAE.InlineType it;
      list<DAE.InlineType> itlst;
      Boolean b;
    case (it,(_,itlst))
      equation
       b = listMember(it,itlst);
      then b;
    else false;
  end matchcontinue;
end checkInlineType;

protected function extendCrefRecords
"extends crefs from records"
  input list<tuple<DAE.ComponentRef, DAE.Exp>> inArgmap;
  input HashTableCG.HashTable inCheckCr;
  output list<tuple<DAE.ComponentRef, DAE.Exp>> outArgmap;
  output HashTableCG.HashTable outCheckCr;
algorithm
  (outArgmap,outCheckCr) := matchcontinue(inArgmap,inCheckCr)
    local
      HashTableCG.HashTable ht,ht1,ht2,ht3;
      list<tuple<DAE.ComponentRef, DAE.Exp>> res,res1,res2,new,new1;
      DAE.ComponentRef c,cref;
      DAE.Exp e;
      list<DAE.Var> varLst;
      list<DAE.Exp> expl;
      list<DAE.ComponentRef> crlst;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef>> creftpllst;
    case ({},ht) then ({},ht);
      /* All elements of the record have correct type already. No cast needed. */
    case((c,(DAE.CAST(exp=e,ty=DAE.T_COMPLEX())))::res,ht)
      equation
        (new1,ht1) = extendCrefRecords((c,e)::res,ht);
      then (new1,ht1);
    case((c,e as (DAE.CREF(componentRef = cref,ty=DAE.T_COMPLEX(varLst=varLst))))::res,ht)
      equation
        (res1,ht1) = extendCrefRecords(res,ht);
        new = List.map2(varLst,extendCrefRecords1,c,cref);
        (new1,ht2) = extendCrefRecords(new,ht1);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2,ht2);
    /* cause of an error somewhere the type of the expression CREF is not equal to the componentreference type
       this case is needed. */
    case((c,e as (DAE.CREF(componentRef = cref)))::res,ht)
      equation
        DAE.T_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cref);
        (res1,ht1) = extendCrefRecords(res,ht);
        new = List.map2(varLst,extendCrefRecords1,c,cref);
        (new1,ht2) = extendCrefRecords(new,ht1);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2,ht2);
    case((c,e as (DAE.CALL(expLst = expl,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=varLst)))))::res,ht)
      equation
        (res1,ht1) = extendCrefRecords(res,ht);
        crlst = List.map1(varLst,extendCrefRecords2,c);
        new = List.threadTuple(crlst,expl);
        (new1,ht2) = extendCrefRecords(new,ht1);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2,ht2);
    case((c,e as (DAE.RECORD(exps = expl,ty=DAE.T_COMPLEX(varLst=varLst))))::res,ht)
      equation
        (res1,ht1) = extendCrefRecords(res,ht);
        crlst = List.map1(varLst,extendCrefRecords2,c);
        new = List.threadTuple(crlst,expl);
        (new1,ht2) = extendCrefRecords(new,ht1);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2,ht2);
    case((c,e)::res,ht)
      equation
        DAE.T_COMPLEX(varLst=varLst) = Expression.typeof(e);
        crlst = List.map1(varLst,extendCrefRecords2,c);
        creftpllst = List.map1(crlst,Util.makeTuple,c);
        ht1 = List.fold(creftpllst,BaseHashTable.add,ht);
        ht2 = getCheckCref(crlst,ht1);
        (res1,ht3) = extendCrefRecords(res,ht2);
      then ((c,e)::res1,ht3);
    case((c,e)::res,ht)
      equation
        (res1,ht1) = extendCrefRecords(res,ht);
      then ((c,e)::res1,ht1);
  end matchcontinue;
end extendCrefRecords;

protected function getCheckCref
  input list<DAE.ComponentRef> inCrefs;
  input HashTableCG.HashTable inCheckCr;
  output HashTableCG.HashTable outCheckCr;
algorithm
  outCheckCr := matchcontinue(inCrefs,inCheckCr)
    local
      HashTableCG.HashTable ht,ht1,ht2,ht3;
      list<DAE.ComponentRef> rest,crlst;
      DAE.ComponentRef cr;
      list<DAE.Var> varLst;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef>> creftpllst;
      case ({},ht)
        then ht;
    case (cr::rest,ht)
      equation
        DAE.T_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr);
        crlst = List.map1(varLst,extendCrefRecords2,cr);
        ht1 = getCheckCref(crlst,ht);
        creftpllst = List.map1(crlst,Util.makeTuple,cr);
        ht2 = List.fold(creftpllst,BaseHashTable.add,ht1);
        ht3 = getCheckCref(rest,ht2);
      then
        ht3;
    case (_::rest,ht)
      equation
        ht1 = getCheckCref(rest,ht);
      then
        ht1;
   end matchcontinue;
end getCheckCref;

protected function extendCrefRecords1
"helper for extendCrefRecords"
  input DAE.Var ev;
  input DAE.ComponentRef c;
  input DAE.ComponentRef e;
  output tuple<DAE.ComponentRef, DAE.Exp> outArg;
algorithm
  outArg := matchcontinue(ev,c,e)
    local
      DAE.Type tp;
      String name;
      DAE.ComponentRef c1,e1;
      DAE.Exp exp;

    case(DAE.TYPES_VAR(name=name,ty=tp),_,_)
      equation
        c1 = ComponentReference.crefPrependIdent(c,name,{},tp);
        e1 = ComponentReference.crefPrependIdent(e,name,{},tp);
        exp = Expression.makeCrefExp(e1,tp);
      then ((c1,exp));
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inline.extendCrefRecords1 failed\n");
      then
        fail();
  end matchcontinue;
end extendCrefRecords1;

protected function extendCrefRecords2
"helper for extendCrefRecords"
  input DAE.Var ev;
  input DAE.ComponentRef c;
  output DAE.ComponentRef outArg;
algorithm
  outArg := matchcontinue(ev,c)
    local
      DAE.Type tp;
      String name;
      DAE.ComponentRef c1;

    case(DAE.TYPES_VAR(name=name,ty=tp),_)
      equation
        c1 = ComponentReference.crefPrependIdent(c,name,{},tp);
      then c1;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inline.extendCrefRecords2 failed\n");
      then
        fail();
  end matchcontinue;
end extendCrefRecords2;

protected function getFunctionBody
"returns the body of a function"
  input Absyn.Path p;
  input Functiontuple fns;
  output list<DAE.Element> outfn;
  output Option<SCode.Comment> oComment;
algorithm
  (outfn,oComment) := matchcontinue(p,fns)
    local
      list<DAE.Element> body;
      DAE.FunctionTree ftree;
      Option<SCode.Comment> comment;
    case(_,(SOME(ftree),_))
      equation
        SOME(DAE.FUNCTION( functions = DAE.FUNCTION_DEF(body = body)::_,comment=comment)) = DAEUtil.avlTreeGet(ftree,p);
      then (body,comment);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("Inline.getFunctionBody failed for function: " + Absyn.pathString(p));
        // Error.addMessage(Error.INTERNAL_ERROR, {"Inline.getFunctionBody failed"});
      then
        fail();
  end matchcontinue;
end getFunctionBody;

protected function getRhsExp
"returns the right hand side of an assignment from a function"
  input list<DAE.Element> inElementList;
  output DAE.Exp outExp;
algorithm
  outExp := match(inElementList)
    local
      list<DAE.Element> cdr;
      DAE.Exp res;
    case({})
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inline.getRhsExp failed - cannot inline such a function\n");
      then
        fail();
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN(exp=res)})) :: _) then res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(exp=res)})):: _) then res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN_ARR(exp=res)})) :: _) then res;
    case(_ :: cdr)
      equation
        res = getRhsExp(cdr);
      then
        res;
  end match;
end getRhsExp;

protected function replaceArgs
"finds DAE.CREF and replaces them with new exps if the cref is in the argmap"
  input DAE.Exp inExp;
  input tuple<list<tuple<DAE.ComponentRef,DAE.Exp>>,HashTableCG.HashTable,Boolean> inTuple;
  output DAE.Exp outExp;
  output tuple<list<tuple<DAE.ComponentRef,DAE.Exp>>,HashTableCG.HashTable,Boolean> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.ComponentRef cref;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp e;
      Absyn.Path path;
      list<DAE.Exp> expLst;
      Boolean tuple_,b, isImpure, isFunctionPointerCall;
      DAE.Type ty,ty2;
      DAE.InlineType inlineType;
      DAE.TailCall tc;
      HashTableCG.HashTable checkcr;
      Boolean replacedfailed;
    case (DAE.CREF(componentRef = cref),(argmap,checkcr,true))
      equation
        e = getExpFromArgMap(argmap,cref);
        (e,_) = ExpressionSimplify.simplify(e);
      then (e,(argmap,checkcr,true));

    case (e as DAE.CREF(componentRef = cref),(argmap,checkcr,true))
      equation
        true = BaseHashTable.hasKey(cref,checkcr);
      then (e,(argmap,checkcr,false));

    case (DAE.UNBOX(DAE.CALL(path,expLst,DAE.CALL_ATTR(_,tuple_,false,isImpure,_,inlineType,tc)),ty),(argmap,checkcr,true))
      equation
        cref = ComponentReference.pathToCref(path);
        (e as DAE.CREF(componentRef=cref,ty=ty2)) = getExpFromArgMap(argmap,cref);
        path = ComponentReference.crefToPath(cref);
        expLst = List.map(expLst,Expression.unboxExp);
        b = Expression.isBuiltinFunctionReference(e);
        isFunctionPointerCall = Types.isFunctionReferenceVar(ty2);
        e = DAE.CALL(path,expLst,DAE.CALL_ATTR(ty,tuple_,b,isImpure,isFunctionPointerCall,inlineType,tc));
        (e,_) = ExpressionSimplify.simplify(e);
      then (e,(argmap,checkcr,true));

    case (e as DAE.UNBOX(DAE.CALL(path,_,DAE.CALL_ATTR(builtin=false)),_),(argmap,checkcr,true))
      equation
        cref = ComponentReference.pathToCref(path);
        true = BaseHashTable.hasKey(cref,checkcr);
      then (e,(argmap,checkcr,false));

    // TODO: Use the inlineType of the function reference!
    case (DAE.CALL(path,expLst,DAE.CALL_ATTR(DAE.T_METATYPE(),tuple_,false,isImpure,_,_,tc)),(argmap,checkcr,true))
      equation
        cref = ComponentReference.pathToCref(path);
        (e as DAE.CREF(componentRef=cref,ty=ty)) = getExpFromArgMap(argmap,cref);
        path = ComponentReference.crefToPath(cref);
        expLst = List.map(expLst,Expression.unboxExp);
        b = Expression.isBuiltinFunctionReference(e);
        (ty2,inlineType) = functionReferenceType(ty);
        isFunctionPointerCall = Types.isFunctionReferenceVar(ty2);
        e = DAE.CALL(path,expLst,DAE.CALL_ATTR(ty2,tuple_,b,isImpure,isFunctionPointerCall,inlineType,tc));
        e = boxIfUnboxedFunRef(e,ty);
        (e,_) = ExpressionSimplify.simplify(e);
      then (e,(argmap,checkcr,true));

    case (e as DAE.CALL(path,_,DAE.CALL_ATTR(ty=DAE.T_METATYPE(),builtin=false)),(argmap,checkcr,true))
      equation
        cref = ComponentReference.pathToCref(path);
        true = BaseHashTable.hasKey(cref,checkcr);
      then (e,(argmap,checkcr,false));

    case (e,(argmap,checkcr,replacedfailed)) then (e,(argmap,checkcr,replacedfailed));
  end matchcontinue;
end replaceArgs;

protected function boxIfUnboxedFunRef
  "Replacing a function pointer with a regular function means that you:
  (1) Need to unbox all inputs
  (2) Need to box the output if it was not done before
  This function handles (2)
  "
  input DAE.Exp iexp;
  input DAE.Type ty;
  output DAE.Exp outExp;
algorithm
  outExp := match (iexp,ty)
    local
      DAE.Type t;
      DAE.Exp exp;
    case (exp,DAE.T_FUNCTION_REFERENCE_FUNC(functionType=DAE.T_FUNCTION(funcResultType=t)))
      equation
        exp = if Types.isBoxedType(t) then exp else DAE.BOX(exp);
      then exp;
    else iexp;
  end match;
end boxIfUnboxedFunRef;

protected function functionReferenceType
  "Retrieves the ExpType that the call should have (this changes if the replacing
  function does not return a boxed value).
  We also return the inline type of the new call."
  input DAE.Type ty1;
  output DAE.Type ty2;
  output DAE.InlineType inlineType;
algorithm
  (ty2,inlineType) := match ty1
    local
      DAE.Type ty;
    case DAE.T_FUNCTION_REFERENCE_FUNC(functionType=DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(inline=inlineType),funcResultType=ty))
      then (Types.simplifyType(ty),inlineType);
    else (ty1,DAE.NO_INLINE());
  end match;
end functionReferenceType;

protected function getExpFromArgMap
"returns the exp from the given argmap with the given key"
  input list<tuple<DAE.ComponentRef, DAE.Exp>> inArgMap;
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inArgMap,inComponentRef)
    local
      DAE.ComponentRef key,cref;
      DAE.Exp exp,e;
      list<tuple<DAE.ComponentRef, DAE.Exp>> cdr;
      list<DAE.Subscript> subs;
    case({},_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("Inline.getExpFromArgMap failed with empty argmap and cref: " + ComponentReference.printComponentRefStr(inComponentRef));
      then
        fail();
    case((cref,exp) :: _,key)
      equation
        subs = ComponentReference.crefSubs(key);
        key = ComponentReference.crefStripSubs(key);
        true = ComponentReference.crefEqual(cref,key);
        e = Expression.applyExpSubscripts(exp,subs);
      then
        e;
    case(_ :: cdr,key)
      equation
        exp = getExpFromArgMap(cdr,key);
      then
        exp;
  end matchcontinue;
end getExpFromArgMap;

protected function getInputCrefs
"returns the crefs of vars that are inputs, wild if not input"
  input DAE.Element inElement;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inElement)
    local
      DAE.ComponentRef cref;
    case(DAE.VAR(componentRef=cref,direction=DAE.INPUT())) then cref;
    else DAE.WILD();
  end match;
end getInputCrefs;

protected function removeWilds
"returns false if the given cref is a wild"
  input DAE.ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inComponentRef)
    case(DAE.WILD()) then false;
    else true;
  end match;
end removeWilds;

public function printInlineTypeStr
"Print what kind of inline we have"
  input DAE.InlineType it;
  output String str;
algorithm
  str := match(it)
    case(DAE.NO_INLINE()) then "No inline";
    case(DAE.AFTER_INDEX_RED_INLINE()) then "Inline after index reduction";
    case(DAE.EARLY_INLINE()) then "Inline as soon as possible";
    case(DAE.BUILTIN_EARLY_INLINE()) then "Inline as soon as possible, even if inlining is globally disabled";
    case(DAE.NORM_INLINE()) then "Inline before index reduction";
    case(DAE.DEFAULT_INLINE()) then "Inline if necessary";
  end match;
end printInlineTypeStr;

public function simplifyAndInlineEquationExp "
  Takes a residual or equality equation, then
  simplifies, inlines and simplifies again
"
  input DAE.EquationExp inExp;
  input Functiontuple fns;
  input DAE.ElementSource inSource;
  output DAE.EquationExp exp;
  output DAE.ElementSource source;
algorithm
  (exp,source) := ExpressionSimplify.simplifyAddSymbolicOperation(inExp,inSource);
  (exp,source) := inlineEquationExp(exp,function inlineCall(fns=fns),source);
end simplifyAndInlineEquationExp;

public function simplifyAndForceInlineEquationExp "
  Takes a residual or equality equation, then
  simplifies, inlines and simplifies again
"
  input DAE.EquationExp inExp;
  input Functiontuple fns;
  input DAE.ElementSource inSource;
  output DAE.EquationExp exp;
  output DAE.ElementSource source;
algorithm
  (exp,source) := ExpressionSimplify.simplifyAddSymbolicOperation(inExp,inSource);
  (exp,source) := inlineEquationExp(exp,function forceInlineCall(fns=fns),source);
end simplifyAndForceInlineEquationExp;

public function inlineEquationExp "
  Takes a residual or equality equation, then
  simplifies, inlines and simplifies again
"
  input DAE.EquationExp inExp;
  input Func fn;
  input DAE.ElementSource inSource;
  output DAE.EquationExp outExp;
  output DAE.ElementSource source;
  partial function Func
    input DAE.Exp inExp;
    input list<DAE.Statement> inTuple;
    output DAE.Exp outExp;
    output list<DAE.Statement> outTuple;
  end Func;
  type Functiontuple = tuple<Option<DAE.FunctionTree>,list<DAE.InlineType>>;
algorithm
  (outExp,source) := match inExp
    local
      Boolean changed;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      DAE.EquationExp eq2;
      Functiontuple fns;
      list<DAE.Statement> assrtLst;
    case DAE.PARTIAL_EQUATION(e)
      equation
        (e_1,_) = Expression.traverseExpBottomUp(e,fn,{});
        changed = not referenceEq(e, e_1);
        eq2 = DAE.PARTIAL_EQUATION(e_1);
        source = ElementSource.condAddSymbolicTransformation(changed,inSource,DAE.OP_INLINE(inExp,eq2));
        (eq2,source) = ExpressionSimplify.condSimplifyAddSymbolicOperation(changed, eq2, source);
      then (eq2,source);
    case DAE.RESIDUAL_EXP(e)
      equation
        (e_1,_) = Expression.traverseExpBottomUp(e,fn,{});
        changed = not referenceEq(e, e_1);
        eq2 = DAE.RESIDUAL_EXP(e_1);
        source = ElementSource.condAddSymbolicTransformation(changed,inSource,DAE.OP_INLINE(inExp,eq2));
        (eq2,source) = ExpressionSimplify.condSimplifyAddSymbolicOperation(changed, eq2, source);
      then (eq2,source);
    case DAE.EQUALITY_EXPS(e1,e2)
      equation
        (e1_1,_) = Expression.traverseExpBottomUp(e1,fn,{});
        (e2_1,_) = Expression.traverseExpBottomUp(e2,fn,{});
        changed = not (referenceEq(e1, e1_1) and referenceEq(e2, e2_1));
        eq2 = DAE.EQUALITY_EXPS(e1_1,e2_1);
        source = ElementSource.condAddSymbolicTransformation(changed,inSource,DAE.OP_INLINE(inExp,eq2));
        (eq2,source) = ExpressionSimplify.condSimplifyAddSymbolicOperation(changed, eq2, source);
      then (eq2,source);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Inline.inlineEquationExp failed"});
      then fail();
  end match;
end inlineEquationExp;

protected function getReplacementCheckComplex
  input VarTransform.VariableReplacements repl;
  input DAE.ComponentRef cr;
  input DAE.Type ty;
  output DAE.Exp exp;
algorithm
  exp := matchcontinue (repl,cr,ty)
    local
      list<DAE.Var> vars;
      list<DAE.ComponentRef> crs;
      list<String> strs;
      list<DAE.Exp> exps;
      Absyn.Path path;
    case (_,_,_) then VarTransform.getReplacement(repl,cr);
    case (_,_,DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path),varLst=vars))
      equation
        crs = List.map1(List.map(vars,Types.varName),ComponentReference.appendStringCref,cr);
        exps = List.map1r(crs, VarTransform.getReplacement, repl);
      then DAE.CALL(path,exps,DAE.CALL_ATTR(ty,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
  end matchcontinue;
end getReplacementCheckComplex;

protected function getInlineHashTableVarTransform
  output HashTableCG.HashTable ht;
  output VarTransform.VariableReplacements repl;
protected
  Option<tuple<HashTableCG.HashTable,VarTransform.VariableReplacements>> opt;
  HashTable2.HashTable regRepl;
  HashTable3.HashTable invRepl;
algorithm
  opt := getGlobalRoot(Global.inlineHashTable);
  (ht,repl) := match opt
    case SOME((ht,repl as VarTransform.REPLACEMENTS(regRepl,invRepl)))
      algorithm
        // Always stored with n=0, etc with the first global root
        BaseHashTable.clearAssumeNoDelete(ht);
        BaseHashTable.clearAssumeNoDelete(regRepl);
        BaseHashTable.clearAssumeNoDelete(invRepl);
      then (ht,repl);
    else
      algorithm
        ht := HashTableCG.emptyHashTable();
        repl := VarTransform.emptyReplacements();
        setGlobalRoot(Global.inlineHashTable, SOME((ht,repl)));
      then (ht,repl);
  end match;
end getInlineHashTableVarTransform;

annotation(__OpenModelica_Interface="frontend");
end Inline;
