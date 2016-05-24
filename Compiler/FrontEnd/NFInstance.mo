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
import SCode.Element;
import NFMod.Modifier;

constant array<Component> NO_COMPONENTS = listArray({});

encapsulated package ClassTree
  import BaseAvlTree;
  import NFInstance.ElementId;
  extends BaseAvlTree(redeclare type Key = String,
                      redeclare type Value = ElementId);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := match inValue
      case ElementId.CLASS_ID() then "class " + String(inValue.id);
      case ElementId.COMPONENT_ID() then "comp " + String(inValue.id);
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
  end EXPANDED_CLASS;

  record INSTANCED_CLASS
    ClassTree.Tree elements;
    array<Component> components;
  end INSTANCED_CLASS;

  record PARTIAL_BUILTIN
  end PARTIAL_BUILTIN;

  function emptyInstancedClass
    output Instance instance;
  algorithm
    instance := INSTANCED_CLASS(ClassTree.new(), NO_COMPONENTS);
  end emptyInstancedClass;

  function initExpandedClass
    input ClassTree.Tree classes;
    output Instance instance;
  algorithm
    instance := EXPANDED_CLASS(classes, NO_COMPONENTS);
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

  function lookupClassId
    input String name;
    input Instance instance;
    output Integer classId;
  protected
    ClassTree.Tree scope;
  algorithm
    scope := match instance
      case EXPANDED_CLASS() then instance.elements;
      case INSTANCED_CLASS() then instance.elements;
    end match;

    ElementId.CLASS_ID(id = classId) := ClassTree.get(scope, name);
  end lookupClassId;
end Instance;

uniontype ElementId
  record CLASS_ID
    Integer id;
  end CLASS_ID;

  record COMPONENT_ID
    Integer id;
  end COMPONENT_ID;
end ElementId;

annotation(__OpenModelica_Interface="frontend");
end NFInstance;
