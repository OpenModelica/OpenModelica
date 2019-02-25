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

encapsulated uniontype NFConnector
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Type = NFType;

  import NFPrefixes.ConnectorType;
  import NFPrefixes.Variability;
  import DAE;

protected
  import Origin = NFComponentRef.Origin;
  import Connector = NFConnector;
  import NFInstNode.InstNode;
  import ElementSource;
  import NFComponent.Component;
  import NFClassTree.ClassTree;
  import NFClass.Class;
  import Restriction = NFRestriction;
  import ComplexType = NFComplexType;
  import Dimension = NFDimension;

public
  type Face = enumeration(INSIDE, OUTSIDE);

  record CONNECTOR
    ComponentRef name;
    Type ty;
    Face face;
    ConnectorType.Type cty;
    DAE.ElementSource source;
  end CONNECTOR;

  function fromCref
    input ComponentRef cref;
    input Type ty;
    input DAE.ElementSource source;
    output Connector conn = fromFacedCref(cref, ty, crefFace(cref), source);
  end fromCref;

  function fromFacedCref
    input ComponentRef cref;
    input Type ty;
    input Face face;
    input DAE.ElementSource source;
    output Connector conn;
  protected
    InstNode node = ComponentRef.node(cref);
    Component comp;
    ConnectorType.Type cty;
    Restriction res;
  algorithm
    if InstNode.isComponent(node) then
      comp := InstNode.component(node);
      res := Class.restriction(InstNode.getClass(Component.classInstance(comp)));
      cty := Component.connectorType(comp);
    else
      cty := intBitOr(ConnectorType.VIRTUAL, ConnectorType.POTENTIAL);
    end if;

    conn := CONNECTOR(ComponentRef.simplifySubscripts(cref), ty, face, cty, source);
  end fromFacedCref;

  function fromExp
    "Constructs a list of Connectors from a cref or an array of crefs."
    input Expression exp;
    input DAE.ElementSource source;
    input output list<Connector> conns = {};
  algorithm
    conns := match exp
      case Expression.CREF() then fromCref(exp.cref, exp.ty, source) :: conns;
      case Expression.ARRAY()
        algorithm
          for e in listReverse(exp.elements) loop
            conns := fromExp(e, source, conns);
          end for;
        then
          conns;

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown expression " +
            Expression.toString(exp), sourceInfo());
        then
          fail();
    end match;
  end fromExp;

  function getType
    input Connector conn;
    output Type ty = conn.ty;
  end getType;

  function getInfo
    input Connector conn;
    output SourceInfo info = conn.source.info;
  end getInfo;

  function variability
    input Connector conn;
    output Variability var =
      Component.variability(InstNode.component(ComponentRef.node(conn.name)));
  end variability;

  function isEqual
    input Connector conn1;
    input Connector conn2;
    output Boolean isEqual = ComponentRef.isEqual(conn1.name, conn2.name) and
                             conn1.face == conn2.face;
  end isEqual;

  function isPrefix
    input Connector conn1;
    input Connector conn2;
    output Boolean isPrefix = ComponentRef.isPrefix(conn1.name, conn2.name);
  end isPrefix;

  function isNodeNameEqual
    input Connector conn1;
    input Connector conn2;
    output Boolean isEqual = InstNode.name(ComponentRef.node(conn1.name)) ==
                             InstNode.name(ComponentRef.node(conn2.name));
  end isNodeNameEqual;

  function isOutside
    input Connector conn;
    output Boolean isOutside;
  protected
    Face f = conn.face; // Needed due to #4502
  algorithm
    isOutside := f == Face.OUTSIDE;
  end isOutside;

  function isInside
    input Connector conn;
    output Boolean isInside;
  protected
    Face f = conn.face; // Needed due to #4502
  algorithm
    isInside := f == Face.INSIDE;
  end isInside;

  function setOutside
    input output Connector conn;
  algorithm
    if conn.face <> Face.OUTSIDE then
      conn.face := Face.OUTSIDE;
    end if;
  end setOutside;

  function isDeleted
    input Connector conn;
    output Boolean isDeleted = ComponentRef.isDeleted(conn.name);
  end isDeleted;

  function isExpandable
    input Connector conn;
    output Boolean isExpandable = ConnectorType.isExpandable(conn.cty);
  end isExpandable;

  function name
    input Connector conn;
    output ComponentRef name = conn.name;
  end name;

  function toString
    input Connector conn;
    output String str = ComponentRef.toString(conn.name);
  end toString;

  function hash
    input Connector conn;
    input Integer mod;
    output Integer hash = ComponentRef.hash(conn.name, mod);
  end hash;

  function split
    "Splits a connector into its primitive components."
    input Connector conn;
    input Boolean splitArrays = Flags.isSet(Flags.NF_SCALARIZE);
    output list<Connector> connl;
  algorithm
    connl := splitImpl(conn.name, conn.ty, conn.face, conn.source, conn.cty, splitArrays);
  end split;

protected
  function crefFace
    "Determines whether a cref refers to an inside or outside connector, where
     an outside connector is a connector where the first part of the cref is a
     connector, and an inside connector all other crefs."
    input ComponentRef cref;
    output Face face;
  algorithm
    face := match cref
      // Simple identifiers must be connectors and thus outside.
      case ComponentRef.CREF(restCref = ComponentRef.EMPTY()) then Face.OUTSIDE;
      // Otherwise, check first part of the cref.
      else if InstNode.isConnector(ComponentRef.node(ComponentRef.firstNonScope(cref)))
             then Face.OUTSIDE else Face.INSIDE;
    end match;
  end crefFace;

  function splitImpl
    input ComponentRef name;
    input Type ty;
    input Face face;
    input DAE.ElementSource source;
    input ConnectorType.Type cty;
    input Boolean splitArrays;
    input output list<Connector> conns = {};
    input list<Dimension> dims = {} "accumulated dimensions if splitArrays = false";
  algorithm
    conns := match ty
      local
        Type t;
        ComplexType ct;
        ClassTree tree;

      case Type.COMPLEX(complexTy = ct as ComplexType.CONNECTOR())
        algorithm
          conns := splitImpl2(name, face, source, ct.potentials, splitArrays, conns, dims);
          conns := splitImpl2(name, face, source, ct.flows, splitArrays, conns, dims);
          conns := splitImpl2(name, face, source, ct.streams, splitArrays, conns, dims);
        then
          conns;

      case Type.COMPLEX()
        algorithm
          tree := Class.classTree(InstNode.getClass(ty.cls));
          conns := splitImpl2(name, face, source,
            arrayList(ClassTree.getComponents(tree)), splitArrays, conns, dims);
        then
          conns;

      case Type.ARRAY()
        algorithm
          t := Type.arrayElementType(ty);
          if splitArrays then
            for c in ComponentRef.scalarize(name) loop
              conns := splitImpl(c, t, face, source, cty, splitArrays, conns, dims);
            end for;
          else
            if not Type.isEmptyArray(ty) then
              conns := splitImpl(name, t, face, source, cty, splitArrays, conns,
                                 listAppend(dims, ty.dimensions));
            end if;
          end if;
        then
          conns;

      else CONNECTOR(name, Type.liftArrayLeftList(ty, dims), face, cty, source) :: conns;
    end match;
  end splitImpl;

  function splitImpl2
    input ComponentRef name;
    input Face face;
    input DAE.ElementSource source;
    input list<InstNode> comps;
    input Boolean splitArrays;
    input output list<Connector> conns;
    input list<Dimension> dims;
  protected
    Component c;
    ComponentRef cref;
    Type ty;
    ConnectorType.Type cty;
  algorithm
    for comp in comps loop
      c := InstNode.component(comp);
      ty := Component.getType(c);
      cty := Component.connectorType(c);

      if not ConnectorType.isPotentiallyPresent(cty) then
        cref := ComponentRef.append(ComponentRef.fromNode(comp, ty), name);
        conns := splitImpl(cref, ty, face, source, cty, splitArrays, conns, dims);
      end if;
    end for;
  end splitImpl2;

  annotation(__OpenModelica_Interface="frontend");
end NFConnector;
