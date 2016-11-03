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

encapsulated package NFComponent

import DAE.Type;
import NFBinding.Binding;
import NFDimension.Dimension;
import NFInstNode.InstNode;
import NFMod.Modifier;
import SCode.Element;

uniontype Component
  uniontype Attributes
    record ATTRIBUTES
      DAE.VarKind variability;
      DAE.VarDirection direction;
      DAE.VarVisibility visibility;
      DAE.ConnectorType connectorType;
    end ATTRIBUTES;
  end Attributes;

  record COMPONENT_DEF
    Element definition;
    Modifier modifier;
  end COMPONENT_DEF;

  record UNTYPED_COMPONENT
    InstNode classInst;
    array<Dimension> dimensions;
    Binding binding;
    Component.Attributes attributes;
    SourceInfo info;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    InstNode classInst;
    Type ty;
    Binding binding;
    Component.Attributes attributes;
  end TYPED_COMPONENT;

  record EXTENDS_NODE
    InstNode node;
  end EXTENDS_NODE;

  record COMPONENT_REF
    Integer node;
    Integer index;
  end COMPONENT_REF;

  function isNamedComponent
    input Component component;
    output Boolean isNamed;
  algorithm
    isNamed := match component
      case EXTENDS_NODE() then false;
      else true;
    end match;
  end isNamedComponent;

  function classInstance
    input Component component;
    output InstNode classInst;
  algorithm
    classInst := match component
      case UNTYPED_COMPONENT() then component.classInst;
      case TYPED_COMPONENT() then component.classInst;
    end match;
  end classInstance;

  function setModifier
    input Modifier modifier;
    input output Component component;
  algorithm
    () := match component
      case COMPONENT_DEF()
        algorithm
          component.modifier := modifier;
        then
          ();
    end match;
  end setModifier;

  function getType
    input Component component;
    output DAE.Type ty;
  algorithm
    ty := match component
      case TYPED_COMPONENT() then component.ty;
    end match;
  end getType;

  function setType
    input DAE.Type ty;
    input output Component component;
  algorithm
    component := match component
      case UNTYPED_COMPONENT()
        then TYPED_COMPONENT(component.classInst, ty, component.binding, component.attributes);

      case TYPED_COMPONENT()
        algorithm
          component.ty := ty;
        then
          component;
    end match;
  end setType;

  function unliftType
    input output Component component;
  algorithm
    () := match component
      local
        DAE.Type ty;

      case TYPED_COMPONENT(ty = DAE.T_ARRAY(ty = ty))
        algorithm
          component.ty := ty;
        then
          ();

      else ();
    end match;
  end unliftType;
end Component;

annotation(__OpenModelica_Interface="frontend");
end NFComponent;
