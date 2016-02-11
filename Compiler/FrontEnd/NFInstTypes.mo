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

encapsulated package NFInstTypes
" file:        NFInstTypes.mo
  package:     NFInstTypes
  description: Types used by NFInst.


  Types used by NFInst.
"

public import Absyn;
public import NFConnect2;
public import DAE;
public import NFInstPrefix;
public import SCode;

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
    "This record is used by NFInst.instElementList to store elements from
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
     These are resolved to statements in the algorithm section"
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
    Env env;
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
    Env env;
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

  record COMPONENT_ALIAS
    Absyn.Path componentName;
  end COMPONENT_ALIAS;
end Component;

public uniontype Condition
  record SINGLE_CONDITION
    Boolean condition;
  end SINGLE_CONDITION;

  record ARRAY_CONDITION
    list<Condition> conditions;
  end ARRAY_CONDITION;
end Condition;

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
    SourceInfo info;
  end MODIFIER;

  record REDECLARE
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    SCode.Element element;
    Env env;
    Modifier mod;
    Option<ConstrainingClass> constrainingClass;
  end REDECLARE;

  record NOMOD end NOMOD;
end Modifier;

public uniontype ConstrainingClass
  record CONSTRAINING_CLASS
    Absyn.Path classPath;
    Modifier mod;
  end CONSTRAINING_CLASS;
end ConstrainingClass;

public uniontype Prefixes
  record NO_PREFIXES end NO_PREFIXES;

  record PREFIXES
    SCode.Visibility visibility;
    SCode.Variability variability;
    SCode.Final finalPrefix;
    Absyn.InnerOuter innerOuter;
    tuple<Absyn.Direction, SourceInfo> direction;
    tuple<SCode.ConnectorType, SourceInfo> connectorType;
    VarArgs varArgs;
  end PREFIXES;
end Prefixes;

public constant Prefixes DEFAULT_PROTECTED_PREFIXES = PREFIXES(
  SCode.PROTECTED(), SCode.VAR(), SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(),
  (Absyn.BIDIR(), Absyn.dummyInfo), (SCode.POTENTIAL(), Absyn.dummyInfo), NO_VARARG());

public constant Prefixes DEFAULT_INPUT_PREFIXES = PREFIXES(
  SCode.PUBLIC(), SCode.VAR(), SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(),
  (Absyn.INPUT(), Absyn.dummyInfo), (SCode.POTENTIAL(), Absyn.dummyInfo), NO_VARARG());

public uniontype VarArgs
  record NO_VARARG end NO_VARARG;
  record IS_VARARG end IS_VARARG;
end VarArgs;

public uniontype DaePrefixes
  record NO_DAE_PREFIXES end NO_DAE_PREFIXES;

  record DAE_PREFIXES
    DAE.VarVisibility visibility;
    DAE.VarKind variability;
    SCode.Final finalPrefix;
    Absyn.InnerOuter innerOuter;
    DAE.VarDirection direction;
    DAE.ConnectorType connectorType;
  end DAE_PREFIXES;
end DaePrefixes;

public constant DaePrefixes DEFAULT_CONST_DAE_PREFIXES = DAE_PREFIXES(
  DAE.PUBLIC(), DAE.CONST(), SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(),
  DAE.BIDIR(), DAE.NON_CONNECTOR());

public uniontype Equation
  record EQUALITY_EQUATION
    DAE.Exp lhs "The left hand side expression.";
    DAE.Exp rhs "The right hand side expression.";
    SourceInfo info;
  end EQUALITY_EQUATION;

  record CONNECT_EQUATION
    DAE.ComponentRef lhs "The left hand side component.";
    NFConnect2.Face lhsFace "The face of the lhs component, inside or outside.";
    DAE.Type lhsType     "The type of the lhs component.";
    DAE.ComponentRef rhs "The right hand side component.";
    NFConnect2.Face rhsFace "The face of the rhs component, inside or outside.";
    DAE.Type rhsType     "The type of the rhs component.";
    Prefix prefix;
    SourceInfo info;
  end CONNECT_EQUATION;

  record FOR_EQUATION
    String name           "The name of the iterator variable.";
    Integer index         "The index of the iterator variable.";
    DAE.Type indexType    "The type of the index/iterator variable.";
    Option<DAE.Exp> range "The range expression to loop over.";
    list<Equation> body   "The body of the for loop.";
    SourceInfo info;
  end FOR_EQUATION;

  record IF_EQUATION
    list<tuple<DAE.Exp, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end IF_EQUATION;

  record WHEN_EQUATION
    list<tuple<DAE.Exp, list<Equation>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end WHEN_EQUATION;

  record ASSERT_EQUATION
    DAE.Exp condition "The assert condition.";
    DAE.Exp message "The message to display if the assert fails.";
    DAE.Exp level "Error or warning";
    SourceInfo info;
  end ASSERT_EQUATION;

  record TERMINATE_EQUATION
    DAE.Exp message "The message to display if the terminate triggers.";
    SourceInfo info;
  end TERMINATE_EQUATION;

  record REINIT_EQUATION
    DAE.ComponentRef cref "The variable to reinitialize.";
    DAE.Exp reinitExp "The new value of the variable.";
    SourceInfo info;
  end REINIT_EQUATION;

  record NORETCALL_EQUATION
    DAE.Exp exp;
    SourceInfo info;
  end NORETCALL_EQUATION;
end Equation;

public uniontype Statement
  record ASSIGN_STMT
    DAE.Exp lhs "The asignee";
    DAE.Exp rhs "The expression";
    SourceInfo info;
  end ASSIGN_STMT;

  record FUNCTION_ARRAY_INIT "Used to mark in which order local array variables in functions should be initialized"
    String name;
    DAE.Type ty;
    SourceInfo info;
  end FUNCTION_ARRAY_INIT;

  record FOR_STMT
    String name "The name of the iterator variable.";
    Integer index "The index of the scope of the iterator variable.";
    DAE.Type indexType "The type of the index/iterator variable.";
    Option<DAE.Exp> range "The range expression to loop over.";
    list<Statement> body "The body of the for loop.";
    SourceInfo info;
  end FOR_STMT;

  record IF_STMT
    list<tuple<DAE.Exp, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end IF_STMT;

  record WHEN_STMT
    list<tuple<DAE.Exp, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    SourceInfo info;
  end WHEN_STMT;

  record ASSERT_STMT
    DAE.Exp condition "The assert condition.";
    DAE.Exp message "The message to display if the assert fails.";
    SourceInfo info;
  end ASSERT_STMT;

  record TERMINATE_STMT
    DAE.Exp message "The message to display if the terminate triggers.";
    SourceInfo info;
  end TERMINATE_STMT;

  record REINIT_STMT
    DAE.ComponentRef cref "The variable to reinitialize.";
    DAE.Exp reinitExp "The new value of the variable.";
    SourceInfo info;
  end REINIT_STMT;

  record NORETCALL_STMT
    DAE.Exp exp;
    SourceInfo info;
  end NORETCALL_STMT;

  record WHILE_STMT
    DAE.Exp exp;
    list<Statement> statementLst;
    SourceInfo info;
  end WHILE_STMT;

  record RETURN_STMT
    SourceInfo info;
  end RETURN_STMT;

  record BREAK_STMT
    SourceInfo info;
  end BREAK_STMT;

  record FAILURE_STMT
    list<Statement> body;
    SourceInfo info;
  end FAILURE_STMT;

end Statement;

public uniontype FunctionSlot
  record SLOT
    String name;
    Option<DAE.Exp> arg;
    Option<DAE.Exp> defaultValue;
  end SLOT;
end FunctionSlot;

public uniontype EntryOrigin
  record LOCAL_ORIGIN "An entry declared in the local scope." end LOCAL_ORIGIN;
  record BUILTIN_ORIGIN "An entry declared in the builtin scope." end BUILTIN_ORIGIN;

  record INHERITED_ORIGIN
    "An entry that has been inherited through an extends clause."
    Absyn.Path baseClass "The path of the baseclass the entry was inherited from.";
    SourceInfo info "The info of the extends clause.";
    list<EntryOrigin> origin "The origins of the element in the baseclass.";
    Env originEnv "The environment the entry was inherited from.";
    Integer index "Index used to identify the extends clause for optimization.";
  end INHERITED_ORIGIN;

  record REDECLARED_ORIGIN
    "An entry that has replaced another entry through redeclare."
    Entry replacedEntry "The replaced entry.";
    Env originEnv "The environment the replacement came from.";
  end REDECLARED_ORIGIN;

  record IMPORTED_ORIGIN
    "An entry that has been imported with an import statement."
    Absyn.Import imp;
    SourceInfo info;
    Env originEnv "The environment the entry was imported from.";
  end IMPORTED_ORIGIN;
end EntryOrigin;

public uniontype Entry
  record ENTRY
    String name;
    SCode.Element element;
    Modifier mod;
    list<EntryOrigin> origins;
  end ENTRY;
end Entry;

public uniontype ScopeType
  record BUILTIN_SCOPE end BUILTIN_SCOPE;
  record TOP_SCOPE end TOP_SCOPE;
  record NORMAL_SCOPE
    Boolean isEncapsulated;
  end NORMAL_SCOPE;
  record IMPLICIT_SCOPE "This scope contains one or more iterators; they are made unique by the following index (plus their name)" Integer iterIndex; end IMPLICIT_SCOPE;
end ScopeType;

public uniontype Frame
  record FRAME
    Option<String> name;
    Option<Prefix> prefix;
    ScopeType scopeType;
    AvlTree entries;
  end FRAME;
end Frame;

public type Env = list<Frame>;

public type AvlKey = String;
public type AvlValue = Entry;

public uniontype AvlTree
  "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value";
    Integer height "height of tree, used for balancing";
    Option<AvlTree> left "left subtree";
    Option<AvlTree> right "right subtree";
  end AVLTREENODE;
end AvlTree;

public uniontype AvlTreeValue
  "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;
end AvlTreeValue;

annotation(__OpenModelica_Interface="frontend");
end NFInstTypes;
