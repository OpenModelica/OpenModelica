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

encapsulated package NFInst
" file:        NFInst.mo
  package:     NFInst
  description: Instantiation

  RCS: $Id: NFInst.mo 14780 2013-01-15 08:47:24Z mahge930 $

  New instantiation, enable with +d=scodeInst.
"

public import Absyn;
public import NFConnect2;
public import DAE;
public import NFInstTypes;
public import HashTablePathToFunction;
public import SCode;
public import NFEnv;
public import NFMod;

protected import BaseHashTable;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Graph;
protected import List;
protected import NFConnectEquations;
protected import NFConnectUtil2;
protected import NFInstDump;
protected import NFInstFlatten;
protected import NFInstSymbolTable;
protected import NFInstUtil;
protected import NFLookup;
//protected import NFSCodeCheck;
protected import NFSCodeExpand;
protected import NFTypeCheck;
protected import NFTyping;
protected import SCodeDump;
protected import System;
protected import Types;
protected import Util;

public type Binding = NFInstTypes.Binding;
public type Class = NFInstTypes.Class;
public type Component = NFInstTypes.Component;
public type Condition = NFInstTypes.Condition;
public type Connections = NFConnect2.Connections;
public type Dimension = NFInstTypes.Dimension;
public type Element = NFInstTypes.Element;
public type Env = NFEnv.Env;
public type Equation = NFInstTypes.Equation;
public type Function = NFInstTypes.Function;
public type FunctionHashTable = HashTablePathToFunction.HashTable;
public type Modifier = NFInstTypes.Modifier;
public type ParamType = NFInstTypes.ParamType;
public type Prefixes = NFInstTypes.Prefixes;
public type Prefix = NFInstTypes.Prefix;
public type Statement = NFInstTypes.Statement;
public type ModTable = NFMod.ModTable;

protected type Entry = NFEnv.Entry;
protected type FunctionSlot = NFInstTypes.FunctionSlot;
protected type SymbolTable = NFInstSymbolTable.SymbolTable;
protected type Globals = tuple<SymbolTable, FunctionHashTable>;

protected uniontype InstPolicy
  record INST_ALL end INST_ALL;
  record INST_ONLY_CONST end INST_ONLY_CONST;
end InstPolicy;

public uniontype ExtendsState
  record NO_EXTENDS end NO_EXTENDS;
  record NORMAL_EXTENDS end NORMAL_EXTENDS;
  record SPECIAL_EXTENDS end SPECIAL_EXTENDS;
end ExtendsState;

public function instClass
  "Flattens a class."
  input Absyn.Path inClassPath;
  input Env inEnv;
  output DAE.DAElist outDae;
  output DAE.FunctionTree outGlobals;
algorithm
  (outDae, outGlobals) := matchcontinue(inClassPath, inEnv)
    local
      Entry top_cls;
      Env env;
      String name;
      Class cls;
      SymbolTable symtab, constants;
      FunctionHashTable functions;
      Connections conn;
      list<NFConnect2.Connector> flows;
      DAE.DAElist dae_conn, dae;
      DAE.FunctionTree func_tree;

    case (_, _)
      equation
        System.startTimer();
        name = Absyn.pathLastIdent(inClassPath);

        /*********************************************************************/
        /* ------------------------- INSTANTIATION ------------------------- */
        /*********************************************************************/

        // Look up the class to instantiate in the environment.
        (top_cls, env) = NFLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);

        //// Instantiate that class.
        functions = HashTablePathToFunction.emptyHashTableSized(BaseHashTable.lowBucketSize);
        constants = NFInstSymbolTable.create();
        (cls, _, _, (constants, functions)) = instClassEntry(inClassPath, top_cls,
          NFInstTypes.NOMOD(), NFMod.emptyModTable, NFInstTypes.NO_PREFIXES(), env,
          NFInstTypes.EMPTY_PREFIX(SOME(inClassPath)), INST_ALL(), (constants, functions));

        //builtin_el = instBuiltinElements((constants, functions));

        // print(NFInstDump.modelStr(name, cls)); print("\n");

        /*********************************************************************/
        /* ----------------------------- TYPING ---------------------------- */
        /*********************************************************************/

        // Build the symboltable to use for typing.
        symtab = NFInstSymbolTable.build(cls);
        // Add the package constants found during instantiation.
        symtab = NFInstSymbolTable.merge(symtab, constants);
        // Add any builtin elements we might need, like StateSelect.
        //symtab = NFInstSymbolTable.addClass(builtin_el, symtab);

        // Mark structural parameters.
        (cls, symtab) = assignParamTypes(cls, symtab);

        // Type all instantiated functions.
        ((functions, symtab)) = List.fold(BaseHashTable.hashTableKeyList(functions),
          NFTyping.typeFunction, (functions, symtab));

        // Type the instantiated class.
        (cls, symtab) = NFTyping.typeClass(cls, NFTyping.CONTEXT_MODEL(), symtab, functions);

        // Instantiate conditional components now that we have typed all crefs
        // that might be used as conditions.
        constants = NFInstSymbolTable.create();
        //(cls, symtab, (constants, functions)) =
        //  instConditionalComponents(cls, symtab, (constants, functions));

        // Type the instantiated class again, to type any instantiated
        // conditional components that might have been added.
        (cls, symtab) = NFTyping.typeClass(cls, NFTyping.CONTEXT_MODEL(), symtab, functions);

        // Type check the typed class components.
        (cls, symtab) = NFTypeCheck.checkClassComponents(cls, NFTyping.CONTEXT_MODEL(), symtab);

        // Type all equation and algorithm sections in the class.
        (cls, conn) = NFTyping.typeSections(cls, symtab, functions);

        // Generate connect equations.
        flows = NFConnectUtil2.collectFlowConnectors(cls);
        dae_conn = NFConnectEquations.generateEquations(conn, flows);

        System.stopTimer();

        //print(NFInstDump.modelStr(name, cls));

        //print("\n\nConnections:\n");
        //print(NFInstDump.connectionsStr(conn));
        //print("\n");

        //print("NFInst took " +& realString(System.getTimerIntervalTime()) +& " seconds.\n");

        /*********************************************************************/
        /* --------------------------- EXPANSION --------------------------- */
        /*********************************************************************/

        // Expand the instantiated and typed class into scalar components,
        // equations and algorithms.
        (dae, func_tree) = NFSCodeExpand.expand(name, cls, functions);
        dae = DAEUtil.appendToCompDae(dae, dae_conn);

        //print("\nEXPANDED FORM:\n\n");
        //print(DAEDump.dumpStr(dae, func_tree) +& "\n");
      then
        (dae, func_tree);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = Absyn.pathString(inClassPath);
        Debug.traceln("NFInst.instClass failed on " +& name);
      then
        fail();

  end matchcontinue;
end instClass;

protected function instClassEntry
  input Absyn.Path inTypePath;
  input Entry inEntry;
  input Modifier inClassMod;
  input ModTable inOuterMods;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input Globals inGlobals;
  output Class outClass;
  output DAE.Type outType;
  output Prefixes outPrefixes;
  output Globals outGlobals;
algorithm
  (outClass, outType, outPrefixes, outGlobals) := match(inTypePath, inEntry,
      inClassMod, inOuterMods, inPrefixes, inEnv, inPrefix, inInstPolicy, inGlobals)
    local
      Absyn.ArrayDim dims;
      Absyn.Info info;
      Absyn.Path path;
      Absyn.TypeSpec dty;
      Class cls;
      ClassInf.State state;
      DAE.Type ty;
      Entry entry;
      Env env;
      ExtendsState es;
      Globals globals;
      InstPolicy ip;
      Integer dim_count;
      list<DAE.Var> vars;
      list<Element> elems;
      list<Equation> eq, ieq;
      list<list<Statement>> alg, ialg;
      list<SCode.Element> el;
      list<SCode.Enum> enums;
      Modifier mod;
      ModTable mods;
      Prefixes prefs;
      SCode.Attributes attr;
      SCode.ClassDef cdef;
      SCode.Element scls;
      SCode.Mod smod;
      SCode.Restriction res;
      String name;

    // A builtin type (only builtin types can be PARTS).
    case (_, NFEnv.ENTRY(element = SCode.CLASS(name = name, restriction = SCode.R_TYPE(),
        classDef = SCode.PARTS(elementLst = _))), _, _, _, _, _, ip, globals)
      equation
        (vars, globals) = instBasicTypeAttributes(inClassMod, name, globals);
        ty = instBasicType(name, {});
      then
        (NFInstTypes.BASIC_TYPE(inTypePath), ty, NFInstTypes.NO_PREFIXES(), globals);

    // A class with parts, instantiate all elements in it.
    case (_, NFEnv.ENTRY(element = SCode.CLASS(name = name, restriction = res,
          classDef = cdef as SCode.PARTS(elementLst = el), info = info)), _, mods,
        _, _, _, ip, globals)
      equation
        // Enter the class scope.
        mods = NFMod.addClassModToTable(inClassMod, inOuterMods);
        env = NFLookup.enterEntryScope(inEntry, mods, inEnv);


        // Instantiate the class' elements.
        (elems, es, globals) = instElementList(el, mods, inPrefixes, env,
            inTypePath, inPrefix, ip, globals);

        // Instantiate all equation and algorithm sections.
        (eq, ieq, alg, ialg, globals) = instSections(cdef, env, inPrefix, ip, globals);

        // Flatten the class parts.
        cls = NFInstTypes.COMPLEX_CLASS(inTypePath, elems, eq, ieq, alg, ialg);
        cls = NFInstFlatten.flattenClass(cls, hasExtends(es));

        // Create the class' type.
        state = ClassInf.start(res, Absyn.IDENT(name));
        (cls, ty) = NFInstUtil.makeClassType(cls, state, hasSpecialExtends(es));
      then
        (cls, ty, NFInstTypes.NO_PREFIXES(), globals);

    // A derived class, look up the inherited class and instantiate it.
    case (_, NFEnv.ENTRY(element = scls as SCode.CLASS(name = name, classDef =
        SCode.DERIVED(modifications = smod, typeSpec = dty, attributes = attr),
        restriction = res, info = info)), _, _, _, _, _, ip, globals)
      equation
        // Look up the inherited class.
        (entry, env) = NFLookup.lookupTypeSpec(dty, inEnv, info);
        path = Absyn.typeSpecPath(dty);

        // Merge the modifiers and instantiate the inherited class.
        dims = Absyn.typeSpecDimensions(dty);
        dim_count = listLength(dims);
        mod = NFMod.translateMod(smod, "", dim_count, inPrefix, inEnv);
        mod = NFMod.mergeMod(inClassMod, mod);

        //    redecls = listAppend(
        //      NFSCodeEnv.getDerivedClassRedeclares(name, dty, envDerived),
        //      NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(smod));
        //      (item, env, _) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv, inPrefix);
        //

        (cls, ty, prefs, globals) = instClassEntry(inTypePath, entry, mod,
          inOuterMods, inPrefixes, env, inPrefix, ip, globals);

        // Merge the attributes of this class and the attributes of the
        // inherited class.
        prefs = NFInstUtil.mergePrefixesWithDerivedClass(path, scls, prefs);

        // Add any dimensions from this class to the resulting type.
        (ty, globals) = liftArrayType(dims, ty, inEnv, inPrefix, info, globals);

        // Construct the type for this derived class.
        state = ClassInf.start(res, Absyn.IDENT(name));
        ty = NFInstUtil.makeDerivedClassType(ty, state);
      then
        (cls, ty, prefs, globals);

    //case (_, NFSCodeEnv.CLASS(cls = scls, classType = NFSCodeEnv.CLASS_EXTENDS(), env = env),
    //    _, _, _, _, ip, globals)
    //  equation
    //    (cls, ty, globals) =
    //      instClassExtends(scls, inMod, inPrefixes, env, inEnv, inPrefix, ip, globals);
    //  then
    //    (cls, ty, NFInstTypes.NO_PREFIXES(), globals);

    case (_, NFEnv.ENTRY(element = SCode.CLASS(classDef =
        SCode.ENUMERATION(enumLst = enums), info = info)), _, _, _, _, _, _, globals)
      equation
        ty = NFInstUtil.makeEnumType(enums, inTypePath);
      then
        (NFInstTypes.BASIC_TYPE(inTypePath), ty, NFInstTypes.NO_PREFIXES(), globals);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFInst.instClassEntry failed on unknown class.\n");
      then
        fail();

  end match;
end instClassEntry;

//protected function instClassExtends
//  input SCode.Element inClassExtends;
//  input Modifier inMod;
//  input Prefixes inPrefixes;
//  input Env inClassEnv;
//  input Env inEnv;
//  input Prefix inPrefix;
//  input InstPolicy inInstPolicy;
//  input Globals inGlobals;
//  output Class outClass;
//  output DAE.Type outType;
//  output Globals outGlobals;
//algorithm
//  (outClass, outType, outGlobals) :=
//  matchcontinue(inClassExtends, inMod, inPrefixes, inClassEnv, inEnv, inPrefix,
//      inInstPolicy, inGlobals)
//    local
//      SCode.ClassDef cdef;
//      SCode.Mod mod;
//      SCode.Element scls, ext;
//      Absyn.Path bc_path;
//      Absyn.Info info;
//      String name;
//      Item item;
//      Env base_env, ext_env;
//      InstPolicy ip;
//      Class base_cls, ext_cls, comp_cls;
//      DAE.Type base_ty, ext_ty, comp_ty;
//      Globals globals;
//
//    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(modifications = mod,
//        composition = cdef)), _, _, _, _, _, ip, globals)
//      equation
//        (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
//        ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
//        cdef = SCode.addElementToCompositeClassDef(ext, cdef);
//        scls = SCode.setElementClassDefinition(cdef, inClassExtends);
//        item = NFSCodeEnv.CLASS(scls, inClassEnv, NFSCodeEnv.CLASS_EXTENDS());
//        (comp_cls, comp_ty, _, globals) = instClassItem(bc_path, item, inMod, inPrefixes, inEnv, inPrefix, ip, globals);
//      then
//        (comp_cls, comp_ty, globals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        name = SCode.elementName(inClassExtends);
//        Debug.traceln("NFInst.instClassExtends failed on " +& name);
//      then
//        fail();
//
//  end matchcontinue;
//end instClassExtends;
//
//protected function getClassExtendsBaseClass
//  input Env inClassEnv;
//  output Absyn.Path outPath;
//  output Absyn.Info outInfo;
//algorithm
//  (outPath, outInfo) := matchcontinue(inClassEnv)
//    local
//      Absyn.Path bc;
//      Absyn.Info info;
//      String name;
//
//    case (NFSCodeEnv.FRAME(extendsTable = NFSCodeEnv.EXTENDS_TABLE(
//        baseClasses = NFSCodeEnv.EXTENDS(baseClass = bc, info = info) :: _)) :: _)
//      then (bc, info);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        name = NFSCodeEnv.getEnvName(inClassEnv);
//        Debug.traceln("NFInst.getClassExtendsBaseClass failed on " +& name);
//      then
//        fail();
//
//  end matchcontinue;
//end getClassExtendsBaseClass;
//
protected function instBasicType
  input SCode.Ident inTypeName;
  input list<DAE.Var> inAttributes;
  output DAE.Type outType;
algorithm
  outType := match(inTypeName, inAttributes)
    case ("Real", _) then DAE.T_REAL(inAttributes, DAE.emptyTypeSource);
    case ("Integer", _) then DAE.T_INTEGER(inAttributes, DAE.emptyTypeSource);
    case ("String", _) then DAE.T_STRING(inAttributes, DAE.emptyTypeSource);
    case ("Boolean", _) then DAE.T_BOOL(inAttributes, DAE.emptyTypeSource);
    case ("StateSelect", _) then DAE.T_ENUMERATION_DEFAULT;
  end match;
end instBasicType;

protected function instBasicTypeAttributes
  input Modifier inMod;
  input String inTypeName;
  input Globals inGlobals;
  output list<DAE.Var> outVars;
  output Globals outGlobals;
algorithm
  (outVars, outGlobals) := match(inMod, inTypeName, inGlobals)
    local
      list<Modifier> submods;
      list<DAE.Var> vars;
      SCode.Element el;
      Absyn.Info info;
      Globals globals;

    case (NFInstTypes.NOMOD(), _, globals) then ({}, globals);

    case (NFInstTypes.MODIFIER(subModifiers = submods), _, globals)
      equation
        (vars, globals) =
          List.map1Fold(submods, instBasicTypeAttribute, inTypeName, globals);
      then
        (vars, globals);

    case (NFInstTypes.REDECLARE(element = el), _, _)
      equation
        info = SCode.elementInfo(el);
        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE, {}, info);
      then
        fail();

  end match;
end instBasicTypeAttributes;

protected function instBasicTypeAttribute
  input Modifier inMod;
  input String inTypeName;
  input Globals inGlobals;
  output DAE.Var outAttribute;
  output Globals outGlobals;
algorithm
  (outAttribute, outGlobals) := match(inMod, inTypeName, inGlobals)
    local
      String ident;
      DAE.Type ty;
      Absyn.Exp bind_exp;
      DAE.Exp inst_exp;
      DAE.Binding binding;
      Env env;
      Prefix prefix;
      Globals globals;
      Absyn.Info info;

    case (NFInstTypes.MODIFIER(name = ident, subModifiers = {}, binding =
        NFInstTypes.RAW_BINDING(bind_exp, env, prefix, _, _), info = info), _, globals)
      equation
        ty = getBasicTypeAttributeType(inTypeName, ident, info);
        (inst_exp, globals) = instExp(bind_exp, env, prefix, info, globals);
        binding = DAE.EQBOUND(inst_exp, NONE(), DAE.C_UNKNOWN(),
          DAE.BINDING_FROM_DEFAULT_VALUE());
      then
        (DAE.TYPES_VAR(ident, DAE.dummyAttrParam, ty, binding, NONE()), globals);

  end match;
end instBasicTypeAttribute;

protected function getBasicTypeAttributeType
  input String inTypeName;
  input String inAttributeName;
  input Absyn.Info inInfo;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inTypeName, inAttributeName, inInfo)
    case ("Real", _, _) then getBasicTypeAttrTypeReal(inAttributeName);
    case ("Integer", _, _) then getBasicTypeAttrTypeInt(inAttributeName);
    case ("Boolean", _, _) then getBasicTypeAttrTypeBool(inAttributeName);
    case ("String", _, _) then getBasicTypeAttrTypeString(inAttributeName);
    else
      equation
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {inAttributeName, inTypeName}, inInfo);
      then
        fail();

  end matchcontinue;
end getBasicTypeAttributeType;

protected function getBasicTypeAttrTypeReal
  input String inAttributeName;
  output DAE.Type outType;
algorithm
  outType := match(inAttributeName)
    case "quantity" then DAE.T_STRING_DEFAULT;
    case "unit" then DAE.T_STRING_DEFAULT;
    case "displayUnit" then DAE.T_STRING_DEFAULT;
    case "min" then DAE.T_REAL_DEFAULT;
    case "max" then DAE.T_REAL_DEFAULT;
    case "start" then DAE.T_REAL_DEFAULT;
    case "fixed" then DAE.T_BOOL_DEFAULT;
    case "nominal" then DAE.T_REAL_DEFAULT;
    case "stateSelect" then DAE.T_ENUMERATION_DEFAULT;
  end match;
end getBasicTypeAttrTypeReal;

protected function getBasicTypeAttrTypeInt
  input String inAttributeName;
  output DAE.Type outType;
algorithm
  outType := match(inAttributeName)
    case "quantity" then DAE.T_STRING_DEFAULT;
    case "min" then DAE.T_INTEGER_DEFAULT;
    case "max" then DAE.T_INTEGER_DEFAULT;
    case "start" then DAE.T_INTEGER_DEFAULT;
    case "fixed" then DAE.T_BOOL_DEFAULT;
  end match;
end getBasicTypeAttrTypeInt;

protected function getBasicTypeAttrTypeBool
  input String inAttributeName;
  output DAE.Type outType;
algorithm
  outType := match(inAttributeName)
    case "quantity" then DAE.T_STRING_DEFAULT;
    case "start" then DAE.T_BOOL_DEFAULT;
    case "fixed" then DAE.T_BOOL_DEFAULT;
  end match;
end getBasicTypeAttrTypeBool;

protected function getBasicTypeAttrTypeString
  input String inAttributeName;
  output DAE.Type outType;
algorithm
  outType := match(inAttributeName)
    case "quantity" then DAE.T_STRING_DEFAULT;
    case "start" then DAE.T_STRING_DEFAULT;
  end match;
end getBasicTypeAttrTypeString;




//protected function instBasicTypeAttribute
//  input Modifier inMod;
//  input NFSCodeEnv.AvlTree inAttributes;
//  input Globals inGlobals;
//  output DAE.Var outAttribute;
//  output Globals outGlobals;
//algorithm
//  (outAttribute, outGlobals) := match(inMod, inAttributes, inGlobals)
//    local
//      String ident, tspec;
//      DAE.Type ty;
//      Absyn.Exp bind_exp;
//      DAE.Exp inst_exp;
//      DAE.Binding binding;
//      Env env;
//      Prefix prefix;
//      Globals globals;
//      Absyn.Info info;
//
//    case (NFInstTypes.MODIFIER(name = ident, subModifiers = {},
//        binding = NFInstTypes.RAW_BINDING(bind_exp, env, prefix, _, _), info = info), _, globals)
//      equation
//        NFSCodeEnv.VAR(var = SCode.COMPONENT(typeSpec = Absyn.TPATH(path =
//          Absyn.IDENT(tspec)))) = NFSCodeEnv.avlTreeGet(inAttributes, ident);
//        ty = instBasicTypeAttributeType(tspec);
//        (inst_exp, globals) = instExp(bind_exp, env, prefix, info, globals);
//        binding = DAE.EQBOUND(inst_exp, NONE(), DAE.C_UNKNOWN(),
//          DAE.BINDING_FROM_DEFAULT_VALUE());
//      then
//        (DAE.TYPES_VAR(ident, DAE.dummyAttrParam, ty, binding, NONE()), globals);
//
//    // TODO: Print error message for invalid attributes.
//  end match;
//end instBasicTypeAttribute;
//
//protected function instBasicTypeAttributeType
//  input String inTypeName;
//  output DAE.Type outType;
//algorithm
//  outType := match(inTypeName)
//    case "$RealType" then DAE.T_REAL_DEFAULT;
//    case "$IntegerType" then DAE.T_INTEGER_DEFAULT;
//    case "$BooleanType" then DAE.T_BOOL_DEFAULT;
//    case "$StringType" then DAE.T_STRING_DEFAULT;
//    case "$EnumType" then DAE.T_ENUMERATION_DEFAULT;
//    case "StateSelect" then DAE.T_ENUMERATION_DEFAULT;
//  end match;
//end instBasicTypeAttributeType;
//

protected function instElementList
  input list<SCode.Element> inElements;
  input ModTable inModifiers;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Absyn.Path inTypePath;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input Globals inGlobals;
  output list<Element> outElements;
  output ExtendsState outExtendsState;
  output Globals outGlobals;
algorithm
  (outElements, outExtendsState, outGlobals) := instElementList2(inElements,
    inModifiers, inPrefixes, inEnv, inPrefix, inInstPolicy, {}, NO_EXTENDS(), inGlobals);
end instElementList;

protected function instElementList2
  input list<SCode.Element> inElements;
  input ModTable inModifiers;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input list<Element> inAccumEl;
  input ExtendsState inExtendsState;
  input Globals inGlobals;
  output list<Element> outElements;
  output ExtendsState outExtendsState;
  output Globals outGlobals;
algorithm
  (outElements, outExtendsState, outGlobals) :=
  match(inElements, inModifiers, inPrefixes, inEnv, inPrefix, inInstPolicy,
      inAccumEl, inExtendsState, inGlobals)
    local
      SCode.Element elem;
      list<SCode.Element> rest_el;
      ModTable mods;
      ExtendsState es;
      list<Element> accum_el;
      Globals globals;
      Env env;

    case (elem :: rest_el, mods, _, env, _, _, accum_el, es, globals)
      equation




        (elem, env) = resolveRedeclaredElement(elem, env);
        (accum_el, es, globals) = instElement(elem, mods, inPrefixes, env,
          inPrefix, inInstPolicy, accum_el, es, globals);
        (accum_el, es, globals) = instElementList2(rest_el, mods, inPrefixes,
          inEnv, inPrefix, inInstPolicy, accum_el, es, globals);
      then
        (accum_el, es, globals);

    case ({}, _, _, _, _, _, _, es, globals)
      then (listReverse(inAccumEl), es, globals);

  end match;
end instElementList2;

protected function resolveRedeclaredElement
  input SCode.Element inElement;
  input Env inEnv;
  output SCode.Element outElement;
  output Env outEnv;
algorithm
  (outElement, outEnv) := match(inElement, inEnv)
    local
      String name;
      SCode.Element elem;
      Env env;



    case (SCode.COMPONENT(name = name), _)
      equation
        (NFEnv.ENTRY(element = elem), env) =
          NFLookup.lookupInLocalScope(name, inEnv);
      then
        (elem, env);

    else (inElement, inEnv);

  end match;
end resolveRedeclaredElement;
        
//public function resolveRedeclaredElement
//  "This function makes sure that an element is up-to-date in case it has been
//   redeclared. This is achieved by looking the element up in the environment. In
//   the case that the element has been redeclared, the environment where it should
//   be instantiated is returned, otherwise the old environment."
//  input tuple<SCode.Element, Modifier> inElement;
//  input Env inEnv;
//  input Prefix inPrefix;
//  output tuple<SCode.Element, Modifier> outElement;
//  output Modifier outOriginalMod;
//  output Env outEnv;
//  output list<tuple<NFSCodeEnv.Item, Env>> outPreviousItem;
//algorithm
//  (outElement, outOriginalMod, outEnv, outPreviousItem) := match(inElement, inEnv, inPrefix)
//    local
//      Modifier mod, omod;
//      String name;
//      Item item;
//      SCode.Element orig_el, new_el;
//      Env env;
//      Boolean b;
//      list<tuple<NFSCodeEnv.Item, Env>> previousItem;
//
//    // Only components which are actually replaceable needs to be looked up,
//    // since non-replaceable components can't have been replaced.
//    case ((orig_el as SCode.COMPONENT(name = name, prefixes =
//        SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(_))), mod), _, _)
//      equation
//        (item, _) = NFSCodeLookup.lookupInClass(name, inEnv);
//        (NFSCodeEnv.VAR(var = new_el), env, previousItem) = NFSCodeEnv.resolveRedeclaredItem(item, inEnv);
//        omod = getOriginalMod(orig_el, inEnv, inPrefix);
//      then
//        ((new_el, mod), omod, env, previousItem);
//
//    // Other elements doesn't need to be looked up. Extends may not be
//    // replaceable, and classes are looked up in the environment anyway. The
//    // exception is packages with constants, but those are handled in
//    // instPackageConstants.
//    else (inElement, NFInstTypes.NOMOD(), inEnv, {});
//
//  end match;
//end resolveRedeclaredElement;
//
//protected function getOriginalMod
//  input SCode.Element inOriginalElement;
//  input Env inEnv;
//  input Prefix inPrefix;
//  output Modifier outModifier;
//algorithm
//  outModifier := match(inOriginalElement, inEnv, inPrefix)
//    local
//      SCode.Ident name;
//      Absyn.ArrayDim ad;
//      Integer dim_count;
//      SCode.Mod smod;
//      Modifier mod;
//
//    case (SCode.COMPONENT(modifications = SCode.NOMOD()), _, _)
//      then NFInstTypes.NOMOD();
//
//    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
//        modifications = smod), _, _)
//      equation
//        dim_count = listLength(ad);
//        mod = NFSCodeMod.translateMod(smod, name, dim_count, inPrefix, inEnv);
//      then
//        mod;
//
//  end match;
//end getOriginalMod;
//

protected function instElement
  input SCode.Element inElement;
  input ModTable inModifiers;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input list<Element> inAccumEl;
  input ExtendsState inExtendsState;
  input Globals inGlobals;
  output list<Element> outElements;
  output ExtendsState outExtendsState;
  output Globals outGlobals;
algorithm
  (outElements, outExtendsState, outGlobals) :=
  match(inElement, inModifiers, inPrefixes, inEnv, inPrefix, inInstPolicy,
      inAccumEl, inExtendsState, inGlobals)
    local
      Globals globals;
      ExtendsState es;
      Element res;
      Option<Element> ores;
      list<Element> accum_el;
      InstPolicy ip;
      String name;

    // A component when we're in 'instantiate everything' mode.
    case (SCode.COMPONENT(name = _), _, _, _, _, INST_ALL(), _, es, globals)
      equation
        (res, globals) = instComponent(inElement, inModifiers, inPrefixes,
          inEnv, inPrefix, inInstPolicy, globals);
      then
        (res :: inAccumEl, es, globals);

    // A constant when we're in 'instantiate only constants' mode.
    case (SCode.COMPONENT(attributes = SCode.ATTR(variability =
        SCode.CONST())), _, _, _, _, INST_ONLY_CONST(), _, es, globals)
      equation
        (res, globals) = instComponent(inElement, inModifiers, inPrefixes,
          inEnv, inPrefix, inInstPolicy, globals);
      then
        (res :: inAccumEl, es, globals);

    // An extends clause.
    case (SCode.EXTENDS(baseClassPath = _), _, _, _, _, ip, _, es, globals)
      equation
        (res, es, globals) = instExtends(inElement, inModifiers, inPrefixes,
          inEnv, inPrefix, es, ip, globals);
      then
        (res :: inAccumEl, es, globals);

    // A package which might contain constants we should instantiate.
    case (SCode.CLASS(name = name, restriction = SCode.R_PACKAGE()),
        _, _, _, _, ip, _, es, globals)
      equation
        (ores, globals) = instPackageConstants(inElement, inModifiers, inEnv,
          inPrefix, globals);
        accum_el = List.consOption(ores, inAccumEl);
      then
        (accum_el, es, globals);

    // Ignore everything else.
    else (inAccumEl, inExtendsState, inGlobals);

  end match;
end instElement;

protected function instComponent
  input SCode.Element inElement;
  input ModTable inModifiers;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input Globals inGlobals;
  output Element outElement;
  output Globals outGlobals;
algorithm
  (outElement, outGlobals) := match(inElement, inModifiers, inPrefixes, inEnv,
      inPrefix, inInstPolicy, inGlobals)
    local
      String name, enum_idx_str;
      Absyn.ArrayDim ad;
      Absyn.Info info;
      Absyn.Path tpath, path;
      SCode.Mod smod;
      InstPolicy ip;
      Globals globals;
      Entry cls_entry;
      Env env;
      list<DAE.Dimension> dims;
      Prefix prefix;
      Integer dim_count, enum_idx;
      Modifier mod, cmod;
      Prefixes prefs, cls_prefs;
      DAE.Type ty;
      ParamType pty;
      Binding binding;
      array<Dimension> dim_arr;
      Class cls;
      Component comp;

    // an outer component
    case (SCode.COMPONENT(name = name,
        typeSpec = Absyn.TPATH(path = tpath),
        prefixes = SCode.PREFIXES(innerOuter = Absyn.OUTER())), _, _, _, _, _, globals)
      equation
        prefix = NFInstUtil.addPrefix(name, {}, inPrefix);
        path = NFInstUtil.prefixToPath(prefix);
        comp = NFInstTypes.OUTER_COMPONENT(path, NONE());
      then
        (NFInstTypes.ELEMENT(comp, NFInstTypes.BASIC_TYPE(tpath)), globals);

    case (SCode.COMPONENT(name = name, typeSpec = Absyn.TPATH(path =
        Absyn.QUALIFIED(name = "$EnumType", path = tpath)), info = info),
        _, _, _, _, ip, globals)
      equation
        Absyn.QUALIFIED(name = enum_idx_str, path = tpath) = tpath;
        enum_idx = stringInt(enum_idx_str);

        (cls_entry, env) = NFLookup.lookupClassName(tpath, inEnv, info);
        path = NFInstUtil.prefixPath(Absyn.IDENT(name), inPrefix);

        (cls, ty, cls_prefs, globals) = instClassEntry(tpath, cls_entry, NFInstTypes.NOMOD(),
          NFMod.emptyModTable, inPrefixes, env, inPrefix, ip, globals);

        binding = NFInstTypes.TYPED_BINDING(DAE.ENUM_LITERAL(path, enum_idx), ty, -1, info);
        comp = NFInstTypes.TYPED_COMPONENT(path, ty, NONE(),
          NFInstTypes.DEFAULT_CONST_DAE_PREFIXES, binding, info);
      then
        (NFInstTypes.ELEMENT(comp, cls), globals);

    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
        typeSpec = Absyn.TPATH(path = tpath), modifications = smod,
        condition = NONE(), info = info), _, _, _, _, ip, globals)
      equation
        // Lookup the class of the component.
        (cls_entry, env) = NFLookup.lookupClassName(tpath, inEnv, info);

        // NFSCodeCheck.checkPartialInstance(cls_entry, info);

        // Instantiate array dimensions and add them to the prefix.
        (dims, globals) = instDimensions(ad, inEnv, inPrefix, info, globals);
        prefix = NFInstUtil.addPrefix(name, dims, inPrefix);

        // Check that it's legal to instantiate the class.
        //NFSCodeCheck.checkInstanceRestriction(cls_entry, prefix, info);

        // Translate the component's modification.
        dim_count = listLength(ad);
        mod = NFMod.translateMod(smod, name, dim_count, prefix, inEnv);

        // Merge the modifier from the class with this element's modifications.
        cmod = NFMod.getModFromTable(name, inModifiers);
        cmod = NFMod.propagateMod(cmod, dim_count);
        mod = NFMod.mergeMod(cmod, mod);

        // Merge prefixes from the instance hierarchy.
        path = NFInstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
        prefs = NFInstUtil.mergePrefixesFromComponent(path, inElement, inPrefixes);
        pty = NFInstUtil.paramTypeFromPrefixes(prefs);

        //redecl = NFMod.extractRedeclares(smod);

        (cls, ty, cls_prefs, globals) = instClassEntry(tpath, cls_entry, mod,
          NFMod.emptyModTable, prefs, env, prefix, ip, globals);

        prefs = NFInstUtil.mergePrefixes(prefs, cls_prefs, path, "variable");

        // Add dimensions from the class type.
        (dims, dim_count) = addDimensionsFromType(dims, ty);
        ty = NFInstUtil.arrayElementType(ty);
        dim_arr = NFInstUtil.makeDimensionArray(dims);

        // Instantiate the binding.
        mod = NFMod.propagateMod(mod, dim_count);
        binding = NFMod.modifierBinding(mod);
        (binding, globals) = instBinding(binding, dim_count, globals);

        // Create the component and add it to the program.
        comp = NFInstTypes.UNTYPED_COMPONENT(path, ty, dim_arr, prefs, pty, binding, info);
      then
        (NFInstTypes.ELEMENT(comp, cls), globals);

//    // A conditional component, save it for later.
//    case (SCode.COMPONENT(name = name, condition = SOME(cond_exp), info = info),
//        _, _, _, _, _, _, globals)
//      equation
//        path = NFInstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
//        (inst_exp, globals) = instExp(cond_exp, inEnv, inPrefix, info, globals);
//        comp = NFInstTypes.CONDITIONAL_COMPONENT(path, inst_exp, inElement,
//          inClassMod, inPrefixes, inEnv, inPrefix, info);
//      then
//        (NFInstTypes.CONDITIONAL_ELEMENT(comp), globals);
//

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFInst.instComponent failed on unknown component.\n");
      then
        fail();

  end match;
end instComponent;

protected function instExtends
  input SCode.Element inExtends;
  input ModTable inModifiers;
  input Prefixes inPrefixes;
  input Env inEnv;
  input Prefix inPrefix;
  input ExtendsState inExtendsState;
  input InstPolicy inInstPolicy;
  input Globals inGlobals;
  output Element outElement;
  output ExtendsState outExtendsState;
  output Globals outGlobals;
algorithm
  (outElement, outExtendsState, outGlobals) := match(inExtends, inModifiers,
      inPrefixes, inEnv, inPrefix, inExtendsState, inInstPolicy, inGlobals)
    local
      Absyn.Path path;
      Absyn.Info info;
      Entry entry;
      Env env;
      Class cls;
      DAE.Type ty;
      ExtendsState es;
      InstPolicy ip;
      Prefixes prefs;
      Globals globals;
      SCode.Mod smod;
      Modifier mod;
      Boolean special_ext;
      ModTable mods;

    case (SCode.EXTENDS(baseClassPath = path, modifications = smod, info = info),
        mods, _, _, _, es, ip, globals)
      equation
        // Look up the base class in the environment.
        (entry, env) = NFLookup.lookupBaseClassName(path, inEnv, info);
//
//        // Apply the redeclarations.
//        (item, env, _) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(
//          inRedeclares, item, env, inEnv, inPrefix);
//
//        // Instantiate the class.
        prefs = NFInstUtil.mergePrefixesFromExtends(inExtends, inPrefixes);
        mod = NFMod.translateMod(smod, "", 0, inPrefix, inEnv);

        (cls, ty, _, globals) =
          instClassEntry(path, entry, mod, mods, prefs, env, inPrefix, ip, globals);

        special_ext = NFInstUtil.isSpecialExtends(ty);
        es = updateExtendsState(es, special_ext);
      then
        (NFInstTypes.EXTENDED_ELEMENTS(path, cls, ty), es, globals);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFInst.instExtends failed on unknown element.\n");
      then
        fail();

  end match;
end instExtends;

protected function updateExtendsState
  "The 'extends state' is used to determine if a class contains any extends, and
   if any of those extends are 'special'. Special extends are e.g. extending a
   base type, which is handled differently than normal extends. The extends
   state is a state machine which can only move in one direction: no extends ->
   normal extends -> special extends."
  input ExtendsState inCurrentState;
  input Boolean inFoundSpecialExtends;
  output ExtendsState outNewState;
algorithm
  outNewState := match(inCurrentState, inFoundSpecialExtends)
    // Already found special extends, no change.
    case (SPECIAL_EXTENDS(), _) then inCurrentState;
    // Found special extends, move to special extends state.
    case (_, true) then SPECIAL_EXTENDS();
    // Otherwise we found a normal extends, move to normal extends state.
    else NORMAL_EXTENDS();
  end match;
end updateExtendsState;

protected function hasExtends
  input ExtendsState inCurrentState;
  output Boolean outHasExtends;
algorithm
  outHasExtends := match(inCurrentState)
    case NO_EXTENDS() then false;
    else true;
  end match;
end hasExtends;

protected function hasSpecialExtends
  input ExtendsState inCurrentState;
  output Boolean outSpecialExtends;
algorithm
  outSpecialExtends := match(inCurrentState)
    case SPECIAL_EXTENDS() then true;
    else false;
  end match;
end hasSpecialExtends;

protected function instPackageConstants
  input SCode.Element inPackage;
  input ModTable inModifiers;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output Option<Element> outElement;
  output Globals outGlobals;
algorithm
  (outElement,outGlobals) := match(inPackage, inModifiers, inEnv, inPrefix, inGlobals)
    local
      String name;
      Option<Element> oel;
      Prefix prefix;
      Entry entry;
      Class cls;
      Globals globals;
      Env env;

    case (SCode.CLASS(partialPrefix = SCode.PARTIAL()), _, _, _, _)
      then (NONE(),inGlobals);

    case (SCode.CLASS(name = name), _, _, _, globals)
      equation
        (entry, env) = NFLookup.lookupInLocalScope(name, inEnv);
        prefix = NFInstUtil.addPrefix(name, {}, inPrefix);
        (cls, _, _, globals) = instClassEntry(Absyn.IDENT(name), entry, NFInstTypes.NOMOD(),
          inModifiers, NFInstTypes.NO_PREFIXES(), env, prefix, INST_ONLY_CONST(), globals);
        oel = makeConstantsPackage(prefix, cls);
      then
        (oel, globals);

    else (NONE(), inGlobals);

  end match;
end instPackageConstants;

protected function makeConstantsPackage
  input Prefix inPrefix;
  input Class inClass;
  output Option<Element> outElement;
algorithm
  outElement := match(inPrefix, inClass)
    local
      Absyn.Path name;
      Element el;

    case (_, NFInstTypes.COMPLEX_CLASS(_, _ :: _, {}, {}, {}, {}))
      equation
        name = NFInstUtil.prefixToPath(inPrefix);
        el = NFInstTypes.ELEMENT(NFInstTypes.PACKAGE(name, NONE()), inClass);
      then
        SOME(el);

    case (_, NFInstTypes.COMPLEX_CLASS(components = _ :: _))
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFInst.makeConstantsPackage got complex class with equations or algorithms!"});
      then
        fail();

    else NONE();

  end match;
end makeConstantsPackage;

//protected function instEnumLiterals
//  input list<SCode.Enum> inEnumLiterals;
//  input Absyn.Path inEnumPath;
//  input DAE.Type inType;
//  input Integer inIndex;
//  input list<Element> inAccumEl;
//  output list<Element> outElements;
//algorithm
//  outElements :=
//  match(inEnumLiterals, inEnumPath, inType, inIndex, inAccumEl)
//    local
//      SCode.Enum enum_lit;
//      list<SCode.Enum> rest_lits;
//      Element el;
//      list<Element> acc;
//
//    case ({}, _, _, _, _) then inAccumEl;
//
//    case (enum_lit :: rest_lits, _, _, _, _)
//      equation
//        el = instEnumLiteral(enum_lit, inEnumPath, inType, inIndex);
//        // adrpo: we need to append it because otherwise is reverse and has the wrong index!
//        acc = listAppend(inAccumEl, {el});
//      then
//        instEnumLiterals(rest_lits, inEnumPath, inType, inIndex + 1, acc);
//
//  end match;
//end instEnumLiterals;
//
//protected function instEnumLiteral
//  input SCode.Enum inEnumLiteral;
//  input Absyn.Path inEnumPath;
//  input DAE.Type inType;
//  input Integer inIndex;
//  output Element outElement;
//algorithm
//  outElement := match(inEnumLiteral, inEnumPath, inType, inIndex)
//    local
//      String name;
//      Absyn.Path path;
//      Component comp;
//
//    case (SCode.ENUM(literal = name), _, _, _)
//      equation
//        path = Absyn.suffixPath(inEnumPath, name);
//        comp = NFInstUtil.makeEnumLiteralComp(path, inType, inIndex);
//      then
//        NFInstTypes.ELEMENT(comp, NFInstTypes.BASIC_TYPE(inEnumPath));
//
//  end match;
//end instEnumLiteral;
//
//protected function instBuiltinElements
//  input Globals inGlobals;
//  output Class outElements;
//algorithm
//  outElements := matchcontinue(inGlobals)
//    local
//      Class stateselect_cls;
//
//    case (_)
//      equation
//        (stateselect_cls, _, _, _) = instClassItem(Absyn.IDENT("StateSelect"),
//          NFLookup.BUILTIN_STATESELECT, NFInstTypes.NOMOD(),
//          NFInstTypes.NO_PREFIXES(), {}, NFInstTypes.EMPTY_PREFIX(NONE()),
//          INST_ALL(), inGlobals);
//      then
//        stateselect_cls;
//
//  end matchcontinue;
//end instBuiltinElements;
//
protected function instBinding
  input Binding inBinding;
  input Integer inCompDimensions;
  input Globals inGlobals;
  output Binding outBinding;
  output Globals outGlobals;
algorithm
  (outBinding, outGlobals) := match(inBinding, inCompDimensions, inGlobals)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      Env env;
      Prefix prefix;
      Integer pl, cd;
      Absyn.Info info;
      Globals globals;

    case (NFInstTypes.RAW_BINDING(aexp, env, prefix, pl, info), cd, globals)
      equation
        (dexp, globals) = instExp(aexp, env, prefix, info, globals);
      then
        (NFInstTypes.UNTYPED_BINDING(dexp, false, pl, info), globals);

    else (inBinding,inGlobals);

  end match;
end instBinding;

protected function instDimensions
  input list<Absyn.Subscript> inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output list<DAE.Dimension> outDimensions;
  output Globals outGlobals;
algorithm
  (outDimensions, outGlobals) :=
    List.map3Fold(inSubscript, instDimension, inEnv, inPrefix, inInfo, inGlobals);
end instDimensions;

protected function instDimension
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.Dimension outDimension;
  output Globals outGlobals;
algorithm
  (outDimension, outGlobals) :=
  match(inSubscript, inEnv, inPrefix, inInfo, inGlobals)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      Globals globals;

    case (Absyn.NOSUB(), _, _, _, _) then (DAE.DIM_UNKNOWN(),inGlobals);

    case (Absyn.SUBSCRIPT(subscript = aexp), _, _, _, globals)
      equation
        (dexp, globals) = instExp(aexp, inEnv, inPrefix, inInfo, globals);
      then
        (NFInstUtil.makeDimension(dexp), globals);

  end match;
end instDimension;

protected function instSubscripts
  input list<Absyn.Subscript> inSubscripts;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output list<DAE.Subscript> outSubscripts;
  output Globals outGlobals;
algorithm
  (outSubscripts, outGlobals) :=
    List.map3Fold(inSubscripts, instSubscript, inEnv, inPrefix, inInfo, inGlobals);
end instSubscripts;

protected function instSubscript
  input Absyn.Subscript inSubscript;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.Subscript outSubscript;
  output Globals outGlobals;
algorithm
  (outSubscript, outGlobals) :=
  match(inSubscript, inEnv, inPrefix, inInfo, inGlobals)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      Globals globals;

    case (Absyn.NOSUB(), _, _, _, globals) then (DAE.WHOLEDIM(), globals);

    case (Absyn.SUBSCRIPT(subscript = aexp), _, _, _, globals)
      equation
        (dexp, globals) = instExp(aexp, inEnv, inPrefix, inInfo, globals);
      then
        (makeSubscript(dexp), globals);

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
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.Type outType;
  output Globals outGlobals;
algorithm
  (outType, outGlobals) :=
  match(inDims, inType, inEnv, inPrefix, inInfo, inGlobals)
    local
      DAE.Dimensions dims1, dims2;
      DAE.TypeSource src;
      DAE.Type ty;
      Globals globals;

    case ({}, _, _, _, _, _) then (inType,inGlobals);
    case (_, DAE.T_ARRAY(ty, dims1, src), _, _, _, globals)
      equation
        (dims2, globals) =
          List.map3Fold(inDims, instDimension, inEnv, inPrefix, inInfo, globals);
        dims1 = listAppend(dims2, dims1);
      then
        (DAE.T_ARRAY(ty, dims1, src), globals);

    else
      equation
        (dims2, globals) =
          List.map3Fold(inDims, instDimension, inEnv, inPrefix, inInfo, inGlobals);
      then
        (DAE.T_ARRAY(inType, dims2, DAE.emptyTypeSource), globals);

  end match;
end liftArrayType;

protected function addDimensionsFromType
  input list<DAE.Dimension> inDimensions;
  input DAE.Type inType;
  output list<DAE.Dimension> outDimensions;
  output Integer outAddedDims;
algorithm
  (outDimensions, outAddedDims) := matchcontinue(inDimensions, inType)
    local
      list<DAE.Dimension> dims;
      Integer added_dims;

    case (_, _)
      equation
        dims = Types.getDimensions(inType);
        added_dims = listLength(dims);
        dims = listAppend(inDimensions, dims);
      then
        (dims, added_dims);

    else (inDimensions, 0);

  end matchcontinue;
end addDimensionsFromType;

protected function instExpList
  input list<Absyn.Exp> inExp;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output list<DAE.Exp> outExp;
  output Globals outGlobals;
algorithm
  (outExp, outGlobals) :=
    List.map3Fold(inExp, instExp, inEnv, inPrefix, inInfo, inGlobals);
end instExpList;

protected function instExpOpt
  input Option<Absyn.Exp> inExp;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output Option<DAE.Exp> outExp;
  output Globals outGlobals;
algorithm
  (outExp, outGlobals) := match (inExp, inEnv, inPrefix, inInfo, inGlobals)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      Globals globals;

    case (SOME(aexp), _, _, _, globals)
      equation
        (dexp, globals) = instExp(aexp, inEnv, inPrefix, inInfo, globals);
      then
        (SOME(dexp), globals);

    else (NONE(), inGlobals);

  end match;
end instExpOpt;

//protected function isBuiltinFunctionName
//"@author: adrpo
// check if the name is a builtin function or operator
// TODO FIXME, add all of them"
//  input Absyn.ComponentRef functionName;
//  output Boolean isBuiltinFname;
//algorithm
//  isBuiltinFname := matchcontinue(functionName)
//    local
//      String name;
//      Boolean b;
//      Absyn.ComponentRef fname;
//
//    case (Absyn.CREF_FULLYQUALIFIED(fname))
//      then
//        isBuiltinFunctionName(fname);
//
//    case (Absyn.CREF_IDENT(name, {}))
//      equation
//        b = listMember(name,
//          {
//            "noEvent",
//            "smooth",
//            "sample",
//            "pre",
//            "edge",
//            "change",
//            "reinit",
//            "size",
//            "rooted",
//            "transpose",
//            "skew",
//            "identity",
//            "min",
//            "max",
//            "cross",
//            "diagonal",
//            "abs",
//            "sum",
//            "product",
//            "assert",
//            "array",
//            "cat",
//            "rem",
//            "actualStream",
//            "inStream",
//            "String",
//            "Real",
//            "Integer"
//            });
//      then
//        b;
//
//    case (_) then false;
//  end matchcontinue;
//end isBuiltinFunctionName;
//
//protected function instBuiltinFunctionCall
//"@author: adrpo
// build all the builtin calls that are not complete in ModelicaBuiltin.mo
// TODO FIXME, add all"
//  input Absyn.Exp inExp;
//  input Env inEnv;
//  input Prefix inPrefix;
//  input Absyn.Info inInfo;
//  input Globals inGlobals;
//  output DAE.Exp outExp;
//  output Globals outGlobals;
//algorithm
//  (outExp,outGlobals) := match (inExp, inEnv, inPrefix, inInfo, inGlobals)
//    local
//      Absyn.ComponentRef acref;
//      Absyn.Exp aexp1, aexp2;
//      DAE.Exp dexp1, dexp2;
//      list<Absyn.Exp>  afargs;
//      list<Absyn.NamedArg> anamed_args;
//      Globals globals;
//      Absyn.Path call_path;
//      list<DAE.Exp> pos_args, args;
//      list<tuple<String, DAE.Exp>> named_args;
//      list<Element> inputs, outputs;
//      Absyn.ForIterators iters;
//      Env env;
//
//    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
//        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1, aexp2})), _, _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
//        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.SIZE(dexp1, SOME(dexp2)), globals);
//
//    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
//        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.SIZE(dexp1, NONE()), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "smooth"),
//        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1, aexp2})), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
//        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1,dexp2}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "rooted"),
//        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "transpose"),
//        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "skew"),
//        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "min"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "max"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "cross"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "diagonal"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "abs"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "product"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "pre"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "noEvent"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "sum"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "assert"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "change"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "array"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "array"),
//        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
//        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "sum"),
//        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
//        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "min"),
//        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
//        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "max"),
//        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
//        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "product"),
//        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
//        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "cat"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "rem"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "actualStream"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "inStream"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "String"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "Integer"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "Real"),
//        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
//      equation
//        call_path = Absyn.crefToPath(acref);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//      then
//        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
//
//    // hopefully all the other ones have a complete entry in ModelicaBuiltin.mo
//    case (Absyn.CALL(function_ = acref,
//        functionArgs = Absyn.FUNCTIONARGS(afargs, anamed_args)), _, _, _, globals)
//      equation
//        (call_path, NFInstTypes.FUNCTION(inputs=inputs,outputs=outputs), globals) = instFunction(acref, inEnv, inPrefix, inInfo, globals);
//        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
//        (named_args, globals) = List.map3Fold(anamed_args, instNamedArg, inEnv, inPrefix, inInfo, globals);
//        args = fillFunctionSlots(pos_args, named_args, inputs, call_path, inInfo);
//      then
//        (DAE.CALL(call_path, args, DAE.callAttrBuiltinOther), globals);
//
// end match;
//end instBuiltinFunctionCall;

protected function instFunctionCallDispatch
  input Absyn.Exp inExp;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.Exp outExp;
  output Globals outGlobals;
algorithm
  (outExp,outGlobals) := matchcontinue (inExp, inEnv, inPrefix, inInfo, inGlobals)
    local
      String str;
      Boolean bval;
      Absyn.ComponentRef funcName;
      DAE.Exp dexp1;
      list<Absyn.Exp>  afargs;
      list<Absyn.NamedArg> named_args;
      Globals globals;

    // handle builtin
//    case (Absyn.CALL(function_ = funcName), _, _, _, _)
//      equation
//        true = isBuiltinFunctionName(funcName);
//        (dexp1, globals) = instBuiltinFunctionCall(inExp, inEnv, inPrefix, inInfo, inGlobals);
//      then
//        (dexp1, globals);

    // handle normal calls
    case (Absyn.CALL(function_ = funcName,
        functionArgs = Absyn.FUNCTIONARGS(afargs, named_args)), _, _, _, globals)
      equation
        //false = isBuiltinFunctionName(funcName);
        (dexp1, globals) = instFunctionCall(funcName, afargs, named_args, inEnv, inPrefix, inInfo, globals);
      then
        (dexp1, globals);

    // failure
    case (Absyn.CALL(function_ = funcName), _, _, _, globals)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        //bval = isBuiltinFunctionName(funcName);
        bval = false;
        str = Util.if_(bval, "*builtin*", "*regular*");
        Debug.traceln("Failed to instantiate call to " +& str +& " function: " +&
          Dump.printExpStr(inExp) +& " at position:" +& Error.infoStr(inInfo));
      then
        fail();

    // handle normal calls - put here for debugging so if it fails above you still can debug after.
    // Let's keep this commented out when not used, otherwise we'll get duplicate error messages.
    //case (Absyn.CALL(function_ = funcName,
    //    functionArgs = Absyn.FUNCTIONARGS(afargs, named_args)), _, _, _, globals)
    //  equation
    //    false = isBuiltinFunctionName(funcName);
    //    (dexp1, globals) = instFunctionCall(funcName, afargs, named_args, inEnv, inPrefix, inInfo, globals);
    //  then
    //    (dexp1, globals);

 end matchcontinue;
end instFunctionCallDispatch;

protected function instExp
  input Absyn.Exp inExp;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.Exp outExp;
  output Globals outGlobals;
algorithm
  (outExp, outGlobals) := match(inExp, inEnv, inPrefix, inInfo, inGlobals)
    local
      Integer ival;
      Real rval;
      String sval, str;
      Boolean bval;
      Absyn.ComponentRef acref;
      DAE.ComponentRef dcref;
      Absyn.Exp aexp1, aexp2, e1, e2, e3;
      DAE.Exp dexp1, dexp2, dexp3;
      Absyn.Operator aop;
      DAE.Operator dop;
      list<Absyn.Exp> aexpl;
      list<DAE.Exp> dexpl;
      list<list<Absyn.Exp>> mat_expl;
      Option<Absyn.Exp> oaexp;
      Option<DAE.Exp> odexp;
      Globals globals;

    case (Absyn.REAL(value = rval), _, _, _, globals)
      then (DAE.RCONST(rval), globals);

    case (Absyn.INTEGER(value = ival), _, _, _, globals)
      then (DAE.ICONST(ival), globals);

    case (Absyn.BOOL(value = bval), _, _, _, globals)
      then (DAE.BCONST(bval), globals);

    case (Absyn.STRING(value = sval), _, _, _, globals)
      then (DAE.SCONST(sval), globals);

    case (Absyn.CREF(componentRef = acref), _, _, _, globals)
      equation
        (dcref, globals) = instCref(acref, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.CREF(dcref, DAE.T_UNKNOWN_DEFAULT), globals);

    case (Absyn.BINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _, _, globals)
      equation
        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
        dop = instOperator(aop);
      then
        (DAE.BINARY(dexp1, dop, dexp2), globals);

    case (Absyn.UNARY(op = aop, exp = aexp1), _, _, _, globals)
      equation
        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
        dop = instOperator(aop);
      then
        (DAE.UNARY(dop, dexp1), globals);

    case (Absyn.LBINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _, _, globals)
      equation
        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
        dop = instOperator(aop);
      then
        (DAE.LBINARY(dexp1, dop, dexp2), globals);

    case (Absyn.LUNARY(op = aop, exp = aexp1), _, _, _, globals)
      equation
        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
        //dop = instOperator(aop);
        dop = DAE.NOT(DAE.T_BOOL_DEFAULT);
      then
        (DAE.LUNARY(dop, dexp1), globals);

    case (Absyn.RELATION(exp1 = aexp1, op = aop, exp2 = aexp2), _, _, _, globals)
      equation
        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
        dop = instOperator(aop);
      then
        (DAE.RELATION(dexp1, dop, dexp2, -1, NONE()), globals);

    case (Absyn.ARRAY(arrayExp = aexpl), _, _, _, globals)
      equation
        (dexp1, globals) = instArray(aexpl, inEnv, inPrefix, inInfo, globals);
      then
        (dexp1, globals);

    case (Absyn.MATRIX(matrix = mat_expl), _, _, _, globals)
      equation
        (dexpl, globals) =
          List.map3Fold(mat_expl, instArray, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, dexpl), globals);

    case (Absyn.CALL(function_ = _), _, _, _, _)
      equation
        (dexp1, globals) = instFunctionCallDispatch(inExp, inEnv, inPrefix, inInfo, inGlobals);
      then
        (dexp1, globals);

    case (Absyn.RANGE(start = aexp1, step = oaexp, stop = aexp2), _, _, _, globals)
      equation
        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
        (odexp, globals) = instExpOpt(oaexp, inEnv, inPrefix, inInfo, globals);
        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.RANGE(DAE.T_UNKNOWN_DEFAULT, dexp1, odexp, dexp2), globals);

    case (Absyn.TUPLE(expressions = aexpl), _, _, _, globals)
      equation
        (dexpl, globals) = instExpList(aexpl, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.TUPLE(dexpl), globals);

    case (Absyn.LIST(exps = aexpl), _, _, _, globals)
      equation
        (dexpl, globals) = instExpList(aexpl, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.LIST(dexpl), globals);

    case (Absyn.CONS(head = aexp1, rest = aexp2), _, _, _, globals)
      equation
        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.CONS(dexp1, dexp2), globals);

    case (Absyn.IFEXP(ifExp = _), _, _, _, globals)
      equation
        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(inExp);
        (dexp1, globals) = instExp(e1, inEnv, inPrefix, inInfo, globals);
        (dexp2, globals) = instExp(e2, inEnv, inPrefix, inInfo, globals);
        (dexp3, globals) = instExp(e3, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.IFEXP(dexp1, dexp2, dexp3), globals);

    //Absyn.PARTEVALFUNCTION
    //Absyn.END
    //Absyn.CODE
    //Absyn.AS
    //Absyn.MATCHEXP

    else
      equation
        str = Dump.printExpStr(inExp);
        str = "NFInst.instExp: Unhandled Expression FIXME: " +& str;
        print(str +& "\n");
      then
        (DAE.SCONST(str),inGlobals);

  end match;
end instExp;

protected function instArray
  input list<Absyn.Exp> inExpl;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.Exp outArray;
  output Globals outGlobals;
protected
  list<DAE.Exp> expl;
algorithm
  (expl,outGlobals) :=
    List.map3Fold(inExpl, instExp, inEnv, inPrefix, inInfo, inGlobals);
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
    // logical have boolean type
    case Absyn.AND() then DAE.AND(DAE.T_BOOL_DEFAULT);
    case Absyn.OR() then DAE.OR(DAE.T_BOOL_DEFAULT);
    case Absyn.NOT() then DAE.NOT(DAE.T_BOOL_DEFAULT);
    // relational have boolean type too
    case Absyn.LESS() then DAE.LESS(DAE.T_BOOL_DEFAULT);
    case Absyn.LESSEQ() then DAE.LESSEQ(DAE.T_BOOL_DEFAULT);
    case Absyn.GREATER() then DAE.GREATER(DAE.T_BOOL_DEFAULT);
    case Absyn.GREATEREQ() then DAE.GREATEREQ(DAE.T_BOOL_DEFAULT);
    case Absyn.EQUAL() then DAE.EQUAL(DAE.T_BOOL_DEFAULT);
    case Absyn.NEQUAL() then DAE.NEQUAL(DAE.T_BOOL_DEFAULT);
  end match;
end instOperator;

protected function instCref
  "This function instantiates a cref, which means translating if from Absyn to
   DAE representation and prefixing it with the correct prefix so that it can
   be uniquely identified in the symbol table."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.ComponentRef outCref;
  output Globals outGlobals;
algorithm
  (outCref,outGlobals) :=
  matchcontinue(inCref, inEnv, inPrefix, inInfo, inGlobals)
    local
      Absyn.ComponentRef acref;
      DAE.ComponentRef cref;
      Absyn.Path path;
      Globals globals;

    case (Absyn.WILD(), _, _, _, _) then (DAE.WILD(),inGlobals);
    case (Absyn.ALLWILD(), _, _, _, _) then (DAE.WILD(),inGlobals);
    case (Absyn.CREF_FULLYQUALIFIED(acref), _, _, _, globals)
      equation
        (cref, globals) = instCref2(acref, inEnv, inPrefix, inInfo, globals);
        path = Absyn.crefToPathIgnoreSubs(inCref);
        (cref, globals) = instPackageConstant(true, cref, path, inEnv, inInfo, inGlobals);
      then
        (cref, globals);

    case (_, _, _, _, globals)
      equation
        (cref, globals) = instCref2(inCref, inEnv, inPrefix, inInfo, globals);
        path = Absyn.crefToPathIgnoreSubs(inCref);
        (cref, globals) = prefixCref(cref, path, inPrefix, inEnv, inInfo, globals);
      then
        (cref, globals);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFInst.instCref failed on " +& Dump.printComponentRefStr(inCref));
      then
        fail();

  end matchcontinue;
end instCref;

protected function instCref2
  "Helper function to instCref, converts an Absyn.ComponentRef to a
   DAE.ComponentRef. This is done by instantiating the cref's subscripts, and
   constructing a DAE.ComponentRef with unknown type (which is filled in during
   typing later on)."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.ComponentRef outCref;
  output Globals outGlobals;
algorithm
  (outCref,outGlobals) := match(inCref, inEnv, inPrefix, inInfo, inGlobals)
    local
      String name;
      Absyn.ComponentRef cref;
      DAE.ComponentRef dcref;
      list<Absyn.Subscript> asubs;
      list<DAE.Subscript> dsubs;
      Globals globals;

    case (Absyn.CREF_IDENT(name, asubs), _, _, _, globals)
      equation
        (dsubs, globals) =
          instSubscripts(asubs, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, dsubs), globals);

    case (Absyn.CREF_QUAL(name, asubs, cref), _, _, _, globals)
      equation
        (dsubs, globals) =
          instSubscripts(asubs, inEnv, inPrefix, inInfo, globals);
        (dcref, globals) = instCref2(cref, inEnv, inPrefix, inInfo, globals);
      then
        (DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, dsubs, dcref), globals);

    case (Absyn.CREF_FULLYQUALIFIED(cref), _, _, _, globals)
      equation
        (dcref, globals) = instCref2(cref, inEnv, inPrefix, inInfo, globals);
      then
        (dcref, globals);

  end match;
end instCref2;

protected function prefixCref
  "Prefixes a cref so that it can be uniquely identified in the symbol table."
  input DAE.ComponentRef inCref;
  input Absyn.Path inCrefPath;
  input Prefix inPrefix;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.ComponentRef outCref;
  output Globals outGlobals;
algorithm
  (outCref, outGlobals) :=
  matchcontinue(inCref, inCrefPath, inPrefix, inEnv, inInfo, inGlobals)
    local
      Env env;
      Entry entry;
      DAE.ComponentRef cref;
      Boolean   is_global;
      String name_str, env_str;
      Globals globals;

    case (_, _, _, _, _, _)
      equation
        name_str = ComponentReference.crefFirstIdent(inCref);
        (is_global, entry, env) = NFLookup.isNameGlobal(name_str, inEnv);
        (_, _) = NFLookup.lookupVariableName(inCrefPath, inEnv, inInfo);

        cref = prefixCref2(inCref, inPrefix, inEnv, env, is_global);
        (cref, globals) = instPackageConstant(is_global, cref, inCrefPath, env, inInfo, inGlobals);
      then
        (cref, globals);

  end matchcontinue;
end prefixCref;

protected function prefixCref2
  "Helper function to prefixCref."
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input Env inOriginEnv;
  input Env inFoundEnv;
  input Boolean inIsGlobal;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inPrefix, inOriginEnv, inFoundEnv, inIsGlobal)

    // Dispatch to the correct function based on whether the cref was found
    // in a local or global scope.
    case (_, _, _, _, false) then prefixLocalCref(inCref, inPrefix, inFoundEnv);
    else prefixGlobalCref(inCref, inPrefix, inOriginEnv, inFoundEnv);

  end match;
end prefixCref2;

protected function prefixLocalCref
  "Prefixes a local cref, i.e. a cref that was found in the local scope."
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input Env inEnv "The environment where we found the cref.";
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inPrefix, inEnv)
    local
      String id;
      Integer iterIndex;
      DAE.Type ty;
      list<DAE.Subscript> subs;

    // Don't prefix iterators.
    case (DAE.CREF_IDENT(id, ty, subs), _, _)
      equation
        iterIndex = NFEnv.getImplicitScopeIndex(inEnv);
      then
        DAE.CREF_ITER(id, iterIndex, ty, subs);

    // In any other case, apply the given prefix.
    else NFInstUtil.prefixCref(inCref, inPrefix);

  end matchcontinue;
end prefixLocalCref;

protected function prefixGlobalCref
  "Prefixes a global cref, i.e. a cref that was found outside the local scope."
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input Env inOriginEnv "The environment where we looked for the cref.";
  input Env inFoundEnv "The environment where we found the cref.";
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inPrefix, inOriginEnv, inFoundEnv)
    local
      list<String> oenv, fenv;
      Prefix prefix;
      DAE.ComponentRef cref;

    // This case tries to figure out the prefix to use when a cref is found in
    // one of the scopes above where it's used, but should still be prefixed
    // with parts of the given prefix. This happens when we have model such as
    // this:
    //
    //   model A
    //     constant Integer j;
    //     package P
    //       constant Integer i = j;
    //     end P;
    //   end A;
    //
    //   model B
    //     A a(j = 2);
    //   end B;
    //
    // In this case we instantiate 'a', which contains a package with constants.
    // We might therefore instantiate 'i' with the prefix 'a.P', resulting in
    // 'a.P.i'.  But 'i' has the binding 'j' that we also want to instantiate,
    // and 'j' is found in the scope above. To get the correct name for 'j',
    // i.e.  'a.j' and not 'A.j', we need to apply only part of the prefix 'a.P'.
    case (_, _, _, _)
      equation
        // Convert both environments to string lists.
        (fenv as _ :: _) = NFEnv.scopeNames(inFoundEnv);
        oenv = NFEnv.scopeNames(inOriginEnv);
        // Reduce the environment by 'subtracting' inFoundEnv from inOriginEnv.
        oenv = reduceEnv(oenv, fenv);
        // Reverse the remaining env so that is has the same order as the prefix.
        oenv = listReverse(oenv);
        // Reduce the prefix by 'subtracting' the remaining scopes from the it.
        prefix = reducePrefix(oenv, inPrefix);
        // Apply the remaining prefix.
        cref = NFInstUtil.prefixCref(inCref, prefix);
      then
        cref;

    // If the previous case failed it means that a suitable prefix could not be
    // found, in which case the cref should be fully qualified instead. In that
    // case we prefix the cref with the environment where it was found.
    else
      equation
        fenv = NFEnv.scopeNames(inFoundEnv);
        cref = ComponentReference.crefPrefixStringList(fenv, inCref);
      then
        cref;

  end matchcontinue;
end prefixGlobalCref;

protected function reduceEnv
  "This function takes two environments represented as string lists, and
   'subtracts' inFoundEnv from inOriginEnv. I.e. if we have inOriginEnv = A.B.C
   and inFoundEnv = A.B, then outRemainingEnv = C. Fails if inFoundEnv is not a
   prefix of inOriginEnv."
  input list<String> inOriginEnv;
  input list<String> inFoundEnv;
  output list<String> outRemainingEnv;
algorithm
  outRemainingEnv := match(inOriginEnv, inFoundEnv)
    local
      String oname, fname;
      list<String> rest_oenv, rest_fenv;

    // Continue if the heads of both strings are the same.
    case (oname :: rest_oenv, fname :: rest_fenv)
      equation
        true = stringEq(oname, fname);
      then
        reduceEnv(rest_oenv, rest_fenv);

    // If we run out of inFoundEnv but still have parts of inOriginEnv left,
    // return the remaining environment.
    case (_ :: _, {}) then inOriginEnv;
  end match;
end reduceEnv;

protected function reducePrefix
  "This function removes the given environment, represented by a string list,
   from the given prefix. I.e. if we have a prefix a.b.P.R and an environment P.R
   we get the result a.b. The environment should be ordered in reverse order,
   top-most scope last, since that's how the prefix is ordered."
  input list<String> inRemainingEnv;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inRemainingEnv, inPrefix)
    local
      String ename, pname;
      list<String> rest_env;
      Prefix rest_prefix;

    // Continue if the heads of the environment and the prefix are the same.
    case (ename :: rest_env,
          NFInstTypes.PREFIX(name = pname, restPrefix = rest_prefix))
      equation
        true = stringEq(ename, pname);
      then
        reducePrefix(rest_env, rest_prefix);

    // If we managed to remove the whole environment from the prefix, return the
    // remaining prefix.
    case ({}, _) then inPrefix;

  end match;
end reducePrefix;

protected function prefixPath
  input Absyn.Path inPath;
  input Prefix inPrefix;
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inPrefix, inEnv)
    local
      Env env;
      Boolean is_global;
      String name_str;
      Absyn.Path path;

    case (Absyn.FULLYQUALIFIED(path = _), _, _) then inPath;

    case (_, _, _)
      equation
        name_str = Absyn.pathFirstIdent(inPath);
        (is_global, _, env) = NFLookup.isNameGlobal(name_str, inEnv);
        path = prefixPath2(inPath, inPrefix, inEnv, env, is_global);
      then
        path;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFInst.prefixPath failed on " +&
          Absyn.pathString(inPath) +& "\n");
      then
        fail();

  end matchcontinue;
end prefixPath;

protected function prefixPath2
  input Absyn.Path inPath;
  input Prefix inPrefix;
  input Env inOriginEnv;
  input Env inFoundEnv;
  input Boolean inIsGlobal;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inPrefix, inOriginEnv, inFoundEnv, inIsGlobal)
    local
      list<String> oenv, fenv;
      Prefix prefix;
      Absyn.Path path;

    // Local path, apply the given prefix.
    case (_, _, _, _, false) then NFInstUtil.prefixPath(inPath, inPrefix);

    // Partially global path, see prefixGlobalCref.
    case (_, _, _, _, true)
      equation
        (fenv as _ :: _) = NFEnv.scopeNames(inFoundEnv);
        oenv = NFEnv.scopeNames(inOriginEnv);
        oenv = reduceEnv(oenv, fenv);
        oenv = listReverse(oenv);
        prefix = reducePrefix(oenv, inPrefix);
        path = NFInstUtil.prefixPath(inPath, prefix);
      then
        path;

    else
      equation
        fenv = NFEnv.scopeNames(inFoundEnv);
        fenv = listReverse(fenv);
        path = List.fold(fenv, Absyn.prefixPath, inPath);
      then
        path;

  end matchcontinue;
end prefixPath2;

protected function instPackageConstant
  input Boolean inIsGlobal;
  input DAE.ComponentRef inCref;
  input Absyn.Path inName;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.ComponentRef outCref;
  output Globals outGlobals;
algorithm
  (outCref, outGlobals) :=
  matchcontinue(inIsGlobal, inCref, inName, inEnv, inInfo, inGlobals)
    local
      Entry entry;
      Env env;
      Absyn.Path name;
      Prefix prefix;
      Globals globals;
      DAE.ComponentRef cref;


    case (false, _, _, _, _, _) then (inCref, inGlobals);

    //case (_, _, Absyn.FULLYQUALIFIED(path = _), _, _, _)
    //  equation
    //    name = Absyn.makeNotFullyQualified(inName);
    //    (item, _, env) = NFLookup.lookupFullyQualified(name, inEnv);
    //    (NFSCodeEnv.VAR(var = selem), env, _) = NFSCodeEnv.resolveRedeclaredItem(item, env);

    //    prefix = NFInstUtil.restPrefix(NFInstUtil.pathPrefix(inName));
    //    (elem, (consts, funcs)) = instElement(selem, NFInstTypes.NOMOD(), NFInstTypes.NOMOD(),
    //      NFInstTypes.NO_PREFIXES(), env, prefix, INST_ALL(), inGlobals);

    //    consts = NFInstSymbolTable.addElement(elem, consts);
    //  then
    //    (inCref, (consts, funcs));

    case (_, _, _, _, _, _)
      equation
        (entry, env) = NFLookup.lookupLocalName(inName, inEnv);

        //print("Instantiating " +& Absyn.pathString(inName) +& "\n");
        //print("Env: " +& NFEnv.printEnvPathStr(inEnv) +& "\n");
        //print("Found env: " +& NFEnv.printEnvPathStr(env) +& "\n");
        //print("Result: " +& Absyn.pathString(name) +& "\n");

        (prefix, name, cref) = makePackageConstantPrefix(inName, inCref, entry, env, inEnv);

        //print("Adding " +& Absyn.pathString(name) +& "\n");
        globals = instPackageConstant2(name, entry, env, prefix, inGlobals);
      then
        (cref, globals);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- instPackageConstant failed on " +& Absyn.pathString(inName));
      then
        fail();

  end matchcontinue;
end instPackageConstant;

protected function makePackageConstantPrefix
  input Absyn.Path inName;
  input DAE.ComponentRef inCref;
  input Entry inEntry;
  input Env inFoundEnv;
  input Env inOriginEnv;
  output Prefix outPrefix;
  output Absyn.Path outName;
  output DAE.ComponentRef outCref;
algorithm
  (outPrefix, outName, outCref) :=
  match(inName, inCref, inEntry, inFoundEnv, inOriginEnv)
    local
      Prefix prefix;
      String name;
      Absyn.Path path;
      DAE.ComponentRef cref;

    case (_, _, NFEnv.ENTRY(element = SCode.COMPONENT(name = name, typeSpec =
        Absyn.TPATH(path = Absyn.QUALIFIED(name = "$EnumType")))), _, _)
      equation
        prefix = NFInstUtil.envPrefix(inFoundEnv);
        path = NFEnv.prefixIdentWithEnv(name, inFoundEnv);
        // The lookup rules forbid looking a class up in a component, so there's
        // no way to have subscripts in the cref for a enumeration literal. So
        // we can safely just convert the path to a cref here.
        cref = ComponentReference.pathToCref(path);
      then
        (prefix, path, cref);

    case (_, _, NFEnv.ENTRY(element = SCode.CLASS(name = name)), _, _)
      equation
        prefix = NFInstUtil.envPrefix(inFoundEnv);
        path = NFEnv.prefixIdentWithEnv(name, inFoundEnv);
        cref = ComponentReference.pathToCref(path);
      then
        (prefix, path, cref);

    else
      equation
        prefix = NFInstUtil.envPrefix(inOriginEnv);
        NFInstTypes.PREFIX(restPrefix = prefix) = NFInstUtil.addPathPrefix(inName, prefix);
      then
        (prefix, inName, inCref);

  end match;
end makePackageConstantPrefix;

protected function instPackageConstant2
  input Absyn.Path inName;
  input Entry inEntry;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output Globals outGlobals;
algorithm
  outGlobals := matchcontinue(inName, inEntry, inEnv, inPrefix, inGlobals)
    local
      SCode.Element selem;
      Element elem;
      SymbolTable consts;
      FunctionHashTable funcs;
      Env env;
      DAE.Type ty;
      Component comp;
      Absyn.Info info;

      Absyn.Path name;
      String cls_name;

    case (_, _, _, _, (consts, _))
      equation
        //print("Looking for " +& Absyn.pathString(inName) +& " in symboltable\n");
        _ = NFInstSymbolTable.lookupName(inName, consts);
        //print(Absyn.pathString(inName) +& " already added\n");
      then
        inGlobals;

    case (_, NFEnv.ENTRY(element = selem as SCode.COMPONENT(typeSpec =
        Absyn.TPATH(path = Absyn.QUALIFIED(name = "$EnumType")))), env, _, _)
      equation
        (elem, (consts, funcs)) = instComponent(selem, NFMod.emptyModTable,
          NFInstTypes.NO_PREFIXES(), env, inPrefix, INST_ALL(), inGlobals);
        consts = NFInstSymbolTable.addElement(elem, consts);
      then
        ((consts, funcs));

    // A normal package constant.
    case (_, NFEnv.ENTRY(element = selem as SCode.COMPONENT(name = _)), env, _, _)
      equation
        (elem, (consts, funcs)) = instComponent(selem, NFMod.emptyModTable,
          NFInstTypes.NO_PREFIXES(), env, inPrefix, INST_ALL(), inGlobals);

        NFInstTypes.ELEMENT(component = comp) = elem;
        name = NFInstUtil.getComponentName(comp);

        consts = NFInstSymbolTable.addElement(elem, consts);
      then
        ((consts, funcs));

    // An enumeration type used as a value.
    case (_, NFEnv.ENTRY(element = SCode.CLASS(name = cls_name, info = info)), _, _, _)
      equation
        // Instantiate the enumeration type to get its type.
        (_, ty, _, (consts, funcs)) = instClassEntry(inName, inEntry,
          NFInstTypes.NOMOD(), NFMod.emptyModTable, NFInstTypes.NO_PREFIXES(),
          inEnv, NFInstTypes.emptyPrefix, INST_ALL(), inGlobals);
        /*********************************************************************/
        // TODO: Check the type, make sure it's an enumeration! Any other types
        // allowed to be used here?
        /*********************************************************************/

        comp = NFInstTypes.TYPED_COMPONENT(inName, ty, NONE(),
          NFInstTypes.NO_DAE_PREFIXES(), NFInstTypes.UNBOUND(), info);
        consts = NFInstSymbolTable.addComponent(comp, consts);
      then
        ((consts, funcs));

  end matchcontinue;
end instPackageConstant2;

protected function instFunctionCall
  input Absyn.ComponentRef inName;
  input list<Absyn.Exp> inPositionalArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output DAE.Exp outCallExp;
  output Globals outGlobals;
algorithm
  (outCallExp, outGlobals) :=
  match(inName, inPositionalArgs, inNamedArgs, inEnv, inPrefix, inInfo, inGlobals)
    local
      Absyn.Path call_path;
      list<DAE.Exp> pos_args, args;
      list<tuple<String, DAE.Exp>> named_args;
      Function func;
      list<Element> inputs;
      Globals globals;

    case (_, _, _, _, _, _, globals)
      equation
        (call_path, func, globals) = instFunction(inName, inEnv, inPrefix, inInfo, globals);
        (pos_args, globals) = instExpList(inPositionalArgs, inEnv, inPrefix, inInfo, globals);
        (named_args, globals) = List.map3Fold(inNamedArgs, instNamedArg, inEnv, inPrefix, inInfo, globals);
        inputs = NFInstUtil.getFunctionInputs(func);
        args = fillFunctionSlots(pos_args, named_args, inputs, call_path, inInfo);
      then
        (DAE.CALL(call_path, args, DAE.callAttrBuiltinOther), globals);

  end match;
end instFunctionCall;

protected function instFunction
  input Absyn.ComponentRef inName;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output Absyn.Path outName;
  output Function outFunction;
  output Globals outGlobals;
algorithm
  (outName, outFunction, outGlobals) := matchcontinue (inName, inEnv, inPrefix, inInfo, inGlobals)
    local
      Absyn.Path path;
      Entry entry;
      Env env;
      Class cls;
      Function func;
      Boolean is_record;
      DAE.Type ty;
      FunctionHashTable functions;
      SymbolTable consts;

    /*
    case (_, _, _, _, globals)
      equation
        path = Absyn.crefToPath(inName);
        outFunction = BaseHashTable.get(path, globals);
      then (path, outFunction, globals);
    */

    case (_, _, _, _, _)
      equation
        path = Absyn.crefToPath(inName);
        (entry, env) = NFLookup.lookupFunctionName(path, inEnv, inInfo);
        path = instFunctionName(path, entry, inEnv, inPrefix);
        (cls, ty, _, (consts, functions)) = instClassEntry(path, entry,
          NFInstTypes.NOMOD(), NFMod.emptyModTable, NFInstTypes.NO_PREFIXES(),
          env, NFInstTypes.functionPrefix, INST_ALL(), inGlobals);
        is_record = Types.isRecord(ty);
        func = instFunction2(path, cls, is_record);
        functions = BaseHashTable.add((path, func), functions);
      then
        (path, func, (consts, functions));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFInst.instFunction failed: " +& Absyn.printComponentRefStr(inName) +&
          " at position: " +& Error.infoStr(inInfo));
        //(_, _, _) = instFunction(inName, inEnv, inPrefix, inInfo, inGlobals);
      then fail();
  end matchcontinue;
end instFunction;

protected function instFunctionName
  input Absyn.Path inPath;
  input Entry inEntry;
  input Env inEnv;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEntry, inEnv, inPrefix)

    // Don't prefix builtin functions.
    case (_, _, _, _)
      equation
        true = NFEnv.entryHasBuiltinOrigin(inEntry);
      then
        inPath;

    else prefixPath(inPath, inPrefix, inEnv);

  end matchcontinue;
end instFunctionName;

protected function instFunction2
  input Absyn.Path inName;
  input Class inFunction;
  input Boolean inIsRecord;
  output Function outFunction;
algorithm
  outFunction := match(inName, inFunction, inIsRecord)
    local
      list<Element> inputs, outputs, locals;
      list<list<Statement>> algorithms;
      list<Statement> stmts;
      list<Statement> initBindings;
      DAE.Type recRetType;
      list<DAE.Var> vars;

    // Records, treat them the same as globals and add bindings as algorithm
    // statements.
    case (_, NFInstTypes.COMPLEX_CLASS(components = locals,
        algorithms = algorithms), true)
      equation
        initBindings = {};
        (locals, initBindings) = List.mapFold(locals, dimensionDeps, initBindings);
        (initBindings, {}) = Graph.topologicalSort(
          Graph.buildGraph(initBindings, getStatementDependencies,
            (initBindings, List.map(initBindings, getInitStatementName))),
          statementLhsEqual);
        algorithms = initBindings :: algorithms;
        stmts = List.flatten(algorithms);

        // make DAE vars for the return type. Includes all components in the record.
        // No need to type and expand an NFInstTypes.ELEMENT. We know what we want.
        vars = List.accumulateMapReverse(locals, NFInstUtil.makeDaeVarsFromElement);
        recRetType = DAE.T_COMPLEX(ClassInf.RECORD(inName), vars, NONE(), DAE.emptyTypeSource);

        // extract all modifiable components in to 'inputs' the rest go in 'locals'
        (inputs, locals) = List.extractOnTrue(locals, NFInstUtil.isModifiableElement);
        // strip all other prefixes and mark as inputs
        inputs = List.map(inputs, NFInstUtil.markElementAsInput);
        // strip all other prefixes and mark as protected.
        locals = List.map(locals, NFInstUtil.markElementAsProtected);
      then
        NFInstTypes.RECORD_CONSTRUCTOR(inName, recRetType, inputs, locals, stmts);

    // Normal globals.
    case (_, NFInstTypes.COMPLEX_CLASS(algorithms = algorithms), false)
      equation
        (inputs, outputs, locals) = getFunctionParameters(inFunction);
        initBindings = {};
        (outputs, initBindings) = List.mapFold(outputs, stripInitBinding, initBindings);
        (locals, initBindings) = List.mapFold(locals, stripInitBinding, initBindings);
        (outputs, initBindings) = List.mapFold(outputs, dimensionDeps, initBindings);
        (locals, initBindings) = List.mapFold(locals, dimensionDeps, initBindings);
        (initBindings, {}) = Graph.topologicalSort(
          Graph.buildGraph(initBindings, getStatementDependencies,
            (initBindings, List.map(initBindings, getInitStatementName))),
          statementLhsEqual);
        algorithms = initBindings :: algorithms;
        stmts = List.flatten(algorithms);
      then
        NFInstTypes.FUNCTION(inName, inputs, outputs, locals, stmts);

  end match;
end instFunction2;

protected function statementLhsEqual
  input Statement left;
  input Statement right;
  output Boolean b;
algorithm
  b := stringEq(getInitStatementName(left),getInitStatementName(right));
end statementLhsEqual;

protected function getInitStatementName
  "x := ... => x. Fails for qualified assignments"
  input Statement stmt;
  output String name;
algorithm
  name := match stmt
    case NFInstTypes.ASSIGN_STMT(lhs=DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name))) then name;
    case NFInstTypes.FUNCTION_ARRAY_INIT(name=name) then name;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"NFInst.getInitStatementName failed"});
      then fail();
  end match;
end getInitStatementName;

protected function getStatementDependencies
  "Returns the dependencies given an element.
  Assumes reduction/loop indexes/etc have been replaced by unique indices."
  input Statement inStmt;
  input tuple<list<Statement>,list<String>> inAllElements;
  output list<Statement> outDependencies;
algorithm
  outDependencies := match (inStmt, inAllElements)
    local
      DAE.Exp exp;
      list<String> deps,allPossible;
      list<Statement> allStatements;
      Absyn.Info info;
      String name;
      list<DAE.Dimension> dims;
      list<DAE.Exp> exps;

    case (NFInstTypes.ASSIGN_STMT(lhs=DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name)),rhs=exp,info=info), (allStatements,allPossible))
      equation
        ((_, deps)) = Expression.traverseExp(exp,getExpDependencies,{});
        Error.assertionOrAddSourceMessage(not listMember(name,deps),Error.INTERNAL_ERROR,{"getStatementDependencies: self-dependence in deps"},info);
        deps = List.intersectionOnTrue(allPossible,deps,stringEq);
      then // O(n^2), but function init-bindings are usually too small to warrant a hashtable
        List.select2(allStatements,selectStatement,deps,SOME(name));
    case (NFInstTypes.FUNCTION_ARRAY_INIT(name,DAE.T_ARRAY(dims=dims),info), (allStatements,allPossible))
      equation
        exps = Expression.dimensionsToExps(dims,{});
        ((_, deps)) = Expression.traverseExp(DAE.LIST(exps),getExpDependencies,{});
        Error.assertionOrAddSourceMessage(not listMember(name,deps),Error.INTERNAL_ERROR,{"getStatementDependencies: self-dependence in deps"},info);
        deps = List.intersectionOnTrue(allPossible,deps,stringEq);
      then // O(n^2), but function init-bindings are usually too small to warrant a hashtable
        List.select2(allStatements,selectStatement,deps,NONE());
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"NFInst.getStatementDependencies failed"});
      then fail();
  end match;
end getStatementDependencies;

protected function selectStatement
  input Statement stmt;
  input list<String> deps;
  input Option<String> oname "If this is SOME(name), return true only if the statement is an array allocation.";
  output Boolean select;
protected
  String name;
algorithm
  name := getInitStatementName(stmt);
  select := listMember(name,deps) or (NFInstUtil.isArrayAllocation(stmt) and stringEq(name,Util.getOptionOrDefault(oname,"")));
end selectStatement;

protected function getExpDependencies
  input tuple<DAE.Exp,list<String>> inTpl;
  output tuple<DAE.Exp,list<String>> outTpl;
algorithm
  outTpl := match inTpl
    local
      list<String> lst;
      String name;
      DAE.Exp exp;
    case ((exp as DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name)),lst)) then ((exp,name::lst));
    case ((exp as DAE.CREF(componentRef=DAE.CREF_QUAL(ident=name)),lst)) then ((exp,name::lst));
    else inTpl;
  end match;
end getExpDependencies;

protected function stripInitBinding
  input Element inElt;
  input list<Statement> inBindings;
  output Element outElt;
  output list<Statement> outBindings;
algorithm
  (outElt,outBindings) := match (inElt,inBindings)
    local
      Absyn.Info info,bindingInfo;
      String name;
      Class cls;
      DAE.Type baseType;
      array<Dimension> dimensions;
      Prefixes prefixes;
      ParamType paramType;
      DAE.Exp bindingExp;
      Component comp;
      Element elt;

    case (NFInstTypes.ELEMENT(NFInstTypes.UNTYPED_COMPONENT(Absyn.IDENT(name),baseType,dimensions,prefixes,paramType,NFInstTypes.UNTYPED_BINDING(bindingExp=bindingExp,info=bindingInfo),info),cls),_)
      equation
        comp = NFInstTypes.UNTYPED_COMPONENT(Absyn.IDENT(name),baseType,dimensions,prefixes,paramType,NFInstTypes.UNBOUND(),info);
        elt = NFInstTypes.ELEMENT(comp,cls);
      then (elt,NFInstTypes.ASSIGN_STMT(DAE.CREF(DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {}),DAE.T_UNKNOWN_DEFAULT),bindingExp,bindingInfo)::inBindings);
    else (inElt,inBindings);
  end match;
end stripInitBinding;

protected function dimensionDeps
  input Element inElt;
  input list<Statement> inBindings;
  output Element outElt;
  output list<Statement> outBindings;
algorithm
  (outElt,outBindings) := match (inElt,inBindings)
    local
      Absyn.Info info;
      String name;
      Class cls;
      array<Dimension> dimensions;
      list<DAE.Dimension> dims;
      Element elt;
      list<Statement> bindings;

    case (elt as NFInstTypes.ELEMENT(NFInstTypes.UNTYPED_COMPONENT(name=Absyn.IDENT(name),dimensions=dimensions,info=info),cls),_)
      equation
        dims = List.map(arrayList(dimensions),NFInstUtil.unwrapDimension);
        bindings = Util.if_(arrayLength(dimensions)>0,
          NFInstTypes.FUNCTION_ARRAY_INIT(name, DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,dims,DAE.emptyTypeSource), info)::inBindings,
          inBindings);
      then (elt,bindings);
    else (inElt,inBindings);
  end match;
end dimensionDeps;

protected function instNamedArg
  input Absyn.NamedArg inNamedArg;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output tuple<String, DAE.Exp> outNamedArg;
  output Globals outGlobals;
protected
  String name;
  Absyn.Exp aexp;
  DAE.Exp dexp;
algorithm
  Absyn.NAMEDARG(argName = name, argValue = aexp) := inNamedArg;
  (dexp,outGlobals) := instExp(aexp, inEnv, inPrefix, inInfo, inGlobals);
  outNamedArg := (name, dexp);
end instNamedArg;

protected function getFunctionParameters
  input Class inClass;
  output list<Element> outInputs;
  output list<Element> outOutputs;
  output list<Element> outLocals;
algorithm
  (outInputs, outOutputs, outLocals) := matchcontinue(inClass)
    local
      list<Element> comps, inputs, outputs, locals;
      Absyn.Path name;

    case NFInstTypes.COMPLEX_CLASS(components = comps)
      equation
        (inputs, outputs, locals) = getFunctionParameters2(comps, {}, {}, {});
      then
        (inputs, outputs, locals);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        name = NFInstUtil.getClassName(inClass);
        Debug.traceln("- NFInst.getFunctionParameters failed for: " +& Absyn.pathString(name) +& ".\n" +&
        NFInstDump.modelStr(Absyn.pathString(name), inClass) +& "\n");
      then
        fail();

  end matchcontinue;
end getFunctionParameters;

protected function getFunctionParameters2
  input list<Element> inElements;
  input list<Element> inAccumInputs;
  input list<Element> inAccumOutputs;
  input list<Element> inAccumLocals;
  output list<Element> outInputs;
  output list<Element> outOutputs;
  output list<Element> outLocals;
algorithm
  (outInputs, outOutputs, outLocals) := match(inElements, inAccumInputs, inAccumOutputs, inAccumLocals)
    local
      Prefixes prefs;
      Absyn.Path name;
      DAE.Type ty;
      Absyn.Info info;
      Element el;
      list<Element> rest_el;
      list<Element> inputs, outputs, locals;

    case ((el as NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(
        name = name, baseType = ty, prefixes = prefs, info = info))) :: rest_el,
        inputs, outputs, locals)
      equation
        validateFunctionVariable(name, ty, prefs, info);
        (inputs, outputs, locals) =
          getFunctionParameters3(name, prefs, info, el, inputs, outputs, locals);
        (inputs, outputs, locals) = getFunctionParameters2(rest_el, inputs, outputs, locals);
      then
        (inputs, outputs, locals);

    // Ignore any elements which are not untyped components.
    case (_ :: rest_el, inputs, outputs, locals)
      equation
        (inputs, outputs, locals) = getFunctionParameters2(rest_el, inputs, outputs, locals);
      then
        (inputs, outputs, locals);

    case ({}, _, _, _)
      then (listReverse(inAccumInputs), listReverse(inAccumOutputs), listReverse(inAccumLocals));

  end match;
end getFunctionParameters2;

protected function getFunctionParameters3
  input Absyn.Path inName;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
  input Element inElement;
  input list<Element> inAccumInputs;
  input list<Element> inAccumOutputs;
  input list<Element> inAccumLocals;
  output list<Element> outInputs;
  output list<Element> outOutputs;
  output list<Element> outLocals;
algorithm
  (outInputs, outOutputs, outLocals) := match(inName, inPrefixes, inInfo, inElement,
      inAccumInputs, inAccumOutputs, inAccumLocals)

    case (_, NFInstTypes.PREFIXES(direction = (Absyn.INPUT(), _)), _, _, _, _, _)
      equation
        validateFormalParameter(inName, inPrefixes, inInfo);
      then
        (inElement :: inAccumInputs, inAccumOutputs, inAccumLocals);

    case (_, NFInstTypes.PREFIXES(direction = (Absyn.OUTPUT(), _)), _, _, _, _, _)
      equation
        validateFormalParameter(inName, inPrefixes, inInfo);
      then
        (inAccumInputs, inElement :: inAccumOutputs, inAccumLocals);

    else
      equation
        validateLocalFunctionVariable(inName, inPrefixes, inInfo);
      then
        (inAccumInputs, inAccumOutputs, inElement :: inAccumLocals);

  end match;
end getFunctionParameters3;

protected function validateFunctionVariable
  input Absyn.Path inName;
  input DAE.Type inType;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inName, inType, inPrefixes, inInfo)
    local
      String name, ty_str, io_str;
      Absyn.InnerOuter io;

    case (_, _, NFInstTypes.PREFIXES(innerOuter = Absyn.NOT_INNER_OUTER()), _)
      equation
        true = Types.isValidFunctionVarType(inType);
      then ();

    case (_, _, _, _)
      equation
        false = Types.isValidFunctionVarType(inType);
        name = Absyn.pathString(inName);
        ty_str = Types.getTypeName(inType);
        Error.addSourceMessage(Error.INVALID_FUNCTION_VAR_TYPE,
          {ty_str, name}, inInfo);
      then
        fail();

    // A formal parameter may not have an inner/outer prefix.
    case (_, _, NFInstTypes.PREFIXES(innerOuter = io), _)
      equation
        false = Absyn.isNotInnerOuter(io);
        name = Absyn.pathString(inName);
        io_str = Dump.unparseInnerouterStr(io);
        Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
          {io_str, name}, inInfo);
      then
        fail();

  end matchcontinue;
end validateFunctionVariable;

protected function validateFormalParameter
  input Absyn.Path inName;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inName, inPrefixes, inInfo)
    local
      String name;

    // A formal parameter must be public.
    case (_, NFInstTypes.PREFIXES(visibility = SCode.PROTECTED()), _)
      equation
        name = Absyn.pathString(inName);
        Error.addSourceMessage(Error.PROTECTED_FORMAL_FUNCTION_VAR,
          {name}, inInfo);
      then
        fail();

    else ();

  end matchcontinue;
end validateFormalParameter;

protected function validateLocalFunctionVariable
  input Absyn.Path inName;
  input Prefixes inPrefixes;
  input Absyn.Info inInfo;
algorithm
  _ := match(inName, inPrefixes, inInfo)
    local
      String name;

    // A local function variable must be protected.
    case (_, NFInstTypes.PREFIXES(visibility = SCode.PUBLIC()), _)
      equation
        name = Absyn.pathString(inName);
        Error.addSourceMessage(Error.NON_FORMAL_PUBLIC_FUNCTION_VAR, {name}, inInfo);
      then
        fail();

    else ();

  end match;
end validateLocalFunctionVariable;

protected function fillFunctionSlots
  input list<DAE.Exp> inPositionalArgs;
  input list<tuple<String, DAE.Exp>> inNamedArgs;
  input list<Element> inInputs;
  input Absyn.Path inFuncName;
  input Absyn.Info inInfo;
  output list<DAE.Exp> outArgs;
protected
  list<FunctionSlot> slots;
algorithm
  //print(Error.infoStr(inInfo) +& " Function: " +& Absyn.pathString(inFuncName) +& ":\n");
  //print(Util.stringDelimitListNonEmptyElts(List.map(inInputs, NFInstUtil.printElement), "\n\t") +& "\n");
  slots := makeFunctionSlots(inInputs, inPositionalArgs, {}, inFuncName, inInfo);
  slots := List.fold(inNamedArgs, fillFunctionSlot, slots);
  outArgs := List.map(slots, extractFunctionSlotExp);
end fillFunctionSlots;

protected function makeFunctionSlots
  input list<Element> inInputs;
  input list<DAE.Exp> inPositionalArgs;
  input list<FunctionSlot> inAccumSlots;
  input Absyn.Path inFuncName;
  input Absyn.Info inInfo;
  output list<FunctionSlot> outSlots;
algorithm
  outSlots := match(inInputs, inPositionalArgs, inAccumSlots, inFuncName, inInfo)
    local
      String param_name, name;
      Binding binding;
      list<Element> rest_inputs;
      Option<DAE.Exp> arg, default_value;
      list<DAE.Exp> rest_args;
      list<FunctionSlot> slots;

    // ignore cond components
    case (NFInstTypes.CONDITIONAL_ELEMENT(component = _) :: rest_inputs, _, slots, _, _)
      then
        makeFunctionSlots(rest_inputs, inPositionalArgs, slots, inFuncName, inInfo);

    // Last vararg input and no positional arguments means we're done.
    case ({NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(prefixes =
        NFInstTypes.PREFIXES(varArgs = NFInstTypes.IS_VARARG())))}, {}, _, _, _)
      then listReverse(inAccumSlots);

    // If the last input of the function is a vararg, handle it first
    case (rest_inputs as (NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(name =
        Absyn.IDENT(param_name), binding = binding, prefixes = NFInstTypes.PREFIXES(varArgs =
        NFInstTypes.IS_VARARG()))) :: {}),  _::_, slots, _, _)
      equation
        (arg, rest_args) = List.splitFirstOption(inPositionalArgs);
        default_value = NFInstUtil.getBindingExpOpt(binding);
        slots = NFInstTypes.SLOT(param_name, arg, default_value) :: slots;
      then
        makeFunctionSlots(rest_inputs, rest_args, slots, inFuncName, inInfo);

    case (NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(name =
        Absyn.IDENT(param_name), binding = binding)) :: rest_inputs, _, slots, _, _)
      equation
        (arg, rest_args) = List.splitFirstOption(inPositionalArgs);
        default_value = NFInstUtil.getBindingExpOpt(binding);
        slots = NFInstTypes.SLOT(param_name, arg, default_value) :: slots;
      then
        makeFunctionSlots(rest_inputs, rest_args, slots, inFuncName, inInfo);

    // No more inputs and positional arguments means we're done.
    case ({}, {}, _, _, _) then listReverse(inAccumSlots);

    // No more inputs but positional arguments left is an error.
    case ({}, _ :: _, _, _, _)
      equation
        // TODO: Make this a proper error message.
        print(Error.infoStr(inInfo) +& ": ");
        name = Absyn.pathString(inFuncName);
        print("NFInst.makeFunctionSlots: Too many arguments to function " +&
          name +& "\n");
      then
        fail();

  end match;
end makeFunctionSlots;

protected function fillFunctionSlot
  input tuple<String, DAE.Exp> inNamedArg;
  input list<FunctionSlot> inSlots;
  output list<FunctionSlot> outSlots;
algorithm
  outSlots := match(inNamedArg, inSlots)
    local
      String arg_name, slot_name;
      FunctionSlot slot;
      list<FunctionSlot> rest_slots;
      Boolean eq;

      case ((arg_name, _), (slot as NFInstTypes.SLOT(name = slot_name)) :: rest_slots)
        equation
          eq = stringEq(arg_name, slot_name);
        then
          fillFunctionSlot2(eq, inNamedArg, slot, rest_slots);

      case ((arg_name, _), {})
        equation
          print("No matching slot " +& arg_name +& "\n");
        then
          fail();

  end match;
end fillFunctionSlot;

protected function fillFunctionSlot2
  input Boolean inMatching;
  input tuple<String, DAE.Exp> inNamedArg;
  input FunctionSlot inSlot;
  input list<FunctionSlot> inRestSlots;
  output list<FunctionSlot> outSlots;
algorithm
  outSlots := match(inMatching, inNamedArg, inSlot, inRestSlots)
    local
      String name;
      DAE.Exp arg;
      FunctionSlot slot;
      list<FunctionSlot> slots;

    // Found a matching empty slot, fill it.
    case (true, (_, arg), NFInstTypes.SLOT(name = name, arg = NONE()), _)
      equation
        slot = NFInstTypes.SLOT(name, SOME(arg), NONE());
      then
        slot :: inRestSlots;

    // Slot not matching, search through the rest of the slots.
    case (false, _, _, _)
      equation
        slots = fillFunctionSlot(inNamedArg, inRestSlots);
      then
        inSlot :: slots;

    // Found a matching slot that is already filled, show error.
    case (true, _, NFInstTypes.SLOT(name = name, arg = SOME(arg)), _)
      equation
        print("Slot " +& name +& " is already filled with: " +& ExpressionDump.printExpStr(arg) +& "\n");
      then
        fail();

  end match;
end fillFunctionSlot2;

protected function extractFunctionSlotExp
  input FunctionSlot inSlot;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSlot)
    local
      DAE.Exp exp;
      String name;

    case NFInstTypes.SLOT(arg = SOME(exp)) then exp;
    case NFInstTypes.SLOT(defaultValue = SOME(exp)) then exp;
    case NFInstTypes.SLOT(name = name)
      equation
        print("Slot " +& name +& " has no value.\n");
      then
        fail();

  end match;
end extractFunctionSlotExp;

protected function assignParamTypes
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) :=
    NFInstUtil.traverseClassComponents(inClass, inSymbolTable, assignParamTypesToComp);
end assignParamTypes;

protected function assignParamTypesToComp
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := match(inComponent, inSymbolTable)
    local
      array<Dimension> dims;
      DAE.Exp cond;
      SymbolTable st;

    case (NFInstTypes.UNTYPED_COMPONENT(dimensions = dims), st)
      equation
        st = Util.arrayFold(dims, assignParamTypesToDim, st);
      then
        (inComponent, st);

    case (NFInstTypes.CONDITIONAL_COMPONENT(condition = cond), st)
      equation
        st = markExpAsStructural(cond, st);
      then
        (inComponent, st);

    else (inComponent, inSymbolTable);

  end match;
end assignParamTypesToComp;

protected function assignParamTypesToDim
  input Dimension inDimension;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inDimension, inSymbolTable)
    local
      DAE.Exp dim_exp;
      SymbolTable st;

    case (NFInstTypes.UNTYPED_DIMENSION(dimension = DAE.DIM_EXP(exp = dim_exp)), st)
      equation
        ((_, st)) = Expression.traverseExpTopDown(dim_exp,
          markDimExpAsStructuralTraverser, st);
      then
        st;

    else inSymbolTable;

  end match;
end assignParamTypesToDim;

protected function markDimExpAsStructuralTraverser
  input tuple<DAE.Exp, SymbolTable> inTuple;
  output tuple<DAE.Exp, Boolean, SymbolTable> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.Exp exp, index_exp;
      SymbolTable st;
      DAE.ComponentRef cref;

    case (((exp as DAE.CREF(componentRef = cref)), st))
      equation
        st = markParamAsStructural(cref, st);
        // TODO: Mark cref subscripts too.
      then
        ((exp, true, st));

    case (((exp as DAE.SIZE(sz = SOME(index_exp))), st))
      equation
        st = markExpAsStructural(index_exp, st);
      then
        ((exp, false, st));

    case ((exp, st)) then ((exp, true, st));

  end match;
end markDimExpAsStructuralTraverser;

protected function markExpAsStructural
  input DAE.Exp inExp;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  ((_, outSymbolTable)) := Expression.traverseExp(inExp,
    markExpAsStructuralTraverser, inSymbolTable);
end markExpAsStructural;

protected function markExpAsStructuralTraverser
  input tuple<DAE.Exp, SymbolTable> inTuple;
  output tuple<DAE.Exp, SymbolTable> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.ComponentRef cref;
      DAE.Exp exp;
      SymbolTable st;

    case (((exp as DAE.CREF(componentRef = cref)), st))
      equation
        st = markParamAsStructural(cref, st);
      then
        ((exp, st));

    else inTuple;

  end match;
end markExpAsStructuralTraverser;

protected function markParamAsStructural
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inCref, inSymbolTable)
    local
      SymbolTable st;
      Component comp;

    case (_, st)
      equation
        (comp, st) = NFInstSymbolTable.lookupCrefResolveOuter(inCref, st);
        st = markComponentAsStructural(comp, st);
      then
        st;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFInst.markParamAsStructural failed on " +&
          ComponentReference.printComponentRefStr(inCref) +& "\n");
      then
        fail();

  end matchcontinue;
end markParamAsStructural;

protected function markComponentAsStructural
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inComponent, inSymbolTable)
    local
      Absyn.Path name;
      DAE.Type ty;
      array<Dimension> dims;
      Prefixes prefs;
      Binding binding;
      Absyn.Info info;
      SymbolTable st;
      Component comp;

    // Already marked as structural.
    case (NFInstTypes.UNTYPED_COMPONENT(paramType = NFInstTypes.STRUCT_PARAM()), _)
      then inSymbolTable;

    case (NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs, _, binding, info), st)
      equation
        st = markBindingAsStructural(binding, st);
        comp = NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs,
          NFInstTypes.STRUCT_PARAM(), binding, info);
        st = NFInstSymbolTable.updateComponent(comp, st);
      then
        st;

    case (NFInstTypes.OUTER_COMPONENT(name = _), _)
      equation
        print("NFInst.markComponentAsStructural: IMPLEMENT ME!\n");
      then
        fail();

    case (NFInstTypes.CONDITIONAL_COMPONENT(name = _), _)
      equation
        print("NFInst.markComponentAsStructural: conditional component used as structural parameter!\n");
      then
        fail();

    else inSymbolTable;
  end match;
end markComponentAsStructural;

protected function markBindingAsStructural
  input Binding inBinding;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := match(inBinding, inSymbolTable)
    local
      DAE.Exp bind_exp;

    case (NFInstTypes.UNTYPED_BINDING(bindingExp = bind_exp), _)
      then markExpAsStructural(bind_exp, inSymbolTable);

    else inSymbolTable;

  end match;
end markBindingAsStructural;

protected function instSections
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  input Prefix inPrefix;
  input InstPolicy inInstPolicy;
  input Globals inGlobals;
  output list<Equation> outEquations;
  output list<Equation> outInitialEquations;
  output list<list<Statement>> outStatements;
  output list<list<Statement>> outInitialStatements;
  output Globals outGlobals;
algorithm
  (outEquations, outInitialEquations, outStatements, outInitialStatements, outGlobals) :=
  match(inClassDef, inEnv, inPrefix, inInstPolicy, inGlobals)
    local
      list<SCode.Equation> snel, siel;
      list<SCode.AlgorithmSection> snal, sial;
      list<Equation> inel, iiel;
      list<list<Statement>> inal, iial;
      Globals globals;

    case (SCode.PARTS(normalEquationLst = snel, initialEquationLst = siel, normalAlgorithmLst = snal, initialAlgorithmLst = sial), _,
        _, INST_ALL(), globals)
      equation
        (inel, globals) = instEquations(snel, inEnv, inPrefix, globals);
        (iiel, globals) = instEquations(siel, inEnv, inPrefix, globals);
        (inal, globals) = instAlgorithmSections(snal, inEnv, inPrefix, globals);
        (iial, globals) = instAlgorithmSections(sial, inEnv, inPrefix, globals);
      then
        (inel, iiel, inal, iial, globals);

    case (_, _, _, INST_ONLY_CONST(), _) then ({}, {}, {}, {}, inGlobals);

  end match;
end instSections;

protected function instEquations
  input list<SCode.Equation> inEquations;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output list<Equation> outEquations;
  output Globals outGlobals;
algorithm
  (outEquations,outGlobals) := List.map2Fold(inEquations, instEquation, inEnv, inPrefix, inGlobals);
end instEquations;

protected function instEquation
  input SCode.Equation inEquation;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output Equation outEquation;
  output Globals outGlobals;
protected
  SCode.EEquation eq;
algorithm
  SCode.EQUATION(eEquation = eq) := inEquation;
  (outEquation,outGlobals) := instEEquation(eq, inEnv, inPrefix, inGlobals);
end instEquation;

protected function instEEquations
  input list<SCode.EEquation> inEquations;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output list<Equation> outEquations;
  output Globals outGlobals;
algorithm
  (outEquations,outGlobals) := List.map2Fold(inEquations, instEEquation, inEnv, inPrefix, inGlobals);
end instEEquations;

protected function instEEquation
  input SCode.EEquation inEquation;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output Equation outEquation;
  output Globals outGlobals;
algorithm
  (outEquation,outGlobals) := matchcontinue (inEquation, inEnv, inPrefix, inGlobals)
    local
      Absyn.Exp exp1, exp2, exp3;
      DAE.Exp dexp1, dexp2, dexp3;
      Absyn.ComponentRef cref1, cref2;
      DAE.ComponentRef dcref1, dcref2;
      Absyn.Info info;
      Integer index;
      String for_index,str;
      list<SCode.EEquation> eql;
      list<Equation> ieql;
      list<Absyn.Exp> if_condition;
      list<list<SCode.EEquation>> if_branches;
      list<tuple<DAE.Exp, list<Equation>>> inst_branches;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> when_branches;
      Env env;
      Globals globals;

    case (SCode.EQ_EQUALS(exp1, exp2, _, info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
        (dexp2, globals) = instExp(exp2, inEnv, inPrefix, info, globals);
      then
        (NFInstTypes.EQUALITY_EQUATION(dexp1, dexp2, info), globals);

    // To determine whether a connected component is inside or outside we need
    // to know the type of the first identifier in the cref. Since it's illegal
    // to connect to global constants we can just save the prefix until we do
    // the typing, which means that we can then determine this with a hashtable
    // lookup.
    case (SCode.EQ_CONNECT(crefLeft = cref1, crefRight = cref2, info = info), _, _, globals)
      equation
        (dcref1, globals) = instCref2(cref1, inEnv, inPrefix, info, globals);
        (dcref2, globals) = instCref2(cref2, inEnv, inPrefix, info, globals);
      then
        (NFInstTypes.CONNECT_EQUATION(dcref1, NFConnect2.NO_FACE(), DAE.T_UNKNOWN_DEFAULT,
          dcref2, NFConnect2.NO_FACE(), DAE.T_UNKNOWN_DEFAULT, inPrefix, info), globals);

    case (SCode.EQ_FOR(index = for_index, range = SOME(exp1), eEquationLst = eql,
        info = info), _, _, globals)
      equation
        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
        (dexp1, globals) = instExp(exp1, env, inPrefix, info, globals);
        (ieql, globals) = instEEquations(eql, env, inPrefix, globals);
      then
        (NFInstTypes.FOR_EQUATION(for_index, index, DAE.T_UNKNOWN_DEFAULT, SOME(dexp1), ieql, info), globals);

    case (SCode.EQ_FOR(index = for_index, range = NONE(), eEquationLst = eql,
        info = info), _, _, globals)
      equation
        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
        (ieql, globals) = instEEquations(eql, env, inPrefix, globals);
      then
        (NFInstTypes.FOR_EQUATION(for_index, index, DAE.T_UNKNOWN_DEFAULT, NONE(), ieql, info), globals);

    case (SCode.EQ_IF(condition = if_condition, thenBranch = if_branches,
        elseBranch = eql, info = info), _, _, globals)
      equation
        (inst_branches, globals) = List.threadMap3ReverseFold(if_condition, if_branches, instIfBranch, inEnv, inPrefix, info, globals);
        (ieql, globals) = instEEquations(eql, inEnv, inPrefix, globals);
        // Add else branch as a branch with condition true last in the list.
        inst_branches = listReverse((DAE.BCONST(true), ieql) :: inst_branches);
      then
        (NFInstTypes.IF_EQUATION(inst_branches, info), globals);

    case (SCode.EQ_WHEN(condition = exp1, eEquationLst = eql,
        elseBranches = when_branches, info = info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
        (ieql, globals) = instEEquations(eql, inEnv, inPrefix, globals);
        (inst_branches, globals) = List.map3Fold(when_branches, instWhenBranch, inEnv, inPrefix, info, globals);
        // Add else branch as a branch with condition true last in the list.
        inst_branches = listReverse((DAE.BCONST(true), ieql) :: inst_branches);
      then
        (NFInstTypes.WHEN_EQUATION(inst_branches, info), globals);

    case (SCode.EQ_ASSERT(condition = exp1, message = exp2, level = exp3, info = info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
        (dexp2, globals) = instExp(exp2, inEnv, inPrefix, info, globals);
        (dexp3, globals) = instExp(exp3, inEnv, inPrefix, info, globals);
      then
        (NFInstTypes.ASSERT_EQUATION(dexp1, dexp2, dexp3, info), globals);

    case (SCode.EQ_TERMINATE(message = exp1, info = info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
      then
        (NFInstTypes.TERMINATE_EQUATION(dexp1, info), globals);

    case (SCode.EQ_REINIT(cref = cref1, expReinit = exp1, info = info), _, _, globals)
      equation
        (dcref1, globals) = instCref(cref1, inEnv, inPrefix, info, globals);
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
      then
        (NFInstTypes.REINIT_EQUATION(dcref1, dexp1, info), globals);

    case (SCode.EQ_NORETCALL(exp = exp1, info = info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
      then
        (NFInstTypes.NORETCALL_EQUATION(dexp1, info), globals);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = SCodeDump.equationStr(inEquation);
        Debug.traceln("Unknown or failed equation in NFInst.instEEquation: " +& str);
      then
        fail();

  end matchcontinue;
end instEEquation;

protected function instAlgorithmSections
  input list<SCode.AlgorithmSection> inSections;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output list<list<Statement>> outStatements;
  output Globals outGlobals;
algorithm
  (outStatements,outGlobals) := List.map2Fold(inSections, instAlgorithmSection, inEnv, inPrefix, inGlobals);
end instAlgorithmSections;

protected function instAlgorithmSection
  input SCode.AlgorithmSection inSection;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output list<Statement> outStatements;
  output Globals outGlobals;
protected
  list<SCode.Statement> sstatements;
algorithm
  SCode.ALGORITHM(statements=sstatements) := inSection;
  (outStatements,outGlobals) := List.map2Fold(sstatements, instStatement, inEnv, inPrefix, inGlobals);
end instAlgorithmSection;

protected function instStatements
  input list<SCode.Statement> sstatements;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output list<Statement> outStatements;
  output Globals outGlobals;
algorithm
  (outStatements,outGlobals) := List.map2Fold(sstatements, instStatement, inEnv, inPrefix, inGlobals);
end instStatements;

protected function instStatement
  input SCode.Statement statement;
  input Env inEnv;
  input Prefix inPrefix;
  input Globals inGlobals;
  output Statement outStatement;
  output Globals outGlobals;
algorithm
  (outStatement,outGlobals) := match (statement,inEnv,inPrefix,inGlobals)
    local
      Absyn.Exp exp1, exp2, if_condition;
      Absyn.Info info;
      DAE.Exp dexp1, dexp2;
      Env env;
      list<SCode.Statement> if_branch,else_branch,body;
      list<tuple<Absyn.Exp,list<SCode.Statement>>> elseif_branches,branches;
      list<tuple<DAE.Exp,list<Statement>>> inst_branches;
      list<Statement> ibody;
      String for_index;
      Integer index;
      Globals globals;

    case (SCode.ALG_ASSIGN(exp1, exp2, _, info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
        (dexp2, globals) = instExp(exp2, inEnv, inPrefix, info, globals);
      then (NFInstTypes.ASSIGN_STMT(dexp1, dexp2, info), globals);

    case (SCode.ALG_FOR(index = for_index, range = SOME(exp1), forBody = body, info = info), _, _, globals)
      equation
        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
        (dexp1, globals) = instExp(exp1, env, inPrefix, info, globals);
        (ibody, globals) = instStatements(body, env, inPrefix, globals);
      then
        (NFInstTypes.FOR_STMT(for_index, index, DAE.T_UNKNOWN_DEFAULT, SOME(dexp1), ibody, info), globals);

    case (SCode.ALG_FOR(index = for_index, range = NONE(), forBody = body, info = info), _, _, globals)
      equation
        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
        (ibody, globals) = instStatements(body, env, inPrefix, globals);
      then
        (NFInstTypes.FOR_STMT(for_index, index, DAE.T_UNKNOWN_DEFAULT, NONE(), ibody, info), globals);

    case (SCode.ALG_WHILE(boolExpr = exp1, whileBody = body, info = info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
        (ibody, globals) = instStatements(body, inEnv, inPrefix, globals);
      then
        (NFInstTypes.WHILE_STMT(dexp1, ibody, info), globals);

    case (SCode.ALG_IF(boolExpr = if_condition, trueBranch = if_branch,
        elseIfBranch = elseif_branches,
        elseBranch = else_branch, info = info), _, _, globals)
      equation
        elseif_branches = (if_condition,if_branch)::elseif_branches;
        /* Save some memory by making this more complicated than it is */
        (inst_branches, globals) = List.map3Fold_tail(elseif_branches,instStatementBranch,inEnv,inPrefix,info, globals,{});
        (inst_branches, globals) = List.map3Fold_tail({(Absyn.BOOL(true),else_branch)},instStatementBranch,inEnv,inPrefix,info, globals,inst_branches);
        inst_branches = listReverse(inst_branches);
      then
        (NFInstTypes.IF_STMT(inst_branches, info), globals);

    case (SCode.ALG_WHEN_A(branches = branches, info = info), _, _, globals)
      equation
        (inst_branches, globals) = List.map3Fold(branches,instStatementBranch,inEnv,inPrefix,info, globals);
      then
        (NFInstTypes.WHEN_STMT(inst_branches, info), globals);

    case (SCode.ALG_NORETCALL(exp = exp1, info = info), _, _, globals)
      equation
        (dexp1, globals) = instExp(exp1, inEnv, inPrefix, info, globals);
      then (NFInstTypes.NORETCALL_STMT(dexp1, info), globals);

    case (SCode.ALG_RETURN(info = info), _, _, globals)
      then (NFInstTypes.RETURN_STMT(info), globals);

    case (SCode.ALG_BREAK(info = info), _, _, globals)
      then (NFInstTypes.BREAK_STMT(info), globals);

    else
      equation
        print("NFInst.instStatement failed: " +& SCodeDump.statementStr(statement) +& "\n");
      then fail();

  end match;
end instStatement;

protected function instIfBranch
  input Absyn.Exp inCondition;
  input list<SCode.EEquation> inBody;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output tuple<DAE.Exp, list<Equation>> outIfBranch;
  output Globals outGlobals;
protected
  DAE.Exp cond_exp;
  list<Equation> eql;
algorithm
  (cond_exp,outGlobals) := instExp(inCondition, inEnv, inPrefix, inInfo, inGlobals);
  (eql,outGlobals) := instEEquations(inBody, inEnv, inPrefix, outGlobals);
  outIfBranch := (cond_exp, eql);
end instIfBranch;

protected function instStatementBranch
  input tuple<Absyn.Exp,list<SCode.Statement>> tpl;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output tuple<DAE.Exp, list<Statement>> outIfBranch;
  output Globals outGlobals;
protected
  Absyn.Exp cond;
  DAE.Exp icond;
  list<SCode.Statement> stmts;
  list<Statement> istmts;
algorithm
  (cond,stmts) := tpl;
  (icond,outGlobals) := instExp(cond, inEnv, inPrefix, inInfo, inGlobals);
  (istmts,outGlobals) := instStatements(stmts, inEnv, inPrefix, outGlobals);
  outIfBranch := (icond, istmts);
end instStatementBranch;

protected function instWhenBranch
  input tuple<Absyn.Exp, list<SCode.EEquation>> inBranch;
  input Env inEnv;
  input Prefix inPrefix;
  input Absyn.Info inInfo;
  input Globals inGlobals;
  output tuple<DAE.Exp, list<Equation>> outBranch;
  output Globals outGlobals;
protected
  Absyn.Exp aexp;
  list<SCode.EEquation> eql;
  DAE.Exp dexp;
  list<Equation> ieql;
algorithm
  (aexp, eql) := inBranch;
  (dexp, outGlobals) := instExp(aexp, inEnv, inPrefix, inInfo, inGlobals);
  (ieql,outGlobals) := instEEquations(eql, inEnv, inPrefix, outGlobals);
  outBranch := (dexp, ieql);
end instWhenBranch;

//protected function instConditionalComponents
//  input Class inClass;
//  input SymbolTable inSymbolTable;
//  input Globals inGlobals;
//  output Class outClass;
//  output SymbolTable outSymbolTable;
//  output Globals outGlobals;
//algorithm
//  (outClass, outSymbolTable, outGlobals) := match(inClass, inSymbolTable, inGlobals)
//    local
//      SymbolTable st;
//      list<Element> comps;
//      list<Equation> eq, ieq;
//      list<list<Statement>> al, ial;
//      Globals globals;
//      Absyn.Path name;
//
//    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st, globals)
//      equation
//        (comps, st, globals) = instConditionalElements(comps, st, {}, globals);
//      then
//        (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st, globals);
//
//    else (inClass, inSymbolTable, inGlobals);
//
//  end match;
//end instConditionalComponents;
//
//protected function instConditionalElements
//  input list<Element> inElements;
//  input SymbolTable inSymbolTable;
//  input list<Element> inAccumEl;
//  input Globals inGlobals;
//  output list<Element> outElements;
//  output SymbolTable outSymbolTable;
//  output Globals outGlobals;
//algorithm
//  (outElements, outSymbolTable, outGlobals) := match(inElements, inSymbolTable, inAccumEl, inGlobals)
//    local
//      Element el;
//      list<Element> rest_el, accum_el;
//      SymbolTable st;
//      Option<Element> oel;
//      Globals globals;
//
//    case ({}, st, accum_el, globals) then (listReverse(accum_el), st, globals);
//
//    case (el :: rest_el, st, accum_el, globals)
//      equation
//        (oel, st, globals) = instConditionalElement(el, st, globals);
//        accum_el = List.consOption(oel, accum_el);
//        (accum_el, st, globals) = instConditionalElements(rest_el, st, accum_el, globals);
//      then
//        (accum_el, st, globals);
//
//  end match;
//end instConditionalElements;
//
//protected function instConditionalElementOnTrue
//  input Boolean inCondition;
//  input Element inElement;
//  input SymbolTable inSymbolTable;
//  input Globals inGlobals;
//  output Option<Element> outElement;
//  output SymbolTable outSymbolTable;
//  output Globals outGlobals;
//algorithm
//  (outElement, outSymbolTable, outGlobals) := match(inCondition, inElement, inSymbolTable, inGlobals)
//    local
//      Option<Element> oel;
//      SymbolTable st;
//      Globals globals;
//
//    case (true, _, st, globals)
//      equation
//        (oel, st, globals) = instConditionalElement(inElement, st, globals);
//      then
//        (oel, st, globals);
//
//    else (NONE(), inSymbolTable, inGlobals);
//
//  end match;
//end instConditionalElementOnTrue;
//
//protected function instConditionalElement
//  input Element inElement;
//  input SymbolTable inSymbolTable;
//  input Globals inGlobals;
//  output Option<Element> outElement;
//  output SymbolTable outSymbolTable;
//  output Globals outGlobals;
//algorithm
//  (outElement, outSymbolTable, outGlobals) := match(inElement, inSymbolTable, inGlobals)
//    local
//      Component comp;
//      Class cls;
//      SymbolTable st;
//      Element el;
//      Option<Element> oel;
//      Absyn.Path bc;
//      DAE.Type ty;
//      Globals globals;
//
//    case (NFInstTypes.ELEMENT(comp, cls), st, globals)
//      equation
//        (cls, st, globals) = instConditionalComponents(cls, st, globals);
//        el = NFInstTypes.ELEMENT(comp, cls);
//      then
//        (SOME(el), st, globals);
//
//    case (NFInstTypes.CONDITIONAL_ELEMENT(comp), st, globals)
//      equation
//        (oel, st, globals) = instConditionalComponent(comp, st, globals);
//      then
//        (oel, st, globals);
//
//    else (SOME(inElement), inSymbolTable, inGlobals);
//
//  end match;
//end instConditionalElement;
//
//protected function instConditionalComponent
//  input Component inComponent;
//  input SymbolTable inSymbolTable;
//  input Globals inGlobals;
//  output Option<Element> outElement;
//  output SymbolTable outSymbolTable;
//  output Globals outGlobals;
//algorithm
//  (outElement, outSymbolTable, outGlobals) := matchcontinue(inComponent, inSymbolTable, inGlobals)
//    local
//      SCode.Element sel;
//      Env env;
//      Prefix prefix;
//      SymbolTable st;
//      DAE.Exp cond_exp;
//      DAE.Type ty;
//      Condition cond;
//      Absyn.Info info;
//      Absyn.Path name;
//      Modifier mod;
//      Option<Element> el;
//      Prefixes prefs;
//      Globals globals;
//
//    case (NFInstTypes.CONDITIONAL_COMPONENT(name, cond_exp, sel, mod, prefs, env,
//        prefix, info), st, globals)
//      equation
//        (cond_exp, ty, _, st) = NFTyping.typeExpEmptyFunctionTable(cond_exp, NFTyping.EVAL_CONST_PARAM(),
//          NFTyping.CONTEXT_MODEL(), st);
//        (cond_exp, _) = ExpressionSimplify.simplify(cond_exp);
//        cond = evaluateConditionalExp(cond_exp, ty, name, info);
//        (el, st, globals) = instConditionalComponent2(cond, name, sel, mod, prefs, env, prefix, st, globals);
//      then
//        (el, st, globals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("NFInst.instConditionalComponent failed on " +&
//          NFInstDump.componentStr(inComponent) +& "\n");
//      then
//        fail();
//
//  end matchcontinue;
//end instConditionalComponent;
//
//protected function instConditionalComponent2
//  input Condition inCondition;
//  input Absyn.Path inName;
//  input SCode.Element inElement;
//  input Modifier inMod;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Prefix inPrefix;
//  input SymbolTable inSymbolTable;
//  input Globals inGlobals;
//  output Option<Element> outElement;
//  output SymbolTable outSymbolTable;
//  output Globals outGlobals;
//algorithm
//  (outElement, outSymbolTable, outGlobals) :=
//  match(inCondition, inName, inElement, inMod, inPrefixes, inEnv, inPrefix, inSymbolTable, inGlobals)
//    local
//      SCode.Element sel;
//      Element el;
//      SymbolTable st;
//      Boolean added;
//      Option<Element> oel;
//      Component comp;
//      Globals globals;
//
//    case (NFInstTypes.SINGLE_CONDITION(true), _, _, _, _, _, _, st, globals)
//      equation
//        // We need to remove the condition from the element, otherwise
//        // instElement will just add it as a conditional component again.
//        sel = SCode.removeComponentCondition(inElement);
//        // Instantiate the element and update the symbol table.
//        (el, globals) = instElement(sel, inMod, NFInstTypes.NOMOD(), inPrefixes, inEnv, inPrefix, INST_ALL(), globals);
//        (st, added) = NFInstSymbolTable.addInstCondElement(el, st);
//        // Recursively instantiate any conditional components in this element.
//        (oel, st, globals) = instConditionalElementOnTrue(added, el, st, globals);
//      then
//        (oel, st, globals);
//
//    case (NFInstTypes.SINGLE_CONDITION(false), _, _, _, _, _, _, st, globals)
//      equation
//        comp = NFInstTypes.DELETED_COMPONENT(inName);
//        st = NFInstSymbolTable.updateComponent(comp, inSymbolTable);
//      then
//        (NONE(), st, globals);
//
//    case (NFInstTypes.ARRAY_CONDITION(conditions = _), _, _, _, _, _, _, st, _)
//      equation
//        print("Sorry, complex arrays with conditional components are not yet supported.\n");
//      then
//        fail();
//
//  end match;
//end instConditionalComponent2;
//
//protected function evaluateConditionalExp
//  input DAE.Exp inExp;
//  input DAE.Type inType;
//  input Absyn.Path inName;
//  input Absyn.Info inInfo;
//  output Condition outCondition;
//algorithm
//  outCondition := match(inExp, inType, inName, inInfo)
//    local
//      Boolean cond;
//      String exp_str, name_str, ty_str;
//      DAE.Type ty;
//      list<DAE.Exp> expl;
//      list<Condition> condl;
//
//    case (DAE.BCONST(bool = cond), DAE.T_BOOL(varLst = _), _, _)
//      then NFInstTypes.SINGLE_CONDITION(cond);
//
//    case (DAE.ARRAY(ty = ty, array = expl), DAE.T_BOOL(varLst = _), _, _)
//      equation
//        condl = List.map3(expl, evaluateConditionalExp, ty, inName, inInfo);
//      then
//        NFInstTypes.ARRAY_CONDITION(condl);
//
//    case (_, DAE.T_BOOL(varLst = _), _, _)
//      equation
//        // TODO: Return the variability of an expression from instExp, so that
//        // we can see whether we got a variable expression here (which is an
//        // error), or if we simply failed to evaluate it (which is a fault in
//        // the compiler).
//        exp_str = ExpressionDump.printExpStr(inExp);
//        Error.addSourceMessage(Error.COMPONENT_CONDITION_VARIABILITY,
//          {exp_str}, inInfo);
//      then
//        fail();
//
//    case (_, _, _, _)
//      equation
//        exp_str = ExpressionDump.printExpStr(inExp);
//        name_str = Absyn.pathString(inName);
//        ty_str = Types.printTypeStr(inType);
//        Error.addSourceMessage(Error.CONDITION_TYPE_ERROR,
//          {exp_str, name_str, ty_str}, inInfo);
//      then
//        fail();
//
//  end match;
//end evaluateConditionalExp;

end NFInst;
