/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2019, Open Source Modelica Consortium (OSMC),
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

interface package AbsynToJuliaTV

package builtin

  function listHead
    input list<T> lst;
    output T head;
    replaceable type T subtypeof Any;
  end listHead;

  function listEmpty
    input list<T> lst;
    output Boolean b;
    replaceable type T subtypeof Any;
  end listEmpty;

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


  function stringEqual
    input String s1;
    input String s2;
    output Boolean b;
  end stringEqual;

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

package Static
  function fromEquationsToAlgAssignments
    input Absyn.ClassPart cp;
    output list<Absyn.AlgorithmItem> algsOut;
  end fromEquationsToAlgAssignments;
end Static;

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
end Absyn;

package Config
  function acceptMetaModelicaGrammar
    output Boolean outBoolean;
  end acceptMetaModelicaGrammar;
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

end Dump;

package System
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
  function escapedString
    input String unescapedString;
    input Boolean unescapeNewline;
    output String escapedString;
  end escapedString;
end System;

package Tpl
  function addSourceTemplateError
    input String inErrMsg;
    input builtin.SourceInfo inInfo;
  end addSourceTemplateError;

  function addTemplateError
    input String inErrMsg;
  end addTemplateError;

uniontype Text
  record MEM_TEXT
  end MEM_TEXT;
  record FILE_TEXT
  end FILE_TEXT;
end Text;

constant Text emptyTxt;

uniontype BlockTypeFileText
  record BT_FILE_TEXT
  end BT_FILE_TEXT;
end BlockTypeFileText;

uniontype StringToken
  record ST_NEW_LINE "Always outputs the new-line char." end ST_NEW_LINE;

  record ST_STRING "A string without new-lines in it."
    String value;
  end ST_STRING;

  record ST_LINE "A (non-empty) string with new-line at the end."
    String line;
  end ST_LINE;

  record ST_STRING_LIST "Every string in the list can have a new-line at its end (but does not have to)."
    list<String> strList;
    Boolean lastHasNewLine "True when the last string in the list has new-line at the end.";
  end ST_STRING_LIST;

  record ST_BLOCK
    Tokens tokens;
    BlockType blockType;
  end ST_BLOCK;
end StringToken;

uniontype BlockType
  record BT_TEXT  end BT_TEXT;

  record BT_INDENT
    Integer width;
  end BT_INDENT;

  record BT_ABS_INDENT
    Integer width;
  end BT_ABS_INDENT;

  record BT_REL_INDENT
    Integer offset;
  end BT_REL_INDENT;

  record BT_ANCHOR
    Integer offset;
  end BT_ANCHOR;

  record BT_ITER
  end BT_ITER;
end BlockType;

uniontype IterOptions
  record ITER_OPTIONS
  end ITER_OPTIONS;
end IterOptions;

end Tpl;

package Flags
  uniontype ConfigFlag end ConfigFlag;
  constant ConfigFlag MODELICA_OUTPUT;
  function getConfigBool
    input ConfigFlag inFlag;
    output Boolean outValue;
  end getConfigBool;
end Flags;

package MMToJuliaUtil
  uniontype Context
    record FUNCTION
      String retValsStr;
      String ty_str;
    end FUNCTION;
    record FUNCTION_RETURN_CONTEXT
      String retValsStr "Contains return values";
      String ty_str "String of the type we are currently operating on";
    end FUNCTION_RETURN_CONTEXT;
    record PACKAGE
    end PACKAGE;
    record UNIONTYPE
      String name;
    end UNIONTYPE;
    record INPUT_CONTEXT
      String ty_str;
    end INPUT_CONTEXT;
    record NO_CONTEXT
    end NO_CONTEXT;
    record MATCH_CONTEXT
      Absyn.Exp inputExp;
    end MATCH_CONTEXT;
  end Context;
  constant Context packageContext;
  constant Context functionContext;
  constant Context noContext;
  constant Context inputContext;
  function makeUniontypeContext
    input String name;
    output Context context;
  end makeUniontypeContext;
  function makeFunctionContext
    input String returnValuesStr;
    output Context context;
  end makeFunctionContext;
  function makeFunctionReturnContext
    input String returnValuesStr;
    input String ty_str;
    output Context context;
  end makeFunctionReturnContext;
  function makeInputContext
    input String ty_str;
    output Context context;
  end makeInputContext;
  function makeMatchContext
    input Absyn.Exp iExp;
    output Context context;
  end makeMatchContext;
  function filterOnDirection
    input list<Absyn.ElementItem> inputs;
    input Absyn.Direction direction;
    output list<Absyn.ElementItem> outputs;
  end filterOnDirection;
  function makeInputDirection
    output Absyn.Direction direction;
  end makeInputDirection;
  function makeOutputDirection
    output Absyn.Direction direction;
  end makeOutputDirection;
  function isFunctionContext
    input Context givenCTX;
    output Boolean isFuncCTX;
  end isFunctionContext;
  function explicitReturnInClassPart
    input list<Absyn.ClassPart> classParts;
    output Boolean existsImplicitReturn;
  end explicitReturnInClassPart;
  function algorithmItemsContainsReturn
    input list<Absyn.AlgorithmItem> contents;
    output Boolean existsReturn;
  end algorithmItemsContainsReturn;
  function elementSpecIsBIDIR
    input Absyn.ElementSpec spec;
    output Boolean isBidr;
  end elementSpecIsBIDIR;
  function elementSpecIsOUTPUT
    input Absyn.ElementSpec spec;
    output Boolean isOutput;
  end elementSpecIsOUTPUT;
  function elementSpecIsOUTPUT_OR_BIDIR
    input Absyn.ElementSpec spec;
    output Boolean isOutput;
  end elementSpecIsOUTPUT_OR_BIDIR;
end MMToJuliaUtil;

package AbsynUtil
function getTypeSpecFromElementItemOpt
  input Absyn.ElementItem inElementItem;
  output Option<Absyn.TypeSpec> outTypeSpec;
end getTypeSpecFromElementItemOpt;
function getComponentItemsFromElementItem
  input Absyn.ElementItem inElementItem;
  output list<Absyn.ComponentItem> componentItems;
end getComponentItemsFromElementItem;
function isClassdef
  input Absyn.Element inElement;
  output Boolean b;
end isClassdef;
  function getElementItemsInClassPart
    input Absyn.ClassPart inClassPart;
    output list<Absyn.ElementItem> outElements;
  end getElementItemsInClassPart;
  function complexIsCref
    input Absyn.Exp inExp;
    output Boolean b;
  end complexIsCref;
end AbsynUtil;

package Util

function escapeModelicaStringToJLString
  input String modelicaString;
  output String cString;
end escapeModelicaStringToJLString;

end Util;

package AbsynToSCode
  function translateAbsyn2SCode
    input Absyn.Program inProgram;
    output SCode.Program outProgram;
  end translateAbsyn2SCode;
  function translateClassdefElements
    input list<Absyn.ClassPart> inAbsynClassPartLst;
    output list<SCode.Element> outElementLst;
  end translateClassdefElements;
end AbsynToSCode;

package SCode
  type Program = list<SCode.Element>;
  type Ident = String;
uniontype Element
  record IMPORT
  end IMPORT;
  record EXTENDS
  end EXTENDS;
  record CLASS
    Ident   name;
    Restriction restriction;
    Partial partialPrefix;
    ClassDef classDef;
  end CLASS;
  record COMPONENT
  end COMPONENT;
  record DEFINEUNIT
  end DEFINEUNIT;
end Element;

uniontype ClassDef
  record PARTS
    list<Element> elementLst;
  end PARTS;
  record CLASS_EXTENDS
  end CLASS_EXTENDS;
  record DERIVED
  end DERIVED;
  record ENUMERATION
  end ENUMERATION;
  record OVERLOAD
  end OVERLOAD;
  record PDER
  end PDER;
end ClassDef;
uniontype Restriction
  record R_CLASS end R_CLASS;
  record R_OPTIMIZATION end R_OPTIMIZATION;
  record R_MODEL end R_MODEL;
  record R_RECORD
  end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR
  end R_CONNECTOR;
  record R_OPERATOR end R_OPERATOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION
  end R_FUNCTION;
  record R_ENUMERATION end R_ENUMERATION;
  record R_PREDEFINED_INTEGER     "predefined IntegerType" end R_PREDEFINED_INTEGER;
  record R_PREDEFINED_REAL        "predefined RealType"    end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING      "predefined StringType"  end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOLEAN     "predefined BooleanType" end R_PREDEFINED_BOOLEAN;
  record R_PREDEFINED_ENUMERATION "predefined EnumType"    end R_PREDEFINED_ENUMERATION;
  record R_PREDEFINED_CLOCK       "predefined ClockType"   end R_PREDEFINED_CLOCK;
  record R_METARECORD "Metamodelica extension"
  end R_METARECORD;
  record R_UNIONTYPE
  end R_UNIONTYPE;
end Restriction;

uniontype Partial "the partial prefix"
  record PARTIAL     "a partial prefix"     end PARTIAL;
  record NOT_PARTIAL "a non partial prefix" end NOT_PARTIAL;
end Partial;

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


package DAE

    type Ident = String;

    type InstDims = list<Dimension>;
    type Dimensions = list<Dimension>;

  uniontype DAElist
    record DAE
      list<Element> elementLst;
    end DAE;
  end DAElist;

  /* AVLTree for functions */
  type AvlKey = Absyn.Path;

  type AvlValue = Option<Function>;

  type FunctionTree = AvlTree;

  uniontype AvlTree "The binary tree data structure"
    record AVLTREENODE
      Option<AvlTreeValue> value "Value" ;
      Integer height "heigth of tree, used for balancing";
      Option<AvlTree> left "left subtree" ;
      Option<AvlTree> right "right subtree" ;
    end AVLTREENODE;

  end AvlTree;

  uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
    record AVLTREEVALUE
      AvlKey key "Key" ;
      AvlValue value "Value" ;
    end AVLTREEVALUE;

  end AvlTreeValue;

  uniontype ElementSource "gives information about the origin of the element"
    record SOURCE
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Within> partOfLst "the model(s) this element came from";
      list<Option<ComponentRef>> instanceOptLst "the instance(s) this element is part of";
      list<Option<tuple<ComponentRef, ComponentRef>>> connectEquationOptLst "this element came from this connect(s)";
      list<Absyn.Path> typeLst "the classes where the type(s) of the element is defined";
      list<SymbolicOperation> operations "the symbolic operations used to end up with the final state of the element";
      list<SCode.Comment> comment;
    end SOURCE;
  end ElementSource;

  uniontype Element
    record VAR
      ComponentRef componentRef " The variable name";
      VarKind kind "varible kind: variable, constant, parameter, discrete etc." ;
      VarDirection direction "input, output or bidir" ;
      VarParallelism parallelism "parglobal, parlocal, or non_parallel";
      VarVisibility protection "if protected or public";
      Type ty "Full type information required";
      Option<Exp> binding "Binding expression e.g. for parameters ; value of start attribute";
      InstDims  dims "dimensions";
      Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
      Stream streamPrefix "Stream variables in connectors" ;
      ElementSource source "the origins of the component/equation/algorithm";
      Option<VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> comment;
      Absyn.InnerOuter innerOuter "inner/outer required to 'change' outer references";
    end VAR;

    record DEFINE "A solved equation"
      ComponentRef componentRef;
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end DEFINE;

    record INITIALDEFINE " A solved initial equation"
      ComponentRef componentRef;
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIALDEFINE;

    record EQUATION "Scalar equation"
      Exp exp;
      Exp scalar;
      ElementSource source "the origin of the component/equation/algorithm";
    end EQUATION;

    record EQUEQUATION "effort variable equality"
      ComponentRef cr1;
      ComponentRef cr2;
      ElementSource source "the origin of the component/equation/algorithm";
    end EQUEQUATION;

    record ARRAY_EQUATION " an array equation"
      Dimensions dimension "dimension sizes" ;
      Exp exp;
      Exp array;
      ElementSource source "the origin of the component/equation/algorithm";
    end ARRAY_EQUATION;

    record INITIAL_ARRAY_EQUATION "An initial array equation"
      Dimensions dimension "dimension sizes";
      Exp exp;
      Exp array;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_ARRAY_EQUATION;

    record CONNECT_EQUATION "a connect equation"
      Element lhsElement;
      Connect.Face lhsFace;
      Element rhsElement;
      Connect.Face rhsFace;
      ElementSource source "the origin of the component/equation/algorithm";
    end CONNECT_EQUATION;

    record COMPLEX_EQUATION "an equation of complex type, e.g. record = func(..)"
      Exp lhs;
      Exp rhs;
      ElementSource source "the origin of the component/equation/algorithm";
    end COMPLEX_EQUATION;

    record INITIAL_COMPLEX_EQUATION "an initial equation of complex type, e.g. record = func(..)"
      Exp lhs;
      Exp rhs;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_COMPLEX_EQUATION;

    record WHEN_EQUATION " a when equation"
      Exp condition "Condition" ;
      list<Element> equations "Equations" ;
      Option<Element> elsewhen_ "Elsewhen should be of type WHEN_EQUATION" ;
      ElementSource source "the origin of the component/equation/algorithm";
    end WHEN_EQUATION;

    record FOR_EQUATION " a for-equation"
      Type type_ "this is the type of the iterator";
      Boolean iterIsArray "True if the iterator has an array type, otherwise false.";
      Ident iter "the iterator variable";
      Integer index "the index of the iterator variable, to make it unique; used by the new inst";
      Exp range "range for the loop";
      list<Element> equations "Equations" ;
      ElementSource source "the origin of the component/equation/algorithm" ;
    end FOR_EQUATION;

    record IF_EQUATION " an if-equation"
      list<Exp> condition1 "Condition" ;
      list<list<Element>> equations2 "Equations of true branch" ;
      list<Element> equations3 "Equations of false branch" ;
      ElementSource source "the origin of the component/equation/algorithm";
    end IF_EQUATION;

    record INITIAL_IF_EQUATION "An initial if-equation"
      list<Exp> condition1 "Condition" ;
      list<list<Element>> equations2 "Equations of true branch" ;
      list<Element> equations3 "Equations of false branch" ;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_IF_EQUATION;

    record INITIALEQUATION " An initial equaton"
      Exp exp1;
      Exp exp2;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIALEQUATION;

    record ALGORITHM " An algorithm section"
      Algorithm algorithm_;
      ElementSource source "the origin of the component/equation/algorithm";
    end ALGORITHM;

    record INITIALALGORITHM " An initial algorithm section"
      Algorithm algorithm_;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIALALGORITHM;

    record COMP
      Ident ident;
      list<Element> dAElist "a component with subelements, normally only used at top level.";
      ElementSource source "the origin of the component/equation/algorithm"; // we might not this here.
      Option<SCode.Comment> comment;
    end COMP;

    record EXTOBJECTCLASS "The 'class' of an external object"
      Absyn.Path path "className of external object";
      ElementSource source "the origin of the component/equation/algorithm";
    end EXTOBJECTCLASS;

    record ASSERT " The Modelica builtin assert"
      Exp condition;
      Exp message;
      Exp level;
      ElementSource source "the origin of the component/equation/algorithm";
    end ASSERT;

    record INITIAL_ASSERT " The Modelica builtin assert"
      Exp condition;
      Exp message;
      Exp level;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_ASSERT;

    record TERMINATE " The Modelica builtin terminate(msg)"
      Exp message;
      ElementSource source "the origin of the component/equation/algorithm";
    end TERMINATE;

    record INITIAL_TERMINATE " The Modelica builtin terminate(msg)"
      Exp message;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_TERMINATE;

    record REINIT " reinit operator for reinitialization of states"
      ComponentRef componentRef;
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end REINIT;

    record NORETCALL "call with no return value, i.e. no equation.
      Typically sideeffect call of external function but also
      Connections.* i.e. Connections.root(...) functions."
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end NORETCALL;

    record INITIAL_NORETCALL "call with no return value, i.e. no equation.
      Typically sideeffect call of external function but also
      Connections.* i.e. Connections.root(...) functions."
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm" ;
    end INITIAL_NORETCALL;

    record CONSTRAINT " constraint section"
      Constraint constraints;
      ElementSource source "the origin of the component/equation/algorithm";
    end CONSTRAINT;

    record COMMENT
      SCode.Comment cmt;
    end COMMENT;

  end Element;

  uniontype Algorithm "The `Algorithm\' type corresponds to a whole algorithm section.
    It is simple a list of algorithm statements."
    record ALGORITHM_STMTS
      list<Statement> statementLst;
    end ALGORITHM_STMTS;

  end Algorithm;

  uniontype Statement
    record STMT_ASSIGN
      Exp exp1;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN;

    record STMT_TUPLE_ASSIGN
      list<Exp> expExpLst;
      Exp exp;
      ElementSource source;
    end STMT_TUPLE_ASSIGN;

    record STMT_ASSIGN_ARR
      Exp lhs;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN_ARR;

    record STMT_IF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
      ElementSource source;
    end STMT_IF;

    record STMT_FOR
      Boolean iterIsArray;
      Ident iter;
      Exp range;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_FOR;

    record STMT_WHILE
      Exp exp;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_WHILE;

    record STMT_WHEN
      Exp exp;
      list<Statement> statementLst;
      Option<Statement> elseWhen;
      list<Integer> helpVarIndices;
      ElementSource source;
    end STMT_WHEN;

    record STMT_ASSERT
      Exp cond;
      Exp msg;
      Exp level;
      ElementSource source;
    end STMT_ASSERT;

    record STMT_TERMINATE
      Exp msg;
      ElementSource source;
    end STMT_TERMINATE;

    record STMT_REINIT
      Exp var;
      Exp value;
      ElementSource source;
    end STMT_REINIT;

    record STMT_NORETCALL
      Exp exp;
      ElementSource source;
    end STMT_NORETCALL;

    record STMT_RETURN
      ElementSource source;
    end STMT_RETURN;

    record STMT_CONTINUE
      ElementSource source;
    end STMT_CONTINUE;

    record STMT_BREAK
      ElementSource source;
    end STMT_BREAK;

    record STMT_FAILURE
      list<Statement> body;
      ElementSource source;
    end STMT_FAILURE;
  end Statement;

  uniontype Else "An if statements can one or more `elseif\' branches and an
        optional `else\' branch."
    record NOELSE end NOELSE;

    record ELSEIF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
    end ELSEIF;

    record ELSE
      list<Statement> statementLst;
    end ELSE;

  end Else;

  uniontype Operator "Operators which are overloaded in the abstract syntax are here
    made type-specific.  The integer addition operator (`ADD(INT)\')
    and the real addition operator (`ADD(REAL)\') are two distinct
    operators."
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

    record MUL_ARRAY_SCALAR " {a,b,c} * s"
      Type ty "type of the array" ;
    end MUL_ARRAY_SCALAR;

    record ADD_ARRAY_SCALAR " {a,b,c} .+ s"
      Type ty "type of the array";
    end ADD_ARRAY_SCALAR;

    record SUB_SCALAR_ARRAY "s .- {a,b,c}"
      Type ty "type of the array" ;
    end SUB_SCALAR_ARRAY;

    record MUL_SCALAR_PRODUCT " {a,b,c} * {c,d,e} => a*c+b*d+c*e"
      Type ty "type of the array" ;
    end MUL_SCALAR_PRODUCT;

    record MUL_MATRIX_PRODUCT "M1 * M2, matrix dot product"
      Type ty "{{..},..}  {{..},{..}}" ;
    end MUL_MATRIX_PRODUCT;

    record DIV_ARRAY_SCALAR "{a, b} / c"
      Type ty  "type of the array";
    end DIV_ARRAY_SCALAR;

    record DIV_SCALAR_ARRAY "c / {a,b}"
      Type ty "type of the array" ;
    end DIV_SCALAR_ARRAY;

    record POW_ARRAY_SCALAR
      Type ty "type of the array" ;
    end POW_ARRAY_SCALAR;

    record POW_SCALAR_ARRAY
      Type ty "type of the array" ;
    end POW_SCALAR_ARRAY;

    record POW_ARR "Power of a matrix: {{1,2,3},{4,5.0,6},{7,8,9}}^2"
      Type ty "type of the array";
    end POW_ARR;

    record POW_ARR2 "elementwise power of arrays: {1,2,3}.^{3,2,1}"
      Type ty "type of the array";
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
      Absyn.Path fqName "The FQ name of the overloaded operator function" ;
    end USERDEFINED;

  end Operator;

  uniontype ExternalDecl
    record EXTERNALDECL
      String name;
      list<ExtArg> args;
      ExtArg returnArg;
      String language;
      Option<SCode.Annotation> ann;
    end EXTERNALDECL;
  end ExternalDecl;

  uniontype ExtArg
    record EXTARG
      ComponentRef componentRef;
      Attributes attributes;
      Type type_;
    end EXTARG;

    record EXTARGEXP
      Exp exp;
      Type type_;
    end EXTARGEXP;

    record EXTARGSIZE
      ComponentRef componentRef;
      Attributes attributes;
      Type type_;
      Exp exp;
    end EXTARGSIZE;

    record NOEXTARG end NOEXTARG;
  end ExtArg;

  uniontype Var "- Variables"
    record TYPES_VAR
      Ident name "name";
      Attributes attributes "attributes";
      Type ty "type" ;
      Binding binding "equation modification";
      Option<Const> constOfForIteratorRange "the constant-ness of the range if this is a for iterator, NONE() if is NOT a for iterator";
    end TYPES_VAR;
  end Var;

  uniontype Attributes "- Attributes"
    record ATTR
      ConnectorType       connectorType "flow, stream or unspecified";
      SCode.Parallelism   parallelism "parallelism";
      SCode.Variability   variability "variability" ;
      Absyn.Direction     direction "direction" ;
      Absyn.InnerOuter    innerOuter "inner, outer,  inner outer or unspecified";
      SCode.Visibility    visibility "public, protected";
    end ATTR;
  end Attributes;

  uniontype ComponentRef "- Component references
      CREF_QUAL(...) is used for qualified component names, e.g. a.b.c
      CREF_IDENT(..) is used for non-qualifed component names, e.g. x"

    record CREF_QUAL
      Ident ident;
      Type identType "type of the identifier, without considering the subscripts";
      list<Subscript> subscriptLst;
      ComponentRef componentRef;
    end CREF_QUAL;

    record CREF_IDENT
      Ident ident;
      Type identType "type of the identifier, without considering the subscripts";
      list<Subscript> subscriptLst;
    end CREF_IDENT;

    record WILD end WILD;

  end ComponentRef;

  uniontype Subscript "The `Subscript\' and `ComponentRef\' datatypes are simple
    translations of the corresponding types in the `Absyn\' module."
    record WHOLEDIM "a{:,1}" end WHOLEDIM;

    record SLICE
      Exp exp "a{1:3,1}, a{1:2:10,2}" ;
    end SLICE;

    record INDEX
      Exp exp "a[i+1]" ;
    end INDEX;

    record WHOLE_NONEXP "Used for non-expanded arrays. Should probably be combined with WHOLEDIM
      into one case with Option<Exp> argument."
      Exp exp;
    end WHOLE_NONEXP;

  end Subscript;

  uniontype VarKind
    record VARIABLE "variable" end VARIABLE;
    record DISCRETE "discrete" end DISCRETE;
    record PARAM "parameter"   end PARAM;
    record CONST "constant"    end CONST;
  end VarKind;

  uniontype ConnectorType "The type of a connector element."
    record POTENTIAL end POTENTIAL;
    record FLOW end FLOW;
    record STREAM
      Option<ComponentRef> associatedFlow;
    end STREAM;
    record NON_CONNECTOR end NON_CONNECTOR;
  end ConnectorType;

  uniontype VarDirection
    record INPUT  "input"                   end INPUT;
    record OUTPUT "output"                  end OUTPUT;
    record BIDIR  "neither input or output" end BIDIR;
  end VarDirection;

  uniontype VarParallelism
    record PARGLOBAL     "Global variables for CUDA and OpenCL"     end PARGLOBAL;
    record PARLOCAL      "Shared for CUDA and local for OpenCL"     end PARLOCAL;
    record NON_PARALLEL  "Non parallel/Normal variables"            end NON_PARALLEL;
  end VarParallelism;

  uniontype StateSelect
    record NEVER end NEVER;
    record AVOID end AVOID;
    record DEFAULT end DEFAULT;
    record PREFER end PREFER;
    record ALWAYS end ALWAYS;
  end StateSelect;

  uniontype Uncertainty
    record GIVEN end GIVEN;
    record SOUGHT end SOUGHT;
    record REFINE end REFINE;
    record PROPAGATE end PROPAGATE;
  end Uncertainty;

  uniontype Distribution
    record DISTRIBUTION
      Exp name;
      Exp params;
      Exp paramNames;
    end DISTRIBUTION;
  end Distribution;

  uniontype VariableAttributes
    record VAR_ATTR_REAL
      Option<Exp> quantity "quantity";
      Option<Exp> unit "unit";
      Option<Exp> displayUnit "displayUnit";
      Option<Exp> min;
      Option<Exp> max;
      Option<Exp> start "start value";
      Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Exp> nominal "nominal";
      Option<StateSelect> stateSelectOption;
      Option<Uncertainty> uncertainOption;
      Option<Distribution> distributionOption;
      Option<Exp> equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;
      Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
    end VAR_ATTR_REAL;

    record VAR_ATTR_INT
      Option<Exp> quantity "quantity";
      Option<Exp> min;
      Option<Exp> max;
      Option<Exp> start "start value";
      Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Uncertainty> uncertainOption;
      Option<Distribution> distributionOption;
      Option<Exp> equationBound;
      Option<Boolean> isProtected; // ,eb,ip
      Option<Boolean> finalPrefix;
      Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
    end VAR_ATTR_INT;

    record VAR_ATTR_BOOL
      Option<Exp> quantity "quantity";
      Option<Exp> start "start value";
      Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Exp> equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;
      Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
    end VAR_ATTR_BOOL;

    record VAR_ATTR_STRING
      Option<Exp> quantity "quantity";
      Option<Exp> start "start value";
      Option<Exp> equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;
      Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
    end VAR_ATTR_STRING;

    record VAR_ATTR_ENUMERATION
      Option<Exp> quantity "quantity";
      Option<Exp> min;
      Option<Exp> max;
      Option<Exp> start "start";
      Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
      Option<Exp> equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;
      Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
    end VAR_ATTR_ENUMERATION;

  end VariableAttributes;

  uniontype VarVisibility
    record PUBLIC "public variables"       end PUBLIC;
    record PROTECTED "protected variables" end PROTECTED;
  end VarVisibility;

  uniontype Function
    record FUNCTION " A Modelica function"
      Absyn.Path path;
      list<FunctionDefinition> functions "contains the body and an optional function derivative mapping";
      Type type_;
      Boolean partialPrefix "MetaModelica extension";
      Boolean isImpure;
      InlineType inlineType;
      ElementSource source "the origin of the component/equation/algorithm";
      Option<SCode.Comment> comment;
    end FUNCTION;

    record RECORD_CONSTRUCTOR "A Modelica record constructor. The function can be generated from the Path and Type alone."
      Absyn.Path path;
      Type type_;
      ElementSource source "the origin of the component/equation/algorithm";
    end RECORD_CONSTRUCTOR;
  end Function;

  uniontype FunctionDefinition

     record FUNCTION_DEF "Normal function body"
       list<Element> body;
     end FUNCTION_DEF;

     record FUNCTION_EXT "Normal external function declaration"
      list<Element> body;
      ExternalDecl externalDecl;
     end FUNCTION_EXT;

    record FUNCTION_DER_MAPPER "Contains derivatives for function"
      Absyn.Path derivedFunction "Function that is derived";
      Absyn.Path derivativeFunction "Path to derivative function";
      Integer derivativeOrder "in case a function have multiple derivatives, include all";
      list<tuple<Integer,derivativeCond>> conditionRefs;
      Option<Absyn.Path> defaultDerivative "if conditions fails, use default derivative if exists";
      list<Absyn.Path> lowerOrderDerivatives;
    end FUNCTION_DER_MAPPER;

    record FUNCTION_INVERSE "A function inverse declaration"
      ComponentRef inputParam "The input parameter the inverse is for";
      Exp inverseCall "The inverse function call";
    end FUNCTION_INVERSE;
  end FunctionDefinition;

  uniontype derivativeCond "Different conditions on derivatives"
    record ZERO_DERIVATIVE end ZERO_DERIVATIVE;
    record NO_DERIVATIVE
      Exp binding;
    end NO_DERIVATIVE;
  end derivativeCond;

  type TypeSource = list<Absyn.Path>;

  uniontype Type "models the different front-end and back-end types"

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

    record T_CLOCK
      list<Var> varLst;
    end T_CLOCK;

    record T_ENUMERATION "If the list of names is empty, this is the super-enumeration that is the super-class of all enumerations"
      Option<Integer> index "the enumeration value index, SOME for element, NONE() for type" ;
      Absyn.Path path "enumeration path" ;
      list<String> names "names" ;
      list<Var> literalVarLst;
      list<Var> attributeLst;
    end T_ENUMERATION;

    record T_ARRAY
      "an array can be represented in two equivalent ways:
         1. T_ARRAY(non_array_type, {dim1, dim2, dim3}) =
         2. T_ARRAY(T_ARRAY(T_ARRAY(non_array_type, {dim1}), {dim2}), {dim3})
         In general Inst generates 1 and all the others generates 2"
      Type ty "Type";
      Dimensions dims "dims";
    end T_ARRAY;

    record T_NORETCALL "For functions not returning any values."
    end T_NORETCALL;

    record T_UNKNOWN "Used when type is not yet determined"
    end T_UNKNOWN;

    record T_COMPLEX
      ClassInf.State complexClassType "The type of a class" ;
      list<Var> varLst "The variables of a complex type" ;
      EqualityConstraint equalityConstraint;
    end T_COMPLEX;

    record T_SUBTYPE_BASIC
      ClassInf.State complexClassType "The type of a class" ;
      list<Var> varLst "complexVarLst; The variables of a complex type! Should be empty, kept here to verify!";
      Type complexType "complexType; A complex type can be a subtype of another (primitive) type (through extends)";
      EqualityConstraint equalityConstraint;
    end T_SUBTYPE_BASIC;

    record T_FUNCTION
      list<FuncArg> funcArg;
      Type funcResultType "Only single-result" ;
      FunctionAttributes functionAttributes;
      Absyn.Path path;
    end T_FUNCTION;

    record T_FUNCTION_REFERENCE_VAR "MetaModelica Function Reference that is a variable"
      Type functionType "the type of the function";
    end T_FUNCTION_REFERENCE_VAR;

    record T_FUNCTION_REFERENCE_FUNC "MetaModelica Function Reference that is a direct reference to a function"
      Boolean builtin;
      Type functionType "type of the non-boxptr function";
      TypeSource source;
    end T_FUNCTION_REFERENCE_FUNC;

    record T_TUPLE
      list<Type> types "For functions returning multiple values.";
    end T_TUPLE;

    record T_CODE
      CodeType ty;
      TypeSource source;
    end T_CODE;

    record T_ANYTYPE
      Option<ClassInf.State> anyClassType "anyClassType - used for generic types. When class state present the type is assumed to be a complex type which has that restriction.";
    end T_ANYTYPE;

    // MetaModelica extensions
    record T_METALIST "MetaModelica list type"
      Type ty "listType";
    end T_METALIST;

    record T_METATUPLE "MetaModelica tuple type"
      list<Type> types;
    end T_METATUPLE;

    record T_METAOPTION "MetaModelica option type"
      Type ty;
    end T_METAOPTION;

    record T_METAUNIONTYPE "MetaModelica Uniontype"
      list<Absyn.Path> paths;
      Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
      Absyn.Path path;
    end T_METAUNIONTYPE;

    record T_METARECORD "MetaModelica Record, used by Uniontypes. added by simbj"
      Absyn.Path path;
      Absyn.Path utPath "the path to its uniontype; this is what we match the type against";
      // If the metarecord constructor was added to the FunctionTree, this would
      // not be needed. They are used to create the datatype in the runtime...
      Integer index; //The index in the uniontype
      list<Var> fields;
      Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
    end T_METARECORD;

    record T_METAARRAY
      Type ty;
    end T_METAARRAY;

    record T_METABOXED "Used for MetaModelica generic types"
      Type ty;
    end T_METABOXED;

    record T_METAPOLYMORPHIC
      String name;
    end T_METAPOLYMORPHIC;

    record T_METATYPE "this type contains all the meta types"
      Type ty;
    end T_METATYPE;

  end Type;

  uniontype InlineType
    record NORM_INLINE "Normal inline, inline as soon as possible"
    end NORM_INLINE;

    record EARLY_INLINE "Inline even earlier than NORM_INLINE. This will display the inlined code in the flattened model and also works for functions calling other functions that should be inlined."
    end EARLY_INLINE;

    record NO_INLINE "Avoid inline, this is default behaviour but is also possible to set with Inline=false"
    end NO_INLINE;

    record AFTER_INDEX_RED_INLINE "Try to inline after index reduction"
    end AFTER_INDEX_RED_INLINE;
  end InlineType;

  uniontype Binding "- Binding"
    record UNBOUND end UNBOUND;

    record EQBOUND
      Exp exp "exp";
      Option<Values.Value> evaluatedExp "evaluatedExp; evaluated exp";
      Const constant_ "constant";
      BindingSource source "Used for error reporting: this boolean tells us that the parameter did not had a binding but had a start value that was used instead.";
    end EQBOUND;

    record VALBOUND
      Values.Value valBound "valBound";
      BindingSource source "Used for error reporting: this boolean tells us that the parameter did not had a binding but had a start value that was used instead";
    end VALBOUND;

  end Binding;

  uniontype Flow "The Flow of a variable indicates if it is a Flow variable or not, or if
     it is not a connector variable at all."
    record FLOW end FLOW;
    record NON_FLOW end NON_FLOW;
    record NON_CONNECTOR end NON_CONNECTOR;
  end Flow;


  uniontype Dimension
    record DIM_INTEGER "Dimension given by an integer."
      Integer integer;
    end DIM_INTEGER;

    record DIM_ENUM "Dimension given by an enumeration."
      Absyn.Path enumTypeName "The enumeration type name.";
      list<String> literals "A list of the literals in the enumeration.";
      Integer size "The size of the enumeration.";
    end DIM_ENUM;

    record DIM_EXP "Dimension given by an expression."
      Exp exp;
    end DIM_EXP;

    record DIM_UNKNOWN "Dimension with unknown size."
      //DimensionBinding dimensionBinding "unknown dimension can be bound or unbound";
    end DIM_UNKNOWN;
  end Dimension;

  uniontype FuncArg
    record FUNCARG
      String name;
      Type ty;
      Const const;
      VarParallelism par;
      Option<Exp> defaultBinding;
    end FUNCARG;
  end FuncArg;

  uniontype Const
    record C_CONST end C_CONST;
    record C_PARAM end C_PARAM;
    record C_VAR end C_VAR;
    record C_UNKNOWN end C_UNKNOWN;
  end Const;

  uniontype Exp "Expressions
      The `Exp\' datatype closely corresponds to the `Absyn.Exp\'
      datatype, but is used for statically analyzed expressions.  It
      includes explicit type promotions and typed (non-overloaded)
      operators. It also contains expression indexing with the `ASUB\'
      constructor.  Indexing arbitrary array expressions is currently
      not supported in Modelica, but it is needed here.

      When making additions, update at least the following functions:
      * Expression.traverseExp
      * Expression.traverseExpTopDown
      * Expression.traverseExpBiDir
      * ExpressionDump.printExpStr
      "
    record ICONST
      Integer integer "Integer constants" ;
    end ICONST;

    record RCONST
      Real real "Real constants" ;
    end RCONST;

    record SCONST
      String string "String constants" ;
    end SCONST;

    record BCONST
      Boolean bool "Bool constants" ;
    end BCONST;

    record ENUM_LITERAL "Enumeration literal"
      Absyn.Path name;
      Integer index;
    end ENUM_LITERAL;

    record CREF "component references, e.g. a.b{2}.c{1}"
      ComponentRef componentRef;
      Type ty;
    end CREF;

    record BINARY "Binary operations, e.g. a+4"
      Exp exp1;
      Operator operator;
      Exp exp2;
    end BINARY;

    record UNARY "Unary operations, -(4x)"
      Operator operator;
      Exp exp;
    end UNARY;

    record LBINARY "Logical binary operations: and, or"
      Exp exp1;
      Operator operator;
      Exp exp2;
    end LBINARY;

    record LUNARY "Logical unary operations: not"
      Operator operator;
      Exp exp;
    end LUNARY;

    record RELATION "Relation, e.g. a <= 0
      Index contains normal an Integer for every ZeroCrossing
      but if Relation is in algorithm with for loop the iterator and the range
      of static iterator is needed for codegen"
      Exp exp1;
      Operator operator;
      Exp exp2;
      Integer index;
      Option<tuple<Exp,Integer,Integer>> optionExpisASUB;
    end RELATION;

    record IFEXP "If expressions"
      Exp expCond;
      Exp expThen;
      Exp expElse;
    end IFEXP;

    record CALL
      Absyn.Path path;
      list<Exp> expLst;
      CallAttributes attr;
    end CALL;

    record PARTEVALFUNCTION
      Absyn.Path path;
      list<Exp> expList;
      Type ty;
    end PARTEVALFUNCTION;

    record ARRAY
      Type ty;
      Boolean scalar "scalar for codegen" ;
      list<Exp> array "Array constructor, e.g. {1,3,4}" ;
    end ARRAY;

    record MATRIX
      Type ty;
      Integer integer;
      list<list<Exp>> matrix;
    end MATRIX;

    record RANGE
      Type ty;
      Exp start "start value";
      Option<Exp> step "step value";
      Exp stop "stop value" ;
    end RANGE;

    record TUPLE
      list<Exp> PR "PR. Tuples, used in func calls returning several
                    arguments" ;
    end TUPLE;

    record CAST "Cast operator"
      Type ty "This is the full type of this expression, i.e. ET_ARRAY(...) for arrays and matrices";
      Exp exp;
    end CAST;

    record ASUB "Array subscripts"
      Exp exp;
      list<Exp> sub;
    end ASUB;

    record TSUB "Tuple 'subscript' (accessing only single values in calls)"
      Exp exp;
      Integer ix;
      Type ty;
    end TSUB;

    record SIZE "The size operator"
      Exp exp;
      Option<Exp> sz;
    end SIZE;

    record CODE "Modelica AST constructor"
      Absyn.CodeNode code;
      Type ty;
    end CODE;

    record EMPTY
      "an empty expression, meaning a constant without a binding. is used to be able to continue the evaluation of a model even if there are
       constants with no bindings. at the end, when we have the DAE we should have no EMPTY values or expressions in it when we need to simulate
       the model.
       From Modelica specification: a package may we look inside should not be partial in a simulation model!"
      String scope "the scope where we could not find the binding";
      ComponentRef name "the name of the variable";
      Type ty "the type of the variable";
      String tyStr;
    end EMPTY;

    record REDUCTION "e.g. sum(i*i+1 for i in 1:4)"
      ReductionInfo reductionInfo;
      Exp expr "expr, e.g i*i+1" ;
      ReductionIterators iterators;
    end REDUCTION;

    /* Part of MetaModelica extension. KS */
    record LIST "MetaModelica list"
      list<Exp> valList;
    end LIST;

    record CONS "MetaModelica list cons"
      Exp car;
      Exp cdr;
    end CONS;

    record META_TUPLE
      list<Exp> listExp;
    end META_TUPLE;

    record META_OPTION
      Option<Exp> exp;
    end META_OPTION;

    /*
      Holds a metarecord call
       <metarecord>(<args>)
    */
    record METARECORDCALL //Metamodelica extension, simbj
      Absyn.Path path;
      list<Exp> args;
      list<String> fieldNames;
      Integer index; //Index in the uniontype
    end METARECORDCALL;

    record MATCHEXPRESSION
      MatchType matchType;
      list<Exp> inputs;
      list<Element> localDecls;
      list<MatchCase> cases;
      Type et;
    end MATCHEXPRESSION;

    record BOX "MetaModelica boxed value"
      Exp exp;
    end BOX;

    record UNBOX "MetaModelica value unboxing (similar to a cast)"
      Exp exp;
      Type ty;
    end UNBOX;

    record SHARED_LITERAL
      "Before code generation, we make a pass that replaces constant literals
      with a SHARED_LITERAL expression. Any immutable type can be shared:
      basic MetaModelica types and Modelica strings are fine. There is no point
      to share Real, Integer, Boolean or Enum though."
      Integer index;
      Type ty "The type is required for code generation to work properly";
    end SHARED_LITERAL;

    record PATTERN "(x,1,ROOT(a as _,false,_)) := rhs; MetaModelica extension"
      Pattern pattern;
    end PATTERN;

  record SUM //i.e. accumulated sum over a range of array vars
    Type ty;
    Exp iterator;
    Exp startIt;
    Exp endIt;
    Exp body;
  end SUM;

  end Exp;

  uniontype CallAttributes
    record CALL_ATTR
      TailCall tailCall "Input variables of the function if the call is tail-recursive";
    end CALL_ATTR;
  end CallAttributes;

  uniontype TailCall
    record NO_TAIL
    end NO_TAIL;
    record TAIL
    end TAIL;
  end TailCall;
end DAE;


package Expression

function typeof
  input DAE.Exp inExp;
  output DAE.Type outType;
end typeof;

function fromAbsynExp
  input Absyn.Exp inAExp;
  output DAE.Exp outDExp;
end fromAbsynExp;

end Expression;

end AbsynToJuliaTV;
