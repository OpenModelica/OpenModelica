/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFStreamFlowAlias
" file:        NFStreamFlowAlias.mo
  package:     NFStreamFlowAlias
  description:

"
  import DisjointSets;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import DAE;
  import ElementSource;
  import Equation = NFEquation;
  import Expression = NFExpression;
  import FlatModel = NFFlatModel;
  import NFInstNode.InstNode;
  import NFPrefixes.Variability;
  import Operator = NFOperator;
  import Type = NFType;

protected
  import Binding = NFBinding;
  import Ceval = NFCeval;
  import Structural = NFStructural;
  import Variable = NFVariable;
  import MetaModelica.Dangerous.listReverseInPlace;

public

  extends DisjointSets(redeclare type Entry = FlowAlias);

  uniontype FlowAlias
    record FLOW_ALIAS
      ComponentRef name;
      Boolean negative;
      Option<Variable> variable;
    end FLOW_ALIAS;

    function isFlow
      input FlowAlias alias;
      output Boolean isFlow = Util.applyOptionOrDefault(alias.variable, Variable.isFlow, false);
    end isFlow;
  end FlowAlias;

  redeclare function extends EntryHash
  algorithm
    hash := ComponentRef.hash(entry.name);
  end EntryHash;

  redeclare function extends EntryEqual
  algorithm
    // Only compare the names, not the signs, since an alias and its negative
    // can't belong to different sets.
    isEqual := ComponentRef.isEqual(entry1.name, entry2.name);
  end EntryEqual;

  redeclare function extends EntryString
  algorithm
    str := ComponentRef.toString(entry.name);
    if entry.negative then
      str := "-" + str;
    end if;
  end EntryString;

  function eliminateAliases
    "Performs alias eliminiation for flow variables defined in stream connectors."
    input output FlatModel flatModel;
  protected
    Sets sets;
    UnorderedMap<ComponentRef, Expression> replacements;
    list<tuple<FlowAlias, list<FlowAlias>>> aliases;
  algorithm
    (flatModel, sets) := fromModel(flatModel);
    (flatModel, aliases) := createAliases(sets, flatModel);
    replacements := buildReplacements(aliases);
    flatModel := applyReplacements(replacements, flatModel);
  end eliminateAliases;

  function fromModel
    "Returns the alias sets and equations found in the given model,
     removing the alias equations from the model in the process."
    input output FlatModel flatModel;
    output Sets sets;
  protected
    list<Equation> alias_eqs, other_eqs;
    list<list<FlowAlias>> flow_aliases;
    list<Variable> vars = {};
    Option<FlowAlias> opt_alias;
    FlowAlias alias;
  algorithm
    sets := emptySets(0);

    // Find alias equations and add them to the alias sets.
    (alias_eqs, flow_aliases, other_eqs) := sortEquations(flatModel.equations);
    flatModel.equations := other_eqs;
    sets := List.threadFold(flow_aliases, alias_eqs, addAliasEquation, sets);

    // Find alias binding equations and add them to the alias sets.
    sets := List.fold(flatModel.variables, addAliasBinding, sets);

    // Update the aliases with which Variable they're associated with.
    for v in flatModel.variables loop
      alias := FlowAlias.FLOW_ALIAS(v.name, false, NONE());
      opt_alias := getEntry(alias, sets);

      if isSome(opt_alias) then
        SOME(alias) := opt_alias;
        alias.variable := SOME(v);
        UnorderedMap.updateKey(alias, sets.elements);
      else
        vars := v :: vars;
      end if;
    end for;

    // Sanity check, all aliases should have an associated Variable now.
    for alias in UnorderedMap.keyList(sets.elements) loop
      if isNone(alias.variable) then
        Error.addInternalError(getInstanceName() + ": " + ComponentRef.toString(alias.name) +
          " has no associated variable", sourceInfo());
      end if;
    end for;

    flatModel.variables := MetaModelica.Dangerous.listReverseInPlace(vars);
  end fromModel;

  function sortEquations
    "Sorts a list of equations into alias equations and non-alias equations,
     and also returns the aliases found in each alias equation."
    input list<Equation> eqs;
    output list<Equation> aliasEqs = {};
    output list<list<FlowAlias>> flowAliases = {};
    output list<Equation> otherEqs = {};
  protected
    list<FlowAlias> aliases;
    DAE.ElementSource src;
  algorithm
    for eq in eqs loop
      aliases := getAliasVarsFromEq(eq);

      if listEmpty(aliases) then
        otherEqs := eq :: otherEqs;
      else
        src := Equation.source(eq);
        src := ElementSource.addAdditionalComment(src, "alias equation");
        eq := Equation.setSource(src, eq);
        aliasEqs := eq :: aliasEqs;
        flowAliases := aliases :: flowAliases;
      end if;
    end for;

    aliasEqs := MetaModelica.Dangerous.listReverseInPlace(aliasEqs);
    flowAliases := MetaModelica.Dangerous.listReverseInPlace(flowAliases);
    otherEqs := MetaModelica.Dangerous.listReverseInPlace(otherEqs);
  end sortEquations;

  function addAliasEquation
    "Adds an alias equation to the sets."
    input list<FlowAlias> aliases;
    input Equation eq;
    input output Sets sets;
  protected
    list<FlowAlias> scalar_aliases1, scalar_aliases2;
    FlowAlias alias1, alias2;
  algorithm
    {alias1, alias2} := aliases;

    if Equation.isArrayEquality(eq) then
      scalar_aliases1 := scalarizeAlias(alias1);
      scalar_aliases2 := scalarizeAlias(alias2);
      sets := List.threadFold(scalar_aliases1, scalar_aliases2, addAliasPair, sets);
    else
      sets := addAliasPair(alias1, alias2, sets);
    end if;
  end addAliasEquation;

  function addAliasBinding
    "Adds a variable's binding equation to the sets if var = binding qualifies
     as an alias equation."
    input Variable var;
    input output Sets sets;
  protected
    Expression bind_exp;
    list<FlowAlias> aliases;
    FlowAlias alias1, alias2;
  algorithm
    if Binding.hasExp(var.binding) then
      bind_exp := Binding.getExp(var.binding);
      aliases := getAliasVarsFromExpPair(Expression.fromTypedCref(var.name, var.ty), bind_exp);

      if not listEmpty(aliases) then
        {alias1, alias2} := aliases;
        sets := addAliasPair(alias1, alias2, sets);
      end if;
    end if;
  end addAliasBinding;

  function addAliasPair
    "Adds the alias equation alias1 = alias2 to the sets."
    input FlowAlias alias1;
    input FlowAlias alias2;
    input output Sets sets;
  protected
    Integer set1, set2, root1, root2;
    Boolean flipped_sign1, flipped_sign2;

    function find_set
      "Returns the set that the alias or its negative belongs to,
       as well as if it was the alias or its negative that was found."
      input FlowAlias alias;
            output Integer set;
      input output Sets sets;
            output Boolean flippedSign;
    protected
      FlowAlias negative_alias = alias;
      FlowAlias entry;
    algorithm
      (set, sets) := findSet(alias, sets);
      SOME(entry) := getEntry(alias, sets);
      flippedSign := entry.negative <> alias.negative;
    end find_set;
  algorithm
    // Find the sets the aliases or their negatives belong to.
    (set1, sets, flipped_sign1) := find_set(alias1, sets);
    (set2, sets, flipped_sign2) := find_set(alias2, sets);

    // If the negative of exactly one of the aliases was found, then all the
    // aliases in one of the sets need to be negated before merging the sets.
    if flipped_sign1 <> flipped_sign2 then
      // TODO: If one of them got added as a new set, then we only need to flip that one.
      root1 := findRoot(set1, sets.nodes);
      root2 := findRoot(set2, sets.nodes);

      // If both aliases belong to the same set then there are inconsistent
      // alias equations (e.g. a = b, a = -b).
      if root1 == root2 then
        // TODO: Give an error message instead?
        return;
      end if;

      sets := negateSet(if alias1.negative then root1 else root2, sets);
    end if;

    sets := union(set1, set2, sets);
  end addAliasPair;

  function getAliasVarsFromEq
    "Returns the alias variables in an equation. For aliases to be found the
     equation should be a simple equation such as a = b or a = -b, and at least
     one of the variables should be a flow variable inside a stream connector."
    input Equation eq;
    output list<FlowAlias> aliases = {};
  algorithm
    aliases := match eq
      case Equation.EQUALITY() then getAliasVarsFromExpPair(eq.lhs, eq.rhs);
      else {};
    end match;
  end getAliasVarsFromEq;

  function getAliasVarsFromExpPair
    "Returns the alias variables found in the given expressions if exp1 = exp2
     qualifies as an alias equation."
    input Expression exp1;
    input Expression exp2;
    output list<FlowAlias> aliases;
  algorithm
    aliases := getAliasVarsFromExp(exp1, exp2, {});
    aliases := getAliasVarsFromExp(exp2, exp1, aliases);

    if listLength(aliases) <> 2 or List.none(aliases, isStreamConnectorFlow) then
      aliases := {};
    end if;
  end getAliasVarsFromExpPair;

  function getAliasVarsFromExp
    "Returns the alias variables for one side of an equation, with the other
     side being used to check for e.g. zero equality but not contributing to
     the list of aliases."
    input Expression exp;
    input Expression otherExp;
    input output list<FlowAlias> aliases;
  protected
    Expression e;
    list<FlowAlias> aliases1, aliases2;
    FlowAlias alias1, alias2;
  algorithm
    aliases := match exp
      // a
      case Expression.CREF() then FlowAlias.FLOW_ALIAS(exp.cref, false, NONE()) :: aliases;
      // -a
      case Expression.UNARY(exp = e as Expression.CREF()) then FlowAlias.FLOW_ALIAS(e.cref, true, NONE()) :: aliases;

      // a + b = 0 => a = -b;
      case Expression.BINARY(operator = Operator.OPERATOR(op = NFOperator.Op.ADD))
        guard Expression.isZero(otherExp)
        algorithm
          aliases1 := getAliasVarsFromExp(exp.exp1, exp.exp2, {});
          aliases2 := getAliasVarsFromExp(exp.exp2, exp.exp1, {});

          if listLength(aliases1) == 1 and listLength(aliases2) == 1 then
            {alias1} := aliases1;
            {alias2} := aliases2;
            alias2.negative := not alias2.negative;
            aliases := alias1 :: alias2 :: aliases;
          end if;
        then
          aliases;

      else aliases;
    end match;
  end getAliasVarsFromExp;

  function isStreamConnectorFlow
    "Checks if the given flow alias refers to a flow variable inside a stream connector."
    input FlowAlias alias;
    output Boolean isStreamFlow;
  protected
    InstNode node;
  algorithm
    // A top-level component is by definition not inside a stream connector.
    if not ComponentRef.isQualified(alias.name) then
      isStreamFlow := false;
      return;
    end if;

    node := ComponentRef.node(alias.name);

    // The component must be a flow variable.
    if not InstNode.isComponent(node) or not Component.isFlow(InstNode.component(node)) then
      isStreamFlow := false;
      return;
    end if;

    // The component must be inside a stream connector.
    isStreamFlow := Type.isStreamConnector(ComponentRef.nodeType(ComponentRef.rest(alias.name)));
  end isStreamConnectorFlow;

  function scalarizeAlias
    input FlowAlias alias;
    output list<FlowAlias> scalarAliases = {};
  protected
    list<ComponentRef> crefs;
  algorithm
    crefs := ComponentRef.scalarize(alias.name, false);
    crefs := MetaModelica.Dangerous.listReverseInPlace(crefs);

    for cr in crefs loop
      scalarAliases := FLOW_ALIAS(cr, alias.negative, NONE()) :: scalarAliases;
    end for;
  end scalarizeAlias;

  function negateSet
    "Flips the sign of all aliases in a set."
    input Integer set;
    input output Sets sets;
  protected
    array<Integer> nodes, indices;
    UnorderedMap<FlowAlias, Integer> elements;
    Integer root;
    FlowAlias alias;
  algorithm
    nodes := sets.nodes;
    elements := sets.elements;
    root := findRoot(set, nodes);
    indices := UnorderedMap.valueArray(elements);

    for i in 1:arrayLength(indices) loop
      if findRoot(i, nodes) == root then
        alias := UnorderedMap.keyAt(elements, i);
        alias.negative := not alias.negative;
        Vector.updateNoBounds(elements.keys, i, alias);
      end if;
    end for;
  end negateSet;

  function createAliases
    "Extracts the alias sets and defines the representatives and their aliases."
    input Sets sets;
    input output FlatModel flatModel;
          output list<tuple<FlowAlias, list<FlowAlias>>> aliases = {};
  protected
    array<list<FlowAlias>> extracted_sets;
    FlowAlias representative;
    Variable repr_var;
    list<FlowAlias> rest_aliases, accum_aliases = {};
    Binding repr_binding;
    list<Variable> alias_vars = {};
    list<Equation> alias_eqs = {};
  algorithm
    extracted_sets := extractSets(sets);

    for set in extracted_sets loop
      // Define the representative for the alias set.
      (representative, rest_aliases) := defineRepresentative(set);
      SOME(repr_var) := representative.variable;
      alias_vars := repr_var :: alias_vars;

      // Create a '= representative' binding for the aliases, to show which
      // variable they're aliases of.
      repr_binding := Variable.asBinding(repr_var);

      // Define the rest of the set as aliases of the representative.
      for alias in rest_aliases loop
        (alias, alias_eqs) := defineAlias(alias, repr_binding, alias_eqs);
        alias_vars := Util.getOption(alias.variable) :: alias_vars;
      end for;

      aliases := (representative, rest_aliases) :: aliases;
    end for;

    aliases := listReverseInPlace(aliases);
    flatModel.variables := listAppend(flatModel.variables, listReverseInPlace(alias_vars));
    flatModel.equations := listAppend(flatModel.equations, listReverseInPlace(alias_eqs));
  end createAliases;

  function buildReplacements
    "Constructs an alias->representative map."
    input list<tuple<FlowAlias, list<FlowAlias>>> aliases;
    output UnorderedMap<ComponentRef, Expression> replacements;
  protected
    FlowAlias representative;
    Expression exp, negative_exp;
    list<FlowAlias> rest_aliases;
  algorithm
    replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);

    for set in aliases loop
      (representative, rest_aliases) := set;
      exp := Expression.fromCref(representative.name);
      exp := if representative.negative then Expression.negate(exp) else exp;
      negative_exp := Expression.negate(exp);

      for alias in rest_aliases loop
        UnorderedMap.addUnique(alias.name, if alias.negative then negative_exp else exp, replacements);
      end for;
    end for;
  end buildReplacements;

  function applyReplacements
    "Replaces aliases with the chosen representative variable in the model."
    input UnorderedMap<ComponentRef, Expression> replacements;
    input output FlatModel flatModel;
  algorithm
    flatModel := FlatModel.mapExp(flatModel,
      function Expression.map(func = function applyReplacementsInExp(replacements = replacements)));
  end applyReplacements;

  function applyReplacementsInExp
    input UnorderedMap<ComponentRef, Expression> replacements;
    input output Expression exp;
  protected
    Option<Expression> opt_val;
  algorithm
    exp := match exp
      case Expression.CREF()
        algorithm
          opt_val := UnorderedMap.get(exp.cref, replacements);
        then
          if isSome(opt_val) then Util.getOption(opt_val) else exp;

      else exp;
    end match;
  end applyReplacementsInExp;

  function defineRepresentative
    "Defines a representative for an alias set, by choosing one of the aliases
     as the representative and determining the start/nominal/min/max attributes
     for it."
    input list<FlowAlias> aliases;
    output FlowAlias representative;
    output list<FlowAlias> restAliases;
  protected
    list<Binding> start_values = {}, nominal_values = {};
    list<Expression> min_values = {}, max_values = {};
    list<FlowAlias> accum_aliases = {};
    Expression min_value, max_value;
    Binding start_binding, nominal_binding, min_binding, max_binding;
  algorithm
    // Evaluate the start/nominal/min/max attributes of the aliases and sort them into lists.
    for alias in aliases loop
      (alias, start_values, nominal_values, min_values, max_values) :=
        evalAliasAttributes(alias, start_values, nominal_values, min_values, max_values);
      accum_aliases := alias :: accum_aliases;
    end for;

    // Select any flow variable in the set as the representative.
    (representative, restAliases) := List.findAndRemove(aliases, FlowAlias.isFlow);

    // Compute start/nominal/min/max attributes for the representative.
    // start/nominal is chosen according to 8.6.2
    start_binding := if listEmpty(start_values) then NFBinding.EMPTY_BINDING else listHead(start_values);
    nominal_binding := if listEmpty(nominal_values) then NFBinding.EMPTY_BINDING else listHead(nominal_values);
    // min/max is max(min_values) and min(max_values) respectively.
    min_binding := computeLimit(min_values, Ceval.evalBuiltinMax2);
    max_binding := computeLimit(max_values, Ceval.evalBuiltinMin2);

    // Update the representative with the new attributes.
    representative := setRepresentativeAttributes(representative, start_binding, nominal_binding,
                                                  min_binding, max_binding);
  end defineRepresentative;

  function computeLimit
    "Computes a min or max value for a representative, depending on the reduce function."
    input list<Expression> values;
    input ReduceFn reduceFn;
    output Binding limit;
  protected
    partial function ReduceFn
      input Expression exp1;
      input Expression exp2;
      output Expression result;
    end ReduceFn;

    Expression res;
  algorithm
    if listEmpty(values) then
      limit := NFBinding.EMPTY_BINDING;
    else
      res := List.reduce(values, reduceFn);
      limit := Binding.makeFlat(res, Variability.CONSTANT, NFBinding.Source.GENERATED);
    end if;
  end computeLimit;

  function defineAlias
    input output FlowAlias alias;
    input Binding binding;
    input output list<Equation> equations;
  protected
    Variable var;
    Expression var_exp, bind_exp;
    Equation bind_eq;
  algorithm
    SOME(var) := alias.variable;

    // Move the variable's binding to an equation if it has one.
    if Binding.isBound(var.binding) then
      var_exp := Expression.fromTypedCref(var.name, var.ty);
      bind_exp := Binding.getExp(var.binding);
      bind_eq := Equation.makeEquality(var_exp, bind_exp, var.ty);
      equations := bind_eq :: equations;
    end if;

    // Replace the variable's binding with the given representative binding and
    // mark it as an alias with a comment.
    var.binding := binding;
    var.comment := SCode.Comment.COMMENT(var.comment.annotation_, SOME("Alias variable"));
    alias.variable := SOME(var);
  end defineAlias;

  function evalAliasAttributes
    "Evaluates the start, nominal, min, and max attributes for an alias and
     appends them to the given lists if they're present.

     Start/nominal values are returned as bindings since we need to know where
     they come from, while for min/max we only need the values."
    input output FlowAlias alias;
    input output list<Binding> startValues;
    input output list<Binding> nominalValues;
    input output list<Expression> minValues;
    input output list<Expression> maxValues;
  protected
    Variable var;
    list<tuple<String, Binding>> attrs, accum_attrs = {};
    String attr_name;
    Binding attr_binding;
    Expression attr_exp;
  algorithm
    SOME(var) := alias.variable;
    attrs := var.typeAttributes;

    for attr in attrs loop
      (attr_name, attr_binding) := attr;

      if Binding.hasExp(attr_binding) then
        attr := match attr_name
          case "start"
            algorithm
              attr_binding := evalAliasAttribute(attr_binding);
              startValues := attr_binding :: startValues;
            then
              (attr_name, attr_binding);

          case "nominal"
            algorithm
              attr_binding := evalAliasAttribute(attr_binding);
              nominalValues := attr_binding :: nominalValues;
            then
              (attr_name, attr_binding);

          case "min"
            algorithm
              (attr_binding, attr_exp) := evalAliasAttribute(attr_binding);
              minValues := attr_exp :: minValues;
            then
              (attr_name, attr_binding);

          case "max"
            algorithm
              (attr_binding, attr_exp) := evalAliasAttribute(attr_binding);
              maxValues := attr_exp :: maxValues;
            then
              (attr_name, attr_binding);

          else attr;
        end match;
      end if;

      accum_attrs := attr :: accum_attrs;
    end for;

    attrs := listReverseInPlace(attrs);
    var.typeAttributes := attrs;
    alias.variable := SOME(var);
  end evalAliasAttributes;

  function evalAliasAttribute
    "Helper function to evalAliasAttributes, evaluates an attribute's binding."
    input output Binding binding;
          output Expression bindingExp;
  algorithm
    bindingExp := Binding.getExp(binding);
    Structural.markExp(bindingExp);
    bindingExp := Ceval.evalExp(bindingExp);
    binding := Binding.setExp(bindingExp, binding);
  end evalAliasAttribute;

  function setRepresentativeAttributes
    "Sets the start, nominal, min, and max attributes for an alias set representative."
    input output FlowAlias alias;
    input Binding startValue;
    input Binding nominalValue;
    input Binding minValue;
    input Binding maxValue;
  protected
    Variable var;
    list<tuple<String, Binding>> attrs = {};
    String attr_name;

    function add_attribute
      input String name;
      input Binding binding;
      input output list<tuple<String, Binding>> attrs;
    algorithm
      if Binding.isBound(binding) then
        attrs := (name, binding) :: attrs;
      end if;
    end add_attribute;
  algorithm
    SOME(var) := alias.variable;

    // Remove any existing attributes.
    attrs := list(attr for attr guard not listMember(Util.tuple21(attr),
                  {"start", "nominal", "min", "max"}) in var.typeAttributes);

    // Add the new attributes if they have a binding.
    attrs := add_attribute("max", maxValue, attrs);
    attrs := add_attribute("min", minValue, attrs);
    attrs := add_attribute("nominal", nominalValue, attrs);
    attrs := add_attribute("start", startValue, attrs);

    var.typeAttributes := attrs;
    alias.variable := SOME(var);
  end setRepresentativeAttributes;

annotation(__OpenModelica_Interface="nf_frontend");
end NFStreamFlowAlias;
