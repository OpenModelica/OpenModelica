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
encapsulated uniontype NBSlice<T>
" file:         NBSlicingUtil.mo
  package:      NBSlicingUtil
  description:  This file contains util functions for slicing operations.
"

protected
  import Slice = NBSlice;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;

  // NB imports
  import NBAdjacency.Mapping;
  import BackendUtil = NBBackendUtil;
  import NBEquation.{Equation, Iterator, Frame, FrameLocation, RecollectStatus, FrameOrderingStatus};
  import Replacements = NBReplacements;

  // Util imports
  import List;
  import UnorderedMap;

public
  type IntLst = list<Integer>;

  record SLICE
    T t;
    IntLst indices;
  end SLICE;

  // ############################################################
  //                Member Functions
  // ############################################################

  function getT
    input Slice<T> slice;
    output T t = slice.t;
  end getT;

  function isEqual
    input Slice<T> slice1;
    input Slice<T> slice2;
    input isEqualT func;
    output Boolean b = func(slice1.t, slice2.t) and List.isEqualOnTrue(slice1.indices, slice2.indices, intEq);
  end isEqual;

  function toString
    input Slice<T> slice;
    input toStringT func;
    input Integer maxLength = 10;
    output String str;
  protected
    String sliceStr;
  algorithm
    str := func(slice.t);
      str := str + "\n\t slice: " + List.toString(inList = slice.indices, inPrintFunc = intString, maxLength = 10);
  end toString;

  function lstToString
    input list<Slice<T>> lst;
    input toStringT_ func;
    input Integer maxLength = 10;
    partial function toStringT_ = toStringT "ugly hack to make type T known to subfunction";
    output String str = List.toString(lst, function toString(func = func, maxLength = maxLength), "", "\t", ";\n\t", ";", false);
  end lstToString;

  function simplify
    "only to be used for unordered purposes!
    lists of all indices are meaningful if they are not in the natural ascending order
    and can indicate range reversal in for loops."
    input output Slice<T> slice;
    input sizeT func;
  algorithm
    if listLength(slice.indices) == func(slice.t) then
      slice.indices := {};
    else
      slice.indices := List.sort(slice.indices, intGt);
    end if;
  end simplify;

  function addToSliceMap
    input T t;
    input Integer i;
    input UnorderedMap<T, IntLst> map;
  algorithm
    if UnorderedMap.contains(t, map) then
      UnorderedMap.add(t, i :: UnorderedMap.getSafe(t, map, sourceInfo()), map);
    else
      UnorderedMap.addNew(t, {i}, map);
    end if;
  end addToSliceMap;

  function fromTpl
    input tuple<T, IntLst> tpl;
    output Slice<T> slice;
  protected
    T t;
    IntLst lst;
  algorithm
    (t, lst) := tpl;
    slice := SLICE(t, lst);
  end fromTpl;

  function fromMap
    input UnorderedMap<T, IntLst> map;
    output list<Slice<T>> slices = list(fromTpl(tpl) for tpl in UnorderedMap.toList(map));
  end fromMap;

  function apply
    input output Slice<T> slice;
    input applyT func;
  algorithm
    slice.t := func(slice.t);
  end apply;

  function applyMutable
    input Slice<T> slice;
    input applyMutableT func;
  algorithm
    func(slice.t);
  end applyMutable;

  // ############################################################
  //                Partial Functions
  // ############################################################

  partial function toStringT
    input T t;
    output String str;
  end toStringT;

  partial function sizeT
    input T t;
    output Integer s;
  end sizeT;

  partial function isEqualT
    input T t1;
    input T t2;
    output Boolean b;
  end isEqualT;

  partial function applyT
    input output T t;
  end applyT;

  partial function applyMutableT
    input T t;
  end applyMutableT;

  // ############################################################
  //                cref accumulation Functions
  // use with:
  //    Equation.collectCrefs()
  //    StrongComponent.collectCrefs()
  // ############################################################

  function getDependentCref
    "checks if crefs are relevant in the given context and collects them."
    input output ComponentRef cref                "the cref to check";
    input Pointer<list<ComponentRef>> acc         "accumulator for relevant crefs";
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input Boolean pseudo;
  protected
    ComponentRef checkCref;
  algorithm
    // if causalized in pseudo array mode, the variables will only have subscript-free variables
    checkCref := if pseudo then ComponentRef.stripSubscriptsAll(cref) else cref;
    if UnorderedMap.contains(checkCref, map) then
      Pointer.update(acc, cref :: Pointer.access(acc));
    end if;
  end getDependentCref;

  function getDependentCrefCausalized
    "checks if crefs are relevant in the given context and collects them.
    previously found crefs are replaced by their dependencies! only works on causalized systems."
    input output ComponentRef cref                              "the cref to check";
    input Pointer<list<ComponentRef>> acc                       "accumulator for relevant crefs";
    input UnorderedSet<ComponentRef> set                        "unordered set to check for array crefs for relevance";
  protected
    ComponentRef checkCref;
  algorithm
    // allways remove subscripts here, this analysis is for sparsity pattern -> currently always scalarized!
    if UnorderedSet.contains(ComponentRef.stripSubscriptsAll(cref), set) then
      Pointer.update(acc, cref :: Pointer.access(acc));
    end if;
  end getDependentCrefCausalized;

  function getUnsolvableExpCrefs
    "finds all unsolvable crefs in an expression."
    input output Expression exp                   "the exp to check for unsolvable crefs";
    input Pointer<list<ComponentRef>> acc         "accumulator for relevant crefs";
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input Boolean pseudo;
  algorithm
    // put all unsolvable logic here!
    exp := match exp
      case Expression.RANGE()     then Expression.map(exp, function Equation.filterExp(filter = function getDependentCref(map = map, pseudo = pseudo), acc = acc));
      case Expression.LBINARY()   then Expression.map(exp, function Equation.filterExp(filter = function getDependentCref(map = map, pseudo = pseudo), acc = acc));
      case Expression.RELATION()  then Expression.map(exp, function Equation.filterExp(filter = function getDependentCref(map = map, pseudo = pseudo), acc = acc));
      else exp;
    end match;
  end getUnsolvableExpCrefs;

  function getDependentCrefIndices
    "[Adjacency.MatrixType.SCALAR] All equations.
    Turns cref dependencies into index lists, used for adjacency."
    input list<ComponentRef> dependencies         "dependent var crefs";
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    output list<Integer> indices = {};
  algorithm
    for cref in dependencies loop
      indices := UnorderedMap.getSafe(cref, map, sourceInfo()) :: indices;
    end for;
    // remove duplicates and sort
    indices := List.sort(List.unique(indices), intLt);
  end getDependentCrefIndices;

  function getDependentCrefIndicesPseudoScalar
    "[Adjacency.MatrixType.PSEUDO] Scalar equations.
    Turns cref dependencies into index lists, used for adjacency."
    input list<ComponentRef> dependencies         "dependent var crefs";
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input Mapping mapping                         "array <-> scalar index mapping";
    output list<Integer> indices = {};
  protected
    ComponentRef stripped;
    Integer var_arr_idx, var_start, var_scal_idx;
    list<Integer> sizes, subs;
  algorithm
    for cref in dependencies loop
      stripped := ComponentRef.stripSubscriptsAll(cref);
      var_arr_idx := UnorderedMap.getSafe(stripped, map, sourceInfo());
      (var_start, _) := mapping.var_AtS[var_arr_idx];
      sizes := ComponentRef.sizes(stripped);
      subs := ComponentRef.subscriptsToInteger(cref);
      var_scal_idx := locationToIndex(List.zip(sizes, subs), var_start);
      indices := var_scal_idx :: indices;
    end for;
    // remove duplicates and sort
    indices := List.sort(List.unique(indices), intLt);
  end getDependentCrefIndicesPseudoScalar;

  function getDependentCrefIndicesPseudoArray
    "[Adjacency.MatrixType.PSEUDO] Array equations.
    Turns cref dependencies into index lists, used for adjacency."
    input list<ComponentRef> dependencies                   "dependent var crefs";
    input UnorderedMap<ComponentRef, Integer> map           "unordered map to check for relevance";
    input Mapping mapping                                   "array <-> scalar index mapping";
    input Integer eqn_arr_idx;
    output array<list<Integer>> indices;
    output array<array<Integer>> mode_to_var;
  protected
    ComponentRef stripped;
    Integer eqn_start, eqn_size, var_arr_idx, var_scal_idx, mode = 1;
    list<Integer> scal_lst;
    Integer idx;
    array<Integer> mode_to_var_row;
  algorithm
    (eqn_start, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
    indices := arrayCreate(eqn_size, {});
    mode_to_var := arrayCreate(eqn_size, arrayCreate(0,0));
    // create unique array for each equation
    for i in 1:eqn_size loop
      mode_to_var[i] := arrayCreate(listLength(dependencies),-1);
    end for;
    for cref in dependencies loop
      stripped := ComponentRef.stripSubscriptsAll(cref);
      var_arr_idx := UnorderedMap.getSafe(stripped, map, sourceInfo());
      // build range in reverse, it will be flipped anyway
      scal_lst := Mapping.getVarScalIndices(var_arr_idx, mapping, true);

      if intMod(eqn_size, listLength(scal_lst)) <> 0 then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
          + " failed because flattened indices " + intString(listLength(scal_lst))
          + " could not be repeated to fit equation size " + intString(eqn_size) + ". lst: " + List.toString(scal_lst, intString)});
        fail();
      else
        // fill the equation with repeated scalar lists
        scal_lst := List.repeat(scal_lst, realInt(eqn_size/listLength(scal_lst)));
      end if;

      idx := 1;
      for var_scal_idx in listReverse(scal_lst) loop
        mode_to_var_row := mode_to_var[idx];
        arrayUpdate(mode_to_var_row, mode, var_scal_idx);
        arrayUpdate(mode_to_var, idx, mode_to_var_row);
        indices[idx] := var_scal_idx :: indices[idx];
        idx := idx + 1;
      end for;
      mode := mode + 1;
    end for;

    // sort
    for i in 1:arrayLength(indices) loop
      indices[i] := List.sort(List.unique(indices[i]), intLt);
    end for;
  end getDependentCrefIndicesPseudoArray;

  function getDependentCrefIndicesPseudoFor
    "[Adjacency.MatrixType.PSEUDO] For-Loop equations.
    Turns cref dependencies into index lists, used for adjacency."
    input list<ComponentRef> dependencies                   "dependent var crefs";
    input UnorderedMap<ComponentRef, Integer> map           "unordered map to check for relevance";
    input Mapping mapping                                   "array <-> scalar index mapping";
    input Iterator iter                                     "iterator frames";
    input Integer eqn_arr_idx;
    output array<list<Integer>> indices;
    output array<array<Integer>> mode_to_var;
  protected
    list<ComponentRef> names;
    list<Expression> ranges, subs;
    list<tuple<ComponentRef, Expression>> frames;
    ComponentRef stripped;
    Integer eqn_start, eqn_size, var_arr_idx, var_start, var_scal_idx, mode = 1;
    list<Integer> scal_lst, sizes;
    Integer idx;
    array<Integer> mode_to_var_row;
  algorithm
    // get iterator frames
    (names, ranges) := Iterator.getFrames(iter);
    frames := List.zip(names, ranges);

    (eqn_start, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
    indices := arrayCreate(eqn_size, {});
    mode_to_var := arrayCreate(eqn_size, arrayCreate(0,0));

    // create unique array for each equation
    for i in 1:eqn_size loop
      mode_to_var[i] := arrayCreate(listLength(dependencies),-1);
    end for;
    for cref in dependencies loop
      stripped        := ComponentRef.stripSubscriptsAll(cref);
      var_arr_idx     := UnorderedMap.getSafe(stripped, map, sourceInfo());
      (var_start, _)  := mapping.var_AtS[var_arr_idx];
      sizes           := ComponentRef.sizes(stripped);
      subs            := ComponentRef.subscriptsToExpression(cref);
      scal_lst        := combineFrames2Indices(var_start, sizes, subs, frames, UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual));

      if listLength(scal_lst) <> eqn_size then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
          + " failed because number of flattened indices " + intString(listLength(scal_lst))
          + " differ from equation size " + intString(eqn_size) + "."});
        fail();
      end if;

      idx := 1;
      for var_scal_idx in listReverse(scal_lst) loop
        mode_to_var_row := mode_to_var[idx];
        mode_to_var_row[mode] := var_scal_idx;
        arrayUpdate(mode_to_var_row, mode, var_scal_idx);
        indices[idx] := var_scal_idx :: indices[idx];
        idx := idx + 1;
      end for;
      mode := mode + 1;
    end for;

    // sort
    for i in 1:arrayLength(indices) loop
      indices[i] := List.sort(List.unique(indices[i]), intLt);
    end for;
  end getDependentCrefIndicesPseudoFor;

  function getDependentCrefsPseudoForCausalized
    "[Adjacency.MatrixType.PSEUDO] For-Loop equations.
    Turns cref dependencies into index lists, used for adjacency."
    input ComponentRef row_cref                                   "cref representing the current row";
    input list<ComponentRef> dependencies                         "dependent var crefs";
    input UnorderedMap<ComponentRef, list<ComponentRef>> map      "hash table to check for relevance";
    input Iterator iter                                           "iterator frames";
    input list<Integer> slice = {}                                "optional slice, empty least means all";
    output list<tuple<ComponentRef, list<ComponentRef>>> tpl_lst  "cref -> dependencies for each scalar cref";
  protected
    ComponentRef stripped;
    list<ComponentRef> names;
    list<Expression> ranges, subs;
    list<list<Expression>> new_subs, new_row_cref_subs;
    list<Subscript> evaluated_subs;
    list<tuple<ComponentRef, Expression>> frames;
    list<ComponentRef> new_row_crefs = {}, new_dep_crefs;
    list<list<ComponentRef>> scalar_dependenciesT = {};
  algorithm
    // get iterator frames
    (names, ranges) := Iterator.getFrames(iter);
    frames := List.zip(names, ranges);

    // get new subscripts for row cref
    subs := ComponentRef.subscriptsToExpression(row_cref);
    new_row_cref_subs := combineFrames2Exp(subs, frames, UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual));
    new_row_cref_subs := if not listEmpty(slice) then List.keepPositions(new_row_cref_subs, slice) else new_row_cref_subs;

    // reapply new subscripts for each frame location
    stripped := ComponentRef.stripSubscriptsAll(row_cref);
    for new_subs_single in new_row_cref_subs loop
      evaluated_subs := list(Subscript.fromTypedExp(exp) for exp in new_subs_single);
      new_row_crefs := ComponentRef.mergeSubscripts(evaluated_subs, stripped, false, true) :: new_row_crefs;
    end for;

    // get the scalar crefs for each column cref
    if not listEmpty(dependencies) then
      for cref in dependencies loop
        subs := ComponentRef.subscriptsToExpression(cref);
        new_subs := combineFrames2Exp(subs, frames, UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual));
        new_subs := if not listEmpty(slice) then List.keepPositions(new_subs, slice) else new_row_cref_subs;

        if listLength(new_subs) <> listLength(new_row_crefs) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because number of flattened indices " + intString(listLength(new_subs))
            + " differ from equation size " + intString(listLength(new_row_cref_subs)) + "."});
          fail();
        end if;

        // apply all subscript lists for scalarization to create scalar crefs
        new_dep_crefs := {};
        stripped := ComponentRef.stripSubscriptsAll(cref);
        for new_subs_single in new_subs loop
          evaluated_subs := list(Subscript.fromTypedExp(exp) for exp in new_subs_single);
          new_dep_crefs := ComponentRef.mergeSubscripts(evaluated_subs, stripped, false, true) :: new_dep_crefs;
        end for;
        scalar_dependenciesT := new_dep_crefs :: scalar_dependenciesT;
      end for;

      // transpose scalar_dependenciesT and merge with new_row_crefs
      tpl_lst := List.zip(new_row_crefs, List.transposeList(scalar_dependenciesT));
    else
      tpl_lst := list((new_row_cref, {}) for new_row_cref in new_row_crefs);
    end if;

  end getDependentCrefsPseudoForCausalized;

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
    "Squashing all equal inertia frames (nested loops) into one.
    Equal inertia for frames shows that they 'fire' at the same time.
    These frames have to change in one step, therefore they should be merged to
    a single one."
    input list<tuple<Integer, FrameLocation>> frame_inertia_lst;
    input UnorderedMap<ComponentRef, Expression> replacements;
    output list<tuple<Integer, FrameLocation>> resolved = {};
    output FrameOrderingStatus status = NBEquation.FrameOrderingStatus.UNCHANGED;
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
            status := NBEquation.FrameOrderingStatus.FAILURE;
          elseif arrayLength(loc1) == 1 then
            b := loc2[1] - loc1[1];
            linMap := Expression.fromCref(name1);
            if b <> 0 then
              linMap := Expression.MULTARY({Expression.INTEGER(b), linMap}, {}, addOp);
            end if;
            UnorderedMap.add(name2, linMap, replacements);
            status := NBEquation.FrameOrderingStatus.CHANGED;
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
                status := NBEquation.FrameOrderingStatus.FAILURE;
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
            status := NBEquation.FrameOrderingStatus.CHANGED;
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
        frames := applyNewFrameRange(frame, (dim[1], 1, dim[1])) :: frames;
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
          // use max/min dim instead of start and stop because the start or end
          // could be missing (missing diagonals)
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
      if fos == NBEquation.FrameOrderingStatus.CHANGED then
        removed_diagonal := SOME(replacements);
        status := NBEquation.RecollectStatus.SUCCESS;
      else
        // no equal inertia to resolve or unable to resolve
        status := NBEquation.RecollectStatus.FAILURE;
      end if;
    else
      status := NBEquation.RecollectStatus.SUCCESS;
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

  // ############################################################
  //                Protected Functions
  // ############################################################

protected
  function combineFrames2Exp
    "Iterates over all elements in nested iterators represented by frames.
    On each single location of a frame it saves all iterator cref -> integer
    replacements in a map and applies these replacements on the subscripts."
    input list<Expression> subs                               "list of cref subscripts";
    input list<tuple<ComponentRef, Expression>> frames        "list of frame tuples containing iterator name and range";
    input UnorderedMap<ComponentRef, Expression> replacements "replacement rules iterator cref -> integer (may have to be simplified)";
    input output list<list<Expression>> new_subs = {}               "list of replaced subscript expressions";
  algorithm
    new_subs := match frames
      local
        list<tuple<ComponentRef, Expression>> rest;
        ComponentRef iterator;
        Expression range;
        Integer start, step, stop;
        list<Expression> local_subs;

      // only occurs for non-for-loop equations (no frames to replace)
      case {} then {subs};

      // extract numeric information about the range
      case (iterator, range) :: rest algorithm
        (start, step, stop) := Expression.getIntegerRange(range);
        // traverse every index in the range
        for index in start:step:stop loop
          UnorderedMap.add(iterator, Expression.INTEGER(index), replacements);
          if listEmpty(rest) then
            // bottom line, resolve current configuration and create index for it
            local_subs := list(SimplifyExp.simplify(Expression.map(sub, function Replacements.applySimpleExp(replacements = replacements))) for sub in subs);
            new_subs := listReverse(local_subs) :: new_subs;
          else
            // not last frame, go deeper
            new_subs := combineFrames2Exp(subs, rest, replacements, new_subs);
          end if;
        end for;
      then new_subs;

      case (iterator, range) :: _ algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because uniontype records are wrong: "
          + ComponentRef.toString(iterator) + " in " + Expression.toString(range)});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
      then fail();

    end match;
  end combineFrames2Exp;

  function combineFrames2Indices
    "Does the same es combineFrames2Exp but converts each of the now integer
    subscript lists (in combination with subscript sizes) to a single scalar
    index of the subscripted cref."
    input Integer first                                       "index of first variable. start counting from here";
    input list<Integer> sizes                                 "list of variables sizes";
    input list<Expression> subs                               "list of cref subscripts";
    input list<tuple<ComponentRef, Expression>> frames        "list of frame tuples containing iterator name and range";
    input UnorderedMap<ComponentRef, Expression> replacements "replacement rules iterator cref -> integer (may have to be simplified)";
    input output list<Integer> indices = {}                   "list of scalarized indices";
  algorithm
    indices := match frames
      local
        list<tuple<ComponentRef, Expression>> rest;
        ComponentRef iterator;
        Expression range;
        Integer start, step, stop;
        list<tuple<Integer, Integer>> ranges;

      // only occurs for non-for-loop equations (no frames to replace)
      case {} then {first};

      // extract numeric information about the range
      case (iterator, range) :: rest algorithm
        (start, step, stop) := Expression.getIntegerRange(range);
        // traverse every index in the range
        for index in start:step:stop loop
          UnorderedMap.add(iterator, Expression.INTEGER(index), replacements);
          if listEmpty(rest) then
            // bottom line, resolve current configuration and create index for it
            ranges  := resolveDimensionsSubscripts(sizes, subs, replacements);
            indices := locationToIndex(ranges, first) :: indices;
          else
            // not last frame, go deeper
            indices := combineFrames2Indices(first, sizes, subs, rest, replacements, indices);
          end if;
        end for;
      then indices;

      case (iterator, range) :: _ algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because uniontype records are wrong: "
          + ComponentRef.toString(iterator) + " in " + Expression.toString(range)});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
      then fail();

    end match;
  end combineFrames2Indices;

  function resolveDimensionsSubscripts
    "uses the replacement module to replace all iterator crefs in the subscript with the current position.
    Returns a list of tuples containing the size of each subscript and current position."
    input list<Integer> sizes                                     "dimension sizes";
    input list<Expression> subs                                   "subscript expressions";
    input UnorderedMap<ComponentRef, Expression> replacements     "replacement map for iterator crefs";
    output list<tuple<Integer, Integer>> ranges                   "tuple pairs (size, pos)";
  protected
    list<Expression> replaced;
    list<Integer> values;
  algorithm
    replaced := list(Expression.map(sub, function Replacements.applySimpleExp(replacements = replacements)) for sub in subs);
    values := list(Expression.integerValue(SimplifyExp.simplify(rep)) for rep in replaced);
    ranges := List.zip(sizes, values);
  end resolveDimensionsSubscripts;

  function applyNewFrameRange
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

  annotation(__OpenModelica_Interface="backend");
end NBSlice;
