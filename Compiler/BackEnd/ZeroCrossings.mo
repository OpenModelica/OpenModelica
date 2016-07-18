/*
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

encapsulated package ZeroCrossings
" file:        ZeroCrossings.mo
  package:     ZeroCrossings
  description: This package contains utility functions for zero crossings
               inside BackendDAE.

"

import BackendDAE;
import BackendDAE.{ZeroCrossing,ZeroCrossingSet};
import BackendDAE.ZeroCrossingSet.ZERO_CROSSING_SET;

protected
import DE=DoubleEndedList;
import DoubleEndedList.toListNoCopyNoClear;
import Expression;
import ExpressionDump;

public

type Tree = ZeroCrossingTree.Tree;

package ZeroCrossingTree "Lookup ZeroCrossing -> list<ZeroCrossing> (the cons-cell storing the ZC)"
  extends BaseAvlTree;
  redeclare type Key = ZeroCrossing;
  redeclare type Value = list<ZeroCrossing>;
  redeclare function extends keyStr
  algorithm
    outString := ExpressionDump.printExpStr(inKey.relation_);
  end keyStr;
  redeclare function extends valueStr
  protected
    ZeroCrossing zc;
  algorithm
    zc := listGet(inValue,1);
    outString := ExpressionDump.printExpStr(zc.relation_);
  end valueStr;
  redeclare function extends keyCompare
  algorithm
    outResult := ZeroCrossings.compare(inKey1, inKey2);
  end keyCompare;
end ZeroCrossingTree;

function new
  output ZeroCrossingSet zc_set;
algorithm
  zc_set := ZERO_CROSSING_SET(DoubleEndedList.fromList({}), arrayCreate(1, ZeroCrossingTree.new()));
end new;

function length
  input ZeroCrossingSet zc_set;
  output Integer i;
algorithm
  i := DE.length(zc_set.zc);
end length;

function add
  input ZeroCrossingSet zc_set;
  input ZeroCrossing zc;
protected
  list<ZeroCrossing> addedCell;
algorithm
  if not contains(zc_set, zc) then
    DE.push_back(zc_set.zc, zc);
    addedCell := DE.currentBackCell(zc_set.zc);
    arrayUpdate(zc_set.tree, 1, ZeroCrossingTree.add(arrayGet(zc_set.tree, 1), zc, addedCell));
  end if;
end add;

function add_list
  input ZeroCrossingSet zc_set;
  input list<ZeroCrossing> zc_lst;
algorithm
  for zc in zc_lst loop
    add(zc_set, zc);
  end for;
end add_list;

function toList
  input ZeroCrossingSet zc;
  output list<ZeroCrossing> lst;
algorithm
  lst := toListNoCopyNoClear(zc.zc);
end toList;

function contains
  input ZeroCrossingSet zc_set;
  input ZeroCrossing zc;
  output Boolean matches;
algorithm
  matches := ZeroCrossingTree.hasKey(arrayGet(zc_set.tree,1), zc);
end contains;

function get
  input ZeroCrossingSet zc_set;
  input ZeroCrossing zc;
  output ZeroCrossing outZc;
algorithm
  outZc::_ := ZeroCrossingTree.get(arrayGet(zc_set.tree,1), zc);
end get;

function equals "Returns true if both zero crossings have the same function expression"
  input ZeroCrossing zc1;
  input ZeroCrossing zc2;
  output Boolean outBoolean;
algorithm
  outBoolean := 0==compare(zc1, zc2);
end equals;

function compare "Returns true if both zero crossings have the same function expression"
  input ZeroCrossing zc1;
  input ZeroCrossing zc2;
  output Integer comp;
algorithm
  comp := match (zc1, zc2)
    local
      DAE.Exp e1, e2, e3, e4;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("sample"), expLst={e1, _, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("sample"), expLst={e2, _, _})))
      then Expression.compare(e1,e2);

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("integer"), expLst={e2, _})))
      then Expression.compare(e1,e2);

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("floor"), expLst={e2, _})))
      then Expression.compare(e1,e2);

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e2, _})))
      then Expression.compare(e1,e2);

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("mod"), expLst={e3, e4, _})))
      algorithm
        comp := Expression.compare(e1,e2);
      then if comp==0 then Expression.compare(e2, e4) else comp;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("div"), expLst={e3, e4, _})))
      algorithm
        comp := Expression.compare(e1,e2);
      then if comp==0 then Expression.compare(e2, e4) else comp;

    case (BackendDAE.ZERO_CROSSING(relation_=e1), BackendDAE.ZERO_CROSSING(relation_=e2))
      then Expression.compare(e1, e2);
  end match;
end compare;

annotation(__OpenModelica_Interface="backend");
end ZeroCrossings;
