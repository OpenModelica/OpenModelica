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

encapsulated package NFPrefixes

import DAE;
import NFInstNode.InstNode;
import Type = NFType;

package ConnectorType
  type Type = Integer;

  constant Type NON_CONNECTOR       = 0;
  constant Type POTENTIAL           = intBitLShift(1, 0) "A connector element without a prefix.";
  constant Type FLOW                = intBitLShift(1, 1) "A connector element with flow prefix.";
  constant Type STREAM              = intBitLShift(1, 2) "A connector element with stream prefix.";
  constant Type POTENTIALLY_PRESENT = intBitLShift(1, 3) "An element declared inside an expandable connector.";
  constant Type VIRTUAL             = intBitLShift(1, 4) "A virtual connector used in a connection.";
  constant Type CONNECTOR           = intBitLShift(1, 5) "A non-expandable connector that contains elements.";
  constant Type EXPANDABLE          = intBitLShift(1, 6) "An expandable connector.";

  // flow/stream
  constant Type FLOW_STREAM_MASK = intBitOr(FLOW, STREAM);
  // potential/flow/stream
  constant Type PREFIX_MASK = intBitOr(POTENTIAL, FLOW_STREAM_MASK);
  // Some kind of connector, where anything inside an expandable connector also counts.
  constant Type CONNECTOR_MASK = intBitOr(CONNECTOR, intBitOr(EXPANDABLE, POTENTIALLY_PRESENT));
  // An element in an expandable connector.
  constant Type UNDECLARED_MASK = intBitOr(VIRTUAL, POTENTIALLY_PRESENT);

  function fromSCode
    input SCode.ConnectorType scodeCty;
    output Type cty;
  algorithm
    cty := match scodeCty
      case SCode.ConnectorType.POTENTIAL() then 0;
      case SCode.ConnectorType.FLOW() then FLOW;
      case SCode.ConnectorType.STREAM() then STREAM;
    end match;
  end fromSCode;

  function toDAE
    input Type cty;
    output DAE.ConnectorType dcty;
  algorithm
    if intBitAnd(cty, POTENTIAL) > 0 then
      dcty := DAE.ConnectorType.POTENTIAL();
    elseif intBitAnd(cty, FLOW) > 0 then
      dcty := DAE.ConnectorType.FLOW();
    elseif intBitAnd(cty, STREAM) > 0 then
      dcty := DAE.ConnectorType.STREAM(NONE());
    else
      dcty := DAE.ConnectorType.NON_CONNECTOR();
    end if;
  end toDAE;

  function merge
    input Type outerCty;
    input Type innerCty;
    input InstNode node;
    input Boolean isClass = false;
    output Type cty;
  algorithm
    // If both the outer and the inner has flow or stream, give an error.
    if intBitAnd(outerCty, FLOW_STREAM_MASK) > 0 and intBitAnd(innerCty, FLOW_STREAM_MASK) > 0 then
      printPrefixError(toString(outerCty), toString(innerCty), node);
    end if;

    cty := intBitOr(outerCty, innerCty);
  end merge;

  function isPotential
    input Type cty;
    output Boolean isPotential;
  algorithm
    isPotential := intBitAnd(cty, POTENTIAL) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isPotential;

  function setPotential
    input output Type cty;
  algorithm
    cty := intBitOr(cty, POTENTIAL);
    annotation(__OpenModelica_EarlyInline = true);
  end setPotential;

  function isFlow
    input Type cty;
    output Boolean isFlow;
  algorithm
    isFlow := intBitAnd(cty, FLOW) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isFlow;

  function isStream
    input Type cty;
    output Boolean isStream;
  algorithm
    isStream := intBitAnd(cty, STREAM) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isStream;

  function isFlowOrStream
    input Type cty;
    output Boolean isFlowOrStream;
  algorithm
    isFlowOrStream := intBitAnd(cty, FLOW_STREAM_MASK) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isFlowOrStream;

  function unsetFlowStream
    input output Type cty;
  algorithm
    cty := intBitAnd(cty, intBitNot(FLOW_STREAM_MASK));
    annotation(__OpenModelica_EarlyInline = true);
  end unsetFlowStream;

  function isConnector
    "Returns true if the connector type has the connector bit set, otherwise false."
    input Type cty;
    output Boolean isConnector;
  algorithm
    isConnector := intBitAnd(cty, CONNECTOR) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isConnector;

  function setConnector
    input output Type cty;
  algorithm
    cty := intBitOr(cty, CONNECTOR);
    annotation(__OpenModelica_EarlyInline = true);
  end setConnector;

  function isConnectorType
    "Returns treu if the connector type has the connector, expandable, or
     potentially present bits set, otherwise false."
    input Type cty;
    output Boolean isConnector;
  algorithm
    isConnector := intBitAnd(cty, CONNECTOR_MASK) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isConnectorType;

  function isExpandable
    input Type cty;
    output Boolean isExpandable;
  algorithm
    isExpandable := intBitAnd(cty, EXPANDABLE) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isExpandable;

  function setExpandable
    input output Type cty;
  algorithm
    cty := intBitOr(cty, EXPANDABLE);
    annotation(__OpenModelica_EarlyInline = true);
  end setExpandable;

  function isUndeclared
    "Returns true if the connector type has the potentially present or virtual
     bits set, otherwise false."
    input Type cty;
    output Boolean isExpandableElement;
  algorithm
    isExpandableElement := intBitAnd(cty, UNDECLARED_MASK) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isUndeclared;

  function isVirtual
    input Type cty;
    output Boolean isVirtual;
  algorithm
    isVirtual := intBitAnd(cty, VIRTUAL) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isVirtual;

  function isPotentiallyPresent
    input Type cty;
    output Boolean isPotentiallyPresent;
  algorithm
    isPotentiallyPresent := intBitAnd(cty, POTENTIALLY_PRESENT) > 0;
    annotation(__OpenModelica_EarlyInline = true);
  end isPotentiallyPresent;

  function setPresent
    input output Type cty;
  algorithm
    cty := intBitAnd(cty, intBitNot(POTENTIALLY_PRESENT));
    annotation(__OpenModelica_EarlyInline = true);
  end setPresent;

  function toString
    input Type cty;
    output String str;
  algorithm
    if intBitAnd(cty, FLOW) > 0 then
      str := "flow";
    elseif intBitAnd(cty, STREAM) > 0 then
      str := "stream";
    elseif intBitAnd(cty, EXPANDABLE) > 0 then
      str := "expandable";
    else
      str := "";
    end if;
  end toString;

  function unparse
    input Type cty;
    output String str;
  algorithm
    if intBitAnd(cty, FLOW) > 0 then
      str := "flow ";
    elseif intBitAnd(cty, STREAM) > 0 then
      str := "stream ";
    else
      str := "";
    end if;
  end unparse;

  function toDebugString
    input Type cty;
    output String str;
  protected
    list<String> strl = {};
  algorithm
    if intBitAnd(cty, POTENTIAL) > 0           then strl := "potential" :: strl; end if;
    if intBitAnd(cty, FLOW) > 0                then strl := "flow" :: strl; end if;
    if intBitAnd(cty, STREAM) > 0              then strl := "stream" :: strl; end if;
    if intBitAnd(cty, POTENTIALLY_PRESENT) > 0 then strl := "potentially present" :: strl; end if;
    if intBitAnd(cty, VIRTUAL) > 0             then strl := "virtual" :: strl; end if;
    if intBitAnd(cty, CONNECTOR) > 0           then strl := "connector" :: strl; end if;
    if intBitAnd(cty, EXPANDABLE) > 0          then strl := "expandable" :: strl; end if;

    str := stringDelimitList(strl, " ");
  end toDebugString;
end ConnectorType;

type Parallelism = enumeration(
  NON_PARALLEL,
  GLOBAL,
  LOCAL
);

type Variability = enumeration(
  CONSTANT,
  STRUCTURAL_PARAMETER,
  PARAMETER,
  DISCRETE,
  IMPLICITLY_DISCRETE,
  CONTINUOUS
);

type Direction = enumeration(
  NONE,
  INPUT,
  OUTPUT
);

type InnerOuter = enumeration(
  NOT_INNER_OUTER,
  INNER,
  OUTER,
  INNER_OUTER
);

type Visibility = enumeration(
  PUBLIC,
  PROTECTED
);

uniontype Replaceable
  record REPLACEABLE
    Option<InstNode> constrainingClass;
  end REPLACEABLE;

  record NOT_REPLACEABLE end NOT_REPLACEABLE;
end Replaceable;

function parallelismFromSCode
  input SCode.Parallelism scodePar;
  output Parallelism par;
algorithm
  par := match scodePar
    case SCode.Parallelism.PARGLOBAL() then Parallelism.GLOBAL;
    case SCode.Parallelism.PARLOCAL() then Parallelism.LOCAL;
    case SCode.Parallelism.NON_PARALLEL() then Parallelism.NON_PARALLEL;
  end match;
end parallelismFromSCode;

function parallelismToSCode
  input Parallelism par;
  output SCode.Parallelism scodePar;
algorithm
  scodePar := match par
    case Parallelism.GLOBAL then SCode.Parallelism.PARGLOBAL();
    case Parallelism.LOCAL then SCode.Parallelism.PARLOCAL() ;
    case Parallelism.NON_PARALLEL then SCode.Parallelism.NON_PARALLEL() ;
  end match;
end parallelismToSCode;

function parallelismToDAE
  input Parallelism par;
  output DAE.VarParallelism dpar;
algorithm
  dpar := match par
    case Parallelism.GLOBAL then DAE.VarParallelism.PARGLOBAL();
    case Parallelism.LOCAL then DAE.VarParallelism.PARLOCAL();
    case Parallelism.NON_PARALLEL then DAE.VarParallelism.NON_PARALLEL();
  end match;
end parallelismToDAE;

function parallelismString
  input Parallelism par;
  output String str;
algorithm
   str := match par
    case Parallelism.GLOBAL then "parglobal";
    case Parallelism.LOCAL then "parlocal";
    else "";
  end match;
end parallelismString;

function unparseParallelism
  input Parallelism par;
  output String str;
algorithm
   str := match par
    case Parallelism.GLOBAL then "parglobal ";
    case Parallelism.LOCAL then "parlocal ";
    else "";
  end match;
end unparseParallelism;

function mergeParallelism
  input Parallelism outerPar;
  input Parallelism innerPar;
  input InstNode node;
  output Parallelism par;
algorithm
  if outerPar == Parallelism.NON_PARALLEL then
    par := innerPar;
  elseif innerPar == Parallelism.NON_PARALLEL then
    par := outerPar;
  elseif innerPar == outerPar then
    par := innerPar;
  else
    printPrefixError(parallelismString(outerPar), parallelismString(innerPar), node);
  end if;
end mergeParallelism;

function variabilityFromSCode
  input SCode.Variability scodeVar;
  output Variability var;
algorithm
  var := match scodeVar
    case SCode.Variability.CONST() then Variability.CONSTANT;
    case SCode.Variability.PARAM() then Variability.PARAMETER;
    case SCode.Variability.DISCRETE() then Variability.DISCRETE;
    case SCode.Variability.VAR() then Variability.CONTINUOUS;
  end match;
end variabilityFromSCode;

function variabilityToSCode
  input Variability var;
  output SCode.Variability scodeVar;
algorithm
  scodeVar := match var
    case Variability.CONSTANT then SCode.Variability.CONST();
    case Variability.STRUCTURAL_PARAMETER then SCode.Variability.PARAM();
    case Variability.PARAMETER then SCode.Variability.PARAM();
    case Variability.DISCRETE then SCode.Variability.DISCRETE();
    else SCode.Variability.VAR();
  end match;
end variabilityToSCode;

function variabilityToDAE
  input Variability var;
  output DAE.VarKind varKind;
algorithm
  varKind := match var
    case Variability.CONSTANT then DAE.VarKind.CONST();
    case Variability.STRUCTURAL_PARAMETER then DAE.VarKind.PARAM();
    case Variability.PARAMETER then DAE.VarKind.PARAM();
    case Variability.DISCRETE then DAE.VarKind.DISCRETE();
    else DAE.VarKind.VARIABLE();
  end match;
end variabilityToDAE;

function variabilityToDAEConst
  input Variability var;
  output DAE.Const const;
algorithm
  const := match var
    case Variability.CONSTANT then DAE.Const.C_CONST();
    case Variability.STRUCTURAL_PARAMETER then DAE.Const.C_PARAM();
    case Variability.PARAMETER then DAE.Const.C_PARAM();
    else DAE.Const.C_VAR();
  end match;
end variabilityToDAEConst;

function variabilityString
  input Variability var;
  output String str;
algorithm
  str := match var
    case Variability.CONSTANT then "constant";
    case Variability.STRUCTURAL_PARAMETER then "parameter";
    case Variability.PARAMETER then "parameter";
    case Variability.DISCRETE then "discrete";
    case Variability.IMPLICITLY_DISCRETE then "discrete";
    case Variability.CONTINUOUS then "continuous";
  end match;
end variabilityString;

function unparseVariability
  input Variability var;
  input Type ty;
  output String str;
algorithm
  str := match var
    case Variability.CONSTANT then "constant ";
    case Variability.STRUCTURAL_PARAMETER then "parameter ";
    case Variability.PARAMETER then "parameter ";
    case Variability.DISCRETE then if Type.isDiscrete(ty) then "" else "discrete ";
    else "";
  end match;
end unparseVariability;

function variabilityMax
  input Variability var1;
  input Variability var2;
  output Variability var = if var1 > var2 then var1 else var2;
end variabilityMax;

function variabilityMin
  input Variability var1;
  input Variability var2;
  output Variability var = if var1 > var2 then var2 else var1;
end variabilityMin;

function effectiveVariability
  input Variability inVar;
  output Variability outVar;
algorithm
  if inVar == Variability.STRUCTURAL_PARAMETER then
    outVar := Variability.PARAMETER;
  elseif inVar == Variability.IMPLICITLY_DISCRETE then
    outVar := Variability.DISCRETE;
  else
    outVar := inVar;
  end if;
end effectiveVariability;

function directionFromSCode
  input Absyn.Direction scodeDir;
  output Direction dir;
algorithm
  dir := match scodeDir
    case Absyn.Direction.INPUT() then Direction.INPUT;
    case Absyn.Direction.OUTPUT() then Direction.OUTPUT;
    else Direction.NONE;
  end match;
end directionFromSCode;

function directionToDAE
  input Direction dir;
  output DAE.VarDirection ddir;
algorithm
  ddir := match dir
    case Direction.INPUT then DAE.VarDirection.INPUT();
    case Direction.OUTPUT then DAE.VarDirection.OUTPUT();
    else DAE.VarDirection.BIDIR();
  end match;
end directionToDAE;

function directionToAbsyn
  input Direction dir;
  output Absyn.Direction adir;
algorithm
  adir := match dir
    case Direction.INPUT then Absyn.INPUT();
    case Direction.OUTPUT then Absyn.OUTPUT();
    else Absyn.BIDIR();
  end match;
end directionToAbsyn;

function directionString
  input Direction dir;
  output String str;
algorithm
  str := match dir
    case Direction.INPUT then "input";
    case Direction.OUTPUT then "output";
    else "";
  end match;
end directionString;

function unparseDirection
  input Direction dir;
  output String str;
algorithm
  str := match dir
    case Direction.INPUT then "input ";
    case Direction.OUTPUT then "output ";
    else "";
  end match;
end unparseDirection;

function mergeDirection
  input Direction outerDir;
  input Direction innerDir;
  input InstNode node;
  input Boolean allowSame = false;
  output Direction dir;
algorithm
  if outerDir == Direction.NONE then
    dir := innerDir;
  elseif innerDir == Direction.NONE then
    dir := outerDir;
  elseif allowSame and outerDir == innerDir then
    dir := innerDir;
  else
    printPrefixError(directionString(outerDir), directionString(innerDir), node);
  end if;
end mergeDirection;

function innerOuterFromSCode
  input Absyn.InnerOuter scodeIO;
  output InnerOuter io;
algorithm
  io := match scodeIO
    case Absyn.NOT_INNER_OUTER() then InnerOuter.NOT_INNER_OUTER;
    case Absyn.INNER() then InnerOuter.INNER;
    case Absyn.OUTER() then InnerOuter.OUTER;
    case Absyn.INNER_OUTER() then InnerOuter.INNER_OUTER;
  end match;
end innerOuterFromSCode;

function innerOuterToAbsyn
  input InnerOuter inIO;
  output Absyn.InnerOuter outIO;
algorithm
  outIO := match inIO
    case InnerOuter.NOT_INNER_OUTER then Absyn.NOT_INNER_OUTER();
    case InnerOuter.INNER then Absyn.INNER();
    case InnerOuter.OUTER then Absyn.OUTER();
    case InnerOuter.INNER_OUTER then Absyn.INNER_OUTER();
  end match;
end innerOuterToAbsyn;

function innerOuterString
  input InnerOuter io;
  output String str;
algorithm
  str := match io
    case InnerOuter.INNER then "inner";
    case InnerOuter.OUTER then "outer";
    case InnerOuter.INNER_OUTER then "inner outer";
    else "";
  end match;
end innerOuterString;

function unparseInnerOuter
  input InnerOuter io;
  output String str;
algorithm
  str := match io
    case InnerOuter.INNER then "inner ";
    case InnerOuter.OUTER then "outer ";
    case InnerOuter.INNER_OUTER then "inner outer ";
    else "";
  end match;
end unparseInnerOuter;

function visibilityFromSCode
  input SCode.Visibility scodeVis;
  output Visibility vis;
algorithm
  vis := match scodeVis
    case SCode.Visibility.PUBLIC() then Visibility.PUBLIC;
    else Visibility.PROTECTED;
  end match;
end visibilityFromSCode;

function visibilityToDAE
  input Visibility vis;
  output DAE.VarVisibility dvis = if vis == Visibility.PUBLIC then
    DAE.VarVisibility.PUBLIC() else DAE.VarVisibility.PROTECTED();
end visibilityToDAE;

function visibilityToSCode
  input Visibility vis;
  output SCode.Visibility scodeVis = if vis == Visibility.PUBLIC then
    SCode.Visibility.PUBLIC() else SCode.Visibility.PROTECTED();
end visibilityToSCode;

function visibilityString
  input Visibility vis;
  output String str = if vis == Visibility.PUBLIC then "public" else "protected";
end visibilityString;

function unparseVisibility
  input Visibility vis;
  output String str = if vis == Visibility.PROTECTED then "protected " else "";
end unparseVisibility;

function mergeVisibility
  input Visibility outerVis;
  input Visibility innerVis;
  output Visibility vis = if outerVis == Visibility.PROTECTED then outerVis else innerVis;
end mergeVisibility;

function unparseReplaceable
  input Replaceable repl;
  output String str;
algorithm
  str := match repl
    case Replaceable.REPLACEABLE() then "replaceable ";
    else "";
  end match;
end unparseReplaceable;

function printPrefixError
  input String outerPrefix;
  input String innerPrefix;
  input InstNode node;
algorithm
  Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
    {outerPrefix, InstNode.typeName(node), InstNode.name(node), innerPrefix},
    InstNode.info(node));
  fail();
end printPrefixError;

annotation(__OpenModelica_Interface="frontend");
end NFPrefixes;
