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

package Absyn
"
  file:	       Absyn.mo
  package:     Absyn
  description: Abstract syntax

  RCS: $Id$

  This file defines the abstract syntax for Modelica in MetaModelica Compiler (MMC).  It mainly
  contains uniontypes for constructing the abstract syntax tree
  (AST), functions for building and altering AST nodes and a few functions
  for printing the AST:

  * Abstract Syntax Tree (Close to Modelica)
     ï¿½ Complete Modelica 2.2
     ï¿½ Including annotations and comments
  * Primary AST for e.g. the Interactive module
     - Model editor related representations (must use annotations)
  * Functions
     - A few small functions, only working on Absyn types, e.g.:
       - pathToCref(Path) => ComponentRef
       - joinPaths(Path, Path) => (Path)
       - etc.


  Absyn.mo\'s constructors are primarily used by the walker
  (Compiler/absyn_builder/walker.g) which takes an ANTLR internal syntax tree and
  converts it into an MetaModelica Compiler (MMC) abstract syntax tree.

  When the AST has been built, it is normally used by SCode.mo in order to
  build the SCode (See SCode.mo). It is also possile to send the AST do
  the unparser (Dump.mo) in order to print it.

  For details regarding the abstract syntax tree, check out the grammar in
  the Modelica language specification.


  The following are the types and uniontypes that are used for the AST:"

protected import System;

public
type Ident = String "An identifier, for example a variable name" ;

public
type ForIterator = tuple<Ident, Option<Exp>>
"For Iterator -
   these are used in:
   * for loops where the expression part can be NONE and then the range
     is taken from an array variable that the iterator is used to index,
     see 3.3.3.2 Several Iterators from Modelica Specification.
   * in array iterators where the expression should always be SOME(Exp),
     see 3.4.4.2 Array constructor with iterators from Specification";
public type ForIterators = list<ForIterator>
"For Iterators -
   these are used in:
   * for loops where the expression part can be NONE and then the range
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
    TimeStamp    globalBuildTimes "";
  end PROGRAM;

   /*
   adrpo: 2008-11-30 !THESE SEEMS NOT TO BE USED ANYMORE!

   ModExtension: The following 3 nodes are not standard Modelica
   Nodes such as BEGIN_DEFINITION and END_DEFINITION
   can be used for representing packages and classes that are entered piecewise,
   e.g., first entering the package head (as BEGIN_DEFINITION),
   then the contained definitions, then an end package repesented as END_DEFINITION.

  record BEGIN_DEFINITION
    Path         path  "path for split definitions" ;
    Restriction  restriction   "Class restriction" ;
    Boolean      partialPrefix      "true if partial" ;
    Boolean      encapsulatedPrefix "true if encapsulated" ;
  end BEGIN_DEFINITION;

  record END_DEFINITION
    Ident  name   "name for split definitions" ;
  end END_DEFINITION;

  record COMP_DEFINITION
    ElementSpec  element    "element for split definitions" ;
    Option<Path> insertInto "insert into, Default: NONE" ;
  end COMP_DEFINITION;

  record IMPORT_DEFINITION
    ElementSpec   importElementFor "For split definitions" ;
    Option<Path>  insertInto       "Insert into, Default: NONE" ;
  end IMPORT_DEFINITION;
  */

end Program;

public
uniontype Within "Within Clauses"
  record WITHIN "the within clause"
    Path path "the path for within";
  end WITHIN;

  record TOP end TOP;

end Within;

public
uniontype Info
"@author adrpo
 added 2005-10-29, changed 2006-02-05
 The Info attribute provides location information for elements and classes."
  record INFO
    String fileName "fileName where the class is defined in" ;
    Boolean isReadOnly "isReadOnly : (true|false). Should be true for libraries" ;
    Integer lineNumberStart "lineNumberStart" ;
    Integer columnNumberStart "columnNumberStart" ;
    Integer lineNumberEnd "lineNumberEnd" ;
    Integer columnNumberEnd "columnNumberEnd" ;
    TimeStamp buildTimes "Build and edit times";
  end INFO;

end Info;

uniontype TimeStamp
 record TIMESTAMP
   Real lastBuildTime "Last Build Time";
   Real lastEditTime "Last Edit Time";
  end TIMESTAMP;
end TimeStamp;

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
"The ClassDef type contains the definition part of a class declaration.
 The definition is either explicit, with a list of parts
 (public, protected, equation, and algorithm), or it is a definition
 derived from another class or an enumeration type.
 For a derived type, the  type contains the name of the derived class
 and an optional array dimension and a list of modifications.
 "
  record PARTS
    list<ClassPart> classParts;
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
    Ident            baseClassName  "name of class to extend" ;
    list<ElementArg> modifications  "modifications to be applied to the base class";
    Option<String>   comment        "comment";
    list<ClassPart>  parts          "class parts";
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

  record ANNOTATIONITEM
    Annotation  annotation_ ;
  end ANNOTATIONITEM;

end ElementItem;

public
uniontype Element "Elements
  The basic element type in Modelica"
  record ELEMENT
    Boolean                   finalPrefix;
    Option<RedeclareKeywords> redeclareKeywords "replaceable, redeclare" ;
    InnerOuter                innerOuter "inner/outer" ;
    Ident                     name;
    ElementSpec               specification "Actual element specification" ;
    Info                      info  "File name the class is defined in + line no + column no" ;
    Option<ConstrainClass> constrainClass "constrainClass ; only valid for classdef and component" ;
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
    ElementSpec elementSpec "elementSpec ; must be extends" ;
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
  end IMPORT;

  record COMPONENTS
    ElementAttributes attributes "attributes" ;
    TypeSpec typeSpec "typeSpec" ;
    list<ComponentItem> components "components" ;
  end COMPONENTS;

end ElementSpec;

public
uniontype InnerOuter "One of the keyword inner and outer CAN be given to reference an inner or
      outer component. Thus there are three disjoint possibilities."
  record INNER "an inner component"                    end INNER;
  record OUTER "an outer component"                    end OUTER;
  record INNEROUTER "an inner/outer component"         end INNEROUTER;
  record UNSPECIFIED "a component without inner/outer" end UNSPECIFIED;
end InnerOuter;

public
uniontype Import "Import statements, different kinds"
  // A named import is a import statement to a variable ex;
  // NAMED_IMPORT("SI",Absyn.QUALIFIED("Modelica",Absyn.IDENT("SIunits")));
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

end Import;

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
    ArrayDim arrayDim "arrayDim ; Array dimensions, if any" ;
    Option<Modification> modification "modification ; Optional modification" ;
  end COMPONENT;

end Component;

public
uniontype EquationItem "Several component declarations can be grouped together in one
  `ElementSpec\' by writing them on the same line in the source.
  This type contains the information specific to one component."
  record EQUATIONITEM
    Equation equation_ "equation" ;
    Option<Comment> comment "comment" ;
  end EQUATIONITEM;

  record EQUATIONITEMANN
    Annotation annotation_ "annotation" ;
  end EQUATIONITEMANN;

end EquationItem;

public
uniontype AlgorithmItem "Info specific for an algorithm item."
  record ALGORITHMITEM
    Algorithm algorithm_ "algorithm" ;
    Option<Comment> comment "comment" ;
  end ALGORITHMITEM;

  record ALGORITHMITEMANN
    Annotation annotation_ "annotation" ;
  end ALGORITHMITEMANN;

end AlgorithmItem;

public
uniontype Equation "Information on one (kind) of equation, different constructors for different
     kinds of equations"
  record EQ_IF
    Exp ifExp "ifExp ; Conditional expression" ;
    list<EquationItem> equationTrueItems "equationTrueItems ; true branch" ;
    list<tuple<Exp, list<EquationItem>>> elseIfBranches "elseIfBranches" ;
    list<EquationItem> equationElseItems "equationElseItems Standard 2-side eqn" ;
  end EQ_IF;

  record EQ_EQUALS
    Exp leftSide "leftSide" ;
    Exp rightSide "rightSide Connect stmt" ;
  end EQ_EQUALS;

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

  // Part of MetaModelica extension. KS
  record ALG_TRY
    list<AlgorithmItem> tryBody;
  end ALG_TRY;

  record ALG_CATCH
    list<AlgorithmItem> catchBody;
  end ALG_CATCH;

  record ALG_THROW
  end ALG_THROW;

  record ALG_MATCHCASES
    list<Exp> switchCases;
  end ALG_MATCHCASES;

  record ALG_GOTO
    String labelName;
  end ALG_GOTO;

  record ALG_LABEL
    String labelName;
  end ALG_LABEL;

  record ALG_FAILURE
    AlgorithmItem equ;
  end ALG_FAILURE;
  //-------------------------------

end Algorithm;

public
uniontype Modification "Modifications are described by the `Modification\' type.  There
  are two forms of modifications: redeclarations and component
  modifications.
  - Modifications"
  record CLASSMOD
    list<ElementArg> elementArgLst;
    Option<Exp> expOption;
  end CLASSMOD;

end Modification;

public
uniontype ElementArg "Wrapper for things that modify elements, modifications and redeclarations"
  record MODIFICATION
    Boolean finalItem "finalItem" ;
    Each each_ "each" ;
    ComponentRef componentRef "componentRef" ;
    Option<Modification> modification "modification" ;
    Option<String> comment "comment" ;
  end MODIFICATION;

  record REDECLARATION
    Boolean finalItem "finalItem" ;
    RedeclareKeywords redeclareKeywords "redeclare  or replaceable " ;
    Each each_ "each" ;
    ElementSpec elementSpec "elementSpec" ;
    Option<ConstrainClass> constrainClass "class definition or declaration" ;
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
uniontype ElementAttributes "- Component attributes"
  record ATTR
    Boolean flowPrefix "flow" ;
    Boolean streamPrefix "stream" ;
//    Boolean inner_ "inner";
//    Boolean outer_ "outer";
    Variability variability "variability ; parameter, constant etc." ;
    Direction direction "direction" ;
    ArrayDim arrayDim "arrayDim" ;
  end ATTR;

end ElementAttributes;

public
uniontype Variability "Variability"
  record VAR end VAR;

  record DISCRETE end DISCRETE;

  record PARAM end PARAM;

  record CONST end CONST;

end Variability;

public
uniontype Direction "Direction"
  record INPUT  "direction is input"                                   end INPUT;
  record OUTPUT "direction is output"                                  end OUTPUT;
  record BIDIR  "direction is not specified, neither input nor output" end BIDIR;
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

  record BINARY   "Binary operations, e.g. a*b"
    Exp exp1;
    Operator op;
    Exp exp2;
  end BINARY;

  record UNARY  "Unary operations, e.g. -(x)"
    Operator op "op" ;
    Exp exp "exp Logical binary operations: and, or" ;
  end UNARY;

  record LBINARY
    Exp exp1 "exp1" ;
    Operator op "op" ;
    Exp exp2 ;
  end LBINARY;

  record LUNARY  "Logical unary operations: not"
    Operator op "op" ;
    Exp exp "exp Relations, e.g. a >= 0" ;
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


  record CODE  "Modelica AST Code constructors - MetaModelica extension"
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

    // The following two are only used internaly in the compiler
  record LIST "Part of MetaModelica extension"
    list<Exp> exps;
  end LIST;

  record VALUEBLOCK "valueblock expression"
    list<ElementItem> localDecls "local decls";
    ValueblockBody body "block body";
    Exp result "block end result";
  end VALUEBLOCK;

end Exp;

public
uniontype ValueblockBody "body of a valueblock"
   record VALUEBLOCKALGORITHMS
      list<AlgorithmItem> algorithmBody "algorithm body";
   end VALUEBLOCKALGORITHMS;

   record VALUEBLOCKMATCHCASE "a case in a {match,matchcontinue} expression"
      list<AlgorithmItem> patternMatching "does pattern matching against the input variables";
      list<EquationItem>  equationBody "need to be translated from equations to algorithms";
      list<AlgorithmItem> resultAssignments "assigns the result to the result variables";
   end VALUEBLOCKMATCHCASE;
end ValueblockBody;


uniontype Case "case in match or matchcontinue"
  record CASE
    Exp pattern " patterns to be matched ";
		list<ElementItem> localDecls " local decls ";
		list<EquationItem>  equations " equations [] for no equations ";
		Exp result " result ";
		Option<String> comment " comment after case like: case pattern string_comment ";
  end CASE;

  record ELSE "else in match or matchcontinue"
		list<ElementItem> localDecls " local decls ";
		list<EquationItem>  equations " equations [] for no equations ";
		Exp result " result ";
		Option<String> comment " comment after case like: case pattern string_comment ";
  end ELSE;
end Case;


uniontype MatchType
  record MATCH end MATCH;
  record MATCHCONTINUE end MATCHCONTINUE;
end MatchType;


uniontype CodeNode "The Code uniontype is used for Meta-programming. It originates from the Code quoting mechanism. See paper in Modelica2003 conference"
  record C_TYPENAME
    Path path;
  end C_TYPENAME;

  record C_VARIABLENAME
    ComponentRef componentRef;
  end C_VARIABLENAME;

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

  /*
  record FOR_ITER_FARG
    Exp from "from" ;
    Ident var "var" ;
    Exp to "to" ;
  end FOR_ITER_FARG;
  */

  record FOR_ITER_FARG
     Exp  exp "iterator expression";
     ForIterators iterators;
  end FOR_ITER_FARG;

end FunctionArgs;


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
  record NOSUB end NOSUB;

  record SUBSCRIPT
    Exp subScript "subScript" ;
  end SUBSCRIPT;

end Subscript;


uniontype ComponentRef "A component reference is the fully or partially qualified name of
  a component.  It is represented as a list of
  identifier--subscript pairs.
  - Component references and paths"
  record CREF_QUAL
    Ident name "name" ;
    list<Subscript> subScripts "subScripts" ;
    ComponentRef componentRef "componentRef" ;
  end CREF_QUAL;

  record CREF_IDENT
    Ident name "name" ;
    list<Subscript> subscripts "subscripts" ;
  end CREF_IDENT;

  record WILD end WILD;

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
  record R_MODEL end R_MODEL;
  record R_RECORD end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR "connector class" end R_CONNECTOR;
  record R_EXP_CONNECTOR "expandable connector class" end R_EXP_CONNECTOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION end R_FUNCTION;
  record R_OPERATOR "an operator" end R_OPERATOR;
  record R_OPERATOR_FUNCTION "an operator function" end R_OPERATOR_FUNCTION;
  record R_ENUMERATION end R_ENUMERATION;
  record R_PREDEFINED_INT end R_PREDEFINED_INT;
  record R_PREDEFINED_REAL end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOL end R_PREDEFINED_BOOL;
  record R_PREDEFINED_ENUM end R_PREDEFINED_ENUM;

  // MetaModelica
  record R_UNIONTYPE "MetaModelica uniontype" end R_UNIONTYPE;
  record R_METARECORD "Metamodelica record"  //MetaModelica extension, added by simbj
    Path name; //Name of the uniontype
    Integer index; //Index in the uniontype
  end R_METARECORD;
  record R_UNKNOWN "Helper restriction" end R_UNKNOWN; /* added by simbj */
end Restriction;

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
    Option<Annotation>   annotation_ ;
  end EXTERNALDECL;

end ExternalDecl;



/* "From here down, only Absyn helper functions should be present.
 Thus, no actual absyn uniontype definitions." */

protected import Util;
protected import Print;
protected import ModUtil;

public constant TimeStamp dummyTimeStamp = TIMESTAMP(0.0,0.0);

public constant Info dummyInfo = INFO("",false,0,0,0,0,dummyTimeStamp);

public function getNewTimeStamp "Function: getNewTimeStamp
generate a new timestamp with edittime>buildtime.
"
output TimeStamp ts;
algorithm
  ts := TIMESTAMP(0.0,1.0);
end getNewTimeStamp;

public function setTimeStampBool ""
  input TimeStamp its;
  input Boolean which "true for edit time, false for build time";
  output TimeStamp ots;
algorithm ots := matchcontinue(its,which)
  local Real timer;
  case(its,true)
    equation
      timer = System.getCurrentTime();
      its = setTimeStampEdit(its,timer);
    then
      its;
  case(its,false)
    equation
      timer = System.getCurrentTime();
      its = setTimeStampBuild(its,timer);
    then
      its;
end matchcontinue;
end setTimeStampBool;

// stefan
public function traverseEquation
"function: traverseEquation
	Traverses all subequations of an equation
	takes a function and an extra argument passed through the traversal"
	input Equation inEquation;
	input FuncTplToTpl inFunc;
	input TypeA inTypeA;
	output tuple<Equation, TypeA> outTpl;
	partial function FuncTplToTpl
	  input tuple<Equation, TypeA> inTpl;
	  output tuple<Equation, TypeA> outTpl;
	  replaceable type TypeA subtypeof Any;
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
        ((EQ_IF(e_1,_,_,_),arg_4)) = rel((eq,arg_3));
      then
        ((EQ_IF(e,eqilst1_1,eeqitlst_1,eqilst2_1),arg_4));
    case(eq as EQ_FOR(fis,eqilst),rel,arg)
      equation
        ((eqilst_1,arg_1)) = traverseEquationItemList(eqilst,rel,arg);
        ((EQ_FOR(fis_1,_),arg_2)) = rel((eq,arg_1));
      then
        ((EQ_FOR(fis_1,eqilst_1),arg_2));
    case(eq as EQ_WHEN_E(e,eqilst,eeqitlst),rel,arg)
      equation
        ((eqilst_1,arg_1)) = traverseEquationItemList(eqilst,rel,arg);
        ((eeqitlst_1,arg_2)) = traverseExpEqItemTupleList(eeqitlst,rel,arg_1);
        ((EQ_WHEN_E(e_1,_,_),arg_3)) = rel((eq,arg_2));
      then
        ((EQ_WHEN_E(e_1,eqilst_1,eeqitlst_1),arg_3));
    case(eq as EQ_FAILURE(ei),rel,arg)
      equation
        ((ei_1,arg_1)) = traverseEquationItem(ei,rel,arg);
        ((EQ_FAILURE(_),arg_2)) = rel((eq,arg_1));
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
"function: traverseEquationItem
	Traverses the equation inside an equationitem"
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
    case(EQUATIONITEM(eq,oc),rel,arg)
      equation
        ((eq_1,arg_1)) = traverseEquation(eq,rel,arg);
      then
        ((EQUATIONITEM(eq_1,oc),arg_1));
    case(ei,rel,arg) then ((ei,arg));
  end matchcontinue;
end traverseEquationItem;

// stefan
public function traverseEquationItemList
"function: traverseEquationItemList
	calls traverseEquationItem on every element of the given list"
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
algorithm
  outTpl := matchcontinue (inEquationItemList,inFunc,inTypeA)
    local
      list<EquationItem> cdr,cdr_1;
      FuncTplToTpl rel;
      TypeA arg,arg_1,arg_2;
      EquationItem ei,ei_1;
    case({},_,arg) then (({},arg));
    case(ei :: cdr,rel,arg)
      equation
        ((ei_1,arg_1)) = traverseEquationItem(ei,rel,arg);
        ((cdr_1,arg_2)) = traverseEquationItemList(cdr,rel,arg_1);
      then
        ((ei_1 :: cdr_1,arg_2));
  end matchcontinue;
end traverseEquationItemList;

// stefan
public function traverseExpEqItemTupleList
"function: traverseExpEqItemTupleList
	traverses a list of Exp * EquationItem list tuples
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
algorithm
  outTpl := matchcontinue (inList,inFunc,inTypeA)
    local
      FuncTplToTpl rel;
      TypeA arg,arg_1,arg_2;
      list<tuple<Exp, list<EquationItem>>> cdr,cdr_1;
      Exp e;
      list<EquationItem> eilst,eilst_1;
    case({},rel,arg) then (({},arg));
    case((e,eilst) :: cdr,rel,arg)
      equation
        ((eilst_1,arg_1)) = traverseEquationItemList(eilst,rel,arg);
        ((cdr_1,arg_2)) = traverseExpEqItemTupleList(cdr,rel,arg_1);
      then
        (((e,eilst_1) :: cdr_1,arg_2));
  end matchcontinue;
end traverseExpEqItemTupleList;

// stefan
public function traverseAlgorithm
"function: traverseAlgorithm
	Traverses all subalgorithms of an algorithm
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
    case(alg as ALG_IF(e,ailst1,eaitlst,ailst2),rel,arg)
      equation
        ((ailst1_1,arg1_1)) = traverseAlgorithmItemList(ailst1,rel,arg);
        ((eaitlst_1,arg2_1)) = traverseExpAlgItemTupleList(eaitlst,rel,arg1_1);
        ((ailst2_1,arg3_1)) = traverseAlgorithmItemList(ailst2,rel,arg2_1);
        ((ALG_IF(e_1,_,_,_),arg_1)) = rel((alg,arg3_1));
      then
        ((ALG_IF(e_1,ailst1_1,eaitlst_1,ailst2_1),arg_1));
    case(alg as ALG_FOR(fis,ailst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((ALG_FOR(fis_1,_),arg_1)) = rel((alg,arg1_1));
      then
        ((ALG_FOR(fis_1,ailst_1),arg_1));
    case(alg as ALG_WHILE(e,ailst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((ALG_WHILE(e_1,_),arg_1)) = rel((alg,arg1_1));
      then
        ((ALG_WHILE(e_1,ailst_1),arg_1));
    case(alg as ALG_WHEN_A(e,ailst,eaitlst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((eaitlst_1,arg2_1)) = traverseExpAlgItemTupleList(eaitlst,rel,arg1_1);
        ((ALG_WHEN_A(e_1,_,_),arg_1)) = rel((alg,arg2_1));
      then
        ((ALG_WHEN_A(e_1,ailst_1,eaitlst_1),arg_1));
    case(alg as ALG_TRY(ailst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((ALG_TRY(_),arg_1)) = rel((alg,arg1_1));
      then
        ((ALG_TRY(ailst_1),arg_1));
    case(alg as ALG_CATCH(ailst),rel,arg)
      equation
        ((ailst_1,arg1_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((ALG_CATCH(_),arg_1)) = rel((alg,arg1_1));
      then
        ((ALG_CATCH(ailst_1),arg_1));
    case(alg,rel,arg)
      equation
        ((alg_1,arg_1)) = rel((alg,arg));
      then
        ((alg_1,arg_1));
  end matchcontinue;
end traverseAlgorithm;

// stefan
public function traverseAlgorithmItem
"function: traverseAlgorithmItem
	traverses the Algorithm contained in an AlgorithmItem, if any
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
    case(ALGORITHMITEM(alg,oc),rel,arg)
      equation
        ((alg_1,arg_1)) = traverseAlgorithm(alg,rel,arg);
      then
        ((ALGORITHMITEM(alg_1,oc),arg_1));
    case(ai,_,arg) then ((ai,arg));
  end matchcontinue;
end traverseAlgorithmItem;

// stefan
public function traverseAlgorithmItemList
"function: traverseAlgorithmItemList
	calls traverseAlgorithmItem on each item in a list of AlgorithmItems"
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
  outTpl := matchcontinue (inAlgorithmItemList,inFunc,inTypeA)
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
  end matchcontinue;
end traverseAlgorithmItemList;

// stefan
public function traverseExpAlgItemTupleList
"function: traverseExpAlgItemTupleList
	traverses a list of Exp * AlgorithmItem list tuples
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
  outTpl := matchcontinue (inList,inFunc,inTypeA)
    local
      FuncTplToTpl rel;
      TypeA arg,arg_1,arg_2;
      list<tuple<Exp, list<AlgorithmItem>>> cdr,cdr_1;
      Exp e;
      list<AlgorithmItem> ailst,ailst_1;
    case({},rel,arg) then (({},arg));
    case((e,ailst) :: cdr,rel,arg)
      equation
        ((ailst_1,arg_1)) = traverseAlgorithmItemList(ailst,rel,arg);
        ((cdr_1,arg_2)) = traverseExpAlgItemTupleList(cdr,rel,arg_1);
      then
        (((e,ailst_1) :: cdr_1,arg_2));
  end matchcontinue;
end traverseExpAlgItemTupleList;

public function traverseExp
" Traverses all subexpressions of an Exp expression.
  Takes a function and an extra argument passed through the traversal.
  NOTE:This function was copied from Exp.traverseExp."
  input Exp inExp;
  input FuncTypeTplExpType_aToTplExpType_a inFuncTypeTplExpTypeAToTplExpTypeA;
  input Type_a inTypeA;
  output tuple<Exp, Type_a> outTplExpTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA:=
  matchcontinue (inExp,inFuncTypeTplExpTypeAToTplExpTypeA,inTypeA)
    local
      Exp e1_1,e,e1,e2_1,e2,e3_1,e_1,e3;
      Type_a ext_arg_1,ext_arg_2,ext_arg,ext_arg_3,ext_arg_4;
      Operator op_1,op;
      FuncTypeTplExpType_aToTplExpType_a rel;
      list<Exp> expl_1,expl;
      Path fn_1,fn,path_1,path;
      Boolean t_1,b_1,t,b,scalar_1,scalar;
      Integer i_1,i;
      Ident id_1,id;
    case ((e as UNARY(op,e1)),rel,ext_arg) /* unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((UNARY(op_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((UNARY(op_1,e1_1),ext_arg_2));
    case ((e as BINARY(e1,op,e2)),rel,ext_arg) /* binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((BINARY(_,op_1,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((BINARY(e1_1,op_1,e2_1),ext_arg_3));
    case ((e as LUNARY(op,e1)),rel,ext_arg) /* logic unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((LUNARY(op_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((LUNARY(op_1,e1_1),ext_arg_2));
    case ((e as LBINARY(e1,op,e2)),rel,ext_arg) /* logic binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((LBINARY(_,op_1,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((LBINARY(e1_1,op_1,e2_1),ext_arg_3));
    case ((e as RELATION(e1,op,e2)),rel,ext_arg) /* RELATION */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((RELATION(_,op_1,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((RELATION(e1_1,op_1,e2_1),ext_arg_3));

    case ((e as IFEXP(e1,e2,e3,elseIfBranch)),rel,ext_arg) /* if expression */
      local list<tuple<Exp,Exp>> elseIfBranch,elseIfBranch1;
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
				((elseIfBranch1,ext_arg_3)) = traverseExpElseIfBranch(elseIfBranch,rel,ext_arg_3);
        ((e_1,ext_arg_4)) = rel((e,ext_arg_3));
      then
        ((IFEXP(e1_1,e2_1,e3_1,elseIfBranch1),ext_arg_4));

    case ((e as CALL(cfn,fargs)),rel,ext_arg)
      local FunctionArgs fargs,fargs1,fargs2; ComponentRef cfn,cfn_1; Exp e_temp;
      equation
        ((fargs1,ext_arg_1)) = traverseExpFunctionArgs(fargs, rel, ext_arg);
        e_temp = CALL(cfn,fargs1);
        ((CALL(cfn_1,fargs2),ext_arg_2)) = rel((e_temp,ext_arg_1));
      then
        ((CALL(cfn_1,fargs2),ext_arg_2));

    //stefan
    case ((e as PARTEVALFUNCTION(cfn,fargs)),rel,ext_arg)
      local
        FunctionArgs fargs,fargs1;
        ComponentRef cfn,cfn_1;
      equation
        ((fargs1,ext_arg_1)) = traverseExpFunctionArgs(fargs,rel,ext_arg);
        ((PARTEVALFUNCTION(cfn_1,_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((PARTEVALFUNCTION(cfn_1,fargs1),ext_arg_2));

    case ((e as ARRAY(expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((ARRAY(_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((ARRAY(expl_1),ext_arg_2));

    case ((e as MATRIX(mexpl)),rel,ext_arg)
      local list<list<Exp>> mexpl,mexpl1;
      equation
        (mexpl1,ext_arg_1) = Util.listlistFoldMap(mexpl,rel,ext_arg);
        ((MATRIX(_),ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((MATRIX(mexpl1),ext_arg_2));

    case ((e as RANGE(e1,NONE,e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((RANGE(_,_,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((RANGE(e1_1,NONE,e2_1),ext_arg_3));
    case ((e as RANGE(e1,SOME(e2),e3)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
        ((RANGE(_,_,_),ext_arg_4)) = rel((e,ext_arg_3));
      then
        ((RANGE(e1_1,SOME(e3),e2_1),ext_arg_4));
    case ((e as TUPLE(expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((TUPLE(expl_1),ext_arg_2));
    case (e,rel,ext_arg)
      equation
        ((e_1,ext_arg_1)) = rel((e,ext_arg));
      then
        ((e_1,ext_arg_1));
  end matchcontinue;
end traverseExp;

// stefan
public function traverseExpList
"function: traverseExpList
	calls traverseExp on each element in the given list"
  input list<Exp> inExpList;
	input FuncTplToTpl inFunc;
	input TypeA inTypeA;
	output tuple<list<Exp>, TypeA> outTpl;
	partial function FuncTplToTpl
	  input tuple<Exp, TypeA> inTpl;
	  output tuple<Exp, TypeA> outTpl;
	  replaceable type TypeA subtypeof Any;
	end FuncTplToTpl;
	replaceable type TypeA subtypeof Any;
algorithm
  outTpl := matchcontinue (inExpList,inFunc,inTypeA)
    local
      FuncTplToTpl rel;
      TypeA arg,arg_1,arg_2;
      Exp e,e_1;
      list<Exp> cdr,cdr_1;
    case({},_,arg) then (({},arg));
    case(e :: cdr,rel,arg)
      equation
        ((e_1,arg_1)) = traverseExp(e,rel,arg);
        ((cdr_1,arg_2)) = traverseExpList(cdr,rel,arg_1);
      then
        ((e_1 :: cdr_1,arg_2));
  end matchcontinue;
end traverseExpList;

public function traverseExpElseIfBranch
"function traverseExpElseIfBranch
  Help function for traverseExp"
  input list<tuple<Exp,Exp>> inLst;
  input FuncTypeTplExpType_aToTplExpType_a rel;
  input Type_a ext_arg;
  output tuple<list<tuple<Exp,Exp>>, Type_a> outTplExpTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA:= matchcontinue(inLst,rel,ext_arg)
 	local Exp e1,e2,e11,e21;
 	  list<tuple<Exp,Exp>> lst;
    case({},rel,ext_arg) then (({},ext_arg));
    case((e1,e2)::inLst,rel,ext_arg) equation
      ((lst,ext_arg)) = traverseExpElseIfBranch(inLst,rel,ext_arg);
      ((e11,ext_arg)) = traverseExp(e1, rel, ext_arg);
      ((e21,ext_arg)) = traverseExp(e2, rel, ext_arg);
    then (((e11,e21)::lst,ext_arg));
  end matchcontinue;
end traverseExpElseIfBranch;

public function traverseExpFunctionArgs
"function traverseExpFunctionArgs
  Help function for traverseExp"
  input FunctionArgs inArgs;
  input FuncTypeTplExpType_aToTplExpType_a rel;
  input Type_a ext_arg;
  output tuple<FunctionArgs, Type_a> outTplExpTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA:= matchcontinue(inArgs,rel,ext_arg)
    local Exp e1,e2,e11,e21,forExp;
      list<NamedArg> nargs;
      list<Exp> expl,expl_1;
      ForIterators iterators;
    case(FUNCTIONARGS(expl,nargs),rel,ext_arg)
      equation
        ((expl_1,ext_arg)) = traverseExpPosArgs(expl,rel,ext_arg);
        ((nargs,ext_arg)) = traverseExpNamedArgs(nargs,rel,ext_arg);
      then ((FUNCTIONARGS(expl_1,nargs),ext_arg));

    case(inArgs as FOR_ITER_FARG(exp = forExp,iterators=iterators),rel,ext_arg)
      equation
        ((e1,ext_arg)) = traverseExp(forExp, rel, ext_arg);
        /* adrpo: TODO! travese iterators! */
      then((FOR_ITER_FARG(e1,iterators),ext_arg));
  end matchcontinue;
end traverseExpFunctionArgs;

protected function traverseExpNamedArgs "Help function to traverseExpFunctionArgs"
  input list<NamedArg> nargs;
  input FuncTypeTplExpType_aToTplExpType_a rel;
  input Type_a ext_arg;
  output tuple<list<NamedArg>, Type_a> outTplExpTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA:= matchcontinue(nargs,rel,ext_arg)
 	local Exp e1,e2,e11,e21;
 	 	Ident id;
 	  list<NamedArg> nargs;
 	  case({},rel,ext_arg)
		then (({},ext_arg));
 	  case(NAMEDARG(id,e1)::nargs,rel,ext_arg) equation
 	    ((e11,ext_arg)) = traverseExp(e1, rel, ext_arg);
 	    ((nargs,ext_arg)) = traverseExpNamedArgs(nargs,rel,ext_arg);
 	  then((NAMEDARG(id,e11)::nargs,ext_arg));
  end matchcontinue;
end traverseExpNamedArgs;

protected function traverseExpPosArgs "Help function to traverseExpFunctionArgs"
  input list<Exp> pargs;
  input FuncTypeTplExpType_aToTplExpType_a rel;
  input Type_a ext_arg;
  output tuple<list<Exp>, Type_a> outTplExpTypeA;
  partial function FuncTypeTplExpType_aToTplExpType_a
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeTplExpType_aToTplExpType_a;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA:= matchcontinue(pargs,rel,ext_arg)
 	local Exp e1,e2,e11,e21;
 	 	Ident id;
 	  list<Exp> pargs;
 	  case({},rel,ext_arg)
		then (({},ext_arg));
 	  case(e1::pargs,rel,ext_arg) equation
 	    ((e11,ext_arg)) = traverseExp(e1, rel, ext_arg);
 	    ((pargs,ext_arg)) = traverseExpPosArgs(pargs,rel,ext_arg);
 	  then((e11::pargs,ext_arg));
  end matchcontinue;
end traverseExpPosArgs;

public function makeIdentPathFromString ""
input String s;
output Path p;
algorithm p := IDENT(s);
end makeIdentPathFromString;

public function setTimeStampEdit "Function: getNewTimeStamp
Update current TimeStamp with a new Edit-time.
"
input TimeStamp its;
input Real editTime;
output TimeStamp ots;
algorithm ots := matchcontinue(its,editTime)
  local
    Real buildTime;
    TimeStamp ts;
  case(TIMESTAMP(buildTime,_),editTime)
    equation
      ts = TIMESTAMP(buildTime,editTime);
    then
      ts;
end matchcontinue;
end setTimeStampEdit;

public function setTimeStampBuild "Function: getNewTimeStamp
Update current TimeStamp with a new Build-time.
"
input TimeStamp its;
input Real buildTime;
output TimeStamp ots;
algorithm ots := matchcontinue(its,buildTime)
  local
    Real editTime;
    TimeStamp ts;
  case(TIMESTAMP(_,editTime),buildTime)
    equation
      ts = TIMESTAMP(buildTime,editTime);
    then
      ts;
end matchcontinue;
end setTimeStampBuild;

public function className "returns the class name of a Class as a Path"
  input Class cl;
  output Path name;
algorithm
  name := matchcontinue(cl)
  local String id;
    case(CLASS(name=id)) then IDENT(id);
  end matchcontinue;
end className;

public function elementSpecName "function: elementSpecName
  The ElementSpec type contans the name of the element, and this
  function extracts this name."
  input ElementSpec inElementSpec;
  output Ident outIdent;
algorithm
  outIdent:=
  matchcontinue (inElementSpec)
    local Ident n;
    case CLASSDEF(class_ = CLASS(name = n)) then n;
    case COMPONENTS(components = {COMPONENTITEM(component = COMPONENT(name = n))}) then n;
    case EXTENDS(path = _)
      equation
        print("#- Absyn.elementSpecName EXTENDS\n");
      then
        fail();
  end matchcontinue;
end elementSpecName;

public function printImportString "Function: printImportString
This function takes a Absyn.Import and prints it as a flat-string.
"
  input Import imp;
  output String ostring;
algorithm ostring := matchcontinue(imp)
  local Path path; String name;
  case(NAMED_IMPORT(name,_)) then name;
  case(QUAL_IMPORT(path))
    equation
      name = pathString(path);
    then name;
  case(UNQUAL_IMPORT(path))
    equation
      name = pathString(path);
    then name;
end matchcontinue;
end printImportString;

public function expCref "returns the componentRef of an expression if matches."
  input Exp exp;
  output ComponentRef cr;
algorithm
  cr := matchcontinue(exp)
    case(CREF(cr)) then cr;
  end matchcontinue;
end expCref;

public function crefExp "returns the componentRef of an expression if matches."
 input ComponentRef cr;
 output Exp exp;
algorithm
  exp := CREF(cr);
end crefExp;

public function expComponentRefStr ""
  input Exp aexp;
  output String outString;
algorithm outString := matchcontinue(aexp)
  local ComponentRef cr;
  case(CREF(cr)) then printComponentRefStr(cr);
  case(_) equation print("Error input for exp_Component_Ref_Str was not a string\n"); then fail();
end matchcontinue;
end expComponentRefStr;

public function printComponentRefStr ""
input ComponentRef cr;
output String ostring;
algorithm ostring := matchcontinue(cr)
  local
  String s1,s2;
  ComponentRef child;
  case(CREF_IDENT(s1,_)) then s1;
  case(CREF_QUAL(s1,_,child))
    equation
    s2 = printComponentRefStr(child);
    s1 = s1 +& "." +& s2;
then s1;
end matchcontinue;
end printComponentRefStr;

public function typeSpecEqual "
Author BZ 2009-01
Check wheter two type specs are equal or not.
"
  input TypeSpec a,b;
  output Boolean ob;
algorithm ob := matchcontinue(a,b)
  local
    Path p1,p2;
    Option<ArrayDim> oad1,oad2;
    list<TypeSpec> lst1,lst2;
  case(TPATH(p1,oad1), TPATH(p2,oad2))
    equation
      true = ModUtil.pathEqual(p1,p2);
      true = optArrayDimEqual(oad1,oad2);
    then true;
  case(TCOMPLEX(p1,lst1,oad1),TCOMPLEX(p2,lst2,oad2))
    equation
      true = ModUtil.pathEqual(p1,p2);
      true = Util.isListEqualWithCompareFunc(lst1,lst2,typeSpecEqual);
      true = optArrayDimEqual(oad1,oad2);
      then
        true;
  case(_,_) then false;
end matchcontinue;
end typeSpecEqual;

public function optArrayDimEqual "
Author BZ
helperfunction for typeSpecEqual
"
  input Option<ArrayDim> oad1,oad2;
  output Boolean b;
algorithm b:= matchcontinue(oad1,oad2)
  local
    list<Subscript> ad1,ad2;
  case(SOME(ad1),SOME(ad2))
    equation
    true = Util.isListEqualWithCompareFunc(ad1,ad2,subscriptEqual);
    then true;
  case(NONE,NONE) then true;
  case(_,_) then false;
end matchcontinue;
end optArrayDimEqual;

public function typeSpecPathString "function: pathString
  This function simply converts a Path to a string."
  input TypeSpec tp;
  output String s;
algorithm s := matchcontinue(tp)
  local Path p;
  case(TCOMPLEX(path = p)) then pathString(p);
  case(TPATH(path = p)) then pathString(p);
end matchcontinue;
end typeSpecPathString;

public function typeSpecPath
"convert TypeSpec to Path"
  input TypeSpec tp;
  output Path p;
algorithm
  p := matchcontinue(tp)
    local Path p;
    case(TCOMPLEX(path = p)) then p;
    case(TPATH(path = p)) then p;
  end matchcontinue;
end typeSpecPath;

public function pathString "function: pathString
  This function simply converts a Path to a string."
  input Path path;
  output String s;
algorithm
  s := pathString2(path, ".");
end pathString;

public function optPathString "function: optPathString
  Returns a path converted to string or an empty string if nothing exist"
  input Option<Path> inPathOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inPathOption)
    local
      Ident str;
      Path p;
    case (NONE) then "";
    case (SOME(p))
      equation
        str = pathString(p);
      then
        str;
  end matchcontinue;
end optPathString;

public function pathString2 "function:
  Helper function to pathString"
  input Path inPath;
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inPath,inString)
    local
      Ident s,ns,s1,ss,str;
      Path n;
    case (IDENT(name = s),_) then s;
    case (QUALIFIED(name = s,path = n),str)
      equation
        ns = pathString2(n, str);
        s1 = stringAppend(s, str);
        ss = stringAppend(s1, ns);
      then
        ss;
    case(FULLYQUALIFIED(path=n),str)
      equation
        ss = pathString2(n,str);
      then ss;
  end matchcontinue;
end pathString2;

public function pathTwoLastIdents "Returns the two last idens of a path"
  input Path p;
  output Path twoLast;
  protected
  Ident id2,id1;
algorithm
  id2 := pathLastIdent(p);
  id1 := pathLastIdent(stripLast(p));
  twoLast := QUALIFIED(id1,IDENT(id2));
end pathTwoLastIdents;

public function pathLastIdent "function: pathLastIdent
  Returns the last ident (After last dot) in a path"
  input Path inPath;
  output Ident outIdent;
algorithm
  outIdent:=
  matchcontinue (inPath)
    local
      Ident res,n;
      Path p;
     case (FULLYQUALIFIED(path = p))
      equation
        res = pathLastIdent(p);
      then
        res;
    case (QUALIFIED(path = p))
      equation
        res = pathLastIdent(p);
      then
        res;
    case (IDENT(name = n)) then n;
  end matchcontinue;
end pathLastIdent;

public function pathFirstIdent "function: pathFirstIdent
  Returns the first ident (before first dot) in a path"
  input Path inPath;
  output Ident outIdent;
algorithm
  outIdent:=
  matchcontinue (inPath)
    local
      Ident n;
      Path p;
    case (FULLYQUALIFIED(path = p)) then pathFirstIdent(p);
    case (QUALIFIED(name = n,path = p)) then n;
    case (IDENT(name = n)) then n;
  end matchcontinue;
end pathFirstIdent;

public function pathSuffixOf "returns true if suffix_path is a suffix of path"
	input Path suffix_path;
	input Path path;
	output Boolean res;
algorithm
  res := matchcontinue(suffix_path,path)
  local Path p;
    case(suffix_path,path)
      equation
      true = ModUtil.pathEqual(suffix_path,path);
      then true;
    case(suffix_path,FULLYQUALIFIED(path = p))
      then pathSuffixOf(suffix_path,p);
    case(suffix_path,QUALIFIED(name=_,path = p))
      then pathSuffixOf(suffix_path,p);
    case(_,_) then false;
  end matchcontinue;
end pathSuffixOf;

public function pathToStringList
input Path path;
output list<String> outPaths;
algorithm outPaths := matchcontinue(path)
    local
      String n;
      Path p;
      list<String> strings;
    case (FULLYQUALIFIED(path = p)) then pathToStringList(p);
    case (QUALIFIED(name = n,path = p))
      equation
        strings = pathToStringList(p);
        strings = listAppend(strings,{n});
        then
          strings;
    case (IDENT(name = n)) then {n};
end matchcontinue;
end pathToStringList;

public function pathPrefixOf "returns true if prefix_path is a prefix of path"
	input Path prefix_path;
	input Path path;
	output Boolean res;
algorithm
  res := matchcontinue(prefix_path,path)
  local Path p;
    case(prefix_path,path)
      equation
      true = ModUtil.pathEqual(prefix_path,path);
      then true;
    case(prefix_path,path)
      then pathPrefixOf(prefix_path,stripLast(path));
    case(_,_) then false;
  end matchcontinue;
end pathPrefixOf;


public function removePrefix "removes the prefix_path from path, and returns the rest of path"
	input Path prefix_path;
	input Path path;
	output Path newPath;
algorithm
  newPath := matchcontinue(prefix_path,path)
  local Path p,p2; Ident id1,id2;
    case (p,FULLYQUALIFIED(p2))
      then removePrefix(p,p2);
    case (QUALIFIED(name=id1,path=p),QUALIFIED(name=id2,path=p2)) equation
      equality(id1=id2);
      then removePrefix(p,p2);
      case(IDENT(id1),QUALIFIED(name=id2,path=p2)) equation
        equality(id1=id2);
        then p2;
  end matchcontinue;
end removePrefix;

public function pathContains "
Author BZ,
checks if one Absyn.IDENT(..) is contained in path.
"
input Path p1,p2;
output Boolean b;
algorithm b := matchcontinue(p1,p2)
  local
    String str1,str2;
    Path qp;
    Boolean b1,b2;
  case(IDENT(str1),IDENT(str2))
      then stringEqual(str1,str2);
  case(QUALIFIED(str1,qp),(p2 as IDENT(str2)))
    equation
      b1 = stringEqual(str1,str2);
      b2 = pathContains(qp,p2);
      b1 = boolOr(b1,b2);
      then
        b1;
  case(FULLYQUALIFIED(qp),p2) then pathContains(qp,p2);
  end matchcontinue;
end pathContains;

public function pathContainedIn "This function checks if subPath is contained in path.
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
  	// A suffix, e.g. C.D in A.B.C.D
    case (subPath,path)
      equation
        true=pathSuffixOf(subPath,path);
      then path;
     // strip last ident of path and recursively check if suffix.
    case (subPath,path)
      local Ident ident; Path newPath;
      equation
        ident = pathLastIdent(path);
        newPath = stripLast(path);
        newPath=pathContainedIn(subPath,newPath);
      then joinPaths(newPath,IDENT(ident));

        // strip last ident of subpath and recursively check if suffix.
    case (subPath,path)
      local Ident ident; Path newSubPath;
      equation
        ident = pathLastIdent(subPath);
        newSubPath = stripLast(subPath);
        newSubPath=pathContainedIn(newSubPath,path);
      then joinPaths(newSubPath,IDENT(ident));
  end matchcontinue;
end pathContainedIn;

public function getCrefsFromSubs "
Author BZ 2009-08
Function for getting ComponentRefs out from Subscripts
"
  input list<Subscript> subs;
  output list<ComponentRef> crefs;
algorithm crefs := matchcontinue(subs)
  local
    list<ComponentRef> crefs1;
    Exp exp;
    case({}) then {};
    case(NOSUB::subs) then getCrefsFromSubs(subs);
    case(SUBSCRIPT(exp)::subs)
      equation
        crefs1 = getCrefsFromSubs(subs);
        crefs = getCrefFromExp(exp,true);
        crefs = listAppend(crefs,crefs1);
        //crefs = Util.listUnionOnTrue(crefs,crefs1,crefEqual);
        then
          crefs;
end matchcontinue;
end getCrefsFromSubs;

public function getCrefFromExp "
  Returns a flattened list of the
  component references in an expression"
  input Exp inExp;
  input Boolean checkSubs;
  output list<ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst:=
  matchcontinue (inExp,checkSubs)
    local
      ComponentRef cr;
      list<ComponentRef> l1,l2,res,res1,l3;
      ComponentCondition e1,e2,e3;
      Operator op;
      list<tuple<ComponentCondition, ComponentCondition>> e4;
      FunctionArgs farg;
      list<list<ComponentRef>> res2;
      list<ComponentCondition> expl;
      list<list<ComponentCondition>> expll;
    case (INTEGER(value = _),checkSubs) then {};
    case (REAL(value = _),checkSubs) then {};
    case (STRING(value = _),checkSubs) then {};
    case (BOOL(value = _),checkSubs) then {};
    case (CREF(componentRef = cr),false) then {cr};
    case (CREF(componentRef = (cr as WILD)),_) then {};

      case (CREF(componentRef = (cr)),true)
        local
          list<Subscript> subs;
        equation
          subs = getSubsFromCref(cr);
          l1 = getCrefsFromSubs(subs);
      then cr::l1;

    case (BINARY(exp1 = e1,op = op,exp2 = e2),checkSubs)
      equation
        l1 = getCrefFromExp(e1,checkSubs);
        l2 = getCrefFromExp(e2,checkSubs);
        res = listAppend(l1, l2);
      then
        res;
    case (UNARY(op = op,exp = e1),checkSubs)
      equation
        res = getCrefFromExp(e1,checkSubs);
      then
        res;
    case (LBINARY(exp1 = e1,op = op,exp2 = e2),checkSubs)
      equation
        l1 = getCrefFromExp(e1,checkSubs);
        l2 = getCrefFromExp(e2,checkSubs);
        res = listAppend(l1, l2);
      then
        res;
    case (LUNARY(op = op,exp = e1),checkSubs)
      equation
        res = getCrefFromExp(e1,checkSubs);
      then
        res;
    case (RELATION(exp1 = e1,op = op,exp2 = e2),checkSubs)
      equation
        l1 = getCrefFromExp(e1,checkSubs);
        l2 = getCrefFromExp(e2,checkSubs);
        res = listAppend(l1, l2);
      then
        res;
    case (IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3,elseIfBranch = e4),checkSubs)
      equation
        l1 = getCrefFromExp(e1,checkSubs);
        l2 = getCrefFromExp(e2,checkSubs);
        res1 = listAppend(l1, l2);
        l3 = getCrefFromExp(e3,checkSubs);
        res = listAppend(res1, l3) "TODO elseif\'s e4" ;
      then
        res;
    case (CALL(functionArgs = farg),checkSubs)
      equation
        res = getCrefFromFarg(farg,checkSubs) "res = Util.listMap(expl,get_cref_from_exp)" ;
      then
        res;
    case (PARTEVALFUNCTION(functionArgs = farg),checkSubs)
      equation
        res = getCrefFromFarg(farg,checkSubs);
      then
        res;
    case (ARRAY(arrayExp = expl),checkSubs)
      local list<list<ComponentRef>> res1;
      equation
        res1 = Util.listMap1(expl, getCrefFromExp,checkSubs);
        res = Util.listFlatten(res1);
      then
        res;
    case (MATRIX(matrix = expll),checkSubs)
      local list<list<list<ComponentRef>>> res1;
      equation
        res1 = Util.listListMap1(expll, getCrefFromExp,checkSubs);
        res2 = Util.listFlatten(res1);
        res = Util.listFlatten(res2);
      then
        res;
    case (RANGE(start = e1,step = SOME(e3),stop = e2),checkSubs)
      equation
        l1 = getCrefFromExp(e1,checkSubs);
        l2 = getCrefFromExp(e2,checkSubs);
        res1 = listAppend(l1, l2);
        l3 = getCrefFromExp(e3,checkSubs);
        res = listAppend(res1, l3);
      then
        res;
    case (RANGE(start = e1,step = NONE,stop = e2),checkSubs)
      equation
        l1 = getCrefFromExp(e1,checkSubs);
        l2 = getCrefFromExp(e2,checkSubs);
        res = listAppend(l1, l2);
      then
        res;
    case (END,checkSubs) then {};

    case (TUPLE(expressions = expl),checkSubs)
      local list<list<ComponentRef>> crefll;
      equation
        crefll = Util.listMap1(expl,getCrefFromExp,checkSubs);
        res = Util.listFlatten(crefll);
      then
        res;
  end matchcontinue;
end getCrefFromExp;

public function getCrefFromFarg "function: getCrefFromFarg
  Returns the flattened list of all component references
  present in a list of function arguments."
  input FunctionArgs inFunctionArgs;
  input Boolean checkSubs;
  output list<ComponentRef> outComponentRefLst;
algorithm outComponentRefLst := matchcontinue (inFunctionArgs,checkSubs)
    local
      list<list<ComponentRef>> l1,l2;
      list<ComponentRef> fl1,fl2,res;
      list<ComponentCondition> expl;
      list<NamedArg> nargl;
    case (FUNCTIONARGS(args = expl,argNames = nargl),checkSubs)
      equation
        l1 = Util.listMap1(expl, getCrefFromExp,checkSubs);
        fl1 = Util.listFlatten(l1);
        l2 = Util.listMap1(nargl, getCrefFromNarg,checkSubs);
        fl2 = Util.listFlatten(l2);
        res = listAppend(fl1, fl2);
      then
        res;
  end matchcontinue;
end getCrefFromFarg;

// stefan
public function appendFunctionArgs
"function: appendFunctionArgs
	appends 2 function args into one
	does not work for FOR_ITER_FARG"
	input FunctionArgs inFunctionArgs1;
	input FunctionArgs inFunctionArgs2;
	output FunctionArgs outFunctionArgs;
algorithm
  outFunctionArgs := matchcontinue(inFunctionArgs1,inFunctionArgs2)
    local
      list<Exp> eargs1,eargs2,eargs;
      list<NamedArg> nargs1,nargs2,nargs;
      FunctionArgs res;
    case(FUNCTIONARGS(eargs1,nargs1),FUNCTIONARGS(eargs2,nargs2))
      equation
        eargs = listAppend(eargs1,eargs2);
        nargs = listAppend(nargs1,nargs2);
        res = FUNCTIONARGS(eargs,nargs);
      then
        res;
    case(_,_) then fail();
  end matchcontinue;
end appendFunctionArgs;

// stefan
public function getClassByName
"function: getClassByName
	searches through a list of Classes and returns the one with the given name
	fails if list is empty (no class found)"
	input Ident inIdent;
	input list<Class> inClassList;
	output Class outClass;
algorithm
  outClass := matchcontinue(inIdent,inClassList)
    local
      list<Class> cdr;
      Ident name,n;
      Class cl;
    case(name,(cl as CLASS(n,_,_,_,_,_,_)) :: _)
      equation
        true = n ==& name;
      then cl;
    case(name,cl :: cdr) then getClassByName(name,cdr);
    case (_,{}) then fail();
  end matchcontinue;
end getClassByName;

// stefan
public function renameClass
"function: renameClass
	returns the same class with a new name"
	input Ident inIdent;
	input Class inClass;
	output Class outClass;
algorithm
  outClass := matchcontinue(inIdent,inClass)
    local
      Class c;
      Ident name,n;
      Boolean pp,fp,ep;
      Restriction r;
      ClassDef cd;
      Info i;
    case(name,CLASS(n,pp,fp,ep,r,cd,i))
      equation
        c = CLASS(name,pp,fp,ep,r,cd,i);
      then
        c;
  end matchcontinue;
end renameClass;

// stefan
public function getClassParts
"function: getClassParts
	returns the classparts of a class definition"
	input Class inClass;
	output list<ClassPart> outClassPartList;
algorithm
  outClassPartList := matchcontinue(inClass)
    local
      list<ClassPart> parts;
    case(CLASS(_,_,_,_,_,PARTS(parts,_),_)) then parts;
    case(_) then {};
  end matchcontinue;
end getClassParts;

// stefan
public function setClassParts
"function: setClassParts
	sets the classparts of a class to the given ones"
	input list<ClassPart> inClassPartList;
	input Class inClass;
	output Class outClass;
algorithm
  outClass := matchcontinue(inClassPartList,inClass)
    local
      list<ClassPart> parts;
      Ident n;
      Boolean pp,fp,ep;
      Restriction r;
      Info i;
      Option<String> c;
      Class cl;
    case(parts,CLASS(n,pp,fp,ep,r,PARTS(_,c),i))
      equation
        cl = CLASS(n,pp,fp,ep,r,PARTS(parts,c),i);
      then
        cl;
  end matchcontinue;
end setClassParts;

// stefan
public function getPublicElementsFromClassParts
"function: getPublicElementsFromClassParts
	returns the element list from a public class part"
	input list<ClassPart> inClassPartList;
	output list<ElementItem> outElementItemList;
algorithm
  outElementItemList := matchcontinue(inClassPartList)
    local
      list<ElementItem> elts,elts_1,elts_2;
      list<ClassPart> cdr;
    case({}) then {};
    case(PUBLIC(elts) :: cdr)
      equation
        elts_1 = getPublicElementsFromClassParts(cdr);
        elts_2 = listAppend(elts,elts_1);
      then
        elts_2;
    case(_ :: cdr)
      equation
        elts = getPublicElementsFromClassParts(cdr);
      then
        elts;
  end matchcontinue;
end getPublicElementsFromClassParts;

// stefan
public function getAlgorithmItems
"function: getAlgorithmItems
	retreives a list of AlgorithmItems from a given Class"
	input Class inClass;
	output list<AlgorithmItem> outAlgorithmItemList;
algorithm
  outAlgorithmItemList := matchcontinue (inClass)
    local
      Class cl;
    case(cl)
      local
        list<AlgorithmItem> algs;
        list<ClassPart> parts;
      equation
        parts = getClassParts(cl);
        algs = getAlgorithmItems2(parts);
      then
        algs;
    case(_) then {};
  end matchcontinue;
end getAlgorithmItems;

// stefan
protected function getAlgorithmItems2
"function: getAlgorithmItems2
	helper function to getAlgorithmItems"
	input list<ClassPart> inClassPartList;
	output list<AlgorithmItem> outAlgorithmItemList;
algorithm
  outAlgorithmItemList := matchcontinue (inClassPartList)
    local
      list<ClassPart> cdr;
      list<AlgorithmItem> algs;
    case({}) then {};
    case(ALGORITHMS(contents=algs) :: cdr)
      local
        list<AlgorithmItem> algs2;
      equation
        algs2 = getAlgorithmItems2(cdr);
      then
        listAppend(algs,algs2);
    case(_ :: cdr) then getAlgorithmItems2(cdr);
  end matchcontinue;
end getAlgorithmItems2;

// stefan
public function setAlgorithmItems
"function: setAlgorithmItems
	sets the algorithm part of a class to the input list of algorithm items"
	input list<AlgorithmItem> inAlgorithmItemList;
	input Class inClass;
	output Class outClass;
algorithm
  outClass := matchcontinue (inAlgorithmItemList,inClass)
    local
      Class oc;
      list<AlgorithmItem> algs;
      list<ClassPart> parts,parts_1;
      Ident n;
      Boolean pp,fp,ep;
      Restriction r;
      ClassDef cd,cd_1;
      Info i;
      Option<String> c;
    case(algs,CLASS(n,pp,fp,ep,r,cd as PARTS(parts,c),i))
      equation
        parts_1 = setAlgorithmItems2(algs,parts);
        cd_1 = PARTS(parts_1,c);
        oc = CLASS(n,pp,fp,ep,r,cd_1,i);
      then oc;
    case(_,_) then inClass;
  end matchcontinue;
end setAlgorithmItems;

// stefan
protected function setAlgorithmItems2
"function: setAlgorithmItems2
	helper function to setAlgorithmItems"
	input list<AlgorithmItem> inAlgorithmItemList;
	input list<ClassPart> inClassPartList;
	output list<ClassPart> outClassPartList;
algorithm
  outClassPartList := matchcontinue (inAlgorithmItemList,inClassPartList)
    local
      list<AlgorithmItem> algs,prev;
      ClassPart part;
      list<ClassPart> cdr,cdr_1;
    case(_,{}) then {};
    case(algs,(part as PUBLIC(_)) :: cdr)
      equation
        cdr_1 = setAlgorithmItems2(algs,cdr);
      then part :: cdr_1;
    case(algs,(part as PROTECTED(_)) :: cdr)
      equation
        cdr_1 = setAlgorithmItems2(algs,cdr);
      then part :: cdr_1;
    case(algs,(part as EQUATIONS(_)) :: cdr)
      equation
        cdr_1 = setAlgorithmItems2(algs,cdr);
      then part :: cdr_1;
    case(algs,(part as INITIALEQUATIONS(_)) :: cdr)
      equation
        cdr_1 = setAlgorithmItems2(algs,cdr);
      then part :: cdr_1;
    case(algs,(part as INITIALALGORITHMS(_)) :: cdr)
      equation
        cdr_1 = setAlgorithmItems2(algs,cdr);
      then part :: cdr_1;
    case(algs,(part as EXTERNAL(_,_)) :: cdr)
      equation
        cdr_1 = setAlgorithmItems2(algs,cdr);
      then part :: cdr_1;
    case(algs,(part as ALGORITHMS(contents=prev)) :: cdr)
      local
        ClassPart part_1;
      equation
        part_1 = ALGORITHMS(algs);
        cdr_1 = setAlgorithmItems2(algs,cdr);
      then part_1 :: cdr_1;
  end matchcontinue;
end setAlgorithmItems2;

// stefan
public function extractArgs
"function: extractArgs
	retrieves the positional and named arguments from a FunctionArgs"
	input FunctionArgs inFunctionArgs;
	output list<Exp> outArgs;
	output list<NamedArg> outNamedArgs;
algorithm
  (outArgs,outNamedArgs) := matchcontinue(inFunctionArgs)
    local
      list<Exp> expl;
      list<NamedArg> nargl;
    case(FUNCTIONARGS(args = expl,argNames = nargl)) then (expl, nargl);
  end matchcontinue;
end extractArgs;

// stefan
public function getNamedFuncArgNamesAndValues
"function: getNamedFuncArgNames
	returns the names from a list of NamedArgs as a string list"
	input list<NamedArg> inNamedArgList;
	output list<String> outStringList;
	output list<Exp> outExpList;
algorithm
  (outStringList,outExpList) := matchcontinue ( inNamedArgList )
    local
      list<NamedArg> cdr;
      String s;
      Exp e;
    case ({})  then ({},{});
    case (NAMEDARG(argName=s,argValue=e) :: cdr)
      local
        list<String> slst;
        list<Exp> elst;
      equation
        (slst,elst) = getNamedFuncArgNamesAndValues(cdr);
      then
        (s :: slst, e :: elst);
  end matchcontinue;
end getNamedFuncArgNamesAndValues;

protected function getCrefFromNarg "function: getCrefFromNarg
  Returns the flattened list of all component references
  present in a list of named function arguments."
  input NamedArg inNamedArg;
  input Boolean checkSubs;
  output list<ComponentRef> outComponentRefLst;
algorithm outComponentRefLst := matchcontinue (inNamedArg,checkSubs)
    local
      list<ComponentRef> res;
      ComponentCondition exp;
    case (NAMEDARG(argValue = exp),checkSubs)
      equation
        res = getCrefFromExp(exp,checkSubs);
      then
        res;
  end matchcontinue;
end getCrefFromNarg;

public function joinPaths "function: joinPaths
  This function joins two paths"
  input Path inPath1;
  input Path inPath2;
  output Path outPath;
algorithm
  outPath:=
  matchcontinue (inPath1,inPath2)
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
  end matchcontinue;
end joinPaths;

public function joinPathsOpt "function: joinPathsOpt
  This function joins two paths when the first one might be NONE"
  input Option<Path> inPath1;
  input Path inPath2;
  output Path outPath;
algorithm
  outPath := matchcontinue (inPath1,inPath2)
    local
      Ident str;
      Path p2,p_1,p;
    case (NONE(), p2) then p2;
    case (SOME(IDENT(name = str)),p2) then QUALIFIED(str,p2);
    case (SOME(QUALIFIED(name = str,path = p)),p2)
      equation
        p_1 = joinPaths(p, p2);
      then
        QUALIFIED(str,p_1);
    case(SOME(FULLYQUALIFIED(p)),p2) then joinPaths(p,p2);
    case(SOME(p),FULLYQUALIFIED(p2)) then joinPaths(p,p2);
  end matchcontinue;
end joinPathsOpt;

public function selectPathsOpt "function: selectPathsOpt
  This function selects the second path when the first one
  is NONE otherwise it will select the first one."
  input Option<Path> inPath1;
  input Path inPath2;
  output Path outPath;
algorithm
  outPath := matchcontinue (inPath1,inPath2)
    local
      Path p;
    case (NONE(), p) then p;
    case (SOME(p),_) then p;
  end matchcontinue;
end selectPathsOpt;

public function optPathAppend "
Author BZ, 2009-01
Appends a path to optional 'base'-path.
"
  input Option<Path> basePath;
  input Path lastPath;
  output Path mergedPath;
algorithm mergedPath := matchcontinue(basePath, lastPath)
  case(NONE,lastPath) then lastPath;
  case(SOME(mergedPath), lastPath) then pathAppendList({mergedPath,lastPath});
end matchcontinue;
end optPathAppend;

public function pathAppendList "function: pathAppendList
  author Lucian
  This function joins a path list"
  input list<Path> inPathLst;
  output Path outPath;
algorithm
  outPath:=
  matchcontinue (inPathLst)
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
  end matchcontinue;
end pathAppendList;

public function stripLast "function: stripLast
  Returns the path given as argument to
  the function minus the last ident."
  input Path inPath;
  output Path outPath;
algorithm
  outPath:=
  matchcontinue (inPath)
    local
      Ident str;
      Path p_1,p;
    case (IDENT(name = _)) then fail();
    case (QUALIFIED(name = str,path = IDENT(name = _))) then IDENT(str);
    case (QUALIFIED(name = str,path = p))
      equation
        p_1 = stripLast(p);
      then
        QUALIFIED(str,p_1);
    case (FULLYQUALIFIED(p)) equation
      p_1 = stripLast(p);
    then FULLYQUALIFIED(p_1);
  end matchcontinue;
end stripLast;

public function crefStripLast "function: stripLast
  Returns the path given as argument to
  the function minus the last ident."
  input ComponentRef inPath;
  output ComponentRef outPath;
algorithm
  outPath:=
  matchcontinue (inPath)
    local
      Ident str;
      ComponentRef p_1,p;
      list<Subscript> subs;
    case (CREF_IDENT(name = _)) then fail();
    case (CREF_QUAL(name = str,subScripts = subs, componentRef = CREF_IDENT(name = _))) then CREF_IDENT(str,subs);
    case (CREF_QUAL(name = str,subScripts = subs,componentRef = p))
      equation
        p_1 = crefStripLast(p);
      then
        CREF_QUAL(str,subs,p_1);
  end matchcontinue;
end crefStripLast;


public function splitQualAndIdentPath "
Author BZ 2008-04
Function for splitting Absynpath into two parts,
qualified part, and ident part (all_but_last, last);
"
  input Path inPath;
  output Path outPath1;
  output Path outPath2;
algorithm (outPath1,outPath2) := matchcontinue(inPath)
  local
    Path qPath,curPath,identPath;
    String s1,s2;
  case (QUALIFIED(name = s1,path = IDENT(name = s2))) then(IDENT(s1),IDENT(s2));
  case(QUALIFIED(name=s1, path=qPath)) equation
    (curPath,identPath) = splitQualAndIdentPath(qPath);
  then (QUALIFIED(s1,curPath),identPath);
  case(FULLYQUALIFIED(qPath))
    equation
    (curPath,identPath) = splitQualAndIdentPath(qPath);
    then
       (curPath,identPath);
  case(qPath)
    equation
      print(" Failure in: " +& pathString(qPath) +& "\n");
    then
      fail();
  case(_) equation print(" failure in splitQualAndIdentPath\n"); then fail();
end matchcontinue;
end splitQualAndIdentPath;

public function stripFirst "function: stripFirst
  Returns the path given as argument
  to the function minus the first ident."
  input Path inPath;
  output Path outPath;
algorithm
  outPath:=
  matchcontinue (inPath)
    local
      Path p;
    case (QUALIFIED(name = _,path = p)) then p;
    case(FULLYQUALIFIED(p)) then stripFirst(p);
  end matchcontinue;
end stripFirst;

public function crefToPath "function: crefToPath
  This function converts a ComponentRef to a Path, if possible.
  If the component reference contains subscripts, it will silently fail."
  input ComponentRef inComponentRef;
  output Path outPath;
algorithm
  outPath:=
  matchcontinue (inComponentRef)
    local
      Ident i;
      Path p;
      ComponentRef c;
    case CREF_IDENT(name = i,subscripts = {}) then IDENT(i);
    case CREF_QUAL(name = i,subScripts = {},componentRef = c)
      equation
        p = crefToPath(c);
      then
        QUALIFIED(i,p);
  end matchcontinue;
end crefToPath;

public function pathToCref "function: pathToCref
  This function converts a Path to a ComponentRef."
  input Path inPath;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inPath)
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
      then pathToCref(p);
  end matchcontinue;
end pathToCref;

public function crefFirstIdent "
Returns the base-name of the Absyn.componentReference"
  input ComponentRef inComponentRef;
  output String str;
algorithm str := matchcontinue(inComponentRef)
  local String ret;
  case(CREF_IDENT(ret,_)) then ret;
  case(CREF_QUAL(ret,_,_)) then ret;
end matchcontinue;
end crefFirstIdent;

public function crefIsIdent "
Returns the base-name of the Absyn.componentReference"
  input ComponentRef inComponentRef;
  output Boolean bol;
algorithm bol := matchcontinue(inComponentRef)
  case(CREF_IDENT(_,_)) then true;
  case(CREF_QUAL(_,_,_)) then false;
end matchcontinue;
end crefIsIdent;

public function crefLastSubs "function: crefLastSubs
  Return the last subscripts of an Absyn.ComponentRef"
  input ComponentRef inComponentRef;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,res;
      ComponentRef cr;
    case (CREF_IDENT(name = id,subscripts= subs)) then subs;
    case (CREF_QUAL(componentRef = cr))
      equation
        res = crefLastSubs(cr);
      then
        res;
  end matchcontinue;
end crefLastSubs;

public function getSubsFromCref "
Author: BZ, 2009-09
 Extract subscripts of crefs.
"
  input ComponentRef cr;
  output list<Subscript> subscripts;

algorithm subscripts := matchcontinue(cr)
  local
    list<Subscript> subs2;
    ComponentRef child;
  case(CREF_IDENT(_,subs2)) then subs2;
  case(CREF_QUAL(_,subs2,child))
    equation
      subscripts = getSubsFromCref(child);
      subscripts = Util.listUnionOnTrue(subscripts,subs2, subscriptEqual);
    then
      subscripts;
end matchcontinue;
end getSubsFromCref;

// stefan
public function buildExpFromCref
"function: buildExpFromCref
	Creates a CREF expression from a ComponentRef"
	input ComponentRef inComponentRef;
	output Exp outExp;
algorithm
  outExp := CREF(inComponentRef);
end buildExpFromCref;

// stefan
public function buildNamedArgList
"function: buildNamedArgList
	builds a list of NamedArg from a list of arg names and args"
	input list<Ident> inIdentList;
	input list<Exp> inExpList;
	output list<NamedArg> outNamedArgList;
algorithm
  outNamedArgList := matchcontinue(inIdentList,inExpList)
    local
      list<Ident> icdr;
      list<Exp> ecdr;
      Ident i;
      Exp e;
      list<NamedArg> ncdr;
      NamedArg n;
    case({},_) then {};
    case(_,{}) then {};
    case(i :: icdr,e :: ecdr)
      equation
        n = NAMEDARG(i,e);
        ncdr = buildNamedArgList(icdr,ecdr);
      then
        n :: ncdr;
  end matchcontinue;
end buildNamedArgList;

// stefan
public function getExpListFromNamedArgList
"function: getExpListFromNamedArgList
	returns the expressions in the named arguments without the argument names"
	input list<NamedArg> inNamedArgList;
	output list<Exp> outExpList;
algorithm
  outExpList := matchcontinue(inNamedArgList)
    local
      list<NamedArg> cdr;
      Exp e;
      list<Exp> res;
    case({}) then {};
    case(NAMEDARG(_,e) :: cdr)
      equation
        res = getExpListFromNamedArgList(cdr);
      then
        e :: res;
  end matchcontinue;
end getExpListFromNamedArgList;

// stefan
public function crefGetLastIdent
"function: crefGetLastIdent
	Gets the last ident in a ComponentRef"
	input ComponentRef inComponentRef;
	output ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      ComponentRef cref,cref_1;
      Ident id;
      list<Subscript> subs;
    case(CREF_IDENT(id,subs)) then CREF_IDENT(id,subs);
    case(CREF_QUAL(id,subs,cref))
      equation
        cref_1 = crefGetLastIdent(cref);
      then
        cref_1;
  end matchcontinue;
end crefGetLastIdent;

// stefan
public function crefSetLastIdent
"function: crefSetLastIdent
	Sets the last ident in a ComponentRef to the given ComponentRef"
	input ComponentRef inComponentRef; // cref to change
	input ComponentRef inNewIdent; // ident to replace the old one
	output ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inNewIdent,inComponentRef)
    local
      ComponentRef cref,cref1,cref2,cref_1;
      Ident id;
      list<Subscript> subs;
    case(CREF_IDENT(id,subs),cref) then cref;
    case(CREF_QUAL(id,subs,cref1),cref2)
      equation
        cref = crefSetLastIdent(cref1,cref2);
        cref_1 = CREF_QUAL(id,subs,cref);
      then
        cref_1;
  end matchcontinue;
end crefSetLastIdent;

public function crefStripLastSubs "function: crefStripLastSubs
  Strips the last subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,s;
      ComponentRef cr_1,cr;
    case (CREF_IDENT(name = id,subscripts= subs)) then CREF_IDENT(id,{});
    case (CREF_QUAL(name= id,subScripts= s,componentRef = cr))
      equation
        cr_1 = crefStripLastSubs(cr);
      then
        CREF_QUAL(id,s,cr_1);
  end matchcontinue;
end crefStripLastSubs;

public function joinCrefs "function: joinCrefs
  This function joins two ComponentRefs."
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident id;
      list<Subscript> sub;
      ComponentRef cr2,cr_1,cr;
    case (CREF_IDENT(name = id,subscripts = sub),cr2) then CREF_QUAL(id,sub,cr2);
    case (CREF_QUAL(name = id,subScripts = sub,componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        CREF_QUAL(id,sub,cr_1);
  end matchcontinue;
end joinCrefs;

public function crefGetFirst "function: crefGetFirst
  Returns first ident from a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef)
    local Ident i;
    case (CREF_IDENT(name = i)) then CREF_IDENT(i,{});
    case (CREF_QUAL(name = i)) then CREF_IDENT(i,{});
  end matchcontinue;
end crefGetFirst;

public function crefStripFirst "function: crefStripFirst
  Strip the first ident from a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef)
    local ComponentRef cr;
    case (CREF_QUAL(componentRef =cr )) then cr;
  end matchcontinue;
end crefStripFirst;

public function restrString "function: restrString
  Maps a class restriction to the corresponding string for printing"
  input Restriction inRestriction;
  output String outString;
algorithm
  outString:=
  matchcontinue (inRestriction)
    case R_CLASS() then "CLASS";
    case R_MODEL() then "MODEL";
    case R_RECORD() then "RECORD";
    case R_BLOCK() then "BLOCK";
    case R_CONNECTOR() then "CONNECTOR";
    case R_EXP_CONNECTOR() then "EXPANDABLE CONNECTOR";
    case R_TYPE() then "TYPE";
    case R_PACKAGE() then "PACKAGE";
    case R_FUNCTION() then "FUNCTION";
    case R_PREDEFINED_INT() then "PREDEFINED_INT";
    case R_PREDEFINED_REAL() then "PREDEFINED_REAL";
    case R_PREDEFINED_STRING() then "PREDEFINED_STRING";
    case R_PREDEFINED_BOOL() then "PREDEFINED_BOOL";

    /* MetaModelica restriction */
    case R_UNIONTYPE() then "UNIONTYPE";
  end matchcontinue;
end restrString;

public function printRestr "function: printRestr
  This is a utility function for printing an Absyn.Restriction."
  input Restriction restr;
  Ident str;
algorithm
  str := restrString(restr);
  Print.printBuf(str);
end printRestr;

public function lastClassname "function: lastClassname
  Returns the path (=name) of the last class in a program"
  input Program inProgram;
  output Path outPath;
algorithm
  outPath:=
  matchcontinue (inProgram)
    local
      Ident id;
      list<Class> lst;
    case (PROGRAM(classes = lst))
      equation
        CLASS(id,_,_,_,_,_,_) = Util.listLast(lst);
      then
        IDENT(id);
  end matchcontinue;
end lastClassname;

public function classFilename "function classFilename
  author: PA
  Retrieves the filename where the class is stored."
  input Class inClass;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClass)
    local Ident filename;
    case (CLASS(info = INFO(fileName = filename))) then filename;
  end matchcontinue;
end classFilename;

public function setClassFilename "function setClassFilename
  author: PA
  Sets the filename where the class is stored."
  input Class inClass;
  input String inString;
  input TimeStamp build1;
  output Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inString,build1)
    local
      Ident n,filename;
      Boolean p,f,e;
      Restriction r;
      ClassDef body;
      TimeStamp build;
    case (CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = body),filename,build)
      then CLASS(n,p,f,e,r,body,INFO(filename,false,0,0,0,0, build)  );
  end matchcontinue;
end setClassFilename;

public function emptyClassInfo ""
output Info info;
algorithm
  info := dummyInfo; //INFO("",false,0,0,0,0,TIMESTAMP(0.0,0.0));
end emptyClassInfo;

public function setClassName "function setClassFilename
  author: BZ
  Sets the name of the class"
  input Class inClass;
  input String newName;
  output Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,newName)
    local
      Ident n;
      Boolean p,f,e;
      Restriction r;
      ClassDef body;
      Info nfo;
    case (CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = body),newName)
      then CLASS(newName,p,f,e,r,body,INFO("",false,0,0,0,0, TIMESTAMP(0.0,0.0))  );
  end matchcontinue;
end setClassName;

public function crefEqual "function: crefEqual
  Checks if the name of a ComponentRef is
  equal to the name of another ComponentRef, including subscripts.
 See also crefEqualNoSubs.
 "
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (cr1,cr2)
    local
      Ident id,id2;
      list<Subscript> ss1,ss2;
    case (CREF_IDENT(name = id,subscripts=ss1),CREF_IDENT(name = id2,subscripts = ss2))
      equation
        equality(id = id2);
        true = subscriptsEqual(ss1,ss2);
      then
        true;
    case (CREF_QUAL(name = id,subScripts = ss1, componentRef = cr1),CREF_QUAL(name = id2,subScripts = ss2, componentRef = cr2))
      equation
        equality(id = id2);
        true = subscriptsEqual(ss1,ss2);
        true = crefEqual(cr1, cr2);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end crefEqual;

public function subscriptsEqual "
Checks if two subscript lists are equal.
See also crefEqual.
"
input list<Subscript> ss1;
input list<Subscript> ss2;
output Boolean equal;
algorithm
  equal := matchcontinue(ss1,ss2)
  local Exp e1,e2;
    case({},{}) then true;
    case(NOSUB()::ss1, NOSUB()::ss2) then subscriptsEqual(ss1,ss2);
    case(SUBSCRIPT(e1)::ss1,SUBSCRIPT(e2)::ss2) equation
      true = expEqual(e1,e2);
    then subscriptsEqual(ss1,ss2);
    case(_,_) then false;
  end matchcontinue;
end subscriptsEqual;

public function crefEqualNoSubs "
  Checks if the name of a ComponentRef is
  equal to the name of another ComponentRef without checking subscripts.
  See also crefEqual."
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (cr1,cr2)
    local
      Ident id,id2;
    case (CREF_IDENT(name = id),CREF_IDENT(name = id2))
      equation
        equality(id = id2);
      then
        true;
    case (CREF_QUAL(name = id,componentRef = cr1),CREF_QUAL(name = id2,componentRef = cr2))
      equation
        equality(id = id2);
        true = crefEqualNoSubs(cr1, cr2);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end crefEqualNoSubs;

public function isPackageRestriction "function isPackageRestriction
  checks if the provided parameter is a package or not"
  input Restriction inRestriction;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inRestriction)
    case (R_PACKAGE()) then true;
    case (_) then false;
  end matchcontinue;
end isPackageRestriction;

public function subscriptEqual "
Author BZ, 2009-01
Check if two subscripts are equal.
"
input Subscript ss1,ss2;
output Boolean b;
algorithm b:= matchcontinue(ss1,ss2)
  local Exp e1,e2;
  case(NOSUB,NOSUB) then true;
  case(SUBSCRIPT(e1),SUBSCRIPT(e2)) then expEqual(e1,e2);
  case(_,_) then false;
  end matchcontinue;
end subscriptEqual;

public function expEqual "Returns true if two expressions are equal"
  input Exp exp1;
  input Exp exp2;
  output Boolean equal;
algorithm
  equal := matchcontinue(exp1,exp2)
    local Exp x, y;
    case (x, y) equation equality(x = y);          then true;
    case (x, y) equation failure(equality(x = y)); then false;
  end matchcontinue;
end expEqual;

public function eachEqual "Returns true if two each attributes are equal"
  input Each each1;
  input Each each2;
  output Boolean equal;
algorithm
  equal := matchcontinue(each1,each2)
    case(NON_EACH(),NON_EACH()) then true;
    case(EACH(),EACH()) then true;
    case(_,_) then false;
  end matchcontinue;
end eachEqual;


/* adrpo - 2007-02-20 equality can be implemented using structural equality!
public function expEqual "Returns true if two expressions are equal"
  input Exp exp1;
  input Exp exp2;
  output Boolean equal;
algorithm
  equal := matchcontinue(exp1,exp2)
    case(INTEGER(i1),INTEGER(i2))
      local Integer i1,i2;
        then intEq(i1,i2);
    case(REAL(r1),REAL(r2))
      local Real r1,r2;
        then realEq(r1,r2);
    case(CREF(cr1),CREF(cr2))
      local ComponentRef cr1,cr2;
        then crefEqual(cr1,cr2);
    case(STRING(s1),STRING(s2))
      local String s1,s2;
        then stringEqual(s1,s2);
    case (BOOL(b1),BOOL(b2))
      local Boolean b1,b2;
        then Util.boolEqual(b1,b2);
    case (BINARY(e11,_,e12),BINARY(e21,_,e22))
      local Exp e11,e12,e21,e22;
      then boolAnd(expEqual(e11,e21),expEqual(e12,e22));
    case (LBINARY(e11,_,e12),LBINARY(e21,_,e22))
      local Exp e11,e12,e21,e22;
      then boolAnd(expEqual(e11,e21),expEqual(e12,e22));
    case (UNARY(_,e1),UNARY(_,e2))
      local Exp e1,e2;
        then expEqual(e1,e2);
    case (LUNARY(_,e1),LUNARY(_,e2))
      local Exp e1,e2;
        then expEqual(e1,e2);
    case (RELATION(e11,_,e12),RELATION(e21,_,e22))
      local Exp e12,e11,e21,e22;
        then boolAnd(expEqual(e11,e21),expEqual(e12,e22));
    case (IFEXP(e11,e12,e13,_),IFEXP(e21,e22,e23,_))
      local  Exp e12,e11,e13,e21,e22,e23; Boolean b1,b2,b3; equation
        b1 = expEqual(e11,e21);
        b2 = expEqual(e12,e22);
        b3 = expEqual(e13,e23);
        equal = Util.boolAndList({b1,b2,b3});
        then equal;
    case (CALL(cref1,args1),CALL(cref2,args2))
      local ComponentRef cref1,cref2; FunctionArgs args1,args2; Boolean b1,b2; list<Boolean> blst; equation
        b1 = crefEqual(cref1,cref2);
        b2 = functionArgsEqual(args1,args2);
        equal = Util.boolAndList({b1,b2});
      then equal;
    case (ARRAY(args1),ARRAY(args2))
      local ComponentRef cref1,cref2; list<Exp> args1,args2; Boolean b1; list<Boolean> blst; equation
        blst = Util.listThreadMap(args1,args2,expEqual);
        equal = Util.boolAndList(blst);
      then equal;

    case (MATRIX(args1),MATRIX(args2))
      local ComponentRef cref1,cref2; list<list<Exp>> args1,args2; Boolean b1; list<list<Boolean>> blst; equation
        blst = Util.listListThreadMap(args1,args2,expEqual);
        equal = Util.boolAndList(Util.listFlatten(blst));
      then equal;

    case (RANGE(e11,SOME(e12),e13),RANGE(e21,SOME(e22),e23))
      local Exp e11,e12,e13,e21,e22,e23;
      Boolean b1,b2,b3;
      equation
         b1 = expEqual(e11,e21);
         b2 = expEqual(e12,e22);
         b3 = expEqual(e13,e23);
         equal = Util.boolAndList({b1,b2,b3});
      then equal;

    case (RANGE(e11,_,e13),RANGE(e21,_,e23))
      local Exp e11,e12,e13,e21,e22,e23;
      Boolean b1,b2,b3;
      equation
        b1 = expEqual(e11,e21);
        b3 = expEqual(e13,e23);
        equal = Util.boolAndList({b1,b3});
      then equal;
    case (TUPLE(args1),TUPLE(args2))
      local ComponentRef cref1,cref2; list<Exp> args1,args2; Boolean b1; list<Boolean> blst; equation
        blst = Util.listThreadMap(args1,args2,expEqual);
        equal = Util.boolAndList(blst);
      then equal;
    case (END(),END()) then true;
    case(CODE(_),CODE(_)) equation
      print("expEqual CODE not implemented yet.\n");
      then false;
    case(_,_) then false;
  end matchcontinue;
end expEqual;

*/

protected function functionArgsEqual "Returns true if two FunctionArgs are equal"
  input FunctionArgs args1;
  input FunctionArgs args2;
  output Boolean equal;
algorithm
 equal := matchcontinue(args1,args2)
   case (FUNCTIONARGS(expl1,_),FUNCTIONARGS(expl2,_))
      local ComponentRef cref1,cref2; list<Exp> expl1,expl2; Boolean b1; list<Boolean> blst;
        equation
        blst = Util.listThreadMap(expl1,expl2,expEqual);
        equal = Util.boolAndList(blst);
      then equal;

   case(_,_) then false;
 end matchcontinue;
end functionArgsEqual;

public function getClassName "function getClassName
  author: adrpo
  gets the name of the class."
  input Class inClass;
  output String outName;
algorithm
  outName:=
  matchcontinue (inClass)
    local
      Ident n,filename;
      Boolean p,f,e;
      Restriction r;
      ClassDef body;
    case (CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = body))
    then n;
  end matchcontinue;
end getClassName;

public function mergeElementAttributes "
Author BZ 2008-05
Function that is used with Derived classes,
merge the derived ElementAttributes with the optional ElementAttributes returned from ~instClass~.
"
  input ElementAttributes ele;
  input Option<ElementAttributes> oEle;
  output Option<ElementAttributes> outoEle;
algorithm outoEle := matchcontinue(ele, oEle)
  local
    Boolean b1,b2,bStream1,bStream2,bStream;
    Variability v1,v2;
    Direction d1,d2;
    ArrayDim ad1,ad2;
  case(ele, NONE ) then SOME(ele);
  case(ATTR(b1,bStream1,v1,d1,ad1), SOME(ATTR(b2,bStream2,v2,d2,ad2)))
    equation
      b1 = boolOr(b1,b2);
      bStream = boolOr(bStream1,bStream2);
      v1 = propagateAbsynVariability(v1,v2);
      d1 = propagateAbsynDirection(d1,d2);
    then
      SOME(ATTR(b1,bStream,v1,d1,ad1));
end matchcontinue;
end mergeElementAttributes;

protected function propagateAbsynVariability "
Helper function for mergeElementAttributes
"
  input Variability v1;
  input Variability v2;
  output Variability v3;
algorithm v3 := matchcontinue(v1,v2)
  case(v1,VAR) then v1;
  case(v1,_) then v1;
end matchcontinue;
end propagateAbsynVariability;

protected function propagateAbsynDirection "
Helper function for mergeElementAttributes
"
  input Direction v1;
  input Direction v2;
  output Direction v3;
algorithm v3 := matchcontinue(v1,v2)
  case(BIDIR(),v2) then v2;
  case(v1,BIDIR()) then v1;
  case(v1,v2)
    equation
      equality(v1 = v2);
    then v1;
  case(_,_)
    equation
      print(" failure in propagateAbsynDirection, inner outer mismatch");
    then
      fail();
end matchcontinue;
end propagateAbsynDirection;

protected function findIteratorInAlgorithmItem
  input String inString;
  input AlgorithmItem inAlgItem;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inAlgItem)
    local
      list<tuple<ComponentRef, Integer>> lst;
      Algorithm alg;
      String id;
      case (id,ALGORITHMITEM(algorithm_=alg))
        equation
          lst=findIteratorInAlgorithm(id,alg);
        then lst;
      case (_,_) then {};
  end matchcontinue;
end findIteratorInAlgorithmItem;

protected function findIteratorInAlgorithm
  input String inString;
  input Algorithm inAlg;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inAlg)
    local
      String id;
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2,lst_3,lst_4;
      Exp e_1,e_2;
      list<AlgorithmItem> algLst_1,algLst_2;
      list<tuple<Exp, list<AlgorithmItem>>> elseIfBranch;
      list<ForIterator> forIterators;
      FunctionArgs funcArgs;
      AlgorithmItem algItem;
      Boolean bool;

      case (id,ALG_ASSIGN(e_1,e_2))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,ALG_IF(e_1,algLst_1,elseIfBranch,algLst_2))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInAlgorithmItemLst(id,algLst_1);
          lst_3=findIteratorInElseIfBranch(id,elseIfBranch);
          lst_4=findIteratorInAlgorithmItemLst(id,algLst_2);
          lst=Util.listFlatten({lst_1,lst_2,lst_3,lst_4});
        then lst;
/*      case (id, ALG_FOR(forIterators,algLst_1))
        equation
          true=iteratorPresentAmongIterators(id,forIterators);
          lst=findIteratorInForIteratorsBounds(id,forIterators);
        then lst;
      case (id, ALG_FOR(forIterators,algLst_1))
        equation
          false=iteratorPresentAmongIterators(id,forIterators);
          lst_1=findIteratorInAlgorithmItemLst(id,algLst_1);
          lst_2=findIteratorInForIteratorsBounds(id,forIterators);
          lst=listAppend(lst_1,lst_2);
        then lst; */
      case (id, ALG_FOR(forIterators,algLst_1))
        equation
          lst_1=findIteratorInAlgorithmItemLst(id,algLst_1);
          (bool,lst_2)=findIteratorInForIteratorsBounds2(id,forIterators);
          lst_1=Util.if_(bool, {}, lst_1);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id, ALG_WHILE(e_1,algLst_1))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInAlgorithmItemLst(id,algLst_1);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,ALG_WHEN_A(e_1,algLst_1,elseIfBranch))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInAlgorithmItemLst(id,algLst_1);
          lst_3=findIteratorInElseIfBranch(id,elseIfBranch);
          lst=Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
      case (id,ALG_NORETCALL(_,funcArgs))
        equation
          lst=findIteratorInFunctionArgs(id,funcArgs);
        then lst;
      case (id,ALG_TRY(algLst_1))
        equation
          lst=findIteratorInAlgorithmItemLst(id,algLst_1);
        then lst;
      case (id,ALG_CATCH(algLst_1))
        equation
          lst=findIteratorInAlgorithmItemLst(id,algLst_1);
        then lst;
      case (_,_) then {};
  end matchcontinue;
end findIteratorInAlgorithm;

public function findIteratorInAlgorithmItemLst"
Used by Inst.instForStatement
"
//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<AlgorithmItem> inAlgItemLst;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inAlgItemLst)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<AlgorithmItem> rest;
      AlgorithmItem algItem;
      case (id,{}) then {};
      case (id,algItem::rest)
        equation
          lst_1=findIteratorInAlgorithmItem(id,algItem);
          lst_2=findIteratorInAlgorithmItemLst(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end matchcontinue;
end findIteratorInAlgorithmItemLst;

protected function findIteratorInElseIfBranch //This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<tuple<Exp, list<AlgorithmItem>>> inElseIfBranch;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inElseIfBranch)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2,lst_3;
      String id;
      list<tuple<Exp, list<AlgorithmItem>>> rest;
      Exp exp;
      list<AlgorithmItem> algItemLst;
      case (id,{}) then {};
      case (id,(exp,algItemLst)::rest)
        equation
          lst_1=findIteratorInExp(id,exp);
          lst_2=findIteratorInAlgorithmItemLst(id,algItemLst);
          lst_3=findIteratorInElseIfBranch(id,rest);
          lst=Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
  end matchcontinue;
end findIteratorInElseIfBranch;

protected function findIteratorInElseIfExpBranch //This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<tuple<Exp, Exp>> inElseIfBranch;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inElseIfBranch)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2,lst_3;
      String id;
      list<tuple<Exp, Exp>> rest;
      Exp e_1,e_2;
      case (id,{}) then {};
      case (id,(e_1,e_2)::rest)
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInExp(id,e_2);
          lst_3=findIteratorInElseIfExpBranch(id,rest);
          lst=Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
  end matchcontinue;
end findIteratorInElseIfExpBranch;

public function findIteratorInFunctionArgs
  input String inString;
  input FunctionArgs inFunctionArgs;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inFunctionArgs)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<Exp> expLst;
      list<NamedArg> namedArgs;
      Exp exp;
      list<ForIterator> forIterators;
      Boolean bool;
      case (id,FUNCTIONARGS(expLst,namedArgs))
        equation
          lst_1=findIteratorInExpLst(id,expLst);
          lst_2=findIteratorInNamedArgs(id,namedArgs);
          lst=listAppend(lst_1,lst_2);
        then lst;
/*      case (id, FOR_ITER_FARG(exp,forIterators))
        equation
          true=iteratorPresentAmongIterators(id,forIterators);
          lst=findIteratorInForIteratorsBounds(id,forIterators);
        then lst;
      case (id, FOR_ITER_FARG(exp,forIterators))
        equation
          false=iteratorPresentAmongIterators(id,forIterators);
          lst_1=findIteratorInExp(id,exp);
          lst_2=findIteratorInForIteratorsBounds(id,forIterators);
          lst=listAppend(lst_1,lst_2);
        then lst;    */
      case (id, FOR_ITER_FARG(exp,forIterators))
        equation
          lst_1=findIteratorInExp(id,exp);
          (bool,lst_2)=findIteratorInForIteratorsBounds2(id,forIterators);
          lst_1=Util.if_(bool, {}, lst_1);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end matchcontinue;
end findIteratorInFunctionArgs;

/*protected function iteratorPresentAmongIterators
  input String inString;
  input list<ForIterator> inForIterators;
  output Boolean outBool;
algorithm
    outBool:=matchcontinue(inString,inForIterators)
    local
      String id,id1;
      Boolean bool;
      list<ForIterator> rest;
      case (id,{}) then false;
      case (id,(id1,_)::rest)
        equation
          equality(id=id1);
        then true;
      case (id,(id1,_)::rest)
        equation
          failure(equality(id=id1));
          bool=iteratorPresentAmongIterators(id,rest);
        then bool;
  end matchcontinue;
end iteratorPresentAmongIterators;      */

public function findIteratorInExpLst//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<Exp> inExpLst;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inExpLst)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<Exp> rest;
      Exp exp;
      case (id,{}) then {};
      case (id,exp::rest)
        equation
          lst_1=findIteratorInExp(id,exp);
          lst_2=findIteratorInExpLst(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end matchcontinue;
end findIteratorInExpLst;

protected function findIteratorInExpLstLst//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<list<Exp>> inExpLstLst;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inExpLstLst)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<list<Exp>> rest;
      list<Exp> expLst;
      case (id,{}) then {};
      case (id,expLst::rest)
        equation
          lst_1=findIteratorInExpLst(id,expLst);
          lst_2=findIteratorInExpLstLst(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end matchcontinue;
end findIteratorInExpLstLst;

protected function findIteratorInNamedArgs
  input String inString;
  input list<NamedArg> inNamedArgs;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inNamedArgs)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<NamedArg> rest;
      Exp exp;
      case (id,{}) then {};
      case (id,NAMEDARG(_,exp)::rest)
        equation
          lst_1=findIteratorInExp(id,exp);
          lst_2=findIteratorInNamedArgs(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end matchcontinue;
end findIteratorInNamedArgs;

/*protected function findIteratorInForIteratorsBounds
  input String inString;
  input list<ForIterator> inForIterators;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inForIterators)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<ForIterator> rest;
      Exp exp;
      case (id,{}) then {};
      case (id,(_,NONE)::rest)
        equation
          lst=findIteratorInForIteratorsBounds(id,rest);
        then lst;
      case (id,(_,SOME(exp))::rest)
        equation
          lst_1=findIteratorInExp(id,exp);
          lst_2=findIteratorInForIteratorsBounds(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end matchcontinue;
end findIteratorInForIteratorsBounds; */

protected function findIteratorInForIteratorsBounds2 "
This is a fixed version of the function; it stops looking for the iterator when it finds another iterator
with the same name. It also returns information about whether it has found such an iterator"
  input String inString;
  input list<ForIterator> inForIterators;
  output Boolean outBool;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    (outBool,outLst):=matchcontinue(inString,inForIterators)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2;
      Boolean bool;
      String id, id_1;
      list<ForIterator> rest;
      Exp exp;
      case (_,{}) then (false,{});
      case (id,(id_1,_)::_)
        equation
          equality(id=id_1);
        then
          (true,{});
      case (id,(_,NONE)::rest)
        equation
          (bool,lst)=findIteratorInForIteratorsBounds2(id,rest);
        then (bool,lst);
      case (id,(_,SOME(exp))::rest)
        equation
          lst_1=findIteratorInExp(id,exp);
          (bool,lst_2)=findIteratorInForIteratorsBounds2(id,rest);
          lst=listAppend(lst_1,lst_2);
        then (bool,lst);
  end matchcontinue;
end findIteratorInForIteratorsBounds2;

public function findIteratorInExp
  input String inString;
  input Exp inExp;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inExp)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2,lst_3,lst_4;
      String id;
      Exp e_1,e_2,e_3;
      list<Exp> expLst;
      list<list<Exp>> expLstLst;
      ComponentRef cref;
      list<tuple<Exp, Exp>> elseIfBranch;
      FunctionArgs funcArgs;
      Option<Exp> expOpt;

      case(id, CREF(cref))
        equation
          lst=findIteratorInCRef(id,cref);
        then lst;
      case(id, BINARY(e_1,_,e_2))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case(id, UNARY(_,e_1))
        equation
          lst=findIteratorInExp(id,e_1);
        then lst;
      case(id, LBINARY(e_1,_,e_2))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case(id, LUNARY(_,e_1))
        equation
          lst=findIteratorInExp(id,e_1);
        then lst;
      case(id, RELATION(e_1,_,e_2))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case(id, IFEXP(e_1,e_2,e_3,elseIfBranch))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInExp(id,e_2);
          lst_3=findIteratorInExp(id,e_3);
          lst_4=findIteratorInElseIfExpBranch(id,elseIfBranch);
          lst=Util.listFlatten({lst_1,lst_2,lst_3,lst_4});
        then lst;
      case (id,CALL(_,funcArgs))
        equation
          lst=findIteratorInFunctionArgs(id,funcArgs);
        then lst;
      // stefan
      case (id, PARTEVALFUNCTION(_,funcArgs))
        equation
          lst=findIteratorInFunctionArgs(id,funcArgs);
        then lst;
      case (id, ARRAY(expLst))
        equation
          lst=findIteratorInExpLst(id,expLst);
        then lst;
      case (id, MATRIX(expLstLst))
        equation
          lst=findIteratorInExpLstLst(id,expLstLst);
        then lst;
      case(id, RANGE(e_1,expOpt,e_2))
        equation
          lst_1=findIteratorInExp(id,e_1);
          lst_2=findIteratorInExpOpt(id,expOpt);
          lst_3=findIteratorInExp(id,e_2);
          lst=Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
      case (id, TUPLE(expLst))
        equation
          lst=findIteratorInExpLst(id,expLst);
        then lst;
      case (id, LIST(expLst))
        equation
          lst=findIteratorInExpLst(id,expLst);
        then lst;
      case(_,_) then {};
  end matchcontinue;
end findIteratorInExp;

protected function findIteratorInExpOpt
  input String inString;
  input Option<Exp> inExpOpt;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inExpOpt)
    local
      list<tuple<ComponentRef, Integer>> lst;
      String id;
      Exp exp;
      case (id,NONE) then {};
      case (id,SOME(exp))
        equation
          lst=findIteratorInExp(id,exp);
        then lst;
  end matchcontinue;
end findIteratorInExpOpt;

public function findIteratorInCRef "
The most important among \"findIteratorIn...\" functions -- they all use this one in the end
"
  input String inString;
  input ComponentRef inCref;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inCref)
    local
      list<tuple<ComponentRef, Integer>> lst,lst_1,lst_2,lst_3;
      String id,name;
      list<Subscript> subLst;
      ComponentRef cref;
      list<Integer> intLst;
      case(id, CREF_IDENT(name,subLst))
        equation
        intLst=findIteratorInSubscripts(id,subLst,1);
        lst=combineCRefAndIntLst(CREF_IDENT(name,{}),intLst);
        then lst;
      case(id, CREF_QUAL(name,subLst,cref))
        equation
        intLst=findIteratorInSubscripts(id,subLst,1);
        lst_1=combineCRefAndIntLst(CREF_IDENT(name,{}),intLst);
        lst_2=findIteratorInCRef(id,cref);
        lst_3=qualifyCRefIntLst(name,subLst,lst_2);
        lst=listAppend(lst_1,lst_3);
        then lst;
      case (_,WILD()) then {};
  end matchcontinue;
end findIteratorInCRef;

protected function findIteratorInSubscripts
  input String inString;
  input list<Subscript> inSubLst;
  input Integer inInt;
  output list<Integer> outIntLst;
algorithm
    outLst:=matchcontinue(inString,inSubLst,inInt)
    local
      list<Integer> lst;
      Integer n, n_1;
      String id,name;
      list<Subscript> rest;
      Subscript sub;
      case (_,{},_) then {};
      case (id,SUBSCRIPT(CREF(CREF_IDENT(name,{})))::rest,n)
        equation
          equality(id=name);
          n_1=n+1;
          lst=findIteratorInSubscripts(id,rest,n_1);
        then n::lst;
      case (id,_::rest,n)
        equation
          n_1=n+1;
          lst=findIteratorInSubscripts(id,rest,n_1);
        then lst;
  end matchcontinue;
end findIteratorInSubscripts;

protected function combineCRefAndIntLst
  input ComponentRef inCRef;
  input list<Integer> inIntLst;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inCRef,inIntLst)
    local
      ComponentRef cref;
      list<Integer> rest;
      Integer i;
      list<tuple<ComponentRef, Integer>> lst;
      case (_,{}) then {};
      case (cref,i::rest)
        equation
          lst=combineCRefAndIntLst(cref,rest);
        then (cref,i)::lst;
  end matchcontinue;
end combineCRefAndIntLst;

protected function qualifyCRefIntLst
  input String inString;
  input list<Subscript> inSubLst;
  input list<tuple<ComponentRef, Integer>> inLst;
  output list<tuple<ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inSubLst,inLst)
    local
      ComponentRef cref;
      String name;
      list<Subscript> subLst;
      list<tuple<ComponentRef, Integer>> rest,lst;
      Integer i;
      case (_,_,{}) then {};
      case (name,subLst,(cref,i)::rest)
        equation
          lst=qualifyCRefIntLst(name,subLst,rest);
        then (CREF_QUAL(name,subLst,cref),i)::lst;
  end matchcontinue;
end qualifyCRefIntLst;

public function pathReplaceIdent
  input Path path;
  input String last;
  output Path out;
algorithm
  out := matchcontinue (path,last)
    local Path p; String n,s;
    case (FULLYQUALIFIED(p),s) equation p = pathReplaceIdent(p,s); then FULLYQUALIFIED(p);
    case (QUALIFIED(n,p),s) equation p = pathReplaceIdent(p,s); then QUALIFIED(n,p);
    case (IDENT(_),s) then IDENT(s);
  end matchcontinue;
end pathReplaceIdent;

public function setBuildTimeInInfo
  input Real buildTime;
  input Info inInfo;
  output Info outInfo;
algorithm
  outInfo := matchcontinue(buildTime, inInfo)
    local
      String fileName "fileName where the class is defined in";
      Boolean isReadOnly "isReadOnly : (true|false). Should be true for libraries";
      Integer lineNumberStart "lineNumberStart";
      Integer columnNumberStart "columnNumberStart";
      Integer lineNumberEnd "lineNumberEnd";
      Integer columnNumberEnd "columnNumberEnd";
      Real lastBuildTime "Last Build Time";
      Real lastEditTime "Last Edit Time";
    case (buildTime, INFO(fileName, isReadOnly, lineNumberStart, columnNumberStart,
                          lineNumberEnd, columnNumberEnd, TIMESTAMP(lastBuildTime,lastEditTime)))
    then
      (INFO(fileName, isReadOnly, lineNumberStart, columnNumberStart, lineNumberEnd, columnNumberEnd, TIMESTAMP(buildTime,lastEditTime)));
  end matchcontinue;
end setBuildTimeInInfo;

public function getFileNameFromInfo
  input Info inInfo;
  output String inFileName;
algorithm
  inFileName := matchcontinue(inInfo)
    local String fileName;
    case (INFO(fileName = fileName)) then fileName;
  end matchcontinue;
end getFileNameFromInfo;

public function isOuter
"@author: adrpo
 this function returns true if the given Absyn.InnerOuter
 is one of Absyn.INNEROUTER() or Absyn.OUTER()"
 input InnerOuter io;
 output Boolean isItAnOuter;
algorithm
  isItAnOuter := matchcontinue(io)
    case (INNEROUTER()) then true;
    case (OUTER()) then true;
    case (_) then false;
  end matchcontinue;
end isOuter;

public function isInner
"@author: adrpo
 this function returns true if the given Absyn.InnerOuter
 is one of Absyn.INNEROUTER() or Absyn.INNER()"
 input InnerOuter io;
 output Boolean isItAnInner;
algorithm
  isItAnInner := matchcontinue(io)
    case (INNEROUTER()) then true;
    case (INNER()) then true;
    case (_) then false;
  end matchcontinue;
end isInner;

end Absyn;
