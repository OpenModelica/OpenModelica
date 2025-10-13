/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBInitialization
"file:        NBInitialization.mo
 package:     NBInitialization
 description: This file contains the main data types for the initialization
              process.
"

protected
  // NF imports
  import Algorithm = NFAlgorithm;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Flatten = NFFlatten;
  import NFFunction.Function;
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import NFInstNode.InstNode;
  import Operator = NFOperator;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes, EquationKind, Iterator, WhenEquationBody, WhenStatement, IfEquationBody};
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers, VarData};
  import Causalize = NBCausalize;
  import Inline = NBInline;
  import Jacobian = NBJacobian;
  import Module = NBModule;
  import Partitioning = NBPartitioning;
  import Replacements = NBReplacements;
  import BPartition = NBPartition;
  import NBPartition.Partition;
  import Tearing = NBTearing;

  // Util imports
  import ClockIndexes;
  import DoubleEnded;
  import Slice = NBSlice;
  import StringUtil;

public
  function main extends Module.wrapper;
  protected
    VariablePointers variables, initialVars;
    EquationPointers equations, initialEqs;
    list<tuple<Module.wrapper, String>> modules;
    list<tuple<String, Real>> clocks;
    list<String> followEquations = Flags.getConfigStringList(Flags.DEBUG_FOLLOW_EQUATIONS);
    Option<UnorderedSet<String>> eq_filter_opt;
  algorithm
    try
      bdae := match bdae
        local
          VarData varData;
          EqData eqData;
          EquationPointers clonedEqns;
          VariablePointers clonedVars;
          UnorderedSet<ComponentRef> algorithm_outputs = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedSet<VariablePointer> new_iters = UnorderedSet.new(BVariable.hash, BVariable.equalName);
          UnorderedMap<ComponentRef, Iterator> cref_map = UnorderedMap.new<Iterator>(ComponentRef.hash, ComponentRef.isEqual);

        case BackendDAE.MAIN( varData = varData as VarData.VAR_DATA_SIM(variables = variables, initials = initialVars),
                              eqData = eqData as EqData.EQ_DATA_SIM(equations = equations, initials = initialEqs))
          algorithm
            // clone all simulation equations and add them to the initial equations.
            clonedEqns := EquationPointers.clone(equations, false);
            initialEqs := EquationPointers.addList(EquationPointers.toList(initialEqs), clonedEqns);
            EquationPointers.mapRemovePtr(initialEqs, Equation.isClocked);
            EquationPointers.mapPtr(initialEqs, replaceClockedFunctionsEqn);

            //remove/replace when equations and clocked equations and remove clocked functions
            initialEqs := EquationPointers.map(initialEqs, function removeWhenEquation(iter = Iterator.EMPTY(), cref_map = cref_map));
            (equations, initialEqs) := createWhenReplacementEquations(cref_map, equations, initialEqs, eqData.uniqueIndex);

            // collect algorithm outputs and do not create start equations for them
            EquationPointers.map(initialEqs, function collectAlgorithmOutputs(outputs = algorithm_outputs));

            // create the equations from fixed variables.
            (variables, equations, initialEqs) := createStartEquations(varData.states, variables, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, "State");
            (variables, equations, initialEqs) := createStartEquations(varData.algebraics, variables, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, "Algebraic");
            (variables, equations, initialEqs) := createStartEquations(varData.discretes, variables, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, "Discrete");
            (variables, equations, initialEqs) := createStartEquations(varData.discrete_states, variables, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, "Discrete State");
            (variables, equations, initialEqs) := createStartEquations(varData.clocked_states, variables, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, "Clocked State");
            (equations, initialEqs, initialVars) := createParameterEquations(varData.parameters, equations, initialEqs, initialVars, new_iters, eqData.uniqueIndex, " ");
            (equations, initialEqs, initialVars) := createParameterEquations(varData.records, equations, initialEqs, initialVars, new_iters, eqData.uniqueIndex, " Record ");
            (equations, initialEqs, initialVars) := createParameterEquations(varData.external_objects, equations, initialEqs, initialVars, new_iters, eqData.uniqueIndex, " External Object ");

            // clone all initial variables and remove clocked variables
            clonedVars := VariablePointers.clone(initialVars, false);
            VariablePointers.mapRemovePtr(clonedVars, BVariable.isClocked);

            varData.variables := variables;
            varData.initials := VariablePointers.compress(clonedVars);
            eqData.equations := equations;
            eqData.initials := EquationPointers.compress(initialEqs);

            // add new iterators
            bdae.eqData := eqData;
        then BackendDAE.setVarData(bdae, VarData.addTypedList(varData, UnorderedSet.toList(new_iters), NBVariable.VarData.VarType.ITERATOR));

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed to create initial partition!"});
        then fail();
      end match;

      // if we filter dump for equations
      if listEmpty(followEquations) then
        eq_filter_opt := NONE();
      else
        eq_filter_opt := SOME(UnorderedSet.fromList(followEquations, stringHashDjb2, stringEqual));
      end if;

      // Modules
      modules := {
        (function BackendDAE.simplify(init = true), "Simplify"),
        (function Inline.main(inline_types = {DAE.NORM_INLINE(), DAE.BUILTIN_EARLY_INLINE(), DAE.EARLY_INLINE(), DAE.DEFAULT_INLINE()}, init = true), "Inline"),
        (function Partitioning.main(kind = NBPartition.Kind.INI),  "Partitioning"),
        (cleanup,                                                  "Cleanup"),
        (function Causalize.main(kind = NBPartition.Kind.INI),     "Causalize"),
        (function Tearing.main(kind = NBPartition.Kind.INI),       "Tearing")
      };
      (bdae, clocks) := BackendDAE.applyModules(bdae, modules, eq_filter_opt, ClockIndexes.RT_CLOCK_NEW_BACKEND_INITIALIZATION);

      if Flags.isSet(Flags.DUMP_BACKEND_CLOCKS) then
        if not listEmpty(clocks) then
          print(StringUtil.headline_4("Initialization Backend Clocks:"));
          print(stringDelimitList(list(Module.moduleClockString(clck) for clck in clocks), "\n") + "\n");
        end if;
      end if;
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed to apply modules!"});
      fail();
    end try;
  end main;

  function createStartEquations
    "Creates start equations from fixed start values."
    input VariablePointers states;
    input output VariablePointers variables;
    input output EquationPointers equations;
    input output EquationPointers initialEqs;
    input Pointer<Integer> idx;
    input UnorderedSet<ComponentRef> algorithm_outputs;
    input String str "only for debugging dump";
  protected
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<Equation>>> ptr_start_eqs = Pointer.create({});
    list<Pointer<Variable>> start_vars;
    list<Pointer<Equation>> start_eqs;
  algorithm
    _ := VariablePointers.mapPtr(states, function createStartEquation(ptr_start_vars = ptr_start_vars, ptr_start_eqs = ptr_start_eqs, idx = idx, algorithm_outputs = algorithm_outputs));
    start_vars := Pointer.access(ptr_start_vars);
    start_eqs := Pointer.access(ptr_start_eqs);

    variables := BVariable.VariablePointers.addList(start_vars, variables);
    equations := EquationPointers.addList(start_eqs, equations);
    initialEqs := EquationPointers.addList(start_eqs, initialEqs);

    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(start_eqs) then
      print(List.toString(start_eqs, function Equation.pointerToString(str = "\t"),
        StringUtil.headline_4("Created " + str + " Start Equations (" + intString(listLength(start_eqs)) + "):"), "", "\n", "", false) + "\n\n");
    end if;
  end createStartEquations;

  function createStartEquation
    "creates a start equation for a fixed variable."
    input Pointer<Variable> var;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
    input UnorderedSet<ComponentRef> algorithm_outputs;
  algorithm
    if not UnorderedSet.contains(BVariable.getVarName(var), algorithm_outputs) then
      () := match Pointer.access(var)
        local
          ComponentRef name, start_name;
          Pointer<Variable> start_var;
          Pointer<Equation> start_eq;
          EquationKind kind;
          Expression start_exp;

        // if it is an array create for equation
        case Variable.VARIABLE() guard BVariable.isFixed(var) and BVariable.isArray(var) algorithm
          createStartEquationSlice(Slice.SLICE(var, {}), ptr_start_vars, ptr_start_eqs, idx);
        then ();

        // create scalar equation
        case Variable.VARIABLE() guard BVariable.isFixed(var) algorithm
          name := BVariable.getVarName(var);
          start_exp := match BVariable.getStartAttribute(var)
            local
              Expression e;
            // use the start attribute itself if it is not a literal
            case SOME(e) guard not Expression.isLiteralXML(e) then e;
            else algorithm
              // create a start variable if it is a literal
              (_, name, start_var, start_name) := createStartVar(var, name, {});
              Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
            then Expression.fromCref(start_name);
          end match;

          // make the new start equation
          kind := if BVariable.isContinuous(var, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
          start_eq := Equation.makeAssignment(Expression.fromCref(name), start_exp, idx, NBEquation.START_STR, Iterator.EMPTY(), EquationAttributes.default(kind, true));
          Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
        then ();

        else ();
      end match;
    end if;
  end createStartEquation;

  function createWhenReplacementEquations
    "Creates start equations from fixed start values."
    input UnorderedMap<ComponentRef, Iterator> cref_map;
    input output EquationPointers equations;
    input output EquationPointers initialEqs;
    input Pointer<Integer> idx;
  protected
    Pointer<list<Pointer<Equation>>> ptr_start_eqs = Pointer.create({});
    list<Pointer<Equation>> start_eqs;
  algorithm
    for tpl in UnorderedMap.toList(cref_map) loop
      createWhenReplacementEquation(tpl, ptr_start_eqs, idx);
    end for;
    start_eqs := Pointer.access(ptr_start_eqs);

    equations := EquationPointers.addList(start_eqs, equations);
    initialEqs := EquationPointers.addList(start_eqs, initialEqs);

    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(start_eqs) then
      print(List.toString(start_eqs, function Equation.pointerToString(str = "\t"),
        StringUtil.headline_4("Created When Replacement Equations (" + intString(listLength(start_eqs)) + "):"), "", "\n", "", false) + "\n\n");
    end if;
  end createWhenReplacementEquations;

  function createWhenReplacementEquation
    "creates a start equation for a fixed state or discrete state."
    input tuple<ComponentRef, Iterator> tpl;
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  protected
    ComponentRef cref;
    Iterator iter;
    Pointer<Variable> var_ptr;
    Option<Pointer<Variable>> var_pre;
    ComponentRef pre;
    list<list<Subscript>> subscripts;
    EquationKind kind;
    Pointer<Equation> eq;
  algorithm
    (cref, iter) := tpl;
    var_ptr := BVariable.getVarPointer(cref, sourceInfo());
    var_pre := BVariable.getVarPre(var_ptr);
    if Util.isSome(var_pre) then
      pre := BVariable.getVarName(Util.getOption(var_pre));
      pre := ComponentRef.copySubscripts(cref, pre);
      kind := if BVariable.isContinuous(var_ptr, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
      eq := Equation.makeAssignment(Expression.fromCref(cref, true), Expression.fromCref(pre, true), idx, NBEquation.START_STR, iter, EquationAttributes.default(kind, true));
      Pointer.update(ptr_start_eqs, eq :: Pointer.access(ptr_start_eqs));
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " could not replace when-replacement for "
        + ComponentRef.toString(cref) + " because it has no pre-variable."});
      fail();
    end if;
  end createWhenReplacementEquation;

  function createStartVar
    "creates start variable and cref.
    for discrete states the variable itself is changed to its
    pre variable because they have to be initialized instead!.
    normal:             var = $START.var
    disc state and pre: $PRE.dst = $START.dst"
    input output Pointer<Variable> var_ptr;
    input output ComponentRef name;
    input list<Subscript> subscripts;
    output Pointer<Variable> start_var;
    output ComponentRef start_name;
  protected
    Option<Pointer<Variable>> var_pre = BVariable.getVarPre(var_ptr);
    Pointer<Variable> disc_state_var;
    ComponentRef merged_name;
  algorithm
    if BVariable.isPrevious(var_ptr) and Util.isSome(var_pre) then
      // for previous change the rhs to the start value of the discrete state
      merged_name := BVariable.getVarName(Util.getOption(var_pre));
      merged_name := ComponentRef.mergeSubscripts(subscripts, merged_name, true, true);
    elseif Util.isSome(var_pre) then
      // for vars with previous change the lhs cref to the $PRE cref
      merged_name := ComponentRef.mergeSubscripts(subscripts, name, true, true);
      var_ptr := Util.getOption(var_pre);
      name := BVariable.getVarName(var_ptr);
      name := ComponentRef.mergeSubscripts(subscripts, name, true, true);
    else
      // just apply subscripts and make start var
      name := ComponentRef.mergeSubscripts(subscripts, name, true, true);
      merged_name := name;
    end if;
    (start_name, start_var) := BVariable.makeStartVar(merged_name);
  end createStartVar;

  function createParameterEquations
    "creates parameter equations of the form param = $START.param for all fixed params."
    input VariablePointers parameters;
    input output EquationPointers equations;
    input output EquationPointers initialEqs;
    input output VariablePointers initialVars;
    input UnorderedSet<VariablePointer> new_iters;
    input Pointer<Integer> idx;
    input String str "only for debug";
  protected
    list<Pointer<Equation>> parameter_eqs = {};
    list<Pointer<Variable>> initial_param_vars = {};
    Pointer<Variable> parent;
    Boolean skip;
  algorithm
    for var in VariablePointers.toList(parameters) loop
      (parameter_eqs, initial_param_vars) := createParameterEquation(var, new_iters, idx, parameter_eqs, initial_param_vars);
    end for;
    equations := EquationPointers.addList(parameter_eqs, equations);
    initialEqs := EquationPointers.addList(parameter_eqs, initialEqs);
    initialVars := VariablePointers.addList(initial_param_vars, initialVars);
    if (Flags.isSet(Flags.INITIALIZATION) and not listEmpty(parameter_eqs)) or Flags.isSet(Flags.DUMP_BINDINGS) then
      print(List.toString(parameter_eqs, function Equation.pointerToString(str = "\t"),
        StringUtil.headline_4("Created" + str + "Parameter Binding Equations (" + intString(listLength(parameter_eqs)) + "):"), "", "\n", "", false) + "\n\n");
    end if;
  end createParameterEquations;

  function createParameterEquation
    input Pointer<Variable> var;
    input UnorderedSet<VariablePointer> new_iters;
    input Pointer<Integer> idx;
    input output list<Pointer<Equation>> parameter_eqs;
    input output list<Pointer<Variable>> initial_param_vars;
  protected
    Pointer<Variable> parent;
    Boolean skip;
  algorithm
    // check if the variable is a record element with bound parent or a record without binding
    // if the parent is not fully unknown also create individual bindings
    skip := match BVariable.getParent(var)
      case SOME(parent) then BVariable.isBound(parent) and BVariable.isKnownRecord(parent);
      else BVariable.isRecord(var) and not BVariable.isBound(var);
    end match;

    // parse records slightly different
    if BVariable.isKnownRecord(var) and not skip then
      // only consider non-evaluable parameter bindings
      if not BVariable.hasEvaluableBindingOrStart(var) then
        initial_param_vars := listAppend(BVariable.getRecordChildren(var), initial_param_vars);
        // if the record is bound or has a start value, create an equation from it, otherwise create from its children
        if BVariable.isBound(var) or BVariable.hasStartAttr(var) then
          parameter_eqs := Equation.generateBindingEquation(var, idx, true, new_iters) :: parameter_eqs;
        else
          for c_var in BVariable.getRecordChildren(var) loop
            (parameter_eqs, initial_param_vars) := createParameterEquation(c_var, new_iters, idx, parameter_eqs, initial_param_vars);
          end for;
        end if;
      else
        for c_var in BVariable.getRecordChildren(var) loop
          if BVariable.isBound(c_var) then
            BVariable.setBindingAsStart(c_var);
          end if;
          (parameter_eqs, initial_param_vars) := createParameterEquation(c_var, new_iters, idx, parameter_eqs, initial_param_vars);
        end for;
      end if;

    // all other variables that are not records and not record elements to be skipped
    elseif not (BVariable.isRecord(var) or skip) then
      // only consider non-evaluable parameter bindings
      if not BVariable.hasEvaluableBindingOrStart(var) then
        // add variable to initial unknowns
        initial_param_vars := var :: initial_param_vars;
        // generate equation only if variable is fixed
        if BVariable.isFixed(var) then
          parameter_eqs := Equation.generateBindingEquation(var, idx, true, new_iters) :: parameter_eqs;
        end if;
      elseif BVariable.isBound(var) then
        BVariable.setBindingAsStart(var);
      end if;
    end if;
  end createParameterEquation;

  function createStartEquationSlice
    "creates a start equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> var_slice;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  protected
    Expression start_exp;
    Pointer<Variable> var_ptr, start_var;
    ComponentRef name, start_name;
    Pointer<Equation> start_eq;
    EquationKind kind;
    Iterator iterator;
    list<Pointer<Equation>> sliced_eqn;
  algorithm
    var_ptr := Slice.getT(var_slice);
    name    := BVariable.getVarName(var_ptr);
    start_exp := match BVariable.getStartAttribute(var_ptr)
      local
        Expression e;
        Call array_constructor;
        list<Subscript> subscripts;
        list<tuple<ComponentRef, Expression, Option<Iterator>>> frames;
        UnorderedMap<ComponentRef, Expression> replacements;
        InstNode old_iter;
        ComponentRef new_iter;

      // convert array constructor to for-equation if elements are not a literal
      case SOME(Expression.CALL(call = array_constructor as Call.TYPED_ARRAY_CONSTRUCTOR(exp = e))) guard not Expression.isLiteralXML(e) algorithm
        (var_ptr, name, _, _, _, frames, iterator) := createIteratedStartCref(var_ptr, name);
        replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        for tpl in List.zip(array_constructor.iters, frames) loop
          ((old_iter, _), (new_iter, _, _)) := tpl;
          UnorderedMap.add(ComponentRef.fromNode(old_iter, InstNode.getType(old_iter)), Expression.fromCref(new_iter), replacements);
        end for;
      then Expression.map(array_constructor.exp, function Replacements.applySimpleExp(replacements = replacements));

      // use the start attribute itself if it is not a literal
      case SOME(e) guard not Expression.isLiteralXML(e) algorithm
        if Slice.isFull(var_slice) then
          (var_ptr, name, _, _) := createStartVar(var_ptr, name, {});
          iterator := Iterator.EMPTY();
        else
          (var_ptr, name, _, _, subscripts, _, iterator) := createIteratedStartCref(var_ptr, name);
          e := Expression.applySubscripts(subscripts, e, true);
        end if;
      then e;

      // create a start variable if it is a literal
      else algorithm
        if Slice.isFull(var_slice) then
          (var_ptr, name, start_var, start_name) := createStartVar(var_ptr, name, {});
          Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
          iterator := Iterator.EMPTY();
        else
          (var_ptr, name, start_var, start_name, subscripts, _, iterator) := createIteratedStartCref(var_ptr, name);
          Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
        end if;
      then Expression.fromCref(start_name);
    end match;

    // make the new start equation
    kind := if BVariable.isContinuous(var_ptr, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
    start_eq := Equation.makeAssignment(Expression.fromCref(name, true), start_exp, idx, NBEquation.START_STR, iterator, EquationAttributes.default(kind, true));
    if not listEmpty(var_slice.indices) then
      // empty list indicates full array, slice otherwise
      (sliced_eqn, _) := Equation.slice(start_eq, var_slice.indices);
      Pointer.update(ptr_start_eqs, listAppend(Pointer.access(ptr_start_eqs), sliced_eqn));
    else
      Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
    end if;
  end createStartEquationSlice;

  protected function createIteratedStartCref
    input output Pointer<Variable> var_ptr;
    input output ComponentRef name;
    output Pointer<Variable> start_var;
    output ComponentRef start_cref;
    output list<Subscript> subscripts;
    output list<tuple<ComponentRef, Expression, Option<Iterator>>> frames;
    output Iterator iterator;
  protected
    list<Dimension> dims;
    list<InstNode> iterators;
    list<Expression> ranges;
    list<ComponentRef> iter_crefs;
  algorithm
    // make unique iterators for the new for-loop
    dims        := Type.arrayDims(ComponentRef.getSubscriptedType(name));
    (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
    iter_crefs  := list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators);
    iter_crefs  := list(BackendDAE.lowerIteratorCref(iter) for iter in iter_crefs);
    subscripts  := list(Subscript.mapExp(sub, BackendDAE.lowerIteratorExp) for sub in subscripts);
    frames      := List.zip3(iter_crefs, ranges, List.fill(NONE(), listLength(iter_crefs)));
    iterator    := Iterator.fromFrames(frames);

    // create start variable name with subscripts and create start expression
    (var_ptr, name, start_var, start_cref) := createStartVar(var_ptr, name, subscripts);
  end createIteratedStartCref;

  public function createPreEquation
    "creates d = $PRE.d equations"
    input Pointer<Variable> var_ptr;
    input Pointer<list<Pointer<Equation>>> ptr_pre_eqs;
    input Pointer<Integer> idx;
  protected
    Option<Pointer<Variable>> pre;
    Pointer<Equation> pre_eq;
    EquationKind kind;
  algorithm
    if not BVariable.isPrevious(var_ptr) then
      pre := BVariable.getVarPre(var_ptr);
      if Util.isSome(pre) then
        kind := if BVariable.isContinuous(var_ptr, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
        pre_eq := Equation.makeAssignment(Expression.fromCref(BVariable.getVarName(var_ptr)), Expression.fromCref(BVariable.getVarName(Util.getOption(pre))), idx, NBEquation.PRE_STR, Iterator.EMPTY(), EquationAttributes.default(kind, true));
        Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
      end if;
    end if;
  end createPreEquation;

  function createPreEquationSlice
    "creates a pre equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> var_slice;
    input Pointer<list<Pointer<Equation>>> ptr_pre_eqs;
    input Pointer<Integer> idx;
  protected
    Pointer<Variable> var_ptr;
    Option<Pointer<Variable>> pre;
    ComponentRef name, pre_name;
    list<Dimension> dims;
    list<InstNode> iterators;
    list<Expression> ranges;
    list<Subscript> subscripts;
    list<tuple<ComponentRef, Expression, Option<Iterator>>> frames;
    Pointer<Equation> pre_eq;
    EquationKind kind;
    list<Pointer<Equation>> sliced_eqn;
  algorithm
    var_ptr := Slice.getT(var_slice);
    if not BVariable.isPrevious(var_ptr) then
      pre := BVariable.getVarPre(var_ptr);
      if Util.isSome(pre) then
        name    := BVariable.getVarName(var_ptr);
        dims    := Type.arrayDims(ComponentRef.getSubscriptedType(name));
        (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
        frames  := List.zip3(list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators), ranges, List.fill(NONE(), listLength(ranges)));

        pre_name := BVariable.getVarName(Util.getOption(pre));
        pre_name := ComponentRef.mergeSubscripts(subscripts, pre_name, true, true);
        name := ComponentRef.mergeSubscripts(subscripts, name, true, true);

        kind := if BVariable.isContinuous(var_ptr, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
        pre_eq := Equation.makeAssignment(Expression.fromCref(name, true), Expression.fromCref(pre_name), idx, NBEquation.PRE_STR, Iterator.fromFrames(frames), EquationAttributes.default(kind, true));

        if not listEmpty(var_slice.indices) then
          // empty list indicates full array, slice otherwise
          (sliced_eqn, _) := Equation.slice(pre_eq, var_slice.indices);
          Pointer.update(ptr_pre_eqs, listAppend(Pointer.access(ptr_pre_eqs), sliced_eqn));
        else
          Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
        end if;
      end if;
    end if;
  end createPreEquationSlice;

  function cleanup
    "removes calls from the initial problem and marks init_0"
    extends Module.wrapper;
  protected
    Pointer<Boolean> hasHom = Pointer.create(false);
  algorithm
    bdae := match bdae
      case BackendDAE.MAIN() algorithm

        // initial() -> false
        bdae.ode        := list(Partition.mapEqn(par, function cleanupInitialCall(init = false)) for par in bdae.ode);
        bdae.algebraic  := list(Partition.mapEqn(par, function cleanupInitialCall(init = false)) for par in bdae.algebraic);
        bdae.ode_event  := list(Partition.mapEqn(par, function cleanupInitialCall(init = false)) for par in bdae.ode_event);
        bdae.alg_event  := list(Partition.mapEqn(par, function cleanupInitialCall(init = false)) for par in bdae.alg_event);
        if Util.isSome(bdae.dae) then
          bdae.dae := SOME(list(Partition.mapEqn(par, function cleanupInitialCall(init = false)) for par in Util.getOption(bdae.dae)));
        end if;
        // initial() -> true
        bdae.init := list(Partition.mapEqn(par, function cleanupInitialCall(init = true)) for par in bdae.init);

        // homotopy(actual, simplified) -> actual
        bdae.ode        := list(Partition.mapExp(par, function cleanupHomotopy(init = false, hasHom = hasHom)) for par in bdae.ode);
        bdae.algebraic  := list(Partition.mapExp(par, function cleanupHomotopy(init = false, hasHom = hasHom)) for par in bdae.algebraic);
        bdae.ode_event  := list(Partition.mapExp(par, function cleanupHomotopy(init = false, hasHom = hasHom)) for par in bdae.ode_event);
        bdae.alg_event  := list(Partition.mapExp(par, function cleanupHomotopy(init = false, hasHom = hasHom)) for par in bdae.alg_event);
        if Util.isSome(bdae.dae) then
          bdae.dae := SOME(list(Partition.mapExp(par, function cleanupHomotopy(init = false, hasHom = hasHom)) for par in Util.getOption(bdae.dae)));
        end if;

        // create init_0 if homotopy call exists.
        if Pointer.access(hasHom) then
          bdae.init_0 := SOME(list(Partition.clone(par, false) for par in bdae.init));
          bdae.init_0 := SOME(list(Partition.mapExp(par, function cleanupHomotopy(init = true, hasHom = hasHom)) for par in Util.getOption(bdae.init_0)));
        end if;
      then bdae;

      else bdae;
    end match;
  end cleanup;

  function cleanupInitialCall
    input output Equation eq;
    input Boolean init;
  protected
    Pointer<Boolean> simplify = Pointer.create(false);
  algorithm
    eq := Equation.map(eq, function cleanupInitialCallExp(init = init, simplify = simplify));
    if Pointer.access(simplify) then
      eq := Equation.simplify(eq);
    end if;
  end cleanupInitialCall;

  function cleanupInitialCallExp
    input output Expression exp;
    input Boolean init;
    input Pointer<Boolean> simplify "output, determines if when-equation should be simplified";
  algorithm
    exp := match exp
      local
        Expression e;
        String name;
        Call call;
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
        e := match name
          case "initial" algorithm
            Pointer.update(simplify, true);
          then Expression.BOOLEAN(init);
          else exp;
        end match;
      then e;
      else exp;
    end match;
  end cleanupInitialCallExp;

  function cleanupHomotopy
    input output Expression exp;
    input Boolean init "if init then replace with simplified, else replace with actual";
    input Pointer<Boolean> hasHom   "output, determines if partition contains homotopy()";
  algorithm
    if Expression.isCallNamed(exp, "homotopy") then
      exp := match exp
        local
          Call call;

        case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
          Pointer.update(hasHom, true);
        then listGet(Call.arguments(exp.call), if init then 2 else 1);

        else exp;
      end match;
    end if;
  end cleanupHomotopy;

  function containsHomotopyCall
    input output Expression exp;
    input Pointer<Boolean> b;
  algorithm
    if not Pointer.access(b) then
      Pointer.update(b, Expression.isCallNamed(exp, "homotopy"));
    end if;
  end containsHomotopyCall;

  function removeWhenEquation
    "this function checks if an equation has to be removed before initialization.
    true for: when branch without condition initial()"
    input output Equation eqn;
    input Iterator iter;
    input UnorderedMap<ComponentRef, Iterator> cref_map;
  algorithm
    eqn := match eqn
      local
        Equation new_eqn;
        list<Statement> stmts;
        list<ComponentRef> lhs_crefs;
        Option<IfEquationBody> if_body;

      // reduce the body of for equations
      case Equation.FOR_EQUATION() algorithm
        eqn.body := list(removeWhenEquation(b, eqn.iter, cref_map) for b in eqn.body);
      then if List.all(eqn.body, Equation.isDummy) then Equation.DUMMY_EQUATION() else eqn;

      // reduce the body of when equations
      case Equation.WHEN_EQUATION() algorithm
        stmts := removeWhenEquationBody(SOME(eqn.body));
        if not listEmpty(stmts) then
          new_eqn := Pointer.access(Equation.makeAlgorithm(stmts, true));
          new_eqn := Equation.setResidualVar(new_eqn, Equation.getResidualVar(Pointer.create(eqn)));
        else
          // get all the discrete crefs that where in this when equation to create cref = pre.cref
          lhs_crefs := WhenEquationBody.getAllAssigned(eqn.body);
          for cref in lhs_crefs loop UnorderedMap.add(cref, iter, cref_map); end for;
          new_eqn := Equation.DUMMY_EQUATION();
        end if;
      then new_eqn;

      // reduce the body of if equations
      case Equation.IF_EQUATION() algorithm
        eqn.body := removeWhenEquationIfBody(eqn.body, iter, cref_map);
        eqn.size := IfEquationBody.size(eqn.body);
      then if eqn.size > 0 then eqn else Equation.DUMMY_EQUATION();

      // reduce the body of algorithms
      case Equation.ALGORITHM() algorithm
        stmts := removeWhenEquationAlgorithmBody(eqn.alg.statements);
        if not listEmpty(stmts) then
          new_eqn := Pointer.access(Equation.makeAlgorithm(stmts, true));
          new_eqn := Equation.setResidualVar(new_eqn, Equation.getResidualVar(Pointer.create(eqn)));
        else
          new_eqn := Equation.DUMMY_EQUATION();
        end if;
      then new_eqn;

      else eqn;
    end match;
  end removeWhenEquation;

  function removeWhenEquationBody
    input Option<WhenEquationBody> body_opt;
    output list<Statement> stmts;
  algorithm
    stmts := match body_opt
      local
        WhenEquationBody body;

      case SOME(body) algorithm
        if isInitialCall(body.condition) then
          // this is kept, return the statements
          stmts := list(WhenStatement.toStatement(st) for st in body.when_stmts);
        else
          // dig deeper
          stmts := removeWhenEquationBody(body.else_when);
        end if;
      then stmts;

      else {};
    end match;
  end removeWhenEquationBody;

  function removeWhenEquationIfBody
    input output IfEquationBody body;
    input Iterator iter;
    input UnorderedMap<ComponentRef, Iterator> cref_map;
  algorithm
    body.then_eqns := list(Pointer.apply(e, function removeWhenEquation(iter = iter, cref_map = cref_map)) for e in body.then_eqns);
    body.else_if := Util.applyOption(body.else_if, function removeWhenEquationIfBody(iter = iter, cref_map = cref_map));
  end removeWhenEquationIfBody;

  function removeWhenEquationAlgorithmBody
    input list<Statement> in_stmts;
    output list<Statement> out_stmts;
  protected
    UnorderedSet<Expression> condition_set = UnorderedSet.new(Expression.hash, Expression.isEqual);
    Pointer<list<Statement>> tail_stmts_ptr = Pointer.create({});
  algorithm
    // stage 1: remove all when statements (that not have initial() conditions) and collect removed condtitions
    out_stmts := List.flatten(list(removeWhenEquationStatement(stmt, condition_set) for stmt in in_stmts));
    // stage 2: remove all statements computing removed conditions that use a pre() variable on the rhs
    out_stmts := List.flatten(list(removeConditionEquation(stmt, condition_set, tail_stmts_ptr) for stmt in out_stmts));
    // stage 3: add all removed statements to the end of the algorithm and add pre() := post() statements for the pre() of the rhs
    out_stmts := listAppend(out_stmts, Pointer.access(tail_stmts_ptr)) annotation(__OpenModelica_DisableListAppendWarning=true);
  end removeWhenEquationAlgorithmBody;

  function removeWhenEquationStatement
    input Statement stmt;
    input UnorderedSet<Expression> condition_set;
    output list<Statement> out_stmts = {};
  algorithm
    out_stmts := match stmt
      local
        Expression cond;
        list<Statement> stmts;
        list<list<Statement>> stmts_acc = {};

      case Statement.WHEN() algorithm
        for tpl in stmt.branches loop
          (cond, stmts) := tpl;
          if isInitialCall(cond) then
            out_stmts := stmts;
          end if;
          collectNonInitial(cond, condition_set);
        end for;
      then out_stmts;

      case Statement.FOR() algorithm
        for body_stmt in listReverse(stmt.body) loop
          stmts_acc := removeWhenEquationStatement(body_stmt, condition_set) :: stmts_acc;
        end for;
        stmts := List.flatten(stmts_acc);
        if not listEmpty(stmts) then
          stmt.body := stmts;
          out_stmts := {stmt};
        else
          out_stmts := {};
        end if;
      then out_stmts;

      else {stmt};
    end match;
  end removeWhenEquationStatement;

  function removeConditionEquation
    input Statement stmt;
    input UnorderedSet<Expression> condition_set;
    input Pointer<list<Statement>> tail_stmts_ptr;
    output list<Statement> out_stmts = {};
  algorithm
    out_stmts := match stmt
      local
        UnorderedSet<ComponentRef> pre_set;
        ComponentRef post_cref;
        list<Statement> tail_stmts;

      case Statement.ASSIGNMENT() guard(UnorderedSet.contains(stmt.lhs, condition_set)) algorithm
        // this is a cse statement. if it contains a pre variable on the RHS remove and add to tail statements
        pre_set := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        Expression.map(stmt.rhs, function findPreVars(pre_set = pre_set));
        if UnorderedSet.isEmpty(pre_set) then
          out_stmts := {stmt};
        else
          tail_stmts := stmt :: Pointer.access(tail_stmts_ptr);
          for pre_cref in UnorderedSet.toList(pre_set) loop
            post_cref := BVariable.getPartnerCref(pre_cref, BVariable.getVarPre);
            tail_stmts := Statement.ASSIGNMENT(Expression.fromCref(pre_cref), Expression.fromCref(post_cref), ComponentRef.getSubscriptedType(pre_cref), DAE.emptyElementSource) :: tail_stmts;
          end for;
          Pointer.update(tail_stmts_ptr, tail_stmts);
        end if;
      then out_stmts;
      else {stmt};
    end match;
  end removeConditionEquation;

  function findPreVars
    input output Expression exp;
    input UnorderedSet<ComponentRef> pre_set;
  algorithm
    _ := match exp
      case Expression.CREF() guard(BVariable.isPrevious(BVariable.getVarPointer(exp.cref, sourceInfo()))) algorithm
        UnorderedSet.add(exp.cref, pre_set);
      then ();
      else ();
    end match;
  end findPreVars;

  function replaceClockedFunctionsEqn
    input output Pointer<Equation> eqn;
  algorithm
    Pointer.update(eqn, Equation.map(Pointer.access(eqn), replaceClockedFunctions));
  end replaceClockedFunctionsEqn;

  function replaceClockedFunctions
    input output Expression exp;
  algorithm
    exp := match exp
      local
        Call call;
      case Expression.CALL(call = call as Call.TYPED_CALL()) guard(AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn)) == "$getPart") algorithm
      then Expression.makeZero(Expression.typeOf(exp));
      else exp;
    end match;
  end replaceClockedFunctions;

  function isInitialCall
    "checks if the expression is an initial call or can be simplified to be one."
    input Expression condition;
    output Boolean b;
  algorithm
    b := match condition
      // it's an initial call -> true;
      case Expression.CALL() then Call.isNamed(condition.call, "initial");
      // it's an "or" expression, check if either argument is an initial call
      case Expression.LBINARY(operator = Operator.OPERATOR(op = NFOperator.Op.OR))
      then isInitialCall(condition.exp1) or isInitialCall(condition.exp2);
      // it's an array where any of the elements is an initialCall
      case Expression.ARRAY() then Array.any(condition.elements, isInitialCall);
      // not an initial call. Ignore "and" constructs
      else false;
    end match;
  end isInitialCall;

  function collectNonInitial
    input Expression condition;
    input UnorderedSet<Expression> condition_set;
  algorithm
    _ := match condition
      case Expression.CREF() algorithm
        UnorderedSet.add(condition, condition_set);
      then ();
      case Expression.ARRAY() algorithm
        for elem in condition.elements loop
          collectNonInitial(elem, condition_set);
        end for;
      then ();
      else ();
    end match;
  end collectNonInitial;

  function collectAlgorithmOutputs
    input output Equation eqn;
    input UnorderedSet<ComponentRef> outputs;
  algorithm
    _ := match eqn
      local
        Algorithm alg;
        list<ComponentRef> out_crefs;

      case Equation.ALGORITHM(alg = alg) algorithm
        out_crefs := List.flatten(list(BVariable.getRecordChildrenCrefOrSelf(o) for o in alg.outputs));
        for cr in out_crefs loop
          UnorderedSet.add(cr, outputs);
        end for;

      then ();
      else ();
    end match;
  end collectAlgorithmOutputs;

  annotation(__OpenModelica_Interface="backend");
end NBInitialization;
