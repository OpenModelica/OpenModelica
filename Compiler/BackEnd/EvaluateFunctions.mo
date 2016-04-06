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
// - evaluation of for-loops
// - evaluation of while-loops
// - evaluation of xOut := funcCall1(funcCall2(xIn[1]));  with funcCall2(xIn[1]) = xIn[1,2] for example have a look at Media.Examples.ReferenceAir.MoistAir
// - evaluation of BackendDAE.ARRAY_EQUATION
// =============================================================================

// =============================================================================
// type definitions
//
// =============================================================================

public uniontype FuncInfo "store informations when traversing the statements and evaluate the function calls"
  record FUNCINFO
    BackendVarTransform.VariableReplacements repl;
    DAE.FunctionTree funcTree;
    Integer idx;
  end FUNCINFO;
end FuncInfo;

public uniontype Variability
  record CONST end CONST;
    record VARIABLE end VARIABLE;
end Variability;

public uniontype CallSignature
  record SIGNATURE
    Absyn.Path path;
    list<Variability> inputsVari;//not scalar, take records, arrays, calls as a single input variability
    Boolean canBeEvaluated;
  end SIGNATURE;
end CallSignature;

// =============================================================================
// caching of already evaluated functions
//
// =============================================================================

protected function checkCallSignatureForExp
  input DAE.Exp expIn;
  input list<CallSignature> signLst;
  output Boolean continueEval;
protected
  CallSignature signature;
algorithm
  continueEval := true;
  signature := getCallSignatureForCall(expIn);
  if List.isMemberOnTrue(signature,signLst,callSignatureIsEqual) then
    SIGNATURE(canBeEvaluated = continueEval) := List.getMemberOnTrue(signature,signLst,callSignatureIsEqual);
  end if;
end checkCallSignatureForExp;

protected function callSignatureStr "outputs a string representation for the CallSignature"
  input CallSignature signat;
  output String str;
protected
   Absyn.Path path;
   list<Variability> varis;
   Boolean b;
algorithm
  SIGNATURE(path=path,inputsVari=varis, canBeEvaluated=b) := signat;
  str := Absyn.pathString(path)+"[ "+stringDelimitList(List.map(varis,VariabilityString)," | ")+" ] "+boolString(b);
end callSignatureStr;

protected function VariabilityString "outputs a string representation for the Variability"
  input Variability var;
  output String str;
algorithm
  str := match(var)
    case(CONST())
      then "CONST";
    else then "VARIABLE";
    end match;
end VariabilityString;

protected function callSignatureIsEqual"outputs true if 2 CallSignatures are equal"
  input CallSignature signat1;
  input CallSignature signat2;
  output Boolean isEqual;
protected
  Absyn.Path path1,path2;
  list<Variability> vari1,vari2;
algorithm
  SIGNATURE(path=path1, inputsVari=vari1) := signat1;
  SIGNATURE(path=path2, inputsVari=vari2) := signat2;
  isEqual := false;
  if Absyn.pathEqual(path1,path2) then
    if List.isEqualOnTrue(vari1,vari2,VariabilityIsEqual) then
      isEqual := true;
    end if;
  end if;
end callSignatureIsEqual;

protected function VariabilityIsEqual"outputs true if 2 Variabilites are equal"
  input Variability vari1;
  input Variability vari2;
  output Boolean isEqual;
algorithm
  isEqual := match(vari1,vari2)
    case(CONST(),CONST())
      then true;
    case(VARIABLE(),VARIABLE())
      then true;
    else
      then false;
   end match;
end VariabilityIsEqual;

protected function getCallSignatureForCall"determines the callSignature for a function call expression"
  input DAE.Exp callExpIn;
  output CallSignature signatureOut;
protected
  Absyn.Path path;
  list<DAE.Exp> expLst;
  list<Variability> vari;
algorithm
  try
    DAE.CALL(path=path, expLst=expLst) := callExpIn;
    vari := List.map(expLst,getVariabilityForExp);
    signatureOut := SIGNATURE(path,vari,true);
  else
    print("evalFunc.getCallSignatureForCall failed for :\n"+ExpressionDump.printExpStr(callExpIn)+"\n");
    fail();
  end try;
end getCallSignatureForCall;

protected function getVariabilityForExp"determines if the exp is either constant or variable"
  input DAE.Exp expIn;
  output Variability variOut;
algorithm
  variOut := match(expIn)
    local
      Variability vari;
  case(DAE.ICONST())
    then CONST();
  case(DAE.RCONST())
    then CONST();
  case(DAE.SCONST())
    then CONST();
  case(DAE.BCONST())
    then CONST();
  case(DAE.CLKCONST())
    then CONST();
  case(DAE.ENUM_LITERAL())
    then CONST();
  case(DAE.CREF())
    then VARIABLE();
  case(DAE.BINARY())
    equation
      if Expression.isConst(expIn) then
        vari = CONST();
      else
        vari=VARIABLE(); end if;
    then vari;
  case(DAE.UNARY())
   equation
      if Expression.isConst(expIn) then vari = CONST();
      else vari=VARIABLE(); end if;
    then vari;
  case(DAE.LBINARY())
    equation
      if Expression.isConst(expIn) then vari = CONST();
      else vari=VARIABLE(); end if;
    then vari;
  case(DAE.LUNARY())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.RELATION())
    then VARIABLE();
  case(DAE.IFEXP())
    then VARIABLE();
  case(DAE.CALL())
    then VARIABLE();
  case(DAE.RECORD())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.PARTEVALFUNCTION())
    then VARIABLE();
  case(DAE.ARRAY())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.MATRIX())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.RANGE())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.TUPLE())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.CAST())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.ASUB())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.TSUB())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.RSUB())
    equation
    if Expression.isConst(expIn) then vari = CONST();
    else vari=VARIABLE(); end if;
    then vari;
  case(DAE.SIZE())
    then VARIABLE();
  case(DAE.CODE())
    then VARIABLE();
  case(DAE.EMPTY())
    then VARIABLE();
  case(DAE.REDUCTION())
    then VARIABLE();
  else
     VARIABLE();
  end match;
end getVariabilityForExp;

// =============================================================================
// evaluate functions
//
// =============================================================================

public function evalFunctions "backend optmization module to evaluate functions completely or partially.
partial constant outputs are added as extra equations. Therefore removeSimpleEquations is necessary afterwards
author:Waurich TUD 2014-04"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  Boolean changed;
  BackendDAE.EqSystems eqSysts;
  BackendDAE.Shared shared;
algorithm
  try
    BackendDAE.DAE(eqs=eqSysts, shared=shared) := inDAE;
    (eqSysts, (shared, _, changed, _)) := List.mapFold(eqSysts, evalFunctions_main, (shared, 1, false, {}));
    //shared = evaluateShared(shared);

    if changed then
      outDAE := updateVarKinds(RemoveSimpleEquations.fastAcausal(BackendDAE.DAE(eqSysts, shared)));
    else
      outDAE := inDAE;
    end if;
  else
    outDAE := inDAE;
  end try;
end evalFunctions;

protected function evaluateShared "evaluate objects in the shared structure that could be dependent of a function. i.e. parameters
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
  sharedOut := BackendDAEUtil.setSharedKnVars(sharedIn,knVars);
end evaluateShared;

protected function evaluateParameter "evaluates a parameter"
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
        ((bindExp,_,_,_,_,_,_)) = evaluateConstantFunction(bindExp,bindExp,funcTree,1,{});
        ExpressionDump.dumpExp(bindExp);
      then
        varIn;
    else varIn;
  end matchcontinue;
end evaluateParameter;

protected function evalFunctions_main "traverses the eqSystems for function calls and tries to evaluate them"
  input BackendDAE.EqSystem eqSysIn;
  input tuple<BackendDAE.Shared,Integer,Boolean, list<CallSignature>> tplIn;
  output BackendDAE.EqSystem eqSysOut;
  output tuple<BackendDAE.Shared,Integer,Boolean, list<CallSignature>> tplOut;
protected
  Boolean changed;
  Integer sysIdx;
  BackendDAE.Shared sharedIn, shared;
  BackendDAE.EquationArray eqs;
  list<BackendDAE.Equation> eqLst, addEqs;
  list<CallSignature> callSign;
algorithm
  (sharedIn,sysIdx,changed,callSign) := tplIn;
  BackendDAE.EQSYSTEM(orderedEqs=eqs) := eqSysIn;
  eqLst := BackendEquation.equationList(eqs);

  //traverse the eqSystem for function calls
  (eqLst, (shared, addEqs, _, changed, callSign)) := List.mapFold(eqLst, evalFunctions_findFuncs, (sharedIn, {}, 1, changed, callSign));
  eqLst := listAppend(eqLst, addEqs);
  eqs := BackendEquation.listEquation(eqLst);
  eqSysOut := BackendDAEUtil.setEqSystEqs(eqSysIn, eqs);

  tplOut := (shared, sysIdx+1, changed, callSign);
end evalFunctions_main;

protected function evalFunctions_findFuncs "traverses the lhs and rhs exps of an equation and tries to evaluate function calls "
  input BackendDAE.Equation eqIn;
  input tuple<BackendDAE.Shared,list<BackendDAE.Equation>,Integer,Boolean, list<CallSignature>> tplIn;
  output BackendDAE.Equation eqOut;
  output tuple<BackendDAE.Shared,list<BackendDAE.Equation>,Integer,Boolean, list<CallSignature>> tplOut;
algorithm
  (eqOut,tplOut) := matchcontinue(eqIn,tplIn)
    local
      Integer idx;
      Boolean b1,b2,changed, changed1;
      BackendDAE.Equation eq;
      BackendDAE.EquationAttributes attr;
      BackendDAE.Shared shared;
      DAE.Exp exp1,exp2,lhsExp,rhsExp;
      DAE.ElementSource source;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> addEqs, addEqs1, addEqs2;
      list<DAE.Exp> lhs;
      list<CallSignature> callSign;
    case(BackendDAE.EQUATION(exp=exp1, scalar=exp2,source=source,attr=attr),_)
      equation
        b1 = Expression.containFunctioncall(exp1);
        b2 = Expression.containFunctioncall(exp2);
        true = b1 or b2;
        (shared,addEqs,idx,changed,callSign) = tplIn;
        funcs = BackendDAEUtil.getFunctions(shared);
        ((rhsExp,lhsExp,addEqs1,funcs,idx,changed1,callSign)) = if b1 then evaluateConstantFunction(exp1,exp2,funcs,idx,callSign) else (exp2,exp1,{},funcs,idx,changed,callSign);
        changed = changed1 or changed;
        ((rhsExp,lhsExp,addEqs2,funcs,idx,changed1,callSign)) = if b2 then evaluateConstantFunction(exp2,exp1,funcs,idx,callSign) else (rhsExp,lhsExp,{},funcs,idx,changed,callSign);
        changed = changed1 or changed;
        addEqs = listAppend(addEqs1,addEqs);
        addEqs = listAppend(addEqs2,addEqs);
        eq = BackendEquation.generateEquation(lhsExp,rhsExp,source,attr);
        //if changed then print("FROM EQ "+BackendDump.equationString(eqIn)+"\n");print("GOT EQ "+BackendDump.equationString(eq)+"\n"); end if;
      then
        (eq,(shared,addEqs,idx+1,changed,callSign));
    case(BackendDAE.ARRAY_EQUATION(),_)
      equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("this is an array equation. update evalFunctions_findFuncs\n");
        end if;
      then
        (eqIn,tplIn);
    case(BackendDAE.COMPLEX_EQUATION(left=exp1, right=exp2, source=source, attr=attr),_)
      equation
        b1 = Expression.containFunctioncall(exp1);
        b2 = Expression.containFunctioncall(exp2);
        true = b1 or b2;
        (shared,addEqs,idx,changed,callSign) = tplIn;
        funcs = BackendDAEUtil.getFunctions(shared);
        ((rhsExp,lhsExp,addEqs1,funcs,idx,changed1,callSign)) = if b1 then evaluateConstantFunction(exp1,exp2,funcs,idx,callSign) else (exp2,exp1,{},funcs,idx,changed,callSign);
        changed = changed or changed1;
        ((rhsExp,lhsExp,addEqs2,funcs,idx,changed1,callSign)) = if b2 then evaluateConstantFunction(exp2,exp1,funcs,idx,callSign) else (rhsExp,lhsExp,{},funcs,idx,changed,callSign);
        changed = changed or changed1;
        addEqs = listAppend(addEqs1,addEqs);
        addEqs = listAppend(addEqs2,addEqs);
        shared = BackendDAEUtil.setSharedFunctionTree(shared, funcs);
        eq = BackendEquation.generateEquation(lhsExp,rhsExp,source,attr);
        //since tuple=tuple is not supported, these equations are converted into a list of simple equations
        (eq,addEqs) = convertTupleEquations(eq,addEqs);
        //if changed then print("FROM EQ "+BackendDump.equationString(eqIn)+"\n");print("GOT EQ "+BackendDump.equationString(eq)+"\n"); end if;
      then
        (eq,(shared,addEqs,idx+1,changed,callSign));
    else
        (eqIn,tplIn);
  end matchcontinue;
end evalFunctions_findFuncs;

public function evaluateConstantFunctionCallExp"checks if the expression is a call and can be evaluated to a constant value.
the output is either a constant expression or the input exp. no partial evaluation is performed in here."
  input DAE.Exp expIn;
  input DAE.FunctionTree funcsIn;
  output DAE.Exp expOut;
algorithm
  expOut := matchcontinue(expIn,funcsIn)
    local
      Boolean hasAssert, hasReturn, hasTerminate, hasReinit, abort;
      Integer idx;
      Absyn.Path path;
      BackendVarTransform.VariableReplacements repl;
      DAE.CallAttributes attr1;
      DAE.Exp exp;
      DAE.Function func;
      DAE.FunctionTree funcs;
      list<DAE.ComponentRef> allInputCrefs, outputCrefs, allOutputCrefs, constInputCrefs, constCrefs, varScalarCrefsInFunc,constComplexCrefs,varComplexCrefs,varScalarCrefs,constScalarCrefs;
      list<list<DAE.ComponentRef>> scalarInputs, scalarOutputs;
      list<DAE.Element> elements, protectVars, algs, allInputs, allOutputs;
      list<DAE.Exp> exps, exps0, sub, allInputExps, constInputExps, constExps, constComplexExps, constScalarExps;
      list<list<DAE.Exp>> scalarExp;

  case(DAE.CALL(path=path, expLst=exps0, attr=attr1),_)
    equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("\nStart constant evaluation of expression: "+ExpressionDump.printExpStr(expIn)+"\n\n");
        end if;

        // get the elements of the function and the algorithms
        SOME(func) = DAE.AvlTreePathFunction.get(funcsIn,path);
        elements = DAEUtil.getFunctionElements(func);

        // get the input exps from the call
        exps = List.map1(exps0,evaluateConstantFunctionCallExp,funcsIn);
        scalarExp = List.map1(exps,expandComplexEpressions,funcsIn);
        allInputExps = List.flatten(scalarExp);
          //print("allInputExps\n"+stringDelimitList(List.map(allInputExps,ExpressionDump.printExpStr),"\n")+"\n");

        if listEmpty(elements) then  // its a record
        //-----------------------its a record-----------------------
          expOut = DAE.TUPLE(allInputExps);
          if Flags.isSet(Flags.EVAL_FUNC_DUMP) then print("\nIts a record.\n");
        end if;
        else
        //-----------------------its a function call-----------------------

        // get all input crefs (from function body) (scalar and one dimensioanl)
        allInputs = List.filterOnTrue(elements,DAEUtil.isInputVar);
        scalarInputs = List.map(allInputs,expandComplexElementsToCrefs);
        allInputCrefs = List.flatten(scalarInputs);
          //print("\nallInputCrefs\n"+stringDelimitList(List.map(allInputCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");

        protectVars = List.filterOnTrue(elements,DAEUtil.isProtectedVar);
        algs = List.filterOnTrue(elements,DAEUtil.isAlgorithm);
        algs = listAppend(protectVars,algs);

        // get all output crefs (complex and scalar)
        allOutputs = List.filterOnTrue(elements,DAEUtil.isOutputVar);
        outputCrefs = List.map(allOutputs,DAEUtil.varCref);
        scalarOutputs = List.map(allOutputs,getScalarsForComplexVar);
        allOutputCrefs = listAppend(outputCrefs,List.flatten(scalarOutputs));
        //print("\n allOutputs\n"+stringDelimitList(List.map(outputCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("\nscalarOutputs\n"+stringDelimitList(List.map(List.flatten(scalarOutputs),ComponentReference.printComponentRefStr),"\n")+"\n");

        // get the constant inputs
            //print("\nallInputExps\n"+stringDelimitList(List.map(allInputExps,ExpressionDump.printExpStr),"\n")+"\n");
            //print("\nall algs "+intString(listLength(algs))+"\n"+DAEDump.dumpElementsStr(algs)+"\n");
        (constInputExps,constInputCrefs) = List.filterOnTrueSync(allInputExps,Expression.isConst,allInputCrefs);
          //print("\nconstInputExps\n"+stringDelimitList(List.map(constInputExps,ExpressionDump.printExpStr),"\n")+"\n");
          //print("\nconstInputCrefs\n"+stringDelimitList(List.map(constInputCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
          //print("\nall algs "+intString(listLength(algs))+"\n"+DAEDump.dumpElementsStr(algs)+"\n");

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

        // go through all algorithms and replace the variables with constants if possible, extend the ht after each algorithm, consider bindings of protected vars as well
        (algs,(funcs,repl,idx)) = List.mapFold(algs,evaluateFunctions_updateAlgElements,(funcsIn,repl,1));
          //print("\nall algs after"+intString(listLength(algs))+"\n"+DAEDump.dumpElementsStr(algs)+"\n");
          //BackendVarTransform.dumpReplacements(repl);

        //get all replacements in order to check for constant outputs
        (constCrefs,constExps) = BackendVarTransform.getAllReplacements(repl);
        (constCrefs,constExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,allOutputCrefs,constExps); // extract outputs
        (constExps,constCrefs) = List.filterOnTrueSync(constExps,Expression.isConst,constCrefs); // extract constant outputs

          //print("all constant crefs \n"+stringDelimitList(List.map(constCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
          //print("all constant exps:\n"+ExpressionDump.printExpListStr(constExps)+"\n");

        // get the completely constant complex outputs, the constant parts of complex outputs and the variable parts of complex outputs and the expressions
        (constComplexCrefs,varComplexCrefs,constScalarCrefs,varScalarCrefs) = checkIfOutputIsEvaluatedConstant(allOutputs,constCrefs,{},{},{},{});
        constScalarExps = List.map1r(constScalarCrefs,BackendVarTransform.getReplacement,repl);
        constComplexExps = List.map1r(constComplexCrefs,BackendVarTransform.getReplacement,repl);
        (constScalarCrefs,constScalarExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constScalarCrefs,constExps);
        (constComplexCrefs,constComplexExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constComplexCrefs,constExps);

        //print("constComplexCrefs\n"+stringDelimitList(List.map(constComplexCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("varComplexCrefs\n"+stringDelimitList(List.map(varComplexCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("constScalarCrefs\n"+stringDelimitList(List.map(constScalarCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("varScalarCrefs\n"+stringDelimitList(List.map(varScalarCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");

        if listEmpty(varScalarCrefs) and listEmpty(varScalarCrefs) and listEmpty(constComplexCrefs) and not listEmpty(constScalarExps) then
        // there is a constant scalar expression
          if listLength(constScalarCrefs)==1 then expOut = listHead(constScalarExps);
          else expOut = DAE.TUPLE(constScalarExps); end if;
        elseif listEmpty(varScalarCrefs) and listEmpty(varScalarCrefs) and listEmpty(constScalarCrefs) and not listEmpty(constComplexExps) then
        // there is a constant complex expression
          if listLength(constComplexCrefs)==1 then expOut = listHead(constComplexExps);
          else expOut = DAE.TUPLE(constComplexExps); end if;
        else expOut = expIn;
        end if;
      end if;

      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
       print("\nevaluated to: "+ExpressionDump.printExpStr(expOut)+"\n\n");
      end if;

      then expOut;

  case(DAE.ASUB(DAE.CALL(path=path, expLst=exps, attr=attr1),sub),_)
    equation
      //this ASUB stuff occurs in the flattened DAE, check this special case because of removeSimpleEquations
     exp = evaluateConstantFunctionCallExp(DAE.CALL(path=path, expLst=exps, attr=attr1),funcsIn);
     (exp,_) = ExpressionSimplify.simplify(DAE.ASUB(exp,sub));
     if not Expression.isConst(exp) then exp = expIn; end if;
    then exp;

  else
  // could not evaluate it
   equation
    then expIn;
  end matchcontinue;
end evaluateConstantFunctionCallExp;


public function evaluateConstantFunction "Analyses if the rhsExp is a function call. the constant inputs are inserted and it will be checked if the outputs can be evaluated to a constant.
If the function can be completely evaluated, the function call will be removed.
If its partially constant, the constant assignments are added as additional equations and the former function will be replaced with an updated new one.
author: Waurich TUD 2014-04"
  input DAE.Exp rhsExpIn;
  input DAE.Exp lhsExpIn;
  input DAE.FunctionTree funcsIn;
  input Integer eqIdx;
  input list<CallSignature> callSignLstIn;
  output tuple<DAE.Exp, DAE.Exp, list<BackendDAE.Equation>, DAE.FunctionTree,Integer,Boolean, list<CallSignature>> outTpl;  //rhs,lhs,addEqs,funcTre,idx,haschanged
algorithm
  outTpl := matchcontinue(rhsExpIn,lhsExpIn,funcsIn,eqIdx,callSignLstIn)
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
      DAE.Type ty, singleOutputType;
      list<BackendDAE.Equation> constEqs;
      list<DAE.ComponentRef> inputCrefs, outputCrefs, allInputCrefs, allOutputCrefs, constInputCrefs, constCrefs, varScalarCrefsInFunc, constScalarCrefsOut,constComplexCrefs,varComplexCrefs,varScalarCrefs,constScalarCrefs;
      list<DAE.Element> elements, algs, allInputs, protectVars, allOutputs, updatedVarOutputs, newOutputVars;
      list<DAE.Exp> exps, expsIn, inputExps, complexExp, allInputExps, constInputExps, constExps, constComplexExps, constScalarExps, lhsExps, sub;
      list<list<DAE.Exp>> scalarExp;
      list<DAE.Statement> stmts;
      list<DAE.Type> outputVarTypes;
      list<String> outputVarNames;
      list<list<DAE.ComponentRef>> scalarInputs, scalarOutputs;
      CallSignature signature;
      list<CallSignature> callSignLst;
      Boolean continueEval;
    case(DAE.CALL(path=path, expLst=expsIn, attr=attr1),_,_,_,callSignLst)
      equation

        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("\nStart function evaluation of:\n"+ExpressionDump.printExpStr(lhsExpIn)+" := "+ExpressionDump.printExpStr(rhsExpIn)+"\n\n");
        end if;

        //------------------------------------------------
        //Check if this particular call signature has been analysed before
        //------------------------------------------------
          //print(stringDelimitList(List.map(callSignLst,callSignatureStr),"\n"));
        continueEval = checkCallSignatureForExp(rhsExpIn,callSignLst);
        if not continueEval and Flags.isSet(Flags.EVAL_FUNC_DUMP) then print("THIS FUNCTION CALL WITH THIS SPECIFIC SIGNATURE CANNOT BE EVALUTED\n"); end if;
        if not continueEval then fail(); end if;

        //------------------------------------------------
        //Collect all I/O Information for the function call
        //------------------------------------------------

        // get the elements of the function and the algorithms
        SOME(func) = DAE.AvlTreePathFunction.get(funcsIn,path);
        elements = DAEUtil.getFunctionElements(func);
        protectVars = List.filterOnTrue(elements,DAEUtil.isProtectedVar);
        algs = List.filterOnTrue(elements,DAEUtil.isAlgorithm);
        //algs = listAppend(protectVars,algs);
        //print("elements: "+DAEDump.dumpElementsStr(elements)+"\n");

        // some exceptions
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) and listEmpty(elements) then
          print("Its a Record!\n");
          false=true;
        elseif Flags.isSet(Flags.EVAL_FUNC_DUMP) and (listLength(protectVars)+listLength(algs)==0) then
          print("Its a Built-In!\n");
          false=true;
        end if;

        false = listEmpty(elements);  // its a record
        false = listEmpty(algs); // its a built in function

        // get the input exps from the call
        exps = List.map1(expsIn,evaluateConstantFunctionCallExp,funcsIn);
        scalarExp = List.map1(exps,expandComplexEpressions,funcsIn);//these exps are evaluated as well
        allInputExps = List.flatten(scalarExp);
          //print("allInputExps\n"+stringDelimitList(List.map(allInputExps,ExpressionDump.printExpStr),"\n")+"\n");

        // get all input crefs (from function body) (scalar and one dimensioanl)
        allInputs = List.filterOnTrue(elements,DAEUtil.isInputVar);
        scalarInputs = List.map(allInputs,expandComplexElementsToCrefs);
        allInputCrefs = List.flatten(scalarInputs);
          //print("\nallInputCrefs\n"+stringDelimitList(List.map(allInputCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");

        // get all output crefs (complex and scalar)
        allOutputs = List.filterOnTrue(elements,DAEUtil.isOutputVar);
        outputCrefs = List.map(allOutputs,DAEUtil.varCref);
        scalarOutputs = List.map(allOutputs,getScalarsForComplexVar);
        allOutputCrefs = listAppend(outputCrefs,List.flatten(scalarOutputs));
          //print("\ncomplex OutputCrefs\n"+stringDelimitList(List.map(outputCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
          //print("\nscalarOutputs\n"+stringDelimitList(List.map(List.flatten(scalarOutputs),ComponentReference.printComponentRefStr),"\n")+"\n");

        // get the constant inputs
        (constInputExps,constInputCrefs) = List.filterOnTrueSync(allInputExps,Expression.isConst,allInputCrefs);
          //print("\nallInputExps\n"+stringDelimitList(List.map(allInputExps,ExpressionDump.printExpStr),"\n")+"\n");
          //print("\nconstInputExps\n"+stringDelimitList(List.map(constInputExps,ExpressionDump.printExpStr),"\n")+"\n");
          //print("\nconstInputCrefs\n"+stringDelimitList(List.map(constInputCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
          //print("\nall algs "+intString(listLength(algs))+"\n"+DAEDump.dumpElementsStr(algs)+"\n");

        //------------------------------------------------
        //evaluate function call
        //------------------------------------------------

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
        (algs,(funcs,repl,idx)) = List.mapFold(algs,evaluateFunctions_updateAlgElements,(funcsIn,repl,eqIdx));
          //print("\nall algs after"+intString(listLength(algs))+"\n"+DAEDump.dumpElementsStr(algs)+"\n");
          //BackendVarTransform.dumpReplacements(repl);

        //get all replacements in order to check for constant outputs
        (constCrefs,constExps) = BackendVarTransform.getAllReplacements(repl);
        (constCrefs,constExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,allOutputCrefs,constExps); // extract outputs
        (constExps,constCrefs) = List.filterOnTrueSync(constExps,Expression.isConst,constCrefs); // extract constant outputs

        //print("all constant crefs \n"+stringDelimitList(List.map(constCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("all constant exps:\n"+ExpressionDump.printExpListStr(constExps)+"\n");

        // get the completely constant complex outputs, the constant parts of complex outputs and the variable parts of complex outputs and the expressions
        (constComplexCrefs,varComplexCrefs,constScalarCrefs,varScalarCrefs) = checkIfOutputIsEvaluatedConstant(allOutputs,constCrefs,{},{},{},{});
        (constScalarCrefs,constScalarExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constScalarCrefs,constExps);
        (constComplexCrefs,constComplexExps) = List.filter1OnTrueSync(constCrefs,ComponentReference.crefInLst,constComplexCrefs,constExps);

        //print("constComplexCrefs\n"+stringDelimitList(List.map(constComplexCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("varComplexCrefs\n"+stringDelimitList(List.map(varComplexCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("constScalarCrefs\n"+stringDelimitList(List.map(constScalarCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("varScalarCrefs\n"+stringDelimitList(List.map(varScalarCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");

        //------------------------------------------------
        //evaluate the result and build new function call accordingly
        //------------------------------------------------

        // is it completely constant or partially?
        funcIsConst = listEmpty(varScalarCrefs) and listEmpty(varComplexCrefs) and (not listEmpty(constScalarCrefs) or not listEmpty(constComplexCrefs));
        funcIsPartConst = ((not listEmpty(varScalarCrefs)) or (not listEmpty(varComplexCrefs))) and ((not listEmpty(constScalarCrefs)) or (not listEmpty(constComplexCrefs))) and not funcIsConst;
        isConstRec = intEq(listLength(constScalarCrefs),listLength(List.flatten(scalarOutputs))) and listEmpty(varScalarCrefs) and listEmpty(varComplexCrefs) and listEmpty(constComplexCrefs);

        //bcall1(isConstRec,print,"the function output is completely constant and its a record\n");
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          if funcIsConst then
            if hasAssert then
              print("the function output is completely constant but there is an assertion\n");
            else
              print("the function output is completely constant\n");
            end if;
          elseif not funcIsPartConst then
            print("the function output is not constant in any case\n");
          end if;
          if abort then
            print("the evaluated function is not used because there is a return or a terminate or a reinit statement\n");
          end if;
        end if;
        funcIsConst = if (hasAssert and funcIsConst) or abort then false else funcIsConst; // quit if there is a return or terminate or use partial evaluation if there is an assert
        funcIsPartConst = if hasAssert and funcIsConst then true else funcIsPartConst;
        funcIsPartConst = if abort then false else funcIsPartConst;  // quit if there is a return or terminate

        true =  funcIsPartConst or funcIsConst;

        signature = getCallSignatureForCall(rhsExpIn);
        signature.canBeEvaluated = true;
        callSignLst = signature::callSignLst;
        changed = funcIsPartConst or funcIsConst;

        // build the new lhs, the new statements for the function, the constant parts...
        (updatedVarOutputs,outputExp,varScalarCrefsInFunc) = buildVariableFunctionParts(scalarOutputs,constComplexCrefs,varComplexCrefs,constScalarCrefs,varScalarCrefs,allOutputs,lhsExpIn);
        (constScalarCrefsOut,constComplexCrefs) = buildConstFunctionCrefs(constScalarCrefs,constComplexCrefs,allOutputCrefs,lhsExpIn);
        //print("constScalarCrefsOut\n"+stringDelimitList(List.map(constScalarCrefsOut,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("constComplexCrefs\n"+stringDelimitList(List.map(constComplexCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");

        if not funcIsConst then
          (algs,constEqs) = buildPartialFunction((varScalarCrefsInFunc,algs),(constScalarCrefs,constScalarExps,constComplexCrefs,constComplexExps,constScalarCrefsOut),repl);
        else
          constEqs = {};
        end if;

        // build the new partial function
        elements = listAppend(protectVars,algs);
        elements = listAppend(updatedVarOutputs,elements);
        elements = listAppend(allInputs,elements);
        elements = List.unique(elements);
        (func,path) = updateFunctionBody(func,elements,idx, updatedVarOutputs, allOutputs);
        funcs = if funcIsPartConst then DAEUtil.addDaeFunction({func},funcs) else funcs;
        idx = if funcIsPartConst or funcIsConst then (idx+1) else idx;


        //decide which lhs to take (tuple or 1d)
        outputExp = if funcIsPartConst then outputExp else lhsExpIn;
        lhsExps = getCrefsForRecord(lhsExpIn);
        outputExp = if isConstRec then DAE.TUPLE(lhsExps) else outputExp;
        // which rhs
        newOutputVars = List.filterOnTrue(updatedVarOutputs,DAEUtil.isOutputVar);
        outputVarTypes = List.map(newOutputVars,DAEUtil.getVariableType);
        outputVarNames = List.map(newOutputVars,DAEUtil.varName);
        attr2 = DAEUtil.replaceCallAttrType(attr1,DAE.T_TUPLE(outputVarTypes,SOME(outputVarNames),DAE.emptyTypeSource));
        DAE.CALL_ATTR(ty = singleOutputType) = attr1;
        singleOutputType = if not listEmpty(newOutputVars) then listHead(outputVarTypes) else singleOutputType;//if the function is evaluated completely
        attr1 = DAEUtil.replaceCallAttrType(attr1,singleOutputType);
        attr2 = if intEq(listLength(newOutputVars),1) then attr1 else attr2;
        //DAEDump.dumpCallAttr(attr2);

        if List.hasOneElement(listAppend(constComplexExps,constScalarExps)) and funcIsConst then
          exp = listHead(listAppend(constComplexExps,constScalarExps)); // either a single equation
        elseif funcIsConst and not List.hasOneElement(listAppend(constComplexExps,constScalarExps)) then
          exp =  DAE.TUPLE(listAppend(constComplexExps,constScalarExps));// or a tuple equation
        else
          exp = rhsExpIn;
        end if;

        exp = if funcIsPartConst then DAE.CALL(path, expsIn, attr2) else exp;  //its partially constant and we have to keep a function call to calc the rest
        exp = if isConstRec then DAE.TUPLE(constScalarExps) else exp; // gather all constant record scalars in a tuple
        outputExp = setRecordTypes(outputExp);

          //BackendDump.dumpEquationList(constEqs,"the additional equations\n");
          //print("LHS EXP:\n");
          //ExpressionDump.dumpExp(outputExp);
          //print("RHS EXP:\n");
          //ExpressionDump.dumpExp(exp);
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("Finish evaluation:\n of: \n"+ExpressionDump.printExpStr(rhsExpIn)+"\nto:\n"+ExpressionDump.printExpStr(outputExp)+" := "+ExpressionDump.printExpStr(exp)+"\n");
          if not listEmpty(constEqs) then
            BackendDump.dumpEquationList(constEqs,"including the additional equations:\n");
          end if;
        end if;
      then
        ((exp,outputExp,constEqs,funcs,idx,changed,callSignLst));

  case(DAE.ASUB(DAE.CALL(path=path, expLst=exps, attr=attr1),sub),_,_,_,callSignLst)
    equation
      exp = DAE.CALL(path=path, expLst=exps, attr=attr1);

      //Check if this particular call signature has been analysed before
      continueEval = checkCallSignatureForExp(exp,callSignLst);
      if not continueEval and Flags.isSet(Flags.EVAL_FUNC_DUMP) then print("THIS FUNCTION CALL WITH THIS SPECIFIC SIGNATURE CANNOT BE EVALUTED\n"); end if;
      if not continueEval then fail(); end if;

      //this ASUB stuff occurs in the flattened DAE, check this special case because of removeSimpleEquations
      exp = evaluateConstantFunctionCallExp(exp,funcsIn);
      (exp,_) = ExpressionSimplify.simplify(DAE.ASUB(exp,sub));

      changed = true;
      if not Expression.isConst(exp) then
        exp = rhsExpIn;
        changed=false;
      end if;
    then ((exp,lhsExpIn,{},funcsIn,eqIdx,changed,callSignLst));

    else
      equation
        callSignLst = callSignLstIn;
        if Expression.isCall(rhsExpIn) then
          //Add a call signature for the call that could not been evaluated
          signature = getCallSignatureForCall(rhsExpIn);
          signature.canBeEvaluated = false;
          if not List.isMemberOnTrue(signature,callSignLstIn,callSignatureIsEqual) then
            callSignLst = signature::callSignLst;
          end if;
        end if;
      then ((rhsExpIn,lhsExpIn,{},funcsIn,eqIdx,false,callSignLst));
  end matchcontinue;
end evaluateConstantFunction;

protected function expandComplexEpressions "gets the complex contents or if its not complex, then the exp itself, if its a call, get the scalar outputs.
it would be possible to evaluate the exp before.
author:Waurich TUD 2014-05"
  input DAE.Exp e;
  input DAE.FunctionTree funcs;
  output list<DAE.Exp> eLst;
algorithm
  eLst := matchcontinue(e,funcs)
    local
      Absyn.Path path;
      DAE.Function func;
      list<DAE.Exp> lst;
      list<DAE.Element> elements, allOutputs;
    case(DAE.CALL(path=path, expLst=lst),_)
      equation
        SOME(func) = DAE.AvlTreePathFunction.get(funcs,path);
        elements = DAEUtil.getFunctionElements(func);
        if listEmpty(elements) then
        // its a record
          eLst = lst;
        else
       // its a call, get the scalar outputs
        SOME(func) = DAE.AvlTreePathFunction.get(funcs,path);
        elements = DAEUtil.getFunctionElements(func);
        allOutputs = List.filterOnTrue(elements,DAEUtil.isOutputVar);
        lst = List.map(List.flatten(List.map(allOutputs,getScalarsForComplexVar)),Expression.crefExp);
        end if;
      then
        lst;
    case(_,_)
      equation
        lst = Expression.getComplexContents(e);
        false = listEmpty(lst);
      then
        lst;
    else
      equation
        //print("Could not scalarize EXP:\n");
        //print(ExpressionDump.dumpExpStr(e,0)+"\n");
      then {e};
  end matchcontinue;
end expandComplexEpressions;

protected function expandComplexElementsToCrefs "gets the complex contents or if its not complex, then the element itself and converts them to crefs.
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

protected function hasAssertFold "fold function to check if a list of stmts has an assert.
author:Waurich TUD 2014-04"
  input DAE.Element stmt;
  input Boolean bIn;
  output Boolean bOut;
protected
  list<Boolean> bLst;
  list<DAE.Statement> stmtLst;
algorithm
  try
    stmtLst := DAEUtil.getStatement(stmt);
    bLst := List.map(stmtLst,DAEUtil.isStmtAssert);
    bOut := List.fold(bLst,boolOr,bIn);
  else
    bOut := false;
  end try;
end hasAssertFold;

protected function hasReturnFold "fold function to check if a list of stmts has an return stmt.
author:Waurich TUD 2014-04"
  input DAE.Element stmt;
  input Boolean bIn;
  output Boolean bOut;
protected
  list<Boolean> bLst;
  list<DAE.Statement> stmtLst;
algorithm
  try
    stmtLst := DAEUtil.getStatement(stmt);
    bLst := List.map(stmtLst,DAEUtil.isStmtReturn);
    bOut := List.fold(bLst,boolOr,bIn);
  else
    bOut := false;
  end try;
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
  try
    stmtLst := DAEUtil.getStatement(stmt);
    bLst := List.map(stmtLst,DAEUtil.isStmtReturn);
    bOut := List.fold(bLst,boolOr,bIn);
  else
    bOut := false;
  end try;
end hasReinitFold;

protected function setRecordTypes "This is somehow a hack for FourBitBinaryAdder because there are function calls in the daelow on the lhs of a function call and this leads to an error in simcode creation
they are used a s a cast for record types, but they should be a cast instead of a call, aren't they?
 func1(x) = func2(y).
 this function removes the call and sets the type
 author:Waurich TUD 2014-04"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      Integer idx;
      DAE.CallAttributes attr;
      DAE.ComponentRef cref;
      DAE.Exp exp1;
      list<DAE.Exp> expLst;
      DAE.FunctionTree funcTree;
      DAE.Type ty;
      BackendVarTransform.VariableReplacements repl;
    case(DAE.CALL(expLst=expLst,attr=DAE.CALL_ATTR(ty=ty)))
      equation
        true = Expression.isCall(inExp);
        true = listLength(expLst) == 1;
        exp1 = listHead(expLst);
        cref = Expression.expCref(exp1);
        exp1 = Expression.makeCrefExp(cref,ty);
      then exp1;
    case(DAE.TUPLE(PR=expLst))
      equation
        expLst = List.map(expLst,setRecordTypes);
      then DAE.TUPLE(expLst);
    else
    equation
      then inExp;
  end matchcontinue;
end setRecordTypes;

public function getCrefsForRecord "get all crefs of a record exp
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
    case(DAE.CREF(componentRef = cref))
      equation
        crefs = ComponentReference.expandCref(cref,true);
        expLst = List.map(crefs,Expression.crefExp);
      then
        expLst;
    else
      {};
  end match;
end getCrefsForRecord;

protected function scalarRecExpForOneDimRec "if the record contains only 1 scalar value, replace the scalar type definition with the record definition.
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
    case(DAE.CREF(componentRef=cref,ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(),varLst=varLst)))
      equation
        true = listLength(varLst)==1;
        DAE.CREF(componentRef=cref) = expIn;
        crefs = getRecordScalars(cref);
        true = listLength(crefs)==1;
        cref = listHead(crefs);
        exp = Expression.crefExp(cref);
      then exp;
    else
      expIn;
  end matchcontinue;
end scalarRecExpForOneDimRec;

protected function scalarRecCrefsForOneDimRec "replace a 1 dimensional record through its scalar value
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
        cref = listHead(crefs);
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
        varScalarExps = List.map1(pos,List.getIndexFirst,expLst);
        outputExp = if List.hasOneElement(varScalarExps) then listHead(varScalarExps) else DAE.TUPLE(varScalarExps);
        funcOutputs = List.map2(outputCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcProts = List.map2(protCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        varOutputs = listAppend(funcOutputs,funcProts);
      then (varOutputs,outputExp,varScalarCrefsInFunc);
    case(_,_,_,_,_,_,DAE.LBINARY())
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
        //print("\n allOutputCrefs \n"+stringDelimitList(List.map(allOutputCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("\n varScalarCrefsInFunc \n"+stringDelimitList(List.map(varScalarCrefsInFunc,ComponentReference.printComponentRefStr),"\n")+"\n");

        (protCrefs,_,outputCrefs) = List.intersection1OnTrue(listAppend(constComplexCrefs,constScalarCrefs),allOutputCrefs,ComponentReference.crefEqual);
        funcOutputs = List.map2(outputCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcProts = List.map2(protCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        varOutputs = listAppend(funcOutputs,funcProts);

        //the lhs-exp of the evaluated function call
        pos = List.map1(outputCrefs,List.position,allOutputCrefs);
        varScalarExps = List.map1(pos,List.getIndexFirst,expLst);
        varScalarExps = List.map(varScalarExps,scalarRecExpForOneDimRec);
        outputExp = if List.hasOneElement(varScalarExps) then listHead(varScalarExps) else DAE.TUPLE(varScalarExps);
      then (varOutputs,outputExp,varScalarCrefsInFunc);
    case(_,_,_,_,_,_,DAE.TUPLE(PR=expLst))
      equation
        true = listEmpty(List.flatten(scalarOutputs));
        true = not listEmpty(constScalarCrefs);
        varScalarCrefsInFunc = {};
        allOutputCrefs = List.map(allOutputs,DAEUtil.varCref);
        (protCrefs,_,outputCrefs) = List.intersection1OnTrue(constScalarCrefs,allOutputCrefs,ComponentReference.crefEqual);
        pos = List.map1(outputCrefs,List.position,allOutputCrefs);
        varScalarExps = List.map1(pos,List.getIndexFirst,expLst);
        outputExp = if List.hasOneElement(varScalarExps) then listHead(varScalarExps) else DAE.TUPLE(varScalarExps);
        funcOutputs = List.map2(outputCrefs,generateOutputElements,allOutputs,lhsExpIn);
        funcProts = List.map2(protCrefs,generateProtectedElements,allOutputs,lhsExpIn);
        varOutputs = listAppend(funcOutputs,funcProts);
      then (varOutputs,outputExp,varScalarCrefsInFunc);
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
        outputExp = if List.hasOneElement(varScalarExps) then listHead(varScalarExps) else DAE.TUPLE(varScalarExps);
      then
        (varOutputs,outputExp,varScalarCrefs);
    else
      equation
        print("buildVariableFunctionParts failed!\n");
        print("\n scalarOutputs \n"+stringDelimitList(List.map(List.flatten(scalarOutputs),ComponentReference.printComponentRefStr),"\n")+"\n");
        print("\n constScalarCrefs \n"+stringDelimitList(List.map(constScalarCrefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        print("\n allOutputs "+"\n"+DAEDump.dumpElementsStr(allOutputs)+"\n");
        print("\n lhsExpIn "+"\n"+ExpressionDump.dumpExpStr(lhsExpIn,0)+"\n");
      then
        fail();
  end matchcontinue;
end buildVariableFunctionParts;

protected function buildConstFunctionCrefs "builds the new crefs (for example the scalars from a record) for the constant functino outputs"
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
       constExps = List.map1(pos,List.getIndexFirst,expLst);
       constCrefs = List.map(constExps,Expression.expCref);
       then
         ({},constCrefs);
    else
       (constScalarCrefs,constComplCrefs);
  end matchcontinue;
end buildConstFunctionCrefs;

protected function checkIfOutputIsEvaluatedConstant
  input list<DAE.Element> elements "check this var";
  input list<DAE.ComponentRef> constCrefs;
  input list<DAE.ComponentRef> constComplexLstIn "completely constant complex or 1d vars";
  input list<DAE.ComponentRef> varComplexLstIn "variable complex or 1d vars";
  input list<DAE.ComponentRef> constScalarLstIn "partially constant complex var parts";
  input list<DAE.ComponentRef> varScalarLstIn "the variable part of the complex var";
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
      list<DAE.ComponentRef> scalars, constVars, varVars, partConstCrefs, varCrefs, constCrefs1;
      list<DAE.Element> rest;
      list<DAE.ComponentRef> constCompl, varCompl, varScalar, constScalar, constScalarCrefs;
    case({},_,_,_,_,_)
        then(constComplexLstIn,varComplexLstIn,constScalarLstIn,varScalarLstIn);
   case(elem::rest,_,_,_,_,_)
        //check if the given complext output cref appears in the constCrefs
        equation
          cref = DAEUtil.varCref(elem);
          //print("the cref\n"+stringDelimitList(List.map({DAEUtil.varCref(elem)},ComponentReference.printComponentRefStr),"\n")+"\n");
          (constVars,varVars,constCrefs1) = List.intersection1OnTrue({cref},constCrefs,ComponentReference.crefEqual);
          //print("constVars\n"+stringDelimitList(List.map(constVars,ComponentReference.printComponentRefStr),"\n")+"\n");
          if listEmpty(constVars) then
            //try again with the scalars
            scalars = getScalarsForComplexVar(elem);
            if listEmpty(scalars) then
              // has no scalars, the 1-d element is variable
              (constCompl,varCompl,constScalar,varScalar) = (constComplexLstIn,listAppend(varVars,varComplexLstIn),constScalarLstIn,varScalarLstIn);
            else
            // has scalars, some are variables some are constant
              (constVars,varVars,constCrefs1) = List.intersection1OnTrue(scalars,constCrefs,ComponentReference.crefEqual);
              (constCompl,varCompl,constScalar,varScalar) = (constComplexLstIn,varComplexLstIn,listAppend(constVars,constScalarLstIn),listAppend(varVars,varScalarLstIn));
            end if;
          else
            //this complex var has been found
            (constCompl,varCompl,constScalar,varScalar) = (listAppend(constVars,constComplexLstIn),varComplexLstIn,constScalarLstIn,varScalarLstIn);
          end if;
        (constCompl,varCompl,constScalar,varScalar) = checkIfOutputIsEvaluatedConstant(rest,constCrefs1,constCompl,varCompl,constScalar,varScalar);
      then (constCompl,varCompl,constScalar,varScalar);
    case(elem::rest,_,_,_,_,_)
      equation
        scalars = getScalarsForComplexVar(elem);
        // function outputs a record, its either constCompl or constScalar and varScalar
        //print("the cref\n"+stringDelimitList(List.map({DAEUtil.varCref(elem)},ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("scalars to check\n"+stringDelimitList(List.map(scalars,ComponentReference.printComponentRefStr),"\n")+"\n");

        false = listEmpty(scalars);
        constVars = List.intersectionOnTrue(scalars,constCrefs,ComponentReference.crefEqual);
        //print("constVars\n"+stringDelimitList(List.map(constVars,ComponentReference.printComponentRefStr),"\n")+"\n");

        const = intEq(listLength(scalars),listLength(constVars));
        constScalarCrefs = List.filter1OnTrue(constCrefs,ComponentReference.crefInLst,constVars);
        (_,varCrefs,_) = List.intersection1OnTrue(scalars,constScalarCrefs,ComponentReference.crefEqual);
        //constCompl = if_(const,cref::constComplexLstIn,constComplexLstIn);
        constCompl = if false then cref::constComplexLstIn else constComplexLstIn;
        //varCompl = if_(not const,cref::varComplexLstIn,varComplexLstIn);
        varCompl = varComplexLstIn;
        //constScalar = if_(not const,listAppend(constScalarCrefs,constScalarLstIn),constScalarLstIn);
        constScalar = if true then listAppend(constScalarCrefs,constScalarLstIn) else constScalarLstIn;

        varScalar = if not const then listAppend(varCrefs,varScalarLstIn) else varScalarLstIn;
        (constCompl,varCompl,constScalar,varScalar) = checkIfOutputIsEvaluatedConstant(rest,constCrefs,constCompl,varCompl,constScalar,varScalar);
      then
        (constCompl,varCompl,constScalar,varScalar);
    case(elem::rest,_,_,_,_,_)
      equation
        cref = DAEUtil.varCref(elem);
        scalars = getScalarsForComplexVar(elem);
        // function output is one dimensional
        true = listEmpty(scalars);
        const = listMember(cref,constCrefs);
        constCompl = if const then cref::constComplexLstIn else constComplexLstIn;
        varCompl = if not const then cref::varComplexLstIn else varComplexLstIn;
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
    case(DAE.CREF_QUAL(subscriptLst=sl),_,_)
      equation
        //print("generate output element\n");
        typ = ComponentReference.crefLastType(cref);
        cref1 = ComponentReference.crefStripLastIdent(cref);

        // if the record is only 1-dimensional, use the scalar value
        crefs = getRecordScalars(cref);
        cref1 = if intEq(listLength(crefs),1) then listHead(crefs) else cref1;

        // its not possible to use qualified output crefs
        i1 = ComponentReference.crefFirstIdent(cref);
        i2 = ComponentReference.crefLastIdent(cref);
        //print("the idents_ "+i1+"  and  "+i2+"\n");
        i1 = i1+"_"+i2;
        cref1 = ComponentReference.makeCrefIdent(i1,typ,sl);

        //print("the inFuncOutputs \n"+DAEDump.dumpElementsStr(inFuncOutputs)+"\n");
        //vars = List.map(inFuncOutputs,DAEUtil.varCref);
        //print("all the crefs of the oldoutputs\n"+stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr),",")+"\n");
        //(vars,oldOutputs2) = List.filter1OnTrueSync(vars,ComponentReference.crefEqual,cref1,inFuncOutputs);
        //var = listHead(oldOutputs2);
        var = listHead(inFuncOutputs);
        var = DAEUtil.replaceCrefandTypeInVar(cref1,typ,var);
        //print("the new var id \n"+DAEDump.dumpElementsStr({var})+"\n");
      then
        var;
    case(DAE.CREF_IDENT(identType=typ),_,_)
      equation
        var = listHead(inFuncOutputs);
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
    case(DAE.CREF_QUAL(subscriptLst=sl),_,_)
      equation
        typ = ComponentReference.crefLastType(cref);
        _ = Expression.crefExp(cref);
        i1 = ComponentReference.crefFirstIdent(cref);
        i2 = ComponentReference.crefLastIdent(cref);
        i1 = i1+"_"+i2;
        cref1 = ComponentReference.makeCrefIdent(i1,typ,sl);
        var = listHead(inFuncOutputs);
        var = DAEUtil.replaceCrefandTypeInVar(cref1,typ,var);
        var = DAEUtil.setElementVarVisibility(var,DAE.PROTECTED());
        var = DAEUtil.setElementVarDirection(var,DAE.BIDIR());
      then
        var;
    case(DAE.CREF_IDENT(identType=typ),_,_)
      equation
        var = listHead(inFuncOutputs);
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

protected function updateFunctionBody "udpates the function with the new elementsm update the type and create a new path name.
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
      SCode.Visibility visibility;
    case (DAE.FUNCTION(path,_,typ,visibility,pP,iI,iType,source,comment),_,_,_,_)
      equation
        //print("the pathname before: "+Absyn.pathString(path)+"\n");
        //print("THE FUNCTION BEFORE \n"+DAEDump.dumpFunctionStr(funcIn)+"\n");
        // assemble the path-name
        s = Absyn.pathString(path);
        chars = stringListStringChar(s);
        chars = listDelete(chars, 1);
        s = stringCharListString(chars);
        path = Absyn.stringPath(s+"_eval"+intString(idx));
        // update the type
        //print("the old type: "+Types.unparseType(typ)+"\n");
        typ = updateFunctionType(typ,outputs,origOutputs);
        //print("the new type: "+Types.unparseType(typ)+"\n");
        func = DAE.FUNCTION(path,{DAE.FUNCTION_DEF(body)},typ,visibility,pP,iI,iType,source,comment);
        //print("THE FUNCTION AFTER \n"+DAEDump.dumpFunctionStr(func)+"\n");
        //print("the pathname after: "+Absyn.pathString(path)+"\n");
      then (func,path);
    else
      equation
        print("updateFunctionBody failed \n");
        then
          fail();
  end match;
end updateFunctionBody;

protected function updateFunctionType "sets the resultTypes in the functionType
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
      list<String> outNames;
  case(DAE.T_FUNCTION(funcArg = inputs, funcResultType = outType, functionAttributes = atts, source = source),_,_)
    equation
      //print("the out types1: "+Types.unparseType(outType)+"\n");
      outTypeLst = list(DAEUtil.getVariableType(o) for o in outputs);
      outNames = list(DAEUtil.varName(o) for o in outputs);
      outType = if intEq(listLength(outTypeLst),1) then listHead(outTypeLst) else DAE.T_TUPLE(outTypeLst,SOME(outNames),DAE.emptyTypeSource);
      outType = DAE.T_FUNCTION(inputs,outType,atts,source);
      //print("the out types2: "+Types.unparseType(outType)+"\n");
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
  funcAlgs := List.filterOnTrue(funcAlgs,DAEUtil.isAlgorithm);// get only the algs, not protected vars or stuff
  // generate the additional equations for the constant scalar values and the constant complex ones
  lhsExps1 := List.map(constScalarCrefsOut,Expression.crefExp);
  lhsExps2 := List.map(constComplCrefs,Expression.crefExp);
  eqsOut := generateConstEqs(lhsExps1,constScalarExps,{});
  eqsOut := generateConstEqs(lhsExps2,constComplExps,eqsOut);

  // build the partial function algorithm, replace the qualified crefs
  stmts1 := List.mapFlatReverse(funcAlgs, DAEUtil.getStatement);
  //stmts1 := List.filterOnTrue(stmts1,statementRHSIsNotConst);
  // remove the constant values
  //stmts1 := traverseStmtsAndUpdate(stmts1,stmtCanBeRemoved,replIn,{});
  // stmts1 := listReverse(stmts1);

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
    case(DAE.STMT_ASSIGN(exp1=e1,exp=e2),_)
      equation
        ({stmt},_) = BackendVarTransform.replaceStatementLst({stmtIn},repl,NONE(),{},false);
        DAE.STMT_ASSIGN(exp1=e1,exp=e2) = stmt;
        b1 = Expression.isConst(e1);
        b2 = Expression.isConst(e2);
        //stmt = if_(b1,stmtIn,stmt);
        stmt = stmtIn;
      then
        ((stmt,b1 and b2));
    else
      then
        ((stmtIn,false));
  end matchcontinue;
end stmtCanBeRemoved;

protected function traverseStmtsAndUpdate "traverses all assign-statements. the stmts can be updated with the given function.
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
    case (DAE.STMT_IF(statementLst=stmtLst, else_=else_)::rest,_,_,_)
      equation
        x = listHead(stmtsIn);
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
        xs = if b then stmtsFold else x::stmtsFold;
        xs = traverseStmtsAndUpdate(rest,func,argIn,xs);
      then
        xs;
  end matchcontinue;
end traverseStmtsAndUpdate;

protected function makeIdentCref "searches only for crefs"
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

protected function makeIdentCref2 "appends the crefs of a qualified crefs with the given delimiter
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
    case(cref1 as DAE.CREF_QUAL(ident=i1,componentRef=cref2),_)
      equation
        true = List.isMemberOnTrue(cref1,changeTheseCrefs,ComponentReference.crefEqual);
        i2 = ComponentReference.crefFirstIdent(cref2);
        i1 = i1+"_"+i2;
        cref2 = replaceCrefIdent(cref2,i1);
        cref2 = makeIdentCref2(cref2,changeTheseCrefs);
      then
        cref2;
    case(cref1 as DAE.CREF_IDENT(),_)
      then
        cref1;
    else
      crefIn;
  end matchcontinue;
end makeIdentCref2;

protected function replaceCrefIdent "replaces the ident of a cref
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
    case(DAE.CREF_QUAL(identType=typ,subscriptLst=sl,componentRef=cref2),_)
      equation
        cref = DAE.CREF_QUAL(ident,typ,sl,cref2);
      then
        cref;
    case(DAE.CREF_IDENT(identType=typ,subscriptLst=sl),_)
      equation
        cref = DAE.CREF_IDENT(ident,typ,sl);
      then
        cref;
    else
      then
        crefIn;
  end match;
end replaceCrefIdent;

protected function statementRHSIsNotConst "checks whether the rhs of a statement is not constant.
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
    case(DAE.STMT_ASSIGN(exp=rhs))
      equation
        b = Expression.isConst(rhs);
      then
        not b;
    else
        true;
  end match;
end statementRHSIsNotConst;

protected function generateConstEqs "generate a list of BackendDAE.EQUATION.
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

protected function addReplacementRuleForAssignment "add a replacement rule according to the simple assigment like cref = const."
  input DAE.Statement stmt;
  input BackendVarTransform.VariableReplacements replIn;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  replOut := match(stmt,replIn)
    local
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref;
      DAE.Exp lhs,rhs;
    case(DAE.STMT_ASSIGN(exp1=lhs,exp=rhs),_)
      equation
        cref = Expression.expCref(lhs);
        repl = BackendVarTransform.addReplacement(replIn,cref,rhs,NONE());
      then
        repl;
    else
      then replIn;
  end match;
end addReplacementRuleForAssignment;

protected function evaluateFunctions_updateAlgElements "gets the statements from an algorithm in order to traverse them and tries to evaluate the binding expressions from protected vars.
author:Waurich TUD 2014-03"
  input DAE.Element algIn;
  input tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements,Integer> tplIn;
  output DAE.Element algOut;
  output tuple<DAE.FunctionTree, BackendVarTransform.VariableReplacements,Integer> tplOut;
algorithm
  (algOut,tplOut) := matchcontinue(algIn,tplIn)
    local
      Integer i;
      BackendVarTransform.VariableReplacements repl;
      DAE.Algorithm alg;
      DAE.ElementSource source;
      DAE.Exp exp;
      DAE.FunctionTree funcs;
      DAE.ComponentRef cref;
      list<DAE.Statement> stmts;
      list<DAE.Exp> scalarExps;
      list<DAE.ComponentRef> scalars;
  case(DAE.ALGORITHM(alg,source),_)
    equation
      stmts = DAEUtil.getStatement(algIn);
      (stmts,tplOut) = evaluateFunctions_updateStatement(stmts,tplIn,{});
      alg = DAE.ALGORITHM_STMTS(stmts);
    then (DAE.ALGORITHM(alg,source),tplOut);

  case(DAE.VAR(componentRef=cref,binding=SOME(exp)),(funcs,repl,i))
    equation
        //print("VARIN1 "+DAEDump.dumpElementsStr({algIn})+"\n");
      (exp,_) = BackendVarTransform.replaceExp(exp, repl,NONE());
      (exp,_) = ExpressionSimplify.simplify(exp);
      if Expression.isConst(exp) then
        //add replacement for complex and scalar values
        repl = BackendVarTransform.addReplacement(repl,cref,exp,NONE());
        scalars = ComponentReference.expandCref(cref,false);
        scalarExps = Expression.getComplexContents(exp);
        if listLength(scalars)==listLength(scalarExps) then
          repl = BackendVarTransform.addReplacements(repl,scalars,scalarExps,NONE());
        end if;
      end if;

      //print("bind "+ExpressionDump.printExpStr(exp)+"\n");
      //update binding in var
    then (DAEUtil.replaceBindungInVar(exp,algIn),(funcs,repl,i));

  case(DAE.VAR(componentRef=cref,binding=NONE()),(funcs,repl,i))
    equation
      //print("VARIN2 "+DAEDump.dumpElementsStr({algIn})+"\n");
    then (algIn,tplIn);

  else
    equation
      //print("unknown type in evaluateFunctions_updateAlgElements "+DAEDump.dumpElementsStr({algIn})+"\n");
    then(algIn,tplIn);
  end matchcontinue;
end evaluateFunctions_updateAlgElements;

protected function unboxExp
"takes an expression and unboxes it if it is boxed"
  input DAE.Exp ie;
  input Boolean bIn;
  output DAE.Exp outExp;
  output Boolean bOut;
algorithm
  (outExp, bOut) := match (ie,bIn)
    local
      DAE.Exp e;
    case (DAE.BOX(e),_) then unboxExp(e,true);
    else (ie,bIn);
  end match;
end unboxExp;

protected function evaluateFunctions_updateStatement "replaces the statements with regards to the given varReplacements and check for constant assignments.
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
      DAE.Exp exp0, exp1, exp2, range, cond, msg, lvl;
      DAE.Else else_;
      DAE.FunctionTree funcTree,funcTree2;
      DAE.Statement alg, alg2;
      DAE.Type typ;
      list<BackendDAE.Equation> addEqs;
      list<DAE.ComponentRef> scalars, varScalars,constScalars, outputs, initOutputs;
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
          //print("the STMT_ASSIGN before: "+DAEDump.ppStatementStr(listHead(algsIn)));
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("assignment:\n"+DAEDump.ppStatementStr(listHead(algsIn)));
        end if;
        cref = Expression.expCref(exp1);
        scalars = getRecordScalars(cref);
        (exp2,_) = BackendVarTransform.replaceExp(exp2,replIn,NONE());
        (exp2,_) = ExpressionSimplify.simplify(exp2);

        (exp2,(exp1,funcTree,idx,addStmts)) = Expression.traverseExpTopDown(exp2,evaluateConstantFunctionWrapper,(exp1,funcTree,idx,{}));

        // (exp2,changed) = bcallret1_2(changed,ExpressionSimplify.simplify,exp2,exp2,changed); This does nothing useful with the statement below...
        (exp2,_) = ExpressionSimplify.simplify(exp2);
        (exp2,_) = Expression.traverseExpBottomUp(exp2,unboxExp,false);// for metamodelica/meta/omc
        expLst = Expression.getComplexContents(exp2);

        // add the replacements for the addStmts and remove the replacements for the variable outputs
        repl = List.fold(addStmts,addReplacementRuleForAssignment,replIn);
        lhsExps = Expression.getComplexContents(exp1);
        outputs = List.map(lhsExps,Expression.expCref);
        BackendVarTransform.removeReplacements(repl,outputs,NONE());

        // check if its constant, a record or a tuple
        isCon = Expression.isConst(exp2) and not Expression.isCall(exp2);
        eqDim = listLength(scalars) == listLength(expLst);  // so it can be partly constant
        isRec = ComponentReference.isRecord(cref) or Expression.isRecordCall(exp2,funcTree);
        isTpl = Expression.isTuple(exp1) and Expression.isTuple(exp2);
        //print("is it const? "+boolString(isCon)+" ,is it rec: "+boolString(isRec)+" ,is it tpl: "+boolString(isTpl)+"\n");

        // remove the variable crefs and add the constant crefs to the replacements
        //print("scalars\n"+stringDelimitList(List.map(scalars,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("expLst\n"+stringDelimitList(List.map(expLst,ExpressionDump.printExpStr),"\n")+"\n");
        scalars = if isRec and eqDim then scalars else {};
        expLst = if isRec and eqDim then expLst else {};
        (_,varScalars) = List.filterOnTrueSync(expLst,Expression.isNotConst,scalars);
        (expLst,constScalars) = List.filterOnTrueSync(expLst,Expression.isConst,scalars);
        //print("variable scalars\n"+stringDelimitList(List.map(varScalars,ComponentReference.printComponentRefStr),"\n")+"\n");
        //BackendVarTransform.dumpReplacements(replIn);

        repl = if isCon and not isRec then BackendVarTransform.addReplacement(repl,cref,exp2,NONE()) else repl;
        repl = if isCon and isRec then BackendVarTransform.addReplacements(repl,scalars,expLst,NONE()) else repl;
        if not isCon then
          if not isRec then
            BackendVarTransform.removeReplacement(repl,cref,NONE());
          else
            BackendVarTransform.removeReplacements(repl,varScalars,NONE());
            repl = BackendVarTransform.addReplacements(repl,constScalars,expLst,NONE());
          end if;
        end if;

        //bcall(isCon and not isRec,print,"add the replacement: "+ComponentReference.crefStr(cref)+" --> "+ExpressionDump.printExpStr(exp2)+"\n");
        //bcall(not isCon,print,"update the replacement for: "+ComponentReference.crefStr(cref)+"\n");
        //BackendVarTransform.dumpReplacements(repl);

        // build the new statements
        alg = if isCon then DAE.STMT_ASSIGN(typ,exp1,exp2,source) else listHead(algsIn);
        tplExpsLHS = if isTpl then Expression.getComplexContents(exp1) else {};
        tplExpsRHS = if isTpl then Expression.getComplexContents(exp2) else {};
        tplStmts = List.map2(List.intRange(listLength(tplExpsLHS)),makeAssignmentMap,tplExpsLHS,tplExpsRHS);
        //alg = if_(isTpl,DAE.STMT_TUPLE_ASSIGN(typ,tplExpsLHS,exp2,source),alg);
        stmts1 = if isTpl then tplStmts else {alg};
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("evaluated assignment to:\n"+stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+"\n");
        end if;

        //stmts1 = alg::lstIn;
        stmts1 = listAppend(stmts1,lstIn);
        //print("\nthe traverse LIST after :"+stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+"\n");
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts1);
      then (rest,tplOut);
    case (DAE.STMT_ASSIGN_ARR(type_=typ, lhs=exp1, exp=exp2, source=source)::rest,(funcTree,replIn,idx),_)
      equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("Array assignment:\n"+DAEDump.ppStatementStr(listHead(algsIn)));
        end if;
        // replace, evaluate, simplify the assignment
       //print("the STMT_ASSIGN_ARR before: "+DAEDump.ppStatementStr(listHead(algsIn)));
        cref = Expression.expCref(exp1);
        scalars = getRecordScalars(cref);
        (exp2,_) = BackendVarTransform.replaceExp(exp2,replIn,NONE());
        (exp2,(exp1,funcTree,idx,addStmts)) = Expression.traverseExpTopDown(exp2,evaluateConstantFunctionWrapper,(exp1,funcTree,idx,{}));
        // (exp2,changed) = bcallret1_2(changed,ExpressionSimplify.simplify,exp2,exp2,changed); This does nothing useful with the statement below...
        (exp2,_) = ExpressionSimplify.simplify(exp2);
        expLst = Expression.getComplexContents(exp2);
        //print("SIMPLIFIED\n"+stringDelimitList(List.map({exp2},ExpressionDump.printExpStr),"\n")+"\n");

        // add the replacements for the addStmts and remove the replacements for the variable outputs
        repl = List.fold(addStmts,addReplacementRuleForAssignment,replIn);
        lhsExps = Expression.getComplexContents(exp1);
        outputs = List.map(lhsExps,Expression.expCref);
        BackendVarTransform.removeReplacements(repl,outputs,NONE());

        // check if its constant, a record or a tuple
        isCon = Expression.isConst(exp2) and not Expression.isCall(exp2);
        eqDim = listLength(scalars) == listLength(expLst);  // so it can be partly constant
        isRec = ComponentReference.isRecord(cref);
        isArr = ComponentReference.isArrayElement(cref);
        isTpl = Expression.isTuple(exp1) and Expression.isTuple(exp2);
          //print("is it const? "+boolString(isCon)+" ,is it rec: "+boolString(isRec)+" ,is it tpl: "+boolString(isTpl)+" ,is it arr: "+boolString(isArr)+"\n");

        // remove the variable crefs and add the constant crefs to the replacements
        scalars = if (isRec or isArr) and eqDim then scalars else {};
        expLst = if (isRec or isArr) and eqDim then expLst else {};
        (_,varScalars) = List.filterOnTrueSync(expLst,Expression.isNotConst,scalars);
        (expLst,constScalars) = List.filterOnTrueSync(expLst,Expression.isConst,scalars);
        //print("scalars\n"+stringDelimitList(List.map(scalars,ComponentReference.printComponentRefStr),"\n")+"\n");
        //print("expLst\n"+stringDelimitList(List.map(expLst,ExpressionDump.printExpStr),"\n")+"\n");
        //print("variable scalars\n"+stringDelimitList(List.map(varScalars,ComponentReference.printComponentRefStr),"\n")+"\n");

        repl = if isCon and not isRec then BackendVarTransform.addReplacement(repl,cref,exp2,NONE()) else repl;
        repl = if isCon and isRec then BackendVarTransform.addReplacements(repl,scalars,expLst,NONE()) else repl;
        repl = if isCon and isArr then BackendVarTransform.addReplacements(repl,scalars,expLst,NONE()) else repl;
        if not isCon then
          if not isRec then
            BackendVarTransform.removeReplacement(repl,cref,NONE());
          else
            BackendVarTransform.removeReplacements(repl,varScalars,NONE());
            repl = BackendVarTransform.addReplacements(repl,constScalars,expLst,NONE());
          end if;
        end if;

        //bcall(isCon and not isRec,print,"add the replacement: "+ComponentReference.crefStr(cref)+" --> "+ExpressionDump.printExpStr(exp2)+"\n");
        //bcall(not isCon,print,"update the replacement for: "+ComponentReference.crefStr(cref)+"\n");
        //BackendVarTransform.dumpReplacements(repl);

        // build the new statements
        alg = if isCon then DAE.STMT_ASSIGN(typ,exp1,exp2,source) else listHead(algsIn);
        tplExpsLHS = if isTpl then Expression.getComplexContents(exp1) else {};
        tplExpsRHS = if isTpl then Expression.getComplexContents(exp2) else {};
        tplStmts = List.map2(List.intRange(listLength(tplExpsLHS)),makeAssignmentMap,tplExpsLHS,tplExpsRHS);
        stmts1 = if isTpl then tplStmts else {alg};
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("evaluated array assignment to:\n"+stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+"\n");
        end if;

        //stmts1 = alg::lstIn;
        stmts1 = listAppend(stmts1,lstIn);
        //print("\nthe traverse LIST after :"+stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+"\n");
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts1);
      then (rest,tplOut);
    case(DAE.STMT_IF(statementLst=stmtsIf, else_=else_)::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("IF-statement:\n"+DAEDump.ppStatementStr(alg));
        end if;

        // get all stmts in the function and the assigned crefs (need the outputs in order to remove the replacements if nothing can be evaluated)
        stmtsLst = getDAEelseStatemntLsts(else_,{});
        stmtsLst = listReverse(stmtsLst);
        stmtsLst = stmtsIf::stmtsLst;
        allStmts = List.flatten(stmtsLst);
        lhsExps = List.fold1(allStmts,getStatementLHSScalar,funcTree,{});
        lhsExps = List.unique(lhsExps);
        outputs = List.map(lhsExps,Expression.expCref);

        //check if the conditions can be evaluated, get evaluated stmts
        (isEval,stmts1,repl) = evaluateIfStatement(alg,FUNCINFO(replIn,funcTree,idx));

        // if its not definite which case, try to predict a constant output, maybe its partially constant, then remove function outputs replacements
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isEval then
          print("-->try to predict the outputs \n");
        end if;
        if not isEval then
          ((stmtsNew,addStmts),FUNCINFO(repl,funcTree,idx)) = predictIfOutput(alg,FUNCINFO(repl,funcTree,idx));
        else
          stmtsNew = stmts1;
          addStmts = {};
          //repl = replIn;
        end if;
        predicted = (not listEmpty(addStmts)) or listEmpty(stmtsNew) and not isEval;
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isEval then
          print("could it be predicted? "+boolString(predicted)+"\n");
        end if;

        // if nothing can be done, remove the replacements for the variables assigned in the if stmt
        if not predicted and not isEval then
          BackendVarTransform.removeReplacements(repl,outputs,NONE());
        end if;
        //print("REMOVE THE REPLACEMENTS\n"+stringDelimitList(List.map(outputs,ComponentReference.printComponentRefStr),"\n")+"\n");

        //stmts1 = if_(simplified and isCon, listAppend(stmts1,addStmts), stmts1);

        stmts1 = if predicted then stmtsNew else stmts1;
        rest = listAppend(addStmts,rest);

        //BackendVarTransform.dumpReplacements(repl);

        //print("the STMT_IF after: \n"+stringDelimitList(List.map(listAppend(stmts1,addStmts),DAEDump.ppStatementStr),"\n")+"\n");
        //print("\nthe REST if after :"+stringDelimitList(List.map(rest,DAEDump.ppStatementStr),"\n")+"\n");
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("evaluated IF-statements to:\n"+stringDelimitList(List.map(listAppend(stmts1,addStmts),DAEDump.ppStatementStr),"\n")+"\n\n");
        end if;

        stmts1 = listAppend(stmts1,lstIn);
        //print("\nthe traverse LIST after :"+stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+"\n");
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts1);
      then (rest,tplOut);
    case(DAE.STMT_TUPLE_ASSIGN(expExpLst=expLst, exp=exp0)::rest,(funcTree,replIn,idx),_)
      equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("Tuple-statement:\n"+DAEDump.ppStatementStr(listHead(algsIn)));
        end if;
        //print("idx: "+intString(idx)+"\n");
        //print("\nthe traverse LIST tpl before :"+stringDelimitList(List.map(lstIn,DAEDump.ppStatementStr),"\n")+"\n");
        //print("the LHS before\n");
        //print(stringDelimitList(List.map(expLst,ExpressionDump.printExpStr),"\n")+"\n");
        //print("the RHS before\n");
        //print(ExpressionDump.printExpStr(exp1)+"\n");
        (exp1,_) = BackendVarTransform.replaceExp(exp0,replIn,NONE());
        //print("the RHS replaced\n");
        //print(ExpressionDump.printExpStr(exp1)+"\n");

        exp2 = DAE.TUPLE(expLst);
        ((exp1,exp2,addEqs,funcTree2,idx,_,_)) = evaluateConstantFunction(exp1,exp2,funcTree,idx,{});
        //print("\nthe LHS after\n");
        //print(ExpressionDump.printExpStr(exp2));
        //ExpressionDump.dumpExp(exp2);
        //print("\nthe RHS after\n");
        //print(ExpressionDump.printExpStr(exp1));
        //BackendDump.dumpEquationList(addEqs,"the additional equations after");
        isCon = Expression.isConst(exp1);
        exp1 = if isCon then exp1 else exp0;
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("--> is the tuple const? "+boolString(isCon)+"\n");
        end if;

        // add the replacements
        varScalars = List.map(expLst,Expression.expCref);
        repl = replIn;
        if not isCon then
          BackendVarTransform.removeReplacements(repl,varScalars,NONE()); // remove the lhs crefs if tis not constant
        else
          repl = addTplReplacements(repl,exp1,exp2); // add all tuple exps to repl if the whole tuple is constant
        end if;

        // build the new statements
        size = DAEUtil.getTupleSize(exp2);
        typ = Expression.typeof(exp2);

        tplExpsLHS = DAEUtil.getTupleExps(exp2);
        tplExpsLHS = if isCon then tplExpsLHS else {};
        tplExpsRHS = DAEUtil.getTupleExps(exp1);
        tplExpsRHS = if isCon then tplExpsRHS else {};
        stmtsNew = List.map2(List.intRange(listLength(tplExpsLHS)),makeAssignmentMap,tplExpsLHS,tplExpsRHS); // if the tuple is completely constant

        alg = listHead(algsIn);
        stmtsNew = if isCon then stmtsNew else {alg};
        stmts2 = if intEq(size,0) then {DAE.STMT_ASSIGN(typ,exp2,exp1,DAE.emptyElementSource)} else stmtsNew;
        stmts1 = List.map(addEqs,equationToStatement);
        stmts2 = listAppend(stmts2,stmts1);
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("evaluated Tuple-statements to (incl. addEqs):\n"+stringDelimitList(List.map(stmts2,DAEDump.ppStatementStr),"\n")+"\n");
        end if;
        stmts2 = listReverse(stmts2);
        stmts2 = listAppend(stmts2,lstIn);
        //print("idx: "+intString(idx)+"\n");
        //print("\nthe traverse LIST tpl after :"+stringDelimitList(List.map(stmts2,DAEDump.ppStatementStr),"\n")+"\n");
        //print("\nthe REST tpl after :"+stringDelimitList(List.map(rest,DAEDump.ppStatementStr),"\n")+"\n");
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree2,repl,idx),stmts2);
      then (rest,tplOut);

    case(DAE.STMT_FOR(statementLst=stmts1)::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        // TODO: evaluate for-loops
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("For-statement:\n"+DAEDump.ppStatementStr(alg));
        end if;

        // lets see if we can evaluate it
        (stmts1,funcTree,repl,idx) = evaluateForStatement(listHead(algsIn), funcTree,replIn,idx);

        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("evaluated for-statements to:\n"+stringDelimitList(List.map(stmts1,DAEDump.ppStatementStr),"\n")+"\n");
        end if;
        stmts2 = List.append_reverse(stmts1,lstIn);
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,repl,idx),stmts2);
      then (rest,tplOut);

    case(DAE.STMT_WHILE(statementLst=stmts1)::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        // TODO: evaluate while-loops
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("While-statement (not evaluated):\n"+DAEDump.ppStatementStr(alg));
        end if;
        lhsExps = List.fold1(stmts1,getStatementLHSScalar,funcTree,{});
        lhsExps = List.unique(lhsExps);
        outputs = List.map(lhsExps,Expression.expCref);
        BackendVarTransform.removeReplacements(replIn,outputs,NONE());
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("evaluated While-statement to:\n"+DAEDump.ppStatementStr(alg));
        end if;
        stmts2 = alg::lstIn;
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,tplOut);
    case(DAE.STMT_ASSERT(cond=cond,msg=msg,level=lvl)::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        (cond,_) = BackendVarTransform.replaceExp(cond,replIn,NONE());
        (cond) = evaluateConstantFunctionCallExp(cond,funcTree);
        (cond,_) = ExpressionSimplify.simplify(cond);
        (msg,_) = BackendVarTransform.replaceExp(msg,replIn,NONE());
        (msg) = evaluateConstantFunctionCallExp(msg,funcTree);
        (msg,_) = ExpressionSimplify.simplify(msg);
        if Expression.expEqual(cond,DAE.BCONST(false)) and Expression.sconstEnumNameString(lvl)=="AssertionLevel.error" then
          if Flags.isSet(Flags.EVAL_FUNC_DUMP) then print("ERROR: "+ExpressionDump.printExpStr(msg)+"\n"); end if;
          fail();
        elseif Expression.expEqual(cond,DAE.BCONST(false)) and Expression.sconstEnumNameString(lvl)=="AssertionLevel.warning" then
          if Flags.isSet(Flags.EVAL_FUNC_DUMP) then print("WARNING: "+ExpressionDump.printExpStr(msg)+"\n"); end if;
          fail();
        end if;

        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("assert-statement:\n"+DAEDump.ppStatementStr(alg));
        end if;
        stmts2 = alg::lstIn;
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,tplOut);
    case(DAE.STMT_TERMINATE()::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("terminate-statement:\n"+DAEDump.ppStatementStr(alg));
        end if;
        stmts2 = alg::lstIn;
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,tplOut);
    case(DAE.STMT_REINIT()::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("reinit-statement:\n"+DAEDump.ppStatementStr(alg));
        end if;
        stmts2 = alg::lstIn;
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,tplOut);
    case(DAE.STMT_NORETCALL()::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("noretcall-statement (not evaluated):\n"+DAEDump.ppStatementStr(alg));
        end if;
        stmts2 = alg::lstIn;
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,tplOut);
    case(DAE.STMT_RETURN()::rest,(funcTree,replIn,idx),_)
      equation
        alg = listHead(algsIn);
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("return-statement:\n"+DAEDump.ppStatementStr(alg));
        end if;
        stmts2 = alg::lstIn;
        (rest,tplOut) = evaluateFunctions_updateStatement(rest,(funcTree,replIn,idx),stmts2);
      then (rest,tplOut);
    else
      equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("evaluateFunctions_updateStatement failed for!\n"+DAEDump.ppStatementStr(listHead(algsIn))+"\n");
        end if;
      then
        fail();
  end matchcontinue;
end evaluateFunctions_updateStatement;

protected function evaluateForStatement"evaluates a for statement. neste for loops wont work"
  input DAE.Statement stmtIn;
  input DAE.FunctionTree funcTreeIn;
  input BackendVarTransform.VariableReplacements replIn;
  input Integer idxIn;
  output list<DAE.Statement> stmtsOut;
  output DAE.FunctionTree funcTreeOut;
  output BackendVarTransform.VariableReplacements repl;
  output Integer idxOut;
protected
  Boolean hasNoRepl;
  Integer i, start, stop ,step;
  DAE.Ident iter;
  DAE.Exp range;
  list<DAE.ComponentRef> outputs;
  list<DAE.Exp> lhsExps;
  list<list<DAE.Exp>> lhsExpLst;
  list<DAE.Statement> stmts,stmtsIn;
algorithm
  DAE.STMT_FOR(iter=iter, range=range, statementLst=stmtsIn) :=  stmtIn;
  try
    (range,_) := BackendVarTransform.replaceExp(range,replIn,NONE());
    (start,stop,step) := getRangeBounds(range);
    true := intEq(step,1);
    repl := replIn;
    for i in List.intRange2(start,stop) loop
      repl := BackendVarTransform.addReplacement(repl, ComponentReference.makeCrefIdent(iter,DAE.T_INTEGER_DEFAULT,{}),DAE.ICONST(i),NONE());
      (stmts,((_,repl,_))) := evaluateFunctions_updateStatement(stmtsIn,(funcTreeIn,repl,i),{});

      // check if any variable has been evaluated. If not, skip the loop (this is necessary for testsuite/modelica/linear_systems/problem1.mos)
      lhsExps := List.fold1(stmts,getStatementLHSScalar,funcTreeIn,{});
      lhsExps := List.unique(lhsExps);
      outputs := List.map(lhsExps,Expression.expCref);
      hasNoRepl := List.applyAndFold1(outputs,boolAnd,BackendVarTransform.hasNoReplacementCrefFirst,repl,true);
      if hasNoRepl then
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then print("For-loop evaluation is skipped, since the first loop evaluated nothing.\n"); end if;
        fail();
      end if;
    end for;
    BackendVarTransform.removeReplacement(repl,ComponentReference.makeCrefIdent(iter,DAE.T_INTEGER_DEFAULT,{}),NONE());
    funcTreeOut := funcTreeIn;
    idxOut := idxIn;
    stmtsOut := stmts;
  else
    // at least remove the replacements for the lhs so we dont declare something as constant which isnt
    lhsExps := List.fold(stmtsIn,getStatementLHS,{});
    lhsExps := List.unique(lhsExps);
    lhsExpLst := List.map(lhsExps,Expression.getComplexContents); //consider arrays etc.
    lhsExps := listAppend(List.flatten(lhsExpLst),lhsExps);
    lhsExps := List.filterOnTrue(lhsExps,Expression.isCref); //remove e.g. ASUBs and consider only the scalar subs
    outputs := List.map(lhsExps,Expression.expCref);
    repl := replIn;
    BackendVarTransform.removeReplacements(repl,outputs,NONE());
    stmtsOut := {stmtIn};
    funcTreeOut := funcTreeIn;
    idxOut := idxIn;
  end try;
end evaluateForStatement;

protected function getRangeBounds
  input DAE.Exp range;
  output Integer start;
  output Integer stop;
  output Integer step;
algorithm
  (start, stop, step) := match(range)
    local
      Integer i1,i2,i3;
  case(DAE.RANGE(start= DAE.ICONST(i1),step=NONE(),stop=DAE.ICONST(i2)))
    then (i1,i2,1);
  case(DAE.RANGE(start= DAE.ICONST(i1),step=SOME(DAE.ICONST(i3)),stop=DAE.ICONST(i2)))
    then (i1,i2,i3);
  else
  equation
    //print("getRangeBounds failed!"+ExpressionDump.printExpStr(range)+"\n");
    then fail();
  end match;
end getRangeBounds;


protected function evaluateIfStatement "check if the cases are constant and if so evaluate them.
author: Waurich TUD 2014-04"
  input DAE.Statement stmtIn;
  input FuncInfo info;
  output Boolean isEval;
  output list<DAE.Statement> stmtsOut;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  (isEval,stmtsOut,replOut) := matchcontinue(stmtIn,info)
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
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("-->try to check if its the if case\n");
        end if;
        (exp1,_) = BackendVarTransform.replaceExp(expIf,replIn,NONE());
        (exp1,(_,_,_,_)) = Expression.traverseExpTopDown(exp1,evaluateConstantFunctionWrapper,(exp1,funcTree,idx,{}));
        (exp1,_) = BackendVarTransform.replaceExp(exp1,replIn,NONE());
        (exp1,_) = ExpressionSimplify.simplify(exp1);
        isCon = Expression.isConst(exp1);
        isIf = if isCon then Expression.toBool(exp1) else false;

        // check if its the IF case, if true then evaluate:
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("-->is the if const? "+boolString(isCon)+" and is it the if case ? "+boolString(isIf)+"\n");
        end if;
        //(stmts1,(funcTree,repl,idx)) = bcallret3_2(isIf and isCon,evaluateFunctions_updateStatement,stmtsIf,(funcTree,replIn,idx),lstIn,stmtsIf,(funcTree,replIn,idx));
        if isIf and isCon then
          (stmts1,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(stmtsIf,(funcTree,replIn,idx),{});  // without listIn
        else
          stmts1 = {stmtIn};
          repl = replIn;
        end if;

        // if its definitly not the if, check the else
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isIf then
          print("-->try to check if its another case\n");
        end if;
        if isCon and not isIf then
          (stmtsElse,isElse) = evaluateElse(else_,info);
        else
          stmtsElse = {stmtIn};
          isElse = false;
        end if;
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) and not isIf then
          print("-->is it an other case? "+boolString(isElse)+"\n");
        end if;
        if isCon and isElse then
          (stmts1,(funcTree,repl,idx)) = evaluateFunctions_updateStatement(stmtsElse,(funcTree,replIn,idx),{});
        else
        end if;
        eval = isCon and (isIf or isElse);
     then
       (eval,stmts1,repl);
     else
       equation
         if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
           print("evaluateIfStatement failed \n");
         end if;
       then
         fail();
  end matchcontinue;
end evaluateIfStatement;

protected function evaluateElse "checks if its one of the elseif cases.
author: Waurich TUD 2014-04"
  input DAE.Else elseIn;
  input FuncInfo info;
  output list<DAE.Statement> stmtsOut;
  output Boolean isElse;
algorithm
  (stmtsOut,isElse) := match(elseIn,info)
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
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("-->try to check if its the elseif case\n");
        end if;
        (exp1,(_,_,_,_)) = Expression.traverseExpTopDown(expIf,evaluateConstantFunctionWrapper,(expIf,funcTree,idx,{}));
        (exp1,_) = BackendVarTransform.replaceExp(exp1,replIn,NONE());
        (exp1,_) = ExpressionSimplify.simplify(exp1);
        isCon = Expression.isConst(exp1);
        isElseIf = if isCon then Expression.toBool(exp1) else false;
        if isCon and not isElseIf then
          (stmts,isElseIf) = evaluateElse(else_,info);
        end if;
      then
        (stmts,isElseIf);
    case(DAE.ELSE(statementLst=stmts),FUNCINFO())
      equation
        // if everything else was const and false, it has to be the else
      then
        (stmts,true);
    case(DAE.NOELSE(),FUNCINFO())
      then
        ({},true);
  end match;
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
        //print("add the tpl  replacements: "+stringDelimitList(List.map(crefs,ComponentReference.printComponentRefStr),",")+stringDelimitList(List.map(tplRHS,ExpressionDump.printExpStr),",")+"\n");
      then
        repl;
   else
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

protected function getStatementLHS "fold function to get the lhs expressions of a statement
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
  case(DAE.STMT_ASSIGN(exp1=exp),_)
    then
      exp::expsIn;
  case(DAE.STMT_TUPLE_ASSIGN(expExpLst=expLst),_)
    equation
      expLst = listAppend(expLst,expsIn);
    then expLst;
  case(DAE.STMT_ASSIGN_ARR(lhs=exp),_)
    then exp::expsIn;
  case(DAE.STMT_IF(statementLst=stmtLst1,else_=else_),_)
    equation
      stmtLstLst = getDAEelseStatemntLsts(else_,{});
      stmtLst2 = List.flatten(stmtLstLst);
      stmtLst1 = listAppend(stmtLst1,stmtLst2);
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_FOR(statementLst=stmtLst1),_)
    equation
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_PARFOR(statementLst=stmtLst1),_)
    equation
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_WHILE(statementLst=stmtLst1),_)
    equation
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_WHEN(statementLst=stmtLst1,elseWhen=SOME(stmt1)),_)
    equation
      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
        print(" check getStatementLHS for WHEN!\n"+DAEDump.ppStatementStr(stmt));
      end if;
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
      expLst = List.fold({stmt1},getStatementLHS,expLst);
    then expLst;
  case(DAE.STMT_WHEN(statementLst=stmtLst1,elseWhen=NONE()),_)
    equation
      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
        print(" check getStatementLHS for WHEN!\n"+DAEDump.ppStatementStr(stmt));
      end if;
      expLst = List.fold(stmtLst1,getStatementLHS,expsIn);
    then expLst;
  case(DAE.STMT_ASSERT(),_)
    equation
      //bcall1(Flags.isSet(Flags.EVAL_FUNC_DUMP),print,"getStatementLHS update for ASSERT!\n"+DAEDump.ppStatementStr(stmt));
    then expsIn;
  case(DAE.STMT_TERMINATE(),_)
    equation
      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
        print("getStatementLHS update for TERMINATE!\n"+DAEDump.ppStatementStr(stmt));
      end if;
    then fail();
  case(DAE.STMT_REINIT(),_)
    equation
      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
        print("getStatementLHS update for REINIT!\n"+DAEDump.ppStatementStr(stmt));
      end if;
    then fail();
  case(DAE.STMT_NORETCALL(),_)
    then expsIn;
  case(DAE.STMT_RETURN(),_)
    equation
      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
        print("getStatementLHS update for RETURN!\n"+DAEDump.ppStatementStr(stmt));
      end if;
    then fail();
  case(DAE.STMT_BREAK(),_)
    equation
      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
        print("getStatementLHS update for BREAK!\n"+DAEDump.ppStatementStr(stmt));
      end if;
    then fail();
  case(DAE.STMT_ARRAY_INIT(),_)
    equation
      if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
        print("getStatementLHS update for ARRAY_INIT!\n"+DAEDump.ppStatementStr(stmt));
      end if;
    then fail();
  else
    equation
      print("getStatementLHS update for !\n"+DAEDump.ppStatementStr(stmt));
    then fail();
  end match;
end getStatementLHS;

protected function getStatementLHSScalar "fold function to get the assigned scalar lhs expressions of a statement
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
  case(DAE.STMT_ASSIGN(exp1=exp,exp=DAE.CALL(path=path)),_,_)
    equation
      SOME(func) = DAE.AvlTreePathFunction.get(funcTree,path);
      elements = DAEUtil.getFunctionElements(func);
      algs = List.filterOnTrue(elements,DAEUtil.isAlgorithm);
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
  case(DAE.STMT_ASSIGN_ARR(lhs=exp),_,_)
    equation
      expLst = Expression.getComplexContents(exp);
      expLst = listAppend(expLst,expsIn);
    then expLst;
  else
    equation
      expLst = getStatementLHS(stmt,expsIn);
    then expLst;
  end matchcontinue;
end getStatementLHSScalar;

protected function getDAEelseStatemntLsts "get all statements for every else or elseif clause
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
    case(DAE.ELSEIF(statementLst=stmts,else_=else1),_)
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
      stmtLstsIn;
  end match;
end getDAEelseStatemntLsts;

protected function evaluateFunctions_updateStatementLst "author:Waurich TUD 2014-03"
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
  output Boolean cont;
  output tuple<DAE.Exp,DAE.FunctionTree,Integer,list<DAE.Statement>> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue(inExp,inTpl)
    local
      Integer idx;
      DAE.Exp rhs, lhs;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> addEqs;
      list<DAE.Statement> stmts,stmtsIn;
  case (DAE.CALL(),(lhs,funcs,idx,stmtsIn))
    equation
      ((rhs,lhs,addEqs,funcs,idx,_,_)) = evaluateConstantFunction(inExp,lhs,funcs,idx,{});
      stmts = List.map(addEqs,equationToStmt);
      stmts = listAppend(stmts,stmtsIn);
    then (rhs,true,(lhs,funcs,idx,stmts));

  case (DAE.UNBOX(exp=rhs),_)
    equation
      (rhs,_,(lhs,funcs,idx,stmts)) = evaluateConstantFunctionWrapper(rhs,inTpl);
    then (rhs,true,(lhs,funcs,idx,stmts));

  case (rhs,(_,_,_,_))
    then (rhs,false,inTpl);
  end matchcontinue;
end evaluateConstantFunctionWrapper;

protected function equationToStmt "transforms a backend equation into a statement"
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
          print("equationToStmt failed for: "+BackendDump.dumpEqnsStr({eqIn})+"\n");
        then fail();
  end matchcontinue;
end equationToStmt;

protected function expType "gets the type of an expression"
  input DAE.Exp eIn;
  output DAE.Type tOut;
algorithm
  tOut := matchcontinue(eIn)
    local
      DAE.Type t;
    case(DAE.CREF(ty=t))
      then
        t;
    else
      equation
      print("expType failed for: "+ExpressionDump.printExpStr(eIn)+"\n");
      then
        fail();
  end matchcontinue;
end expType;

protected function getScalarsForComplexVar "gets the list<ComponentRef> for the scalar values of complex vars and multidimensional vars (at least real) .
author: Waurich TUD 2014-03"
  input DAE.Element inElem;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := matchcontinue(inElem)
    local
      list<Integer> dim;
      list<list<Integer>> ranges;
      list<DAE.Dimension> dims;
      list<list<DAE.Subscript>> subslst, subslst1, subslst2;
      DAE.ComponentRef cref;
      DAE.Dimensions dimensions, dimensions2;
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
        //print("the names for the scalar complex crefs: "+stringDelimitList(names,"\n;")+"\n");
        types = List.map(varLst,DAEUtil.varType);
        crefs = List.map1(names,ComponentReference.appendStringCref,cref);
        crefs = setTypesForScalarCrefs(crefs,types);
        crefLst = List.map1(crefs,ComponentReference.expandCref,true);
        crefs = List.flatten(crefLst);
      then
        crefs;

    case(DAE.VAR(componentRef=cref,ty=DAE.T_REAL(), dims=dims ))
      algorithm
        subslst := expandDimension(dims,{});
        crefs := List.map1r(subslst,ComponentReference.subscriptCref,cref);
      then
        crefs;

    case(DAE.VAR(componentRef=cref,ty=DAE.T_INTEGER(), dims=dims ))
      algorithm
        subslst := expandDimension(dims,{});
        crefs := List.map1r(subslst,ComponentReference.subscriptCref,cref);
      then
        crefs;

    case(DAE.VAR(componentRef=cref,ty=DAE.T_ARRAY(ty=DAE.T_ARRAY(ty=ty, dims=dimensions2), dims=dimensions)))// a 2-dim array
      algorithm
        subslst1 := expandDimension(dimensions,{});
        subslst2 := expandDimension(dimensions2,{});
        subslst := {};
        for subs in subslst1 loop
          for subs2 in subslst2 loop
            subslst := listAppend(subs,subs2)::subslst;
          end for;
        end for;
        crefs := List.map1r(subslst,ComponentReference.subscriptCref,cref);
      then
        crefs;

    case(DAE.VAR(componentRef=cref,ty=DAE.T_ARRAY(dims=dimensions)))
      equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("the array cref before\n"+stringDelimitList(List.map({cref},ComponentReference.printComponentRefStr),"\n")+"\n");
        end if;
        crefs = ComponentReference.expandArrayCref(cref,dimensions);
      then
        crefs;
    case(DAE.VAR(componentRef=cref,ty=DAE.T_ENUMERATION()))
      equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("update getScalarsForComplexVar for enumerations: the enum cref is :"+stringDelimitList(List.map({cref},ComponentReference.printComponentRefStr),"\n")+"\n");
        end if;
      then
        {};
    case(DAE.VAR(componentRef=cref,ty=DAE.T_TUPLE()))
      equation
        if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
          print("update getScalarsForComplexVar for tuple types: the tupl cref is :\n"+stringDelimitList(List.map({cref},ComponentReference.printComponentRefStr),"\n")+"\n");
        end if;
      then
        {};
    else
    equation
      then
        {};
  end matchcontinue;
end getScalarsForComplexVar;

protected function expandDimension"expands the dimensions. e.g. [3,3] {{1,1},{1,2},{1,3}, {2,1},{2,2},{2,3}, {3,1},{3,2},{3,3}}"
  input list<DAE.Dimension> dims;
  input list<list<DAE.Subscript>> subsIn;
  output list<list<DAE.Subscript>> subsOut;
algorithm
  subsOut := matchcontinue(dims,subsIn)
    local
      Integer size;
      list<Integer> range;
      DAE.Dimension dim;
      DAE.Subscript sub;
      list<DAE.Dimension> rest;
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> subsLst, subsLst1, subFold = {};
  case(dim::rest,_)
    algorithm
      size := Expression.dimensionSize(dim);
      range := List.intRange(size);
      subs := List.map(range, Expression.intSubscript);
      subsLst := List.map(subs,List.create);
      for sub in subsIn loop
        subsLst1 := List.map1r(subsLst,listAppend,sub);
        subFold := listAppend(subFold,subsLst1);
      end for;
      if listEmpty(subsIn) then subFold := subsLst; end if;
    then expandDimension(rest,subFold);
  case({},_)
    equation
    then subsIn;
  end matchcontinue;
end expandDimension;

protected function subsLstString
  input list<DAE.Subscript> subs;
  output String s;
algorithm
  s := "{"+stringDelimitList(List.map(subs,ExpressionDump.subscriptString),",")+"}";
end subsLstString;

protected function isNotComplexVar "returns true if the given var is one dimensional (no array,record...).
author: Waurich TUD 2014-03"
  input DAE.Element inElem;
  output Boolean b;
algorithm
  b := matchcontinue(inElem)
    local
      list<Integer> dimints;
      list<DAE.Dimension> dims;

    case (DAE.VAR(ty=DAE.T_COMPLEX(_))) then false;

    case (DAE.VAR(ty=DAE.T_REAL(_), dims=dims))
      equation
        dimints = List.map(dims, Expression.dimensionSize);
        true = listHead(dimints) <> 0;
      then
        false;

    case (DAE.VAR(ty=DAE.T_INTEGER(_), dims=dims))
      equation
        dimints = List.map(dims, Expression.dimensionSize);
        true = listHead(dimints) <> 0;
      then
        false;

    case (DAE.VAR(ty=DAE.T_ARRAY(_))) then false;
    else true;
  end matchcontinue;
end isNotComplexVar;

protected function setTypesForScalarCrefs
  input list<DAE.ComponentRef> allCrefs;
  input list<DAE.Type> types;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := list(ComponentReference.crefSetLastType(cr, ty)
    threaded for cr in allCrefs, ty in types);
end setTypesForScalarCrefs;

public function getRecordScalars "gets all crefs from a record"
  input DAE.ComponentRef crefIn;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  try
    crefsOut := ComponentReference.expandCref(crefIn, true);
  else
    crefsOut := {};
  end try;
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
      list<DAE.Exp> exps;
      list<DAE.Var> vl;
      list<DAE.Type> tyl;
      Integer exps_len;

    // tuple
    case DAE.TUPLE(exps as _ :: _)
      algorithm
        exps_len := intAdd(1 for exp guard(Expression.isNotWild(exp)) in exps);
        size := intAdd(getScalarExpSize(exp) for exp in exps);
      then
        max(size, exps_len);

    // record cref
    case DAE.CREF(ty = DAE.T_COMPLEX(varLst = vl as _ :: _))
      then intAdd(getScalarVarSize(v) for v in vl);

    // array cref
    case DAE.CREF(componentRef = cref)
      algorithm
        size := if ComponentReference.isArrayElement(cref) then
          listLength(ComponentReference.expandCref(cref, true)) else 1;
      then
        size;

    case DAE.CALL(attr = DAE.CALL_ATTR(ty = DAE.T_COMPLEX(varLst = vl as _ :: _)))
      then intAdd(getScalarVarSize(v) for v in vl);

    case DAE.CALL(attr = DAE.CALL_ATTR(ty = DAE.T_TUPLE(types = tyl as _ :: _)))
      algorithm
        size := 0;
        for ty in tyl loop
          vl := getVarLstFromType(ty);

          if not listEmpty(vl) then
            size := size + intAdd(getScalarVarSize(v) for v in vl);
          end if;
        end for;
      then
        size;

    else 0;
  end match;
end getScalarExpSize;

protected function getVarLstFromType "gets the list of DAE.Var from a DAE.Type
author:Waurich TUD 2014-04"
  input DAE.Type tyIn;
  output list<DAE.Var> varsOut;
algorithm
  varsOut := match(tyIn)
    local
      list<DAE.Var> varLst;
      list<DAE.Type> tyLst;

    case DAE.T_TUPLE(types = tyLst as _ :: _)
      then listAppend(getVarLstFromType(ty) for ty in tyLst);

    case DAE.T_COMPLEX(varLst = varLst) then varLst;
    case DAE.T_SUBTYPE_BASIC(varLst = varLst) then varLst;
    else {};
  end match;
end getVarLstFromType;

protected function getScalarVarSize "gets the number of scalars of an DAE.Var.
author:Waurich TUD 2014-04"
  input DAE.Var inVar;
  output Integer size;
algorithm
  size := match(inVar)
    local
      DAE.Type ty;
      list<DAE.Var> vl;

    case DAE.TYPES_VAR(ty = DAE.T_COMPLEX(varLst = vl as _ :: _))
      then intAdd(getScalarVarSize(v) for v in vl);

    case DAE.TYPES_VAR(ty = ty as DAE.T_ARRAY(_))
      then intMul(sz for sz in DAEUtil.expTypeArrayDimensions(ty));

    else 1;
  end match;
end getScalarVarSize;


// =============================================================================
// predict if statements
//
// =============================================================================

protected function evaluateFunctions_updateStatementEmptyRepl "replace and update the statements but start with an empty replacement.
author:Waurich TUD 2014-03"
  input list<DAE.Statement> algsIn;
  input DAE.FunctionTree inFuncTree;
  input Integer inIndex;
  output tuple<list<DAE.Statement>,BackendVarTransform.VariableReplacements> mapTplOut;
  output DAE.FunctionTree outFuncTree;
  output Integer outIndex;
protected
  BackendVarTransform.VariableReplacements repl;
  list<DAE.Statement> algsOut;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  //print("start new evaluation with empty replacement\n"+stringDelimitList(List.map(algsIn,DAEDump.ppStatementStr),"\n")+"\n");
  (algsOut, (outFuncTree, repl, outIndex)) := evaluateFunctions_updateStatement(algsIn, (inFuncTree, repl, inIndex), {});
  //print("the new evaluated stmts wit empty repl \n"+stringDelimitList(List.map(algsOut,DAEDump.ppStatementStr),"\n")+"\n");
  mapTplOut := (algsOut, repl);
end evaluateFunctions_updateStatementEmptyRepl;

protected function predictIfOutput "evaluate outputs for all if/elseif/else and check if its constant at any time
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
    case(DAE.STMT_IF(statementLst=stmts1, else_=else_),FUNCINFO(replIn,funcTree,idx))
       equation
         // get a list of all statements for each case
         stmtsLst = getDAEelseStatemntLsts(else_,{});
         stmtsLst = listReverse(stmtsLst);
         stmtsLst = stmts1::stmtsLst;
         //print("all stmts to predict: \n"+stringDelimitList(List.map(List.flatten(stmtsLst),DAEDump.ppStatementStr),"\n")+"\n");

         // replace with the already known stuff and build the new replacements
         repl = getOnlyConstantReplacements(replIn);
         (stmtsLst,_) = List.map4_2(stmtsLst,BackendVarTransform.replaceStatementLstRHS,repl,NONE(),{},false);
         //print("al stmts replaced: \n"+stringDelimitList(List.map(List.flatten(stmtsLst),DAEDump.ppStatementStr),"\n")+"\n");
         (tplLst, funcTree, idx) = List.mapFold2(stmtsLst, evaluateFunctions_updateStatementEmptyRepl, funcTree, idx);
         stmtsLst = List.map(tplLst,Util.tuple21);
         //print("all evaled stmts1: \n"+stringDelimitList(List.map(List.flatten(stmtsLst),DAEDump.ppStatementStr),"---------\n")+"\n");
         replLst = List.map(stmtsLst,collectReplacements);
         //replLst = List.map(replLst,getOnlyConstantReplacements);
         //List.map_0(replLst,BackendVarTransform.dumpReplacements);

         // get the outputs of every case
         expLst = List.fold(List.flatten(stmtsLst),getStatementLHS,{});
         expLst = List.unique(expLst);
         allLHS = listReverse(expLst);
         //print("the outputs: "+stringDelimitList(List.map(allLHS,ExpressionDump.printExpStr),"\n")+"\n");
         expLstLst = List.map1(replLst,replaceExps,allLHS);
         //print("the outputs replaced: \n"+stringDelimitList(List.map(expLstLst,ExpressionDump.printExpListStr),"\n")+"\n\n");

         // compare the constant outputs
         constantOutputs = compareConstantExps(expLstLst);
         outExps = List.map1(constantOutputs,List.getIndexFirst,allLHS);
         _ = List.map(outExps,Expression.expCref);
         //print("constantOutputs: "+stringDelimitList(List.map(constantOutputs,intString),",")+"\n");
         expLst = List.map1(constantOutputs,List.getIndexFirst,listHead(expLstLst));
         //print("the constant shared outputs: "+stringDelimitList(List.map(expLst,ExpressionDump.printExpStr),"\n")+"\n");
         //print("the constant shared output crefs: "+stringDelimitList(List.map(outExps,ExpressionDump.printExpStr),"\n")+"\n");
         if Flags.isSet(Flags.EVAL_FUNC_DUMP) then
           print("--> the predicted const outputs:\n"+stringDelimitList(List.map(outExps,ExpressionDump.printExpStr),"\n"));
         end if;
         (constOutExps,_,varOutExps) = List.intersection1OnTrue(outExps,allLHS,Expression.expEqual);

         //_ = (not listEmpty(constOutExps)) and listEmpty(varOutExps);
         //repl = bcallret3(not predicted, BackendVarTransform.removeReplacements,replIn,varCrefs,NONE(),replIn);
         //bcall(not predicted,print,"remove the replacement for: "+stringDelimitList(List.map(varCrefs,ComponentReference.crefStr),"\n")+"\n");
         repl = replIn;
         // build the additional statements and update the old one
         addStmts = List.map2(List.intRange(listLength(outExps)),makeAssignmentMap,outExps,expLst);
         stmtNew = updateStatementsInIfStmt(stmtsLst,stmtIn);

         //print("the new predicted stmts: \n"+stringDelimitList(List.map({stmtNew},DAEDump.ppStatementStr),"\n")+"\nAnd the additional "+stringDelimitList(List.map(addStmts,DAEDump.ppStatementStr),"\n")+"\n");

         //repl = BackendVarTransform.addReplacements(replIn,crefs,expLst,NONE());
       then
         (({stmtNew},addStmts),FUNCINFO(repl,funcTree,idx));
   else
       (({stmtIn},{}),infoIn);
  end matchcontinue;
end predictIfOutput;

protected function collectReplacements "gathers replacement rules for a given set of statements without updating them
author:Waurich TUD 2014-04"
  input list<DAE.Statement> stmtsIn;
  output BackendVarTransform.VariableReplacements replOut;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  replOut := collectReplacements1(stmtsIn,repl);
end collectReplacements;

protected function collectReplacements1 "author:Waurich TUD 2014-04"
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
      then
        replIn;
    case(DAE.STMT_ASSIGN(exp1=lhs,exp=rhs)::rest,_)
      equation
        (rhs,_) = BackendVarTransform.replaceExp(rhs,replIn,NONE());
        (rhs,_) = ExpressionSimplify.simplify(rhs);
        true = Expression.isConst(rhs);
        cref = Expression.expCref(lhs);
        repl = BackendVarTransform.addReplacement(replIn,cref,rhs,NONE());
        repl = collectReplacements1(rest,repl);
      then
        repl;
    case(DAE.STMT_TUPLE_ASSIGN(expExpLst=lhsLst,exp=rhs)::rest,_)
      equation
        (rhs,_) = BackendVarTransform.replaceExp(rhs,replIn,NONE());
        (rhs,_) = ExpressionSimplify.simplify(rhs);
        rhsLst = Expression.getComplexContents(rhs);
        crefs = List.map(lhsLst,Expression.expCref);
        (constExps,constCrefs) = List.filterOnTrueSync(rhsLst,Expression.isConst,crefs);
        (_,varCrefs) = List.filterOnTrueSync(rhsLst,Expression.isNotConst,crefs);
        repl = BackendVarTransform.addReplacements(replIn,constCrefs,constExps,NONE());
        BackendVarTransform.removeReplacements(repl,varCrefs,NONE());
        repl = collectReplacements1(rest,repl);
      then
        repl;
    case(stmt::rest,_)
      equation
        lhsLst = getStatementLHS(stmt,{});
        crefs = List.map(lhsLst,Expression.expCref);
        BackendVarTransform.removeReplacements(replIn,crefs,NONE());
        repl = collectReplacements1(rest,replIn);
      then
        repl;
    else
      equation
        print("collectReplacements failed\n");
      then
        fail();
  end matchcontinue;
end collectReplacements1;

protected function getOnlyConstantReplacements "removes replacement rules that do not have a constant expression as value
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

protected function updateStatementsInIfStmt "replaces the statements in the if statement
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
    case(stmts::rest,DAE.STMT_IF(exp=exp,else_=els,source=source))
      equation
        els = updateStatementsInElse(rest,els);
      then
        DAE.STMT_IF(exp,stmts,els,source);
  end match;
end updateStatementsInIfStmt;

protected function updateStatementsInElse "replaces the statements in else
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
    case(stmts::rest,DAE.ELSEIF(exp=exp,else_=els))
      equation
        els = updateStatementsInElse(rest,els);
      then
        DAE.ELSEIF(exp,stmts,els);
    case(stmts::_,DAE.ELSE())
      then
        DAE.ELSE(stmts);
    case(_::_,DAE.NOELSE())
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
  num := listLength(listHead(expLstLstIn));
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
  posOut := if b1 and b2 then posLst else posIn;
end compareConstantExps2;

protected function makeAssignmentMap "mapping functino fo build the statements for a list of lhs and rhs exps.
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

protected function makeAssignment "makes an DAE.STMT_ASSIGN of the 2 DAE.Exp"
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

protected function updateVarKinds "if there is a variable declared as a state that is not longer present inside a der-call or selected as a state, change the status to VARIABLE
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

protected function updateVarKinds_eqSys "author:Waurich TUD 2014-04"
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem sysOut;
protected
  BackendDAE.Variables vars;
  list<BackendDAE.Var> states,varLst,ssVarLst;
  BackendDAE.EquationArray eqs, initEqs;
  list<DAE.ComponentRef> derVars,ssVars,derVarsInit;

algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs) := sysIn;
  varLst := BackendVariable.varList(vars);
  initEqs := BackendEquation.getInitialEqnsFromShared(shared);
  states := List.filterOnTrue(varLst, BackendVariable.isStateorStateDerVar);
  ((_, derVarsInit)) := BackendDAEUtil.traverseBackendDAEExpsEqns(initEqs, Expression.traverseSubexpressionsHelper, (findDerVarCrefs, {}));
  ((_, derVars)) := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs, Expression.traverseSubexpressionsHelper, (findDerVarCrefs, derVarsInit));
    //print("derVars\n"+stringDelimitList(List.map(derVars,ComponentReference.printComponentRefStr),"\n")+"\n\n");
  ssVarLst := List.filterOnTrue(varLst, varSSisPreferOrHigher);
  ssVars := List.map(ssVarLst,BackendVariable.varCref);
    //print("ssVars\n"+stringDelimitList(List.map(ssVars,ComponentReference.printComponentRefStr),"\n")+"\n\n");
  derVars := listAppend(derVars, ssVars);
  derVars := List.unique(derVars);
  (vars, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars, setVarKindForStates, derVars);
  sysOut := BackendDAEUtil.setEqSystVars(sysIn, vars);
end updateVarKinds_eqSys;

protected function varSSisPreferOrHigher "outputs true if the stateSelect attribute is prefer or always
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

protected function setVarKindForStates "if a state var is a memeber of the list of state-crefs, it remains a state. otherwise it will be changed to VarKind.Variable
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
    case (varOld as BackendDAE.VAR(varName=cr1,varKind=BackendDAE.STATE()),derVars)
      equation
        isState = List.isMemberOnTrue(cr1,derVars,ComponentReference.crefEqual);
        varNew = if not isState then BackendVariable.setVarKind(varOld,BackendDAE.VARIABLE()) else varOld;
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
  (eqOut, addEqsOut) := match(eqIn)
    local
      DAE.Exp lhsExp, rhsExp;
      list<DAE.Exp> lhs, rhs;
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqs;

    case BackendDAE.COMPLEX_EQUATION(left = DAE.TUPLE(lhs), right = DAE.TUPLE(rhs))
      algorithm
        eq :: eqs := list(makeBackendEquation(lh, rh) threaded for lh in lhs, rh in rhs);
      then
        (eq, listAppend(eqs, addEqsIn));

    else (eqIn, addEqsIn);
  end match;
end convertTupleEquations;

protected function makeBackendEquation "author:Waurich TUD 2014-04
  builds a backendEquation for the lhs-exp and rhs-exp"
  input DAE.Exp ls;
  input DAE.Exp rs;
  output BackendDAE.Equation eq;
algorithm
  eq := BackendDAE.EQUATION(rs, ls, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
end makeBackendEquation;

annotation(__OpenModelica_Interface="backend");
end EvaluateFunctions;
