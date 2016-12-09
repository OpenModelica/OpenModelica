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

encapsulated package NFClass

import BaseAvlTree;
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

uniontype Class
  record NOT_INSTANTIATED end NOT_INSTANTIATED;

  record PARTIAL_CLASS
    ClassTree.Tree classes;
    list<SCode.Element> elements;
    Modifier modifier;
  end PARTIAL_CLASS;

  record EXPANDED_CLASS
    ClassTree.Tree elements;
    list<InstNode> extendsNodes;
    array<InstNode> components;
    Modifier modifier;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end EXPANDED_CLASS;

  record INSTANCED_CLASS
    ClassTree.Tree elements;
    array<InstNode> components;
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
    output Class cls;
  algorithm
    cls := INSTANCED_CLASS(ClassTree.new(), listArray({}), {}, {}, {}, {});
  end emptyInstancedClass;

  function initExpandedClass
    input ClassTree.Tree classes;
    output Class cls;
  algorithm
    cls := EXPANDED_CLASS(classes, {}, listArray({}), Modifier.NOMOD(), {}, {}, {}, {});
  end initExpandedClass;

  function instExpandedClass
    input array<InstNode> components;
    input Class expandedClass;
    output Class instancedClass;
  algorithm
    instancedClass := match expandedClass
      case EXPANDED_CLASS()
        then INSTANCED_CLASS(expandedClass.elements, components,
          expandedClass.equations, expandedClass.initialEquations,
          expandedClass.algorithms, expandedClass.initialAlgorithms);
    end match;
  end instExpandedClass;

  function components
    input Class cls;
    output array<InstNode> components;
  algorithm
    components := match cls
      case EXPANDED_CLASS() then cls.components;
      case INSTANCED_CLASS() then cls.components;
    end match;
  end components;

  function setComponents
    input array<InstNode> components;
    input output Class cls;
  algorithm
    _ := match cls
      case EXPANDED_CLASS()
        algorithm
          cls.components := components;
        then
          ();

      case INSTANCED_CLASS()
        algorithm
          cls.components := components;
        then
          ();
    end match;
  end setComponents;

  function setElements
    input ClassTree.Tree elements;
    input output Class cls;
  algorithm
    _ := match cls
      case EXPANDED_CLASS()
        algorithm
          cls.elements := elements;
        then
          ();

      case INSTANCED_CLASS()
        algorithm
          cls.elements := elements;
        then
          ();
    end match;
  end setElements;

  function setSections
    input list<Equation> equations;
    input list<Equation> initialEquations;
    input list<list<Statement>> algorithms;
    input list<list<Statement>> initialAlgorithms;
    input output Class cls;
  algorithm
    cls := match cls
      case EXPANDED_CLASS()
        then EXPANDED_CLASS(cls.elements, cls.extendsNodes, cls.components,
          cls.modifier, equations, initialEquations, algorithms, initialAlgorithms);

      case INSTANCED_CLASS()
        then INSTANCED_CLASS(cls.elements, cls.components, equations,
          initialEquations, algorithms, initialAlgorithms);
    end match;
  end setSections;

  function lookupElement
    input String name;
    input Class cls;
    output InstNode node;
  protected
    ClassTree.Tree scope;
    Class.Element element;
  algorithm
    scope := match cls
      case EXPANDED_CLASS() then cls.elements;
      case INSTANCED_CLASS() then cls.elements;
    end match;

    element := ClassTree.get(scope, name);

    node := match element
      case Element.CLASS() then element.node;
      case Element.COMPONENT() then arrayGet(components(cls), element.index);
    end match;
  end lookupElement;

  function isBuiltin
    input Class cls;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match cls
      case PARTIAL_BUILTIN() then true;
      case INSTANCED_BUILTIN() then true;
      else false;
    end match;
  end isBuiltin;

  function setModifier
    input Modifier modifier;
    input output Class cls;
  algorithm
    _ := match cls
      case PARTIAL_CLASS()
        algorithm
          cls.modifier := modifier;
        then
          ();

      case EXPANDED_CLASS()
        algorithm
          cls.modifier := modifier;
        then
          ();

      case PARTIAL_BUILTIN()
        algorithm
          cls.modifier := modifier;
        then
          ();

      else
        algorithm
          assert(false, getInstanceName() + " got unmodifiable instance");
        then
          fail();

    end match;
  end setModifier;

  function getModifier
    input Class cls;
    output Modifier modifier;
  algorithm
    modifier := match cls
      case PARTIAL_CLASS() then cls.modifier;
      case EXPANDED_CLASS() then cls.modifier;
      case PARTIAL_BUILTIN() then cls.modifier;
      else Modifier.NOMOD();
    end match;
  end getModifier;

  function clone
    input output Class cls;
  algorithm
    () := match cls
      local
        ClassTree.Tree tree;

      //case PARTIAL_CLASS()
      //  algorithm
      //    instance.classes := ClassTree.map(instance.classes, cloneEntry);
      //  then
      //    ();

      case EXPANDED_CLASS()
        algorithm
          //instance.elements := ClassTree.map(instance.elements, cloneEntry);
          cls.components := Array.map(cls.components, InstNode.clone);
        then
          ();

      case INSTANCED_CLASS()
        algorithm
          //instance.elements := ClassTree.map(instance.elements, cloneEntry);
          cls.components := Array.map(cls.components, InstNode.clone);
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
end Class;

annotation(__OpenModelica_Interface="frontend");
end NFClass;
