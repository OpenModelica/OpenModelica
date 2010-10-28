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
protected import Lookup;
protected import RTOpts;
protected import Types;
protected import Util;
protected import ValuesUtil;

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
        env = Util.listFold(sl, evaluateStatement, inEnv);
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

protected function evaluateStatement
  input DAE.Statement inStatement;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(inStatement, inEnv)
    local
      Env.Env env;
      DAE.Exp lhs, rhs;
      DAE.ComponentRef lhs_cref;
      Values.Value rhs_val;
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
    case (DAE.STMT_ASSIGN_ARR(type_ = _), _)
      equation
        print("STMT_ASSIGN_ARR\n");
      then
        fail();
    case (DAE.STMT_IF(exp = _), _)
      equation
        print("STMT_IF\n");
      then
        fail();
    case (DAE.STMT_FOR(type_ = _), _)
      equation
        print("STMT_FOR\n");
      then
        fail();
    case (DAE.STMT_WHILE(exp = _), _)
      equation
        print("STMT_WHILE\n");
      then
        fail();
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
  end matchcontinue;
end evaluateStatement;

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
        print("CONSTANT EVALUATE VAR DIMENSIONS AND USE THEM HERE!\n");
        var = elementToVar(e, SOME(val));
        env = Env.extendFrameV(env, var, NONE(), Env.VAR_TYPED(), {});
      then
        extendEnvWithFunctionVars(env, el, rest_vals);
    case (env, (e as DAE.VAR(direction = _, binding = SOME(binding_exp))) :: el, _)
      local
        DAE.Exp binding_exp;
      equation
        print("CONSTANT EVALUATE VAR DIMENSIONS AND USE THEM HERE!\n");
        val = cevalExp(binding_exp, inEnv);
        var = elementToVar(e, SOME(val));
        env = Env.extendFrameV(env, var, NONE(), Env.VAR_TYPED(), {});
      then
        extendEnvWithFunctionVars(env, el, inFuncArgs);
    case (env, (e as DAE.VAR(direction = _)) :: el, _)
      equation
        print("CONSTANT EVALUATE VAR DIMENSIONS AND USE THEM HERE!\n");
        var = elementToVar(e, NONE());
        env = Env.extendFrameV(env, var, NONE(), Env.VAR_TYPED(), {});
      then
        extendEnvWithFunctionVars(env, el, inFuncArgs);
    case (env, e :: el, _)
      then extendEnvWithFunctionVars(env, el, inFuncArgs);
  end matchcontinue;
end extendEnvWithFunctionVars;

protected function elementToVar 
  input DAE.Element inElement;
  input Option<Values.Value> inBindingValue;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue(inElement, inBindingValue)
    case (DAE.VAR(componentRef = cr, ty = ty), _)
      local
        DAE.ComponentRef cr;
        String var_name;
        DAE.Type ty;
        DAE.Binding binding;
      equation
        binding = getBinding(inBindingValue);
        var_name = ComponentReference.crefStr(cr);
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
          NONE);
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
        env = updateVariableBinding(cr, inEnv, (DAE.T_NOTYPE(), NONE()), val);
      then
        env;
    case (cr as DAE.CREF_IDENT(subscriptLst = subs), _, _)
      equation
        cr = ComponentReference.crefStripSubs(cr);
        (ty, DAE.VALBOUND(valBound = val)) =
          getVariableTypeAndBinding(cr, inEnv); 
        val = assignSlice(inNewValue, val, subs, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        env;
    case (cr as DAE.CREF_IDENT(subscriptLst = subs), _, _)
      equation
        cr = ComponentReference.crefStripSubs(cr);
        (ty, _) = getVariableTypeAndBinding(cr, inEnv);
        print(Env.printEnvStr(inEnv) +& "\n");
        print("Type: " +& Types.printTypeStr(ty) +& "\n");
        val = generateDefaultBinding(ty);
        val = assignSlice(inNewValue, val, subs, inEnv);
        env = updateVariableBinding(cr, inEnv, ty, val);
      then
        env;
  end matchcontinue;
end assignVariable;

protected function assignSlice
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
      list<Values.Value> values;
      list<Integer> dims;
      Integer i;
      list<DAE.Subscript> rest_subs;
    case (_, _, {}, _) then inNewValue;
    case (_, Values.ARRAY(valueLst = values, dimLst = dims), 
          DAE.INDEX(exp = e) :: rest_subs, _)
      equation
        index = cevalExp(e, inEnv);
        i = ValuesUtil.valueInteger(index) - 1;
        val = listNth(values, i);
        val = assignSlice(inNewValue, val, rest_subs, inEnv);
        values = Util.listReplaceAt(val, i, values);
      then
        Values.ARRAY(values, dims);
    case (_, _, _, _)
      equation
        Debug.fprintln("failtrace", "- CevalFunction.assignSlice failed!\n");
      then
        fail();
  end matchcontinue;
end assignSlice;

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
    case (DAE.CREF(componentRef = cref)) then cref;
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
        print("Array: " +& intString(int_dim) +& "\n");
      then
        Values.ARRAY(values, int_dim :: dims);
    case (_)
      equation
        Debug.fprintln("failtrace", "- CevalFunction.generateDefaultBinding failed\n");
      then
        fail();
  end matchcontinue;
end generateDefaultBinding;

end CevalFunction;
