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
import NFComponent.Component;
import NFEquation.Equation;
import NFMod.Modifier;
import NFStatement.Statement;
import SCode.Element;

constant array<Component> NO_COMPONENTS = listArray({});

encapsulated package ClassTree
  uniontype Entry
    record CLASS
      Integer id;
    end CLASS;

    record COMPONENT
      Integer id;
    end COMPONENT;
  end Entry;

  import BaseAvlTree;
  extends BaseAvlTree(redeclare type Key = String,
                      redeclare type Value = Entry);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := match inValue
      case Entry.CLASS() then "class " + String(inValue.id);
      case Entry.COMPONENT() then "comp " + String(inValue.id);
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
    list<Element> elements;
  end PARTIAL_CLASS;

  record EXPANDED_CLASS
    ClassTree.Tree elements;
    array<Component> components;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end EXPANDED_CLASS;

  record INSTANCED_CLASS
    ClassTree.Tree elements;
    array<Component> components;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end INSTANCED_CLASS;

  record PARTIAL_BUILTIN
    Modifier modifier;
  end PARTIAL_BUILTIN;

  record INSTANCED_BUILTIN
    list<Modifier> attributes;
  end INSTANCED_BUILTIN;

  type ElementId = ClassTree.Entry;

  function emptyInstancedClass
    output Instance instance;
  algorithm
    instance := INSTANCED_CLASS(ClassTree.new(), NO_COMPONENTS, {}, {}, {}, {});
  end emptyInstancedClass;

  function initExpandedClass
    input ClassTree.Tree classes;
    output Instance instance;
  algorithm
    instance := EXPANDED_CLASS(classes, NO_COMPONENTS, {}, {}, {}, {});
  end initExpandedClass;

  function components
    input Instance instance;
    output array<Component> components;
  algorithm
    components := match instance
      case EXPANDED_CLASS() then instance.components;
      case INSTANCED_CLASS() then instance.components;
    end match;
  end components;

  function setComponents
    input array<Component> components;
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
        then EXPANDED_CLASS(instance.elements, instance.components, equations,
          initialEquations, algorithms, initialAlgorithms);

      case INSTANCED_CLASS()
        then INSTANCED_CLASS(instance.elements, instance.components, equations,
          initialEquations, algorithms, initialAlgorithms);
    end match;
  end setSections;

  function lookupElementId
    input String name;
    input Instance instance;
    output ElementId element;
  protected
    ClassTree.Tree scope;
  algorithm
    scope := match instance
      case EXPANDED_CLASS() then instance.elements;
      case INSTANCED_CLASS() then instance.elements;
    end match;

    element := ClassTree.get(scope, name);
  end lookupElementId;

  function lookupClassId
    input String name;
    input Instance instance;
    output Integer classId;
  algorithm
    ElementId.CLASS(id = classId) := lookupElementId(name, instance);
  end lookupClassId;

  function lookupComponent
    input String name;
    input Instance instance;
    output Component component;
  algorithm
    component := lookupComponentById(lookupElementId(name, instance), instance);
  end lookupComponent;

  function lookupComponentById
    input ElementId id;
    input Instance instance;
    output Component component;
  protected
    Integer comp_id;
  algorithm
    ElementId.COMPONENT(id = comp_id) := id;
    component := arrayGet(components(instance),  comp_id);
  end lookupComponentById;
end Instance;

annotation(__OpenModelica_Interface="frontend");
end NFInstance;
