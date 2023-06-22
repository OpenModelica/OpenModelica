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
  import BVariable = NBVariable;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData, EquationAttributes, IfEquationBody, Iterator};
  import NBVariable.{VariablePointer, VariablePointers, VarData};
  import Events = NBEvents;
  import NFFlatten.FunctionTree;
  import Jacobian = NBJacobian;
  import NBJacobian.{SparsityPattern, SparsityColoring};
  import StrongComponent = NBStrongComponent;
  import NBSystem;
  import NBSystem.System;

protected
  // New Frontend imports
  import Algorithm = NFAlgorithm;
  import BackendExtension = NFBackendExtension;
  import Binding = NFBinding;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import FEquation = NFEquation;
  import FlatModel = NFFlatModel;
  import InstNode = NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // New Backend imports
  import BackendDAE = NBackendDAE;
  import Bindings = NBBindings;
  import Causalize = NBCausalize;
  import DetectStates = NBDetectStates;
  import DAEMode = NBDAEMode;
  import Initialization = NBInitialization;
  import Inline = NBInline;
  import NBJacobian.JacobianType;
  import Module = NBModule;
  import Partitioning = NBPartitioning;
  import Alias = NBAlias;
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
    // add init_1 for lambda = 1 (test for efficency)
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
    array<StrongComponent> comps                "the sorted equations";
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
            if isSome(bdae.init_0) then
              tmp := tmp + System.toStringList(Util.getOption(bdae.init_0), "[INI_0] Initialization Lambda=0: " + str);
            end if;
            if isSome(bdae.dae) then
              tmp := tmp + System.toStringList(Util.getOption(bdae.dae), "[DAE] DAEMode: " + str);
            end if;
          end if;
          tmp := tmp + Events.EventInfo.toString(bdae.eventInfo);
      then tmp;

      case JACOBIAN() algorithm
        tmp := StringUtil.headline_1(Jacobian.jacobianTypeString(bdae.jacType) + " Jacobian " + bdae.name + ": " + str) + "\n";
        tmp := tmp + BVariable.VarData.toString(bdae.varData, 1);
        for i in 1:arrayLength(bdae.comps) loop
          tmp := tmp + StrongComponent.toString(bdae.comps[i], i) + "\n";
        end for;
        tmp := tmp + SparsityPattern.toString(bdae.sparsityPattern) + "\n" + SparsityColoring.toString(bdae.sparsityColoring);
      then tmp;

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
    // expand records to its children. Put behind flag?
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
    // (do not change order SIMPLIFY -> ALIAS -> EVENTS -> DETECTSTATES)
    preOptModules := {
      (Bindings.main,      "Bindings"),
      (function Inline.main(inline_types = {DAE.NORM_INLINE(), DAE.BUILTIN_EARLY_INLINE(), DAE.EARLY_INLINE(), DAE.DEFAULT_INLINE()}), "Early Inline"),
      (simplify,           "simplify1"),
      (Alias.main,         "Alias"),
      (simplify,           "simplify2"), // TODO simplify in Alias only
      (Events.main,        "Events"),
      (DetectStates.main,  "Detect States")
    };

    mainModules := {
      (function Partitioning.main(systemType = NBSystem.SystemType.ODE),  "Partitioning"),
      (function Causalize.main(systemType = NBSystem.SystemType.ODE),     "Causalize"),
      (function Inline.main(inline_types = {DAE.AFTER_INDEX_RED_INLINE()}), "After Index Reduction Inline"),
      (Initialization.main,                                               "Initialization")
    };

    if Flags.getConfigBool(Flags.DAE_MODE) then
      mainModules := (DAEMode.main, "DAE-Mode") :: mainModules;
    end if;

    // (do not change order SOLVE -> JACOBIAN)
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
      debugStr := "[failtrace] ........ [" + ClockIndexes.toString(clock_idx) + "] " + name;
      debugStr := debugStr + StringUtil.repeat(".", 60 - stringLength(debugStr));
      if clock_idx <> -1 then
        BuiltinSystem.realtimeClear(clock_idx);
        BuiltinSystem.realtimeTick(clock_idx);
        try
          bdae := func(bdae);
        else
          if Flags.isSet(Flags.FAILTRACE) then
            debugStr := debugStr + " failed\n";
            print(debugStr);
          end if;
          fail();
        end try;
        clock_time := BuiltinSystem.realtimeTock(clock_idx);
        ExecStat.execStat(name);
        module_clocks := (name, clock_time) :: module_clocks;
        if Flags.isSet(Flags.FAILTRACE) then
          debugStr := debugStr + " " + realString(clock_time) + "s\n";
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
    () := match bdae
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
    list<Variable> vars;
    Pointer<Variable> lowVar_ptr, time_ptr, dummy_ptr;
    list<Pointer<Variable>> unknowns_lst = {}, knowns_lst = {}, initials_lst = {}, auxiliaries_lst = {}, aliasVars_lst = {}, nonTrivialAlias_lst = {};
    list<Pointer<Variable>> states_lst = {}, derivatives_lst = {}, algebraics_lst = {}, discretes_lst = {}, previous_lst = {};
    list<Pointer<Variable>> parameters_lst = {}, constants_lst = {}, records_lst = {}, artificials_lst = {};
    VariablePointers variables, unknowns, knowns, initials, auxiliaries, aliasVars, nonTrivialAlias;
    VariablePointers states, derivatives, algebraics, discretes, previous;
    VariablePointers parameters, constants, records, artificials;
    Pointer<list<Pointer<Variable>>> binding_iter_lst = Pointer.create({});
    Boolean scalarized = Flags.isSet(Flags.NF_SCALARIZE);
  algorithm
    vars := List.flatten(list(Variable.expandChildren(v) for v in varList));

    // instantiate variable data (with one more space for time variable);
    variables := VariablePointers.empty(listLength(vars) + 1, scalarized);

    // create dummy and time var and add then
    // needed to make function BVariable.getVarPointer() more universally applicable
    dummy_ptr := Pointer.create(NBVariable.DUMMY_VARIABLE);
    time_ptr := BVariable.createTimeVar();
    variables := VariablePointers.add(dummy_ptr, variables);
    variables := VariablePointers.add(time_ptr, variables);
    artificials_lst := {dummy_ptr, time_ptr};

    // routine to prepare the lists for pointer arrays
    for var in listReverse(vars) loop
      lowVar_ptr := lowerVariable(var);
      lowVar := Pointer.access(lowVar_ptr);
      variables := VariablePointers.add(lowVar_ptr, variables);
      () := match lowVar.backendinfo.varKind

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

        case BackendExtension.RECORD() algorithm
          records_lst := lowVar_ptr :: records_lst;
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
    records         := VariablePointers.fromList(records_lst, scalarized);
    artificials     := VariablePointers.fromList(artificials_lst, scalarized);

    /* lower the variable bindings and add binding iterators */
    variables       := VariablePointers.map(variables, function collectVariableBindingIterators(variables = variables, binding_iter_lst = binding_iter_lst));
    variables       := VariablePointers.addList(Pointer.access(binding_iter_lst), variables);
    knowns          := VariablePointers.addList(Pointer.access(binding_iter_lst), knowns);
    artificials     := VariablePointers.addList(Pointer.access(binding_iter_lst), artificials);
    variables       := VariablePointers.map(variables, function Variable.mapExp(fn = function lowerComponentReferenceExp(variables = variables)));

    /* lower the records to add children */
    records         := VariablePointers.map(records, function lowerRecordChildren(variables = variables));

    /* create variable data */
    variableData := BVariable.VAR_DATA_SIM(variables, unknowns, knowns, initials, auxiliaries, aliasVars, nonTrivialAlias,
                    derivatives, algebraics, discretes, previous, states, parameters, constants, records, artificials);
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
      local
        list<Pointer<Variable>> children = {};

      // variable -> artificial state if it has stateSelect = StateSelect.always
      case (NFPrefixes.Variability.CONTINUOUS, BackendExtension.VAR_ATTR_REAL(stateSelect = SOME(NFBackendExtension.StateSelect.ALWAYS)), _)
        guard(variability == NFPrefixes.Variability.CONTINUOUS)
      then BackendExtension.STATE(1, NONE(), false);

      // add children pointers for records afterwards
      case (_, _, Type.COMPLEX())                                     then BackendExtension.RECORD({});
      case (_, _, _) guard(Type.isComplexArray(ty))                   then BackendExtension.RECORD({});

      case (NFPrefixes.Variability.CONTINUOUS, _, Type.BOOLEAN())     then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.INTEGER())     then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.ENUMERATION()) then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, _)                  then BackendExtension.ALGEBRAIC();

      case (NFPrefixes.Variability.DISCRETE, _, _)                    then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.IMPLICITLY_DISCRETE, _, _)         then BackendExtension.DISCRETE();

      case (NFPrefixes.Variability.PARAMETER, _, _)                   then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.STRUCTURAL_PARAMETER, _, _)        then BackendExtension.PARAMETER(); // CONSTANT ?
      case (NFPrefixes.Variability.NON_STRUCTURAL_PARAMETER, _, _)    then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.CONSTANT, _, _)                    then BackendExtension.CONSTANT();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;

    // make adjustments to attributes based on variable kind
    attributes := match varKind
      case BackendExtension.PARAMETER() then BackendExtension.VariableAttributes.setFixed(attributes, ty, true, false);
      else attributes;
    end match;
  end lowerVariableKind;

  function collectVariableBindingIterators
    input output Variable var;
    input VariablePointers variables;
    input Pointer<list<Pointer<Variable>>> binding_iter_lst;
  protected
    Option<Expression> exp_opt;
  algorithm
    BackendExtension.BackendInfo.map(var.backendinfo, function collectBindingIterators(variables = variables, binding_iter_lst = binding_iter_lst));
    exp_opt := Binding.typedExp(var.binding);
    if isSome(exp_opt) then
      Expression.map(Util.getOption(exp_opt), function collectBindingIterators(variables = variables, binding_iter_lst = binding_iter_lst));
    end if;
  end collectVariableBindingIterators;

  function lowerRecordChildren
    input output Variable var;
    input VariablePointers variables;
  algorithm
    var := match var
      local
        BackendExtension.BackendInfo binfo;
        BackendExtension.VariableKind varKind;
      case Variable.VARIABLE(backendinfo = binfo as BackendExtension.BACKEND_INFO(varKind = varKind as BackendExtension.RECORD())) algorithm
        // kabdelhak: why is this list reversed in the frontend? doesnt match input order
        varKind.children := listReverse(list(VariablePointers.getVarSafe(variables, ComponentRef.stripSubscriptsAll(child.name)) for child in var.children));
        binfo.varKind := varKind;
        var.backendinfo := binfo;
      then var;
      else var;
    end match;
  end lowerRecordChildren;

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
    list<Pointer<Equation>> equation_lst, continuous_lst, discretes_lst, initials_lst, auxiliaries_lst, simulation_lst, removed_lst;
    EquationPointers equations;
    Pointer<Equation> eq;
    Pointer<Integer> idx = Pointer.create(0);
  algorithm
    equation_lst := lowerEquationsAndAlgorithms(eq_lst, al_lst, init_eq_lst, init_al_lst);
    for eqn_ptr in equation_lst loop
      Equation.createName(eqn_ptr, idx, NBEquation.SIMULATION_STR);
      iterators := listAppend(Equation.getForIteratorCrefs(Pointer.access(eqn_ptr)), iterators);
    end for;
    iterators := List.uniqueOnTrue(iterators, ComponentRef.isEqual);
    varData := VarData.addTypedList(varData, list(lowerIterator(iter) for iter in iterators), NBVariable.VarData.VarType.ITERATOR);
    equations := EquationPointers.fromList(equation_lst);
    equations := lowerComponentReferences(equations, VarData.getVariables(varData));

    (simulation_lst, continuous_lst, discretes_lst, initials_lst, auxiliaries_lst, removed_lst) := BEquation.typeList(EquationPointers.toList(equations));

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
    input FEquation frontend_equation                 "Original Frontend equation.";
    input Boolean init                                "True if an initial equation should be created.";
    output list<Pointer<Equation>> backend_equations  "Resulting Backend equations.";
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
        EquationAttributes attr;
        Integer rec_size;
        Statement stmt;
        Algorithm alg;

      case FEquation.ARRAY_EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source)
        guard(Type.isArray(ty)) algorithm
        attr := lowerEquationAttributes(ty, init);
      then {Pointer.create(BEquation.ARRAY_EQUATION(ty, lhs, rhs, source, attr, Type.complexSize(ty)))};

      // sometimes regular equalities are array equations aswell. Need to update frontend?
      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source)
        guard(Type.isArray(ty)) algorithm
        attr := lowerEquationAttributes(ty, init);
      then {Pointer.create(BEquation.ARRAY_EQUATION(ty, lhs, rhs, source, attr, Type.complexSize(ty)))};

      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source) algorithm
        attr := lowerEquationAttributes(ty, init);
        if Type.isComplex(ty) then
          try
            SOME(rec_size) := Type.complexSize(ty);
          else
            Error.addMessage(Error.COMPILER_WARNING,{getInstanceName()
              + ": could not determine complex type size of \n" + FEquation.toString(frontend_equation)});
            fail();
          end try;
          result := {Pointer.create(BEquation.RECORD_EQUATION(ty, lhs, rhs, source, attr, rec_size))};
        else
          result := {Pointer.create(BEquation.SCALAR_EQUATION(ty, lhs, rhs, source, attr))};
        end if;
      then result;

      case FEquation.FOR(range = SOME(range)) algorithm
        if Expression.rangeSize(range) > 0 then
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
            body_elem := Equation.mergeIterators(body_elem);
            // inline if size 1
            body_elem := Inline.inlineForEquation(body_elem);

            Pointer.update(body_elem_ptr, body_elem);
            result := body_elem_ptr :: result;
          end for;
        else
          if Flags.isSet(Flags.FAILTRACE) then
            Error.addMessage(Error.COMPILER_WARNING,{getInstanceName()
              + ": Empty for-equation got removed:\n" + FEquation.toString(frontend_equation)});
          end if;
        end if;
      then result;

      // if equation
      case FEquation.IF() then {Pointer.create(lowerIfEquation(frontend_equation, init))};

      // When equation cases
      case FEquation.WHEN()   then lowerWhenEquation(frontend_equation, init);
      case FEquation.ASSERT() then lowerWhenEquation(frontend_equation, init);

      // wrap no return call in algorithm
      case FEquation.NORETCALL() algorithm
        stmt := Statement.NORETCALL(frontend_equation.exp, frontend_equation.source);
        alg  := Algorithm.ALGORITHM({stmt}, {}, {}, InstNode.EMPTY_NODE(), frontend_equation.source);
        alg  := Algorithm.setInputsOutputs(alg);
      then {lowerAlgorithm(alg, init)};

      // These have to be called inside a when equation body since they need
      // to get passed a condition from surrounding when equation.
      case FEquation.TERMINATE() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for TERMINATE expression without condition:\n" + FEquation.toString(frontend_equation)});
      then fail();
      case FEquation.REINIT() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for REINIT expression without condition:\n" + FEquation.toString(frontend_equation)});
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
        IfEquationBody ifEqBody;
        EquationAttributes attr;

      case FEquation.IF(branches = branches, source = source)
        algorithm
          attr := if init then NBEquation.EQ_ATTR_DEFAULT_INITIAL else NBEquation.EQ_ATTR_DEFAULT_DISCRETE;
          SOME(ifEqBody) := lowerIfEquationBody(branches, init);
          // ToDo: compute correct size
      then BEquation.IF_EQUATION(IfEquationBody.size(ifEqBody), ifEqBody, source, attr);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + FEquation.toString(frontend_equation)});
      then fail();

    end match;
  end lowerIfEquation;

  function lowerIfEquationBody
    input list<FEquation.Branch> branches;
    input Boolean init;
    output Option<IfEquationBody> ifEq;
  algorithm
    ifEq := match branches
      local
        FEquation.Branch branch;
        list<FEquation.Branch> rest;
        list<Pointer<Equation>> eqns;
        Expression condition;
        Option<IfEquationBody> result;

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
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n"
          + List.toString(branches, function FEquation.Branch.toString(indent = ""), "", "\t", "\n", "\n")});
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
    input FEquation frontend_equation;
    input Boolean init;
    output list<Pointer<Equation>> backend_equations;
  algorithm
    backend_equations := match frontend_equation
      local
        list<FEquation.Branch> branches;
        DAE.ElementSource source;
        Expression condition, message, level;
        BEquation.WhenEquationBody whenEqBody;
        list<BEquation.WhenEquationBody> bodies;
        EquationAttributes attr;

      case FEquation.WHEN(branches = branches, source = source)
        algorithm
          // When equation inside initial actually not allowed. Throw error?
          attr := if init then NBEquation.EQ_ATTR_DEFAULT_INITIAL else NBEquation.EQ_ATTR_DEFAULT_DISCRETE;
          SOME(whenEqBody) := lowerWhenEquationBody(branches);
          bodies := BEquation.WhenEquationBody.split(whenEqBody);
      then list(Pointer.create(BEquation.WHEN_EQUATION(BEquation.WhenEquationBody.size(b), b, source, attr)) for b in bodies);

      case FEquation.ASSERT(condition = condition, message = message, level = level, source = source)
        algorithm
          attr := NBEquation.EQ_ATTR_EMPTY_DISCRETE;
          whenEqBody := BEquation.WHEN_EQUATION_BODY(condition, {BEquation.ASSERT(condition, message, level, source)}, NONE());
      then {Pointer.create(BEquation.WHEN_EQUATION(0, whenEqBody, source, attr))};

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
    EquationAttributes attr;
  algorithm
    // ToDo! check if always DAE.EXPAND() can be used
    // ToDo! export inputs
    size := sum(ComponentRef.size(out) for out in alg.outputs);
    attr := if init then NBEquation.EQ_ATTR_DEFAULT_INITIAL
            elseif ComponentRef.listHasDiscrete(alg.outputs) then NBEquation.EQ_ATTR_DEFAULT_DISCRETE
            else NBEquation.EQ_ATTR_DEFAULT_DYNAMIC;
    eq := Pointer.create(Equation.ALGORITHM(size, alg, alg.source, DAE.EXPAND(), attr));
  end lowerAlgorithm;

  function lowerEquationAttributes
    input Type ty;
    input Boolean init;
    output EquationAttributes attr;
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

  public function lowerComponentReferenceExp
    input output Expression exp;
    input VariablePointers variables;
  algorithm
    exp := match exp
      local
        Call call;

      case Expression.CREF() guard(not ComponentRef.isNameNode(exp.cref))
      then Expression.CREF(exp.ty, lowerComponentReference(exp.cref, variables));

      case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
        call.iters := list(Util.applyTuple21(tpl, function lowerInstNode(variables = variables)) for tpl in call.iters);
        exp.call := call;
      then exp;

      case Expression.CALL(call = call as Call.TYPED_REDUCTION()) algorithm
        call.iters := list(Util.applyTuple21(tpl, function lowerInstNode(variables = variables)) for tpl in call.iters);
        exp.call := call;
      then exp;
    else exp;
    end match;
  end lowerComponentReferenceExp;

  protected function lowerComponentReference
    input output ComponentRef cref;
    input VariablePointers variables;
  protected
    Pointer<Variable> var;
    list<list<Subscript>> subs;
  algorithm
    try
      if not ComponentRef.isWild(cref) then
        var := VariablePointers.getVarSafe(variables, ComponentRef.stripSubscriptsAll(cref));
        cref := lowerComponentReferenceInstNode(cref, var);
        cref := ComponentRef.mapSubscripts(cref, function Subscript.mapExp(func = function lowerComponentReferenceExp(variables = variables)));
      end if;
    else
      if Flags.isSet(Flags.FAILTRACE) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + ComponentRef.toString(cref)});
      end if;
    end try;
  end lowerComponentReference;

  function collectBindingIterators
    "collects all iterators in bindings and creates variables for them.
    in bindings they are only known locally but they still need a respective variable"
    input output Expression exp;
    input VariablePointers variables;
    input Pointer<list<Pointer<Variable>>> binding_iter_lst;
  algorithm
    try
    () := match exp
      local
        Call call;

      case Expression.CREF() guard(not (VariablePointers.containsCref(exp.cref, variables)
        or ComponentRef.isNameNode(exp.cref))) algorithm
        Pointer.update(binding_iter_lst, lowerIterator(exp.cref) :: Pointer.access(binding_iter_lst));
      then ();

      case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
        for tpl in call.iters loop
          collectIterator(Util.tuple21(tpl), variables, binding_iter_lst);
        end for;
      then ();

      case Expression.CALL(call = call as Call.TYPED_REDUCTION()) algorithm
        for tpl in call.iters loop
          collectIterator(Util.tuple21(tpl), variables, binding_iter_lst);
        end for;
      then ();
      else ();
    end match;
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + Expression.toString(exp)});
      fail();
    end try;
  end collectBindingIterators;

  function collectIterator
    "collects all iterators in bindings and creates variables for them.
    in bindings they are only known locally but they still need a respective variable"
    input InstNode iterator;
    input VariablePointers variables;
    input Pointer<list<Pointer<Variable>>> binding_iter_lst;
  protected
    ComponentRef cref;
  algorithm
    cref := ComponentRef.fromNode(iterator, InstNode.getType(iterator), {}, NFComponentRef.Origin.ITERATOR);
    if not VariablePointers.containsCref(cref, variables) then
      Pointer.update(binding_iter_lst, lowerIterator(cref) :: Pointer.access(binding_iter_lst));
    end if;
  end collectIterator;

  function lowerInstNode
    input output InstNode node;
    input VariablePointers variables;
  protected
    ComponentRef cref = ComponentRef.fromNode(node, Type.INTEGER(), {}, NFComponentRef.Origin.ITERATOR);
    Pointer<Variable> var;
  algorithm
    var := VariablePointers.getVarSafe(variables, ComponentRef.stripSubscriptsAll(cref));
    node := InstNode.VAR_NODE(InstNode.name(node), var);
  end lowerInstNode;

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

  function lowerIterator
    input ComponentRef iterator;
    output Pointer<Variable> var_ptr = lowerVariable(Variable.fromCref(iterator));
  end lowerIterator;

  function lowerIteratorCref
    input output ComponentRef iterator;
  algorithm
    iterator := BVariable.getVarName(lowerIterator(iterator));
  end lowerIteratorCref;

  function lowerIteratorExp
    input output Expression exp;
  algorithm
    exp := match exp
      case Expression.CREF() algorithm
        exp.cref := lowerIteratorCref(exp.cref);
      then exp;
      else exp;
    end match;
  end lowerIteratorExp;
  annotation(__OpenModelica_Interface="backend");
end NBackendDAE;
