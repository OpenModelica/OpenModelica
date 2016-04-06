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

encapsulated package ConnectUtil
" file:        ConnectUtil.mo
  package:     ConnectUtil
  description: Connection set management


  Connections generate connection sets (datatype SET is described in Connect)
  which are constructed during instantiation.  When a connection
  set is generated, it is used to create a number of equations.
  The kind of equations created depends on the type of the set.

  ConnectUtil.mo is called from Inst.mo and is responsible for
  creation of all connect-equations later passed to the DAE module
  in DAEUtil.mo."

// public imports
public
import Absyn;
import SCode;
import ClassInf;
import Config;
import Connect;
import DAE;
import FCore;
import InnerOuter;
import Prefix;
import ConnectionGraph;

// protected imports
protected
import ComponentReference;
import DAEUtil;
import Debug;
import ElementSource;
import Error;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import Flags;
import List;
import Lookup;
import PrefixUtil;
import System;
import Types;
import Util;

// Import some types from Connect.
import Connect.Face;
import Connect.ConnectorType;
import Connect.ConnectorElement;
import Connect.SetTrieNode;
import Connect.SetTrie;
import Connect.SetConnection;
import Connect.OuterConnect;
import Connect.Sets;
import Connect.Set;

// Set graph represented as an adjacency list.
protected type SetGraph = array<list<Integer>>;

public function newSet
  "This function creates a 'new' set for the given prefix. This means that it
  makes a set with a new empty trie, but copies the set count and connection
  crefs from the old set. This is done because we don't need to propagate
  connections down in the instance hierarchy, but the list of connection crefs
  needs to be propagated to be able to evaluate the cardinality operator. See
  comments in addSet below for how the sets are merged later."
  input Prefix.Prefix prefix;
  input output Sets sets;
protected
  String pstr;
  Integer sc;
  DAE.ComponentRef cr;
algorithm
  Sets.SETS(setCount = sc) := sets;

  try
    cr := PrefixUtil.prefixFirstCref(prefix);
    pstr := ComponentReference.printComponentRefStr(cr);
  else
    cr := DAE.WILD();
    pstr := "";
  end try;

  sets := Sets.SETS(SetTrieNode.SET_TRIE_NODE(pstr, cr, {}, 0), sc, {}, {});
end newSet;

public function addSet
  "This function adds a child set to a parent set."
  input Sets parentSets;
  input Sets childSets;
  output Sets sets;
algorithm
  sets := matchcontinue(parentSets, childSets)
    local
      list<SetConnection> c1, c2;
      list<OuterConnect> o1, o2;
      Integer sc;
      SetTrieNode node;

    // If the child set is empty we don't need to add it.
    case (_, _) guard isEmptySet(childSets)
      then parentSets;

    // If both sets are nameless, i.e. a top scope set, just return the child
    // set as it is. This is to avoid getting nestled top scope sets in some
    // cases, and the child should be a superset of the parent.
    case (Sets.SETS(sets = SetTrieNode.SET_TRIE_NODE(cref = DAE.WILD())),
         Sets.SETS(sets = SetTrieNode.SET_TRIE_NODE(cref = DAE.WILD())))
      then childSets;

    // Check if the node already exists. In that case it's probably due to
    // multiple inheritance and we should ignore it.
    case (Sets.SETS(sets = node as SetTrieNode.SET_TRIE_NODE()),
          Sets.SETS())
      algorithm
        _ := setTrieGetNode(setTrieNodeName(childSets.sets), node.nodes);
      then
        parentSets;

    // In the normal case we add the trie on the child sets to the parent, and
    // also merge their lists of outer connects.
    case (Sets.SETS(node as SetTrieNode.SET_TRIE_NODE(), _, c1, o1),
          Sets.SETS(_, sc, c2, o2))
      algorithm
        c1 := listAppend(c2, c1);
        o1 := listAppend(o2, o1);
        node.nodes := childSets.sets :: node.nodes;
      then
        Sets.SETS(node, sc, c1, o1);

  end matchcontinue;
end addSet;

protected function isEmptySet
  "Check if a given set is empty."
  input Sets sets;
  output Boolean isEmpty;
algorithm
  isEmpty := match(sets)
    case Sets.SETS(sets = SetTrieNode.SET_TRIE_NODE(nodes = {}),
      connections = {}, outerConnects = {}) then true;
    else false;
  end match;
end isEmptySet;

public function addConnection
  "Adds a new connection by looking up both the given connector elements in the
   set trie and merging the sets together."
  input output Sets sets;
  input DAE.ComponentRef cref1;
  input Face face1;
  input DAE.ComponentRef cref2;
  input Face face2;
  input SCode.ConnectorType connectorType;
  input DAE.ElementSource source;
protected
  ConnectorElement e1, e2;
  ConnectorType ty;
algorithm
  ty := makeConnectorType(connectorType);
  e1 := findElement(cref1, face1, ty, source, sets);
  e2 := findElement(cref2, face2, ty, source, sets);
  sets := mergeSets(e1, e2, sets);
end addConnection;

protected function getConnectCount
  input DAE.ComponentRef cref;
  input SetTrie trie;
  output Integer count;
protected
  SetTrieNode node;
algorithm
  try
    node := setTrieGet(cref, trie, false);

    count := match node
      case SetTrieNode.SET_TRIE_NODE() then node.connectCount;
      case SetTrieNode.SET_TRIE_LEAF() then node.connectCount;
    end match;
  else
    count := 0;
  end try;
end getConnectCount;

public function addArrayConnection
  "Connects two arrays of connectors."
  input output Sets sets;
  input DAE.ComponentRef cref1;
  input Face face1;
  input DAE.ComponentRef cref2;
  input Face face2;
  input DAE.ElementSource source;
  input SCode.ConnectorType connectorType;
protected
  list<DAE.ComponentRef> crefs1, crefs2;
  DAE.ComponentRef cr2;
algorithm
  crefs1 := ComponentReference.expandCref(cref1, false);
  crefs2 := ComponentReference.expandCref(cref2, false);

  for cr1 in crefs1 loop
    cr2 :: crefs2 := crefs2;
    sets := addConnection(sets, cr1, face1, cr2, face2, connectorType, source);
  end for;
end addArrayConnection;

protected function makeConnectorType
  "Creates a connector type from the flow or stream prefix given."
  input SCode.ConnectorType connectorType;
  output ConnectorType ty;
algorithm
  ty := match(connectorType)
    case SCode.POTENTIAL() then ConnectorType.EQU();
    case SCode.FLOW() then ConnectorType.FLOW();
    case SCode.STREAM() then ConnectorType.STREAM(NONE());
    else
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {"ConnectUtil.makeConnectorType: invalid connector type."});
      then
        fail();
  end match;
end makeConnectorType;

public function addConnectorVariablesFromDAE
  "If the class state indicates a connector, this function adds all flow
  variables in the dae as inside connectors to the connection sets."
  input Boolean ignore;
  input ClassInf.State classState;
  input Prefix.Prefix prefix;
  input list<DAE.Var> vars;
  input SourceInfo info;
  input DAE.ElementSource elementSource;
  input output Sets sets;
algorithm
  sets := match classState
    local
      Absyn.Path class_path;
      list<DAE.Var> streams, flows;

    case ClassInf.CONNECTOR(path = class_path, isExpandable = false) guard not ignore
      algorithm
        // Check balance of non expandable connectors.
        checkConnectorBalance(vars, class_path, info);

        // Add flow variables as inside connectors, unless disabled by flag.
        if not Flags.isSet(Flags.DISABLE_SINGLE_FLOW_EQ) then
          (flows, streams) := getStreamAndFlowVariables(vars);
          sets := List.fold2(flows, addFlowVariableFromDAE, elementSource, prefix, sets);
          sets := addStreamFlowAssociations(sets, prefix, streams, flows);
        end if;
      then
        sets;

    else sets;
  end match;
end addConnectorVariablesFromDAE;

protected function addFlowVariableFromDAE
  "Adds a flow variable from the DAE to the sets as an inside flow variable."
  input DAE.Var variable;
  input DAE.ElementSource elementSource;
  input Prefix.Prefix prefix;
  input output Sets sets;
protected
  list<DAE.ComponentRef> crefs;
algorithm
  crefs := daeVarToCrefs(variable);

  for cr in crefs loop
    sets := addInsideFlowVariable(sets, cr, elementSource, prefix);
  end for;
end addFlowVariableFromDAE;

public function isExpandable
  input DAE.ComponentRef name;
  output Boolean expandableConnector;
algorithm
  expandableConnector := match(name)
    case DAE.CREF_IDENT()
      then Types.isExpandableConnector(name.identType);

    case DAE.CREF_QUAL()
      then Types.isExpandableConnector(name.identType) or
           isExpandable(name.componentRef);

    else false;

  end match;
end isExpandable;

protected function daeHasExpandableConnectors
  "Checks if a DAE contains any expandable connectors."
  input DAE.DAElist DAE;
  output Boolean hasExpandable;
protected
  list<DAE.Element> vars;
algorithm
  if System.getHasExpandableConnectors() then
    DAE.DAE(vars) := DAE;
    hasExpandable := List.exist(vars, isVarExpandable);
  else
    hasExpandable := false;
  end if;
end daeHasExpandableConnectors;

protected function isVarExpandable
  input DAE.Element var;
  output Boolean isExpandable;
algorithm
  isExpandable := match var
    case DAE.VAR() then isExpandable(var.componentRef);
    else false;
  end match;
end isVarExpandable;

protected function getExpandableVariablesWithNoBinding
  "@author: adrpo
   Goes through a list of expandable variables
   THAT HAVE NO BINDING and returns their crefs"
  input list<DAE.Element> variables;
  output list<DAE.ComponentRef> potential = {};
protected
  DAE.ComponentRef name;
algorithm
  for var in variables loop
    _ := match var
      // do not return the ones that have a binding as they are used
      // TODO: actually only if their binding is not another expandable??!!
      case DAE.VAR(componentRef = name, binding = NONE())
        algorithm
          if isExpandable(name) then
            potential := name :: potential;
          end if;
        then
          ();

      else ();
    end match;
  end for;
end getExpandableVariablesWithNoBinding;

protected function getStreamAndFlowVariables
  "Goes through a list of variables and filters out all flow and stream
   variables into separate lists."
  input list<DAE.Var> variables;
  output list<DAE.Var> flows = {};
  output list<DAE.Var> streams = {};
algorithm
  for var in variables loop
    _ := match var
      case DAE.TYPES_VAR(attributes = DAE.ATTR(connectorType = SCode.FLOW()))
        algorithm
          flows := var :: flows;
        then
          ();

      case DAE.TYPES_VAR(attributes = DAE.ATTR(connectorType = SCode.STREAM()))
        algorithm
          streams := var :: streams;
        then
          ();

      else ();
    end match;
  end for;
end getStreamAndFlowVariables;

protected function addStreamFlowAssociations
  "Adds information to the connection sets about which flow variables each
  stream variable is associated to."
  input output Sets sets;
  input Prefix.Prefix prefix;
  input list<DAE.Var> streamVars;
  input list<DAE.Var> flowVars;
protected
  DAE.Var flow_var;
  DAE.ComponentRef flow_cr;
  list<DAE.ComponentRef> stream_crs;
algorithm
  // No stream variables => not a stream connector.
  if listEmpty(streamVars) then
    return;
  end if;

  // Stream variables and exactly one flow => add associations.
  {flow_var} := flowVars;
  {flow_cr} := daeVarToCrefs(flow_var);
  flow_cr := PrefixUtil.prefixCrefNoContext(prefix, flow_cr);

  for stream_var in streamVars loop
    stream_crs := daeVarToCrefs(stream_var);

    for stream_cr in stream_crs loop
      sets := addStreamFlowAssociation(stream_cr, flow_cr, sets);
    end for;
  end for;
end addStreamFlowAssociations;

protected function daeVarToCrefs
  "Converts a DAE.Var to a list of crefs."
  input DAE.Var var;
  output list<DAE.ComponentRef> crefs;
protected
  String name;
  DAE.Type ty;
  list<DAE.ComponentRef> crs;
  DAE.Dimensions dims;
  DAE.ComponentRef cr;
algorithm
  DAE.TYPES_VAR(name = name, ty = ty) := var;
  ty := Types.derivedBasicType(ty);

  crefs := match ty
    // Scalar
    case DAE.T_REAL() then {DAE.CREF_IDENT(name, ty, {})};

    // Complex type
    case DAE.T_COMPLEX()
      algorithm
        crs := listAppend(daeVarToCrefs(v) for v in listReverse(ty.varLst));
        cr := DAE.CREF_IDENT(name, DAE.T_REAL_DEFAULT, {});
      then
        list(ComponentReference.joinCrefs(cr, c) for c in crs);

    // Array
    case DAE.T_ARRAY()
      algorithm
        dims := Types.getDimensions(ty);
        cr := DAE.CREF_IDENT(name, ty, {});
      then
        expandArrayCref(cr, dims);

    else
      algorithm
        Error.addInternalError("Unknown var " + name +
          " in ConnectUtil.daeVarToCrefs", sourceInfo());
      then
        fail();

  end match;
end daeVarToCrefs;

protected function expandArrayCref
  "This function takes an array cref and a list of dimensions, and generates all
  scalar crefs by expanding the dimensions into subscripts."
  input DAE.ComponentRef cref;
  input DAE.Dimensions dims;
  input list<DAE.ComponentRef> accumCrefs = {};
  output list<DAE.ComponentRef> crefs;
algorithm
  crefs := matchcontinue dims
    local
      DAE.Dimension dim;
      DAE.Dimensions rest_dims;
      DAE.Exp idx;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;

    case {} then cref :: accumCrefs;

    case dim :: rest_dims
      algorithm
        (idx, dim) := getNextIndex(dim);
        cr := ComponentReference.subscriptCref(cref, {DAE.INDEX(idx)});
        crs := expandArrayCref(cr, rest_dims, accumCrefs);
        crs := expandArrayCref(cref, dim :: rest_dims, crs);
      then
        crs;

    else accumCrefs;

  end matchcontinue;
end expandArrayCref;

protected function reverseEnumType
  "Reverses the order of the literals in an enumeration dimension, or just
  returns the given dimension if it's not an enumeration. This is used by
  getNextIndex that starts from the end, so that it can take the first literal
  in the list instead of the last (more efficient)."
  input output DAE.Dimension dim;
algorithm
  _ := match dim
    case DAE.DIM_ENUM()
      algorithm
        dim.literals := listReverse(dim.literals);
      then
        ();

    else ();
  end match;
end reverseEnumType;

protected function getNextIndex
  "Returns the next index given a dimension, and updates the dimension. Fails
  when there are no indices left."
  input DAE.Dimension dim;
  output DAE.Exp nextIndex;
  output DAE.Dimension restDim;
algorithm
  (nextIndex, restDim) := match dim
    local
      Integer new_idx, dim_size;
      Absyn.Path p, ep;
      String l;
      list<String> l_rest;

    case DAE.DIM_INTEGER(integer = 0) then fail();
    case DAE.DIM_ENUM(size = 0) then fail();

    case DAE.DIM_INTEGER(integer = new_idx)
      algorithm
        dim_size := new_idx - 1;
      then
        (DAE.ICONST(new_idx), DAE.DIM_INTEGER(dim_size));

    // Assumes that the enum has been reversed with reverseEnumType.
    case DAE.DIM_ENUM(p, l :: l_rest, new_idx)
      algorithm
        ep := Absyn.joinPaths(p, Absyn.IDENT(l));
        dim_size := new_idx - 1;
      then
        (DAE.ENUM_LITERAL(ep, new_idx), DAE.DIM_ENUM(p, l_rest, dim_size));
  end match;
end getNextIndex;

protected function addInsideFlowVariable
  "Adds a single inside flow variable to the connection sets."
  input output Sets sets;
  input DAE.ComponentRef cref;
  input DAE.ElementSource source;
  input Prefix.Prefix prefix;
protected
  ConnectorElement e;
algorithm
  try
    // Check if it exists in the sets already.
    setTrieGetElement(cref, Face.INSIDE(), sets.sets);
  else
    // Otherwise, add a new set for it.
    sets.setCount := sets.setCount + 1;
    e := newElement(cref, Face.INSIDE(), ConnectorType.FLOW(), source, sets.setCount);
    sets.sets := setTrieAdd(e, sets.sets);
  end try;
end addInsideFlowVariable;

protected function addStreamFlowAssociation
  "Adds an association between a stream variable and a flow."
  input DAE.ComponentRef streamCref;
  input DAE.ComponentRef flowCref;
  input output Sets sets;
algorithm
  sets := updateSetLeaf(sets, streamCref, flowCref, addStreamFlowAssociation2);
end addStreamFlowAssociation;

protected function addStreamFlowAssociation2
  "Helper function to addSTreamFlowAssocication, sets the flow association in a
   leaf node."
  input DAE.ComponentRef flowCref;
  input output SetTrieNode node;
algorithm
  _ := match node
    case SetTrieNode.SET_TRIE_LEAF()
      algorithm
        node.flowAssociation := SOME(flowCref);
      then
        ();
  end match;
end addStreamFlowAssociation2;

protected function getStreamFlowAssociation
  "Returns the associated flow variable for a stream variable."
  input DAE.ComponentRef streamCref;
  input Sets sets;
  output DAE.ComponentRef flowCref;
algorithm
  SetTrieNode.SET_TRIE_LEAF(flowAssociation = SOME(flowCref)) :=
    setTrieGet(streamCref, sets.sets, false);
end getStreamFlowAssociation;

public function addOuterConnection
  "Adds a connection with a reference to an outer connector These are added to a
   special list, such that they can be moved up in the instance hierarchy to a
   place where both instances are defined."
  input Prefix.Prefix scope;
  input output Sets sets;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Face f1;
  input Face f2;
  input DAE.ElementSource source;
protected
  OuterConnect new_oc;
algorithm
  // Only add a new outer connection if it doesn't already exist in the list.
  if not List.exist2(sets.outerConnects, outerConnectionMatches, cr1, cr2) then
    new_oc := OuterConnect.OUTERCONNECT(scope, cr1, io1, f1, cr2, io2, f2, source);
    sets.outerConnects := new_oc :: sets.outerConnects;
  end if;
end addOuterConnection;

protected function outerConnectionMatches
  "Returns true if Connect.OuterConnect matches the two component references
  passed as argument."
  input OuterConnect oc;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean matches;
algorithm
  matches := match oc
    case OuterConnect.OUTERCONNECT()
      then ComponentReference.crefEqual(oc.cr1,cr1) and ComponentReference.crefEqual(oc.cr2,cr2) or
           ComponentReference.crefEqual(oc.cr1,cr2) and ComponentReference.crefEqual(oc.cr2,cr1);
  end match;
end outerConnectionMatches;

public function addOuterConnectToSets
  "Adds an outer connection to all sets where a corresponding inner definition
  is present. For instance, if a connection set contains {world.v, topPin.v} and
  we have an outer connection connect(world, a2.aPin), the connection is added
  to the sets, resulting in {world.v, topPin.v, a2.aPin.v}. Returns the updated
  sets and a boolean that indicates if anything was added or not."
  input DAE.ComponentRef cref1;
  input DAE.ComponentRef cref2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Face face1;
  input Face face2;
  input output Sets sets;
  input SourceInfo inInfo;
  output Boolean added;
protected
  Boolean is_outer1, is_outer2;
algorithm
  is_outer1 := Absyn.isOuter(io1);
  is_outer2 := Absyn.isOuter(io2);

  added := match(is_outer1, is_outer2)
    // Both are outer => error.
    case (true, true)
      algorithm
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,
          {"Connections where both connectors are outer references", "No suggestion"}, inInfo);
      then
        false;

    // Both are inner => do nothing.
    case (false, false) then false;

    // The first is outer and the second inner, call addOuterConnectToSets2.
    case (true, false)
      algorithm
        (sets, added) := addOuterConnectToSets2(cref1, cref2, face1, face2, sets);
      then
        added;

    // The first is inner and the second outer, call addOuterConnectToSets2 with
    // reversed order on the components compared to above.
    case (false, true)
      algorithm
        (sets, added) := addOuterConnectToSets2(cref2, cref1, face2, face1, sets);
      then
        added;
  end match;
end addOuterConnectToSets;

protected function addOuterConnectToSets2
  "Helper function to addOuterConnectToSets. Tries to add connections between
   the inner and outer components."
  input DAE.ComponentRef outerCref;
  input DAE.ComponentRef innerCref;
  input Face outerFace;
  input Face innerFace;
  input output Sets sets;
  output Boolean added;
protected
  SetTrieNode node;
  list<ConnectorElement> outer_els, inner_els;
  Integer sc;
algorithm
  try
    // Find the trie node for the outer component.
    node := setTrieGet(outerCref, sets.sets, true);
    // Collect all connector elements in the node.
    outer_els := collectOuterElements(node, outerFace);
    // Find or create inner elements corresponding to the outer elements.
    inner_els := list(findInnerElement(oe, innerCref, innerFace, sets) for oe in outer_els);
    // Merge the inner and outer sets pairwise from the two lists.
    sc := sets.setCount;
    sets := List.threadFold(outer_els, inner_els, mergeSets, sets);
    // Check if the number of sets changed.
    added := sc <> sets.setCount;
  else
    added := false;
  end try;
end addOuterConnectToSets2;

protected function collectOuterElements
  "Collects all connector elements with a certain face from a trie node."
  input SetTrieNode node;
  input Face face;
  output list<ConnectorElement> outerElements;
algorithm
  outerElements := match node
    case SetTrieNode.SET_TRIE_NODE()
      then List.map2Flat(node.nodes, collectOuterElements2, face, NONE());

    else collectOuterElements2(node, face, NONE());
  end match;
end collectOuterElements;

protected function collectOuterElements2
  "Helper function to collectOuterElements."
  input SetTrieNode node;
  input Face face;
  input Option<DAE.ComponentRef> prefix;
  output list<ConnectorElement> outerElements;
algorithm
  outerElements := match node
    local
      DAE.ComponentRef cr;
      list<SetTrieNode> nodes;
      ConnectorElement e;

    case SetTrieNode.SET_TRIE_NODE(cref = cr)
      algorithm
        cr := optPrefixCref(prefix, cr);
      then
        List.map2Flat(node.nodes, collectOuterElements2, face, SOME(cr));

    case SetTrieNode.SET_TRIE_LEAF()
      algorithm
        e := setTrieGetLeafElement(node, face);
        cr := getElementName(e);
        e := setElementName(e, optPrefixCref(prefix, cr));
      then
        {e};

  end match;
end collectOuterElements2;

protected function findInnerElement
  "Finds or creates an inner element based on a given outer element."
  input ConnectorElement outerElement;
  input DAE.ComponentRef innerCref;
  input Face innerFace;
  input Sets sets;
  output ConnectorElement innerElement;
protected
  DAE.ComponentRef name;
  ConnectorType ty;
  DAE.ElementSource src;
algorithm
  ConnectorElement.CONNECTOR_ELEMENT(name = name, ty = ty, source = src) := outerElement;
  name := ComponentReference.joinCrefs(innerCref, name);
  innerElement := findElement(name, innerFace, ty, src, sets);
end findInnerElement;

protected function optPrefixCref
  "Appends an optional prefix to a cref."
  input Option<DAE.ComponentRef> prefix;
  input output DAE.ComponentRef cref;
algorithm
  cref := match prefix
    local
      DAE.ComponentRef cr;

    case NONE() then cref;
    case SOME(cr) then ComponentReference.joinCrefs(cr, cref);

  end match;
end optPrefixCref;

protected function findElement
  "Tries to find a connector element in the sets given a cref and a face. If no
   element can be found it creates a new one."
  input DAE.ComponentRef cref;
  input Face face;
  input ConnectorType ty;
  input DAE.ElementSource source;
  input Sets sets;
  output ConnectorElement element;
algorithm
  try
    element := setTrieGetElement(cref, face, sets.sets);
  else
    element := newElement(cref, face, ty, source, Connect.NEW_SET);
  end try;
end findElement;

protected function newElement
  "Creates a new connector element."
  input DAE.ComponentRef cref;
  input Face face;
  input ConnectorType ty;
  input DAE.ElementSource source;
  input Integer set;
  output ConnectorElement element;
algorithm
  element := ConnectorElement.CONNECTOR_ELEMENT(cref, face, ty, source, set);
end newElement;

protected function isNewElement
  "Checks if the element is new, i.e. hasn't been assigned to a set yet."
  input ConnectorElement element;
  output Boolean isNew;
protected
  Integer set;
algorithm
  ConnectorElement.CONNECTOR_ELEMENT(set = set) := element;
  isNew := set == Connect.NEW_SET;
end isNewElement;

protected function getElementSetIndex
  "Returns the set index of a connector element."
  input ConnectorElement inElement;
  output Integer outIndex;
algorithm
  ConnectorElement.CONNECTOR_ELEMENT(set = outIndex) := inElement;
end getElementSetIndex;

protected function setElementSetIndex
  "Sets the set index of a connector element."
  input output ConnectorElement element;
  input Integer index;
algorithm
  element.set := index;
end setElementSetIndex;

protected function getElementName
  "Returns the name of a connector element."
  input ConnectorElement element;
  output DAE.ComponentRef name;
algorithm
  ConnectorElement.CONNECTOR_ELEMENT(name = name) := element;
end getElementName;

protected function setElementName
  "Sets the name of a connector element."
  input output ConnectorElement element;
  input DAE.ComponentRef name;
algorithm
  element.name := name;
end setElementName;

protected function getElementSource
  "Returns the element source of a connector element."
  input ConnectorElement element;
  output DAE.ElementSource source;
algorithm
  ConnectorElement.CONNECTOR_ELEMENT(source = source) := element;
end getElementSource;

protected function setTrieNewLeaf
  "Creates a new trie leaf."
  input String id;
  input ConnectorElement element;
  output SetTrieNode leaf;
algorithm
  leaf := match element
    case ConnectorElement.CONNECTOR_ELEMENT(face = Face.INSIDE())
      then SetTrieNode.SET_TRIE_LEAF(id, SOME(element), NONE(), NONE(), 0);

    case ConnectorElement.CONNECTOR_ELEMENT(face = Face.OUTSIDE())
      then SetTrieNode.SET_TRIE_LEAF(id, NONE(), SOME(element), NONE(), 0);

  end match;
end setTrieNewLeaf;

protected function setTrieNewNode
  "Creates a new trie node."
  input DAE.ComponentRef cref;
  input ConnectorElement element;
  output SetTrieNode node;
algorithm
  node := match cref
    local
      String id;
      DAE.ComponentRef cr;

    // A simple identifier, just create a new leaf.
    case DAE.CREF_IDENT()
      algorithm
        id := ComponentReference.printComponentRefStr(cref);
      then
        setTrieNewLeaf(id, setElementName(element, cref));

    // A qualified identifier, call this function recursively.
    // I.e. a.b.c becomes NODE(a, {NODE(b, {NODE(c)})});
    case DAE.CREF_QUAL()
      algorithm
        cr := ComponentReference.crefFirstCref(cref);
        id := ComponentReference.printComponentRefStr(cr);
        node := setTrieNewNode(cref.componentRef, element);
      then
        SetTrieNode.SET_TRIE_NODE(id, cr, {node}, 0);

  end match;
end setTrieNewNode;

protected function setTrieNodeName
  input SetTrieNode node;
  output String name;
algorithm
  name := match node
    case SetTrieNode.SET_TRIE_NODE() then node.name;
    case SetTrieNode.SET_TRIE_LEAF() then node.name;
  end match;
end setTrieNodeName;

protected function mergeSets
  "Merges two sets."
  input ConnectorElement element1;
  input ConnectorElement element2;
  input output Sets sets;
protected
  Boolean new1, new2;
algorithm
  new1 := isNewElement(element1);
  new2 := isNewElement(element2);
  sets := mergeSets2(element1, element2, new1, new2, sets);
end mergeSets;

protected function mergeSets2
  "Helper function to mergeSets, dispatches to the correct function based on if
   the elements are new or not."
  input ConnectorElement element1;
  input ConnectorElement element2;
  input Boolean isNew1;
  input Boolean isNew2;
  input output Sets sets;
algorithm
  sets := match(isNew1, isNew2)
    // Both elements are new, add them to a new set.
    case (true, true) then addNewSet(element1, element2, sets);

    // The first is new and the second old, add the first to the same set as the
    // second.
    case (true, false) then addToSet(element1, element2, sets);

    // The second is new and the first old, add the second to the same set as
    // the first.
    case (false, true) then addToSet(element2, element1, sets);

    // Both sets are old, add a connection between their sets.
    case (false, false) then connectSets(element1, element2, sets);
  end match;
end mergeSets2;

protected function addNewSet
  "Adds a new set containing the given two elements to the sets."
  input ConnectorElement element1;
  input ConnectorElement element2;
  input output Sets sets;
protected
  SetTrie node;
  Integer sc;
  ConnectorElement e1, e2;
algorithm
  sc := sets.setCount + 1;
  e1 := setElementSetIndex(element1, sc);
  e2 := setElementSetIndex(element2, sc);
  node := sets.sets;
  node := setTrieAdd(e1, node);
  sets.sets := setTrieAdd(e2, node);
  sets.setCount := sc;
end addNewSet;

protected function addToSet
  "Adds the first connector element to the same set as the second."
  input ConnectorElement element;
  input ConnectorElement set;
  input output Sets sets;
protected
  Integer index;
  ConnectorElement e;
algorithm
  index := getElementSetIndex(set);
  e := setElementSetIndex(element, index);
  sets.sets := setTrieAdd(e, sets.sets);
end addToSet;

protected function connectSets
  "Connects two sets."
  input ConnectorElement element1;
  input ConnectorElement element2;
  input output Sets sets;
protected
  Integer set1, set2;
algorithm
  set1 := getElementSetIndex(element1);
  set2 := getElementSetIndex(element2);

  // Add a new connection if the elements don't belong to the same set already.
  if set1 <> set2 then
    sets.connections := (set1, set2) :: sets.connections;
  end if;
end connectSets;

protected function setTrieGetElement
  "Fetches a connector element from the trie given a cref and a face."
  input DAE.ComponentRef cref;
  input Face face;
  input SetTrie trie;
  output ConnectorElement element;
protected
  SetTrieNode node;
algorithm
  node := setTrieGet(cref, trie, false);
  element := setTrieGetLeafElement(node, face);
end setTrieGetElement;

protected function setTrieAddLeafElement
  "Adds a connector element to a trie leaf."
  input ConnectorElement element;
  input output SetTrieNode node;
algorithm
  _ := match node
    case SetTrieNode.SET_TRIE_LEAF()
      algorithm
        _ := match element.face
          case Face.INSIDE()
            algorithm
              node.insideElement := SOME(element);
            then
              ();

          case Face.OUTSIDE()
            algorithm
              node.outsideElement := SOME(element);
            then
              ();
        end match;
      then
        ();
  end match;
end setTrieAddLeafElement;

protected function setTrieGetLeafElement
  "Returns the connector element of a trie leaf, given a face."
  input SetTrieNode node;
  input Face face;
  output ConnectorElement element;
algorithm
  element := match(face, node)
    local
      ConnectorElement e;

    case (Face.INSIDE(), SetTrieNode.SET_TRIE_LEAF(insideElement = SOME(e))) then e;
    case (Face.OUTSIDE(), SetTrieNode.SET_TRIE_LEAF(outsideElement = SOME(e))) then e;
  end match;
end setTrieGetLeafElement;

protected function setTrieAdd
  "Adds a connector element to the trie."
  input ConnectorElement element;
  input output SetTrie trie;
protected
  DAE.ComponentRef cref, el_cr;
  ConnectorElement el;
algorithm
  cref := getElementName(element);
  el_cr := ComponentReference.crefLastCref(cref);
  el := setElementName(element, el_cr);
  trie := setTrieUpdate(cref, el, trie, setTrieAddLeafElement);
end setTrieAdd;

protected function updateSetLeaf<Arg>
  "Updates a trie leaf in the sets with the given update function."
  input output Sets sets;
  input DAE.ComponentRef cref;
  input Arg arg;
  input UpdateFunc updateFunc;

  partial function UpdateFunc
    input Arg arg;
    input output SetTrieNode node;
  end UpdateFunc;
algorithm
  sets.sets := setTrieUpdate(cref, arg, sets.sets, updateFunc);
end updateSetLeaf;

protected function setTrieUpdate<Arg>
  "Updates a trie leaf in the trie with the given update function."
  input DAE.ComponentRef cref;
  input Arg arg;
  input output SetTrie trie;
  input UpdateFunc updateFunc;

  partial function UpdateFunc
    input Arg arg;
    input output SetTrieNode node;
  end UpdateFunc;
algorithm
  _ := match(cref, trie)
    local
      String id;

    case (DAE.CREF_QUAL(), SetTrieNode.SET_TRIE_NODE())
      algorithm
        id := ComponentReference.printComponentRef2Str(cref.ident, cref.subscriptLst);
        trie.nodes := setTrieUpdateNode(id, cref, cref.componentRef, arg, updateFunc, trie.nodes);
      then
        ();

    case (DAE.CREF_IDENT(), SetTrieNode.SET_TRIE_NODE())
      algorithm
        id := ComponentReference.printComponentRef2Str(cref.ident, cref.subscriptLst);
        trie.nodes := setTrieUpdateLeaf(id, arg, trie.nodes, updateFunc);
      then
        ();

  end match;
end setTrieUpdate;

protected function setTrieUpdateNode<Arg>
  "Helper function to setTrieUpdate, updates a node in the trie."
  input String id;
  input DAE.ComponentRef wholeCref;
  input DAE.ComponentRef cref;
  input Arg arg;
  input UpdateFunc updateFunc;
  input output list<SetTrieNode> nodes;

  partial function UpdateFunc
    input Arg arg;
    input output SetTrieNode node;
  end UpdateFunc;
protected
  SetTrieNode node2;
  Integer n=1;
algorithm
  for node in nodes loop
    if setTrieIsNode(node) and setTrieNodeName(node) == id then
      node2 := setTrieUpdate(cref, arg, node, updateFunc);
      nodes := List.replaceAt(node2, n, nodes); // Can be slow in memory and time
      return;
    else
      n := n+1;
    end if;
  end for;

  nodes := setTrieUpdateNode2(wholeCref, arg, updateFunc, nodes);
end setTrieUpdateNode;

protected function setTrieUpdateNode2<Arg>
  "Helper function to setTrieUpdateNode."
  input DAE.ComponentRef cref;
  input Arg arg;
  input UpdateFunc updateFunc;
  input output list<SetTrieNode> nodes;

  partial function UpdateFunc
    input Arg arg;
    input output SetTrieNode node;
  end UpdateFunc;
algorithm
  nodes := match cref
    local
      String id;
      DAE.ComponentRef cr, rest_cr;
      SetTrieNode node;
      list<SetTrieNode> child_nodes;

    case DAE.CREF_IDENT()
      algorithm
        id := ComponentReference.printComponentRefStr(cref);
        node := SetTrieNode.SET_TRIE_LEAF(id, NONE(), NONE(), NONE(), 0);
        node := updateFunc(arg, node);
      then
        node :: nodes;

    case DAE.CREF_QUAL()
      algorithm
        cr := ComponentReference.crefFirstCref(cref);
        id := ComponentReference.printComponentRefStr(cr);
        child_nodes := setTrieUpdateNode2(cref.componentRef, arg, updateFunc, {});
      then
        SetTrieNode.SET_TRIE_NODE(id, cr, child_nodes, 0) :: nodes;

  end match;
end setTrieUpdateNode2;

protected function setTrieUpdateLeaf<Arg>
  "Helper funtion to setTrieUpdate, updates a trie leaf."
  input String id;
  input Arg arg;
  input output list<SetTrieNode> nodes;
  input UpdateFunc updateFunc;

  partial function UpdateFunc
    input Arg arg;
    input output SetTrieNode node;
  end UpdateFunc;
protected
  Integer n = 1;
algorithm
  for node in nodes loop
    if setTrieNodeName(node) == id then
      // Found matching leaf, update it.
      nodes := List.replaceAt(updateFunc(arg, node), n, nodes); // Can be slow in time and memory...
      return;
    end if;

    n := n+1;
  end for;

  // Is slow in time; need to do a linear search. Cheap in memory (single cons)
  nodes := updateFunc(arg, Connect.SET_TRIE_LEAF(id, NONE(), NONE(), NONE(), 0)) :: nodes;
end setTrieUpdateLeaf;

public function traverseSets<Arg>
  "Traverses the trie leaves in a sets."
  input output Sets sets;
  input output Arg arg;
  input UpdateFunc updateFunc;

  partial function UpdateFunc
    input output SetTrieNode node;
    input output Arg arg;
  end UpdateFunc;
protected
  SetTrieNode node;
algorithm
  (node, arg) := setTrieTraverseLeaves(sets.sets, updateFunc, arg);
  sets.sets := node;
end traverseSets;

protected function setTrieTraverseLeaves<Arg>
  "Traverses the leaves of a trie."
  input output SetTrieNode node;
  input UpdateFunc updateFunc;
  input output Arg arg;

  partial function UpdateFunc
    input output SetTrieNode node;
    input output Arg arg;
  end UpdateFunc;
algorithm
  _ := match node
    local
      list<SetTrieNode> nodes;

    case SetTrieNode.SET_TRIE_NODE()
      algorithm
        (nodes, arg) := List.map1Fold(node.nodes, setTrieTraverseLeaves, updateFunc, arg);
        node.nodes := nodes;
      then
        ();

     case SetTrieNode.SET_TRIE_LEAF()
       algorithm
         (node, arg) := updateFunc(node, arg);
       then
         ();

  end match;
end setTrieTraverseLeaves;

protected function setTrieGet
  "Fetches a node from the trie given a cref to search for. If inMatchPrefix is
  true it also matches a prefix of the cref if the full cref couldn't be found."
  input DAE.ComponentRef cref;
  input SetTrie trie;
  input Boolean matchPrefix;
  output SetTrieNode leaf;
protected
  list<SetTrieNode> nodes;
  String subs_str, id_subs, id_nosubs;
  SetTrieNode node;
algorithm
  SetTrieNode.SET_TRIE_NODE(nodes = nodes) := trie;

  id_nosubs := ComponentReference.crefFirstIdent(cref);
  subs_str := List.toString(ComponentReference.crefFirstSubs(cref),
    ExpressionDump.printSubscriptStr, "", "[", ",", "]", false);
  id_subs := id_nosubs + subs_str;

  try
    // Try to look up the identifier with subscripts, in case single array
    // elements have been added to the trie.
    leaf := setTrieGetNode(id_subs, nodes);
  else
    // If the above fails, try again without the subscripts in case a whole
    // array has been added to the trie.
    leaf := setTrieGetNode(id_nosubs, nodes);
  end try;

  // If the cref is qualified, continue to look up the rest of the cref in node
  // we just found.
  if not ComponentReference.crefIsIdent(cref) then
    try
      leaf := setTrieGet(ComponentReference.crefRest(cref), leaf, matchPrefix);
    else
      // Look up failed, return the previously found node if prefix matching is
      // turned on and the node we found is a leaf.
      true := matchPrefix and not setTrieIsNode(leaf);
    end try;
  end if;
end setTrieGet;

protected function setTrieGetNode
  "Returns a node with a given name from a list of nodes, or fails if no such
  node exists in the list."
  input String id;
  input list<SetTrieNode> nodes;
  output SetTrieNode node;
algorithm
  node := List.getMemberOnTrue(id, nodes, setTrieNodeNamed);
end setTrieGetNode;

protected function setTrieNodeNamed
  "Returns true if the given node has the same name as the given string,
  otherwise false."
  input String id;
  input SetTrieNode node;
  output Boolean isNamed;
algorithm
  isNamed := match node
    case SetTrieNode.SET_TRIE_NODE() then id == node.name;
    case SetTrieNode.SET_TRIE_LEAF() then id == node.name;
    else false;
  end match;
end setTrieNodeNamed;

protected function setTrieGetLeaf
  "Returns a leaf node with a given name from a list of nodes, or fails if no
  such node exists in the list."
  input String id;
  input list<SetTrieNode> nodes;
  output SetTrieNode node;
algorithm
  node := List.getMemberOnTrue(id, nodes, setTrieLeafNamed);
end setTrieGetLeaf;

protected function setTrieLeafNamed
  "Returns true if the given leaf node has the same name as the given string,
  otherwise false."
  input String id;
  input SetTrieNode node;
  output Boolean isNamed;
algorithm
  isNamed := match node
    case SetTrieNode.SET_TRIE_LEAF() then id == node.name;
    else false;
  end match;
end setTrieLeafNamed;

protected function setTrieIsNode
  input SetTrieNode node;
  output Boolean isNode;
algorithm
  isNode := match node
    case SetTrieNode.SET_TRIE_NODE() then true;
    else false;
  end match;
end setTrieIsNode;

public function equations
  "Generates equations from a connection set and evaluates stream operators if
  called from the top scope, otherwise does nothing."
  input Boolean topScope;
  input Sets sets;
  input output DAE.DAElist DAE;
  input ConnectionGraph.ConnectionGraph connectionGraph;
  input String modelNameQualified;
protected
  list<Set> set_list;
  array<Set> set_array;
  DAE.DAElist dae, dae2;
  Boolean has_stream, has_expandable, has_cardinality;
  ConnectionGraph.DaeEdges broken, connected;
algorithm
  if not topScope then
    return;
  end if;

  //print(printSetsStr(inSets) + "\n");
  set_array := generateSetArray(sets);
  set_list := arrayList(set_array);
  //print("Sets:\n");
  //print(stringDelimitList(List.map(sets, printSetStr), "\n") + "\n");

  if daeHasExpandableConnectors(DAE) then
    (set_list, dae) := removeUnusedExpandableVariablesAndConnections(set_list, DAE);
  else
    dae := DAE;
  end if;

  // send in the connection graph and build the connected/broken connects
  // we do this here so we do it once and not for every EQU set.
  (dae, connected, broken) := ConnectionGraph.handleOverconstrainedConnections(
    connectionGraph, modelNameQualified, dae);

  // adrpo: FIXME: maybe we should just remove them from the sets then send the
  // updates sets further
  dae2 := equationsDispatch(listReverse(set_list), connected, broken);
  DAE := DAEUtil.joinDaes(dae, dae2);
  DAE := evaluateConnectionOperators(sets, set_array, DAE);
  // add the equality constraint equations to the dae.
  DAE := ConnectionGraph.addBrokenEqualityConstraintEquations(DAE, broken);
end equations;

protected function getExpandableEquSetsAsCrefs
"@author: adrpo
 returns only the sets containing expandable connectors"
  input list<Set> sets;
  output list<list<DAE.ComponentRef>> crefSets = {};
protected
  list<DAE.ComponentRef> cref_set;
algorithm
  for set in sets loop
    _ := match set
      case Set.SET(ty = ConnectorType.EQU())
        algorithm
          cref_set := getAllEquCrefs({set});

          if List.applyAndFold(cref_set, boolOr, isExpandable, false) then
            crefSets := cref_set :: crefSets;
          end if;
        then
          ();

      else ();
    end match;
  end for;
end getExpandableEquSetsAsCrefs;

protected function removeCrefsFromSets
  input output list<Set> sets;
  input list<DAE.ComponentRef> nonUsefulExpandable;
algorithm
  sets := List.select1(sets, removeCrefsFromSets2, nonUsefulExpandable);
end removeCrefsFromSets;

protected function removeCrefsFromSets2
  input Set set;
  input list<DAE.ComponentRef> nonUsefulExpandable;
  output Boolean isInSet;
protected
  list<DAE.ComponentRef> setCrefs, lst;
algorithm
  setCrefs := getAllEquCrefs({set});
  lst := List.intersectionOnTrue(setCrefs, nonUsefulExpandable, ComponentReference.crefEqualNoStringCompare);
  isInSet := listEmpty(lst);
end removeCrefsFromSets2;

function mergeEquSetsAsCrefs
  input output list<list<DAE.ComponentRef>> setsAsCrefs;
algorithm
  setsAsCrefs := match(setsAsCrefs)
    local
      list<DAE.ComponentRef> set;
      list<list<DAE.ComponentRef>> rest, sets;

    case ({}) then {};
    case ({set}) then {set};
    case (set::rest)
      algorithm
        (set, rest) := mergeWithRest(set, rest);
        sets := mergeEquSetsAsCrefs(rest);
      then
        set::sets;
  end match;
end mergeEquSetsAsCrefs;

protected function mergeWithRest
  input output list<DAE.ComponentRef> set;
  input output list<list<DAE.ComponentRef>> sets;
  input list<list<DAE.ComponentRef>> acc = {};
algorithm
  (set, sets) := match (set, sets)
    local
      list<DAE.ComponentRef> set1, set2;
      list<list<DAE.ComponentRef>> rest;
      Boolean b;
    case (_, {}) then (set, listReverse(acc));
    case (set1, set2::rest)
      algorithm
         // Could be faster if we had a function for intersectionExist in a set
         b := listEmpty(List.intersectionOnTrue(set1, set2, ComponentReference.crefEqualNoStringCompare));
         set := if not b then List.unionOnTrue(set1, set2, ComponentReference.crefEqualNoStringCompare) else set1;
         (set, rest) := mergeWithRest(set, rest, List.consOnTrue(b, set2, acc));
      then (set, rest);
  end match;
end mergeWithRest;

protected function getOnlyExpandableConnectedCrefs
  input list<list<DAE.ComponentRef>> sets;
  output list<DAE.ComponentRef> usefulConnectedExpandable = {};
algorithm
  for set in sets loop
    if allCrefsAreExpandable(set) then
      usefulConnectedExpandable := listAppend(set, usefulConnectedExpandable);
    end if;
  end for;
end getOnlyExpandableConnectedCrefs;

public function allCrefsAreExpandable
  input list<DAE.ComponentRef> connects;
  output Boolean allAreExpandable;
algorithm
  for cr in connects loop
    if not isExpandable(cr) then
      allAreExpandable := false;
      return;
    end if;
  end for;

  allAreExpandable := true;
end allCrefsAreExpandable;

protected function generateSetArray
  "Generates an array of sets from a connection set."
  input Sets sets;
  output array<Set> setArray;
algorithm
  // Create a new array.
  setArray := arrayCreate(sets.setCount, Set.SET(ConnectorType.NO_TYPE(), {}));
  // Add connection pointers to the array.
  setArray := setArrayAddConnections(sets.connections, sets.setCount, setArray);
  // Fill the array with sets.
  setArray := generateSetArray2(sets.sets, {}, setArray);
end generateSetArray;

protected function setArrayAddConnections
  "The connection set maintains a list of connections, but when we generate the
  set array which is used to generate the equations we want to merge these sets.
  This function adds pointers to the array, so that when we fill it with
  generateSetArray2 we can follow the pointers to the correct sets. I.e. if sets
  1 and 2 are connected we might add a pointer from 2 to 1, so that all elements
  that belongs to set 2 are instead added to set 1. To make sure that we get
  correct pointers we build a graph and use an algorithm to find the strongly
  connected components in it."
  input list<SetConnection> connections;
  input Integer setCount;
  input output array<Set> sets;
protected
  SetGraph graph;
algorithm
  // Create a new graph, represented as an adjacency list.
  graph := arrayCreate(setCount, {});
  // Add the connections to the graph.
  graph := List.fold(connections, addConnectionToGraph, graph);

  // Add the connections to the array with help from the graph.
  for i in 1:arrayLength(graph) loop
    (sets, graph) := setArrayAddConnection(i, graph[i], sets, graph);
  end for;
end setArrayAddConnections;

protected function addConnectionToGraph
  "Adds a connection to the set graph."
  input SetConnection connection;
  input output SetGraph graph;
protected
  Integer set1, set2;
  list<Integer> node1, node2;
algorithm
  (set1, set2) := connection;
  node1 := arrayGet(graph, set1);
  graph := arrayUpdate(graph, set1, set2 :: node1);
  node2 := arrayGet(graph, set2);
  graph := arrayUpdate(graph, set2, set1 :: node2);
end addConnectionToGraph;

protected function setArrayAddConnection
  "Helper function to setArrayAddConnections, adds a connection pointer to the
   set array."
  input Integer set;
  input list<Integer> edges;
  input output array<Set> sets;
  input output SetGraph graph;
protected
  list<Integer> edge_lst;
algorithm
  for e in edges loop
    if e <> set then
      // Create a pointer to the given set.
      sets := setArrayAddConnection2(e, set, sets);
      edge_lst := graph[e];
      graph[e] := {};
      (sets, graph) := setArrayAddConnection(set, edge_lst, sets, graph);
    end if;
  end for;
end setArrayAddConnection;

protected function setArrayAddConnection2
  "Helper function to setArrayAddConnection, adds a pointer from the given
   pointer to the pointee."
  input Integer setPointer;
  input Integer setPointee;
  input output array<Set> sets;
protected
  Set set;
algorithm
  set := sets[setPointee];

  sets := match set
    // If the set pointed at is a real set, add a pointer to it.
    case Set.SET()
      then arrayUpdate(sets, setPointer, Set.SET_POINTER(setPointee));

    // If the set pointed at is itself a pointer, follow the pointer until a
    // real set is found (path compression).
    case Set.SET_POINTER()
      then setArrayAddConnection2(setPointer, set.index, sets);
  end match;
end setArrayAddConnection2;

protected function generateSetArray2
  "This function fills the set array with the sets from the set trie."
  input SetTrie sets;
  input list<DAE.ComponentRef> prefix;
  input output array<Set> setArray;
algorithm
  setArray := match sets
    local
      Option<ConnectorElement> ie, oe;
      Option<DAE.ComponentRef> prefix_cr, flow_cr;

    case SetTrieNode.SET_TRIE_NODE(cref = DAE.WILD())
      then List.fold1(sets.nodes, generateSetArray2, prefix, setArray);

    case SetTrieNode.SET_TRIE_NODE()
      then List.fold1(sets.nodes, generateSetArray2, sets.cref :: prefix, setArray);

    case SetTrieNode.SET_TRIE_LEAF(insideElement = ie, outsideElement = oe,
        flowAssociation = flow_cr)
      algorithm
        ie := insertFlowAssociationInStreamElement(sets.insideElement, flow_cr);
        oe := insertFlowAssociationInStreamElement(sets.outsideElement, flow_cr);
        prefix_cr := buildElementPrefix(prefix);
        setArray := setArrayAddElement(ie, prefix_cr, setArray);
        setArray := setArrayAddElement(oe, prefix_cr, setArray);
      then
        setArray;

    else setArray;
  end match;
end generateSetArray2;

protected function insertFlowAssociationInStreamElement
  "If the given element is a stream element, sets the associated flow. Otherwise
  does nothing."
  input output Option<ConnectorElement> element;
  input Option<DAE.ComponentRef> flowCref;
protected
  ConnectorElement el;
algorithm
  if isSome(element) then
    SOME(el) := element;

    element := match el
      case ConnectorElement.CONNECTOR_ELEMENT(ty = ConnectorType.STREAM(NONE()))
        algorithm
          el.ty := ConnectorType.STREAM(flowCref);
        then
          SOME(el);

      else element;
    end match;
  end if;
end insertFlowAssociationInStreamElement;

protected function setArrayAddElement
  "Adds a connector element to the set array."
  input Option<ConnectorElement> element;
  input Option<DAE.ComponentRef> prefix;
  input output array<Set> sets;
algorithm
  sets := match (element, prefix)
    local
      ConnectorElement el;
      DAE.ComponentRef prefix_cr;

    // No element, do nothing.
    case (NONE(), _) then sets;

    // An element but no prefix, add the element as it is.
    case (SOME(el as ConnectorElement.CONNECTOR_ELEMENT()), NONE())
      then setArrayUpdate(sets, el.set, el);

    // Both an element and a prefix, add the prefix to the element before adding
    // it to the array.
    case (SOME(el as ConnectorElement.CONNECTOR_ELEMENT()), SOME(prefix_cr))
      algorithm
        el.name := ComponentReference.joinCrefs(prefix_cr, el.name);
      then
        setArrayUpdate(sets, el.set, el);

  end match;
end setArrayAddElement;

protected function buildElementPrefix
  "Helper function to generateSetArray2, build a prefix from a list of crefs."
  input list<DAE.ComponentRef> prefix;
  output Option<DAE.ComponentRef> cref;
protected
  DAE.ComponentRef cr;
  String id;
  list<DAE.Subscript> subs;
algorithm
  // If a connector that extends a basic type is used on the top level we
  // don't have a prefix.
  if listEmpty(prefix) then
    cref := NONE();
  else
    cr := listHead(prefix);
    for c in listRest(prefix) loop
      DAE.CREF_IDENT(ident = id, subscriptLst = subs) := c;
      cr := DAE.CREF_QUAL(id, DAE.T_UNKNOWN_DEFAULT, subs, cr);
    end for;

    cref := SOME(cr);
  end if;
end buildElementPrefix;

protected function setArrayUpdate
  "Updates the element at a given index in the set array."
  input output array<Set> sets;
  input Integer index;
  input ConnectorElement element;
protected
  Set set;
  list<ConnectorElement> el;
algorithm
  set := sets[index];

  sets := match (set, element)
    case (Set.SET(), ConnectorElement.CONNECTOR_ELEMENT())
      algorithm
        if Config.orderConnections() and isEquType(element.ty) then
          // Sort the elements if orderConnections is true and the set is an equality set.
          el := List.mergeSorted({element}, set.elements, equSetElementLess);
        else
          // Other sets, just add them.
          el := element :: set.elements;
        end if;
      then
        arrayUpdate(sets, index, Set.SET(element.ty, el));

    // A pointer, follow the pointer.
    case (Set.SET_POINTER(), _)
      then setArrayUpdate(sets, set.index, element);

  end match;
end setArrayUpdate;

protected function equSetElementLess
  "Comparison function used by setArrayUpdate2 to order equ sets."
  input ConnectorElement element1;
  input ConnectorElement element2;
  output Boolean isLess;
algorithm
  isLess := ComponentReference.crefSortFunc(element2.name, element1.name);
end equSetElementLess;

protected function setArrayGet
  "Returns the set on a given index in the set array."
  input array<Set> setArray;
  input Integer index;
  output Set set;
algorithm
  set := setArray[index];

  set := match set
    case Set.SET() then set;
    case Set.SET_POINTER() then setArrayGet(setArray, set.index);
  end match;
end setArrayGet;

protected function equationsDispatch
  "Dispatches to the correct equation generating function based on the type of
  the given set."
  input list<Set> sets;
  input ConnectionGraph.DaeEdges connected;
  input ConnectionGraph.DaeEdges broken;
  output DAE.DAElist DAE = DAE.emptyDae;
protected
  list<ConnectorElement> eql;
  Real flowThreshold = Flags.getConfigReal(Flags.FLOW_THRESHOLD);
algorithm
  for set in sets loop
    DAE := match set
      // A set pointer left from generateSetList, ignore it.
      case Set.SET_POINTER() then DAE;

      case Set.SET(ty = ConnectorType.EQU())
        algorithm
          // Here we do some overconstrained connection breaking.
          eql := ConnectionGraph.removeBrokenConnects(set.elements, connected, broken);
        then
          DAEUtil.joinDaes(generateEquEquations(eql), DAE);

      case Set.SET(ty = ConnectorType.FLOW(), elements = eql)
        then DAEUtil.joinDaes(generateFlowEquations(set.elements), DAE);

      case Set.SET(ty = ConnectorType.STREAM(), elements = eql)
        then DAEUtil.joinDaes(generateStreamEquations(set.elements, flowThreshold), DAE);

      // Should never happen.
      case Set.SET(ty = ConnectorType.NO_TYPE())
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR,
            {"ConnectUtil.equationsDispatch failed on connection set with no type."});
        then
          fail();

      else
        algorithm
          Error.addMessage(Error.INTERNAL_ERROR,
            {"ConnectUtil.equationsDispatch failed because of unknown reason."});
        then
          fail();

    end match;
  end for;
end equationsDispatch;

protected function generateEquEquations
  "A non-flow connection set contains a number of components. Generating the
   equations from this set means equating all the components. For n components,
   this will give n-1 equations. For example, if the set contains the components
   X, Y.A and Z.B, the equations generated will be X = Y.A and X = Z.B. The
   order of the equations depends on whether the compiler flag orderConnections
   is true or false."
  input list<ConnectorElement> elements;
  output DAE.DAElist DAE = DAE.emptyDae;
protected
  list<DAE.Element> eql = {};
  ConnectorElement e1;
  DAE.ElementSource src, x_src, y_src;
  DAE.ComponentRef x, y;
algorithm
  if listEmpty(elements) then
    return;
  end if;

  e1 := listHead(elements);

  if Config.orderConnections() then
    for e2 in listRest(elements) loop
      src := ElementSource.mergeSources(e1.source, e2.source);
      src := ElementSource.addElementSourceConnect(src, (e1.name, e2.name));
      eql := DAE.EQUEQUATION(e1.name, e2.name, src) :: eql;
    end for;
  else
    for e2 in listRest(elements) loop
      (x, y) := Util.swap(shouldFlipEquEquation(e1.name, e1.source), e1.name, e2.name);
      src := ElementSource.mergeSources(e1.source, e2.source);
      src := ElementSource.addElementSourceConnect(src, (x, y));
      eql := DAE.EQUEQUATION(x, y, src) :: eql;
      e1 := e2;
    end for;
  end if;

  DAE := DAE.DAE(listReverse(eql));
end generateEquEquations;

protected function shouldFlipEquEquation
  "If the flag +orderConnections=false is used, then we should keep the order of
   the connector elements as they occur in the connection (if possible). In that
   case we check if the cref of the first argument to the first connection
   stored in the element source is a prefix of the connector element cref. If
   it isn't, indicate that we should flip the generated equation."
  input DAE.ComponentRef lhsCref;
  input DAE.ElementSource lhsSource;
  output Boolean shouldFlip;
algorithm
  shouldFlip := match lhsSource
    local
      DAE.ComponentRef lhs;

    case DAE.SOURCE(connectEquationOptLst = (lhs, _) :: _)
      then not ComponentReference.crefPrefixOf(lhs, lhsCref);

    else false;
  end match;
end shouldFlipEquEquation;

protected function generateFlowEquations
  "Generating equations from a flow connection set is a little trickier that
   from a non-flow set. Only one equation is generated, but it has to consider
   whether the components were inside or outside connectors. This function
   creates a sum expression of all components (some of which will be negated),
   and the returns the equation where this sum is equal to 0.0."
  input list<ConnectorElement> elements;
  output DAE.DAElist DAE;
protected
  DAE.Exp sum;
  DAE.ElementSource src;
algorithm
  sum := makeFlowExp(listHead(elements));
  src := getElementSource(listHead(elements));

  for e in listRest(elements) loop
    sum := Expression.makeRealAdd(sum, makeFlowExp(e));
    src := ElementSource.mergeSources(src, e.source);
  end for;

  DAE := DAE.DAE({DAE.EQUATION(sum, DAE.RCONST(0.0), src)});
end generateFlowEquations;

protected function makeFlowExp
  "Creates an expression from a connector element, which is the element itself
   if it's an inside connector, or negated if it's outside."
  input ConnectorElement element;
  output DAE.Exp exp;
algorithm
  exp := Expression.crefExp(element.name);

  if isOutsideElement(element) then
    exp := Expression.negateReal(exp);
  end if;
end makeFlowExp;

public function increaseConnectRefCount
  input DAE.ComponentRef lhsCref;
  input DAE.ComponentRef rhsCref;
  input output Sets sets;
protected
  list<DAE.ComponentRef> crefs;
algorithm
  if System.getUsesCardinality() then
    crefs := ComponentReference.expandCref(lhsCref, false);
    sets.sets := increaseConnectRefCount2(crefs, sets.sets);
    crefs := ComponentReference.expandCref(rhsCref, false);
    sets.sets := increaseConnectRefCount2(crefs, sets.sets);
  end if;
end increaseConnectRefCount;

public function increaseConnectRefCount2
  input list<DAE.ComponentRef> crefs;
  input output SetTrie sets;
algorithm
  for cr in crefs loop
    sets := setTrieUpdate(cr, 1, sets, increaseRefCount);
  end for;
end increaseConnectRefCount2;

protected function increaseRefCount
  input Integer amount;
  input output SetTrieNode node;
algorithm
  _ := match node
    case SetTrieNode.SET_TRIE_NODE()
      algorithm
        node.connectCount := node.connectCount + amount;
      then
        ();

    case SetTrieNode.SET_TRIE_LEAF()
      algorithm
        node.connectCount := node.connectCount + amount;
      then
        ();
  end match;
end increaseRefCount;

protected function generateStreamEquations
  "Generates the equations for a stream connection set."
  input list<ConnectorElement> elements;
  input Real flowThreshold;
  output DAE.DAElist DAE;
algorithm
  DAE := match elements
    local
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource src1, src2, src;
      DAE.DAElist dae;
      DAE.Exp cref1, cref2, e1, e2;
      list<ConnectorElement> inside, outside;

    // Unconnected stream connector, do nothing!
    case {ConnectorElement.CONNECTOR_ELEMENT(face = Face.INSIDE())}
      then DAE.emptyDae;

    // Both inside, do nothing!
    case {ConnectorElement.CONNECTOR_ELEMENT(face = Face.INSIDE()),
          ConnectorElement.CONNECTOR_ELEMENT(face = Face.INSIDE())}
      then DAE.emptyDae;

    // Both outside:
    // cr1 = inStream(cr2);
    // cr2 = inStream(cr1);
    case {ConnectorElement.CONNECTOR_ELEMENT(name = cr1, face = Face.OUTSIDE(), source = src1),
          ConnectorElement.CONNECTOR_ELEMENT(name = cr2, face = Face.OUTSIDE(), source = src2)}
      algorithm
        cref1 := Expression.crefExp(cr1);
        cref2 := Expression.crefExp(cr2);
        e1 := makeInStreamCall(cref2);
        e2 := makeInStreamCall(cref1);
        src := ElementSource.mergeSources(src1, src2);
        dae := DAE.DAE({
          DAE.EQUATION(cref1, e1, src),
          DAE.EQUATION(cref2, e2, src)});
      then
        dae;

    // One inside, one outside:
    // cr1 = cr2;
    case {ConnectorElement.CONNECTOR_ELEMENT(name = cr1, source = src1),
           ConnectorElement.CONNECTOR_ELEMENT(name = cr2, source = src2)}
      algorithm
        src := ElementSource.mergeSources(src1, src2);
        e1 := Expression.crefExp(cr1);
        e2 := Expression.crefExp(cr2);
        dae := DAE.DAE({DAE.EQUATION(e1,e2,src)});
      then
        dae;

    // The general case with N inside connectors and M outside:
    else
      algorithm
        (outside, inside) := List.splitOnTrue(elements, isOutsideElement);
        dae := streamEquationGeneral(outside, inside, flowThreshold);
      then
        dae;

  end match;
end generateStreamEquations;

protected function isOutsideElement
  "Returns true if the connector element belongs to an outside connector."
  input ConnectorElement element;
  output Boolean isOutside;
algorithm
  isOutside := match element
    case ConnectorElement.CONNECTOR_ELEMENT(face = Face.OUTSIDE()) then true;
    else false;
  end match;
end isOutsideElement;

protected function isZeroFlowMinMax
  "Returns true if the given flow attribute of a connector is zero."
  input DAE.ComponentRef streamCref;
  input ConnectorElement element;
  output Boolean isZero;
algorithm
  if compareCrefStreamSet(streamCref, element) then
    isZero := false;
  elseif isOutsideElement(element) then
    isZero := isZeroFlow(element, "max");
  else
    isZero := isZeroFlow(element, "min");
  end if;
end isZeroFlowMinMax;

protected function isZeroFlow
  "Returns true if the given flow attribute of a connector is zero."
  input ConnectorElement element;
  input String attr;
  output Boolean isZero;
protected
  DAE.Type ty;
  Option<DAE.Exp> attr_oexp;
  DAE.Exp flow_exp, attr_exp;
algorithm
  flow_exp := flowExp(element);
  ty := Expression.typeof(flow_exp);
  attr_oexp := Types.lookupAttributeExp(Types.getAttributes(ty), attr);
  if isSome(attr_oexp) then
    SOME(attr_exp) := attr_oexp;
    isZero := Expression.isZero(attr_exp);
  else
    isZero := false;
  end if;
end isZeroFlow;

protected function streamEquationGeneral
  "Generates an equation for an outside stream connector element."
  input list<ConnectorElement> outsideElements;
  input list<ConnectorElement> insideElements;
  input Real flowThreshold;
  output DAE.DAElist DAE;
protected
  list<ConnectorElement> outside;
  DAE.Exp cref_exp, res;
  DAE.ElementSource src;
  DAE.DAElist dae;
  DAE.ComponentRef name;
  list<DAE.Element> eql = {};
algorithm
  for e in outsideElements loop
    cref_exp := Expression.crefExp(e.name);
    outside := removeStreamSetElement(e.name, outsideElements);
    res := streamSumEquationExp(outside, insideElements, flowThreshold);
    src := ElementSource.addAdditionalComment(e.source, " equation generated by stream handling");
    eql := DAE.EQUATION(cref_exp, res, src) :: eql;
  end for;

  DAE := DAE.DAE(eql);
end streamEquationGeneral;

protected function streamSumEquationExp
  "Generates the sum expression used by stream connector equations, given M
  outside connectors and N inside connectors:

    (sum(max(-flow_exp[i], eps) * stream_exp[i] for i in N) +
     sum(max( flow_exp[i], eps) * inStream(stream_exp[i]) for i in M)) /
    (sum(max(-flow_exp[i], eps) for i in N) +
     sum(max( flow_exp[i], eps) for i in M))

  where eps = inFlowThreshold.
  "
  input list<ConnectorElement> outsideElements;
  input list<ConnectorElement> insideElements;
  input Real flowThreshold;
  output DAE.Exp sumExp;
protected
  DAE.Exp outside_sum1, outside_sum2, inside_sum1, inside_sum2, res;
algorithm
  if listEmpty(outsideElements) then
    // No outside components.
    inside_sum1 := sumMap(insideElements, sumInside1, flowThreshold);
    inside_sum2 := sumMap(insideElements, sumInside2, flowThreshold);
    sumExp := Expression.expDiv(inside_sum1, inside_sum2);
  elseif listEmpty(insideElements) then
    // No inside components.
    outside_sum1 := sumMap(outsideElements, sumOutside1, flowThreshold);
    outside_sum2 := sumMap(outsideElements, sumOutside2, flowThreshold);
    sumExp := Expression.expDiv(outside_sum1, outside_sum2);
  else
    // Both outside and inside components.
    outside_sum1 := sumMap(outsideElements, sumOutside1, flowThreshold);
    outside_sum2 := sumMap(outsideElements, sumOutside2, flowThreshold);
    inside_sum1 := sumMap(insideElements, sumInside1, flowThreshold);
    inside_sum2 := sumMap(insideElements, sumInside2, flowThreshold);
    sumExp := Expression.expDiv(Expression.expAdd(outside_sum1, inside_sum1),
                                   Expression.expAdd(outside_sum2, inside_sum2));
  end if;
end streamSumEquationExp;

protected function sumMap
  "Creates a sum expression by applying the given function on the list of
  elements and summing up the resulting expressions."
  input list<ConnectorElement> elements;
  input FuncType func;
  input Real flowThreshold;
  output DAE.Exp exp;

  partial function FuncType
    input ConnectorElement element;
    input Real flowThreshold;
    output DAE.Exp exp;
  end FuncType;
algorithm
  exp := Expression.expAdd(func(e, flowThreshold) for e in listReverse(elements));
end sumMap;

protected function streamFlowExp
  "Returns the stream and flow component in a stream set element as expressions."
  input ConnectorElement element;
  output DAE.Exp streamExp;
  output DAE.Exp flowExp;
protected
  DAE.ComponentRef flow_cr;
algorithm
  ConnectorElement.CONNECTOR_ELEMENT(ty = ConnectorType.STREAM(SOME(flow_cr))) := element;
  streamExp := Expression.crefExp(element.name);
  flowExp := Expression.crefExp(flow_cr);
end streamFlowExp;

protected function flowExp
  "Returns the flow component in a stream set element as an expression."
  input ConnectorElement element;
  output DAE.Exp flowExp;
protected
  DAE.ComponentRef flow_cr;
algorithm
  ConnectorElement.CONNECTOR_ELEMENT(ty = ConnectorType.STREAM(SOME(flow_cr))) := element;
  flowExp := Expression.crefExp(flow_cr);
end flowExp;

protected function sumOutside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps) * inStream(stream_exp)
  given a stream set element."
  input ConnectorElement element;
  input Real flowThreshold;
  output DAE.Exp exp;
protected
  DAE.Exp stream_exp, flow_exp, flow_threshold;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(element);
  flow_threshold := DAE.RCONST(flowThreshold);
  exp := Expression.expMul(makePositiveMaxCall(flow_exp, flow_threshold),
                              makeInStreamCall(stream_exp));
end sumOutside1;

protected function sumInside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps) * stream_exp
  given a stream set element."
  input ConnectorElement element;
  input Real flowThreshold;
  output DAE.Exp exp;
protected
  DAE.Exp stream_exp, flow_exp, flow_threshold;
  DAE.Type flowTy, streamTy;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(element);
  flowTy := Expression.typeof(flow_exp);
  flow_exp := DAE.UNARY(DAE.UMINUS(flowTy), flow_exp);
  flow_threshold := DAE.RCONST(flowThreshold);
  exp := Expression.expMul(makePositiveMaxCall(flow_exp, flow_threshold), stream_exp);
end sumInside1;

protected function sumOutside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps)
  given a stream set element."
  input ConnectorElement element;
  input Real flowThreshold;
  output DAE.Exp exp;
protected
  DAE.Exp flow_exp;
algorithm
  flow_exp := flowExp(element);
  exp := makePositiveMaxCall(flow_exp, DAE.RCONST(flowThreshold));
end sumOutside2;

protected function sumInside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps)
  given a stream set element."
  input ConnectorElement element;
  input Real flowThreshold;
  output DAE.Exp exp;
protected
  DAE.Exp flow_exp;
  DAE.Type flowTy;
algorithm
  flow_exp := flowExp(element);
  flowTy := Expression.typeof(flow_exp);
  flow_exp := DAE.UNARY(DAE.UMINUS(flowTy), flow_exp);
  exp := makePositiveMaxCall(flow_exp, DAE.RCONST(flowThreshold));
end sumInside2;

public function faceEqual "Test for face equality."
  input Face face1;
  input Face face2;
  output Boolean sameFaces = valueConstructor(face1) == valueConstructor(face2);
end faceEqual;

protected function makeInStreamCall
  "Creates an inStream call expression."
  input DAE.Exp streamExp;
  output DAE.Exp inStreamCall;
  annotation(__OpenModelica_EarlyInline = true);
protected
  DAE.Type ty;
algorithm
  ty := Expression.typeof(streamExp);
  inStreamCall := Expression.makeBuiltinCall("inStream", {streamExp}, ty, false);
end makeInStreamCall;

protected function makePositiveMaxCall
  "Generates a max(flow_exp, eps) call."
  input DAE.Exp flowExp;
  input DAE.Exp flowThreshold;
  output DAE.Exp positiveMaxCall;
  annotation(__OpenModelica_EarlyInline = true);
protected
  DAE.Type ty;
  list<DAE.Var> attr;
  Option<DAE.Exp> nominal_oexp;
  DAE.Exp nominal_exp, flow_threshold;
algorithm
  ty := Expression.typeof(flowExp);
  nominal_oexp := Types.lookupAttributeExp(Types.getAttributes(ty), "nominal");

  if isSome(nominal_oexp) then
    SOME(nominal_exp) := nominal_oexp;
    flow_threshold := Expression.expMul(flowThreshold, nominal_exp);
  else
    flow_threshold := flowThreshold;
  end if;

  positiveMaxCall :=
    DAE.CALL(Absyn.IDENT("max"), {flowExp, flow_threshold},
      DAE.CALL_ATTR(
        ty,
        false,
        true,
        false,
        false,
        DAE.NO_INLINE(),
        DAE.NO_TAIL()));
end makePositiveMaxCall;

protected function evaluateConnectionOperators
  "Evaluates connection operators inStream, actualStream and cardinality in the
   given DAE."
  input Sets sets;
  input array<Set> setArray;
  input output DAE.DAElist DAE;
protected
  Real flow_threshold;
  Boolean has_cardinality = System.getUsesCardinality();
algorithm
  // Only do this phase if we have any connection operators.
  if System.getHasStreamConnectors() or has_cardinality then
    flow_threshold := Flags.getConfigReal(Flags.FLOW_THRESHOLD);
    DAE := DAEUtil.traverseDAE(DAE, DAE.AvlTreePathFunction.Tree.EMPTY(),
      function evaluateConnectionOperators2(
        hasCardinality = has_cardinality,
        setArray = setArray,
        flowThreshold = flow_threshold), sets);
    DAE := simplifyDAEElements(has_cardinality, DAE);
  end if;
end evaluateConnectionOperators;

protected function evaluateConnectionOperators2
  "Helper function to evaluateConnectionOperators."
  input output DAE.Exp exp;
  input output Sets sets;
  input array<Set> setArray;
  input Boolean hasCardinality;
  input Real flowThreshold;
protected
  Boolean changed;
algorithm
  (exp, changed) := Expression.traverseExpBottomUp(exp,
    function evaluateConnectionOperatorsExp(
      sets = sets,
      setArray = setArray,
      flowThreshold = flowThreshold), false);

  // Only apply simplify if the expression changed *AND* we have cardinality.
  if changed and hasCardinality then
    exp := ExpressionSimplify.simplify(exp);
  end if;
end evaluateConnectionOperators2;

protected function evaluateConnectionOperatorsExp
  "Helper function to evaluateConnectionOperators2. Checks if the given
   expression is a call to inStream or actualStream, and if so calls the
   appropriate function in ConnectUtil to evaluate the call."
  input output DAE.Exp exp;
  input Sets sets;
  input array<Set> setArray;
  input Real flowThreshold;
  input output Boolean changed;
algorithm
  (exp, changed) := match exp
    local
      DAE.ComponentRef cr;
      DAE.Exp e;

    case DAE.CALL(path = Absyn.IDENT("inStream"),
                  expLst = {DAE.CREF(componentRef = cr)})
      algorithm
        e := evaluateInStream(cr, sets, setArray, flowThreshold);
        //print("Evaluated inStream(" + ExpressionDump.dumpExpStr(DAE.CREF(cr, ty), 0) + ") ->\n" + ExpressionDump.dumpExpStr(e, 0) + "\n");
      then
        (e, true);

    case DAE.CALL(path = Absyn.IDENT("actualStream"),
                  expLst = {DAE.CREF(componentRef = cr)})
      algorithm
        e := evaluateActualStream(cr, sets, setArray, flowThreshold);
        //print("Evaluated actualStream(" + ExpressionDump.dumpExpStr(DAE.CREF(cr, ty), 0) + ") ->\n" + ExpressionDump.dumpExpStr(e, 0) + "\n");
      then
        (e, true);

    case DAE.CALL(path = Absyn.IDENT("cardinality"),
                  expLst = {DAE.CREF(componentRef = cr)})
      algorithm
        e := evaluateCardinality(cr, sets);
      then
        (e, true);

    else (exp, changed);

  end match;
end evaluateConnectionOperatorsExp;

protected function mkArrayIfNeeded
"@author: adrpo
 does an array out of exp if needed"
  input DAE.Type ty;
  input output DAE.Exp exp;
algorithm
  exp := Expression.arrayFill(Types.getDimensions(ty), exp);
end mkArrayIfNeeded;

protected function evaluateInStream
  "This function evaluates the inStream operator for a component reference,
   given the connection sets."
  input DAE.ComponentRef streamCref;
  input Sets sets;
  input array<Set> setArray;
  input Real flowThreshold;
  output DAE.Exp exp;
protected
  ConnectorElement e;
  list<ConnectorElement> sl;
  Integer set;
algorithm
  try
    e := findElement(streamCref, Face.INSIDE(), ConnectorType.STREAM(NONE()),
      DAE.emptyElementSource, sets);

    if isNewElement(e) then
      // A new element means that the stream element couldn't be found in the sets
      // => unconnected stream connector.
      sl := {e};
    else
      // Otherwise, fetch the set that the element belongs to and evaluate the
      // inStream call.
      ConnectorElement.CONNECTOR_ELEMENT(set = set) := e;
      Set.SET(ty = ConnectorType.STREAM(), elements = sl) :=
        setArrayGet(setArray, set);
    end if;

    exp := generateInStreamExp(streamCref, sl, sets, setArray, flowThreshold);
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- ConnectUtil.evaluateInStream failed for " +
      ComponentReference.crefStr(streamCref) + "\n");
  end try;
end evaluateInStream;

protected function generateInStreamExp
  "Helper function to evaluateInStream. Generates an expression for inStream
  given a connection set."
  input DAE.ComponentRef streamCref;
  input list<ConnectorElement> streams;
  input Sets sets;
  input array<Set> setArray;
  input Real flowThreshold;
  output DAE.Exp exp;
protected
  list<ConnectorElement> reducedStreams;
algorithm
  reducedStreams := List.filterOnFalse(streams, function isZeroFlowMinMax(streamCref = streamCref));

  exp := match reducedStreams
    local
      DAE.ComponentRef c;
      Face f1, f2;
      DAE.Exp e;
      list<ConnectorElement>  inside, outside;

    // Unconnected stream connector:
    // inStream(c) = c;
    case {ConnectorElement.CONNECTOR_ELEMENT(name = c, face = Face.INSIDE())}
      then Expression.crefExp(c);

    // Two inside connected stream connectors:
    // inStream(c1) = c2;
    // inStream(c2) = c1;
    case {ConnectorElement.CONNECTOR_ELEMENT(face = Face.INSIDE()),
          ConnectorElement.CONNECTOR_ELEMENT(face = Face.INSIDE())}
      algorithm
        {ConnectorElement.CONNECTOR_ELEMENT(name = c)} :=
          removeStreamSetElement(streamCref, reducedStreams);
        e := Expression.crefExp(c);
      then
        e;

    // One inside, one outside connected stream connector:
    // inStream(c1) = inStream(c2);
    case {ConnectorElement.CONNECTOR_ELEMENT(face = f1),
          ConnectorElement.CONNECTOR_ELEMENT(face = f2)} guard not faceEqual(f1, f2)
      algorithm
        {ConnectorElement.CONNECTOR_ELEMENT(name = c)} :=
          removeStreamSetElement(streamCref, reducedStreams);
        e := evaluateInStream(c, sets, setArray, flowThreshold);
      then
        e;

    // The general case:
    else
      algorithm
        (outside, inside) := List.splitOnTrue(reducedStreams, isOutsideElement);
        inside := removeStreamSetElement(streamCref, inside);
        e := streamSumEquationExp(outside, inside, flowThreshold);
        // Evaluate any inStream calls that were generated.
        e := evaluateConnectionOperators2(e, sets, setArray, false, flowThreshold);
      then
        e;
  end match;
end generateInStreamExp;

protected function evaluateActualStream
  "This function evaluates the actualStream operator for a component reference,
  given the connection sets."
  input DAE.ComponentRef streamCref;
  input Sets sets;
  input array<Set> setArray;
  input Real flowThreshold;
  output DAE.Exp exp;
protected
  DAE.ComponentRef flow_cr;
  DAE.Exp e, flow_exp, stream_exp, instream_exp, rel_exp;
  DAE.Type ety;
  Integer flow_dir;
algorithm
  flow_cr := getStreamFlowAssociation(streamCref, sets);
  ety := ComponentReference.crefLastType(flow_cr);
  flow_dir := evaluateFlowDirection(ety);

  // Select a branch if we know the flow direction, otherwise generate the whole
  // if-equation.
  if flow_dir == 1 then
    rel_exp := evaluateInStream(streamCref, sets, setArray, flowThreshold);
  elseif flow_dir == -1 then
    rel_exp := Expression.crefExp(streamCref);
  else
    flow_exp := Expression.crefExp(flow_cr);
    stream_exp := Expression.crefExp(streamCref);
    instream_exp := evaluateInStream(streamCref, sets, setArray, flowThreshold);
    rel_exp := DAE.IFEXP(
      DAE.RELATION(flow_exp, DAE.GREATER(ety), DAE.RCONST(0.0), -1, NONE()),
      instream_exp, stream_exp);
  end if;

  // actualStream(stream_var) = smooth(0, if flow_var > 0 then inStream(stream_var)
  //                                                      else stream_var);
  exp := DAE.CALL(Absyn.IDENT("smooth"), {DAE.ICONST(0), rel_exp},
    DAE.callAttrBuiltinReal);
end evaluateActualStream;

protected function evaluateFlowDirection
  "Checks the min/max attributes of a flow variables type to try and determine
  the flow direction. If the flow is positive 1 is returned, if it is negative
  -1, otherwise 0 if the direction can't be decided."
  input DAE.Type ty;
  output Integer direction = 0;
protected
  list<DAE.Var> attr;
  Option<Values.Value> min_oval, max_oval;
  Real min_val, max_val;
algorithm
  attr := Types.getAttributes(ty);
  if listEmpty(attr) then return; end if;

  min_oval := Types.lookupAttributeValue(attr, "min");
  max_oval := Types.lookupAttributeValue(attr, "max");

  direction := match (min_oval, max_oval)
    // No attributes, flow direction can't be decided.
    case (NONE(), NONE()) then 0;
    // Flow is positive if min is positive.
    case (SOME(Values.REAL(min_val)), NONE())
      then if min_val >= 0 then 1 else 0;
    // Flow is negative if max is negative.
    case (NONE(), SOME(Values.REAL(max_val)))
      then if max_val <= 0 then -1 else 0;
    // Flow is positive if both min and max are positive, negative if they are
    // both negative, otherwise undecideable.
    case (SOME(Values.REAL(min_val)), SOME(Values.REAL(max_val)))
      then
        if min_val >= 0 and max_val >= min_val then 1
        elseif max_val <= 0 and min_val <= max_val then -1
        else 0;
    else 0;
  end match;
end evaluateFlowDirection;

protected function evaluateCardinality
  input DAE.ComponentRef cref;
  input Sets sets;
  output DAE.Exp exp;
algorithm
  exp := DAE.ICONST(getConnectCount(cref, sets.sets));
end evaluateCardinality;

protected function simplifyDAEElements
"run this only if we have cardinality"
  input Boolean hasCardinality;
  input output DAE.DAElist DAE;
algorithm
  if hasCardinality then
    DAE := DAE.DAE(List.mapFlat(DAE.elementLst, simplifyDAEElement));
  end if;
end simplifyDAEElements;

protected function simplifyDAEElement
  input DAE.Element element;
  output list<DAE.Element> elements;
algorithm
  elements := matchcontinue(element)
    local
      list<DAE.Exp> conds;
      list<list<DAE.Element>> branches;
      list<DAE.Element> else_branch;

    case DAE.IF_EQUATION(conds, branches, else_branch)
      then simplifyDAEIfEquation(conds, branches, else_branch);

    case DAE.INITIAL_IF_EQUATION(conds, branches, else_branch)
      then simplifyDAEIfEquation(conds, branches, else_branch);

    case DAE.ASSERT(condition = DAE.BCONST(true)) then {};

    else {element};

  end matchcontinue;
end simplifyDAEElement;

protected function simplifyDAEIfEquation
  input list<DAE.Exp> conditions;
  input list<list<DAE.Element>> branches;
  input list<DAE.Element> elseBranch;
  output list<DAE.Element> elements;
protected
  Boolean cond_value;
  list<list<DAE.Element>> rest_branches = branches;
algorithm
  for cond in conditions loop
    DAE.BCONST(cond_value) := cond;

    // Condition is true, substitute if-equation with the branch contents.
    if cond_value == true then
      elements := listReverse(listHead(rest_branches));
      return;
    end if;

    // Condition is false, discard the branch and continue with the other branches.
    rest_branches := listRest(rest_branches);
  end for;

  // All conditions were false, substitute if-equation with else-branch contents.
  elements := listReverse(elseBranch);
end simplifyDAEIfEquation;

protected function removeStreamSetElement
  "This function removes the given cref from a connection set."
  input DAE.ComponentRef cref;
  input output list<ConnectorElement> elements;
algorithm
  elements := List.deleteMemberOnTrue(cref, elements, compareCrefStreamSet);
end removeStreamSetElement;

protected function compareCrefStreamSet
  "Helper function to removeStreamSetElement. Checks if the cref in a stream set
  element matches the given cref."
  input DAE.ComponentRef cref;
  input ConnectorElement element;
  output Boolean matches;
algorithm
  matches := ComponentReference.crefEqualNoStringCompare(cref, element.name);
end compareCrefStreamSet;

public function componentFace
"This function determines whether a component
  reference refers to an inner or outer connector:
  Rules:
    qualified cref and connector     => OUTSIDE
    non-qualifed cref                => OUTSIDE
    qualified cref and non-connector => INSIDE

  Modelica Specification 4.0
  Section: 9.1.2 Inside and Outside Connectors
  In an element instance M, each connector element of M is called an outside connector with respect to M.
  All other connector elements that are hierarchically inside M, but not in one of the outside connectors
  of M, is called an inside connector with respect to M. This is done **BEFORE** resolving outer elements
  to corresponding inner ones."
  input FCore.Graph env;
  input DAE.ComponentRef componentRef;
  output Face face;
algorithm
  face := matchcontinue componentRef
    local
      DAE.Ident id;

    // is a non-qualified cref => OUTSIDE
    case DAE.CREF_IDENT() then Face.OUTSIDE();

    // is a qualified cref and is a connector => OUTSIDE
    case DAE.CREF_QUAL(ident = id)
      algorithm
       (_, _, DAE.T_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_)),_,_,_,_,_,_)
         := Lookup.lookupVar(FCore.emptyCache(), env,
           ComponentReference.makeCrefIdent(id, DAE.T_UNKNOWN_DEFAULT,{}));
      then Face.OUTSIDE();

    // is a qualified cref and is NOT a connector => INSIDE
    case DAE.CREF_QUAL() then Face.INSIDE();
  end matchcontinue;
end componentFace;

public function componentFaceType
"Author: BZ, 2008-12
  Same functionalty as componentFace, with the difference that
  this function checks ident-type rather then env->lookup ==> type.
  Rules:
    qualified cref and connector     => OUTSIDE
    non-qualifed cref                => OUTSIDE
    qualified cref and non-connector => INSIDE

  Modelica Specification 4.0
  Section: 9.1.2 Inside and Outside Connectors
  In an element instance M, each connector element of M is called an outside connector with respect to M.
  All other connector elements that are hierarchically inside M, but not in one of the outside connectors
  of M, is called an inside connector with respect to M. This is done **BEFORE** resolving outer elements
  to corresponding inner ones."
  input DAE.ComponentRef inComponentRef;
  output Face outFace;
algorithm
  outFace := match (inComponentRef)
    // is a non-qualified cref => OUTSIDE
    case (DAE.CREF_IDENT()) then Face.OUTSIDE();
    // is a qualified cref and is a connector => OUTSIDE
    case (DAE.CREF_QUAL(identType = DAE.T_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_)))) then Face.OUTSIDE();
    // is a qualified cref and is an array of connectors => OUTSIDE
    case (DAE.CREF_QUAL(identType = DAE.T_ARRAY(ty = DAE.T_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_))))) then Face.OUTSIDE();
    // is a qualified cref and is NOT a connector => INSIDE
    case (DAE.CREF_QUAL()) then Face.INSIDE();
  end match;
end componentFaceType;

public function checkConnectorBalance
  "Checks if a connector class is balanced or not, according to the rules in the
  Modelica 3.2 specification."
  input list<DAE.Var> vars;
  input Absyn.Path path;
  input SourceInfo info;
protected
  Integer potentials, flows, streams;
algorithm
  (potentials, flows, streams) := countConnectorVars(vars);
  true := checkConnectorBalance2(potentials, flows, streams, path, info);
  //print(Absyn.pathString(path) + " has:\n\t" +
  //  String(potentials) + " potential variables\n\t" +
  //  String(flows) + " flow variables\n\t" +
  //  String(streams) + " stream variables\n\n");
end checkConnectorBalance;

protected function checkConnectorBalance2
  input Integer potentialVars;
  input Integer flowVars;
  input Integer streamVars;
  input Absyn.Path path;
  input SourceInfo info;
  output Boolean isBalanced = true;
protected
  String error_str, flow_str, potential_str, class_str;
algorithm
  // Don't check connector balance for language version 2.x and earlier.
  if Config.languageStandardAtMost(Config.LanguageStandard.'2.x') then
    return;
  end if;

  // Modelica 3.2 section 9.3.1:
  // For each non-partial connector class the number of flow variables shall
  // be equal to the number of variables that are neither parameter, constant,
  // input, output, stream nor flow.
  if potentialVars <> flowVars then
    flow_str := String(flowVars);
    potential_str := String(potentialVars);
    class_str := Absyn.pathString(path);
    error_str := stringAppendList({
      "The number of potential variables (",
      potential_str,
      ") is not equal to the number of flow variables (",
      flow_str, ")."});
    Error.addSourceMessage(Error.UNBALANCED_CONNECTOR, {class_str, error_str}, info);

    // This should be a hard error, but there are models that contain such
    // connectors. So we print an error but return that the connector is balanced.
  end if;

  // Modelica 3.2 section 15.1:
  // A stream connector must have exactly one scalar variable with the flow prefix.
  if streamVars > 0 and flowVars <> 1 then
    flow_str := String(flowVars);
    class_str := Absyn.pathString(path);
    error_str := stringAppendList({
      "A stream connector must have exactly one flow variable, this connector has ",
      flow_str, " flow variables."});
    Error.addSourceMessage(Error.INVALID_STREAM_CONNECTOR,
      {class_str, error_str}, info);
    isBalanced := false;
  end if;
end checkConnectorBalance2;

protected function countConnectorVars
  "Given a list of connector variables, this function counts how many potential,
  flow and stream variables it contains."
  input list<DAE.Var> vars;
  output Integer potentialVars = 0;
  output Integer flowVars = 0;
  output Integer streamVars = 0;
protected
  DAE.Type ty, ty2;
  DAE.Attributes attr;
  Integer n, p, f, s;
algorithm
  for var in vars loop
    DAE.TYPES_VAR(ty = ty, attributes = attr) := var;
    ty2 := Types.arrayElementType(ty);

    // Check if we have a connector inside a connector.
    if Types.isConnector(ty2) then
      // If we have an array of connectors, count the elements.
      n := product(dim for dim in Types.getDimensionSizes(ty));
      // Count the number of different variables inside the connector, and then
      // multiply those numbers with the dimensions of the array.
      (p, f, s) := countConnectorVars(Types.getConnectorVars(ty2));

      // If the variable is input/output we don't count potential variables.
      if Absyn.isInputOrOutput(DAEUtil.getAttrDirection(attr)) then
        p := 0;
      end if;

      potentialVars := potentialVars + p * n;
      flowVars := flowVars + f * n;
      streamVars := streamVars + s * n;
    else
      _ := match attr
        // A flow variable.
        case DAE.ATTR(connectorType = SCode.FLOW())
          algorithm
            flowVars := flowVars + sizeOfType(var.ty);
          then
            ();

        // A stream variable.
        case DAE.ATTR(connectorType = SCode.STREAM())
          algorithm
            streamVars := streamVars + sizeOfType(var.ty);
          then
            ();

        // A potential variable.
        case DAE.ATTR(direction = Absyn.BIDIR(), variability = SCode.VAR())
          algorithm
            potentialVars := potentialVars + sizeOfType(var.ty);
          then
            ();

        else ();
      end match;
    end if;
  end for;
end countConnectorVars;

protected function sizeOfVariableList
  "Calls sizeOfVariable on a list of variables, and adds up the results."
  input list<DAE.Var> vars;
  output Integer size = 0;
algorithm
  for var in vars loop
    size := size + sizeOfType(var.ty);
  end for;
end sizeOfVariableList;

protected function sizeOfType
  "Different types of variables have different size, for example arrays. This
   function checks the size of one variable."
  input DAE.Type ty;
  output Integer size;
algorithm
  size := match ty
    local
      Integer n;
      DAE.Type t;
      list<DAE.Var> v;

    // Scalar values consist of one element.
    case DAE.T_INTEGER() then 1;
    case DAE.T_REAL() then 1;
    case DAE.T_STRING() then 1;
    case DAE.T_BOOL() then 1;
    case DAE.T_ENUMERATION(index = NONE()) then 1;
    // The size of an array is its dimension multiplied with the size of its type.
    case DAE.T_ARRAY()
      then intMul(Expression.dimensionSize(dim) for dim in ty.dims) * sizeOfType(ty.ty);
    // The size of a complex type without an equalityConstraint (such as a
    // record), is the sum of the sizes of its components.
    case DAE.T_COMPLEX(varLst = v, equalityConstraint = NONE())
      then sizeOfVariableList(v);
    // The size of a complex type with an equalityConstraint function is
    // determined by the size of the return value of that function.
    case DAE.T_COMPLEX(equalityConstraint = SOME((_, n, _))) then n;
    // The size of a basic subtype with equality constraint is ZERO.
    case DAE.T_SUBTYPE_BASIC(equalityConstraint = SOME(_)) then 0;
    // The size of a basic subtype is the size of the extended type.
    case DAE.T_SUBTYPE_BASIC(complexType = t) then sizeOfType(t);
    // Anything we forgot?
    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ConnectUtil.sizeOfType failed on " + Types.printTypeStr(ty));
      then
        fail();
  end match;
end sizeOfType;

public function checkShortConnectorDef
  "Checks a short connector definition that has extended a basic type, i.e.
   connector C = Real;."
  input ClassInf.State state;
  input SCode.Attributes attributes;
  input SourceInfo info;
  output Boolean isValid;
algorithm
  isValid := match(state, attributes)
    local
      Integer pv = 0, fv = 0, sv = 0;
      SCode.ConnectorType ct;

    // Extended from bidirectional basic type, which means that it can't be
    // balanced.
    case (ClassInf.CONNECTOR(),
        SCode.ATTR(connectorType = ct, direction = Absyn.BIDIR()))
      algorithm
        // The connector might be either flow, stream or neither.
        // This will set either fv, sv, or pv to 1, and the rest to 0, and
        // checkConnectorBalance2 will then be called to provide the appropriate
        // error message (or might actually succeed if +std=2.x or 1.x).
        if SCode.flowBool(ct) then
          fv := 1;
        elseif SCode.streamBool(ct) then
          sv := 1;
        else
          pv := 1;
        end if;
      then
        checkConnectorBalance2(pv, fv, sv, state.path, info);

    // All other cases are ok.
    else true;
  end match;
end checkShortConnectorDef;

public function isReferenceInConnects
  input list<ConnectorElement> connects;
  input DAE.ComponentRef cref;
  output Boolean isThere = false;
algorithm
  for ce in connects loop
    if ComponentReference.crefPrefixOf(cref, ce.name) then
      isThere := true;
      return;
    end if;
  end for;
end isReferenceInConnects;

public function removeReferenceFromConnects
  input output list<ConnectorElement> connects;
  input DAE.ComponentRef cref;
  output Boolean wasRemoved;
protected
  Option<ConnectorElement> oe;
algorithm
  (connects, oe) := List.deleteMemberOnTrue(cref, connects,
    removeReferenceFromConnects2);
  wasRemoved := isSome(oe);
end removeReferenceFromConnects;

protected function removeReferenceFromConnects2
  input DAE.ComponentRef cref;
  input ConnectorElement element;
  output Boolean matches;
algorithm
  matches := ComponentReference.crefPrefixOf(cref, element.name);
end removeReferenceFromConnects2;

public function printSetsStr
  "Prints a Sets to a String."
  input Sets sets;
  output String string;
algorithm
  string := String(sets.setCount) + " sets:\n";
  string := string + printSetTrieStr(sets.sets, "\t");
  string := string + "Connected sets:\n";
  string := string + printSetConnections(sets.connections) + "\n";
end printSetsStr;

protected function printSetTrieStr
  "Prints a SetTrie to a String."
  input SetTrie trie;
  input String accumName;
  output String string;
algorithm
  string := match trie
    local
      String name, res;

    case SetTrieNode.SET_TRIE_LEAF()
      algorithm
        res := accumName + "." + trie.name + ":";
        res := res + printLeafElementStr(trie.insideElement);
        res := res + printLeafElementStr(trie.outsideElement);
        res := res + printOptFlowAssociation(trie.flowAssociation) + "\n";
      then
        res;

    case SetTrieNode.SET_TRIE_NODE(name = "")
      then stringAppendList(List.map1(trie.nodes, printSetTrieStr, accumName));

    case SetTrieNode.SET_TRIE_NODE()
      algorithm
        name := accumName + "." + trie.name;
        res := stringAppendList(List.map1(trie.nodes, printSetTrieStr, name));
      then
        res;

  end match;
end printSetTrieStr;

protected function printLeafElementStr
  "Prints an optional connector element to a String."
  input Option<ConnectorElement> element;
  output String string;
algorithm
  string := match(element)
    local
      ConnectorElement e;
      String res;

    case SOME(e as ConnectorElement.CONNECTOR_ELEMENT())
      algorithm
        res := " " + printFaceStr(e.face) + " ";
        res := res + printConnectorTypeStr(e.ty) + " [" + String(e.set) + "]";
      then
        res;

    else "";

  end match;
end printLeafElementStr;

protected function printElementStr
  "Prints a connector element to a String."
  input ConnectorElement element;
  output String string;
algorithm
  string := ComponentReference.printComponentRefStr(element.name) + " ";
  string := string + printFaceStr(element.face) + " ";
  string := string + printConnectorTypeStr(element.ty) + " [" + String(element.set) + "]";
end printElementStr;

public function printFaceStr
  "Prints the Face to a String."
  input Face face;
  output String string;
algorithm
  string := match face
    case Face.INSIDE() then "inside";
    case Face.OUTSIDE() then "outside";
    case Face.NO_FACE() then "unknown";
  end match;
end printFaceStr;

protected function printConnectorTypeStr
  "Prints the connector type to a String."
  input ConnectorType ty;
  output String string;
algorithm
  string := match ty
    case ConnectorType.EQU() then "equ";
    case ConnectorType.FLOW() then "flow";
    case ConnectorType.STREAM() then "stream";
  end match;
end printConnectorTypeStr;

protected function printOptFlowAssociation
  "Print an optional flow association to a String."
  input Option<DAE.ComponentRef> cref;
  output String string;
algorithm
  string := match cref
    local
      DAE.ComponentRef cr;

    case NONE()
      then "";

    case SOME(cr)
      then " associated flow: " + ComponentReference.printComponentRefStr(cr);

  end match;
end printOptFlowAssociation;

protected function printSetConnections
  "Prints a list of set connection to a String."
  input list<SetConnection> connections;
  output String string;
algorithm
  string := stringAppendList(List.map(connections, printSetConnection));
end printSetConnections;

protected function printSetConnection
  "Prints a set connection to a String."
  input SetConnection connection;
  output String string;
protected
  Integer set1, set2;
algorithm
  (set1, set2) := connection;
  string := "\t" + String(set1) + " connected to " + intString(set2) + "\n";
end printSetConnection;

protected function printSetStr
  "Prints a Set to a String."
  input Set set;
  output String string;
algorithm
  string := match set
    case Set.SET()
      then stringDelimitList(List.map(set.elements, printElementStr), ", ");

    case Set.SET_POINTER()
      then "pointer to set " + intString(set.index);
  end match;
end printSetStr;

protected function getAllEquCrefs
"@author: adrpo
 return all crefs present in EQU sets"
  input list<Set> sets;
  output list<DAE.ComponentRef> crefs = {};
algorithm
  for set in sets loop
    _ := match set
      case Set.SET(ty = ConnectorType.EQU())
        algorithm
          for e in set.elements loop
            crefs := e.name :: crefs;
          end for;
        then
          ();

      else ();
    end match;
  end for;
end getAllEquCrefs;

protected function removeUnusedExpandableVariablesAndConnections
"@author: adrpo
 this function will remove all unconnected/unused/unnecessary expandable variables and connections from the DAE.
 NOTE that this is not so obvious:
 1. collect all expandable variables crefs
 2. collect all expandable crefs used in the DAE (with the expandable variables THAT HAVE NO BINDING removed)
 3. get all expandable crefs that are connected ONLY with expandable
 4. substract: (3)-(2)
 5. remove (4) from the DAE and connection sets
 6. get all the connected potential variables
 7. substract (2) from (1)
 8. substract (6) from (7)
 9. remove (8) from the DAE (5)"
  input output list<Set> sets;
  input output DAE.DAElist DAE;
protected
  list<DAE.Element> elems;
  list<DAE.ComponentRef> expandableVars, unnecessary, usedInDAE, onlyExpandableConnected, equVars;
  DAE.DAElist dae;
  list<list<DAE.ComponentRef>> setsAsCrefs;
algorithm
  DAE.DAE(elems) := DAE;

  // 1 - get all expandable crefs
  expandableVars := getExpandableVariablesWithNoBinding(elems);
  // print("All expandable (1):\n  " + stringDelimitList(List.map(expandableVars, ComponentReference.printComponentRefStr), "\n  ") + "\n");

  // 2 - remove all expandable without binding from the dae
  dae := DAEUtil.removeVariables(DAE, expandableVars);
  // 2 - get all expandable crefs used in the dae (without the expandable vars)
  usedInDAE := DAEUtil.getAllExpandableCrefsFromDAE(dae);
  // print("Used in the DAE (2):\n  " + stringDelimitList(List.map(usedInDAE, ComponentReference.printComponentRefStr), "\n  ") + "\n");

  // 3 - get all expandable crefs that are connected ONLY with expandable
  setsAsCrefs := getExpandableEquSetsAsCrefs(sets);
  setsAsCrefs := mergeEquSetsAsCrefs(setsAsCrefs);
  // TODO! FIXME! maybe we should do fixpoint here??
  setsAsCrefs := mergeEquSetsAsCrefs(setsAsCrefs);
  onlyExpandableConnected := getOnlyExpandableConnectedCrefs(setsAsCrefs);
  // print("All expandable - expandable connected (3):\n  " + stringDelimitList(List.map(onlyExpandableConnected, ComponentReference.printComponentRefStr), "\n  ") + "\n");

  // 4 - subtract (2) from (3)
  unnecessary := List.setDifferenceOnTrue(onlyExpandableConnected, usedInDAE, ComponentReference.crefEqualWithoutSubs);
  // print("REMOVE: (3)-(2):\n  " + stringDelimitList(List.map(unnecessary, ComponentReference.printComponentRefStr), "\n  ") + "\n");

  // 5 - remove unnecessary variables form the DAE
  DAE := DAEUtil.removeVariables(DAE, unnecessary);
  // 5 - remove unnecessary variables form the connection sets
  sets := removeCrefsFromSets(sets, unnecessary);

  equVars := getAllEquCrefs(sets);
  // print("(6):\n  " + stringDelimitList(List.map(equVars, ComponentReference.printComponentRefStr), "\n  ") + "\n");
  expandableVars := List.setDifferenceOnTrue(expandableVars, usedInDAE, ComponentReference.crefEqualWithoutSubs);
  // print("(1)-(2)=(7):\n  " + stringDelimitList(List.map(equVars, ComponentReference.printComponentRefStr), "\n  ") + "\n");
  unnecessary := List.setDifferenceOnTrue(expandableVars, equVars, ComponentReference.crefEqualWithoutSubs);
  // print("REMOVE: (7)-(6):\n  " + stringDelimitList(List.map(unnecessary, ComponentReference.printComponentRefStr), "\n  ") + "\n");
  DAE := DAEUtil.removeVariables(DAE, unnecessary);
end removeUnusedExpandableVariablesAndConnections;

protected function isEquType
  input ConnectorType ty;
  output Boolean isEqu;
algorithm
  isEqu := match ty
    case ConnectorType.EQU() then true;
    else false;
  end match;
end isEquType;

annotation(__OpenModelica_Interface="frontend");
end ConnectUtil;
