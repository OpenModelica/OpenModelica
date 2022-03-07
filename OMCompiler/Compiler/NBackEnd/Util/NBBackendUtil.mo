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
  import Type = NFType;
  import Variable = NFVariable;

  // backend imports
  import BEquation = NBEquation;
  import NBEquation.{Equation, Frame, FrameLocation};
  import System = NBSystem;
  import BVariable = NBVariable;

  // Util imports
  import Util;

  type RecollectStatus = enumeration(SUCCESS, FAILURE);
  type FrameOrderingStatus = enumeration(UNCHANGED, CHANGED, FAILURE);

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

    for tpl in List.zip(sizes, vals) loop
      (ss, v) := tpl;
    end for;
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
    output UnorderedMap<ComponentRef, Expression> replacements = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    output FrameOrderingStatus status;
  protected
    list<tuple<Integer, FrameLocation>> frame_inertia_lst;
  algorithm
    // get inertia for each frame
    frame_inertia_lst := list((frameLocationInertia(frame), frame) for frame in frame_locations_transposed);
    // sort by inertia (ascending)
    frame_inertia_lst := List.sort(frame_inertia_lst, Util.compareTupleIntGt);
    // resolve equal inertia (diagonal slices)
    (frame_inertia_lst, status) := resolveEqualInertia(frame_inertia_lst, replacements);
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

  protected function resolveEqualInertia
    input list<tuple<Integer, FrameLocation>> frame_inertia_lst;
    input UnorderedMap<ComponentRef, Expression> replacements;
    output list<tuple<Integer, FrameLocation>> resolved = {};
    output FrameOrderingStatus status = FrameOrderingStatus.UNCHANGED;
  protected
    tuple<Integer, FrameLocation> tpl1, tpl2;
    list<tuple<Integer, FrameLocation>> rest;
  algorithm
    tpl1 :: rest := frame_inertia_lst;
    while not listEmpty(rest) loop
      tpl2 :: rest := rest;
      tpl1 := match (tpl1, tpl2)
        local
          Integer inertia1, inertia2, m, b;
          array<Integer> loc1, loc2;
          ComponentRef name1, name2;
          Operator addOp, mulOp;
          Expression linMap;

        // equal inertia, combine the frames
        case ((inertia1, (loc1, (name1, _))), (inertia2, (loc2, (name2, _)))) guard(inertia1 == inertia2) algorithm
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, NFOperator.SizeClassification.SCALAR), Type.INTEGER());
          mulOp := Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, NFOperator.SizeClassification.SCALAR), Type.INTEGER());
          if arrayLength(loc1) <> arrayLength(loc2) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because frames have same inertia but different length.\n"
              + List.toString(arrayList(loc1), intString) + "\n" + List.toString(arrayList(loc2), intString)});
            status := FrameOrderingStatus.FAILURE;
          elseif arrayLength(loc1) == 1 then
            b := loc2[1] - loc1[1];
            linMap := Expression.fromCref(name1);
            if b <> 0 then
              linMap := Expression.MULTARY({Expression.INTEGER(b), linMap}, {}, addOp);
            end if;
            UnorderedMap.add(name2, linMap, replacements);
            status := FrameOrderingStatus.CHANGED;
          else
            // compute linear map from frame1 to frame2 (y = m*x + b)
            // ToDo: integer to real conversion might be wrong?
            m := realInt((loc2[1]-loc2[1+inertia2])/(loc1[1]-loc1[1+inertia1]));
            b := loc2[1]-m*loc1[1];
            // check if linear map holds
            for i in 2:arrayLength(loc1) loop
              if loc2[i] <> m*loc1[i] + b then
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because frames have same inertia but the linear map does not hold.\n"
                  + "map: y = " + intString(m) + " * x + " + intString(b) + "\n" + List.toString(arrayList(loc1), intString) + "\n" + List.toString(arrayList(loc2), intString)});
                status := FrameOrderingStatus.FAILURE;
              end if;
            end for;
            linMap := Expression.fromCref(name1);
            if m <> 1 then
              linMap := Expression.MULTARY({Expression.INTEGER(m), linMap}, {}, mulOp);
            end if;
            if b <> 0 then
              linMap := Expression.MULTARY({Expression.INTEGER(b), linMap}, {}, addOp);
            end if;
            UnorderedMap.add(name2, linMap, replacements);
            status := FrameOrderingStatus.CHANGED;
          end if;
        then tpl1;

        // different inertia
        else algorithm
          resolved := tpl1 :: resolved;
        then tpl2;
      end match;
    end while;
    resolved := listReverse(tpl1 :: resolved);
  end resolveEqualInertia;

  public function recollectRangesHeuristic
    "consecutively builds up the new frames from frame locations.
    Assumes that slicing along the dimensions is possible.
    Basic Idea:
      1. iterate over each frame location
      2. take first (start) and second (stop) element of frame dim to start the search for a pattern (step = stop - start)
      3. shift the stop location further until the step changes and safe the start-step-stop pattern
        3.1 iterate over the rest of the dim and check if the pattern holds for all of it
        3.2 if it not holds search a missing diagonal for this dimension (reconstruct diagonal)
      4. increase the shift for the length of the previous pattern and go to next frame location (shifting happens inherently in step 3)"
    input list<FrameLocation> frame_locations_transposed;
    output list<Frame> frames = {};
    output Option<UnorderedMap<ComponentRef, Expression>> removed_diagonal = NONE();
    output RecollectStatus status;
  protected
    array<Integer> dim;
    Frame frame;
    Integer check_shift, pre_shift, shift = 1;
    Integer start, step, stop, max_size, new_step, new_stop, check_stop;
    Boolean fail_;
    list<Integer> rest;
    list<Integer> starts = {}, stops = {}, steps = {}, shifts = {};
    list<Boolean> failed = {};
    Integer min_dim, max_dim;
    list<FrameLocation> diagonal;
    UnorderedMap<ComponentRef, Expression> replacements;
    FrameOrderingStatus fos;
  algorithm
    for tpl in frame_locations_transposed loop
      // 1. iterate over each frame location
      fail_ := false;
      (dim, frame) := tpl;
      pre_shift := shift;
      max_size := arrayLength(dim);
      if max_size == 1 then
        // if there is only one frame, it is a single equation at that exact point
        frames := applyNewFrameRange(frame, (dim[1], 0, dim[1])) :: frames;
        starts := dim[1] :: starts;
        steps := 0 :: steps;
        stops := dim[1] :: stops;
        shifts := shift :: shifts;
      else
        // 2. take first (start) and second (stop) element of frame dim to start the search for a pattern (step = stop - start)
        start := dim[1];
        stop := dim[1 + shift];
        step := stop - start;
        if step == 0 then
          // if the step size is zero, this range only has a single entry
          // this should not happen?
          frames := applyNewFrameRange(frame, (start, 1, stop)) :: frames;
          starts := start :: starts;
          steps := step :: steps;
          stops := stop :: stops;
          shifts := shift :: shifts;
        else
          // 3. shift the stop location further until the step changes and safe the start-step-stop pattern
          new_step := step;
          new_stop := stop;
          while (new_step == step) and (shift + pre_shift < max_size) loop
            stop := new_stop;
            shift := shift + pre_shift;
            new_stop := dim[1 + shift];
            new_step := new_stop - stop;
          end while;
          if new_step == step then
            // if new_step and step are still equal we hit the end (max_size)
            stop := new_stop;
            shift := shift + pre_shift; //not necessary but more correct
          else
            // 3.1 iterate over the rest of the dim and check if the pattern holds for all of it
            check_shift := shift;
            while (check_shift + pre_shift < max_size) loop
              new_step := step;
              while (new_step == step) and (check_shift + pre_shift < max_size) loop
                check_stop := new_stop;
                check_shift := check_shift + pre_shift;
                new_stop := dim[1 + check_shift];
                new_step := new_stop - check_stop;
              end while;
              // has to be the same amount of steps after the step size changes
              if (check_shift + pre_shift == max_size) then
                check_shift := check_shift + pre_shift;
              end if;
              if not intMod(check_shift, shift) == 0 then
                fail_ := true;
                break;
              end if;
            end while;
          end if;
          min_dim := min(d for d in dim);
          max_dim := max(d for d in dim);
          if fail_ then
            if step > 0 then
              frames := applyNewFrameRange(frame, (min_dim, step, max_dim)) :: frames;
            else
              frames := applyNewFrameRange(frame, (max_dim, step, min_dim)) :: frames;
            end if;
          else
            frames := applyNewFrameRange(frame, (start, step, stop)) :: frames;
          end if;
          steps := step :: steps;
          starts := if step > 0 then min_dim :: starts else max_dim :: starts;
          stops := if step > 0 then max_dim :: stops else min_dim :: stops;
          shifts := shift :: shifts;
          failed := fail_ :: failed;
        end if;
      end if;
    end for;

    // 3.2 if it not holds search a missing diagonal for this dimension (reconstruct diagonal)
    // if any dimension was not consistent, try to find a missing diagonal
    // it is stored in an unordered map as linear map for the indices
    if List.fold(failed, boolOr, false) then
      diagonal := reconstructDiagonal(frame_locations_transposed, listReverse(starts), listReverse(steps), listReverse(stops), listReverse(shifts), listReverse(failed));
      (diagonal, replacements, fos) := orderTransposedFrameLocations(diagonal);
      if fos == FrameOrderingStatus.CHANGED then
        removed_diagonal := SOME(replacements);
        status := RecollectStatus.SUCCESS;
      else
        // no equal inertia to resolve or unable to resolve
        status := RecollectStatus.FAILURE;
      end if;
    else
      status := RecollectStatus.SUCCESS;
    end if;
  end recollectRangesHeuristic;

  function reconstructDiagonal
    "reconstructs a supposed missing diagonal if it exists.
    ToDo1: create multiple diagonals if missing indices are found in one go without reset"
    input list<FrameLocation> frame_locations_transposed;
    input list<Integer> starts;
    input list<Integer> steps;
    input list<Integer> stops;
    input list<Integer> shifts;
    input list<Boolean> failed;
    output list<FrameLocation> diagonal = {};
  protected
    Integer start, step, stop, pos, shift = 1;
    Boolean fail_;
    list<Integer> start_rest = starts, step_rest = steps, stop_rest = stops, shift_rest = shifts;
    list<Boolean> fail_rest = failed;
    array<Integer> dim;
    list<Integer> missing_dims;
    Frame frame;
  algorithm
    // ToDo: all lists have to be of equal length!
    // default first shift to 1
    for tpl in frame_locations_transposed loop
      // get dims and frame from tpl
      (dim, frame) := tpl;
      // take out start, step, stop, fail
      start :: start_rest := start_rest;
      step :: step_rest := step_rest;
      stop :: stop_rest := stop_rest;
      fail_ :: fail_rest := fail_rest;
      // initialize missing dims and pos
      missing_dims := {};
      pos := start;
      if fail_ then
        for i in 1:shift:arrayLength(dim) loop
          while dim[i] <> pos loop
            // ToDo1
            missing_dims := pos :: missing_dims;
            pos := pos + step;
            if (sign(step)*pos > sign(step)*stop) then
              break;
            end if;
          end while;
          if (sign(step)*(pos+step) > sign(step)*stop) then
            pos := start;
          else
            pos := pos + step;
          end if;
        end for;
        while sign(step)*pos <= sign(step)*stop loop
          missing_dims := pos :: missing_dims;
          pos := pos + step;
        end while;
      else
        for i in 1:shift:arrayLength(dim) loop
          missing_dims := dim[i] :: missing_dims;
        end for;
      end if;
      diagonal := (listArray(listReverse(missing_dims)), frame) :: diagonal;
      // take out shift from shifts
      shift :: shift_rest := shift_rest;
    end for;
    diagonal := listReverse(diagonal);
  end reconstructDiagonal;

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
    "ToDo: is this mod safe? (missing intMod!)"
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
