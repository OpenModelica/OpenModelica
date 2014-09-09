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

encapsulated package EvaluateFunctions
" file:        EvaluateFunctions.mo
  package:     EvaluateFunctions
  description: This package contains functions to evaluate modelica functions completely or partially"

public import Absyn;
public import BackendDAE;
public import DAE;
public import HashTable2;
public import BackendVarTransform;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import DAEDump;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;
protected import RemoveSimpleEquations;
protected import SCode;
protected import Util;


// =============================================================================
// TODO:
//
// =============================================================================
/*
- evaluation of for-loops
- evaluation of while-loops
- evaluation of xOut := funcCall1(funcCall2(xIn[1]));  with funcCall2(xIn[1]) = xIn[1,2] for example have a look at Media.Examples.ReferenceAir.MoistAir
(I think the stmt in MoistAir.setState_pTX should be a STMT_IF instead of a STMT_ASSIGN, thats why its not evaluated)
- run the msl models and check for failures in List.filter1OnTrueSync and List.filterOnTrueSync, this fails somewhere and could improve something if fixed
- evaluation of BackendDAE.ARRAY_EQUATION
*/
// =============================================================================
// type definitions
//
// =============================================================================

public uniontype FuncInfo "store global informations when traversing the statemtents and evaluate the function calls"
  record FUNCINFO
    BackendVarTransform.VariableReplacements repl;
    DAE.FunctionTree funcTree;
    Integer idx;
  end FUNCINFO;
end FuncInfo;

// =============================================================================
// evaluate functions
//
// =============================================================================

public function evalFunctions"backend optmization module to evaluate functions completely or partially.
partial constant outputs are added as extra equations. Therefore removeSimpleEquations is necessary afterwards
author:Waurich TUD 2014-04"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      Boolean changed;
      BackendDAE.EqSystems eqSysts;
      BackendDAE.Shared shared;
    case(_)
      equation
        false = Flags.isSet(Flags.EVALUATE_CONST_FUNCTIONS);
        BackendDAE.DAE(eqs = eqSysts,shared = shared) = inDAE;
        (eqSysts,(shared,_,changed)) = List.mapFold(eqSysts,evalFunctions_main,(shared,1,false));
        //shared = evaluateShared(shared);
        outDAE = Util.if_(changed,BackendDAE.DAE(eqSysts,shared),inDAE);
        outDAE = Debug.bcallret1(changed,RemoveSimpleEquations.fastAcausal,outDAE,inDAE);
        outDAE = Debug.bcallret1(changed,updateVarKinds,outDAE,inDAE);
      then
        outDAE;
    else
      then
        inDAE;
  end matchcontinue;
end evalFunctions;

protected function evaluateShared"evaluate objects in the shared structure that could be dependent of a function. i.e. parameters
author:Waurich TUD 2014-04"
  input BackendDAE.Shared sharedIn;
  output BackendDAE.Shared sharedOut;
protected
  BackendDAE.Variables knVars;
  DAE.FunctionTree funcTree;
  list<BackendDAE.Var> varLst;
algorithm
  knVars := BackendDAEUtil.getknvars(sharedIn);
  funcTree := BackendDAEUtil.getFunctions(sharedIn);
  varLst := BackendVariable.varList(knVars);
  varLst := List.map1(varLst,evaluateParameter,funcTree);
  knVars := BackendVariable.listVar(varLst);
  sharedOut := BackendDAEUtil.replaceKnownVarsInShared(sharedIn,knVars);
end evaluateShared;

protected function evaluateParameter"evaluates a parameter"
  input BackendDAE.Var varIn;
  input DAE.FunctionTree funcTree;
  output BackendDAE.Var varOut;
algorithm
  varOut := matchcontinue(varIn,funcTree)
    local
      DAE.Exp bindExp;
    case(BackendDAE.VAR(varKind=BackendDAE.PARAM()),_)
      equation
        BackendDump.printVar(varIn);
        bindExp = BackendVariable.varBindExp(varIn);
        true = Expression.isCall(bindExp);
        ExpressionDump.dumpExp(bindExp);
        ((bindExp,_,_,_,_,_)) = evaluateConstantFunction(bindExp,bindExp,funcTree,1);
        ExpressionDump.dumpExp(bindExp);
      then
        varIn;
    else
      equation
        then varIn;
  end matchcontinue;
end evaluateParameter;

protected function evalFunctions_main"traverses the eqSystems for function calls and tries to evaluate them"
  input BackendDAE.EqSystem eqSysIn;
  input tuple<BackendDAE.Shared,Integer,Boolean> tplIn;
  output BackendDAE.EqSystem eqSysOut;
  output tuple<BackendDAE.Shared,Integer,Boolean> tplOut;
protected
  Boolean changed;
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
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  (sharedIn,sysIdx,changed) := tplIn;
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqs,m=m,mT=mT,matching=matching,stateSets=stateSets,partitionKind=partitionKind) := eqSysIn;
  eqLst := BackendEquation.equationList(eqs);
  varLst := BackendVariable.varList(vars);

  //traverse the eqSystem for function calls
  (eqLst,(shared,addEqs,_,changed)) := List.mapFold(eqLst,evalFunctions_findFuncs,(sharedIn,{},1,changed));
  eqLst := listAppend(eqLst,addEqs);
  eqs := BackendEquation.listEquation(eqLst);
  eqSysOut := BackendDAE.EQSYSTEM(vars,eqs,m,mT,matching,stateSets,partitionKind);

  tplOut := (shared,sysIdx+1,changed);
end evalFunctions_main;

protected function evalFunctions_findFuncs"traverses the lhs and rhs exps of an equation and tries to evaluate function calls "
  input BackendDAE.Equation eqIn;
  input tuple<BackendDAE.Shared,list<BackendDAE.Equation>,Integer,Boolean> tplIn;
  output BackendDAE.Equation eqOut;
  output tuple<BackendDAE.Shared,list<BackendDAE.Equation>,Integer,Boolean> tplOut;
algorithm
  (eqOut,tplOut) := matchcontinue(eqIn,tplIn)
    local
      Integer sizeL,sizeR,size,idx;
      Boolean b1,b2,changed, changed1;
      BackendDAE.Equation eq;
      BackendDAE.EquationAttributes attr;
      BackendDAE.Shared shared;
      DAE.Exp exp1,exp2,lhsExp,rhsExp;
      DAE.ElementSource source;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> addEqs, addEqs1, addEqs2;
      list<DAE.Exp> lhs;
    case(BackendDAE.EQUATION(exp=exp1, scalar=exp2,source=source,attr=attr),_)
      equation
        b1 = Expression.containFunctioncall(exp1);
        b2 = Expression.containFunctioncall(exp2);
        true = b1 or b2;
        (shared,addEqs,idx,changed) = tplIn;
        funcs = BackendDAEUtil.getFunctions(shared);
        ((rhsExp,lhsExp,addEqs1,funcs,idx,changed1)) = Debug.bcallret4(b1,evaluateConstantFunction,exp1,exp2,funcs,idx,(exp2,exp1,{},funcs,idx,changed));
        changed = changed1 or changed;
        ((rhsExp,lhsExp,addEqs2,funcs,idx,changed1)) = Debug.bcallret4(b2,evaluateConstantFunction,exp2,exp1,funcs,idx,(rhsExp,lhsExp,{},funcs,idx,changed));
        changed = changed1 or changed;
        addEqs = listAppend(addEqs1,addEqs);
        addEqs = listAppend(addEqs2,addEqs);
        eq = BackendDAE.EQUATION(lhsExp,rhsExp,source,attr);
      then
        (eq,(shared,addEqs,idx+1,changed));
    case(BackendDAE.ARRAY_EQUATION(dimSize=_),_)
      equation
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"this is an array equation. update evalFunctions_findFuncs\n");
      then
        (eqIn,tplIn);
    case(BackendDAE.COMPLEX_EQUATION(left=exp1, right=exp2, source=source, attr=attr),_)
      equation
        b1 = Expression.containFunctioncall(exp1);
        b2 = Expression.containFunctioncall(exp2);
        true = b1 or b2;
        (shared,addEqs,idx,changed) = tplIn;
        funcs = BackendDAEUtil.getFunctions(shared);
        ((rhsExp,lhsExp,addEqs1,funcs,idx,changed1)) = Debug.bcallret4(b1,evaluateConstantFunction,exp1,exp2,funcs,idx,(exp2,exp1,{},funcs,idx,changed));
        changed = changed or changed1;
        ((rhsExp,lhsExp,addEqs2,funcs,idx,changed1)) = Debug.bcallret4(b2,evaluateConstantFunction,exp2,exp1,funcs,idx,(rhsExp,lhsExp,{},funcs,idx,changed));
        changed = changed or changed1;
        addEqs = listAppend(addEqs1,addEqs);
        addEqs = listAppend(addEqs2,addEqs);
        shared = BackendDAEUtil.addFunctionTree(funcs,shared);
        sizeL = getScalarExpSize(lhsExp);
        sizeR = getScalarExpSize(rhsExp);
        size = intMax(sizeR,sizeL);
        eq = Util.if_(intEq(size,0),BackendDAE.EQUATION(lhsExp,rhsExp,source,attr),BackendDAE.COMPLEX_EQUATION(size,lhsExp,rhsExp,source,attr));
        //since tuple=tuple is not supported, these equations are converted into a list of simple equations
        (eq,addEqs) = convertTupleEquations(eq,addEqs);
      then
        (eq,(shared,addEqs,idx+1,changed));
    else
      equation
      then
        (eqIn,tplIn);
  end matchcontinue;
end evalFunctions_findFuncs;

protected function evaluateConstantFunction"Analyses if the rhsExp is a function call. the constant inputs are inserted and it will be checked if the outputs can be evaluated to a constant.
If the function can be completely evaluated, the function call will be removed.
If its partially constant, the constant assignments are added as additional equations and the former function will be replaced with an updated new one.
author: Waurich TUD 2014-04"
  input DAE.Exp rhsExpIn;
  input DAE.Exp lhsExpIn;
  input DAE.FunctionTree funcsIn;
  input Integer eqIdx;
  output tuple<DAE.Exp, DAE.Exp, list<BackendDAE.Equation>, DAE.FunctionTree,Integer,Boolean> outTpl;  //rhs,lhs,addEqs,funcTre,idx
algorithm
  outTpl := matchcontinue(rhsExpIn,lhsExpIn,funcsIn,eqIdx)
    local
      Boolean funcIsConst, funcIsPartConst, isConstRec, hasAssert, hasReturn, hasTerminate, hasReinit, abort, changed;
      Integer idx;
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
      DAE.Type ty;
      list<BackendDAE.Equation> constEqs;
      list<DAE.ComponentRef> inputCrefs, outputCrefs, allInputCrefs, allOutputCrefs, constInputCrefs, constCrefs, varScalarCrefsInFunc,constComplexCrefs,varComplexCrefs,constScalarCrefs, constScalarCrefsOut,varScalarCrefs;
      list<DAE.Element> elements, algs, allInputs, protectVars, allOutputs, varOutputs;
      list<DAE.Exp> exps, inputExps, complexExp, allInputExps, constInputExps, constExps, constComplexExps, constScalarExps, lhsExps;
      list<list<DAE.Exp>> scalarExp;
      list<DAE.Statement> stmts;
      list<list<DAE.ComponentRef>> scalarInputs, scalarOutputs;
    case(DAE.CALL(path=path, expLst=exps, attr=attr1),_,_,_)
      equation
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"\nStart evaluation of:\n"+&ExpressionDump.printExpStr(lhsExpIn)+&" := "+&ExpressionDump.printExpStr(rhsExpIn)+&"\n\n");

        // get the elements of the function and the algorithms
        SOME(func) = DAEUtil.avlTreeGet(funcsIn,path);
        elements = DAEUtil.getFunctionElements(func);
        true = List.isNotEmpty(elements);
        protectVars = List.filterOnTrue(elements,DAEUtil.isProtectedVar);
        algs = List.filter(elements,DAEUtil.isAlgorithm);

        // get all input crefs and expresssions (scalar and one dimensioanl)
        allInputs = List.filter(elements,DAEUtil.isInputVar);
        scalarInputs = List.map(allInputs,expandComplexElementsToCrefs);
        allInputCrefs = List.flatten(scalarInputs);
        //print("\nallInputCrefs\n"+&stringDelimitList(List.map(allInputCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");

        scalarExp = List.map(exps,expandComplexEpressions);
        allInputExps = List.flatten(scalarExp);
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
        repl = BackendVarTransform.addReplacements(repl,constInputCrefs,constInputExps,NONE());
        //repl = BackendVarTransform.addReplacements(repl,allInputCrefs,allInputExps,NONE());
         //BackendVarTransform.dumpReplacements(repl);

        // recognize if there are statements we cannot evaluate at the moment
        hasAssert = List.fold(algs,hasAssertFold,false);
        hasReturn = List.fold(algs,hasReturnFold,false);
        hasTerminate = List.fold(algs,hasReturnFold,false);
        hasReinit = List.fold(algs,hasReinitFold,false);
        abort = hasReturn or hasTerminate or hasReinit;

        // go through all algorithms and replace the variables with constants if possible, extend the ht after each algorithm
        (algs,(funcs,repl,idx)) = List.mapFold(algs,evaluateFunctions_updateAlgorithms,(funcsIn,repl,eqIdx));
          //print("\nall algs after"+&intString(listLength(algs))+&"\n"+&DAEDump.dumpElementsStr(algs)+&"\n");
          //BackendVarTransform.dumpReplacements(repl);

        //get all replacements in order to check for constant outputs
        (constCrefs,constExps) = BackendVarTransform.getAllReplacements(repl);
        (constCrefs,constExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,allOutputCrefs,constExps); // extract outputs
        (constExps,constCrefs) = List.filterOnTrueSync(constExps,Expression.isConst,constCrefs); // extract constant outputs

        //print("all constant crefs \n"+&stringDelimitList(List.map(constCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("all constant exps:\n"+&ExpressionDump.printExpListStr(constExps)+&"\n");

        // get the completely constant complex outputs, the constant parts of complex outputs and the variable parts of complex outputs and the expressions
        (constComplexCrefs,varComplexCrefs,constScalarCrefs,varScalarCrefs) = checkIfOutputIsEvaluatedConstant(allOutputs,constCrefs,{},{},{},{});
        (constScalarCrefs,constScalarExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constScalarCrefs,constExps);
        (constComplexCrefs,constComplexExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constComplexCrefs,constExps);

        //print("constComplexCrefs\n"+&stringDelimitList(List.map(constComplexCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("varComplexCrefs\n"+&stringDelimitList(List.map(varComplexCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("constScalarCrefs 1\n"+&stringDelimitList(List.map(constScalarCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("varScalarCrefs 1\n"+&stringDelimitList(List.map(varScalarCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");

        // is it completely constant or partially?
        funcIsConst = List.isEmpty(varScalarCrefs) and List.isNotEmpty(varComplexCrefs);
        funcIsPartConst = (List.isNotEmpty(varScalarCrefs) or List.isNotEmpty(varComplexCrefs)) and (List.isNotEmpty(constScalarCrefs) or List.isNotEmpty(constComplexCrefs)) and not funcIsConst;
        isConstRec = intEq(listLength(constScalarCrefs),listLength(List.flatten(scalarOutputs))) and List.isEmpty(varScalarCrefs) and listEmpty(varComplexCrefs) and listEmpty(constComplexCrefs);

        //Debug.bcall1(isConstRec,print,"the function output is completely constant and its a record\n");
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and funcIsConst,print,"the function output is completely constant\n");
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and funcIsPartConst,print,"the function output is partially constant\n");
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and not funcIsPartConst and not funcIsConst,print,"the function output is not constant in any case\n");
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and hasAssert and funcIsConst,print,"the function output is completely constant but there is an assert\n");
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and abort,print,"the evaluated function is not used because there is a return or a terminate or a reinit statement\n");
        funcIsConst = Util.if_((hasAssert and funcIsConst) or abort,false,funcIsConst); // quit if there is a return or terminate or use partial evaluation if there is an assert
        funcIsPartConst = Util.if_(hasAssert and funcIsConst,true,funcIsPartConst);
        funcIsPartConst = Util.if_(abort,false,funcIsPartConst);  // quit if there is a return or terminate

        true =  funcIsPartConst or funcIsConst;
        changed = funcIsPartConst or funcIsConst;
        // build the new lhs, the new statements for the function, the constant parts...
        (varOutputs,outputExp,varScalarCrefsInFunc) = buildVariableFunctionParts(scalarOutputs,constComplexCrefs,varComplexCrefs,constScalarCrefs,varScalarCrefs,allOutputs,lhsExpIn);
        (constScalarCrefsOut,constComplexCrefs) = buildConstFunctionCrefs(constScalarCrefs,constComplexCrefs,allOutputCrefs,lhsExpIn);
        (algs,constEqs) = Debug.bcallret3_2(not funcIsConst,buildPartialFunction,(varScalarCrefsInFunc,algs),(constScalarCrefs,constScalarExps,constComplexCrefs,constComplexExps,constScalarCrefsOut),repl,algs,{});

        //print("constScalarCrefsOut\n"+&stringDelimitList(List.map(constScalarCrefsOut,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("constComplexCrefs\n"+&stringDelimitList(List.map(constComplexCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");

        // build the new partial function
        elements = listAppend(allInputs,varOutputs);
        elements = listAppend(elements,protectVars);
        elements = listAppend(elements,algs);
        elements = List.unique(elements);
        (func,path) = updateFunctionBody(func,elements,idx, varOutputs, allOutputs);
        funcs = Debug.bcallret2(funcIsPartConst,DAEUtil.addDaeFunction,{func},funcs,funcs);
        idx = Util.if_(funcIsPartConst or funcIsConst,idx+1,idx);

        //decide which lhs to take (tuple or 1d)
        outputExp = Util.if_(funcIsPartConst,outputExp,lhsExpIn);
        lhsExps = getCrefsForRecord(lhsExpIn);
        outputExp = Util.if_(isConstRec,DAE.TUPLE(lhsExps),outputExp);
        // which rhs
        attr2 = DAEUtil.replaceCallAttrType(attr1,DAE.T_TUPLE({},DAE.emptyTypeSource));
        attr2 = Util.if_(intEq(listLength(varOutputs),1),attr1,attr2);
        //DAEDump.dumpCallAttr(attr2);
        exp2 = Debug.bcallret1(List.hasOneElement(constComplexExps) and funcIsConst,List.first,constComplexExps,DAE.TUPLE(constComplexExps));  // either a single equation or a tuple equation
        exp = Util.if_(funcIsConst,exp2,rhsExpIn);
        exp = Util.if_(funcIsPartConst,DAE.CALL(path, exps, attr2),exp);
        exp = Util.if_(isConstRec,DAE.TUPLE(constScalarExps),exp);

        //BackendDump.dumpEquationList(constEqs,"the additional equations\n");
        //print("LHS EXP:\n");
        //ExpressionDump.dumpExp(outputExp);
        outputExp = setRecordTypes(outputExp,FUNCINFO(repl,funcs,idx));
        //print("RHS EXP:\n");
        //ExpressionDump.dumpExp(exp);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"Finish evaluation in:\n"+&ExpressionDump.printExpStr(outputExp)+&" := "+&ExpressionDump.printExpStr(exp)+&"\n");
          Debug.bcall2(Flags.isSet(Flags.EVAL_FUNC_DUMP) and List.isNotEmpty(constEqs),BackendDump.dumpEquationList,constEqs,"including the additional equations:\n");
      then
        ((exp,outputExp,constEqs,funcs,idx,changed));
    else
      equation
      then
        ((rhsExpIn,lhsExpIn,{},funcsIn,eqIdx,false));
  end matchcontinue;
end evaluateConstantFunction;

protected function expandComplexEpressions"gets the complex contents or if its not complex, then the exp itself
author:Waurich TUD 2014-05"
  input DAE.Exp e;
  output list<DAE.Exp> eLst;
algorithm
  eLst := matchcontinue(e)
    local
      list<DAE.Exp> lst;
    case(_)
      equation
        lst = Expression.getComplexContents(e);
        true = List.isNotEmpty(lst);
      then
        lst;
    else
      then {e};
  end matchcontinue;
end expandComplexEpressions;

protected function expandComplexElementsToCrefs"gets the complex contents or if its not complex, then the element itself and converts them to crefs.
author:Waurich TUD 2014-05"
  input DAE.Element e;
  output list<DAE.ComponentRef> eLst;
algorithm
  eLst := matchcontinue(e)
    local
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> lst;
    case(_)
      equation
        false = isNotComplexVar(e);
        lst = getScalarsForComplexVar(e);
      then
        lst;
    else
      equation
        cref = DAEUtil.varCref(e);
      then {cref};
  end matchcontinue;
end expandComplexElementsToCrefs;

protected function hasAssertFold"fold function to check if a list of stmts has an assert.
author:Waurich TUD 2014-04"
  input DAE.Element stmt;
  input Boolean bIn;
  output Boolean bOut;
protected
  list<Boolean> bLst;
  list<DAE.Statement> stmtLst;
algorithm
  stmtLst := DAEUtil.getStatement(stmt);
  bLst := List.map(stmtLst,DAEUtil.isStmtAssert);
  bOut := List.fold(bLst,boolOr,bIn);
end hasAssertFold;

protected function hasReturnFold"fold function to check if a list of stmts has an return stmt.
author:Waurich TUD 2014-04"
  input DAE.Element stmt;
  input Boolean bIn;
  output Boolean bOut;
protected
  list<Boolean> bLst;
  list<DAE.Statement> stmtLst;
algorithm
  stmtLst := DAEUtil.getStatement(stmt);
  bLst := List.map(stmtLst,DAEUtil.isStmtReturn);
  bOut := List.fold(bLst,boolOr,bIn);
end hasReturnFold;

protected function hasReinitFold "fold function to check if a list of stmts has an reinit stmt.
author:Waurich TUD 2014-04"
  input DAE.Element stmt;
  input Boolean bIn;
  output Boolean bOut;
protected
  list<Boolean> bLst;
  list<DAE.Statement> stmtLst;
algorithm
  stmtLst := DAEUtil.getStatement(stmt);
  bLst := List.map(stmtLst,DAEUtil.isStmtReturn);
  bOut := List.fold(bLst,boolOr,bIn);
end hasReinitFold;

protected function hasTerminateFold"fold function to check if a list of stmts has an terminate stmt.
author:Waurich TUD 2014-04"
  input DAE.Element stmt;
  input Boolean bIn;
  output Boolean bOut;
protected
  list<Boolean> bLst;
  list<DAE.Statement> stmtLst;
algorithm
  stmtLst := DAEUtil.getStatement(stmt);
  bLst := List.map(stmtLst,DAEUtil.isStmtTerminate);
  bOut := List.fold(bLst,boolOr,bIn);
end hasTerminateFold;

protected function setRecordTypes"This is somehow a hack for FourBitBinaryAdder because there are function calls in the daelow on the lhs of a function call and this leads to an error in simcode creation
they are used a s a cast for record types, but they should be a cast instead of a call, aren't they?
 func1(x) = func2(y).
 this function removes the call and sets the type
 author:Waurich TUD 2014-04"
  input DAE.Exp inExp;
  input FuncInfo info;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp,info)
    local
      Integer idx;
      DAE.CallAttributes attr;
      DAE.ComponentRef cref;
      DAE.Exp exp1;
      list<DAE.Exp> expLst;
      DAE.FunctionTree funcTree;
      DAE.Type ty;
      BackendVarTransform.VariableReplacements repl;
    case(DAE.CALL(path=_,expLst=expLst,attr= attr as DAE.CALL_ATTR(ty=ty,tuple_=_,builtin=_,isImpure=_,inlineType=_,tailCall=_)),FUNCINFO(repl=repl,funcTree=funcTree,idx=idx))
      equation
        true = Expression.isCall(inExp);
        true = listLength(expLst) == 1;
        exp1 = List.first(expLst);
        cref = Expression.expCref(exp1);
        exp1 = Expression.makeCrefExp(cref,ty);
      then exp1;
    else
      then inExp;
  end matchcontinue;
end setRecordTypes;

public function getCrefsForRecord"get all crefs of a record exp
author:Waurich TUD 2014-04"
  input DAE.Exp e;
  output list<DAE.Exp> es;
algorithm
  es := match(e)
    local
      DAE.ComponentRef cref;
      DAE.Exp exp;
      list<DAE.Exp> expLst;
      list<DAE.ComponentRef> crefs;
    case(DAE.CREF(componentRef = cref,ty=_))
      equation
        crefs = ComponentReference.expandCref(cref,true);
        expLst = List.map(crefs,Expression.crefExp);
      then
        expLst;
    else
    equation
    then
      {};
  end match;
end getCrefsForRecord;

protected function scalarRecExpForOneDimRec"if the record contains only 1 scalar value, replace the scalar type definition with the record definition.
author:Waurich TUD 2014-04"
  input DAE.Exp expIn;
  output DAE.Exp expOut;
algorithm
  expOut := matchcontinue(expIn)
    local
      Absyn.Path path;
      DAE.Exp exp;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs;
      DAE.Type ty;
      list<DAE.Var> varLst;
    case(DAE.CREF(componentRef=cref,ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path=path),varLst=varLst,equalityConstraint=_,source=_)))
      equation
        true = listLength(varLst)==1;
        DAE.CREF(componentRef=cref,ty=ty) = expIn;
        crefs = getRecordScalars(cref);
        true = listLength(crefs)==1;
        cref = List.first(crefs);
        exp = Expression.crefExp(cref);
      then exp;
    else
      equation
      then expIn;
  end matchcontinue;
end scalarRecExpForOneDimRec;

protected function scalarRecCrefsForOneDimRec"replace a 1 dimensional record through its scalar value
author:Waurich TUD 2014-04"
  input DAE.ComponentRef crefIn;
  output DAE.ComponentRef crefOut;
algorithm
  crefOut := matchcontinue(crefIn)
    local
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs;
    case(_)
      equation
        crefs = getRecordScalars(crefIn);
        true = listLength(crefs)==1;
        cref = List.first(crefs);
      then cref;
    else
      then crefIn;
  end matchcontinue;
end scalarRecCrefsForOneDimRec;

protected function buildVariableFunctionParts "builds the output elements of the new function, the output expression for the new function call (lhs-exp)
and the crefs of the variable outputs of the new function
author: Waurich TUD 2014-04"
  input list<list<DAE.ComponentRef>> scalarOutputs;  //crefs for  all scalar function output elements
  input list<DAE.ComponentRef> constComplexCrefs;
  input list<DAE.ComponentRef> varComplexCrefs;
  input list<DAE.ComponentRef> constScalarCrefs;
  input list<DAE.ComponentRef> varScalarCrefs;
  input list<DAE.Element> allOutputs; // the complex (or 1-dimensional) output elements
  input DAE.Exp lhsExpIn; // the output expression
  output list<DAE.Element> varOutputs; // the protected and output variable elements of the function body
  output DAE.Exp outputExpOut;  // the outputs(lhs) of the function call
  output list<DAE.ComponentRef> varScalarCrefsInFunc;  // these crefs have to be updated (makeIdentCref) in the function algorithms
protected
  list<Integer> pos;
  DAE.ComponentRef lhsCref;
  DAE.Exp outputExp,exp1,exp2;
  list<DAE.ComponentRef> varScalarCrefs1, outputCrefs, outputSCrefs, allOutputCrefs, allOutputCrefs2, protCrefs, protSCrefs;
  list<DAE.Element> funcOutputs,funcProts,funcSOutputs,funcSProts;
  list<DAE.Exp> expLst, varScalarExps;
algorithm
  (varOutputs,outputExpOut,varScalarCrefsInFunc) := matchcontinue(scalarOutputs,constComplexCrefs,varComplexCrefs,constScalarCrefs,varScalarCrefs,allOutputs,lhsExpIn)
    case(_,_,_,{},{},_,DAE.TUPLE(PR=expLst))
      equation
        // only 1d or complex outputs in a tuple exp
        varScalarCrefsInFunc = {};
        allOutputCrefs = List.map(allOutputs,DAEUtil.varCref);
        (protCrefs,_,outputCrefs) = List.intersection1OnTrue(constComplexCrefs,allOutputCrefs,ComponentReference.crefEqual);
        pos = List.map1(outputCrefs,List.position,allOutputCrefs);
        pos = List.map1(pos,intAdd,1);
        varScalarExps = List.map1(pos,List.getIndexFirst,expLst);
        outputExp = Debug.bcallret1(List.hasOneElement(varScalarExps),List.first,varScalarExps,DAE.TUPLE(varScalarExps));
        funcOutputs = List.map2(outputCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcProts = List.map2(protCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        varOutputs = listAppend(funcOutputs,funcProts);
      then (varOutputs,outputExp,varScalarCrefsInFunc);
    case(_,_,_,_,_,_,DAE.LBINARY(exp1=exp1,operator=_,exp2=exp2))
      equation
      then
        ({},lhsExpIn,{});
    case(_,_,_,_,_,_,DAE.TUPLE(PR=expLst))
      equation
        // a tuple including variable and constant parts
        // the protected and output variables of the function
        allOutputCrefs = List.map(allOutputs,DAEUtil.varCref);

        //1d records are replaced by their scalar value
        allOutputCrefs2 = List.map(allOutputCrefs,scalarRecCrefsForOneDimRec);
        (_,_,varScalarCrefsInFunc) = List.intersection1OnTrue(allOutputCrefs,allOutputCrefs2,ComponentReference.crefEqual);
        allOutputCrefs = allOutputCrefs2;
        //print("\n allOutputCrefs \n"+&stringDelimitList(List.map(allOutputCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("\n varScalarCrefsInFunc \n"+&stringDelimitList(List.map(varScalarCrefsInFunc,ComponentReference.printComponentRefStr),"\n")+&"\n");

        (protCrefs,_,outputCrefs) = List.intersection1OnTrue(listAppend(constComplexCrefs,constScalarCrefs),allOutputCrefs,ComponentReference.crefEqual);
        funcOutputs = List.map2(outputCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcProts = List.map2(protCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        varOutputs = listAppend(funcOutputs,funcProts);

        //the lhs-exp of the evaluated function call
        pos = List.map1(outputCrefs,List.position,allOutputCrefs);
        pos = List.map1(pos,intAdd,1);
        varScalarExps = List.map1(pos,List.getIndexFirst,expLst);
        varScalarExps = List.map(varScalarExps,scalarRecExpForOneDimRec);
        outputExp = Debug.bcallret1(List.hasOneElement(varScalarExps),List.first,varScalarExps,DAE.TUPLE(varScalarExps));
      then (varOutputs,outputExp,varScalarCrefsInFunc);
    case(_,_,_,_,_,_,DAE.LBINARY(exp1=exp1,operator=_,exp2=exp2))
      equation
      then
        ({},lhsExpIn,{});
    case(_,_,_,_,_,_,DAE.TUPLE(PR=expLst))
      equation
        true = List.isEmpty(List.flatten(scalarOutputs));
        true = not List.isEmpty(constScalarCrefs);
        varScalarCrefsInFunc = {};
        allOutputCrefs = List.map(allOutputs,DAEUtil.varCref);
        (protCrefs,_,outputCrefs) = List.intersection1OnTrue(constScalarCrefs,allOutputCrefs,ComponentReference.crefEqual);
        pos = List.map1(outputCrefs,List.position,allOutputCrefs);
        pos = List.map1(pos,intAdd,1);
        varScalarExps = List.map1(pos,List.getIndexFirst,expLst);
        outputExp = Debug.bcallret1(List.hasOneElement(varScalarExps),List.first,varScalarExps,DAE.TUPLE(varScalarExps));
        funcOutputs = List.map2(outputCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcProts = List.map2(protCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        varOutputs = listAppend(funcOutputs,funcProts);
      then (varOutputs,outputExp,varScalarCrefsInFunc);
    case(_,_,_,_,_,_,DAE.LBINARY(exp1=exp1,operator=_,exp2=exp2))
      equation
      then
        ({},lhsExpIn,{});
    case(_,{},{},_,{},_,_)
      equation
        // only constant scalarOutputs
        lhsCref = Expression.expCref(lhsExpIn);
        outputCrefs = List.map(constScalarCrefs,ComponentReference.crefStripFirstIdent);
        outputCrefs = List.map1(outputCrefs,ComponentReference.joinCrefsR,lhsCref);
        expLst = List.map(outputCrefs,Expression.crefExp);
        outputExp = DAE.TUPLE(expLst);
      then
        ({},outputExp,{});
   case(_,_,_,_,_,_,_)
      equation
        lhsCref = Expression.expCref(lhsExpIn);
        allOutputCrefs = List.map(allOutputs,DAEUtil.varCref);
        funcOutputs = List.map2(varComplexCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcProts = List.map2(constComplexCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        funcSOutputs = List.map2(varScalarCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcSProts = List.map2(constScalarCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        funcProts = listAppend(funcProts,funcSProts);
        funcOutputs = listAppend(funcOutputs,funcSOutputs);
        varOutputs =  listAppend(funcOutputs,funcProts);
        //varOutputs = List.map2(varScalarCrefs,generateOutputElements,allOutputs,lhsExpIn);
        varScalarCrefs1 = List.map(varScalarCrefs,ComponentReference.crefStripFirstIdent);
        varScalarCrefs1 = List.map1(varScalarCrefs1,ComponentReference.joinCrefsR,lhsCref);
        varScalarExps = List.map(varScalarCrefs1,Expression.crefExp);
        outputExp = Debug.bcallret1(List.hasOneElement(varScalarExps),List.first,varScalarExps,DAE.TUPLE(varScalarExps));
      then
        (varOutputs,outputExp,varScalarCrefs);
    else
      equation
        print("buildVariableFunctionParts failed!\n");
        print("\n scalarOutputs \n"+&stringDelimitList(List.map(List.flatten(scalarOutputs),ComponentReference.printComponentRefStr),"\n")+&"\n");
        print("\n constScalarCrefs \n"+&stringDelimitList(List.map(constScalarCrefs,ComponentReference.printComponentRefStr),"\n")+&"\n");
        print("\n allOutputs "+&"\n"+&DAEDump.dumpElementsStr(allOutputs)+&"\n");
        print("\n lhsExpIn "+&"\n"+&ExpressionDump.dumpExpStr(lhsExpIn,0)+&"\n");
      then
        fail();
  end matchcontinue;
end buildVariableFunctionParts;

protected function buildConstFunctionCrefs  // builds the new crefs (for example the scalars from a record) for the constant functino outputs
  input list<DAE.ComponentRef> constScalarCrefs;
  input list<DAE.ComponentRef> constComplCrefs;
  input list<DAE.ComponentRef> allOutputCrefs;
  input DAE.Exp lhsExpIn;
  output list<DAE.ComponentRef> constScalarCrefsOut;
  output list<DAE.ComponentRef> constComplCrefsOut;
algorithm
  (constScalarCrefsOut,constComplCrefsOut) := matchcontinue(constScalarCrefs,constComplCrefs,allOutputCrefs,lhsExpIn)
    local
      list<Integer> pos;
      DAE.ComponentRef lhsCref;
      list<DAE.Exp> expLst, constExps;
      list<DAE.ComponentRef> constCrefs;
    case(_,{},_,_)
      equation
        lhsCref = Expression.expCref(lhsExpIn);
        constCrefs = List.map(constScalarCrefs,ComponentReference.crefStripFirstIdent);
        constCrefs = List.map1(constCrefs,ComponentReference.joinCrefsR,lhsCref);
     then
       (constCrefs,{});
    case({},_,_,DAE.TUPLE(PR=expLst))
      equation
        // tuple equation with only 1d or completely complex outputs
       pos = List.map1(constComplCrefs,List.position,allOutputCrefs);
       pos = List.map1(pos,intAdd,1);
       constExps = List.map1(pos,List.getIndexFirst,expLst);
       constCrefs = List.map(constExps,Expression.expCref);
       then
         ({},constCrefs);
    case(_,_,_,_)
      equation
     then
       (constScalarCrefs,constComplCrefs);
  end matchcontinue;
end buildConstFunctionCrefs;

protected function checkIfOutputIsEvaluatedConstant
  input list<DAE.Element> elements;  // check this var
  input list<DAE.ComponentRef> constCrefs;
  input list<DAE.ComponentRef> constComplexLstIn; // completely constant complex or 1d vars
  input list<DAE.ComponentRef> varComplexLstIn; // variable complex or 1d vars
  input list<DAE.ComponentRef> constScalarLstIn; // partially constant complex var parts
  input list<DAE.ComponentRef> varScalarLstIn; // the variable part of the complex var
  output list<DAE.ComponentRef> constComplexLstOut;
  output list<DAE.ComponentRef> varComplexLstOut;
  output list<DAE.ComponentRef> constScalarLstOut;
  output list<DAE.ComponentRef> varScalarLstOut;
algorithm
  (constComplexLstOut,varComplexLstOut,constScalarLstOut,varScalarLstOut) := matchcontinue(elements,constCrefs,constComplexLstIn,varComplexLstIn,constScalarLstIn,varScalarLstIn)
    local
      Boolean const;
      DAE.ComponentRef cref,constCref;
      DAE.Element elem;
      list<DAE.ComponentRef> scalars, constVars, varVars, partConstCrefs, varCrefs;
      list<DAE.Element> rest;
      list<DAE.ComponentRef> constCompl, varCompl, varScalar, constScalar, constScalarCrefs;
    case({},_,_,_,_,_)
      equation
        then(constComplexLstIn,varComplexLstIn,constScalarLstIn,varScalarLstIn);
    case(elem::rest,_,_,_,_,_)
      equation
        cref = DAEUtil.varCref(elem);
        scalars = getScalarsForComplexVar(elem);
        // function outputs a record, its either constCompl or constScalar and varScalar
        //print("the cref\n"+&stringDelimitList(List.map({cref},ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("scalars to check\n"+&stringDelimitList(List.map(scalars,ComponentReference.printComponentRefStr),"\n")+&"\n");

        true = List.isNotEmpty(scalars);
        (constVars,_,_) = List.intersection1OnTrue(scalars,constCrefs,ComponentReference.crefEqual);
        //print("constVars\n"+&stringDelimitList(List.map(constVars,ComponentReference.printComponentRefStr),"\n")+&"\n");

        const = intEq(listLength(scalars),listLength(constVars));
        constScalarCrefs = List.filter1OnTrue(constCrefs,ComponentReference.crefInLst,constVars);
        (_,varCrefs,_) = List.intersection1OnTrue(scalars,constScalarCrefs,ComponentReference.crefEqual);
        //constCompl = Util.if_(const,cref::constComplexLstIn,constComplexLstIn);
        constCompl = Util.if_(false,cref::constComplexLstIn,constComplexLstIn);
        //varCompl = Util.if_(not const,cref::varComplexLstIn,varComplexLstIn);
        varCompl = varComplexLstIn;
        //constScalar = Util.if_(not const,listAppend(constScalarCrefs,constScalarLstIn),constScalarLstIn);
        constScalar = Util.if_(true,listAppend(constScalarCrefs,constScalarLstIn),constScalarLstIn);

        varScalar = Util.if_(not const,listAppend(varCrefs,varScalarLstIn),varScalarLstIn);
        (constCompl,varCompl,constScalar,varScalar) = checkIfOutputIsEvaluatedConstant(rest,constCrefs,constCompl,varCompl,constScalar,varScalar);
      then
        (constCompl,varCompl,constScalar,varScalar);
    case(elem::rest,_,_,_,_,_)
      equation
        cref = DAEUtil.varCref(elem);
        scalars = getScalarsForComplexVar(elem);
        // function output is one dimensional
        true = List.isEmpty(scalars);
        const = listMember(cref,constCrefs);
        constCompl = Util.if_(const,cref::constComplexLstIn,constComplexLstIn);
        varCompl = Util.if_(not const,cref::varComplexLstIn,varComplexLstIn);
        (constCompl,varCompl,constScalar,varScalar) = checkIfOutputIsEvaluatedConstant(rest,constCrefs,constCompl,varCompl,constScalarLstIn,varScalarLstIn);
      then
        (constCompl,varCompl,constScalar,varScalar);
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
      list<DAE.ComponentRef> crefs;
      list<DAE.Element> oldOutputs2;
      list<DAE.Subscript> sl;
    case(DAE.CREF_QUAL(ident=_,identType=_,subscriptLst=sl,componentRef=_),_,_)
      equation
        //print("generate output element\n");
        typ = ComponentReference.crefLastType(cref);
        cref1 = ComponentReference.crefStripLastIdent(cref);

        // if the record is only 1-dimensional, use the scalar value
        crefs = getRecordScalars(cref);
        cref1 = Debug.bcallret1(intEq(listLength(crefs),1),List.first,crefs,cref1);

        // its not possible to use qualified output crefs
        i1 = ComponentReference.crefFirstIdent(cref);
        i2 = ComponentReference.crefLastIdent(cref);
        //print("the idents_ "+&i1+&"  and  "+&i2+&"\n");
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
    case(DAE.CREF_IDENT(ident=_,identType=typ,subscriptLst=_),_,_)
      equation
        var = List.first(inFuncOutputs);
        var = DAEUtil.replaceCrefandTypeInVar(cref,typ,var);
      then
        var;
    else
      equation
        print("generateOutputElements failed!\n");
      then fail();
  end match;
end generateOutputElements;

protected function generateProtectedElements "generates a protected variable for the new function
author:Waurich TUD 2014-03"
  input DAE.ComponentRef cref;
  input list<DAE.Element> inFuncOutputs;
  input DAE.Exp recId;
  output DAE.Element newProts;
algorithm
  newProts := match(cref,inFuncOutputs,recId)
    local
      DAE.ComponentRef cref1;
      DAE.Ident i1,i2;
      DAE.Element var;
      DAE.Exp exp;
      DAE.Type typ;
      list<DAE.Element> oldOutputs2;
      list<DAE.Subscript> sl;
    case(DAE.CREF_QUAL(ident=_,identType=_,subscriptLst=sl,componentRef=_),_,_)
      equation
        typ = ComponentReference.crefLastType(cref);
        _ = Expression.crefExp(cref);
        i1 = ComponentReference.crefFirstIdent(cref);
        i2 = ComponentReference.crefLastIdent(cref);
        i1 = i1+&"_"+&i2;
        cref1 = ComponentReference.makeCrefIdent(i1,typ,sl);
        var = List.first(inFuncOutputs);
        var = DAEUtil.replaceCrefandTypeInVar(cref1,typ,var);
        var = DAEUtil.setElementVarVisibility(var,DAE.PROTECTED());
        var = DAEUtil.setElementVarDirection(var,DAE.BIDIR());
      then
        var;
    case(DAE.CREF_IDENT(ident=_,identType=typ,subscriptLst=_),_,_)
      equation
        var = List.first(inFuncOutputs);
        var = DAEUtil.replaceCrefandTypeInVar(cref,typ,var);
        var = DAEUtil.setElementVarVisibility(var,DAE.PROTECTED());
        var = DAEUtil.setElementVarDirection(var,DAE.BIDIR());
      then
        var;
    else
      equation
        print("generateProtectedElements failed!\n");
      then fail();
  end match;
end generateProtectedElements;

protected function updateFunctionBody"udpates the function with the new elementsm update the type and create a new path name.
author:Waurich TUD 2014-04"
  input DAE.Function funcIn;
  input list<DAE.Element> body;
  input Integer idx;
  input list<DAE.Element> outputs;
  input list<DAE.Element> origOutputs;
  output DAE.Function funcOut;
  output Absyn.Path pathOut;
algorithm
  (funcOut,pathOut) := match(funcIn, body, idx, outputs, origOutputs)
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
    case(DAE.FUNCTION(path=path,functions=_,type_=typ,partialPrefix=pP,isImpure=iI,inlineType=iType,source=source,comment=comment),_,_,_,_)
      equation
        //print("the pathname before: "+&Absyn.pathString(path)+&"\n");
        //print("THE FUNCTION BEFORE \n"+&DAEDump.dumpFunctionStr(funcIn)+&"\n");
        // assemble the path-name
        s = Absyn.pathString(path);
        chars = stringListStringChar(s);
        chars = List.delete(chars, 1);
        s = stringCharListString(chars);
        path = Absyn.stringPath(s+&"_eval"+&intString(idx));
        // update the type
        //print("the old type: "+&Types.unparseType(typ)+&"\n");
        typ = updateFunctionType(typ,outputs,origOutputs);
        //print("the new type: "+&Types.unparseType(typ)+&"\n");
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

protected function updateFunctionType"sets the resultTypes in the functionType
author:Waurich TUD 2014-05"
  input DAE.Type typIn;
  input list<DAE.Element> outputs;  // the new outputs of the function
  input list<DAE.Element> originOutputs; // the original outputs of the function
  output DAE.Type typOut;
algorithm
  typOut := matchcontinue(typIn,outputs,originOutputs)
    local
      DAE.FunctionAttributes atts;
      DAE.TypeSource source;
      DAE.Type outType;
      list<DAE.Type> outTypeLst;
      list<DAE.FuncArg> inputs;
  case(DAE.T_FUNCTION(funcArg = inputs, funcResultType = outType, functionAttributes = atts, source = source),_,_)
    equation
      //print("the out types1: "+&Types.unparseType(outType)+&"\n");
      outTypeLst = List.map(outputs,DAEUtil.getVariableType);
      outType = Debug.bcallret1(intEq(listLength(outTypeLst),1),List.first,outTypeLst,DAE.T_TUPLE(outTypeLst,DAE.emptyTypeSource));
      outType = DAE.T_FUNCTION(inputs,outType,atts,source);
      //print("the out types2: "+&Types.unparseType(outType)+&"\n");
    then
      outType;
  else
    then typIn;
  end matchcontinue;
end updateFunctionType;

protected function buildPartialFunction "build a partial function for the variable outputs of a complex function and generate some simple equations for the constant outputs.
author:Waurich TUD 2014-03"
  input tuple<list<DAE.ComponentRef>,list<DAE.Element>> varPart;
  input tuple<list<DAE.ComponentRef>,list<DAE.Exp>,list<DAE.ComponentRef>,list<DAE.Exp>,list<DAE.ComponentRef>> constPart;
  input BackendVarTransform.VariableReplacements replIn;
  output list<DAE.Element> algsOut;
  output list<BackendDAE.Equation> eqsOut;
protected
  BackendDAE.Equation eqs;
  list<DAE.ComponentRef> constScalarCrefs ,varScalarCrefs, constComplCrefs, constScalarCrefsOut;
  DAE.Exp funcIn;
  list<DAE.Element> funcAlgs;
  list<DAE.Exp> constComplExps, constScalarExps, lhsExps1, lhsExps2;
  list<list<DAE.Exp>> lhsLst;
  list<DAE.Statement> stmts1;
algorithm
  (varScalarCrefs,funcAlgs) := varPart;
  (constScalarCrefs,constScalarExps,constComplCrefs,constComplExps,constScalarCrefsOut) := constPart;

  // generate the additional equations for the constant scalar values and the constant complex ones
  lhsExps1 := List.map(constScalarCrefsOut,Expression.crefExp);
  lhsExps2 := List.map(constComplCrefs,Expression.crefExp);
  eqsOut := generateConstEqs(lhsExps1,constScalarExps,{});
  eqsOut := generateConstEqs(lhsExps2,constComplExps,eqsOut);

  // build the partial function algorithm, replace the qualified crefs
  stmts1 := List.mapFlat(funcAlgs, DAEUtil.getStatement);
  //stmts1 := listReverse(stmts1);
  //stmts1 := List.filterOnTrue(stmts1,statementRHSIsNotConst);
  // remove the constant values
  //stmts1 := traverseStmtsAndUpdate(stmts1,stmtCanBeRemoved,replIn,{});
    stmts1 := listReverse(stmts1);

  // build new crefs for the scalars
  (stmts1,_) := DAEUtil.traverseDAEEquationsStmts(stmts1,Expression.traverseSubexpressionsHelper,(makeIdentCref,varScalarCrefs));
  (stmts1,_) := DAEUtil.traverseDAEEquationsStmts(stmts1,Expression.traverseSubexpressionsHelper,(makeIdentCref,constScalarCrefs));
  algsOut := {DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts1),DAE.emptyElementSource)};
end buildPartialFunction;

protected function stmtCanBeRemoved "function to be used in traverseStmtsAndUpdate in order
to detect the equations with a constant lhs and constant rhs so that they can be removed.
author:Waurich TUD 2014-04"
  input DAE.Statement stmtIn;
  input BackendVarTransform.VariableReplacements repl;
  output tuple<DAE.Statement,Boolean> tplOut;
replaceable type Type_a subtypeof Any;
algorithm
  tplOut := matchcontinue(stmtIn,repl)
    local
      Boolean b1,b2;
      DAE.Exp e1, e2;
      DAE.Statement stmt;
    case(DAE.STMT_ASSIGN(type_=_,exp1=e1,exp=e2,source=_),_)
      equation
        ({stmt},_) = BackendVarTransform.replaceStatementLst({stmtIn},repl,NONE(),{},false);
        DAE.STMT_ASSIGN(type_=_,exp1=e1,exp=e2,source=_) = stmt;
        b1 = Expression.isConst(e1);
        b2 = Expression.isConst(e2) and b1;
        //stmt = Util.if_(b1,stmtIn,stmt);
        stmt = stmtIn;
      then
        ((stmt,b1 and b2));
    else
      then
        ((stmtIn,false));
  end matchcontinue;
end stmtCanBeRemoved;

protected function traverseStmtsAndUpdate"traverses all assign-statements. the stmts can be updated with the given function.
the Boolean function says if the statement should be deleted"
  input list<DAE.Statement> stmtsIn;
  input FuncType func;
  input Type_a argIn;
  input list<DAE.Statement> stmtsFold;
partial function FuncType
   input DAE.Statement stmtsIn;
   input Type_a argIn;
   output tuple<DAE.Statement,Boolean> stmtsOut;
end FuncType;
  replaceable type Type_a subtypeof Any;
  output list<DAE.Statement> stmtsOut;
algorithm
  stmtsOut := matchcontinue(stmtsIn,func,argIn,stmtsFold)
    local
      Boolean b;
      DAE.Exp e;
      DAE.ElementSource source;
      DAE.Else else_;
      list<DAE.Statement> stmtLst, xs, rest;
      list<list<DAE.Statement>> stmtLstLst;
      DAE.Statement x;
    case ({},_,_,_)
      equation
        _ = listReverse(stmtsFold);
      then
        stmtsFold;
    case (DAE.STMT_IF(exp =_, statementLst=stmtLst, else_=else_)::rest,_,_,_)
      equation
        x = List.first(stmtsIn);
        stmtLstLst = getDAEelseStatemntLsts(else_,{});
        stmtLstLst = listReverse(stmtLstLst);
        stmtLstLst = List.map3(stmtLstLst,traverseStmtsAndUpdate,func,argIn,{});
        stmtLst = traverseStmtsAndUpdate(stmtLst,func,argIn,{});
        stmtLstLst = stmtLst::stmtLstLst;
        x  = updateStatementsInIfStmt(stmtLstLst,x);
        xs = traverseStmtsAndUpdate(rest,func,argIn,x::stmtsFold);
      then
        xs;
    case(x::rest,_,_,_)
      equation
        ((x,b)) = func(x,argIn);
        xs = Util.if_(b,stmtsFold,x::stmtsFold);
        xs = traverseStmtsAndUpdate(rest,func,argIn,xs);
      then
        xs;
  end matchcontinue;
end traverseStmtsAndUpdate;

protected function expLstIsConst"checks if a list of Expressions is completely constant"
  input list<DAE.Exp> exps;
  output Boolean b;
algorithm
  b := match(exps)
    local
      Boolean b1;
      DAE.Exp exp;
      list<DAE.Exp> rest;
    case({exp})
      equation
        b1 = Expression.isConst(exp);
      then
        b1;
    case({})
      equation
      then
        false;
    case(exp::rest)
      equation
        b1 = Expression.isConst(exp);
        b1 = Debug.bcallret1(b1,expLstIsConst,rest,false);
      then
        b1;
  end match;
end expLstIsConst;

protected function expLstIsNotConst
  input list<DAE.Exp> exps;
  output Boolean b;
algorithm
  b := not expLstIsConst(exps);
end expLstIsNotConst;

protected function makeIdentCref  "searches only for crefs"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inCrefs;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  (outExp,outCrefs) := match (inExp,inCrefs)
    local
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs;
      DAE.Exp exp;
      DAE.Type ty;
      String delimiter;
    case (DAE.CREF(componentRef=cref,ty=ty),crefs)
      equation
        cref = makeIdentCref2(cref,crefs);
        exp = DAE.CREF(cref,ty);
      then
        (exp,crefs);
    else (inExp,inCrefs);
  end match;
end makeIdentCref;


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
    case(cref1 as DAE.CREF_QUAL(ident=i1,identType=_,subscriptLst=_,componentRef=cref2),_)
      equation
        true = List.isMemberOnTrue(cref1,changeTheseCrefs,ComponentReference.crefEqual);
        i2 = ComponentReference.crefFirstIdent(cref2);
        i1 = i1+&"_"+&i2;
        cref2 = replaceCrefIdent(cref2,i1);
        cref2 = makeIdentCref2(cref2,changeTheseCrefs);
      then
        cref2;
    case(cref1 as DAE.CREF_IDENT(ident=_,identType=_,subscriptLst=_),_)
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

protected function statementRHSIsNotConst"checks whether the rhs of a statement is not constant.
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
          true;
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
        eq = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
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

protected function addReplacementRuleForAssignment"add a replacement rule according to the simple assigment like cref = const."
  input DAE.Statement stmt;
  input BackendVarTransform.VariableReplacements replIn;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  replOut := match(stmt,replIn)
    local
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref;
      DAE.Exp lhs,rhs;
    case(DAE.STMT_ASSIGN(type_=_,exp1=lhs,exp=rhs,source=_),_)
      equation
        cref = Expression.expCref(lhs);
        repl = BackendVarTransform.addReplacement(replIn,cref,rhs,NONE());
      then
        repl;
    else
      then replIn;
  end match;
end addReplacementRuleForAssignment;

protected function evaluateFunctions_updateAlgorithms"gets the statements from an algorithm in order to traverse them.
author:Waurich TUD 2014-03"
  input DAE.Element algIn;
  input tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements,Integer> tplIn;
  output DAE.Element algOut;
  output tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements,Integer> tplOut;
protected
  DAE.Algorithm alg;
  DAE.ElementSource source;
  list<DAE.Statement> stmts;
algorithm
  DAE.ALGORITHM(alg,source) := algIn;
  stmts := DAEUtil.getStatement(algIn);
  (stmts,tplOut) := evaluateFunctions_updateStatement(stmts,tplIn,{});
  alg := DAE.ALGORITHM_STMTS(stmts);
  algOut := DAE.ALGORITHM(alg,source);
end evaluateFunctions_updateAlgorithms;

protected function evaluateFunctions_updateStatement"replaces the statements with regards to the given varReplacements and check for constant assignments.
if there are constant assignments add this replacement rule
author:Waurich TUD 2014-03"
  input list<DAE.Statement> algsIn;
  input tuple<DAE.FunctionTree,BackendVarTransform.VariableReplacements,Integer> tplIn;
  input list<DAE.Statement> lstIn;
  output list<DAE.Statement> algsOut;
  output tuple<DAE.FunctionTree,BackendVarTransform.VariableReplacements,Integer> tplOut;
algorithm
  (algsOut,tplOut) := matchcontinue(algsIn,tplIn,lstIn)
    local
      Boolean changed, isCon, simplified, isIf, isRec, isTpl, predicted, eqDim, isCall, isEval, isArr;
      Integer idx, size, s, iterIdx;
      String iter;
      BackendVarTransform.VariableReplacements repl, replIn;
      DAE.ComponentRef cref;
      DAE.ElementSource source;
      DAE.Exp exp0, exp1, exp2, range;
      DAE.Else else_;
      DAE.FunctionTree funcTree,funcTree2;
      DAE.Statement alg, alg2;
      DAE.Type typ;
      list<BackendDAE.Equation> addEqs;
      list<DAE.ComponentRef> scalars, varScalars,constScalars, outputs, initOutputs;
      list<list<DAE.Exp>> lhsExpLst;
      list<DAE.Statement> stmts1, stmts2, stmtsIf, rest, addStmts, stmtsNew, allStmts, initStmts, tplStmts;
      list<list<DAE.Statement>> stmtsLst;
      list<DAE.Exp> expLst,tplExpsLHS,tplExpsRHS,lhsExps,lhsExpsInit,rhsExps;
    case({},(_,_,_),_)
      equation
        stmts1 = listReverse(lstIn);
      then (stmts1,tplIn);
    case(DAE.STMT_ASSIGN(type_=typ, exp1=exp1, exp=exp2, source=source)::rest,(funcTree,replIn,idx),_)
      equation
        // replace, evaluate, simplify the assignment
       //print("the STMT_ASSIGN before: "+&DAEDump.ppStatementStr(List.first(algsIn)));
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"assignment:\n"+&DAEDump.ppStatementStr(List.first(algsIn)));
        cref = Expression.expCref(exp1);
        scalars = getRecordScalars(cref);
        (exp2,changed) = BackendVarTransform.replaceExp(exp2,replIn,NONE());
        (exp2,(exp1,funcTree,idx,addStmts)) = Expression.traverseExpTopDown(exp2,evaluateConstantFunctionWrapper,(exp1,funcTree,idx,{}));
        (exp2,changed) = Debug.bcallret1_2(changed,ExpressionSimplify.simplify,exp2,exp2,changed);
        (exp2,_) = ExpressionSimplify.simplify(exp2);
        expLst = Expression.getComplexContents(exp2);
        //print("SIMPLIFIED\n"+&stringDelimitList(List.map({exp2},ExpressionDump.printExpStr),"\n")+&"\n");

        // add the replacements for the addStmts and remove the replacements for the variable outputs
        repl = List.fold(addStmts,addReplacementRuleForAssignment,replIn);
        lhsExps = Expression.getComplexContents(exp1);
        outputs = List.map(lhsExps,Expression.expCref);
        repl = BackendVarTransform.removeReplacements(repl,outputs,NONE());

        // check if its constant, a record or a tuple
        isCon = Expression.isConst(exp2);
        eqDim = listLength(scalars) == listLength(expLst);  // so it can be partly constant
        isRec = ComponentReference.isRecord(cref);
        isTpl = Expression.isTuple(exp1) and Expression.isTuple(exp2);
        isCall = Expression.isCall(exp2);
        //print("is it const? "+&boolString(isCon)+&" ,is it rec: "+&boolString(isRec)+&" ,is it tpl: "+&boolString(isTpl)+&" ,is it call: "+&boolString(isCall)+&"\n");

        // remove the variable crefs and add the constant crefs to the replacements
        //print("scalars\n"+&stringDelimitList(List.map(scalars,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //print("expLst\n"+&stringDelimitList(List.map(expLst,ExpressionDump.printExpStr),"\n")+&"\n");
        scalars = Util.if_(isRec and eqDim,scalars,{});
        expLst = Util.if_(isRec and eqDim,expLst,{});
        (_,varScalars) = List.filterOnTrueSync(expLst,Expression.isNotConst,scalars);
        (expLst,constScalars) = List.filterOnTrueSync(expLst,Expression.isConst,scalars);
        //print("variable scalars\n"+&stringDelimitList(List.map(varScalars,ComponentReference.printComponentRefStr),"\n")+&"\n");
        //BackendVarTransform.dumpReplacements(replIn);

        repl = Debug.bcallret4(isCon and not isRec, BackendVarTransform.addReplacement,repl,cref,exp2,NONE(),repl);
        repl = Debug.bcallret4(isCon and isRec, BackendVarTransform.addReplacements,repl,scalars,expLst,NONE(),repl);
        repl = Debug.bcallret3(not isCon and not isRec, BackendVarTransform.removeReplacement, repl,cref,NONE(),repl);
        repl = Debug.bcallret3(not isCon and isRec, BackendVarTransform.removeReplacements,repl,varScalars,NONE(),repl);
        repl = Debug.bcallret4(not isCon and isRec, BackendVarTransform.addReplacements,repl,constScalars,expLst,NONE(),repl);

        //Debug.bcall(isCon and not isRec,print,"add the replacement: "+&ComponentReference.crefStr(cref)+&" --> "+&ExpressionDump.printExpStr(exp2)+&"\n");
        //Debug.bcall(not isCon,print,"update the replacement for: "+&ComponentReference.crefStr(cref)+&"\n");
        //BackendVarTransform.dumpReplacements(repl);

        // build the new statements
        alg = Util.if_(isCon,DAE.STMT_ASSIGN(typ,exp1,exp2,source),List.first(algsIn));
        tplExpsLHS = Debug.bcallret1(isTpl,Expression.getComplexContents,exp1,{});
        tplExpsRHS = Debug.bcallret1(isTpl,Expression.getComplexContents,exp2,{});
        tplStmts = List.map2(List.intRange(listLength(tplExpsLHS)),makeAssignmentMap,tplExpsLHS,tplExpsRHS);
        //alg = Util.if_(isTpl,DAE.STMT_TUPLE_ASSIGN(typ,tplExpsLHS,exp2,source),alg);
        stmts1 = Util.if_(isTpl,tplStmts,{alg});
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"evaluated assignment to:\n"+&stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+&"\n");

        //stmts1 = listAppend({alg},lstIn);
        stmts1 = listAppend(stmts1,lstIn);
        //print("\nthe traverse LIST after :"+&stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+&"\n");
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts1);
      then (rest,(funcTree,repl,idx));
    case (DAE.STMT_ASSIGN_ARR(type_=_, componentRef=_, exp=_)::rest,(funcTree,_,idx),_)
      equation
        //print("STMT_ASSIGN_ARR");
        //print("the STMT_ASSIGN_ARR: "+&DAEDump.ppStatementStr(List.first(algsIn))+&"\n");
        alg = List.first(algsIn);
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,tplIn,alg::lstIn);
      then (rest,(funcTree,repl,idx));
    case(DAE.STMT_IF(exp=exp0, statementLst=stmtsIf, else_=else_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"IF-statement:\n"+&DAEDump.ppStatementStr(alg));

        // get all stmts in the function and the assigned crefs (need the outputs in order to remove the replacements if nothing can be evaluated)
        stmtsLst = getDAEelseStatemntLsts(else_,{});
        stmtsLst = listReverse(stmtsLst);
        stmtsLst = stmtsIf::stmtsLst;
        allStmts = List.flatten(stmtsLst);
        lhsExps = List.fold1(allStmts,getStatementLHSScalar,funcTree,{});
        lhsExps = List.unique(lhsExps);
        outputs = List.map(lhsExps,Expression.expCref);

        //check if the conditions can be evaluated, get evaluated stmts
        (isEval,stmts1) = evaluateIfStatement(alg,FUNCINFO(replIn,funcTree,idx));

        // if its not definite which case, try to predict a constant output, maybe its partially constant, then remove function outputs replacements
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isEval,print,"-->try to predict the outputs \n");
        ((stmtsNew,addStmts),FUNCINFO(repl,funcTree,idx)) = Debug.bcallret2_2(not isEval ,predictIfOutput,alg,FUNCINFO(replIn,funcTree,idx),(stmts1,{}),FUNCINFO(replIn,funcTree,idx));
        predicted = List.isNotEmpty(addStmts) or List.isEmpty(stmtsNew) and not isEval;
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isEval,print,"could it be predicted? "+&boolString(predicted)+&"\n");

        // if nothing can be done, remove the replacements for the variables assigned in the if stmt
        repl = Debug.bcallret3(not predicted and not isEval, BackendVarTransform.removeReplacements, repl,outputs,NONE(),repl);
        //print("REMOVE THE REPLACEMENTS\n"+&stringDelimitList(List.map(outputs,ComponentReference.printComponentRefStr),"\n")+&"\n");

        //stmts1 = Util.if_(simplified and isCon, listAppend(stmts1,addStmts), stmts1);

        stmts1 = Util.if_(predicted, stmtsNew,stmts1);
        rest = listAppend(addStmts,rest);

        //BackendVarTransform.dumpReplacements(repl);

        //print("the STMT_IF after: \n"+&stringDelimitList(List.map(listAppend(stmts1,addStmts),DAEDump.ppStatementStr),"\n")+&"\n");
        //print("\nthe REST if after :"+&stringDelimitList(List.map(rest,DAEDump.ppStatementStr),"\n")+&"\n");
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"evaluated IF-statements to:\n"+&stringDelimitList(List.map(listAppend(stmts1,addStmts),DAEDump.ppStatementStr),"\n")+&"\n\n");

        stmts1 = listAppend(stmts1,lstIn);
        //print("\nthe traverse LIST after :"+&stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+&"\n");
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts1);
      then (rest,(funcTree,repl,idx));
    case(DAE.STMT_TUPLE_ASSIGN(type_=_, expExpLst=expLst, exp=exp0)::rest,(funcTree,replIn,idx),_)
      equation
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"Tuple-statement:\n"+&DAEDump.ppStatementStr(List.first(algsIn)));
        //print("idx: "+&intString(idx)+&"\n");
        //print("\nthe traverse LIST tpl before :"+&stringDelimitList(List.map(lstIn,DAEDump.ppStatementStr),"\n")+&"\n");
        //print("the LHS before\n");
        //print(stringDelimitList(List.map(expLst,ExpressionDump.printExpStr),"\n")+&"\n");
        //print("the RHS before\n");
        //print(ExpressionDump.printExpStr(exp1)+&"\n");
        (exp1,_) = BackendVarTransform.replaceExp(exp0,replIn,NONE());
        //print("the RHS replaced\n");
        //print(ExpressionDump.printExpStr(exp1)+&"\n");

        exp2 = DAE.TUPLE(expLst);
        ((exp1,exp2,addEqs,funcTree2,idx,_)) = evaluateConstantFunction(exp1,exp2,funcTree,idx);
        //print("\nthe LHS after\n");
        //print(ExpressionDump.printExpStr(exp2));
        //ExpressionDump.dumpExp(exp2);
        //print("\nthe RHS after\n");
        //print(ExpressionDump.printExpStr(exp1));
        //BackendDump.dumpEquationList(addEqs,"the additional equations after");
        isCon = Expression.isConst(exp1);
        exp1 = Util.if_(isCon,exp1,exp0);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"--> is the tuple const? "+&boolString(isCon)+&"\n");

        // add the replacements
        varScalars = List.map(expLst,Expression.expCref);
        repl = Debug.bcallret3(not isCon,BackendVarTransform.removeReplacements,replIn,varScalars,NONE(),replIn); // remove the lhs crefs if tis not constant
        repl = Debug.bcallret3(isCon,addTplReplacements,repl,exp1,exp2,repl);  // add all tuple exps to repl if the whole tuple is constant

        // build the new statements
        size = DAEUtil.getTupleSize(exp2);
        typ = Expression.typeof(exp2);
        expLst = DAEUtil.getTupleExps(exp2);

        tplExpsLHS = DAEUtil.getTupleExps(exp2);
        tplExpsLHS = Util.if_(isCon,tplExpsLHS,{});
        tplExpsRHS = DAEUtil.getTupleExps(exp1);
        tplExpsRHS = Util.if_(isCon,tplExpsRHS,{});
        stmtsNew = List.map2(List.intRange(listLength(tplExpsLHS)),makeAssignmentMap,tplExpsLHS,tplExpsRHS); // if the tuple is completely constant

        alg = List.first(algsIn);
        stmtsNew = Util.if_(isCon,stmtsNew,{alg});
        stmts2 = Util.if_(intEq(size,0),{DAE.STMT_ASSIGN(typ,exp2,exp1,DAE.emptyElementSource)},stmtsNew);
        stmts1 = List.map(addEqs,equationToStatement);
        stmts2 = listAppend(stmts2,stmts1);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"evaluated Tuple-statements to (incl. addEqs):\n"+&stringDelimitList(List.map(stmts2,DAEDump.ppStatementStr),"\n")+&"\n");
        stmts2 = listReverse(stmts2);
        stmts2 = listAppend(stmts2,lstIn);
        //print("idx: "+&intString(idx)+&"\n");
        //print("\nthe traverse LIST tpl after :"+&stringDelimitList(List.map(stmts2,DAEDump.ppStatementStr),"\n")+&"\n");
        //print("\nthe REST tpl after :"+&stringDelimitList(List.map(rest,DAEDump.ppStatementStr),"\n")+&"\n");
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree2,repl,idx),stmts2);
      then (rest,(funcTree,repl,idx));

    case(DAE.STMT_FOR(type_=_,iterIsArray=isArr,iter=iter,index=iterIdx,range=range,statementLst=stmts1,source=_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
        // TODO: evaluate for-loops
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"For-statement:\n"+&DAEDump.ppStatementStr(alg));
        // at least remove the replacements for the lhs
        lhsExps = List.fold1(stmts1,getStatementLHSScalar,funcTree,{});
        lhsExps = List.unique(lhsExps);
        lhsExpLst = List.map(lhsExps,Expression.getComplexContents); //consider arrays etc.
        lhsExps = listAppend(List.flatten(lhsExpLst),lhsExps);
        lhsExps = List.filterOnTrue(lhsExps,Expression.isCref); //remove e.g. ASUBs and consider only the scalar subs
        outputs = List.map(lhsExps,Expression.expCref);
        repl = Debug.bcallret3(true, BackendVarTransform.removeReplacements,replIn,outputs,NONE(),replIn);

        // lets see if we can evaluate it

          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"evaluated For-statement to:\n"+&DAEDump.ppStatementStr(alg));
        stmts2 = alg::lstIn;
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts2);
      then (rest,(funcTree,repl,idx));

    case(DAE.STMT_WHILE(exp=_,statementLst=stmts1,source=_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
        // TODO: evaluate while-loops
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"While-statement (not evaluated):\n"+&DAEDump.ppStatementStr(alg));
        lhsExps = List.fold1(stmts1,getStatementLHSScalar,funcTree,{});
        lhsExps = List.unique(lhsExps);
        outputs = List.map(lhsExps,Expression.expCref);
        repl = Debug.bcallret3(true, BackendVarTransform.removeReplacements,replIn,outputs,NONE(),replIn);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"evaluated While-statement to:\n"+&DAEDump.ppStatementStr(alg));
        stmts2 = alg::lstIn;
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts2);
      then (rest,(funcTree,repl,idx));
    case(DAE.STMT_ASSERT(cond=_,msg=_,level=_,source=_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"assert-statement (not evaluated):\n"+&DAEDump.ppStatementStr(alg));
        stmts2 = alg::lstIn;
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,(funcTree,repl,idx));
    case(DAE.STMT_TERMINATE(msg=_,source=_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"terminate-statement:\n"+&DAEDump.ppStatementStr(alg));
        stmts2 = alg::lstIn;
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,(funcTree,repl,idx));
    case(DAE.STMT_REINIT(var=_,value=_,source=_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"reinit-statement:\n"+&DAEDump.ppStatementStr(alg));
        stmts2 = alg::lstIn;
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,(funcTree,repl,idx));
    case(DAE.STMT_NORETCALL(exp=_,source=_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"noretcall-statement (not evaluated):\n"+&DAEDump.ppStatementStr(alg));
        stmts2 = alg::lstIn;
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,(funcTree,repl,idx));
    case(DAE.STMT_RETURN(source=_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = List.first(algsIn);
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"return-statement:\n"+&DAEDump.ppStatementStr(alg));
        stmts2 = alg::lstIn;
        (rest,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,(funcTree,repl,idx));
    else
      equation
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"evaluateFunctions_updateStatement failed for!\n"+&DAEDump.ppStatementStr(List.first(algsIn))+&"\n");
      then
        fail();
  end matchcontinue;
end evaluateFunctions_updateStatement;

protected function evaluateIfStatement"check if the cases are constant and if so evaluate them.
author: Waurich TUD 2014-04"
  input DAE.Statement stmtIn;
  input FuncInfo info;
  output Boolean isEval;
  output list<DAE.Statement> stmtsOut;
algorithm
  (isEval,stmtsOut) := matchcontinue(stmtIn,info)
    local
      Boolean  isIf, isCon, isElse, eval;
      Integer idx;
      BackendVarTransform.VariableReplacements repl, replIn;
      DAE.Else else_;
      DAE.Exp expIf,exp1;
      DAE.FunctionTree funcTree;
      list<DAE.Statement> stmtsIf,stmts1,stmtsElse;
    case(DAE.STMT_IF(exp=expIf, statementLst=stmtsIf, else_=else_),FUNCINFO(repl=replIn, funcTree=funcTree, idx=idx))
      equation
        //check if its the if
          Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"-->try to check if its the if case\n");
        (exp1,(_,_,_,_)) = Expression.traverseExpTopDown(expIf,evaluateConstantFunctionWrapper,(expIf,funcTree,idx,{}));
        (exp1,_) = BackendVarTransform.replaceExp(exp1,replIn,NONE());
        (exp1,_) = ExpressionSimplify.simplify(exp1);
        isCon = Expression.isConst(exp1);
        isIf = Debug.bcallret1(isCon,Expression.getBoolConst,exp1,false);

        // check if its the IF case, if true then evaluate:
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"-->is the if const? "+&boolString(isCon)+&" and is it the if case ? "+&boolString(isIf)+&"\n");
        //(stmts1,(funcTree,repl,idx)) = Debug.bcallret3_2(isIf and isCon,evaluateFunctions_updateStatement,stmtsIf,(funcTree,replIn,idx),lstIn,stmtsIf,(funcTree,replIn,idx));
        (stmts1,(funcTree,repl,idx)) = Debug.bcallret3_2(isIf and isCon,evaluateFunctions_updateStatement,stmtsIf,(funcTree,replIn,idx),{},{stmtIn},(funcTree,replIn,idx));  // without listIn

        // if its definitly not the if, check the else
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isIf,print,"-->try to check if its another case\n");
        (stmtsElse,isElse) = Debug.bcallret2_2(isCon and not isIf,evaluateElse,else_,info,{stmtIn},false);
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isIf,print,"-->is it an other case? "+&boolString(isElse)+&"\n");
        (stmts1,(funcTree,repl,idx)) = Debug.bcallret3_2(isCon and isElse,evaluateFunctions_updateStatement,stmtsElse,(funcTree,replIn,idx),{},stmts1,(funcTree,replIn,idx));
        eval = isCon and (isIf or isElse);
     then
       (eval,stmts1);
     else
       equation
         Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"evaluateIfStatement failed \n");
       then
         fail();
  end matchcontinue;
end evaluateIfStatement;

protected function evaluateElse"checks if its one of the elseif cases.
author: Waurich TUD 2014-04"
  input DAE.Else elseIn;
  input FuncInfo info;
  output list<DAE.Statement> stmtsOut;
  output Boolean isElse;
algorithm
  (stmtsOut,isElse) := matchcontinue(elseIn,info)
    local
      Boolean isCon,isElseIf;
      Integer idx;
      BackendVarTransform.VariableReplacements replIn;
      DAE.Exp expIf,exp1;
      DAE.Else else_;
      DAE.FunctionTree funcTree;
      list<DAE.Statement> stmts;
    case(DAE.ELSEIF(exp=expIf,statementLst=stmts,else_=else_),FUNCINFO(repl=replIn, funcTree=funcTree, idx=idx))
      equation
        // check if its the elseif
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"-->try to check if its the elseif case\n");
        (exp1,(_,_,_,_)) = Expression.traverseExpTopDown(expIf,evaluateConstantFunctionWrapper,(expIf,funcTree,idx,{}));
        (exp1,_) = BackendVarTransform.replaceExp(exp1,replIn,NONE());
        (exp1,_) = ExpressionSimplify.simplify(exp1);
        isCon = Expression.isConst(exp1);
        isElseIf = Debug.bcallret1(isCon,Expression.getBoolConst,exp1,false);
        (stmts,isElseIf) = Debug.bcallret2_2(isCon and not isElseIf,evaluateElse,else_,info,stmts,isElseIf);
      then
        (stmts,isElseIf);
    case(DAE.ELSE(statementLst=stmts),FUNCINFO(repl=replIn, funcTree=funcTree, idx=idx))
      equation
        // if everything else was const and false, it has to be the else
      then
        (stmts,true);
    case(DAE.NOELSE(),FUNCINFO(repl=replIn, funcTree=funcTree, idx=idx))
      equation
      then
        ({},true);
  end matchcontinue;
end evaluateElse;

protected function addTplReplacements
  input BackendVarTransform.VariableReplacements replIn;
  input DAE.Exp e1;
  input DAE.Exp e2;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  replOut := matchcontinue(replIn,e1,e2)
    local
      list<DAE.Exp> tplLHS, tplRHS;
      list<DAE.ComponentRef> crefs;
      BackendVarTransform.VariableReplacements repl;
    case(_,_,_)
      equation
        tplRHS = DAEUtil.getTupleExps(e1);
        tplLHS = DAEUtil.getTupleExps(e2);
        crefs = List.map(tplLHS,Expression.expCref);
        repl = BackendVarTransform.addReplacements(replIn,crefs,tplRHS,NONE());
        //print("add the tpl  replacements: "+&stringDelimitList(List.map(crefs,ComponentReference.printComponentRefStr),",")+&stringDelimitList(List.map(tplRHS,ExpressionDump.printExpStr),",")+&"\n");
      then
        repl;
   else
     then
       replIn;
  end matchcontinue;
end addTplReplacements;

protected function equationToStatement "converts a simple BackendDAE.Equation to a DAE.Statement
author:Waurich TUD 2014-04"
  input BackendDAE.Equation eqIn;
  output DAE.Statement stmtOut;
algorithm
  stmtOut := match(eqIn)
    local
      DAE.ElementSource source;
      DAE.Exp rhs,lhs;
      DAE.Type typ;
    case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source))
      equation
        typ = Expression.typeof(lhs);
      then
        DAE.STMT_ASSIGN(typ,lhs,rhs,source);
    else
      equation
        print("equationToStatement failed!\n");
      then fail();
  end match;
end equationToStatement;

protected function replaceExps "mapping function that replaces the expressions. the mapping values are replacement lsts
author:Waurich TUD 2014-04"
  input BackendVarTransform.VariableReplacements replIn;
  input list<DAE.Exp> expsIn;
  output list<DAE.Exp> expsOut;
algorithm
  (expsOut,_) := List.map2_2(expsIn,BackendVarTransform.replaceExp,replIn,NONE());
end replaceExps;

protected function getStatementLHS"fold function to get the lhs expressions of a statement
author:Waurich TUD 2014-04"
  input DAE.Statement stmt;
  input list<DAE.Exp> expsIn;
  output list<DAE.Exp> lhs;
algorithm
  lhs := match(stmt,expsIn)
  local
    DAE.Else else_;
    DAE.Exp exp;
    DAE.ComponentRef cref;
    DAE.Statement stmt1;
    list<DAE.Exp> expLst,expLst2;
    list<DAE.Statement> stmtLst1,stmtLst2;
    list<list<DAE.Statement>> stmtLstLst;
  case(DAE.STMT_ASSIGN(type_=_,exp1=exp,exp=_),_)
    equation
    then
      exp::expsIn;
  case(DAE.STMT_TUPLE_ASSIGN(type_=_,expExpLst=expLst,exp=_,source=_),_)
    equation
      expLst = listAppend(expLst,expsIn);
    then expLst;
  case(DAE.STMT_ASSIGN_ARR(type_=_,componentRef=cref,exp=exp,source=_),_)
    equation
      exp = Expression.crefExp(cref);
    then {exp};
  case(DAE.STMT_IF(exp=_,statementLst=stmtLst1,else_=else_,source=_),_)
    equation
      stmtLstLst = getDAEelseStatemntLsts(else_,{});
      stmtLst2 = List.flatten(stmtLstLst);
      stmtLst1 = listAppend(stmtLst1,stmtLst2);
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_FOR(type_=_,iterIsArray=_,iter=_,index=_,range=_,statementLst=stmtLst1,source=_),_)
    equation
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_PARFOR(type_=_,iterIsArray=_,iter=_,index=_,range=_,statementLst=stmtLst1,loopPrlVars=_,source=_),_)
    equation
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_WHILE(exp=_,statementLst=stmtLst1,source=_),_)
    equation
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_WHEN(exp=_,conditions=_,initialCall=_,statementLst=stmtLst1,elseWhen=SOME(stmt1),source=_),_)
    equation
      Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print," check getStatementLHS for WHEN!\n"+&DAEDump.ppStatementStr(stmt));
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
      expLst = List.fold({stmt1},getStatementLHS,expLst);
    then expLst;
  case(DAE.STMT_WHEN(exp=_,conditions=_,initialCall=_,statementLst=stmtLst1,elseWhen=NONE(),source=_),_)
    equation
      Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print," check getStatementLHS for WHEN!\n"+&DAEDump.ppStatementStr(stmt));
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_ASSERT(cond=_,msg=_,level=_,source=_),_)
    equation
      //Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"getStatementLHS update for ASSERT!\n"+&DAEDump.ppStatementStr(stmt));
    then expsIn;
  case(DAE.STMT_TERMINATE(msg=_,source=_),_)
    equation
      Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"getStatementLHS update for TERMINATE!\n"+&DAEDump.ppStatementStr(stmt));
    then fail();
  case(DAE.STMT_REINIT(var=_,value=_,source=_),_)
    equation
      Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"getStatementLHS update for REINIT!\n"+&DAEDump.ppStatementStr(stmt));
    then fail();
  case(DAE.STMT_NORETCALL(exp=exp,source=_),_)
    equation
    then expsIn;
  case(DAE.STMT_RETURN(source=_),_)
    equation
      Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"getStatementLHS update for RETURN!\n"+&DAEDump.ppStatementStr(stmt));
    then fail();
  case(DAE.STMT_BREAK(source=_),_)
    equation
      Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"getStatementLHS update for BREAK!\n"+&DAEDump.ppStatementStr(stmt));
    then fail();
  case(DAE.STMT_ARRAY_INIT(name=_,ty=_,source=_),_)
    equation
      Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"getStatementLHS update for ARRAY_INIT!\n"+&DAEDump.ppStatementStr(stmt));
    then fail();
  else
    equation
      print("getStatementLHS update for !\n"+&DAEDump.ppStatementStr(stmt));
    then fail();
  end match;
end getStatementLHS;

protected function getStatementLHSScalar"fold function to get the assigned scalar lhs expressions of a statement
TODO: move to getStatementLHS
author:Waurich TUD 2014-04"
  input DAE.Statement stmt;
  input DAE.FunctionTree funcTree;
  input list<DAE.Exp> expsIn;
  output list<DAE.Exp> lhs;
algorithm
  lhs := matchcontinue(stmt,funcTree,expsIn)
  local
    Absyn.Path path;
    DAE.ComponentRef lhsCref;
    DAE.Else else_;
    DAE.Exp exp;
    DAE.Function func;
    list<DAE.ComponentRef> outputCrefs;
    list<DAE.Element> algs,elements;
    list<DAE.Exp> expLst;
    list<DAE.Statement> stmtLst1,stmtLst2;
    list<list<DAE.Statement>> stmtLstLst;
  case(DAE.STMT_ASSIGN(type_=_,exp1=exp,exp=DAE.CALL(path=path,expLst=_,attr=_)),_,_)
    equation
      SOME(func) = DAEUtil.avlTreeGet(funcTree,path);
      elements = DAEUtil.getFunctionElements(func);
      algs = List.filter(elements,DAEUtil.isAlgorithm);
      stmtLstLst = List.map(algs,DAEUtil.getStatement);
      stmtLst1 = List.flatten(stmtLstLst);
      expLst = List.fold1(stmtLst1,getStatementLHSScalar,funcTree,expsIn);
      outputCrefs = List.map(expLst,Expression.expCref);

      lhsCref = Expression.expCref(exp);
      outputCrefs = List.filterOnTrue(outputCrefs,ComponentReference.crefIsNotIdent);
      outputCrefs = List.map(outputCrefs,ComponentReference.crefStripFirstIdent);
      outputCrefs = List.map1(outputCrefs,ComponentReference.joinCrefsR,lhsCref);

      expLst = List.map(outputCrefs,Expression.crefExp);
      expLst = listAppend(expLst,expsIn);
    then
      expLst;
  case(DAE.STMT_ASSIGN_ARR(type_=_,componentRef=lhsCref,exp=exp,source=_),_,_)
    equation
      exp = Expression.crefExp(lhsCref);
      expLst = Expression.getComplexContents(exp);
      expLst = listAppend(expLst,expsIn);
    then expLst;
  else
    equation
      expLst = getStatementLHS(stmt,expsIn);
    then expLst;
  end matchcontinue;
end getStatementLHSScalar;

protected function getDAEelseStatemntLsts"get all statements for every else or elseif clause
author:Waurich TUD 2014"
  input DAE.Else elseIn;
  input list<list<DAE.Statement>> stmtLstsIn;
  output list<list<DAE.Statement>> stmtLstsOut;
algorithm
  stmtLstsOut := match(elseIn,stmtLstsIn)
    local
      DAE.Else else1;
      list<DAE.Statement> stmts;
      list<list<DAE.Statement>> stmtsLst;
    case(DAE.ELSEIF(exp=_,statementLst=stmts,else_=else1),_)
      equation
        stmtsLst = stmts::stmtLstsIn;
        stmtsLst = getDAEelseStatemntLsts(else1,stmtsLst);
      then
        stmtsLst;
    case(DAE.ELSE(statementLst=stmts),_)
      equation
        stmtsLst = stmts::stmtLstsIn;
      then
        stmtsLst;
    else
      equation
      then
        stmtLstsIn;
  end match;
end getDAEelseStatemntLsts;

protected function evaluateFunctions_updateStatementLst"
author:Waurich TUD 2014-03"
  input list<DAE.Statement> stmtsIn;
  input tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements,Integer> tplIn;
  output list<DAE.Statement> stmtsOut;
  output tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements,Integer> tplOut;
protected
  Integer idx;
  BackendVarTransform.VariableReplacements repl;
  DAE.FunctionTree funcs;
algorithm
  (stmtsOut,tplOut) := evaluateFunctions_updateStatement(stmtsIn,tplIn,{});
end evaluateFunctions_updateStatementLst;

protected function evaluateConstantFunctionWrapper
  input DAE.Exp inExp;
  input tuple<DAE.Exp, DAE.FunctionTree,Integer,list<DAE.Statement>> inTpl;
  output DAE.Exp outExp;
  output Boolean continue;
  output tuple<DAE.Exp,DAE.FunctionTree,Integer,list<DAE.Statement>> outTpl;
algorithm
  (outExp,continue,outTpl) := matchcontinue(inExp,inTpl)
    local
      Integer idx;
      DAE.Exp rhs, lhs;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> addEqs;
      list<DAE.Statement> stmts,stmtsIn;
  case (rhs,(lhs,funcs,idx,stmtsIn))
    equation
      DAE.CALL(path=_,expLst=_,attr=_) = rhs;
      ((rhs,lhs,addEqs,funcs,idx,_)) = evaluateConstantFunction(rhs,lhs,funcs,idx);

      stmts = List.map(addEqs,equationToStmt);

      stmts = listAppend(stmts,stmtsIn);
    then (rhs,true,(lhs,funcs,idx,stmts));
  case (rhs,(lhs,funcs,idx,stmtsIn))
    then (rhs,false,(lhs,funcs,idx,stmtsIn));
  end matchcontinue;
end evaluateConstantFunctionWrapper;

protected function equationToStmt"transforms a backend equation into a statement"
  input BackendDAE.Equation eqIn;
  output DAE.Statement stmtOut;
algorithm
  stmtOut := matchcontinue(eqIn)
    local
      DAE.ElementSource source;
      DAE.Exp lhs,rhs;
      DAE.Type typ;
    case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source))
      equation
        typ = expType(lhs);
        then
          DAE.STMT_ASSIGN(typ,lhs,rhs,source);
      else
        equation
          print("equationToStmt failed for: "+&BackendDump.dumpEqnsStr({eqIn})+&"\n");
        then fail();
  end matchcontinue;
end equationToStmt;

protected function expType"gets the type of an expression"
  input DAE.Exp eIn;
  output DAE.Type tOut;
algorithm
  tOut := matchcontinue(eIn)
    local
      DAE.Type t;
    case(DAE.CREF(componentRef=_, ty=t))
      equation
      then
        t;
    else
      equation
      print("expType failed for: "+&ExpressionDump.printExpStr(eIn)+&"\n");
      then
        fail();
  end matchcontinue;
end expType;

protected function simplifyElse "evaluates an else or elseIf.
author:Waurich TUD 2014-03"
  input DAE.Else elseIn;
  input tuple<DAE.FunctionTree,BackendVarTransform.VariableReplacements,Integer> inTpl;
  output list<DAE.Statement> stmtsOut;
  output tuple<DAE.FunctionTree,BackendVarTransform.VariableReplacements,Integer,Boolean> outTpl;
algorithm
  (stmtsOut,outTpl) := matchcontinue(elseIn,inTpl)
    local
      Integer idx;
      Boolean const;
      Boolean isElseIf;
      BackendVarTransform.VariableReplacements repl,replIn;
      DAE.Else else_;
      DAE.Exp exp;
      DAE.FunctionTree funcs;
      list<DAE.Statement> stmts;
    case(DAE.NOELSE(),(funcs,replIn,idx))
      equation
        //print("NO ELSE\n");
       then
         ({},(funcs,replIn,idx,true));
    case(DAE.ELSEIF(exp=exp, statementLst=stmts,else_=else_),(funcs,replIn,idx))
        equation
        // simplify the condition
          //print("STMT_IF_EXP_IN_ELSEIF:\n");
        (exp,(_,funcs,idx,_)) = Expression.traverseExpTopDown(exp,evaluateConstantFunctionWrapper,(exp,funcs,idx,{}));
        (exp,_) = BackendVarTransform.replaceExp(exp,replIn,NONE());
        (exp,_) = ExpressionSimplify.simplify(exp);

          //print("STMT_IF_EXP_IN_ELSEIF SIMPLIFIED:\n");
          //ExpressionDump.dumpExp(exp);
        // check if this could be evaluated
        const = Expression.isConst(exp);
        isElseIf = Debug.bcallret1(const,Expression.getBoolConst,exp,false);
        //print("do we have to use the elseif: "+&boolString(isElseIf)+&"\n");
        (stmts,(funcs,repl,idx)) = Debug.bcallret3_2(const and isElseIf,evaluateFunctions_updateStatement,stmts,(funcs,replIn,idx),{},stmts,(funcs,replIn,idx));  // is this elseif case
        (stmts,(funcs,repl,idx,isElseIf)) = Debug.bcallret2_2(not isElseIf,simplifyElse,else_,(funcs,replIn,idx),stmts,(funcs,repl,idx,isElseIf)); // is the another elseif case or the else case
      then
        (stmts,(funcs,repl,idx,isElseIf));
    case(DAE.ELSE(statementLst=stmts),(funcs,repl,idx))
        equation
           //print("the STMT_ELSE before: "+&stringDelimitList(List.map(stmts,DAEDump.ppStatementStr),"\n")+&"\n");
         repl = BackendVarTransform.emptyReplacements();
         (stmts,(funcs,repl,idx)) = evaluateFunctions_updateStatementLst(stmts,(funcs,repl,idx));  // is this elseif case
           //print("the STMT_ELSE simplified: "+&stringDelimitList(List.map(stmts,DAEDump.ppStatementStr),"\n")+&"\n");
      then
         (stmts,(funcs,repl,idx,false));
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
      DAE.Dimensions dimensions;
      DAE.Type ty;
      DAE.Exp exp;
      list<DAE.Exp> exps;
      list<DAE.Var> varLst;
      list<DAE.ComponentRef> crefs, lastCrefs;
      list<list<DAE.ComponentRef>> crefLst;
      list<DAE.Type> types;
      list<String> names;
    case(DAE.VAR(componentRef = cref,ty=DAE.T_COMPLEX(varLst = varLst)))
      equation
        names = List.map(varLst,DAEUtil.typeVarIdent);
        //print("the names for the scalar complex crefs: "+&stringDelimitList(names,"\n;")+&"\n");
        types = List.map(varLst,DAEUtil.VarType);
        crefs = List.map1(names,ComponentReference.appendStringCref,cref);
        crefs = setTypesForScalarCrefs(crefs,types,{});
        crefLst = List.map1(crefs,ComponentReference.expandCref,true);
        crefs = List.flatten(crefLst);
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
    case(DAE.VAR(componentRef=cref,ty=DAE.T_ARRAY(ty=_,dims=dimensions,source=_)))
      equation
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"the array cref before\n"+&stringDelimitList(List.map({cref},ComponentReference.printComponentRefStr),"\n")+&"\n");
        crefs = ComponentReference.expandArrayCref(cref,dimensions);
      then
        crefs;
    case(DAE.VAR(componentRef=cref,ty=DAE.T_ENUMERATION(index=_,path=_,names=_,literalVarLst=_,attributeLst=_,source=_)))
      equation
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"update getScalarsForComplexVar for enumerations: the enum cref is :"+&stringDelimitList(List.map({cref},ComponentReference.printComponentRefStr),"\n")+&"\n");
      then
        {};
    case(DAE.VAR(componentRef=cref,ty=DAE.T_TUPLE(tupleType=_,source=_)))
      equation
        Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"update getScalarsForComplexVar for tuple types: the tupl cref is :\n"+&stringDelimitList(List.map({cref},ComponentReference.printComponentRefStr),"\n")+&"\n");
      then
        {};
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
        true = intNe(List.first(dim),0);
      then
        false;
    case(DAE.VAR(componentRef=_,ty=DAE.T_ARRAY(ty=_, dims=_, source=_), dims=dims ))
      equation
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
  case(DAE.CREF_QUAL(ident=_,identType=_,subscriptLst=_,componentRef=_)::crest, t1::trest, _)
    equation
      cr1 = List.first(allCrefs);
      cr1 = ComponentReference.crefSetLastType(cr1,t1);
      crs = setTypesForScalarCrefs(crest,trest,cr1::crefsIn);
    then
      crs;
  case(DAE.CREF_IDENT(ident=id,identType=_,subscriptLst=sl)::crest, t1::trest, _)
    equation
      cr1 = List.first(allCrefs);
      cr1 = DAE.CREF_IDENT(id,t1,sl);
      crs = setTypesForScalarCrefs(crest,trest,cr1::crefsIn);
    then
      crs;
  case(DAE.CREF_ITER(ident=id,index=idx,identType=_,subscriptLst=sl)::crest, t1::trest, _)
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

public function getRecordScalars"gets all crefs from a record"
  input DAE.ComponentRef crefIn;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := matchcontinue(crefIn)
    local
  case(_)
    equation
      crefsOut = ComponentReference.expandCref(crefIn,true);
    then
      crefsOut;
  else
    then
      {};
  end matchcontinue;
end getRecordScalars;

protected function getScalarExpSize "gets the number of scalars of an expression.
author:Waurich TUD 2014-04"
  input DAE.Exp inExp;
  output Integer size;
algorithm
  size := match(inExp)
    local
      Boolean b;
      DAE.ComponentRef cref;
      list<Integer> sizes;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> exps;
      list<DAE.Var> vl;
      list<DAE.Type> tyl;
      list<list<DAE.Var>> vlLst;
      DAE.Type ty;
    case(DAE.TUPLE(exps))
      equation
        // tuple
        exps = List.filterOnTrue(exps,Expression.isNotWild);
        sizes = List.map(exps,getScalarExpSize);//check if the expressions are records or something
        size = List.fold(sizes,intAdd,0);
        size = intMax(size,listLength(exps));
        then
          size;
    case(DAE.CREF(componentRef=_,ty=DAE.T_COMPLEX(varLst=vl)))
      equation
        // record cref
        sizes = List.map(vl,getScalarVarSize);
        size = List.fold(sizes,intAdd,0);
        then
          size;
    case(DAE.CREF(componentRef=cref,ty=_))
      equation
        // array cref
        b = ComponentReference.isArrayElement(cref);
        crefs = Debug.bcallret2(b, ComponentReference.expandCref,cref,true,{cref});
        size = listLength(crefs);
        then
          size;
    case(DAE.CALL(path=_,expLst=_,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=vl),tuple_=_,builtin=_,isImpure=_,inlineType=_,tailCall=_)))
      equation
        sizes = List.map(vl,getScalarVarSize);
        size = List.fold(sizes,intAdd,0);
        then size;
    case(DAE.CALL(path=_,expLst=exps,attr=DAE.CALL_ATTR(ty=DAE.T_TUPLE(tupleType=tyl,source=_),tuple_=_,builtin=_,isImpure=_,inlineType=_,tailCall=_)))
      equation
        vlLst = List.map(tyl,getVarLstFromType);
        vl = List.flatten(vlLst);
        sizes = List.map(vl,getScalarVarSize);
        size = List.fold(sizes,intAdd,0);
        then size;
    else
      then 0;
  end match;
end getScalarExpSize;

protected function getVarLstFromType"gets the list of DAE.Var from a DAE.Type
author:Waurich TUD 2014-04"
  input DAE.Type tyIn;
  output list<DAE.Var> varsOut;
algorithm
  varsOut := match(tyIn)
    local
      list<DAE.Var> varLst;
      list<list<DAE.Var>> varLst2;
      list<DAE.Type> tyLst;
    case(DAE.T_TUPLE(tupleType=tyLst,source=_))
      equation
        varLst2 = List.map(tyLst,getVarLstFromType);
        varLst = List.flatten(varLst2);
        then
          varLst;
    case(DAE.T_COMPLEX(varLst = varLst))
      equation
        then
          varLst;
    case(DAE.T_SUBTYPE_BASIC(varLst = varLst))
      equation
        then
          varLst;
    else
      then
        {};
  end match;
end getVarLstFromType;

protected function getScalarVarSize "gets the number of scalars of an DAE.Var.
author:Waurich TUD 2014-04"
  input DAE.Var inVar;
  output Integer size;
algorithm
  size := matchcontinue(inVar)
    local
      DAE.Type ty;
      list<Integer> sizes;
      list<DAE.Exp> exps;
      list<DAE.Var> vl;
    case(DAE.TYPES_VAR(name=_,attributes=_,ty=DAE.T_COMPLEX(complexClassType=_,varLst=vl,equalityConstraint=_,source=_),binding=_,constOfForIteratorRange=_))
      equation
        sizes = List.map(vl,getScalarVarSize);
        size = List.fold(sizes,intAdd,0);
        then
          size;
    case(DAE.TYPES_VAR(name=_,attributes=_,ty=DAE.T_ARRAY(ty=_,dims=_,source=_),binding=_,constOfForIteratorRange=_))
      equation
        ty = DAEUtil.VarType(inVar);
        sizes = DAEUtil.expTypeArrayDimensions(ty);
        size = List.fold(sizes,intAdd,0);
        then
          size;
    else
    equation
      then
        1;
  end matchcontinue;
end getScalarVarSize;


// =============================================================================
// predict if statements
//
// =============================================================================

protected function evaluateFunctions_updateStatementEmptyRepl"replace and update the statements but start with an empty replacement.
author:Waurich TUD 2014-03"
  input list<DAE.Statement> algsIn;
  input tuple<DAE.FunctionTree,Integer> foldTplIn;
  output tuple<list<DAE.Statement>,BackendVarTransform.VariableReplacements> mapTplOut;
  output tuple<DAE.FunctionTree,Integer> foldTplOut;
protected
  Integer idx;
  BackendVarTransform.VariableReplacements repl;
  DAE.FunctionTree funcTree;
  list<DAE.Statement> algsOut;
algorithm
  (funcTree,idx) := foldTplIn;
  repl := BackendVarTransform.emptyReplacements();
  //print("start new evaluation with empty replacement\n"+&stringDelimitList(List.map(algsIn,DAEDump.ppStatementStr),"\n")+&"\n");
  (algsOut,(funcTree,repl,idx)) := evaluateFunctions_updateStatement(algsIn,(funcTree,repl,idx),{});
  //print("the new evaluated stmts wit empty repl \n"+&stringDelimitList(List.map(algsOut,DAEDump.ppStatementStr),"\n")+&"\n");
  foldTplOut := (funcTree,idx);
  mapTplOut := (algsOut,repl);
end evaluateFunctions_updateStatementEmptyRepl;

protected function predictIfOutput"evaluate outputs for all if/elseif/else and check if its constant at any time
author: Waurich TUD 2014-04"
  input DAE.Statement stmtIn;
  input FuncInfo infoIn;
  output tuple<list<DAE.Statement>,list<DAE.Statement>> stmtsOut;
  output FuncInfo infoOut;
algorithm
  (stmtsOut,infoOut) := matchcontinue(stmtIn,infoIn)
    local
      Boolean predicted;
      Integer idx;
      list<Integer> constantOutputs,idxLst;
      BackendVarTransform.VariableReplacements repl,replIn;
      list<BackendVarTransform.VariableReplacements> replLst;
      DAE.Else else_;
      DAE.Exp exp1;
      DAE.ElementSource source;
      DAE.FunctionTree funcTree;
      DAE.Statement stmtNew;
      list<DAE.ComponentRef> crefs,varCrefs, scalars;
      list<list<DAE.ComponentRef>> scalarLst;
      list<DAE.Exp> expLst,outExps,constOutExps,varOutExps, allLHS;
      list<list<DAE.Exp>> expLstLst;
      list<DAE.Statement> stmts1,addStmts;
      list<list<DAE.Statement>> stmtsLst;
      list<tuple<list<DAE.Statement>,BackendVarTransform.VariableReplacements>> tplLst;
    case(DAE.STMT_IF(exp=_, statementLst=stmts1, else_=else_),FUNCINFO(replIn,funcTree,idx))
       equation
         // get a list of all statements for each case
         stmtsLst = getDAEelseStatemntLsts(else_,{});
         stmtsLst = listReverse(stmtsLst);
         stmtsLst = stmts1::stmtsLst;
         //print("all stmts to predict: \n"+&stringDelimitList(List.map(List.flatten(stmtsLst),DAEDump.ppStatementStr),"\n")+&"\n");

         // replace with the already known stuff and build the new replacements
         repl = getOnlyConstantReplacements(replIn);
         (stmtsLst,_) = List.map4_2(stmtsLst,BackendVarTransform.replaceStatementLstRHS,repl,NONE(),{},false);
         //print("al stmts replaced: \n"+&stringDelimitList(List.map(List.flatten(stmtsLst),DAEDump.ppStatementStr),"\n")+&"\n");
         (tplLst,(funcTree,idx)) = List.mapFold(stmtsLst,evaluateFunctions_updateStatementEmptyRepl,(funcTree,idx));
         stmtsLst = List.map(tplLst,Util.tuple21);
         //print("all evaled stmts1: \n"+&stringDelimitList(List.map(List.flatten(stmtsLst),DAEDump.ppStatementStr),"---------\n")+&"\n");
         replLst = List.map(stmtsLst,collectReplacements);
         //replLst = List.map(replLst,getOnlyConstantReplacements);
         //List.map_0(replLst,BackendVarTransform.dumpReplacements);

         // get the outputs of every case
         expLst = List.fold(List.flatten(stmtsLst),getStatementLHS,{});
         expLst = List.unique(expLst);
         allLHS = listReverse(expLst);
         //print("the outputs: "+&stringDelimitList(List.map(allLHS,ExpressionDump.printExpStr),"\n")+&"\n");
         expLstLst = List.map1(replLst,replaceExps,allLHS);
         //print("the outputs replaced: \n"+&stringDelimitList(List.map(expLstLst,ExpressionDump.printExpListStr),"\n")+&"\n\n");

         // compare the constant outputs
         constantOutputs = compareConstantExps(expLstLst);
         outExps = List.map1(constantOutputs,List.getIndexFirst,allLHS);
         _ = List.map(outExps,Expression.expCref);
         //print("constantOutputs: "+&stringDelimitList(List.map(constantOutputs,intString),",")+&"\n");
         expLst = List.map1(constantOutputs,List.getIndexFirst,List.first(expLstLst));
         //print("the constant shared outputs: "+&stringDelimitList(List.map(expLst,ExpressionDump.printExpStr),"\n")+&"\n");
         //print("the constant shared output crefs: "+&stringDelimitList(List.map(outExps,ExpressionDump.printExpStr),"\n")+&"\n");
           Debug.bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"--> the predicted const outputs:\n"+&stringDelimitList(List.map(outExps,ExpressionDump.printExpStr),"\n"));
         (constOutExps,_,varOutExps) = List.intersection1OnTrue(outExps,allLHS,Expression.expEqual);

         predicted = List.isNotEmpty(constOutExps) and List.isEmpty(varOutExps);
         //repl = Debug.bcallret3(not predicted, BackendVarTransform.removeReplacements,replIn,varCrefs,NONE(),replIn);
         //Debug.bcall(not predicted,print,"remove the replacement for: "+&stringDelimitList(List.map(varCrefs,ComponentReference.crefStr),"\n")+&"\n");
         repl = replIn;
         // build the additional statements and update the old one
         addStmts = List.map2(List.intRange(listLength(outExps)),makeAssignmentMap,outExps,expLst);
         stmtNew = updateStatementsInIfStmt(stmtsLst,stmtIn);

         //print("the new predicted stmts: \n"+&stringDelimitList(List.map({stmtNew},DAEDump.ppStatementStr),"\n")+&"\nAnd the additional "+&stringDelimitList(List.map(addStmts,DAEDump.ppStatementStr),"\n")+&"\n");

         //repl = BackendVarTransform.addReplacements(replIn,crefs,expLst,NONE());
       then
         (({stmtNew},addStmts),FUNCINFO(repl,funcTree,idx));
   else
     equation
       then(({stmtIn},{}),infoIn);
  end matchcontinue;
end predictIfOutput;

protected function collectReplacements"gathers replacement rules for a given set of statements without updating them
author:Waurich TUD 2014-04"
  input list<DAE.Statement> stmtsIn;
  output BackendVarTransform.VariableReplacements replOut;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  replOut := collectReplacements1(stmtsIn,repl);
end collectReplacements;

protected function collectReplacements1"
author:Waurich TUD 2014-04"
  input list<DAE.Statement> stmtsIn;
  input BackendVarTransform.VariableReplacements replIn;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  replOut := matchcontinue(stmtsIn,replIn)
    local
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref;
      DAE.Exp lhs,rhs;
      DAE.Statement stmt;
      list<DAE.ComponentRef> crefs,constCrefs,varCrefs;
      list<DAE.Exp> lhsLst,rhsLst,constExps,varExps;
      list<DAE.Statement> rest;
    case({},_)
      equation
      then
        replIn;
    case(DAE.STMT_ASSIGN(type_=_,exp1=lhs,exp=rhs)::rest,_)
      equation
        (rhs,_) = BackendVarTransform.replaceExp(rhs,replIn,NONE());
        (rhs,_) = ExpressionSimplify.simplify(rhs);
        true = Expression.isConst(rhs);
        cref = Expression.expCref(lhs);
        repl = BackendVarTransform.addReplacement(replIn,cref,rhs,NONE());
        repl = collectReplacements1(rest,repl);
      then
        repl;
    case(DAE.STMT_TUPLE_ASSIGN(type_=_,expExpLst=lhsLst,exp=rhs,source=_)::rest,_)
      equation
        (rhs,_) = BackendVarTransform.replaceExp(rhs,replIn,NONE());
        (rhs,_) = ExpressionSimplify.simplify(rhs);
        rhsLst = Expression.getComplexContents(rhs);
        crefs = List.map(lhsLst,Expression.expCref);
        (constExps,constCrefs) = List.filterOnTrueSync(rhsLst,Expression.isConst,crefs);
        (varExps,varCrefs) = List.filterOnTrueSync(rhsLst,Expression.isNotConst,crefs);
        repl = BackendVarTransform.addReplacements(replIn,constCrefs,constExps,NONE());
        repl = BackendVarTransform.removeReplacements(repl,varCrefs,NONE());
        repl = collectReplacements1(rest,repl);
      then
        repl;
    case(stmt::rest,_)
      equation
        lhsLst = getStatementLHS(stmt,{});
        crefs = List.map(lhsLst,Expression.expCref);
        repl = BackendVarTransform.removeReplacements(replIn,crefs,NONE());
        repl = collectReplacements1(rest,repl);
      then
        repl;
    else
      equation
        print("collectReplacements failed\n");
      then
        fail();
  end matchcontinue;
end collectReplacements1;

protected function getOnlyConstantReplacements"removes replacement rules that do not have a constant expression as value
author:Waurich TUD 2014-04"
  input BackendVarTransform.VariableReplacements replIn;
  output BackendVarTransform.VariableReplacements replOut;
protected
  list<DAE.Exp> exps;
  list<DAE.ComponentRef> crefs;
  BackendVarTransform.VariableReplacements repl;
algorithm
  (crefs,exps) := BackendVarTransform.getAllReplacements(replIn);
  (exps,crefs) := List.filterOnTrueSync(exps,Expression.isConst,crefs);
  repl := BackendVarTransform.emptyReplacements();
  replOut := BackendVarTransform.addReplacements(repl,crefs,exps,NONE());
end getOnlyConstantReplacements;

protected function updateStatementsInIfStmt"replaces the statements in the if statement
author:Waurich TUD 2014-04"
  input list<list<DAE.Statement>> stmtLstIn;
  input DAE.Statement origIf;
  output DAE.Statement ifStmtOut;
algorithm
  ifStmtOut := match(stmtLstIn,origIf)
    local
      DAE.Else els;
      DAE.Exp exp;
      DAE.ElementSource source;
      list<DAE.Statement> stmts;
      list<list<DAE.Statement>> rest;
    case(stmts::rest,DAE.STMT_IF(exp=exp,statementLst=_,else_=els,source=source))
      equation
        els = updateStatementsInElse(rest,els);
      then
        DAE.STMT_IF(exp,stmts,els,source);
  end match;
end updateStatementsInIfStmt;

protected function updateStatementsInElse"replaces the statements in else
author:Waurich TUD 2014-04"
  input list<list<DAE.Statement>> stmtLstIn;
  input DAE.Else origElse;
  output DAE.Else elseOut;
algorithm
  elseOut := match(stmtLstIn,origElse)
    local
      DAE.Else els;
      DAE.Exp exp;
      DAE.ElementSource source;
      list<DAE.Statement> stmts;
      list<list<DAE.Statement>> rest;
    case(stmts::rest,DAE.ELSEIF(exp=exp,statementLst=_,else_=els))
      equation
        els = updateStatementsInElse(rest,els);
      then
        DAE.ELSEIF(exp,stmts,els);
    case(stmts::_,DAE.ELSE(statementLst=_))
      equation
      then
        DAE.ELSE(stmts);
    case(_::_,DAE.NOELSE())
      equation
      then
        DAE.NOELSE();
  end match;
end updateStatementsInElse;

protected function compareConstantExps "compares the lists of expressions if there are the same constants at the same position
author:Waurich TUD 2014-04"
  input list<list<DAE.Exp>> expLstLstIn;
  output list<Integer> posLstOut;
protected
  Integer num;
  list<Integer> idcs;
algorithm
  num := listLength(List.first(expLstLstIn));
  idcs := List.intRange(num);
  posLstOut := List.fold1(idcs,compareConstantExps2,expLstLstIn,{});
end compareConstantExps;

protected function compareConstantExps2
  input Integer idx;
  input list<list<DAE.Exp>> expLstLst;
  input list<Integer> posIn;
  output list<Integer> posOut;
protected
  Boolean b1,b2;
  list<Boolean> bLst;
  list<Integer> posLst;
  DAE.Exp firstExp;
  list<DAE.Exp> expLst,rest;
algorithm
  expLst := List.map1(expLstLst,listGet,idx);
  firstExp::rest := expLst;
  bLst := List.map(expLst,Expression.isConst);
  b1 := List.fold(bLst,boolAnd,true);
  bLst := List.map1(rest,Expression.expEqual,firstExp);
  b2 := List.fold(bLst,boolAnd,true);
  posLst := idx::posIn;
  posOut := Util.if_(b1 and b2,posLst,posIn);
end compareConstantExps2;

protected function makeAssignmentMap"mapping functino fo build the statements for a list of lhs and rhs exps.
author:Waurich TUD 2014-04"
  input Integer idx;
  input list<DAE.Exp> lhs;
  input list<DAE.Exp> rhs;
  output DAE.Statement stmt;
protected
  DAE.Exp e1,e2;
algorithm
  e1 := listGet(lhs,idx);
  e2 := listGet(rhs,idx);
  stmt := makeAssignment(e1,e2);
end makeAssignmentMap;

protected function makeAssignment"makes an DAE.STMT_ASSIGN of the 2 DAE.Exp"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output DAE.Statement stmtOut;
protected
  DAE.Type ty;
algorithm
  ty := Expression.typeof(rhs);
  stmtOut := DAE.STMT_ASSIGN(ty,lhs,rhs,DAE.emptyElementSource);
end makeAssignment;

// =============================================================================
// redeclare the varKinds (maybe some state candidates are vanished)
//
// =============================================================================

protected function updateVarKinds"if there is a variable declared as a state that is not longer present inside a der-call or selected as a state, change the status to VARIABLE
author:Waurich TUD 2014-04"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(eqs=systs,shared=shared) := inDAE;
  systs := List.map1(systs,updateVarKinds_eqSys,shared);
  outDAE := BackendDAE.DAE(systs,shared);
end updateVarKinds;

protected function updateVarKinds_eqSys"
author:Waurich TUD 2014-04"
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem sysOut;
protected
  BackendDAE.Variables vars;
  list<BackendDAE.Var> states,varLst,ssVarLst;
  BackendDAE.EquationArray eqs, initEqs;
  BackendDAE.StateSets stateSets;
  BackendDAE.Matching matching;
  list<DAE.ComponentRef> derVars,ssVars,derVarsInit;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqs,m=m,mT=mT,matching=matching,stateSets=stateSets,partitionKind=partitionKind) := sysIn;
  varLst := BackendVariable.varList(vars);
  initEqs := BackendEquation.getInitialEqnsFromShared(shared);
  states := List.filterOnTrue(varLst,BackendVariable.isStateorStateDerVar);
  ((_,derVarsInit)) := BackendDAEUtil.traverseBackendDAEExpsEqns(initEqs,Expression.traverseSubexpressionsHelper,(findDerVarCrefs,{}));
  ((_,derVars)) := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs,Expression.traverseSubexpressionsHelper,(findDerVarCrefs,derVarsInit));
    //print("derVars\n"+&stringDelimitList(List.map(derVars,ComponentReference.printComponentRefStr),"\n")+&"\n\n");
  ssVarLst := List.filterOnTrue(varLst,varSSisPreferOrHigher);
  ssVars := List.map(ssVarLst,BackendVariable.varCref);
    //print("ssVars\n"+&stringDelimitList(List.map(ssVars,ComponentReference.printComponentRefStr),"\n")+&"\n\n");
  derVars := listAppend(derVars,ssVars);
  derVars := List.unique(derVars);
  (vars,_) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,setVarKindForStates,derVars);
  sysOut := BackendDAE.EQSYSTEM(vars,eqs,m,mT,matching,stateSets,partitionKind);
end updateVarKinds_eqSys;

protected function varSSisPreferOrHigher"outputs true if the stateSelect attribute is prefer or always
author:Waurich TUD 2014-04"
  input BackendDAE.Var varIn;
  output Boolean ssOut;
protected
  Integer i;
  DAE.StateSelect ss;
algorithm
  ss := BackendVariable.varStateSelect(varIn);
  i := BackendVariable.stateSelectToInteger(ss);
  ssOut := intGe(i,2);
end varSSisPreferOrHigher;

protected function setVarKindForStates"if a state var is a memeber of the list of state-crefs, it remains a state. otherwise it will be changed to VarKind.Variable
waurich TUD 2014-04"
  input BackendDAE.Var inVar;
  input list<DAE.ComponentRef> inCrefs;
  output BackendDAE.Var outVar;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  (outVar,outCrefs) := matchcontinue (inVar,inCrefs)
    local
      Boolean isState;
      DAE.ComponentRef cr1;
      BackendDAE.Var varOld,varNew;
      list<DAE.ComponentRef> derVars;
    case (varOld as BackendDAE.VAR(varName=cr1,varKind=BackendDAE.STATE(index=_,derName=_)),derVars)
      equation
        isState = List.isMemberOnTrue(cr1,derVars,ComponentReference.crefEqual);
        varNew = Debug.bcallret2(not isState,BackendVariable.setVarKind,varOld,BackendDAE.VARIABLE(),varOld);
      then (varNew,derVars);
    else (inVar,inCrefs);
  end matchcontinue;
end setVarKindForStates;

protected function findDerVarCrefs "traverses all the sub expressions and searches for der(var)"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inCrefs;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  (outExp,outCrefs) := match(inExp,inCrefs)
    local
      DAE.ComponentRef cr;
      tuple<DAE.Exp,list<DAE.ComponentRef>> tpl;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),_)
       then (inExp,cr::inCrefs);
    else (inExp,inCrefs);
  end match;
end findDerVarCrefs;

// =============================================================================
// convert tuple equations to several single equations
//
// =============================================================================

protected function convertTupleEquations "author:Waurich TUD 2014-04
  converts an equation tupleExp=tupleExp to several simple equations of exp=const"
  input BackendDAE.Equation eqIn;
  input list<BackendDAE.Equation> addEqsIn;
  output BackendDAE.Equation eqOut;
  output list<BackendDAE.Equation> addEqsOut;
algorithm
  (eqOut, addEqsOut) := matchcontinue (eqIn, addEqsIn)
    local
      BackendDAE.Equation eq;
      DAE.Exp lhsExp, rhsExp;
      list<DAE.Exp> lhs, rhs;
      list<BackendDAE.Equation> eqs;

    case (BackendDAE.COMPLEX_EQUATION(left=lhsExp, right=rhsExp), _) equation
      DAE.TUPLE(lhs) = lhsExp;
      DAE.TUPLE(rhs) = rhsExp;
      eqs = makeBackendEquation(lhs, rhs, {});
      eq::eqs = eqs;
      eqs = listAppend(eqs, addEqsIn);
    then (eq, eqs);

    else
    then (eqIn, addEqsIn);
  end matchcontinue;
end convertTupleEquations;

protected function makeBackendEquation "author:Waurich TUD 2014-04
  builds backendEquations for the list of lhs-exps and rhs-exps"
  input list<DAE.Exp> ls;
  input list<DAE.Exp> rs;
  input list<BackendDAE.Equation> eqLstIn;
  output list<BackendDAE.Equation> eqLstOut;
algorithm
  eqLstOut := match(ls, rs, eqLstIn)
    local
      list<DAE.Exp> lrest;
      list<DAE.Exp> rrest;
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqLst;
      DAE.Exp l;
      DAE.Exp r;

    case ({}, {}, _)
    then eqLstIn;

    case (l::lrest, r::rrest, _) equation
      eq = BackendDAE.EQUATION(r, l, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
      eqLst = eq::eqLstIn;
      eqLst = makeBackendEquation(lrest, rrest, eqLst);
    then eqLst;
  end match;
end makeBackendEquation;

end EvaluateFunctions;
