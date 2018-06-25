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
  import NFInstNode.InstNode;
  import NFFunction.Function;
  import Type = NFType;

protected
  import Record = NFRecord;
  import ComponentRef = NFComponentRef;
  import NFClassTree.ClassTree;
  import NFClass.Class;

public
  function instConstructor
    input Absyn.Path path;
    input output InstNode recordNode;
    input SourceInfo info;
  protected
    ComponentRef ctor_ref;
    Absyn.Path ctor_path;
    Boolean ctor_overloaded;
    InstNode ctor_node;
  algorithm
    // Check if the operator record has an overloaded constructor declared.
    try
      ctor_ref := Function.lookupFunctionSimple("'constructor'", recordNode);
      ctor_overloaded := true;
    else
      ctor_overloaded := false;
    end try;

    if ctor_overloaded then
      // If it has an overloaded constructor, instantiate it and add the
      // function(s) to the record node.
      //ctor_node := ComponentRef.node(ctor_ref);
      (_, ctor_node) := Function.instFunctionRef(ctor_ref, info);
      ctor_path := InstNode.scopePath(ctor_node, includeRoot = true);
      //ctor_node := Function.instFunction2(ctor_path, ctor_node, info);

      for f in Function.getCachedFuncs(ctor_node) loop
        checkOperatorConstructorOutput(f, Class.lastBaseClass(recordNode), ctor_path, info);
        recordNode := InstNode.cacheAddFunc(recordNode, f, false);
      end for;
    end if;

    recordNode := Record.instDefaultConstructor(path, recordNode, info);
  end instConstructor;

  function instOperatorFunctions
    input output InstNode node;
    input SourceInfo info;
  protected
    ClassTree tree;
    array<InstNode> mclss;
    Absyn.Path path;
    list<Function> allfuncs = {}, funcs;
  algorithm
    checkOperatorRestrictions(node);
    tree := Class.classTree(InstNode.getClass(node));

    () := match tree
      case ClassTree.FLAT_TREE(classes = mclss)
        algorithm
          for op in mclss loop
            //path := InstNode.scopePath(op, includeRoot = true);
            //Function.instFunction2(path, op, info);
            Function.instFunctionNode(op);
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
    if not SCode.isElementEncapsulated(InstNode.definition(operatorNode)) then
      Error.addSourceMessage(Error.OPERATOR_NOT_ENCAPSULATED,
        {Absyn.pathString(InstNode.scopePath(operatorNode, includeRoot = true))},
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
            fn_ref := Function.lookupFunctionSimple(operatorName, node);
            is_defined := true;
          else
            is_defined := false;
          end try;

          if is_defined then
            fn_ref := Function.instFunctionRef(fn_ref, InstNode.info(node));
            functions := Function.typeRefCache(fn_ref);
          else
            functions := {};
          end if;
        then
          functions;

      else {};
    end match;
  end lookupOperatorFunctionsInType;

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
        {Absyn.pathString(path)}, info);
      fail();
    end if;

    output_node := listHead(fn.outputs);
    output_ty := InstNode.classScope(output_node);
    if not InstNode.isSame(output_ty, recordNode) then
      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_INVALID_OUTPUT_TYPE,
        {InstNode.name(output_node), Absyn.pathString(path),
         InstNode.name(recordNode), InstNode.name(output_ty)}, info);
      fail();
    end if;
  end checkOperatorConstructorOutput;

  annotation(__OpenModelica_Interface="frontend");
end NFOperatorOverloading;
