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

encapsulated package NBInitialization
"file:        NBInitialization.mo
 package:     NBInitialization
 description: This file contains the main data types for the initialization
              process.
"

protected
  import AbsynUtil;

  // NF imports
  import Algorithm = NFAlgorithm;
  import Binding = NFBinding;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Flatten = NFFlatten;
  import NFFunction.Function;
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
  import PointerWeak;
  import NBVariable.{VariablePointer, VariablePointers, VarData};
  import Causalize = NBCausalize;
  import Inline = NBInline;
  import Jacobian = NBJacobian;
  import Module = NBModule;
  import Partitioning = NBPartitioning;
  import Replacements = NBReplacements;
  import BPartition = NBPartition;
  import NBPartition.Partition;
  import StrongComponent = NBStrongComponent;
  import Tearing = NBTearing;

  // Util imports
  import ClockIndexes;
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
          list<Pointer<Equation>> parameter_eqs, secondary_eqs, primary_aux_eqs;
          list<Pointer<Variable>> parameter_vars, secondary_vars;
          list<StrongComponent> primary_comps;

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
            (variables, initialVars, equations, initialEqs) := createStartEquations(varData.states, variables, initialVars, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, varData.aliasVars, "State");
            (variables, initialVars, equations, initialEqs) := createStartEquations(varData.algebraics, variables, initialVars, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, varData.aliasVars, "Algebraic");
            (variables, initialVars, equations, initialEqs) := createStartEquations(varData.discretes, variables, initialVars, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, varData.aliasVars, "Discrete");
            (variables, initialVars, equations, initialEqs) := createStartEquations(varData.discrete_states, variables, initialVars, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, varData.aliasVars, "Discrete State");
            (variables, initialVars, equations, initialEqs) := createStartEquations(varData.clocked_states, variables, initialVars, equations, initialEqs, eqData.uniqueIndex, algorithm_outputs, varData.aliasVars, "Clocked State");
            (parameter_eqs, parameter_vars) := createParameterEquations(varData.parameters, new_iters, eqData.uniqueIndex, {}, {});
            (parameter_eqs, parameter_vars) := createParameterEquations(varData.resizables, new_iters, eqData.uniqueIndex, parameter_eqs, parameter_vars);
            (parameter_eqs, parameter_vars) := createParameterEquations(varData.records, new_iters, eqData.uniqueIndex, parameter_eqs, parameter_vars);
            (parameter_eqs, parameter_vars) := createParameterEquations(varData.external_objects, new_iters, eqData.uniqueIndex, parameter_eqs, parameter_vars);

            // like the old backend: the primary parameters (not depending on a parameter that is not fixed)
            // are solved explicitly before the initialization, only the secondary ones are part of it
            // the function alias variables in the bindings are solved with them if possible
            (primary_comps, secondary_eqs, secondary_vars, primary_aux_eqs) := selectPrimaryParameters(parameter_eqs, parameter_vars,
              list(eqn_ptr for eqn_ptr guard(isFunctionAliasBinding(eqn_ptr)) in EquationPointers.toList(initialEqs)), EquationPointers.toList(initialEqs));
            equations   := EquationPointers.addList(parameter_eqs, equations);
            initialEqs  := EquationPointers.removeList(primary_aux_eqs, initialEqs);
            initialEqs  := EquationPointers.addList(secondary_eqs, initialEqs);
            initialVars := VariablePointers.removeList(list(BVariable.getVarPointer(Expression.toCref(Util.getOption(Equation.getLHS(Pointer.access(eqn_ptr)))), sourceInfo()) for eqn_ptr in primary_aux_eqs), initialVars);
            initialVars := VariablePointers.addList(secondary_vars, initialVars);
            if Flags.isSet(Flags.INITIALIZATION) or Flags.isSet(Flags.DUMP_BINDINGS) then
              print(List.toStringCustom(secondary_eqs, function Equation.pointerToString(str = "\t"),
                StringUtil.headline_4("Created Secondary Parameter Binding Equations (" + intString(listLength(secondary_eqs)) + "):"), "", "\n", "", false) + "\n\n");
              print(List.toStringCustom(primary_comps, function StrongComponent.toString(index = -1),
                StringUtil.headline_4("Created Primary Parameter Binding Equations (" + intString(listLength(primary_comps)) + "):"), "", "\n", "", false) + "\n\n");
            end if;

            // clone all initial variables and remove clocked variables
            clonedVars := VariablePointers.clone(initialVars);
            VariablePointers.mapRemovePtr(clonedVars, BVariable.isClocked);

            varData.variables := variables;
            varData.initials := VariablePointers.compress(clonedVars);
            eqData.equations := equations;
            eqData.initials := EquationPointers.compress(initialEqs);

            // add new iterators
            bdae.eqData := eqData;
            bdae.parameters := primary_comps;
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
    "Creates start equations from (fixed) start values."
    input VariablePointers states;
    input output VariablePointers variables;
    input output VariablePointers initialVars;
    input output EquationPointers equations;
    input output EquationPointers initialEqs;
    input Pointer<Integer> idx;
    input UnorderedSet<ComponentRef> algorithm_outputs;
    input VariablePointers aliasVars;
    input String str "only for debugging dump";
  protected
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<Variable>>> ptr_start_vars_init = Pointer.create({});
    Pointer<list<Pointer<Equation>>> ptr_start_eqs = Pointer.create({});
    list<Pointer<Equation>> start_eqs;
  algorithm
    VariablePointers.mapPtr(states, function createStartEquation(ptr_start_vars = ptr_start_vars, ptr_start_vars_init = ptr_start_vars_init, ptr_start_eqs = ptr_start_eqs, idx = idx, algorithm_outputs = algorithm_outputs, aliasVars = aliasVars));
    start_eqs := Pointer.access(ptr_start_eqs);

    variables := BVariable.VariablePointers.addList(Pointer.access(ptr_start_vars), variables);
    initialVars := BVariable.VariablePointers.addList(Pointer.access(ptr_start_vars_init), initialVars);
    equations := EquationPointers.addList(start_eqs, equations);
    initialEqs := EquationPointers.addList(start_eqs, initialEqs);

    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(start_eqs) then
      print(List.toStringCustom(start_eqs, function Equation.pointerToString(str = "\t"),
        StringUtil.headline_4("Created " + str + " Start Equations (" + intString(listLength(start_eqs)) + "):"), "", "\n", "", false) + "\n\n");
    end if;
  end createStartEquations;

  function createStartEquation
    "creates a start equation for a fixed variable."
    input Pointer<Variable> var;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars       "new start vars that are just initialized by the init xml";
    input Pointer<list<Pointer<Variable>>> ptr_start_vars_init  "new start vars that are unknowns in the system";
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs        "new start equations";
    input Pointer<Integer> idx;
    input UnorderedSet<ComponentRef> algorithm_outputs;
    input VariablePointers aliasVars;
  algorithm
    if not UnorderedSet.contains(BVariable.getVarName(var), algorithm_outputs) then
      () := match Pointer.access(var)
        local
          ComponentRef name, start_name;
          Pointer<Variable> start_var;
          Pointer<Equation> start_eq;
          EquationKind kind;
          Expression start_exp;
          Pointer<Boolean> start_ok;

        // if it is an array create for-equation (fixed or unfixed)
        case Variable.VARIABLE() guard BVariable.isArray(var) algorithm
          // the start value of a function output is the call at the start values of its arguments
          if not BVariable.isFixed(var) and isFunctionAliasOrElement(var) then
            start_ok := Pointer.create(true);
            () := match BVariable.getStartAttribute(var)
              case SOME(start_exp) guard not Expression.isLiteralXML(start_exp) algorithm
                start_exp := resolveStartCrefs(start_exp, ptr_start_vars, aliasVars, start_ok, 0);
                if Pointer.access(start_ok) then
                  Pointer.update(var, BVariable.setStartAttribute(Pointer.access(var), start_exp, true));
                end if;
              then ();
              else ();
            end match;
            if not Pointer.access(start_ok) then
              return;
            end if;
          end if;
          if BVariable.isFixed(var) then
            createStartEquationSlice(Slice.SLICE(var, {}), ptr_start_vars, ptr_start_eqs, idx, BVariable.isFixed(var));
          else
            createStartEquationSlice(Slice.SLICE(var, {}), ptr_start_vars_init, ptr_start_eqs, idx, BVariable.isFixed(var));
          end if;
        then ();

        // create fixed scalar equation
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

        // create unfixed scalar start equation
        case Variable.VARIABLE() algorithm
          () := match BVariable.getStartAttribute(var)
            local
              Expression e;
            // only create if there is a start attribute that is not literal
            case SOME(e) guard not Expression.isLiteralXML(e) algorithm
              // the start value of a function output is the call at the start values of its arguments
              start_ok := Pointer.create(true);
              if isFunctionAliasOrElement(var) then
                e := resolveStartCrefs(e, ptr_start_vars, aliasVars, start_ok, 0);
              end if;
              if Pointer.access(start_ok) then
                (_, _, start_var, start_name) := createStartVar(var, BVariable.getVarName(var), {});
                // make the new start equation
                kind := if BVariable.isContinuous(var, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
                start_eq := Equation.makeAssignment(Expression.fromCref(start_name), e, idx, NBEquation.START_STR, Iterator.EMPTY(), EquationAttributes.default(kind, true));
                Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
                // add the new variable to initial unknowns
                Pointer.update(ptr_start_vars_init, start_var :: Pointer.access(ptr_start_vars_init));
              end if;
            then ();

            else ();
          end match;
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
      print(List.toStringCustom(start_eqs, function Equation.pointerToString(str = "\t"),
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
    EquationKind kind;
    Pointer<Equation> eq;
  algorithm
    (cref, iter) := tpl;
    var_ptr := BVariable.getVarPointer(cref, sourceInfo());
    var_pre := BVariable.getVarPre(var_ptr);
    if isSome(var_pre) then
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
    ComponentRef merged_name;
  algorithm
    if BVariable.isPrevious(var_ptr) and isSome(var_pre) then
      // for previous change the rhs to the start value of the discrete state
      merged_name := BVariable.getVarName(Util.getOption(var_pre));
      merged_name := ComponentRef.mergeSubscripts(subscripts, merged_name, true, true, true);
    elseif isSome(var_pre) then
      // for vars with previous change the lhs cref to the $PRE cref
      merged_name := ComponentRef.mergeSubscripts(subscripts, name, true, true, true);
      var_ptr := Util.getOption(var_pre);
      name := BVariable.getVarName(var_ptr);
      name := ComponentRef.mergeSubscripts(subscripts, name, true, true, true);
    else
      // just apply subscripts and make start var
      name := ComponentRef.mergeSubscripts(subscripts, name, true, true, true);
      merged_name := name;
    end if;
    (start_name, start_var) := BVariable.makeStartVar(merged_name);

    // set the record parent if neccessary
    start_var := match BVariable.getParent(var_ptr)
      local
        Pointer<Variable> parent, start_parent;
      case SOME(parent) algorithm
        start_parent := match BVariable.getVarStart(parent)
          case SOME(start_parent) then start_parent;
          else algorithm
            (_, _, start_parent, _) := createStartVar(parent, BVariable.getVarName(parent), {});
          then start_parent;
        end match;
        // create the parent <-> child link
        BVariable.addRecordChild(start_parent, start_var);
        start_var := BVariable.setParent(start_var, start_parent);
      then start_var;
      else start_var;
    end match;
  end createStartVar;

  function createParameterEquations
    "creates the binding equations of the parameters and their initial unknowns"
    input VariablePointers parameters;
    input UnorderedSet<VariablePointer> new_iters;
    input Pointer<Integer> idx;
    input output list<Pointer<Equation>> parameter_eqs;
    input output list<Pointer<Variable>> initial_param_vars;
  algorithm
    for var in VariablePointers.toList(parameters) loop
      (parameter_eqs, initial_param_vars) := createParameterEquation(var, new_iters, idx, parameter_eqs, initial_param_vars);
    end for;
  end createParameterEquations;

  function selectPrimaryParameters
    "Like the old backend (Initialization.selectInitializationVariablesDAE): a parameter is secondary if it is not
    fixed or depends on a secondary parameter, all others are primary. The bindings of the primary parameters are
    sorted by their dependencies and solved explicitly before the initialization. Only bindings of the form
    p = exp are considered, all other ones (for equations, records, external objects) stay in the initialization."
    input list<Pointer<Equation>> parameter_eqs;
    input list<Pointer<Variable>> initial_param_vars;
    input list<Pointer<Equation>> aux_eqs "bindings of function alias variables";
    input list<Pointer<Equation>> initial_eqs "all equations of the initialization, what they define is not known";
    output list<StrongComponent> primary_comps = {};
    output list<Pointer<Equation>> secondary_eqs = {};
    output list<Pointer<Variable>> secondary_vars = {};
    output list<Pointer<Equation>> primary_aux_eqs = {};
  protected
    UnorderedSet<ComponentRef> primary = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual)    "solved parameters";
    UnorderedSet<ComponentRef> unresolved = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual) "parameters with a binding equation";
    UnorderedSet<ComponentRef> duplicates = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual) "variables that are defined by several equations";
    list<Pointer<Equation>> remaining = {}, next, sorted = {};
    Option<ComponentRef> name_opt;
    ComponentRef name;
    Boolean progress = true, ready;
  algorithm
    for eqn_ptr in listAppend(parameter_eqs, aux_eqs) loop
      name_opt := explicitBindingName(eqn_ptr);
      () := match name_opt
        case SOME(name) algorithm
          // a variable that is defined by several equations can not be solved explicitly
          if UnorderedSet.contains(name, unresolved) then
            UnorderedSet.add(name, duplicates);
          end if;
          UnorderedSet.add(name, unresolved);
          remaining := eqn_ptr :: remaining;
        then ();
        // the target of any other equation can not be solved explicitly here
        else algorithm
          () := match Equation.getLHS(Pointer.access(eqn_ptr))
            case SOME(Expression.CREF(cref = name)) algorithm
              UnorderedSet.add(ComponentRef.stripSubscriptsAll(name), unresolved);
            then ();
            else ();
          end match;
        then ();
      end match;
    end for;
    remaining := list(eqn_ptr for eqn_ptr guard(not isDuplicateBinding(eqn_ptr, duplicates)) in listReverse(remaining));

    // everything that is defined by an equation of the initialization is unknown until it is solved as a primary parameter
    for eqn_ptr in initial_eqs loop
      () := match Equation.getLHS(Pointer.access(eqn_ptr))
        case SOME(Expression.CREF(cref = name)) algorithm
          UnorderedSet.add(ComponentRef.stripSubscriptsAll(name), unresolved);
        then ();
        else ();
      end match;
    end for;

    // repeatedly take all bindings that only depend on primary parameters
    while progress and not listEmpty(remaining) loop
      progress := false;
      next := {};
      for eqn_ptr in remaining loop
        SOME(name) := explicitBindingName(eqn_ptr);
        ready := true;
        for dep in UnorderedSet.toList(Expression.extractCrefs(Util.getOption(Equation.getRHS(Pointer.access(eqn_ptr))))) loop
          if not isPrimaryCref(dep, primary, unresolved) then
            ready := false;
            break;
          end if;
        end for;
        if ready then
          UnorderedSet.add(name, primary);
          sorted := eqn_ptr :: sorted;
          progress := true;
        else
          next := eqn_ptr :: next;
        end if;
      end for;
      remaining := listReverse(next);
    end while;
    sorted := listReverse(sorted);

    primary_comps := list(StrongComponent.fromSolvedEquationSlice(Slice.SLICE(eqn_ptr, {})) for eqn_ptr in sorted);
    secondary_eqs := list(eqn_ptr for eqn_ptr guard(not isPrimaryBinding(eqn_ptr, primary)) in parameter_eqs);
    secondary_vars := list(var for var guard(not isSolved(ComponentRef.stripSubscriptsAll(BVariable.getVarName(var)), primary)) in initial_param_vars);
    primary_aux_eqs := list(eqn_ptr for eqn_ptr guard(isPrimaryBinding(eqn_ptr, primary)) in aux_eqs);
  end selectPrimaryParameters;

  function isFunctionAliasBinding
    "a binding aux = exp of a function alias variable"
    input Pointer<Equation> eqn_ptr;
    output Boolean b;
  algorithm
    b := match Pointer.access(eqn_ptr)
      local
        ComponentRef cref;
      case Equation.SCALAR_EQUATION(lhs = Expression.CREF(cref = cref)) then isFunctionAliasCref(cref);
      case Equation.ARRAY_EQUATION(lhs = Expression.CREF(cref = cref), recordSize = NONE()) then isFunctionAliasCref(cref);
      else false;
    end match;
  end isFunctionAliasBinding;

  function isFunctionAliasCref
    input ComponentRef cref;
    output Boolean b;
  algorithm
    b := match cref
      case ComponentRef.CREF() guard InstNode.isVar(ComponentRef.node(cref))
        then BVariable.isFunctionAlias(BVariable.getVarPointer(cref, sourceInfo()));
      else false;
    end match;
  end isFunctionAliasCref;

  function explicitBindingName
    "the (unsubscripted) parameter of a binding equation p = exp"
    input Pointer<Equation> eqn_ptr;
    output Option<ComponentRef> name;
  algorithm
    name := match Pointer.access(eqn_ptr)
      local
        ComponentRef cref;
        Type ty;
      // only a binding for a whole variable, not for a part of it or of an element of an array of components
      case Equation.SCALAR_EQUATION(lhs = Expression.CREF(cref = cref)) guard(not hasSubscripts(cref))
        then SOME(cref);
      // an array of records is inlined in the initialization, it can not be assigned as a whole
      case Equation.ARRAY_EQUATION(ty = ty, lhs = Expression.CREF(cref = cref), recordSize = NONE())
        guard(not hasSubscripts(cref) and not Type.isComplex(Type.arrayElementType(ty)))
        then SOME(cref);
      // a record bound as a whole
      case Equation.RECORD_EQUATION(lhs = Expression.CREF(cref = cref)) guard(not hasSubscripts(cref))
        then SOME(cref);
      // a for equation that binds every element of a variable once: x[i, j] = exp
      case Equation.FOR_EQUATION(body = {Equation.SCALAR_EQUATION(lhs = Expression.CREF(cref = cref))})
        guard(coversVariable(cref, Pointer.access(eqn_ptr)))
        then SOME(ComponentRef.stripSubscriptsAll(cref));
      else NONE();
    end match;
  end explicitBindingName;

  function coversVariable
    "the subscripts of the cref are distinct iterators and the equation has as many elements as the variable"
    input ComponentRef cref;
    input Equation eqn;
    output Boolean b;
  protected
    list<Subscript> subs = ComponentRef.subscriptsAllFlat(cref);
    UnorderedSet<ComponentRef> iters = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    ComponentRef iter;
    Pointer<Variable> var_ptr;
  algorithm
    // a for equation binding a field of a record (e.g. an array of records) is inlined
    // in the initialization like a whole record, it can not be assigned as a whole
    var_ptr := BVariable.getVarPointer(ComponentRef.stripSubscriptsAll(cref), sourceInfo());
    if isSome(BVariable.getParent(var_ptr)) then
      b := false;
      return;
    end if;
    b := not listEmpty(subs);
    for sub in subs loop
      if not Subscript.isIterator(sub) then
        b := false;
        break;
      end if;
      iter := Expression.toCref(Subscript.toExp(sub));
      if UnorderedSet.contains(iter, iters) then
        b := false;
        break;
      end if;
      UnorderedSet.add(iter, iters);
    end for;
    if b then
      b := Equation.size(Pointer.create(eqn)) == BVariable.size(BVariable.getVarPointer(ComponentRef.stripSubscriptsAll(cref), sourceInfo()));
    end if;
  end coversVariable;

  function hasSubscripts
    input ComponentRef cref;
    output Boolean b = not ComponentRef.isEqual(cref, ComponentRef.stripSubscriptsAll(cref));
  end hasSubscripts;

  function isDuplicateBinding
    input Pointer<Equation> eqn_ptr;
    input UnorderedSet<ComponentRef> duplicates;
    output Boolean b;
  algorithm
    b := match explicitBindingName(eqn_ptr)
      local
        ComponentRef name;
      case SOME(name) then UnorderedSet.contains(name, duplicates);
      else false;
    end match;
  end isDuplicateBinding;

  function isPrimaryBinding
    input Pointer<Equation> eqn_ptr;
    input UnorderedSet<ComponentRef> primary;
    output Boolean b;
  algorithm
    b := match explicitBindingName(eqn_ptr)
      local
        ComponentRef name;
      case SOME(name) then UnorderedSet.contains(name, primary);
      else false;
    end match;
  end isPrimaryBinding;

  function isSolved
    "the cref or one of its parents (e.g. a record) is solved as a primary parameter"
    input ComponentRef cref;
    input UnorderedSet<ComponentRef> primary;
    output Boolean b = false;
  protected
    ComponentRef parent = cref;
  algorithm
    while not ComponentRef.isEmpty(parent) loop
      if UnorderedSet.contains(parent, primary) then
        b := true;
        break;
      end if;
      parent := ComponentRef.rest(parent);
    end while;
  end isSolved;

  function isPrimaryCref
    "true if the value of the cref is known before the initialization"
    input ComponentRef cref;
    input UnorderedSet<ComponentRef> primary;
    input UnorderedSet<ComponentRef> unresolved;
    output Boolean b;
  protected
    ComponentRef name = ComponentRef.stripSubscriptsAll(cref);
    ComponentRef parent = name;
    Pointer<Variable> var_ptr;
  algorithm
    if ComponentRef.isIterator(cref) or isSolved(name, primary) then
      b := true;
    else
      // a parameter (or one of its parents) that has a binding equation which is not solved explicitly
      b := true;
      while not ComponentRef.isEmpty(parent) loop
        if UnorderedSet.contains(parent, unresolved) then
          b := false;
          break;
        end if;
        parent := ComponentRef.rest(parent);
      end while;

      // otherwise it has to be a fixed parameter or a constant (e.g. with an evaluable binding)
      if b then
        b := match cref
          case ComponentRef.CREF() guard InstNode.isVar(ComponentRef.node(cref)) algorithm
            var_ptr := BVariable.getVarPointer(cref, sourceInfo());
          then BVariable.isConst(var_ptr) or (BVariable.isParamOrConst(var_ptr) and BVariable.isFixed(var_ptr));
          else false;
        end match;
      end if;
    end if;
  end isPrimaryCref;

  function createParameterEquation
    input Pointer<Variable> var;
    input UnorderedSet<VariablePointer> new_iters;
    input Pointer<Integer> idx;
    input output list<Pointer<Equation>> parameter_eqs;
    input output list<Pointer<Variable>> initial_param_vars;
  protected
    Pointer<Variable> parent, c_var;
    PointerWeak<Variable> c_cell;
    Boolean skip;
  algorithm
    if BVariable.isConst(var) then
      // skip this variable if it is constant
      skip := true;
    else
      // check if the variable is a record element with bound parent or a record without binding
      // if the parent is not fully unknown also create individual bindings
      skip := match BVariable.getParent(var)
        case SOME(parent) then BVariable.isBound(parent) and BVariable.isKnownRecord(parent);
        else (BVariable.isRecord(var) and not BVariable.isBound(var));
      end match;
    end if;

    // do nothing if skipped
    if skip then return; end if;

    // parse known records
    if BVariable.isKnownRecord(var) then
      // only consider non-evaluable parameter bindings
      // if the record is bound or has a start value, create an equation from it, otherwise create from its children
      if not BVariable.hasEvaluableBinding(var) and (BVariable.isBound(var) or BVariable.hasStartAttr(var)) then
        initial_param_vars  := listAppend(BVariable.getRecordChildren(var), initial_param_vars);
        parameter_eqs       := Equation.generateBindingEquation(var, idx, true, new_iters) :: parameter_eqs;
      else
        for c_cell in BVariable.getRecordChildrenCells(var) loop
          c_var := PointerWeak.upgrade(c_cell);
          if BVariable.isBound(c_var) then
            BVariable.setBindingAsStart(c_var, true);
          end if;
          // Only recurse for record children; scalar children are already handled by the parameters pass
          if BVariable.isRecord(c_var) then
            (parameter_eqs, initial_param_vars) := createParameterEquation(c_var, new_iters, idx, parameter_eqs, initial_param_vars);
          end if;
        end for;
      end if;

    // all other variables that are not records
    elseif not BVariable.isRecord(var) then
      // only consider non-evaluable parameter bindings
      if not BVariable.hasEvaluableBinding(var) then
        // add variable to initial unknowns
        initial_param_vars := var :: initial_param_vars;
        if BVariable.isFixed(var) then
          parameter_eqs := Equation.generateBindingEquation(var, idx, true, new_iters) :: parameter_eqs;
        end if;
      elseif BVariable.isBound(var) then
        BVariable.setBindingAsStart(var, true);
      end if;
    end if;
  end createParameterEquation;

  function isAliasVar
    input Pointer<Variable> var_ptr;
    input VariablePointers aliasVars;
    output Boolean b = VariablePointers.containsCref(BVariable.getVarName(var_ptr), aliasVars);
  end isAliasVar;

  function isFunctionAliasOrElement
    "true for function alias variables and the elements of function alias records"
    input Pointer<Variable> var_ptr;
    output Boolean b;
  algorithm
    b := match BVariable.getParent(var_ptr)
      local
        Pointer<Variable> parent;
      case SOME(parent) then isFunctionAliasOrElement(parent);
      else BVariable.isFunctionAlias(var_ptr);
    end match;
  end isFunctionAliasOrElement;

  function resolveStartCrefs
    "Replaces the variables in a start expression by their start values, e.g. the start value of a function output
    is the function call at the start values of its arguments. Since start values can be changed after the
    compilation, the start variables ($START.x) are used and not the values.
    Sets ok to false if the expression can not be resolved."
    input Expression exp;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input VariablePointers aliasVars;
    input Pointer<Boolean> ok;
    input Integer depth;
    output Expression res;
  algorithm
    res := Expression.map(exp, function resolveStartCref(ptr_start_vars = ptr_start_vars, aliasVars = aliasVars, ok = ok, depth = depth));
  end resolveStartCrefs;

  function resolveStartCref
    input Expression exp;
    output Expression res = exp;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input VariablePointers aliasVars;
    input Pointer<Boolean> ok;
    input Integer depth;
  protected
    Pointer<Variable> var_ptr;
    Variable var;
    ComponentRef start_name;
    Pointer<Variable> start_var;
    Boolean existed;
    Option<Expression> start_opt;
  algorithm
    res := match exp
      // internal helper functions (e.g. of stream connectors) have no code outside of equations
      case Expression.CALL() guard(StringUtil.startsWith(AbsynUtil.pathFirstIdent(Call.functionName(exp.call)), "$OMC$")) algorithm
        Pointer.update(ok, false);
      then res;

      case Expression.CREF(cref = ComponentRef.CREF()) guard(not ComponentRef.isTime(exp.cref)) algorithm
        var_ptr := BVariable.getVarPointer(exp.cref, sourceInfo());
        var     := Pointer.access(var_ptr);
        if ComponentRef.isEmpty(var.name) then
          // not a variable of the system
          Pointer.update(ok, false);
        elseif VariablePointers.containsCref(ComponentRef.stripSubscriptsAll(exp.cref), aliasVars) then
          // aliases are removed, use their defining expression (e.g. x = time)
          if depth < 10 and Binding.isBound(var.binding) then
            // an element of an array alias is the same element of its defining expression
            res := Binding.getExp(var.binding);
            if ComponentRef.hasSubscripts(exp.cref) and Type.isArray(Expression.typeOf(res)) then
              res := Expression.applySubscripts(ComponentRef.subscriptsAllWithWholeFlat(exp.cref), res, true);
            end if;
            res := resolveStartCrefs(res, ptr_start_vars, aliasVars, ok, depth + 1);
          else
            Pointer.update(ok, false);
          end if;
        elseif List.any(BVariable.getRecordChildren(var_ptr), function isAliasVar(aliasVars = aliasVars)) then
          // alias records are marked as parameters after alias removal, but their elements are aliases
          Pointer.update(ok, false);
        elseif BVariable.isParamOrConst(var_ptr) or BVariable.isStart(var_ptr)
           or BVariable.isIterator(var_ptr) or BVariable.isExtObj(var_ptr) then
          // already known
        elseif BVariable.isRecord(var_ptr) or isSome(BVariable.getParent(var_ptr)) then
          // records (and their elements) can be removed as aliases from the system, referencing
          // them would bring back their record equations and unbalance the initialization
          Pointer.update(ok, false);
        elseif Type.isReal(Type.arrayElementType(Variable.typeOf(var))) and not Type.isArray(Expression.typeOf(exp)) and BVariable.isContinuous(var_ptr, true) then
          start_opt := BVariable.getStartAttribute(var_ptr);
          existed   := isSome(BVariable.getVarStart(var_ptr));
          if BVariable.isFixed(var_ptr) and isSome(start_opt) and not Expression.isLiteralXML(Util.getOption(start_opt)) then
            // fixed variables use their start expression directly, an element uses the same element of it
            if depth < 10 then
              res := Util.getOption(start_opt);
              if ComponentRef.hasSubscripts(exp.cref) and Type.isArray(Expression.typeOf(res)) then
                res := Expression.applySubscripts(ComponentRef.subscriptsAllWithWholeFlat(exp.cref), res, true);
              end if;
              res := resolveStartCrefs(res, ptr_start_vars, aliasVars, ok, depth + 1);
            else
              Pointer.update(ok, false);
            end if;
          elseif isNone(start_opt) and not existed then
            // no start value, the call would be evaluated at a meaningless zero
            Pointer.update(ok, false);
          else
            (start_name, start_var) := BVariable.makeStartVar(exp.cref);
            res := Expression.fromCref(start_name);
            // literal start values of unfixed variables have to be initialized by the init xml
            if not existed and not BVariable.isFixed(var_ptr) and (isNone(start_opt) or Expression.isLiteralXML(Util.getOption(start_opt))) then
              Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
            end if;
          end if;
        else
          Pointer.update(ok, false);
        end if;
      then res;

      else exp;
    end match;
  end resolveStartCref;

  function createStartEquationSlice
    "creates a start equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> var_slice;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars "either the new start vars initialized by init xml or intial unkowns depending on fixed=true or false";
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs  "new start equations";
    input Pointer<Integer> idx;
    input Boolean fixed;
  protected
    Expression start_exp, start_var_exp, e;
    Pointer<Variable> var_ptr, start_var;
    ComponentRef name;
    Option<Pointer<Equation>> start_eq = NONE();
    EquationKind kind;
    Iterator iterator;
    list<Pointer<Equation>> sliced_eqn;
  algorithm
    var_ptr := Slice.getT(var_slice);
    name    := BVariable.getVarName(var_ptr);
    kind := if BVariable.isContinuous(var_ptr, true) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;

    if fixed then
      start_exp := match BVariable.getStartAttribute(var_ptr)
        // create from start expression if its not a literal
        case SOME(e) guard not Expression.isLiteralXML(e) algorithm
          (start_exp, var_ptr, name, _, _, iterator) := createStartExpressionSlice(e, var_slice, var_ptr, name);
        then start_exp;

        // create a start variable if it is a literal
        else algorithm
          (start_var_exp, var_ptr, name, iterator) := createStartVariableSlice(var_slice, var_ptr, name, ptr_start_vars);
        then start_var_exp;
      end match;

      // make the new start equation
      start_eq := SOME(Equation.makeAssignment(Expression.fromCref(name, true), start_exp, idx, NBEquation.START_STR, iterator, EquationAttributes.default(kind, true)));
    else
      start_eq := match BVariable.getStartAttribute(var_ptr)
        // create from start expression only if its not literal
        case SOME(e) guard not Expression.isLiteralXML(e) algorithm
          (start_exp, var_ptr, _, start_var, name, iterator) := createStartExpressionSlice(e, var_slice, var_ptr, name);
          start_eq := SOME(Equation.makeAssignment(Expression.fromCref(name, true), start_exp, idx, NBEquation.START_STR, iterator, EquationAttributes.default(kind, true)));
          Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
        then start_eq;

        // exit the function, no start equation is created
        else NONE();
      end match;
    end if;

    if isSome(start_eq) then
      // empty list indicates full array, slice otherwise
      if not listEmpty(var_slice.indices) then
        (sliced_eqn, _) := Equation.slice(Util.getOption(start_eq), var_slice.indices);
        Pointer.update(ptr_start_eqs, listAppend(Pointer.access(ptr_start_eqs), sliced_eqn));
      else
        Pointer.update(ptr_start_eqs, Util.getOption(start_eq) :: Pointer.access(ptr_start_eqs));
      end if;
    end if;
  end createStartEquationSlice;

  function createStartExpressionSlice
    input Expression exp;
    input Slice<VariablePointer> var_slice;
    output Expression start_exp;
    input output Pointer<Variable> var_ptr;
    input output ComponentRef name;
    output Pointer<Variable> start_var;
    output ComponentRef start_cref;
    output Iterator iterator;
  algorithm
    (start_exp, iterator) := match exp
      local
        Call array_constructor;
        list<tuple<ComponentRef, Expression, Option<Iterator>>> frames;
        UnorderedMap<ComponentRef, Expression> replacements;
        InstNode old_iter;
        ComponentRef new_iter;
        list<Subscript> subscripts;

      // convert array constructor to for-equation
      case Expression.CALL(call = array_constructor as Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
        (var_ptr, name, start_var, start_cref, _, frames, iterator) := createIteratedStartCref(var_ptr, name, listLength(array_constructor.iters));
        replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        for tpl in List.zip(array_constructor.iters, frames) loop
          ((old_iter, _), (new_iter, _, _)) := tpl;
          UnorderedMap.add(ComponentRef.fromNode(old_iter, InstNode.getType(old_iter)), Expression.fromCref(new_iter), replacements);
        end for;
      then (Expression.map(array_constructor.exp, function Replacements.applySimpleExp(replacements = replacements)), iterator);

      // use the start attribute itself
      else algorithm
        if Slice.isFull(var_slice) then
          (var_ptr, name, start_var, start_cref) := createStartVar(var_ptr, name, {});
          iterator := Iterator.EMPTY();
          start_exp := exp;
        else
          (var_ptr, name, start_var, start_cref, subscripts, _, iterator) := createIteratedStartCref(var_ptr, name, 0);
          start_exp := Expression.applySubscripts(subscripts, exp, true);
        end if;
      then (start_exp, iterator);
    end match;
  end createStartExpressionSlice;

  function createStartVariableSlice
    input Slice<VariablePointer> var_slice;
    output Expression start_exp;
    input output Pointer<Variable> var_ptr;
    input output ComponentRef name;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    output Iterator iterator;
  protected
    Pointer<Variable> start_var;
    ComponentRef start_name;
    list<Subscript> subscripts;
  algorithm
    if Slice.isFull(var_slice) then
      (var_ptr, name, start_var, start_name) := createStartVar(var_ptr, name, {});
      iterator := Iterator.EMPTY();
    else
      (var_ptr, name, start_var, start_name, subscripts, _, iterator) := createIteratedStartCref(var_ptr, name, 0);
    end if;
    Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
    start_exp := Expression.fromCref(start_name);
  end createStartVariableSlice;

  protected function createIteratedStartCref
    input output Pointer<Variable> var_ptr;
    input output ComponentRef name;
    input Integer num_dim;
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
    dims        := if num_dim == 0 then dims else List.firstN(dims, num_dim);
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
      if isSome(pre) then
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
      if isSome(pre) then
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
    list<Partition> init_0;
  algorithm
    bdae := match bdae
      case BackendDAE.MAIN() algorithm
        // initial() -> false, initialSimplified() -> false
        bdae.ode        := list(Partition.mapEqn(par, function cleanupInitialCall(kind = Partition.getKind(par))) for par in bdae.ode);
        bdae.algebraic  := list(Partition.mapEqn(par, function cleanupInitialCall(kind = Partition.getKind(par))) for par in bdae.algebraic);
        bdae.ode_event  := list(Partition.mapEqn(par, function cleanupInitialCall(kind = Partition.getKind(par))) for par in bdae.ode_event);
        bdae.alg_event  := list(Partition.mapEqn(par, function cleanupInitialCall(kind = Partition.getKind(par))) for par in bdae.alg_event);
        if isSome(bdae.dae) then
          bdae.dae := SOME(list(Partition.mapEqn(par, function cleanupInitialCall(kind = Partition.getKind(par))) for par in Util.getOption(bdae.dae)));
        end if;
        // homotopy(actual, simplified) -> actual
        bdae.ode        := list(Partition.mapExp(par, function cleanupHomotopy(kind = Partition.getKind(par))) for par in bdae.ode);
        bdae.algebraic  := list(Partition.mapExp(par, function cleanupHomotopy(kind = Partition.getKind(par))) for par in bdae.algebraic);
        bdae.ode_event  := list(Partition.mapExp(par, function cleanupHomotopy(kind = Partition.getKind(par))) for par in bdae.ode_event);
        bdae.alg_event  := list(Partition.mapExp(par, function cleanupHomotopy(kind = Partition.getKind(par))) for par in bdae.alg_event);
        if isSome(bdae.dae) then
          bdae.dae := SOME(list(Partition.mapExp(par, function cleanupHomotopy(kind = Partition.getKind(par))) for par in Util.getOption(bdae.dae)));
        end if;

        // check if we have init lambda0 system
        bdae.init := list(Partition.mapExp(par, function containsLambda0(b = hasHom)) for par in bdae.init);

        // create init_0 if homotopy call exists.
        if Pointer.access(hasHom) then
          init_0 := list(Partition.setKind(Partition.clone(par, false), NBPartition.Kind.INI_0) for par in bdae.init);

          // initial() -> true, initialSimplified() -> true
          init_0 := list(Partition.mapEqn(par, function cleanupInitialCall(kind = Partition.getKind(par))) for par in init_0);
          // homotopy(actual, simplified) -> simplified
          init_0 := list(Partition.mapExp(par, function cleanupHomotopy(kind = Partition.getKind(par))) for par in init_0);

          bdae.init_0 := SOME(init_0);
        end if;

        // initial() -> true, initialSimplified() -> false
        bdae.init := list(Partition.mapEqn(par, function cleanupInitialCall(kind = Partition.getKind(par))) for par in bdae.init);

      then bdae;

      else bdae;
    end match;
  end cleanup;

  function cleanupInitialCall
    input output Equation eq;
    input BPartition.Kind kind;
  protected
    Pointer<Boolean> simplify = Pointer.create(false);

    function cleanupInitialCallExp
      input output Expression exp;
      input BPartition.Kind kind;
      input Pointer<Boolean> simplify "output, determines if when-equation should be simplified";
    algorithm
      if Expression.isCallNamed(exp, "initial") then
        exp := Expression.BOOLEAN(kind == NBPartition.Kind.INI or kind == NBPartition.Kind.INI_0);
        Pointer.update(simplify, true);
      elseif Flags.isConfigFlagSet(Flags.ALLOW_NON_STANDARD_MODELICA, "initialSimplified") and Expression.isCallNamed(exp, "initialSimplified") then
        exp := Expression.BOOLEAN(kind == NBPartition.Kind.INI_0);
        Pointer.update(simplify, true);
      end if;
    end cleanupInitialCallExp;
  algorithm
    eq := Equation.map(eq, function cleanupInitialCallExp(kind = kind, simplify = simplify));
    if Pointer.access(simplify) then
      eq := Equation.simplify(eq);
    end if;
  end cleanupInitialCall;

  function cleanupHomotopy
    input output Expression exp;
    input BPartition.Kind kind;
  algorithm
    exp := match exp
      case Expression.CALL() guard Call.isNamed(exp.call, "homotopy")
        then match kind
            case NBPartition.Kind.INI_0 then listGet(Call.arguments(exp.call), 2);
            case NBPartition.Kind.INI   then exp;
            else listHead(Call.arguments(exp.call));
          end match;
      else exp;
    end match;
  end cleanupHomotopy;

  function containsHomotopyCall
    input output Expression exp;
    input Pointer<Boolean> b;
  algorithm
    if not Pointer.access(b) and Expression.isCallNamed(exp, "homotopy") then
      Pointer.update(b, true);
    end if;
  end containsHomotopyCall;

  function containsLambda0
    input output Expression exp;
    input Pointer<Boolean> b;
  algorithm
    if not Pointer.access(b) and (
        Expression.isCallNamed(exp, "homotopy") or
        (
          Flags.isConfigFlagSet(Flags.ALLOW_NON_STANDARD_MODELICA, "initialSimplified") and
          Expression.isCallNamed(exp, "initialSimplified")
        )
      )
    then
      Pointer.update(b, true);
    end if;
  end containsLambda0;

  function minimizeHomotopySystem
    extends Module.wrapper;
  algorithm
    bdae := match bdae
      case BackendDAE.MAIN() algorithm
        if isSome(bdae.init_0) then
          // for now all strong components have homotopy if init_0 exists
          // TODO reduced analysis on what needs to be computed for homotopy
          bdae.init := list(Partition.mapStrongComponents(par, function StrongComponent.setHomotopy(homotopy = true)) for par in bdae.init);
        end if;
      then bdae;

      else bdae;
    end match;
  end minimizeHomotopySystem;

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
        Algorithm alg;

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
      case Equation.ALGORITHM(alg = alg) algorithm
        stmts := removeWhenEquationAlgorithmBody(alg.statements);
        if not listEmpty(stmts) then
          // update alg in-place to preserve original equation kind: re-evaluating via
          // makeAlgorithm would set DISCRETE if event auxiliaries (e.g. $SEV_0) are in outputs
          alg.statements := stmts;
          eqn.alg := Algorithm.setInputsOutputs(alg);
          eqn.size := sum(ComponentRef.size(out, true) for out in eqn.alg.outputs);
          new_eqn := eqn;
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
    () := match exp
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
    () := match condition
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
    () := match eqn
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

  annotation(__OpenModelica_Interface="nbackend");
end NBInitialization;
