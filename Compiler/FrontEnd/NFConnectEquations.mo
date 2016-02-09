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

encapsulated package NFConnectEquations
" file:        NFConnectEquations.mo
  package:     NFConnectEquations
  description: Functions that generate connect equations.

  RCS: $Id$
"

public import Absyn;
public import NFConnect2;
public import DAE;
public import NFConnectionSets;
public import NFInstTypes;
public import Types;

protected import NFConnectUtil2;
protected import NFExpandableConnectors;
protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import List;
protected import Util;

public type Connections = NFConnect2.Connections;
public type Connection = NFConnect2.Connection;
public type Connector = NFConnect2.Connector;
public type ConnectorType = NFConnect2.ConnectorType;
public type Face = NFConnect2.Face;

public type Equation = NFInstTypes.Equation;
protected type DisjointSets = NFConnectionSets.DisjointSets;

public function generateEquations
  input Connections inConnections;
  input list<Connector> inFlowVariables;
  output DAE.DAElist outEquations;
algorithm
  outEquations := matchcontinue(inConnections, inFlowVariables)
    local
      DisjointSets disjoint_sets;
      Integer set_size;
      DAE.DAElist eql;
      list<list<Connector>> sets;
      list<Connector> flows;
      list<Connection> connections, expconnl;

    case (_, {}) guard NFConnectUtil2.isEmptyConnections(inConnections)
      then
        DAE.emptyDae;

    case (NFConnect2.CONNECTIONS(connections, expconnl, _, _), _)
      equation
        // Create set structure. TODO: Better set size?
        set_size = NFConnectUtil2.connectionCount(inConnections) + listLength(inFlowVariables);
        disjoint_sets = NFConnectionSets.emptySets(set_size);

        // Add flow variables to the set structure.
        flows = List.mapFlatReverse(inFlowVariables, NFConnectUtil2.expandConnector);
        disjoint_sets = List.fold(flows, NFConnectionSets.add, disjoint_sets);

        // Add connections to the set structure.
        connections = listReverse(connections);
        disjoint_sets = List.fold(connections, addConnectionToSet, disjoint_sets);

        // Elaborate expandable connectors and add them to the set structure.
        expconnl = NFExpandableConnectors.elaborate(expconnl);
        /*-------------------------------------------------------------------*/
        // TODO: Perhaps not use addConnectionToSet, since expansion might
        // already have been done?
        /*-------------------------------------------------------------------*/
        disjoint_sets = List.fold(expconnl, addConnectionToSet, disjoint_sets);

        // Extract the sets and generate equations for them.
        sets = NFConnectionSets.extractSets(disjoint_sets);
        eql = List.fold(sets, generateEquation, DAE.emptyDae);
      then
        eql;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ConnectUtil.generateEquations failed to generate connect equations.");
      then
        fail();

  end matchcontinue;
end generateEquations;

protected function addConnectionToSet
  input Connection inConnection;
  input DisjointSets inSets;
  output DisjointSets outSets;
algorithm
  outSets := match(inConnection, inSets)
    local
      DAE.VarKind var;

    // Don't add parameter/constant connectors, asserts for them should already
    // have been generated during typing.
    case (NFConnect2.CONNECTION(lhs = NFConnect2.CONNECTOR(attr =
        NFConnect2.CONN_ATTR(variability = var))), _)
        // Variability should have been checked already, so should be enough to
        // just check one since they should be the same.
        guard DAEUtil.isParamOrConstVarKind(var)
      then
        inSets;

    else
      then NFConnectionSets.expandAddConnection(inConnection, inSets);

  end match;
end addConnectionToSet;

protected function generateEquation
  input list<Connector> inSet;
  input DAE.DAElist inAccumEql;
  output DAE.DAElist outEquations;
protected
  ConnectorType cty;
  DAE.DAElist dae;
algorithm
  cty := getSetType(inSet);
  dae := generateEquation_dispatch(inSet, cty);
  outEquations := DAEUtil.joinDaes(inAccumEql, dae);
end generateEquation;

protected function getSetType
  input list<Connector> inSet;
  output ConnectorType outType;
algorithm
  // All connectors in a set should have the same type, so pick the first.
  NFConnect2.CONNECTOR(cty = outType) :: _ := inSet;
end getSetType;

protected function generateEquation_dispatch
  input list<Connector> inSet;
  input ConnectorType inType;
  output DAE.DAElist outEquations;
algorithm
  outEquations := match(inSet, inType)
    local

    case (_, NFConnect2.POTENTIAL()) then generatePotentialEquations(inSet);
    case (_, NFConnect2.FLOW()) then generateFlowEquations(inSet);
    case (_, NFConnect2.STREAM(_)) then generateStreamEquations(inSet);
    case (_, NFConnect2.NO_TYPE())
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"ConnectUtil.generateEquation_dispatch failed because of unknown connector type."});
      then
        fail();

  end match;
end generateEquation_dispatch;

protected function generatePotentialEquations
  "A non-flow connection set contains a number of components. Generating the
   equations from this set means equating all the components. For n components,
   this will give n-1 equations. For example, if the set contains the components
   X, Y.A and Z.B, the equations generated will be X = Y.A and X = Z.B. The
   order of the equations depends on whether the compiler flag orderConnections
   is true or false."
  input list<Connector> inElements;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(inElements)
    local
      DAE.ComponentRef x, y;
      list<Connector> rest_el;
      Connector e1, e2;
      list<DAE.Element> eq;
      String str;
      DAE.ElementSource src;

    case ((e1 as NFConnect2.CONNECTOR(name = x)) ::
          (e2 as NFConnect2.CONNECTOR(name = y)) :: rest_el)
      equation
        e1 = if Config.orderConnections() then e1 else e2;
        DAE.DAE(eq) = generatePotentialEquations(e1 :: rest_el);
        src = DAE.emptyElementSource;
      then
        DAE.DAE(DAE.EQUEQUATION(x, y, src) :: eq);

    case {_} then DAE.emptyDae;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = stringDelimitList(List.map(inElements, NFConnectUtil2.connectorStr), ", ");
        Debug.traceln("- ConnectUtil.generatePotentialEquations failed on {" + str + "}");
      then
        fail();

  end matchcontinue;
end generatePotentialEquations;

protected function generateFlowEquations
  "Generating equations from a flow connection set is a little trickier that
   from a non-flow set. Only one equation is generated, but it has to consider
   whether the components were inside or outside connectors. This function
   creates a sum expression of all components (some of which will be negated),
   and then returns the equation where this sum is equal to 0.0."
  input list<Connector> inElements;
  output DAE.DAElist outDae;
protected
  DAE.Exp sum;
  DAE.ElementSource src;
algorithm
  sum := List.reduce(List.map(inElements, makeFlowExp), Expression.makeRealAdd);
  src := DAE.emptyElementSource;
  outDae := DAE.DAE({DAE.EQUATION(sum, DAE.RCONST(0.0), src)});
end generateFlowEquations;

protected function makeFlowExp
  "Creates an expression from a connector element, which is the element itself
   if it's an inside connector, or negated if it's outside."
  input Connector inElement;
  output DAE.Exp outExp;
algorithm
  outExp := match(inElement)
    local
      DAE.ComponentRef name;

    case NFConnect2.CONNECTOR(name = name, face = NFConnect2.INSIDE())
      then Expression.crefExp(name);

    case NFConnect2.CONNECTOR(name = name, face = NFConnect2.OUTSIDE())
      then Expression.negateReal(Expression.crefExp(name));

  end match;
end makeFlowExp;

protected function generateStreamEquations
  "Generates the equations for a stream connection set."
  input list<Connector> inElements;
  output DAE.DAElist outDae;
algorithm
  outDae := match(inElements)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource src;
      DAE.DAElist dae;
      Face f1, f2;
      DAE.Exp cref1, cref2, e1, e2;
      list<Connector> inside, outside;

    // Unconnected stream connector, do nothing!
    case ({NFConnect2.CONNECTOR(face = NFConnect2.INSIDE())})
      then DAE.emptyDae;

    // Both inside, do nothing!
    case ({NFConnect2.CONNECTOR(face = NFConnect2.INSIDE()),
           NFConnect2.CONNECTOR(face = NFConnect2.INSIDE())})
      then DAE.emptyDae;

    // Both outside:
    // cr1 = inStream(cr2);
    // cr2 = inStream(cr1);
    case ({NFConnect2.CONNECTOR(name = cr1, face = NFConnect2.OUTSIDE()),
           NFConnect2.CONNECTOR(name = cr2, face = NFConnect2.OUTSIDE())})
      equation
        cref1 = Expression.crefExp(cr1);
        cref2 = Expression.crefExp(cr2);
        e1 = makeInStreamCall(cref2);
        e2 = makeInStreamCall(cref1);
        src = DAE.emptyElementSource;
        dae = DAE.DAE({
          DAE.EQUATION(cref1, e1, src),
          DAE.EQUATION(cref2, e2, src)});
      then
        dae;

    // One inside, one outside:
    // cr1 = cr2;
    case ({NFConnect2.CONNECTOR(name = cr1),
           NFConnect2.CONNECTOR(name = cr2)})
      equation
        e1 = Expression.crefExp(cr1);
        e2 = Expression.crefExp(cr2);
        src = DAE.emptyElementSource;
        dae = DAE.DAE({DAE.EQUATION(e1, e2, src)});
      then
        dae;

    // The general case with N inside connectors and M outside:
    case (_)
      equation
        (outside, inside) = List.splitOnTrue(inElements, isOutsideStream);
        dae = List.fold2(outside, streamEquationGeneral,
          outside, inside, DAE.emptyDae);
      then
        dae;

  end match;
end generateStreamEquations;

protected function isOutsideStream
  "Returns true if the stream connector element belongs to an outside connector."
  input Connector inElement;
  output Boolean isOutside;
algorithm
  isOutside := match(inElement)
    case NFConnect2.CONNECTOR(face = NFConnect2.OUTSIDE()) then true;
    else false;
  end match;
end isOutsideStream;

protected function streamEquationGeneral
  "Generates an equation for an outside stream connector element."
  input Connector inElement;
  input list<Connector> inOutsideElements;
  input list<Connector> inInsideElements;
  input DAE.DAElist inDae;
  output DAE.DAElist outDae;
protected
  list<Connector> outside;
  DAE.ComponentRef stream_cr;
  DAE.Exp cref_exp, outside_sum1, outside_sum2, inside_sum1, inside_sum2, res;
  DAE.ElementSource src;
  DAE.DAElist dae;
algorithm
  NFConnect2.CONNECTOR(name = stream_cr) := inElement;
  src := DAE.emptyElementSource;
  cref_exp := Expression.crefExp(stream_cr);
  outside := removeStreamSetElement(stream_cr, inOutsideElements);
  res := streamSumEquationExp(outside, inInsideElements);
  dae := DAE.DAE({DAE.EQUATION(cref_exp, res, src)});
  outDae := DAEUtil.joinDaes(dae, inDae);
end streamEquationGeneral;

protected function streamSumEquationExp
  "Generates the sum expression used by stream connector equations, given M
  outside connectors and N inside connectors:

    (sum(max(-flow_exp[i], eps) * stream_exp[i] for i in N) +
     sum(max( flow_exp[i], eps) * inStream(stream_exp[i]) for i in M)) /
    (sum(max(-flow_exp[i], eps) for i in N) +
     sum(max( flow_exp[i], eps) for i in M))
  "
  input list<Connector> inOutsideElements;
  input list<Connector> inInsideElements;
  output DAE.Exp outSumExp;
protected
  DAE.Exp outside_sum1, outside_sum2, inside_sum1, inside_sum2, res;
algorithm
  outSumExp := match(inOutsideElements, inInsideElements)
    // No outside components.
    case ({}, _)
      equation
        inside_sum1 = sumMap(inInsideElements, sumInside1);
        inside_sum2 = sumMap(inInsideElements, sumInside2);
        res = Expression.expDiv(inside_sum1, inside_sum2);
      then
        res;
    // No inside components.
    case (_, {})
      equation
        outside_sum1 = sumMap(inOutsideElements, sumOutside1);
        outside_sum2 = sumMap(inOutsideElements, sumOutside2);
        res = Expression.expDiv(outside_sum1, outside_sum2);
      then
        res;
    // Both outside and inside components.
    else
      equation
        outside_sum1 = sumMap(inOutsideElements, sumOutside1);
        outside_sum2 = sumMap(inOutsideElements, sumOutside2);
        inside_sum1 = sumMap(inInsideElements, sumInside1);
        inside_sum2 = sumMap(inInsideElements, sumInside2);
        res = Expression.expDiv(Expression.expAdd(outside_sum1, inside_sum1),
                                Expression.expAdd(outside_sum2, inside_sum2));
      then
        res;
  end match;
end streamSumEquationExp;

protected function sumMap
  "Creates a sum expression by applying the given function on the list of
  elements and summing up the resulting expressions."
  input list<SetElement> inElements;
  input FuncType inFunc;
  output DAE.Exp outExp;

  replaceable type SetElement subtypeof Any;

  partial function FuncType
    input SetElement inElement;
    output DAE.Exp outExp;
  end FuncType;
algorithm
  outExp := match(inElements, inFunc)
    local
      SetElement elem;
      list<SetElement> rest_elem;
      DAE.Exp e1, e2;

    case ({elem}, _)
      equation
        e1 = inFunc(elem);
      then
        e1;

    case (elem :: rest_elem, _)
      equation
        e1 = inFunc(elem);
        e2 = sumMap(rest_elem, inFunc);
      then
        Expression.expAdd(e1, e2);
  end match;
end sumMap;

protected function streamFlowExp
  "Returns the stream and flow component in a stream set element as expressions."
  input Connector inElement;
  output DAE.Exp outStreamExp;
  output DAE.Exp outFlowExp;
protected
  DAE.ComponentRef stream_cr, flow_cr;
algorithm
  NFConnect2.CONNECTOR(name = stream_cr, cty = NFConnect2.STREAM(SOME(flow_cr))) := inElement;
  outStreamExp := Expression.crefExp(stream_cr);
  outFlowExp := Expression.crefExp(flow_cr);
end streamFlowExp;

protected function flowExp
  "Returns the flow component in a stream set element as an expression."
  input Connector inElement;
  output DAE.Exp outFlowExp;
protected
  DAE.ComponentRef flow_cr;
algorithm
  NFConnect2.CONNECTOR(cty = NFConnect2.STREAM(SOME(flow_cr))) := inElement;
  outFlowExp := Expression.crefExp(flow_cr);
end flowExp;

protected function sumOutside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps) * inStream(stream_exp)
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp stream_exp, flow_exp;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(inElement);
  outExp := Expression.expMul(makePositiveMaxCall(flow_exp),
                              makeInStreamCall(stream_exp));
end sumOutside1;

protected function sumInside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps) * stream_exp
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp stream_exp, flow_exp;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(inElement);
  flow_exp := DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT), flow_exp);
  outExp := Expression.expMul(makePositiveMaxCall(flow_exp), stream_exp);
end sumInside1;

protected function sumOutside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps)
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp flow_exp;
algorithm
  flow_exp := flowExp(inElement);
  outExp := makePositiveMaxCall(flow_exp);
end sumOutside2;

protected function sumInside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps)
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp flow_exp;
algorithm
  flow_exp := flowExp(inElement);
  flow_exp := DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT), flow_exp);
  outExp := makePositiveMaxCall(flow_exp);
end sumInside2;

protected function makeInStreamCall
  "Creates an inStream call expression."
  input DAE.Exp inStreamExp;
  output DAE.Exp outInStreamCall;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outInStreamCall := DAE.CALL(Absyn.IDENT("inStream"), {inStreamExp},
    DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT, false, false, false, false, DAE.NO_INLINE(), DAE.NO_TAIL()));
end makeInStreamCall;

protected function makePositiveMaxCall
  "Generates a max(flow_exp, eps) call."
  input DAE.Exp inFlowExp;
  output DAE.Exp outPositiveMaxCall;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outPositiveMaxCall := DAE.CALL(Absyn.IDENT("max"),
    {inFlowExp, DAE.RCONST(1e-15)}, DAE.CALL_ATTR(DAE.T_REAL_DEFAULT, false, true, false, false, DAE.NO_INLINE(), DAE.NO_TAIL()));
end makePositiveMaxCall;

protected function removeStreamSetElement
  "This function removes the given cref from a connection set."
  input DAE.ComponentRef inCref;
  input list<Connector> inElements;
  output list<Connector> outElements;
algorithm
  (outElements, _) := List.deleteMemberOnTrue(inCref, inElements, compareCrefStreamSet);
end removeStreamSetElement;

protected function compareCrefStreamSet
  "Helper function to removeStreamSetElement. Checks if the cref in a stream set
  element matches the given cref."
  input DAE.ComponentRef inCref;
  input Connector inElement;
  output Boolean outRes;
algorithm
  outRes := match(inCref, inElement)
    local
      DAE.ComponentRef cr;
    case (_, NFConnect2.CONNECTOR(name = cr)) guard ComponentReference.crefEqualNoStringCompare(inCref, cr)
      then
        true;
    else false;
  end match;
end compareCrefStreamSet;

public function generateAssertion
  input Connector inLhsConnector;
  input Connector inRhsConnector;
  input SourceInfo inInfo;
  input list<Equation> inEquations;
  output list<Equation> outEquations;
  output Boolean outIsOnlyConst;
algorithm
  (outEquations, outIsOnlyConst) := matchcontinue(inLhsConnector, inRhsConnector,
      inInfo, inEquations)
    local
      DAE.ComponentRef lhs, rhs;
      DAE.Exp lhs_exp, rhs_exp;
      list<Equation> eql;
      Boolean is_only_const;
      DAE.Type lhs_ty, rhs_ty, ty;

    // Variable simple connection, nothing to do.
    case (NFConnect2.CONNECTOR(), NFConnect2.CONNECTOR(), _, _)
      equation
        false = NFConnectUtil2.isConstOrComplexConnector(inLhsConnector);
        false = NFConnectUtil2.isConstOrComplexConnector(inRhsConnector);
      then
        (inEquations, false);

    // One or both of the connectors are constant/parameter or complex,
    // generate assertion or error message.
    case (NFConnect2.CONNECTOR(name = lhs, ty = lhs_ty),
          NFConnect2.CONNECTOR(name = rhs, ty = rhs_ty), _, _)
      equation
        /* ------------------------------------------------------------------*/
        // TODO: If we have mixed Real/Integer, one of these expression might
        // need to be typecast. ty should be the common type.
        /* ------------------------------------------------------------------*/
        lhs_exp = DAE.CREF(lhs, lhs_ty);
        rhs_exp = DAE.CREF(rhs, rhs_ty);
        ty = lhs_ty;

        (eql, is_only_const) = generateAssertion2(lhs_exp, rhs_exp,
          ty, inInfo, inEquations);
      then
        (eql, is_only_const);

  end matchcontinue;
end generateAssertion;

protected function generateAssertion2
  input DAE.Exp inLhsExp;
  input DAE.Exp inRhsExp;
  input DAE.Type inType;
  input SourceInfo inInfo;
  input list<Equation> inEquations;
  output list<Equation> outEquations;
  output Boolean outIsOnlyConst;
algorithm
  (outEquations, outIsOnlyConst) :=
  matchcontinue(inLhsExp, inRhsExp, inType, inInfo, inEquations)
    local
      DAE.Exp bin_exp, abs_exp, cond_exp;
      Equation assertion;
      list<DAE.Var> lhs_vars, lhs_rest, rhs_vars, rhs_rest;
      DAE.ComponentRef lhs_cref, rhs_cref;
      list<Equation> eql;
      Boolean ioc;
      String ty_str;

    // One or both of the connectors are scalar Reals.
    case (_, _, _, _, _)
      equation
        true = Types.isScalarReal(inType);
        // Generate an 'abs(lhs - rhs) <= 0' assertion, to keep the flat Modelica
        // somewhat similar to Modelica (which doesn't allow == for Reals).
        bin_exp = DAE.BINARY(inLhsExp, DAE.SUB(inType), inRhsExp);
        abs_exp = DAE.CALL(Absyn.IDENT("abs"), {bin_exp}, DAE.callAttrBuiltinReal);
        cond_exp = DAE.RELATION(abs_exp, DAE.LESSEQ(inType), DAE.RCONST(0.0), 0, NONE());
        assertion = makeAssertion(cond_exp, inInfo);
      then
        (assertion :: inEquations, true);

    // Array connectors.
    case (_, _, DAE.T_ARRAY(), _, _)
      equation
        /* ------------------------------------------------------------------*/
        // TODO: Implement this.
        /* ------------------------------------------------------------------*/
        Error.addSourceMessage(Error.INTERNAL_ERROR,
          {"Generating assertions for connections not yet implemented for arrays."},
          inInfo);
      then
        fail();

    // Complex connectors.
    case (DAE.CREF(lhs_cref, DAE.T_COMPLEX(varLst = lhs_vars)),
          DAE.CREF(rhs_cref, DAE.T_COMPLEX(varLst = rhs_vars)), _, _, _)
      equation
        (lhs_vars, lhs_rest) = List.splitOnTrue(lhs_vars, DAEUtil.isParamConstOrComplexVar);
        (rhs_vars, rhs_rest) = List.splitOnTrue(rhs_vars, DAEUtil.isParamConstOrComplexVar);

        ioc = listEmpty(lhs_rest) and listEmpty(rhs_rest);

        (eql, ioc) = generateAssertion3(lhs_vars, rhs_vars,
          lhs_cref, rhs_cref, inInfo, inEquations, ioc);
      then
        (eql, ioc);

    // Other scalar types.
    case (_, _, _, _, _)
      equation
        true = Types.isSimpleType(inType);
        // Generate an 'lhs = rhs' assertion.
        cond_exp = DAE.RELATION(inLhsExp, DAE.EQUAL(inType), inRhsExp, 0, NONE());
        assertion = makeAssertion(cond_exp, inInfo);
      then
        (assertion :: inEquations, true);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- ConnectUtil.generateConnectAssertion2 failed on unknown type ");
        ty_str = Types.unparseType(inType);
        Debug.traceln(ty_str);
      then
        fail();

  end matchcontinue;
end generateAssertion2;

protected function makeAssertion
  input DAE.Exp inCondition;
  input SourceInfo inInfo;
  output Equation outAssert;
protected
  DAE.Exp cond_exp, msg_exp;
algorithm
  /* ------------------------------------------------------------------*/
  // TODO: Change this to a better message. Kept like this for now to be
  // as close to the old instantiation as possible.
  /* ------------------------------------------------------------------*/
  msg_exp := DAE.SCONST("automatically generated from connect");
  outAssert := NFInstTypes.ASSERT_EQUATION(inCondition, msg_exp,
    DAE.ASSERTIONLEVEL_ERROR, inInfo);
end makeAssertion;

protected function generateAssertion3
  input list<DAE.Var> inLhsVar;
  input list<DAE.Var> inRhsVar;
  input DAE.ComponentRef inLhsCref;
  input DAE.ComponentRef inRhsCref;
  input SourceInfo inInfo;
  input list<Equation> inEquations;
  input Boolean inIsOnlyConst;
  output list<Equation> outEquations;
  output Boolean outIsOnlyConst;
algorithm
  (outEquations, outIsOnlyConst) := match(inLhsVar, inRhsVar,
      inLhsCref, inRhsCref, inInfo, inEquations, inIsOnlyConst)
    local
      DAE.Var lhs_var, rhs_var;
      list<DAE.Var> lhs_rest, rhs_rest;
      list<Equation> eql;
      Boolean ioc;

    case (lhs_var :: lhs_rest, rhs_var :: rhs_rest, _, _, _, eql, _)
      equation
        (eql, ioc) = generateAssertion4(lhs_var, rhs_var,
          inLhsCref, inRhsCref, inInfo, eql);
        ioc = ioc and inIsOnlyConst;
        (eql, ioc) = generateAssertion3(lhs_rest, rhs_rest,
          inLhsCref, inRhsCref, inInfo, eql, ioc);
      then
        (eql, ioc);

    case ({}, {}, _ ,_, _, _, _) then (inEquations, inIsOnlyConst);

  end match;
end generateAssertion3;

protected function generateAssertion4
  input DAE.Var inLhsVar;
  input DAE.Var inRhsVar;
  input DAE.ComponentRef inLhsCref;
  input DAE.ComponentRef inRhsCref;
  input SourceInfo inInfo;
  input list<Equation> inEquations;
  output list<Equation> outEquations;
  output Boolean outIsOnlyConst;
protected
  Connector lhs_conn, rhs_conn;
algorithm
  lhs_conn := NFConnectUtil2.varToConnector(inLhsVar, inLhsCref, NFConnect2.INSIDE());
  rhs_conn := NFConnectUtil2.varToConnector(inRhsVar, inRhsCref, NFConnect2.INSIDE());
  (outEquations, outIsOnlyConst) := generateAssertion(lhs_conn, rhs_conn,
    inInfo, inEquations);
end generateAssertion4;

annotation(__OpenModelica_Interface="frontend");
end NFConnectEquations;
