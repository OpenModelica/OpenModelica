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

encapsulated uniontype NFComponentRef
protected
  import NFComponent.Component;
  import DAE;
  import Subscript = NFSubscript;
  import Type = NFType;
  import NFInstNode.InstNode;

  import ComponentRef = NFComponentRef;

public
  type Origin = enumeration(
    CREF "From an Absyn cref.",
    SCOPE "From prefixing the cref with its scope.",
    ITERATOR "From an iterator."
  );

  record CREF
    InstNode node;
    list<Subscript> subscripts;
    Type ty;
    Origin origin;
    ComponentRef restCref;
  end CREF;

  record EMPTY end EMPTY;

  record WILD end WILD;

  function fromNode
    input InstNode node;
    input Type ty;
    input list<Subscript> subs = {};
    input Origin origin = Origin.CREF;
    output ComponentRef cref = CREF(node, subs, ty, origin, EMPTY());
  end fromNode;

  function getType
    input ComponentRef cref;
    output Type ty;
  algorithm
    ty := match cref
      case CREF() then cref.ty;
      else Type.UNKNOWN();
    end match;
  end getType;

  function setType
    input Type ty;
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.ty := ty;
        then
          ();
    end match;
  end setType;

  function getVariability
    input ComponentRef cref;
    output DAE.Const var;
  algorithm
    var := match cref
      case CREF()
        then
          match Component.variability(InstNode.component(cref.node))
            case DAE.VarKind.VARIABLE() then DAE.Const.C_VAR();
            case DAE.VarKind.DISCRETE() then DAE.Const.C_VAR();
            case DAE.VarKind.PARAM() then DAE.Const.C_PARAM();
            case DAE.VarKind.CONST() then DAE.Const.C_CONST();
            else DAE.Const.C_UNKNOWN();
          end match;

      else DAE.Const.C_UNKNOWN();
    end match;
  end getVariability;

  function addSubscript
    input Subscript subscript;
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.subscripts := subscript :: cref.subscripts;
        then
          ();
    end match;
  end addSubscript;

  function setSubscripts
    input list<Subscript> subscripts;
    input output ComponentRef cref;
  algorithm
    () := match cref
      case CREF()
        algorithm
          cref.subscripts := subscripts;
        then
          ();
    end match;
  end setSubscripts;

  function allSubscripts
    input ComponentRef cref;
    input list<list<Subscript>> accumSubs = {};
    output list<list<Subscript>> subscripts;
  algorithm
    subscripts := match cref
      case CREF() then allSubscripts(cref.restCref, cref.subscripts :: accumSubs);
      else accumSubs;
    end match;
  end allSubscripts;

  function transferSubscripts
    input ComponentRef srcCref;
    input ComponentRef dstCref;
    output ComponentRef cref;
  algorithm
    cref := match (srcCref, dstCref)
      case (EMPTY(), _) then dstCref;
      case (_, CREF(origin = Origin.ITERATOR)) then dstCref;

      case (CREF(), CREF(origin = Origin.CREF))
        algorithm
          dstCref.restCref := transferSubscripts(srcCref, dstCref.restCref);
        then
          dstCref;

      case (CREF(), CREF())
        algorithm
          cref := transferSubscripts(srcCref.restCref, dstCref.restCref);
        then
          CREF(dstCref.node, srcCref.subscripts, dstCref.ty, dstCref.origin, cref);

      else
        algorithm
          assert(false, getInstanceName() + " failed");
        then
          fail();
    end match;
  end transferSubscripts;

  function compare
    input ComponentRef cref1;
    input ComponentRef cref2;
    output Integer comp = 0;
  algorithm
    assert(false, getInstanceName() + ": IMPLEMENT ME");
  end compare;

  function toDAE
    input ComponentRef cref;
    output DAE.ComponentRef dcref;
  algorithm
    dcref := match cref
      case CREF()
        algorithm
          dcref := DAE.ComponentRef.CREF_IDENT(InstNode.name(cref.node), Type.toDAE(cref.ty),
            list(Subscript.toDAE(s) for s in cref.subscripts));
        then
          toDAE_impl(cref.restCref, dcref);

      case WILD() then DAE.ComponentRef.WILD();
    end match;
  end toDAE;

  function toDAE_impl
    input ComponentRef cref;
    input DAE.ComponentRef accumCref;
    output DAE.ComponentRef dcref;
  algorithm
    dcref := match cref
      case EMPTY() then accumCref;
      case CREF()
        algorithm
          dcref := DAE.ComponentRef.CREF_QUAL(InstNode.name(cref.node), Type.toDAE(cref.ty),
            list(Subscript.toDAE(s) for s in cref.subscripts), accumCref);
        then
          toDAE_impl(cref.restCref, dcref);
    end match;
  end toDAE_impl;

  function toString
    input ComponentRef cref;
    output String str;
  algorithm
    str := match cref
      case CREF(restCref = EMPTY())
        then InstNode.name(cref.node) + Subscript.toStringList(cref.subscripts);

      case CREF()
        algorithm
          str := toString(cref.restCref);
        then
          str + "." + InstNode.name(cref.node) + Subscript.toStringList(cref.subscripts);

      case WILD() then "_";
      else "EMPTY_CREF";
    end match;
  end toString;

  function toPath
    input ComponentRef cref;
    output Absyn.Path path;
  algorithm
    path := match cref
      case CREF()
        then toPath_impl(cref.restCref, Absyn.IDENT(InstNode.name(cref.node)));
    end match;
  end toPath;

  function toPath_impl
    input ComponentRef cref;
    input Absyn.Path accumPath;
    output Absyn.Path path;
  algorithm
    path := match cref
      case CREF()
        then toPath_impl(cref.restCref,
          Absyn.QUALIFIED(InstNode.name(cref.node), accumPath));
      else accumPath;
    end match;
  end toPath_impl;

  function fromNodeList
    input list<InstNode> nodes;
    output ComponentRef cref = ComponentRef.EMPTY();
  algorithm
    for n in nodes loop
      cref := CREF(n, {}, InstNode.getType(n), Origin.SCOPE, cref);
    end for;
  end fromNodeList;

annotation(__OpenModelica_Interface="frontend");
end NFComponentRef;
