/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
" file:        MMToJuliaUtil.mo
  package:     MMToJuliaUtil
  description: MMToJuliaUtil contains utility functions for Julia translation.
  It makes use of a global hash table indexed with MM_TO_JL_HT_INDEX."

protected
import Absyn;
import AbsynUtil;
import Global;
import MMToJuliaHT;
import MMToJuliaKeywords;
import Util;

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

  record IMPORT_CONTEXT
  end IMPORT_CONTEXT;

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

function makeImportContext
  output Context context;
algorithm
  context := IMPORT_CONTEXT();
end makeImportContext;

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


function simplifyAbsyn
"
Input Absyn.Program
outoyt Absyn.Program

Description:
  This function takes an Absyn.Program and transforms it to an equvivalent Absyn.Program with
  certain MetaModelica simplified.
  Each refactored component is saved in a cache.

  For instance the Uniontype A declared in the following way:

  uniontype A
    function f1 end f1;
    function f2 end f2;
    record r1 end r1;
    record r2 end r2;
  end A;

Is transformed into:

package P_A
  Uniontype A
    record  r1 end r1;
    record r2 end r2;
  end A;
  function f1 end f1;
  function f2 end f2;
end P_A;

The uniontype A is saved in the cache.
Along with the names of the concerned records.

All references to A is rerouted to P_A

If a reference is to a record that is saved in the cache.
That reference is rerouted to P_A.A. This to account for the additional level of redirection.
"

  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
protected
  Absyn.Program tmpProgram;
  MMToJuliaHT.HashTable mmToJuliaHT;
  Boolean visitProtected = true;
algorithm
  MMToJuliaHT.init();
  mmToJuliaHT := getGlobalRoot(Global.MM_TO_JL_HT_INDEX);
  (tmpProgram, NONE(), mmToJuliaHT) := AbsynUtil.traverseClasses(inProgram,
                                                       NONE(),
                                                       refactorUniontypesWithFunctions,
                                                       mmToJuliaHT,
                                                       visitProtected);
  outProgram := tmpProgram;
//  BaseHashTable.dumpHashTable(mmToJuliaHT);
end simplifyAbsyn;

function refactorUniontypesWithFunctions
  input tuple<Absyn.Class, Option<Absyn.Path>, MMToJuliaHT.HashTable> inTpl;
  output tuple<Absyn.Class, Option<Absyn.Path>, MMToJuliaHT.HashTable> outTpl;
protected
  Absyn.Class inClass;
  Absyn.Class newPackage;
  Absyn.ClassDef tmpClassDef;
  Boolean classHasSubClassesOfTypeFunctionOrUniontype = false;
  Boolean isUniontype = false;
  Boolean subClassesOfTypeFunction = false;
  Boolean subClassesOfTypeUniontype = false;
  MMToJuliaHT.HashTable hashTable;
  Option<Absyn.Path> inPath;
  String className;
  list<Absyn.ClassPart> nonRecords = {};
  list<Absyn.ClassPart> records = {};
algorithm
  (inClass, inPath, hashTable) := inTpl;
  isUniontype := AbsynUtil.isUniontype(inClass);
  /* Julia also does not support the concept of having uniontypes within uniontypes */
  subClassesOfTypeUniontype := AbsynUtil.classHasLocalClassesThatAreUniontypes(inClass);
  subClassesOfTypeFunction := AbsynUtil.classHasLocalClassesThatAreFunctions(inClass);
  classHasSubClassesOfTypeFunctionOrUniontype := subClassesOfTypeUniontype
                                              or subClassesOfTypeFunction;
  if not (isUniontype and classHasSubClassesOfTypeFunctionOrUniontype) then
    outTpl := inTpl;
    return;
  end if;
  /* The class is a uniontype and it has functions */
  (records, nonRecords) := AbsynUtil.splitRecordsAndOtherElements(inClass);
  /* Create a new package and surround the record by said package.*/
  className := AbsynUtil.optPathString(SOME(AbsynUtil.className(inClass)));
  try
    () := match inClass.body
      local
        list<Absyn.ClassPart> bodyParts;
        list<String> typeVars;
        list<Absyn.NamedArg> classAttrs;
        list<Absyn.Annotation> ann;
        Option<String>  comment;
        Absyn.ClassPart newClassPart;
      case Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, ann = ann, comment = comment) algorithm
        inClass.body := Absyn.PARTS(typeVars, classAttrs,  records, ann, comment);
        newClassPart := AbsynUtil.makePublicClassPartFromElementItem(AbsynUtil.makeClassElement(inClass));
        tmpClassDef := Absyn.PARTS(typeVars, classAttrs,  newClassPart :: nonRecords, ann, comment);
        then ();
      else fail();
   end match;
   newPackage := Absyn.CLASS("P_" + className,
                            false,
                            false,
                            false,
                            Absyn.R_PACKAGE(),
                            tmpClassDef,
                            sourceInfo());
    MMToJuliaHT.add(className, SOME(MMToJuliaHT.CLASS_INFO(inClass, newPackage)));
    outTpl := (newPackage, NONE(), hashTable);
    return;
  /* Update our hash table with our new package and the uniontype */
 else /* No modification */
   outTpl := inTpl;
 end try;
end refactorUniontypesWithFunctions;

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
      case Absyn.ALGORITHMITEM(algorithm_ = alg) then match alg
        case Absyn.ALG_RETURN(__) then true;
        else false;
        end match;
      else false;
    end match;
  end for;
end algorithmItemsContainsReturn;

function mMKeywordToJLKeyword
"Maps the inName to a Julia comptatible outName.
If there exists no such name. Returns the original string"
  input String inName;
  output String outName;
algorithm
  outName := match inName
    case MMToJuliaKeywords.REAL then "AbstractFloat";
    case MMToJuliaKeywords.BOOLEAN then "Bool";
    case MMToJuliaKeywords.LIST then "List";
    case MMToJuliaKeywords.ARRAY then "Array";
    case MMToJuliaKeywords.TUPLE then "Tuple";
    case MMToJuliaKeywords.POLYMORPHIC then "Any";
    case MMToJuliaKeywords.MUTABLE then "MutableType";
    case MMToJuliaKeywords.TYPE_LC then "M_type";
    case MMToJuliaKeywords.TYPE_UC then "M_Type";
    case MMToJuliaKeywords.FUNCTION_UC then "M_Function";
    case MMToJuliaKeywords.FUNCTION_LC then "M_function";
    case MMToJuliaKeywords.CONST then "M_const";
    else "";
  end match;
end mMKeywordToJLKeyword;

function ifMMKeywordReturnSelf
  input String inName;
  output String outName;
end ifMMKeywordReturnSelf;

annotation(__OpenModelica_Interface="backend");
end MMToJuliaUtil;
