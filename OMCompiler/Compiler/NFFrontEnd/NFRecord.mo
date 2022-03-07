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

encapsulated package NFRecord
" file:        NFRecord.mo
  package:     NFRecord
  description: package for handling records.


  Functions used by NFInst for handling records.
"

import Binding = NFBinding;
import Class = NFClass;
import Component = NFComponent;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import Type = NFType;
import Subscript = NFSubscript;
import InstContext = NFInstContext;

protected
import Inst = NFInst;
import Lookup = NFLookup;
import TypeCheck = NFTypeCheck;
import Typing = NFTyping;
import NFPrefixes.Direction;
import NFPrefixes.Variability;
import NFPrefixes.Visibility;
import NFFunction.Function;
import NFClassTree.ClassTree;
import ComplexType = NFComplexType;
import ComponentRef = NFComponentRef;
import NFFunction.FunctionStatus;
import MetaModelica.Dangerous.listReverseInPlace;
import UnorderedMap;
import UnorderedSet;

public

encapsulated uniontype Field
  record INPUT
    String name;
  end INPUT;

  record LOCAL
    String name;
  end LOCAL;

  function isInput
    input Field field;
    output Boolean isInput;
  algorithm
    isInput := match field
      case INPUT() then true;
      else false;
    end match;
  end isInput;

  function name
    input Field field;
    output String name;
  algorithm
    name := match field
      case INPUT() then field.name;
      case LOCAL() then field.name;
    end match;
  end name;
end Field;

function instDefaultConstructor
  input Absyn.Path path;
  input output InstNode node;
  input InstContext.Type context;
  input SourceInfo info;
protected
  list<InstNode> inputs, locals, all_params, sorted_locals;
  DAE.FunctionAttributes attr;
  Pointer<FunctionStatus> status;
  InstNode ctor_node, out_rec;
  Component out_comp;
  Class ctor_cls;
  InstContext.Type ctor_context;
algorithm
  // The node we get is usually a record instance, with applied modifiers and so on.
  // So the first thing we do is to create a "pure" instance of the record.

  // TODO: The lookup will fail for records declared in redeclare modifiers,
  //       since the parent will be the class scope of the modifier instead of
  //       the element being modified. In that case we just reinstantiate the
  //       record completely, but this probably isn't entirely correct. We
  //       should make the expanded but not fully instantiated class available
  //       here somehow.
  try
    ctor_node := Lookup.lookupLocalSimpleName(InstNode.name(node), InstNode.classScope(InstNode.parent(node)));
    true := referenceEq(InstNode.definition(node), InstNode.definition(ctor_node));
  else
    ctor_node := InstNode.replaceClass(Class.NOT_INSTANTIATED(), node);
  end try;

  ctor_context := InstContext.set(context, NFInstContext.RELAXED);
  ctor_node := InstNode.setNodeType(NFInstNode.InstNodeType.ROOT_CLASS(InstNode.parent(node)), ctor_node);
  ctor_node := Inst.instantiate(ctor_node, context = ctor_context);
  Inst.instExpressions(ctor_node, context = ctor_context);

  // Collect the record fields.
  (inputs, locals, all_params) := collectRecordParams(ctor_node);

  // TODO: The local fields can contain depenencies on each other which requires
  //       reordering them such that they can be initialized before they're used.
  //       But the code generation uses the type of the record constructor both
  //       for generating the record struct and the record constructor, so we
  //       can't currently reorder variables here without also messing up the
  //       order of the record itself.
  //sorted_locals := Function.sortLocals(locals, info);
  //all_params := listAppend(inputs, sorted_locals);

  // Create the output record element, using the instance created above as both parent and type.
  out_comp := Component.UNTYPED_COMPONENT(ctor_node, listArray({}),
                NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
                NFComponent.OUTPUT_ATTR, NONE(), false, AbsynUtil.dummyInfo);
  out_rec := InstNode.fromComponent("$out" + InstNode.name(ctor_node), out_comp, ctor_node);

  // Make a record constructor class and create a node for the constructor.
  ctor_cls := Class.makeRecordConstructor(all_params, out_rec);
  ctor_node := InstNode.replaceClass(ctor_cls, ctor_node);
  InstNode.classApply(ctor_node, Class.setType, Type.COMPLEX(ctor_node, ComplexType.CLASS()));

  // Create the constructor function and add it to the function cache.
  attr := DAE.FUNCTION_ATTRIBUTES_DEFAULT;
  status := Pointer.create(FunctionStatus.INITIAL);
  InstNode.cacheAddFunc(node, Function.FUNCTION(path, ctor_node, inputs,
    {out_rec}, locals, {}, Type.UNKNOWN(), attr, {}, listArray({}), status, Pointer.create(0)), false);
end instDefaultConstructor;

function checkLocalFieldOrder
  "Checks if the local variables in a record constructor requires reordering,
   and issues an error in that case since we can't handle it yet."
  input list<InstNode> locals;
  input InstNode recNode;
  input SourceInfo info;
protected
  UnorderedSet<InstNode> locals_set;
  list<InstNode> locs, deps;
  InstNode loc;
algorithm
  if listLength(locals) <= 1 then
    return;
  end if;

  loc :: locs := listReverse(locals);
  locals_set := UnorderedSet.fromList({loc}, InstNode.hash, InstNode.refEqual);

  for l in locs loop
    deps := Function.getLocalDependencies(l, locals_set);

    if not listEmpty(deps) then
      Error.addSourceMessage(Error.UNSUPPORTED_RECORD_REORDERING,
        {InstNode.name(recNode)}, info);
      fail();
    end if;

    UnorderedSet.add(l, locals_set);
  end for;
end checkLocalFieldOrder;

function collectRecordParams
  input InstNode recNode;
  output list<InstNode> inputs = {};
  output list<InstNode> locals = {};
  output list<InstNode> allParams = {};
protected
  InstNode comp;
  array<InstNode> comps;
  array<Mutable<InstNode>> pcomps;
  ClassTree tree;
algorithm
  tree := Class.classTree(InstNode.getClass(recNode));

  () := match tree
    case ClassTree.FLAT_TREE(components = comps)
      algorithm
        for i in arrayLength(comps):-1:1 loop
          comp := comps[i];
          (inputs, locals) := collectRecordParam(comp, inputs, locals);
          allParams := comp :: allParams;
        end for;
      then
        ();

    case ClassTree.INSTANTIATED_TREE(components = pcomps)
      algorithm
        for i in arrayLength(pcomps):-1:1 loop
          comp := Mutable.access(pcomps[i]);
          (inputs, locals) := collectRecordParam(comp, inputs, locals);
          allParams := comp :: allParams;
        end for;
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-instantiated function", sourceInfo());
      then
        fail();

  end match;
end collectRecordParams;

function collectRecordParam
  input InstNode component;
  input output list<InstNode> inputs;
  input output list<InstNode> locals;
protected
  Component comp;
  InstNode comp_node = InstNode.resolveInner(component);
algorithm
  if InstNode.isProtected(comp_node) then
    locals := comp_node :: locals;
    return;
  end if;

  comp := InstNode.component(comp_node);

  if Component.isModifiable(comp) then
    setFieldDirection(comp_node, Direction.INPUT);
    inputs := comp_node :: inputs;
  else
    setFieldDirection(comp_node, Direction.NONE);
    locals := comp_node :: locals;
  end if;
end collectRecordParam;

function setFieldDirection
  input InstNode field;
  input Direction direction;
protected
  Component comp = InstNode.component(field);
  Component.Attributes attr;
algorithm
  attr := Component.getAttributes(comp);
  attr.direction := direction;
  comp := Component.setAttributes(attr, comp);
  InstNode.updateComponent(comp, field);
end setFieldDirection;

function collectRecordFields
  input InstNode recNode;
  output array<Field> fields;
  output UnorderedMap<String, Integer> indexMap;
protected
  list<Field> field_lst;
  ClassTree tree;
algorithm
  tree := Class.classTree(InstNode.getClass(recNode));
  field_lst := ClassTree.foldComponents(tree, collectRecordField, {});
  fields := listArray(listReverseInPlace(field_lst));
  indexMap := UnorderedMap.new<Integer>(stringHashDjb2Mod, stringEq, arrayLength(fields));
  Type.updateRecordFieldsIndexMap(fields, indexMap);
end collectRecordFields;

function collectRecordField
  input InstNode component;
  input output list<Field> fields;
protected
  InstNode comp_node = InstNode.resolveInner(component);
  Component comp;
algorithm
  if InstNode.isProtected(comp_node) then
    fields := Field.LOCAL(InstNode.name(comp_node)) :: fields;
  else
    comp := InstNode.component(comp_node);

    if not Component.isModifiable(comp) then
      fields := Field.LOCAL(InstNode.name(comp_node)) :: fields;
    elseif not Component.isOutput(comp) then
      fields := Field.INPUT(InstNode.name(comp_node)) :: fields;
    end if;
  end if;
end collectRecordField;

function fieldsToDAE
  input list<Field> fields;
  output list<String> fieldNames = {};
algorithm
  for field in fields loop
    () := match field
      case Field.INPUT()
        algorithm
          fieldNames := field.name :: fieldNames;
        then
          ();

      else ();
    end match;
  end for;
end fieldsToDAE;

function foldInputFields<T, ArgT>
  input list<Field> fields;
  input list<T> args;
  input FuncT func;
  input output ArgT foldArg;

  partial function FuncT
    input T arg;
    input output ArgT foldArg;
  end FuncT;
protected
  T arg;
  list<T> rest_args = args;
algorithm
  for field in fields loop
    arg :: rest_args := rest_args;

    if Field.isInput(field) then
      foldArg := func(arg, foldArg);
    end if;
  end for;
end foldInputFields;

annotation(__OpenModelica_Interface="frontend");
end NFRecord;
