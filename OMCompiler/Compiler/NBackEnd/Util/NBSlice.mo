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

  import List;
  import UnorderedMap;

public
  type IntLst = list<Integer>;

  record SLICE
    T t;
    IntLst indices;
  end SLICE;

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
    if listLength(slice.indices) > maxLength then
      str := str + "\n\t slice: " + List.toString(List.firstN(slice.indices, maxLength), intString, "", "{", ", ", "") + " ...}";
    elseif not listEmpty(slice.indices) then
      str := str + "\n\t slice: " + List.toString(slice.indices, intString);
    end if;
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
      UnorderedMap.add(t, i :: UnorderedMap.getSafe(t, map), map);
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

  annotation(__OpenModelica_Interface="backend");
end NBSlice;