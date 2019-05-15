interface package NFInstDump.TV

package Absyn
  uniontype Exp end Exp;
end Absyn;

//package NFConnect2
//  uniontype Face
//    record INSIDE end INSIDE;
//    record OUTSIDE end OUTSIDE;
//    record NO_FACE end NO_FACE;
//  end Face;
//
//  uniontype ExpandableConnector
//    record EXPANDABLE_CONNECTOR
//      //list<...> potentialVars;
//      //list<...> presentVars;
//    end EXPANDABLE_CONNECTOR;
//  end ExpandableConnector;
//
//  uniontype Connector
//    record CONNECTOR
//      DAE.ComponentRef name;
//      Face face;
//    end CONNECTOR;
//  end Connector;
//
//  uniontype Connection
//    record CONNECTION
//      Connector lhs;
//      Connector rhs;
//      SourceInfo info;
//    end CONNECTION;
//  end Connection;
//
//  //uniontype Branch
//  //  record BRANCH
//  //    Connector lhs;
//  //    Connector rhs;
//  //    Boolean breakable;
//  //    SourceInfo info;
//  //  end BRANCH;
//  //end Branch;
//
//  uniontype Root
//    record ROOT
//      DAE.ComponentRef name;
//      SourceInfo info;
//    end ROOT;
//
//    record POTENTIAL_ROOT
//      DAE.ComponentRef name;
//      Integer priority;
//      SourceInfo info;
//    end POTENTIAL_ROOT;
//  end Root;
//
//  uniontype Connections
//    record CONNECTIONS
//      list<Connection> connections;
//      list<Connection> branches;
//      list<Root> roots;
//    end CONNECTIONS;
//  end Connections;
//end NFConnect2;

package DAE
  uniontype ComponentRef end ComponentRef;
  uniontype Exp end Exp;
  uniontype Type end Type;
  uniontype Dimension end Dimension;
  type Dimensions = list<Dimension>;
end DAE;

package Expression
  function typeof
    input DAE.Exp inExp;
    output DAE.Type outType;
  end typeof;
end Expression;

package NFInstDump
  function dumpUntypedComponentDims
    input NFInstTypes.Component inComponent;
    output String outString;
  end dumpUntypedComponentDims;
end NFInstDump;

package NFInstPrefix
  uniontype Prefix
    record EMPTY_PREFIX
      Option<Absyn.Path> classPath;
    end EMPTY_PREFIX;

    record PREFIX
      String name;
      DAE.Dimensions dims;
      Prefix restPrefix;
    end PREFIX;
  end Prefix;
end NFInstPrefix;

package NFInstTypes
  uniontype Element
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

  uniontype Class
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

  uniontype Function
    record FUNCTION
      Absyn.Path path;
      list<Element> inputs;
      list<Element> outputs;
      list<Element> locals;
      list<Statement> algorithms;
    end FUNCTION;
  end Function;

  uniontype Dimension
    record UNTYPED_DIMENSION
      DAE.Dimension dimension;
      Boolean isProcessing;
    end UNTYPED_DIMENSION;

    record TYPED_DIMENSION
      DAE.Dimension dimension;
    end TYPED_DIMENSION;
  end Dimension;

  uniontype Binding
    record UNBOUND end UNBOUND;

    record RAW_BINDING
      Absyn.Exp bindingExp;
      NFEnv.Env env;
      Prefix prefix;
      Integer propagatedDims;
      SourceInfo info;
    end RAW_BINDING;

    record UNTYPED_BINDING
      DAE.Exp bindingExp;
      Boolean isProcessing;
      Integer propagatedDims;
      SourceInfo info;
    end UNTYPED_BINDING;

    record TYPED_BINDING
      DAE.Exp bindingExp;
      DAE.Type bindingType;
      Integer propagatedDims;
      SourceInfo info;
    end TYPED_BINDING;
  end Binding;

  uniontype Component
    record UNTYPED_COMPONENT
      Absyn.Path name;
      DAE.Type baseType;
      //array<Dimension> dimensions;
      Prefixes prefixes;
      ParamType paramType;
      Binding binding;
      SourceInfo info;
    end UNTYPED_COMPONENT;

    record TYPED_COMPONENT
      Absyn.Path name;
      DAE.Type ty;
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
      NFEnv.Env env;
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
  end Component;

  uniontype Condition
    record SINGLE_CONDITION
      Boolean condition;
    end SINGLE_CONDITION;

    record ARRAY_CONDITION
      list<Condition> conditions;
    end ARRAY_CONDITION;
  end Condition;

  uniontype ParamType
    record NON_PARAM end NON_PARAM;
    record NON_STRUCT_PARAM end NON_STRUCT_PARAM;
    record STRUCT_PARAM end STRUCT_PARAM;
  end ParamType;

  uniontype Modifier
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

  uniontype Prefixes
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

  uniontype VarArgs
    record NO_VARARG end NO_VARARG;
    record IS_VARARG end IS_VARARG;
  end VarArgs;

  uniontype DaePrefixes
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

  uniontype Equation
    record EQUALITY_EQUATION
      DAE.Exp lhs;
      DAE.Exp rhs;
      SourceInfo info;
    end EQUALITY_EQUATION;

    record CONNECT_EQUATION
      DAE.ComponentRef lhs;
      NFConnect2.Face lhsFace;
      DAE.Type lhsType;
      DAE.ComponentRef rhs;
      NFConnect2.Face rhsFace;
      DAE.Type rhsType;
      Prefix prefix;
      SourceInfo info;
    end CONNECT_EQUATION;

    record FOR_EQUATION
      String name;
      Integer index;
      DAE.Type indexType;
      Option<DAE.Exp> range;
      list<Equation> body;
      SourceInfo info;
    end FOR_EQUATION;

    record IF_EQUATION
      list<tuple<DAE.Exp, list<Equation>>> branches;
      SourceInfo info;
    end IF_EQUATION;

    record WHEN_EQUATION
      list<tuple<DAE.Exp, list<Equation>>> branches;
      SourceInfo info;
    end WHEN_EQUATION;

    record ASSERT_EQUATION
      DAE.Exp condition;
      DAE.Exp message;
      SourceInfo info;
    end ASSERT_EQUATION;

    record TERMINATE_EQUATION
      DAE.Exp message;
      SourceInfo info;
    end TERMINATE_EQUATION;

    record REINIT_EQUATION
      DAE.ComponentRef cref;
      DAE.Exp reinitExp;
      SourceInfo info;
    end REINIT_EQUATION;

    record NORETCALL_EQUATION
      DAE.Exp exp;
      SourceInfo info;
    end NORETCALL_EQUATION;
  end Equation;

  uniontype Statement
    record ASSIGN_STMT
      DAE.Exp lhs;
      DAE.Exp rhs;
      SourceInfo info;
    end ASSIGN_STMT;

    record FOR_STMT
      String index;
      DAE.Type indexType;
      Option<DAE.Exp> range;
      list<Statement> body;
      SourceInfo info;
    end FOR_STMT;

    record IF_STMT
      list<tuple<DAE.Exp, list<Statement>>> branches;
      SourceInfo info;
    end IF_STMT;

    record WHEN_STMT
      list<tuple<DAE.Exp, list<Statement>>> branches;
      SourceInfo info;
    end WHEN_STMT;

    record ASSERT_STMT
      DAE.Exp condition;
      DAE.Exp message;
      SourceInfo info;
    end ASSERT_STMT;

    record TERMINATE_STMT
      DAE.Exp message;
      SourceInfo info;
    end TERMINATE_STMT;

    record REINIT_STMT
      DAE.ComponentRef cref;
      DAE.Exp reinitExp;
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
end NFInstTypes;

package Tpl
  function addTemplateError
    input String inErrMsg;
  end addTemplateError;
end Tpl;

end NFInstDump.TV;
