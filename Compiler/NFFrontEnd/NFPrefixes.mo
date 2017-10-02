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

type Variability = enumeration(
  CONSTANT,
  PARAMETER,
  DISCRETE,
  CONTINUOUS
);

function variabilityFromSCode
  input SCode.Variability scodeVar;
  output Variability var;
algorithm
  var := match scodeVar
    case SCode.CONST() then Variability.CONSTANT;
    case SCode.PARAM() then Variability.PARAMETER;
    case SCode.DISCRETE() then Variability.DISCRETE;
    case SCode.VAR() then Variability.CONTINUOUS;
  end match;
end variabilityFromSCode;

function variabilityToDAE
  input Variability var;
  output DAE.VarKind varKind;
algorithm
  varKind := match var
    case Variability.CONSTANT then DAE.VarKind.CONST();
    case Variability.PARAMETER then DAE.VarKind.PARAM();
    case Variability.DISCRETE then DAE.VarKind.DISCRETE();
    case Variability.CONTINUOUS then DAE.VarKind.VARIABLE();
  end match;
end variabilityToDAE;

function variabilityString
  input Variability var;
  output String str;
algorithm
  str := match var
    case Variability.CONSTANT then "constant";
    case Variability.PARAMETER then "parameter";
    case Variability.DISCRETE then "discrete";
    case Variability.CONTINUOUS then "continuous";
  end match;
end variabilityString;

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

annotation(__OpenModelica_Interface="frontend");
end NFPrefixes;
