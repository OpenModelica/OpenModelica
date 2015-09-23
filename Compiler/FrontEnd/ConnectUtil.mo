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

  RCS: $Id: ConnectUtil.mo 25082 2015-03-13 09:40:07Z lochel $

  Connections generate connection sets (datatype SET is described in Connect)
  which are constructed during instantiation.  When a connection
  set is generated, it is used to create a number of equations.
  The kind of equations created depends on the type of the set.

  ConnectUtil.mo is called from Inst.mo and is responsible for
  creation of all connect-equations later passed to the DAE module
  in DAEUtil.mo."

// public imports
public import Absyn;
public import SCode;
public import ClassInf;
public import Config;
public import Connect;
public import DAE;
public import FCore;
public import InnerOuter;
public import Prefix;
public import ConnectionGraph;

// protected imports
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;
protected import Lookup;
protected import PrefixUtil;
protected import System;
protected import Types;
protected import Util;
protected import InstSection;

// Import some types from Connect.
public type Face = Connect.Face;
public type ConnectorType = Connect.ConnectorType;
public type ConnectorElement = Connect.ConnectorElement;
public type SetTrieNode = Connect.SetTrieNode;
public type SetTrie = Connect.SetTrie;
public type SetConnection = Connect.SetConnection;
public type OuterConnect = Connect.OuterConnect;
public type Sets = Connect.Sets;
public type Set = Connect.Set;

// Set graph represented as an adjacency list.
protected type SetGraph = array<list<Integer>>;

public function newSet
  "This function creates a 'new' set for the given prefix. This means that it
  makes a set with a new empty trie, but copies the set count and connection
  crefs from the old set. This is done because we don't need to propagate
  connections down in the instance hierarchy, but the list of connection crefs
  needs to be propagated to be able to evaluate the cardinality operator. See
  comments in addSet below for how the sets are merged later."
  input Prefix.Prefix inPrefix;
  input Sets inSets;
  output Sets outSets;
algorithm
  outSets := matchcontinue(inPrefix, inSets)
    local
      String pstr;
      Integer sc;
      DAE.ComponentRef cr;

    case (_, Connect.SETS(setCount = sc))
      equation
        cr = PrefixUtil.prefixFirstCref(inPrefix);
        pstr = ComponentReference.printComponentRefStr(cr);
      then
        Connect.SETS(Connect.SET_TRIE_NODE(pstr, cr, {}, 0), sc, {}, {});

    case (_, Connect.SETS(setCount = sc))
      then
        Connect.SETS(Connect.SET_TRIE_NODE("", DAE.WILD(), {}, 0), sc, {}, {});

  end matchcontinue;
end newSet;

public function addSet
  "This function adds a child set to a parent set."
  input Connect.Sets inParentSets;
  input Connect.Sets inChildSets;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(inParentSets, inChildSets)
    local
      String name;
      list<SetTrieNode> nodes;
      list<SetConnection> c1, c2;
      list<OuterConnect> o1, o2;
      Integer sc, count;
      SetTrieNode node;
      DAE.ComponentRef cr;

    // If the child set is empty we don't need to add it.
    case (_, _)
      equation
        true = isEmptySet(inChildSets);
      then
        inParentSets;

    // If both sets are nameless, i.e. a top scope set, just return the child
    // set as it is. This is to avoid getting nestled top scope sets in some
    // cases, and the child should be a superset of the parent.
    case (Connect.SETS(sets = Connect.SET_TRIE_NODE(cref = DAE.WILD())),
        Connect.SETS(sets = Connect.SET_TRIE_NODE(cref = DAE.WILD())))
      then inChildSets;

    // Check if the node already exists. In that case it's probably due to
    // multiple inheritance and we should ignore it.
    case (Connect.SETS(sets = Connect.SET_TRIE_NODE(nodes = nodes)),
        Connect.SETS(sets = node))
      equation
        name = setTrieNodeName(node);
        _ = setTrieGetNode(name, nodes);
      then
        inParentSets;

    // In the normal case we add the trie on the child sets to the parent, and
    // also merge their lists of outer connects.
    case (Connect.SETS(Connect.SET_TRIE_NODE(name = name, cref = cr,
        nodes = nodes, connectCount = count), _, c1, o1), Connect.SETS(node, sc, c2, o2))
      equation
        c1 = listAppend(c2, c1);
        o1 = listAppend(o2, o1);
        nodes = node :: nodes;
      then
        Connect.SETS(Connect.SET_TRIE_NODE(name, cr, nodes, count), sc, c1, o1);

  end matchcontinue;
end addSet;

protected function isEmptySet
  "Check if a given set is empty."
  input Connect.Sets inSets;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match(inSets)
    case Connect.SETS(sets = Connect.SET_TRIE_NODE(nodes = {}),
      connections = {}, outerConnects = {}) then true;
    else false;
  end match;
end isEmptySet;

protected function setSets
  input SetTrie inTrie;
  input Sets inSets;
  output Sets outSets;
protected
  Integer sc;
  list<SetConnection> c;
  list<OuterConnect> o;
algorithm
  Connect.SETS(_, sc, c, o) := inSets;
  outSets := Connect.SETS(inTrie, sc, c, o);
end setSets;

public function addConnection
  "Adds a new connection by looking up both the given connector elements in the
   set trie and merging the sets together."
  input Sets inSets;
  input DAE.ComponentRef inCref1;
  input Face inFace1;
  input DAE.ComponentRef inCref2;
  input Face inFace2;
  input SCode.ConnectorType inConnectorType;
  input DAE.ElementSource inSource;
  output Sets outSets;
algorithm
  outSets := match(inSets, inCref1, inFace1, inCref2, inFace2, inConnectorType, inSource)
    local
      ConnectorElement e1, e2;
      ConnectorType ty;
      Sets sets;

    case (_, _, _, _, _, _, _)
      equation
        ty = makeConnectorType(inConnectorType);
        e1 = findElement(inCref1, inFace1, ty, inSource, inSets);
        e2 = findElement(inCref2, inFace2, ty, inSource, inSets);
        sets = mergeSets(e1, e2, inSets);
      then
        sets;

  end match;
end addConnection;

protected function getConnectCount
  input DAE.ComponentRef inCref;
  input SetTrie inTrie;
  output Integer outCount;
algorithm
  outCount := matchcontinue(inCref, inTrie)
    local
      SetTrieNode node;
      Integer count;

    case (_, _)
      equation
        node = setTrieGet(inCref, inTrie, false);
      then
        getConnectCount2(node);

    else 0;
  end matchcontinue;
end getConnectCount;

protected function getConnectCount2
  input SetTrieNode inNode;
  output Integer outCount;
algorithm
  outCount := match(inNode)
    local
      Integer count;

    case Connect.SET_TRIE_NODE(connectCount = count) then count;
    case Connect.SET_TRIE_LEAF(connectCount = count) then count;

  end match;
end getConnectCount2;

public function addArrayConnection
  "Connects two arrays of connectors."
  input Connect.Sets inSets;
  input DAE.ComponentRef inCref1;
  input Connect.Face inFace1;
  input DAE.ComponentRef inCref2;
  input Connect.Face inFace2;
  input DAE.ElementSource inSource;
  input SCode.ConnectorType inConnectorType;
  output Connect.Sets outSets;
algorithm
  outSets :=
  match(inSets, inCref1, inFace1, inCref2, inFace2, inSource, inConnectorType)
    local
      list<DAE.ComponentRef> crefs1, crefs2;

    case (_, _, _, _, _, _, _)
      equation
        crefs1 = ComponentReference.expandCref(inCref1,false);
        crefs2 = ComponentReference.expandCref(inCref2,false);
      then
        addArrayConnection2(inSets, crefs1, inFace1, crefs2, inFace2, inSource,
          inConnectorType);

  end match;
end addArrayConnection;

protected function addArrayConnection2
  input Connect.Sets inSets;
  input list<DAE.ComponentRef> inCrefs1;
  input Connect.Face inFace1;
  input list<DAE.ComponentRef> inCrefs2;
  input Connect.Face inFace2;
  input DAE.ElementSource inSource;
  input SCode.ConnectorType inConnectorType;
  output Connect.Sets outSets;
algorithm
  outSets := match(inSets, inCrefs1, inFace1, inCrefs2, inFace2, inSource,
      inConnectorType)
    local
      DAE.ComponentRef cref1, cref2;
      list<DAE.ComponentRef> rest_crefs1, rest_crefs2;
      Connect.Sets cs;

    case (cs, cref1 :: rest_crefs1, _, cref2 :: rest_crefs2, _, _, _)
      equation
        cs = addConnection(cs, cref1, inFace1, cref2, inFace2, inConnectorType, inSource);
      then
        addArrayConnection2(cs, rest_crefs1, inFace1, rest_crefs2, inFace2,
          inSource, inConnectorType);

    else inSets;

  end match;
end addArrayConnection2;

protected function makeConnectorType
  "Creates a connector type from the flow or stream prefix given."
  input SCode.ConnectorType inConnectorType;
  output ConnectorType outType;
algorithm
  outType := match(inConnectorType)
    case SCode.POTENTIAL() then Connect.EQU();
    case SCode.FLOW() then Connect.FLOW();
    case SCode.STREAM() then Connect.STREAM(NONE());
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"ConnectUtil.makeConnectorType: invalid connector type."});
      then
        fail();
  end match;
end makeConnectorType;

public function addConnectorVariablesFromDAE
  "If the class state indicates a connector, this function adds all flow
  variables in the dae as inside connectors to the connection sets."
  input Boolean inIgnore;
  input ClassInf.State inClassState;
  input Prefix.Prefix inPrefix;
  input list<DAE.Var> inVars;
  input Sets inConnectionSet;
  input SourceInfo info;
  input DAE.ElementSource inElementSource;
  output Sets outConnectionSet;
algorithm
  outConnectionSet :=
  match(inIgnore, inClassState, inPrefix, inVars, inConnectionSet, info, inElementSource)
    local
      Absyn.Path class_path;
      list<DAE.Var> vars, streams, flows;
      Sets cs;

    // check balance of non expandable connectors!
    case (false, ClassInf.CONNECTOR(path = class_path, isExpandable = false), _, _, cs, _, _)
      equation
        checkConnectorBalance(inVars, class_path, info);
        vars = if Flags.isSet(Flags.DISABLE_SINGLE_FLOW_EQ) then {} else inVars;
        (flows, streams) = getStreamAndFlowVariables(vars, {}, {});
        cs = List.fold2(flows, addFlowVariableFromDAE, inElementSource, inPrefix, cs);
        cs = addStreamFlowAssociations(cs, inPrefix, streams, flows);
      then
        cs;

    else inConnectionSet;
  end match;
end addConnectorVariablesFromDAE;

protected function addFlowVariableFromDAE
  "Adds a flow variable from the DAE to the sets as an inside flow variable."
  input DAE.Var inVariable;
  input DAE.ElementSource inElementSource;
  input Prefix.Prefix inPrefix;
  input Sets inConnectionSet;
  output Sets outConnectionSet;
protected
  list<DAE.ComponentRef> crefs;
algorithm
  crefs := daeVarToCrefs(inVariable);
  outConnectionSet := List.fold2r(crefs, addInsideFlowVariable,
    inElementSource, inPrefix, inConnectionSet);
end addFlowVariableFromDAE;

public function isExpandable
  input DAE.ComponentRef inName;
  output Boolean isExpandableConnector;
algorithm
  isExpandableConnector := match(inName)
    local
      DAE.Type ty;
      Boolean b;
      DAE.ComponentRef cr;

    case (DAE.CREF_IDENT(identType = ty))
      equation
        b = InstSection.isExpandableConnectorType(ty);
      then
        b;

    case (DAE.CREF_QUAL(identType = ty, componentRef = cr))
      equation
        b = InstSection.isExpandableConnectorType(ty);
        b = diveIsExpandable(b, cr);
      then
        b;

    else false;

  end match;
end isExpandable;

protected function diveIsExpandable
"@author: adrpo
 if isExpandable is true don't dive in"
  input Boolean inIsExpandable;
  input DAE.ComponentRef inName;
  output Boolean b;
algorithm
  b := match(inIsExpandable, inName)

    case (true, _) then true;

    case (false, _)
      equation
        b = isExpandable(inName);
      then
        b;

  end match;
end diveIsExpandable;

protected function daeHasExpandableConnectors
"Goes through a list of variables and returns their crefs"
  input DAE.DAElist inDAE;
  output Boolean hasExpandable;
algorithm
  hasExpandable := matchcontinue(inDAE)
    local
      list<DAE.Element> vars;
      DAE.ComponentRef name;
      Boolean b;

    // if we didn't detect any there aren't any
    case (_)
      equation
        false = System.getHasExpandableConnectors();
      then false;

    case (DAE.DAE(vars)) then List.exist(vars, isVarExpandable);

  end matchcontinue;
end daeHasExpandableConnectors;

protected function isVarExpandable
  input DAE.Element var;
  output Boolean b;
algorithm
  b := match var
    local
      DAE.ComponentRef name;
    case DAE.VAR(componentRef = name) then isExpandable(name);
    else false;
  end match;
end isVarExpandable;

protected function getExpandableVariablesWithNoBinding
"@author: adrpo
 Goes through a list of expandable variables
 THAT HAVE NO BINDING and returns their crefs"
  input list<DAE.Element> inVariables;
  input list<DAE.ComponentRef> inAccPotential;
  output list<DAE.ComponentRef> outPotential;
algorithm
  outPotential := match (inVariables, inAccPotential)
    local
      list<DAE.Element> rest_vars;
      DAE.ComponentRef name;
      list<DAE.ComponentRef> potential;
      Option<DAE.Exp> bnd;

    case ({}, _) then (inAccPotential);

    // do not return the ones that have a binding as they are used
    // TODO: actually only if their binding is not another expandable??!!
    case (DAE.VAR(componentRef = name, binding = bnd) :: rest_vars, _)
      equation
        potential =
          if isSome(bnd)
            then inAccPotential
            else List.consOnTrue(isExpandable(name), name, inAccPotential);
        potential = getExpandableVariablesWithNoBinding(rest_vars, potential);
      then
        potential;

    case (_::rest_vars, _)
      equation
        potential = getExpandableVariablesWithNoBinding(rest_vars, inAccPotential);
      then
        potential;

  end match;
end getExpandableVariablesWithNoBinding;

protected function getStreamAndFlowVariables
  "Goes through a list of variables and filters out all flow and stream
  variables into separate lists."
  input list<DAE.Var> inVariable;
  input list<DAE.Var> inAccFlows;
  input list<DAE.Var> inAccStreams;
  output list<DAE.Var> outFlows;
  output list<DAE.Var> outStreams;
algorithm
  (outFlows, outStreams) := match(inVariable, inAccFlows, inAccStreams)
    local
      DAE.Var var;
      list<DAE.Var> rest_vars, flows, streams;

    case ({}, _, _) then (inAccFlows, inAccStreams);

    case ((var as DAE.TYPES_VAR(attributes = DAE.ATTR(
        connectorType = SCode.FLOW()))) :: rest_vars, _, _)
      equation
        (flows, streams) =
          getStreamAndFlowVariables(rest_vars, var :: inAccFlows, inAccStreams);
      then
        (flows, streams);

    case ((var as DAE.TYPES_VAR(attributes = DAE.ATTR(
        connectorType = SCode.STREAM()))) :: rest_vars, _, _)
      equation
        (flows, streams) =
          getStreamAndFlowVariables(rest_vars, inAccFlows, var :: inAccStreams);
      then
        (flows, streams);

    case (_ :: rest_vars, _ ,_)
      equation
        (flows, streams) =
          getStreamAndFlowVariables(rest_vars, inAccFlows, inAccStreams);
      then
        (flows, streams);

  end match;
end getStreamAndFlowVariables;

protected function addStreamFlowAssociations
  "Adds information to the connection sets about which flow variables each
  stream variable is associated to."
  input Sets inSets;
  input Prefix.Prefix inPrefix;
  input list<DAE.Var> inStreamVars;
  input list<DAE.Var> inFlowVars;
  output Sets outSets;
algorithm
  outSets := match(inSets, inPrefix, inStreamVars, inFlowVars)
    local
      DAE.Var flow_var;
      DAE.ComponentRef flow_cr;
      list<DAE.ComponentRef> stream_crs;
      Sets sets;

    // No stream variables => not a stream connector.
    case (_, _, {}, _) then inSets;

    // Stream variables and exactly one flow => add associations.
    case (_, _, _, {flow_var})
      equation
        {flow_cr} = daeVarToCrefs(flow_var);
        flow_cr = PrefixUtil.prefixCrefNoContext(inPrefix, flow_cr);
        stream_crs = List.mapFlat(inStreamVars, daeVarToCrefs);
        sets = List.fold1(stream_crs, addStreamFlowAssociation,
          flow_cr, inSets);
      then sets;
  end match;
end addStreamFlowAssociations;

protected function daeVarToCrefs
  "Converts a DAE.Var to a list of crefs."
  input DAE.Var inVar;
  output list<DAE.ComponentRef> outCrefs;
protected
  String name;
  DAE.Type ty;
  list<DAE.ComponentRef> crefs;
  DAE.Dimensions dims;
  DAE.ComponentRef cr;
algorithm
  DAE.TYPES_VAR(name = name, ty = ty) := inVar;
  ty := Types.derivedBasicType(ty);

  outCrefs := match ty
    // Scalar
    case DAE.T_REAL() then {DAE.CREF_IDENT(name, ty, {})};

    // Complex type
    case DAE.T_COMPLEX()
      algorithm
        crefs := listAppend(daeVarToCrefs(v) for v in listReverse(ty.varLst));
        cr := DAE.CREF_IDENT(name, DAE.T_REAL_DEFAULT, {});
      then
        list(ComponentReference.joinCrefs(cr, c) for c in crefs);

    // Array
    case DAE.T_ARRAY()
      algorithm
        dims := Types.getDimensions(ty);
        cr := DAE.CREF_IDENT(name, ty, {});
      then
        expandArrayCref(cr, dims, {});

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
  input DAE.ComponentRef inCref;
  input DAE.Dimensions inDims;
  input list<DAE.ComponentRef> inAccumCrefs;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  outCrefs := matchcontinue(inCref, inDims, inAccumCrefs)
    local
      DAE.Dimension dim;
      DAE.Dimensions dims;
      DAE.Exp idx;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;

    case (_, {}, _) then inCref :: inAccumCrefs;

    case (_, dim :: dims, _)
      equation
        (idx, dim) = getNextIndex(dim);
        cr = ComponentReference.subscriptCref(inCref, {DAE.INDEX(idx)});
        crefs = expandArrayCref(cr, dims, inAccumCrefs);
        crefs = expandArrayCref(inCref, dim :: dims, crefs);
      then
        crefs;

    else inAccumCrefs;

  end matchcontinue;
end expandArrayCref;

protected function reverseEnumType
  "Reverses the order of the literals in an enumeration dimension, or just
  returns the given dimension if it's not an enumeration. This is used by
  getNextIndex that starts from the end, so that it can take the first literal
  in the list instead of the last (more efficient)."
  input DAE.Dimension inDim;
  output DAE.Dimension outDim;
algorithm
  outDim := match(inDim)
    local
      Absyn.Path p;
      list<String> lits;
      Integer dim_size;
    case DAE.DIM_ENUM(p, lits, dim_size)
      equation
        lits = listReverse(lits);
      then DAE.DIM_ENUM(p, lits, dim_size);
    else inDim;
  end match;
end reverseEnumType;

protected function getNextIndex
  "Returns the next index given a dimension, and updates the dimension. Fails
  when there are no indices left."
  input DAE.Dimension inDim;
  output DAE.Exp outNextIndex;
  output DAE.Dimension outDim;
algorithm
  (outNextIndex, outDim) := match(inDim)
    local
      Integer new_idx, dim_size;
      Absyn.Path p, ep;
      String l;
      list<String> l_rest;

    case DAE.DIM_INTEGER(integer = 0) then fail();
    case DAE.DIM_ENUM(size = 0) then fail();

    case DAE.DIM_INTEGER(integer = new_idx)
      equation
        dim_size = new_idx - 1;
      then
        (DAE.ICONST(new_idx), DAE.DIM_INTEGER(dim_size));

    // Assumes that the enum has been reversed with reverseEnumType.
    case DAE.DIM_ENUM(p, l :: l_rest, new_idx)
      equation
        ep = Absyn.joinPaths(p, Absyn.IDENT(l));
        dim_size = new_idx - 1;
      then
        (DAE.ENUM_LITERAL(ep, new_idx), DAE.DIM_ENUM(p, l_rest, dim_size));
  end match;
end getNextIndex;

protected function addInsideFlowVariable
  "Adds a single inside flow variable to the connection sets."
  input Connect.Sets inSets;
  input DAE.ComponentRef inCref;
  input DAE.ElementSource inSource;
  input Prefix.Prefix inPrefix;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(inSets, inCref, inSource, inPrefix)
    local
      ConnectorElement e;
      SetTrie sets;
      Integer sc;
      list<SetConnection> c;
      list<OuterConnect> o;
      SourceInfo info;
      DAE.ElementSource src;

    // Check if it exists in the sets already.
    case (Connect.SETS(sets = sets), _, _, _)
      equation
        _ = setTrieGetElement(inCref, Connect.INSIDE(), sets);
      then
        inSets;

    // Otherwise, add a new set for it.
    case (Connect.SETS(sets, sc, c, o), _, DAE.SOURCE(), _)
      equation
        sc = sc + 1;
        //src = DAEUtil.addAdditionalComment(inSource, " add inside flow(" +
        //        PrefixUtil.printPrefixStr(inPrefix) + "/" +
        //        ComponentReference.printComponentRefStr(inCref) +
        //        ")");
        e = newElement(inCref, Connect.INSIDE(), Connect.FLOW(), inSource, sc);
        sets = setTrieAdd(e, sets);
      then
        Connect.SETS(sets, sc, c, o);

  end matchcontinue;
end addInsideFlowVariable;

protected function addStreamFlowAssociation
  "Adds an association between a stream variable and a flow."
  input DAE.ComponentRef inStreamCref;
  input DAE.ComponentRef inFlowCref;
  input Connect.Sets inSets;
  output Connect.Sets outSets;
algorithm
  outSets := updateSetLeaf(inSets, inStreamCref, inFlowCref,
    addStreamFlowAssociation2);
end addStreamFlowAssociation;

protected function addStreamFlowAssociation2
  "Helper function to addSTreamFlowAssocication, sets the flow association in a
  leaf node."
  input DAE.ComponentRef inFlowCref;
  input SetTrieNode inNode;
  output SetTrieNode outNode;
algorithm
  outNode := match(inFlowCref, inNode)
    local
      String name;
      Option<ConnectorElement> ie, oe;
      Integer c;

    case (_, Connect.SET_TRIE_LEAF(name, ie, oe, _, c))
      then Connect.SET_TRIE_LEAF(name, ie, oe, SOME(inFlowCref), c);

  end match;
end addStreamFlowAssociation2;

protected function getStreamFlowAssociation
  "Returns the associated flow variable for a stream variable."
  input DAE.ComponentRef inStreamCref;
  input Connect.Sets inSets;
  output DAE.ComponentRef outFlowCref;
protected
  SetTrie sets;
algorithm
  Connect.SETS(sets = sets) := inSets;
  Connect.SET_TRIE_LEAF(flowAssociation = SOME(outFlowCref)) :=
    setTrieGet(inStreamCref, sets, false);
end getStreamFlowAssociation;

public function addOuterConnect
  "Adds an outer connect to a Connect.Sets."
  input Sets inSets;
  input OuterConnect inOuterConnect;
  output Sets outSets;
protected
  SetTrie sets;
  Integer sc;
  list<SetConnection> c;
  list<OuterConnect> o;
algorithm
  Connect.SETS(sets, sc, c, o) := inSets;
  outSets := Connect.SETS(sets, sc, c, inOuterConnect :: o);
end addOuterConnect;

public function setOuterConnects
  "Sets the outer connect part of a Connect.Sets."
  input Sets inSets;
  input list<OuterConnect> inOuterConnects;
  output Sets outSets;
protected
  SetTrie sets;
  Integer sc;
  list<SetConnection> c;
algorithm
  Connect.SETS(sets, sc, c, _) := inSets;
  outSets := Connect.SETS(sets, sc, c, inOuterConnects);
end setOuterConnects;

public function addOuterConnection
  "Adds a connection with a reference to an outer connector These are added to a
   special list, such that they can be moved up in the instance hierarchy to a
   place where both instances are defined."
  input Prefix.Prefix scope;
  input Connect.Sets sets;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Connect.Face f1;
  input Connect.Face f2;
  input DAE.ElementSource source;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(scope,sets,cr1,cr2,io1,io2,f1,f2,source)
    local
      list<Connect.OuterConnect> oc;
      Connect.OuterConnect new_oc;
    // First check if already added
    case(_, Connect.SETS(outerConnects = oc),_,_,_,_,_,_,_)
      equation
        _::_ = List.select2(oc,outerConnectionMatches,cr1,cr2);
      then sets;
    // add the outerconnect
    else
      equation
        new_oc = Connect.OUTERCONNECT(scope, cr1, io1, f1, cr2, io2, f2, source);
      then addOuterConnect(sets, new_oc);
  end matchcontinue;
end addOuterConnection;

protected function outerConnectionMatches
  "Returns true if Connect.OuterConnect matches the two component references
  passed as argument."
  input Connect.OuterConnect oc;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean matches;
algorithm
  matches := match(oc,cr1,cr2)
    local DAE.ComponentRef cr11,cr22;
    case(Connect.OUTERCONNECT(cr1=cr11,cr2=cr22),_,_)
      equation
        matches =
        ComponentReference.crefEqual(cr11,cr1) and ComponentReference.crefEqual(cr22,cr2) or
        ComponentReference.crefEqual(cr11,cr2) and ComponentReference.crefEqual(cr22,cr1);
      then matches;
  end match;
end outerConnectionMatches;

public function addDeletedComponent
  "Marks a component as deleted in the sets."
  input String inComponentName;
  input Sets inSets;
  output Sets outSets;
protected
  SetTrie sets;
  Integer sc, count;
  list<SetConnection> c;
  list<OuterConnect> o;
  String name;
  DAE.ComponentRef cref;
  list<SetTrieNode> nodes;
algorithm
  Connect.SETS(sets, sc, c, o) := inSets;
  Connect.SET_TRIE_NODE(name, cref, nodes, count) := sets;
  nodes := Connect.SET_TRIE_DELETED(inComponentName) :: nodes;
  sets := Connect.SET_TRIE_NODE(name, cref, nodes, count);
  outSets := Connect.SETS(sets, sc, c, o);
end addDeletedComponent;

protected function isDeletedComponent
  "Checks if the given component is deleted or not."
  input DAE.ComponentRef inComponent;
  input SetTrie inSets;
protected
  DAE.ComponentRef cr;
algorithm
  // Send true as last argument to setTrieGet, so that it also matches any
  // prefix of the cref in case the cref is a subcomponent of a deleted component.
  //cr := ComponentReference.crefStripSubs(inComponent);
  Connect.SET_TRIE_DELETED() := setTrieGet(inComponent, inSets, true);
end isDeletedComponent;

public function connectionContainsDeletedComponents
  "Checks if a connection contains a deleted component, i.e. if either of the
  given crefs belong to a deleted component."
  input DAE.ComponentRef inComponent1;
  input DAE.ComponentRef inComponent2;
  input Sets inSets;
  output Boolean containsDeletedComponent;
algorithm
  containsDeletedComponent := matchcontinue(inComponent1, inComponent2, inSets)
    local
      SetTrie sets;

    // No sets, so nothing can be deleted.
    case (_, _, Connect.SETS(sets = Connect.SET_TRIE_NODE(nodes = {})))
      then
        false;

    // Check if the first component is deleted.
    case (_, _, Connect.SETS(sets = sets))
      equation
        isDeletedComponent(inComponent1, sets);
      then
        true;

    // Check if the second component is deleted.
    case (_, _, Connect.SETS(sets = sets))
      equation
        isDeletedComponent(inComponent2, sets);
      then
        true;

    else false;
  end matchcontinue;
end connectionContainsDeletedComponents;

public function addOuterConnectToSets
  "Adds an outer connection to all sets where a corresponding inner definition
  is present. For instance, if a connection set contains {world.v, topPin.v} and
  we have an outer connection connect(world, a2.aPin), the connection is added
  to the sets, resulting in {world.v, topPin.v, a2.aPin.v}. Returns the updated
  sets and a boolean that indicates if anything was added or not."
  input DAE.ComponentRef inCref1;
  input DAE.ComponentRef inCref2;
  input Absyn.InnerOuter inIO1;
  input Absyn.InnerOuter inIO2;
  input Connect.Face inFace1;
  input Connect.Face inFace2;
  input Connect.Sets inSets;
  input SourceInfo inInfo;
  output Connect.Sets outSets;
  output Boolean outAdded;
protected
  Boolean is_outer1, is_outer2;
algorithm
  is_outer1 := Absyn.isOuter(inIO1);
  is_outer2 := Absyn.isOuter(inIO2);
  (outSets, outAdded) := addOuterConnectToSets2(inCref1, inCref2, is_outer1,
    is_outer2, inFace1, inFace2, inSets, inInfo);
end addOuterConnectToSets;

protected function addOuterConnectToSets2
  "Helper function to addOuterConnectToSets. Dispatches based on the inner/outer
   prefix of both connector elements."
  input DAE.ComponentRef inCref1;
  input DAE.ComponentRef inCref2;
  input Boolean inIsOuter1;
  input Boolean inIsOuter2;
  input Face inFace1;
  input Face inFace2;
  input Sets inSets;
  input SourceInfo inInfo;
  output Sets outSets;
  output Boolean outAdded;
algorithm
  (outSets, outAdded) := match(inCref1, inCref2, inIsOuter1, inIsOuter2,
      inFace1, inFace2, inSets, inInfo)
    local
      Sets sets;
      Boolean added;

    // Both are outer => error.
    case (_, _, true, true, _, _, _, _)
      equation
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,
          {"Connections where both connectors are outer references", "No suggestion"}, inInfo);
      then
        (inSets, false);

    // Both are inner => do nothing.
    case (_, _, false, false, _, _, _, _) then (inSets, false);

    // The first is outer and the second inner, call addOuterConnectToSets3.
    case (_, _, true, false, _, _, _, _)
      equation
        (sets, added) = addOuterConnectToSets3(inCref1, inCref2, inFace1,
          inFace2, inSets);
      then
        (sets, added);

    // The first is inner and the second outer, call addOuterConnectToSets3 with
    // reversed order on the components compared to above.
    case (_, _, false, true, _, _, _, _)
      equation
        (sets, added) = addOuterConnectToSets3(inCref2, inCref1, inFace2,
          inFace1, inSets);
      then
        (sets, added);
  end match;
end addOuterConnectToSets2;

protected function addOuterConnectToSets3
  "Helper function to addOuterConnectToSets2. Tries to add connections between
   the inner and outer components."
  input DAE.ComponentRef inOuterCref;
  input DAE.ComponentRef inInnerCref;
  input Face inOuterFace;
  input Face inInnerFace;
  input Sets inSets;
  output Sets outSets;
  output Boolean outAdded;
algorithm
  (outSets, outAdded) :=
  matchcontinue(inOuterCref, inInnerCref, inOuterFace, inInnerFace, inSets)
    local
      Sets sets;
      SetTrieNode node;
      SetTrie trie;
      Integer sc, sets_added;
      list<ConnectorElement> outer_els, inner_els;
      Boolean added;

    case (_, _, _, _, Connect.SETS(sets = trie, setCount = sc))
      equation
        // Find the trie node for the outer component.
        node = setTrieGet(inOuterCref, trie, true);
        // Collect all connector elements in the node.
        outer_els = collectOuterElements(node, inOuterFace);
        // Find or create inner elements corresponding to the outer elements.
        inner_els = List.map3(outer_els, findInnerElement, inInnerCref,
          inInnerFace, inSets);
        // Merge the inner and outer sets pairwise from the two lists.
        (sets as Connect.SETS(setCount = sets_added)) = List.threadFold(outer_els, inner_els, mergeSets, inSets);
        // Check if the number of sets changed.
        added = not intEq(sc, sets_added);
      then
        (sets, added);

    else (inSets, false);

  end matchcontinue;
end addOuterConnectToSets3;

protected function collectOuterElements
  "Collects all connector elements with a certain face from a trie node."
  input SetTrieNode inNode;
  input Connect.Face inFace;
  output list<ConnectorElement> outOuterElements;
algorithm
  outOuterElements := match(inNode, inFace)
    local
      list<SetTrieNode> nodes;

    case (Connect.SET_TRIE_NODE(nodes = nodes), _)
      then List.map2Flat(nodes, collectOuterElements2, inFace, NONE());

    else collectOuterElements2(inNode, inFace, NONE());
  end match;
end collectOuterElements;

protected function collectOuterElements2
  "Helper function to collectOuterElements."
  input SetTrieNode inNode;
  input Connect.Face inFace;
  input Option<DAE.ComponentRef> inPrefix;
  output list<ConnectorElement> outOuterElements;
algorithm
  outOuterElements := match(inNode, inFace, inPrefix)
    local
      DAE.ComponentRef cr;
      list<SetTrieNode> nodes;
      ConnectorElement e;

    case (Connect.SET_TRIE_NODE(cref = cr, nodes = nodes), _, _)
      equation
        cr = optPrefixCref(inPrefix, cr);
      then
        List.map2Flat(nodes, collectOuterElements2, inFace, SOME(cr));

    case (Connect.SET_TRIE_LEAF(), _, _)
      equation
        e = setTrieGetLeafElement(inNode, inFace);
        cr = getElementName(e);
        e = setElementName(e, optPrefixCref(inPrefix, cr));
      then
        {e};

    case (Connect.SET_TRIE_DELETED(), _, _) then {};

  end match;
end collectOuterElements2;

protected function findInnerElement
  "Finds or creates an inner element based on a given outer element."
  input ConnectorElement inOuterElement;
  input DAE.ComponentRef inInnerCref;
  input Face inInnerFace;
  input Sets inSets;
  output ConnectorElement outInnerElement;
protected
  DAE.ComponentRef name;
  ConnectorType ty;
  DAE.ElementSource src;
algorithm
  Connect.CONNECTOR_ELEMENT(name = name, ty = ty, source = src) := inOuterElement;
  name := ComponentReference.joinCrefs(inInnerCref, name);
  outInnerElement := findElement(name, inInnerFace, ty, src, inSets);
end findInnerElement;

protected function optPrefixCref
  "Appends an optional prefix to a cref."
  input Option<DAE.ComponentRef> inPrefix;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inPrefix, inCref)
    local
      DAE.ComponentRef cr;

    case (NONE(), _) then inCref;
    case (SOME(cr), _)
      then ComponentReference.joinCrefs(cr, inCref);

  end match;
end optPrefixCref;

protected function findElement
  "Tries to find a connector element in the sets given a cref and a face. If no
   element can be found it creates a new one."
  input DAE.ComponentRef inCref;
  input Face inFace;
  input ConnectorType inType;
  input DAE.ElementSource inSource;
  input Sets inSets;
  output ConnectorElement outElement;
algorithm
  outElement := matchcontinue(inCref, inFace, inType, inSource, inSets)
    local
      SetTrie sets;

    // first try the actual face
    case (_, _, _, _, Connect.SETS(sets = sets))
      then setTrieGetElement(inCref, inFace, sets);

    else newElement(inCref, inFace, inType, inSource, Connect.NEW_SET);
  end matchcontinue;
end findElement;

protected function newElement
  "Creates a new connector element."
  input DAE.ComponentRef inCref;
  input Face inFace;
  input ConnectorType inType;
  input DAE.ElementSource inSource;
  input Integer inSet;
  output ConnectorElement outElement;
protected
  DAE.ComponentRef name;
algorithm
  outElement := Connect.CONNECTOR_ELEMENT(inCref, inFace, inType, inSource, inSet);
end newElement;

protected function isNewElement
  "Checks if the element is new, i.e. hasn't been assigned to a set yet."
  input ConnectorElement inElement;
  output Boolean outIsNew;
protected
  Integer set;
algorithm
  Connect.CONNECTOR_ELEMENT(set = set) := inElement;
  outIsNew := (set == Connect.NEW_SET);
end isNewElement;

protected function getElementSetIndex
  "Returns the set index of a connector element."
  input ConnectorElement inElement;
  output Integer outIndex;
algorithm
  Connect.CONNECTOR_ELEMENT(set = outIndex) := inElement;
end getElementSetIndex;

protected function setElementSetIndex
  "Sets the set index of a connector element."
  input ConnectorElement inElement;
  input Integer inIndex;
  output ConnectorElement outElement;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType ty;
  DAE.ElementSource source;
algorithm
  Connect.CONNECTOR_ELEMENT(name, face, ty, source, _) := inElement;
  outElement := Connect.CONNECTOR_ELEMENT(name, face, ty, source, inIndex);
end setElementSetIndex;

protected function getElementName
  "Returns the name of a connector element."
  input ConnectorElement inElement;
  output DAE.ComponentRef outName;
algorithm
  Connect.CONNECTOR_ELEMENT(name = outName) := inElement;
end getElementName;

protected function setElementName
  "Sets the name of a connector element."
  input ConnectorElement inElement;
  input DAE.ComponentRef inName;
  output ConnectorElement outElement;
protected
  Face face;
  ConnectorType ty;
  DAE.ElementSource source;
  Integer set;
algorithm
  Connect.CONNECTOR_ELEMENT(_, face, ty, source, set) := inElement;
  outElement := Connect.CONNECTOR_ELEMENT(inName, face, ty, source, set);
end setElementName;

protected function getElementSource
  "Returns the element source of a connector element."
  input ConnectorElement inElement;
  output DAE.ElementSource outSource;
algorithm
  Connect.CONNECTOR_ELEMENT(source = outSource) := inElement;
end getElementSource;

protected function setTrieNewLeaf
  "Creates a new trie leaf."
  input String inId;
  input ConnectorElement inElement;
  output SetTrieNode outLeaf;
algorithm
  outLeaf := match(inId, inElement)
    local
      String name;

    case (_, Connect.CONNECTOR_ELEMENT(face = Connect.INSIDE()))
      then Connect.SET_TRIE_LEAF(inId, SOME(inElement), NONE(), NONE(), 0);

    case (_, Connect.CONNECTOR_ELEMENT(face = Connect.OUTSIDE()))
      then Connect.SET_TRIE_LEAF(inId, NONE(), SOME(inElement), NONE(), 0);

  end match;
end setTrieNewLeaf;

protected function setTrieNewNode
  "Creates a new trie node."
  input DAE.ComponentRef inCref;
  input ConnectorElement inElement;
  output SetTrieNode outNode;
algorithm
  outNode := match(inCref, inElement)
    local
      String id;
      DAE.ComponentRef rest_cr;
      SetTrieNode node;
      DAE.ComponentRef cr;
      DAE.Type ty;
      ConnectorElement el;

    // A simple identifier, just create a new leaf.
    case (DAE.CREF_IDENT(), _)
      equation
        id = ComponentReference.printComponentRefStr(inCref);
        el = setElementName(inElement, inCref);
      then
        setTrieNewLeaf(id, el);

    // A qualified identifier, call this function recursively.
    // I.e. a.b.c becomes NODE(a, {NODE(b, {NODE(c)})});
    case (DAE.CREF_QUAL(componentRef = rest_cr), _)
      equation
        cr = ComponentReference.crefFirstCref(inCref);
        id = ComponentReference.printComponentRefStr(cr);
        node = setTrieNewNode(rest_cr, inElement);
      then
        Connect.SET_TRIE_NODE(id, cr, {node}, 0);

  end match;
end setTrieNewNode;

protected function setTrieNodeName
  input SetTrieNode inNode;
  output String outName;
algorithm
  outName := match(inNode)
    local
      String name;

    case Connect.SET_TRIE_NODE(name = name) then name;
    case Connect.SET_TRIE_LEAF(name = name) then name;
    case Connect.SET_TRIE_DELETED(name = name) then name;

  end match;
end setTrieNodeName;

protected function mergeSets
  "Merges two sets."
  input ConnectorElement inElement1;
  input ConnectorElement inElement2;
  input Sets inSets;
  output Sets outSets;
protected
  Boolean new1, new2;
algorithm
  new1 := isNewElement(inElement1);
  new2 := isNewElement(inElement2);
  outSets := mergeSets2(inElement1, inElement2, new1, new2, inSets);
end mergeSets;

protected function mergeSets2
  "Helper function to mergeSets, dispatches to the correct function based on if
   the elements are new or not."
  input ConnectorElement inElement1;
  input ConnectorElement inElement2;
  input Boolean inIsNew1;
  input Boolean inIsNew2;
  input Sets inSets;
  output Sets outSets;
algorithm
  outSets := match(inElement1, inElement2, inIsNew1, inIsNew2, inSets)

    // Both elements are new, add them to a new set.
    case (_, _, true, true, _)
      then addNewSet(inElement1, inElement2, inSets);

    // The first is new and the second old, add the first to the same set as the
    // second.
    case (_, _, true, false, _)
      then addToSet(inElement1, inElement2, inSets);

    // The second is new and the first old, add the second to the same set as
    // the first.
    case (_, _, false, true, _)
      then addToSet(inElement2, inElement1, inSets);

    // Both sets are old, add a connection between their sets.
    case (_, _, false, false, _)
      then connectSets(inElement1, inElement2, inSets);

  end match;
end mergeSets2;

protected function addNewSet
  "Adds a new set containing the given two elements to the sets."
  input ConnectorElement inElement1;
  input ConnectorElement inElement2;
  input Sets inSets;
  output Sets outSets;
protected
  SetTrie sets;
  Integer sc;
  list<SetConnection> c;
  list<OuterConnect> o;
  ConnectorElement e1, e2;
algorithm
  Connect.SETS(sets, sc, c, o) := inSets;
  sc := sc + 1;
  e1 := setElementSetIndex(inElement1, sc);
  e2 := setElementSetIndex(inElement2, sc);
  sets := setTrieAdd(e1, sets);
  sets := setTrieAdd(e2, sets);
  outSets := Connect.SETS(sets, sc, c, o);
end addNewSet;

protected function addToSet
  "Adds the first connector element to the same set as the second."
  input ConnectorElement inElement;
  input ConnectorElement inSet;
  input Sets inSets;
  output Sets outSets;
protected
  SetTrie sets;
  Integer sc, index;
  list<SetConnection> c;
  list<OuterConnect> o;
  ConnectorElement e;
algorithm
  index := getElementSetIndex(inSet);
  e := setElementSetIndex(inElement, index);
  Connect.SETS(sets, sc, c, o) := inSets;
  sets := setTrieAdd(e, sets);
  outSets := Connect.SETS(sets, sc, c, o);
end addToSet;

protected function connectSets
  "Connects two sets."
  input ConnectorElement inElement1;
  input ConnectorElement inElement2;
  input Sets inSets;
  output Sets outSets;
algorithm
  outSets := matchcontinue(inElement1, inElement2, inSets)
    local
      Integer set1, set2;
      SetTrie sets;
      Integer sc;
      list<SetConnection> connections;
      list<OuterConnect> o;

    // The elements already belong to the same set, nothing needs to be done.
    case (_, _, _)
      equation
        set1 = getElementSetIndex(inElement1);
        set2 = getElementSetIndex(inElement2);
        true = intEq(set1, set2);
      then
        inSets;

    // Otherwise, add a connection to the connection list.
    case (_, _, Connect.SETS(sets, sc, connections, o))
      equation
        set1 = getElementSetIndex(inElement1);
        set2 = getElementSetIndex(inElement2);
      then
        Connect.SETS(sets, sc, (set1, set2) :: connections, o);

  end matchcontinue;
end connectSets;

protected function setTrieGetElement
  "Fetches a connector element from the trie given a cref and a face."
  input DAE.ComponentRef inCref;
  input Face inFace;
  input SetTrie inTrie;
  output ConnectorElement outElement;
protected
  SetTrieNode node;
algorithm
  node := setTrieGet(inCref, inTrie, false);
  outElement := setTrieGetLeafElement(node, inFace);
end setTrieGetElement;

protected function setTrieAddLeafElement
  "Adds a connector element to a trie leaf."
  input ConnectorElement inElement;
  input SetTrieNode inNode;
  output SetTrieNode outNode;
algorithm
  outNode := match(inElement, inNode)
    local
      String name;
      Option<ConnectorElement> oce;
      Option<DAE.ComponentRef> fa;
      Integer c;

    case (Connect.CONNECTOR_ELEMENT(face = Connect.INSIDE()),
        Connect.SET_TRIE_LEAF(name, _, oce, fa, c))
      then Connect.SET_TRIE_LEAF(name, SOME(inElement), oce, fa, c);

    case (Connect.CONNECTOR_ELEMENT(face = Connect.OUTSIDE()),
        Connect.SET_TRIE_LEAF(name, oce, _, fa, c))
      then Connect.SET_TRIE_LEAF(name, oce, SOME(inElement), fa, c);

  end match;
end setTrieAddLeafElement;

protected function setTrieGetLeafElement
  "Returns the connector element of a trie leaf, given a face."
  input SetTrieNode inNode;
  input Face inFace;
  output ConnectorElement outElement;
algorithm
  outElement := match(inNode, inFace)
    local
      ConnectorElement e;

    case (Connect.SET_TRIE_LEAF(insideElement = SOME(e)), Connect.INSIDE()) then e;
    case (Connect.SET_TRIE_LEAF(outsideElement = SOME(e)), Connect.OUTSIDE()) then e;
  end match;
end setTrieGetLeafElement;

protected function setTrieAdd
  "Adds a connector element to the trie."
  input ConnectorElement inElement;
  input SetTrie inTrie;
  output SetTrie outTrie;
protected
  DAE.ComponentRef cref, el_cr;
  ConnectorElement el;
algorithm
  cref := getElementName(inElement);
  el_cr := ComponentReference.crefLastCref(cref);
  el := setElementName(inElement, el_cr);
  outTrie := setTrieUpdate(cref, el, inTrie, setTrieAddLeafElement);
end setTrieAdd;

protected function updateSetLeaf
  "Updates a trie leaf in the sets with the given update function."
  input Sets inSets;
  input DAE.ComponentRef inCref;
  input Arg inArg;
  input UpdateFunc inUpdateFunc;
  output Sets outSets;

  replaceable type Arg subtypeof Any;

  partial function UpdateFunc
    input Arg inArg;
    input SetTrieNode inNode;
    output SetTrieNode outNode;
  end UpdateFunc;
protected
  SetTrie sets;
  Integer sc;
  list<SetConnection> c;
  list<OuterConnect> o;
algorithm
  Connect.SETS(sets, sc, c, o) := inSets;
  sets := setTrieUpdate(inCref, inArg, sets, inUpdateFunc);
  outSets := Connect.SETS(sets, sc, c, o);
end updateSetLeaf;

protected function setTrieUpdate
  "Updates a trie leaf in the trie with the given update function."
  input DAE.ComponentRef inCref;
  input Arg inArg;
  input SetTrie inTrie;
  input UpdateFunc inUpdateFunc;
  output SetTrie outTrie;

  replaceable type Arg subtypeof Any;

  partial function UpdateFunc
    input Arg inArg;
    input SetTrieNode inNode;
    output SetTrieNode outNode;
  end UpdateFunc;
algorithm
  outTrie := match(inCref, inArg, inTrie, inUpdateFunc)
    local
      String id, name;
      DAE.ComponentRef el_cr, rest_cref;
      list<SetTrieNode> nodes;
      list<DAE.Subscript> subs;
      Integer cc;

    case (DAE.CREF_QUAL(ident = id, subscriptLst = subs, componentRef = rest_cref),
        _, Connect.SET_TRIE_NODE(name, el_cr, nodes, cc), _)
      equation
        id = ComponentReference.printComponentRef2Str(id, subs);
        nodes = setTrieUpdateNode(firstElementIsTrieNodeNamed(nodes, id), id, inCref, rest_cref, inArg, nodes, inUpdateFunc, {});
      then
        Connect.SET_TRIE_NODE(name, el_cr, nodes, cc);

    case (DAE.CREF_IDENT(ident = id, subscriptLst = subs), _,
        Connect.SET_TRIE_NODE(name, el_cr, nodes, cc), _)
      equation
        id = ComponentReference.printComponentRef2Str(id, subs);
        nodes = setTrieUpdateLeaf(id, inArg, nodes, inUpdateFunc);
      then
        Connect.SET_TRIE_NODE(name, el_cr, nodes, cc);

  end match;
end setTrieUpdate;

protected function setTrieUpdateNode
  "Helper function to setTrieUpdate, updates a node in the trie."
  input Boolean firstMatches;
  input String inId;
  input DAE.ComponentRef wholeCref;
  input DAE.ComponentRef inCref;
  input Arg inArg;
  input list<SetTrieNode> inNodes;
  input UpdateFunc inUpdateFunc;
  input list<SetTrieNode> acc;
  output list<SetTrieNode> outNodes;

  replaceable type Arg subtypeof Any;

  partial function UpdateFunc
    input Arg inArg;
    input SetTrieNode inNode;
    output SetTrieNode outNode;
  end UpdateFunc;
algorithm
  outNodes := match (firstMatches, inId, wholeCref, inCref, inArg, inNodes, inUpdateFunc, acc)
    local
      SetTrieNode node,node2;
      list<SetTrieNode> rest_nodes;
      String id;

    case (_, _, _, _, _, {}, _, _)
      then setTrieUpdateNode2(wholeCref, inArg, inUpdateFunc, acc);

    case (true, _, _, _, _, node :: rest_nodes, _, _)
      equation
        node2 = setTrieUpdate(inCref, inArg, node, inUpdateFunc);
        outNodes = listAppend(acc, node2 :: rest_nodes);
      then outNodes;

    case (_, _, _, _, _, node :: rest_nodes, _, _)
      equation
        rest_nodes = setTrieUpdateNode(firstElementIsTrieNodeNamed(rest_nodes, inId), inId, wholeCref, inCref, inArg, rest_nodes, inUpdateFunc, node::acc);
      then rest_nodes;

  end match;
end setTrieUpdateNode;

protected function setTrieUpdateNode2
  "Helper function to setTrieUpdateNode."
  input DAE.ComponentRef inCref;
  input Arg inArg;
  input UpdateFunc inUpdateFunc;
  input list<SetTrieNode> acc;
  output list<SetTrieNode> nodes;

  replaceable type Arg subtypeof Any;

  partial function UpdateFunc
    input Arg inArg;
    input SetTrieNode inNode;
    output SetTrieNode outNode;
  end UpdateFunc;
algorithm
  nodes := match(inCref, inArg, inUpdateFunc, acc)
    local
      String id;
      DAE.ComponentRef cr, rest_cr;
      SetTrieNode node;

    case (DAE.CREF_IDENT(), _, _, _)
      equation
        id = ComponentReference.printComponentRefStr(inCref);
        node = Connect.SET_TRIE_LEAF(id, NONE(), NONE(), NONE(), 0);
        node = inUpdateFunc(inArg, node);
      then
        node :: acc;

    case (DAE.CREF_QUAL(componentRef = rest_cr), _, _, _)
      equation
        cr = ComponentReference.crefFirstCref(inCref);
        id = ComponentReference.printComponentRefStr(cr);
        nodes = setTrieUpdateNode2(rest_cr, inArg, inUpdateFunc, {});
      then
        Connect.SET_TRIE_NODE(id, cr, nodes, 0) :: acc;

  end match;
end setTrieUpdateNode2;

protected function setTrieUpdateLeaf
  "Helper funtion to setTrieUpdate, updates a trie leaf."
  input String inId;
  input Arg inArg;
  input list<SetTrieNode> inNodes;
  input UpdateFunc inUpdateFunc;
  output list<SetTrieNode> outNodes;

  replaceable type Arg subtypeof Any;

  partial function UpdateFunc
    input Arg inArg;
    input SetTrieNode inNode;
    output SetTrieNode outNode;
  end UpdateFunc;
algorithm
  outNodes := matchcontinue(inId, inArg, inNodes, inUpdateFunc)
    local
      SetTrieNode node;
      list<SetTrieNode> rest_nodes;
      String id;

    // No matching leaves, add a new leaf.
    case (_, _, {}, _)
      equation
        node = Connect.SET_TRIE_LEAF(inId, NONE(), NONE(), NONE(), 0);
        node = inUpdateFunc(inArg, node);
      then
        {node};

    // Found matching leaf, update it.
    //case (_, _, (node as Connect.SET_TRIE_LEAF(name = id)) :: rest_nodes, _)
    case (_, _, node :: rest_nodes, _)
      equation
        id = setTrieNodeName(node);
        true = stringEqual(inId, id);
        node = inUpdateFunc(inArg, node);
      then
        node :: rest_nodes;

    // No matching leaves, search rest of leaves.
    case (_, _, node :: rest_nodes, _)
      equation
        rest_nodes = setTrieUpdateLeaf(inId, inArg, rest_nodes, inUpdateFunc);
      then
        node :: rest_nodes;

  end matchcontinue;
end setTrieUpdateLeaf;

public function traverseSets
  "Traverses the trie leaves in a sets."
  input Sets inSets;
  input Arg inArg;
  input UpdateFunc inUpdateFunc;
  output Sets outSets;
  output Arg outArg;

  replaceable type Arg subtypeof Any;

  partial function UpdateFunc
    input SetTrieNode inNode;
    input Arg inArg;
    output SetTrieNode outNode;
    output Arg outArg;
  end UpdateFunc;
protected
  SetTrie sets;
  Integer sc;
  list<SetConnection> c;
  list<OuterConnect> o;
algorithm
  Connect.SETS(sets, sc, c, o) := inSets;
  (sets, outArg) := setTrieTraverseLeaves(sets, inUpdateFunc, inArg);
  outSets := Connect.SETS(sets, sc, c, o);
end traverseSets;

protected function setTrieTraverseLeaves
  "Traverses the leaves of a trie."
  input SetTrieNode inNode;
  input UpdateFunc inUpdateFunc;
  input Arg inArg;
  output SetTrieNode outNode;
  output Arg outArg;

  replaceable type Arg subtypeof Any;

  partial function UpdateFunc
    input SetTrieNode inNode;
    input Arg inArg;
    output SetTrieNode outNode;
    output Arg outArg;
  end UpdateFunc;
algorithm
  (outNode, outArg) := match(inNode, inUpdateFunc, inArg)
    local
      String name;
      DAE.ComponentRef cref;
      list<SetTrieNode> nodes;
      SetTrieNode node;
      Arg arg;
      Integer cc;

    case (Connect.SET_TRIE_NODE(name, cref, nodes, cc), _, _)
      equation
        (nodes, arg) = List.map1Fold(nodes, setTrieTraverseLeaves,
          inUpdateFunc, inArg);
      then
        (Connect.SET_TRIE_NODE(name, cref, nodes, cc), arg);

     case (Connect.SET_TRIE_LEAF(), _, _)
       equation
         (node, arg) = inUpdateFunc(inNode, inArg);
       then
         (node, arg);

     case (Connect.SET_TRIE_DELETED(), _, _)
       then (inNode, inArg);

  end match;
end setTrieTraverseLeaves;

protected function setTrieGet
  "Fetches a node from the trie given a cref to search for. If inMatchPrefix is
  true it also matches a prefix of the cref if the full cref couldn't be found."
  input DAE.ComponentRef inCref;
  input SetTrie inTrie;
  input Boolean inMatchPrefix;
  output SetTrieNode outLeaf;
protected
  list<SetTrieNode> nodes;
  String subs_str, id_subs, id_nosubs;
  SetTrieNode node;
algorithm
  Connect.SET_TRIE_NODE(nodes = nodes) := inTrie;

  id_nosubs := ComponentReference.crefFirstIdent(inCref);
  subs_str := List.toString(ComponentReference.crefFirstSubs(inCref),
    ExpressionDump.printSubscriptStr, "", "[", ",", "]", false);
  id_subs := id_nosubs + subs_str;

  try
    // Try to look up the identifier with subscripts, in case single array
    // elements have been added to the trie.
    outLeaf := setTrieGetNode(id_subs, nodes);
  else
    // If the above fails, try again without the subscripts in case a whole
    // array has been added to the trie.
    outLeaf := setTrieGetNode(id_nosubs, nodes);
  end try;

  // If the cref is qualified, continue to look up the rest of the cref in node
  // we just found.
  if not ComponentReference.crefIsIdent(inCref) then
    try
      outLeaf := setTrieGet(ComponentReference.crefRest(inCref), outLeaf, inMatchPrefix);
    else
      // Look up failed, return the previously found node if prefix matching is
      // turned on and the node we found is a leaf.
      true := inMatchPrefix and not setTrieIsNode(outLeaf);
    end try;
  end if;
end setTrieGet;

protected function setTrieGetNode
  "Returns a node with a given name from a list of nodes, or fails if no such
  node exists in the list."
  input String inId;
  input list<SetTrieNode> inNodes;
  output SetTrieNode outNode;
algorithm
  outNode := List.getMemberOnTrue(inId, inNodes, setTrieNodeNamed);
end setTrieGetNode;

protected function setTrieNodeNamed
  "Returns true if the given node has the same name as the given string,
  otherwise false."
  input String inId;
  input SetTrieNode inNode;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match(inId, inNode)
    local
      String id;

    case (_, Connect.SET_TRIE_NODE(name = id))
      then stringEqual(inId, id);

    case (_, Connect.SET_TRIE_LEAF(name = id))
      then stringEqual(inId, id);

    case (_, Connect.SET_TRIE_DELETED(name = id))
      then stringEqual(inId, id);

    else false;
  end match;
end setTrieNodeNamed;

protected function setTrieGetLeaf
  "Returns a leaf node with a given name from a list of nodes, or fails if no
  such node exists in the list."
  input String inId;
  input list<SetTrieNode> inNodes;
  output SetTrieNode outNode;
algorithm
  outNode := List.getMemberOnTrue(inId, inNodes, setTrieLeafNamed);
end setTrieGetLeaf;

protected function setTrieLeafNamed
  "Returns true if the given leaf node has the same name as the given string,
  otherwise false."
  input String inId;
  input SetTrieNode inNode;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match(inId, inNode)
    local
      String id;

    case (_, Connect.SET_TRIE_LEAF(name = id))
      then stringEqual(inId, id);

    case (_, Connect.SET_TRIE_DELETED(name = id))
      then stringEqual(inId, id);

    else false;
  end match;
end setTrieLeafNamed;

protected function setTrieIsNode
  input SetTrieNode inNode;
  output Boolean outIsNode;
algorithm
  outIsNode := match inNode
    case Connect.SET_TRIE_NODE() then true;
    else false;
  end match;
end setTrieIsNode;

public function equations
  "Generates equations from a connection set and evaluates stream operators if
  called from the top scope, otherwise does nothing."
  input Boolean inTopScope;
  input Sets inSets;
  input DAE.DAElist inDae;
  input ConnectionGraph.ConnectionGraph inConnectionGraph;
  input String inModelNameQualified;
  output DAE.DAElist outDae;
protected
  list<Set> sets;
  array<Set> set_array;
algorithm
  outDae := match(inTopScope, inSets, inDae, inConnectionGraph, inModelNameQualified)
    local
      DAE.DAElist dae, dae2;
      Boolean has_stream, has_expandable, has_cardinality;
      ConnectionGraph.DaeEdges broken, connected;
      Real flow_threshold;

    case (true, _, _, _, _)
      equation
        //print(printSetsStr(inSets) + "\n");
        set_array = generateSetArray(inSets);
        sets = arrayList(set_array);
        //print("Sets:\n");
        //print(stringDelimitList(List.map(sets, printSetStr), "\n") + "\n");

        has_expandable = daeHasExpandableConnectors(inDae);
        (sets, dae) = removeUnusedExpandableVariablesAndConnections(sets, inDae, has_expandable);

        // send in the connection graph and build the connected/broken connects
        // we do this here so we do it once and not for every EQU set.
        (dae, connected, broken) = ConnectionGraph.handleOverconstrainedConnections(inConnectionGraph, inModelNameQualified, dae);
        // adrpo: FIXME: maybe we should just remove them from the sets then send the updates sets further
        flow_threshold = Flags.getConfigReal(Flags.FLOW_THRESHOLD);
        dae2 = equationsDispatch(listReverse(sets), connected, broken, flow_threshold);
        dae = DAEUtil.joinDaes(dae, dae2);
        has_stream = System.getHasStreamConnectors();
        has_cardinality = System.getUsesCardinality();
        dae = evaluateConnectionOperators(has_stream, has_cardinality, inSets, set_array, dae);
        // add the equality constraint equations to the dae.
        dae = ConnectionGraph.addBrokenEqualityConstraintEquations(dae, broken);
      then
        dae;

    else inDae;

  end match;
end equations;

protected function getExpandableEquSetsAsCrefs
"@author: adrpo
 returns only the sets containing expandable connectors"
  input list<Set> inSets;
  input list<list<DAE.ComponentRef>> inSetsAcc;
  output list<list<DAE.ComponentRef>> outSets;
algorithm
  outSets := match (inSets, inSetsAcc)
    local
      list<Set> rest;
      list<DAE.ComponentRef> crefSet;
      Set set;
      Boolean b;

    case ({}, _) then inSetsAcc;

    case ((set as Connect.SET(ty = Connect.EQU()))::rest, _)
      equation
        crefSet = getAllEquCrefs({set}, {});
        b = List.applyAndFold(crefSet, boolOr, isExpandable, false);
      then
        getExpandableEquSetsAsCrefs(rest, List.consOnTrue(b,crefSet,inSetsAcc));

    case (_::rest, _)
      then getExpandableEquSetsAsCrefs(rest, inSetsAcc);
  end match;
end getExpandableEquSetsAsCrefs;


protected function removeCrefsFromSets
  input list<Set> inSets;
  input list<DAE.ComponentRef> inNonUsefulExpandable;
  output list<Set> outSets;
algorithm
  outSets := List.select1(inSets, removeCrefsFromSets2, inNonUsefulExpandable);
end removeCrefsFromSets;

protected function removeCrefsFromSets2
  input Set inSet;
  input list<DAE.ComponentRef> inNonUsefulExpandable;
  output Boolean isInSet;
protected
  list<DAE.ComponentRef> setCrefs, lst;
algorithm
  setCrefs := getAllEquCrefs({inSet}, {});
  lst := List.intersectionOnTrue(setCrefs, inNonUsefulExpandable, ComponentReference.crefEqualNoStringCompare);
  isInSet := listEmpty(lst);
end removeCrefsFromSets2;

function mergeEquSetsAsCrefs
  input list<list<DAE.ComponentRef>> inSetsAsCrefs;
  output list<list<DAE.ComponentRef>> outSetsAsCrefs;
algorithm
  outSetsAsCrefs := matchcontinue(inSetsAsCrefs)
    local
      list<DAE.ComponentRef> set;
      list<list<DAE.ComponentRef>> rest, sets;

    case ({}) then {};
    case ({set}) then {set};
    case (set::rest)
      equation
        (set, rest) = mergeWithRest(set, rest, {});
        sets = mergeEquSetsAsCrefs(rest);
      then
        set::sets;
  end matchcontinue;
end mergeEquSetsAsCrefs;

protected function mergeWithRest
  input list<DAE.ComponentRef> inSet;
  input list<list<DAE.ComponentRef>> inSets;
  input list<list<DAE.ComponentRef>> inAcc;
  output list<DAE.ComponentRef> outSet;
  output list<list<DAE.ComponentRef>> outSets;
algorithm
  (outSet, outSets) := match (inSet, inSets, inAcc)
    local
      list<DAE.ComponentRef> set, set1, set2;
      list<list<DAE.ComponentRef>> rest, acc;
      Boolean b;
    case (_, {}, _) then (inSet, listReverse(inAcc));
    case (set1, set2::rest, acc)
      equation
         // Could be faster if we had a function for intersectionExist in a set
         b = listEmpty(List.intersectionOnTrue(set1, set2, ComponentReference.crefEqualNoStringCompare));
         set = if not b then List.unionOnTrue(set1, set2, ComponentReference.crefEqualNoStringCompare) else set1;
         acc = List.consOnTrue(b, set2, acc);
         (set, rest) = mergeWithRest(set, rest, acc);
      then (set, rest);
  end match;
end mergeWithRest;

protected function getOnlyExpandableConnectedCrefs
  input list<list<DAE.ComponentRef>> inSets;
  input list<DAE.ComponentRef> inAcc;
  output list<DAE.ComponentRef> outUsefulConnectedExpandable;
algorithm
  outUsefulConnectedExpandable := match (inSets, inAcc)
    local
      list<DAE.ComponentRef> set, acc;
      list<list<DAE.ComponentRef>> rest;

    case ({}, _) then inAcc;

    case (set::rest, _)
      equation
        // print("OnlyExp Set:\n\t" + stringDelimitList(List.map(set, ComponentReference.printComponentRefStr), "\n\t") + "\n");
        acc = if allCrefsAreExpandable(set) then listAppend(set, inAcc) else inAcc;
        acc = getOnlyExpandableConnectedCrefs(rest, acc);
      then
        acc;

  end match;
end getOnlyExpandableConnectedCrefs;

public function allCrefsAreExpandable
  input list<DAE.ComponentRef> inConnects;
  output Boolean allAreExpandable;
algorithm
  allAreExpandable := match(inConnects)
    local
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef name;
      Boolean b;

    case ({}) then true;

    case (name::rest)
      equation
        b = if isExpandable(name) then allCrefsAreExpandable(rest) else false;
      then b;

  end match;
end allCrefsAreExpandable;

protected function generateSetArray
  "Generates an array of sets from a connection set."
  input Sets inSets;
  output array<Set> outSetArray;
algorithm
  outSetArray := match(inSets)
    local
      SetTrie sets;
      Integer set_count;
      list<SetConnection> connections;
      array<Set> set_array;

    case (Connect.SETS(sets = sets, setCount = set_count,
        connections = connections))
      equation
        // Create a new array.
        set_array = arrayCreate(set_count, Connect.SET(Connect.NO_TYPE(), {}));
        // Add connection pointers to the array.
        set_array = setArrayAddConnections(connections, set_count, set_array);
        // Fill the array with sets.
        set_array = generateSetArray2(sets, {}, set_array);
      then
        set_array;

  end match;
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
  input list<SetConnection> inConnections;
  input Integer inSetCount;
  input array<Set> inSets;
  output array<Set> outSets;
protected
  SetGraph graph;
algorithm
  // Create a new graph, represented as an adjacency list.
  graph := arrayCreate(inSetCount, {});
  // Add the connections to the graph.
  graph := List.fold(inConnections, addConnectionToGraph, graph);
  // Add the connections to the array with help from the graph.
  outSets := setArrayAddConnections2(1 <= arrayLength(graph), 1, graph, inSets);
end setArrayAddConnections;

protected function addConnectionToGraph
  "Adds a connection to the set graph."
  input SetConnection inConnection;
  input SetGraph inGraph;
  output SetGraph outGraph;
protected
  Integer set1, set2;
  list<Integer> node1, node2;
algorithm
  (set1, set2) := inConnection;
  node1 := arrayGet(inGraph, set1);
  outGraph := arrayUpdate(inGraph, set1, set2 :: node1);
  node2 := arrayGet(inGraph, set2);
  outGraph := arrayUpdate(inGraph, set2, set1 :: node2);
end addConnectionToGraph;

protected function setArrayAddConnections2
  "Adds pointers to the set array."
  input Boolean stop;
  input Integer inIndex;
  input SetGraph inGraph;
  input array<Set> inSets;
  output array<Set> outSets;
algorithm
  outSets := match (stop, inIndex, inGraph, inSets)
    local
      list<Integer> edges;
      array<Set> sets;
      SetGraph graph;

    case (false, _, _, _) then inSets;
    else
      equation
        edges = arrayGet(inGraph, inIndex);
        (sets, graph) = setArrayAddConnection(inIndex, edges, inSets, inGraph);
      then setArrayAddConnections2(inIndex+1 <= arrayLength(graph), inIndex + 1, graph, sets);

  end match;
end setArrayAddConnections2;

protected function setArrayAddConnection
  "Helper function to setArrayAddConnections2, adds a connection pointer to the
   set array."
  input Integer inSet;
  input list<Integer> inEdges;
  input array<Set> inSets;
  input SetGraph inGraph;
  output array<Set> outSets;
  output SetGraph outGraph;
algorithm
  (outSets, outGraph) := matchcontinue(inSet, inEdges, inSets, inGraph)
    local
      Integer edge;
      list<Integer> edges, rest_edges;
      array<Set> sets;
      SetGraph graph;

    case (_, {}, _, _) then (inSets, inGraph);

    case (_, edge :: rest_edges, _, _)
      equation
        false = intEq(inSet, edge);
        // Create a pointer to the given set.
        sets = setArrayAddConnection2(edge, inSet, inSets);
        edges = arrayGet(inGraph, edge);
        graph = arrayUpdate(inGraph, edge, {});
        (sets, graph) = setArrayAddConnection(inSet, edges, sets, graph);
        (sets, graph) = setArrayAddConnection(inSet, rest_edges, sets, graph);
      then
        (sets, graph);

    case (_, _ :: rest_edges, _, _)
      equation
        (sets, graph) = setArrayAddConnection(inSet, rest_edges, inSets,
          inGraph);
      then
        (sets, graph);

  end matchcontinue;
end setArrayAddConnection;

protected function setArrayAddConnection2
  "Helper function to setArrayAddConnection, adds a pointer from the given
   pointer to the pointee."
  input Integer inSetPointer;
  input Integer inSetPointee;
  input array<Set> inSets;
  output array<Set> outSets;
algorithm
  outSets := match(inSetPointer, inSetPointee, inSets)
    local
      Integer pointee;
      Set set;

    case (_, _, _)
      equation
        set = arrayGet(inSets, inSetPointee);
        outSets = match(set)
                    // If the set pointed at is a real set, add a pointer to it.
                    case Connect.SET()
                      then arrayUpdate(inSets, inSetPointer, Connect.SET_POINTER(inSetPointee));
                    // If the set pointed at is itself a pointer, follow the pointer until a
                    // real set is found (path compression).
                    case Connect.SET_POINTER(index = pointee)
                      then setArrayAddConnection2(inSetPointer, pointee, inSets);
                 end match;
      then
        outSets;

  end match;
end setArrayAddConnection2;

protected function generateSetArray2
  "This function fills the set array with the sets from the set trie."
  input SetTrie inSets;
  input list<DAE.ComponentRef> inPrefix;
  input array<Set> inSetArray;
  output array<Set> outSetArray;
algorithm
  outSetArray := match(inSets, inPrefix, inSetArray)
    local
      list<SetTrieNode> nodes;
      array<Set> sets;
      Option<ConnectorElement> ie, oe;
      DAE.ComponentRef node_cr;
      Option<DAE.ComponentRef> prefix_cr, flow_cr;
      list<DAE.ComponentRef> prefix;

    case (Connect.SET_TRIE_NODE(cref = DAE.WILD(), nodes = nodes), _, _)
      then
        List.fold1(nodes, generateSetArray2, inPrefix, inSetArray);

    case (Connect.SET_TRIE_NODE(cref = node_cr, nodes = nodes),
        prefix, _)
      then
        List.fold1(nodes, generateSetArray2, node_cr :: prefix, inSetArray);

    case (Connect.SET_TRIE_LEAF(insideElement = ie, outsideElement = oe,
        flowAssociation = flow_cr), prefix, sets)
      equation
        prefix_cr = buildElementPrefix(prefix);
        ie = insertFlowAssociationInStreamElement(ie, flow_cr);
        oe = insertFlowAssociationInStreamElement(oe, flow_cr);
        sets = setArrayAddElement(ie, prefix_cr, sets);
        sets = setArrayAddElement(oe, prefix_cr, sets);
      then
        sets;

    else inSetArray;
  end match;
end generateSetArray2;

protected function insertFlowAssociationInStreamElement
  "If the given element is a stream element, sets the associated flow. Otherwise
  does nothing."
  input Option<ConnectorElement> inElement;
  input Option<DAE.ComponentRef> inFlowCref;
  output Option<ConnectorElement> outElement;
algorithm
  outElement := match(inElement, inFlowCref)
    local
      DAE.ComponentRef name, flow_cr;
      Face face;
      DAE.ElementSource source;
      Integer set;

    case (SOME(Connect.CONNECTOR_ELEMENT(name = name, face = face,
        ty = Connect.STREAM(NONE()), source = source, set = set)),
        SOME(flow_cr))
      then
        SOME(Connect.CONNECTOR_ELEMENT(name, face,
          Connect.STREAM(SOME(flow_cr)), source, set));

    else inElement;
  end match;
end insertFlowAssociationInStreamElement;

protected function setArrayAddElement
  "Adds a connector element to the set array."
  input Option<ConnectorElement> inElement;
  input Option<DAE.ComponentRef> inPrefix;
  input array<Set> inSets;
  output array<Set> outSets;
algorithm
  outSets := match(inElement, inPrefix, inSets)
    local
      ConnectorElement el;
      DAE.ComponentRef name, prefix;
      Face face;
      ConnectorType ty;
      DAE.ElementSource src;
      Integer set;

    // No element, do nothing.
    case (NONE(), _, _) then inSets;

    // An element but no prefix, add the element as it is.
    case (SOME(el as Connect.CONNECTOR_ELEMENT(set = set)), NONE(), _)
      then setArrayUpdate(inSets, set, el);

    // Both an element and a prefix, add the prefix to the element before adding
    // it to the array.
    case (SOME(Connect.CONNECTOR_ELEMENT(name, face, ty, src, set)),
        SOME(prefix), _)
      equation
        name = ComponentReference.joinCrefs(prefix, name);
        el = Connect.CONNECTOR_ELEMENT(name, face, ty, src, set);
      then
        setArrayUpdate(inSets, set, el);

  end match;
end setArrayAddElement;

protected function buildElementPrefix
  "Helper function to generateSetArray2, build a prefix from a list of crefs."
  input list<DAE.ComponentRef> inPrefix;
  output Option<DAE.ComponentRef> outCref;
algorithm
  outCref := match(inPrefix)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest_cr;

    // If a connector that extends a basic type is used on the top level we
    // don't have a prefix.
    case ({}) then NONE();

    case (cr :: rest_cr)
      equation
        cr = buildElementPrefix2(rest_cr, cr);
      then
        SOME(cr);

  end match;
end buildElementPrefix;

protected function buildElementPrefix2
  "Helper function to buildElementPrefix."
  input list<DAE.ComponentRef> inPrefix;
  input DAE.ComponentRef inAccumCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inPrefix, inAccumCref)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest_cr;
      String id;
      list<DAE.Subscript> subs;

    case ({}, _) then inAccumCref;

    case (DAE.CREF_IDENT(ident = id, subscriptLst = subs) :: rest_cr, cr)
      equation
        cr = DAE.CREF_QUAL(id, DAE.T_UNKNOWN_DEFAULT, subs, cr);
      then
        buildElementPrefix2(rest_cr, cr);

  end match;
end buildElementPrefix2;

protected function setArrayUpdate
  "Updates the element at a given index in the set array."
  input array<Set> inSets;
  input Integer inIndex;
  input ConnectorElement inElement;
  output array<Set> outSets;
protected
  Set set;
algorithm
  set := arrayGet(inSets, inIndex);
  outSets := setArrayUpdate2(inSets, set, inIndex, inElement);
end setArrayUpdate;

protected function setArrayUpdate2
  "Helper function to setArrayUpdate."
  input array<Set> inSets;
  input Set inSet;
  input Integer inIndex;
  input ConnectorElement inElement;
  output array<Set> outSets;
algorithm
  outSets := matchcontinue(inSets, inSet, inIndex, inElement)
    local
      list<ConnectorElement> el;
      ConnectorType ty;
      Integer index;

    // Sort the elements if orderConnections is true and the set is an equality set.
    case (_, Connect.SET(elements = el), _,
        Connect.CONNECTOR_ELEMENT(ty = ty as Connect.EQU()))
      equation
        true = Config.orderConnections();
        el = List.mergeSorted({inElement}, el, equSetElementLess);
      then
        arrayUpdate(inSets, inIndex, Connect.SET(ty, el));

    // Other sets, just add them.
    case (_, Connect.SET(elements = el), _, Connect.CONNECTOR_ELEMENT(ty = ty))
      then arrayUpdate(inSets, inIndex, Connect.SET(ty, inElement :: el));

    // A pointer, follow the pointer.
    case (_, Connect.SET_POINTER(index = index), _, _)
      then setArrayUpdate(inSets, index, inElement);

  end matchcontinue;
end setArrayUpdate2;

protected function equSetElementLess
  "Comparison function used by setArrayUpdate2 to order equ sets."
  input ConnectorElement inElement1;
  input ConnectorElement inElement2;
  output Boolean outIsLess;
protected
  DAE.ComponentRef name1, name2;
algorithm
  Connect.CONNECTOR_ELEMENT(name = name1) := inElement1;
  Connect.CONNECTOR_ELEMENT(name = name2) := inElement2;
  outIsLess := ComponentReference.crefSortFunc(name2, name1);
end equSetElementLess;

protected function setArrayGet
  "Returns the set on a given index in the set array."
  input array<Set> inSetArray;
  input Integer inIndex;
  output Set outSet;
protected
  Set set;
algorithm
  set := arrayGet(inSetArray, inIndex);
  outSet := setArrayGet2(set, inSetArray);
end setArrayGet;

protected function setArrayGet2
  "Helper function to setArrayGet, follows pointers until a real set is found."
  input Set inSet;
  input array<Set> inSetArray;
  output Set outSet;
algorithm
  outSet := match(inSet, inSetArray)
    local
      Integer set;

    case (Connect.SET(), _) then inSet;
    case (Connect.SET_POINTER(index = set), _)
      then setArrayGet(inSetArray, set);
  end match;
end setArrayGet2;

protected function equationsDispatch
  "Dispatches to the correct equation generating function based on the type of
  the given set."
  input list<Set> inSets;
  input ConnectionGraph.DaeEdges inConnected;
  input ConnectionGraph.DaeEdges inBroken;
  input Real inFlowThreshold;
  output DAE.DAElist outDae = DAE.emptyDae;
protected
  list<ConnectorElement> eql;
algorithm
  for set in inSets loop
    outDae := match set
      // A set pointer left from generateSetList, ignore it.
      case Connect.SET_POINTER() then outDae;

      case Connect.SET(ty = Connect.EQU(), elements = eql)
        algorithm
          // Here we do some overconstrained connection breaking.
          eql := ConnectionGraph.removeBrokenConnects(eql, inConnected, inBroken);
        then
          DAEUtil.joinDaes(generateEquEquations(eql), outDae);

      case Connect.SET(ty = Connect.FLOW(), elements = eql)
        then DAEUtil.joinDaes(generateFlowEquations(eql), outDae);

      case Connect.SET(ty = Connect.STREAM(), elements = eql)
        then DAEUtil.joinDaes(generateStreamEquations(eql, inFlowThreshold), outDae);

      // Should never happen.
      case Connect.SET(ty = Connect.NO_TYPE())
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
  input list<ConnectorElement> inElements;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(inElements)
    local
      DAE.ComponentRef x, y;
      DAE.ElementSource x_src, y_src, src;
      list<ConnectorElement> rest_el;
      ConnectorElement e1, e2;
      list<DAE.Element> eq;
      String str;
      Boolean order_conn;

    case {} then DAE.emptyDae;

    case {_} then DAE.emptyDae;

    case ((e1 as Connect.CONNECTOR_ELEMENT(name = x, source = x_src)) ::
          (e2 as Connect.CONNECTOR_ELEMENT(name = y, source = y_src)) :: rest_el)
      equation
        order_conn = Config.orderConnections();
        e1 = if order_conn then e1 else e2;
        DAE.DAE(eq) = generateEquEquations(e1 :: rest_el);
        (x, y) = Util.swap(shouldFlipEquEquation(x, x_src, order_conn), x, y);
        src = DAEUtil.mergeSources(x_src, y_src);
        src = DAEUtil.addElementSourceConnectOpt(src, SOME((x, y)));
      then
        DAE.DAE(DAE.EQUEQUATION(x, y, src) :: eq);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = stringDelimitList(List.map(inElements, printElementStr), ", ");
        Debug.traceln("- ConnectUtil.generateEquEquations failed on {" + str + "}");
      then
        fail();

  end matchcontinue;
end generateEquEquations;

protected function shouldFlipEquEquation
  "If the flag +orderConnections=false is used, then we should keep the order of
   the connector elements as they occur in the connection (if possible). In that
   case we check if the cref of the first argument to the first connection
   stored in the element source is a prefix of the connector element cref. If
   it isn't, indicate that we should flip the generated equation."
  input DAE.ComponentRef inLhsCref;
  input DAE.ElementSource inLhsSource;
  input Boolean inShouldOrder;
  output Boolean outShouldFlip;
algorithm
  outShouldFlip := matchcontinue(inLhsCref, inLhsSource, inShouldOrder)
    local
      DAE.ComponentRef lhs;

    case (_, DAE.SOURCE(connectEquationOptLst = SOME((lhs, _)) :: _), false)
      then not ComponentReference.crefPrefixOf(lhs, inLhsCref);

    else false;
  end matchcontinue;
end shouldFlipEquEquation;

protected function generateFlowEquations
  "Generating equations from a flow connection set is a little trickier that
   from a non-flow set. Only one equation is generated, but it has to consider
   whether the components were inside or outside connectors. This function
   creates a sum expression of all components (some of which will be negated),
   and the returns the equation where this sum is equal to 0.0."
  input list<ConnectorElement> inElements;
  output DAE.DAElist outDae;
protected
  DAE.Exp sum;
  DAE.ElementSource src;
  list<DAE.ElementSource> srcl;
  DAE.FunctionTree funcs;
algorithm
  sum := List.reduce(List.map(inElements, makeFlowExp),Expression.makeRealAdd);
  srcl := List.map(inElements, getElementSource);
  src := List.reduce(srcl, DAEUtil.mergeSources);
  outDae := DAE.DAE({DAE.EQUATION(sum, DAE.RCONST(0.0), src)});
end generateFlowEquations;

protected function makeFlowExp
  "Creates an expression from a connector element, which is the element itself
   if it's an inside connector, or negated if it's outside."
  input ConnectorElement inElement;
  output DAE.Exp outExp;
algorithm
  outExp := match(inElement)
    local
      DAE.ComponentRef name;

    case Connect.CONNECTOR_ELEMENT(name = name, face = Connect.INSIDE())
      then Expression.crefExp(name);

    case Connect.CONNECTOR_ELEMENT(name = name, face = Connect.OUTSIDE())
      then Expression.negateReal(Expression.crefExp(name));

  end match;
end makeFlowExp;

public function increaseConnectRefCount
  input DAE.ComponentRef inLhsCref;
  input DAE.ComponentRef inRhsCref;
  input Sets inSets;
  output Sets outSets;
algorithm
  outSets := matchcontinue(inLhsCref, inRhsCref, inSets)
    local
      SetTrie sets;
      list<DAE.ComponentRef> crefs;

    case (_, _, _)
      equation
        false = System.getUsesCardinality();
      then
        inSets;

    case (_, _, Connect.SETS(sets = sets))
      equation
        crefs = ComponentReference.expandCref(inLhsCref, false);
        sets = increaseConnectRefCount2(crefs, sets);
        crefs = ComponentReference.expandCref(inRhsCref, false);
        sets = increaseConnectRefCount2(crefs, sets);
      then
        setSets(sets, inSets);

  end matchcontinue;
end increaseConnectRefCount;

public function increaseConnectRefCount2
  input list<DAE.ComponentRef> inCref;
  input SetTrie inSets;
  output SetTrie outSets;
protected
  list<DAE.ComponentRef> crefs;
algorithm
  outSets := match(inCref, inSets)
    local
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> rest_crefs;
      SetTrie sets;

    case (cref :: rest_crefs, _)
      equation
        sets = setTrieUpdate(cref, 1, inSets, increaseRefCount);
      then
        increaseConnectRefCount2(rest_crefs, sets);

    else inSets;

  end match;
end increaseConnectRefCount2;

protected function increaseRefCount
  input Integer inAmount;
  input SetTrieNode inNode;
  output SetTrieNode outNode;
algorithm
  outNode := match(inAmount, inNode)
    local
      String name;
      DAE.ComponentRef cref;
      list<SetTrieNode> nodes;
      Integer cc;
      Option<ConnectorElement> ie, oe;
      Option<DAE.ComponentRef> fa;

    case (_, Connect.SET_TRIE_NODE(name, cref, nodes, cc))
      equation
        cc = cc + inAmount;
      then
        Connect.SET_TRIE_NODE(name, cref, nodes, cc);

    case (_, Connect.SET_TRIE_LEAF(name, ie, oe, fa, cc))
      equation
        cc = cc + inAmount;
      then
        Connect.SET_TRIE_LEAF(name, ie, oe, fa, cc);

  end match;
end increaseRefCount;

protected function generateStreamEquations
  "Generates the equations for a stream connection set."
  input list<ConnectorElement> inElements;
  input Real inFlowThreshold;
  output DAE.DAElist outDae;
algorithm
  outDae := match(inElements)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource src1, src2, src;
      DAE.DAElist dae;
      Connect.Face f1, f2;
      DAE.Exp cref1, cref2, e1, e2;
      list<ConnectorElement> inside, outside;

    // Unconnected stream connector, do nothing!
    case ({Connect.CONNECTOR_ELEMENT(face = Connect.INSIDE())})
      then DAE.emptyDae;

    // Both inside, do nothing!
    case ({Connect.CONNECTOR_ELEMENT(face = Connect.INSIDE()),
           Connect.CONNECTOR_ELEMENT(face = Connect.INSIDE())})
      then DAE.emptyDae;

    // Both outside:
    // cr1 = inStream(cr2);
    // cr2 = inStream(cr1);
    case ({Connect.CONNECTOR_ELEMENT(name = cr1, face = Connect.OUTSIDE(), source = src1),
           Connect.CONNECTOR_ELEMENT(name = cr2, face = Connect.OUTSIDE(), source = src2)})
      equation
        cref1 = Expression.crefExp(cr1);
        cref2 = Expression.crefExp(cr2);
        e1 = makeInStreamCall(cref2);
        e2 = makeInStreamCall(cref1);
        src = DAEUtil.mergeSources(src1, src2);
        dae = DAE.DAE({
          DAE.EQUATION(cref1, e1, src),
          DAE.EQUATION(cref2, e2, src)});
      then
        dae;

    // One inside, one outside:
    // cr1 = cr2;
    case ({Connect.CONNECTOR_ELEMENT(name = cr1, source = src1),
           Connect.CONNECTOR_ELEMENT(name = cr2, source = src2)})
      equation
        src = DAEUtil.mergeSources(src1, src2);
        e1 = Expression.crefExp(cr1);
        e2 = Expression.crefExp(cr2);
        dae = DAE.DAE({DAE.EQUATION(e1,e2,src)});
      then dae;

    // The general case with N inside connectors and M outside:
    else
      algorithm
        (outside, inside) := List.splitOnTrue(inElements, isOutsideStream);
        dae := streamEquationGeneral(outside, inside, inFlowThreshold);
      then
        dae;

  end match;
end generateStreamEquations;

protected function isOutsideStream
  "Returns true if the stream connector element belongs to an outside connector."
  input ConnectorElement inElement;
  output Boolean isOutside;
algorithm
  isOutside := match(inElement)
    case Connect.CONNECTOR_ELEMENT(face = Connect.OUTSIDE()) then true;
    else false;
  end match;
end isOutsideStream;

protected function isZeroFlowMinMax
  "Returns true if the given flow attribute of a connector is zero."
  input DAE.ComponentRef inStreamCref;
  input ConnectorElement inElement;
  output Boolean isZero;
algorithm
  if compareCrefStreamSet(inStreamCref, inElement) then
    isZero := false;
  elseif isOutsideStream(inElement) then
    isZero := isZeroFlow(inElement, "max");
  else
    isZero := isZeroFlow(inElement, "min");
  end if;
end isZeroFlowMinMax;

protected function isZeroFlow
  "Returns true if the given flow attribute of a connector is zero."
  input ConnectorElement inElement;
  input String attr;
  output Boolean isZero;
protected
  DAE.Type ty;
  Option<DAE.Exp> attr_oexp;
  DAE.Exp flow_exp, attr_exp;
algorithm
  flow_exp := flowExp(inElement);
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
  input list<ConnectorElement> inOutsideElements;
  input list<ConnectorElement> inInsideElements;
  input Real inFlowThreshold;
  output DAE.DAElist outDae = DAE.emptyDae;
protected
  list<ConnectorElement> outside;
  DAE.Exp cref_exp, res;
  DAE.ElementSource src;
  DAE.DAElist dae;
  DAE.ComponentRef name;
algorithm
  for e in inOutsideElements loop
    Connect.CONNECTOR_ELEMENT(name = name, source = src) := e;
    cref_exp := Expression.crefExp(name);
    outside := removeStreamSetElement(name, inOutsideElements);
    res := streamSumEquationExp(outside, inInsideElements, inFlowThreshold);
    src := DAEUtil.addAdditionalComment(src, " equation generated by stream handling");
    dae := DAE.DAE({DAE.EQUATION(cref_exp, res, src)});
    outDae := DAEUtil.joinDaes(dae, outDae);
  end for;
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
  input list<ConnectorElement> inOutsideElements;
  input list<ConnectorElement> inInsideElements;
  input Real inFlowThreshold;
  output DAE.Exp outSumExp;
protected
  DAE.Exp outside_sum1, outside_sum2, inside_sum1, inside_sum2, res;
algorithm
  if listEmpty(inOutsideElements) then
    // No outside components.
    inside_sum1 := sumMap(inInsideElements, sumInside1, inFlowThreshold);
    inside_sum2 := sumMap(inInsideElements, sumInside2, inFlowThreshold);
    outSumExp := Expression.expDiv(inside_sum1, inside_sum2);
  elseif listEmpty(inInsideElements) then
    // No inside components.
    outside_sum1 := sumMap(inOutsideElements, sumOutside1, inFlowThreshold);
    outside_sum2 := sumMap(inOutsideElements, sumOutside2, inFlowThreshold);
    outSumExp := Expression.expDiv(outside_sum1, outside_sum2);
  else
    // Both outside and inside components.
    outside_sum1 := sumMap(inOutsideElements, sumOutside1, inFlowThreshold);
    outside_sum2 := sumMap(inOutsideElements, sumOutside2, inFlowThreshold);
    inside_sum1 := sumMap(inInsideElements, sumInside1, inFlowThreshold);
    inside_sum2 := sumMap(inInsideElements, sumInside2, inFlowThreshold);
    outSumExp := Expression.expDiv(Expression.expAdd(outside_sum1, inside_sum1),
                                   Expression.expAdd(outside_sum2, inside_sum2));
  end if;
end streamSumEquationExp;

protected function sumMap
  "Creates a sum expression by applying the given function on the list of
  elements and summing up the resulting expressions."
  input list<ConnectorElement> inElements;
  input FuncType inFunc;
  input Real inFlowThreshold;
  output DAE.Exp outExp;

  partial function FuncType
    input ConnectorElement inElement;
    input Real inFlowThreshold;
    output DAE.Exp outExp;
  end FuncType;
algorithm
  outExp := Expression.expAdd(inFunc(e, inFlowThreshold) for e in listReverse(inElements));
end sumMap;

protected function streamFlowExp
  "Returns the stream and flow component in a stream set element as expressions."
  input ConnectorElement inElement;
  output DAE.Exp outStreamExp;
  output DAE.Exp outFlowExp;
protected
  DAE.ComponentRef stream_cr, flow_cr;
algorithm
  Connect.CONNECTOR_ELEMENT(name = stream_cr, ty = Connect.STREAM(SOME(flow_cr))) := inElement;
  outStreamExp := Expression.crefExp(stream_cr);
  outFlowExp := Expression.crefExp(flow_cr);
end streamFlowExp;

protected function flowExp
  "Returns the flow component in a stream set element as an expression."
  input ConnectorElement inElement;
  output DAE.Exp outFlowExp;
protected
  DAE.ComponentRef flow_cr;
algorithm
  Connect.CONNECTOR_ELEMENT(ty = Connect.STREAM(SOME(flow_cr))) := inElement;
  outFlowExp := Expression.crefExp(flow_cr);
end flowExp;

protected function sumOutside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps) * inStream(stream_exp)
  given a stream set element."
  input ConnectorElement inElement;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
protected
  DAE.Exp stream_exp, flow_exp, flow_threshold;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(inElement);
  flow_threshold := DAE.RCONST(inFlowThreshold);
  outExp := Expression.expMul(makePositiveMaxCall(flow_exp, flow_threshold),
                              makeInStreamCall(stream_exp));
end sumOutside1;

protected function sumInside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps) * stream_exp
  given a stream set element."
  input ConnectorElement inElement;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
protected
  DAE.Exp stream_exp, flow_exp, flow_threshold;
  DAE.Type flowTy, streamTy;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(inElement);
  flowTy := Expression.typeof(flow_exp);
  flow_exp := DAE.UNARY(DAE.UMINUS(flowTy), flow_exp);
  flow_threshold := DAE.RCONST(inFlowThreshold);
  outExp := Expression.expMul(makePositiveMaxCall(flow_exp, flow_threshold), stream_exp);
end sumInside1;

protected function sumOutside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps)
  given a stream set element."
  input ConnectorElement inElement;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
protected
  DAE.Exp flow_exp;
algorithm
  flow_exp := flowExp(inElement);
  outExp := makePositiveMaxCall(flow_exp, DAE.RCONST(inFlowThreshold));
end sumOutside2;

protected function sumInside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps)
  given a stream set element."
  input ConnectorElement inElement;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
protected
  DAE.Exp flow_exp;
  DAE.Type flowTy;
algorithm
  flow_exp := flowExp(inElement);
  flowTy := Expression.typeof(flow_exp);
  flow_exp := DAE.UNARY(DAE.UMINUS(flowTy), flow_exp);
  outExp := makePositiveMaxCall(flow_exp, DAE.RCONST(inFlowThreshold));
end sumInside2;

public function faceEqual "Test for face equality."
  input Connect.Face inFace1;
  input Connect.Face inFace2;
  output Boolean sameFaces;
algorithm
  sameFaces := match (inFace1,inFace2)
    case (Connect.INSIDE(),Connect.INSIDE()) then true;
    case (Connect.OUTSIDE(),Connect.OUTSIDE()) then true;
    else false;
  end match;
end faceEqual;

protected function makeInStreamCall
  "Creates an inStream call expression."
  input DAE.Exp inStreamExp;
  output DAE.Exp outInStreamCall;
  annotation(__OpenModelica_EarlyInline = true);
protected
  DAE.Type ty;
algorithm
  ty := Expression.typeof(inStreamExp);
  outInStreamCall := Expression.makeBuiltinCall("inStream",{inStreamExp},ty,false);
end makeInStreamCall;

protected function makePositiveMaxCall
  "Generates a max(flow_exp, eps) call."
  input DAE.Exp inFlowExp;
  input DAE.Exp inFlowThreshold;
  output DAE.Exp outPositiveMaxCall;
  annotation(__OpenModelica_EarlyInline = true);
protected
  DAE.Type ty;
  list<DAE.Var> attr;
  Option<DAE.Exp> nominal_oexp;
  DAE.Exp nominal_exp, flow_threshold;
algorithm
  ty := Expression.typeof(inFlowExp);
  nominal_oexp := Types.lookupAttributeExp(Types.getAttributes(ty), "nominal");

  if isSome(nominal_oexp) then
    SOME(nominal_exp) := nominal_oexp;
    flow_threshold := Expression.expMul(inFlowThreshold, nominal_exp);
  else
    flow_threshold := inFlowThreshold;
  end if;

  outPositiveMaxCall :=
     DAE.CALL(
        Absyn.IDENT("max"),
        {inFlowExp, flow_threshold},
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
  input Boolean inHasStream;
  input Boolean inHasCardinality;
  input Sets inSets;
  input array<Set> inSetArray;
  input DAE.DAElist inDae;
  output DAE.DAElist outDae;
protected
  Real flow_threshold;
algorithm
  // Skip this phase if we have no connection operators.
  if not inHasStream and not inHasCardinality then
    outDae := inDae;
  else
    flow_threshold := Flags.getConfigReal(Flags.FLOW_THRESHOLD);
    outDae := DAEUtil.traverseDAE(inDae, DAE.emptyFuncTree,
      function evaluateConnectionOperators2(
        inHasCardinality = inHasCardinality,
        inSetArray = inSetArray,
        inFlowThreshold = flow_threshold), inSets);
    outDae := simplifyDAEElements(inHasCardinality, outDae);
  end if;
end evaluateConnectionOperators;

protected function evaluateConnectionOperators2
  "Helper function to evaluateConnectionOperators."
  input DAE.Exp inExp;
  input Connect.Sets inSets;
  input array<Set> inSetArray;
  input Boolean inHasCardinality;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
  output Connect.Sets outSets = inSets;
protected
  Boolean changed;
algorithm
  (outExp, changed) := Expression.traverseExpBottomUp(inExp,
    function evaluateConnectionOperatorsExp(
      inSets = inSets,
      inSetArray = inSetArray,
      inFlowThreshold = inFlowThreshold), false);

  // Only apply simplify if the expression changed *AND* we have cardinality.
  if changed and inHasCardinality then
    outExp := ExpressionSimplify.simplify(outExp);
  end if;
end evaluateConnectionOperators2;

protected function evaluateConnectionOperatorsExp
  "Helper function to evaluateConnectionOperators2. Checks if the given
   expression is a call to inStream or actualStream, and if so calls the
   appropriate function in ConnectUtil to evaluate the call."
  input DAE.Exp inExp;
  input Sets inSets;
  input array<Set> inSetArray;
  input Real inFlowThreshold;
  input Boolean inChanged;
  output DAE.Exp outExp;
  output Boolean outChanged;
algorithm
  (outExp, outChanged) := match inExp
    local
      DAE.ComponentRef cr;
      Connect.Sets sets;
      array<Set> set_arr;
      DAE.Exp e;
      DAE.Type ty;

    case DAE.CALL(path = Absyn.IDENT("inStream"),
                  expLst = {DAE.CREF(componentRef = cr)})
      equation
        e = evaluateInStream(cr, inSets, inSetArray, inFlowThreshold);
        //print("Evaluated inStream(" + ExpressionDump.dumpExpStr(DAE.CREF(cr, ty), 0) + ") ->\n" + ExpressionDump.dumpExpStr(e, 0) + "\n");
      then
        (e, true);

    case DAE.CALL(path = Absyn.IDENT("actualStream"),
                  expLst = {DAE.CREF(componentRef = cr)})
      equation
        e = evaluateActualStream(cr, inSets, inSetArray, inFlowThreshold);
        //print("Evaluated actualStream(" + ExpressionDump.dumpExpStr(DAE.CREF(cr, ty), 0) + ") ->\n" + ExpressionDump.dumpExpStr(e, 0) + "\n");
      then
        (e, true);

    case DAE.CALL(path = Absyn.IDENT("cardinality"),
                  expLst = {DAE.CREF(componentRef = cr)})
      equation
        e = evaluateCardinality(cr, inSets);
      then
        (e, true);

    else (inExp, inChanged);

  end match;
end evaluateConnectionOperatorsExp;

protected function mkArrayIfNeeded
"@author: adrpo
 does an array out of exp if needed"
  input DAE.Type inTy;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inTy, inExp)
    local
      DAE.Exp exp;
      DAE.Dimensions dims;

    case (_, _)
      equation
        dims = Types.getDimensions(inTy);
        exp = Expression.arrayFill(dims, inExp);
      then
        exp;

    else inExp;

  end matchcontinue;
end mkArrayIfNeeded;

protected function evaluateInStream
  "This function evaluates the inStream operator for a component reference,
   given the connection sets."
  input DAE.ComponentRef inStreamCref;
  input Sets inSets;
  input array<Set> inSetArray;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
protected
  ConnectorElement e;
  list<ConnectorElement> sl;
  Integer set;
algorithm
  try
    e := findElement(inStreamCref, Connect.INSIDE(), Connect.STREAM(NONE()),
      DAE.emptyElementSource, inSets);

    if isNewElement(e) then
      // A new element means that the stream element couldn't be found in the sets
      // => unconnected stream connector.
      sl := {e};
    else
      // Otherwise, fetch the set that the element belongs to and evaluate the
      // inStream call.
      Connect.CONNECTOR_ELEMENT(set = set) := e;
      Connect.SET(ty = Connect.STREAM(), elements = sl) :=
        setArrayGet(inSetArray, set);
    end if;

    outExp := generateInStreamExp(inStreamCref, sl, inSets, inSetArray, inFlowThreshold);
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- ConnectUtil.evaluateInStream failed for " +
      ComponentReference.crefStr(inStreamCref) + "\n");
  end try;
end evaluateInStream;

protected function generateInStreamExp
  "Helper function to evaluateInStream. Generates an expression for inStream
  given a connection set."
  input DAE.ComponentRef inStreamCref;
  input list<ConnectorElement> inStreams;
  input Sets inSets;
  input array<Set> inSetArray;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
protected
  list<ConnectorElement> reducedStreams;
algorithm
  reducedStreams := List.filterOnFalse(inStreams, function isZeroFlowMinMax(inStreamCref = inStreamCref));
  outExp := match reducedStreams
    local
      DAE.ComponentRef c;
      Connect.Face f1, f2;
      DAE.Exp e;
      list<ConnectorElement>  inside, outside;

    // Unconnected stream connector:
    // inStream(c) = c;
    case {Connect.CONNECTOR_ELEMENT(name = c, face = Connect.INSIDE())}
      then Expression.crefExp(c);

    // Two inside connected stream connectors:
    // inStream(c1) = c2;
    // inStream(c2) = c1;
    case {Connect.CONNECTOR_ELEMENT(face = Connect.INSIDE()),
          Connect.CONNECTOR_ELEMENT(face = Connect.INSIDE())}
      algorithm
        {Connect.CONNECTOR_ELEMENT(name = c)} :=
          removeStreamSetElement(inStreamCref, reducedStreams);
        e := Expression.crefExp(c);
      then
        e;

    // One inside, one outside connected stream connector:
    // inStream(c1) = inStream(c2);
    case {Connect.CONNECTOR_ELEMENT(face = f1),
          Connect.CONNECTOR_ELEMENT(face = f2)}
      algorithm
        false := faceEqual(f1, f2);
        {Connect.CONNECTOR_ELEMENT(name = c)} :=
          removeStreamSetElement(inStreamCref, reducedStreams);
        e := evaluateInStream(c, inSets, inSetArray, inFlowThreshold);
      then
        e;

    // The general case:
    else
      algorithm
        (outside, inside) := List.splitOnTrue(reducedStreams, isOutsideStream);
        inside := removeStreamSetElement(inStreamCref, inside);
        e := streamSumEquationExp(outside, inside, inFlowThreshold);
        // Evaluate any inStream calls that were generated.
        e := evaluateConnectionOperators2(e, inSets, inSetArray, false, inFlowThreshold);
      then
        e;
  end match;
end generateInStreamExp;

protected function evaluateActualStream
  "This function evaluates the actualStream operator for a component reference,
  given the connection sets."
  input DAE.ComponentRef inStreamCref;
  input Connect.Sets inSets;
  input array<Set> inSetArray;
  input Real inFlowThreshold;
  output DAE.Exp outExp;
protected
  DAE.ComponentRef flow_cr;
  DAE.Exp e, flow_exp, stream_exp, instream_exp, rel_exp;
  DAE.Type ety;
  Integer flow_dir;
algorithm
  flow_cr := getStreamFlowAssociation(inStreamCref, inSets);
  ety := ComponentReference.crefLastType(flow_cr);
  flow_dir := evaluateFlowDirection(ety);

  // Select a branch if we know the flow direction, otherwise generate the whole
  // if-equation.
  if flow_dir == 1 then
    rel_exp := evaluateInStream(inStreamCref, inSets, inSetArray, inFlowThreshold);
  elseif flow_dir == -1 then
    rel_exp := Expression.crefExp(inStreamCref);
  else
    flow_exp := Expression.crefExp(flow_cr);
    stream_exp := Expression.crefExp(inStreamCref);
    instream_exp := evaluateInStream(inStreamCref, inSets, inSetArray,
                      inFlowThreshold);
    rel_exp := DAE.IFEXP(
      DAE.RELATION(flow_exp, DAE.GREATER(ety), DAE.RCONST(0.0), -1, NONE()),
      instream_exp, stream_exp);
  end if;

  // actualStream(stream_var) = smooth(0, if flow_var > 0 then inStream(stream_var)
  //                                                      else stream_var);
  outExp := DAE.CALL(Absyn.IDENT("smooth"), {DAE.ICONST(0), rel_exp},
    DAE.callAttrBuiltinReal);
end evaluateActualStream;

protected function evaluateFlowDirection
  "Checks the min/max attributes of a flow variables type to try and determine
  the flow direction. If the flow is positive 1 is returned, if it is negative
  -1, otherwise 0 if the direction can't be decided."
  input DAE.Type inType;
  output Integer outDirection = 0;
protected
  list<DAE.Var> attr;
  Option<Values.Value> min_oval, max_oval;
  Real min_val, max_val;
algorithm
  attr := Types.getAttributes(inType);
  if listEmpty(attr) then return; end if;

  min_oval := Types.lookupAttributeValue(attr, "min");
  max_oval := Types.lookupAttributeValue(attr, "max");

  outDirection := match (min_oval, max_oval)
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
  input DAE.ComponentRef inCref;
  input Connect.Sets inSets;
  output DAE.Exp outExp;
protected
  SetTrie sets;
  Integer count;
algorithm
  Connect.SETS(sets = sets) := inSets;
  count := getConnectCount(inCref, sets);
  outExp := DAE.ICONST(count);
end evaluateCardinality;

protected function simplifyDAEElements
"run this only if we have cardinality"
  input Boolean inHasCardinality;
  input DAE.DAElist inDAE;
  output DAE.DAElist outDAE;
algorithm
  outDAE := match(inHasCardinality, inDAE)
    local
      list<DAE.Element> elems;

    case (false, _) then inDAE;

    case (true, _)
      equation
        DAE.DAE(elementLst = elems) = inDAE;
        elems = List.mapFlat(elems, simplifyDAEElement);
        outDAE = DAE.DAE(elems);
      then
        outDAE;

  end match;
end simplifyDAEElements;

protected function simplifyDAEElement
  input DAE.Element inElement;
  output list<DAE.Element> outElements;
algorithm
  outElements := matchcontinue(inElement)
    local
      list<DAE.Exp> conds;
      list<list<DAE.Element>> branches;
      list<DAE.Element> else_branch;
      DAE.ElementSource src;

    case DAE.IF_EQUATION(conds, branches, else_branch, src)
      then simplifyDAEIfEquation(conds, branches, else_branch, src);

    case DAE.INITIAL_IF_EQUATION(conds, branches, else_branch, src)
      then simplifyDAEIfEquation(conds, branches, else_branch, src);

    case DAE.ASSERT(condition = DAE.BCONST(true)) then {};
    else {inElement};

  end matchcontinue;
end simplifyDAEElement;

protected function simplifyDAEIfEquation
  input list<DAE.Exp> inConditions;
  input list<list<DAE.Element>> inBranches;
  input list<DAE.Element> inElseBranch;
  input DAE.ElementSource inSource;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inConditions, inBranches, inElseBranch, inSource)
    local
      list<DAE.Element> elems;
      list<list<DAE.Element>> rest_branches;
      list<DAE.Exp> rest_cond;

    // Condition is true, substitute if-equation with the branch contents.
    case (DAE.BCONST(true) :: _, elems :: _, _, _)
      then listReverse(elems);

    // Condition is false, discard the branch and continue with the other branches.
    case (DAE.BCONST(false) :: rest_cond, _ :: rest_branches, _, _)
      then simplifyDAEIfEquation(rest_cond, rest_branches, inElseBranch, inSource);

    // All conditions were false, substitute if-equation with else-branch contents.
    case ({}, {}, _, _) then listReverse(inElseBranch);

  end match;
end simplifyDAEIfEquation;

protected function removeStreamSetElement
  "This function removes the given cref from a connection set."
  input DAE.ComponentRef inCref;
  input list<ConnectorElement> inElements;
  output list<ConnectorElement> outElements;
algorithm
  (outElements, _) := List.deleteMemberOnTrue(inCref, inElements, compareCrefStreamSet);
end removeStreamSetElement;

protected function compareCrefStreamSet
  "Helper function to removeStreamSetElement. Checks if the cref in a stream set
  element matches the given cref."
  input DAE.ComponentRef inCref;
  input ConnectorElement inElement;
  output Boolean outRes;
algorithm
  outRes := matchcontinue(inCref, inElement)
    local
      DAE.ComponentRef cr;
    case (_, Connect.CONNECTOR_ELEMENT(name = cr))
      equation
        true = ComponentReference.crefEqualNoStringCompare(inCref, cr);
      then
        true;
    else false;
  end matchcontinue;
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
  input InnerOuter.InstHierarchy inIH;
  input DAE.ComponentRef inComponentRef;
  output Connect.Face outFace;
algorithm
  outFace := matchcontinue (env,inIH,inComponentRef)
    local
      DAE.ComponentRef cr;
      DAE.Ident id;
      InnerOuter.InstHierarchy ih;

    // is a non-qualified cref => OUTSIDE
    case (_,_,DAE.CREF_IDENT())
      then Connect.OUTSIDE();

    // is a qualified cref and is a connector => OUTSIDE
    case (_,_,DAE.CREF_QUAL(ident = id))
      equation
       (_,_,DAE.T_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_)),_,_,_,_,_,_)
         = Lookup.lookupVar(FCore.emptyCache(),env,ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
      then Connect.OUTSIDE();

    // is a qualified cref and is NOT a connector => INSIDE
    case (_,_,DAE.CREF_QUAL())
      then Connect.INSIDE();
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
  output Connect.Face outFace;
algorithm
  outFace := match (inComponentRef)
    // is a non-qualified cref => OUTSIDE
    case (DAE.CREF_IDENT()) then Connect.OUTSIDE();
    // is a qualified cref and is a connector => OUTSIDE
    case (DAE.CREF_QUAL(identType = DAE.T_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_)))) then Connect.OUTSIDE();
    // is a qualified cref and is NOT a connector => INSIDE
    case (DAE.CREF_QUAL()) then Connect.INSIDE();
  end match;
end componentFaceType;

public function checkConnectorBalance
  "Checks if a connector class is balanced or not, according to the rules in the
  Modelica 3.2 specification."
  input list<DAE.Var> inVars;
  input Absyn.Path path;
  input SourceInfo info;
protected
  Integer potentials, flows, streams;
algorithm
  (potentials, flows, streams) := countConnectorVars(inVars);
  true := checkConnectorBalance2(potentials, flows, streams, path, info);
  //print(Absyn.pathString(path) + " has:\n\t" +
  //  intString(potentials) + " potential variables\n\t" +
  //  intString(flows) + " flow variables\n\t" +
  //  intString(streams) + " stream variables\n\n");
end checkConnectorBalance;

protected function checkConnectorBalance2
  input Integer inPotentialVars;
  input Integer inFlowVars;
  input Integer inStreamVars;
  input Absyn.Path path;
  input SourceInfo info;
  output Boolean outIsBalanced;
algorithm
  outIsBalanced :=
  matchcontinue(inPotentialVars, inFlowVars, inStreamVars, path, info)
    local
      String error_str, flow_str, potential_str, class_str;

    // The connector is balanced.
    case (_, _, _, _, _)
      equation
        true = intEq(inPotentialVars, inFlowVars) or
          Config.languageStandardAtMost(Config.MODELICA_2_X());
        true = if intEq(inStreamVars, 0) then true else intEq(inFlowVars, 1);
      then
        true;

    // Modelica 3.2 section 9.3.1:
    // For each non-partial connector class the number of flow variables shall
    // be equal to the number of variables that are neither parameter, constant,
    // input, output, stream nor flow.
    case (_, _, _, _, _)
      equation
        false = intEq(inPotentialVars, inFlowVars);
        flow_str = intString(inFlowVars);
        potential_str = intString(inPotentialVars);
        class_str = Absyn.pathString(path);
        error_str = stringAppendList({
          "The number of potential variables (",
          potential_str,
          ") is not equal to the number of flow variables (",
          flow_str, ")."});
        Error.addSourceMessage(Error.UNBALANCED_CONNECTOR,
          {class_str, error_str}, info);
      then
        fail();

    // Modelica 3.2 section 15.1:
    // A stream connector must have exactly one scalar variable with the flow prefix.
    case (_, _, _, _, _)
      equation
        false = intEq(inStreamVars, 0);
        false = intEq(inFlowVars, 1);
        flow_str = intString(inFlowVars);
        class_str = Absyn.pathString(path);
        error_str = stringAppendList({
          "A stream connector must have exactly one flow variable, this connector has ",
          flow_str, " flow variables."});
        Error.addSourceMessage(Error.INVALID_STREAM_CONNECTOR,
          {class_str, error_str}, info);
      then
        false;

    else true;

  end matchcontinue;
end checkConnectorBalance2;

protected function countConnectorVars
  "Given a list of connector variables, this function counts how many potential,
  flow and stream variables it contains."
  input list<DAE.Var> inVars;
  output Integer potentialVars = 0;
  output Integer flowVars = 0;
  output Integer streamVars = 0;
protected
  DAE.Type ty, ty2;
  DAE.Attributes attr;
  Integer n, p, f, s;
  list<DAE.Var> vars;
algorithm
  for var in inVars loop
    DAE.TYPES_VAR(ty = ty, attributes = attr) := var;
    ty2 := Types.arrayElementType(ty);

    // Check if we have a connector inside a connector.
    if Types.isConnector(ty2) then
      // If we have an array of connectors, count the elements.
      n := product(dim for dim in Types.getDimensionSizes(ty));
      // Count the number of different variables inside the connector, and then
      // multiply those numbers with the dimensions of the array.
      vars := Types.getConnectorVars(ty2);
      (p, f, s) := countConnectorVars(vars);

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
            flowVars := flowVars + sizeOfVariable(var);
          then
            ();

        // A stream variable.
        case DAE.ATTR(connectorType = SCode.STREAM())
          algorithm
            streamVars := streamVars + sizeOfVariable(var);
          then
            ();

        // A potential variable.
        case DAE.ATTR(direction = Absyn.BIDIR(), variability = SCode.VAR())
          algorithm
            potentialVars := potentialVars + sizeOfVariable(var);
          then
            ();

        else ();
      end match;
    end if;
  end for;
end countConnectorVars;

protected function sizeOfVariableList
  "Calls sizeOfVariable on a list of variables, and adds up the results."
  input list<DAE.Var> inVar;
  output Integer outSize;
protected
  list<Integer> sizes;
algorithm
  sizes := List.map(inVar, sizeOfVariable);
  outSize := List.fold(sizes, intAdd, 0);
end sizeOfVariableList;

protected function sizeOfVariable
  "Different types of variables have different size, for example arrays. This
  function checks the size of one variable."
  input DAE.Var inVar;
  output Integer outSize;
algorithm
  outSize := match(inVar)
    local DAE.Type t;
    case DAE.TYPES_VAR(ty = t) then sizeOfVariable2(t);
  end match;
end sizeOfVariable;

protected function sizeOfVariable2
  "Helper function to sizeOfVariable."
  input DAE.Type inType;
  output Integer outSize;
algorithm
  outSize := match inType
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
      then intMul(Expression.dimensionSize(dim) for dim in inType.dims) *
           sizeOfVariable2(inType.ty);
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
    case DAE.T_SUBTYPE_BASIC(complexType = t) then sizeOfVariable2(t);
    // Anything we forgot?
    case t
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ConnectUtil.sizeOfVariable failed on " + Types.printTypeStr(t));
      then
        fail();
  end match;
end sizeOfVariable2;

public function checkShortConnectorDef
  "Checks a short connector definition that has extended a basic type, i.e.
   connector C = Real;."
  input ClassInf.State inState;
  input SCode.Attributes inAttributes;
  input SourceInfo inInfo;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inState, inAttributes, inInfo)
    local
      Absyn.Path class_path;
      Integer pv, fv, sv;
      SCode.ConnectorType ct;
      Boolean bf, bs;

    // Extended from bidirectional basic type, which means that it can't be
    // balanced.
    case (ClassInf.CONNECTOR(path = class_path),
        SCode.ATTR(connectorType = ct, direction = Absyn.BIDIR()), _)
      equation
        // The connector might be either flow, stream or neither.
        // This will set either fv, sv, or pv to 1, and the rest to 0, and
        // checkConnectorBalance2 will then be called to provide the appropriate
        // error message (or might actually succeed if +std=2.x or 1.x).
        bf = SCode.flowBool(ct);
        bs = SCode.streamBool(ct);
        fv = if bf then 1 else 0;
        sv = if bs then 1 else 0;
        pv = if bf or bs then 0 else 1;
        true = checkConnectorBalance2(pv, fv, sv, class_path, inInfo);
      then
        true;

    // Previous case failed, not a valid connector.
    case (ClassInf.CONNECTOR(),
      SCode.ATTR(direction = Absyn.BIDIR()), _) then false;

    // All other cases are ok.
    else true;
  end matchcontinue;
end checkShortConnectorDef;

public function isReferenceInConnects
  input list<ConnectorElement> inConnects;
  input DAE.ComponentRef inCref;
  output Boolean isThere;
algorithm
  isThere := match(inConnects, inCref)
    local
      list<ConnectorElement> rest;
      DAE.ComponentRef name;
      Boolean b;

    case ({}, _) then false;

    case (Connect.CONNECTOR_ELEMENT(name = name)::rest, _)
      equation
        b = if (ComponentReference.crefPrefixOf(inCref, name))
            then true
            else isReferenceInConnects(rest, inCref);
      then
        b;

  end match;
end isReferenceInConnects;

public function removeReferenceFromConnects
  input list<ConnectorElement> inConnects;
  input DAE.ComponentRef inCref;
  input list<ConnectorElement> inPrefix;
  output list<ConnectorElement> outConnects;
  output Boolean wasRemoved;
algorithm
  (outConnects, wasRemoved) := match(inConnects, inCref, inPrefix)
    local
      list<ConnectorElement> rest,  all;
      ConnectorElement e;
      DAE.ComponentRef name;
      Boolean b;

    // not there
    case ({}, _, _) then (listReverse(inPrefix), false);

    // there or middleground
    case ((e as Connect.CONNECTOR_ELEMENT(name = name))::rest, _, _)
      equation
        if (ComponentReference.crefPrefixOf(inCref, name))
        then
          all = listAppend(listReverse(inPrefix), rest);
          b = true;
        else
          (all, b) = removeReferenceFromConnects(rest, inCref, e::inPrefix);
        end if;
      then
        (all, b);

  end match;
end removeReferenceFromConnects;

public function printSetsStr
  "Prints a Sets to a String."
  input Sets inSets;
  output String outString;
protected
  SetTrie sets;
  Integer sc;
  list<SetConnection> c;
  list<OuterConnect> o;
algorithm
  Connect.SETS(sets, sc, c, o) := inSets;
  outString := intString(sc) + " sets:\n";
  outString := outString + printSetTrieStr(sets, "\t");
  outString := outString + "Connected sets:\n";
  outString := outString + printSetConnections(c) + "\n";
end printSetsStr;

protected function printSetTrieStr
  "Prints a SetTrie to a String."
  input SetTrie inTrie;
  input String inAccumName;
  output String outString;
algorithm
  outString := match(inTrie, inAccumName)
    local
      String name, res;
      Option<ConnectorElement> ie, oe;
      Option<DAE.ComponentRef> fa;
      list<SetTrieNode> nodes;

    case (Connect.SET_TRIE_DELETED(name = name), _)
      then inAccumName + "." + name + ": deleted\n";

    case (Connect.SET_TRIE_LEAF(name = name,
        insideElement = ie, outsideElement = oe, flowAssociation = fa), _)
      equation
        res = inAccumName + "." + name + ":";
        res = res + printLeafElementStr(ie);
        res = res + printLeafElementStr(oe);
        res = res + printOptFlowAssociation(fa) + "\n";
      then
        res;

    case (Connect.SET_TRIE_NODE(name = "", nodes = nodes), _)
      then stringAppendList(List.map1(nodes, printSetTrieStr, inAccumName));

    case (Connect.SET_TRIE_NODE(name = name, nodes = nodes), _)
      equation
        name = inAccumName + "." + name;
        res = stringAppendList(List.map1(nodes, printSetTrieStr, name));
      then
        res;

  end match;
end printSetTrieStr;

protected function printLeafElementStr
  "Prints an optional connector element to a String."
  input Option<ConnectorElement> inElement;
  output String outString;
algorithm
  outString := match(inElement)
    local
      ConnectorElement e;
      Integer set;
      ConnectorType ty;
      Face face;
      String res;

    case SOME(Connect.CONNECTOR_ELEMENT(face = face, ty = ty, set = set))
      equation
        res = " " + printFaceStr(face) + " ";
        res = res + printConnectorTypeStr(ty) + " [" + intString(set) + "]";
      then
        res;

    else "";

  end match;
end printLeafElementStr;

protected function printElementStr
  "Prints a connector element to a String."
  input ConnectorElement inElement;
  output String outString;
algorithm
  outString := match(inElement)
    local
      DAE.ComponentRef name;
      Integer set;
      ConnectorType ty;
      Face face;
      String res;

    case Connect.CONNECTOR_ELEMENT(name = name, face = face, ty = ty, set = set)
      equation
        res = ComponentReference.printComponentRefStr(name) + " ";
        res = res + printFaceStr(face) + " ";
        res = res + printConnectorTypeStr(ty) + " [" + intString(set) + "]";
      then
        res;

  end match;
end printElementStr;

public function printFaceStr
  "Prints the Face to a String."
  input Face inFace;
  output String outString;
algorithm
  outString := match(inFace)
    case Connect.INSIDE() then "inside";
    case Connect.OUTSIDE() then "outside";
    case Connect.NO_FACE() then "unknown";
  end match;
end printFaceStr;

protected function printConnectorTypeStr
  "Prints the connector type to a String."
  input ConnectorType inType;
  output String outString;
algorithm
  outString := match(inType)
    case Connect.EQU() then "equ";
    case Connect.FLOW() then "flow";
    case Connect.STREAM(_) then "stream";
  end match;
end printConnectorTypeStr;

protected function printOptFlowAssociation
  "Print an optional flow association to a String."
  input Option<DAE.ComponentRef> inCref;
  output String outString;
algorithm
  outString := match(inCref)
    local
      DAE.ComponentRef cr;

    case NONE() then "";
    case SOME(cr) then " associated flow: " +
      ComponentReference.printComponentRefStr(cr);

  end match;
end printOptFlowAssociation;

protected function printSetConnections
  "Prints a list of set connection to a String."
  input list<SetConnection> inConnections;
  output String outString;
algorithm
  outString := stringAppendList(List.map(inConnections, printSetConnection));
end printSetConnections;

protected function printSetConnection
  "Prints a set connection to a String."
  input SetConnection inConnection;
  output String outString;
protected
  Integer set1, set2;
algorithm
  (set1, set2) := inConnection;
  outString := "\t" + intString(set1) + " connected to " + intString(set2) + "\n";
end printSetConnection;

protected function printSetStr
  "Prints a Set to a String."
  input Set inSet;
  output String outString;
algorithm
  outString := match(inSet)
    local
      list<ConnectorElement> el;
      String str;
      Integer index;

    case Connect.SET(elements = el)
      equation
        str = stringDelimitList(List.map(el, printElementStr), ", ");
      then
        str;

    case Connect.SET_POINTER(index = index)
      equation
        str = "pointer to set " + intString(index);
      then
        str;

  end match;
end printSetStr;

protected function getAllEquCrefs
"@author: adrpo
 return all crefs present in EQU sets"
  input list<Set> inSets;
  input list<DAE.ComponentRef> inAcc;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  outCrefs := match (inSets, inAcc)
    local
      list<Set> rest;
      list<ConnectorElement> elms;
      DAE.ComponentRef name;
      list<DAE.ComponentRef> acc;

    case ({}, _) then inAcc;

    case (Connect.SET(ty = Connect.EQU(), elements = {})::rest, _)
      then getAllEquCrefs(rest, inAcc);

    case (Connect.SET(ty = Connect.EQU(), elements = Connect.CONNECTOR_ELEMENT(name = name)::elms)::rest, _)
      equation
        acc = getAllEquCrefs(Connect.SET(Connect.EQU(), elms)::rest, name::inAcc);
      then
        acc;
    /* TODO! FIXME! check if flow can be here or not, in an expandable connector
    case (Connect.SET(ty = Connect.FLOW(), elements = {})::rest, _)
      then getAllEquCrefs(rest, inAcc);

    case (Connect.SET(ty = Connect.FLOW(), elements = Connect.CONNECTOR_ELEMENT(name = name)::elms)::rest, _)
      equation
        acc = getAllEquCrefs(Connect.SET(Connect.FLOW(), elms)::rest, name::inAcc);
      then
        acc;
    */
    case (_::rest, _)
      then getAllEquCrefs(rest, inAcc);
  end match;
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
  input list<Set> inSets;
  input DAE.DAElist inDAE;
  input Boolean hasExpandable;
  output list<Set> outSets;
  output DAE.DAElist outDAE;
algorithm
  (outSets, outDAE) := match(inSets, inDAE, hasExpandable)
    local
      list<DAE.Element> elems;
      list<DAE.ComponentRef> expandableVars, unnecessary, usedInDAE, onlyExpandableConnected, equVars;
      DAE.DAElist dae;
      list<Set> sets;
      list<list<DAE.ComponentRef>> setsAsCrefs;

    case (_, _, false) then (inSets, inDAE);

    case (_, DAE.DAE(elems), true)
      equation
        // 1 - get all expandable crefs
        expandableVars = getExpandableVariablesWithNoBinding(elems, {});
        // print("All expandable (1):\n  " + stringDelimitList(List.map(expandableVars, ComponentReference.printComponentRefStr), "\n  ") + "\n");

        // 2 - remove all expandable without binding from the dae
        dae = DAEUtil.removeVariables(inDAE, expandableVars);
        // 2 - get all expandable crefs used in the dae (without the expandable vars)
        usedInDAE = DAEUtil.getAllExpandableCrefsFromDAE(dae);
        // print("Used in the DAE (2):\n  " + stringDelimitList(List.map(usedInDAE, ComponentReference.printComponentRefStr), "\n  ") + "\n");

        // 3 - get all expandable crefs that are connected ONLY with expandable
        setsAsCrefs = getExpandableEquSetsAsCrefs(inSets, {});
        setsAsCrefs = mergeEquSetsAsCrefs(setsAsCrefs);
        // TODO! FIXME! maybe we should do fixpoint here??
        setsAsCrefs = mergeEquSetsAsCrefs(setsAsCrefs);
        onlyExpandableConnected = getOnlyExpandableConnectedCrefs(setsAsCrefs, {});
        // print("All expandable - expandable connected (3):\n  " + stringDelimitList(List.map(onlyExpandableConnected, ComponentReference.printComponentRefStr), "\n  ") + "\n");

        // 4 - subtract (2) from (3)
        unnecessary = List.setDifferenceOnTrue(onlyExpandableConnected, usedInDAE, ComponentReference.crefEqualWithoutSubs);
        // print("REMOVE: (3)-(2):\n  " + stringDelimitList(List.map(unnecessary, ComponentReference.printComponentRefStr), "\n  ") + "\n");

        // 5 - remove unnecessary variables form the DAE
        dae = DAEUtil.removeVariables(inDAE, unnecessary);
        // 5 - remove unnecessary variables form the connection sets
        sets = removeCrefsFromSets(inSets, unnecessary);

        equVars = getAllEquCrefs(sets, {});
        // print("(6):\n  " + stringDelimitList(List.map(equVars, ComponentReference.printComponentRefStr), "\n  ") + "\n");
        expandableVars = List.setDifferenceOnTrue(expandableVars, usedInDAE, ComponentReference.crefEqualWithoutSubs);
        // print("(1)-(2)=(7):\n  " + stringDelimitList(List.map(equVars, ComponentReference.printComponentRefStr), "\n  ") + "\n");
        unnecessary = List.setDifferenceOnTrue(expandableVars, equVars, ComponentReference.crefEqualWithoutSubs);
        // print("REMOVE: (7)-(6):\n  " + stringDelimitList(List.map(unnecessary, ComponentReference.printComponentRefStr), "\n  ") + "\n");
        dae = DAEUtil.removeVariables(dae, unnecessary);
      then
        (sets, dae);
  end match;
end removeUnusedExpandableVariablesAndConnections;

protected function firstElementIsTrieNodeNamed
  input list<SetTrieNode> nodes;
  input String name;
  output Boolean b;
algorithm
  b := match (nodes,name)
    local
      String named;
    case (Connect.SET_TRIE_NODE(name = named)::_,_) then stringEq(name,named);
    else false;
  end match;
end firstElementIsTrieNodeNamed;

annotation(__OpenModelica_Interface="frontend");
end ConnectUtil;

