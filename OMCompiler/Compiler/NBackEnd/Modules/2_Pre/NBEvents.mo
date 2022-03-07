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
encapsulated package NBEvents
"file:        NBEvents.mo
 package:     NBEvents
 description: This file contains the functions for the event collection module.
"

public
  import Module = NBModule;

protected
  // OF
  import DAE;

  // NF
  import Builtin = NFBuiltin;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTreeImpl;
  import Operator = NFOperator;
  import Prefixes = NFPrefixes;
  import Variable = NFVariable;

  // OB
  import OldBackendDAE = BackendDAE;
  import OldTree = ZeroCrossings.Tree;
  import OldZeroCrossings = ZeroCrossings;

  // New Backend
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.Equation;
  import NBEquation.EqData;
  import NBEquation.EquationAttributes;
  import NBEquation.EquationPointers;
  import NBEquation.IfEquationBody;
  import Solve = NBSolve;
  import System = NBSystem;
  import BVariable = NBVariable;
  import NBVariable.VarData;
  import NBVariable.VariablePointers;
  import NBEquation.WhenEquationBody;

  // Util
  import BackendUtil = NBBackendUtil;
  import DoubleEnded;
  import StringUtil;
  import BuiltinSystem = System;

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
public
  function main
    "Wrapper function for any event collection function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
  protected
    Module.eventsInterface func;
  algorithm
    func := getModule();

    bdae := match bdae
      local
        VarData varData;
        EqData eqData;
        EventInfo eventInfo;

      case BackendDAE.MAIN()
        algorithm
          (varData, eqData, eventInfo) := func(bdae.varData, bdae.eqData, bdae.eventInfo);
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.eventInfo := eventInfo;
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.eventsInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.ZERO_CROSSINGS)
  algorithm
    (func) := match flag
      case "default" then (eventsDefault);
      /* ... New detect states modules have to be added here */
      else fail();
    end match;
  end getModule;

// =========================================================================
//                    TYPES, UNIONTYPES AND MEMBER FUNCTIONS
// =========================================================================

  uniontype EventInfo
    record EVENT_INFO
      list<TimeEvent> timeEvents      "all time events";
      list<StateEvent> stateEvents    "all state events";
      Integer numberMathEvents        "stores the number of math function that trigger events e.g. floor, ceil, integer, ...";
    end EVENT_INFO;

    function toString
      input EventInfo eventInfo;
      output String str = "";
    algorithm
      if not isEmpty(eventInfo) then
        str := StringUtil.headline_2("Event Info") + "\n";
        str := str + TimeEvent.toStringList(eventInfo.timeEvents) + "\n";
        str := str + StateEvent.toStringList(eventInfo.stateEvents) + "\n\n";
      end if;
    end toString;

    function create
      input Bucket bucket;
      input Pointer<Integer> idx;
      output EventInfo eventInfo;
      output list<Pointer<Variable>> auxiliary_vars = {};
      output list<Pointer<Equation>> auxiliary_eqns = {};
    protected
      String context = "EVT";
      list<TimeEvent> timeEvents = TimeEventSet.listKeys(bucket.timeEventSet);
      list<StateEvent> stateEvents = StateEventTree.toEventList(bucket.stateEventTree);
      list<tuple<Expression, Pointer<Variable>>> full_time_event_list = TimeEventTree.toList(bucket.timeEventTree);
      Expression rhs;
      Pointer<Variable> aux_var;
      Pointer<Equation> aux_eqn;
    algorithm
      // get auxiliary eqns and vars from time events
      for tpl in full_time_event_list loop
        (rhs, aux_var) := tpl;
        aux_eqn := Equation.fromLHSandRHS(Expression.fromCref(BVariable.getVarName(aux_var)), rhs, idx, context, NBEquation.EQ_ATTR_DEFAULT_DISCRETE);
        auxiliary_vars := aux_var :: auxiliary_vars;
        auxiliary_eqns := aux_eqn :: auxiliary_eqns;
      end for;

      // get auxiliary eqns and vars from state events
      for stateEvent in stateEvents loop
        STATE_EVENT(auxiliary = aux_var, relation = rhs) := stateEvent;
        aux_eqn := Equation.fromLHSandRHS(Expression.fromCref(BVariable.getVarName(aux_var)), rhs, idx, context, NBEquation.EQ_ATTR_DEFAULT_DISCRETE);
        auxiliary_vars := aux_var :: auxiliary_vars;
        auxiliary_eqns := aux_eqn :: auxiliary_eqns;
      end for;

      eventInfo := EVENT_INFO(
        timeEvents        = timeEvents,
        stateEvents       = stateEvents,
        numberMathEvents  = 0 // ToDo
      );
    end create;

    function empty
      output EventInfo eventInfo;
    algorithm
      eventInfo := EVENT_INFO(
        timeEvents        = {},
        stateEvents       = {},
        numberMathEvents  = 0
      );
    end empty;

    function isEmpty
      input EventInfo eventInfo;
      output Boolean b;
    algorithm
      b := listEmpty(eventInfo.timeEvents) and listEmpty(eventInfo.stateEvents);
    end isEmpty;

    function convert
      input EventInfo eventInfo;
      output list<OldBackendDAE.ZeroCrossing> zeroCrossings;
      output list<OldBackendDAE.ZeroCrossing> relations     "== zeroCrossings for the most part (only eq pointer different?)";
      output list<OldBackendDAE.TimeEvent> timeEvents;
    algorithm
      zeroCrossings := list(StateEvent.convert(stateEvent) for stateEvent in eventInfo.stateEvents);
      relations := zeroCrossings;
      // for some reason this needs to be reverted
      timeEvents := listReverse(list(TimeEvent.convert(te) for te in eventInfo.timeEvents));
    end convert;
  end EventInfo;

  uniontype TimeEvent
    record SINGLE           "e.g. time > 0.5"
      Integer index         "unique sample index";
      Expression trigger    "single point in time that triggers it";
    end SINGLE;

    record SAMPLE           "e.g. sample(1, 1)"
      Integer index         "unique sample index";
      Expression start      "first trigger point";
      Expression interval   "equidistant intervals";
    end SAMPLE;

    function toString
      input TimeEvent timeEvent;
      output String str;
    algorithm
      str := match timeEvent
        case SINGLE() then "\t(" + intString(timeEvent.index) + ") time > " + Expression.toString(timeEvent.trigger);
        case SAMPLE() then "\t(" + intString(timeEvent.index) + ") sample(" + Expression.toString(timeEvent.start) + ", " + Expression.toString(timeEvent.interval) + ")";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end toString;

    function toStringList
      input list<TimeEvent> events_lst;
      output String str;
    algorithm
      str := StringUtil.headline_4("Time Events");
      if listEmpty(events_lst) then
        str := str + "\t<No Time Events>\n";
      else
        str := str + stringDelimitList(list(toString(te) for te in events_lst), "\n");
      end if;
    end toStringList;

    function create
      input output Expression condition;
      input output Bucket bucket;
      output Boolean failed = false "returns true if time event list could not be created";
    protected
      Pointer<Variable> aux_var;
      ComponentRef aux_cref;
    algorithm
      (condition, bucket, failed) := match condition
        local
          Expression exp1, exp2;
          Boolean b1, b2;

        case Expression.LBINARY()
          guard(Operator.getMathClassification(condition.operator) == NFOperator.MathClassification.LOGICAL)
          algorithm
            (exp1, bucket, b1) := create(condition.exp1, bucket);
            (exp2, bucket, b2) := create(condition.exp2, bucket);
            failed := (b1 or b2);
            if not failed then
              // we could simplify here
              condition.exp1 := exp1;
              condition.exp2 := exp2;
            end if;
        then (condition, bucket, failed);

        else createSingleOrSample(condition, bucket);

      end match;

      if not failed then
        if TimeEventTree.hasKey(bucket.timeEventTree, condition) then
          // time event already exists, just get the identifier
          aux_var := TimeEventTree.get(bucket.timeEventTree, condition);
          aux_cref := BVariable.getVarName(aux_var);
        else
          // make a new auxiliary variable representing the state
          (aux_var, aux_cref) := BVariable.makeEventVar(NBVariable.TIME_EVENT_STR, bucket.auxiliaryTimeEventIndex);
          bucket.auxiliaryTimeEventIndex := bucket.auxiliaryTimeEventIndex + 1;
          // add the new event to the tree
          bucket.timeEventTree := TimeEventTree.add(bucket.timeEventTree, condition, aux_var);
          // also return the expression which replaces the zero crossing
        end if;
        condition := Expression.fromCref(aux_cref);
      end if;
    end create;

    function createSingleOrSample
      "The cases:
      1. creates a single time event from a comparing binary expression which
        has to only depend on time
      2. creates a sample time event from a sample operator
      3. fails for anything else
      NOTE: create sample from sin and cos functions?"
      input output Expression exp         "has to be BINARY() with comparing operator or a sample CALL()";
      input output Bucket bucket          "bucket containing the events";
      output Boolean failed               "true if it did not work to create a compact time event";
    protected
      Expression new_exp;
    algorithm
      failed := match exp
          local
            Equation tmpEqn;
            Solve.Status status;
            Call call;
            Boolean invert;
            TimeEvent timeEvent;

        case Expression.RELATION()
          guard(Operator.getMathClassification(exp.operator) == NFOperator.MathClassification.RELATION)
          algorithm
            // create auxiliary equation and solve for TIME
            tmpEqn := Pointer.access(Equation.fromLHSandRHS(exp.exp1, exp.exp2, Pointer.create(0), "TMP"));
            (tmpEqn, _, status, invert) := Solve.solveEquation(tmpEqn, NFBuiltin.TIME_CREF, FunctionTreeImpl.EMPTY());
            if status == NBSolve.Status.EXPLICIT then
              // save simplified binary
              exp.exp1 := Equation.getLHS(tmpEqn);
              exp.exp2 := Equation.getRHS(tmpEqn);
              if invert then
                exp.operator := Operator.invert(exp.operator);
                // ToDo: Operator cannot be < or <= after inversion, because it has been solved for time -> fail()?
              end if;
              timeEvent := SINGLE(0, exp.exp2);
              if not TimeEventSet.hasKey(bucket.timeEventSet, timeEvent) then
                bucket.timeEventIndex := bucket.timeEventIndex + 1;
                timeEvent := setIndex(timeEvent, bucket.timeEventIndex);
                bucket.timeEventSet := TimeEventSet.add(bucket.timeEventSet, timeEvent);
              end if;
              // change expression to sample(index, trigger, maxInt)
              // ToDo: remove this! it is just a very ugly hack to have single events in current simcode/runtime
              // but currently there is no way around this
              new_exp := Expression.CALL(Call.makeTypedCall(
                fn          = NFBuiltinFuncs.SAMPLE,
                args        = {Expression.INTEGER(getIndex(timeEvent)), exp.exp2, Expression.REAL(BuiltinSystem.intMaxLit())},
                variability = NFPrefixes.Variability.PARAMETER,
                purity      = NFPrefixes.Purity.IMPURE
              ));
              failed := false;
            else
              new_exp := exp;
              failed := true;
            end if;
        then failed;

        case Expression.CALL(call = call) algorithm
          (call, bucket, failed) := createSample(call, bucket);
          exp.call := call;
          new_exp := exp;
        then failed;

        else true;
      end match;
      exp := new_exp;
    end createSingleOrSample;

    function createSample
      input output Call call;
      input output Bucket bucket;
      output Boolean failed;
    algorithm
      failed := match Call.getNameAndArgs(call)
          local
            Integer value;
            Expression start, interval;
            TimeEvent timeEvent;

          case ("sample", {start, interval}) algorithm
            timeEvent := SAMPLE(0, start, interval);
            if not TimeEventSet.hasKey(bucket.timeEventSet, timeEvent) then
              bucket.timeEventIndex := bucket.timeEventIndex + 1;
              timeEvent := setIndex(timeEvent, bucket.timeEventIndex);
              bucket.timeEventSet := TimeEventSet.add(bucket.timeEventSet, timeEvent);
            end if;
            // add index to sample interface
            call := Call.setArguments(call, {Expression.INTEGER(TimeEvent.getIndex(timeEvent)), start, interval});
        then false;

          case ("sample", _) algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for sample operator: " + Call.toString(call)});
          then fail();

          // Maybe add funky sin/cos stuff here

          else true;
        end match;
    end createSample;

    function createSampleTraverse
      "used only for StateEvent traversel to encapsulate sample operators"
      input output Expression exp         "has to be BINARY() with comparing operator or a sample CALL()";
      input output Bucket bucket          "bucket containing the events";
    algorithm
      exp := match exp
        local
          Call call;
        case Expression.CALL(call = call) algorithm
          (call, bucket, _) := createSample(call, bucket);
          exp.call := call;
        then exp;
        else exp;
      end match;
    end createSampleTraverse;

    function getIndex
      input TimeEvent timeEvent;
      output Integer index;
    algorithm
      index := match timeEvent
        case SINGLE() then timeEvent.index;
        case SAMPLE() then timeEvent.index;
      end match;
    end getIndex;

    function setIndex
      input output TimeEvent timeEvent;
      input Integer index;
    algorithm
      timeEvent := match timeEvent
        case SINGLE() algorithm timeEvent.index := index; then timeEvent;
        case SAMPLE() algorithm timeEvent.index := index; then timeEvent;
        else timeEvent;
      end match;
    end setIndex;

    function compare
      "compares the full time event (used for collecting, afterwards equal index usually suffices)"
      input TimeEvent te1;
      input TimeEvent te2;
      output Integer i;
    algorithm
      i := match (te1, te2)
        case (SINGLE(), SINGLE()) then Expression.compare(te1.trigger, te2.trigger);
        case (SAMPLE(), SAMPLE()) then BackendUtil.compareCombine(
                                          Expression.compare(te1.start, te2.start),
                                          Expression.compare(te1.interval, te2.interval)
                                       );
        else Util.intCompare(valueConstructor(te1), valueConstructor(te2));
      end match;
    end compare;

    function convert
      input TimeEvent timeEvent;
      output OldBackendDAE.TimeEvent oldTimeEvent;
    algorithm
      oldTimeEvent := match timeEvent
        // treat single time events as sample time events with maximum integer as interval
        case SINGLE() then OldBackendDAE.TimeEvent.SAMPLE_TIME_EVENT(
          index       = timeEvent.index,
          startExp    = Expression.toDAE(timeEvent.trigger),
          intervalExp = DAE.RCONST(BuiltinSystem.intMaxLit()));
        case SAMPLE() then OldBackendDAE.TimeEvent.SAMPLE_TIME_EVENT(
          index       = timeEvent.index,
          startExp    = Expression.toDAE(timeEvent.start),
          intervalExp = Expression.toDAE(timeEvent.interval));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end convert;
  end TimeEvent;

  uniontype StateEvent
    record STATE_EVENT
      Pointer<Variable> auxiliary         "auxiliary variable representing the relation";
      Expression relation                 "function";
      list<Pointer<Equation>> occurEqLst  "list of equations where the function occurs";
    end STATE_EVENT;

    function toString
      input StateEvent se;
      output String str = "\t" + BVariable.toString(Pointer.access(se.auxiliary)) + " = " + Expression.toString(se.relation);
    end toString;

    function toStringList
      input list<StateEvent> events_lst;
      output String str;
    algorithm
      str := StringUtil.headline_4("State Events");
      if listEmpty(events_lst) then
        str := str + "\t<No State Events>\n";
      else
        str := str + stringDelimitList(list(toString(te) for te in events_lst), "\n");
      end if;
    end toStringList;

    function create
      input output Expression condition;
      input output Bucket bucket;
      input Pointer<Equation> eqn;
    protected
      StateEvent event;
      Pointer<Variable> aux_var;
      ComponentRef aux_cref;
    algorithm
      // collect possible state events from condition
      (condition, bucket) := Expression.mapFold(condition, TimeEvent.createSampleTraverse, bucket);

      // create state event with dummy variable and update it later on if it does not already exist
      event := STATE_EVENT(
        auxiliary   = Pointer.create(NBVariable.DUMMY_VARIABLE),
        relation    = condition,
        occurEqLst  = {}
      );
      if StateEventTree.hasKey(bucket.stateEventTree, event) then
        // if the state event already exist just update the equations it belongs to
        bucket.stateEventTree := StateEventTree.update(bucket.stateEventTree, event, eqn :: StateEventTree.get(bucket.stateEventTree, event));
      else
        // otherwise make a new auxiliary variable representing the state
        (aux_var, aux_cref) := BVariable.makeEventVar(NBVariable.STATE_EVENT_STR, bucket.auxiliaryStateEventIndex);
        event.auxiliary := aux_var;
        bucket.auxiliaryStateEventIndex := bucket.auxiliaryStateEventIndex + 1;

        // add the new event to the tree
        bucket.stateEventTree := StateEventTree.add(bucket.stateEventTree, event, {eqn});
        // also return the expression which replaces the zero crossing
        condition := Expression.fromCref(aux_cref);
      end if;
    end create;

    function equals "Returns true if both zero crossings have the same function expression"
      input StateEvent se1;
      input StateEvent se2;
      output Boolean outBoolean;
    algorithm
      outBoolean := 0==compare(se1, se2);
    end equals;

    function compare "Returns true if both zero crossings have the same function expression"
      input StateEvent se1;
      input StateEvent se2;
      output Integer comp;
    algorithm
      comp := match (se1.relation, se2.relation)
        local
          Call call1, call2;
          Expression e1, e2, e3, e4;
        case (Expression.CALL(call = call1), Expression.CALL(call = call2))
        then match (Call.getNameAndArgs(call1), Call.getNameAndArgs(call2))
          case (("sample", e1::_), ("sample", e2::_))   then Expression.compare(e1,e2);
          case (("integer", e1::_), ("integer", e2::_)) then Expression.compare(e1,e2);
          case (("floor", e1::_), ("floor", e2::_))     then Expression.compare(e1,e2);
          case (("ceil", e1::_), ("ceil", e2::_))       then Expression.compare(e1,e2);
          case (("mod", e1::e2::_), ("mod", e3::e4::_)) then BackendUtil.compareCombine(Expression.compare(e1, e3), Expression.compare(e2, e4));
          case (("div", e1::e2::_), ("div", e3::e4::_)) then BackendUtil.compareCombine(Expression.compare(e1, e3), Expression.compare(e2, e4));
        end match;
        else Expression.compare(se1.relation, se2.relation);
      end match;
    end compare;

    function convert
      input StateEvent se;
      output OldBackendDAE.ZeroCrossing oldZc;
    algorithm
      oldZc := OldBackendDAE.ZERO_CROSSING(
        relation_   = Expression.toDAE(se.relation),
        occurEquLst = {} //ToDo: low priority - only for debugging
      );
    end convert;
  end StateEvent;


// =========================================================================
//                    PROTECTED UNIONTYPES AND FUNCTIONS
// =========================================================================

protected
  package TimeEventSet
    extends BaseAvlSet;
    redeclare type Key = TimeEvent;

    redeclare function extends keyStr
    algorithm
      outString := TimeEvent.toString(inKey);
    end keyStr;

    redeclare function extends keyCompare
    algorithm
      outResult := TimeEvent.compare(inKey1, inKey2);
    end keyCompare;
  end TimeEventSet;

  package TimeEventTree
    extends BaseAvlTree;
    redeclare type Key = Expression;
    redeclare type Value = Pointer<Variable>;

    redeclare function extends keyStr
    algorithm
      outString := Expression.toString(inKey);
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := Variable.toString(Pointer.access(inValue));
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := Expression.compare(inKey1, inKey2);
    end keyCompare;
  end TimeEventTree;

  package StateEventTree
    "Lookup StateEvent -> list<PointerEquation>"
    extends BaseAvlTree;
    redeclare type Key = StateEvent;
    redeclare type Value = list<Pointer<Equation>>;

    redeclare function extends keyStr
    algorithm
      outString := StateEvent.toString(inKey);
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := stringDelimitList(list(Equation.toString(Pointer.access(eq)) for eq in inValue), "\n");
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := StateEvent.compare(inKey1, inKey2);
    end keyCompare;

    function toEventList
      input Tree tree;
      output list<StateEvent> events;
    protected
      list<tuple<StateEvent, list<Pointer<Equation>>>> key_value_tpl_lst;
    algorithm
      key_value_tpl_lst := toList(tree);
      events := list(combineKeyValue(tpl) for tpl in key_value_tpl_lst);
    end toEventList;

    function combineKeyValue
      input tuple<StateEvent, list<Pointer<Equation>>> key_value_tpl;
      output StateEvent stateEvent;
    protected
      list<Pointer<Equation>> eqn_lst;
    algorithm
      (stateEvent, eqn_lst) := key_value_tpl;
      stateEvent.occurEqLst := eqn_lst;
    end combineKeyValue;

  end StateEventTree;

  uniontype Bucket
    record BUCKET
      TimeEventSet.Tree timeEventSet        "tracks compact time events (SINGLE or SAMPLE)";
      TimeEventTree.Tree timeEventTree      "tracks full time events of the form $TEV_11 = ...";
      StateEventTree.Tree stateEventTree    "tracks full state events of the form $SEV_4 = ...";
      Integer timeEventIndex                "used for internal indexing of time events";
      Integer auxiliaryTimeEventIndex       "used for indexing new $TEV vars";
      Integer auxiliaryStateEventIndex      "used for indexing new $SEV vars";
    end BUCKET;
  end Bucket;

  function eventsDefault extends Module.eventsInterface;
  protected
    Bucket bucket = BUCKET(TimeEventSet.new(), TimeEventTree.new(), StateEventTree.new(), 0, 0, 0);
    list<Pointer<Variable>> auxiliary_vars;
    list<Pointer<Equation>> auxiliary_eqns;
  algorithm
    eventInfo := match (varData, eqData)
      case (BVariable.VAR_DATA_SIM(), BEquation.EQ_DATA_SIM()) algorithm
        // collect event info and replace all conditions with auxiliary variables
        bucket := EquationPointers.foldPtr(eqData.equations, collectEvents, bucket);
        (eventInfo, auxiliary_vars, auxiliary_eqns) := EventInfo.create(bucket, eqData.uniqueIndex);

        // add auxiliary variables
        varData.variables := VariablePointers.addList(auxiliary_vars, varData.variables);
        varData.unknowns := VariablePointers.addList(auxiliary_vars, varData.unknowns);
        varData.initials := VariablePointers.addList(auxiliary_vars, varData.initials);
        varData.discretes := VariablePointers.addList(auxiliary_vars, varData.discretes);

        // add auxiliary equations
        eqData.equations := EquationPointers.addList(auxiliary_eqns, eqData.equations);
        eqData.simulation := EquationPointers.addList(auxiliary_eqns, eqData.simulation);
        eqData.initials := EquationPointers.addList(auxiliary_eqns, eqData.initials);
        eqData.discretes := EquationPointers.addList(auxiliary_eqns, eqData.discretes);
      then eventInfo;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end eventsDefault;

  function collectEvents
    input Pointer<Equation> eqn_ptr;
    input output Bucket bucket;
  protected
    Equation eqn = Pointer.access(eqn_ptr);
  algorithm
    bucket := match eqn
      local
        WhenEquationBody whenBody;
        IfEquationBody ifBody;

      case Equation.WHEN_EQUATION() algorithm
        (whenBody, bucket) := collectEventsWhenBody(eqn.body, bucket , eqn_ptr);
        eqn.body := whenBody;
      then bucket;

      case Equation.IF_EQUATION() algorithm
        (ifBody, bucket) := collectEventsIfBody(eqn.body, bucket , eqn_ptr);
        eqn.body := ifBody;
      then bucket;

      else bucket;
    end match;

    if not referenceEq(eqn, Pointer.access(eqn_ptr)) then
      Pointer.update(eqn_ptr, eqn);
    end if;
  end collectEvents;

  function collectEventsWhenBody
    input output WhenEquationBody body;
    input output Bucket bucket;
    input Pointer<Equation> eqn_ptr;
  protected
    Expression new_condition;
    WhenEquationBody else_when;
  algorithm
    // condition is replaced by auxiliary variable
    (new_condition, bucket) := collectEventsCondition(body.condition, bucket, eqn_ptr);
    body.condition := new_condition;

    // ToDo: traverse statements?

    // go deeper and collect in else when
    if Util.isSome(body.else_when) then
      (else_when, bucket) := collectEventsWhenBody(Util.getOption(body.else_when), bucket, eqn_ptr);
      body.else_when := SOME(else_when);
    end if;
  end collectEventsWhenBody;

  function collectEventsIfBody
    input output IfEquationBody body;
    input output Bucket bucket;
    input Pointer<Equation> eqn_ptr;
  protected
    Expression new_condition;
    IfEquationBody else_if;
  algorithm
    // condition is replaced by auxiliary variable
    (new_condition, bucket) := collectEventsCondition(body.condition, bucket, eqn_ptr);
    body.condition := new_condition;

    // ToDo: traverse statements?

    // go deeper and collect in else if
    if Util.isSome(body.else_if) then
      (else_if, bucket) := collectEventsIfBody(Util.getOption(body.else_if), bucket, eqn_ptr);
      body.else_if := SOME(else_if);
    end if;
  end collectEventsIfBody;

  function collectEventsCondition
    input output Expression condition;
    input output Bucket bucket;
    input Pointer<Equation> eqn_ptr;
  protected
    Boolean failed = true;
  algorithm
    // try to create time event
    if BackendUtil.isOnlyTimeDependent(condition) then
      (condition, bucket, failed) := TimeEvent.create(condition, bucket);
    end if;

    // if it failed create state event
    if failed then
      (condition, bucket) := StateEvent.create(condition, bucket, eqn_ptr);
    end if;
  end collectEventsCondition;

annotation(__OpenModelica_Interface="backend");
end NBEvents;
