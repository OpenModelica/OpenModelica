interface package ExpressionDumpTV

package Tpl
  function addTemplateError
    input String inErrMsg;
  end addTemplateError;
end Tpl;

package Absyn
  type Ident = String;

  uniontype CodeNode
  end CodeNode;

  uniontype Path
    record QUALIFIED
      Ident name;
      Path path;
    end QUALIFIED;

    record IDENT
      Ident name;
    end IDENT;

    record FULLYQUALIFIED
      Path path;
    end FULLYQUALIFIED;
  end Path;

  uniontype ReductionIterType
    record COMBINE
    end COMBINE;
    record THREAD
    end THREAD;
  end ReductionIterType;

end Absyn;

package ClassInf
  function getStateName
    input State inState;
    output Absyn.Path outPath;
  end getStateName;

  uniontype State
    record UNKNOWN
      Absyn.Path path;
    end UNKNOWN;

    record OPTIMIZATION
      Absyn.Path path;
    end OPTIMIZATION;

    record MODEL
      Absyn.Path path;
    end MODEL;

    record RECORD
      Absyn.Path path;
    end RECORD;

    record BLOCK
      Absyn.Path path;
    end BLOCK;

    record CONNECTOR
      Absyn.Path path;
      Boolean isExpandable;
    end CONNECTOR;

    record TYPE
      Absyn.Path path;
    end TYPE;

    record PACKAGE
      Absyn.Path path;
    end PACKAGE;

    record FUNCTION
      Absyn.Path path;
    end FUNCTION;

    record ENUMERATION
      Absyn.Path path;
    end ENUMERATION;

    record HAS_RESTRICTIONS
      Absyn.Path path;
    end HAS_RESTRICTIONS;

    record TYPE_INTEGER
      Absyn.Path path;
    end TYPE_INTEGER;

    record TYPE_REAL
      Absyn.Path path;
    end TYPE_REAL;

    record TYPE_STRING
      Absyn.Path path;
    end TYPE_STRING;

    record TYPE_BOOL
      Absyn.Path path;
    end TYPE_BOOL;

    record TYPE_CLOCK
      Absyn.Path path;
    end TYPE_CLOCK;

    record TYPE_ENUM
      Absyn.Path path;
    end TYPE_ENUM;

    record EXTERNAL_OBJ
      Absyn.Path path;
    end EXTERNAL_OBJ;

    record META_TUPLE
      Absyn.Path path;
    end META_TUPLE;

    record META_LIST
      Absyn.Path path;
    end META_LIST;

    record META_OPTION
      Absyn.Path path;
    end META_OPTION;

    record META_RECORD
      Absyn.Path path;
    end META_RECORD;

    record META_UNIONTYPE
      Absyn.Path path;
    end META_UNIONTYPE;

    record META_ARRAY
      Absyn.Path path;
    end META_ARRAY;

    record META_POLYMORPHIC
      Absyn.Path path;
    end META_POLYMORPHIC;
  end State;
end ClassInf;

package DAE
  type Ident = String;

  uniontype ComponentRef
    record CREF_QUAL
      Ident ident;
      Type identType;
      list<Subscript> subscriptLst;
      ComponentRef componentRef;
    end CREF_QUAL;

    record CREF_IDENT
      Ident ident;
      Type identType;
      list<Subscript> subscriptLst;
    end CREF_IDENT;

    record CREF_ITER
      Ident ident;
      Integer index;
      Type identType;
      list<Subscript> subscriptLst;
    end CREF_ITER;

    record OPTIMICA_ATTR_INST_CREF
      ComponentRef componentRef;
      String instant;
    end OPTIMICA_ATTR_INST_CREF;

    record WILD end WILD;
  end ComponentRef;

  uniontype Const end Const;

  type Dimensions = list<Dimension>;

  uniontype Dimension
    record DIM_INTEGER
      Integer integer;
    end DIM_INTEGER;

    record DIM_ENUM
      Absyn.Path enumTypeName;
      list<String> literals;
      Integer size;
    end DIM_ENUM;

    record DIM_EXP
      Exp exp;
    end DIM_EXP;

    record DIM_UNKNOWN
    end DIM_UNKNOWN;
  end Dimension;

  uniontype ClockKind
    record INFERRED_CLOCK
    end INFERRED_CLOCK;

    record INTEGER_CLOCK
      Exp intervalCounter;
      Exp resolution;
    end INTEGER_CLOCK;

    record REAL_CLOCK
      Exp interval;
    end REAL_CLOCK;

    record BOOLEAN_CLOCK
      Exp condition;
      Exp startInterval;
    end BOOLEAN_CLOCK;

    record SOLVER_CLOCK
      Exp c;
      Exp solverMethod;
    end SOLVER_CLOCK;
  end ClockKind;

  uniontype Exp
    record ICONST
      Integer integer;
    end ICONST;

    record RCONST
      Real real;
    end RCONST;

    record SCONST
      String string;
    end SCONST;

    record BCONST
      Boolean bool;
    end BCONST;

    record CLKCONST
      ClockKind clk;
    end CLKCONST;

    record ENUM_LITERAL
      Absyn.Path name;
      Integer index;
    end ENUM_LITERAL;

    record CREF
      ComponentRef componentRef;
      Type ty;
    end CREF;

    record BINARY
      Exp exp1;
      Operator operator;
      Exp exp2;
    end BINARY;

    record UNARY
      Operator operator;
      Exp exp;
    end UNARY;

    record LBINARY
      Exp exp1;
      Operator operator;
      Exp exp2;
    end LBINARY;

    record LUNARY
      Operator operator;
      Exp exp;
    end LUNARY;

    record RELATION
      Exp exp1;
      Operator operator;
      Exp exp2;
      Integer index;
      Option<tuple<Exp,Integer,Integer>> optionExpisASUB;
    end RELATION;

    record IFEXP
      Exp expCond;
      Exp expThen;
      Exp expElse;
    end IFEXP;

    record CALL
      Absyn.Path path;
      list<Exp> expLst;
      CallAttributes attr;
    end CALL;

    record RECORD
      Absyn.Path path;
      list<Exp> exps;
      list<String> comp;
    end RECORD;

    record PARTEVALFUNCTION
      Absyn.Path path;
      list<Exp> expList;
      Type ty;
    end PARTEVALFUNCTION;

    record ARRAY
      Type ty;
      Boolean scalar;
      list<Exp> array;
    end ARRAY;

    record MATRIX
      Type ty;
      Integer integer;
      list<list<Exp>> matrix;
    end MATRIX;

    record RANGE
      Type ty;
      Exp start;
      Option<Exp> step;
      Exp stop;
    end RANGE;

    record TUPLE
      list<Exp> PR;
    end TUPLE;

    record CAST
      Type ty;
      Exp exp;
    end CAST;

    record ASUB
      Exp exp;
      list<Exp> sub;
    end ASUB;

    record TSUB
      Exp exp;
      Integer ix;
      Type ty;
    end TSUB;

    record RSUB
      Exp exp;
      String fieldName;
      Type ty;
    end RSUB;

    record SIZE
      Exp exp;
      Option<Exp> sz;
    end SIZE;

    record CODE
      Absyn.CodeNode code;
      Type ty;
    end CODE;

    record EMPTY
      String scope;
      ComponentRef name;
      Type ty;
      String tyStr;
    end EMPTY;

    record REDUCTION
      ReductionInfo reductionInfo;
      Exp expr;
      ReductionIterators iterators;
    end REDUCTION;

    record LIST
      list<Exp> valList;
    end LIST;

    record CONS
      Exp car;
      Exp cdr;
    end CONS;

    record META_TUPLE
      list<Exp> listExp;
    end META_TUPLE;

    record META_OPTION
      Option<Exp> exp;
    end META_OPTION;

    record METARECORDCALL
      Absyn.Path path;
      list<Exp> args;
      list<String> fieldNames;
      Integer index;
    end METARECORDCALL;

    record MATCHEXPRESSION
      MatchType matchType;
      list<Exp> inputs;
      list<Element> localDecls;
      list<MatchCase> cases;
      Type et;
    end MATCHEXPRESSION;

    record BOX
      Exp exp;
    end BOX;

    record UNBOX
      Exp exp;
      Type ty;
    end UNBOX;

    record SHARED_LITERAL
      Integer index;
      Exp exp;
    end SHARED_LITERAL;

    record PATTERN
      Pattern pattern;
    end PATTERN;

    record SUM
      Type ty;
      Exp iterator;
      Exp startIt;
      Exp endIt;
      Exp body;
    end SUM;
  end Exp;

  uniontype FuncArg
    record FUNCARG
      String name;
      Type ty;
      Const const;
      VarParallelism par;
      Option<Exp> defaultBinding;
      Boolean structural;
    end FUNCARG;
  end FuncArg;

  uniontype MatchCase
    record CASE
      list<Pattern> patterns;
      list<Statement> body;
      Option<Exp> result;
    end CASE;
  end MatchCase;

  uniontype MatchType
    record MATCHCONTINUE end MATCHCONTINUE;
    record MATCH
      Option<tuple<Integer,Type,Integer>> switch;
    end MATCH;
  end MatchType;

  uniontype Operator
    record ADD
      Type ty;
    end ADD;

    record SUB
      Type ty;
    end SUB;

    record MUL
      Type ty;
    end MUL;

    record DIV
      Type ty;
    end DIV;

    record POW
      Type ty;
    end POW;

    record UMINUS
      Type ty;
    end UMINUS;

    record UMINUS_ARR
      Type ty;
    end UMINUS_ARR;

    record ADD_ARR
      Type ty;
    end ADD_ARR;

    record SUB_ARR
      Type ty;
    end SUB_ARR;

    record MUL_ARR
      Type ty;
    end MUL_ARR;

    record DIV_ARR
      Type ty;
    end DIV_ARR;

    record MUL_ARRAY_SCALAR
      Type ty;
    end MUL_ARRAY_SCALAR;

    record ADD_ARRAY_SCALAR
      Type ty;
    end ADD_ARRAY_SCALAR;

    record SUB_SCALAR_ARRAY
      Type ty;
    end SUB_SCALAR_ARRAY;

    record MUL_SCALAR_PRODUCT
      Type ty;
    end MUL_SCALAR_PRODUCT;

    record MUL_MATRIX_PRODUCT
      Type ty;
    end MUL_MATRIX_PRODUCT;

    record DIV_ARRAY_SCALAR
      Type ty;
    end DIV_ARRAY_SCALAR;

    record DIV_SCALAR_ARRAY
      Type ty;
    end DIV_SCALAR_ARRAY;

    record POW_ARRAY_SCALAR
      Type ty;
    end POW_ARRAY_SCALAR;

    record POW_SCALAR_ARRAY
      Type ty;
    end POW_SCALAR_ARRAY;

    record POW_ARR
      Type ty;
    end POW_ARR;

    record POW_ARR2
      Type ty;
    end POW_ARR2;

    record AND
      Type ty;
    end AND;

    record OR
      Type ty;
    end OR;

    record NOT
      Type ty;
    end NOT;

    record LESS
      Type ty;
    end LESS;

    record LESSEQ
      Type ty;
    end LESSEQ;

    record GREATER
      Type ty;
    end GREATER;

    record GREATEREQ
      Type ty;
    end GREATEREQ;

    record EQUAL
      Type ty;
    end EQUAL;

    record NEQUAL
      Type ty;
    end NEQUAL;

    record USERDEFINED
      Absyn.Path fqName;
    end USERDEFINED;
  end Operator;

  uniontype Pattern
    record PAT_WILD
    end PAT_WILD;

    record PAT_CONSTANT
      Option<Type> ty;
      Exp exp;
    end PAT_CONSTANT;

    record PAT_AS
      String id;
      Option<Type> ty;
      Pattern pat;
    end PAT_AS;

    record PAT_AS_FUNC_PTR
      String id;
      Pattern pat;
    end PAT_AS_FUNC_PTR;

    record PAT_META_TUPLE
      list<Pattern> patterns;
    end PAT_META_TUPLE;

    record PAT_CALL_TUPLE
      list<Pattern> patterns;
    end PAT_CALL_TUPLE;

    record PAT_CONS
      Pattern head;
      Pattern tail;
    end PAT_CONS;

    record PAT_CALL
      Absyn.Path name;
      Integer index;
      list<Pattern> patterns;
      Boolean knownSingleton;
    end PAT_CALL;

    record PAT_CALL_NAMED
      Absyn.Path name;
      list<tuple<Pattern, String, Type>> patterns;
    end PAT_CALL_NAMED;

    record PAT_SOME
      Pattern pat;
    end PAT_SOME;
  end Pattern;

  uniontype CallAttributes
    record CALL_ATTR
      Type ty;
      Boolean builtin;
    end CALL_ATTR;
  end CallAttributes;

  uniontype ReductionInfo
    record REDUCTIONINFO
      Absyn.Path path;
      Absyn.ReductionIterType iterType;
      Type exprType;
      Option<Exp> foldExp;
    end REDUCTIONINFO;
  end ReductionInfo;

  type ReductionIterators = list<ReductionIterator>;

  uniontype ReductionIterator
    record REDUCTIONITER
      String id;
      Exp exp;
      Option<Exp> guardExp;
      Type ty;
    end REDUCTIONITER;
  end ReductionIterator;

  uniontype Statement end Statement;

  uniontype Subscript
    record WHOLEDIM end WHOLEDIM;

    record SLICE
      Exp exp;
    end SLICE;

    record INDEX
      Exp exp;
    end INDEX;

    record WHOLE_NONEXP
      Exp exp;
    end WHOLE_NONEXP;
  end Subscript;

  uniontype Type
    record T_INTEGER
      list<Var> varLst;
    end T_INTEGER;

    record T_REAL
      list<Var> varLst;
    end T_REAL;

    record T_STRING
      list<Var> varLst;
    end T_STRING;

    record T_BOOL
      list<Var> varLst;
    end T_BOOL;

    record T_ENUMERATION
      Absyn.Path path;
    end T_ENUMERATION;

    record T_ARRAY
      Type ty;
      Dimensions dims;
    end T_ARRAY;

    record T_NORETCALL
      TypeSource source;
    end T_NORETCALL;

    record T_UNKNOWN
      TypeSource source;
    end T_UNKNOWN;

    record T_COMPLEX
      ClassInf.State complexClassType;
    end T_COMPLEX;

    record T_SUBTYPE_BASIC
      ClassInf.State complexClassType;
      Type complexType;
    end T_SUBTYPE_BASIC;

    record T_FUNCTION
      list<FuncArg> funcArg;
      Type funcResultType;
    end T_FUNCTION;

    record T_FUNCTION_REFERENCE_VAR
      Type functionType;
    end T_FUNCTION_REFERENCE_VAR;

    record T_FUNCTION_REFERENCE_FUNC
      Boolean builtin;
      Type functionType;
    end T_FUNCTION_REFERENCE_FUNC;

    record T_TUPLE
      list<Type> types;
    end T_TUPLE;

    record T_CODE
      CodeType ty;
    end T_CODE;

    record T_ANYTYPE
      Option<ClassInf.State> anyClassType;
    end T_ANYTYPE;

    record T_METALIST
      Type ty;
    end T_METALIST;

    record T_METATUPLE
      list<Type> types;
    end T_METATUPLE;

    record T_METAOPTION
      Type ty;
    end T_METAOPTION;

    record T_METAUNIONTYPE
      list<Absyn.Path> paths;
      Boolean knownSingleton;
      TypeSource source;
    end T_METAUNIONTYPE;

    record T_METARECORD
      Absyn.Path utPath;
      Integer index;
      list<Var> fields;
      Boolean knownSingleton;
      TypeSource source;
    end T_METARECORD;

    record T_METAARRAY
      Type ty;
    end T_METAARRAY;

    record T_METABOXED
      Type ty;
    end T_METABOXED;

    record T_METAPOLYMORPHIC
      String name;
    end T_METAPOLYMORPHIC;

    record T_METATYPE
      Type ty;
    end T_METATYPE;
  end Type;

  type TypeSource = list<Absyn.Path> "the class(es) where the type originated";

  uniontype Var
    record TYPES_VAR
      Ident name;
    end TYPES_VAR;
  end Var;
end DAE;

package Dump
  function printCodeStr
    input Absyn.CodeNode inCode;
    output String outString;
  end printCodeStr;
end Dump;

package Expression
  function shouldParenthesize
    input DAE.Exp inOperand;
    input DAE.Exp inOperator;
    input Boolean inLhs;
    output Boolean outShouldParenthesize;
  end shouldParenthesize;
end Expression;

package System
  function escapedString
    input String unescapedString;
    input Boolean escapeNewline;
    output String escapedString;
  end escapedString;
end System;

package Config
  function typeinfo
    output Boolean flag;
  end typeinfo;
end Config;

package Types
  function unparseType
    input DAE.Type ty;
    output String str;
  end unparseType;
end Types;

package Flags
  uniontype ConfigFlag end ConfigFlag;
  constant ConfigFlag MODELICA_OUTPUT;
  function getConfigBool
    input ConfigFlag inFlag;
    output Boolean outValue;
  end getConfigBool;
end Flags;

end ExpressionDumpTV;
