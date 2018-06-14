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

import NFBinding.Binding;
import NFClass.Class;
import NFComponent.Component;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFExpression.CallAttributes;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import Type = NFType;
import Subscript = NFSubscript;

protected
import Inst = NFInst;
import List;
import Lookup = NFLookup;
import TypeCheck = NFTypeCheck;
import Types;
import Typing = NFTyping;
import NFInstUtil;
import NFPrefixes.Variability;
import NFPrefixes.Visibility;
import NFFunction.Function;
import NFClassTree.ClassTree;
import ComplexType = NFComplexType;
import ComponentRef = NFComponentRef;
import ErrorExt;

public

function instDefaultConstructor
  input Absyn.Path path;
  input output InstNode node;
  input SourceInfo info;
protected
  list<InstNode> inputs, locals;
  DAE.FunctionAttributes attr;
  Pointer<Boolean> collected;
  InstNode ctor_node, out_rec;
  Component out_comp;
  Class ctor_cls;
  InstNode ty_node;
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

  ctor_node := Inst.instantiate(ctor_node);
  Inst.instExpressions(ctor_node);

  // Collect the record fields.
  (inputs, locals) := collectRecordParams(ctor_node);

  // Create the output record element, using the instance created above as both parent and type.
  out_comp := Component.UNTYPED_COMPONENT(ctor_node, listArray({}),
                NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
                NFComponent.OUTPUT_ATTR, NONE(), false, Absyn.dummyInfo);
  out_rec := InstNode.fromComponent("$out" + InstNode.name(ctor_node), out_comp, ctor_node);

  // Make a record constructor class and create a node for the constructor.
  ctor_cls := Class.makeRecordConstructor(inputs, locals, out_rec);
  ctor_node := InstNode.replaceClass(ctor_cls, ctor_node);

  // Create the constructor function and add it to the function cache.
  attr := DAE.FUNCTION_ATTRIBUTES_DEFAULT;
  collected := Pointer.create(false);
  InstNode.cacheAddFunc(node, Function.FUNCTION(path, ctor_node, inputs,
    {out_rec}, locals, {}, Type.UNKNOWN(), attr, {}, collected, Pointer.create(0)), false);
end instDefaultConstructor;

function collectRecordParams
  input InstNode recNode;
  output list<InstNode> inputs = {};
  output list<InstNode> locals = {};
protected
  Class cls;
  array<InstNode> components;
  InstNode n;
  Component comp;
  ClassTree tree;
algorithm
  Error.assertion(InstNode.isClass(recNode), getInstanceName() + " got non-class node", sourceInfo());
  tree := Class.classTree(InstNode.getClass(recNode));

  () := match tree
    case ClassTree.FLAT_TREE(components = components)
      algorithm
        for i in arrayLength(components):-1:1 loop
          n := components[i];

          if InstNode.isEmpty(n) then
            continue;
          end if;

          comp := InstNode.component(n);

          if InstNode.isProtected(n) or
             Component.isConst(comp) and Component.hasBinding(comp) then
            locals := n :: locals;
          else
            n := InstNode.updateComponent(Component.makeInput(comp), n);
            inputs := n :: inputs;
          end if;
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

annotation(__OpenModelica_Interface="frontend");
end NFRecord;
