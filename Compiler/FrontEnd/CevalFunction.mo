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

  RCS: $Id$

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
public import Env;
public import SCode;
public import Values;

// protected imports
protected import Ceval;
protected import ClassInf;
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

// [TYPE]  Types

// This type represents a list of dependencies for a variable, where the first
// component reference is the variable itself.
protected type Dependency = tuple<DAE.ComponentRef, list<DAE.ComponentRef>>;

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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Function inFunction;
  input list<Values.Value> inFunctionArguments;
  output Env.Cache outCache;
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
      Env.Cache cache;

    // The DAE.FUNCTION structure might contain an optional function derivative
    // mapping which is why functions below is a list. We only evaluate the
    // first function, which is hopefully the one we want.
    case (_, _, DAE.FUNCTION(
        path = p,
        functions = func :: _,
        type_ = ty,
        partialPrefix = false), _)
      equation
        func_name = Absyn.pathString(p);
        (cache, result) = evaluateFunctionDefinition(inCache, inEnv, func_name,
          func, ty, inFunctionArguments); 
      then
        (cache, result);

    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- CevalFunction.evaluate failed for function ");
        Debug.traceln(DAEDump.dumpFunctionStr(inFunction));
      then
        fail();
  end matchcontinue;
end evaluate;

protected function evaluateFunctionDefinition
  "This function constant evaluates a function definition."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inFuncName;
  input DAE.FunctionDefinition inFunc;
  input DAE.Type inFuncType;
  input list<Values.Value> inFuncArgs;
  output Env.Cache outCache;
  output Values.Value outResult;
algorithm
  (outCache, outResult) := 
  matchcontinue(inCache, inEnv, inFuncName, inFunc, inFuncType, inFuncArgs)
    local
      list<DAE.Element> body;
      list<DAE.Element> vars, output_vars;
      Env.Cache cache;
      Env.Env env;
      list<Values.Value> return_values;
      Values.Value return_value;
    
    case (_, _, _, DAE.FUNCTION_DEF(body = body), _, _)
      equation
        // Split the definition into function variables and statements.
        (vars, body) = Util.listSplitOnFirstMatch(body, DAEUtil.isNotVar);
        // Save the output variables, so that we can return their values when
        // we're done.
        output_vars = Util.listFilter(vars, DAEUtil.isOutputVar);
        vars = sortFunctionVarsByDependency(vars);
        // Create an environment for the function and add all function variables.
        (cache, env) = setupFunctionEnvironment(inCache, inEnv, inFuncName, vars, inFuncArgs);
        // Evaluate the body of the function.
        (cache, env, _) = evaluateElements(body, cache, env, NEXT());
        // Fetch the values of the output variables.
        return_values = Util.listMap1(output_vars, getFunctionReturnValue, env);
        // If we have several output variables they should be boxed into a tuple.
        return_value = boxReturnValue(return_values);
      then
        (cache, return_value);
    
    else
      equation
        Debug.fprintln("failtrace", "- CevalFunction.evaluateFunction failed.\n");
      then
        fail();
  end matchcontinue;
end evaluateFunctionDefinition;

protected function evaluateElements
  "This function evaluates a list of elements."
  input list<DAE.Element> inElements;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input LoopControl inLoopControl;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := 
  match(inElements, inCache, inEnv, inLoopControl)
    local
      DAE.Element elem;
      list<DAE.Element> rest_elems;
      Env.Cache cache;
      Env.Env env;
      LoopControl loop_ctrl;
    case (_, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case ({}, _, _, _) then (inCache, inEnv, NEXT());
    case (elem :: rest_elems, _, _, _)
      equation
        (cache, env, loop_ctrl) = evaluateElement(elem, inCache, inEnv);
        (cache, env, loop_ctrl) = evaluateElements(rest_elems, cache, env, loop_ctrl);
      then
        (cache, env, loop_ctrl);
  end match;
end evaluateElements;

protected function evaluateElement
  "This function evaluates a single element, which should be an algorithm."
  input DAE.Element inElement;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := match(inElement, inCache, inEnv)
    local
      Env.Cache cache;
      Env.Env env;
      LoopControl loop_ctrl;
      list<DAE.Statement> sl;

    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = sl)), _, _)
      equation
        (sl, env) = DAEUtil.traverseDAEEquationsStmts(sl, optimizeExp, inEnv);
        (cache, env, loop_ctrl) = evaluateStatements(sl, inCache, env);
      then
        (cache, env, loop_ctrl);
   end match;
end evaluateElement;

protected function evaluateStatement
  "This function evaluates a statement."
  input DAE.Statement inStatement;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := matchcontinue(inStatement, inCache, inEnv)
    local
      Env.Cache cache;
      Env.Env env;
      DAE.Exp lhs, rhs, condition;
      DAE.ComponentRef lhs_cref;
      Values.Value rhs_val;
      list<DAE.Statement> statements;
      list<DAE.Exp> expl;
      Absyn.Path fn_name;
      LoopControl loop_ctrl;

    case (DAE.STMT_ASSIGN(exp1 = lhs, exp = rhs), cache, env)
      equation
        (cache, rhs_val) = cevalExp(rhs, cache, env);
        lhs_cref = extractLhsComponentRef(lhs);
        (cache, env) = assignVariable(lhs_cref, rhs_val, cache, env);
      then
        (cache, env, NEXT());

    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = _), _, _)
      equation
        (cache, env) = evaluateTupleAssignStatement(inStatement, inCache, inEnv); 
      then
        (cache, env, NEXT());

    case (DAE.STMT_ASSIGN_ARR(componentRef = lhs_cref, exp = rhs), _, env)
      equation
        (cache, rhs_val) = cevalExp(rhs, inCache, env);
        (cache, env) = assignVariable(lhs_cref, rhs_val, cache, env);
      then
        (cache, env, NEXT());

    case (DAE.STMT_IF(exp = _), _, _)
      equation
        (cache, env, loop_ctrl) = evaluateIfStatement(inStatement, inCache, inEnv);
      then
        (cache, env, loop_ctrl);

    case (DAE.STMT_FOR(type_ = _), _, _)
      equation
        (cache, env, loop_ctrl) = evaluateForStatement(inStatement, inCache, inEnv);
      then
        (cache, env, loop_ctrl);

    case (DAE.STMT_WHILE(exp = condition, statementLst = statements), _, _)
      equation
        (cache, env, loop_ctrl) = evaluateWhileStatement(condition, statements,
          inCache, inEnv, NEXT());
      then
        (cache, env, loop_ctrl);

    // If the condition is true in the assert, do nothing. If the condition
    // is false we should stop the instantiation (depending on the assertion
    // level), but we can't really do much about that here. So right now we just
    // fail.
    case (DAE.STMT_ASSERT(cond = condition), _, _)
      equation
        (cache, Values.BOOL(boolean = true)) = cevalExp(condition, inCache, inEnv);
      then
        (cache, inEnv, NEXT());

    // Non-returning function calls should probably be constant evaluated, but
    // causes problem when we call functions with side-effects (such as in the
    // test case mosfiles/Random.mos). Enable this code when functions with
    // side-effects are no longer constant evaluated.
    /*case (DAE.STMT_NORETCALL(exp = rhs), _, _)
      equation
        _ = cevalExp(rhs, inEnv);
      then
        (inEnv, NEXT());*/

    case (DAE.STMT_RETURN(source = _), _, _)
      then
        (inCache, inEnv, RETURN());

    case (DAE.STMT_BREAK(source = _), _, _)
      then
        (inCache, inEnv, BREAK());

    case (_, _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- CevalFunction.evaluateStatement failed for:");
        Debug.traceln(DAEDump.ppStatementStr(inStatement));
      then
        fail();
  end matchcontinue;
end evaluateStatement;

protected function evaluateStatements
  "This function evaluates a list of statements. This is just a wrapper for
  evaluateStatements2."
  input list<DAE.Statement> inStatement;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := 
    evaluateStatements2(inStatement, inCache, inEnv, NEXT());
end evaluateStatements;

protected function evaluateStatements2
  "This is a helper function to evaluateStatements that evaluates a list of
  statements."
  input list<DAE.Statement> inStatement;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input LoopControl inLoopControl;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := 
  matchcontinue(inStatement, inCache, inEnv, inLoopControl)
    local
      DAE.Statement stmt;
      list<DAE.Statement> rest_stmts;
      Env.Cache cache;
      Env.Env env;
      LoopControl loop_ctrl;
    case (_, _, _, BREAK()) then (inCache, inEnv, inLoopControl);
    case (_, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case ({}, _, _, _) then (inCache, inEnv, inLoopControl);
    case (stmt :: rest_stmts, _, _, NEXT())
      equation
        (cache, env, loop_ctrl) = evaluateStatement(stmt, inCache, inEnv);
        (cache, env, loop_ctrl) = evaluateStatements2(rest_stmts, cache, env, loop_ctrl);
      then
        (cache, env, loop_ctrl);
  end matchcontinue;
end evaluateStatements2;

protected function evaluateTupleAssignStatement
  "This function evaluates tuple assignment statements, i.e. assignment
  statements where the right hand side expression is a tuple. Ex:
    (x, y, z) := fun(...)"
  input DAE.Statement inStatement;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := match(inStatement, inCache, inEnv)
    local
      list<DAE.Exp> lhs_expl;
      DAE.Exp rhs;
      list<Values.Value> rhs_vals;
      list<DAE.ComponentRef> lhs_crefs;
      Env.Cache cache;
      Env.Env env;
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = lhs_expl, exp = rhs), _, env)
      equation
        (cache, Values.TUPLE(valueLst = rhs_vals)) = cevalExp(rhs, inCache, env);
        lhs_crefs = Util.listMap(lhs_expl, extractLhsComponentRef);
        (cache, env) = assignTuple(lhs_crefs, rhs_vals, cache, env);
      then
        (cache, env);
  end match;
end evaluateTupleAssignStatement;

protected function evaluateIfStatement
  "This function evaluates an if statement."
  input DAE.Statement inStatement;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := match(inStatement, inCache, inEnv)
    local
      DAE.Exp cond;
      list<DAE.Statement> stmts;
      DAE.Else else_branch;
      Env.Cache cache;
      Env.Env env;
      Boolean bool_cond;
      LoopControl loop_ctrl;
    case (DAE.STMT_IF(exp = cond, statementLst = stmts, else_ = else_branch), _, _)
      equation
        (cache, Values.BOOL(boolean = bool_cond)) = cevalExp(cond, inCache, inEnv);
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := 
  match(inCondition, inStatements, inElse, inCache, inEnv)
    local
      Env.Cache cache;
      Env.Env env;
      list<DAE.Statement> statements;
      DAE.Exp condition;
      Boolean bool_condition;
      DAE.Else else_branch;
      LoopControl loop_ctrl;
    // If the condition is true, evaluate the statements in the if branch.
    case (true, statements, _, _, env)
      equation
        (cache, env, loop_ctrl) = evaluateStatements(statements, inCache, env);
      then
        (cache, env, loop_ctrl);
    // If the condition is false and we have an else, evaluate the statements in
    // the else branch.
    case (false, _, DAE.ELSE(statementLst = statements), _, env)
      equation
        (cache, env, loop_ctrl) = evaluateStatements(statements, inCache, env);
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := matchcontinue(inStatement, inCache, inEnv)
    local
      DAE.ExpType ety;
      DAE.Type ty;
      String iter_name;
      DAE.Exp start, stop, step, range;
      Option<DAE.Exp> opt_step;
      list<DAE.Statement> statements;
      Values.Value start_val, stop_val, step_val;
      list<Values.Value> range_vals;
      Env.Cache cache;
      Env.Env env;
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

    // The case where the range is a range on the form start:step:stop.
    case (DAE.STMT_FOR(type_ = ety, iter = iter_name, 
        range = DAE.RANGE(exp = start, expOption = opt_step, range = stop),
        statementLst = statements), cache, env)
      equation
        step = Util.getOptionOrDefault(opt_step, DAE.ICONST(1));
        (cache, start_val) = cevalExp(start, cache, env);
        (cache, step_val) = cevalExp(step, cache, env);
        (cache, stop_val) = cevalExp(stop, cache, env);
        (env, ty, iter_cr) = extendEnvWithForScope(iter_name, ety, env);
        (cache, env, loop_ctrl) = evaluateForLoopRange(cache, env, iter_cr, ty,
          start_val, step_val, stop_val, statements, NEXT());
      then
        (cache, env, loop_ctrl);

    case (DAE.STMT_FOR(range = range), _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- evaluateForStatement not implemented for:");
        Debug.traceln(ExpressionDump.printExpStr(range));
      then
        fail();
  end matchcontinue;
end evaluateForStatement;

protected function evaluateForLoopArray
  "This function evaluates a for loop where the range is an array."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inIter;
  input DAE.Type inIterType;
  input list<Values.Value> inValues;
  input list<DAE.Statement> inStatements;
  input LoopControl inLoopControl;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := matchcontinue(inCache, inEnv, inIter,
      inIterType, inValues, inStatements, inLoopControl)
    local
      Values.Value value;
      list<Values.Value> rest_vals;
      Env.Cache cache;
      Env.Env env;
      LoopControl loop_ctrl;
    case (_, _, _, _, _, _, BREAK()) then (inCache, inEnv, NEXT());
    case (_, _, _, _, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case (_, _, _, _, {}, _, _) then (inCache, inEnv, inLoopControl);
    case (_, env, _, _, value :: rest_vals, _, NEXT())
      equation
        env = updateVariableBinding(inIter, env, inIterType, value);
        (cache, env, loop_ctrl) = evaluateStatements(inStatements, inCache, env);
        (cache, env, loop_ctrl) = evaluateForLoopArray(cache, env, inIter,
          inIterType, rest_vals, inStatements, loop_ctrl);
      then
        (cache, env, loop_ctrl);
  end matchcontinue;
end evaluateForLoopArray;

protected function evaluateForLoopRange
  "This function evaluates a for loop where the range is on the form
  start:step:stop."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inIter;
  input DAE.Type inIterType;
  input Values.Value inStartValue;
  input Values.Value inStepValue;
  input Values.Value inStopValue;
  input list<DAE.Statement> inStatements;
  input LoopControl inLoopControl;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := 
  matchcontinue(inCache, inEnv, inIter, inIterType, inStartValue, inStepValue,
      inStopValue, inStatements, inLoopControl)
    local
      Env.Cache cache;
      Env.Env env;
      Values.Value next_val;
      LoopControl loop_ctrl;
    case (_, _, _, _, _, _, _, _, BREAK()) then (inCache, inEnv, NEXT());
    case (_, _, _, _, _, _, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case (cache, env, _, _, _, _, _, _, NEXT())
      equation
        true = ValuesUtil.safeLessEq(inStartValue, inStopValue);
        env = updateVariableBinding(inIter, env, inIterType, inStartValue);
        (cache, env, loop_ctrl) = evaluateStatements(inStatements, cache, env);
        next_val = ValuesUtil.safeIntRealOp(inStartValue, inStepValue, 
          Values.ADDOP());
        (cache, env, loop_ctrl) = evaluateForLoopRange(cache, env, inIter,
          inIterType, next_val, inStepValue, inStopValue, inStatements, loop_ctrl);
      then
        (cache, env, loop_ctrl);
    else
      equation
        false = ValuesUtil.safeLessEq(inStartValue, inStopValue);
      then
        (inCache, inEnv, NEXT());
  end matchcontinue;
end evaluateForLoopRange;

protected function evaluateWhileStatement
  "This function evaluates a while statement."
  input DAE.Exp inCondition;
  input list<DAE.Statement> inStatements;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input LoopControl inLoopControl;
  output Env.Cache outCache;
  output Env.Env outEnv;
  output LoopControl outLoopControl;
algorithm
  (outCache, outEnv, outLoopControl) := 
  matchcontinue(inCondition, inStatements, inCache, inEnv, inLoopControl)
    local
      Env.Cache cache;
      Env.Env env;
      LoopControl loop_ctrl;
    case (_, _, _, _, BREAK()) then (inCache, inEnv, NEXT());
    case (_, _, _, _, RETURN()) then (inCache, inEnv, inLoopControl);
    case (_, _, _, _, _)
      equation
        (cache, Values.BOOL(boolean = true)) = cevalExp(inCondition, inCache, inEnv);
        (cache, env, loop_ctrl) = evaluateStatements(inStatements, cache, inEnv);
        (cache, env, loop_ctrl) = 
          evaluateWhileStatement(inCondition, inStatements, cache, env, loop_ctrl);
      then
        (cache, env, loop_ctrl);
    else
      equation
        (cache, Values.BOOL(boolean = false)) = cevalExp(inCondition, inCache, inEnv);
      then
        (cache, inEnv, NEXT());
  end matchcontinue;
end evaluateWhileStatement;

protected function extractLhsComponentRef
  "This function extracts a component reference from an expression. It's used to
  get the left hand side component reference in simple assignments."
  input DAE.Exp inExp;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inExp)
    local
      DAE.ComponentRef cref;
      DAE.Exp asub_exp;
    case DAE.CREF(componentRef = cref) then cref;
    else
      equation
        print("- CevalFunction.extractLhsComponentRef failed on " +&
          ExpressionDump.printExpStr(inExp) +& "\n");
      then
        fail();
  end matchcontinue;
end extractLhsComponentRef;

protected function cevalExp
  "A wrapper for Ceval with most of the arguments filled in."
  input DAE.Exp inExp;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue, _) := Ceval.ceval(inCache, inEnv, inExp, true, NONE(), 
    NONE(), Ceval.NO_MSG());
end cevalExp;

// [EENV]  Environment extension functions (add variables).

protected function setupFunctionEnvironment
  "Opens up a new scope for the functions and adds all function variables to it."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inFuncName;
  input list<DAE.Element> inFuncVars;
  input list<Values.Value> inFuncArgs;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  outEnv := Env.openScope(inEnv, false, SOME(inFuncName), SOME(Env.FUNCTION_SCOPE()));
  (outCache, outEnv) := 
    extendEnvWithFunctionVars(inCache, outEnv, inFuncVars, inFuncArgs);
end setupFunctionEnvironment;

protected function extendEnvWithFunctionVars
  "Extends the environment with a list of variables. The list of values is the
  input arguments to the function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Element> inFuncVars;
  input list<Values.Value> inFuncArgs;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := matchcontinue(inCache, inEnv, inFuncVars, inFuncArgs)
    local
      DAE.Element e;
      list<DAE.Element> el;
      Values.Value val;
      list<Values.Value> rest_vals;
      Env.Cache cache;
      Env.Env env;
      DAE.Var var;
      DAE.Exp binding_exp;
    
    case (_, _, {}, {}) then (inCache, inEnv);
    
    // For an input arguments we take the first value in the list of input
    // values, and assigns the value to the variable that we create.
    case (_, env, (e as DAE.VAR(direction = DAE.INPUT())) :: el, val :: rest_vals)
      equation
        (cache, env) = extendEnvWithElement(e, SOME(val), inCache, env);
        (cache, env) = extendEnvWithFunctionVars(inCache, env, el, rest_vals);
      then
        (cache, env);
    
    // Non-input arguments might have a default binding, so we use that if it's
    // available.
    case (_, env, (e as DAE.VAR(direction = _, binding = SOME(binding_exp))) :: el, _)
      equation
        (cache, val) = cevalExp(binding_exp, inCache, inEnv);
        (cache, env) = extendEnvWithElement(e, SOME(val), cache, env);
        (cache, env) = extendEnvWithFunctionVars(cache, env, el, inFuncArgs);
      then
        (cache, env);
    
    // Otherwise, just add the variable to the environment.
    case (_, env, (e as DAE.VAR(direction = _)) :: el, _)
      equation
        (cache, env) = extendEnvWithElement(e, NONE(), inCache, env);
        (cache, env) = extendEnvWithFunctionVars(inCache, env, el, inFuncArgs);
      then
        (cache, env);
    
    case (_, env, e :: _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("- CevalFunction.extendEnvWithFunctionVars failed for:");
        Debug.traceln(DAEDump.dumpElementsStr({e}));
      then
        fail();
  end matchcontinue;
end extendEnvWithFunctionVars;

protected function extendEnvWithElement
  "This function extracts the necessary data from a variable element, and calls
  extendEnvWithVar to add a new variable to the environment."
  input DAE.Element inElement;
  input Option<Values.Value> inBindingValue;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := match(inElement, inBindingValue, inCache, inEnv)
    local
      DAE.ComponentRef cr;
      String name;
      DAE.Type ty;
      DAE.InstDims dims;
      Env.Cache cache;
      Env.Env env;
    case (DAE.VAR(componentRef = cr, ty = ty, dims = dims), _, _, _)
      equation
        name = ComponentReference.crefStr(cr);
        (cache, env) = extendEnvWithVar(name, ty, inBindingValue, dims, inCache, inEnv);
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := 
  matchcontinue(inName, inType, inOptValue, inDims, inCache, inEnv)
    local
      DAE.Type ty;
      DAE.Var var;
      DAE.Binding binding;
      Env.Cache cache;
      Env.Env env, record_env;

    // Records are special, since they have their own environment with their
    // components in them. A record variable is thus always unbound, and their
    // values are instead determined by their components values.
    case (_, _, _, _, _, _)
      equation
        true = Types.isRecord(inType);
        (cache, ty) = appendDimensions(inType, inOptValue, inDims, inCache, inEnv);
        var = makeFunctionVariable(inName, ty, DAE.UNBOUND());
        (cache, record_env) = makeRecordEnvironment(inType, inOptValue, cache);
        env = Env.extendFrameV(inEnv, var, NONE(), Env.VAR_TYPED(), record_env);
      then
        (cache, env);

    // Normal variables.
    else
      equation
        binding = getBinding(inOptValue);
        (cache, ty) = appendDimensions(inType, inOptValue, inDims, inCache, inEnv);
        var = makeFunctionVariable(inName, ty, binding);
        env = Env.extendFrameV(inEnv, var, NONE(), Env.VAR_TYPED(), {});
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
algorithm
  outVar := DAE.TYPES_VAR(
    inName,
    DAE.ATTR(false, false, SCode.RW(), SCode.VAR(), Absyn.BIDIR(), Absyn.UNSPECIFIED()),
    false, inType, inBinding, NONE());
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
  input Env.Cache inCache;
  output Env.Cache outCache;
  output Env.Env outRecordEnv;
algorithm
  (outCache, outRecordEnv) := match(inRecordType, inOptValue, inCache)
    local
      list<DAE.Var> var_lst;
      list<Option<Values.Value>> vals;
      Env.Cache cache;
      Env.Env env;
    case ((DAE.T_COMPLEX(
        complexClassType = ClassInf.RECORD(path = _),
        complexVarLst = var_lst), _), _, _)
      equation
        env = Env.newEnvironment();
        vals = getRecordValues(inOptValue, inRecordType);
        ((cache, env)) = Util.listThreadFold(var_lst, vals,
          extendEnvWithRecordVar, (inCache, env));
      then
        (cache, env);
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
        opt_vals = Util.listMap(vals, Util.makeOption);
      then
        opt_vals;
    case (NONE(), (DAE.T_COMPLEX(complexVarLst = vars), _))
      equation
        n = listLength(vars);
        opt_vals = Util.listFill(NONE(), n);
      then
        opt_vals;
  end match;
end getRecordValues;

protected function extendEnvWithRecordVar
  "This function extends an environment with a record component."
  input DAE.Var inVar;
  input Option<Values.Value> inOptValue;
  input tuple<Env.Cache, Env.Env> inEnv;
  output tuple<Env.Cache, Env.Env> outEnv;
algorithm
  outEnv := match(inVar, inOptValue, inEnv)
    local
      String name;
      DAE.Type ty;
      Env.Cache cache;
      Env.Env env;
    case (DAE.TYPES_VAR(name = name, type_ = ty), _, (cache, env))
      equation
        (cache, env) = extendEnvWithVar(name, ty, inOptValue, {}, cache, env);
        outEnv = (cache,env);
      then outEnv;
  end match;
end extendEnvWithRecordVar;

protected function extendEnvWithForScope
  "This function opens a new for loop scope in the environment by opening a new
  scope and adding the given iterator to it. For convenience it also returns the
  type and component reference of the iterator."
  input String inIterName;
  input DAE.ExpType inIterType;
  input Env.Env inEnv;
  output Env.Env outEnv;
  output DAE.Type outIterType;
  output DAE.ComponentRef outIterCref;
protected
  DAE.ComponentRef iter_cr;
algorithm
  outIterType := Types.expTypetoTypesType(inIterType);
  outEnv := Env.extendFrameForIterator(inEnv, inIterName, outIterType,
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output DAE.Type outType;
protected
  list<Integer> binding_dims;
algorithm
  binding_dims := ValuesUtil.valueDimensions(
    Util.getOptionOrDefault(inOptBinding, Values.INTEGER(0)));
  (outCache, outType) := appendDimensions2(inType, inDims, binding_dims, inCache, inEnv);
end appendDimensions;
        
protected function appendDimensions2
  "Helper function to appendDimensions. Appends dimensions to a type. inDims is
  the declared dimensions of the variable while inBindingDims is the dimensions
  of the variables binding (empty list if it doesn't have a binding)."
  input DAE.Type inType;
  input DAE.InstDims inDims;
  input list<Integer> inBindingDims;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
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
      Env.Cache cache;
    
    case (ty, {}, _, _, _) then (inCache, ty);
    
    // Use the given dimension if the dimension has been declared. The list of
    // dimensions might be empty in this case, so listRestOrEmpty is used
    // instead of matching.
    case (ty, DAE.INDEX(exp = dim_exp) :: rest_dims, bind_dims, _, _)
      equation
        (cache, dim_val) = cevalExp(dim_exp, inCache, inEnv);
        dim_int = ValuesUtil.valueInteger(dim_val);
        dim = Expression.intDimension(dim_int);
        bind_dims = Util.listRestOrEmpty(bind_dims);
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, (DAE.T_ARRAY(dim, ty), NONE()));
    
    // Otherwise, take the dimension from the binding.
    case (ty, DAE.WHOLEDIM() :: rest_dims, dim_int :: bind_dims, _, _)
      equation
        dim = Expression.intDimension(dim_int);
        (cache, ty) = appendDimensions2(ty, rest_dims, bind_dims, inCache, inEnv);
      then
        (cache, (DAE.T_ARRAY(dim, ty), NONE()));
    
    case (_, sub :: _, _, _, _)
      equation
        Debug.fprintln("failtrace", "- CevalFunction.appendDimensions2 failed");
      then
        fail();
  end matchcontinue;
end appendDimensions2;

// [MENV]  Environment manipulation functions (set and get variables).

protected function assignVariable
  "This function assigns a variable in the environment a new value."
  input DAE.ComponentRef inVariableCref;
  input Values.Value inNewValue;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := matchcontinue(inVariableCref, inNewValue, inCache, inEnv)
    local
      DAE.ComponentRef cr, cr_rest;
      Env.Cache cache;
      Env.Env env;
      list<DAE.Subscript> subs;
      DAE.Type ty;
      DAE.ExpType ety;
      DAE.Binding binding;
      Values.Value val;
      DAE.Var var;
      Env.InstStatus inst_status;
      String id;

    // A record assignment.
    case (cr as DAE.CREF_IDENT(ident = id, subscriptLst = {}, identType = ety as
        DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _))), _, _, _)
      equation
        (_, var, _, inst_status, env) =
          Lookup.lookupIdentLocal(inCache, inEnv, id);
        (cache, env) = assignRecord(ety, inNewValue, inCache, env);
        env = Env.updateFrameV(inEnv, var, inst_status, env);
      then
        (cache, env);

    // If we get a scalar we just update the value.
    case (cr as DAE.CREF_IDENT(subscriptLst = {}), _, _, _)
      equation
        (ty, _) = getVariableTypeAndBinding(cr, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, inNewValue);
      then
        (inCache, env);

    // If we get a vector we first get the old value and update the relevant
    // part of it, and then update the variables value.
    case (cr as DAE.CREF_IDENT(subscriptLst = subs), _, _, _)
      equation
        cr = ComponentReference.crefStripSubs(cr);
        (ty, val) = getVariableTypeAndValue(cr, inEnv); 
        (cache, val) = assignVector(inNewValue, val, subs, inCache, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        (cache, env);

    // A qualified component reference is a record component, so first lookup
    // the records environment, and then assign the variable in that environment.
    case (cr as DAE.CREF_QUAL(ident = id, subscriptLst = {},
        componentRef = cr_rest), _, _, _)
      equation
        (_, var, _, inst_status, env) =
          Lookup.lookupIdentLocal(inCache, inEnv, id);
        (cache, env) = assignVariable(cr_rest, inNewValue, inCache, env);
        env = Env.updateFrameV(inEnv, var, inst_status, env);
      then
        (cache, env);
  end matchcontinue;
end assignVariable;

protected function assignTuple
  "This function assign a tuple by calling assignVariable for each tuple
  component."
  input list<DAE.ComponentRef> inLhsCrefs;
  input list<Values.Value> inRhsValues;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := match(inLhsCrefs, inRhsValues, inCache, inEnv)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest_crefs;
      Values.Value value;
      list<Values.Value> rest_vals;
      Env.Cache cache;
      Env.Env env;
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
  input DAE.ExpType inType;
  input Values.Value inValue;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := match(inType, inValue, inCache, inEnv)
    local
      list<Values.Value> values;
      list<DAE.ExpVar> vars;
      Env.Cache cache;
      Env.Env env;
    case (DAE.ET_COMPLEX(varLst = vars), Values.RECORD(orderd = values), _, _)
      equation
        (cache, env) = assignRecordComponents(vars, values, inCache, inEnv);
      then
        (cache, env);
  end match;
end assignRecord;

protected function assignRecordComponents
  input list<DAE.ExpVar> inVars;
  input list<Values.Value> inValues;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output Env.Env outEnv;
algorithm
  (outCache, outEnv) := match(inVars, inValues, inCache, inEnv)
    local
      list<DAE.ExpVar> rest_vars;
      Values.Value val;
      list<Values.Value> rest_vals;
      String name;
      DAE.ComponentRef cr;
      DAE.ExpType ety;
      Env.Cache cache;
      Env.Env env;
    case (DAE.COMPLEX_VAR(name = name, tp = ety) :: rest_vars,
          val :: rest_vals, _ , _)
      equation
        cr = ComponentReference.makeCrefIdent(name, ety, {});
        (cache, env) = assignVariable(cr, val, inCache, inEnv);
        (cache, env) = assignRecordComponents(rest_vars, rest_vals, cache, env);
      then
        (cache, env);
  end match;
end assignRecordComponents;
  
protected function assignVector
  "This function assigns a part of a vector by replacing the parts indicated by
  the subscripts in the old value with the new value."
  input Values.Value inNewValue;
  input Values.Value inOldValue;
  input list<DAE.Subscript> inSubscripts;
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
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
      Env.Cache cache;

    // No subscripts, we have either reached the end of the recursion or the
    // whole vector was assigned.
    case (_, _, {}, _, _) then (inCache, inNewValue);

    // An index subscript. Extract the indicated vector element and update it
    // with assignVector, and then put it back in the list of old values.
    case (_, Values.ARRAY(valueLst = values, dimLst = dims), 
        DAE.INDEX(exp = e) :: rest_subs, _, _)
      equation
        (cache, index) = cevalExp(e, inCache, inEnv);
        i = ValuesUtil.valueInteger(index) - 1;
        val = listNth(values, i);
        (cache, val) = assignVector(inNewValue, val, rest_subs, cache, inEnv);
        values = Util.listReplaceAt(val, i, values);
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
        (old_values, old_values2) = Util.listSplit(old_values, i - 1);
        // Update the rest of the old value with assignSlice.
        (cache, values2) = 
          assignSlice(values, old_values2, indices, rest_subs, i, cache, inEnv);
        // Assemble the list of values again.
        values = listAppend(old_values, values2);
      then
        (cache, Values.ARRAY(values, dims));

    // A : (whole dimension).
    case (Values.ARRAY(valueLst = values), 
          Values.ARRAY(valueLst = values2, dimLst = dims),
        DAE.WHOLEDIM() :: rest_subs, _, _)
      equation
        (cache, values) = assignWholeDim(values, values2, rest_subs, inCache, inEnv);
      then
        (cache, Values.ARRAY(values, dims));

    case (_, _, sub :: _, _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        print("- CevalFunction.assignVector failed on: ");
        print(ExpressionDump.printSubscriptStr(sub) +& "\n");
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<Values.Value> outResult;
algorithm
  (outCache, outResult) := 
  matchcontinue(inNewValues, inOldValues, inIndices, inSubscripts, inIndex,
      inCache, inEnv)
    local
      Values.Value v1, v2, index;
      list<Values.Value> vl1, vl2, rest_indices;
      Env.Cache cache;

    case (_, _, {}, _, _, _, _) then (inCache, inOldValues);

    // Skip indices that are smaller than the next index in the slice.
    case (vl1, v2 :: vl2, index :: rest_indices, _, _, _, _)
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  output Env.Cache outCache;
  output list<Values.Value> outResult;
algorithm
  (outCache, outResult) := 
  match(inNewValues, inOldValues, inSubscripts, inCache, inEnv)
    local
      Values.Value v1, v2;
      list<Values.Value> vl1, vl2;
      Env.Cache cache;
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
  input Env.Env inEnv;
  input DAE.Type inType;
  input Values.Value inNewValue;
  output Env.Env outEnv;
protected
  String var_name;
  DAE.Var var;
algorithm
  var_name := ComponentReference.crefStr(inVariableCref);
  var := makeFunctionVariable(var_name, inType, 
    DAE.VALBOUND(inNewValue, DAE.BINDING_FROM_DEFAULT_VALUE()));
  outEnv := Env.updateFrameV(inEnv, var, Env.VAR_TYPED(), {});
end updateVariableBinding;

protected function getVariableTypeAndBinding
  "This function looks a variable up in the environment, and returns it's type
  and binding."
  input DAE.ComponentRef inCref;
  input Env.Env inEnv;
  output DAE.Type outType;
  output DAE.Binding outBinding;
algorithm
  (_, _, outType, outBinding, _, _, _, _, _) := 
    Lookup.lookupVar(Env.emptyCache(), inEnv, inCref);
end getVariableTypeAndBinding;

protected function getVariableTypeAndValue
  "This function looks a variable up in the environment, and returns it's type
  and value. If it doesn't have a value, then a default value will be returned."
  input DAE.ComponentRef inCref;
  input Env.Env inEnv;
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
    else then generateDefaultBinding(inType);
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
      Absyn.Path p;
      list<DAE.Var> vars;
      list<String> names;
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
     
protected function getFunctionReturnValue
  "This function fetches one return value for the function, given an output
  variable and an environment."
  input DAE.Element inOutputVar;
  input Env.Env inEnv;
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
  input Env.Env inEnv;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue(inCref, inType, inEnv)
    local
      Values.Value val;
      Absyn.Path p;

    // A record doesn't have a value, but an environment with it's components.
    // So we need to assemble the records value.
    case (_, (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = _)), _), _)
      equation
        p = ComponentReference.crefToPath(inCref);
        val = getRecordValue(p, inType, inEnv);
      then
        val;

    // All other variables we can just look up in the environment.
    case (_, _, _)
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
  input Env.Env inEnv;
  output Values.Value outValue;
algorithm
  outValue := match(inRecordName, inType, inEnv)
    local
      list<DAE.Var> vars;
      list<Values.Value> vals;
      list<String> var_names;
      String id;
      Absyn.Path p;
      Env.Env env;
    case (Absyn.IDENT(name = id), 
          (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = p),
                         complexVarLst = vars), _), _)
      equation
        (_, _, _, _, env) =
          Lookup.lookupIdentLocal(Env.emptyCache(), inEnv, id);
        vals = Util.listMap1(vars, getRecordComponentValue, env);
        var_names = Util.listMap(vars, Types.getVarName);
      then
        Values.RECORD(p, vals, var_names, -1);
  end match;
end getRecordValue;
  
protected function getRecordComponentValue
  "Looks up the value for a record component."
  input DAE.Var inVars;
  input Env.Env inEnv;
  output Values.Value outValues;
algorithm
  outValues := match(inVars, inEnv)
    local
      Values.Value val;
      String id;
      DAE.Type ty;

    // The component is a record itself.
    case (DAE.TYPES_VAR(
        name = id, 
        type_ = ty as (DAE.T_COMPLEX(
          complexClassType = ClassInf.RECORD(path = _)), _)), _)
      equation
        val = getRecordValue(Absyn.IDENT(id), ty, inEnv);
      then
        val;

    // A non-record variable.
    case (DAE.TYPES_VAR(name = id), _)
      equation
        (_, DAE.TYPES_VAR(binding = DAE.VALBOUND(valBound = val)), _, _, _) =
          Lookup.lookupIdentLocal(Env.emptyCache(), inEnv, id);
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
  outValue := matchcontinue(inReturnValues)
    local
      Values.Value val;
    
    case ({}) then Values.NORETCALL();
    case ({val}) then val;
    case (_ :: _) then Values.TUPLE(inReturnValues);
  end matchcontinue;
end boxReturnValue;

// [DEPS]  Function variable dependency handling.

protected function sortFunctionVarsByDependency
  "A functions variables might depend on each other, for example by defining
  dimensions that depend on the size of another variable. This function sorts
  the list of variables so that any dependencies to a variable will be before
  the variable in resulting list."
  input list<DAE.Element> inFuncVars;
  output list<DAE.Element> outFuncVars;
protected
  list<Dependency> dependencies;
algorithm
  // Build a dependency list that shows which variable depends on which. Using a
  // list for this is not the most efficient way to do it, but if this becomes
  // an issue then someone uses more function variables than is sane.
  dependencies := Util.listMap(inFuncVars, buildDependencyList);
  // Use the dependency list to sort the variables.
  outFuncVars := sortFunctionVarsByDependency2(inFuncVars, dependencies);
end sortFunctionVarsByDependency;

protected function sortFunctionVarsByDependency2
  "Helper function to sortFunctionVarsByDependency. Sorts a list of variables
  given a list of dependencies."
  input list<DAE.Element> inFuncVars;
  input list<Dependency> inDependencies;
  output list<DAE.Element> outFuncVars;
algorithm
  outFuncVars := match(inFuncVars, inDependencies)
    local
      DAE.Element elem;
      DAE.ComponentRef cref;
      list<DAE.Element> rest_elems, dep_elems;
      list<DAE.ComponentRef> deps;
    
    case ({}, _) then {};
    
    case ((elem as DAE.VAR(componentRef = cref)) :: rest_elems, _)
      equation
        // Look up which variables this variable depends on.
        deps = findDependencies(cref, inDependencies);
        // Split the rest of the variables based on if this variable depends on
        // them or not.
        (dep_elems, rest_elems) = extractDependencies(deps, rest_elems);
        // Sort the dependencies.
        dep_elems = sortFunctionVarsByDependency2(dep_elems, inDependencies); 
        // Sort the non-dependencies.
        rest_elems = sortFunctionVarsByDependency2(rest_elems, inDependencies);
        // Assemble the variable list with dependencies before this variable,
        // and all other variables after.
        rest_elems = elem :: rest_elems;
        rest_elems = listAppend(dep_elems, rest_elems);
      then
        rest_elems;
  end match;
end sortFunctionVarsByDependency2;

protected function extractDependencies
  "Given a list of dependencies this function splits a list of variables into
  variables that are dependencies and variable that are not."
  input list<DAE.ComponentRef> inDependencies;
  input list<DAE.Element> inFuncVars;
  output list<DAE.Element> outDepVars;
  output list<DAE.Element> outRestVars;
algorithm
  (outDepVars, outRestVars) := match(inDependencies, inFuncVars)
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
  end match;
end extractDependencies;
        
protected function extractDependency
  "Helper function to extractDependencies. Tries to find a certain variable in
  the list of variables, and if found it returns ({found variable}, {rest of
  variables}), otherwise ({}, {all variables})."
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

    // No variable found.
    case (_, {}) then ({}, {});

    // A match was found.
    case (_, (e as DAE.VAR(componentRef = cr)) :: el)
      equation
        true = ComponentReference.crefEqualNoStringCompare(inCref, cr);
      then
        ({e}, el);

    // No match, keep searching.
    case (_, e :: el)
      equation
        (el, el2) = extractDependency(inCref, el);
      then
        (el, e :: el2);
  end matchcontinue;
end extractDependency;

protected function findDependencies
  "Find the dependencies of a variable in a list of dependencies. This function
  is recursive, so it will also find the dependencies of the dependencies, and
  so on."
  input DAE.ComponentRef inCref;
  input list<Dependency> inDependencies;
  output list<DAE.ComponentRef> outDependencies;
protected
  list<DAE.ComponentRef> deps;
  list<list<DAE.ComponentRef>> dep_deps;
algorithm
  deps := findDependency(inCref, inDependencies);
  dep_deps := Util.listMap1(deps, findDependencies, inDependencies);
  outDependencies := listAppend(Util.listFlatten(dep_deps), deps);
end findDependencies;

protected function findDependency
  "Helper function to findDependencies. Finds the correct entry for the variable
  in the list of dependencies, and returns the list of variables that the
  variable directly depends on."
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
  "A constructor for the Depedency type."
  input DAE.Element inVar;
  input list<DAE.ComponentRef> inDependencies;
  output Dependency outDependency;
algorithm
  outDependency := match(inVar, inDependencies)
    local
      DAE.ComponentRef cr;
    case (DAE.VAR(componentRef = cr), _) then ((cr, inDependencies));
  end match;
end createDependency;

protected function buildDependencyList
  "This function build dependency information about a variable, i.e. which
  variables a certain variable directly depends on."
  input DAE.Element inVar;
  output Dependency outDependencies;
algorithm
  outDependencies := match(inVar)
    local
      DAE.Exp bind_exp;
      DAE.InstDims dims;
      list<DAE.ComponentRef> cl, cl2;
      list<list<DAE.ComponentRef>> subs_crefs;

    // A variable with a binding. Both the variables dimensions and binding
    // might contain dependencies.
    case DAE.VAR(binding = SOME(bind_exp), dims = dims)
      equation
        cl = Expression.extractCrefsFromExp(bind_exp);
        subs_crefs = Util.listMap(dims, extractCrefsFromSubscript);
        cl2 = Util.listFlatten(subs_crefs);
        cl = listAppend(cl, cl2);
      then
        createDependency(inVar, cl);

    // A variable without a binding. Only the variables dimensions might contain
    // dependencies.
    case DAE.VAR(binding = NONE(), dims = dims)
      equation
        subs_crefs = Util.listMap(dims, extractCrefsFromSubscript);
        cl = Util.listFlatten(subs_crefs);
      then
        createDependency(inVar, cl);
  end match;
end buildDependencyList;

protected function extractCrefsFromSubscript
  "Extracts all component references from a subscript."
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

// [EOPT]  Expression optimization functions.

protected function optimizeExp
  "This function optimizes expressions in a function. So far this is only used
  to transform ASUB expressions to CREFs so that this doesn't need to be done
  while evaluating the function. But it's possible that more forms of
  optimization can be done too."
  input tuple<DAE.Exp, Env.Env> inTuple;
  output tuple<DAE.Exp, Env.Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.Exp e;
      Env.Env env;
    case ((e, env))
      equation
        ((e, env)) = Expression.traverseExp(e, optimizeExpTraverser, env);
      then
        ((e, env));
  end match;
end optimizeExp;

protected function optimizeExpTraverser
  input tuple<DAE.Exp, Env.Env> inTuple;
  output tuple<DAE.Exp, Env.Env> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.ComponentRef cref;
      DAE.ExpType ety;
      list<DAE.Exp> sub_exps;
      list<DAE.Subscript> subs;
      Env.Env env;
      DAE.Exp exp;
      
    case ((DAE.ASUB(exp = DAE.CREF(componentRef = cref, ty = ety), sub = sub_exps), env))
      equation
        subs = Util.listMap(sub_exps, Expression.makeIndexSubscript);
        cref = ComponentReference.subscriptCref(cref, subs);
        exp = Expression.makeCrefExp(cref, ety); 
      then
        ((exp, env));
    else then inTuple;
  end match;
end optimizeExpTraverser;

end CevalFunction;
