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
  import Operator = NFOperator;
  import Type = NFType;

  extends DisjointSets(redeclare type Entry = FlowAlias);

  uniontype FlowAlias
    record FLOW_ALIAS
      ComponentRef name;
      Boolean negative;
    end FLOW_ALIAS;
  end FlowAlias;

  redeclare function extends EntryHash
  algorithm
    hash := ComponentRef.hash(entry.name);
  end EntryHash;

  redeclare function extends EntryEqual
  algorithm
    isEqual := entry1.negative == entry2.negative and
               ComponentRef.isEqual(entry1.name, entry2.name);
  end EntryEqual;

  redeclare function extends EntryString
  algorithm
    str := ComponentRef.toString(entry.name);
    if entry.negative then
      str := "-" + str;
    end if;
  end EntryString;

  function fromModel
    input output FlatModel flatModel;
    output Sets sets;
    output list<Equation> aliasEqs;
  protected
    list<Equation> other_eqs;
    list<list<FlowAlias>> flow_aliases;
  algorithm
    sets := emptySets(0);
    (aliasEqs, flow_aliases, other_eqs) := sortEquations(flatModel.equations);
    flatModel.equations := other_eqs;
    sets := List.threadFold(flow_aliases, aliasEqs, addAliasEquation, sets);
  end fromModel;

  function sortEquations
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

  function addAliasPair
    input FlowAlias alias1;
    input FlowAlias alias2;
    input output Sets sets;
  protected
    Integer set1, set2, root1, root2;
    Boolean flipped_sign1, flipped_sign2;

    function find_set
      "Returns the set that the alias or its negative belongs to."
      input FlowAlias alias;
            output Integer set;
      input output Sets sets;
            output Boolean flippedSign;
    protected
      FlowAlias negative_alias = alias;
    algorithm
      negative_alias.negative := not negative_alias.negative;

      if contains(negative_alias, sets) then
        (set, sets) := findSet(negative_alias, sets);
        flippedSign := true;
      else
        (set, sets) := findSet(alias, sets);
        flippedSign := false;
      end if;
    end find_set;
  algorithm
    // Find the sets the aliases or their negatives belong to.
    (set1, sets, flipped_sign1) := find_set(alias1, sets);
    (set2, sets, flipped_sign2) := find_set(alias2, sets);

    // If the negative of exactly one of the aliases was found, then all the
    // aliases in one of the sets need to be negated before merging the sets.
    if flipped_sign1 <> flipped_sign2 then
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
      case Equation.EQUALITY()
        algorithm
          aliases := getAliasVarsFromExp(eq.lhs, eq.rhs, aliases);
          aliases := getAliasVarsFromExp(eq.rhs, eq.lhs, aliases);
        then
          if listLength(aliases) == 2 and List.any(aliases, isStreamConnectorFlow) then aliases else {};

      else {};
    end match;
  end getAliasVarsFromEq;

  function getAliasVarsFromExp
    input Expression exp;
    input Expression otherExp;
    input output list<FlowAlias> aliases;
  protected
    Expression e;
    list<FlowAlias> aliases1, aliases2;
    FlowAlias alias1, alias2;
  algorithm
    aliases := match exp
      case Expression.CREF() then FlowAlias.FLOW_ALIAS(exp.cref, false) :: aliases;
      case Expression.UNARY(exp = e as Expression.CREF()) then FlowAlias.FLOW_ALIAS(e.cref, true) :: aliases;

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
      scalarAliases := FLOW_ALIAS(cr, alias.negative) :: scalarAliases;
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

  function removeAliases
    input output FlatModel flatModel;
  protected
    Sets sets;
    list<Equation> flow_eqs;
    UnorderedMap<ComponentRef, Expression> replacements;
    array<list<FlowAlias>> alias_sets;
  algorithm
    (flatModel, sets, flow_eqs) := fromModel(flatModel);
    replacements := buildReplacements(sets);
    flatModel := applyReplacements(replacements, flatModel);
    flatModel.equations := listAppend(flatModel.equations, flow_eqs);
  end removeAliases;

  function buildReplacements
    input Sets sets;
    output UnorderedMap<ComponentRef, Expression> replacements;
  protected
    FlowAlias representative;
    Expression exp, negative_exp;
    list<FlowAlias> rest_aliases;
    array<list<FlowAlias>> extracted_sets;
  algorithm
    replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    extracted_sets := extractSets(sets);

    for set in extracted_sets loop
      representative :: rest_aliases := set;
      exp := Expression.fromCref(representative.name);
      exp := if representative.negative then Expression.negate(exp) else exp;
      negative_exp := Expression.negate(exp);

      for alias in rest_aliases loop
        UnorderedMap.addUnique(alias.name, if alias.negative then negative_exp else exp, replacements);
      end for;
    end for;
  end buildReplacements;

  function applyReplacements
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

annotation(__OpenModelica_Interface="nf_frontend");
end NFStreamFlowAlias;
