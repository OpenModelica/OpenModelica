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
public import Connect;
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

public uniontype Function
  record FUNCTION "A function has inputs,output and locals without binding. These are resolved to statements in the algorithm section"
    list<Element> inputs;
    list<Element> outputs;
    list<Element> locals;
    list<SCode.AlgorithmSection> algorithms "TODO: Add default bindings";
  end FUNCTION;
end Function;

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
    ParamType paramType;
    Binding binding;
    Absyn.Info info;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    Absyn.Path name;
    DAE.Type ty;
    DaePrefixes prefixes;
    Binding binding;
    Absyn.Info info;
  end TYPED_COMPONENT;
    
  record CONDITIONAL_COMPONENT
    Absyn.Path name;
    DAE.Exp condition;
    SCode.Element element;
    Modifier modifier;
    Prefixes prefixes;
    SCodeEnv.Env env;
    Prefix prefix;
    Absyn.Info info;
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
  end PACKAGE;
end Component;

public uniontype ParamType
  record NON_PARAM "Not a parameter." end NON_PARAM;
  record NON_STRUCT_PARAM "A non-structural parameter." end NON_STRUCT_PARAM;
  record STRUCT_PARAM "A structural parameter." end STRUCT_PARAM;
end ParamType;

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
    SCode.Visibility visibility;
    SCode.Variability variability;
    SCode.Final finalPrefix;
    Absyn.InnerOuter innerOuter;
    tuple<Absyn.Direction, Absyn.Info> direction;
    tuple<SCode.Flow, Absyn.Info> flowPrefix;
    tuple<SCode.Stream, Absyn.Info> streamPrefix;
  end PREFIXES;
end Prefixes;

public uniontype DaePrefixes
  record NO_DAE_PREFIXES end NO_DAE_PREFIXES;

  record DAE_PREFIXES
    DAE.VarVisibility visibility;
    DAE.VarKind variability;
    SCode.Final finalPrefix;
    Absyn.InnerOuter innerOuter;
    DAE.VarDirection direction;
    DAE.Flow flowPrefix;
    DAE.Stream streamPrefix;
  end DAE_PREFIXES;
end DaePrefixes;

public constant DaePrefixes DEFAULT_CONST_DAE_PREFIXES = DAE_PREFIXES(
  DAE.PUBLIC(), DAE.CONST(), SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(),
  DAE.BIDIR(), DAE.NON_CONNECTOR(), DAE.NON_STREAM_CONNECTOR());

public uniontype Equation
  record EQUALITY_EQUATION
    DAE.Exp lhs "The left hand side expression.";
    DAE.Exp rhs "The right hand side expression.";
    Absyn.Info info;
  end EQUALITY_EQUATION;

  record CONNECT_EQUATION
    DAE.ComponentRef lhs "The left hand side component.";
    Connect.Face lhsFace "The face of the lhs component, inside or outside.";
    DAE.Type lhsType     "The type of the lhs component.";
    DAE.ComponentRef rhs "The right hand side component.";
    Connect.Face rhsFace "The face of the rhs component, inside or outside.";
    DAE.Type rhsType     "The type of the rhs component.";
    Prefix prefix;
    Absyn.Info info;
  end CONNECT_EQUATION;

  record FOR_EQUATION
    String index          "The name of the index/iterator variable.";
    DAE.Type indexType    "The type of the index/iterator variable.";
    Option<DAE.Exp> range "The range expression to loop over.";
    list<Equation> body   "The body of the for loop.";
    Absyn.Info info;
  end FOR_EQUATION;

  record IF_EQUATION
    list<tuple<DAE.Exp, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    Absyn.Info info;
  end IF_EQUATION;

  record WHEN_EQUATION
    list<tuple<DAE.Exp, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    Absyn.Info info;
  end WHEN_EQUATION;

  record ASSERT_EQUATION
    DAE.Exp condition "The assert condition.";
    DAE.Exp message "The message to display if the assert fails.";
    Absyn.Info info;
  end ASSERT_EQUATION;

  record TERMINATE_EQUATION
    DAE.Exp message "The message to display if the terminate triggers.";
    Absyn.Info info;
  end TERMINATE_EQUATION;

  record REINIT_EQUATION
    DAE.ComponentRef cref "The variable to reinitialize.";
    DAE.Exp reinitExp "The new value of the variable.";
    Absyn.Info info;
  end REINIT_EQUATION;

  record NORETCALL_EQUATION
    Absyn.Path funcName;
    list<DAE.Exp> funcArgs;
    Absyn.Info info;
  end NORETCALL_EQUATION;
end Equation;

public uniontype Statement
  record ASSIGN_STMT
    DAE.Exp lhs "The asignee";
    DAE.Exp rhs "The expression";
    Absyn.Info info;
  end ASSIGN_STMT;

  record FOR_STMT
    String index "The name of the index/iterator variable.";
    DAE.Type indexType "The type of the index/iterator variable.";
    Option<DAE.Exp> range "The range expression to loop over.";
    list<Statement> body "The body of the for loop.";
    Absyn.Info info;
  end FOR_STMT;

  record IF_STMT
    list<tuple<DAE.Exp, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    Absyn.Info info;
  end IF_STMT;

  record WHEN_STMT
    list<tuple<DAE.Exp, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    Absyn.Info info;
  end WHEN_STMT;

  record ASSERT_STMT
    DAE.Exp condition "The assert condition.";
    DAE.Exp message "The message to display if the assert fails.";
    Absyn.Info info;
  end ASSERT_STMT;

  record TERMINATE_STMT
    DAE.Exp message "The message to display if the terminate triggers.";
    Absyn.Info info;
  end TERMINATE_STMT;

  record REINIT_STMT
    DAE.ComponentRef cref "The variable to reinitialize.";
    DAE.Exp reinitExp "The new value of the variable.";
    Absyn.Info info;
  end REINIT_STMT;

  record NORETCALL_STMT
    Absyn.Path funcName;
    list<DAE.Exp> funcArgs;
    Absyn.Info info;
  end NORETCALL_STMT;

  record WHILE_STMT
    DAE.Exp exp;
    list<Statement> statementLst;
    Absyn.Info info;
  end WHILE_STMT;

  record RETURN_STMT
    Absyn.Info info;
  end RETURN_STMT;

  record BREAK_STMT
    Absyn.Info info;
  end BREAK_STMT;

  record FAILURE_STMT
    list<Statement> body;
    Absyn.Info info;
  end FAILURE_STMT;

end Statement;

public uniontype FunctionSlot
  record SLOT
    String name;
    Option<DAE.Exp> arg;
    Option<DAE.Exp> defaultValue;
  end SLOT;
end FunctionSlot;

end InstTypes;
