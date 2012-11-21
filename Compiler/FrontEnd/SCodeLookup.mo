/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SCodeLookup
" file:        SCodeLookup.mo
  package:     SCodeLookup
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import Absyn;
public import DAE;
public import Error;
public import InstTypes;
public import SCode;
public import SCodeEnv;

protected import ComponentReference;
protected import Debug;
protected import EnvExtends;
protected import Flags;
protected import InstUtil;
protected import List;
protected import SCodeCheck;
protected import SCodeFlattenImports;
protected import SCodeFlattenRedeclare;

public type Env = SCodeEnv.Env;
public type Item = SCodeEnv.Item;
public type Extends = SCodeEnv.Extends;
public type Frame = SCodeEnv.Frame;
public type FrameType = SCodeEnv.FrameType;
public type AvlTree = SCodeEnv.AvlTree;
public type Import = Absyn.Import;

public uniontype RedeclareReplaceStrategy
  record INSERT_REDECLARES end INSERT_REDECLARES;
  record IGNORE_REDECLARES end IGNORE_REDECLARES;
end RedeclareReplaceStrategy;

public uniontype LookupStrategy
  record NO_BUILTIN_TYPES end NO_BUILTIN_TYPES;
  record LOOKUP_ANY end LOOKUP_ANY;
end LookupStrategy;

public uniontype Origin
  record INSTANCE_ORIGIN end INSTANCE_ORIGIN;
  record CLASS_ORIGIN end CLASS_ORIGIN;
  record BUILTIN_ORIGIN end BUILTIN_ORIGIN;
end Origin;

// Default parts of the declarations for builtin elements and types.
public constant SCode.Prefixes BUILTIN_PREFIXES = SCode.PREFIXES(
  SCode.PUBLIC(), SCode.NOT_REDECLARE(), SCode.NOT_FINAL(),
  Absyn.NOT_INNER_OUTER(), SCode.NOT_REPLACEABLE());

public constant SCode.Attributes BUILTIN_ATTRIBUTES = SCode.ATTR(
  {}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR());

public constant SCode.Attributes BUILTIN_CONST_ATTRIBUTES = SCode.ATTR(
  {}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR());

public constant SCode.ClassDef BUILTIN_EMPTY_CLASS = SCode.PARTS(
  {}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE());


// Metatypes used to define the builtin types.
public constant SCode.Element BUILTIN_REALTYPE = SCode.CLASS(
  "$RealType", BUILTIN_PREFIXES, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(),
  SCode.R_PREDEFINED_REAL(), BUILTIN_EMPTY_CLASS, Absyn.dummyInfo);

public constant SCode.Element BUILTIN_INTEGERTYPE = SCode.CLASS(
  "$IntegerType", BUILTIN_PREFIXES, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(),
  SCode.R_PREDEFINED_INTEGER(), BUILTIN_EMPTY_CLASS, Absyn.dummyInfo);

public constant SCode.Element BUILTIN_BOOLEANTYPE = SCode.CLASS(
  "$BooleanType", BUILTIN_PREFIXES, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(),
  SCode.R_PREDEFINED_BOOLEAN(), BUILTIN_EMPTY_CLASS, Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STRINGTYPE = SCode.CLASS(
  "$StringType", BUILTIN_PREFIXES, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(),
  SCode.R_PREDEFINED_STRING(), BUILTIN_EMPTY_CLASS, Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ENUMTYPE = SCode.CLASS(
  "$EnumType", BUILTIN_PREFIXES, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(),
  SCode.R_PREDEFINED_ENUMERATION(), BUILTIN_EMPTY_CLASS, Absyn.dummyInfo);

public constant Item BUILTIN_REALTYPE_ITEM = 
  SCodeEnv.VAR(BUILTIN_REALTYPE, NONE());
public constant Item BUILTIN_INTEGERTYPE_ITEM =
  SCodeEnv.VAR(BUILTIN_INTEGERTYPE, NONE());
public constant Item BUILTIN_BOOLEANTYPE_ITEM =
  SCodeEnv.VAR(BUILTIN_BOOLEANTYPE, NONE());
public constant Item BUILTIN_STRINGTYPE_ITEM =
  SCodeEnv.VAR(BUILTIN_STRINGTYPE, NONE());
public constant Item BUILTIN_ENUMTYPE_ITEM =
  SCodeEnv.VAR(BUILTIN_ENUMTYPE, NONE());

public constant Absyn.TypeSpec BUILTIN_REALTYPE_SPEC = 
  Absyn.TPATH(Absyn.IDENT("$RealType"), NONE());
public constant Absyn.TypeSpec BUILTIN_INTEGERTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$IntegerType"), NONE());
public constant Absyn.TypeSpec BUILTIN_BOOLEANTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$BooleanType"), NONE());
public constant Absyn.TypeSpec BUILTIN_STRINGTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$StringType"), NONE());
public constant Absyn.TypeSpec BUILTIN_ENUMTYPE_SPEC =
  Absyn.TPATH(Absyn.IDENT("$EnumType"), NONE());
public constant Absyn.TypeSpec BUILTIN_STATESELECT_SPEC =
  Absyn.TPATH(Absyn.IDENT("StateSelect"), NONE());

// Parts of the builtin types.
// Generic elements:
public constant SCode.Element BUILTIN_ATTR_QUANTITY = SCode.COMPONENT(
  "quantity", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_UNIT = SCode.COMPONENT(
  "unit", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_DISPLAYUNIT = SCode.COMPONENT(
  "displayUnit", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_FIXED = SCode.COMPONENT(
  "fixed", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_BOOLEANTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ATTR_STATESELECT = SCode.COMPONENT(
  "stateSelect", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STATESELECT_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

// Real-specific elements:
public constant SCode.Element BUILTIN_REAL_MIN = SCode.COMPONENT(
  "min", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_REAL_MAX = SCode.COMPONENT(
  "max", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_REAL_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_REAL_NOMINAL = SCode.COMPONENT(
  "nominal", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_REALTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

// Integer-specific elements:
public constant SCode.Element BUILTIN_INTEGER_MIN = SCode.COMPONENT(
  "min", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_INTEGERTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_INTEGER_MAX = SCode.COMPONENT(
  "max", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_INTEGERTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_INTEGER_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_INTEGERTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

// Boolean-specific elements:
public constant SCode.Element BUILTIN_BOOLEAN_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_BOOLEANTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

// String-specific elements:
public constant SCode.Element BUILTIN_STRING_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_STRINGTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

// StateSelect-specific elements:
public constant SCode.Element BUILTIN_ENUM_MIN = SCode.COMPONENT(
  "min", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ENUM_MAX = SCode.COMPONENT(
  "max", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_ENUM_START = SCode.COMPONENT(
  "start", BUILTIN_PREFIXES, BUILTIN_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_NEVER = SCode.COMPONENT(
  "never", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_AVOID = SCode.COMPONENT(
  "avoid", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_DEFAULT = SCode.COMPONENT(
  "default", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_PREFER = SCode.COMPONENT(
  "prefer", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);

public constant SCode.Element BUILTIN_STATESELECT_ALWAYS = SCode.COMPONENT(
  "always", BUILTIN_PREFIXES, BUILTIN_CONST_ATTRIBUTES, BUILTIN_ENUMTYPE_SPEC,
  SCode.NOMOD(), NONE(), NONE(), Absyn.dummyInfo);


// Environments for the builtin types:
public constant Env BUILTIN_REAL_ENV = {SCodeEnv.FRAME(SOME("Real"), 
  SCodeEnv.NORMAL_SCOPE(), 
  SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("nominal", 
      SCodeEnv.VAR(BUILTIN_REAL_NOMINAL, NONE()))), 4, 
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("max",
        SCodeEnv.VAR(BUILTIN_REAL_MAX, NONE()))), 3,
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("fixed",
            SCodeEnv.VAR(BUILTIN_ATTR_FIXED, NONE()))), 2,
              SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("displayUnit",
                SCodeEnv.VAR(BUILTIN_ATTR_DISPLAYUNIT, NONE()))), 1,
                  NONE(), NONE())),
                NONE())),
            SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("min",
              SCodeEnv.VAR(BUILTIN_REAL_MIN, NONE()))), 1,
                NONE(), NONE())))),
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("start",
        SCodeEnv.VAR(BUILTIN_REAL_START, NONE()))), 3,
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("quantity",
            SCodeEnv.VAR(BUILTIN_ATTR_QUANTITY, NONE()))), 1,
              NONE(), NONE())),
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("stateSelect",
            SCodeEnv.VAR(BUILTIN_ATTR_STATESELECT, NONE()))), 2,
              NONE(),
              SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("unit",
                SCodeEnv.VAR(BUILTIN_ATTR_UNIT, NONE()))), 1,
                  NONE(), NONE()))))))),
  SCodeEnv.EXTENDS_TABLE({}, {}, NONE()), SCodeEnv.IMPORT_TABLE(false, {}, {}), NONE())};

public constant Env BUILTIN_INTEGER_ENV = {SCodeEnv.FRAME(SOME("Integer"), 
  SCodeEnv.NORMAL_SCOPE(), 
  SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("quantity", 
      SCodeEnv.VAR(BUILTIN_ATTR_QUANTITY, NONE()))), 3, 
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("max",
        SCodeEnv.VAR(BUILTIN_INTEGER_MAX, NONE()))), 2,
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("fixed",
            SCodeEnv.VAR(BUILTIN_ATTR_FIXED, NONE()))), 1,
              NONE(), NONE())),
            SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("min",
              SCodeEnv.VAR(BUILTIN_INTEGER_MIN, NONE()))), 1,
                NONE(),
                NONE())))),
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("start",
        SCodeEnv.VAR(BUILTIN_INTEGER_START, NONE()))), 1,
          NONE(), NONE()))),
  SCodeEnv.EXTENDS_TABLE({}, {}, NONE()), SCodeEnv.IMPORT_TABLE(false, {}, {}), NONE())};

public constant Env BUILTIN_BOOLEAN_ENV = {SCodeEnv.FRAME(SOME("Boolean"), 
  SCodeEnv.NORMAL_SCOPE(), 
  SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("quantity", 
      SCodeEnv.VAR(BUILTIN_ATTR_QUANTITY, NONE()))), 2, 
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("fixed",
        SCodeEnv.VAR(BUILTIN_ATTR_FIXED, NONE()))), 1,
          NONE(), NONE())),
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("start",
        SCodeEnv.VAR(BUILTIN_BOOLEAN_START, NONE()))), 1,
          NONE(), NONE()))),
  SCodeEnv.EXTENDS_TABLE({}, {}, NONE()), SCodeEnv.IMPORT_TABLE(false, {}, {}), NONE())};

public constant Env BUILTIN_STRING_ENV = {SCodeEnv.FRAME(SOME("String"), 
  SCodeEnv.NORMAL_SCOPE(), 
  SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("quantity", 
      SCodeEnv.VAR(BUILTIN_ATTR_QUANTITY, NONE()))), 2, 
      NONE(),
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("start",
        SCodeEnv.VAR(BUILTIN_STRING_START, NONE()))), 1,
          NONE(), NONE()))),
  SCodeEnv.EXTENDS_TABLE({}, {}, NONE()), SCodeEnv.IMPORT_TABLE(false, {}, {}), NONE())};

public constant Env BUILTIN_STATESELECT_ENV = {SCodeEnv.FRAME(SOME("StateSelect"), 
  SCodeEnv.NORMAL_SCOPE(), 
  SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("max",
    SCodeEnv.VAR(BUILTIN_ENUM_MAX, NONE()))), 4,
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("default",
        SCodeEnv.VAR(BUILTIN_STATESELECT_DEFAULT, NONE()))), 3,
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("avoid",
            SCodeEnv.VAR(BUILTIN_STATESELECT_AVOID, NONE()))), 2,
              SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("always",
                SCodeEnv.VAR(BUILTIN_STATESELECT_ALWAYS, NONE()))), 1,
                  NONE(), NONE())),
              NONE())),
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("fixed",
            SCodeEnv.VAR(BUILTIN_ATTR_FIXED, NONE()))), 1,
              NONE(), NONE())))),
      SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("never",
        SCodeEnv.VAR(BUILTIN_STATESELECT_NEVER, NONE()))), 3,
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("min",
            SCodeEnv.VAR(BUILTIN_ENUM_MIN, NONE()))), 1,
              NONE(), NONE())),
          SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("quantity",
            SCodeEnv.VAR(BUILTIN_ATTR_QUANTITY, NONE()))), 2,
              SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("prefer",
                SCodeEnv.VAR(BUILTIN_STATESELECT_PREFER, NONE()))), 1,
                  NONE(), NONE())),
              SOME(SCodeEnv.AVLTREENODE(SOME(SCodeEnv.AVLTREEVALUE("start",
                SCodeEnv.VAR(BUILTIN_ENUM_START, NONE()))), 1,
                  NONE(), NONE()))))))),
  SCodeEnv.EXTENDS_TABLE({}, {}, NONE()), SCodeEnv.IMPORT_TABLE(false, {}, {}), NONE())};


// The builtin types:
public constant Item BUILTIN_REAL = SCodeEnv.CLASS(
  SCode.CLASS("Real", SCode.defaultPrefixes, 
      SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
      SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()),
      Absyn.dummyInfo), BUILTIN_REAL_ENV, SCodeEnv.BASIC_TYPE());
  
public constant Item BUILTIN_INTEGER = SCodeEnv.CLASS(
  SCode.CLASS("Integer", SCode.defaultPrefixes,
      SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
      SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()),
      Absyn.dummyInfo), BUILTIN_INTEGER_ENV, SCodeEnv.BASIC_TYPE());

public constant Item BUILTIN_BOOLEAN = SCodeEnv.CLASS(
  SCode.CLASS("Boolean", SCode.defaultPrefixes,
      SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
      SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()),
      Absyn.dummyInfo), BUILTIN_BOOLEAN_ENV, SCodeEnv.BASIC_TYPE());

public constant Item BUILTIN_STRING = SCodeEnv.CLASS(
  SCode.CLASS("String", SCode.defaultPrefixes,
      SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
      SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()),
      Absyn.dummyInfo), BUILTIN_STRING_ENV, SCodeEnv.BASIC_TYPE());

public constant Item BUILTIN_STATESELECT = SCodeEnv.CLASS(
  SCode.CLASS("StateSelect",  SCode.defaultPrefixes,
      SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_CLASS(),
      SCode.ENUMERATION({
        SCode.ENUM("never", NONE()),
        SCode.ENUM("avoid", NONE()),
        SCode.ENUM("default", NONE()),
        SCode.ENUM("prefer", NONE()),
        SCode.ENUM("always", NONE())}, NONE()),
      Absyn.dummyInfo), BUILTIN_STATESELECT_ENV, SCodeEnv.BASIC_TYPE());

public constant Item BUILTIN_EXTERNALOBJECT = SCodeEnv.CLASS(
  SCode.CLASS("ExternalObject", SCode.defaultPrefixes,
      SCode.NOT_ENCAPSULATED(), SCode.PARTIAL(), SCode.R_CLASS(),
      SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()),
      Absyn.dummyInfo), SCodeEnv.emptyEnv, SCodeEnv.BASIC_TYPE());

public function lookupSimpleName
  "Looks up a simple identifier in the environment and returns the environment
  item, the path, and the enclosing scope of the name."
  input Absyn.Ident inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (SOME(outItem), SOME(outPath), SOME(outEnv)) := 
    lookupSimpleName2(inName, inEnv, {});
end lookupSimpleName;

protected function lookupSimpleName2
  "Helper function to lookupSimpleName. Looks up a simple identifier in the
  environment."
  input Absyn.Ident inName;
  input Env inEnv;
  input list<String> inVisitedScopes;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inEnv, inVisitedScopes)
    local
      FrameType frame_type;
      Env rest_env;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;
      String scope_name;

    // Check the local scope.
    case (_, _, _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInLocalScope(inName, inEnv, inVisitedScopes);
      then
        (opt_item, opt_path, opt_env);

    // If not found in the local scope, check the next frame unless the current
    // frame is encapsulated.
    case (_, SCodeEnv.FRAME(name = SOME(scope_name), frameType = frame_type) ::
        rest_env, _)
      equation
        frameNotEncapsulated(frame_type);
        (opt_item, opt_path, opt_env) = 
          lookupSimpleName2(inName, rest_env, scope_name :: inVisitedScopes);
      then
        (opt_item, opt_path, opt_env);

    // If the current frame is encapsulated, check for builtin types and
    // functions in the top scope.
    case (_, SCodeEnv.FRAME(frameType = SCodeEnv.ENCAPSULATED_SCOPE()) :: 
        rest_env, _)
      equation
        rest_env = SCodeEnv.getEnvTopScope(rest_env);
        (opt_item, opt_path, opt_env) = lookupSimpleName2(inName, rest_env, {});
        checkBuiltinItem(opt_item);
      then
        (opt_item, opt_path, opt_env);

  end matchcontinue;
end lookupSimpleName2;

public function frameNotEncapsulated
  "Fails if the frame type is encapsulated, otherwise succeeds."
  input FrameType frameType;
algorithm
  _ := match(frameType)
    case SCodeEnv.ENCAPSULATED_SCOPE() then fail();
    else then ();
  end match;
end frameNotEncapsulated;

protected function checkBuiltinItem
  input Option<Item> inItem;
algorithm
  _ := match(inItem)
    local

    case (SOME(SCodeEnv.CLASS(classType = SCodeEnv.BUILTIN()))) then ();
    case (NONE()) then ();
  end match;
end checkBuiltinItem;

public function lookupInLocalScope
  "Looks up a simple identifier in the environment. Returns SOME(item) if an
  item is found, NONE() if a partial match was found (for example when the name
  matches the import name of an import, but the imported class couldn't be
  found), or fails if no match is found."
  input Absyn.Ident inName;
  input Env inEnv;
  input list<String> inVisitedScopes;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inEnv, inVisitedScopes)
    local
      Env rest_env, env;
      Item item;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      list<Import> imps;
      Absyn.Path path;
      Option<Env> opt_env;

    // Look among the locally declared components.
    case (_, _, _)
      equation
        (item, env) = lookupInClass(inName, inEnv);
      then
        (SOME(item), SOME(Absyn.IDENT(inName)), SOME(env));

    // Look among the inherited components.
    case (_, _, _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInBaseClasses(inName, inEnv, INSERT_REDECLARES(), inVisitedScopes);
      then
        (opt_item, opt_path, opt_env);

    // Look among the qualified imports.
    case (_, SCodeEnv.FRAME(importTable = 
        SCodeEnv.IMPORT_TABLE(hidden = false, qualifiedImports = imps)) :: _, _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInQualifiedImports(inName, imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Look among the unqualified imports.
    case (_, SCodeEnv.FRAME(importTable = 
        SCodeEnv.IMPORT_TABLE(hidden = false, unqualifiedImports = imps)) :: _, _)
      equation
        (item, path, env) = 
          lookupInUnqualifiedImports(inName, imps, inEnv);
      then
        (SOME(item), SOME(path), SOME(env));

    // Look in the next scope only if the current scope is an implicit scope
    // (for example a for or match/matchcontinue scope).
    case (_, SCodeEnv.FRAME(frameType = SCodeEnv.IMPLICIT_SCOPE(iterIndex=_)) :: rest_env, _)
      equation
        (opt_item, opt_path, opt_env) = 
          lookupInLocalScope(inName, rest_env, inVisitedScopes);
      then
        (opt_item, opt_path, opt_env);

  end matchcontinue;
end lookupInLocalScope;

public function lookupInClass
  input Absyn.Ident inName;
  input Env inEnv;
  output Item outItem;
  output Env outEnv;
protected
  AvlTree tree;
algorithm
  SCodeEnv.FRAME(clsAndVars = tree) :: _ := inEnv;
  outItem := SCodeEnv.avlTreeGet(tree, inName);
  (outItem, outEnv) := resolveAlias(outItem, inEnv);
end lookupInClass;

public function resolveAlias
  "Resolved an alias by looking up the aliased item recursively in the
   environment until a non-alias item is found."
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := match(inItem, inEnv)
    local
      String name;
      Item item;
      Absyn.Path path;
      Env env;
      AvlTree tree;

    case (SCodeEnv.ALIAS(name = name, path = NONE()),
          SCodeEnv.FRAME(clsAndVars = tree) :: _)
      equation
        item = SCodeEnv.avlTreeGet(tree, name);
        (item, env) = resolveAlias(item, inEnv);
      then
        (item, env);

    case (SCodeEnv.ALIAS(name = name, path = SOME(path)), _)
      equation
        env = SCodeEnv.getEnvTopScope(inEnv);
        env = SCodeEnv.enterScopePath(env, path);
        SCodeEnv.FRAME(clsAndVars = tree) :: _ = env;
        item = SCodeEnv.avlTreeGet(tree, name);
        (item, env) = resolveAlias(item, env);
      then
        (item, env);

    else (inItem, inEnv);
  end match;
end resolveAlias;

protected function lookupInBaseClasses
  "Looks up an identifier by following the extends clauses in a scope."
  input Absyn.Ident inName;
  input Env inEnv;
  input RedeclareReplaceStrategy inReplaceRedeclares;
  input list<String> inVisitedScopes;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
protected
  Env env;
  list<Extends> bcl;
algorithm
  SCodeEnv.FRAME(extendsTable = 
    SCodeEnv.EXTENDS_TABLE(baseClasses = bcl as _ :: _)) :: _ := inEnv;
  // Remove the extends, base class names should not be inherited.
  env := SCodeEnv.removeExtendsFromLocalScope(inEnv);
  // Unhide the imports in case they've been hidden so we can find the base
  // classes.
  env := SCodeEnv.setImportTableHidden(env, false);
  (outItem, outPath, outEnv) := 
    lookupInBaseClasses2(inName, bcl, env, inEnv, inReplaceRedeclares, inVisitedScopes);
end lookupInBaseClasses;

protected function lookupInBaseClasses2
  "Helper function to lookupInBaseClasses. Tries to find an identifier by
   looking in the extended classes in a scope."
  input Absyn.Ident inName;
  input list<Extends> inBaseClasses;
  input Env inEnv;
  input Env inEnvWithExtends;
  input RedeclareReplaceStrategy inReplaceRedeclares;
  input list<String> inVisitedScopes;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) :=
  matchcontinue(inName, inBaseClasses, inEnv, inEnvWithExtends,
      inReplaceRedeclares, inVisitedScopes)
    local
      Extends ext;
      list<Extends> rest_ext;
      Option<Item> item;
      Option<Absyn.Path> path;
      Option<Env> env;

    case (_, ext :: _, _, _, _, _)
      equation
        (item, path, env) = lookupInBaseClasses3(inName, ext, inEnv,
          inEnvWithExtends, inReplaceRedeclares, inVisitedScopes);
      then
        (item, path, env);

    case (_, _ :: rest_ext, _, _, _, _)
      equation
        (item, path, env) = lookupInBaseClasses2(inName, rest_ext, inEnv,
          inEnvWithExtends, inReplaceRedeclares, inVisitedScopes);
      then
        (item, path, env);

  end matchcontinue;
end lookupInBaseClasses2;

public function lookupInBaseClasses3
  "Helper function to lookupInBaseClasses2. Looks up an identifier in the given
   extended class."
  input Absyn.Ident inName;
  input Extends inBaseClass;
  input Env inEnv;
  input Env inEnvWithExtends;
  input RedeclareReplaceStrategy inReplaceRedeclares;
  input list<String> inVisitedScopes;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := match(inName, inBaseClass, inEnv,
      inEnvWithExtends, inReplaceRedeclares, inVisitedScopes)
    local
      Absyn.Path bc, path;
      list<Extends> rest_bc;
      Item item;
      Env env;
      list<SCodeEnv.Redeclaration> redecls;
      Absyn.Info info;
      Option<Absyn.Path> opt_path;
      Option<Item> opt_item;
      Option<Env> opt_env;

    case (_, SCodeEnv.EXTENDS(baseClass = bc as Absyn.QUALIFIED(name = "$E"),
        info = info), _, _, _, _)
      equation
        EnvExtends.printExtendsError(bc, inEnvWithExtends, info);
      then
        (NONE(), NONE(), NONE());

    // Look in the first base class.
    case (_, SCodeEnv.EXTENDS(baseClass = bc, redeclareModifiers = redecls, info = info),
        _, _, _, _)
      equation
        // Find the base class.
        (item, path, env) = lookupBaseClassName(bc, inEnv, info);
        true = checkVisitedScopes(inVisitedScopes, inEnv, path);
        // Hide the imports to make sure that we don't find the name via them
        // (imports are not inherited).
        item = SCodeEnv.setImportsInItemHidden(item, true);
        // Look in the base class.
        (opt_item, opt_env) = SCodeFlattenRedeclare.replaceRedeclares(redecls, 
          item, env, inEnvWithExtends, inReplaceRedeclares); 
        (opt_item, opt_path, opt_env) = 
          lookupInBaseClasses4(Absyn.IDENT(inName), opt_item, opt_env);
      then
        (opt_item, opt_path, opt_env);

  end match;
end lookupInBaseClasses3;

protected function checkVisitedScopes
  "Checks if we are trying to look up a base class that we are coming from when
   going up in the environment, to avoid infinite loops."
  input list<String> inVisitedScopes;
  input Env inEnv;
  input Absyn.Path inBaseClass;
  output Boolean outRes;
algorithm
  outRes := matchcontinue(inVisitedScopes, inEnv, inBaseClass)
    local
      Absyn.Path env_path, visited_path, bc_path;

    case ({}, _, _) then true;

    case (_, _, _)
      equation
        env_path = SCodeEnv.getEnvPath(inEnv);
        bc_path = Absyn.removePrefix(env_path, inBaseClass);
        visited_path = Absyn.stringListPath(inVisitedScopes);
        true = Absyn.pathPrefixOf(visited_path, bc_path);
      then
        false;

    else true;
  end matchcontinue;
end checkVisitedScopes;

protected function lookupInBaseClasses4
  "Helper function to lookupInBaseClasses3. Tries to find the name in the given
   item."
  input Absyn.Path inName;
  input Option<Item> inItem;
  input Option<Env> inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := match(inName, inItem, inEnv)
    local
      Item item;
      Absyn.Path path;
      Env env;
      
    // If the item and env is NONE it means that an error occured (hopefully a
    // user error), and we should stop searching.
    case (_, NONE(), NONE()) then (NONE(), NONE(), NONE());

    // Otherwise, try to find the name in the given item. If the name can not be
    // found we fail, so that we can continue to look in other base classes.
    case (_, SOME(item), SOME(env))
      equation
        (item, path, env) = lookupNameInItem(inName, item, env);
      then
        (SOME(item), SOME(path), SOME(env));

  end match;
end lookupInBaseClasses4;

public function lookupInQualifiedImports
  "Looks up a name through the qualified imports in a scope. If it finds the
  name it returns the item, path, and environment for the name. It can also find
  a partial match, in which case it returns NONE() to signal that the lookup
  shouldn't look further. This can happen if the have an 'import A.B' and an
  element 'B.C', but C is not in A.B. Finally it can also fail to find anything,
  in which case it simply fails as normal."
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Option<Item> outItem;
  output Option<Absyn.Path> outPath;
  output Option<Env> outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path;
      Item item;
      list<Import> rest_imps;
      Option<Item> opt_item;
      Option<Absyn.Path> opt_path;
      Option<Env> opt_env;
      Env env;

    // No match, search the rest of the list of imports.
    case (_, Absyn.NAMED_IMPORT(name = name) :: rest_imps, _)
      equation
        false = stringEqual(inName, name);
        (opt_item, opt_path, opt_env) = 
          lookupInQualifiedImports(inName, rest_imps, inEnv);
      then
        (opt_item, opt_path, opt_env);

    // Match, look up the fully qualified import path.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
        (item, path, env) = lookupFullyQualified(path, inEnv);
      then
        (SOME(item), SOME(path), SOME(env));

    // Partial match, return NONE(). This is when only part of the import path
    // can be found, in which case we should stop looking further.
    case (_, Absyn.NAMED_IMPORT(name = name, path = path) :: _, _)
      equation
        true = stringEqual(inName, name);
      then
        (NONE(), NONE(), NONE());

  end matchcontinue;
end lookupInQualifiedImports;

public function lookupInUnqualifiedImports
  "Looks up a name through the qualified imports in a scope. If it finds the
  name it returns the item, path, and environment for the name, otherwise it
  fails."
  input Absyn.Ident inName;
  input list<Import> inImports;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (outItem, outPath, outEnv) := matchcontinue(inName, inImports, inEnv)
    local
      Item item;
      Absyn.Path path, path2;
      list<Import> rest_imps;
      Env env;

    // For each unqualified import we have to look up the package the import
    // points to, and then look among the public member of the package for the
    // name we are looking for.
    case (_, Absyn.UNQUAL_IMPORT(path = path) :: _, _)
      equation
        // Look up the import path.
        (item, path, env) = lookupFullyQualified(path, inEnv);
        // Look up the name among the public member of the found package.
        (item, path2, env) = lookupNameInItem(Absyn.IDENT(inName), item, env);
        // Combine the paths for the name and the package it was found in.
        path = joinPaths(path, path2);
      then
        (item, path, env);

    // No match, continue with the rest of the imports.
    case (_, _ :: rest_imps, _)
      equation
        (item, path, env) = 
          lookupInUnqualifiedImports(inName, rest_imps, inEnv);
      then
        (item, path, env);
  end matchcontinue;
end lookupInUnqualifiedImports;

public function lookupFullyQualified
  "Looks up a fully qualified path in the environment, returning the
  environment item, path and environment of the name if found."
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
protected
  Env env;
algorithm
  env := SCodeEnv.getEnvTopScope(inEnv);
  (outItem, outPath, outEnv, _) := lookupNameInPackage(inName, env);
  outPath := Absyn.makeFullyQualified(outPath);
end lookupFullyQualified;

public function lookupNameInPackage
  "Looks up a name inside the environment of a package, returning the
  environment item, path and environment of the name if found." 
  input Absyn.Path inName;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
  output Origin outOrigin;
algorithm
  (outItem, outPath, outEnv, outOrigin) := match(inName, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path path, new_path;
      Frame top_scope;
      Env  env;
      Item item;
      Origin origin;

    // Simple name, look in the local scope.
    case (Absyn.IDENT(name = name), _)
      equation
        (SOME(item), SOME(path), SOME(env)) = lookupInLocalScope(name, inEnv, {});
        env = SCodeEnv.setImportTableHidden(env, false);
        origin = itemOrigin(item);
      then
        (item, path, env, origin);

    // Qualified name.
    case (Absyn.QUALIFIED(name = name, path = path), top_scope :: _)
      equation
        // Look up the name in the local scope.
        (SOME(item), SOME(new_path), SOME(env)) = 
          lookupInLocalScope(name, inEnv, {});
        origin = itemOrigin(item);
        env = SCodeEnv.setImportTableHidden(env, false);
        // Look for the rest of the path in the found item.
        (item, path, env) = lookupNameInItem(path, item, env);
        path = joinPaths(new_path, path);
      then
        (item, path, env, origin);

  end match;
end lookupNameInPackage;

public function lookupCrefInPackage
  "Looks up a component reference inside the environment of a package, returning
  the environment item, path and environment of the reference if found."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Item outItem;
  output Absyn.ComponentRef outCref;
algorithm
  (outItem, outCref) := match(inCref, inEnv)
    local
      Absyn.Ident name;
      Absyn.Path new_path;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cref, cref_rest;
      Item item;
      Env env;
     
    // Simple identifier, look in the local scope.
    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _)
      equation
        (SOME(item), SOME(new_path), _) = lookupInLocalScope(name, inEnv, {});
        cref = Absyn.pathToCrefWithSubs(new_path, subs);
      then
        (item, cref);

    // Qualified identifier.
    case (Absyn.CREF_QUAL(name = name, subscripts = subs, 
        componentRef = cref_rest), _)
      equation
        // Look in the local scope.
        (SOME(item), SOME(new_path), SOME(env)) = 
          lookupInLocalScope(name, inEnv, {});
        // Look for the rest of the reference in the found item.
        (item, cref_rest) = lookupCrefInItem(cref_rest, item, env);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);
        cref = Absyn.joinCrefs(cref, cref_rest);
      then
        (item, cref);

  end match;
end lookupCrefInPackage;

public function lookupNameInItem
  "Looks up a name inside of an item, which can be either a variable or a
  class."
  input Absyn.Path inName;
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Absyn.Path outPath;
  output Env outEnv;
algorithm
  (outItem, outPath, outEnv) := match(inName, inItem, inEnv)
    local
      Item item;
      Absyn.Path path;
      Frame class_env;
      Env env, type_env;
      Absyn.TypeSpec type_spec;
      SCode.Mod mods;
      list<SCodeEnv.Redeclaration> redeclares;
      Absyn.Info info;

    // A variable.
    case (_, SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = type_spec, 
        modifications = mods, info = info)), env)
      equation
        //env = SCodeEnv.setImportTableHidden(env, false);
        // Look up the variable type.
        (item, _, type_env) = lookupTypeSpec(type_spec, env, info);
        // Apply redeclares to the type and look for the name inside the type.
        redeclares = SCodeFlattenRedeclare.extractRedeclaresFromModifier(mods);
        (item, type_env, _) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redeclares, item, type_env, inEnv, InstTypes.emptyPrefix);
        (item, path, env) = lookupNameInItem(inName, item, type_env);
      then
        (item, path, env);

    // A class.
    case (_, SCodeEnv.CLASS(env = {class_env}), _) 
      equation
        // Look in the class's environment.
        env = SCodeEnv.enterFrame(class_env, inEnv);
        (item, path, env, _) = lookupNameInPackage(inName, env);
      then
        (item, path, env);

    case (_, SCodeEnv.REDECLARED_ITEM(item = item, declaredEnv = env), _)
      equation
        (item, path, env) = lookupNameInItem(inName, item, env);
      then
        (item, path, env);

  end match;
end lookupNameInItem;

public function lookupCrefInItem
  "Looks up a component reference inside of an item, which can be either a
  variable or a class."
  input Absyn.ComponentRef inCref;
  input Item inItem;
  input Env inEnv;
  output Item outItem;
  output Absyn.ComponentRef outCref;
algorithm
  (outItem, outCref) := match(inCref, inItem, inEnv)
    local
      Item item;
      Absyn.ComponentRef cref;
      Frame class_env;
      Env env, type_env;
      Absyn.TypeSpec type_spec;
      SCode.Mod mods;
      list<SCodeEnv.Redeclaration> redeclares;
      Absyn.Info info;

    // A variable.
    case (_, SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = type_spec, 
        modifications = mods, info = info)), _)
      equation
        // Look up the variable's type.
        (item, _, type_env) = lookupTypeSpec(type_spec, inEnv, info);
        // Apply redeclares to the type and look for the name inside the type.
        redeclares = SCodeFlattenRedeclare.extractRedeclaresFromModifier(mods);
        (item, type_env, _) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redeclares, item, type_env, inEnv, InstTypes.emptyPrefix);
        (item, cref) = lookupCrefInItem(inCref, item, type_env);
      then
        (item, cref);

    // A class.
    case (_, SCodeEnv.CLASS(env = {class_env}), _)
      equation
        // Look in the class's environment.
        env = SCodeEnv.enterFrame(class_env, inEnv);
        (item, cref) = lookupCrefInPackage(inCref, env);
      then
        (item, cref);

    case (_, SCodeEnv.REDECLARED_ITEM(item = item, declaredEnv = env), _)
      equation
        (item, cref) = lookupCrefInItem(inCref, item, env);
      then
        (item, cref);

  end match;
end lookupCrefInItem;

public function lookupBaseClasses
  "Looks up the given name, and returns a list of all the base classes in the
   current scope that the name was found in."
  input SCode.Ident inName;
  input Env inEnv;
  output list<Absyn.Path> outBaseClasses;
protected
  list<Extends> bcl;
algorithm
  SCodeEnv.FRAME(extendsTable =
    SCodeEnv.EXTENDS_TABLE(baseClasses = bcl as _ :: _)) :: _ := inEnv;
  ((_, outBaseClasses)) :=
    List.fold2(bcl, lookupBaseClasses2, inName, inEnv, ({}, {}));
  false := List.isEmpty(outBaseClasses);
  outBaseClasses := listReverse(outBaseClasses);
end lookupBaseClasses;

protected function lookupBaseClasses2
  "Helper function to lookupBaseClasses. Tries to find a name in the given base
   class, and appends the base class path to the given list if found. Otherwise
   returns the unchanged list."
  input Extends inBaseClass;
  input SCode.Ident inName;
  input Env inEnv;
  input tuple<list<Item>, list<Absyn.Path>> inAccum;
  output tuple<list<Item>, list<Absyn.Path>> outResult;
algorithm
  outResult := matchcontinue(inBaseClass, inName, inEnv, inAccum)
    local
      Absyn.Path bc;
      list<SCodeEnv.Redeclaration> redecls;
      Absyn.Info info;
      Env env;
      Item item;
      Option<Item> opt_item;
      Option<Env> opt_env;
      list<Item> items;
      list<Absyn.Path> bcl;

    case (SCodeEnv.EXTENDS(baseClass = bc, redeclareModifiers = redecls,
        info = info), _, _, _)
      equation
        // Look up the base class.
        (item, _, env) = lookupBaseClassName(bc, inEnv, info);

        // Hide the imports to make sure that we don't find the name via them
        // (imports are not inherited).
        item = SCodeEnv.setImportsInItemHidden(item, true);

        // Note that we don't need to apply any redeclares here, since no part
        // of the base class path may be replaceable. The element we're looking
        // for may have been replaced, but that doesn't matter since we only
        // want to check if it can be found or not.

        // Check if we can find the name in the base class. If so, add the base
        // class path to the list.
        (item, _, _) = lookupNameInItem(Absyn.IDENT(inName), item, env);
        (items, bcl) = inAccum;
      then
        ((item :: items, bc :: bcl));

    else inAccum;

  end matchcontinue;
end lookupBaseClasses2;

public function lookupInheritedName
  "Looks up an inherited name by searching the extends in the local scope."
  input SCode.Ident inName;
  input Env inEnv;
  output Item outItem;
  output Env outEnv;
algorithm
  (SOME(outItem), _, SOME(outEnv)) :=
    lookupInBaseClasses(inName, inEnv, INSERT_REDECLARES(), {});
end lookupInheritedName;

public function lookupInheritedNameAndBC
  input SCode.Ident inName;
  input Env inEnv;
  output list<Item> outItems;
  output list<Absyn.Path> outBaseClasses;
protected
  list<Extends> bcl;
algorithm
  SCodeEnv.FRAME(extendsTable =
    SCodeEnv.EXTENDS_TABLE(baseClasses = bcl as _ :: _)) :: _ := inEnv;
  ((outItems, outBaseClasses)) :=
    List.fold2(bcl, lookupBaseClasses2, inName, inEnv, ({}, {}));
  outBaseClasses := listReverse(outBaseClasses);
  outItems := listReverse(outItems);
end lookupInheritedNameAndBC;
  
public function lookupRedeclaredClassByItem
  input Item inItem;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := matchcontinue(inItem, inEnv, inInfo)
    local
      SCode.Ident name;
      Item item;
      Env env;
      SCode.Redeclare rdp;
      SCode.Replaceable rpp;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name)), _, _)
      equation
        (SOME(item), _, SOME(env)) = lookupInBaseClasses(name, inEnv,
          IGNORE_REDECLARES(), {});
        SCode.PREFIXES(redeclarePrefix = rdp, replaceablePrefix = rpp) =
          SCodeEnv.getItemPrefixes(item);
        (item, env) = lookupRedeclaredClass2(item, rdp, rpp, env, inInfo);
      then
        (item, env);

    // No error message is output if the previous case fails. This is because
    // lookupInBaseClasses is used by SCodeEnv.extendEnvWithClassExtends when
    // adding the redeclaration to the environment, and lookupRedeclaredClass2
    // outputs its own errors.
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);  
        Debug.traceln("- SCodeLookup.lookupRedeclaredClassByItem failed on " +&
            SCodeEnv.getItemName(inItem) +& " in " +&
            SCodeEnv.getEnvName(inEnv));
      then
        fail();
  end matchcontinue;
end lookupRedeclaredClassByItem;

protected function lookupRedeclaredClass2
  input Item inItem;
  input SCode.Redeclare inRedeclarePrefix;
  input SCode.Replaceable inReplaceablePrefix;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := 
    matchcontinue(inItem, inRedeclarePrefix, inReplaceablePrefix, inEnv, inInfo)
    local
      SCode.Ident name;
      Item item;
      Env env;
      Absyn.Info info;
      SCode.Redeclare rdp;
      SCode.Replaceable rpp;
 
    // Replaceable element which is not a redeclaration => return the element.
    case (_, SCode.NOT_REDECLARE(), SCode.REPLACEABLE(cc = _), _, _)
      then (inItem, inEnv);

    // Replaceable element which is a redeclaration => continue.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name)),
        SCode.REDECLARE(), SCode.REPLACEABLE(cc = _), _, _)
      equation
        (SOME(item), _, SOME(env)) = lookupInBaseClasses(name, inEnv, 
          IGNORE_REDECLARES(), {});
        SCode.PREFIXES(redeclarePrefix = rdp, replaceablePrefix = rpp) = 
          SCodeEnv.getItemPrefixes(item);
        (item, env) = lookupRedeclaredClass2(item, rdp, rpp, env, inInfo);
      then
        (item, env);

    // Non-replaceable element => error.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name, info = info)), 
        _, SCode.NOT_REPLACEABLE(), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        Error.addSourceMessage(Error.REDECLARE_NON_REPLACEABLE, {"class", name}, info);
      then
        fail();

    // Redeclaration of class to component => error.
    case (SCodeEnv.VAR(var = SCode.COMPONENT(name = name, info = info)), _, _, _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        Error.addSourceMessage(Error.INVALID_REDECLARE_AS, 
          {"component", name, "a class"}, info);
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeLookup.lookupRedeclaredClass2 failed on " +&
            SCodeEnv.getItemName(inItem) +& " in " +&
            SCodeEnv.getEnvName(inEnv));
      then
        fail();
  end matchcontinue;
end lookupRedeclaredClass2;

public function lookupBuiltinType
  "Checks if a name references a builtin type, and returns an environment item
  for that type or fails."
  input Absyn.Ident inName;
  output Item outItem;
algorithm
  outItem := match(inName)
    case "Real" then BUILTIN_REAL;
    case "Integer" then BUILTIN_INTEGER;
    case "Boolean" then BUILTIN_BOOLEAN;
    case "String" then BUILTIN_STRING;
    case "StateSelect" then BUILTIN_STATESELECT;
    case "ExternalObject" then BUILTIN_EXTERNALOBJECT;
    case "$RealType" then BUILTIN_REALTYPE_ITEM;
    case "$IntegerType" then BUILTIN_INTEGERTYPE_ITEM;
    case "$BooleanType" then BUILTIN_BOOLEANTYPE_ITEM;
    case "$StringType" then BUILTIN_STRINGTYPE_ITEM;
    case "$EnumType" then BUILTIN_ENUMTYPE_ITEM;
  end match;
end lookupBuiltinType;

protected function lookupBuiltinName
  input Absyn.Path inName;
  output Item outItem;
  output Env outEnv;
algorithm
  (outItem, outEnv) := match(inName)
    local
      Absyn.Ident id;
      Item item;

    // A builtin type.
    case Absyn.IDENT(name = id)
      equation
        item = lookupBuiltinType(id);
      then
        (item, SCodeEnv.emptyEnv);

    // Builtin type StateSelect. The only builtin type that can be qualified,
    // i.e. StateSelect.always.
    case Absyn.QUALIFIED(name = "StateSelect", path = Absyn.IDENT(id))
      equation
        (item, _) = lookupInClass(id, BUILTIN_STATESELECT_ENV);
      then
        (item, BUILTIN_STATESELECT_ENV);

  end match;
end lookupBuiltinName;

protected function lookupName
  "Looks up a simple or qualified name in the environment and returns the
  environment item corresponding to the name, the path for the name and
  optionally the enclosing scope of the name if the name references a class.
  This function doesn't know what kind of thing the name references, so to get
  meaningful error messages you should use one of the lookup****Name below
  instead."
  input Absyn.Path inName;
  input Env inEnv;
  input LookupStrategy inLookupStrategy;
  input Absyn.Info inInfo;
  input Option<Error.Message> inErrorType;
  output Item outItem;
  output Absyn.Path outName;
  output Env outEnv;
  output Origin outOrigin;
algorithm
  (outItem, outName, outEnv, outOrigin) := 
  matchcontinue(inName, inEnv, inLookupStrategy, inInfo, inErrorType)
    local
      Absyn.Ident id;
      Item item;
      Absyn.Path path, new_path;
      Env env;
      String name_str, env_str;
      Error.Message error_id;
      Origin origin;

    // Builtin types.
    case (_, _, LOOKUP_ANY(), _, _)
      equation
        (item, env) = lookupBuiltinName(inName);
      then
        (item, inName, env, BUILTIN_ORIGIN());

    // Simple name.
    case (Absyn.IDENT(name = id), _, _, _, _)
      equation
        (item, new_path, env) = lookupSimpleName(id, inEnv);
        origin = itemOrigin(item);
      then
        (item, new_path, env, origin);
        
    // Qualified name.
    case (Absyn.QUALIFIED(name = id, path = path), _, _, _, _)
      equation
        // Look up the first identifier.
        (item, new_path, env) = lookupSimpleName(id, inEnv);
        origin = itemOrigin(item);
        // Look up the rest of the name in the environment of the first
        // identifier.
        (item, path, env) = lookupNameInItem(path, item, env);
        path = joinPaths(new_path, path);
      then
        (item, path, env, origin);
             
    case (Absyn.FULLYQUALIFIED(path = path), _, _, _, _)
      equation
        (item, path, env) = lookupFullyQualified(path, inEnv);
      then
        (item, path, env, CLASS_ORIGIN());

    case (_, _, _, _, SOME(error_id))
      equation
        name_str = Absyn.pathString(inName);
        env_str = SCodeEnv.getEnvName(inEnv);
        Error.addSourceMessage(error_id, {name_str, env_str}, inInfo);
      then
        fail();
        
  end matchcontinue;
end lookupName;
 
protected function joinPaths
  "Joins two paths, like Absyn.joinPaths but not with quite the same behaviour.
   If the second path is fully qualified it just returns the cref, because then
   it has been looked up through an import and already points directly at the
   class. If the first path is fully qualified it joins the paths, and return a
   fully qualified path. Otherwise it has the same behaviour as Absyn.joinPaths,
   i.e. it simply joins the paths."
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath1, inPath2)
    local
      Absyn.Ident id;
      Absyn.Path path;

    // The second path is fully qualified, return only that path.
    case (_, Absyn.FULLYQUALIFIED(path = _)) then inPath2;

    // Neither of the paths are fully qualified, just join them.
    case (Absyn.IDENT(name = id), _) then Absyn.QUALIFIED(id, inPath2);
    case (Absyn.QUALIFIED(name = id, path = path), _)
      equation
        path = joinPaths(path, inPath2);
      then
        Absyn.QUALIFIED(id, path);

    // The first path is fully qualified, merge it with the second path and
    // return the result as a fully qualified path.
    case (Absyn.FULLYQUALIFIED(path = path), _)
      equation
        path = joinPaths(path, inPath2);
      then
        Absyn.FULLYQUALIFIED(path);
  end match;
end joinPaths;

public function lookupNameSilent
  "Looks up a name, but doesn't print an error message if it fails."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Env outEnv;
  output Origin outOrigin;
algorithm
  (outItem, outName, outEnv, outOrigin) := lookupName(inName, inEnv,
    LOOKUP_ANY(), inInfo, NONE());
end lookupNameSilent;

public function lookupClassName
  "Calls lookupName with the 'Class not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Env outEnv;
algorithm
  (outItem, outName, outEnv, _) := lookupName(inName, inEnv, LOOKUP_ANY(),
    inInfo, SOME(Error.LOOKUP_ERROR));
end lookupClassName;

public function lookupBaseClassName
  "Calls lookupName with the 'Baseclass not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Env outEnv;
algorithm
  (outItem, outName, outEnv) := match(inName, inEnv, inInfo)
    local
      Absyn.Ident id;
      Env env;
      Item item;
      Absyn.Path path;

    // Special case for the baseclass of a class extends. Should be looked up
    // among the inherited elements of the enclosing class.
    case (Absyn.QUALIFIED(name = "$ce", path = path as Absyn.IDENT(name = id)), _ :: env, _)
      equation
        (item, env) = lookupInheritedName(id, env);
      then
        (item, path, env);

    // The extends was marked as erroneous in the qualifying phase, print an error.
    case (Absyn.QUALIFIED(name = "$E"), _, _)
      equation
        EnvExtends.printExtendsError(inName, inEnv, inInfo);
      then
        fail();

    // Normal baseclass.
    else
      equation
        (item, path, env, _) = lookupName(inName, inEnv, LOOKUP_ANY(), inInfo,
          SOME(Error.LOOKUP_BASECLASS_ERROR));
      then
        (item, path, env);

  end match;
end lookupBaseClassName;

public function lookupVariableName
  "Calls lookupName with the 'Variable not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Env outEnv;
algorithm
  (outItem, outName, outEnv, _) := lookupName(inName, inEnv, NO_BUILTIN_TYPES(),
    inInfo, SOME(Error.LOOKUP_VARIABLE_ERROR));
end lookupVariableName;

public function lookupFunctionName
  "Calls lookupName with the 'Function not found' error message."
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.Path outName;
  output Env outEnv;
  output Origin outOrigin;
algorithm
  (outItem, outName, outEnv, outOrigin) := lookupName(inName, inEnv,
    NO_BUILTIN_TYPES(), inInfo, SOME(Error.LOOKUP_FUNCTION_ERROR));
end lookupFunctionName;

protected function crefStripEnvPrefix
  "Removes the entire environment prefix from the given component reference, or
  returns the unchanged reference. This is done because models might import
  local packages, for example:

    package P
      import myP = InsideP;

      package InsideP
        function f end f;
      end InsideP;

      constant c = InsideP.f();
    end P;

    package P2
      extends P;
    end P2;

  When P2 is instantiated all elements from P will be brought into P2's scope
  due to the extends. The binding of c will still point to P.InsideP.f though, so
  the lookup will try to instantiate P which might fail if P is a partial
  package or for other reasons. This is really a bug in Lookup (it shouldn't
  need to instantiate the whole package just to find a function), but to work
  around this problem for now this function will remove the environment prefix
  when InsideP.f is looked up in P, so that it resolves to InsideP.f and not
  P.InsideP.f. This allows P2 to find it in the local scope instead, since the
  InsideP package has been inherited from P."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnv)
    local
      Absyn.Path env_path;
      Absyn.ComponentRef cref;

    case (_, _)
      equation
        env_path = SCodeEnv.getEnvPath(inEnv);
        cref = Absyn.unqualifyCref(inCref);
      then
        crefStripEnvPrefix2(cref, env_path);

    else inCref;
  end matchcontinue;
end crefStripEnvPrefix;
  
protected function crefStripEnvPrefix2
  input Absyn.ComponentRef inCref;
  input Absyn.Path inEnvPath;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnvPath)
    local
      Absyn.Ident id1, id2;
      Absyn.ComponentRef cref;
      Absyn.Path env_path;

    case (Absyn.CREF_QUAL(name = id1, subscripts = {}, componentRef = cref), 
          Absyn.QUALIFIED(name = id2, path = env_path))
      equation
        true = stringEqual(id1, id2);
      then
        crefStripEnvPrefix2(cref, env_path);

    case (Absyn.CREF_QUAL(name = id1, subscripts = {}, componentRef = cref),
          Absyn.IDENT(name = id2))
      equation
        true = stringEqual(id1, id2);
      then
        cref;
  end match;
end crefStripEnvPrefix2;

public function lookupComponentRef
  "Look up a component reference in the environment and returns it fully
  qualified."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnv, inInfo)
    local
      Absyn.ComponentRef cref;
      Env env;

    // Special case for StateSelect, do nothing.
    case (Absyn.CREF_QUAL(name = "StateSelect", subscripts = {}, 
        componentRef = Absyn.CREF_IDENT(name = _)), _, _)
      then inCref;

    // Wildcard.
    case (Absyn.WILD(), _, _) then inCref;

    // All other component references.
    case (_, _, _)
      equation
        // First look up all subscripts, because all subscripts should be found
        // in the enclosing scope of the component reference.
        cref = SCodeFlattenImports.flattenComponentRefSubs(inCref, inEnv, inInfo);
        // Then look up the component reference itself.
        (cref, env) = lookupComponentRef2(cref, inEnv);
        cref = crefStripEnvPrefix(cref, inEnv);
      then
        cref;

    // Otherwise, mark the cref as invalid, which is ok as long as it's not
    // actually used anywhere.
    //else then Absyn.CREF_INVALID(inCref);
    else inCref;

  end matchcontinue;
end lookupComponentRef;

protected function lookupComponentRef2
  "Helper function to lookupComponentRef. Does the actual look up of the
  component reference."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;
  output Env outEnv;
algorithm
  (outCref, outEnv) := match(inCref, inEnv)
    local
      Absyn.ComponentRef cref, rest_cref;
      Absyn.Ident name;
      list<Absyn.Subscript> subs;
      Absyn.Path path, new_path;
      Env env;
      Item item;

    // A simple name.
    case (Absyn.CREF_IDENT(name, subs), _)
      equation
        (_, path, env) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(path, subs);
      then
        (cref, env);

    // A qualified name.
    case (Absyn.CREF_QUAL(name, subs, rest_cref), _)
      equation
        // Lookup the first identifier.
        (item, new_path, env) = lookupSimpleName(name, inEnv);
        cref = Absyn.pathToCrefWithSubs(new_path, subs);

        // Lookup the rest of the cref in the enclosing scope of the first
        // identifier.
        (item, rest_cref) = lookupCrefInItem(rest_cref, item, env);
        cref = joinCrefs(cref, rest_cref);
      then
        (cref, env);

    // A fully qualified name.
    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cref), _)
      equation
        cref = lookupCrefFullyQualified(cref, inEnv);
        env = SCodeEnv.getEnvTopScope(inEnv);
      then
        (cref, env);

  end match;
end lookupComponentRef2;

public function lookupCrefFullyQualified
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;
protected
  Env env;
algorithm
  env := SCodeEnv.getEnvTopScope(inEnv);
  (_, outCref) := lookupCrefInPackage(inCref, inEnv);
  outCref := Absyn.crefMakeFullyQualified(outCref);
end lookupCrefFullyQualified;
  
public function joinCrefs
  "Joins two component references. If the second cref is fully qualified it just
  returns the cref, because then it has been looked up through an import and
  already points directly at the class. Otherwise it just calls Absyn.joinCrefs."
  input Absyn.ComponentRef inCref1;
  input Absyn.ComponentRef inCref2;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := match(inCref1, inCref2)
    case (_, Absyn.CREF_FULLYQUALIFIED(componentRef = _)) then inCref2;
    else then Absyn.joinCrefs(inCref1, inCref2);
  end match;
end joinCrefs;

public function lookupTypeSpec
  "Looks up a type specification and returns the environment item and enclosing
  scopes of the type."
  input Absyn.TypeSpec inTypeSpec;
  input Env inEnv;
  input Absyn.Info inInfo;
  output Item outItem;
  output Absyn.TypeSpec outTypeSpec;
  output Env outTypeEnv;
algorithm
  (outItem, outTypeSpec, outTypeEnv) := match(inTypeSpec, inEnv, inInfo)
    local
      Absyn.Path path, newpath;
      Absyn.Ident name;
      Item item;
      Env env;
      SCode.Element cls;
      Option<Absyn.ArrayDim> ad;

    // A normal type.
    case (Absyn.TPATH(path, ad), _, _)
      equation
        (item, newpath, env) = lookupClassName(path, inEnv, inInfo);
      then
        (item, Absyn.TPATH(newpath, ad), env);

    // A MetaModelica type such as list or tuple.
    case (Absyn.TCOMPLEX(path = Absyn.IDENT(name = name)), _, _)
      equation
        cls = makeDummyMetaType(name);
      then 
        (SCodeEnv.CLASS(cls, SCodeEnv.emptyEnv, SCodeEnv.BASIC_TYPE()),
          inTypeSpec,
          SCodeEnv.emptyEnv);
         
  end match;
end lookupTypeSpec;
   
protected function makeDummyMetaType
  input String inTypeName;
  output SCode.Element outClass;
algorithm
  outClass := 
  SCode.CLASS(
    inTypeName, 
    SCode.defaultPrefixes, 
    SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()), Absyn.dummyInfo);
end makeDummyMetaType;

public function qualifyPath
  "Qualifies a path by looking up a path in the environment, and merging the
  resulting path with it's environment."
  input Absyn.Path inPath;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Option<Error.Message> inErrorType;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnv, inInfo, inErrorType)
    local
      Absyn.Ident id;
      Absyn.Path path;
      Env env;

    // Never fully qualify builtin types.
    case (Absyn.IDENT(name = id), _, _, _)
      equation
        _ = lookupBuiltinType(id);
      then
        inPath;

    case (_, _, _, _)
      equation
        (_, path, env, _) = lookupName(inPath, inEnv, NO_BUILTIN_TYPES(),
          inInfo, inErrorType);
        path = SCodeEnv.mergePathWithEnvPath(path, env);
        path = Absyn.makeFullyQualified(path);
      then
        path;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeLookup.qualifyPath failed on " +&
          Absyn.pathString(inPath) +& " in " +&
          SCodeEnv.getEnvName(inEnv));
      then
        fail();
  end matchcontinue;
end qualifyPath;

public function itemOrigin
  input Item inItem;
  output Origin outOrigin;
algorithm
  outOrigin := match(inItem)
    local
      Item item;

    case SCodeEnv.VAR(var = _) then INSTANCE_ORIGIN();
    case SCodeEnv.CLASS(classType = SCodeEnv.BUILTIN()) then BUILTIN_ORIGIN();
    case SCodeEnv.CLASS(cls = _) then CLASS_ORIGIN();
    case SCodeEnv.REDECLARED_ITEM(item = item) then itemOrigin(item);
  end match;
end itemOrigin;

public function originIsGlobal
  input Origin inOrigin;
  output Boolean outRes;
algorithm
  outRes := match(inOrigin)
    case CLASS_ORIGIN() then true;
    case BUILTIN_ORIGIN() then true;
    else false;
  end match;
end originIsGlobal;

public function lookupCrefUnique
  "This function tries to look up a cref and returns whether it's a global name
   or not, i.e. found in the class or the instance hierarchy, and the
   environment it was found in. The environment is the environment the name is
   defined in after flattening extends, e.g. if class A extends B, and x is
   defined in B, then A will be returned if we're looking for x in A. This is
   contrary to e.g. lookupName, which would return B. Also note that only the
   first identifier of the cref is looked up, since that's enough to determine
   the scope, so the returned environment is the environment where the first
   identifier of the cref is defined.
   
   The Unique part of the function name comes from the fact that this function
   is used by SCodeInst.prefixCref to find a unique name for all crefs."
  input DAE.ComponentRef inCref;
  input Env inEnv;
  output Boolean outIsGlobal;
  output Env outEnv;
algorithm
  (outIsGlobal, outEnv) := match(inCref, inEnv)
    local
      String id;
      Boolean is_global;
      Env env;

    case (DAE.CREF_IDENT(ident = "time"), _)
      then (false, SCodeEnv.emptyEnv);

    // A simple identifier.
    case (DAE.CREF_IDENT(ident = id), _)
      equation
        (is_global, env) = lookupCrefUnique2(id, inEnv);
      then
        (is_global, env);

    // A qualified identifier.
    case (DAE.CREF_QUAL(ident = id), _)
      equation
        // We only need to know were the first identifier is defined, the cref
        // itself already contains the rest of the path.
        (is_global, env) = lookupCrefUnique2(id, inEnv);
      then
        (is_global, env);

    // We shouldn't get any other types of crefs here.
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeLookup.lookupCrefUnique failed on unknown cref!\n");
      then
        fail();

  end match;
end lookupCrefUnique;

protected function lookupCrefUnique2
  "Helper function to lookupCrefUnique, does the actual work."
  input String inIdentifier;
  input Env inEnv;
  output Boolean outIsGlobal;
  output Env outEnv;
algorithm
  (outIsGlobal, outEnv) := matchcontinue(inIdentifier, inEnv)
    local
      DAE.ComponentRef cref;
      Env env;
      Item item;
      Boolean is_global;

    case (_, _)
      equation
        _ = lookupBuiltinType(inIdentifier);
      then
        (false, SCodeEnv.emptyEnv);

    // Try to find the identifier in the local scope.
    case (_, _)
      equation
        (SOME(item), _, _) = lookupInLocalScope(inIdentifier, inEnv, {});
        // If the name was found in a local class, say that it's a global
        // name. Otherwise it's a local name.
        is_global = SCodeEnv.isClassItem(item);
      then
        (is_global, inEnv);

    // Otherwise, try to find the identifier in one of the scopes above.
    case (_, _)
      equation
        SOME(env) = lookupCrefUnique3(inIdentifier, inEnv);
      then
        (true, env);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeLookup.lookupCrefUnique2 failed on " +&
          inIdentifier +& "\n");
      then
        fail();

  end matchcontinue;
end lookupCrefUnique2;

protected function lookupCrefUnique3
  "Helper function to lookupCrefUnique2. Tries to find an identifier in one of
   the given scopes, and if successful returns the identifiers enclosing scopes.
   Returns NONE if the search was aborted due to an encapsulated scope, or fails
   if the identifier couldn't be found."
  input String inIdentifier;
  input Env inEnv;
  output Option<Env> outEnv;
algorithm
  outEnv := matchcontinue(inIdentifier, inEnv)
    local
      Env env;

    // Stop looking if we encounter an encapsulated scope.
    case (_, SCodeEnv.FRAME(frameType = SCodeEnv.ENCAPSULATED_SCOPE()) :: _)
      then NONE();

    // Look the identifier up in the scope above.
    case (_, _ :: env)
      equation
        (SOME(_), _, _) = lookupInLocalScope(inIdentifier, env, {});
      then
        SOME(env);

    // If previous case failed, look in the scope above.
    case (_, _ :: env) then lookupCrefUnique3(inIdentifier, env);

  end matchcontinue;
end lookupCrefUnique3;

end SCodeLookup;
