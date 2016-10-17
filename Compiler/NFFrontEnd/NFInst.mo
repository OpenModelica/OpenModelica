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
import NFBinding.Binding;
import NFComponent.Component;
import NFDimension.Dimension;
import NFInstance.ClassTree;
import NFInstance.Instance;
import NFInstanceTree.InstanceTree;
import NFInstNode.InstNode;
import NFInstNode.InstParent;
import NFMod.Modifier;
import NFMod.ModifierScope;
import NFEquation.Equation;
import NFStatement.Statement;

protected
import Error;
import Flatten = NFFlatten;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import System;
import Typing = NFTyping;

public
function instClassInProgram
  input Absyn.Path classPath;
  input SCode.Program program;
  output DAE.DAElist dae;
protected
  InstanceTree inst_tree;
  InstNode cls;
algorithm
  System.startTimer();
  inst_tree := makeTree(program);

  (cls, inst_tree) := Lookup.lookupClassName(classPath, inst_tree, Absyn.dummyInfo);
  (cls, inst_tree) := instantiate(cls, Modifier.NOMOD(), InstParent.NO_PARENT(), inst_tree);

  // TODO: Why is this a separate phase? Could be done in instComponent?
  (cls, inst_tree) := instBindings(cls, inst_tree);

  (cls, inst_tree, _) := Typing.typeClass(cls, inst_tree);

  dae := NFFlatten.flattenClass(cls);

  System.stopTimer();
  //print("NFInst done in " + String(System.getTimerIntervalTime()) + "\n");
end instClassInProgram;

function instantiate
  input output InstNode node;
  input Modifier modifier;
  input InstParent parent;
  input output InstanceTree tree;
algorithm
  (node, tree) := partialInstClass(node, tree);
  (node, tree) := expandClass(node, parent, tree);
  (node, tree) := instClass(node, modifier, tree);
end instantiate;

function expand
  input output InstNode node;
  input InstParent parent;
  input output InstanceTree tree;
algorithm
  (node, tree) := partialInstClass(node, tree);
  (node, tree) := expandClass(node, parent, tree);
end expand;

function makeTree
  input list<SCode.Element> topClasses;
  output InstanceTree tree;
protected
  ClassTree.Tree scope;
  InstNode top;
algorithm
  // Add the given classes to a new instance tree.
  (scope, _, tree) := makeScope(topClasses, InstanceTree.new());
  // Update the top scope with the added classes.
  top := InstanceTree.lookupNode(NFInstanceTree.TOP_SCOPE, tree);
  top := InstNode.setInstance(top,
    Instance.INSTANCED_CLASS(scope, NFInstance.NO_COMPONENTS, {}, {}, {}, {}));
  tree := InstanceTree.updateNode(top, tree);
end makeTree;

function makeScope
  "Creates a new scope from a list of SCode elements. It returns a scope with
   all the classes added to it, a list of the non-class elements that were not
   added to the scope, and an updated instance tree."
  input list<SCode.Element> elements;
        output ClassTree.Tree scope "Tree with classes.";
        output list<SCode.Element> componentsExtends = {} "Components and extends.";
  input output InstanceTree tree;
protected
  Integer idx, scope_id;
  list<InstNode> il = {};
  InstNode node;
  list<SCode.Element> imports = {};
algorithm
  scope_id := InstanceTree.currentScopeIndex(tree);
  idx := InstanceTree.instanceCount(tree);
  scope := ClassTree.new();

  for e in elements loop
    _ := match e
      // A class, add a class node to the instance tree and a pointer to that
      // node in the class scope.
      case SCode.CLASS()
        algorithm
          idx := idx + 1;
          node := InstNode.new(e.name, e, idx, scope_id, InstParent.NO_PARENT());
          il := node :: il;
          scope := addElementIdToScope(e.name, ClassTree.Entry.CLASS(idx), e.info, scope);
        then
          ();

      // A component, add it to the list of non-class elements.
      case SCode.COMPONENT()
        algorithm
          componentsExtends := e :: componentsExtends;
        then
          ();

      // An extends, add it to the list of non-class elements.
      case SCode.EXTENDS()
        algorithm
          componentsExtends := e :: componentsExtends;
        then
          ();

      // An import, save it for later.
      case SCode.IMPORT()
        algorithm
          imports := e :: imports;
        then
          ();
    end match;
  end for;

  tree := InstanceTree.addInstances(Dangerous.listReverseInPlace(il), tree);
  (scope, tree) := addImportsToScope(imports, scope, tree);
end makeScope;

function addElementIdToScope
  input String name;
  input ClassTree.Entry id;
  input SourceInfo info;
  input output ClassTree.Tree scope;
algorithm
  try
    scope := ClassTree.add(scope, name, id, ClassTree.addConflictFail);
  else
    // TODO: Add proper error message.
    print("Duplicate element " + name + " found.\n");
    fail();
  end try;
end addElementIdToScope;

function addImportsToScope
  input list<SCode.Element> imports;
  input output ClassTree.Tree scope;
  input output InstanceTree tree;
protected
  Absyn.Import i;
  Integer scope_idx;
  InstNode node;
  SourceInfo info;
algorithm
  if listEmpty(imports) then
    return;
  end if;

  scope_idx := InstanceTree.currentScopeIndex(tree);

  for imp in imports loop
    SCode.IMPORT(imp = i, info = info) := imp;

    _ := match i
      case Absyn.NAMED_IMPORT()
        algorithm
          (node, tree) := Lookup.lookupClassName(Absyn.FULLYQUALIFIED(i.path), tree, info);
          scope := ClassTree.add(scope, i.name,
            ClassTree.Entry.CLASS(InstNode.index(node)));
        then
          ();

      case Absyn.QUAL_IMPORT()
        algorithm
          (node, tree) := Lookup.lookupClassName(Absyn.FULLYQUALIFIED(i.path), tree, info);
          scope := ClassTree.add(scope, Absyn.pathLastIdent(i.path),
            ClassTree.Entry.CLASS(InstNode.index(node)));
        then
          ();

      else ();
    end match;
  end for;

  tree := InstanceTree.setCurrentScopeIndex(tree, scope_idx);
end addImportsToScope;

function partialInstClass
  input output InstNode node;
  input output InstanceTree tree;
algorithm
  _ := match node
    local
      SCode.Element def;
      Instance instance;

    case InstNode.INST_NODE(instance = Instance.NOT_INSTANTIATED(), definition = SOME(def))
      algorithm
        tree := InstanceTree.setCurrentScope(tree, node);
        (instance, tree) := partialInstClass2(def, tree);
        node.instance := instance;
        tree := InstanceTree.updateNode(node, tree);
      then
        ();

    else ();
  end match;
end partialInstClass;

function partialInstClass2
  input SCode.Element definition;
        output Instance instance;
  input output InstanceTree tree;
protected
  SCode.ClassDef cdef;
  ClassTree.Tree classes;
  list<SCode.Element> elements;
algorithm
  instance := match definition
    case SCode.CLASS(classDef = cdef as SCode.PARTS())
      algorithm
        (classes, elements, tree) := makeScope(cdef.elementLst, tree);
      then
        Instance.PARTIAL_CLASS(classes, elements);

    else Instance.PARTIAL_CLASS(ClassTree.new(), {});
  end match;
end partialInstClass2;

function expandClass
  input output InstNode node;
  input InstParent parent;
  input output InstanceTree tree;
algorithm
  _ := match node
    local
      SCode.Element def;

    case InstNode.INST_NODE(instance = Instance.PARTIAL_CLASS(), definition = SOME(def))
      algorithm
        (node, tree) := expandClass2(node, def, parent, tree);
      then
        ();

    else ();
  end match;

  tree := InstanceTree.setCurrentScope(tree, node);
end expandClass;

function expandClass2
  input InstNode node;
  input SCode.Element definition;
  input InstParent parent;
        output InstNode expandedNode = node;
  input output InstanceTree tree;
algorithm
  _ := match definition
    local
      Absyn.TypeSpec ty;
      Absyn.Path ty_path;
      ClassTree.Tree scope;
      list<SCode.Element> elements;
      list<Component> components;
      array<Component> comp_array;
      Integer idx, scope_id;
      Instance i;
      InstNode inode;
      SCode.Mod der_mod;
      Modifier mod;
      SCode.ClassDef cdef;
      list<Equation> eq, ieq;
      list<list<Statement>> alg, ialg;
      SCode.Element def, ext;

    case def as SCode.CLASS(classDef = SCode.DERIVED(typeSpec = ty, modifications = der_mod))
      algorithm
        def := definition;
        ext := SCode.EXTENDS(Absyn.typeSpecPath(ty), SCode.PUBLIC(),
          der_mod, NONE(), Absyn.dummyInfo);
        def.classDef := SCode.PARTS({ext}, {}, {}, {}, {}, {}, {}, NONE());
        i := Instance.PARTIAL_CLASS(ClassTree.new(), {ext});
        inode := InstNode.setInstance(node, i);
        (expandedNode, tree) := expandClass2(inode, def, parent, tree);
      then
        ();
//    case SCode.CLASS(classDef = SCode.DERIVED(typeSpec = ty, modifications = der_mod))
//      algorithm
//        // TODO: Maybe derived classes do need their own scope, with all their children knowing which their parent is?
//
//        // TODO: Maybe do transformation: class A = B => class A extends B; end A;
//
//        // Derived classes have no scope of their own, use the parent scope.
//        scope_id := InstNode.parent(expandedNode);
//        tree := InstanceTree.setCurrentScopeIndex(tree, scope_id);
//
//        // Lookup and expand the derived class.
//        Absyn.TPATH(path = ty_path) := ty;
//        (expandedNode, tree) := Lookup.lookupClassName(ty_path, tree, definition.info);
//        (expandedNode, tree) := expand(expandedNode, tree);
//
//        // Process the modifier from the class.
//        mod := Modifier.create(der_mod, definition.name,
//          ModifierScope.CLASS_SCOPE(definition.name), scope_id);
//
//        // If we have a modifier, add it to the expanded instance.
//        if not Modifier.isEmpty(mod) then
//          expandedNode := InstNode.setInstance(expandedNode,
//            applyModifier(mod, InstNode.instance(expandedNode),
//              ModifierScope.CLASS_SCOPE(definition.name)));
//        end if;
//
//        // Update the expanded instance in the instance tree.
//        expandedNode := InstNode.setIndex(expandedNode, InstNode.index(node));
//        tree := InstanceTree.updateNode(expandedNode, tree);
//      then
//        ();

    case SCode.CLASS(classDef = cdef as SCode.PARTS())
      algorithm
        Instance.PARTIAL_CLASS(classes = scope, elements = elements) :=
          InstNode.instance(expandedNode);
        tree := InstanceTree.setCurrentScope(tree, expandedNode);
        i := Instance.initExpandedClass(scope);
        expandedNode := InstNode.setInstance(expandedNode, i);
        tree := InstanceTree.updateNode(expandedNode, tree);

        // Expand all extends clauses.
        (components, scope, tree) := expandExtends(elements, definition.name,
          scope, parent, tree);

        // Add component ids to the scope.
        idx := 1;
        for c in components loop
          if Component.isNamedComponent(c) then
            // TODO: Handle components with the same name.
            scope := ClassTree.add(scope, Component.name(c),
                ClassTree.Entry.COMPONENT(idx), ClassTree.addConflictReplace);
          end if;

          idx := idx + 1;
        end for;

        (eq, tree) := instEquations(cdef.normalEquationLst, tree);
        (ieq, tree) := instEquations(cdef.initialEquationLst, tree);
        (alg, tree) := instAlgorithmSections(cdef.normalAlgorithmLst, tree);
        (ialg, tree) := instAlgorithmSections(cdef.initialAlgorithmLst, tree);

        i := Instance.EXPANDED_CLASS(scope, listArray(components),
          eq, ieq, alg, ialg);

        // Update the instance in the tree.
        expandedNode := InstNode.setInstance(expandedNode, i);
        expandedNode := InstNode.setInstParent(expandedNode, parent);
        tree := InstanceTree.updateNode(expandedNode, tree);
      then
        ();

    else ();
  end match;
end expandClass2;

function expandExtends
  "This function takes a list of SCode elements and expands all the extends
   clauses. This means expanding the extended classes and inserting their
   contents into the scope and element list, as well as applying any modifiers
   from the extends clause to the inherited elements. The result is a list of
   components, both local and inherited, as well as a scope filled with local
   and inherited components and classes."
  input list<SCode.Element> elements;
  input String className;
        output list<Component> components = {};
  input output ClassTree.Tree scope;
  input InstParent parent;
  input output InstanceTree tree;
protected
  InstNode ext_node;
  list<SCode.Element> ext_comps;
  Integer scope_id = InstanceTree.currentScopeIndex(tree);
  Modifier mod;
  Instance ext_inst;
  ModifierScope mod_scope;
algorithm
  for e in elements loop
    _ := match e
      case SCode.EXTENDS()
        algorithm
          // Look up the name and expand the class.
          (ext_node, tree) := Lookup.lookupBaseClassName(e.baseClassPath, tree, e.info);
          ext_node := InstNode.setInstance(ext_node, Instance.NOT_INSTANTIATED());
          ext_node := InstNode.setIndex(ext_node, InstanceTree.instanceCount(tree) + 1);
          ext_node := InstNode.rename(ext_node, className);
          tree := InstanceTree.addInstances({ext_node}, tree);
          (ext_node, tree) := expand(ext_node, parent, tree);

          // Initialize the modifier from the extends clause.
          mod_scope := ModifierScope.EXTENDS_SCOPE(e.baseClassPath);
          mod := Modifier.create(e.modifications, "", mod_scope, scope_id);

          // Apply the modifier to the expanded instance of the extended class.
          ext_inst := InstNode.instance(ext_node);
          ext_inst := applyModifier(mod, ext_inst, mod_scope);
          ext_node := InstNode.setInstance(ext_node, ext_inst);

          components := Component.EXTENDS_NODE(ext_node) :: components;
          components := addInheritedComponentRefs(ext_inst, components);
          scope := addInheritedClassRefs(ext_inst, scope);
        then
          ();

      case SCode.COMPONENT()
        algorithm
          // Make a class element and add it to the list of components.
          components := Component.COMPONENT_DEF(e, Modifier.NOMOD(), scope_id) :: components;
        then
          ();

      else
        algorithm
          print("expandExtends got unknown element!\n");
        then
          fail();

    end match;
  end for;
end expandExtends;

function applyModifier
  input Modifier modifier;
  input output Instance instance;
  input ModifierScope modifierScope;
algorithm
  _ := match instance
    local
      list<Modifier> mods;
      ClassTree.Tree elements;
      array<Component> components;
      ClassTree.Entry idx;
      Component comp;

    case Instance.EXPANDED_CLASS(elements = elements, components = components)
      algorithm
        mods := Modifier.toList(modifier);

        for m in mods loop
          // Skip empty modifiers.
          if Modifier.isEmpty(m) then
            continue;
          end if;

          // Fetch the element id for the element with the same name as the modifier.
          try
            idx := ClassTree.get(elements, Modifier.name(m));
          else
            Error.addSourceMessageAndFail(Error.MISSING_MODIFIED_ELEMENT,
              {Modifier.name(m), ModifierScope.name(modifierScope)}, Modifier.info(m));
          end try;

          _ := match idx
            // Modifier is for a component, add it to the component in the array.
            case ClassTree.Entry.COMPONENT()
              algorithm
                comp := components[idx.id];
                components[idx.id] := Component.setModifier(m, comp);
              then
                ();

            case ClassTree.Entry.CLASS()
              algorithm
                print("IMPLEMENT ME: Class modifier.\n");
              then
                ();

          end match;
        end for;
      then
        ();

    case Instance.PARTIAL_BUILTIN()
      algorithm
        instance.modifier := Modifier.merge(modifier, instance.modifier);
      then
        ();

  end match;
end applyModifier;

function addInheritedComponentRefs
  input Instance extendsInstance;
  input output list<Component> components;
protected
  Integer node_idx = listLength(components);
  Integer idx = 0;
algorithm
  _ := match extendsInstance
    case Instance.EXPANDED_CLASS()
      algorithm
        for c in extendsInstance.components loop
          idx := idx + 1;
          components := Component.COMPONENT_REF(Component.name(c), node_idx, idx) :: components;
        end for;
      then
        ();
  end match;
end addInheritedComponentRefs;

function addInheritedClassRefs
  input Instance extendsInstance;
  input output ClassTree.Tree scope;
algorithm
  _ := match extendsInstance
    case Instance.EXPANDED_CLASS()
      algorithm
        scope := ClassTree.fold(extendsInstance.elements, addInheritedClassRefs2, scope);
      then
        ();
  end match;
end addInheritedClassRefs;

function addInheritedClassRefs2
  input String name;
  input ClassTree.Entry id;
  input ClassTree.Tree inScope;
  output ClassTree.Tree scope;
algorithm
  scope := match id
    case ClassTree.Entry.CLASS() then ClassTree.add(inScope, name, id);
    else inScope;
  end match;
end addInheritedClassRefs2;

function instClass
  input output InstNode node;
  input Modifier modifier;
  input output InstanceTree tree;
algorithm
  _ := match node
    local
      Instance i, i_mod;
      array<Component> components;
      ClassTree.Tree scope;
      Integer comp_count, idx;
      Modifier type_mod;
      list<Modifier> type_mods, inst_type_mods;
      Binding binding;

    // A normal class.
    case InstNode.INST_NODE(instance = i as Instance.EXPANDED_CLASS(elements = scope))
      algorithm
        comp_count := arrayLength(i.components);
        tree := InstanceTree.setCurrentScope(tree, node);

        if comp_count > 0 then
          components := Dangerous.arrayCreateNoInit(comp_count,
            Dangerous.arrayGetNoBoundsChecking(i.components, 1));

          i_mod := applyModifier(modifier, i, ModifierScope.CLASS_SCOPE(InstNode.name(node)));
          idx := 1;
          for c in Instance.components(i_mod) loop
            (c, tree) := instComponent(c, tree);
            Dangerous.arrayUpdateNoBoundsChecking(components, idx, c);
            idx := idx + 1;
          end for;
        else
          components := i.components;
        end if;

        node.instance := Instance.INSTANCED_CLASS(scope, components,
            i.equations, i.initialEquations, i.algorithms, i.initialAlgorithms);
      then
        ();

    // A builtin type.
    case InstNode.INST_NODE(instance = i as Instance.PARTIAL_BUILTIN())
      algorithm
        inst_type_mods := {};
        // Merge any outer modifiers on the class with the class' own modifier.
        type_mod := Modifier.merge(modifier, i.modifier);

        // If the modifier isn't empty, instantiate it.
        if not Modifier.isEmpty(type_mod) then
          type_mods := Modifier.toList(type_mod);

          // Instantiate the binding of each submodifier.
          for m in type_mods loop
            _ := match m
              case Modifier.MODIFIER()
                algorithm
                  (binding, tree) := instBinding(m.binding, tree);
                  m.binding := binding;
                then
                  ();

              else ();
            end match;

            inst_type_mods := m :: inst_type_mods;
          end for;
        end if;

        node.instance := Instance.INSTANCED_BUILTIN(inst_type_mods);
      then
        ();

    else ();
  end match;
end instClass;

function instComponent
  input output Component component;
  input output InstanceTree tree;
protected
  SCode.Element comp;
  InstNode cls;
  Modifier comp_mod;
  Binding binding;
  DAE.Type ty;
  Component redecl_comp;
  Component.Attributes attr;
  list<Dimension> dims;
  Integer scope;
algorithm
  (component, tree) := match component
    case Component.COMPONENT_DEF(modifier = comp_mod as Modifier.REDECLARE())
      algorithm
        redecl_comp := Component.COMPONENT_DEF(comp_mod.element, Modifier.NOMOD(), comp_mod.scope);
      then
        instComponent(redecl_comp, tree);

    case Component.COMPONENT_DEF(definition = comp as SCode.COMPONENT())
      algorithm
        scope := InstanceTree.currentScopeIndex(tree);
        tree := InstanceTree.setCurrentScopeIndex(tree, component.scope);
        comp_mod := Modifier.create(comp.modifications, comp.name,
          ModifierScope.COMPONENT_SCOPE(comp.name), component.scope);
        comp_mod := Modifier.merge(component.modifier, comp_mod);
        comp_mod := Modifier.propagate(comp_mod, listLength(comp.attributes.arrayDims));
        (cls, tree) := instTypeSpec(comp.typeSpec, comp_mod,
          InstParent.COMPONENT(component), comp.info, tree);
        (dims, tree) := instDimensions(comp.attributes.arrayDims, tree);
        Modifier.checkEach(comp_mod, listEmpty(dims), comp.name);
        attr := instComponentAttributes(comp.attributes, comp.prefixes);
        binding := Modifier.binding(comp_mod);
        tree := InstanceTree.setCurrentScopeIndex(tree, scope);
      then
        (Component.UNTYPED_COMPONENT(comp.name, cls, listArray(dims), binding, attr, comp.info), tree);

    case Component.EXTENDS_NODE()
      algorithm
        (cls, tree) := instClass(component.node, Modifier.NOMOD(), tree);
        component.node := cls;
      then
        (component, tree);

    else (component, tree);
  end match;
end instComponent;

function instComponentAttributes
  input SCode.Attributes compAttr;
  input SCode.Prefixes compPrefs;
  output Component.Attributes attributes;
protected
  DAE.VarKind variability;
  DAE.VarDirection direction;
  DAE.VarVisibility visiblity;
  DAE.ConnectorType connectorType;
algorithm
  variability := InstUtil.translateVariability(compAttr.variability);
  direction := InstUtil.translateDirection(compAttr.direction);
  visiblity := InstUtil.translateVisibility(compPrefs.visibility);
  connectorType := InstUtil.translateConnectorType(compAttr.connectorType);
  attributes := Component.Attributes.ATTRIBUTES(variability, direction, visiblity, connectorType);
end instComponentAttributes;

function instTypeSpec
  input Absyn.TypeSpec typeSpec;
  input Modifier modifier;
  input InstParent parent;
  input SourceInfo info;
        output InstNode node;
  input output InstanceTree tree;
algorithm
  (node, tree) := match typeSpec
    case Absyn.TPATH()
      algorithm
        (node, tree) := Lookup.lookupClassName(typeSpec.path, tree, info);
        (node, tree) := instantiate(node, modifier, parent, tree);
      then
        (node, tree);

    case Absyn.TCOMPLEX()
      algorithm
        print("NFInst.instTypeSpec: TCOMPLEX not implemented.\n");
      then
        fail();

  end match;
end instTypeSpec;

function instModifier
  input output Modifier modifier;
  input output InstanceTree tree;
algorithm

end instModifier;

function instDimension
  input Absyn.Subscript subscript;
        output Dimension dimension;
  input output InstanceTree tree;
algorithm
  dimension := match subscript
    local
      Absyn.Exp exp;
      DAE.Exp dim_exp;
      DAE.Dimension dim;

    case Absyn.NOSUB() then Dimension.TYPED_DIM(DAE.Dimension.DIM_UNKNOWN());
    case Absyn.SUBSCRIPT(subscript = exp)
      algorithm
        (exp, tree) := instExp(exp, tree);
      then
        Dimension.UNTYPED_DIM(exp, false);
    //case Absyn.SUBSCRIPT(subscript = exp)
    //  algorithm
    //    dim := match exp
    //      // Convert integer and boolean literals directly to the appropriate dimension.
    //      case Absyn.Exp.INTEGER() then DAE.Dimension.DIM_INTEGER(exp.value);
    //      else
    //        algorithm // Any other expression needs to be instantiated.
    //          (dim_exp, tree) := Inst.instExp(exp, tree);
    //        then
    //          DAE.Dimension.DIM_EXP(dim_exp);
    //    end match;
    //  then
    //    new(dim);
  end match;
end instDimension;

function instDimensions
  input Absyn.ArrayDim absynDims;
        output list<Dimension> dims;
  input output InstanceTree tree;
algorithm
  (dims, tree) := List.mapFold(absynDims, instDimension, tree);
end instDimensions;

function instBindings
  input output InstNode node;
  input output InstanceTree tree;
algorithm
  _ := match node
    local
      Integer idx;
      array<Component> components;

    case InstNode.INST_NODE(instance = Instance.INSTANCED_CLASS(components = components))
      algorithm
        idx := 1;
        for comp in components loop
          arrayUpdate(components, idx, instComponentBinding(comp, tree));
          idx := +idx + 1;
        end for;
      then
        ();

    else ();
  end match;
end instBindings;

function instComponentBinding
  input output Component component;
  input output InstanceTree tree;
algorithm
  _ := match component
    local
      InstNode cls;
      Binding binding;

    case Component.UNTYPED_COMPONENT(classInst = cls)
      algorithm
        (cls, tree) := instBindings(component.classInst, tree);
        component.classInst := cls;
        (binding, tree) := instBinding(component.binding, tree);
        component.binding := binding;
      then
        ();

    case Component.EXTENDS_NODE()
      algorithm
        (cls, tree) := instBindings(component.node, tree);
        component.node := cls;
      then
        ();

    else ();
  end match;
end instComponentBinding;

function instBinding
  input output Binding binding;
  input output InstanceTree tree;
algorithm
  binding := match binding
    local
      Absyn.Exp bind_exp;

    case Binding.RAW_BINDING()
      algorithm
        (bind_exp, tree) := instExp(binding.bindingExp, tree);
      then
        Binding.UNTYPED_BINDING(bind_exp, false, binding.scope, binding.propagatedDims, binding.info);

    else binding;
  end match;
end instBinding;

function instExpOpt
  input output Option<Absyn.Exp> optExp;
  input output InstanceTree tree;
algorithm
  optExp := match optExp
    local
      Absyn.Exp exp;

    case NONE() then NONE();
    case SOME(exp)
      algorithm
        (exp, tree) := instExp(exp, tree);
      then
        SOME(exp);

  end match;
end instExpOpt;

function instExp
  input output Absyn.Exp absynExp;
  input output InstanceTree tree;
algorithm
  //daeExp := match absynExp
  //  local
  //    DAE.Exp exp1, exp2;
  //    DAE.Operator op;
  //    list<DAE.Exp> expl;

  //  case Absyn.INTEGER() then DAE.ICONST(absynExp.value);
  //  case Absyn.REAL() then DAE.RCONST(stringReal(absynExp.value));
  //  case Absyn.STRING() then DAE.SCONST(absynExp.value);
  //  case Absyn.BOOL() then DAE.BCONST(absynExp.value);
  //  case Absyn.CREF()
  //    algorithm
  //      (daeExp, tree) := instCref(absynExp.componentRef, tree);
  //    then
  //      daeExp;

  //  case Absyn.BINARY()
  //    algorithm
  //      (exp1, tree) := instExp(absynExp.exp1, tree);
  //      (exp2, tree) := instExp(absynExp.exp2, tree);
  //      op := instOperator(absynExp.op);
  //    then
  //      DAE.BINARY(exp1, op, exp2);

  //  case Absyn.UNARY()
  //    algorithm
  //      (exp1, tree) := instExp(absynExp.exp, tree);
  //      op := instOperator(absynExp.op);
  //    then
  //      DAE.UNARY(op, exp1);

  //  case Absyn.LBINARY()
  //    algorithm
  //      (exp1, tree) := instExp(absynExp.exp1, tree);
  //      (exp2, tree) := instExp(absynExp.exp2, tree);
  //      op := instOperator(absynExp.op);
  //    then
  //      DAE.LBINARY(exp1, op, exp2);

  //  case Absyn.LUNARY()
  //    algorithm
  //      (exp1, tree) := instExp(absynExp.exp, tree);
  //      op := instOperator(absynExp.op);
  //    then
  //      DAE.LUNARY(op, exp1);

  //  case Absyn.RELATION()
  //    algorithm
  //      (exp1, tree) := instExp(absynExp.exp1, tree);
  //      (exp2, tree) := instExp(absynExp.exp2, tree);
  //      op := instOperator(absynExp.op);
  //    then
  //      DAE.RELATION(exp1, op, exp2, 0, NONE());

  //  case Absyn.ARRAY()
  //    algorithm
  //      (expl, tree) := List.mapFold(absynExp.arrayExp, instExp, tree);
  //    then
  //      DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, expl);

  //  case Absyn.MATRIX()
  //    algorithm
  //      (expl, tree) := List.mapFold(list(Absyn.ARRAY(e) for e in absynExp.matrix), instExp, tree);
  //    then
  //      DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, expl);

  //  else DAE.SCONST("ERROR");
  //end match;
end instExp;

function instCref
  input output Absyn.ComponentRef cref;
  input output InstanceTree tree;
algorithm

  //daeCref := match absynCref
  //  local
  //    DAE.ComponentRef cref;

  //  case Absyn.CREF_IDENT()
  //    then DAE.CREF_IDENT(absynCref.name, DAE.T_UNKNOWN_DEFAULT, {});

  //  case Absyn.CREF_QUAL()
  //    algorithm
  //      (cref, tree) := instCref(absynCref.componentRef, tree);
  //    then
  //      DAE.CREF_QUAL(absynCref.name, DAE.T_UNKNOWN_DEFAULT, {}, cref);

  //  case Absyn.CREF_FULLYQUALIFIED()
  //    algorithm
  //      (cref, tree) := instCref(absynCref.componentRef, tree);
  //    then
  //      cref;

  //  case Absyn.WILD() then DAE.WILD();
  //  case Absyn.ALLWILD() then DAE.WILD();

  //end match;
end instCref;

function instEquations
  input list<SCode.Equation> scodeEql;
        output list<Equation> instEql;
  input output InstanceTree tree;
algorithm
  (instEql, tree) := List.mapFold(scodeEql, instEquation, tree);
end instEquations;

function instEquation
  input SCode.Equation scodeEq;
        output Equation instEq;
  input output InstanceTree tree;
protected
  SCode.EEquation eq;
algorithm
  SCode.EQUATION(eEquation = eq) := scodeEq;
  instEq := instEEquation(eq, tree);
end instEquation;

function instEEquations
  input list<SCode.EEquation> scodeEql;
        output list<Equation> instEql;
  input output InstanceTree tree;
algorithm
  (instEql, tree) := List.mapFold(scodeEql, instEEquation, tree);
end instEEquations;

function instEEquation
  input SCode.EEquation scodeEq;
        output Equation instEq;
  input output InstanceTree tree;
algorithm
  instEq := match scodeEq
    local
      Absyn.Exp exp1, exp2, exp3;
      Absyn.ComponentRef cr1, cr2;
      Option<Absyn.Exp> oexp;
      list<Equation> eql;
      list<Absyn.Exp> expl;
      list<tuple<Absyn.Exp, list<Equation>>> branches;

    case SCode.EQ_EQUALS()
      algorithm
        (exp1, tree) := instExp(scodeEq.expLeft, tree);
        (exp2, tree) := instExp(scodeEq.expRight, tree);
      then
        Equation.UNTYPED_EQUALITY(exp1, exp2, scodeEq.info);

    case SCode.EQ_CONNECT()
      algorithm
        (cr1, tree) := instCref(scodeEq.crefLeft, tree);
        (cr2, tree) := instCref(scodeEq.crefRight, tree);
      then
        Equation.UNTYPED_CONNECT(cr1, cr2, scodeEq.info);

    case SCode.EQ_FOR()
      algorithm
        (oexp, tree) := instExpOpt(scodeEq.range, tree);
        (eql, tree) := instEEquations(scodeEq.eEquationLst, tree);
      then
        Equation.UNTYPED_FOR(scodeEq.index, oexp, eql, scodeEq.info);

    case SCode.EQ_IF()
      algorithm
        // Instantiate the conditions.
        (expl, tree) := List.mapFold(scodeEq.condition, instExp, tree);

        // Instantiate each branch and pair it up with a condition.
        branches := {};
        for branch in scodeEq.thenBranch loop
          (eql, tree) := instEEquations(scodeEq.elseBranch, tree);
          exp1 :: expl := expl;
          branches := (exp1, eql) :: branches;
        end for;

        // Instantiate the else-branch, if there is one, and make it a branch
        // with condition true.
        if not listEmpty(scodeEq.elseBranch) then
          (eql, tree) := instEEquations(scodeEq.elseBranch, tree);
          branches := (Absyn.BOOL(true), eql) :: branches;
        end if;
      then
        Equation.UNTYPED_IF(listReverse(branches), scodeEq.info);

    case SCode.EQ_WHEN()
      algorithm
        (exp1, tree) := instExp(scodeEq.condition, tree);
        (eql, tree) := instEEquations(scodeEq.eEquationLst, tree);
        branches := {(exp1, eql)};

        for branch in scodeEq.elseBranches loop
          (exp1, tree) := instExp(Util.tuple21(branch), tree);
          (eql, tree) := instEEquations(Util.tuple22(branch), tree);
          branches := (exp1, eql) :: branches;
        end for;
      then
        Equation.UNTYPED_WHEN(branches, scodeEq.info);

    case SCode.EQ_ASSERT()
      algorithm
        (exp1, tree) := instExp(scodeEq.condition, tree);
        (exp2, tree) := instExp(scodeEq.message, tree);
        (exp3, tree) := instExp(scodeEq.level, tree);
      then
        Equation.UNTYPED_ASSERT(exp1, exp2, exp3, scodeEq.info);

    case SCode.EQ_TERMINATE()
      algorithm
        (exp1, tree) := instExp(scodeEq.message, tree);
      then
        Equation.UNTYPED_TERMINATE(exp1, scodeEq.info);

    case SCode.EQ_REINIT()
      algorithm
        (cr1, tree) := instCref(scodeEq.cref, tree);
        (exp1, tree) := instExp(scodeEq.expReinit, tree);
      then
        Equation.UNTYPED_REINIT(cr1, exp1, scodeEq.info);

    case SCode.EQ_NORETCALL()
      algorithm
        (exp1, tree) := instExp(scodeEq.exp, tree);
      then
        Equation.UNTYPED_NORETCALL(exp1, scodeEq.info);

    else
      algorithm
        Error.addInternalError("NFInst.instEEquation: Unknown equation",
          SCode.getEEquationInfo(scodeEq));
      then
        fail();

  end match;
end instEEquation;

function instAlgorithmSections
  input list<SCode.AlgorithmSection> algorithmSections;
        output list<list<Statement>> statements;
  input output InstanceTree tree;
algorithm
  (statements, tree) := List.mapFold(algorithmSections, instAlgorithmSection, tree);
end instAlgorithmSections;

function instAlgorithmSection
  input SCode.AlgorithmSection algorithmSection;
        output list<Statement> statements;
  input output InstanceTree tree;
algorithm
  (statements, tree) := instStatements(algorithmSection.statements, tree);
end instAlgorithmSection;

function instStatements
  input list<SCode.Statement> scodeStmtl;
        output list<Statement> statements;
  input output InstanceTree tree;
algorithm
  (statements, tree) := List.mapFold(scodeStmtl, instStatement, tree);
end instStatements;

function instStatement
  input SCode.Statement scodeStmt;
        output Statement statement;
  input output InstanceTree tree;
algorithm
  statement := match scodeStmt
    local
      Absyn.Exp exp1, exp2, exp3;
      Absyn.ComponentRef cr;
      Option<Absyn.Exp> oexp;
      list<Statement> stmtl;
      list<tuple<Absyn.Exp, list<Statement>>> branches;

    case SCode.ALG_ASSIGN()
      algorithm
        (exp1, tree) := instExp(scodeStmt.assignComponent, tree);
        (exp2, tree) := instExp(scodeStmt.value, tree);
      then
        Statement.UNTYPED_ASSIGNMENT(exp1, exp2, scodeStmt.info);

    case SCode.ALG_FOR()
      algorithm
        (oexp, tree) := instExpOpt(scodeStmt.range, tree);
        (stmtl, tree) := instStatements(scodeStmt.forBody, tree);
      then
        Statement.UNTYPED_FOR(scodeStmt.index, oexp, stmtl, scodeStmt.info);

    case SCode.ALG_IF()
      algorithm
        branches := {};
        for branch in (scodeStmt.boolExpr, scodeStmt.trueBranch) :: scodeStmt.elseIfBranch loop
          (exp1, tree) := instExp(Util.tuple21(branch), tree);
          (stmtl, tree) := instStatements(Util.tuple22(branch), tree);
          branches := (exp1, stmtl) :: branches;
        end for;

        (stmtl, tree) := instStatements(scodeStmt.elseBranch, tree);
        branches := listReverse((Absyn.BOOL(true), stmtl) :: branches);
      then
        Statement.UNTYPED_IF(branches, scodeStmt.info);

    case SCode.ALG_WHEN_A()
      algorithm
        branches := {};
        for branch in scodeStmt.branches loop
          (exp1, tree) := instExp(Util.tuple21(branch), tree);
          (stmtl, tree) := instStatements(Util.tuple22(branch), tree);
          branches := (exp1, stmtl) :: branches;
        end for;
      then
        Statement.UNTYPED_WHEN(listReverse(branches), scodeStmt.info);

    case SCode.ALG_ASSERT()
      algorithm
        (exp1, tree) := instExp(scodeStmt.condition, tree);
        (exp2, tree) := instExp(scodeStmt.message, tree);
        (exp3, tree) := instExp(scodeStmt.level, tree);
      then
        Statement.UNTYPED_ASSERT(exp1, exp2, exp3, scodeStmt.info);

    case SCode.ALG_TERMINATE()
      algorithm
        (exp1, tree) := instExp(scodeStmt.message, tree);
      then
        Statement.UNTYPED_TERMINATE(exp1, scodeStmt.info);

    case SCode.ALG_REINIT()
      algorithm
        (cr, tree) := instCref(scodeStmt.cref, tree);
        (exp1, tree) := instExp(scodeStmt.newValue, tree);
      then
        Statement.UNTYPED_REINIT(cr, exp1, scodeStmt.info);

    case SCode.ALG_NORETCALL()
      algorithm
        (exp1, tree) := instExp(scodeStmt.exp, tree);
      then
        Statement.UNTYPED_NORETCALL(exp1, scodeStmt.info);

    case SCode.ALG_WHILE()
      algorithm
        (exp1, tree) := instExp(scodeStmt.boolExpr, tree);
        (stmtl, tree) := instStatements(scodeStmt.whileBody, tree);
      then
        Statement.UNTYPED_WHILE(exp1, stmtl, scodeStmt.info);

    case SCode.ALG_RETURN() then Statement.RETURN(scodeStmt.info);
    case SCode.ALG_BREAK() then Statement.BREAK(scodeStmt.info);

    case SCode.ALG_FAILURE()
      algorithm
        (stmtl, tree) := instStatements(scodeStmt.stmts, tree);
      then
        Statement.FAILURE(stmtl, scodeStmt.info);

    else
      algorithm
        Error.addInternalError("NFInst.instStatement: Unknown statement",
          SCode.getStatementInfo(scodeStmt));
      then
        fail();

  end match;
end instStatement;

annotation(__OpenModelica_Interface="frontend");
end NFInst;
