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

encapsulated uniontype NBInline<T>
" file:         NBInline.mo
  package:      NBInline
  description:  This file contains functions for inlining operations.
"

protected
  import Inline = NBInline;

  // OF imports
  import Absyn;
  import AbsynUtil;
  import DAE;
  import DAEDump;
  import DAEUtil;

  // NF imports
  import BackendExtension = NFBackendExtension;
  import Binding = NFBinding;
  import Call = NFCall;
  import Class = NFClass;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFFunction.Function;
  import NFFlatten.FunctionTree;
  import InstNode = NFInstNode.InstNode;
  import NFModifier.Modifier;
  import Operator = NFOperator;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // NB imports
  import Module = NBModule;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, IfEquationBody, EquationPointers, EqData, EquationAttributes, Iterator};
  import Replacements = NBReplacements;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers, VarData};

  // Util
  import Slice = NBSlice;
  import StringUtil;

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
public
  function main
    "Wrapper function for any inlining function. This will be
     called during simulation and gets the corresponding subfunction from
     the given input."
    extends Module.wrapper;
    input list<DAE.InlineType> inline_types;
    input Boolean init;
  algorithm
    bdae := match bdae
      local
        EqData eqData;
        VarData varData;
      case BackendDAE.MAIN()
        algorithm
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print(StringUtil.headline_4("[dumpBackendInline] Inlining operatations for: "
              + List.toString(inline_types, DAEDump.dumpInlineTypeBackendStr)));
          end if;
          (eqData, varData) := inline(bdae.eqData, bdae.varData, bdae.funcMap, inline_types, init);
          bdae.eqData := eqData;
          bdae.varData := varData;
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print("\n");
          end if;
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

// =========================================================================
//                    TYPES, UNIONTYPES AND MEMBER FUNCTIONS
// =========================================================================
  function inlineForEquation
    "inlines for-equations of size 1 to its body equation by replacing
    the iterators by the only values they are ever going to be."
    input output Equation eqn;
  algorithm
    eqn := match eqn
      local
        Equation new_eqn;
        UnorderedMap<ComponentRef, Expression> replacements     "replacement map for iterator crefs";
        list<ComponentRef> names;
        list<Expression> ranges;
        ComponentRef name;
        Expression range;
        Integer start;

      case Equation.FOR_EQUATION(body = {new_eqn}) guard(Iterator.size(eqn.iter) == 1 and not Iterator.isResizable(eqn.iter)) algorithm
        replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        (names, ranges) := Iterator.getFrames(eqn.iter);
        for tpl in List.zip(names, ranges) loop
          (name, range) := tpl;
          (start, _, _) := Expression.getIntegerRange(range, true);
          UnorderedMap.add(name, Expression.INTEGER(start), replacements);
        end for;
        new_eqn := Equation.map(new_eqn, function Replacements.applySimpleExp(replacements = replacements));
        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
          print("-- Result: " + Equation.toString(new_eqn) + "\n");
        end if;
      then new_eqn;

      else eqn;
    end match;
  end inlineForEquation;

  function functionInlineable
    "returns true if the function can be inlined"
    input Function fn;
    output Boolean b = false;
  algorithm
    // currently we only inline single assignments
    // also check for single output?
    if Function.hasSingleOrEmptyBody(fn) then
      b := match Function.getBody(fn)
        case {Statement.ASSIGNMENT()} then true;
        else false;
      end match;
    end if;
  end functionInlineable;

  function inlineRecordSliceEquation
    input Slice<Pointer<Equation>> slice;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
    output list<Slice<Pointer<Equation>>> slices;
  protected
    Pointer<list<Pointer<Equation>>> record_eqns = Pointer.create({});
  algorithm
    inlineRecordTupleArrayEquation(Pointer.access(Slice.getT(slice)), Iterator.EMPTY(), variables, record_eqns, set, index, inlineSimple);
    // somehow split slice.indices
    slices := list(Slice.SLICE(eqn, {}) for eqn in Pointer.access(record_eqns));
    if listEmpty(slices) then
      slices := {slice};
    end if;
  end inlineRecordSliceEquation;

  function inlineArrayConstructorSingle
    input output Equation eqn;
    input Iterator iter;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
    output Boolean changed;
  algorithm
    try
      (eqn, changed) := match eqn
        local
          Equation new_eqn, body;
          Expression lhs, rhs;
          Call call;

        // CREF = {... for i in []} array constructor equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs=Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR())) algorithm
        then (inlineArrayConstructor(eqn, lhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index), true);

        // {... for i in []} = CREF array constructor equation
        case Equation.ARRAY_EQUATION(lhs=Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()), rhs = rhs as Expression.CREF()) algorithm
        then (inlineArrayConstructor(eqn, rhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index), true);

        // apply on for-equation. assumed to be split up
        case Equation.FOR_EQUATION(body = {body}) algorithm
          (new_eqn, changed) := inlineArrayConstructorSingle(body, eqn.iter, variables, set, index, new_eqns);
          new_eqn := if changed then new_eqn else eqn;
        then (new_eqn, changed);

        // nothing happens
        else (eqn, false);
      end match;
      // unpack the equation
      eqn := if Equation.isDummy(eqn) then Pointer.access(listHead(Pointer.access(new_eqns))) else eqn;
    else
      changed := false;
      if Flags.isSet(Flags.FAILTRACE) then
        Error.addCompilerWarning("Failed to inline following equation:\n" + Equation.toString(eqn));
      end if;
    end try;
  end inlineArrayConstructorSingle;

protected
  function inline extends Module.inlineInterface;
  protected
    UnorderedMap<Absyn.Path, Function> replacements "rules for replacements are stored inside here";
    UnorderedSet<VariablePointer> set "new iterators from function bodies";
    VariablePointers variables = VarData.getVariables(varData);
    Absyn.Path key;
    Function value;
    // this map should probably be saved somewhere so its not done again for the initial system
    UnorderedMap<Function, InlineRating> func_map = UnorderedMap.new<InlineRating>(Function.nameHash, Function.nameEqual);
  algorithm
    // collect functions
    replacements := UnorderedMap.new<Function>(AbsynUtil.pathHash, AbsynUtil.pathEqual);
    for tpl in UnorderedMap.toList(funcMap) loop
      (key, value) := tpl;
      // only add to the map if the function has one of the inline types and is inlineable
      // if its inline type = default check if its reasonable to inline
      if checkInline(value, inline_types, func_map) then
        UnorderedMap.add(key, value, replacements);
      end if;
    end for;

    if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) and List.contains(inline_types, DAE.InlineType.DEFAULT_INLINE(), DAEUtil.inlineTypeEqual) and not init then
      print(StringUtil.headline_2("Heuristic results for Inline=default functions. Threshold = " + intString(HEURISTIC_THRESHOLD)));
      print(UnorderedMap.toString(func_map, function Function.signatureString(printTypes = false), InlineRating.toString) + "\n\n");
    end if;

    // carry the attributes (min, max, nominal, unit, ...) declared on the
    // function inputs/outputs onto the model variables bound to them before the
    // call is replaced by the function body, so they are not lost (#15947).
    eqData  := propagateAttributes(eqData, variables, replacements);

    // apply replacements
    eqData  := Replacements.replaceFunctions(eqData, variables, replacements);

    // do not inline records tuples and arrays after causalization
    // ToDo: do it properly on strong components, cannot remove equations here
    set     := UnorderedSet.new(BVariable.hash, BVariable.equalName);
    if not List.any(inline_types, function DAEUtil.inlineTypeEqual(it2 = DAE.AFTER_INDEX_RED_INLINE())) then
      // replace record constucters after functions because record operator
      // functions will produce record constructors once inlined
      eqData  := inlineRecordsTuplesArrays(eqData, variables, set, init);
    end if;

    // collect new iterators from replaced function bodies
    eqData  := EqData.map(eqData, function BackendDAE.lowerEquationIterators(variables = variables, set = set));
    varData := VarData.addTypedList(varData, UnorderedSet.toList(set), NBVariable.VarData.VarType.ITERATOR);
    eqData  := EqData.mapExp(eqData, function BackendDAE.lowerComponentReferenceExp(variables = variables, complete = true));
  end inline;

// =========================================================================
//          ATTRIBUTE PROPAGATION (min/max/nominal/unit/... see #15947)
// =========================================================================
  function propagateAttributes
    "Carries the attributes (min, max, nominal, unit, start, fixed, ...) declared
     on the inputs and outputs of the functions that are about to be inlined onto
     the model variables that are bound to them, so the information is not lost
     when the call is replaced by the function body (#15947)."
    input output EqData eqData;
    input VariablePointers variables;
    input UnorderedMap<Absyn.Path, Function> replacements;
  protected
    UnorderedMap<ComponentRef, ComponentRef> alias_map;
  algorithm
    if UnorderedMap.isEmpty(replacements) then return; end if;
    // The frontend extracts function call outputs into auxiliary '$FUN_x'
    // variables ('$FUN_x = fn(...)' plus 'realVar = $FUN_x'). Build a map from
    // such auxiliary variables to the real variable they are bound to so the
    // output attributes end up on the real variable.
    alias_map := UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    eqData := EqData.map(eqData, function collectFunctionAlias(variables = variables, alias_map = alias_map));
    eqData := EqData.map(eqData, function propagateEquationAttributes(variables = variables, replacements = replacements, alias_map = alias_map));
  end propagateAttributes;

  function collectFunctionAlias
    "Collects 'realVar = $FUN_x' (or the reverse) equations into a map from the
     auxiliary function-alias variable to the real variable bound to it."
    input output Equation eqn;
    input VariablePointers variables;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  algorithm
    () := match eqn
      local
        ComponentRef cr1, cr2;
      case Equation.SCALAR_EQUATION(lhs = Expression.CREF(cref = cr1), rhs = Expression.CREF(cref = cr2)) algorithm
        addFunctionAlias(cr1, cr2, variables, alias_map);
      then ();
      case Equation.RECORD_EQUATION(lhs = Expression.CREF(cref = cr1), rhs = Expression.CREF(cref = cr2)) algorithm
        addFunctionAlias(cr1, cr2, variables, alias_map);
      then ();
      else ();
    end match;
  end collectFunctionAlias;

  function addFunctionAlias
    "Adds a mapping aux -> real if exactly one of the two crefs is a function
     alias variable."
    input ComponentRef cr1;
    input ComponentRef cr2;
    input VariablePointers variables;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  protected
    ComponentRef n1 = ComponentRef.stripSubscriptsAll(cr1);
    ComponentRef n2 = ComponentRef.stripSubscriptsAll(cr2);
    Boolean f1, f2;
  algorithm
    if not (VariablePointers.containsCref(n1, variables) and VariablePointers.containsCref(n2, variables)) then
      return;
    end if;
    f1 := BVariable.isFunctionAlias(VariablePointers.getVarSafe(variables, n1));
    f2 := BVariable.isFunctionAlias(VariablePointers.getVarSafe(variables, n2));
    if f1 and not f2 then
      UnorderedMap.add(n1, n2, alias_map);
    elseif f2 and not f1 then
      UnorderedMap.add(n2, n1, alias_map);
    end if;
  end addFunctionAlias;

  function resolveAlias
    "Follows the function-alias chain to the real variable bound to it."
    input output ComponentRef name;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  protected
    Integer cnt = 0;
  algorithm
    while cnt < 100 loop
      cnt := cnt + 1;
      name := match UnorderedMap.get(name, alias_map)
        case SOME(name) then name;
        else algorithm return; then name;
      end match;
    end while;
  end resolveAlias;

  function propagateEquationAttributes
    "Applied on each equation. Does not change the equation, it only mutates the
     attributes of the variables bound to the inlined function inputs/outputs."
    input output Equation eqn;
    input VariablePointers variables;
    input UnorderedMap<Absyn.Path, Function> replacements;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  algorithm
    // output side: carry the output attributes onto the result variable of a
    // simple 'cref = fn(...)' (or 'fn(...) = cref') equation.
    () := match eqn
      case Equation.SCALAR_EQUATION() algorithm propagateOutput(eqn.lhs, eqn.rhs, variables, replacements, alias_map); then ();
      case Equation.ARRAY_EQUATION()  algorithm propagateOutput(eqn.lhs, eqn.rhs, variables, replacements, alias_map); then ();
      case Equation.RECORD_EQUATION() algorithm propagateOutput(eqn.lhs, eqn.rhs, variables, replacements, alias_map); then ();
      else ();
    end match;
    // input side: carry the input attributes onto every cref argument of any
    // inlinable call found anywhere in the equation.
    eqn := Equation.map(eqn, function propagateInputExp(variables = variables, replacements = replacements, alias_map = alias_map));
  end propagateEquationAttributes;

  function propagateOutput
    "Carries the (single) output's attributes onto the result variable of a
     'cref = fn(...)' or 'fn(...) = cref' equation."
    input Expression lhs;
    input Expression rhs;
    input VariablePointers variables;
    input UnorderedMap<Absyn.Path, Function> replacements;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  protected
    Expression cref_exp, call_exp;
    Call call;
    Function fn;
  algorithm
    // figure out which side is the result cref and which is the inlinable call
    if Expression.isCref(lhs) and isInlinableCall(rhs, replacements) then
      cref_exp := lhs;
      call_exp := rhs;
    elseif Expression.isCref(rhs) and isInlinableCall(lhs, replacements) then
      cref_exp := rhs;
      call_exp := lhs;
    else
      return;
    end if;

    Expression.CALL(call = call) := call_exp;
    fn := Call.typedFunction(call);
    fn := UnorderedMap.getOrFail(fn.path, replacements);
    // only single-output functions have a well defined result variable
    if listLength(fn.outputs) == 1 then
      mergeNodeOntoArg(listHead(fn.outputs), cref_exp, variables, alias_map);
    end if;
  end propagateOutput;

  function propagateInputExp
    "Needs to be mapped with Expression.map(). Merges the declared input
     attributes onto the cref arguments of every inlinable call."
    input output Expression exp;
    input VariablePointers variables;
    input UnorderedMap<Absyn.Path, Function> replacements;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  protected
    Call call;
    Function fn;
    list<Expression> args;
  algorithm
    () := match exp
      case Expression.CALL(call = call as Call.TYPED_CALL(fn = fn, arguments = args))
        guard UnorderedMap.contains(fn.path, replacements) algorithm
        fn := UnorderedMap.getOrFail(fn.path, replacements);
        if listLength(fn.inputs) == listLength(args) then
          for tpl in List.zip(fn.inputs, args) loop
            mergeNodeOntoArg(Util.tuple21(tpl), Util.tuple22(tpl), variables, alias_map);
          end for;
        end if;
      then ();
      else ();
    end match;
  end propagateInputExp;

  function isInlinableCall
    "True if the expression is a call to a function that will be inlined."
    input Expression exp;
    input UnorderedMap<Absyn.Path, Function> replacements;
    output Boolean b;
  algorithm
    b := match exp
      local
        Function fn;
      case Expression.CALL(call = Call.TYPED_CALL(fn = fn)) then UnorderedMap.contains(fn.path, replacements);
      else false;
    end match;
  end isInlinableCall;

  function mergeNodeOntoArg
    "Merges the attributes declared on an input/output node onto the model
     variable bound to the given argument expression. Handles records both as
     crefs and as record constructors/literals."
    input InstNode node;
    input Expression arg;
    input VariablePointers variables;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  protected
    list<InstNode> node_children;
    list<Expression> elems;
  algorithm
    () := match arg
      case Expression.CREF() algorithm
        mergeNodeOntoCref(node, arg.cref, variables, alias_map);
      then ();

      // record constructor / record literal argument: recurse element-wise
      else algorithm
        node_children := nodeRecordChildren(node);
        if not listEmpty(node_children) then
          try
            elems := Expression.getRecordElements(arg);
          else
            elems := {};
          end try;
          if listLength(node_children) == listLength(elems) then
            for tpl in List.zip(node_children, elems) loop
              mergeNodeOntoArg(Util.tuple21(tpl), Util.tuple22(tpl), variables, alias_map);
            end for;
          end if;
        end if;
      then ();
    end match;
  end mergeNodeOntoArg;

  function mergeNodeOntoCref
    "Merges the attributes declared on an input/output node onto the variable
     referenced by cref. For record variables it recurses onto the children."
    input InstNode node;
    input ComponentRef cref;
    input VariablePointers variables;
    input UnorderedMap<ComponentRef, ComponentRef> alias_map;
  protected
    ComponentRef name;
    Pointer<Variable> var_ptr;
    Variable var;
    BackendExtension.BackendInfo binfo;
    list<Pointer<Variable>> rec_children;
    list<InstNode> node_children;
    list<ComponentRef> cref_children;
    BackendExtension.VariableAttributes src_attrs;
  algorithm
    name := ComponentRef.stripSubscriptsAll(cref);
    // redirect auxiliary function-alias variables to the real variable
    name := resolveAlias(name, alias_map);
    if not VariablePointers.containsCref(name, variables) then
      return;
    end if;
    var_ptr := VariablePointers.getVarSafe(variables, name);

    // records: recurse onto the children variables
    rec_children := BVariable.getRecordChildren(var_ptr);
    if not listEmpty(rec_children) then
      node_children := nodeRecordChildren(node);
      cref_children := BVariable.getRecordChildrenCref(name);
      if listLength(node_children) == listLength(cref_children) then
        for tpl in List.zip(node_children, cref_children) loop
          mergeNodeOntoCref(Util.tuple21(tpl), Util.tuple22(tpl), variables, alias_map);
        end for;
      end if;
      return;
    end if;

    // scalar leaf: merge the declared attributes onto the variable
    try
      src_attrs := nodeVariableAttributes(node);
      var := Pointer.access(var_ptr);
      binfo := var.backendinfo;
      binfo.attributes := BackendExtension.VariableAttributes.merge(binfo.attributes, src_attrs);
      var.backendinfo := binfo;
      Pointer.update(var_ptr, var);
    else
    end try;
  end mergeNodeOntoCref;

  function nodeRecordChildren
    "Returns the record field nodes of a node, or {} if it is not a record."
    input InstNode node;
    output list<InstNode> children;
  protected
    InstNode cls_node;
  algorithm
    children := match Type.arrayElementType(InstNode.getType(node))
      case Type.COMPLEX(cls = cls_node) then arrayList(Class.getComponents(InstNode.getClass(cls_node)));
      else {};
    end match;
  end nodeRecordChildren;

  function nodeVariableAttributes
    "Builds the backend VariableAttributes declared on a (scalar) function
     input/output node. Only constant attribute values are kept so that no
     function-local references leak into the model variable's attributes."
    input InstNode node;
    output BackendExtension.VariableAttributes attrs;
  protected
    Component comp = InstNode.component(node);
    list<tuple<String, Binding>> ty_attrs;
  algorithm
    ty_attrs := list((Modifier.name(m), Modifier.binding(m)) for m in
      Class.getTypeAttributes(InstNode.getClass(Component.classInstance(comp))));
    ty_attrs := List.filterOnTrue(ty_attrs, attrIsConst);
    attrs := BackendExtension.VariableAttributes.create(ty_attrs, InstNode.getType(node),
      Component.getAttributes(comp), {}, Component.comment(comp));
  end nodeVariableAttributes;

  function attrIsConst
    "True if the attribute binding is typed and contains no component references."
    input tuple<String, Binding> attr;
    output Boolean b;
  protected
    Expression exp;
  algorithm
    try
      exp := Binding.getTypedExp(Util.tuple22(attr));
      b := not Expression.contains(exp, isCrefExp);
    else
      b := false;
    end try;
  end attrIsConst;

  function isCrefExp
    input Expression exp;
    output Boolean b;
  algorithm
    b := match exp
      case Expression.CREF() then true;
      else false;
    end match;
  end isCrefExp;

  function inlineRecordsTuplesArrays
    "does not inline simple record equalities"
    input output EqData eqData;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Boolean init;
  protected
    Pointer<Integer> index = EqData.getUniqueIndex(eqData);
    Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
  algorithm
    if init then
      eqData := match eqData
        case EqData.EQ_DATA_SIM() algorithm
          eqData.initials := EquationPointers.map(eqData.initials, function inlineRecordTupleArrayEquation(iter = Iterator.EMPTY(), variables = variables, new_eqns = new_eqns, set = set, index = index, inlineSimple = false));
          eqData.initials := EquationPointers.addList(Pointer.access(new_eqns), eqData.initials);
          eqData.initials := EquationPointers.compress(eqData.initials);
        then eqData;

        else eqData;
      end match;
    else
      eqData := EqData.map(eqData, function inlineRecordTupleArrayEquation(iter = Iterator.EMPTY(), variables = variables, new_eqns = new_eqns, set = set, index = index, inlineSimple = false));
      eqData := EqData.addUntypedList(eqData, Pointer.access(new_eqns), false);
      eqData := EqData.compress(eqData);
    end if;
  end inlineRecordsTuplesArrays;

public
  function inlineRecordTupleArrayEquation
    input output Equation eqn;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  algorithm
    try
      eqn := match eqn
        local
          Equation new_eqn, body;
          Expression lhs, rhs;
          Call call;
          Dimension dim;
          list<Expression> elements;
          Integer size;

        // don't inline simple cref equalities
        case Equation.RECORD_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF()) guard(not inlineSimple) then eqn;
        case Equation.ARRAY_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF())  guard(not inlineSimple) then eqn;

        // try to inline other record equations. try catch to be sure to not discard
        case Equation.RECORD_EQUATION(ty = Type.COMPLEX()) then inlineRecordEquation(eqn, eqn.lhs, eqn.rhs, iter, eqn.attr, eqn.recordSize, variables, new_eqns, set, index, inlineSimple);

        // only if record size is not NONE()
        case Equation.ARRAY_EQUATION(recordSize = SOME(size)) then inlineRecordEquation(eqn, eqn.lhs, eqn.rhs, iter, eqn.attr, size, variables, new_eqns, set, index, inlineSimple);

        // inlining potential tuple equations
        case Equation.RECORD_EQUATION() then inlineTupleEquation(eqn, eqn.lhs, eqn.rhs, eqn.attr, iter, variables, new_eqns, set, index);

        // {...} = {...} array equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.ARRAY(), rhs = rhs as Expression.ARRAY())
        then inlineArrayEquation(eqn, lhs.elements, rhs.elements, eqn.attr, iter, variables, new_eqns, set, index);

        // CREF = {...} array equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs = rhs as Expression.ARRAY()) algorithm
          dim       := listHead(Type.arrayDims(lhs.ty));
          elements  := list(NFExpression.applySubscripts({Subscript.nth(dim, i)}, lhs, true) for i in 1:arrayLength(rhs.elements));
        then inlineArrayEquation(eqn, listArray(elements), rhs.elements, eqn.attr, iter, variables, new_eqns, set, index);

        // {...} = CREF array equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.ARRAY(), rhs = rhs as Expression.CREF()) algorithm
          dim       := listHead(Type.arrayDims(rhs.ty));
          elements  := list(NFExpression.applySubscripts({Subscript.nth(dim, i)}, rhs, true) for i in 1:arrayLength(lhs.elements));
        then inlineArrayEquation(eqn, lhs.elements, listArray(elements), eqn.attr, iter, variables, new_eqns, set, index);

        // CREF = {... for i in []} array constructor equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs=Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()))
        then inlineArrayConstructor(eqn, lhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index);

        // {... for i in []} = CREF array constructor equation
        case Equation.ARRAY_EQUATION(lhs=Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()), rhs = rhs as Expression.CREF())
        then inlineArrayConstructor(eqn, rhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index);

        // CREF = cat()
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs = Expression.CALL(call = call))
          guard(AbsynUtil.pathString(Function.nameConsiderBuiltin(Call.typedFunction(call))) == "cat")
        then inlineCatCall(eqn, lhs.cref, Call.arguments(call), eqn.attr, iter, variables, new_eqns, set, index);

        // cat() = CREF
        case Equation.ARRAY_EQUATION(lhs = Expression.CALL(call = call), rhs = rhs as Expression.CREF())
          guard(AbsynUtil.pathString(Function.nameConsiderBuiltin(Call.typedFunction(call))) == "cat")
        then inlineCatCall(eqn, rhs.cref, Call.arguments(call), eqn.attr, iter, variables, new_eqns, set, index);

        // CREF = promote()
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs = Expression.CALL(call = call))
          guard(AbsynUtil.pathString(Function.nameConsiderBuiltin(Call.typedFunction(call))) == "promote")
        then inlinePromoteCall(eqn, lhs.cref, Call.arguments(call), eqn.attr, iter, variables, new_eqns, set, index);

        // promote() = CREF
        case Equation.ARRAY_EQUATION(lhs = Expression.CALL(call = call), rhs = rhs as Expression.CREF())
          guard(AbsynUtil.pathString(Function.nameConsiderBuiltin(Call.typedFunction(call))) == "promote")
        then inlinePromoteCall(eqn, rhs.cref, Call.arguments(call), eqn.attr, iter, variables, new_eqns, set, index);

        // apply on for-equation. assumed to be split up
        case Equation.FOR_EQUATION(body = {body}) algorithm
          new_eqn := inlineRecordTupleArrayEquation(body, eqn.iter, variables, new_eqns, set, index, true);
          new_eqn := if Equation.isDummy(new_eqn) then new_eqn else eqn;
        then new_eqn;

        // apply on if-equation body equations
        case Equation.IF_EQUATION() guard IfEquationBody.isRecordOrTupleEquation(eqn.body) algorithm
          new_eqn := inlineRecordTupleArrayIfEquation(eqn, eqn.body, iter, variables, new_eqns, set, index, inlineSimple);
          new_eqn := if Equation.isDummy(new_eqn) then new_eqn else eqn;
        then new_eqn;

        // nothing happens
        else eqn;
      end match;
    else
      if Flags.isSet(Flags.FAILTRACE) then
        Error.addCompilerWarning("Failed to inline following equation:\n" + Equation.toString(eqn));
      end if;
    end try;
  end inlineRecordTupleArrayEquation;

protected
  function inlineRecordTupleArrayIfEquation
    "Documentation"
    input output Equation eqn;
    input IfEquationBody body;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  protected
    list<Pointer<Equation>> eqns;
    IfEquationBody new_body;
    Pointer<Equation> new_eqn;
  algorithm
    eqns := Pointer.access(new_eqns);
    new_body := inlineRecordTupleArrayIfBody(body, iter, variables, set, index, inlineSimple);
    for b in IfEquationBody.split(new_body) loop
      new_eqn := IfEquationBody.makeIfEquation(b, index, NBEquation.SIMULATION_STR, iter, Equation.getSource(eqn), Equation.getAttributes(eqn));
      eqns := new_eqn :: eqns;
    end for;
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineRecordTupleArrayIfEquation;

  function inlineRecordTupleArrayIfBody
    "Documentation"
    input output IfEquationBody body;
    input Iterator iter;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  protected
    Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
  algorithm
    body.then_eqns := List.flatten(list(
      match inlineRecordTupleArrayEquation(Pointer.access(e), iter, variables, new_eqns, set, index, inlineSimple)
        case Equation.DUMMY_EQUATION() then Pointer.access(new_eqns);
        else {e};
      end match for e in body.then_eqns));
    body.else_if := Util.applyOption(body.else_if, function inlineRecordTupleArrayIfBody(iter = iter, variables = variables, set = set, index = index, inlineSimple = inlineSimple));
  end inlineRecordTupleArrayIfBody;

  function inlineRecordEquation
    "tries to inline a record equation. Removes the old equation by making it a dummy
    and appends new equations to the mutable list.
    EquationPointers.compress() should be used afterwards to remove the dummy equations."
    input output Equation eqn;
    input Expression lhs;
    input Expression rhs;
    input Iterator iter;
    input EquationAttributes attr;
    input Integer recordSize;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  protected
    Expression new_lhs, new_rhs;
    list<Pointer<Equation>> eqns;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("\n[" + getInstanceName() + "] Inlining: ");
      if not Iterator.isEmpty(iter) then
        print("{" + Iterator.toString(iter) + "} ");
      end if;
      print(Equation.toString(eqn) + "\n");
    end if;
    eqns := Pointer.access(new_eqns);
    for i in 1:recordSize loop
      new_lhs := inlineRecordConstructorExp(lhs, i, variables);
      new_rhs := inlineRecordConstructorExp(rhs, i, variables);
      eqns    := createInlinedEquation(eqns, new_lhs, new_rhs, attr, iter, variables, set, index);
    end for;
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineRecordEquation;

  function inlineTupleEquation
    "online inlines of LHS and RHS are of type Tuple"
    input output Equation eqn;
    input Expression LHS;
    input Expression RHS;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    list<Pointer<Equation>> eqns;
    list<Expression> lhs_elems, rhs_elems;
    Expression lhs, rhs;
  algorithm
    lhs_elems := getElementList(LHS);
    rhs_elems := getElementList(RHS);
    if not listEmpty(lhs_elems) and List.compareLength(lhs_elems, rhs_elems) == 0 then
      if Flags.isSet(Flags.DUMPBACKENDINLINE) then
        print("\n[" + getInstanceName() + "] Inlining: ");
        if not Iterator.isEmpty(iter) then
          print("{" + Iterator.toString(iter) + "} ");
        end if;
        print(Equation.toString(eqn) + "\n");
      end if;
      eqns := Pointer.access(new_eqns);
      for tpl in List.zip(lhs_elems, rhs_elems) loop
        (lhs, rhs) := tpl;
        // skip wild cref assignments
        if not (Expression.isWildCref(lhs) or Expression.isWildCref(rhs)) then
          eqns := createInlinedEquation(eqns, lhs, rhs, attr, iter, variables, set, index);
        end if;
      end for;
      Pointer.update(new_eqns, eqns);
      eqn := Equation.DUMMY_EQUATION();
    end if;
  end inlineTupleEquation;

  function inlineArrayEquation
    "inlines array equations of the form {a, b, c, ...} = {d, e, f, ...}
    to a = d; and so on. Also inlines them if inside for-equation or nested arrays.
    ToDo: inside When/If"
    input output Equation eqn;
    input array<Expression> lhs_elements;
    input array<Expression> rhs_elements;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    list<Pointer<Equation>> eqns;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("\n[" + getInstanceName() + "] Inlining: ");
      if not Iterator.isEmpty(iter) then
        print("{" + Iterator.toString(iter) + "} ");
      end if;
      print(Equation.toString(eqn) + "\n");
    end if;
    eqns := Pointer.access(new_eqns);
    for i in 1: arrayLength(lhs_elements) loop
      eqns := createInlinedEquation(eqns, lhs_elements[i], rhs_elements[i], attr, iter, variables, set, index);
    end for;
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineArrayEquation;

  function inlineArrayConstructor
    input output Equation eqn;
    input ComponentRef cref;
    input Expression rhs;
    input list<tuple<InstNode, Expression>> iters;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    list<tuple<ComponentRef, Expression, Option<Iterator>>> frames;
    list<Subscript> subs;
    Expression cref_exp, new_rhs;
    UnorderedSet<VariablePointer> local_set = UnorderedSet.new(BVariable.hash, BVariable.equalName);
    VariablePointers local_it;
    list<Pointer<Equation>> eqns;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("\n[" + getInstanceName() + "] Inlining: ");
      if not Iterator.isEmpty(iter) then
        print("{" + Iterator.toString(iter) + "} ");
      end if;
      print(Equation.toString(eqn) + "\n");
    end if;
    eqns := Pointer.access(new_eqns);

    // inline the iterators
    frames  := list(Iterator.createFrame(iter, local_set) for iter in iters);
    UnorderedSet.merge(set, local_set);

    // add the iterators to the cref
    subs      := Iterator.normalizedSubscripts(Iterator.fromFrames(frames));
    cref_exp  := Expression.fromCref(ComponentRef.mergeSubscripts(subs, cref, true));

    // lower the potentiall new iterators
    local_it  := VariablePointers.fromList(UnorderedSet.toList(local_set));
    cref_exp  := Expression.map(cref_exp, function BackendDAE.lowerComponentReferenceExp(variables = local_it, complete = false));
    new_rhs   := Expression.map(rhs, function BackendDAE.lowerComponentReferenceExp(variables = local_it, complete = false));

    eqns      := createInlinedEquation(eqns, cref_exp, new_rhs, attr, Iterator.addFrames(iter, frames), variables, set, index);
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineArrayConstructor;

  function inlinePromoteCall
    "inlines a promote() call by creating a new equation for the argument. needs prior handling in function alias
    where both the promote() and its argument have been replaced by alias variables such that we can always expect
    the structure:
      FUN_2 = promote(FUN_1, DIM)
    the result will be:
      FUN_2[:,:,:,1,1,1,1] = FUN_1;
    where the amount of ':' is equal to the number of dimensions in FUN_1 and
    the amount of '1' is equal to DIM minus that number.
    "
    input output Equation eqn;
    input ComponentRef cref;
    input list<Expression> args;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    Expression arg;
    Integer n, dim_count;
    list<Subscript> subs;
    Expression lhs;
    Pointer<Equation> new_eqn;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("\n[" + getInstanceName() + "] Inlining: ");
      if not Iterator.isEmpty(iter) then
        print("{" + Iterator.toString(iter) + "} ");
      end if;
      print(Equation.toString(eqn) + "\n");
    end if;

    {arg, Expression.INTEGER(n)} := args;

    eqn := match arg
      case Expression.CREF() algorithm
        dim_count := Type.dimensionCount(ComponentRef.getSubscriptedType(arg.cref));
        if n == dim_count then
          lhs     := Expression.fromCref(cref);
        else
          subs    := Subscript.fillWithWholeLeft(List.fill(Subscript.INDEX(Expression.INTEGER(1)), n - dim_count), n);
          lhs     := Expression.fromCref(ComponentRef.mergeSubscripts(subs, cref));
        end if;
        // create the new equation
        new_eqn   := Equation.makeAssignment(lhs, arg, index, NBEquation.SIMULATION_STR, iter, attr);
        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("-- Result: " + Equation.pointerToString(new_eqn) + "\n");
        end if;
      then Pointer.access(new_eqn);
      else eqn;
    end match;
  end inlinePromoteCall;

  function inlineCatCall
    "inlines a cat() call by creating a new equation each of the arguments. needs prior handling in function alias
    where both the cat() and all its arguments have been replaced by alias variables such that we can always expect
    the structure:
      FUN_X = cat(DIM, FUN_1, FUN_2, FUN_3, ....)
    the result will be for each scalar argument:
      FUN_X[shift + 1] = FUN_1;
    and for array argument:
      for $i0 in 1:size(FUN_2) loop
        FUN_X[shift + i0] = FUN_2[i0];
      end for;
    shift always takes the size of the sum of the previous sizes so that all replacements in total make up the size of FUN_X."
    input output Equation eqn;
    input ComponentRef cref;
    input list<Expression> args;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    Integer n, sz;
    list<Expression> rest;
    list<Pointer<Equation>> eqns;
    Type ty;
    Dimension dim;
    ComponentRef iterator_name, lhs, rhs;
    Pointer<Variable> iterator_var;
    VariablePointers update_vars;
    Expression range, subscript_exp, lhs_sub, lhs_exp, rhs_exp, shift, new_size;
    Iterator local_iter;
    Pointer<Equation> new_eqn;
    Boolean failed = false;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("\n[" + getInstanceName() + "] Inlining: ");
      if not Iterator.isEmpty(iter) then
        print("{" + Iterator.toString(iter) + "} ");
      end if;
      print(Equation.toString(eqn) + "\n");
    end if;
    eqns := Pointer.access(new_eqns);

    // split of the first argument as it is the dimension indicator
    Expression.INTEGER(n) :: rest := args;

    // create an iterator that can be used multiple times
    iterator_name := ComponentRef.makeIterator(InstNode.newUniqueIterator(), Type.INTEGER());
    iterator_var  := BackendDAE.lowerIterator(iterator_name);
    iterator_name := BVariable.getVarName(iterator_var);
    // create a variable array that is used to properly lower the variable nodes of iterators
    update_vars   := VariablePointers.fromList({iterator_var});
    UnorderedSet.add(iterator_var, set);
    // create an expression of the iterator that can be used for subscripting
    subscript_exp := Expression.fromCref(iterator_name);

    // initialize the shift at 0
    shift := Expression.INTEGER(0);

    for arg in rest loop
      failed := match arg
        case Expression.CREF(cref = rhs) guard(not failed) algorithm
          ty  := Expression.typeOf(arg);
          if Type.isArray(ty) then
            dim := Type.nthDimension(ty, n);
            sz  := Dimension.size(dim);
            // if its size one, create scalar assignment, otherwise create for-loop
            if sz <> 1 or Dimension.isResizable(dim) then
              // ARRAY
              // make a range of proper size to the rhs
              new_size    := Dimension.sizeExp(dim);
              range       := Expression.makeRange(Expression.INTEGER(1), NONE(), new_size);
              // add the new iterator
              local_iter  := Iterator.addFrames(iter, {(iterator_name, range, NONE())});
              // subscript the LHS with the shift+iterator
              lhs_sub     := if Expression.isZero(shift) then subscript_exp else Expression.MULTARY({shift, subscript_exp}, {}, Operator.makeAdd(Type.INTEGER()));
              lhs         := ComponentRef.mergeSubscripts(Subscript.fillWithWholeLeft({Subscript.INDEX(lhs_sub)}, n), cref);
              // subscript the LHS only with iterator
              rhs         := ComponentRef.mergeSubscripts(Subscript.fillWithWholeLeft({Subscript.INDEX(subscript_exp)}, n), rhs);
              // lower the iterators to add proper variable nodes
              lhs_exp     := Expression.map(Expression.fromCref(lhs), function BackendDAE.lowerComponentReferenceExp(variables = update_vars, complete = false));
              rhs_exp     := Expression.map(Expression.fromCref(rhs), function BackendDAE.lowerComponentReferenceExp(variables = update_vars, complete = false));
            else
              // SCALAR.
              // properly subscript LHS with shift
              new_size    := Expression.INTEGER(1);
              lhs_sub     := bumpShift(shift, new_size);
              lhs         := ComponentRef.mergeSubscripts(Subscript.fillWithWholeLeft({Subscript.INDEX(lhs_sub)}, n), cref);
              lhs_exp     := Expression.fromCref(lhs);
              // if its an array type RHS needs to be subscripted even though its of size 1
              rhs         := ComponentRef.mergeSubscripts(Subscript.fillWithWholeLeft({Subscript.INDEX(Expression.INTEGER(1))}, n), rhs);
              rhs_exp     := Expression.fromCref(rhs);
              // the local iterator does not add anything, just take surrounding iterator
              local_iter  := iter;
            end if;
          else
            // SCALAR
            // properly subscript LHS with shift
            new_size    := Expression.INTEGER(1);
            lhs_sub     := bumpShift(shift, new_size);
            lhs         := ComponentRef.mergeSubscripts(Subscript.fillWithWholeLeft({Subscript.INDEX(lhs_sub)}, n), cref);
            lhs_exp     := Expression.fromCref(lhs);
            rhs_exp     := Expression.fromCref(rhs);
            // the local iterator does not add anything, just take surrounding iterator
            local_iter  := iter;
          end if;

          // create the new equation
          new_eqn     := Equation.makeAssignment(lhs_exp, rhs_exp, index, NBEquation.SIMULATION_STR, local_iter, attr);

          // bump the shift adding the size of this last equation
          shift := bumpShift(shift, new_size);

          eqns := new_eqn :: eqns;
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print("-- Result: " + Equation.pointerToString(new_eqn) + "\n");
          end if;
        then false;

        // inline for literals down to element, nested arrays possible
        case Expression.ARRAY() guard(not failed and Expression.isLiteral(arg)) algorithm
          (eqns, shift) := inlineCatCallLiterals(arg, cref, iter, attr, n, index, eqns, shift);
        then false;

        else true;
      end match;
    end for;

    if not failed then
      Pointer.update(new_eqns, eqns);
      eqn := Equation.DUMMY_EQUATION();
    end if;
  end inlineCatCall;

  function inlineCatCallLiterals
    "recursively inlines arrays of literal expressions that were an argument to a cat() call"
    input Expression exp;
    input ComponentRef cref;
    input Iterator iter;
    input EquationAttributes attr;
    input Integer n;
    input Pointer<Integer> index;
    input output list<Pointer<Equation>> eqns;
    input output Expression shift;
    input list<Subscript> subs = {};
  algorithm
    () := match exp
      local
        Expression sub_idx;
        Boolean is_cat_dim;
        Subscript sub;
        ComponentRef lhs;
        Expression lhs_exp;
        Pointer<Equation> new_eqn;

      case Expression.ARRAY() algorithm
        is_cat_dim  := n == listLength(subs) + 1;
        sub_idx     := if is_cat_dim then bumpShift(shift, Expression.INTEGER(1)) else Expression.INTEGER(1);

        for elem in exp.elements loop
          sub           := Subscript.INDEX(sub_idx);
          (eqns, shift) := inlineCatCallLiterals(elem, cref, iter, attr, n, index, eqns, shift, sub :: subs);
          sub_idx       := bumpShift(sub_idx, Expression.INTEGER(1));
        end for;

        if is_cat_dim then
          shift := bumpShift(shift, Expression.INTEGER(arrayLength(exp.elements)));
        end if;
      then ();

      else algorithm
        // properly subscript LHS with shift
        lhs         := ComponentRef.mergeSubscripts(listReverse(subs), cref);
        lhs_exp     := Expression.fromCref(lhs);

        // create the new equation
        new_eqn     := Equation.makeAssignment(lhs_exp, exp, index, NBEquation.SIMULATION_STR, iter, attr);

        eqns := new_eqn :: eqns;
        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("-- Result: " + Equation.pointerToString(new_eqn) + "\n");
        end if;
      then ();
    end match;
  end inlineCatCallLiterals;

  function bumpShift
    input output Expression shift;
    input Expression new_size;
  algorithm
    shift := match(shift, new_size)
      local
        Integer value;
        Expression arg;
        list<Expression> args;
      // two integers, just add them
      case (Expression.INTEGER(), Expression.INTEGER()) then Expression.INTEGER(shift.value + new_size.value);
      // add integer to multary. first argument of multary is the integer (the algorithm here makes sure of it)
      case (Expression.MULTARY(arguments = Expression.INTEGER(value) :: args), Expression.INTEGER())
        guard(Operator.getMathClassification(shift.operator) == NFOperator.MathClassification.ADDITION) algorithm
        shift.arguments := Expression.INTEGER(value + new_size.value) :: args;
      then shift;
      // add anything to multary. make sure the first argument is untouched
      case (Expression.MULTARY(arguments = arg :: args), _)
        guard(Operator.getMathClassification(shift.operator) == NFOperator.MathClassification.ADDITION) algorithm
        shift.arguments := arg :: new_size :: args;
      then shift;
      // add anything else, just create multary
      else Expression.MULTARY({shift, new_size}, {}, Operator.makeAdd(Type.INTEGER()));
    end match;
  end bumpShift;

  function createInlinedEquation
    "used for inlining record, tuple and array equations.
    tries to create new equation from lhs and rhs and applying
    the inlining methods on the results"
    input output list<Pointer<Equation>> eqns;
    input Expression lhs;
    input Expression rhs;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    Pointer<list<Pointer<Equation>>> tmp_eqns = Pointer.create({});
    Equation inlined;
    Pointer<Equation> new_eqn;
  algorithm
    new_eqn := Equation.makeAssignment(lhs, rhs, index, NBEquation.SIMULATION_STR, iter, attr);
    inlined := inlineRecordTupleArrayEquation(Pointer.access(new_eqn), iter, variables, tmp_eqns, set, index, false);
    eqns := match inlined
      case Equation.DUMMY_EQUATION() then listAppend(eqns, Pointer.access(tmp_eqns));
      else algorithm
        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("-- Result: " + Equation.toString(inlined) + "\n");
        end if;
      then new_eqn :: eqns;
    end match;
  end createInlinedEquation;

  function inlineRecordConstructorExp
    "inlines record constructors in a single expression"
    input output Expression exp;
    input Integer index;
    input VariablePointers variables;
  algorithm
    exp := Expression.nthRecordElement(index, exp);
   // lower indexed record constructor elements
    exp := Expression.map(exp, inlineRecordConstructorElements);
    // lower the new component references of record attributes
    exp := Expression.map(exp, function BackendDAE.lowerComponentReferenceExp(variables = variables, complete = true));
  end inlineRecordConstructorExp;

  function inlineRecordConstructorElements
    "removes indexed constructor element calls
    Constructor(a,b,c)[2] --> b"
    input output Expression exp;
  algorithm
    exp := match exp
      local
        Expression new_exp;
        Call call;
        Function fn;

      case Expression.RECORD_ELEMENT(recordExp = Expression.CALL(call = call as Call.TYPED_CALL(fn = fn))) algorithm
        if Function.isDefaultRecordConstructor(fn) then
          new_exp := listGet(call.arguments, exp.index);
        elseif Function.isNonDefaultRecordConstructor(fn) then
          // ToDo: this has to be mapped correctly with the body.
          //   for non default record constructors its not always the
          //   case that inputs map 1:1 to attributes
          new_exp := listGet(call.arguments, exp.index);
        else
          new_exp := exp;
        end if;
      then new_exp;

      else exp;
    end match;
  end inlineRecordConstructorElements;

  function getElementList
    "used for inlining tuple equations
    returns the tuple elements of an expression"
    input Expression exp;
    output list<Expression> elements;
  algorithm
    elements := match exp
      local
        Expression sub_exp, elem;

      case Expression.TUPLE() then exp.elements;

      case Expression.TUPLE_ELEMENT(tupleExp = sub_exp as Expression.TUPLE()) algorithm
        if exp.index > listLength(sub_exp.elements) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get subscripted tuple element: " + Expression.toString(exp)});
          fail();
        else
          elem := listGet(sub_exp.elements, exp.index);
        end if;
      then {elem};

      else {};
    end match;
  end getElementList;

  function checkInline
    "checks if the function should be inlined. three properties are checked:
    A. is the inline type in the list of current stages?
    B. is it inlineable?
    C. if its default inline type: heuristic to check if its reasonable to do so
    Inline if (A and B and C). ordered for cheapest checks first"
    input Function func;
    input list<DAE.InlineType> inline_types;
    input UnorderedMap<Function, InlineRating> func_map;
    output Boolean b;
  protected
    DAE.InlineType it = Function.inlineBuiltin(func);
  algorithm
    // A and B
    b := List.contains(inline_types, it, DAEUtil.inlineTypeEqual) and functionInlineable(func);
    // C: heuristic check for default
    if b and DAEUtil.inlineTypeEqual(it, DAE.InlineType.DEFAULT_INLINE()) then
      b := defaultHeuristic(func, func_map);
    end if;
  end checkInline;

  constant Integer HEURISTIC_THRESHOLD = 10;

  function defaultHeuristic
    "heuristically determines if a function should be inlined.
    only apply to functions with inline type default."
    input Function fn;
    input UnorderedMap<Function, InlineRating> func_map;
    output Boolean b;
  algorithm
    b := InlineRating.resolve(InlineRating.fromFunction(fn, func_map)) < HEURISTIC_THRESHOLD;
  end defaultHeuristic;

  uniontype InlineRating
    "used to rate a function by how much it grows when inlining.
    collects data about how often the inputs will occur and how much constant bloating inlining would cause."
    record INLINE_RATING
      "factors for each input with an additional constant overhead."
      array<Integer> input_rating;
      Integer constant_rating;
    end INLINE_RATING;

    function toString
      input InlineRating ir;
      output String str;
    algorithm
      str := "{resolved: " + realString(resolve(ir)) + " | input: " + Array.toString(ir.input_rating, intString) + " | constant: " + intString(ir.constant_rating) + "}";
    end toString;

    function resolve
      "resolve the rating to a final single rational number"
      input InlineRating ir;
      output Real r = sum(v for v in ir.input_rating)/arrayLength(ir.input_rating) + intReal(ir.constant_rating);
    end resolve;

    function add
      "adds the rating of src to dst"
      input output InlineRating dst;
      input InlineRating src;
    algorithm
      if arrayLength(dst.input_rating) == arrayLength(src.input_rating) then
        for i in 1:arrayLength(dst.input_rating) loop
          dst.input_rating[i] := dst.input_rating[i] + src.input_rating[i];
        end for;
        dst.constant_rating := dst.constant_rating + src.constant_rating;
      else
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed because dst and src input arrays are of different length.\n"
          + "dst: " + toString(dst) + "\nsrc: " + toString(src)});
        fail();
      end if;
    end add;

    function multiply
      input output InlineRating ir;
      input Integer i;
    algorithm
      for i in 1:arrayLength(ir.input_rating) loop
        ir.input_rating[i] := i * ir.input_rating[i];
      end for;
      ir.constant_rating := i * ir.constant_rating;
    end multiply;

    function addConst
      "bumps the constant cost"
      input output InlineRating ir;
    algorithm
      ir.constant_rating := ir.constant_rating + 1;
    end addConst;

    function addMapped
      "adds the rating of src to dst mapping the interfaces correctly."
      input output InlineRating dst;
      input InlineRating src;
      input array<Expression> args;
      input UnorderedMap<ComponentRef, InlineRating> local_map;
    protected
      Pointer<InlineRating> irp = Pointer.create(InlineRating.INLINE_RATING(arrayCreate(arrayLength(dst.input_rating), 0), src.constant_rating));
    algorithm
      if arrayLength(src.input_rating) == arrayLength(args) then
        for i in 1:arrayLength(src.input_rating) loop
          if src.input_rating[i] <> 0 then
            Expression.map(args[i], function addMappedExp(i = src.input_rating[i], irp = irp, local_map = local_map));
          end if;
        end for;
        dst := add(dst, Pointer.access(irp));
      else
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed because src input array and arguments are of different length.\n"
          + "src: " + toString(src) + "\nargs: " + Array.toString(args, Expression.toString)});
        fail();
      end if;
    end addMapped;

    function addMappedExp
      "checks if a cref has a rating already and multiplies it by the local bloating"
      input output Expression exp;
      input Integer i;
      input Pointer<InlineRating> irp;
      input UnorderedMap<ComponentRef, InlineRating> local_map;
    algorithm
      () := match exp
        local
          Option<InlineRating> iro;
        case Expression.CREF() algorithm
          iro := UnorderedMap.get(exp.cref, local_map);
          if isSome(iro) then
            Pointer.update(irp, add(Pointer.access(irp), multiply(Util.getOption(iro), i)));
          end if;
        then ();
        else ();
      end match;
    end addMappedExp;

    function fromFunction
      "rates a function by analyzing the body and the local variables.
      also adds the rating to a map so each function is only rated once."
      input Function fn;
      input UnorderedMap<Function, InlineRating> func_map;
      output InlineRating ir;
    protected
      Pointer<InlineRating> irp;
      InlineRating lir;
      Integer idx=1, num_inp = listLength(fn.inputs);
      InlineRating tmp;
      UnorderedMap<ComponentRef, InlineRating> local_map = UnorderedMap.new<InlineRating>(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      // add the trivial input mappings as ratings
      for inp in fn.inputs loop
        tmp := InlineRating.INLINE_RATING(arrayCreate(num_inp, 0), 0);
        tmp.input_rating[idx] := 1;
        idx := idx + 1;
        UnorderedMap.add(ComponentRef.fromNode(inp, InstNode.getType(inp)), tmp, local_map);
      end for;

      // add the local variable ratings
      for loc in fn.locals loop
        irp := Pointer.create(InlineRating.INLINE_RATING(arrayCreate(num_inp, 0), 0));
        lir := match InstNode.getBindingExpOpt(loc)
          local
            Expression bind;
          case SOME(bind) algorithm
            Expression.fakeMap(bind, function rateExpression(func_map = func_map, local_map = local_map, irp = irp));
          then Pointer.access(irp);
          else Pointer.access(irp);
        end match;
        UnorderedMap.add(ComponentRef.fromNode(loc, InstNode.getType(loc)), lir, local_map);
      end for;

      // apply rating mapping to body
      irp := Pointer.create(InlineRating.INLINE_RATING(arrayCreate(num_inp, 0), 0));

      Expression.fakeMap(Function.getSingleBodyExp(fn), function rateExpression(func_map = func_map, local_map = local_map, irp = irp));
      ir := Pointer.access(irp);

      // also add rating to the map so it will not be rated again
      UnorderedMap.add(fn, ir, func_map);
    end fromFunction;

    function rateExpression
      "rates an expression and updates the rating pointer.
      functions are rated with the function map, component references with the local map.
      Furthermore, constants are counted."
      input output Expression exp;
      input UnorderedMap<Function, InlineRating> func_map;
      input UnorderedMap<ComponentRef, InlineRating> local_map;
      input Pointer<InlineRating> irp;
    protected
      Boolean cont;
    algorithm
      if Expression.isLiteral(exp) then
        // just count literals as constants
        Pointer.update(irp, addConst(Pointer.access(irp)));
      else
        cont := match exp
          local
            Function fn;
            Option<InlineRating> lir;

          // check if the call already has a rating. if not only rate inline type default functions
          // no-inline has no bloating (traverse the args so just put NONE())
          // if inlined assumed to not scale as well (traverse the args so just put NONE())
          case Expression.CALL() guard(functionInlineable(Call.typedFunction(exp.call))) algorithm
            fn  := Call.typedFunction(exp.call);
            lir := UnorderedMap.get(fn, func_map);
            if isSome(lir) then
              // add the found rating to the overall rating
              Pointer.update(irp, addMapped(Pointer.access(irp), Util.getOption(lir), listArray(Call.arguments(exp.call)), local_map));
              cont := false;
            elseif DAEUtil.inlineTypeEqual(Function.inlineBuiltin(fn), DAE.InlineType.DEFAULT_INLINE()) then
              // determine rating and add it to the overall rating
              Pointer.update(irp, addMapped(Pointer.access(irp), fromFunction(fn, func_map), listArray(Call.arguments(exp.call)), local_map));
              cont := false;
            else
              cont := true;
            end if;
          then cont;

          // check if the cref has a rating, otherwise count as constant
          case Expression.CREF() then match UnorderedMap.get(ComponentRef.stripSubscriptsAll(exp.cref), local_map)
            case lir as SOME(_) algorithm
              Pointer.update(irp, add(Pointer.access(irp), Util.getOption(lir)));
            then false;
            else algorithm
              Pointer.update(irp, addConst(Pointer.access(irp)));
            then false;
          end match;

          // no relevant case, traverse deeper later
          else true;
        end match;

        if cont then
          // traverse deeper if no rating was found here
          exp := Expression.mapShallow(exp, function rateExpression(func_map = func_map, local_map = local_map, irp = irp));
        end if;
      end if;
    end rateExpression;
  end InlineRating;

  annotation(__OpenModelica_Interface="nbackend");
end NBInline;
