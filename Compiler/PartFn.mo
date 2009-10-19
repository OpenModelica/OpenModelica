/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package PartFn
" file:	       PartFn.mo
  package:     PartFn
  description: partially evaluated functions
  
  RCS: $Id: PartFn.mo 4306 2009-10-06 06:32:29Z sjoelund.se $
  
  This module contains data structures and functions for partially evaulated functions.
  "

public import Absyn;
public import Util;
public import Debug;
public import RTOpts;

// stefan
// function name, function args, caller function, arg position, arg name
public type PartFn = tuple<Absyn.ComponentRef, Absyn.FunctionArgs, Absyn.ComponentRef, Option<Integer>, Option<String>>;

// stefan
public function createPartEvalFunctionClasses
"function: createPartEvalFunctionClasses
	Searches through an Absyn.Program for partially evaluated functions
	and creates new classes for each one"
	input Absyn.Program inProgram;
	output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram)
    local
      Absyn.Program program;
      list<Absyn.Class> cls,cls_1;
      Absyn.Within w;
      Absyn.TimeStamp gbt;
    case (program)
      equation
        false = RTOpts.acceptMetaModelicaGrammar();
      then program;
    case(program as Absyn.PROGRAM(classes=cls,within_=w,globalBuildTimes=gbt))
      equation
        cls_1 = createPartEvalFunctionClasses2(cls,program);
        program = Absyn.PROGRAM(cls_1,w,gbt);
      then program;
  end matchcontinue;
end createPartEvalFunctionClasses;

// stefan
protected function createPartEvalFunctionClasses2
"function: create partEvalFunctionClasses2
	Helper function to createPartEvalFunctionClasses"
	input list<Absyn.Class> inClassList;
	input Absyn.Program inProgram;
	output list<Absyn.Class> outClassList;
algorithm
  outClassList := matchcontinue(inClassList,inProgram)
    local
      Absyn.Program p;
      Absyn.Class cl;
      list<Absyn.Class> cdr,p_classes;
      Absyn.Within w;
      Absyn.TimeStamp gbt;
    case({},_) then {};
    case(cl :: cdr,p as Absyn.PROGRAM(p_classes,w,gbt))
      local
        list<Absyn.AlgorithmItem> algs,algs_1;
        list<Absyn.Class> newClasses,classes,classes_1,classes_2,cdr_1,p_classes_1,p_classes_2;
        Absyn.Class cl_1;
        Absyn.Program p_1;
      equation
        algs = Absyn.getAlgorithmItems(cl);
        p_classes_1 = Util.listSetDifference(p_classes,{cl});
        ((algs_1,newClasses)) = Absyn.traverseAlgorithmItemList(algs,fixCallsAndCreateClasses,p_classes_1);
        cl_1 = Absyn.setAlgorithmItems(algs_1,cl);
        classes = cl_1 :: newClasses;
        p_classes_2 = cl_1 :: p_classes_1;
        p_1 = Absyn.PROGRAM(p_classes_2,w,gbt);
        cdr_1 = createPartEvalFunctionClasses2(cdr,p_1);
        classes_1 = listAppend(classes,cdr_1);
        classes_2 = selectUniqueClasses(classes_1);
      then
        classes_2;
  end matchcontinue;
end createPartEvalFunctionClasses2;

// stefan
protected function selectUniqueClasses
"function: selectUniqueClasses
	removes all classes whose names appear more than once in a list of classes"
	input list<Absyn.Class> inClassList;
	output list<Absyn.Class> outClassList;
algorithm
  outClassList := matchcontinue(inClassList)
    local
      Absyn.Class cl;
      list<Absyn.Class> cdr,cdr_1;
    case({}) then {};
    case(cl :: cdr)
      equation
        true = Util.listContains(cl,cdr);
        cdr_1 = selectUniqueClasses(cdr);
      then
        cdr_1;
    case(cl :: cdr)
      equation
        cdr_1 = selectUniqueClasses(cdr);
      then
        cl :: cdr_1;
  end matchcontinue;
end selectUniqueClasses;

// stefan
protected function fixCallsAndCreateClasses
"function: fixCallsAndCreateClasses
	This function is passed as an argument to the algorithm traversal function
	Calls Absyn.traverseExp to look for calls that have
	partially evaluated functions in their arguments
	the end goal is to transform these calls and create new classes"
	input tuple<Absyn.Algorithm, list<Absyn.Class>> inTuple;
	output tuple<Absyn.Algorithm, list<Absyn.Class>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Absyn.Algorithm alg,alg_1;
      list<Absyn.Class> cls,cls_1,cls_2,cls_3,cls_4;
      Absyn.Exp e,e1,e2,e_1,e1_1,e2_1;
      list<Absyn.AlgorithmItem> ailst,ailst1,ailst2,ailst_1,ailst1_1,ailst2_1;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eaitlst,eaitlst_1;
      Absyn.ForIterators fis,fis_1;
      Absyn.ComponentRef cref,cref_1;
      Absyn.FunctionArgs fargs,fargs_1;
    case((Absyn.ALG_ASSIGN(e1,e2),cls))
      equation
        ((e1_1,cls_1)) = Absyn.traverseExp(e1,fixCallsAndCreateClasses2,cls);
        ((e2_1,cls_2)) = Absyn.traverseExp(e2,fixCallsAndCreateClasses2,cls_1);
      then
        ((Absyn.ALG_ASSIGN(e1_1,e2_1),cls_2));
    case((Absyn.ALG_IF(e,ailst1,eaitlst,ailst2),cls))
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        //((ailst1_1,cls_2)) = Absyn.traverseAlgorithmItemList(ailst1,fixCallsAndCreateClasses,cls_1);
        (eaitlst_1,cls_2) = fixExpAlgItemTupleLists(eaitlst,cls_1);
        //((ailst2_1,cls_4)) = Absyn.traverseAlgorithmItemList(ailst2,fixCallsAndCreateClasses,cls_3);
      then
        ((Absyn.ALG_IF(e_1,ailst1,eaitlst_1,ailst2),cls_2));
    case((Absyn.ALG_FOR(fis,ailst),cls))
      equation
        (fis_1,cls_1) = fixForIterators(fis,cls);
        //((ailst_1,cls_2)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsAndCreateClasses,cls_1);
      then
        ((Absyn.ALG_FOR(fis_1,ailst),cls_1));
    case((Absyn.ALG_WHILE(e,ailst),cls))
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        //((ailst_1,cls_2)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsAndCreateClasses,cls_1);
      then
        ((Absyn.ALG_WHILE(e_1,ailst),cls_1));
    case((Absyn.ALG_WHEN_A(e,ailst,eaitlst),cls))
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        (eaitlst_1,cls_2) = fixExpAlgItemTupleLists(eaitlst,cls_1);
        //((ailst_1,cls_3)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsAndCreateClasses,cls_2);
      then
        ((Absyn.ALG_WHEN_A(e_1,ailst,eaitlst_1),cls_2));
    case((Absyn.ALG_NORETCALL(cref,fargs),cls))
      equation
        (cref_1,fargs_1,cls_1) = buildNewFunctionCall(cref,fargs,cls);
      then
        ((Absyn.ALG_NORETCALL(cref_1,fargs_1),cls_1));
  end matchcontinue;
end fixCallsAndCreateClasses;

// stefan
protected function fixCallsAndCreateClasses3
"function: fixCallsInNewClass3
	handles equations"
	input tuple<Absyn.Equation, list<Absyn.Class>> inTuple;
	output tuple<Absyn.Equation, list<Absyn.Class>> outTuple;
algorithm
  outTuple := matchcontinue (inTuple)
    local
      Absyn.Equation eq;
      list<Absyn.Class> cls,cls_1,cls_2;
      Absyn.Exp e,e1,e2,e_1,e1_1,e2_1;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eeqitlst,eeqitlst_1;
      list<Absyn.EquationItem> eilst,eilst1,eilst2;
      Absyn.ForIterators fis,fis_1;
      Absyn.ComponentRef cref,cref_1;
      Absyn.FunctionArgs fargs,fargs_1;
    case((Absyn.EQ_IF(e,eilst1,eeqitlst,eilst2),cls))
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        (eeqitlst_1,cls_2) = fixExpEqItemTupleLists(eeqitlst,cls_1);
      then
        ((Absyn.EQ_IF(e_1,eilst1,eeqitlst_1,eilst2),cls_2));
    case((Absyn.EQ_EQUALS(e1,e2),cls))
      equation
        ((e1_1,cls_1)) = Absyn.traverseExp(e1,fixCallsAndCreateClasses2,cls);
        ((e2_1,cls_2)) = Absyn.traverseExp(e2,fixCallsAndCreateClasses2,cls_1);
      then
        ((Absyn.EQ_EQUALS(e1_1,e2_1),cls_2));
    case((Absyn.EQ_FOR(fis,eilst),cls))
      equation
        (fis_1,cls_1) = fixForIterators(fis,cls);
      then
        ((Absyn.EQ_FOR(fis_1,eilst),cls_1));
    case((Absyn.EQ_WHEN_E(e,eilst,eeqitlst),cls))
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        (eeqitlst_1,cls_2) = fixExpEqItemTupleLists(eeqitlst,cls_1);
      then
        ((Absyn.EQ_WHEN_E(e_1,eilst,eeqitlst_1),cls_2));
    case((Absyn.EQ_NORETCALL(cref,fargs),cls))
      equation
        (cref_1,fargs_1,cls_1) = buildNewFunctionCall(cref,fargs,cls);
      then
        ((Absyn.EQ_NORETCALL(cref_1,fargs_1),cls_1));
    case((eq,cls)) then ((eq,cls));
  end matchcontinue;
end fixCallsAndCreateClasses3;
        
// stefan
protected function fixExpAlgItemTupleLists
"function: fixExpAlgItemTupleLists
	helper function to fixCallsAndCreateClasses
	traverses the expressions in the input list"
	input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTupleList;
	input list<Absyn.Class> inClassList;
	output list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> outTupleList;
	output list<Absyn.Class> outClassList;
algorithm
  (outTupleList,outClassList) := matchcontinue (inTupleList,inClassList)
    local
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> cdr,cdr_1;
      list<Absyn.AlgorithmItem> ailst;
      Absyn.Exp e,e_1;
      list<Absyn.Class> cls,cls_1,cls_2;
    case({},cls) then ({},cls);
    case((e, ailst) :: cdr,cls)
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        (cdr_1,cls_2) = fixExpAlgItemTupleLists(cdr,cls_1);
      then
        ((e_1,ailst) :: cdr_1,cls_2);
  end matchcontinue;
end fixExpAlgItemTupleLists;

// stefan
protected function fixExpAlgItemTupleLists2
"function: fixExpAlgItemTupleLists2
	as above, but for fixing calls in the new classes
	I should probably write a general function for these"
	input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTupleList;
	input tuple<list<Absyn.Class>, list<PartFn>> inTuple;
	output list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> outTupleList;
	output tuple<list<Absyn.Class>, list<PartFn>> outTuple;
algorithm
  (outTupleList,outTuple) := matchcontinue (inTupleList,inTuple)
    local
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> cdr,cdr_1;
      list<Absyn.AlgorithmItem> ailst;
      Absyn.Exp e,e_1;
      list<Absyn.Class> cls,cls_1,cls_2;
      list<PartFn> pfn;
    case({},(cls,pfn)) then ({},(cls,pfn));
    case((e, ailst) :: cdr,(cls,pfn))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        (cdr_1,(cls_2,pfn)) = fixExpAlgItemTupleLists2(cdr,(cls_1,pfn));
      then
        ((e_1,ailst) :: cdr_1,(cls_2,pfn));
  end matchcontinue;
end fixExpAlgItemTupleLists2;

// stefan
protected function fixExpEqItemTupleLists
"function: fixExpAlgItemTupleLists
	helper function to fixCallsAndCreateClasses
	traverses the expressions in the input list"
	input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTupleList;
	input list<Absyn.Class> inClassList;
	output list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> outTupleList;
	output list<Absyn.Class> outClassList;
algorithm
  (outTupleList,outClassList) := matchcontinue (inTupleList,inClassList)
    local
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> cdr,cdr_1;
      list<Absyn.EquationItem> eqilst;
      Absyn.Exp e,e_1;
      list<Absyn.Class> cls,cls_1,cls_2;
    case({},cls) then ({},cls);
    case((e, eqilst) :: cdr,cls)
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        (cdr_1,cls_2) = fixExpEqItemTupleLists(cdr,cls_1);
      then
        ((e_1,eqilst) :: cdr_1,cls_2);
  end matchcontinue;
end fixExpEqItemTupleLists;

// stefan
protected function fixExpEqItemTupleLists2
"function: fixExpEqItemTupleLists2
	as above, but for fixing calls in the new classes
	I should probably write a general function for these"
	input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTupleList;
	input tuple<list<Absyn.Class>, list<PartFn>> inTuple;
	output list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> outTupleList;
	output tuple<list<Absyn.Class>, list<PartFn>> outTuple;
algorithm
  (outTupleList,outTuple) := matchcontinue (inTupleList,inTuple)
    local
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> cdr,cdr_1;
      list<Absyn.EquationItem> eqilst;
      Absyn.Exp e,e_1;
      list<Absyn.Class> cls,cls_1,cls_2;
      list<PartFn> pfn;
    case({},(cls,pfn)) then ({},(cls,pfn));
    case((e, eqilst) :: cdr,(cls,pfn))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        (cdr_1,(cls_2,pfn)) = fixExpEqItemTupleLists2(cdr,(cls_1,pfn));
      then
        ((e_1,eqilst) :: cdr_1,(cls_2,pfn));
  end matchcontinue;
end fixExpEqItemTupleLists2;

// stefan
protected function fixForIterators
"function: fixForIterators
	helper function to fixCallsAndCreateClasses
	searches a list of for iterators for expressions containing partially evaluated functions"
	input Absyn.ForIterators inForIterators;
	input list<Absyn.Class> inClassList;
	output Absyn.ForIterators outForIterators;
	output list<Absyn.Class> outClassList;
algorithm
  (outForIterators,outClassList) := matchcontinue (inForIterators,inClassList)
    local
      Absyn.ForIterators cdr,fis;
      Absyn.ForIterator fi;
      Absyn.Ident i;
      Absyn.Exp e,e_1;
      list<Absyn.Class> cls,cls_1,cls_2;
    case({},cls) then ({},cls);
    case((i,SOME(e)) :: cdr,cls)
      equation
        ((e_1,cls_1)) = Absyn.traverseExp(e,fixCallsAndCreateClasses2,cls);
        (fis,cls_2) = fixForIterators(cdr,cls_1);
      then
        ((i,SOME(e_1)) :: fis,cls_2);
    case(fi :: cdr,cls)
      equation
        (fis,cls_1) = fixForIterators(cdr,cls);
      then
        (fi :: fis,cls_1);
  end matchcontinue;
end fixForIterators;

// stefan
protected function fixForIterators2
"function: fixForIterators2
	as above but for fixing the calls in the new classes"
	input Absyn.ForIterators inForIterators;
	input tuple<list<Absyn.Class>, list<PartFn>> inTuple;
	output Absyn.ForIterators outForIterators;
	output tuple<list<Absyn.Class>, list<PartFn>> outTuple;
algorithm
  (outForIterators,outTuple) := matchcontinue (inForIterators,inTuple)
    local
      Absyn.ForIterators cdr,fis;
      Absyn.ForIterator fi;
      Absyn.Ident i;
      Absyn.Exp e,e_1;
      list<Absyn.Class> cls,cls_1,cls_2;
      list<PartFn> pfn;
    case({},(cls,pfn)) then ({},(cls,pfn));
    case((i,SOME(e)) :: cdr,(cls,pfn))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        (fis,(cls_2,pfn)) = fixForIterators2(cdr,(cls_1,pfn));
      then
        ((i,SOME(e_1)) :: fis,(cls_2,pfn));
    case(fi :: cdr,(cls,pfn))
      equation
        (fis,(cls_1,pfn)) = fixForIterators2(cdr,(cls,pfn));
      then
        (fi :: fis,(cls_1,pfn));
  end matchcontinue;
end fixForIterators2;

// stefan
protected function fixCallsAndCreateClasses2
"function: fixCallsAndCreateClasses2
	helper function to fixCallsAndCreateClasses
	traverses expressions in search of partially evaluated functions
	also builds new classes"
	input tuple<Absyn.Exp, list<Absyn.Class>> inTuple;
	output tuple<Absyn.Exp, list<Absyn.Class>> outTuple;
algorithm
  outTuple := matchcontinue (inTuple)
    local
      Absyn.Exp e,me,res;
      list<Absyn.Class> cls,cls_1;
      Absyn.ComponentRef cref,cref_1;
      Absyn.FunctionArgs fargs,fargs_1;
      list<PartFn> pfn1,pfn2;
      list<Absyn.Exp> eargs;
      list<Absyn.NamedArg> nargs;
      Absyn.MatchType mt;
      list<Absyn.ElementItem> eilst;
      list<Absyn.Case> caselst,caselst_1;
      Option<String> oc;
      Absyn.ValueblockBody vb,vb_1;
    case((Absyn.CALL(cref,fargs),cls))
      equation
        (cref_1,fargs_1,cls_1) = buildNewFunctionCall(cref,fargs,cls);
      then
        ((Absyn.CALL(cref_1,fargs_1),cls_1));
    case((Absyn.MATCHEXP(mt,me,eilst,caselst,oc),cls))
      equation
        caselst_1 = fixCaseListClasses(caselst,cls);
      then
        ((Absyn.MATCHEXP(mt,me,eilst,caselst_1,oc),cls));
    case((Absyn.VALUEBLOCK(eilst,vb,res),cls))
      equation
        vb_1 = fixVBodyClasses(vb,cls);
      then
        ((Absyn.VALUEBLOCK(eilst,vb_1,res),cls));
    case((e,cls)) then ((e,cls));
  end matchcontinue;
end fixCallsAndCreateClasses2;

// stefan
protected function buildNewFunctionCall
"function: buildNewFunctionCall
	if a partially evaluated function is found
	build a new function (if it doesn't exist already)
	change the call to call that function
	remove the partevalfunction from the arguments
	place the arguments from that record into the call args"
	input Absyn.ComponentRef inComponentRef;
	input Absyn.FunctionArgs inFunctionArgs;
	input list<Absyn.Class> inClassList;
	output Absyn.ComponentRef outComponentRef;
	output Absyn.FunctionArgs outFunctionArgs;
	output list<Absyn.Class> outClassList;
algorithm
  (outComponentRef,outFunctionArgs,outClassList) := matchcontinue (inComponentRef,inFunctionArgs,inClassList)
    local
      Absyn.ComponentRef cref,cref_1,cref_2,cref_3;
      Absyn.FunctionArgs fargs,fargs_1;
      list<Absyn.Class> cls,cls_1,cls_2;
      list<Absyn.Exp> eargs,eargs_1,eargs_2,eargs_3;
      list<Absyn.NamedArg> nargs,nargs_1;
      list<PartFn> pfn,pfn_1,pfn1,pfn2;
      Absyn.Class cl,cl_1;
      String s1,s2;
      list<Absyn.AlgorithmItem> ailst,ailst_1;
    case(cref,fargs,cls)
      equation
        cref_1 = Absyn.crefGetLastIdent(cref);
        (eargs,nargs) = Absyn.extractArgs(fargs);
        pfn1 = findPartFnInPosArgs(eargs,eargs);
        pfn2 = findPartFnInNamedArgs(nargs);
        pfn = listAppend(pfn1,pfn2);
        true = 0 < listLength(pfn);
        pfn_1 = addCrefToPartFnList(cref_1,pfn);
        cref_2 = generateFuncName(cref_1,pfn);
        cref_3 = Absyn.crefSetLastIdent(cref,cref_2);
        s1 = Absyn.printComponentRefStr(cref_1);
        s2 = Absyn.printComponentRefStr(cref_2);
        eargs_1 = fixPosArgs(eargs);
        (nargs_1,eargs_2) = fixNamedArgs(nargs);
        eargs_3 = listAppend(eargs_1,eargs_2);
        fargs_1 = Absyn.FUNCTIONARGS(eargs_3,nargs_1);
        cl = buildNewClass(s1,s2,pfn_1,cls);
        cls_1 = cl :: cls;
        ailst = Absyn.getAlgorithmItems(cl);
        ((ailst_1,_)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsInNewClass,(cls_1,pfn_1));
        cl_1 = Absyn.setAlgorithmItems(ailst_1,cl);
        cls_2 = cl_1 :: cls;
      then
        (cref_3,fargs_1,cls_2);
    case(cref,fargs,cls) then (cref,fargs,cls);
  end matchcontinue;
end buildNewFunctionCall;

// stefan
protected function buildNewClass
"function: buildNewClass
	creates a new class based on the given name, partfn list and class list"
	input String inString1;
	input String inString2;
	input list<PartFn> inPartFnList;
	input list<Absyn.Class> inClassList;
	output Absyn.Class outClass;
algorithm
  outClass := matchcontinue(inString1,inString2,inPartFnList,inClassList)
    local
      String orig_name,new_name;
      list<PartFn> pfn;
      list<Absyn.Class> cls;
      Absyn.Class cl,cl_1,cl_2,cl_3;
      list<Absyn.AlgorithmItem> ailst,ailst_1;
      list<Absyn.ClassPart> parts,parts_1;
    case(orig_name,new_name,pfn,cls)
      equation
        true = listLength(pfn) < 2;
        cl = Absyn.getClassByName(orig_name,cls);
        cl_1 = Absyn.renameClass(new_name,cl);
        parts = Absyn.getClassParts(cl_1);
        parts_1 = fixClassInputs(parts,pfn,cls);
        cl_2 = Absyn.setClassParts(parts_1,cl_1);
        //ailst = Absyn.getAlgorithmItems(cl_1); - THIS IS NOW HANDLED BY BUILDNEWFUNCTIONCALL
        // WARNING - TWO PARTIALLY EVAULATED FUNCTIONS CANNOT BE PASSED AS ARGUMENTS IN THE SAME CALL
        //((ailst_1,_)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsInNewClass,(cls,pfn));
        //cl_3 = Absyn.setAlgorithmItems(ailst_1,cl_2);
      then
        cl_2;
    case(_,_,_,_)
      equation
        Debug.fprintln("failtrace","buildNewClass - multiple partially evaluated functions may not be passed in the same call");
      then
        fail();
  end matchcontinue;
end buildNewClass;

// stefan
protected function fixCallsInNewClass
"function: fixCallsInNewClass
	helper function to buildNewClass
	passed as argument to traverseAlgorithmItemList
	fixes the function calls so that they call the correct function with the correct arguments
	WARNING: herein lie the limitations of partially evaluated functions!"
	input tuple<Absyn.Algorithm, tuple<list<Absyn.Class>, list<PartFn>>> inTpl;
	output tuple<Absyn.Algorithm, tuple<list<Absyn.Class>, list<PartFn>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      Absyn.Algorithm alg,alg_1;
      list<Absyn.Class> cls,cls_1,cls_2,cls_3,cls_4;
      Absyn.Exp e,e1,e2,e_1,e1_1,e2_1;
      list<Absyn.AlgorithmItem> ailst,ailst1,ailst2,ailst_1,ailst1_1,ailst2_1;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eaitlst,eaitlst_1;
      Absyn.ForIterators fis,fis_1;
      Absyn.ComponentRef cref,cref_1;
      Absyn.FunctionArgs fargs,fargs_1;
      list<PartFn> pfn;
      list<Absyn.Exp> elst,elst_1;
    case((Absyn.ALG_ASSIGN(e1,e2),(cls,pfn)))
      equation
        ((e1_1,(cls_1,pfn))) = Absyn.traverseExp(e1,fixCallsInNewClass2,(cls,pfn));
        ((e2_1,(cls_2,pfn))) = Absyn.traverseExp(e2,fixCallsInNewClass2,(cls_1,pfn));
      then
        ((Absyn.ALG_ASSIGN(e1_1,e2_1),(cls_2,pfn)));
    case((Absyn.ALG_IF(e,ailst1,eaitlst,ailst2),(cls,pfn)))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        //((ailst1_1,cls_2)) = Absyn.traverseAlgorithmItemList(ailst1,fixCallsInNewClass,cls_1);
        (eaitlst_1,(cls_2,pfn)) = fixExpAlgItemTupleLists2(eaitlst,(cls_1,pfn));
        //((ailst2_1,cls_4)) = Absyn.traverseAlgorithmItemList(ailst2,fixCallsInNewClass,cls_3);
      then
        ((Absyn.ALG_IF(e_1,ailst1,eaitlst_1,ailst2),(cls_2,pfn)));
    case((Absyn.ALG_FOR(fis,ailst),(cls,pfn)))
      equation
        (fis_1,(cls_1,pfn)) = fixForIterators2(fis,(cls,pfn));
        //((ailst_1,cls_2)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsInNewClass,cls_1);
      then
        ((Absyn.ALG_FOR(fis_1,ailst),(cls_1,pfn)));
    case((Absyn.ALG_WHILE(e,ailst),(cls,pfn)))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        //((ailst_1,cls_2)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsInNewClass,cls_1);
      then
        ((Absyn.ALG_WHILE(e_1,ailst),(cls_1,pfn)));
    case((Absyn.ALG_WHEN_A(e,ailst,eaitlst),(cls,pfn)))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        (eaitlst_1,(cls_2,pfn)) = fixExpAlgItemTupleLists2(eaitlst,(cls_1,pfn));
        //((ailst_1,cls_3)) = Absyn.traverseAlgorithmItemList(ailst,fixCallsInNewClass,cls_2);
      then
        ((Absyn.ALG_WHEN_A(e_1,ailst,eaitlst_1),(cls_2,pfn)));
    case((Absyn.ALG_MATCHCASES(elst),(cls,pfn)))
      equation
        ((elst_1,(cls_1,pfn))) = Absyn.traverseExpList(elst,fixCallsInNewClass2,(cls,pfn));
      then
        ((Absyn.ALG_MATCHCASES(elst_1),(cls_1,pfn)));
    case((Absyn.ALG_NORETCALL(cref,fargs),(cls,pfn)))
      equation
        (cref_1,fargs_1) = buildNewCallInNewClass(cref,fargs,cls,pfn);
      then
        ((Absyn.ALG_NORETCALL(cref_1,fargs_1),(cls,pfn)));
    case((alg,(cls,pfn))) then ((alg,(cls,pfn)));
  end matchcontinue;
end fixCallsInNewClass;

// stefan
protected function fixCallsInNewClass2
"function: fixCallsInNewClass2
	helper function to fixCallsInNewClass"
	input tuple<Absyn.Exp, tuple<list<Absyn.Class>, list<PartFn>>> inTuple;
	output tuple<Absyn.Exp, tuple<list<Absyn.Class>, list<PartFn>>> outTuple;
algorithm
  outTuple := matchcontinue (inTuple)
    local
      Absyn.Exp e,me,res;
      list<Absyn.Class> cls;
      list<PartFn> pfn;
      Absyn.ComponentRef cref,cref_1;
      Absyn.FunctionArgs fargs,fargs_1;
      Absyn.MatchType  mt;
      list<Absyn.Case> caselst,caselst_1;
      list<Absyn.ElementItem> eilst;
      Option<String> oc;
      Absyn.ValueblockBody vb,vb_1;
    case((Absyn.CALL(cref,fargs),(cls,pfn)))
      equation
        (cref_1,fargs_1) = buildNewCallInNewClass(cref,fargs,cls,pfn);
      then
        ((Absyn.CALL(cref_1,fargs_1),(cls,pfn)));
    case((Absyn.MATCHEXP(mt,me,eilst,caselst,oc),(cls,pfn)))
      equation
        caselst_1 = fixCaseListCalls(caselst,cls,pfn);
      then
        ((Absyn.MATCHEXP(mt,me,eilst,caselst_1,oc),(cls,pfn)));
    case((Absyn.VALUEBLOCK(eilst,vb,res),(cls,pfn)))
      equation
        vb_1 = fixVBodyCalls(vb,cls,pfn);
      then
        ((Absyn.VALUEBLOCK(eilst,vb_1,res),(cls,pfn)));
    case((e,(cls,pfn))) then ((e,(cls,pfn)));
  end matchcontinue;
end fixCallsInNewClass2;

// stefan
protected function fixCallsInNewClass3
"function: fixCallsInNewClass3
	handles equations"
	input tuple<Absyn.Equation, tuple<list<Absyn.Class>, list<PartFn>>> inTuple;
	output tuple<Absyn.Equation, tuple<list<Absyn.Class>, list<PartFn>>> outTuple;
algorithm
  outTuple := matchcontinue (inTuple)
    local
      Absyn.Equation eq;
      list<Absyn.Class> cls,cls_1,cls_2;
      list<PartFn> pfn;
      Absyn.Exp e,e1,e2,e_1,e1_1,e2_1;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eeqitlst,eeqitlst_1;
      list<Absyn.EquationItem> eilst,eilst1,eilst2;
      Absyn.ForIterators fis,fis_1;
      Absyn.ComponentRef cref,cref_1;
      Absyn.FunctionArgs fargs,fargs_1;
    case((Absyn.EQ_IF(e,eilst1,eeqitlst,eilst2),(cls,pfn)))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        (eeqitlst_1,(cls_2,pfn)) = fixExpEqItemTupleLists2(eeqitlst,(cls_1,pfn));
      then
        ((Absyn.EQ_IF(e_1,eilst1,eeqitlst_1,eilst2),(cls_2,pfn)));
    case((Absyn.EQ_EQUALS(e1,e2),(cls,pfn)))
      equation
        ((e1_1,(cls_1,pfn))) = Absyn.traverseExp(e1,fixCallsInNewClass2,(cls,pfn));
        ((e2_1,(cls_2,pfn))) = Absyn.traverseExp(e2,fixCallsInNewClass2,(cls_1,pfn));
      then
        ((Absyn.EQ_EQUALS(e1_1,e2_1),(cls_2,pfn)));
    case((Absyn.EQ_FOR(fis,eilst),(cls,pfn)))
      equation
        (fis_1,(cls_1,pfn)) = fixForIterators2(fis,(cls,pfn));
      then
        ((Absyn.EQ_FOR(fis_1,eilst),(cls_1,pfn)));
    case((Absyn.EQ_WHEN_E(e,eilst,eeqitlst),(cls,pfn)))
      equation
        ((e_1,(cls_1,pfn))) = Absyn.traverseExp(e,fixCallsInNewClass2,(cls,pfn));
        (eeqitlst_1,(cls_2,pfn)) = fixExpEqItemTupleLists2(eeqitlst,(cls_1,pfn));
      then
        ((Absyn.EQ_WHEN_E(e_1,eilst,eeqitlst_1),(cls_2,pfn)));
    case((Absyn.EQ_NORETCALL(cref,fargs),(cls,pfn)))
      equation
        (cref_1,fargs_1) = buildNewCallInNewClass(cref,fargs,cls,pfn);
      then
        ((Absyn.EQ_NORETCALL(cref_1,fargs_1),(cls,pfn)));
    case((eq,(cls,pfn))) then ((eq,(cls,pfn)));
  end matchcontinue;
end fixCallsInNewClass3;

// stefan
protected function fixCaseListCalls
"function: fixCaseListCalls
	helper function to fixCallsInNewClass2
	goes through a list of matchcontinue cases"
	input list<Absyn.Case> inCaseList;
	input list<Absyn.Class> inClassList;
	input list<PartFn> inPartFnList;
	output list<Absyn.Case> outCaseList;
algorithm
  outCaseList := matchcontinue (inCaseList,inClassList,inPartFnList)
    local
      list<Absyn.Case> cdr,cdr_1;
      Absyn.Exp p,r;
      list<Absyn.ElementItem> eilst;
      list<Absyn.EquationItem> eqilst,eqilst_1;
      Option<String> oc;
      list<Absyn.Class> cls,cls_1;
      list<PartFn> pfn;
    case({},_,_) then {};
    case(Absyn.CASE(p,eilst,eqilst,r,oc) :: cdr,cls,pfn)
      equation
        ((eqilst_1,(cls_1,pfn))) = Absyn.traverseEquationItemList(eqilst,fixCallsInNewClass3,(cls,pfn));
        cdr_1 = fixCaseListCalls(cdr,cls_1,pfn);
      then
        (Absyn.CASE(p,eilst,eqilst_1,r,oc) :: cdr_1);
    case(Absyn.ELSE(eilst,eqilst,r,oc) :: cdr,cls,pfn)
      equation
        ((eqilst_1,(cls_1,pfn))) = Absyn.traverseEquationItemList(eqilst,fixCallsInNewClass3,(cls,pfn));
        cdr_1 = fixCaseListCalls(cdr,cls_1,pfn);
      then
        (Absyn.ELSE(eilst,eqilst,r,oc) :: cdr_1);
  end matchcontinue;
end fixCaseListCalls;

// stefan
protected function fixCaseListClasses
"function: fixCaseListCalls
	helper function to fixCallsAndCreateClasses2
	goes through a list of matchcontinue cases"
	input list<Absyn.Case> inCaseList;
	input list<Absyn.Class> inClassList;
	output list<Absyn.Case> outCaseList;
algorithm
  outCaseList := matchcontinue (inCaseList,inClassList)
    local
      list<Absyn.Case> cdr,cdr_1;
      Absyn.Exp p,r;
      list<Absyn.ElementItem> eilst;
      list<Absyn.EquationItem> eqilst,eqilst_1;
      Option<String> oc;
      list<Absyn.Class> cls,cls_1;
    case(Absyn.CASE(p,eilst,eqilst,r,oc) :: cdr,cls)
      equation
        ((eqilst_1,cls_1)) = Absyn.traverseEquationItemList(eqilst,fixCallsAndCreateClasses3,cls);
        cdr_1 = fixCaseListClasses(cdr,cls_1);
      then
        (Absyn.CASE(p,eilst,eqilst_1,r,oc) :: cdr_1);
    case(Absyn.ELSE(eilst,eqilst,r,oc) :: cdr,cls)
      equation
        ((eqilst_1,cls_1)) = Absyn.traverseEquationItemList(eqilst,fixCallsAndCreateClasses3,cls);
        cdr_1 = fixCaseListClasses(cdr,cls_1);
      then
        (Absyn.ELSE(eilst,eqilst,r,oc) :: cdr_1);
  end matchcontinue;
end fixCaseListClasses;

// stefan
protected function fixVBodyCalls
"function: fixVBodyCalls
	helper function to fixCallsInNewClass2
	goes through a valueblock body"
	input Absyn.ValueblockBody inValueblockBody;
	input list<Absyn.Class> inClassList;
	input list<PartFn> inPartFnList;
	output Absyn.ValueblockBody outValueblockBody;
algorithm
  outValueblockBody :=
  matchcontinue (inValueblockBody,inClassList,inPartFnList)
    local
      list<Absyn.AlgorithmItem> ailst1,ailst_1,ailst2,ailst_2;
      list<Absyn.EquationItem> eqilst,eqilst_1;
      list<Absyn.Class> cls,cls_1;
      list<PartFn> pfn;
    case(Absyn.VALUEBLOCKALGORITHMS(ailst1),cls,pfn)
      equation
        ((ailst_1,(cls_1,pfn))) = Absyn.traverseAlgorithmItemList(ailst1,fixCallsInNewClass,(cls,pfn));
      then
        Absyn.VALUEBLOCKALGORITHMS(ailst_1);
    case(Absyn.VALUEBLOCKMATCHCASE(ailst1,eqilst,ailst2),cls,pfn)
      equation
        ((ailst_1,_)) = Absyn.traverseAlgorithmItemList(ailst1,fixCallsInNewClass,(cls,pfn));
        ((eqilst_1,_)) = Absyn.traverseEquationItemList(eqilst,fixCallsInNewClass3,(cls,pfn));
        ((ailst_2,_)) = Absyn.traverseAlgorithmItemList(ailst2,fixCallsInNewClass,(cls,pfn));
      then
        Absyn.VALUEBLOCKMATCHCASE(ailst_1,eqilst_1,ailst_2);
  end matchcontinue;
end fixVBodyCalls;

// stefan
protected function fixVBodyClasses
"function: fixVBodyClasses
	helper function to fixCallsAndCreateClasses2
	goes through a valueblock body"
	input Absyn.ValueblockBody inValueblockBody;
	input list<Absyn.Class> inClassList;
	output Absyn.ValueblockBody outValueblockBody;
algorithm
  outValueblockBody :=
  matchcontinue (inValueblockBody,inClassList)
    local
      list<Absyn.AlgorithmItem> ailst1,ailst_1,ailst2,ailst_2;
      list<Absyn.EquationItem> eqilst,eqilst_1;
      list<Absyn.Class> cls,cls_1;
    case(Absyn.VALUEBLOCKALGORITHMS(ailst1),cls)
      equation
        ((ailst_1,cls_1)) = Absyn.traverseAlgorithmItemList(ailst1,fixCallsAndCreateClasses,cls);
      then
        Absyn.VALUEBLOCKALGORITHMS(ailst_1);
    case(Absyn.VALUEBLOCKMATCHCASE(ailst1,eqilst,ailst2),cls)
      equation
        ((ailst_1,_)) = Absyn.traverseAlgorithmItemList(ailst1,fixCallsAndCreateClasses,cls);
        ((eqilst_1,_)) = Absyn.traverseEquationItemList(eqilst,fixCallsAndCreateClasses3,cls);
        ((ailst_2,_)) = Absyn.traverseAlgorithmItemList(ailst2,fixCallsAndCreateClasses,cls);
      then
        Absyn.VALUEBLOCKMATCHCASE(ailst_1,eqilst_1,ailst_2);
  end matchcontinue;
end fixVBodyClasses;

// stefan
protected function buildNewCallInNewClass
"function: buildNewCallInNewClass
	builds the new calls in the new class
	takes the data from the PartFn to build the new call
	if the called function does not exist in the class list"
	input Absyn.ComponentRef inComponentRef;
	input Absyn.FunctionArgs inFunctionArgs;
	input list<Absyn.Class> inClassList;
	input list<PartFn> inPartFnList;
	output Absyn.ComponentRef outComponentRef;
	output Absyn.FunctionArgs outFunctionArgs;
algorithm
  (outComponentRef,outFunctionArgs) :=
  matchcontinue (inComponentRef,inFunctionArgs,inClassList,inPartFnList)
    local
      Absyn.ComponentRef cref,cref_1,cref_2,cref_3,cref_4;
      Absyn.FunctionArgs fargs,fargs_1,fargs_2;
      list<Absyn.Class> cls;
      list<PartFn> pfn;
      String s,s1,s2,s_1,fnargname;
      PartFn p;
      list<Absyn.Exp> elst;
      Absyn.Class cl,rec_cl;
      list<Absyn.ClassPart> cps,rec_cps;
      list<String> slst,slst_1;
      list<Absyn.ElementItem> elts1,elts2,elts3,rec_elts;
      list<Absyn.Path> plst;
      list<Absyn.ComponentRef> creflst;
      Absyn.Path p;
      Integer fnPos;
      list<Absyn.Exp> eargs,eargs_1,eargs_2,eargs_3;
      list<Absyn.NamedArg> nargs,nargs_1,nargs_2,nargs_3;
      Boolean isInNargs; // used to check if the function reference is in the named arguments
    // Recursive call
    case(cref,fargs,cls,pfn)
      equation
        cref_1 = Absyn.crefGetLastIdent(cref);
        s1 = Absyn.printComponentRefStr(cref_1); // recursive function
        ((cref_2,_,_,_,_)) = Util.listFirst(pfn);
        cref_3 = Absyn.crefGetLastIdent(cref_2);
        s2 = Absyn.printComponentRefStr(cref_3); // partially evaulated function
        s_1 = s1 +& "_" +& s2; // real function call
        cl = Absyn.getClassByName(s_1,cls);
        p = Absyn.makeIdentPathFromString(s_1);
        cref_4 = Absyn.pathToCref(p); // new cref
        cps = Absyn.getClassParts(cl); // retrieve elements from new class to get func input position
        elts1 = Absyn.getPublicElementsFromClassParts(cps);
        fnPos = getFuncArgPosition(elts1,s2,0);
        rec_cl = Absyn.getClassByName(s1,cls); // get original class to find out the function arg name
        rec_cps = Absyn.getClassParts(rec_cl);
        rec_elts = Absyn.getPublicElementsFromClassParts(rec_cps);
        Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,_,Absyn.COMPONENTS(_,_,Absyn.COMPONENTITEM(Absyn.COMPONENT(fnargname,_,_),_,_) :: _),_,_)) = listNth(rec_elts,fnPos);
        (eargs_1,nargs) = Absyn.extractArgs(fargs);
        (nargs_1,isInNargs) = stripFunctionFromNargs(nargs,fnargname);
        nargs_2 = generateNamedArgs(elts1,s2);
        nargs_3 = listAppend(nargs_1,nargs_2);
        eargs = Absyn.getExpListFromNamedArgList(nargs_2);
        //eargs_2 = Util.listReplaceAtWithList(eargs_1,fnPos,eargs);
        eargs_2 = stripFunctionFromEargs(eargs_1,fnPos);
        eargs_3 = Util.if_(isInNargs,eargs_1,eargs_2);
        //fargs_2 = Util.if_(fnPos == -1,Absyn.FUNCTIONARGS(eargs,nargs_3),Absyn.FUNCTIONARGS(eargs_2,nargs));
        fargs_2 = Absyn.FUNCTIONARGS(eargs_3,nargs_3);
      then
        (cref_4,fargs_2);
    // Function exists in the class list
    case(cref,fargs,cls,pfn)
      equation
        cref_1 = Absyn.crefGetLastIdent(cref);
        s = Absyn.printComponentRefStr(cref_1);
        _ = Absyn.getClassByName(s,cls);
      then
        (cref,fargs);
    // Function does not exist, create new call
    case(cref,fargs,cls,pfn)
      equation
        ((cref_1,_,_,_,_)) = Util.listFirst(pfn);
        s = Absyn.printComponentRefStr(cref_1);
        cl = Absyn.getClassByName(s,cls);
        cps = Absyn.getClassParts(cl);
        elts1 = Absyn.getPublicElementsFromClassParts(cps);
        elts2 = Util.listSelect(elts1,isInputElement);
        s_1 = stringAppend(s,"_");
        slst = Util.listMap(elts2,getInputName);
        slst_1 = Util.listMap1r(slst,stringAppend,s_1);
        plst = Util.listMap(slst_1,Absyn.makeIdentPathFromString);
        creflst = Util.listMap(plst,Absyn.pathToCref);
        elst = Util.listMap(creflst,Absyn.buildExpFromCref);
        fargs_1 = Absyn.FUNCTIONARGS(elst,{});
        fargs_2 = Absyn.appendFunctionArgs(fargs,fargs_1);
      then
        (cref_1,fargs_2);
  end matchcontinue;
end buildNewCallInNewClass;

// stefan
protected function generateNamedArgs
"function: generateNamedArgs
	takes a list of public elements and a function name, and generates named args from these"
	input list<Absyn.ElementItem> inElementItemList;
	input String inString;
	output list<Absyn.NamedArg> outNamedArgList;
algorithm
  outNamedArgList := matchcontinue (inElementItemList,inString)
    local
      list<Absyn.ElementItem> elts,elts_1;
      String name;
      list<String> el_names;
      list<Absyn.Path> plst;
      list<Absyn.ComponentRef> creflst;
      list<Absyn.Exp> elst;
      list<Absyn.NamedArg> nargs;
    case(elts,name)
      equation
        elts_1 = Util.listSelect1(elts,name,isElementNamed);
        el_names = Util.listMap(elts_1,getInputName);
        plst = Util.listMap(el_names,Absyn.makeIdentPathFromString);
        creflst = Util.listMap(plst,Absyn.pathToCref);
        elst = Util.listMap(creflst,Absyn.buildExpFromCref);
        nargs = Absyn.buildNamedArgList(el_names,elst);
      then
        nargs;
  end matchcontinue;
end generateNamedArgs;

// stefan
protected function isElementNamed
"function: isElementNamed
	helper function to generateNamedArgs"
	input Absyn.ElementItem inElementItem;
	input String inString;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inElementItem,inString)
    local
      String name,el_name;
      Integer len,len1,len2;
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,_,Absyn.COMPONENTS(_,_,Absyn.COMPONENTITEM(Absyn.COMPONENT(el_name,_,_),_,_) :: _),_,_)),name)
      equation
        len1 = stringLength(name);
        len2 = stringLength(el_name);
        len = intMin(len1,len2);
        true = Util.strncmp(name,el_name,len);
      then
        true;
    case(_,_) then false;
  end matchcontinue;
end isElementNamed;

// stefan
protected function stripFunctionFromEargs
"function: stripFunctionFromEargs
	removes the given cref from a list of positional function args"
	input list<Absyn.Exp> inExpList;
	input Integer inPos;
	output list<Absyn.Exp> outExpList;
algorithm
  outExpList := matchcontinue (inExpList,inPos)
    local
      list<Absyn.Exp> cdr,cdr_1;
      Integer pos;
    case(cdr,-1) then cdr;
    case(cdr,pos)
      equation
        true = pos < listLength(cdr);
        cdr_1 = Util.listRemoveNth(cdr,pos);
      then
        cdr_1;
    case(cdr,_) then cdr;
  end matchcontinue;
end stripFunctionFromEargs;

// stefan
protected function stripFunctionFromNargs
"function: stripFunctionFromNargs
	removes the given cref from a list of named function args"
	input list<Absyn.NamedArg> inNamedArgList;
	input String inString;
	output list<Absyn.NamedArg> outNamedArgList;
	output Boolean outBoolean;
algorithm
  (outNamedArgList,outBoolean) := matchcontinue(inNamedArgList,inString)
    local
      Absyn.NamedArg narg;
      list<Absyn.NamedArg> cdr,cdr_1;
      String argname,fnname;
      Boolean b;
    case({},_) then ({},false);
    // function found!
    case(Absyn.NAMEDARG(argname,_) :: cdr,fnname)
      equation
        true = argname ==& fnname;
      then
        (cdr,true);
    case(narg :: cdr,fnname)
      equation
        (cdr_1,b) = stripFunctionFromNargs(cdr,fnname);
      then
        (narg :: cdr_1,b);
  end matchcontinue;
end stripFunctionFromNargs;

// stefan
protected function getFuncArgPosition
"function: getFuncArgPosition
	returns the position of a functional argument based on the function name"
	input list<Absyn.ElementItem> inElementItemList;
	input String inString;
	input Integer inInteger;
	output Integer outInteger;
algorithm
  outInteger := matchcontinue (inElementItemList,inString,inInteger)
    local
      list<Absyn.ElementItem> cdr;
      String str,name;
      Integer pos,pos_1,pos_2,len,len1,len2;
    case({},str,pos) then -1;
      // Function argument found!
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,_,Absyn.COMPONENTS(_,_,Absyn.COMPONENTITEM(Absyn.COMPONENT(name,_,_),_,_) :: _),_,_)) :: cdr,str,pos)
      equation
        len1 = stringLength(str);
        len2 = stringLength(name);
        len = intMin(len1,len2);
        true = Util.strncmp(str,name,len);
      then
        pos;
    // Function argument not found
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,_,Absyn.COMPONENTS(_,_,Absyn.COMPONENTITEM(Absyn.COMPONENT(name,_,_),_,_) :: _),_,_)) :: cdr,str,pos)
      equation
        pos_1 = pos + 1;
        pos_2 = getFuncArgPosition(cdr,str,pos_1);
      then
        pos_2;
  end matchcontinue;
end getFuncArgPosition;

// stefan
protected function getInputName
"function: getInputNames
	passed as argument to Util.listMap
	retreives the name of an input element"
	input Absyn.ElementItem inElementItem;
	output String outString;
algorithm
  outString := matchcontinue(inElementItem)
    local
      list<Absyn.ComponentItem> cilst;
      String s;
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,_,Absyn.COMPONENTS(_,_,cilst),_,_)))
      equation
        Absyn.COMPONENTITEM(Absyn.COMPONENT(s,_,_),_,_) = Util.listFirst(cilst);
      then
        s;
    case(_) then "";
  end matchcontinue;
end getInputName;

// stefan
protected function fixClassInputs
"function: fixClassParts
	replaces partially evaluated function inputs with the inputs of the given functions"
	input list<Absyn.ClassPart> inClassPartList;
	input list<PartFn> inPartFnList;
	input list<Absyn.Class> inClassList;
	output list<Absyn.ClassPart> outClassPartList;
algorithm
  outClassPartList := matchcontinue (inClassPartList,inPartFnList,inClassList)
    local
      list<Absyn.ElementItem> elts,elts_1,elts_2;
      list<Absyn.ClassPart> cdr,cdr_1;
      list<PartFn> pfn;
      list<Absyn.Class> cls;
      Absyn.ClassPart cp;
    case({},_,_) then {};
    case(Absyn.PUBLIC(elts) :: cdr,pfn,cls)
      equation
        elts_1 = fixClassInputsPosArg(elts,pfn,cls,0);
        elts_2 = fixClassInputsNamedArg(elts_1,pfn,cls);
        cp = Absyn.PUBLIC(elts_2);
        cdr_1 = fixClassInputs(cdr,pfn,cls);
      then
        cp :: cdr_1;
    case(cp :: cdr,pfn,cls)
      equation
        cdr_1 = fixClassInputs(cdr,pfn,cls);
      then
        cp :: cdr_1;
  end matchcontinue;
end fixClassInputs;

// stefan
protected function isInputElement
"function: isInputElement
	returns true if the given Absyn.ElementItem is an input
	used as an argument to Util.listSelect"
	input Absyn.ElementItem inElementItem;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inElementItem)
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,_,Absyn.COMPONENTS(Absyn.ATTR(_,_,_,Absyn.INPUT(),_),_,_),_,_))) then true;
    case(_) then false;
  end matchcontinue;
end isInputElement;

// stefan
protected function prependStringToIdent
"function: prependStringToIdent
	prepends the given string to the ident of the given elementitem"
	input Absyn.ElementItem inElementItem;
	input String inString;
	output Absyn.ElementItem outElementItem;
algorithm
  outElementItem := matchcontinue(inElementItem,inString)
    local
      Boolean fp;
      Option<Absyn.RedeclareKeywords> rk;
      Absyn.InnerOuter io;
      String prefix,n,n_1;
      Absyn.ElementSpec s;
      Absyn.Info i;
      Option<Absyn.ConstrainClass> cc;
      Absyn.ElementAttributes ea;
      Absyn.TypeSpec ts;
      Absyn.ElementItem res;
      list<Absyn.ComponentItem> cilst,cilst_1;
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(fp,rk,io,n,Absyn.COMPONENTS(ea,ts,cilst),i,cc)),prefix)
      equation
        cilst_1 = Util.listMap1(cilst,prependStringToIdent2,prefix);
        res = Absyn.ELEMENTITEM(Absyn.ELEMENT(fp,rk,io,n,Absyn.COMPONENTS(ea,ts,cilst_1),i,cc));
      then
        res;
  end matchcontinue;
end prependStringToIdent;

// stefan
protected function prependStringToIdent2
"function: prependStringToIdent2
	helper function to prependStringToIdent
	passed as an argument to Util.listMap1"
	input Absyn.ComponentItem inComponentItem;
	input String inString;
	output Absyn.ComponentItem outComponentItem;
algorithm
  outComponentItem := matchcontinue(inComponentItem,inString)
    local
      Option<Absyn.ComponentCondition> cco;
      Option<Absyn.Comment> co;
      String n,n_1,prefix;
      Absyn.ArrayDim ad;
      Option<Absyn.Modification> mod;
      Absyn.ComponentItem res;
    case(Absyn.COMPONENTITEM(Absyn.COMPONENT(n,ad,mod),cco,co),prefix)
      equation
        n_1 = stringAppend(prefix,n);
        res = Absyn.COMPONENTITEM(Absyn.COMPONENT(n_1,ad,mod),cco,co);
      then res;
  end matchcontinue;
end prependStringToIdent2;

// stefan
protected function fixClassInputsPosArg
"function: fixClassPartsPosArg
	helper function to fixClassParts"
	input list<Absyn.ElementItem> inElementItemList;
	input list<PartFn> inPartFnList;
	input list<Absyn.Class> inClassList;
	input Integer inOffset;
	output list<Absyn.ElementItem> outElementItemList;
algorithm
  outElementItemList := matchcontinue (inElementItemList,inPartFnList,inClassList,inOffset)
    local
      list<Absyn.ElementItem> elts,elts2,elts3,elts4,elts_1,elts_2;
      list<PartFn> cdr;
      list<Absyn.Class> cls;
      Integer pos,pos_1,n,n_1;
      Absyn.ComponentRef cref;
      Absyn.Class cl;
      String s,s_1;
      list<Absyn.ClassPart> cps;
    case(elts,{},_,_) then elts;
    case(elts,(cref,_,_,SOME(pos),_) :: cdr,cls,n)
      equation
        s = Absyn.printComponentRefStr(cref);
        cl = Absyn.getClassByName(s,cls);
        cps = Absyn.getClassParts(cl);
        elts2 = Absyn.getPublicElementsFromClassParts(cps);
        elts3 = Util.listSelect(elts2,isInputElement);
        s_1 = stringAppend(s,"_");
        elts4 = Util.listMap1(elts3,prependStringToIdent,s_1);
        pos_1 = pos + n;
        elts_1 = Util.listReplaceAtWithList(elts4,pos_1,elts);
        n_1 = listLength(elts2) + n - 1;
        elts_2 = fixClassInputsPosArg(elts_1,cdr,cls,n_1);
      then
        elts_2;
    case(elts,_ :: cdr,cls,n)
      equation
        elts_1 = fixClassInputsPosArg(elts,cdr,cls,n);
      then
        elts_1;
  end matchcontinue;
end fixClassInputsPosArg;

// stefan
protected function getElementItemNamed
"function: getElementItemNamed
	helper function to fixClassInputsNamedArg
	used as argument to listSelect
	returns true if the element item contains a component with the given name"
	input Absyn.ElementItem inElementItem;
	input String inString;
	output Boolean outBoolean;
algorithm
  outElementItem := matchcontinue(inElementItem,inString)
    local
      String name;
      list<Absyn.ComponentItem> cilst,cilst_1;
      Integer len;
    case(Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_,_,Absyn.COMPONENTS(_,_,cilst),_,_)),name)
      equation
        cilst_1 = Util.listSelect1(cilst,name,getComponentItemNamed);
        len = listLength(cilst_1);
        true = len > 0;
      then
        true;
    case(_,_) then false;
  end matchcontinue;
end getElementItemNamed;

// stefan
protected function getComponentItemNamed
"function: getComponentItemNamed
	helper function to getElementItemNamed
	used as argument to listSelect
	returns true if the component item has the given name"
	input Absyn.ComponentItem inComponentItem;
	input String inString;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inComponentItem,inString)
    local
      String name,n;
    case(Absyn.COMPONENTITEM(Absyn.COMPONENT(n,_,_),_,_),name)
      equation
        true = name ==& n;
      then
        true;
    case(_,_) then false;
  end matchcontinue;
end getComponentItemNamed;

// stefan
protected function fixClassInputsNamedArg
"function: fixClassInputsNamedArg
	helper function to fixClassParts"
	input list<Absyn.ElementItem> inElementItemList;
	input list<PartFn> inPartFnList;
	input list<Absyn.Class> inClassList;
	output list<Absyn.ElementItem> outElementItemList;
algorithm
  outElementItemList := matchcontinue (inElementItemList,inPartFnList,inClassList)
    local
      list<Absyn.ElementItem> elts,elts2,elts3,elts4,elts_1,elts_2,items;
      list<PartFn> cdr;
      list<Absyn.Class> cls;
      String s,s_1,name;
      Absyn.Class cl;
      list<Absyn.ClassPart> cps;
      Integer pos;
      Absyn.ElementItem item;
      Absyn.ComponentRef cref;
    case(elts,{},_) then elts;
    case(elts,(cref,_,_,_,SOME(name)) :: cdr,cls)
      equation
        s = Absyn.printComponentRefStr(cref);
        cl = Absyn.getClassByName(s,cls);
        cps = Absyn.getClassParts(cl);
        elts2 = Absyn.getPublicElementsFromClassParts(cps);
        elts3 = Util.listSelect(elts2,isInputElement);
        s_1 = stringAppend(s,"_");
        elts4 = Util.listMap1(elts3,prependStringToIdent,s_1);
        items = Util.listSelect1(elts,name,getElementItemNamed);
        item = Util.listFirst(items);
        pos = Util.listPosition(item,elts);
        elts_1 = Util.listReplaceAtWithList(elts4,pos,elts);
        elts_2 = fixClassInputsNamedArg(elts_1,cdr,cls);
      then
        elts_2;
    case(elts,_ :: cdr,cls)
      equation
        elts_1 = fixClassInputsNamedArg(elts,cdr,cls);
      then
        elts_1;
  end matchcontinue;
end fixClassInputsNamedArg;

// stefan
protected function generateFuncName
"function: generateFuncName
	generates a new function name from a cref and a list of partfns"
	input Absyn.ComponentRef inComponentRef;
	input list<PartFn> inPartFnList;
	output Absyn.ComponentRef outComponentRef;
	String s,s_1,s_2;
	Absyn.Path p,p_1;
algorithm
  p := Absyn.crefToPath(inComponentRef);
  s := Absyn.pathString(p);
  s_1 := generateFuncName2(inPartFnList);
  s_2 := stringAppend(s,s_1);
  p_1 := Absyn.makeIdentPathFromString(s_2);
  outComponentRef := Absyn.pathToCref(p_1);
end generateFuncName;

// stefan
protected function generateFuncName2
"function: generateFuncName2
	helper function to generateFuncName"
	input list<PartFn> inPartFnList;
	output String outString;
algorithm
  outString := matchcontinue(inPartFnList)
    local
      list<PartFn> cdr;
      Absyn.ComponentRef cref;
      String s1,s2,s3,s4;
    case({}) then "";
    case((cref,_,_,_,_) :: cdr)
      equation
        s1 = "_"; //delimiter
        s2 = Absyn.printComponentRefStr(cref);
        s3 = generateFuncName2(cdr);
        s4 = s1 +& s2 +& s3;
      then
        s4;
  end matchcontinue;
end generateFuncName2;

// stefan
protected function fixPosArgs
"function: fixPosArgs
	Removes PARTEVALFUNCTION exps from the posarg list
	appends the arguments of this exp to the posarg list"
	input list<Absyn.Exp> inSearchList;
	output list<Absyn.Exp> outExpList;
algorithm
  outExpList := matchcontinue (inSearchList)
    local
      list<Absyn.Exp> cdr,eargs,nargexps,newargs,cdr_1;
      Absyn.Exp e;
      list<Absyn.NamedArg> nargs;
    case({}) then {};
    case(Absyn.PARTEVALFUNCTION(_,Absyn.FUNCTIONARGS(eargs,nargs)) :: cdr)
      equation
        (_,nargexps) = Absyn.getNamedFuncArgNamesAndValues(nargs);
        cdr_1 = fixPosArgs(cdr);
        newargs = listAppend(eargs,nargexps);
      then
        listAppend(cdr_1,newargs);
    case(e :: cdr)
      equation
        cdr_1 = fixPosArgs(cdr);
    then e :: cdr_1;
  end matchcontinue;
end fixPosArgs;

// stefan
protected function fixNamedArgs
"function: fixNamedArgs
	Removes PARTEVALFUNCTION exps from the posarg list
	appends the arguments of this exp to the posarg list"
	input list<Absyn.NamedArg> inNamedArgList;
	output list<Absyn.NamedArg> outNamedArgList;
	output list<Absyn.Exp> outPosArgList;
algorithm
  (outNamedArgList,outPosArgList) := matchcontinue(inNamedArgList)
    local
      Absyn.NamedArg na;
      list<Absyn.NamedArg> cdr,cdr_1,nargs;
      list<Absyn.Exp> new_eargs,new_eargs2,eargs;
      String name;
    case({}) then ({},{});
    case(Absyn.NAMEDARG(name,Absyn.PARTEVALFUNCTION(_,Absyn.FUNCTIONARGS(eargs,nargs))) :: cdr)
      equation
        (_,new_eargs) = Absyn.getNamedFuncArgNamesAndValues(nargs);
        (cdr_1,new_eargs2) = fixNamedArgs(cdr);
      then
        (cdr_1,listAppend(listAppend(eargs,new_eargs),new_eargs2));
    case(na :: cdr)
      equation
        (cdr_1,new_eargs) = fixNamedArgs(cdr);
      then
        (na :: cdr_1,new_eargs);
  end matchcontinue;
end fixNamedArgs;

// stefan
protected function addCrefToPartFnList
"function: addCrefToPartFnList
	takes a cref and a list of PartFn
	sets the last element of each tuple to the given cref"
	input Absyn.ComponentRef inComponentRef;
	input list<PartFn> inPartFnList;
	output list<PartFn> outPartFnList;
algorithm
  outPartFnList := matchcontinue(inComponentRef,inPartFnList)
    local
      Absyn.ComponentRef c,cref;
      Absyn.FunctionArgs f;
      list<PartFn> cdr,cdr_1;
      PartFn p;
      Option<Integer> io;
      Option<String> so;
    case(_,{}) then {};
    case(cref,(c,f,_,io,so) :: cdr)
      equation
        p = (c,f,cref,io,so);
        cdr_1 = addCrefToPartFnList(cref,cdr);
      then p :: cdr_1;
  end matchcontinue;
end addCrefToPartFnList;

// stefan
protected function findPartFnInPosArgs
"function: findPartFnInPosArgs
	searches a list of Absyn.Exp for PARTEVALFUNCTIONs"
	input list<Absyn.Exp> inExpList1;
	input list<Absyn.Exp> inExpList2;
	output list<PartFn> outPartFnList;
algorithm
  outPartFnList := matchcontinue(inExpList1,inExpList2)
    local
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs fargs;
      list<Absyn.Exp> cdr,elst;
      list<PartFn> pfn;
      PartFn p;
      Integer pos;
      Absyn.Exp e;
    case({},_) then {};
    case((e as Absyn.PARTEVALFUNCTION(cref,fargs)) :: cdr,elst)
      equation
        pos = Util.listPosition(e,elst);
        p = (cref,fargs,Absyn.CREF_IDENT("",{}),SOME(pos),NONE());
        pfn = findPartFnInPosArgs(cdr,elst);
      then p :: pfn;
    case(_ :: cdr,elst) then findPartFnInPosArgs(cdr,elst);
  end matchcontinue;
end findPartFnInPosArgs;

// stefan
protected function findPartFnInNamedArgs
"function: findPartFnInPosArgs
	searches a list Absyn.NamedArg for PARTEVALFUNCTIONs"
	input list<Absyn.NamedArg> inNamedArgList;
	output list<PartFn> outPartFnList;
algorithm
  outPartFnList := matchcontinue(inNamedArgList)
    local
      list<Absyn.NamedArg> cdr;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs fargs;
      list<PartFn> pfn;
      PartFn p;
      String s;
    case({}) then {};
    case(Absyn.NAMEDARG(s,Absyn.PARTEVALFUNCTION(cref,fargs)) :: cdr)
      equation
        p = (cref,fargs,Absyn.CREF_IDENT("",{}),NONE(),SOME(s));
        pfn = findPartFnInNamedArgs(cdr);
      then p :: pfn;
    case(_ :: cdr) then findPartFnInNamedArgs(cdr);
  end matchcontinue;
end findPartFnInNamedArgs;

end PartFn;