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

encapsulated package SCodeInst
" file:        SCodeInst.mo
  package:     SCodeInst
  description: SCode instantiation

  RCS: $Id$

  Prototype SCode instantiation, enable with +d=scodeInst.
"

public import Absyn;
public import DAE;
public import SCode;
public import SCodeEnv;

protected import BaseHashTable;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import Graph;
protected import List;
protected import SCodeDump;
protected import SCodeExpand;
protected import SCodeFlattenRedeclare;
protected import SCodeLookup;
protected import SCodeMod;
protected import System;
protected import Types;
protected import Util;

public type Env = SCodeEnv.Env;
protected type Item = SCodeEnv.Item;

public type Prefix = list<tuple<String, Absyn.ArrayDim>>;

public uniontype Element
  record ELEMENT
    Component component;
    Class cls;
  end ELEMENT;

  record CONDITIONAL_ELEMENT
    Component component;
  end CONDITIONAL_ELEMENT;

  record EXTENDED_ELEMENTS
    Absyn.Path baseClass;
    Class cls;
    DAE.Type ty;
  end EXTENDED_ELEMENTS;
end Element;

public uniontype Class
  record COMPLEX_CLASS
    list<Element> components;
    list<DAE.Element> equations;
    list<DAE.Element> initialEquations;
    list<SCode.AlgorithmSection> algorithms;
    list<SCode.AlgorithmSection> initialAlgorithms;
  end COMPLEX_CLASS;

  record BASIC_TYPE end BASIC_TYPE;
end Class;

public uniontype Dimension
  record UNTYPED_DIMENSION
    DAE.Dimension dimension;
    Boolean isProcessing;
  end UNTYPED_DIMENSION;

  record TYPED_DIMENSION
    DAE.Dimension dimension;
  end TYPED_DIMENSION;
end Dimension;

public uniontype Binding
  record UNBOUND end UNBOUND;

  record RAW_BINDING
    Absyn.Exp bindingExp;
    Env env;
    Prefix prefix;
    Integer propagatedDims "See SCodeMod.propagateMod.";
    Absyn.Info info;
  end RAW_BINDING;

  record UNTYPED_BINDING
    DAE.Exp bindingExp;
    Boolean isProcessing;
    Integer propagatedDims "See SCodeMod.propagateMod.";
    Absyn.Info info;
  end UNTYPED_BINDING;

  record TYPED_BINDING
    DAE.Exp bindingExp;
    DAE.Type bindingType;
    Integer propagatedDims "See SCodeMod.propagateMod.";
    Absyn.Info info;
  end TYPED_BINDING;
end Binding;

public uniontype Component
  record UNTYPED_COMPONENT
    Absyn.Path name;
    DAE.Type baseType;
    array<Dimension> dimensions;
    Prefixes prefixes;
    Binding binding;
    Absyn.Info info;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    Absyn.Path name;
    DAE.Type ty;
    Prefixes prefixes;
    Binding binding;
    Absyn.Info info;
  end TYPED_COMPONENT;
    
  record CONDITIONAL_COMPONENT
    Absyn.Path name;
    SCode.Element element;
    Modifier modifier;
    Prefixes prefixes;
    Env env;
    Prefix prefix;
  end CONDITIONAL_COMPONENT; 

  record OUTER_COMPONENT
    Absyn.Path name;
    Option<Absyn.Path> innerName;
  end OUTER_COMPONENT;
end Component;

public uniontype Modifier
  record MODIFIER
    String name;
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    Binding binding;
    list<Modifier> subModifiers;
    Absyn.Info info;
  end MODIFIER;

  record REDECLARE
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    SCode.Element element;
  end REDECLARE;

  record NOMOD end NOMOD;
end Modifier;

public uniontype Prefixes
  record NO_PREFIXES end NO_PREFIXES;

  record PREFIXES
    DAE.VarVisibility visibility;
    DAE.VarKind variability;
    SCode.Final finalPrefix;
    Absyn.InnerOuter innerOuter;
    tuple<DAE.VarDirection, Absyn.Info> direction;
    tuple<DAE.Flow, Absyn.Info> flowPrefix;
    tuple<DAE.Stream, Absyn.Info> streamPrefix;
  end PREFIXES;
end Prefixes;

protected constant Prefixes DEFAULT_CONST_PREFIXES = PREFIXES(
  DAE.PUBLIC(), DAE.CONST(), SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(),
  (DAE.BIDIR(), Absyn.dummyInfo), (DAE.NON_CONNECTOR(), Absyn.dummyInfo),
  (DAE.NON_STREAM_CONNECTOR(), Absyn.dummyInfo));

protected type Key = Absyn.Path;
protected type Value = Component;

protected type HashTableFunctionsType = tuple<FuncHashKey, FuncKeyEqual, FuncKeyStr, FuncValueStr>;

protected type SymbolTable = tuple<
  array<list<tuple<Key, Integer>>>,
  tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
  Integer,
  Integer,
  HashTableFunctionsType
>;

partial function FuncHashKey
  input Key inKey;
  input Integer inMod;
  output Integer outHash;
end FuncHashKey;

partial function FuncKeyEqual
  input Key inKey1;
  input Key inKey2;
  output Boolean outEqual;
end FuncKeyEqual;

partial function FuncKeyStr
  input Key inKey;
  output String outString;
end FuncKeyStr;

partial function FuncValueStr
  input Value inValue;
  output String outString;
end FuncValueStr;

protected function hashFunc
  input Key inKey;
  input Integer inMod;
  output Integer outHash;
protected
  String str;
algorithm
  str := Absyn.pathString(inKey);
  outHash := System.stringHashDjb2Mod(str, inMod);
end hashFunc;

protected function emptySymbolTable
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := emptySymbolTableSized(BaseHashTable.defaultBucketSize);
end emptySymbolTable;

protected function emptySymbolTableSized
  input Integer inSize;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := BaseHashTable.emptyHashTableWork(inSize,
    (hashFunc, Absyn.pathEqual, Absyn.pathString, printComponent));
end emptySymbolTableSized;

public function instClass
  "Flattens a class."
  input Absyn.Path inClassPath;
  input Env inEnv;
  input list<Absyn.Path> inGlobalConstants;
algorithm
  _ := matchcontinue(inClassPath, inEnv, inGlobalConstants)
    local
      Item item;
      Absyn.Path path;
      Env env; 
      String name;
      Class cls;
      SymbolTable symtab;
      list<Absyn.Path> consts;
      list<Element> const_el;

    case (_, _, _)
      equation
        false = Flags.isSet(Flags.SCODE_INST);
      then
        ();

    case (_, _, _)
      equation
        System.startTimer();
        name = Absyn.pathLastIdent(inClassPath);
        (item, path, env) = 
          SCodeLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
        (cls, _) = instClassItem(item, NOMOD(), NO_PREFIXES(), env, {});
        const_el = instGlobalConstants(inGlobalConstants, inEnv);
        cls = addElementsToClass(const_el, cls);

        (cls, symtab) = buildSymbolTable(cls);
        (cls, symtab) = typeClass(cls, symtab);
        // Type normal equations and algorithm here.
        (cls, symtab) = instConditionalComponents(cls, symtab);
        (cls, symtab) = typeClass(cls, symtab);
        // Type connects here.
        System.stopTimer();
        //print("\nclass " +& name +& "\n");
        //print(printClass(cls));
        //print("\nend " +& name +& "\n");

        _ = SCodeExpand.expand(name, cls);
        //print("SCodeInst took " +& realString(System.getTimerIntervalTime()) +& " seconds.\n");
      then
        ();

    else
      equation
        print("SCodeInst.instClass failed\n");
        true = Flags.isSet(Flags.FAILTRACE);
        name = Absyn.pathString(inClassPath);
        Debug.traceln("SCodeInst.instClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end instClass;

protected function addElementsToClass
  input list<Element> inElements;
  input Class inClass;
  output Class outClass;
algorithm
  outClass := match(inElements, inClass)
    local
      list<Element> el;
      list<DAE.Element> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;

    case (_, COMPLEX_CLASS(el, eq, ieq, al, ial))
      equation
        el = listAppend(inElements, el);
      then
        COMPLEX_CLASS(el, eq, ieq, al, ial);

    case (_, BASIC_TYPE())
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.addElementsToClass: Can't add elements to basic type.\n"});
      then
        fail();

  end match;
end addElementsToClass;

protected function instClassItem
  input Item inItem;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  output Class outClass;
  output DAE.Type outType;
algorithm
  (outClass, outType) := match(inItem, inMod, inPrefixes, inEnv, inPrefix)
    local
      list<SCode.Element> el;
      list<tuple<SCode.Element, Modifier>> mel;
      Absyn.TypeSpec dty;
      Item item;
      Env env;
      Absyn.Info info;
      SCode.Mod smod;
      Modifier mod;
      SCodeEnv.AvlTree cls_and_vars;
      String name, err_msg;
      list<SCode.Equation> snel, siel;
      list<DAE.Element> dnel, diel;
      list<SCode.AlgorithmSection> nal, ial;
      DAE.Type ty;
      Absyn.ArrayDim dims;
      list<DAE.Var> vars;
      list<SCode.Enum> enums;
      Absyn.Path path;
      Class cls;
      list<Element> elems;
      SCode.Element sel;
      Boolean cse;
      SCode.Element scls;
      SCode.ClassDef cdef;
      SCodeEnv.Frame frame;
      Integer dim_count;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name), env = env,
        classType = SCodeEnv.BASIC_TYPE()), _, _, _, _) 
      equation
        vars = instBasicTypeAttributes(inMod, env);
        ty = instBasicType(name, inMod, vars);
      then 
        (BASIC_TYPE(), ty);

    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name,
          classDef = SCode.PARTS(el, snel, siel, nal, ial, _, _, _), info = info),
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _, _, _)
      equation
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        el = List.map1(el, lookupElement, cls_and_vars);
        mel = SCodeMod.applyModifications(inMod, el, inPrefix, env);
        (elems, cse) = instElementList(mel, inPrefixes, env, inPrefix);
        dnel = instEquations(snel, inEnv, inPrefix);
        diel = instEquations(siel, inEnv, inPrefix);
        (cls, ty) = makeClass(elems, dnel, diel, nal, ial, cse);
      then
        (cls, ty);

    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.DERIVED(modifications = smod, typeSpec = dty), info = info)), _, _, _, _)
      equation
        (item, env) = SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        dims = Absyn.typeSpecDimensions(dty);
        dim_count = listLength(dims);
        mod = SCodeMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inMod, mod);
        (cls, ty) = instClassItem(item, mod, inPrefixes, env, inPrefix);
        ty = liftArrayType(dims, ty, inEnv, inPrefix);
      then
        (cls, ty);
        
    case (SCodeEnv.CLASS(cls = scls, classType = SCodeEnv.CLASS_EXTENDS(), env = env), _, _, _, _)
      equation
        (cls, ty) = instClassExtends(scls, inMod, inPrefixes, env, inEnv, inPrefix);
      then
        (cls, ty);

    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.ENUMERATION(enumLst = enums), info = info)), _, _, _, _)
      equation
        path = prefixToPath(inPrefix);
        ty = makeEnumType(enums, path);
      then
        (BASIC_TYPE(), ty);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instClassItem failed on unknown class.\n");
      then
        fail();

  end match;
end instClassItem;
  
protected function instClassExtends
  input SCode.Element inClassExtends;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inClassEnv;
  input Env inEnv;
  input Prefix inPrefix;
  output Class outClass;
  output DAE.Type outType;
algorithm
  (outClass, outType) := 
  matchcontinue(inClassExtends, inMod, inPrefixes, inClassEnv, inEnv, inPrefix)
    local
      SCode.ClassDef cdef;
      Absyn.Path bc_path;
      SCode.Element ext;
      SCode.Mod mod;
      SCode.Element scls;
      Class cls;
      DAE.Type ty;
      Item item;
      String name;
      Absyn.Info info;

    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(modifications = mod, 
        composition = cdef)), _, _, _, _, _)
      equation
        (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
        ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
        cdef = SCode.addElementToCompositeClassDef(ext, cdef);
        scls = SCode.setElementClassDefinition(cdef, inClassExtends);
        item = SCodeEnv.CLASS(scls, inClassEnv, SCodeEnv.USERDEFINED());
        (cls, ty) = instClassItem(item, inMod, inPrefixes, inEnv, inPrefix);
      then
        (cls, ty);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCode.elementName(inClassExtends);
        Debug.traceln("SCodeInst.instClassExtends failed on " +& name);
      then
        fail();

  end matchcontinue;
end instClassExtends;

protected function getClassExtendsBaseClass
  input Env inClassEnv;
  output Absyn.Path outPath;
  output Absyn.Info outInfo;
algorithm
  (outPath, outInfo) := matchcontinue(inClassEnv)
    local
      Absyn.Path bc;
      Absyn.Info info;
      String name;

    case (SCodeEnv.FRAME(extendsTable = SCodeEnv.EXTENDS_TABLE(
        baseClasses = SCodeEnv.EXTENDS(baseClass = bc, info = info) :: _)) :: _)
      then (bc, info);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = SCodeEnv.getEnvName(inClassEnv);
        Debug.traceln("SCodeInst.getClassExtendsBaseClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end getClassExtendsBaseClass;

protected function makeClass
  input list<Element> inElements;
  input list<DAE.Element> inEquations;
  input list<DAE.Element> inInitialEquations;
  input list<SCode.AlgorithmSection> inAlgorithms;
  input list<SCode.AlgorithmSection> inInitialAlgorithms;
  input Boolean inContainsSpecialExtends;
  output Class outClass;
  output DAE.Type outClassType;
algorithm
  (outClass, outClassType) := match(inElements, inEquations, inInitialEquations,
      inAlgorithms, inInitialAlgorithms, inContainsSpecialExtends)
    local
      list<Element> elems;
      list<DAE.Element> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      Class cls;
      DAE.Type ty;

    case (elems, eq, ieq, al, ial, false)
      then (COMPLEX_CLASS(elems, eq, ieq, al, ial), DAE.T_COMPLEX_DEFAULT);

    case (_, {}, {}, {}, {}, true)
      equation
        (EXTENDED_ELEMENTS(cls = cls, ty = ty), elems) =
          getSpecialExtends(inElements);
      then
        (cls, ty);

  end match;
end makeClass;
        
protected function getSpecialExtends
  input list<Element> inElements;
  output Element outSpecialExtends;
  output list<Element> outRestElements;
algorithm
  (outSpecialExtends, outRestElements) := getSpecialExtends2(inElements, {});
end getSpecialExtends;

protected function getSpecialExtends2
  input list<Element> inElements;
  input list<Element> inAccumEl;
  output Element outSpecialExtends;
  output list<Element> outRestElements;
algorithm
  (outSpecialExtends, outRestElements) := matchcontinue(inElements, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      DAE.Type ty;

    case ((el as EXTENDED_ELEMENTS(ty = ty)) :: rest_el, _)
      equation
        true = isSpecialExtends(ty);
        rest_el = listAppend(listReverse(inAccumEl), rest_el);
      then
        (el, rest_el);

    // TODO: Check for illegal elements here (components, etc.).

    case (el :: rest_el, _)
      equation
        (el, rest_el) = getSpecialExtends2(rest_el, el :: inAccumEl);
      then
        (el, rest_el);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeInst.getSpecialExtends2 failed!");
      then
        fail();

  end matchcontinue;
end getSpecialExtends2;

protected function makeClassComment
  input list<SCode.Annotation> inAnnotations;
  input Option<SCode.Comment> inComment;
  output Option<SCode.Comment> outComment;
algorithm
  outComment := match(inAnnotations, inComment)
    case ({}, NONE()) then NONE();
    else SOME(SCode.CLASS_COMMENT(inAnnotations, inComment));
  end match;
end makeClassComment;

protected function instBasicType
  input SCode.Ident inTypeName;
  input Modifier inMod;
  input list<DAE.Var> inAttributes;
  output DAE.Type outType;
algorithm
  outType := match(inTypeName, inMod, inAttributes)
    case ("Real", _, _) then DAE.T_REAL(inAttributes, DAE.emptyTypeSource);
    case ("Integer", _, _) then DAE.T_INTEGER(inAttributes, DAE.emptyTypeSource);
    case ("String", _, _) then DAE.T_STRING(inAttributes, DAE.emptyTypeSource);
    case ("Boolean", _, _) then DAE.T_BOOL(inAttributes, DAE.emptyTypeSource);
    case ("StateSelect", _, _) then DAE.T_ENUMERATION_DEFAULT;
  end match;
end instBasicType;

protected function instBasicTypeAttributes
  input Modifier inMod;
  input Env inEnv;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inMod, inEnv)
    local
      list<Modifier> submods;
      SCodeEnv.AvlTree attrs;
      list<DAE.Var> vars;
      SCode.Element el;
      Absyn.Info info;

    case (NOMOD(), _) then {};

    case (MODIFIER(subModifiers = submods), 
        SCodeEnv.FRAME(clsAndVars = attrs) :: _)
      equation
        vars = List.map1(submods, instBasicTypeAttribute, attrs);
      then
        vars;

    case (REDECLARE(element = el), _)
      equation
        info = SCode.elementInfo(el);
        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE, {}, info);
      then
        fail();
         
  end match;
end instBasicTypeAttributes;

protected function instBasicTypeAttribute
  input Modifier inMod;
  input SCodeEnv.AvlTree inAttributes;
  output DAE.Var outAttribute;
algorithm
  outAttribute := matchcontinue(inMod, inAttributes)
    local
      String ident, tspec;
      DAE.Type ty;
      Absyn.Exp bind_exp;
      DAE.Exp inst_exp;
      DAE.Binding binding;
      Env env;
      Prefix prefix;

    case (MODIFIER(name = ident, subModifiers = {}, 
        binding = RAW_BINDING(bind_exp, env, prefix, _, _)), _)
      equation
        SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = Absyn.TPATH(path =
          Absyn.IDENT(tspec)))) = SCodeLookup.lookupInTree(ident, inAttributes);
        ty = instBasicTypeAttributeType(tspec);
        inst_exp = instExp(bind_exp, env, prefix);
        binding = DAE.EQBOUND(inst_exp, NONE(), DAE.C_UNKNOWN(), 
          DAE.BINDING_FROM_DEFAULT_VALUE());
      then
        DAE.TYPES_VAR(ident, DAE.dummyAttrParam, SCode.PUBLIC(), ty, binding, NONE());

    // TODO: Print error message for invalid attributes.
  end matchcontinue;
end instBasicTypeAttribute;
        
protected function instBasicTypeAttributeType
  input String inTypeName;
  output DAE.Type outType;
algorithm
  outType := match(inTypeName)
    case "$RealType" then DAE.T_REAL_DEFAULT;
    case "$IntegerType" then DAE.T_INTEGER_DEFAULT;
    case "$BooleanType" then DAE.T_BOOL_DEFAULT;
    case "$StringType" then DAE.T_STRING_DEFAULT;
    case "$EnumType" then DAE.T_ENUMERATION_DEFAULT;
    case "StateSelect" then DAE.T_ENUMERATION_DEFAULT;
  end match;
end instBasicTypeAttributeType;

protected function lookupElement
  "This functions might seem a little odd, why look up elements in the
   environment when we already have them? This is because they might have been
   redeclared, and redeclares are only applied to the environment and not the
   SCode itself. So we need to look them up in the environment to make sure we
   have the right elements."
  input SCode.Element inElement;
  input SCodeEnv.AvlTree inEnv;
  output SCode.Element outElement;
algorithm
  outElement := match(inElement, inEnv)
    local
      String name;
      SCode.Element el;

    case (SCode.COMPONENT(name = name), _)
      equation
        SCodeEnv.VAR(var = el) = SCodeEnv.avlTreeGet(inEnv, name);
      then
        el;

    // Only components need to be looked up. Extends are not allowed to be
    // redeclared, while classes are not instantiated by instElement.
    else inElement;
  end match;
end lookupElement;
        
protected function instElementList
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  output list<Element> outElements;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElements, outContainsSpecialExtends) :=
    instElementList2(inElements, inPrefixes, inEnv, inPrefix, {}, false);
end instElementList;

protected function instElementList2
  input list<tuple<SCode.Element, Modifier>> inElements;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input list<Element> inAccumEl;
  input Boolean inContainsSpecialExtends;
  output list<Element> outElements;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElements, outContainsSpecialExtends) :=
  match(inElements, inPrefixes, inEnv, inPrefix, inAccumEl, inContainsSpecialExtends)
    local
      SCode.Element elem;
      Modifier mod;
      list<tuple<SCode.Element, Modifier>> rest_el;
      Element res;
      Boolean cse;
      list<Element> accum_el;

    case ({}, _, _, _, _, cse) then (inAccumEl, cse);

    case ((elem as SCode.COMPONENT(name = _), mod) :: rest_el, _, _, _, _, cse)
      equation
        res = instElement(elem, mod, inPrefixes, inEnv, inPrefix);
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, inEnv, inPrefix,
          res :: inAccumEl, cse);
      then
        (accum_el, cse);

    case ((elem as SCode.EXTENDS(baseClassPath = _), mod) :: rest_el, _, _, _, _, _)
      equation
        (res, cse) = instExtends(elem, mod, inPrefixes, inEnv, inPrefix);
        cse = inContainsSpecialExtends or cse;
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, inEnv, inPrefix,
          res :: inAccumEl, cse);
      then
        (accum_el, cse);

    case (_ :: rest_el, _, _, _, _, cse)
      equation
        (accum_el, cse) = instElementList2(rest_el, inPrefixes, inEnv, inPrefix,
          inAccumEl, cse);
      then
        (accum_el, cse);

  end match;
end instElementList2;

protected function instElement
  input SCode.Element inElement;
  input Modifier inClassMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  output Element outElement;
algorithm
  outElement := match(inElement, inClassMod, inPrefixes, inEnv, inPrefix)
    local
      Absyn.ArrayDim ad;
      Absyn.Info info;
      Absyn.Path path, inner_comp;
      Component comp;
      DAE.Type ty;
      Env env;
      Item item;
      list<SCodeEnv.Redeclaration> redecls;
      Binding binding;
      Prefix prefix;
      SCode.Mod smod;
      Modifier mod, cmod;
      String name;
      SCode.Variability var;
      list<DAE.Dimension> dims;
      array<Dimension> dim_arr;
      Class cls;
      Element el;
      SCode.Prefixes pf;
      SCode.Attributes attr;
      Prefixes prefs;
      Integer dim_count;

    case (SCode.COMPONENT(name = name, 
        prefixes = SCode.PREFIXES(innerOuter = Absyn.OUTER())), _, _, _, _)
      equation
        prefix = (name, {}) :: inPrefix;
        path = prefixToPath(prefix);
        comp = OUTER_COMPONENT(path, NONE());
      then
        ELEMENT(comp, BASIC_TYPE());

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(name = name, prefixes = pf, 
        attributes = attr as SCode.ATTR(arrayDims = ad),
        typeSpec = Absyn.TPATH(path = path), modifications = smod,
        condition = NONE(), info = info), _, _, _, _)
      equation
        // Look up the class of the component.
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);

        // Apply the redeclarations to the class.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(smod);
        (item, env) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redecls, item, env, inEnv, inPrefix);

        // Instantiate the class.
        prefix = (name, ad) :: inPrefix;
        path = prefixToPath(prefix);
        prefs = mergePrefixes(path, pf, attr, inPrefixes, info);
        dim_count = listLength(ad);
        mod = SCodeMod.translateMod(smod, name, dim_count, inPrefix, inEnv);
        cmod = SCodeMod.propagateMod(inClassMod, dim_count);
        mod = SCodeMod.mergeMod(cmod, mod);
        (cls, ty) = instClassItem(item, mod, prefs, env, prefix);

        // Instantiate array dimensions.
        dims = instDimensions(ad, inEnv, inPrefix);
        (dims, dim_count) = addDimensionsFromType(dims, ty);
        ty = Types.arrayElementType(ty);
        dim_arr = makeDimensionArray(dims);

        // Instantiate binding.
        mod = SCodeMod.propagateMod(mod, dim_count);
        binding = SCodeMod.getModifierBinding(mod);
        binding = instBinding(binding, dim_count);

        // Create the component and add it to the program.
        comp = UNTYPED_COMPONENT(path, ty, dim_arr, prefs, binding, info);
      then
        ELEMENT(comp, cls);

    // A conditional component, save it for later.
    case (SCode.COMPONENT(name = name, condition = SOME(_)), _, _, _, _)
      equation
        path = prefixPath(Absyn.IDENT(name), inPrefix);
        comp = CONDITIONAL_COMPONENT(path, inElement, inClassMod, inPrefixes, inEnv, inPrefix);
      then
        CONDITIONAL_ELEMENT(comp);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instElement failed on unknown element.\n");
      then
        fail();

  end match;
end instElement;

protected function instExtends
  input SCode.Element inExtends;
  input Modifier inClassMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  output Element outElement;
  output Boolean outContainsSpecialExtends;
algorithm
  (outElement, outContainsSpecialExtends) :=
  match(inExtends, inClassMod, inPrefixes, inEnv, inPrefix)
    local
      Absyn.Path path;
      SCode.Mod smod;
      Absyn.Info info;
      SCodeEnv.ExtendsTable exts;
      Item item;
      Env env;
      list<SCodeEnv.Redeclaration> redecls;
      Modifier mod;
      Class cls;
      DAE.Type ty;
      Boolean cse;

    case (SCode.EXTENDS(baseClassPath = path, modifications = smod, info = info),
        _, _, SCodeEnv.FRAME(extendsTable = exts) :: _, _)
      equation
        // Look up the extended class.
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        path = SCodeEnv.mergePathWithEnvPath(path, env);

        // Apply the redeclarations.
        redecls = SCodeFlattenRedeclare.lookupExtendsRedeclaresInTable(path, exts);
        (item, env) = SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
          redecls, item, env, inEnv, inPrefix);

        // Instantiate the class.
        mod = SCodeMod.translateMod(smod, "", 0, inPrefix, inEnv);
        mod = SCodeMod.mergeMod(inClassMod, mod);
        (cls, ty) = instClassItem(item, mod, inPrefixes, env, inPrefix);
        cse = isSpecialExtends(ty);
      then
        (EXTENDED_ELEMENTS(path, cls, ty), cse);
        
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instExtends failed on unknown element.\n");
      then
        fail();

  end match;
end instExtends;

protected function isSpecialExtends
  input DAE.Type inType;
  output Boolean outResult;
algorithm
  outResult := match(inType)
    case DAE.T_COMPLEX(varLst = _) then false;
    else true;
  end match;
end isSpecialExtends;

protected function mergePrefixes
  input Absyn.Path inComponentName;
  input SCode.Prefixes inInnerPrefixes;
  input SCode.Attributes inAttributes;
  input Prefixes inOuterPrefixes;
  input Absyn.Info inInfo;
  output Prefixes outPrefixes;
algorithm
  outPrefixes :=
  match(inComponentName, inInnerPrefixes, inAttributes, inOuterPrefixes, inInfo)
    local
      SCode.Visibility vis1;
      DAE.VarVisibility vis2;
      SCode.Variability var1;
      DAE.VarKind var2;
      SCode.Final fp1, fp2;
      Absyn.InnerOuter io;
      Absyn.Direction dir1;
      tuple<DAE.VarDirection, Absyn.Info> dir2;
      SCode.Flow flp1;
      tuple<DAE.Flow, Absyn.Info> flp2;
      SCode.Stream sp1;
      tuple<DAE.Stream, Absyn.Info> sp2;

    case (_, SCode.PREFIXES(SCode.PUBLIC(), _, SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(), _), 
        SCode.ATTR(_, SCode.NOT_FLOW(), SCode.NOT_STREAM(), _, SCode.VAR(), Absyn.BIDIR()), _, _)
      then inOuterPrefixes;

    case (_, _, _, NO_PREFIXES(), _) 
      then makePrefixes(inInnerPrefixes, inAttributes, inInfo);

    case (_, SCode.PREFIXES(vis1, _, fp1, io, _), SCode.ATTR(_, flp1, sp1, _, var1, dir1),
        PREFIXES(vis2, var2, fp2, _, dir2, flp2, sp2), _)
      equation
        vis2 = mergeVisibility(vis1, vis2);
        var2 = mergeVariability(var1, var2);
        fp2 = mergeFinal(fp1, fp2);
        dir2 = mergeDirection(dir1, dir2, inComponentName, inInfo);
        (flp2, sp2) = mergeFlowStream(flp1, sp1, flp2, sp2, inComponentName, inInfo);
      then
        PREFIXES(vis2, var2, fp2, io, dir2, flp2, sp2);

  end match;
end mergePrefixes;

protected function makePrefixes
  input SCode.Prefixes inPrefixes;
  input SCode.Attributes inAttributes;
  input Absyn.Info inInfo;
  output Prefixes outPrefixes;
protected
  SCode.Visibility vis;
  DAE.VarVisibility dvis;
  SCode.Variability var;
  DAE.VarKind vkind;
  SCode.Final fp;
  Absyn.InnerOuter io;
  Absyn.Direction dir;
  DAE.VarDirection ddir;
  SCode.Flow flp;
  DAE.Flow dflp;
  SCode.Stream sp;
  DAE.Stream dsp;
algorithm
  SCode.PREFIXES(visibility = vis, finalPrefix = fp, innerOuter = io) := inPrefixes;
  SCode.ATTR(flowPrefix = flp, streamPrefix = sp, variability = var,
    direction = dir) := inAttributes;
  dvis := makeVarVisibility(vis);
  vkind := makeVarKind(var);
  ddir := makeVarDirection(dir);
  dflp := makeVarFlow(flp);
  dsp := makeVarStream(sp);
  outPrefixes := PREFIXES(dvis, vkind, fp, io, 
    (ddir, inInfo), (dflp, inInfo), (dsp, inInfo));
end makePrefixes;

protected function makeVarVisibility
  input SCode.Visibility inVisibility;
  output DAE.VarVisibility outVisibility;
algorithm
  outVisibility := match(inVisibility)
    case SCode.PUBLIC() then DAE.PUBLIC();
    else DAE.PROTECTED();
  end match;
end makeVarVisibility;

protected function makeVarKind
  input SCode.Variability inVariability;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inVariability)
    case SCode.VAR() then DAE.VARIABLE();
    case SCode.PARAM() then DAE.PARAM();
    case SCode.CONST() then DAE.CONST();
    case SCode.DISCRETE() then DAE.DISCRETE();
  end match;
end makeVarKind;

protected function makeVarDirection
  input Absyn.Direction inDirection;
  output DAE.VarDirection outDirection;
algorithm
  outDirection := match(inDirection)
    case Absyn.BIDIR() then DAE.BIDIR();
    case Absyn.OUTPUT() then DAE.OUTPUT();
    case Absyn.INPUT() then DAE.INPUT();
  end match;
end makeVarDirection;

protected function makeVarFlow
  input SCode.Flow inFlow;
  output DAE.Flow outFlow;
algorithm
  outFlow := match(inFlow)
    case SCode.NOT_FLOW() then DAE.NON_CONNECTOR();
    else DAE.FLOW();
  end match;
end makeVarFlow;

protected function makeVarStream
  input SCode.Stream inStream;
  output DAE.Stream outStream;
algorithm
  outStream := match(inStream)
    case SCode.NOT_STREAM() then DAE.NON_STREAM_CONNECTOR();
    else DAE.STREAM();
  end match;
end makeVarStream;

protected function mergeVisibility
  input SCode.Visibility inInnerVisibility;
  input DAE.VarVisibility inOuterVisibility;
  output DAE.VarVisibility outVisibility;
algorithm
  outVisibility := match(inInnerVisibility, inOuterVisibility)
    case (_, DAE.PROTECTED()) then DAE.PROTECTED();
    else makeVarVisibility(inInnerVisibility);
  end match;
end mergeVisibility;

protected function mergeVariability
  input SCode.Variability inInnerVariability;
  input DAE.VarKind inOuterVariability;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inInnerVariability, inOuterVariability)
    case (_, DAE.CONST()) then DAE.CONST();
    case (SCode.CONST(), _) then DAE.CONST();
    case (_, DAE.PARAM()) then DAE.PARAM();
    case (SCode.PARAM(), _) then DAE.PARAM();
    case (_, DAE.DISCRETE()) then DAE.DISCRETE();
    case (SCode.DISCRETE(), _) then DAE.DISCRETE();
    else DAE.VARIABLE();
  end match;
end mergeVariability;

protected function mergeFinal
  input SCode.Final inInnerFinal;
  input SCode.Final inOuterFinal;
  output SCode.Final outFinal;
algorithm
  outFinal := match(inInnerFinal, inOuterFinal)
    case (_, SCode.FINAL()) then SCode.FINAL();
    else inInnerFinal;
  end match;
end mergeFinal;

protected function mergeDirection
  input Absyn.Direction inInnerDirection;
  input tuple<DAE.VarDirection, Absyn.Info> inOuterDirection;
  input Absyn.Path inComponentName;
  input Absyn.Info inInfo;
  output tuple<DAE.VarDirection, Absyn.Info> outDirection;
algorithm
  outDirection := match(inInnerDirection, inOuterDirection, inComponentName, inInfo)
    local
      DAE.VarDirection dir;
      Absyn.Info info;
      String dir_str1, dir_str2, comp_name;

    case (Absyn.BIDIR(), _, _, _) then inOuterDirection;

    case (_, (DAE.BIDIR(), _), _, _)
      equation
        dir = makeVarDirection(inInnerDirection);
      then
        ((dir, inInfo));

    case (_, (dir, info), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        dir_str1 = varDirectionString(dir);
        dir_str2 = directionString(inInnerDirection);
        comp_name = Absyn.pathString(inComponentName);
        Error.addSourceMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH,
          {dir_str1, comp_name, dir_str2}, info);
      then
        fail();

  end match;
end mergeDirection;

protected function mergeFlowStream
  input SCode.Flow inInnerFlow;
  input SCode.Stream inInnerStream;
  input tuple<DAE.Flow, Absyn.Info> inOuterFlow;
  input tuple<DAE.Stream, Absyn.Info> inOuterStream;
  input Absyn.Path inComponentName;
  input Absyn.Info inInfo;
  output tuple<DAE.Flow, Absyn.Info> outFlow;
  output tuple<DAE.Stream, Absyn.Info> outStream;
algorithm
  (outFlow, outStream) := matchcontinue(inInnerFlow, inInnerStream, inOuterFlow,
      inOuterStream, inComponentName, inInfo)
    local
      DAE.Flow fp;
      DAE.Stream sp;
      Absyn.Info info;
      String fp_str, sp_str, pf_str, comp_name;
      tuple<DAE.Flow, Absyn.Info> new_fp;
      tuple<DAE.Stream, Absyn.Info> new_sp;

    case (SCode.NOT_FLOW(), SCode.NOT_STREAM(), _, _, _, _) 
      then (inOuterFlow, inOuterStream);

    case (_, _, (fp, _), (sp, _), _, _)
      equation
        false = ((SCode.flowBool(inInnerFlow) or SCode.streamBool(inInnerStream)) and
                 (DAEUtil.isFlow(fp) or DAEUtil.isStream(sp)));
        new_fp = mergeFlow(inInnerFlow, inOuterFlow, inInfo);
        new_sp = mergeStream(inInnerStream, inOuterStream, inInfo);
      then
        (new_fp, new_sp);
        
    case (_, _, (DAE.FLOW(), info), _, _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        fp_str = SCodeDump.flowStr(inInnerFlow);
        sp_str = SCodeDump.streamStr(inInnerStream);
        pf_str = fp_str +& sp_str;
        comp_name = Absyn.pathString(inComponentName);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {"flow", comp_name, pf_str}, info);
      then
        fail();

    case (_, _, _, (DAE.STREAM(), info), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        fp_str = SCodeDump.flowStr(inInnerFlow);
        sp_str = SCodeDump.streamStr(inInnerStream);
        pf_str = fp_str +& sp_str;
        comp_name = Absyn.pathString(inComponentName);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {"stream", comp_name, pf_str}, info);
      then
        fail();

  end matchcontinue;
end mergeFlowStream;

protected function mergeFlow
  input SCode.Flow inInnerFlow;
  input tuple<DAE.Flow, Absyn.Info> inOuterFlow;
  input Absyn.Info inInfo;
  output tuple<DAE.Flow, Absyn.Info> outFlow;
algorithm
  outFlow := match(inInnerFlow, inOuterFlow, inInfo)
    case (SCode.NOT_FLOW(), _, _) then inOuterFlow;
    else ((DAE.FLOW(), inInfo));
  end match;
end mergeFlow;

protected function mergeStream
  input SCode.Stream inInnerStream;
  input tuple<DAE.Stream, Absyn.Info> inOuterStream;
  input Absyn.Info inInfo;
  output tuple<DAE.Stream, Absyn.Info> outStream;
algorithm
  outStream := match(inInnerStream, inOuterStream, inInfo)
    case (SCode.NOT_STREAM(), _, _) then inOuterStream;
    else ((DAE.STREAM(), inInfo));
  end match;
end mergeStream;
   
protected function directionString
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString := match(inDirection)
    case Absyn.INPUT() then "input";
    case Absyn.OUTPUT() then "output";
    else "";
  end match;
end directionString;

protected function varDirectionString
  input DAE.VarDirection inDirection;
  output String outString;
algorithm
  outString := match(inDirection)
    case DAE.INPUT() then "input";
    case DAE.OUTPUT() then "output";
    else "";
  end match;
end varDirectionString;

protected function makeEnumType
  input list<SCode.Enum> inEnumLiterals;
  input Absyn.Path inEnumPath;
  output DAE.Type outType;
protected
  list<String> names;
algorithm
  names := List.map(inEnumLiterals, SCode.enumName);
  outType := DAE.T_ENUMERATION(NONE(), inEnumPath, names, {}, {}, DAE.emptyTypeSource);
end makeEnumType;

protected function instEnumLiterals
  input list<SCode.Enum> inEnumLiterals;
  input Absyn.Path inEnumPath;
  input DAE.Type inType;
  input Integer inIndex;
  input list<Element> inAccumEl;
  output list<Element> outElements;
algorithm
  outElements := 
  match(inEnumLiterals, inEnumPath, inType, inIndex, inAccumEl)
    local
      SCode.Enum enum_lit;
      list<SCode.Enum> rest_lits;
      Element el;

    case ({}, _, _, _, _) then inAccumEl;

    case (enum_lit :: rest_lits, _, _, _, _)
      equation
        el = instEnumLiteral(enum_lit, inEnumPath, inType, inIndex);
      then
        instEnumLiterals(rest_lits, inEnumPath, inType, inIndex + 1, 
          el :: inAccumEl);

  end match;
end instEnumLiterals;

protected function instEnumLiteral
  input SCode.Enum inEnumLiteral;
  input Absyn.Path inEnumPath;
  input DAE.Type inType;
  input Integer inIndex;
  output Element outElement;
algorithm
  outElement := match(inEnumLiteral, inEnumPath, inType, inIndex)
    local
      String name;
      Absyn.Path path;
      Component comp;

    case (SCode.ENUM(literal = name), _, _, _)
      equation
        path = Absyn.suffixPath(inEnumPath, name);
        comp = TYPED_COMPONENT(path, inType, DEFAULT_CONST_PREFIXES,
          TYPED_BINDING(DAE.ENUM_LITERAL(path, inIndex), inType, 0, Absyn.dummyInfo), Absyn.dummyInfo);
      then
        ELEMENT(comp, BASIC_TYPE());

  end match;
end instEnumLiteral;

protected function instBinding
  input Binding inBinding;
  input Integer inCompDimensions;
  output Binding outBinding;
algorithm
  outBinding := match(inBinding, inCompDimensions)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      Env env;
      Prefix prefix;
      Integer pl, cd;
      Absyn.Info info;

    case (RAW_BINDING(aexp, env, prefix, pl, info), cd)
      equation
        dexp = instExp(aexp, env, prefix);
      then
        UNTYPED_BINDING(dexp, false, pl, info);

    else inBinding;

  end match;
end instBinding;

protected function instDimensions
  input list<Absyn.Subscript> inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Dimension> outDimensions;
algorithm
  outDimensions := List.map2(inSubscript, instDimension, inEnv, inPrefix);
end instDimensions;

protected function instDimension
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inSubscript, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (Absyn.NOSUB(), _, _) then DAE.DIM_UNKNOWN();

    case (Absyn.SUBSCRIPT(subscript = aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
      then
        makeDimension(dexp);

  end match;
end instDimension;

protected function makeDimensionArray
  input list<DAE.Dimension> inDimensions;
  output array<Dimension> outDimensions;
protected
  list<Dimension> dims;
algorithm
  dims := List.map(inDimensions, wrapDimension);
  outDimensions := listArray(dims);
end makeDimensionArray;

protected function wrapDimension
  input DAE.Dimension inDimension;
  output Dimension outDimension;
algorithm
  outDimension := UNTYPED_DIMENSION(inDimension, false);
end wrapDimension;
  
protected function makeDimension
  input DAE.Exp inExp;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inExp)
    local
      Integer idim;

    case DAE.ICONST(idim) then DAE.DIM_INTEGER(idim);
    else DAE.DIM_EXP(inExp);
  end match;
end makeDimension;

protected function instSubscripts
  input list<Absyn.Subscript> inSubscripts;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := List.map2(inSubscripts, instSubscript, inEnv, inPrefix);
end instSubscripts;

protected function instSubscript
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match(inSubscript, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (Absyn.NOSUB(), _, _) then DAE.WHOLEDIM();

    case (Absyn.SUBSCRIPT(subscript = aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
      then
        makeSubscript(dexp);

  end match;
end instSubscript;

protected function makeSubscript
  input DAE.Exp inExp;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match(inExp)
    case DAE.RANGE(ty = _)
      then DAE.SLICE(inExp);

    else DAE.INDEX(inExp);

  end match;
end makeSubscript;

protected function liftArrayType
  input Absyn.ArrayDim inDims;
  input DAE.Type inType;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Type outType;
algorithm
  outType := match(inDims, inType, inEnv, inPrefix)
    local
      DAE.Dimensions dims1, dims2;
      DAE.TypeSource src;
      DAE.Type ty;

    case ({}, _, _, _) then inType;
    case (_, DAE.T_ARRAY(ty, dims1, src), _, _)
      equation
        dims2 = List.map2(inDims, instDimension, inEnv, inPrefix);
        dims1 = listAppend(dims2, dims1);
      then
        DAE.T_ARRAY(ty, dims1, src);

    else
      equation
        dims2 = List.map2(inDims, instDimension, inEnv, inPrefix);
      then
        DAE.T_ARRAY(inType, dims2, DAE.emptyTypeSource);
  
  end match;
end liftArrayType;

protected function addDimensionsFromType
  input list<DAE.Dimension> inDimensions;
  input DAE.Type inType;
  output list<DAE.Dimension> outDimensions;
  output Integer outAddedDims;
algorithm
  (outDimensions, outAddedDims) := match(inDimensions, inType)
    local
      list<DAE.Dimension> dims;
      Integer added_dims;

    case (_, DAE.T_ARRAY(dims = dims))
      equation
        added_dims = listLength(dims);
        dims = listAppend(dims, inDimensions);
      then
        (dims, added_dims);

    else (inDimensions, 0);

  end match;
end addDimensionsFromType;

protected function instExpList
  input list<Absyn.Exp> inExp;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Exp> outExp;
algorithm
  outExp := List.map2(inExp, instExp, inEnv, inPrefix);
end instExpList;

protected function instExpOpt
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input Prefix inPrefix;
  output Option<DAE.Exp> outExp;
algorithm
  outExp := match(inExp, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (SOME(aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
      then
        SOME(dexp);

    else NONE();

  end match;
end instExpOpt;

protected function instExp
  input Absyn.Exp inExp;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inEnv, inPrefix)
    local
      Integer ival;
      Real rval;
      String sval;
      Boolean bval;
      Absyn.ComponentRef acref;
      DAE.ComponentRef dcref;
      Absyn.Exp aexp1, aexp2;
      DAE.Exp dexp1, dexp2;
      Absyn.Operator aop;
      DAE.Operator dop;
      list<Absyn.Exp> aexpl, afargs;
      list<DAE.Exp> dexpl, dfargs;
      list<list<Absyn.Exp>> mat_expl;
      list<Absyn.NamedArg> named_args;
      Absyn.Path path;
      Option<Absyn.Exp> oaexp;
      Option<DAE.Exp> odexp;

    case (Absyn.REAL(value = rval), _, _) then DAE.RCONST(rval);
    case (Absyn.INTEGER(value = ival), _, _) then DAE.ICONST(ival);
    case (Absyn.BOOL(value = bval), _, _) then DAE.BCONST(bval);
    case (Absyn.STRING(value = sval), _, _) then DAE.SCONST(sval);
    case (Absyn.CREF(componentRef = acref), _, _) 
      equation
        dcref = instCref(acref, inEnv, inPrefix);
      then
        DAE.CREF(dcref, DAE.T_UNKNOWN_DEFAULT);

    case (Absyn.BINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.BINARY(dexp1, dop, dexp2);

    case (Absyn.UNARY(op = aop, exp = aexp1), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.UNARY(dop, dexp1);

    case (Absyn.LBINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.LBINARY(dexp1, dop, dexp2);

    case (Absyn.LUNARY(op = aop, exp = aexp1), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        //dop = instOperator(aop);
        dop = DAE.NOT(DAE.T_BOOL_DEFAULT);
      then
        DAE.LUNARY(dop, dexp1);

    case (Absyn.RELATION(exp1 = aexp1, op = aop, exp2 = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
        dop = instOperator(aop);
      then
        DAE.RELATION(dexp1, dop, dexp2, -1, NONE());

    case (Absyn.ARRAY(arrayExp = aexpl), _, _)
      equation
        dexp1 = instArray(aexpl, inEnv, inPrefix);
      then
        dexp1;

    case (Absyn.MATRIX(matrix = mat_expl), _, _)
      equation
        dexpl = List.map2(mat_expl, instArray, inEnv, inPrefix);
      then
        DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, dexpl);

    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1, aexp2})), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
      then
        DAE.SIZE(dexp1, SOME(dexp2));

    case (Absyn.CALL(function_ = acref, 
        functionArgs = Absyn.FUNCTIONARGS(afargs, named_args)), _, _)
      equation
        dexp1 = instFunctionCall(acref, afargs, named_args, inEnv, inPrefix);
      then
        dexp1;

    case (Absyn.RANGE(start = aexp1, step = oaexp, stop = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        odexp = instExpOpt(oaexp, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
      then
        DAE.RANGE(DAE.T_UNKNOWN_DEFAULT, dexp1, odexp, dexp2);

    case (Absyn.TUPLE(expressions = aexpl), _, _)
      equation
        dexpl = instExpList(aexpl, inEnv, inPrefix);
      then
        DAE.TUPLE(dexpl);

    case (Absyn.LIST(exps = aexpl), _, _)
      equation
        dexpl = instExpList(aexpl, inEnv, inPrefix);
      then
        DAE.LIST(dexpl);

    case (Absyn.CONS(head = aexp1, rest = aexp2), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
      then
        DAE.CONS(dexp1, dexp2);

    //Absyn.PARTEVALFUNCTION
    //Absyn.END
    //Absyn.CODE
    //Absyn.AS
    //Absyn.MATCHEXP

    else DAE.SCONST("fixme");
  end match;
end instExp;

protected function instArray
  input list<Absyn.Exp> inExpl;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Exp outArray;
protected
  list<DAE.Exp> expl;
algorithm
  expl := List.map2(inExpl, instExp, inEnv, inPrefix);
  outArray := DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, expl);
end instArray;

protected function instOperator
  input Absyn.Operator inOperator;
  output DAE.Operator outOperator;
algorithm
  outOperator := match(inOperator)
    case Absyn.ADD() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.SUB() then DAE.SUB(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.MUL() then DAE.MUL(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.DIV() then DAE.DIV(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.POW() then DAE.POW(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UPLUS() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UMINUS() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.ADD_EW() then DAE.ADD_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.SUB_EW() then DAE.SUB_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.MUL_EW() then DAE.MUL_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.DIV_EW() then DAE.DIV_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.POW_EW() then DAE.POW_ARR2(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UPLUS_EW() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UMINUS_EW() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.AND() then DAE.AND(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.OR() then DAE.OR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.NOT() then DAE.NOT(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.LESS() then DAE.LESS(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.LESSEQ() then DAE.LESSEQ(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.GREATER() then DAE.GREATER(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.GREATEREQ() then DAE.GREATEREQ(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.EQUAL() then DAE.EQUAL(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.NEQUAL() then DAE.NEQUAL(DAE.T_UNKNOWN_DEFAULT);
  end match;
end instOperator;

protected function originString
  input SCodeLookup.Origin inOrigin;
  output String outString;
algorithm
  outString := match(inOrigin)
    case SCodeLookup.INSTANCE_ORIGIN() then "instance origin";
    case SCodeLookup.CLASS_ORIGIN() then "class origin";
    case SCodeLookup.BUILTIN_ORIGIN() then "builtin origin";
  end match;
end originString;

protected function instCref
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnv, inPrefix)
    local
      Absyn.ComponentRef acref;
      DAE.ComponentRef cref;
      SCode.Variability var;
      SCodeLookup.Origin origin;

    case (Absyn.WILD(), _, _) then DAE.WILD();
    case (Absyn.ALLWILD(), _, _) then DAE.WILD();
    case (Absyn.CREF_FULLYQUALIFIED(acref), _, _)
      equation
        cref = instCref2(acref, inEnv, inPrefix);
      then
        cref;

    case (_, _, _)
      equation
        cref = instGlobalConstantCref(inCref, inEnv, inPrefix);
      then
        cref;

    else
      equation
        cref = instCref2(inCref, inEnv, inPrefix);
        cref = prefixCref(cref, inPrefix);
      then
        cref;
      
  end matchcontinue;
end instCref;
        
protected function instGlobalConstantCref
  "Instantiates a global constant cref. A global constant is a constant that
   comes from a package and not a class instance, i.e. it's available anywhere."
  input Absyn.ComponentRef inName;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.ComponentRef outName;
algorithm
  outName := match(inName, inEnv, inPrefix)
    local
      Absyn.Path path;
      Env env;
      String name;
      DAE.ComponentRef cref;
      SCodeLookup.Origin origin;

    // Package constants must be in a package, so we only need to check
    // qualified crefs.
    case (Absyn.CREF_QUAL(name = _), _, _)
      equation
        path = Absyn.crefToPath(inName);
        (SCodeEnv.VAR(var = SCode.COMPONENT(name = name, attributes = SCode.ATTR(
            variability = SCode.CONST()))), path, env, origin) =
          SCodeLookup.lookupName(path, inEnv, Absyn.dummyInfo, NONE());
        true = SCodeLookup.originIsGlobal(origin);
        path = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), env);
        cref = ComponentReference.pathToCref(path);
      then
        cref;
        
  end match;
end instGlobalConstantCref;

protected function instCref2
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inEnv, inPrefix)
    local
      String name;
      Absyn.ComponentRef cref;
      DAE.ComponentRef dcref;
      list<Absyn.Subscript> asubs;
      list<DAE.Subscript> dsubs;

    case (Absyn.CREF_IDENT(name, asubs), _, _)
      equation
        dsubs = instSubscripts(asubs, inEnv, inPrefix);
      then
        DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, dsubs);

    case (Absyn.CREF_QUAL(name, asubs, cref), _, _)
      equation
        dsubs = instSubscripts(asubs, inEnv, inPrefix);
        dcref = instCref2(cref, inEnv, inPrefix);
      then
        DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, dsubs, dcref);

    case (Absyn.CREF_FULLYQUALIFIED(cref), _, _)
      then instCref2(cref, inEnv, inPrefix);

  end match;
end instCref2;

protected function prefixCref
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inPrefix)
    local
      String name;
      Prefix rest_prefix;
      DAE.ComponentRef cref;

    case (_, {}) then inCref;
    case (_, {(name, _)}) then DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
    case (_, (name, _) :: rest_prefix)
      equation
        cref = DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
      then
        prefixCref(cref, rest_prefix);

  end match;
end prefixCref;
 
protected function prefixToCref
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inPrefix)
    local
      String name;
      Prefix rest_prefix;
      DAE.ComponentRef cref;

    case ({(name, _)}) then DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {});
    case ((name, _) :: rest_prefix)
      equation
        cref = DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {});
      then
        prefixCref(cref, rest_prefix);

  end match;
end prefixToCref;

protected function prefixPath
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath, inPrefix)
    local
      String name;
      Prefix rest_prefix;
      Absyn.Path path;

    case (_, {}) then inPath;
    case (_, {(name, _)}) then Absyn.QUALIFIED(name, inPath);
    case (_, (name, _) :: rest_prefix)
      equation
        path = Absyn.QUALIFIED(name, inPath);
      then
        prefixPath(path, rest_prefix);

  end match;
end prefixPath;

protected function prefixToPath
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPrefix)
    local
      String name;
      Prefix rest_prefix;
      Absyn.Path path;

    case ({(name, _)}) then Absyn.IDENT(name);
    case ((name, _) :: rest_prefix)
      equation
        path = Absyn.IDENT(name);
      then
        prefixPath(path, rest_prefix);

  end match;
end prefixToPath;

protected function pathPrefix
  input Absyn.Path inPath;
  output Prefix outPrefix;
algorithm
  outPrefix := pathPrefix2(inPath, {});
end pathPrefix;

protected function pathPrefix2
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inPath, inPrefix)
    local
      Absyn.Path path;
      String name;
      Prefix prefix;

    case (Absyn.QUALIFIED(name, path), _)
      then pathPrefix2(path, (name, {}) :: inPrefix);

    case (Absyn.IDENT(name), _)
      then (name, {}) :: inPrefix;

    case (Absyn.FULLYQUALIFIED(path), _)
      then pathPrefix2(path, inPrefix);

  end match;
end pathPrefix2;

protected function instFunctionCall
  input Absyn.ComponentRef inName;
  input list<Absyn.Exp> inPositionalArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Exp outCallExp;
algorithm
  outCallExp := match(inName, inPositionalArgs, inNamedArgs, inEnv, inPrefix)
    local
      Absyn.Path call_path;
      DAE.ComponentRef cref;
      list<DAE.Exp> pos_args;

    case (_, _, _, _, _)
      equation
        call_path = instFunctionName(inName, inEnv, inPrefix);
        pos_args = instExpList(inPositionalArgs, inEnv, inPrefix);
      then
        DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther);

  end match;
end instFunctionCall;

protected function instFunctionName
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  output Absyn.Path outName;
algorithm
  outName := matchcontinue(inCref, inEnv, inPrefix)
    local
      Absyn.Path path;
      Item item;
      SCodeLookup.Origin origin;
      Env env;

    case (_, _, _)
      equation
        path = Absyn.crefToPath(inCref);
        (item, _, env, origin) =
          SCodeLookup.lookupFunctionName(path, inEnv, Absyn.dummyInfo);
        path = instFunctionName2(item, path, origin, env, inPrefix);
      then
        path;

  end matchcontinue;
end instFunctionName;

protected function instFunctionName2
  input Item inItem;
  input Absyn.Path inPath;
  input SCodeLookup.Origin inOrigin;
  input Env inEnv;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inItem, inPath, inOrigin, inEnv, inPrefix)
    local
      String name;
      Absyn.Path path;

    // The name of a builtin function should not be prefixed.
    case (_, _, SCodeLookup.BUILTIN_ORIGIN(), _, _)
      then inPath;

    // A qualified name with class origin should be prefixed with the package
    // name.
    case (_, Absyn.QUALIFIED(name = _), SCodeLookup.CLASS_ORIGIN(), _, _)
      equation
        name = SCodeEnv.getItemName(inItem);
        path = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), inEnv);
      then
        path;

    // A name with instance origin or a non-qualified name with class origin
    // (i.e. a local name), should be prefixed with the instance prefix.
    else
      equation
        path = prefixPath(inPath, inPrefix);
      then
        path;

  end match;
end instFunctionName2;

protected function instEquations
  input list<SCode.Equation> inEquations;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Element> outEquations;
algorithm
  //outEquations := List.map2(inEquations, instEquation, inEnv, inPrefix);
  outEquations := {};
end instEquations;

protected function instEquation
  input SCode.Equation inEquation;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Element outEquation;
protected
  SCode.EEquation eq; 
algorithm
  SCode.EQUATION(eEquation = eq) := inEquation;
  outEquation := instEEquation(eq, inEnv, inPrefix);
end instEquation;

protected function instEEquation
  input SCode.EEquation inEquation;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Element outEquation;
algorithm
  outEquation := match(inEquation, inEnv, inPrefix)
    local
      Absyn.Exp exp1, exp2;
      DAE.Exp dexp1, dexp2;

    case (SCode.EQ_EQUALS(exp1, exp2, _, _), _, _)
      equation
        dexp1 = instExp(exp1, inEnv, inPrefix);
        dexp2 = instExp(exp2, inEnv, inPrefix);
      then
        DAE.EQUATION(dexp1, dexp2, DAE.emptyElementSource);

    else
      equation
        print("Unknown equation in SCodeInst.instEEquation.\n");
      then
        fail();

  end match;
end instEEquation;

protected function instGlobalConstants
  input list<Absyn.Path> inGlobalConstants;
  input Env inEnv;
  output list<Element> outElements;
algorithm
  outElements := matchcontinue(inGlobalConstants, inEnv)
    local
      list<Element> el;
      Element ss;

    case (_, _)
      equation
        el = List.map1(inGlobalConstants, instGlobalConstant, inEnv);
        ss = instGlobalConstant2(SCodeLookup.BUILTIN_STATESELECT,
          Absyn.IDENT("StateSelect"), {});
      then
        ss :: el;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instGlobalConstants failed\n");
      then
        fail();

  end matchcontinue;
end instGlobalConstants;

protected function instGlobalConstant
  input Absyn.Path inPath;
  input Env inEnv;
  output Element outElement;
algorithm
  outElement := matchcontinue(inPath, inEnv)
    local
      Item item;
      Env env;
      
    case (_, _)
      equation
        (item, _, env) = SCodeLookup.lookupFullyQualified(inPath, inEnv);
      then
        instGlobalConstant2(item, inPath, env);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instGlobalConstant failed on " +&
          Absyn.pathString(inPath) +& "\n");
      then
        fail();

  end matchcontinue;
end instGlobalConstant;

protected function instGlobalConstant2
  input Item inItem;
  input Absyn.Path inPath;
  input Env inEnv;
  output Element outElement;
algorithm
  outElement := matchcontinue(inItem, inPath, inEnv)
    local
      Absyn.Path pre_path;
      Prefix prefix;
      SCode.Element el;
      list<SCode.Enum> enuml;
      DAE.Type ty, arr_ty;
      list<Element> enum_el;
      list<DAE.Exp> enum_exps;
      Integer enum_count;
      DAE.Exp bind_exp;
      Binding binding;
      Absyn.Info info;

    case (SCodeEnv.VAR(var = el), _, _)
      equation
        pre_path = Absyn.pathPrefix(inPath);
        prefix = pathPrefix(pre_path);
      then
        instElement(el, NOMOD(), NO_PREFIXES(), inEnv, prefix);

    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef = 
        SCode.ENUMERATION(enumLst = enuml), info = info)), _, _)
      equation
        // Instantiate the literals.
        ty = makeEnumType(enuml, inPath);
        enum_el = instEnumLiterals(enuml, inPath, ty, 1, {});
        // Create a binding for the enumeration type, i.e. an array of all
        // literals.
        enum_exps = List.map(enum_el, makeEnumExpFromElement);
        enum_count = listLength(enum_exps);
        arr_ty = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(enum_count)}, DAE.emptyTypeSource);
        bind_exp = DAE.ARRAY(arr_ty, true, enum_exps);
        binding = TYPED_BINDING(bind_exp, arr_ty, 1, info);
      then
        ELEMENT(TYPED_COMPONENT(inPath, ty, DEFAULT_CONST_PREFIXES, UNBOUND(), info),
          COMPLEX_CLASS(enum_el, {}, {}, {}, {}));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instGlobalConstant failed on " +&
          Absyn.pathString(inPath) +& "\n");
      then
        fail();

  end matchcontinue;
end instGlobalConstant2;

protected function makeEnumExpFromElement
  input Element inElement;
  output DAE.Exp outExp;
algorithm
  ELEMENT(component = TYPED_COMPONENT(binding = 
    TYPED_BINDING(bindingExp = outExp))) := inElement;
end makeEnumExpFromElement;

protected function countElementsInClass
  input Class inClass;
  output Integer outElements;
algorithm
  outElements := match(inClass)
    local
      list<Element> comps;
      Integer count;

    case BASIC_TYPE() then 0;

    case COMPLEX_CLASS(components = comps)
      equation
        count = List.fold(comps, countElementsInElement, 0);
      then
        count;

  end match;
end countElementsInClass;

protected function countElementsInElement
  input Element inElement;
  input Integer inCount;
  output Integer outCount;
algorithm
  outCount := match(inElement, inCount)
    local
      Class cls;

    case (ELEMENT(cls = cls), _)
      then 1 + countElementsInClass(cls) + inCount;

    case (CONDITIONAL_ELEMENT(component = _), _)
      then 1 + inCount;

    case (EXTENDED_ELEMENTS(cls = cls), _)
      then countElementsInClass(cls) + inCount;

  end match;
end countElementsInElement;

protected function buildSymbolTable
  input Class inClass;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass)
    local
      SymbolTable symtab;
      Integer comp_size, bucket_size;
      Class cls;

    case (_)
      equation
        // Set the bucket size to the nearest prime of the number of components
        // multiplied with 4/3, to get ~75% occupancy.
        comp_size = countElementsInClass(inClass);
        bucket_size = Util.nextPrime(intDiv((comp_size * 4), 3));
        symtab = emptySymbolTableSized(bucket_size);
        (cls, symtab) = fillSymbolTable(inClass, symtab);
      then
        (cls, symtab);

  end match;
end buildSymbolTable;

protected function fillSymbolTable
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      list<Element> comps;
      list<DAE.Element> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      SymbolTable st;

    case (BASIC_TYPE(), st) then (inClass, st);

    case (COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        (comps, st) = addElementsToSymbolTable(comps, st);
      then
        (COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

  end match;
end fillSymbolTable;

protected function addElementsToSymbolTable
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) :=
    addElementsToSymbolTable2(inElements, inSymbolTable, {});
end addElementsToSymbolTable;

protected function addElementsToSymbolTable2
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) := match(inElements, inSymbolTable, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      Boolean added;
      SymbolTable st;

    case ({}, st, _) then (inAccumEl, st);

    case (el :: rest_el, st, _)
      equation
        (el, st, added) = addElementToSymbolTable(el, st);
        accum_el = List.consOnTrue(added, el, inAccumEl);
        (rest_el, st) = addElementsToSymbolTable2(rest_el, st, accum_el);
      then
        (rest_el, st);

  end match;
end addElementsToSymbolTable2;

protected function addElementToSymbolTable
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outElement, outSymbolTable, outAdded) := matchcontinue(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      SymbolTable st;
      Boolean added;
      Absyn.Path bc;
      DAE.Type ty;

    case (ELEMENT(comp, cls), st)
      equation
        (st, added) = addComponentToTable(comp, st);
        (cls, st) = fillSymbolTableOnTrue(cls, st, added);
      then
        (ELEMENT(comp, cls), st, added);

    case (CONDITIONAL_ELEMENT(comp), st)
      equation
        (st, added) = addComponentToTable(comp, st);
      then
        (CONDITIONAL_ELEMENT(comp), st, added);

    case (EXTENDED_ELEMENTS(bc, cls, ty), st)
      equation
        (cls, st) = fillSymbolTable(cls, st);
      then
        (EXTENDED_ELEMENTS(bc, cls, ty), st, true);

  end matchcontinue;
end addElementToSymbolTable;

protected function fillSymbolTableOnTrue
  input Class inClass;
  input SymbolTable inSymbolTable;
  input Boolean inCondition;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable, inCondition)
    local
      Class cls;
      SymbolTable st;

    case (cls, st, false) then (cls, st);
    case (cls, st, true)
      equation
        (cls, st) = fillSymbolTable(cls, st);
      then
        (cls, st);

  end match;
end fillSymbolTableOnTrue;

protected function addComponentToTable
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outSymbolTable, outAdded) := matchcontinue(inComponent, inSymbolTable) 
    local
      Absyn.Path name;
      Option<Component> comp;
      SymbolTable st;
      Boolean added;

    case (_, st)
      equation
        name = getComponentName(inComponent);
        comp = lookupNameInTable(name, st);
        (st, added) = addOptionalComponentToTable(name, inComponent, comp, st);
      then
        (st, added);

    else
      equation
        print("Failed to add unknown component to symbol table!\n");
      then
        (inSymbolTable, false);

  end matchcontinue;
end addComponentToTable;

protected function addOptionalComponentToTable
  input Absyn.Path inName;
  input Component inNewComponent;
  input Option<Component> inOldComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outSymbolTable, outAdded) :=
  match(inName, inNewComponent, inOldComponent, inSymbolTable)
    local
      Component comp;
      SymbolTable st;

    case (_, comp, NONE(), st)
      equation
        st = BaseHashTable.addNoUpdCheck((inName, comp), st);
      then
        (st, true);

    case (_, _, SOME(comp), st)
      equation
        //checkEqualComponents
      then
        (inSymbolTable, false);

  end match;
end addOptionalComponentToTable;

protected function addInstCondElementToTable
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outElement, outSymbolTable, outAdded) := match(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path name;
      Option<Component> opt_comp;
      Boolean added;
      SymbolTable st;

    case (ELEMENT(comp, cls), st)
      equation
        name = getComponentName(comp);
        opt_comp = lookupNameInTable(name, st);
        (st, added) = addInstCondComponentToTable(name, comp, opt_comp, st);
        (cls, st) = fillSymbolTableOnTrue(cls, st, added);
      then
        (ELEMENT(comp, cls), st, added);

  end match;
end addInstCondElementToTable;
    
protected function addInstCondComponentToTable
  input Absyn.Path inName;
  input Component inNewComponent;
  input Option<Component> inOldComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
  output Boolean outAdded;
algorithm
  (outSymbolTable, outAdded) :=
  match(inName, inNewComponent, inOldComponent, inSymbolTable)
    local
      Component comp;
      SymbolTable st;

    case (_, _, SOME(CONDITIONAL_COMPONENT(name = _)), st)
      equation
        st = BaseHashTable.addNoUpdCheck((inName, inNewComponent), st);
      then
        (st, true);

    case (_, _, SOME(comp), st)
      equation
        //checkEqualComponents
      then
        (st, false);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.addInstCondElementToTable couldn't find existing conditional component!\n"});
      then
        fail();
  end match;
end addInstCondComponentToTable;

public function getComponentName
  input Component inComponent;
  output Absyn.Path outName;
algorithm
  outName := match(inComponent)
    local
      Absyn.Path name;

    case UNTYPED_COMPONENT(name = name) then name;
    case TYPED_COMPONENT(name = name) then name;
    case CONDITIONAL_COMPONENT(name = name) then name;
    case OUTER_COMPONENT(name = name) then name;

  end match;
end getComponentName;

protected function typeClass
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      list<Element> comps;
      list<DAE.Element> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      SymbolTable st;

    case (BASIC_TYPE(), st) then (inClass, st);

    case (COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        (comps, st) = List.mapFold(comps, typeElement, st);
      then
        (COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

  end match;
end typeClass;

protected function typeElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := match(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path name;
      SymbolTable st;
      DAE.Type ty;

    case (ELEMENT(comp as UNTYPED_COMPONENT(name = name), cls), st)
      equation
        comp = BaseHashTable.get(name, st);
        (comp, st) = typeComponent(comp, st);
        (cls, st) = typeClass(cls, st);
      then
        (ELEMENT(comp, cls), st);

    case (ELEMENT(comp, cls), st)
      equation
        (cls, st) = typeClass(cls, st);
      then
        (ELEMENT(comp, cls), st);

    case (EXTENDED_ELEMENTS(name, cls, ty), st)
      equation
        (cls, st) = typeClass(cls, st);
      then
        (EXTENDED_ELEMENTS(name, cls, ty), st);

    else (inElement, inSymbolTable);

  end match;
end typeElement;

protected function typeComponent
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := match(inComponent, inSymbolTable)
    local
      Absyn.Path name, inner_name;
      DAE.Type ty;
      Binding binding;
      list<Dimension> dims;
      SymbolTable st;
      Component comp, inner_comp;
      SCode.Variability var;

    case (UNTYPED_COMPONENT(name = name, baseType = ty, binding = binding), st)
      equation
        (ty, st) = typeComponentDims(inComponent, st);
        (comp, st ) = typeComponentBinding(inComponent, SOME(ty), st);
      then
        (comp, st);

    case (TYPED_COMPONENT(name = _), st) then (inComponent, st);

    case (OUTER_COMPONENT(innerName = SOME(name)), st)
      equation
        comp = BaseHashTable.get(name, st);
        (comp, st) = typeComponent(comp, st);
      then
        (comp, st);

    case (OUTER_COMPONENT(name = name, innerName = NONE()), st)
      equation
        (_, SOME(inner_comp), st) = updateInnerReference(inComponent, st);
        (inner_comp, st) = typeComponent(inner_comp, st);
      then
        (inner_comp, st);

    case (CONDITIONAL_COMPONENT(name = name), _)
      equation
        print("Trying to type conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

  end match;
end typeComponent;

protected function updateInnerReference
  input Component inOuterComponent;
  input SymbolTable inSymbolTable;
  output Absyn.Path outInnerName;
  output Option<Component> outInnerComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outInnerName, outInnerComponent, outSymbolTable) :=
  match(inOuterComponent, inSymbolTable)
    local
      Absyn.Path outer_name, inner_name;
      Component outer_comp, inner_comp;
      SymbolTable st;

    case (OUTER_COMPONENT(name = outer_name, innerName = NONE()), st)
      equation
        (inner_name, inner_comp) = findInnerComponent(outer_name, st); 
        outer_comp = OUTER_COMPONENT(outer_name, SOME(inner_name));
        st = BaseHashTable.add((outer_name, outer_comp), st);
      then
        (inner_name, SOME(inner_comp), st);
        
    case (OUTER_COMPONENT(innerName = SOME(inner_name)), st)
      then (inner_name, NONE(), st);

  end match;
end updateInnerReference;

protected function typeComponentDims
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outType, outSymbolTable) := matchcontinue(inComponent, inSymbolTable)
    local
      DAE.Type ty;
      SymbolTable st;
      array<Dimension> dims;
      list<DAE.Dimension> typed_dims;
      Absyn.Path name;

    case (UNTYPED_COMPONENT(baseType = ty, dimensions = dims), st)
      equation
        true = intEq(0, arrayLength(dims));
      then
        (ty, st);

    case (UNTYPED_COMPONENT(name = name, baseType = ty, dimensions = dims), st)
      equation
        (typed_dims, st) = typeDimensions(dims, name, st);
      then
        (DAE.T_ARRAY(ty, typed_dims, DAE.emptyTypeSource), st);
        
    case (TYPED_COMPONENT(ty = ty), st) then (ty, st);

  end matchcontinue;
end typeComponentDims;

protected function typeComponentDim
  input Component inComponent;
  input Integer inIndex;
  input SymbolTable inSymbolTable;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) := match(inComponent, inIndex, inSymbolTable)
    local
      list<DAE.Dimension> dims;
      DAE.Dimension typed_dim;
      SymbolTable st;
      array<Dimension> dims_arr;
      Dimension dim;
      Absyn.Path name;

    case (TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), _, st)
      equation
        typed_dim = listGet(dims, inIndex);
      then
        (typed_dim, st);

    case (UNTYPED_COMPONENT(name = name, dimensions = dims_arr), _, st)
      equation
        dim = arrayGet(dims_arr, inIndex);
        (typed_dim, st) = typeDimension(dim, name, st, dims_arr, inIndex);
      then
        (typed_dim, st);

  end match;
end typeComponentDim;
        
protected function typeDimensions
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input SymbolTable inSymbolTable;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
protected
  Integer len;
algorithm
  len := arrayLength(inDimensions);
  (outDimensions, outSymbolTable) := 
  typeDimensions2(inDimensions, inComponentName, inSymbolTable, 1, len, {});
end typeDimensions;

protected function typeDimensions2
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input SymbolTable inSymbolTable;
  input Integer inIndex;
  input Integer inLength;
  input list<DAE.Dimension> inAccDims;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
algorithm
  (outDimensions, outSymbolTable) :=
  matchcontinue(inDimensions, inComponentName, inSymbolTable, inIndex, inLength, inAccDims)
    local
      Dimension dim;
      DAE.Dimension typed_dim;
      SymbolTable st;
      list<DAE.Dimension> dims;

    case (_, _, _, _, _, _)
      equation
        true = inIndex > inLength;
      then
        (listReverse(inAccDims), inSymbolTable);

    else
      equation
        dim = arrayGet(inDimensions, inIndex);
        (typed_dim, st) = 
          typeDimension(dim, inComponentName, inSymbolTable, inDimensions, inIndex);
        (dims, st) = typeDimensions2(inDimensions, inComponentName, st, inIndex + 1,
          inLength, typed_dim :: inAccDims);
      then
        (dims, st);

  end matchcontinue;
end typeDimensions2;

protected function typeDimension
  input Dimension inDimension;
  input Absyn.Path inComponentName;
  input SymbolTable inSymbolTable;
  input array<Dimension> inDimensions;
  input Integer inIndex;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) := 
  match(inDimension, inComponentName, inSymbolTable, inDimensions, inIndex)
    local
      SymbolTable st;
      DAE.Dimension dim;
      DAE.Exp dim_exp;
      Integer dim_int, dim_count;
      Dimension typed_dim;
      Component comp;

    case (UNTYPED_DIMENSION(isProcessing = true), _, _, _, _)
      equation
        print("Found dimension loop\n");
      then
        fail();

    case (UNTYPED_DIMENSION(dimension = dim as DAE.DIM_EXP(exp = dim_exp)), _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, UNTYPED_DIMENSION(dim, true));
        (dim_exp, _, st) = typeExp(dim_exp, st);
        dim = makeDimension(dim_exp);
        typed_dim = TYPED_DIMENSION(dim);
        _ = arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (UNTYPED_DIMENSION(dimension = dim as DAE.DIM_UNKNOWN()), _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, UNTYPED_DIMENSION(dim, true));
        comp = BaseHashTable.get(inComponentName, st);
        (comp, st) = typeComponentBinding(comp, NONE(), st);
        dim_count = arrayLength(inDimensions);
        dim = getComponentBindingDimension(comp, inIndex, dim_count);
        typed_dim = TYPED_DIMENSION(dim);
        _ = arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (UNTYPED_DIMENSION(dimension = dim), _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, TYPED_DIMENSION(dim));
      then 
        (dim, st);

    case (TYPED_DIMENSION(dimension = dim), _, st, _, _) then (dim, st);

    else
      equation
        print("typeDimension got unknown dimension\n");
      then
        fail();

  end match;
end typeDimension;

protected function getComponentBinding
  input Component inComponent;
  output Binding outBinding;
algorithm
  outBinding := match(inComponent)
    local
      Binding binding;

    case UNTYPED_COMPONENT(binding = binding) then binding;
    case TYPED_COMPONENT(binding = binding) then binding;

  end match;
end getComponentBinding;

protected function getComponentBindingDimension
  input Component inComponent;
  input Integer inDimension;
  input Integer inCompDimensions;
  output DAE.Dimension outDimension;
protected
  Binding binding;
algorithm
  binding := getComponentBinding(inComponent);
  outDimension := getBindingDimension(binding, inDimension, inCompDimensions);
end getComponentBindingDimension;

protected function getBindingDimension
  input Binding inBinding;
  input Integer inDimension;
  input Integer inCompDimensions;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inBinding, inDimension, inCompDimensions)
    local
      DAE.Exp exp;
      Integer pd, index;
      Absyn.Info info;

    case (TYPED_BINDING(bindingExp = exp, propagatedDims = pd), _, _)
      equation
        index = Util.if_(intEq(pd, -1), inDimension,
          inDimension + pd - inCompDimensions);
      then
        getExpDimension(exp, index);

  end match;
end getBindingDimension;
  
protected function getExpDimension
  input DAE.Exp inExp;
  input Integer inDimIndex;
  output DAE.Dimension outDimension;
algorithm
  outDimension := matchcontinue(inExp, inDimIndex)
    local
      DAE.Type ty;
      list<DAE.Dimension> dims;
      DAE.Dimension dim;

    case (_, _)
      equation
        ty = Expression.typeof(inExp);
        dims = Types.getDimensions(ty);
        dim = listGet(dims, inDimIndex);
      then
        dim;

    else DAE.DIM_UNKNOWN();

  end matchcontinue;
end getExpDimension;
    
protected function typeComponentBinding
  input Component inComponent;
  input Option<DAE.Type> inType;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := match(inComponent, inType, inSymbolTable)
    local
      Absyn.Path name;
      Binding binding;
      SymbolTable st;
      Component comp;

    case (UNTYPED_COMPONENT(name = name, binding = binding), _, st)
      equation
        st = markComponentBindingAsProcessing(inComponent, st);
        (binding, st) = typeBinding(binding, st);
        comp = updateComponentBinding(inComponent, binding, inType);
        st = BaseHashTable.add((name, comp), st);
      then
        (comp, st);

    else (inComponent, inSymbolTable);

  end match;
end typeComponentBinding;

protected function updateComponentBinding
  input Component inComponent;
  input Binding inBinding;
  input Option<DAE.Type> inType;
  output Component outComponent;
algorithm
  outComponent := match(inComponent, inBinding, inType)
    local
      Absyn.Path name;
      DAE.Type ty;
      Prefixes pf;
      SCode.Element el;
      array<Dimension> dims;
      Absyn.Info info;
     
    case (UNTYPED_COMPONENT(name = name, prefixes = pf, info = info), _, SOME(ty))
      then TYPED_COMPONENT(name, ty, pf, inBinding, info);

    case (UNTYPED_COMPONENT(name, ty, dims, pf, _, info), _, NONE())
      then UNTYPED_COMPONENT(name, ty, dims, pf, inBinding, info);

  end match;
end updateComponentBinding;

protected function markComponentBindingAsProcessing
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inComponent, inSymbolTable)
    local
      Absyn.Path name;
      SCode.Element el;
      DAE.Type ty;
      array<Dimension> dims;
      Binding binding;
      Component comp;
      DAE.VarKind var;
      DAE.Exp binding_exp;
      Integer pl;
      Prefixes pf;
      Absyn.Info info1, info2;

    case (UNTYPED_COMPONENT(prefixes = PREFIXES(variability = var)), _)
      equation
        false = DAEUtil.isParamOrConstVarKind(var);
      then
        inSymbolTable;

    case (UNTYPED_COMPONENT(name, ty, dims, pf,
        UNTYPED_BINDING(binding_exp, _, pl, info1), info2), _)
      equation
        comp = UNTYPED_COMPONENT(name, ty, dims, pf,
          UNTYPED_BINDING(binding_exp, true, pl, info1), info2);
      then
        BaseHashTable.add((name, comp), inSymbolTable);

    case (UNTYPED_COMPONENT(binding = _), _) then inSymbolTable;

    else
      equation
        print("markComponentAsProcessing got unknown component\n");
      then
        fail();

  end matchcontinue;
end markComponentBindingAsProcessing;
      
protected function typeBinding
  input Binding inBinding;
  input SymbolTable inSymbolTable;
  output Binding outBinding;
  output SymbolTable outSymbolTable;
algorithm
  (outBinding, outSymbolTable) := match(inBinding, inSymbolTable)
    local
      DAE.Exp binding;
      SymbolTable st;
      DAE.Type ty;
      Integer pd;
      Absyn.Info info;

    case (UNTYPED_BINDING(isProcessing = true), st)
      equation
        showCyclicDepError(st);
      then
        fail();

    case (UNTYPED_BINDING(bindingExp = binding, propagatedDims = pd, info = info), st)
      equation
        (binding, ty, st) = typeExp(binding, st);
      then
        (TYPED_BINDING(binding, ty, pd, info), st);

    case (TYPED_BINDING(bindingExp = _), st)
      then (inBinding, st);

    else (UNBOUND(), inSymbolTable);

  end match;
end typeBinding;

protected function typeExpList
  input list<DAE.Exp> inExpList;
  input SymbolTable inSymbolTable;
  output list<DAE.Exp> outExpList;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExpList, outType, outSymbolTable) := match(inExpList, inSymbolTable)
    local
      DAE.Exp exp;
      list<DAE.Exp> rest_expl;
      SymbolTable st;
      DAE.Type ty;

    case ({}, st) then ({}, DAE.T_UNKNOWN_DEFAULT, st);

    case (exp :: rest_expl, st)
      equation
        (exp, ty, st) = typeExp(exp, st);
        (rest_expl, _, st) = typeExpList(rest_expl, st);
      then
        (exp :: rest_expl, ty, st);

  end match;
end typeExpList;

protected function typeExp
  input DAE.Exp inExp;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) := match(inExp, inSymbolTable)
    local
      DAE.Exp e1, e2, e3;
      DAE.ComponentRef cref;
      DAE.Type ty;
      SymbolTable st;
      DAE.Operator op;
      Component comp;
      Integer dim_int;
      DAE.Dimension dim;
      list<DAE.Exp> expl;

    case (DAE.ICONST(integer = _), st) then (inExp, DAE.T_INTEGER_DEFAULT, st);
    case (DAE.RCONST(real = _), st) then (inExp, DAE.T_REAL_DEFAULT, st);
    case (DAE.SCONST(string = _), st) then (inExp, DAE.T_STRING_DEFAULT, st);
    case (DAE.BCONST(bool = _), st) then (inExp, DAE.T_BOOL_DEFAULT, st);
    case (DAE.CREF(componentRef = cref), st)
      equation
        (e1, ty, st) = typeCref(cref, st);
      then
        (e1, ty, st);
        
    case (DAE.ARRAY(array = expl), st)
      equation
        (expl, ty, st) = typeExpList(expl, st);
        dim_int = listLength(expl);
        ty = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(dim_int)}, DAE.emptyTypeSource);
      then
        (DAE.ARRAY(ty, true, expl), ty, st);

    case (DAE.BINARY(exp1 = e1, operator = op, exp2 = e2), st)
      equation
        (e1, ty, st) = typeExp(e1, st);
        (e2, ty, st) = typeExp(e2, st);
      then
        (DAE.BINARY(e1, op, e2), ty, st);

    case (DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2), st)
      equation
        (e1, ty, st) = typeExp(e1, st);
        (e2, ty, st) = typeExp(e2, st);
      then
        (DAE.LBINARY(e1, op, e2), ty, st);

    case (DAE.LUNARY(operator = op, exp = e1), st)
      equation
        (e1, ty, st) = typeExp(e1, st);
      then
        (DAE.LUNARY(op, e1), ty, st);

    case (DAE.SIZE(exp = DAE.CREF(componentRef = cref), sz = SOME(e2)), st)
      equation
        (DAE.ICONST(dim_int), _, st) = typeExp(e2, st);
        comp = lookupCrefInTable(cref, st);
        (dim, st) = typeComponentDim(comp, dim_int, st);
        e1 = dimensionExp(dim);
      then
        (e1, DAE.T_INTEGER_DEFAULT, st);

    else (inExp, DAE.T_UNKNOWN_DEFAULT, inSymbolTable);
    //else
    //  equation
    //    print("typeExp: unknown expression " +&
    //        ExpressionDump.printExpStr(inExp) +& "\n");
    //  then
    //    fail();

  end match;
end typeExp;
    
protected function dimensionExp
  input DAE.Dimension inDimension;
  output DAE.Exp outExp;
algorithm
  outExp := match(inDimension)
    local
      Integer dim_int;
      DAE.Exp dim_exp;

    case (DAE.DIM_INTEGER(dim_int)) then DAE.ICONST(dim_int);
    case (DAE.DIM_EXP(dim_exp)) then dim_exp;

  end match;
end dimensionExp;
  
protected function typeCref
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) := matchcontinue(inCref, inSymbolTable)
    local
      Absyn.Path path;
      SymbolTable st;
      Component comp;
      DAE.Type ty;
      DAE.Exp exp;
      DAE.VarKind var;
      Boolean param_or_const;
      DAE.ComponentRef cref;

    case (_, st)
      equation
        comp = lookupCrefInTable(inCref, st);
        var = getComponentVariability(comp);
        param_or_const = DAEUtil.isParamOrConstVarKind(var);
        (exp, ty, st) = typeCref2(inCref, comp, param_or_const, st);
      then
        (exp, ty, st);

    case (_, st)
      equation
        (cref, st) = replaceCrefOuterPrefix(inCref, st);
        (exp, ty, st) = typeCref(cref, st);
      then
        (exp, ty, st);

    else
      equation
        print("Failed to type cref " +&
            ComponentReference.printComponentRefStr(inCref) +& "\n");
      then
        fail();

  end matchcontinue;
end typeCref;
        
protected function getComponentVariability
  input Component inComponent;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inComponent)
    local
      DAE.VarKind var;

    case UNTYPED_COMPONENT(prefixes = PREFIXES(variability = var)) then var;
    case TYPED_COMPONENT(prefixes = PREFIXES(variability = var)) then var;
    else DAE.VARIABLE();

  end match;
end getComponentVariability;

protected function typeCref2
  input DAE.ComponentRef inCref;
  input Component inComponent;
  input Boolean inIsParamOrConst;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) :=
  match(inCref, inComponent, inIsParamOrConst, inSymbolTable)
    local
      DAE.Type ty;
      Binding binding;
      SymbolTable st;
      DAE.Exp exp;
      Absyn.Path inner_name;
      Component inner_comp;
      DAE.ComponentRef inner_cref;

    case (_, TYPED_COMPONENT(ty = ty, binding = binding), true, st)
      equation
        exp = getBindingExp(binding);
      then
        (exp, ty, st);

    case (_, TYPED_COMPONENT(ty = ty), false, st)
      then (DAE.CREF(inCref, ty), ty, st);

    case (_, UNTYPED_COMPONENT(name = _), true, st)
      equation
        (TYPED_COMPONENT(ty = ty, binding = binding), st) =
          typeComponent(inComponent, st);
        exp = getBindingExp(binding);
      then
        (exp, ty, st);

    case (_, UNTYPED_COMPONENT(name = _), false, st)
      equation
        (ty, st) = typeComponentDims(inComponent, st);
      then
        (DAE.CREF(inCref, ty), ty, st);

    case (_, OUTER_COMPONENT(name = _), _, st)
      equation
        (inner_comp, st) = typeComponent(inComponent, st);
        inner_name = getComponentName(inner_comp);
        inner_cref = removeCrefOuterPrefix(inner_name, inCref);
        (exp, ty, st) = typeCref2(inner_cref, inner_comp, inIsParamOrConst, st);
      then
        (exp, ty, st);

  end match;
end typeCref2;

protected function getBindingExp
  input Binding inBinding;
  output DAE.Exp outExp;
algorithm
  outExp := match(inBinding)
    local
      DAE.Exp exp;

    case TYPED_BINDING(bindingExp = exp) then exp;
    else DAE.ICONST(0);
  end match;
end getBindingExp;

protected function lookupCrefInTable
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output Component outComponent;
protected
  Absyn.Path path;
algorithm
  path := ComponentReference.crefToPathIgnoreSubs(inCref);
  outComponent := BaseHashTable.get(path, inSymbolTable);
end lookupCrefInTable;

protected function lookupNameInTable
  input Absyn.Path inName;
  input SymbolTable inSymbolTable;
  output Option<Component> outComponent;
algorithm
  outComponent := matchcontinue(inName, inSymbolTable)
    local
      Component comp;

    case (_, _)
      equation
        comp = BaseHashTable.get(inName, inSymbolTable);
      then
        SOME(comp);

    else NONE();
  end matchcontinue;
end lookupNameInTable;

protected function showCyclicDepError
  input SymbolTable inSymbolTable;
algorithm
  _ := matchcontinue(inSymbolTable)
    local
      list<DAE.Exp> deps;
      String dep_str;

    case (_)
      equation
        deps = findCyclicDependencies(inSymbolTable);
        dep_str = 
          stringDelimitList(List.map(deps, ExpressionDump.printExpStr), ", ");
        dep_str = "{" +& dep_str +& "}";
        Error.addMessage(Error.CIRCULAR_COMPONENTS, {"FIX ME", dep_str});
      then
        ();

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Found cyclic dependencies, but failed to show error."});
      then
        fail();
  
  end matchcontinue;
end showCyclicDepError;

protected function findCyclicDependencies
  input SymbolTable inSymbolTable;
  output list<DAE.Exp> outDeps;
protected
  list<tuple<Absyn.Path, Component>> hash_list;
  list<tuple<DAE.Exp, list<DAE.Exp>>> dep_graph;
  list<DAE.Exp> deps;
algorithm
  hash_list := BaseHashTable.hashTableList(inSymbolTable);
  dep_graph := buildDependencyGraph(hash_list, {});
  (_, dep_graph) := Graph.topologicalSort(dep_graph, nodeEqual);
  {outDeps} := Graph.findCycles(dep_graph, nodeEqual);
end findCyclicDependencies;
  
protected function buildDependencyGraph
  input list<tuple<Absyn.Path, Component>> inComponents;
  input list<tuple<DAE.Exp, list<DAE.Exp>>> inAccumGraph;
  output list<tuple<DAE.Exp, list<DAE.Exp>>> outGraph;
algorithm
  outGraph := match(inComponents, inAccumGraph)
    local
      list<tuple<Absyn.Path, Component>> rest_comps;
      list<tuple<DAE.Exp, list<DAE.Exp>>> accum;
      Binding binding;
      array<Dimension> dims;
      list<Dimension> dimsl;
      Absyn.Path name;

    case ({}, _) then inAccumGraph;

    case ((name, UNTYPED_COMPONENT(binding = binding, dimensions = dims)) ::
        rest_comps, accum)
      equation
        accum = addBindingDependency(binding, name, accum);
        dimsl = arrayList(dims);
        //accum = List.fold(dimsl, addDimensionDependency, accum);
        accum = buildDependencyGraph(rest_comps, accum);
      then
        accum;

    case (_ :: rest_comps, accum)
      then buildDependencyGraph(rest_comps, accum);

  end match;
end buildDependencyGraph;
  
protected function addBindingDependency
  input Binding inBinding;
  input Absyn.Path inComponentName;
  input list<tuple<DAE.Exp, list<DAE.Exp>>> inAccumGraph;
  output list<tuple<DAE.Exp, list<DAE.Exp>>> outGraph;
algorithm
  outGraph := match(inBinding, inComponentName, inAccumGraph)
    local
      DAE.Exp bind_exp;
      list<DAE.Exp> deps;
      DAE.ComponentRef cref;
      tuple<DAE.Exp, list<DAE.Exp>> dep;

    case (UNTYPED_BINDING(bindingExp = bind_exp, isProcessing = true), _, _)
      equation
        deps = getDependenciesFromExp(bind_exp);
        cref = ComponentReference.pathToCref(inComponentName);
        dep = (DAE.CREF(cref, DAE.T_UNKNOWN_DEFAULT), deps);
      then
        dep :: inAccumGraph;

    else inAccumGraph;
  end match;
end addBindingDependency;

protected function getDependenciesFromExp
  input DAE.Exp inExp;
  output list<DAE.Exp> outDeps;
algorithm
  ((_, outDeps)) := Expression.traverseExp(inExp, expDependencyTraverser, {});
end getDependenciesFromExp;

protected function expDependencyTraverser
  input tuple<DAE.Exp, list<DAE.Exp>> inTuple;
  output tuple<DAE.Exp, list<DAE.Exp>> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.Exp exp;
      list<DAE.Exp> deps;

    case ((exp as DAE.CREF(componentRef = _), deps))
      then ((exp, exp :: deps));

    else inTuple;

  end match;
end expDependencyTraverser;

protected function nodeEqual
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inExp1, inExp2)
    local
      DAE.ComponentRef cref1, cref2;

    case (DAE.CREF(componentRef = cref1), DAE.CREF(componentRef = cref2))
      then ComponentReference.crefEqualNoStringCompare(cref1, cref2);

    else false;

  end match;
end nodeEqual;

protected function removeCrefOuterPrefix
  input Absyn.Path inInnerPath;
  input DAE.ComponentRef inOuterCref;
  output DAE.ComponentRef outInnerCref;
algorithm
  outInnerCref := match(inInnerPath, inOuterCref)
    local
      Absyn.Path path;
      DAE.ComponentRef cref;
      String id, err_msg;
      DAE.Type ty;
      list<DAE.Subscript> subs;

    case (Absyn.IDENT(name = _), _)
      equation
        cref = ComponentReference.crefLastCref(inOuterCref);
      then
        cref;

    case (Absyn.QUALIFIED(path = path), DAE.CREF_QUAL(id, ty, subs, cref))
      equation
        cref = removeCrefOuterPrefix(path, cref);
      then
        DAE.CREF_QUAL(id, ty, subs, cref);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        err_msg = "SCodeInst.removeCrefOuterPrefix failed on inner path " +&
          Absyn.pathString(inInnerPath) +& " and outer cref " +&
          ComponentReference.printComponentRefStr(inOuterCref);
        Debug.traceln(err_msg);
      then
        fail();

  end match;
end removeCrefOuterPrefix;

protected function replaceCrefOuterPrefix
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output DAE.ComponentRef outCref;
  output SymbolTable outSymbolTable;
algorithm
  (outCref, outSymbolTable) := match(inCref, inSymbolTable)
    local
      DAE.ComponentRef prefix_cref, rest_cref, cref;
      SymbolTable st;
    
    case (_, st)
      equation
        (prefix_cref, rest_cref) = ComponentReference.splitCrefLast(inCref);
        (cref, st) = replaceCrefOuterPrefix2(prefix_cref, rest_cref, st);
      then
        (cref, st);
        
  end match;
end replaceCrefOuterPrefix;

protected function replaceCrefOuterPrefix2
  input DAE.ComponentRef inPrefixCref;
  input DAE.ComponentRef inSuffixCref;
  input SymbolTable inSymbolTable;
  output DAE.ComponentRef outNewCref;
  output SymbolTable outSymbolTable;
algorithm
  (outNewCref, outSymbolTable) :=
  matchcontinue(inPrefixCref, inSuffixCref, inSymbolTable)
    local
      Absyn.Path inner_name;
      Component comp;
      SymbolTable st;
      DAE.ComponentRef inner_cref, new_cref, prefix_cref, rest_cref;

    case (_, _, st)
      equation
        comp = lookupCrefInTable(inPrefixCref, st);
        (inner_name, _, st) = updateInnerReference(comp, st);
        inner_cref = removeCrefOuterPrefix(inner_name, inPrefixCref);
        new_cref = ComponentReference.joinCrefs(inner_cref, inSuffixCref);
      then
        (new_cref, st);

    case (_, _, st)
      equation
        (prefix_cref, rest_cref) = ComponentReference.splitCrefLast(inPrefixCref);
        rest_cref = ComponentReference.joinCrefs(rest_cref, inSuffixCref);
        (new_cref, st) = replaceCrefOuterPrefix2(prefix_cref, rest_cref, st);
      then
        (new_cref, st);
         
  end matchcontinue;
end replaceCrefOuterPrefix2;

protected function instConditionalComponents
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      SymbolTable st;
      list<Element> comps;
      list<DAE.Element> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;

    case (COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        (comps, st) = instConditionalElements(comps, st, {});
      then
        (COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

    else (inClass, inSymbolTable);

  end match;
end instConditionalComponents;

protected function instConditionalElements
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output SymbolTable outSymbolTable;
algorithm
  (outElements, outSymbolTable) := match(inElements, inSymbolTable, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      SymbolTable st;
      Option<Element> oel;
      Component comp;
      Absyn.Path bc;
      Class cls;
      DAE.Type ty;

    case ({}, st, accum_el) then (listReverse(accum_el), st);

    case (el :: rest_el, st, accum_el)
      equation
        (oel, st) = instConditionalElement(el, st);
        accum_el = List.consOption(oel, accum_el);
        (accum_el, st) = instConditionalElements(rest_el, st, accum_el);
      then
        (accum_el, st);

  end match;
end instConditionalElements;
        
protected function instConditionalElementOnTrue
  input Boolean inCondition;
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := match(inCondition, inElement, inSymbolTable)
    local
      Option<Element> oel;
      SymbolTable st;

    case (true, _, st)
      equation
        (oel, st) = instConditionalElement(inElement, st);
      then
        (oel, st);

    else (NONE(), inSymbolTable);

  end match;
end instConditionalElementOnTrue;

protected function instConditionalElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := match(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      SymbolTable st;
      Element el;
      Option<Element> oel;
      Absyn.Path bc;
      DAE.Type ty;

    case (ELEMENT(comp, cls), st)
      equation
        (cls, st) = instConditionalComponents(cls, st);
        el = ELEMENT(comp, cls);
      then
        (SOME(el), st);

    case (CONDITIONAL_ELEMENT(comp), st)
      equation
        (oel, st) = instConditionalComponent(comp, st);
      then
        (oel, st);

    case (EXTENDED_ELEMENTS(bc, cls, ty), st)
      equation
        (cls, st) = instConditionalComponents(cls, st);
        el = EXTENDED_ELEMENTS(bc, cls, ty);
      then
        (SOME(el), st);

    else (SOME(inElement), inSymbolTable);

  end match;
end instConditionalElement;

protected function instConditionalComponent
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := matchcontinue(inComponent, inSymbolTable)
    local
      SCode.Element sel;
      Absyn.Exp cond_exp;
      Env env;
      Prefix prefix;
      SymbolTable st;
      DAE.Exp inst_exp;
      DAE.Type ty;
      Boolean cond;
      Absyn.Info info;
      Absyn.Path name;
      Modifier mod;
      Option<Element> el;
      Prefixes prefs;

    case (CONDITIONAL_COMPONENT(name, sel as SCode.COMPONENT(condition = 
      SOME(cond_exp), info = info), mod, prefs, env, prefix), st)
      equation
        inst_exp = instExp(cond_exp, env, prefix);
        (inst_exp, ty, st) = typeExp(inst_exp, st);
        (inst_exp, _) = ExpressionSimplify.simplify(inst_exp);
        cond = evaluateConditionalExp(inst_exp, ty, name, info);
        (el, st) = instConditionalComponent2(cond, sel, mod, prefs, env, prefix, st);
      then
        (el, st);
         
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeInst.instConditionalComponent failed on " +&
          printComponent(inComponent) +& "\n");
      then
        fail();

  end matchcontinue;
end instConditionalComponent;

protected function instConditionalComponent2
  input Boolean inCondition;
  input SCode.Element inElement;
  input Modifier inMod;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  output Option<Element> outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := 
  match(inCondition, inElement, inMod, inPrefixes, inEnv, inPrefix, inSymbolTable)
    local
      SCode.Element sel;
      Element el;
      SymbolTable st;
      Boolean added;
      Option<Element> oel;

    case (true, _, _, _, _, _, st)
      equation
        // We need to remove the condition from the element, otherwise
        // instElement will just add it as a conditional component again.
        sel = SCode.removeComponentCondition(inElement);
        // Instantiate the element and update the symbol table.
        el = instElement(sel, inMod, inPrefixes, inEnv, inPrefix);
        (el, st, added) = addInstCondElementToTable(el, st);
        // Recursively instantiate any conditional components in this element.
        (oel, st) = instConditionalElementOnTrue(added, el, st);
      then
        (oel, st);

    else (NONE(), inSymbolTable);
  end match;
end instConditionalComponent2;

protected function evaluateConditionalExp
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Absyn.Path inName;
  input Absyn.Info inInfo;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp, inType, inName, inInfo)
    local
      Boolean cond;
      String exp_str, name_str, ty_str;

    case (DAE.BCONST(bool = cond), DAE.T_BOOL(varLst = _), _, _) then cond;

    // TODO: remove this case once typing is fixed!
    case (DAE.BCONST(bool = cond), _, _, _) then cond;

    case (_, DAE.T_BOOL(varLst = _), _, _)
      equation
        // TODO: Return the variability of an expression from instExp, so that
        // we can see whether we got a variable expression here (which is an
        // error), or if we simply failed to evaluate it (which is a fault in
        // the compiler).
        exp_str = ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.COMPONENT_CONDITION_VARIABILITY,
          {exp_str}, inInfo);
      then
        fail();

    case (_, _, _, _)
      equation
        exp_str = ExpressionDump.printExpStr(inExp);
        name_str = Absyn.pathString(inName);
        ty_str = Types.printTypeStr(inType);
        Error.addSourceMessage(Error.CONDITION_TYPE_ERROR,
          {exp_str, name_str, ty_str}, inInfo);
      then
        fail();

  end match;
end evaluateConditionalExp;

protected function findInnerComponent
  input Absyn.Path inOuterName;
  input SymbolTable inSymbolTable;
  output Absyn.Path outInnerName;
  output Component outInnerComponent;
algorithm
  (outInnerName, outInnerComponent) := matchcontinue(inOuterName, inSymbolTable)
    local
      list<String> pathl;
      String comp_name;
      Absyn.Path prefix, inner_name, path;
      Component comp;

    case (_, _)
      equation
        pathl = Absyn.pathToStringList(inOuterName);
        comp_name :: _ :: pathl = listReverse(pathl);
        (inner_name, comp) = findInnerComponent2(comp_name, pathl, inSymbolTable);
      then
        (inner_name, comp);

    case (Absyn.IDENT(name = _), _)
      equation
        print("Outer component at top level\n");
      then
        fail();

    else
      equation
        print("Couldn't find corresponding inner component for " +&
            Absyn.pathString(inOuterName) +& "\n");
      then
        fail();

  end matchcontinue;
end findInnerComponent;

protected function findInnerComponent2
  input String inComponentName;
  input list<String> inPrefix;
  input SymbolTable inSymbolTable;
  output Absyn.Path outInnerPath;
  output Component outInnerComponent;
algorithm
  (outInnerPath, outInnerComponent) :=
  matchcontinue(inComponentName, inPrefix, inSymbolTable)
    local
      list<String> pathl;
      Absyn.Path path;
      Component comp;

    case (_, {}, _)
      equation
        path = Absyn.IDENT(inComponentName);
        comp = BaseHashTable.get(path, inSymbolTable);
        true = isInnerComponent(comp);
      then
        (path, comp);

    case (_, _ :: _, _)
      equation
        pathl = inComponentName :: inPrefix;
        path = Absyn.stringListPathReversed(pathl);
        comp = BaseHashTable.get(path, inSymbolTable);
        true = isInnerComponent(comp);
      then
        (path, comp);
        
    case (_, _ :: pathl, _)
      equation
        (path, comp) = findInnerComponent2(inComponentName, pathl, inSymbolTable);
      then
        (path, comp);

  end matchcontinue;
end findInnerComponent2;

protected function isInnerComponent
  input Component inComponent;
  output Boolean outIsInner;
algorithm
  outIsInner := match(inComponent)
    local
      SCode.Element el;
      Absyn.InnerOuter io;

    case UNTYPED_COMPONENT(prefixes = PREFIXES(innerOuter = io))
      then Absyn.isInner(io);

    case TYPED_COMPONENT(prefixes = PREFIXES(innerOuter = io))
      then Absyn.isInner(io);

    case CONDITIONAL_COMPONENT(element = el)
      then SCode.isInnerComponent(el);
        
    else false;
  end match;
end isInnerComponent;

public function printBinding
  input Binding inBinding;
  output String outString;
algorithm
  outString := match(inBinding)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      DAE.Type ty;

    case (RAW_BINDING(bindingExp = aexp))
      then " = " +& Dump.printExpStr(aexp);

    case (UNTYPED_BINDING(bindingExp = dexp))
      then " = " +& ExpressionDump.printExpStr(dexp);

    case (TYPED_BINDING(bindingExp = dexp, bindingType = ty))
      then " = (" +& Types.unparseType(ty) +& ") " +&
        ExpressionDump.printExpStr(dexp);

    else "";
  end match;
end printBinding;

protected function printComponent
  input Component inComponent;
  output String outString;
algorithm
  outString := match(inComponent)
    local
      Absyn.Path path, inner_path;
      Binding binding;
      DAE.Type ty;

    case UNTYPED_COMPONENT(name = path, binding = binding)
      then "  " +& Absyn.pathString(path) +& printBinding(binding);

    case TYPED_COMPONENT(name = path, ty = ty, binding = binding)
      then "  " +& Types.unparseType(ty) +& " " +& Absyn.pathString(path) +&
        printBinding(binding);

    case CONDITIONAL_COMPONENT(name = path) 
      then "  conditional " +& Absyn.pathString(path);

    case OUTER_COMPONENT(name = path, innerName = SOME(inner_path))
      then "  outer " +& Absyn.pathString(path) +& " -> " +& Absyn.pathString(inner_path);

    case OUTER_COMPONENT(name = path)
      then "  outer " +& Absyn.pathString(path);

    else "#UNKNOWN COMPONENT#";
  end match;
end printComponent;

public function printPrefix
  input Prefix inPrefix;
  output String outString;
algorithm
  outString := match(inPrefix)
    local
      String id;
      Absyn.ArrayDim dims;
      Prefix rest_pre;

    case {} then "";
    case {(id, dims)} then id +& Dump.printArraydimStr(dims);
    case ((id, dims) :: rest_pre)
      then printPrefix(rest_pre) +& "." +& id +& Dump.printArraydimStr(dims);

  end match;
end printPrefix;

protected function printElement
  input Element inElement;
  output String outString;
algorithm
  outString := match(inElement)
    local
      Component comp;
      list<Element> el;
      Class cls;
      String comp_str, cls_str, delim;

    case ELEMENT(component = comp, cls = cls)
      equation
        comp_str = printComponent(comp);
        cls_str = printClass(cls);
      then
        Util.stringDelimitListNonEmptyElts({comp_str, cls_str}, "\n");

    case CONDITIONAL_ELEMENT(component = comp)
      then printComponent(comp);

    case EXTENDED_ELEMENTS(cls = cls)
      then printClass(cls);

  end match;
end printElement;

protected function printClass
  input Class inClass;
  output String outString;
algorithm
  outString := match(inClass)
    local
      list<Element> comps;
      list<DAE.Element> eq, ieq;
      String comps_str, eq_str, ieq_str, str;

    case BASIC_TYPE() then "";

    case COMPLEX_CLASS(components = comps, equations = eq, 
        initialEquations = ieq)
      equation
        comps_str = Util.stringDelimitListNonEmptyElts(
          List.map(comps, printElement), "\n");
        ieq_str = stringAppendList(List.map(ieq, DAEDump.dumpEquationStr));
        ieq_str = Util.stringAppendNonEmpty("\ninitial equation\n", ieq_str);
        eq_str = stringAppendList(List.map(eq, DAEDump.dumpEquationStr));
        eq_str = Util.stringAppendNonEmpty("\nequation\n", eq_str);
        str = comps_str +& ieq_str +& eq_str;
      then
        str;

  end match;
end printClass;
  
end SCodeInst;
