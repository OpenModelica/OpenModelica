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

type ConnectorType = enumeration(
  POTENTIAL,
  FLOW,
  STREAM,
  NON_CONNECTOR
);

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

function connectorTypeFromSCode
  input SCode.ConnectorType scodeCty;
  output ConnectorType cty;
algorithm
  cty := match scodeCty
    case SCode.ConnectorType.POTENTIAL() then ConnectorType.POTENTIAL;
    case SCode.ConnectorType.FLOW() then ConnectorType.FLOW;
    case SCode.ConnectorType.STREAM() then ConnectorType.STREAM;
  end match;
end connectorTypeFromSCode;

function connectorTypeToDAE
  input ConnectorType cty;
  output DAE.ConnectorType dcty;
algorithm
  dcty := match cty
    case ConnectorType.POTENTIAL then DAE.ConnectorType.POTENTIAL();
    case ConnectorType.FLOW then DAE.ConnectorType.FLOW();
    case ConnectorType.STREAM then DAE.ConnectorType.STREAM(NONE());
    case ConnectorType.NON_CONNECTOR then DAE.ConnectorType.NON_CONNECTOR();
  end match;
end connectorTypeToDAE;

function connectorTypeString
  input ConnectorType cty;
  output String str;
algorithm
  str := match cty
    case ConnectorType.FLOW then "flow";
    case ConnectorType.STREAM then "stream";
    else "";
  end match;
end connectorTypeString;

function unparseConnectorType
  input ConnectorType cty;
  output String str;
algorithm
  str := match cty
    case ConnectorType.FLOW then "flow ";
    case ConnectorType.STREAM then "stream ";
    else "";
  end match;
end unparseConnectorType;

function mergeConnectorType
  input ConnectorType outerCty;
  input ConnectorType innerCty;
  input InstNode node;
  output ConnectorType cty;
algorithm
  if outerCty == ConnectorType.POTENTIAL then
    cty := innerCty;
  elseif innerCty == ConnectorType.POTENTIAL then
    cty := outerCty;
  else
    printPrefixError(connectorTypeString(outerCty), connectorTypeString(innerCty), node);
  end if;
end mergeConnectorType;

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
