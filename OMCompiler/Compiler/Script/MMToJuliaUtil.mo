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

encapsulated package MMToJuliaUtil
protected
import List;
import Absyn;
import AbsynUtil;
import Util;
import DoubleEndedList;
import Global;


function createGenericTypes
  input String ty;
protected
  DoubleEndedList<String> genericTypes = DoubleEndedList.fromList({});
algorithm
  setGlobalRoot(Global.MMToJLListIndex, SOME(genericTypes));
end createGenericTypes;

function addGenericType
  input String ty;
protected
  DoubleEndedList<String> genericTypes;
algorithm
  genericTypes := getGlobalRoot(Global.MMToJLListIndex);
  DoubleEndedList.push_back(genericTypes, ty);
end addGenericType;

function clearGenericTypes
protected
  DoubleEndedList<String> genericTypes;
algorithm
  genericTypes := getGlobalRoot(Global.MMToJLListIndex);
  {} := DoubleEndedList.toListAndClear(genericTypes);
end clearGenericTypes;

function isGenericType
  input String str;
  output Boolean b = false;
protected
  list<String> tmpLst;
  DoubleEndedList<String> genericTypes;
algorithm
  genericTypes := getGlobalRoot(Global.MMToJLListIndex);
  tmpLst := DoubleEndedList.toListNoCopyNoClear(genericTypes);
  for i in tmpLst loop
    if i == str then
      b := true;
      break;
    end if;
  end for;
  genericTypes := DoubleEndedList.fromList(tmpLst);
end isGenericType;

public
uniontype Context

  record FUNCTION
    String retValsStr "Contains return values";
  end FUNCTION;

  record FUNCTION_RETURN_CONTEXT
    String retValsStr "Contains return values";
    String ty_str "String of the type we are currently operating on";
  end FUNCTION_RETURN_CONTEXT;

  record PACKAGE
  end PACKAGE;

  record UNIONTYPE
    String name;
  end UNIONTYPE;

  record NO_CONTEXT
  end NO_CONTEXT;

  record INPUT_CONTEXT
    String ty_str;
  end INPUT_CONTEXT;

  record MATCH_CONTEXT
    Absyn.Exp inputExp;
  end MATCH_CONTEXT;

end Context;

constant Context packageContext = PACKAGE();
constant Context noContext = NO_CONTEXT();
constant Context functionContext = FUNCTION("");
constant Context returnContext = FUNCTION_RETURN_CONTEXT("","");
constant Context inputContext = INPUT_CONTEXT("");

function makeUniontypeContext
  input String name;
  output Context context;
algorithm
  context := UNIONTYPE(name);
end makeUniontypeContext;

function makeInputContext
  input String ty_str;
  output Context context;
algorithm
  context := INPUT_CONTEXT(ty_str);
end makeInputContext;

function makeFunctionContext
  input String returnValuesStr;
  output Context context;
algorithm
  context := FUNCTION(returnValuesStr);
end makeFunctionContext;

function makeFunctionReturnContext
  input String returnValuesStr;
  input String ty_str;
  output Context context;
algorithm
  context := FUNCTION_RETURN_CONTEXT(returnValuesStr, ty_str);
end makeFunctionReturnContext;

function makeMatchContext
  input Absyn.Exp iExp;
  output Context context;
algorithm
  context := MATCH_CONTEXT(iExp);
end makeMatchContext;

function makeInputDirection
  output Absyn.Direction direction;
algorithm
  direction := Absyn.INPUT();
end makeInputDirection;

function makeOutputDirection
  output Absyn.Direction direction;
algorithm
  direction := Absyn.OUTPUT();
end makeOutputDirection;

function makeInputOutputDirection
  output Absyn.Direction direction;
algorithm
  direction := Absyn.INPUT_OUTPUT();
end makeInputOutputDirection;

function makeBDirection
  output Absyn.Direction direction;
algorithm
  direction := Absyn.BIDIR();
end makeBDirection;

function isFunctionContext
  input Context givenCTX;
  output Boolean isFuncCTX = false;
algorithm
  isFuncCTX := match givenCTX case FUNCTION(__) then true; else false; end match;
end isFunctionContext;

function filterOnDirection
"@author johti17
Returns a list<ElementItem>, where the direction is equal to the supplied direction or input-output direction"
  input list<Absyn.ElementItem> inputs;
  input Absyn.Direction direction;
  output list<Absyn.ElementItem> outputs = {};
protected
  Absyn.Direction ioDirection = makeInputOutputDirection();
  Boolean directionEQ = false;
algorithm
  for i in inputs loop
    directionEQ := AbsynUtil.directionEqual(direction, AbsynUtil.getDirection(i))
      or AbsynUtil.directionEqual(ioDirection, AbsynUtil.getDirection(i));
    if directionEQ then
      outputs := i :: outputs;
    end if;
  end for;
end filterOnDirection;

function elementSpecIsBIDIR
 "@author:johti17"
  input Absyn.ElementSpec spec;
  output Boolean isBidir;
algorithm
  isBidir := match spec
    local Absyn.ElementAttributes attributes;
    case Absyn.COMPONENTS(attributes=attributes) then
      match attributes.direction
        case Absyn.BIDIR() then true;
        else false;
      end match;
    else false;
  end match;
end elementSpecIsBIDIR;

function elementSpecIsOUTPUT
 "@author:johti17"
  input Absyn.ElementSpec spec;
  output Boolean isOutput;
algorithm
  isOutput := match spec
    local Absyn.ElementAttributes attributes;
    case Absyn.COMPONENTS(attributes=attributes) then
      match attributes.direction
        case Absyn.OUTPUT() then true;
        else false;
      end match;
    else false;
  end match;
end elementSpecIsOUTPUT;

function elementSpecIsOUTPUT_OR_BIDIR
 "@author:johti17"
  input Absyn.ElementSpec spec;
  output Boolean isOutput;
algorithm
  isOutput := elementSpecIsOUTPUT(spec) or elementSpecIsBIDIR(spec);
end elementSpecIsOUTPUT_OR_BIDIR;

function explicitReturnInClassPart
  "@author:johti17
   Only works for Algorithms!"
  input list<Absyn.ClassPart> classParts;
  output Boolean existsImplicitReturn;
algorithm
  for cp in classParts loop
    existsImplicitReturn := match cp
      local list<Absyn.AlgorithmItem> contents;
      case Absyn.ALGORITHMS(contents = contents) then algorithmItemsContainsReturn(contents);
      else false;
    end match;
  end for;
end explicitReturnInClassPart;

function algorithmItemsContainsReturn
"@author: johti17"
  input list<Absyn.AlgorithmItem> contents;
  output Boolean existsReturn;
algorithm
  for item in contents loop
    existsReturn := match item
      local Absyn.Algorithm alg;
      case Absyn.ALGORITHMITEM(algorithm_ = alg) then
        match alg
          case Absyn.ALG_RETURN(__) then true;
          else false;
        end match;
      else false;
    end match;
  end for;
end algorithmItemsContainsReturn;

annotation(__OpenModelica_Interface="backend");
end MMToJuliaUtil;
