/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
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
encapsulated uniontype NBReplacements
"file:        NBReplacements.mo
 package:     NBReplacements
 description:
  Replacements consists of a mapping between variables and expressions, the first binary tree of this type.
  To eliminate a variable from an equation system a replacement rule varname->expression is added to this
  datatype.
  To be able to update these replacement rules incrementally a backward lookup mechanism is also required.
  For instance, having a rule a->b and adding a rule b->c requires to find the first rule a->b and update it to
  a->c. This is what the second binary tree is used for.
"

protected
  // rename self import
  import Replacements = NBReplacements;

  // NF imports
  import Binding = NFBinding;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTreeImpl;
  import SimplifyExp = NFSimplifyExp;
  import Variable = NFVariable;

  // Backend imports
  import BVariable = NBVariable;
  import NBEquation.{EqData, Equation, EquationPointers};
  import Solve = NBSolve;
  import StrongComponent = NBStrongComponent;
  import NBVariable.{VarData, VariablePointers};

public

  function single
    "performs a single replacement"
    input output Expression exp   "Replacement happens inside this expression";
    input Expression old          "Replaced by new";
    input Expression new          "Replaces old";
  protected
    function traverse
      input output Expression exp;
      input Expression old;
      input Expression new;
    algorithm
      exp := if Expression.isEqual(exp, old) then new else exp;
    end traverse;
  algorithm
    exp := Expression.map(exp, function traverse(old = old, new = new));
  end single;

  function simple
    "creates simple replacement rules for removeSimpleEquations"
    input list<StrongComponent> comps;
    input UnorderedMap<ComponentRef, Expression> replacements;
  algorithm
    for comp in comps loop
      addSimple(comp, replacements);
    end for;
  end simple;

  function addSimple
    "ToDo: More cases!"
    input StrongComponent comp;
    input UnorderedMap<ComponentRef, Expression> replacements;
  algorithm
    _ := match comp
      local
        ComponentRef varName;
        Equation solvedEq;
        Solve.Status status;
        Expression replace_exp;

      case StrongComponent.SINGLE_EQUATION() algorithm
        // solve the equation for the variable
        varName := BVariable.getVarName(comp.var);
        (solvedEq, _, status, _) := Solve.solveEquation(Pointer.access(comp.eqn), varName, FunctionTreeImpl.EMPTY());
        if status == NBSolve.Status.EXPLICIT then
          // apply all previous replacements on the RHS
          replace_exp := Equation.getRHS(solvedEq);
          replace_exp := Expression.map(replace_exp, function applySimpleExp(replacements = replacements));
          // add the new replacement rule
          UnorderedMap.add(varName, SimplifyExp.simplify(replace_exp), replacements);
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong component cannot be solved explicitely: " + StrongComponent.toString(comp)});
          fail();
        end if;
      then replacements;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong component is not simple: " + StrongComponent.toString(comp)});
      then fail();
    end match;
  end addSimple;

  function applySimple
    "Used for RemoveSimpleEquations.
    This should be applied before partitioning. Otherwise all systems have to be checked for jacobians
    and hessians on which this also has to be applied. Can be applied on single jacobians and hessians
    while removing simple equations on them."
    input output EqData eqData;
    input output VarData varData; // bindings
    input UnorderedMap<ComponentRef, Expression> replacements "rules for replacements are stored inside here";
  protected
    list<tuple<ComponentRef, Expression>> entries;
    ComponentRef aliasCref;
    Expression replacement;
    Pointer<Variable> var_ptr;
    Variable var;
  algorithm
    // do nothing if replacements are empty
    if UnorderedMap.isEmpty(replacements) then return; end if;

    eqData := match eqData
      case EqData.EQ_DATA_SIM() algorithm
        // we do not want to traverse removed equations, otherwise we could break them
        eqData.simulation   := EquationPointers.mapExp(eqData.simulation, function applySimpleExp(replacements = replacements));
        eqData.continuous   := EquationPointers.mapExp(eqData.continuous, function applySimpleExp(replacements = replacements));
        eqData.discretes    := EquationPointers.mapExp(eqData.discretes, function applySimpleExp(replacements = replacements));
        eqData.initials     := EquationPointers.mapExp(eqData.initials, function applySimpleExp(replacements = replacements));
        eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, function applySimpleExp(replacements = replacements));
      then eqData;

      case EqData.EQ_DATA_JAC() algorithm
        eqData.results      := EquationPointers.mapExp(eqData.results, function applySimpleExp(replacements = replacements));
        eqData.temporary    := EquationPointers.mapExp(eqData.temporary, function applySimpleExp(replacements = replacements));
        eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, function applySimpleExp(replacements = replacements));
      then eqData;

      case EqData.EQ_DATA_HES() algorithm
        Pointer.update(eqData.result, Equation.map(Pointer.access(eqData.result), function applySimpleExp(replacements = replacements)));
        eqData.temporary    := EquationPointers.mapExp(eqData.temporary, function applySimpleExp(replacements = replacements));
        eqData.auxiliaries  := EquationPointers.mapExp(eqData.auxiliaries, function applySimpleExp(replacements = replacements));
      then eqData;
    end match;

    // apply on bindings (is this necessary?)
    varData := match varData
      case VarData.VAR_DATA_SIM() algorithm
        varData.variables := VariablePointers.map(varData.variables, function applySimpleVar(replacements = replacements));
        varData.aliasVars := VariablePointers.map(varData.aliasVars, function applySimpleVar(replacements = replacements));
      then varData;
      case VarData.VAR_DATA_JAC() algorithm
        varData.variables := VariablePointers.map(varData.variables, function applySimpleVar(replacements = replacements));
      then varData;
      case VarData.VAR_DATA_HES() algorithm
        varData.variables := VariablePointers.map(varData.variables, function applySimpleVar(replacements = replacements));
      then varData;
    end match;

    // update alias variable bindings
    entries := UnorderedMap.toList(replacements);
    for entry in entries loop
      (aliasCref, replacement) := entry;
      var_ptr := BVariable.getVarPointer(aliasCref);
      var := Pointer.access(var_ptr);
      var.binding := Binding.update(var.binding, replacement);
      Pointer.update(var_ptr, var);
    end for;
  end applySimple;

  function applySimpleExp
    "Needs to be mapped with Expression.map()"
    input output Expression exp                               "Replacement happens inside this expression";
    input UnorderedMap<ComponentRef, Expression> replacements "rules for replacements are stored inside here";
  algorithm
    exp := match exp
      case Expression.CREF() guard(UnorderedMap.contains(exp.cref, replacements))
      then UnorderedMap.getSafe(exp.cref, replacements);
      else exp;
    end match;
  end applySimpleExp;

  function applySimpleVar
    "applys replacement on the variable binding expression"
    input output Variable var;
    input UnorderedMap<ComponentRef, Expression> replacements "rules for replacements are stored inside here";
  algorithm
    var := match var
      local
        Binding binding;
      case Variable.VARIABLE(binding = binding as Binding.TYPED_BINDING()) algorithm
        binding.bindingExp := Expression.map(binding.bindingExp, function applySimpleExp(replacements = replacements));
        var.binding := binding;
      then var;
      else var;
    end match;
  end applySimpleVar;

  function simpleToString
    input UnorderedMap<ComponentRef, Expression> replacements;
    output String str = "";
  protected
    list<tuple<ComponentRef, Expression>> entries;
    String constStr="", aliasStr="", nonTrivialStr="";
    ComponentRef key;
    Expression value;
  algorithm
    entries := UnorderedMap.toList(replacements);
    for entry in entries loop
      (key, value) := entry;
      if Expression.isConstNumber(value) then
        // constant alias
        constStr := constStr + "\t" + ComponentRef.toString(key) + "\t ==> \t" + Expression.toString(value) + "\n";
      elseif (not (Expression.isCref(value) or Expression.isCref(Expression.negate(value)))) and BVariable.checkExpMap(value, BVariable.isTimeDependent) then
        // non trivial alias
        nonTrivialStr := nonTrivialStr + "\t" + ComponentRef.toString(key) + "\t ==> \t" + Expression.toString(value) + "\n";
      else
        // trivial alias
        aliasStr := aliasStr + "\t" + ComponentRef.toString(key) + "\t ==> \t" + Expression.toString(value) + "\n";
      end if;
    end for;
    str := str + StringUtil.headline_4("[dumprepl] Constant Replacements:") + constStr;
    str := str + StringUtil.headline_4("[dumprepl] Trivial Alias Replacements:") + aliasStr;
    str := str + StringUtil.headline_4("[dumprepl] Nontrivial Alias Replacements:") + nonTrivialStr;
  end simpleToString;

  annotation(__OpenModelica_Interface="backend");
end NBReplacements;
