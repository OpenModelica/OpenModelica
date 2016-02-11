interface package SCodeTV

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
end builtin;

package Absyn
  type Ident = String;

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
      Real value;
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
  end Exp;

  uniontype Case
    record CASE
      Exp pattern;
      Info patternInfo;
      list<ElementItem> localDecls;
      list<EquationItem>  equations;
      Exp result;
      Info resultInfo;
      Option<String> comment;
      Info info;
    end CASE;

    record ELSE
      list<ElementItem> localDecls;
      list<EquationItem>  equations;
      Exp result;
      Info resultInfo;
      Option<String> comment;
      Info info;
    end ELSE;
  end Case;

  uniontype MatchType
    record MATCH end MATCH;
    record MATCHCONTINUE end MATCHCONTINUE;
  end MatchType;

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

  uniontype FunctionArgs
    record FUNCTIONARGS
      list<Exp> args;
      list<NamedArg> argNames;
    end FUNCTIONARGS;

    record FOR_ITER_FARG
      Exp  exp;
      ForIterators iterators;
    end FOR_ITER_FARG;
  end FunctionArgs;

  uniontype NamedArg
    record NAMEDARG
      Ident argName;
      Exp argValue;
    end NAMEDARG;
  end NamedArg;

  uniontype InnerOuter
    record INNER end INNER;
    record OUTER end OUTER;
    record INNER_OUTER end INNER_OUTER;
    record NOT_INNER_OUTER end NOT_INNER_OUTER;
  end InnerOuter;

  uniontype Direction
    record INPUT end INPUT;
    record OUTPUT end OUTPUT;
    record BIDIR end BIDIR;
  end Direction;

  uniontype TypeSpec
    record TPATH
      Path path;
      Option<ArrayDim> arrayDim;
    end TPATH;

    record TCOMPLEX
      Path             path;
      list<TypeSpec>   typeSpecs;
      Option<ArrayDim> arrayDim;
    end TCOMPLEX;
  end TypeSpec;
end Absyn;

package Dump
  function expPriority
    input Absyn.Exp inExp;
    output Integer outInteger;
  end expPriority;
end Dump;

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
    end R_METARECORD;

    record R_UNIONTYPE
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
      Absyn.ComponentRef cref;
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
      Absyn.ComponentRef cref;
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
end Tpl;

package Config
  function showAnnotations
    output Boolean show;
  end showAnnotations;
end Config;

package System
  function escapedString
    input String unescapedString;
    input Boolean unescapeNewline;
    output String escapedString;
  end escapedString;
end System;

end SCodeTV;
