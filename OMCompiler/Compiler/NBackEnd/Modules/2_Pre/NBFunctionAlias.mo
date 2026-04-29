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

encapsulated package NBFunctionAlias
"file:        NBFunctionAlias.mo
 package:     NBFunctionAlias
 description: This file contains the functions for the function alias encapsulation module.
"
public
  import Module = NBModule;
protected
  // OF imports
  import Absyn;
  import AbsynUtil;
  import DAE;

  // NF imports
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFFunction.Function;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import Inline = NBInline;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes, EquationKind, Iterator};
  import Partition = NBPartition;
  import Partitioning = NBPartitioning;
  import NBPartitioning.BClock;
  import Slice = NBSlice;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers, VarData};

  // Util imports
  import StringUtil;
  import UnorderedMap;
public
  function main
    "Wrapper function for any function alias introduction function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
    input Partition.Kind kind;
  protected
    Module.aliasInterface func;
  algorithm
    (func) := getModule();

    bdae := match bdae
      local
        VarData varData         "Data containing variable pointers";
        EqData eqData           "Data containing equation pointers";

      case BackendDAE.MAIN(varData = varData, eqData = eqData)
        algorithm
          (varData, eqData) := func(varData, eqData, kind);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case BackendDAE.HESSIAN(varData = varData, eqData = eqData)
        algorithm
          (varData, eqData) := func(varData, eqData, kind);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.functionAliasInterface func;
  protected
    String flag = "default";
  algorithm
    func := match flag
      case "default" then functionAliasDefault;
      /* ... New function alias modules have to be added here */
      else fail();
    end match;
  end getModule;

  function introduceSlicedStateAlias
    "introduces alias for variables that are only partially states to ensure variables are either a state in their entirety or not a state at all.
    to be used in DetectStates, just before the der() calls are resolved.
    1. collect all crefs in der() calls that do not fully access the variable
    2. check if any variable is not fully a state by combining all their sliced der() calls
    3. replace all variables that are not fully states by alias variables and create equations"
    extends Module.functionAliasInterface;
  protected
    UnorderedMap<Call_Id, Call_Aux> aux_map = UnorderedMap.new<Call_Aux>(Call_Id.hash, Call_Id.isEqual);
    list<Pointer<Variable>> new_vars_cont = {}, new_vars_recd = {};
    list<Pointer<Equation>> new_eqns_cont = {};
  algorithm
    _ := match (eqData, varData)
      local
        UnorderedMap<ComponentRef,Indices> map = UnorderedMap.new<Indices>(ComponentRef.hash, ComponentRef.isEqual);
        UnorderedSet<ComponentRef> set;
        Pointer<Integer> aux_index = Pointer.create(1);

      case (EqData.EQ_DATA_SIM(), VarData.VAR_DATA_SIM()) algorithm
        // first collect all state slices
        EquationPointers.map(eqData.simulation, function collectSlicedStatesAliasEquation(map = map));
        set := getSlicedStatesSet(map);

        if not UnorderedSet.isEmpty(set) then
          // replace all state slices of variables that are only partially states
          eqData.simulation := EquationPointers.map(eqData.simulation, function introduceSlicedStateAliasEquation(set = set, map = aux_map, aux_index = aux_index));

          // create new state slice variables and corresponding equations for the alias
          (_, new_vars_cont, _, new_vars_recd, _, new_eqns_cont, _) :=
            resolveAux(aux_map, eqData.uniqueIndex, false, {}, new_vars_cont, {}, new_vars_recd, {}, new_eqns_cont, {});
        end if;
      then ();
      else ();
    end match;

    // add the new variables and equations (should only be continuous, states are still considered algebraic)
    varData := VarData.addTypedList(varData, new_vars_cont, VarData.VarType.ALGEBRAIC);
    varData := VarData.addTypedList(varData, new_vars_recd, VarData.VarType.RECORD);
    eqData  := EqData.addTypedList(eqData, new_eqns_cont, EqData.EqType.CONTINUOUS, false);

    // update record children
    for var in new_vars_recd loop
      BackendDAE.lowerRecordChildren(var, VarData.getVariables(varData));
    end for;

    // dump if flag is set
    if Flags.isSet(Flags.DUMP_CSE) then
      print(aliasListToString(UnorderedMap.toList(aux_map), Call_Id.toString, Call_Aux.toString, "Sliced State"));
    end if;
  end introduceSlicedStateAlias;

protected
  uniontype Call_Id
    "key for UnorderedMap.
    used to uniquely identify a function call"
    record CALL_ID
      Expression call;
      Iterator iter;
      // ToDo: instead of skipping when and if, one could collect these conditions
      //    and create the function call equations with them.
      // Note: update hashing, isEqual and take into account that there can be
      //    elseif/elsewhen which need to be chained
      // Option<Expression> when_condition
      // Option<Expression> if_condition
    end CALL_ID;

    function toString
      input Call_Id id;
      output String str;
    algorithm
      str := if not Iterator.isEmpty(id.iter) then " [" + Iterator.toString(id.iter) + "]" else "";
      str := Expression.toString(id.call) + str;
    end toString;

    function hash
      "just hashes the id based on its string representation"
      input Call_Id id;
      output Integer hash;
    algorithm
      hash := stringHashDjb2(toString(id));
    end hash;

    function isEqual
      input Call_Id id1;
      input Call_Id id2;
      output Boolean b;
    algorithm
      b := Expression.isEqual(id1.call, id2.call) and Iterator.isEqual(id1.iter, id2.iter);
    end isEqual;
  end Call_Id;

  uniontype Call_Aux
    "value for UnorderedMap.
    represents the auxilliary variable that will be created and has
    the equation kind for auxilliary equation."
    record CALL_AUX
      Expression replacer;
      EquationKind kind;
      Boolean parsed;
    end CALL_AUX;

    function toString
      input Call_Aux aux;
      output String str = Expression.toString(aux.replacer);
    end toString;

    function getVars
      input Call_Aux aux;
      output list<Pointer<Variable>> vars = getVarsExp(aux.replacer);
    protected
      function getVarsExp
        input Expression exp;
        output list<Pointer<Variable>> vars;
      algorithm
        vars := match exp
          case Expression.CREF(cref = ComponentRef.WILD()) then {};
          case Expression.CREF()    then {BVariable.getVarPointer(exp.cref, sourceInfo())};
          case Expression.TUPLE()   then List.flatten(list(getVarsExp(elem) for elem in exp.elements));
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because function alias auxilliary has a return type that currently cannot be parsed: " + Expression.toString(exp)});
          then fail();
        end match;
      end getVarsExp;
    end getVars;

    function createName
      input Type ty;
      input Iterator iter;
      input Pointer<Integer> aux_index;
      input String aux_name;
      input Boolean init;
      output ComponentRef name;
    protected
      Type new_ty = ty;
      list<Subscript> subs;
    algorithm
      if not Iterator.isEmpty(iter) then
        new_ty    := Type.liftArrayRightList(ty, Iterator.dimensions(iter));
        (_, name) := BVariable.makeAuxVar(aux_name, Pointer.access(aux_index), new_ty, init);
        // add iterators to subscripts of auxilliary variable. fill with WHOLE if necessary
        subs      := Iterator.normalizedSubscripts(iter);
        subs      := Subscript.fillWithWholeLeft(subs, Type.dimensionCount(new_ty));
        name      := ComponentRef.mergeSubscripts(subs, name, true, true);
      else
        (_, name) := BVariable.makeAuxVar(aux_name, Pointer.access(aux_index), new_ty, init);
      end if;
      Pointer.update(aux_index, Pointer.access(aux_index) + 1);
    end createName;
  end Call_Aux;

  function functionAliasTplString
    input tuple<String, String> tpl;
    input Integer max_length;
    output String str;
  algorithm
    str := Util.tuple21(tpl) + " " + StringUtil.repeat(".", max_length - stringLength(Util.tuple21(tpl))) + " " + Util.tuple22(tpl);
  end functionAliasTplString;

  function functionAliasDefault
    extends Module.functionAliasInterface;
  protected
    UnorderedMap<Call_Id, Call_Aux> map = UnorderedMap.new<Call_Aux>(Call_Id.hash, Call_Id.isEqual);
    VariablePointers variables = VarData.getVariables(varData);
    UnorderedSet<VariablePointer> set = UnorderedSet.new(BVariable.hash, BVariable.equalName) "new iterators";
    UnorderedMap<BClock, ComponentRef> clock_map, infer_map;
    Pointer<Integer> aux_index = Pointer.create(1);
    list<Pointer<Variable>> new_vars_disc = {}, new_vars_cont = {}, new_vars_init = {}, new_vars_recd = {}, new_vars_clck, new_vars_infr;
    list<Pointer<Equation>> new_eqns_disc = {}, new_eqns_cont = {}, new_eqns_init = {}, new_eqns_clck, new_eqns_infr;
    list<tuple<Call_Id, Call_Aux>> debug_lst_sim = {}, debug_lst_ini;
  algorithm
    _ := match (eqData, varData)
      case (EqData.EQ_DATA_SIM(), VarData.VAR_DATA_SIM()) algorithm
        // first collect all new functions from simulation equations
        eqData.simulation := EquationPointers.map(eqData.simulation,
          function introduceFunctionAliasEquation(map = map, variables = variables, set = set, aux_index = aux_index, eqn_index = eqData.uniqueIndex, init = false));

        // also collect all new functions from removed equations
        eqData.removed := EquationPointers.map(eqData.removed,
          function introduceFunctionAliasEquation(map = map, variables = variables, set = set, aux_index = aux_index, eqn_index = eqData.uniqueIndex, init = false));

        // create new simulation variables and corresponding equations for the function alias
        (new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, new_eqns_disc, new_eqns_cont, new_eqns_init) :=
          resolveAux(map, eqData.uniqueIndex, false, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, new_eqns_disc, new_eqns_cont, new_eqns_init);

        if Flags.isSet(Flags.DUMP_CSE) then
          debug_lst_sim := UnorderedMap.toList(map);
        end if;

        // afterwards collect all functions from initial equations
        eqData.initials := EquationPointers.map(eqData.initials,
          function introduceFunctionAliasEquation(map = map, variables = variables, set = set, aux_index = aux_index, eqn_index = eqData.uniqueIndex, init = true));

        // add parameter function alias
        varData.parameters := VariablePointers.mapPtr(varData.parameters,
          function BVariable.mapExp(funcExp = function introduceFunctionAlias(map = map, aux_index = aux_index, iter = Iterator.EMPTY(), init = true),
          mapFunc = Expression.fakeMap));

        // create new initialization variables and corresponding equations for the function alias
        (new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, new_eqns_disc, new_eqns_cont, new_eqns_init) :=
          resolveAux(map, eqData.uniqueIndex, true, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, new_eqns_disc, new_eqns_cont, new_eqns_init);

        // create clock alias equations
        (new_eqns_clck, new_eqns_infr, new_vars_clck, new_vars_infr, clock_map, infer_map) := addClockedAlias(eqData.simulation, eqData.uniqueIndex);
      then ();
      else ();
    end match;

    // add the new variables and equations.
    // Note: inferred clocks are handled as unknowns to properly partition them
    varData := VarData.addTypedList(varData, new_vars_cont, VarData.VarType.ALGEBRAIC);
    varData := VarData.addTypedList(varData, new_vars_disc, VarData.VarType.DISCRETE);
    varData := VarData.addTypedList(varData, new_vars_init, VarData.VarType.PARAMETER);
    varData := VarData.addTypedList(varData, new_vars_recd, VarData.VarType.RECORD);
    varData := VarData.addTypedList(varData, new_vars_clck, VarData.VarType.CLOCK);
    varData := VarData.addTypedList(varData, new_vars_infr, VarData.VarType.DISCRETE);
    varData := VarData.addTypedList(varData, UnorderedSet.toList(set), VarData.VarType.ITERATOR);
    eqData  := EqData.addTypedList(eqData, new_eqns_cont, EqData.EqType.CONTINUOUS, false);
    eqData  := EqData.addTypedList(eqData, new_eqns_disc, EqData.EqType.DISCRETE, false);
    eqData  := EqData.addTypedList(eqData, new_eqns_init, EqData.EqType.INITIAL, false);
    eqData  := EqData.addTypedList(eqData, new_eqns_clck, EqData.EqType.CLOCKED, false);
    eqData  := EqData.addTypedList(eqData, new_eqns_infr, EqData.EqType.DISCRETE, false);

    // update record children
    for var in new_vars_recd loop
      BackendDAE.lowerRecordChildren(var, VarData.getVariables(varData));
    end for;

    // dump if flag is set
    if Flags.isSet(Flags.DUMP_CSE) then
      // remove sim vars from final map to see whats exclusively initial
      for tpl in debug_lst_sim loop
        UnorderedMap.remove(Util.tuple21(tpl), map);
      end for;
      debug_lst_ini := UnorderedMap.toList(map);
      print(aliasListToString(debug_lst_sim, Call_Id.toString, Call_Aux.toString, "Simulation Function"));
      print(aliasListToString(debug_lst_ini, Call_Id.toString, Call_Aux.toString, "Initial Function"));
      print(aliasListToString(UnorderedMap.toList(clock_map), BClock.toString, ComponentRef.toString, "Clocked Function"));
      print(aliasListToString(UnorderedMap.toList(infer_map), BClock.toString, ComponentRef.toString, "Inferred Clocked Function"));
    end if;
  end functionAliasDefault;

  function aliasListToString<T1, T2>
    input list<tuple<T1, T2>> aux_lst;
    input idToString func1;
    input auxToString func2;
    input String name;
    output String str;
  protected
    list<tuple<String, String>> str_lst;
    Integer max_length;
    partial function idToString<T1>
      input T1 t1;
      output String str;
    end idToString;
    partial function auxToString<T2>
      input T2 t2;
      output String str;
    end auxToString;
  algorithm
      str := StringUtil.headline_3(name + " Alias");
      if listEmpty(aux_lst) then
        str := str + "  <no alias>\n\n";
      else
        str_lst := list((func2(Util.tuple22(tpl)), func1(Util.tuple21(tpl))) for tpl in aux_lst);
        max_length := max(stringLength(Util.tuple21(tpl)) for tpl in str_lst) + 3;
        str := str + List.toString(str_lst, function functionAliasTplString(max_length = max_length), "", "  ", "\n  ", "\n\n");
      end if;
  end aliasListToString;

  function resolveAux
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> eq_index;
    input Boolean init;
    input output list<Pointer<Variable>> new_vars_disc;
    input output list<Pointer<Variable>> new_vars_cont;
    input output list<Pointer<Variable>> new_vars_init;
    input output list<Pointer<Variable>> new_vars_recd;
    input output list<Pointer<Equation>> new_eqns_disc;
    input output list<Pointer<Equation>> new_eqns_cont;
    input output list<Pointer<Equation>> new_eqns_init;
  protected
    Call_Id id;
    Call_Aux aux;
    Boolean disc;
    Pointer<Equation> new_eqn;
    list<Pointer<Variable>> new_vars;
  algorithm
    // create new simulation variables and corresponding equations for the function alias
    for tpl in listReverse(UnorderedMap.toList(map)) loop
      (id, aux) := tpl;
      // only create new var and eqn if there is not already parsed
      if not aux.parsed then
        new_vars  := Call_Aux.getVars(aux);
        disc      := true;

        // categorize all aux variables
        for new_var in new_vars loop
          (disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd) := addAuxVar(new_var, disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, init);
        end for;

        // if any of the created variables is continuous, so is the equation
        new_eqn := Equation.makeAssignment(aux.replacer, id.call, eq_index, "AUX", id.iter, EquationAttributes.default(aux.kind, init));
        if init then
          new_eqns_init := new_eqn :: new_eqns_init;
        elseif disc then
          new_eqns_disc := new_eqn :: new_eqns_disc;
        else
          new_eqns_cont := new_eqn :: new_eqns_cont;
        end if;

        aux.parsed := true;
        UnorderedMap.add(id, aux, map);
      end if;
    end for;
  end resolveAux;

  function introduceFunctionAliasEquation
    "creates auxilliary variables for all not inlineable function calls in the equation"
    input output Equation eqn;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> aux_index;
    input Pointer<Integer> eqn_index;
    input Boolean init;
  protected
    Iterator iter;
    type Depth = enumeration(FULL, CONDITION, STOP);
    Depth depth;
  algorithm
    // inline trivial array constructors first
    eqn := Inline.inlineArrayConstructorSingle(eqn, Iterator.EMPTY(), variables, set, eqn_index);

    // get iterator and determine if it needs to be checked further
    (iter, depth) := match eqn
      local
        Equation body;
      case Equation.FOR_EQUATION(body = {body}) then (eqn.iter, if Equation.isWhenEquation(Pointer.create(body))
                                                                or Equation.isIfEquation(Pointer.create(body))
                                                                then Depth.CONDITION else Depth.FULL);
      case Equation.WHEN_EQUATION()             then (Iterator.EMPTY(), Depth.CONDITION);
      case Equation.IF_EQUATION()               then (Iterator.EMPTY(), Depth.CONDITION);
      case Equation.ALGORITHM()                 then (Iterator.EMPTY(), Depth.STOP);
                                                else (Iterator.EMPTY(), Depth.FULL);
    end match;

    // do the function alias replacement
    if depth == Depth.FULL then
      eqn := Equation.map(eqn, function introduceFunctionAlias(map = map, aux_index = aux_index, iter = iter, init = init), NONE(), Expression.fakeMap);
    elseif depth == Depth.CONDITION then
      eqn := Equation.mapCondition(eqn, function introduceFunctionAlias(map = map, aux_index = aux_index, iter = iter, init = init), NONE(), Expression.fakeMap);
    end if;
  end introduceFunctionAliasEquation;

  function introduceFunctionAlias
    "checks if an expression is a function call and replaces it with auxilliary if not inlinable
    map with Equation.map() or Expression.map()
    ToDo: also exclude special functions der(), pre(), ..."
    input output Expression exp;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> aux_index;
    input Iterator iter;
    input Boolean init;
  protected
    Iterator deep_iter;
  algorithm
    // add local iterators to deep recursion
    deep_iter := match exp
      case Expression.CALL() then Iterator.expand(iter, exp.call);
      else iter;
    end match;
    exp := Expression.mapShallow(exp, function introduceFunctionAlias(map = map, aux_index = aux_index, iter = deep_iter, init = init));

    // use the original iterator for local analysis
    exp := match exp
      local
        Call call;
        Expression new_exp, sub_exp;

      case Expression.CALL() guard(checkCallReplacement(exp.call)) then introduceAlias(exp, map, aux_index, NBVariable.FUNCTION_STR, iter, init);

      // create alias for array constructors as arguments to functions
      case new_exp as Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        call.arguments  := list(Expression.map(arg, function introduceArrayConstructorAlias(map = map, aux_index = aux_index, iter = iter, init = init)) for arg in call.arguments);
        new_exp.call    := call;
      then new_exp;

      // create alias for array constructors in multaries and binaries
      // Note: do not map! only replace top lvl constructors
      case Expression.MULTARY() algorithm
        exp.arguments     := list(introduceArrayConstructorAlias(arg, map, aux_index, iter, init) for arg in exp.arguments);
        exp.inv_arguments := list(introduceArrayConstructorAlias(arg, map, aux_index, iter, init) for arg in exp.inv_arguments);
      then exp;
      case Expression.BINARY() algorithm
        exp.exp1 := introduceArrayConstructorAlias(exp.exp1, map, aux_index, iter, init);
        exp.exp2 := introduceArrayConstructorAlias(exp.exp2, map, aux_index, iter, init);
      then exp;

      // remove tuple expressions that occur when using a function only for one output
      // y = fun(x)[1] where fun() has multiple outputs
      // we create y = ($FUN1, $FUN2)[1] and simplify to y = $FUN1
      case Expression.TUPLE_ELEMENT(tupleExp = sub_exp as Expression.TUPLE()) algorithm
        if exp.index > listLength(sub_exp.elements) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get subscripted tuple element: " + Expression.toString(exp)});
          fail();
        else
          new_exp := listGet(sub_exp.elements, exp.index);
        end if;
      then new_exp;

      // do nothing if not function call or inlineable
      else exp;
    end match;
  end introduceFunctionAlias;

  function introduceArrayConstructorAlias
    "introduces alias variables for array constructor and reduction calls"
    input output Expression exp;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> aux_index;
    input Iterator iter;
    input Boolean init;
  algorithm
    exp := match exp
      case Expression.CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR()) then introduceAlias(exp, map, aux_index,  NBVariable.FUNCTION_STR, iter, init);
      case Expression.CALL(call = Call.TYPED_REDUCTION()) then introduceAlias(exp, map, aux_index,  NBVariable.FUNCTION_STR, iter, init);
      else exp;
    end match;
  end introduceArrayConstructorAlias;

  function introduceAliasCrefConditional
    "introduces alias variables for crefs, only if they are in the set"
    input output Expression exp;
    input UnorderedSet<ComponentRef> set;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> aux_index;
    input Iterator iter;
    input Boolean init;
  algorithm
    exp := match exp
      case Expression.CREF() guard(UnorderedSet.contains(ComponentRef.stripSubscriptsAll(exp.cref), set))
      then introduceAlias(exp, map, aux_index,  NBVariable.STATE_ALIAS_STR, iter, init);
      else exp;
    end match;
  end introduceAliasCrefConditional;

  function introduceAlias
    "introduces alias variables for any expression.
    Extra handling for cat() and promotion() calls."
    input output Expression exp;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> aux_index;
    input String aux_name;
    input Iterator iter;
    input Boolean init;
  protected
    list<ComponentRef> names;
    list<Expression> ranges;
    list<Option<Iterator>> maps;
    Iterator new_iter;
    Call_Id id;
    ComponentRef name;
    Type ty;
    Call_Aux aux;
    Option<Call_Aux> aux_opt;
    list<Expression> tpl_lst;
  algorithm
    // strip nested iterator for the iterators that actually occure in the function call
    if not Iterator.isEmpty(iter) then
      (names, ranges, maps) := Iterator.getFrames(iter);
      new_iter := Iterator.fromFrames(filterFrames(exp, names, ranges, maps));
    else
      new_iter := iter;
    end if;

    // check if call id already exists in the map
    id      := CALL_ID(exp, new_iter);
    aux_opt := UnorderedMap.get(id, map);
    if isSome(aux_opt) then
      aux := Util.getOption(aux_opt);
      exp := aux.replacer;
    else
      // create auxilliary variables for each cat call argument as well (needed for inline)
      (exp, aux_opt) := match exp
        local
          Call call;
          Expression arg1, arg2;

        case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
          _ := match (Call.functionName(call), call.arguments)
            case (Absyn.IDENT(name = "cat"), _) algorithm
              call.arguments  := listHead(call.arguments) :: list(if Expression.isLiteral(arg) or Expression.isCref(arg) then arg
                else introduceAlias(arg, map, aux_index, aux_name, iter, init) for arg in listRest(call.arguments));
              exp.call        := call;
              id              := CALL_ID(exp, new_iter);
              // double check if after replacing cat() call arguments the ID already exists
              aux_opt         := UnorderedMap.get(id, map);
            then ();

            case (Absyn.IDENT(name = "promote"), {arg1, arg2}) algorithm
              call.arguments  := {if Expression.isLiteral(arg1) or Expression.isCref(arg1) then arg1
                else introduceAlias(arg1, map, aux_index, aux_name, iter, init), arg2};
              exp.call        := call;
              id              := CALL_ID(exp, new_iter);
              // double check if after replacing promote() call arguments the ID already exists
              aux_opt         := UnorderedMap.get(id, map);
            then ();

            else ();
          end match;
        then (exp, aux_opt);
        else (exp, aux_opt);
      end match;

      // for initial systems create parameters, otherwise use type to determine variable kind
      ty := Expression.typeOf(exp);
      exp := match (aux_opt, ty)
        case (SOME(aux), _) then aux.replacer;
        case (_, Type.TUPLE()) algorithm
          names   := list(Call_Aux.createName(sub_ty, new_iter, aux_index, aux_name, init) for sub_ty in ty.types);
          tpl_lst := list(if ComponentRef.size(cref, true) == 0 then Expression.fromCref(ComponentRef.WILD()) else Expression.fromCref(cref) for cref in names);
        then Expression.TUPLE(ty, tpl_lst);
        else algorithm
          name := Call_Aux.createName(ty, new_iter, aux_index, aux_name, init);
        then Expression.fromCref(name);
      end match;

      if Util.isNone(aux_opt) then
        // create auxilliary and add to map if there was none before
        aux := CALL_AUX(exp, if Type.isDiscrete(ty) then EquationKind.DISCRETE else EquationKind.CONTINUOUS, false);
        UnorderedMap.add(id, aux, map);
      end if;
    end if;
  end introduceAlias;

  function checkCallReplacement
    "returns true if the call should be replaced"
    input Call call;
    output Boolean b;
  protected
    Function fn = Call.typedFunction(call);
  algorithm
    b := forceReplacement(fn) or not (Inline.functionInlineable(fn) or Function.isSpecialBuiltin(fn) or replaceException(fn));
  end checkCallReplacement;

  function forceReplacement
    "returns true if the call has to be force replaced without exception"
    input Function fn;
    output Boolean b;
  algorithm
    b := match AbsynUtil.pathFirstIdent(Function.nameConsiderBuiltin(fn))
      case "cat" then true;
      case "terminal" then true;
      else false;
    end match;
  end forceReplacement;

  function replaceException
    "returns true if this call should not be replaced"
    input Function fn;
    output Boolean b;
  protected
    Absyn.Path path;
  algorithm
    // do not replace record constructors
    if Function.isDefaultRecordConstructor(fn)
    or Function.isNonDefaultRecordConstructor(fn)
    // do not replace impure functions
    or Function.isImpure(fn)
    // do not replace functions with no output
    or listEmpty(fn.outputs) then
      b := true;
      return;
    end if;
    if not Function.isBuiltin(fn) then
      b := false;
    else
      path := Function.nameConsiderBuiltin(fn);
      if not AbsynUtil.pathIsIdent(path) then
        b := false;
      else
        b := match AbsynUtil.pathFirstIdent(path)
          case "integer" then true;
          case "String" then true;
          case "$OMC$PositiveMax" then true;
          case "$OMC$inStreamDiv" then true;
          else false;
        end match;
      end if;
    end if;
  end replaceException;

  function filterFrames
    "filters the list of frames for all iterators that occure in exp"
    input Expression exp;
    input list<ComponentRef> names;
    input list<Expression> ranges;
    input list<Option<Iterator>> maps;
    output list<tuple<ComponentRef, Expression, Option<Iterator>>> frames;
  protected
    UnorderedMap<ComponentRef, Expression> frame_map = UnorderedMap.fromLists<Expression>(names, ranges, ComponentRef.hash, ComponentRef.isEqual);
    UnorderedMap<ComponentRef, Expression> new_map = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);

    Pointer<list<ComponentRef>> names_acc = Pointer.create({});
    Pointer<list<Expression>> ranges_acc = Pointer.create({});
    function collectFrames
      input output Expression exp;
      input UnorderedMap<ComponentRef, Expression> frame_map;
      input UnorderedMap<ComponentRef, Expression> new_map;
    algorithm
      _ := match exp
        local
          Option<Expression> range;
        case Expression.CREF() algorithm
          range := UnorderedMap.get(exp.cref, frame_map);
          if isSome(range) then
            UnorderedMap.add(exp.cref, Util.getOption(range), new_map);
          end if;
        then ();
        else ();
      end match;
    end collectFrames;

    list<ComponentRef> n;
    list<Expression> r;
    list<Option<Iterator>> m;
  algorithm
    _ := Expression.map(exp, function collectFrames(frame_map = frame_map, new_map = new_map));
    n := UnorderedMap.keyList(new_map);
    r := UnorderedMap.valueList(new_map);
    m := List.fill(NONE(), listLength(n));
    frames := List.zip3(n, r, m);
  end filterFrames;

  function addAuxVar
    "add the aux var to the correct list and potentially resolve records properly"
    input Pointer<Variable> new_var;
    input output Boolean disc;
    input output list<Pointer<Variable>> new_vars_disc;
    input output list<Pointer<Variable>> new_vars_cont;
    input output list<Pointer<Variable>> new_vars_init;
    input output list<Pointer<Variable>> new_vars_recd;
    input Boolean init;
  protected
    list<Variable> children;
    Pointer<Variable> var_ptr;
  algorithm
    if BVariable.isRecord(new_var) then
      new_vars_recd := new_var :: new_vars_recd;
      // create record element variables (ignore first output since its the variable itself)
      _ :: children := Variable.expandChildren(Pointer.access(new_var), addDimensions = false);
      for child in children loop
        (disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd) := addAuxVar(BVariable.makeVarPtrCyclic(child, child.name), disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, init);
      end for;
    elseif init then
      new_vars_init := BVariable.setFixed(new_var, false) :: new_vars_init;
    elseif BVariable.isContinuous(new_var, false) then
      disc := false;
      new_vars_cont := new_var :: new_vars_cont;
    else
      new_vars_disc := new_var :: new_vars_disc;
    end if;
  end addAuxVar;

  function addClockedAlias
    "add clocked alias equations and variables
    Note: inferred clocks are handled as unknowns for partitioning"
    input EquationPointers equations;
    input Pointer<Integer> eqn_idx;
    output list<Pointer<Equation>> clock_eqns = {};
    output list<Pointer<Equation>> infer_eqns = {};
    output list<Pointer<Variable>> clock_vars;
    output list<Pointer<Variable>> infer_vars;
    output UnorderedMap<BClock, ComponentRef> clck_coll = UnorderedMap.new<ComponentRef>(BClock.hash, BClock.isEqual);
    output UnorderedMap<BClock, ComponentRef> infr_coll = UnorderedMap.new<ComponentRef>(BClock.hash, BClock.isEqual);
  protected
    Pointer<list<Pointer<Variable>>> new_clocks = Pointer.create({});
    Pointer<list<Pointer<Variable>>> new_infers = Pointer.create({});
    Pointer<Integer> idx = Pointer.create(0);
    BClock clock;
    ComponentRef clock_name;
  algorithm
    EquationPointers.mapExp(equations, function Partitioning.extractClocks(
      clck_coll = clck_coll, infr_coll = infr_coll, new_clocks = new_clocks, new_infers = new_infers, idx = idx));

    // create clocks
    clock_vars := Pointer.access(new_clocks);
    for tpl in UnorderedMap.toList(clck_coll) loop
      (clock, clock_name) := tpl;
      clock_eqns := Equation.makeAssignment(Expression.fromCref(clock_name), BClock.toExp(clock), eqn_idx, "AUX", Iterator.EMPTY(), EquationAttributes.default(EquationKind.CLOCKED, false)) :: clock_eqns;
    end for;

    // create inferred clocks
    infer_vars := Pointer.access(new_infers);
    for tpl in UnorderedMap.toList(infr_coll) loop
      (clock, clock_name) := tpl;
      infer_eqns := Equation.makeAssignment(Expression.fromCref(clock_name), BClock.toExp(clock), eqn_idx, "AUX", Iterator.EMPTY(), EquationAttributes.default(EquationKind.CLOCKED, false)) :: infer_eqns;
    end for;
  end addClockedAlias;

  // type for slice collection
  type Indices = UnorderedSet<Integer>;

  function collectSlicedStatesAliasEquation
    "helper function to map equations for sliced state collection"
    input output Equation eqn;
    input UnorderedMap<ComponentRef,Indices> map;
  protected
    Iterator iter = Equation.getForIterator(eqn);
  algorithm
    Equation.map(eqn, function collectSlicedStatesAlias(iter = iter, map = map), NONE(), Expression.fakeMap);
  end collectSlicedStatesAliasEquation;

  function collectSlicedStatesAlias
    "check cref in a der() call for full access of the variable.
    if its not fully accessing the variable, add it to the slice map."
    input output Expression exp;
    input Iterator iter;
    input UnorderedMap<ComponentRef,Indices> map;
  algorithm
    exp := match exp
      local
        Integer iter_size, cref_size, var_size;
        Expression arg;
        UnorderedSet<ComponentRef> call_crefs;
        ComponentRef stripped_cref;
        UnorderedSet<Integer> indices;
        list<ComponentRef> names;
        list<Expression> ranges;
        list<Option<Iterator>> maps;

      // derivative
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")), arguments = {arg})) algorithm
        // get the iterator size
        iter_size := Iterator.size(iter, true);
        // collect all crefs in the call
        call_crefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        Slice.filterExp(arg, function Slice.getContinuous(init = false), call_crefs);
        for cref in UnorderedSet.toList(call_crefs) loop
          cref_size := Type.sizeOf(ComponentRef.getSubscriptedType(cref), true);
          var_size  := BVariable.size(BVariable.getVarPointer(cref, sourceInfo()), true);
          // if the cref does not represent the full variable it has to be collected as it might cause a sliced state
          if var_size <> cref_size * iter_size then
            stripped_cref         := ComponentRef.stripSubscriptsAll(cref);
            indices               := UnorderedMap.getOrDefault(stripped_cref, map, UnorderedSet.new(Util.id, intEq));
            (names, ranges, maps) := Iterator.getFrames(iter);
            // get all the local indices (start index = 0) and collect with potential previous indices
            for index in Slice.getCrefInFrameIndicesLocal(cref, stripped_cref, List.zip3(names, ranges, maps), 0, true) loop
              UnorderedSet.add(index, indices);
            end for;
            UnorderedMap.add(stripped_cref, indices, map);
          end if;
        end for;
      then exp;

      // array constructor, get the iterators and add them going deeper
      case Expression.CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
        Expression.mapShallow(exp, function collectSlicedStatesAlias(iter = Iterator.expand(iter, exp.call), map = map));
      then exp;
      case Expression.CALL(call = Call.TYPED_REDUCTION()) algorithm
        Expression.mapShallow(exp, function collectSlicedStatesAlias(iter = Iterator.expand(iter, exp.call), map = map));
      then exp;

      // just map deeper in search for der() calls
      else algorithm
        Expression.mapShallow(exp, function collectSlicedStatesAlias(iter = iter, map = map));
      then exp;
    end match;
  end collectSlicedStatesAlias;

  function getSlicedStatesSet
    "takes the map of states and their sliced indices and returns the set of all states of which the indices are not covering the full state"
    input UnorderedMap<ComponentRef,Indices> map;
    output UnorderedSet<ComponentRef> set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  protected
    ComponentRef state;
    UnorderedSet<Integer> indices;
  algorithm
    for tpl in UnorderedMap.toList(map) loop
      (state, indices) := tpl;
      if BVariable.size(BVariable.getVarPointer(state, sourceInfo()), true) <> UnorderedSet.size(indices) then
        UnorderedSet.add(state, set);
      end if;
    end for;
  end getSlicedStatesSet;

  function introduceSlicedStateAliasEquation
    "creates auxilliary variables for all state slices where the variable is only partially a state"
    input output Equation eqn;
    input UnorderedSet<ComponentRef> set;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> aux_index;
  protected
    Iterator iter = Equation.getForIterator(eqn);
  algorithm
    eqn := Equation.map(eqn, function introduceSlicedStateAliasExp(set = set, map = map, iter = iter, aux_index = aux_index), NONE(), Expression.fakeMap);
  end introduceSlicedStateAliasEquation;

  function introduceSlicedStateAliasExp
    "replace component references in der() calls that have been found to be only partially states."
    input output Expression exp;
    input UnorderedSet<ComponentRef> set;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Iterator iter;
    input Pointer<Integer> aux_index;
  algorithm
    exp := match exp
      local
        Call call;
        Expression arg, new_exp;

      case Expression.CALL(call = call as Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")), arguments = {arg})) algorithm
        call.arguments  := {Expression.map(arg, function introduceAliasCrefConditional(set = set, map = map, iter = iter, aux_index = aux_index, init = false))};
        exp.call        := call;
      then exp;

        // array constructor, get the iterators and add them going deeper
      case Expression.CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR()) algorithm
        new_exp := Expression.mapShallow(exp, function introduceSlicedStateAliasExp(set = set, map = map, iter = Iterator.expand(iter, exp.call), aux_index = aux_index));
      then new_exp;
      case Expression.CALL(call = Call.TYPED_REDUCTION()) algorithm
        new_exp := Expression.mapShallow(exp, function introduceSlicedStateAliasExp(set = set, map = map, iter = Iterator.expand(iter, exp.call), aux_index = aux_index));
      then new_exp;

      // just map deeper in search for der() calls
      else algorithm
        new_exp := Expression.mapShallow(exp, function introduceSlicedStateAliasExp(set = set, map = map, iter = iter, aux_index = aux_index));
      then new_exp;
    end match;
  end introduceSlicedStateAliasExp;

  annotation(__OpenModelica_Interface="backend");
end NBFunctionAlias;
