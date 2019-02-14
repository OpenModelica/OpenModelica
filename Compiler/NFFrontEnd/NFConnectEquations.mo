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
" file:        ConnectEquations.mo
  package:     ConnectEquations
  description: Functions that generate connect equations.

"

public
import Connector = NFConnector;
import DAE;
import ConnectionSets = NFConnectionSets.ConnectionSets;
import Equation = NFEquation;
import CardinalityTable = NFCardinalityTable;

protected
import ComponentReference;
import ComponentRef = NFComponentRef;
import Config;
import ElementSource;
import Expression = NFExpression;
import Face = NFConnector.Face;
import List;
import NFPrefixes.ConnectorType;
import NFPrefixes.Variability;
import Operator = NFOperator;
import Type = NFType;
import NFCall.Call;
import NFBuiltinFuncs;
import NFInstNode.InstNode;
import NFClass.Class;
import NFBinding.Binding;
import NFFunction.Function;
import Global;
import BuiltinCall = NFBuiltinCall;
import ComplexType = NFComplexType;
import ExpandExp = NFExpandExp;

constant Expression EQ_ASSERT_STR =
  Expression.STRING("Connected constants/parameters must be equal");

public
function generateEquations
  input array<list<Connector>> sets;
  output list<Equation> equations = {};
protected
  partial function potFunc
    input list<Connector> elements;
    output list<Equation> equations;
  end potFunc;

  list<Equation> set_eql;
  potFunc potfunc;
  Expression flowThreshold;
algorithm
  setGlobalRoot(Global.isInStream, NONE());

  //potfunc := if Config.orderConnections() then
  //  generatePotentialEquationsOrdered else generatePotentialEquations;
  potfunc := generatePotentialEquations;
  flowThreshold := Expression.REAL(Flags.getConfigReal(Flags.FLOW_THRESHOLD));

  for set in sets loop
    set_eql := match getSetType(set)
      case ConnectorType.POTENTIAL then potfunc(set);
      case ConnectorType.FLOW then generateFlowEquations(set);
      case ConnectorType.STREAM then generateStreamEquations(set, flowThreshold);
      else
        algorithm
          Error.addInternalError("Invalid connector type on set "
            + List.toString(set, Connector.toString, "", "{", ", ", "}", true), sourceInfo());
        then
          fail();
    end match;

    equations := listAppend(set_eql, equations);
  end for;
end generateEquations;

function evaluateOperators
  input Expression exp;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input CardinalityTable.Table ctable;
  output Expression evalExp;
algorithm
  evalExp := match exp
    local
      Call call;
      Boolean expanded;

    case Expression.CALL(call = call)
      then match call
        case Call.TYPED_CALL()
          then match Function.name(call.fn)
            case Absyn.IDENT("inStream")
              then evaluateInStream(Expression.toCref(listHead(call.arguments)), sets, setsArray, ctable);
            case Absyn.IDENT("actualStream")
              then evaluateActualStream(Expression.toCref(listHead(call.arguments)), sets, setsArray, ctable);
            case Absyn.IDENT("cardinality")
              then CardinalityTable.evaluateCardinality(listHead(call.arguments), ctable);
            else Expression.mapShallow(exp,
              function evaluateOperators(sets = sets, setsArray = setsArray, ctable = ctable));
          end match;

        // inStream/actualStream can't handle non-literal subscripts, so reductions and array
        // constructors containing such calls needs to expanded to get rid of the iterators.
        case Call.TYPED_REDUCTION()
          guard Expression.contains(call.exp, isStreamCall)
          then evaluateOperatorIteratorExp(exp, sets, setsArray, ctable);

        case Call.TYPED_ARRAY_CONSTRUCTOR()
          guard Expression.contains(call.exp, isStreamCall)
          then evaluateOperatorIteratorExp(exp, sets, setsArray, ctable);

        else Expression.mapShallow(exp,
          function evaluateOperators(sets = sets, setsArray = setsArray, ctable = ctable));
      end match;

    else Expression.mapShallow(exp,
      function evaluateOperators(sets = sets, setsArray = setsArray, ctable = ctable));
  end match;
end evaluateOperators;

protected
function getSetType
  input list<Connector> set;
  output ConnectorType cty;
algorithm
  // All connectors in a set should have the same type, so pick the first.
  Connector.CONNECTOR(cty = cty) :: _ := set;
end getSetType;

function generatePotentialEquations
  "Generating the equations for a set of potential variables means equating all
   the components. For n components, this will give n-1 equations. For example,
   if the set contains the components X, Y.A and Z.B, the equations generated
   will be X = Y.A and X = Z.B."
  input list<Connector> elements;
  output list<Equation> equations;
protected
  Connector c1;
algorithm
  c1 := listHead(elements);

  if Connector.variability(c1) > Variability.PARAMETER then
    equations := list(makeEqualityEquation(c1.name, c1.source, c2.name, c2.source)
      for c2 in listRest(elements));
  else
    equations := list(makeEqualityAssert(c1.name, c1.source, c2.name, c2.source)
      for c2 in listRest(elements));
  end if;
end generatePotentialEquations;

//function generatePotentialEquationsOrdered
//  "Like generatePotentialEquations, but orders the connectors with
//   shouldFlipPotentialEquation."
//  input list<Connector> elements;
//  output list<Equation> equations = {};
//protected
//  partial function eqFunc
//    input ComponentRef lhsCref;
//    input DAE.ElementSource lhsSource;
//    input ComponentRef rhsCref;
//    input DAE.ElementSource rhsSource;
//    output Equation eq;
//  end eqFunc;
//
//  Connector c1;
//  ComponentRef cr1, cr2;
//  DAE.ElementSource source;
//  eqFunc eqfunc;
//algorithm
//  if listEmpty(elements) then
//    return;
//  end if;
//
//  c1 := listHead(elements);
//  eqfunc := if Connector.variability(c1) > Variability.PARAMETER then
//    makeEqualityEquation else makeEqualityAssert;
//
//  cr1 := c1.name;
//
//  for c2 in listRest(elements) loop
//    cr2 := c2.name;
//    (cr1, cr2) := Util.swap(shouldFlipPotentialEquation(cr1, c1.source), cr1, cr2);
//    equations := eqfunc(cr1, c2.source, cr2, c2.source) :: equations;
//    c1 := c2;
//    cr1 := cr2;
//  end for;
//end generatePotentialEquationsOrdered;

function makeEqualityEquation
  input ComponentRef lhsCref;
  input DAE.ElementSource lhsSource;
  input ComponentRef rhsCref;
  input DAE.ElementSource rhsSource;
  output Equation equalityEq;
protected
  DAE.ElementSource source;
algorithm
  source := ElementSource.mergeSources(lhsSource, rhsSource);
  //source := ElementSource.addElementSourceConnect(source, (lhsCref, rhsCref));
  equalityEq := Equation.CREF_EQUALITY(lhsCref, rhsCref, source);
end makeEqualityEquation;

function makeEqualityAssert
  input ComponentRef lhsCref;
  input DAE.ElementSource lhsSource;
  input ComponentRef rhsCref;
  input DAE.ElementSource rhsSource;
  output Equation equalityAssert;
protected
  DAE.ElementSource source;
  Expression lhs_exp, rhs_exp, exp;
  Type ty;
algorithm
  source := ElementSource.mergeSources(lhsSource, rhsSource);
  //source := ElementSource.addElementSourceConnect(source, (lhsCref, rhsCref));

  ty := ComponentRef.getComponentType(lhsCref);
  lhs_exp := Expression.fromCref(lhsCref);
  rhs_exp := Expression.fromCref(rhsCref);

  if Type.isReal(ty) then
    // Modelica doesn't allow == for Reals, so to keep the flat Modelica
    // somewhat valid we use 'abs(lhs - rhs) <= 0' instead.
    exp := Expression.BINARY(lhs_exp, Operator.makeSub(ty), rhs_exp);
    exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.ABS_REAL, {exp}, Expression.variability(exp)));
    exp := Expression.RELATION(exp, Operator.makeLessEq(ty), Expression.REAL(0.0));
  else
    // For any other type, generate assertion for 'lhs == rhs'.
    exp := Expression.RELATION(lhs_exp, Operator.makeEqual(ty), rhs_exp);
  end if;

  equalityAssert := Equation.ASSERT(exp, EQ_ASSERT_STR, NFBuiltin.ASSERTIONLEVEL_ERROR, source);
end makeEqualityAssert;

//protected function shouldFlipPotentialEquation
//  "If the flag +orderConnections=false is used, then we should keep the order of
//   the connector elements as they occur in the connection (if possible). In that
//   case we check if the cref of the first argument to the first connection
//   stored in the element source is a prefix of the connector element cref. If
//   it isn't, indicate that we should flip the generated equation."
//  input DAE.ComponentRef lhsCref;
//  input DAE.ElementSource lhsSource;
//  output Boolean shouldFlip;
//algorithm
//  shouldFlip := match lhsSource
//    local
//      DAE.ComponentRef lhs;
//
//    case DAE.SOURCE(connectEquationOptLst = (lhs, _) :: _)
//      then not ComponentReference.crefPrefixOf(lhs, lhsCref);
//
//    else false;
//  end match;
//end shouldFlipPotentialEquation;

function generateFlowEquations
  input list<Connector> elements;
  output list<Equation> equations;
protected
  Connector c;
  list<Connector> c_rest;
  DAE.ElementSource src;
  Expression sum;
algorithm
  c :: c_rest := elements;
  src := c.source;

  if listEmpty(c_rest) then
    sum := Expression.fromCref(c.name);
  else
    sum := makeFlowExp(c);

    for e in c_rest loop
      sum := Expression.BINARY(sum, Operator.makeAdd(Type.REAL()), makeFlowExp(e));
      src := ElementSource.mergeSources(src, e.source);
    end for;
  end if;

  equations := {Equation.EQUALITY(sum, Expression.REAL(0.0), c.ty, src)};
end generateFlowEquations;

function makeFlowExp
  "Creates an expression from a connector element, which is the element itself
   if it's an inside connector, or the element negated if it's outside."
  input Connector element;
  output Expression exp;
protected
  Face face;
algorithm
  exp := Expression.fromCref(element.name);

  // TODO: Remove unnecessary variable 'face' once #4502 is fixed.
  face := element.face;
  if face == Face.OUTSIDE then
    exp := Expression.UNARY(Operator.makeUMinus(Type.REAL()), exp);
  end if;
end makeFlowExp;

function generateStreamEquations
  "Generates the equations for a stream connection set."
  input list<Connector> elements;
  input Expression flowThreshold;
  output list<Equation> equations;
algorithm
  equations := match elements
    local
      ComponentRef cr1, cr2;
      DAE.ElementSource src, src1, src2;
      Expression cref1, cref2, e1, e2;
      list<Connector> inside, outside;
      Variability var1, var2;

    // Unconnected stream connector, do nothing.
    case ({Connector.CONNECTOR(face = Face.INSIDE)}) then {};

    // Both inside, do nothing.
    case ({Connector.CONNECTOR(face = Face.INSIDE),
           Connector.CONNECTOR(face = Face.INSIDE)}) then {};

    // Both outside:
    // cr1 = inStream(cr2);
    // cr2 = inStream(cr1);
    case ({Connector.CONNECTOR(name = cr1, face = Face.OUTSIDE, source = src1),
           Connector.CONNECTOR(name = cr2, face = Face.OUTSIDE, source = src2)})
      algorithm
        cref1 := Expression.fromCref(cr1);
        cref2 := Expression.fromCref(cr2);
        e1 := makeInStreamCall(cref2);
        e2 := makeInStreamCall(cref1);
        src := ElementSource.mergeSources(src1, src2);
      then
        {Equation.EQUALITY(cref1, e1, Type.REAL(), src),
         Equation.EQUALITY(cref2, e2, Type.REAL(), src)};

    // One inside, one outside:
    // cr1 = cr2;
    case ({Connector.CONNECTOR(name = cr1, source = src1),
           Connector.CONNECTOR(name = cr2, source = src2)})
      algorithm
        src := ElementSource.mergeSources(src1, src2);
      then
        {Equation.CREF_EQUALITY(cr1, cr2, src)};

    // The general case with N inside connectors and M outside:
    else
      algorithm
        (outside, inside) := List.splitOnTrue(elements, Connector.isOutside);
      then
        streamEquationGeneral(outside, inside, flowThreshold);

  end match;
end generateStreamEquations;

function streamEquationGeneral
  "Generates an equation for an outside stream connector element."
  input list<Connector> outsideElements;
  input list<Connector> insideElements;
  input Expression flowThreshold;
  output list<Equation> equations = {};
protected
  list<Connector> outside = outsideElements;
  Expression cref_exp, res;
  DAE.ElementSource src;
algorithm
  for e in outsideElements loop
    cref_exp := Expression.fromCref(e.name);
    outside := removeStreamSetElement(e.name, outsideElements);
    res := streamSumEquationExp(outside, insideElements, flowThreshold);
    src := ElementSource.addAdditionalComment(e.source, " equation generated from stream connection");
    equations := Equation.EQUALITY(cref_exp, res, Type.REAL(), src) :: equations;
  end for;
end streamEquationGeneral;

function streamSumEquationExp
  "Generates the sum expression used by stream connector equations, given M
  outside connectors and N inside connectors:

    (sum(max(-flow_exp[i], eps) * stream_exp[i] for i in N) +
     sum(max( flow_exp[i], eps) * inStream(stream_exp[i]) for i in M)) /
    (sum(max(-flow_exp[i], eps) for i in N) +
     sum(max( flow_exp[i], eps) for i in M))

  where eps = inFlowThreshold.
  "
  input list<Connector> outsideElements;
  input list<Connector> insideElements;
  input Expression flowThreshold;
  output Expression sumExp;
protected
  Expression outside_sum1, outside_sum2, inside_sum1, inside_sum2, res;
algorithm
  if listEmpty(outsideElements) then
    // No outside components.
    inside_sum1 := sumMap(insideElements, sumInside1, flowThreshold);
    inside_sum2 := sumMap(insideElements, sumInside2, flowThreshold);
    sumExp := Expression.BINARY(inside_sum1, Operator.makeDiv(Type.REAL()), inside_sum2);
  elseif listEmpty(insideElements) then
    // No inside components.
    outside_sum1 := sumMap(outsideElements, sumOutside1, flowThreshold);
    outside_sum2 := sumMap(outsideElements, sumOutside2, flowThreshold);
    sumExp := Expression.BINARY(outside_sum1, Operator.makeDiv(Type.REAL()), outside_sum2);
  else
    // Both outside and inside components.
    outside_sum1 := sumMap(outsideElements, sumOutside1, flowThreshold);
    outside_sum2 := sumMap(outsideElements, sumOutside2, flowThreshold);
    inside_sum1 := sumMap(insideElements, sumInside1, flowThreshold);
    inside_sum2 := sumMap(insideElements, sumInside2, flowThreshold);
    sumExp := Expression.BINARY(
      Expression.BINARY(outside_sum1, Operator.makeAdd(Type.REAL()), inside_sum1),
      Operator.makeDiv(Type.REAL()),
      Expression.BINARY(outside_sum2, Operator.makeAdd(Type.REAL()), inside_sum2));
  end if;
end streamSumEquationExp;

function sumMap
  "Creates a sum expression by applying the given function on the list of
  elements and summing up the resulting expressions."
  input list<Connector> elements;
  input FuncType func;
  input Expression flowThreshold;
  output Expression exp;

  partial function FuncType
    input Connector element;
    input Expression flowThreshold;
    output Expression exp;
  end FuncType;
algorithm
  exp := func(listHead(elements), flowThreshold);
  for e in listRest(elements) loop
    exp := Expression.BINARY(func(e, flowThreshold), Operator.makeAdd(Type.REAL()), exp);
  end for;
end sumMap;

function streamFlowExp
  "Returns the stream and flow component in a stream set element as expressions."
  input Connector element;
  output Expression streamExp;
  output Expression flowExp;
protected
  ComponentRef stream_cr;
algorithm
  stream_cr := Connector.name(element);
  streamExp := Expression.fromCref(stream_cr);
  flowExp := Expression.fromCref(associatedFlowCref(stream_cr));
end streamFlowExp;

function flowExp
  "Returns the flow component in a stream set element as an expression."
  input Connector element;
  output Expression flowExp;
protected
  ComponentRef flow_cr;
algorithm
  flow_cr := associatedFlowCref(Connector.name(element));
  flowExp := Expression.fromCref(flow_cr);
end flowExp;

function sumOutside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps) * inStream(stream_exp)
   given a stream set element."
  input Connector element;
  input Expression flowThreshold;
  output Expression exp;
protected
  Expression stream_exp, flow_exp;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(element);
  exp := Expression.BINARY(makePositiveMaxCall(flow_exp, element, flowThreshold),
    Operator.makeMul(Type.REAL()), makeInStreamCall(stream_exp));
end sumOutside1;

function sumInside1
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps) * stream_exp
   given a stream set element."
  input Connector element;
  input Expression flowThreshold;
  output Expression exp;
protected
  Expression stream_exp, flow_exp, flow_threshold;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(element);
  flow_exp := Expression.UNARY(Operator.makeUMinus(Type.REAL()), flow_exp);
  exp := Expression.BINARY(makePositiveMaxCall(flow_exp, element, flowThreshold),
    Operator.makeMul(Type.REAL()), stream_exp);
end sumInside1;

function sumOutside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(flow_exp, eps)
   given a stream set element."
  input Connector element;
  input Expression flowThreshold;
  output Expression exp;
protected
  Expression flow_exp;
algorithm
  flow_exp := flowExp(element);
  exp := makePositiveMaxCall(flow_exp, element, flowThreshold);
end sumOutside2;

function sumInside2
  "Helper function to streamSumEquationExp. Returns the expression
    max(-flow_exp, eps)
   given a stream set element."
  input Connector element;
  input Expression flowThreshold;
  output Expression exp;
protected
  Expression flow_exp;
algorithm
  flow_exp := flowExp(element);
  flow_exp := Expression.UNARY(Operator.makeUMinus(Type.REAL()), flow_exp);
  exp := makePositiveMaxCall(flow_exp, element, flowThreshold);
end sumInside2;

function makeInStreamCall
  "Creates an inStream call expression."
  input Expression streamExp;
  output Expression inStreamCall;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  inStreamCall := Expression.CALL(Call.makeTypedCall(
    NFBuiltinFuncs.IN_STREAM, {streamExp}, Expression.variability(streamExp)));
end makeInStreamCall;

function makePositiveMaxCall
  "Generates a max(flow_exp, eps) call."
  input Expression flowExp;
  input Connector element;
  input Expression flowThreshold;
  output Expression positiveMaxCall;
protected
  InstNode flow_node;
  Option<Expression> nominal_oexp;
  Expression nominal_exp, flow_threshold;
algorithm
  flow_node := ComponentRef.node(associatedFlowCref(Connector.name(element)));
  nominal_oexp := Class.lookupAttributeValue("nominal", InstNode.getClass(flow_node));

  if isSome(nominal_oexp) then
    SOME(nominal_exp) := nominal_oexp;
    flow_threshold := Expression.BINARY(flowThreshold, Operator.makeMul(Type.REAL()), nominal_exp);
  else
    flow_threshold := flowThreshold;
  end if;

  positiveMaxCall := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.POSITIVE_MAX_REAL,
    {flowExp, flow_threshold}, Connector.variability(element)));

  setGlobalRoot(Global.isInStream, SOME(true));
end makePositiveMaxCall;

function isStreamCall
  input Expression exp;
  output Boolean streamCall;
algorithm
  streamCall := match exp
    local
      String name;

    case Expression.CALL()
      then match Function.name(Call.typedFunction(exp.call))
        case Absyn.IDENT("inStream") then true;
        case Absyn.IDENT("actualStream") then true;
        else false;
      end match;

    else false;
  end match;
end isStreamCall;

function evaluateOperatorIteratorExp
  input Expression exp;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input CardinalityTable.Table ctable;
  output Expression evalExp;
protected
  Boolean expanded;
algorithm
  (evalExp, expanded) := ExpandExp.expand(exp);

  if not expanded then
    Error.addInternalError(getInstanceName() +
      " failed to expand call containing stream operator: " +
      Expression.toString(exp), sourceInfo());
  end if;

  evalExp := evaluateOperators(evalExp, sets, setsArray, ctable);
end evaluateOperatorIteratorExp;

function evaluateInStream
  "Evaluates the inStream operator with the given cref as argument."
  input ComponentRef cref;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input CardinalityTable.Table ctable;
  output Expression exp;
protected
  Connector c;
  list<Connector> sl;
  Integer set;
algorithm
  c := Connector.CONNECTOR(cref, Type.UNKNOWN(), Face.INSIDE,
    ConnectorType.STREAM, DAE.emptyElementSource);

  try
    set := ConnectionSets.findSetArrayIndex(c, sets);
    sl := arrayGet(setsArray, set);
  else
    sl := {c};
  end try;

  exp := generateInStreamExp(cref, sl, sets, setsArray, ctable,
    Flags.getConfigReal(Flags.FLOW_THRESHOLD));
end evaluateInStream;

function generateInStreamExp
  "Helper function to evaluateInStream. Generates an expression for inStream
   given a connection set."
  input ComponentRef streamCref;
  input list<Connector> streams;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input CardinalityTable.Table ctable;
  input Real flowThreshold;
  output Expression exp;
protected
  list<Connector> reducedStreams, inside, outside;
  ComponentRef cr;
  Face f1, f2;
algorithm
  reducedStreams := list(s for s guard not isZeroFlowMinMax(s, streamCref) in streams);

  exp := match reducedStreams
    // Unconnected stream connector:
    //   inStream(c) = c;
    case {Connector.CONNECTOR(face = Face.INSIDE)}
      then Expression.fromCref(streamCref);

    // Two inside connected stream connectors:
    //   inStream(c1) = c2;
    //   inStream(c2) = c1;
    case {Connector.CONNECTOR(face = Face.INSIDE),
          Connector.CONNECTOR(face = Face.INSIDE)}
      algorithm
        {Connector.CONNECTOR(name = cr)} :=
          removeStreamSetElement(streamCref, reducedStreams);
      then
        Expression.fromCref(cr);

    // One inside, one outside connected stream connector:
    //   inStream(c1) = inStream(c2);
    case {Connector.CONNECTOR(face = f1),
          Connector.CONNECTOR(face = f2)} guard f1 <> f2
      algorithm
        {Connector.CONNECTOR(name = cr)} :=
          removeStreamSetElement(streamCref, reducedStreams);
      then
        evaluateInStream(cr, sets, setsArray, ctable);

    // The general case:
    else
      algorithm
        (outside, inside) := List.splitOnTrue(reducedStreams, Connector.isOutside);
        inside := removeStreamSetElement(streamCref, inside);
        exp := streamSumEquationExp(outside, inside, Expression.REAL(flowThreshold));
        // Evaluate any inStream calls that were generated.
        exp := evaluateOperators(exp, sets, setsArray, ctable);
      then
        exp;

  end match;
end generateInStreamExp;

function isZeroFlowMinMax
  "Returns true if the given flow attribute of a connector is zero."
  input Connector conn;
  input ComponentRef streamCref;
  output Boolean isZero;
algorithm
  if ComponentRef.isEqual(streamCref, conn.name) then
    isZero := false;
  elseif Connector.isOutside(conn) then
    isZero := isZeroFlow(conn, "max");
  else
    isZero := isZeroFlow(conn, "min");
  end if;
end isZeroFlowMinMax;

function isZeroFlow
  "Returns true if the given flow attribute of a connector is zero."
  input Connector element;
  input String attr;
  output Boolean isZero;
protected
  Option<Expression> attr_oexp;
  Expression flow_exp, attr_exp;
  InstNode flow_node;
algorithm
  flow_exp := flowExp(element);
  flow_node := ComponentRef.node(Expression.toCref(flow_exp));
  attr_oexp := Class.lookupAttributeValue(attr, InstNode.getClass(flow_node));

  if isSome(attr_oexp) then
    SOME(attr_exp) := attr_oexp;
    isZero := Expression.isZero(attr_exp);
  else
    isZero := false;
  end if;
end isZeroFlow;

protected function evaluateActualStream
  "This function evaluates the actualStream operator for a component reference,
   given the connection sets."
  input ComponentRef streamCref;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input CardinalityTable.Table ctable;
  output Expression exp;
protected
  ComponentRef flow_cr;
  Integer flow_dir;
  Expression rel_exp, flow_exp, stream_exp, instream_exp;
  Operator op;
algorithm
  flow_cr := associatedFlowCref(streamCref);
  flow_dir := evaluateFlowDirection(flow_cr);

  // Select a branch if we know the flow direction, otherwise generate the whole
  // if-equation.
  if flow_dir == 1 then
    rel_exp := evaluateInStream(streamCref, sets, setsArray, ctable);
  elseif flow_dir == -1 then
    rel_exp := Expression.fromCref(streamCref);
  else
    flow_exp := Expression.fromCref(flow_cr);
    stream_exp := Expression.fromCref(streamCref);
    instream_exp := evaluateInStream(streamCref, sets, setsArray, ctable);
    op := Operator.makeGreater(ComponentRef.nodeType(flow_cr));
    rel_exp := Expression.IF(
      Expression.RELATION(flow_exp, op, Expression.REAL(0.0)),
      instream_exp, stream_exp);
  end if;

  // actualStream(stream_var) = smooth(0, if flow_var > 0 then inStream(stream_var)
  //                                                      else stream_var);
  exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.SMOOTH,
    {DAE.INTEGER(0), rel_exp}, Expression.variability(rel_exp)));
end evaluateActualStream;

function evaluateFlowDirection
  input ComponentRef flowCref;
  output Integer direction = 0;
protected
  Class flow_cls;
  Option<Expression> omin, omax;
  Real min_val, max_val;
algorithm
  flow_cls := InstNode.getClass(ComponentRef.node(flowCref));
  omin := Class.lookupAttributeValue("min", flow_cls);
  omax := Class.lookupAttributeValue("max", flow_cls);

  direction := match (omin, omax)
    // No attributes, flow direction can't be decided.
    case (NONE(), NONE()) then 0;
    // Flow is positive if min is positive.
    case (SOME(Expression.REAL(min_val)), NONE())
      then if min_val >= 0 then 1 else 0;
    // Flow is negative if max is negative.
    case (NONE(), SOME(Expression.REAL(max_val)))
      then if max_val <= 0 then -1 else 0;
    // Flow is positive if both min and max are positive, negative if they are
    // both negative, otherwise undecideable.
    case (SOME(Expression.REAL(min_val)), SOME(Expression.REAL(max_val)))
      then
        if min_val >= 0 and max_val >= min_val then 1
        elseif max_val <= 0 and min_val <= max_val then -1
        else 0;
    // Flow is undecideable if either attribute is not a constant Real value.
    else 0;
  end match;
end evaluateFlowDirection;

protected function removeStreamSetElement
  "This function removes the given cref from a connection set."
  input ComponentRef cref;
  input output list<Connector> elements;
algorithm
  elements := List.deleteMemberOnTrue(cref, elements, compareCrefStreamSet);
end removeStreamSetElement;

protected function compareCrefStreamSet
  "Helper function to removeStreamSetElement. Checks if the cref in a stream set
  element matches the given cref."
  input ComponentRef cref;
  input Connector element;
  output Boolean matches;
algorithm
  matches := ComponentRef.isEqual(cref, element.name);
end compareCrefStreamSet;

function associatedFlowCref
  "Returns the flow cref that's declared in the same connector as the given
   stream cref."
  input ComponentRef streamCref;
  output ComponentRef flowCref;
protected
  Type ty;
  ComponentRef rest_cr;
  InstNode flow_node;
algorithm
  ComponentRef.CREF(ty = ty, restCref = rest_cr) := streamCref;

  flowCref := match Type.arrayElementType(ty)
    // A connector with a single flow, append the flow node to the cref and return it.
    case Type.COMPLEX(complexTy = ComplexType.CONNECTOR(flows = {flow_node}))
      then ComponentRef.prefixCref(flow_node, InstNode.getType(flow_node), {}, streamCref);

    // Otherwise, remove the first part of the cref and try again.
    else associatedFlowCref(rest_cr);
  end match;
end associatedFlowCref;

annotation(__OpenModelica_Interface="frontend");
end NFConnectEquations;
