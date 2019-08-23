encapsulated package NFTypes
protected
import Absyn.{Exp, Path, Subscript};
import AbsynUtil;
import ClassInf;
import DAE;
import Dump;
import ElementSource;
import Error;
import ExpressionSimplify;
import Flags;
import IOStream;
import List;
import MetaModelica.Dangerous.listReverseInPlace;
import NFBinding.Binding;
import NFCall.Call;
import NFClass.Class;
import NFClassTree.ClassTree;
import NFComponent.Component;
import NFFunction.Function;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFPrefixes.ConnectorType;
import NFPrefixes.Variability;
import NFPrefixes.Visibility;
import SCode.Annotation;
import SCode;
import SCodeDump;
import SCodeUtil;
import System;
import Types;
import Util;
import Values;
import ValuesUtil;
protected
public
uniontype NFComplexType
  record CLASS end CLASS;
  record EXTENDS_TYPE
    "Used for long class declarations extending from a type, e.g.:
       type SomeType
         extends Real;
       end SomeType;"
    InstNode baseClass;
  end EXTENDS_TYPE;

  record CONNECTOR
    list<InstNode> potentials;
    list<InstNode> flows;
    list<InstNode> streams;
  end CONNECTOR;

  record EXPANDABLE_CONNECTOR
    list<InstNode> potentiallyPresents;
    list<InstNode> expandableConnectors;
  end EXPANDABLE_CONNECTOR;

  record RECORD
    InstNode constructor;
    list<String> fieldNames;
  end RECORD;

  record EXTERNAL_OBJECT
    InstNode constructor;
    InstNode destructor;
  end EXTERNAL_OBJECT;
end NFComplexType;

type ComplexType = NFComplexType;

uniontype NFVariable
  record VARIABLE
    ComponentRef name;
    Type ty;
    Binding binding;
    Visibility visibility;
    Component.Attributes attributes;
    list<tuple<String, Binding>> typeAttributes;
    Option<SCode.Comment> comment;
    SourceInfo info;
  end VARIABLE;
end NFVariable;
uniontype NFSubscript

  record RAW_SUBSCRIPT
    Absyn.Subscript subscript;
  end RAW_SUBSCRIPT;

  record UNTYPED
    Expression exp;
  end UNTYPED;

  record INDEX
    Expression index;
  end INDEX;

  record SLICE
    Expression slice;
  end SLICE;

  record EXPANDED_SLICE
    list<Subscript> indices;
  end EXPANDED_SLICE;

  record WHOLE end WHOLE;
end NFSubscript;

uniontype NFConnection

  record CONNECTION
    // TODO: This should be Connector, but the import above doesn't work due to some compiler bug.
    NFConnector lhs;
    NFConnector rhs;
  end CONNECTION;
end NFConnection;


uniontype NFConnections

  type BrokenEdge = tuple<ComponentRef, ComponentRef, list<Equation>>;
  type BrokenEdges = list<BrokenEdge>;

  record CONNECTIONS
    list<Connection> connections;
    list<Connector> flows;
    BrokenEdges broken;
  end CONNECTIONS;
end NFConnections;

public
  type Face = enumeration(INSIDE, OUTSIDE);

uniontype NFConnector
  record CONNECTOR
    ComponentRef name;
    Type ty;
    Face face;
    ConnectorType.Type cty;
    DAE.ElementSource source;
  end CONNECTOR;
end NFConnector;

  public
    type Origin = enumeration(
                              CREF "From an Absyn cref.",
                              SCOPE "From prefixing thecref with its scope.",
                              ITERATOR "From an iterator."
  );

uniontype NFComponentRef
  record CREF
    InstNode node;
    list<Subscript> subscripts;
    Type ty "The type of the node, without taking subscripts into account.";
    Origin origin;
    ComponentRef restCref;
  end CREF;
  record EMPTY end EMPTY;
  record WILD end WILD;
end NFComponentRef;

uniontype NFDimension

  record RAW_DIM
    Absyn.Subscript dim;
  end RAW_DIM;

  record UNTYPED
    Expression dimension;
    Boolean isProcessing;
  end UNTYPED;

  record INTEGER
    Integer size;
    Variability var;
  end INTEGER;

  record BOOLEAN
  end BOOLEAN;

  record ENUM
    Type enumType;
  end ENUM;

  record EXP
    Expression exp;
    Variability var;
  end EXP;

  record UNKNOWN
  end UNKNOWN;
end NFDimension;
public
  uniontype Branch
    record BRANCH
      Expression condition;
      Variability conditionVar;
      list<Equation> body;
    end BRANCH;

    record INVALID_BRANCH
      Branch branch;
      list<Error.TotalMessage> errors;
    end INVALID_BRANCH;
end Branch;

uniontype NFEquation
  record EQUALITY
    Expression lhs "The left hand side expression.";
    Expression rhs "The right hand side expression.";
    Type ty;
    DAE.ElementSource source;
  end EQUALITY;

  record CREF_EQUALITY
    ComponentRef lhs;
    ComponentRef rhs;
    DAE.ElementSource source;
  end CREF_EQUALITY;

  record ARRAY_EQUALITY
    Expression lhs;
    Expression rhs;
    Type ty;
    DAE.ElementSource source;
  end ARRAY_EQUALITY;

  record CONNECT
    Expression lhs;
    Expression rhs;
    DAE.ElementSource source;
  end CONNECT;

  record FOR
    InstNode iterator;
    Option<Expression> range;
    list<Equation> body   "The body of the for loop.";
    DAE.ElementSource source;
  end FOR;

  record IF
    list<Branch> branches;
    DAE.ElementSource source;
  end IF;

  record WHEN
    list<Branch> branches;
    DAE.ElementSource source;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level "Error or warning";
    DAE.ElementSource source;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    DAE.ElementSource source;
  end TERMINATE;

  record REINIT
    Expression cref "The variable to reinitialize.";
    Expression reinitExp "The new value of the variable.";
    DAE.ElementSource source;
  end REINIT;

  record NORETCALL
    Expression exp;
    DAE.ElementSource source;
  end NORETCALL;
end NFEquation;

    uniontype ClockKind
      record INFERRED_CLOCK
      end INFERRED_CLOCK;

      record INTEGER_CLOCK
        Expression intervalCounter;
        Expression resolution " integer type >= 1 ";
      end INTEGER_CLOCK;

      record REAL_CLOCK
        Expression interval;
      end REAL_CLOCK;

      record BOOLEAN_CLOCK
        Expression condition;
        Expression startInterval " real type >= 0.0 ";
      end BOOLEAN_CLOCK;

      record SOLVER_CLOCK
        Expression c;
        Expression solverMethod " string type ";
      end SOLVER_CLOCK;
    end ClockKind;

uniontype NFExpression
  record INTEGER
    Integer value;
  end INTEGER;

  record REAL
    Real value;
  end REAL;

  record STRING
    String value;
  end STRING;

  record BOOLEAN
    Boolean value;
  end BOOLEAN;

  record ENUM_LITERAL
    Type ty;
    String name;
    Integer index;
  end ENUM_LITERAL;

  record CREF
    Type ty;
    ComponentRef cref;
  end CREF;

  record TYPENAME "Represents a type used as a range, e.g. Boolean."
    Type ty;
  end TYPENAME;

  record ARRAY
    Type ty;
    list<Expression> elements;
    Boolean literal "True if the array is known to only contain literal expressions.";
  end ARRAY;

  record MATRIX "The array concatentation operator [a,b; c,d]; this should be removed during type-checking"
    // Does not have a type since we only keep this operator before type-checking
    list<list<Expression>> elements;
  end MATRIX;

  record RANGE
    Type ty;
    Expression start;
    Option<Expression> step;
    Expression stop;
  end RANGE;

  record TUPLE
    Type ty;
    list<Expression> elements;
  end TUPLE;

  record RECORD
    Path path; // Maybe not needed since the type contains the name. Prefix?
    Type ty;
    list<Expression> elements;
  end RECORD;

  record CALL
    Call call;
  end CALL;

  record SIZE
    Expression exp;
    Option<Expression> dimIndex;
  end SIZE;

  record END
  end END;

  record BINARY "Binary operations, e.g. a+4"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end BINARY;

  record UNARY "Unary operations, -(4x)"
    Operator operator;
    Expression exp;
  end UNARY;

  record LBINARY "Logical binary operations: and, or"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end LBINARY;

  record LUNARY "Logical unary operations: not"
    Operator operator;
    Expression exp;
  end LUNARY;

  record RELATION "Relation, e.g. a <= 0"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end RELATION;

  record IF
    Expression condition;
    Expression trueBranch;
    Expression falseBranch;
  end IF;

  record CAST
    Type ty;
    Expression exp;
  end CAST;

  record UNBOX "MetaModelica value unboxing (similar to a cast)"
    Expression exp;
    Type ty;
  end UNBOX;

  record SUBSCRIPTED_EXP
    Expression exp;
    list<Subscript> subscripts;
    Type ty;
  end SUBSCRIPTED_EXP;

  record TUPLE_ELEMENT
    Expression tupleExp;
    Integer index;
    Type ty;
  end TUPLE_ELEMENT;

  record RECORD_ELEMENT
    Expression recordExp;
    Integer index;
    String fieldName;
    Type ty;
  end RECORD_ELEMENT;

  record BOX "MetaModelica boxed value"
    Expression exp;
  end BOX;

  record MUTABLE
    Mutable<Expression> exp;
  end MUTABLE;

  record EMPTY
    Type ty;
  end EMPTY;

  record CLKCONST "Clock constructors"
    ClockKind clk "Clock kinds";
  end CLKCONST;

  record PARTIAL_FUNCTION_APPLICATION
    ComponentRef fn;
    list<Expression> args;
    list<String> argNames;
    Type ty;
  end PARTIAL_FUNCTION_APPLICATION;
end NFExpression;

uniontype NFExpressionIterator

  record ARRAY_ITERATOR
    list<Expression> array;
    list<Expression> slice;
  end ARRAY_ITERATOR;

  record SCALAR_ITERATOR
    Expression exp;
  end SCALAR_ITERATOR;

  record EACH_ITERATOR
    Expression exp;
  end EACH_ITERATOR;

  record NONE_ITERATOR
  end NONE_ITERATOR;

  record REPEAT_ITERATOR
    list<Expression> current;
    list<Expression> all;
  end REPEAT_ITERATOR;
end NFExpressionIterator;

uniontype NFFlatModel
  record FLAT_MODEL
    String name;
    list<Variable> variables;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<Algorithm> algorithms;
    list<Algorithm> initialAlgorithms;
    Option<SCode.Comment> comment;
  end FLAT_MODEL;
end NFFlatModel;

uniontype NFStatement
  record ASSIGNMENT
    Expression lhs "The asignee";
    Expression rhs "The expression";
    Type ty;
    DAE.ElementSource source;
  end ASSIGNMENT;

  record FUNCTION_ARRAY_INIT "Used to mark in which order local array variables in functions should be initialized"
    String name;
    Type ty;
    DAE.ElementSource source;
  end FUNCTION_ARRAY_INIT;

  record FOR
    InstNode iterator;
    Option<Expression> range;
    list<Statement> body "The body of the for loop.";
    DAE.ElementSource source;
  end FOR;

  record IF
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    DAE.ElementSource source;
  end IF;

  record WHEN
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    DAE.ElementSource source;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level;
    DAE.ElementSource source;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    DAE.ElementSource source;
  end TERMINATE;

  record NORETCALL
    Expression exp;
    DAE.ElementSource source;
  end NORETCALL;

  record WHILE
    Expression condition;
    list<Statement> body;
    DAE.ElementSource source;
  end WHILE;

  record RETURN
    DAE.ElementSource source;
  end RETURN;

  record BREAK
    DAE.ElementSource source;
  end BREAK;

  record FAILURE
    list<Statement> body;
    DAE.ElementSource source;
  end FAILURE;
end NFStatement;

uniontype NFSections
  record SECTIONS
    list<Equation> equations;
    list<Equation> initialEquations;
    list<Algorithm> algorithms;
    list<Algorithm> initialAlgorithms;
  end SECTIONS;

  record EXTERNAL
    String name;
    list<Expression> args;
    ComponentRef outputRef;
    String language;
    Option<SCode.Annotation> ann;
    Boolean explicit;
  end EXTERNAL;

  record EMPTY end EMPTY;
end NFSections;

uniontype NFImport
  record UNRESOLVED_IMPORT
    Absyn.Import imp;
    InstNode scope;
    SourceInfo info;
  end UNRESOLVED_IMPORT;

  record RESOLVED_IMPORT
    InstNode node;
    SourceInfo info;
  end RESOLVED_IMPORT;

  record CONFLICTING_IMPORT
    Import imp1;
    Import imp2;
  end CONFLICTING_IMPORT;
end NFImport;

uniontype NFRestriction
  record CLASS end CLASS;

  record CONNECTOR
    Boolean isExpandable;
  end CONNECTOR;

  record ENUMERATION end ENUMERATION;
  record EXTERNAL_OBJECT end EXTERNAL_OBJECT;
  record FUNCTION end FUNCTION;
  record MODEL end MODEL;
  record OPERATOR end OPERATOR;

  record RECORD
    Boolean isOperator;
  end RECORD;

  record RECORD_CONSTRUCTOR end RECORD_CONSTRUCTOR;
  record TYPE end TYPE;
  record CLOCK end CLOCK;
  record UNKNOWN end UNKNOWN;
end NFRestriction;

uniontype NFRangeIterator
  record INT_RANGE
    Integer current;
    Integer last;
  end INT_RANGE;

  record INT_STEP_RANGE
    Integer current;
    Integer stepsize;
    Integer last;
  end INT_STEP_RANGE;

  record REAL_RANGE
    Real start;
    Real stepsize;
    Integer current;
    Integer steps;
  end REAL_RANGE;

  record ARRAY_RANGE
    list<Expression> values;
  end ARRAY_RANGE;

  record INVALID_RANGE
    Expression exp;
  end INVALID_RANGE;
end NFRangeIterator;

uniontype NFOperator
  type Op = enumeration(
    // Basic arithmetic operators.
    ADD,               // +
    SUB,               // -
    MUL,               // *
    DIV,               // /
    POW,               // ^
    // Element-wise arithmetic operators. These are only used until the type
    // checking, then replaced with a more specific operator.
    ADD_EW,            // .+
    SUB_EW,            // .-
    MUL_EW,            // .*
    DIV_EW,            // ./
    POW_EW,            // .^
    // Scalar-Array and Array-Scalar arithmetic operators.
    ADD_SCALAR_ARRAY,  // scalar + array
    ADD_ARRAY_SCALAR,  // array + scalar
    SUB_SCALAR_ARRAY,  // scalar - array
    SUB_ARRAY_SCALAR,  // array - scalar
    MUL_SCALAR_ARRAY,  // scalar * array
    MUL_ARRAY_SCALAR,  // array * scalar
    MUL_VECTOR_MATRIX, // vector * matrix
    MUL_MATRIX_VECTOR, // matrix * vector
    SCALAR_PRODUCT,    // vector * vector
    MATRIX_PRODUCT,    // matrix * matrix
    DIV_SCALAR_ARRAY,  // scalar / array
    DIV_ARRAY_SCALAR,  // array / scalar
    POW_SCALAR_ARRAY,  // scalar ^ array
    POW_ARRAY_SCALAR,  // array ^ scalar
    POW_MATRIX,        // matrix ^ Integer
    // Unary arithmetic operators.
    UMINUS,            // -
    // Logic operators.
    AND,               // and
    OR,                // or
    NOT,               // not
    // Relational operators.
    LESS,              // <
    LESSEQ,            // <=
    GREATER,           // >
    GREATEREQ,         // >=
    EQUAL,             // ==
    NEQUAL,            // <>
    USERDEFINED        // Overloaded operator.
  );

  record OPERATOR
    Type ty;
    Op op;
  end OPERATOR;
end NFOperator;

    public
  type Condition = enumeration(ZERO_DERIVATIVE, NO_DERIVATIVE);

uniontype NFFunctionDerivative

  record FUNCTION_DER
    InstNode derivativeFn;
    InstNode derivedFn;
    Expression order;
    list<tuple<Integer, Condition>> conditions;
    list<InstNode> lowerOrderDerivatives;
  end FUNCTION_DER;
end NFFunctionDerivative;

uniontype NFType
  type FunctionType = enumeration(
    FUNCTIONAL_PARAMETER "Function parameter of function type.",
    FUNCTION_REFERENCE   "Function name used to reference a function.",
    FUNCTIONAL_VARIABLE  "A variable that contains a function reference."
  );

  record INTEGER
  end INTEGER;

  record REAL
  end REAL;

  record STRING
  end STRING;

  record BOOLEAN
  end BOOLEAN;

  record CLOCK
  end CLOCK;

  record ENUMERATION
    Absyn.Path typePath;
    list<String> literals;
  end ENUMERATION;

  record ENUMERATION_ANY "enumeration(:)"
  end ENUMERATION_ANY;

  record ARRAY
    Type elementType;
    list<Dimension> dimensions;
  end ARRAY;

  record TUPLE
    list<Type> types;
    Option<list<String>> names;
  end TUPLE;

  record NORETCALL
  end NORETCALL;

  record UNKNOWN
  end UNKNOWN;

  record COMPLEX
    InstNode cls;
    ComplexType complexTy;
  end COMPLEX;

  record FUNCTION
    Function fn;
    FunctionType fnType;
  end FUNCTION;

  record METABOXED "Used for MetaModelica generic types"
    Type ty;
  end METABOXED;

  record POLYMORPHIC
    String name;
  end POLYMORPHIC;

  record ANY
  end ANY;
end NFType;

    type ComponentRef = NFComponentRef;
type Connector = NFConnector;
  type Expression = NFExpression;
  type Type = NFType;
  type Builtin = NFBuiltin;
  type BuiltinCall = NFBuiltinCall;
  type Dimension = NFDimension;
  type ExpandExp = NFExpandExp;
  type Function = NFFunction;
    type Prefixes = NFPrefixes;
    type RangeIterator = NFRangeIterator;
    type Restriction = NFRestriction;
    type SimplifyExp = NFSimplifyExp;
    type Subscript = NFSubscript;
    type ComplexType = NFComplexType;
    type ExpressionIterator = NFExpressionIterator;
    type FunctionDerivative = NFFunctionDerivative;
    type Import = NFImport;
    type Lookup = NFLookup;
    type Connection = NFConnection;
    type ConvertDAE = NFConvertDAE;
    type Equation = NFEquation;
      type FlatModel = NFFlatModel;
      type Operator = NFOperator;
      type TypeCheck = NFTypeCheck;
      type Variable = NFVariable;
      type Sections = NFSections;
      type Statement = NFStatement;
      type Connections = NFConnections;
      type Inst = NFInst;
      type Typing = NFTyping;
      type Algorithm = NFAlgorithm;
      type Connection = NFConnection;

annotation(__OpenModelica_Interface="frontend");
end NFTypes;
