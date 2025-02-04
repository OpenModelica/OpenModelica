/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
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
  import Partitioning = NBPartitioning;
  import NBPartitioning.BClock;
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
          (varData, eqData) := func(varData, eqData);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case BackendDAE.HESSIAN(varData = varData, eqData = eqData)
        algorithm
          (varData, eqData) := func(varData, eqData);
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
          case Expression.CREF()    then {BVariable.getVarPointer(exp.cref)};
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
      input Boolean init;
      output ComponentRef name;
    protected
      Type new_ty = ty;
    algorithm
      if not Iterator.isEmpty(iter) then
        new_ty := Type.liftArrayRightList(ty, list(Dimension.fromInteger(i) for i in Iterator.sizes(iter)));
        (_, name) := BVariable.makeAuxVar(NBVariable.FUNCTION_STR, Pointer.access(aux_index), new_ty, init);
        // add iterators to subscripts of auxilliary variable
        name      := ComponentRef.mergeSubscripts(Iterator.normalizedSubscripts(iter), name, true, true);
      else
        (_, name) := BVariable.makeAuxVar(NBVariable.FUNCTION_STR, Pointer.access(aux_index), new_ty, init);
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
    UnorderedMap<BClock, ComponentRef> clock_map;
    Pointer<Integer> aux_index = Pointer.create(1);
    list<Pointer<Variable>> new_vars_disc = {}, new_vars_cont = {}, new_vars_init = {}, new_vars_recd = {}, new_vars_clck;
    list<Pointer<Equation>> new_eqns_disc = {}, new_eqns_cont = {}, new_eqns_init = {}, new_eqns_clck;
    list<tuple<Call_Id, Call_Aux>> debug_lst_sim, debug_lst_ini;
    list<tuple<String, String>> debug_str;
    Integer debug_max_length;
  algorithm
    _ := match eqData
      local
        Call_Id id;
        Call_Aux aux;
        Boolean disc;
        Pointer<Equation> new_eqn;
        list<Pointer<Variable>> new_vars;

      case EqData.EQ_DATA_SIM() algorithm
        // first collect all new functions from simulation equations
        eqData.simulation := EquationPointers.map(eqData.simulation,
          function introduceFunctionAliasEquation(map = map, variables = variables, set = set, aux_index = aux_index, eqn_index = eqData.uniqueIndex, init = false));

        // create new simulation variables and corresponding equations for the function alias
        for tpl in listReverse(UnorderedMap.toList(map)) loop
          (id, aux) := tpl;
          new_vars  := Call_Aux.getVars(aux);
          disc := true;

          // categorize all aux variables
          for new_var in new_vars loop
            (disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd) := addAuxVar(new_var, disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, false);
          end for;

          // if any of the created variables is continuous, so is the equation
          new_eqn := Equation.makeAssignment(aux.replacer, id.call, eqData.uniqueIndex, "AUX", id.iter, EquationAttributes.default(aux.kind, false));
          if disc then
            new_eqns_disc := new_eqn :: new_eqns_disc;
          else
            new_eqns_cont := new_eqn :: new_eqns_cont;
          end if;

          aux.parsed := true;
          UnorderedMap.add(id, aux, map);
        end for;

        if Flags.isSet(Flags.DUMP_CSE) then
          debug_lst_sim := UnorderedMap.toList(map);
        end if;

        // afterwards collect all functions from initial equations
        eqData.initials := EquationPointers.map(eqData.initials,
          function introduceFunctionAliasEquation(map = map, variables = variables, set = set, aux_index = aux_index, eqn_index = eqData.uniqueIndex, init = true));

        // create new initialization variables and corresponding equations for the function alias
        for tpl in listReverse(UnorderedMap.toList(map)) loop
          (id, aux) := tpl;

          // only create new var and eqn if there is not already one in the simulation system
          if not aux.parsed then
            // unfix parameters in initial system because we also add an equation
            new_vars := Call_Aux.getVars(aux);

            for new_var in new_vars loop
              (disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd) := addAuxVar(new_var, disc, new_vars_disc, new_vars_cont, new_vars_init, new_vars_recd, true);
            end for;

            new_eqn := Equation.makeAssignment(aux.replacer, id.call, eqData.uniqueIndex, "AUX", id.iter, EquationAttributes.default(aux.kind, false));
            new_eqns_init := new_eqn :: new_eqns_init;
          end if;
        end for;

        // create clock alias equations
        (new_eqns_clck, new_vars_clck, clock_map) := addClockedAlias(eqData.simulation, eqData.uniqueIndex);
      then ();
      else ();
    end match;
    // add the new variables and equations
    varData := VarData.addTypedList(varData, new_vars_cont, VarData.VarType.ALGEBRAIC);
    varData := VarData.addTypedList(varData, new_vars_disc, VarData.VarType.DISCRETE);
    varData := VarData.addTypedList(varData, new_vars_init, VarData.VarType.PARAMETER);
    varData := VarData.addTypedList(varData, new_vars_recd, VarData.VarType.RECORD);
    varData := VarData.addTypedList(varData, new_vars_clck, VarData.VarType.CLOCK);
    varData := VarData.addTypedList(varData, UnorderedSet.toList(set), VarData.VarType.ITERATOR);
    eqData  := EqData.addTypedList(eqData, new_eqns_cont, EqData.EqType.CONTINUOUS, false);
    eqData  := EqData.addTypedList(eqData, new_eqns_disc, EqData.EqType.DISCRETE, false);
    eqData  := EqData.addTypedList(eqData, new_eqns_init, EqData.EqType.INITIAL, false);
    eqData  := EqData.addTypedList(eqData, new_eqns_clck, EqData.EqType.CLOCKED, false);

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
      print(StringUtil.headline_3("Simulation Function Alias"));
      debug_str := list((Call_Aux.toString(Util.tuple22(tpl)), Call_Id.toString(Util.tuple21(tpl))) for tpl in debug_lst_sim);
      debug_max_length := max(stringLength(Util.tuple21(tpl)) for tpl in debug_str) + 3;
      print(List.toString(debug_str, function functionAliasTplString(max_length = debug_max_length), "", "  ", "\n  ", "\n\n"));
      print(StringUtil.headline_3("Initial Function Alias"));
      debug_str := list((Call_Aux.toString(Util.tuple22(tpl)), Call_Id.toString(Util.tuple21(tpl))) for tpl in debug_lst_ini);
      debug_max_length := max(stringLength(Util.tuple21(tpl)) for tpl in debug_str) + 3;
      print(List.toString(debug_str, function functionAliasTplString(max_length = debug_max_length), "", "  ", "\n  ", "\n\n"));
      print(StringUtil.headline_3("Clocked Function Alias"));
      debug_str := list((ComponentRef.toString(Util.tuple22(tpl)), BClock.toString(Util.tuple21(tpl))) for tpl in UnorderedMap.toList(clock_map));
      debug_max_length := max(stringLength(Util.tuple21(tpl)) for tpl in debug_str) + 3;
      print(List.toString(debug_str, function functionAliasTplString(max_length = debug_max_length), "", "  ", "\n  ", "\n\n"));
    end if;
  end functionAliasDefault;

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
    Boolean stop;
  algorithm
    // inline trivial array constructors first
    eqn := Inline.inlineArrayConstructorSingle(eqn, Iterator.EMPTY(), variables, set, eqn_index);

    // get iterator and determine if it needs to be checked further
    (iter, stop) := match eqn
      local
        Equation body;
      case Equation.FOR_EQUATION(body = {body}) then (eqn.iter, Equation.isWhenEquation(Pointer.create(body))
                                                            or Equation.isIfEquation(Pointer.create(body)));
      case Equation.WHEN_EQUATION()             then (Iterator.EMPTY(), true);
      case Equation.IF_EQUATION()               then (Iterator.EMPTY(), true);
      case Equation.ALGORITHM()                 then (Iterator.EMPTY(), true);
                                                else (Iterator.EMPTY(), false);
    end match;

    // do the function alias replacement
    if not stop then
      eqn := Equation.map(eqn, function introduceFunctionAlias(map = map, aux_index = aux_index, iter = iter, init = init));
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
  algorithm
    exp := match exp
      local
        Call call;
        Expression new_exp, sub_exp;

      case Expression.CALL() guard(checkCallReplacement(exp.call)) then introduceAlias(exp, map, aux_index, iter, init);

      // create alias for array constructors as arguments to functions
      case new_exp as Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        call.arguments  := list(Expression.map(arg, function introduceArrayConstructorAlias(map = map, aux_index = aux_index, iter = iter, init = init)) for arg in call.arguments);
        new_exp.call    := call;
      then new_exp;

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
    input output Expression exp;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> aux_index;
    input Iterator iter;
    input Boolean init;
  algorithm
    exp := match exp
      case Expression.CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR()) then introduceAlias(exp, map, aux_index, iter, init);
      else exp;
    end match;
  end introduceArrayConstructorAlias;

  function introduceAlias
    input output Expression exp;
    input UnorderedMap<Call_Id, Call_Aux> map;
    input Pointer<Integer> aux_index;
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
      ty := Expression.typeOf(exp);
    else
      // for initial systems create parameters, otherwise use type to determine variable kind
      ty := Expression.typeOf(exp);
      exp := match ty
        case Type.TUPLE() algorithm
          names   := list(Call_Aux.createName(sub_ty, new_iter, aux_index, init) for sub_ty in ty.types);
          tpl_lst := list(if ComponentRef.size(cref, true) == 0 then Expression.fromCref(ComponentRef.WILD()) else Expression.fromCref(cref) for cref in names);
        then Expression.TUPLE(ty, tpl_lst);
        else algorithm
          name := Call_Aux.createName(ty, new_iter, aux_index, init);
        then Expression.fromCref(name);
      end match;
    end if;

    // create auxilliary and add to map
    aux := CALL_AUX(exp, if Type.isDiscrete(ty) then EquationKind.DISCRETE else EquationKind.CONTINUOUS, false);
    UnorderedMap.add(id, aux, map);
  end introduceAlias;

  function checkCallReplacement
    "returns true if the call should be replaced"
    input Call call;
    output Boolean b;
  protected
    Function fn = Call.typedFunction(call);
  algorithm
    b := not (Inline.functionInlineable(fn) or Function.isSpecialBuiltin(fn) or replaceException(fn));
  end checkCallReplacement;

  function replaceException
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
    input EquationPointers equations;
    input Pointer<Integer> eqn_idx;
    output list<Pointer<Equation>> clock_eqns = {};
    output list<Pointer<Variable>> clock_vars;
    output UnorderedMap<BClock, ComponentRef> collector = UnorderedMap.new<ComponentRef>(BClock.hash, BClock.isEqual);
  protected
    Pointer<list<Pointer<Variable>>> new_clocks = Pointer.create({});
    Pointer<Integer> idx = Pointer.create(0);
    BClock clock;
    ComponentRef clock_name;
  algorithm
    EquationPointers.mapExp(equations, function Partitioning.extractClocks(collector = collector, new_clocks = new_clocks, idx = idx));
    clock_vars := Pointer.access(new_clocks);
    for tpl in UnorderedMap.toList(collector) loop
      (clock, clock_name) := tpl;
      clock_eqns := Equation.makeAssignment(Expression.fromCref(clock_name), BClock.toExp(clock), eqn_idx, "AUX", Iterator.EMPTY(), EquationAttributes.default(EquationKind.CLOCKED, false)) :: clock_eqns;
    end for;
  end addClockedAlias;

  annotation(__OpenModelica_Interface="backend");
end NBFunctionAlias;
