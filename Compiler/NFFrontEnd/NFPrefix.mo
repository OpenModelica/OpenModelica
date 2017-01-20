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

encapsulated package NFPrefix
" file:        NFPrefix.mo
  package:     NFPrefix
  description:
"

import DAE;
import Subscript = NFSubscript;
import Type = NFType;

protected
import ExpressionDump;
import List;

public
uniontype Prefix
  record PREFIX
    String name;
    list<Subscript> subscripts;
    Type ty;
    Prefix restPrefix;
  end PREFIX;

  record NO_PREFIX end NO_PREFIX;

  function add
    input String name;
    input list<Subscript> subscripts;
    input Type ty;
    input output Prefix prefix;
  algorithm
    prefix := PREFIX(name, subscripts, ty, prefix);
  end add;

  function addClass
    input String name;
    input output Prefix prefix;
  algorithm
    prefix := add(name, {}, Type.UNKNOWN(), prefix);
  end addClass;

  function addSubscript
    input Subscript subscript;
    input output Prefix prefix;
  algorithm
    () := match prefix
      case PREFIX()
        algorithm
          prefix.subscripts := subscript :: prefix.subscripts;
        then
          ();
    end match;
  end addSubscript;

  function setSubscripts
    input list<Subscript> subscripts;
    input output Prefix prefix;
  algorithm
    _ := match prefix
      case PREFIX()
        algorithm
          prefix.subscripts := subscripts;
        then
          ();
    end match;
  end setSubscripts;

  function allSubscripts
    input Prefix prefix;
    output list<list<Subscript>> subscripts = {};
  protected
    Prefix rest_pre = prefix;
    list<Subscript> subs;
  algorithm
    while not isEmpty(rest_pre) loop
      PREFIX(subscripts = subs, restPrefix = rest_pre) := rest_pre;
      subscripts := subs :: subscripts;
    end while;
  end allSubscripts;

  function isEmpty
    input Prefix prefix;
    output Boolean isEmpty;
  algorithm
    isEmpty := match prefix
      case NO_PREFIX() then true;
      else false;
    end match;
  end isEmpty;

  function toCref
    input Prefix prefix;
    output DAE.ComponentRef cref;
  protected
    String name;
    list<Subscript> subs;
    list<DAE.Subscript> dsubs;
    Type ty;
    Prefix rest_pre;
  algorithm
    PREFIX(name, subs, ty, rest_pre) := prefix;
    dsubs := list(Subscript.toDAE(sub) for sub in subs);
    cref := DAE.CREF_IDENT(name, Type.toDAE(ty), dsubs);
    cref := prefixCref(cref, rest_pre);
  end toCref;

  function prefixCref
    input output DAE.ComponentRef cref;
    input Prefix prefix;
  protected
    String name;
    list<Subscript> subs;
    list<DAE.Subscript> dsubs;
    Type ty;
    Prefix rest_pre = prefix;
  algorithm
    while not isEmpty(rest_pre) loop
      PREFIX(name, subs, ty, rest_pre) := rest_pre;
      dsubs := list(Subscript.toDAE(sub) for sub in subs);
      cref := DAE.CREF_QUAL(name, Type.toDAE(ty), dsubs, cref);
    end while;
  end prefixCref;

  function toString
    input Prefix prefix;
    output String string;
  protected
    Prefix rest_pre = prefix;
    String name;
    list<Subscript> subs;
    list<String> parts = {};
  algorithm
    while not isEmpty(rest_pre) loop
      PREFIX(name = name, subscripts = subs, restPrefix = rest_pre) := rest_pre;
      name := name + List.toString(subs, Subscript.toString, "", "[", ", ", "]", false);
      parts := name :: parts;
    end while;

    string := stringDelimitList(parts, ".");
  end toString;

end Prefix;

annotation(__OpenModelica_Interface="frontend");
end NFPrefix;
