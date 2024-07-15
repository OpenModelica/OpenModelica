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
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData, EquationAttributes, EquationKind, IfEquationBody, Iterator};
  import NBVariable.{VariablePointer, VariablePointers, VarData};
  import Events = NBEvents;
  import NFFlatten.FunctionTree;
  import Jacobian = NBJacobian;
  import Partitioning = NBPartitioning;
  import NBJacobian.{SparsityPattern, SparsityColoring};
  import StrongComponent = NBStrongComponent;
  import NBStrongComponent.CountCollector;
  import NBPartition;
  import NBPartition.Partition;

protected
  // Old Frontend imports
  import Absyn.Path;
  import AbsynUtil;

  // New Frontend imports
  import Algorithm = NFAlgorithm;
  import NFBackendExtension.{Annotations, BackendInfo, VariableAttributes, VariableKind};
  import Binding = NFBinding;
  import Call = NFCall;
  import Class = NFClass;
  import ComplexType = NFComplexType;
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import FEquation = NFEquation;
  import FlatModel = NFFlatModel;
  import NFFunction.Function;
  import InstNode = NFInstNode.InstNode;
  import Prefixes = NFPrefixes;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // New Backend imports
  import Alias = NBAlias;
  import BackendDAE = NBackendDAE;
  import Bindings = NBBindings;
  import Causalize = NBCausalize;
  import DAEMode = NBDAEMode;
  import DetectStates = NBDetectStates;
  import Differentiate = NBDifferentiate;
  import FunctionAlias = NBFunctionAlias;
  import Initialization = NBInitialization;
  import Inline = NBInline;
  import NBJacobian.JacobianType;
  import Module = NBModule;
  import Solve = NBSolve;
  import Tearing = NBTearing;

  // Util imports
  import ClockIndexes;
  import Error;
  import ExecStat;
  import ExpandableArray;
  import Flags;
  import StringUtil;
  import System;

public
  record MAIN
    list<Partition> ode                   "Partitions for differential-algebraic equations";
    list<Partition> algebraic             "Partitions for algebraic equations";
    list<Partition> ode_event             "Partitions for differential-algebraic event iteration";
    list<Partition> alg_event             "Partitions for algebraic event iteration";
    list<Partition> clocked               "Clocked Partitions";
    list<Partition> init                  "Partitions for initialization";
    Option<list<Partition>> init_0        "Partitions for lambda 0 (homotopy) Initialization";
    // add init_1 for lambda = 1 (test for efficency)
    Option<list<Partition>> dae           "Partitions for dae mode";

    VarData varData                       "Variable data.";
    EqData eqData                         "Equation data.";

    Events.EventInfo eventInfo            "contains time and state events";
    Partitioning.ClockedInfo clockedInfo  "contains information about clocked partitions";
    FunctionTree funcTree                 "Function bodies.";
  end MAIN;

  record JACOBIAN
    String name                       "unique matrix name";
    JacobianType jacType              "type of jacobian";
    VarData varData                   "Variable data.";
    array<StrongComponent> comps      "the sorted equations";
    SparsityPattern sparsityPattern   "Sparsity pattern for the jacobian";
    SparsityColoring sparsityColoring "Coloring information";
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
          if (listEmpty(bdae.ode) and listEmpty(bdae.algebraic) and listEmpty(bdae.ode_event) and listEmpty(bdae.alg_event) and listEmpty(bdae.clocked))
             or not Flags.isSet(Flags.BLT_DUMP) then
            tmp := StringUtil.headline_1("BackendDAE: " + str) + "\n";
            tmp := tmp +  VarData.toString(bdae.varData, 2) + "\n" +
                          EqData.toString(bdae.eqData, 1);
          else
            tmp := tmp + Partition.toStringList(bdae.ode, "[ODE] Differential-Algebraic: " + str);
            tmp := tmp + Partition.toStringList(bdae.algebraic, "[ALG] Algebraic: " + str);
            tmp := tmp + Partition.toStringList(bdae.ode_event, "[ODE_EVENT] Event Handling: " + str);
            tmp := tmp + Partition.toStringList(bdae.alg_event, "[ALG_EVENT] Event Handling: " + str);
            tmp := tmp + Partition.toStringList(bdae.clocked, "[CLOCKED] Event Handling: " + str);
            tmp := tmp + Partition.toStringList(bdae.init, "[INI] Initialization: " + str);
            if isSome(bdae.init_0) then
              tmp := tmp + Partition.toStringList(Util.getOption(bdae.init_0), "[INI_0] Initialization Lambda=0: " + str);
            end if;
            if isSome(bdae.dae) then
              tmp := tmp + Partition.toStringList(Util.getOption(bdae.dae), "[DAE] DAEMode: " + str);
            end if;
          end if;
          tmp := tmp + Events.EventInfo.toString(bdae.eventInfo);
          tmp := tmp + Partitioning.ClockedInfo.toString(bdae.clockedInfo);
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
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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
    Partitioning.ClockedInfo clockedInfo = Partitioning.ClockedInfo.new();
    UnorderedMap<Path, Function> functions;
  algorithm
    variableData := lowerVariableData(flatModel.variables);
    (equationData, variableData) := lowerEquationData(flatModel.equations, flatModel.algorithms, flatModel.initialEquations, flatModel.initialAlgorithms, variableData);
    bdae := MAIN({}, {}, {}, {}, {}, {}, NONE(), NONE(), variableData, equationData, eventInfo, clockedInfo, lowerFunctions(funcTree));
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
      (FunctionAlias.main, "FunctionAlias"),
      (function Inline.main(inline_types = {DAE.NORM_INLINE(), DAE.BUILTIN_EARLY_INLINE(), DAE.EARLY_INLINE(), DAE.DEFAULT_INLINE()}), "Early Inline"),
      (simplify,           "simplify1"),
      (Alias.main,         "Alias"),
      (simplify,           "simplify2"), // TODO simplify in Alias only
      (DetectStates.main,  "Detect States"),
      (Events.main,        "Events")
    };

    mainModules := {
      (function Partitioning.main(kind = NBPartition.Kind.ODE),             "Partitioning"),
      (function Causalize.main(kind = NBPartition.Kind.ODE),                "Causalize"),
      (function Inline.main(inline_types = {DAE.AFTER_INDEX_RED_INLINE()}), "After Index Reduction Inline"),
      (Initialization.main,                                                 "Initialization")
    };

    if Flags.getConfigBool(Flags.DAE_MODE) then
      mainModules := (DAEMode.main, "DAE-Mode") :: mainModules;
    end if;

    // (do not change order SOLVE -> JACOBIAN)
    postOptModules := {
      (function Tearing.main(kind = NBPartition.Kind.ODE),    "Tearing"),
      (Partitioning.categorize,                               "Categorize"),
      (Solve.main,                                            "Solve"),
      (function Jacobian.main(kind = NBPartition.Kind.ODE),   "Jacobian")
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

    backenddaeinfo(bdae);
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
        System.realtimeClear(clock_idx);
        System.realtimeTick(clock_idx);
        try
          bdae := func(bdae);
        else
          if Flags.isSet(Flags.FAILTRACE) then
            debugStr := debugStr + " failed\n";
            print(debugStr);
          end if;
          fail();
        end try;
        clock_time := System.realtimeTock(clock_idx);
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
    bdae := match bdae
      local
        EqData eqData;
      case MAIN(eqData = eqData as BEquation.EQ_DATA_SIM()) algorithm
        eqData.equations := EquationPointers.map(eqData.equations, function Equation.simplify(name = getInstanceName(), indent = ""));
        bdae.eqData := EqData.compress(eqData);
      then bdae;
      else bdae;
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
          var_lst := listAppend(Partition.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.algebraic loop
          var_lst := listAppend(Partition.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.ode_event loop
          var_lst := listAppend(Partition.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.alg_event loop
          var_lst := listAppend(Partition.getLoopResiduals(syst), var_lst);
        end for;
        for syst in bdae.init loop
          var_lst := listAppend(Partition.getLoopResiduals(syst), var_lst);
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
    list<Pointer<Variable>> states_lst = {}, derivatives_lst = {}, algebraics_lst = {}, discretes_lst = {}, discrete_states_lst = {}, clocked_states_lst = {}, previous_lst = {}, clocks_lst = {};
    list<Pointer<Variable>> inputs_lst = {}, parameters_lst = {}, constants_lst = {}, records_lst = {}, external_objects_lst = {}, artificials_lst = {};
    VariablePointers variables, unknowns, knowns, initials, auxiliaries, aliasVars, nonTrivialAlias;
    VariablePointers states, derivatives, algebraics, discretes, discrete_states, clocked_states, previous, clocks;
    VariablePointers inputs, parameters, constants, records, external_objects, artificials;
    UnorderedSet<VariablePointer> binding_iter_set = UnorderedSet.new(BVariable.hash, BVariable.equalName);
    list<Pointer<Variable>> binding_iter_lst;
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

        // do nothing for size 0 variables, they get removed
        // Note: record elements need to exist in the full
        //   variable array even if they are of size 0
        case _ guard(Variable.size(var) == 0) then ();

        case _ guard(Variable.isTopLevelInput(var)) algorithm
          inputs_lst := lowVar_ptr :: inputs_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        case VariableKind.ALGEBRAIC() algorithm
          algebraics_lst := lowVar_ptr :: algebraics_lst;
          unknowns_lst := lowVar_ptr :: unknowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case VariableKind.STATE() algorithm
          states_lst := lowVar_ptr :: states_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case VariableKind.STATE_DER() algorithm
          derivatives_lst := lowVar_ptr :: derivatives_lst;
          unknowns_lst := lowVar_ptr :: unknowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case VariableKind.DISCRETE() algorithm
          discretes_lst := lowVar_ptr :: discretes_lst;
          unknowns_lst := lowVar_ptr :: unknowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case VariableKind.PREVIOUS() algorithm
          previous_lst := lowVar_ptr :: previous_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
          initials_lst := lowVar_ptr :: initials_lst;
        then ();

        case VariableKind.PARAMETER() algorithm
          parameters_lst := lowVar_ptr :: parameters_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        case VariableKind.CONSTANT() algorithm
          constants_lst := lowVar_ptr :: constants_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        // always consider records known since their attributes are in the unknown section (if they are unknown)
        case VariableKind.RECORD() algorithm
          records_lst := lowVar_ptr :: records_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        case VariableKind.CLOCK() algorithm
          clocks_lst := lowVar_ptr :: clocks_lst;
        then ();

        case VariableKind.EXTOBJ() algorithm
          lowVar_ptr := BVariable.setFixed(lowVar_ptr);
          external_objects_lst := lowVar_ptr :: external_objects_lst;
          knowns_lst := lowVar_ptr :: knowns_lst;
        then ();

        /* other cases should not occur up until now */
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + BVariable.toString(var)});
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
    discrete_states := VariablePointers.fromList(discrete_states_lst, scalarized);
    clocked_states  := VariablePointers.fromList(clocked_states_lst, scalarized);
    previous        := VariablePointers.fromList(previous_lst, scalarized);
    clocks          := VariablePointers.fromList(clocks_lst, scalarized);

    inputs          := VariablePointers.fromList(inputs_lst, scalarized);
    parameters      := VariablePointers.fromList(parameters_lst, scalarized);
    constants       := VariablePointers.fromList(constants_lst, scalarized);
    records         := VariablePointers.fromList(records_lst, scalarized);
    external_objects:= VariablePointers.fromList(external_objects_lst, scalarized);
    artificials     := VariablePointers.fromList(artificials_lst, scalarized);

    /* lower the variable bindings and add binding iterators */
    variables       := VariablePointers.map(variables, function collectVariableBindingIterators(variables = variables, set = binding_iter_set));
    binding_iter_lst:= UnorderedSet.toList(binding_iter_set);
    variables       := VariablePointers.addList(binding_iter_lst, variables);
    knowns          := VariablePointers.addList(binding_iter_lst, knowns);
    artificials     := VariablePointers.addList(binding_iter_lst, artificials);
    variables       := VariablePointers.map(variables, function Variable.mapExp(fn = function lowerComponentReferenceExp(variables = variables)));

    /* lower the records to add children */
    records         := VariablePointers.mapPtr(records, function lowerRecordChildren(variables = variables));

    /* create variable data */
    variableData := BVariable.VAR_DATA_SIM(variables, unknowns, knowns, initials, auxiliaries, aliasVars, nonTrivialAlias,
                      derivatives, algebraics, discretes, discrete_states, clocked_states, previous, clocks,
                      states, inputs, parameters, constants, records, external_objects, artificials);
  end lowerVariableData;

  function lowerVariable
    input Variable var;
    output Pointer<Variable> var_ptr;
  protected
    VariableKind varKind;
    VariableAttributes attributes;
    Annotations annotations;
  algorithm
    try
      attributes := VariableAttributes.create(var.typeAttributes, var.ty, var.attributes, var.children, var.comment);
      annotations := Annotations.create(var.comment);

      // only change varKind if unset (Iterators are set before)
      var.backendinfo := match var.backendinfo
        case BackendInfo.BACKEND_INFO(varKind = VariableKind.FRONTEND_DUMMY()) algorithm
          (varKind, attributes) := lowerVariableKind(Variable.variability(var), attributes, var.ty);
        then BackendInfo.BACKEND_INFO(varKind, attributes, annotations, NONE(), NONE(), NONE(), NONE());
        else BackendInfo.setAttributes(var.backendinfo, attributes, annotations);
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
    output VariableKind varKind;
    input output VariableAttributes attributes;
    input Type ty;
  algorithm
    varKind := match(variability, attributes, ty)
      local
        Type elemTy;
        list<Pointer<Variable>> children = {};

      case (_, _, Type.CLOCK()) then VariableKind.CLOCK();

      // variable -> artificial state if it has stateSelect = StateSelect.always
      case (NFPrefixes.Variability.CONTINUOUS, VariableAttributes.VAR_ATTR_REAL(stateSelect = SOME(NFBackendExtension.StateSelect.ALWAYS)), _)
        guard(variability == NFPrefixes.Variability.CONTINUOUS)
      then VariableKind.STATE(1, NONE(), false);

      // get external object class
      case (_, _, Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT()))
      then VariableKind.EXTOBJ(Class.constrainingClassPath(ty.cls));
      case (_, _, Type.ARRAY(elementType = elemTy as Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT())))
      then VariableKind.EXTOBJ(Class.constrainingClassPath(elemTy.cls));

      // add children pointers for records afterwards, record is considered known if it is of "less" then discrete variability
      case (_, _, Type.COMPLEX())                                     then VariableKind.RECORD({}, variability < NFPrefixes.Variability.DISCRETE);
      case (_, _, Type.ARRAY(elementType = Type.COMPLEX()))           then VariableKind.RECORD({}, variability < NFPrefixes.Variability.DISCRETE);

      case (NFPrefixes.Variability.CONTINUOUS, _, Type.BOOLEAN())     then VariableKind.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.INTEGER())     then VariableKind.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.ENUMERATION()) then VariableKind.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, _)                  then VariableKind.ALGEBRAIC();

      case (NFPrefixes.Variability.DISCRETE, _, _)                    then VariableKind.DISCRETE();
      case (NFPrefixes.Variability.IMPLICITLY_DISCRETE, _, _)         then VariableKind.DISCRETE();

      case (NFPrefixes.Variability.PARAMETER, _, _)                   then VariableKind.PARAMETER();
      case (NFPrefixes.Variability.STRUCTURAL_PARAMETER, _, _)        then VariableKind.PARAMETER(); // CONSTANT ?
      case (NFPrefixes.Variability.NON_STRUCTURAL_PARAMETER, _, _)    then VariableKind.PARAMETER();
      case (NFPrefixes.Variability.CONSTANT, _, _)                    then VariableKind.CONSTANT();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;

    // make adjustments to attributes based on variable kind
    attributes := match varKind
      case VariableKind.PARAMETER() then VariableAttributes.setFixed(attributes, ty, true, false);
      else attributes;
    end match;
  end lowerVariableKind;

  function collectVariableBindingIterators
    input output Variable var;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set;
  protected
    Option<Expression> exp_opt;
  algorithm
    BackendInfo.map(var.backendinfo, function collectIterators(variables = variables, set = set));
    exp_opt := Binding.typedExp(var.binding);
    if isSome(exp_opt) then
      Expression.map(Util.getOption(exp_opt), function collectIterators(variables = variables, set = set));
    end if;
  end collectVariableBindingIterators;

  public function lowerRecordChildren
    input Pointer<Variable> var_ptr;
    input VariablePointers variables;
  protected
    Variable var = Pointer.access(var_ptr);
  algorithm
    var := match var
      local
        BackendInfo binfo;
        VariableKind varKind;
      case Variable.VARIABLE(backendinfo = binfo as BackendInfo.BACKEND_INFO(varKind = varKind as VariableKind.RECORD())) algorithm
        // kabdelhak: why is this list reversed in the frontend? doesnt match input order
        varKind.children := listReverse(list(VariablePointers.getVarSafe(variables, ComponentRef.stripSubscriptsAll(child.name)) for child in var.children));
        // set parent for all children
        varKind.children := list(BVariable.setParent(child, var_ptr) for child in varKind.children);
        binfo.varKind := varKind;
        var.backendinfo := binfo;
      then var;
      else var;
    end match;
    Pointer.update(var_ptr, var);
  end lowerRecordChildren;

  protected function lowerEquationData
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
    UnorderedSet<VariablePointer> set = UnorderedSet.new(BVariable.hash, BVariable.equalName);
    list<Pointer<Equation>> equation_lst, continuous_lst, clocked_lst, discretes_lst, initials_lst, auxiliaries_lst, simulation_lst, removed_lst;
    EquationPointers equations;
    Pointer<Equation> eq;
    Pointer<Integer> idx = Pointer.create(0);
  algorithm
    equation_lst := lowerEquationsAndAlgorithms(eq_lst, al_lst, init_eq_lst, init_al_lst);
    for eqn_ptr in equation_lst loop
      // uniquely name the equation
      Equation.createName(eqn_ptr, idx, NBEquation.SIMULATION_STR);
      // make all iterators the same and lower them
      Equation.renameIterators(eqn_ptr, "$i");
      lowerEquationIterators(Pointer.access(eqn_ptr), VarData.getVariables(varData), set);
    end for;
    varData   := VarData.addTypedList(varData, UnorderedSet.toList(set), NBVariable.VarData.VarType.ITERATOR);
    equations := EquationPointers.fromList(equation_lst);
    equations := lowerComponentReferences(equations, VarData.getVariables(varData));

    (simulation_lst, continuous_lst, clocked_lst, discretes_lst, initials_lst, auxiliaries_lst, removed_lst) := BEquation.typeList(EquationPointers.toList(equations));

    eqData := BEquation.EQ_DATA_SIM(
      uniqueIndex = idx,
      equations   = EquationPointers.removeList(clocked_lst, equations),
      simulation  = EquationPointers.fromList(simulation_lst),
      continuous  = EquationPointers.fromList(continuous_lst),
      clocked     = EquationPointers.fromList(clocked_lst),
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
        list<IfEquationBody> bodies;

      case FEquation.ARRAY_EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source)
        guard(Type.isArray(ty)) algorithm
        attr := lowerEquationAttributes(ty, init);
      then {Pointer.create(BEquation.ARRAY_EQUATION(ty, lhs, rhs, source, attr, Type.complexSize(ty)))};

      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source) algorithm
        attr := lowerEquationAttributes(ty, init);
        result := match ty
          case Type.ARRAY()   then {Pointer.create(BEquation.ARRAY_EQUATION(ty, lhs, rhs, source, attr, Type.complexSize(ty)))};
          case Type.COMPLEX() then {Pointer.create(BEquation.RECORD_EQUATION(ty, lhs, rhs, source, attr, Type.sizeOf(ty)))};
          case Type.TUPLE()   then {Pointer.create(BEquation.RECORD_EQUATION(ty, lhs, rhs, source, attr, Type.sizeOf(ty)))};
                              else {Pointer.create(BEquation.SCALAR_EQUATION(ty, lhs, rhs, source, attr))};
        end match;
      then result;

      case FEquation.FOR(range = SOME(range)) algorithm
        if Expression.rangeSize(range) > 0 then
          // Treat each body equation individually because they can have different equation attributes
          // E.g.: DISCRETE, EvalStages
          iterator := ComponentRef.fromNode(frontend_equation.iterator, Type.INTEGER(), {}, NFComponentRef.Origin.ITERATOR);
          for eq in frontend_equation.body loop
            for body_elem_ptr in lowerEquation(eq, init) loop
              body_elem := Pointer.access(body_elem_ptr);
              new_body := match body_elem
                case Equation.IF_EQUATION() algorithm
                  bodies := IfEquationBody.split(body_elem.body);
                  for body in bodies loop
                    new_body := Pointer.create(BEquation.IF_EQUATION(IfEquationBody.size(body), body, body_elem.source, body_elem.attr)) :: new_body;
                  end for;
                then new_body;
                else body_elem_ptr :: new_body;
              end match;
            end for;
          end for;
          for body_elem_ptr in new_body loop
            body_elem := Pointer.access(body_elem_ptr);
            body_elem := BEquation.FOR_EQUATION(
              size    = Expression.rangeSize(range) * Equation.size(body_elem_ptr),
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
      case FEquation.IF() then lowerIfEquation(frontend_equation, init);

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
    output list<Pointer<Equation>> backend_equations;
  algorithm
    backend_equations := match frontend_equation
      local
        list<FEquation.Branch> branches;
        DAE.ElementSource source;
        IfEquationBody ifEqBody;
        list<IfEquationBody> bodies;
        EquationAttributes attr;

      case FEquation.IF(branches = branches, source = source)
        algorithm
          attr      := EquationAttributes.default(EquationKind.CONTINUOUS, init);
          ifEqBody  := lowerIfEquationBody(branches, init);
          bodies    := IfEquationBody.split(ifEqBody);
      then list(IfEquationBody.toEquation(body, source, init) for body in bodies);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + FEquation.toString(frontend_equation)});
      then fail();

    end match;
  end lowerIfEquation;

  function lowerIfEquationBody
    input list<FEquation.Branch> branches;
    input Boolean init;
    output IfEquationBody ifEq;
  algorithm
    ifEq := match branches
      local
        FEquation.Branch branch;
        list<FEquation.Branch> rest;
        list<Pointer<Equation>> eqns;
        Expression condition;
        IfEquationBody result;

      // lower current branch
      case branch::rest
        algorithm
          (eqns, condition) := lowerIfBranch(branch, init);
          if Expression.isTrue(condition) then
            // finish recursion when a condition is found to be true because
            // following branches can never be reached. Also the last plain else
            // case has default Boolean true value in the NF.
            result := BEquation.IF_EQUATION_BODY(Expression.END(), eqns, NONE());
          elseif Expression.isFalse(condition) then
            // discard a branch and continue with the rest if a condition is
            // found to be false, because it can never be reached.
            result := lowerIfEquationBody(rest, init);
          else
            result := BEquation.IF_EQUATION_BODY(condition, eqns, SOME(lowerIfEquationBody(rest, init)));
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
          SOME(whenEqBody) := lowerWhenEquationBody(branches);
          bodies := BEquation.WhenEquationBody.split(whenEqBody);
      then list(Pointer.create(BEquation.WHEN_EQUATION(
        size    = BEquation.WhenEquationBody.size(b),
        body    = b,
        source  = source,
        attr    = EquationAttributes.default(if BEquation.WhenEquationBody.size(b) > 0 then EquationKind.DISCRETE else EquationKind.EMPTY, init)
      )) for b in bodies);

      case FEquation.ASSERT(condition = condition, message = message, level = level, source = source)
        algorithm
          attr := EquationAttributes.default(EquationKind.EMPTY, init);
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
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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

  public function lowerAlgorithm
    input Algorithm alg;
    input Boolean init;
    output Pointer<Equation> eq;
  protected
    Integer size;
    list<ComponentRef> inputs, outputs;
    EquationAttributes attr;
  algorithm
    size := sum(ComponentRef.size(out, true) for out in alg.outputs);

    if listEmpty(alg.outputs) then
      attr := EquationAttributes.default(EquationKind.EMPTY, init);
    elseif ComponentRef.listHasDiscrete(alg.outputs) then
      attr := EquationAttributes.default(EquationKind.DISCRETE, init);
    else
      attr := EquationAttributes.default(EquationKind.CONTINUOUS, init);
    end if;
    eq := Pointer.create(Equation.ALGORITHM(size, alg, alg.source, DAE.EXPAND(), attr));
  end lowerAlgorithm;

  protected function lowerEquationAttributes
    input Type ty;
    input Boolean init;
    output EquationAttributes attr;
  algorithm
    if Type.isClock(ty) then
      attr := EquationAttributes.default(EquationKind.CLOCKED, init, SOME(-1));
    elseif Type.isDiscrete(ty) then
      attr := EquationAttributes.default(EquationKind.DISCRETE, init);
    else
      attr := EquationAttributes.default(EquationKind.CONTINUOUS, init);
    end if;
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

  function collectIterators
    "collects all iterators in expressions and creates variables for them.
    in bindings they are only known locally but they still need a respective variable"
    input output Expression exp;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set;
  algorithm
    try
    () := match exp
      local
        Call call;

      case Expression.CREF() guard(not (VariablePointers.containsCref(exp.cref, variables)
        or ComponentRef.isNameNode(exp.cref) or ComponentRef.isWild(exp.cref))) algorithm
        UnorderedSet.add(lowerIterator(exp.cref), set);
      then ();

      case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
        for tpl in call.iters loop
          collectIterator(Util.tuple21(tpl), variables, set);
        end for;
      then ();

      case Expression.CALL(call = call as Call.TYPED_REDUCTION()) algorithm
        for tpl in call.iters loop
          collectIterator(Util.tuple21(tpl), variables, set);
        end for;
      then ();
      else ();
    end match;
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + Expression.toString(exp)});
      fail();
    end try;
  end collectIterators;

  function collectIterator
    "collects all iterators in bindings and creates variables for them.
    in bindings they are only known locally but they still need a respective variable"
    input InstNode iterator;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set;
  protected
    ComponentRef cref;
  algorithm
    cref := ComponentRef.fromNode(iterator, InstNode.getType(iterator), {}, NFComponentRef.Origin.ITERATOR);
    if not VariablePointers.containsCref(cref, variables) then
      UnorderedSet.add(lowerIterator(cref), set);
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

  function lowerEquationIterators
    "lowers all iterators that occur in this equation and
    add the generated variables to a set"
    input output Equation eqn;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set;
  protected
    Iterator iter = Equation.getForIterator(eqn);
    list<ComponentRef> iterators;
  algorithm
    // get all iterators from the for-loop-frames (if there are any)
    (iterators, _) := Iterator.getFrames(iter);
    for iter in iterators loop
      UnorderedSet.add(lowerIterator(iter), set);
    end for;
    // get all iterators from the equation body
    Equation.map(eqn, function collectIterators(variables = variables, set = set));
  end lowerEquationIterators;

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

  function lowerFunctions
    input output FunctionTree funcTree;
  protected
    // ToDo: replace all function trees with this UnorderedMap
    UnorderedMap<Path, Function> functions = UnorderedMap.new<Function>(AbsynUtil.pathHash, AbsynUtil.pathEqual);
  protected
    Path path;
    Function fn;
  algorithm
    for tpl in FunctionTree.toList(funcTree) loop
      (path, fn) := tpl;
      (fn, funcTree) := Differentiate.resolvePartialDerivatives(fn, funcTree);
      UnorderedMap.add(path, fn, functions);
    end for;
  end lowerFunctions;

  function backenddaeinfo
    input BackendDAE bdae;
  algorithm
    if Flags.isSet(Flags.DUMP_BACKENDDAE_INFO) then
      _ := match bdae
        local
          VarData varData;
          EqData eqData;
          String p_ode, p_alg, p_ode_e, p_alg_e, p_clk, p_ini, p_ini_0;
          String states, discretes, discrete_states, clocked_states, clocks, inputs;

        case MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM()) algorithm
          // collect partition size info
          p_ode   := intString(listLength(bdae.ode));
          p_alg   := intString(listLength(bdae.algebraic));
          p_ode_e := intString(listLength(bdae.ode_event));
          p_alg_e := intString(listLength(bdae.alg_event));
          p_clk   := "0";
          p_ini   := intString(listLength(bdae.init));
          p_ini_0 := if isSome(bdae.init_0) then intString(listLength(Util.getOption(bdae.init_0))) else "0";

          // collect variable info
          states          := intString(VariablePointers.scalarSize(varData.states)) + " (" + intString(VariablePointers.size(varData.states)) + ")";
          discretes       := intString(VariablePointers.scalarSize(varData.discretes)) + " (" + intString(VariablePointers.size(varData.discretes)) + ")";
          discrete_states := intString(VariablePointers.scalarSize(varData.discrete_states)) + " (" + intString(VariablePointers.size(varData.discrete_states)) + ")";
          clocked_states  := intString(VariablePointers.scalarSize(varData.clocked_states)) + " (" + intString(VariablePointers.size(varData.clocked_states)) + ")";
          clocks          := intString(VariablePointers.scalarSize(varData.clocks)) + " (" + intString(VariablePointers.size(varData.clocks)) + ")";
          inputs          := intString(VariablePointers.scalarSize(varData.top_level_inputs)) + " (" + intString(VariablePointers.size(varData.top_level_inputs)) + ")";

          if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) then
            states := states + " " + List.toString(VariablePointers.toList(varData.states), BVariable.nameString);
          else
            states := states + " ('-d=stateselection' for the list of states)";
          end if;

          if Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO) then
            discretes := discretes + " " + List.toString(VariablePointers.toList(varData.discretes), BVariable.nameString);
            clocks := clocks + " " + List.toString(VariablePointers.toList(varData.clocks), BVariable.nameString);
            inputs := inputs + " " + List.toString(VariablePointers.toList(varData.top_level_inputs), BVariable.nameString);
          else
            discretes := discretes + " ('-d=discreteinfo' for the list of discrete variables)";
            clocks := clocks + " ('-d=discreteinfo' for the list of clocks variables)";
            inputs := inputs + " ('-d=discreteinfo' for the list of top level inputs)";
          end if;

          if  Flags.isSet(Flags.DUMP_STATESELECTION_INFO) or Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO) then
            discrete_states := discrete_states + " " + List.toString(VariablePointers.toList(varData.discrete_states), BVariable.nameString);
            clocked_states := clocked_states + " " + List.toString(VariablePointers.toList(varData.clocked_states), BVariable.nameString);
          else
            discrete_states := discrete_states + " ('-d=discreteinfo' or '-d=stateselection' for the list of discrete states)";
            clocked_states := clocked_states + " ('-d=discreteinfo' or '-d=stateselection' for the list of clocked states)";
          end if;

          Error.addCompilerNotification(
            "Partition statistics after passing the back-end:\n"
            + " * Number of ODE partitions: ..................... " + p_ode + "\n"
            + " * Number of algebraic partitions: ............... " + p_alg + "\n"
            + " * Number of ODE event partitions: ............... " + p_ode_e + "\n"
            + " * Number of algebraic event partitions: ......... " + p_alg_e + "\n"
            + " * Number of clocked partitions: ................. " + p_clk + "\n"
            + " * Number of initial partitions: ................. " + p_ini + "\n"
            + " * Number of initial(lambda=0) partitions: ....... " + p_ini_0);

          Error.addCompilerNotification(
            "Variable statistics after passing the back-end:\n"
            + " * Number of states: ............................. " + states + "\n"
            + " * Number of discrete states: .................... " + discrete_states + "\n"
            + " * Number of clocked states: ..................... " + clocked_states + "\n"
            + " * Number of discrete variables: ................. " + discretes + "\n"
            + " * Number of clocks: ............................. " + clocks + "\n"
            + " * Number of top-level inputs: ................... " + inputs);

          // collect strong component info simulation
          strongcomponentinfo("Simulation", {bdae.ode, bdae.algebraic, bdae.ode_event, bdae.alg_event});
          // collect strong component info initialization
          strongcomponentinfo("Initialization", {bdae.init});
          if Util.isSome(bdae.init_0) then
            strongcomponentinfo("Initialization (lambda=0)", {Util.getOption(bdae.init_0)});
          end if;

        then ();
      end match;
    end if;
  end backenddaeinfo;

  function strongcomponentinfo
    input String phase;
    input list<list<Partition>> systems;
  protected
    CountCollector c = CountCollector.COUNT_COLLECTOR(0,0,0,0,0,0,0,0,0,0,0);
    Pointer<CountCollector> collector_ptr = Pointer.create(c);
    String single_sc, multi_sc, for_sc, alg_sc;
  algorithm
    for lst in systems loop
      for system in lst loop
        Partition.mapStrongComponents(system, function StrongComponent.strongComponentInfo(collector_ptr = collector_ptr));
      end for;
    end for;
    c := Pointer.access(collector_ptr);
    single_sc := intString(c.single_scalar + c.single_array + c.single_record) + " (scalar:" + intString(c.single_scalar) + ", array:" + intString(c.single_array) + ", record:" + intString(c.single_record) + ")";
    multi_sc := intString(c.multi_algorithm + c.multi_when + c.multi_if) + " (algorithm:" + intString(c.multi_algorithm) + ", when:" + intString(c.multi_when) + ", if:" + intString(c.multi_if) + ", tuple:" + intString(c.multi_tpl) + ")";
    for_sc := intString(c.generic_for + c.entwined_for) + " (generic: " + intString(c.generic_for) + ", entwined:" + intString(c.entwined_for) + ")";
    alg_sc := intString(c.loop_lin + c.loop_nlin) + " (linear: " + intString(c.loop_lin) + ", nonlinear:" + intString(c.loop_nlin) + ")";

    Error.addCompilerNotification(
      "[" + phase + "] Strong Component statistics after passing the back-end:\n"
      + " * Number of single strong components: ........... " + single_sc + "\n"
      + " * Number of multi strong components: ............ " + multi_sc + "\n"
      + " * Number of for-loop strong components: ......... " + for_sc + "\n"
      + " * Number of algebraic-loop strong components: ... " + alg_sc);
  end strongcomponentinfo;

  annotation(__OpenModelica_Interface="backend");
end NBackendDAE;
