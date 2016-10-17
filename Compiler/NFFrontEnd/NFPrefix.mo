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

import DAE.{ComponentRef, Subscript, Type};

protected
import ExpressionDump;
import List;

public
uniontype Prefix
  record PREFIX
    String name;
    list<DAE.Subscript> subscripts;
    DAE.Type ty;
    Prefix restPrefix;
  end PREFIX;

  record NO_PREFIX end NO_PREFIX;

  function add
    input String name;
    input list<DAE.Subscript> subscripts;
    input DAE.Type ty;
    input output Prefix prefix;
  algorithm
    prefix := PREFIX(name, subscripts, ty, prefix);
  end add;

  function addClass
    input String name;
    input output Prefix prefix;
  algorithm
    prefix := add(name, {}, DAE.T_UNKNOWN_DEFAULT, prefix);
  end addClass;

  function setSubscripts
    input list<DAE.Subscript> subscripts;
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
    output list<list<DAE.Subscript>> subscripts = {};
  protected
    Prefix rest_pre = prefix;
    list<DAE.Subscript> subs;
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
    list<DAE.Subscript> subs;
    DAE.Type ty;
    Prefix rest_pre;
  algorithm
    PREFIX(name, subs, ty, rest_pre) := prefix;
    cref := DAE.CREF_IDENT(name, ty, subs);
    cref := prefixCref(cref, rest_pre);
  end toCref;

  function prefixCref
    input output DAE.ComponentRef cref;
    input Prefix prefix;
  protected
    String name;
    list<DAE.Subscript> subs;
    DAE.Type ty;
    Prefix rest_pre = prefix;
  algorithm
    while not isEmpty(rest_pre) loop
      PREFIX(name, subs, ty, rest_pre) := rest_pre;
      cref := DAE.CREF_QUAL(name, ty, subs, cref);
    end while;
  end prefixCref;

  function prefixExp
    input output DAE.Exp exp;
    input Prefix prefix;
    //input list<DAE.Exp> inEqSubscripts;
  algorithm
    exp := match exp
      local
        DAE.ComponentRef cref;
        DAE.Type ty;
        DAE.Exp e1, e2;
        DAE.Operator op;

      case DAE.CREF()
        algorithm
          exp.componentRef := prefixCref(exp.componentRef, prefix);
        then
          exp;

      case DAE.BINARY(e1, op, e2)
        algorithm
          e1 := prefixExp(e1, prefix);
          e2 := prefixExp(e2, prefix);
          //op = Expression.unliftOperatorX(op, listLength(inEqSubscripts));
        then
          DAE.BINARY(e1, op, e2);

      case DAE.ARRAY()
        algorithm
          e1 := prefixArrayElements(exp, prefix);
          //e1 = DAE.ASUB(e1, inEqSubscripts);
        then
          e1;

      case DAE.CAST(ty, e1)
        algorithm
          e1 := prefixExp(e1, prefix);
          ty := Types.arrayElementType(ty);
          e1 := DAE.CAST(ty, e1);
        then
          e1;

      else exp;
    end match;
  end prefixExp;

  function toString
    input Prefix prefix;
    output String string;
  protected
    Prefix rest_pre = prefix;
    String name;
    list<DAE.Subscript> subs;
    list<String> parts = {};
  algorithm
    while not isEmpty(rest_pre) loop
      PREFIX(name = name, subscripts = subs, restPrefix = rest_pre) := rest_pre;
      name := name + List.toString(subs, ExpressionDump.printSubscriptStr,
        "", "[", ", ", "]", false);
      parts := name :: parts;
    end while;

    string := stringDelimitList(parts, ".");
  end toString;

protected
  function prefixArrayElements
    input output DAE.Exp array;
    input Prefix prefix;
  algorithm
    _ := match array
      local
        DAE.Type ty;
        Boolean scalar;
        list<DAE.Exp> expl;

      case DAE.ARRAY(ty = DAE.T_ARRAY(ty = DAE.T_ARRAY()))
        algorithm
          array.array := list(prefixArrayElements(e, prefix) for e in array.array);
        then
          ();

      case DAE.ARRAY()
        algorithm
          array.array := list(prefixExp(e, prefix) for e in array.array);
        then
          ();

    end match;
  end prefixArrayElements;
end Prefix;

annotation(__OpenModelica_Interface="frontend");
end NFPrefix;
