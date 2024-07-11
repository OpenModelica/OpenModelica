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
  algorithm
    try
      bdae := match bdae
        local
          VarData varData;
          EqData eqData;
          EquationPointers clonedEqns;
          VariablePointers clonedVars;
          UnorderedMap<ComponentRef, Iterator> cref_map = UnorderedMap.new<Iterator>(ComponentRef.hash, ComponentRef.isEqual);

        case BackendDAE.MAIN( varData = varData as VarData.VAR_DATA_SIM(variables = variables, initials = initialVars),
                              eqData = eqData as EqData.EQ_DATA_SIM(equations = equations, initials = initialEqs))
          algorithm
            // create the equations from fixed variables.
            (variables, equations, initialEqs) := createStartEquations(varData.states, variables, equations, initialEqs, eqData.uniqueIndex, "State");
            (variables, equations, initialEqs) := createStartEquations(varData.discretes, variables, equations, initialEqs, eqData.uniqueIndex, "Discretes");
            (variables, equations, initialEqs) := createStartEquations(varData.discrete_states, variables, equations, initialEqs, eqData.uniqueIndex, "Discrete States");
            (variables, equations, initialEqs) := createStartEquations(varData.clocked_states, variables, equations, initialEqs, eqData.uniqueIndex, "Clocked States");
            (equations, initialEqs, initialVars) := createParameterEquations(varData.parameters, equations, initialEqs, initialVars, eqData.uniqueIndex, " ");
            (equations, initialEqs, initialVars) := createParameterEquations(varData.records, equations, initialEqs, initialVars, eqData.uniqueIndex, " Record ");
            (equations, initialEqs, initialVars) := createParameterEquations(varData.external_objects, equations, initialEqs, initialVars, eqData.uniqueIndex, " External Object ");

            // clone all simulation equations and add them to the initial equations. also remove/replace when equations and clocked equations
            clonedEqns := EquationPointers.clone(equations, false);
            clonedEqns := EquationPointers.map(clonedEqns, function removeWhenEquation(iter = Iterator.EMPTY(), cref_map = cref_map));
            EquationPointers.mapRemovePtr(clonedEqns, Equation.isClocked);
            initialEqs := EquationPointers.addList(EquationPointers.toList(initialEqs), clonedEqns);
            (equations, initialEqs) := createWhenReplacementEquations(cref_map, equations, initialEqs, eqData.uniqueIndex);

            // clone all initial variables and remove clocked variables
            clonedVars := VariablePointers.clone(initialVars, false);
            VariablePointers.mapRemovePtr(clonedVars, BVariable.isClocked);

            varData.variables := variables;
            varData.initials := clonedVars;
            eqData.equations := equations;
            eqData.initials := EquationPointers.compress(initialEqs);

            bdae.varData := varData;
            bdae.eqData := eqData;
        then bdae;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed to create initial partition!"});
        then fail();
      end match;

      // Modules
      modules := {
        (function Inline.main(inline_types = {DAE.NORM_INLINE(), DAE.BUILTIN_EARLY_INLINE(), DAE.EARLY_INLINE(), DAE.DEFAULT_INLINE()}), "Inline"),
        (function Partitioning.main(kind = NBPartition.Kind.INI),  "Partitioning"),
        (cleanup,                                                  "Cleanup"),
        (function Causalize.main(kind = NBPartition.Kind.INI),     "Causalize"),
        (function Tearing.main(kind = NBPartition.Kind.INI),       "Tearing")
      };
      (bdae, clocks) := BackendDAE.applyModules(bdae, modules, ClockIndexes.RT_CLOCK_NEW_BACKEND_INITIALIZATION);

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
    input String str "only for debugging dump";
  protected
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<Equation>>> ptr_start_eqs = Pointer.create({});
    list<Pointer<Variable>> start_vars;
    list<Pointer<Equation>> start_eqs;
  algorithm
    _ := VariablePointers.mapPtr(states, function createStartEquation(ptr_start_vars = ptr_start_vars, ptr_start_eqs = ptr_start_eqs, idx = idx));
    start_vars := Pointer.access(ptr_start_vars);
    start_eqs := Pointer.access(ptr_start_eqs);

    variables := BVariable.VariablePointers.addList(start_vars, variables);
    equations := EquationPointers.addList(start_eqs, equations);
    initialEqs := EquationPointers.addList(start_eqs, initialEqs);

    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(start_eqs) then
      print(List.toString(start_eqs, function Equation.pointerToString(str = ""),
       StringUtil.headline_4("Created " + str + " Start Equations (" + intString(listLength(start_eqs)) + "):"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createStartEquations;

  function createStartEquation
    "creates a start equation for a fixed state or discrete state."
    input Pointer<Variable> state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  algorithm
    () := match Pointer.access(state)
      local
        ComponentRef name, start_name;
        Pointer<Variable> start_var;
        Pointer<Equation> start_eq;
        EquationKind kind;
        Expression start_exp;

      // if it is an array create for equation
      case Variable.VARIABLE() guard BVariable.isFixed(state) and BVariable.isArray(state) algorithm
        createStartEquationSlice(Slice.SLICE(state, {}), ptr_start_vars, ptr_start_eqs, idx);
      then ();

      // create scalar equation
      case Variable.VARIABLE() guard BVariable.isFixed(state) algorithm
        name := BVariable.getVarName(state);
        start_exp := match BVariable.getStartAttribute(state)
          local
            Expression e;
          // use the start attribute itself if it is not a literal
          case SOME(e) guard not Expression.isLiteral(e) then e;
          else algorithm
            // create a start variable if it is a literal
            (_, name, start_var, start_name) := createStartVar(state, name, {});
            Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
          then Expression.fromCref(start_name);
        end match;

        // make the new start equation
        kind := if BVariable.isContinuous(state, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
        start_eq := Equation.makeAssignment(Expression.fromCref(name), start_exp, idx, NBEquation.START_STR, Iterator.EMPTY(), EquationAttributes.default(kind, true));
        Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
      then ();

      else ();
    end match;
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
      print(List.toString(start_eqs, function Equation.pointerToString(str = ""),
       StringUtil.headline_4("Created When Replacement Equations (" + intString(listLength(start_eqs)) + "):"), "\t", "\n\t", "", false) + "\n\n");
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
    Option<Pointer<Variable>> pre_post;
    ComponentRef pre;
    list<Subscript> subscripts;
    EquationKind kind;
    Pointer<Equation> eq;
  algorithm
    (cref, iter) := tpl;
    var_ptr := BVariable.getVarPointer(cref);
    pre_post := BVariable.getPrePost(var_ptr);
    if Util.isSome(pre_post) then
      subscripts := ComponentRef.subscriptsAllFlat(cref);
      pre := BVariable.getVarName(Util.getOption(pre_post));
      pre := ComponentRef.mergeSubscripts(subscripts, pre, true, true);
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
    Option<Pointer<Variable>> pre_post = BVariable.getPrePost(var_ptr);
    Pointer<Variable> disc_state_var;
    ComponentRef merged_name;
  algorithm
    if BVariable.isPrevious(var_ptr) and Util.isSome(pre_post) then
      // for previous change the rhs to the start value of the discrete state
      merged_name := BVariable.getVarName(Util.getOption(pre_post));
      merged_name := ComponentRef.mergeSubscripts(subscripts, merged_name, true, true);
    elseif Util.isSome(pre_post) then
      // for vars with previous change the lhs cref to the $PRE cref
      merged_name := ComponentRef.mergeSubscripts(subscripts, name, true, true);
      var_ptr := Util.getOption(pre_post);
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
    input Pointer<Integer> idx;
    input String str "only for debug";
  protected
    list<Pointer<Equation>> parameter_eqs = {};
    list<Pointer<Variable>> initial_param_vars = {};
    Pointer<Variable> parent;
    Boolean skip;
  algorithm
    for var in VariablePointers.toList(parameters) loop
      // check if the variable is a record element with bound parent or a record without binding
      skip := match BVariable.getParent(var)
        case SOME(parent) then BVariable.isBound(parent);
        else BVariable.isRecord(var) and not BVariable.isBound(var);
      end match;

      // parse records slightly different
      if BVariable.isKnownRecord(var) and not skip then
        // only consider non-evaluable parameter bindings
        if not BVariable.hasEvaluableBinding(var) then
          initial_param_vars := listAppend(BVariable.getRecordChildren(var), initial_param_vars);
          parameter_eqs := Equation.generateBindingEquation(var, idx, true) :: parameter_eqs;
        else
          for c_var in BVariable.getRecordChildren(var) loop
            BVariable.setBindingAsStart(c_var);
          end for;
        end if;

      // all other variables that are not records and not record elements to be skipped
      elseif not (BVariable.isRecord(var) or skip) then
        // only consider non-evaluable parameter bindings
        if not BVariable.hasEvaluableBinding(var) then
          // add variable to initial unknowns
          initial_param_vars := var :: initial_param_vars;
          // generate equation only if variable is fixed
          if BVariable.isFixed(var) then
            parameter_eqs := Equation.generateBindingEquation(var, idx, true) :: parameter_eqs;
          end if;
        else
          BVariable.setBindingAsStart(var);
        end if;
      end if;
    end for;
    equations := EquationPointers.addList(parameter_eqs, equations);
    initialEqs := EquationPointers.addList(parameter_eqs, initialEqs);
    initialVars := VariablePointers.addList(initial_param_vars, initialVars);
    if (Flags.isSet(Flags.INITIALIZATION) and not listEmpty(parameter_eqs)) or Flags.isSet(Flags.DUMP_BINDINGS) then
      print(List.toString(parameter_eqs, function Equation.pointerToString(str = ""),
        StringUtil.headline_4("Created" + str + "Parameter Binding Equations (" + intString(listLength(parameter_eqs)) + "):"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createParameterEquations;

  function createStartEquationSlice
    "creates a start equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> state;
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
  algorithm
    var_ptr := Slice.getT(state);
    name    := BVariable.getVarName(var_ptr);
    start_exp := match BVariable.getStartAttribute(var_ptr)
      local
        Expression e;
        list<InstNode> iterators;
        UnorderedMap<ComponentRef, Expression> replacements;
        list<Dimension> dims;
        list<ComponentRef> iter_crefs;
        list<Expression> ranges;
        list<Subscript> subscripts;
        list<tuple<ComponentRef, Expression>> frames;
        Call array_constructor;
        InstNode old_iter;
        ComponentRef new_iter;

      // convert array constructor to for-equation if elements are not a literal
      case SOME(Expression.CALL(call = array_constructor as Call.TYPED_ARRAY_CONSTRUCTOR(exp = e))) guard not Expression.isLiteral(e) algorithm

        // make unique iterators for the new for-loop
        dims        := Type.arrayDims(ComponentRef.getSubscriptedType(name));
        (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
        iter_crefs  := list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators);
        iter_crefs  := list(BackendDAE.lowerIteratorCref(iter) for iter in iter_crefs);
        subscripts  := list(Subscript.mapExp(sub, BackendDAE.lowerIteratorExp) for sub in subscripts);
        frames      := List.zip(iter_crefs, ranges);
        iterator    := Iterator.fromFrames(frames);

        // create start variable name with subscripts and create start expression
        (var_ptr, name, _ , _) := createStartVar(var_ptr, name, subscripts);
        replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        for tpl in List.zip(array_constructor.iters, frames) loop
          ((old_iter, _), (new_iter, _)) := tpl;
          UnorderedMap.add(ComponentRef.fromNode(old_iter, InstNode.getType(old_iter)), Expression.fromCref(new_iter), replacements);
        end for;
      then Expression.map(array_constructor.exp, function Replacements.applySimpleExp(replacements = replacements));

      // use the start attribute itself if it is not a literal
      case SOME(e) guard not Expression.isLiteral(e) algorithm
        (var_ptr, name, _, _) := createStartVar(var_ptr, name, {});
        iterator := Iterator.EMPTY();
      then e;

      else algorithm
        // create a start variable if it is a literal
        (var_ptr, name, start_var, start_name) := createStartVar(var_ptr, name, {});
        Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
        iterator := Iterator.EMPTY();
      then Expression.fromCref(start_name);
    end match;

    // make the new start equation
    kind := if BVariable.isContinuous(var_ptr, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
    start_eq := Equation.makeAssignment(Expression.fromCref(name, true), start_exp, idx, NBEquation.START_STR, iterator, EquationAttributes.default(kind, true));
    if not listEmpty(state.indices) then
      // empty list indicates full array, slice otherwise
      (start_eq, _, _) := Equation.slice(start_eq, state.indices, NONE(), FunctionTreeImpl.EMPTY());
    end if;
    Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
  end createStartEquationSlice;

  function createPreEquation
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
      pre := BVariable.getPrePost(var_ptr);
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
    list<tuple<ComponentRef, Expression>> frames;
    Pointer<Equation> pre_eq;
    EquationKind kind;
  algorithm
    var_ptr := Slice.getT(var_slice);
    if not BVariable.isPrevious(var_ptr) then
      pre := BVariable.getPrePost(var_ptr);
      if Util.isSome(pre) then
        name    := BVariable.getVarName(var_ptr);
        dims    := Type.arrayDims(ComponentRef.getSubscriptedType(name));
        (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
        frames  := List.zip(list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators), ranges);

        pre_name := BVariable.getVarName(Util.getOption(pre));
        pre_name := ComponentRef.mergeSubscripts(subscripts, pre_name, true, true);
        name := ComponentRef.mergeSubscripts(subscripts, name, true, true);

        kind := if BVariable.isContinuous(var_ptr, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
        pre_eq := Equation.makeAssignment(Expression.fromCref(name, true), Expression.fromCref(pre_name), idx, NBEquation.PRE_STR, Iterator.fromFrames(frames), EquationAttributes.default(kind, true));

        if not listEmpty(var_slice.indices) then
          // empty list indicates full array, slice otherwise
          (pre_eq, _, _) := Equation.slice(pre_eq, var_slice.indices, NONE(), FunctionTreeImpl.EMPTY());
        end if;
        Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
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
    exp := match exp
      local
        Expression e;
        String name;
        Call call;
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
        e := match name
          case "homotopy" algorithm
            Pointer.update(hasHom, true);
          then listGet(Call.arguments(exp.call), if init then 2 else 1);
          else exp;
        end match;
      then e;
      else exp;
    end match;
  end cleanupHomotopy;

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
    if Util.isSome(body.else_if) then
      body.else_if := SOME(removeWhenEquationIfBody(Util.getOption(body.else_if), iter, cref_map));
    end if;
  end removeWhenEquationIfBody;

  function removeWhenEquationAlgorithmBody
    input list<Statement> in_stmts;
    output list<Statement> out_stmts;
  protected
    list<list<Statement>> stmts = {};
  algorithm
    for stmt in listReverse(in_stmts) loop
      stmts := removeWhenEquationStatement(stmt) :: stmts;
    end for;
    out_stmts := List.flatten(stmts);
  end removeWhenEquationAlgorithmBody;

  function removeWhenEquationStatement
    input Statement stmt;
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
            break;
          end if;
        end for;
      then out_stmts;

      case Statement.FOR() algorithm
        for body_stmt in listReverse(stmt.body) loop
          stmts_acc := removeWhenEquationStatement(body_stmt) :: stmts_acc;
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
      case Expression.ARRAY() then List.any(arrayList(condition.elements), isInitialCall);
      // not an initial call. Ignore "and" constructs
      else false;
    end match;
  end isInitialCall;

  annotation(__OpenModelica_Interface="backend");
end NBInitialization;
