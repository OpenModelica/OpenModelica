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
  // NF
  import Algorithm = NFAlgorithm;
  import Builtin = NFBuiltin;
  import Call = NFCall;
  import ClockKind = NFClockKind;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTree;
  import Operator = NFOperator;
  import Prefixes = NFPrefixes;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // OB
  import OldBackendDAE = BackendDAE;

  // New Backend
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, Frame, Iterator, EqData, EquationAttributes, EquationKind, EquationPointers, IfEquationBody, WhenEquationBody};
  import Solve = NBSolve;
  import BVariable = NBVariable;
  import NBVariable.{VarData, VariablePointers};

  // SimCode
  import NSimGenericCall.SimIterator;
  import OldSimIterator = BackendDAE.SimIterator;
  import Block = NSimStrongComponent.Block;

  // Util
  import BackendUtil = NBBackendUtil;
  import StringUtil;

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
          (varData, eqData, eventInfo) := func(bdae.varData, bdae.eqData, bdae.eventInfo, bdae.funcTree);
          bdae.varData := varData;
          bdae.eqData := eqData;
          bdae.eventInfo := eventInfo;
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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
      UnorderedSet<TimeEvent> time_set                  "tracks compact time events (SINGLE or SAMPLE)";
      UnorderedMap<Condition, CompositeEvent> time_map  "tracks full time events of the form $TEV_11 = ...";
      UnorderedMap<Condition, StateEvent> state_map     "tracks full state events of the form $SEV_4 = ...";
      Integer numberMathEvents                          "stores the number of math function that trigger events e.g. floor, ceil, integer, ...";
    end EVENT_INFO;

    function toString
      input EventInfo eventInfo;
      output String str = "";
    protected
      list<TimeEvent> tev_lst;
      list<tuple<Condition, CompositeEvent>> cev_lst;
      list<tuple<Condition, StateEvent>> sev_lst;
      function tplString<T1, T2>
        input tuple<T1, T2> tpl;
        input F1 f1;
        input F2 f2;
        output String str;
      protected
        T1 t1;
        T2 t2;
        partial function F1 input T1 t1; output String str; end F1;
        partial function F2 input T2 t2; output String str; end F2;
      algorithm
        (t1, t2) := tpl;
        str := f2(t2) + " = " + f1(t1);
      end tplString;
    algorithm
      if not isEmpty(eventInfo) then
        (tev_lst, cev_lst, sev_lst) := toLists(eventInfo);
        str := StringUtil.headline_2("Event Info") + "\n";
        str := str +  StringUtil.headline_4("Time Events") + List.toString(tev_lst, function TimeEvent.toString(printIndex = true), "", "", "\n", "") + "\n\n";
        str := str +  StringUtil.headline_4("Composite Events") + List.toString(cev_lst, function tplString(f1 = Condition.toString, f2 = CompositeEvent.toString), "", "", "\n", "") + "\n\n";
        str := str +  StringUtil.headline_4("State Events") + List.toString(sev_lst, function tplString(f1 = Condition.toString, f2 = StateEvent.toString), "", "", "\n", "") + "\n\n";
      end if;
    end toString;

    function toLists
      input EventInfo eventInfo;
      output list<TimeEvent> tev_lst;
      output list<tuple<Condition, CompositeEvent>> cev_lst;
      output list<tuple<Condition, StateEvent>> sev_lst;
    algorithm
      tev_lst := List.sort(UnorderedSet.toList(eventInfo.time_set), TimeEvent.indexGt);
      cev_lst := List.sort(UnorderedMap.toList(eventInfo.time_map), CompositeEvent.indexGt);
      sev_lst := List.sort(UnorderedMap.toList(eventInfo.state_map), StateEvent.indexGt);
    end toLists;

    function create
      input Bucket bucket;
      input VariablePointers variables;
      input Pointer<Integer> idx;
      output EventInfo eventInfo;
      output list<Pointer<Variable>> auxiliary_vars = {};
      output list<Pointer<Equation>> auxiliary_eqns = {};
    protected
      Condition cond;
      CompositeEvent cev;
      StateEvent sev;
    algorithm
      // get auxiliary eqns and vars from composite events
      for tpl in UnorderedMap.toList(bucket.time_map) loop
        (cond, cev) := tpl;
        (auxiliary_vars, auxiliary_eqns) := createAux(cond, cev.auxiliary, variables, idx, auxiliary_vars, auxiliary_eqns);
      end for;

      // get auxiliary eqns and vars from state events
      for tpl in UnorderedMap.toList(bucket.state_map) loop
        (cond, sev) := tpl;
        (auxiliary_vars, auxiliary_eqns) := createAux(cond, sev.auxiliary, variables, idx, auxiliary_vars, auxiliary_eqns);
      end for;

      eventInfo := EVENT_INFO(
        time_set          = bucket.time_set,
        time_map          = bucket.time_map,
        state_map         = bucket.state_map, // ToDo: StateEvent.updateIndices(stateEvents),
        numberMathEvents  = 0 // ToDo
      );

      if Flags.isSet(Flags.DUMP_EVENTS) then
        print(toString(eventInfo));
        print(List.toString(auxiliary_eqns, function Equation.pointerToString(str = "  "), StringUtil.headline_4("Event Equations"), "", "\n", "\n\n"));
      end if;
    end create;

    function createAux
      input Condition cond;
      input Pointer<Variable> aux_var;
      input VariablePointers variables;
      input Pointer<Integer> idx;
      input output list<Pointer<Variable>> auxiliary_vars;
      input output list<Pointer<Equation>> auxiliary_eqns;
    protected
      ComponentRef lhs_cref;
      Pointer<Equation> aux_eqn;
    algorithm
      // if it has a statement index, it already has been created as a statement inside an algorithm (0 implies no index)
      if cond.stmt_index == 0 then
        // lower the subscripts (containing iterators)
        lhs_cref := ComponentRef.mapSubscripts(BVariable.getVarName(aux_var), function Subscript.mapExp(
          func = function BackendDAE.lowerComponentReferenceExp(variables = variables, complete = true)));
        aux_eqn := Equation.makeAssignment(Expression.fromCref(lhs_cref), cond.exp, idx, "EVT", cond.iter, EquationAttributes.default(EquationKind.DISCRETE, false));
        auxiliary_eqns := aux_eqn :: auxiliary_eqns;
      end if;
      // remove all subscripts from the variable name
      BVariable.setVarName(aux_var, ComponentRef.stripSubscriptsAll(BVariable.getVarName(aux_var)));
      auxiliary_vars := aux_var :: auxiliary_vars;
    end createAux;

    function createAuxStatements
      input output list<Statement> new_stmts;
      input Pointer<Bucket> bucket_ptr;
      input VariablePointers variables;
    protected
      Bucket bucket = Pointer.access(bucket_ptr);
      Statement new_stmt;
      Condition cond;
      ComponentRef aux, lhs_cref;
    algorithm
      if Util.isSome(bucket.aux_stmts) then
        // add all new statements to the algorithm body
        for tpl in Util.getOption(bucket.aux_stmts) loop
          (cond, aux) := tpl;
          aux               := ComponentRef.mapSubscripts(aux, function Subscript.mapExp(func =
            function BackendDAE.lowerComponentReferenceExp(variables = variables, complete = true)));
          new_stmt          := Statement.makeAssignment(Expression.fromCref(aux), cond.exp, ComponentRef.getSubscriptedType(aux), DAE.emptyElementSource);
          new_stmts         := new_stmt :: new_stmts;
        end for;
        // remove the current statements because they have been added
        bucket.aux_stmts   := NONE();
        Pointer.update(bucket_ptr, bucket);
      end if;
    end createAuxStatements;

    function empty
      output EventInfo eventInfo;
    algorithm
      eventInfo := EVENT_INFO(
        time_set          = UnorderedSet.new(TimeEvent.hash, TimeEvent.isEqual),
        time_map          = UnorderedMap.new<CompositeEvent>(Condition.hash, Condition.isEqual),
        state_map         = UnorderedMap.new<StateEvent>(Condition.hash, Condition.isEqual),
        numberMathEvents  = 0
      );
    end empty;

    function isEmpty
      input EventInfo eventInfo;
      output Boolean b;
    algorithm
      b := UnorderedSet.isEmpty(eventInfo.time_set) and UnorderedMap.isEmpty(eventInfo.time_map) and UnorderedMap.isEmpty(eventInfo.state_map) and eventInfo.numberMathEvents == 0;
    end isEmpty;

    function convert
      input EventInfo eventInfo;
      output list<OldBackendDAE.ZeroCrossing> zeroCrossings;
      output list<OldBackendDAE.ZeroCrossing> relations     "== zeroCrossings for the most part (only eq pointer different?)";
      output list<OldBackendDAE.TimeEvent> timeEvents;
      input UnorderedMap<ComponentRef, Block> equation_map;
    protected
      list<TimeEvent> tev_lst;
      list<tuple<Condition, CompositeEvent>> cev_lst;
      list<tuple<Condition, StateEvent>> sev_lst;
    algorithm
      // add composite at some point?
      (tev_lst, cev_lst, sev_lst) := toLists(eventInfo);
      zeroCrossings := list(StateEvent.convert(sev_tpl, equation_map) for sev_tpl in sev_lst);
      relations := zeroCrossings;
      timeEvents := list(TimeEvent.convert(tev) for tev in tev_lst);
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
      input Boolean printIndex = true "for hashing we want to supress index";
      output String str;
    algorithm
      str := match timeEvent
        case SINGLE() then "time > " + Expression.toString(timeEvent.trigger);
        case SAMPLE() then "sample(" + intString(timeEvent.index) + ", " + Expression.toString(timeEvent.start) + ", " + Expression.toString(timeEvent.interval) + ")";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
      if printIndex then
        str := "(" + intString(getIndex(timeEvent)) + ") " + str;
      end if;
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

    function hash
      input TimeEvent tev;
      output Integer h = stringHashDjb2(toString(tev, false));
    end hash;

    function isEqual
      input TimeEvent tev1;
      input TimeEvent tev2;
      output Boolean b;
    algorithm
      b := match (tev1, tev2)
        case (SINGLE(), SINGLE()) then Expression.isEqual(tev1.trigger, tev2.trigger);
        case (SAMPLE(), SAMPLE()) then Expression.isEqual(tev1.start, tev2.start) and Expression.isEqual(tev1.interval, tev2.interval);
        else false;
      end match;
    end isEqual;

    function indexGt
      input TimeEvent tev1;
      input TimeEvent tev2;
      output Boolean b = getIndex(tev1) > getIndex(tev2);
    end indexGt;

    function create
      input output Expression exp;
      input output Bucket bucket;
      input Iterator iter;
      input Pointer<Equation> eqn;
      input FunctionTree funcTree;
      input Boolean createEqn;
      output Boolean failed = false "returns true if time event list could not be created";
    algorithm
      (exp, bucket, failed) := match exp
        local
          Expression exp1, exp2;
          Boolean b1, b2;

        case Expression.LBINARY()
          guard(Operator.getMathClassification(exp.operator) == NFOperator.MathClassification.LOGICAL)
          algorithm
            (exp1, bucket, b1) := create(exp.exp1, bucket, iter, eqn, funcTree, createEqn);
            (exp2, bucket, b2) := create(exp.exp2, bucket, iter, eqn, funcTree, createEqn);
            failed := (b1 or b2);
            if not failed then
              // we could simplify here
              exp.exp1 := exp1;
              exp.exp2 := exp2;
            end if;
        then (exp, bucket, failed);

        else createSingleOrSample(exp, bucket, iter, eqn, funcTree);
      end match;

      if not failed then
        (exp, bucket) := CompositeEvent.add(exp, iter, bucket, createEqn);
      end if;
    end create;

    function createSingleOrSample
      "The cases:
      1. creates a single time event from a comparing binary expression which
        has to only depend on time
      2. creates a sample time event from a sample operator
      3. fails for anything else
      NOTE: create sample from sin and cos functions?"
      input output Expression exp         "has to be LBINARY() with comparing operator or a sample CALL()";
      input output Bucket bucket          "bucket containing the events";
      input Iterator iter;
      input Pointer<Equation> eqn;
      input FunctionTree funcTree         "function tree for differentiation (solve)";
      output Boolean failed               "true if it did not work to create a compact time event";
    algorithm
      (exp, failed) := match exp
          local
            Equation tmpEqn;
            Solve.Status status;
            Boolean can_trigger;
            Solve.RelationInversion invert;
            Call call;
            Expression trigger, new_exp;
            TimeEvent timeEvent;
            Pointer<Boolean> containsTime = Pointer.create(false);

        // check for "sample" call
        case Expression.CALL() algorithm
          (call, bucket, failed, _) := createSample(exp.call, bucket);
          exp.call := call;
        then (exp, failed);

        // try to extract single time event
        case Expression.RELATION()
          guard(Operator.getMathClassification(exp.operator) == NFOperator.MathClassification.RELATION)
          algorithm
            // create auxiliary equation and solve for TIME
            tmpEqn := Pointer.access(Equation.makeAssignment(exp.exp1, exp.exp2, Pointer.create(0), NBVariable.TEMPORARY_STR, Iterator.EMPTY(), EquationAttributes.default(EquationKind.UNKNOWN, false)));
            _ := Equation.map(tmpEqn, function containsTimeTraverseExp(b = containsTime), SOME(function containsTimeTraverseCref(b = containsTime)));
            if Pointer.access(containsTime) then
              (tmpEqn, _, status, invert) := Solve.solveBody(tmpEqn, NFBuiltin.TIME_CREF, funcTree);
              if status == NBSolve.Status.EXPLICIT and invert <> NBSolve.RelationInversion.UNKNOWN then
                trigger := Equation.getRHS(tmpEqn);
                // only cases for RelationInversion == TRUE or FALSE can be present
                exp.operator := if invert == NBSolve.RelationInversion.TRUE then Operator.invert(exp.operator) else exp.operator;
                if Equation.isWhenEquation(eqn) then
                  // if it is a when equation check if it can even trigger
                  can_trigger := match exp.operator.op
                    case NFOperator.Op.GREATER    then true;
                    case NFOperator.Op.GREATEREQ  then true;
                    else false;
                  end match;
                  // if it can trigger replace it by the sample call, otherwise just make the trigger false
                  new_exp := if can_trigger then Expression.CALL(Call.makeTypedCall(
                      fn          = NFBuiltinFuncs.SAMPLE,
                      args        = {Expression.INTEGER(UnorderedSet.size(bucket.time_set) + 1), trigger, Expression.makeMaxValue(Type.REAL())},
                      variability = NFPrefixes.Variability.DISCRETE,
                      purity      = NFPrefixes.Purity.PURE
                    )) else Expression.BOOLEAN(false);
                else
                  // inside if can always trigger, keep the expression as is
                  can_trigger := true;
                  new_exp := exp;
                end if;

                // create and add the time event
                if can_trigger then
                  timeEvent := SINGLE(UnorderedSet.size(bucket.time_set), trigger);
                  if not UnorderedSet.contains(timeEvent, bucket.time_set) then
                    UnorderedSet.add(timeEvent, bucket.time_set);
                  end if;
                end if;

                failed := false;
              else
                failed := true;
                new_exp := exp;
              end if;
            else
              failed := true;
              new_exp := exp;
            end if;
        then (new_exp, failed);

        else (exp, true);
      end match;
    end createSingleOrSample;

    function createSample
      input output Call call;
      input output Bucket bucket;
      output Boolean failed;
      output Boolean clocked;
    algorithm
      (failed, clocked) := match (AbsynUtil.pathLastIdent(Call.functionName(call)), Call.arguments(call))
        local
          Type ty;
          Integer value;
          Expression start, interval;
          TimeEvent timeEvent;

        // don't create samples for clocks
        case ("sample", {_, Expression.CREF(ty = ty)}) guard(Type.isClock(ty)) then (false, true);

        case ("sample", {start, interval}) algorithm
          timeEvent := SAMPLE(UnorderedSet.size(bucket.time_set), start, interval);
          if not UnorderedSet.contains(timeEvent, bucket.time_set) then
            UnorderedSet.add(timeEvent, bucket.time_set);
          end if;
          // add index to sample interface
          call := Call.setArguments(call, {Expression.INTEGER(getIndex(timeEvent) + 1), start, interval});
        then (false, false);

        case ("sample", _) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for sample operator: " + Call.toString(call)});
        then fail();

        // Maybe add funky sin/cos stuff here

        else (true, false);
      end match;
    end createSample;

    function createSampleTraverse
      "used only for StateEvent traversal to encapsulate sample operators"
      input output Expression exp         "has to be LBINARY() with comparing operator or a sample CALL()";
      input output Bucket bucket          "bucket containing the events";
      input Pointer<Boolean> clocked      "true if its clocked and should not create an auxiliary";
    protected
      Boolean c;
    algorithm
      exp := match exp
        local
          Call call;
        case Expression.CALL(call = call) algorithm
          (call, bucket, _, c) := createSample(call, bucket);
          exp.call := call;
          if c then Pointer.update(clocked, c); end if;
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

    function convert
      input TimeEvent timeEvent;
      output OldBackendDAE.TimeEvent oldTimeEvent;
    algorithm
      oldTimeEvent := match timeEvent
        // treat single time events as sample time events with maximum integer as interval
        case SINGLE() then OldBackendDAE.TimeEvent.SAMPLE_TIME_EVENT(
          index       = timeEvent.index,
          startExp    = Expression.toDAE(timeEvent.trigger),
          intervalExp = Expression.toDAE(Expression.makeMaxValue(Type.REAL())));
        case SAMPLE() then OldBackendDAE.TimeEvent.SAMPLE_TIME_EVENT(
          index       = timeEvent.index,
          startExp    = Expression.toDAE(timeEvent.start),
          intervalExp = Expression.toDAE(timeEvent.interval));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end convert;
  end TimeEvent;

  uniontype StateEvent
    record STATE_EVENT
      Integer index                       "index for simcode";
      Pointer<Variable> auxiliary         "auxiliary variable representing the relation";
      list<Pointer<Equation>> eqns        "list of equations where the function occurs";
    end STATE_EVENT;

    function toString
      input StateEvent sev;
      output String str = "(" + intString(sev.index) + ") " + BVariable.toString(Pointer.access(sev.auxiliary));
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

    function indexGt
      input tuple<Condition, StateEvent> tpl1;
      input tuple<Condition, StateEvent> tpl2;
      output Boolean b;
    protected
      StateEvent sev1, sev2;
    algorithm
      (_, sev1) := tpl1;
      (_, sev2) := tpl2;
      b := sev1.index > sev2.index;
    end indexGt;

    function fromStatement
      input output Statement stmt;
      input Pointer<Bucket> bucket_ptr;
      input Pointer<Equation> eqn;
      input VariablePointers variables;
      input FunctionTree funcTree;
      input list<Frame> frames = {};
    algorithm
      stmt := match stmt
        local
          ComponentRef name;
          Expression range;
          list<Frame> new_frames;
          Iterator iter;
          Statement new_stmt;
          list<Statement> new_stmts;

        case Statement.FOR(range = SOME(range)) algorithm
          new_stmts := {};
          name := ComponentRef.fromNode(stmt.iterator, Type.INTEGER());
          name := BackendDAE.lowerComponentReference(name, variables);
          new_frames := (name, range, NONE()) :: frames;
          for elem in stmt.body loop
            new_stmt := fromStatement(elem, bucket_ptr, eqn, variables, funcTree, new_frames);
            new_stmts := new_stmt :: new_stmts;
            new_stmts := EventInfo.createAuxStatements(new_stmts, bucket_ptr, variables);
          end for;
          stmt.body := listReverse(new_stmts);
        then stmt;

        else algorithm
          iter := Iterator.fromFrames(listReverse(frames));
          stmt := Statement.mapExp(stmt, function Expression.fakeMap(
              func = function collectEventsTraverse(
                bucket_ptr  = bucket_ptr,
                iter        = iter,
                eqn         = eqn,
                funcTree    = funcTree,
                createEqn   = false)));
        then stmt;
      end match;
    end fromStatement;

    function create
      input output Expression exp;
      input output Bucket bucket;
      input Iterator iter;
      input Pointer<Equation> eqn;
      input Boolean createEqn;
    protected
      Condition condition;
      Option<StateEvent> sev_opt;
      StateEvent sev;
      Pointer<Variable> aux_var;
      ComponentRef aux_cref;
      Pointer<Boolean> clocked = Pointer.create(false);
    algorithm
      // collect possible sample events from exp
      (exp, bucket) := Expression.mapFold(exp, function TimeEvent.createSampleTraverse(clocked = clocked), bucket);

      if createEqn then
        // create an equation
        condition := Condition.CONDITION(exp, iter, 0);
      else
        // create a statement inside algorithms
        condition := Condition.CONDITION(exp, iter, bucket.stmt_index);
        bucket.stmt_index := bucket.stmt_index + 1;
      end if;

      sev_opt := UnorderedMap.get(condition, bucket.state_map);
      if Util.isSome(sev_opt) then
        // if the state event already exist update the equations it belongs to
        SOME(sev) := sev_opt;
        sev.eqns := eqn :: sev.eqns;
        UnorderedMap.add(condition, sev, bucket.state_map);
        // return the auxiliary instead of the zero crossing
        aux_cref := BVariable.getVarName(sev.auxiliary);
        exp := Expression.fromCref(aux_cref);
      elseif not Pointer.access(clocked) then
        // make a new auxiliary variable and return the expression which replaces the zero crossing
        (aux_var, aux_cref) := BVariable.makeEventVar(NBVariable.STATE_EVENT_STR, UnorderedMap.size(bucket.state_map), Expression.typeOf(exp), iter);
        exp := Expression.fromCref(aux_cref);

        // add the new event to the map
        sev := STATE_EVENT(UnorderedMap.size(bucket.state_map), aux_var, {eqn});
        condition := Condition.setRelationIndex(condition, sev.index);
        UnorderedMap.add(condition, sev, bucket.state_map);
      end if;

      if not (createEqn or Pointer.access(clocked)) then
        bucket.aux_stmts := SOME((condition, aux_cref) :: Util.getOptionOrDefault(bucket.aux_stmts, {}));
      end if;
    end create;

    function convert
      input tuple<Condition, StateEvent> sev_tpl;
      input UnorderedMap<ComponentRef, Block> equation_map;
      output OldBackendDAE.ZeroCrossing oldZc;
    protected
      Condition cond;
      StateEvent sev;
      Option<list<OldSimIterator>> iter;
      list<ComponentRef> eqn_names;
      list<Integer> eqn_indices;
    algorithm
      (cond, sev) := sev_tpl;
      iter        := if Iterator.isEmpty(cond.iter) then NONE() else SOME(list(SimIterator.convert(it) for it in SimIterator.fromIterator(cond.iter)));
      eqn_names   := list(Equation.getEqnName(eqn) for eqn guard(not Equation.isDummy(Pointer.access(eqn))) in sev.eqns);
      eqn_indices := list(Block.getIndex(UnorderedMap.getSafe(name, equation_map, sourceInfo())) for name guard(UnorderedMap.contains(name, equation_map)) in eqn_names);
      oldZc := OldBackendDAE.ZERO_CROSSING(
        index       = sev.index,
        relation_   = Expression.toDAE(cond.exp),
        occurEquLst = eqn_indices,
        iter        = iter
      );
    end convert;
  end StateEvent;

  uniontype CompositeEvent
    record COMPOSITE_EVENT
      Integer index;
      Pointer<Variable> auxiliary;
    end COMPOSITE_EVENT;

    function toString
      input CompositeEvent cev;
      output String str = "(" + intString(cev.index) + ") " + BVariable.pointerToString(cev.auxiliary);
    end toString;

    function indexGt
      input tuple<Condition, CompositeEvent> tpl1;
      input tuple<Condition, CompositeEvent> tpl2;
      output Boolean b;
    protected
      CompositeEvent cev1, cev2;
    algorithm
      (_, cev1) := tpl1;
      (_, cev2) := tpl2;
      b := cev1.index > cev2.index;
    end indexGt;

    function create
      "Find special events of the form:  sample(t0, dt) and (f(x) > 0)
      These events can only occur at the sample times. At that time the additional condition
      is checked only once, no state event necessary!
      NOTE: This does not work for SIMPLE_TIME, e.g. (time > 0.2) and (f(x) > 0)"
      input output Expression exp;
      input output Bucket bucket;
      input Iterator iter;
      input Boolean createEqn;
      output Boolean failed = false "returns true if composite event list could not be created";
    protected
      Pointer<Variable> aux_var;
      ComponentRef aux_cref;
    algorithm
      (exp, bucket, failed) := match exp
        local
          Expression exp1, exp2;
          Call call;

        // base case: sample is the left operand to AND
        case Expression.LBINARY(exp1 = exp1 as Expression.CALL(call = call), operator = Operator.OPERATOR(op = NFOperator.Op.AND))
          guard BackendUtil.isOnlyTimeDependent(exp1)
          algorithm
            (call, exp2, bucket, failed) := checkDirectComposite(call, exp.exp2, bucket, iter, createEqn);
            if not failed then
              exp1.call := call;
              exp.exp1 := exp1;
              if not referenceEq(exp2, exp.exp2) then
                exp.exp2 := exp2;
              end if;
            end if;
        then (exp, bucket, failed);

        // base case: sample is the right operand to AND
        case Expression.LBINARY(exp2 = exp2 as Expression.CALL(call = call), operator = Operator.OPERATOR(op = NFOperator.Op.AND))
          guard BackendUtil.isOnlyTimeDependent(exp2)
          algorithm
            (call, exp1, bucket, failed) := checkDirectComposite(call, exp.exp1, bucket, iter, createEqn);
            if not failed then
              exp2.call := call;
              exp.exp2 := exp2;
              if not referenceEq(exp1, exp.exp1) then
                exp.exp1 := exp1;
              end if;
            end if;
        then (exp, bucket, failed);

        // recursion: sample might be nested (all parent operators have to be AND)
        // e.g. (sample(t0, dt) and f1(x)) and f2(x)
        case Expression.LBINARY(operator = Operator.OPERATOR(op = NFOperator.Op.AND))
          algorithm
            (exp1, bucket, failed) := create(exp.exp1, bucket, iter, createEqn);
            if not failed then
              exp.exp1 := exp1;
              (exp2, bucket, failed) := create(exp.exp2, bucket, iter, createEqn);
              if not failed then
                // TODO what if there is more than one sample()?
                exp.exp2 := exp2;
              end if;
              failed := false; // we know we have a composite time event in the first half
            else
              (exp2, bucket, failed) := create(exp.exp2, bucket, iter, createEqn);
              if not failed then
                exp.exp2 := exp2;
              end if;
            end if;
        then (exp, bucket, failed);

        else (exp, bucket, true);
      end match;

      if not failed then
        (exp, bucket) := add(exp, iter, bucket, createEqn);
      end if;
    end create;

    function checkDirectComposite
      "Checks if call is a sample call and if it is creates the appropriate events.
      Also checks the rest exp for composite events, not sure if this is necessary."
      input output Call call "sample call";
      input output Expression exp;
      input output Bucket bucket;
      input Iterator iter;
      input Boolean createEqn;
      output Boolean failed;
    protected
      Boolean failed2;
    algorithm
      (call, bucket, failed, _) := TimeEvent.createSample(call, bucket);
      if not failed then
        (exp, bucket, failed2) := create(exp, bucket, iter, createEqn);
        if not failed2 then
          // TODO what if there is more than one sample()? Can we simplify this?
        end if;
      end if;
    end checkDirectComposite;

    function add
      input Expression cond;
      input Iterator iter;
      output Expression exp;
      input output Bucket bucket;
      input Boolean createEqn;
    protected
      Condition condition;
      Option<CompositeEvent> cev_opt;
      CompositeEvent cev;
      Pointer<Variable> aux_var;
      ComponentRef aux_cref;
    algorithm
      if createEqn then
        // create an equation
        condition := Condition.CONDITION(cond, iter, 0);
      else
        // create a statement inside algorithms
        condition := Condition.CONDITION(cond, iter, bucket.stmt_index);
        bucket.stmt_index := bucket.stmt_index + 1;
      end if;

      cev_opt := UnorderedMap.get(condition, bucket.time_map);
      if Util.isSome(cev_opt) then
        // time event already exists, just get the identifier
        SOME(cev) := cev_opt;
        aux_cref := BVariable.getVarName(cev.auxiliary);
        exp := Expression.fromCref(aux_cref);
      else
        // make a new auxiliary variable and return the expression which replaces the zero crossing
        (aux_var, aux_cref) := BVariable.makeEventVar(NBVariable.TIME_EVENT_STR, UnorderedMap.size(bucket.time_map), Expression.typeOf(condition.exp), iter);
        exp := Expression.fromCref(aux_cref);
        // add the new event to the map
        cev := CompositeEvent.COMPOSITE_EVENT(UnorderedMap.size(bucket.time_map), aux_var);
        UnorderedMap.add(condition, cev, bucket.time_map);
      end if;

      if not createEqn then
        bucket.aux_stmts := SOME((condition, aux_cref) :: Util.getOptionOrDefault(bucket.aux_stmts, {}));
      end if;
    end add;
  end CompositeEvent;

  uniontype Condition
    record CONDITION
      Expression exp;
      Iterator iter;
      Integer stmt_index;
    end CONDITION;

    function toString
      input Condition cond;
      output String str;
    algorithm
      str := Expression.toString(cond.exp);
      if not Iterator.isEmpty(cond.iter) then
        str := str + " for {" + Iterator.toString(cond.iter) + "}";
      end if;
      if not cond.stmt_index == 0 then
        str := str + "(" +  intString(cond.stmt_index) + ")";
      end if;
    end toString;

    function hash
      input Condition cond;
      output Integer h = stringHashDjb2(toString(cond));
    end hash;

    function isEqual
      input Condition cond1;
      input Condition cond2;
      output Boolean b = Expression.isEqual(cond1.exp, cond2.exp) and Iterator.isEqual(cond1.iter, cond2.iter) and cond1.stmt_index == cond2.stmt_index;
    end isEqual;

    function size
      input Condition cond;
      output Integer s = Iterator.size(cond.iter);
    end size;

    function setRelationIndex
      input output Condition cond;
      input Integer index;
    algorithm
      cond.exp := match cond.exp
        local
          Expression exp;
        case exp as Expression.RELATION()
          algorithm
            exp.index := index;
          then exp;
        else cond.exp;
      end match;
    end setRelationIndex;
  end Condition;

// =========================================================================
//                    PROTECTED UNIONTYPES AND FUNCTIONS
// =========================================================================

protected
  uniontype Bucket
    record BUCKET
      UnorderedSet<TimeEvent> time_set                      "tracks compact time events (SINGLE or SAMPLE)";
      UnorderedMap<Condition, CompositeEvent> time_map      "tracks full time events of the form $TEV_11 = ...";
      UnorderedMap<Condition, StateEvent> state_map         "tracks full state events of the form $SEV_4 = ...";
      Option<list<tuple<Condition, ComponentRef>>> aux_stmts "optional statement conditions in algorithms";
      Integer stmt_index                                    "index to be used for unique statement auxiliaries";
    end BUCKET;
  end Bucket;

  function eventsDefault extends Module.eventsInterface;
  protected
    Bucket bucket = BUCKET(
      time_set    = UnorderedSet.new(TimeEvent.hash, TimeEvent.isEqual),
      time_map    = UnorderedMap.new<CompositeEvent>(Condition.hash, Condition.isEqual),
      state_map   = UnorderedMap.new<StateEvent>(Condition.hash, Condition.isEqual),
      aux_stmts    = NONE(),
      stmt_index  = 1);
    Pointer<Bucket> bucket_ptr;
    list<Pointer<Variable>> auxiliary_vars;
    list<Pointer<Equation>> auxiliary_eqns;
  algorithm
    eventInfo := match (varData, eqData)
      case (BVariable.VAR_DATA_SIM(), BEquation.EQ_DATA_SIM()) algorithm
        // collect event info and replace all conditions with auxiliary variables
        bucket_ptr := Pointer.create(bucket);
        EquationPointers.mapPtr(eqData.simulation, function collectEvents(bucket_ptr = bucket_ptr, variables = varData.variables, funcTree = funcTree));
        EquationPointers.mapPtr(eqData.clocked, function collectEvents(bucket_ptr = bucket_ptr, variables = varData.variables, funcTree = funcTree));
        EquationPointers.mapPtr(eqData.removed, function collectEvents(bucket_ptr = bucket_ptr, variables = varData.variables, funcTree = funcTree));
        bucket := Pointer.access(bucket_ptr);

        (eventInfo, auxiliary_vars, auxiliary_eqns) := EventInfo.create(bucket, varData.variables, eqData.uniqueIndex);

        // add auxiliary variables
        varData.variables := VariablePointers.addList(auxiliary_vars, varData.variables);
        varData.unknowns  := VariablePointers.addList(auxiliary_vars, varData.unknowns);
        varData.initials  := VariablePointers.addList(auxiliary_vars, varData.initials);
        varData.discretes := VariablePointers.addList(auxiliary_vars, varData.discretes);

        // add auxiliary equations
        eqData.equations  := EquationPointers.addList(auxiliary_eqns, eqData.equations);
        eqData.simulation := EquationPointers.addList(auxiliary_eqns, eqData.simulation);
        eqData.initials   := EquationPointers.addList(auxiliary_eqns, eqData.initials);
        eqData.discretes  := EquationPointers.addList(auxiliary_eqns, eqData.discretes);
      then eventInfo;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end eventsDefault;

  function collectEvents
    "collects all events from an equation pointer."
    input output Pointer<Equation> eqn_ptr;
    input Pointer<Bucket> bucket_ptr;
    input VariablePointers variables;
    input FunctionTree funcTree;
  protected
    Equation eqn = Pointer.access(eqn_ptr), body_eqn;
    Iterator iter;
    Boolean createEqn = not Equation.isAlgorithm(eqn_ptr);
    BEquation.MapFuncExp collector;
    Algorithm alg;
    list<Statement> new_stmts;
  algorithm
    // create the traverser function
    iter := Equation.getForIterator(eqn);
    collector := function collectEventsTraverse(
          bucket_ptr  = bucket_ptr,
          iter        = iter,
          eqn         = eqn_ptr,
          funcTree    = funcTree,
          createEqn   = createEqn);

    eqn := match eqn
      case Equation.ALGORITHM(alg = alg) algorithm
        new_stmts := {};
        for stmt in alg.statements loop
          stmt := StateEvent.fromStatement(stmt, bucket_ptr, eqn_ptr, variables, funcTree);
          new_stmts := EventInfo.createAuxStatements(new_stmts, bucket_ptr, variables);
          new_stmts := stmt :: new_stmts;
        end for;
        // save all the new stuff in our algorithm
        alg.statements  := listReverse(new_stmts);
        eqn.alg         := Algorithm.setInputsOutputs(alg);
        eqn.size        := sum(ComponentRef.size(out, true) for out in eqn.alg.outputs);
      then eqn;

      // For when equations only map the condition and not the body
      case Equation.WHEN_EQUATION() algorithm
        eqn.body := WhenEquationBody.mapCondition(eqn.body, collector, NONE(), Expression.fakeMap);
      then eqn;

      // Also don't do it for when equations in for-equations
      case Equation.FOR_EQUATION(body = {body_eqn as Equation.WHEN_EQUATION()}) algorithm
        body_eqn.body := WhenEquationBody.mapCondition(body_eqn.body, collector, NONE(), Expression.fakeMap);
        eqn.body := {body_eqn};
      then eqn;

      // Map if equation body with this function to ensure that when equation bodies are not traversed
      case Equation.IF_EQUATION() algorithm
        eqn.body := IfEquationBody.mapEqnExpCref(eqn.body,
          func        = function collectEvents(bucket_ptr = bucket_ptr, variables = variables, funcTree = funcTree),
          funcExp     = collector,
          funcCrefOpt = NONE(),
          mapFunc     = Expression.mapReverse);
      then eqn;

      else Equation.map(eqn, collector, NONE(), Expression.fakeMap);
    end match;

    if not referenceEq(eqn, Pointer.access(eqn_ptr)) then
      Pointer.update(eqn_ptr, eqn);
    end if;
  end collectEvents;

  function collectEventsTraverse
    "checks expressions if they are a zero crossing.
    can be used on any expression with Exression.mapReverse
    (reverse is necessary so the subexpressions are not traversed first)"
    input output Expression exp;
    input Pointer<Bucket> bucket_ptr;
    input Iterator iter;
    input Pointer<Equation> eqn;
    input FunctionTree funcTree;
    input Boolean createEqn;
  algorithm
    exp := match exp
      local
        Bucket bucket;
        ClockKind clk;
        Expression condition;
        Call call;
        list<Frame> new_frames;

      // logical unarys: e.g. not a
      // FIXME this is wrong for `not initial()`
      case Expression.LUNARY() algorithm
        (exp, bucket) := collectEventsCondition(exp, Pointer.access(bucket_ptr), iter, eqn, funcTree, createEqn);
        Pointer.update(bucket_ptr, bucket);
      then exp;

      // logical binarys: e.g. (a and b)
      // Todo: this might not always be correct -> check with something like "contains relation?"
      case Expression.LBINARY() algorithm
        (exp, bucket) := collectEventsCondition(exp, Pointer.access(bucket_ptr), iter, eqn, funcTree, createEqn);
        Pointer.update(bucket_ptr, bucket);
      then exp;

      // relations: e.g. (a > b)
      case Expression.RELATION() algorithm
        (exp, bucket) := collectEventsCondition(exp, Pointer.access(bucket_ptr), iter, eqn, funcTree, createEqn);
        Pointer.update(bucket_ptr, bucket);
      then exp;

      // sample functions
      case Expression.CALL() guard(Call.isNamed(exp.call, "sample")) algorithm
        (exp, bucket) := collectEventsCondition(exp, Pointer.access(bucket_ptr), iter, eqn, funcTree, createEqn);
        Pointer.update(bucket_ptr, bucket);
      then exp;

      // event clocks
      case Expression.CLKCONST(clk = clk as ClockKind.EVENT_CLOCK(condition = condition)) algorithm
        clk.condition := collectEventsTraverse(condition, bucket_ptr, iter, eqn, funcTree, createEqn);
        exp.clk := clk;
      then exp;

      // replace $PRE variables with auxiliaries
      // necessary if the $PRE variable is a when condition (cannot check the pre of a pre variable)
      case Expression.CALL(call = Call.TYPED_CALL(arguments = {Expression.CREF()})) guard(Call.isNamed(exp.call, "pre")) algorithm
        (exp, bucket) := CompositeEvent.add(exp, iter, Pointer.access(bucket_ptr), createEqn);
        Pointer.update(bucket_ptr, bucket);
      then exp;
      case Expression.CREF() guard(BVariable.isPrevious(BVariable.getVarPointer(exp.cref, sourceInfo()))) algorithm
        (exp, bucket) := CompositeEvent.add(exp, iter, Pointer.access(bucket_ptr), createEqn);
        Pointer.update(bucket_ptr, bucket);
      then exp;

      // add the reduction iterators to the iterator used to build the condition
      // ToDo: if they are not ranges we need to normalize them
      case Expression.CALL(call = call as Call.TYPED_REDUCTION()) algorithm
        new_frames := list((ComponentRef.fromNode(Util.tuple21(tpl), Type.INTEGER()), Util.tuple22(tpl), NONE()) for tpl in call.iters);
        call.exp := collectEventsTraverse(call.exp, bucket_ptr, Iterator.addFrames(iter, new_frames), eqn, funcTree, createEqn);
        exp.call := call;
      then exp;

      // don't traverse noEvent() calls
      case Expression.CALL() guard(Call.isNamed(exp.call, "noEvent")) then exp;

      // don't traverse cref subscripts
      case Expression.CREF() then exp;

      // ToDo: math events (check the call name in a function and merge with sample case?)

      else Expression.mapShallow(exp, function collectEventsTraverse(
        bucket_ptr  = bucket_ptr,
        iter        = iter,
        eqn         = eqn,
        funcTree    = funcTree,
        createEqn   = createEqn));
    end match;
  end collectEventsTraverse;

  function collectEventsCondition
    "collects an expression as a zero crossing.
    has to be used with collectEventsTraverse to make sure that only
    suitable expressions are checked."
    input output Expression exp;
    input output Bucket bucket;
    input Iterator iter;
    input Pointer<Equation> eqn;
    input FunctionTree funcTree;
    input Boolean createEqn;
  protected
    Boolean failed = true;
  algorithm
    // try to create time event or composite time event
    if BackendUtil.isOnlyTimeDependent(exp) then
      (exp, bucket, failed) := TimeEvent.create(exp, bucket, iter, eqn, funcTree, createEqn);
    else
      (exp, bucket, failed) := CompositeEvent.create(exp, bucket, iter, createEqn);
    end if;

    // if it failed create state event
    if failed then
      (exp, bucket) := StateEvent.create(exp, bucket, iter, eqn, createEqn);
    end if;
  end collectEventsCondition;

  function containsTimeTraverseExp
    input output Expression exp;
    input Pointer<Boolean> b;
  algorithm
    if not Pointer.access(b) and Expression.isTime(exp) then
      Pointer.update(b, true);
    end if;
  end containsTimeTraverseExp;

  function containsTimeTraverseCref
    input output ComponentRef cref;
    input Pointer<Boolean> b;
  algorithm
    if not Pointer.access(b) and ComponentRef.isTime(cref) then
      Pointer.update(b, true);
    end if;
  end containsTimeTraverseCref;

annotation(__OpenModelica_Interface="backend");
end NBEvents;
