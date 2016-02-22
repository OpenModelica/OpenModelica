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

encapsulated package NFInst
" file:        NFInst.mo
  package:     NFInst
  description: Instantiation


  New instantiation, enable with +d=scodeInst.
"

public import Absyn;
public import DAE;
public import SCode;
public import NFEnv;

protected import Error;
protected import List;
protected import NFFlatten;
protected import NFLookup;
protected import Util;

public import NFEnv.{Env, Scope, ScopeIndex};

public uniontype Instance
  record CLASS_INST
    String name;
    list<Instance> children;
    ScopeIndex scopeIndex;
    ScopeIndex parentScope;
  end CLASS_INST;

  record EXTENDS_INST
    ScopeIndex scopeIndex;
  end EXTENDS_INST;

  record COMP_INST
    String name;
    Instance ty;
    // Integer index?
  end COMP_INST;

  record ELEMENT_DEF
    SCode.Element element;
  end ELEMENT_DEF;
end Instance;

protected function emptyClassInstance
  input String inName;
  output Instance outClass;
algorithm
  outClass := CLASS_INST(inName, {}, NFEnv.NO_SCOPE, NFEnv.NO_SCOPE);
end emptyClassInstance;

public function instClassInProgram
  input Absyn.Path inPath;
  input SCode.Program inProgram;
  output Instance outClass;
protected
  SCode.Element cls;
  String id;
  Env env;
  Instance builtin_scope;
algorithm
  Absyn.IDENT(id) := inPath;
  cls := List.getMemberOnTrue(id, inProgram, SCode.isClassNamed);
  (outClass, env) := instClassElement(cls, NFEnv.newEnv());
  outClass := NFFlatten.flattenClass(outClass);
  dumpClass(outClass);
end instClassInProgram;

protected function instClassElement
  input SCode.Element inClass;
  input Env inEnv;
  output Instance outClass;
  output Env outEnv;
algorithm
  (outClass, outEnv) := partialInstClass(inClass, inEnv);
  outClass := instClass(outClass, outEnv);
end instClassElement;

protected function instClass
  input Instance inClass;
  input Env inEnv;
  output Instance outClass;
  output Env outEnv;
algorithm
  outEnv := inEnv;
  outClass := instClassComponents(inClass, inEnv);
end instClass;

protected function instClassComponents
  input Instance inClass;
  input Env inEnv;
  output Instance outClass = inClass;
algorithm
  outClass := match outClass
    local
      Env env;

    case CLASS_INST()
      algorithm
        env := NFEnv.setCurrentScope(inClass, inEnv);
        outClass.children := instComponents(outClass.children, env);
      then
        outClass;

  end match;
end instClassComponents;

protected function instComponents
  input list<Instance> inElements;
  input Env inEnv;
  output list<Instance> outElements;
protected
  SCode.Element comp;
algorithm
  outElements := list(match e
    case ELEMENT_DEF(element = comp as SCode.COMPONENT())
      then instComponentElement(comp, inEnv);
    else e;
  end match for e in inElements);
end instComponents;

protected function instComponentElement
  input SCode.Element inComponent;
  input Env inEnv;
  output Instance outComponent;
algorithm
  outComponent := match inComponent
    local
      Instance ty;

    case SCode.COMPONENT()
      algorithm
        ty := NFLookup.lookupTypeSpec(inComponent.typeSpec, inEnv,
          inComponent.info);
        ty := instClass(ty, inEnv);
      then
        COMP_INST(inComponent.name, ty);

  end match;
end instComponentElement;

protected function partialInstClass
  input SCode.Element inClass;
  input Env inEnv;
  output Instance outClass;
  output Env outEnv;
algorithm
  outClass := match inClass
    local
      Instance cls;
      list<Instance> el;

    case SCode.CLASS()
      algorithm
        (cls, outEnv) := NFEnv.addScope(emptyClassInstance(inClass.name), inEnv);
        (el, outEnv) := partialInstClassDef(inClass.classDef, outEnv);

        // Partially instantiate classes.
        el := partialInstClassElements(el, outEnv);
        (cls, outEnv) := updateClassChildren(cls, el, outEnv);

        // Partially instantiate extends.
        el := partialInstClassExtends(el, outEnv);
        (cls, outEnv) := updateClassChildren(cls, el, outEnv);
      then
        cls;

  end match;
end partialInstClass;

protected function partialInstClassElements
  input list<Instance> inElements;
  input Env inEnv;
  output list<Instance> outElements = {};
  output Env outEnv = inEnv;
protected
  SCode.Element cls;
  Instance i;
algorithm
  for e in inElements loop
    e := match e
      case ELEMENT_DEF(element = cls as SCode.CLASS())
        algorithm
          (i, outEnv) := partialInstClass(cls, outEnv);
        then
          i;

      else e;
    end match;

    outElements := e :: outElements;
  end for;
  outElements := listReverse(outElements);
end partialInstClassElements;

protected function partialInstClassExtends
  input list<Instance> inElements;
  input Env inEnv;
  output list<Instance> outElements = {};
  output Env outEnv = inEnv;
protected
  SCode.Element ext;
  list<Instance> el;
algorithm
  for e in inElements loop
    _ := match e
      case ELEMENT_DEF(element = ext as SCode.EXTENDS())
        algorithm
          (el, outEnv) := partialInstExtends(ext, outEnv);
          outElements := List.append_reverse(el, outElements);
        then
          ();

      else
        algorithm
          outElements := e :: outElements;
        then
          ();

    end match;
  end for;

  outElements := listReverse(outElements);
end partialInstClassExtends;

protected function partialInstExtends
  input SCode.Element inExtends;
  input Env inEnv;
  output list<Instance> outElements;
  output Env outEnv = inEnv;
algorithm
  _ := match inExtends
    case SCode.EXTENDS()
      algorithm
        CLASS_INST(children = outElements) :=
          NFLookup.lookupBaseClassName(inExtends.baseClassPath, inEnv, inExtends.info);
      then
        ();

  end match;
end partialInstExtends;

protected function updateClassChildren
  input Instance inClass;
  input list<Instance> inChildren;
  input Env inEnv;
  output Instance outClass;
  output Env outEnv;
algorithm
  outClass := setClassChildren(inClass, inChildren);
  outEnv := NFEnv.updateScope(outClass, inEnv);
end updateClassChildren;

protected function setClassChildren
  input Instance inClass;
  input list<Instance> inChildren;
  output Instance outClass = inClass;
algorithm
  outClass := match outClass
    case CLASS_INST()
      algorithm
        outClass.children := inChildren;
      then
        outClass;
  end match;
end setClassChildren;

protected function makeElementDefList
  input list<SCode.Element> inElements;
  output list<Instance> outElementDefs;
algorithm
  outElementDefs := list(ELEMENT_DEF(e) for e in inElements);
end makeElementDefList;

protected function partialInstClassDef
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  output list<Instance> outInstances;
  output Env outEnv = inEnv;
algorithm
  outInstances := match inClassDef
    case SCode.PARTS()
      then makeElementDefList(inClassDef.elementLst);

  end match;
end partialInstClassDef;

public function instanceName
  input Instance inInstance;
  output String outName;
algorithm
  outName := match inInstance
    case CLASS_INST() then inInstance.name;
    case COMP_INST() then inInstance.name;
  end match;
end instanceName;

public function dumpClass
  input Instance inClass;
  input String inIndent = "";
protected
  String name;
  ScopeIndex index, parent;
  list<Instance> children;
algorithm
  CLASS_INST(name = name, children = children, scopeIndex = index, parentScope =
      parent) := inClass;

//  print(inIndent + "class " + name + " <" + intString(index) + ", " +
//      intString(parent) + ">\n");
  print(inIndent + "class " + name + "\n");

  for c in children loop
    _ := match c
      case CLASS_INST()
        algorithm
          dumpClass(c, inIndent + "  ");
        then
          ();

      case EXTENDS_INST()
        algorithm
          print(inIndent + "  extends <" + intString(c.scopeIndex) + ">\n");
        then
          ();

      case COMP_INST()
        algorithm
          print(inIndent + "  " + instanceName(c.ty) + " " + c.name + ";\n");
        then
          ();

      case ELEMENT_DEF()
        algorithm
          print(inIndent + "  element\n");
        then
          ();

    end match;

  end for;

  print("end " + name + ";\n");
end dumpClass;

//public type Binding = NFInstTypes.Binding;
//public type Class = NFInstTypes.Class;
//public type Component = NFInstTypes.Component;
//public type Condition = NFInstTypes.Condition;
//public type Connections = NFConnect2.Connections;
//public type Dimension = NFInstTypes.Dimension;
//public type Element = NFInstTypes.Element;
//public type Env = NFEnv.Env;
//public type Equation = NFInstTypes.Equation;
//public type Function = NFInstTypes.Function;
//public type FunctionHashTable = HashTablePathToFunction.HashTable;
//public type Modifier = NFInstTypes.Modifier;
//public type ParamType = NFInstTypes.ParamType;
//public type Prefixes = NFInstTypes.Prefixes;
//public type Prefix = NFInstPrefix.Prefix;
//public type Statement = NFInstTypes.Statement;
//
//protected type Entry = NFEnv.Entry;
//protected type EntryOrigin = NFInstTypes.EntryOrigin;
//protected type FunctionSlot = NFInstTypes.FunctionSlot;
//protected type SymbolTable = NFInstSymbolTable.SymbolTable;
//protected type Globals = tuple<SymbolTable, FunctionHashTable>;
//
//public uniontype ExtendsState
//  record NO_EXTENDS end NO_EXTENDS;
//  record NORMAL_EXTENDS end NORMAL_EXTENDS;
//  record SPECIAL_EXTENDS end SPECIAL_EXTENDS;
//end ExtendsState;
//
//public function instClass
//  "Flattens a class."
//  input Absyn.Path inClassPath;
//  input Env inEnv;
//  output DAE.DAElist outDae;
//  output DAE.FunctionTree outGlobals;
//algorithm
//  (outDae, outGlobals) := matchcontinue(inClassPath, inEnv)
//    local
//      Entry top_cls;
//      Env env;
//      String name;
//      Class cls;
//      SymbolTable symtab, constants;
//      FunctionHashTable functions;
//      Connections conn;
//      list<NFConnect2.Connector> flows;
//      DAE.DAElist dae_conn, dae;
//      DAE.FunctionTree func_tree;
//
//    case (_, _)
//      equation
//        System.startTimer();
//        name = Absyn.pathLastIdent(inClassPath);
//
//        /*********************************************************************/
//        /* ------------------------- INSTANTIATION ------------------------- */
//        /*********************************************************************/
//
//        // Look up the class to instantiate in the environment.
//        (top_cls, env) = NFLookup.lookupClassName(inClassPath, inEnv, Absyn.dummyInfo);
//
//        //// Instantiate that class.
//        functions = HashTablePathToFunction.emptyHashTableSized(BaseHashTable.lowBucketSize);
//        constants = NFInstSymbolTable.create();
//        (cls, _, _, (constants, functions)) = instClassEntryNoMod(inClassPath, top_cls,
//          env, NFInstPrefix.makeEmptyPrefix(inClassPath), (constants, functions));
//
//        //print(NFInstDump.modelStr(name, cls)); print("\n");
//
//        /*********************************************************************/
//        /* ----------------------------- TYPING ---------------------------- */
//        /*********************************************************************/
//
//        // Build the symboltable to use for typing.
//        symtab = NFInstSymbolTable.build(cls);
//        // Add the package constants found during instantiation.
//        symtab = NFInstSymbolTable.merge(symtab, constants);
//        // Add any builtin elements we might need, like StateSelect.
//        //symtab = NFInstSymbolTable.addClass(builtin_el, symtab);
//
//        // Mark structural parameters.
//        (cls, symtab) = assignParamTypes(cls, symtab);
//
//        // Type all instantiated functions.
//        ((functions, symtab)) = List.fold(BaseHashTable.hashTableKeyList(functions),
//          NFTyping.typeFunction, (functions, symtab));
//
//        // Type the instantiated class.
//        (cls, symtab) = NFTyping.typeClass(cls, NFTyping.CONTEXT_MODEL(), symtab, functions);
//
//        // Instantiate conditional components now that we have typed all crefs
//        // that might be used as conditions.
//        _ = NFInstSymbolTable.create();
//        //(cls, symtab, (constants, functions)) =
//        //  instConditionalComponents(cls, symtab, (constants, functions));
//
//        // Type the instantiated class again, to type any instantiated
//        // conditional components that might have been added.
//        (cls, symtab) = NFTyping.typeClass(cls, NFTyping.CONTEXT_MODEL(), symtab, functions);
//
//        // Type check the typed class components.
//        (cls, symtab) = NFTypeCheck.checkClassComponents(cls, NFTyping.CONTEXT_MODEL(), symtab);
//
//        // Type all equation and algorithm sections in the class.
//        (cls, conn) = NFTyping.typeSections(cls, symtab, functions);
//
//        // Generate connect equations.
//        flows = NFConnectUtil2.collectFlowConnectors(cls);
//        dae_conn = NFConnectEquations.generateEquations(conn, flows);
//
//        System.stopTimer();
//
//        //print(NFInstDump.modelStr(name, cls));
//
//        //print("\n\nConnections:\n");
//        //print(NFInstDump.connectionsStr(conn));
//        //print("\n");
//
//        //print("NFInst took " + realString(System.getTimerIntervalTime()) + " seconds.\n");
//
//        /*********************************************************************/
//        /* --------------------------- EXPANSION --------------------------- */
//        /*********************************************************************/
//
//        // Expand the instantiated and typed class into scalar components,
//        // equations and algorithms.
//        (dae, func_tree) = NFSCodeExpand.expand(name, cls, functions);
//        dae = DAEUtil.appendToCompDae(dae, dae_conn);
//
//        //print("\nEXPANDED FORM:\n\n");
//        //print(DAEDump.dumpStr(dae, func_tree) + "\n");
//      then
//        (dae, func_tree);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        name = Absyn.pathString(inClassPath);
//        Debug.traceln("NFInst.instClass failed on " + name);
//      then
//        fail();
//
//  end matchcontinue;
//end instClass;
//
//protected function instClassEntry
//  input Absyn.Path inTypePath;
//  input Entry inEntry;
//  input Modifier inClassMod;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Prefix inPrefix;
//  input Globals inGlobals;
//  output Class outClass;
//  output DAE.Type outType;
//  output Prefixes outPrefixes;
//  output Globals outGlobals;
//protected
//  SCode.Element el;
//  Modifier mod;
//  Entry entry;
//  Env env;
//algorithm
//  mod := NFEnv.entryModifier(inEntry);
//  (entry, _, env) := redeclareEntry(inEntry, mod, inEnv);
//  el := NFEnv.entryElement(entry);
//  (outClass, outType, outPrefixes, outGlobals) :=
//    instClassEntry_impl(inTypePath, el, entry, inClassMod, inPrefixes, env,
//      inPrefix, inGlobals);
//end instClassEntry;
//
//protected function instClassEntryNoMod
//  "Instantiates a class entry without modifiers and prefixes."
//  input Absyn.Path inTypePath;
//  input Entry inEntry;
//  input Env inEnv;
//  input Prefix inPrefix;
//  input Globals inGlobals;
//  output Class outClass;
//  output DAE.Type outType;
//  output Prefixes outPrefixes;
//  output Globals outGlobals;
//algorithm
//  (outClass, outType, outPrefixes, outGlobals) := instClassEntry(inTypePath, inEntry,
//    NFInstTypes.NOMOD(), NFInstTypes.NO_PREFIXES(), inEnv, inPrefix, inGlobals);
//end instClassEntryNoMod;
//
//protected function instClassEntry_impl
//  input Absyn.Path inTypePath;
//  input SCode.Element inElement;
//  input Entry inEntry;
//  input Modifier inClassMod;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Prefix inPrefix;
//  input Globals inGlobals;
//  output Class outClass;
//  output DAE.Type outType;
//  output Prefixes outPrefixes;
//  output Globals outGlobals;
//algorithm
//  (outClass, outType, outPrefixes, outGlobals) := match(inTypePath, inElement, inEntry,
//      inClassMod, inPrefixes, inEnv, inPrefix, inGlobals)
//    local
//      Absyn.ArrayDim dims;
//      SourceInfo info;
//      Absyn.Path path;
//      Absyn.TypeSpec dty;
//      Class cls;
//      ClassInf.State state;
//      DAE.Type ty;
//      Entry entry;
//      Env env;
//      ExtendsState es;
//      Globals globals;
//      Integer dim_count;
//      list<DAE.Var> vars;
//      list<Element> elems;
//      list<Equation> eq, ieq;
//      list<list<Statement>> alg, ialg;
//      list<SCode.Element> el;
//      list<SCode.Enum> enums;
//      Modifier mod;
//      Prefixes prefs;
//      SCode.Attributes attr;
//      SCode.ClassDef cdef;
//      SCode.Element scls;
//      SCode.Mod smod;
//      SCode.Restriction res;
//      String name;
//      list<Modifier> ext_mods;
//      Prefix prefix;
//
//    // A builtin type (only builtin types can be PARTS).
//    case (_, SCode.CLASS(name = name, restriction = SCode.R_TYPE(),
//          classDef = SCode.PARTS(elementLst = {})), _, _, _, _, _, globals)
//      equation
//        (vars, globals) = instBasicTypeAttributes(inClassMod, name, globals);
//        ty = instBasicType(name, vars);
//      then
//        (NFInstTypes.BASIC_TYPE(inTypePath), ty, NFInstTypes.NO_PREFIXES(), globals);
//
//    case (_, SCode.CLASS( restriction = SCode.R_TYPE(),
//        classDef = SCode.PARTS(elementLst = el)), _, _, _, _, _, globals)
//      equation
//        cdef = makeDerivedTypeClassDef(el);
//        scls = SCode.setElementClassDefinition(cdef, inElement);
//        (cls, ty, prefs, globals) = instClassEntry_impl(inTypePath, scls,
//          inEntry, inClassMod, inPrefixes, inEnv, inPrefix, globals);
//      then
//        (cls, ty, prefs, globals);
//
//    // A class with parts, instantiate all elements in it.
//    case (_, SCode.CLASS(name = name, restriction = res,
//          classDef = cdef as SCode.PARTS(elementLst = el)), _,
//        _, _, _, _, globals)
//      equation
//        // Enter the class scope.
//        (env, ext_mods) = NFLookup.enterEntryScope(inEntry, inClassMod,
//          SOME(inPrefix), inEnv);
//
//        // Instantiate the class' elements.
//        (elems, es, globals) = instElementList(el, ext_mods, inPrefixes, env, globals);
//
//        // Instantiate all equation and algorithm sections.
//        (eq, ieq, alg, ialg, globals) = instSections(cdef, env, globals);
//
//        // Flatten the class parts.
//        cls = NFInstTypes.COMPLEX_CLASS(inTypePath, elems, eq, ieq, alg, ialg);
//        cls = NFInstFlatten.flattenClass(cls, hasExtends(es));
//
//        // Create the class' type.
//        state = ClassInf.start(res, Absyn.IDENT(name));
//        (cls, ty) = NFInstUtil.makeClassType(cls, state, hasSpecialExtends(es));
//      then
//        (cls, ty, NFInstTypes.NO_PREFIXES(), globals);
//
//    // A derived class, look up the inherited class and instantiate it.
//    case (_, SCode.CLASS(name = name, classDef = SCode.DERIVED(modifications = smod,
//          typeSpec = dty), restriction = res, info = info),
//        _, _, _, _, _, globals)
//      equation
//        // Look up the inherited class.
//        (entry, env) = NFLookup.lookupTypeSpec(dty, inEnv, info);
//        path = Absyn.typeSpecPath(dty);
//        //prefix = NFEnv.scopePrefix(inEnv);
//
//        // Merge the modifiers and instantiate the inherited class.
//        dims = Absyn.typeSpecDimensions(dty);
//        dim_count = listLength(dims);
//        mod = NFMod.translateMod(smod, "", dim_count, inEnv);
//        mod = NFMod.mergeMod(NFEnv.entryModifier(inEntry), mod);
//        mod = NFMod.mergeMod(inClassMod, mod);
//
//        //    redecls = listAppend(
//        //      NFSCodeEnv.getDerivedClassRedeclares(name, dty, envDerived),
//        //      NFSCodeFlattenRedeclare.extractRedeclaresFromModifier(smod));
//        //      (item, env, _) = NFSCodeFlattenRedeclare.replaceRedeclaredElementsInEnv(redecls, item, env, inEnv, inPrefix);
//        //
//
//        (cls, ty, prefs, globals) = instClassEntry(inTypePath, entry, mod,
//          inPrefixes, env, inPrefix, globals);
//
//        // Merge the attributes of this class and the attributes of the
//        // inherited class.
//        prefs = NFInstUtil.mergePrefixesWithDerivedClass(path, inElement, prefs);
//
//        // Add any dimensions from this class to the resulting type.
//        (ty, globals) = liftArrayType(dims, ty, inEnv, info, globals);
//
//        // Construct the type for this derived class.
//        state = ClassInf.start(res, Absyn.IDENT(name));
//        ty = NFInstUtil.makeDerivedClassType(ty, state);
//      then
//        (cls, ty, prefs, globals);
//
//    case (_, SCode.CLASS(classDef = SCode.CLASS_EXTENDS()),
//        _, _, _, _, _, globals)
//      equation
//        (cls, ty, globals) =
//          instClassExtends(inElement, inClassMod, inPrefixes, inEnv, globals);
//      then
//        (cls, ty, NFInstTypes.NO_PREFIXES(), globals);
//
//    case (_, SCode.CLASS(classDef = SCode.ENUMERATION(enumLst = enums)),
//        _, _, _, _, _, globals)
//      equation
//        ty = NFInstUtil.makeEnumType(enums, inTypePath);
//      then
//        (NFInstTypes.BASIC_TYPE(inTypePath), ty, NFInstTypes.NO_PREFIXES(), globals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("NFInst.instClassEntry failed on unknown class.\n");
//      then
//        fail();
//
//  end match;
//end instClassEntry_impl;
//
//protected function makeDerivedTypeClassDef
//  input list<SCode.Element> inElements;
//  output SCode.ClassDef outClassDef;
//algorithm
//  outClassDef := match(inElements)
//    local
//      Absyn.Path path;
//      SCode.Mod mod;
//
//    case ({SCode.EXTENDS(baseClassPath = path, modifications = mod)})
//      then SCode.DERIVED(Absyn.TPATH(path, NONE()), mod, SCode.defaultVarAttr);
//
//  end match;
//end makeDerivedTypeClassDef;
//
//protected function instClassExtends
//  input SCode.Element inClassExtends;
//  input Modifier inMod;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Class outClass;
//  output DAE.Type outType;
//  output Globals outGlobals;
//algorithm
//  (outClass, outType, outGlobals) := matchcontinue(inClassExtends, inMod,
//      inPrefixes, inEnv, inGlobals)
//    local
//      SCode.ClassDef cdef;
//      SCode.Mod mod;
//      Globals globals;
//      String name;
//
//    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS()), _, _, _, _)
//      equation
//        print("instClassExtends");
//      then
//        (NFInstTypes.BASIC_TYPE(Absyn.IDENT("test")), DAE.T_INTEGER_DEFAULT, inGlobals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        name = SCode.elementName(inClassExtends);
//        Debug.traceln("NFInst.instClassExtends failed on " + name);
//      then
//        fail();
//
//  end matchcontinue;
//end instClassExtends;
//
////protected function instClassExtends
////  input SCode.Element inClassExtends;
////  input Modifier inMod;
////  input Prefixes inPrefixes;
////  input Env inClassEnv;
////  input Env inEnv;
////  input Prefix inPrefix;
////  input Globals inGlobals;
////  output Class outClass;
////  output DAE.Type outType;
////  output Globals outGlobals;
////algorithm
////  (outClass, outType, outGlobals) :=
////  matchcontinue(inClassExtends, inMod, inPrefixes, inClassEnv, inEnv, inPrefix,
////      inGlobals)
////    local
////      SCode.ClassDef cdef;
////      SCode.Mod mod;
////      SCode.Element scls, ext;
////      Absyn.Path bc_path;
////      SourceInfo info;
////      String name;
////      Item item;
////      Env base_env, ext_env;
////      Class base_cls, ext_cls, comp_cls;
////      DAE.Type base_ty, ext_ty, comp_ty;
////      Globals globals;
////
////    case (SCode.CLASS(classDef = SCode.CLASS_EXTENDS(modifications = mod,
////        composition = cdef)), _, _, _, _, _, globals)
////      equation
////        (bc_path, info) = getClassExtendsBaseClass(inClassEnv);
////        ext = SCode.EXTENDS(bc_path, SCode.PUBLIC(), mod, NONE(), info);
////        cdef = SCode.addElementToCompositeClassDef(ext, cdef);
////        scls = SCode.setElementClassDefinition(cdef, inClassExtends);
////        item = NFSCodeEnv.CLASS(scls, inClassEnv, NFSCodeEnv.CLASS_EXTENDS());
////        (comp_cls, comp_ty, _, globals) = instClassItem(bc_path, item, inMod, inPrefixes, inEnv, inPrefix, globals);
////      then
////        (comp_cls, comp_ty, globals);
////
////    else
////      equation
////        true = Flags.isSet(Flags.FAILTRACE);
////        name = SCode.elementName(inClassExtends);
////        Debug.traceln("NFInst.instClassExtends failed on " + name);
////      then
////        fail();
////
////  end matchcontinue;
////end instClassExtends;
////
////protected function getClassExtendsBaseClass
////  input Env inClassEnv;
////  output Absyn.Path outPath;
////  output SourceInfo outInfo;
////algorithm
////  (outPath, outInfo) := matchcontinue(inClassEnv)
////    local
////      Absyn.Path bc;
////      SourceInfo info;
////      String name;
////
////    case (NFSCodeEnv.FRAME(extendsTable = NFSCodeEnv.EXTENDS_TABLE(
////        baseClasses = NFSCodeEnv.EXTENDS(baseClass = bc, info = info) :: _)) :: _)
////      then (bc, info);
////
////    else
////      equation
////        true = Flags.isSet(Flags.FAILTRACE);
////        name = NFSCodeEnv.getEnvName(inClassEnv);
////        Debug.traceln("NFInst.getClassExtendsBaseClass failed on " + name);
////      then
////        fail();
////
////  end matchcontinue;
////end getClassExtendsBaseClass;
////
//protected function instBasicType
//  input SCode.Ident inTypeName;
//  input list<DAE.Var> inAttributes;
//  output DAE.Type outType;
//algorithm
//  outType := match(inTypeName, inAttributes)
//    case ("Real", _) then DAE.T_REAL(inAttributes, DAE.emptyTypeSource);
//    case ("Integer", _) then DAE.T_INTEGER(inAttributes, DAE.emptyTypeSource);
//    case ("String", _) then DAE.T_STRING(inAttributes, DAE.emptyTypeSource);
//    case ("Boolean", _) then DAE.T_BOOL(inAttributes, DAE.emptyTypeSource);
//    // BTH
//    case ("Clock", _)
//      equation
//        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
//      then DAE.T_CLOCK(inAttributes, DAE.emptyTypeSource);
//    case ("StateSelect", _) then DAE.T_ENUMERATION_DEFAULT;
//  end match;
//end instBasicType;
//
//protected function instBasicTypeAttributes
//  input Modifier inMod;
//  input String inTypeName;
//  input Globals inGlobals;
//  output list<DAE.Var> outVars;
//  output Globals outGlobals;
//algorithm
//  (outVars, outGlobals) := match(inMod, inTypeName, inGlobals)
//    local
//      list<Modifier> submods;
//      list<DAE.Var> vars;
//      SCode.Element el;
//      SourceInfo info;
//      Globals globals;
//
//    case (NFInstTypes.NOMOD(), _, globals) then ({}, globals);
//
//    case (NFInstTypes.MODIFIER(subModifiers = submods), _, globals)
//      equation
//        (vars, globals) =
//          List.map1Fold(submods, instBasicTypeAttribute, inTypeName, globals);
//      then
//        (vars, globals);
//
//    case (NFInstTypes.REDECLARE(element = el), _, _)
//      equation
//        info = SCode.elementInfo(el);
//        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE, {}, info);
//      then
//        fail();
//
//  end match;
//end instBasicTypeAttributes;
//
//protected function instBasicTypeAttribute
//  input Modifier inMod;
//  input String inTypeName;
//  input Globals inGlobals;
//  output DAE.Var outAttribute;
//  output Globals outGlobals;
//algorithm
//  (outAttribute, outGlobals) := match(inMod, inTypeName, inGlobals)
//    local
//      String ident;
//      DAE.Type ty;
//      Absyn.Exp bind_exp;
//      DAE.Exp inst_exp;
//      DAE.Binding binding;
//      Env env;
//      Globals globals;
//      SourceInfo info;
//
//    case (NFInstTypes.MODIFIER(name = ident, subModifiers = {}, binding =
//        NFInstTypes.RAW_BINDING(bindingExp = bind_exp, env = env), info = info), _, globals)
//      equation
//        ty = getBasicTypeAttributeType(inTypeName, ident, info);
//        (inst_exp, globals) = instExp(bind_exp, env, info, globals);
//        binding = DAE.EQBOUND(inst_exp, NONE(), DAE.C_UNKNOWN(),
//          DAE.BINDING_FROM_DEFAULT_VALUE());
//      then
//        (DAE.TYPES_VAR(ident, DAE.dummyAttrParam, ty, binding, NONE()), globals);
//
//  end match;
//end instBasicTypeAttribute;
//
//protected function getBasicTypeAttributeType
//  input String inTypeName;
//  input String inAttributeName;
//  input SourceInfo inInfo;
//  output DAE.Type outType;
//algorithm
//  outType := matchcontinue(inTypeName, inAttributeName, inInfo)
//    case ("Real", _, _) then getBasicTypeAttrTypeReal(inAttributeName);
//    case ("Integer", _, _) then getBasicTypeAttrTypeInt(inAttributeName);
//    case ("Boolean", _, _) then getBasicTypeAttrTypeBool(inAttributeName);
//    case ("String", _, _) then getBasicTypeAttrTypeString(inAttributeName);
//    case ("StateSelect", _, _) then getBasicTypeAttrTypeStateSelect(inAttributeName);
//    else
//      equation
//        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
//          {inAttributeName, inTypeName}, inInfo);
//      then
//        fail();
//
//  end matchcontinue;
//end getBasicTypeAttributeType;
//
//protected function getBasicTypeAttrTypeReal
//  input String inAttributeName;
//  output DAE.Type outType;
//algorithm
//  outType := match(inAttributeName)
//    case "quantity" then DAE.T_STRING_DEFAULT;
//    case "unit" then DAE.T_STRING_DEFAULT;
//    case "displayUnit" then DAE.T_STRING_DEFAULT;
//    case "min" then DAE.T_REAL_DEFAULT;
//    case "max" then DAE.T_REAL_DEFAULT;
//    case "start" then DAE.T_REAL_DEFAULT;
//    case "fixed" then DAE.T_BOOL_DEFAULT;
//    case "nominal" then DAE.T_REAL_DEFAULT;
//    case "stateSelect" then DAE.T_ENUMERATION_DEFAULT;
//  end match;
//end getBasicTypeAttrTypeReal;
//
//protected function getBasicTypeAttrTypeInt
//  input String inAttributeName;
//  output DAE.Type outType;
//algorithm
//  outType := match(inAttributeName)
//    case "quantity" then DAE.T_STRING_DEFAULT;
//    case "min" then DAE.T_INTEGER_DEFAULT;
//    case "max" then DAE.T_INTEGER_DEFAULT;
//    case "start" then DAE.T_INTEGER_DEFAULT;
//    case "fixed" then DAE.T_BOOL_DEFAULT;
//  end match;
//end getBasicTypeAttrTypeInt;
//
//protected function getBasicTypeAttrTypeBool
//  input String inAttributeName;
//  output DAE.Type outType;
//algorithm
//  outType := match(inAttributeName)
//    case "quantity" then DAE.T_STRING_DEFAULT;
//    case "start" then DAE.T_BOOL_DEFAULT;
//    case "fixed" then DAE.T_BOOL_DEFAULT;
//  end match;
//end getBasicTypeAttrTypeBool;
//
//protected function getBasicTypeAttrTypeString
//  input String inAttributeName;
//  output DAE.Type outType;
//algorithm
//  outType := match(inAttributeName)
//    case "quantity" then DAE.T_STRING_DEFAULT;
//    case "start" then DAE.T_STRING_DEFAULT;
//  end match;
//end getBasicTypeAttrTypeString;
//
//protected function getBasicTypeAttrTypeStateSelect
//  input String inAttributeName;
//  output DAE.Type outType;
//algorithm
//  outType := match(inAttributeName)
//    case "quantity" then DAE.T_STRING_DEFAULT;
//    case "min" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//    case "max" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//    case "start" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//    case "fixed" then DAE.T_BOOL_DEFAULT;
//    case "never" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//    case "avoid" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//    case "default" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//    case "prefer" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//    case "always" then NFBuiltin.BUILTIN_TYPE_STATE_SELECT;
//  end match;
//end getBasicTypeAttrTypeStateSelect;
//
//protected function instElementList
//  input list<SCode.Element> inElements;
//  input list<Modifier> inExtendsMods;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Globals inGlobals;
//  output list<Element> outElements;
//  output ExtendsState outExtendsState;
//  output Globals outGlobals;
//algorithm
//  (outElements, outExtendsState, outGlobals) := instElementList2(inElements,
//    inExtendsMods, inPrefixes, inEnv, {}, NO_EXTENDS(), inGlobals);
//end instElementList;
//
//protected function instElementList2
//  input list<SCode.Element> inElements;
//  input list<Modifier> inExtendsMods;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input list<Element> inAccumEl;
//  input ExtendsState inExtendsState;
//  input Globals inGlobals;
//  output list<Element> outElements;
//  output ExtendsState outExtendsState;
//  output Globals outGlobals;
//algorithm
//  (outElements, outExtendsState, outGlobals) := match(inElements, inExtendsMods, inPrefixes,
//      inEnv, inAccumEl, inExtendsState, inGlobals)
//    local
//      SCode.Element elem;
//      list<SCode.Element> rest_el;
//      Modifier mod;
//      ExtendsState es;
//      list<Element> accum_el;
//      Globals globals;
//      Env env;
//      list<Modifier> ext_mods;
//
//    case (elem :: rest_el, _, _, env, accum_el, es, globals)
//      equation
//        (accum_el, ext_mods, es, globals) = instElement(elem, inExtendsMods,
//          inPrefixes, env, accum_el, es, globals);
//        (accum_el, es, globals) = instElementList2(rest_el, ext_mods, inPrefixes,
//          inEnv, accum_el, es, globals);
//      then
//        (accum_el, es, globals);
//
//    case ({}, _, _, _, _, es, globals)
//      then (listReverse(inAccumEl), es, globals);
//
//  end match;
//end instElementList2;
//
//protected function instElement
//  input SCode.Element inElement;
//  input list<Modifier> inExtendsMods;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input list<Element> inAccumEl;
//  input ExtendsState inExtendsState;
//  input Globals inGlobals;
//  output list<Element> outElements;
//  output list<Modifier> outExtendsMods;
//  output ExtendsState outExtendsState;
//  output Globals outGlobals;
//algorithm
//  (outElements, outExtendsMods, outExtendsState, outGlobals) :=
//  match(inElement, inExtendsMods, inPrefixes, inEnv,
//      inAccumEl, inExtendsState, inGlobals)
//    local
//      Globals globals;
//      ExtendsState es;
//      Element res;
//      Option<Element> ores;
//      list<Element> accum_el;
//      String name;
//      Modifier mod;
//      list<Modifier> ext_mods;
//      Entry entry;
//      SCode.Element el;
//      Env env;
//      tuple<SCode.Mod, Env> orig_mod;
//
//    // A component.
//    case (SCode.COMPONENT(name = name), _, _, _, _, _, globals)
//      equation
//        (entry, _) = NFLookup.lookupInLocalScope(name, inEnv);
//        (res, globals) = instComponentEntry(entry, inPrefixes, inEnv, inGlobals);
//      then
//        (res :: inAccumEl, inExtendsMods, inExtendsState, globals);
//
//    // An extends clause.
//    case (SCode.EXTENDS(), mod :: ext_mods, _, _, _, es, globals)
//      equation
//        (res, es, globals) = instExtends(inElement, mod, inPrefixes, inEnv,
//          es, globals);
//      then
//        (res :: inAccumEl, ext_mods, es, globals);
//
//    // Ignore everything else.
//    else (inAccumEl, inExtendsMods, inExtendsState, inGlobals);
//
//  end match;
//end instElement;
//
//protected function getRedeclaredModifier
//  input SCode.Element inElement;
//  output SCode.Mod outModifier;
//algorithm
//  outModifier := match(inElement)
//    local
//      SCode.Mod mod;
//
//    case SCode.COMPONENT(prefixes = SCode.PREFIXES(replaceablePrefix =
//      SCode.REPLACEABLE(cc = SOME(SCode.CONSTRAINCLASS(modifier = mod))))) then mod;
//
//    case SCode.COMPONENT(modifications = mod) then mod;
//
//    else SCode.NOMOD();
//
//  end match;
//end getRedeclaredModifier;
//
//protected function redeclareEntry
//  input Entry inEntry;
//  input Modifier inModifier;
//  input Env inEnv;
//  output Entry outEntry;
//  output tuple<SCode.Mod, Env> outOriginalMod;
//  output Env outEnv;
//algorithm
//  (outEntry, outOriginalMod, outEnv) := match(inEntry, inModifier, inEnv)
//    local
//      SCode.Element el, orig_el;
//      Env env;
//      Modifier mod;
//      SCode.Mod smod;
//      String name;
//      EntryOrigin origin;
//
//    case (_, NFInstTypes.REDECLARE(element = el, env = env, mod = mod), _)
//      equation
//        orig_el = NFEnv.entryElement(inEntry);
//        name = SCode.elementName(orig_el);
//        smod = getRedeclaredModifier(orig_el);
//        origin = NFInstTypes.REDECLARED_ORIGIN(inEntry, inEnv);
//        env = NFEnv.copyScopePrefix(inEnv, env);
//      then
//        (NFInstTypes.ENTRY(name, el, mod, {origin}), (smod, inEnv), env);
//
//    else
//      equation
//        orig_el = NFEnv.entryElement(inEntry);
//        _ = SCode.elementName(orig_el);
//        smod = getRedeclaredModifier(orig_el);
//      then
//        (inEntry, (smod, inEnv), inEnv);
//
//  end match;
//end redeclareEntry;
//
//protected function instComponentEntry
//  input Entry inEntry;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Element outElement;
//  output Globals outGlobals;
//protected
//  String name;
//  Entry entry;
//  Modifier mod;
//  tuple<SCode.Mod, Env> orig_mod;
//  SCode.Element el;
//  Env env;
//algorithm
//  mod := NFEnv.entryModifier(inEntry);
//  (entry, orig_mod, env) := redeclareEntry(inEntry, mod, inEnv);
//  el := NFEnv.entryElement(entry);
//  mod := NFEnv.entryModifier(entry);
//  (outElement, outGlobals) := instComponentElement(el, orig_mod, mod,
//    inPrefixes, inEnv, inGlobals);
//end instComponentEntry;
//
//protected function instComponentElement
//  input SCode.Element inElement;
//  input tuple<SCode.Mod, Env> inElementModifier;
//  input Modifier inOuterModifier;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Element outElement;
//  output Globals outGlobals;
//algorithm
//  (outElement, outGlobals) := match(inElement, inElementModifier,
//      inOuterModifier, inPrefixes, inEnv, inGlobals)
//    local
//      Globals globals;
//      Element el;
//
//    // An outer component.
//    case (SCode.COMPONENT(prefixes = SCode.PREFIXES(innerOuter = Absyn.OUTER())),
//        _, _, _, _, _)
//      equation
//        el = instComponentOuter(inElement, inOuterModifier, inPrefixes, inEnv);
//      then
//        (el, inGlobals);
//
//    // A component that's part of an enumeration, i.e. an enumeration literal.
//    case (SCode.COMPONENT(typeSpec = Absyn.TPATH(path =
//        Absyn.QUALIFIED(name = "$EnumType"))), _, _, _, _, _)
//      equation
//        (el, globals) = instComponentEnum(inElement, inOuterModifier,
//          inPrefixes, inEnv, inGlobals);
//      then
//        (el, globals);
//
//    // A normal component.
//    case (SCode.COMPONENT(condition = NONE()), _, _, _, _, _)
//      equation
//        (el, globals) = instComponent(inElement, inElementModifier,
//          inOuterModifier, inPrefixes, inEnv, inGlobals);
//      then
//        (el, globals);
//
////    // A conditional component, save it for later.
////    case (SCode.COMPONENT(name = name, condition = SOME(cond_exp), info = info),
////        _, _, _, _, _, globals)
////      equation
////        path = NFInstUtil.prefixPath(Absyn.IDENT(name), inPrefix);
////        (inst_exp, globals) = instExp(cond_exp, inEnv, inPrefix, info, globals);
////        comp = NFInstTypes.CONDITIONAL_COMPONENT(path, inst_exp, inElement,
////          inClassMod, inPrefixes, inEnv, inPrefix, info);
////      then
////        (NFInstTypes.CONDITIONAL_ELEMENT(comp), globals);
////
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("NFInst.instComponent failed on unknown component.\n");
//      then
//        fail();
//
//  end match;
//end instComponentElement;
//
//protected function instComponentOuter
//  input SCode.Element inElement;
//  input Modifier inOuterModifier;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  output Element outElement;
//algorithm
//  outElement := match(inElement, inOuterModifier, inPrefixes, inEnv)
//    local
//      Prefix prefix;
//      Absyn.Path path, tpath;
//      Component comp;
//      String name;
//
//    // TODO: Error if an outer component has a modifier.
//
//    case (SCode.COMPONENT(name = name, typeSpec = Absyn.TPATH(path = tpath)), _, _, _)
//      equation
//        prefix = NFEnv.scopePrefix(inEnv);
//        prefix = NFInstPrefix.add(name, {}, prefix);
//        path = NFInstPrefix.toPath(prefix);
//        comp = NFInstTypes.OUTER_COMPONENT(path, NONE());
//      then
//        NFInstTypes.ELEMENT(comp, NFInstTypes.BASIC_TYPE(tpath));
//
//  end match;
//end instComponentOuter;
//
//protected function instComponentEnum
//  input SCode.Element inElement;
//  input Modifier inOuterModifier;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Element outElement;
//  output Globals outGlobals;
//algorithm
//  (outElement, outGlobals) := match(inElement, inOuterModifier, inPrefixes,
//      inEnv, inGlobals)
//    local
//      String enum_idx_str, name;
//      Absyn.Path tpath, path;
//      SourceInfo info;
//      Integer enum_idx;
//      Entry cls_entry;
//      Env env;
//      DAE.Type ty;
//      Prefixes cls_prefs;
//      Globals globals;
//      Binding binding;
//      Component comp;
//      Class cls;
//      Prefix prefix;
//
//    case (SCode.COMPONENT(name = name, typeSpec = Absyn.TPATH(path =
//        Absyn.QUALIFIED(name = "$EnumType", path = tpath)), info = info),
//        _, _, _, globals)
//      equation
//        Absyn.QUALIFIED(name = enum_idx_str, path = tpath) = tpath;
//        enum_idx = stringInt(enum_idx_str);
//
//        (cls_entry, env) = NFLookup.lookupScopeEntry(inEnv);
//        prefix = NFEnv.scopePrefix(inEnv);
//        path = NFInstPrefix.prefixPath(Absyn.IDENT(name), prefix);
//
//        (cls, ty,_, globals) = instClassEntry(tpath, cls_entry, NFInstTypes.NOMOD(),
//          inPrefixes, env, prefix, globals);
//
//        binding = NFInstTypes.TYPED_BINDING(DAE.ENUM_LITERAL(path, enum_idx), ty, -1, info);
//        comp = NFInstTypes.TYPED_COMPONENT(path, ty, NONE(),
//          NFInstTypes.DEFAULT_CONST_DAE_PREFIXES, binding, info);
//      then
//        (NFInstTypes.ELEMENT(comp, cls), globals);
//
//  end match;
//end instComponentEnum;
//
//protected function instComponent
//  input SCode.Element inElement;
//  input tuple<SCode.Mod, Env> inElementModifier;
//  input Modifier inOuterModifier;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Element outElement;
//  output Globals outGlobals;
//algorithm
//  (outElement, outGlobals) := match(inElement, inElementModifier,
//      inOuterModifier, inPrefixes, inEnv, inGlobals)
//    local
//      String name;
//      Absyn.ArrayDim ad;
//      Absyn.Path path, tpath;
//      SourceInfo info;
//      SCode.Mod smod;
//      Env env, mod_env;
//      Globals globals;
//      Entry cls_entry;
//      list<DAE.Dimension> dims;
//      Prefix prefix, comp_prefix;
//      Integer dim_count;
//      Modifier emod, omod, mod;
//      Prefixes prefs, cls_prefs;
//      ParamType pty;
//      DAE.Type ty;
//      array<Dimension> dim_arr;
//      Binding binding;
//      Component comp;
//      Class cls;
//
//    case (SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad),
//        typeSpec = Absyn.TPATH(path = tpath), condition = NONE(), info = info),
//        (smod, mod_env), _, _, _, globals)
//      equation
//        // Lookup the class of the component.
//        (cls_entry, env) = NFLookup.lookupClassName(tpath, inEnv, info);
//        checkPartialInstance(cls_entry, info);
//
//        // Instantiate array dimensions and add them to the prefix.
//        prefix = NFEnv.scopePrefix(inEnv);
//        (dims, globals) = instDimensions(ad, inEnv, info, globals);
//        comp_prefix = NFInstPrefix.add(name, dims, prefix);
//
//        // Check that it's legal to instantiate the class.
//        checkInstanceRestriction(cls_entry, name, info);
//
//        // Translate the component's modification.
//        dim_count = listLength(ad);
//        emod = NFMod.translateMod(smod, name, dim_count, mod_env);
//        omod = NFMod.propagateMod(inOuterModifier, dim_count);
//
//        // TODO: Update inElementMod with prefix and dim_count. Need to get
//        // dimensions from type?
//        mod = NFMod.mergeMod(omod, emod);
//
//        // Merge prefixes from the instance hierarchy.
//        path = NFInstPrefix.prefixPath(Absyn.IDENT(name), prefix);
//        prefs = NFInstUtil.mergePrefixesFromComponent(path, inElement, inPrefixes);
//        pty = NFInstUtil.paramTypeFromPrefixes(prefs);
//
//        // TODO: Check that constants do not have fixed = false.
//
//        (cls, ty, cls_prefs, globals) = instClassEntry(tpath, cls_entry, mod,
//          prefs, env, comp_prefix, globals);
//
//        prefs = NFInstUtil.mergePrefixes(prefs, cls_prefs, path, "variable");
//
//        // Add dimensions from the class type.
//        (dims, dim_count) = addDimensionsFromType(dims, ty);
//        ty = NFInstUtil.arrayElementType(ty);
//        dim_arr = NFInstUtil.makeDimensionArray(dims);
//
//        // Instantiate the binding.
//        mod = NFMod.propagateMod(mod, dim_count);
//        binding = NFMod.modifierBinding(mod);
//        (binding, globals) = instBinding(binding, dim_count, globals);
//
//        // Create the component and add it to the program.
//        comp = NFInstTypes.UNTYPED_COMPONENT(path, ty, dim_arr, prefs, pty, binding, info);
//      then
//        (NFInstTypes.ELEMENT(comp, cls), globals);
//
//  end match;
//end instComponent;
//
//protected function checkInstanceRestriction
//  input Entry inClass;
//  input String inName;
//  input SourceInfo inInfo;
//algorithm
//  _ := matchcontinue(inClass, inName, inInfo)
//    local
//      SCode.Restriction res;
//      String res_str;
//
//    case (_, _, _)
//      equation
//        SCode.CLASS(restriction = res) = NFEnv.entryElement(inClass);
//        true = SCode.isInstantiableClassRestriction(res);
//      then
//        ();
//
//    else
//      equation
//        SCode.CLASS(restriction = res) = NFEnv.entryElement(inClass);
//        res_str = SCodeDump.restrictionStringPP(res);
//        Error.addSourceMessage(Error.INVALID_CLASS_RESTRICTION,
//          {res_str, inName}, inInfo);
//      then
//        fail();
//
//  end matchcontinue;
//end checkInstanceRestriction;
//
//protected function checkPartialInstance
//  input Entry inEntry;
//  input SourceInfo inInfo;
//algorithm
//  _ := matchcontinue(inEntry, inInfo)
//    local
//      String name;
//
//    case (_, _)
//      equation
//        SCode.CLASS(partialPrefix = SCode.NOT_PARTIAL()) =
//          NFEnv.entryElement(inEntry);
//      then
//        ();
//
//    else
//      equation
//        SCode.CLASS(name = name) = NFEnv.entryElement(inEntry);
//        Error.addSourceMessage(Error.INST_PARTIAL_CLASS, {name}, inInfo);
//      then
//        fail();
//
//  end matchcontinue;
//end checkPartialInstance;
//
//protected function instExtends
//  input SCode.Element inExtends;
//  input Modifier inModifier;
//  input Prefixes inPrefixes;
//  input Env inEnv;
//  input ExtendsState inExtendsState;
//  input Globals inGlobals;
//  output Element outElement;
//  output ExtendsState outExtendsState;
//  output Globals outGlobals;
//algorithm
//  (outElement, outExtendsState, outGlobals) := match(inExtends, inModifier,
//      inPrefixes, inEnv, inExtendsState, inGlobals)
//    local
//      Absyn.Path path;
//      SourceInfo info;
//      Entry entry;
//      Env env;
//      Class cls;
//      DAE.Type ty;
//      ExtendsState es;
//      Prefixes prefs;
//      Globals globals;
//      SCode.Mod smod;
//      Modifier mod;
//      Boolean special_ext;
//      Prefix prefix;
//
//    case (SCode.EXTENDS(baseClassPath = path, modifications = smod, info = info),
//        _, _, _, es, globals)
//      equation
//        // Look up the base class in the environment.
//        (entry, env) = NFLookup.lookupBaseClassName(path, inEnv, info);
//        prefs = NFInstUtil.mergePrefixesFromExtends(inExtends, inPrefixes);
//        prefix = NFEnv.scopePrefix(inEnv);
//        mod = NFMod.translateMod(smod, "", 0, inEnv);
//        mod = NFMod.mergeMod(inModifier, mod);
//
//        (cls, ty, _, globals) =
//          instClassEntry(path, entry, mod, prefs, env, prefix, globals);
//
//        special_ext = NFInstUtil.isSpecialExtends(ty);
//        es = updateExtendsState(es, special_ext);
//      then
//        (NFInstTypes.EXTENDED_ELEMENTS(path, cls, ty), es, globals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("NFInst.instExtends failed on unknown element.\n");
//      then
//        fail();
//
//  end match;
//end instExtends;
//
//protected function updateExtendsState
//  "The 'extends state' is used to determine if a class contains any extends, and
//   if any of those extends are 'special'. Special extends are e.g. extending a
//   base type, which is handled differently than normal extends. The extends
//   state is a state machine which can only move in one direction: no extends ->
//   normal extends -> special extends."
//  input ExtendsState inCurrentState;
//  input Boolean inFoundSpecialExtends;
//  output ExtendsState outNewState;
//algorithm
//  outNewState := match(inCurrentState, inFoundSpecialExtends)
//    // Already found special extends, no change.
//    case (SPECIAL_EXTENDS(), _) then inCurrentState;
//    // Found special extends, move to special extends state.
//    case (_, true) then SPECIAL_EXTENDS();
//    // Otherwise we found a normal extends, move to normal extends state.
//    else NORMAL_EXTENDS();
//  end match;
//end updateExtendsState;
//
//protected function hasExtends
//  input ExtendsState inCurrentState;
//  output Boolean outHasExtends;
//algorithm
//  outHasExtends := match(inCurrentState)
//    case NO_EXTENDS() then false;
//    else true;
//  end match;
//end hasExtends;
//
//protected function hasSpecialExtends
//  input ExtendsState inCurrentState;
//  output Boolean outSpecialExtends;
//algorithm
//  outSpecialExtends := match(inCurrentState)
//    case SPECIAL_EXTENDS() then true;
//    else false;
//  end match;
//end hasSpecialExtends;
//
//protected function instBinding
//  input Binding inBinding;
//  input Integer inCompDimensions;
//  input Globals inGlobals;
//  output Binding outBinding;
//  output Globals outGlobals;
//algorithm
//  (outBinding, outGlobals) := match(inBinding, inCompDimensions, inGlobals)
//    local
//      Absyn.Exp aexp;
//      DAE.Exp dexp;
//      Env env;
//      Integer pl, cd;
//      SourceInfo info;
//      Globals globals;
//
//    case (NFInstTypes.RAW_BINDING(aexp, env, pl, info), _, globals)
//      equation
//        (dexp, globals) = instExp(aexp, env, info, globals);
//      then
//        (NFInstTypes.UNTYPED_BINDING(dexp, false, pl, info), globals);
//
//    else (inBinding,inGlobals);
//
//  end match;
//end instBinding;
//
//protected function instDimensions
//  input list<Absyn.Subscript> inSubscript;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output list<DAE.Dimension> outDimensions;
//  output Globals outGlobals;
//algorithm
//  (outDimensions, outGlobals) :=
//    List.map2Fold(inSubscript, instDimension, inEnv, inInfo, inGlobals);
//end instDimensions;
//
//protected function instDimension
//  input Absyn.Subscript inSubscript;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.Dimension outDimension;
//  output Globals outGlobals;
//algorithm
//  (outDimension, outGlobals) :=
//  match(inSubscript, inEnv, inInfo, inGlobals)
//    local
//      Absyn.Exp aexp;
//      DAE.Exp dexp;
//      Globals globals;
//
//    case (Absyn.NOSUB(), _, _, _) then (DAE.DIM_UNKNOWN(),inGlobals);
//
//    case (Absyn.SUBSCRIPT(subscript = aexp), _, _, globals)
//      equation
//        (dexp, globals) = instExp(aexp, inEnv, inInfo, globals);
//      then
//        (NFInstUtil.makeDimension(dexp), globals);
//
//  end match;
//end instDimension;
//
//protected function instSubscripts
//  input list<Absyn.Subscript> inSubscripts;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output list<DAE.Subscript> outSubscripts;
//  output Globals outGlobals;
//algorithm
//  (outSubscripts, outGlobals) :=
//    List.map2Fold(inSubscripts, instSubscript, inEnv, inInfo, inGlobals);
//end instSubscripts;
//
//protected function instSubscript
//  input Absyn.Subscript inSubscript;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.Subscript outSubscript;
//  output Globals outGlobals;
//algorithm
//  (outSubscript, outGlobals) :=
//  match(inSubscript, inEnv, inInfo, inGlobals)
//    local
//      Absyn.Exp aexp;
//      DAE.Exp dexp;
//      Globals globals;
//
//    case (Absyn.NOSUB(), _, _, globals) then (DAE.WHOLEDIM(), globals);
//
//    case (Absyn.SUBSCRIPT(subscript = aexp), _, _, globals)
//      equation
//        (dexp, globals) = instExp(aexp, inEnv, inInfo, globals);
//      then
//        (makeSubscript(dexp), globals);
//
//  end match;
//end instSubscript;
//
//protected function makeSubscript
//  input DAE.Exp inExp;
//  output DAE.Subscript outSubscript;
//algorithm
//  outSubscript := match(inExp)
//    case DAE.RANGE()
//      then DAE.SLICE(inExp);
//
//    else DAE.INDEX(inExp);
//
//  end match;
//end makeSubscript;
//
//protected function liftArrayType
//  input Absyn.ArrayDim inDims;
//  input DAE.Type inType;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.Type outType;
//  output Globals outGlobals;
//algorithm
//  (outType, outGlobals) :=
//  match(inDims, inType, inEnv, inInfo, inGlobals)
//    local
//      DAE.Dimensions dims1, dims2;
//      DAE.TypeSource src;
//      DAE.Type ty;
//      Globals globals;
//
//    case ({}, _, _, _, _) then (inType,inGlobals);
//    case (_, DAE.T_ARRAY(ty, dims1, src), _, _, globals)
//      equation
//        (dims2, globals) =
//          List.map2Fold(inDims, instDimension, inEnv, inInfo, globals);
//        dims1 = listAppend(dims2, dims1);
//      then
//        (DAE.T_ARRAY(ty, dims1, src), globals);
//
//    else
//      equation
//        (dims2, globals) =
//          List.map2Fold(inDims, instDimension, inEnv, inInfo, inGlobals);
//      then
//        (DAE.T_ARRAY(inType, dims2, DAE.emptyTypeSource), globals);
//
//  end match;
//end liftArrayType;
//
//protected function addDimensionsFromType
//  input list<DAE.Dimension> inDimensions;
//  input DAE.Type inType;
//  output list<DAE.Dimension> outDimensions;
//  output Integer outAddedDims;
//algorithm
//  (outDimensions, outAddedDims) := matchcontinue(inDimensions, inType)
//    local
//      list<DAE.Dimension> dims;
//      Integer added_dims;
//
//    case (_, _)
//      equation
//        dims = Types.getDimensions(inType);
//        added_dims = listLength(dims);
//        dims = listAppend(inDimensions, dims);
//      then
//        (dims, added_dims);
//
//    else (inDimensions, 0);
//
//  end matchcontinue;
//end addDimensionsFromType;
//
//protected function instExpList
//  input list<Absyn.Exp> inExp;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output list<DAE.Exp> outExp;
//  output Globals outGlobals;
//algorithm
//  (outExp, outGlobals) :=
//    List.map2Fold(inExp, instExp, inEnv, inInfo, inGlobals);
//end instExpList;
//
//protected function instExpOpt
//  input Option<Absyn.Exp> inExp;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output Option<DAE.Exp> outExp;
//  output Globals outGlobals;
//algorithm
//  (outExp, outGlobals) := match (inExp, inEnv, inInfo, inGlobals)
//    local
//      Absyn.Exp aexp;
//      DAE.Exp dexp;
//      Globals globals;
//
//    case (SOME(aexp), _, _, globals)
//      equation
//        (dexp, globals) = instExp(aexp, inEnv, inInfo, globals);
//      then
//        (SOME(dexp), globals);
//
//    else (NONE(), inGlobals);
//
//  end match;
//end instExpOpt;
//
////protected function isBuiltinFunctionName
////"@author: adrpo
//// check if the name is a builtin function or operator
//// TODO FIXME, add all of them"
////  input Absyn.ComponentRef functionName;
////  output Boolean isBuiltinFname;
////algorithm
////  isBuiltinFname := matchcontinue(functionName)
////    local
////      String name;
////      Boolean b;
////      Absyn.ComponentRef fname;
////
////    case (Absyn.CREF_FULLYQUALIFIED(fname))
////      then
////        isBuiltinFunctionName(fname);
////
////    case (Absyn.CREF_IDENT(name, {}))
////      equation
////        b = listMember(name,
////          {
////            "noEvent",
////            "smooth",
////            "sample",
////            "pre",
////            "edge",
////            "change",
////            "reinit",
////            "size",
////            "rooted",
////            "transpose",
////            "skew",
////            "identity",
////            "min",
////            "max",
////            "cross",
////            "diagonal",
////            "abs",
////            "sum",
////            "product",
////            "assert",
////            "array",
////            "cat",
////            "rem",
////            "actualStream",
////            "inStream",
////            "String",
////            "Real",
////            "Integer"
////            });
////      then
////        b;
////
////    case (_) then false;
////  end matchcontinue;
////end isBuiltinFunctionName;
////
////protected function instBuiltinFunctionCall
////"@author: adrpo
//// build all the builtin calls that are not complete in ModelicaBuiltin.mo
//// TODO FIXME, add all"
////  input Absyn.Exp inExp;
////  input Env inEnv;
////  input Prefix inPrefix;
////  input SourceInfo inInfo;
////  input Globals inGlobals;
////  output DAE.Exp outExp;
////  output Globals outGlobals;
////algorithm
////  (outExp,outGlobals) := match (inExp, inEnv, inPrefix, inInfo, inGlobals)
////    local
////      Absyn.ComponentRef acref;
////      Absyn.Exp aexp1, aexp2;
////      DAE.Exp dexp1, dexp2;
////      list<Absyn.Exp>  afargs;
////      list<Absyn.NamedArg> anamed_args;
////      Globals globals;
////      Absyn.Path call_path;
////      list<DAE.Exp> pos_args, args;
////      list<tuple<String, DAE.Exp>> named_args;
////      list<Element> inputs, outputs;
////      Absyn.ForIterators iters;
////      Env env;
////
////    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
////        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1, aexp2})), _, _, _, globals)
////      equation
////        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
////        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.SIZE(dexp1, SOME(dexp2)), globals);
////
////    case (Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "size"),
////        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
////      equation
////        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.SIZE(dexp1, NONE()), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "smooth"),
////        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1, aexp2})), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
////        (dexp2, globals) = instExp(aexp2, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1,dexp2}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "rooted"),
////        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "transpose"),
////        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "skew"),
////        functionArgs = Absyn.FUNCTIONARGS(args = {aexp1})), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (dexp1, globals) = instExp(aexp1, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "min"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "max"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "cross"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "diagonal"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "abs"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "product"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "pre"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "noEvent"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "sum"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "assert"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "change"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "array"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "array"),
////        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
////        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "sum"),
////        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
////        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "min"),
////        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
////        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "max"),
////        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
////        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "product"),
////        functionArgs = Absyn.FOR_ITER_FARG(exp=aexp1, iterators=iters)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        env = NFSCodeEnv.extendEnvWithIterators(iters, System.tmpTickIndex(NFSCodeEnv.tmpTickIndex), inEnv);
////        (dexp1, globals) = instExp(aexp1, env, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, {dexp1}, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "cat"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "rem"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "actualStream"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "inStream"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "String"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "Integer"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    case (Absyn.CALL(function_ = acref as Absyn.CREF_IDENT(name = "Real"),
////        functionArgs = Absyn.FUNCTIONARGS(args = afargs)), _, _, _, globals)
////      equation
////        call_path = Absyn.crefToPath(acref);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////      then
////        (DAE.CALL(call_path, pos_args, DAE.callAttrBuiltinOther), globals);
////
////    // hopefully all the other ones have a complete entry in ModelicaBuiltin.mo
////    case (Absyn.CALL(function_ = acref,
////        functionArgs = Absyn.FUNCTIONARGS(afargs, anamed_args)), _, _, _, globals)
////      equation
////        (call_path, NFInstTypes.FUNCTION(inputs=inputs,outputs=outputs), globals) = instFunction(acref, inEnv, inPrefix, inInfo, globals);
////        (pos_args, globals) = instExpList(afargs, inEnv, inPrefix, inInfo, globals);
////        (named_args, globals) = List.map3Fold(anamed_args, instNamedArg, inEnv, inPrefix, inInfo, globals);
////        args = fillFunctionSlots(pos_args, named_args, inputs, call_path, inInfo);
////      then
////        (DAE.CALL(call_path, args, DAE.callAttrBuiltinOther), globals);
////
//// end match;
////end instBuiltinFunctionCall;
//
//protected function instFunctionCallDispatch
//  input Absyn.Exp inExp;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.Exp outExp;
//  output Globals outGlobals;
//algorithm
//  (outExp,outGlobals) := matchcontinue (inExp, inEnv, inInfo, inGlobals)
//    local
//      String str;
//      Boolean bval;
//      Absyn.ComponentRef funcName;
//      DAE.Exp dexp1;
//      list<Absyn.Exp>  afargs;
//      list<Absyn.NamedArg> named_args;
//      Globals globals;
//
//    // handle builtin
////    case (Absyn.CALL(function_ = funcName), _, _, _, _)
////      equation
////        true = isBuiltinFunctionName(funcName);
////        (dexp1, globals) = instBuiltinFunctionCall(inExp, inEnv, inPrefix, inInfo, inGlobals);
////      then
////        (dexp1, globals);
//
//    // handle normal calls
//    case (Absyn.CALL(function_ = funcName,
//        functionArgs = Absyn.FUNCTIONARGS(afargs, named_args)), _, _, globals)
//      equation
//        //false = isBuiltinFunctionName(funcName);
//        (dexp1, globals) = instFunctionCall(funcName, afargs, named_args, inEnv, inInfo, globals);
//      then
//        (dexp1, globals);
//
//    // failure
//    case (Absyn.CALL(), _, _, _)
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        //bval = isBuiltinFunctionName(funcName);
//        bval = false;
//        str = if bval then "*builtin*" else "*regular*";
//        Debug.traceln("Failed to instantiate call to " + str + " function: " +
//          Dump.printExpStr(inExp) + " at position:" + Error.infoStr(inInfo));
//      then
//        fail();
//
//    // handle normal calls - put here for debugging so if it fails above you still can debug after.
//    // Let's keep this commented out when not used, otherwise we'll get duplicate error messages.
//    //case (Absyn.CALL(function_ = funcName,
//    //    functionArgs = Absyn.FUNCTIONARGS(afargs, named_args)), _, _, _, globals)
//    //  equation
//    //    false = isBuiltinFunctionName(funcName);
//    //    (dexp1, globals) = instFunctionCall(funcName, afargs, named_args, inEnv, inPrefix, inInfo, globals);
//    //  then
//    //    (dexp1, globals);
//
// end matchcontinue;
//end instFunctionCallDispatch;
//
//protected function instExp
//  input Absyn.Exp inExp;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.Exp outExp;
//  output Globals outGlobals;
//algorithm
//  (outExp, outGlobals) := match(inExp, inEnv, inInfo, inGlobals)
//    local
//      Integer ival;
//      Real rval;
//      String sval, str;
//      Boolean bval;
//      Absyn.ComponentRef acref;
//      DAE.ComponentRef dcref;
//      Absyn.Exp aexp1, aexp2, e1, e2, e3;
//      DAE.Exp dexp1, dexp2, dexp3;
//      Absyn.Operator aop;
//      DAE.Operator dop;
//      list<Absyn.Exp> aexpl;
//      list<DAE.Exp> dexpl;
//      list<list<Absyn.Exp>> mat_expl;
//      Option<Absyn.Exp> oaexp;
//      Option<DAE.Exp> odexp;
//      Globals globals;
//
//    case (Absyn.REAL(value = sval), _, _, globals)
//      equation
//        rval = System.stringReal(sval);
//      then (DAE.RCONST(rval), globals);
//
//    case (Absyn.INTEGER(value = ival), _, _, globals)
//      then (DAE.ICONST(ival), globals);
//
//    case (Absyn.BOOL(value = bval), _, _, globals)
//      then (DAE.BCONST(bval), globals);
//
//    case (Absyn.STRING(value = sval), _, _, globals)
//      then (DAE.SCONST(sval), globals);
//
//    case (Absyn.CREF(componentRef = acref), _, _, globals)
//      equation
//        (dcref, globals) = instCref(acref, inEnv, inInfo, globals);
//      then
//        (DAE.CREF(dcref, DAE.T_UNKNOWN_DEFAULT), globals);
//
//    case (Absyn.BINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inInfo, globals);
//        (dexp2, globals) = instExp(aexp2, inEnv, inInfo, globals);
//        dop = instOperator(aop);
//      then
//        (DAE.BINARY(dexp1, dop, dexp2), globals);
//
//    case (Absyn.UNARY(op = aop, exp = aexp1), _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inInfo, globals);
//        dop = instOperator(aop);
//      then
//        (DAE.UNARY(dop, dexp1), globals);
//
//    case (Absyn.LBINARY(exp1 = aexp1, op = aop, exp2 = aexp2), _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inInfo, globals);
//        (dexp2, globals) = instExp(aexp2, inEnv, inInfo, globals);
//        dop = instOperator(aop);
//      then
//        (DAE.LBINARY(dexp1, dop, dexp2), globals);
//
//    case (Absyn.LUNARY(exp = aexp1), _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inInfo, globals);
//        //dop = instOperator(aop);
//        dop = DAE.NOT(DAE.T_BOOL_DEFAULT);
//      then
//        (DAE.LUNARY(dop, dexp1), globals);
//
//    case (Absyn.RELATION(exp1 = aexp1, op = aop, exp2 = aexp2), _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inInfo, globals);
//        (dexp2, globals) = instExp(aexp2, inEnv, inInfo, globals);
//        dop = instOperator(aop);
//      then
//        (DAE.RELATION(dexp1, dop, dexp2, -1, NONE()), globals);
//
//    case (Absyn.ARRAY(arrayExp = aexpl), _, _, globals)
//      equation
//        (dexp1, globals) = instArray(aexpl, inEnv, inInfo, globals);
//      then
//        (dexp1, globals);
//
//    case (Absyn.MATRIX(matrix = mat_expl), _, _, globals)
//      equation
//        (dexpl, globals) =
//          List.map2Fold(mat_expl, instArray, inEnv, inInfo, globals);
//      then
//        (DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, dexpl), globals);
//
//    case (Absyn.CALL(), _, _, _)
//      equation
//        (dexp1, globals) = instFunctionCallDispatch(inExp, inEnv, inInfo, inGlobals);
//      then
//        (dexp1, globals);
//
//    case (Absyn.RANGE(start = aexp1, step = oaexp, stop = aexp2), _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inInfo, globals);
//        (odexp, globals) = instExpOpt(oaexp, inEnv, inInfo, globals);
//        (dexp2, globals) = instExp(aexp2, inEnv, inInfo, globals);
//      then
//        (DAE.RANGE(DAE.T_UNKNOWN_DEFAULT, dexp1, odexp, dexp2), globals);
//
//    case (Absyn.TUPLE(expressions = aexpl), _, _, globals)
//      equation
//        (dexpl, globals) = instExpList(aexpl, inEnv, inInfo, globals);
//      then
//        (DAE.TUPLE(dexpl), globals);
//
//    case (Absyn.LIST(exps = aexpl), _, _, globals)
//      equation
//        (dexpl, globals) = instExpList(aexpl, inEnv, inInfo, globals);
//      then
//        (DAE.LIST(dexpl), globals);
//
//    case (Absyn.CONS(head = aexp1, rest = aexp2), _, _, globals)
//      equation
//        (dexp1, globals) = instExp(aexp1, inEnv, inInfo, globals);
//        (dexp2, globals) = instExp(aexp2, inEnv, inInfo, globals);
//      then
//        (DAE.CONS(dexp1, dexp2), globals);
//
//    case (Absyn.IFEXP(), _, _, globals)
//      equation
//        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(inExp);
//        (dexp1, globals) = instExp(e1, inEnv, inInfo, globals);
//        (dexp2, globals) = instExp(e2, inEnv, inInfo, globals);
//        (dexp3, globals) = instExp(e3, inEnv, inInfo, globals);
//      then
//        (DAE.IFEXP(dexp1, dexp2, dexp3), globals);
//
//    //Absyn.PARTEVALFUNCTION
//    //Absyn.END
//    //Absyn.CODE
//    //Absyn.AS
//    //Absyn.MATCHEXP
//
//    else
//      equation
//        str = Dump.printExpStr(inExp);
//        str = "NFInst.instExp: Unhandled Expression FIXME: " + str;
//        print(str + "\n");
//      then
//        (DAE.SCONST(str),inGlobals);
//
//  end match;
//end instExp;
//
//protected function instArray
//  input list<Absyn.Exp> inExpl;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.Exp outArray;
//  output Globals outGlobals;
//protected
//  list<DAE.Exp> expl;
//algorithm
//  (expl,outGlobals) :=
//    List.map2Fold(inExpl, instExp, inEnv, inInfo, inGlobals);
//  outArray := DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, expl);
//end instArray;
//
//protected function instOperator
//  input Absyn.Operator inOperator;
//  output DAE.Operator outOperator;
//algorithm
//  outOperator := match(inOperator)
//    case Absyn.ADD() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.SUB() then DAE.SUB(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.MUL() then DAE.MUL(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.DIV() then DAE.DIV(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.POW() then DAE.POW(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.UPLUS() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.UMINUS() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.ADD_EW() then DAE.ADD_ARR(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.SUB_EW() then DAE.SUB_ARR(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.MUL_EW() then DAE.MUL_ARR(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.DIV_EW() then DAE.DIV_ARR(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.POW_EW() then DAE.POW_ARR2(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.UPLUS_EW() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
//    case Absyn.UMINUS_EW() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
//    // logical have boolean type
//    case Absyn.AND() then DAE.AND(DAE.T_BOOL_DEFAULT);
//    case Absyn.OR() then DAE.OR(DAE.T_BOOL_DEFAULT);
//    case Absyn.NOT() then DAE.NOT(DAE.T_BOOL_DEFAULT);
//    // relational have boolean type too
//    case Absyn.LESS() then DAE.LESS(DAE.T_BOOL_DEFAULT);
//    case Absyn.LESSEQ() then DAE.LESSEQ(DAE.T_BOOL_DEFAULT);
//    case Absyn.GREATER() then DAE.GREATER(DAE.T_BOOL_DEFAULT);
//    case Absyn.GREATEREQ() then DAE.GREATEREQ(DAE.T_BOOL_DEFAULT);
//    case Absyn.EQUAL() then DAE.EQUAL(DAE.T_BOOL_DEFAULT);
//    case Absyn.NEQUAL() then DAE.NEQUAL(DAE.T_BOOL_DEFAULT);
//  end match;
//end instOperator;
//
//protected function instCref
//  "This function instantiates a cref, which means translating if from Absyn to
//   DAE representation and prefixing it with the correct prefix so that it can
//   be uniquely identified in the symbol table."
//  input Absyn.ComponentRef inCref;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.ComponentRef outCref;
//  output Globals outGlobals;
//algorithm
//  (outCref,outGlobals) :=
//  matchcontinue(inCref, inEnv, inInfo, inGlobals)
//    local
//      Absyn.ComponentRef acref;
//      DAE.ComponentRef cref;
//      Absyn.Path path;
//      Globals globals;
//
//    // Wildcards should not be prefixed.
//    case (Absyn.WILD(), _, _, _) then (DAE.WILD(), inGlobals);
//    case (Absyn.ALLWILD(), _, _, _) then (DAE.WILD(), inGlobals);
//
//    case (_, _, _, globals)
//      equation
//        // Convert the Absyn.ComponentRef to an untyped DAE.ComponentRef.
//        (cref, globals) = instCref2(inCref, inEnv, inInfo, globals);
//        path = Absyn.crefToPathIgnoreSubs(inCref);
//        // Apply a prefix to the cref to make it uniquely identifiable.
//        (cref, globals) = prefixCref(cref, path, inEnv, inInfo, globals);
//      then
//        (cref, globals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFInst.instCref failed on " + Dump.printComponentRefStr(inCref));
//      then
//        fail();
//
//  end matchcontinue;
//end instCref;
//
//protected function instCref2
//  "Helper function to instCref, converts an Absyn.ComponentRef to a
//   DAE.ComponentRef. This is done by instantiating the cref's subscripts, and
//   constructing a DAE.ComponentRef with unknown type (which is filled in during
//   typing later on)."
//  input Absyn.ComponentRef inCref;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.ComponentRef outCref;
//  output Globals outGlobals;
//algorithm
//  (outCref,outGlobals) := match(inCref, inEnv, inInfo, inGlobals)
//    local
//      String name;
//      Absyn.ComponentRef cref;
//      DAE.ComponentRef dcref;
//      list<Absyn.Subscript> asubs;
//      list<DAE.Subscript> dsubs;
//      Globals globals;
//
//    case (Absyn.CREF_IDENT(name, asubs), _, _, globals)
//      equation
//        (dsubs, globals) =
//          instSubscripts(asubs, inEnv, inInfo, globals);
//      then
//        (DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, dsubs), globals);
//
//    case (Absyn.CREF_QUAL(name, asubs, cref), _, _, globals)
//      equation
//        (dsubs, globals) =
//          instSubscripts(asubs, inEnv, inInfo, globals);
//        (dcref, globals) = instCref2(cref, inEnv, inInfo, globals);
//      then
//        (DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, dsubs, dcref), globals);
//
//    case (Absyn.CREF_FULLYQUALIFIED(cref), _, _, globals)
//      equation
//        (dcref, globals) = instCref2(cref, inEnv, inInfo, globals);
//      then
//        (dcref, globals);
//
//  end match;
//end instCref2;
//
//protected function prefixCref
//  "Prefixes a cref so that it can be uniquely identified in the symbol table."
//  input DAE.ComponentRef inCref;
//  input Absyn.Path inCrefPath;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.ComponentRef outCref;
//  output Globals outGlobals;
//algorithm
//  (outCref, outGlobals) :=
//  matchcontinue(inCref, inCrefPath, inEnv, inInfo, inGlobals)
//    local
//      Env base_env, env;
//      Entry entry;
//      DAE.ComponentRef cref;
//      Boolean is_class;
//      String name_str, env_str;
//      Globals globals;
//      Option<Prefix> opt_prefix;
//      Prefix prefix;
//      SCode.Element elem;
//
//    // Builting names should not be prefixed.
//    case (_, _, _, _, _)
//      equation
//        (_, _) = NFLookup.lookupBuiltinName(inCrefPath, inEnv);
//      then
//        (inCref, inGlobals);
//
//    // Fully qualified names are already prefixed.
//    case (_, Absyn.FULLYQUALIFIED(_), _, _, _)
//      equation
//        (entry, env) = NFLookup.lookupVariableName(inCrefPath, inEnv, inInfo);
//        prefix = NFEnv.envPrefix(env);
//        globals = instPackageConstant(inCref, entry, env, SOME(prefix), inInfo, inGlobals);
//      then
//        (inCref, globals);
//
//    // Any other cref needs to have a prefix applied.
//    case (_, _, _, _, _)
//      equation
//        // Look up the first identifier in the cref and figure out the correct
//        // prefix for the cref.
//        name_str = ComponentReference.crefFirstIdent(inCref);
//        (entry, base_env) = NFLookup.lookupSimpleNameUnresolved(name_str, inEnv);
//        is_class = NFEnv.isClassEntry(entry);
//        opt_prefix = NFEnv.scopePrefixOpt(base_env);
//        prefix = makeNamePrefix(opt_prefix, base_env);
//
//        // Look up the whole cref and prefix it.
//        (entry, env) = NFLookup.lookupVariableName(inCrefPath, inEnv, inInfo);
//        cref = prefixCref2(inCref, prefix, env);
//
//        // If the cref refers to a package constant, make sure it's instantiated
//        // and added to the symbol table.
//        opt_prefix = makePackageConstantPrefix(is_class, opt_prefix, inCrefPath, prefix);
//        globals = instPackageConstant(cref, entry, env, opt_prefix, inInfo, inGlobals);
//      then
//        (cref, globals);
//
//  end matchcontinue;
//end prefixCref;
//
//protected function makeNamePrefix
//  "Creates a name prefix given the prefix from the environment where the first
//   part of the name was found."
//  input Option<Prefix> inPrefix;
//  input Env inEnv;
//  output Prefix outPrefix;
//algorithm
//  outPrefix := match(inPrefix, inEnv)
//    local
//      Prefix prefix;
//
//    // The current scope has a prefix, use it.
//    case (SOME(prefix), _) then prefix;
//    // The current scope has no prefix, use the environment to make one.
//    case (NONE(), _) then NFEnv.envPrefix(inEnv);
//
//  end match;
//end makeNamePrefix;
//
//protected function prefixCref2
//  input DAE.ComponentRef inCref;
//  input Prefix inPrefix;
//  input Env inEnv;
//  output DAE.ComponentRef outCref;
//algorithm
//  outCref := matchcontinue(inCref, inPrefix, inEnv)
//    local
//      String id;
//      Integer iterIndex;
//      DAE.Type ty;
//      list<DAE.Subscript> subs;
//      Prefix prefix;
//
//    // Don't prefix iterators, just convert them to CREF_ITER.
//    case (DAE.CREF_IDENT(id, ty, subs), _, _)
//      equation
//        iterIndex = NFEnv.getImplicitScopeIndex(inEnv);
//      then
//        DAE.CREF_ITER(id, iterIndex, ty, subs);
//
//    // For all other crefs, apply the given prefix.
//    else NFInstPrefix.prefixCref(inCref, inPrefix);
//
//  end matchcontinue;
//end prefixCref2;
//
//protected function makePackageConstantPrefix
//  "Creates a prefix for a package constant, or returns NONE() if the cref isn't
//   a package constant that needs to be instantiated."
//  input Boolean inIsClass;
//  input Option<Prefix> inPrefix;
//  input Absyn.Path inCrefPath;
//  input Prefix inCrefPrefix;
//  output Option<Prefix> outPrefix;
//algorithm
//  outPrefix :=
//  match(inIsClass, inPrefix, inCrefPath, inCrefPrefix)
//    local
//      Prefix prefix;
//
//    // A component found in a scope with a prefix. If the prefix is a package
//    // prefix then the cref is a package constant which should be instantiated
//    // because it's a dependency of another package constant, in which case the
//    // given prefix should be used. Otherwise it's not a package constant and
//    // will be instantiated normally, in which case NONE() is returned.
//    case (false, SOME(prefix), _, _)
//      then if NFInstPrefix.isPackagePrefix(prefix) then inPrefix else NONE();
//
//    // Otherwise we have a component without a prefix or a class.
//    else
//      equation
//        // If the scope has a prefix, use that. Otherwise use the cref prefix.
//        prefix = Util.getOptionOrDefault(inPrefix, inCrefPrefix);
//        // Add the cref path except for the last identifier to the prefix.
//        prefix = NFInstPrefix.addOptPath(Absyn.stripLastOpt(inCrefPath), prefix);
//      then
//        SOME(prefix);
//
//  end match;
//end makePackageConstantPrefix;
//
//protected function instPackageConstant
//  "If given some prefix, instantiates the given entry and adds it to the global
//   symbol table."
//  input DAE.ComponentRef inCref;
//  input Entry inEntry;
//  input Env inEnv;
//  input Option<Prefix> inPrefix;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output Globals outGlobals;
//algorithm
//  outGlobals := matchcontinue(inCref, inEntry, inEnv, inPrefix, inInfo, inGlobals)
//    local
//      Prefix prefix;
//      SymbolTable consts;
//      FunctionHashTable funcs;
//      Element elem;
//      Env env;
//      Globals globals;
//      String cref_str;
//
//    // No prefix => not a package constant. Nothing should be done.
//    case (_, _, _, NONE(), _, _) then inGlobals;
//
//    // Skip instantiation if the package constant has already been instantiated.
//    case (_, _, _, _, _, (consts, _))
//      equation
//        _ = NFInstSymbolTable.lookupCref(inCref, consts);
//      then
//        inGlobals;
//
//    // An enumeration typename used as a dimension or for range.
//    case (_, _, _, SOME(prefix), _, (_, _))
//      equation
//        true = NFEnv.isClassEntry(inEntry);
//      then
//        instPackageEnumType(inEntry, inEnv, prefix, inInfo, inGlobals);
//
//    // A prefix => a package constant. Instantiate the given entry.
//    case (_, _, _, SOME(prefix), _, _)
//      equation
//        false = NFEnv.isClassEntry(inEntry);
//        env = NFEnv.setScopePrefix(prefix, inEnv);
//        (elem, (consts, funcs)) =
//          instComponentEntry(inEntry, NFInstTypes.NO_PREFIXES(), env, inGlobals);
//        consts = NFInstSymbolTable.addElement(elem, consts);
//      then
//        ((consts, funcs));
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        cref_str = ComponentReference.printComponentRefStr(inCref);
//        Debug.traceln("- NFInst.instPackageConstant failed on " + cref_str);
//      then
//        fail();
//
//  end matchcontinue;
//end instPackageConstant;
//
//protected function instPackageEnumType
//  "Instantiates an enumeration typename used as a dimension or for range."
//  input Entry inEntry;
//  input Env inEnv;
//  input Prefix inPrefix;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output Globals outGlobals;
//algorithm
//  outGlobals := match(inEntry, inEnv, inPrefix, inInfo, inGlobals)
//    local
//      SymbolTable consts;
//      FunctionHashTable funcs;
//      String name;
//      Prefix prefix;
//      Component comp;
//      Absyn.Path path;
//      Env env;
//      list<String> lit_names;
//      DAE.Type ty;
//
//    case (_, _, _, _, _)
//      equation
//        // Make sure that we got a class.
//        SCode.CLASS(name = name) = NFEnv.entryElement(inEntry);
//        prefix = NFInstPrefix.addString(name, inPrefix);
//        path = NFInstPrefix.toPath(prefix);
//
//        // Instantiate the class.
//        (_, ty, _, (consts, funcs)) =
//          instClassEntryNoMod(path, inEntry, inEnv, prefix, inGlobals);
//
//        // Make sure it was an enumeration, and make a component for the
//        // enumeration typename which has an array of all literals as binding.
//        ty = Types.derivedBasicType(ty);
//        DAE.T_ENUMERATION(names = lit_names) = ty;
//        comp = instEnumTypeComponent(lit_names, path, inInfo);
//        consts = NFInstSymbolTable.addComponent(comp, consts);
//
//        // Add all literals to the symbol table too.
//        consts = instPackageEnumTypeLiterals(lit_names, prefix, ty, 1, consts);
//      then
//        ((consts, funcs));
//
//  end match;
//end instPackageEnumType;
//
//protected function instPackageEnumTypeLiterals
//  "Adds all literals for an enumeration to the symbol table."
//  input list<String> inLiterals;
//  input Prefix inPrefix;
//  input DAE.Type inType;
//  input Integer inIndex;
//  input SymbolTable inConstants;
//  output SymbolTable outConstants;
//algorithm
//  outConstants := match(inLiterals, inPrefix, inType, inIndex, inConstants)
//    local
//      String lit;
//      list<String> rest_lits;
//      Absyn.Path name;
//      Component comp;
//      SymbolTable consts;
//      Integer idx;
//
//    case (lit :: rest_lits, _, _, _, _)
//      equation
//        name = NFInstPrefix.prefixPath(Absyn.IDENT(lit), inPrefix);
//        comp = NFInstUtil.makeEnumLiteralComp(name, inType, inIndex);
//        consts = NFInstSymbolTable.addComponent(comp, inConstants);
//        idx = inIndex + 1;
//      then
//        instPackageEnumTypeLiterals(rest_lits, inPrefix, inType, idx, consts);
//
//    else inConstants;
//
//  end match;
//end instPackageEnumTypeLiterals;
//
//protected function makeEnumArray
//  "Expands an enumeration type to an array of it's enumeration literals."
//  input Absyn.Path inTypeName;
//  input list<String> inLiterals;
//  output DAE.Exp outArrayExp;
//  output DAE.Type outType;
//protected
//  list<String> names;
//  list<DAE.Exp> enum_lit_expl;
//  Integer sz;
//  DAE.Type ety;
//algorithm
//  enum_lit_expl := Expression.makeEnumLiterals(inTypeName, inLiterals);
//  sz := listLength(inLiterals);
//  ety := DAE.T_ARRAY(
//  DAE.T_ENUMERATION(NONE(), inTypeName, inLiterals, {}, {}, DAE.emptyTypeSource),
//    {DAE.DIM_ENUM(inTypeName, inLiterals, sz)},
//    DAE.emptyTypeSource);
//  outArrayExp := DAE.ARRAY(ety, true, enum_lit_expl);
//  outType := ety;
//end makeEnumArray;
//
//protected function instEnumTypeComponent
//  "Creates a component for an enumeration typename which has an array of all
//   literals as binding."
//  input list<String> inLiterals;
//  input Absyn.Path inEnumPath;
//  input SourceInfo inInfo;
//  output Component outComponent;
//protected
//  DAE.Type ty;
//  DAE.Exp enum_arr;
//  Binding binding;
//algorithm
//  (enum_arr, ty) := makeEnumArray(inEnumPath, inLiterals);
//  binding := NFInstTypes.TYPED_BINDING(enum_arr, ty, 0, inInfo);
//  outComponent := NFInstTypes.TYPED_COMPONENT(inEnumPath, ty, NONE(),
//    NFInstTypes.DEFAULT_CONST_DAE_PREFIXES, binding, inInfo);
//end instEnumTypeComponent;
//
//protected function prefixPath
//  "Prefixes a path so that it can be uniquely identified."
//  input Absyn.Path inPath;
//  input Env inCurrentEnv;
//  output Absyn.Path outPath;
//algorithm
//  outPath := match(inPath, inCurrentEnv)
//    local
//      String first_id;
//      Option<Prefix> opt_prefix;
//      Prefix prefix;
//      Env env;
//      Absyn.Path path;
//
//    // Fully qualified paths doesn't need to be prefixed.
//    case (Absyn.FULLYQUALIFIED(_), _) then inPath;
//
//    else
//      equation
//        // Look up the first identifier in the path to get the environment where
//        // it's defined.
//        first_id = Absyn.pathFirstIdent(inPath);
//        (_, env) = NFLookup.lookupSimpleNameUnresolved(first_id, inCurrentEnv);
//
//        // Use the found environment to figure out the correct prefix and apply
//        // it to the path.
//        opt_prefix = NFEnv.scopePrefixOpt(env);
//        prefix = makeNamePrefix(opt_prefix, env);
//        path = NFInstPrefix.prefixPath(inPath, prefix);
//      then
//        path;
//
//  end match;
//end prefixPath;
//
//protected function instFunctionCall
//  input Absyn.ComponentRef inName;
//  input list<Absyn.Exp> inPositionalArgs;
//  input list<Absyn.NamedArg> inNamedArgs;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output DAE.Exp outCallExp;
//  output Globals outGlobals;
//algorithm
//  (outCallExp, outGlobals) :=
//  match(inName, inPositionalArgs, inNamedArgs, inEnv, inInfo, inGlobals)
//    local
//      Absyn.Path call_path;
//      list<DAE.Exp> pos_args, args;
//      list<tuple<String, DAE.Exp>> named_args;
//      Function func;
//      list<Element> inputs;
//      Globals globals;
//      DAE.Exp exp;
//
//    case (Absyn.CREF_IDENT(name = "size"), _, _, _, _, globals)
//      equation
//        (pos_args, globals) = instExpList(inPositionalArgs, inEnv, inInfo, globals);
//        exp = instBuiltinSize(pos_args, inNamedArgs, inInfo);
//      then
//        (exp, globals);
//
//    case (_, _, _, _, _, globals)
//      equation
//        (call_path, func, globals) = instFunction(inName, inEnv, inInfo, globals);
//        (pos_args, globals) = instExpList(inPositionalArgs, inEnv, inInfo, globals);
//        (named_args, globals) = List.map2Fold(inNamedArgs, instNamedArg, inEnv, inInfo, globals);
//        inputs = NFInstUtil.getFunctionInputs(func);
//        args = fillFunctionSlots(pos_args, named_args, inputs, call_path, inInfo);
//      then
//        (DAE.CALL(call_path, args, DAE.callAttrBuiltinOther), globals);
//
//  end match;
//end instFunctionCall;
//
//protected function instBuiltinSize
//  input list<DAE.Exp> inPositionalArgs;
//  input list<Absyn.NamedArg> inNamedArgs;
//  input SourceInfo inInfo;
//  output DAE.Exp outSizeExp;
//algorithm
//  outSizeExp := match(inPositionalArgs, inNamedArgs, inInfo)
//    local
//      String name;
//      DAE.Exp array_exp, idx_exp;
//
//    case (_, Absyn.NAMEDARG(argName = name) :: _, _)
//      equation
//        Error.addSourceMessage(Error.NO_SUCH_ARGUMENT, {"size", name}, inInfo);
//      then
//        fail();
//
//    case ({array_exp}, _, _)
//      then DAE.SIZE(array_exp, NONE());
//
//    case ({array_exp, idx_exp}, _, _)
//      then DAE.SIZE(array_exp, SOME(idx_exp));
//
//    else
//      equation
//        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS, {"size"}, inInfo);
//      then
//        fail();
//
//  end match;
//end instBuiltinSize;
//
//protected function instFunction
//  input Absyn.ComponentRef inName;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output Absyn.Path outName;
//  output Function outFunction;
//  output Globals outGlobals;
//algorithm
//  (outName, outFunction, outGlobals) := matchcontinue(inName, inEnv, inInfo, inGlobals)
//    local
//      Absyn.Path path;
//      Entry entry;
//      Env env;
//      Class cls;
//      Function func;
//      Boolean is_record, is_builtin;
//      DAE.Type ty;
//      FunctionHashTable functions;
//      SymbolTable consts;
//      Prefix prefix;
//
//    /*
//    case (_, _, _, _, globals)
//      equation
//        path = Absyn.crefToPath(inName);
//        outFunction = BaseHashTable.get(path, globals);
//      then (path, outFunction, globals);
//    */
//
//    case (_, _, _, _)
//      equation
//        path = instFunctionName(inName, inInfo);
//        (entry, env) = NFLookup.lookupFunctionName(path, inEnv, inInfo);
//        is_builtin = NFEnv.entryHasBuiltinOrigin(entry);
//        path = prefixFunctionName(path, is_builtin, inEnv);
//        (cls, ty, (consts, functions)) =
//          instFunctionEntry(path, entry, is_builtin, env, inGlobals);
//        is_record = Types.isRecord(ty);
//        func = instFunction2(path, cls, is_record);
//        functions = BaseHashTable.add((path, func), functions);
//      then
//        (path, func, (consts, functions));
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("NFInst.instFunction failed: " + Absyn.printComponentRefStr(inName) +
//          " at position: " + Error.infoStr(inInfo));
//        //(_, _, _) = instFunction(inName, inEnv, inPrefix, inInfo, inGlobals);
//      then fail();
//  end matchcontinue;
//end instFunction;
//
//protected function instFunctionName
//  input Absyn.ComponentRef inName;
//  input SourceInfo inInfo;
//  output Absyn.Path outName;
//algorithm
//  outName := matchcontinue(inName, inInfo)
//    local
//      String name;
//
//    case (_, _) then Absyn.crefToPath(inName);
//
//    else
//      equation
//        name = Dump.printComponentRefStr(inName);
//        Error.addSourceMessage(Error.SUBSCRIPTED_FUNCTION_CALL, {name}, inInfo);
//      then
//        fail();
//
//  end matchcontinue;
//end instFunctionName;
//
//protected function prefixFunctionName
//  input Absyn.Path inPath;
//  input Boolean inBuiltin;
//  input Env inEnv;
//  output Absyn.Path outPath;
//algorithm
//  outPath := match(inPath, inBuiltin, inEnv)
//    case (_, true, _) then inPath; // Don't prefix builtin functions.
//    else prefixPath(inPath, inEnv);
//  end match;
//end prefixFunctionName;
//
//protected function instFunctionEntry
//  input Absyn.Path inPath;
//  input Entry inEntry;
//  input Boolean inIsBuiltin;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Class outClass;
//  output DAE.Type outType;
//  output Globals outGlobals;
//algorithm
//  (outClass, outType, outGlobals) := match(inPath, inEntry, inIsBuiltin, inEnv, inGlobals)
//    local
//      Class cls;
//      DAE.Type ty;
//      Globals globals;
//
//    //case (_, _, false, _, _)
//    case (_, _, _, _, _)
//      equation
//        (cls, ty, _, globals) = instClassEntryNoMod(inPath, inEntry,
//          inEnv, NFInstPrefix.makeEmptyPrefix(inPath), inGlobals);
//      then
//        (cls, ty, globals);
//
//    //else
//    //  equation
//    //    (cls, ty, globals) = instBuiltinFunction(inPath, inEntry, inEnv, inGlobals);
//    //  then
//    //    (cls, ty, globals);
//
//  end match;
//end instFunctionEntry;
//
////protected function instBuiltinFunction
////  input Absyn.Path inPath;
////  input Entry inEntry;
////  input Env inEnv;
////  input Globals inGlobals;
////  output Class outClass;
////  output DAE.Type outType;
////  output Globals outGlobals;
////algorithm
////  (outClass, outType, outGlobals) := matchcontinue(inPath, inEntry, inEnv, inGlobals)
////    local
////      Class cls;
////      DAE.Type ty;
////      Globals globals;
////
////    case (_, _, _, _)
////      equation
////        (cls, ty) = instBuiltinSpecialFunction(inPath, inEntry, inEnv);
////      then
////        (cls, ty, inGlobals);
////
////    else
////      equation
////        (cls, ty, globals) = instFunctionEntry(inPath, inEntry, false, inEnv, inGlobals);
////      then
////        (cls, ty, globals);
////
////  end matchcontinue;
////end instBuiltinFunction;
//
//protected function instFunction2
//  input Absyn.Path inName;
//  input Class inFunction;
//  input Boolean inIsRecord;
//  output Function outFunction;
//algorithm
//  outFunction := match(inName, inFunction, inIsRecord)
//    local
//      list<Element> inputs, outputs, locals;
//      list<list<Statement>> algorithms;
//      list<Statement> stmts;
//      list<Statement> initBindings;
//      DAE.Type recRetType;
//      list<DAE.Var> vars;
//
//    // Records, treat them the same as globals and add bindings as algorithm
//    // statements.
//    case (_, NFInstTypes.COMPLEX_CLASS(components = locals,
//        algorithms = algorithms), true)
//      equation
//        initBindings = {};
//        (locals, initBindings) = List.mapFold(locals, dimensionDeps, initBindings);
//        (initBindings, {}) = Graph.topologicalSort(
//          Graph.buildGraph(initBindings, getStatementDependencies,
//            (initBindings, List.map(initBindings, getInitStatementName))),
//          statementLhsEqual);
//        algorithms = initBindings :: algorithms;
//        stmts = List.flatten(algorithms);
//
//        // make DAE vars for the return type. Includes all components in the record.
//        // No need to type and expand an NFInstTypes.ELEMENT. We know what we want.
//        vars = List.accumulateMapReverse(locals, NFInstUtil.makeDaeVarsFromElement);
//        recRetType = DAE.T_COMPLEX(ClassInf.RECORD(inName), vars, NONE(), DAE.emptyTypeSource);
//
//        // extract all modifiable components in to 'inputs' the rest go in 'locals'
//        (inputs, locals) = List.extractOnTrue(locals, NFInstUtil.isModifiableElement);
//        // strip all other prefixes and mark as inputs
//        inputs = List.map(inputs, NFInstUtil.markElementAsInput);
//        // strip all other prefixes and mark as protected.
//        locals = List.map(locals, NFInstUtil.markElementAsProtected);
//      then
//        NFInstTypes.RECORD_CONSTRUCTOR(inName, recRetType, inputs, locals, stmts);
//
//    // Normal globals.
//    case (_, NFInstTypes.COMPLEX_CLASS(algorithms = algorithms), false)
//      equation
//        (inputs, outputs, locals) = getFunctionParameters(inFunction);
//        initBindings = {};
//        (outputs, initBindings) = List.mapFold(outputs, stripInitBinding, initBindings);
//        (locals, initBindings) = List.mapFold(locals, stripInitBinding, initBindings);
//        (outputs, initBindings) = List.mapFold(outputs, dimensionDeps, initBindings);
//        (locals, initBindings) = List.mapFold(locals, dimensionDeps, initBindings);
//        (initBindings, {}) = Graph.topologicalSort(
//          Graph.buildGraph(initBindings, getStatementDependencies,
//            (initBindings, List.map(initBindings, getInitStatementName))),
//          statementLhsEqual);
//        algorithms = initBindings :: algorithms;
//        stmts = List.flatten(algorithms);
//      then
//        NFInstTypes.FUNCTION(inName, inputs, outputs, locals, stmts);
//
//  end match;
//end instFunction2;
//
//protected function statementLhsEqual
//  input Statement left;
//  input Statement right;
//  output Boolean b;
//algorithm
//  b := stringEq(getInitStatementName(left),getInitStatementName(right));
//end statementLhsEqual;
//
//protected function getInitStatementName
//  "x := ... => x. Fails for qualified assignments"
//  input Statement stmt;
//  output String name;
//algorithm
//  name := match stmt
//    case NFInstTypes.ASSIGN_STMT(lhs=DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name))) then name;
//    case NFInstTypes.FUNCTION_ARRAY_INIT(name=name) then name;
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,{"NFInst.getInitStatementName failed"});
//      then fail();
//  end match;
//end getInitStatementName;
//
//protected function getStatementDependencies
//  "Returns the dependencies given an element.
//  Assumes reduction/loop indexes/etc have been replaced by unique indices."
//  input Statement inStmt;
//  input tuple<list<Statement>,list<String>> inAllElements;
//  output list<Statement> outDependencies;
//algorithm
//  outDependencies := match (inStmt, inAllElements)
//    local
//      DAE.Exp exp;
//      list<String> deps,allPossible;
//      list<Statement> allStatements;
//      SourceInfo info;
//      String name;
//      list<DAE.Dimension> dims;
//      list<DAE.Exp> exps;
//
//    case (NFInstTypes.ASSIGN_STMT(lhs=DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name)),rhs=exp,info=info), (allStatements,allPossible))
//      equation
//        (_, deps) = Expression.traverseExp(exp,getExpDependencies,{});
//        Error.assertionOrAddSourceMessage(not listMember(name,deps),Error.INTERNAL_ERROR,{"getStatementDependencies: self-dependence in deps"},info);
//        deps = List.intersectionOnTrue(allPossible,deps,stringEq);
//      then // O(n^2), but function init-bindings are usually too small to warrant a hashtable
//        List.select2(allStatements,selectStatement,deps,SOME(name));
//    case (NFInstTypes.FUNCTION_ARRAY_INIT(name,DAE.T_ARRAY(dims=dims),info), (allStatements,allPossible))
//      equation
//        exps = Expression.dimensionsToExps(dims,{});
//        (_, deps) = Expression.traverseExp(DAE.LIST(exps),getExpDependencies,{});
//        Error.assertionOrAddSourceMessage(not listMember(name,deps),Error.INTERNAL_ERROR,{"getStatementDependencies: self-dependence in deps"},info);
//        deps = List.intersectionOnTrue(allPossible,deps,stringEq);
//      then // O(n^2), but function init-bindings are usually too small to warrant a hashtable
//        List.select2(allStatements,selectStatement,deps,NONE());
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,{"NFInst.getStatementDependencies failed"});
//      then fail();
//  end match;
//end getStatementDependencies;
//
//protected function selectStatement
//  input Statement stmt;
//  input list<String> deps;
//  input Option<String> oname "If this is SOME(name), return true only if the statement is an array allocation.";
//  output Boolean select;
//protected
//  String name;
//algorithm
//  name := getInitStatementName(stmt);
//  select := listMember(name,deps) or (NFInstUtil.isArrayAllocation(stmt) and stringEq(name,Util.getOptionOrDefault(oname,"")));
//end selectStatement;
//
//protected function getExpDependencies
//  input DAE.Exp inExp;
//  input list<String> inLst;
//  output DAE.Exp exp;
//  output list<String> lst;
//algorithm
//  (exp,lst) := match (inExp,inLst)
//    local
//      String name;
//    case (exp as DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name)),lst) then (exp,name::lst);
//    case (exp as DAE.CREF(componentRef=DAE.CREF_QUAL(ident=name)),lst) then (exp,name::lst);
//    else (inExp,inLst);
//  end match;
//end getExpDependencies;
//
//protected function stripInitBinding
//  input Element inElt;
//  input list<Statement> inBindings;
//  output Element outElt;
//  output list<Statement> outBindings;
//algorithm
//  (outElt,outBindings) := match (inElt,inBindings)
//    local
//      SourceInfo info,bindingInfo;
//      String name;
//      Class cls;
//      DAE.Type baseType;
//      array<Dimension> dimensions;
//      Prefixes prefixes;
//      ParamType paramType;
//      DAE.Exp bindingExp;
//      Component comp;
//      Element elt;
//
//    case (NFInstTypes.ELEMENT(NFInstTypes.UNTYPED_COMPONENT(Absyn.IDENT(name),baseType,dimensions,prefixes,paramType,NFInstTypes.UNTYPED_BINDING(bindingExp=bindingExp,info=bindingInfo),info),cls),_)
//      equation
//        comp = NFInstTypes.UNTYPED_COMPONENT(Absyn.IDENT(name),baseType,dimensions,prefixes,paramType,NFInstTypes.UNBOUND(),info);
//        elt = NFInstTypes.ELEMENT(comp,cls);
//      then (elt,NFInstTypes.ASSIGN_STMT(DAE.CREF(DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {}),DAE.T_UNKNOWN_DEFAULT),bindingExp,bindingInfo)::inBindings);
//    else (inElt,inBindings);
//  end match;
//end stripInitBinding;
//
//protected function dimensionDeps
//  input Element inElt;
//  input list<Statement> inBindings;
//  output Element outElt;
//  output list<Statement> outBindings;
//algorithm
//  (outElt,outBindings) := match (inElt,inBindings)
//    local
//      SourceInfo info;
//      String name;
//      Class cls;
//      array<Dimension> dimensions;
//      list<DAE.Dimension> dims;
//      Element elt;
//      list<Statement> bindings;
//
//    case (elt as NFInstTypes.ELEMENT(NFInstTypes.UNTYPED_COMPONENT(name=Absyn.IDENT(name),dimensions=dimensions,info=info),_),_)
//      equation
//        dims = List.map(arrayList(dimensions),NFInstUtil.unwrapDimension);
//        bindings = if arrayLength(dimensions)>0
//          then NFInstTypes.FUNCTION_ARRAY_INIT(name, DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT,dims,DAE.emptyTypeSource), info)::inBindings
//          else inBindings;
//      then (elt,bindings);
//    else (inElt,inBindings);
//  end match;
//end dimensionDeps;
//
//protected function instNamedArg
//  input Absyn.NamedArg inNamedArg;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output tuple<String, DAE.Exp> outNamedArg;
//  output Globals outGlobals;
//protected
//  String name;
//  Absyn.Exp aexp;
//  DAE.Exp dexp;
//algorithm
//  Absyn.NAMEDARG(argName = name, argValue = aexp) := inNamedArg;
//  (dexp,outGlobals) := instExp(aexp, inEnv, inInfo, inGlobals);
//  outNamedArg := (name, dexp);
//end instNamedArg;
//
//protected function getFunctionParameters
//  input Class inClass;
//  output list<Element> outInputs;
//  output list<Element> outOutputs;
//  output list<Element> outLocals;
//algorithm
//  (outInputs, outOutputs, outLocals) := matchcontinue(inClass)
//    local
//      list<Element> comps, inputs, outputs, locals;
//      Absyn.Path name;
//
//    case NFInstTypes.COMPLEX_CLASS(components = comps)
//      equation
//        (inputs, outputs, locals) = getFunctionParameters2(comps, {}, {}, {});
//      then
//        (inputs, outputs, locals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        name = NFInstUtil.getClassName(inClass);
//        Debug.traceln("- NFInst.getFunctionParameters failed for: " + Absyn.pathString(name) + ".\n" +
//        NFInstDump.modelStr(Absyn.pathString(name), inClass) + "\n");
//      then
//        fail();
//
//  end matchcontinue;
//end getFunctionParameters;
//
//protected function getFunctionParameters2
//  input list<Element> inElements;
//  input list<Element> inAccumInputs;
//  input list<Element> inAccumOutputs;
//  input list<Element> inAccumLocals;
//  output list<Element> outInputs;
//  output list<Element> outOutputs;
//  output list<Element> outLocals;
//algorithm
//  (outInputs, outOutputs, outLocals) := match(inElements, inAccumInputs, inAccumOutputs, inAccumLocals)
//    local
//      Prefixes prefs;
//      Absyn.Path name;
//      DAE.Type ty;
//      SourceInfo info;
//      Element el;
//      list<Element> rest_el;
//      list<Element> inputs, outputs, locals;
//
//    case ((el as NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(
//        name = name, baseType = ty, prefixes = prefs, info = info))) :: rest_el,
//        inputs, outputs, locals)
//      equation
//        validateFunctionVariable(name, ty, prefs, info);
//        (inputs, outputs, locals) =
//          getFunctionParameters3(name, prefs, info, el, inputs, outputs, locals);
//        (inputs, outputs, locals) = getFunctionParameters2(rest_el, inputs, outputs, locals);
//      then
//        (inputs, outputs, locals);
//
//    // Ignore any elements which are not untyped components.
//    case (_ :: rest_el, inputs, outputs, locals)
//      equation
//        (inputs, outputs, locals) = getFunctionParameters2(rest_el, inputs, outputs, locals);
//      then
//        (inputs, outputs, locals);
//
//    case ({}, _, _, _)
//      then (listReverse(inAccumInputs), listReverse(inAccumOutputs), listReverse(inAccumLocals));
//
//  end match;
//end getFunctionParameters2;
//
//protected function getFunctionParameters3
//  input Absyn.Path inName;
//  input Prefixes inPrefixes;
//  input SourceInfo inInfo;
//  input Element inElement;
//  input list<Element> inAccumInputs;
//  input list<Element> inAccumOutputs;
//  input list<Element> inAccumLocals;
//  output list<Element> outInputs;
//  output list<Element> outOutputs;
//  output list<Element> outLocals;
//algorithm
//  (outInputs, outOutputs, outLocals) := match(inName, inPrefixes, inInfo, inElement,
//      inAccumInputs, inAccumOutputs, inAccumLocals)
//
//    case (_, NFInstTypes.PREFIXES(direction = (Absyn.INPUT(), _)), _, _, _, _, _)
//      equation
//        validateFormalParameter(inName, inPrefixes, inInfo);
//      then
//        (inElement :: inAccumInputs, inAccumOutputs, inAccumLocals);
//
//    case (_, NFInstTypes.PREFIXES(direction = (Absyn.OUTPUT(), _)), _, _, _, _, _)
//      equation
//        validateFormalParameter(inName, inPrefixes, inInfo);
//      then
//        (inAccumInputs, inElement :: inAccumOutputs, inAccumLocals);
//
//    else
//      equation
//        validateLocalFunctionVariable(inName, inPrefixes, inInfo);
//      then
//        (inAccumInputs, inAccumOutputs, inElement :: inAccumLocals);
//
//  end match;
//end getFunctionParameters3;
//
//protected function validateFunctionVariable
//  input Absyn.Path inName;
//  input DAE.Type inType;
//  input Prefixes inPrefixes;
//  input SourceInfo inInfo;
//algorithm
//  _ := matchcontinue(inName, inType, inPrefixes, inInfo)
//    local
//      String name, ty_str, io_str;
//      Absyn.InnerOuter io;
//
//    case (_, _, NFInstTypes.PREFIXES(innerOuter = Absyn.NOT_INNER_OUTER()), _)
//      equation
//        true = Types.isValidFunctionVarType(inType);
//      then ();
//
//    case (_, _, _, _)
//      equation
//        false = Types.isValidFunctionVarType(inType);
//        name = Absyn.pathString(inName);
//        ty_str = Types.getTypeName(inType);
//        Error.addSourceMessage(Error.INVALID_FUNCTION_VAR_TYPE,
//          {ty_str, name}, inInfo);
//      then
//        fail();
//
//    // A formal parameter may not have an inner/outer prefix.
//    case (_, _, NFInstTypes.PREFIXES(innerOuter = io), _)
//      equation
//        false = Absyn.isNotInnerOuter(io);
//        name = Absyn.pathString(inName);
//        io_str = Dump.unparseInnerouterStr(io);
//        Error.addSourceMessage(Error.INNER_OUTER_FORMAL_PARAMETER,
//          {io_str, name}, inInfo);
//      then
//        fail();
//
//  end matchcontinue;
//end validateFunctionVariable;
//
//protected function validateFormalParameter
//  input Absyn.Path inName;
//  input Prefixes inPrefixes;
//  input SourceInfo inInfo;
//algorithm
//  _ := matchcontinue(inName, inPrefixes, inInfo)
//    local
//      String name;
//
//    // A formal parameter must be public.
//    case (_, NFInstTypes.PREFIXES(visibility = SCode.PROTECTED()), _)
//      equation
//        name = Absyn.pathString(inName);
//        Error.addSourceMessage(Error.PROTECTED_FORMAL_FUNCTION_VAR,
//          {name}, inInfo);
//      then
//        fail();
//
//    else ();
//
//  end matchcontinue;
//end validateFormalParameter;
//
//protected function validateLocalFunctionVariable
//  input Absyn.Path inName;
//  input Prefixes inPrefixes;
//  input SourceInfo inInfo;
//algorithm
//  _ := match(inName, inPrefixes, inInfo)
//    local
//      String name;
//
//    // A local function variable must be protected.
//    case (_, NFInstTypes.PREFIXES(visibility = SCode.PUBLIC()), _)
//      equation
//        name = Absyn.pathString(inName);
//        Error.addSourceMessage(Error.NON_FORMAL_PUBLIC_FUNCTION_VAR, {name}, inInfo);
//      then
//        fail();
//
//    else ();
//
//  end match;
//end validateLocalFunctionVariable;
//
//protected function fillFunctionSlots
//  input list<DAE.Exp> inPositionalArgs;
//  input list<tuple<String, DAE.Exp>> inNamedArgs;
//  input list<Element> inInputs;
//  input Absyn.Path inFuncName;
//  input SourceInfo inInfo;
//  output list<DAE.Exp> outArgs;
//protected
//  list<FunctionSlot> slots;
//algorithm
//  //print(Error.infoStr(inInfo) + " Function: " + Absyn.pathString(inFuncName) + ":\n");
//  //print(Util.stringDelimitListNonEmptyElts(List.map(inInputs, NFInstUtil.printElement), "\n\t") + "\n");
//  slots := makeFunctionSlots(inInputs, inPositionalArgs, {}, inFuncName, inInfo);
//  slots := List.fold(inNamedArgs, fillFunctionSlot, slots);
//  outArgs := List.map(slots, extractFunctionSlotExp);
//end fillFunctionSlots;
//
//protected function makeFunctionSlots
//  input list<Element> inInputs;
//  input list<DAE.Exp> inPositionalArgs;
//  input list<FunctionSlot> inAccumSlots;
//  input Absyn.Path inFuncName;
//  input SourceInfo inInfo;
//  output list<FunctionSlot> outSlots;
//algorithm
//  outSlots := match(inInputs, inPositionalArgs, inAccumSlots, inFuncName, inInfo)
//    local
//      String param_name, name;
//      Binding binding;
//      list<Element> rest_inputs;
//      Option<DAE.Exp> arg, default_value;
//      list<DAE.Exp> rest_args;
//      list<FunctionSlot> slots;
//
//    // ignore cond components
//    case (NFInstTypes.CONDITIONAL_ELEMENT() :: rest_inputs, _, slots, _, _)
//      then
//        makeFunctionSlots(rest_inputs, inPositionalArgs, slots, inFuncName, inInfo);
//
//    // Last vararg input and no positional arguments means we're done.
//    case ({NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(prefixes =
//        NFInstTypes.PREFIXES(varArgs = NFInstTypes.IS_VARARG())))}, {}, _, _, _)
//      then listReverse(inAccumSlots);
//
//    // If the last input of the function is a vararg, handle it first
//    case (rest_inputs as (NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(name =
//        Absyn.IDENT(param_name), binding = binding, prefixes = NFInstTypes.PREFIXES(varArgs =
//        NFInstTypes.IS_VARARG()))) :: {}),  _::_, slots, _, _)
//      equation
//        (arg, rest_args) = List.splitFirstOption(inPositionalArgs);
//        default_value = NFInstUtil.getBindingExpOpt(binding);
//        slots = NFInstTypes.SLOT(param_name, arg, default_value) :: slots;
//      then
//        makeFunctionSlots(rest_inputs, rest_args, slots, inFuncName, inInfo);
//
//    case (NFInstTypes.ELEMENT(component = NFInstTypes.UNTYPED_COMPONENT(name =
//        Absyn.IDENT(param_name), binding = binding)) :: rest_inputs, _, slots, _, _)
//      equation
//        (arg, rest_args) = List.splitFirstOption(inPositionalArgs);
//        default_value = NFInstUtil.getBindingExpOpt(binding);
//        slots = NFInstTypes.SLOT(param_name, arg, default_value) :: slots;
//      then
//        makeFunctionSlots(rest_inputs, rest_args, slots, inFuncName, inInfo);
//
//    // No more inputs and positional arguments means we're done.
//    case ({}, {}, _, _, _) then listReverse(inAccumSlots);
//
//    // No more inputs but positional arguments left is an error.
//    case ({}, _ :: _, _, _, _)
//      equation
//        // TODO: Make this a proper error message.
//        print(Error.infoStr(inInfo) + ": ");
//        name = Absyn.pathString(inFuncName);
//        print("NFInst.makeFunctionSlots: Too many arguments to function " +
//          name + "\n");
//      then
//        fail();
//
//  end match;
//end makeFunctionSlots;
//
//protected function fillFunctionSlot
//  input tuple<String, DAE.Exp> inNamedArg;
//  input list<FunctionSlot> inSlots;
//  output list<FunctionSlot> outSlots;
//algorithm
//  outSlots := match(inNamedArg, inSlots)
//    local
//      String arg_name, slot_name;
//      FunctionSlot slot;
//      list<FunctionSlot> rest_slots;
//      Boolean eq;
//
//      case ((arg_name, _), (slot as NFInstTypes.SLOT(name = slot_name)) :: rest_slots)
//        equation
//          eq = stringEq(arg_name, slot_name);
//        then
//          fillFunctionSlot2(eq, inNamedArg, slot, rest_slots);
//
//      case ((arg_name, _), {})
//        equation
//          print("No matching slot " + arg_name + "\n");
//        then
//          fail();
//
//  end match;
//end fillFunctionSlot;
//
//protected function fillFunctionSlot2
//  input Boolean inMatching;
//  input tuple<String, DAE.Exp> inNamedArg;
//  input FunctionSlot inSlot;
//  input list<FunctionSlot> inRestSlots;
//  output list<FunctionSlot> outSlots;
//algorithm
//  outSlots := match(inMatching, inNamedArg, inSlot, inRestSlots)
//    local
//      String name;
//      DAE.Exp arg;
//      FunctionSlot slot;
//      list<FunctionSlot> slots;
//
//    // Found a matching empty slot, fill it.
//    case (true, (_, arg), NFInstTypes.SLOT(name = name, arg = NONE()), _)
//      equation
//        slot = NFInstTypes.SLOT(name, SOME(arg), NONE());
//      then
//        slot :: inRestSlots;
//
//    // Slot not matching, search through the rest of the slots.
//    case (false, _, _, _)
//      equation
//        slots = fillFunctionSlot(inNamedArg, inRestSlots);
//      then
//        inSlot :: slots;
//
//    // Found a matching slot that is already filled, show error.
//    case (true, _, NFInstTypes.SLOT(name = name, arg = SOME(arg)), _)
//      equation
//        print("Slot " + name + " is already filled with: " + ExpressionDump.printExpStr(arg) + "\n");
//      then
//        fail();
//
//  end match;
//end fillFunctionSlot2;
//
//protected function extractFunctionSlotExp
//  input FunctionSlot inSlot;
//  output DAE.Exp outExp;
//algorithm
//  outExp := match(inSlot)
//    local
//      DAE.Exp exp;
//      String name;
//
//    case NFInstTypes.SLOT(arg = SOME(exp)) then exp;
//    case NFInstTypes.SLOT(defaultValue = SOME(exp)) then exp;
//    case NFInstTypes.SLOT(name = name)
//      equation
//        print("Slot " + name + " has no value.\n");
//      then
//        fail();
//
//  end match;
//end extractFunctionSlotExp;
//
//protected function assignParamTypes
//  input Class inClass;
//  input SymbolTable inSymbolTable;
//  output Class outClass;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outClass, outSymbolTable) :=
//    NFInstUtil.traverseClassComponents(inClass, inSymbolTable, assignParamTypesToComp);
//end assignParamTypes;
//
//protected function assignParamTypesToComp
//  input Component inComponent;
//  input SymbolTable inSymbolTable;
//  output Component outComponent;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outComponent, outSymbolTable) := match(inComponent, inSymbolTable)
//    local
//      array<Dimension> dims;
//      DAE.Exp cond;
//      SymbolTable st;
//
//    case (NFInstTypes.UNTYPED_COMPONENT(dimensions = dims), st)
//      equation
//        st = Array.fold(dims, assignParamTypesToDim, st);
//      then
//        (inComponent, st);
//
//    case (NFInstTypes.CONDITIONAL_COMPONENT(condition = cond), st)
//      equation
//        st = markExpAsStructural(cond, st);
//      then
//        (inComponent, st);
//
//    else (inComponent, inSymbolTable);
//
//  end match;
//end assignParamTypesToComp;
//
//protected function assignParamTypesToDim
//  input Dimension inDimension;
//  input SymbolTable inSymbolTable;
//  output SymbolTable outSymbolTable;
//algorithm
//  outSymbolTable := match(inDimension, inSymbolTable)
//    local
//      DAE.Exp dim_exp;
//      SymbolTable st;
//
//    case (NFInstTypes.UNTYPED_DIMENSION(dimension = DAE.DIM_EXP(exp = dim_exp)), st)
//      equation
//        (_, st) = Expression.traverseExpTopDown(dim_exp, markDimExpAsStructuralTraverser, st);
//      then st;
//
//    else inSymbolTable;
//
//  end match;
//end assignParamTypesToDim;
//
//protected function markDimExpAsStructuralTraverser
//  input DAE.Exp exp;
//  input SymbolTable inSt;
//  output DAE.Exp outExp;
//  output Boolean cont;
//  output SymbolTable st;
//algorithm
//  (outExp,cont,st) := match (exp,inSt)
//    local
//      DAE.Exp index_exp;
//      DAE.ComponentRef cref;
//
//    case (DAE.CREF(componentRef = cref), st)
//      equation
//        st = markParamAsStructural(cref, st);
//        // TODO: Mark cref subscripts too.
//      then (exp, true, st);
//
//    case (DAE.SIZE(sz = SOME(index_exp)), st)
//      equation
//        st = markExpAsStructural(index_exp, st);
//      then (exp, false, st);
//
//    else (exp, true, inSt);
//
//  end match;
//end markDimExpAsStructuralTraverser;
//
//protected function markExpAsStructural
//  input DAE.Exp inExp;
//  input SymbolTable inSymbolTable;
//  output SymbolTable outSymbolTable;
//algorithm
//  (_, outSymbolTable) := Expression.traverseExp(inExp, markExpAsStructuralTraverser, inSymbolTable);
//end markExpAsStructural;
//
//protected function markExpAsStructuralTraverser
//  input DAE.Exp inExp;
//  input SymbolTable inSt;
//  output DAE.Exp exp;
//  output SymbolTable st;
//algorithm
//  (exp,st) := match (inExp,inSt)
//    local
//      DAE.ComponentRef cref;
//
//    case (DAE.CREF(componentRef = cref), st)
//      equation
//        st = markParamAsStructural(cref, st);
//      then (inExp, st);
//
//    else (inExp,inSt);
//
//  end match;
//end markExpAsStructuralTraverser;
//
//protected function markParamAsStructural
//  input DAE.ComponentRef inCref;
//  input SymbolTable inSymbolTable;
//  output SymbolTable outSymbolTable;
//algorithm
//  outSymbolTable := matchcontinue(inCref, inSymbolTable)
//    local
//      SymbolTable st;
//      Component comp;
//
//    case (_, st)
//      equation
//        (comp, st) = NFInstSymbolTable.lookupCrefResolveOuter(inCref, st);
//        st = markComponentAsStructural(comp, st);
//      then
//        st;
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFInst.markParamAsStructural failed on " +
//          ComponentReference.printComponentRefStr(inCref) + "\n");
//      then
//        fail();
//
//  end matchcontinue;
//end markParamAsStructural;
//
//protected function markComponentAsStructural
//  input Component inComponent;
//  input SymbolTable inSymbolTable;
//  output SymbolTable outSymbolTable;
//algorithm
//  outSymbolTable := match(inComponent, inSymbolTable)
//    local
//      Absyn.Path name;
//      DAE.Type ty;
//      array<Dimension> dims;
//      Prefixes prefs;
//      Binding binding;
//      SourceInfo info;
//      SymbolTable st;
//      Component comp;
//
//    // Already marked as structural.
//    case (NFInstTypes.UNTYPED_COMPONENT(paramType = NFInstTypes.STRUCT_PARAM()), _)
//      then inSymbolTable;
//
//    case (NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs, _, binding, info), st)
//      equation
//        st = markBindingAsStructural(binding, st);
//        comp = NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs,
//          NFInstTypes.STRUCT_PARAM(), binding, info);
//        st = NFInstSymbolTable.updateComponent(comp, st);
//      then
//        st;
//
//    case (NFInstTypes.OUTER_COMPONENT(), _)
//      equation
//        print("NFInst.markComponentAsStructural: IMPLEMENT ME!\n");
//      then
//        fail();
//
//    case (NFInstTypes.CONDITIONAL_COMPONENT(), _)
//      equation
//        print("NFInst.markComponentAsStructural: conditional component used as structural parameter!\n");
//      then
//        fail();
//
//    else inSymbolTable;
//  end match;
//end markComponentAsStructural;
//
//protected function markBindingAsStructural
//  input Binding inBinding;
//  input SymbolTable inSymbolTable;
//  output SymbolTable outSymbolTable;
//algorithm
//  outSymbolTable := match(inBinding, inSymbolTable)
//    local
//      DAE.Exp bind_exp;
//
//    case (NFInstTypes.UNTYPED_BINDING(bindingExp = bind_exp), _)
//      then markExpAsStructural(bind_exp, inSymbolTable);
//
//    else inSymbolTable;
//
//  end match;
//end markBindingAsStructural;
//
//protected function instSections
//  input SCode.ClassDef inClassDef;
//  input Env inEnv;
//  input Globals inGlobals;
//  output list<Equation> outEquations;
//  output list<Equation> outInitialEquations;
//  output list<list<Statement>> outStatements;
//  output list<list<Statement>> outInitialStatements;
//  output Globals outGlobals;
//algorithm
//  (outEquations, outInitialEquations, outStatements, outInitialStatements, outGlobals) :=
//  match(inClassDef, inEnv, inGlobals)
//    local
//      list<SCode.Equation> snel, siel;
//      list<SCode.AlgorithmSection> snal, sial;
//      list<Equation> inel, iiel;
//      list<list<Statement>> inal, iial;
//      Globals globals;
//
//    case (SCode.PARTS(normalEquationLst = snel, initialEquationLst = siel,
//                      normalAlgorithmLst = snal, initialAlgorithmLst = sial), _, globals)
//      equation
//        (inel, globals) = instEquations(snel, inEnv, globals);
//        (iiel, globals) = instEquations(siel, inEnv, globals);
//        (inal, globals) = instAlgorithmSections(snal, inEnv, globals);
//        (iial, globals) = instAlgorithmSections(sial, inEnv, globals);
//      then
//        (inel, iiel, inal, iial, globals);
//
//  end match;
//end instSections;
//
//protected function instEquations
//  input list<SCode.Equation> inEquations;
//  input Env inEnv;
//  input Globals inGlobals;
//  output list<Equation> outEquations;
//  output Globals outGlobals;
//algorithm
//  (outEquations,outGlobals) := List.map1Fold(inEquations, instEquation, inEnv, inGlobals);
//end instEquations;
//
//protected function instEquation
//  input SCode.Equation inEquation;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Equation outEquation;
//  output Globals outGlobals;
//protected
//  SCode.EEquation eq;
//algorithm
//  SCode.EQUATION(eEquation = eq) := inEquation;
//  (outEquation,outGlobals) := instEEquation(eq, inEnv, inGlobals);
//end instEquation;
//
//protected function instEEquations
//  input list<SCode.EEquation> inEquations;
//  input Env inEnv;
//  input Globals inGlobals;
//  output list<Equation> outEquations;
//  output Globals outGlobals;
//algorithm
//  (outEquations,outGlobals) := List.map1Fold(inEquations, instEEquation, inEnv, inGlobals);
//end instEEquations;
//
//protected function instEEquation
//  input SCode.EEquation inEquation;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Equation outEquation;
//  output Globals outGlobals;
//algorithm
//  (outEquation,outGlobals) := matchcontinue (inEquation, inEnv, inGlobals)
//    local
//      Absyn.Exp exp1, exp2, exp3;
//      DAE.Exp dexp1, dexp2, dexp3;
//      Absyn.ComponentRef cref1, cref2;
//      DAE.ComponentRef dcref1, dcref2;
//      SourceInfo info;
//      Integer index;
//      String for_index,str;
//      list<SCode.EEquation> eql;
//      list<Equation> ieql;
//      list<Absyn.Exp> if_condition;
//      list<list<SCode.EEquation>> if_branches;
//      list<tuple<DAE.Exp, list<Equation>>> inst_branches;
//      list<tuple<Absyn.Exp, list<SCode.EEquation>>> when_branches;
//      Env env;
//      Globals globals;
//      Prefix prefix;
//
//    case (SCode.EQ_EQUALS(exp1, exp2, _, info), _, globals)
//      equation
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//        (dexp2, globals) = instExp(exp2, inEnv, info, globals);
//      then
//        (NFInstTypes.EQUALITY_EQUATION(dexp1, dexp2, info), globals);
//
//    // To determine whether a connected component is inside or outside we need
//    // to know the type of the first identifier in the cref. Since it's illegal
//    // to connect to global constants we can just save the prefix until we do
//    // the typing, which means that we can then determine this with a hashtable
//    // lookup.
//    case (SCode.EQ_CONNECT(crefLeft = cref1, crefRight = cref2, info = info), _, globals)
//      equation
//        (dcref1, globals) = instCref2(cref1, inEnv, info, globals);
//        (dcref2, globals) = instCref2(cref2, inEnv, info, globals);
//        prefix = NFEnv.scopePrefix(inEnv);
//      then
//        (NFInstTypes.CONNECT_EQUATION(dcref1, NFConnect2.NO_FACE(), DAE.T_UNKNOWN_DEFAULT,
//          dcref2, NFConnect2.NO_FACE(), DAE.T_UNKNOWN_DEFAULT, prefix, info), globals);
//
//    case (SCode.EQ_FOR(index = for_index, range = SOME(exp1), eEquationLst = eql,
//        info = info), _, globals)
//      equation
//        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
//        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
//        (dexp1, globals) = instExp(exp1, env, info, globals);
//        (ieql, globals) = instEEquations(eql, env, globals);
//      then
//        (NFInstTypes.FOR_EQUATION(for_index, index, DAE.T_UNKNOWN_DEFAULT, SOME(dexp1), ieql, info), globals);
//
//    case (SCode.EQ_FOR(index = for_index, range = NONE(), eEquationLst = eql,
//        info = info), _, globals)
//      equation
//        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
//        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
//        (ieql, globals) = instEEquations(eql, env, globals);
//      then
//        (NFInstTypes.FOR_EQUATION(for_index, index, DAE.T_UNKNOWN_DEFAULT, NONE(), ieql, info), globals);
//
//    case (SCode.EQ_IF(condition = if_condition, thenBranch = if_branches,
//        elseBranch = eql, info = info), _, globals)
//      equation
//        (inst_branches, globals) = List.threadMap2ReverseFold(if_condition, if_branches, instIfBranch, inEnv, info, globals);
//        (ieql, globals) = instEEquations(eql, inEnv, globals);
//        // Add else branch as a branch with condition true last in the list.
//        inst_branches = listReverse((DAE.BCONST(true), ieql) :: inst_branches);
//      then
//        (NFInstTypes.IF_EQUATION(inst_branches, info), globals);
//
//    case (SCode.EQ_WHEN(condition = exp1, eEquationLst = eql,
//        elseBranches = when_branches, info = info), _, globals)
//      equation
//        (_, globals) = instExp(exp1, inEnv, info, globals);
//        (ieql, globals) = instEEquations(eql, inEnv, globals);
//        (inst_branches, globals) = List.map2Fold(when_branches, instWhenBranch, inEnv, info, globals);
//        // Add else branch as a branch with condition true last in the list.
//        inst_branches = listReverse((DAE.BCONST(true), ieql) :: inst_branches);
//      then
//        (NFInstTypes.WHEN_EQUATION(inst_branches, info), globals);
//
//    case (SCode.EQ_ASSERT(condition = exp1, message = exp2, level = exp3, info = info), _, globals)
//      equation
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//        (dexp2, globals) = instExp(exp2, inEnv, info, globals);
//        (dexp3, globals) = instExp(exp3, inEnv, info, globals);
//      then
//        (NFInstTypes.ASSERT_EQUATION(dexp1, dexp2, dexp3, info), globals);
//
//    case (SCode.EQ_TERMINATE(message = exp1, info = info), _, globals)
//      equation
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//      then
//        (NFInstTypes.TERMINATE_EQUATION(dexp1, info), globals);
//
//    case (SCode.EQ_REINIT(cref = cref1, expReinit = exp1, info = info), _, globals)
//      equation
//        (dcref1, globals) = instCref(cref1, inEnv, info, globals);
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//      then
//        (NFInstTypes.REINIT_EQUATION(dcref1, dexp1, info), globals);
//
//    case (SCode.EQ_NORETCALL(exp = exp1, info = info), _, globals)
//      equation
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//      then
//        (NFInstTypes.NORETCALL_EQUATION(dexp1, info), globals);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        str = SCodeDump.equationStr(inEquation,SCodeDump.defaultOptions);
//        Debug.traceln("Unknown or failed equation in NFInst.instEEquation: " + str);
//      then
//        fail();
//
//  end matchcontinue;
//end instEEquation;
//
//protected function instAlgorithmSections
//  input list<SCode.AlgorithmSection> inSections;
//  input Env inEnv;
//  input Globals inGlobals;
//  output list<list<Statement>> outStatements;
//  output Globals outGlobals;
//algorithm
//  (outStatements,outGlobals) := List.map1Fold(inSections, instAlgorithmSection, inEnv, inGlobals);
//end instAlgorithmSections;
//
//protected function instAlgorithmSection
//  input SCode.AlgorithmSection inSection;
//  input Env inEnv;
//  input Globals inGlobals;
//  output list<Statement> outStatements;
//  output Globals outGlobals;
//protected
//  list<SCode.Statement> sstatements;
//algorithm
//  SCode.ALGORITHM(statements=sstatements) := inSection;
//  (outStatements,outGlobals) := List.map1Fold(sstatements, instStatement, inEnv, inGlobals);
//end instAlgorithmSection;
//
//protected function instStatements
//  input list<SCode.Statement> sstatements;
//  input Env inEnv;
//  input Globals inGlobals;
//  output list<Statement> outStatements;
//  output Globals outGlobals;
//algorithm
//  (outStatements,outGlobals) := List.map1Fold(sstatements, instStatement, inEnv, inGlobals);
//end instStatements;
//
//protected function instStatement
//  input SCode.Statement statement;
//  input Env inEnv;
//  input Globals inGlobals;
//  output Statement outStatement;
//  output Globals outGlobals;
//algorithm
//  (outStatement, outGlobals) := match(statement, inEnv, inGlobals)
//    local
//      Absyn.Exp exp1, exp2, if_condition;
//      SourceInfo info;
//      DAE.Exp dexp1, dexp2;
//      Env env;
//      list<SCode.Statement> if_branch, else_branch, body;
//      list<tuple<Absyn.Exp, list<SCode.Statement>>> elseif_branches, branches;
//      list<tuple<DAE.Exp, list<Statement>>> inst_branches;
//      list<Statement> ibody;
//      String for_index;
//      Integer index;
//      Globals globals;
//
//    case (SCode.ALG_ASSIGN(exp1, exp2, _, info), _, globals)
//      equation
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//        (dexp2, globals) = instExp(exp2, inEnv, info, globals);
//      then (NFInstTypes.ASSIGN_STMT(dexp1, dexp2, info), globals);
//
//    case (SCode.ALG_FOR(index = for_index, range = SOME(exp1), forBody = body, info = info), _, globals)
//      equation
//        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
//        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
//        (dexp1, globals) = instExp(exp1, env, info, globals);
//        (ibody, globals) = instStatements(body, env, globals);
//      then
//        (NFInstTypes.FOR_STMT(for_index, index, DAE.T_UNKNOWN_DEFAULT, SOME(dexp1), ibody, info), globals);
//
//    case (SCode.ALG_FOR(index = for_index, range = NONE(), forBody = body, info = info), _, globals)
//      equation
//        index = System.tmpTickIndex(NFEnv.tmpTickIndex);
//        env = NFEnv.insertIterators({Absyn.ITERATOR(for_index, NONE(), NONE())}, index, inEnv);
//        (ibody, globals) = instStatements(body, env, globals);
//      then
//        (NFInstTypes.FOR_STMT(for_index, index, DAE.T_UNKNOWN_DEFAULT, NONE(), ibody, info), globals);
//
//    case (SCode.ALG_WHILE(boolExpr = exp1, whileBody = body, info = info), _, globals)
//      equation
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//        (ibody, globals) = instStatements(body, inEnv, globals);
//      then
//        (NFInstTypes.WHILE_STMT(dexp1, ibody, info), globals);
//
//    case (SCode.ALG_IF(boolExpr = if_condition, trueBranch = if_branch,
//        elseIfBranch = elseif_branches,
//        elseBranch = else_branch, info = info), _, globals)
//      equation
//        elseif_branches = (if_condition,if_branch) :: elseif_branches;
//        /* Save some memory by making this more complicated than it is */
//        (inst_branches, globals) = List.map2Fold(elseif_branches, instStatementBranch, inEnv, info, globals, {});
//        (inst_branches, globals) = List.map2Fold({(Absyn.BOOL(true), else_branch)}, instStatementBranch, inEnv, info, globals, inst_branches);
//        inst_branches = listReverse(inst_branches);
//      then
//        (NFInstTypes.IF_STMT(inst_branches, info), globals);
//
//    case (SCode.ALG_WHEN_A(branches = branches, info = info), _, globals)
//      equation
//        (inst_branches, globals) = List.map2Fold(branches, instStatementBranch, inEnv, info, globals);
//      then
//        (NFInstTypes.WHEN_STMT(inst_branches, info), globals);
//
//    case (SCode.ALG_NORETCALL(exp = exp1, info = info), _, globals)
//      equation
//        (dexp1, globals) = instExp(exp1, inEnv, info, globals);
//      then (NFInstTypes.NORETCALL_STMT(dexp1, info), globals);
//
//    case (SCode.ALG_RETURN(info = info), _, globals)
//      then (NFInstTypes.RETURN_STMT(info), globals);
//
//    case (SCode.ALG_BREAK(info = info), _, globals)
//      then (NFInstTypes.BREAK_STMT(info), globals);
//
//    else
//      equation
//        print("NFInst.instStatement failed: " + SCodeDump.statementStr(statement,SCodeDump.defaultOptions) + "\n");
//      then fail();
//
//  end match;
//end instStatement;
//
//protected function instIfBranch
//  input Absyn.Exp inCondition;
//  input list<SCode.EEquation> inBody;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output tuple<DAE.Exp, list<Equation>> outIfBranch;
//  output Globals outGlobals;
//protected
//  DAE.Exp cond_exp;
//  list<Equation> eql;
//algorithm
//  (cond_exp,outGlobals) := instExp(inCondition, inEnv, inInfo, inGlobals);
//  (eql,outGlobals) := instEEquations(inBody, inEnv, outGlobals);
//  outIfBranch := (cond_exp, eql);
//end instIfBranch;
//
//protected function instStatementBranch
//  input tuple<Absyn.Exp,list<SCode.Statement>> tpl;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output tuple<DAE.Exp, list<Statement>> outIfBranch;
//  output Globals outGlobals;
//protected
//  Absyn.Exp cond;
//  DAE.Exp icond;
//  list<SCode.Statement> stmts;
//  list<Statement> istmts;
//algorithm
//  (cond,stmts) := tpl;
//  (icond,outGlobals) := instExp(cond, inEnv, inInfo, inGlobals);
//  (istmts,outGlobals) := instStatements(stmts, inEnv, outGlobals);
//  outIfBranch := (icond, istmts);
//end instStatementBranch;
//
//protected function instWhenBranch
//  input tuple<Absyn.Exp, list<SCode.EEquation>> inBranch;
//  input Env inEnv;
//  input SourceInfo inInfo;
//  input Globals inGlobals;
//  output tuple<DAE.Exp, list<Equation>> outBranch;
//  output Globals outGlobals;
//protected
//  Absyn.Exp aexp;
//  list<SCode.EEquation> eql;
//  DAE.Exp dexp;
//  list<Equation> ieql;
//algorithm
//  (aexp, eql) := inBranch;
//  (dexp, outGlobals) := instExp(aexp, inEnv, inInfo, inGlobals);
//  (ieql,outGlobals) := instEEquations(eql, inEnv, outGlobals);
//  outBranch := (dexp, ieql);
//end instWhenBranch;
//
////protected function instConditionalComponents
////  input Class inClass;
////  input SymbolTable inSymbolTable;
////  input Globals inGlobals;
////  output Class outClass;
////  output SymbolTable outSymbolTable;
////  output Globals outGlobals;
////algorithm
////  (outClass, outSymbolTable, outGlobals) := match(inClass, inSymbolTable, inGlobals)
////    local
////      SymbolTable st;
////      list<Element> comps;
////      list<Equation> eq, ieq;
////      list<list<Statement>> al, ial;
////      Globals globals;
////      Absyn.Path name;
////
////    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st, globals)
////      equation
////        (comps, st, globals) = instConditionalElements(comps, st, {}, globals);
////      then
////        (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st, globals);
////
////    else (inClass, inSymbolTable, inGlobals);
////
////  end match;
////end instConditionalComponents;
////
////protected function instConditionalElements
////  input list<Element> inElements;
////  input SymbolTable inSymbolTable;
////  input list<Element> inAccumEl;
////  input Globals inGlobals;
////  output list<Element> outElements;
////  output SymbolTable outSymbolTable;
////  output Globals outGlobals;
////algorithm
////  (outElements, outSymbolTable, outGlobals) := match(inElements, inSymbolTable, inAccumEl, inGlobals)
////    local
////      Element el;
////      list<Element> rest_el, accum_el;
////      SymbolTable st;
////      Option<Element> oel;
////      Globals globals;
////
////    case ({}, st, accum_el, globals) then (listReverse(accum_el), st, globals);
////
////    case (el :: rest_el, st, accum_el, globals)
////      equation
////        (oel, st, globals) = instConditionalElement(el, st, globals);
////        accum_el = List.consOption(oel, accum_el);
////        (accum_el, st, globals) = instConditionalElements(rest_el, st, accum_el, globals);
////      then
////        (accum_el, st, globals);
////
////  end match;
////end instConditionalElements;
////
////protected function instConditionalElementOnTrue
////  input Boolean inCondition;
////  input Element inElement;
////  input SymbolTable inSymbolTable;
////  input Globals inGlobals;
////  output Option<Element> outElement;
////  output SymbolTable outSymbolTable;
////  output Globals outGlobals;
////algorithm
////  (outElement, outSymbolTable, outGlobals) := match(inCondition, inElement, inSymbolTable, inGlobals)
////    local
////      Option<Element> oel;
////      SymbolTable st;
////      Globals globals;
////
////    case (true, _, st, globals)
////      equation
////        (oel, st, globals) = instConditionalElement(inElement, st, globals);
////      then
////        (oel, st, globals);
////
////    else (NONE(), inSymbolTable, inGlobals);
////
////  end match;
////end instConditionalElementOnTrue;
////
////protected function instConditionalElement
////  input Element inElement;
////  input SymbolTable inSymbolTable;
////  input Globals inGlobals;
////  output Option<Element> outElement;
////  output SymbolTable outSymbolTable;
////  output Globals outGlobals;
////algorithm
////  (outElement, outSymbolTable, outGlobals) := match(inElement, inSymbolTable, inGlobals)
////    local
////      Component comp;
////      Class cls;
////      SymbolTable st;
////      Element el;
////      Option<Element> oel;
////      Absyn.Path bc;
////      DAE.Type ty;
////      Globals globals;
////
////    case (NFInstTypes.ELEMENT(comp, cls), st, globals)
////      equation
////        (cls, st, globals) = instConditionalComponents(cls, st, globals);
////        el = NFInstTypes.ELEMENT(comp, cls);
////      then
////        (SOME(el), st, globals);
////
////    case (NFInstTypes.CONDITIONAL_ELEMENT(comp), st, globals)
////      equation
////        (oel, st, globals) = instConditionalComponent(comp, st, globals);
////      then
////        (oel, st, globals);
////
////    else (SOME(inElement), inSymbolTable, inGlobals);
////
////  end match;
////end instConditionalElement;
////
////protected function instConditionalComponent
////  input Component inComponent;
////  input SymbolTable inSymbolTable;
////  input Globals inGlobals;
////  output Option<Element> outElement;
////  output SymbolTable outSymbolTable;
////  output Globals outGlobals;
////algorithm
////  (outElement, outSymbolTable, outGlobals) := matchcontinue(inComponent, inSymbolTable, inGlobals)
////    local
////      SCode.Element sel;
////      Env env;
////      Prefix prefix;
////      SymbolTable st;
////      DAE.Exp cond_exp;
////      DAE.Type ty;
////      Condition cond;
////      SourceInfo info;
////      Absyn.Path name;
////      Modifier mod;
////      Option<Element> el;
////      Prefixes prefs;
////      Globals globals;
////
////    case (NFInstTypes.CONDITIONAL_COMPONENT(name, cond_exp, sel, mod, prefs, env,
////        prefix, info), st, globals)
////      equation
////        (cond_exp, ty, _, st) = NFTyping.typeExpEmptyFunctionTable(cond_exp, NFTyping.EVAL_CONST_PARAM(),
////          NFTyping.CONTEXT_MODEL(), st);
////        (cond_exp, _) = ExpressionSimplify.simplify(cond_exp);
////        cond = evaluateConditionalExp(cond_exp, ty, name, info);
////        (el, st, globals) = instConditionalComponent2(cond, name, sel, mod, prefs, env, prefix, st, globals);
////      then
////        (el, st, globals);
////
////    else
////      equation
////        true = Flags.isSet(Flags.FAILTRACE);
////        Debug.traceln("NFInst.instConditionalComponent failed on " +
////          NFInstDump.componentStr(inComponent) + "\n");
////      then
////        fail();
////
////  end matchcontinue;
////end instConditionalComponent;
////
////protected function instConditionalComponent2
////  input Condition inCondition;
////  input Absyn.Path inName;
////  input SCode.Element inElement;
////  input Modifier inMod;
////  input Prefixes inPrefixes;
////  input Env inEnv;
////  input Prefix inPrefix;
////  input SymbolTable inSymbolTable;
////  input Globals inGlobals;
////  output Option<Element> outElement;
////  output SymbolTable outSymbolTable;
////  output Globals outGlobals;
////algorithm
////  (outElement, outSymbolTable, outGlobals) :=
////  match(inCondition, inName, inElement, inMod, inPrefixes, inEnv, inPrefix, inSymbolTable, inGlobals)
////    local
////      SCode.Element sel;
////      Element el;
////      SymbolTable st;
////      Boolean added;
////      Option<Element> oel;
////      Component comp;
////      Globals globals;
////
////    case (NFInstTypes.SINGLE_CONDITION(true), _, _, _, _, _, _, st, globals)
////      equation
////        // We need to remove the condition from the element, otherwise
////        // instElement will just add it as a conditional component again.
////        sel = SCode.removeComponentCondition(inElement);
////        // Instantiate the element and update the symbol table.
////        (el, globals) = instElement(sel, inMod, NFInstTypes.NOMOD(), inPrefixes, inEnv, inPrefix, globals);
////        (st, added) = NFInstSymbolTable.addInstCondElement(el, st);
////        // Recursively instantiate any conditional components in this element.
////        (oel, st, globals) = instConditionalElementOnTrue(added, el, st, globals);
////      then
////        (oel, st, globals);
////
////    case (NFInstTypes.SINGLE_CONDITION(false), _, _, _, _, _, _, st, globals)
////      equation
////        comp = NFInstTypes.DELETED_COMPONENT(inName);
////        st = NFInstSymbolTable.updateComponent(comp, inSymbolTable);
////      then
////        (NONE(), st, globals);
////
////    case (NFInstTypes.ARRAY_CONDITION(conditions = _), _, _, _, _, _, _, st, _)
////      equation
////        print("Sorry, complex arrays with conditional components are not yet supported.\n");
////      then
////        fail();
////
////  end match;
////end instConditionalComponent2;
////
////protected function evaluateConditionalExp
////  input DAE.Exp inExp;
////  input DAE.Type inType;
////  input Absyn.Path inName;
////  input SourceInfo inInfo;
////  output Condition outCondition;
////algorithm
////  outCondition := match(inExp, inType, inName, inInfo)
////    local
////      Boolean cond;
////      String exp_str, name_str, ty_str;
////      DAE.Type ty;
////      list<DAE.Exp> expl;
////      list<Condition> condl;
////
////    case (DAE.BCONST(bool = cond), DAE.T_BOOL(varLst = _), _, _)
////      then NFInstTypes.SINGLE_CONDITION(cond);
////
////    case (DAE.ARRAY(ty = ty, array = expl), DAE.T_BOOL(varLst = _), _, _)
////      equation
////        condl = List.map3(expl, evaluateConditionalExp, ty, inName, inInfo);
////      then
////        NFInstTypes.ARRAY_CONDITION(condl);
////
////    case (_, DAE.T_BOOL(varLst = _), _, _)
////      equation
////        // TODO: Return the variability of an expression from instExp, so that
////        // we can see whether we got a variable expression here (which is an
////        // error), or if we simply failed to evaluate it (which is a fault in
////        // the compiler).
////        exp_str = ExpressionDump.printExpStr(inExp);
////        Error.addSourceMessage(Error.COMPONENT_CONDITION_VARIABILITY,
////          {exp_str}, inInfo);
////      then
////        fail();
////
////    case (_, _, _, _)
////      equation
////        exp_str = ExpressionDump.printExpStr(inExp);
////        name_str = Absyn.pathString(inName);
////        ty_str = Types.printTypeStr(inType);
////        Error.addSourceMessage(Error.CONDITION_TYPE_ERROR,
////          {exp_str, name_str, ty_str}, inInfo);
////      then
////        fail();
////
////  end match;
////end evaluateConditionalExp;

annotation(__OpenModelica_Interface="frontend");
end NFInst;
