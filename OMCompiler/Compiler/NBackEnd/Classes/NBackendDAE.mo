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
encapsulated uniontype NBackendDAE
"file:        NBackendDAE.mo
 package:     NBackendDAE
 description: This file contains the main data type for the backend containing
              all data. It further contains the lower and solve main function.
"
public
  import NBSystem;
  import NBSystem.System;
  import BVariable = NBVariable;
  import BEquation = NBEquation;
  import Jacobian = NBJacobian;
  import Events = NBEvents;
  import NFFlatten.FunctionTree;
  import NBEquation.{Equation, EquationPointers, EqData, Iterator};
  import NBVariable.{VariablePointers, VarData};

protected
  // New Frontend imports
  import Algorithm = NFAlgorithm;
  import BackendExtension = NFBackendExtension;
  import Binding = NFBinding;
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import FEquation = NFEquation;
  import FlatModel = NFFlatModel;
  import InstNode = NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // New Backend imports
  import BackendDAE = NBackendDAE;
  import Causalize = NBCausalize;
  import DetectStates = NBDetectStates;
  import DAEMode = NBDAEMode;
  import Initialization = NBInitialization;
  import NBJacobian.JacobianType;
  import Module = NBModule;
  import Partitioning = NBPartitioning;
  import RemoveSimpleEquations = NBRemoveSimpleEquations;
  import Solve = NBSolve;
  import Tearing = NBTearing;

  // Util imports
  import BuiltinSystem = System;
  import ClockIndexes;
  import Error;
  import ExecStat;
  import ExpandableArray;
  import Flags;
  import StringUtil;

public
  record MAIN
    list<System> ode                  "Systems for differential-algebraic equations";
    list<System> algebraic            "Systems for algebraic equations";
    list<System> ode_event            "Systems for differential-algebraic event iteration";
    list<System> alg_event            "Systems for algebraic event iteration";
    list<System> init                 "Systems for initialization";
    Option<list<System>> init_0       "Systems for lambda 0 (homotopy) Initialization";
    Option<list<System>> dae          "Systems for dae mode";

    VarData varData                   "Variable data.";
    EqData eqData                     "Equation data.";

    Events.EventInfo eventInfo        "contains time and state events";
    FunctionTree funcTree             "Function bodies.";
  end MAIN;

  record JACOBIAN
    String name                                 "unique matrix name";
    JacobianType jacType                        "type of jacobian";
    VarData varData                             "Variable data.";
    EqData eqData                               "Equation data.";
    Jacobian.SparsityPattern sparsityPattern    "Sparsity pattern for the jacobian";
    Jacobian.SparsityColoring sparsityColoring  "Coloring information";
  end JACOBIAN;

  record HESSIAN
    VarData varData     "Variable data.";
    EqData eqData       "Equation data.";
  end HESSIAN;

  function toString
    input BackendDAE bdae;
    input output String str = "";
  algorithm
    str := match bdae
      local
        String tmp = "";
        list<System> dae;
      case MAIN()
        algorithm
          if (listEmpty(bdae.ode) and listEmpty(bdae.algebraic) and listEmpty(bdae.ode_event) and listEmpty(bdae.alg_event))
             or not Flags.isSet(Flags.BLT_DUMP) then
            tmp := StringUtil.headline_1("BackendDAE: " + str) + "\n";
            tmp := tmp +  VarData.toString(bdae.varData, 2) + "\n" +
                          EqData.toString(bdae.eqData, 1);
          else
            tmp := tmp + System.toStringList(bdae.ode, "[ODE] Differential-Algebraic: " + str);
            tmp := tmp + System.toStringList(bdae.algebraic, "[ALG] Algebraic: " + str);
            tmp := tmp + System.toStringList(bdae.ode_event, "[ODE_EVENT] Event Handling: " + str);
            tmp := tmp + System.toStringList(bdae.alg_event, "[ALG_EVENT] Event Handling: " + str);
            tmp := tmp + System.toStringList(bdae.init, "[INI] Initialization: " + str);
            if isSome(bdae.dae) then
              SOME(dae) := bdae.dae;
              tmp := tmp + System.toStringList(dae, "[DAE] DAEMode: " + str);
            end if;
          end if;
          tmp := tmp + Events.EventInfo.toString(bdae.eventInfo);
      then tmp;

      case JACOBIAN() then StringUtil.headline_1("Jacobian " + bdae.name + ": " + str) + "\n" +
                              VarData.toString(bdae.varData, 1) + "\n" +
                              EqData.toString(bdae.eqData, 1) + "\n" +
                              Jacobian.SparsityPattern.toString(bdae.sparsityPattern, bdae.sparsityColoring);

      case HESSIAN() then StringUtil.headline_1("Hessian: " + str) + "\n" +
                              VarData.toString(bdae.varData, 1) + "\n" +
                              EqData.toString(bdae.eqData, 1);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end toString;

  function getVarData
    input BackendDAE bdae;
    output VarData varData;
  algorithm
    varData := match bdae
      case MAIN() then bdae.varData;
      case JACOBIAN() then bdae.varData;
      case HESSIAN() then bdae.varData;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end getVarData;

  function getEqData
    input BackendDAE bdae;
    output EqData eqData;
  algorithm
    eqData := match bdae
      case MAIN() then bdae.eqData;
      case JACOBIAN() then bdae.eqData;
      case HESSIAN() then bdae.eqData;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end getEqData;

  function getFunctionTree
    input BackendDAE bdae;
    output FunctionTree funcTree;
  algorithm
    funcTree := match bdae
      case MAIN(funcTree = funcTree) then funcTree;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed! Only the record type MAIN() has a function tree."});
      then fail();
    end match;
  end getFunctionTree;

  function lower
    "This function transforms the FlatModel structure to BackendDAE."
    input FlatModel flatModel;
    input FunctionTree funcTree;
    output BackendDAE bdae;
  protected
    VarData variableData;
    EqData equationData;
    Events.EventInfo eventInfo = Events.EventInfo.empty();
  algorithm
    variableData := lowerVariableData(flatModel.variables);
    (equationData, variableData) := lowerEquationData(flatModel.equations, flatModel.algorithms, flatModel.initialEquations, flatModel.initialAlgorithms, variableData);
    bdae := MAIN({}, {}, {}, {}, {}, NONE(), NONE(), variableData, equationData, eventInfo, funcTree);
  end lower;

  function main
    input output BackendDAE bdae;
  protected
    list<tuple<Module.wrapper, String>> preOptModules;
    list<tuple<Module.wrapper, String>> mainModules;
    list<tuple<Module.wrapper, String>> postOptModules;
    list<tuple<String, Real>> preOptClocks;
    list<tuple<String, Real>> mainClocks;
    list<tuple<String, Real>> postOptClocks;
  algorithm
    // Pre-Partitioning Modules
    // (do not change order SIMPLIFY -> RSE -> EVENTS -> DETECTSTATES)
    preOptModules := {
      (simplify,                    "simplify"),
      (RemoveSimpleEquations.main,  "RemoveSimpleEquations"),
      (Events.main,                 "Events"),
      (DetectStates.main,           "DetectStates")
    };

    mainModules := {
      (function Partitioning.main(systemType = NBSystem.SystemType.ODE),  "Partitioning"),
      (function Causalize.main(systemType = NBSystem.SystemType.ODE),     "Causalize"),
      (Initialization.main,                                               "Initialization")
    };

    if Flags.getConfigBool(Flags.DAE_MODE) then
      mainModules := (DAEMode.main, "DAE-Mode") :: mainModules;
    end if;

    postOptModules := {
      (function Tearing.main(systemType = NBSystem.SystemType.ODE),   "Tearing"),
      (Partitioning.categorize,                                       "Categorize"),
      (Solve.main,                                                    "Solve"),
      (function Jacobian.main(systemType = NBSystem.SystemType.ODE),  "Jacobian")
    };

    (bdae, preOptClocks)  := applyModules(bdae, preOptModules, ClockIndexes.RT_CLOCK_NEW_BACKEND_MODULE);
    (bdae, mainClocks)    := applyModules(bdae, mainModules, ClockIndexes.RT_CLOCK_NEW_BACKEND_MODULE);
    (bdae, postOptClocks) := applyModules(bdae, postOptModules, ClockIndexes.RT_CLOCK_NEW_BACKEND_MODULE);
    if Flags.isSet(Flags.DUMP_BACKEND_CLOCKS) then
      if not listEmpty(preOptClocks) then
        print(StringUtil.headline_4("Pre-Opt Backend Clocks:"));
        print(stringDelimitList(list(Module.moduleClockString(clck) for clck in preOptClocks), "\n") + "\n");
      end if;
      if not listEmpty(mainClocks) then
        print(StringUtil.headline_4("Main Backend Clocks:"));
        print(stringDelimitList(list(Module.moduleClockString(clck) for clck in mainClocks), "\n") + "\n");
      end if;
      if not listEmpty(postOptClocks) then
        print(StringUtil.headline_4("Post-Opt Backend Clocks:"));
        print(stringDelimitList(list(Module.moduleClockString(clck) for clck in postOptClocks), "\n") + "\n\n");
      end if;
    end if;
  end main;

  function applyModules
    input output BackendDAE bdae;
    input list<tuple<Module.wrapper, String>> modules;
    input Integer clock_idx;
    output list<tuple<String, Real>> module_clocks = {};
  protected
    Module.wrapper func;
    String name, debugStr;
    Real clock_time;
    Integer length;
  algorithm
    for module in modules loop
      (func, name) := module;
      if clock_idx <> -1 then
        BuiltinSystem.realtimeClear(clock_idx);
        BuiltinSystem.realtimeTick(clock_idx);
        bdae := func(bdae);
        clock_time := BuiltinSystem.realtimeTock(clock_idx);
        ExecStat.execStat(name);
        module_clocks := (name, clock_time) :: module_clocks;
        if Flags.isSet(Flags.FAILTRACE) then
          debugStr := "[failtrace] ........ [" + ClockIndexes.toString(clock_idx) + "] " + name;
          debugStr := debugStr + StringUtil.repeat(".", 60 - stringLength(debugStr)) + " " + realString(clock_time) + "s\n";
          print(debugStr);
        end if;
      else
        bdae := func(bdae);
      end if;

      if Flags.isSet(Flags.OPT_DAE_DUMP) or (Flags.isSet(Flags.BLT_DUMP) and (name == "Causalize" or name == "Solve")) then
        print(toString(bdae, "(" + name + ")"));
      end if;
    end for;

    module_clocks := listReverse(module_clocks);
  end applyModules;

  function simplify
    "ToDo: add simplification for bindings"
    input output BackendDAE bdae;
  algorithm
    // no output needed, all pointers
    _ := match bdae
      local
        EquationPointers equations;
      case MAIN(eqData = BEquation.EQ_DATA_SIM(equations = equations)) algorithm
        _ := EquationPointers.map(equations, function Equation.simplify(name = getInstanceName(), indent = ""));
      then ();
      else ();
    end match;
  end simplify;

  function getLoopResiduals
    input BackendDAE bdae;
    output VariablePointers residuals;
  algorithm
    residuals := match bdae
      local
        list<Pointer<Variable>> var_lst = {};

      case MAIN() algorithm
        for syst in bdae.ode loop
          var_lst := listAppend(System.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.algebraic loop
          var_lst := listAppend(System.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.ode_event loop
          var_lst := listAppend(System.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.alg_event loop
          var_lst := listAppend(System.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.init loop
          var_lst := listAppend(System.getLoopResiduals(syst), var_lst);
        end for;
        residuals := VariablePointers.fromList(var_lst);
      then residuals;

      else VariablePointers.empty();
    end match;
  end getLoopResiduals;

protected
  function lowerVariableData
    "Lowers all variables to backend structure.
    kabdelhak: Splitting up the creation of the variable array and the variable
    pointer arrays in two steps is slightly less effective, but way more readable
    and maintainable."
    input list<Variable> varList;
    output VarData variableData;
  protected
    Variable lowVar;
    Pointer<Variable> lowVar_ptr, time_ptr, dummy_ptr;
    list<Pointer<Variable>> unknowns_lst = {}, knowns_lst = {}, initials_lst = {}, auxiliaries_lst = {}, aliasVars_lst = {}, nonTrivialAlias_lst = {};
    list<Pointer<Variable>> states_lst = {}, derivatives_lst = {}, algebraics_lst = {}, discretes_lst = {}, previous_lst = {};
    list<Pointer<Variable>> parameters_lst = {}, constants_lst = {};
    VariablePointers variables, unknowns, knowns, initials, auxiliaries, aliasVars, nonTrivialAlias;
    VariablePointers states, derivatives, algebraics, discretes, previous;
    VariablePointers parameters, constants;
    Boolean scalarized = Flags.isSet(Flags.NF_SCALARIZE);
  algorithm
    // instantiate variable data (with one more space for time variable);
    variables := VariablePointers.empty(listLength(varList) + 1, scalarized);

    // create dummy and time var and add then
    // needed to make function BVariable.getVarPointer() more universally applicable
    dummy_ptr := Pointer.create(NBVariable.DUMMY_VARIABLE);
    time_ptr := BVariable.createTimeVar();
    variables := VariablePointers.add(dummy_ptr, variables);
    variables := VariablePointers.add(time_ptr, variables);

    // routine to prepare the lists for pointer arrays
    for var in listReverse(varList) loop
      lowVar_ptr := lowerVariable(var);
      lowVar := Pointer.access(lowVar_ptr);
      variables := VariablePointers.add(lowVar_ptr, variables);
      _ := match lowVar.backendinfo.varKind

        case BackendExtension.ALGEBRAIC() guard(Variable.isTopLevelInput(var)) algorithm
          algebraics_lst := lowVar_ptr :: algebraics_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        case BackendExtension.DISCRETE() guard(Variable.isTopLevelInput(var)) algorithm
          discretes_lst := lowVar_ptr :: discretes_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        case BackendExtension.ALGEBRAIC() algorithm
          algebraics_lst := lowVar_ptr :: algebraics_lst;
          unknowns_lst := lowVar_ptr :: unknowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case BackendExtension.STATE() algorithm
          states_lst := lowVar_ptr :: states_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case BackendExtension.STATE_DER() algorithm
          derivatives_lst := lowVar_ptr :: derivatives_lst;
          unknowns_lst := lowVar_ptr :: unknowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case BackendExtension.DISCRETE() algorithm
          discretes_lst := lowVar_ptr :: discretes_lst;
          unknowns_lst := lowVar_ptr :: unknowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case BackendExtension.PREVIOUS() algorithm
          previous_lst := lowVar_ptr :: previous_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case BackendExtension.PARAMETER() algorithm
          parameters_lst := lowVar_ptr :: parameters_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        case BackendExtension.CONSTANT() algorithm
          constants_lst := lowVar_ptr :: constants_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        /* other cases should not occur up until now */
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + Variable.toString(var)});
        then fail();

      end match;
    end for;

    // create pointer arrays
    unknowns        := VariablePointers.fromList(unknowns_lst, scalarized);
    knowns          := VariablePointers.fromList(knowns_lst, scalarized);
    initials        := VariablePointers.fromList(initials_lst, scalarized);
    auxiliaries     := VariablePointers.fromList(auxiliaries_lst, scalarized);
    aliasVars       := VariablePointers.fromList(aliasVars_lst, scalarized);
    nonTrivialAlias := VariablePointers.fromList(nonTrivialAlias_lst, scalarized);

    states          := VariablePointers.fromList(states_lst, scalarized);
    derivatives     := VariablePointers.fromList(derivatives_lst, scalarized);
    algebraics      := VariablePointers.fromList(algebraics_lst, scalarized);
    discretes       := VariablePointers.fromList(discretes_lst, scalarized);
    previous        := VariablePointers.fromList(previous_lst, scalarized);

    parameters      := VariablePointers.fromList(parameters_lst, scalarized);
    constants       := VariablePointers.fromList(constants_lst, scalarized);

    /* lower the variable bindings */
    VariablePointers.map(variables, function lowerVariableBinding(variables = variables));

    /* create variable data */
    variableData := BVariable.VAR_DATA_SIM(variables, unknowns, knowns, initials, auxiliaries, aliasVars, nonTrivialAlias,
                    derivatives, algebraics, discretes, previous, states, parameters, constants);
  end lowerVariableData;

  function lowerVariable
    input Variable var;
    output Pointer<Variable> var_ptr;
  protected
    BackendExtension.VariableAttributes attributes;
    BackendExtension.VariableKind varKind;
  algorithm
    // ToDo! extract tearing select option
    try
      attributes := BackendExtension.VariableAttributes.create(var.typeAttributes, var.ty, var.attributes, var.children, var.comment);

      // only change varKind if unset (Iterators are set before)
      var.backendinfo := match var.backendinfo
        case BackendExtension.BACKEND_INFO(varKind = BackendExtension.FRONTEND_DUMMY()) algorithm
          (varKind, attributes) := lowerVariableKind(Variable.variability(var), attributes, var.ty);
        then BackendExtension.BACKEND_INFO(varKind, attributes);
        else BackendExtension.BackendInfo.setAttributes(var.backendinfo, attributes);
      end match;

      // Remove old type attribute information since it has been converted.
      var.typeAttributes := {};

      // This creates a cyclic dependency, be aware of that!
      (var_ptr, _) := BVariable.makeVarPtrCyclic(var, var.name);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + Variable.toString(var)});
      fail();
    end try;
  end lowerVariable;

  function lowerIterator
    input ComponentRef iterator;
    output Pointer<Variable> var_ptr = lowerVariable(Variable.fromCref(iterator));
  end lowerIterator;

  function lowerVariableKind
    "ToDo: Merge this part from old backend conversion:
      /* Consider toplevel inputs as known unless they are protected. Ticket #5591 */
      false := DAEUtil.topLevelInput(inComponentRef, inVarDirection, inConnectorType, protection);"
    input Prefixes.Variability variability;
    output BackendExtension.VariableKind varKind;
    input output BackendExtension.VariableAttributes attributes;
    input Type ty;
  algorithm
    varKind := match(variability, attributes, ty)

      // variable -> artificial state if it has stateSelect = StateSelect.always
      case (NFPrefixes.Variability.CONTINUOUS, BackendExtension.VAR_ATTR_REAL(stateSelect = SOME(NFBackendExtension.StateSelect.ALWAYS)), _)
        guard(variability == NFPrefixes.Variability.CONTINUOUS)
      then BackendExtension.STATE(1, NONE(), false);

      // variable -> artificial state if it has stateSelect = StateSelect.prefer
      /* I WANT TO REMOVE THIS AND CATCH IT PROPERLY IN STATE SELECTION!
      case (Prefixes.Variability.CONTINUOUS(), SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.PREFER()))))
      then BackendExtension.STATE(1, NONE(), false);
      */

      // is this just a hack? Do we need those cases, or do we need even more?
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.BOOLEAN())     then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.INTEGER())     then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.ENUMERATION()) then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, _)                  then BackendExtension.ALGEBRAIC();

      case (NFPrefixes.Variability.DISCRETE, _, _)                    then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.IMPLICITLY_DISCRETE, _, _)         then BackendExtension.DISCRETE();

      case (NFPrefixes.Variability.PARAMETER, _, _)                   then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.STRUCTURAL_PARAMETER, _, _)        then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.NON_STRUCTURAL_PARAMETER, _, _)    then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.CONSTANT, _, _)                    then BackendExtension.CONSTANT();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;

    // make adjustments to attributes based on variable kind
    attributes := match varKind
      case BackendExtension.PARAMETER() then BackendExtension.VariableAttributes.setFixedIfNone(attributes);
      else attributes;
    end match;
  end lowerVariableKind;

  function lowerVariableBinding
    input output Variable var;
    input VariablePointers variables;
  algorithm
    var := match var
      local
        Binding binding;
      case Variable.VARIABLE(binding = binding as Binding.TYPED_BINDING())
        algorithm
          binding.bindingExp := Expression.map(binding.bindingExp, function lowerComponentReferenceExp(variables = variables));
          var.binding := binding;
      then var;
      else var;
    end match;
  end lowerVariableBinding;

  function lowerEquationData
    "Lowers all equations to backend structure.
    kabdelhak: Splitting up the creation of the equation array and the equation
    pointer arrays in two steps is slightly less effective, but way more readable
    and maintainable."
    input list<FEquation> eq_lst;
    input list<Algorithm> al_lst;
    input list<FEquation> init_eq_lst;
    input list<Algorithm> init_al_lst;
    output EqData eqData;
    input output VarData varData;
  protected
    list<ComponentRef> iterators = {};
    list<Pointer<Equation>> equation_lst, continuous_lst = {}, discretes_lst = {}, initials_lst = {}, auxiliaries_lst = {}, simulation_lst = {}, removed_lst = {};
    EquationPointers equations;
    Pointer<Equation> eq;
    Pointer<Integer> idx = Pointer.create(0);
  algorithm
    equation_lst := lowerEquationsAndAlgorithms(eq_lst, al_lst, init_eq_lst, init_al_lst);
    for eqn_ptr in equation_lst loop
      BEquation.Equation.createName(eqn_ptr, idx, "SIM");
      iterators := listAppend(Equation.getForIterators(Pointer.access(eqn_ptr)), iterators);
    end for;
    iterators := List.uniqueOnTrue(iterators, ComponentRef.isEqual);
    varData := VarData.addTypedList(varData, list(lowerIterator(iter) for iter in iterators), NBVariable.VarData.VarType.ITERATOR);
    equations := EquationPointers.fromList(equation_lst);
    equations := lowerComponentReferences(equations, VarData.getVariables(varData));

    for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
      if ExpandableArray.occupied(i, equations.eqArr) then
        eq := ExpandableArray.get(i, equations.eqArr);
        _:= match Equation.getAttributes(Pointer.access(eq))
          case BEquation.EQUATION_ATTRIBUTES(kind = BEquation.DYNAMIC_EQUATION())
            algorithm
              continuous_lst := eq :: continuous_lst;
              simulation_lst := eq :: simulation_lst;
          then ();

          case BEquation.EQUATION_ATTRIBUTES(kind = BEquation.DISCRETE_EQUATION())
            algorithm
              discretes_lst := eq :: discretes_lst;
              simulation_lst := eq :: simulation_lst;
          then ();

          case BEquation.EQUATION_ATTRIBUTES(kind = BEquation.INITIAL_EQUATION())
            algorithm
              initials_lst := eq :: initials_lst;
          then ();

          case BEquation.EQUATION_ATTRIBUTES(kind = BEquation.AUX_EQUATION())
            algorithm
              auxiliaries_lst := eq :: auxiliaries_lst;
              simulation_lst := eq :: simulation_lst;
          then ();

          case BEquation.EQUATION_ATTRIBUTES(kind = BEquation.EMPTY_EQUATION())
            algorithm
              removed_lst := eq :: removed_lst;
          then ();

          else
            algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + Equation.toString(Pointer.access(eq))});
          then fail();
        end match;
      end if;
    end for;

    eqData := BEquation.EQ_DATA_SIM(
      uniqueIndex = idx,
      equations   = equations,
      simulation  = EquationPointers.fromList(simulation_lst),
      continuous  = EquationPointers.fromList(continuous_lst),
      discretes   = EquationPointers.fromList(discretes_lst),
      initials    = EquationPointers.fromList(initials_lst),
      auxiliaries = EquationPointers.fromList(auxiliaries_lst),
      removed     = EquationPointers.fromList(removed_lst)
    );
  end lowerEquationData;

  function lowerEquationsAndAlgorithms
    "ToDo! Replace instNode in all Crefs
    Converts all frontend equations and algorithms to backend equations."
    input list<FEquation> eq_lst;
    input list<Algorithm> al_lst;
    input list<FEquation> init_eq_lst;
    input list<Algorithm> init_al_lst;
    output list<Pointer<Equation>> equations = {};
  algorithm
    // ---------------------------
    // convert all equations
    // ---------------------------
    for eq in eq_lst loop
      // returns a list of equations since for and if equations might be split up
      equations := listAppend(lowerEquation(eq, false), equations);
    end for;

    // ---------------------------
    // convert all algorithms
    // ---------------------------
    for alg in al_lst loop
      equations := lowerAlgorithm(alg, false) :: equations;
    end for;

    // ---------------------------
    // convert all initial equations
    // ---------------------------
    for eq in init_eq_lst loop
      // returns a list of equations since for and if equations might be split up
      equations := listAppend(lowerEquation(eq, true), equations);
    end for;

    // ---------------------------
    // convert all initial algorithms
    // ---------------------------
    for alg in init_al_lst loop
      equations := lowerAlgorithm(alg, true) :: equations;
    end for;
  end lowerEquationsAndAlgorithms;

  function lowerEquation
    input FEquation frontend_equation         "Original Frontend equation.";
    input Boolean init                        "True if an initial equation should be created.";
    output list<Pointer<Equation>> backend_equations   "Resulting Backend equations.";
  algorithm
    backend_equations := match frontend_equation
      local
        list<Pointer<Equation>> result = {}, new_body = {};
        Equation body_elem;
        Expression lhs, rhs, range;
        ComponentRef lhs_cref, rhs_cref;
        list<FEquation> body;
        Type ty;
        DAE.ElementSource source;
        ComponentRef iterator;
        list<FEquation.Branch> branches;
        BEquation.EquationAttributes attr;

      case FEquation.ARRAY_EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source)
        guard(Type.isArray(ty))
        algorithm
          attr := lowerEquationAttributes(ty, init);
          //ToDo! How to get Record size and replace NONE()?
      then {Pointer.create(BEquation.ARRAY_EQUATION(ty, lhs, rhs, source, attr, NONE()))};

      // sometimes regular equalities are array equations aswell. Need to update frontend?
      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source)
        guard(Type.isArray(ty))
        algorithm
          attr := lowerEquationAttributes(ty, init);
          //ToDo! How to get Record size and replace NONE()?
      then {Pointer.create(BEquation.ARRAY_EQUATION(ty, lhs, rhs, source, attr, NONE()))};

      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source)
        algorithm
          attr := lowerEquationAttributes(ty, init);
          result := if Type.isComplex(ty) then {Pointer.create(BEquation.RECORD_EQUATION(ty, lhs, rhs, source, attr))}
                                          else {Pointer.create(BEquation.SCALAR_EQUATION(ty, lhs, rhs, source, attr))};
      then result;

      case FEquation.CREF_EQUALITY(lhs = lhs_cref as NFComponentRef.CREF(ty = ty), rhs = rhs_cref, source = source)
        algorithm
          attr := lowerEquationAttributes(ty, init);
          // No check for complex. Simple equation is more important than complex. -> alias removal!
      then {Pointer.create(BEquation.SIMPLE_EQUATION(ty, lhs_cref, rhs_cref, source, attr))};

      case FEquation.FOR(range = SOME(range))
        algorithm
        // Treat each body equation individually because they can have different equation attributes
        // E.g.: DISCRETE, EvalStages

        iterator := ComponentRef.fromNode(frontend_equation.iterator, Type.INTEGER(), {}, NFComponentRef.Origin.ITERATOR);
        for eq in frontend_equation.body loop
          new_body := listAppend(lowerEquation(eq, init), new_body);
        end for;
        for body_elem_ptr in new_body loop
          body_elem := Pointer.access(body_elem_ptr);
          body_elem := BEquation.FOR_EQUATION(
            ty      = Type.liftArrayLeftList(Equation.getType(body_elem), {Dimension.fromRange(range)}),
            iter    = Iterator.SINGLE(iterator, range),
            body    = {body_elem},
            source  = frontend_equation.source,
            attr    = Equation.getAttributes(body_elem)
          );

          // merge iterators of each for equation instead of having nested loops (for {i in 1:10, j in 1:3, k in 1:5})
          Pointer.update(body_elem_ptr, Equation.mergeIterators(body_elem));
          result := body_elem_ptr :: result;
        end for;
      then result;

      // if equation
      case FEquation.IF()     then {Pointer.create(lowerIfEquation(frontend_equation, init))};

      // When equation cases
      case FEquation.WHEN()   then {Pointer.create(lowerWhenEquation(frontend_equation, init))};
      case FEquation.ASSERT() then {Pointer.create(lowerWhenEquation(frontend_equation, init))};

      // These have to be called inside a when equation body since they need
      // to get passed a condition from surrounding when equation.
      case FEquation.TERMINATE() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for TERMINATE expression without condition:\n" + FEquation.toString(frontend_equation)});
      then fail();
      case FEquation.REINIT() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for REINIT expression without condition:\n" + FEquation.toString(frontend_equation)});
      then fail();
      case FEquation.NORETCALL() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for NORETCALL expression without condition:\n" + FEquation.toString(frontend_equation)});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + FEquation.toString(frontend_equation)});
      then fail();
    end match;
  end lowerEquation;

  function lowerIfEquation
    input FEquation frontend_equation;
    input Boolean init;
    output Equation backend_equation;
  algorithm
    backend_equation := match frontend_equation
      local
        list<FEquation.Branch> branches;
        DAE.ElementSource source;
        BEquation.IfEquationBody ifEqBody;
        BEquation.EquationAttributes attr;

      case FEquation.IF(branches = branches, source = source)
        algorithm
          attr := if init then NBEquation.EQ_ATTR_DEFAULT_INITIAL else NBEquation.EQ_ATTR_DEFAULT_DISCRETE;
          SOME(ifEqBody) := lowerIfEquationBody(branches, init);
          // ToDo: compute correct size
      then BEquation.IF_EQUATION(0, ifEqBody, source, attr);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + FEquation.toString(frontend_equation)});
      then fail();

    end match;
  end lowerIfEquation;

  function lowerIfEquationBody
    input list<FEquation.Branch> branches;
    input Boolean init;
    output Option<BEquation.IfEquationBody> ifEq;
  algorithm
    ifEq := match branches
      local
        FEquation.Branch branch;
        list<FEquation.Branch> rest;
        list<Pointer<Equation>> eqns;
        Expression condition;
        Option<BEquation.IfEquationBody> result;

      // lower current branch
      case branch::rest
        algorithm
          (eqns, condition) := lowerIfBranch(branch, init);
          if Expression.isTrue(condition) then
            // finish recursion when a condition is found to be true because
            // following branches can never be reached. Also the last plain else
            // case has default Boolean true value in the NF.
            result := SOME(BEquation.IF_EQUATION_BODY(Expression.END(), eqns, NONE()));
          elseif Expression.isFalse(condition) then
            // discard a branch and continue with the rest if a condition is
            // found to be false, because it can never be reached.
            result := lowerIfEquationBody(rest, init);
          else
            result := SOME(BEquation.IF_EQUATION_BODY(condition, eqns, lowerIfEquationBody(rest, init)));
          end if;
      then result;

      // We should never get an empty list here since the last condition has to
      // be TRUE. If-Equations have to have a plain else case for consistency!
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();

    end match;
  end lowerIfEquationBody;

  function lowerIfBranch
    input FEquation.Branch branch;
    input Boolean init;
    output list<Pointer<Equation>> eqns;
    output Expression cond;
  algorithm
    (eqns, cond) := match branch
      local
        Expression condition;
        list<FEquation.Equation> body;

      case FEquation.BRANCH(condition = condition, body = body) guard(not Expression.isFalse(condition))
        // ToDo! Use condition variability here to have proper type of the
        // auxiliary that will be created for the condition.
      then (lowerIfBranchBody(body, init), condition);

      // Save some time by not lowering body if condition is false.
      case FEquation.BRANCH(condition = condition, body = body) guard(Expression.isFalse(condition))
      then ({}, condition);

      case FEquation.INVALID_BRANCH() algorithm
        // what to do with error message from invalid branch? Is that even needed?
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for invalid branch that should not exist outside of frontend."});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed without proper error message."});
      then fail();

    end match;
  end lowerIfBranch;

  function lowerIfBranchBody
    input list<FEquation.Equation> body;
    input Boolean init;
    input output list<Pointer<Equation>> eqns = {};
  algorithm
      eqns := match body
        local
          FEquation.Equation elem;
          list<FEquation.Equation> rest;
      case {}         then eqns;
      case elem::rest then lowerIfBranchBody(rest, init, listAppend(lowerEquation(elem, init), eqns));
    end match;
  end lowerIfBranchBody;

  function lowerWhenEquation
    // ToDo! inherit findEvents or implement own routine to be applied after lowering
    input FEquation frontend_equation;
    input Boolean init;
    output Equation backend_equation;
  algorithm
    backend_equation := match frontend_equation
      local
        list<FEquation.Branch> branches;
        DAE.ElementSource source;
        Expression condition, message, level;
        BEquation.WhenEquationBody whenEqBody;
        BEquation.EquationAttributes attr;

      case FEquation.WHEN(branches = branches, source = source)
        algorithm
          // When equation inside initial actually not allowed. Throw error?
          attr := if init then NBEquation.EQ_ATTR_DEFAULT_INITIAL else NBEquation.EQ_ATTR_DEFAULT_DISCRETE;
          SOME(whenEqBody) := lowerWhenEquationBody(branches);
      then BEquation.WHEN_EQUATION(BEquation.WhenEquationBody.size(whenEqBody), whenEqBody, source, attr);

      case FEquation.ASSERT(condition = condition, message = message, level = level, source = source)
        algorithm
          attr := NBEquation.EQ_ATTR_EMPTY_DISCRETE;
          whenEqBody := BEquation.WHEN_EQUATION_BODY(condition, {BEquation.ASSERT(condition, message, level, source)}, NONE());
      then BEquation.WHEN_EQUATION(0, whenEqBody, source, attr);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + FEquation.toString(frontend_equation)});
      then fail();

    end match;
  end lowerWhenEquation;

  function lowerWhenEquationBody
    input list<FEquation.Branch> branches;
    output Option<BEquation.WhenEquationBody> whenEq;
  algorithm
    whenEq := match branches
      local
        FEquation.Branch branch;
        list<FEquation.Branch> rest;
        list<BEquation.WhenStatement> stmts;
        Expression condition;

      // End of the line
      case {} then NONE();

      // lower current branch
      case branch::rest
        algorithm
          (stmts, condition) := lowerWhenBranch(branch);
      then SOME(BEquation.WHEN_EQUATION_BODY(condition, stmts, lowerWhenEquationBody(rest)));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();

    end match;
  end lowerWhenEquationBody;

  function lowerWhenBranch
    input FEquation.Branch branch;
    output list<BEquation.WhenStatement> stmts;
    output Expression cond;
  algorithm
    (stmts, cond) := match branch
      local
        Expression condition;
        list<FEquation.Equation> body;
      case FEquation.BRANCH(condition = condition, body = body)
        // ToDo! Use condition variability here to have proper type of the
        // auxiliary that will be created for the condition.
      then (lowerWhenBranchBody(condition, body), condition);

      case FEquation.INVALID_BRANCH() algorithm
        // what to do with error message from invalid branch? Is that even needed?
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for invalid branch that should not exist outside of frontend."});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed without proper error message."});
      then fail();

    end match;
  end lowerWhenBranch;

  function lowerWhenBranchBody
    input Expression condition;
    input list<FEquation.Equation> body;
    input output list<BEquation.WhenStatement> stmts = {};
  algorithm
    stmts := match body
      local
        FEquation.Equation elem;
        list<FEquation.Equation> rest;
      case {}         then stmts;
      case elem::rest then lowerWhenBranchBody(condition, rest, lowerWhenBranchStatement(elem, condition) :: stmts);
    end match;
  end lowerWhenBranchBody;

  function lowerWhenBranchStatement
    input FEquation.Equation eq;
    input Expression condition;
    output BEquation.WhenStatement stmt;
  algorithm
    stmt := match eq
      local
        Expression message, exp, lhs, rhs;
        ComponentRef cref, lhs_cref, rhs_cref;
        Type lhs_ty, rhs_ty;
        DAE.ElementSource source;
      // These should hopefully not occur since they have their own top level condition, check assert for same condition?
      // case FEquation.WHEN()       then fail();
      // case FEquation.ASSERT()     then fail();

      // These do not provide their own conditions and are therefore body branches
      case FEquation.TERMINATE(message = message, source = source)
      then BEquation.TERMINATE(message, source);

      case FEquation.REINIT(cref = Expression.CREF(cref = cref), reinitExp = exp, source = source)
      then BEquation.REINIT(cref, exp, source);

      case FEquation.NORETCALL(exp = exp, source = source)
      then BEquation.NORETCALL(exp, source);

      // Convert other equations to assignments
      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, source = source)
      then BEquation.ASSIGN(lhs, rhs, source);

      case FEquation.CREF_EQUALITY(lhs = lhs_cref as NFComponentRef.CREF(ty = lhs_ty), rhs = rhs_cref as NFComponentRef.CREF(ty = rhs_ty), source = source)
      then BEquation.ASSIGN(Expression.CREF(lhs_ty, lhs_cref), Expression.CREF(rhs_ty, rhs_cref), source);

      case FEquation.ARRAY_EQUALITY(lhs = lhs, rhs = rhs, source = source)
      then BEquation.ASSIGN(lhs, rhs, source);

      /* ToDo! implement proper cases for FOR and IF --> need FOR_ASSIGN and IF_ASSIGN ?
      case FEquation.FOR(iterator = iterator, range = SOME(range), body = body, source = source)
      case FEquation.IF(branches = branches, source = source)
      */

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerWhenBranchStatement for " + FEquation.toString(eq)});
      then fail();
    end match;
  end lowerWhenBranchStatement;

  function lowerAlgorithm
    input Algorithm alg;
    input Boolean init;
    output Pointer<Equation> eq;
  protected
    Integer size;
    list<ComponentRef> inputs, outputs;
    BEquation.EquationAttributes attr;
  algorithm
    // ToDo! check if always DAE.EXPAND() can be used
    // ToDo! export inputs
    // ToDo! get array sizes instead of only list length
    size := listLength(alg.outputs);
    attr := if init then NBEquation.EQ_ATTR_DEFAULT_INITIAL
            elseif ComponentRef.listHasDiscrete(alg.outputs) then NBEquation.EQ_ATTR_DEFAULT_DISCRETE
            else NBEquation.EQ_ATTR_DEFAULT_DYNAMIC;
    eq := Pointer.create(Equation.ALGORITHM(size, alg, alg.source, DAE.EXPAND(), attr));
  end lowerAlgorithm;

  function lowerEquationAttributes
    input Type ty;
    input Boolean init;
    output BEquation.EquationAttributes attr;
  algorithm
    attr := if init then NBEquation.EQ_ATTR_DEFAULT_INITIAL
            elseif Type.isDiscrete(ty) then NBEquation.EQ_ATTR_DEFAULT_DISCRETE
            else NBEquation.EQ_ATTR_DEFAULT_DYNAMIC;
  end lowerEquationAttributes;

  function lowerComponentReferences
    input output EquationPointers equations;
    input VariablePointers variables;
  algorithm
    equations := EquationPointers.mapExp(equations,function lowerComponentReferenceExp(variables = variables), SOME(function lowerComponentReference(variables = variables)));
  end lowerComponentReferences;

  function lowerComponentReferenceExp
    input output Expression exp;
    input VariablePointers variables;
  algorithm
    exp := match exp
      local
        Type ty;
        ComponentRef cref;
      case Expression.CREF(ty = ty, cref = cref) then Expression.CREF(ty, lowerComponentReference(cref, variables));
      else exp;
    end match;
  end lowerComponentReferenceExp;

  function lowerComponentReference
    input output ComponentRef cref;
    input VariablePointers variables;
  protected
    Pointer<Variable> var;
    list<list<Subscript>> subs;
  algorithm
    try
      var := VariablePointers.getVarSafe(variables, ComponentRef.stripSubscriptsAll(cref));
      cref := lowerComponentReferenceInstNode(cref, var);
    else
      if Flags.isSet(Flags.FAILTRACE) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      end if;
    end try;
  end lowerComponentReference;

public
  function lowerComponentReferenceInstNode
    "Adds the pointer to a variable to a component reference. This function needs
    to be public since it is needed whenever a component reference is extracted
    from a variable."
    input output ComponentRef cref;
    input Pointer<Variable> var;
  algorithm
    cref := match cref
      local
        ComponentRef qual;

      case qual as ComponentRef.CREF()
        algorithm
          qual.node := InstNode.VAR_NODE(InstNode.name(qual.node), var);
      then qual;

      else cref;
    end match;
  end lowerComponentReferenceInstNode;

protected

  annotation(__OpenModelica_Interface="backend");
end NBackendDAE;
