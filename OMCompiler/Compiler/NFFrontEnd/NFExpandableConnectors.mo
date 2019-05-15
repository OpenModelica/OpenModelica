/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFExpandableConnectors

public
import FlatModel = NFFlatModel;
import Connections = NFConnections;

protected
import Array;
import BaseHashSet;
import Binding = NFBinding;
import ComplexType = NFComplexType;
import ComponentRef = NFComponentRef;
import Connection = NFConnection;
import ConnectionSets = NFConnectionSets.ConnectionSets;
import Connector = NFConnector;
import DAE;
import ElementSource;
import NFClass.Class;
import NFClassTree.ClassTree;
import NFComponent.Component;
import NFInstNode.InstNode;
import NFPrefixes.ConnectorType;
import NFPrefixes.Visibility;
import Prefixes = NFPrefixes;
import System;
import Type = NFType;
import Typing = NFTyping;
import Util;
import Variable = NFVariable;
import MetaModelica.Dangerous.listReverseInPlace;
import TypeCheck = NFTypeCheck;
import NFTypeCheck.MatchKind;
import Expression = NFExpression;

public
function elaborate
  input output FlatModel flatModel;
  input output Connections connections;
protected
  list<Connection> expandable_conns, undeclared_conns, conns;
  list<Variable> vars;
  ConnectionSets.Sets csets;
  array<list<Connector>> csets_array;
algorithm
  // Sort the connections based on whether they involve expandable connectors,
  // virtual/potentially present connectors, or only normal connectors.
  (expandable_conns, undeclared_conns, conns) := sortConnections(connections.connections);

  // Don't do anything if there aren't any expandable connectors in the model.
  if listEmpty(expandable_conns) and listEmpty(undeclared_conns) then
    return;
  end if;

  // Create a graph from the connections. Expandable connectors connect to
  // expandable connectors, while virtual/potentially present connectors connect
  // to the expandable connector they belong to.
  csets := ConnectionSets.emptySets(listLength(expandable_conns) + listLength(undeclared_conns));
  csets := addExpandableConnectorsToSets(expandable_conns, csets);
  (undeclared_conns, csets) := List.mapFold(undeclared_conns, addUndeclaredConnectorToSets, csets);
  // Extract the sets of connected connectors.
  csets_array := ConnectionSets.extractSets(csets);

  //for set in csets_array loop
  //  print("Expandable connection set:\n");
  //  print(List.toString(set, Connector.toString, "", "{", ", ", "}", true) + "\n");
  //end for;

  // Augment the expandable connectors with the necessary elements, mark
  // connected potentially present variables as present, and add the
  // created variables to the flat model.
  vars := flatModel.variables;
  for set in csets_array loop
    vars := elaborateExpandableSet(set, vars);
  end for;

  // Update the connections and put them back in the list of connections.
  conns := List.fold(undeclared_conns, updateUndeclaredConnection, conns);
  conns := List.fold(expandable_conns, updateExpandableConnection, conns);
  connections.connections := conns;

  // Update the attributes of potentially present variables so that they have
  // the same attributes as their node. Their connector type will have changed
  // if they've been marked as present.
  vars := list(updatePotentiallyPresentVariable(v) for v in vars);
  flatModel.variables := vars;
end elaborate;

protected

encapsulated package ExpandableSet
  import BaseHashSet;
  import System;
  import Connector = NFConnector;
  import ComponentRef = NFComponentRef;

  extends BaseHashSet(redeclare type Key = Connector);

  function emptySet
    input Integer size;
    output HashSet set;
  algorithm
    set := BaseHashSet.emptyHashSetWork(size,
      (hashConnector, Connector.isNodeNameEqual, Connector.toString));
  end emptySet;

  function hashConnector
    input Connector conn;
    input Integer mod;
    output Integer res;
  algorithm
    res := stringHashDjb2Mod(ComponentRef.firstName(conn.name), mod);
  end hashConnector;

  annotation(__OpenModelica_Interface="frontend");
end ExpandableSet;

function sortConnections
  "Sorts the connections into different categories of connectors based on
   whether they involve expandable connectors, virtual/potentially present
   connector, or only normal connectors."
  input list<Connection> conns;
  output list<Connection> expandableConnections = {};
  output list<Connection> undeclaredConnections = {};
  output list<Connection> normalConnections = {};
protected
  Connector c1, c2;
  Option<tuple<Error.Message, list<Connector>>> err_msg;
  Boolean is_undeclared1, is_undeclared2, is_expandable1, is_expandable2;
algorithm
  for conn in conns loop
    Connection.CONNECTION(lhs = c1, rhs = c2) := conn;

    is_undeclared1 := ConnectorType.isUndeclared(c1.cty);
    is_undeclared2 := ConnectorType.isUndeclared(c2.cty);
    is_expandable1 := ConnectorType.isExpandable(c1.cty);
    is_expandable2 := ConnectorType.isExpandable(c2.cty);

    if is_expandable1 or is_expandable2 then
      if is_expandable1 and is_expandable2 then
        expandableConnections := conn :: expandableConnections;
      else
        // An expandable connector may only connect to another expandable connector.
        Error.addSourceMessageAndFail(Error.EXPANDABLE_NON_EXPANDABLE_CONNECTION,
          {Connector.toString(if is_expandable1 then c1 else c2),
           Connector.toString(if is_expandable1 then c2 else c1)},
          Connector.getInfo(c1));
      end if;
    elseif is_undeclared1 or is_undeclared2 then
      if is_undeclared1 and is_undeclared2 then
        // Both sides can't be undeclared, one must be a declared component.
        Error.addSourceMessageAndFail(Error.UNDECLARED_CONNECTION,
          {Connector.toString(c1), Connector.toString(c2)}, Connector.getInfo(c1));
      else
        undeclaredConnections := conn :: undeclaredConnections;
      end if;
    else
      normalConnections := conn :: normalConnections;
    end if;
  end for;

  normalConnections := listReverseInPlace(normalConnections);
end sortConnections;

function addExpandableConnectorsToSets
  input list<Connection> conns;
  input output ConnectionSets.Sets csets;
protected
  Connector c1, c2;
algorithm
  for conn in conns loop
    Connection.CONNECTION(lhs = c1, rhs = c2) := conn;
    csets := addConnectionToSets(c1, c2, csets);
    csets := addNestedExpandableConnectorsToSets(c1, c2, csets);
  end for;
end addExpandableConnectorsToSets;

function addNestedExpandableConnectorsToSets
  input Connector c1;
  input Connector c2;
  input output ConnectionSets.Sets csets;
protected
  list<Connector> ecl1, ecl2;
  Option<Connector> oec;
algorithm
  ecl1 := getExpandableConnectorsInConnector(c1);
  ecl2 := getExpandableConnectorsInConnector(c2);

  if listEmpty(ecl1) and listEmpty(ecl2) then
    return;
  end if;

  for ec1 in ecl1 loop
    (ecl2, oec) := List.deleteMemberOnTrue(ec1, ecl2, Connector.isNodeNameEqual);

    if isSome(oec) then
      csets := addConnectionToSets(ec1, Util.getOption(oec), csets);
    end if;
  end for;
end addNestedExpandableConnectorsToSets;

function getExpandableConnectorsInConnector
  input Connector c1;
  output list<Connector> ecl;
protected
  list<InstNode> nodes;
  ComponentRef par_name, name;
  Type ty;
algorithm
  ecl := match c1
    case Connector.CONNECTOR(name = par_name, ty = Type.COMPLEX(
        complexTy = ComplexType.EXPANDABLE_CONNECTOR(expandableConnectors = nodes)))
      algorithm
        ecl := {};

        for n in nodes loop
          ty := InstNode.getType(n);
          name := ComponentRef.prefixCref(n, ty, {}, par_name);
          ecl := Connector.fromCref(name, ty, ElementSource.createElementSource(InstNode.info(n))) :: ecl;
        end for;
      then
        ecl;

    else {};
  end match;
end getExpandableConnectorsInConnector;

function addUndeclaredConnectorToSets
  input output Connection conn;
  input output ConnectionSets.Sets csets;
protected
  Connector c1, c2, c, ec;
algorithm
  Connection.CONNECTION(lhs = c1, rhs = c2) := conn;

  // Figure out which connector to add, and create a virtual connector if necessary.
  if ConnectorType.isUndeclared(c1.cty) then
    if ConnectorType.isVirtual(c1.cty) then
      c1 := makeVirtualConnector(c1, c2);
      conn := Connection.CONNECTION(c1, c2);
    end if;

    c := c1;
  else
    if ConnectorType.isVirtual(c2.cty) then
      c2 := makeVirtualConnector(c2, c1);
      conn := Connection.CONNECTION(c1, c2);
    end if;

    c := c2;
  end if;

  // Create a parent connector for the undeclared connector, i.e. the expandable
  // connector it should be added to. The type here is wrong, but it doesn't matter.
  ec := Connector.CONNECTOR(ComponentRef.rest(c.name), c.ty, c.face, ConnectorType.EXPANDABLE, c.source);

  // Add a connection between the undeclared connector and the expandable connector.
  csets := addConnectionToSets(c, ec, csets);
end addUndeclaredConnectorToSets;

function addConnectionToSets
  input Connector c1;
  input Connector c2;
  input output ConnectionSets.Sets csets;
algorithm
  // The connection sets are not used to represent actual connections here, only
  // to keep track of which expandable connectors that are associated. So to
  // make sure we only get one instance of each expandable connector in the sets
  // we make sure the face of all the connectors we add is the same.
  csets := ConnectionSets.merge(Connector.setOutside(c1), Connector.setOutside(c2), csets);
end addConnectionToSets;

function makeVirtualConnector
  input Connector virtualConnector;
  input Connector normalConnector;
  output Connector newConnector;
protected
  ComponentRef virtual_cref, normal_cref;
  Type ty;
  InstNode node;
algorithm
  virtual_cref := virtualConnector.name;
  normal_cref := normalConnector.name;
  ty := normalConnector.ty;

  // TODO: Update the virtual connector with the created node.
  node := ComponentRef.node(normal_cref);
  node := InstNode.clone(node);
  node := InstNode.rename(ComponentRef.firstName(virtual_cref), node);
  node := InstNode.setParent(ComponentRef.node(ComponentRef.rest(virtual_cref)), node);
  virtual_cref := ComponentRef.prefixCref(node, ty, {}, ComponentRef.rest(virtual_cref));

  // TODO: This needs more work, the new connector might be a complex connector.
  newConnector := Connector.CONNECTOR(virtual_cref, ty, virtualConnector.face,
    virtualConnector.cty, virtualConnector.source);
end makeVirtualConnector;

function elaborateExpandableSet
  input list<Connector> set;
  input output list<Variable> vars;
protected
  ExpandableSet.HashSet exp_set;
  list<Connector> exp_conns = {}, exp_set_lst;
algorithm
  exp_set := ExpandableSet.emptySet(Util.nextPrime(listLength(set)));

  for c in set loop
    if ConnectorType.isExpandable(c.cty) then
      exp_conns := c :: exp_conns;
    elseif ConnectorType.isUndeclared(c.cty) then
      exp_set := BaseHashSet.add(c, exp_set);
      markComponentPresent(ComponentRef.node(Connector.name(c)));
    end if;
  end for;

  exp_set_lst := BaseHashSet.hashSetList(exp_set);

  for ec in exp_conns loop
    vars := augmentExpandableConnector(ec, exp_set_lst, vars);
  end for;
end elaborateExpandableSet;

function markComponentPresent
  input InstNode node;
protected
  Component comp;
  ConnectorType.Type cty;
algorithm
  comp := InstNode.component(node);
  cty := Component.connectorType(comp);

  if ConnectorType.isPotentiallyPresent(cty) then
    cty := ConnectorType.setPresent(cty);
    comp := Component.setConnectorType(cty, comp);
    InstNode.updateComponent(comp, node);
  end if;
end markComponentPresent;

function augmentExpandableConnector
  input Connector conn;
  input list<Connector> expandableSet;
  input output list<Variable> vars;
protected
  ComponentRef exp_name, elem_name;
  InstNode exp_node, comp_node, cls_node, node;
  Class cls;
  ClassTree cls_tree;
  Component comp;
  list<InstNode> nodes = {};
  Variable var;
  Type ty;
  ComplexType complex_ty;
algorithm
  exp_name := Connector.name(conn);
  exp_node := ComponentRef.node(exp_name);
  cls_node := InstNode.classScope(exp_node);
  cls := InstNode.getClass(cls_node);
  cls_tree := Class.classTree(cls);

  // Go through the union of elements the expandable connector should have.
  for c in expandableSet loop
    elem_name := Connector.name(c);
    node := ComponentRef.node(elem_name);

    try
      comp_node := ClassTree.lookupElement(InstNode.name(node), cls_tree);
    else
      comp_node := InstNode.EMPTY_NODE();
    end try;

    if InstNode.isEmpty(comp_node) then
      // If the element doesn't already exist, add it to the list of elements to be
      // added to the connector.
      nodes := node :: nodes;
      ty := c.ty;
      elem_name := ComponentRef.prefixCref(node, ty, {}, exp_name);
      // TODO: This needs more work, the new connector might be a complex connector.
      var := Variable.VARIABLE(elem_name, ty, NFBinding.EMPTY_BINDING,
        Visibility.PUBLIC, NFComponent.DEFAULT_ATTR, {},
        SOME(SCode.COMMENT(NONE(), SOME("virtual variable in expandable connector"))),
        ElementSource.getInfo(c.source));
      vars := var :: vars;
    else
      comp_node := ClassTree.lookupElement(InstNode.name(node), cls_tree);
      comp_node := InstNode.resolveInner(comp_node);

      if InstNode.isComponent(comp_node) then
        // If the element already exists and is a potentially present component,
        // change it to be present.
        markComponentPresent(comp_node);
      else
        Error.addInternalError(getInstanceName() + " got non-component element", sourceInfo());
      end if;
    end if;
  end for;

  if not listEmpty(nodes) then
    cls_tree := ClassTree.addElementsToFlatTree(nodes, cls_tree);
    cls := Class.setClassTree(cls_tree, cls);
  end if;

  // Create a normal non-expandable complex type for the augmented expandable connector.
  complex_ty := Typing.makeConnectorType(cls_tree, isExpandable = false);
  ty := Type.COMPLEX(cls_node, complex_ty);
  cls := Class.setType(ty, cls);
  InstNode.updateClass(cls, cls_node);
  InstNode.componentApply(exp_node, Component.setType, ty);
end augmentExpandableConnector;

function updateUndeclaredConnection
  input Connection conn;
  input output list<Connection> conns;
algorithm
  conns := conn :: conns;
end updateUndeclaredConnection;

function updateExpandableConnection
  input Connection conn;
  input output list<Connection> conns;
protected
  Connector c1, c2;
  Type ty1, ty2;
  MatchKind mk;
  Expression e1, e2;
algorithm
  Connection.CONNECTION(lhs = c1, rhs = c2) := conn;
  (c1, ty1) := updateExpandableConnector(c1);
  (c2, ty2) := updateExpandableConnector(c2);

  // Check that the types match now that the connectors have been augmented.
  e1 := Expression.CREF(ty1, Connector.name(c1));
  e2 := Expression.CREF(ty2, Connector.name(c2));
  (_, _, _, mk) := TypeCheck.matchExpressions(e1, ty1, e2, ty2, allowUnknown = true);

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessageAndFail(Error.INVALID_CONNECTOR_VARIABLE,
      {Expression.toString(e1), Expression.toString(e2)}, Connector.getInfo(c1));
  end if;

  conns := Connection.CONNECTION(c1, c2) :: conns;
end updateExpandableConnection;

function updateExpandableConnector
  input output Connector conn;
        output Type ty;
protected
  ComponentRef name;
algorithm
  Connector.CONNECTOR(name = name, ty = ty) := conn;
  name := ComponentRef.updateNodeType(name);
  ty := Type.setArrayElementType(ty, Type.arrayElementType(ComponentRef.nodeType(name)));
  conn := Connector.CONNECTOR(name, ty, conn.face, conn.cty, conn.source);
end updateExpandableConnector;

function updatePotentiallyPresentVariable
  input output Variable var;
algorithm
  if ConnectorType.isPotentiallyPresent(var.attributes.connectorType) then
    var.attributes := Component.getAttributes(InstNode.component(ComponentRef.node(var.name)));
  end if;
end updatePotentiallyPresentVariable;

annotation(__OpenModelica_Interface="frontend");
end NFExpandableConnectors;
