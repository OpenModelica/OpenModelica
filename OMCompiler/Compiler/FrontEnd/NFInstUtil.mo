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

encapsulated package NFInstUtil
" file:        NFInstUtil.mo
  package:     NFInstUtil
  description: Utility functions for NFInstTypes.


  Utility functions for operating on the types in NFInstTypes.
"

public import DAE;
public import SCode;

function daeToSCodeConnectorType
  input DAE.ConnectorType inConnectorType;
  output SCode.ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case DAE.NON_CONNECTOR() then SCode.POTENTIAL();
    case DAE.POTENTIAL() then SCode.POTENTIAL();
    case DAE.FLOW() then SCode.FLOW();
    case DAE.STREAM() then SCode.STREAM();
  end match;
end daeToSCodeConnectorType;

function daeToSCodeParallelism
  input DAE.VarParallelism inParallelism;
  output SCode.Parallelism outParallelism;
algorithm
  outParallelism := match(inParallelism)
    case DAE.PARGLOBAL() then SCode.PARGLOBAL();
    case DAE.PARLOCAL() then SCode.PARLOCAL();
    case DAE.NON_PARALLEL() then SCode.NON_PARALLEL();
  end match;
end daeToSCodeParallelism;

function daeToSCodeVariability
  input DAE.VarKind inVariability;
  output SCode.Variability outVariability;
algorithm
  outVariability := match(inVariability)
    case DAE.VARIABLE() then SCode.VAR();
    case DAE.DISCRETE() then SCode.DISCRETE();
    case DAE.PARAM() then SCode.PARAM();
    case DAE.CONST() then SCode.CONST();
  end match;
end daeToSCodeVariability;

function daeToAbsynDirection
  input DAE.VarDirection inDirection;
  output Absyn.Direction outDirection;
algorithm
  outDirection := match(inDirection)
    case DAE.BIDIR() then Absyn.BIDIR();
    case DAE.INPUT() then Absyn.INPUT();
    case DAE.OUTPUT() then Absyn.OUTPUT();
  end match;
end daeToAbsynDirection;

function daeToAbsynInnerOuter
  input DAE.VarInnerOuter inInnerOuter;
  output Absyn.InnerOuter outInnerOuter;
algorithm
  outInnerOuter := match(inInnerOuter)
    case DAE.INNER() then Absyn.INNER();
    case DAE.INNER_OUTER() then Absyn.INNER_OUTER();
    case DAE.OUTER() then Absyn.OUTER();
    case DAE.NOT_INNER_OUTER() then Absyn.NOT_INNER_OUTER();
  end match;
end daeToAbsynInnerOuter;

function daeToSCodeVisibility
  input DAE.VarVisibility inVisibility;
  output SCode.Visibility outVisibility;
algorithm
  outVisibility := match(inVisibility)
    case DAE.PUBLIC() then SCode.PUBLIC();
    case DAE.PROTECTED() then SCode.PROTECTED();
  end match;
end daeToSCodeVisibility;

function translateConnectorType
  input SCode.ConnectorType inConnectorType;
  output DAE.ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case SCode.FLOW() then DAE.FLOW();
    case SCode.STREAM() then DAE.STREAM(NONE());
    else DAE.NON_CONNECTOR();
  end match;
end translateConnectorType;

function translateParallelism
  input SCode.Parallelism inParallelism;
  output DAE.VarParallelism outParallelism;
algorithm
  outParallelism := match(inParallelism)
    case SCode.PARGLOBAL() then DAE.PARGLOBAL();
    case SCode.PARLOCAL() then DAE.PARLOCAL();
    case SCode.NON_PARALLEL() then DAE.NON_PARALLEL();
  end match;
end translateParallelism;

function translateVariability
  input SCode.Variability inVariability;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inVariability)
    case SCode.VAR() then DAE.VARIABLE();
    case SCode.PARAM() then DAE.PARAM();
    case SCode.CONST() then DAE.CONST();
    case SCode.DISCRETE() then DAE.DISCRETE();
  end match;
end translateVariability;

function translateDirection
  input Absyn.Direction inDirection;
  output DAE.VarDirection outDirection;
algorithm
  outDirection := match(inDirection)
    case Absyn.BIDIR() then DAE.BIDIR();
    case Absyn.OUTPUT() then DAE.OUTPUT();
    case Absyn.INPUT() then DAE.INPUT();
  end match;
end translateDirection;

function translateInnerOuter
  input Absyn.InnerOuter inInnerOuter;
  output DAE.VarInnerOuter outInnerOuter;
algorithm
  outInnerOuter := match(inInnerOuter)
    case Absyn.INNER() then DAE.INNER();
    case Absyn.INNER_OUTER() then DAE.INNER_OUTER();
    case Absyn.OUTER() then DAE.OUTER();
    case Absyn.NOT_INNER_OUTER() then DAE.NOT_INNER_OUTER();
  end match;
end translateInnerOuter;

function translateVisibility
  input SCode.Visibility inVisibility;
  output DAE.VarVisibility outVisibility;
algorithm
  outVisibility := match(inVisibility)
    case SCode.PUBLIC() then DAE.PUBLIC();
    else DAE.PROTECTED();
  end match;
end translateVisibility;

function toConst
  "Translates SCode.Variability to DAE.Const"
  input SCode.Variability inVar;
  output DAE.Const outConst;
algorithm
  outConst := match inVar
    case SCode.CONST() then DAE.C_CONST();
    case SCode.PARAM() then DAE.C_PARAM();
    else DAE.C_VAR();
  end match;
end toConst;

function variabilityAnd
  "Returns the most variable of two VarKinds."
  input DAE.VarKind var1;
  input DAE.VarKind var2;
  output DAE.VarKind var;
algorithm
  var := match (var1, var2)
    case (DAE.VarKind.VARIABLE(), _) then var1;
    case (_, DAE.VarKind.VARIABLE()) then var2;
    case (DAE.VarKind.DISCRETE(), _) then var1;
    case (_, DAE.VarKind.DISCRETE()) then var2;
    case (DAE.VarKind.PARAM(), _) then var1;
    case (_, DAE.VarKind.PARAM()) then var2;
    else var1;
  end match;
end variabilityAnd;

function variabilityOr
  "Returns the least variable of two VarKinds."
  input DAE.VarKind var1;
  input DAE.VarKind var2;
  output DAE.VarKind var;
algorithm
  var := match (var1, var2)
    case (DAE.VarKind.CONST(), _) then var1;
    case (_, DAE.VarKind.CONST()) then var2;
    case (DAE.VarKind.PARAM(), _) then var1;
    case (_, DAE.VarKind.PARAM()) then var2;
    case (DAE.VarKind.DISCRETE(), _) then var1;
    case (_, DAE.VarKind.DISCRETE()) then var2;
    else var1;
  end match;
end variabilityOr;

function variabilityString
  input DAE.VarKind var;
  output String string;
algorithm
  string := match var
    case DAE.VarKind.CONST() then "constant";
    case DAE.VarKind.PARAM() then "parameter";
    case DAE.VarKind.DISCRETE() then "discrete";
    case DAE.VarKind.VARIABLE() then "continuous";
  end match;
end variabilityString;


annotation(__OpenModelica_Interface="frontend");
end NFInstUtil;
