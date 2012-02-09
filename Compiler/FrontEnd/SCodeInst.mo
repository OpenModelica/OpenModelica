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
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Graph;
protected import List;
protected import SCodeDump;
protected import SCodeLookup;
protected import SCodeFlattenRedeclare;
protected import SCodeMod;
protected import System;
protected import Types;
protected import Util;

public type Env = SCodeEnv.Env;
protected type Item = SCodeEnv.Item;

public type Prefix = list<tuple<String, Absyn.ArrayDim>>;

public uniontype FlatProgram
  record EMPTY_FLAT_PROGRAM end EMPTY_FLAT_PROGRAM;

  record FLAT_PROGRAM
    list<Component> components;
    list<Component> conditionals;
    list<SCode.Equation> equations;
    list<SCode.Equation> initialEquations;
    list<SCode.AlgorithmSection> algorithms;
    list<SCode.AlgorithmSection> initalAlgorithms;
  end FLAT_PROGRAM;
end FlatProgram;

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

  record UNTYPED_BINDING
    DAE.Exp bindingExp;
    Boolean isProcessing;
  end UNTYPED_BINDING;

  record TYPED_BINDING
    DAE.Exp bindingExp;
    DAE.Type bindingType;
  end TYPED_BINDING;
end Binding;

public uniontype Component
  record UNTYPED_COMPONENT
    Absyn.Path name;
    SCode.Element element;
    DAE.Type baseType;
    array<Dimension> dimensions;
    Binding binding;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    Absyn.Path name;
    DAE.Type ty;
    SCode.Variability variability;
    Binding binding;
  end TYPED_COMPONENT;
    
  record CONDITIONAL_COMPONENT
    Absyn.Path name;
    SCode.Element element;
    Env env;
    Prefix prefix;
  end CONDITIONAL_COMPONENT; 
end Component;

public type Key = Absyn.Path;
public type Value = Component;

public type HashTableFunctionsType = tuple<FuncHashKey, FuncKeyEqual, FuncKeyStr, FuncValueStr>;

public type SymbolTable = tuple<
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

public function hashFunc
  input Key inKey;
  input Integer inMod;
  output Integer outHash;
protected
  String str;
algorithm
  str := Absyn.pathString(inKey);
  outHash := System.stringHashDjb2Mod(str, inMod);
end hashFunc;

public function emptySymbolTable
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := emptySymbolTableSized(BaseHashTable.defaultBucketSize);
end emptySymbolTable;

public function emptySymbolTableSized
  input Integer inSize;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := BaseHashTable.emptyHashTableWork(inSize,
    (hashFunc, Absyn.pathEqual, Absyn.pathString, printComponent));
end emptySymbolTableSized;

public function makeClassFlatProgram
  input list<SCode.Equation> inEquations;
  input list<SCode.Equation> inInitialEquations;
  input list<SCode.AlgorithmSection> inAlgorithms;
  input list<SCode.AlgorithmSection> inInitialAlgorithms;
  output FlatProgram outProgram;
algorithm
  outProgram := match(inEquations, inInitialEquations, inAlgorithms,
      inInitialAlgorithms)
    case ({}, {}, {}, {}) then EMPTY_FLAT_PROGRAM();
    else FLAT_PROGRAM({}, {}, inEquations, inInitialEquations,
      inAlgorithms, inInitialAlgorithms);
  end match;
end makeClassFlatProgram;

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
      FlatProgram program, const_prog;
      SymbolTable symtab;

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
        (program, _) = instClassItem(item, SCode.NOMOD(), env, {});
        const_prog = instGlobalConstants(inGlobalConstants, inEnv,
          EMPTY_FLAT_PROGRAM());
        program = mergeFlatProgram(const_prog, program);
        symtab = buildSymbolTable(program);
        symtab = typeComponents(program, symtab);
        System.stopTimer();
        print("SCodeInst took " +& realString(System.getTimerIntervalTime()) +&
          " seconds.\n");
        printFlatProgram(name, program);
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

protected function mergeFlatProgram
  input FlatProgram inProgram1;
  input FlatProgram inProgram2;
  output FlatProgram outProgram;
algorithm
  outProgram := match(inProgram1, inProgram2)
    local
      list<Component> cl1, cl2, cdl1, cdl2;
      list<SCode.Equation> eq1, eq2, ie1, ie2;
      list<SCode.AlgorithmSection> al1, al2, ia1, ia2;

    case (EMPTY_FLAT_PROGRAM(), _) then inProgram2;
    case (_, EMPTY_FLAT_PROGRAM()) then inProgram1;

    case (FLAT_PROGRAM(cl1, cdl1, eq1, ie1, al1, ia1),
        FLAT_PROGRAM(cl2, cdl2, eq2, ie2, al2, ia2))
      equation
        cl1 = listAppend(cl1, cl2);
        cdl1 = listAppend(cdl1, cdl2);
        eq1 = listAppend(eq1, eq2);
        ie1 = listAppend(ie1, ie2);
        al1 = listAppend(al1, al2);
        ia1 = listAppend(ia1, ia2);
      then
        FLAT_PROGRAM(cl1, cdl1, eq1, ie1, al1, ia1);

  end match;
end mergeFlatProgram;

protected function addComponentToFlatProgram
  input Component inComponent;
  input SCode.Variability inVariability;
  input FlatProgram inProgram;
  output FlatProgram outProgram;
protected
algorithm
  outProgram := match(inComponent, inVariability, inProgram)
    local
      list<Component> cl, cdl;
      list<SCode.Equation> eq, ie;
      list<SCode.AlgorithmSection> al, ia;

    case (_, _, FLAT_PROGRAM(cl, cdl, eq, ie, al, ia))
      then FLAT_PROGRAM(inComponent :: cl, cdl, eq, ie, al, ia);

    case (_, _, EMPTY_FLAT_PROGRAM())
      then FLAT_PROGRAM({inComponent}, {}, {}, {}, {}, {});

  end match;
end addComponentToFlatProgram;

protected function instClassItem
  input Item inItem;
  input SCode.Mod inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output FlatProgram outProgram;
  output DAE.Type outType;
protected
  Item item;
algorithm
  item := convertDerivedBasicTypeToShortDef(inItem);
  (outProgram, outType) := instClassItem2(item, inMod, inEnv, inPrefix);
end instClassItem;

protected function instClassItem2
  input Item inItem;
  input SCode.Mod inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output FlatProgram outProgram;
  output DAE.Type outType;
algorithm
  (outProgram, outType) := match(inItem, inMod, inEnv, inPrefix)
    local
      list<SCode.Element> el;
      Absyn.TypeSpec dty;
      Item item;
      Env env;
      Absyn.Info info;
      SCode.Mod mod;
      SCodeEnv.AvlTree cls_and_vars;
      String name;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal, ial;
      list<FlatProgram> progs;
      FlatProgram prog;
      DAE.Type ty;
      Absyn.ArrayDim dims;
      list<DAE.Var> vars;

      list<DAE.Element> del;

    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name), env = env,
        classType = SCodeEnv.BASIC_TYPE()), _, _, _) 
      equation
        vars = instBasicTypeAttributes(inMod, env, inPrefix);
        ty = instBasicType(name, inMod, vars);
      then 
        (EMPTY_FLAT_PROGRAM(), ty);

    // A class with parts, instantiate all elements in it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(name = name, 
          classDef = SCode.PARTS(el, nel, iel, nal, ial, _, _, _)), 
        env = {SCodeEnv.FRAME(clsAndVars = cls_and_vars)}), _, _, _)
      equation
        env = SCodeEnv.mergeItemEnv(inItem, inEnv);
        el = List.map1(el, lookupElement, cls_and_vars);
        el = SCodeMod.applyModifications(inMod, el, inPrefix, env);

        //del = List.map2(nel, instEquation, env, inPrefix);
        //print(stringDelimitList(List.map(del, DAEDump.dumpEquationStr), "\n") +& "\n");
        prog = makeClassFlatProgram(nel, iel, nal, ial);
        prog = instElementList(el, env, inPrefix, prog);
      then
        (prog, DAE.T_COMPLEX_DEFAULT);

    // A derived class, look up the inherited class and instantiate it.
    case (SCodeEnv.CLASS(cls = SCode.CLASS(classDef =
        SCode.DERIVED(modifications = mod, typeSpec = dty), info = info)), _, _, _)
      equation
        (item, env) = SCodeLookup.lookupTypeSpec(dty, inEnv, info);
        mod = SCodeMod.mergeMod(inMod, mod);
        (prog, ty) = instClassItem(item, mod, env, inPrefix);
        dims = Absyn.typeSpecDimensions(dty);
        //ty = liftArrayType(dims, ty, inEnv, inPrefix);
      then
        (prog, ty);
        
    else (EMPTY_FLAT_PROGRAM(), DAE.T_UNKNOWN_DEFAULT);
  end match;
end instClassItem2;

protected function convertDerivedBasicTypeToShortDef
  input Item inItem;
  output Item outItem;
algorithm
  outItem := match(inItem)
    local
      String bc;
      Boolean is_basic;

    case SCodeEnv.CLASS(cls = SCode.CLASS(classDef = SCode.PARTS(
        {SCode.EXTENDS(baseClassPath = Absyn.IDENT(bc))}, {}, {}, {}, {}, NONE(), _, _)))
      equation
        is_basic = isBasicType(bc);
      then 
        convertDerivedBasicTypeToShortDef2(inItem, is_basic, bc);

    else inItem;
  end match;
end convertDerivedBasicTypeToShortDef;

protected function isBasicType
  input String inTypeName;
  output Boolean outIsBasicType;
algorithm
  outIsBasicType := match(inTypeName)
    case "Real" then true;
    case "Integer" then true;
    case "String" then true;
    case "Boolean" then true;
    case "StateSelect" then true;
    else false;
  end match;
end isBasicType;

protected function convertDerivedBasicTypeToShortDef2
  input Item inItem;
  input Boolean inIsBasicType;
  input String inBaseClass;
  output Item outItem;
algorithm
  outItem := match(inItem, inIsBasicType, inBaseClass)
    local
      String name;
      SCode.Prefixes pf;
      SCode.Encapsulated ep;
      SCode.Partial pp;
      SCode.Restriction res;
      Absyn.Info info;
      Env env;
      SCodeEnv.ClassType ty;
      SCode.Visibility vis;
      SCode.Mod mod;
      list<SCode.Annotation> annl;
      Option<SCode.Comment> cmt;

    case (_, false, _) then inItem;

    case (SCodeEnv.CLASS(SCode.CLASS(name, pf, ep, pp, res, 
        SCode.PARTS({SCode.EXTENDS(_, vis, mod, _, _)}, {}, {}, {}, {}, 
          NONE(), annl, cmt), info), env, ty), _, _)
      equation
        cmt = makeClassComment(annl, cmt);
        // TODO: Check restriction
        // TODO: Check visibility
      then
        SCodeEnv.CLASS(SCode.CLASS(name, pf, ep, pp, res,
          SCode.DERIVED(Absyn.TPATH(Absyn.IDENT(inBaseClass), NONE()), mod,
            SCode.defaultVarAttr, cmt), info), env, ty);

  end match;
end convertDerivedBasicTypeToShortDef2;

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
  input SCode.Mod inMod;
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
  input SCode.Mod inMod;
  input Env inEnv;
  input Prefix inPrefix;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inMod, inEnv, inPrefix)
    local
      list<SCode.SubMod> submods;
      SCodeEnv.AvlTree attrs;
      list<DAE.Var> vars;
      SCode.Element el;
      Absyn.Info info;

    case (SCode.NOMOD(), _, _) then {};

    case (SCode.MOD(subModLst = submods), 
        SCodeEnv.FRAME(clsAndVars = attrs) :: _, _)
      equation
        vars = List.map3(submods, instBasicTypeAttribute, attrs, inEnv, inPrefix);
      then
        vars;

    case (SCode.REDECL(element = el), _, _)
      equation
        info = SCode.elementInfo(el);
        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE, {}, info);
      then
        fail();
         
  end match;
end instBasicTypeAttributes;

protected function instBasicTypeAttribute
  input SCode.SubMod inSubMod;
  input SCodeEnv.AvlTree inAttributes;
  input Env inEnv;
  input Prefix inPrefix;
  output DAE.Var outAttribute;
algorithm
  outAttribute := matchcontinue(inSubMod, inAttributes, inEnv, inPrefix)
    local
      String ident, tspec;
      DAE.Type ty;
      Absyn.Exp bind_exp;
      DAE.Exp inst_exp;
      DAE.Binding binding;

    case (SCode.NAMEMOD(ident = ident, 
        A = SCode.MOD(subModLst = {}, binding = SOME((bind_exp, _)))), _, _, _)
      equation
        SCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = Absyn.TPATH(path =
          Absyn.IDENT(tspec)))) = SCodeLookup.lookupInTree(ident, inAttributes);
        ty = instBasicTypeAttributeType(tspec);
        inst_exp = instExp(bind_exp, inEnv, inPrefix);
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
  input list<SCode.Element> inElements;
  input Env inEnv;
  input Prefix inPrefix;
  input FlatProgram inProgram;
  output FlatProgram outProgram;
algorithm
  outProgram := match(inElements, inEnv, inPrefix, inProgram)
    local
      SCode.Element elem;
      list<SCode.Element> rest_el;
      FlatProgram prog;

    case ({}, _, _, _) then inProgram;

    case (elem :: rest_el, _, _, _)
      equation
        prog = instElement(elem, inEnv, inPrefix);
        prog = mergeFlatProgram(prog, inProgram);
      then
        instElementList(rest_el, inEnv, inPrefix, prog);

  end match;
end instElementList;

protected function instElement
  input SCode.Element inElement;
  input Env inEnv;
  input Prefix inPrefix;
  output FlatProgram outProgram;
algorithm
  outProgram := match(inElement, inEnv, inPrefix)
    local
      Absyn.ArrayDim ad;
      Absyn.Info info;
      Absyn.Path path;
      Component comp;
      DAE.Type ty;
      Env env;
      FlatProgram prog;
      Item item;
      list<SCodeEnv.Redeclaration> redecls;
      Option<Absyn.Exp> binding;
      Binding inst_binding;
      Prefix prefix;
      SCodeEnv.ExtendsTable exts;
      SCode.Mod mod;
      String name;
      SCode.Variability var;
      list<Dimension> dims;
      array<Dimension> dim_arr;

    // A component, look up it's type and instantiate that class.
    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad,
        variability = var), typeSpec = Absyn.TPATH(path = path), 
        modifications = mod, condition = NONE(), info = info), _, _)
      equation
        // Look up the class of the component.
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        // Apply the redeclarations to the class.
        redecls = SCodeFlattenRedeclare.extractRedeclaresFromModifier(mod);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        // Instantiate the class.
        prefix = (name, ad) :: inPrefix;
        (prog, ty) = instClassItem(item, mod, env, prefix);

        // Instantiate array dimensions and binding.
        dims = List.map2(ad, instDimension, inEnv, inPrefix);
        dim_arr = listArray(dims);
        binding = SCode.getModifierBinding(mod);
        inst_binding = instBinding(binding, inEnv, inPrefix);

        // Create the component and add it to the program.
        path = prefixToPath(prefix);
        comp = UNTYPED_COMPONENT(path, inElement, ty, dim_arr, inst_binding);
        prog = addComponentToFlatProgram(comp, var, prog);

        //print("Type of " +& name +& ": " +& Types.printTypeStr(ty) +& "\n");
      then
        prog;

    // A conditional component, save it for later.
    case (SCode.COMPONENT(name = name, condition = SOME(_)), _, _)
      equation
        path = prefixPath(Absyn.IDENT(name), inPrefix);
        comp = CONDITIONAL_COMPONENT(path, inElement, inEnv, inPrefix);
        prog = FLAT_PROGRAM({}, {comp}, {}, {}, {}, {});
      then
        prog;

    // An extends, look up the extended class and instantiate it.
    case (SCode.EXTENDS(baseClassPath = path, modifications = mod, info = info),
        SCodeEnv.FRAME(extendsTable = exts) :: _, _)
      equation
        // Look up the extended class.
        (item, path, env) = SCodeLookup.lookupClassName(path, inEnv, info);
        path = SCodeEnv.mergePathWithEnvPath(path, env);
        // Apply the redeclarations.
        redecls = SCodeFlattenRedeclare.lookupExtendsRedeclaresInTable(path, exts);
        (item, env) =
          SCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv);
        // Instantiate the class.
        (prog, ty) = instClassItem(item, mod, env, inPrefix);
      then
        prog;
        
    else EMPTY_FLAT_PROGRAM();
  end match;
end instElement;

protected function instBinding
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input Prefix inPrefix;
  output Binding outExp;
algorithm
  outExp := match(inExp, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;

    case (NONE(), _, _) then UNBOUND();
    case (SOME(aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
      then
        UNTYPED_BINDING(dexp, false);

  end match;
end instBinding;

protected function instDimension
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  output Dimension outDimension;
algorithm
  outDimension := match(inSubscript, inEnv, inPrefix)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      DAE.Dimension dim;

    case (Absyn.NOSUB(), _, _) 
      then UNTYPED_DIMENSION(DAE.DIM_UNKNOWN(), false);

    case (Absyn.SUBSCRIPT(subscript = aexp), _, _)
      equation
        dexp = instExp(aexp, inEnv, inPrefix);
        dim = makeDimension(dexp);
      then
        UNTYPED_DIMENSION(dim, false);

  end match;
end instDimension;

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

//protected function liftArrayType
//  input Absyn.ArrayDim inDims;
//  input DAE.Type inType;
//  input Env inEnv;
//  input Prefix inPrefix;
//  output DAE.Type outType;
//algorithm
//  outType := match(inDims, inType, inEnv, inPrefix)
//    local
//      DAE.Dimensions dims1, dims2;
//      DAE.TypeSource src;
//      DAE.Type ty;
//
//    case ({}, _, _, _) then inType;
//    case (_, DAE.T_ARRAY(ty, dims1, src), _, _)
//      equation
//        dims2 = List.map2(inDims, instDimension, inEnv, inPrefix);
//        dims1 = listAppend(dims2, dims1);
//      then
//        DAE.T_ARRAY(ty, dims1, src);
//
//    else
//      equation
//        dims2 = List.map2(inDims, instDimension, inEnv, inPrefix);
//      then
//        DAE.T_ARRAY(inType, dims2, DAE.emptyTypeSource);
//  
//  end match;
//end liftArrayType;

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
      list<Absyn.Exp> aexpl;
      list<DAE.Exp> dexpl;

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
        dop = instOperator(aop);
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
        dexpl = List.map2(aexpl, instExp, inEnv, inPrefix);
      then
        DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, dexpl);

    //Absyn.CALL
    //Absyn.PARTEVALFUNCTION
    //Absyn.ARRAY
    //Absyn.MATRIX
    //Absyn.RANGE
    //Absyn.TUPLE
    //Absyn.END
    //Absyn.CODE
    //Absyn.AS
    //Absyn.CONS
    //Absyn.MATCHEXP
    //Absyn.LIST

    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1, aexp2})), _, _)
      equation
        dexp1 = instExp(aexp1, inEnv, inPrefix);
        dexp2 = instExp(aexp2, inEnv, inPrefix);
      then
        DAE.SIZE(dexp1, SOME(dexp2));

    else DAE.ICONST(0);
  end match;
end instExp;

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
      DAE.ComponentRef cref;
      SCode.Variability var;
      SCodeLookup.Origin origin;

    case (Absyn.WILD(), _, _) then DAE.WILD();
    case (Absyn.ALLWILD(), _, _) then DAE.WILD();
    //case (Absyn.CREF_FULLYQUALIFIED(_), _, _)
    //  equation
    //    print("Found fully qualified path " +& Dump.printComponentRefStr(inCref) +& "!\n");
    //  then
    //    fail();

    case (_, _, _)
      equation
        cref = instGlobalConstantCref(inCref, inEnv, inPrefix);
      then
        cref;

    else
      equation
        cref = instCref2(inCref);
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

    case (Absyn.CREF_QUAL(name = _), _, _)
      equation
        path = Absyn.crefToPath(inName);
        (SCodeEnv.VAR(var = SCode.COMPONENT(name = name, attributes = SCode.ATTR(
            variability = SCode.CONST()))), path, env, SCodeLookup.CLASS_ORIGIN()) =
          SCodeLookup.lookupName(path, inEnv, Absyn.dummyInfo, NONE());
        path = SCodeEnv.mergePathWithEnvPath(Absyn.IDENT(name), env);
        cref = ComponentReference.pathToCref(path);
      then
        cref;
        
  end match;
end instGlobalConstantCref;

protected function instCref2
  input Absyn.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref)
    local
      String name;
      Absyn.ComponentRef cref;
      DAE.ComponentRef dcref;

    case Absyn.CREF_IDENT(name = name)
      then DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {});

    case Absyn.CREF_QUAL(name = name, componentRef = cref)
      equation
        dcref = instCref2(cref);
      then
        DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, dcref);

    case Absyn.CREF_FULLYQUALIFIED(cref) then instCref2(cref);

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

  end match;
end instEEquation;

protected function instGlobalConstants
  input list<Absyn.Path> inGlobalConstants;
  input Env inEnv;
  input FlatProgram inProgram;
  output FlatProgram outProgram;
algorithm
  outProgram := match(inGlobalConstants, inEnv, inProgram)
    local
      Absyn.Path const, pre_path;
      list<Absyn.Path> rest_const;
      FlatProgram prog;
      Prefix prefix;
      SCode.Element el;
      Env env;

    case ({}, _, _) then inProgram;

    case (const :: rest_const, _, _)
      equation
        pre_path = Absyn.pathPrefix(const);
        prefix = pathPrefix(pre_path);
        (SCodeEnv.VAR(var = el), _, env) = 
          SCodeLookup.lookupFullyQualified(const, inEnv);
        prog = instElement(el, env, prefix);
        prog = mergeFlatProgram(prog, inProgram);
      then
        instGlobalConstants(rest_const, inEnv, prog);

  end match;
end instGlobalConstants;

protected function buildSymbolTable
  input FlatProgram inProgram;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inProgram)
    local
      list<Component> comps, conds;
      SymbolTable symtab;
      Integer comp_size, bucket_size;

    case EMPTY_FLAT_PROGRAM() then emptySymbolTableSized(0);

    case FLAT_PROGRAM(components = comps, conditionals = conds)
      equation
        // Set the bucket size to the nearest prime of the number of components
        // multiplied with 4/3, to get ~75% occupancy.
        comp_size = listLength(comps) + listLength(conds);
        bucket_size = Util.nextPrime(intDiv((comp_size * 4), 3));
        symtab = emptySymbolTableSized(bucket_size);
        symtab = fillSymbolTable(comps, conds, symtab);
      then
        symtab;

  end match;
end buildSymbolTable;

protected function fillSymbolTable
  input list<Component> inComponents;
  input list<Component> inConditionals;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := List.fold(inComponents, addComponentToTable, inSymbolTable); 
  outSymbolTable := List.fold(inConditionals, addComponentToTable, outSymbolTable); 
end fillSymbolTable;

protected function addComponentToTable
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inComponent, inSymbolTable) 
    local
      Absyn.Path name;

    case (UNTYPED_COMPONENT(name = name), _)
      then BaseHashTable.addNoUpdCheck((name, inComponent), inSymbolTable);

    case (CONDITIONAL_COMPONENT(name = name), _)
      then BaseHashTable.addNoUpdCheck((name, inComponent), inSymbolTable);

    case (UNTYPED_COMPONENT(name = name), _)
      equation
        print("Failed to add component " +& Absyn.pathString(name) +& " to symbol table!\n");
      then
        inSymbolTable;

    else
      equation
        print("Failed to add unknown component to symbol table!\n");
      then
        inSymbolTable;

  end matchcontinue;
end addComponentToTable;

protected function typeComponents
  input FlatProgram inProgram;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inProgram, inSymbolTable)
    local
      list<Component> cl;
      SymbolTable st;

    case (EMPTY_FLAT_PROGRAM(), _) then inSymbolTable;

    case (FLAT_PROGRAM(components = cl), st)
      equation
        (cl, st) = typeComponents2(cl, st, {});
        print("Components [" +& intString(listLength(cl)) +& "]: \n");
        print(stringDelimitList(List.map(cl, printComponent), "\n") +& "\n");
      then
        st;

  end match;
end typeComponents;

protected function typeComponents2
  input list<Component> inComponents;
  input SymbolTable inSymbolTable;
  input list<Component> inAccumComps;
  output list<Component> outComponents;
  output SymbolTable outSymbolTable;
algorithm
  (outComponents, outSymbolTable) := 
  match(inComponents, inSymbolTable, inAccumComps)
    local
      Absyn.Path name;
      Component comp;
      list<Component> rest_comps;
      SymbolTable st;
    
    case ({}, _, _) then (listReverse(inAccumComps), inSymbolTable);

    case (UNTYPED_COMPONENT(name = name) :: rest_comps, st, _)
      equation
        comp = BaseHashTable.get(name, st);
        (comp, st) = typeComponent(comp, st);
        (rest_comps, st) = typeComponents2(rest_comps, st, comp :: inAccumComps);
      then
        (rest_comps, st);

  end match;
end typeComponents2;

protected function typeComponent
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := match(inComponent, inSymbolTable)
    local
      Absyn.Path name;
      DAE.Type ty;
      Binding binding;
      list<Dimension> dims;
      SymbolTable st;
      Component comp;
      SCode.Variability var;

    case (UNTYPED_COMPONENT(name = name, baseType = ty, binding = binding), st)
      equation
        (ty, st) = typeComponentDims(inComponent, st);
        (comp, st ) = typeComponentBinding(inComponent, SOME(ty), st);
        //st = markComponentBindingAsProcessing(inComponent, st);
        //(binding, st) = typeBinding(binding, st);
        //comp = TYPED_COMPONENT(name, ty, var, binding);
        //st = BaseHashTable.add((name, comp), st);
      then
        (comp, st);

    case (TYPED_COMPONENT(name = _), st) then (inComponent, st);

    case (CONDITIONAL_COMPONENT(name = name), _)
      equation
        print("Trying to type conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

  end match;
end typeComponent;

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
        typed_dim = listNth(dims, inIndex);
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
      Integer dim_int;
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
        dim = getComponentBindingDimension(comp, inIndex);
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
  output DAE.Dimension outDimension;
protected
  Binding binding;
algorithm
  binding := getComponentBinding(inComponent);
  outDimension := getBindingDimension(binding, inDimension);
end getComponentBindingDimension;

protected function getBindingDimension
  input Binding inBinding;
  input Integer inDimension;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inBinding, inDimension)
    local
      DAE.Exp exp;

    case (TYPED_BINDING(bindingExp = exp), _)
      then getExpDimension(exp, inDimension);

  end match;
end getBindingDimension;
  
protected function getExpDimension
  input DAE.Exp inExp;
  input Integer inDimension;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inExp, inDimension)
    local
      DAE.Type ty;
      list<DAE.Dimension> dims;
      DAE.Dimension dim;

    case (DAE.ARRAY(ty = ty), _)
      equation
        dims = Types.getDimensions(ty);
        dim = listGet(dims, inDimension);
      then
        dim;

  end match;
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
      SCode.Variability var;
      SCode.Element el;
      array<Dimension> dims;
     
    case (UNTYPED_COMPONENT(name = name, element = SCode.COMPONENT(attributes =
        SCode.ATTR(variability = var))), _, SOME(ty))
      then TYPED_COMPONENT(name, ty, var, inBinding);

    case (UNTYPED_COMPONENT(name, el, ty, dims, _), _, NONE())
      then UNTYPED_COMPONENT(name, el, ty, dims, inBinding);

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
      SCode.Variability var;
      DAE.Exp binding_exp;

    case (UNTYPED_COMPONENT(element = SCode.COMPONENT(attributes =
            SCode.ATTR(variability = var))), _)
      equation
        false = SCode.isParameterOrConst(var);
      then
        inSymbolTable;

    case (UNTYPED_COMPONENT(name, el, ty, dims, 
        UNTYPED_BINDING(bindingExp = binding_exp)), _)
      equation
        comp = UNTYPED_COMPONENT(name, el, ty, dims, 
          UNTYPED_BINDING(binding_exp, true));
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

    case (UNTYPED_BINDING(isProcessing = true), st)
      equation
        print("Found loop in binding\n");
      then
        fail();

    case (UNTYPED_BINDING(bindingExp = binding), st)
      equation
        (binding, ty, st) = typeExp(binding, st);
      then
        (TYPED_BINDING(binding, ty), st);

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
    //case (DAE.SIZE(exp = e1, sz = SOME(

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
      SCode.Variability var;
      Boolean param_or_const;

    case (_, st)
      equation
        comp = lookupCrefInTable(inCref, st);
        var = getComponentVariability(comp);
        param_or_const = SCode.isParameterOrConst(var);
        (exp, ty, st) = typeCref2(inCref, comp, param_or_const, st);
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
  output SCode.Variability outVariability;
algorithm
  outVariability := match(inComponent)
    local
      SCode.Variability var;

    case (UNTYPED_COMPONENT(element = SCode.COMPONENT(attributes =
        SCode.ATTR(variability = var)))) 
      then var;

    case (TYPED_COMPONENT(variability = var)) then var;

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
      SCode.Variability var;
      Binding binding;
      SymbolTable st;
      DAE.Exp exp;

    case (_, TYPED_COMPONENT(variability = var, ty = ty, binding = binding), true, st)
      equation
        exp = getBindingExp(binding);
      then
        (exp, ty, st);

    case (_, TYPED_COMPONENT(variability = var, ty = ty), false, st)
      then (DAE.CREF(inCref, ty), ty, st);

    case (_, UNTYPED_COMPONENT(element = SCode.COMPONENT(attributes =
        SCode.ATTR(variability = var))), true, st)
      equation
        (TYPED_COMPONENT(ty = ty, binding = binding), st) =
          typeComponent(inComponent, st);
        exp = getBindingExp(binding);
      then
        (exp, ty, st);

    case (_, UNTYPED_COMPONENT(element = SCode.COMPONENT(attributes =
        SCode.ATTR(variability = var))), false, st)
      equation
        false = SCode.isParameterOrConst(var);
        (ty, st) = typeComponentDims(inComponent, st);
      then
        (DAE.CREF(inCref, ty), ty, st);

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
algorithm
  outComponent := matchcontinue(inCref, inSymbolTable)
    local
      Absyn.Path path;
      Component comp;
      SymbolTable st;

    case (_, st)
      equation
        path = ComponentReference.crefToPath(inCref);
        comp = BaseHashTable.get(path, st);
      then
        comp;

    else
      equation
        print("Could not find cref " +&
            ComponentReference.printComponentRefStr(inCref) +& " in the symbol table\n");
      then
        fail();
  
  end matchcontinue;
end lookupCrefInTable;

public function printMod
  input SCode.Mod inMod;
  output String outString;
algorithm
  outString := match(inMod)
    local
      SCode.Final fp;
      SCode.Each ep;
      list<SCode.SubMod> submods;
      Option<tuple<Absyn.Exp, Boolean>> binding;
      SCode.Element el;
      String fstr, estr, submod_str, bind_str, el_str;

    case SCode.MOD(fp, ep, submods, binding, _)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        submod_str = stringDelimitList(List.map(submods, printSubMod), ", ");
        bind_str = printBinding(binding);
      then
        "MOD(" +& fstr +& estr +& "{" +& submod_str +& "})" +& bind_str;

    case SCode.REDECL(fp, ep, el)
      equation
        fstr = SCodeDump.finalStr(fp);
        estr = SCodeDump.eachStr(ep);
        el_str = SCodeDump.unparseElementStr(el);
      then
        "REDECL(" +& fstr +& estr +& el_str +& ")";

    case SCode.NOMOD() then "NOMOD()";
  end match;
end printMod;

protected function printSubMod
  input SCode.SubMod inSubMod;
  output String outString;
algorithm
  outString := match(inSubMod)
    local
      SCode.Mod mod;
      list<SCode.Subscript> subs;
      String id, mod_str, subs_str;

    case SCode.NAMEMOD(ident = id, A = mod)
      equation
        mod_str = printMod(mod);
      then
        "NAMEMOD(" +& id +& " = " +& mod_str +& ")";

    case SCode.IDXMOD(subscriptLst = subs, an = mod)
      equation
        subs_str = Dump.printSubscriptsStr(subs);
        mod_str = printMod(mod);
      then
        "IDXMOD(" +& subs_str +& ", " +& mod_str +& ")";

  end match;
end printSubMod;

protected function printBinding
  input Option<tuple<Absyn.Exp, Boolean>> inBinding;
  output String outString;
algorithm
  outString := match(inBinding)
    local
      Absyn.Exp exp;

    case SOME((exp, _)) then " = " +& Dump.printExpStr(exp);
    else "";
  end match;
end printBinding;
        
protected function printFlatProgram
  input SCode.Ident inName;
  input FlatProgram inProgram;
algorithm
  _ := match(inName, inProgram)
    local
      list<Component> cl, cdl;
      list<SCode.Equation> eq, ie;
      list<SCode.AlgorithmSection> al, ia;

    case (_, EMPTY_FLAT_PROGRAM())
      equation
        print("class " +& inName +& "\n");
        print("end " +& inName +& "\n");
      then
        ();

    case (_, FLAT_PROGRAM(cl, cdl, eq, ie, al, ia))
      equation
        print("class " +& inName +& "\n");
        print("Components: " +& intString(listLength(cl)) +& "\n");
        print("Conditionals: " +& intString(listLength(cdl)) +& "\n");
        print("Equations:  " +& intString(listLength(eq)) +& "\n");
        //print(stringDelimitList(List.map(eq, SCodeDump.equationStr2), "\n") +& "\n");
        print("Initial eq: " +& intString(listLength(ie)) +& "\n");
        print("Algorithms: " +& intString(listLength(al)) +& "\n");
        print("Initial al: " +& intString(listLength(ia)) +& "\n");
        print("end " +& inName +& "\n");
      then
        ();

  end match;
end printFlatProgram;

protected function printVar
  input Prefix inName;
  input SCode.Element inVar;
  input Absyn.Path inClassPath;
  input Item inClass;
algorithm
  _ := match(inName, inVar, inClassPath, inClass)
    local
      String name, cls;
      SCode.Element var;
      SCode.Prefixes pf;
      SCode.Flow fp;
      SCode.Stream sp;
      SCode.Variability vp;
      Absyn.Direction dp;
      SCode.Mod mod;
      Option<SCode.Comment> cmt;
      Option<Absyn.Exp> cond;
      Absyn.Info info;

    case (_, SCode.COMPONENT(_, pf, 
          SCode.ATTR(_, fp, sp, vp, dp), _, mod, cmt, cond, info), _,
        SCodeEnv.CLASS(classType = SCodeEnv.BASIC_TYPE()))
      equation
        name = printPrefix(inName);
        var = SCode.COMPONENT(name, pf, SCode.ATTR({}, fp, sp, vp, dp), 
          Absyn.TPATH(inClassPath, NONE()), mod, cmt, cond, info);
        print("  " +& SCodeDump.unparseElementStr(var) +& ";\n");
      then
        ();

    else ();
  end match;
end printVar;

protected function printComponent
  input Component inComponent;
  output String outString;
algorithm
  outString := match(inComponent)
    local
      Absyn.Path path;
      DAE.Exp binding;
      DAE.Type ty, ty2;

    case UNTYPED_COMPONENT(name = path, binding = UNTYPED_BINDING(bindingExp = binding))
      then Absyn.pathString(path) +& " = " +& ExpressionDump.printExpStr(binding);

    case UNTYPED_COMPONENT(name = path) 
      then Absyn.pathString(path);
      
    case TYPED_COMPONENT(name = path, ty = ty, binding = TYPED_BINDING(binding, ty2))
      then Types.unparseType(ty) +& " " +& Absyn.pathString(path) +& " = " +&
        Types.unparseType(ty2) +& " " +& ExpressionDump.printExpStr(binding);

    case TYPED_COMPONENT(name = path, ty = ty)
      then Types.unparseType(ty) +& " " +& Absyn.pathString(path);

    case CONDITIONAL_COMPONENT(name = path) 
      then "conditional " +& Absyn.pathString(path);

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

end SCodeInst;
