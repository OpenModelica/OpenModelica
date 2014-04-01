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

encapsulated package EvaluateFunctions
" file:        EvaluateFunctions.mo
  package:     EvaluateFunctions
  description: This package contains functions to evaluate modelica functions completely or partially

  RCS: $Id: EvaluateFunctions.mo 19593 2014-03-15 21:20:27Z lochel $"

public import Absyn;
public import BackendDAE;
public import DAE;
public import HashTable2;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEUtil;
protected import DAEDump;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;
protected import SCode;
protected import Util;


// =============================================================================
// evaluate functions 
//
// =============================================================================

public function evalFunctions
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      BackendDAE.EqSystems eqSysts;
      BackendDAE.Shared shared;
    case(_)
      equation
        true = Flags.isSet(Flags.EVALUATE_CONST_FUNCTIONS);
        BackendDAE.DAE(eqs = eqSysts,shared = shared) = inDAE;
        (eqSysts,(shared,_)) = List.mapFold(eqSysts,evalFunctions_main,(shared,1));
        outDAE = BackendDAE.DAE(eqSysts,shared);
      then
        outDAE;
    else
      then
        inDAE;   
  end matchcontinue;   
end evalFunctions;

protected function evalFunctions_main
  input BackendDAE.EqSystem eqSysIn;
  input tuple<BackendDAE.Shared,Integer> tplIn;
  output BackendDAE.EqSystem eqSysOut;
  output tuple<BackendDAE.Shared,Integer> tplOut;
protected
  Integer sysIdx;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.IncidenceMatrix m1,m2;
  BackendDAE.Shared sharedIn, shared;
  BackendDAE.EquationArray eqs;
  BackendDAE.Matching matching;
  BackendDAE.Variables vars;
  list<BackendDAE.Var> varLst;
  list<BackendDAE.Equation> eqLst, addEqs;
  BackendDAE.StateSets stateSets;
algorithm
  (sharedIn,sysIdx) := tplIn;
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqs,m=m,mT=mT,matching=matching,stateSets=stateSets) := eqSysIn;
  eqLst := BackendEquation.equationList(eqs);
  varLst := BackendVariable.varList(vars);
  BackendDump.dumpEquationList(eqLst, "the equations before evaluationg the functions"); 
   
  //traverse the eqSystem for function calls
  (eqLst,(shared,addEqs)) := List.mapFold(eqLst,evalFunctions_findFuncs,(sharedIn,{}));
  eqLst := listAppend(eqLst,addEqs);
  eqs := BackendEquation.listEquation(eqLst);
  eqSysOut := BackendDAE.EQSYSTEM(vars,eqs,m,mT,matching,stateSets);
  
  BackendDump.dumpEquationList(eqLst, "the equations after evaluationg the functions"); 
  
  //(_,m1,m2,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(eqSysOut,BackendDAE.NORMAL(),NONE());
  //BackendDump.dumpIncidenceMatrix(m1);
  //BackendDump.dumpIncidenceMatrixT(m2);
  
  tplOut := (shared,sysIdx+1);
end evalFunctions_main;

protected function evalFunctions_findFuncs
  input BackendDAE.Equation eqIn;
  input tuple<BackendDAE.Shared,list<BackendDAE.Equation>> tplIn;
  output BackendDAE.Equation eqOut;
  output tuple<BackendDAE.Shared,list<BackendDAE.Equation>> tplOut;
algorithm
  (eqOut,tplOut) := matchcontinue(eqIn,tplIn)
    local
      Integer size;
      Boolean b1,b2,diff;
      BackendDAE.Equation eq;
      BackendDAE.Shared shared;
      DAE.Exp exp1,exp2,lhsExp,rhsExp;
      DAE.ElementSource source;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> addEqs;
      list<DAE.Exp> lhs;
    case(BackendDAE.EQUATION(exp=exp1, scalar=exp2,source=source,differentiated=diff),_)
      equation
        b1 = Expression.containFunctioncall(exp1);
        b2 = Expression.containFunctioncall(exp2);
        true = b1 or b2;
        (shared,addEqs) = tplIn;
        funcs = BackendDAEUtil.getFunctions(shared);
        ((rhsExp,lhsExp,addEqs,funcs)) = Debug.bcallret3(b1,evaluateConstantFunction,exp1,exp2,funcs,(exp2,exp1,addEqs,funcs));
        ((rhsExp,lhsExp,addEqs,funcs)) = Debug.bcallret3(b2,evaluateConstantFunction,exp2,exp1,funcs,(rhsExp,lhsExp,addEqs,funcs));
        eq = BackendDAE.EQUATION(lhsExp,rhsExp,source,diff);
      then
        (eq,(shared,addEqs));
    case(BackendDAE.ARRAY_EQUATION(dimSize =_, left=exp1, right=exp2, source=source, differentiated=diff),_)
      equation
        print("this is an array equation. update evalFunctions_findFuncs");
      then
        (eqIn,tplIn);
    case(BackendDAE.COMPLEX_EQUATION(size =_, left=exp1, right=exp2, source=source, differentiated=diff),_)
      equation
        b1 = Expression.containFunctioncall(exp1);
        b2 = Expression.containFunctioncall(exp2);
        true = b1 or b2;
        (shared,addEqs) = tplIn;
        funcs = BackendDAEUtil.getFunctions(shared);
        ((rhsExp,lhsExp,addEqs,funcs)) = Debug.bcallret3(b1,evaluateConstantFunction,exp1,exp2,funcs,(exp2,exp1,addEqs,funcs));
        ((rhsExp,lhsExp,addEqs,funcs)) = Debug.bcallret3(b2,evaluateConstantFunction,exp2,exp1,funcs,(rhsExp,lhsExp,addEqs,funcs));
        shared = BackendDAEUtil.addFunctionTree(funcs,shared);  
        size = DAEUtil.getTupleSize(lhsExp);
        eq = Util.if_(intEq(size,0),BackendDAE.EQUATION(lhsExp,rhsExp,source,diff),BackendDAE.COMPLEX_EQUATION(size,lhsExp,rhsExp,source,diff));
        
        //print("the lhs:\n");
        //ExpressionDump.dumpExp(lhsExp);
        //print("the rhs \n");
        //ExpressionDump.dumpExp(rhsExp);
        //BackendDump.printEquation(eq);
        //print("the size of the complex equation: "+&intString(size)+&"\n");
      then
        (eq,(shared,addEqs));
    else
      equation
        (shared,addEqs) = tplIn;
      then
        (eqIn,tplIn);
  end matchcontinue;        
end evalFunctions_findFuncs;

protected function evaluateConstantFunction
  input DAE.Exp rhsExpIn;
  input DAE.Exp lhsExpIn;
  input DAE.FunctionTree funcsIn;
  output tuple<DAE.Exp, DAE.Exp, list<BackendDAE.Equation>, DAE.FunctionTree> outTpl;
algorithm
  outTpl := matchcontinue(rhsExpIn,lhsExpIn,funcsIn)
    local
      Boolean funcIsConst, funcIsPartConst;
      list<Boolean> bList;
      list<Integer> constIdcs;
      Absyn.Path path;
      BackendVarTransform.VariableReplacements repl;
      HashTable2.HashTable ht;
      DAE.CallAttributes attr1, attr2;
      DAE.ComponentRef constCref, lhsCref;
      DAE.Exp exp, exp2, constExp, outputExp;
      DAE.Function func;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> constEqs;
      list<DAE.ComponentRef> inputCrefs, outputCrefs, allInputCrefs, allOutputCrefs, constInputCrefs, constComplexCrefs, constScalarCrefs, constCrefs, varScalarCrefs,varScalarCrefsInFunc;
      list<DAE.Element> elements, algs, allInputs, protectVars, inputs1d, allOutputs, complex, varInputs, varOutputs;
      list<DAE.Exp> exps, inputExps, complexExp, allInputExps, constInputExps, constExps, constComplexExps, constScalarExps, varScalarExps;
      list<list<DAE.Exp>> scalarExp;
      list<DAE.Statement> stmts;
      list<list<DAE.ComponentRef>> scalarInputs, scalarOutputs;
      list<DAE.ComponentRef> constComplexLst;
      list<DAE.ComponentRef> partConstLst;
      list<DAE.ComponentRef> partVarLst;
    case(DAE.CALL(path=path, expLst=exps, attr=attr1),_,_)
      equation
        //print("BEFORE:\n");
        //ExpressionDump.dumpExp(rhsExpIn);
        
        // get the elements of the function and the algorithms
        SOME(func) = DAEUtil.avlTreeGet(funcsIn,path);
        elements = DAEUtil.getFunctionElements(func);
        protectVars = List.filterOnTrue(elements,DAEUtil.isProtectedVar);
        algs = List.filter(elements,DAEUtil.isAlgorithm);
        lhsCref = Expression.expCref(lhsExpIn);
                       
        // get all input crefs and expresssions (scalar and one dimensioanl)
        allInputs = List.filter(elements,DAEUtil.isInputVar);
        scalarInputs = List.map(allInputs,getScalarsForComplexVar);  
        inputs1d = List.filterOnTrue(allInputs,isNotComplexVar);
        inputCrefs = List.map(inputs1d,DAEUtil.varCref);  // the one dimensional variables
        allInputCrefs = listAppend(inputCrefs,List.flatten(scalarInputs));
        //print("\nallInputCrefs\n"+&stringDelimitList(List.map(allInputCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        
        scalarExp = List.map(exps,Expression.getComplexContents); 
        inputExps = List.filterOnTrue(exps,Expression.isNotComplex);
        allInputExps = listAppend(inputExps,List.flatten(scalarExp));
        //print("\nallInputExps\n"+&stringDelimitList(List.map(allInputExps,ExpressionDump.printExpStr),"\n")+&"\n");
        
        // get all output crefs (complex and scalar)
        allOutputs = List.filter(elements,DAEUtil.isOutputVar);
        outputCrefs = List.map(allOutputs,DAEUtil.varCref);          
        scalarOutputs = List.map(allOutputs,getScalarsForComplexVar);
        allOutputCrefs = listAppend(outputCrefs,List.flatten(scalarOutputs));
        //print("\ncomplex OutputCrefs\n"+&stringDelimitList(List.map(outputCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("\nOutputCrefs\n"+&stringDelimitList(List.map(allOutputCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
             
        // get the constant inputs
        (constInputExps,constInputCrefs) = List.filterOnTrueSync(allInputExps,Expression.isConst,allInputCrefs);
        //print("\nallInputExps\n"+&stringDelimitList(List.map(allInputExps,ExpressionDump.printExpStr),"\n")+&"\n");
        //print("\nconstInputExps\n"+&stringDelimitList(List.map(constInputExps,ExpressionDump.printExpStr),"\n")+&"\n");
        //print("\naconstInputCrefs\n"+&stringDelimitList(List.map(constInputCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("\nall algs "+&intString(listLength(algs))+&"\n"+&DAEDump.dumpElementsStr(algs)+&"\n");
        
        //build replacement rules
        repl = BackendVarTransform.emptyReplacements();
        //repl = BackendVarTransform.addReplacements(repl,constInputCrefs,constInputExps,NONE());
        repl = BackendVarTransform.addReplacements(repl,allInputCrefs,allInputExps,NONE());
          //BackendVarTransform.dumpReplacements(repl);
        
        // go through all algorithms and replace the variables with constants if possible, extend the ht after each algorithm
        (algs,(_,repl)) = List.mapFold(algs,evaluateFunctions_updateAlgorithms,(funcsIn,repl));
          //print("\nall algs after"+&intString(listLength(algs))+&"\n"+&DAEDump.dumpElementsStr(algs)+&"\n");
          //BackendVarTransform.dumpReplacements(repl);
               
        //get all replacements in order to check for constant outputs
        (constCrefs,constExps) = BackendVarTransform.getAllReplacements(repl);  
        (constCrefs,constExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,allOutputCrefs,constExps); // extract outputs
        (constExps,constCrefs) = List.filterOnTrueSync(constExps,Expression.isConst,constCrefs); // extract constant outputs
        //print("all constant crefs \n"+&stringDelimitList(List.map(constCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("all constant exps:\n"+&ExpressionDump.printExpListStr(constExps)+&"\n");        
        
        // get the completely constant complex outputs, the constant parts of complex outputs and the variable parts of complex outputs adn the expressions
        (constComplexLst,constScalarCrefs,varScalarCrefs) = checkIfOutputIsEvaluatedConstant(allOutputs,constCrefs,{},{},{});
        (constScalarCrefs,constScalarExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constScalarCrefs,constExps);
        (constComplexLst,constComplexExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constComplexLst,constExps);
        //print("\nconstComplexLst 1\n"+&stringDelimitList(List.map(constComplexLst,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("\npartConstLst 1\n"+&stringDelimitList(List.map(constScalarCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("\npartVarLst 1\n"+&stringDelimitList(List.map(varScalarCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        
        // is it completely constant or partially?
        funcIsConst = List.isEmpty(varScalarCrefs);
        funcIsPartConst = List.isNotEmpty(varScalarCrefs);
        
        //Debug.bcall1(funcIsConst,print,"the function output is completely constant\n");
        //Debug.bcall1(not funcIsConst,print,"the function output is not completely constant\n");
        //Debug.bcall1(funcIsPartConst,print,"the function output is partially constant\n");
        //Debug.bcall1(not funcIsPartConst and not funcIsConst,print,"the function output is not constant in any case\n");
        true =  funcIsPartConst or funcIsConst;
             
        // build the new lhs and the new statements for the function
        (_,varScalarCrefsInFunc,_) = List.intersection1OnTrue(List.flatten(scalarOutputs),constScalarCrefs,ComponentReference.crefEqual);  
        varOutputs = List.map2(varScalarCrefsInFunc,generateOutputElements,allOutputs,lhsExpIn);  
        varScalarCrefs = List.map(varScalarCrefsInFunc,ComponentReference.crefStripFirstIdent);
        varScalarCrefs = List.map1(varScalarCrefs,ComponentReference.joinCrefsR,lhsCref);
        varScalarExps = List.map(varScalarCrefs,Expression.crefExp);
        //print("\n varScalarCrefs \n"+&stringDelimitList(List.map(varScalarCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        
        constScalarCrefs = List.map(constScalarCrefs,ComponentReference.crefStripFirstIdent);
        constScalarCrefs = List.map1(constScalarCrefs,ComponentReference.joinCrefsR,lhsCref);
        outputExp = Debug.bcallret1(List.hasOneElement(varScalarExps),List.first,varScalarExps,DAE.TUPLE(varScalarExps));
        
        // build the new partial function
        (algs,constEqs) = Debug.bcallret3_2(not funcIsConst,buildPartialFunction,(varScalarCrefsInFunc,algs),(constScalarCrefs,constScalarExps),repl,algs,{});
        elements = listAppend(allInputs,varOutputs);
        elements = listAppend(elements,protectVars);
        elements = listAppend(elements,algs);
        elements = List.unique(elements);
        (func,path) = updateFunctionBody(func,elements);
        attr2 = DAEUtil.replaceCallAttrType(attr1,DAE.T_TUPLE({},DAE.emptyTypeSource));
        attr2 = Util.if_(intEq(listLength(varOutputs),1),attr1,attr2);
        //DAEDump.dumpCallAttr(attr2);
        funcs = DAEUtil.addDaeFunction({func},funcsIn);
        exp2 = DAE.CALL(path, exps, attr2);
          
        //decide which lhs or which rhs to take
        outputExp = Util.if_(funcIsPartConst,outputExp,lhsExpIn);
        exp = Debug.bcallret1(funcIsConst,List.first,constComplexExps,rhsExpIn);       
        exp = Util.if_(funcIsPartConst,exp2,exp);

        //print("LHS EXP:\n");
        //ExpressionDump.dumpExp(outputExp);       
        //print("RHS EXP:\n");
        //ExpressionDump.dumpExp(exp);
      then
        ((exp,outputExp,constEqs,funcs));
    else
      equation
      then
        ((rhsExpIn,lhsExpIn,{},funcsIn));
  end matchcontinue;
end evaluateConstantFunction;

protected function checkIfOutputIsEvaluatedConstant
  input list<DAE.Element> elements;  // check this var
  input list<DAE.ComponentRef> constCrefs;
  input list<DAE.ComponentRef> constComplexLstIn; //completely constant complex vars
  input list<DAE.ComponentRef> partConstLstIn; // partially constant complex var parts
  input list<DAE.ComponentRef> partVarLstIn; // the variable part of the complex var
  output list<DAE.ComponentRef> constComplexLstOut;
  output list<DAE.ComponentRef> partConstLstOut;
  output list<DAE.ComponentRef> partVarLstOut;
algorithm
  (constComplexLstOut,partConstLstOut,partVarLstOut) := matchcontinue(elements,constCrefs,constComplexLstIn,partConstLstIn,partVarLstIn)
    local
      Boolean const;
      DAE.ComponentRef cref;
      DAE.Element elem;
      list<DAE.ComponentRef> scalars, constVars, varVars, partConstCrefs, varCrefs;
      list<DAE.Element> rest;
      list<DAE.ComponentRef> partVar;
      list<DAE.ComponentRef> constCompl, partConst;
    case({},_,_,_,_)
      equation
        then(constComplexLstIn,partConstLstIn,partVarLstIn);
    case(elem::rest,_,_,_,_)
      equation
        cref = DAEUtil.varCref(elem);
        scalars = getScalarsForComplexVar(elem);
        // function outputs a record
        true = List.isNotEmpty(scalars);
        (constVars,varVars,_) = List.intersection1OnTrue(scalars,constCrefs,ComponentReference.crefEqual);
        const = intEq(listLength(scalars),listLength(constVars));
          //print("is the complete output var constant? "+&boolString(const)+&"\n");
          //print("\nconstVars 1\n"+&stringDelimitList(List.map(constVars,ComponentReference.printComponentRefStr),"\n")+&"\n");
          //print("\nvarVars 1\n"+&stringDelimitList(List.map(varVars,ComponentReference.printComponentRefStr),"\n")+&"\n");
        (partConstCrefs) = List.filter1OnTrue(constCrefs,ComponentReference.crefInLst,constVars);
        (_,varCrefs,_) = List.intersection1OnTrue(scalars,partConstCrefs,ComponentReference.crefEqual);
        constCompl = Util.if_(const,cref::constComplexLstIn,constComplexLstIn);
        partConst = Util.if_(not const,listAppend(partConstCrefs,partConstLstIn),partConstLstIn);
        partVar = Util.if_(not const,listAppend(varCrefs,partVarLstIn),partVarLstIn);
        (constCompl,partConst,partVar) = checkIfOutputIsEvaluatedConstant(rest,constCrefs,constCompl,partConst,partVar);
      then
        (constCompl,partConst,partVar);  
    case(elem::rest,_,_,_,_)
      equation
        cref = DAEUtil.varCref(elem);
        scalars = getScalarsForComplexVar(elem);
        // function output is one dimensional
        true = List.isEmpty(scalars); 
        (constCompl,partConst,partVar) = checkIfOutputIsEvaluatedConstant(rest,constCrefs,cref::constComplexLstIn,partConstLstIn,partVarLstIn);
      then
        (constCompl,partConst,partVar);
    else
      equation
        print("checkIfOutputIsEvaluatedConstant failed!\n");
        then
          fail();
  end matchcontinue;
end checkIfOutputIsEvaluatedConstant;


protected function generateOutputElements "generates the scalar outputs for the new function
author:Waurich TUD 2014-03"
  input DAE.ComponentRef cref;
  input list<DAE.Element> inFuncOutputs;
  input DAE.Exp recId;
  output DAE.Element newOutputs;
algorithm
  newOutputs := match(cref,inFuncOutputs,recId)
    local
      DAE.Ident i1,i2;
      DAE.ComponentRef cref1,cref2;
      DAE.Element var;
      DAE.Exp exp;
      DAE.Type typ;
      list<DAE.ComponentRef> vars;
      list<DAE.Element> oldOutputs2;
      list<DAE.Subscript> sl;
    case(DAE.CREF_QUAL(ident=_,identType=typ,subscriptLst=sl,componentRef=_),_,_)
      equation    
        //print("generate output element\n");
        typ = ComponentReference.crefLastType(cref);
        //cref1 = ComponentReference.crefStripLastIdent(cref);
        //print("cref\n"+&ComponentReference.printComponentRefStr(cref)+&"\n");     
        exp = Expression.crefExp(cref); 
        //ExpressionDump.dumpExp(exp);
        
        // its not possible to use qualified output crefs
        i1 = ComponentReference.crefFirstIdent(cref);
        i2 = ComponentReference.crefLastIdent(cref);
        //print("the idents_ "+&i1+&i2+&"\n");
        i1 = i1+&"_"+&i2;
        cref1 = ComponentReference.makeCrefIdent(i1,typ,sl);
        
        
        //print("the inFuncOutputs \n"+&DAEDump.dumpElementsStr(inFuncOutputs)+&"\n");
        //vars = List.map(inFuncOutputs,DAEUtil.varCref);
        //print("all the crefs of the oldoutputs\n"+&stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr),",")+&"\n");
        //(vars,oldOutputs2) = List.filter1OnTrueSync(vars,ComponentReference.crefEqual,cref1,inFuncOutputs);
        //var = List.first(oldOutputs2);
        var = List.first(inFuncOutputs);
        var = DAEUtil.replaceCrefandTypeInVar(cref1,typ,var);
        //print("the new var id \n"+&DAEDump.dumpElementsStr({var})+&"\n");
      then
        var;
    else
      equation 
        print("generateOutputElements failed!\n");
      then fail();
  end match;
end generateOutputElements;


protected function updateFunctionBody
  input DAE.Function funcIn;
  input list<DAE.Element> body;
  output DAE.Function funcOut;
  output Absyn.Path pathOut;
algorithm
  (funcOut,pathOut) := match(funcIn, body)
    local
      String s;
      list<String> chars;
      Absyn.Path path;
      list<DAE.FunctionDefinition> funcs;
      DAE.Type typ;
      Boolean pP, iI;
      DAE.InlineType iType;
      DAE.ElementSource source;
      DAE.Function func;
      Option<SCode.Comment> comment;
    case(DAE.FUNCTION(path=path,functions=funcs,type_=typ,partialPrefix=pP,isImpure=iI,inlineType=iType,source=source,comment=comment),_)
      equation
        //print("the pathname before: "+&Absyn.pathString(path)+&"\n");
        //print("THE FUNCTION BEFORE \n"+&DAEDump.dumpFunctionStr(funcIn)+&"\n");
        s = Absyn.pathString(path);
        chars = stringListStringChar(s);
        chars = listDelete(chars,0);
        s = stringCharListString(chars);
        path = Absyn.stringPath(s+&"_eval");
        func = DAE.FUNCTION(path,{DAE.FUNCTION_DEF(body)},typ,pP,iI,iType,source,comment);
        //print("THE FUNCTION AFTER \n"+&DAEDump.dumpFunctionStr(func)+&"\n");
        //print("the pathname after: "+&Absyn.pathString(path)+&"\n");
      then
        (func,path);
    else
      equation
        print("updateFunctionBody failed \n");
        then
          fail();
  end match;
end updateFunctionBody;


protected function buildPartialFunction "build a partial function for the variable outputs of a complex function and generate some simple equations for the constant outputs.
author:Waurich TUD 2014-03"
  input tuple<list<DAE.ComponentRef>,list<DAE.Element>> varPart;
  input tuple<list<DAE.ComponentRef>,list<DAE.Exp>> constPart;
  input BackendVarTransform.VariableReplacements replIn;
  output list<DAE.Element> algsOut;
  output list<BackendDAE.Equation> eqsOut;
protected
  BackendDAE.Equation eqs;
  list<DAE.ComponentRef> constCrefs,varCrefs;
  DAE.Exp funcIn;
  list<DAE.Element> funcAlgs;
  list<DAE.Exp> constExps,lhsExps; 
  list<DAE.Statement> stmts;
algorithm
  (varCrefs,funcAlgs) := varPart;
  (constCrefs,constExps) := constPart;
  //print("all the varCrefs\n"+&stringDelimitList(List.map(varCrefs,ComponentReference.printComponentRefStr),",")+&"\n");
  
  // generate the additional equations
  lhsExps := List.map(constCrefs,Expression.crefExp);
  eqsOut := generateConstEqs(lhsExps,constExps,{}); 
  
  // build the partial function algorithm, replace the qualified crefs
  stmts := List.mapFlat(funcAlgs, DAEUtil.getStatement);
  stmts := List.filterOnTrue(stmts,statementRHSIsNotConst);
  
  (stmts,_) := DAEUtil.traverseDAEEquationsStmts(stmts,makeIdentCref,varCrefs);
  algsOut := {DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),DAE.emptyElementSource)};
end buildPartialFunction;

protected function makeIdentCref  "traverses the exps"
  input tuple<DAE.Exp,list<DAE.ComponentRef>> inTpl;
  output tuple<DAE.Exp,list<DAE.ComponentRef>> outTpl;
protected
  DAE.Exp exp;
  list<DAE.ComponentRef> crefs;
algorithm
  (exp,crefs) := inTpl;
  ((exp,crefs)) := Expression.traverseExpTopDown(exp,makeIdentCref1,crefs);
  outTpl := (exp,crefs);
end makeIdentCref;

protected function makeIdentCref1  "searches only for crefs"
  input tuple<DAE.Exp, list<DAE.ComponentRef>> inTpl;
  output tuple<DAE.Exp, Boolean, list<DAE.ComponentRef>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs;
      DAE.Exp exp;
      DAE.Type ty;
      String delimiter;
    case((DAE.CREF(componentRef=cref,ty=ty),crefs))
      equation
        cref = makeIdentCref2(cref,crefs);
        exp = DAE.CREF(cref,ty);
      then
        ((exp,true,crefs));
    case((exp,crefs))
      then
        ((exp,false,crefs));
  end match;
end makeIdentCref1;


protected function makeIdentCref2"appends the crefs of a qualified crefs with the given delimiter
author:Waurich TUD 2014-03"
  input DAE.ComponentRef crefIn;
  input list<DAE.ComponentRef> changeTheseCrefs;
  output DAE.ComponentRef crefOut;
algorithm
  crefOut := matchcontinue(crefIn,changeTheseCrefs)
    local
      DAE.ComponentRef cref1, cref2;
      String delimiter,i1,i2;
      DAE.Type typ;
      list<DAE.Subscript> sl;
    case(cref1 as DAE.CREF_QUAL(ident=i1,identType=typ,subscriptLst=sl,componentRef=cref2),_)
      equation
        true = List.isMemberOnTrue(cref1,changeTheseCrefs,ComponentReference.crefEqual); 
        i2 = ComponentReference.crefFirstIdent(cref2);
        i1 = i1+&"_"+&i2;
        cref2 = replaceCrefIdent(cref2,i1);
        cref2 = makeIdentCref2(cref2,changeTheseCrefs); 
      then
        cref2;
    case(cref1 as DAE.CREF_IDENT(ident=i1,identType=typ,subscriptLst=sl),_)
      equation
       then
         cref1;
    else
      then
        crefIn;
  end matchcontinue;
end makeIdentCref2;

protected function replaceCrefIdent  "replaces the ident of a cref
author:Waurich TUD 2014-03"
  input DAE.ComponentRef crefIn;
  input String ident;
  output DAE.ComponentRef crefOut;
algorithm
  crefOut := match(crefIn,ident)
    local
      DAE.ComponentRef cref,cref2;
      DAE.Type typ;
      list<DAE.Subscript> sl;
    case(DAE.CREF_QUAL(ident=_,identType=typ,subscriptLst=sl,componentRef=cref2),_)
      equation
        cref = DAE.CREF_QUAL(ident,typ,sl,cref2);
      then
        cref;
    case(DAE.CREF_IDENT(ident=_,identType=typ,subscriptLst=sl),_)     
      equation
        cref = DAE.CREF_IDENT(ident,typ,sl);
      then
        cref;
    else
      then 
        crefIn;
  end match;
end replaceCrefIdent;


protected function stmt2Alg"makes a DAE.Element.ALGORITHM of a DAE.Statement.
author:Waurich TUD 2014-03"
  input DAE.Statement stmt;
  output DAE.Element alg;
algorithm
  alg := DAE.ALGORITHM(DAE.ALGORITHM_STMTS({stmt}),DAE.emptyElementSource);
end stmt2Alg;

protected function statementRHSIsNotConst"checks whether the rhs of a statement is constant.
author:Waurich TUD 2014-03"
  input DAE.Statement stmt;
  output Boolean notConst;
algorithm
  notConst := match(stmt)
    local
      Boolean b, trueCond;
      DAE.Else else_;
      DAE.Exp rhs, cond;
      list<DAE.Statement> stmts;
    case(DAE.STMT_ASSIGN(type_=_,exp1=_,exp=rhs))
      equation
        b = Expression.isConst(rhs);
      then
        not b;
    else
      equation
        then
          false;
  end match;
end statementRHSIsNotConst;
  
protected function generateConstEqs" generate a list of BackendDAE.EQUATION.
author:Waurich TUD 2014-03"
  input list<DAE.Exp> lhsLst;
  input list<DAE.Exp> rhsLst;
  input list<BackendDAE.Equation> eqsIn;
  output list<BackendDAE.Equation> eqsOut;
algorithm
  eqsOut := match(lhsLst,rhsLst,eqsIn)
    local
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqs;
      DAE.Exp lhs,rhs;
      list<DAE.Exp> lrest,rrest;
    case({},{},_)
      then
        eqsIn;
    case(lhs::lrest,rhs::rrest,_)
      equation
        eq = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,false);
        eqs = generateConstEqs(lrest,rrest,eq::eqsIn);
      then
        eqs;
    else
      equation
        print("generateConstEqs failed!\n");
      then
        fail();
  end match;
end generateConstEqs;
         
protected function crefIsInLst
  input DAE.ComponentRef crefIn;
  input list<DAE.ComponentRef> crefLst;
  output Boolean isInLst;
algorithm
  isInLst := List.isMemberOnTrue(crefIn, crefLst, ComponentReference.crefEqual);
end crefIsInLst;  

protected function evaluateFunctions_updateAlgorithms"gets the statements from an algorithm in order to traverse them.
author:Waurich TUD 2014-03"
  input DAE.Element algIn;
  input tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements> tplIn;
  output DAE.Element algOut;
  output tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements> tplOut;
protected
  BackendVarTransform.VariableReplacements replIn, replOut;
  DAE.Algorithm alg;
  DAE.ElementSource source;
  DAE.FunctionTree funcs;
  list<DAE.Statement> stmts;
algorithm
  (funcs,replIn) := tplIn;
  DAE.ALGORITHM(alg,source) := algIn;
  stmts := DAEUtil.getStatement(algIn);  
  //(stmts,(_,replOut)) := List.mapFold(stmts,evaluateFunctions_updateStatement,(funcs,replIn));
  (stmts,replOut) := evaluateFunctions_updateStatement(stmts,funcs,replIn,{});
  alg := DAE.ALGORITHM_STMTS(stmts);

  algOut := DAE.ALGORITHM(alg,source);
  tplOut := (funcs,replOut);
end evaluateFunctions_updateAlgorithms;

protected function evaluateFunctions_updateStatement"
author:Waurich TUD 2014-03"
  input list<DAE.Statement> algsIn;
  input DAE.FunctionTree funcTree;
  input BackendVarTransform.VariableReplacements replIn;
  input list<DAE.Statement> lstIn;
  output list<DAE.Statement> algsOut;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  (algsOut,replOut) := matchcontinue(algsIn,funcTree,replIn,lstIn)
    local
      Boolean changed, isCon, simplified, isIf;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref;
      DAE.ElementSource source;
      DAE.Exp exp1, exp2;
      DAE.Else else_;
      DAE.Statement alg;
      DAE.Type typ;
      list<DAE.Statement> stmts1, stmts2, rest;
      list<DAE.Exp> expLst;
    case({},_,_,_)
      equation
        //stmts1 = listReverse(lstIn);
      then
        (lstIn,replIn);
    case(DAE.STMT_ASSIGN(type_=typ, exp1=exp1, exp=exp2, source=source)::rest,_,_,_)
      equation
        //print("the STMT_ASSIGN before: "+&DAEDump.ppStatementStr(List.first(algsIn)));
        cref = Expression.expCref(exp1);
        (exp2,changed) = BackendVarTransform.replaceExp(exp2,replIn,NONE());
        (exp2,changed) = Debug.bcallret1_2(changed,ExpressionSimplify.simplify,exp2,exp2,changed);
        (exp2,_) = ExpressionSimplify.simplify(exp2);
        isCon = Expression.isConst(exp2);
               
        //repl = Debug.bcallret4(isCon,BackendVarTransform.addReplacement,replIn,cref,exp2,NONE(),replIn);
        //repl = Debug.bcallret4(not isCon,BackendVarTransform.addReplacement,replIn,cref,exp2,NONE(),replIn); // add a dummy replacement(is needed if a former const array is overwritten with a variable)
        repl = BackendVarTransform.addReplacement(replIn,cref,exp2,NONE());
        //print("add the replacement: "+&ComponentReference.crefStr(cref)+&" --> "+&ExpressionDump.dumpExpStr(exp2,0)+&"\n");
        
        alg = Util.if_(isCon,DAE.STMT_ASSIGN(typ,exp1,exp2,source),List.first(algsIn));
          //print("the STMT_ASSIGN after : "+&DAEDump.ppStatementStr(alg)+&"\n");
        (rest,repl) = evaluateFunctions_updateStatement(rest,funcTree,repl,alg::lstIn);
      then
        (rest,repl);
    case (DAE.STMT_ASSIGN_ARR(type_=typ, componentRef=cref, exp=exp1, source=source)::rest,_,_,_)
      equation
          //print("STMT_ASSIGN_ARR");
          //print("the STMT_ASSIGN_ARR: "+&DAEDump.ppStatementStr(List.first(algsIn))+&"\n");
        (rest,repl) = evaluateFunctions_updateStatement(rest,funcTree,replIn,lstIn);
      then
        (rest,repl);
    case(DAE.STMT_IF(exp=exp1, statementLst=stmts1, else_=else_, source=source)::rest,_,_,_)
      equation
        // simplify the condition
        //print("the STMT_IF before: "+&DAEDump.ppStatementStr(List.first(algsIn)));
          
        ((exp1,_)) = Expression.traverseExpTopDown(exp1,evaluateConstantFunctionWrapper,(exp1,funcTree));
        (exp1,changed) = BackendVarTransform.replaceExp(exp1,replIn,NONE());
        (exp1,_) = ExpressionSimplify.simplify(exp1);
        
        //check if its the if case
        isCon = Expression.isConst(exp1);
        isIf = Debug.bcallret1(isCon,Expression.getBoolConst,exp1,false);
          //print("is it const? "+&boolString(isCon)+&" do we have to use the if: "+&boolString(isIf)+&"\n");
        
        // simplify the if statements
        (stmts1,(_,repl)) = Debug.bcallret2_2(isIf and isCon, evaluateFunctions_updateStatementLst, stmts1, (funcTree,replIn), stmts1, (funcTree,replIn));
        
        // simplify the else statements
        (stmts1,simplified) = Debug.bcallret2_2(not isIf and isCon, simplifyElse, else_, (funcTree,replIn), stmts1, false);       
          //print("is it simplified? "+&boolString(simplified)+&"\n");
        
        alg = List.first(algsIn);
        stmts1 = Util.if_(simplified and isCon, stmts1, {alg});
        
        stmts1 = listReverse(stmts1);
          //print("the STMT_IF after: "+&stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+&"\n");
                
        stmts1 = listAppend(stmts1,lstIn);        
        (rest,repl) = evaluateFunctions_updateStatement(rest,funcTree,repl,stmts1);
      then
        (rest,repl);
    case(DAE.STMT_TUPLE_ASSIGN(type_=_, expExpLst=expLst, exp=exp1, source=source)::rest,_,_,_)
      equation
        //print("the STMT_TUPLE_ASSIGN stmt: "+&DAEDump.ppStatementStr(List.first(algsIn)));
      // IMPLEMENT A PARTIAL FUNCTION EVALUATION FOR FUNCTIONS IN FUNCTIONS
      alg = List.first(algsIn);
      //print("the STMT_TUPLE_ASSIGN after: "+&DAEDump.ppStatementStr(alg));
      (rest,repl) = evaluateFunctions_updateStatement(rest,funcTree,replIn,alg::lstIn);
    then (rest,repl);
    else
      equation
          print("evaluateFunctions_updateStatement failed!\n");
      then
        fail();
  end matchcontinue;
end evaluateFunctions_updateStatement;


protected function evaluateFunctions_updateStatementLst"
author:Waurich TUD 2014-03"
  input list<DAE.Statement> stmtsIn;
  input tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements> tplIn;
  output list<DAE.Statement> stmtsOut;
  output tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements> tplOut;
protected
  BackendVarTransform.VariableReplacements repl;
  DAE.FunctionTree funcs;
algorithm
  (funcs,repl) := tplIn;
  (stmtsOut,repl) := evaluateFunctions_updateStatement(stmtsIn,funcs,repl,{});
  //(stmtsOut,(_,repl)) := List.mapFold(stmtsIn,evaluateFunctions_updateStatement,(funcs,repl));
  tplOut := (funcs,repl);
end evaluateFunctions_updateStatementLst;


protected function evaluateConstantFunctionWrapper
  input tuple<DAE.Exp,tuple<DAE.Exp, DAE.FunctionTree>> inTpl;
  output tuple<DAE.Exp, Boolean, tuple<DAE.Exp,DAE.FunctionTree>> outTpl;
protected
  DAE.Exp rhs, lhs;
  DAE.FunctionTree funcs;
algorithm
  (rhs,(lhs,funcs)) := inTpl;
  ((rhs,_,_,_)) := evaluateConstantFunction(rhs,lhs,funcs);
  outTpl := (rhs,true,(lhs,funcs));
end evaluateConstantFunctionWrapper;  


protected function simplifyElse "evaluates an else or elseIf.
author:Waurich TUD 2014-03"
  input DAE.Else elseIn;
  input tuple<DAE.FunctionTree,BackendVarTransform.VariableReplacements> inTpl;
  output list<DAE.Statement> stmtsOut;
  output Boolean simplified;
algorithm
  (stmtsOut,simplified) := matchcontinue(elseIn,inTpl)
    local
      Boolean const;
      Boolean isElseIf;
      BackendVarTransform.VariableReplacements repl;
      DAE.Else else_;
      DAE.Exp exp;
      DAE.FunctionTree funcs;
      list<DAE.Statement> stmts;
    case(DAE.NOELSE(),_)
      equation
        //print("NO ELSE\n");
       then
         ({},true);
    case(DAE.ELSEIF(exp=exp, statementLst=stmts,else_=else_),(funcs,repl))
        equation
        // simplify the condition
          //print("STMT_IF_EXP_IN_ELSEIF:\n");
          //ExpressionDump.dumpExp(exp);
        ((exp,_)) = Expression.traverseExpTopDown(exp,evaluateConstantFunctionWrapper,(exp,funcs));
        (exp,_) = BackendVarTransform.replaceExp(exp,repl,NONE());
        (exp,_) = ExpressionSimplify.simplify(exp);

          //print("STMT_IF_EXP_IN_ELSEIF SIMPLIFIED:\n");
          //ExpressionDump.dumpExp(exp);
        // check if this could be evaluated
        const = Expression.isConst(exp);
        isElseIf = Debug.bcallret1(const,Expression.getBoolConst,exp,false);
          //print("do we have to use the elseif: "+&boolString(isElseIf)+&"\n");
        (stmts,(_,_)) = Debug.bcallret2_2(const and isElseIf,evaluateFunctions_updateStatementLst,stmts,(funcs,repl),stmts,(funcs,repl));  // is this elseif case
        (stmts,_) = Debug.bcallret2_2(const and not isElseIf,simplifyElse,else_,(funcs,repl),{},false); // is the another elseif case or the else case
      then
        (stmts,false);
    case(DAE.ELSE(statementLst=stmts),(funcs,repl))
        equation
           //print("the STMT_ELSE before: "+&stringDelimitList(List.map(stmts,DAEDump.ppStatementStr),"\n")+&"\n");
         repl = BackendVarTransform.emptyReplacements();
         (stmts,(_,_)) = evaluateFunctions_updateStatementLst(stmts,(funcs,repl));  // is this elseif case
           //print("the STMT_ELSE simplified: "+&stringDelimitList(List.map(stmts,DAEDump.ppStatementStr),"\n")+&"\n");
      then
         (stmts,false);
    else
    equation
        print("simplifyElse failed\n");
      then
        fail();    
  end matchcontinue;        
end simplifyElse;

protected function getScalarsForComplexVar"gets the list<ComponentRef> for the scalar values of complex vars and multidimensional vars (at least real) .
author: Waurich TUD 2014-03"
  input DAE.Element inElem;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := matchcontinue(inElem)
    local
      list<Integer> dim;
      list<list<Integer>> ranges;
      list<DAE.Subscript> dims;
      list<list<DAE.Subscript>> subslst;
      DAE.ComponentRef cref;
      DAE.Type ty;
      DAE.Exp exp;
      list<DAE.Exp> exps;
      list<DAE.Var> varLst;
      list<DAE.ComponentRef> crefs, lastCrefs;
      list<DAE.Type> types;
      list<String> names;
    case(DAE.VAR(componentRef = cref,ty=DAE.T_COMPLEX(varLst = varLst)))
      equation
        names = List.map(varLst,DAEUtil.typeVarIdent);
        //lastCrefs = List.map(names);
        //print("the names for the scalar crefs: "+&stringDelimitList(names,"\n")+&"\n");
        types = List.map(varLst,DAEUtil.VarType);
        exp = Expression.crefExp(cref);
        //ExpressionDump.dumpExp(exp);  
        
        crefs = List.map1(names,ComponentReference.appendStringCref,cref);
        crefs = setTypesForScalarCrefs(crefs,types,{});   
        crefs = listReverse(crefs);    
      then
        crefs;
    case(DAE.VAR(componentRef=cref,ty=DAE.T_REAL(varLst=_, source=_), dims=dims ))
      equation
        dim = Expression.subscriptsInt(dims);
        Debug.bcall1(intEq(listLength(dim),2),print,"failure in getScalarsForComplexVar:the array has multiple dimensions");
        true = listLength(dim) == 1;
        dim = List.intRange(List.first(dim));
        ranges = List.map1(dim,List.fill,1);                
        subslst = List.map(ranges,BackendDAEUtil.rangesToSubscript);
        crefs = List.map1r(subslst,ComponentReference.subscriptCref,cref);
      then
        crefs;
    else
      equation
      then
        {};      
  end matchcontinue;
end getScalarsForComplexVar;

protected function isNotComplexVar"returns true if the given var is one dimensional (no array,record...).
author: Waurich TUD 2014-03"
  input DAE.Element inElem;
  output Boolean b;
algorithm
  b := matchcontinue(inElem)
    local
      list<Integer> dim;
      list<DAE.Subscript> dims;
    case(DAE.VAR(componentRef = _,ty=DAE.T_COMPLEX(varLst = _)))
      then
        false;
    case(DAE.VAR(componentRef=_,ty=DAE.T_REAL(varLst=_, source=_), dims=dims ))
      equation
        dim = Expression.subscriptsInt(dims);
        true = intNe(List.first(dim),1);
      then
        false;
    else
      equation
      then
       true;      
  end matchcontinue;
end isNotComplexVar;

protected function setTypesForScalarCrefs
  input list<DAE.ComponentRef> allCrefs;
  input list<DAE.Type> types;
  input list<DAE.ComponentRef> crefsIn;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := match(allCrefs,types,crefsIn)
    local
      Integer idx;
      DAE.ComponentRef cr1,cr2;
      DAE.Ident id;
      DAE.Type t1,t2;
      list<DAE.ComponentRef> crest,crs;
      list<DAE.Subscript> sl;
      list<DAE.Type> trest;
  case({},{},_)
    equation
      then crefsIn;    
  case(DAE.CREF_QUAL(ident=id,identType=t2,subscriptLst=sl,componentRef=cr2)::crest, t1::trest, _)
    equation
      cr1 = List.first(allCrefs);
      cr1 = ComponentReference.crefSetLastType(cr1,t1);
      crs = setTypesForScalarCrefs(crest,trest,cr1::crefsIn);
    then
      crs;
  case(DAE.CREF_IDENT(ident=id,identType=t2,subscriptLst=sl)::crest, t1::trest, _)
    equation
      cr1 = List.first(allCrefs);
      cr1 = DAE.CREF_IDENT(id,t1,sl);
      crs = setTypesForScalarCrefs(crest,trest,cr1::crefsIn);
    then
      crs;
  case(DAE.CREF_ITER(ident=id,index=idx,identType=t2,subscriptLst=sl)::crest, t1::trest, _)
    equation
      cr1 = List.first(allCrefs);
      cr1 = DAE.CREF_ITER(id,idx,t1,sl);
      crs = setTypesForScalarCrefs(crest,trest,cr1::crefsIn);
    then
      crs;
  else
    then
      fail();    
  end match;
end setTypesForScalarCrefs;

end EvaluateFunctions;