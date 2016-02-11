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

encapsulated package NFInstTypesOld
" file:        NFInstTypes.mo
  package:     NFInstTypes
  description: Types used by NFSCodeInst.


  Types used by NFSCodeInst.
"

public import Absyn;
public import DAE;
public import SCode;
public import NFSCodeEnv;
public import NFInstPrefix;
public import NFInstTypes;

public type Dimension = NFInstTypes.Dimension;
public type Condition = NFInstTypes.Condition;
public type ParamType = NFInstTypes.ParamType;
public type Prefixes = NFInstTypes.Prefixes;
public type VarArgs = NFInstTypes.VarArgs;
public type DaePrefixes = NFInstTypes.DaePrefixes;
public type Equation = NFInstTypes.Equation;
public type Statement = NFInstTypes.Statement;
public type FunctionSlot = NFInstTypes.FunctionSlot;
public type Prefix = NFInstPrefix.Prefix;

public uniontype Element
  record ELEMENT
    Component component;
    Class cls;
  end ELEMENT;

  record CONDITIONAL_ELEMENT
    Component component;
  end CONDITIONAL_ELEMENT;

  record EXTENDED_ELEMENTS
    "This record is used by NFSCodeInst.instElementList to store elements from
     extends, but is removed by instFlatten. Most functions which handle
     elements should therefore be able to ignore this record."
    Absyn.Path baseClass;
    Class cls;
    DAE.Type ty;
  end EXTENDED_ELEMENTS;
end Element;

public uniontype Class
  record COMPLEX_CLASS
    Absyn.Path name;
    list<Element> components;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end COMPLEX_CLASS;

  record BASIC_TYPE
    Absyn.Path name;
  end BASIC_TYPE;
end Class;

public uniontype Function

  record FUNCTION
    "A function has inputs, output and locals without binding.
     These are resolved to statements in the algorithm section."
    Absyn.Path path;
    list<Element> inputs;
    list<Element> outputs;
    list<Element> locals;
    list<Statement> algorithms "TODO: Add default bindings";
  end FUNCTION;

  record RECORD_CONSTRUCTOR
    "A record constructor has inputs and locals (with bindings)?"
    Absyn.Path path;
    DAE.Type recType;
    list<Element> inputs "componets of the original record which CAN be modified";
    list<Element> locals "componets of the original record which CAN NOT be modified (protected, final, constant WITH binding)";
    list<Statement> algorithms "TODO: Add default bindings";
  end RECORD_CONSTRUCTOR;

end Function;

public uniontype Binding
  record UNBOUND end UNBOUND;

  record RAW_BINDING
    Absyn.Exp bindingExp;
    NFSCodeEnv.Env env;
    Prefix prefix;
    Integer propagatedDims "See NFSCodeMod.propagateMod.";
    SourceInfo info;
  end RAW_BINDING;

  record UNTYPED_BINDING
    DAE.Exp bindingExp;
    Boolean isProcessing;
    Integer propagatedDims "See NFSCodeMod.propagateMod.";
    SourceInfo info;
  end UNTYPED_BINDING;

  record TYPED_BINDING
    DAE.Exp bindingExp;
    DAE.Type bindingType;
    Integer propagatedDims "See NFSCodeMod.propagateMod.";
    SourceInfo info;
  end TYPED_BINDING;
end Binding;

public uniontype Component
  record UNTYPED_COMPONENT
    Absyn.Path name;
    DAE.Type baseType;
    array<Dimension> dimensions;
    Prefixes prefixes;
    ParamType paramType;
    Binding binding;
    SourceInfo info;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    Absyn.Path name;
    DAE.Type ty;
    Option<Component> parent; //NO_COMPONENT?
    DaePrefixes prefixes;
    Binding binding;
    SourceInfo info;
  end TYPED_COMPONENT;

  record CONDITIONAL_COMPONENT
    Absyn.Path name;
    DAE.Exp condition;
    SCode.Element element;
    Modifier modifier;
    Prefixes prefixes;
    NFSCodeEnv.Env env;
    Prefix prefix;
    SourceInfo info;
  end CONDITIONAL_COMPONENT;

  record DELETED_COMPONENT
    Absyn.Path name;
  end DELETED_COMPONENT;

  record OUTER_COMPONENT
    Absyn.Path name;
    Option<Absyn.Path> innerName;
  end OUTER_COMPONENT;

  record PACKAGE
    Absyn.Path name;
    Option<Component> parent; //NO_COMPONENT?
  end PACKAGE;

  record COMPONENT_ALIAS
    Absyn.Path componentName;
  end COMPONENT_ALIAS;
end Component;

public uniontype Modifier
  record MODIFIER
    String name;
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    Binding binding;
    list<Modifier> subModifiers;
    SourceInfo info;
  end MODIFIER;

  record REDECLARE
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    SCode.Element element;
  end REDECLARE;

  record NOMOD end NOMOD;
end Modifier;

annotation(__OpenModelica_Interface="frontend");
end NFInstTypesOld;
