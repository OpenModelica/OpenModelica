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


  This file defines the abstract syntax for Modelica in MetaModelica Compiler (MMC). It
  contains uniontypes for constructing the abstract syntax tree
  (AST).

  * Abstract Syntax Tree (Close to Modelica)
     - Complete Modelica 2.2, 3.1, 3.2, MetaModelica
     - Including annotations and comments
  * Primary AST for e.g. the Interactive module
     - Model editor related representations (must use annotations)

  mo\'s constructors are primarily used by (Parser/Modelica.g).

  When the AST has been built, it is normally used by SCodeUtil.mo in order to
  build the SCode (See SCodeUtil.mo). It is also possile to send the AST do
  the unparser (Dump.mo) in order to print it.

  For details regarding the abstract syntax tree, check out the grammar in
  the Modelica language specification.


  The following are the types and uniontypes that are used for the AST:"

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
type ArrayDim = list<Subscript> "Component attributes are
  properties of components which are applied by type prefixes.
  As an example, declaring a component as `input Real x;\' will
  give the attributes `ATTR({},false,VAR,INPUT)\'.
  Components in Modelica can be scalar or arrays with one or more
  dimensions. This type is used to indicate the dimensionality
  of a component or a type definition.
- Array dimensions" ;


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
    Info info;
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
type ComponentCondition = Exp "A componentItem can have a condition that must be fulfilled if
  the component should be instantiated.
" ;

public
uniontype ComponentItem "Collection of component and an optional comment"
  record COMPONENTITEM
    Component component "component" ;
    Option<ComponentCondition> condition "condition" ;
    Option<Comment> comment "comment" ;
  end COMPONENTITEM;

end ComponentItem;

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
    FunctionArgs functionArgs;
    list<Absyn.Path> typeVars;
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
    Exp exp;
    Exp index;
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

annotation(__OpenModelica_Interface="frontend");
end Absyn;
