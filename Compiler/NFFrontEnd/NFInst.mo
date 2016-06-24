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
import NFInstance.ClassTree;
import NFInstance.ElementId;
import NFInstance.Instance;
import NFInstanceTree.InstanceTree;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFMod.ModifierScope;

protected
import Error;
import Flatten = NFFlatten;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import System;

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
  (cls, inst_tree) := instantiate(cls, Modifier.NOMOD(), inst_tree);

  (cls, inst_tree) := instBindings(cls, inst_tree);

  dae := NFFlatten.flattenClass(cls);

  System.stopTimer();
  //print("NFInst done in " + String(System.getTimerIntervalTime()) + "\n");
end instClassInProgram;

function instantiate
  input output InstNode node;
  input Modifier modifier;
  input output InstanceTree tree;
algorithm
  (node, tree) := partialInstClass(node, tree);
  (node, tree) := expandClass(node, tree);
  (node, tree) := instClass(node, modifier, tree);
end instantiate;

function expand
  input output InstNode node;
  input output InstanceTree tree;
algorithm
  (node, tree) := partialInstClass(node, tree);
  (node, tree) := expandClass(node, tree);
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
    Instance.INSTANCED_CLASS(scope, NFInstance.NO_COMPONENTS));
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
          node := InstNode.new(e.name, e, idx, scope_id);
          il := node :: il;
          scope := addElementIdToScope(e.name, ElementId.CLASS_ID(idx), e.info, scope);
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
  input ElementId id;
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
            ElementId.CLASS_ID(InstNode.index(node)));
        then
          ();

      case Absyn.QUAL_IMPORT()
        algorithm
          (node, tree) := Lookup.lookupClassName(Absyn.FULLYQUALIFIED(i.path), tree, info);
          scope := ClassTree.add(scope, Absyn.pathLastIdent(i.path),
            ElementId.CLASS_ID(InstNode.index(node)));
        then
          ();

      else ();
    end match;
  end for;

  tree := InstanceTree.setCurrentScope(tree, scope_idx);
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
        tree := InstanceTree.setCurrentScope(tree, InstNode.index(node));
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
  input output InstanceTree tree;
algorithm
  _ := match node
    local
      SCode.Element def;

    case InstNode.INST_NODE(instance = Instance.PARTIAL_CLASS(), definition = SOME(def))
      algorithm
        (node, tree) := expandClass2(node, def, tree);
      then
        ();

    else ();
  end match;

  tree := InstanceTree.setCurrentScope(tree, InstNode.index(node));
end expandClass;

function expandClass2
  input InstNode node;
  input SCode.Element definition;
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
      SCode.Mod der_mod;
      Modifier mod;

    case SCode.CLASS(classDef = SCode.DERIVED(typeSpec = ty, modifications = der_mod))
      algorithm
        // Derived classes have no scope of their own, use the parent scope.
        scope_id := InstNode.parent(expandedNode);
        tree := InstanceTree.setCurrentScope(tree, scope_id);

        // Lookup and expand the derived class.
        Absyn.TPATH(path = ty_path) := ty;
        (expandedNode, tree) := Lookup.lookupClassName(ty_path, tree, definition.info);
        (expandedNode, tree) := expand(expandedNode, tree);

        // Process the modifier from the class.
        mod := Modifier.create(der_mod, definition.name,
          ModifierScope.CLASS_SCOPE(definition.name), scope_id);

        // If we have a modifier, add it to the expanded instance.
        if not Modifier.isEmpty(mod) then
          expandedNode := InstNode.setInstance(expandedNode,
            applyModifier(mod, InstNode.instance(expandedNode)));
        end if;

        // Update the expanded instance in the instance tree.
        expandedNode := InstNode.setIndex(expandedNode, InstNode.index(node));
        tree := InstanceTree.updateNode(expandedNode, tree);
      then
        ();

    case SCode.CLASS(classDef = SCode.PARTS())
      algorithm
        Instance.PARTIAL_CLASS(classes = scope, elements = elements) :=
          InstNode.instance(expandedNode);
        tree := InstanceTree.setCurrentScope(tree, InstNode.index(expandedNode));
        i := Instance.initExpandedClass(scope);
        expandedNode := InstNode.setInstance(expandedNode, i);
        tree := InstanceTree.updateNode(expandedNode, tree);

        // Expand all extends clauses.
        (components, scope, tree) := expandExtends(elements, scope, tree);

        // Add component ids to the scope.
        idx := 1;
        for c in components loop
          // TODO: Handle components with the same name.
          scope := ClassTree.add(scope, Component.name(c),
              ElementId.COMPONENT_ID(idx), ClassTree.addConflictReplace);
          idx := idx + 1;
        end for;

        i := Instance.setElements(scope, i);

        // Add the components to the instance.
        i := Instance.setComponents(listArray(components), i);
        expandedNode := InstNode.setInstance(expandedNode, i);
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
        output list<Component> components = {};
  input output ClassTree.Tree scope;
  input output InstanceTree tree;
protected
  InstNode ext_node;
  list<SCode.Element> ext_comps;
  Integer scope_id = InstanceTree.currentScopeIndex(tree);
  Modifier mod;
  Instance ext_inst;
algorithm
  for e in elements loop
    _ := match e
      case SCode.EXTENDS()
        algorithm
          // Look up the name and expand the class.
          (ext_node, tree) := Lookup.lookupBaseClassName(e.baseClassPath, tree, e.info);
          (ext_node, tree) := expand(ext_node, tree);

          // Initialize the modifier from the extends clause.
          mod := Modifier.create(e.modifications, "",
            ModifierScope.EXTENDS_SCOPE(e.baseClassPath), InstNode.index(ext_node));

          // Apply the modifier to the expanded instance of the extended class.
          ext_inst := InstNode.instance(ext_node);
          ext_inst := applyModifier(mod, ext_inst);

          // Add the inherited elements to the extending class.
          (scope, components) := mergeInheritedElements(InstNode.instance(ext_node),
            e.modifications, scope, components);
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
algorithm
  _ := match instance
    local
      list<Modifier> mods;
      ClassTree.Tree elements;
      array<Component> components;
      ElementId idx;

    case Instance.EXPANDED_CLASS(elements = elements, components = components)
      algorithm
        mods := Modifier.toList(modifier);

        for m in mods loop
          // Skip empty modifiers.
          if Modifier.isEmpty(m) then
            continue;
          end if;

          // Fetch the element id for the element with the same name as the modifier.
          idx :=  ClassTree.get(elements, Modifier.name(m));

          _ := match idx
            // Modifier is for a component, add it to the component in the array.
            case ElementId.COMPONENT_ID()
              algorithm
                arrayUpdate(components, idx.id,
                  Component.setModifier(m, arrayGet(components, idx.id)));
              then
                ();

            case ElementId.CLASS_ID()
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

function mergeInheritedElements
  input Instance extClass;
  input SCode.Mod modifier;
  input output ClassTree.Tree scope;
  input output list<Component> components;
algorithm
  (scope, components) := match extClass
    local
      String name;
      Modifier mod;

    case Instance.EXPANDED_CLASS()
      algorithm
        // Copy the classes from the derived class into the deriving class' scope.
        scope := ClassTree.fold(extClass.elements, mergeInheritedElements2, scope);


        // Components are not added to the scope yet since they need to be
        // given a unique array index, so just collect them for later.
        components := listAppend(arrayList(extClass.components), components);
      then
        (scope, components);

  end match;
end mergeInheritedElements;

function mergeInheritedElements2
  input String name;
  input ElementId id;
  input ClassTree.Tree inScope;
  output ClassTree.Tree scope;
algorithm
  scope := match id
    case ElementId.CLASS_ID() then ClassTree.add(inScope, name, id);
    else inScope;
  end match;
end mergeInheritedElements2;

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

        if comp_count > 0 then
          tree := InstanceTree.setCurrentScope(tree, InstNode.index(node));

          components := Dangerous.arrayCreateNoInit(comp_count,
            Dangerous.arrayGetNoBoundsChecking(i.components, 1));

          i_mod := applyModifier(modifier, i);
          idx := 1;
          for c in Instance.components(i_mod) loop
            (c, tree) := instComponent(c, tree);
            Dangerous.arrayUpdateNoBoundsChecking(components, idx, c);
            idx := idx + 1;
          end for;
        else
          components := i.components;
        end if;

        node.instance := Instance.INSTANCED_CLASS(scope, components);
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
algorithm
  (component, tree) := match component
    case Component.COMPONENT_DEF(modifier = comp_mod as Modifier.REDECLARE())
      algorithm
        redecl_comp := Component.COMPONENT_DEF(comp_mod.element, Modifier.NOMOD(), comp_mod.scope);
      then
        instComponent(redecl_comp, tree);

    case Component.COMPONENT_DEF(definition = comp as SCode.COMPONENT())
      algorithm
        tree := InstanceTree.setCurrentScope(tree, component.scope);
        comp_mod := Modifier.create(comp.modifications, comp.name,
          ModifierScope.COMPONENT_SCOPE(comp.name), component.scope);
        comp_mod := Modifier.merge(component.modifier, comp_mod);
        binding := Modifier.binding(comp_mod);
        (cls, tree) := instTypeSpec(comp.typeSpec, comp_mod, comp.info, tree);
        ty := makeType(cls);
        attr := instComponentAttributes(comp.attributes, comp.prefixes);
      then
        (Component.COMPONENT(comp.name, cls, ty, binding, attr), tree);

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
  input SourceInfo info;
        output InstNode node;
  input output InstanceTree tree;
algorithm
  (node, tree) := match typeSpec
    case Absyn.TPATH()
      algorithm
        (node, tree) := Lookup.lookupClassName(typeSpec.path, tree, info);
        (node, tree) := instantiate(node, modifier, tree);
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

function makeType
  input InstNode node;
  output DAE.Type ty;
algorithm
  ty := match node
    local
      list<Modifier> type_mods;
      list<DAE.Var> type_attr;

    case InstNode.INST_NODE(instance = Instance.INSTANCED_CLASS())
      then DAE.T_COMPLEX_DEFAULT;

    case InstNode.INST_NODE(instance = Instance.INSTANCED_BUILTIN(attributes = type_mods))
      algorithm
        type_attr := list(makeTypeAttribute(m) for m in type_mods);
      then
        match node.name
          case "Real" then DAE.T_REAL(type_attr, DAE.emptyTypeSource);
          case "Integer" then DAE.T_INTEGER(type_attr, DAE.emptyTypeSource);
          case "Boolean" then DAE.T_BOOL(type_attr, DAE.emptyTypeSource);
          case "String" then DAE.T_STRING(type_attr, DAE.emptyTypeSource);
          else DAE.T_UNKNOWN_DEFAULT;
        end match;

    else DAE.T_UNKNOWN_DEFAULT;
  end match;
end makeType;

function makeTypeAttribute
  input Modifier modifier;
  output DAE.Var attribute;
algorithm
  attribute := match modifier
    local
      DAE.Exp exp;
      DAE.Binding binding;

    case Modifier.MODIFIER(binding = Binding.UNTYPED_BINDING(bindingExp = exp))
      algorithm
        binding := DAE.EQBOUND(exp, NONE(), DAE.C_UNKNOWN(),
          DAE.BindingSource.BINDING_FROM_START_VALUE());
      then
        DAE.TYPES_VAR(modifier.name, DAE.dummyAttrVar, DAE.T_UNKNOWN_DEFAULT, binding, NONE());

    else
      algorithm
        print("NFInst.makeTypeAttribute: Bad modifier\n");
      then
        fail();

  end match;
end makeTypeAttribute;

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

    case Component.COMPONENT(classInst = cls)
      algorithm
        (cls, tree) := instBindings(component.classInst, tree);
        component.classInst := cls;
        (binding, tree) := instBinding(component.binding, tree);
        component.binding := binding;
      then
        ();

  end match;
end instComponentBinding;

function instBinding
  input output Binding binding;
  input output InstanceTree tree;
algorithm
  binding := match binding
    local
      DAE.Exp bind_exp;

    case Binding.RAW_BINDING()
      algorithm
        (bind_exp, tree) := instExp(binding.bindingExp, tree);
      then
        Binding.UNTYPED_BINDING(bind_exp, false, 0, binding.info);

    else binding;
  end match;
end instBinding;

function instExp
  input Absyn.Exp absynExp;
  input InstanceTree inTree;
  output DAE.Exp daeExp;
  output InstanceTree tree = inTree;
algorithm
  daeExp := match absynExp
    local
      DAE.Exp exp1, exp2;
      DAE.Operator op;
      list<DAE.Exp> expl;

    case Absyn.INTEGER() then DAE.ICONST(absynExp.value);
    case Absyn.REAL() then DAE.RCONST(stringReal(absynExp.value));
    case Absyn.STRING() then DAE.SCONST(absynExp.value);
    case Absyn.BOOL() then DAE.BCONST(absynExp.value);
    case Absyn.CREF()
      algorithm
        (daeExp, tree) := instCref(absynExp.componentRef, tree);
      then
        daeExp;

    case Absyn.BINARY()
      algorithm
        (exp1, tree) := instExp(absynExp.exp1, tree);
        (exp2, tree) := instExp(absynExp.exp2, tree);
        op := instOperator(absynExp.op);
      then
        DAE.BINARY(exp1, op, exp2);

    case Absyn.UNARY()
      algorithm
        (exp1, tree) := instExp(absynExp.exp, tree);
        op := instOperator(absynExp.op);
      then
        DAE.UNARY(op, exp1);

    case Absyn.LBINARY()
      algorithm
        (exp1, tree) := instExp(absynExp.exp1, tree);
        (exp2, tree) := instExp(absynExp.exp2, tree);
        op := instOperator(absynExp.op);
      then
        DAE.LBINARY(exp1, op, exp2);

    case Absyn.LUNARY()
      algorithm
        (exp1, tree) := instExp(absynExp.exp, tree);
        op := instOperator(absynExp.op);
      then
        DAE.LUNARY(op, exp1);

    case Absyn.RELATION()
      algorithm
        (exp1, tree) := instExp(absynExp.exp1, tree);
        (exp2, tree) := instExp(absynExp.exp2, tree);
        op := instOperator(absynExp.op);
      then
        DAE.RELATION(exp1, op, exp2, 0, NONE());

    case Absyn.ARRAY()
      algorithm
        (expl, tree) := List.mapFold(absynExp.arrayExp, instExp, tree);
      then
        DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, expl);

    case Absyn.MATRIX()
      algorithm
        (expl, tree) := List.mapFold(list(Absyn.ARRAY(e) for e in absynExp.matrix), instExp, tree);
      then
        DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, expl);

    else DAE.SCONST("ERROR");
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

function instCref
  input Absyn.ComponentRef absynCref;
  input InstanceTree inTree;
  output DAE.Exp daeCref;
  output InstanceTree tree;
protected
  DAE.ComponentRef cref;
algorithm
  (cref, tree) := instCref2(absynCref, inTree);
  daeCref := DAE.CREF(cref, DAE.T_UNKNOWN_DEFAULT);
end instCref;

function instCref2
  input Absyn.ComponentRef absynCref;
  input InstanceTree inTree;
  output DAE.ComponentRef daeCref;
  output InstanceTree tree = inTree;
algorithm
  daeCref := match absynCref
    local
      DAE.ComponentRef cref;

    case Absyn.CREF_IDENT()
      then DAE.CREF_IDENT(absynCref.name, DAE.T_UNKNOWN_DEFAULT, {});

    case Absyn.CREF_QUAL()
      algorithm
        (cref, tree) := instCref2(absynCref.componentRef, tree);
      then
        DAE.CREF_QUAL(absynCref.name, DAE.T_UNKNOWN_DEFAULT, {}, cref);

    case Absyn.CREF_FULLYQUALIFIED()
      algorithm
        (cref, tree) := instCref2(absynCref.componentRef, tree);
      then
        cref;

    case Absyn.WILD() then DAE.WILD();
    case Absyn.ALLWILD() then DAE.WILD();

  end match;
end instCref2;

annotation(__OpenModelica_Interface="frontend");
end NFInst;
