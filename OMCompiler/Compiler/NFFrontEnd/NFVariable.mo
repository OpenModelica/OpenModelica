/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype NFVariable
  import Binding = NFBinding;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import NFPrefixes.Visibility;
  import NFPrefixes.Variability;
  import NFPrefixes.ConnectorType;
  import Type = NFType;
  import BackendInfo = NFBackendExtension.BackendInfo;

protected
  import Variable = NFVariable;
  import IOStream;
  import Util;

public
  record VARIABLE
    ComponentRef name;
    Type ty;
    Binding binding;
    Visibility visibility;
    Component.Attributes attributes;
    list<tuple<String, Binding>> typeAttributes;
    list<Variable> children;
    Option<SCode.Comment> comment;
    SourceInfo info;
    BackendInfo backendinfo "NFBackendExtension.DUMMY_BACKEND_INFO for all of frontend. Only used in Backend.";
  end VARIABLE;

  function fromCref
    input ComponentRef cref;
    output Variable variable;
  protected
    InstNode node;
    Component comp;
    Type ty;
    Binding binding;
    Visibility vis;
    Component.Attributes attr;
    Option<SCode.Comment> cmt;
    SourceInfo info;
  algorithm
    node := ComponentRef.node(cref);
    comp := InstNode.component(node);
    ty := ComponentRef.getSubscriptedType(cref);
    binding := Component.getBinding(comp);
    vis := InstNode.visibility(node);
    attr := Component.getAttributes(comp);
    cmt := Component.comment(comp);
    info := InstNode.info(node);
    // kabdelhak: add dummy backend info, will be changed to actual value in
    // conversion to backend process. NBackendDAE.lower
    variable := VARIABLE(cref, ty, binding, vis, attr, {}, {}, cmt, info, NFBackendExtension.DUMMY_BACKEND_INFO);
  end fromCref;

  function isStructural
    input Variable variable;
    output Boolean structural =
      variable.attributes.variability <= Variability.STRUCTURAL_PARAMETER;
  end isStructural;

  function variability
    input Variable variable;
    output Variability variability = variable.attributes.variability;
  end variability;

  function isEmptyArray
    input Variable variable;
    output Boolean isEmpty = Type.isEmptyArray(variable.ty);
  end isEmptyArray;

  function isDeleted
    input Variable variable;
    output Boolean deleted;
  protected
    InstNode node;
  algorithm
    node := ComponentRef.node(variable.name);
    deleted := InstNode.isComponent(node) and Component.isDeleted(InstNode.component(node));
  end isDeleted;

  function isPresent
    input Variable variable;
    output Boolean present = not ConnectorType.isPotentiallyPresent(variable.attributes.connectorType);
  end isPresent;

  function isPotential
    input Variable variable;
    output Boolean potential = ConnectorType.isPotential(variable.attributes.connectorType);
  end isPotential;

  function isFlow
    input Variable variable;
    output Boolean potential = ConnectorType.isFlow(variable.attributes.connectorType);
  end isFlow;

  function isStream
    input Variable variable;
    output Boolean potential = ConnectorType.isStream(variable.attributes.connectorType);
  end isStream;

  function lookupTypeAttribute
    input String name;
    input Variable var;
    output Binding binding;
  algorithm
    for attr in var.typeAttributes loop
      if Util.tuple21(attr) == name then
        binding := Util.tuple22(attr);
        return;
      end if;
    end for;

    binding := NFBinding.EMPTY_BINDING;
  end lookupTypeAttribute;

  function mapExp
    input output Variable var;
    input MapFn fn;

    partial function MapFn
      input output Expression exp;
    end MapFn;
  algorithm
    var.binding := Binding.mapExp(var.binding, fn);
    var.typeAttributes := list(
      (Util.tuple21(a), Binding.mapExp(Util.tuple22(a), fn)) for a in var.typeAttributes);
    var.children := list(mapExp(v, fn) for v in var.children);
  end mapExp;

  function toString
    input Variable var;
    input String indent = "";
    input Boolean printBindingType = false;
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toStream(var, indent, printBindingType, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toString;

  function toStream
    input Variable var;
    input String indent = "";
    input Boolean printBindingType = false;
    input output IOStream.IOStream s;
  protected
    Boolean first;
    Binding b;
  algorithm
    s := IOStream.append(s, indent);

    if var.visibility == Visibility.PROTECTED then
      s := IOStream.append(s, "protected ");
    end if;

    s := IOStream.append(s, Component.Attributes.toString(var.attributes, var.ty));
    s := IOStream.append(s, Type.toString(var.ty));
    s := IOStream.append(s, " ");
    s := IOStream.append(s, ComponentRef.toString(var.name));

    if not listEmpty(var.typeAttributes) then
      s := IOStream.append(s, "(");

      first := true;
      for a in var.typeAttributes loop
        if first then
          first := false;
        else
          s := IOStream.append(s, ", ");
        end if;

        b := Util.tuple22(a);

        if Binding.isEach(b) then
          s := IOStream.append(s, "each ");
        end if;

        s := IOStream.append(s, Util.tuple21(a));
        s := IOStream.append(s, " = ");
        s := IOStream.append(s, Binding.toString(b));
      end for;

      s := IOStream.append(s, ")");
    end if;

    if Binding.isBound(var.binding) then
      s := IOStream.append(s, " = ");

      if printBindingType then
        s := IOStream.append(s, "(");
        s := IOStream.append(s, Type.toString(Binding.getType(var.binding)));
        s := IOStream.append(s, ") ");
      end if;

      s := IOStream.append(s, Binding.toString(var.binding));
    end if;
  end toStream;

  function toFlatStream
    input Variable var;
    input String indent = "";
    input Boolean printBindingType = false;
    input output IOStream.IOStream s;
  protected
    Boolean first;
    Binding b;
    Integer var_dims, binding_dims;
  algorithm
    s := IOStream.append(s, indent);

    if var.visibility == Visibility.PROTECTED then
      s := IOStream.append(s, "protected ");
    else
      s := IOStream.append(s, "public ");
    end if;

    s := Component.Attributes.toFlatStream(var.attributes, var.ty, s, ComponentRef.isSimple(var.name));
    s := IOStream.append(s, Type.toFlatString(var.ty));
    s := IOStream.append(s, " ");
    s := IOStream.append(s, ComponentRef.toFlatString(var.name));
    s := Component.typeAttrsToFlatStream(var.typeAttributes, var.ty, s);

    if Binding.isBound(var.binding) then
      s := IOStream.append(s, " = ");

      if printBindingType then
        s := IOStream.append(s, "(");
        s := IOStream.append(s, Type.toFlatString(Binding.getType(var.binding)));
        s := IOStream.append(s, ") ");
      end if;

      s := IOStream.append(s, Binding.toFlatString(var.binding));
    end if;
  end toFlatStream;

  annotation(__OpenModelica_Interface="frontend");
end NFVariable;
