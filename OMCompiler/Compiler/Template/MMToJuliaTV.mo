interface package MMToJuliaTV

package builtin
  function listReverse
    input list<T> inLst;
    output list<T> outLst;
    replaceable type T subtypeof Any;
  end listReverse;

  function boolAnd
    input Boolean b1;
    input Boolean b2;
    output Boolean b;
  end boolAnd;

  function boolOr
    input Boolean a;
    input Boolean b;
    output Boolean c;
  end boolOr;

  function boolNot
    input Boolean b;
    output Boolean nb;
  end boolNot;

  uniontype SourceInfo
    record SOURCEINFO
      String fileName;
      Boolean isReadOnly;
      Integer lineNumberStart;
      Integer columnNumberStart;
      Integer lineNumberEnd;
      Integer columnNumberEnd;
    end SOURCEINFO;
  end SourceInfo;
end builtin;

package Absyn
  type Ident = String;

  uniontype Program
    record PROGRAM
      list<Class> classes;
      Within within_;
    end PROGRAM;
  end Program;

  uniontype Within
    record WITHIN
      Path path;
    end WITHIN;

    record TOP end TOP;
  end Within;

  uniontype Class
    record CLASS
      Ident name;
      Boolean partialPrefix;
      Boolean finalPrefix;
      Boolean encapsulatedPrefix;
      Restriction restriction;
      ClassDef body;
      builtin.SourceInfo info;
    end CLASS;
  end Class;

  uniontype ClassDef
    record PARTS
      list<String> typeVars;
      list<NamedArg> classAttrs;
      list<ClassPart> classParts;
      list<Annotation> ann;
      Option<String> comment;
    end PARTS;

    record DERIVED
      TypeSpec typeSpec;
      ElementAttributes attributes;
      list<ElementArg> arguments;
      Option<Comment> comment;
    end DERIVED;

    record ENUMERATION
      EnumDef enumLiterals;
      Option<Comment> comment;
    end ENUMERATION;

    record OVERLOAD
      list<Path> functionNames;
      Option<Comment> comment;
    end OVERLOAD;

    record CLASS_EXTENDS
      Ident baseClassName;
      list<ElementArg> modifications;
      Option<String> comment;
      list<ClassPart> parts;
      list<Annotation> ann;
    end CLASS_EXTENDS;

    record PDER
      Path functionName;
      list<Ident> vars;
      Option<Comment> comment;
    end PDER;
  end ClassDef;

  uniontype TypeSpec
    record TPATH
      Path path;
      Option<ArrayDim> arrayDim;
    end TPATH;

    record TCOMPLEX
      Path path;
      list<TypeSpec> typeSpecs;
      Option<ArrayDim> arrayDim;
    end TCOMPLEX;
  end TypeSpec;

  uniontype EnumDef
    record ENUMLITERALS
      list<EnumLiteral> enumLiterals;
    end ENUMLITERALS;

    record ENUM_COLON end ENUM_COLON;
  end EnumDef;

  uniontype EnumLiteral
    record ENUMLITERAL
      Ident literal;
      Option<Comment> comment;
    end ENUMLITERAL;
  end EnumLiteral;

  uniontype ClassPart
    record PUBLIC
      list<ElementItem> contents;
    end PUBLIC;

    record PROTECTED
      list<ElementItem> contents;
    end PROTECTED;

    record CONSTRAINTS
      list<Exp> contents;
    end CONSTRAINTS;

    record EQUATIONS
      list<EquationItem> contents;
    end EQUATIONS;

    record INITIALEQUATIONS
      list<EquationItem> contents;
    end INITIALEQUATIONS;

    record ALGORITHMS
      list<AlgorithmItem> contents;
    end ALGORITHMS;

    record INITIALALGORITHMS
      list<AlgorithmItem> contents;
    end INITIALALGORITHMS;

    record EXTERNAL
      ExternalDecl externalDecl;
      Option<Annotation> annotation_;
    end EXTERNAL;
  end ClassPart;

  uniontype ElementItem
    record ELEMENTITEM
      Element element;
    end ELEMENTITEM;

    record LEXER_COMMENT
      String comment;
    end LEXER_COMMENT;
  end ElementItem;

  uniontype Element
    record ELEMENT
      Boolean finalPrefix;
      Option<RedeclareKeywords> redeclareKeywords;
      InnerOuter innerOuter;
      ElementSpec specification;
      builtin.SourceInfo info;
      Option<ConstrainClass> constrainClass;
    end ELEMENT;

    record DEFINEUNIT
      Ident name;
      list<NamedArg> args;
    end DEFINEUNIT;

    record TEXT
      Option<Ident> optName;
      String string;
      builtin.SourceInfo info;
    end TEXT;
  end Element;

  uniontype ConstrainClass
    record CONSTRAINCLASS
      ElementSpec elementSpec;
      Option<Comment> comment;
    end CONSTRAINCLASS;
  end ConstrainClass;

  uniontype ElementSpec
    record CLASSDEF
      Boolean replaceable_;
      Class class_;
    end CLASSDEF;

    record EXTENDS
      Path path;
      list<ElementArg> elementArg;
      Option<Annotation> annotationOpt;
    end EXTENDS;

    record IMPORT
      Import import_;
      Option<Comment> comment;
      builtin.SourceInfo info;
    end IMPORT;

    record COMPONENTS
      ElementAttributes attributes;
      TypeSpec typeSpec;
      list<ComponentItem> components;
    end COMPONENTS;
  end ElementSpec;

  uniontype InnerOuter
    record INNER end INNER;
    record OUTER end OUTER;
    record INNER_OUTER end INNER_OUTER;
    record NOT_INNER_OUTER end NOT_INNER_OUTER;
  end InnerOuter;

  uniontype Import
    record NAMED_IMPORT
      Ident name;
      Path path;
    end NAMED_IMPORT;

    record QUAL_IMPORT
      Path path;
    end QUAL_IMPORT;

    record UNQUAL_IMPORT
      Path path;
    end UNQUAL_IMPORT;

    record GROUP_IMPORT
      Path prefix;
      list<GroupImport> groups;
    end GROUP_IMPORT;
  end Import;

  uniontype GroupImport
    record GROUP_IMPORT_NAME
      String name;
    end GROUP_IMPORT_NAME;

    record GROUP_IMPORT_RENAME
      String rename;
      String name;
    end GROUP_IMPORT_RENAME;
  end GroupImport;

  uniontype ComponentItem
    record COMPONENTITEM
      Component component;
      Option<ComponentCondition> condition;
      Option<Comment> comment;
    end COMPONENTITEM;
  end ComponentItem;

  type ComponentCondition = Exp;

  uniontype Component
    record COMPONENT
      Ident name;
      ArrayDim arrayDim;
      Option<Modification> modification;
    end COMPONENT;
  end Component;

  uniontype EquationItem
    record EQUATIONITEM
      Equation equation_;
      Option<Comment> comment;
    end EQUATIONITEM;

    record EQUATIONITEMCOMMENT
      String comment;
    end EQUATIONITEMCOMMENT;
  end EquationItem;

  uniontype AlgorithmItem
    record ALGORITHMITEM
      Algorithm algorithm_;
      Option<Comment> comment;
    end ALGORITHMITEM;

    record ALGORITHMITEMCOMMENT
      String comment;
    end ALGORITHMITEMCOMMENT;
  end AlgorithmItem;

  uniontype Equation
    record EQ_IF
      Exp ifExp;
      list<EquationItem> equationTrueItems;
      list<tuple<Exp, list<EquationItem>>> elseIfBranches;
      list<EquationItem> equationElseItems;
    end EQ_IF;

    record EQ_EQUALS
      Exp leftSide;
      Exp rightSide;
    end EQ_EQUALS;

    record EQ_PDE
      Exp leftSide;
      Exp rightSide;
      ComponentRef domain;
    end EQ_PDE;

    record EQ_CONNECT
      ComponentRef connector1;
      ComponentRef connector2;
    end EQ_CONNECT;

    record EQ_FOR
      ForIterators iterators;
      list<EquationItem> forEquations;
    end EQ_FOR;

    record EQ_WHEN_E
      Exp whenExp;
      list<EquationItem> whenEquations;
      list<tuple<Exp, list<EquationItem>>> elseWhenEquations;
    end EQ_WHEN_E;

    record EQ_NORETCALL
      ComponentRef functionName;
      FunctionArgs functionArgs;
    end EQ_NORETCALL;

    record EQ_FAILURE
      EquationItem equ;
    end EQ_FAILURE;
  end Equation;

  uniontype Algorithm
    record ALG_ASSIGN
      Exp assignComponent;
      Exp value;
    end ALG_ASSIGN;

    record ALG_IF
      Exp ifExp;
      list<AlgorithmItem> trueBranch;
      list<tuple<Exp, list<AlgorithmItem>>> elseIfAlgorithmBranch;
      list<AlgorithmItem> elseBranch;
    end ALG_IF;

    record ALG_FOR
      ForIterators iterators;
      list<AlgorithmItem> forBody;
    end ALG_FOR;

    record ALG_PARFOR
      ForIterators iterators;
      list<AlgorithmItem> parforBody;
    end ALG_PARFOR;

    record ALG_WHILE
      Exp boolExpr;
      list<AlgorithmItem> whileBody;
    end ALG_WHILE;

    record ALG_WHEN_A
      Exp boolExpr;
      list<AlgorithmItem> whenBody;
      list<tuple<Exp, list<AlgorithmItem>>> elseWhenAlgorithmBranch;
    end ALG_WHEN_A;

    record ALG_NORETCALL
      ComponentRef functionCall;
      FunctionArgs functionArgs;
    end ALG_NORETCALL;

    record ALG_RETURN end ALG_RETURN;
    record ALG_BREAK end ALG_BREAK;

    record ALG_FAILURE
      list<AlgorithmItem> equ;
    end ALG_FAILURE;

    record ALG_TRY
      list<AlgorithmItem> body;
      list<AlgorithmItem> elseBody;
    end ALG_TRY;

    record ALG_CONTINUE end ALG_CONTINUE;
  end Algorithm;

  uniontype Modification
    record CLASSMOD
      list<ElementArg> elementArgLst;
      EqMod eqMod;
    end CLASSMOD;
  end Modification;

  uniontype EqMod
    record NOMOD end NOMOD;

    record EQMOD
      Exp exp;
    end EQMOD;
  end EqMod;

  uniontype ElementArg
    record MODIFICATION
      Boolean finalPrefix;
      Each eachPrefix;
      Path path;
      Option<Modification> modification;
      Option<String> comment;
    end MODIFICATION;

    record REDECLARATION
      Boolean finalPrefix;
      RedeclareKeywords redeclareKeywords;
      Each eachPrefix;
      ElementSpec elementSpec;
      Option<ConstrainClass> constrainClass;
    end REDECLARATION;
  end ElementArg;

  uniontype RedeclareKeywords
    record REDECLARE end REDECLARE;
    record REPLACEABLE end REPLACEABLE;
    record REDECLARE_REPLACEABLE end REDECLARE_REPLACEABLE;
  end RedeclareKeywords;

  uniontype Each
    record EACH end EACH;
    record NON_EACH end NON_EACH;
  end Each;

  uniontype ElementAttributes
    record ATTR
      Boolean flowPrefix;
      Boolean streamPrefix;
      Parallelism parallelism;
      Variability variability;
      IsField isField;
      Direction direction;
      ArrayDim arrayDim;
    end ATTR;
  end ElementAttributes;

  uniontype IsField "Is field"
    record NONFIELD "variable is not a field"  end NONFIELD;
    record FIELD "variable is a field"         end FIELD;
  end IsField;

  uniontype Parallelism
    record PARGLOBAL end PARGLOBAL;
    record PARLOCAL end PARLOCAL;
    record NON_PARALLEL end NON_PARALLEL;
  end Parallelism;

  uniontype FlowStream
    record FLOW end FLOW;
    record STREAM end STREAM;
    record NOT_FLOW_STREAM end NOT_FLOW_STREAM;
  end FlowStream;

  uniontype Variability
    record VAR end VAR;
    record DISCRETE end DISCRETE;
    record PARAM end PARAM;
    record CONST end CONST;
  end Variability;

  uniontype Direction
    record INPUT end INPUT;
    record OUTPUT end OUTPUT;
    record BIDIR end BIDIR;
    record INPUT_OUTPUT end INPUT_OUTPUT;
  end Direction;

  uniontype ForIterator
    record ITERATOR
      String name;
      Option<Exp> guardExp;
      Option<Exp> range;
    end ITERATOR;
  end ForIterator;

  type ForIterators = list<ForIterator>;

  uniontype Exp
    record INTEGER
      Integer value;
    end INTEGER;

    record REAL
      String value;
    end REAL;

    record CREF
      ComponentRef componentRef;
    end CREF;

    record STRING
      String value;
    end STRING;

    record BOOL
      Boolean value;
    end BOOL;

    record BINARY
      Exp exp1;
      Operator op;
      Exp exp2;
    end BINARY;

    record UNARY
      Operator op;
      Exp exp;
    end UNARY;

    record LBINARY
      Exp exp1;
      Operator op;
      Exp exp2;
    end LBINARY;

    record LUNARY
      Operator op;
      Exp exp;
    end LUNARY;

    record RELATION
      Exp exp1;
      Operator op;
      Exp exp2;
    end RELATION;

    record IFEXP
      Exp ifExp;
      Exp trueBranch;
      Exp elseBranch;
      list<tuple<Exp, Exp>> elseIfBranch;
    end IFEXP;

    record CALL
      ComponentRef function_;
      FunctionArgs functionArgs ;
    end CALL;

    record PARTEVALFUNCTION
      ComponentRef function_;
      FunctionArgs functionArgs ;
    end PARTEVALFUNCTION;

    record ARRAY
      list<Exp> arrayExp ;
    end ARRAY;

    record MATRIX
      list<list<Exp>> matrix ;
    end MATRIX;

    record RANGE
      Exp start;
      Option<Exp> step;
      Exp stop;
    end RANGE;

    record TUPLE
      list<Exp> expressions;
    end TUPLE;

    record END
    end END;

    record CODE
      CodeNode code;
    end CODE;

    record AS
      Ident id;
      Exp exp;
    end AS;

    record CONS
      Exp head;
      Exp rest;
    end CONS;

    record MATCHEXP
      MatchType matchTy;
      Exp inputExp;
      list<ElementItem> localDecls;
      list<Case> cases;
      Option<String> comment;
    end MATCHEXP;

    record LIST
      list<Exp> exps;
    end LIST;

    record DOT "exp.index"
      Exp exp;
      Exp index;
    end DOT;

  end Exp;

  uniontype Case
    record CASE
      Exp pattern;
      Option<Exp> patternGuard;
      builtin.SourceInfo patternInfo;
      list<ElementItem> localDecls;
      ClassPart classPart;
      Exp result;
      builtin.SourceInfo resultInfo;
      Option<String> comment;
      builtin.SourceInfo info;
    end CASE;

    record ELSE
      list<ElementItem> localDecls;
      ClassPart classPart;
      Exp result;
      builtin.SourceInfo resultInfo;
      Option<String> comment;
      builtin.SourceInfo info;
    end ELSE;
  end Case;

  uniontype MatchType
    record MATCH end MATCH;
    record MATCHCONTINUE end MATCHCONTINUE;
  end MatchType;

  uniontype CodeNode
    record C_TYPENAME
      Path path;
    end C_TYPENAME;

    record C_VARIABLENAME
      ComponentRef componentRef;
    end C_VARIABLENAME;

    record C_CONSTRAINTSECTION
      Boolean boolean;
      list<EquationItem> equationItemLst;
    end C_CONSTRAINTSECTION;

    record C_EQUATIONSECTION
      Boolean boolean;
      list<EquationItem> equationItemLst;
    end C_EQUATIONSECTION;

    record C_ALGORITHMSECTION
      Boolean boolean;
      list<AlgorithmItem> algorithmItemLst;
    end C_ALGORITHMSECTION;

    record C_ELEMENT
      Element element;
    end C_ELEMENT;

    record C_EXPRESSION
      Exp exp;
    end C_EXPRESSION;

    record C_MODIFICATION
      Modification modification;
    end C_MODIFICATION;
  end CodeNode;

  uniontype FunctionArgs
    record FUNCTIONARGS
      list<Exp> args;
      list<NamedArg> argNames;
    end FUNCTIONARGS;

    record FOR_ITER_FARG
      Exp  exp;
      ReductionIterType iterType;
      ForIterators iterators;
    end FOR_ITER_FARG;
  end FunctionArgs;

  uniontype ReductionIterType
    record COMBINE
    end COMBINE;
    record THREAD
    end THREAD;
  end ReductionIterType;

  uniontype NamedArg
    record NAMEDARG
      Ident argName;
      Exp argValue;
    end NAMEDARG;
  end NamedArg;

  uniontype Operator
    record ADD end ADD;
    record SUB end SUB;
    record MUL end MUL;
    record DIV end DIV;
    record POW end POW;
    record UPLUS end UPLUS;
    record UMINUS end UMINUS;
    record ADD_EW end ADD_EW;
    record SUB_EW end SUB_EW;
    record MUL_EW end MUL_EW;
    record DIV_EW end DIV_EW;
    record POW_EW end POW_EW;
    record UPLUS_EW end UPLUS_EW;
    record UMINUS_EW end UMINUS_EW;
    record AND end AND;
    record OR end OR;
    record NOT end NOT;
    record LESS end LESS;
    record LESSEQ end LESSEQ;
    record GREATER end GREATER;
    record GREATEREQ end GREATEREQ;
    record EQUAL end EQUAL;
    record NEQUAL end NEQUAL;
  end Operator;

  uniontype Subscript
    record NOSUB end NOSUB;

    record SUBSCRIPT
      Exp subscript;
    end SUBSCRIPT;
  end Subscript;

  type ArrayDim = list<Subscript>;

  uniontype ComponentRef
    record CREF_FULLYQUALIFIED
      ComponentRef componentRef;
    end CREF_FULLYQUALIFIED;
    record CREF_QUAL
      Ident name;
      list<Subscript> subscripts;
      ComponentRef componentRef;
    end CREF_QUAL;

    record CREF_IDENT
      Ident name;
      list<Subscript> subscripts;
    end CREF_IDENT;

    record WILD end WILD;
    record ALLWILD end ALLWILD;
  end ComponentRef;

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

  uniontype Restriction
    record R_CLASS end R_CLASS;
    record R_OPTIMIZATION end R_OPTIMIZATION;
    record R_MODEL end R_MODEL;
    record R_RECORD end R_RECORD;
    record R_BLOCK end R_BLOCK;
    record R_CONNECTOR end R_CONNECTOR;
    record R_EXP_CONNECTOR end R_EXP_CONNECTOR;
    record R_TYPE end R_TYPE;
    record R_PACKAGE end R_PACKAGE;
    record R_FUNCTION
      FunctionRestriction functionRestriction;
    end R_FUNCTION;
    record R_OPERATOR end R_OPERATOR;
    record R_OPERATOR_RECORD end R_OPERATOR_RECORD;
    record R_ENUMERATION end R_ENUMERATION;
    record R_PREDEFINED_INTEGER end R_PREDEFINED_INTEGER;
    record R_PREDEFINED_REAL end R_PREDEFINED_REAL;
    record R_PREDEFINED_STRING end R_PREDEFINED_STRING;
    record R_PREDEFINED_BOOLEAN end R_PREDEFINED_BOOLEAN;
    record R_PREDEFINED_ENUMERATION end R_PREDEFINED_ENUMERATION;
    record R_UNIONTYPE end R_UNIONTYPE;
    record R_METARECORD
      Path name;
      Integer index;
      Boolean singleton;
      list<String> typeVars;
    end R_METARECORD;
    record R_UNKNOWN  end R_UNKNOWN;
  end Restriction;

  uniontype FunctionPurity
    record PURE end PURE;
    record IMPURE end IMPURE;
    record NO_PURITY end NO_PURITY;
  end FunctionPurity;

  uniontype FunctionRestriction
    record FR_NORMAL_FUNCTION
      FunctionPurity purity;
    end FR_NORMAL_FUNCTION;

    record FR_OPERATOR_FUNCTION end FR_OPERATOR_FUNCTION;
    record FR_PARALLEL_FUNCTION end FR_PARALLEL_FUNCTION;
    record FR_KERNEL_FUNCTION end FR_KERNEL_FUNCTION;
  end FunctionRestriction;

  uniontype Annotation
    record ANNOTATION
      list<ElementArg> elementArgs;
    end ANNOTATION;
  end Annotation;

  uniontype Comment
    record COMMENT
      Option<Annotation> annotation_;
      Option<String> comment;
    end COMMENT;
  end Comment;

  uniontype ExternalDecl
    record EXTERNALDECL
      Option<Ident> funcName;
      Option<String> lang;
      Option<ComponentRef> output_;
      list<Exp> args;
      Option<Annotation> annotation_;
    end EXTERNALDECL;
  end ExternalDecl;

  function isClassdef
    input Element inElement;
    output Boolean b;
  end isClassdef;

end Absyn;

package Config
  function acceptMetaModelicaGrammar
    output Boolean outBoolean;
  end acceptMetaModelicaGrammar;
  function showAnnotations
    output Boolean show;
  end showAnnotations;
end Config;

package Dump
  function shouldParenthesize
    input Absyn.Exp inOperand;
    input Absyn.Exp inOperator;
    input Boolean inLhs;
    output Boolean outShouldParenthesize;
  end shouldParenthesize;

  uniontype DumpOptions
    record DUMPOPTIONS
      String fileName;
    end DUMPOPTIONS;
  end DumpOptions;

  constant DumpOptions defaultDumpOptions;

  function boolUnparseFileFromInfo
    input builtin.SourceInfo info;
    input DumpOptions options;
    output Boolean b;
  end boolUnparseFileFromInfo;

  function expPriority
    input Absyn.Exp inExp;
    output Integer outInteger;
  end expPriority;
end Dump;

package Tpl
  function addSourceTemplateError
    input String inErrMsg;
    input builtin.SourceInfo inInfo;
  end addSourceTemplateError;

  function addTemplateError
    input String inErrMsg;
  end addTemplateError;
end Tpl;

package Flags
  uniontype ConfigFlag end ConfigFlag;
  constant ConfigFlag MODELICA_OUTPUT;
  function getConfigBool
    input ConfigFlag inFlag;
    output Boolean outValue;
  end getConfigBool;
end Flags;


package builtin
  function boolNot
    input Boolean inBoolean;
    output Boolean outNegatedBoolean;
  end boolNot;

  function intLt
    input Integer x;
    input Integer y;
    output Boolean outResult;
  end intLt;

  function intEq
    input Integer x;
    input Integer y;
    output Boolean outResult;
  end intEq;

  function listLength "Return the length of the list"
    replaceable type TypeVar subtypeof Any;
    input list<TypeVar> lst;
    output Integer result;
  end listLength;

  uniontype SourceInfo "The Info attribute provides location information for elements and classes."
    record SOURCEINFO
      String fileName;
      Boolean isReadOnly;
      Integer lineNumberStart;
      Integer columnNumberStart;
      Integer lineNumberEnd;
      Integer columnNumberEnd;
      Real lastModification;
    end SOURCEINFO;
  end SourceInfo;

end builtin;

package SCode
  type Ident = Absyn.Ident;
  type Path = Absyn.Path;
  type Subscript = Absyn.Subscript;

  uniontype Restriction
    record R_CLASS end R_CLASS;
    record R_OPTIMIZATION end R_OPTIMIZATION;
    record R_MODEL end R_MODEL;
    record R_RECORD
    Boolean isOperator;
  end R_RECORD;
    record R_BLOCK end R_BLOCK;
    record R_CONNECTOR
      Boolean isExpandable;
    end R_CONNECTOR;
    record R_OPERATOR end R_OPERATOR;
    record R_OPERATOR_FUNCTION end R_OPERATOR_FUNCTION;
    record R_OPERATOR_RECORD end R_OPERATOR_RECORD;
    record R_TYPE end R_TYPE;
    record R_PACKAGE end R_PACKAGE;
    record R_FUNCTION
      FunctionRestriction functionRestriction;
    end R_FUNCTION;
    record R_EXT_FUNCTION end R_EXT_FUNCTION;
    record R_ENUMERATION end R_ENUMERATION;

    record R_PREDEFINED_INTEGER     end R_PREDEFINED_INTEGER;
    record R_PREDEFINED_REAL        end R_PREDEFINED_REAL;
    record R_PREDEFINED_STRING      end R_PREDEFINED_STRING;
    record R_PREDEFINED_BOOLEAN     end R_PREDEFINED_BOOLEAN;
    record R_PREDEFINED_ENUMERATION end R_PREDEFINED_ENUMERATION;

    record R_METARECORD
      Absyn.Path name;
      Integer index;
      list<String> typeVars;
    end R_METARECORD;

    record R_UNIONTYPE
      list<String> typeVars;
    end R_UNIONTYPE;
  end Restriction;

  uniontype FunctionRestriction
    record FR_NORMAL_FUNCTION "a normal function"
      Boolean isImpure;
    end FR_NORMAL_FUNCTION;
    record FR_EXTERNAL_FUNCTION "an external function"
      Boolean isImpure;
    end FR_EXTERNAL_FUNCTION;

    record FR_OPERATOR_FUNCTION "an operator function" end FR_OPERATOR_FUNCTION;
    record FR_RECORD_CONSTRUCTOR "record constructor"  end FR_RECORD_CONSTRUCTOR;
  end FunctionRestriction;

  uniontype Mod
    record MOD
      Final finalPrefix;
      Each  eachPrefix;
      list<SubMod> subModLst;
      Option<Absyn.Exp> binding;
    end MOD;

    record REDECL
      Final         finalPrefix;
      Each          eachPrefix;
      Element       element;
    end REDECL;

    record NOMOD end NOMOD;
  end Mod;

  uniontype SubMod
    record NAMEMOD
      Ident ident;
      Mod mod;
    end NAMEMOD;
  end SubMod;

  type Program = list<Element>;

  uniontype Enum
    record ENUM
      Ident   literal;
      Comment comment;
    end ENUM;
  end Enum;

  uniontype ClassDef
    record PARTS
      list<Element> elementLst;
      list<Equation> normalEquationLst;
      list<Equation> initialEquationLst;
      list<AlgorithmSection> normalAlgorithmLst;
      list<AlgorithmSection> initialAlgorithmLst;
      Option<ExternalDecl> externalDecl;
    end PARTS;

    record CLASS_EXTENDS
      Ident baseClassName;
      Mod modifications;
      ClassDef composition;
    end CLASS_EXTENDS;

    record DERIVED
      Absyn.TypeSpec typeSpec;
      Mod modifications;
      Attributes attributes;
    end DERIVED;

    record ENUMERATION
      list<Enum> enumLst;
    end ENUMERATION;

    record OVERLOAD
      list<Absyn.Path> pathLst;
    end OVERLOAD;

    record PDER
      Absyn.Path functionPath;
      list<Ident> derivedVariables;
    end PDER;

  end ClassDef;

  uniontype Comment
    record COMMENT
      Option<Annotation> annotation_;
      Option<String> comment;
    end COMMENT;
  end Comment;

  uniontype Annotation
    record ANNOTATION
      Mod modification;
    end ANNOTATION;
  end Annotation;

  uniontype ExternalDecl
    record EXTERNALDECL
      Option<Ident> funcName;
      Option<String> lang;
      Option<Absyn.ComponentRef> output_;
      list<Absyn.Exp>      args;
      Option<Annotation>   annotation_ ;
    end EXTERNALDECL;

  end ExternalDecl;

  uniontype Equation
    record EQUATION
      EEquation eEquation;
    end EQUATION;
  end Equation;

  uniontype EEquation
    record EQ_IF
      list<Absyn.Exp> condition;
      list<list<EEquation>> thenBranch;
      list<EEquation>       elseBranch;
      Comment comment;
      SourceInfo info;
    end EQ_IF;

    record EQ_EQUALS
      Absyn.Exp expLeft;
      Absyn.Exp expRight;
      Comment comment;
      SourceInfo info;
    end EQ_EQUALS;

    record EQ_PDE
      Absyn.Exp expLeft;
      Absyn.Exp expRight;
      ComponentRef domain;
      Comment comment;
      SourceInfo info;
    end EQ_PDE;

    record EQ_CONNECT
      Absyn.ComponentRef crefLeft;
      Absyn.ComponentRef crefRight;
      Comment comment;
      SourceInfo info;
    end EQ_CONNECT;

    record EQ_FOR
      Ident index;
      Option<Absyn.Exp> range;
      list<EEquation> eEquationLst;
      Comment comment;
      SourceInfo info;
    end EQ_FOR;

    record EQ_WHEN
      Absyn.Exp condition;
      list<EEquation> eEquationLst;
      list<tuple<Absyn.Exp, list<EEquation>>> elseBranches;
      Comment comment;
      SourceInfo info;
    end EQ_WHEN;

    record EQ_ASSERT
      Absyn.Exp condition;
      Absyn.Exp message;
      Absyn.Exp level;
      Comment comment;
      SourceInfo info;
    end EQ_ASSERT;

    record EQ_TERMINATE
      Absyn.Exp message;
      Comment comment;
      SourceInfo info;
    end EQ_TERMINATE;

    record EQ_REINIT
      Absyn.Exp cref;
      Absyn.Exp expReinit;
      Comment comment;
      SourceInfo info;
    end EQ_REINIT;

    record EQ_NORETCALL
      Absyn.Exp exp;
      Comment comment;
      SourceInfo info;
    end EQ_NORETCALL;

  end EEquation;

  uniontype AlgorithmSection
    record ALGORITHM
      list<Statement> statements;
    end ALGORITHM;

  end AlgorithmSection;

  uniontype Statement
    record ALG_ASSIGN
      Absyn.Exp assignComponent;
      Absyn.Exp value;
      Comment comment;
      SourceInfo info;
    end ALG_ASSIGN;

    record ALG_IF
      Absyn.Exp boolExpr;
      list<Statement> trueBranch;
      list<tuple<Absyn.Exp, list<Statement>>> elseIfBranch;
      list<Statement> elseBranch;
      Comment comment;
      SourceInfo info;
    end ALG_IF;

    record ALG_FOR
      String index;
      Option<Absyn.Exp> range;
      list<Statement> forBody;
      Comment comment;
      SourceInfo info;
    end ALG_FOR;

    record ALG_WHILE
      Absyn.Exp boolExpr;
      list<Statement> whileBody;
      Comment comment;
      SourceInfo info;
    end ALG_WHILE;

    record ALG_WHEN_A
      list<tuple<Absyn.Exp, list<Statement>>> branches;
      Comment comment;
      SourceInfo info;
    end ALG_WHEN_A;

    record ALG_ASSERT
      Absyn.Exp condition;
      Absyn.Exp message;
      Absyn.Exp level;
      Comment comment;
      SourceInfo info;
    end ALG_ASSERT;

    record ALG_TERMINATE
      Absyn.Exp message;
      Comment comment;
      SourceInfo info;
    end ALG_TERMINATE;

    record ALG_REINIT
      Absyn.Exp cref;
      Absyn.Exp newValue;
      Comment comment;
      SourceInfo info;
    end ALG_REINIT;

    record ALG_NORETCALL
      Absyn.Exp exp;
      Comment comment;
      SourceInfo info;
    end ALG_NORETCALL;

    record ALG_RETURN
      Comment comment;
      SourceInfo info;
    end ALG_RETURN;

    record ALG_BREAK
      Comment comment;
      SourceInfo info;
    end ALG_BREAK;

    record ALG_CATCH
      list<Statement> catchBody;
      Comment comment;
      SourceInfo info;
    end ALG_CATCH;

    record ALG_THROW
      Comment comment;
      SourceInfo info;
    end ALG_THROW;

    record ALG_FAILURE
      list<Statement> stmts;
      Comment comment;
      SourceInfo info;
    end ALG_FAILURE;

    record ALG_TRY
      list<Statement> body;
      list<Statement> elseBody;
      Comment comment;
      SourceInfo info;
    end ALG_TRY;

    record ALG_CONTINUE
      Comment comment;
      SourceInfo info;
    end ALG_CONTINUE;

  end Statement;

  uniontype Visibility
    record PUBLIC end PUBLIC;
    record PROTECTED end PROTECTED;
  end Visibility;

  uniontype Redeclare
    record REDECLARE end REDECLARE;
    record NOT_REDECLARE end NOT_REDECLARE;
  end Redeclare;

  uniontype ConstrainClass
    record CONSTRAINCLASS
      Absyn.Path constrainingClass;
      Mod modifier;
      Option<Comment> comment;
    end CONSTRAINCLASS;
  end ConstrainClass;

  uniontype Replaceable
    record REPLACEABLE
      Option<ConstrainClass> cc;
    end REPLACEABLE;
    record NOT_REPLACEABLE end NOT_REPLACEABLE;
  end Replaceable;

  uniontype Final
    record FINAL end FINAL;
    record NOT_FINAL end NOT_FINAL;
  end Final;

  uniontype Each
    record EACH end EACH;
    record NOT_EACH end NOT_EACH;
  end Each;

  uniontype Encapsulated
    record ENCAPSULATED end ENCAPSULATED;
    record NOT_ENCAPSULATED end NOT_ENCAPSULATED;
  end Encapsulated;

  uniontype Partial
    record PARTIAL end PARTIAL;
    record NOT_PARTIAL end NOT_PARTIAL;
  end Partial;

  uniontype ConnectorType
    record POTENTIAL end POTENTIAL;
    record FLOW end FLOW;
    record STREAM end STREAM;
  end ConnectorType;

  uniontype Prefixes
    record PREFIXES
      Visibility visibility;
      Redeclare redeclarePrefix;
      Final finalPrefix;
      Absyn.InnerOuter innerOuter;
      Replaceable replaceablePrefix;
    end PREFIXES;
  end Prefixes;

  uniontype Element
    record IMPORT
      Absyn.Import imp;
      Visibility   visibility;
      SourceInfo   info;
    end IMPORT;

    record EXTENDS
      Path baseClassPath;
      Visibility visibility;
      Mod modifications;
      Option<Annotation> ann;
      SourceInfo info;
    end EXTENDS;

    record CLASS
      Ident name;
      Prefixes prefixes;
      Encapsulated encapsulatedPrefix;
      Partial partialPrefix;
      Restriction restriction;
      ClassDef classDef;
      Comment cmt;
      SourceInfo info;
    end CLASS;

    record COMPONENT
      Ident name;
      Prefixes prefixes;
      Attributes attributes;
      Absyn.TypeSpec typeSpec;
      Mod modifications;
      Comment comment;
      Option<Absyn.Exp> condition;
      SourceInfo info;
    end COMPONENT;

    record DEFINEUNIT
      Ident name;
      Visibility visibility;
      Option<String> exp;
      Option<Real> weight;
    end DEFINEUNIT;

  end Element;

  uniontype Attributes
    record ATTR
      Absyn.ArrayDim arrayDims;
      ConnectorType connectorType;
      Parallelism parallelism;
      Variability variability;
      Absyn.Direction direction;
    end ATTR;
  end Attributes;

  uniontype Parallelism
    record PARGLOBAL      end PARGLOBAL;
    record PARLOCAL       end PARLOCAL;
    record NON_PARALLEL   end NON_PARALLEL;
  end Parallelism;

  uniontype Variability
    record VAR      end VAR;
    record DISCRETE end DISCRETE;
    record PARAM    end PARAM;
    record CONST    end CONST;
  end Variability;

  uniontype Initial
    record INITIAL end INITIAL;
    record NON_INITIAL end NON_INITIAL;
  end Initial;

  function getOutputElements
    input list<Element> inElements;
    output list<Element> outElements;
  end getOutputElements;

end SCode;

package SCodeDump
  uniontype SCodeDumpOptions
    record OPTIONS
      Boolean stripAlgorithmSections;
      Boolean stripProtectedImports;
      Boolean stripStringComments;
      Boolean stripExternalDecl;
      Boolean stripOutputBindings;
    end OPTIONS;
  end SCodeDumpOptions;
  constant SCodeDumpOptions defaultOptions;

  function filterElements
    input list<SCode.Element> element;
    input SCodeDumpOptions options;
    output list<SCode.Element> outElements;
  end filterElements;

end SCodeDump;

package Tpl
  function addTemplateError
    input String inErrMsg;
  end addTemplateError;
  function addSourceTemplateError
    "Wraps call to Error.addSourceMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
    input String inErrMsg;
    input builtin.SourceInfo inInfo;
  end addSourceTemplateError;
end Tpl;

package System
  function escapedString
    input String unescapedString;
    input Boolean unescapeNewline;
    output String escapedString;
  end escapedString;
  function trimWhitespace
    input String inString;
    output String outString;
  end trimWhitespace;
  function stringReplace
    input String str;
    input String source;
    input String target;
    output String res;
  end stringReplace;
end System;

package Util
  type StatefulBoolean = array<Boolean>;
  function getStatefulBoolean
    input StatefulBoolean sb;
    output Boolean b;
  end getStatefulBoolean;
  function setStatefulBoolean
    input StatefulBoolean sb;
    input Boolean b;
  end setStatefulBoolean;
  function makeStatefulBoolean
    input Boolean b;
    output StatefulBoolean sb;
  end makeStatefulBoolean;
end Util;

package Error
  function infoStr
    input builtin.SourceInfo info;
    output String str;
  end infoStr;
end Error;

package SCodeUtil

  function translateEquations
    input list<Absyn.EquationItem> inAbsynEquationItemLst;
    input Boolean inIsInitial;
    output list<SCode.Equation> outEquationLst;
  end translateEquations;

  function translateClassdefAlgorithmitems
    input list<Absyn.AlgorithmItem> inStatements;
    output list<SCode.Statement> outStatements;
  end translateClassdefAlgorithmitems;

  function translateEitemlist
    input list<Absyn.ElementItem> inAbsynElementItemLst;
    // input SCode.Visibility inVisibility = SCode.PUBLIC();
    output list<SCode.Element> outElementLst;
  end translateEitemlist;

end SCodeUtil;

package MMToJuliaUtil
  uniontype Context
    record FUNCTION
    end FUNCTION;
    record PACKAGE
    end PACKAGE;
    record UNIONTYPE
      String name;
    end UNIONTYPE;
  end Context;
  constant Context packageContext;
  constant Context functionContext;
  function makeUniontypeContext
    input String name;
    output Context context;
  end makeUniontypeContext;
end MMToJuliaUtil;

end MMToJuliaTV;