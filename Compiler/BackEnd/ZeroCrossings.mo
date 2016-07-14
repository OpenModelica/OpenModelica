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

public

function new
  output ZeroCrossingSet zc_set;
algorithm
  zc_set := ZERO_CROSSING_SET(DoubleEndedList.fromList({}));
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
algorithm
  if not contains(zc_set, zc) then
    DE.push_back(zc_set.zc, zc);
  end if;
end add;

function add_front
  input ZeroCrossingSet zc_set;
  input ZeroCrossing zc;
algorithm
  if not contains(zc_set, zc) then
    DE.push_front(zc_set.zc, zc);
  end if;
end add_front;

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
  output Boolean matches=true;
algorithm
  matches := 0<>sum(match equals(zc, zc1) case true algorithm return; then 1; else 0; end match for zc1 in toListNoCopyNoClear(zc_set.zc));
end contains;

function equals "Returns true if both zero crossings have the same function expression"
  input ZeroCrossing inZeroCrossing1;
  input ZeroCrossing inZeroCrossing2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inZeroCrossing1, inZeroCrossing2)
    local
      Boolean res, res2;
      DAE.Exp e1, e2, e3, e4;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("sample"), expLst={e1, _, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("sample"), expLst={e2, _, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("integer"), expLst={e2, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("floor"), expLst={e2, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e2, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("mod"), expLst={e3, e4, _}))) equation
      res = Expression.expEqual(e1, e3);
      res2 = Expression.expEqual(e2, e4);
    then (res and res2);

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("div"), expLst={e3, e4, _}))) equation
      res = Expression.expEqual(e1, e3);
      res2 = Expression.expEqual(e2, e4);
    then (res and res2);

    case (BackendDAE.ZERO_CROSSING(relation_=e1), BackendDAE.ZERO_CROSSING(relation_=e2)) equation
      res = Expression.expEqual(e1, e2);
    then res;
  end match;
end equals;

annotation(__OpenModelica_Interface="backend");
end ZeroCrossings;
