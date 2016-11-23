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

encapsulated package NFInstance

import BaseAvlTree;
import NFComponentNode.ComponentNode;
import NFEquation.Equation;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFStatement.Statement;
import SCode.Element;
import Array;
import Error;

encapsulated package ClassTree
  uniontype Entry
    record CLASS
      InstNode node;
    end CLASS;

    record COMPONENT
      Integer index;
    end COMPONENT;
  end Entry;

  import BaseAvlTree;
  import NFInstNode.InstNode;
  import NFComponentNode.ComponentNode;

  extends BaseAvlTree(redeclare type Key = String,
                      redeclare type Value = Entry);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := match inValue
      case Entry.CLASS() then "class " + InstNode.name(inValue.node);
      case Entry.COMPONENT() then "comp " + String(inValue.index);
    end match;
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;

  annotation(__OpenModelica_Interface="util");
end ClassTree;

uniontype Instance
  record NOT_INSTANTIATED end NOT_INSTANTIATED;

  record PARTIAL_CLASS
    ClassTree.Tree classes;
    list<SCode.Element> elements;
    Modifier modifier;
  end PARTIAL_CLASS;

  record EXPANDED_CLASS
    ClassTree.Tree elements;
    list<ComponentNode> extendsNodes;
    array<ComponentNode> components;
    Modifier modifier;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end EXPANDED_CLASS;

  record INSTANCED_CLASS
    ClassTree.Tree elements;
    array<ComponentNode> components;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end INSTANCED_CLASS;

  record PARTIAL_BUILTIN
    String name;
    Modifier modifier;
  end PARTIAL_BUILTIN;

  record INSTANCED_BUILTIN
    String name;
    list<Modifier> attributes;
  end INSTANCED_BUILTIN;

  type Element = ClassTree.Entry;

  function emptyInstancedClass
    output Instance instance;
  algorithm
    instance := INSTANCED_CLASS(ClassTree.new(), listArray({}), {}, {}, {}, {});
  end emptyInstancedClass;

  function initExpandedClass
    input ClassTree.Tree classes;
    output Instance instance;
  algorithm
    instance := EXPANDED_CLASS(classes, {}, listArray({}), Modifier.NOMOD(), {}, {}, {}, {});
  end initExpandedClass;

  function components
    input Instance instance;
    output array<ComponentNode> components;
  algorithm
    components := match instance
      case EXPANDED_CLASS() then instance.components;
      case INSTANCED_CLASS() then instance.components;
    end match;
  end components;

  function setComponents
    input array<ComponentNode> components;
    input output Instance instance;
  algorithm
    _ := match instance
      case EXPANDED_CLASS()
        algorithm
          instance.components := components;
        then
          ();

      case INSTANCED_CLASS()
        algorithm
          instance.components := components;
        then
          ();
    end match;
  end setComponents;

  function setElements
    input ClassTree.Tree elements;
    input output Instance instance;
  algorithm
    _ := match instance
      case EXPANDED_CLASS()
        algorithm
          instance.elements := elements;
        then
          ();

      case INSTANCED_CLASS()
        algorithm
          instance.elements := elements;
        then
          ();
    end match;
  end setElements;

  function setSections
    input list<Equation> equations;
    input list<Equation> initialEquations;
    input list<list<Statement>> algorithms;
    input list<list<Statement>> initialAlgorithms;
    input output Instance instance;
  algorithm
    instance := match instance
      case EXPANDED_CLASS()
        then EXPANDED_CLASS(instance.elements, instance.extendsNodes, instance.components,
          instance.modifier, equations, initialEquations, algorithms, initialAlgorithms);

      case INSTANCED_CLASS()
        then INSTANCED_CLASS(instance.elements, instance.components, equations,
          initialEquations, algorithms, initialAlgorithms);
    end match;
  end setSections;

  function lookupElement
    input String name;
    input Instance instance;
    output Element element;
  protected
    ClassTree.Tree scope;
  algorithm
    scope := match instance
      case EXPANDED_CLASS() then instance.elements;
      case INSTANCED_CLASS() then instance.elements;
    end match;

    element := ClassTree.get(scope, name);
  end lookupElement;

  function lookupClass
    input String name;
    input Instance instance;
    output InstNode cls;
  algorithm
    Element.CLASS(node = cls) := lookupElement(name, instance);
  end lookupClass;

  function lookupComponent
    input String name;
    input Instance instance;
    output ComponentNode component;
  protected
    Integer index;
  algorithm
    component := lookupComponentByElement(lookupElement(name, instance), instance);
  end lookupComponent;

  function lookupComponentByIndex
    input Integer index;
    input Instance instance;
    output ComponentNode component;
  algorithm
    component := arrayGet(components(instance), index);
  end lookupComponentByIndex;

  function lookupComponentByElement
    input Element element;
    input Instance instance;
    output ComponentNode component;
  protected
    Integer index;
  algorithm
    Element.COMPONENT(index = index) := element;
    component := arrayGet(components(instance), index);
  end lookupComponentByElement;

  function isBuiltin
    input Instance instance;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match instance
      case PARTIAL_BUILTIN() then true;
      case INSTANCED_BUILTIN() then true;
      else false;
    end match;
  end isBuiltin;

  function setModifier
    input Modifier modifier;
    input output Instance instance;
  algorithm
    _ := match instance
      case PARTIAL_CLASS()
        algorithm
          instance.modifier := modifier;
        then
          ();

      case EXPANDED_CLASS()
        algorithm
          instance.modifier := modifier;
        then
          ();

      case PARTIAL_BUILTIN()
        algorithm
          instance.modifier := modifier;
        then
          ();

      else
        algorithm
          Error.addInternalError("NFInstance.setModifier got unmodifiable instance!\n",
            Absyn.dummyInfo);
        then
          fail();

    end match;
  end setModifier;

  function getModifier
    input Instance instance;
    output Modifier modifier;
  algorithm
    modifier := match instance
      case PARTIAL_CLASS() then instance.modifier;
      case EXPANDED_CLASS() then instance.modifier;
      case PARTIAL_BUILTIN() then instance.modifier;
      else Modifier.NOMOD();
    end match;
  end getModifier;

  function clone
    input output Instance instance;
  algorithm
    () := match instance
      local
        ClassTree.Tree tree;

      case PARTIAL_CLASS()
        algorithm
          instance.classes := ClassTree.map(instance.classes, cloneEntry);
        then
          ();

      case EXPANDED_CLASS()
        algorithm
          instance.elements := ClassTree.map(instance.elements, cloneEntry);
          Array.map(instance.components, ComponentNode.clone);
        then
          ();

      case INSTANCED_CLASS()
        algorithm
          instance.elements := ClassTree.map(instance.elements, cloneEntry);
          Array.map(instance.components, ComponentNode.clone);
        then
          ();

      else ();
    end match;
  end clone;

  function cloneEntry
    input String name;
    input ClassTree.Entry entry;
    output ClassTree.Entry clone;
  algorithm
    clone := match entry
      case ClassTree.Entry.CLASS() then ClassTree.Entry.CLASS(InstNode.clone(entry.node));
      else entry;
    end match;
  end cloneEntry;
end Instance;

annotation(__OpenModelica_Interface="frontend");
end NFInstance;
