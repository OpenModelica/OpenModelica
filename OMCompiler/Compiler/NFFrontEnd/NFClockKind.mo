/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated uniontype NFClockKind
  import Absyn;
  import DAE;
  import Expression = NFExpression;

protected
  import AbsynUtil;
  import ClockKind = NFClockKind;

public
  record INFERRED_CLOCK
  end INFERRED_CLOCK;

  record RATIONAL_CLOCK
    Expression intervalCounter " integer type >= 0 ";
    Expression resolution " integer type >= 1, defaults to 1 ";
  end RATIONAL_CLOCK;

  record REAL_CLOCK
    Expression interval " real type > 0 ";
  end REAL_CLOCK;

  record EVENT_CLOCK
    Expression condition " boolean type ";
    Expression startInterval " real type >= 0.0 ";
  end EVENT_CLOCK;

  record SOLVER_CLOCK
    Expression c "clock type ";
    Expression solverMethod " string type ";
  end SOLVER_CLOCK;

  function compare
    input ClockKind ck1;
    input ClockKind ck2;
    output Integer comp;
  algorithm
    comp := match (ck1, ck2)
      local
        Expression i1, ic1, r1, c1, si1, sm1, i2, ic2, r2, c2, si2, sm2;
      case (INFERRED_CLOCK(), INFERRED_CLOCK()) then 0;
      case (RATIONAL_CLOCK(i1, r1),RATIONAL_CLOCK(i2, r2))
        algorithm
          comp := Expression.compare(i1, i2);
          if (comp == 0) then
            comp := Expression.compare(r1, r2);
          end if;
        then comp;
      case (REAL_CLOCK(i1), REAL_CLOCK(i2)) then Expression.compare(i1, i2);
      case (EVENT_CLOCK(c1, si1), EVENT_CLOCK(c2, si2))
        algorithm
          comp := Expression.compare(c1, c2);
          if (comp == 0) then
            comp := Expression.compare(si1, si2);
          end if;
        then comp;
      case (SOLVER_CLOCK(c1, sm2), SOLVER_CLOCK(c2, sm1))
        algorithm
          comp := Expression.compare(c1, c2);
          if (comp == 0) then
            comp := Expression.compare(sm1, sm2);
          end if;
        then comp;
    end match;
  end compare;

  function containsExp
    input ClockKind ck;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match ck
      case RATIONAL_CLOCK() then Expression.contains(ck.intervalCounter, func) or
                                Expression.contains(ck.resolution, func);
      case REAL_CLOCK()    then Expression.contains(ck.interval, func);
      case EVENT_CLOCK() then Expression.contains(ck.condition, func) or
                                Expression.contains(ck.startInterval, func);
      case SOLVER_CLOCK()  then Expression.contains(ck.c, func) or
                                Expression.contains(ck.solverMethod, func);
      else false;
    end match;
  end containsExp;

  function containsExpShallow
    input ClockKind ck;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match ck
      case RATIONAL_CLOCK() then func(ck.intervalCounter) or func(ck.resolution);
      case REAL_CLOCK()    then func(ck.interval);
      case EVENT_CLOCK() then func(ck.condition) or func(ck.startInterval);
      case SOLVER_CLOCK()  then func(ck.c) or func(ck.solverMethod);
      else false;
    end match;
  end containsExpShallow;

  function applyExp
    input ClockKind ck;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match ck
      case RATIONAL_CLOCK()
        algorithm
          Expression.apply(ck.intervalCounter, func);
          Expression.apply(ck.resolution, func);
        then
          ();

      case REAL_CLOCK()
        algorithm
          Expression.apply(ck.interval, func);
        then
          ();

      case EVENT_CLOCK()
        algorithm
          Expression.apply(ck.condition, func);
          Expression.apply(ck.startInterval, func);
        then
          ();

      case SOLVER_CLOCK()
        algorithm
          Expression.apply(ck.c, func);
          Expression.apply(ck.solverMethod, func);
        then
          ();

      else ();
    end match;
  end applyExp;

  function applyExpShallow
    input ClockKind ck;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match ck
      case RATIONAL_CLOCK()
        algorithm
          func(ck.intervalCounter);
          func(ck.resolution);
        then
          ();

      case REAL_CLOCK()
        algorithm
          func(ck.interval);
        then
          ();

      case EVENT_CLOCK()
        algorithm
          func(ck.condition);
          func(ck.startInterval);
        then
          ();

      case SOLVER_CLOCK()
        algorithm
          func(ck.c);
          func(ck.solverMethod);
        then
          ();

      else ();
    end match;
  end applyExpShallow;

  function foldExp<ArgT>
    input ClockKind ck;
    input FoldFunc func;
    input ArgT arg;
    output ArgT result;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    result := match ck
      case RATIONAL_CLOCK()
        algorithm
          result := Expression.fold(ck.intervalCounter, func, arg);
        then
          Expression.fold(ck.resolution, func, result);

      case REAL_CLOCK()
        then Expression.fold(ck.interval, func, arg);

      case EVENT_CLOCK()
        algorithm
          result := Expression.fold(ck.condition, func, arg);
        then
          Expression.fold(ck.startInterval, func, result);

      case SOLVER_CLOCK()
        algorithm
          result := Expression.fold(ck.c, func, arg);
        then
          Expression.fold(ck.solverMethod, func, result);

      else arg;
    end match;
  end foldExp;

  function mapExp
    input ClockKind ck;
    input MapFunc func;
    output ClockKind outCk;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    Expression e1, e2, e3, e4;
  algorithm
    outCk := match ck
      case RATIONAL_CLOCK(e1, e2)
        algorithm
          e3 := Expression.map(e1, func);
          e4 := Expression.map(e2, func);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else RATIONAL_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          e3 := Expression.map(e1, func);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case EVENT_CLOCK(e1, e2)
        algorithm
          e3 := Expression.map(e1, func);
          e4 := Expression.map(e2, func);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else EVENT_CLOCK(e3, e4);

      case SOLVER_CLOCK(e1, e2)
        algorithm
          e3 := Expression.map(e1, func);
          e4 := Expression.map(e2, func);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else SOLVER_CLOCK(e3, e4);

      else ck;
    end match;
  end mapExp;

  function mapExpShallow
    input ClockKind ck;
    input MapFunc func;
    output ClockKind outCk;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    Expression e1, e2, e3, e4;
  algorithm
    outCk := match ck
      case RATIONAL_CLOCK(e1, e2)
        algorithm
          e3 := func(e1);
          e4 := func(e2);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else RATIONAL_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          e3 := func(e1);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case EVENT_CLOCK(e1, e2)
        algorithm
          e3 := func(e1);
          e4 := func(e2);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else EVENT_CLOCK(e3, e4);

      case SOLVER_CLOCK(e1, e2)
        algorithm
          e3 := func(e1);
          e4 := func(e2);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else SOLVER_CLOCK(e3, e4);

      else ck;
    end match;
  end mapExpShallow;

  function mapFoldExp<ArgT>
    input ClockKind ck;
    input MapFunc func;
          output ClockKind outCk;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    Expression e1, e2, e3, e4;
  algorithm
    outCk := match ck
      case RATIONAL_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFold(e1, func, arg);
          (e4, arg) := Expression.mapFold(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else RATIONAL_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          (e3, arg) := Expression.mapFold(e1, func, arg);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case EVENT_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFold(e1, func, arg);
          (e4, arg) := Expression.mapFold(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else EVENT_CLOCK(e3, e4);

      case SOLVER_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFold(e1, func, arg);
          (e4, arg) := Expression.mapFold(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else SOLVER_CLOCK(e3, e4);

      else ck;
    end match;
  end mapFoldExp;

  function mapFoldExpShallow<ArgT>
    input ClockKind ck;
    input MapFunc func;
          output ClockKind outCk;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    Expression e1, e2, e3, e4;
  algorithm
    outCk := match ck
      case RATIONAL_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
          (e4, arg) := Expression.mapFoldShallow(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else RATIONAL_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case EVENT_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
          (e4, arg) := Expression.mapFoldShallow(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else EVENT_CLOCK(e3, e4);

      case SOLVER_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
          (e4, arg) := Expression.mapFoldShallow(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else SOLVER_CLOCK(e3, e4);

      else ck;
    end match;
  end mapFoldExpShallow;

  function toAbsyn
    input ClockKind clk;
    output Absyn.Exp exp;
  protected
    list<Absyn.Exp> args;
  algorithm
    args := match clk
      case INFERRED_CLOCK() then {};
      case RATIONAL_CLOCK()
        then {Expression.toAbsyn(clk.intervalCounter), Expression.toAbsyn(clk.resolution)};
      case REAL_CLOCK()
        then {Expression.toAbsyn(clk.interval)};
      case EVENT_CLOCK()
        then {Expression.toAbsyn(clk.condition), Expression.toAbsyn(clk.startInterval)};
      case SOLVER_CLOCK()
        then {Expression.toAbsyn(clk.c), Expression.toAbsyn(clk.solverMethod)};
    end match;

    exp := AbsynUtil.makeCall(Absyn.ComponentRef.CREF_IDENT("Clock", {}), args);
  end toAbsyn;

  function toDAE
    input ClockKind ick;
    output DAE.ClockKind ock;
  algorithm
    ock := match ick
      local
        Expression i, ic, r, c, si, sm;
      case INFERRED_CLOCK()     then DAE.INFERRED_CLOCK();
      case RATIONAL_CLOCK(i, r)  then DAE.RATIONAL_CLOCK(Expression.toDAE(i), Expression.toDAE(r));
      case REAL_CLOCK(i)        then DAE.REAL_CLOCK(Expression.toDAE(i));
      case EVENT_CLOCK(c, si) then DAE.EVENT_CLOCK(Expression.toDAE(c), Expression.toDAE(si));
      case SOLVER_CLOCK(c, sm)  then DAE.SOLVER_CLOCK(Expression.toDAE(c), Expression.toDAE(sm));
    end match;
  end toDAE;

  function toDebugString
    input ClockKind ick;
    output String ock;
  algorithm
    ock := match ick
      local
        Expression i, ic, r, c, si, sm;
      case INFERRED_CLOCK()     then "INFERRED_CLOCK()";
      case RATIONAL_CLOCK(i, r)  then "RATIONAL_CLOCK(" + Expression.toString(i) + ", " + Expression.toString(r) + ")";
      case REAL_CLOCK(i)        then "REAL_CLOCK(" + Expression.toString(i) + ")";
      case EVENT_CLOCK(c, si) then "EVENT_CLOCK(" + Expression.toString(c) + ", " + Expression.toString(si) + ")";
      case SOLVER_CLOCK(c, sm)  then "SOLVER_CLOCK(" + Expression.toString(c) + ", " + Expression.toString(sm) + ")";
    end match;
  end toDebugString;

  function toString
    input ClockKind ck;
    output String str;
  algorithm
    str := match ck
      local
        Expression e1, e2;

      case INFERRED_CLOCK()      then "";
      case RATIONAL_CLOCK(e1, e2) then Expression.toString(e1) + ", " + Expression.toString(e2);
      case REAL_CLOCK(e1)        then Expression.toString(e1);
      case EVENT_CLOCK(e1, e2) then Expression.toString(e1) + ", " + Expression.toString(e2);
      case SOLVER_CLOCK(e1, e2)  then Expression.toString(e1) + ", " + Expression.toString(e2);
    end match;

    str := "Clock(" + str + ")";
  end toString;

  function toFlatString
    input ClockKind ck;
    output String str;
  algorithm
    str := match ck
      local
        Expression e1, e2;

      case INFERRED_CLOCK()      then "";
      case RATIONAL_CLOCK(e1, e2) then Expression.toFlatString(e1) + ", " + Expression.toFlatString(e2);
      case REAL_CLOCK(e1)        then Expression.toFlatString(e1);
      case EVENT_CLOCK(e1, e2) then Expression.toFlatString(e1) + ", " + Expression.toFlatString(e2);
      case SOLVER_CLOCK(e1, e2)  then Expression.toFlatString(e1) + ", " + Expression.toFlatString(e2);
    end match;

    str := "Clock(" + str + ")";
  end toFlatString;

annotation(__OpenModelica_Interface="frontend");
end NFClockKind;

