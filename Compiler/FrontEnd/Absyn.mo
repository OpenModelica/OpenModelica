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

encapsulated package Absyn
"
  file:        mo
  package:     Absyn
  description: Abstract syntax


  This file defines the abstract syntax for Modelica in MetaModelica Compiler (MMC).  It mainly
  contains uniontypes for constructing the abstract syntax tree
  (AST), functions for building and altering AST nodes and a few functions
  for printing the AST:

  * Abstract Syntax Tree (Close to Modelica)
     - Complete Modelica 2.2, 3.1, 3.2, MetaModelica
     - Including annotations and comments
  * Primary AST for e.g. the Interactive module
     - Model editor related representations (must use annotations)
  * Functions
     - A few small functions, only working on Absyn types, e.g.:
       - pathToCref(Path) => ComponentRef
       - joinPaths(Path, Path) => (Path)
       - etc.


  mo\'s constructors are primarily used by (Parser/Modelica.g).

  When the AST has been built, it is normally used by SCode.mo in order to
  build the SCode (See SCode.mo). It is also possile to send the AST do
  the unparser (Dump.mo) in order to print it.

  For details regarding the abstract syntax tree, check out the grammar in
  the Modelica language specification.


  The following are the types and uniontypes that are used for the AST:"

protected import Dump;
protected import System;

public
type Ident = String "An identifier, for example a variable name" ;

public uniontype ForIterator
  "For Iterator - these are used in:
   * for loops where the expression part can be NONE() and then the range
     is taken from an array variable that the iterator is used to index,
     see 3.3.3.2 Several Iterators from Modelica Specification.
   * in array iterators where the expression should always be SOME(Exp),
     see 3.4.4.2 Array constructor with iterators from Specification
   * the guard is a MetaModelica extension; it's a Boolean expression that
     filters out items in the range."
  record ITERATOR
    String name;
    Option<Exp> guardExp;
    Option<Exp> range;
  end ITERATOR;
end ForIterator;

public type ForIterators = list<ForIterator>
"For Iterators -
   these are used in:
   * for loops where the expression part can be NONE() and then the range
     is taken from an array variable that the iterator is used to index,
     see 3.3.3.2 Several Iterators from Modelica Specification.
   * in array iterators where the expression should always be SOME(Exp),
     see 3.4.4.2 Array constructor with iterators from Specification";

public
uniontype Program
"- Programs, the top level construct
   A program is simply a list of class definitions declared at top
   level in the source file, combined with a within statement that
   indicates the hieractical position of the program."
  record PROGRAM  "PROGRAM, the top level construct"
    list<Class>  classes "List of classes" ;
    Within       within_ "Within clause" ;
  end PROGRAM;
end Program;

public
uniontype Within "Within Clauses"
  record WITHIN "the within clause"
    Path path "the path for within";
  end WITHIN;

  record TOP end TOP;
end Within;

type Info = SourceInfo;

public
uniontype Class
 "A class definition consists of a name, a flag to indicate
  if this class is declared as partial, the declared class restriction,
  and the body of the declaration."
 record CLASS
    Ident name;
    Boolean     partialPrefix   "true if partial" ;
    Boolean     finalPrefix     "true if final" ;
    Boolean     encapsulatedPrefix "true if encapsulated" ;
    Restriction restriction  "Restriction" ;
    ClassDef    body;
    Info       info    "Information: FileName is the class is defined in +
               isReadOnly bool + start line no + start column no +
               end line no + end column no";
  end CLASS;

end Class;

public
uniontype ClassDef
"The ClassDef type contains thClasse definition part of a class declaration.
 The definition is either explicit, with a list of parts
 (public, protected, equation, and algorithm), or it is a definition
 derived from another class or an enumeration type.
 For a derived type, the  type contains the name of the derived class
 and an optional array dimension and a list of modifications.
 "
  record PARTS
    list<String> typeVars "class A<B,C> ... has type variables B,C";
    list<NamedArg> classAttrs "optimization Op (objective=...) end Op. A list arguments attributing a
    class declaration. Currently used only for Optimica extensions";
    list<ClassPart> classParts;
    list<Annotation> ann "Modelica2 allowed multiple class-annotations";
    Option<String>  comment;
  end PARTS;

  record DERIVED
    TypeSpec          typeSpec "typeSpec specification includes array dimensions" ;
    ElementAttributes attributes;
    list<ElementArg>  arguments;
    Option<Comment>   comment;
  end DERIVED;

  record ENUMERATION
    EnumDef         enumLiterals;
    Option<Comment> comment;
  end ENUMERATION;

  record OVERLOAD
    list<Path>      functionNames;
    Option<Comment> comment;
  end OVERLOAD;

  record CLASS_EXTENDS
    Ident              baseClassName  "name of class to extend" ;
    list<ElementArg>   modifications  "modifications to be applied to the base class";
    Option<String>     comment        "comment";
    list<ClassPart>    parts          "class parts";
    list<Annotation> ann;
  end CLASS_EXTENDS;

  record PDER
    Path         functionName;
    list<Ident>  vars "derived variables" ;
    Option<Comment> comment "comment";
  end PDER;
end ClassDef;

public
uniontype TypeSpec "ModExtension: new MetaModelica type specification!"
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

public
uniontype EnumDef
  "The definition of an enumeration is either a list of literals
     or a colon, \':\', which defines a supertype of all enumerations"
  record ENUMLITERALS
    list<EnumLiteral> enumLiterals;
  end ENUMLITERALS;

  record ENUM_COLON end ENUM_COLON;

end EnumDef;

public
uniontype EnumLiteral "EnumLiteral, which is a name in an enumeration and an optional
   Comment."
  record ENUMLITERAL
    Ident           literal;
    Option<Comment> comment;
  end ENUMLITERAL;

end EnumLiteral;

public
uniontype ClassPart "A class definition contains several parts.  There are public and
  protected component declarations, type definitions and `extends\'
  clauses, collectively called elements.  There are also equation
  sections and algorithm sections. The EXTERNAL part is used only by functions
  which can be declared as external C or FORTRAN functions."
  record PUBLIC
    list<ElementItem> contents ;
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
    ExternalDecl externalDecl "externalDecl" ;
    Option<Annotation> annotation_ "annotation" ;
  end EXTERNAL;

end ClassPart;

public
uniontype ElementItem "An element item is either an element or an annotation"
  record ELEMENTITEM
    Element  element;
  end ELEMENTITEM;

  record LEXER_COMMENT
    String comment;
  end LEXER_COMMENT;

end ElementItem;

public
uniontype Element "Elements
  The basic element type in Modelica"
  record ELEMENT
    Boolean                   finalPrefix;
    Option<RedeclareKeywords> redeclareKeywords "replaceable, redeclare" ;
    InnerOuter                innerOuter "inner/outer" ;
    ElementSpec               specification "Actual element specification" ;
    Info                      info  "File name the class is defined in + line no + column no" ;
    Option<ConstrainClass> constrainClass "only valid for classdef and component" ;
  end ELEMENT;

  record DEFINEUNIT
    Ident name;
    list<NamedArg> args;
  end DEFINEUNIT;

  record TEXT
    Option<Ident> optName "optName : optional name of text, e.g. model with syntax error.
                                       We need the name to be able to browse it..." ;
    String string;
    Info info;
  end TEXT;

end Element;

public
uniontype ConstrainClass "Constraining type, must be extends"
  record CONSTRAINCLASS
    ElementSpec elementSpec "must be extends" ;
    Option<Comment> comment "comment" ;
  end CONSTRAINCLASS;

end ConstrainClass;

public
uniontype ElementSpec "An element is something that occurs in a public or protected
    section in a class definition.  There is one constructor in the
    `ElementSpec\' type for each possible element type.  There are
    class definitions (`CLASSDEF\'), `extends\' clauses (`EXTENDS\')
    and component declarations (`COMPONENTS\').

    As an example, if the element `extends TwoPin;\' appears
    in the source, it is represented in the AST as
    `EXTENDS(IDENT(\"TwoPin\"),{})\'.
"
  record CLASSDEF
    Boolean replaceable_ "replaceable" ;
    Class class_ "class" ;
  end CLASSDEF;

  record EXTENDS
    Path path "path" ;
    list<ElementArg> elementArg "elementArg" ;
    Option<Annotation> annotationOpt "optional annotation";
  end EXTENDS;

  record IMPORT
    Import import_ "import" ;
    Option<Comment> comment "comment" ;
    Info info;
  end IMPORT;

  record COMPONENTS
    ElementAttributes attributes "attributes" ;
    TypeSpec typeSpec "typeSpec" ;
    list<ComponentItem> components "components" ;
  end COMPONENTS;

end ElementSpec;

public
uniontype InnerOuter
  "One of the keyword inner and outer CAN be given to reference an
   inner or outer element. Thus there are three disjoint possibilities."
  record INNER           "an inner prefix"       end INNER;
  record OUTER           "an outer prefix"       end OUTER;
  record INNER_OUTER     "an inner outer prefix" end INNER_OUTER;
  record NOT_INNER_OUTER "no inner outer prefix" end NOT_INNER_OUTER;
end InnerOuter;

public
uniontype Import "Import statements, different kinds"
  // A named import is a import statement to a variable ex;
  // NAMED_IMPORT("SI",QUALIFIED("Modelica",IDENT("SIunits")));
  record NAMED_IMPORT
    Ident name "name" ;
    Path path "path" ;
  end NAMED_IMPORT;

  record QUAL_IMPORT
    Path path "path" ;
  end QUAL_IMPORT;

  record UNQUAL_IMPORT
    Path path "path" ;
  end UNQUAL_IMPORT;

  record GROUP_IMPORT
    Path prefix;
    list<GroupImport> groups;
  end GROUP_IMPORT;

end Import;

public
uniontype GroupImport
  record GROUP_IMPORT_NAME
    String name;
  end GROUP_IMPORT_NAME;
  record GROUP_IMPORT_RENAME
    String rename;
    String name;
  end GROUP_IMPORT_RENAME;
end GroupImport;

public
uniontype ComponentItem "Collection of component and an optional comment"
  record COMPONENTITEM
    Component component "component" ;
    Option<ComponentCondition> condition "condition" ;
    Option<Comment> comment "comment" ;
  end COMPONENTITEM;

end ComponentItem;

public
type ComponentCondition = Exp "A componentItem can have a condition that must be fulfilled if
  the component should be instantiated.
" ;

public
uniontype Component "Some kind of Modelica entity (object or variable)"
  record COMPONENT
    Ident name "name" ;
    ArrayDim arrayDim "Array dimensions, if any" ;
    Option<Modification> modification "Optional modification" ;
  end COMPONENT;

end Component;

public
uniontype EquationItem "Several component declarations can be grouped together in one
  `ElementSpec\' by writing them on the same line in the source.
  This type contains the information specific to one component."
  record EQUATIONITEM
    Equation equation_ "equation" ;
    Option<Comment> comment "comment" ;
    Info info "line number" ;
  end EQUATIONITEM;

  record EQUATIONITEMCOMMENT
    String comment;
  end EQUATIONITEMCOMMENT;

end EquationItem;

public
uniontype AlgorithmItem "Info specific for an algorithm item."
  record ALGORITHMITEM
    Algorithm algorithm_ "algorithm" ;
    Option<Comment> comment "comment" ;
    Info info "line number" ;
  end ALGORITHMITEM;

  record ALGORITHMITEMCOMMENT "A comment from the lexer"
    String comment;
  end ALGORITHMITEMCOMMENT;

end AlgorithmItem;

public
uniontype Equation "Information on one (kind) of equation, different constructors for different
     kinds of equations"
  record EQ_IF
    Exp ifExp "Conditional expression" ;
    list<EquationItem> equationTrueItems "true branch" ;
    list<tuple<Exp, list<EquationItem>>> elseIfBranches "elseIfBranches" ;
    list<EquationItem> equationElseItems "equationElseItems Standard 2-side eqn" ;
  end EQ_IF;

  record EQ_EQUALS
    Exp leftSide "leftSide" ;
    Exp rightSide "rightSide Connect stmt" ;
  end EQ_EQUALS;

  record EQ_PDE
    Exp leftSide "leftSide" ;
    Exp rightSide "rightSide Connect stmt" ;
    ComponentRef domain "domain for PDEs" ;
  end EQ_PDE;

  record EQ_CONNECT
    ComponentRef connector1 "connector1" ;
    ComponentRef connector2 "connector2" ;
  end EQ_CONNECT;

  record EQ_FOR
    ForIterators iterators;
    list<EquationItem> forEquations "forEquations" ;
  end EQ_FOR;

  record EQ_WHEN_E
    Exp whenExp "whenExp" ;
    list<EquationItem> whenEquations "whenEquations" ;
    list<tuple<Exp, list<EquationItem>>> elseWhenEquations "elseWhenEquations" ;
  end EQ_WHEN_E;

  record EQ_NORETCALL
    ComponentRef functionName "functionName" ;
    FunctionArgs functionArgs "functionArgs; fcalls without return value" ;
  end EQ_NORETCALL;

  record EQ_FAILURE
    EquationItem equ;
  end EQ_FAILURE;

end Equation;

public
uniontype Algorithm "The Algorithm type describes one algorithm statement in an
  algorithm section.  It does not describe a whole algorithm.  The
  reason this type is named like this is that the name of the
  grammar rule for algorithm statements is `algorithm\'."
  record ALG_ASSIGN
    Exp assignComponent "assignComponent" ;
    Exp value "value" ;
  end ALG_ASSIGN;

  record ALG_IF
    Exp ifExp "ifExp" ;
    list<AlgorithmItem> trueBranch "trueBranch" ;
    list<tuple<Exp, list<AlgorithmItem>>> elseIfAlgorithmBranch "elseIfAlgorithmBranch" ;
    list<AlgorithmItem> elseBranch "elseBranch" ;
  end ALG_IF;

  record ALG_FOR
    ForIterators iterators;
    list<AlgorithmItem> forBody "forBody" ;
  end ALG_FOR;

  record ALG_PARFOR
    ForIterators iterators;
    list<AlgorithmItem> parforBody "parallel for loop Body" ;
  end ALG_PARFOR;

  record ALG_WHILE
    Exp boolExpr "boolExpr" ;
    list<AlgorithmItem> whileBody "whileBody" ;
  end ALG_WHILE;

  record ALG_WHEN_A
    Exp boolExpr "boolExpr" ;
    list<AlgorithmItem> whenBody "whenBody" ;
    list<tuple<Exp, list<AlgorithmItem>>> elseWhenAlgorithmBranch "elseWhenAlgorithmBranch" ;
  end ALG_WHEN_A;

  record ALG_NORETCALL
    ComponentRef functionCall "functionCall" ;
    FunctionArgs functionArgs "functionArgs; general fcalls without return value" ;
  end ALG_NORETCALL;

  record ALG_RETURN
  end ALG_RETURN;

  record ALG_BREAK
  end ALG_BREAK;

  // MetaModelica extensions
  record ALG_FAILURE
    list<AlgorithmItem> equ;
  end ALG_FAILURE;

  record ALG_TRY
    list<AlgorithmItem> body;
    list<AlgorithmItem> elseBody;
  end ALG_TRY;

  record ALG_CONTINUE
  end ALG_CONTINUE;

end Algorithm;

public
uniontype Modification "Modifications are described by the `Modification\' type.  There
  are two forms of modifications: redeclarations and component
  modifications.
  - Modifications"
  record CLASSMOD
    list<ElementArg> elementArgLst;
    EqMod eqMod;
  end CLASSMOD;

end Modification;

public
uniontype EqMod
  record NOMOD
  end NOMOD;
  record EQMOD
    Exp exp;
    Info info;
  end EQMOD;
end EqMod;

public
uniontype ElementArg "Wrapper for things that modify elements, modifications and redeclarations"
  record MODIFICATION
    Boolean finalPrefix "final prefix";
    Each eachPrefix "each";
    Path path;
    Option<Modification> modification "modification";
    Option<String> comment "comment";
    Info info;
  end MODIFICATION;

  record REDECLARATION
    Boolean finalPrefix "final prefix";
    RedeclareKeywords redeclareKeywords "redeclare  or replaceable ";
    Each eachPrefix "each prefix";
    ElementSpec elementSpec "elementSpec";
    Option<ConstrainClass> constrainClass "class definition or declaration";
    Info info "needed because ElementSpec does not contain this info; Element does";
  end REDECLARATION;

end ElementArg;

public
uniontype RedeclareKeywords "The keywords redeclare and replacable can be given in three different kombinations, each one by themself or the both combined."
  record REDECLARE end REDECLARE;

  record REPLACEABLE end REPLACEABLE;

  record REDECLARE_REPLACEABLE end REDECLARE_REPLACEABLE;

end RedeclareKeywords;

public
uniontype Each "The each keyword can be present in both MODIFICATION\'s and REDECLARATION\'s.
  - Each attribute"
  record EACH end EACH;

  record NON_EACH end NON_EACH;

end Each;

public
uniontype ElementAttributes "Element attributes"
  record ATTR
    Boolean flowPrefix "flow";
    Boolean streamPrefix "stream";
    Parallelism parallelism "for OpenCL/CUDA parglobal, parlocal ...";
    Variability variability "parameter, constant etc.";
    Direction direction "input/output";
    IsField isField "non-field / field";
    ArrayDim arrayDim "array dimensions";
   end ATTR;
end ElementAttributes;

public
uniontype IsField "Is field"
  record NONFIELD "variable is not a field"  end NONFIELD;
  record FIELD "variable is a field"         end FIELD;
end IsField;

public
uniontype Parallelism "Parallelism"
  record PARGLOBAL  "Global variables for CUDA and OpenCL"            end PARGLOBAL;
  record PARLOCAL "Shared for CUDA and local for OpenCL"              end PARLOCAL;
  record NON_PARALLEL  "Non parallel/Normal variables"                 end NON_PARALLEL;
end Parallelism;

public
uniontype FlowStream
  record FLOW end FLOW;
  record STREAM end STREAM;
  record NOT_FLOW_STREAM end NOT_FLOW_STREAM;
end FlowStream;

public
uniontype Variability "Variability"
  record VAR end VAR;

  record DISCRETE end DISCRETE;

  record PARAM end PARAM;

  record CONST end CONST;

end Variability;

public
uniontype Direction "Direction"
  record INPUT "direction is input"
  end INPUT;
  record OUTPUT "direction is output"
  end OUTPUT;
  record BIDIR  "direction is not specified, neither input nor output"
  end BIDIR;
  record INPUT_OUTPUT "direction is both input and output (OM extension; syntactic sugar for functions)"
  end INPUT_OUTPUT;
end Direction;

public
type ArrayDim = list<Subscript> "Component attributes are
  properties of components which are applied by type prefixes.
  As an example, declaring a component as `input Real x;\' will
  give the attributes `ATTR({},false,VAR,INPUT)\'.
  Components in Modelica can be scalar or arrays with one or more
  dimensions. This type is used to indicate the dimensionality
  of a component or a type definition.
- Array dimensions" ;

public
uniontype Exp "The Exp uniontype is the container of a Modelica expression.
  - Expressions"
  record INTEGER
    Integer value;
  end INTEGER;

  record REAL
    String value "String representation of a Real, in order to unparse without changing the user's display preference";
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

  record BINARY   "Binary operations, e.g. a*b"
    Exp exp1;
    Operator op;
    Exp exp2;
  end BINARY;

  record UNARY  "Unary operations, e.g. -(x), +(x)"
    Operator op "op" ;
    Exp exp "exp - any arithmetic expression" ;
  end UNARY;

  record LBINARY
    Exp exp1 "exp1" ;
    Operator op "op" ;
    Exp exp2 ;
  end LBINARY;

  record LUNARY  "Logical unary operations: not"
    Operator op "op" ;
    Exp exp "exp - any logical or relation expression" ;
  end LUNARY;

  record RELATION
    Exp exp1 "exp1" ;
    Operator op "op" ;
    Exp exp2  ;
  end RELATION;

  record IFEXP  "If expressions"
    Exp ifExp "ifExp" ;
    Exp trueBranch "trueBranch" ;
    Exp elseBranch "elseBranch" ;
    list<tuple<Exp, Exp>> elseIfBranch "elseIfBranch Function calls" ;
  end IFEXP;

  record CALL
    ComponentRef function_ "function" ;
    FunctionArgs functionArgs ;
  end CALL;

  // stefan
  record PARTEVALFUNCTION "Partially evaluated function"
    ComponentRef function_ "function" ;
    FunctionArgs functionArgs ;
  end PARTEVALFUNCTION;

  record ARRAY   "Array construction using {, }, or array"
    list<Exp> arrayExp ;
  end ARRAY;

  record MATRIX  "Matrix construction using {, } "
    list<list<Exp>> matrix ;
  end MATRIX;

  record RANGE  "Range expressions, e.g. 1:10 or 1:0.5:10"
    Exp start "start" ;
    Option<Exp> step "step" ;
    Exp stop "stop";
  end RANGE;

  record TUPLE " Tuples used in function calls returning several values"
    list<Exp> expressions "comma-separated expressions" ;
  end TUPLE;

  record END "array access operator for last element, e.g. a{end}:=1;"
  end END;


  record CODE  "Modelica AST Code constructors - OpenModelica extension"
    CodeNode code;
  end CODE;

  // MetaModelica expressions follow below!

  record AS  "as operator"
    Ident id " only an id " ;
    Exp exp  " expression to bind to the id ";
  end AS;

  record CONS  "list cons or :: operator"
    Exp head " head of the list ";
    Exp rest " rest of the list ";
  end CONS;

  record MATCHEXP "matchcontinue expression"
    MatchType matchTy            " match or matchcontinue      ";
    Exp inputExp                 " match expression of         ";
    list<ElementItem> localDecls " local declarations          ";
    list<Case> cases             " case list + else in the end ";
    Option<String> comment       " match expr comment_optional ";
  end MATCHEXP;

  // The following are only used internally in the compiler
  record LIST "Part of MetaModelica extension"
    list<Exp> exps;
  end LIST;

  record DOT "exp.index"
    Exp exp, index;
  end DOT;

end Exp;

uniontype Case "case in match or matchcontinue"
  record CASE
    Exp pattern " patterns to be matched ";
    Option<Exp> patternGuard;
    Info patternInfo "file information of the pattern";
    list<ElementItem> localDecls " local decls ";
    ClassPart classPart " equation or algorithm section ";
    Exp result " result ";
    Info resultInfo "file information of the result-exp";
    Option<String> comment " comment after case like: case pattern string_comment ";
    Info info "file information of the whole case";
  end CASE;

  record ELSE "else in match or matchcontinue"
    list<ElementItem> localDecls " local decls ";
    ClassPart classPart " equation or algorithm section ";
    Exp result " result ";
    Info resultInfo "file information of the result-exp";
    Option<String> comment " comment after case like: case pattern string_comment ";
    Info info "file information of the whole case";
  end ELSE;
end Case;


uniontype MatchType
  record MATCH end MATCH;
  record MATCHCONTINUE end MATCHCONTINUE;
end MatchType;


uniontype CodeNode "The Code uniontype is used for Meta-programming. It originates from the $Code quoting mechanism. See paper in Modelica2003 conference"
  record C_TYPENAME "Cannot be parsed; used by Static for API calls"
    Path path;
  end C_TYPENAME;

  record C_VARIABLENAME "Cannot be parsed; used by Static for API calls"
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


uniontype FunctionArgs "The FunctionArgs uniontype consists of a list of positional arguments
  followed by a list of named arguments (Modelica v2.0)"
  record FUNCTIONARGS
    list<Exp> args "args" ;
    list<NamedArg> argNames "argNames" ;
  end FUNCTIONARGS;

  record FOR_ITER_FARG
     Exp  exp "iterator expression";
     ReductionIterType iterType;
     ForIterators iterators;
  end FOR_ITER_FARG;

end FunctionArgs;

constant FunctionArgs emptyFunctionArgs = FUNCTIONARGS({},{});

uniontype ReductionIterType
  record COMBINE "Reductions are by default calculated as all combinations of the iterators"
  end COMBINE;
  record THREAD "With this option, all iterators must have the same length"
  end THREAD;
end ReductionIterType;

uniontype NamedArg "The NamedArg uniontype consist of an Identifier for the argument and an expression
  giving the value of the argument"
  record NAMEDARG
    Ident argName "argName" ;
    Exp argValue "argValue" ;
  end NAMEDARG;

end NamedArg;


uniontype Operator "Expression operators"
  /* arithmetic operators */
  record ADD       "addition"                    end ADD;
  record SUB       "subtraction"                 end SUB;
  record MUL       "multiplication"              end MUL;
  record DIV       "division"                    end DIV;
  record POW       "power"                       end POW;
  record UPLUS     "unary plus"                  end UPLUS;
  record UMINUS    "unary minus"                 end UMINUS;
  /* element-wise arithmetic operators */
  record ADD_EW    "element-wise addition"       end ADD_EW;
  record SUB_EW    "element-wise subtraction"    end SUB_EW;
  record MUL_EW    "element-wise multiplication" end MUL_EW;
  record DIV_EW    "element-wise division"       end DIV_EW;
  record POW_EW    "element-wise power"          end POW_EW;
  record UPLUS_EW  "element-wise unary minus"    end UPLUS_EW;
  record UMINUS_EW "element-wise unary plus"     end UMINUS_EW;
  /* logical operators */
  record AND       "logical and"                 end AND;
  record OR        "logical or"                  end OR;
  record NOT       "logical not"                 end NOT;
  /* relational operators */
  record LESS      "less than"                   end LESS;
  record LESSEQ    "less than or equal"          end LESSEQ;
  record GREATER   "greater than"                end GREATER;
  record GREATEREQ "greater than or equal"       end GREATEREQ;
  record EQUAL     "relational equal"            end EQUAL;
  record NEQUAL    "relational not equal"        end NEQUAL;
end Operator;


uniontype Subscript "The Subscript uniontype is used both in array declarations and
  component references.  This might seem strange, but it is
  inherited from the grammar.  The NOSUB constructor means that
  the dimension size is undefined when used in a declaration, and
  when it is used in a component reference it means a slice of the
  whole dimension.
  - Subscripts"
  record NOSUB "unknown array dimension" end NOSUB;

  record SUBSCRIPT "dimension as an expression"
    Exp subscript "subscript";
  end SUBSCRIPT;
end Subscript;


uniontype ComponentRef "A component reference is the fully or partially qualified name of
  a component.  It is represented as a list of
  identifier--subscript pairs.
  - Component references and paths"
  record CREF_FULLYQUALIFIED
    ComponentRef componentRef;
  end CREF_FULLYQUALIFIED;
  record CREF_QUAL
    Ident name "name" ;
    list<Subscript> subscripts "subscripts" ;
    ComponentRef componentRef "componentRef" ;
  end CREF_QUAL;

  record CREF_IDENT
    Ident name "name" ;
    list<Subscript> subscripts "subscripts" ;
  end CREF_IDENT;

  record WILD end WILD;
  record ALLWILD end ALLWILD;
end ComponentRef;


uniontype Path "The type `Path\', on the other hand,
  is used to store references to class names, or names inside
  class definitions."
  record QUALIFIED
    Ident name "name" ;
    Path path "path" ;
  end QUALIFIED;

  record IDENT
    Ident name "name" ;
  end IDENT;

  record FULLYQUALIFIED "Used during instantiation for names that are fully qualified,
    i.e. the names are looked up from top scope directly like for instance Modelica.SIunits.Voltage
    Note: Not created during parsing, only during instantation to speedup/simplify lookup.
  "
    Path path;
  end FULLYQUALIFIED;
end Path;


uniontype Restriction "These constructors each correspond to a different kind of class
  declaration in Modelica, except the last four, which are used
  for the predefined types.  The parser assigns each class
  declaration one of the restrictions, and the actual class
  definition is checked for conformance during translation.  The
  predefined types are created in the Builtin module and are
  assigned special restrictions.
 "
  record R_CLASS end R_CLASS;
  record R_OPTIMIZATION end R_OPTIMIZATION;
  record R_MODEL end R_MODEL;
  record R_RECORD end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR "connector class" end R_CONNECTOR;
  record R_EXP_CONNECTOR "expandable connector class" end R_EXP_CONNECTOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION
    FunctionRestriction functionRestriction;
  end R_FUNCTION;
  record R_OPERATOR "an operator" end R_OPERATOR;
  record R_OPERATOR_RECORD   "an operator record"   end R_OPERATOR_RECORD;
  record R_ENUMERATION end R_ENUMERATION;
  record R_PREDEFINED_INTEGER end R_PREDEFINED_INTEGER;
  record R_PREDEFINED_REAL end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOLEAN end R_PREDEFINED_BOOLEAN;
  record R_PREDEFINED_ENUMERATION end R_PREDEFINED_ENUMERATION;
  // BTH
  record R_PREDEFINED_CLOCK end R_PREDEFINED_CLOCK;

  // MetaModelica
  record R_UNIONTYPE "MetaModelica uniontype" end R_UNIONTYPE;
  record R_METARECORD "Metamodelica record"  //MetaModelica extension, added by simbj
    Path name; //Name of the uniontype
    Integer index; //Index in the uniontype
    Boolean singleton;
    Boolean moved; // true if moved outside uniontype, otherwise false.
    list<String> typeVars;
  end R_METARECORD;
  record R_UNKNOWN "Helper restriction" end R_UNKNOWN; /* added by simbj */
end Restriction;

public
uniontype FunctionPurity "function purity"
  record PURE   end PURE;
  record IMPURE end IMPURE;
  record NO_PURITY end NO_PURITY;
end FunctionPurity;

public
uniontype FunctionRestriction
  record FR_NORMAL_FUNCTION "a normal function"
    FunctionPurity purity "function purity";
  end FR_NORMAL_FUNCTION;
  record FR_OPERATOR_FUNCTION "an operator function" end FR_OPERATOR_FUNCTION;
  record FR_PARALLEL_FUNCTION "an OpenCL/CUDA parallel/device function" end FR_PARALLEL_FUNCTION;
  record FR_KERNEL_FUNCTION "an OpenCL/CUDA kernel function" end FR_KERNEL_FUNCTION;
end FunctionRestriction;

public
uniontype Annotation "An Annotation is a class_modification.
  - Annotation"
  record ANNOTATION
    list<ElementArg> elementArgs "elementArgs" ;
  end ANNOTATION;

end Annotation;

public
uniontype Comment "Comment"
  record COMMENT
    Option<Annotation> annotation_ "annotation" ;
    Option<String> comment "comment" ;
  end COMMENT;

end Comment;

public
uniontype ExternalDecl "Declaration of an external function call - ExternalDecl"

  record EXTERNALDECL
    Option<Ident>        funcName "The name of the external function" ;
    Option<String>       lang     "Language of the external function" ;
    Option<ComponentRef> output_  "output parameter as return value" ;
    list<Exp>            args     "only positional arguments, i.e. expression list" ;
    Option<Annotation>   annotation_;
  end EXTERNALDECL;

end ExternalDecl;

public uniontype Ref
  record RCR
    ComponentRef cr;
  end RCR;
  record RTS
    TypeSpec ts;
  end RTS;
  record RIM
    Import im;
  end RIM;
end Ref;

public uniontype Msg "Controls output of error-messages"
  record MSG "Give error message"
    Info info;
  end MSG;

  record NO_MSG "Do not give error message" end NO_MSG;
end Msg;

/* "From here down, only Absyn helper functions should be present.
 Thus, no actual absyn uniontype definitions." */

protected import List;
protected import Util;
protected import Error;

public constant ClassDef dummyParts = PARTS({},{},{},{},NONE());
public constant Info dummyInfo = SOURCEINFO("",false,0,0,0,0,0.0);
public constant Program dummyProgram = PROGRAM({},TOP());

// stefan
public function traverseEquation
  "Traverses all subequations of an equation.
   Takes a function and an extra argument passed through the traversal"
  input Equation inEquation;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<Equation, TypeA> outTpl;

  partial function FuncTplToTpl
    input tuple<Equation, TypeA> inTpl;
    output tuple<Equation, TypeA> outTpl;
  end FuncTplToTpl;

  replaceable type TypeA subtypeof Any;
algorithm
  outTpl := matchcontinue (inEquation,inFunc,inTypeA)
    local
      TypeA arg,arg_1,arg_2,arg_3,arg_4;
      Equation eq,eq_1;
      FuncTplToTpl rel;
      Exp e,e_1;
      list<EquationItem> eqilst,eqilst1,eqilst2,eqilst_1,eqilst1_1,eqilst2_1;
      list<tuple<Exp, list<EquationItem>>> eeqitlst,eeqitlst_1;
      ForIterators fis,fis_1;
      EquationItem ei,ei_1;
    case(eq as EQ_IF(e,eqilst1,eeqitlst,eqilst2),rel,arg)
      equation
        ((eqilst1_1,arg_1)) = traverseEquationItemList(eqilst1,rel,arg);
        ((eeqitlst_1,arg_2)) = traverseExpEqItemTupleList(eeqitlst,rel,arg_1);
        ((eqilst2_1,arg_3)) = traverseEquationItemList(eqilst2,rel,arg_2);
        ((EQ_IF(),arg_4)) = rel((eq,arg_3));
      then
        ((EQ_IF(e,eqilst1_1,eeqitlst_1,eqilst2_1),arg_4));
    case(eq as EQ_FOR(_,eqilst),rel,arg)
      equation
        ((eqilst_1,arg_1)) = traverseEquationItemList(eqilst,rel,arg);
        ((EQ_FOR(fis_1,_),arg_2)) = rel((eq,arg_1));
      then
        ((EQ_FOR(fis_1,eqilst_1),arg_2));
    case(eq as EQ_WHEN_E(_,eqilst,eeqitlst),rel,arg)
      equation
        ((eqilst_1,arg_1)) = traverseEquationItemList(eqilst,rel,arg);
        ((eeqitlst_1,arg_2)) = traverseExpEqItemTupleList(eeqitlst,rel,arg_1);
        ((EQ_WHEN_E(e_1,_,_),arg_3)) = rel((eq,arg_2));
      then
        ((EQ_WHEN_E(e_1,eqilst_1,eeqitlst_1),arg_3));
    case(eq as EQ_FAILURE(ei),rel,arg)
      equation
        ((ei_1,arg_1)) = traverseEquationItem(ei,rel,arg);
        ((EQ_FAILURE(),arg_2)) = rel((eq,arg_1));
      then
        ((EQ_FAILURE(ei_1),arg_2));
    case(eq,rel,arg)
      equation
        ((eq_1,arg_1)) = rel((eq,arg));
      then
        ((eq_1,arg_1));
  end matchcontinue;
end traverseEquation;

// stefan
protected function traverseEquationItem
"Traverses the equation inside an equationitem"
  input EquationItem inEquationItem;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<EquationItem, TypeA> outTpl;
  partial function FuncTplToTpl
    input tuple<Equation, TypeA> inTpl;
    output tuple<Equation, TypeA> outTpl;
    replaceable type TypeA subtypeof Any;
  end FuncTplToTpl;
  replaceable type TypeA subtypeof Any;
algorithm
  outTpl := matchcontinue (inEquationItem,inFunc,inTypeA)
    local
      EquationItem ei;
      FuncTplToTpl rel;
      TypeA arg,arg_1;
      Equation eq,eq_1;
      Option<Comment> oc;
      Info info;
    case(EQUATIONITEM(eq,oc,info),rel,arg)
      equation
        ((eq_1,arg_1)) = traverseEquation(eq,rel,arg);
      then
        ((EQUATIONITEM(eq_1,oc,info),arg_1));
    case(ei,_,arg) then ((ei,arg));
  end matchcontinue;
end traverseEquationItem;

// stefan
public function traverseEquationItemList
"calls traverseEquationItem on every element of the given list"
  input list<EquationItem> inEquationItemList;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<list<EquationItem>, TypeA> outTpl;
  partial function FuncTplToTpl
    input tuple<Equation, TypeA> inTpl;
    output tuple<Equation, TypeA> outTpl;
    replaceable type TypeA subtypeof Any;
  end FuncTplToTpl;
  replaceable type TypeA subtypeof Any;
protected
  TypeA arg2 = inTypeA;
algorithm
  outTpl := (list(match el
      local
        EquationItem ei,ei_1;
      case (ei) equation
        ((ei_1,arg2)) = traverseEquationItem(ei,inFunc,arg2);
      then ei_1;
    end match for el in inEquationItemList), arg2);
end traverseEquationItemList;

// stefan
public function traverseExpEqItemTupleList
"traverses a list of Exp * EquationItem list tuples
  mostly used for else-if blocks"
  input list<tuple<Exp, list<EquationItem>>> inList;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<list<tuple<Exp, list<EquationItem>>>, TypeA> outTpl;
  partial function FuncTplToTpl
    input tuple<Equation, TypeA> inTpl;
    output tuple<Equation, TypeA> outTpl;
    replaceable type TypeA subtypeof Any;
  end FuncTplToTpl;
  replaceable type TypeA subtypeof Any;
protected
  TypeA arg2 = inTypeA;
algorithm
  outTpl := (list(match el
      local
        Exp e;
        list<EquationItem> eilst,eilst_1;
      case (e,eilst) equation
        ((eilst_1,arg2)) = traverseEquationItemList(eilst,inFunc,arg2);
      then (e,eilst_1);
    end match for el in inList), arg2);
end traverseExpEqItemTupleList;

// stefan
public function traverseAlgorithm
"Traverses all subalgorithms of an algorithm
  Takes a function and an extra argument passed through the traversal"
  input Algorithm inAlgorithm;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<Algorithm, TypeA> outTpl;
  partial function FuncTplToTpl
    input tuple<Algorithm, TypeA> inTpl;
    output tuple<Algorithm, TypeA> outTpl;
    replaceable type TypeA subtypeof Any;
  end FuncTplToTpl;
  replaceable type TypeA subtypeof Any;
algorithm
  outTpl := matchcontinue (inAlgorithm,inFunc,inTypeA)
    local
      TypeA arg,arg_1,arg1_1,arg2_1,arg3_1;
      Algorithm alg,alg_1,alg1_1,alg2_1,alg3_1;
      list<AlgorithmItem> ailst,ailst1,ailst2,ailst_1,ailst1_1,ailst2_1;
      list<tuple<Exp, list<AlgorithmItem>>> eaitlst,eaitlst_1;
      FuncTplToTpl rel;
      AlgorithmItem ai,ai_1;
      Exp e,e_1;
      ForIterators fis,fis_1;
    case(alg as ALG_IF(_,ailst1,eaitlst,ailst2),rel,arg)
      equation
        ((ailst1_1,arg1_1)) = traverseAlgorithmItemList(ailst1,rel,arg);
        ((eaitlst_1,arg2_1)) = traverseExpAlgItemTupleList(eaitlst,rel,arg1_1);
        ((ailst2_1,arg3_1)) = traverseAlgorithmItemList(ailst2,rel,arg2_1);
        ((ALG_IF(e_1,_,_,_),arg_1)) = rel((alg,arg3_1));
      then
        ((ALG_IF(e_1,ailst1_1,eaitlst_1,ailst2_1),arg_1));
    case(alg as ALG_FOR(_,ailst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((ALG_FOR(fis_1,_),arg_1)) = rel((alg,arg1_1));
      then
        ((ALG_FOR(fis_1,ailst_1),arg_1));
    case(alg as ALG_PARFOR(_,ailst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((ALG_PARFOR(fis_1,_),arg_1)) = rel((alg,arg1_1));
      then
        ((ALG_PARFOR(fis_1,ailst_1),arg_1));
    case(alg as ALG_WHILE(_,ailst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((ALG_WHILE(e_1,_),arg_1)) = rel((alg,arg1_1));
      then
        ((ALG_WHILE(e_1,ailst_1),arg_1));
    case(alg as ALG_WHEN_A(_,ailst,eaitlst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((eaitlst_1,arg2_1)) = traverseExpAlgItemTupleList(eaitlst,rel,arg1_1);
        ((ALG_WHEN_A(e_1,_,_),arg_1)) = rel((alg,arg2_1));
      then
        ((ALG_WHEN_A(e_1,ailst_1,eaitlst_1),arg_1));
    case(alg,rel,arg)
      equation
        ((alg_1,arg_1)) = rel((alg,arg));
      then
        ((alg_1,arg_1));
  end matchcontinue;
end traverseAlgorithm;

// stefan
public function traverseAlgorithmItem
"traverses the Algorithm contained in an AlgorithmItem, if any
  see traverseAlgorithm"
  input AlgorithmItem inAlgorithmItem;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<AlgorithmItem, TypeA> outTpl;
  partial function FuncTplToTpl
    input tuple<Algorithm, TypeA> inTpl;
    output tuple<Algorithm, TypeA> outTpl;
    replaceable type TypeA subtypeof Any;
  end FuncTplToTpl;
  replaceable type TypeA subtypeof Any;
algorithm
  outTpl := matchcontinue (inAlgorithmItem,inFunc,inTypeA)
    local
      FuncTplToTpl rel;
      TypeA arg,arg_1;
      Algorithm alg,alg_1;
      Option<Comment> oc;
      AlgorithmItem ai;
      Info info;
    case(ALGORITHMITEM(alg,oc,info),rel,arg)
      equation
        ((alg_1,arg_1)) = traverseAlgorithm(alg,rel,arg);
      then
        ((ALGORITHMITEM(alg_1,oc,info),arg_1));
    case(ai,_,arg) then ((ai,arg));
  end matchcontinue;
end traverseAlgorithmItem;

// stefan
public function traverseAlgorithmItemList
"calls traverseAlgorithmItem on each item in a list of AlgorithmItems"
  input list<AlgorithmItem> inAlgorithmItemList;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<list<AlgorithmItem>, TypeA> outTpl;
  partial function FuncTplToTpl
    input tuple<Algorithm, TypeA> inTpl;
    output tuple<Algorithm, TypeA> outTpl;
    replaceable type TypeA subtypeof Any;
  end FuncTplToTpl;
  replaceable type TypeA subtypeof Any;
algorithm
  outTpl := match (inAlgorithmItemList,inFunc,inTypeA)
    local
      FuncTplToTpl rel;
      TypeA arg,arg_1,arg_2;
      AlgorithmItem ai,ai_1;
      list<AlgorithmItem> cdr,cdr_1;
    case({},_,arg) then (({},arg));
    case(ai :: cdr,rel,arg)
      equation
        ((ai_1,arg_1)) = traverseAlgorithmItem(ai,rel,arg);
        ((cdr_1,arg_2)) = traverseAlgorithmItemList(cdr,rel,arg_1);
      then
        ((ai_1 :: cdr_1,arg_2));
  end match;
end traverseAlgorithmItemList;

// stefan
public function traverseExpAlgItemTupleList
"traverses a list of Exp * AlgorithmItem list tuples
  mostly used for else-if blocks"
  input list<tuple<Exp, list<AlgorithmItem>>> inList;
  input FuncTplToTpl inFunc;
  input TypeA inTypeA;
  output tuple<list<tuple<Exp, list<AlgorithmItem>>>, TypeA> outTpl;
  partial function FuncTplToTpl
    input tuple<Algorithm, TypeA> inTpl;
    output tuple<Algorithm, TypeA> outTpl;
    replaceable type TypeA subtypeof Any;
  end FuncTplToTpl;
  replaceable type TypeA subtypeof Any;
algorithm
  outTpl := match (inList,inFunc,inTypeA)
    local
      FuncTplToTpl rel;
      TypeA arg,arg_1,arg_2;
      list<tuple<Exp, list<AlgorithmItem>>> cdr,cdr_1;
      Exp e;
      list<AlgorithmItem> ailst,ailst_1;
    case({},_,arg) then (({},arg));
    case((e,ailst) :: cdr,rel,arg)
      equation
        ((ailst_1,arg_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((cdr_1,arg_2)) = traverseExpAlgItemTupleList(cdr,rel,arg_1);
      then
        (((e,ailst_1) :: cdr_1,arg_2));
  end match;
end traverseExpAlgItemTupleList;

public function traverseExp
" Traverses all subexpressions of an Exp expression.
  Takes a function and an extra argument passed through the traversal.
  NOTE:This function was copied from Expression.traverseExpression."
  input Exp inExp;
  input FuncType inFunc;
  input Type_a inArg;
  output Exp outExp;
  output Type_a outArg;
  partial function FuncType
    input Exp inExp;
    input Type_a inArg;
    output Exp outExp;
    output Type_a outArg;
    replaceable type Type_a subtypeof Any;
  end FuncType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outArg) := traverseExpBidir(inExp,dummyTraverseExp,inFunc,inArg);
end traverseExp;

public function traverseExpTopDown
" Traverses all subexpressions of an Exp expression.
  Takes a function and an extra argument passed through the traversal."
  input Exp inExp;
  input FuncType inFunc;
  input Type_a inArg;
  output Exp outExp;
  output Type_a outArg;
  partial function FuncType
    input Exp inExp;
    input Type_a inArg;
    output Exp outExp;
    output Type_a outArg;
    replaceable type Type_a subtypeof Any;
  end FuncType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outArg) := traverseExpBidir(inExp,inFunc,dummyTraverseExp,inArg);
end traverseExpTopDown;

public function traverseExpList
"calls traverseExp on each element in the given list"
  input list<Exp> inExpList;
  input FuncTplToTpl inFunc;
  input Type_a inArg;
  output list<Exp> outExpList;
  output Type_a outArg;
  partial function FuncTplToTpl
    input Exp inExp;
    input Type_a inArg;
    output Exp outExp;
    output Type_a outArg;
    replaceable type Type_a subtypeof Any;
  end FuncTplToTpl;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExpList,outArg) := traverseExpListBidir(inExpList,dummyTraverseExp,inFunc,inArg);
end traverseExpList;

public function traverseExpListBidir
  "Traverses a list of expressions, calling traverseExpBidir on each
  expression."
  input list<Exp> inExpl;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output list<Exp> outExpl;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;
  replaceable type Argument subtypeof Any;
algorithm
  (outExpl, outArg) := List.map2FoldCheckReferenceEq(inExpl, traverseExpBidir, enterFunc, exitFunc, inArg);
end traverseExpListBidir;

public function traverseExpBidir
  "This function takes an expression and a tuple with an enter function, an exit
  function, and an extra argument. For each expression it encounters it calls
  the enter function with the expression and the extra argument. It then
  traverses all subexpressions in the expression and calls traverseExpBidir on
  them with the updated argument. Finally it calls the exit function, again with
  the updated argument. This means that this function is bidirectional, and can
  be used to emulate both top-down and bottom-up traversal."
  input Exp inExp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output Exp e;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (e, arg) := enterFunc(inExp, inArg);
  (e, arg) := traverseExpBidirSubExps(e, enterFunc, exitFunc, arg);
  (e, arg) := exitFunc(e, arg);
end traverseExpBidir;

public function traverseExpOptBidir
  "Same as traverseExpBidir, but with an optional expression. Calls
  traverseExpBidir if the option is SOME(), or just returns the input if it's
  NONE()"
  input Option<Exp> inExp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output Option<Exp> outExp;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outExp, arg) := match(inExp, enterFunc, exitFunc, inArg)
    local
      Exp e1,e2;
      tuple<FuncType, FuncType, Argument> tup;

    case (SOME(e1), _, _, _)
      equation
        (e2, arg) = traverseExpBidir(e1, enterFunc, exitFunc, inArg);
      then
        (if referenceEq(e1,e2) then inExp else SOME(e2), arg);

    else (inExp, inArg);
  end match;
end traverseExpOptBidir;

protected function traverseExpBidirSubExps
  "Helper function to traverseExpBidir. Traverses the subexpressions of an
  expression and calls traverseExpBidir on them."
  input Exp inExp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output Exp e;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (e, arg) := match (inExp, enterFunc, exitFunc, inArg)
    local
      Exp e1, e1m, e2, e2m, e3, e3m;
      Option<Exp> oe1, oe1m;
      tuple<FuncType, FuncType, Argument> tup;
      Operator op;
      ComponentRef cref, crefm;
      list<tuple<Exp, Exp>> else_ifs1,else_ifs2;
      list<Exp> expl1,expl2;
      list<list<Exp>> mat_expl;
      FunctionArgs fargs1,fargs2;
      String error_msg;
      Ident id, enterName, exitName;
      MatchType match_ty;
      list<ElementItem> match_decls;
      list<Case> match_cases;
      Option<String> cmt;

    case (INTEGER(), _, _, _) then (inExp, inArg);
    case (REAL(), _, _, _) then (inExp, inArg);
    case (STRING(), _, _, _) then (inExp, inArg);
    case (BOOL(), _, _, _) then (inExp, inArg);

    case (CREF(componentRef = cref), _, _, arg)
      equation
        (crefm, arg) = traverseExpBidirCref(cref, enterFunc, exitFunc, arg);
      then
        (if referenceEq(cref,crefm) then inExp else CREF(crefm), arg);

    case (BINARY(exp1 = e1, op = op, exp2 = e2), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then inExp else BINARY(e1m, op, e2m), arg);

    case (UNARY(op = op, exp = e1), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) then inExp else UNARY(op, e1m), arg);

    case (LBINARY(exp1 = e1, op = op, exp2 = e2), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then inExp else LBINARY(e1m, op, e2m), arg);

    case (LUNARY(op = op, exp = e1), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) then inExp else LUNARY(op, e1m), arg);

    case (RELATION(exp1 = e1, op = op, exp2 = e2), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then inExp else RELATION(e1m, op, e2m), arg);

    case (IFEXP(ifExp = e1, trueBranch = e2, elseBranch = e3,
        elseIfBranch = else_ifs1), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
        (e3m, arg) = traverseExpBidir(e3, enterFunc, exitFunc, arg);
        (else_ifs2, arg) = List.map2FoldCheckReferenceEq(else_ifs1, traverseExpBidirElseIf, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) and referenceEq(e3,e3m) and referenceEq(else_ifs1,else_ifs2) then inExp else IFEXP(e1m, e2m, e3m, else_ifs2), arg);

    case (CALL(function_ = cref, functionArgs = fargs1), _, _, arg)
      equation
        (fargs2, arg) = traverseExpBidirFunctionArgs(fargs1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(fargs1,fargs2) then inExp else CALL(cref, fargs2), arg);

    case (PARTEVALFUNCTION(function_ = cref, functionArgs = fargs1), _, _, arg)
      equation
        (fargs2, arg) = traverseExpBidirFunctionArgs(fargs1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(fargs1,fargs2) then inExp else PARTEVALFUNCTION(cref, fargs2), arg);

    case (ARRAY(arrayExp = expl1), _, _, arg)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) then inExp else ARRAY(expl2), arg);

    case (MATRIX(matrix = mat_expl), _, _, arg)
      equation
        (mat_expl, arg) = List.map2FoldCheckReferenceEq(mat_expl, traverseExpListBidir, enterFunc, exitFunc, arg);
      then
        (MATRIX(mat_expl), arg);

    case (RANGE(start = e1, step = oe1, stop = e2), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (oe1m, arg) = traverseExpOptBidir(oe1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) and referenceEq(oe1,oe1m) then inExp else RANGE(e1m, oe1m, e2m), arg);

    case (END(), _, _, _) then (inExp, inArg);

    case (TUPLE(expressions = expl1), _, _, arg)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) then inExp else TUPLE(expl2), arg);

    case (AS(id = id, exp = e1), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) then inExp else AS(id, e1m), arg);

    case (CONS(head = e1, rest = e2), _, _, arg)
      equation
        (e1m, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2m, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e1m) and referenceEq(e2,e2m) then inExp else CONS(e1m, e2m), arg);

    case (MATCHEXP(matchTy = match_ty, inputExp = e1, localDecls = match_decls,
        cases = match_cases, comment = cmt), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (match_cases, arg) = List.map2FoldCheckReferenceEq(match_cases, traverseMatchCase, enterFunc, exitFunc, arg);
      then
        (MATCHEXP(match_ty, e1, match_decls, match_cases, cmt), arg);

    case (LIST(exps = expl1), _, _, arg)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) then inExp else LIST(expl2), arg);

    case (CODE(), _, _, _)
      then (inExp, inArg);

    case (DOT(), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(inExp.exp, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(inExp.index, enterFunc, exitFunc, arg);
      then
        (if referenceEq(inExp.exp,e1) and referenceEq(inExp.index,e2) then inExp else DOT(e1, e2), arg);

    else
      algorithm
        (,,enterName) := System.dladdr(enterFunc);
        (,,exitName) := System.dladdr(exitFunc);
        error_msg := "in traverseExpBidirSubExps(" + enterName + ", " + exitName + ") - Unknown expression: ";
        error_msg := error_msg + Dump.printExpStr(inExp);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();

  end match;
end traverseExpBidirSubExps;

public function traverseExpBidirCref
  "Helper function to traverseExpBidirSubExps. Traverses any expressions in a
  component reference (i.e. in it's subscripts)."
  input ComponentRef inCref;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output ComponentRef outCref;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;
  replaceable type Argument subtypeof Any;

algorithm
  (outCref, arg) := match(inCref, enterFunc, exitFunc, inArg)
    local
      Ident name;
      ComponentRef cr1,cr2;
      list<Subscript> subs1,subs2;
      tuple<FuncType, FuncType, Argument> tup;

    case (CREF_FULLYQUALIFIED(componentRef = cr1), _, _, arg)
      equation
        (cr2, arg) = traverseExpBidirCref(cr1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(cr1,cr2) then inCref else crefMakeFullyQualified(cr2), arg);

    case (CREF_QUAL(name = name, subscripts = subs1, componentRef = cr1), _, _, arg)
      equation
        (subs2, arg) = List.map2FoldCheckReferenceEq(subs1, traverseExpBidirSubs, enterFunc, exitFunc, arg);
        (cr2, arg) = traverseExpBidirCref(cr1, enterFunc, exitFunc, arg);
      then
        (if referenceEq(cr1,cr2) and referenceEq(subs1,subs2) then inCref else CREF_QUAL(name, subs2, cr2), arg);

    case (CREF_IDENT(name = name, subscripts = subs1), _, _, arg)
      equation
        (subs2, arg) = List.map2FoldCheckReferenceEq(subs1, traverseExpBidirSubs, enterFunc, exitFunc, arg);
      then
        (if referenceEq(subs1,subs2) then inCref else CREF_IDENT(name, subs2), arg);

    case (ALLWILD(), _, _, _) then (inCref, inArg);
    case (WILD(), _, _, _) then (inCref, inArg);
  end match;
end traverseExpBidirCref;

public function traverseExpBidirSubs
  "Helper function to traverseExpBidirCref. Traverses expressions in a
  subscript."
  input Subscript inSubscript;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output Subscript outSubscript;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;

algorithm
  (outSubscript, arg) := match(inSubscript, enterFunc, exitFunc, inArg)
    local
      Exp e1,e2;

    case (SUBSCRIPT(subscript = e1), _, _, arg)
      equation
        (e2, arg) = traverseExpBidir(e1, enterFunc, exitFunc, inArg);
      then
        (if referenceEq(e1,e2) then inSubscript else SUBSCRIPT(e2), arg);

    case (NOSUB(), _, _, _) then (inSubscript, inArg);
  end match;
end traverseExpBidirSubs;

public function traverseExpBidirElseIf
  "Helper function to traverseExpBidirSubExps. Traverses the expressions in an
  elseif branch."
  input tuple<Exp, Exp> inElseIf;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output tuple<Exp, Exp> outElseIf;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;

protected
  Exp e1, e2;
  tuple<FuncType, FuncType, Argument> tup;
algorithm
  (e1, e2) := inElseIf;
  (e1, arg) := traverseExpBidir(e1, enterFunc, exitFunc, inArg);
  (e2, arg) := traverseExpBidir(e2, enterFunc, exitFunc, arg);
  outElseIf := (e1, e2);
end traverseExpBidirElseIf;

public function traverseExpBidirFunctionArgs
  "Helper function to traverseExpBidirSubExps. Traverses the expressions in a
  list of function argument."
  input FunctionArgs inArgs;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output FunctionArgs outArgs;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outArgs, outArg) := match(inArgs, enterFunc, exitFunc, inArg)
    local
      Exp e1,e2;
      list<Exp> expl1,expl2;
      list<NamedArg> named_args1,named_args2;
      ForIterators iters1,iters2;
      Argument arg;
      ReductionIterType iterType;

    case (FUNCTIONARGS(args = expl1, argNames = named_args1), _, _, arg)
      equation
        (expl2, arg) = traverseExpListBidir(expl1, enterFunc, exitFunc, arg);
        (named_args2, arg) = List.map2FoldCheckReferenceEq(named_args1, traverseExpBidirNamedArg, enterFunc, exitFunc, arg);
      then
        (if referenceEq(expl1,expl2) and referenceEq(named_args1,named_args2) then inArgs else FUNCTIONARGS(expl2, named_args2), arg);

    case (FOR_ITER_FARG(e1, iterType, iters1), _, _, arg)
      equation
        (e2, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (iters2, arg) = List.map2FoldCheckReferenceEq(iters1, traverseExpBidirIterator, enterFunc, exitFunc, arg);
      then
        (if referenceEq(e1,e2) and referenceEq(iters1,iters2) then inArgs else FOR_ITER_FARG(e2, iterType, iters2), arg);
  end match;
end traverseExpBidirFunctionArgs;

public function traverseExpBidirNamedArg
  "Helper function to traverseExpBidirFunctionArgs. Traverses the expressions in
  a named function argument."
  input NamedArg inArg;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inExtra;
  output NamedArg outArg;
  output Argument outExtra;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;

protected
  Ident name;
  Exp value1,value2;
algorithm
  NAMEDARG(name, value1) := inArg;
  (value2, outExtra) := traverseExpBidir(value1, enterFunc, exitFunc, inExtra);
  outArg := if referenceEq(value1,value2) then inArg else NAMEDARG(name, value2);
end traverseExpBidirNamedArg;

public function traverseExpBidirIterator
  "Helper function to traverseExpBidirFunctionArgs. Traverses the expressions in
  an iterator."
  input ForIterator inIterator;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output ForIterator outIterator;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;

protected
  Ident name;
  Option<Exp> guardExp1,guardExp2,range1,range2;
algorithm
  ITERATOR(name=name, guardExp=guardExp1, range=range1) := inIterator;
  (guardExp2, outArg) := traverseExpOptBidir(guardExp1, enterFunc, exitFunc, inArg);
  (range2, outArg) := traverseExpOptBidir(range1, enterFunc, exitFunc, outArg);
  outIterator := if referenceEq(guardExp1,guardExp2) and referenceEq(range1,range2) then inIterator else ITERATOR(name, guardExp2, range2);
end traverseExpBidirIterator;

public function traverseMatchCase
  input Case inMatchCase;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output Case outMatchCase;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outMatchCase, outArg) := match(inMatchCase, enterFunc, exitFunc, inArg)
    local
      Argument arg;
      Exp pattern, result;
      Info info, resultInfo, pinfo;
      list<ElementItem> ldecls;
      ClassPart cp;
      Option<String> cmt;
      Option<Exp> patternGuard;

    case (CASE(pattern, patternGuard, pinfo, ldecls, cp, result, resultInfo, cmt, info), _, _, arg)
      equation
        (pattern, arg) = traverseExpBidir(pattern, enterFunc, exitFunc, arg);
        (patternGuard, arg) = traverseExpOptBidir(patternGuard, enterFunc, exitFunc, arg);
        (cp, arg) = traverseClassPartBidir(cp, enterFunc, exitFunc, arg);
        (result, arg) = traverseExpBidir(result, enterFunc, exitFunc, arg);
      then
        (CASE(pattern, patternGuard, pinfo, ldecls, cp, result, resultInfo, cmt, info), arg);

    case (ELSE(localDecls = ldecls, classPart = cp, result = result, resultInfo = resultInfo,
        comment = cmt, info = info), _, _, arg)
      equation
        (cp, arg) = traverseClassPartBidir(cp, enterFunc, exitFunc, arg);
        (result, arg) = traverseExpBidir(result, enterFunc, exitFunc, arg);
      then
        (ELSE(ldecls, cp, result, resultInfo, cmt, info), arg);

  end match;
end traverseMatchCase;

protected function traverseClassPartBidir
  input ClassPart cp;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output ClassPart outCp;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outCp, outArg) := match (cp,enterFunc,exitFunc,inArg)
    local
      list<AlgorithmItem> algs;
      list<EquationItem> eqs;
      Argument arg;
    case (ALGORITHMS(algs),_,_,arg)
      equation
        (algs, arg) = List.map2FoldCheckReferenceEq(algs, traverseAlgorithmItemBidir, enterFunc, exitFunc, arg);
      then (ALGORITHMS(algs),arg);
    case (EQUATIONS(eqs),_,_,arg)
      equation
        (eqs, arg) = List.map2FoldCheckReferenceEq(eqs, traverseEquationItemBidir, enterFunc, exitFunc, arg);
      then (EQUATIONS(eqs),arg);
  end match;
end traverseClassPartBidir;

protected function traverseEquationItemListBidir
  input list<EquationItem> inEquationItems;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output list<EquationItem> outEquationItems;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outEquationItems, outArg) := List.map2FoldCheckReferenceEq(inEquationItems, traverseEquationItemBidir, enterFunc, exitFunc, inArg);
end traverseEquationItemListBidir;

protected function traverseAlgorithmItemListBidir
  input list<AlgorithmItem> inAlgs;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output list<AlgorithmItem> outAlgs;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outAlgs, outArg) := List.map2FoldCheckReferenceEq(inAlgs, traverseAlgorithmItemBidir, enterFunc, exitFunc, inArg);
end traverseAlgorithmItemListBidir;

protected function traverseAlgorithmItemBidir
  input AlgorithmItem inAlgorithmItem;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output AlgorithmItem outAlgorithmItem;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outAlgorithmItem, outArg) := match(inAlgorithmItem, enterFunc, exitFunc, inArg)
    local
      Argument arg;
      Algorithm alg;
      Option<Comment> cmt;
      Info info;

    case (ALGORITHMITEM(algorithm_ = alg, comment = cmt, info = info), _, _, arg)
      equation
        (alg, arg) = traverseAlgorithmBidir(alg, enterFunc, exitFunc, arg);
      then
        (ALGORITHMITEM(alg, cmt, info), arg);

    case (ALGORITHMITEMCOMMENT(), _, _, _) then (inAlgorithmItem,inArg);
  end match;
end traverseAlgorithmItemBidir;

protected function traverseEquationItemBidir
  input EquationItem inEquationItem;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output EquationItem outEquationItem;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outEquationItem, outArg) := match(inEquationItem, enterFunc, exitFunc, inArg)
    local
      Argument arg;
      Equation eq;
      Option<Comment> cmt;
      Info info;

    case (EQUATIONITEM(equation_ = eq, comment = cmt, info = info), _, _, arg)
      equation
        (eq, arg) = traverseEquationBidir(eq, enterFunc, exitFunc, arg);
      then
        (EQUATIONITEM(eq, cmt, info), arg);

  end match;
end traverseEquationItemBidir;

public function traverseEquationBidir
  input Equation inEquation;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output Equation outEquation;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outEquation, outArg) := match(inEquation, enterFunc, exitFunc, inArg)
    local
      Argument arg;
      Exp e1, e2;
      list<EquationItem> eqil1, eqil2;
      list<tuple<Exp, list<EquationItem>>> else_branch;
      ComponentRef cref1, cref2;
      ForIterators iters;
      FunctionArgs func_args;
      EquationItem eq;

    case (EQ_IF(ifExp = e1, equationTrueItems = eqil1,
        elseIfBranches = else_branch, equationElseItems = eqil2), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (eqil1, arg) = traverseEquationItemListBidir(eqil1, enterFunc, exitFunc, arg);
        (else_branch,arg) = List.map2FoldCheckReferenceEq(else_branch, traverseEquationBidirElse, enterFunc, exitFunc, arg);
        (eqil2,arg) = traverseEquationItemListBidir(eqil2, enterFunc, exitFunc, arg);
      then
        (EQ_IF(e1, eqil1, else_branch, eqil2), arg);

    case (EQ_EQUALS(leftSide = e1, rightSide = e2), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (EQ_EQUALS(e1, e2), arg);
    case (EQ_PDE(leftSide = e1, rightSide = e2, domain = cref1), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
        cref1 = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
      then
        (EQ_PDE(e1, e2,cref1), arg);

    case (EQ_CONNECT(connector1 = cref1, connector2 = cref2), _, _, arg)
      equation
        (cref1, arg) = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
        (cref2, arg) = traverseExpBidirCref(cref2, enterFunc, exitFunc, arg);
      then
        (EQ_CONNECT(cref1, cref2), arg);

    case (EQ_FOR(iterators = iters, forEquations = eqil1), _, _, arg)
      equation
        (iters, arg) = List.map2FoldCheckReferenceEq(iters, traverseExpBidirIterator, enterFunc, exitFunc, arg);
        (eqil1, arg) = traverseEquationItemListBidir(eqil1, enterFunc, exitFunc, arg);
      then
        (EQ_FOR(iters, eqil1), arg);

    case (EQ_WHEN_E(whenExp = e1, whenEquations = eqil1, elseWhenEquations = else_branch), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (eqil1, arg) = traverseEquationItemListBidir(eqil1, enterFunc, exitFunc, arg);
        (else_branch, arg) = List.map2FoldCheckReferenceEq(else_branch, traverseEquationBidirElse, enterFunc, exitFunc, arg);
      then
        (EQ_WHEN_E(e1, eqil1, else_branch), arg);

    case (EQ_NORETCALL(functionName = cref1, functionArgs = func_args), _, _, arg)
      equation
        (cref1, arg) = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
        (func_args, arg) = traverseExpBidirFunctionArgs(func_args, enterFunc, exitFunc, arg);
      then
        (EQ_NORETCALL(cref1, func_args), arg);

    case (EQ_FAILURE(equ = eq), _, _, arg)
      equation
        (eq, arg) = traverseEquationItemBidir(eq, enterFunc, exitFunc, arg);
      then
        (EQ_FAILURE(eq), arg);

  end match;
end traverseEquationBidir;

protected function traverseEquationBidirElse
  input tuple<Exp, list<EquationItem>> inElse;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output tuple<Exp, list<EquationItem>> outElse;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
protected
  Exp e;
  list<EquationItem> eqil;
algorithm
  (e, eqil) := inElse;
  (e, arg) := traverseExpBidir(e, enterFunc, exitFunc, inArg);
  (eqil, arg) := traverseEquationItemListBidir(eqil, enterFunc, exitFunc, arg);
  outElse := (e, eqil);
end traverseEquationBidirElse;

protected function traverseAlgorithmBidirElse
  input tuple<Exp, list<AlgorithmItem>> inElse;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output tuple<Exp, list<AlgorithmItem>> outElse;
  output Argument arg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
protected
  Exp e;
  list<AlgorithmItem> algs;
algorithm
  (e, algs) := inElse;
  (e, arg) := traverseExpBidir(e, enterFunc, exitFunc, inArg);
  (algs, arg) := traverseAlgorithmItemListBidir(algs, enterFunc, exitFunc, arg);
  outElse := (e, algs);
end traverseAlgorithmBidirElse;

protected function traverseAlgorithmBidir
  input Algorithm inAlg;
  input FuncType enterFunc;
  input FuncType exitFunc;
  input Argument inArg;
  output Algorithm outAlg;
  output Argument outArg;

  partial function FuncType
    input Exp inExp;
    input Argument inArg;
    output Exp outExp;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outAlg, outArg) := match(inAlg, enterFunc, exitFunc, inArg)
    local
      Argument arg;
      Exp e1, e2;
      list<AlgorithmItem> algs1, algs2;
      list<tuple<Exp, list<AlgorithmItem>>> else_branch;
      ComponentRef cref1, cref2;
      ForIterators iters;
      FunctionArgs func_args;
      AlgorithmItem alg;

    case (ALG_ASSIGN(e1, e2), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (e2, arg) = traverseExpBidir(e2, enterFunc, exitFunc, arg);
      then
        (ALG_ASSIGN(e1, e2), arg);

    case (ALG_IF(e1, algs1, else_branch, algs2), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
        (else_branch, arg) = List.map2FoldCheckReferenceEq(else_branch, traverseAlgorithmBidirElse, enterFunc, exitFunc, arg);
        (algs2, arg) = traverseAlgorithmItemListBidir(algs2, enterFunc, exitFunc, arg);
      then (ALG_IF(e1, algs1, else_branch, algs2), arg);

    case (ALG_FOR(iters, algs1), _, _, arg)
      equation
        (iters, arg) = List.map2FoldCheckReferenceEq(iters, traverseExpBidirIterator, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then (ALG_FOR(iters, algs1), arg);

    case (ALG_PARFOR(iters, algs1), _, _, arg)
      equation
        (iters, arg) = List.map2FoldCheckReferenceEq(iters, traverseExpBidirIterator, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then (ALG_PARFOR(iters, algs1), arg);

    case (ALG_WHILE(e1, algs1), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then (ALG_WHILE(e1, algs1), arg);

    case (ALG_WHEN_A(e1, algs1, else_branch), _, _, arg)
      equation
        (e1, arg) = traverseExpBidir(e1, enterFunc, exitFunc, arg);
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
        (else_branch, arg) = List.map2FoldCheckReferenceEq(else_branch, traverseAlgorithmBidirElse, enterFunc, exitFunc, arg);
      then (ALG_WHEN_A(e1, algs1, else_branch), arg);

    case (ALG_NORETCALL(cref1, func_args), _, _, arg)
      equation
        (cref1, arg) = traverseExpBidirCref(cref1, enterFunc, exitFunc, arg);
        (func_args, arg) = traverseExpBidirFunctionArgs(func_args, enterFunc, exitFunc, arg);
      then
        (ALG_NORETCALL(cref1, func_args), arg);

    case (ALG_RETURN(), _, _, arg)
      then (inAlg, arg);

    case (ALG_BREAK(), _, _, arg)
      then (inAlg, arg);

    case (ALG_CONTINUE(), _, _, arg)
      then (inAlg, arg);

    case (ALG_FAILURE(algs1), _, _, arg)
      equation
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
      then
        (ALG_FAILURE(algs1), arg);

    case (ALG_TRY(algs1, algs2), _, _, arg)
      equation
        (algs1, arg) = traverseAlgorithmItemListBidir(algs1, enterFunc, exitFunc, arg);
        (algs2, arg) = traverseAlgorithmItemListBidir(algs2, enterFunc, exitFunc, arg);
      then
        (ALG_TRY(algs1, algs2), arg);

  end match;
end traverseAlgorithmBidir;

public function makeIdentPathFromString
  input String s;
  output Path p;
algorithm
  p := IDENT(s);
annotation(__OpenModelica_EarlyInline = true);
end makeIdentPathFromString;

public function makeQualifiedPathFromStrings
  input String s1;
  input String s2;
  output Path p;
algorithm
  p := QUALIFIED(s1,IDENT(s2));
annotation(__OpenModelica_EarlyInline = true);
end makeQualifiedPathFromStrings;

public function className "returns the class name of a Class as a Path"
  input Class cl;
  output Path name;
protected
  String id;
algorithm
  CLASS(name = id) := cl;
  name := IDENT(id);
end className;

public function isClassNamed
  input String inName;
  input Class inClass;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match inClass
    case CLASS() then inName == inClass.name;
    else false;
  end match;
end isClassNamed;

public function elementSpecName
  "The ElementSpec type contains the name of the element, and this function
   extracts this name."
  input ElementSpec inElementSpec;
  output Ident outIdent;
algorithm
  outIdent := match (inElementSpec)
    local Ident n;

    case CLASSDEF(class_ = CLASS(name = n)) then n;
    case COMPONENTS(components = {COMPONENTITEM(component = COMPONENT(name = n))}) then n;
  end match;
end elementSpecName;

public function isClassdef
  input Element inElement;
  output Boolean b;
algorithm
  b := match inElement
    case ELEMENT(specification=CLASSDEF()) then true;
    else false;
  end match;
end isClassdef;

public function printImportString
  "This function takes a Import and prints it as a flat-string."
  input Import imp;
  output String ostring;
algorithm
  ostring := match(imp)
    local
      Path path;
      String name;

    case(NAMED_IMPORT(name,_)) then name;
    case(QUAL_IMPORT(path))
      equation
        name = pathString(path);
      then name;

    case(UNQUAL_IMPORT(path))
      equation
        name = pathString(path);
      then name;
  end match;
end printImportString;

public function expString "returns the string of an expression if it is a string constant."
  input Exp exp;
  output String str;
algorithm
  STRING(str) := exp;
end expString;

public function expCref "returns the componentRef of an expression if matches."
  input Exp exp;
  output ComponentRef cr;
algorithm
  CREF(cr) := exp;
end expCref;

public function crefExp "returns the componentRef of an expression if matches."
 input ComponentRef cr;
 output Exp exp;
algorithm
  exp := CREF(cr);
annotation(__OpenModelica_EarlyInline = true);
end crefExp;

public function expComponentRefStr
  input Exp aexp;
  output String outString;
algorithm
  outString := printComponentRefStr(expCref(aexp));
end expComponentRefStr;

public function printComponentRefStr
  input ComponentRef cr;
  output String ostring;
algorithm
  ostring := match(cr)
    local
      String s1,s2;
      ComponentRef child;
    case(CREF_IDENT(s1,_)) then s1;
    case(CREF_QUAL(s1,_,child))
      equation
        s2 = printComponentRefStr(child);
        s1 = s1 + "." + s2;
      then s1;
    case(CREF_FULLYQUALIFIED(child))
      equation
        s2 = printComponentRefStr(child);
        s1 = "." + s2;
      then s1;
    case (ALLWILD()) then "__";
    case (WILD()) then "_";
  end match;
end printComponentRefStr;

public function pathEqual "Returns true if two paths are equal."
  input Path inPath1;
  input Path inPath2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inPath1, inPath2)
    local
      String id1,id2;
      Boolean res;
      Path path1,path2;
    // fully qual vs. path
    case (FULLYQUALIFIED(path1),path2) then pathEqual(path1,path2);
    // path vs. fully qual
    case (path1,FULLYQUALIFIED(path2)) then pathEqual(path1,path2);
    // ident vs. ident
    case (IDENT(id1),IDENT(id2))
      then stringEq(id1, id2);
    // qual ident vs. qual ident
    case (QUALIFIED(id1, path1),QUALIFIED(id2, path2))
      equation
        res = if stringEq(id1, id2) then pathEqual(path1, path2) else false;
      then res;
    // other return false
    else false;
  end match;
end pathEqual;

public function typeSpecEqual
  "Author BZ 2009-01
   Check whether two type specs are equal or not."
  input TypeSpec a,b;
  output Boolean ob;
algorithm
  ob := matchcontinue(a,b)
    local
      Path p1,p2;
      Option<ArrayDim> oad1,oad2;
      list<TypeSpec> lst1,lst2;
      Ident i1, i2;
      Integer pos1, pos2;

    // first try full equality
    case(TPATH(p1,oad1), TPATH(p2,oad2))
      equation
        true = pathEqual(p1,p2);
        true = optArrayDimEqual(oad1,oad2);
      then true;

    case(TCOMPLEX(p1,lst1,oad1),TCOMPLEX(p2,lst2,oad2))
      equation
        true = pathEqual(p1,p2);
        true = List.isEqualOnTrue(lst1,lst2,typeSpecEqual);
        true = optArrayDimEqual(oad1,oad2);
      then
        true;
    else false;
  end matchcontinue;
end typeSpecEqual;

public function optArrayDimEqual
  "Author BZ
   helper function for typeSpecEqual"
  input Option<ArrayDim> oad1,oad2;
  output Boolean b;
algorithm b:= matchcontinue(oad1,oad2)
  local
    list<Subscript> ad1,ad2;
  case(SOME(ad1),SOME(ad2))
    equation
    true = List.isEqualOnTrue(ad1,ad2,subscriptEqual);
    then true;
  case(NONE(),NONE()) then true;
  else false;
end matchcontinue;
end optArrayDimEqual;

public function typeSpecPathString "This function simply converts a Path to a string."
  input TypeSpec tp;
  output String s;
algorithm s := match(tp)
  local Path p;
  case(TCOMPLEX(path = p)) then pathString(p);
  case(TPATH(path = p)) then pathString(p);
end match;
end typeSpecPathString;

public function typeSpecPath
  "Converts a TypeSpec to Path"
  input TypeSpec tp;
  output Path op;
algorithm
  op := match(tp)
    local Path p;
    case(TCOMPLEX(path = p)) then p;
    case(TPATH(path = p)) then p;
  end match;
end typeSpecPath;

public function typeSpecDimensions
  "Returns the dimensions of a TypeSpec."
  input TypeSpec inTypeSpec;
  output ArrayDim outDimensions;
algorithm
  outDimensions := match(inTypeSpec)
    local
      ArrayDim dim;

    case TPATH(arrayDim = SOME(dim)) then dim;
    case TCOMPLEX(arrayDim = SOME(dim)) then dim;
    else {};

  end match;
end typeSpecDimensions;

public function pathString "This function simply converts a Path to a string."
  input Path path;
  input String delimiter=".";
  input Boolean usefq=true;
  input Boolean reverse=false;
  output String s;
protected
  Path p1,p2;
  Integer count=0, len=0, dlen=stringLength(delimiter);
  Boolean b;
algorithm
  // First, calculate the length of the string to be generated
  p1 :=  if usefq then path else makeNotFullyQualified(path);
  _ := match p1
    case IDENT()
      algorithm
        // Do not allocate memory if we're just going to copy the only identifier
        s := p1.name;
        return;
      then ();
    else ();
  end match;
  p2 := p1;
  b := true;
  while b loop
    (p2,len,count,b) := match p2
      case IDENT() then (p2,len+1,count+stringLength(p2.name),false);
      case QUALIFIED() then (p2.path,len+1,count+stringLength(p2.name),true);
      case FULLYQUALIFIED() then (p2.path,len+1,count,true);
    end match;
  end while;
  s := pathStringWork(p1, (len-1)*dlen+count, delimiter, dlen, reverse);
end pathString;

protected

function pathStringWork
  input Path inPath;
  input Integer len;
  input String delimiter;
  input Integer dlen;
  input Boolean reverse;
  output String s="";
protected
  Path p=inPath;
  Boolean b=true;
  Integer count=0;
  // Allocate a string of the exact required length
  System.StringAllocator sb=System.StringAllocator(len);
algorithm
  // Fill the string
  while b loop
    (p,count,b) := match p
      case IDENT()
        algorithm
          System.stringAllocatorStringCopy(sb, p.name, if reverse then len-count-stringLength(p.name) else count);
        then (p,count+stringLength(p.name),false);
      case QUALIFIED()
        algorithm
          System.stringAllocatorStringCopy(sb, p.name, if reverse then len-count-dlen-stringLength(p.name) else count);
          System.stringAllocatorStringCopy(sb, delimiter, if reverse then len-count-dlen else count+stringLength(p.name));
        then (p.path,count+stringLength(p.name)+dlen,true);
      case FULLYQUALIFIED()
        algorithm
          System.stringAllocatorStringCopy(sb, delimiter, if reverse then len-count-dlen else count);
        then (p.path,count+dlen,true);
    end match;
  end while;
  // Return the string
  s := System.stringAllocatorResult(sb,s);
end pathStringWork;

public

function pathStringNoQual = pathString(usefq=false);

function pathStringDefault
  input Path path;
  output String s = pathString(path);
end pathStringDefault;

public function classNameCompare
  input Class c1,c2;
  output Integer o;
algorithm
  o := stringCompare(c1.name, c2.name);
end classNameCompare;

public function classNameGreater
  input Class c1,c2;
  output Boolean b;
algorithm
  b := stringCompare(c1.name, c2.name) > 0;
end classNameGreater;

public function pathCompare
  input Path ip1;
  input Path ip2;
  output Integer o;
algorithm
  o := match (ip1,ip2)
    local
      Path p1,p2;
      String i1,i2;
    case (FULLYQUALIFIED(p1),FULLYQUALIFIED(p2)) then pathCompare(p1,p2);
    case (FULLYQUALIFIED(),_) then 1;
    case (_,FULLYQUALIFIED()) then -1;
    case (QUALIFIED(i1,p1),QUALIFIED(i2,p2))
      equation
        o = stringCompare(i1,i2);
        o = if o == 0 then pathCompare(p1, p2) else o;
      then o;
    case (QUALIFIED(),_) then 1;
    case (_,QUALIFIED()) then -1;
    case (IDENT(i1),IDENT(i2))
      then stringCompare(i1,i2);
  end match;
end pathCompare;

public function pathCompareNoQual
  input Path ip1;
  input Path ip2;
  output Integer o;
algorithm
  o := match (ip1,ip2)
    local
      Path p1,p2;
      String i1,i2;
    case (FULLYQUALIFIED(p1),p2) then pathCompareNoQual(p1,p2);
    case (p1,FULLYQUALIFIED(p2)) then pathCompareNoQual(p1,p2);
    case (QUALIFIED(i1,p1),QUALIFIED(i2,p2))
      equation
        o = stringCompare(i1,i2);
        o = if o == 0 then pathCompare(p1, p2) else o;
      then o;
    case (QUALIFIED(),_) then 1;
    case (_,QUALIFIED()) then -1;
    case (IDENT(i1),IDENT(i2))
      then stringCompare(i1,i2);
  end match;
end pathCompareNoQual;

public function pathHashMod "Hashes a path."
  input Path path;
  input Integer mod;
  output Integer hash;
algorithm
// hash := valueHashMod(path,mod);
// print(pathString(path) + " => " + intString(hash) + "\n");
// hash := stringHashDjb2Mod(pathString(path),mod);
// TODO: stringHashDjb2 is missing a default value for the seed; add this once we bootstrapped omc so we can use that function instead of our own hack
  hash := intAbs(intMod(pathHashModWork(path,5381),mod));
end pathHashMod;

public function pathHashModWork "Hashes a path."
  input Path path;
  input Integer acc;
  output Integer hash;
algorithm
  hash := match (path,acc)
    local
      Path p;
      String s;
      Integer i,i2;
    case (FULLYQUALIFIED(p),_) then pathHashModWork(p, acc*31 + 46 /* '.' */);
    case (QUALIFIED(s,p),_) equation i = stringHashDjb2(s); i2 = acc*31+46; then pathHashModWork(p, i2*31 + i);
    case (IDENT(s),_) equation i = stringHashDjb2(s); i2 = acc*31+46; then i2*31 + i;
  end match;
end pathHashModWork;

public function optPathString "Returns a path converted to string or an empty string if nothing exist"
  input Option<Path> inPathOption;
  output String outString;
algorithm
  outString := match (inPathOption)
    local
      Ident str;
      Path p;
    case (NONE()) then "";
    case (SOME(p))
      equation
        str = pathString(p);
      then
        str;
  end match;
end optPathString;

public function pathStringUnquoteReplaceDot
" Changes a path to string. Uses the input string as separator.
  If the separtor exists in the string then it is doubled (sep _ then
  a_b changes to a__b) before delimiting
  (Replaces dots with that separator). And also unquotes each ident.
"
  input Path inPath;
  input String repStr;
  output String outString;
protected
  list<String> strlst;
  String rep_rep;
algorithm
  rep_rep := repStr + repStr;
  strlst := pathToStringList(inPath);
  strlst := List.map2(strlst,System.stringReplace, repStr, rep_rep);
  strlst := List.map(strlst,System.unquoteIdentifier);
  outString := stringDelimitList(strlst,repStr);
end pathStringUnquoteReplaceDot;

public function stringPath
  "Converts a string into a qualified path."
  input String str;
  output Path qualifiedPath;

protected
  list<String> paths;
algorithm
  paths := Util.stringSplitAtChar(str, ".");
  qualifiedPath := stringListPath(paths);
end stringPath;

public function stringListPath
  "Converts a list of strings into a qualified path."
  input list<String> paths;
  output Path qualifiedPath;
algorithm
  qualifiedPath := matchcontinue(paths)
    local
      String str;
      list<String> rest_str;
      Path p;
    case ({}) then fail();
    case (str :: {}) then IDENT(str);
    case (str :: rest_str)
      equation
        p = stringListPath(rest_str);
      then
        QUALIFIED(str, p);
  end matchcontinue;
end stringListPath;

public function stringListPathReversed
  "Converts a list of strings into a qualified path, in reverse order.
   Ex: {'a', 'b', 'c'} => c.b.a"
  input list<String> inStrings;
  output Path outPath;
protected
  String id;
  list<String> rest_str;
  Path path;
algorithm
  id :: rest_str := inStrings;
  path := IDENT(id);
  outPath := stringListPathReversed2(rest_str, path);
end stringListPathReversed;

protected function stringListPathReversed2
  input list<String> inStrings;
  input Path inAccumPath;
  output Path outPath;
algorithm
  outPath := match(inStrings, inAccumPath)
    local
      String id;
      list<String> rest_str;
      Path path;

    case ({}, _) then inAccumPath;

    case (id :: rest_str, _)
      equation
        path = QUALIFIED(id, inAccumPath);
      then
        stringListPathReversed2(rest_str, path);

  end match;
end stringListPathReversed2;

public function pathTwoLastIdents "Returns the two last idents of a path"
  input Path inPath;
  output Path outTwoLast;
algorithm
  outTwoLast := match(inPath)
    local
      Path p;

    case QUALIFIED(path = IDENT()) then inPath;
    case QUALIFIED(path = p) then pathTwoLastIdents(p);
    case FULLYQUALIFIED(path = p) then pathTwoLastIdents(p);
  end match;
end pathTwoLastIdents;

public function pathLastIdent
  "Returns the last ident (after last dot) in a path"
  input Path inPath;
  output String outIdent;
algorithm
  outIdent := match(inPath)
    local
      Ident id;
      Path p;

    case QUALIFIED(path = p) then pathLastIdent(p);
    case IDENT(name = id) then id;
    case FULLYQUALIFIED(path = p) then pathLastIdent(p);
  end match;
end pathLastIdent;

public function pathLast
  "Returns the last ident (after last dot) in a path"
  input output Path path;
algorithm
  path := match path
    local
      Path p;
    case QUALIFIED(path = p) then pathLast(p);
    case IDENT() then path;
    case FULLYQUALIFIED(path = p) then pathLast(p);
  end match;
end pathLast;

public function pathFirstIdent "Returns the first ident (before first dot) in a path"
  input Path inPath;
  output Ident outIdent;
algorithm
  outIdent := match (inPath)
    local
      Ident n;
      Path p;

    case (FULLYQUALIFIED(path = p)) then pathFirstIdent(p);
    case (QUALIFIED(name = n)) then n;
    case (IDENT(name = n)) then n;
  end match;
end pathFirstIdent;

public function pathFirstPath
  input Path inPath;
  output Path outPath;
algorithm
  outPath := match inPath
    local
      Ident n;

    case IDENT() then inPath;
    case QUALIFIED(name = n) then IDENT(n);
    case FULLYQUALIFIED(path = outPath) then pathFirstPath(outPath);
  end match;
end pathFirstPath;

public function pathSecondIdent
  input Path inPath;
  output Ident outIdent;
algorithm
  outIdent := match(inPath)
    local
      Ident n;
      Path p;

    case QUALIFIED(path = QUALIFIED(name = n)) then n;
    case QUALIFIED(path = IDENT(name = n)) then n;
    case FULLYQUALIFIED(path = p) then pathSecondIdent(p);

  end match;
end pathSecondIdent;

public function pathRest
  input Path inPath;
  output Path outPath;
algorithm
  outPath := match inPath
    case QUALIFIED(path = outPath) then outPath;
    case FULLYQUALIFIED(path = outPath) then pathRest(outPath);
  end match;
end pathRest;

public function pathStripSamePrefix
  "strips the same prefix paths and returns the stripped path. e.g pathStripSamePrefix(P.M.A, P.M.B) => A"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath1, inPath2)
    local
      Ident ident1, ident2;
      Absyn.Path path1, path2;

    case (_, _)
      equation
        ident1 = pathFirstIdent(inPath1);
        ident2 = pathFirstIdent(inPath2);
        true = stringEq(ident1, ident2);
        path1 = stripFirst(inPath1);
        path2 = stripFirst(inPath2);
      then
        pathStripSamePrefix(path1, path2);

    else inPath1;
  end matchcontinue;
end pathStripSamePrefix;

public function pathPrefix
  "Returns the prefix of a path, i.e. this.is.a.path => this.is.a"
  input Path path;
  output Path prefix;
algorithm
  prefix := matchcontinue(path)
    local
      Path p;
      Ident n;

    case (FULLYQUALIFIED(path = p)) then pathPrefix(p);
    case (QUALIFIED(name = n, path = IDENT())) then IDENT(n);
    case (QUALIFIED(name = n, path = p))
      equation
        p = pathPrefix(p);
      then
        QUALIFIED(n, p);
  end matchcontinue;
end pathPrefix;

public function prefixPath
  "Prefixes a path with an identifier."
  input Ident prefix;
  input Path path;
  output Path outPath;
algorithm
  outPath := QUALIFIED(prefix, path);
end prefixPath;

public function prefixOptPath
  "Prefixes an optional path with an identifier."
  input Ident prefix;
  input Option<Path> optPath;
  output Option<Path> outPath;
algorithm
  outPath := match(prefix, optPath)
    local
      Path path;

    case (_, NONE()) then SOME(IDENT(prefix));
    case (_, SOME(path)) then SOME(QUALIFIED(prefix, path));
  end match;
end prefixOptPath;

public function suffixPath
  "Adds a suffix to a path. Ex:
     suffixPath(a.b.c, 'd') => a.b.c.d"
  input Path inPath;
  input Ident inSuffix;
  output Path outPath;
algorithm
  outPath := match(inPath, inSuffix)
    local
      Ident name;
      Path path;

    case (IDENT(name), _)
      then QUALIFIED(name, IDENT(inSuffix));

    case (QUALIFIED(name, path), _)
      equation
        path = suffixPath(path, inSuffix);
      then
        QUALIFIED(name, path);

    case (FULLYQUALIFIED(path), _)
      equation
        path = suffixPath(path, inSuffix);
      then
        FULLYQUALIFIED(path);

  end match;
end suffixPath;

public function pathSuffixOf "returns true if suffix_path is a suffix of path"
  input Path suffix_path;
  input Path path;
  output Boolean res;
algorithm
  res := matchcontinue(suffix_path,path)
  local Path p;
    case(_,_)
      equation
      true = pathEqual(suffix_path,path);
      then true;
    case(_,FULLYQUALIFIED(path = p))
      then pathSuffixOf(suffix_path,p);
    case(_,QUALIFIED(path = p))
      then pathSuffixOf(suffix_path,p);
    else false;
  end matchcontinue;
end pathSuffixOf;

public function pathSuffixOfr "returns true if suffix_path is a suffix of path"
  input Path path;
  input Path suffix_path;
  output Boolean res;
algorithm
  res := pathSuffixOf(suffix_path, path);
end pathSuffixOfr;

public function pathToStringList
  input Path path;
  output list<String> outPaths;
algorithm
  outPaths := listReverse(pathToStringListWork(path,{}));
end pathToStringList;

protected function pathToStringListWork
  input Path path;
  input list<String> acc;
  output list<String> outPaths;
algorithm
  outPaths := match(path,acc)
    local
      String n;
      Path p;
      list<String> strings;

    case (IDENT(name = n),_) then n::acc;
    case (FULLYQUALIFIED(path = p),_) then pathToStringListWork(p,acc);
    case (QUALIFIED(name = n,path = p),_)
      then pathToStringListWork(p,n::acc);
  end match;
end pathToStringListWork;

public function pathReplaceFirstIdent "
  Replaces the first part of a path with a replacement path:
  (a.b.c, d.e) => d.e.b.c
  (a, b.c.d) => b.c.d
"
  input Path path;
  input Path replPath;
  output Path outPath;
algorithm
  outPath := match(path,replPath)
    local
      Path p;
    // Should not be possible to replace FQ paths
    case (QUALIFIED(path = p), _) then joinPaths(replPath,p);
    case (IDENT(), _) then replPath;
  end match;
end pathReplaceFirstIdent;

public function addSubscriptsLast
  "Function for appending subscripts at end of last ident"
  input ComponentRef icr;
  input list<Subscript> i;
  output ComponentRef ocr;
algorithm
  ocr := match(icr,i)
    local
      list<Subscript> subs;
      String id;
      ComponentRef cr;

    case (CREF_IDENT(id,subs),_)
      then CREF_IDENT(id, listAppend(subs, i));

    case (CREF_QUAL(id,subs,cr),_)
      equation
        cr = addSubscriptsLast(cr,i);
      then
        CREF_QUAL(id,subs,cr);
    case (CREF_FULLYQUALIFIED(cr),_)
      equation
        cr = addSubscriptsLast(cr,i);
      then
        crefMakeFullyQualified(cr);
  end match;
end addSubscriptsLast;

public function crefReplaceFirstIdent "
  Replaces the first part of a cref with a replacement path:
  (a[4].b.c[3], d.e) => d.e[4].b.c[3]
  (a[3], b.c.d) => b.c.d[3]
"
  input ComponentRef icref;
  input Path replPath;
  output ComponentRef outCref;
algorithm
  outCref := match(icref,replPath)
    local
      list<Subscript> subs;
      ComponentRef cr,cref;
    case (CREF_FULLYQUALIFIED(componentRef = cr),_)
      equation
        cr = crefReplaceFirstIdent(cr,replPath);
      then crefMakeFullyQualified(cr);
    case (CREF_QUAL(componentRef = cr, subscripts = subs),_)
      equation
        cref = pathToCref(replPath);
        cref = addSubscriptsLast(cref,subs);
      then joinCrefs(cref,cr);
    case (CREF_IDENT(subscripts = subs),_)
      equation
        cref = pathToCref(replPath);
        cref = addSubscriptsLast(cref,subs);
      then cref;
  end match;
end crefReplaceFirstIdent;

public function pathPrefixOf
  "Returns true if prefixPath is a prefix of path, false otherwise."
  input Path prefixPath;
  input Path path;
  output Boolean isPrefix;
algorithm
  isPrefix := matchcontinue(prefixPath, path)
    local
      Path p, p2;
      String id, id2;
    case (FULLYQUALIFIED(p), p2) then pathPrefixOf(p, p2);
    case (p, FULLYQUALIFIED(p2)) then pathPrefixOf(p, p2);
    case (IDENT(id), IDENT(id2)) then stringEq(id, id2);
    case (IDENT(id), QUALIFIED(name = id2)) then stringEq(id, id2);
    case (QUALIFIED(id, p), QUALIFIED(id2, p2))
      equation
        true = stringEq(id, id2);
        true = pathPrefixOf(p, p2);
      then
        true;
    else false;
  end matchcontinue;
end pathPrefixOf;

public function crefPrefixOf
"Alternative names: crefIsPrefixOf, isPrefixOf, prefixOf
  Author: DH 2010-03

  Returns true if prefixCr is a prefix of cr, i.e., false otherwise.
  Subscripts are NOT checked."
  input ComponentRef prefixCr;
  input ComponentRef cr;
  output Boolean out;
algorithm
  out := matchcontinue(prefixCr, cr)
    case(_, _)
      equation
        true = crefEqualNoSubs(prefixCr, cr);
      then true;
    case(_, _)
      then crefPrefixOf(prefixCr, crefStripLast(cr));
    else false;
  end matchcontinue;
end crefPrefixOf;

public function removePrefix "removes the prefix_path from path, and returns the rest of path"
  input Path prefix_path;
  input Path path;
  output Path newPath;
algorithm
  newPath := match(prefix_path,path)
    local Path p,p2; Ident id1,id2;
    // fullyqual path
    case (p,FULLYQUALIFIED(p2)) then removePrefix(p,p2);
    // qual
    case (QUALIFIED(name=id1,path=p),QUALIFIED(name=id2,path=p2))
      equation
        true = stringEq(id1, id2);
      then
        removePrefix(p,p2);
    // ids
    case(IDENT(id1),QUALIFIED(name=id2,path=p2))
      equation
        true = stringEq(id1, id2);
      then p2;
  end match;
end removePrefix;

public function removePartialPrefix
  "Tries to remove a given prefix from a path with removePrefix. If it fails it
  removes the first identifier in the prefix and tries again, until it either
  succeeds or reaches the end of the prefix. Ex:
    removePartialPrefix(A.B.C, B.C.D.E) => D.E
  "
  input Path inPrefix;
  input Path inPath;
  output Path outPath;
algorithm
  outPath := matchcontinue(inPrefix, inPath)
    local
      Path p;

    case (_, _)
      equation
        p = removePrefix(inPrefix, inPath);
      then
        p;

    case (QUALIFIED(path = p), _)
      equation
        p = removePrefix(p, inPath);
      then
        p;

    case (FULLYQUALIFIED(path = p), _)
      equation
        p = removePartialPrefix(p, inPath);
      then
        p;

    else inPath;
  end matchcontinue;
end removePartialPrefix;

public function crefRemovePrefix
"
  function: crefRemovePrefix
  Alternative names: removePrefix
  Author: DH 2010-03

  If prefixCr is a prefix of cr, removes prefixCr from cr and returns the remaining reference,
  otherwise fails. Subscripts are NOT checked.
"
  input ComponentRef prefixCr;
  input ComponentRef cr;
  output ComponentRef out;
algorithm
  out := match(prefixCr, cr)
    local
      Ident prefixIdent, ident;
      ComponentRef prefixRestCr, restCr;
    // fqual
    case(CREF_FULLYQUALIFIED(componentRef = prefixRestCr), CREF_FULLYQUALIFIED(componentRef = restCr))
      then
        crefRemovePrefix(prefixRestCr, restCr);
    // qual
    case(CREF_QUAL(name = prefixIdent, componentRef = prefixRestCr), CREF_QUAL(name = ident, componentRef = restCr))
      equation
        true = stringEq(prefixIdent, ident);
      then
        crefRemovePrefix(prefixRestCr, restCr);
    // id vs. qual
    case(CREF_IDENT(name = prefixIdent), CREF_QUAL(name = ident, componentRef = restCr))
      equation
        true = stringEq(prefixIdent, ident);
      then restCr;
    // id vs. id
    case(CREF_IDENT(name = prefixIdent), CREF_IDENT(name = ident))
      equation
        true = stringEq(prefixIdent, ident);
      then CREF_IDENT("", {});
  end match;
end crefRemovePrefix;

public function pathContains
  "Author BZ,
   checks if one IDENT(..) is contained in path."
  input Path fullPath;
  input Path pathId;
  output Boolean b;
algorithm
  b := match (fullPath,pathId)
    local
      String str1,str2;
      Path qp;
      Boolean b1,b2;

    case(IDENT(str1),IDENT(str2)) then stringEq(str1,str2);

    case(QUALIFIED(str1,qp),IDENT(str2))
      equation
        b1 = stringEq(str1,str2);
        b2 = pathContains(qp,pathId);
        b1 = boolOr(b1,b2);
      then
        b1;

    case(FULLYQUALIFIED(qp),_) then pathContains(qp,pathId);
  end match;
end pathContains;

public function pathContainsString
  "Author OT,
   checks if Path contains the given string."
  input Path p1;
  input String str;
  output Boolean b;
algorithm
  b := match(p1,str)
    local
      String str1,searchStr;
      Path qp;
      Boolean b1,b2,b3;

    case(IDENT(str1),searchStr)
      equation
        b1 = System.stringFind(str1,searchStr) <> -1;
      then b1;

    case(QUALIFIED(str1,qp),searchStr)
      equation
        b1 = System.stringFind(str1, searchStr) <> -1;
        b2 = pathContainsString(qp, searchStr);
        b3 = boolOr(b1, b2);
      then
        b3;

    case(FULLYQUALIFIED(qp), searchStr) then pathContainsString(qp, searchStr);
  end match;
end pathContainsString;

public function pathContainedIn
  "This function checks if subPath is contained in path.
   If it is the complete path is returned. Otherwise the function fails.
   For example,
     pathContainedIn( C.D, A.B.C) => A.B.C.D
     pathContainedIn(C.D, A.B.C.D) => A.B.C.D
     pathContainedIn(A.B.C.D, A.B.C.D) => A.B.C.D
     pathContainedIn(B.C,A.B) => A.B.C"
  input Path subPath;
  input Path path;
  output Path completePath;
algorithm
  completePath := matchcontinue(subPath,path)
    local
      Ident ident;
      Path newPath,newSubPath;

    // A suffix, e.g. C.D in A.B.C.D
    case (_,_)
      equation
        true=pathSuffixOf(subPath,path);
      then path;

    // strip last ident of path and recursively check if suffix.
    case (_,_)
      equation
        ident = pathLastIdent(path);
        newPath = stripLast(path);
        newPath=pathContainedIn(subPath,newPath);
      then joinPaths(newPath,IDENT(ident));

    // strip last ident of subpath and recursively check if suffix.
    else
      equation
        ident = pathLastIdent(subPath);
        newSubPath = stripLast(subPath);
        newSubPath=pathContainedIn(newSubPath,path);
      then joinPaths(newSubPath,IDENT(ident));

  end matchcontinue;
end pathContainedIn;

public function getCrefsFromSubs
  "Author BZ 2009-08
   Function for getting ComponentRefs out from Subscripts"
  input list<Subscript> isubs;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<ComponentRef> crefs;
algorithm
  crefs := match(isubs,includeSubs,includeFunctions)
    local
      list<ComponentRef> crefs1;
      Exp exp;
      list<Subscript> subs;

    case({},_,_) then {};

    case(NOSUB()::subs,_,_) then getCrefsFromSubs(subs,includeSubs,includeFunctions);

    case(SUBSCRIPT(exp)::subs,_,_)
      equation
        crefs1 = getCrefsFromSubs(subs,includeSubs,includeFunctions);
        crefs = getCrefFromExp(exp,includeSubs,includeFunctions);
      then
        listAppend(crefs,crefs1);
  end match;
end getCrefsFromSubs;

public function getCrefFromExp
  "Returns a flattened list of the
   component references in an expression"
  input Exp inExp;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst := match (inExp,includeSubs,includeFunctions)
    local
      ComponentRef cr;
      list<ComponentRef> l1,l2,res;
      ComponentCondition e1,e2,e3;
      Operator op;
      list<tuple<ComponentCondition, ComponentCondition>> e4;
      FunctionArgs farg;
      list<ComponentCondition> expl;
      list<list<ComponentCondition>> expll;
      list<Subscript> subs;
      list<list<ComponentRef>> lstres1;
      list<list<ComponentRef>> crefll;

    case (INTEGER(),_,_) then {};
    case (REAL(),_,_) then {};
    case (STRING(),_,_) then {};
    case (BOOL(),_,_) then {};
    case (CREF(componentRef = ALLWILD()),_,_) then {};
    case (CREF(componentRef = WILD()),_,_) then {};
    case (CREF(componentRef = cr),false,_) then {cr};

    case (CREF(componentRef = (cr)),true,_)
      equation
        subs = getSubsFromCref(cr,includeSubs,includeFunctions);
        l1 = getCrefsFromSubs(subs,includeSubs,includeFunctions);
      then cr::l1;

    case (BINARY(exp1 = e1,exp2 = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (UNARY(exp = e1),_,_)
      equation
        res = getCrefFromExp(e1,includeSubs,includeFunctions);
      then
        res;

    case (LBINARY(exp1 = e1,exp2 = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (LUNARY(exp = e1),_,_)
      equation
        res = getCrefFromExp(e1,includeSubs,includeFunctions);
      then
        res;

    case (RELATION(exp1 = e1,exp2 = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    // TODO: Handle else if-branches.
    case (IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3),_,_)
      then List.flatten({
        getCrefFromExp(e1, includeSubs, includeFunctions),
        getCrefFromExp(e2, includeSubs, includeFunctions),
        getCrefFromExp(e3, includeSubs, includeFunctions)});

    case (CALL(function_ = cr, functionArgs = farg),_,_)
      equation
        res = getCrefFromFarg(farg,includeSubs,includeFunctions);
        res = if includeFunctions then cr::res else res;
      then
        res;
    case (PARTEVALFUNCTION(function_ = cr, functionArgs = farg),_,_)
      equation
        res = getCrefFromFarg(farg,includeSubs,includeFunctions);
        res = if includeFunctions then cr::res else res;
      then
        res;
    case (ARRAY(arrayExp = expl),_,_)
      equation
        lstres1 = List.map2(expl, getCrefFromExp, includeSubs, includeFunctions);
        res = List.flatten(lstres1);
      then
        res;
    case (MATRIX(matrix = expll),_,_)
      equation
        res = List.flatten(List.flatten(List.map2List(expll, getCrefFromExp, includeSubs, includeFunctions)));
      then
        res;
    case (RANGE(start = e1,step = SOME(e3),stop = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        l2 = listAppend(l1, l2);
        l1 = getCrefFromExp(e3,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;
    case (RANGE(start = e1,step = NONE(),stop = e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (END(),_,_) then {};

    case (TUPLE(expressions = expl),_,_)
      equation
        crefll = List.map2(expl,getCrefFromExp,includeSubs,includeFunctions);
        res = List.flatten(crefll);
      then
        res;

    case (CODE(),_,_) then {};

    case (AS(exp = e1),_,_) then getCrefFromExp(e1,includeSubs,includeFunctions);

    case (CONS(e1,e2),_,_)
      equation
        l1 = getCrefFromExp(e1,includeSubs,includeFunctions);
        l2 = getCrefFromExp(e2,includeSubs,includeFunctions);
        res = listAppend(l1, l2);
      then
        res;

    case (LIST(expl),_,_)
      equation
        crefll = List.map2(expl,getCrefFromExp,includeSubs,includeFunctions);
        res = List.flatten(crefll);
      then
        res;

    case (MATCHEXP(),_,_) then fail();

    case (DOT(),_,_)
      // inExp.index is only allowed to contain names to index the function call; not crefs that are evaluated in any way
      then getCrefFromExp(inExp.exp,includeSubs,includeFunctions);

    else
      equation
        Error.addInternalError(getInstanceName() + " failed " + Dump.printExpStr(inExp), sourceInfo());
      then fail();
  end match;
end getCrefFromExp;

public function getCrefFromFarg "Returns the flattened list of all component references
  present in a list of function arguments."
  input FunctionArgs inFunctionArgs;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst := match (inFunctionArgs,includeSubs,includeFunctions)
    local
      list<list<ComponentRef>> l1,l2;
      list<ComponentRef> fl1,fl2,fl3,res;
      list<ComponentCondition> expl;
      list<NamedArg> nargl;
      ForIterators iterators;
      Exp exp;

    case (FUNCTIONARGS(args = expl,argNames = nargl),_,_)
      equation
        l1 = List.map2(expl, getCrefFromExp, includeSubs, includeFunctions);
        fl1 = List.flatten(l1);
        l2 = List.map2(nargl, getCrefFromNarg, includeSubs, includeFunctions);
        fl2 = List.flatten(l2);
        res = listAppend(fl1, fl2);
      then
        res;

    case (FOR_ITER_FARG(exp,_,iterators),_,_)
      equation
        l1 = List.map2Option(List.map(iterators,iteratorRange),getCrefFromExp,includeSubs,includeFunctions);
        l2 = List.map2Option(List.map(iterators,iteratorGuard),getCrefFromExp,includeSubs,includeFunctions);
        fl1 = List.flatten(l1);
        fl2 = List.flatten(l2);
        fl3 = getCrefFromExp(exp,includeSubs,includeFunctions);
        res = listAppend(fl1,listAppend(fl2, fl3));
      then
        res;

  end match;
end getCrefFromFarg;

public function iteratorName
  input ForIterator iterator;
  output String name;
algorithm
  ITERATOR(name=name) := iterator;
end iteratorName;

public function iteratorRange
  input ForIterator iterator;
  output Option<Exp> range;
algorithm
  ITERATOR(range=range) := iterator;
end iteratorRange;

public function iteratorGuard
  input ForIterator iterator;
  output Option<Exp> guardExp;
algorithm
  ITERATOR(guardExp=guardExp) := iterator;
end iteratorGuard;

// stefan
public function getNamedFuncArgNamesAndValues
"returns the names from a list of NamedArgs as a string list"
  input list<NamedArg> inNamedArgList;
  output list<String> outStringList;
  output list<Exp> outExpList;
algorithm
  (outStringList,outExpList) := match ( inNamedArgList )
    local
      list<NamedArg> cdr;
      String s;
      Exp e;
      list<String> slst;
      list<Exp> elst;

    case ({})  then ({},{});
    case (NAMEDARG(argName=s,argValue=e) :: cdr)
      equation
        (slst,elst) = getNamedFuncArgNamesAndValues(cdr);
      then
        (s :: slst, e :: elst);
  end match;
end getNamedFuncArgNamesAndValues;

protected function getCrefFromNarg "Returns the flattened list of all component references
  present in a list of named function arguments."
  input NamedArg inNamedArg;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst := match (inNamedArg,includeSubs,includeFunctions)
    local
      list<ComponentRef> res;
      ComponentCondition exp;
    case (NAMEDARG(argValue = exp),_,_)
      equation
        res = getCrefFromExp(exp,includeSubs,includeFunctions);
      then
        res;
  end match;
end getCrefFromNarg;

public function joinPaths "This function joins two paths"
  input Path inPath1;
  input Path inPath2;
  output Path outPath;
algorithm
  outPath := match (inPath1,inPath2)
    local
      Ident str;
      Path p2,p_1,p;
    case (IDENT(name = str),p2) then QUALIFIED(str,p2);
    case (QUALIFIED(name = str,path = p),p2)
      equation
        p_1 = joinPaths(p, p2);
      then
        QUALIFIED(str,p_1);
    case(FULLYQUALIFIED(p),p2) then joinPaths(p,p2);
    case(p,FULLYQUALIFIED(p2)) then joinPaths(p,p2);
  end match;
end joinPaths;

public function joinPathsOpt "This function joins two paths when the first one might be NONE"
  input Option<Path> inPath1;
  input Path inPath2;
  output Path outPath;
algorithm
  outPath := match (inPath1,inPath2)
    local Path p;
    case (NONE(), _) then inPath2;
    case (SOME(p), _) then joinPaths(p, inPath2);
  end match;
end joinPathsOpt;

public function joinPathsOptSuffix
  input Path inPath1;
  input Option<Path> inPath2;
  output Path outPath;
algorithm
  outPath := match(inPath1, inPath2)
    local
      Path p;

    case (_, SOME(p)) then joinPaths(inPath1, p);
    else inPath1;

  end match;
end joinPathsOptSuffix;

public function selectPathsOpt "This function selects the second path when the first one
  is NONE() otherwise it will select the first one."
  input Option<Path> inPath1;
  input Path inPath2;
  output Path outPath;
algorithm
  outPath := match (inPath1,inPath2)
    local
      Path p;
    case (NONE(), p) then p;
    case (SOME(p),_) then p;
  end match;
end selectPathsOpt;

public function pathAppendList "author Lucian
  This function joins a path list"
  input list<Path> inPathLst;
  output Path outPath;
algorithm
  outPath := match (inPathLst)
    local
      Path path,res_path,first;
      list<Path> rest;
    case ({}) then IDENT("");
    case ((path :: {})) then path;
    case ((first :: rest))
      equation
        path = pathAppendList(rest);
        res_path = joinPaths(first, path);
      then
        res_path;
  end match;
end pathAppendList;

public function stripLast "Returns the path given as argument to
  the function minus the last ident."
  input Path inPath;
  output Path outPath;
algorithm
  outPath := match (inPath)
    local
      Ident str;
      Path p;

    case QUALIFIED(name = str, path = IDENT())
      then IDENT(str);

    case QUALIFIED(name = str, path = p)
      equation
        p = stripLast(p);
      then
        QUALIFIED(str, p);

    case FULLYQUALIFIED(p)
      equation
        p = stripLast(p);
      then
        FULLYQUALIFIED(p);

  end match;
end stripLast;

public function stripLastOpt
  input Path inPath;
  output Option<Path> outPath;
algorithm
  outPath := match(inPath)
    local
      Path p;

    case IDENT() then NONE();

    else
      equation
        p = stripLast(inPath);
      then
        SOME(p);

  end match;
end stripLastOpt;

public function crefStripLast "Returns the path given as argument to
  the function minus the last ident."
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := match (inCref)
    local
      Ident str;
      ComponentRef c_1, c;
      list<Subscript> subs;

    case (CREF_IDENT()) then fail();
    case (CREF_QUAL(name = str,subscripts = subs, componentRef = CREF_IDENT())) then CREF_IDENT(str,subs);
    case (CREF_QUAL(name = str,subscripts = subs,componentRef = c))
      equation
        c_1 = crefStripLast(c);
      then
        CREF_QUAL(str,subs,c_1);
    case (CREF_FULLYQUALIFIED(componentRef = c))
      equation
        c_1 = crefStripLast(c);
      then
        crefMakeFullyQualified(c_1);
  end match;
end crefStripLast;

public function splitQualAndIdentPath "
Author BZ 2008-04
Function for splitting Absynpath into two parts,
qualified part, and ident part (all_but_last, last);
"
  input Path inPath;
  output Path outPath1;
  output Path outPath2;
algorithm (outPath1,outPath2) := match(inPath)
  local
    Path qPath,curPath,identPath;
    String s1,s2;

  case (QUALIFIED(name = s1, path = IDENT(name = s2)))
    then (IDENT(s1), IDENT(s2));

  case (QUALIFIED(name = s1, path = qPath))
    equation
      (curPath, identPath) = splitQualAndIdentPath(qPath);
    then
      (QUALIFIED(s1, curPath), identPath);

  case (FULLYQUALIFIED(qPath))
    equation
      (curPath, identPath) = splitQualAndIdentPath(qPath);
    then
      (curPath, identPath);
  end match;
end splitQualAndIdentPath;

public function stripFirst "Returns the path given as argument
  to the function minus the first ident."
  input Path inPath;
  output Path outPath;
algorithm
  outPath:=
  match (inPath)
    local
      Path p;
    case (QUALIFIED(path = p)) then p;
    case(FULLYQUALIFIED(p)) then stripFirst(p);
  end match;
end stripFirst;

public function crefToPath "This function converts a ComponentRef to a Path, if possible.
  If the component reference contains subscripts, it will silently fail."
  input ComponentRef inComponentRef;
  output Path outPath;
algorithm
  outPath:=
  match (inComponentRef)
    local
      Ident i;
      Path p;
      ComponentRef c;
    case CREF_IDENT(name = i,subscripts = {}) then IDENT(i);
    case CREF_QUAL(name = i,subscripts = {},componentRef = c)
      equation
        p = crefToPath(c);
      then
        QUALIFIED(i,p);
    case CREF_FULLYQUALIFIED(componentRef = c)
      equation
        p = crefToPath(c);
      then
        FULLYQUALIFIED(p);
  end match;
end crefToPath;

public function elementSpecToPath "This function converts a ElementSpec to a Path, if possible.
  If the ElementSpec is not EXTENDS, it will silently fail."
  input ElementSpec inElementSpec;
  output Path outPath;
algorithm
  outPath:= match (inElementSpec)
    local
      Path p;
    case EXTENDS(path = p) then p;
  end match;
end elementSpecToPath;

public function crefToPathIgnoreSubs
  "Converts a ComponentRef to a Path, ignoring any subscripts."
  input ComponentRef inComponentRef;
  output Path outPath;
algorithm
  outPath := match(inComponentRef)
    local
      Ident i;
      Path p;
      ComponentRef c;

    case CREF_IDENT(name = i) then IDENT(i);

    case CREF_QUAL(name = i, componentRef = c)
      equation
        p = crefToPathIgnoreSubs(c);
      then
        QUALIFIED(i, p);

    case CREF_FULLYQUALIFIED(componentRef = c)
      equation
        p = crefToPathIgnoreSubs(c);
      then
        FULLYQUALIFIED(p);
  end match;
end crefToPathIgnoreSubs;

public function pathToCref "This function converts a Path to a ComponentRef."
  input Path inPath;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inPath)
    local
      Ident i;
      ComponentRef c;
      Path p;
    case IDENT(name = i) then CREF_IDENT(i,{});
    case QUALIFIED(name = i,path = p)
      equation
        c = pathToCref(p);
      then
        CREF_QUAL(i,{},c);
    case(FULLYQUALIFIED(p))
      equation
        c = pathToCref(p);
      then crefMakeFullyQualified(c);
  end match;
end pathToCref;

public function pathToCrefWithSubs
  "This function converts a Path to a ComponentRef, and applies the given
  subscripts to the last identifier."
  input Path inPath;
  input list<Subscript> inSubs;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inPath, inSubs)
    local
      Ident i;
      ComponentRef c;
      Path p;

    case (IDENT(name = i), _) then CREF_IDENT(i, inSubs);

    case (QUALIFIED(name = i, path = p), _)
      equation
        c = pathToCrefWithSubs(p, inSubs);
      then
        CREF_QUAL(i, {}, c);

    case (FULLYQUALIFIED(p), _)
      equation
        c = pathToCrefWithSubs(p, inSubs);
      then
        crefMakeFullyQualified(c);
  end match;
end pathToCrefWithSubs;

public function crefLastIdent
  "Returns the last identifier in a component reference."
  input ComponentRef inComponentRef;
  output Ident outIdent;
algorithm
  outIdent := match(inComponentRef)
    local
      ComponentRef cref;
      Ident id;

    case CREF_IDENT(name = id) then id;
    case CREF_QUAL(componentRef = cref) then crefLastIdent(cref);
    case CREF_FULLYQUALIFIED(componentRef = cref) then crefLastIdent(cref);
  end match;
end crefLastIdent;

public function crefFirstIdentNoSubs
  "Returns the basename of the component reference, but fails if it encounters
  any subscripts."
  input ComponentRef inCref;
  output Ident outIdent;
algorithm
  outIdent := match(inCref)
    local
      Ident id;
      ComponentRef cr;
    case CREF_IDENT(name = id, subscripts = {}) then id;
    case CREF_QUAL(name = id, subscripts = {}) then id;
    case CREF_FULLYQUALIFIED(componentRef = cr) then crefFirstIdentNoSubs(cr);
  end match;
end crefFirstIdentNoSubs;

public function crefIsIdent
  "Returns true if the component reference is a simple identifier, otherwise false."
  input ComponentRef inComponentRef;
  output Boolean outIsIdent;
algorithm
  outIsIdent := match(inComponentRef)
    case CREF_IDENT() then true;
    else false;
  end match;
end crefIsIdent;

public function crefIsQual
  "Returns true if the component reference is a qualified identifier, otherwise false."
  input ComponentRef inComponentRef;
  output Boolean outIsQual;
algorithm
  outIsQual := match(inComponentRef)
    case CREF_QUAL() then true;
    case CREF_FULLYQUALIFIED() then true;
    else false;
  end match;
end crefIsQual;

public function crefLastSubs "Return the last subscripts of an ComponentRef"
  input ComponentRef inComponentRef;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  match (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,res;
      ComponentRef cr;
    case (CREF_IDENT(subscripts= subs)) then subs;
    case (CREF_QUAL(componentRef = cr))
      equation
        res = crefLastSubs(cr);
      then
        res;
    case (CREF_FULLYQUALIFIED(componentRef = cr))
      equation
        res = crefLastSubs(cr);
      then
        res;
  end match;
end crefLastSubs;

public function crefSetLastSubs
  input ComponentRef inCref;
  input list<Subscript> inSubscripts;
  output ComponentRef outCref = inCref;
algorithm
  outCref := match outCref
    case CREF_IDENT()
      algorithm
        outCref.subscripts := inSubscripts;
      then
        outCref;

    case CREF_QUAL()
      algorithm
        outCref.componentRef := crefSetLastSubs(outCref.componentRef, inSubscripts);
      then
        outCref;

    case CREF_FULLYQUALIFIED()
      algorithm
        outCref.componentRef := crefSetLastSubs(outCref.componentRef, inSubscripts);
      then
        outCref;

  end match;
end crefSetLastSubs;

public function crefHasSubscripts "This function finds if a cref has subscripts"
  input ComponentRef cref;
  output Boolean hasSubscripts;
algorithm
  hasSubscripts := match cref
    case CREF_IDENT() then not listEmpty(cref.subscripts);
    case CREF_QUAL(subscripts = {}) then crefHasSubscripts(cref.componentRef);
    case CREF_FULLYQUALIFIED() then crefHasSubscripts(cref.componentRef);
    case WILD() then false;
    case ALLWILD() then false;
    else true;
  end match;
end crefHasSubscripts;

public function getSubsFromCref "
Author: BZ, 2009-09
 Extract subscripts of crefs."
  input ComponentRef cr;
  input Boolean includeSubs "include crefs from array subscripts";
  input Boolean includeFunctions "note that if you say includeSubs = false then you won't get the functions from array subscripts";
  output list<Subscript> subscripts;
algorithm
  subscripts := match(cr,includeSubs,includeFunctions)
    local
      list<Subscript> subs2;
      ComponentRef child;

    case(CREF_IDENT(_,subs2), _, _) then subs2;

    case(CREF_QUAL(_,subs2,child), _, _)
      equation
        subscripts = getSubsFromCref(child, includeSubs, includeFunctions);
        subscripts = List.unionOnTrue(subscripts,subs2, subscriptEqual);
      then
        subscripts;

    case(CREF_FULLYQUALIFIED(child), _, _)
      equation
        subscripts = getSubsFromCref(child, includeSubs, includeFunctions);
      then
        subscripts;
  end match;
end getSubsFromCref;

// stefan
public function crefGetLastIdent
"Gets the last ident in a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      ComponentRef cref,cref_1;
      Ident id;
      list<Subscript> subs;
    case(CREF_IDENT(id,subs)) then CREF_IDENT(id,subs);
    case(CREF_QUAL(_,_,cref))
      equation
        cref_1 = crefGetLastIdent(cref);
      then
        cref_1;
    case(CREF_FULLYQUALIFIED(cref))
      equation
        cref_1 = crefGetLastIdent(cref);
      then
        cref_1;
  end match;
end crefGetLastIdent;

public function crefStripLastSubs "Strips the last subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,s;
      ComponentRef cr_1,cr;
    case (CREF_IDENT(name = id)) then CREF_IDENT(id,{});
    case (CREF_QUAL(name= id,subscripts= s,componentRef = cr))
      equation
        cr_1 = crefStripLastSubs(cr);
      then
        CREF_QUAL(id,s,cr_1);
    case (CREF_FULLYQUALIFIED(componentRef = cr))
      equation
        cr_1 = crefStripLastSubs(cr);
      then
        crefMakeFullyQualified(cr_1);
  end match;
end crefStripLastSubs;

public function joinCrefs "This function joins two ComponentRefs."
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inComponentRef1,inComponentRef2)
    local
      Ident id;
      list<Subscript> sub;
      ComponentRef cr2,cr_1,cr;
    case (CREF_IDENT(name = id,subscripts = sub),cr2)
      equation
        failure(CREF_FULLYQUALIFIED() = cr2);
      then CREF_QUAL(id,sub,cr2);
    case (CREF_QUAL(name = id,subscripts = sub,componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        CREF_QUAL(id,sub,cr_1);
    case (CREF_FULLYQUALIFIED(componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        crefMakeFullyQualified(cr_1);
  end match;
end joinCrefs;

public function crefFirstIdent "Returns first ident from a ComponentRef"
  input ComponentRef inCref;
  output Ident outIdent;
algorithm
  outIdent := match inCref
    case CREF_IDENT() then inCref.name;
    case CREF_QUAL() then inCref.name;
    case CREF_FULLYQUALIFIED() then crefFirstIdent(inCref.componentRef);
  end match;
end crefFirstIdent;

public function crefSecondIdent
  input ComponentRef cref;
  output Ident ident;
algorithm
  ident := match cref
    case CREF_QUAL() then crefFirstIdent(cref.componentRef);
    case CREF_FULLYQUALIFIED() then crefSecondIdent(cref.componentRef);
  end match;
end crefSecondIdent;

public function crefFirstCref
  "Returns the first part of a cref."
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := match inCref
    case CREF_QUAL() then CREF_IDENT(inCref.name, inCref.subscripts);
    case CREF_FULLYQUALIFIED() then crefFirstCref(inCref.componentRef);
    else inCref;
  end match;
end crefFirstCref;

public function crefStripFirst "Strip the first ident from a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inComponentRef)
    local ComponentRef cr;
    case CREF_QUAL(componentRef = cr) then cr;
    case CREF_FULLYQUALIFIED(componentRef = cr) then crefStripFirst(cr);
  end match;
end crefStripFirst;

public function crefIsFullyQualified
  input ComponentRef inCref;
  output Boolean outIsFullyQualified;
algorithm
  outIsFullyQualified := match inCref
    case CREF_FULLYQUALIFIED() then true;
    else false;
  end match;
end crefIsFullyQualified;

public function crefMakeFullyQualified
  "Makes a component reference fully qualified unless it already is."
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inComponentRef)
    case CREF_FULLYQUALIFIED() then inComponentRef;
    else CREF_FULLYQUALIFIED(inComponentRef);
  end match;
end crefMakeFullyQualified;

public function restrString "Maps a class restriction to the corresponding string for printing"
  input Restriction inRestriction;
  output String outString;
algorithm
  outString:=
  match (inRestriction)
    case R_CLASS() then "CLASS";
    case R_OPTIMIZATION() then "OPTIMIZATION";
    case R_MODEL() then "MODEL";
    case R_RECORD() then "RECORD";
    case R_BLOCK() then "BLOCK";
    case R_CONNECTOR() then "CONNECTOR";
    case R_EXP_CONNECTOR() then "EXPANDABLE CONNECTOR";
    case R_TYPE() then "TYPE";
    case R_PACKAGE() then "PACKAGE";
    case R_FUNCTION(FR_NORMAL_FUNCTION(PURE())) then "PURE FUNCTION";
    case R_FUNCTION(FR_NORMAL_FUNCTION(IMPURE())) then "IMPURE FUNCTION";
    case R_FUNCTION(FR_NORMAL_FUNCTION(NO_PURITY())) then "FUNCTION";
    case R_FUNCTION(FR_OPERATOR_FUNCTION()) then "OPERATOR FUNCTION";
    case R_PREDEFINED_INTEGER() then "PREDEFINED_INT";
    case R_PREDEFINED_REAL() then "PREDEFINED_REAL";
    case R_PREDEFINED_STRING() then "PREDEFINED_STRING";
    case R_PREDEFINED_BOOLEAN() then "PREDEFINED_BOOL";
    // BTH
    case R_PREDEFINED_CLOCK() then "PREDEFINED_CLOCK";

    /* MetaModelica restriction */
    case R_UNIONTYPE() then "UNIONTYPE";
    else "* Unknown restriction *";
  end match;
end restrString;

public function lastClassname "Returns the path (=name) of the last class in a program"
  input Program inProgram;
  output Path outPath;
protected
  list<Class> lst;
  Ident id;
algorithm
  PROGRAM(classes = lst) := inProgram;
  CLASS(name = id) := List.last(lst);
  outPath := IDENT(id);
end lastClassname;

public function classFilename
  "Retrieves the filename where the class is stored."
  input Class inClass;
  output String outFilename;
algorithm
  CLASS(info = SOURCEINFO(fileName = outFilename)) := inClass;
end classFilename;

public function setClassFilename "Sets the filename where the class is stored."
  input Class inClass;
  input String fileName;
  output Class outClass;
algorithm
  outClass := match inClass
    local
      SourceInfo info;
      Class cl;
    case cl as CLASS(info=info as SOURCEINFO())
      equation
        info.fileName = fileName;
        cl.info = info;
      then cl;
  end match;
end setClassFilename;

public function setClassName "author: BZ
  Sets the name of the class"
  input Class inClass;
  input String newName;
  output Class outClass = inClass;
algorithm
  outClass := match outClass
    case CLASS()
      algorithm
        outClass.name := newName;
      then
        outClass;
  end match;
end setClassName;

public function setClassBody
  input Class inClass;
  input ClassDef inBody;
  output Class outClass = inClass;
algorithm
  outClass := match outClass
    case CLASS()
      algorithm
        outClass.body := inBody;
      then
        outClass;
  end match;
end setClassBody;

public function crefEqual " Checks if the name of a ComponentRef is
 equal to the name of another ComponentRef, including subscripts.
 See also crefEqualNoSubs."
  input ComponentRef iCr1;
  input ComponentRef iCr2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (iCr1,iCr2)
    local
      Ident id,id2;
      list<Subscript> ss1,ss2;
      ComponentRef cr1,cr2;

    case (CREF_IDENT(name = id,subscripts=ss1),CREF_IDENT(name = id2,subscripts = ss2))
      equation
        true = stringEq(id, id2);
        true = subscriptsEqual(ss1,ss2);
      then
        true;

    case (CREF_QUAL(name = id,subscripts = ss1, componentRef = cr1),CREF_QUAL(name = id2,subscripts = ss2, componentRef = cr2))
      equation
        true = stringEq(id, id2);
        true = subscriptsEqual(ss1,ss2);
        true = crefEqual(cr1, cr2);
      then
        true;

    case (CREF_FULLYQUALIFIED(componentRef = cr1),CREF_FULLYQUALIFIED(componentRef = cr2))
      then
        crefEqual(cr1, cr2);

    else false;
  end matchcontinue;
end crefEqual;

public function crefFirstEqual
  "@author: adrpo
   a.b, a -> true
   b.c, a -> false"
  input ComponentRef iCr1;
  input ComponentRef iCr2;
  output Boolean outBoolean;
algorithm
  outBoolean := stringEq(crefFirstIdent(iCr1),crefFirstIdent(iCr2));
end crefFirstEqual;

public function subscriptEqual
  input Subscript inSubscript1;
  input Subscript inSubscript2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inSubscript1, inSubscript2)
    local
      Exp e1, e2;

    case (NOSUB(), NOSUB()) then true;
    case (SUBSCRIPT(e1), SUBSCRIPT(e2)) then expEqual(e1, e2);
    else false;
  end match;
end subscriptEqual;

public function subscriptsEqual
  "Checks if two subscript lists are equal."
  input list<Subscript> inSubList1;
  input list<Subscript> inSubList2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := List.isEqualOnTrue(inSubList1, inSubList2, subscriptEqual);
end subscriptsEqual;

public function crefEqualNoSubs
  "Checks if the name of a ComponentRef is equal to the name
   of another ComponentRef without checking subscripts.
   See also crefEqual."
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (cr1,cr2)
    local
      ComponentRef rest1,rest2;
      Ident id,id2;
    case (CREF_IDENT(name = id),CREF_IDENT(name = id2))
      equation
        true = stringEq(id, id2);
      then
        true;
    case (CREF_QUAL(name = id,componentRef = rest1),CREF_QUAL(name = id2,componentRef = rest2))
      equation
        true = stringEq(id, id2);
        true = crefEqualNoSubs(rest1, rest2);
      then
        true;
    case (CREF_FULLYQUALIFIED(componentRef = rest1),CREF_FULLYQUALIFIED(componentRef = rest2))
      then crefEqualNoSubs(rest1, rest2);
    else false;
  end matchcontinue;
end crefEqualNoSubs;

public function isPackageRestriction "checks if the provided parameter is a package or not"
  input Restriction inRestriction;
  output Boolean outIsPackage;
algorithm
  outIsPackage := match(inRestriction)
    case R_PACKAGE() then true;
    else false;
  end match;
end isPackageRestriction;

public function isFunctionRestriction "checks if restriction is a function or not"
  input Restriction inRestriction;
  output Boolean outIsFunction;
algorithm
  outIsFunction := match(inRestriction)
    case R_FUNCTION() then true;
    else false;
  end match;
end isFunctionRestriction;

public function expEqual "Returns true if two expressions are equal"
  input Exp exp1;
  input Exp exp2;
  output Boolean equal;
algorithm
  equal := matchcontinue(exp1,exp2)
    local
      Boolean b;
      Exp x, y;
      Integer i;
      String r;

    // real vs. integer
    case (INTEGER(i), REAL(r))
      equation
        b = realEq(intReal(i), System.stringReal(r));
      then b;

    case (REAL(r), INTEGER(i))
      equation
        b = realEq(intReal(i), System.stringReal(r));
      then b;

    // anything else, exact match!
    case (x, y) then valueEq(x,y);
  end matchcontinue;
end expEqual;

public function eachEqual "Returns true if two each attributes are equal"
  input Each each1;
  input Each each2;
  output Boolean equal;
algorithm
  equal := match(each1, each2)
    case(NON_EACH(), NON_EACH()) then true;
    case(EACH(), EACH()) then true;
    else false;
  end match;
end eachEqual;

protected function functionArgsEqual "Returns true if two FunctionArgs are equal"
  input FunctionArgs args1;
  input FunctionArgs args2;
  output Boolean equal;
algorithm
  equal := match(args1,args2)
    local
      list<Exp> expl1,expl2;

    case (FUNCTIONARGS(args = expl1), FUNCTIONARGS(args = expl2))
      then List.isEqualOnTrue(expl1, expl2, expEqual);

    else false;
  end match;
end functionArgsEqual;

public function getClassName "author: adrpo
  gets the name of the class."
  input Class inClass;
  output String outName;
algorithm
  CLASS(name=outName) := inClass;
end getClassName;

public type IteratorIndexedCref = tuple<ComponentRef, Integer>;

public function findIteratorIndexedCrefs
  "Find all crefs in an expression which are subscripted with the given
   iterator, and return a list of cref-Integer tuples, where the cref is the
   index of the subscript."
  input Exp inExp;
  input String inIterator;
  input list<IteratorIndexedCref> inCrefs = {};
  output list<IteratorIndexedCref> outCrefs;
algorithm
  (_, outCrefs) := traverseExp(inExp,
    function findIteratorIndexedCrefs_traverser(inIterator = inIterator), {});
  outCrefs := List.fold(outCrefs,
    function List.unionEltOnTrue(inCompFunc = iteratorIndexedCrefsEqual), inCrefs);
end findIteratorIndexedCrefs;

protected function findIteratorIndexedCrefs_traverser
  "Traversal function used by deduceReductionIterationRange. Used to find crefs
   which are subscripted by a given iterator."
  input Exp inExp;
  input list<IteratorIndexedCref> inCrefs;
  input String inIterator;
  output Exp outExp = inExp;
  output list<IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := match inExp
    local
      ComponentRef cref;

    case CREF(componentRef = cref)
      then getIteratorIndexedCrefs(cref, inIterator, inCrefs);

    else inCrefs;
  end match;
end findIteratorIndexedCrefs_traverser;

protected function iteratorIndexedCrefsEqual
  "Checks whether two cref-index pairs are equal."
  input IteratorIndexedCref inCref1;
  input IteratorIndexedCref inCref2;
  output Boolean outEqual;
protected
  ComponentRef cr1, cr2;
  Integer idx1, idx2;
algorithm
  (cr1, idx1) := inCref1;
  (cr2, idx2) := inCref2;
  outEqual := idx1 == idx2 and crefEqual(cr1, cr2);
end iteratorIndexedCrefsEqual;

protected function getIteratorIndexedCrefs
  "Checks if the given component reference is subscripted by the given iterator.
   Only cases where a subscript consists of only the iterator is considered.
   If so it adds a cref-index pair to the list, where the cref is the subscripted
   cref without subscripts, and the index is the subscripted dimension. E.g. for
   iterator i:
     a[i] => (a, 1), b[1, i] => (b, 2), c[i+1] => (), d[2].e[i] => (d[2].e, 1)"
  input ComponentRef inCref;
  input String inIterator;
  input list<IteratorIndexedCref> inCrefs;
  output list<IteratorIndexedCref> outCrefs = inCrefs;
protected
  list<tuple<ComponentRef, Integer>> crefs;
algorithm
  outCrefs := match inCref
    local
      list<Subscript> subs;
      Integer idx;
      String name, id;
      ComponentRef cref;

    case CREF_IDENT(name = id, subscripts = subs)
      algorithm
        // For each subscript, check if the subscript consists of only the
        // iterator we're looking for.
        idx := 1;
        for sub in subs loop
          _ := match sub
            case SUBSCRIPT(subscript = CREF(componentRef =
                CREF_IDENT(name = name, subscripts = {})))
              algorithm
                if name == inIterator then
                  outCrefs := (CREF_IDENT(id, {}), idx) :: outCrefs;
                end if;
              then
                ();

            else ();
          end match;

          idx := idx + 1;
        end for;
      then
        outCrefs;

    case CREF_QUAL(name = id, subscripts = subs, componentRef = cref)
      algorithm
        crefs := getIteratorIndexedCrefs(cref, inIterator, {});

        // Append the prefix from the qualified cref to any matches, and add
        // them to the result list.
        for cr in crefs loop
          (cref, idx) := cr;
          outCrefs := (CREF_QUAL(id, subs, cref), idx) :: outCrefs;
        end for;
      then
        getIteratorIndexedCrefs(CREF_IDENT(id, subs), inIterator, outCrefs);

    case CREF_FULLYQUALIFIED(componentRef = cref)
      algorithm
        crefs := getIteratorIndexedCrefs(cref, inIterator, {});

        // Make any matches fully qualified, and add them to the result list.
        for cr in crefs loop
          (cref, idx) := cr;
          outCrefs := (CREF_FULLYQUALIFIED(cref), idx) :: outCrefs;
        end for;
      then
        outCrefs;

    else inCrefs;
  end match;
end getIteratorIndexedCrefs;

public function pathReplaceIdent
  input Path path;
  input String last;
  output Path out;
algorithm
  out := match (path,last)
    local Path p; String n,s;
    case (FULLYQUALIFIED(p),s) equation p = pathReplaceIdent(p,s); then FULLYQUALIFIED(p);
    case (QUALIFIED(n,p),s) equation p = pathReplaceIdent(p,s); then QUALIFIED(n,p);
    case (IDENT(),s) then IDENT(s);
  end match;
end pathReplaceIdent;

public function getFileNameFromInfo
  input SourceInfo inInfo;
  output String inFileName;
algorithm
  SOURCEINFO(fileName = inFileName) := inInfo;
end getFileNameFromInfo;

public function isOuter
"@author: adrpo
  this function returns true if the given InnerOuter
  is one of INNER_OUTER() or OUTER()"
  input InnerOuter io;
  output Boolean isItAnOuter;
algorithm
  isItAnOuter := match(io)
    case (INNER_OUTER()) then true;
    case (OUTER()) then true;
    else false;
  end match;
end isOuter;

public function isInner
"@author: adrpo
  this function returns true if the given InnerOuter
  is one of INNER_OUTER() or INNER()"
  input InnerOuter io;
  output Boolean isItAnInner;
algorithm
  isItAnInner := match(io)
    case (INNER_OUTER()) then true;
    case (INNER()) then true;
    else false;
  end match;
end isInner;

public function isOnlyInner
  "Returns true if the InnerOuter is INNER, false otherwise."
  input InnerOuter inIO;
  output Boolean outOnlyInner;
algorithm
  outOnlyInner := match(inIO)
    case (INNER()) then true;
    else false;
  end match;
end isOnlyInner;

public function isOnlyOuter
  "Returns true if the InnerOuter is OUTER, false otherwise."
  input InnerOuter inIO;
  output Boolean outOnlyOuter;
algorithm
  outOnlyOuter := match(inIO)
    case (OUTER()) then true;
    else false;
  end match;
end isOnlyOuter;

public function isInnerOuter
  input InnerOuter inIO;
  output Boolean outIsInnerOuter;
algorithm
  outIsInnerOuter := match(inIO)
    case (INNER_OUTER()) then true;
    else false;
  end match;
end isInnerOuter;

public function isNotInnerOuter
  input InnerOuter inIO;
  output Boolean outIsNotInnerOuter;
algorithm
  outIsNotInnerOuter := match(inIO)
    case (NOT_INNER_OUTER()) then true;
    else false;
  end match;
end isNotInnerOuter;

public function innerOuterEqual "Returns true if two InnerOuter's are equal"
  input InnerOuter io1;
  input InnerOuter io2;
  output Boolean res;
algorithm
  res := match(io1,io2)
    case(INNER(),INNER()) then true;
    case(OUTER(),OUTER()) then true;
    case(INNER_OUTER(),INNER_OUTER()) then true;
    case(NOT_INNER_OUTER(),NOT_INNER_OUTER()) then true;
    else false;
  end match;
end innerOuterEqual;

public function makeFullyQualified
"Makes a path fully qualified unless it already is."
  input Path inPath;
  output Path outPath;
algorithm
  outPath := match(inPath)
    case FULLYQUALIFIED() then inPath;
    else FULLYQUALIFIED(inPath);
  end match;
end makeFullyQualified;

public function makeNotFullyQualified
"Makes a path not fully qualified unless it already is."
  input Path inPath;
  output Path outPath;
algorithm
  outPath := match inPath
    local Path path;
    case FULLYQUALIFIED(path) then path;
    else inPath;
  end match;
end makeNotFullyQualified;

public function importEqual "Compares two import elements. "
  input Import im1;
  input Import im2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (im1,im2)
    local
      Ident id,id2;
      Path p1,p2;
    case (NAMED_IMPORT(name = id,path=p1),NAMED_IMPORT(name = id2,path=p2))
      equation
        true = stringEq(id, id2);
        true = pathEqual(p1,p2);
      then
        true;
    case (QUAL_IMPORT(path=p1),QUAL_IMPORT(path=p2))
      equation
        true = pathEqual(p1,p2);
      then
        true;
    case (UNQUAL_IMPORT(path=p1),UNQUAL_IMPORT(path=p2))
      equation
        true = pathEqual(p1,p2);
      then
        true;
    else false;
  end matchcontinue;
end importEqual;

public function canonIfExp "Transforms an if-expression to canonical form (without else-if branches)"
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp := match inExp
    local
      Exp cond,tb,eb,ei_cond,ei_tb,e;
      list<tuple<Exp,Exp>> eib;

    case IFEXP(elseIfBranch={}) then inExp;
    case IFEXP(ifExp=cond,trueBranch=tb,elseBranch=eb,elseIfBranch=(ei_cond,ei_tb)::eib)
      equation
        e = canonIfExp(IFEXP(ei_cond,ei_tb,eb,eib));
      then IFEXP(cond,tb,e,{});
  end match;
end canonIfExp;

public function onlyLiteralsInAnnotationMod
"@author: adrpo
  This function checks if a modification only contains literal expressions"
  input list<ElementArg> inMod;
  output Boolean onlyLiterals;
algorithm
  onlyLiterals := matchcontinue(inMod)
    local
      list<ElementArg> dive, rest;
      EqMod eqMod;
      Boolean b1, b2, b3, b;

    case ({}) then true;

    // skip "interaction" annotation!
    case (MODIFICATION(path = IDENT(name = "interaction")) :: rest)
      equation
        b = onlyLiteralsInAnnotationMod(rest);
      then
        b;


    // search inside, some(exp)
    case (MODIFICATION(modification = SOME(CLASSMOD(dive, eqMod))) :: rest)
      equation
        b1 = onlyLiteralsInEqMod(eqMod);
        b2 = onlyLiteralsInAnnotationMod(dive);
        b3 = onlyLiteralsInAnnotationMod(rest);
        b = boolAnd(b1, boolAnd(b2, b3));
      then
        b;

    case (_ :: rest)
      equation
        b = onlyLiteralsInAnnotationMod(rest);
      then
        b;

    // failed above, return false
    else false;

  end matchcontinue;
end onlyLiteralsInAnnotationMod;

protected function onlyLiteralsInEqMod
"@author: adrpo
  This function checks if an optional expression only contains literal expressions"
  input EqMod eqMod;
  output Boolean onlyLiterals;
algorithm
  onlyLiterals := match (eqMod)
    local
      Exp exp;
      list<Exp> lst;
      Boolean b;

    case (NOMOD()) then true;

    // DynamicSelect returns true!
    case (EQMOD(exp=CALL(function_ = CREF_IDENT(name = "DynamicSelect")))) then true;

    // search inside, some(exp)
    case (EQMOD(exp=exp))
      equation
         (_, lst::{}) = traverseExpBidir(exp, onlyLiteralsInExpEnter, onlyLiteralsInExpExit, {}::{});
         // if list is empty (no crefs were added)
         b = listEmpty(lst);
         // debugging:
         // print("Crefs in annotations: (" + stringDelimitList(List.map(lst, Dump.printExpStr), ", ") + ")\n");
      then
        b;
  end match;
end onlyLiteralsInEqMod;

protected function onlyLiteralsInExpEnter
"@author: adrpo
 Visitor function for checking if Exp contains only literals, NO CREFS!
 It returns an empty list if it doesn't contain any crefs!"
  input Exp inExp;
  input list<list<Exp>> inLst;
  output Exp outExp;
  output list<list<Exp>> outLst;
algorithm
  (outExp,outLst) := match (inExp,inLst)
    local
      Boolean b;
      Exp e;
      ComponentRef cr;
      list<Exp> lst;
      list<list<Exp>> rest;
      String name;

    // first handle DynamicSelect (push a stack that we can pop and ignore later on)
    case (CALL(function_ = CREF_IDENT(name = "DynamicSelect")), rest)
      then (inExp, {}::rest);

    // first handle all graphic enumerations!
    // FillPattern.*, Smooth.*, TextAlignment.*, etc!
    case (e as CREF(CREF_QUAL(name=name)), lst::rest)
      equation
        b = listMember(name,{
                          "LinePattern",
                          "Arrow",
                          "FillPattern",
                          "BorderPattern",
                          "TextStyle",
                          "Smooth",
                          "TextAlignment"});
        lst = List.consOnTrue(not b,e,lst);
      then (inExp, lst::rest);

    // crefs, add to list
    case (CREF(), lst::rest) then (inExp,(inExp::lst)::rest);
    // anything else, return the same!
    else (inExp,inLst);

  end match;
end onlyLiteralsInExpEnter;

protected function onlyLiteralsInExpExit
"@author: adrpo
 Visitor function for checking if Exp contains only literals, NO CREFS!
 It returns an empty list if it doesn't contain any crefs!"
  input Exp inExp;
  input list<list<Exp>> inLst;
  output Exp outExp;
  output list<list<Exp>> outLst;
algorithm
  (outExp,outLst) := match (inExp,inLst)
    local
      list<list<Exp>> lst;

    // first handle DynamicSelect; pop the stack (ignore any crefs inside DynamicSelect)
    case (CALL(function_ = CREF_IDENT(name = "DynamicSelect")), _::lst)
      then (inExp, lst);

    // anything else, return the same!
    else (inExp,inLst);

  end match;
end onlyLiteralsInExpExit;

public function makeCons
  input Exp e1;
  input Exp e2;
  output Exp e;
algorithm
  e := CONS(e1,e2);
annotation(__OpenModelica_EarlyInline = true);
end makeCons;

public function crefIdent
  input ComponentRef cr;
  output String str;
algorithm
  CREF_IDENT(str,{}) := cr;
end crefIdent;

public function unqotePathIdents
  input Path inPath;
  output Path path;
algorithm
  path := stringListPath(List.map(pathToStringList(inPath), System.unquoteIdentifier));
end unqotePathIdents;

public function unqualifyCref
  "If the given component reference is fully qualified this function removes the
  fully qualified qualifier, otherwise does nothing."
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := match(inCref)
    local
      ComponentRef cref;

    case CREF_FULLYQUALIFIED(componentRef = cref) then cref;
    else inCref;
  end match;
end unqualifyCref;

public function pathIsFullyQualified
  input Path inPath;
  output Boolean outIsQualified;
algorithm
  outIsQualified := match(inPath)
    case FULLYQUALIFIED() then true;
    else false;
  end match;
end pathIsFullyQualified;

public function pathIsIdent
  input Path inPath;
  output Boolean outIsIdent;
algorithm
  outIsIdent := match(inPath)
    case IDENT() then true;
    else false;
  end match;
end pathIsIdent;

public function pathIsQual
  input Path inPath;
  output Boolean outIsQual;
algorithm
  outIsQual := match(inPath)
    case QUALIFIED() then true;
    else false;
  end match;
end pathIsQual;

public function withinEqual
  input Within within1;
  input Within within2;
  output Boolean b;
algorithm
  b := match (within1,within2)
    local
      Path p1,p2;
    case (TOP(),TOP()) then true;
    case (WITHIN(p1),WITHIN(p2)) then pathEqual(p1,p2);
    else false;
  end match;
end withinEqual;

public function withinString
  input Within w1;
  output String str;
algorithm
  str := match (w1)
    local
      Path p1;
    case (TOP()) then "within ;";
    case (WITHIN(p1)) then "within " + pathString(p1) + ";";
  end match;
end withinString;

public function joinWithinPath
  input Within within_;
  input Path path;
  output Path outPath;
algorithm
  outPath := match (within_,path)
    local
      Path path1;
    case (TOP(),_) then path;
    case (WITHIN(path1),_) then joinPaths(path1,path);
  end match;
end joinWithinPath;

public function innerOuterStr
  input InnerOuter io;
  output String str;
algorithm
  str := match(io)
    case (INNER_OUTER()) then "inner outer ";
    case (INNER()) then "inner ";
    case (OUTER()) then "outer ";
    case (NOT_INNER_OUTER()) then "";
  end match;
end innerOuterStr;

public function subscriptExpOpt
  input Subscript inSub;
  output Option<Exp> outExpOpt;
algorithm
  outExpOpt := match(inSub)
    local
      Exp e;

    case SUBSCRIPT(subscript = e) then SOME(e);
    case NOSUB() then NONE();
  end match;
end subscriptExpOpt;

public function crefInsertSubscriptLstLst
  input Exp inExp;
  input list<list<Subscript>> inLst;
  output Exp outExp;
  output list<list<Subscript>> outLst;
algorithm
  (outExp,outLst) := matchcontinue(inExp,inLst)
    local
      ComponentRef cref,cref2;
      list<list<Subscript>> subs;
      Exp e;
    case (CREF(componentRef=cref),subs)
      equation
        cref2 = crefInsertSubscriptLstLst2(cref,subs);
      then
         (CREF(cref2),subs);
    else (inExp,inLst);
  end matchcontinue;
end crefInsertSubscriptLstLst;

public function crefInsertSubscriptLstLst2
"Helper function to crefInsertSubscriptLstLst"
  input ComponentRef inCref;
  input list<list<Subscript>> inSubs;
  output ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref,inSubs)
    local
      ComponentRef cref, cref2;
      Ident n;
      list<list<Subscript>> subs;
      list<Subscript> s;
      case (cref,{})
        then cref;
      case (CREF_IDENT(name = n), {s})
        then CREF_IDENT(n,s);
      case (CREF_QUAL(name = n, componentRef = cref), s::subs)
        equation
          cref2 = crefInsertSubscriptLstLst2(cref, subs);
        then
          CREF_QUAL(n,s,cref2);
      case (CREF_FULLYQUALIFIED(componentRef = cref), subs)
        equation
          cref2 = crefInsertSubscriptLstLst2(cref, subs);
        then
          crefMakeFullyQualified(cref2);
  end matchcontinue;
end crefInsertSubscriptLstLst2;

public function isCref
  input Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case CREF() then true;
    else false;
  end match;
end isCref;

public function isTuple
  input Exp inExp;
  output Boolean outIsTuple;
algorithm
  outIsTuple := match inExp
    case TUPLE() then true;
    else false;
  end match;
end isTuple;

public function isDerCref
  input Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case CALL(CREF_IDENT("der",{}),FUNCTIONARGS({CREF()},{})) then true;
    else false;
  end match;
end isDerCref;

public function isDerCrefFail
  input Exp exp;
algorithm
  CALL(CREF_IDENT("der",{}),FUNCTIONARGS({CREF()},{})) := exp;
end isDerCrefFail;

public function getExpsFromArrayDim
 "author: adrpo
  returns all the expressions from array dimension as a list
  also returns if we have unknown dimensions in the array dimension"
  input ArrayDim inAd;
  output Boolean hasUnknownDimensions;
  output list<Exp> outExps;
algorithm
  (hasUnknownDimensions, outExps) := getExpsFromArrayDim_tail(inAd, {});
end getExpsFromArrayDim;

public function getExpsFromArrayDimOpt
 "author: adrpo
  returns all the expressions from array dimension as a list
  also returns if we have unknown dimensions in the array dimension"
  input Option<ArrayDim> inAdO;
  output Boolean hasUnknownDimensions;
  output list<Exp> outExps;
algorithm
  (hasUnknownDimensions, outExps) := match(inAdO)
    local ArrayDim ad;

    case (NONE()) then (false, {});

    case (SOME(ad))
      equation
        (hasUnknownDimensions, outExps) = getExpsFromArrayDim_tail(ad, {});
      then
        (hasUnknownDimensions, outExps);

  end match;
end getExpsFromArrayDimOpt;

public function getExpsFromArrayDim_tail
 "author: adrpo
  returns all the expressions from array dimension as a list
  also returns if we have unknown dimensions in the array dimension"
  input ArrayDim inAd;
  input list<Exp> inAccumulator;
  output Boolean hasUnknownDimensions;
  output list<Exp> outExps;
algorithm
  (hasUnknownDimensions, outExps) := match(inAd, inAccumulator)
    local
      list<Subscript> rest;
      Exp e;
      list<Exp> exps, acc;
      Boolean b;

    // handle empty list
    case ({}, acc) then (false, listReverse(acc));

    // handle SUBSCRIPT
    case (SUBSCRIPT(e)::rest, acc)
      equation
        (b, exps) = getExpsFromArrayDim_tail(rest, e::acc);
       then
         (b, exps);

    // handle NOSUB
    case (NOSUB()::rest, acc)
      equation
        (_, exps) = getExpsFromArrayDim_tail(rest, acc);
       then
         (true, exps);
  end match;
end getExpsFromArrayDim_tail;

public function isInputOrOutput
"@author: adrpo
 returns true if the given direction is input or output"
 input Direction direction;
 output Boolean isIorO "input or output only";
algorithm
  isIorO := match(direction)
    case (INPUT()) then true;
    case (OUTPUT()) then true;
    case (INPUT_OUTPUT()) then true;
    case (BIDIR()) then false;
  end match;
end isInputOrOutput;

public function isInput
  input Direction inDirection;
  output Boolean outIsInput;
algorithm
  outIsInput := match(inDirection)
    case INPUT() then true;
    case INPUT_OUTPUT() then true;
    else false;
  end match;
end isInput;

public function isOutput
  input Direction inDirection;
  output Boolean outIsOutput;
algorithm
  outIsOutput := match(inDirection)
    case OUTPUT() then true;
    case INPUT_OUTPUT() then true;
    else false;
  end match;
end isOutput;

public function directionEqual
  input Direction inDirection1;
  input Direction inDirection2;
  output Boolean outEqual;
algorithm
  outEqual := match(inDirection1, inDirection2)
    case (BIDIR(), BIDIR()) then true;
    case (INPUT(), INPUT()) then true;
    case (OUTPUT(), OUTPUT()) then true;
    case (INPUT_OUTPUT(), INPUT_OUTPUT()) then true;
    else false;
  end match;
end directionEqual;

public function isFieldEqual
  input IsField isField1;
  input IsField isField2;
  output Boolean outEqual;
algorithm
  outEqual := match(isField1, isField2)
    case (NONFIELD(), NONFIELD()) then true;
    case (FIELD(), FIELD()) then true;
    else false;
  end match;
end isFieldEqual;


public function pathLt
  input Path path1;
  input Path path2;
  output Boolean lt;
algorithm
  lt := stringCompare(pathString(path1),pathString(path2)) < 0;
end pathLt;

public function pathGe
  input Path path1;
  input Path path2;
  output Boolean ge;
algorithm
  ge := not pathLt(path1,path2);
end pathGe;

public function getShortClass "Strips out long class definitions"
  input Class cl;
  output Class o;
algorithm
  o := match cl
    local
      Ident name;
      Boolean pa, fi, en;
      Restriction re;
      ClassDef body;
      Info info;
    case CLASS(body=PARTS()) then fail();
    case CLASS(body=CLASS_EXTENDS()) then fail();
    case CLASS(name,pa,fi,en,re,body,info)
      equation
        body = stripClassDefComment(body);
      then CLASS(name,pa,fi,en,re,body,info);
  end match;
end getShortClass;

protected function stripClassDefComment
  "Strips out class definition comments."
  input ClassDef cl;
  output ClassDef o;
algorithm
  o := match cl
    local
      EnumDef enumLiterals;
      TypeSpec typeSpec;
      ElementAttributes attributes;
      list<ElementArg> arguments;
      list<Path> functionNames;
      Path functionName;
      list<Ident> vars;
      list<String> typeVars;
      Ident baseClassName;
      list<ElementArg> modifications;
      list<ClassPart> parts;
      list<NamedArg> classAttrs;
      list<Annotation> ann;
    case PARTS(typeVars,classAttrs,parts,ann,_) then PARTS(typeVars,classAttrs,parts,ann,NONE());
    case CLASS_EXTENDS(baseClassName,modifications,_,parts,ann) then CLASS_EXTENDS(baseClassName,modifications,NONE(),parts,ann);
    case DERIVED(typeSpec,attributes,arguments,_) then DERIVED(typeSpec,attributes,arguments,NONE());
    case ENUMERATION(enumLiterals,_) then ENUMERATION(enumLiterals,NONE());
    case OVERLOAD(functionNames,_) then OVERLOAD(functionNames,NONE());
    case PDER(functionName,vars,_) then PDER(functionName,vars,NONE());
    else cl;
  end match;
end stripClassDefComment;

public function getFunctionInterface "Strips out the parts of a function definition that are not needed for the interface"
  input Class cl;
  output Class o;
algorithm
  o := match cl
    local
      Ident name;
      Boolean partialPrefix, finalPrefix, encapsulatedPrefix;
      Info info;
      list<String> typeVars;
      list<ClassPart> classParts;
      list<ElementItem> elts;
      FunctionRestriction funcRest;
      list<NamedArg> classAttr;
    case CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,R_FUNCTION(funcRest),PARTS(typeVars,classAttr,classParts,_,_),info)
      equation
        (elts as _::_) = List.fold(listReverse(classParts),getFunctionInterfaceParts,{});
      then CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,R_FUNCTION(funcRest),PARTS(typeVars,classAttr,PUBLIC(elts)::{},{},NONE()),info);
  end match;
end getFunctionInterface;

protected function getFunctionInterfaceParts
  input ClassPart part;
  input list<ElementItem> elts;
  output list<ElementItem> oelts;
algorithm
  oelts := match (part,elts)
    local
      list<ElementItem> elts1,elts2;
    case (PUBLIC(elts1),elts2)
      equation
        elts1 = List.filterOnTrue(elts1,filterAnnotationItem);
      then listAppend(elts1,elts2);
    else elts;
  end match;
end getFunctionInterfaceParts;

protected function filterAnnotationItem
  input ElementItem elt;
  output Boolean outB;
algorithm
  outB := match elt
    case ELEMENTITEM() then true;
    else false;
  end match;
end filterAnnotationItem;

public function filterNestedClasses
  "Filter outs the nested classes from the class if any."
  input Class cl;
  output Class o;
algorithm
  o := match cl
    local
      Ident name;
      Boolean partialPrefix, finalPrefix, encapsulatedPrefix;
      Restriction restriction;
      list<String> typeVars;
      list<NamedArg> classAttrs;
      list<ClassPart> classParts;
      list<Annotation> annotations;
      Option<String> comment;
      Info info;
    case CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,PARTS(typeVars,classAttrs,classParts,annotations,comment),info)
      equation
        (classParts as _::_) = List.fold(listReverse(classParts),filterNestedClassesParts,{});
      then CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,PARTS(typeVars,classAttrs,classParts,annotations,comment),info);
    else cl;
  end match;
end filterNestedClasses;

protected function filterNestedClassesParts
  "Helper funciton for filterNestedClassesParts."
  input ClassPart classPart;
  input list<ClassPart> inClassParts;
  output list<ClassPart> outClassPart;
algorithm
  outClassPart := match (classPart, inClassParts)
    local
      list<ClassPart> classParts;
      list<ElementItem> elts;
    case (PUBLIC(elts), classParts)
      equation
        classPart.contents = List.filterOnFalse(elts, isElementItemClass);
      then classPart::classParts;
    case (PROTECTED(elts), classParts)
      equation
        classPart.contents = List.filterOnFalse(elts, isElementItemClass);
      then classPart::classParts;
    else classPart::inClassParts;
  end match;
end filterNestedClassesParts;

public function getExternalDecl
  "@author: adrpo
   returns the EXTERNAL form parts if there is any.
   if there is none, it fails!"
  input Class inCls;
  output ClassPart outExternal;
protected
  ClassPart cp;
  list<ClassPart> class_parts;
algorithm
  CLASS(body = PARTS(classParts = class_parts)) := inCls;
  outExternal := List.find(class_parts, isExternalPart);
end getExternalDecl;

protected function isExternalPart
  input ClassPart inClassPart;
  output Boolean outFound;
algorithm
  outFound := match inClassPart
    case EXTERNAL() then true;
    else false;
  end match;
end isExternalPart;

public function isParts
  input ClassDef cl;
  output Boolean b;
algorithm
  b := match cl
    case PARTS() then true;
    else false;
  end match;
end isParts;

public function makeClassElement "Makes a class into an ElementItem"
  input Class cl;
  output ElementItem el;
protected
  Info info;
  Boolean fp;
algorithm
  CLASS(finalPrefix = fp, info = info) := cl;
  el := ELEMENTITEM(ELEMENT(fp,NONE(),NOT_INNER_OUTER(),CLASSDEF(false,cl),info,NONE()));
end makeClassElement;

public function componentName
  input ComponentItem c;
  output String name;
algorithm
  COMPONENTITEM(component=COMPONENT(name=name)) := c;
end componentName;

public function pathSetLastIdent
  input Path inPath;
  input Path inLastIdent;
  output Path outPath;
algorithm
  outPath := match(inPath, inLastIdent)
    local
      Path p;
      String n;

    case (IDENT(), _) then inLastIdent;

    case (QUALIFIED(n, p), _)
      equation
        p = pathSetLastIdent(p, inLastIdent);
      then
        QUALIFIED(n, p);

    case (FULLYQUALIFIED(p), _)
      equation
        p = pathSetLastIdent(p, inLastIdent);
      then
        FULLYQUALIFIED(p);

  end match;
end pathSetLastIdent;

public function expContainsInitial
"@author:
  returns true if expression contains initial()"
  input Exp inExp;
  output Boolean hasInitial;
algorithm
  hasInitial := matchcontinue(inExp)
    local Boolean b;
    case (_)
      equation
        (_, b) = traverseExp(inExp, isInitialTraverseHelper, false);
      then
        b;
    else false;
  end matchcontinue;
end expContainsInitial;

protected function isInitialTraverseHelper
"@author:
  returns true if expression is initial()"
  input Exp inExp;
  input Boolean inBool;
  output Exp outExp;
  output Boolean outBool;
algorithm
  (outExp,outBool) := match (inExp,inBool)
    local Exp e; Boolean b;

    // make sure we don't have not initial()
    case (UNARY(NOT(), _) , _) then (inExp,inBool);
    // we have initial
    case (e , _)
      equation
        b = isInitial(e);
      then (e, b);
    else (inExp,inBool);
  end match;
end isInitialTraverseHelper;

public function isInitial
"@author:
  returns true if expression is initial()"
  input Exp inExp;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inExp)
    case (CALL(function_ = CREF_IDENT("initial", _))) then true;
    case (CALL(function_ = CREF_FULLYQUALIFIED(CREF_IDENT("initial", _)))) then true;
    else false;
  end match;
end isInitial;

public function importPath
  "Return the path of the given import."
  input Import inImport;
  output Path outPath;
algorithm
  outPath := match(inImport)
    local
      Path path;

    case NAMED_IMPORT(path = path) then path;
    case QUAL_IMPORT(path = path) then path;
    case UNQUAL_IMPORT(path = path) then path;
    case GROUP_IMPORT(prefix = path) then path;

  end match;
end importPath;

public function importName
  "Returns the import name of a named or qualified import."
  input Import inImport;
  output Ident outName;
algorithm
  outName := match(inImport)
    local
      Ident name;
      Path path;

    // Named import has a given name, 'import D = A.B.C' => D.
    case NAMED_IMPORT(name = name) then name;
    // Qualified import uses the last identifier, 'import A.B.C' => C.
    case QUAL_IMPORT(path = path) then pathLastIdent(path);

  end match;
end importName;

public function mergeAnnotations
" This function takes an old annotation as first argument and a new
   annotation as  second argument and merges the two.
   Annotation \"parts\" that exist in both the old and the new annotation
   will be changed according to the new definition. For instance,
   merge_annotations(annotation(x=1,y=2),annotation(x=3))
   => annotation(x=3,y=2)"
  input Annotation inAnnotation1;
  input Annotation inAnnotation2;
  output Annotation outAnnotation;
algorithm
  outAnnotation:=
  match (inAnnotation1,inAnnotation2)
    local
      list<ElementArg> oldmods,newmods;
      Annotation a;
    case (ANNOTATION(elementArgs = {}),a) then a;

    case (ANNOTATION(elementArgs = oldmods),ANNOTATION(elementArgs = newmods))
      then ANNOTATION(mergeAnnotations2(oldmods, newmods));
  end match;
end mergeAnnotations;

protected

function mergeAnnotations2
  input list<ElementArg> oldmods;
  input list<ElementArg> newmods;
  output list<ElementArg> res = listReverse(oldmods);
protected
  list<ElementArg> mods;
  Boolean b;
  Path p;
  ElementArg mod1,mod2;
algorithm
  for mod in newmods loop
    MODIFICATION(path=p) := mod;
    try
      mod2 := List.find(res, function isModificationOfPath(path=p));
      mod1 := subModsInSameOrder(mod2, mod);
      (res, true) := List.replaceOnTrue(mod1, res, function isModificationOfPath(path=p));
    else
      res := mod::res;
    end try;
  end for;
  res := listReverse(res);
end mergeAnnotations2;

public function mergeCommentAnnotation
  "Merges an annotation into a Comment option."
  input Annotation inAnnotation;
  input Option<Comment> inComment;
  output Option<Comment> outComment;
algorithm
  outComment := match inComment
    local
      Annotation ann;
      Option<String> cmt;

    // No comment, create a new one.
    case NONE()
      then SOME(COMMENT(SOME(inAnnotation), NONE()));

    // A comment without annotation, insert the annotation.
    case SOME(COMMENT(annotation_ = NONE(), comment = cmt))
      then SOME(COMMENT(SOME(inAnnotation), cmt));

    // A comment with annotation, merge the annotations.
    case SOME(COMMENT(annotation_ = SOME(ann), comment = cmt))
      then SOME(COMMENT(SOME(mergeAnnotations(ann, inAnnotation)), cmt));

  end match;
end mergeCommentAnnotation;

function isModificationOfPath
"returns true or false if the given path is in the list of modifications"
  input ElementArg mod;
  input Path path;
  output Boolean yes;
algorithm
  yes := match (mod,path)
    local
      String id1,id2;
    case (MODIFICATION(path = IDENT(name = id1)),IDENT(name = id2)) then id1==id2;
    else false;
  end match;
end isModificationOfPath;

function subModsInSameOrder
  input ElementArg oldmod;
  input ElementArg newmod;
  output ElementArg mod;
algorithm
  mod := match (oldmod,newmod)
    local
      list<ElementArg> args1,args2,res;
      ElementArg arg2;
      EqMod eq1,eq2;
      Path p;

    // mod1 or mod2 has no submods
    case (_, MODIFICATION(modification=NONE())) then newmod;
    case (MODIFICATION(modification=NONE()), _) then newmod;
    // mod1
    case (MODIFICATION(modification=SOME(CLASSMOD(args1,_))), arg2 as MODIFICATION(modification=SOME(CLASSMOD(args2,eq2))))
      algorithm
        // Delete all items from args2 that are not in args1
        res := {};
        for arg1 in args1 loop
          MODIFICATION(path=p) := arg1;
          if List.exist(args2, function isModificationOfPath(path=p)) then
            res := arg1::res;
          end if;
        end for;
        res := listReverse(res);
        // Merge the annotations
        res := mergeAnnotations2(res, args2);
        arg2.modification := SOME(CLASSMOD(res,eq2));
      then arg2;
  end match;
end subModsInSameOrder;

public function annotationToElementArgs
  input Annotation ann;
  output list<ElementArg> args;
algorithm
  ANNOTATION(args) := ann;
end annotationToElementArgs;

public function pathToTypeSpec
  input Path inPath;
  output TypeSpec outTypeSpec;
algorithm
  outTypeSpec := TPATH(inPath, NONE());
end pathToTypeSpec;

public function typeSpecString
  input TypeSpec inTs;
  output String outStr;
algorithm
  outStr := Dump.unparseTypeSpec(inTs);
end typeSpecString;

public function crefString
  input ComponentRef inCr;
  output String outStr;
algorithm
  outStr := Dump.printComponentRefStr(inCr);
end crefString;

public function typeSpecStringNoQualNoDims
  input TypeSpec inTs;
  output String outStr;
algorithm
  outStr := match (inTs)
    local
      Ident str,s,str1,str2,str3;
      Path path;
      Option<list<Subscript>> adim;
      list<TypeSpec> typeSpecLst;

    case (TPATH(path = path))
      equation
        str = pathString(makeNotFullyQualified(path));
      then
        str;

    case (TCOMPLEX(path = path,typeSpecs = typeSpecLst))
      equation
        str1 = pathString(makeNotFullyQualified(path));
        str2 = typeSpecStringNoQualNoDimsLst(typeSpecLst);
        str = stringAppendList({str1,"<",str2,">"});
      then
        str;

  end match;
end typeSpecStringNoQualNoDims;

public function typeSpecStringNoQualNoDimsLst
  input list<TypeSpec> inTypeSpecLst;
  output String outString;
algorithm
  outString := List.toString(inTypeSpecLst, typeSpecStringNoQualNoDims,
    "", "", ", ", "", false);
end typeSpecStringNoQualNoDimsLst;

public function crefStringIgnoreSubs
  input ComponentRef inCr;
  output String outStr;
protected
  Path p;
algorithm
  p := crefToPathIgnoreSubs(inCr);
  outStr := pathString(makeNotFullyQualified(p));
end crefStringIgnoreSubs;

public function importString
  input Import inImp;
  output String outStr;
algorithm
  outStr := Dump.unparseImportStr(inImp);
end importString;

public function refString
"@author: adrpo
 full Ref -> string
 cref/path full qualified, type dims, subscripts in crefs"
  input Ref inRef;
  output String outStr;
algorithm
  outStr := match(inRef)
    local ComponentRef cr; TypeSpec ts; Import im;
    case (RCR(cr)) then crefString(cr);
    case (RTS(ts)) then typeSpecString(ts);
    case (RIM(im)) then importString(im);
  end match;
end refString;

public function refStringBrief
"@author: adrpo
 brief Ref -> string
 no cref/path full qualified, no type dims, no subscripts in crefs"
  input Ref inRef;
  output String outStr;
algorithm
  outStr := match(inRef)
    local ComponentRef cr; TypeSpec ts; Import im;
    case (RCR(cr)) then crefStringIgnoreSubs(cr);
    case (RTS(ts)) then typeSpecStringNoQualNoDims(ts);
    case (RIM(im)) then importString(im);
  end match;
end refStringBrief;

public function getArrayDimOptAsList
  input Option<ArrayDim> inArrayDim;
  output ArrayDim outArrayDim;
algorithm
  outArrayDim := match(inArrayDim)
    local ArrayDim ad;
    case (SOME(ad)) then ad;
    else {};
  end match;
end getArrayDimOptAsList;

public function removeCrefFromCrefs
"Removes a variable from a variable list"
  input list<ComponentRef> inAbsynComponentRefLst;
  input ComponentRef inComponentRef;
  output list<ComponentRef> outAbsynComponentRefLst;
algorithm
  outAbsynComponentRefLst := matchcontinue (inAbsynComponentRefLst,inComponentRef)
    local
      String n1,n2;
      list<ComponentRef> rest_1,rest;
      ComponentRef cr1,cr2;
    case ({},_) then {};
    case ((cr1 :: rest),cr2)
      equation
        CREF_IDENT(name = n1,subscripts = {}) = cr1;
        CREF_IDENT(name = n2,subscripts = {}) = cr2;
        true = stringEq(n1, n2);
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        rest_1;
    case ((cr1 :: rest),cr2) // If modifier like on comp like: T t(x=t.y) => t.y must be removed
      equation
        CREF_QUAL(name = n1) = cr1;
        CREF_IDENT(name = n2) = cr2;
        true = stringEq(n1, n2);
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        rest_1;
    case ((cr1 :: rest),cr2)
      equation
        rest_1 = removeCrefFromCrefs(rest, cr2);
      then
        (cr1 :: rest_1);
  end matchcontinue;
end removeCrefFromCrefs;

public function getNamedAnnotationInClass
  "Retrieve e.g. the documentation annotation as a string from the class passed as argument."
  input Class inClass;
  input Path id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inClass,id,f)
    local
      TypeA str,res;
      list<ClassPart> parts;
      list<ElementArg> annlst;
      list<Annotation> ann;

    case (CLASS(body = PARTS(ann = ann)),_,_)
      equation
        annlst = List.flatten(List.map(ann,annotationToElementArgs));
        SOME(str) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(str);

    case (CLASS(body = CLASS_EXTENDS(ann = ann)),_,_)
      equation
        annlst = List.flatten(List.map(ann,annotationToElementArgs));
        SOME(str) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(str);

    case (CLASS(body = DERIVED(comment = SOME(COMMENT(SOME(ANNOTATION(annlst)),_)))),_,_)
      equation
        SOME(res) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(res);

    case (CLASS(body = ENUMERATION(comment = SOME(COMMENT(SOME(ANNOTATION(annlst)),_)))),_,_)
      equation
        SOME(res) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(res);

    case (CLASS(body = OVERLOAD(comment = SOME(COMMENT(SOME(ANNOTATION(annlst)),_)))),_,_)
      equation
        SOME(res) = getNamedAnnotationStr(annlst,id,f);
      then
        SOME(res);

    else NONE();

  end matchcontinue;
end getNamedAnnotationInClass;

protected function getNamedAnnotationStr
"Helper function to getNamedAnnotationInElementitemlist."
  input list<ElementArg> inAbsynElementArgLst;
  input Path id;
  input ModFunc f;
  output Option<TypeA> outString;
  replaceable type TypeA subtypeof Any;
  partial function ModFunc
    input Option<Modification> mod;
    output TypeA docStr;
  end ModFunc;
algorithm
  outString := matchcontinue (inAbsynElementArgLst,id,f)
    local
      TypeA str;
      ElementArg ann;
      Option<Modification> mod;
      list<ElementArg> xs;
      Ident id1,id2;
      Path rest;

    case (((MODIFICATION(path = IDENT(name = id1),modification = mod)) :: _),IDENT(id2),_)
      equation
        true = stringEq(id1, id2);
        str = f(mod);
      then
        SOME(str);

    case (((MODIFICATION(path = IDENT(name = id1),modification = SOME(CLASSMOD(elementArgLst=xs)))) :: _),QUALIFIED(name=id2,path=rest),_)
      equation
        true = stringEq(id1, id2);
      then getNamedAnnotationStr(xs,rest,f);

    case ((_ :: xs),_,_) then getNamedAnnotationStr(xs,id,f);
  end matchcontinue;
end getNamedAnnotationStr;

public function mapCrefParts
  "This function splits each part of a cref into CREF_IDENTs and applies the
   given function to each part. If the given cref is a qualified cref then the
   map function is expected to also return CREF_IDENT, so that the split cref
   can be reconstructed. Otherwise the map function is free to return whatever
   it wants."
  input ComponentRef inCref;
  input MapFunc inMapFunc;
  output ComponentRef outCref;

  partial function MapFunc
    input ComponentRef inCref;
    output ComponentRef outCref;
  end MapFunc;
algorithm
  outCref := match(inCref, inMapFunc)
    local
      Ident name;
      list<Subscript> subs;
      ComponentRef rest_cref;
      ComponentRef cref;

    case (CREF_QUAL(name, subs, rest_cref), _)
      equation
        cref = CREF_IDENT(name, subs);
        CREF_IDENT(name, subs) = inMapFunc(cref);
        rest_cref = mapCrefParts(rest_cref, inMapFunc);
      then
        CREF_QUAL(name, subs, rest_cref);

    case (CREF_FULLYQUALIFIED(cref), _)
      equation
        cref = mapCrefParts(cref, inMapFunc);
      then
        CREF_FULLYQUALIFIED(cref);

    else
      equation
        cref = inMapFunc(inCref);
      then
        cref;

  end match;
end mapCrefParts;

public function opEqual
 input Operator op1;
 input Operator op2;
 output Boolean isEqual;
algorithm
  isEqual := valueEq(op1, op2);
end opEqual;

public function opIsElementWise
 input Operator op;
 output Boolean isElementWise;
algorithm
  isElementWise := match op
    case ADD_EW() then true;
    case SUB_EW() then true;
    case MUL_EW() then true;
    case DIV_EW() then true;
    case POW_EW() then true;
    case UPLUS_EW() then true;
    case UMINUS_EW() then true;
    else false;
  end match;
end opIsElementWise;

protected function dummyTraverseExp
  input Exp inExp;
  input Arg inArg;
  output Exp outExp;
  output Arg outArg;
  replaceable type Arg subtypeof Any;
algorithm
  outExp := inExp;
  outArg := inArg;
end dummyTraverseExp;

public function getDefineUnitsInElements "retrives defineunit definitions in elements"
  input list<ElementItem> elts;
  output list<Element> outElts;
algorithm
  outElts := matchcontinue(elts)
    local
      Element e;
      list<ElementItem> rest;
    case {} then {};
    case (ELEMENTITEM(e as DEFINEUNIT())::rest)
      equation
        outElts = getDefineUnitsInElements(rest);
      then e::outElts;
    case (_::rest)
      then getDefineUnitsInElements(rest);
  end matchcontinue;
end getDefineUnitsInElements;

public function getElementItemsInClass
  "Returns the public and protected elements in a class."
  input Class inClass;
  output list<ElementItem> outElements;
algorithm
  outElements := match(inClass)
    local
      list<ClassPart> parts;

    case CLASS(body = PARTS(classParts = parts))
      then List.mapFlat(parts, getElementItemsInClassPart);

    case CLASS(body = CLASS_EXTENDS(parts = parts))
      then List.mapFlat(parts, getElementItemsInClassPart);

    else {};

  end match;
end getElementItemsInClass;

protected function getElementItemsInClassPart
  "Returns the public and protected elements in a class part."
  input ClassPart inClassPart;
  output list<ElementItem> outElements;
algorithm
  outElements := match(inClassPart)
    local
      list<ElementItem> elts;

    case PUBLIC(contents = elts) then elts;
    case PROTECTED(contents = elts) then elts;
    else {};
  end match;
end getElementItemsInClassPart;

public function traverseClassComponents<ArgT>
  input Class inClass;
  input FuncType inFunc;
  input ArgT inArg;
  output Class outClass = inClass;
  output ArgT outArg;

  partial function FuncType
    input list<ComponentItem> inComponents;
    input ArgT inArg;
    output list<ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  outClass := match(outClass)
    local
      ClassDef body;

    case CLASS()
      algorithm
        (body, outArg) := traverseClassDef(outClass.body,
          function traverseClassPartComponents(inFunc = inFunc), inArg);
        if not referenceEq(body, outClass.body) then outClass.body := body; end if;
      then
        outClass;

  end match;
end traverseClassComponents;

protected function traverseListGeneric<T, ArgT>
  input list<T> inList;
  input FuncType inFunc;
  input ArgT inArg;
  output list<T> outList = {};
  output ArgT outArg = inArg;
  output Boolean outContinue = true;

  partial function FuncType
    input T inElement;
    input ArgT inArg;
    output T outElement;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
protected
  Boolean eq, changed = false;
  T e, new_e;
  list<T> rest_e = inList;
algorithm
  while not listEmpty(rest_e) loop
    e :: rest_e := rest_e;
    (new_e, outArg, outContinue) := inFunc(e, outArg);
    eq := referenceEq(new_e, e);
    outList := (if eq then e else new_e) :: outList;
    changed := changed or not eq;
    if not outContinue then break; end if;
  end while;

  if changed then
    outList := List.append_reverse(outList, rest_e);
  else
    outList := inList;
  end if;
end traverseListGeneric;

protected function traverseClassPartComponents<ArgT>
  input ClassPart inClassPart;
  input FuncType inFunc;
  input ArgT inArg;
  output ClassPart outClassPart = inClassPart;
  output ArgT outArg = inArg;
  output Boolean outContinue = true;

  partial function FuncType
    input list<ComponentItem> inComponents;
    input ArgT inArg;
    output list<ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  _ := match(outClassPart)
    local
      list<ElementItem> items;

    case PUBLIC()
      algorithm
        (items, outArg, outContinue) :=
          traverseListGeneric(outClassPart.contents,
            function traverseElementItemComponents(inFunc = inFunc), inArg);
        outClassPart.contents := items;
      then
        ();

    case PROTECTED()
      algorithm
        (items, outArg, outContinue) :=
          traverseListGeneric(outClassPart.contents,
             function traverseElementItemComponents(inFunc = inFunc), inArg);
        outClassPart.contents := items;
      then
        ();

    else ();
  end match;
end traverseClassPartComponents;

protected function traverseElementItemComponents<ArgT>
  input ElementItem inItem;
  input FuncType inFunc;
  input ArgT inArg;
  output ElementItem outItem;
  output ArgT outArg;
  output Boolean outContinue;

  partial function FuncType
    input list<ComponentItem> inComponents;
    input ArgT inArg;
    output list<ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  (outItem, outArg, outContinue) := match(inItem)
    local
      Element elem;

    case ELEMENTITEM()
      algorithm
        (elem, outArg, outContinue) := traverseElementComponents(inItem.element,
          inFunc, inArg);
        outItem := if referenceEq(elem, inItem.element) then inItem else ELEMENTITEM(elem);
      then
        (outItem, outArg, outContinue);

    else (inItem, inArg, true);
  end match;
end traverseElementItemComponents;

protected function traverseElementComponents<ArgT>
  input Element inElement;
  input FuncType inFunc;
  input ArgT inArg;
  output Element outElement = inElement;
  output ArgT outArg;
  output Boolean outContinue;

  partial function FuncType
    input list<ComponentItem> inComponents;
    input ArgT inArg;
    output list<ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  (outElement, outArg, outContinue) := match(outElement)
    local
      ElementSpec spec;

    case ELEMENT()
      algorithm
        (spec, outArg, outContinue) := traverseElementSpecComponents(
          outElement.specification, inFunc, inArg);

        if not referenceEq(spec, outElement.specification) then
          outElement.specification := spec;
        end if;
      then
        (outElement, outArg, outContinue);

    else (inElement, inArg, true);
  end match;
end traverseElementComponents;

protected function traverseElementSpecComponents<ArgT>
  input ElementSpec inSpec;
  input FuncType inFunc;
  input ArgT inArg;
  output ElementSpec outSpec = inSpec;
  output ArgT outArg;
  output Boolean outContinue;

  partial function FuncType
    input list<ComponentItem> inComponents;
    input ArgT inArg;
    output list<ComponentItem> outComponents;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  (outSpec, outArg, outContinue) := match(outSpec)
    local
      Class cls;
      list<ComponentItem> comps;

    case COMPONENTS()
      algorithm
        (comps, outArg, outContinue) := inFunc(outSpec.components, inArg);
        if not referenceEq(comps, outSpec.components) then
          outSpec.components := comps;
        end if;
      then
        (outSpec, outArg, outContinue);

    else (inSpec, inArg, true);
  end match;
end traverseElementSpecComponents;

protected function traverseClassDef<ArgT>
  input ClassDef inClassDef;
  input FuncType inFunc;
  input ArgT inArg;
  output ClassDef outClassDef = inClassDef;
  output ArgT outArg = inArg;
  output Boolean outContinue = true;

  partial function FuncType
    input ClassPart inPart;
    input ArgT inArg;
    output ClassPart outPart;
    output ArgT outArg;
    output Boolean outContinue;
  end FuncType;
algorithm
  _ := match(outClassDef)
    local
      list<ClassPart> parts;

    case PARTS()
      algorithm
        (parts, outArg, outContinue) :=
          traverseListGeneric(outClassDef.classParts, inFunc, inArg);
        outClassDef.classParts := parts;
      then
        ();

    case CLASS_EXTENDS()
      algorithm
        (parts, outArg, outContinue) :=
          traverseListGeneric(outClassDef.parts, inFunc, inArg);
        outClassDef.parts := parts;
      then
        ();

    else ();
  end match;
end traverseClassDef;

public function isEmptyMod
  input Modification inMod;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inMod
    case CLASSMOD({}, NOMOD()) then true;
    case CLASSMOD({}, EQMOD(exp = TUPLE(expressions = {}))) then true;
    else false;
  end match;
end isEmptyMod;

public function isEmptySubMod
  input ElementArg inSubMod;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inSubMod
    local
      Modification mod;

    case MODIFICATION(modification = NONE()) then true;
    case MODIFICATION(modification = SOME(mod)) then isEmptyMod(mod);
  end match;
end isEmptySubMod;

public function elementArgName
  input ElementArg inArg;
  output Path outName;
algorithm
  outName := match(inArg)
    local
      ElementSpec e;
    case MODIFICATION(path = outName) then outName;
    case REDECLARATION(elementSpec = e) then makeIdentPathFromString(elementSpecName(e));
  end match;
end elementArgName;

public function elementArgEqualName
  input ElementArg inArg1;
  input ElementArg inArg2;
  output Boolean outEqual;
protected
  Path name1, name2;
algorithm
  outEqual := match(inArg1, inArg2)
    case (MODIFICATION(path = name1), MODIFICATION(path = name2))
      then pathEqual(name1, name2);

    else false;
  end match;
end elementArgEqualName;

public function optMsg
  "Creates a Msg based on a boolean value."
  input Boolean inShowMessage;
  input SourceInfo inInfo;
  output Msg outMsg;
algorithm
  outMsg := if inShowMessage then MSG(inInfo) else NO_MSG();
  annotation(__OpenModelica_EarlyInline = true);
end optMsg;

public function makeSubscript
  input Exp inExp;
  output Subscript outSubscript;
algorithm
  outSubscript := SUBSCRIPT(inExp);
end makeSubscript;

public function crefExplode
  "Splits a cref into parts."
  input ComponentRef inCref;
  input list<ComponentRef> inAccum = {};
  output list<ComponentRef> outCrefParts;
algorithm
  outCrefParts := match inCref
    case CREF_QUAL() then crefExplode(inCref.componentRef, crefFirstCref(inCref) :: inAccum);
    case CREF_FULLYQUALIFIED() then crefExplode(inCref.componentRef, inAccum);
    else listReverse(inCref :: inAccum);
  end match;
end crefExplode;

public function traverseExpShallow<ArgT>
  "Calls the given function on each subexpression (non-recursively) of the given
   expression, sending in the extra argument to each call."
  input Exp inExp;
  input ArgT inArg;
  input FuncT inFunc;
  output Exp outExp = inExp;

  partial function FuncT
    input Exp inExp;
    input ArgT inArg;
    output Exp outExp;
  end FuncT;
algorithm
  _ := match outExp
    local
      Exp e1, e2;

    case BINARY()
      algorithm
        outExp.exp1 := inFunc(outExp.exp1, inArg);
        outExp.exp2 := inFunc(outExp.exp2, inArg);
      then
        ();

    case UNARY()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
      then
        ();

    case LBINARY()
      algorithm
        outExp.exp1 := inFunc(outExp.exp1, inArg);
        outExp.exp2 := inFunc(outExp.exp2, inArg);
      then
        ();

    case LUNARY()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
      then
        ();

    case RELATION()
      algorithm
        outExp.exp1 := inFunc(outExp.exp1, inArg);
        outExp.exp2 := inFunc(outExp.exp2, inArg);
      then
        ();

    case IFEXP()
      algorithm
        outExp.ifExp := inFunc(outExp.ifExp, inArg);
        outExp.trueBranch := inFunc(outExp.trueBranch, inArg);
        outExp.elseBranch := inFunc(outExp.elseBranch, inArg);
        outExp.elseIfBranch := list((inFunc(Util.tuple21(e), inArg),
          inFunc(Util.tuple22(e), inArg)) for e in outExp.elseIfBranch);
      then
        ();

    case CALL()
      algorithm
        outExp.functionArgs := traverseExpShallowFuncArgs(outExp.functionArgs,
          inArg, inFunc);
      then
        ();

    case PARTEVALFUNCTION()
      algorithm
        outExp.functionArgs := traverseExpShallowFuncArgs(outExp.functionArgs,
          inArg, inFunc);
      then
        ();

    case ARRAY()
      algorithm
        outExp.arrayExp := list(inFunc(e, inArg) for e in outExp.arrayExp);
      then
        ();

    case MATRIX()
      algorithm
        outExp.matrix := list(list(inFunc(e, inArg) for e in lst) for lst in
            outExp.matrix);
      then
        ();

    case RANGE()
      algorithm
        outExp.start := inFunc(outExp.start, inArg);
        outExp.step := Util.applyOption1(outExp.step, inFunc, inArg);
        outExp.stop := inFunc(outExp.stop, inArg);
      then
        ();

    case TUPLE()
      algorithm
        outExp.expressions := list(inFunc(e, inArg) for e in outExp.expressions);
      then
        ();

    case AS()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
      then
        ();

    case CONS()
      algorithm
        outExp.head := inFunc(outExp.head, inArg);
        outExp.rest := inFunc(outExp.rest, inArg);
      then
        ();

    case LIST()
      algorithm
        outExp.exps := list(inFunc(e, inArg) for e in outExp.exps);
      then
        ();

    case DOT()
      algorithm
        outExp.exp := inFunc(outExp.exp, inArg);
        outExp.index := inFunc(outExp.index, inArg);
      then
        ();

    else ();
  end match;
end traverseExpShallow;

protected function traverseExpShallowFuncArgs<ArgT>
  input FunctionArgs inArgs;
  input ArgT inArg;
  input FuncT inFunc;
  output FunctionArgs outArgs = inArgs;

  partial function FuncT
    input Exp inExp;
    input ArgT inArg;
    output Exp outExp;
  end FuncT;
algorithm
  outArgs := match outArgs
    case FUNCTIONARGS()
      algorithm
        outArgs.args := list(inFunc(arg, inArg) for arg in outArgs.args);
      then
        outArgs;

    case FOR_ITER_FARG()
      algorithm
        outArgs.exp := inFunc(outArgs.exp, inArg);
        outArgs.iterators := list(traverseExpShallowIterator(it, inArg, inFunc)
          for it in outArgs.iterators);
      then
        outArgs;

  end match;
end traverseExpShallowFuncArgs;

protected function traverseExpShallowIterator<ArgT>
  input ForIterator inIterator;
  input ArgT inArg;
  input FuncT inFunc;
  output ForIterator outIterator;

  partial function FuncT
    input Exp inExp;
    input ArgT inArg;
    output Exp outExp;
  end FuncT;
protected
  String name;
  Option<Exp> guard_exp, range_exp;
algorithm
  ITERATOR(name, guard_exp, range_exp) := inIterator;
  guard_exp := Util.applyOption1(guard_exp, inFunc, inArg);
  range_exp := Util.applyOption1(range_exp, inFunc, inArg);
  outIterator := ITERATOR(name, guard_exp, range_exp);
end traverseExpShallowIterator;

public function isElementItemClass
  input ElementItem inElement;
  output Boolean outIsClass;
algorithm
  outIsClass := match inElement
    case ELEMENTITEM(element = ELEMENT(specification = CLASSDEF())) then true;
    else false;
  end match;
end isElementItemClass;

public function isElementItem
  input ElementItem inElement;
  output Boolean outIsClass;
algorithm
  outIsClass := match inElement
    case ELEMENTITEM() then true;
    else false;
  end match;
end isElementItem;

public function isAlgorithmItem
  input AlgorithmItem inAlg;
  output Boolean outIsClass;
algorithm
  outIsClass := match inAlg
    case ALGORITHMITEM() then true;
    else false;
  end match;
end isAlgorithmItem;

public function isElementItemClassNamed
  input String inName;
  input ElementItem inElement;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match inElement
    local
      String name;

    case ELEMENTITEM(element = ELEMENT(specification = CLASSDEF(
      class_ = CLASS(name = name)))) then name == inName;
    else false;
  end match;
end isElementItemClassNamed;

public function isEmptyClassPart
  input ClassPart inClassPart;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inClassPart
    case PUBLIC(contents = {}) then true;
    case PROTECTED(contents = {}) then true;
    case CONSTRAINTS(contents = {}) then true;
    case EQUATIONS(contents = {}) then true;
    case INITIALEQUATIONS(contents = {}) then true;
    case ALGORITHMS(contents = {}) then true;
    case INITIALALGORITHMS(contents = {}) then true;
    else false;
  end match;
end isEmptyClassPart;

public function isInvariantExpNoTraverse "For use with traverseExp"
  input output Absyn.Exp e;
  input output Boolean b;
algorithm
  if not b then
    return;
  end if;
  b := match e
    case INTEGER() then true;
    case REAL() then true;
    case STRING() then true;
    case BOOL() then true;
    case BINARY() then true;
    case UNARY() then true;
    case LBINARY() then true;
    case LUNARY() then true;
    case RELATION() then true;
    case IFEXP() then true;
    // case CREF(CREF_FULLYQUALIFIED()) then true;
    case CALL(function_=CREF_FULLYQUALIFIED()) then true;
    case PARTEVALFUNCTION(function_=CREF_FULLYQUALIFIED()) then true;
    case ARRAY() then true;
    case MATRIX() then true;
    case RANGE() then true;
    case CONS() then true;
    case LIST() then true;
    else false;
  end match;
end isInvariantExpNoTraverse;

function pathPartCount
  "Returns the number of parts a path consists of, e.g. A.B.C gives 3."
  input Path path;
  input Integer partsAccum = 0;
  output Integer parts;
algorithm
  parts := match path
    case Path.IDENT() then partsAccum + 1;
    case Path.QUALIFIED() then pathPartCount(path.path, partsAccum + 1);
    case Path.FULLYQUALIFIED() then pathPartCount(path.path, partsAccum);
  end match;
end pathPartCount;

annotation(__OpenModelica_Interface="frontend");
end Absyn;
