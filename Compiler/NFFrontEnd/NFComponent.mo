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

import DAE;
import NFBinding.Binding;
import NFDimension.Dimension;
import NFInstNode.InstNode;
import NFMod.Modifier;
import SCode.Element;
import SCode;

protected
import NFInstUtil;

public
constant Component.Attributes DEFAULT_ATTR =
  Component.Attributes.ATTRIBUTES(
     DAE.NON_CONNECTOR(),
     DAE.NON_PARALLEL(),
     DAE.VARIABLE(),
     DAE.BIDIR(),
     DAE.NOT_INNER_OUTER(),
     DAE.PUBLIC());

constant Component.Attributes INPUT_ATTR =
  Component.Attributes.ATTRIBUTES(
     DAE.NON_CONNECTOR(),
     DAE.NON_PARALLEL(),
     DAE.VARIABLE(),
     DAE.INPUT(),
     DAE.NOT_INNER_OUTER(),
     DAE.PUBLIC());

constant Component.Attributes OUTPUT_ATTR =
  Component.Attributes.ATTRIBUTES(
     DAE.NON_CONNECTOR(),
     DAE.NON_PARALLEL(),
     DAE.VARIABLE(),
     DAE.OUTPUT(),
     DAE.NOT_INNER_OUTER(),
     DAE.PUBLIC());

uniontype Component
  uniontype Attributes
    record ATTRIBUTES
      // adrpo: keep the order in DAE.ATTR
      DAE.ConnectorType connectorType;
      DAE.VarParallelism parallelism;
      DAE.VarKind variability;
      DAE.VarDirection direction;
      DAE.VarInnerOuter innerOuter;
      DAE.VarVisibility visibility;
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
    DAE.Type ty;
    Binding binding;
    Component.Attributes attributes;
  end TYPED_COMPONENT;

  function classInstance
    input Component component;
    output InstNode classInst;
  algorithm
    classInst := match component
      case UNTYPED_COMPONENT() then component.classInst;
      case TYPED_COMPONENT() then component.classInst;
    end match;
  end classInstance;

  function setClassInstance
    input InstNode classInst;
    input output Component component;
  algorithm
    () := match component
      case UNTYPED_COMPONENT()
        algorithm
          component.classInst := classInst;
        then
          ();

      case TYPED_COMPONENT()
        algorithm
          component.classInst := classInst;
        then
          ();

    end match;
  end setClassInstance;

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

  function mergeModifier
    input Modifier modifier;
    input output Component component;
  algorithm
    () := match component
      case COMPONENT_DEF()
        algorithm
          component.modifier := Modifier.merge(modifier, component.modifier);
        then
          ();
    end match;
  end mergeModifier;

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

      case TYPED_COMPONENT(ty = DAE.Type.T_ARRAY(ty = ty))
        algorithm
          component.ty := ty;
        then
          ();

      else ();
    end match;
  end unliftType;

  function getAttributes
    input Component component;
    output Component.Attributes attr;
  algorithm
    attr := match component
      case UNTYPED_COMPONENT() then component.attributes;
      case TYPED_COMPONENT() then component.attributes;
    end match;
  end getAttributes;

  function getBinding
    input Component component;
    output NFBinding.Binding b;
  algorithm
    b := match component
      case UNTYPED_COMPONENT() then component.binding;
      case TYPED_COMPONENT() then component.binding;
    end match;
  end getBinding;

  function attr2DaeAttr
    input Attributes attr;
    output DAE.Attributes daeAttr;
  algorithm
    daeAttr := match(attr)
      case ATTRIBUTES()
        then DAE.ATTR(
               NFInstUtil.daeToSCodeConnectorType(attr.connectorType),
               NFInstUtil.daeToSCodeParallelism(attr.parallelism),
               NFInstUtil.daeToSCodeVariability(attr.variability),
               NFInstUtil.daeToAbsynDirection(attr.direction),
               NFInstUtil.daeToAbsynInnerOuter(attr.innerOuter),
               NFInstUtil.daeToSCodeVisibility(attr.visibility));
    end match;
  end attr2DaeAttr;

end Component;

annotation(__OpenModelica_Interface="frontend");
end NFComponent;
