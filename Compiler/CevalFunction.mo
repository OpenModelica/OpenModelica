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

package CevalFunction
" file:         CevalFunction.mo
  package:      CevalFunction
  description:  This module constant evaluates DAE.Function objects, i.e.
  modelica functions defined by the user.
  "

public import Absyn;
public import DAE;
public import Env;
public import SCode;
public import Values;

protected import Ceval;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import Lookup;
protected import RTOpts;
protected import Types;
protected import Util;
protected import ValuesUtil;

protected type Dependency = tuple<DAE.ComponentRef, list<DAE.ComponentRef>>;

public function evaluate
  input Env.Env inEnv;
  input DAE.Function inFunction;
  input list<Values.Value> inFunctionArguments;
  output Values.Value outResult;
algorithm
  outResult := matchcontinue(inEnv, inFunction, inFunctionArguments)
    local
      Absyn.Path p;
      DAE.FunctionDefinition func;
      DAE.Type ty;
      Values.Value result;
      String func_name;
    case (_, DAE.FUNCTION(
        path = p,
        functions = func :: _,
        type_ = ty,
        partialPrefix = false), _)
      equation
        func_name = Absyn.pathString(p);
        result = evaluateFunction(inEnv, func_name, func, ty, inFunctionArguments);
      then
        result;
    case (_, _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        print("- CevalFunction.evaluate failed for:\n");
        print(DAEDump.dumpFunctionStr(inFunction));
      then
        fail();
  end matchcontinue;
end evaluate;

protected function evaluateFunction
  input Env.Env inEnv;
  input String inFuncName;
  input DAE.FunctionDefinition inFunc;
  input DAE.Type inFuncType;
  input list<Values.Value> inFuncArgs;
  output Values.Value outResult;
algorithm
  outResult := matchcontinue(inEnv, inFuncName, inFunc, inFuncType, inFuncArgs)
    case (_, _, DAE.FUNCTION_DEF(body = body), _, _)
      local
        list<DAE.Element> body;
        list<DAE.Element> vars, output_vars;
        Env.Env env;
        list<Values.Value> return_values;
        Values.Value return_value;
      equation
        (vars, body) = Util.listSplitOnFirstMatch(body, DAEUtil.isNotVar);
        vars = sortFunctionVarsByDependency(vars);
        output_vars = Util.listFilter(vars, DAEUtil.isOutputVar);
        env = setupFunctionEnvironment(inEnv, inFuncName, vars, inFuncArgs);
        env = Util.listFold(body, evaluateElement, env);
        return_values = Util.listMap1(output_vars, getFunctionReturnValue, env);
        return_value = boxReturnValue(return_values);
      then
        return_value;
    case (_, _, _, _, _)
      equation
        Debug.fprintln("failtrace", "- CevalFunction.evaluateFunction failed.\n");
      then
        fail();
  end matchcontinue;
end evaluateFunction;

protected function evaluateElement
  input DAE.Element inElement;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inElement, inEnv)
    local
      Env.Env env;
      list<DAE.Statement> sl;
    case (DAE.DEFINE(componentRef = _), _)
      equation
        print("DEFINE\n");
      then
        fail();
    case (DAE.INITIALDEFINE(componentRef = _), _)
      equation
        print("INITIAL DEFINE\n");
      then
        fail();
    case (DAE.EQUATION(exp = _), _)
      equation
        print("EQUATION\n");
      then
        fail();
    case (DAE.EQUEQUATION(cr1 = _), _)
      equation
        print("EQUEQUATION\n");
      then
        fail();
    case (DAE.ARRAY_EQUATION(dimension = _), _)
      equation
        print("ARRAY_EQUATION\n");
      then
        fail();
    case (DAE.INITIAL_ARRAY_EQUATION(dimension = _), _)
      equation
        print("INITIAL_ARRAY_EQUATION\n");
      then
        fail();
    case (DAE.COMPLEX_EQUATION(lhs = _), _)
      equation
        print("COMPLEX_EQUATION\n");
      then
        fail();
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = _), _)
      equation
        print("INITIAL_COMPLEX_EQUATION\n");
      then
        fail();
    case (DAE.WHEN_EQUATION(condition = _), _)
      equation
        print("WHEN_EQUATION\n");
      then
        fail();
    case (DAE.IF_EQUATION(condition1 = _), _)
      equation
        print("IF_EQUATION\n");
      then
        fail();
    case (DAE.INITIAL_IF_EQUATION(condition1 = _), _)
      equation
        print("INITIAL_IF_EQUATION\n");
      then
        fail();
    case (DAE.INITIALEQUATION(exp1 = _), _)
      equation
        print("INITIALEQUATION\n");
      then
        fail();
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = sl)), _)
      equation
        (sl, env) = DAEUtil.traverseDAEEquationsStmts(sl, optimizeExp, inEnv);
        env = Util.listFold(sl, evaluateStatement, env);
      then
        env;
    case (DAE.INITIALALGORITHM(algorithm_ = _), _)
      equation
        print("INITIALALGORITHM\n");
      then
        fail();
    case (DAE.COMP(ident = _), _)
      equation
        print("COMP\n");
      then
        fail();
    case (DAE.EXTOBJECTCLASS(path = _), _)
      equation
        print("EXTOBJECTCLASS\n");
      then
        fail();
    case (DAE.ASSERT(condition = _), _)
      equation
        print("ASSERT\n");
      then
        fail();
    case (DAE.TERMINATE(message = _), _)
      equation
        print("TERMINATE\n");
      then
        fail();
    case (DAE.REINIT(componentRef = _), _)
      equation
        print("REINIT\n");
      then
        fail();
    case (DAE.NORETCALL(functionName = _), _)
      equation
        print("NORETCALL\n");
      then
        fail();
  end matchcontinue;
end evaluateElement;

protected function optimizeExp
  input tuple<DAE.Exp, Env.Env> inTuple;
  output tuple<DAE.Exp, Env.Env> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.ComponentRef cref;
      DAE.ExpType ety;
      list<DAE.Exp> sub_exps;
      list<DAE.Subscript> subs;
      Env.Env env;
    case ((DAE.ASUB(
        exp = DAE.CREF(componentRef = cref, ty = ety), 
        sub = sub_exps), env))
      equation
        subs = Util.listMap(sub_exps, Expression.makeIndexSubscript);
        cref = ComponentReference.subscriptCref(cref, subs);
      then
        ((DAE.CREF(cref, ety), env));
    else then inTuple;
  end matchcontinue;
end optimizeExp;
        

protected function evaluateStatement
  input DAE.Statement inStatement;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inStatement, inEnv)
    local
      Env.Env env;
      DAE.Exp lhs, rhs, condition;
      DAE.ComponentRef lhs_cref;
      Values.Value rhs_val;
      list<DAE.Statement> statements;
    case (DAE.STMT_ASSIGN(exp1 = lhs, exp = rhs), env)
      equation
        rhs_val = cevalExp(rhs, env);
        lhs_cref = extractLhsComponentRef(lhs);
        env = assignVariable(lhs_cref, inEnv, rhs_val);
      then
        env;
    case (DAE.STMT_TUPLE_ASSIGN(type_ = _), _)
      equation
        print("STMT_TUPLE_ASSIGN\n");
      then
        fail();
    case (DAE.STMT_ASSIGN_ARR(componentRef = lhs_cref, exp = rhs), env)
      equation
        rhs_val = cevalExp(rhs, env);
        env = assignVariable(lhs_cref, inEnv, rhs_val);
      then
        env;
    case (DAE.STMT_IF(exp = _), _)
      equation
        env = evaluateIfStatement(inStatement, inEnv);
      then
        env;
    case (DAE.STMT_FOR(type_ = _), _)
      equation
        env = evaluateForStatement(inStatement, inEnv);
      then
        env;
    case (DAE.STMT_WHILE(exp = condition, statementLst = statements), _)
      equation
        env = evaluateWhileStatement(condition, statements, inEnv);
      then
        env;
    case (DAE.STMT_WHEN(exp = _), _)
      equation
        print("STMT_WHEN\n");
      then
        fail();
    case (DAE.STMT_ASSERT(cond = _), _)
      equation
        print("STMT_ASSERT\n");
      then
        fail();
    case (DAE.STMT_TERMINATE(msg = _), _)
      equation
        print("STMT_TERMINATE\n");
      then
        fail();
    case (DAE.STMT_REINIT(var = _), _)
      equation
        print("STMT_REINIT\n");
      then
        fail();
    case (DAE.STMT_NORETCALL(exp = _), _)
      equation
        print("STMT_NORETCALL\n");
      then
        fail();
    case (DAE.STMT_RETURN(source = _), _)
      equation
        print("STMT_RETURN\n");
      then
        fail();
    case (DAE.STMT_BREAK(source = _), _)
      equation
        print("STMT_BREAK\n");
      then
        fail();
    case (_, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- CevalFunction.evaluateStatement failed for:");
        Debug.traceln(DAEDump.ppStatementStr(inStatement));
      then
        fail();
  end matchcontinue;
end evaluateStatement;

protected function evaluateIfStatement
  input DAE.Statement inStatement;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inStatement, inEnv)
    local
      DAE.Exp cond;
      list<DAE.Statement> stmts;
      DAE.Else else_branch;
      Env.Env env;
      Boolean bool_cond;
    case (DAE.STMT_IF(exp = cond, statementLst = stmts, else_ = else_branch), _)
      equation
        Values.BOOL(boolean = bool_cond) = cevalExp(cond, inEnv);
        env = evaluateIfStatement2(bool_cond, stmts, else_branch, inEnv);
      then
        env;
  end matchcontinue;
end evaluateIfStatement;

protected function evaluateIfStatement2
  input Boolean inCondition;
  input list<DAE.Statement> inStatements;
  input DAE.Else inElse;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inCondition, inStatements, inElse, inEnv)
    local
      Env.Env env;
      list<DAE.Statement> statements;
      DAE.Exp condition;
      Boolean bool_condition;
      DAE.Else else_branch;
    case (true, statements, _, env)
      equation
        env = Util.listFold(statements, evaluateStatement, env);
      then
        env;
    case (false, _, DAE.ELSE(statementLst = statements), env)
      equation
        env = Util.listFold(statements, evaluateStatement, env);
      then
        env;
    case (false, _, DAE.ELSEIF(exp = condition, statementLst = statements, 
        else_ = else_branch), env)
      equation
        Values.BOOL(boolean = bool_condition) = cevalExp(condition, env);
        env = evaluateIfStatement2(bool_condition, statements, else_branch, env);
      then
        env;
     case (false, _, DAE.NOELSE(), _) then inEnv;
  end matchcontinue;
end evaluateIfStatement2;
  
protected function evaluateForStatement
  input DAE.Statement inStatement;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inStatement, inEnv)
    local
      DAE.ExpType ety;
      DAE.Type ty;
      String iter_name;
      DAE.Exp start, stop, step;
      Option<DAE.Exp> opt_step;
      list<DAE.Statement> statements;
      Values.Value start_val, stop_val, step_val;
      Env.Env env;
      DAE.ComponentRef iter_cr;
    case (DAE.STMT_FOR(type_ = ety, iter = iter_name, 
        range = DAE.RANGE(exp = start, expOption = opt_step, range = stop),
        statementLst = statements), env)
      equation
        ty = Types.expTypetoTypesType(ety);
        step = Util.getOptionOrDefault(opt_step, DAE.ICONST(1));
        start_val = cevalExp(start, inEnv);
        step_val = cevalExp(step, inEnv);
        stop_val = cevalExp(stop, inEnv);
        iter_cr = ComponentReference.makeCrefIdent(iter_name, ety, {});
        env = Env.extendFrameForIterator(env, iter_name, ty, DAE.UNBOUND(),
          SCode.CONST(), SOME(DAE.C_CONST())); 
        env = evaluateForLoopRange(env, iter_cr, ty, start_val, step_val,
          stop_val, statements);
      then
        env;
  end matchcontinue;
end evaluateForStatement;

protected function evaluateForLoopRange
  input Env.Env inEnv;
  input DAE.ComponentRef inIter;
  input DAE.Type inIterType;
  input Values.Value inStartValue;
  input Values.Value inStepValue;
  input Values.Value inStopValue;
  input list<DAE.Statement> inStatements;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv, inIter, inIterType, inStartValue, inStepValue,
      inStopValue, inStatements)
    local
      Env.Env env;
      Values.Value next_val;
    case (env, _, _, _, _, _, _)
      equation
        true = ValuesUtil.safeLessEq(inStartValue, inStopValue);
        env = updateVariableBinding(inIter, env, inIterType, inStartValue);
        env = Util.listFold(inStatements, evaluateStatement, env);
        next_val = ValuesUtil.safeIntRealOp(inStartValue, inStepValue, 
          Values.ADDOP);
        env = evaluateForLoopRange(env, inIter, inIterType, next_val,
        inStepValue, inStopValue, inStatements);
      then
        env;
    case (_, _, _, _, _, _, _)
      equation
        false = ValuesUtil.safeLessEq(inStartValue, inStopValue);
      then
        inEnv;
  end matchcontinue;
end evaluateForLoopRange;

protected function evaluateWhileStatement
  input DAE.Exp inCondition;
  input list<DAE.Statement> inStatements;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inCondition, inStatements, inEnv)
    local
      Env.Env env;
    case (_, _, _)
      equation
        Values.BOOL(boolean = true) = cevalExp(inCondition, inEnv);
        env = Util.listFold(inStatements, evaluateStatement, inEnv);
        env = evaluateWhileStatement(inCondition, inStatements, env);
      then
        env;
    case (_, _, _)
      equation
        Values.BOOL(boolean = false) = cevalExp(inCondition, inEnv);
      then
        inEnv;
  end matchcontinue;
end evaluateWhileStatement;

protected function getFunctionReturnValue
  input DAE.Element inOutputVar;
  input Env.Env inEnv;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue(inOutputVar, inEnv)
    case (DAE.VAR(componentRef = cr), _)
      local 
        DAE.ComponentRef cr;
        Values.Value val;
      equation
        (_, DAE.VALBOUND(valBound = val)) = getVariableTypeAndBinding(cr, inEnv);
      then
        val;
  end matchcontinue;
end getFunctionReturnValue;
  
protected function boxReturnValue
  input list<Values.Value> inReturnValues;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue(inReturnValues)
    local
      Values.Value val;
    case ({}) then Values.NORETCALL();
    case ({val}) then val;
    case (_ :: _) then Values.TUPLE(inReturnValues);
  end matchcontinue;
end boxReturnValue;

protected function setupFunctionEnvironment
  input Env.Env inEnv;
  input String inFuncName;
  input list<DAE.Element> inFuncVars;
  input list<Values.Value> inFuncArgs;
  output Env.Env outEnv;
algorithm
  outEnv := Env.openScope(inEnv, false, SOME(inFuncName), SOME(Env.FUNCTION_SCOPE));
  outEnv := extendEnvWithFunctionVars(outEnv, inFuncVars, inFuncArgs);
end setupFunctionEnvironment;

protected function extendEnvWithFunctionVars
  input Env.Env inEnv;
  input list<DAE.Element> inFuncVars;
  input list<Values.Value> inFuncArgs;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv, inFuncVars, inFuncArgs)
    local
      DAE.Element e;
      list<DAE.Element> el;
      Values.Value val;
      list<Values.Value> rest_vals;
      Env.Env env;
      DAE.Var var;
    case (_, {}, {}) then inEnv;
    case (env, (e as DAE.VAR(direction = DAE.INPUT())) :: el, val :: rest_vals)
      equation
        var = elementToVar(e, SOME(val), env);
        env = Env.extendFrameV(env, var, NONE(), Env.VAR_TYPED(), {});
      then
        extendEnvWithFunctionVars(env, el, rest_vals);
    case (env, (e as DAE.VAR(direction = _, binding = SOME(binding_exp))) :: el, _)
      local
        DAE.Exp binding_exp;
      equation
        val = cevalExp(binding_exp, inEnv);
        var = elementToVar(e, SOME(val), env);
        env = Env.extendFrameV(env, var, NONE(), Env.VAR_TYPED(), {});
      then
        extendEnvWithFunctionVars(env, el, inFuncArgs);
    case (env, (e as DAE.VAR(direction = _)) :: el, _)
      equation
        var = elementToVar(e, NONE(), env);
        env = Env.extendFrameV(env, var, NONE(), Env.VAR_TYPED(), {});
      then
        extendEnvWithFunctionVars(env, el, inFuncArgs);
    case (env, e :: _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- CevalFunction.extendEnvWithFunctionVars failed for:");
        Debug.traceln(DAEDump.dumpElementsStr({e}));
      then
        fail();
  end matchcontinue;
end extendEnvWithFunctionVars;

protected function elementToVar 
  input DAE.Element inElement;
  input Option<Values.Value> inBindingValue;
  input Env.Env inEnv;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue(inElement, inBindingValue, inEnv)
    case (DAE.VAR(componentRef = cr, ty = ty, dims = dims), _, _)
      local
        DAE.ComponentRef cr;
        String var_name;
        DAE.Type ty;
        DAE.Binding binding;
        DAE.InstDims dims;
        list<Integer> binding_dims;
      equation
        binding = getBinding(inBindingValue);
        var_name = ComponentReference.crefStr(cr);
        binding_dims = ValuesUtil.valueDimensions(
          Util.getOptionOrDefault(inBindingValue, Values.INTEGER(0)));
        ty = appendDimensions(ty, dims, binding_dims, inEnv);
      then
        DAE.TYPES_VAR(
          var_name,
          DAE.ATTR(
            false,
            false,
            SCode.RW(),
            SCode.VAR(),
            Absyn.BIDIR(),
            Absyn.UNSPECIFIED()),
          false,
          ty,
          binding,
          NONE());
  end matchcontinue;
end elementToVar;
        
protected function getBinding
  input Option<Values.Value> inBindingValue;
  output DAE.Binding outBinding;
algorithm
  outBinding := matchcontinue(inBindingValue)
    local Values.Value val;
    case SOME(val) then DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE());
    case NONE() then DAE.UNBOUND();
  end matchcontinue;
end getBinding;
  
protected function cevalExp
  input DAE.Exp inExp;
  input Env.Env inEnv;
  output Values.Value outValue;
algorithm
  (_, outValue, _) := Ceval.ceval(Env.emptyCache(), inEnv, inExp, true, NONE(), 
    NONE(), Ceval.NO_MSG());
end cevalExp;

protected function assignVariable
  input DAE.ComponentRef inVariableCref;
  input Env.Env inEnv;
  input Values.Value inNewValue;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inVariableCref, inEnv, inNewValue)
    local
      DAE.ComponentRef cr;
      Env.Env env;
      list<DAE.Subscript> subs;
      DAE.Type ty;
      Values.Value val;
    case (cr as DAE.CREF_IDENT(subscriptLst = {}), _, val)
      equation
        (ty, _) = getVariableTypeAndBinding(cr, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        env;
    case (cr as DAE.CREF_IDENT(subscriptLst = subs), _, _)
      equation
        cr = ComponentReference.crefStripSubs(cr);
        (ty, DAE.VALBOUND(valBound = val)) =
          getVariableTypeAndBinding(cr, inEnv); 
        val = assignVector(inNewValue, val, subs, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        env;
    case (cr as DAE.CREF_IDENT(subscriptLst = subs), _, _)
      equation
        cr = ComponentReference.crefStripSubs(cr);
        (ty, _) = getVariableTypeAndBinding(cr, inEnv);
        val = generateDefaultBinding(ty);
        val = assignVector(inNewValue, val, subs, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        env;
  end matchcontinue;
end assignVariable;

protected function assignVector
  input Values.Value inNewValue;
  input Values.Value inOldValue;
  input list<DAE.Subscript> inSubscripts;
  input Env.Env inEnv;
  output Values.Value outResult;
algorithm
  outResult := matchcontinue(inNewValue, inOldValue, inSubscripts, inEnv)
    local
      DAE.Exp e;
      Values.Value index, val;
      list<Values.Value> values, values2;
      list<Values.Value> old_values, old_values2, indices;
      list<Integer> dims;
      Integer i;
      DAE.Subscript sub;
      list<DAE.Subscript> rest_subs;
    case (_, _, {}, _) then inNewValue;
    case (_, Values.ARRAY(valueLst = values, dimLst = dims), 
        DAE.INDEX(exp = e) :: rest_subs, _)
      equation
        index = cevalExp(e, inEnv);
        i = ValuesUtil.valueInteger(index) - 1;
        val = listNth(values, i);
        val = assignVector(inNewValue, val, rest_subs, inEnv);
        values = Util.listReplaceAt(val, i, values);
      then
        Values.ARRAY(values, dims);
    case (Values.ARRAY(valueLst = values),
        Values.ARRAY(valueLst = old_values, dimLst = dims),
        DAE.SLICE(exp = e) :: rest_subs, _)
      equation
        Values.ARRAY(valueLst = (indices as (Values.INTEGER(integer = i) :: _))) = 
          cevalExp(e, inEnv);
        (old_values, old_values2) = Util.listSplit(old_values, i - 1);
        values2 = assignSlice(values, old_values2, indices, rest_subs, inEnv);
        values = listAppend(old_values, values2);
      then
        Values.ARRAY(values, dims);
    case (Values.ARRAY(valueLst = values), 
          Values.ARRAY(valueLst = values2, dimLst = dims),
        DAE.WHOLEDIM() :: rest_subs, _)
      equation
        values = assignWholeDim(values, values2, rest_subs, inEnv);
      then
        Values.ARRAY(values, dims);
    case (_, _, sub :: _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        print("- CevalFunction.assignVector failed on: ");
        print(ExpressionDump.printSubscriptStr(sub) +& "\n");
      then
        fail();
  end matchcontinue;
end assignVector;

protected function assignSlice
  input list<Values.Value> inNewValues;
  input list<Values.Value> inOldValues;
  input list<Values.Value> inIndices;
  input list<DAE.Subscript> inSubscripts;
  input Env.Env inEnv;
  output list<Values.Value> outResult;
algorithm
  outResult := matchcontinue(inNewValues, inOldValues, inIndices, inSubscripts, inEnv)
    local
      Values.Value v1, v2;
      list<Values.Value> vl1, vl2, rest_indices;
    case (_, _, {}, _, _) then inOldValues;
    case (v1 :: vl1, v2 :: vl2, _ :: rest_indices, _, _)
      equation
        v1 = assignVector(v1, v2, inSubscripts, inEnv);
        vl1 = assignSlice(vl1, vl2, rest_indices, inSubscripts, inEnv);
      then
        v1 :: vl1;
  end matchcontinue;
end assignSlice;

protected function assignWholeDim
  input list<Values.Value> inNewValues;
  input list<Values.Value> inOldValues;
  input list<DAE.Subscript> inSubscripts;
  input Env.Env inEnv;
  output list<Values.Value> outResult;
algorithm
  outResult := matchcontinue(inNewValues, inOldValues, inSubscripts, inEnv)
    local
      Values.Value v1, v2;
      list<Values.Value> vl1, vl2;
    case ({}, _, _, _) then {};
    case (v1 :: vl1, v2 :: vl2, _, _)
      equation
        v1 = assignVector(v1, v2, inSubscripts, inEnv);
        vl1 = assignWholeDim(vl1, vl2, inSubscripts, inEnv);
      then
        v1 :: vl1;
  end matchcontinue;
end assignWholeDim;

protected function updateVariableBinding
  input DAE.ComponentRef inVariableCref;
  input Env.Env inEnv;
  input DAE.Type inType;
  input Values.Value inNewValue;
  output Env.Env outEnv;

  String var_name;
algorithm
  var_name := ComponentReference.crefStr(inVariableCref);
  outEnv := Env.updateFrameV(
    inEnv, 
    DAE.TYPES_VAR(
      var_name,
      DAE.ATTR(
        false,
        false,
        SCode.RW(),
        SCode.VAR(),
        Absyn.BIDIR(),
        Absyn.UNSPECIFIED()),
      false,
      inType,
      DAE.VALBOUND(inNewValue, DAE.BINDING_FROM_DEFAULT_VALUE()),
      NONE()),
    Env.VAR_TYPED(),
    {});
end updateVariableBinding;

protected function extractLhsComponentRef
  input DAE.Exp inExp;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inExp)
    local
      DAE.ComponentRef cref;
      DAE.Exp asub_exp;
    case DAE.CREF(componentRef = cref) then cref;
    case DAE.ASUB(exp = asub_exp) then extractLhsComponentRef(asub_exp);
    else
      equation
        print("- CevalFunction.extractLhsComponentRef failed on " +&
          ExpressionDump.printExpStr(inExp) +& "\n");
      then
        fail();
  end matchcontinue;
end extractLhsComponentRef;

protected function getVariableTypeAndBinding
  input DAE.ComponentRef inCref;
  input Env.Env inEnv;
  output DAE.Type outType;
  output DAE.Binding outBinding;
algorithm
  (_, _, outType, outBinding, _, _, _, _, _) := 
    Lookup.lookupVar(Env.emptyCache(), inEnv, inCref);
end getVariableTypeAndBinding;

protected function generateDefaultBinding
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
    case ((DAE.T_INTEGER(varLstInt = _), _)) then Values.INTEGER(0);
    case ((DAE.T_REAL(varLstReal = _), _)) then Values.REAL(0.0);
    case ((DAE.T_STRING(varLstString = _), _)) then Values.STRING("");
    case ((DAE.T_BOOL(varLstBool = _), _)) then Values.BOOL(false);
    case ((DAE.T_ENUMERATION(index = _), _)) 
      then Values.ENUM_LITERAL(Absyn.IDENT(""), 0);
    case ((DAE.T_ARRAY(arrayDim = dim, arrayType = ty), _))
      equation
        int_dim = Expression.dimensionSize(dim);
        value = generateDefaultBinding(ty);
        values = Util.listFill(value, int_dim);
        dims = ValuesUtil.valueDimensions(value);
      then
        Values.ARRAY(values, int_dim :: dims);
    case (_)
      equation
        Debug.fprintln("failtrace", "- CevalFunction.generateDefaultBinding failed\n");
      then
        fail();
  end matchcontinue;
end generateDefaultBinding;

protected function appendDimensions
  input DAE.Type inType;
  input DAE.InstDims inDims;
  input list<Integer> inBindingDims;
  input Env.Env inEnv;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType, inDims, inBindingDims, inEnv)
    local
      DAE.InstDims rest_dims;
      DAE.Exp dim_exp;
      Values.Value dim_val;
      Integer dim_int;
      DAE.Dimension dim;
      DAE.Type ty;
      list<Integer> bind_dims;
    case (ty, {}, _, _) then ty;
    case (ty, DAE.INDEX(exp = dim_exp) :: rest_dims, bind_dims, _)
      equation
        dim_val = cevalExp(dim_exp, inEnv);
        dim_int = ValuesUtil.valueInteger(dim_val);
        dim = Expression.intDimension(dim_int);
        bind_dims = Util.listRestOrEmpty(bind_dims);
        ty = appendDimensions(ty, rest_dims, bind_dims, inEnv);
      then
        ((DAE.T_ARRAY(dim, ty), NONE()));
    case (ty, DAE.WHOLEDIM() :: rest_dims, dim_int :: bind_dims, _)
      equation
        dim = Expression.intDimension(dim_int);
        ty = appendDimensions(ty, rest_dims, bind_dims, inEnv);
      then
        ((DAE.T_ARRAY(dim, ty), NONE()));
    case (_, sub :: _, _, _)
      local
        DAE.Subscript sub;
      equation
        Debug.fprintln("failtrace", "- CevalFunction.appendDimensions failed");
      then
        fail();
  end matchcontinue;
end appendDimensions;

protected function sortFunctionVarsByDependency
  input list<DAE.Element> inFuncVars;
  output list<DAE.Element> outFuncVars;

  list<Dependency> dependencies;
algorithm
  dependencies := Util.listMap(inFuncVars, buildDependencyList);
  outFuncVars := sortFunctionVarsByDependency2(inFuncVars, dependencies);
end sortFunctionVarsByDependency;

protected function sortFunctionVarsByDependency2
  input list<DAE.Element> inFuncVars;
  input list<Dependency> inDependencies;
  output list<DAE.Element> outFuncVars;
algorithm
  outFuncVars := matchcontinue(inFuncVars, inDependencies)
    local
      DAE.Element elem;
      DAE.ComponentRef cref;
      list<DAE.Element> rest_elems, dep_elems;
      list<DAE.ComponentRef> deps;
    case ({}, _) then {};
    case ((elem as DAE.VAR(componentRef = cref)) :: rest_elems, _)
      equation
        deps = findDependencies(cref, inDependencies);
        (dep_elems, rest_elems) = extractDependencies(deps, rest_elems);
        dep_elems = sortFunctionVarsByDependency2(dep_elems, inDependencies); 
        rest_elems = sortFunctionVarsByDependency2(rest_elems, inDependencies);
        rest_elems = elem :: rest_elems;
        rest_elems = listAppend(dep_elems, rest_elems);
      then
        rest_elems;
  end matchcontinue;
end sortFunctionVarsByDependency2;

protected function extractDependencies
  input list<DAE.ComponentRef> inDependencies;
  input list<DAE.Element> inFuncVars;
  output list<DAE.Element> outDepVars;
  output list<DAE.Element> outRestVars;
algorithm
  (outDepVars, outRestVars) := matchcontinue(inDependencies, inFuncVars)
    local
      DAE.ComponentRef dep_cref;
      list<DAE.ComponentRef> rest_deps;
      list<DAE.Element> dep_elem, dep_elems, rest_elems;
    case ({}, _) then ({}, inFuncVars);
    case (dep_cref :: rest_deps, _)
      equation
        (dep_elem, rest_elems) = extractDependency(dep_cref, inFuncVars);
        (dep_elems, rest_elems) = extractDependencies(rest_deps, rest_elems);
        dep_elems = listAppend(dep_elem, dep_elems);
      then
        (dep_elems, rest_elems);
  end matchcontinue;
end extractDependencies;
        
protected function extractDependency
  input DAE.ComponentRef inCref;
  input list<DAE.Element> inFuncVars;
  output list<DAE.Element> outDependency;
  output list<DAE.Element> outRestVars;
algorithm
  (outDependency, outRestVars) := matchcontinue(inCref, inFuncVars)
    local
      DAE.ComponentRef cr;
      DAE.Element e;
      list<DAE.Element> el, el2;
    case (_, {}) then ({}, {});
    case (_, (e as DAE.VAR(componentRef = cr)) :: el)
      equation
        true = ComponentReference.crefEqualNoStringCompare(inCref, cr);
      then
        ({e}, el);
    case (_, e :: el)
      equation
        (el, el2) = extractDependency(inCref, el);
      then
        (el, e :: el2);
  end matchcontinue;
end extractDependency;

protected function findDependencies
  input DAE.ComponentRef inCref;
  input list<Dependency> inDependencies;
  output list<DAE.ComponentRef> outDependencies;

  list<DAE.ComponentRef> deps;
  list<list<DAE.ComponentRef>> dep_deps;
algorithm
  deps := findDependency(inCref, inDependencies);
  dep_deps := Util.listMap1(deps, findDependencies, inDependencies);
  outDependencies := listAppend(Util.listFlatten(dep_deps), deps);
end findDependencies;

protected function findDependency
  input DAE.ComponentRef inCref;
  input list<Dependency> inDependencies;
  output list<DAE.ComponentRef> outDependencies;
algorithm
  outDependencies := matchcontinue(inCref, inDependencies)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> cl;
      list<Dependency> rest_deps;
    case (_, {}) then {};
    case (_, (cr, cl) :: _)
      equation
        true = ComponentReference.crefEqualNoStringCompare(inCref, cr);
      then
        cl;
    case (_, _ :: rest_deps)
      equation
        cl = findDependency(inCref, rest_deps);
      then
        cl;
  end matchcontinue;
end findDependency;

protected function createDependency
  input DAE.Element inVar;
  input list<DAE.ComponentRef> inDependencies;
  output Dependency outDependency;
algorithm
  outDependency := matchcontinue(inVar, inDependencies)
    local
      DAE.ComponentRef cr;
    case (DAE.VAR(componentRef = cr), _) then ((cr, inDependencies));
  end matchcontinue;
end createDependency;

protected function buildDependencyList
  input DAE.Element inVar;
  output Dependency outDependencies;
algorithm
  outDependencies := matchcontinue(inVar)
    local
      DAE.Exp bind_exp;
      DAE.InstDims dims;
      list<DAE.ComponentRef> cl, cl2;
      list<list<DAE.ComponentRef>> subs_crefs;
    // A variable with a binding.
    case DAE.VAR(binding = SOME(bind_exp), dims = dims)
      equation
        cl = Expression.extractCrefsFromExp(bind_exp);
        subs_crefs = Util.listMap(dims, extractCrefsFromSubscript);
        cl2 = Util.listFlatten(subs_crefs);
        cl = listAppend(cl, cl2);
      then
        createDependency(inVar, cl);
    // A variable without a binding.
    case DAE.VAR(binding = NONE(), dims = dims)
      equation
        subs_crefs = Util.listMap(dims, extractCrefsFromSubscript);
        cl = Util.listFlatten(subs_crefs);
      then
        createDependency(inVar, cl);
  end matchcontinue;
end buildDependencyList;

protected function extractCrefsFromSubscript
  input DAE.Subscript inSubscript;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  outCrefs := matchcontinue(inSubscript)
    local
      DAE.Exp e;
    case DAE.SLICE(exp = e) then Expression.extractCrefsFromExp(e);
    case DAE.INDEX(exp = e) then Expression.extractCrefsFromExp(e);
    else then {};
  end matchcontinue;
end extractCrefsFromSubscript;
      
end CevalFunction;
