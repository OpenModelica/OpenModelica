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

import NFInstNode.InstNode;
import NFMod.Modifier;
import NFStatement.Statement;
import SCode.Element;
import Type = NFType;
import NFComponent.Component;
import Dimension = NFDimension;
import NFClassTree.ClassTree;
import NFSections.Sections;

uniontype Class
  uniontype Prefixes
    record PREFIXES
      SCode.Encapsulated encapsulatedPrefix;
      SCode.Partial partialPrefix;
      SCode.Visibility visibility;
      SCode.Final finalPrefix;
      Absyn.InnerOuter innerOuter;
      SCode.Replaceable replaceablePrefix;
    end PREFIXES;

    record DEFAULT end DEFAULT;

    function isEqual
      input Prefixes prefs1;
      input Prefixes prefs2;
      output Boolean isEqual = valueEq(prefs1, prefs2);
    end isEqual;
  end Prefixes;

  record NOT_INSTANTIATED end NOT_INSTANTIATED;

  record PARTIAL_CLASS
    ClassTree elements;
    Modifier modifier;
  end PARTIAL_CLASS;

  record EXPANDED_CLASS
    ClassTree elements;
    Modifier modifier;
    Class.Prefixes prefixes;
  end EXPANDED_CLASS;

  record DERIVED_CLASS
    InstNode baseClass;
    Modifier modifier;
    list<Dimension> dims;
    Class.Prefixes prefixes;
    Component.Attributes attributes;
  end DERIVED_CLASS;

  record PARTIAL_BUILTIN
    Type ty;
    ClassTree elements;
    Modifier modifier;
  end PARTIAL_BUILTIN;

  record INSTANCED_CLASS
    ClassTree elements;
    Sections sections;
  end INSTANCED_CLASS;

  record INSTANCED_BUILTIN
    Type ty;
    ClassTree elements;
    list<Modifier> attributes;
  end INSTANCED_BUILTIN;

  function fromSCode
    input list<SCode.Element> elements;
    input Boolean isClassExtends;
    input InstNode scope;
    output Class cls;
  protected
    ClassTree tree;
  algorithm
    tree := ClassTree.fromSCode(elements, isClassExtends, scope);
    cls := PARTIAL_CLASS(tree, Modifier.NOMOD());
  end fromSCode;

  function fromEnumeration
    input list<SCode.Enum> literals;
    input Type enumType;
    input InstNode enumClass;
    output Class cls;
  protected
    ClassTree tree;
  algorithm
    tree := ClassTree.fromEnumeration(literals, enumType, enumClass);
    cls := PARTIAL_BUILTIN(enumType, tree, Modifier.NOMOD());
  end fromEnumeration;

  function initExpandedClass
    input output Class cls;
  algorithm
    cls := match cls
      case PARTIAL_CLASS()
        then EXPANDED_CLASS(cls.elements, cls.modifier, Prefixes.DEFAULT());
    end match;
  end initExpandedClass;

  function setSections
    input Sections sections;
    input output Class cls;
  algorithm
    cls := match cls
      case EXPANDED_CLASS() then INSTANCED_CLASS(cls.elements, sections);
      case INSTANCED_CLASS() then INSTANCED_CLASS(cls.elements, sections);
    end match;
  end setSections;

  function lookupElement
    input String name;
    input Class cls;
    output InstNode node;
  algorithm
    node := ClassTree.lookupElement(name, classTree(cls));
  end lookupElement;

  function isBuiltin
    input Class cls;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match cls
      case PARTIAL_BUILTIN() then true;
      case INSTANCED_BUILTIN() then true;
      case DERIVED_CLASS() then isBuiltin(InstNode.getClass(cls.baseClass));
      else false;
    end match;
  end isBuiltin;

  function classTree
    input Class cls;
    output ClassTree tree;
  algorithm
    tree := match cls
      case Class.PARTIAL_CLASS() then cls.elements;
      case Class.EXPANDED_CLASS() then cls.elements;
      case Class.DERIVED_CLASS() then classTree(InstNode.getClass(cls.baseClass));
      case Class.PARTIAL_BUILTIN() then cls.elements;
      case Class.INSTANCED_CLASS() then cls.elements;
      case Class.INSTANCED_BUILTIN() then cls.elements;
    end match;
  end classTree;

  function setClassTree
    input ClassTree tree;
    input output Class cls;
  algorithm
    () := match cls
      case Class.PARTIAL_CLASS() algorithm cls.elements := tree; then ();
      case Class.EXPANDED_CLASS() algorithm cls.elements := tree; then ();
      case Class.PARTIAL_BUILTIN() algorithm cls.elements := tree; then ();
      case Class.INSTANCED_CLASS() algorithm cls.elements := tree; then ();
      case Class.INSTANCED_BUILTIN() algorithm cls.elements := tree; then ();
    end match;
  end setClassTree;

  function getModifier
    input Class cls;
    output Modifier modifier;
  algorithm
    modifier := match cls
      case PARTIAL_CLASS() then cls.modifier;
      case EXPANDED_CLASS() then cls.modifier;
      case DERIVED_CLASS() then cls.modifier;
      case PARTIAL_BUILTIN() then cls.modifier;
      else Modifier.NOMOD();
    end match;
  end getModifier;

  function mergeModifier
    input Modifier modifier;
    input output Class cls;
  algorithm
    () := match cls
      case PARTIAL_CLASS()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      case EXPANDED_CLASS()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      case DERIVED_CLASS()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      case PARTIAL_BUILTIN()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      else
        algorithm
          assert(false, getInstanceName() + " got non-modifiable class");
        then
          fail();
    end match;
  end mergeModifier;

  function isIdentical
    input Class cls1;
    input Class cls2;
    output Boolean identical = false;
  algorithm
    identical := match (cls1, cls2)
      case (EXPANDED_CLASS(), EXPANDED_CLASS())
        then Prefixes.isEqual(cls1.prefixes, cls2.prefixes) and
             ClassTree.isIdentical(cls1.elements, cls2.elements);

      case (INSTANCED_BUILTIN(), INSTANCED_BUILTIN())
        algorithm
          if not Type.isEqual(cls1.ty, cls2.ty) then
            return;
          end if;
        then
          true;

      else true;
    end match;
  end isIdentical;

  function getDimensions
    input Class cls;
    output list<Dimension> dims;
  algorithm
    dims := match cls
      case DERIVED_CLASS()
        then listAppend(cls.dims, getDimensions(InstNode.getClass(cls.baseClass)));
      else {};
    end match;
  end getDimensions;

  function isProtected
    input Class cls;
    output Boolean isProtected;
  algorithm
    isProtected := match cls
      case EXPANDED_CLASS(prefixes = Prefixes.PREFIXES(visibility = SCode.Visibility.PROTECTED())) then true;
      case DERIVED_CLASS(prefixes = Prefixes.PREFIXES(visibility = SCode.Visibility.PROTECTED())) then true;
      else false;
    end match;
  end isProtected;

  function getAttributes
    input Class cls;
    output Component.Attributes attr;
  algorithm
    attr := match cls
      case DERIVED_CLASS() then cls.attributes;
      else Component.Attributes.DEFAULT();
    end match;
  end getAttributes;

  function getTypeAttributes
    input Class cls;
    output list<Modifier> attributes;
  algorithm
    attributes := match cls
      case INSTANCED_BUILTIN() then cls.attributes;
      else {};
    end match;
  end getTypeAttributes;

end Class;

annotation(__OpenModelica_Interface="frontend");
end NFClass;
