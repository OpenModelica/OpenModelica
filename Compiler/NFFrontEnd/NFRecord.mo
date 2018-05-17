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

function instConstructors
  input Absyn.Path path;
  input output InstNode node;
  input SourceInfo info;
protected
  InstNode ctor_over;
  DAE.FunctionAttributes attr;
  ComponentRef con_ref;
  Boolean ctor_defined;
algorithm

  // See if we have overloaded constructors.
  try
    con_ref := Function.lookupFunctionSimple("'constructor'", node);
    ctor_defined := true;
  else
    ctor_defined := false;
  end try;

  if ctor_defined then
    ctor_over := ComponentRef.node(con_ref);
    ctor_over := Function.instFunc2(InstNode.scopePath(ctor_over), ctor_over, InstNode.info(ctor_over));
    for f in Function.getCachedFuncs(ctor_over) loop
      node := InstNode.cacheAddFunc(node, f, false);
    end for;
  end if;

  // See if we have '0' constructor.
  try
    con_ref := Function.lookupFunctionSimple("'0'", node);
    ctor_defined := true;
  else
    ctor_defined := false;
  end try;

  if ctor_defined then
    ctor_over := ComponentRef.node(con_ref);

    ctor_over := Function.instFunc2(InstNode.scopePath(ctor_over), ctor_over, InstNode.info(ctor_over));
    for f in Function.getCachedFuncs(ctor_over) loop
      node := InstNode.cacheAddFunc(node, f, false);
    end for;
  end if;

  node := instDefaultConstructor(path, node, info);
end instConstructors;

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
  node := Lookup.lookupLocalSimpleName(InstNode.name(node), InstNode.parentScope(node));
  node := Inst.instantiate(node);
  Inst.instExpressions(node);

  // Collect the record fields.
  (inputs, locals) := collectRecordParams(node);

  // Create the output record element, using the instance created above as both parent and type.
  out_comp := Component.TYPED_COMPONENT(node, Type.COMPLEX(node, ComplexType.RECORD(node)),
                Binding.UNBOUND(NONE()), Binding.UNBOUND(NONE()),
                NFComponent.OUTPUT_ATTR, NONE(), Absyn.dummyInfo);
  out_rec := InstNode.fromComponent("$out" + InstNode.name(node), out_comp, node);

  // Make a record constructor class and create a node for the constructor.
  ctor_cls := Class.makeRecordConstructor(inputs, locals, out_rec);
  ctor_node := InstNode.replaceClass(ctor_cls, node);

  // Create the constructor function and add it to the function cache.
  attr := DAE.FUNCTION_ATTRIBUTES_DEFAULT;
  collected := Pointer.create(false);
  InstNode.cacheAddFunc(node, Function.FUNCTION(path, ctor_node, inputs,
    {out_rec}, locals, {}, Type.UNKNOWN(), attr, collected, Pointer.create(0)), false);
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

function instOperatorFunctions
  input output InstNode node;
  input SourceInfo info;
protected
  ClassTree tree;
  array<InstNode> mclss;
  InstNode op;
  Absyn.Path path;
  list<Function> allfuncs = {}, funcs;
algorithm
  tree := Class.classTree(InstNode.getClass(node));

  () := match tree
    case ClassTree.FLAT_TREE(classes = mclss)
      algorithm
        for i in arrayLength(mclss):-1:1 loop
          op := mclss[i];
          path := InstNode.scopePath(op);
          Function.instFunc2(path, op, info);
          funcs := Function.getCachedFuncs(op);
          allfuncs := listAppend(allfuncs,funcs);
        end for;

        for f in allfuncs loop
          node := InstNode.cacheAddFunc(node, f, false);
        end for;
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-instantiated function", sourceInfo());
      then
        fail();

  end match;
end instOperatorFunctions;

annotation(__OpenModelica_Interface="frontend");
end NFRecord;
