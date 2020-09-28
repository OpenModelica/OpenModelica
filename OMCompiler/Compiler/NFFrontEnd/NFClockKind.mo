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
  import DAE;
  import Expression = NFExpression;

protected
  import ClockKind = NFClockKind;

public
  record INFERRED_CLOCK
  end INFERRED_CLOCK;

  record INTEGER_CLOCK
    Expression intervalCounter;
    Expression resolution " integer type >= 1 ";
  end INTEGER_CLOCK;

  record REAL_CLOCK
    Expression interval;
  end REAL_CLOCK;

  record BOOLEAN_CLOCK
    Expression condition;
    Expression startInterval " real type >= 0.0 ";
  end BOOLEAN_CLOCK;

  record SOLVER_CLOCK
    Expression c;
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
      case (INTEGER_CLOCK(i1, r1),INTEGER_CLOCK(i2, r2))
        algorithm
          comp := Expression.compare(i1, i2);
          if (comp == 0) then
            comp := Expression.compare(r1, r2);
          end if;
        then comp;
      case (REAL_CLOCK(i1), REAL_CLOCK(i2)) then Expression.compare(i1, i2);
      case (BOOLEAN_CLOCK(c1, si1), BOOLEAN_CLOCK(c2, si2))
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

  function applyExp
    input ClockKind ck;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match ck
      case INTEGER_CLOCK()
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

      case BOOLEAN_CLOCK()
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
      case INTEGER_CLOCK()
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

      case BOOLEAN_CLOCK()
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
      case INTEGER_CLOCK()
        algorithm
          result := Expression.fold(ck.intervalCounter, func, arg);
        then
          Expression.fold(ck.resolution, func, result);

      case REAL_CLOCK()
        then Expression.fold(ck.interval, func, arg);

      case BOOLEAN_CLOCK()
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
      case INTEGER_CLOCK(e1, e2)
        algorithm
          e3 := Expression.map(e1, func);
          e4 := Expression.map(e2, func);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else INTEGER_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          e3 := Expression.map(e1, func);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case BOOLEAN_CLOCK(e1, e2)
        algorithm
          e3 := Expression.map(e1, func);
          e4 := Expression.map(e2, func);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else BOOLEAN_CLOCK(e3, e4);

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
      case INTEGER_CLOCK(e1, e2)
        algorithm
          e3 := func(e1);
          e4 := func(e2);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else INTEGER_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          e3 := func(e1);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case BOOLEAN_CLOCK(e1, e2)
        algorithm
          e3 := func(e1);
          e4 := func(e2);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else BOOLEAN_CLOCK(e3, e4);

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
      case INTEGER_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFold(e1, func, arg);
          (e4, arg) := Expression.mapFold(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else INTEGER_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          (e3, arg) := Expression.mapFold(e1, func, arg);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case BOOLEAN_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFold(e1, func, arg);
          (e4, arg) := Expression.mapFold(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else BOOLEAN_CLOCK(e3, e4);

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
      case INTEGER_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
          (e4, arg) := Expression.mapFoldShallow(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else INTEGER_CLOCK(e3, e4);

      case REAL_CLOCK(e1)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
        then
          if referenceEq(e1, e3) then ck else REAL_CLOCK(e3);

      case BOOLEAN_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
          (e4, arg) := Expression.mapFoldShallow(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else BOOLEAN_CLOCK(e3, e4);

      case SOLVER_CLOCK(e1, e2)
        algorithm
          (e3, arg) := Expression.mapFoldShallow(e1, func, arg);
          (e4, arg) := Expression.mapFoldShallow(e2, func, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then ck else SOLVER_CLOCK(e3, e4);

      else ck;
    end match;
  end mapFoldExpShallow;

  function toDAE
    input ClockKind ick;
    output DAE.ClockKind ock;
  algorithm
    ock := match ick
      local
        Expression i, ic, r, c, si, sm;
      case INFERRED_CLOCK()     then DAE.INFERRED_CLOCK();
      case INTEGER_CLOCK(i, r)  then DAE.INTEGER_CLOCK(Expression.toDAE(i), Expression.toDAE(r));
      case REAL_CLOCK(i)        then DAE.REAL_CLOCK(Expression.toDAE(i));
      case BOOLEAN_CLOCK(c, si) then DAE.BOOLEAN_CLOCK(Expression.toDAE(c), Expression.toDAE(si));
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
      case INTEGER_CLOCK(i, r)  then "INTEGER_CLOCK(" + Expression.toString(i) + ", " + Expression.toString(r) + ")";
      case REAL_CLOCK(i)        then "REAL_CLOCK(" + Expression.toString(i) + ")";
      case BOOLEAN_CLOCK(c, si) then "BOOLEAN_CLOCK(" + Expression.toString(c) + ", " + Expression.toString(si) + ")";
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
      case INTEGER_CLOCK(e1, e2) then Expression.toString(e1) + ", " + Expression.toString(e2);
      case REAL_CLOCK(e1)        then Expression.toString(e1);
      case BOOLEAN_CLOCK(e1, e2) then Expression.toString(e1) + ", " + Expression.toString(e2);
      case SOLVER_CLOCK(e1, e2)  then Expression.toString(e1) + ", " + Expression.toString(e2);
    end match;

    str := "Clock(" + str + ")";
  end toString;

annotation(__OpenModelica_Interface="frontend");
end NFClockKind;

