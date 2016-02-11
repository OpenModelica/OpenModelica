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

encapsulated package CevalFunction
" file:         CevalFunction.mo
  package:      CevalFunction
  description:  This module constant evaluates DAE.Function objects, i.e.
                modelica functions defined by the user.


  TODO:
    * Implement evaluation of MetaModelica statements.
    * Enable NORETCALL (see comment in evaluateStatement).
    * Implement terminate and assert(false, ...).
    * Arrays of records probably doesn't work yet.
"

// Jump table for CevalFunction:
// [TYPE]  Types.
// [EVAL]  Constant evaluation functions.
// [EENV]  Environment extension functions (add variables).
// [MENV]  Environment manipulation functions (set and get variables).
// [DEPS]  Function variable dependency handling.
// [EOPT]  Expression optimization functions.

// public imports
public import Absyn;
public import DAE;
public import FCore;
public import GlobalScript;
public import SCode;
public import Values;

// protected imports
protected import Ceval;
protected import ClassInf;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Graph;
protected import Lapack;
protected import List;
protected import Lookup;
protected import Types;
protected import Util;
protected import ValuesUtil;
protected import FGraph;
protected import FNode;

// [TYPE]  Types
protected type SymbolTable = Option<GlobalScript.SymbolTable>;
protected type FunctionVar = tuple<DAE.Element, Option<Values.Value>>;

// LoopControl is used to control the functions behaviour in different
// situations. All evaluation functions returns a LoopControl variable that
// tells the caller whether it should continue evaluating or not.
protected uniontype LoopControl
  record NEXT "Continue to the next statement." end NEXT;
  record BREAK "Exit the current loop." end BREAK;
  record RETURN "Exit the function." end RETURN;
end LoopControl;

// [EVAL]  Constant evaluation functions.

public function evaluate
  "This is the entry point of CevalFunction. This function constant evaluates a
  function given an instantiated function and a list of function arguments."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Function inFunction;
  input list<Values.Value> inFunctionArguments;
  input Option<GlobalScript.SymbolTable> inST;
  output FCore.Cache outCache;
  output Values.Value outResult;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache, outResult, outST) :=
  matchcontinue(inCache, inEnv, inFunction, inFunctionArguments, inST)
    local
      Absyn.Path p;
      DAE.FunctionDefinition func;
      DAE.Type ty;
      Values.Value result;
      String func_name;
      FCore.Cache cache;
      SymbolTable st;
      Boolean partialPrefix;
      DAE.ElementSource src;

    // The DAE.FUNCTION structure might contain an optional function derivative
    // mapping which is why functions below is a list. We only evaluate the
    // first function, which is hopefully the one we want.
    case (_, _, DAE.FUNCTION(
        path = p,
        functions = func :: _,
        type_ = ty,
        partialPrefix = false,
        source = src), _, st)
      equation
        func_name = Absyn.pathString(p);
        (cache, result, st) = evaluateFunctionDefinition(inCache, inEnv, func_name,
          func, ty, inFunctionArguments, src, st);
      then
        (cache, result, st);

    case (_, _, DAE.FUNCTION(
        path = p,
        functions = _ :: _,
        partialPrefix = partialPrefix), _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CevalFunction.evaluate failed for function: " + (if partialPrefix then "partial " else "") + Absyn.pathString(p));
      then
        fail();
  end matchcontinue;
end evaluate;

protected function evaluateFunctionDefinition
  "This function constant evaluates a function definition."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFuncName;
  input DAE.FunctionDefinition inFunc;
  input DAE.Type inFuncType;
  input list<Values.Value> inFuncArgs;
  input DAE.ElementSource inSource;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output Values.Value outResult;
  output SymbolTable outST;
algorithm
  (outCache, outResult, outST) :=
  matchcontinue(inCache, inEnv, inFuncName, inFunc, inFuncType, inFuncArgs, inSource, inST)
    local
      list<DAE.Element> body;
      list<DAE.Element> vars, output_vars;
      list<FunctionVar> func_params;
      FCore.Cache cache;
      FCore.Graph env;
      list<Values.Value> return_values;
      Values.Value return_value;
      SymbolTable st;
      String ext_fun_name;
      list<DAE.ExtArg> ext_fun_args;
      DAE.ExtArg ext_fun_ret;

    case (_, _, _, DAE.FUNCTION_DEF(body = body), _, _, _, st)
      equation
        // Split the definition into function variables and statements.
        (vars, body) = List.splitOnFirstMatch(body, DAEUtil.isNotVar);
        vars = List.map(vars, removeSelfReferentialDims);

        // Save the output variables, so that we can return their values when
        // we're done.
        output_vars = List.filterOnTrue(vars, DAEUtil.isOutputVar);

        // Pair the input arguments to input parameters and sort the function
        // variables by dependencies.
        func_params = pairFuncParamsWithArgs(vars, inFuncArgs);
        func_params = sortFunctionVarsByDependency(func_params, inSource);

        // Create an environment for the function and add all function variables.
        (cache, env, st) =
          setupFunctionEnvironment(inCache, inEnv, inFuncName, func_params, st);
        // Evaluate the body of the function.
        (cache, env, _, st) = evaluateElements(body, cache, env, NEXT(), st);
        // Fetch the values of the output variables.
        return_values = List.map1(output_vars, getFunctionReturnValue, env);
        // If we have several output variables they should be boxed into a tuple.
        return_value = boxReturnValue(return_values);
      then
        (cache, return_value, st);

    case (_, _, _, DAE.FUNCTION_EXT(body = body, externalDecl =
        DAE.EXTERNALDECL(name = ext_fun_name,
                         args = ext_fun_args)), _, _, _, st)
      equation
        // Get all variables from the function. Ignore everything else, since
        // external functions shouldn't have statements.
        (vars, _) = List.splitOnFirstMatch(body, DAEUtil.isNotVar);
        vars = List.map(vars, removeSelfReferentialDims);

        // Save the output variables, so that we can return their values when
        // we're done.
        output_vars = List.filterOnTrue(vars, DAEUtil.isOutputVar);

        // Pair the input arguments to input parameters and sort the function
        // variables by dependencies.
        func_params = pairFuncParamsWithArgs(vars, inFuncArgs);
        func_params = sortFunctionVarsByDependency(func_params, inSource);

        // Create an environment for the function and add all function variables.
        (cache, env, st) =
          setupFunctionEnvironment(inCache, inEnv, inFuncName, func_params, st);

        // Call the function.
        (cache, env, st) =
          evaluateExternalFunc(ext_fun_name, ext_fun_args, cache, env, st);

        // Fetch the values of the output variables.
        return_values = List.map1(output_vars, getFunctionReturnValue, env);
        // If we have several output variables they should be boxed into a tuple.
        return_value = boxReturnValue(return_values);
      then
        (cache, return_value, st);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- CevalFunction.evaluateFunction failed.\n");
      then
        fail();
  end matchcontinue;
end evaluateFunctionDefinition;

protected function pairFuncParamsWithArgs
  "This function pairs up the input arguments to the input parameters, so that
  each input parameter get one input argument. This is done since we sort the
  function variables by dependencies, and need to keep track of which argument
  belongs to which parameter."
  input list<DAE.Element> inElements;
  input list<Values.Value> inValues;
  output list<FunctionVar> outFunctionVars;
algorithm
  outFunctionVars := match(inElements, inValues)
    local
      DAE.Element var;
      list<DAE.Element> rest_vars;
      Values.Value val;
      list<Values.Value> rest_vals;
      list<FunctionVar> params;

    case ({}, {}) then {};

    case ((DAE.VAR(direction = DAE.INPUT())) :: _, {})
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- CevalFunction.pairFuncParamsWithArgs failed because of too few input arguments.\n");
      then
        fail();

    case ((var as DAE.VAR(direction = DAE.INPUT())) :: rest_vars, val :: rest_vals)
      equation
        params = pairFuncParamsWithArgs(rest_vars, rest_vals);
      then
        (var, SOME(val)) :: params;

    case (var :: rest_vars, _)
      equation
        params = pairFuncParamsWithArgs(rest_vars, inValues);
      then
        (var, NONE()) :: params;

  end match;
end pairFuncParamsWithArgs;

protected function removeSelfReferentialDims
  "We can't handle self-referential dimensions in function parameters, i.e.
   x[:, size(x, 1)], so just replace them with : instead."
  input DAE.Element inElement;
  output DAE.Element outElement;
algorithm
  outElement := match(inElement)
    local
      DAE.ComponentRef cref;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.VarParallelism vp;
      DAE.VarVisibility vv;
      DAE.Type ty;
      Option<DAE.Exp> bind;
      DAE.InstDims dims;
      DAE.ConnectorType ct;
      DAE.ElementSource es;
      Option<DAE.VariableAttributes> va;
      Option<SCode.Comment> cmt;
      Absyn.InnerOuter io;
      String name;

    case DAE.VAR(cref as DAE.CREF_IDENT(ident = name), vk, vd, vp, vv, ty,
        bind, dims, ct, es, va, cmt, io)
      equation
        dims = List.map1(dims, removeSelfReferentialDim, name);
      then
        DAE.VAR(cref, vk, vd, vp, vv, ty, bind, dims, ct, es, va, cmt, io);

  end match;
end removeSelfReferentialDims;

protected function removeSelfReferentialDim
  input DAE.Dimension inDim;
  input String inName;
  output DAE.Dimension outDim;
algorithm
  outDim := matchcontinue(inDim, inName)
    local
      DAE.Exp exp;
      list<DAE.ComponentRef> crefs;

    case (DAE.DIM_EXP(exp = exp), _)
      equation
        crefs = Expression.extractCrefsFromExp(exp);
        true = List.isMemberOnTrue(inName, crefs, isCrefNamed);
      then
        DAE.DIM_UNKNOWN();

    else inDim;

  end matchcontinue;
end removeSelfReferentialDim;

protected function isCrefNamed
  input String inName;
  input DAE.ComponentRef inCref;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match(inName, inCref)
    local
      String name;

    case (_, DAE.CREF_IDENT(ident = name)) then stringEq(inName, name);
    else false;
  end match;
end isCrefNamed;

protected function evaluateExtInputArg
  "Evaluates an external function argument to a value."
  input DAE.ExtArg inArgument;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output Values.Value outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
algorithm
  (outValue, outCache, outST) := matchcontinue(inArgument, inCache, inEnv, inST)
    local
      DAE.ComponentRef cref;
      DAE.Type ty;
      DAE.Exp exp;
      Values.Value val;
      FCore.Cache cache;
      SymbolTable st;
      String err_str;

    case (DAE.EXTARG(componentRef = cref, type_ = ty), _, _, _)
      equation
        val = getVariableValue(cref, ty, inEnv);
      then
        (val, inCache, inST);

    case (DAE.EXTARGEXP(exp = exp), cache, _, st)
      equation
        (cache, val, st) = cevalExp(exp, cache, inEnv, st);
      then
        (val, cache, st);

    case (DAE.EXTARGSIZE(componentRef = cref, exp = exp), cache, _, st)
      equation
        exp = DAE.SIZE(DAE.CREF(cref, DAE.T_UNKNOWN_DEFAULT), SOME(exp));
        (cache, val, st) = cevalExp(exp, cache, inEnv, st);
      then
        (val, cache, st);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        err_str = DAEDump.dumpExtArgStr(inArgument);
        Debug.traceln("- CevalFunction.evaluateExtInputArg failed on " + err_str);
      then
        fail();

  end matchcontinue;
end evaluateExtInputArg;

protected function evaluateExtIntArg
  "Evaluates an external function argument to an Integer."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output Integer outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
algorithm
  (Values.INTEGER(outValue), outCache, outST) :=
    evaluateExtInputArg(inArg, inCache, inEnv, inST);
end evaluateExtIntArg;

protected function evaluateExtRealArg
  "Evaluates an external function argument to a Real."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output Real outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
algorithm
  (Values.REAL(outValue), outCache, outST) :=
    evaluateExtInputArg(inArg, inCache, inEnv, inST);
end evaluateExtRealArg;

protected function evaluateExtStringArg
  "Evaluates an external function argument to a String."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output String outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
algorithm
  (Values.STRING(outValue), outCache, outST) :=
    evaluateExtInputArg(inArg, inCache, inEnv, inST);
end evaluateExtStringArg;

protected function evaluateExtIntArrayArg
  "Evaluates an external function argument to an Integer array."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output list<Integer> outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
protected
  Values.Value val;
algorithm
  (val, outCache, outST) :=
    evaluateExtInputArg(inArg, inCache, inEnv, inST);
  outValue := ValuesUtil.arrayValueInts(val);
end evaluateExtIntArrayArg;

protected function evaluateExtRealArrayArg
  "Evaluates an external function argument to a Real array."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output list<Real> outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
protected
  Values.Value val;
algorithm
  (val, outCache, outST) :=
    evaluateExtInputArg(inArg, inCache, inEnv, inST);
  outValue := ValuesUtil.arrayValueReals(val);
end evaluateExtRealArrayArg;

protected function evaluateExtRealMatrixArg
  "Evaluates an external function argument to a Real matrix."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output list<list<Real>> outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
protected
  Values.Value val;
algorithm
  (val, outCache, outST) :=
    evaluateExtInputArg(inArg, inCache, inEnv, inST);
  outValue := ValuesUtil.matrixValueReals(val);
end evaluateExtRealMatrixArg;

protected function evaluateExtOutputArg
  "Returns the component reference to an external function output."
  input DAE.ExtArg inArg;
  output DAE.ComponentRef outCref;
algorithm
  DAE.EXTARG(componentRef = outCref) := inArg;
end evaluateExtOutputArg;

protected function assignExtOutputs
  "Assigns the outputs from an external function to the correct variables in the
  environment."
  input list<DAE.ExtArg> inArgs;
  input list<Values.Value> inValues;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) := match(inArgs, inValues, inCache, inEnv, inST)
    local
      DAE.ExtArg arg;
      Values.Value val;
      list<DAE.ExtArg> rest_args;
      list<Values.Value> rest_vals;
      FCore.Cache cache;
      SymbolTable st;
      FCore.Graph env;
      DAE.ComponentRef cr;

    case ({}, {}, _, _, _) then (inCache, inEnv, inST);

    case (arg :: rest_args, val :: rest_vals, cache, env, st)
      equation
        cr = evaluateExtOutputArg(arg);
        val = unliftExtOutputValue(cr, val, env);
        (cache, env, st) = assignVariable(cr, val, cache, env, st);
        (cache, env, st) = assignExtOutputs(rest_args, rest_vals, cache, env, st);
      then
        (cache, env, st);

  end match;
end assignExtOutputs;

protected function unliftExtOutputValue
  "Some external functions don't make much difference between arrays and
  matrices, so this function converts a matrix value to an array value when
  needed."
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue(inCref, inValue, inEnv)
    local
      DAE.Type ty;
      list<Values.Value> vals;
      Integer dim;
      DAE.Dimensions dims;

    // Matrix value, array type => convert.
    case (_, Values.ARRAY(valueLst = vals as Values.ARRAY() :: _, dimLst = dim :: _), _)
      equation
        (DAE.T_ARRAY(ty = ty, dims = dims), _) = getVariableTypeAndBinding(inCref, inEnv);
        false = Types.isNonscalarArray(ty, dims);
        vals = List.map(vals, ValuesUtil.arrayScalar);
      then
        Values.ARRAY(vals, {dim});

    // Otherwise, do nothing.
    else inValue;
  end matchcontinue;
end unliftExtOutputValue;

protected function evaluateExternalFunc
  "This function evaluates an external function, at the moment this means a
  LAPACK function. This function was automatically generated. No programmers
  were hurt during the generation of this function."
  input String inFuncName;
  input list<DAE.ExtArg> inFuncArgs;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) :=
  match(inFuncName, inFuncArgs, inCache, inEnv, inST)
    local
      DAE.ExtArg arg_JOBU, arg_JOBVL, arg_JOBVR, arg_JOBVT, arg_TRANS, arg_INFO, arg_K;
      DAE.ExtArg arg_KL, arg_KU, arg_LDA, arg_LDAB, arg_LDB, arg_LDU, arg_LDVL;
      DAE.ExtArg arg_LDVR, arg_LDVT, arg_LWORK, arg_M, arg_N, arg_NRHS, arg_P;
      DAE.ExtArg arg_RANK, arg_RCOND, arg_IPIV, arg_JPVT, arg_ALPHAI, arg_ALPHAR, arg_BETA;
      DAE.ExtArg arg_C, arg_D, arg_DL, arg_DU, arg_TAU, arg_WI, arg_WORK;
      DAE.ExtArg arg_WR, arg_X, arg_A, arg_AB, arg_B, arg_S, arg_U;
      DAE.ExtArg arg_VL, arg_VR, arg_VT;
      Values.Value val_INFO, val_RANK, val_IPIV, val_JPVT, val_ALPHAI, val_ALPHAR, val_BETA;
      Values.Value val_C, val_D, val_DL, val_DU, val_TAU, val_WI, val_WORK;
      Values.Value val_WR, val_X, val_A, val_AB, val_B, val_S, val_U;
      Values.Value val_VL, val_VR, val_VT;
      Integer INFO, K, KL, KU, LDA, LDAB, LDB, LDU, LDVL, LDVR, LDVT, LWORK, M, N, NRHS, P, RANK;
      Real RCOND;
      String JOBU, JOBVL, JOBVR, JOBVT, TRANS;
      list<Integer> IPIV, JPVT;
      list<Real> ALPHAI, ALPHAR, BETA, C, D, DL, DU, TAU, WI, WORK, WR, X, S;
      list<list<Real>> A, AB, B, U, VL, VR, VT;
      list<DAE.ExtArg> arg_out;
      list<Values.Value> val_out;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;

    case("dgeev", {arg_JOBVL, arg_JOBVR, arg_N, arg_A, arg_LDA, arg_WR, arg_WI,
                   arg_VL, arg_LDVL, arg_VR, arg_LDVR, arg_WORK, arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (JOBVL, cache, st) = evaluateExtStringArg(arg_JOBVL, cache, env, st);
        (JOBVR, cache, st) = evaluateExtStringArg(arg_JOBVR, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (LDVL, cache, st) = evaluateExtIntArg(arg_LDVL, cache, env, st);
        (LDVR, cache, st) = evaluateExtIntArg(arg_LDVR, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (LWORK, cache, st) = evaluateExtIntArg(arg_LWORK, cache, env, st);
        (A, WR, WI, VL, VR, WORK, INFO) =
          Lapack.dgeev(JOBVL, JOBVR, N, A, LDA, LDVL, LDVR, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_WR = ValuesUtil.makeRealArray(WR);
        val_WI = ValuesUtil.makeRealArray(WI);
        val_VL = ValuesUtil.makeRealMatrix(VL);
        val_VR = ValuesUtil.makeRealMatrix(VR);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_WR, arg_WI, arg_VL, arg_VR, arg_WORK, arg_INFO};
        val_out = {val_A, val_WR, val_WI, val_VL, val_VR, val_WORK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgegv", {arg_JOBVL, arg_JOBVR, arg_N, arg_A, arg_LDA, arg_B, arg_LDB,
                   arg_ALPHAR, arg_ALPHAI, arg_BETA, arg_VL, arg_LDVL, arg_VR, arg_LDVR,
                   arg_WORK, arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (JOBVL, cache, st) = evaluateExtStringArg(arg_JOBVL, cache, env, st);
        (JOBVR, cache, st) = evaluateExtStringArg(arg_JOBVR, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (LDVL, cache, st) = evaluateExtIntArg(arg_LDVL, cache, env, st);
        (LDVR, cache, st) = evaluateExtIntArg(arg_LDVR, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (LWORK, cache, st) = evaluateExtIntArg(arg_LWORK, cache, env, st);
        (ALPHAR, ALPHAI, BETA, VL, VR, WORK, INFO) =
          Lapack.dgegv(JOBVL, JOBVR, N, A, LDA, B, LDB, LDVL, LDVR, WORK, LWORK);
        val_ALPHAR = ValuesUtil.makeRealArray(ALPHAR);
        val_ALPHAI = ValuesUtil.makeRealArray(ALPHAI);
        val_BETA = ValuesUtil.makeRealArray(BETA);
        val_VL = ValuesUtil.makeRealMatrix(VL);
        val_VR = ValuesUtil.makeRealMatrix(VR);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_ALPHAR, arg_ALPHAI, arg_BETA, arg_VL, arg_VR, arg_WORK, arg_INFO};
        val_out = {val_ALPHAR, val_ALPHAI, val_BETA, val_VL, val_VR, val_WORK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgels", {arg_TRANS, arg_M, arg_N, arg_NRHS, arg_A, arg_LDA, arg_B,
                   arg_LDB, arg_WORK, arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (TRANS, cache, st) = evaluateExtStringArg(arg_TRANS, cache, env, st);
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (NRHS, cache, st) = evaluateExtIntArg(arg_NRHS, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (LWORK, cache, st) = evaluateExtIntArg(arg_LWORK, cache, env, st);
        (A, B, WORK, INFO) =
          Lapack.dgels(TRANS, M, N, NRHS, A, LDA, B, LDB, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_WORK, arg_INFO};
        val_out = {val_A, val_B, val_WORK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgelsx", {arg_M, arg_N, arg_NRHS, arg_A, arg_LDA, arg_B, arg_LDB,
                    arg_JPVT, arg_RCOND, arg_RANK, arg_WORK, arg_INFO},
        cache, env, st)
      equation
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (NRHS, cache, st) = evaluateExtIntArg(arg_NRHS, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (JPVT, cache, st) = evaluateExtIntArrayArg(arg_JPVT, cache, env, st);
        (RCOND, cache, st) = evaluateExtRealArg(arg_RCOND, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (A, B, JPVT, RANK, INFO) =
          Lapack.dgelsx(M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, WORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_JPVT = ValuesUtil.makeIntArray(JPVT);
        val_RANK = ValuesUtil.makeInteger(RANK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_JPVT, arg_RANK, arg_INFO};
        val_out = {val_A, val_B, val_JPVT, val_RANK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgelsx", {arg_M, arg_N, arg_NRHS, arg_A, arg_LDA, arg_B, arg_LDB,
                    arg_JPVT, arg_RCOND, arg_RANK, arg_WORK, arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (NRHS, cache, st) = evaluateExtIntArg(arg_NRHS, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (JPVT, cache, st) = evaluateExtIntArrayArg(arg_JPVT, cache, env, st);
        (RCOND, cache, st) = evaluateExtRealArg(arg_RCOND, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (A, B, JPVT, RANK, INFO) =
          Lapack.dgelsx(M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, WORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_JPVT = ValuesUtil.makeIntArray(JPVT);
        val_RANK = ValuesUtil.makeInteger(RANK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_JPVT, arg_RANK, arg_INFO};
        val_out = {val_A, val_B, val_JPVT, val_RANK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgesv", {arg_N, arg_NRHS, arg_A, arg_LDA, arg_IPIV, arg_B, arg_LDB,
                   arg_INFO},
        cache, env, st)
      equation
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (NRHS, cache, st) = evaluateExtIntArg(arg_NRHS, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (A, IPIV, B, INFO) =
          Lapack.dgesv(N, NRHS, A, LDA, B, LDB);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_IPIV = ValuesUtil.makeIntArray(IPIV);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_IPIV, arg_B, arg_INFO};
        val_out = {val_A, val_IPIV, val_B, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgglse", {arg_M, arg_N, arg_P, arg_A, arg_LDA, arg_B, arg_LDB,
                    arg_C, arg_D, arg_X, arg_WORK, arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (P, cache, st) = evaluateExtIntArg(arg_P, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (C, cache, st) = evaluateExtRealArrayArg(arg_C, cache, env, st);
        (D, cache, st) = evaluateExtRealArrayArg(arg_D, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (LWORK, cache, st) = evaluateExtIntArg(arg_LWORK, cache, env, st);
        (A, B, C, D, X, WORK, INFO) =
          Lapack.dgglse(M, N, P, A, LDA, B, LDB, C, D, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_C = ValuesUtil.makeRealArray(C);
        val_D = ValuesUtil.makeRealArray(D);
        val_X = ValuesUtil.makeRealArray(X);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_C, arg_D, arg_X, arg_WORK, arg_INFO};
        val_out = {val_A, val_B, val_C, val_D, val_X, val_WORK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgtsv", {arg_N, arg_NRHS, arg_DL, arg_D, arg_DU, arg_B, arg_LDB,
                   arg_INFO},
        cache, env, st)
      equation
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (NRHS, cache, st) = evaluateExtIntArg(arg_NRHS, cache, env, st);
        (DL, cache, st) = evaluateExtRealArrayArg(arg_DL, cache, env, st);
        (D, cache, st) = evaluateExtRealArrayArg(arg_D, cache, env, st);
        (DU, cache, st) = evaluateExtRealArrayArg(arg_DU, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (DL, D, DU, B, INFO) =
          Lapack.dgtsv(N, NRHS, DL, D, DU, B, LDB);
        val_DL = ValuesUtil.makeRealArray(DL);
        val_D = ValuesUtil.makeRealArray(D);
        val_DU = ValuesUtil.makeRealArray(DU);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_DL, arg_D, arg_DU, arg_B, arg_INFO};
        val_out = {val_DL, val_D, val_DU, val_B, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgbsv", {arg_N, arg_KL, arg_KU, arg_NRHS, arg_AB, arg_LDAB, arg_IPIV,
                   arg_B, arg_LDB, arg_INFO},
        cache, env, st)
      equation
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (KL, cache, st) = evaluateExtIntArg(arg_KL, cache, env, st);
        (KU, cache, st) = evaluateExtIntArg(arg_KU, cache, env, st);
        (NRHS, cache, st) = evaluateExtIntArg(arg_NRHS, cache, env, st);
        (AB, cache, st) = evaluateExtRealMatrixArg(arg_AB, cache, env, st);
        (LDAB, cache, st) = evaluateExtIntArg(arg_LDAB, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (AB, IPIV, B, INFO) =
          Lapack.dgbsv(N, KL, KU, NRHS, AB, LDAB, B, LDB);
        val_AB = ValuesUtil.makeRealMatrix(AB);
        val_IPIV = ValuesUtil.makeIntArray(IPIV);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_AB, arg_IPIV, arg_B, arg_INFO};
        val_out = {val_AB, val_IPIV, val_B, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgesvd", {arg_JOBU, arg_JOBVT, arg_M, arg_N, arg_A, arg_LDA, arg_S,
                    arg_U, arg_LDU, arg_VT, arg_LDVT, arg_WORK, arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (JOBU, cache, st) = evaluateExtStringArg(arg_JOBU, cache, env, st);
        (JOBVT, cache, st) = evaluateExtStringArg(arg_JOBVT, cache, env, st);
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (LDU, cache, st) = evaluateExtIntArg(arg_LDU, cache, env, st);
        (LDVT, cache, st) = evaluateExtIntArg(arg_LDVT, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (LWORK, cache, st) = evaluateExtIntArg(arg_LWORK, cache, env, st);
        (A, S, U, VT, WORK, INFO) =
          Lapack.dgesvd(JOBU, JOBVT, M, N, A, LDA, LDU, LDVT, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_S = ValuesUtil.makeRealArray(S);
        val_U = ValuesUtil.makeRealMatrix(U);
        val_VT = ValuesUtil.makeRealMatrix(VT);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_S, arg_U, arg_VT, arg_WORK, arg_INFO};
        val_out = {val_A, val_S, val_U, val_VT, val_WORK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgetrf", {arg_M, arg_N, arg_A, arg_LDA, arg_IPIV, arg_INFO},
        cache, env, st)
      equation
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (A, IPIV, INFO) =
          Lapack.dgetrf(M, N, A, LDA);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_IPIV = ValuesUtil.makeIntArray(IPIV);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_IPIV, arg_INFO};
        val_out = {val_A, val_IPIV, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgetrs", {arg_TRANS, arg_N, arg_NRHS, arg_A, arg_LDA, arg_IPIV, arg_B,
                    arg_LDB, arg_INFO},
        cache, env, st)
      equation
        (TRANS, cache, st) = evaluateExtStringArg(arg_TRANS, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (NRHS, cache, st) = evaluateExtIntArg(arg_NRHS, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (IPIV, cache, st) = evaluateExtIntArrayArg(arg_IPIV, cache, env, st);
        (B, cache, st) = evaluateExtRealMatrixArg(arg_B, cache, env, st);
        (LDB, cache, st) = evaluateExtIntArg(arg_LDB, cache, env, st);
        (B, INFO) =
          Lapack.dgetrs(TRANS, N, NRHS, A, LDA, IPIV, B, LDB);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_B, arg_INFO};
        val_out = {val_B, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgetri", {arg_N, arg_A, arg_LDA, arg_IPIV, arg_WORK, arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (IPIV, cache, st) = evaluateExtIntArrayArg(arg_IPIV, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (LWORK, cache, st) = evaluateExtIntArg(arg_LWORK, cache, env, st);
        (A, WORK, INFO) =
          Lapack.dgetri(N, A, LDA, IPIV, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_WORK, arg_INFO};
        val_out = {val_A, val_WORK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dgeqpf", {arg_M, arg_N, arg_A, arg_LDA, arg_JPVT, arg_TAU, arg_WORK,
                    arg_INFO},
        cache, env, st)
      equation
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (JPVT, cache, st) = evaluateExtIntArrayArg(arg_JPVT, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (A, JPVT, TAU, INFO) =
          Lapack.dgeqpf(M, N, A, LDA, JPVT, WORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_JPVT = ValuesUtil.makeIntArray(JPVT);
        val_TAU = ValuesUtil.makeRealArray(TAU);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_JPVT, arg_TAU, arg_INFO};
        val_out = {val_A, val_JPVT, val_TAU, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);

    case("dorgqr", {arg_M, arg_N, arg_K, arg_A, arg_LDA, arg_TAU, arg_WORK,
                    arg_LWORK, arg_INFO},
        cache, env, st)
      equation
        (M, cache, st) = evaluateExtIntArg(arg_M, cache, env, st);
        (N, cache, st) = evaluateExtIntArg(arg_N, cache, env, st);
        (K, cache, st) = evaluateExtIntArg(arg_K, cache, env, st);
        (A, cache, st) = evaluateExtRealMatrixArg(arg_A, cache, env, st);
        (LDA, cache, st) = evaluateExtIntArg(arg_LDA, cache, env, st);
        (TAU, cache, st) = evaluateExtRealArrayArg(arg_TAU, cache, env, st);
        (WORK, cache, st) = evaluateExtRealArrayArg(arg_WORK, cache, env, st);
        (LWORK, cache, st) = evaluateExtIntArg(arg_LWORK, cache, env, st);
        (A, WORK, INFO) =
          Lapack.dorgqr(M, N, K, A, LDA, TAU, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_WORK, arg_INFO};
        val_out = {val_A, val_WORK, val_INFO};
        (cache, env, st) = assignExtOutputs(arg_out, val_out, cache, env, st);
      then
        (cache, env, st);
  end match;
end evaluateExternalFunc;

protected function evaluateElements
  "This function evaluates a list of elements."
  input list<DAE.Element> inElements;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input LoopControl inLoopControl;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
  match(inElements, inCache, inEnv, inLoopControl, inST)
    local
      DAE.Element elem;
      list<DAE.Element> rest_elems;
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
      SymbolTable st;

    case (_, _, _, RETURN(), _) then (inCache, inEnv, inLoopControl, inST);
    case ({}, _, _, _, _) then (inCache, inEnv, NEXT(), inST);
    case (elem :: rest_elems, _, _, _, st)
      equation
        (cache, env, loop_ctrl, st) = evaluateElement(elem, inCache, inEnv, st);
        (cache, env, loop_ctrl, st) =
          evaluateElements(rest_elems, cache, env, loop_ctrl, st);
      then
        (cache, env, loop_ctrl, st);
  end match;
end evaluateElements;

protected function evaluateElement
  "This function evaluates a single element, which should be an algorithm."
  input DAE.Element inElement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) := match(inElement, inCache, inEnv, inST)
    local
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
      list<DAE.Statement> sl;
      SymbolTable st;

    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = sl)), _, _, st)
      equation
        (sl, (_,env)) = DAEUtil.traverseDAEEquationsStmts(sl, Expression.traverseSubexpressionsHelper, (optimizeExpTraverser, inEnv));
        (cache, env, loop_ctrl, st) = evaluateStatements(sl, inCache, env, st);
      then
        (cache, env, loop_ctrl, st);
   end match;
end evaluateElement;

protected function evaluateStatement
  "This function evaluates a statement."
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
  match(inStatement, inCache, inEnv, inST)
    local
      FCore.Cache cache;
      FCore.Graph env;
      DAE.Exp lhs, rhs, condition;
      DAE.ComponentRef lhs_cref;
      Values.Value rhs_val;
      list<DAE.Exp> exps;
      list<Values.Value> vals;
      list<DAE.Statement> statements;
      Absyn.Path path;
      LoopControl loop_ctrl;
      SymbolTable st;

    case (DAE.STMT_ASSIGN(exp1 = lhs, exp = rhs), cache, env, st)
      equation
        (cache, rhs_val, st) = cevalExp(rhs, cache, env, st);
        lhs_cref = extractLhsComponentRef(lhs);
        (cache, env, st) = assignVariable(lhs_cref, rhs_val, cache, env, st);
      then
        (cache, env, NEXT(), st);

    case (DAE.STMT_TUPLE_ASSIGN(), _, _, st)
      equation
        (cache, env, st) =
          evaluateTupleAssignStatement(inStatement, inCache, inEnv, st);
      then
        (cache, env, NEXT(), st);

    case (DAE.STMT_ASSIGN_ARR(lhs = lhs, exp = rhs), _, env, st)
      equation
        (cache, rhs_val, st) = cevalExp(rhs, inCache, env, st);
        lhs_cref = extractLhsComponentRef(lhs);
        (cache, env, st) = assignVariable(lhs_cref, rhs_val, cache, env, st);
      then
        (cache, env, NEXT(), st);

    case (DAE.STMT_IF(), _, _, st)
      equation
        (cache, env, loop_ctrl, st) =
          evaluateIfStatement(inStatement, inCache, inEnv, st);
      then
        (cache, env, loop_ctrl, st);

    case (DAE.STMT_FOR(), _, _, st)
      equation
        (cache, env, loop_ctrl, st) =
          evaluateForStatement(inStatement, inCache, inEnv, st);
      then
        (cache, env, loop_ctrl, st);

    case (DAE.STMT_WHILE(exp = condition, statementLst = statements), _, _, st)
      equation
        (cache, env, loop_ctrl, st) =
          evaluateWhileStatement(condition, statements, inCache, inEnv, NEXT(), st);
      then
        (cache, env, loop_ctrl, st);

    // If the condition is true in the assert, do nothing. If the condition
    // is false we should stop the instantiation (depending on the assertion
    // level), but we can't really do much about that here. So right now we just
    // fail.
    case (DAE.STMT_ASSERT(cond = condition), _, _, st)
      equation
        (cache, Values.BOOL(boolean = true), st) =
          cevalExp(condition, inCache, inEnv, st);
      then
        (cache, inEnv, NEXT(), st);

    // Special case for print, and other known calls for now; evaluated even when there is no ST
    case (DAE.STMT_NORETCALL(exp = rhs as DAE.CALL(path = path, expLst = exps)), _, _, _)
      algorithm
        (cache, vals, st) := cevalExpList(exps, inCache, inEnv, inST);
        if isSome(st) then
          (cache, _, st) := cevalExp(rhs, cache, inEnv, st);
        else
          (cache, _) := Ceval.cevalKnownExternalFuncs(cache,inEnv,path,vals,Absyn.NO_MSG());
        end if;
      then
        (cache, inEnv, NEXT(), st);

    case (DAE.STMT_RETURN(), _, _, _)
      then
        (inCache, inEnv, RETURN(), inST);

    case (DAE.STMT_BREAK(), _, _, _)
      then
        (inCache, inEnv, BREAK(), inST);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CevalFunction.evaluateStatement failed for:");
        Debug.traceln(DAEDump.ppStatementStr(inStatement));
      then
        fail();
  end match;
end evaluateStatement;

protected function evaluateStatements
  "This function evaluates a list of statements. This is just a wrapper for
  evaluateStatements2."
  input list<DAE.Statement> inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
    evaluateStatements2(inStatement, inCache, inEnv, NEXT(), inST);
end evaluateStatements;

protected function evaluateStatements2
  "This is a helper function to evaluateStatements that evaluates a list of
  statements."
  input list<DAE.Statement> inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input LoopControl inLoopControl;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
  match(inStatement, inCache, inEnv, inLoopControl, inST)
    local
      DAE.Statement stmt;
      list<DAE.Statement> rest_stmts;
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
      SymbolTable st;
    case (_, _, _, BREAK(), _) then (inCache, inEnv, inLoopControl, inST);
    case (_, _, _, RETURN(), _) then (inCache, inEnv, inLoopControl, inST);
    case ({}, _, _, _, _) then (inCache, inEnv, inLoopControl, inST);
    case (stmt :: rest_stmts, _, _, NEXT(), st)
      equation
        (cache, env, loop_ctrl, st) = evaluateStatement(stmt, inCache, inEnv, st);
        (cache, env, loop_ctrl, st) =
          evaluateStatements2(rest_stmts, cache, env, loop_ctrl, st);
      then
        (cache, env, loop_ctrl, st);
  end match;
end evaluateStatements2;

protected function evaluateTupleAssignStatement
  "This function evaluates tuple assignment statements, i.e. assignment
  statements where the right hand side expression is a tuple. Ex:
    (x, y, z) := fun(...)"
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) := match(inStatement, inCache, inEnv, inST)
    local
      list<DAE.Exp> lhs_expl;
      DAE.Exp rhs;
      list<Values.Value> rhs_vals;
      list<DAE.ComponentRef> lhs_crefs;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;

    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = lhs_expl, exp = rhs), _, env, st)
      equation
        (cache, Values.TUPLE(valueLst = rhs_vals), st) =
          cevalExp(rhs, inCache, env, st);
        lhs_crefs = List.map(lhs_expl, extractLhsComponentRef);
        (cache, env, st) = assignTuple(lhs_crefs, rhs_vals, cache, env, st);
      then
      (cache, env, st);
  end match;
end evaluateTupleAssignStatement;

protected function evaluateIfStatement
  "This function evaluates an if statement."
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
  match(inStatement, inCache, inEnv, inST)
    local
      DAE.Exp cond;
      list<DAE.Statement> stmts;
      DAE.Else else_branch;
      FCore.Cache cache;
      FCore.Graph env;
      Boolean bool_cond;
      LoopControl loop_ctrl;
      SymbolTable st;

    case (DAE.STMT_IF(exp = cond, statementLst = stmts, else_ = else_branch), _, _, st)
      equation
        (cache, Values.BOOL(boolean = bool_cond), st) =
          cevalExp(cond, inCache, inEnv, st);
        (cache, env, loop_ctrl, st) = evaluateIfStatement2(bool_cond, stmts,
          else_branch, cache, inEnv, st);
      then
        (cache, env, loop_ctrl, st);
  end match;
end evaluateIfStatement;

protected function evaluateIfStatement2
  "Helper function to evaluateIfStatement."
  input Boolean inCondition;
  input list<DAE.Statement> inStatements;
  input DAE.Else inElse;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
  match(inCondition, inStatements, inElse, inCache, inEnv, inST)
    local
      FCore.Cache cache;
      FCore.Graph env;
      list<DAE.Statement> statements;
      DAE.Exp condition;
      Boolean bool_condition;
      DAE.Else else_branch;
      LoopControl loop_ctrl;
      SymbolTable st;

    // If the condition is true, evaluate the statements in the if branch.
    case (true, statements, _, _, env, st)
      equation
        (cache, env, loop_ctrl, st) =
          evaluateStatements(statements, inCache, env, st);
      then
        (cache, env, loop_ctrl, st);
    // If the condition is false and we have an else, evaluate the statements in
    // the else branch.
    case (false, _, DAE.ELSE(statementLst = statements), _, env, st)
      equation
        (cache, env, loop_ctrl, st) =
          evaluateStatements(statements, inCache, env, st);
      then
        (cache, env, loop_ctrl, st);
    // If the condition is false and we have an else if, call this function
    // again recursively.
    case (false, _, DAE.ELSEIF(exp = condition, statementLst = statements,
        else_ = else_branch), _, env, st)
      equation
        (cache, Values.BOOL(boolean = bool_condition), st) =
          cevalExp(condition, inCache, env, st);
        (cache, env, loop_ctrl, st) =
          evaluateIfStatement2(bool_condition, statements, else_branch, cache, env, st);
      then
        (cache, env, loop_ctrl, st);
     // If the condition is false and we have no else branch, just continue.
    case (false, _, DAE.NOELSE(), _, _, _) then (inCache, inEnv, NEXT(), inST);
  end match;
end evaluateIfStatement2;

protected function evaluateForStatement
  "This function evaluates for statements."
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
  matchcontinue(inStatement, inCache, inEnv, inST)
    local
      DAE.Type ety;
      DAE.Type ty;
      String iter_name;
      DAE.Exp    range;
      list<DAE.Statement> statements;
      list<Values.Value> range_vals;
      FCore.Cache cache;
      FCore.Graph env;
      DAE.ComponentRef iter_cr;
      LoopControl loop_ctrl;
      SymbolTable st;

    // The case where the range is an array.
    case (DAE.STMT_FOR(type_ = ety, iter = iter_name,
        range = range, statementLst = statements), _, env, st)
      equation
        (cache, Values.ARRAY(valueLst = range_vals), st) =
          cevalExp(range, inCache, env, st);
        (env, ty, iter_cr) = extendEnvWithForScope(iter_name, ety, env);
        (cache, env, loop_ctrl, st) = evaluateForLoopArray(cache, env, iter_cr,
          ty, range_vals, statements, NEXT(), st);
      then
      (cache, env, loop_ctrl, st);

    case (DAE.STMT_FOR(range = range), _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- evaluateForStatement not implemented for:");
        Debug.traceln(ExpressionDump.printExpStr(range));
      then
        fail();
  end matchcontinue;
end evaluateForStatement;

protected function evaluateForLoopArray
  "This function evaluates a for loop where the range is an array."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inIter;
  input DAE.Type inIterType;
  input list<Values.Value> inValues;
  input list<DAE.Statement> inStatements;
  input LoopControl inLoopControl;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) := match(inCache, inEnv, inIter,
      inIterType, inValues, inStatements, inLoopControl, inST)
    local
      Values.Value value;
      list<Values.Value> rest_vals;
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
      SymbolTable st;

    case (_, _, _, _, _, _, BREAK(), _) then (inCache, inEnv, NEXT(), inST);
    case (_, _, _, _, _, _, RETURN(), _) then (inCache, inEnv, inLoopControl, inST);
    case (_, _, _, _, {}, _, _, _) then (inCache, inEnv, inLoopControl, inST);
    case (_, env, _, _, value :: rest_vals, _, NEXT(), st)
      equation
        env = updateVariableBinding(inIter, env, inIterType, value);
        (cache, env, loop_ctrl, st) =
          evaluateStatements(inStatements, inCache, env, st);
        (cache, env, loop_ctrl, st) = evaluateForLoopArray(cache, env, inIter,
          inIterType, rest_vals, inStatements, loop_ctrl, st);
      then
        (cache, env, loop_ctrl, st);
  end match;
end evaluateForLoopArray;

protected function evaluateWhileStatement
  "This function evaluates a while statement."
  input DAE.Exp inCondition;
  input list<DAE.Statement> inStatements;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input LoopControl inLoopControl;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outLoopControl, outST) :=
  match(inCondition, inStatements, inCache, inEnv, inLoopControl, inST)
    local
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
      SymbolTable st;
      Boolean b;

    case (_, _, _, _, BREAK(), _) then (inCache, inEnv, NEXT(), inST);
    case (_, _, _, _, RETURN(), _) then (inCache, inEnv, inLoopControl, inST);
    case (_, _, _, _, _, st)
      equation
        (cache, Values.BOOL(boolean = b), st) = cevalExp(inCondition, inCache, inEnv, st);
        if b then
          (cache, env, loop_ctrl, st) = evaluateStatements(inStatements, cache, inEnv, st);
          (cache, env, loop_ctrl, st) = evaluateWhileStatement(inCondition, inStatements, cache, env, loop_ctrl, st);
        else
          loop_ctrl = NEXT();
          env = inEnv;
        end if;
      then
        (cache, env, loop_ctrl, st);

  end match;
end evaluateWhileStatement;

protected function extractLhsComponentRef
  "This function extracts a component reference from an expression. It's used to
  get the left hand side component reference in simple assignments."
  input DAE.Exp inExp;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match (inExp)
    local
      DAE.ComponentRef cref;
    case DAE.CREF(componentRef = cref) then cref;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CevalFunction.extractLhsComponentRef failed on " + ExpressionDump.printExpStr(inExp));
      then
        fail();
  end match;
end extractLhsComponentRef;

protected function cevalExp
  "A wrapper for Ceval with most of the arguments filled in."
  input DAE.Exp inExp;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output SymbolTable outST;
algorithm
  (outCache, outValue, outST) := Ceval.ceval(inCache, inEnv, inExp, true, inST, Absyn.NO_MSG(), 0);
end cevalExp;

protected function cevalExpList
  "A wrapper for Ceval with most of the arguments filled in."
  input list<DAE.Exp> inExpLst;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output list<Values.Value> outValue;
  output SymbolTable outST;
algorithm
  (outCache, outValue, outST) := Ceval.cevalList(inCache, inEnv, inExpLst, true, inST, Absyn.NO_MSG(), 0);
end cevalExpList;

// [EENV]  Environment extension functions (add variables).

protected function setupFunctionEnvironment
  "Opens up a new scope for the functions and adds all function variables to it."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFuncName;
  input list<FunctionVar> inFuncParams;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  outEnv := FGraph.openScope(inEnv, SCode.NOT_ENCAPSULATED(), SOME(inFuncName), SOME(FCore.FUNCTION_SCOPE()));
  (outCache, outEnv, outST) :=
    extendEnvWithFunctionVars(inCache, outEnv, inFuncParams, inST);
end setupFunctionEnvironment;

protected function extendEnvWithFunctionVars
  "Extends the environment with a list of variables. The list of values is the
  input arguments to the function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<FunctionVar> inFuncParams;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) := match(inCache, inEnv, inFuncParams, inST)
    local
      FunctionVar param;
      list<FunctionVar> rest_params;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;

    case (_, _, {}, _) then (inCache, inEnv, inST);

    case (cache, env, param :: rest_params, st)
      equation
        (cache, env, st) = extendEnvWithFunctionVar(cache, env, param, st);
        (cache, env, st) = extendEnvWithFunctionVars(cache, env, rest_params, st);
      then
        (cache, env, st);

  end match;
end extendEnvWithFunctionVars;

protected function extendEnvWithFunctionVar
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input FunctionVar inFuncParam;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) := matchcontinue(inCache, inEnv, inFuncParam, inST)
    local
      DAE.Element e;
      Option<Values.Value> val;
      FCore.Cache cache;
      FCore.Graph env;
      Option<DAE.Exp> binding_exp;
      SymbolTable st;

    // Input parameters are assigned their corresponding input argument given to
    // the function.
    case (_, env, (e, val as SOME(_)), st)
      equation
        (cache, env, st) = extendEnvWithElement(e, val, inCache, env, st);
      then
        (cache, env, st);

    // Non-input parameters might have a default binding, so we use that if it's
    // available.
    case (_, env, ((e as DAE.VAR(binding = binding_exp)), NONE()), st)
      equation
        (val, cache, st) = evaluateBinding(binding_exp, inCache, inEnv, st);
        (cache, env, st) = extendEnvWithElement(e, val, cache, env, st);
      then
        (cache, env, st);

    case (_, _, (e, _), _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CevalFunction.extendEnvWithFunctionVars failed for:");
        Debug.traceln(DAEDump.dumpElementsStr({e}));
      then
        fail();
  end matchcontinue;
end extendEnvWithFunctionVar;

protected function evaluateBinding
  "Evaluates an optional binding expression. If SOME expression is given,
  returns SOME value or fails. If NONE expression given, returns NONE value."
  input Option<DAE.Exp> inBinding;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output Option<Values.Value> outValue;
  output FCore.Cache outCache;
  output SymbolTable outST;
algorithm
  (outValue, outCache, outST) := match(inBinding, inCache, inEnv, inST)
    local
      DAE.Exp binding_exp;
      FCore.Cache cache;
      Values.Value val;
      SymbolTable st;

    case (SOME(binding_exp), _, _, _)
      equation
        (cache, val, st) = cevalExp(binding_exp, inCache, inEnv, inST);
      then
        (SOME(val), cache, st);

    case (NONE(), _, _, _) then (NONE(), inCache, inST);
  end match;
end evaluateBinding;

protected function extendEnvWithElement
  "This function extracts the necessary data from a variable element, and calls
  extendEnvWithVar to add a new variable to the environment."
  input DAE.Element inElement;
  input Option<Values.Value> inBindingValue;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) :=
  match(inElement, inBindingValue, inCache, inEnv, inST)
    local
      DAE.ComponentRef cr;
      String name;
      DAE.Type ty;
      DAE.InstDims dims;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;

    case (DAE.VAR(componentRef = cr, ty = ty, dims = dims), _, _, _, st)
      equation
        name = ComponentReference.crefStr(cr);
        (cache, env, st) =
          extendEnvWithVar(name, ty, inBindingValue, dims, inCache, inEnv, st);
      then
        (cache, env, st);
  end match;
end extendEnvWithElement;

protected function extendEnvWithVar
  "This function does the actual work of extending the environment with a
  variable."
  input String inName;
  input DAE.Type inType;
  input Option<Values.Value> inOptValue;
  input DAE.InstDims inDims;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) :=
  matchcontinue(inName, inType, inOptValue, inDims, inCache, inEnv, inST)
    local
      DAE.Type ty;
      DAE.Var var;
      DAE.Binding binding;
      FCore.Cache cache;
      FCore.Graph env, record_env;
      SymbolTable st;

    // Records are special, since they have their own environment with their
    // components in them. A record variable is thus always unbound, and their
    // values are instead determined by their components values.
    case (_, _, _, _, _, _, _)
      equation
        true = Types.isRecord(inType);
        binding = getBinding(inOptValue);
        (cache, ty, st) =
          appendDimensions(inType, inOptValue, inDims, inCache, inEnv, inST);
        var = makeFunctionVariable(inName, ty, binding);
        (cache, record_env, st) =
          makeRecordEnvironment(inType, inOptValue, cache, inEnv, st);
        env = FGraph.mkComponentNode(
                inEnv,
                var,
                SCode.COMPONENT(
                  inName,
                  SCode.defaultPrefixes,
                  SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(),Absyn.NONFIELD()),
                  Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
                  SCode.noComment, NONE(), Absyn.dummyInfo),
                DAE.NOMOD(),
                FCore.VAR_TYPED(),
                record_env);
      then
        (cache, env, st);

    // Normal variables.
    else
      equation
        binding = getBinding(inOptValue);
        (cache, ty, st) =
          appendDimensions(inType, inOptValue, inDims, inCache, inEnv, inST);
        var = makeFunctionVariable(inName, ty, binding);
        env = FGraph.mkComponentNode(
                inEnv,
                var,
                SCode.COMPONENT(
                  inName,
                  SCode.defaultPrefixes,
                  SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(),Absyn.NONFIELD()),
                  Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
                  SCode.noComment, NONE(), Absyn.dummyInfo),
                DAE.NOMOD(),
                FCore.VAR_TYPED(),
                FGraph.empty());
      then
        (cache, env, st);

  end matchcontinue;
end extendEnvWithVar;

protected function makeFunctionVariable
  "This function creates a new variable ready to be added to an environment
  given a name, type and binding."
  input String inName;
  input DAE.Type inType;
  input DAE.Binding inBinding;
  output DAE.Var outVar;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outVar := DAE.TYPES_VAR(inName, DAE.dummyAttrVar, inType, inBinding, NONE());
end makeFunctionVariable;

protected function getBinding
  "Creates a binding from an optional value. If some value is given we return a
  value bound binding, otherwise an unbound binding."
  input Option<Values.Value> inBindingValue;
  output DAE.Binding outBinding;
algorithm
  outBinding := match(inBindingValue)
    local Values.Value val;
    case SOME(val) then DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE());
    case NONE() then DAE.UNBOUND();
  end match;
end getBinding;

protected function makeRecordEnvironment
  "This function creates an environment for a record variable by creating a new
  environment and adding the records components to it. If an optional value is
  supplied it also gives the components a value binding."
  input DAE.Type inRecordType;
  input Option<Values.Value> inOptValue;
  input FCore.Cache inCache;
  input FCore.Graph inGraph;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outRecordEnv;
  output SymbolTable outST;
algorithm
  (outCache, outRecordEnv, outST) :=
  match(inRecordType, inOptValue, inCache, inGraph, inST)
    local
      list<DAE.Var> var_lst;
      list<Option<Values.Value>> vals;
      FCore.Cache cache;
      FCore.Graph graph;
      SymbolTable st;
      FCore.Ref parent, child;
      FCore.Node node;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(),varLst = var_lst), _, _, _, st)
      equation
        parent = FGraph.lastScopeRef(inGraph);
        (graph, node) = FGraph.node(inGraph, FNode.feNodeName, {parent}, FCore.ND(NONE()));
        child = FNode.toRef(node);
        FNode.addChildRef(parent, FNode.feNodeName, child);
        graph = FGraph.pushScopeRef(graph, child);

        vals = getRecordValues(inOptValue, inRecordType);
        ((cache, graph, st)) = List.threadFold(var_lst, vals,
          extendEnvWithRecordVar, (inCache, graph, st));
      then
        (cache, graph, st);
  end match;
end makeRecordEnvironment;

protected function getRecordValues
  "This function returns a list of optional values that will be assigned to a
  records components. If some record value is given it returns the list of
  values inside it, made into options, otherwise it returns a list of as many
  NONE as there are components in the record."
  input Option<Values.Value> inOptValue;
  input DAE.Type inRecordType;
  output list<Option<Values.Value>> outValues;
algorithm
  outValues := match(inOptValue, inRecordType)
    local
      list<Values.Value> vals;
      list<Option<Values.Value>> opt_vals;
      list<DAE.Var> vars;
      Integer n;
    case (SOME(Values.RECORD(orderd = vals)), _)
      equation
        opt_vals = List.map(vals, Util.makeOption);
      then
        opt_vals;

    case (NONE(), DAE.T_COMPLEX(varLst = vars))
      equation
        n = listLength(vars);
        opt_vals = List.fill(NONE(), n);
      then
        opt_vals;
  end match;
end getRecordValues;

protected function extendEnvWithRecordVar
  "This function extends an environment with a record component."
  input DAE.Var inVar;
  input Option<Values.Value> inOptValue;
  input tuple<FCore.Cache, FCore.Graph, SymbolTable> inEnv;
  output tuple<FCore.Cache, FCore.Graph, SymbolTable> outEnv;
algorithm
  outEnv := match(inVar, inOptValue, inEnv)
    local
      String name;
      DAE.Type ty;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;

    case (DAE.TYPES_VAR(name = name, ty = ty), _, (cache, env, st))
      equation
        (cache, env, st) =
          extendEnvWithVar(name, ty, inOptValue, {}, cache, env, st);
        outEnv = (cache, env, st);
      then
        outEnv;
  end match;
end extendEnvWithRecordVar;

protected function extendEnvWithForScope
  "This function opens a new for loop scope in the environment by opening a new
  scope and adding the given iterator to it. For convenience it also returns the
  type and component reference of the iterator."
  input String inIterName;
  input DAE.Type inIterType;
  input FCore.Graph inEnv;
  output FCore.Graph outEnv;
  output DAE.Type outIterType;
  output DAE.ComponentRef outIterCref;
protected
  DAE.ComponentRef iter_cr;
algorithm
  outIterType := Types.expTypetoTypesType(inIterType);
  outEnv := FGraph.addForIterator(inEnv, inIterName, outIterType,
    DAE.UNBOUND(), SCode.CONST(), SOME(DAE.C_CONST()));
  outIterCref := ComponentReference.makeCrefIdent(inIterName, inIterType, {});
end extendEnvWithForScope;

protected function appendDimensions
  "This function appends dimensions to a type. This is needed because DAE.VAR
  separates the type and dimensions, while DAE.TYPES_VAR keeps the dimension
  information in the type itself. The dimensions can come from two sources:
  either they are specified in the variable itself as DAE.InstDims, or if the
  variable is declared with unknown dimensions they can be determined from the
  variables binding (i.e. input argument to the function)."
  input DAE.Type inType;
  input Option<Values.Value> inOptBinding;
  input DAE.InstDims inDims;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output DAE.Type outType;
  output SymbolTable outST;
protected
  list<Integer> binding_dims;
algorithm
  binding_dims := ValuesUtil.valueDimensions(
    Util.getOptionOrDefault(inOptBinding, Values.INTEGER(0)));
  (outCache, outType, outST) :=
    appendDimensions2(inType, inDims, binding_dims, inCache, inEnv, inST);
end appendDimensions;

protected function appendDimensions2
  "Helper function to appendDimensions. Appends dimensions to a type. inDims is
  the declared dimensions of the variable while inBindingDims is the dimensions
  of the variables binding (empty list if it doesn't have a binding)."
  input DAE.Type inType;
  input DAE.InstDims inDims;
  input list<Integer> inBindingDims;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output DAE.Type outType;
  output SymbolTable outST;
algorithm
  (outCache, outType, outST) :=
  matchcontinue(inType, inDims, inBindingDims, inCache, inEnv, inST)
    local
      DAE.InstDims rest_dims;
      DAE.Exp dim_exp;
      Values.Value dim_val;
      Integer dim_int;
      DAE.Dimension dim;
      DAE.Type ty;
      list<Integer> bind_dims;
      DAE.Subscript sub;
      FCore.Cache cache;
      SymbolTable st;

    case (ty, {}, _, _, _, _) then (inCache, ty, inST);

    case (ty, DAE.DIM_UNKNOWN() :: rest_dims, dim_int :: bind_dims, _, _, st)
      equation
        dim = Expression.intDimension(dim_int);
        (cache, ty, st) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv, st);
      then
        (cache, DAE.T_ARRAY(ty, {dim}, DAE.emptyTypeSource), st);

    // If the variable is not an input, set the dimension size to 0 (dynamic size).
    case (ty, DAE.DIM_UNKNOWN() :: rest_dims, bind_dims, _, _, st)
      equation
        (cache, ty, st) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv, st);
      then
        (cache, DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(0)}, DAE.emptyTypeSource), st);

    case (ty, DAE.DIM_INTEGER(dim_int) :: rest_dims, bind_dims, _, _, st)
      equation
        dim = DAE.DIM_INTEGER(dim_int);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty, st) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv, st);
      then
        (cache, DAE.T_ARRAY(ty, {dim}, DAE.emptyTypeSource), st);

    case (ty, DAE.DIM_BOOLEAN() :: rest_dims, bind_dims, _, _, st)
      equation
        dim = DAE.DIM_INTEGER(2);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty, st) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv, st);
      then
        (cache, DAE.T_ARRAY(ty, {dim}, DAE.emptyTypeSource), st);

    case (ty, DAE.DIM_ENUM(size = dim_int) :: rest_dims, bind_dims, _, _, st)
      equation
        dim = DAE.DIM_INTEGER(dim_int);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty, st) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv, st);
      then
        (cache, DAE.T_ARRAY(ty, {dim}, DAE.emptyTypeSource), st);

    case (ty, DAE.DIM_EXP(exp = dim_exp) :: rest_dims, bind_dims, _, _, st)
      equation
        (cache, dim_val, st) = cevalExp(dim_exp, inCache, inEnv, st);
        dim_int = ValuesUtil.valueInteger(dim_val);
        dim = DAE.DIM_INTEGER(dim_int);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty, st) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv, st);
      then
        (cache, DAE.T_ARRAY(ty, {dim}, DAE.emptyTypeSource), st);

    case (_, _ :: _, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- CevalFunction.appendDimensions2 failed\n");
      then
        fail();
  end matchcontinue;
end appendDimensions2;

// [MENV]  Environment manipulation functions (set and get variables).

protected function assignVariable
  "This function assigns a variable in the environment a new value."
  input DAE.ComponentRef inCref;
  input Values.Value inNewValue;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) :=
  matchcontinue(inCref, inNewValue, inCache, inEnv, inST)
    local
      DAE.ComponentRef cr, cr_rest;
      FCore.Cache cache;
      FCore.Graph env;
      list<DAE.Subscript> subs;
      DAE.Type ty;
      DAE.Type ety;
      Values.Value val;
      DAE.Var var;
      FCore.Status inst_status;
      String id, comp_id;
      SymbolTable st;

    // Wildcard, no need to assign anything.
    case (DAE.WILD(), _, _, _, _) then (inCache, inEnv, inST);

    // A record assignment.
    case (DAE.CREF_IDENT(ident = id, subscriptLst = {}, identType = ety as
        DAE.T_COMPLEX(complexClassType = ClassInf.RECORD())), _, _, _, st)
      equation
        (_, var, _, _, inst_status, env) =
          Lookup.lookupIdentLocal(inCache, inEnv, id);
        (cache, env, st) = assignRecord(ety, inNewValue, inCache, env, st);
        var = updateRecordBinding(var, inNewValue);
        env = FGraph.updateComp(inEnv, var, inst_status, env);
      then
        (cache, env, st);

    // If we get a scalar we just update the value.
    case (cr as DAE.CREF_IDENT(subscriptLst = {}), _, _, _, st)
      equation
        ty = Types.unflattenArrayType(Expression.typeof(ValuesUtil.valueExp(inNewValue))); // In case of zero-dimensions, update the dimensions; they are all known now
        env = updateVariableBinding(cr, inEnv, ty, inNewValue);
      then
        (inCache, env, st);

    // If we get a vector we first get the old value and update the relevant
    // part of it, and then update the variables value.
    case (DAE.CREF_IDENT(subscriptLst = subs), _, _, _, st)
      equation
        cr = ComponentReference.crefStripSubs(inCref);
        (ty, val) = getVariableTypeAndValue(cr, inEnv);
        (cache, val, st) = assignVector(inNewValue, val, subs, inCache, inEnv, st);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        (cache, env, st);

    // A qualified component reference is a record component, so first lookup
    // the records environment, and then assign the variable in that environment.
    case (DAE.CREF_QUAL(ident = id, subscriptLst = {},
        componentRef = cr_rest), _, _, _, st)
      equation
        (_, var, _, _, inst_status, env) =
          Lookup.lookupIdentLocal(inCache, inEnv, id);
        (cache, env, st) = assignVariable(cr_rest, inNewValue, inCache, env, st);
        comp_id = ComponentReference.crefFirstIdent(cr_rest);
        var = updateRecordComponentBinding(var, comp_id, inNewValue);
        env = FGraph.updateComp(inEnv, var, inst_status, env);
      then
        (cache, env, st);
  end matchcontinue;
end assignVariable;

protected function assignTuple
  "This function assign a tuple by calling assignVariable for each tuple
  component."
  input list<DAE.ComponentRef> inLhsCrefs;
  input list<Values.Value> inRhsValues;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) :=
  match(inLhsCrefs, inRhsValues, inCache, inEnv, inST)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest_crefs;
      Values.Value value;
      list<Values.Value> rest_vals;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;
    case ({}, _, cache, env, st) then (cache, env, st);
    case (cr :: rest_crefs, value :: rest_vals, cache, env, st)
      equation
        (cache, env, st) = assignVariable(cr, value, cache, env, st);
        (cache, env, st) = assignTuple(rest_crefs, rest_vals, cache, env, st);
      then
        (cache, env, st);
  end match;
end assignTuple;

protected function assignRecord
  input DAE.Type inType;
  input Values.Value inValue;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) := match(inType, inValue, inCache, inEnv, inST)
    local
      list<Values.Value> values;
      list<DAE.Var> vars;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;
    case (DAE.T_COMPLEX(varLst = vars), Values.RECORD(orderd = values), _, _, st)
      equation
        (cache, env, st) = assignRecordComponents(vars, values, inCache, inEnv, st);
      then
        (cache, env, st);
  end match;
end assignRecord;

protected function assignRecordComponents
  input list<DAE.Var> inVars;
  input list<Values.Value> inValues;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SymbolTable outST;
algorithm
  (outCache, outEnv, outST) := match(inVars, inValues, inCache, inEnv, inST)
    local
      list<DAE.Var> rest_vars;
      Values.Value val;
      list<Values.Value> rest_vals;
      String name;
      DAE.ComponentRef cr;
      DAE.Type ty;
      FCore.Cache cache;
      FCore.Graph env;
      SymbolTable st;

    case ({}, {}, _, _, _) then (inCache, inEnv, inST);

    case (DAE.TYPES_VAR(name = name, ty = ty) :: rest_vars, val :: rest_vals, _ , _, st)
      equation
        cr = ComponentReference.makeCrefIdent(name, ty, {});
        (cache, env, st) = assignVariable(cr, val, inCache, inEnv, st);
        (cache, env, st) = assignRecordComponents(rest_vars, rest_vals, cache, env, st);
      then
        (cache, env, st);
  end match;
end assignRecordComponents;

public function assignVector
  "This function assigns a part of a vector by replacing the parts indicated by
  the subscripts in the old value with the new value."
  input Values.Value inNewValue;
  input Values.Value inOldValue;
  input list<DAE.Subscript> inSubscripts;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<GlobalScript.SymbolTable> inST;
  output FCore.Cache outCache;
  output Values.Value outResult;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache, outResult, outST) :=
  matchcontinue(inNewValue, inOldValue, inSubscripts, inCache, inEnv, inST)
    local
      DAE.Exp e;
      Values.Value index, val;
      list<Values.Value> values, values2;
      list<Values.Value> old_values, old_values2, indices;
      list<Integer> dims;
      Integer i;
      DAE.Subscript sub;
      list<DAE.Subscript> rest_subs;
      FCore.Cache cache;
      SymbolTable st;

    // No subscripts, we have either reached the end of the recursion or the
    // whole vector was assigned.
    case (_, _, {}, _, _, _) then (inCache, inNewValue, inST);

    // An index subscript. Extract the indicated vector element and update it
    // with assignVector, and then put it back in the list of old values.
    case (_, Values.ARRAY(valueLst = values, dimLst = dims), DAE.INDEX(exp = e) :: rest_subs, _, _, st)
      equation
        (cache, index, st) = cevalExp(e, inCache, inEnv, st);
        i = ValuesUtil.valueInteger(index);
        val = listGet(values, i);
        (cache, val, st) = assignVector(inNewValue, val, rest_subs, cache, inEnv, st);
        values = List.replaceAt(val, i, values);
      then
        (cache, Values.ARRAY(values, dims), st);

    // A slice.
    case (Values.ARRAY(valueLst = values),
          Values.ARRAY(valueLst = old_values, dimLst = dims),
          DAE.SLICE(exp = e) :: rest_subs, _, _, st)
      equation
        // Evaluate the slice range to a list of values.
        (cache, Values.ARRAY(valueLst = (indices as (Values.INTEGER(integer = i) :: _))), st) =
        cevalExp(e, inCache, inEnv, st);
        // Split the list of old values at the first slice index.
        (old_values, old_values2) = List.split(old_values, i - 1);
        // Update the rest of the old value with assignSlice.
        (cache, values2, st) =
          assignSlice(values, old_values2, indices, rest_subs, i, cache, inEnv, st);
        // Assemble the list of values again.
        values = listAppend(old_values, values2);
      then
        (cache, Values.ARRAY(values, dims), st);

    // A : (whole dimension).
    case (Values.ARRAY(valueLst = values),
          Values.ARRAY(valueLst = values2, dimLst = dims),
          DAE.WHOLEDIM() :: rest_subs, _, _, st)
      equation
        (cache, values, st) =
          assignWholeDim(values, values2, rest_subs, inCache, inEnv, st);
      then
        (cache, Values.ARRAY(values, dims), st);

    case (_, _, sub :: _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        print("- CevalFunction.assignVector failed on: ");
        print(ExpressionDump.printSubscriptStr(sub) + "\n");
      then
        fail();
  end matchcontinue;
end assignVector;

protected function assignSlice
  "This function assigns a slice of a vector given a list of new and old values
  and a list of indices."
  input list<Values.Value> inNewValues;
  input list<Values.Value> inOldValues;
  input list<Values.Value> inIndices;
  input list<DAE.Subscript> inSubscripts;
  input Integer inIndex;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output list<Values.Value> outResult;
  output SymbolTable outST;
algorithm
  (outCache, outResult, outST) :=
  matchcontinue(inNewValues, inOldValues, inIndices, inSubscripts, inIndex,
  inCache, inEnv, inST)
    local
      Values.Value v1, v2, index;
      list<Values.Value> vl1, vl2, rest_indices;
      FCore.Cache cache;
      SymbolTable st;

    case (_, _, {}, _, _, _, _, _) then (inCache, inOldValues, inST);

    // Skip indices that are smaller than the next index in the slice.
    case (vl1, v2 :: vl2, index :: _, _, _, _, _, st)
      equation
        true = (inIndex < ValuesUtil.valueInteger(index));
        (cache, vl1, st) = assignSlice(vl1, vl2, inIndices, inSubscripts,
          inIndex + 1, inCache, inEnv, st);
      then
        (cache, v2 :: vl1, st);

    case (v1 :: vl1, v2 :: vl2, _ :: rest_indices, _, _, _, _, st)
      equation
        (cache, v1, st) = assignVector(v1, v2, inSubscripts, inCache, inEnv, st);
        (cache, vl1, st) = assignSlice(vl1, vl2, rest_indices, inSubscripts,
          inIndex + 1, inCache, inEnv, st);
      then
        (cache, v1 :: vl1, st);
  end matchcontinue;
end assignSlice;

protected function assignWholeDim
  "This function assigns a whole dimension of a vector."
  input list<Values.Value> inNewValues;
  input list<Values.Value> inOldValues;
  input list<DAE.Subscript> inSubscripts;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SymbolTable inST;
  output FCore.Cache outCache;
  output list<Values.Value> outResult;
  output SymbolTable outST;
algorithm
  (outCache, outResult, outST) :=
  match(inNewValues, inOldValues, inSubscripts, inCache, inEnv, inST)
    local
      Values.Value v1, v2;
      list<Values.Value> vl1, vl2;
      FCore.Cache cache;
      SymbolTable st;
    case ({}, _, _, _, _, _) then (inCache, {}, inST);
    case (v1 :: vl1, v2 :: vl2, _, _, _, st)
      equation
        (cache, v1, st) = assignVector(v1, v2, inSubscripts, inCache, inEnv, st);
        (cache, vl1, st) = assignWholeDim(vl1, vl2, inSubscripts, inCache, inEnv, st);
      then
        (cache, v1 :: vl1, st);
  end match;
end assignWholeDim;

protected function updateVariableBinding
  "This function updates a variables binding in the environment."
  input DAE.ComponentRef inVariableCref;
  input FCore.Graph inEnv;
  input DAE.Type inType;
  input Values.Value inNewValue;
  output FCore.Graph outEnv;
protected
  String var_name;
  DAE.Var var;
algorithm
  var_name := ComponentReference.crefStr(inVariableCref);
  var := makeFunctionVariable(var_name, inType,
    DAE.VALBOUND(inNewValue, DAE.BINDING_FROM_DEFAULT_VALUE()));
  outEnv := FGraph.updateComp(inEnv, var, FCore.VAR_TYPED(), FGraph.empty());
end updateVariableBinding;

protected function updateRecordBinding
  "Updates the binding of a record variable."
  input DAE.Var inVar;
  input Values.Value inValue;
  output DAE.Var outVar;
protected
  DAE.Ident name;
  DAE.Attributes attr;
  DAE.Type ty;
  Option<DAE.Const> c;
algorithm
  DAE.TYPES_VAR(name, attr, ty, _, c) := inVar;
  outVar := DAE.TYPES_VAR(name, attr, ty,
    DAE.VALBOUND(inValue, DAE.BINDING_FROM_DEFAULT_VALUE()), c);
end updateRecordBinding;

protected function updateRecordComponentBinding
  "Updates the binding of a record component."
  input DAE.Var inVar;
  input String inComponentId;
  input Values.Value inValue;
  output DAE.Var outVar;
protected
  DAE.Ident name;
  DAE.Attributes attr;
  DAE.Type ty;
  DAE.Binding binding;
  Option<DAE.Const> c;
  Values.Value val;
algorithm
  DAE.TYPES_VAR(name, attr, ty, binding, c) := inVar;
  val := getBindingOrDefault(binding, ty);
  val := updateRecordComponentValue(inComponentId, inValue, val);
  binding := DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE());
  outVar := DAE.TYPES_VAR(name, attr, ty, binding, c);
end updateRecordComponentBinding;

protected function updateRecordComponentValue
  input String inComponentId;
  input Values.Value inComponentValue;
  input Values.Value inRecordValue;
  output Values.Value outRecordValue;
protected
  Absyn.Path name;
  list<Values.Value> vals;
  list<String> comps;
  Integer pos;
algorithm
  Values.RECORD(name, vals, comps, -1) := inRecordValue;
  pos := List.position(inComponentId, comps);
  vals := List.replaceAt(inComponentValue, pos, vals);
  outRecordValue := Values.RECORD(name, vals, comps, -1);
end updateRecordComponentValue;

protected function getVariableTypeAndBinding
  "This function looks a variable up in the environment, and returns it's type
  and binding."
  input DAE.ComponentRef inCref;
  input FCore.Graph inEnv;
  output DAE.Type outType;
  output DAE.Binding outBinding;
algorithm
  (_, _, outType, outBinding, _, _, _, _, _) :=
    Lookup.lookupVar(FCore.emptyCache(), inEnv, inCref);
end getVariableTypeAndBinding;

protected function getVariableTypeAndValue
  "This function looks a variable up in the environment, and returns it's type
  and value. If it doesn't have a value, then a default value will be returned."
  input DAE.ComponentRef inCref;
  input FCore.Graph inEnv;
  output DAE.Type outType;
  output Values.Value outValue;
protected
  DAE.Binding binding;
algorithm
  (outType, binding) := getVariableTypeAndBinding(inCref, inEnv);
  outValue := getBindingOrDefault(binding, outType);
end getVariableTypeAndValue;

protected function getBindingOrDefault
  "Returns the value in a binding, or a default value if binding isn't a value
  binding."
  input DAE.Binding inBinding;
  input DAE.Type inType;
  output Values.Value outValue;
algorithm
  outValue := match(inBinding, inType)
    local
      Values.Value val;
    case (DAE.VALBOUND(valBound = val), _) then val;
    else generateDefaultBinding(inType);
  end match;
end getBindingOrDefault;

protected function generateDefaultBinding
  "This function generates a default value for a type. This is needed when
  assigning parts of an array, since we can only assign parts of an already
  existing array. The value will be the types equivalence to zero."
  input DAE.Type inType;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue(inType)
    local
      DAE.Dimension dim;
      Integer int_dim;
      list<Integer> dims;
      DAE.Type ty;
      list<Values.Value> values;
      Values.Value value;
      Absyn.Path path;
      list<DAE.Var> vars;
      list<String> var_names;

    case (DAE.T_INTEGER()) then Values.INTEGER(0);
    case (DAE.T_REAL()) then Values.REAL(0.0);
    case (DAE.T_STRING()) then Values.STRING("");
    case (DAE.T_BOOL()) then Values.BOOL(false);
    case (DAE.T_ENUMERATION())
      then Values.ENUM_LITERAL(Absyn.IDENT(""), 0);

    case (DAE.T_ARRAY(dims = {dim}, ty = ty))
      equation
        int_dim = Expression.dimensionSize(dim);
        value = generateDefaultBinding(ty);
        values = List.fill(value, int_dim);
        dims = ValuesUtil.valueDimensions(value);
      then
        Values.ARRAY(values, int_dim :: dims);

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = path), varLst = vars))
      equation
        (values, var_names) = List.map_2(vars, getRecordVarBindingAndName);
      then
        Values.RECORD(path, values, var_names, -1);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- CevalFunction.generateDefaultBinding failed\n");
      then
        fail();
  end matchcontinue;
end generateDefaultBinding;

protected function getRecordVarBindingAndName
  input DAE.Var inVar;
  output Values.Value outBinding;
  output String outName;
algorithm
  (outBinding, outName) := matchcontinue(inVar)
    local
      String name;
      DAE.Type ty;
      DAE.Binding binding;
      Values.Value val;

    case (DAE.TYPES_VAR(name = name, ty = ty, binding = binding))
      equation
        val = getBindingOrDefault(binding, ty);
      then
        (val, name);

    case (DAE.TYPES_VAR(name = name))
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CevalFunction.getRecordVarBindingAndName failed on variable "
          + name + "\n");
      then
        fail();
  end matchcontinue;
end getRecordVarBindingAndName;

protected function getFunctionReturnValue
  "This function fetches one return value for the function, given an output
  variable and an environment."
  input DAE.Element inOutputVar;
  input FCore.Graph inEnv;
  output Values.Value outValue;
algorithm
  outValue := match(inOutputVar, inEnv)
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
      Values.Value val;
    case (DAE.VAR(componentRef = cr, ty = ty), _)
      equation
        val = getVariableValue(cr, ty, inEnv);
      then
        val;
  end match;
end getFunctionReturnValue;

protected function getVariableValue
  "Helper function to getFunctionReturnValue. Fetches a variables value from the
  environment."
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  input FCore.Graph inEnv;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue(inCref, inType, inEnv)
    local
      Values.Value val;
      Absyn.Path p;

    // A record doesn't have a value, but an environment with it's components.
    // So we need to assemble the records value.
    case (_, DAE.T_COMPLEX(complexClassType = ClassInf.RECORD()), _)
      equation
        p = ComponentReference.crefToPath(inCref);
        val = getRecordValue(p, inType, inEnv);
      then
        val;

    // All other variables we can just look up in the environment.
    else
      equation
        (_, val) = getVariableTypeAndValue(inCref, inEnv);
      then
        val;
  end matchcontinue;
end getVariableValue;

protected function getRecordValue
  "Looks up the value of a record by looking up the record components in the
  records environment and assembling a record value."
  input Absyn.Path inRecordName;
  input DAE.Type inType;
  input FCore.Graph inEnv;
  output Values.Value outValue;
algorithm
  outValue := match(inRecordName, inType, inEnv)
    local
      list<DAE.Var> vars;
      list<Values.Value> vals;
      list<String> var_names;
      String id;
      Absyn.Path p;
      FCore.Graph env;
    case (Absyn.IDENT(name = id),
          DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = p),
                        varLst = vars), _)
      equation
        (_, _, _, _, _, env) =
          Lookup.lookupIdentLocal(FCore.emptyCache(), inEnv, id);
        vals = List.map1(vars, getRecordComponentValue, env);
        var_names = List.map(vars, Types.getVarName);
      then
        Values.RECORD(p, vals, var_names, -1);
  end match;
end getRecordValue;

protected function getRecordComponentValue
  "Looks up the value for a record component."
  input DAE.Var inVars;
  input FCore.Graph inEnv;
  output Values.Value outValues;
algorithm
  outValues := match(inVars, inEnv)
    local
      Values.Value val;
      String id;
      DAE.Type ty;
      DAE.Binding binding;

    // The component is a record itself.
    case (DAE.TYPES_VAR(
        name = id,
        ty = ty as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD())), _)
      equation
        val = getRecordValue(Absyn.IDENT(id), ty, inEnv);
      then
        val;

    // A non-record variable.
    case (DAE.TYPES_VAR(name = id, ty = ty), _)
      equation
        (_, DAE.TYPES_VAR(binding = binding), _, _, _, _) =
          Lookup.lookupIdentLocal(FCore.emptyCache(), inEnv, id);
        val = getBindingOrDefault(binding, ty);
      then
        val;
  end match;
end getRecordComponentValue;

protected function boxReturnValue
  "This function takes a list of return values, and return either a NORETCALL, a
  single value or a tuple with the values depending on how many return variables
  there are."
  input list<Values.Value> inReturnValues;
  output Values.Value outValue;
algorithm
  outValue := match(inReturnValues)
    local
      Values.Value val;

    case ({}) then Values.NORETCALL();
    case ({val}) then val;
    case (_ :: _) then Values.TUPLE(inReturnValues);
  end match;
end boxReturnValue;

// [DEPS]  Function variable dependency handling.

protected function sortFunctionVarsByDependency
  "A functions variables might depend on each other, for example by defining
  dimensions that depend on the size of another variable. This function sorts
  the list of variables so that any dependencies to a variable will be before
  the variable in resulting list."
  input list<FunctionVar> inFuncVars;
  input DAE.ElementSource inSource;
  output list<FunctionVar> outFuncVars;
protected
  list<tuple<FunctionVar, list<FunctionVar>>> cycles;
algorithm
  (outFuncVars, cycles) := Graph.topologicalSort(
    Graph.buildGraph(inFuncVars, getElementDependencies, inFuncVars),
    isElementEqual);
  checkCyclicalComponents(cycles, inSource);
end sortFunctionVarsByDependency;

protected function getElementDependencies
  "Returns the dependencies given an element."
  input FunctionVar inElement;
  input list<FunctionVar> inAllElements;
  output list<FunctionVar> outDependencies;
  type Arg = tuple<list<FunctionVar>, list<FunctionVar>, list<DAE.Ident>>;
algorithm
  outDependencies := matchcontinue(inElement, inAllElements)
    local
      DAE.Exp bind_exp;
      list<FunctionVar> deps;
      list<DAE.Dimension> dims;
      Arg arg;

    case ((DAE.VAR(binding = SOME(bind_exp), dims = dims), _), _)
      equation
        (_, arg as (_, deps, _)) = Expression.traverseExpBidir(
          bind_exp,
          getElementDependenciesTraverserEnter,
          getElementDependenciesTraverserExit,
          (inAllElements, {}, {}));
        (_, (_, deps, _)) = List.mapFold(dims,
          getElementDependenciesFromDims, arg);
      then
        deps;

    case ((DAE.VAR(dims = dims), _), _)
      equation
        (_, (_, deps, _)) = List.mapFold(dims,
          getElementDependenciesFromDims, (inAllElements, {}, {}));
      then
        deps;

    else {};
  end matchcontinue;
end getElementDependencies;

protected function getElementDependenciesFromDims
  "Helper function to getElementDependencies that gets the dependencies from the
  dimensions of a variable."
  input DAE.Dimension inDimension;
  input Arg inArg;
  output DAE.Dimension outDimension;
  output Arg outArg;
  type Arg = tuple<list<FunctionVar>, list<FunctionVar>, list<DAE.Ident>>;
algorithm
  (outDimension, outArg) := matchcontinue(inDimension, inArg)
    local
      Arg arg;
      DAE.Exp dim_exp;

    case (_, _)
      equation
        dim_exp = Expression.dimensionSizeExp(inDimension);
        (_, arg) = Expression.traverseExpBidir(
          dim_exp,
          getElementDependenciesTraverserEnter,
          getElementDependenciesTraverserExit,
          inArg);
       then
        (inDimension, arg);

    else (inDimension, inArg);
  end matchcontinue;
end getElementDependenciesFromDims;

protected function getElementDependenciesTraverserEnter
  "Traverse function used by getElementDependencies to collect all dependencies
  for an element. The extra arguments are a list of all elements, a list of
  accumulated depencies and a list of iterators from enclosing for-loops."
  input DAE.Exp inExp;
  input Arg inArg;
  output DAE.Exp outExp;
  output Arg outArg;
  type Arg = tuple<list<FunctionVar>, list<FunctionVar>, list<DAE.Ident>>;
algorithm
  (outExp, outArg) := matchcontinue(inExp, inArg)
    local
      DAE.Exp exp;
      DAE.ComponentRef cref;
      list<FunctionVar> all_el, accum_el;
      FunctionVar e;
      DAE.Ident iter;
      list<DAE.Ident> iters;
      DAE.ReductionIterators riters;

    // Check if the crefs matches any of the iterators that might shadow a
    // function variable, and don't add it as a dependency if that's the case.
    case (exp as DAE.CREF(componentRef = DAE.CREF_IDENT(ident = iter)),
        (all_el, accum_el, iters as _ :: _))
      equation
        true = List.isMemberOnTrue(iter, iters, stringEqual);
      then
        (exp, (all_el, accum_el, iters));

    // Otherwise, try to delete the cref from the list of all elements. If that
    // succeeds, add it to the list of dependencies. Since we have deleted the
    // element from the list of all variables this ensures that the dependency
    // list only contains unique elements.
    case (exp as DAE.CREF(componentRef = cref), (all_el, accum_el, iters))
      equation
        (all_el, SOME(e)) = List.deleteMemberOnTrue(cref, all_el,
          isElementNamed);
      then
        (exp, (all_el, e :: accum_el, iters));

    // If we encounter a reduction, add the iterator to the iterator list so
    // that we know which iterators shadow function variables.
    case (exp as DAE.REDUCTION(iterators = riters), (all_el, accum_el, iters))
      equation
        iters = listAppend(List.map(riters, Expression.reductionIterName), iters);
      then
        (exp, (all_el, accum_el, iters));

    else (inExp, inArg);
  end matchcontinue;
end getElementDependenciesTraverserEnter;

protected function getElementDependenciesTraverserExit
  "Exit traversal function used by getElementDependencies."
  input DAE.Exp inExp;
  input Arg inArg;
  output DAE.Exp outExp;
  output Arg outArg;
  type Arg = tuple<list<FunctionVar>, list<FunctionVar>, list<DAE.Ident>>;
algorithm
  (outExp, outArg) := match(inExp, inArg)
    local
      DAE.Exp exp;
      list<FunctionVar> all_el, accum_el;
      list<DAE.Ident> iters;
      DAE.ReductionIterators riters;

    // If we encounter a reduction, make sure that its iterator matches the
    // first iterator in the iterator list, and if so remove it from the list.
    case (exp as DAE.REDUCTION(iterators = riters), (all_el, accum_el, iters))
      equation
        iters = compareIterators(listReverse(riters), iters);
      then
        (exp, (all_el, accum_el, iters));

    else (inExp, inArg);
  end match;
end getElementDependenciesTraverserExit;

protected function compareIterators
  input DAE.ReductionIterators inRiters;
  input list<String> inIters;
  output list<String> outIters;
algorithm
  outIters := matchcontinue(inRiters,inIters)
    local
      String id1,id2;
      DAE.ReductionIterators riters;
      list<String> iters;

    case (DAE.REDUCTIONITER(id = id1) :: riters, id2 :: iters)
      equation
        true = stringEqual(id1, id2);
      then
        compareIterators(riters, iters);

    case ({}, _) then inIters;

    // This should never happen, print an error if it does.
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Different iterators in CevalFunction.compareIterators."});
      then
        fail();

  end matchcontinue;
end compareIterators;

protected function isElementNamed
  "Checks if a function parameter has the given name."
  input DAE.ComponentRef inName;
  input FunctionVar inElement;
  output Boolean isNamed;
protected
  DAE.ComponentRef name;
algorithm
  (DAE.VAR(componentRef = name), _) := inElement;
  isNamed := ComponentReference.crefEqualWithoutSubs(name, inName);
end isElementNamed;

protected function isElementEqual
  "Checks if two function parameters are equal, i.e. have the same name."
  input FunctionVar inElement1;
  input FunctionVar inElement2;
  output Boolean isEqual;
protected
  DAE.ComponentRef cr1, cr2;
algorithm
  (DAE.VAR(componentRef = cr1), _) := inElement1;
  (DAE.VAR(componentRef = cr2), _) := inElement2;
  isEqual := ComponentReference.crefEqualWithoutSubs(cr1, cr2);
end isElementEqual;

protected function checkCyclicalComponents
  "Checks the return value from Graph.topologicalSort. If the list of cycles is
  not empty, print an error message and fail, since it's not allowed for
  constants or parameters to have cyclic dependencies."
  input list<tuple<FunctionVar, list<FunctionVar>>> inCycles;
  input DAE.ElementSource inSource;
algorithm
  _ := match(inCycles, inSource)
    local
      list<list<FunctionVar>> cycles;
      list<list<DAE.Element>> elements;
      list<list<DAE.ComponentRef>> crefs;
      list<list<String>> names;
      list<String> cycles_strs;
      String cycles_str, scope_str;
      SourceInfo info;

    case ({}, _) then ();

    else
      equation
        cycles = Graph.findCycles(inCycles, isElementEqual);
        elements = List.mapList(cycles, Util.tuple21);
        crefs = List.mapList(elements, DAEUtil.varCref);
        names = List.mapList(crefs,
          ComponentReference.printComponentRefStr);
        cycles_strs = List.map1(names, stringDelimitList, ",");
        cycles_str = stringDelimitList(cycles_strs, "}, {");
        cycles_str = "{" + cycles_str + "}";
        scope_str = "";
        info = DAEUtil.getElementSourceFileInfo(inSource);
        Error.addSourceMessage(Error.CIRCULAR_COMPONENTS, {scope_str, cycles_str}, info);
      then
        fail();

  end match;
end checkCyclicalComponents;

// [EOPT]  Expression optimization functions.

protected function optimizeExpTraverser
  "This function optimizes expressions in a function. So far this is only used
  to transform ASUB expressions to CREFs so that this doesn't need to be done
  while evaluating the function. But it's possible that more forms of
  optimization can be done too."
  input DAE.Exp inExp;
  input FCore.Graph inEnv;
  output DAE.Exp outExp;
  output FCore.Graph outEnv;
algorithm
  (outExp,outEnv) := match (inExp,inEnv)
    local
      DAE.ComponentRef cref;
      DAE.Type ety;
      list<DAE.Exp> sub_exps;
      list<DAE.Subscript> subs;
      FCore.Graph env;
      DAE.Exp exp;

    case (DAE.ASUB(exp = DAE.CREF(componentRef = cref, ty = ety), sub = sub_exps), env)
      equation
        subs = List.map(sub_exps, Expression.makeIndexSubscript);
        cref = ComponentReference.subscriptCref(cref, subs);
        exp = Expression.makeCrefExp(cref, ety);
      then (exp, env);

    case (DAE.TSUB(exp = DAE.TUPLE(exp::_), ix = 1), env)
      then (exp, env);

    else (inExp,inEnv);
  end match;
end optimizeExpTraverser;

annotation(__OpenModelica_Interface="frontend");
end CevalFunction;
