module DoubleEndedList
using MetaModelica
#= /*
  * This file is part of OpenModelica.
  *
  * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
  * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
  * http:www.openmodelica.org, and in the OpenModelica distribution.
  * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
  *
  * This program is distributed WITHOUT ANY WARRANTY; without
  * even the implied warranty of  MERCHANTABILITY or FITNESS
  * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
  * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
  *
  * See the full OSMC Public License conditions for more details.
  *
  */ =#

#= Implementation of a mutable double-ended list. O(1) push_front, push_back, pop_front, toListAndClear =#
using Mutable


@Uniontype DLL begin
  @Record LIST begin
    length::UMutable
    front::UMutable
    back::UMutable
  end
end

import GC
import MetaModelica.Dangerous

function new(first::T)::DLL
  local delst::DLL

  local lst::IList = list(first)

  delst = LIST(Mutable.create(1), Mutable.create(lst), Mutable.create(lst))
  delst
end

function fromList(lst::IList)::DLL
  local delst::DLL

  local head::IList
  local tail::IList
  local tmp::IList
  local length::ModelicaInteger
  local t::T

  if listEmpty(lst)
    delst = LIST(Mutable.create(0), Mutable.create(list()), Mutable.create(list()))
    return delst
  end
  t, tmp = listHead(lst), listRest(lst)
  head = list(t)
  tail = head
  length = 1
  for l in tmp
    tmp = list(l)
    Dangerous.listSetRest(tail, tmp)
    tail = tmp
    length = length + 1
  end
  delst = LIST(Mutable.create(length), Mutable.create(head), Mutable.create(tail))
  delst
end

function empty(dummy::T)::DLL
  local delst::DLL

  delst = LIST(Mutable.create(0), Mutable.create(list()), Mutable.create(list()))
  delst
end

function length(delst::DLL)::ModelicaInteger
  local length::ModelicaInteger

  length = Mutable.access(delst.length)
  length
end

function pop_front(delst::DLL)::T
  local elt::T

  local length::ModelicaInteger = Mutable.access(delst.length)
  local lst::IList

  @assert true == (length > 0)
  Mutable.update(delst.length, length - 1)
  if length == 1
    Mutable.update(delst.front, list())
    Mutable.update(delst.back, list())
    return elt
  end
  elt, lst = listHead(Mutable.access(delst.front)), listRest(Mutable.access(delst.front))
  Mutable.update(delst.front, lst)
  elt
end

function currentBackCell(delst::DLL)::IList
  local last::IList

  last = Mutable.access(delst.back)
  last
end

function push_front(delst::DLL, elt::T)
  local length::ModelicaInteger = Mutable.access(delst.length)
  local lst::IList

  Mutable.update(delst.length, length + 1)
  if length == 0
    lst = list(elt)
    Mutable.update(delst.front, lst)
    Mutable.update(delst.back, lst)
    return
  end
  lst = Mutable.access(delst.front)
  Mutable.update(delst.front, elt <| lst)
end

function push_list_front(delst::DLL, lst::IList)
  local length::ModelicaInteger = Mutable.access(delst.length)
  local lstLength::ModelicaInteger
  local work::IList
  local oldHead::IList
  local tmp::IList
  local head::IList
  local t::T

  lstLength = listLength(lst)
  if lstLength == 0
    return
  end
  Mutable.update(delst.length, length + lstLength)
  t, tmp = listHead(lst), listRest(lst)
  head = list(t)
  oldHead = Mutable.access(delst.front)
  Mutable.update(delst.front, head)
  for l in tmp
    work = list(l)
    Dangerous.listSetRest(head, work)
    head = work
  end
  if length == 0
    Mutable.update(delst.back, head)
  else
    Dangerous.listSetRest(head, oldHead)
  end
end

T = Any
function push_back(delst::DLL, elt::T)
  local length::ModelicaInteger = Mutable.access(delst.length)
  local lst::IList

  Mutable.update(delst.length, length + 1)
  if length == 0
    lst = list(elt)
    Mutable.update(delst.front, lst)
    Mutable.update(delst.back, lst)
    return
  end
  lst = list(elt)
  Dangerous.listSetRest(Mutable.access(delst.back), lst)
  Mutable.update(delst.back, lst)
end

function push_list_back(delst::DLL, lst::IList)
  local length::ModelicaInteger = Mutable.access(delst.length)
  local lstLength::ModelicaInteger
  local tail::IList
  local tmp::IList
  local t::T

  lstLength = listLength(lst)
  if lstLength == 0
    return
  end
  Mutable.update(delst.length, length + lstLength)
  t = listGet(lst, 1)
  tmp = list(t)
  if length == 0
    Mutable.update(delst.front, tmp)
  else
    Dangerous.listSetRest(Mutable.access(delst.back), tmp)
  end
  tail = tmp
  for l in listRest(lst)
    tmp = list(l)
    Dangerous.listSetRest(tail, tmp)
    tail = tmp
  end
  Mutable.update(delst.back, tail)
end

function toListAndClear(delst::DLL, prependToList::IList = list())::IList
  local res::IList

  if Mutable.access(delst.length) == 0
    res = prependToList
    return res
  end
  res = Mutable.access(delst.front)
  if ! listEmpty(prependToList)
    Dangerous.listSetRest(Mutable.access(delst.back), prependToList)
  end
  Mutable.update(delst.back, list())
  Mutable.update(delst.front, list())
  Mutable.update(delst.length, 0)
  res
end

#= Returns the working list, which may be changed later on! =#
function toListNoCopyNoClear(delst::DLL)::IList
  local res::IList

  res = Mutable.access(delst.front)
  res
end

function clear(delst::DLL)
  local lst::IList

  lst = Mutable.access(delst.front)
  Mutable.update(delst.back, list())
  Mutable.update(delst.front, list())
  Mutable.update(delst.length, 0)
  for l in lst
    GC.free(l)
  end
end

ArgT1 = Any
function mapNoCopy_1(delst::DLL, inMapFunc::MapFunc, inArg1::ArgT1)
  local lst::IList = Mutable.access(delst.front)

  while ! listEmpty(lst)
    Dangerous.listSetFirst(lst, inMapFunc(listGet(lst, 1), inArg1))
    _, lst = listHead(lst), listRest(lst)
  end
end

ArgT1 = Any
function mapFoldNoCopy(delst::DLL, inMapFunc::MapFunc, arg::ArgT1)::ArgT1


  local element::T
  local lst::IList = Mutable.access(delst.front)

  while ! listEmpty(lst)
    (element, arg) = inMapFunc(listGet(lst, 1), arg)
    Dangerous.listSetFirst(lst, element)
    _, lst = listHead(lst), listRest(lst)
  end
  arg
end

end
