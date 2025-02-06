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

  // OF imports
  import Absyn;

  // NF imports
  import Binding = NFBinding;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import NFFunction.Function;
  import NFFlatten.FunctionTreeImpl;
  import SimplifyExp = NFSimplifyExp;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import BVariable = NBVariable;
  import NBEquation.{EqData, Equation, EquationPointers};
  import Inline = NBInline;
  import Solve = NBSolve;
  import StrongComponent = NBStrongComponent;
  import NBVariable.{VarData, VariablePointers};

  // Util
  import StringUtil;

public
// =========================================================================
//                     COMPONENT REFERENCE REPLACEMENT
// =========================================================================

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
    "creates simple replacement rules for alias removal"
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
    () := match comp
      local
        ComponentRef varName;
        Equation solvedEq;
        Solve.Status status;
        Expression replace_exp;

      case StrongComponent.SINGLE_COMPONENT() algorithm
        // solve the equation for the variable
        varName := BVariable.getVarName(comp.var);
        (solvedEq, _, status, _) := Solve.solveBody(Pointer.access(comp.eqn), varName, FunctionTreeImpl.EMPTY());
        if status == NBSolve.Status.EXPLICIT then
          // apply all previous replacements on the RHS
          replace_exp := Equation.getRHS(solvedEq);
          replace_exp := Expression.map(replace_exp, function applySimpleExp(replacements = replacements));
          // add the new replacement rule
          UnorderedMap.add(varName, SimplifyExp.simplifyDump(replace_exp, true, getInstanceName()), replacements);
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong component cannot be solved explicitly: " + StrongComponent.toString(comp)});
          fail();
        end if;
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong component is not simple: " + StrongComponent.toString(comp)});
      then fail();
    end match;
  end addSimple;

  function applySimple
    "Used for alias removal.
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
    eqData := EqData.mapExp(eqData, function applySimpleExp(replacements = replacements));

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
      local
        Expression res;
        ComponentRef stripped;
        list<Subscript> subs;

      case Expression.CREF() algorithm
        if UnorderedMap.contains(exp.cref, replacements) then
          // the cref (with subscripts) is found in replacements
          res := UnorderedMap.getOrFail(exp.cref, replacements);
        else
          // try to strip the subscripts and see if that cref occurs
          stripped := ComponentRef.stripSubscriptsAll(exp.cref);
          if UnorderedMap.contains(stripped, replacements) then
            subs  := ComponentRef.subscriptsAllFlat(exp.cref);
            subs  := list(s for s guard(not Subscript.isWhole(s)) in subs);
            res   := UnorderedMap.getOrFail(stripped, replacements);
            res   := Expression.applySubscripts(subs, res, true);
          else
            // do nothing
            res := exp;
          end if;
        end if;
      then res;
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
      elseif not Expression.isTrivialCref(value) then
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

// =========================================================================
//                     FUNCTION BODY REPLACEMENT
// =========================================================================

  function replaceFunctions
    "replaces all function calls in the replacements map with their body expressions,
    if possible."
    input output EqData eqData;
    input VariablePointers variables;
    input UnorderedMap<Absyn.Path, Function> replacements;
  algorithm
        // do nothing if replacements are empty
    if UnorderedMap.isEmpty(replacements) then return; end if;
    eqData := EqData.mapExp(eqData, function applyFuncExp(replacements = replacements, variables = variables));
  end replaceFunctions;

  function applyFuncExp
    "Needs to be mapped with Expression.map()"
    input output Expression exp                               "Replacement happens inside this expression";
    input UnorderedMap<Absyn.Path, Function> replacements     "rules for replacements are stored inside here";
    input VariablePointers variables;
  algorithm
    exp := match exp
      local
        Call call;
        Function fn;
        UnorderedMap<ComponentRef, Expression> local_replacements;
        list<ComponentRef> input_crefs;
        ComponentRef local_cref;
        Option<Expression> binding_exp_opt;
        Expression binding_exp, body_exp;

      case Expression.CALL(call = call as Call.TYPED_CALL(fn = fn)) guard(UnorderedMap.contains(fn.path, replacements)) algorithm
        // use the function from the tree, in case it was changed
        fn := UnorderedMap.getOrFail(fn.path, replacements);

        // map all the inputs to the arguments and add to local replacement map
        local_replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        input_crefs := list(ComponentRef.fromNode(node, InstNode.getType(node)) for node in fn.inputs);
        // ToDo: rather use the function slots for this?
        for tpl in List.zip(input_crefs, call.arguments) loop
          addInputArgTpl(tpl, local_replacements);
        end for;

        // add replacement rules for local (protected) variables
        for local_node in fn.locals loop
          local_cref    := ComponentRef.fromNode(local_node, InstNode.getType(local_node));
          binding_exp_opt := InstNode.getBindingExpOpt(local_node);
          if Util.isSome(binding_exp_opt) then
            // replace binding expression with already gathered input replacements
            binding_exp := Expression.map(Util.getOption(binding_exp_opt), function applySimpleExp(replacements = local_replacements));
          else
            // add a "wild" binding. This will result in unused outputs being ignored.
            binding_exp := Expression.CREF(Type.UNKNOWN(), ComponentRef.WILD());
          end if;
          addInputArgTpl((local_cref, binding_exp), local_replacements);
        end for;

        // get the expression from function body (fails if its not a single replacable assignment)
        body_exp := getFunctionBody(fn);
        // replace input withs arguments in expression
        body_exp := Expression.map(body_exp, function applySimpleExp(replacements = local_replacements));
        body_exp := SimplifyExp.combineBinaries(body_exp);
        body_exp := SimplifyExp.simplifyDump(body_exp, true, getInstanceName(), "\n");

        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("[" + getInstanceName() + "] Inlining: " + Expression.toString(exp) + "\n");
          print("-- Result: " + Expression.toString(body_exp) + "\n\n");
        end if;
      then body_exp;

      else exp;
    end match;
  end applyFuncExp;

  function addInputArgTpl
    "adds an input to argument replacement and also adds
    all record children replacements."
    input tuple<ComponentRef, Expression> tpl;
    input UnorderedMap<ComponentRef, Expression> replacements;
  protected
    ComponentRef cref;
    Expression arg;
    list<Expression> children_args;
    list<ComponentRef> children, tmp;
    Call call;
    Function fn;
  algorithm
    (cref, arg) := tpl;
    UnorderedMap.add(cref, arg, replacements);

    // also try to add element replacements (throw error if impossible?)
    children := ComponentRef.getRecordChildren(cref);
    if not listEmpty(children) then
      children_args := match arg

        // if the argument is a cref, get its children
        case Expression.CREF() algorithm
          tmp := BVariable.getRecordChildrenCref(arg.cref);
        then list(Expression.fromCref(child) for child in tmp);

        // if it is a basic record, take its elements
        case Expression.RECORD()  then arg.elements;
        case Expression.TUPLE()   then arg.elements;

        // if the argument is a record constructor, map it to its attributes
        case Expression.CALL(call = call as Call.TYPED_CALL(fn = fn)) algorithm
          if Function.isDefaultRecordConstructor(fn) then
            children_args := call.arguments;
          elseif Function.isNonDefaultRecordConstructor(fn) then
            // ToDo: this has to be mapped correctly with the body.
            //   for non default record constructors its not always the
            //   case that inputs map 1:1 to attributes
            children_args := call.arguments;
          else
            children_args := {};
          end if;
        then children_args;

        else {};
      end match;

      // check if children and children_args can be mapped to one another
      if List.compareLength(children, children_args) == 0 then
        for child_tpl in List.zip(children, children_args) loop
          addInputArgTpl(child_tpl, replacements);
        end for;
      end if;
    end if;
  end addInputArgTpl;

  function getFunctionBody
    "returns the rhs of the function body if its a single assignment, fails otherwise"
    input Function fn;
    output Expression exp;
  protected
    list<Statement> body;
  algorithm
    body := Function.getBody(fn);
    exp := match body
      local
        Statement stmt;

      case {stmt as Statement.ASSIGNMENT()} then stmt.rhs;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
          + " failed because the body of the function is not a single assignment:\n"
          + List.toString(body, function Statement.toString(indent = "\t"), "", "", "\n", "")});
      then fail();
    end match;
  end getFunctionBody;

  annotation(__OpenModelica_Interface="backend");
end NBReplacements;
