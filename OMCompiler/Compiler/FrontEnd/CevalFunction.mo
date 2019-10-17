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
public import AbsynUtil;
public import DAE;
public import FCore;
public import SCode;
public import Values;

// protected imports
protected import Ceval;
protected import ClassInf;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import ElementSource;
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
  output FCore.Cache outCache;
  output Values.Value outResult;
algorithm
  (outCache, outResult) :=
  matchcontinue(inCache, inEnv, inFunction, inFunctionArguments)
    local
      Absyn.Path p;
      DAE.FunctionDefinition func;
      DAE.Type ty;
      Values.Value result;
      String func_name;
      FCore.Cache cache;
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
        source = src), _)
      equation
        func_name = AbsynUtil.pathString(p);
        (cache, result) = evaluateFunctionDefinition(inCache, inEnv, func_name,
          func, ty, inFunctionArguments, src);
      then
        (cache, result);

    case (_, _, DAE.FUNCTION(
        path = p,
        functions = _ :: _,
        partialPrefix = partialPrefix), _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CevalFunction.evaluate failed for function: " + (if partialPrefix then "partial " else "") + AbsynUtil.pathString(p));
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
  output FCore.Cache outCache;
  output Values.Value outResult;
algorithm
  (outCache, outResult) :=
  matchcontinue(inCache, inEnv, inFuncName, inFunc, inFuncType, inFuncArgs, inSource)
    local
      list<DAE.Element> body;
      list<DAE.Element> vars, output_vars;
      list<FunctionVar> func_params;
      FCore.Cache cache;
      FCore.Graph env;
      list<Values.Value> return_values;
      Values.Value return_value;
      String ext_fun_name;
      list<DAE.ExtArg> ext_fun_args;
      DAE.ExtArg ext_fun_ret;

    case (_, _, _, DAE.FUNCTION_DEF(body = body), _, _, _)
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
        (cache, env) =
          setupFunctionEnvironment(inCache, inEnv, inFuncName, func_params);
        // Evaluate the body of the function.
        (cache, env, _) = evaluateElements(body, cache, env, NEXT());
        // Fetch the values of the output variables.
        return_values = List.map1(output_vars, getFunctionReturnValue, env);
        // If we have several output variables they should be boxed into a tuple.
        return_value = boxReturnValue(return_values);
      then
        (cache, return_value);

    case (_, _, _, DAE.FUNCTION_EXT(body = body, externalDecl =
        DAE.EXTERNALDECL(name = ext_fun_name,
                         args = ext_fun_args)), _, _, _)
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
        (cache, env) =
          setupFunctionEnvironment(inCache, inEnv, inFuncName, func_params);

        // Call the function.
        (cache, env) =
          evaluateExternalFunc(ext_fun_name, ext_fun_args, cache, env);

        // Fetch the values of the output variables.
        return_values = List.map1(output_vars, getFunctionReturnValue, env);
        // If we have several output variables they should be boxed into a tuple.
        return_value = boxReturnValue(return_values);
      then
        (cache, return_value);

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
  output Values.Value outValue;
  output FCore.Cache outCache;
algorithm
  (outValue, outCache) := matchcontinue(inArgument, inCache, inEnv)
    local
      DAE.ComponentRef cref;
      DAE.Type ty;
      DAE.Exp exp;
      Values.Value val;
      FCore.Cache cache;
      String err_str;

    case (DAE.EXTARG(componentRef = cref, type_ = ty), _, _)
      equation
        val = getVariableValue(cref, ty, inEnv);
      then
        (val, inCache);

    case (DAE.EXTARGEXP(exp = exp), cache, _)
      equation
        (cache, val) = cevalExp(exp, cache, inEnv);
      then
        (val, cache);

    case (DAE.EXTARGSIZE(componentRef = cref, exp = exp), cache, _)
      equation
        exp = DAE.SIZE(DAE.CREF(cref, DAE.T_UNKNOWN_DEFAULT), SOME(exp));
        (cache, val) = cevalExp(exp, cache, inEnv);
      then
        (val, cache);

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
  output Integer outValue;
  output FCore.Cache outCache;
algorithm
  (Values.INTEGER(outValue), outCache) :=
    evaluateExtInputArg(inArg, inCache, inEnv);
end evaluateExtIntArg;

protected function evaluateExtRealArg
  "Evaluates an external function argument to a Real."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output Real outValue;
  output FCore.Cache outCache;
algorithm
  (Values.REAL(outValue), outCache) :=
    evaluateExtInputArg(inArg, inCache, inEnv);
end evaluateExtRealArg;

protected function evaluateExtStringArg
  "Evaluates an external function argument to a String."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output String outValue;
  output FCore.Cache outCache;
algorithm
  (Values.STRING(outValue), outCache) :=
    evaluateExtInputArg(inArg, inCache, inEnv);
end evaluateExtStringArg;

protected function evaluateExtIntArrayArg
  "Evaluates an external function argument to an Integer array."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output list<Integer> outValue;
  output FCore.Cache outCache;
protected
  Values.Value val;
algorithm
  (val, outCache) :=
    evaluateExtInputArg(inArg, inCache, inEnv);
  outValue := ValuesUtil.arrayValueInts(val);
end evaluateExtIntArrayArg;

protected function evaluateExtRealArrayArg
  "Evaluates an external function argument to a Real array."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output list<Real> outValue;
  output FCore.Cache outCache;
protected
  Values.Value val;
algorithm
  (val, outCache) :=
    evaluateExtInputArg(inArg, inCache, inEnv);
  outValue := ValuesUtil.arrayValueReals(val);
end evaluateExtRealArrayArg;

protected function evaluateExtRealMatrixArg
  "Evaluates an external function argument to a Real matrix."
  input DAE.ExtArg inArg;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output list<list<Real>> outValue;
  output FCore.Cache outCache;
protected
  Values.Value val;
algorithm
  (val, outCache) :=
    evaluateExtInputArg(inArg, inCache, inEnv);
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
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) := match(inArgs, inValues, inCache, inEnv)
    local
      DAE.ExtArg arg;
      Values.Value val;
      list<DAE.ExtArg> rest_args;
      list<Values.Value> rest_vals;
      FCore.Cache cache;
      FCore.Graph env;
      DAE.ComponentRef cr;

    case ({}, {}, _, _) then (inCache, inEnv);

    case (arg :: rest_args, val :: rest_vals, cache, env)
      equation
        cr = evaluateExtOutputArg(arg);
        val = unliftExtOutputValue(cr, val, env);
        (cache, env) = assignVariable(cr, val, cache, env);
        (cache, env) = assignExtOutputs(rest_args, rest_vals, cache, env);
      then
        (cache, env);

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
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) :=
  match(inFuncName, inFuncArgs, inCache, inEnv)
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

    case("dgeev", {arg_JOBVL, arg_JOBVR, arg_N, arg_A, arg_LDA, arg_WR, arg_WI,
                   arg_VL, arg_LDVL, arg_VR, arg_LDVR, arg_WORK, arg_LWORK, arg_INFO},
        cache, env)
      equation
        (JOBVL, cache) = evaluateExtStringArg(arg_JOBVL, cache, env);
        (JOBVR, cache) = evaluateExtStringArg(arg_JOBVR, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (LDVL, cache) = evaluateExtIntArg(arg_LDVL, cache, env);
        (LDVR, cache) = evaluateExtIntArg(arg_LDVR, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
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
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgegv", {arg_JOBVL, arg_JOBVR, arg_N, arg_A, arg_LDA, arg_B, arg_LDB,
                   arg_ALPHAR, arg_ALPHAI, arg_BETA, arg_VL, arg_LDVL, arg_VR, arg_LDVR,
                   arg_WORK, arg_LWORK, arg_INFO},
        cache, env)
      equation
        (JOBVL, cache) = evaluateExtStringArg(arg_JOBVL, cache, env);
        (JOBVR, cache) = evaluateExtStringArg(arg_JOBVR, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (LDVL, cache) = evaluateExtIntArg(arg_LDVL, cache, env);
        (LDVR, cache) = evaluateExtIntArg(arg_LDVR, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
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
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgels", {arg_TRANS, arg_M, arg_N, arg_NRHS, arg_A, arg_LDA, arg_B,
                   arg_LDB, arg_WORK, arg_LWORK, arg_INFO},
        cache, env)
      equation
        (TRANS, cache) = evaluateExtStringArg(arg_TRANS, cache, env);
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
        (A, B, WORK, INFO) =
          Lapack.dgels(TRANS, M, N, NRHS, A, LDA, B, LDB, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_WORK, arg_INFO};
        val_out = {val_A, val_B, val_WORK, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgelsx", {arg_M, arg_N, arg_NRHS, arg_A, arg_LDA, arg_B, arg_LDB,
                    arg_JPVT, arg_RCOND, arg_RANK, arg_WORK, arg_INFO},
        cache, env)
      equation
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (JPVT, cache) = evaluateExtIntArrayArg(arg_JPVT, cache, env);
        (RCOND, cache) = evaluateExtRealArg(arg_RCOND, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (A, B, JPVT, RANK, INFO) =
          Lapack.dgelsx(M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, WORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_JPVT = ValuesUtil.makeIntArray(JPVT);
        val_RANK = ValuesUtil.makeInteger(RANK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_JPVT, arg_RANK, arg_INFO};
        val_out = {val_A, val_B, val_JPVT, val_RANK, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgelsx", {arg_M, arg_N, arg_NRHS, arg_A, arg_LDA, arg_B, arg_LDB,
                    arg_JPVT, arg_RCOND, arg_RANK, arg_WORK, _, arg_INFO},
        cache, env)
      equation
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (JPVT, cache) = evaluateExtIntArrayArg(arg_JPVT, cache, env);
        (RCOND, cache) = evaluateExtRealArg(arg_RCOND, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (A, B, JPVT, RANK, INFO) =
          Lapack.dgelsx(M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, WORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_JPVT = ValuesUtil.makeIntArray(JPVT);
        val_RANK = ValuesUtil.makeInteger(RANK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_JPVT, arg_RANK, arg_INFO};
        val_out = {val_A, val_B, val_JPVT, val_RANK, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgelsy", {arg_M, arg_N, arg_NRHS, arg_A, arg_LDA, arg_B, arg_LDB,
                    arg_JPVT, arg_RCOND, arg_RANK, arg_WORK, arg_LWORK, arg_INFO},
        cache, env)
      equation
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (JPVT, cache) = evaluateExtIntArrayArg(arg_JPVT, cache, env);
        (RCOND, cache) = evaluateExtRealArg(arg_RCOND, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
        (A, B, JPVT, RANK, WORK, INFO) =
          Lapack.dgelsy(M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_JPVT = ValuesUtil.makeIntArray(JPVT);
        val_RANK = ValuesUtil.makeInteger(RANK);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_B, arg_JPVT, arg_RANK, arg_WORK, arg_INFO};
        val_out = {val_A, val_B, val_JPVT, val_RANK, val_WORK, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgesv", {arg_N, arg_NRHS, arg_A, arg_LDA, arg_IPIV, arg_B, arg_LDB,
                   arg_INFO},
        cache, env)
      equation
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (A, IPIV, B, INFO) =
          Lapack.dgesv(N, NRHS, A, LDA, B, LDB);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_IPIV = ValuesUtil.makeIntArray(IPIV);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_IPIV, arg_B, arg_INFO};
        val_out = {val_A, val_IPIV, val_B, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgglse", {arg_M, arg_N, arg_P, arg_A, arg_LDA, arg_B, arg_LDB,
                    arg_C, arg_D, arg_X, arg_WORK, arg_LWORK, arg_INFO},
        cache, env)
      equation
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (P, cache) = evaluateExtIntArg(arg_P, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (C, cache) = evaluateExtRealArrayArg(arg_C, cache, env);
        (D, cache) = evaluateExtRealArrayArg(arg_D, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
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
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgtsv", {arg_N, arg_NRHS, arg_DL, arg_D, arg_DU, arg_B, arg_LDB,
                   arg_INFO},
        cache, env)
      equation
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (DL, cache) = evaluateExtRealArrayArg(arg_DL, cache, env);
        (D, cache) = evaluateExtRealArrayArg(arg_D, cache, env);
        (DU, cache) = evaluateExtRealArrayArg(arg_DU, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (DL, D, DU, B, INFO) =
          Lapack.dgtsv(N, NRHS, DL, D, DU, B, LDB);
        val_DL = ValuesUtil.makeRealArray(DL);
        val_D = ValuesUtil.makeRealArray(D);
        val_DU = ValuesUtil.makeRealArray(DU);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_DL, arg_D, arg_DU, arg_B, arg_INFO};
        val_out = {val_DL, val_D, val_DU, val_B, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgbsv", {arg_N, arg_KL, arg_KU, arg_NRHS, arg_AB, arg_LDAB, arg_IPIV,
                   arg_B, arg_LDB, arg_INFO},
        cache, env)
      equation
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (KL, cache) = evaluateExtIntArg(arg_KL, cache, env);
        (KU, cache) = evaluateExtIntArg(arg_KU, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (AB, cache) = evaluateExtRealMatrixArg(arg_AB, cache, env);
        (LDAB, cache) = evaluateExtIntArg(arg_LDAB, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (AB, IPIV, B, INFO) =
          Lapack.dgbsv(N, KL, KU, NRHS, AB, LDAB, B, LDB);
        val_AB = ValuesUtil.makeRealMatrix(AB);
        val_IPIV = ValuesUtil.makeIntArray(IPIV);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_AB, arg_IPIV, arg_B, arg_INFO};
        val_out = {val_AB, val_IPIV, val_B, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgesvd", {arg_JOBU, arg_JOBVT, arg_M, arg_N, arg_A, arg_LDA, arg_S,
                    arg_U, arg_LDU, arg_VT, arg_LDVT, arg_WORK, arg_LWORK, arg_INFO},
        cache, env)
      equation
        (JOBU, cache) = evaluateExtStringArg(arg_JOBU, cache, env);
        (JOBVT, cache) = evaluateExtStringArg(arg_JOBVT, cache, env);
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (LDU, cache) = evaluateExtIntArg(arg_LDU, cache, env);
        (LDVT, cache) = evaluateExtIntArg(arg_LDVT, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
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
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgetrf", {arg_M, arg_N, arg_A, arg_LDA, arg_IPIV, arg_INFO},
        cache, env)
      equation
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (A, IPIV, INFO) =
          Lapack.dgetrf(M, N, A, LDA);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_IPIV = ValuesUtil.makeIntArray(IPIV);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_IPIV, arg_INFO};
        val_out = {val_A, val_IPIV, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgetrs", {arg_TRANS, arg_N, arg_NRHS, arg_A, arg_LDA, arg_IPIV, arg_B,
                    arg_LDB, arg_INFO},
        cache, env)
      equation
        (TRANS, cache) = evaluateExtStringArg(arg_TRANS, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (NRHS, cache) = evaluateExtIntArg(arg_NRHS, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (IPIV, cache) = evaluateExtIntArrayArg(arg_IPIV, cache, env);
        (B, cache) = evaluateExtRealMatrixArg(arg_B, cache, env);
        (LDB, cache) = evaluateExtIntArg(arg_LDB, cache, env);
        (B, INFO) =
          Lapack.dgetrs(TRANS, N, NRHS, A, LDA, IPIV, B, LDB);
        val_B = ValuesUtil.makeRealMatrix(B);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_B, arg_INFO};
        val_out = {val_B, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgetri", {arg_N, arg_A, arg_LDA, arg_IPIV, arg_WORK, arg_LWORK, arg_INFO},
        cache, env)
      equation
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (IPIV, cache) = evaluateExtIntArrayArg(arg_IPIV, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
        (A, WORK, INFO) =
          Lapack.dgetri(N, A, LDA, IPIV, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_WORK, arg_INFO};
        val_out = {val_A, val_WORK, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dgeqpf", {arg_M, arg_N, arg_A, arg_LDA, arg_JPVT, arg_TAU, arg_WORK,
                    arg_INFO},
        cache, env)
      equation
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (JPVT, cache) = evaluateExtIntArrayArg(arg_JPVT, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (A, JPVT, TAU, INFO) =
          Lapack.dgeqpf(M, N, A, LDA, JPVT, WORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_JPVT = ValuesUtil.makeIntArray(JPVT);
        val_TAU = ValuesUtil.makeRealArray(TAU);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_JPVT, arg_TAU, arg_INFO};
        val_out = {val_A, val_JPVT, val_TAU, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);

    case("dorgqr", {arg_M, arg_N, arg_K, arg_A, arg_LDA, arg_TAU, arg_WORK,
                    arg_LWORK, arg_INFO},
        cache, env)
      equation
        (M, cache) = evaluateExtIntArg(arg_M, cache, env);
        (N, cache) = evaluateExtIntArg(arg_N, cache, env);
        (K, cache) = evaluateExtIntArg(arg_K, cache, env);
        (A, cache) = evaluateExtRealMatrixArg(arg_A, cache, env);
        (LDA, cache) = evaluateExtIntArg(arg_LDA, cache, env);
        (TAU, cache) = evaluateExtRealArrayArg(arg_TAU, cache, env);
        (WORK, cache) = evaluateExtRealArrayArg(arg_WORK, cache, env);
        (LWORK, cache) = evaluateExtIntArg(arg_LWORK, cache, env);
        (A, WORK, INFO) =
          Lapack.dorgqr(M, N, K, A, LDA, TAU, WORK, LWORK);
        val_A = ValuesUtil.makeRealMatrix(A);
        val_WORK = ValuesUtil.makeRealArray(WORK);
        val_INFO = ValuesUtil.makeInteger(INFO);
        arg_out = {arg_A, arg_WORK, arg_INFO};
        val_out = {val_A, val_WORK, val_INFO};
        (cache, env) = assignExtOutputs(arg_out, val_out, cache, env);
      then
        (cache, env);
  end match;
end evaluateExternalFunc;

protected function evaluateElements
  "This function evaluates a list of elements."
  input list<DAE.Element> inElements;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input LoopControl inLoopControl;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
  match(inElements, inCache, inEnv, inLoopControl)
    local
      DAE.Element elem;
      list<DAE.Element> rest_elems;
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;

    case (_, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case ({}, _, _, _) then (inCache, inEnv, NEXT());
    case (elem :: rest_elems, _, _, _)
      equation
        (cache, env, loop_ctrl) = evaluateElement(elem, inCache, inEnv);
        (cache, env, loop_ctrl) =
          evaluateElements(rest_elems, cache, env, loop_ctrl);
      then
        (cache, env, loop_ctrl);
  end match;
end evaluateElements;

protected function evaluateElement
  "This function evaluates a single element, which should be an algorithm."
  input DAE.Element inElement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := match(inElement, inCache, inEnv)
    local
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
      list<DAE.Statement> sl;

    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = sl)), _, _)
      equation
        (sl, (_,env)) = DAEUtil.traverseDAEEquationsStmts(sl, Expression.traverseSubexpressionsHelper, (optimizeExpTraverser, inEnv));
        (cache, env, loop_ctrl) = evaluateStatements(sl, inCache, env);
      then
        (cache, env, loop_ctrl);
   end match;
end evaluateElement;

protected function evaluateStatement
  "This function evaluates a statement."
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
  match(inStatement, inCache, inEnv)
    local
      FCore.Cache cache;
      FCore.Graph env;
      DAE.Exp lhs, rhs, condition;
      DAE.ComponentRef lhs_cref;
      Values.Value rhs_val, v;
      list<DAE.Exp> exps;
      list<Values.Value> vals;
      list<DAE.Statement> statements;
      Absyn.Path path;
      DAE.Type returnType;
      LoopControl loop_ctrl;
      DAE.TailCall tailCall;
      String var;
      list<String> vars;

    case (DAE.STMT_ASSIGN(exp1 = lhs, exp = rhs), cache, env)
      equation
        (cache, rhs_val) = cevalExp(rhs, cache, env);
        lhs_cref = extractLhsComponentRef(lhs);
        (cache, env) = assignVariable(lhs_cref, rhs_val, cache, env);
      then
        (cache, env, NEXT());

    case (DAE.STMT_TUPLE_ASSIGN(), _, _)
      equation
        (cache, env) =
          evaluateTupleAssignStatement(inStatement, inCache, inEnv);
      then
        (cache, env, NEXT());

    case (DAE.STMT_ASSIGN_ARR(lhs = lhs, exp = rhs), _, env)
      equation
        (cache, rhs_val) = cevalExp(rhs, inCache, env);
        lhs_cref = extractLhsComponentRef(lhs);
        (cache, env) = assignVariable(lhs_cref, rhs_val, cache, env);
      then
        (cache, env, NEXT());

    case (DAE.STMT_IF(), _, _)
      equation
        (cache, env, loop_ctrl) =
          evaluateIfStatement(inStatement, inCache, inEnv);
      then
        (cache, env, loop_ctrl);

    case (DAE.STMT_FOR(), _, _)
      equation
        (cache, env, loop_ctrl) =
          evaluateForStatement(inStatement, inCache, inEnv);
      then
        (cache, env, loop_ctrl);

    case (DAE.STMT_WHILE(exp = condition, statementLst = statements), _, _)
      equation
        (cache, env, loop_ctrl) =
          evaluateWhileStatement(condition, statements, inCache, inEnv, NEXT());
      then
        (cache, env, loop_ctrl);

    // If the condition is true in the assert, do nothing. If the condition
    // is false we should stop the instantiation (depending on the assertion
    // level), but we can't really do much about that here. So right now we just
    // fail.
    case (DAE.STMT_ASSERT(cond = condition), _, _)
      equation
        (cache, Values.BOOL(boolean = true)) =
          cevalExp(condition, inCache, inEnv);
      then
        (cache, inEnv, NEXT());

    case (DAE.STMT_ASSERT(cond = condition), _, _)
      equation
        (cache, Values.BOOL(boolean = true)) =
          cevalExp(condition, inCache, inEnv);
      then
        (cache, inEnv, NEXT());
    // Special case for print, and other known calls for now; evaluated even when there is no ST
    case (DAE.STMT_NORETCALL(exp = rhs as DAE.CALL( expLst = exps, attr=DAE.CALL_ATTR(ty=_, tailCall=tailCall))), _, _)
      algorithm
        (cache, vals) := cevalExpList(exps, inCache, inEnv);
        (cache, v) := cevalExp(rhs, cache, inEnv);
        (cache, env, outLoopControl) := match tailCall
          case DAE.NO_TAIL() then (cache, inEnv, NEXT());
          // Handle tail recursion; same as a assigning all outputs followed by a return
          case DAE.TAIL(outVars={}) then (cache, inEnv, RETURN());
          case DAE.TAIL(outVars={var})
            algorithm
              (cache, env) := assignVariable(ComponentReference.makeUntypedCrefIdent(var), v, cache, inEnv);
            then (cache, env, RETURN());
          case DAE.TAIL(outVars=vars)
            algorithm
              Values.TUPLE(vals) := v;
              for val in vals loop
                var::vars := vars;
                (cache, env) := assignVariable(ComponentReference.makeUntypedCrefIdent(var), val, cache, inEnv);
              end for;
            then (cache, env, RETURN());
        end match;
      then
        (cache, env, NEXT());

    case (DAE.STMT_RETURN(), _, _)
      then
        (inCache, inEnv, RETURN());

    case (DAE.STMT_BREAK(), _, _)
      then
        (inCache, inEnv, BREAK());

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
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
    evaluateStatements2(inStatement, inCache, inEnv, NEXT());
end evaluateStatements;

protected function evaluateStatements2
  "This is a helper function to evaluateStatements that evaluates a list of
  statements."
  input list<DAE.Statement> inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input LoopControl inLoopControl;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
  match(inStatement, inCache, inEnv, inLoopControl)
    local
      DAE.Statement stmt;
      list<DAE.Statement> rest_stmts;
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
    case (_, _, _, BREAK()) then (inCache, inEnv, inLoopControl);
    case (_, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case ({}, _, _, _) then (inCache, inEnv, inLoopControl);
    case (stmt :: rest_stmts, _, _, NEXT())
      equation
        (cache, env, loop_ctrl) = evaluateStatement(stmt, inCache, inEnv);
        (cache, env, loop_ctrl) =
          evaluateStatements2(rest_stmts, cache, env, loop_ctrl);
      then
        (cache, env, loop_ctrl);
  end match;
end evaluateStatements2;

protected function evaluateTupleAssignStatement
  "This function evaluates tuple assignment statements, i.e. assignment
  statements where the right hand side expression is a tuple. Ex:
    (x, y, z) := fun(...)"
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) := match(inStatement, inCache, inEnv)
    local
      list<DAE.Exp> lhs_expl;
      DAE.Exp rhs;
      list<Values.Value> rhs_vals;
      list<DAE.ComponentRef> lhs_crefs;
      FCore.Cache cache;
      FCore.Graph env;

    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = lhs_expl, exp = rhs), _, env)
      equation
        (cache, Values.TUPLE(valueLst = rhs_vals)) =
          cevalExp(rhs, inCache, env);
        lhs_crefs = List.map(lhs_expl, extractLhsComponentRef);
        (cache, env) = assignTuple(lhs_crefs, rhs_vals, cache, env);
      then
      (cache, env);
  end match;
end evaluateTupleAssignStatement;

protected function evaluateIfStatement
  "This function evaluates an if statement."
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
  match(inStatement, inCache, inEnv)
    local
      DAE.Exp cond;
      list<DAE.Statement> stmts;
      DAE.Else else_branch;
      FCore.Cache cache;
      FCore.Graph env;
      Boolean bool_cond;
      LoopControl loop_ctrl;

    case (DAE.STMT_IF(exp = cond, statementLst = stmts, else_ = else_branch), _, _)
      equation
        (cache, Values.BOOL(boolean = bool_cond)) =
          cevalExp(cond, inCache, inEnv);
        (cache, env, loop_ctrl) = evaluateIfStatement2(bool_cond, stmts,
          else_branch, cache, inEnv);
      then
        (cache, env, loop_ctrl);
  end match;
end evaluateIfStatement;

protected function evaluateIfStatement2
  "Helper function to evaluateIfStatement."
  input Boolean inCondition;
  input list<DAE.Statement> inStatements;
  input DAE.Else inElse;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
  match(inCondition, inStatements, inElse, inCache, inEnv)
    local
      FCore.Cache cache;
      FCore.Graph env;
      list<DAE.Statement> statements;
      DAE.Exp condition;
      Boolean bool_condition;
      DAE.Else else_branch;
      LoopControl loop_ctrl;

    // If the condition is true, evaluate the statements in the if branch.
    case (true, statements, _, _, env)
      equation
        (cache, env, loop_ctrl) =
          evaluateStatements(statements, inCache, env);
      then
        (cache, env, loop_ctrl);
    // If the condition is false and we have an else, evaluate the statements in
    // the else branch.
    case (false, _, DAE.ELSE(statementLst = statements), _, env)
      equation
        (cache, env, loop_ctrl) =
          evaluateStatements(statements, inCache, env);
      then
        (cache, env, loop_ctrl);
    // If the condition is false and we have an else if, call this function
    // again recursively.
    case (false, _, DAE.ELSEIF(exp = condition, statementLst = statements,
        else_ = else_branch), _, env)
      equation
        (cache, Values.BOOL(boolean = bool_condition)) =
          cevalExp(condition, inCache, env);
        (cache, env, loop_ctrl) =
          evaluateIfStatement2(bool_condition, statements, else_branch, cache, env);
      then
        (cache, env, loop_ctrl);
     // If the condition is false and we have no else branch, just continue.
    case (false, _, DAE.NOELSE(), _, _) then (inCache, inEnv, NEXT());
  end match;
end evaluateIfStatement2;

protected function evaluateForStatement
  "This function evaluates for statements."
  input DAE.Statement inStatement;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
  matchcontinue(inStatement, inCache, inEnv)
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

    // The case where the range is an array.
    case (DAE.STMT_FOR(type_ = ety, iter = iter_name,
        range = range, statementLst = statements), _, env)
      equation
        (cache, Values.ARRAY(valueLst = range_vals)) =
          cevalExp(range, inCache, env);
        (env, ty, iter_cr) = extendEnvWithForScope(iter_name, ety, env);
        (cache, env, loop_ctrl) = evaluateForLoopArray(cache, env, iter_cr,
          ty, range_vals, statements, NEXT());
      then
      (cache, env, loop_ctrl);

    case (DAE.STMT_FOR(range = range), _, _)
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
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := match(inCache, inEnv, inIter,
      inIterType, inValues, inStatements, inLoopControl)
    local
      Values.Value value;
      list<Values.Value> rest_vals;
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;

    case (_, _, _, _, _, _, BREAK()) then (inCache, inEnv, NEXT());
    case (_, _, _, _, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case (_, _, _, _, {}, _, _) then (inCache, inEnv, inLoopControl);
    case (_, env, _, _, value :: rest_vals, _, NEXT())
      equation
        env = updateVariableBinding(inIter, env, inIterType, value);
        (cache, env, loop_ctrl) =
          evaluateStatements(inStatements, inCache, env);
        (cache, env, loop_ctrl) = evaluateForLoopArray(cache, env, inIter,
          inIterType, rest_vals, inStatements, loop_ctrl);
      then
        (cache, env, loop_ctrl);
  end match;
end evaluateForLoopArray;

protected function evaluateWhileStatement
  "This function evaluates a while statement."
  input DAE.Exp inCondition;
  input list<DAE.Statement> inStatements;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input LoopControl inLoopControl;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) :=
  match(inCondition, inStatements, inCache, inEnv, inLoopControl)
    local
      FCore.Cache cache;
      FCore.Graph env;
      LoopControl loop_ctrl;
      Boolean b;

    case (_, _, _, _, BREAK()) then (inCache, inEnv, NEXT());
    case (_, _, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case (_, _, _, _, _)
      equation
        (cache, Values.BOOL(boolean = b)) = cevalExp(inCondition, inCache, inEnv);
        if b then
          (cache, env, loop_ctrl) = evaluateStatements(inStatements, cache, inEnv);
          (cache, env, loop_ctrl) = evaluateWhileStatement(inCondition, inStatements, cache, env, loop_ctrl);
        else
          loop_ctrl = NEXT();
          env = inEnv;
        end if;
      then
        (cache, env, loop_ctrl);

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
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) := Ceval.ceval(inCache, inEnv, inExp, true, Absyn.MSG(AbsynUtil.dummyInfo), 0);
  false := valueEq(Values.META_FAIL(), outValue);
end cevalExp;

protected function cevalExpList
  "A wrapper for Ceval with most of the arguments filled in."
  input list<DAE.Exp> inExpLst;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output list<Values.Value> outValue;
algorithm
  (outCache, outValue) := Ceval.cevalList(inCache, inEnv, inExpLst, true, Absyn.MSG(AbsynUtil.dummyInfo), 0);
end cevalExpList;

// [EENV]  Environment extension functions (add variables).

protected function setupFunctionEnvironment
  "Opens up a new scope for the functions and adds all function variables to it."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFuncName;
  input list<FunctionVar> inFuncParams;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  outEnv := FGraph.openScope(inEnv, SCode.NOT_ENCAPSULATED(), inFuncName, SOME(FCore.FUNCTION_SCOPE()));
  (outCache, outEnv) :=
    extendEnvWithFunctionVars(inCache, outEnv, inFuncParams);
end setupFunctionEnvironment;

protected function extendEnvWithFunctionVars
  "Extends the environment with a list of variables. The list of values is the
  input arguments to the function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<FunctionVar> inFuncParams;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) := match(inCache, inEnv, inFuncParams)
    local
      FunctionVar param;
      list<FunctionVar> rest_params;
      FCore.Cache cache;
      FCore.Graph env;

    case (_, _, {}) then (inCache, inEnv);

    case (cache, env, param :: rest_params)
      equation
        (cache, env) = extendEnvWithFunctionVar(cache, env, param);
        (cache, env) = extendEnvWithFunctionVars(cache, env, rest_params);
      then
        (cache, env);

  end match;
end extendEnvWithFunctionVars;

protected function extendEnvWithFunctionVar
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input FunctionVar inFuncParam;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) := matchcontinue(inCache, inEnv, inFuncParam)
    local
      DAE.Element e;
      Option<Values.Value> val;
      FCore.Cache cache;
      FCore.Graph env;
      Option<DAE.Exp> binding_exp;

    // Input parameters are assigned their corresponding input argument given to
    // the function.
    case (_, env, (e, val as SOME(_)))
      equation
        (cache, env) = extendEnvWithElement(e, val, inCache, env);
      then
        (cache, env);

    // Non-input parameters might have a default binding, so we use that if it's
    // available.
    case (_, env, ((e as DAE.VAR(binding = binding_exp)), NONE()))
      equation
        (val, cache) = evaluateBinding(binding_exp, inCache, inEnv);
        (cache, env) = extendEnvWithElement(e, val, cache, env);
      then
        (cache, env);

    case (_, _, (e, _))
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
  output Option<Values.Value> outValue;
  output FCore.Cache outCache;
algorithm
  (outValue, outCache) := match(inBinding, inCache, inEnv)
    local
      DAE.Exp binding_exp;
      FCore.Cache cache;
      Values.Value val;

    case (SOME(binding_exp), _, _)
      equation
        (cache, val) = cevalExp(binding_exp, inCache, inEnv);
      then
        (SOME(val), cache);

    case (NONE(), _, _) then (NONE(), inCache);
  end match;
end evaluateBinding;

protected function extendEnvWithElement
  "This function extracts the necessary data from a variable element, and calls
  extendEnvWithVar to add a new variable to the environment."
  input DAE.Element inElement;
  input Option<Values.Value> inBindingValue;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) :=
  match(inElement, inBindingValue, inCache, inEnv)
    local
      DAE.ComponentRef cr;
      String name;
      DAE.Type ty;
      DAE.InstDims dims;
      FCore.Cache cache;
      FCore.Graph env;

    case (DAE.VAR(componentRef = cr, ty = ty, dims = dims), _, _, _)
      equation
        name = ComponentReference.crefStr(cr);
        (cache, env) =
          extendEnvWithVar(name, ty, inBindingValue, dims, inCache, inEnv);
      then
        (cache, env);
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
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) :=
  matchcontinue(inName, inType, inOptValue, inDims, inCache, inEnv)
    local
      DAE.Type ty;
      DAE.Var var;
      DAE.Binding binding;
      FCore.Cache cache;
      FCore.Graph env, record_env;

    // Records are special, since they have their own environment with their
    // components in them. A record variable is thus always unbound, and their
    // values are instead determined by their components values.
    case (_, _, _, _, _, _)
      equation
        true = Types.isRecord(inType);
        binding = makeBinding(inOptValue);
        (cache, ty) =
          appendDimensions(inType, inOptValue, inDims, inCache, inEnv);
        var = makeFunctionVariable(inName, ty, binding);
        (cache, record_env) =
          makeRecordEnvironment(inType, inOptValue, cache, inEnv);
        env = FGraph.mkComponentNode(
                inEnv,
                var,
                SCode.COMPONENT(
                  inName,
                  SCode.defaultPrefixes,
                  SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(),Absyn.NONFIELD()),
                  Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
                  SCode.noComment, NONE(), AbsynUtil.dummyInfo),
                DAE.NOMOD(),
                FCore.VAR_TYPED(),
                record_env);
      then
        (cache, env);

    // Normal variables.
    else
      equation
        binding = makeBinding(inOptValue);
        (cache, ty) =
          appendDimensions(inType, inOptValue, inDims, inCache, inEnv);
        var = makeFunctionVariable(inName, ty, binding);
        env = FGraph.mkComponentNode(
                inEnv,
                var,
                SCode.COMPONENT(
                  inName,
                  SCode.defaultPrefixes,
                  SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(),Absyn.NONFIELD()),
                  Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
                  SCode.noComment, NONE(), AbsynUtil.dummyInfo),
                DAE.NOMOD(),
                FCore.VAR_TYPED(),
                FGraph.empty());
      then
        (cache, env);

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
  outVar := DAE.TYPES_VAR(inName, DAE.dummyAttrVar, inType, inBinding, false, NONE());
end makeFunctionVariable;

protected function makeBinding
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
end makeBinding;

protected function makeRecordEnvironment
  "This function creates an environment for a record variable by creating a new
  environment and adding the records components to it. If an optional value is
  supplied it also gives the components a value binding."
  input DAE.Type inRecordType;
  input Option<Values.Value> inOptValue;
  input FCore.Cache inCache;
  input FCore.Graph inGraph;
  output FCore.Cache outCache;
  output FCore.Graph outRecordEnv;
algorithm
  (outCache, outRecordEnv) :=
  match(inRecordType, inOptValue, inCache, inGraph)
    local
      list<DAE.Var> var_lst;
      list<Option<Values.Value>> vals;
      FCore.Cache cache;
      FCore.Graph graph;
      FCore.Ref parent, child;
      FCore.Node node;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(),varLst = var_lst), _, _, _)
      equation
        parent = FGraph.lastScopeRef(inGraph);
        (graph, node) = FGraph.node(inGraph, FNode.feNodeName, {parent}, FCore.ND(NONE()));
        child = FNode.toRef(node);
        FNode.addChildRef(parent, FNode.feNodeName, child);
        graph = FGraph.pushScopeRef(graph, child);

        vals = getRecordValues(inOptValue, inRecordType);
        ((cache, graph)) = List.threadFold(var_lst, vals,
          extendEnvWithRecordVar, (inCache, graph));
      then
        (cache, graph);
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
  input tuple<FCore.Cache, FCore.Graph> inEnv;
  output tuple<FCore.Cache, FCore.Graph> outEnv;
algorithm
  outEnv := match(inVar, inOptValue, inEnv)
    local
      String name;
      DAE.Type ty;
      FCore.Cache cache;
      FCore.Graph env;

    case (DAE.TYPES_VAR(name = name, ty = ty), _, (cache, env))
      equation
        (cache, env) =
          extendEnvWithVar(name, ty, inOptValue, {}, cache, env);
        outEnv = (cache, env);
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
  output FCore.Cache outCache;
  output DAE.Type outType;
protected
  list<Integer> binding_dims;
algorithm
  binding_dims := ValuesUtil.valueDimensions(
    Util.getOptionOrDefault(inOptBinding, Values.INTEGER(0)));
  (outCache, outType) :=
    appendDimensions2(inType, inDims, binding_dims, inCache, inEnv);
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
  output FCore.Cache outCache;
  output DAE.Type outType;
algorithm
  (outCache, outType) :=
  matchcontinue(inType, inDims, inBindingDims, inCache, inEnv)
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

    case (ty, {}, _, _, _) then (inCache, ty);

    case (ty, DAE.DIM_UNKNOWN() :: rest_dims, dim_int :: bind_dims, _, _)
      equation
        dim = Expression.intDimension(dim_int);
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, DAE.T_ARRAY(ty, {dim}));

    // If the variable is not an input, set the dimension size to 0 (dynamic size).
    case (ty, DAE.DIM_UNKNOWN() :: rest_dims, bind_dims, _, _)
      equation
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(0)}));

    case (ty, DAE.DIM_INTEGER(dim_int) :: rest_dims, bind_dims, _, _)
      equation
        dim = DAE.DIM_INTEGER(dim_int);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, DAE.T_ARRAY(ty, {dim}));

    case (ty, DAE.DIM_BOOLEAN() :: rest_dims, bind_dims, _, _)
      equation
        dim = DAE.DIM_INTEGER(2);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, DAE.T_ARRAY(ty, {dim}));

    case (ty, DAE.DIM_ENUM(size = dim_int) :: rest_dims, bind_dims, _, _)
      equation
        dim = DAE.DIM_INTEGER(dim_int);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, DAE.T_ARRAY(ty, {dim}));

    case (ty, DAE.DIM_EXP(exp = dim_exp) :: rest_dims, bind_dims, _, _)
      equation
        (cache, dim_val) = cevalExp(dim_exp, inCache, inEnv);
        dim_int = ValuesUtil.valueInteger(dim_val);
        dim = DAE.DIM_INTEGER(dim_int);
        bind_dims = List.stripFirst(bind_dims);
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, DAE.T_ARRAY(ty, {dim}));

    case (_, _ :: _, _, _, _)
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
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) :=
  matchcontinue(inCref, inNewValue, inCache, inEnv)
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

    // Wildcard, no need to assign anything.
    case (DAE.WILD(), _, _, _) then (inCache, inEnv);

    // A record assignment.
    case (DAE.CREF_IDENT(ident = id, subscriptLst = {}, identType = ety as
        DAE.T_COMPLEX(complexClassType = ClassInf.RECORD())), _, _, _)
      equation
        (_, var, _, _, inst_status, env) =
          Lookup.lookupIdentLocal(inCache, inEnv, id);
        (cache, env) = assignRecord(ety, inNewValue, inCache, env);
        var = updateRecordBinding(var, inNewValue);
        env = FGraph.updateComp(inEnv, var, inst_status, env);
      then
        (cache, env);

    // If we get a scalar we just update the value.
    case (cr as DAE.CREF_IDENT(subscriptLst = {}), _, _, _)
      equation
        ty = Types.unflattenArrayType(Expression.typeof(ValuesUtil.valueExp(inNewValue))); // In case of zero-dimensions, update the dimensions; they are all known now
        env = updateVariableBinding(cr, inEnv, ty, inNewValue);
      then
        (inCache, env);

    // If we get a vector we first get the old value and update the relevant
    // part of it, and then update the variables value.
    case (DAE.CREF_IDENT(subscriptLst = subs), _, _, _)
      equation
        cr = ComponentReference.crefStripSubs(inCref);
        (ty, val) = getVariableTypeAndValue(cr, inEnv);
        (cache, val) = assignVector(inNewValue, val, subs, inCache, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        (cache, env);

    // A qualified component reference is a record component, so first lookup
    // the records environment, and then assign the variable in that environment.
    case (DAE.CREF_QUAL(ident = id, subscriptLst = {},
        componentRef = cr_rest), _, _, _)
      equation
        (_, var, _, _, inst_status, env) =
          Lookup.lookupIdentLocal(inCache, inEnv, id);
        (cache, env) = assignVariable(cr_rest, inNewValue, inCache, env);
        comp_id = ComponentReference.crefFirstIdent(cr_rest);
        var = updateRecordComponentBinding(var, comp_id, inNewValue);
        env = FGraph.updateComp(inEnv, var, inst_status, env);
      then
        (cache, env);
  end matchcontinue;
end assignVariable;

protected function assignTuple
  "This function assign a tuple by calling assignVariable for each tuple
  component."
  input list<DAE.ComponentRef> inLhsCrefs;
  input list<Values.Value> inRhsValues;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) :=
  match(inLhsCrefs, inRhsValues, inCache, inEnv)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest_crefs;
      Values.Value value;
      list<Values.Value> rest_vals;
      FCore.Cache cache;
      FCore.Graph env;
    case ({}, _, cache, env) then (cache, env);
    case (cr :: rest_crefs, value :: rest_vals, cache, env)
      equation
        (cache, env) = assignVariable(cr, value, cache, env);
        (cache, env) = assignTuple(rest_crefs, rest_vals, cache, env);
      then
        (cache, env);
  end match;
end assignTuple;

protected function assignRecord
  input DAE.Type inType;
  input Values.Value inValue;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) := match(inType, inValue, inCache, inEnv)
    local
      list<Values.Value> values;
      list<DAE.Var> vars;
      FCore.Cache cache;
      FCore.Graph env;
    case (DAE.T_COMPLEX(varLst = vars), Values.RECORD(orderd = values), _, _)
      equation
        (cache, env) = assignRecordComponents(vars, values, inCache, inEnv);
      then
        (cache, env);
  end match;
end assignRecord;

protected function assignRecordComponents
  input list<DAE.Var> inVars;
  input list<Values.Value> inValues;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
algorithm
  (outCache, outEnv) := match(inVars, inValues, inCache, inEnv)
    local
      list<DAE.Var> rest_vars;
      Values.Value val;
      list<Values.Value> rest_vals;
      String name;
      DAE.ComponentRef cr;
      DAE.Type ty;
      FCore.Cache cache;
      FCore.Graph env;

    case ({}, {}, _, _) then (inCache, inEnv);

    case (DAE.TYPES_VAR(name = name, ty = ty) :: rest_vars, val :: rest_vals, _ , _)
      equation
        cr = ComponentReference.makeCrefIdent(name, ty, {});
        (cache, env) = assignVariable(cr, val, inCache, inEnv);
        (cache, env) = assignRecordComponents(rest_vars, rest_vals, cache, env);
      then
        (cache, env);
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
  output FCore.Cache outCache;
  output Values.Value outResult;
algorithm
  (outCache, outResult) :=
  matchcontinue(inNewValue, inOldValue, inSubscripts, inCache, inEnv)
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

    // No subscripts, we have either reached the end of the recursion or the
    // whole vector was assigned.
    case (_, _, {}, _, _) then (inCache, inNewValue);

    // An index subscript. Extract the indicated vector element and update it
    // with assignVector, and then put it back in the list of old values.
    case (_, Values.ARRAY(valueLst = values, dimLst = dims), DAE.INDEX(exp = e) :: rest_subs, _, _)
      equation
        (cache, index) = cevalExp(e, inCache, inEnv);
        i = ValuesUtil.valueInteger(index);
        val = listGet(values, i);
        (cache, val) = assignVector(inNewValue, val, rest_subs, cache, inEnv);
        values = List.replaceAt(val, i, values);
      then
        (cache, Values.ARRAY(values, dims));

    // A slice.
    case (Values.ARRAY(valueLst = values),
          Values.ARRAY(valueLst = old_values, dimLst = dims),
          DAE.SLICE(exp = e) :: rest_subs, _, _)
      equation
        // Evaluate the slice range to a list of values.
        (cache, Values.ARRAY(valueLst = (indices as (Values.INTEGER(integer = i) :: _)))) =
        cevalExp(e, inCache, inEnv);
        // Split the list of old values at the first slice index.
        (old_values, old_values2) = List.splitr(old_values, i - 1);
        // Update the rest of the old value with assignSlice.
        (cache, values2) =
          assignSlice(values, old_values2, indices, rest_subs, i, cache, inEnv);
        // Assemble the list of values again.
        values = List.append_reverse(old_values, values2);
      then
        (cache, Values.ARRAY(values, dims));

    // A : (whole dimension).
    case (Values.ARRAY(valueLst = values),
          Values.ARRAY(valueLst = values2, dimLst = dims),
          DAE.WHOLEDIM() :: rest_subs, _, _)
      equation
        (cache, values) =
          assignWholeDim(values, values2, rest_subs, inCache, inEnv);
      then
        (cache, Values.ARRAY(values, dims));

    case (_, _, sub :: _, _, _)
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
  output FCore.Cache outCache;
  output list<Values.Value> outResult;
algorithm
  (outCache, outResult) :=
  matchcontinue(inNewValues, inOldValues, inIndices, inSubscripts, inIndex,
  inCache, inEnv)
    local
      Values.Value v1, v2, index;
      list<Values.Value> vl1, vl2, rest_indices;
      FCore.Cache cache;

    case (_, _, {}, _, _, _, _) then (inCache, inOldValues);

    // Skip indices that are smaller than the next index in the slice.
    case (vl1, v2 :: vl2, index :: _, _, _, _, _)
      equation
        true = (inIndex < ValuesUtil.valueInteger(index));
        (cache, vl1) = assignSlice(vl1, vl2, inIndices, inSubscripts,
          inIndex + 1, inCache, inEnv);
      then
        (cache, v2 :: vl1);

    case (v1 :: vl1, v2 :: vl2, _ :: rest_indices, _, _, _, _)
      equation
        (cache, v1) = assignVector(v1, v2, inSubscripts, inCache, inEnv);
        (cache, vl1) = assignSlice(vl1, vl2, rest_indices, inSubscripts,
          inIndex + 1, inCache, inEnv);
      then
        (cache, v1 :: vl1);
  end matchcontinue;
end assignSlice;

protected function assignWholeDim
  "This function assigns a whole dimension of a vector."
  input list<Values.Value> inNewValues;
  input list<Values.Value> inOldValues;
  input list<DAE.Subscript> inSubscripts;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  output FCore.Cache outCache;
  output list<Values.Value> outResult;
algorithm
  (outCache, outResult) :=
  match(inNewValues, inOldValues, inSubscripts, inCache, inEnv)
    local
      Values.Value v1, v2;
      list<Values.Value> vl1, vl2;
      FCore.Cache cache;
    case ({}, _, _, _, _) then (inCache, {});
    case (v1 :: vl1, v2 :: vl2, _, _, _)
      equation
        (cache, v1) = assignVector(v1, v2, inSubscripts, inCache, inEnv);
        (cache, vl1) = assignWholeDim(vl1, vl2, inSubscripts, inCache, inEnv);
      then
        (cache, v1 :: vl1);
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
  outVar := inVar;
  outVar.binding := DAE.VALBOUND(inValue, DAE.BINDING_FROM_DEFAULT_VALUE());
end updateRecordBinding;

protected function updateRecordComponentBinding
  "Updates the binding of a record component."
  input DAE.Var inVar;
  input String inComponentId;
  input Values.Value inValue;
  output DAE.Var outVar;
protected
  Values.Value val;
algorithm
  outVar := inVar;
  val := getBindingOrDefault(outVar.binding, outVar.ty);
  val := updateRecordComponentValue(inComponentId, inValue, val);
  outVar.binding := DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE());
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

protected function getBindingValueOpt
  "Returns the value in a binding, or NONE()."
  input DAE.Binding inBinding;
  output Option<Values.Value> outValue;
algorithm
  outValue := match(inBinding)
    local
      Values.Value val;
    case DAE.VALBOUND(valBound = val) then SOME(val);
    case DAE.EQBOUND(evaluatedExp = SOME(val)) then SOME(val);
    else NONE();
  end match;
end getBindingValueOpt;

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
    case (DAE.EQBOUND(evaluatedExp = SOME(val)), _) then val;
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
      Option<Values.Value> oval;
      String id;
      DAE.Type ty;
      DAE.Binding binding, tvbinding;

    // The component is a record itself.
    case (DAE.TYPES_VAR(
        name = id,
        ty = ty as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD())), _)
      equation
        val = getRecordValue(Absyn.IDENT(id), ty, inEnv);
      then
        val;

    // A non-record variable.
    case (DAE.TYPES_VAR(name = id, ty = ty, binding = tvbinding), _)
      algorithm
        (_, DAE.TYPES_VAR(binding = binding), _, _, _, _) :=
          Lookup.lookupIdentLocal(FCore.emptyCache(), inEnv, id);
        oval := getBindingValueOpt(binding);

        // if no binding from env then use the typesvar binding.
        if isNone(oval) then
          oval := getBindingValueOpt(tvbinding);
        end if;

        // if there is still no binding in the typesvar then generated default
        // binding. IDK if this is a good idea. It is like generating a default
        // equation for a variable if in a model. But this is how it was done.
        if isSome(oval) then
          SOME(val) := oval;
        else
          val := generateDefaultBinding(ty);
        end if;

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
        info = ElementSource.getElementSourceFileInfo(inSource);
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
