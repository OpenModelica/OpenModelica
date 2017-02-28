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

  New instantiation, enable with +d=newInst.
"

import Absyn;
import SCode;

import Builtin = NFBuiltin;
import Binding = NFBinding;
import NFComponent.Component;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import NFExpression.Expression;
import NFClass.ClassTree;
import NFClass.Class;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFMod.Modifier;
import NFMod.ModifierScope;
import Operator = NFOperator;
import NFEquation.Equation;
import NFStatement.Statement;
import Type = NFType;
import Subscript = NFSubscript;

protected
import Array;
import Error;
import Flatten = NFFlatten;
import Global;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import NFExtend;
import NFImport;
import Typing = NFTyping;
import ExecStat.{execStat,execStatReset};
import SCodeDump;
import SCodeUtil;
import System;
import Call = NFCall;

public
function instClassInProgram
  "Instantiates a class given by its fully qualified path, with the result being
   a DAE."
  input Absyn.Path classPath;
  input SCode.Program program;
  output DAE.DAElist dae;
protected
  InstNode top, cls, inst_cls;
  Component top_comp;
  InstNode top_comp_node;
  String name;
algorithm
  execStatReset();

  // Create a root node from the given top-level classes.
  top := makeTopNode(program);
  name := Absyn.pathString(classPath);

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, Absyn.dummyInfo);
  cls := InstNode.setNodeType(InstNodeType.ROOT_CLASS(), cls);

  // Instantiate the class.
  inst_cls := instantiate(cls);
  execStat("NFInst.instantiate("+ name +")");

  // Instantiate component bindings. This is done as a separate step after
  // instantiation to make sure that lookup is able to find the correct nodes.
  instExpressions(inst_cls);
  execStat("NFInst.instBindings("+ name +")");

  // Type the class.
  Typing.typeClass(inst_cls);
  execStat("NFTyping.typeClass("+ name +")");

  // Flatten the class into a DAE.
  dae := Flatten.flatten(inst_cls);
  execStat("NFFlatten.flatten("+ name +")");
end instClassInProgram;

function instantiate
  input output InstNode node;
  input Modifier modifier = Modifier.NOMOD();
  input InstNode parent = InstNode.EMPTY_NODE();
algorithm
  node := partialInstClass(node);
  node := expandClass(node);
  node := instClass(node, modifier, parent);
end instantiate;

function expand
  input output InstNode node;
algorithm
  node := partialInstClass(node);
  node := expandClass(node);
end expand;

function makeTopNode
  "Creates an instance node from the given list of top-level classes."
  input list<SCode.Element> topClasses;
  output InstNode topNode;
protected
  SCode.Element cls;
  ClassTree.Tree scope;
  Class c;
algorithm
  // Create a fake SCode.Element for the top scope, so we don't have to make the
  // definition in InstNode an option.
  cls := SCode.CLASS("<top>", SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(),
    SCode.NOT_PARTIAL(), SCode.R_PACKAGE(),
    SCode.PARTS(topClasses, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.COMMENT(NONE(), NONE()), Absyn.dummyInfo);

  // Make an InstNode for the top scope.
  topNode := InstNode.newClass(cls, InstNode.EMPTY_NODE(), InstNodeType.TOP_SCOPE());

  // Create a scope from the top classes, and insert them into the top scope class.
  scope := makeScope(topClasses, topNode);
  c := Class.initExpandedClass(scope);
  topNode := InstNode.updateClass(c, topNode);
end makeTopNode;

function makeScope
  "Creates a new scope from a list of SCode elements. It returns a scope with
   all the classes added to it, and a list of the non-class elements that were
   not added to the scope."
  input list<SCode.Element> elements;
  input InstNode parentScope;
  output ClassTree.Tree scope "Tree with classes.";
  output list<SCode.Element> componentsExtends = {} "Components and extends.";
protected
  InstNode node;
  list<SCode.Element> imports = {};
  SCode.Element ex;
algorithm
  scope := ClassTree.new();

  for e in elements loop
    () := match e
      // A class, create a new instance node for it and add it to the tree.
      case SCode.CLASS() guard not NFExtend.isRedeclareElement(e)
        algorithm
          node := InstNode.newClass(e, parentScope);
          scope := addClassToScope(e.name, ClassTree.Entry.CLASS(node), e.info, scope);
        then
          ();

      // A component, add it to the list of components and extends.
      case SCode.COMPONENT() guard not NFExtend.isRedeclareElement(e)
        algorithm
          componentsExtends := e :: componentsExtends;
        then
          ();

      // An extends clause, add it to the list of components and extends.
      case SCode.EXTENDS()
        algorithm
          {ex} := NFExtend.addRedeclareAsElementsToExtends({e}, List.select(elements, NFExtend.isRedeclareElement));
          componentsExtends := ex :: componentsExtends;
        then
          ();

      case SCode.IMPORT()
        algorithm
          imports := e :: imports;
        then
          ();

      else
       algorithm
         // print("Skipping:\n" + SCodeDump.unparseElementStr(e) + "\n");
       then ();
    end match;
  end for;

  scope := NFImport.addImportsToScope(imports, parentScope, scope);
end makeScope;

function addClassToScope
  input String name;
  input ClassTree.Entry id;
  input SourceInfo info;
  input output ClassTree.Tree scope;
algorithm
  try
    scope := ClassTree.add(scope, name, id, ClassTree.addConflictFail);
  else
    // TODO: Add proper error message.
    print(getInstanceName() + " duplicate element " + name + " found.\n");
    fail();
  end try;
end addClassToScope;

function partialInstClass
  input output InstNode node;
protected
  Class c;
algorithm
  () := match InstNode.getClass(node)
    case Class.NOT_INSTANTIATED()
      algorithm
        c := partialInstClass2(InstNode.definition(node), node);
        node := InstNode.updateClass(c, node);
      then
        ();

    else ();
  end match;
end partialInstClass;

function partialInstClass2
  input SCode.Element definition;
  input InstNode scope;
  output Class cls;
algorithm
  cls := match definition
    local
      SCode.ClassDef cdef;
      ClassTree.Tree class_tree;
      list<SCode.Element> elements;
      Type ty;
      array<InstNode> comps;

    case SCode.CLASS(classDef = cdef as SCode.PARTS())
      algorithm
        (class_tree, elements) := makeScope(cdef.elementLst, scope);
      then
        Class.PARTIAL_CLASS(class_tree, elements, Modifier.NOMOD());

    case SCode.CLASS(classDef = cdef as SCode.ENUMERATION())
      algorithm
        ty := makeEnumerationType(cdef.enumLst, scope);
        (class_tree, comps) := makeEnumerationScope(cdef.enumLst, ty, scope);
      then
        Class.PARTIAL_BUILTIN(ty, class_tree, comps, Modifier.NOMOD());

    case SCode.CLASS(classDef = cdef as SCode.CLASS_EXTENDS())
      algorithm
        // get the already existing classes with the same name
        print(getInstanceName() + " got class extends: " + definition.name + "\n");
      then
        fail();

    else Class.PARTIAL_CLASS(ClassTree.new(), {}, Modifier.NOMOD());
  end match;
end partialInstClass2;

function makeEnumerationType
  input list<SCode.Enum> literals;
  input InstNode scope;
  output Type ty;
protected
  list<String> lits;
  Absyn.Path path;
algorithm
  path := InstNode.path(scope);
  lits := list(e.literal for e in literals);
  ty := Type.ENUMERATION(path, lits);
end makeEnumerationType;

function makeEnumerationScope
  input list<SCode.Enum> literals;
  input Type enumType;
  input InstNode enumClass;
  output ClassTree.Tree scope;
  output array<InstNode> literalNodes;
protected
  list<InstNode> lit_nodes = {};
  SCode.Element enum_def = InstNode.definition(enumClass);
  SourceInfo info = SCode.elementInfo(enum_def);
  Binding binding;
  Component comp;
  Integer index = 1;
algorithm
  for lit in literals loop
    binding := Binding.TYPED_BINDING(Expression.ENUM_LITERAL(enumType, lit.literal, index),
      enumType, DAE.C_CONST(), 0, info);
    comp := Component.TYPED_COMPONENT(enumClass, enumType, binding, NFComponent.CONST_ATTR);
    lit_nodes := InstNode.fromComponent(lit.literal, comp, enum_def, enumClass) :: lit_nodes;
  end for;

  scope := addComponentsToScope(lit_nodes, ClassTree.new());
  literalNodes := listArray(lit_nodes);
end makeEnumerationScope;

function expandClass
  input output InstNode node;
algorithm
  node := match InstNode.getClass(node)
    case Class.PARTIAL_CLASS()
      then expandClass2(node);
    else node;
  end match;
end expandClass;

function expandClass2
  input output InstNode node;
protected
  SCode.Element def = InstNode.definition(node);
algorithm
  node := match def
    local
      Absyn.TypeSpec ty;
      SCode.Mod der_mod;
      SCode.Element ext, cls;
      Class c;
      SCode.ClassDef cdef;
      ClassTree.Tree scope;
      list<SCode.Element> elements;
      list<InstNode> components;
      Integer idx;
      list<Equation> eq, ieq;
      list<list<Statement>> alg, ialg;
      InstNode n;
      Modifier mod;
      list<InstNode> ext_nodes;
      array<InstNode> ext_arr;
      Option<InstNode> builtin_ext;
      InstNode builtin_comp;
      SCode.Ident name;
      SCode.Prefixes prefixes;
      SCode.Comment cmt;
      SourceInfo info;
      list<SCode.Enum> enumLst;

    case SCode.CLASS(classDef = SCode.DERIVED(typeSpec = ty, modifications = der_mod))
      algorithm
        ext := SCode.EXTENDS(Absyn.typeSpecPath(ty), SCode.PUBLIC(),
          der_mod, NONE(), Absyn.dummyInfo);
        def.classDef := SCode.PARTS({ext}, {}, {}, {}, {}, {}, {}, NONE());
        c := Class.PARTIAL_CLASS(ClassTree.new(), {ext},
          Class.getModifier(InstNode.getClass(node)));
        node := InstNode.updateClass(c, node);
        node := InstNode.setDefinition(def, node);
      then
        expandClass2(node);

    case SCode.CLASS(classDef = cdef as SCode.PARTS())
      algorithm
        Class.PARTIAL_CLASS(classes = scope, elements = elements, modifier = mod) :=
          InstNode.getClass(node);

        // Change the class to an empty expanded class, to avoid instantiation loops.
        c := Class.initExpandedClass(scope);
        node := InstNode.updateClass(c, node);

        // Expand all the extends clauses.
        (components, scope, ext_nodes, builtin_ext) :=
          expandExtends(elements, def.name, node, scope);

        if isSome(builtin_ext) then
          SOME(builtin_comp) := builtin_ext;
          node := expandBuiltinExtends(builtin_comp, ext_nodes, components, scope, mod, node);
        else
          scope := addComponentsToScope(components, scope);

          ext_nodes := flattenExtends(ext_nodes);
          ext_arr := listArray(ext_nodes);
          scope := addInheritedElements(ext_nodes, scope);

          c := Class.EXPANDED_CLASS(scope, ext_arr, listArray(components), mod);
          node := InstNode.updateClass(c, node);
        end if;
      then
        node;

    case SCode.CLASS(classDef = cdef as SCode.CLASS_EXTENDS())
      algorithm
        // get the already existing classes with the same name
        print(getInstanceName() + " got class extends: " + def.name + "\n");
      then
        fail();

    else
      algorithm
        assert(false, getInstanceName() + " got unknown class");
      then
        fail();

  end match;
end expandClass2;

function expandExtends
  "This function takes a list of SCode element and expands all the extends
   clauses. This means expanding the extended classes and inserting their
   contents into the scope and element list, as well as applying any modifiers
   from the extends clause to the inherited elements. The result is a list of
   components, both local and inherited, as well as a scope filled with local
   and inherited components and classes."
  input list<SCode.Element> elements;
  input String className;
  input InstNode currentScope;
        output list<InstNode> components = {};
  input output ClassTree.Tree scope;
  output list<InstNode> extendsNodes = {};
  output Option<InstNode> builtinExtends = NONE();
protected
  InstNode ext_node;
  Class ext_inst;
  Modifier mod;
  ModifierScope mod_scope;
  Boolean is_builtin, builtin_ext;
  Integer ext_idx = 0;
algorithm
  for e in elements loop
    () := match e
      case SCode.EXTENDS()
        algorithm
          ext_idx := ext_idx + 1;

          // Look up the name and expand the class.
          ext_node := Lookup.lookupBaseClassName(e.baseClassPath, currentScope, e.info);
          is_builtin := Class.isBuiltin(InstNode.getClass(ext_node));

          if not is_builtin then
            ext_node := InstNode.newExtends(ext_node, currentScope);
            ext_node := expand(ext_node);
          end if;


          // Initialize the modifiers from the extends clause.
          mod_scope := ModifierScope.EXTENDS_SCOPE(e.baseClassPath);
          mod := Modifier.create(e.modifications, "", mod_scope, currentScope);

          // Apply the modifier from the extends clause to the expanded class.
          ext_inst := InstNode.getClass(ext_node);
          ext_inst := applyModifier(mod, ext_inst, mod_scope);
          ext_node := InstNode.updateClass(ext_inst, ext_node);

          ext_inst := InstNode.getClass(ext_node);
          builtin_ext := isBuiltinExtends(ext_inst);

          if not builtin_ext then
            components := InstNode.REF_NODE(ext_idx) :: components;
          else
            builtinExtends := SOME(ext_node);
          end if;

          extendsNodes := ext_node :: extendsNodes;
        then
          ();

      case SCode.COMPONENT()
        algorithm
          // A component, add it to the list of components.
          components := InstNode.newComponent(e) :: components;
        then
          ();

      else
        algorithm
          assert(false, getInstanceName() + " got unknown element");
        then
          fail();

    end match;
  end for;

  extendsNodes := listReverse(extendsNodes);
end expandExtends;

function isBuiltinExtends
  "Checks if an extends is extending a builtin type."
  input Class cls;
  output Boolean isBuiltinExtends;
algorithm
  isBuiltinExtends := match cls
    case Class.PARTIAL_BUILTIN() then true;
    else false;
  end match;
end isBuiltinExtends;

function expandBuiltinExtends
  "This function handles the case where a class extends from a builtin type."
  input InstNode builtinExtends;
  input list<InstNode> extendsNodes;
  input list<InstNode> components;
  input ClassTree.Tree scope;
  input Modifier modifier;
  input output InstNode node;
protected
  InstNode n;
  Class c;
  Modifier mod;
algorithm
  // A class extending from a builtin type may not have any other elements.
  if listLength(extendsNodes) <> 1 or listLength(components) > 0 or
      not ClassTree.isEmpty(scope) then
    // ***TODO***: Find the invalid element and use its info to make the error
    //             message more accurate.
    Error.addSourceMessage(Error.BUILTIN_EXTENDS_INVALID_ELEMENTS,
      {InstNode.name(builtinExtends)}, InstNode.info(node));
    fail();
  end if;

  // Fetch the class of the builtin type.
  c := InstNode.getClass(builtinExtends);

  // Apply the given modifier to the class.
  mod := Modifier.merge(Class.getModifier(c), modifier);
  c := Class.setModifier(mod, c);

  // Replace the class we're expanding with the builtin type.
  node := InstNode.updateClass(c, node);
end expandBuiltinExtends;

function applyModifier
  "Takes a modifier and applies the submodifiers in it to an class."
  input Modifier modifier;
  input output Class cls;
  input ModifierScope modifierScope;
algorithm
  () := match cls
    local
      list<Modifier> mods;
      ClassTree.Tree elements;
      ClassTree.Entry entry;
      InstNode node;
      String name;
      SCode.Element c;

    case Class.PARTIAL_BUILTIN()
      algorithm
        cls.modifier := Modifier.merge(modifier, cls.modifier);
      then
        ();

    else
      algorithm
        elements := Class.elements(cls);
        mods := Modifier.toList(modifier);

        for m in mods loop
          // Skip empty modifiers.
          if Modifier.isEmpty(m) then
            continue;
          end if;

          // Fetch the class tree entry for the element with the same name as the modifier.
          try
            entry := ClassTree.get(elements, Modifier.name(m));
          else
            Error.addSourceMessageAndFail(Error.MISSING_MODIFIED_ELEMENT,
              {Modifier.name(m), ModifierScope.name(modifierScope)}, Modifier.info(m));
          end try;

          () := match entry
            // Modifier is for a component, add it to the component in the array.
            case ClassTree.Entry.COMPONENT()
              algorithm
                node := Class.resolveElement(entry, cls);
                InstNode.componentApply(node, Component.mergeModifier, m);
              then
                ();

            case ClassTree.Entry.CLASS()
              algorithm
                _ := match m
                  case Modifier.MODIFIER()
                    algorithm
                      // If a class is modified it's probably going to be used, so we
                      // might as well partially instantiate it now to simplify the
                      // modifier handling a bit.
                      entry.node := partialInstClass(entry.node);
                      InstNode.classApply(entry.node, Class.setModifier, m);
                    then
                      ();

                  case Modifier.REDECLARE()
                    algorithm
                      name := InstNode.name(m.element);
                      c := InstNode.definition(m.element);
                      elements :=
                      match c
                        case SCode.CLASS(classDef = SCode.CLASS_EXTENDS())
                          then
                            NFExtend.adaptClassExtendsChain(name, ClassTree.Entry.CLASS(m.element), elements);

                        else
                          then
                            ClassTree.add(elements, name, ClassTree.Entry.CLASS(m.element), ClassTree.addConflictReplace);
                      end match;
                    then
                      ();

                end match;
              then
                ();

          end match;
        end for;

        cls := Class.setElements(elements, cls);
      then
        ();

  end match;
end applyModifier;

function addComponentsToScope
  input list<InstNode> components;
  input output ClassTree.Tree scope;
protected
  Integer comp_idx = 0;
algorithm
  for c in components loop
    comp_idx := comp_idx + 1;

    if InstNode.isComponent(c) then
      scope := ClassTree.add(scope, InstNode.name(c),
        ClassTree.Entry.COMPONENT(0, comp_idx), ClassTree.addConflictReplace);
    end if;
  end for;
end addComponentsToScope;

function flattenExtends
  input list<InstNode> extNodes;
  output list<InstNode> accumExt = {};
protected
  Class ext;
algorithm
  for e in extNodes loop
    assert(InstNode.isClass(e), getInstanceName() + " got non-class extends node");
    ext := InstNode.getClass(e);

    _ := match ext
      case Class.EXPANDED_CLASS()
        algorithm
          for e in ext.extendsNodes loop
            accumExt := e :: accumExt;
          end for;
        then
          ();

      else
        algorithm
          assert(false, getInstanceName() + " got non-expanded class");
        then
          fail();

    end match;
  end for;

  accumExt := listAppend(extNodes, accumExt);
end flattenExtends;

function addInheritedElements
  input list<InstNode> extNodes;
  input output ClassTree.Tree scope;
protected
  Class ext;
  Integer i = 1;
algorithm
  for node in extNodes loop
    ext := InstNode.getClass(node);

    () := match ext
      case Class.EXPANDED_CLASS()
        algorithm
          scope := ClassTree.fold(ext.elements,
            function addInheritedElements2(nodeIndex = i), scope);
          i := i + 1;
        then
          ();

      else
        algorithm
          assert(false, getInstanceName() + " got non-expanded class");
        then
          fail();
    end match;
  end for;
end addInheritedElements;

function addInheritedElements2
  input String name;
  input ClassTree.Entry id;
  input ClassTree.Tree inScope;
  input Integer nodeIndex;
  output ClassTree.Tree scope;
algorithm
  scope := match id

    case ClassTree.Entry.CLASS()
      algorithm
        try
         scope := ClassTree.add(inScope, name, id);
        else
         // the element exists already (could be a class extends)
         print(getInstanceName() + " duplicate element " + name + " found.\n");
         scope := inScope;
        end try;
      then
        scope;

    case ClassTree.Entry.COMPONENT(node = 0)
      then ClassTree.add(inScope, name, ClassTree.Entry.COMPONENT(nodeIndex, id.index));

    else inScope;

  end match;
end addInheritedElements2;

function instClass
  "Instantiates a class. The class is cloned, so each call to this function
   creates a unique instance. The parent is usually the component whose type
   should be instantiated. If the parent is an empty node, then the class itself
   will be used as the parent (after cloning)."
  input output InstNode node;
  input Modifier modifier;
  input InstNode parent;
protected
  Class cls = InstNode.getClass(node), inst_cls;
  array<InstNode> components, ext_nodes;
  Modifier mod;
  list<Modifier> type_mods, inst_type_mods;
  Binding binding;
  InstNode scope, par;
algorithm
  () := match cls
    case Class.EXPANDED_CLASS()
      algorithm
        components := Array.map(cls.components, InstNode.clone);
        ext_nodes := cls.extendsNodes;
        for n in ext_nodes loop
          InstNode.clone(n);
        end for;

        inst_cls := Class.INSTANCED_CLASS(cls.elements, ext_nodes, components, {}, {}, {}, {});
        node := InstNode.replaceClass(inst_cls, node);

        // Apply the modifier to the class.
        mod := Modifier.merge(modifier, cls.modifier);
        inst_cls := applyModifier(modifier, inst_cls,
          ModifierScope.CLASS_SCOPE(InstNode.name(node)));
        node := InstNode.updateClass(inst_cls, node);

        // If the parent is an empty node, use the cloned node as parent instead.
        // This is used for e.g. extends nodes, which are their own parents.
        par := if InstNode.isEmpty(parent) then node else parent;

        // Instantiate the extends nodes.
        for i in 1:arrayLength(ext_nodes) loop
          ext_nodes[i] := instClass(ext_nodes[i], Modifier.NOMOD(), InstNode.EMPTY_NODE());
        end for;

        // Instantiate local components.
        instComponents(components, ext_nodes, par, node);
      then
        ();

    // A builtin type.
    case Class.PARTIAL_BUILTIN()
      algorithm
        // Merge any outer modifiers on the class with the class' own modifier.
        mod := Modifier.merge(modifier, cls.modifier);

        // If the modifier isn't empty, instantiate it.
        inst_type_mods := {};
        if not Modifier.isEmpty(mod) then
          type_mods := Modifier.toList(mod);
          scope := InstNode.parent(node);

          // Instantiate the binding of each submodifier.
          for m in type_mods loop
            () := match m
              case Modifier.MODIFIER()
                algorithm
                  binding := instBinding(m.binding);
                  m.binding := binding;
                then
                  ();

              else ();
            end match;

            inst_type_mods := m :: inst_type_mods;
          end for;
        end if;

        inst_cls := Class.INSTANCED_BUILTIN(cls.ty, cls.elements, cls.components, inst_type_mods);
        node := InstNode.replaceClass(inst_cls, node);
      then
        ();

    // Any other type of class is already instantiated.
    else ();
  end match;
end instClass;

function instComponents
  input output array<InstNode> components;
  input output array<InstNode> extendsNodes;
  input InstNode parent;
  input InstNode scope;
protected
  InstNode node;
  Integer ref_id;
algorithm
  for i in 1:arrayLength(components) loop
    node := components[i];

    if InstNode.isComponent(node) then
      components[i] := instComponent(node, parent, scope);
    elseif InstNode.isRef(node) then
      // Extends nodes have already been instantiated. Here we just replace the
      // reference nodes with the actual nodes, so we don't need to handle
      // reference nodes after this.
      InstNode.REF_NODE(index = ref_id) := node;
      components[i] := extendsNodes[ref_id];
    else
      assert(false, getInstanceName() + " got invalid node");
    end if;
  end for;
end instComponents;

function instComponent
  input output InstNode node "The component node to instantiate.";
  input InstNode parent "The parent of the component, usually another component.";
  input InstNode scope "The scope containing the component.";
protected
  Component component, inst_comp;
  String name;
  SCode.Element comp;
  InstNode cls;
  Modifier comp_mod;
  Binding binding;
  DAE.Type ty;
  Component.Attributes attr;
  list<Dimension> dims;
algorithm
  component := InstNode.component(node);
  comp := InstNode.definition(node);

  () := match (component, comp)
    case (Component.COMPONENT_DEF(modifier = comp_mod as Modifier.REDECLARE()), _)
      algorithm
        node := instComponent(comp_mod.element, parent, InstNode.parent(comp_mod.element));
      then
        ();

    case (Component.COMPONENT_DEF(), SCode.COMPONENT())
      algorithm
        name := InstNode.name(node);
        node := InstNode.setOrphanParent(parent, node);

        // Merge the modifier from the component.
        comp_mod := Modifier.create(comp.modifications, name,
          ModifierScope.COMPONENT_SCOPE(name), parent);
        comp_mod := Modifier.merge(component.modifier, comp_mod);
        comp_mod := Modifier.propagate(comp_mod, listLength(comp.attributes.arrayDims));

        binding := Modifier.binding(comp_mod);

        // Instantiate the type of the component.
        cls := instTypeSpec(comp.typeSpec, comp_mod, scope, node, comp.info);

        // Instantiate the component's dimensions.
        dims := instDimensions(comp.attributes.arrayDims, scope, comp.info);
        Modifier.checkEach(comp_mod, listEmpty(dims), name);

        // Instantiate attributes and create the untyped component.
        attr := instComponentAttributes(comp.attributes, comp.prefixes);
        inst_comp := Component.UNTYPED_COMPONENT(cls, listArray(dims), binding, attr);
        node := InstNode.updateComponent(inst_comp, node);
      then
        ();

    else ();
  end match;
end instComponent;

function instComponentAttributes
  input SCode.Attributes compAttr;
  input SCode.Prefixes compPrefs;
  output Component.Attributes attributes;
protected
  DAE.ConnectorType connectorType;
  DAE.VarParallelism parallelism;
  DAE.VarKind variability;
  DAE.VarDirection direction;
  DAE.VarInnerOuter innerOuter;
  DAE.VarVisibility visiblity;
algorithm
  connectorType := InstUtil.translateConnectorType(compAttr.connectorType);
  parallelism := InstUtil.translateParallelism(compAttr.parallelism);
  variability := InstUtil.translateVariability(compAttr.variability);
  direction := InstUtil.translateDirection(compAttr.direction);
  innerOuter := InstUtil.translateInnerOuter(compPrefs.innerOuter);
  visiblity := InstUtil.translateVisibility(compPrefs.visibility);
  attributes := Component.Attributes.ATTRIBUTES(connectorType, parallelism, variability, direction, innerOuter, visiblity);
end instComponentAttributes;

function instTypeSpec
  input Absyn.TypeSpec typeSpec;
  input Modifier modifier;
  input InstNode scope;
  input InstNode parent;
  input SourceInfo info;
  output InstNode node;
algorithm
  node := match typeSpec
    case Absyn.TPATH()
      algorithm
        node := Lookup.lookupClassName(typeSpec.path, scope, info);
        node := instantiate(node, modifier, parent);
      then
        node;

    case Absyn.TCOMPLEX()
      algorithm
        print("NFInst.instTypeSpec: TCOMPLEX not implemented.\n");
      then
        fail();

  end match;
end instTypeSpec;

function instDimension
  input Absyn.Subscript subscript;
  input InstNode scope;
  input SourceInfo info;
  output Dimension dimension;
algorithm
  dimension := match subscript
    local
      Expression exp;

    case Absyn.NOSUB() then Dimension.UNKNOWN();
    case Absyn.SUBSCRIPT()
      algorithm
        exp := instExp(subscript.subscript, scope, info, true);
      then
        Dimension.UNTYPED(exp, false);

  end match;
end instDimension;

function instDimensions
  input Absyn.ArrayDim absynDims;
  input InstNode scope;
  input SourceInfo info;
  output list<Dimension> dims;
algorithm
  dims := list(instDimension(dim, scope, info) for dim in absynDims);
end instDimensions;

function instExpressions
  input InstNode node;
  input InstNode scope = node;
protected
  Class cls = InstNode.getClass(node);
algorithm
  () := match cls
    case Class.INSTANCED_CLASS()
      algorithm
        for c in cls.components loop
          if InstNode.isComponent(c) then
            instComponentBindings(c);
          else
            instExpressions(c);
          end if;
        end for;

        instSections(node, scope);
      then
        ();

    case Class.PARTIAL_BUILTIN() then ();
    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        assert(false, getInstanceName() + " got invalid class");
      then
        fail();

  end match;
end instExpressions;

function instComponentBindings
  input InstNode component;
protected
  Component c = InstNode.component(component);
algorithm
  () := match c
    case Component.UNTYPED_COMPONENT()
      algorithm
        c.binding := instBinding(c.binding);
        instExpressions(c.classInst, component);
        InstNode.updateComponent(c, component);
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got invalid component");
      then
        fail();

  end match;
end instComponentBindings;

function instBinding
  input output Binding binding;
algorithm
  binding := match binding
    local
      Expression bind_exp;

    case Binding.RAW_BINDING()
      algorithm
        bind_exp := instExp(binding.bindingExp, binding.scope, binding.info);
      then
        Binding.UNTYPED_BINDING(bind_exp, false, binding.scope, binding.propagatedDims, binding.info);

    else binding;
  end match;
end instBinding;

function instExpOpt
  input Option<Absyn.Exp> absynExp;
  input InstNode scope;
  input SourceInfo info;
  output Option<Expression> exp;
algorithm
  exp := match absynExp
    local
      Absyn.Exp aexp;

    case NONE() then NONE();
    case SOME(aexp) then SOME(instExp(aexp, scope, info));

  end match;
end instExpOpt;

function instExp
  input Absyn.Exp absynExp;
  input InstNode scope;
  input SourceInfo info;
  input Boolean allowTypename = false;
  output Expression exp;
algorithm
  exp := match absynExp
    local
      Expression e1, e2, e3;
      Option<Expression> oe;
      Operator op;
      list<Expression> expl;

    case Absyn.Exp.INTEGER() then Expression.INTEGER(absynExp.value);
    case Absyn.Exp.REAL() then Expression.REAL(stringReal(absynExp.value));
    case Absyn.Exp.STRING() then Expression.STRING(absynExp.value);
    case Absyn.Exp.BOOL() then Expression.BOOLEAN(absynExp.value);

    case Absyn.Exp.CREF()
      then instCref(absynExp.componentRef, scope, info, allowTypename);

    case Absyn.Exp.ARRAY()
      algorithm
        expl := list(instExp(e, scope, info) for e in absynExp.arrayExp);
      then
        Expression.ARRAY(Type.UNKNOWN(), expl);

    case Absyn.Exp.MATRIX()
      algorithm
        expl := list(Expression.ARRAY(
            Type.UNKNOWN(), list(instExp(e, scope, info) for e in el))
          for el in absynExp.matrix);
      then
        Expression.ARRAY(Type.UNKNOWN(), expl);

    case Absyn.Exp.RANGE()
      algorithm
        e1 := instExp(absynExp.start, scope, info);
        oe := instExpOpt(absynExp.step, scope, info);
        e3 := instExp(absynExp.stop, scope, info);
      then
        Expression.RANGE(Type.UNKNOWN(), e1, oe, e3);

    case Absyn.Exp.BINARY()
      algorithm
        e1 := instExp(absynExp.exp1, scope, info);
        e2 := instExp(absynExp.exp2, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.BINARY(e1, op, e2);

    case Absyn.Exp.UNARY()
      algorithm
        e1 := instExp(absynExp.exp, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.UNARY(op, e1);

    case Absyn.Exp.LBINARY()
      algorithm
        e1 := instExp(absynExp.exp1, scope, info);
        e2 := instExp(absynExp.exp2, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.LBINARY(e1, op, e2);

    case Absyn.Exp.LUNARY()
      algorithm
        e1 := instExp(absynExp.exp, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.LUNARY(op, e1);

    case Absyn.Exp.RELATION()
      algorithm
        e1 := instExp(absynExp.exp1, scope, info);
        e2 := instExp(absynExp.exp2, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.RELATION(e1, op, e2);

    case Absyn.Exp.IFEXP()
      algorithm
        e3 := instExp(absynExp.elseBranch, scope, info);

        for branch in listReverse(absynExp.elseIfBranch) loop
          e1 := instExp(Util.tuple21(branch), scope, info);
          e2 := instExp(Util.tuple22(branch), scope, info);
          e3 := Expression.IF(e1, e2, e3);
        end for;

        e1 := instExp(absynExp.ifExp, scope, info);
        e2 := instExp(absynExp.trueBranch, scope, info);
      then
        Expression.IF(e1, e2, e3);

    case Absyn.Exp.CALL()
      then Call.instantiate(absynExp.function_, absynExp.functionArgs, scope, info);

    else
      algorithm
        assert(false, getInstanceName() + " got unknown expression");
      then
        fail();

  end match;
end instExp;

function instCref
  input Absyn.ComponentRef absynCref;
  input InstNode scope;
  input SourceInfo info;
  input Boolean allowTypename = false "Allows crefs referring to typenames if true.";
  output Expression cref;
protected
  list<InstNode> nodes;
  ComponentRef cr;
  InstNode found_scope;
algorithm
  (_, nodes, found_scope) := Lookup.lookupComponent(absynCref, scope, info, allowTypename);
  cr := ComponentRef.fromNodeList(InstNode.scopeList(found_scope));
  cr := makeCref(absynCref, nodes, scope, info, cr);
  cref := Expression.CREF(cr);
end instCref;

function makeCref
  input Absyn.ComponentRef absynCref;
  input list<InstNode> nodes;
  input InstNode scope;
  input SourceInfo info;
  input ComponentRef accumCref = ComponentRef.EMPTY();
  output ComponentRef cref;

  import NFComponentRef.Origin;
algorithm
  cref := match (absynCref, nodes)
    local
      InstNode node;
      list<InstNode> rest_nodes;
      list<Subscript> subs;

    case (Absyn.ComponentRef.CREF_IDENT(), {node})
      algorithm
        subs := list(instSubscript(s, scope, info) for s in absynCref.subscripts);
      then
        ComponentRef.CREF(node, subs, Type.UNKNOWN(), Origin.CREF, accumCref);

    case (Absyn.ComponentRef.CREF_QUAL(), node :: rest_nodes)
      algorithm
        subs := list(instSubscript(s, scope, info) for s in absynCref.subscripts);
        cref := ComponentRef.CREF(node, subs, Type.UNKNOWN(), Origin.CREF, accumCref);
      then
        makeCref(absynCref.componentRef, rest_nodes, scope, info, cref);

    case (Absyn.ComponentRef.CREF_FULLYQUALIFIED(), _)
      then makeCref(absynCref.componentRef, nodes, scope, info, accumCref);

    case (Absyn.ComponentRef.WILD(), _) then ComponentRef.WILD();
    case (Absyn.ComponentRef.ALLWILD(), _) then ComponentRef.WILD();

    else
      algorithm
        assert(false, getInstanceName() + " failed");
      then
        fail();

  end match;
end makeCref;

function instSubscript
  input Absyn.Subscript absynSub;
  input InstNode scope;
  input SourceInfo info;
  output Subscript subscript;
protected
  Expression exp;
algorithm
  subscript := match absynSub
    case Absyn.Subscript.NOSUB() then Subscript.WHOLE();
    case Absyn.Subscript.SUBSCRIPT()
      algorithm
        exp := instExp(absynSub.subscript, scope, info);
      then
        Subscript.fromExp(exp);
  end match;
end instSubscript;

function instSections
  input output InstNode node;
  input InstNode scope;
protected
  SCode.Element el = InstNode.definition(node);
  SCode.ClassDef def;
algorithm
  node := match el
    case SCode.CLASS(classDef = SCode.PARTS())
      then instSections2(el.classDef, node, scope);

    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = def as SCode.PARTS()))
      then instSections2(def, node, scope);

    else node;
  end match;
end instSections;

function instSections2
  input SCode.ClassDef parts;
  input output InstNode node;
  input InstNode scope;
protected
  list<SCode.Equation> seq, sieq;
  list<SCode.AlgorithmSection> salg, sialg;
  list<Equation> eq, ieq;
  list<list<Statement>> alg, ialg;
  Class c;
algorithm
  SCode.PARTS(normalEquationLst = seq, initialEquationLst = sieq,
    normalAlgorithmLst = salg, initialAlgorithmLst = sialg) := parts;
  eq := instEquations(seq, scope);
  ieq := instEquations(sieq, scope);
  alg := instAlgorithmSections(salg, scope);
  ialg := instAlgorithmSections(sialg, scope);
  c := InstNode.getClass(node);
  c := Class.setSections(eq, ieq, alg, ialg, c);
  node := InstNode.updateClass(c, node);
end instSections2;

function instEquations
  input list<SCode.Equation> scodeEql;
  input InstNode scope;
  output list<Equation> instEql;
algorithm
  instEql := list(instEquation(eq, scope) for eq in scodeEql);
end instEquations;

function instEquation
  input SCode.Equation scodeEq;
  input InstNode scope;
  output Equation instEq;
protected
  SCode.EEquation eq;
algorithm
  SCode.EQUATION(eEquation = eq) := scodeEq;
  instEq := instEEquation(eq, scope);
end instEquation;

function instEEquations
  input list<SCode.EEquation> scodeEql;
  input InstNode scope;
  output list<Equation> instEql;
algorithm
  instEql := list(instEEquation(eq, scope) for eq in scodeEql);
end instEEquations;

function instEEquation
  input SCode.EEquation scodeEq;
  input InstNode scope;
  output Equation instEq;
algorithm
  instEq := match scodeEq
    local
      Expression exp1, exp2, exp3;
      Option<Expression> oexp;
      list<Expression> expl;
      list<Equation> eql;
      list<tuple<Expression, list<Equation>>> branches;
      SourceInfo info;

    case SCode.EEquation.EQ_EQUALS(info = info)
      algorithm
        exp1 := instExp(scodeEq.expLeft, scope, info);
        exp2 := instExp(scodeEq.expRight, scope, info);
      then
        Equation.EQUALITY(exp1, exp2, Type.UNKNOWN(), info);

    case SCode.EEquation.EQ_CONNECT(info = info)
      algorithm
        exp1 := instCref(scodeEq.crefLeft, scope, info);
        exp2 := instCref(scodeEq.crefRight, scope, info);
      then
        Equation.CONNECT(exp1, Type.UNKNOWN(), exp2, Type.UNKNOWN(), info);

    case SCode.EEquation.EQ_FOR(info = info)
      algorithm
        oexp := instExpOpt(scodeEq.range, scope, info);
        eql := instEEquations(scodeEq.eEquationLst, scope);
      then
        Equation.FOR(scodeEq.index, 0, Type.UNKNOWN(), oexp, eql, info);

    case SCode.EEquation.EQ_IF(info = info)
      algorithm
        // Instantiate the conditions.
        expl := list(instExp(c, scope, info) for c in scodeEq.condition);

        // Instantiate each branch and pair it up with a condition.
        branches := {};
        for branch in scodeEq.thenBranch loop
          eql := instEEquations(branch, scope);
          exp1 :: expl := expl;
          branches := (exp1, eql) :: branches;
        end for;

        // Instantiate the else-branch, if there is one, and make it a branch
        // with condition true.
        if not listEmpty(scodeEq.elseBranch) then
          eql := instEEquations(scodeEq.elseBranch, scope);
          branches := (Expression.BOOLEAN(true), eql) :: branches;
        end if;
      then
        Equation.IF(listReverse(branches), info);

    case SCode.EEquation.EQ_WHEN(info = info)
      algorithm
        exp1 := instExp(scodeEq.condition, scope, info);
        eql := instEEquations(scodeEq.eEquationLst, scope);
        branches := {(exp1, eql)};

        for branch in scodeEq.elseBranches loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          eql := instEEquations(Util.tuple22(branch), scope);
          branches := (exp1, eql) :: branches;
        end for;
      then
        Equation.WHEN(branches, info);

    case SCode.EEquation.EQ_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeEq.condition, scope, info);
        exp2 := instExp(scodeEq.message, scope, info);
        exp3 := instExp(scodeEq.level, scope, info);
      then
        Equation.ASSERT(exp1, exp2, exp3, info);

    case SCode.EEquation.EQ_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeEq.message, scope, info);
      then
        Equation.TERMINATE(exp1, info);

    case SCode.EEquation.EQ_REINIT(info = info)
      algorithm
        exp1 := instCref(scodeEq.cref, scope, info);
        exp2 := instExp(scodeEq.expReinit, scope, info);
      then
        Equation.REINIT(exp1, exp2, info);

    case SCode.EEquation.EQ_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeEq.exp, scope, info);
      then
        Equation.NORETCALL(exp1, info);

    else
      algorithm
        assert(false, getInstanceName() + " got unknown equation");
      then
        fail();

  end match;
end instEEquation;

function instAlgorithmSections
  input list<SCode.AlgorithmSection> algorithmSections;
  input InstNode scope;
  output list<list<Statement>> statements;
algorithm
  statements := list(instAlgorithmSection(alg, scope) for alg in algorithmSections);
end instAlgorithmSections;

function instAlgorithmSection
  input SCode.AlgorithmSection algorithmSection;
  input InstNode scope;
  output list<Statement> statements;
algorithm
  statements := instStatements(algorithmSection.statements, scope);
end instAlgorithmSection;

function instStatements
  input list<SCode.Statement> scodeStmtl;
  input InstNode scope;
  output list<Statement> statements;
algorithm
  statements := list(instStatement(stmt, scope) for stmt in scodeStmtl);
end instStatements;

function instStatement
  input SCode.Statement scodeStmt;
  input InstNode scope;
  output Statement statement;
algorithm
  statement := match scodeStmt
    local
      Expression exp1, exp2, exp3;
      Option<Expression> oexp;
      list<Statement> stmtl;
      list<tuple<Expression, list<Statement>>> branches;
      SourceInfo info;

    case SCode.Statement.ALG_ASSIGN(info = info)
      algorithm
        exp1 := instExp(scodeStmt.assignComponent, scope, info);
        exp2 := instExp(scodeStmt.value, scope, info);
      then
        Statement.ASSIGNMENT(exp1, exp2, info);

    case SCode.Statement.ALG_FOR(info = info)
      algorithm
        oexp := instExpOpt(scodeStmt.range, scope, info);
        stmtl := instStatements(scodeStmt.forBody, scope);
      then
        Statement.FOR(scodeStmt.index, 0, Type.UNKNOWN(), oexp, stmtl, info);

    case SCode.Statement.ALG_IF(info = info)
      algorithm
        branches := {};
        for branch in (scodeStmt.boolExpr, scodeStmt.trueBranch) :: scodeStmt.elseIfBranch loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          stmtl := instStatements(Util.tuple22(branch), scope);
          branches := (exp1, stmtl) :: branches;
        end for;

        stmtl := instStatements(scodeStmt.elseBranch, scope);
        branches := listReverse((Expression.BOOLEAN(true), stmtl) :: branches);
      then
        Statement.IF(branches, info);

    case SCode.Statement.ALG_WHEN_A(info = info)
      algorithm
        branches := {};
        for branch in scodeStmt.branches loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          stmtl := instStatements(Util.tuple22(branch), scope);
          branches := (exp1, stmtl) :: branches;
        end for;
      then
        Statement.WHEN(listReverse(branches), info);

    case SCode.Statement.ALG_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeStmt.condition, scope, info);
        exp2 := instExp(scodeStmt.message, scope, info);
        exp3 := instExp(scodeStmt.level, scope, info);
      then
        Statement.ASSERT(exp1, exp2, exp3, info);

    case SCode.Statement.ALG_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.message, scope, info);
      then
        Statement.TERMINATE(exp1, info);

    case SCode.Statement.ALG_REINIT(info = info)
      algorithm
        exp1 := instCref(scodeStmt.cref, scope, info);
        exp2 := instExp(scodeStmt.newValue, scope, info);
      then
        Statement.REINIT(exp1, exp2, info);

    case SCode.Statement.ALG_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeStmt.exp, scope, info);
      then
        Statement.NORETCALL(exp1, info);

    case SCode.Statement.ALG_WHILE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.boolExpr, scope, info);
        stmtl := instStatements(scodeStmt.whileBody, scope);
      then
        Statement.WHILE(exp1, stmtl, info);

    case SCode.Statement.ALG_RETURN() then Statement.RETURN(scodeStmt.info);
    case SCode.Statement.ALG_BREAK() then Statement.BREAK(scodeStmt.info);

    case SCode.Statement.ALG_FAILURE()
      algorithm
        stmtl := instStatements(scodeStmt.stmts, scope);
      then
        Statement.FAILURE(stmtl, scodeStmt.info);

    else
      algorithm
        assert(false, getInstanceName() + " got unknown statement");
      then
        fail();

  end match;
end instStatement;

annotation(__OpenModelica_Interface="frontend");
end NFInst;
