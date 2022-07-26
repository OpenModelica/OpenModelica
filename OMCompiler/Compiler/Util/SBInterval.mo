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

encapsulated uniontype SBInterval
  "Interval type for set based graphs."

  import UnorderedSet;

protected
  import System;
  import MetaModelica.Dangerous.listReverseInPlace;

  function euclid
    "uses the extended euclidean algorithm to compute
     - greatest common divisor d = gcd(a,b)
     - least common multiple m = lcm(a,b) = a*(b/d)
     - Bézout coefficients ua + vb = u*a + v*b = d
    "
    input Integer a;
    input Integer b;
    output Integer d "gcd";
    output Integer m "lcm";
    output Integer ua;
    output Integer vb;
  protected
    Integer q;
    Integer r1 = a, r2 = b;
    Integer s1 = a, s2 = 0;
    Integer tmp;
  algorithm
    while r2 <> 0 loop
      q := div(r1, r2);

      tmp := r2;
      r2 := r1 - q * r2;
      r1 := tmp;

      tmp := s2;
      s2 := s1 - q * s2;
      s1 := tmp;
    end while;
    d := r1;
    m := abs(s2);
    ua := s1;
    vb := r1 - s1;
  end euclid;

public
  record INTERVAL
    Integer lo;
    Integer step;
    Integer hi;
  end INTERVAL;

  function new
    input Integer lo;
    input Integer step;
    input Integer hi;
    output SBInterval int;
  protected
    Integer r;
  algorithm
    if lo >= 0 and step > 0 and hi >= 0 then
      if lo <= hi and hi < System.intMaxLit() then
        int := INTERVAL(lo, step, hi - mod(hi - lo, step));
      elseif lo <= hi and hi == System.intMaxLit() then
        int := INTERVAL(lo, step, System.intMaxLit());
      else
        // Warning: Wrong values for subscript (check low <= hi).
        int := INTERVAL(lo, 0, hi);
      end if;
    elseif lo >= 0 and step == 0 and hi == lo then
      int := INTERVAL(lo, 1, hi);
    else
      // Warning: Subscript should be positive.
      int := newEmpty();
    end if;
  end new;

  function newEmpty
    output SBInterval int = INTERVAL(-1, 0, -1);
  end newEmpty;

  function newUnit
    output SBInterval int = INTERVAL(1, 1, 1);
  end newUnit;

  function newFull
    output SBInterval int = INTERVAL(1, 1, System.intMaxLit());
  end newFull;

  function lowerBound
    input SBInterval int;
    output Integer lo = int.lo;
  end lowerBound;

  function stepValue
    input SBInterval int;
    output Integer step = int.step;
  end stepValue;

  function upperBound
    input SBInterval int;
    output Integer hi = int.hi;
  end upperBound;

  function crop
    input output SBInterval int;
  algorithm
    if int.hi < System.intMaxLit() then
      int.hi := int.hi - mod(int.hi - int.lo, int.step);
    end if;
  end crop;

  function intersection
    input SBInterval int1;
    input SBInterval int2;
    output SBInterval int;
  protected
    Integer new_lo, new_step, new_hi;
    Integer gcd_, ua, vb, x;
  algorithm
    if int1.hi < int2.lo or int2.hi < int1.lo then
      // The intervals do not intersect.
      int := newEmpty();
    else
      // The new step will be the least common multiple of the two intervals' steps.
      (gcd_, new_step, ua, vb) := euclid(int1.step, int2.step);

      if 0 <> mod(int1.lo - int2.lo, gcd_) then
        // The intervals step through each other without touching
        int := newEmpty();
      else
        // x is an integer on both intervals (modulo new_step)
        x := div(int1.lo, gcd_) * vb + div(int2.lo, gcd_) * ua + mod(int1.lo, gcd_);

        // Find new lower and upper bound, crop with x
        new_lo := intMax(int1.lo, int2.lo);
        new_hi := intMin(int1.hi, int2.hi);
        new_lo := new_lo + mod(x - new_lo, new_step);
        if new_hi < System.intMaxLit() then
          new_hi := new_hi - mod(new_hi - x, new_step);
        end if;

        if new_hi < new_lo then
          // Empty interval
          int := newEmpty();
        else
          int := new(new_lo, new_step, new_hi);
        end if;
      end if;
    end if;
  end intersection;

  function complement
    "Returns a set of intervals corresponding to the removal of int2 from int1."
    input SBInterval int1;
    input SBInterval int2;
    output UnorderedSet<SBInterval> ints;
  protected
    SBInterval i2;
    Integer count_r, count_s;
  algorithm
    ints := UnorderedSet.new(hash, isEqual);
    i2 := intersection(int1, int2);

    if isEmpty(i2) then
      // No intersection, nothing to remove.
      UnorderedSet.add(int1, ints);
    elseif not isEqual(int1, i2) then
      // Rightmost interval.
      if i2.hi < int1.hi then
        UnorderedSet.add(new(i2.hi + int1.step, int1.step, int1.hi), ints);
      end if;

      count_r := div(i2.step, int1.step) - 1;
      count_s := if i2.hi < System.intMaxLit() then div(i2.hi - i2.lo, i2.step) else System.intMaxLit();

      if count_r < count_s then
        // create an interval for every residue class not equal to i2.lo
        if count_s < System.intMaxLit() then
          for i in count_r:-1:1 loop
            UnorderedSet.add(new(i2.lo + i * int1.step, i2.step, i2.hi - i2.step + i * int1.step), ints);
          end for;
        else
          for i in count_r:-1:1 loop
            UnorderedSet.add(new(i2.lo + i * int1.step, i2.step, System.intMaxLit()), ints);
          end for;
        end if;
      else
        // create an interval for every space between removed points
        for i in count_s:-1:1 loop
          UnorderedSet.add(new(i2.lo + int1.step + (i - 1) * i2.step, int1.step, i2.lo - int1.step + i * i2.step), ints);
        end for;
      end if;

      // Leftmost interval.
      if i2.lo > int1.lo then
        UnorderedSet.add(new(int1.lo, int1.step, i2.lo - int1.step), ints);
      end if;
    end if;
  end complement;

  function affine
    "Affine function for scaling and offsetting an interval."
    input SBInterval int;
    input Real gain;
    input Integer offset;
    output SBInterval res;
  protected
    Real lo, step, hi;
    Integer ilo, istep, ihi;
  algorithm
    INTERVAL(lo, step, hi) := int;

    if gain > 0 then
      lo := lo * gain + offset;
      hi := hi * gain + offset;
      step := step * gain;

      if step < 1 then
        step := 1.0;
        lo := ceil(lo);
        hi := floor(hi);
      end if;

      if lo < 0 then
        lo := lo + step * (1 + floor(abs(lo) / step));
      end if;

      if hi < lo then
        // Empty interval.
        res := newEmpty();
      else
        ilo := integer(lo);
        ihi := integer(hi);
        istep := if ilo == ihi then 1 else integer(step);

        res := new(ilo, istep, ihi);
      end if;
    else
      if offset > 0 then
        res := new(offset, 1, offset);
      else
        // Empty interval.
        res := newEmpty();
      end if;
    end if;
  end affine;

  function cardinality
    input SBInterval int;
    output Integer card = realInt(intReal(int.hi - int.lo)/intReal(int.step));
  end cardinality;

  function contains
    "Returns true if c belongs to the interval, otherwise false."
    input Integer c;
    input SBInterval int;
    output Boolean res;
  algorithm
    res := not isEmpty(int) and
           c >= int.lo and
           c <= int.hi and
           mod(c - int.lo, int.step) == 0;
  end contains;

  function isEmpty
    input SBInterval int;
    output Boolean res = int.step == 0;
  end isEmpty;

  function size
    input SBInterval int;
    output Integer res = intDiv(int.hi - int.lo, int.step) + 1;
  end size;

  function isEqual
    input SBInterval int1;
    input SBInterval int2;
    output Boolean equal;
  algorithm
    equal := int1.lo == int2.lo and int1.step == int2.step and int1.hi == int2.hi;
  end isEqual;

  function hash
    input SBInterval int;
    input Integer mod;
    output Integer hash = intMod(int.lo, mod);
  end hash;

  function toString
    input SBInterval interval;
    output String str;
  algorithm
    str := "[" + String(interval.lo) + ":" +
                 String(interval.step) + ":" +
                 String(interval.hi) + "]";
  end toString;

annotation(__OpenModelica_Interface="util");
end SBInterval;
