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

encapsulated package NFOperatorOverloading
  import Absyn;
  import AbsynUtil;
  import NFInstNode.InstNode;
  import NFFunction.Function;
  import Type = NFType;

protected
  import Record = NFRecord;
  import ComponentRef = NFComponentRef;
  import NFClassTree.ClassTree;
  import Class = NFClass;
  import Component = NFComponent;
  import Binding = NFBinding;
  import Expression = NFExpression;
  import Call = NFCall;
  import SCodeUtil;
  import InstContext = NFInstContext;

public
  function instConstructor
    input Absyn.Path path;
    input output InstNode recordNode;
    input InstContext.Type context;
    input SourceInfo info;
  protected
    ComponentRef ctor_ref;
    Absyn.Path ctor_path;
    Boolean ctor_overloaded;
    InstNode ctor_node;
  algorithm
    // Check if the operator record has an overloaded constructor declared.
    try
      ctor_ref := Function.lookupFunctionSimple("'constructor'", recordNode, context);
      ctor_overloaded := true;
    else
      ctor_overloaded := false;
    end try;

    if ctor_overloaded then
      // If it has an overloaded constructor, instantiate it and add the
      // function(s) to the record node.
      (_, ctor_node) := Function.instFunctionRef(ctor_ref, context, info);
      ctor_path := InstNode.fullPath(ctor_node);

      for f in Function.getCachedFuncs(ctor_node) loop
        checkOperatorConstructorOutput(f, Class.lastBaseClass(recordNode), ctor_path, info);
        recordNode := InstNode.cacheAddFunc(recordNode, f, false);
      end for;
    end if;

    recordNode := Record.instDefaultConstructor(path, recordNode, context, info);
  end instConstructor;

  function instOperatorFunctions
    input output InstNode node;
    input InstContext.Type context;
    input SourceInfo info;
  protected
    ClassTree tree;
    array<InstNode> mclss;
    list<Function> allfuncs = {}, funcs;
  algorithm
    checkOperatorRestrictions(node);
    tree := Class.classTree(InstNode.getClass(node));

    () := match tree
      case ClassTree.FLAT_TREE(classes = mclss)
        algorithm
          for op in mclss loop
            Function.instFunctionNode(op, context, info);
            funcs := Function.getCachedFuncs(op);
            allfuncs := listAppend(funcs, allfuncs);
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

  function checkOperatorRestrictions
    input InstNode operatorNode;
  algorithm
    if not SCodeUtil.isElementEncapsulated(InstNode.definition(operatorNode)) then
      Error.addSourceMessage(Error.OPERATOR_NOT_ENCAPSULATED,
        {AbsynUtil.pathString(InstNode.fullPath(operatorNode))},
        InstNode.info(operatorNode));
      fail();
    end if;
  end checkOperatorRestrictions;

  function lookupOperatorFunctionsInType
    input String operatorName;
    input Type ty;
    output list<Function> functions;
  protected
    InstNode node;
    ComponentRef fn_ref;
    Boolean is_defined;
  algorithm
    functions := match Type.arrayElementType(ty)
      case Type.COMPLEX(cls = node)
        algorithm
          try
            fn_ref := Function.lookupFunctionSimple(operatorName, node, NFInstContext.NO_CONTEXT);
            is_defined := true;
          else
            is_defined := false;
          end try;

          if is_defined then
            fn_ref := Function.instFunctionRef(fn_ref, NFInstContext.NO_CONTEXT, InstNode.info(node));
            functions := Function.typeRefCache(fn_ref);
          else
            functions := {};
          end if;
        then
          functions;

      else {};
    end match;
  end lookupOperatorFunctionsInType;

  function patchOperatorRecordConstructorBinding
    "Patches operator record constructors to avoid recursive binding.

     They often have outputs declared as:
       output RecordType result = RecordType(args)

     The binding in such cases causes a recursive definition of the constructor,
     so to avoid that we rewrite any calls to the constructor in the binding as
     record expressions."
    input output Function fn;
  protected
    InstNode output_node;
    Component output_comp;
    Binding output_binding;
  algorithm
    // Due to how this function is used it might also be called on destructors,
    // which we just ignore.
    if listLength(fn.outputs) <> 1 then
      return;
    end if;

    output_node := listHead(fn.outputs);
    output_comp := InstNode.component(output_node);
    output_binding := Component.getBinding(output_comp);

    if not Binding.isBound(output_binding) then
      return;
    end if;

    output_binding := Binding.mapExp(output_binding,
      function patchOperatorRecordConstructorBinding_traverser(constructorFn = fn));
    output_comp := Component.setBinding(output_binding, output_comp);
    output_node := InstNode.updateComponent(output_comp, output_node);
  end patchOperatorRecordConstructorBinding;

protected
  function checkOperatorConstructorOutput
    input Function fn;
    input InstNode recordNode;
    input Absyn.Path path;
    input SourceInfo info;
  protected
    InstNode output_node, output_ty;
  algorithm
    if listLength(fn.outputs) <> 1 then
      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_ONE_OUTPUT_ERROR,
        {AbsynUtil.pathString(path)}, info);
      fail();
    end if;

    output_node := listHead(fn.outputs);
    output_ty := InstNode.classScope(output_node);
    if not InstNode.isSame(output_ty, recordNode) then
      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_INVALID_OUTPUT_TYPE,
        {InstNode.name(output_node), AbsynUtil.pathString(path),
         InstNode.name(recordNode), InstNode.name(output_ty)}, info);
      fail();
    end if;
  end checkOperatorConstructorOutput;

  function patchOperatorRecordConstructorBinding_traverser
    input Expression exp;
    input Function constructorFn;
    output Expression outExp;
  protected
    Function fn;
    list<Expression> args;
    Type ty;
  algorithm
    outExp := match exp
      case Expression.CALL(call = Call.TYPED_CALL(fn = fn, ty = ty, arguments = args))
        guard referenceEq(constructorFn.node, fn.node)
        then Expression.makeRecord(Function.name(constructorFn), ty, args);

      else exp;
    end match;
  end patchOperatorRecordConstructorBinding_traverser;

  annotation(__OpenModelica_Interface="frontend");
end NFOperatorOverloading;
