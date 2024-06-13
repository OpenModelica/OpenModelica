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
" file:         NBSlice.mo
  package:      NBSlice
  description:  This file contains util functions for slicing operations.
"

protected
  import Slice = NBSlice;

  // NF imports
  import ComplexType = NFComplexType;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // NB imports
  import NBAdjacency.{Mapping, Mode, CausalizeModes, Dependency};
  import BackendUtil = NBBackendUtil;
  import NBEquation.{Equation, Iterator, Frame, FrameLocation, RecollectStatus, FrameOrderingStatus};
  import Replacements = NBReplacements;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

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
    if maxLength > 0 then
      str := str + "\n\t slice: " + List.toString(inList = slice.indices, inPrintFunc = intString, maxLength = 10);
    end if;
  end toString;

  function lstToString
    input list<Slice<T>> lst;
    input toStringT_ func;
    input Integer maxLength = 10;
    partial function toStringT_ = toStringT "ugly hack to make type T known to subfunction";
    output String str = List.toString(lst, function toString(func = func, maxLength = maxLength), "", "\t", ";\n\t", ";", false);
  end lstToString;

  function isFull
    input Slice<T> slice;
    output Boolean b = listEmpty(slice.indices);
  end isFull;

  function size
    input Slice<T> slice;
    input sizeT func;
    output Integer s;
  algorithm
    if listEmpty(slice.indices) then
      s := func(slice.t);
    else
      s := listLength(slice.indices);
    end if;
  end size;

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
    UnorderedMap.add(t, i :: UnorderedMap.getOrDefault(t, map, {}), map);
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

  partial function filterCref
    "partial function that needs to be provided.
    decides if the the cref is added to the list pointer."
    input output ComponentRef cref;
    input UnorderedSet<ComponentRef> acc;
  end filterCref;

  partial function getDependentCrefIndices
    input list<ComponentRef> dependencies                   "dependent var crefs";
    input UnorderedMap<ComponentRef, Integer> map           "unordered map to check for relevance";
    input Mapping mapping                                   "array <-> scalar index mapping";
    input Integer eqn_arr_idx;
    output array<list<Integer>> indices;
    output array<array<Integer>> mode_to_var;
  end getDependentCrefIndices;

  // ############################################################
  //                cref accumulation Functions
  // use with:
  //    Equation.collectCrefs()
  //    filterExp()
  // ############################################################

  function filterExp
    "wrapper function that applies filter cref to
    a cref expression."
    input output Expression exp;
    input filterCref filter;
    input UnorderedSet<ComponentRef> acc;
  algorithm
    () := match exp
      case Expression.CREF() algorithm filter(exp.cref, acc); then ();
      else ();
    end match;
  end filterExp;

  function getSliceCandidates
    "Used to collect all slices of a certain variable name.
    Note: the name has to be stripped of all subscripts for this to work."
  extends filterCref;
    input ComponentRef name "the name of the variable";
  algorithm
    if ComponentRef.isEqual(name, ComponentRef.stripSubscriptsAll(cref)) then
      UnorderedSet.add(cref, acc);
    end if;
  end getSliceCandidates;

  function getDependentCref
    "checks if crefs are relevant in the given context and collects them."
  extends filterCref;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input Boolean pseudo;
  protected
    ComponentRef checkCref, childCref;
    list<Pointer<Variable>> record_children;
  algorithm
    // if causalized in pseudo array mode, the variables will only have subscript-free variables
    checkCref := if pseudo then ComponentRef.stripSubscriptsAll(cref) else cref;
    record_children := BVariable.getRecordChildren(BVariable.getVarPointer(checkCref));
    if listEmpty(record_children) then
      // not a record
      if UnorderedMap.contains(checkCref, map) then
        UnorderedSet.add(cref, acc);
      end if;
    else
      // its a record, instead parse all the children
      for child in record_children loop
        childCref := BVariable.getVarName(child);
        if UnorderedMap.contains(childCref, map) then
          UnorderedSet.add(childCref, acc);
        end if;
      end for;
    end if;
  end getDependentCref;

  function getDependentCrefCausalized
    "checks if crefs are relevant in the given context and collects them.
    previously found crefs are replaced by their dependencies! only works on causalized systems."
  extends filterCref;
    input UnorderedSet<ComponentRef> set "unordered set to check for array crefs for relevance";
  protected
    ComponentRef checkCref, childCref;
    list<Pointer<Variable>> record_children;
  algorithm
    // always remove subscripts here, this analysis is for sparsity pattern -> currently always scalarized!
    checkCref := ComponentRef.stripSubscriptsAll(cref);
    record_children := BVariable.getRecordChildren(BVariable.getVarPointer(checkCref));
    if listEmpty(record_children) then
      // not a record
      if UnorderedSet.contains(checkCref, set) then
        UnorderedSet.add(cref, acc);
      end if;
    else
      // its a record, instead parse all the children
      for child in record_children loop
        childCref := BVariable.getVarName(child);
        if UnorderedSet.contains(childCref, set) then
          UnorderedSet.add(childCref, acc);
        end if;
      end for;
    end if;
  end getDependentCrefCausalized;

  function getUnsolvableExpCrefs
    "finds all unsolvable crefs in an expression."
    input output Expression exp                   "the exp to check for unsolvable crefs";
    input UnorderedSet<ComponentRef> acc          "accumulator for relevant crefs";
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input Boolean pseudo;
  algorithm
    // put all unsolvable logic here!
    exp := match exp
      case Expression.RANGE()     then Expression.map(exp, function filterExp(filter = function getDependentCref(map = map, pseudo = pseudo), acc = acc));
      case Expression.LBINARY()   then Expression.map(exp, function filterExp(filter = function getDependentCref(map = map, pseudo = pseudo), acc = acc));
      case Expression.RELATION()  then Expression.map(exp, function filterExp(filter = function getDependentCref(map = map, pseudo = pseudo), acc = acc));
      else exp;
    end match;
  end getUnsolvableExpCrefs;

  function getDependentCrefIndicesPseudoScalar
    "Scalar equations.
    Turns cref dependencies into index lists, used for adjacency."
    input list<ComponentRef> dependencies         "dependent var crefs";
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input Mapping mapping                         "array <-> scalar index mapping";
    output list<Integer> indices = {};
  protected
    list<ComponentRef> scalarized_dependencies = List.flatten(list(ComponentRef.scalarizeAll(dep) for dep in dependencies));
    ComponentRef stripped;
    Integer var_arr_idx, var_start, var_scal_idx;
    list<Integer> sizes, int_subs;
  algorithm
    for cref in scalarized_dependencies loop
      stripped := ComponentRef.stripSubscriptsAll(cref);
      var_arr_idx := UnorderedMap.getSafe(stripped, map, sourceInfo());
      (var_start, _) := mapping.var_AtS[var_arr_idx];
      sizes := ComponentRef.sizes(stripped);
      int_subs := ComponentRef.subscriptsToInteger(cref);
      var_scal_idx := locationToIndex(List.zip(sizes, int_subs), var_start);
      indices := var_scal_idx :: indices;
    end for;
    // remove duplicates and sort
    if not listEmpty(indices) then
      indices := List.sort(List.uniqueIntN(indices, max(i for i in indices)), intLt);
    end if;
  end getDependentCrefIndicesPseudoScalar;

  function getDependentCrefIndicesPseudoFull
    "equations that will get full dependency.
    Turns cref dependencies into index lists, used for adjacency."
    extends getDependentCrefIndices;
  protected
    list<ComponentRef> scalarized_dependencies = List.flatten(list(ComponentRef.scalarizeAll(dep) for dep in dependencies));
    ComponentRef stripped;
    Integer eqn_start, eqn_size, var_arr_idx, var_scal_idx, mode = 1;
    list<Integer> scal_lst;
    Integer idx;
    array<Integer> mode_to_var_row;
    list<Subscript> subs;
    list<Dimension> dims;
    Type ty;
  algorithm
    (eqn_start, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
    indices := arrayCreate(eqn_size, {});
    mode_to_var := arrayCreate(eqn_size, arrayCreate(0,0));
    // create unique array for each equation
    for i in 1:eqn_size loop
      mode_to_var[i] := arrayCreate(listLength(scalarized_dependencies),-1);
    end for;
    for cref in scalarized_dependencies loop
      stripped := ComponentRef.stripSubscriptsAll(cref);
      var_arr_idx := UnorderedMap.getSafe(stripped, map, sourceInfo());

      // build range in reverse, it will be flipped anyway
      subs := ComponentRef.subscriptsAllWithWholeFlat(cref);
      ty := ComponentRef.getSubscriptedType(stripped, true);
      dims := Type.arrayDims(ty);
      scal_lst := Mapping.getVarScalIndices(var_arr_idx, mapping, subs, dims, true);

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
      indices[i] := List.sort(UnorderedSet.unique_list(indices[i], Util.id, intEq), intLt);
    end for;
  end getDependentCrefIndicesPseudoFull;

  function getDependentCrefIndicesPseudoFor
    "For-Loop equations.
    Turns cref dependencies into index lists, used for adjacency."
    extends getDependentCrefIndices;
    input Iterator iter                                     "iterator frames";
  protected
    list<ComponentRef> names;
    list<Expression> ranges;
    list<tuple<ComponentRef, Expression>> frames;
    Integer eqn_size, iter_size, body_size, mode = 1;
    updateDependencies func;
  algorithm
    // get iterator size and frames
    iter_size := Iterator.size(iter);
    (names, ranges) := Iterator.getFrames(iter);
    frames := List.zip(names, ranges);

    // get eqn size and create the adjacency matrix and causalization mode arrays
    (_, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
    indices := arrayCreate(eqn_size, {});
    mode_to_var := arrayCreate(eqn_size, arrayCreate(0,0));

    // sanity check for eqn size and get size of body equation
    if mod(eqn_size, iter_size) == 0 then
      body_size := realInt(eqn_size/iter_size);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
        + " failed because the equation size " + intString(eqn_size)
        + " could not be divided by the iterator size " + intString(iter_size) + " without rest."});
    end if;

    // create unique array for each equation
    for i in 1:eqn_size loop
      mode_to_var[i] := arrayCreate(listLength(dependencies),-1);
    end for;

    // create rows
    for dep in dependencies loop
      func := function updateDependenciesInteger(mode = mode, mode_to_var = mode_to_var, indices = indices);
      fillDependencyArray(dep, body_size, frames, mapping, map, func);
      // increase mode index
      mode := mode + 1;
    end for;

    // sort (kabdelhak: is this needed? try to FixMe)
    for i in 1:arrayLength(indices) loop
      indices[i] := List.sort(UnorderedSet.unique_list(indices[i], Util.id, intEq), intLt);
    end for;
  end getDependentCrefIndicesPseudoFor;

  function getDependentCrefsPseudoForCausalized
    "(Jacobian) For-Loop equations.
    Turns cref dependencies into index lists, used for adjacency."
    input ComponentRef row_cref                                   "cref representing the current row";
    input list<ComponentRef> dependencies                         "dependent var crefs";
    input VariablePointers var_rep                                "scalarized variable representatives";
    input VariablePointers eqn_rep                                "scalarized equation representatives";
    input Mapping var_rep_mapping                                 "index mapping for variable representatives";
    input Mapping eqn_rep_mapping                                 "index mapping for equation representatives";
    input Iterator iter                                           "iterator frames";
    input Integer eqn_size                                        "full equation size (not considering the slice)";
    input list<Integer> slice = {}                                "optional slice, empty list implies full slice";
    input Boolean implicit = false                                "do not compute row cref indices if implicit";
    output list<tuple<ComponentRef, list<ComponentRef>>> tpl_lst  "cref -> dependencies for each scalar cref";
  protected
    list<ComponentRef> names;
    list<Expression> ranges;
    list<tuple<ComponentRef, Expression>> frames;

    Integer num_rows, iter_size, body_size;
    list<ComponentRef> row_crefs;
    list<Integer> row_scal_lst;
    list<list<Integer>> accum_row_lst = {};
    array<list<ComponentRef>> accum_dep_arr;
    list<list<ComponentRef>> accum_dep_lst;
    updateDependencies func_var, func_eqn;
  algorithm
    // create the array of maximum equation size and slice afterwards
    accum_dep_arr := arrayCreate(eqn_size, {});

    // get iterator size and frames
    iter_size := Iterator.size(iter);
    (names, ranges) := Iterator.getFrames(iter);
    frames := List.zip(names, ranges);

    // sanity check for eqn size and get size of body equation
    if mod(eqn_size, iter_size) == 0 then
      body_size := realInt(eqn_size/iter_size);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
        + " failed because the equation size " + intString(eqn_size)
        + " could not be divided by the iterator size " + intString(iter_size) + " without rest."});
    end if;

    // get row cref lst
    if implicit then
      row_crefs := ComponentRef.scalarizeAll(row_cref);
    else
      for cref in ComponentRef.scalarizeAll(row_cref) loop
        row_scal_lst  := getCrefInFrameIndices(cref, frames, eqn_rep_mapping, eqn_rep.map);
        accum_row_lst := row_scal_lst :: accum_row_lst;
      end for;
      row_scal_lst  := List.flatten(accum_row_lst);
      row_crefs     := list(VariablePointers.varSlice(eqn_rep, i, eqn_rep_mapping) for i in row_scal_lst);
    end if;
    row_crefs := if listEmpty(slice) then row_crefs else List.getAtIndexLst(row_crefs, slice, true);
    num_rows := listLength(row_crefs);

    // prepare the functions to update dependencies
    func_var := function updateDependenciesCref(accum_dep_arr = accum_dep_arr, vars = var_rep, mapping = var_rep_mapping);
    func_eqn := function updateDependenciesCref(accum_dep_arr = accum_dep_arr, vars = eqn_rep, mapping = eqn_rep_mapping);

    for dep in dependencies loop
      if UnorderedMap.contains(dep, var_rep.map) then
        fillDependencyArray(dep, body_size, frames, var_rep_mapping, var_rep.map, func_var);
      elseif UnorderedMap.contains(dep, eqn_rep.map) then
        fillDependencyArray(dep, body_size, frames, eqn_rep_mapping, eqn_rep.map, func_eqn);
      end if;
    end for;

    accum_dep_lst := listReverse(arrayList(accum_dep_arr));
    accum_dep_lst := if listEmpty(slice) then accum_dep_lst else List.getAtIndexLst(accum_dep_lst, slice, true);

    tpl_lst := List.zip(row_crefs, accum_dep_lst);
  end getDependentCrefsPseudoForCausalized;

  function fillDependencyArray
    "body function of getDependentCrefsPseudoFor and getDependentCrefsPseudoForCausalized
    this generates all entries to jacobian or adjacency matrices for a specific dependency.
    This dependency might be an array cref, part of a reduction or contain slices."
    input ComponentRef dep;
    input Integer body_size;
    input list<tuple<ComponentRef, Expression>> frames;
    input Mapping mapping;
    input UnorderedMap<ComponentRef, Integer> map;
    input updateDependencies func;
  protected
    Integer scal_length, body_repeat, eqn_idx;
    list<Integer> scal_lst;
    list<tuple<ComponentRef, list<Integer>>> scal_tpl_lst = {};
  algorithm
    // get all dependencies for each scalarized cref
    // Note: scalarization does not remove the iterators, therefore it can still yield
    //   multiple scalar indices when evaluated along the iterator frames
    for scal_cref in ComponentRef.scalarizeAll(dep) loop
      scal_lst := getCrefInFrameIndices(scal_cref, frames, mapping, map);
      scal_tpl_lst := (scal_cref, scal_lst) :: scal_tpl_lst;
    end for;

    // check wether or not the element has to be repeated to fit the body
    scal_length := listLength(scal_tpl_lst);
    if mod(scal_length, body_size) == 0 then
      body_repeat := realInt(scal_length/body_size);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
        + " failed because number of flattened indices " + intString(scal_length)
        + " for dependency " + ComponentRef.toString(dep)
        + " could not be divided by the body size " + intString(body_size) + " without rest."});
      fail();
    end if;

    eqn_idx := 1;
    for tpl in scal_tpl_lst loop
      (_, scal_lst) := tpl;

      // reverse the scalar index list to traverse it in the correct order
      scal_lst := listReverse(scal_lst);

      // check if body_repeat > 1 to set the causalization mode to -1 for unsolvable
      if body_repeat > 1 then
        // reset the counter to 1 if the body is supposed to be repeated
        // ToDo: reductions are only tested for body equations of size 1!
        eqn_idx := 1;
      end if;

      for var_idx in scal_lst loop
        // we now know that there is a dependency of equation (eqn_idx) to variable (var_idx)
        // call the function that adds this specific variable to the correct structure
        eqn_idx := func(eqn_idx, var_idx);
      end for;
    end for;
  end fillDependencyArray;

  partial function updateDependencies
    input output Integer eqn_idx;
    input Integer var_idx;
  end updateDependencies;

  function updateDependenciesCref
    "(jacobian) adds the variable of (var_idx) as a dependency to (eqn_idx)
    jacobian depencies are stored as component references"
    extends updateDependencies;
    input array<list<ComponentRef>> accum_dep_arr; //mutable
    input VariablePointers vars;
    input Mapping mapping;
  algorithm
    arrayUpdate(accum_dep_arr, eqn_idx, VariablePointers.varSlice(vars, var_idx, mapping) :: accum_dep_arr[eqn_idx]);
    eqn_idx := eqn_idx + 1;
  end updateDependenciesCref;

  function updateDependenciesInteger
    "(adjacency) adds the variable of (var_idx) as a dependency to (eqn_idx)
    adjacency dependencies are stored as integers
    also updates the causalization modes"
    extends updateDependencies;
    input Integer mode;
    input array<array<Integer>> mode_to_var;  //mutable
    input array<list<Integer>> indices;       //mutable
  protected
    array<Integer> mode_to_var_row;
  algorithm
    // get the clean pointer to the scalar row to avoid double indexing (meta modelica jank)
    mode_to_var_row := mode_to_var[eqn_idx];
    // set the dependency mode for this scalar equation to the scalar variable
    arrayUpdate(mode_to_var_row, mode, var_idx);
    // this is the adjacency matrix row. each dependency cref
    // will add exactly one integer to each row belonging to this for-equation
    arrayUpdate(indices, eqn_idx, var_idx :: indices[eqn_idx]);
    eqn_idx := eqn_idx + 1;
  end updateDependenciesInteger;

  function getDependentCrefsPseudoArrayCausalized
    "Array equations.
    Turns cref dependencies into index lists, used for adjacency."
    input ComponentRef row_cref                                   "cref representing the current row";
    input list<ComponentRef> dependencies                         "dependent var crefs";
    input list<Integer> slice = {}                                "optional slice, empty least means all";
    output list<tuple<ComponentRef, list<ComponentRef>>> tpl_lst  "cref -> dependencies for each scalar cref";
  protected
    list<ComponentRef> row_cref_scal, dep_scal;
    list<list<ComponentRef>> dependencies_scal = {};
    Boolean sliced = not listEmpty(slice);
  algorithm
    row_cref_scal := ComponentRef.scalarizeAll(row_cref);
    if sliced then
      row_cref_scal := List.getAtIndexLst(row_cref_scal, slice, true);
    end if;
    for dep in listReverse(dependencies) loop
      dep_scal := ComponentRef.scalarizeAll(dep);
      if sliced then
        dep_scal := List.getAtIndexLst(dep_scal, slice, true);
      end if;
      dependencies_scal := dep_scal :: dependencies_scal;
    end for;
    dependencies_scal := List.transposeList(dependencies_scal);
    tpl_lst := List.zip(row_cref_scal, dependencies_scal);
  end getDependentCrefsPseudoArrayCausalized;

  function locationToIndex
    "reverse function to indexToLocation()
    maps a frame location to a scalar index starting from first index (one based!)"
    input list<tuple<Integer,Integer>> size_val_tpl_lst;
    input output Integer index;
  protected
    Integer size, val, factor = 1;
  algorithm
    for tpl in size_val_tpl_lst loop
      (size, val) := tpl;
      index := index + (val-1) * factor;
      factor := factor * size;
    end for;
  end locationToIndex;

  function indexToLocation
    "reverse function to locationToIndex()
    maps a scalar index to its frame location (zero based!)"
    input Integer index;
    input list<Integer> sizes;
    output list<Integer> vals = {};
  protected
    Integer iterator = index;
    Integer divisor = product(s for s in sizes);
  algorithm
    for size in sizes loop
      divisor   := intDiv(divisor, size);
      vals      := intDiv(iterator, divisor) :: vals;
      iterator  := mod(iterator, divisor);
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

  // #### KAB ### new adjacency util
  function upgradeRowFull
    "Scalar equations.
    Turns cref dependencies into index lists, used for adjacency."
    input list<ComponentRef> dependencies         "dependent var crefs";
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input Mapping mapping                         "array <-> scalar index mapping";
    output list<Integer> indices = {};
  protected
    list<ComponentRef> scalarized_dependencies = List.flatten(list(ComponentRef.scalarizeAll(dep) for dep in dependencies));
    ComponentRef stripped;
    Integer var_arr_idx, var_start, var_scal_idx;
    list<Integer> sizes, int_subs;
  algorithm
    for cref in scalarized_dependencies loop
      stripped := ComponentRef.stripSubscriptsAll(cref);
      var_arr_idx := UnorderedMap.getSafe(stripped, map, sourceInfo());
      (var_start, _) := mapping.var_AtS[var_arr_idx];
      sizes := ComponentRef.sizes(stripped);
      int_subs := ComponentRef.subscriptsToInteger(cref);
      var_scal_idx := locationToIndex(List.zip(sizes, int_subs), var_start);
      indices := var_scal_idx :: indices;
    end for;
  end upgradeRowFull;

  function upgradeRow
    "For-Loop equations.
    Turns cref dependencies into index lists, used for adjacency."
    input ComponentRef eqn_name;
    input Integer eqn_arr_idx;
    input Iterator iter                                     "iterator frames";
    input Type ty;
    input list<ComponentRef> dependencies                   "dependent var crefs";
    input UnorderedMap<ComponentRef, Dependency> dep        "dependency map";
    input UnorderedSet<ComponentRef> rep                    "repetition set";
    input UnorderedMap<ComponentRef, Integer> map           "unordered map to check for relevance";
    input array<list<Integer>> m;
    input Mapping mapping                                   "array <-> scalar index mapping";
    input UnorderedMap<Mode.Key, Mode> modes;
  algorithm
    for cref in dependencies loop
      resolveDependency(cref, eqn_name, eqn_arr_idx, iter, ty, dep, rep, map, m, mapping, modes);
    end for;
  end upgradeRow;

  // ############################################################
  //                Protected Functions
  // ############################################################

protected
  function resolveSkips
    input output Integer index;
    input output Type ty;
    input list<Integer> skips;
    input ComponentRef cref;
    input UnorderedMap<ComponentRef, Integer> map           "unordered map to check for relevance";
  algorithm
    (index, ty) := match (ty, skips)
      local
        Integer skip;
        list<Integer> rest, tail;
        Type sub_ty;
        list<Type> rest_ty;
        Pointer<Variable> parent;
        list<ComponentRef> crefs;
        ComponentRef field;

      // 0 skips are full dependencies
      case (Type.TUPLE(types = rest_ty), 0::rest) then (index, ty);

      // skip to a tuple element
      case (Type.TUPLE(types = rest_ty), skip::rest) guard(skip <= listLength(rest_ty)) algorithm
        // skip to the desired sub type and shift the starting index accordingly
        for i in 1:skip-1 loop
          sub_ty :: rest_ty := rest_ty;
          index := index + Type.sizeOf(sub_ty);
        end for;
        sub_ty :: rest_ty := rest_ty;
        // see if there is nested skips
      then resolveSkips(index, sub_ty, rest, cref, map);

      // skip to a record element
      case (Type.COMPLEX(complexTy = ComplexType.RECORD()), skip::rest) algorithm
        // get the children and skip to correct one
        field := match BVariable.getParent(BVariable.getVarPointer(cref))
          case SOME(parent) algorithm
            crefs :=  list(BVariable.getVarName(child) for child in BVariable.getRecordChildren(parent));
            crefs := list(c for c guard(UnorderedMap.contains(c, map)) in crefs);
            for i in 1:skip-1 loop
              field :: crefs := crefs;
              index := index + Type.sizeOf(ComponentRef.getSubscriptedType(field));
            end for;
            field :: crefs := crefs;
          then field;
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because skip of " + intString(skip)
              + " for type " + Type.toString(ty) + " is requested, but the cref is not part of a record:" + ComponentRef.toString(cref) + "."});
          then fail();
        end match;
        // see if there is nested skips
      then resolveSkips(index, ComponentRef.getSubscriptedType(field), rest, cref, map);

      // skip to an array element
      case (Type.ARRAY(), rest) guard(listLength(rest) >= listLength(ty.dimensions)) algorithm
        (rest, tail) := List.split(rest, listLength(ty.dimensions));
        index := locationToIndex(List.zip(list(Dimension.size(dim) for dim in ty.dimensions), rest), index);
      then resolveSkips(index, ty.elementType, tail, cref, map);

      // skip for tuple or array, but the skip is too large
      case (_, skip::_) guard(Type.isTuple(ty) or Type.isArray(ty)) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because skip of " + intString(skip)
          + " for type " + Type.toString(ty) + " is too large."});
      then fail();

      // there is no skip but there is a tuple (no-skip array is fine)
      case (Type.TUPLE(types = rest_ty), {}) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there is no skip for type "
          + Type.toString(ty)});
      then fail();

      // invalid skip
      case (_, skip::_) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because skip of " + intString(skip)
          + " for type " + Type.toString(ty) + " is invalid."});
      then fail();

      else (index, ty);
    end match;
  end resolveSkips;

  // intermediate types and functions for resolveDependency()
  type Key = list<Integer>;
  type Val1 = list<ComponentRef>;
  type Val2 = list<Integer>;

  function keyString
    input Key key;
    output String str = List.toString(key, intString);
  end keyString;

  function keyHash
    input Key key;
    output Integer hash = stringHashDjb2(keyString(key));
  end keyHash;

  function keyEqual
    input Key key1;
    input Key key2;
    output Boolean b = List.isEqualOnTrue(key1, key2, intEq);
  end keyEqual;

  function val1String
    input list<ComponentRef> val;
    output String str = List.toString(val, ComponentRef.toString);
  end val1String;

  function resolveDependency
    "resolves the dependency of a component reference in an equation.
    I.  Resolve skip dimensions (Tuples, Records, Array Constructors)
    II. Resolve regular vs. reduced dimensions"
    input ComponentRef cref;
    input ComponentRef eqn_name;
    input Integer eqn_arr_idx;
    input Iterator iter;
    input Type ty;
    input UnorderedMap<ComponentRef, Dependency> dep        "dependency map";
    input UnorderedSet<ComponentRef> rep                    "repetition set";
    input UnorderedMap<ComponentRef, Integer> map           "unordered map to check for relevance";
    input array<list<Integer>> m;
    input Mapping mapping                                   "array <-> scalar index mapping";
    input UnorderedMap<Mode.Key, Mode> modes;
  protected
    Dependency d;
    Type skip_ty;
    Integer skip_idx, start, size, body_size, iter_size, scal_size, shift = 0;
    list<ComponentRef> names;
    list<Expression> ranges;
    list<tuple<ComponentRef, Expression>> frames;
    list<Boolean> regulars;
    ComponentRef stripped;
    list<Subscript> subs;
    list<Dimension> dims, eq_dims;
    array<Integer> key;
    UnorderedMap<Key, Val1> map1;
    UnorderedMap<Key, Val2> map2;
    UnorderedMap<ComponentRef, Val2> map3;
    list<ComponentRef> scalarized;
    list<Integer> scal_lst;
    Boolean repeated;
    Mode mode;
  algorithm
    try
      // I. resolve the skips
      d                   := UnorderedMap.getSafe(cref, dep, sourceInfo());
      (start, _)          := mapping.eqn_AtS[eqn_arr_idx];
      if not UnorderedSet.contains(cref, rep) then
        (skip_idx, skip_ty) := resolveSkips(start, ty, d.skips, cref, map);
      else
        (skip_idx, skip_ty) := (start, ty);
      end if;

      // get equation and iterator sizes and frames
      body_size       := Type.sizeOf(skip_ty);
      iter_size       := Iterator.size(iter);
      size            := body_size * iter_size;
      (names, ranges) := Iterator.getFrames(iter);
      frames          := List.zip(names, ranges);

      // II. check for regular vs. reduced dimensions
      regulars := Dependency.toBoolean(d);
      if List.all(regulars, Util.id) then
        // II.1 all regular - single dependency per row.
        mode := Mode.create(eqn_name, {cref}, false);
        scalarized  := listReverse(ComponentRef.scalarizeAll(cref));
        map3        := UnorderedMap.new<Val2>(ComponentRef.hash, ComponentRef.isEqual);
        for scal in scalarized loop
          UnorderedMap.add(scal, getCrefInFrameIndices(scal, frames, mapping, map), map3);
        end for;
        scal_size   := listLength(List.flatten(UnorderedMap.valueList(map3)));
        // either the scalarized list has to be equal in length to the equation or it can be repeated enough times to fit
        if size == scal_size or (UnorderedSet.contains(cref, rep) and intMod(size, scal_size) == 0) then
          for i in 1:size/scal_size loop
            for scal in scalarized loop
              for scal_idx in UnorderedMap.getSafe(scal, map3, sourceInfo()) loop
                addMatrixEntry(m, modes, skip_idx + shift, scal_idx, mode);
                shift := shift + 1;
              end for;
            end for;
          end for;
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " (single dependency) failed because list of scalar variables("
          + intString(scal_size) + ") " + List.toString(scalarized, ComponentRef.toString)
          + ", does not fit the equation size " + intString(size) + ".\n"});
          fail();
        end if;

      elseif List.any(regulars, Util.id) then
        // II.2 mixed regularity - find all necessary configurations and add them to a map with a proper key
        // 1. get the cref subscripts and dimensions as well as the equation dimensions (they have to match in length)
        subs    := ComponentRef.subscriptsAllWithWholeFlat(cref);
        dims    := Type.arrayDims(ComponentRef.getSubscriptedType(cref));
        eq_dims := Type.arrayDims(ty);
        if listLength(subs) == listLength(dims) and listLength(subs) == listLength(regulars) and listLength(subs) == listLength(eq_dims) then
          // 2. create a map that maps a configuration key to the corresponding scalar crefs
          stripped  := ComponentRef.stripSubscriptsAll(cref);
          key       := arrayCreate(listLength(subs), 0);
          map1      := UnorderedMap.new<Val1>(keyHash, keyEqual);
          resolveReductions(List.zip3(subs, dims, regulars), map1, key, stripped);

          // 3. create a map that maps a configuration key to the final variable indices
          map2      := UnorderedMap.new<Val2>(keyHash, keyEqual);
          for k in UnorderedMap.keyList(map1) loop
            scalarized := UnorderedMap.getSafe(k, map1, sourceInfo());
            scal_lst := List.flatten(list(getCrefInFrameIndices(scal, frames, mapping, map) for scal in scalarized));
            UnorderedMap.add(k, scal_lst, map2);
          end for;

          // 4. iterate over all equation dimensions and use the map to get the correct dependencies
          key := arrayCreate(listLength(subs), 0);
          resolveEquationDimensions(List.zip(eq_dims, regulars), map2, key, m, modes, Mode.create(eqn_name, {cref}, false), Pointer.create(skip_idx));
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because subscripts, dimensions and dependencies were not of equal length.\n"
            + "variable subscripts(" + intString(listLength(subs)) + "): " + List.toString(subs, Subscript.toString) + "\n"
            + "variable dimensions(" + intString(listLength(dims)) + "): " + List.toString(dims, Dimension.toString) + "\n"
            + "equation dimensions(" + intString(listLength(eq_dims)) + "): " + List.toString(eq_dims, Dimension.toString) + "\n"
            + "variable dependencies(" + intString(listLength(regulars)) + "): " + List.toString(regulars, boolString) + "\n"});
          fail();
        end if;

      else
        // II.3 all reduced - full dependency per row. scalarize and add to all rows of the equation
        repeated    := UnorderedSet.contains(cref, rep);
        scalarized  := listReverse(ComponentRef.scalarizeAll(cref));
        map3        := UnorderedMap.new<Val2>(ComponentRef.hash, ComponentRef.isEqual);
        for scal in scalarized loop
          UnorderedMap.add(scal, getCrefInFrameIndices(scal, frames, mapping, map), map3);
        end for;

        // if its repeated, use the same cref always
        if repeated then
          mode := Mode.create(eqn_name, {cref}, false);
        end if;

        for i in skip_idx:iter_size:skip_idx+size-iter_size loop
          shift := 0;
          for scal in scalarized loop
            // if its not repeated use local cref
            if not repeated then
              mode := Mode.create(eqn_name, {scal}, true);
            end if;
            for scal_idx in UnorderedMap.getSafe(scal, map3, sourceInfo()) loop
              if intMod(shift, iter_size) == 0 then shift := 0; end if;
              addMatrixEntry(m, modes, i + shift, scal_idx, mode);
              shift := shift + 1;
            end for;
          end for;
        end for;
      end if;
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + ComponentRef.toString(cref) + "."});
      fail();
    end try;
  end resolveDependency;

  function resolveEquationDimensions
    "a component reference in a list of equation dimensions. The second argument to the tuple
    is TRUE if its a regular occurence of the cref and FALSE if its a reduced occurence.
    The key is created from the dimensions and the additional boolean to look up the cref occurence in the map."
    input list<tuple<Dimension, Boolean>> lst   "equation dimension and cref regularity tuple list";
    input UnorderedMap<Key, Val2> map           "map to look up occurence";
    input Array<Integer> key                    "mutable key";
    input array<list<Integer>> m                "adjacency matrix";
    input UnorderedMap<Mode.Key, Mode> modes;
    input Mode mode;
    input Pointer<Integer> eqn_idx_ptr          "mutable equation index";
    input Integer index = 1                     "dimension index for the key";
  algorithm
    _ := match lst
      local
        Dimension dim;
        list<tuple<Dimension, Boolean>> rest;
        Integer eqn_idx;
        list<Integer> scal_lst;

      case {} algorithm
        // no further dimensions. resolve with current key config and bump equation index
        eqn_idx := Pointer.access(eqn_idx_ptr);
        scal_lst := UnorderedMap.getSafe(arrayList(key), map, sourceInfo());
        for scal_idx in scal_lst loop
          addMatrixEntry(m, modes, eqn_idx, scal_idx, mode);
        end for;
        Pointer.update(eqn_idx_ptr, eqn_idx + 1);
      then ();

      case (dim, false)::rest algorithm
        // reduced dimension, keep key index at 0 and go deeper with next dimension
        for i in 1:Dimension.size(dim) loop
          resolveEquationDimensions(rest, map, key, m, modes, mode, eqn_idx_ptr, index+1);
        end for;
      then ();

      case (dim, true)::rest algorithm
        // regular dimension, update key index to corresponding dimension index
        // and go deeper with next dimension
        for i in 1:Dimension.size(dim) loop
          arrayUpdate(key, index, i);
          resolveEquationDimensions(rest, map, key, m, modes, mode, eqn_idx_ptr, index+1);
        end for;
      then ();
    end match;
  end resolveEquationDimensions;

  function addMatrixEntry
    input array<list<Integer>> m                "adjacency matrix";
    input UnorderedMap<Mode.Key, Mode> modes;
    input Integer eqn_idx;
    input Integer var_idx;
    input Mode mode;
  algorithm
    //print("adding eqn: " + intString(eqn_idx) + " var: " + intString(var_idx) + " with mode " + Mode.toString(mode) + "\n");
    arrayUpdate(m, eqn_idx, var_idx :: m[eqn_idx]);
    UnorderedMap.addUpdate((eqn_idx, var_idx), function Mode.mergeCreate(mode = mode), modes);
  end addMatrixEntry;

  function resolveReductions
    input list<tuple<Subscript, Dimension, Boolean>> lst;
    input UnorderedMap<Key, Val1> map;
    input Array<Integer> key;
    input ComponentRef stripped;
    input list<Subscript> acc = {};
    input Integer index = 1;
  algorithm
    _ := match lst
      local
        list<tuple<Subscript, Dimension, Boolean>> rest;
        Subscript sub;
        Dimension dim;
        ComponentRef cref;
        Val1 val;
        Integer sub_idx;

      case {} algorithm
        cref := ComponentRef.mergeSubscripts(listReverse(acc), stripped);
        val := ComponentRef.scalarizeAll(cref);
        UnorderedMap.add(arrayList(key), val, map);
      then ();

      case (sub, _, false)::rest algorithm
        resolveReductions(rest, map, key, stripped, sub::acc, index+1);
      then ();

      case (sub, dim, true)::rest algorithm
        sub_idx := 1;
        for s in Subscript.scalarize(sub, dim) loop
          arrayUpdate(key, index, sub_idx);
          resolveReductions(rest, map, key, stripped, s::acc, index+1);
          sub_idx := sub_idx + 1;
        end for;
      then ();

    end match;
  end resolveReductions;

  function combineFrames2Indices
    "Iterates over all elements in nested iterators represented by frames.
    Converts each of the now integer subscript lists (in combination with
    subscript sizes) to a single scalar index of the subscripted cref."
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
        list<Expression> iterator_exps;
        list<Integer> iterator_lst;

      // only occurs for non-for-loop equations (no frames to replace)
      case {} algorithm
        ranges  := resolveDimensionsSubscripts(sizes, subs, replacements);
      then {locationToIndex(ranges, first)};

      // extract numeric information about the range
      case (iterator, range) :: rest algorithm
        iterator_lst := match range
          case Expression.RANGE() algorithm
            (start, step, stop) := Expression.getIntegerRange(range);
          then List.intRange3(start,step, stop);
          case Expression.ARRAY() algorithm
            iterator_exps := list(Expression.map(e, function Replacements.applySimpleExp(replacements = replacements)) for e in range.elements);
            iterator_lst  := list(Expression.integerValue(SimplifyExp.simplifyDump(e, true, getInstanceName())) for e in iterator_exps);
          then iterator_lst;
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because iterator binding could not be parsed: "
              + ComponentRef.toString(iterator) + " in " + Expression.toString(range)});
          then fail();
        end match;

        // traverse every index in the range
        for index in iterator_lst loop
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

  function getCrefInFrameIndices
    input ComponentRef cref                                 "cref to get indices from";
    input list<tuple<ComponentRef, Expression>> frames      "iterator frames at which to evaluate cref";
    input Mapping mapping                                   "index mapping (only variable mapping needed)";
    input UnorderedMap<ComponentRef, Integer> map           "unordered map to check for relevance";
    output list<Integer> scal_lst                           "scalar indices of cref";
  protected
    ComponentRef stripped;
    Integer var_arr_idx, var_start;
    list<Integer> sizes;
    list<Expression> subs;
  algorithm
    stripped        := if listEmpty(frames) then cref else ComponentRef.stripSubscriptsAll(cref);
    var_arr_idx     := UnorderedMap.getSafe(stripped, map, sourceInfo());
    (var_start, _)  := mapping.var_AtS[var_arr_idx];
    sizes           := ComponentRef.sizes(stripped);
    subs            := ComponentRef.subscriptsToExpression(cref, true);
    scal_lst        := listReverse(combineFrames2Indices(var_start, sizes, subs, frames, UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual)));
  end getCrefInFrameIndices;

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
    values := list(Expression.integerValueOrDefault(SimplifyExp.simplifyDump(rep, true, getInstanceName()), 1) for rep in replaced);
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
