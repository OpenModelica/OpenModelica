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

encapsulated package InstTypes
" file:        InstTypes.mo
  package:     InstTypes
  description: Types used by SCodeInst.

  RCS: $Id$

  Types used by SCodeInst.
"

public import Absyn;
public import DAE;
public import SCode;
public import SCodeEnv;

public type Prefix = list<tuple<String, DAE.Dimensions>>;
public constant Prefix emptyPrefix = {};

public uniontype Element
  record ELEMENT
    Component component;
    Class cls;
  end ELEMENT;

  record CONDITIONAL_ELEMENT
    Component component;
  end CONDITIONAL_ELEMENT;

  record EXTENDED_ELEMENTS
    Absyn.Path baseClass;
    Class cls;
    DAE.Type ty;
  end EXTENDED_ELEMENTS;
end Element;

public uniontype Class
  record COMPLEX_CLASS
    list<Element> components;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<SCode.AlgorithmSection> algorithms;
    list<SCode.AlgorithmSection> initialAlgorithms;
  end COMPLEX_CLASS;

  record BASIC_TYPE end BASIC_TYPE;
end Class;

public uniontype Dimension
  record UNTYPED_DIMENSION
    DAE.Dimension dimension;
    Boolean isProcessing;
  end UNTYPED_DIMENSION;

  record TYPED_DIMENSION
    DAE.Dimension dimension;
  end TYPED_DIMENSION;
end Dimension;

public uniontype Binding
  record UNBOUND end UNBOUND;

  record RAW_BINDING
    Absyn.Exp bindingExp;
    SCodeEnv.Env env;
    Prefix prefix;
    Integer propagatedDims "See SCodeMod.propagateMod.";
    Absyn.Info info;
  end RAW_BINDING;

  record UNTYPED_BINDING
    DAE.Exp bindingExp;
    Boolean isProcessing;
    Integer propagatedDims "See SCodeMod.propagateMod.";
    Absyn.Info info;
  end UNTYPED_BINDING;

  record TYPED_BINDING
    DAE.Exp bindingExp;
    DAE.Type bindingType;
    Integer propagatedDims "See SCodeMod.propagateMod.";
    Absyn.Info info;
  end TYPED_BINDING;
end Binding;

public uniontype Component
  record UNTYPED_COMPONENT
    Absyn.Path name;
    DAE.Type baseType;
    array<Dimension> dimensions;
    Prefixes prefixes;
    Binding binding;
    Absyn.Info info;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    Absyn.Path name;
    DAE.Type ty;
    Prefixes prefixes;
    Binding binding;
    Absyn.Info info;
  end TYPED_COMPONENT;
    
  record CONDITIONAL_COMPONENT
    Absyn.Path name;
    SCode.Element element;
    Modifier modifier;
    Prefixes prefixes;
    SCodeEnv.Env env;
    Prefix prefix;
  end CONDITIONAL_COMPONENT; 

  record OUTER_COMPONENT
    Absyn.Path name;
    Option<Absyn.Path> innerName;
  end OUTER_COMPONENT;

  record PACKAGE
    Absyn.Path name;
  end PACKAGE;
end Component;

public uniontype Modifier
  record MODIFIER
    String name;
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    Binding binding;
    list<Modifier> subModifiers;
    Absyn.Info info;
  end MODIFIER;

  record REDECLARE
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    SCode.Element element;
  end REDECLARE;

  record NOMOD end NOMOD;
end Modifier;

public uniontype Prefixes
  record NO_PREFIXES end NO_PREFIXES;

  record PREFIXES
    DAE.VarVisibility visibility;
    DAE.VarKind variability;
    SCode.Final finalPrefix;
    Absyn.InnerOuter innerOuter;
    tuple<DAE.VarDirection, Absyn.Info> direction;
    tuple<DAE.Flow, Absyn.Info> flowPrefix;
    tuple<DAE.Stream, Absyn.Info> streamPrefix;
  end PREFIXES;
end Prefixes;

public constant Prefixes DEFAULT_CONST_PREFIXES = PREFIXES(
  DAE.PUBLIC(), DAE.CONST(), SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(),
  (DAE.BIDIR(), Absyn.dummyInfo), (DAE.NON_CONNECTOR(), Absyn.dummyInfo),
  (DAE.NON_STREAM_CONNECTOR(), Absyn.dummyInfo));

public uniontype Equation
  record EQUALITY_EQUATION
    DAE.Exp lhs;
    DAE.Exp rhs;
  end EQUALITY_EQUATION;
end Equation;

end InstTypes;
