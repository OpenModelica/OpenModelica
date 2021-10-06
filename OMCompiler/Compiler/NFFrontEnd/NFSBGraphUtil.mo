/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFSBGraphUtil

protected
  import SBGraph.VertexDescriptor;
  import SBGraph.IncidenceList;
  import Array;
  import Ceval = NFCeval;
  import Dimension = NFDimension;
  import MetaModelica.Dangerous.*;
  import Error;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import Op = NFOperator.Op;
  import SBInterval;
  import SBLinearMap;
  import SBMultiInterval;
  import SBPWLinearMap;
  import SBSet;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import System;
  import Vector;

public
  function multiIntervalFromDimensions
    input list<Dimension> dims;
    input Vector<Integer> vCount;
    output SBMultiInterval multiInt;
  protected
    Vector<Integer> new_vCount;
    Integer vc, dim_size, index;
    array<SBInterval> ints;
    SBInterval int;
  algorithm
    if listEmpty(dims) then
      vc := Vector.get(vCount, 1);
      Vector.update(vCount, 1, vc + 1);

      multiInt := SBMultiInterval.fromArray(arrayCreate(Vector.size(vCount), SBInterval.new(vc, 1, vc)));
    else
      ints := arrayCreate(Vector.size(vCount), SBInterval.newEmpty());
      new_vCount := Vector.copy(vCount);
      index := 1;

      for dim in dims loop
        if not Dimension.isKnown(dim) then
          Error.assertion(false, getInstanceName() + ": unknown dimension " + Dimension.toString(dim),
                                 sourceInfo());
        end if;

        dim_size := Dimension.size(dim);
        vc := Vector.get(vCount, index);
        int := SBInterval.new(vc, 1, vc + dim_size - 1);

        if SBInterval.isEmpty(int) then
          ints := listArray({});
          break;
        else
          ints[index] := int;
          Vector.update(new_vCount, index, vc + dim_size);
        end if;

        index := index + 1;
      end for;

      for i in listLength(dims)+1:Vector.size(vCount) loop
        vc := Vector.get(vCount, 1);
        ints[i] := SBInterval.new(vc, 1, vc);
      end for;

      multiInt := SBMultiInterval.fromArray(ints);

      if not SBMultiInterval.isEmpty(multiInt) then
        Vector.swap(new_vCount, vCount);
      end if;
    end if;
  end multiIntervalFromDimensions;

  function multiIntervalFromSubscripts
    input list<Subscript> subs;
    input Vector<Integer> vCount;
    input output SBMultiInterval multiInt;
  protected
    array<SBInterval> mi, miv;
    SBInterval int;
    Integer index, aux_lo;
    Expression sub_exp;
  algorithm
    miv := SBMultiInterval.intervals(multiInt);

    if listEmpty(subs) then
      mi := Array.map(miv, make_lo_interval);
    else
      index := 1;
      mi := arrayCopy(miv);

      for s in subs loop
        sub_exp := evalCrefs(Subscript.toExp(s));
        int := intervalFromExp(sub_exp);
        aux_lo := SBInterval.lowerBound(miv[index]) - 1;
        int := SBInterval.new(aux_lo + SBInterval.lowerBound(int),
                              SBInterval.stepValue(int),
                              aux_lo + SBInterval.upperBound(int));

        if not SBInterval.isEmpty(int) then
          mi[index] := int;
        else
          mi := listArray({});
          break;
        end if;

        index := index + 1;
      end for;

      for i in listLength(subs)+1:arrayLength(mi) loop
        aux_lo := SBInterval.lowerBound(miv[i]);
        mi[index] := SBInterval.new(aux_lo, 1, aux_lo);
      end for;
    end if;

    multiInt := SBMultiInterval.fromArray(mi);
  end multiIntervalFromSubscripts;

  function make_lo_interval
    input SBInterval i;
    output SBInterval res;
  protected
    Integer lo = SBInterval.lowerBound(i);
  algorithm
    res := SBInterval.new(lo, 1, lo);
  end make_lo_interval;

  function evalCrefs
    input output Expression e;
  protected
    function evalCref
      input Expression e;
      output Expression outExp;
    algorithm
      if Expression.isCref(e) then
        outExp := Ceval.evalExp(e, Ceval.EvalTarget.RANGE(AbsynUtil.dummyInfo));
      else
        outExp := e;
      end if;
    end evalCref;
  algorithm
    e := Expression.map(e, evalCref);
  end evalCrefs;

  function intervalFromExp
    input Expression e;
    output SBInterval i;
  algorithm
    i := match e
      case Expression.INTEGER() then SBInterval.new(e.value, 1, e.value);
      case Expression.BOOLEAN() then SBInterval.new(Util.boolInt(e.value), 1, Util.boolInt(e.value));
      case Expression.REAL() then SBInterval.new(realInt(e.value), 1, realInt(e.value));
      case Expression.BINARY() then intervalFromBinaryExp(e.exp1, e.operator, e.exp2);
      case Expression.UNARY() then intervalFromUnaryExp(e.exp);
      case Expression.RANGE() then intervalFromRange(e);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown expression " +
                                 Expression.toString(e), sourceInfo());
        then
          fail();
    end match;
  end intervalFromExp;

  function intervalFromBinaryExp
    input Expression lhs;
    input Operator op;
    input Expression rhs;
    output SBInterval i;
  protected
    SBInterval lhs_i, rhs_i;
    Integer lhs_sz, rhs_sz, res;
    Integer llo, rlo, lhi, rhi, step;
  algorithm
    lhs_i := intervalFromExp(lhs);
    rhs_i := intervalFromExp(rhs);

    lhs_sz := SBInterval.size(lhs_i);
    rhs_sz := SBInterval.size(rhs_i);

    llo := SBInterval.lowerBound(lhs_i);
    rlo := SBInterval.lowerBound(rhs_i);

    if lhs_sz == 1 and rhs_sz == 1 then
      Expression.INTEGER(value = res) :=
        Ceval.evalBinaryOp_dispatch(Expression.INTEGER(llo), op, Expression.INTEGER(rlo));
      i := SBInterval.new(res, 1, res);
    elseif lhs_sz == 1 or rhs_sz == 1 then
      lhi := SBInterval.upperBound(lhs_i);
      rhi := SBInterval.upperBound(rhs_i);
      step := SBInterval.stepValue(if lhs_sz == 1 then rhs_i else lhs_i);

      i := match op.op
        case Op.ADD then SBInterval.new(llo + rlo, step, lhi + rhi);
        case Op.SUB then SBInterval.new(llo - rlo, step, lhi - rhi);
        case Op.MUL then SBInterval.new(llo * rlo, llo * step, lhi * rhi);
        else
          algorithm
            Error.assertion(false, getInstanceName() +
              " got unknown operator " + Operator.symbol(op), sourceInfo());
          then
            fail();
      end match;
    else
      Error.assertion(false, getInstanceName() + " got unknown expression " +
        Expression.toString(Expression.BINARY(lhs, op, rhs)) + "\n", sourceInfo());
    end if;
  end intervalFromBinaryExp;

  function intervalFromUnaryExp
    input Expression e;
    output SBInterval i;
  algorithm
    i := intervalFromExp(e);
    i := SBInterval.new(-SBInterval.lowerBound(i), 1, -SBInterval.upperBound(i));
  end intervalFromUnaryExp;

  function intervalFromRange
    input Expression e;
    output SBInterval i;
  protected
    Expression start, stop;
    Option<Expression> ostep;
    Integer lo, step, hi;
  algorithm
    Expression.RANGE(start = start, step = ostep, stop = stop) := SimplifyExp.simplify(e);
    lo := Expression.toInteger(start);
    hi := Expression.toInteger(stop);

    if isSome(ostep) then
      step := Expression.toInteger(Util.getOption(ostep));
    else
      step := 1;
    end if;

    i := SBInterval.new(lo, step, hi);
  end intervalFromRange;

  function linearMapFromIntervals
    input VertexDescriptor d1;
    input VertexDescriptor d2;
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    input Vector<Integer> eCount;
    output String name;
    output SBPWLinearMap pw1;
    output SBPWLinearMap pw2;
  protected
    array<SBInterval> ints1, ints2, mi;
    Integer mi1_sz, mi2_sz, sz, sz1, sz2;
    Integer count, aux_ec;
    array<Real> g1, g2, o1, o2;
    Real g1i, g2i, o1i, o2i;
    SBInterval i1, i2;
    Vector<Integer> new_ec;
    SBSet s;
    SBLinearMap lm1, lm2;
  algorithm
    ints1 := SBMultiInterval.intervals(mi1);
    mi1_sz := SBMultiInterval.size(mi1);

    ints2 := SBMultiInterval.intervals(mi2);
    mi2_sz := SBMultiInterval.size(mi2);

    if SBMultiInterval.ndim(mi1) <> SBMultiInterval.ndim(mi2) and
       mi1_sz <> 1 and mi2_sz <> 1 then
      Error.assertion(false, getInstanceName() + " got incompatible connect", sourceInfo());
    end if;

    sz := arrayLength(ints1);
    g1 := arrayCreateNoInit(sz, 0.0);
    g2 := arrayCreateNoInit(sz, 0.0);
    o1 := arrayCreateNoInit(sz, 0.0);
    o2 := arrayCreateNoInit(sz, 0.0);
    mi := arrayCreateNoInit(sz, ints1[1]);
    new_ec := Vector.new<Integer>();

    for i in 1:sz loop
      sz1 := SBInterval.size(ints1[i]);
      sz2 := SBInterval.size(ints2[i]);

      if sz1 <> sz2 and sz1 <> 1 and sz2 <> 1 then
        Error.assertion(false, getInstanceName() + " got incompatible connect", sourceInfo());
      end if;

      count := max(sz1, sz2);
      aux_ec := Vector.get(eCount, i);
      mi[i] := SBInterval.new(aux_ec, 1, aux_ec + count - 1);

      i1 := ints1[i];
      i2 := ints2[i];

      if sz1 == 1 then
        g1[i] := 0.0;
        o1[i] := SBInterval.lowerBound(i1);
      else
        g1i := SBInterval.stepValue(i1);
        o1i := -g1i * aux_ec + SBInterval.lowerBound(i1);
        g1[i] := g1i;
        o1[i] := o1i;
      end if;

      if sz2 == 1 then
        g2[i] := 0.0;
        o2[i] := SBInterval.lowerBound(i2);
      else
        g2i := SBInterval.stepValue(i2);
        o2i := -g2i * aux_ec + SBInterval.lowerBound(i2);
        g2[i] := g2i;
        o2[i] := o2i;
      end if;

      Vector.push(new_ec, aux_ec + count);
    end for;

    Vector.swap(eCount, new_ec);

    s := SBSet.newEmpty();
    s := SBSet.addAtomicSet(SBAtomicSet.new(SBMultiInterval.fromArray(mi)), s);

    lm1 := SBLinearMap.new(g1, o1);
    lm2 := SBLinearMap.new(g2, o2);

    pw1 := SBPWLinearMap.newScalar(s, lm1);
    pw2 := SBPWLinearMap.newScalar(s, lm2);

    name := "E" + String(System.tmpTick());
  end linearMapFromIntervals;

  annotation(__OpenModelica_Interface="frontend");
end NFSBGraphUtil;