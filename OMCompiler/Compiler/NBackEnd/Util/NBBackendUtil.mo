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
encapsulated package NBBackendUtil
" file:         NBBackendUtil.mo
  package:      NBBackendUtil
  description:  This file contains util functions for the backend.
"

public
  // NF imports
  import BackendExtension = NFBackendExtension;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import Variable = NFVariable;

  // backend imports
  import BEquation = NBEquation;
  import NBEquation.{Equation, Frame, FrameLocation};
  import BVariable = NBVariable;

  // Util imports
  import Util;

  function findTrueIndices
    "returns all indices of elements that are true"
    input array<Boolean> arr;
    output list<Integer> indices = list(i for i guard arr[i] in arrayLength(arr):-1:1);
  end findTrueIndices;

  function countElem
    input array<list<Integer>> m;
    output Integer count = 0;
  algorithm
    for lst in m loop
      count := count + listLength(lst);
    end for;
  end countElem;

  function indexTplGt<T>
    "use with List.sort() and a rating function to sort any list"
    input tuple<Integer, T> tpl1;
    input tuple<Integer, T> tpl2;
    output Boolean gt;
  protected
    Integer i1, i2;
  algorithm
    (i1, _) := tpl1;
    (i2, _) := tpl2;
    gt := if i1 > i2 then true else false;
  end indexTplGt;

  function compareCombine
    "combines two integer values for tree management.
    Only returns 0 if both are 0"
    input Integer i1;
    input Integer i2;
    output Integer comp;
  algorithm
    if i1 == 0 and i2 == 0 then
      comp := 0;
    elseif i1 == -i2 then
      comp := i1 + 2*i2;
    else
      comp := i1 + i2;
    end if;
  end compareCombine;

  function locationToIndex
    "reverse function to indexToLocation()
    maps a frame location to a scalar index starting from first index (one based!)"
    input list<tuple<Integer,Integer>> size_val_tpl_lst;
    input output Integer index;
  protected
    Integer size, val, factor = 1;
  algorithm
    for tpl in listReverse(size_val_tpl_lst) loop
      (size, val) := tpl;
      //print("(" + intString(size) + "," + intString(val) + ")");
      index := index + (val-1) * factor;
      factor := factor * size;
    end for;
    //print("=>" + intString(index) + "\n");
  end locationToIndex;

  function indexToLocation
    "reverse function to locationToIndex()
    maps a scalar index to its frame location (zero based!)"
    input Integer index;
    input list<Integer> sizes;
    output list<Integer> vals = {};
  protected
    Integer iterator = index, v, ss;
    Integer divisor = product(s for s in sizes);
  algorithm

    for size in sizes loop
      divisor   := intDiv(divisor, size);
      vals      := intDiv(iterator, divisor) :: vals;
      iterator  := mod(iterator, divisor);
    end for;
    vals := listReverse(vals);

    //print("idx : " + intString(index) + " - ");
    for tpl in List.zip(sizes, vals) loop
      (ss, v) := tpl;
      //print("(" + intString(ss) + ", " + intString(v) + ")");
    end for;
    //print("\n");
  end indexToLocation;

  function compareLocations
    "compares to frames of the same size and returns an array
    containing the differences"
    input list<Integer> location1;
    input list<Integer> location2;
    output list<Integer> diffs= {};
  protected
    list<tuple<Integer, Integer>> location_tpl = List.zip(location1, location2);
    Integer v1, v2;
  algorithm
    for tpl in location_tpl loop
      (v1, v2) := tpl;
      diffs := v1 - v2 :: diffs;
    end for;
    diffs := listReverse(diffs);
  end compareLocations;

  function transposeLocations
    "transpose the location indices.
    Before:   Each inner list of indices represents a scalar equations
              location inside all of the dimensions
    After:    Each inner array of indices represents the location of all
              scalar equations for just one of the dimensions.
              (still in order from Sorting)"
    input list<list<Integer>> locations;
    input Integer out_size;
    output list<array<Integer>> locations_transposed;
  protected
    array<list<Integer>> lT_tmp = arrayCreate(out_size, {});
    array<array<Integer>> lT_tmp2 = arrayCreate(out_size, arrayCreate(0,0));
    Integer idx;
  algorithm
    for location in locations loop
      idx := 1;
      for i in location loop
        lT_tmp[idx] := i :: lT_tmp[idx];
        idx := idx + 1;
      end for;
    end for;
    for j in 1:arrayLength(lT_tmp) loop
      lT_tmp2[j] := listArray(listReverse(lT_tmp[j]));
    end for;
    locations_transposed := listReverse(arrayList(lT_tmp2));
  end transposeLocations;

  function orderTransposedFrameLocations
    "order the frame locations by ascending inertia.
    (the longer the chain of equal values at the start, the higher the inertia)
    This is done to perform necessary reordering of nested for-loops"
    input output list<FrameLocation> frame_locations_transposed;
  protected
    list<tuple<Integer, FrameLocation>> frame_inertia_lst;
  algorithm
    frame_inertia_lst := list((frameLocationInertia(frame), frame) for frame in frame_locations_transposed);
    frame_inertia_lst := List.sort(frame_inertia_lst, Util.compareTupleIntGt);
    frame_locations_transposed := list(Util.tuple22(frame_inertia) for frame_inertia in frame_inertia_lst);
  end orderTransposedFrameLocations;

  protected function frameLocationInertia
    "the longer the chain of equal values at the start, the higher the inertia"
    input FrameLocation frameLocation;
    output Integer inertia = 1;
  protected
    array<Integer> dim;
  algorithm
    dim := Util.tuple21(frameLocation);
    while inertia < arrayLength(dim) and dim[inertia] == dim[inertia+1] loop
      inertia := inertia + 1;
    end while;
  end frameLocationInertia;

  public function recollectRangesHeuristic
    "consecutively builds up the new frames from frame locations.
    Assumes that slicing along the dimensions is possible.
    ToDo:
      - Add special case to catch diagonal slicing
      - Implement check that fails (or scalarizes) if it is not consistent"
    input list<FrameLocation> frame_locations_transposed;
    output list<Frame> frames = {};
  protected
    array<Integer> dim;
    Frame frame;
    Integer pre_shift, shift = 1;
    Integer start, step, stop, max_size, new_step, new_stop;
    list<Integer> rest;
  algorithm
    for tpl in frame_locations_transposed loop
      (dim, frame) := tpl;
      pre_shift := shift;
      max_size := arrayLength(dim);
      if max_size == 1 then
        // if there is only one frame, it is a single equation at that exact point
        frames := applyNewFrameRange(frame, (dim[1], 0, dim[1])) :: frames;
        //print("I:" + List.toString(arrayList(dim), intString) + " --> (" + intString(dim[1]) + ", " +intString(0) + ", " + intString(dim[1]) + ")\n");
      else
        start := dim[1];
        stop := dim[1 + shift];
        step := stop - start;
        if step == 0 then
          // if the step size is zero, this range only has a single entry
          frames := applyNewFrameRange(frame, (start, 1, start)) :: frames;
          //print("II:" + List.toString(arrayList(dim), intString) + " --> (" + intString(start) + ", " +intString(1) + ", " + intString(start) + ")\n");
        else
          // go forward until the step changes
          new_step := step;
          new_stop := stop;
          while (new_step == step) and (shift + pre_shift < max_size) loop
            //print(intString(max_size) + " > " + intString(shift) + " + " + intString(pre_shift) + "\n");
            stop := new_stop;
            shift := shift + pre_shift;
            new_stop := dim[1 + shift];
            new_step := new_stop - stop;
          end while;
          if new_step == step then
            stop := new_stop;
          end if;
          frames := applyNewFrameRange(frame, (start, step, stop)) :: frames;
          //print("III:" + List.toString(arrayList(dim), intString) + " --> (" + intString(start) + ", " +intString(step) + ", " + intString(stop) + ")\n");
        end if;
      end if;
    end for;
  end recollectRangesHeuristic;

  function applyFrameInversion
    "inverts all frames that have negative location difference"
    input output list<Frame> frames;
    input list<Integer> diffs;
  algorithm
    frames := match (frames, diffs)
      local
        list<Frame> rest_frames;
        ComponentRef name;
        Expression range;
        list<Integer> rest_diffs;
        Integer diff;

      // nothing left to do
      case ({}, {}) then {};

      // this range has to be inverted
      case ((name, range) :: rest_frames, diff :: rest_diffs) guard(diff > 0)
      then (name, Expression.invertRange(range)) :: applyFrameInversion(rest_frames, rest_diffs);

      // this range does not have to be inverted
      case ((name, range) :: rest_frames, _ :: rest_diffs)
      then (name, range) :: applyFrameInversion(rest_frames, rest_diffs);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because frames and diffs seem to have different length."});
      then fail();
    end match;
  end applyFrameInversion;

  protected function applyNewFrameRange
    "applies new start, step and stop to a frame"
    input output Frame frame;
    input tuple<Integer, Integer, Integer> range;
  algorithm
    frame := match frame
      local
        ComponentRef name;
        Expression exp;

      case (name, exp as Expression.RANGE()) then (name, Expression.sliceRange(exp, range));

      case (_, exp) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
          + " failed because frame expression was not Expression.RANGE(): " + Expression.toString(exp)});
      then fail();
    end match;
  end applyNewFrameRange;

  public function noNameHashEq
    input BEquation.Equation eq;
    input Integer mod;
    output Integer hash;
  algorithm
    hash := noNameHashExp(BEquation.Equation.getResidualExp(eq), mod);
  end noNameHashEq;

  function noNameHashExp
    input Expression exp;
    input Integer mod;
    output Integer hash = 0;
  algorithm
    hash := match exp
      local
        Variable var;
        Integer hash1, hash2;
      case Expression.INTEGER() then exp.value;
      case Expression.REAL() then realInt(exp.value);
      case Expression.STRING() then stringHashDjb2Mod(exp.value, mod);
      case Expression.BOOLEAN() then Util.boolInt(exp.value);
      case Expression.ENUM_LITERAL() then exp.index; // ty !!
      case Expression.CLKCONST () then 0; // clk !!
      case Expression.CREF() algorithm
        var := BVariable.getVar(exp.cref);
      then stringHashDjb2Mod(BackendExtension.BackendInfo.toString(var.backendinfo), mod);
      case Expression.TYPENAME() then 1; // ty !!
      case Expression.ARRAY() algorithm // ty !!
        for elem in exp.elements loop
          hash := hash + noNameHashExp(elem, mod);
        end for;
        hash := hash + Util.boolInt(exp.literal);
      then hash;
      case Expression.MATRIX() algorithm
        for lst in exp.elements loop
          for elem in lst loop
            hash := hash + noNameHashExp(elem, mod);
          end for;
        end for;
      then hash;
      case Expression.RANGE() algorithm
        if isSome(exp.step) then
          hash := noNameHashExp(Util.getOption(exp.step), mod);
        end if;
      then hash + noNameHashExp(exp.start, mod) + noNameHashExp(exp.stop, mod);
      case Expression.TUPLE() algorithm // ty !!
        for elem in exp.elements loop
          hash := hash + noNameHashExp(elem, mod);
        end for;
      then hash;
      case Expression.RECORD() algorithm // path, ty !!
        for elem in exp.elements loop
          hash := hash + noNameHashExp(elem, mod);
        end for;
      then hash;
      case Expression.CALL() then 2; // call!!
      case Expression.SIZE() algorithm
        if isSome(exp.dimIndex) then
          hash := noNameHashExp(Util.getOption(exp.dimIndex), mod);
        end if;
      then hash + noNameHashExp(exp.exp, mod);
      case Expression.END() then stringHashDjb2Mod("end", mod);
      case Expression.BINARY() algorithm
        hash1 := noNameHashExp(exp.exp1, mod);
        hash2 := noNameHashExp(exp.exp2, mod);
        hash := match Operator.classify(exp.operator)
          case (NFOperator.MathClassification.ADDITION, _)        then hash1 + hash2;
          case (NFOperator.MathClassification.SUBTRACTION, _)     then hash1 - hash2;
          case (NFOperator.MathClassification.MULTIPLICATION, _)  then hash1 * hash2;
          case (NFOperator.MathClassification.DIVISION, _)        then realInt(hash1 / hash2);
          case (NFOperator.MathClassification.POWER, _)           then realInt(hash1 ^ hash2);
          case (NFOperator.MathClassification.LOGICAL, _)         then -(hash1 + hash2);
          case (NFOperator.MathClassification.RELATION, _)        then hash2 - hash1;
          else hash2 - hash1;
        end match;
      then hash;
      case Expression.UNARY() then -noNameHashExp(exp.exp, mod);
      case Expression.LBINARY() algorithm
        hash1 := noNameHashExp(exp.exp1, mod);
        hash2 := noNameHashExp(exp.exp2, mod);
        hash := match exp.operator.op
          case NFOperator.Op.AND then hash1 + hash2;
          case NFOperator.Op.OR then hash1 - hash2;
          else hash2 - hash1;
        end match;
      then hash;
      case Expression.LUNARY() then -noNameHashExp(exp.exp, mod);
      case Expression.RELATION() algorithm
        hash1 := noNameHashExp(exp.exp1, mod);
        hash2 := noNameHashExp(exp.exp2, mod);
        hash := match exp.operator.op
          case NFOperator.Op.LESS       then hash1 + hash2;
          case NFOperator.Op.LESSEQ     then -(hash1 + hash2);
          case NFOperator.Op.GREATER    then hash1 - hash2;
          case NFOperator.Op.GREATEREQ  then hash2 - hash1;
          case NFOperator.Op.EQUAL      then hash1 * hash2;
          case NFOperator.Op.NEQUAL     then realInt(hash1 ^ hash2);
          else hash2 - hash1;
        end match;
      then hash;
      case Expression.IF() then noNameHashExp(exp.condition, mod) +
                                noNameHashExp(exp.trueBranch, mod) +
                                noNameHashExp(exp.falseBranch, mod);
      case Expression.CAST() then noNameHashExp(exp.exp, mod);
      case Expression.BOX() then noNameHashExp(exp.exp, mod);
      case Expression.UNBOX() then noNameHashExp(exp.exp, mod);
      case Expression.SUBSCRIPTED_EXP() then noNameHashExp(exp.exp, mod); // subscripts!
      case Expression.TUPLE_ELEMENT() then noNameHashExp(exp.tupleExp, mod) + exp.index;
      case Expression.RECORD_ELEMENT() then noNameHashExp(exp.recordExp, mod) + exp.index;
      case Expression.MUTABLE() then noNameHashExp(Mutable.access(exp.exp), mod);
      case Expression.EMPTY() then stringHashDjb2Mod("empty", mod);
      case Expression.PARTIAL_FUNCTION_APPLICATION() algorithm
        //should we hash function names here?
        for arg in exp.args loop
          hash := hash + noNameHashExp(arg, mod);
        end for;
      then hash;
      else 0;
    end match;
    hash := intMod(intAbs(hash), mod);
  end noNameHashExp;

  function isOnlyTimeDependent
    input Expression exp;
    output Boolean b;
  algorithm
    b := Expression.fold(exp, isOnlyTimeDependentFold, true);
  end isOnlyTimeDependent;

  function isOnlyTimeDependentFold
    input Expression exp;
    input output Boolean b;
  algorithm
    if b then
      b := match exp
        case Expression.CREF() then ComponentRef.isTime(exp.cref) or BVariable.checkCref(exp.cref, BVariable.isParamOrConst);
        else true;
      end match;
    end if;
  end isOnlyTimeDependentFold;

  annotation(__OpenModelica_Interface="backend");
end NBBackendUtil;
