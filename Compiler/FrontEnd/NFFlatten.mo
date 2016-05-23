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

encapsulated package NFFlatten
" file:        NFFlatten.mo
  package:     NFFlatten
  description: Flattening


  New instantiation, enable with +d=scodeInst.
"

import NFBinding.Binding;
import Inst = NFInst;
import NFInst.InstanceTree;
import NFInst.InstNode;
import NFInst.Instance;
import NFInst.Component;

import DAE;
import SCode;
import System;

function flattenClass
  input InstNode classInst;
  output DAE.DAElist dae;
protected
  list<DAE.Element> elems;
  DAE.Element class_elem;
algorithm
  elems := flattenNode(classInst);
  elems := listReverse(elems);
  class_elem := DAE.COMP(InstNode.name(classInst), elems, DAE.emptyElementSource, NONE());
  dae := DAE.DAE({class_elem});
end flattenClass;

function flattenNode
  input InstNode node;
  input list<String> prefix = {};
  input list<DAE.Element> inElements = {};
  output list<DAE.Element> elements;
protected
  Instance i;
  String name;
algorithm
  InstNode.INST_NODE(name = name, instance = i) := node;
  elements := flattenInstance(name, i, prefix, inElements);
end flattenNode;

function flattenInstance
  input String name;
  input Instance instance;
  input list<String> prefix;
  input list<DAE.Element> inElements;
  output list<DAE.Element> elements = inElements;
algorithm
  _ := match instance
    case Instance.INSTANCED_CLASS()
      algorithm
        for c in instance.components loop
          elements := flattenComponent(c, prefix, elements);
        end for;
      then
        ();

    else
      algorithm
        print("Got non-instantiated component " +
          stringDelimitList(listReverse(prefix), ".") + "\n");
      then
        ();

  end match;
end flattenInstance;

function flattenComponent
  input Component component;
  input list<String> prefix;
  input list<DAE.Element> inElements;
  output list<DAE.Element> elements;
algorithm
  elements := match component
    local
      Instance i;
      DAE.Element var;
      DAE.ComponentRef cref;

    case Component.COMPONENT(classInst = InstNode.INST_NODE(instance = Instance.PARTIAL_BUILTIN()))
      algorithm
        cref := DAE.CREF_IDENT(component.name, DAE.T_UNKNOWN_DEFAULT, {});
        for id in prefix loop
          cref := DAE.CREF_QUAL(id, DAE.T_UNKNOWN_DEFAULT, {}, cref);
        end for;

        var := DAE.VAR(
          cref,
          DAE.VARIABLE(),
          DAE.BIDIR(),
          DAE.NON_PARALLEL(),
          DAE.PUBLIC(),
          component.ty,
          Binding.untypedExp(component.binding),
          {},
          DAE.NON_CONNECTOR(),
          DAE.emptyElementSource,
          NONE(),
          NONE(),
          Absyn.NOT_INNER_OUTER());

        elements := var :: inElements;
      then
        elements;

    case Component.COMPONENT(classInst = InstNode.INST_NODE(instance = i))
      then flattenInstance(component.name, i, component.name :: prefix, inElements);

  end match;
end flattenComponent;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
