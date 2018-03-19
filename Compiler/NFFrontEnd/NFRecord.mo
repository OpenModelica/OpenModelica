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
import ClassTree = NFClassTree.ClassTree;
import ComplexType = NFComplexType;
import ComponentRef = NFComponentRef;
import ErrorExt;

public

function instConstructors
  input Absyn.Path path;
  input output InstNode node;
  input SourceInfo info;
 protected
   Class cls;
   list<InstNode> inputs, outputs, locals;
  InstNode out_rec, ctor_over;
   DAE.FunctionAttributes attr;
   Pointer<Boolean> collected;
   Absyn.Path con_path;
  ComponentRef con_ref;
  Boolean ctor_defined;
 algorithm

  // See if we have overloaded costructors.
  try
    con_ref := Function.lookupFunctionSilent(Absyn.CREF_IDENT("'constructor'",{}), node, info);
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

  // See if we have '0' costructor.
  try
    con_ref := Function.lookupFunctionSilent(Absyn.CREF_IDENT("'0'",{}), node, info);
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

  // Create the default constructor.
  (inputs, locals) := collectRecordParams(node);
  attr := DAE.FUNCTION_ATTRIBUTES_DEFAULT;
  // attr := makeAttributes(node, inputs, outputs);
  collected := Pointer.create(false);
  con_path := Absyn.suffixPath(path,"'constructor'.'$default'");

  // Create an output record element for the default constructor.
  // create a TYPED_COMPONENT here since this output "default constructed" record is not part
  // of the class node. So it will not be typed later by typeFunction. Instead of changing
  // things there just handle it here.
  out_rec := InstNode.COMPONENT_NODE("$out" + InstNode.name(node),
    Visibility.PUBLIC,
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      node,
      Type.COMPLEX(node, ComplexType.CLASS()),
      Binding.UNBOUND(),
      Binding.UNBOUND(),
      NFComponent.OUTPUT_ATTR,
      NONE(),
      Absyn.dummyInfo)),
    0,
    node);

  InstNode.cacheAddFunc(node, Function.FUNCTION(con_path, node, inputs, {out_rec}, locals, {}, Type.UNKNOWN(), attr, collected), false);

end instConstructors;


function collectRecordParams
  input InstNode recNode;
  output list<InstNode> inputs = {};
  output list<InstNode> locals = {};
protected

  Class cls;
  array<Mutable<InstNode>> components;
  InstNode n;
  Component comp;
algorithm

  Error.assertion(InstNode.isClass(recNode), getInstanceName() + " got non-class node", sourceInfo());
  cls := InstNode.getClass(recNode);

  () := match cls
    case Class.EXPANDED_CLASS(elements = ClassTree.INSTANTIATED_TREE(components = components))
      algorithm
        for i in arrayLength(components):-1:1 loop
          n := Mutable.access(components[i]);
          comp := InstNode.component(n);

          if InstNode.isProtected(n) then
            locals := n :: locals;
          else
            if Component.isConst(comp) then
              if not Component.hasBinding(comp) then
                inputs := n :: inputs;
              else
                locals := n :: locals;
              end if;
            else
              inputs := n :: inputs;
            end if;
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
  Class cls;
  array<Mutable<InstNode>> mclss;
  InstNode op;
  Absyn.Path path;
  list<Function> allfuncs = {}, funcs;

algorithm
  cls := InstNode.getClass(node);

    () := match cls
      case Class.EXPANDED_CLASS(elements = ClassTree.INSTANTIATED_TREE(classes = mclss))  algorithm
        for i in arrayLength(mclss):-1:1 loop
          op := Mutable.access(mclss[i]);
          path := InstNode.scopePath(op);
          Function.instFunc2(path, op, info);
          funcs := Function.getCachedFuncs(op);
          allfuncs := listAppend(allfuncs,funcs);
        end for;
        for f in allfuncs loop
          node := InstNode.cacheAddFunc(node, f, false);
        end for;
      then ();

      else algorithm
        Error.assertion(false, getInstanceName() + " got non-instantiated function", sourceInfo());
      then fail();
    end match;
end instOperatorFunctions;

annotation(__OpenModelica_Interface="frontend");
end NFRecord;
